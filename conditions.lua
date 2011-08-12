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
local GetNumPartyMembers, GetNumRaidMembers =
	  GetNumPartyMembers, GetNumRaidMembers
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

local CNDT = TMW:NewModule("Conditions", "AceEvent-3.0") TMW.CNDT = CNDT

hooksecurefunc(TMW, "OnInitialize", function()
	db = TMW.db
end)

local test
--[[test = function()
	test = nil
	print("|cffffffffRUNNING CONDITION TESTS")
	local icon = CreateFrame("Button", "TESTICON")
	Env.TESTICON = icon
	icon.Conditions = {}
	for k, v in ipairs(CNDT.Types) do
		icon.Conditions[k] = CopyTable(TMW.Icon_Defaults.Conditions["**"])
		icon.Conditions[k].Type = v.value
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
end]]

local classes = {
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
	totemtex = { --TODO: change these to GetSpellTexture(#####)
		"Interface\\Icons\\spell_nature_guardianward",
		"Interface\\Icons\\spell_nature_stoneskintotem",
		"Interface\\Icons\\spell_nature_manaregentotem",
		"Interface\\Icons\\spell_nature_slowingtotem",
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
for k, v in ipairs(TMW.Stances) do
	if v.class == pclass then
		firststanceid = v.id
		break
	end
end

function CNDT:ECLIPSE_DIRECTION_CHANGE()
	Env.EclipseDir = GetEclipseDirection() == "sun" and 1 or 0
end

function CNDT:ZONE_CHANGED_NEW_AREA()
	local _, z = IsInInstance()
	if z == "pvp" then
		Env.ZoneType = 1
	elseif z == "arena" then
		Env.ZoneType = 2
	elseif z == "party" then
		Env.ZoneType = 2 + GetInstanceDifficulty() --3-4
	elseif z == "raid" then
		Env.ZoneType = 4 + GetInstanceDifficulty() --5-8
	else
		Env.ZoneType = 0
	end
end

function CNDT:PLAYER_UPDATE_RESTING()
	Env.Resting = IsResting()
end

function CNDT:PARTY_MEMBERS_CHANGED()
	Env.NumPartyMembers = GetNumPartyMembers()
end

function CNDT:RAID_ROSTER_UPDATE()
	Env.NumRaidMembers = GetNumRaidMembers()
end

local GetShapeshiftForm = TMW.GetShapeshiftForm
local RevCSN = {}
for k, v in pairs(TMW.CSN) do
	RevCSN[v] = k
end
function CNDT:UPDATE_SHAPESHIFT_FORM()
	local i = GetShapeshiftForm()
	if i == 0 then
		Env.ShapeshiftForm = 0
	else
		local _, n = GetShapeshiftFormInfo(i)
		Env.ShapeshiftForm = RevCSN[n] or 0
	end
end

function CNDT:UNIT_STATS(_, unit)
	if unit == "player" then
		for i = 1, 5 do
			local _, val = UnitStat("player", i)
			Env["UnitStat" .. i] = val
		end
	end
end

function CNDT:UNIT_ATTACK_POWER(_, unit)
	if unit == "player" then
		local base, pos, neg = UnitAttackPower("player")
		Env.MeleeAttackPower = base + pos + neg
	end
end

function CNDT:UNIT_ATTACK_SPEED(_, unit)
	if unit == "player" then
		Env.MeleeHaste = GetMeleeHaste()/100
	end
end

function CNDT:UNIT_RANGED_ATTACK_POWER(_, unit)
	if unit == "player" then
		local base, pos, neg = UnitRangedAttackPower("player")
		Env.RangeAttackPower = base + pos + neg
	end
end

function CNDT:UNIT_RANGEDDAMAGE(_, unit)
	if unit == "player" then
		Env.RangeHaste = GetRangedHaste()/100
	end
end

function CNDT:COMBAT_RATING_UPDATE()
	Env.Expertise = GetExpertise()
	Env.MeleeCrit = GetCritChance()/100
	Env.RangeCrit = GetRangedCritChance()/100

	local minCrit = GetSpellCritChance(2)
	for i=3, MAX_SPELL_SCHOOLS do
		minCrit = min(minCrit, GetSpellCritChance(i))
	end
	Env.SpellCrit = minCrit/100
	Env.SpellHaste = UnitSpellHaste("player")/100
end

function CNDT:MASTERY_UPDATE()
	Env.Mastery = GetMastery()
end

function CNDT:PLAYER_DAMAGE_DONE_MODS()
	local minModifier = GetSpellBonusDamage(2)
	for i=3, MAX_SPELL_SCHOOLS do
		minModifier = min(minModifier, GetSpellBonusDamage(i))
	end
	Env.SpellDamage = minModifier
	Env.SpellHealing = GetSpellBonusHealing()
end

function CNDT:PLAYER_REGEN_ENABLED()
	Env.PlayerInCombat = nil
end

function CNDT:PLAYER_REGEN_DISABLED()
	Env.PlayerInCombat = 1
end

function CNDT:UNIT_VEHICLE(_, unit)
	if unit == "player" then
		Env.PlayerInVehicle = UnitHasVehicleUI("player")
	end
end



local PetModes = {
    clientVersion >= 40200 and "PET_MODE_ASSIST" or "PET_MODE_AGGRESSIVE",
    "PET_MODE_DEFENSIVE",
    "PET_MODE_PASSIVE",
}
local PetModesLookup = {}
for k, v in pairs(PetModes) do PetModesLookup[v] = k end
function CNDT:PET_BAR_UPDATE()
	for i = NUM_PET_ACTION_SLOTS, 1, -1 do -- go backwards since they are probably at the end of the action bar
		local name, _, _, isToken, isActive = GetPetActionInfo(i)
		if isToken and isActive and PetModesLookup[name] then
			Env.ActivePetMode = PetModesLookup[name]
			break
		end
	end
end

local trackingmap = {}
function CNDT:MINIMAP_UPDATE_TRACKING()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		Env.Tracking[strlower(name)] = active
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

Env = {
	UnitHealth = UnitHealth,
	UnitHealthMax = UnitHealthMax,
	UnitPower = UnitPower,
	UnitPowerMax = UnitPowerMax,
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
	GetNumRaidMembers = GetNumRaidMembers,
	GetNumPartyMembers = GetNumPartyMembers,
	GetRaidTargetIndex = GetRaidTargetIndex,
	UnitIsEnemy = UnitIsEnemy,
	UnitIsUnit = UnitIsUnit,
	UnitReaction = UnitReaction,
	GetRuneType = GetRuneType,
	GetRuneCount = GetRuneCount,
	UnitLevel = UnitLevel,
	strlower = strlower,
	strlowerCache = TMW.strlowerCache,
	strfind = strfind,
	floor = floor,
	select = select,
	IsMounted = IsMounted,
	IsSwimming = IsSwimming,
	GetUnitSpeed = GetUnitSpeed,
	GetManaRegen = GetManaRegen,
	IsUsableSpell = IsUsableSpell,
	UnitBuff = UnitBuff,
	UnitDebuff = UnitDebuff,
	GetWeaponEnchantInfo = GetWeaponEnchantInfo,
	GetItemCount = GetItemCount,
	IsEquippedItem = IsEquippedItem,
	UnitCast = UnitCast,
	IsSpellInRange = IsSpellInRange,
	IsItemInRange = IsItemInRange,
	GetCurrencyInfo = GetCurrencyInfo,
	SecureCmdOptionParse = SecureCmdOptionParse,
	GetSpellAutocast = GetSpellAutocast,

	classifications = classifications,
	roles = roles,
	
	ActivePetMode = 0,
	ZoneType = 0,
	NumPartyMembers = 0,
	NumRaidMembers = 0,
	print = TMW.print,
	time = GetTime(),
	Tracking = {},
	TalentMap = {},
} CNDT.Env = Env

-- helper functions
local OnGCD = TMW.OnGCD
local GetSpellCooldown = GetSpellCooldown
function Env.CooldownDuration(spell, time)
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
function Env.UnitCast(unit, level)
	local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
	end
	if level == 0 then -- only interruptible
		return name and not notInterruptible
	elseif level == 1 then -- present
		return name
	else
		return not name -- absent
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

local huge = math.huge
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

CNDT.Operators = {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}
CNDT.OperatorTooltips = {}
for k, v in pairs(CNDT.Operators) do
	CNDT.OperatorTooltips[v.value] = v.tooltipText
end

CNDT.AndOrs = {
	{ text=L["CONDITIONPANEL_AND"], value="AND" },
	{ text=L["CONDITIONPANEL_OR"], 	value="OR" 	},
}


local function formatSeconds(seconds, arg2)
	if type(seconds) == "table" then
		seconds = arg2
	end
	local d =  seconds / 86400
	local h = (seconds % 86400) / 3600
	local m = (seconds % 86400  % 3600) / 60
	local s =  seconds % 86400  % 3600  % 60

	s = tonumber(format("%.1f", s))
	if s < 10 then
		s = "0" .. s
	end

	if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, s) end
	if h >= 1 then return format("%d:%02d:%s", h, m, s) end
	return format("%d:%s", m, s)
end

-- preset text tables that are frequently used
local percent = function(k) return k.."%" end
local pluspercent = function(k) return "+"..k.."%" end
local bool = {[0] = L["TRUE"],[1] = L["FALSE"],}
local usableunusable = {[0] = L["ICONMENU_USABLE"],[1] = L["ICONMENU_UNUSABLE"],}
local presentabsent = {[0] = L["ICONMENU_PRESENT"],[1] = L["ICONMENU_ABSENT"],}
local absentseconds = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = formatSeconds})
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
		funcstr = [[UnitHealth(c.Unit)/UnitHealthMax(c.Unit) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit)/UnitPowerMax(c.Unit) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit, 0)/UnitPowerMax(c.Unit, 0) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit, 3)/UnitPowerMax(c.Unit, 3) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit, 1)/UnitPowerMax(c.Unit, 1) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit, 2)/UnitPowerMax(c.Unit, 2) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit, 6)/UnitPowerMax(c.Unit, 6) c.Operator c.Level]],
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
		funcstr = [[UnitPower(c.Unit, 10)/UnitPowerMax(c.Unit, 10) c.Operator c.Level]],
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
		funcstr = [[c.Level == EclipseDir]],
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
		hidden = pclass ~= "DEATHKNIGHT",
	},
	{ -- combo
		text = L["CONDITIONPANEL_COMBO"],
		value = "COMBO",
		category = L["CNDTCAT_RESOURCES"],
		min = 0,
		max = 5,
		icon = "Interface\\Icons\\ability_rogue_eviscerate",
		tcoords = standardtcoords,
		funcstr = [[GetComboPoints("player", c.Unit) c.Operator c.Level]],
	},


-------------------------------------status/attributes
	{ -- exists
		text = L["CONDITIONPANEL_EXISTS"],
		category = L["CNDTCAT_STATUS"],
		value = "EXISTS",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\ABILITY_SEAL",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == UnitExists(c.Unit)]],
	},
	{ -- alive
		text = L["CONDITIONPANEL_ALIVE"],
		tooltip = L["CONDITIONPANEL_ALIVE_DESC"],
		category = L["CNDTCAT_STATUS"],
		value = "ALIVE",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\Ability_Vanish",
		tcoords = standardtcoords,
		funcstr = [[c.nil1 == UnitIsDeadOrGhost(c.Unit)]], -- note usage of nil1, not 1nil
	},
	{ -- combat
		text = L["CONDITIONPANEL_COMBAT"],
		category = L["CNDTCAT_STATUS"],
		value = "COMBAT",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\CharacterFrame\\UI-StateIcon",
		tcoords = {0.53, 0.92, 0.05, 0.42},
		funcstr = function(c)
			if strlower(c.Unit) == "player" then
				CNDT:RegisterEvent("PLAYER_REGEN_ENABLED")
				CNDT:RegisterEvent("PLAYER_REGEN_DISABLED")
				Env.PlayerInCombat = UnitAffectingCombat("player")
				return [[c.1nil == PlayerInCombat]]
			else
				return [[c.1nil == UnitAffectingCombat(c.Unit)]]
			end
		end,
	},
	{ -- controlling vehicle
		text = L["CONDITIONPANEL_VEHICLE"],
		category = L["CNDTCAT_STATUS"],
		value = "VEHICLE",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\Ability_Vehicle_SiegeEngineCharge",
		tcoords = standardtcoords,
		funcstr = function(c)
			if strlower(c.Unit) == "player" then
				CNDT:RegisterEvent("UNIT_ENTERED_VEHICLE", "UNIT_VEHICLE")
				CNDT:RegisterEvent("UNIT_EXITED_VEHICLE", "UNIT_VEHICLE")
				Env.PlayerInVehicle = UnitHasVehicleUI("player")
				return [[c.True == PlayerInVehicle]]
			else
				return [[c.True == UnitHasVehicleUI(c.Unit)]]
			end
		end,
	},
	{ -- pvp
		text = L["CONDITIONPANEL_PVPFLAG"],
		category = L["CNDTCAT_STATUS"],
		value = "PVPFLAG",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\TargetingFrame\\UI-PVP-" .. UnitFactionGroup("player"),
		tcoords = {0.046875, 0.609375, 0.015625, 0.59375},
		funcstr = [[c.1nil == UnitIsPVP(c.Unit)]],
	},
	{ -- react
		text = L["ICONMENU_REACT"],
		category = L["CNDTCAT_STATUS"],
		value = "REACT",
		min = 1,
		max = 2,
		texttable = {[1] = L["ICONMENU_HOSTILE"], [2] = L["ICONMENU_FRIEND"]},
		nooperator = true,
		icon = "Interface\\Icons\\Warrior_talent_icon_FuryInTheBlood",
		tcoords = standardtcoords,
		funcstr = [[(((UnitIsEnemy("player", c.Unit) or ((UnitReaction("player", c.Unit) or 5) <= 4)) and 1) or 2) == c.Level]],
	},
	{ -- speed
		text = L["SPEED"],
		tooltip = L["SPEED_DESC"],
		category = L["CNDTCAT_STATUS"],
		value = "SPEED",
		min = 0,
		max = 500,
		percent = true,
		texttable = percent,
		icon = "Interface\\Icons\\ability_rogue_sprint",
		tcoords = standardtcoords,
		funcstr = [[GetUnitSpeed(c.Unit)/]].. BASE_MOVEMENT_SPEED ..[[ c.Operator c.Level]],
	},
	{ -- runspeed
		text = L["RUNSPEED"],
		category = L["CNDTCAT_STATUS"],
		value = "RUNSPEED",
		min = 0,
		max = 500,
		percent = true,
		texttable = percent,
		icon = "Interface\\Icons\\ability_rogue_sprint",
		tcoords = standardtcoords,
		funcstr = [[select(2, GetUnitSpeed(c.Unit))/]].. BASE_MOVEMENT_SPEED ..[[ c.Operator c.Level]],
	},
	{ -- name
		text = L["CONDITIONPANEL_NAME"],
		category = L["CNDTCAT_STATUS"],
		value = "NAME",
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_NAME", "CONDITIONPANEL_NAMETOOLTIP", nil, nil, 1) editbox.label = L["CONDITIONPANEL_NAME"] end,
		nooperator = true,
		texttable = bool,
		icon = "Interface\\LFGFrame\\LFGFrame-SearchIcon-Background",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == (strfind(c.Name, ";" .. strlowerCache[UnitName(c.Unit) or ""] .. ";") and 1)]],
	},
	{ -- level
		text = L["CONDITIONPANEL_LEVEL"],
		category = L["CNDTCAT_STATUS"],
		value = "LEVEL",
		min = -1,
		max = 90,
		texttable = {[-1] = BOSS},
		icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
		tcoords = {0.05, 0.95, 0.03, 0.97},
		funcstr = [[UnitLevel(c.Unit) c.Operator c.Level]],
	},
	{ -- class
		text = L["CONDITIONPANEL_CLASS"],
		category = L["CNDTCAT_STATUS"],
		value = "CLASS",
		min = 1,
		max = #classes,
		texttable = function(k) return classes[k] and LOCALIZED_CLASS_NAMES_MALE[classes[k]] end,
		icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
		nooperator = true,
		tcoords = {
			CLASS_ICON_TCOORDS[pclass][1]+.02,
			CLASS_ICON_TCOORDS[pclass][2]-.02,
			CLASS_ICON_TCOORDS[pclass][3]+.02,
			CLASS_ICON_TCOORDS[pclass][4]-.02,
		},
		funcstr = function(c)
			return [[select(2, UnitClass(c.Unit)) == "]] .. (classes[c.Level] or "whoops") .. "\""
		end,
	},
	{ -- classification
		text = L["CONDITIONPANEL_CLASSIFICATION"],
		category = L["CNDTCAT_STATUS"],
		value = "CLASSIFICATION",
		min = 1,
		max = #classifications,
		texttable = function(k) return L[classifications[k]] end,
		icon = "Interface\\Icons\\achievement_pvp_h_03",
		tcoords = standardtcoords,
		funcstr = [[(classifications[UnitClassification(c.Unit)] or 1) c.Operator c.Level]],
	},
	{ -- role
		text = L["CONDITIONPANEL_ROLE"],
		category = L["CNDTCAT_STATUS"],
		value = "ROLE",
		min = 1,
		max = #roles,
		texttable = setmetatable({[1]=NONE}, {__index = function(t, k) return L[roles[k]] end}),
		icon = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES",
		tcoords = {GetTexCoordsForRole("DAMAGER")},
		funcstr = [[(roles[UnitGroupRolesAssigned(c.Unit)] or 1) c.Operator c.Level]],
	},
	{ -- raid icon
		text = L["CONDITIONPANEL_RAIDICON"],
		category = L["CNDTCAT_STATUS"],
		value = "RAIDICON",
		min = 0,
		max = 8,
		texttable = setmetatable({[0]=NONE}, {__index = function(t, k) return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..k..":0|t ".._G["RAID_TARGET_"..k] end}),
		icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
		funcstr = [[(GetRaidTargetIndex(c.Unit) or 0) c.Operator c.Level]],
	},
	{ -- unit is unit
		text = L["CONDITIONPANEL_UNITISUNIT"],
		tooltip = L["CONDITIONPANEL_UNITISUNIT_DESC"],
		category = L["CNDTCAT_STATUS"],
		value = "UNITISUNIT",
		min = 0,
		max = 1,
		nooperator = true,
		name = function(editbox) TMW:TT(editbox, "UNITTWO", "CONDITIONPANEL_UNITISUNIT_EBDESC", nil, nil, 1) editbox.label = L["UNITTWO"] end,
		texttable = bool,
		icon = "Interface\\Icons\\spell_holy_prayerofhealing",
		tcoords = standardtcoords,
		funcstr = [[UnitIsUnit(c.Unit, c.Unit2) == c.1nil]],
	},
	{ -- unit threat scaled
		text = L["CONDITIONPANEL_THREAT_SCALED"],
		tooltip = L["CONDITIONPANEL_THREAT_SCALED_DESC"],
		category = L["CNDTCAT_STATUS"],
		value = "THREATSCALED",
		min = 0,
		max = 100,
		texttable = percent,
		icon = "Interface\\Icons\\spell_misc_emotionangry",
		tcoords = standardtcoords,
		funcstr = [[(select(3, UnitDetailedThreatSituation("player", c.Unit)) or 0) c.Operator c.Level]],
	},
	{ -- unit threat raw
		text = L["CONDITIONPANEL_THREAT_RAW"],
		tooltip = L["CONDITIONPANEL_THREAT_RAW_DESC"],
		category = L["CNDTCAT_STATUS"],
		value = "THREATRAW",
		min = 0,
		max = 130,
		texttable = percent,
		icon = "Interface\\Icons\\spell_misc_emotionhappy",
		tcoords = standardtcoords,
		funcstr = [[(select(4, UnitDetailedThreatSituation("player", c.Unit)) or 0) c.Operator c.Level]],
	},

	{ -- instance type
		text = L["CONDITIONPANEL_INSTANCETYPE"],
		category = L["CNDTCAT_STATUS"],
		value = "INSTANCE",
		spacebefore = true,
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
		funcstr = [[ZoneType c.Operator c.Level]],
		events = "ZONE_CHANGED_NEW_AREA",
	},
	{ -- grouptype
		text = L["CONDITIONPANEL_GROUPTYPE"],
		category = L["CNDTCAT_STATUS"],
		value = "GROUP",
		min = 0,
		max = 2,
		midt = true,
		unit = false,
		texttable = {[0] = SOLO, [1] = PARTY, [2] = RAID},
		icon = "Interface\\Calendar\\MeetingIcon",
		tcoords = standardtcoords,
		funcstr = [[((NumRaidMembers > 0 and 2) or (NumPartyMembers > 0 and 1) or 0) c.Operator c.Level]], -- this one was harder than it should have been to figure out; keep it in mind for future condition creating
		events = "PARTY_MEMBERS_CHANGED RAID_ROSTER_UPDATE",
	},
	{ -- mounted
		text = L["CONDITIONPANEL_MOUNTED"],
		category = L["CNDTCAT_STATUS"],
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
		category = L["CNDTCAT_STATUS"],
		value = "SWIMMING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsSwimming()]],
	},
	{ -- resting
		text = L["CONDITIONPANEL_RESTING"],
		category = L["CNDTCAT_STATUS"],
		value = "RESTING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\CHARACTERFRAME\\UI-StateIcon",
		tcoords = {0.0625, 0.453125, 0.046875, 0.421875},
		funcstr = [[c.1nil == Resting]],
		events = "PLAYER_UPDATE_RESTING",
	},
	{ -- stance
		text = 	pclass == "HUNTER" and L["ASPECT"] or
				pclass == "PALADIN" and L["AURA"] or
				pclass == "DEATHKNIGHT" and L["PRESENCE"] or
				pclass == "DRUID" and L["SHAPESHIFT"] or
				--pclass == "WARRIOR" and L["STANCE"] or
				L["STANCE"],
		category = L["CNDTCAT_STATUS"],
		value = "STANCE",
		min = 0,
		max = #TMW.CSN,
		texttable = TMW.CSN, -- now isn't this convenient? too bad i have to track them by ID so they wont upgrade properly when stances are added/removed
		unit = PLAYER,
		icon = function() return firststanceid and GetSpellTexture(firststanceid) end,
		tcoords = standardtcoords,
		funcstr = [[ShapeshiftForm c.Operator c.Level]],
		events = "UPDATE_SHAPESHIFT_FORM",
		hidden = #TMW.CSN == 0,
	},
	{ -- talent spec
		text = L["UIPANEL_SPEC"],
		category = L["CNDTCAT_STATUS"],
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
		funcstr = [[c.Level == CurrentSpec]],
	},
	{ -- talent tree
		text = L["UIPANEL_TREE"],
		category = L["CNDTCAT_STATUS"],
		value = "TREE",
		min = 1,
		max = 3,
		midt = true,
		texttable = function(i) return select(2, GetTalentTabInfo(i)) end,
		unit = PLAYER,
		icon = function() return select(4, GetTalentTabInfo(1)) end,
		tcoords = standardtcoords,
		funcstr = [[CurrentTree c.Operator c.Level]],
	}, 
	{ -- points in talent
		text = L["UIPANEL_PTSINTAL"],
		category = L["CNDTCAT_STATUS"],
		value = "PTSINTAL",
		min = 0,
		max = 5,
		unit = PLAYER,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
		useSUG = true,
		icon = function() return select(2, GetTalentInfo(1, 1)) end,
		tcoords = standardtcoords,
		funcstr = [[(TalentMap[c.NameName] or 0) c.Operator c.Level]],
		events = "PLAYER_TALENT_UPDATE",
	},
	{ -- pet autocast
		text = L["CONDITIONPANEL_AUTOCAST"],
		category = L["CNDTCAT_STATUS"],
		value = "AUTOCAST",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PET,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_AUTOCAST", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
		useSUG = true,
		icon = "Interface\\Icons\\ability_physical_taunt",
		tcoords = standardtcoords,
		funcstr = [[select(2, GetSpellAutocast(c.NameName)) == c.1nil]],
	},
	{ -- pet attack mode
		text = L["CONDITIONPANEL_PETMODE"],
		category = L["CNDTCAT_STATUS"],
		value = "PETMODE",
		min = 1,
		max = 3,
		midt = true,
		texttable = function(k) return _G[PetModes[k]] end,
		unit = PET,
		icon = PET_ASSIST_TEXTURE,
		tcoords = standardtcoords,
		funcstr = [[ActivePetMode c.Operator c.Level]],
		events = "PET_BAR_UPDATE",
	},
	{ -- tracking
		text = L["CONDITIONPANEL_TRACKING"],
		category = L["CNDTCAT_STATUS"],
		value = "TRACKING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_TRACKING", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
		useSUG = "tracking",
		icon = "Interface\\MINIMAP\\TRACKING\\None",
		tcoords = standardtcoords,
		funcstr = [[Tracking[c.NameName] == c.1nil]],
		events = "MINIMAP_UPDATE_TRACKING",
	},


-------------------------------------icon functions
	{ -- spell cooldown
		text = L["SPELLCOOLDOWN"],
		value = "SPELLCD",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
		useSUG = true,
		unit = PLAYER,
		texttable = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_USABLE"]..")"}, {__index = formatSeconds}),
		icon = "Interface\\Icons\\spell_holy_divineintervention",
		tcoords = standardtcoords,
		funcstr = [[CooldownDuration(c.NameFirst, time) c.Operator c.Level]],
	},
	{ -- spell cooldown compare
		text = L["SPELLCOOLDOWN"] .. " - " .. L["COMPARISON"],
		value = "SPELLCDCOMP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "SPELLTOCOMP1", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCOMP1"] end,
		name2 = function(editbox) TMW:TT(editbox, "SPELLTOCOMP2", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCOMP2"] end,
		useSUG = true,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_divineintervention",
		tcoords = standardtcoords,
		funcstr = [[CooldownDuration(c.NameFirst, time) c.Operator CooldownDuration(c.NameFirst2, time)]],
	},
	{ -- spell reactivity
		text = L["SPELLREACTIVITY"],
		tooltip = L["REACTIVECNDT_DESC"],
		value = "REACTIVE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "ICONMENU_REACTIVE", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
		check = function(check) TMW:TT(check, "ICONMENU_IGNORENOMANA", "ICONMENU_IGNORENOMANA_DESC", nil, nil, 1) end,
		useSUG = true,
		nooperator = true,
		unit = false,
		texttable = usableunusable,
		icon = "Interface\\Icons\\ability_warrior_revenge",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == ReactiveHelper(c.NameFirst, c.Checked)]], 
	},
	{ -- spell has mana
		text = L["CONDITIONPANEL_MANAUSABLE"],
		value = "MANAUSABLE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_MANAUSABLE", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
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
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_SPELLRANGE", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["SPELLTOCHECK"] end,
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
		useSUG = true,
		unit = PLAYER,
		texttable = bool,
		icon = "Interface\\Icons\\ability_hunter_steadyshot",
		tcoords = standardtcoords,
		funcstr = [[(GCD > 0 and GCD < 1.7) == c.True]],
	},
	
	{ -- item cooldown
		text = L["ITEMCOOLDOWN"],
		value = "ITEMCD",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, L["ITEMCOOLDOWN"], "CNDT_ONLYFIRST", 1, nil, 1) editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		unit = PLAYER,
		texttable = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_USABLE"]..")"}, {__index = formatSeconds}),
		icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
		tcoords = standardtcoords,
		funcstr = [[ItemCooldownDuration(c.ItemID, time) c.Operator c.Level]],
		spacebefore = true,
	},
	{ -- item cooldown compare
		text = L["ITEMCOOLDOWN"] .. " - " .. L["COMPARISON"],
		value = "ITEMCDCOMP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "ITEMTOCOMP1", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["ITEMTOCOMP1"] end,
		name2 = function(editbox) TMW:TT(editbox, "ITEMTOCOMP2", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["ITEMTOCOMP2"] end,
		useSUG = "item",
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
		tcoords = standardtcoords,
		funcstr = [[ItemCooldownDuration(c.ItemID, time) c.Operator ItemCooldownDuration(c.ItemID2, time)]],
	},
	{ -- item range
		text = L["CONDITIONPANEL_ITEMRANGE"],
		value = "ITEMRANGE",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_ITEMRANGE", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		nooperator = true,
		texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
		icon = "Interface\\Icons\\ability_hunter_snipershot",
		tcoords = standardtcoords,
		funcstr = function(c)
			return 1-c.Level .. [[ == (IsItemInRange(c.ItemID, c.Unit) or 0)]]
		end,
	},
	{ -- item in bags
		text = L["ITEMINBAGS"],
		value = "ITEMINBAGS",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 50,
		texttable = function(k) return format(ITEM_SPELL_CHARGES, k) end,
		name = function(editbox) TMW:TT(editbox, "ITEMINBAGS", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		unit = false,
		icon = "Interface\\Icons\\inv_misc_bag_08",
		tcoords = standardtcoords,
		funcstr = [[GetItemCount(c.ItemID, nil, 1) c.Operator c.Level]],
	},
	{ -- item equipped
		text = L["ITEMEQUIPPED"],
		value = "ITEMEQUIPPED",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 1,
		nooperator = true,
		texttable = bool,
		name = function(editbox) TMW:TT(editbox, "ITEMEQUIPPED", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["ITEMTOCHECK"] end,
		useSUG = "item",
		unit = false,
		icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsEquippedItem(c.ItemID)]],
	},

	{ -- unit buff duration
		text = L["ICONMENU_BUFF"] .. " - " .. L["DURATIONPANEL_TITLE"],
		value = "BUFFDUR",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["DURATIONPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		texttable = absentseconds,
		icon = "Interface\\Icons\\spell_nature_rejuvenation",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator c.Level]]
		end,
		spacebefore = true,
	},
	{ -- unit buff duration compare
		text = L["ICONMENU_BUFF"] .. " - " .. L["DURATIONPANEL_TITLE"] .. " - " .. L["COMPARISON"],
		value = "BUFFDURCOMP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "BUFFTOCOMP1", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["BUFFTOCOMP1"] end,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		name2 = function(editbox) TMW:TT(editbox, "BUFFTOCOMP2", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["BUFFTOCOMP2"] end,
		check2 = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		useSUG = true,
		icon = "Interface\\Icons\\spell_nature_rejuvenation",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator AuraDur(c.Unit, c.NameName2, "HELPFUL]] .. (c.Checked2 and "|PLAYER" or "") .. [[", time)]]
		end,
	},
	{ -- unit buff stacks
		text = L["ICONMENU_BUFF"] .. " - " .. L["STACKSPANEL_TITLE"],
		value = "BUFFSTACKS",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["STACKSPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
		icon = "Interface\\Icons\\inv_misc_herb_felblossom",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraStacks(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
	},
	{ -- unit buff tooltip
		text = L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"],
		tooltip = L["TOOLTIPSCAN_DESC"],
		value = "BUFFTOOLTIP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 500,
		texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"], "TOOLTIPSCAN_DESC", 1, nil, 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		icon = "Interface\\Icons\\inv_elemental_primal_mana",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[GetTooltipNumber(c.Unit, c.NameName, "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
	},
	{ -- unit buff number
		text = L["ICONMENU_BUFF"] .. " - " .. L["NUMAURAS"],
		tooltip = L["NUMAURAS_DESC"],
		value = "BUFFNUMBER",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["NUMAURAS"], "BUFFCNDT_DESC", 1, nil, 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		texttable = function(k) return format(L["ACTIVE"], k) end,
		icon = "Interface\\Icons\\ability_paladin_sacredcleansing",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraCount(c.Unit, "]]..strlower(TMW:GetSpellNames(nil, c.Name, 1, 1))..[[", "HELPFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
	},
	{ -- unit debuff duration
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATIONPANEL_TITLE"],
		value = "DEBUFFDUR",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 30,
		step = 0.1,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["DURATIONPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) editbox.label = L["DEBUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		texttable = absentseconds,
		icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator c.Level]]
		end,
	},
	{ -- unit buff duration compare
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATIONPANEL_TITLE"] .. " - " .. L["COMPARISON"],
		value = "DEBUFFDURCOMP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "DEBUFFTOCOMP1", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["DEBUFFTOCOMP1"] end,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		name2 = function(editbox) TMW:TT(editbox, "DEBUFFTOCOMP2", "CNDT_ONLYFIRST", nil, nil, 1) editbox.label = L["DEBUFFTOCOMP2"] end,
		check2 = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		useSUG = true,
		icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraDur(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[", time) c.Operator AuraDur(c.Unit, c.NameName2, "HARMFUL]] .. (c.Checked2 and "|PLAYER" or "") .. [[", time)]]
		end,
	},
	{ -- unit debuff stacks
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["STACKSPANEL_TITLE"],
		value = "DEBUFFSTACKS",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["STACKSPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) editbox.label = L["DEBUFFTOCHECK"]end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
		icon = "Interface\\Icons\\ability_warrior_sunder",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraStacks(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
	},
	{ -- unit debuff tooltip
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"],
		tooltip = L["TOOLTIPSCAN_DESC"],
		value = "DEBUFFTOOLTIP",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 500,
		texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"], "TOOLTIPSCAN_DESC", 1, nil, 1) editbox.label = L["BUFFTOCHECK"] end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		icon = "Interface\\Icons\\spell_shadow_lifedrain",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[GetTooltipNumber(c.Unit, c.NameName, "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
	},
	{ -- unit debuff number
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["NUMAURAS"],
		tooltip = L["NUMAURAS_DESC"],
		value = "DEBUFFNUMBER",
		category = L["CNDTCAT_SPELLSABILITIES"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["NUMAURAS"], "BUFFCNDT_DESC", 1, nil, 1) editbox.label = L["DEBUFFTOCHECK"]end,
		useSUG = true,
		check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC", nil, nil, 1) end,
		texttable = function(k) return format(L["ACTIVE"], k) end,
		icon = "Interface\\Icons\\spell_deathknight_frostfever",
		tcoords = standardtcoords,
		funcstr = function(c)
			return [[AuraCount(c.Unit, "]]..strlower(TMW:GetSpellNames(nil, c.Name, 1, 1))..[[", "HARMFUL]] .. (c.Checked and "|PLAYER" or "") .. [[") c.Operator c.Level]]
		end,
	},

	{ -- mainhand
		text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_WEAPONMAINHAND,
		value = "MAINHAND",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 120,
		unit = false,
		texttable = absentseconds,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_14" end,
		tcoords = standardtcoords,
		funcstr = [[(select(2, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
		spacebefore = true,
	},
	{ -- offhand
		text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_WEAPONOFFHAND,
		value = "OFFHAND",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 120,
		unit = false,
		texttable = absentseconds,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_15" end,
		tcoords = standardtcoords,
		funcstr = [[(select(5, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
	},
	{ -- thrown
		text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_THROWN,
		value = "THROWN",
		category = L["CNDTCAT_SPELLSABILITIES"],
		range = 120,
		unit = false,
		texttable = absentseconds,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("RangedSlot")) or "Interface\\Icons\\inv_throwingknife_06" end,
		tcoords = standardtcoords,
		funcstr = [[(select(8, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
		hidden = pclass ~= "ROGUE",
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
			[0] = L["ICONMENU_ONLYINTERRUPTIBLE"],
			[1] = L["ICONMENU_PRESENT"],
			[2] = L["ICONMENU_ABSENT"],
		},
		midt = true,
		icon = "Interface\\Icons\\Temp",
		tcoords = standardtcoords,
		funcstr = [[UnitCast(c.Unit, c.Level)]],
		spacebefore = true,
	},


-------------------------------------stats
	{ -- strength
		text = _G["SPELL_STAT1_NAME"],
		value = "STRENGTH",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_strength",
		tcoords = standardtcoords,
		funcstr = [[UnitStat1 c.Operator c.Level]],
		events = "UNIT_STATS",
	},
	{ -- agility
		text = _G["SPELL_STAT2_NAME"],
		value = "AGILITY",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_blessingofagility",
		tcoords = standardtcoords,
		funcstr = [[UnitStat2 c.Operator c.Level]],
		events = "UNIT_STATS",
	},
	{ -- stamina
		text = _G["SPELL_STAT3_NAME"],
		value = "STAMINA",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_wordfortitude",
		tcoords = standardtcoords,
		funcstr = [[UnitStat3 c.Operator c.Level]],
		events = "UNIT_STATS",
	},
	{ -- intellect
		text = _G["SPELL_STAT4_NAME"],
		value = "INTELLECT",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_magicalsentry",
		tcoords = standardtcoords,
		funcstr = [[UnitStat4 c.Operator c.Level]],
		events = "UNIT_STATS",
	},
	{ -- spirit
		text = _G["SPELL_STAT5_NAME"],
		value = "SPIRIT",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_shadow_burningspirit",
		tcoords = standardtcoords,
		funcstr = [[UnitStat5 c.Operator c.Level]],
		events = "UNIT_STATS",
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
		funcstr = [[Mastery c.Operator c.Level]],
		events = "MASTERY_UPDATE",
	},

	{ -- melee AP
		text = MELEE_ATTACK_POWER,
		value = "MELEEAP",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\INV_Sword_04",
		tcoords = standardtcoords,
		funcstr = [[MeleeAttackPower c.Operator c.Level]],
		events = "UNIT_ATTACK_POWER",
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
		funcstr = [[MeleeCrit c.Operator c.Level]],
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
		funcstr = [[MeleeHaste c.Operator c.Level]],
		events = "UNIT_ATTACK_SPEED",
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
		funcstr = [[Expertise c.Operator c.Level]],
		events = "COMBAT_RATING_UPDATE",
	},

	{ -- ranged AP
		text = RANGED_ATTACK_POWER,
		value = "RANGEAP",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\INV_Weapon_Bow_07",
		tcoords = standardtcoords,
		funcstr = [[RangeAttackPower c.Operator c.Level]],
		events = "UNIT_RANGED_ATTACK_POWER",
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
		funcstr = [[RangeCrit c.Operator c.Level]],
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
		funcstr = [[RangeHaste c.Operator c.Level]],
		events = "UNIT_RANGEDDAMAGE",
	},


	{ -- spell damage
		text = STAT_SPELLDAMAGE,
		value = "SPELLDMG",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_fire_flamebolt",
		tcoords = standardtcoords,
		funcstr = [[SpellDamage c.Operator c.Level]],
		events = "PLAYER_DAMAGE_DONE_MODS",
		spacebefore = true,
	},
	{ -- spell healing
		text = STAT_SPELLHEALING,
		value = "SPELLHEALING",
		category = L["CNDTCAT_STATS"],
		range = 5000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_healingtouch",
		tcoords = standardtcoords,
		funcstr = [[SpellHealing c.Operator c.Level]],
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
		funcstr = [[SpellCrit c.Operator c.Level]],
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
		funcstr = [[SpellHaste c.Operator c.Level]],
		events = "COMBAT_RATING_UPDATE",
	},
	{ -- mana regen
		text = MANA_REGEN,
		value = "MANAREGEN",
		category = L["CNDTCAT_STATS"],
		range = 1000/5,
		unit = PLAYER,
		texttable = function(k) return format(L["MP5"], k*5) end,
		icon = "Interface\\Icons\\spell_magic_managain",
		tcoords = standardtcoords,
		funcstr = [[GetManaRegen() c.Operator c.Level]], -- anyone know of an event that can be reliably listened to to get this?
	},
	{ -- mana in combat
		text = MANA_REGEN_COMBAT,
		value = "MANAREGENCOMBAT",
		category = L["CNDTCAT_STATS"],
		range = 1000/5,
		unit = PLAYER,
		texttable = function(k) return format(L["MP5"], k*5) end,
		icon = "Interface\\Icons\\spell_frost_summonwaterelemental",
		tcoords = standardtcoords,
		funcstr = [[select(2,GetManaRegen()) c.Operator c.Level]],
	},


	"CURRENCYPLACEHOLDER",

	{ -- icon shown
		text = L["CONDITIONPANEL_ICON"],
		tooltip = L["CONDITIONPANEL_ICON_DESC"],
		value = "ICON",
		spacebefore = true,
		min = 0,
		max = 1,
		texttable = bool,
		isicon = true,
		nooperator = true,
		unit = false,
		icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
		tcoords = standardtcoords,
		showhide = function(group)
			group.TextUnitOrIcon:SetText(L["ICONTOCHECK"])
			group.Icon:Show()
		end,
		funcstr = function(c)
			if c.Icon == "" then return [[true]] end
			local str = [[(c.Icon and c.Icon.__shown and c.Icon.OnUpdate and not c.Icon:OnUpdate(time))]]
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
		name = function(editbox) TMW:TT(editbox, "MACROCONDITION", "MACROCONDITION_EB_DESC", nil, nil, 1) editbox.label = L["MACROTOEVAL"] end,
		unit = false,
		icon = "Interface\\Icons\\inv_misc_punchcards_yellow",
		tcoords = standardtcoords,
		funcstr = function(c)
			local text = c.Name
			text = (not strfind(text, "^%[") and ("[" .. text)) or text
			text = (not strfind(text, "%]$") and (text .. "]")) or text
			return [[SecureCmdOptionParse("]] .. text .. [[")]]
		end,
	},
	{ -- Lua
		text = L["LUACONDITION"],
		tooltip = L["LUACONDITION_DESC"],
		value = "LUA",
		min = 0,
		max = 1,
		nooperator = true,
		noslide = true,
		name = function(editbox) TMW:TT(editbox, "LUACONDITION", gsub(L["LUACONDITION_DESC"], "\n", " "), nil, 1, 1) editbox.label = L["CODETOEXE"] end,
		unit = false,
		icon = "Interface\\Icons\\INV_Misc_Gear_01",
		tcoords = standardtcoords,
		funcstr = function(c) return c.Name end,
	},
}

local currencies = {
	-- currencies were extracted using the script in the /Scripts folder (source is wowhead)
	-- make sure and order them here in a way that makes sense (most common first, blah blah derp herping)
	395,	--Justice Points
	396,	--Valor Points
	392,	--Honor Points
	390,	--Conquest Points
	
	-- i dont know what these are
	--483,	--Conquest Arena Meta
	--484,	--Conquest BG Meta
	
	391,	--Tol Barad Commendation
	416,	--Mark of the World Tree
	241,	--Champion\'s Seal
	
	361,	--Illustrious Jewelcrafter\'s Token
	402,	--Chef\'s Award
	61,		--Dalaran Jewelcrafter\'s Token
	81,		--Dalaran Cooking Award
	
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
		for _, id in ipairs(currencies) do
			tinsert(CNDT.Types, k, {
				value = "CURRENCY"..id,
				category = L["CNDTCAT_CURRENCIES"],
				range = 500,
				unit = false,
				funcstr = [[select(2, GetCurrencyInfo(]]..id..[[)) c.Operator c.Level]],
				tcoords = standardtcoords,
				hidden = true,
			})
			k = k + 1
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
CNDT:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
CNDT:CURRENCY_DISPLAY_UPDATE()

local EnvMeta = {
	__index = _G,
	--__newindex = _G,
}

local functionCache = {} CNDT.functionCache = functionCache
function CNDT:ProcessConditions(icon)
	if TMW.debug and test then test() end
	local Conditions = icon.Conditions
	Conditions["**"] = nil -- i dont know why these occasionally pop up, but this seems like a good place to get rid of them
	local funcstr = ""
	local luaUsed
	for i = 1, #Conditions do
		local c = Conditions[i]
		local t = c.Type
		local v = ConditionsByType[t]
		
		local andor
		if c.AndOr == "OR" then
			andor = "or " --have a space so they are both 3 chars long
		else
			andor = "and"
		end
		
		if v then
			if v.events then
				for k, event in TMW:Vararg(strsplit(" ", v.events)) do
					CNDT:RegisterEvent(event)
					CNDT[event](CNDT, event, "player")
				end
			end
			if t == "LUA" then
				luaUsed = 1
				setmetatable(Env, EnvMeta)
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

			local thiscondtstr = v.funcstr
			if type(thiscondtstr) == "function" then
				thiscondtstr = thiscondtstr(c)
			end

			if thiscondtstr then
				local thisstr = andor .. "(" .. strrep("(", c.PrtsBefore) .. thiscondtstr .. strrep(")", c.PrtsAfter)  .. ")"

				
				if strfind(thisstr, "c.Unit2") and (strfind(c.Name, "maintank") or strfind(c.Name, "mainassist")) then -- Unit2 MUST be before Unit
					local unit = gsub(c.Name, "|cFFFF0000#|r", "1")
					thisstr = gsub(thisstr, "c.Unit2",		unit) -- sub it in as a variable
					Env[unit] = unit
					TMW:RegisterEvent("RAID_ROSTER_UPDATE")
					TMW:RAID_ROSTER_UPDATE()
				else
					thisstr = gsub(thisstr, "c.Unit2",	"\"" .. c.Name .. "\"") -- sub it in as a string
				end
				
				if strfind(thisstr, "c.Unit") and (strfind(c.Unit, "maintank") or strfind(c.Unit, "mainassist")) then
					local unit = gsub(c.Unit, "|cFFFF0000#|r", "1")
					thisstr = gsub(thisstr, "c.Unit",		unit) -- sub it in as a variable
					Env[unit] = unit
					TMW:RegisterEvent("RAID_ROSTER_UPDATE")
					TMW:RAID_ROSTER_UPDATE()
				else
					thisstr = gsub(thisstr, "c.Unit",	"\"" .. c.Unit .. "\"") -- sub it in as a string
				end
				

				if v.percent then
					thisstr = gsub(thisstr, "c.Level", 		c.Level/100)
				else
					thisstr = gsub(thisstr, "c.Level", 		c.Level)
					thisstr = gsub(thisstr, "c.1nil", 		c.Level == 0 and 1 or "nil")
					thisstr = gsub(thisstr, "c.nil1", 		c.Level == 1 and 1 or "nil") -- reverse 1nil
				end

				thisstr = thisstr:
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
				gsub("c.False", 		tostring(c.Level == 1))
				funcstr = funcstr .. thisstr
			else
				funcstr = funcstr .. (andor .. "(" .. strrep("(", c.PrtsBefore) .. "true" .. strrep(")", c.PrtsAfter)  .. ")")
			end
		else
			funcstr = funcstr .. (andor .. "(" .. strrep("(", c.PrtsBefore) .. "true" .. strrep(")", c.PrtsAfter)  .. ")")
		end
	end

	if strfind(icon:GetName(), "Icon") then
		funcstr = [[if not (]] .. strsub(funcstr, 4) .. [[) then
			]] .. (icon.ConditionAlpha == 0 and (icon:GetName()..[[:SetAlpha(0) return true, false]]) or (icon:GetName()..[[.CndtFailed = 1 return false, false]])) .. [[
		else
			]]..icon:GetName()..[[.CndtFailed = nil return false, true
		end]]
	else -- its a group condition
		funcstr = [[if not (]] .. strsub(funcstr, 4) .. [[) then
			]] .. icon:GetName() .. [[:Hide() return false, false
		else
			]] .. icon:GetName() .. [[:Show() return false, true
		end]]
	end


	if functionCache[funcstr] then
		icon.CndtCheck = functionCache[funcstr]
		return functionCache[funcstr]
	end

	local func, err = loadstring(funcstr, icon:GetName() .. " Condition")
	if func then
		func = setfenv(func, Env)
		icon.CndtCheck = func
		functionCache[funcstr] = func
		return func
	elseif (TMW.debug or luaUsed) and err then
		print(funcstr)
		geterrorhandler()(err)
	end
end



