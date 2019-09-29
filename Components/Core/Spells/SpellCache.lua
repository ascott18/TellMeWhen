-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local strfind, strlower, pairs
    = strfind, strlower, pairs
local GetSpellInfo, InCombatLockdown, C_TradeSkillUI
    = GetSpellInfo, InCombatLockdown, C_TradeSkillUI

local debugprofilestop = debugprofilestop_SAFE

local clientVersion = select(4, GetBuildInfo())
local clientBuild = select(2, GetBuildInfo())

local SpellCache = TMW:NewModule("SpellCache", "AceEvent-3.0", "AceTimer-3.0")

local Cache

 -- Keep this pretty low. Ideally, the framerate impact is completely unnoticable.
 -- It'll be set significantly higher if the icon editor is opened.
local NumCachePerFrame = 70
local IsCaching


SpellCache.CONST = {
	-- A rough estimate of the highest spellID in the game. Doesn't have to be accurate at all - visual only.
	MAX_SPELLID_GUESS = 280000,
	
	-- Maximum number of non-existant spellIDs that will be checked before the cache is declared complete.
	MAX_FAILED_SPELLS = 2000,
	
	WHITELIST = {
		-- A list of spells that will fail other filters, but are still desired
		[8178] = true, -- Grounding Totem Effect
		[3355] = true, -- Freezing Trap Effect
		[14308] = true, -- Freezing Trap Effect
		[14309] = true, -- Freezing Trap Effect
		[19675] = true, -- Feral Charge Effect
	},

	-- A list of spells that should be excluded from the cache
	INVALID_SPELLS = {
		[1852] = true, -- GM spell named silenced
	},

	-- Any spell that uses these textures should be excluded.
	INVALID_TEXTURES = {
		-- These are the worst offenders by far.
		-- Engineering is especially bad because its icon is used for tons of internal spells
		-- that the player never sees.
		[136243] = true, -- ["Interface\\Icons\\Trade_Engineering"] = true, 
		[136240] = true, -- ["Interface\\Icons\\Trade_Alchemy"] = true, 
		[136241] = true, -- ["Interface\\Icons\\Trade_BlackSmithing"] = true, 
		[136247] = true, -- ["Interface\\Icons\\Trade_LeatherWorking"] = true, 

		-- These aren't as bad as the rest, but still don't have any real spells that should be in the list.
		[136244] = true, -- ["Interface\\Icons\\Trade_Engraving"] = true, 
		[136245] = true, -- ["Interface\\Icons\\Trade_Fishing"] = true, 
		[136246] = true, -- ["Interface\\Icons\\Trade_Herbalism"] = true, 
		[136248] = true, -- ["Interface\\Icons\\Trade_Mining"] = true, 
		[136249] = true, -- ["Interface\\Icons\\Trade_Tailoring"] = true, 
		[237171] = true, -- ["Interface\\Icons\\INV_Inscription_Tradeskill01"] = true, 
	},
}
local CONST = SpellCache.CONST


TMW.IE:RegisterDatabaseDefaults{
	locale = {
		SpellCacheLength = CONST.MAX_SPELLID_GUESS,
		SpellCacheWoWVersion = 0,

		-- Keys are spellIDs that are known to be invalid. Values are the number of spells after the key that are also invalid.
		SpellCacheInvalidRanges = {

		},
	},
}

TMW.IE:RegisterUpgrade(71016, {
	global = function(self)
		TMW.IE.db.global.SpellCache = nil
		TMW.IE.db.global.CacheLength = nil
		TMW.IE.db.global.IncompleteCache = nil
		TMW.IE.db.global.WoWVersion = nil
	end,
})

-- Force a re-cache - If a re-cache is needed, just update this version num to the latest version.
-- 84201 - Added a fix to exclude spells with blank names, because Blizzard managed to make a spell with no name.
TMW.IE:RegisterUpgrade(84201, {
	locale = function(self, locale)
		locale.SpellCacheWoWVersion = 0
	end,
})

TMW.IE:RegisterUpgrade(84405, {
	-- I managed to make the spell cache fast enough that its no longer worth persisting to disk.
	-- We're going to recreate it on each load of TMW_Options.
	-- This eliminates the significant factor in the load time of TMW_Options, and will also increase logout speeds.
	locale = function(self, locale)
		TMW.IE.db.locale.SpellCache = nil
		TMW.IE.db.locale.IncompleteSpellCache = nil
	end,
})

-- PUBLIC:

--[[ Returns the main cache table. Structure:
Cache = {
	[spellID] = 1,
}
]]
function SpellCache:GetCache()
	if not Cache then
		error("SpellCache is not yet initialized", 2)
	end
	
	return Cache
end

-- Sets the number of spells that will be checked per frame.
function SpellCache:SetNumCachePerFrame(num)
	TMW:ValidateType(2, "SpellCache:SetNumCachePerFrame()", num, "number")
	
	if NumCachePerFrame ~= num then
		NumCachePerFrame = num
		TMW:Fire("TMW_SPELLCACHE_NUMCACHEPERFRAME_CHANGED", num)
	end
end

-- Gets the number of spells that will be checked per frame.
function SpellCache:GetNumCachePerFrame()
	return NumCachePerFrame
end

-- Gets the expected length of the finished cache.
function SpellCache:GetExpectedCacheLength()
	return TMW.IE.db.locale.SpellCacheLength
end

-- Returns whether or not the cache is currently in progress.
function SpellCache:IsCaching()
	return IsCaching
end

-- END PUBLIC




-- PRIVATE:

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()

	Cache = {}

	local SpellCacheInvalidRanges = TMW.IE.db.locale.SpellCacheInvalidRanges

	local haveSpellCacheInvalidRanges = true
	if TMW.IE.db.locale.SpellCacheWoWVersion ~= clientBuild then
		wipe(SpellCacheInvalidRanges)
		haveSpellCacheInvalidRanges = false
	end

	TMW:Fire("TMW_SPELLCACHE_EXPECTEDCACHELENGTH_UPDATED", TMW.IE.db.locale.SpellCacheLength)

	local INVALID_TEXTURES = CONST.INVALID_TEXTURES
	local MAX_FAILED_SPELLS = CONST.MAX_FAILED_SPELLS
	
	local isNameGood = { [""] = false }
	local spellID, spellsFailed = 0, 0

	-- The most recent failed spellID that was seen after a success.
	-- nil if the last spellID was a success.
	local lastFail = nil
	local Parser, LT1 = TMW:GetParser()

	local function SpellCacher()
		local numToCheck = InCombatLockdown() and 10 or NumCachePerFrame

		for _ = 1, numToCheck do
			spellID = spellID + 1

			local skip = SpellCacheInvalidRanges[spellID]
			if skip then
				spellID = spellID + skip
			end

			local name, _, icon = GetSpellInfo(spellID)
			local fail
			if name then
				spellsFailed = 0

				-- This is our best filter by far - about 70k spells are filtered out by this.
				fail = INVALID_TEXTURES[icon] or false

				if not fail then
					-- Keep track of known good names. Don't do name checking on known good names.
					-- Cache by the name before lowering it to avoid strlower() hits.
					-- We store the lowered name as the value for good names, otherwise false.
					local knownGood = isNameGood[name]
					if knownGood == false then
						fail = true
					elseif knownGood ~= nil then
						name = knownGood
					else
						local nameOriginal = name
						name = strlower(name)
						fail =
							(strfind(name, "quest") and strfind(name, "%f[%a]quest%f[%A]")) or
							(strfind(name, "trigger") and strfind(name, "%f[%a]trigger%f[%A]")) or
							strfind(name, "[%]%[%%%+%?]") or -- no brackets, plus signs, percent signs, or question marks
							(strfind(name, "visual") and strfind(name, "%f[%a]visual%f[%A]")) or
							(strfind(name, "dnd") and strfind(name, "%f[%a]dnd%f[%A]")) or
							(strfind(name, "event") and strfind(name, "%f[%a]event%f[%A]")) or
							(strfind(name, "test") and strfind(name, "%f[%a]test%f[%A]")) or
							strfind(name, "%d.%d") or -- Number Dot Number is probably a patch number, used often for internal spells
							(strfind(name, "vehicle") and strfind(name, "%f[%a]vehicle%f[%A]")) or
							(strfind(name, "credit") and strfind(name, "%f[%a]credit%f[%A]")) or
							-- 'effect' is used quite bit in classic for lots of real things. Don't blacklist it.
							-- (strfind(name, "effect") and strfind(name, "%f[%a]effect%f[%A]")) or
							(strfind(name, "camera") and strfind(name, "%f[%a]camera%f[%A]")) or
							(strfind(name, "ph") and strfind(name, "%f[%a]ph%f[%A]")) or
							(strfind(name, "proc") and strfind(name, "%f[%a]proc%f[%A]")) or
							(strfind(name, "debug") and strfind(name, "%f[%a]debug%f[%A]")) or
							(strfind(name, "bunny") and strfind(name, "%f[%a]bunny%f[%A]")) or
							strfind(name, ":%s?%d") or -- interferes with colon duration syntax
							(strfind(name, "dmg") and strfind(name, "%f[%a]dmg%f[%A]"))

						isNameGood[nameOriginal] = not fail and name or false
					end

					-- if not fail then
					-- 	Parser:SetOwner(UIParent, "ANCHOR_NONE")
					-- 	Parser:SetSpellByID(spellID)
					-- 	local r, g, b = LT1:GetTextColor()
					-- 	if g < .95 or r < .95 or b < .95 then
					-- 		fail = true
					-- 	end
					-- end

					if not fail then
						Cache[spellID] = name
					end
				end

			else
				fail = true
				spellsFailed = spellsFailed + 1
			end

			if not haveSpellCacheInvalidRanges then
				if fail then
					if not lastFail then lastFail = spellID end
				elseif lastFail then
					-- spellID was successful (fail is false).
					-- Record the range if its big enough to be significant.
					local range = spellID - lastFail
					if range > 2 then
						SpellCacheInvalidRanges[lastFail] = range
					end
					lastFail = nil
				end
			end
		end

		TMW:Fire("TMW_SPELLCACHE_NUMCACHED_CHANGED", spellID)
		if spellID > TMW.IE.db.locale.SpellCacheLength then
			TMW.IE.db.locale.SpellCacheLength = spellID
			TMW:Fire("TMW_SPELLCACHE_EXPECTEDCACHELENGTH_UPDATED", TMW.IE.db.locale.SpellCacheLength)
		end
	end

	IsCaching = true
	TMW:Fire("TMW_SPELLCACHE_STARTED")

	local f = CreateFrame("Frame")
	local hadError = false
	local totalTime = 0
	f:SetScript("OnUpdate", function()
		local start = debugprofilestop()

		local success = TMW.safecall(SpellCacher)
		if success and spellsFailed < MAX_FAILED_SPELLS then
			-- Carry on. Keep iterating.
		else
			-- We're done, or we errored.

			if success then
				-- We didn't error.
				TMW.IE.db.locale.SpellCacheWoWVersion = clientBuild
			end

			-- We're done, or we errored.
			print("Cache complete in " .. totalTime)

			f:SetScript("OnUpdate", nil)

			for spellID in pairs(CONST.INVALID_SPELLS) do
				Cache[spellID] = nil
			end
			for spellID in pairs(CONST.WHITELIST) do
				Cache[spellID] = strlower(GetSpellInfo(spellID))
			end

			IsCaching = nil
			TMW:Fire("TMW_SPELLCACHE_COMPLETED")
		end
		totalTime = totalTime + debugprofilestop() - start
	end)
end)

-- END PRIVATE

