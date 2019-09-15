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

local CNDT = TMW.CNDT
local Env = CNDT.Env

local _, pclass = UnitClass("Player")

Env.UnitHealth = TMW.UnitHealth
Env.UnitHealthMax = TMW.UnitHealthMax
Env.UnitPower = UnitPower
Env.UnitPowerMax = UnitPowerMax


TMW:RegisterUpgrade(62032, {
	condition = function(self, condition)
		if condition.Type == "RUNES" then
			condition.Checked = false
		end
	end,
})


local ConditionCategory = CNDT:GetCategory("RESOURCES", 1, L["CNDTCAT_RESOURCES"], false, false)


ConditionCategory:RegisterCondition(1.0, "HEALTH", {
	text = HEALTH .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_54",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealth(c.Unit)/(UnitHealthMax(c.Unit)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(1.1, "HEALTH_ABS", {
	text = HEALTH .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 1000000,
	icon = "Interface\\Icons\\inv_potion_54",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealth(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(1.2, "HEALTH_MAX", {
	text = HEALTH .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 1000000,
	icon = "Interface\\Icons\\inv_potion_54",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealthMax(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(1.9)



local offset = TMW.tContains({"ROGUE", "DRUID"}, pclass) and 0 or 62
ConditionCategory:RegisterCondition(27 + offset, "COMBO", {
	text = L["CONDITIONPANEL_COMBO"],
	min = 0,
	max = 10,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_rogue_eviscerate",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetComboPoints = GetComboPoints,
	},
	funcstr = [[GetComboPoints("player", "target") c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "COMBO_POINTS")
	end,
})

ConditionCategory:RegisterSpacer(30)

-- The main resource type for the current player's class will land around 50.

ConditionCategory:RegisterSpacer(70)

-- Resources with Percent, Abs, and Max conditions.

local S = 50
ConditionCategory:RegisterCondition(102.0, "DEFAULT", {
	text = L["CONDITIONPANEL_POWER"] .. " - " .. L["CONDITIONPANEL_PERCENT"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_69",
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
ConditionCategory:RegisterCondition(102.1, "DEFAULT_ABS", {
	text = L["CONDITIONPANEL_POWER"] .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
	icon = "Interface\\Icons\\inv_potion_69",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_DISPLAYPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(102.2, "DEFAULT_MAX", {
	text = L["CONDITIONPANEL_POWER"] .. " - " .. L["CONDITIONPANEL_MAX"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
	icon = "Interface\\Icons\\inv_potion_69",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_DISPLAYPOWER", CNDT:GetUnit(c.Unit))
	end,
})

offset = TMW.tContains({"PALADIN", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "HUNTER"}, pclass) and S or 0
ConditionCategory:RegisterCondition(103.0 - offset, "MANA", {
	text = MANA .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_76",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d)/(UnitPowerMax(c.Unit, %d)+epsilon) c.Operator c.Level]]):format(Enum.PowerType.Mana, Enum.PowerType.Mana),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "MANA"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "MANA")
	end,
})
ConditionCategory:RegisterCondition(103.1 - offset, "MANA_ABS", {
	text = MANA .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
	icon = "Interface\\Icons\\inv_potion_76",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Mana),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "MANA")
	end,
})
ConditionCategory:RegisterCondition(103.2 - offset, "MANA_MAX", {
	text = MANA .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
	icon = "Interface\\Icons\\inv_potion_76",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Mana),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})

offset = TMW.tContains({"ROGUE", "DRUID"}, pclass) and S or 0
ConditionCategory:RegisterCondition(104.0 - offset, "ENERGY", {
	text = ENERGY .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_31",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d)/(UnitPowerMax(c.Unit, %d)+epsilon) c.Operator c.Level]]):format(Enum.PowerType.Energy, Enum.PowerType.Energy),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "ENERGY"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "ENERGY")
	end,
})
ConditionCategory:RegisterCondition(104.1 - offset, "ENERGY_ABS", {
	text = ENERGY .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_31",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Energy),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "ENERGY")
	end,
})
ConditionCategory:RegisterCondition(104.2 - offset, "ENERGY_MAX", {
	text = ENERGY .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_31",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Energy),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "ENERGY")
	end,
})

offset = TMW.tContains({"WARRIOR", "DRUID"}, pclass) and S or 0
ConditionCategory:RegisterCondition(105.0 - offset, "RAGE", {
	text = RAGE .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_24",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d)/(UnitPowerMax(c.Unit, %d)+epsilon) c.Operator c.Level]]):format(Enum.PowerType.Rage, Enum.PowerType.Rage),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "RAGE"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "RAGE")
	end,
})
ConditionCategory:RegisterCondition(105.1 - offset, "RAGE_ABS", {
	text = RAGE .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_24",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Rage),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "RAGE")
	end,
})
ConditionCategory:RegisterCondition(105.2 - offset, "RAGE_MAX", {
	text = RAGE .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_24",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Rage),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "RAGE")
	end,
})

offset = pclass == "HUNTER" and S or 0
ConditionCategory:RegisterCondition(106.0 - offset, "FOCUS", {
	text = FOCUS .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_39",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d)/(UnitPowerMax(c.Unit, %d)+epsilon) c.Operator c.Level]]):format(Enum.PowerType.Focus, Enum.PowerType.Focus),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "FOCUS"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "FOCUS")
	end,
})
ConditionCategory:RegisterCondition(106.1 - offset, "FOCUS_ABS", {
	text = FOCUS .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_39",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Focus),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "FOCUS")
	end,
})
ConditionCategory:RegisterCondition(106.2 - offset, "FOCUS_MAX", {
	text = FOCUS .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_39",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Focus),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "FOCUS")
	end,
})


ConditionCategory:RegisterSpacer(200)
