-- --------------------
-- TellMeWhen
-- Originally by NephMakes

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

local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName
local GetClassInfo = TMW.GetClassInfo
local GetMaxClassID = TMW.GetMaxClassID

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
    local SpellData = self.SpellData

	if not next(PlayerSpells) then
		if SpellData[pclass] then
			for k, v in pairs(SpellData[pclass]) do
				PlayerSpells[k] = 1
			end
		end
		for k, v in pairs(SpellData.PET) do
			if v == pclass then
				PlayerSpells[k] = 1
			end
		end

		local _, race = UnitRace("player")


		for spellID, data in pairs(SpellData.RACIAL) do
			local raceNames = data[1]
			local classReq = data[2]
			if TMW.tContains(raceNames, race) then
				if classReq ~= 0 then
					-- Verify that it is valid for this class.
					for classID = 1, GetMaxClassID() do
						local name, token = GetClassInfo(classID)
						if name and token == pclass and bit.band(bit.lshift(1, classID-1), classReq) > 0 then
							PlayerSpells[spellID] = 1
							break
						end
					end
				else
					PlayerSpells[spellID] = 1
				end
			end
		end
	end
	
	return PlayerSpells
end

--[[ Returns the main cache table. Structure:
SpellData = {
	[classToken] = {
		[spellID] = 1,
	},
	PET = {
		[spellID] = classToken,
	},
	RACIAL = {
		[spellID] = {{raceName [,raceName2]...}, classReq},
		-- classReq is a bitfield, with enabled bits representing classIDs that the racial is good for. If 0, the spell has no restrictions.
	},
}
]]
function ClassSpellCache:GetCache()
	if not CacheIsReady then
		error("The class spell cache hasn't been prepared yet.")
	end

	return self.SpellData
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
		for class, spells in pairs(self.SpellData) do
			if class ~= "RACIAL" and class ~= "PET" then
				local c = {}
				NameCache[class] = c
				for spellID, value in pairs(spells) do
					local name = GetSpellName(spellID)
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

function TMW.GameTooltip_SetSpellByIDWithClassIcon(self, spellID)
	local ret = self:SetSpellByID(spellID)

	local classToken = ClassSpellLookup[spellID]
	if classToken then
		local secondIcon = ""
		if classToken == "PET" then
			classToken = ClassSpellCache.SpellData.PET[spellID]
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


			local data = ClassSpellCache.SpellData.RACIAL[spellID]
			-- There are class restrictions on the spell.
			local raceNames = data[1]
			local classReq = data[2]

			for _, raceName in pairs(raceNames) do
				secondIcon = secondIcon .. TMW:FormatAtlasString(TMW:GetRaceIconInfo(raceName), 0.07)
			end

			-- Find the classes that it is valid for.
			if classReq ~= 0 then
				for classID = 1, GetMaxClassID() do
					local name, token = GetClassInfo(classID)
					if name and bit.band(bit.lshift(1, classID-1), classReq) > 0 then
						secondIcon = secondIcon .. " " .. getClassIconString(token)
					end
				end
			end
		end

		local classIcon = classToken and getClassIconString(classToken) or ""

		local textLeft1 = _G[self:GetName() .. "TextLeft1"]
		textLeft1:SetText( 
			classIcon ..
			secondIcon .. " " ..
			(textLeft1:GetText() or "")
		)
	end

	return ret
end

-- END PUBLIC





-- PRIVATE:

function ClassSpellCache:TMW_DB_INITIALIZED()
	local SpellData = self.SpellData

	for classID, spellList in pairs(CopyTable(SpellData)) do
		if type(classID) == "number" then
			local name, token, classID = GetClassInfo(classID)

			if name then
				local spellDict = {}
				for k, v in pairs(spellList) do
					spellDict[v] = true
				end

				SpellData[token] = spellDict
				SpellData[classID] = nil
			end
		end
	end

	for spellID, classID in pairs(SpellData.PET) do
		SpellData.PET[spellID] = select(2, GetClassInfo(classID))
	end

	-- Translate raceIDs into their corresponding race names.
	for spellID, data in pairs(SpellData.RACIAL) do
		for i, raceId in pairs(data[1]) do
			data[1][i] = self.RaceMap[raceId]
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
	if SpellData[pclass] then
		for id in pairs(SpellData[pclass]) do
			AddID(id)
		end
	else
		TMW:Error("Unknown class " .. pclass)
	end
	
	-- Next comes spells of all other classes.
	for class, tbl in pairs(SpellData) do
		if class ~= pclass and class ~= "PET" then
			for id in pairs(tbl) do
				AddID(id)
			end
		end
	end

	-- Pets are last because there are some overlapping names with class spells
	-- and we don't want to overwrite the textures for class spells with ones for pet spells.
	for id in pairs(SpellData.PET) do
		AddID(id)
	end
	
	for class, tbl in pairs(SpellData) do
		for id in pairs(tbl) do
			ClassSpellLookup[id] = class
		end
	end

	CacheIsReady = true
	
	return true -- Signal callback destruction
end
TMW:RegisterSelfDestructingCallback("TMW_DB_INITIALIZED", ClassSpellCache)


-- END PRIVATE
