-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
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

local strlower, min =
	  strlower, min
local NONE, MAX_SPELL_SCHOOLS =
	  NONE, MAX_SPELL_SCHOOLS
local GetEclipseDirection, IsResting =
	  GetEclipseDirection, IsResting
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
local UnitAura =
	  UnitAura

local _G = _G
local print = TMW.print

local CNDT = TMW:NewModule("Conditions", "AceEvent-3.0") TMW.CNDT = CNDT

hooksecurefunc(TMW, "OnInitialize", function()
	db = TMW.db
end)

local test
test = function()
	if true then return end -- toggle this on and off here
	_G.print("|cffffffffRUNNING CONDITION TESTS")
	test = nil
	local icon = CreateFrame("Button", "TESTICON")
	Env.TESTICON = icon
	icon.Conditions = {}
	for k, v in pairs(CNDT.Types) do
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
function CNDT:UPDATE_SHAPESHIFT_FORM()
	local i = GetShapeshiftForm()
	if i == 0 then
		Env.ShapeshiftForm = NONE
	else
		local _, n = GetShapeshiftFormInfo(i)
		Env.ShapeshiftForm = n
	end
end

function CNDT:UNIT_STATS(unit)
	if unit == "player" then
		for i = 1, 5 do
			local _, val = UnitStat("player", i)
			Env["UnitStat" .. i] = val
		end
	end
end

function CNDT:UNIT_ATTACK_POWER(unit)
	if unit == "player" then
		local base, pos, neg = UnitAttackPower("player")
		Env.MeleeAttackPower = base + pos + neg
	end
end

function CNDT:UNIT_ATTACK_SPEED(unit)
	if unit == "player" then
		Env.MeleeHaste = GetMeleeHaste()/100
	end
end

function CNDT:UNIT_RANGED_ATTACK_POWER(unit)
	if unit == "player" then
		local base, pos, neg = UnitRangedAttackPower("player")
		Env.RangeAttackPower = base + pos + neg
	end
end

function CNDT:UNIT_RANGEDDAMAGE(unit)
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

-- helper functions
local OnGCD = TMW.OnGCD

local GetSpellCooldown = GetSpellCooldown
local function IsSpellOnCooldown(spell)
	local start, duration = GetSpellCooldown(spell)
	return not (duration == 0 or OnGCD(duration))
end

local GetItemCooldown = GetItemCooldown
local function IsItemOnCooldown(itemID)
	local start, duration = GetItemCooldown(itemID)
	return not (duration == 0 or OnGCD(duration))
end

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local function UnitCast(unit, level)
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

local function AuraStacks(unit, name, filter)
	local buffName, _, _, count = UnitAura(unit, name, nil, filter)
	if not buffName then
		return 0
	elseif buffName and count == 0 then
		return 1
	else
		return count
	end
end

local function AuraDur(unit, name, filter)
	local buffName, _, _, _, _, duration, expirationTime = UnitAura(unit, name, nil, filter)
	if not buffName then
		return 0
	else
		return expirationTime == 0 and 0 or expirationTime - TMW.time
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
	UnitIsPVP = UnitIsPVP,
	GetNumRaidMembers = GetNumRaidMembers,
	GetNumPartyMembers = GetNumPartyMembers,
	UnitIsEnemy = UnitIsEnemy,
	UnitReaction = UnitReaction,
	GetRuneType = GetRuneType,
	GetRuneCount = GetRuneCount,
	UnitLevel = UnitLevel,
	strlower = strlower,
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
	AuraStacks = AuraStacks,
	AuraDur = AuraDur,

	IsSpellOnCooldown = IsSpellOnCooldown,
	IsItemOnCooldown = IsItemOnCooldown,

	ZoneType = 0,
	NumPartyMembers = 0,
	NumRaidMembers = 0,
	print = TMW.print,
	time = GetTime()
} CNDT.Env = Env

CNDT.Operators  =  {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}

CNDT.AndOrs = {
	{ text=L["CONDITIONPANEL_AND"], value="AND" },
	{ text=L["CONDITIONPANEL_OR"], 	value="OR" 	},
}

local percent = setmetatable({}, {__index = function(t, k) return k.."%" end})
local pluspercent = setmetatable({}, {__index = function(t, k) return "+"..k.."%" end})
local bool = {[0] = L["TRUE"],[1] = L["FALSE"],}
local usableunusable = {[0] = L["ICONMENU_USABLE"],[1] = L["ICONMENU_UNUSABLE"],}
local presentabsent = {[0] = L["ICONMENU_PRESENT"],[1] = L["ICONMENU_ABSENT"],}
local standardtcoords = {0.07, 0.93, 0.07, 0.93}

CNDT.Types = {
	{ -- health
		text = HEALTH,
		value = "HEALTH",
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
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
		category = L["RESOURCES"],
		min = 0,
		max = 3,
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 7) c.Operator c.Level]],
		shouldshow = pclass == "WARLOCK",
	},
	{ -- holy power
		text = HOLY_POWER,
		value = "HOLY_POWER",
		category = L["RESOURCES"],
		min = 0,
		max = 3,
		unit = PLAYER,
		icon = "Interface\\Icons\\Spell_Holy_Rune",
		tcoords = standardtcoords,
		funcstr = [[UnitPower(c.Unit, 9) c.Operator c.Level]],
		shouldshow = pclass == "PALADIN",
	},
	{ -- eclipse
		text = ECLIPSE,
		tooltip = L["CONDITIONPANEL_ECLIPSE_DESC"],
		value = "ECLIPSE",
		category = L["RESOURCES"],
		min = -100,
		max = 100,
		mint = "-100 (" .. L["MOON"] .. ")",
		maxt = "100 (" .. L["SUN"] .. ")",
		unit = PLAYER,
		icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
		tcoords = {0.65625000, 0.74609375, 0.37500000, 0.55468750},
		funcstr = [[UnitPower(c.Unit, 8) c.Operator c.Level]],
		shouldshow = pclass == "DRUID",
	},
	{ -- eclipse direction
		text = L["ECLIPSE_DIRECTION"],
		value = "ECLIPSE_DIRECTION",
		category = L["RESOURCES"],
		min = 0,
		max = 1,
		texttable = {[0] = L["MOON"], [1] = L["SUN"]},
		unit = PLAYER,
		nooperator = true,
		icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
		tcoords = {0.55859375, 0.64843750, 0.57031250, 0.75000000},
		funcstr = [[c.Level == EclipseDir]],
		shouldshow = pclass == "DRUID",
		events = {"ECLIPSE_DIRECTION_CHANGE"},
	},
	{ -- pet happiness
		text = HAPPINESS,
		value = "HAPPINESS",
		category = L["RESOURCES"],
		min = 1,
		max = 3,
		texttable = setmetatable({}, {__index = function(t, k) return _G["PET_HAPPINESS" .. k] end}),
		unit = PET,
		icon = "Interface\\PetPaperDollFrame\\UI-PetHappiness",
		tcoords = {0.390625, 0.5491, 0.03, 0.3305},
		funcstr = GetPetHappiness and [[(GetPetHappiness() or 0) c.Operator c.Level]] or [[true]], -- dummy string to keep support for wowCN
		shouldshow = not not (GetPetHappiness and (pclass == "HUNTER")), -- dont show if GetPetHappiness doesnt exist (if happiness is removed in the client version), not not because it must be false, not nil
	},
	{ -- runes
		text = RUNES,
		tooltip = L["CONDITIONPANEL_RUNES_DESC"],
		value = "RUNES",
		category = L["RESOURCES"],
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
		shouldshow = pclass == "DEATHKNIGHT",
	},
	{ -- combo
		text = L["CONDITIONPANEL_COMBO"],
		value = "COMBO",
		category = L["RESOURCES"],
		min = 0,
		max = 5,
		icon = "Interface\\Icons\\ability_rogue_eviscerate",
		tcoords = standardtcoords,
		funcstr = [[GetComboPoints("player", c.Unit) c.Operator c.Level]],
	},

-------------------------------------stats
	{ -- strength
		text = _G["SPELL_STAT1_NAME"],
		value = "STRENGTH",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_strength",
		tcoords = standardtcoords,
		funcstr = [[UnitStat1 c.Operator c.Level]],
		events = {"UNIT_STATS"},
	},
	{ -- agility
		text = _G["SPELL_STAT2_NAME"],
		value = "AGILITY",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_blessingofagility",
		tcoords = standardtcoords,
		funcstr = [[UnitStat2 c.Operator c.Level]],
		events = {"UNIT_STATS"},
	},
	{ -- stamina
		text = _G["SPELL_STAT3_NAME"],
		value = "STAMINA",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_wordfortitude",
		tcoords = standardtcoords,
		funcstr = [[UnitStat3 c.Operator c.Level]],
		events = {"UNIT_STATS"},
	},
	{ -- intellect
		text = _G["SPELL_STAT4_NAME"],
		value = "INTELLECT",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_magicalsentry",
		tcoords = standardtcoords,
		funcstr = [[UnitStat4 c.Operator c.Level]],
		events = {"UNIT_STATS"},
	},
	{ -- spirit
		text = _G["SPELL_STAT5_NAME"],
		value = "SPIRIT",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_shadow_burningspirit",
		tcoords = standardtcoords,
		funcstr = [[UnitStat5 c.Operator c.Level]],
		events = {"UNIT_STATS"},
	},
	{ -- mastery
		text = STAT_MASTERY,
		value = "MASTERY",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_championsbond",
		tcoords = standardtcoords,
		funcstr = [[Mastery c.Operator c.Level]],
		events = {"MASTERY_UPDATE"},
	},

	{ -- melee AP
		text = MELEE_ATTACK_POWER,
		value = "MELEEAP",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 50000,
		unit = PLAYER,
		icon = "Interface\\Icons\\INV_Sword_04",
		tcoords = standardtcoords,
		funcstr = [[MeleeAttackPower c.Operator c.Level]],
		events = {"UNIT_ATTACK_POWER"},
		spacebefore = true,
	},
	{ -- melee crit
		text = L["MELEECRIT"],
		value = "MELEECRIT",
		category = L["PLAYERSTATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_CriticalStrike",
		tcoords = standardtcoords,
		funcstr = [[MeleeCrit c.Operator c.Level]],
		events = {"COMBAT_RATING_UPDATE"},
	},
	{ -- melee haste
		text = L["MELEEHASTE"],
		value = "MELEEHASTE",
		category = L["PLAYERSTATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_bloodlust",
		tcoords = standardtcoords,
		funcstr = [[MeleeHaste c.Operator c.Level]],
		events = {"UNIT_ATTACK_SPEED"},
	},
	{ -- expertise
		text = _G["COMBAT_RATING_NAME"..CR_EXPERTISE],
		value = "EXPERTISE",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_rogue_shadowstrikes",
		tcoords = standardtcoords,
		funcstr = [[Expertise c.Operator c.Level]],
		events = {"COMBAT_RATING_UPDATE"},
	},

	{ -- ranged AP
		text = RANGED_ATTACK_POWER,
		value = "RANGEAP",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 50000,
		unit = PLAYER,
		icon = "Interface\\Icons\\INV_Weapon_Bow_07",
		tcoords = standardtcoords,
		funcstr = [[RangeAttackPower c.Operator c.Level]],
		events = {"UNIT_RANGED_ATTACK_POWER"},
		spacebefore = true,
	},
	{ -- range crit
		text = L["RANGEDCRIT"],
		value = "RANGEDCRIT",
		category = L["PLAYERSTATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_CriticalStrike",
		tcoords = standardtcoords,
		funcstr = [[RangeCrit c.Operator c.Level]],
		events = {"COMBAT_RATING_UPDATE"},
	},
	{ -- range haste
		text = L["RANGEDHASTE"],
		value = "RANGEDHASTE",
		category = L["PLAYERSTATS"],
		percent = true,
		texttable = pluspercent,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_bloodlust",
		tcoords = standardtcoords,
		funcstr = [[RangeHaste c.Operator c.Level]],
		events = {"UNIT_RANGEDDAMAGE"},
	},


	{ -- spell damage
		text = STAT_SPELLDAMAGE,
		value = "SPELLDMG",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_fire_flamebolt",
		tcoords = standardtcoords,
		funcstr = [[SpellDamage c.Operator c.Level]],
		events = {"PLAYER_DAMAGE_DONE_MODS"},
		spacebefore = true,
	},
	{ -- spell healing
		text = STAT_SPELLHEALING,
		value = "SPELLHEALING",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 20000,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_nature_healingtouch",
		tcoords = standardtcoords,
		funcstr = [[SpellHealing c.Operator c.Level]],
		events = {"PLAYER_DAMAGE_DONE_MODS"},
	},
	{ -- spell crit
		text = L["SPELLCRIT"],
		value = "SPELLCRIT",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 100,
		percent = true,
		texttable = pluspercent,
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_gizmo_supersappercharge",
		tcoords = standardtcoords,
		funcstr = [[SpellCrit c.Operator c.Level]],
		events = {"COMBAT_RATING_UPDATE"},
	},
	{ -- spell haste
		text = L["SPELLHASTE"],
		value = "SPELLHASTE",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 100,
		percent = true,
		texttable = pluspercent,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_mage_timewarp",
		tcoords = standardtcoords,
		funcstr = [[SpellHaste c.Operator c.Level]],
		events = {"COMBAT_RATING_UPDATE"},
	},
	{ -- mana regen
		text = MANA_REGEN,
		value = "MANAREGEN",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 15000/5,
		unit = PLAYER,
		texttable = setmetatable({}, {__index = function(t, k) return format(L["MP5"], k*5) end}),
		icon = "Interface\\Icons\\spell_magic_managain",
		tcoords = standardtcoords,
		funcstr = [[GetManaRegen() c.Operator c.Level]], -- anyone know of an event that can be reliably listened to to get this?
	},
	{ -- mana in combat
		text = MANA_REGEN_COMBAT,
		value = "MANAREGENCOMBAT",
		category = L["PLAYERSTATS"],
		min = 0,
		max = 15000/5,
		unit = PLAYER,
		texttable = setmetatable({}, {__index = function(t, k) return format(L["MP5"], k*5) end}),
		icon = "Interface\\Icons\\spell_frost_summonwaterelemental",
		tcoords = standardtcoords,
		funcstr = [[select(2,GetManaRegen()) c.Operator c.Level]],
	},
--///////////////////////////////////stats

-------------------------------------icon functions

	{ -- icon shown
		text = L["CONDITIONPANEL_ICON"],
		tooltip = L["CONDITIONPANEL_ICON_DESC"],
		value = "ICON",
		category = L["ICONFUNCTIONS"],
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
				str = str .. [[and c.Icon.FakeAlpha > 0]]
			else
				str = str .. [[and c.Icon.FakeAlpha == 0]]
			end
			return gsub(str, "c.Icon", c.Icon)
		end,
	},
	{ -- spell cooldown
		text = L["ICONMENU_COOLDOWN"] .. " - " .. L["ICONMENU_SPELL"],
		value = "SPELLCD",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_COOLDOWN"] .. " - " .. L["ICONMENU_SPELL"], "CNDT_ONLYFIRST", 1, nil, 1) end,
		nooperator = true,
		unit = false,
		texttable = usableunusable,
		icon = "Interface\\Icons\\spell_holy_divineintervention",
		tcoords = standardtcoords,
		funcstr = [[c.False == IsSpellOnCooldown(c.NameFirst)]],
		spacebefore = true,
	},
	{ -- item cooldown
		text = L["ICONMENU_COOLDOWN"] .. " - " .. L["ICONMENU_ITEM"],
		value = "ITEMCD",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_COOLDOWN"] .. " - " .. L["ICONMENU_ITEM"], "CNDT_ONLYFIRST", 1, nil, 1) end,
		nooperator = true,
		unit = false,
		texttable = usableunusable,
		icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
		tcoords = standardtcoords,
		funcstr = [[c.False == IsItemOnCooldown(c.ItemID)]],
	},
	{ -- unit buff duration
		text = L["ICONMENU_BUFF"] .. " - " .. L["DURATIONPANEL_TITLE"],
		value = "BUFFDUR",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 600,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["DURATIONPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) end,
		texttable = setmetatable({[0] = "0 ("..L["ICONMENU_ABSENT"].."/"..L["INFINITE"]..")"}, {__index = function(tbl, k) return format(D_SECONDS, k) end}),
		icon = "Interface\\Icons\\spell_nature_rejuvenation",
		tcoords = standardtcoords,
		funcstr = [[AuraDur(c.Unit, c.NameName, "HELPFUL") c.Operator c.Level]],
	},
	{ -- unit buff stacks
		text = L["ICONMENU_BUFF"] .. " - " .. L["STACKSPANEL_TITLE"],
		value = "BUFFSTACKS",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_BUFF"] .. " - " .. L["STACKSPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) end,
		texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
		icon = "Interface\\Icons\\inv_misc_herb_felblossom",
		tcoords = standardtcoords,
		funcstr = [[AuraStacks(c.Unit, c.NameName, "HELPFUL") c.Operator c.Level]],
	},
	{ -- unit debuff duration
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATIONPANEL_TITLE"],
		value = "DEBUFFDUR",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 600,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["DURATIONPANEL_TITLE"], "BUFFCNDT_DESC", 1, nil, 1) end,
		texttable = setmetatable({[0] = "0 ("..L["ICONMENU_ABSENT"].."/"..L["INFINITE"]..")"}, {__index = function(tbl, k) return format(D_SECONDS, k) end}),
		icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
		tcoords = standardtcoords,
		funcstr = [[AuraDur(c.Unit, c.NameName, "HARMFUL") c.Operator c.Level]],
	},
	{ -- unit debuff stacks
		text = L["ICONMENU_DEBUFF"] .. " - " .. L["STACKSPANEL_TITLE"],
		value = "DEBUFFSTACKS",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 20,
		name = function(editbox) TMW:TT(editbox, L["ICONMENU_DEBUFF"] .. " - " .. L["STACKSPANEL_TITLE"], "BUFFCNDT_DESC", nil, nil, 1) end,
		texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
		icon = "Interface\\Icons\\ability_warrior_sunder",
		tcoords = standardtcoords,
		funcstr = [[AuraStacks(c.Unit, c.NameName, "HARMFUL") c.Operator c.Level]],
	},
	{ -- reactive
		text = L["ICONMENU_REACTIVE"],
		tooltip = L["REACTIVECNDT_DESC"],
		value = "REACTIVE",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "ICONMENU_REACTIVE", "CNDT_ONLYFIRST", nil, nil, 1) end,
		nooperator = true,
		unit = false,
		texttable = usableunusable,
		icon = "Interface\\Icons\\ability_warrior_revenge",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsUsableSpell(c.NameFirst)]],
	},
	{ -- mainhand
		text = INVTYPE_WEAPONMAINHAND .. " - " .. L["ICONMENU_WPNENCHANT"],
		value = "MAINHAND",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		nooperator = true,
		unit = false,
		texttable = presentabsent,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_14" end,
		tcoords = standardtcoords,
		funcstr = [[c.1nil == GetWeaponEnchantInfo()]],
	},
	{ -- offhand
		text = INVTYPE_WEAPONOFFHAND .. " - " .. L["ICONMENU_WPNENCHANT"],
		value = "OFFHAND",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		nooperator = true,
		unit = false,
		texttable = presentabsent,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_15" end,
		tcoords = standardtcoords,
		funcstr = [[c.1nil == select(4, GetWeaponEnchantInfo())]],
	},
	{ -- thrown
		text = INVTYPE_THROWN .. " - " .. L["ICONMENU_WPNENCHANT"],
		value = "THROWN",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		nooperator = true,
		unit = false,
		texttable = presentabsent,
		icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("RangedSlot")) or "Interface\\Icons\\inv_throwingknife_06" end,
		tcoords = standardtcoords,
		funcstr = [[c.1nil == select(7, GetWeaponEnchantInfo())]],
		shouldshow = pclass == "ROGUE",
	},
	{ -- casting
		text = L["ICONMENU_CAST"],
		value = "CASTING",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 2,
		nooperator = true,
		texttable = {
			[0] = L["ICONMENU_ONLYINTERRUPTIBLE"],
			[1] = L["ICONMENU_PRESENT"],
			[2] = L["ICONMENU_ABSENT"],
		},
		midt = L["ICONMENU_PRESENT"],
		icon = "Interface\\Icons\\Temp",
		tcoords = standardtcoords,
		funcstr = [[UnitCast(c.Unit, c.Level)]],
	},

	{ -- item in bags
		text = L["ITEMINBAGS"],
		value = "ITEMINBAGS",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 50,
		texttable = setmetatable({}, {__index = function(tbl, k) return format(ITEM_SPELL_CHARGES, k) end}),
		name = function(editbox) TMW:TT(editbox, "ITEMINBAGS", "CNDT_ONLYFIRST", nil, nil, 1) end,
		unit = false,
		icon = "Interface\\Icons\\inv_misc_bag_08",
		tcoords = standardtcoords,
		funcstr = [[GetItemCount(c.ItemID, nil, 1) c.Operator c.Level]],
		spacebefore = true,
	},
	{ -- item equipped
		text = L["ITEMEQUIPPED"],
		value = "ITEMEQUIPPED",
		category = L["ICONFUNCTIONS"],
		min = 0,
		max = 1,
		nooperator = true,
		texttable = bool,
		name = function(editbox) TMW:TT(editbox, "ITEMEQUIPPED", "CNDT_ONLYFIRST", nil, nil, 1) end,
		unit = false,
		icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == IsEquippedItem(c.ItemID)]],
	},



--////////////////////////////////////icon functions

	{ -- exists
		text = L["CONDITIONPANEL_EXISTS"],
		value = "EXISTS",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\Icons\\ABILITY_SEAL",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == UnitExists(c.Unit)]],
		spacebefore = true,
	},
	{ -- alive
		text = L["CONDITIONPANEL_ALIVE"],
		tooltip = L["CONDITIONPANEL_ALIVE_DESC"],
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
		value = "COMBAT",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		icon = "Interface\\CharacterFrame\\UI-StateIcon",
		tcoords = {0.53, 0.92, 0.05, 0.42},
		funcstr = [[c.1nil == UnitAffectingCombat(c.Unit)]],
	},
	{ -- pvp
		text = L["CONDITIONPANEL_PVPFLAG"],
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
		value = "SPEED",
		min = 0,
		max = 500,
		percent = true,
		texttable = percent,
		icon = "Interface\\Icons\\ability_rogue_sprint",
		tcoords = standardtcoords,
		funcstr = [[floor(GetUnitSpeed(c.Unit)*]].. BASE_MOVEMENT_SPEED ..[[) c.Operator c.Level]],
	},
	{ -- runspeed
		text = L["RUNSPEED"],
		value = "RUNSPEED",
		min = 0,
		max = 500,
		percent = true,
		texttable = percent,
		icon = "Interface\\Icons\\ability_rogue_sprint",
		tcoords = standardtcoords,
		funcstr = [[floor(select(2, GetUnitSpeed(c.Unit))*]].. BASE_MOVEMENT_SPEED ..[[) c.Operator c.Level]],
	},
	{ -- name
		text = L["CONDITIONPANEL_NAME"],
		value = "NAME",
		min = 0,
		max = 1,
		name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_NAME", "CONDITIONPANEL_NAMETOOLTIP", nil, nil, 1) end,
		nooperator = true,
		texttable = bool,
		icon = "Interface\\LFGFrame\\LFGFrame-SearchIcon-Background",
		tcoords = standardtcoords,
		funcstr = [[c.1nil == (strfind(c.Name, ";" .. strlower(UnitName(c.Unit) or "") .. ";") and 1)]],
	},
	{ -- level
		text = L["CONDITIONPANEL_LEVEL"],
		value = "LEVEL",
		min = -1,
		max = 90,
		texttable = setmetatable({[-1] = BOSS}, {__index = function(t, k) return k end}),
		icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
		tcoords = {0.05, 0.95, 0.03, 0.97},
		funcstr = [[UnitLevel(c.Unit) c.Operator c.Level]],
	},

	{ -- instance type
		text = L["CONDITIONPANEL_INSTANCETYPE"],
		value = "INSTANCE",
		min = 0,
		max = 8,
		unit = false,
		texttable = TMW.ZoneTypes,
		icon = "Interface\\Icons\\Spell_Frost_Stun",
		tcoords = standardtcoords,
		funcstr = [[ZoneType c.Operator c.Level]],
		events = {"ZONE_CHANGED_NEW_AREA"},
		spacebefore = true,
	},
	{ -- grouptype
		text = L["CONDITIONPANEL_GROUPTYPE"],
		value = "GROUP",
		min = 0,
		max = 2,
		unit = false,
		texttable = {[0] = SOLO, [1] = PARTY, [2] = RAID},
		icon = "Interface\\Calendar\\MeetingIcon",
		tcoords = standardtcoords,
		funcstr = [[((NumRaidMembers > 0 and 2) or (NumPartyMembers > 0 and 1) or 0) c.Operator c.Level]], -- this one was harder than it should have been to figure out; keep it in mind for future condition creating
		events = {"PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE"},
	},
	{ -- mounted
		text = L["CONDITIONPANEL_MOUNTED"],
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
		value = "RESTING",
		min = 0,
		max = 1,
		texttable = bool,
		nooperator = true,
		unit = PLAYER,
		icon = "Interface\\CHARACTERFRAME\\UI-StateIcon",
		tcoords = {0.0625, 0.453125, 0.046875, 0.421875},
		funcstr = [[c.1nil == Resting]],
		events = {"PLAYER_UPDATE_RESTING"},
	},
	{ -- stance
		text = 	pclass == "HUNTER" and L["ASPECT"] or
				pclass == "PALADIN" and L["AURA"] or
				pclass == "WARRIOR" and L["STANCE"] or
				pclass == "DEATHKNIGHT" and L["PRESENCE"] or
				pclass == "DRUID" and L["SHAPESHIFT"] or
			--	firststanceid and GetSpellInfo(firststanceid) or
				L["STANCE"],
		value = "STANCE",
		min = 0,
		max = #TMW.CSN,
		texttable = TMW.CSN, -- now isn't this convenient? too bad i have to track them by ID so they wont upgrade properly when stances are added/removed
		unit = PLAYER,
		nooperator = true,
		icon = function() return firststanceid and GetSpellTexture(firststanceid) end,
		tcoords = standardtcoords,
		funcstr = function(c)
			return (TMW.CSN[c.Level] and "\""..TMW.CSN[c.Level].."\"" or "nil") .. [[ == ShapeshiftForm]]
		end,
		events = {"UPDATE_SHAPESHIFT_FORM"},
		shouldshow = #TMW.CSN > 0,
	},
	{ -- talent spec
		text = L["UIPANEL_SPEC"],
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
		value = "TREE",
		min = 1,
		max = 3,
		texttable = setmetatable({}, {__index=function(t, i) return select(2, GetTalentTabInfo(i)) end}),
		unit = PLAYER,
		icon = function() return select(4, GetTalentTabInfo(1)) end,
		tcoords = standardtcoords,
		funcstr = [[CurrentTree c.Operator c.Level]],
	},
}

CNDT.ConditionsByType = {}
for k, v in pairs(CNDT.Types) do
	CNDT.ConditionsByType[v.value] = v
end local ConditionsByType = CNDT.ConditionsByType

local functionCache = {} CNDT.functionCache = functionCache
function CNDT:ProcessConditions(icon)
	if TMW.debug and test then test() end
	local Conditions = icon.Conditions
	local funcstr = ""
	for i = 1, #Conditions do
		local c = Conditions[i]
		local t = c.Type
		local v = ConditionsByType[t]
		if v and v.events then
			for k, event in pairs(v.events) do
				CNDT:RegisterEvent(event)
				CNDT[event](CNDT, "player")
			end
		end

		local name = gsub(c.Name, "; ", ";")
		name = gsub(name, " ;", ";")
		name = ";" .. name .. ";"
		name = gsub(name, ";;", ";")
		name = strtrim(name)
		name = strlower(name)
		local andor
		if c.AndOr == "OR" then
			andor = "or " --have a space so they are both 3 chars long
		else
			andor = "and"
		end

		local thiscondtstr = v.funcstr
		if type(thiscondtstr) == "function" then
			thiscondtstr = thiscondtstr(c)
		end

		if thiscondtstr then
			local thisstr = andor .. "(" .. thiscondtstr .. ")"

			if strfind(thisstr, "c.Unit") and (strfind(c.Unit, "maintank") or strfind(c.Unit, "mainassist")) then
				local unit = gsub(c.Unit, "|cFFFF0000#|r", "1")
				thisstr = gsub(thisstr, "c.Unit",	unit) -- sub it in as a variable
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
			gsub("c.Operator", 		c.Operator):
			gsub("c.NameFirst", 	"\"" .. TMW:GetSpellNames(nil, name, 1) .. "\""):
			gsub("c.NameName", 		"\"" .. TMW:GetSpellNames(nil, name, 1, 1) .. "\""):
			gsub("c.ItemID", 		TMW:GetItemIDs(icon, name, 1)):
			gsub("c.Name", 			"\"" .. name .. "\""):

			gsub("c.True", 			tostring(c.Level == 0)):
			gsub("c.False", 		tostring(c.Level == 1))
			funcstr = funcstr .. thisstr
		end
	end
	funcstr = [[if not (]] .. strsub(funcstr, 4) .. [[) then
		]] .. (icon.ConditionAlpha == 0 and (icon:GetName()..[[:SetAlpha(0) return true]]) or (icon:GetName()..[[.CndtFailed = 1]])) .. [[
	else
		]]..icon:GetName()..[[.CndtFailed = nil
	end]]

	local func, err = functionCache[funcstr] or loadstring(funcstr, icon:GetName() .. " Condition")

	if func then
		func = setfenv(func, Env)
		icon.CndtCheck = func
		functionCache[funcstr] = func
		return funcs
	elseif TMW.debug and err then
		print(funcstr)
		error(err)
	end
end



