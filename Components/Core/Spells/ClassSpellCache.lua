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

local pairs, type, ipairs, bit, select = 
      pairs, type, ipairs, bit, select

local _, pclass = UnitClass("Player")


TMW:RegisterUpgrade(72013, {
	global = function()
		-- The class spell cache is no longer generated dynamically - too many problems with it
		-- (lacking many spells, sharing over comm is vulnerable to bad data, etc.)
		TMW.db.global.ClassSpellCache = nil
		TMW.db.global.XPac_ClassSpellCache = nil

		-- Also nil out some other unused, old SVs.
		TMW.db.global.XPac = nil
		TMW.db.global.XPac_AuraCache = nil
	end,
})

local ClassSpellCache = TMW:NewModule("ClassSpellCache", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")


local RaceMap = {
	[1] = "Human",
	[2] = "Orc",
	[3] = "Dwarf",
	[4] = "NightElf",
	[5] = "Scourge",
	[6] = "Tauren",
	[7] = "Gnome",
	[8] = "Troll",
}
local Cache = {
	[1] =  {},
	[2] =  {},
	[3] =  {},
	[4] =  {},
	[5] =  {},
	[6] =  nil, -- Deathknight
	[7] =  {},
	[8] =  {},
	[9] =  {},
	[10] = nil, -- Monk
	[11] = {},
	["RACIAL"] = {},
	["PET"] = {}
}


-- Adjustments to the imported cache data:
tinsert(Cache[3], 1, 75) -- Add "Auto Shot" to hunter.


local CacheIsReady = false

local PlayerSpells = {}
local ClassSpellLookup = {}
local NameCache


-- PUBLIC:

-- Contains a dictionary of spellIDs that are player spells.
function ClassSpellCache:GetSpellLookup()	
	if not CacheIsReady then
		error("The class spell cache hasn't been prepared yet.")
	end

	return ClassSpellLookup
end

-- Returns a dictionary of spellIDs that (should) belong to the current player.
function ClassSpellCache:GetPlayerSpells()
	if not next(PlayerSpells) then
		for k, v in pairs(Cache[pclass]) do
			PlayerSpells[k] = 1
		end
		for k, v in pairs(Cache.PET) do
			if v == pclass then
				PlayerSpells[k] = 1
			end
		end

		local _, race = UnitRace("player")


		for spellID, data in pairs(Cache.RACIAL) do
			if type(data) == "table" then
				error("apparently there still are class restrictions on racials in classic?")
				-- There are class restrictions on the spell.
				-- local raceName = data[1]
				-- local classReq = data[2]
				-- if raceName == race then
				-- 	-- Verify that it is valid for this class.
				-- 	for classID = 1, MAX_CLASSES do
				-- 		local token = CLASS_SORT_ORDER[classID]
				-- 		if token == pclass and bit.band(bit.lshift(1, classID-1), classReq) > 0 then
				-- 			PlayerSpells[spellID] = 1
				-- 			break
				-- 		end
				-- 	end
				-- end

			elseif data == race then
				-- data is a race name
				-- There are no class restrictions on this spell.
				PlayerSpells[spellID] = 1
			end
		end
	end
	
	return PlayerSpells
end

--[[ Returns the main cache table. Structure:
Cache = {
	[classToken] = {
		[spellID] = 1,
	},
	PET = {
		[spellID] = classToken,
	},
	RACIAL = {
		[spellID] = raceName,
		[spellID2] = {raceName, classReq},
		-- classReq is a bitfield, with enabled bits representing classIDs that the racial is good for.
	},
}
]]
function ClassSpellCache:GetCache()
	if not CacheIsReady then
		error("The class spell cache hasn't been prepared yet.")
	end

	return Cache
end

--[[ Returns a mapping of spell names to spellIDs. Structure:
NameCache = {
	[classToken] = {
		[spellName] = true,
	},
}
]]
function ClassSpellCache:GetNameCache()
	if not CacheIsReady then
		error("The class spell cache hasn't been prepared yet.")
	end
	
	if not NameCache then
		NameCache = {}
		for class, spells in pairs(Cache) do
			if class ~= "RACIAL" and class ~= "PET" then
				local c = {}
				NameCache[class] = c
				for spellID, value in pairs(spells) do
					local name = GetSpellInfo(spellID)
					if name then
						c[name:lower()] = true
					end
				end
			end
		end
	end

	return NameCache
end

local function getClassIconString(classToken)
	return "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:256:256:" ..
	(CLASS_ICON_TCOORDS[classToken][1]+.02)*256 .. ":" .. 
	(CLASS_ICON_TCOORDS[classToken][2]-.02)*256 .. ":" .. 
	(CLASS_ICON_TCOORDS[classToken][3]+.02)*256 .. ":" .. 
	(CLASS_ICON_TCOORDS[classToken][4]-.02)*256 .. "|t"
end

function GameTooltip:TMW_SetSpellByIDWithClassIcon(spellID)
	local ret = GameTooltip:SetSpellByID(spellID)

	local classToken = ClassSpellLookup[spellID]
	if classToken then
		local secondIcon = ""
		if classToken == "PET" then
			classToken = Cache.PET[spellID]
			local icon
			if classToken == "WARLOCK" then
				icon = "spell_shadow_metamorphosis"
			elseif classToken == "DEATHKNIGHT" then
				icon = "spell_deathknight_gnaw_ghoul"
			elseif classToken == "SHAMAN" then
				icon = "spell_fire_elemental_totem"
			else
				icon = "ability_hunter_mendpet"
			end
			secondIcon = " |TInterface\\Icons\\" .. icon .. ":0:0:0:0:32:32:2.24:29.76:2.24:29.76|t"
		elseif classToken == "RACIAL" then
			classToken = nil


			local data = Cache.RACIAL[spellID]
			if type(data) == "table" then
				error("apparently there still are class restrictions on racials in classic?")
				-- There are class restrictions on the spell.
				-- local raceName = data[1]
				-- local classReq = data[2]

				-- secondIcon = TMW:FormatAtlasString(TMW:GetRaceIconInfo(raceName), 0.07)

				-- -- Find the classes that it is valid for.
				-- for classID = 1, MAX_CLASSES do
				-- 	local name, token = GetClassInfo(classID)
				-- 	if bit.band(bit.lshift(1, classID-1), classReq) > 0 then
				-- 		secondIcon = secondIcon .. " " .. getClassIconString(token)
				-- 	end
				-- end

			else
				-- There are no class restriction on the spell.
				-- data is a race name
				secondIcon = TMW:FormatAtlasString(TMW:GetRaceIconInfo(data), 0.07)
			end
		end

		local classIcon = classToken and getClassIconString(classToken) or ""

		GameTooltipTextLeft1:SetText( 
		classIcon ..
		secondIcon .. " " ..
		GameTooltipTextLeft1:GetText())
	end

	return ret
end

-- END PUBLIC





-- PRIVATE:

function ClassSpellCache:TMW_DB_INITIALIZED()
	
	for classID, spellList in pairs(Cache) do
		if type(classID) == "number" then
			local classInfo = C_CreatureInfo.GetClassInfo(classID)

			local spellDict = {}
			for k, v in pairs(spellList) do
				spellDict[v] = true
			end

			Cache[classInfo.classFile] = spellDict
			Cache[classID] = nil
		end
	end

	for spellID, classID in pairs(Cache.PET) do
		Cache.PET[spellID] = select(2, C_CreatureInfo.GetClassInfo(classID).classFile)
	end

	for spellID, data in pairs(Cache.RACIAL) do
		if type(data) == "table" then
			local raceID = data[1]
			local classReq = data[2]
			data[1] = RaceMap[raceID]
		else
			-- data is a raceID.
			Cache.RACIAL[spellID] = RaceMap[data]
		end
	end
	
	-- Adds a spell's texture to the texture cache by name
	-- so that we can get textures by spell name much more frequently,
	-- reducing the usage of question mark and pocketwatch icons.
	local function AddID(id)
		if id > 0x7FFFFFFF then
			return
		end
		local name, _, tex = GetSpellInfo(id)
		name = TMW.strlowerCache[name]
		if name and not TMW.SpellTexturesMetaIndex[name] then
			TMW.SpellTexturesMetaIndex[name] = tex
		end
	end
	
	-- Spells of the user's class should be prioritized.
	for id in pairs(Cache[pclass]) do
		AddID(id)
	end
	
	-- Next comes spells of all other classes.
	for class, tbl in pairs(Cache) do
		if class ~= pclass and class ~= "PET" then
			for id in pairs(tbl) do
				AddID(id)
			end
		end
	end

	-- Pets are last because there are some overlapping names with class spells
	-- and we don't want to overwrite the textures for class spells with ones for pet spells.
	for id in pairs(Cache.PET) do
		AddID(id)
	end
	
	for class, tbl in pairs(Cache) do
		for id in pairs(tbl) do
			ClassSpellLookup[id] = class
		end
	end

	CacheIsReady = true
	
	return true -- Signal callback destruction
end
TMW:RegisterSelfDestructingCallback("TMW_DB_INITIALIZED", ClassSpellCache)


-- END PRIVATE
