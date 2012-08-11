-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

if not TMW then return end

local TMW = TMW
local Env

-- -----------------------
-- LOCALS/GLOBALS/UTILITIES
-- -----------------------

local L = TMW.L
local _, pclass = UnitClass("Player")

local tostring, type, pairs, ipairs, tremove, pcall, unpack, select, tonumber, wipe, assert, next, loadstring, setfenv, setmetatable =
	  tostring, type, pairs, ipairs, tremove, pcall, unpack, select, tonumber, wipe, assert, next, loadstring, setfenv, setmetatable
local strlower, min, max, gsub, strfind, strsub, strtrim, format, strmatch, strsplit, strrep =
	  strlower, min, max, gsub, strfind, strsub, strtrim, format, strmatch, strsplit, strrep
local NONE, MAX_SPELL_SCHOOLS =
	  NONE, MAX_SPELL_SCHOOLS
local GetPetActionInfo, GetTotemInfo =
	  GetPetActionInfo, GetTotemInfo
local IsInInstance, GetInstanceDifficulty =
	  IsInInstance, GetInstanceDifficulty
local GetNumTalentTabs, GetNumTalents, GetTalentInfo =
	  GetNumTalentTabs, GetNumTalents, GetTalentInfo
local GetShapeshiftFormInfo, GetShapeshiftForm, GetNumShapeshiftForms =
	  GetShapeshiftFormInfo, GetShapeshiftForm, GetNumShapeshiftForms
local UnitAttackPower, UnitRangedAttackPower =
	  UnitAttackPower, UnitRangedAttackPower
local GetSpellCritChance =
	  GetSpellCritChance
local GetSpellBonusDamage, GetSpellBonusHealing =
	  GetSpellBonusDamage, GetSpellBonusHealing
local GetSpellTexture, GetInventoryItemTexture, GetInventorySlotInfo, GetCurrencyInfo =
	  GetSpellTexture, GetInventoryItemTexture, GetInventorySlotInfo, GetCurrencyInfo
local UnitAura =
	  UnitAura
local GetNumTrackingTypes, GetTrackingInfo =
	  GetNumTrackingTypes, GetTrackingInfo

local _G = _G
local print = TMW.print
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber
local huge = math.huge

local time = GetTime()

local CNDT = TMW:NewModule("Conditions", "AceEvent-3.0", "AceSerializer-3.0") TMW.CNDT = CNDT
CNDT.SpecialUnitsUsed = {}

local functionCache = {} CNDT.functionCache = functionCache

TMW.Condition_Defaults = {
	n 					= 0,
	["**"] = {
		AndOr 	   		= "AND",
		Type 	   		= "",
		Icon 	   		= "",
		Operator   		= "==",
		Level 	   		= 0,
		Unit 	   		= "player",
		Name 	   		= "",
		Name2 	   		= "",
		PrtsBefore 		= 0,
		PrtsAfter  		= 0,
		Checked			= false,
		Checked2   		= false,
		Runes 	   		= {},
	},
}

TMW.Icon_Defaults.Conditions = TMW.Condition_Defaults
TMW.Group_Defaults.Conditions = TMW.Condition_Defaults

TMW:RegisterCallback("TMW_UPGRADE_REQUESTED", function(event, type, version, ...)
	-- When a global settings upgrade is requested, update all text layouts.
	
	if type == "group" then
		local gs, groupID = ...
		
		-- delegate to conditions
		for conditionID, condition in TMW:InNLengthTable(gs.Conditions) do
			TMW:DoUpgrade("condition", version, condition, conditionID, groupID)
		end
		
	elseif type == "icon" then
		local ics, groupID, iconID = ...
		
		-- delegate to conditions
		for conditionID, condition in TMW:InNLengthTable(ics.Conditions) do
			TMW:DoUpgrade("condition", version, condition, conditionID, groupID, iconID)
		end
	end
	
end)

TMW:RegisterUpgrade(51008, {
	condition = function(self, condition)
		if condition.Type == "TOTEM1"
		or condition.Type == "TOTEM2"
		or condition.Type == "TOTEM3"
		or condition.Type == "TOTEM4"
		then
			condition.Name = ""
		end
	end,
})
TMW:RegisterUpgrade(46417, {
	-- cant use the conditions key here because it depends on Conditions.n, which is 0 until this is ran
	-- also, dont use TMW:InNLengthTable because it will use conditions.n, which is 0 until the upgrade is complete
	group = function(self, gs)
		local n = 0
		for k in pairs(gs.Conditions) do
			if type(k) == "number" then
				n = max(n, k)
			end
		end
		gs.Conditions.n = n
	end,
	icon = function(self, ics)
		local n = 0
		for k in pairs(ics.Conditions) do
			if type(k) == "number" then
				n = max(n, k)
			end
		end
		ics.Conditions.n = n
	end,
})
TMW:RegisterCallback("TMW_DB_PRE_DEFAULT_UPGRADES", function() -- 46413
	-- The default condition type changed from "HEALTH" to "" in v46413
	-- So, if the user is upgrading to this version, and Condition.Type is nil,
	-- then it must have previously been set to "HEALTH", causing Ace3DB not to store it,
	-- so explicity set it as "HEALTH" to make sure it doesn't change just because the default changed.
	
	if TellMeWhenDB.profiles and TellMeWhenDB.Version < 46413 then
		for _, p in pairs(TellMeWhenDB.profiles) do
			if p.Groups then
				for _, gs in pairs(p.Groups) do
					if gs.Conditions then
						for k, Condition in pairs(gs.Conditions) do
							if type(k) == "number" and Condition.Type == nil then
								Condition.Type = "HEALTH"
							end
						end
					end
					if gs.Icons then
						for _, ics in pairs(gs.Icons) do
							if ics.Conditions then
								for k, Condition in pairs(ics.Conditions) do
									if type(k) == "number" and Condition.Type == nil then
										Condition.Type = "HEALTH"
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)
TMW:RegisterUpgrade(45802, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "CASTING" then
				condition.Name = ""
			end
		end
	end,
})
TMW:RegisterUpgrade(44202, {
	icon = function(self, ics)
		ics.Conditions["**"] = nil
	end,
})
TMW:RegisterUpgrade(42105, {
	-- cleanup some old stuff that i noticed is sticking around in my settings, probably in other peoples' settings too
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" then
				for k in pairs(condition) do
					if strfind(k, "Condition") then
						condition[k] = nil
					end
				end
				condition.Names = nil
			end
		end
	end,
})
TMW:RegisterUpgrade(41206, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "STANCE" then
				condition.Operator = "=="
			end
		end
	end,
})
TMW:RegisterUpgrade(41008, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" then
				if condition.Type == "SPELLCD" or condition.Type == "ITEMCD" then
					if condition.Level == 0 then
						condition.Operator = "=="
					elseif condition.Level == 1 then
						condition.Operator = ">"
						condition.Level = 0
					end
				elseif condition.Type == "MAINHAND" or condition.Type == "OFFHAND" or condition.Type == "THROWN" then
					if condition.Level == 0 then
						condition.Operator = ">"
					elseif condition.Level == 1 then
						condition.Operator = "=="
						condition.Level = 0
					end
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(41004, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" then
				if condition.Type == "BUFF" then
					condition.Type = "BUFFSTACKS"
				elseif condition.Type == "DEBUFF" then
					condition.Type = "DEBUFFSTACKS"
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(40115, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and (condition.Type == "BUFF" or condition.Type == "DEBUFF") then
				if condition.Level == 0 then
					condition.Operator = ">"
				elseif condition.Level == 1 then
					condition.Operator = "=="
					condition.Level = 0
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(40112, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "CASTING" then
				condition.Level = condition.Level + 1
			end
		end
	end,
})
TMW:RegisterUpgrade(40106, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "ITEMINBAGS" then
				if condition.Level == 0 then
					condition.Operator = ">"
				elseif condition.Level == 1 then
					condition.Operator = "=="
					condition.Level = 0
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(40100, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "NAME" then
				condition.Level = 0
			end
		end
	end,
})
TMW:RegisterUpgrade(40080, {
	icon = function(self, ics)
		for k, v in pairs(ics.Conditions) do
			if type(k) == "number" and v.Type == "ECLIPSE_DIRECTION" and v.Level == -1 then
				v.Level = 0
			end
		end
	end,
})
TMW:RegisterUpgrade(22010, {
	icon = function(self, ics)
		for k, condition in ipairs(ics.Conditions) do
			if type(k) == "number" then
				for k, v in pairs(condition) do
					condition[k] = nil
					condition[k:gsub("Condition", "")] = v
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(22000, {
	icon = function(self, ics)
		for k, v in ipairs(ics.Conditions) do
			if type(k) == "number" and ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
				v.ConditionLevel = 0
			end
		end
	end,
})
TMW:RegisterUpgrade(20100, {
	icon = function(self, ics)
		for k, v in ipairs(ics.Conditions) do
			v.ConditionLevel = tonumber(v.ConditionLevel) or 0
			if type(k) == "number" and ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
				v.ConditionLevel = ceil((v.ConditionLevel/100)*3)
			end
		end
	end,
})


function CNDT:OnInitialize()
end

function CNDT:MINIMAP_UPDATE_TRACKING()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		Env.Tracking[strlower(name)] = active
	end
end

function CNDT:RAID_ROSTER_UPDATE()
	TMW.UNITS:UpdateTankAndAssistMap()
	for oldunit in pairs(Env) do
		if CNDT.SpecialUnitsUsed[oldunit] then
			TMW.UNITS:SubstituteTankAndAssistUnit(oldunit, Env, oldunit, true)
		end
	end
end

if TMW.ISMOP then
	function CNDT:PLAYER_TALENT_UPDATE()
		for talent = 1, MAX_NUM_TALENTS do
			local name, _, _, _, selected = GetTalentInfo(talent)
			local lower = name and strlowerCache[name]
			if lower then
				Env.TalentMap[lower] = selected and 1 or nil
			end
		end
	end
else
	function CNDT:PLAYER_TALENT_UPDATE()
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				local name, _, _, _, rank = GetTalentInfo(tab, talent)
				local lower = name and strlowerCache[name]
				if lower then
					Env.TalentMap[lower] = rank or 0
				end
			end
		end
	end
end

local GetGlyphSocketInfo = GetGlyphSocketInfo
function CNDT:GLYPH_UPDATED()
	local GlyphLookup = Env.GlyphLookup
	wipe(GlyphLookup)
	for i = 1, NUM_GLYPH_SLOTS do
		local _, _, _, spellID = GetGlyphSocketInfo(i)
		local link = GetGlyphLink(i)
		local glyphID = tonumber(strmatch(link, "|H.-:(%d+)"))
		
		if glyphID then
			GlyphLookup[glyphID] = true
			
			local name = GetSpellInfo(spellID)
			name = strlowerCache[name]
			GlyphLookup[name] = true
		end
	end
end


local Classes = {
	"DEATHKNIGHT",
	"DRUID",
	"HUNTER",
	"MAGE",
	"PRIEST",
	"PALADIN",
	"ROGUE",
	"SHAMAN",
	"WARLOCK",
	"WARRIOR",
	TMW.ISMOP and "MONK" or nil,
}

local classifications = {
	"normal",
	"rare",
	"elite",
	"rareelite",
	"worldboss",
}
for k, v in pairs(classifications) do
	classifications[v] = k
end

local roles = {
	"NONE",
	"DAMAGER",
	"HEALER",
	"TANK",
}
for k, v in pairs(roles) do
	roles[v] = k
end

local totems = {}
local totemtex = {}
if pclass == "SHAMAN" then
	totems = {
		L["ICONMENU_TOTEM"] .. " - " .. L["FIRE"],
		L["ICONMENU_TOTEM"] .. " - " .. L["EARTH"],
		L["ICONMENU_TOTEM"] .. " - " .. L["WATER"],
		L["ICONMENU_TOTEM"] .. " - " .. L["AIR"],
	}
	totemtex = {
		GetSpellTexture(8227),	-- flametongue
		GetSpellTexture(78222),	-- stoneskin
		GetSpellTexture(5675),	-- mana spring
		GetSpellTexture(3738),	-- wrath of air
	}
elseif pclass == "DRUID" then
	totems = {
		format(L["MUSHROOM"], 1),
		format(L["MUSHROOM"], 2),
		format(L["MUSHROOM"], 3),
	}
	totemtex = {
		GetSpellTexture(88747),
		GetSpellTexture(88747),
		GetSpellTexture(88747),
	}
elseif pclass == "DEATHKNIGHT" then
	totems = {
		L["ICONMENU_GHOUL"]
	}
	totemtex = {
		GetSpellTexture(46584),
	}
end


local firststanceid
do -- STANCES
	local Stances = {
		{class = "WARRIOR", 	id = 2457}, 	-- Battle Stance
		{class = "WARRIOR", 	id = 71}, 		-- Defensive Stance
		{class = "WARRIOR", 	id = 2458}, 	-- Berserker Stance

		{class = "DRUID", 		id = 5487}, 	-- Bear Form
		{class = "DRUID", 		id = 768}, 		-- Cat Form
		{class = "DRUID", 		id = 1066}, 	-- Aquatic Form
		{class = "DRUID", 		id = 783}, 		-- Travel Form
		{class = "DRUID", 		id = 24858}, 	-- Moonkin Form
		{class = "DRUID", 		id = 33891}, 	-- Tree of Life
		{class = "DRUID", 		id = 33943}, 	-- Flight Form
		{class = "DRUID", 		id = 40120}, 	-- Swift Flight Form

		{class = "PRIEST", 		id = 15473}, 	-- Shadowform

		{class = "ROGUE", 		id = 1784}, 	-- Stealth

		{class = "HUNTER", 		id = 82661}, 	-- Aspect of the Fox
		{class = "HUNTER", 		id = 13165}, 	-- Aspect of the Hawk
		{class = "HUNTER", 		id = 5118}, 	-- Aspect of the Cheetah
		{class = "HUNTER", 		id = 13159}, 	-- Aspect of the Pack
		{class = "HUNTER", 		id = 20043}, 	-- Aspect of the Wild

		{class = "DEATHKNIGHT", id = 48263}, 	-- Blood Presence
		{class = "DEATHKNIGHT", id = 48266}, 	-- Frost Presence
		{class = "DEATHKNIGHT", id = 48265}, 	-- Unholy Presence

		{class = "PALADIN", 	id = 19746}, 	-- Concentration Aura
		{class = "PALADIN", 	id = 32223}, 	-- Crusader Aura
		{class = "PALADIN", 	id = 465}, 		-- Devotion Aura
		{class = "PALADIN", 	id = 19891}, 	-- Resistance Aura
		{class = "PALADIN", 	id = 7294}, 	-- Retribution Aura

		{class = "WARLOCK", 	id = 47241}, 	-- Metamorphosis
		
		--[[{class = "MONK", 		id = 115069}, 	-- Sturdy Ox
		{class = "MONK", 		id = 115070}, 	-- Wise Serpent
		{class = "MONK", 		id = 103985}, 	-- Fierce Tiger]]
	}

	TMW.CSN = {
		[0]	= NONE,
	}

	for k, v in ipairs(Stances) do
		if v.class == pclass then
			firststanceid = firststanceid or v.id
			local z = GetSpellInfo(v.id)
			tinsert(TMW.CSN, z)
		end
	end

	for k, v in pairs(TMW.CSN) do
		TMW.CSN[v] = k
	end
end




Env = {
	UnitHealth = UnitHealth,
	UnitHealthMax = UnitHealthMax,
	UnitPower = UnitPower,
	UnitPowerMax = UnitPowerMax,
	UnitAura = UnitAura,
	GetPetHappiness = GetPetHappiness,
	GetEclipseDirection = GetEclipseDirection,
	UnitName = UnitName,
	GetComboPoints = GetComboPoints,
	UnitExists = UnitExists,
	UnitIsDeadOrGhost = UnitIsDeadOrGhost,
	UnitAffectingCombat = UnitAffectingCombat,
	UnitHasVehicleUI = UnitHasVehicleUI,
	UnitIsPVP = UnitIsPVP,
	UnitClass = UnitClass,
	UnitClassification = UnitClassification,
	UnitGroupRolesAssigned = UnitGroupRolesAssigned,
	UnitDetailedThreatSituation = UnitDetailedThreatSituation,
	GetRaidTargetIndex = GetRaidTargetIndex,
	UnitIsEnemy = UnitIsEnemy,
	UnitIsUnit = UnitIsUnit,
	UnitReaction = UnitReaction,
	GetRuneType = GetRuneType,
	GetRuneCount = GetRuneCount,
	GetSpellCooldown = GetSpellCooldown,
	GetItemCooldown = GetItemCooldown,
	UnitLevel = UnitLevel,
	strlower = strlower,
	strlowerCache = TMW.strlowerCache,
	strfind = strfind,
	floor = floor,
	select = select,
	min = min,
	IsMounted = IsMounted,
	IsSwimming = IsSwimming,
	IsResting = IsResting,
	GetUnitSpeed = GetUnitSpeed,
	GetManaRegen = GetManaRegen,
	UnitBuff = UnitBuff,
	UnitDebuff = UnitDebuff,
	GetWeaponEnchantInfo = GetWeaponEnchantInfo,
	GetItemCount = GetItemCount,
	IsEquippedItem = IsEquippedItem,
	IsSpellInRange = IsSpellInRange,
	IsItemInRange = IsItemInRange,
	GetCurrencyInfo = GetCurrencyInfo,
	SecureCmdOptionParse = SecureCmdOptionParse,
	GetSpellAutocast = GetSpellAutocast,

	UnitStat = UnitStat,
	UnitAttackPower = UnitAttackPower,
	UnitRangedAttackPower = UnitRangedAttackPower,
	UnitSpellHaste = UnitSpellHaste,
	GetMeleeHaste = GetMeleeHaste,
	GetRangedHaste = GetRangedHaste,
	GetExpertise = GetExpertise,
	GetCritChance = GetCritChance,
	GetRangedCritChance = GetRangedCritChance,
	GetSpellCritChance = GetSpellCritChance,
	GetMastery = GetMastery,
	GetSpellBonusDamage = GetSpellBonusDamage,
	GetSpellBonusHealing = GetSpellBonusHealing,

	classifications = classifications,
	roles = roles,

	ActivePetMode = 0,
	NumPartyMembers = 0,
	print = TMW.print,
	type = type,
	time = TMW.time,
	huge = math.huge,
	epsilon = 1e-255,

	Tracking = {},
	TalentMap = {},
	GlyphLookup = {},
	TMW = TMW,
	GCDSpell = TMW.GCDSpell,
} CNDT.Env = Env

TMW:RegisterCallback("TMW_ONUPDATE_PRE", function(event, time_arg)
	time = time_arg
	Env.time = time_arg
end)

Env.SemicolonConcatCache = setmetatable(
{}, {
	__index = function(t, i)
		if not i then return end

		local o = ";" .. strlowerCache[i] .. ";"
		t[i] = o
		return o
	end,
})
local SemicolonConcatCache = Env.SemicolonConcatCache

-- helper functions
local OnGCD = TMW.OnGCD
local GetSpellCooldown = GetSpellCooldown
function Env.CooldownDuration(spell)
	if spell == "gcd" then
		local start, duration = GetSpellCooldown(TMW.GCDSpell)
		return duration == 0 and 0 or (duration - (time - start))
	end

	local start, duration = GetSpellCooldown(spell)
	if duration then
		return ((duration == 0 or OnGCD(duration)) and 0) or (duration - (time - start))
	end
	return 0
end

local GetItemCooldown = GetItemCooldown
function Env.ItemCooldownDuration(itemID)
	local start, duration = GetItemCooldown(itemID)
	if duration then
		return ((duration == 0 or OnGCD(duration)) and 0) or (duration - (time - start))
	end
	return 0
end

local IsUsableSpell = IsUsableSpell
function Env.ReactiveHelper(NameFirst, Checked)
	local usable, nomana = IsUsableSpell(NameFirst)
	if Checked then
		return usable or nomana
	else
		return usable
	end
end

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
function Env.UnitCast(unit, level, matchname)
	local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
	end
	name = strlowerCache[name]
	if matchname == "" and name then
		matchname = name
	end
	if level == 0 then -- only interruptible
		return not notInterruptible and (name == matchname)
	elseif level == 1 then -- present
		return (name == matchname)
	else
		return not (name == matchname) -- absent
	end
end

function Env.AuraStacks(unit, name, namename, filter)
	local isID = isNumber[name]
	
	local buffName, _, _, count, _, _, _, _, _, _, id = UnitAura(unit, namename, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			buffName, _, _, count, _, _, _, _, _, _, id = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	if not buffName then
		return 0
	elseif buffName and count == 0 then
		return 1
	else
		return count
	end
end

function Env.AuraCount(unit, name, namename, filter)
	local n = 0
	local isID = isNumber[name]
	for z = 1, 60 do
		local buffName, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, z, filter)
		if not buffName then
			return n
		elseif (isID and isID == id) or (not isID and strlowerCache[buffName] == name) then
			n = n + 1
		end
	end
	return n
end

function Env.AuraDur(unit, name, namename, filter)
	local isID = isNumber[name]
	
	local buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, namename, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	
	if not buffName then
		return 0
	else
		return expirationTime == 0 and huge or expirationTime - time
	end
end

function Env.AuraTooltipNumber(unit, name, namename, filter)
	local isID = isNumber[name]
	
	local _, _, _, _, _, _, _, _, _, _, id, _, _, v1, v2, v3 = UnitAura(unit, namename, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			_, _, _, _, _, _, _, _, _, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	if v1 then
		if v1 > 0 then
			return v1
		elseif v2 > 0 then
			return v2
		elseif v3 > 0 then
			return v3
		end
	end
	return 0
end

function Env.TotemHelper(slot, nameString)
	local have, name, start, duration = GetTotemInfo(slot)
	if nameString and nameString ~= "" and nameString ~= ";" and name and not strfind(nameString, SemicolonConcatCache[name or ""]) then
		return 0
	end
	return duration and duration ~= 0 and (duration - (time - start)) or 0
end

function Env.GetZoneType()
	local _, z = IsInInstance()
	if z == "pvp" then
		return 1
	elseif z == "arena" then
		return 2
	elseif z == "party" then
		return 2 + GetInstanceDifficulty() --3-4
	elseif z == "raid" then
		return 4 + GetInstanceDifficulty() --5-8
	else
		return 0
	end
end

local NumShapeshiftForms
function Env.GetShapeshiftForm()
	-- very hackey function because of inconsistencies in blizzard's GetShapeshiftForm
	local i = GetShapeshiftForm()
	if pclass == "WARLOCK" and i == 2 then  --metamorphosis is index 2 for some reason
		i = 1
	elseif pclass == "ROGUE" and i > 1 then	--vanish and shadow dance return 3 when active, vanish returns 2 when shadow dance isnt learned. Just treat everything as stealth
		i = 1
	--[[elseif pclass == "MONK" then
		if NumShapeshiftForms == 2 then
			-- Sturdy Ox (Brewmaster, 1st in TMW.CSN)
			-- Wise Serpent (Mistweaver, 2nd in TMW.CSN)
			if i == 2 then
				i = 1
			else
				
			end
		elseif i == 1 then
			-- Fierce Tiger, 3rd in TMW.CSN
			i = 3
		end]]
	end
	if i > NumShapeshiftForms then 	--many Classes return an invalid number on login, but not anymore!
		i = 0
	end

	if i == 0 then
		return 0
	else
		local _, n = GetShapeshiftFormInfo(i)
		return TMW.CSN[n] or 0
	end
end

local UnitAttackPower = UnitAttackPower
function Env.UnitAttackPower(unit)
	local base, pos, neg = UnitAttackPower(unit)
	return base + pos + neg
end

local UnitRangedAttackPower = UnitRangedAttackPower
function Env.UnitRangedAttackPower(unit)
	local base, pos, neg = UnitRangedAttackPower(unit)
	return base + pos + neg
end

local GetSpellCritChance = GetSpellCritChance
function Env.GetSpellCritChance()
	return min(
		GetSpellCritChance(2),
		GetSpellCritChance(3),
		GetSpellCritChance(4),
		GetSpellCritChance(5),
		GetSpellCritChance(6),
		GetSpellCritChance(7)
	)
end

local GetSpellBonusDamage = GetSpellBonusDamage
function Env.GetSpellBonusDamage()
	return min(
		GetSpellBonusDamage(2),
		GetSpellBonusDamage(3),
		GetSpellBonusDamage(4),
		GetSpellBonusDamage(5),
		GetSpellBonusDamage(6),
		GetSpellBonusDamage(7)
	)
end

if MAX_SPELL_SCHOOLS ~= 7 then
	TMW:Error("MAX_SPELL_SCHOOLS has changed, so the spell school dependent conditions need updating")
end

local PetModes = {
	clientVersion >= 40200 and "PET_MODE_ASSIST" or "PET_MODE_AGGRESSIVE",
	"PET_MODE_DEFENSIVE",
	"PET_MODE_PASSIVE",
}
for k, v in pairs(PetModes) do PetModes[v] = k end
function Env.GetActivePetMode()
	for i = NUM_PET_ACTION_SLOTS, 1, -1 do -- go backwards since they are probably at the end of the action bar
		local name, _, _, isToken, isActive = GetPetActionInfo(i)
		if isToken and isActive and PetModes[name] then
			return PetModes[name]
		end
	end
end



local function formatSeconds(seconds, arg2)
	if type(seconds) == "table" then -- if i set it directly as a metamethod
		seconds = arg2
	end
	local y =  seconds / 31556925.9936
	local d = (seconds % 31556925.9936) / 86400
	local h = (seconds % 31556925.9936 % 86400) / 3600
	local m = (seconds % 31556925.9936 % 86400  % 3600) / 60
	local s = (seconds % 31556925.9936 % 86400  % 3600  % 60)

	s = tonumber(format("%.1f", s))
	if s < 10 then
		s = "0" .. s
	end

	if y >= 1 then return format("%d:%d:%02d:%02d:%s", y, d, h, m, s) end
	if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, s) end
	if h >= 1 then return format("%d:%02d:%s", h, m, s) end
	return format("%d:%s", m, s)
end

-- preset text tables that are frequently used
local commanumber = function(k)
	k = gsub(k, "(%d)(%d%d%d)$", "%1,%2", 1)
	local found
	repeat
		k, found = gsub(k, "(%d)(%d%d%d),", "%1,%2,", 1)
	until found == 0

	return k
end
local percent = function(k) return k.."%" end
local pluspercent = function(k) return "+"..k.."%" end
local bool = {[0] = L["TRUE"],[1] = L["FALSE"],}
local usableunusable = {[0] = L["ICONMENU_USABLE"],[1] = L["ICONMENU_UNUSABLE"],}
local presentabsent = {[0] = L["ICONMENU_PRESENT"],[1] = L["ICONMENU_ABSENT"],}
local absentseconds = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = formatSeconds})
local usableseconds = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_USABLE"]..")"}, {__index = formatSeconds})
local standardtcoords = {0.07, 0.93, 0.07, 0.93}


CNDT.Types = {
-------------------------------------resources
	{ -- health
		text = HEALTH,
		value = "HEALTH",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_alchemy_elixir_05",
		tcoords = standardtcoords,
		funcstr = [[UnitHealth(c.Unit)/(UnitHealthMax(c.Unit)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXHEALTH", c.Unit)
		end,
	},
	{ -- primary resource
		text = L["CONDITIONPANEL_POWER"],
		tooltip = L["CONDITIONPANEL_POWER_DESC"],
		value = "DEFAULT",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_alchemy_elixir_02",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit)/(UnitPowerMax(c.Unit)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_DISPLAYPOWER", c.Unit)
		end,
	},
	{ -- mana
		text = MANA,
		value = "MANA",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_potion_126",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 0)/(UnitPowerMax(c.Unit, 0)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- energy
		text = ENERGY,
		value = "ENERGY",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_potion_125",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 3)/(UnitPowerMax(c.Unit, 3)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- rage
		text = RAGE,
		value = "RAGE",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_potion_120",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 1)/(UnitPowerMax(c.Unit, 1)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- focus
		text = FOCUS,
		value = "FOCUS",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_potion_124",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 2)/(UnitPowerMax(c.Unit, 2)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- runic power
		text = RUNIC_POWER,
		value = "RUNIC_POWER",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\inv_potion_128",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 6)/(UnitPowerMax(c.Unit, 6)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- alternate power (atramedes, chogall, etc)
		text = L["CONDITIONPANEL_ALTPOWER"],
		tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
		value = "ALTPOWER",
		category = L["CNDTCAT_RESOURCES"],
		percent = true,
		texttable = percent,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\spell_shadow_mindflay",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 10)/(UnitPowerMax(c.Unit, 10)+epsilon) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", c.Unit)
		end,
		spaceafter = true,
	},

	{ -- soul shards
		text = SOUL_SHARDS,
		value = "SOUL_SHARDS",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 3,
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 7) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER", c.Unit)
		end,
		hidden = pclass ~= "WARLOCK",
	},
	{ -- holy power
		text = HOLY_POWER,
		value = "HOLY_POWER",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 3,
		unit = PLAYER,
		icon = "Interface\\Icons\\Spell_Holy_Rune",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 9) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER", c.Unit)
		end,
		hidden = pclass ~= "PALADIN",
	},
	{ -- eclipse
		text = ECLIPSE,
		tooltip = L["CONDITIONPANEL_ECLIPSE_DESC"],
		value = "ECLIPSE",
		category = L["CNDTCAT_RESOURCES"],
		min = -100,
		max = 100,
		mint = "-100 (" .. L["MOON"] .. ")",
		maxt = "100 (" .. L["SUN"] .. ")",
		unit = PLAYER,
		icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
		tcoords = {0.65625000, 0.74609375, 0.37500000, 0.55468750},
		funcstr = [[UnitPower(c.Unit, 8) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER", c.Unit)
		end,
		hidden = pclass ~= "DRUID",
	},
	{ -- eclipse direction
		text = L["ECLIPSE_DIRECTION"],
		value = "ECLIPSE_DIRECTION",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 1,
		texttable = {[0] = L["MOON"], [1] = L["SUN"]},
		unit = PLAYER,
		nooperator = true,
		icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
		tcoords = {0.55859375, 0.64843750, 0.57031250, 0.75000000},
		funcstr = [[c.Level == (GetEclipseDirection() == "sun" and 1 or 0)]],
		hidden = pclass ~= "DRUID",
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("ECLIPSE_DIRECTION_CHANGE")
		end,
	},
	{ -- pet happiness
		text = HAPPINESS,
		value = "HAPPINESS",
		category = L["CNDTCAT_RESOURCES"],
		min = 1,
		max = 3,
		midt = true,
		texttable = function(k) return _G["PET_HAPPINESS" .. k] end,
		unit = PET,
		icon = "Interface\\PetPaperDollFrame\\UI-PetHappiness",
		tcoords = {0.390625, 0.5491, 0.03, 0.3305},
		funcstr = GetPetHappiness and [[(GetPetHappiness() or 0) c.Operator c.Level]] or [[true]], -- dummy string to keep support for wowCN
		hidden = not GetPetHappiness or pclass ~= "HUNTER", -- dont show if GetPetHappiness doesnt exist (if happiness is removed in the client version), not not because it must be false, not nil
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString("pet"),
				ConditionObj:GenerateNormalEventString("UNIT_HAPPINESS", "pet"),
				ConditionObj:GenerateNormalEventString("UNIT_POWER", "pet")
		end,
	},
	{ -- runes
		text = RUNES,
		tooltip = L["CONDITIONPANEL_RUNES_DESC"],
		value = "RUNES",
		category = L["CNDTCAT_RESOURCES"],
		unit = false,
		nooperator = true,
		noslide = true,
		icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
		showhide = function(group)
			group.Runes:Show()
		end,
		funcstr = function(c) -- sub-constructor function
			local str = ""
			for k, v in pairs(c.Runes) do
				if v ~= nil then
					str = str .. "and" .. (v==false and " not" or "")
					if k > 6 then
						k=k-6
						str = str .. [[(GetRuneType(]]..k..[[)==4 and GetRuneCount(]]..k..[[)==1)]]
					else
						str = str .. [[(GetRuneCount(]]..k..[[)==1)]]
					end
				end
			end
			if str ~= "" then
				return strsub(str, 4) -- remove the first 'and'
			else
				return [[true]] -- just a cheesy error prevention if no runes are checked
			end
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("RUNE_POWER_UPDATE"),
				ConditionObj:GenerateNormalEventString("RUNE_TYPE_UPDATE")
		end,
		hidden = pclass ~= "DEATHKNIGHT",
	},
	{ -- combo
		text = L["CONDITIONPANEL_COMBO"],
		value = "COMBO",
		category = L["CNDTCAT_RESOURCES"],
		defaultUnit = "target",
		min = 0,
		max = 5,
		icon = "Interface\\Icons\\ability_rogue_eviscerate",
		tcoords = standardtcoords,
		funcstr = [[GetComboPoints("player", c.Unit) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_COMBO_POINTS", "player")
		end,
	},
	{ -- shadow orbs
		text = SHADOW_ORBS,
		value = "SHADOW_ORBS",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 3,
		unit = PLAYER,
		icon = "Interface\\Icons\\Spell_Priest_Shadoworbs",
		tcoords = standardtcoords,
		funcstr = [[UnitPower("player", 13) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_POWER", "player")
		end,
		hidden = pclass ~= "PRIEST" or not TMW.ISMOP,
	},
	{ -- chi
		text = CHI_POWER,
		value = "CHI",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 5,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_monk_chiwave",
		tcoords = standardtcoords,
		funcstr = [[UnitPower("player", 12) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_POWER", "player")
		end,
		hidden = pclass ~= "MONK",
	},
	{ -- burning embers (whole embers)
		text = BURNING_EMBERS,
		value = "BURNING_EMBERS",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 4,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_warlock_burningembers",
		tcoords = standardtcoords,
		funcstr = [[UnitPower("player", 14, false) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_POWER", "player")
		end,
		hidden = pclass ~= "WARLOCK" or not TMW.ISMOP,
	},
	{ -- burning embers (ember "fragments")
		text = L["BURNING_EMBERS_FRAGMENTS"],
		tooltip = L["BURNING_EMBERS_FRAGMENTS_DESC"],
		value = "BURNING_EMBERS_FRAGMENTS",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 40,
		unit = PLAYER,
		icon = "Interface\\Icons\\INV_Elemental_Mote_Fire01",
		tcoords = standardtcoords,
		funcstr = [[UnitPower("player", 14, true) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_POWER", "player")
		end,
		hidden = pclass ~= "WARLOCK" or not TMW.ISMOP,
	},
	{ -- demonic fury
		text = DEMONIC_FURY,
		value = "DEMONIC_FURY",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 1000,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_Warlock_Eradication",
		tcoords = standardtcoords,
		funcstr = [[UnitPower("player", 15, true) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_POWER", "player")
		end,
		hidden = pclass ~= "WARLOCK" or not TMW.ISMOP,
	},
	
	{ -- abs health
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. HEALTH,
		value = "HEALTH_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 1000000,
		step = 1,
		icon = "Interface\\Icons\\inv_alchemy_elixir_05",
		tcoords = standardtcoords,
		funcstr = [[UnitHealth(c.Unit) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", c.Unit)
		end,
		spacebefore = true,
	},
	{ -- abs primary resource
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. L["CONDITIONPANEL_POWER"],
		tooltip = L["CONDITIONPANEL_POWER_DESC"],
		value = "DEFAULT_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 40000,
		step = 1,
		icon = "Interface\\Icons\\inv_alchemy_elixir_02",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_DISPLAYPOWER", c.Unit)
		end,
	},
	{ -- abs mana
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. MANA,
		value = "MANA_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 40000,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_126",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 0) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit)
		end,
	},
	{ -- abs energy
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. ENERGY,
		value = "ENERGY_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_125",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 3) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit)
		end,
	},
	{ -- abs rage
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. RAGE,
		value = "RAGE_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_120",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit)
		end,
	},
	{ -- abs focus
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. FOCUS,
		value = "FOCUS_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_124",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 2) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit)
		end,
	},
	{ -- abs runic power
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. RUNIC_POWER,
		value = "RUNIC_POWER_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_128",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 6) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit)
		end,
	},
	{ -- abs alternate power (atramedes, chogall, etc)
		text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
		tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
		value = "ALTPOWER_ABS",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\spell_shadow_mindflay",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 10) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", c.Unit)
		end,
	},

	{ -- max health
		text = L["CONDITIONPANEL_MAX"] .. " " .. HEALTH,
		value = "HEALTH_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 1000000,
		step = 100,
		icon = "Interface\\Icons\\inv_alchemy_elixir_05",
		tcoords = standardtcoords,
		funcstr = [[UnitHealthMax(c.Unit) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXHEALTH", c.Unit)
		end,
		spacebefore = true,
	},
	{ -- max primary resource
		text = L["CONDITIONPANEL_MAX"] .. " " .. L["CONDITIONPANEL_POWER"],
		tooltip = L["CONDITIONPANEL_POWER_DESC"],
		value = "DEFAULT_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 40000,
		step = 100,
		icon = "Interface\\Icons\\inv_alchemy_elixir_02",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXHEALTH", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_DISPLAYPOWER", c.Unit)
		end,
	},
	{ -- max mana
		text = L["CONDITIONPANEL_MAX"] .. " " .. MANA,
		value = "MANA_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 40000,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_126",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit, 0) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- max energy
		text = L["CONDITIONPANEL_MAX"] .. " " .. ENERGY,
		value = "ENERGY_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_125",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit, 3) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- max rage
		text = L["CONDITIONPANEL_MAX"] .. " " .. RAGE,
		value = "RAGE_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_120",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit, 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- max focus
		text = L["CONDITIONPANEL_MAX"] .. " " .. FOCUS,
		value = "FOCUS_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_124",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit, 2) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- max runic power
		text = L["CONDITIONPANEL_MAX"] .. " " .. RUNIC_POWER,
		value = "RUNIC_POWER_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\inv_potion_128",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit, 6) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit)
		end,
	},
	{ -- max alternate power (atramedes, chogall, etc)
		text = L["CONDITIONPANEL_MAX"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
		tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
		value = "ALTPOWER_MAX",
		category = L["CNDTCAT_RESOURCES"],
		texttable = commanumber,
		range = 200,
		step = 1,
		icon = "Interface\\Icons\\spell_shadow_mindflay",
		tcoords = standardtcoords,
		funcstr = [[UnitPowerMax(c.Unit, 10) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_MAXPOWER", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", c.Unit)
		end,
	},


-------------------------------------unit status/attributes
	{ -- exists
		text = L["CONDITIONPANEL_EXISTS"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
	--	categorySpacebefore = true,
		value = "EXISTS",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\ABILITY_SEAL",
		tcoords = standardtcoords,
		funcstr = function(c)
			if c.Unit == "player" then
				return [[true]]
			else
				return [[c.1nil == UnitExists(c.Unit)]]
			end
		end,
		events = function(ConditionObj, c)
			--if c.Unit == "mouseover" then -- there is no event for when you are no longer mousing over a unit, so we cant use this
			--	return "UPDATE_MOUSEOVER_UNIT"
			--else
				return
					ConditionObj:GetUnitChangedEventString(c.Unit) -- this should work
			--end
		end,
	},
	{ -- alive
		text = L["CONDITIONPANEL_ALIVE"],
		tooltip = L["CONDITIONPANEL_ALIVE_DESC"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "ALIVE",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\Ability_Vanish",
		tcoords = standardtcoords,
		funcstr = [[c.nil1 == UnitIsDeadOrGhost(c.Unit)]], -- note usage of nil1, not 1nil
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_HEALTH", c.Unit)
		end,
	},
	{ -- combat
		text = L["CONDITIONPANEL_COMBAT"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "COMBAT",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\CharacterFrame\\UI-StateIcon",
		tcoords = {0.53, 0.92, 0.05, 0.42},
		funcstr = function(c)
			return [[c.1nil == UnitAffectingCombat(c.Unit)]]
		end,
		events = function(ConditionObj, c)
			if c.Unit == "player" then
				return
					ConditionObj:GenerateNormalEventString("PLAYER_REGEN_ENABLED"),
					ConditionObj:GenerateNormalEventString("PLAYER_REGEN_DISABLED")
			else
				return
					ConditionObj:GetUnitChangedEventString(c.Unit),
					ConditionObj:GenerateNormalEventString("UNIT_FLAGS", c.Unit),
					ConditionObj:GenerateNormalEventString("UNIT_DYNAMIC_FLAGS", c.Unit) -- idk if UNIT_DYNAMIC_FLAGS is needed. but lets do it anyway.
			end
		end,
	},
	{ -- controlling vehicle
		text = L["CONDITIONPANEL_VEHICLE"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "VEHICLE",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\Ability_Vehicle_SiegeEngineCharge",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[c.True == UnitHasVehicleUI(c.Unit)]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_ENTERED_VEHICLE", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_EXITED_VEHICLE", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_VEHICLE", c.Unit)
		end,
	},
	{ -- pvp
		text = L["CONDITIONPANEL_PVPFLAG"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "PVPFLAG",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\TargetingFrame\\UI-PVP-" .. UnitFactionGroup("player"),
		tcoords = {0.046875, 0.609375, 0.015625, 0.59375},
		funcstr = [[c.1nil == UnitIsPVP(c.Unit)]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_FACTION", c.Unit)
		end,
	},
	{ -- react
		text = L["ICONMENU_REACT"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "REACT",
		min = 1,
		max = 2,
		texttable = {[1] = L["ICONMENU_HOSTILE"], [2] = L["ICONMENU_FRIEND"]},
		nooperator = true,
		icon = "Interface\\Icons\\Warrior_talent_icon_FuryInTheBlood",
		tcoords = standardtcoords,
		funcstr = [[(((UnitIsEnemy("player", c.Unit) or ((UnitReaction("player", c.Unit) or 5) <= 4)) and 1) or 2) == c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_FLAGS", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_DYNAMIC_FLAGS", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_FLAGS", "player"),
				ConditionObj:GenerateNormalEventString("UNIT_DYNAMIC_FLAGS", "player")
		end,
	},
	{ -- speed
		text = L["SPEED"],
		tooltip = L["SPEED_DESC"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "SPEED",
		min = 0,
		max = 500,
		percent = true,
		texttable = percent,
		icon = "Interface\\Icons\\ability_rogue_sprint",
		tcoords = standardtcoords,
		funcstr = [[GetUnitSpeed(c.Unit)/]].. BASE_MOVEMENT_SPEED ..[[ c.Operator c.Level]],
		-- events = absolutely no events
	},
	{ -- runspeed
		text = L["RUNSPEED"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "RUNSPEED",
		min = 0,
		max = 500,
		percent = true,
		texttable = percent,
		icon = "Interface\\Icons\\ability_rogue_sprint",
		tcoords = standardtcoords,
		funcstr = [[select(2, GetUnitSpeed(c.Unit))/]].. BASE_MOVEMENT_SPEED ..[[ c.Operator c.Level]],
		-- events = absolutely no events
	},
	{ -- name
		text = L["CONDITIONPANEL_NAME"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "NAME",
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_NAMETOMATCH", "CONDITIONPANEL_NAMETOOLTIP") editbox.label = L["CONDITIONPANEL_NAMETOMATCH"] end,
		nooperator = true,
		texttable = bool,
		icon = "Interface\\LFGFrame\\LFGFrame-SearchIcon-Background",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == (strfind(c.Name, SemicolonConcatCache[UnitName(c.Unit) or ""]) and 1)]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_NAME_UPDATE", c.Unit)
		end,
	},
	{ -- level
		text = L["CONDITIONPANEL_LEVEL"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "LEVEL",
		min = -1,
		max = 90,
		texttable = {[-1] = BOSS},
		icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
		tcoords = {0.05, 0.95, 0.03, 0.97},
		funcstr = [[UnitLevel(c.Unit) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_LEVEL", c.Unit)
		end,
	},
	{ -- class
		text = L["CONDITIONPANEL_CLASS"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "CLASS",
		min = 1,
		max = #Classes,
		texttable = function(k) return Classes[k] and LOCALIZED_CLASS_NAMES_MALE[Classes[k]] end,
		icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
		nooperator = true,
		tcoords = {
			CLASS_ICON_TCOORDS[pclass][1]+.02,
			CLASS_ICON_TCOORDS[pclass][2]-.02,
			CLASS_ICON_TCOORDS[pclass][3]+.02,
			CLASS_ICON_TCOORDS[pclass][4]-.02,
		},
		funcstr = function(c)
			return [[select(2, UnitClass(c.Unit)) == "]] .. (Classes[c.Level] or "whoops") .. "\""
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit) -- classes cant change, so this is all we should need
		end,
	},
	{ -- classification
		text = L["CONDITIONPANEL_CLASSIFICATION"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "CLASSIFICATION",
		min = 1,
		max = #classifications,
		texttable = function(k) return L[classifications[k]] end,
		icon = "Interface\\Icons\\achievement_pvp_h_03",
		tcoords = standardtcoords,
		funcstr = [[(classifications[UnitClassification(c.Unit)] or 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_CLASSIFICATION_CHANGED", c.Unit)
		end,
	},
	{ -- role
		text = L["CONDITIONPANEL_ROLE"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "ROLE",
		min = 1,
		max = #roles,
		texttable = setmetatable({[1]=NONE}, {__index = function(t, k) return L[roles[k]] end}),
		icon = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES",
		tcoords = {GetTexCoordsForRole("DAMAGER")},
		funcstr = [[(roles[UnitGroupRolesAssigned(c.Unit)] or 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			-- the unit change events should actually cover many of the changes (at least for party and raid units, but roles only exist in party and raid anyway.)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("PLAYER_ROLES_ASSIGNED"),
				ConditionObj:GenerateNormalEventString("ROLE_CHANGED_INFORM")
		end,


	},
	{ -- raid icon
		text = L["CONDITIONPANEL_RAIDICON"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "RAIDICON",
		min = 0,
		max = 8,
		texttable = setmetatable({[0]=NONE}, {__index = function(t, k) return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..k..":0|t ".._G["RAID_TARGET_"..k] end}),
		icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
		funcstr = [[(GetRaidTargetIndex(c.Unit) or 0) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("RAID_TARGET_UPDATE")
		end,
	},
	{ -- unit is unit
		text = L["CONDITIONPANEL_UNITISUNIT"],
		tooltip = L["CONDITIONPANEL_UNITISUNIT_DESC"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "UNITISUNIT",
		min = 0,
		max = 1,
		nooperator = true,
		name = function(editbox) TMW:TT(editbox, "UNITTWO", "CONDITIONPANEL_UNITISUNIT_EBDESC") editbox.label = L["UNITTWO"] end,
		texttable = bool,
		icon = "Interface\\Icons\\spell_holy_prayerofhealing",
		tcoords = standardtcoords,
		funcstr = [[UnitIsUnit(c.Unit, c.Unit2) == c.1nil]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GetUnitChangedEventString(c.Name)
		end,
	},
	{ -- unit threat scaled
		text = L["CONDITIONPANEL_THREAT_SCALED"],
		tooltip = L["CONDITIONPANEL_THREAT_SCALED_DESC"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "THREATSCALED",
		min = 0,
		max = 100,
		texttable = percent,
		icon = "Interface\\Icons\\spell_misc_emotionangry",
		tcoords = standardtcoords,
		funcstr = [[(select(3, UnitDetailedThreatSituation("player", c.Unit)) or 0) c.Operator c.Level]],
		-- events = absolutely no events
	},
	{ -- unit threat raw
		text = L["CONDITIONPANEL_THREAT_RAW"],
		tooltip = L["CONDITIONPANEL_THREAT_RAW_DESC"],
		category = L["CNDTCAT_ATTRIBUTES_UNIT"],
		value = "THREATRAW",
		min = 0,
		max = 130,
		texttable = percent,
		icon = "Interface\\Icons\\spell_misc_emotionhappy",
		tcoords = standardtcoords,
		funcstr = [[(select(4, UnitDetailedThreatSituation("player", c.Unit)) or 0) c.Operator c.Level]],
		-- events = absolutely no events
	},


-------------------------------------player status/attributes
	{ -- instance type
		text = L["CONDITIONPANEL_INSTANCETYPE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "INSTANCE",
		min = 0,
		max = 8,
		unit = false,
		texttable = {
			[0] = NONE,
			[1] = BATTLEGROUND,
			[2] = ARENA,
			[3] = DUNGEON_DIFFICULTY1,
			[4] = DUNGEON_DIFFICULTY2,
			[5] = RAID_DIFFICULTY1,
			[6] = RAID_DIFFICULTY2,
			[7] = RAID_DIFFICULTY3,
			[8] = RAID_DIFFICULTY4,
		},
		icon = "Interface\\Icons\\Spell_Frost_Stun",
		tcoords = standardtcoords,
		funcstr = [[GetZoneType() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("ZONE_CHANGED_NEW_AREA"),
				ConditionObj:GenerateNormalEventString("PLAYER_DIFFICULTY_CHANGED")
		end,
	},
	{ -- grouptype
		text = L["CONDITIONPANEL_GROUPTYPE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "GROUP",
		min = 0,
		max = 2,
		midt = true,
		unit = false,
		texttable = {[0] = SOLO, [1] = PARTY, [2] = RAID},
		icon = "Interface\\Calendar\\MeetingIcon",
		tcoords = standardtcoords,
		funcstr = TMW.ISMOP and [[((IsInRaid() and 2) or (IsInGroup() and 1) or 0) c.Operator c.Level]] or
			[[((GetNumRaidMembers() > 0 and 2) or (GetNumPartyMembers() > 0 and 1) or 0) c.Operator c.Level]], -- this one was harder than it should have been to figure out; keep it in mind for future condition creating
		Env = {
			IsInRaid = IsInRaid,
			IsInGroup = IsInGroup,
			GetNumRaidMembers = GetNumRaidMembers,
			GetNumPartyMembers = GetNumPartyMembers,
		},
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PARTY_MEMBERS_CHANGED"),
				ConditionObj:GenerateNormalEventString("RAID_ROSTER_UPDATE")
		end,
	},
	{ -- mounted
		text = L["CONDITIONPANEL_MOUNTED"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "MOUNTED",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_Mount_Charger",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsMounted()]],
	},
	{ -- swimming
		text = L["CONDITIONPANEL_SWIMMING"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "SWIMMING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsSwimming()]],
		--events = absolutely no events (SPELL_UPDATE_USABLE is close, but not close enough)
	},
	{ -- resting
		text = L["CONDITIONPANEL_RESTING"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "RESTING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\CHARACTERFRAME\\UI-StateIcon",
		tcoords = {0.0625, 0.453125, 0.046875, 0.421875},
		funcstr = [[c.1nil == IsResting()]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_UPDATE_RESTING"),
				ConditionObj:GenerateNormalEventString("PLAYER_ENTERING_WORLD")
		end,
	},
	{ -- stance
		text = 	pclass == "HUNTER" and L["ASPECT"] or
				pclass == "PALADIN" and L["AURA"] or
				pclass == "DEATHKNIGHT" and L["PRESENCE"] or
				pclass == "DRUID" and L["SHAPESHIFT"] or
				--pclass == "WARRIOR" and L["STANCE"] or
				--pclass == "MONK" and L["STANCE"] or
				L["STANCE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "STANCE",
		min = 0,
		max = #TMW.CSN,
		texttable = TMW.CSN, -- now isn't this convenient? too bad i have to track them by ID so they wont upgrade properly when stances are added/removed
		unit = PLAYER,
		icon = function()
			return firststanceid and GetSpellTexture(firststanceid)
		end,
		tcoords = standardtcoords,
		funcstr = [[GetShapeshiftForm() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UPDATE_SHAPESHIFT_FORM")
		end,
		hidden = #TMW.CSN == 0,
	},
	{ -- talent spec
		text = L["UIPANEL_SPEC"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "SPEC",
		min = 1,
		max = 2,
		texttable = {
			[1] = L["UIPANEL_PRIMARYSPEC"],
			[2] = L["UIPANEL_SECONDARYSPEC"],
		},
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\Icons\\achievement_general",
		tcoords = standardtcoords,
		Env = {
			GetActiveTalentGroup = GetActiveTalentGroup,
			GetActiveSpecGroup = GetActiveSpecGroup, --ISMOP
		},
		funcstr = TMW.ISMOP and [[c.Level == GetActiveSpecGroup()]] or [[c.Level == GetActiveTalentGroup()]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObj:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	},
	TMW.ISMOP and { -- active specialization
		text = L["UIPANEL_SPECIALIZATION"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "TREE",
		min = 1,
		max = 3,
		midt = true,
		texttable = function(i) return select(2, GetSpecializationInfo(i)) end,
		unit = PLAYER,
		icon = function() return select(4, GetSpecializationInfo(1)) end,
		tcoords = standardtcoords,
		funcstr = [[(GetSpecialization() or 0) c.Operator c.Level]],
		Env = {
			GetSpecialization = GetSpecialization
		},
	--	events = function(ConditionObj, c)
	--		--TODO: probably wrong events
	--		return
	--			ConditionObj:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
	--			ConditionObj:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	--	end,
	} or { -- talent tree
		text = L["UIPANEL_TREE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "TREE",
		min = 1,
		max = 3,
		midt = true,
		texttable = function(i) return select(2, GetTalentTabInfo(i)) end, --MOP DEPRECIATED, COMPAT CODE IN PLACE
		unit = PLAYER,
		icon = function() return select(4, GetTalentTabInfo(1)) end, --MOP DEPRECIATED, COMPAT CODE IN PLACE 
		tcoords = standardtcoords,
		funcstr = [[GetPrimaryTalentTree() c.Operator c.Level]],
		Env = {
			GetPrimaryTalentTree = GetPrimaryTalentTree
		},
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObj:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	},
	{ -- talent learned
		text = L["UIPANEL_TALENTLEARNED"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "TALENTLEARNED",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = "talents",
		icon = function() return select(2, GetTalentInfo(1)) end,
		tcoords = standardtcoords,
		hidden = not TMW.ISMOP,
		funcstr = [[TalentMap[LOWER(c.NameName)] == c.1nil]],
		events = function(ConditionObj, c)
			-- this is handled externally because TalentMap is so extensive a process,
			-- and if it does get stuck in an OnUpdate condition, it could be very bad.
			CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
			CNDT:PLAYER_TALENT_UPDATE()
			
			-- we still only need to update the condition when talents change, though.
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObj:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	},
	{ -- points in talent
		text = L["UIPANEL_PTSINTAL"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "PTSINTAL",
		min = 0,
		max = 5,
		unit = PLAYER,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = "talents",
		icon = function() return select(2, GetTalentInfo(1, 1)) end,
		tcoords = standardtcoords,
		hidden = TMW.ISMOP,
		funcstr = function(c)
			-- Brilliant hack that will automatically upgrade to the MOP version of the condition when it is processed.
			-- This upgrade is kinda bad because we went from a number comparison to a boolean check, but we should at least put the level down to a valid value.
			-- Users are going to need to redo their conditions anyway for gameplay reasons, so I'm not to worried about a poor upgrade here.
			if TMW.ISMOP then
				c.Type = "TALENTLEARNED"
				if c.Level > 1 then
					c.Level = 0
				end
				return CNDT.ConditionsByType.TALENTLEARNED.funcstr
			else
				return [[(TalentMap[LOWER(c.NameName)] or 0) c.Operator c.Level]]
			end
		end,
		events = function(ConditionObj, c)
			-- this is handled externally because TalentMap is so extensive a process,
			-- and if it does get stuck in an OnUpdate condition, it could be very bad.
			CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
			CNDT:PLAYER_TALENT_UPDATE()
			-- we still only need to update the condition when talents change, though.
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObj:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	},
	{ -- glyph
		text = L["UIPANEL_GLYPH"],
		tooltip = L["UIPANEL_GLYPH_DESC"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "GLYPH",
		min = 0,
		max = 1,
		texttable = bool,
		unit = PLAYER,
		name = function(editbox) TMW:TT(editbox, "GLYPHTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["GLYPHTOCHECK"] end,
		nooperator = true,
		useSUG = "glyphs",
		icon = "inv_inscription_tradeskill01",
		tcoords = standardtcoords,
		funcstr = [[GlyphLookup[c.NameFirst] == c.True]],
		events = function(ConditionObj, c)
			-- this is handled externally because GlyphLookup is so extensive a process,
			-- and if it does get stuck in an OnUpdate condition, it could be very bad.
	
			CNDT:RegisterEvent("GLYPH_ADDED", 	 "GLYPH_UPDATED")
			CNDT:RegisterEvent("GLYPH_DISABLED", "GLYPH_UPDATED")
			CNDT:RegisterEvent("GLYPH_ENABLED",  "GLYPH_UPDATED")
			CNDT:RegisterEvent("GLYPH_REMOVED",  "GLYPH_UPDATED")
			CNDT:RegisterEvent("GLYPH_UPDATED",  "GLYPH_UPDATED")
			CNDT:GLYPH_UPDATED()
			-- we still only need to update the condition when glyphs change, though.
			
			return
				ConditionObj:GenerateNormalEventString("GLYPH_ADDED"),
				ConditionObj:GenerateNormalEventString("GLYPH_DISABLED"),
				ConditionObj:GenerateNormalEventString("GLYPH_ENABLED"),
				ConditionObj:GenerateNormalEventString("GLYPH_REMOVED"),
				ConditionObj:GenerateNormalEventString("GLYPH_UPDATED")
		end,
	},
	{ -- pet autocast
		text = L["CONDITIONPANEL_AUTOCAST"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "AUTOCAST",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PET,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_AUTOCAST", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = true,
		icon = "Interface\\Icons\\ability_physical_taunt",
		tcoords = standardtcoords,
		funcstr = [[select(2, GetSpellAutocast(c.NameName)) == c.1nil]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PET_BAR_UPDATE")
		end,
	},
	{ -- pet attack mode
		text = L["CONDITIONPANEL_PETMODE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "PETMODE",
		min = 1,
		max = 3,
		midt = true,
		texttable = function(k) return _G[PetModes[k]] end,
		unit = PET,
		icon = PET_ASSIST_TEXTURE,
		tcoords = standardtcoords,
		funcstr = [[GetActivePetMode() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PET_BAR_UPDATE")
		end,
	},
	{ -- pet talent spec
		text = L["CONDITIONPANEL_PETSPEC"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "PETSPEC",
		min = 0,
		max = 3,
		midt = true,
		texttable = {
			[0] = NONE,
			L["PET_TYPE_FEROCITY"],
			L["PET_TYPE_TENACITY"],
			L["PET_TYPE_CUNNING"],
		},
		unit = PET,
		icon = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
		tcoords = standardtcoords,
		funcstr = [[(GetSpecialization(nil, true) or 0) c.Operator c.Level]],
		Env = {
			GetSpecialization = GetSpecialization
		},
		hidden = not TMW.ISMOP,
		--events = function(ConditionObj, c)
		--MAYBE WRONG EVENTS, CHECK BEFORE UNCOMMENTING
		--	return
		--		ConditionObj:GenerateNormalEventString("UNIT_PET", "player")
		--end,
	},
	{ -- pet talent tree
		text = L["CONDITIONPANEL_PETTREE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "PETTREE",
		min = 409,
		max = 411,
		midt = true,
		texttable = {
			[409] = L["PET_TYPE_TENACITY"],
			[410] = L["PET_TYPE_FEROCITY"],
			[411] = L["PET_TYPE_CUNNING"],
		},
		unit = PET,
		icon = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
		tcoords = standardtcoords,
		funcstr = function(c)
			-- Brilliant hack that will automatically upgrade to the MOP version of the condition when it is processed.
			if TMW.ISMOP then
				c.Type = "PETSPEC"
				
				if c.Level == 409 then -- old tenacity
					c.Level = 2 -- new tenacity
				elseif c.Level == 410 then -- old ferocity
					c.Level = 1 -- new ferocity
				elseif c.Level == 411 then -- old cunning
					c.Level = 3 -- new cunning
				end
				
				return CNDT.ConditionsByType.PETSPEC.funcstr
			else
				return [[(GetTalentTabInfo(1, nil, 1) or 0) c.Operator c.Level]] --MOP DEPRECIATED, COMPAT CODE IN PLACE 
			end
		end,
		Env = {
			GetTalentTabInfo = GetTalentTabInfo
		},
		hidden = TMW.ISMOP,
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_PET", "player")
		end,
	},
	{ -- tracking
		text = L["CONDITIONPANEL_TRACKING"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "TRACKING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_TRACKING", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = "tracking",
		icon = "Interface\\MINIMAP\\TRACKING\\None",
		tcoords = standardtcoords,
		funcstr = [[Tracking[c.NameName] == c.1nil]],
		events = function(ConditionObj, c)
			-- keep this event based because it is so extensive
			CNDT:RegisterEvent("MINIMAP_UPDATE_TRACKING")
			CNDT:MINIMAP_UPDATE_TRACKING()
			
			return
				ConditionObj:GenerateNormalEventString("MINIMAP_UPDATE_TRACKING")
		end,
	},


-------------------------------------spells/items
	{ -- spell cooldown
		text = L["SPELLCOOLDOWN"],
		value = "SPELLCD",
		category = L["CNDTCAT_SPELLSABILITIES"],
		categorySpacebefore = true,
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = "spellWithGCD",
		unit = PLAYER,
		texttable = usableseconds,
		icon = "Interface\\Icons\\spell_holy_divineintervention",
		tcoords = standardtcoords,
		funcstr = [[CooldownDuration(c.NameFirst) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_USABLE")
		end,
		anticipate = [[
			local start, duration = GetSpellCooldown(c.GCDReplacedNameFirst)
			local VALUE = duration and start + (duration - c.Level) or huge
		]],
	},
	{ -- spell cooldown compare
		text = L["SPELLCOOLDOWN"] .. " - " .. L["COMPARISON"],
		value = "SPELLCDCOMP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCOMP1"] end,
		name2 = function(editbox) TMW:TT(editbox, "SPELLTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCOMP2"] end,
		useSUG = "spellWithGCD",
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_divineintervention",
		tcoords = standardtcoords,
		funcstr = [[CooldownDuration(c.NameFirst) c.Operator CooldownDuration(c.NameFirst2)]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_USABLE")
		end,
		-- what a shitty anticipate func
		anticipate = [[
			local start, duration = GetSpellCooldown(c.GCDReplacedNameFirst)
			local start2, duration2 = GetSpellCooldown(c.GCDReplacedNameFirst2)
			local VALUE
			if duration and duration2 then
				local v1, v2 = start + duration, start2 + duration2
				VALUE = v1 < v2 and v1 or v2
			elseif duration then
				VALUE = start + duration
			elseif duration2 then
				VALUE = start2 + duration2
			else
				VALUE = huge
			end
		]],
	},
	{ -- spell reactivity
		text = L["SPELLREACTIVITY"],
		tooltip = L["REACTIVECNDT_DESC"],
		value = "REACTIVE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "ICONMENU_REACTIVE", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		check = function(check) TMW:TT(check, "ICONMENU_IGNORENOMANA", "ICONMENU_IGNORENOMANA_DESC") end,
		useSUG = true,
		nooperator = true,
		unit = false,
		texttable = usableunusable,
		icon = "Interface\\Icons\\ability_warrior_revenge",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == ReactiveHelper(c.NameFirst, c.Checked)]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_USABLE")
		end,
	},
		{ -- spell has mana
		text = L["CONDITIONPANEL_MANAUSABLE"],
		value = "MANAUSABLE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_MANAUSABLE", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = true,
		nooperator = true,
		unit = false,
		texttable = usableunusable,
		icon = "Interface\\Icons\\inv_potion_137",
		tcoords = standardtcoords,
		funcstr = [[c.nil1 == SpellHasNoMana(c.NameFirst)]],
		Env = {
			SpellHasNoMana = TMW.SpellHasNoMana
		},
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_USABLE"),
				ConditionObj:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player")
		end,
	},
		{ -- spell range
		text = L["CONDITIONPANEL_SPELLRANGE"],
		value = "SPELLRANGE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_SPELLRANGE", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
		useSUG = true,
		nooperator = true,
		texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
		icon = "Interface\\Icons\\ability_hunter_snipershot",
		tcoords = standardtcoords,
		funcstr = function(c)
			return 1-c.Level .. [[ == (IsSpellInRange(c.NameName, c.Unit) or 0)]]
		end,
	},
	{ -- GCD active
		text = L["GCD_ACTIVE"],
		value = "GCD",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		nooperator = true,
		unit = PLAYER,
		texttable = bool,
		icon = "Interface\\Icons\\ability_hunter_steadyshot",
		tcoords = standardtcoords,
		funcstr = [[(TMW.GCD > 0 and TMW.GCD < 1.7) == c.True]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
				ConditionObj:GenerateNormalEventString("SPELL_UPDATE_USABLE")
		end,
		anticipate = [[
			local start, duration = GetSpellCooldown(TMW.GCDSpell)
			local VALUE = start + duration -- the time at which we need to update again. (when the GCD ends)
		]],
	},

	{ -- item cooldown
		text = L["ITEMCOOLDOWN"],
		value = "ITEMCD",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, L["ITEMCOOLDOWN"], "CNDT_ONLYFIRST", 1) editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		unit = PLAYER,
		texttable = usableseconds,
		icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
		tcoords = standardtcoords,
		funcstr = [[ItemCooldownDuration(c.ItemID) c.Operator c.Level]],
		spacebefore = true,
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("BAG_UPDATE_COOLDOWN")
		end,
		anticipate = [[
			local start, duration = GetItemCooldown(c.ItemID)
			local VALUE = duration and start + (duration - c.Level) or huge
		]],
	},
	{ -- item cooldown compare
		text = L["ITEMCOOLDOWN"] .. " - " .. L["COMPARISON"],
		value = "ITEMCDCOMP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "ITEMTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCOMP1"] end,
		name2 = function(editbox) TMW:TT(editbox, "ITEMTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCOMP2"] end,
		useSUG = "item",
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
		tcoords = standardtcoords,
		funcstr = [[ItemCooldownDuration(c.ItemID) c.Operator ItemCooldownDuration(c.ItemID2)]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("BAG_UPDATE_COOLDOWN")
		end,
		-- what a shitty anticipate func
		anticipate = [[
			local start, duration = GetItemCooldown(c.ItemID)
			local start2, duration2 = GetItemCooldown(c.ItemID2)
			local VALUE
			if duration and duration2 then
				local v1, v2 = start + duration, start2 + duration2
				VALUE = v1 < v2 and v1 or v2
			elseif duration then
				VALUE = start + duration
			elseif duration2 then
				VALUE = start2 + duration2
			else
				VALUE = huge
			end
		]],
	},
	{ -- item range
		text = L["CONDITIONPANEL_ITEMRANGE"],
		value = "ITEMRANGE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_ITEMRANGE", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		nooperator = true,
		texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
		icon = "Interface\\Icons\\ability_hunter_snipershot",
		tcoords = standardtcoords,
		funcstr = function(c)
			return 1-c.Level .. [[ == (IsItemInRange(c.ItemID, c.Unit) or 0)]]
		end,
		-- events = absolutely none
	},
	{ -- item in bags
		text = L["ITEMINBAGS"],
		value = "ITEMINBAGS",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 50,
		texttable = function(k) return format(ITEM_SPELL_CHARGES, k) end,
		name = function(editbox) TMW:TT(editbox, "ITEMINBAGS", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		unit = false,
		icon = "Interface\\Icons\\inv_misc_bag_08",
		tcoords = standardtcoords,
		funcstr = [[GetItemCount(c.ItemID, nil, 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("BAG_UPDATE"),
				ConditionObj:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
		end,
	},
	{ -- item equipped
		text = L["ITEMEQUIPPED"],
		value = "ITEMEQUIPPED",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		nooperator = true,
		texttable = bool,
		name = function(editbox) TMW:TT(editbox, "ITEMEQUIPPED", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		unit = false,
		icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsEquippedItem(c.ItemID)]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("BAG_UPDATE"),
				ConditionObj:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
		end,
	},

	{ -- totem1
		text = totems[1],
		value = "TOTEM1",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
		useSUG = true,
		allowMultipleSUGEntires = true,
		texttable = absentseconds,
		icon = totemtex[1],
		tcoords = standardtcoords,
		funcstr = [[TotemHelper(1, c.Name) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
		end,
		anticipate = function(c)
			return [[local VALUE = time + TotemHelper(1) - c.Level]]
		end,
		hidden = not totems[1],
		spacebefore = true,
	},
	{ -- totem2
		text = totems[2],
		value = "TOTEM2",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
		useSUG = true,
		allowMultipleSUGEntires = true,
		texttable = absentseconds,
		icon = totemtex[2],
		tcoords = standardtcoords,
		funcstr = [[TotemHelper(2, c.Name) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
		end,
		anticipate = function(c)
			return [[local VALUE = time + TotemHelper(2) - c.Level]]
		end,
		hidden = not totems[2],
	},
	{ -- totem3
		text = totems[3],
		value = "TOTEM3",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
		useSUG = true,
		allowMultipleSUGEntires = true,
		texttable = absentseconds,
		icon = totemtex[3],
		tcoords = standardtcoords,
		funcstr = [[TotemHelper(3, c.Name) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
		end,
		anticipate = function(c)
			return [[local VALUE = time + TotemHelper(3) - c.Level]]
		end,
		hidden = not totems[3],
	},
	{ -- totem4
		text = totems[4],
		value = "TOTEM4",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
		useSUG = true,
		allowMultipleSUGEntires = true,
		texttable = absentseconds,
		icon = totemtex[4],
		tcoords = standardtcoords,
		funcstr = [[TotemHelper(4, c.Name) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
		end,
		anticipate = function(c)
			return [[local VALUE = time + TotemHelper(4) - c.Level]]
		end,
		hidden = not totems[4],
	},

	{ -- casting
		text = L["ICONMENU_CAST"],
		value = "CASTING",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 2,
		nooperator = true,
		texttable = {
			[0] = L["CONDITIONPANEL_INTERRUPTIBLE"],
			[1] = L["ICONMENU_PRESENT"],
			[2] = L["ICONMENU_ABSENT"],
		},
		midt = true,
		icon = "Interface\\Icons\\Temp",
		tcoords = standardtcoords,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_CASTTOMATCH", "CONDITIONPANEL_CASTTOMATCH_DESC") editbox.label = L["CONDITIONPANEL_CASTTOMATCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
		useSUG = true,
		funcstr = [[UnitCast(c.Unit, c.Level, LOWER(c.NameName))]], -- LOWER is some gsub magic
		events = function(ConditionObj, c)
			-- holy shit... need i say more?
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_START", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_STOP", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_FAILED", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_DELAYED", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_INTERRUPTED", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_START", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_UPDATE", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_STOP", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_INTERRUPTED", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_INTERRUPTIBLE", c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", c.Unit)
		end,
		spacebefore = true,
	},


-------------------------------------buffs/debuffs
	{ -- unit buff duration
		text = L["ICONMENU_BUFF"] .. " - " .. L["DURATION"],
		value = "BUFFDUR",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["DURATION"], "BUFFCNDT_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		texttable = absentseconds,
		icon = "Interface\\Icons\\spell_nature_rejuvenation",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameFirst, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
		anticipate = function(c)
			return [[local dur = AuraDur(c.Unit, c.NameFirst, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time)
			local VALUE
			if dur and dur > 0 then
				local expirationTime = dur + time
				VALUE = expirationTime and expirationTime - c.Level or 0
			else
				VALUE = 0
			end]]
		end,
	},
	{ -- unit buff duration compare
		text = L["ICONMENU_BUFF"] .. " - " .. L["DURATION"] .. " - " .. L["COMPARISON"],
		value = "BUFFDURCOMP",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "BUFFTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["BUFFTOCOMP1"] end,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		name2 = function(editbox) TMW:TT(editbox, "BUFFTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["BUFFTOCOMP2"] end,
		check2 = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		useSUG = true,
		icon = "Interface\\Icons\\spell_nature_rejuvenation",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameFirst, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator AuraDur(c.Unit, c.NameFirst2, c.NameName2, "HELPFUL]] .. (c.Checked2 and "|PLAYER" or "") .. [[", time)]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},
	{ -- unit buff stacks
		text = L["ICONMENU_BUFF"] .. " - " .. L["STACKS"],
		value = "BUFFSTACKS",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["STACKS"], "BUFFCNDT_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
		icon = "Interface\\Icons\\inv_misc_herb_felblossom",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraStacks(c.Unit, c.NameFirst, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},
	{ -- unit buff tooltip
		text = L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"],
		tooltip = L["TOOLTIPSCAN_DESC"],
		value = "BUFFTOOLTIP",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 500,
		--texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"], "TOOLTIPSCAN_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		icon = "Interface\\Icons\\inv_elemental_primal_mana",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraTooltipNumber(c.Unit, c.NameFirst, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},
	{ -- unit buff number
		text = L["ICONMENU_BUFF"] .. " - " .. L["NUMAURAS"],
		tooltip = L["NUMAURAS_DESC"],
		value = "BUFFNUMBER",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["NUMAURAS"], "BUFFCNDT_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		texttable = function(k) return format(L["ACTIVE"], k) end,
		icon = "Interface\\Icons\\ability_paladin_sacredcleansing",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraCount(c.Unit, c.NameFirst, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},

	{ -- unit debuff duration
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATION"],
		value = "DEBUFFDUR",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["DURATION"], "BUFFCNDT_DESC", 1) editbox.label = L["DEBUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		texttable = absentseconds,
		icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameFirst, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
		anticipate = function(c)
			return [[local dur = AuraDur(c.Unit, c.NameFirst, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time)
			local VALUE
			if dur and dur > 0 then
				local expirationTime = dur + time
				VALUE = expirationTime and expirationTime - c.Level or 0
			else
				VALUE = 0
			end]]
		end,
		spacebefore = true,
	},
	{ -- unit debuff duration compare
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATION"] .. " - " .. L["COMPARISON"],
		value = "DEBUFFDURCOMP",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "DEBUFFTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["DEBUFFTOCOMP1"] end,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		name2 = function(editbox) TMW:TT(editbox, "DEBUFFTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["DEBUFFTOCOMP2"] end,
		check2 = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		useSUG = true,
		icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameFirst, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator AuraDur(c.Unit, c.NameFirst2, c.NameName2, "HARMFUL]] .. (c.Checked2 and "|PLAYER" or "") .. [[", time)]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
		-- anticipate: no anticipator is needed because the durations will always remain the same relative to eachother until at least a UNIT_AURA fires
	},
	{ -- unit debuff stacks
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["STACKS"],
		value = "DEBUFFSTACKS",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["STACKS"], "BUFFCNDT_DESC", 1) editbox.label = L["DEBUFFTOCHECK"]end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
		icon = "Interface\\Icons\\ability_warrior_sunder",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraStacks(c.Unit, c.NameFirst, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},
	{ -- unit debuff tooltip
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"],
		tooltip = L["TOOLTIPSCAN_DESC"],
		value = "DEBUFFTOOLTIP",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 500,
		--texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"], "TOOLTIPSCAN_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		icon = "Interface\\Icons\\spell_shadow_lifedrain",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraTooltipNumber(c.Unit, c.NameFirst, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},
	{ -- unit debuff number
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["NUMAURAS"],
		tooltip = L["NUMAURAS_DESC"],
		value = "DEBUFFNUMBER",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["NUMAURAS"], "BUFFCNDT_DESC", 1) editbox.label = L["DEBUFFTOCHECK"]end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		texttable = function(k) return format(L["ACTIVE"], k) end,
		icon = "Interface\\Icons\\spell_deathknight_frostfever",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraCount(c.Unit, c.NameFirst, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(ConditionObj, c)
			return
				ConditionObj:GetUnitChangedEventString(c.Unit),
				ConditionObj:GenerateNormalEventString("UNIT_AURA", c.Unit)
		end,
	},

	{ -- mainhand
		text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_WEAPONMAINHAND,
		value = "MAINHAND",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 120,
		unit = false,
		texttable = absentseconds,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_14" end,
		tcoords = standardtcoords,
		funcstr = [[(select(2, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
		end,
		anticipate = [[local _, dur = GetWeaponEnchantInfo()
			local VALUE = time + (dur/1000) - c.Level]],
		spacebefore = true,
	},
	{ -- offhand
		text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_WEAPONOFFHAND,
		value = "OFFHAND",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 120,
		unit = false,
		texttable = absentseconds,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_15" end,
		tcoords = standardtcoords,
		funcstr = [[(select(5, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
		end,
		anticipate = [[local _, _, _, _, dur = GetWeaponEnchantInfo()
			local VALUE = time + (dur/1000) - c.Level]],
	},
	{ -- thrown
		text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_THROWN,
		value = "THROWN",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 120,
		unit = false,
		texttable = absentseconds,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("RangedSlot")) or "Interface\\Icons\\inv_throwingknife_06" end,
		tcoords = standardtcoords,
		funcstr = [[(select(8, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
		end,
		anticipate = [[local _, _, _, _, _, _, _, dur = GetWeaponEnchantInfo()
			local VALUE = time + (dur/1000) - c.Level]],
		hidden = pclass ~= "ROGUE",
	},


-------------------------------------stats
	{ -- strength
		text = _G["SPELL_STAT1_NAME"],
		value = "STRENGTH",
		category = L["CNDTCAT_STATS"],
		categorySpacebefore = true,
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_nature_strength",
		tcoords = standardtcoords,
		funcstr = [[UnitStat("player", 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_STATS", "player")
		end,
	},
	{ -- agility
		text = _G["SPELL_STAT2_NAME"],
		value = "AGILITY",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_holy_blessingofagility",
		tcoords = standardtcoords,
		funcstr = [[UnitStat("player", 2) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_STATS", "player")
		end,
	},
	{ -- stamina
		text = _G["SPELL_STAT3_NAME"],
		value = "STAMINA",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_holy_wordfortitude",
		tcoords = standardtcoords,
		funcstr = [[UnitStat("player", 3) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_STATS", "player")
		end,
	},
	{ -- intellect
		text = _G["SPELL_STAT4_NAME"],
		value = "INTELLECT",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_holy_magicalsentry",
		tcoords = standardtcoords,
		funcstr = [[UnitStat("player", 4) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_STATS", "player")
		end,
	},
	{ -- spirit
		text = _G["SPELL_STAT5_NAME"],
		value = "SPIRIT",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_shadow_burningspirit",
		tcoords = standardtcoords,
		funcstr = [[UnitStat("player", 1) c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_STATS", "player")
		end,
	},
	{ -- mastery
		text = STAT_MASTERY,
		value = "MASTERY",
		category = L["CNDTCAT_STATS"],
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_championsbond",
		tcoords = standardtcoords,
		funcstr = [[GetMastery() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("MASTERY_UPDATE")
		end,
	},

	{ -- melee AP
		text = MELEE_ATTACK_POWER,
		value = "MELEEAP",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\INV_Sword_04",
		tcoords = standardtcoords,
		funcstr = [[UnitAttackPower("player") c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_ATTACK_POWER", "player")
		end,
		spacebefore = true,
	},
	{ -- melee crit
		text = L["MELEECRIT"],
		value = "MELEECRIT",
		category = L["CNDTCAT_STATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_CriticalStrike",
		tcoords = standardtcoords,
		funcstr = [[GetCritChance()/100 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("COMBAT_RATING_UPDATE")
		end,
	},
	{ -- melee haste
		text = L["MELEEHASTE"],
		value = "MELEEHASTE",
		category = L["CNDTCAT_STATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_bloodlust",
		tcoords = standardtcoords,
		funcstr = [[GetMeleeHaste()/100 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_ATTACK_SPEED", "player")
		end,
	},
	{ -- expertise
		text = _G["COMBAT_RATING_NAME"..CR_EXPERTISE],
		value = "EXPERTISE",
		category = L["CNDTCAT_STATS"],
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_rogue_shadowstrikes",
		tcoords = standardtcoords,
		funcstr = [[GetExpertise() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("COMBAT_RATING_UPDATE")
		end,
	},

	{ -- ranged AP
		text = RANGED_ATTACK_POWER,
		value = "RANGEAP",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\INV_Weapon_Bow_07",
		tcoords = standardtcoords,
		funcstr = [[UnitRangedAttackPower("player") c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_RANGED_ATTACK_POWER", "player")
		end,
		spacebefore = true,
	},
	{ -- range crit
		text = L["RANGEDCRIT"],
		value = "RANGEDCRIT",
		category = L["CNDTCAT_STATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_CriticalStrike",
		tcoords = standardtcoords,
		funcstr = [[GetRangedCritChance()/100 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("COMBAT_RATING_UPDATE")
		end,
	},
	{ -- range haste
		text = L["RANGEDHASTE"],
		value = "RANGEDHASTE",
		category = L["CNDTCAT_STATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_hunter_runningshot",
		tcoords = standardtcoords,
		funcstr = [[GetRangedHaste()/100 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("UNIT_RANGEDDAMAGE", "player")
		end,
	},


	{ -- spell damage
		text = STAT_SPELLDAMAGE,
		value = "SPELLDMG",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_fire_flamebolt",
		tcoords = standardtcoords,
		funcstr = [[GetSpellBonusDamage() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_DAMAGE_DONE_MODS")
		end,
		spacebefore = true,
	},
	{ -- spell healing
		text = STAT_SPELLHEALING,
		value = "SPELLHEALING",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		texttable = commanumber,
		icon = "Interface\\Icons\\spell_nature_healingtouch",
		tcoords = standardtcoords,
		funcstr = [[GetSpellBonusHealing() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("PLAYER_DAMAGE_DONE_MODS")
		end,
	},
	{ -- spell crit
		text = L["SPELLCRIT"],
		value = "SPELLCRIT",
		category = L["CNDTCAT_STATS"],
		min = 0,
		max = 100,
		percent = true,
		texttable = pluspercent,
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_gizmo_supersappercharge",
		tcoords = standardtcoords,
		funcstr = [[GetSpellCritChance() c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("COMBAT_RATING_UPDATE")
		end,
	},
	{ -- spell haste
		text = L["SPELLHASTE"],
		value = "SPELLHASTE",
		category = L["CNDTCAT_STATS"],
		min = 0,
		max = 100,
		percent = true,
		texttable = pluspercent,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_mage_timewarp",
		tcoords = standardtcoords,
		funcstr = [[UnitSpellHaste("player")/100 c.Operator c.Level]],
		events = function(ConditionObj, c)
			return
				ConditionObj:GenerateNormalEventString("COMBAT_RATING_UPDATE"),
				ConditionObj:GenerateNormalEventString("UNIT_SPELL_HASTE", "player")
		end,
	},
		{ -- mana regen
		text = MANA_REGEN,
		value = "MANAREGEN",
		category = L["CNDTCAT_STATS"],
		range = 1000/5,
		unit = PLAYER,
		texttable = function(k) return format(L["MP5"], commanumber(k)*5) end,
		icon = "Interface\\Icons\\spell_magic_managain",
		tcoords = standardtcoords,
		funcstr = [[GetManaRegen() c.Operator c.Level]], -- anyone know of an event that can be reliably listened to to get this?
		-- events = EVENTS NEEDED FOR THIS!! TODO
	},
		{ -- mana in combat
		text = MANA_REGEN_COMBAT,
		value = "MANAREGENCOMBAT",
		category = L["CNDTCAT_STATS"],
		range = 1000/5,
		unit = PLAYER,
		texttable = function(k) return format(L["MP5"], commanumber(k)*5) end,
		icon = "Interface\\Icons\\spell_frost_summonwaterelemental",
		tcoords = standardtcoords,
		funcstr = [[select(2, GetManaRegen()) c.Operator c.Level]],
		-- events = EVENTS NEEDED FOR THIS!! TODO
	},


	"CURRENCYPLACEHOLDER",

	{ -- icon shown
		text = L["CONDITIONPANEL_ICON"],
		tooltip = L["CONDITIONPANEL_ICON_DESC"],
		value = "ICON",
		spacebefore = true,
		min = 0,
		max = 1,
		texttable = {
			[0] = L["CONDITIONPANEL_ICON_SHOWN"],
			[1] = L["CONDITIONPANEL_ICON_HIDDEN"],
		},
		isicon = true,
		nooperator = true,
		unit = false,
		icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
		tcoords = standardtcoords,
		showhide = function(group)
			group.TextUnitOrIcon:SetText(L["ICONTOCHECK"])
			group.Icon:Show()
		end,
		funcstr = function(c, icon)
			if c.Icon == "" or c.Icon == icon:GetName() then
				return [[true]]
			end

			local g, i = strmatch(c.Icon, "TellMeWhen_Group(%d+)_Icon(%d+)")
			g, i = tonumber(g) or 0, tonumber(i) or 0
			if icon.IsIcon then
				TMW:QueueValidityCheck(c.Icon, icon.group:GetID(), icon:GetID(), g, i)
			elseif icon.class == TMW.Classes.Group then
				TMW:QueueValidityCheck(c.Icon, icon:GetID(), nil, g, i)
			end

			local str = [[( c.Icon and c.Icon.attributes.shown and c.Icon.OnUpdate and not c.Icon:Update())]]
			if c.Level == 0 then
				str = str .. [[and c.Icon.attributes.realAlpha > 0]]
			else
				str = str .. [[and c.Icon.attributes.realAlpha == 0]]
			end
			return gsub(str, "c.Icon", c.Icon)
		end,
	--[[	events = function(ConditionObj, c)
			ConditionObj:SetNumEventArgs(1)
			
			local t = {}
			for _, IconDataProcessor_name in TMW:Vararg("REALALPHA", "SHOWN") do
				local IconDataProcessor = TMW.ProcessorsByName[IconDataProcessor_name]
				local changedEvent = IconDataProcessor and IconDataProcessor.changedEvent
				
				if changedEvent then
					ConditionObj:RequestEvent(changedEvent)
					
					t[#t+1] = "event == '" .. changedEvent .. "' and arg1 == " .. c.Icon
				end
			end
			
			return unpack(t)
		end,]]
	},
	{ -- macro conditional
		text = L["MACROCONDITION"],
		tooltip = L["MACROCONDITION_DESC"],
		value = "MACRO",
		min = 0,
		max = 1,
		nooperator = true,
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "MACROCONDITION", "MACROCONDITION_EB_DESC") editbox.label = L["MACROTOEVAL"] end,
		unit = false,
		icon = "Interface\\Icons\\inv_misc_punchcards_yellow",
		tcoords = standardtcoords,
		funcstr = function(c)
			local text = c.Name
			text = (not strfind(text, "^%[") and ("[" .. text)) or text
			text = (not strfind(text, "%]$") and (text .. "]")) or text
			return [[SecureCmdOptionParse("]] .. text .. [[")]]
		end,
		-- events = absolutely no events
	},
	{ -- mouseover
		text = L["MOUSEOVERCONDITION"],
		tooltip = L["MOUSEOVERCONDITION_DESC"],
		value = "MOUSEOVER",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = false,
		icon = "Interface\\Icons\\Ability_Marksmanship",
		tcoords = standardtcoords,
		funcstr = function(c, parent)
			return [[c.True == ]] .. parent:GetName() .. [[:IsMouseOver()]]
		end,
		-- events = -- there is no good way to handle events for this condition
	},
	{ -- Lua
		text = L["LUACONDITION"],
		tooltip = L["LUACONDITION_DESC"],
		value = "LUA",
		min = 0,
		max = 1,
		nooperator = true,
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "LUACONDITION", "LUACONDITION_DESC") editbox.label = L["CODETOEXE"] end,
		unit = false,
		icon = "Interface\\Icons\\INV_Misc_Gear_01",
		tcoords = standardtcoords,
		funcstr = function(c)
			setmetatable(TMW.CNDT.Env, TMW.CNDT.EnvMeta)
			return c.Name ~= "" and c.Name or "true"
		end,
		events = function(ConditionObj, c) --TODO: update this for the new system
			-- allows parsing of events from the code string. EG:
			-- --EVENTS:'PLAYER_ENTERING_WORLD','PLAYER_LOGIN'
			-- --[[EVENTS:'PLAYER_ENTERING_WORLD','UNIT_AURA','target']]
			
			
			
			if true then return end
			
			
			
			
			
			local eventString = strmatch(c.Name, "EVENTS:([^ \t]-)\]?")
			if eventString then
				CNDT.LuaTemporaryConditionTable = c
				local func = [[
					local c = TMW.CNDT.LuaTemporaryConditionTable
				return ]] .. eventString
				local func, err = loadstring(func)
				if func then
					-- we do this convoluted shit because the function is supposed to return a list of events,
					-- but the first ret from pcall is success, which isn't expected as a ret value,
					-- but we still need to return all other values (and an unknown number of them),
					-- which makes unpack ideal for this.
					local t = {pcall(func)}
					local success = tremove(t, 1)
					if success then
						return unpack(t)
					end
				end
			end
		end,
	},


	{ -- default
		text = L["CONDITIONPANEL_DEFAULT"],
		value = "",
		hidden = true,
		noslide = true,
		unit = false,
		nooperator = true,
		min = 0,
		max = 100,
		funcstr = [[true]],
		events = function()
			-- Returning false (as a string, not a boolean) won't cause responses to any events,
			-- and it also won't make the ConditionObj default to being OnUpdate driven.
			
			return "false"
		end,
	},

}

local currencies = {
	-- currencies were extracted using the script in the /Scripts folder (source is wowhead)
	-- make sure and order them here in a way that makes sense (most common first, blah blah derp herping)
	395,	--Justice Points
	396,	--Valor Points
	392,	--Honor Points
	390,	--Conquest Points
	"SPACE",
	391,	--Tol Barad Commendation
	416,	--Mark of the World Tree
	241,	--Champion\'s Seal
	515,	--Darkmoon Prize Ticket
	"SPACE",
	614,	--Mote of Darkness
	615,	--Essence of Corrupted Deathwing
	"SPACE",
	361,	--Illustrious Jewelcrafter\'s Token
	402,	--Chef\'s Award
	61,		--Dalaran Jewelcrafter\'s Token
	81,		--Dalaran Cooking Award
	"SPACE",
	384,	--Dwarf Archaeology Fragment
	398,	--Draenei Archaeology Fragment
	393,	--Fossil Archaeology Fragment
	394,	--Night Elf Archaeology Fragment
	400,	--Nerubian Archaeology Fragment
	397,	--Orc Archaeology Fragment
	401,	--Tol\'vir Archaeology Fragment
	385,	--Troll Archaeology Fragment
	399,	--Vrykul Archaeology Fragment
}
for k, v in ipairs(CNDT.Types) do
	if v == "CURRENCYPLACEHOLDER" then
		CNDT.Types[k] = nil
		local spacenext

		for _, id in ipairs(currencies) do
			if id == "SPACE" then
				spacenext = true
			else
				tinsert(CNDT.Types, k, {
					value = "CURRENCY"..id,
					category = L["CNDTCAT_CURRENCIES"],
					range = 500,
					unit = false,
					funcstr = [[select(2, GetCurrencyInfo(]]..id..[[)) c.Operator c.Level]],
					tcoords = standardtcoords,
					spacebefore = spacenext,
					hidden = true,
					events = function(ConditionObj, c)
						return
							ConditionObj:GenerateNormalEventString("CURRENCY_DISPLAY_UPDATE")
					end,
				})
				spacenext = nil
				k = k + 1
			end
		end
		break
	end
end

CNDT.ConditionsByType = {}
for k, v in pairs(CNDT.Types) do
	CNDT.ConditionsByType[v.value] = v
end local ConditionsByType = CNDT.ConditionsByType
function CNDT:CURRENCY_DISPLAY_UPDATE()
	for _, id in pairs(currencies) do
		if id ~= "SPACE" then
			local data = CNDT.ConditionsByType["CURRENCY"..id]
			local name, amount, texture, _, _, totalMax = GetCurrencyInfo(id)
			if name ~= "" then
				data.text = name
				data.icon = "Interface\\Icons\\"..texture
				data.hidden = false
				if TMWOptDB then
					TMWOptDB.Currencies = TMWOptDB.Currencies or {}
					TMWOptDB.Currencies[id] = name .. "^" .. texture
				end
				--[[if totalMax > 0 then -- not using this till blizzard fixes the bug where it shows the honor and conquest caps as 40,000
					data.max = totalMax/100
				end]]
			elseif TMWOptDB and TMWOptDB.Currencies then
				if TMWOptDB.Currencies[id] then
					local name, texture = strmatch(TMWOptDB.Currencies[id], "(.*)^(.*)")
					if name and texture then
						data.text = name
						data.icon = "Interface\\Icons\\"..texture
						data.hidden = false
					end
				end
			end
		end
	end
end
CNDT:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
CNDT:CURRENCY_DISPLAY_UPDATE()

TMW:RegisterCallback("TMW_OPTIONS_LOADED", "CURRENCY_DISPLAY_UPDATE", CNDT)

do -- InConditionSettings
	local states = {}
	local function getstate(stage, currentCondition, extIter, extIterState)
		local state = wipe(tremove(states) or {})

		state.stage = stage
		state.extIter = extIter
		state.extIterState = extIterState
		state.currentCondition = currentCondition

		return state
	end

	local function iter(state)
		state.currentCondition = state.currentCondition + 1

		if not state.currentConditions or state.currentCondition > (state.currentConditions.n or #state.currentConditions) then
			local settings
			settings, state.cg, state.ci = state.extIter(state.extIterState)
			if not settings then
				if state.stage == "icon" then
					state.extIter, state.extIterState = TMW:InGroupSettings()
					state.stage = "group"
					return iter(state)
				else
					tinsert(states, state)
					return
				end
			end
			state.currentConditions = settings.Conditions
			state.currentCondition = 0
			return iter(state)
		end
		local condition = rawget(state.currentConditions, state.currentCondition)
		if not condition then return iter(state) end
		return condition, state.currentCondition, state.cg, state.ci -- condition data, conditionID, groupID, iconID
	end

	function TMW:InConditionSettings()
		return iter, getstate("icon", 0, TMW:InIconSettings())
	end
end

	
local EnvMeta = {
	__index = _G,
	--__newindex = _G,
} TMW.CNDT.EnvMeta = EnvMeta

function CNDT:TMW_GLOBAL_UPDATE()
	Env.Locked = TMW.Locked
	NumShapeshiftForms = GetNumShapeshiftForms()
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", CNDT)

function CNDT:TMW_GLOBAL_UPDATE_POST()
	for _, ConditionObj in pairs(TMW.Classes.ConditionObject.instances) do
		ConditionObj:Check()
	end
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", CNDT)

TMW:RegisterCallback("TMW_CONFIG_ICON_RECONCILIATION_REQUESTED", function(event, replace, limitSourceGroup)
	for Condition, _, groupID in TMW:InConditionSettings() do
		if not limitSourceGroup or groupID == limitSourceGroup then
			if Condition.Icon ~= "" and type(Condition.Icon) == "string" then
				replace(Condition, "Icon")
			end
		end
	end
end)

local function strWrap(string)
	local num = isNumber[string]
	if num then
		return num
	else
		return format("%q", string)
	end
end

function CNDT:DoConditionSubstitutions(parent, v, c, thisstr)
	for _, append in TMW:Vararg("2", "") do -- Unit2 MUST be before Unit
		if strfind(thisstr, "c.Unit" .. append) then
			local unit
			if append == "2" then
				unit = TMW.UNITS:GetOriginalUnitTable(c.Name)[1] or ""
			elseif append == "" then
				unit = TMW.UNITS:GetOriginalUnitTable(c.Unit)[1] or ""
			end
			if (strfind(unit, "maintank") or strfind(unit, "mainassist")) then
				thisstr = gsub(thisstr, "c.Unit" .. append,		unit) -- sub it in as a variable
				Env[unit] = unit
				CNDT.SpecialUnitsUsed[unit] = true
				CNDT:RegisterEvent("RAID_ROSTER_UPDATE")
				CNDT:RAID_ROSTER_UPDATE()
			elseif strfind(unit, "^%%[Uu]") then
				--TODO: depricate this
				local after = strmatch(unit, "^%%[Uu]%-?(.*)")
				-- it is intended that we sub in parent:GetName() instead of "icon". 
				-- We want to create unique ConditionObjects for each icon that uses %u (as opposed to using a cached one)
				local sub = "(" .. parent:GetName() .. ".attributes.unit or '')"
				if after and after ~= "" then
					sub = "(" .. sub .. " .. \"-" .. after .. "\")"
				end
				thisstr = gsub(thisstr, "c.Unit" .. append,		sub) -- sub it in as a variable
			else
				thisstr = gsub(thisstr, "c.Unit" .. append,	"\"" .. unit .. "\"") -- sub it in as a string
			end
		end
	end

	local name = gsub((c.Name or ""), "; ", ";")
	name = gsub(name, " ;", ";")
	name = ";" .. name .. ";"
	name = gsub(name, ";;", ";")
	name = strtrim(name)
	name = strlower(name)

	local name2 = gsub((c.Name2 or ""), "; ", ";")
	name2 = gsub(name2, " ;", ";")
	name2 = ";" .. name2 .. ";"
	name2 = gsub(name2, ";;", ";")
	name2 = strtrim(name2)
	name2 = strlower(name2)

	thisstr = thisstr:
	gsub("c.Level", 		v.percent and c.Level/100 or c.Level):
	gsub("c.Checked", 		tostring(c.Checked)):
	gsub("c.Operator", 		c.Operator):
	gsub("c.NameFirst2", 	strWrap(TMW:GetSpellNames(nil, name2, 1))): --Name2 must be before Name
	gsub("c.NameName2", 	strWrap(TMW:GetSpellNames(nil, name2, 1, 1))):
	gsub("c.ItemID2", 		strWrap(TMW:GetItemIDs(nil, name2, 1))):
	gsub("c.Name2", 		strWrap(name2)):

	gsub("c.NameFirst", 	strWrap(TMW:GetSpellNames(nil, name, 1))):
	gsub("c.NameName", 		strWrap(TMW:GetSpellNames(nil, name, 1, 1))):
	gsub("c.ItemID", 		strWrap(TMW:GetItemIDs(nil, name, 1))):
	gsub("c.Name", 			strWrap(name)):

	gsub("c.True", 			tostring(c.Level == 0)):
	gsub("c.False", 		tostring(c.Level == 1)):
	gsub("c.1nil", 			c.Level == 0 and 1 or "nil"):
	gsub("c.nil1", 			c.Level == 1 and 1 or "nil"): -- reverse 1nil

	gsub("LOWER%((.-)%)",	strlower) -- fun gsub magic stuff

	-- extra fun stuff
	if thisstr:find("c.GCDReplacedNameFirst2") then
		local name = TMW:GetSpellNames(nil, name2, 1)
		if name == "gcd" then
			name = TMW.GCDSpell
		end
		thisstr = thisstr:gsub("c.GCDReplacedNameFirst2", "\"" .. name .. "\"")
	end
	if thisstr:find("c.GCDReplacedNameFirst") then
		local name = TMW:GetSpellNames(nil, name, 1)
		if name == "gcd" then
			name = TMW.GCDSpell
		end
		thisstr = thisstr:gsub("c.GCDReplacedNameFirst", "\"" .. name .. "\"")
	end

	return thisstr
end

local argCheckerStringsReusable = {}
function CNDT:CompileUpdateFunction(parent, obj)
	local Conditions = obj.settings
	local argCheckerStrings = wipe(argCheckerStringsReusable)
	local numAnticipatorResults = 0
	local anticipatorstr = ""

	for _, c in TMW:InNLengthTable(Conditions) do
		local t = c.Type
		local v = CNDT.ConditionsByType[t]
		if v and v.events then
			local voidNext
			for n, argCheckerString in TMW:Vararg(TMW.get(v.events, obj, c)) do
				if type(argCheckerString) == "string" then
					if argCheckerString == "OnUpdate" then
						return
					elseif argCheckerString == "" then
						TMW:Error("Condition.events shouldn't return blank strings! (From condition %q). Return false if you don't want the condition to update OnUpdate but it also has no events (basically, if it is static).", t)
					else
						argCheckerStrings[argCheckerString] = true
					end
				end
			end
		else
			return
		end

		-- handle code that anticipates when a change in state will occur.
		-- this is usually used to predict when a duration threshold will be used, but you could really use it for whatever you want.
		if v.anticipate then
			numAnticipatorResults = numAnticipatorResults + 1

			local thisstr = TMW.get(v.anticipate, c) -- get the anticipator string from the condition data
			thisstr = CNDT:DoConditionSubstitutions(parent, v, c, thisstr) -- substitute in any user settings

			-- append a check to make sure that the smallest value out of all anticipation checks isnt less than the current time.
			thisstr = thisstr .. [[
			if VALUE <= time then
				VALUE = huge
			end]]

			-- change VALUE to the appropriate ANTICIPATOR_RESULT#
			thisstr = thisstr:gsub("VALUE", "ANTICIPATOR_RESULT" .. numAnticipatorResults)

			anticipatorstr = anticipatorstr .. "\r\n" .. thisstr
		end
	end

	if not next(argCheckerStrings) then
		return
	end

	local doesAnticipate
	if anticipatorstr ~= "" then
		local allVars = ""
		for i = 1, numAnticipatorResults do
			allVars = allVars .. "ANTICIPATOR_RESULT" .. i .. ","
		end
		allVars = allVars:sub(1, -2)

		anticipatorstr = anticipatorstr .. ([[
		local nextTime = %s
		if nextTime == 0 then
			nextTime = huge
		end
		obj.NextUpdateTime = nextTime]]):format((numAnticipatorResults == 1 and allVars or "min(" .. allVars .. ")"))

		doesAnticipate = true
	end

	obj.UpdateMethod = "OnEvent" --DEBUG: COMMENTING THIS LINE FORCES ALL CONDITIONS TO BE ONUPDATE DRIVEN

	-- Begin creating the final string that will be used to make the function.
	local funcstr = [[
	if not event then
		return
	elseif (]]
	
	-- Compile all of the arg checker strings into one single composite that can be checked in an (if ... then) statement.
	local argCheckerStringComposite = ""
	for argCheckerString in pairs(argCheckerStrings) do
		if argCheckerString ~= "" then
			argCheckerStringComposite = argCheckerStringComposite .. [[(]] .. argCheckerString .. [[) or ]]
		end
	end
	
	if argCheckerStringComposite ~= "" then
		-- If any arg checkers were added to the composite (it isnt a blank string),
		-- trim off the final ") or " at the end of it.
		argCheckerStringComposite = argCheckerStringComposite:sub(1, -5)
	else
		-- The arg checker string should never ever be blank. Raise an error if it was.
		TMW:Error("The arg checker string for the ConditionObj being compiled for %q was blank. This should not have happened.", parent:GetName())
	end

	-- Tack on the composite arg checker string to the function, and then close the elseif that it goes into.
	funcstr = funcstr .. argCheckerStringComposite .. [[) then
		if obj.doesAutoUpdate then
			obj:Check()
		else
			obj.UpdateNeeded = true
		end
	end]]

	-- Add the anticipator function string to the beginning of the function string, before event handling happens.
	funcstr = anticipatorstr .. "\r\n" .. funcstr
	
	-- Finally, create the header of the function that will get all of the args passed into it.
	local argHeader = [[local obj, event]]
	for i = 1, obj.numArgsForEventString do 
		argHeader = argHeader .. [[, arg]] .. i
	end
	
	-- argHeader now looks like: local obj, event, arg1, arg2, arg3, ..., argN
	
	-- Set the variables that accept the args to the vararg with all of the function input,
	-- and tack on the body of the function
	funcstr = argHeader .. [[ = ...
	]] .. funcstr

	local func
	--if functionCache[funcstr] then
	--	func = functionCache[funcstr]
	--else
		local err
		func, err = loadstring(funcstr, tostring(obj) .. " Condition Events")
		if func then
			func = setfenv(func, Env)
		--	functionCache[funcstr] = func
		elseif err then
			TMW:Error(err)
		end
	--end
	obj.updateString = funcstr

	obj.AnticipateFunction = doesAnticipate and func
	obj.UpdateFunction = func

	-- Register the events and the object with the UpdateEngine
	obj:RegisterForUpdating()
end

function CNDT:IsUnitEventUnit(unit)
	if	unit == "player" then
		return ""
	elseif unit == "target" then
		return "PLAYER_TARGET_CHANGED"
	elseif unit == "pet" then
		return "UNIT_PET|'player'"
	elseif unit == "focus" then
		return "PLAYER_FOCUS_CHANGED"
	elseif unit:find("^raid%d+$") then
		return "RAID_ROSTER_UPDATE"
	elseif unit:find("^party%d+$") then
		return "PARTY_MEMBERS_CHANGED"
	elseif unit:find("^boss%d+$") then
		return "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
	elseif unit:find("^arena%d+$") then
		return "ARENA_OPPONENT_UPDATE"
	end
	
	return "OnUpdate"
end




local ConditionObject = TMW:NewClass("ConditionObject")
ConditionObject.numArgsForEventString = 1

function ConditionObject:OnNewInstance(parent, Conditions, conditionString)	
	self.settings = Conditions
	self.conditionString = conditionString

	self.AutoUpdateRequests = {}
	self.RequestedEvents = {}
	
	self.UpdateNeeded = true
	self.NextUpdateTime = huge
	self.UpdateMethod = "OnUpdate"
	
	local func, err = loadstring(conditionString, tostring(self) .. " Condition")
	if func then
		func = setfenv(func, TMW.CNDT.Env)
		self.CheckFunction = setfenv(func, TMW.CNDT.Env)
	elseif err then
		TMW:Error(err)
	end
	
	CNDT:CompileUpdateFunction(parent, self)
	
	self:Check()
end

function ConditionObject:Check()
	if self.CheckFunction then
	
		if self.UpdateMethod == "OnEvent" then
			self.UpdateNeeded = nil
			
			if self.AnticipateFunction then
				self:AnticipateFunction()
			end
		end
		
		if self.NextUpdateTime < time then
			self.NextUpdateTime = huge
		end
		
		local failed = not self:CheckFunction()
		if self.Failed ~= failed then
			self.Failed = failed
			TMW:Fire("TMW_CNDT_OBJ_PASSING_CHANGED", self, failed)
		end
	end
end

function ConditionObject:RequestAutoUpdates(parent, doRequest)
	if doRequest then
		if not next(self.AutoUpdateRequests) then
			self.doesAutoUpdate = true
			self:RegisterForUpdating()
		end
		
		self.AutoUpdateRequests[parent] = true
	else
		self.AutoUpdateRequests[parent] = nil
		
		if not next(self.AutoUpdateRequests) then
			self.doesAutoUpdate = false
			self:UnregisterForUpdating()
		end
	end
end

function ConditionObject:RegisterForUpdating()
	CNDT.UpdateEngine:RegisterObject(self)
end

function ConditionObject:UnregisterForUpdating()
	CNDT.UpdateEngine:UnregisterObject(self)
end

function ConditionObject:SetNumEventArgs(num)
	self.numArgsForEventString = max(self.numArgsForEventString, num)
end

function ConditionObject:RequestEvent(event)
	-- Note that this function does not actually register the event with CNDT.UpdateEngine
	-- It simply tells the object that it needs to register the event with CNDT.UpdateEngine
	-- once processing is done and it has been determined that the entire condition set can be event driven
	-- (if it has no OnUpdate conditions in it)
	self.RequestedEvents[event] = true
end

function ConditionObject:GenerateNormalEventString(event, ...)
	self:RequestEvent(event)
	self:SetNumEventArgs(select("#", ...))
	
	local str = "event == '"
    str = str .. event
    str = str .. "'"
    
	for n, arg in TMW:Vararg(...) do
		
		local arg_type = type(arg)
		if 
			arg_type ~= "number" and 
			arg_type ~= "string" and 
			arg_type ~= "boolean" and 
			arg_type ~= "nil" 
		then
			TMW:Error("Unsupported event arg type: " .. arg_type)
		elseif arg ~= nil then
			str = str .. " and arg"
			str = str .. n
			str = str .. " == "
			
			if arg_type == "string" then
				str = str .. "'"
				str = str .. arg
				str = str .. "'"
			else -- number, boolean
				str = str .. tostring(arg)
			end
		end
	end
	
	return str
end

function ConditionObject:GetUnitChangedEventString(unit)
	if unit == "player" then
		-- Returning false (as a string, not a boolean) won't cause responses to any events,
		-- and it also won't make the ConditionObj default to being OnUpdate driven.
		
		return "false"
	elseif unit == "target" then
		return self:GenerateNormalEventString("PLAYER_TARGET_CHANGED")
	elseif unit == "pet" then
		return self:GenerateNormalEventString("UNIT_PET", "player")
	elseif unit == "focus" then
		return self:GenerateNormalEventString("PLAYER_FOCUS_CHANGED")
	elseif unit:find("^raid%d+$") then
		return self:GenerateNormalEventString("RAID_ROSTER_UPDATE")
	elseif unit:find("^party%d+$") then
		return self:GenerateNormalEventString("PARTY_MEMBERS_CHANGED")
	elseif unit:find("^boss%d+$") then
		return self:GenerateNormalEventString("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	elseif unit:find("^arena%d+$") then
		return self:GenerateNormalEventString("ARENA_OPPONENT_UPDATE")
	end
	
	return false
end

local ConditionObjectConstructor = TMW:NewClass("ConditionObjectConstructor"){
	status = "ready",
	
	GetStatus = function(self)
		return self.status
	end,
	LoadParentAndConditions = function(self, parent, Conditions)
		-- Loads the parent and the Condition settings that will be used to
		-- construct a ConditionObject.
		
		assert(self.status == "ready", "Cannot :LoadParentAndConditions() to a ConditionObjectConstructor whose status is not 'ready'!")
		
		self.parent = parent
		self.Conditions = Conditions
		self.ConditionsToConstructWith = Conditions
		
		self.status = "loaded"
	end,
	ResetModifiableConditionsBase = function(self)
		self.ModifiableConditionsBase.n = 0
		for k, v in ipairs(self.ModifiableConditionsBase) do
			TMW:CopyTableInPlaceWithMeta(TMW.Icon_Defaults.Conditions, v)
		end
	end,
	GetPostUserModifiableConditions = function(self)
		-- Returns a copy of the settings table that was defined through :LoadConditions()
		-- that can be modified without changing user settings. If this modified version of the conditions is created,
		-- it will be used to :Construct() the ConditionObject instead of the original conditions.
		
		if self.ModifiableConditions then
			return self.ModifiableConditions
		end
		if not self.ModifiableConditionsBase then
			self.ModifiableConditionsBase = TMW:CopyWithMetatable(self.Conditions)
		end
		
		self:ResetModifiableConditionsBase()
		
		self.ModifiableConditions = TMW:CopyTableInPlaceWithMeta(self.Conditions, self.ModifiableConditionsBase)
		self.ConditionsToConstructWith = self.ModifiableConditions
		
		return self.ModifiableConditions
	end,
	
	Modify_AppendNew = function(self)
		-- Adds a single condition to the end.
		-- Returns this condition so that it can be manually configured however necessary.
		
		local ModifiableConditions = self:GetPostUserModifiableConditions()
		local mod = ModifiableConditions -- Alias for brevity
		
		mod.n = mod.n + 1
		
		return mod[mod.n]
	end,
	Modify_WrapExistingAndAppendNew = function(self)
		-- Wraps all existing conditions in parenthesis (if needed) and adds a single condition to the end.
		-- Returns this condition so that it can be manually configured however necessary.
		
		local ModifiableConditions = self:GetPostUserModifiableConditions()
		local mod = ModifiableConditions -- Alias for brevity
		
		mod.n = mod.n + 1
		if mod.n > 2 then
			mod[1].PrtsBefore = mod[1].PrtsBefore + 1
			mod[mod.n-1].PrtsAfter = mod[mod.n-1].PrtsAfter + 1
		end
		
		return mod[mod.n]
	end,
		
	Construct = function(self)
		-- Constructs and returns a ConditionObject that will reflect any modifications
		-- that were done through the ConditionObjectConstructor.
		
		local obj = CNDT:GetConditionObject(self.parent, self.ConditionsToConstructWith)
		
		self:Terminate()
		
		return obj
	end,
	Terminate = function(self)
		-- Terminates the ConditionObjectConstructor and prepares it for reuse.
		-- This is automatically called after performing :Construct().
		
		self.parent = nil
		self.Conditions = nil
		self.ConditionsToConstructWith = nil
		self.ModifiableConditions = nil
		
		if self.ModifiableConditionsBase then
			self:ResetModifiableConditionsBase()
		end
		
		self.status = "ready"
	end,
}

function CNDT:GetConditionObjectConstructor()
	for _, instance in pairs(ConditionObjectConstructor.instances) do
		if instance:GetStatus() == "ready" then
			return instance
		end
	end
	
	return ConditionObjectConstructor:New()
end

function CNDT:GetConditionObject(parent, Conditions)
	local conditionString = CNDT:GetConditionCheckFunctionString(parent, Conditions)
	
	if conditionString and conditionString ~= "" then
		local instances = ConditionObject.instances
		for i = 1, #instances do
			local instance = instances[i]
			if instance.conditionString == conditionString then
				return instance
			end
		end
		return ConditionObject:New(parent, Conditions, conditionString)
	end
end

function CNDT:GetConditionCheckFunctionString(parent, Conditions)
	local funcstr = ""
	
	if not CNDT:CheckParentheses(Conditions) then
		return ""
	end

	for _, c in TMW:InNLengthTable(Conditions) do
		local t = c.Type
		local v = TMW.CNDT.ConditionsByType[t]
		
		local andor
		if c.AndOr == "OR" then
			-- Need a space after "or" so it 3 chars long (to match the length of "and");
			-- the rest of the code expects this, so don't change this or things will break.
			andor = "or "
		else
			andor = "and"
		end

		if c.Operator == "~|=" or c.Operator == "|="  or c.Operator == "||=" then
			c.Operator = "~=" -- fix potential corruption from importing a string (a single | becaomes || when pasted, "~=" in encoded as "~|=")
		end

		local thiscondtstr
		if v then
		
			-- Add in anything that the condition wants to include in Env
			if v.Env then
				for k, v in pairs(v.Env) do
					if Env[k] ~= nil and Env[k] ~= v then
						TMW:Error("Condition " .. t .. " tried to write values to Env different than those that were already in it. Pick different keys for its data or otherwise figure out why this happened.")
					else
						Env[k] = v
					end
				end
			end
		
			thiscondtstr = v.funcstr
			if type(thiscondtstr) == "function" then
				thiscondtstr = thiscondtstr(c, parent)
			end
		end
		
		thiscondtstr = thiscondtstr or "true"
		
		local thisstr = andor .. "(" .. strrep("(", c.PrtsBefore) .. thiscondtstr .. strrep(")", c.PrtsAfter)  .. ")"

		if v then
			thisstr = CNDT:DoConditionSubstitutions(parent, v, c, thisstr)
		end
		
		funcstr = funcstr .. thisstr
	end
	
	funcstr = funcstr:sub(4)
	
	if funcstr ~= "" then
		-- Well, what the fuck? Apparently this code here doesn't work in MoP. I have to do it on a single line for some strange reason.
		--funcstr = [[local obj, icon = ...
		--return ( ]] .. funcstr .. [[ )]]
		
		funcstr = "local obj, icon = ... \r\n return ( " .. funcstr .. " )"
	end
	
	return funcstr
end


function CNDT:CheckParentheses(settings)

	local numclose, numopen, runningcount = 0, 0, 0
	local unopened = 0

	for _, Condition in TMW:InNLengthTable(settings) do
		for i = 1, Condition.PrtsBefore do
			numopen = numopen + 1
			runningcount = runningcount + 1
			if runningcount < 0 then unopened = unopened + 1 end
		end
		for i = 1, Condition.PrtsAfter do
			numclose = numclose + 1
			runningcount = runningcount - 1
			if runningcount < 0 then unopened = unopened + 1 end
		end
	end

	if numopen ~= numclose then
		local typeNeeded, num
		if numopen > numclose then
			typeNeeded, num = ")", numopen-numclose
		else
			typeNeeded, num = "(", numclose-numopen
		end
				
		return false, L["PARENTHESIS_WARNING1"], num, L["PARENTHESIS_TYPE_" .. typeNeeded]
	elseif unopened > 0 then
		
		return false, L["PARENTHESIS_WARNING2"], unopened
	else
		
		return true
	end
end

CNDT.UpdateEngine = CreateFrame("Frame")

function CNDT.UpdateEngine:CreateUpdateTableManager()
	local manager = TMW.Classes.UpdateTableManager:New()
	
	manager:UpdateTable_Set()
	
	return manager.UpdateTable_UpdateTable, manager
end

TMW:NewClass("EventUpdateTableManager", "UpdateTableManager"){
	OnNewInstance_EventUpdateTableManager = function(self, event)
		self.event = event
		self:UpdateTable_Set()
	end,
	
	UpdateTable_OnUsed = function(self)
		CNDT.UpdateEngine:RegisterEvent(self.event)
	end,
	UpdateTable_OnUnused = function(self)
		CNDT.UpdateEngine:UnregisterEvent(self.event)
	end,

}

function CNDT.UpdateEngine:CreateEventUpdateTableManager(event)
	local manager = TMW.Classes.EventUpdateTableManager:New(event)
	
	return manager.UpdateTable_UpdateTable, manager
end

local OnUpdate_UpdateTable, OnUpdate_UpdateTableManager = CNDT.UpdateEngine:CreateUpdateTableManager()
local OnAnticipate_UpdateTable, OnAnticipate_UpdateTableManager = CNDT.UpdateEngine:CreateUpdateTableManager()

CNDT.UpdateEngine.EventUpdateTables = {}
CNDT.UpdateEngine.EventUpdateTableManagers = {}



function CNDT.UpdateEngine:RegisterObject(ConditionObject)
	if ConditionObject.UpdateMethod == "OnUpdate" then
		self:RegisterObjForOnUpdate(ConditionObject)
		
	elseif ConditionObject.UpdateMethod == "OnEvent" then
		self:RegisterObjForOnEvent(ConditionObject)
	end
end
function CNDT.UpdateEngine:UnregisterObject(ConditionObject)
	if ConditionObject.UpdateMethod == "OnUpdate" then
		self:UnregisterObjForOnUpdate(ConditionObject)
		
	elseif ConditionObject.UpdateMethod == "OnEvent" then
		self:UnregisterObjForOnEvent(ConditionObject)
	end
end


function CNDT.UpdateEngine:RegisterObjForOnEvent(ConditionObject)
	for event in pairs(ConditionObject.RequestedEvents) do
		self:RegisterObjForEvent(ConditionObject, event)
	end
	
	if ConditionObject.AnticipateFunction and ConditionObject.doesAutoUpdate then
		OnAnticipate_UpdateTableManager:UpdateTable_Register(ConditionObject)
	end
end
function CNDT.UpdateEngine:RegisterObjForEvent(ConditionObject, event)
	
	if event:find("^TMW_") then
		TMW:RegisterCallback(event, ConditionObject.UpdateFunction, ConditionObject)
	else		
		local UpdateTableManager = CNDT.UpdateEngine.EventUpdateTableManagers[event]
		if not UpdateTableManager then
			local UpdateTable
			UpdateTable, UpdateTableManager = self:CreateEventUpdateTableManager(event)
			
			CNDT.UpdateEngine.EventUpdateTableManagers[event] = UpdateTableManager
			CNDT.UpdateEngine.EventUpdateTables[event] = UpdateTable
		end
		
		UpdateTableManager:UpdateTable_Register(ConditionObject)		
	end	
end

function CNDT.UpdateEngine:UnregisterObjForOnEvent(ConditionObject)
	for event in pairs(ConditionObject.RequestedEvents) do
		self:UnregisterObjForEvent(ConditionObject, event)
	end
	
	if ConditionObject.AnticipateFunction then
		OnAnticipate_UpdateTableManager:UpdateTable_Unregister(ConditionObject)
	end
end
function CNDT.UpdateEngine:UnregisterObjForEvent(ConditionObject, event)
	if event:find("^TMW_") then
		TMW:UnregisterCallback(event, ConditionObject.UpdateFunction, ConditionObject)
	else
		local UpdateTableManager = CNDT.UpdateEngine.EventUpdateTableManagers[event]
		if UpdateTableManager then
			UpdateTableManager:UpdateTable_Unregister(ConditionObject)
		end
	end
end

function CNDT.UpdateEngine:OnEvent(event, ...)
	local UpdateTable = self.EventUpdateTables[event]
	
	if UpdateTable then
		for i = 1, #UpdateTable do
			local ConditionObject = UpdateTable[i]
			ConditionObject:UpdateFunction(event, ...)
		end
	end
end
CNDT.UpdateEngine:SetScript("OnEvent", CNDT.UpdateEngine.OnEvent)



function CNDT.UpdateEngine:RegisterObjForOnUpdate(ConditionObject)
	OnUpdate_UpdateTableManager:UpdateTable_Register(ConditionObject)
end
function CNDT.UpdateEngine:UnregisterObjForOnUpdate(ConditionObject)
	OnUpdate_UpdateTableManager:UpdateTable_Unregister(ConditionObject)
end

function CNDT.UpdateEngine:OnUpdate(event, time, Locked)
	if Locked then
		for i = 1, #OnUpdate_UpdateTable do
			local ConditionObject = OnUpdate_UpdateTable[i]
			
			ConditionObject:Check()
			
			--TODO: remove support for %u substitution in conditions, move this functionality to unit sets
		end
		
		for i = 1, #OnAnticipate_UpdateTable do
			local ConditionObject = OnAnticipate_UpdateTable[i]
			if ConditionObject.NextUpdateTime < time then
				ConditionObject:Check()
			end
		end
	end

end
TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", "OnUpdate", CNDT.UpdateEngine)



TMW:NewClass("ConditionImplementor"){
	OnNewInstance_ConditionImplementor = function(self)
		Env[self:GetName()] = self
	end,
	Conditions_GetConstructor = function(self, Conditions)
		local ConditionObjectConstructor = TMW.CNDT:GetConditionObjectConstructor()
		
		ConditionObjectConstructor:LoadParentAndConditions(self, Conditions)
		
		return ConditionObjectConstructor
	end,
}

TMW.Classes.Icon:Inherit("ConditionImplementor")
TMW.Classes.Group:Inherit("ConditionImplementor")