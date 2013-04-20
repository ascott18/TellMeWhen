-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local clientVersion = select(4, GetBuildInfo())

local SpellCache = TMW:NewModule("SpellCache", "AceEvent-3.0", "AceTimer-3.0")

local Cache
local CurrentItems = {}
local NumCachePerFrame = 500
local IsCaching

SpellCache.CONST = {
	-- A rough estimate of the highest spellID in the game. Doesn't have to be accurate at all - visual only.
	MAX_SPELLID_GUESS = 132000,
	
	-- Maximum number of non-existant spellIDs that will be checked before the cache is declared complete.
	MAX_FAILED_SPELLS = 2000,
	
	-- A list of spells that should be excluded from the cache
	INVALID_SPELLS = {
		[1852] = true, -- GM spell named silenced, interferes with equiv
		[47923] = true, -- spell named stunned, interferes
		[65918] = true, -- spell named stunned, interferes
		[78320] = true, -- spell named stunned, interferes
		[71216] = true, -- enraged, interferes
		[59208] = true, -- enraged, interferes
		[118542] = true, -- disarmed, interferes
	},
	
	-- A list of textures, spells that have these textures should be excluded from the cache.
	INVALID_TEXTURES = {
		["Interface\\Icons\\Trade_Alchemy"] = true,
		["Interface\\Icons\\Trade_BlackSmithing"] = true,
		["Interface\\Icons\\Trade_BrewPoison"] = true,
		["Interface\\Icons\\Trade_Engineering"] = true,
		["Interface\\Icons\\Trade_Engraving"] = true,
		["Interface\\Icons\\Trade_Fishing"] = true,
		["Interface\\Icons\\Trade_Herbalism"] = true,
		["Interface\\Icons\\Trade_LeatherWorking"] = true,
		["Interface\\Icons\\Trade_Mining"] = true,
		["Interface\\Icons\\Trade_Tailoring"] = true,
		["Interface\\Icons\\INV_Inscription_Tradeskill01"] = true,
		["Interface\\Icons\\Temp"] = true,
	},
}
local CONST = SpellCache.CONST


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
	return TMWOptDB.CacheLength
end

-- Returns whether or not the cache is currently in progress.
function SpellCache:IsCaching()
	return IsCaching
end

-- END PUBLIC




-- PRIVATE:

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	TMWOptDB.SpellCache = TMWOptDB.SpellCache or {}

	Cache = TMWOptDB.SpellCache

	if TMWOptDB.IncompleteCache or not TMWOptDB.WoWVersion or TMWOptDB.WoWVersion < clientVersion then
		TMWOptDB.IncompleteCache = true
		
		local function findword(str, word)
			if not strfind(str, word) then
				return nil
			else
				if strfind(str, "%A" .. word .. "%A") -- in the middle
				or strfind(str, "^" .. word .. "%A") -- at the beginning
				or strfind(str, "%A" .. word .. "$")-- at the end
				then
					return true
				end
			end
		end
		
		local index, spellsFailed = 0, 0

		TMWOptDB.CacheLength = TMWOptDB.CacheLength or CONST.MAX_SPELLID_GUESS
		TMW:Fire("TMW_SPELLCACHE_EXPECTEDCACHELENGTH_UPDATED", TMWOptDB.CacheLength)

		if TMWOptDB.WoWVersion and TMWOptDB.WoWVersion < clientVersion then
			wipe(Cache)
		elseif TMWOptDB.IncompleteCache then
			for id in pairs(Cache) do
				index = max(index, id)
			end
		end
		TMWOptDB.WoWVersion = clientVersion

		local Parser, LT1 = TMW:GetParser()

		local SPELL_CAST_CHANNELED = SPELL_CAST_CHANNELED
		local yield, resume = coroutine.yield, coroutine.resume

		local isInCombatLockdown = InCombatLockdown()
		local function SpellCacher()

			while spellsFailed < CONST.MAX_FAILED_SPELLS do
			
				local name, rank, icon = GetSpellInfo(index)
				if name then
					name = strlower(name)

					local fail =
					CONST.INVALID_TEXTURES[icon] or
					findword(name, "dnd") or
					findword(name, "test") or
					findword(name, "debug") or
					findword(name, "bunny") or
					findword(name, "visual") or
					findword(name, "trigger") or
					strfind(name, "[%]%[%%%+%?]") or -- no brackets, plus signs, percent signs, or question marks
					findword(name, "vehicle") or
					findword(name, "event") or
					findword(name, "quest") or
					strfind(name, ":%s?%d") or -- interferes with colon duration syntax
					findword(name, "camera") or
					findword(name, "dmg")

					if not fail then
						Parser:SetOwner(UIParent, "ANCHOR_NONE") -- must set the owner before text can be obtained.
						Parser:SetSpellByID(index)
						local r, g, b = LT1:GetTextColor()
						if g > .95 and r > .95 and b > .95 then
							Cache[index] = name
						end
						spellsFailed = 0
					end
				else
					spellsFailed = spellsFailed + 1
				end
				index = index + 1

				if index % (isInCombatLockdown and 1 or NumCachePerFrame) == 0 then
					TMW:Fire("TMW_SPELLCACHE_NUMCACHED_CHANGED", index)
					yield()
				end
			end
		end
		local co = coroutine.create(SpellCacher)
		
		IsCaching = true
		TMW:Fire("TMW_SPELLCACHE_STARTED")

		local f = CreateFrame("Frame")
		f:SetScript("OnUpdate", function()
			if not resume(co) then
				TMWOptDB.IncompleteCache = false
				TMWOptDB.CacheLength = index

				f:SetScript("OnUpdate", nil)

				for spellID in pairs(CONST.INVALID_SPELLS) do
					Cache[spellID] = nil
				end

				co = nil
				Parser:Hide()
				
				IsCaching = nil
				TMW:Fire("TMW_SPELLCACHE_COMPLETED")
		
				collectgarbage()
			end
		end)
		f:RegisterEvent("UNIT_FLAGS") -- accurately detects changes to InCombatLockdown
		f:SetScript("OnEvent", function(self, event)
			isInCombatLockdown = InCombatLockdown()
		end)
			
	end
end)

-- END PRIVATE

