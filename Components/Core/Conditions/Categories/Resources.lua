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

local CNDT = TMW.CNDT
local Env = CNDT.Env

local _, pclass = UnitClass("Player")

Env.UnitHealth = UnitHealth
Env.UnitHealthMax = UnitHealthMax
Env.UnitPower = UnitPower
Env.UnitPowerMax = UnitPowerMax


local ConditionCategory = CNDT:GetCategory("RESOURCES", 1, L["CNDTCAT_RESOURCES"], false, false)

ConditionCategory:RegisterCondition(1,	 "HEALTH", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. HEALTH,
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_alchemy_elixir_05",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealth(c.Unit)/(UnitHealthMax(c.Unit)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(2,	 "DEFAULT", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. L["CONDITIONPANEL_POWER"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_alchemy_elixir_02",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit)/(UnitPowerMax(c.Unit)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_DISPLAYPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(3,	 "MANA", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. MANA,
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_126",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 0)/(UnitPowerMax(c.Unit, 0)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(4,	 "ENERGY", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. ENERGY,
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 3)/(UnitPowerMax(c.Unit, 3)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(5,	 "RAGE", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. RAGE,
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_120",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 1)/(UnitPowerMax(c.Unit, 1)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(6,	 "FOCUS", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. FOCUS,
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 2)/(UnitPowerMax(c.Unit, 2)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(7,	 "RUNIC_POWER", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. RUNIC_POWER,
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 6)/(UnitPowerMax(c.Unit, 6)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(8,	 "ALTPOWER", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
	tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
	percent = true,
	texttable = CNDT.COMMON.percent,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\spell_shadow_mindflay",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 10)/(UnitPowerMax(c.Unit, 10)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(10)

ConditionCategory:RegisterCondition(11,	 "SOUL_SHARDS", {
	text = SOUL_SHARDS,
	min = 0,
	max = 4,
	unit = PLAYER,
	icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 7) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER", CNDT:GetUnit(c.Unit))
	end,
	hidden = pclass ~= "WARLOCK",
})

ConditionCategory:RegisterCondition(12,	 "HOLY_POWER", {
	text = HOLY_POWER,
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Holy_Rune",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 9) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER", CNDT:GetUnit(c.Unit))
	end,
	hidden = pclass ~= "PALADIN",
})

ConditionCategory:RegisterCondition(13.1, "ECLIPSE", {
	text = ECLIPSE,
	tooltip = L["CONDITIONPANEL_ECLIPSE_DESC"],
	min = -100,
	max = 100,
	mint = "-100 (" .. L["MOON"] .. ")",
	maxt = "100 (" .. L["SUN"] .. ")",
	unit = PLAYER,
	icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
	tcoords = {0.65625000, 0.74609375, 0.37500000, 0.55468750},
	funcstr = [[UnitPower(c.Unit, 8) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER", CNDT:GetUnit(c.Unit))
	end,
	hidden = pclass ~= "DRUID",
})
ConditionCategory:RegisterCondition(13.2, "ECLIPSE_DIRECTION", {
	text = L["ECLIPSE_DIRECTION"],
	min = 0,
	max = 1,
	texttable = {[0] = L["MOON"], [1] = L["SUN"]},
	unit = PLAYER,
	nooperator = true,
	icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
	tcoords = {0.55859375, 0.64843750, 0.57031250, 0.75000000},
	Env = {
		GetEclipseDirection = GetEclipseDirection,
	},
	funcstr = [[c.Level == (GetEclipseDirection() == "sun" and 1 or 0)]],
	hidden = pclass ~= "DRUID",
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("ECLIPSE_DIRECTION_CHANGE")
	end,
})

ConditionCategory:RegisterCondition(14,	 "HAPPINESS", {
	text = HAPPINESS,
	min = 1,
	max = 3,
	midt = true,
	texttable = function(k) return _G["PET_HAPPINESS" .. k] end,
	unit = PET,
	icon = "Interface\\PetPaperDollFrame\\UI-PetHappiness",
	tcoords = {0.390625, 0.5491, 0.03, 0.3305},
	Env = {
		GetPetHappiness = GetPetHappiness,
	},
	funcstr = GetPetHappiness and [[(GetPetHappiness() or 0) c.Operator c.Level]] or [[true]], -- dummy string to keep support for wowCN
	hidden = not GetPetHappiness or pclass ~= "HUNTER", -- dont show if GetPetHappiness doesnt exist (if happiness is removed in the client version), not not because it must be false, not nil
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit("pet")),
			ConditionObject:GenerateNormalEventString("UNIT_HAPPINESS", "pet"),
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "pet")
	end,
})

ConditionCategory:RegisterCondition(15,	 "RUNES", {
	text = RUNES,
	tooltip = L["CONDITIONPANEL_RUNES_DESC"],
	unit = false,
	nooperator = true,
	noslide = true,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
	Env = {
		GetRuneType = GetRuneType,
		GetRuneCount = GetRuneCount,
	},
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
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("RUNE_POWER_UPDATE"),
			ConditionObject:GenerateNormalEventString("RUNE_TYPE_UPDATE")
	end,
	hidden = pclass ~= "DEATHKNIGHT",
})
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData and conditionData.value == "RUNES" then
		CndtGroup.Runes:Show()
	else
		CndtGroup.Runes:Hide()
	end
end)

ConditionCategory:RegisterCondition(15.5, "CHI", {
	text = CHI_POWER,
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_monk_chiwave",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 12) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player")
	end,
	hidden = pclass ~= "MONK",
})

ConditionCategory:RegisterCondition(16,	 "COMBO", {
	text = L["CONDITIONPANEL_COMBO"],
	defaultUnit = "target",
	min = 0,
	max = 5,
	icon = "Interface\\Icons\\ability_rogue_eviscerate",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetComboPoints = GetComboPoints,
	},
	funcstr = [[GetComboPoints("player", c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_COMBO_POINTS", "player")
	end,
})

ConditionCategory:RegisterCondition(17,	 "SHADOW_ORBS", {
	text = SHADOW_ORBS,
	min = 0,
	max = 3,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Priest_Shadoworbs",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 13) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player")
	end,
	hidden = pclass ~= "PRIEST" or not TMW.ISMOP,
})

ConditionCategory:RegisterCondition(19.1, "BURNING_EMBERS", {
	text = BURNING_EMBERS,
	min = 0,
	max = 4,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_warlock_burningembers",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 14, false) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player")
	end,
	hidden = pclass ~= "WARLOCK" or not TMW.ISMOP,
})
ConditionCategory:RegisterCondition(19.2, "BURNING_EMBERS_FRAGMENTS", {
	text = L["BURNING_EMBERS_FRAGMENTS"],
	tooltip = L["BURNING_EMBERS_FRAGMENTS_DESC"],
	min = 0,
	max = 40,
	unit = PLAYER,
	icon = "Interface\\Icons\\INV_Elemental_Mote_Fire01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 14, true) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player")
	end,
	hidden = pclass ~= "WARLOCK" or not TMW.ISMOP,
})
ConditionCategory:RegisterCondition(19.3, "DEMONIC_FURY", {
	text = DEMONIC_FURY,
	min = 0,
	max = 1000,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_Warlock_Eradication",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 15) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player")
	end,
	hidden = pclass ~= "WARLOCK" or not TMW.ISMOP,
})

ConditionCategory:RegisterSpacer(40)

ConditionCategory:RegisterCondition(41,	 "HEALTH_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. HEALTH,
	texttable = CNDT.COMMON.commanumber,
	range = 1000000,
	step = 1,
	icon = "Interface\\Icons\\inv_alchemy_elixir_05",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealth(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(42,	 "DEFAULT_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. L["CONDITIONPANEL_POWER"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	texttable = CNDT.COMMON.commanumber,
	range = 40000,
	step = 1,
	icon = "Interface\\Icons\\inv_alchemy_elixir_02",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_DISPLAYPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(43,	 "MANA_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. MANA,
	texttable = CNDT.COMMON.commanumber,
	range = 40000,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_126",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(44,	 "ENERGY_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. ENERGY,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 3) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(45,	 "RAGE_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. RAGE,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_120",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(46,	 "FOCUS_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. FOCUS,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 2) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(47,	 "RUNIC_POWER_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. RUNIC_POWER,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 6) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(48,	 "ALTPOWER_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
	tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\spell_shadow_mindflay",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 10) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(60)

ConditionCategory:RegisterCondition(61,	 "HEALTH_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. HEALTH,
	texttable = CNDT.COMMON.commanumber,
	range = 1000000,
	step = 100,
	icon = "Interface\\Icons\\inv_alchemy_elixir_05",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealthMax(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(62,	 "DEFAULT_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. L["CONDITIONPANEL_POWER"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	texttable = CNDT.COMMON.commanumber,
	range = 40000,
	step = 100,
	icon = "Interface\\Icons\\inv_alchemy_elixir_02",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_DISPLAYPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(63,	 "MANA_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. MANA,
	texttable = CNDT.COMMON.commanumber,
	range = 40000,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_126",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(64,	 "ENERGY_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. ENERGY,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 3) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(65,	 "RAGE_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. RAGE,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_120",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(66,	 "FOCUS_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. FOCUS,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 2) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(67,	 "RUNIC_POWER_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. RUNIC_POWER,
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 6) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(68,	 "ALTPOWER_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
	tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
	texttable = CNDT.COMMON.commanumber,
	range = 200,
	step = 1,
	icon = "Interface\\Icons\\spell_shadow_mindflay",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 10) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", CNDT:GetUnit(c.Unit))
	end,
})

