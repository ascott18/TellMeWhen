-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

if not TMW then return end

local TMW = TMW
local db = TMW.db
local Env

-- -----------------------
-- LOCALS/GLOBALS/UTILITIES
-- -----------------------

local L = TMW.L
local _, pclass = UnitClass("Player")

local strlower, min, gsub, tostring, strfind, strsub, type, pairs, strtrim, select, format, tonumber =
	  strlower, min, gsub, tostring, strfind, strsub, type, pairs, strtrim, select, format, tonumber
local NONE, MAX_SPELL_SCHOOLS =
	  NONE, MAX_SPELL_SCHOOLS
local GetEclipseDirection, IsResting, GetPetActionInfo, GetTotemInfo, GetTalentTabInfo =
	  GetEclipseDirection, IsResting, GetPetActionInfo, GetTotemInfo, GetTalentTabInfo
local IsInInstance, GetInstanceDifficulty =
	  IsInInstance, GetInstanceDifficulty
local GetShapeshiftFormInfo =
	  GetShapeshiftFormInfo
local UnitAttackPower, UnitRangedAttackPower =
	  UnitAttackPower, UnitRangedAttackPower
local GetMeleeHaste, GetRangedHaste, UnitSpellHaste =
	  GetMeleeHaste, GetRangedHaste, UnitSpellHaste
local GetCritChance, GetRangedCritChance, GetSpellCritChance =
	  GetCritChance, GetRangedCritChance, GetSpellCritChance
local GetSpellBonusDamage, GetSpellBonusHealing =
	  GetSpellBonusDamage, GetSpellBonusHealing
local GetExpertise, GetMastery, UnitStat =
	  GetExpertise, GetMastery, UnitStat
local UnitAura, UnitAffectingCombat, UnitHasVehicleUI =
	  UnitAura, UnitAffectingCombat, UnitHasVehicleUI
local GetNumTrackingTypes, GetTrackingInfo =
	  GetNumTrackingTypes, GetTrackingInfo

local _G = _G
local print = TMW.print
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber
local huge = math.huge

local CNDT = TMW:NewModule("Conditions", "AceEvent-3.0", "AceSerializer-3.0") TMW.CNDT = CNDT
CNDT.SpecialUnitsUsed = {}

local functionCache = {} CNDT.functionCache = functionCache



function CNDT:OnInitialize()
	db = TMW.db
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

local test
--[[
test = function()
	test = nil
	TMW:Debug("|cffffffffRUNNING CONDITION TESTS")
	local icon = CreateFrame("Button", "TESTICON")
	Env.TESTICON = icon
	icon.Conditions = {n = 0}
	for k, v in ipairs(CNDT.Types) do
		icon.Conditions[k] = CopyTable(TMW.Icon_Defaults.Conditions["**"])
		icon.Conditions[k].Type = v.value
		icon.Conditions.n = icon.Conditions.n + 1
	end
	CNDT:ProcessConditions(icon)
	icon:CndtCheck()

	local n = 0
	for _ in pairs(CNDT.ConditionsByType) do
		n = n + 1
	end
	if #CNDT.Types ~= n then
		error("you screwed up the value field somewhere")
	end
end--]]

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
	GetNumPartyMembers = GetNumPartyMembers,
	GetNumRaidMembers = GetNumRaidMembers,
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
	IsUsableSpell = IsUsableSpell,
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
	GetTalentTabInfo = GetTalentTabInfo,
	GetPrimaryTalentTree = GetPrimaryTalentTree,
	GetActiveTalentGroup = GetActiveTalentGroup,

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
	time = TMW.time,
	huge = math.huge,
	epsilon = 1e-255,

	Tracking = {},
	TalentMap = {},
	TMW = TMW,
	GCDSpell = TMW.GCDSpell,
} CNDT.Env = Env

-- helper functions
local OnGCD = TMW.OnGCD
local GetSpellCooldown = GetSpellCooldown
function Env.CooldownDuration(spell, time)
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
function Env.ItemCooldownDuration(itemID, time)
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

function Env.AuraStacks(unit, name, filter)
	local buffName, _, _, count = UnitAura(unit, name, nil, filter)
	if not buffName then
		return 0
	elseif buffName and count == 0 then
		return 1
	else
		return count
	end
end

function Env.AuraCount(unit, name, filter)
	local n = 0
	for i = 1, 60 do
		local buffName = UnitAura(unit, i, filter)
		if not buffName then
			return n
		elseif strlower(buffName) == name then
			n = n + 1
		end
	end
	return n
end

function Env.AuraDur(unit, name, filter, time)
	local buffName, _, _, _, _, duration, expirationTime = UnitAura(unit, name, nil, filter)
	if not buffName then
		return 0
	else
		return expirationTime == 0 and huge or expirationTime - time
	end
end

function Env.TotemDuration(slot, time)
	local have, name, start, duration = GetTotemInfo(slot)
	return duration and duration ~= 0 and (duration - (time - start)) or 0
end

function Env.GetTooltipNumber(unit, name, filter)
	local buffName, _, _, count, _, _, _, _, _, _, _, _, _, v1, v2, v3 = UnitAura(unit, name, nil, filter)
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

Env.UnitNameConcatCache = setmetatable(
{}, {
	__index = function(t, i)
		if not i then return end

		local o = ";" .. strlowerCache[i] .. ";"
		t[i] = o
		return o
	end,
})




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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_HEALTH_FREQUENT", c.Unit, "UNIT_MAXHEALTH", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit, "UNIT_DISPLAYPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_MAXPOWER", c.Unit, "UNIT_POWER_BAR_SHOW", c.Unit, "UNIT_POWER_BAR_HIDE", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER", c.Unit
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
		funcstr = [[c.Level == GetEclipseDirection() == "sun" and 1 or 0]],
		hidden = pclass ~= "DRUID",
		events = "ECLIPSE_DIRECTION_CHANGE",
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
		events = function()
			return "UNIT_HAPPINESS", "pet", "UNIT_POWER", "pet"
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
		events = function(c)
			return "RUNE_POWER_UPDATE", "RUNE_TYPE_UPDATE"
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
		events = "UNIT_COMBO_POINTS",
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_HEALTH_FREQUENT", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_DISPLAYPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_POWER_FREQUENT", c.Unit, "UNIT_POWER_BAR_SHOW", c.Unit, "UNIT_POWER_BAR_HIDE", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXHEALTH", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit, "UNIT_DISPLAYPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_MAXPOWER", c.Unit, "UNIT_POWER_BAR_SHOW", c.Unit, "UNIT_POWER_BAR_HIDE", c.Unit
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
		events = function(c)
			--if c.Unit == "mouseover" then -- there is no event for when you are no longer mousing over a unit, so we cant use this
			--	return "UPDATE_MOUSEOVER_UNIT"
			--else
				return CNDT:IsUnitEventUnit(c.Unit) -- this should work
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_HEALTH", c.Unit
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
		events = function(c)
			if c.Unit == "player" then
				return "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"
			else
				return CNDT:IsUnitEventUnit(c.Unit), "UNIT_FLAGS", c.Unit, "UNIT_DYNAMIC_FLAGS", c.Unit -- idk if UNIT_DYNAMIC_FLAGS is needed. but lets do it anyway.
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_ENTERED_VEHICLE", c.Unit, "UNIT_EXITED_VEHICLE", c.Unit, "UNIT_VEHICLE", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_FACTION", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_FLAGS", c.Unit, "UNIT_DYNAMIC_FLAGS", c.Unit
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
		funcstr = [[c.1nil == (strfind(c.Name, UnitNameConcatCache[UnitName(c.Unit) or ""]) and 1)]],
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_NAME_UPDATE", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_LEVEL", c.Unit
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit) -- classes cant change, so this is all we should need
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_CLASSIFICATION_CHANGED", c.Unit
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
		events = function(c)
			-- the unit change events should actually cover many of the changes (at least for party and raid units, but roles only exist in party and raid anyway.)
			return CNDT:IsUnitEventUnit(c.Unit), "PLAYER_ROLES_ASSIGNED", "ROLE_CHANGED_INFORM"
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
		events = "RAID_TARGET_UPDATE",
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
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), CNDT:IsUnitEventUnit(c.Name)
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
		events = function(c)
			return "ZONE_CHANGED_NEW_AREA", "PLAYER_DIFFICULTY_CHANGED"
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
		funcstr = [[((GetNumRaidMembers() > 0 and 2) or (GetNumPartyMembers() > 0 and 1) or 0) c.Operator c.Level]], -- this one was harder than it should have been to figure out; keep it in mind for future condition creating
		events = function(c)
			return "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE"
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
		events = function(c)
			return "UNIT_AURA", "player" -- hopefully this is adequate
		end,
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
		events = "PLAYER_UPDATE_RESTING",
	},
	{ -- stance
		text = 	pclass == "HUNTER" and L["ASPECT"] or
				pclass == "PALADIN" and L["AURA"] or
				pclass == "DEATHKNIGHT" and L["PRESENCE"] or
				pclass == "DRUID" and L["SHAPESHIFT"] or
				--pclass == "WARRIOR" and L["STANCE"] or
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
		events = "UPDATE_SHAPESHIFT_FORM",
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
		funcstr = [[c.Level == GetActiveTalentGroup()]],
		events = function(c)
			return "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED"
		end,
	},
	{ -- talent tree
		text = L["UIPANEL_TREE"],
		category = L["CNDTCAT_ATTRIBUTES_PLAYER"],
		value = "TREE",
		min = 1,
		max = 3,
		midt = true,
		texttable = function(i) return select(2, GetTalentTabInfo(i)) end,
		unit = PLAYER,
		icon = function() return select(4, GetTalentTabInfo(1)) end,
		tcoords = standardtcoords,
		funcstr = [[GetPrimaryTalentTree() c.Operator c.Level]],
		events = function(c)
			return "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED"
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
		funcstr = [[(TalentMap[c.NameName] or 0) c.Operator c.Level]],
		events = function(c)
			-- this is handled externally because TalentMap is so extensive a process,
			-- and if it does get stuck in an OnUpdate condition, it could be very bad.
			CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
			CNDT:PLAYER_TALENT_UPDATE()
			-- we still only need to update the condition when talents change, though.
			return "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED"
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
		events = "PET_BAR_UPDATE",
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
		events = "PET_BAR_UPDATE",
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
		funcstr = [[(GetTalentTabInfo(1, nil, 1) or 0) c.Operator c.Level]],
		events = function()
			return "UNIT_PET", "player"
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
		events = function()
			-- keep this event based because it is so extensive
			CNDT:RegisterEvent("MINIMAP_UPDATE_TRACKING")
			CNDT:MINIMAP_UPDATE_TRACKING()
			return "MINIMAP_UPDATE_TRACKING"
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
		funcstr = [[CooldownDuration(c.NameFirst, time) c.Operator c.Level]],
		events = function(c)
			return "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE"
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
		funcstr = [[CooldownDuration(c.NameFirst, time) c.Operator CooldownDuration(c.NameFirst2, time)]],
		events = function(c)
			return "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE"
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
		events = "SPELL_UPDATE_USABLE",
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
		funcstr = [[c.nil1 == select(2, IsUsableSpell(c.NameFirst))]],
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
		funcstr = [[(GCD > 0 and GCD < 1.7) == c.True]],
		events = function(c)
			return "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE"
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
		funcstr = [[ItemCooldownDuration(c.ItemID, time) c.Operator c.Level]],
		spacebefore = true,
		events = "BAG_UPDATE_COOLDOWN",
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
		funcstr = [[ItemCooldownDuration(c.ItemID, time) c.Operator ItemCooldownDuration(c.ItemID2, time)]],
		events = "BAG_UPDATE_COOLDOWN",
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
		events = function(c)
			return "BAG_UPDATE", "UNIT_INVENTROY_CHANGED", "player"
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
		events = function(c)
			return "BAG_UPDATE", "UNIT_INVENTROY_CHANGED", "player"
		end,
	},

	{ -- totem1
		text = totems[1],
		value = "TOTEM1",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		texttable = absentseconds,
		icon = totemtex[1],
		tcoords = standardtcoords,
		funcstr = [[TotemDuration(1, time) c.Operator c.Level]],
		events = "PLAYER_TOTEM_UPDATE",
		anticipate = function(c)
			return [[local VALUE = time + TotemDuration(1, time) - c.Level]]
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
		texttable = absentseconds,
		icon = totemtex[2],
		tcoords = standardtcoords,
		funcstr = [[TotemDuration(2, time) c.Operator c.Level]],
		events = "PLAYER_TOTEM_UPDATE",
		anticipate = function(c)
			return [[local VALUE = time + TotemDuration(2, time) - c.Level]]
		end,
		hidden = not totems[2],
	},
	{ -- totem3
		text = totems[3],
		value = "TOTEM3",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		texttable = absentseconds,
		icon = totemtex[3],
		tcoords = standardtcoords,
		funcstr = [[TotemDuration(3, time) c.Operator c.Level]],
		events = "PLAYER_TOTEM_UPDATE",
		anticipate = function(c)
			return [[local VALUE = time + TotemDuration(3, time) - c.Level]]
		end,
		hidden = not totems[3],
	},
	{ -- totem4
		text = totems[4],
		value = "TOTEM4",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 60,
		unit = false,
		texttable = absentseconds,
		icon = totemtex[4],
		tcoords = standardtcoords,
		funcstr = [[TotemDuration(4, time) c.Operator c.Level]],
		events = "PLAYER_TOTEM_UPDATE",
		anticipate = function(c)
			return [[local VALUE = time + TotemDuration(4, time) - c.Level]]
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
		events = function(c)
			-- holy shit... need i say more?
			return CNDT:IsUnitEventUnit(c.Unit),
			"UNIT_SPELLCAST_START", c.Unit,
			"UNIT_SPELLCAST_STOP", c.Unit,
			"UNIT_SPELLCAST_FAILED", c.Unit,
			"UNIT_SPELLCAST_DELAYED", c.Unit,
			"UNIT_SPELLCAST_INTERRUPTED", c.Unit,
			"UNIT_SPELLCAST_CHANNEL_START", c.Unit,
			"UNIT_SPELLCAST_CHANNEL_UPDATE", c.Unit,
			"UNIT_SPELLCAST_CHANNEL_STOP", c.Unit,
			"UNIT_SPELLCAST_CHANNEL_INTERRUPTED", c.Unit,
			"UNIT_SPELLCAST_INTERRUPTIBLE", c.Unit,
			"UNIT_SPELLCAST_NOT_INTERRUPTIBLE", c.Unit
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
			return [[AuraDur(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
		end,
		anticipate = function(c)
			return [[local _, _, _, _, _, _, expirationTime = UnitAura(c.Unit, c.NameName, nil, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[")
			local VALUE = expirationTime and expirationTime - c.Level or 0]]
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
			return [[AuraDur(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator AuraDur(c.Unit, c.NameName2, "HELPFUL]] .. (c.Checked2 and "|PLAYER" or "") .. [[", time)]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
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
			return [[AuraStacks(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
		end,
	},
	{ -- unit buff tooltip
		text = L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"],
		tooltip = L["TOOLTIPSCAN_DESC"],
		value = "BUFFTOOLTIP",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 500,
		texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"], "TOOLTIPSCAN_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		icon = "Interface\\Icons\\inv_elemental_primal_mana",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[GetTooltipNumber(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
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
			return [[AuraCount(c.Unit, "]]..strlower(TMW:GetSpellNames(nil, c.Name, 1, 1))..[[", "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
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
			return [[AuraDur(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
		end,
		anticipate = function(c)
			return [[local _, _, _, _, _, _, expirationTime = UnitAura(c.Unit, c.NameName, nil, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[")
			local VALUE = expirationTime and expirationTime - c.Level or 0]]
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
			return [[AuraDur(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator AuraDur(c.Unit, c.NameName2, "HARMFUL]] .. (c.Checked2 and "|PLAYER" or "") .. [[", time)]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
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
			return [[AuraStacks(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
		end,
	},
	{ -- unit debuff tooltip
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"],
		tooltip = L["TOOLTIPSCAN_DESC"],
		value = "DEBUFFTOOLTIP",
		category = L["CNDTCAT_BUFFSDEBUFFS"],
		range = 500,
		texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"], "TOOLTIPSCAN_DESC", 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
		icon = "Interface\\Icons\\spell_shadow_lifedrain",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[GetTooltipNumber(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
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
			return [[AuraCount(c.Unit, "]]..strlower(TMW:GetSpellNames(nil, c.Name, 1, 1))..[[", "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
		events = function(c)
			return CNDT:IsUnitEventUnit(c.Unit), "UNIT_AURA", c.Unit
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
		events = function()
			return "UNIT_INVENTORY_CHANGED", "player"
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
		events = function()
			return "UNIT_INVENTORY_CHANGED", "player"
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
		events = function()
			return "UNIT_INVENTORY_CHANGED", "player"
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
		events = function() return "UNIT_STATS", "player" end,
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
		events = function() return "UNIT_STATS", "player" end,
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
		events = function() return "UNIT_STATS", "player" end,
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
		events = function() return "UNIT_STATS", "player" end,
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
		events = function() return "UNIT_STATS", "player" end,
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
		events = "MASTERY_UPDATE",
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
		events = function() return "UNIT_ATTACK_POWER", "player" end,
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
		events = "COMBAT_RATING_UPDATE",
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
		events = function() return "UNIT_ATTACK_SPEED", "player" end,
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
		events = "COMBAT_RATING_UPDATE",
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
		events = function() return "UNIT_RANGED_ATTACK_POWER", "player" end,
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
		events = "COMBAT_RATING_UPDATE",
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
		events = function() return "UNIT_RANGEDDAMAGE", "player" end,
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
		events = "PLAYER_DAMAGE_DONE_MODS",
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
		events = "PLAYER_DAMAGE_DONE_MODS",
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
		events = "COMBAT_RATING_UPDATE",
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
		events = function() return "COMBAT_RATING_UPDATE", "UNIT_SPELL_HASTE", "player" end,
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
		-- events = EVENTS NEEDED FOR THIS!!
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
		-- events = EVENTS NEEDED FOR THIS!!
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
			if icon.class == TMW.Classes.Icon then
				TMW:QueueValidityCheck(c.Icon, icon.group:GetID(), icon:GetID(), g, i)
			else
				TMW:QueueValidityCheck(c.Icon, icon:GetID(), nil, g, i)
			end

			local str = [[(c.Icon and c.Icon.__shown and c.Icon.OnUpdate and not c.Icon:Update())]]
			if c.Level == 0 then
				str = str .. [[and c.Icon.__alpha > 0]]
			else
				str = str .. [[and c.Icon.__alpha == 0]]
			end
			return gsub(str, "c.Icon", c.Icon)
		end,
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
		-- events = absolutely no events
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
					events = "CURRENCY_DISPLAY_UPDATE",
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

local EnvMeta = {
	__index = _G,
	--__newindex = _G,
} TMW.CNDT.EnvMeta = EnvMeta

function CNDT:TMW_GLOBAL_UPDATE()
	Env.Locked = db.profile.Locked
	NumShapeshiftForms = GetNumShapeshiftForms()
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", CNDT)


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
				local after = strmatch(unit, "^%%[Uu]%-?(.*)")
				-- it is intended that we sub in parent:GetName() instead of "icon". 
				-- We want to create unique ConditionObjects for each icon that uses %u
				local sub = "(" .. parent:GetName() .. ".__unitChecked or '')"
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
	gsub("c.NameFirst2", 	"\"" .. TMW:GetSpellNames(nil, name2, 1) .. "\""): --Name2 must be before Name
	gsub("c.NameName2", 	"\"" .. TMW:GetSpellNames(nil, name2, 1, 1) .. "\""):
	gsub("c.ItemID2", 		TMW:GetItemIDs(nil, name2, 1)):
	gsub("c.Name2", 		"\"" .. name2 .. "\""):

	gsub("c.NameFirst", 	"\"" .. TMW:GetSpellNames(nil, name, 1) .. "\""):
	gsub("c.NameName", 		"\"" .. TMW:GetSpellNames(nil, name, 1, 1) .. "\""):
	gsub("c.ItemID", 		TMW:GetItemIDs(nil, name, 1)):
	gsub("c.Name", 			"\"" .. name .. "\""):

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

local activeEventsReusable = {}
function CNDT:CompileUpdateFunction(parent, obj, activeEvents)
	local Conditions = obj.settings
	activeEvents = activeEvents or wipe(activeEventsReusable)
	local numAnticipatorArgs = 0
	local anticipatorstr = ""

	for i = 1, Conditions.n do
		local c = Conditions[i]
		local t = c.Type
		local v = CNDT.ConditionsByType[t]
		if v and v.events then
			local voidNext
			for n, value in TMW:Vararg(TMW.get(v.events, c)) do
				if value == "OnUpdate" then
					return
				end

				if voidNext then
					-- voidNext is an event. value should be a unitID that we are going to associate with the event
					assert(not value:find("[A-Z]"))
					activeEvents[voidNext .. "|'" .. value .. "'"] = true
					voidNext = nil
				else
					-- value is an event
					if value == "unit_changed_event" then
						if c.Unit == "target" then
							activeEvents.PLAYER_TARGET_CHANGED = true
						elseif c.Unit == "pet" then
							activeEvents["UNIT_PET|'player'"] = true
						elseif c.Unit == "focus" then
							activeEvents.PLAYER_FOCUS_CHANGED = true
						elseif c.Unit:find("^raid%d+$") then
							activeEvents.RAID_ROSTER_UPDATE = true
						elseif c.Unit:find("^party%d+$") then
							activeEvents.PARTY_MEMBERS_CHANGED = true
						elseif c.Unit:find("^boss%d+$") then
							activeEvents.INSTANCE_ENCOUNTER_ENGAGE_UNIT = true
						elseif c.Unit:find("^arena%d+$") then
							activeEvents.ARENA_OPPONENT_UPDATE = true
						end
					elseif value:find("^UNIT_") then
						voidNext = value -- tell the iterator to listen to the next value as a unitID
					else
						activeEvents[value] = true
					end
				end
			end
		else
			return
		end

		-- handle code that anticipates when a change in state will occur.
		-- this is usually used to predict when a duration threshold will be used, but you could really use it for whatever you want.
		if v.anticipate then
			numAnticipatorArgs = numAnticipatorArgs + 1

			local thisstr = TMW.get(v.anticipate, c) -- get the anticipator string from the condition data
			thisstr = CNDT:DoConditionSubstitutions(parent, v, c, thisstr) -- substitute in any user settings

			-- append a check to make sure that the smallest value out of all anticipation checks isnt less than the current time.
			thisstr = thisstr .. [[
			if VALUE <= time then
				VALUE = huge
			end]]

			-- change VALUE to the appropriate ARGUMENT#
			thisstr = thisstr:gsub("VALUE", "ARGUMENT" .. numAnticipatorArgs)

			anticipatorstr = anticipatorstr .. "\r\n" .. thisstr
		end
	end

	if not next(activeEvents) then
		return
	end

	local doesAnticipate
	if anticipatorstr ~= "" then
		local allVars = ""
		for i = 1, numAnticipatorArgs do
			allVars = allVars .. "ARGUMENT" .. i .. ","
		end
		allVars = allVars:sub(1, -2)

		anticipatorstr = anticipatorstr .. ([[
		local nextTime = %s
		if nextTime == 0 then
			nextTime = huge
		end
		obj.NextUpdateTime = nextTime]]):format((numAnticipatorArgs == 1 and allVars or "min(" .. allVars .. ")"))

		doesAnticipate = true
	end

	obj.UpdateMethod = "OnEvent" --DEBUG: COMMENTING THIS LINE FORCES ALL CONDITIONS TO BE ONUPDATE DRIVEN

	local numberOfIfs = 0
	local funcstr = [[
	if not event then
		return
	elseif (]]
	for event in pairs(activeEvents) do
		local thisstr

		if event:find("|") then
			-- event contains both the event and a arg to check, separated by "|".
			-- args should be string wrapped if they are supposed to be strings, because we want to allow variable substitution too
			local realEvent, arg = strsplit("|", event)
			activeEvents[event] = realEvent --associate the entry with the real event

			thisstr = ([[event == %q and arg1 == %s]]):format(realEvent, arg)
		else
			thisstr = ([[event == %q]]):format(event)
		end

		funcstr = funcstr .. [[(]] .. thisstr .. [[) or ]]
	end

	funcstr = funcstr:sub(1, -5) .. [[) then
		obj.UpdateNeeded = true
	end]]

	funcstr = anticipatorstr .. "\r\n" .. funcstr
	
	funcstr = [[local obj, event, arg1 = ...
	]] .. funcstr

	-- clear out all existing funcs for the icon
	CNDT.EventEngine:UnregisterObject(obj)

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

	if func then
		for event, realEvent in pairs(activeEvents) do
			if realEvent ~= true then
				event = realEvent
			end
			CNDT.EventEngine:Register(event, func, obj)
		end
	end
end

function CNDT:IsUnitEventUnit(unit)
	if	unit == "player"
	or	unit == "pet"
	or	unit == "target"
	or	unit == "focus"
	or	unit:find("^raid%d+$")
	or	unit:find("^party%d+$")
	or	unit:find("^boss%d+$")
	or	unit:find("^arena%d+$")
	then
		return "unit_changed_event"
	end
	return "OnUpdate"
end




local ConditionObject = TMW:NewClass("ConditionObject")


function ConditionObject:OnNewInstance(parent, Conditions, conditionString, updateFuncArg1)
	self.settings = Conditions
	self.conditionString = conditionString
	
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
	
	CNDT:CompileUpdateFunction(parent, self, updateFuncArg1)
end

function ConditionObject:Check(parent)
	if self.CheckFunction then
	
		if self.UpdateMethod == "OnEvent" then
			self.UpdateNeeded = nil
			
			if self.AnticipateFunction then
				self:AnticipateFunction()
			end
		end
		local time = TMW.time
		if self.NextUpdateTime < time then
			self.NextUpdateTime = huge
		end
		
		if self.LastUpdateTime ~= time then
			self.LastUpdateTime = time
			self.LastCheckFailed = self.Failed
		end
		
		self.Failed = not self:CheckFunction(parent)
	end
end

function CNDT:GetConditionObject(parent, Conditions)
	local conditionString, updateFuncArg1 = CNDT:GetConditionCheckFunctionString(parent, Conditions)
	
	if conditionString and conditionString ~= "" then
		local instances = ConditionObject.instances
		for i = 1, #instances do
			local instance = instances[i]
			if instance.conditionString == conditionString then
				return instance
			end
		end
		return ConditionObject:New(parent, Conditions, conditionString, updateFuncArg1)
	end
end


function CNDT.Conditions_LoadData(self, Conditions)
end

function CNDT:GetConditionCheckFunctionString(parent, Conditions)
	if TMW.debug and test then test() end

	local funcstr = ""
	
	if not CNDT:CheckParentheses(nil, Conditions) then
		return ""
	end

	for i = 1, Conditions.n do
		local c = Conditions[i]
		local t = c.Type
		local v = TMW.CNDT.ConditionsByType[t]

		local andor
		if c.AndOr == "OR" then
			andor = "or " --have a space so they are both 3 chars long
		else
			andor = "and"
		end

		if c.Operator == "~|=" then
			c.Operator = "~=" -- fix potential corruption from importing a string (a single | becaomes || when pasted, "~=" in encoded as "~|=")
		end

		local thiscondtstr
		if v then
			thiscondtstr = v.funcstr
			if type(thiscondtstr) == "function" then
				thiscondtstr = thiscondtstr(c, parent)
			end
		end
		
		thiscondtstr = thiscondtstr or "true"
		
		local thisstr = andor .. "(" .. strrep("(", c.PrtsBefore) .. thiscondtstr .. strrep(")", c.PrtsAfter)  .. ")"

		thisstr = CNDT:DoConditionSubstitutions(parent, v, c, thisstr)

		funcstr = funcstr .. thisstr
	end
	
	local funcstr, arg1 = parent:FinishCompilingConditions(funcstr:sub(4))
	
	if funcstr ~= "" then
		funcstr = [[local obj, icon = ...
		return (]] .. funcstr .. [[)]]
	end
	
	return funcstr, arg1
end


function CNDT:CheckParentheses(type, settings)

	local numclose, numopen, runningcount = 0, 0, 0
	local unopened = 0

	for Condition in TMW:InConditions(settings) do
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
		
		if type then
			TMW.HELP:Show("CNDT_PARENTHESES_ERROR", nil, TMW.IE.Conditions, 0, 0, L["PARENTHESIS_WARNING1"], num, L["PARENTHESIS_TYPE_" .. typeNeeded])

			CNDT[type.."invalid"] = 1
		end
		
		return false
	elseif unopened > 0 then
		if type then
			TMW.HELP:Show("CNDT_PARENTHESES_ERROR", nil, TMW.IE.Conditions, 0, 0, L["PARENTHESIS_WARNING2"], unopened)

			CNDT[type.."invalid"] = 1
		end
		
		return false
	else
		if type then
			TMW.HELP:Hide("CNDT_PARENTHESES_ERROR")
			CNDT[type.."invalid"] = nil
		end
		
		return true
	end
end

CNDT.EventEngine = CreateFrame("Frame")
CNDT.EventEngine.funcs = {}
function CNDT.EventEngine:Register(event, func, obj)
	self:RegisterEvent(event)
	CNDT.EventEngine.funcs[event] = CNDT.EventEngine.funcs[event] or {}
	CNDT.EventEngine.funcs[event][obj] = func
end

function CNDT.EventEngine:UnregisterObject(obj)
	for event, funcs in pairs(CNDT.EventEngine.funcs) do
		for objKey in pairs(funcs) do
			if obj == objKey then
				funcs[objKey] = nil
			end
		end
	end
end

function CNDT.EventEngine:OnEvent(event, arg1)
	local funcs = self.funcs[event]
	if funcs then
		for obj, func in next, funcs do
			func(obj, event, arg1)
		end
	end
end
CNDT.EventEngine:SetScript("OnEvent", CNDT.EventEngine.OnEvent)
