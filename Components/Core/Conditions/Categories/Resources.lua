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

local GetRuneCooldown = GetRuneCooldown


TMW:RegisterUpgrade(62032, {
	condition = function(self, condition)
		if condition.Type == "RUNES" then
			condition.Checked = false
		end
	end,
})


local ConditionCategory = CNDT:GetCategory("RESOURCES", 1, L["CNDTCAT_RESOURCES"], false, false)


ConditionCategory:RegisterCondition(1.0, "HEALTH", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. HEALTH,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
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
ConditionCategory:RegisterCondition(1.1, "HEALTH_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. HEALTH,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 1000000,
	icon = "Interface\\Icons\\inv_alchemy_elixir_05",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealth(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEALTH_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(1.2, "HEALTH_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. HEALTH,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 1000000,
	icon = "Interface\\Icons\\inv_alchemy_elixir_05",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealthMax(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(1.9)

ConditionCategory:RegisterCondition(2.0, "DEFAULT", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. L["CONDITIONPANEL_POWER"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
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
ConditionCategory:RegisterCondition(2.1, "DEFAULT_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. L["CONDITIONPANEL_POWER"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
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
ConditionCategory:RegisterCondition(2.2, "DEFAULT_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. L["CONDITIONPANEL_POWER"],
	tooltip = L["CONDITIONPANEL_POWER_DESC"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
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



ConditionCategory:RegisterSpacer(3)



-- Private Class Resources (other players can't see them)
ConditionCategory:RegisterCondition(23, "SOUL_SHARDS", {
	text = SOUL_SHARDS,
	min = 0,
	max = 4,
	unit = PLAYER,
	icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(SPELL_POWER_SOUL_SHARDS),
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "SOUL_SHARDS")
	end,
	hidden = pclass ~= "WARLOCK",
})
ConditionCategory:RegisterCondition(24, "HOLY_POWER", {
	text = HOLY_POWER,
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Holy_Rune",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(SPELL_POWER_HOLY_POWER),
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "HOLY_POWER")
	end,
	hidden = pclass ~= "PALADIN",
})
ConditionCategory:RegisterCondition(25, "RUNES2", {
	text = L["CONDITIONPANEL_RUNES"],
	tooltip = L["CONDITIONPANEL_RUNES_DESC3"],
	unit = false,
	min = 0,
	max = 6,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
	Env = {
		GetRuneType = GetRuneType,
		GetRuneCount = GetRuneCount,
	},
	funcstr = function(c)
		local str = ""
		for i = 1, 6 do
			str = str .. [[ + (GetRuneCount(]]..i..[[) or 0)]]
		end
		return str:trim("+ ") .. " c.Operator c.Level" 
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("RUNE_POWER_UPDATE")
	end,
	hidden = pclass ~= "DEATHKNIGHT",
})
ConditionCategory:RegisterCondition(26, "CHI", {
	text = CHI_POWER,
	min = 0,
	max = 6,
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
local offset = TMW.tContains({"ROGUE", "DRUID"}, pclass) and 0 or 62
ConditionCategory:RegisterCondition(27 + offset, "COMBO", {
	text = L["CONDITIONPANEL_COMBO"],
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_rogue_eviscerate",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitPower = UnitPower,
	},
	funcstr = [[UnitPower("player", 4) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "COMBO_POINTS")
	end,
})
ConditionCategory:RegisterCondition(28, "ARCANE_CHARGES", {
	text = ARCANE_CHARGES_POWER,
	min = 0,
	max = 4,
	icon = "Interface\\Icons\\spell_arcane_arcanetorrent",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(SPELL_POWER_ARCANE_CHARGES),
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "ARCANE_CHARGES")
	end,
	hidden = pclass ~= "MAGE",
})

ConditionCategory:RegisterSpacer(30)
ConditionCategory:RegisterSpacer(70)


-- Public Class Resources that don't need percent/abs/max conditions
local S = 80
local offset = pclass == "PRIEST" and S or 0
ConditionCategory:RegisterCondition(90.0 - offset, "INSANITY", {
	text = INSANITY_POWER,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\spell_shadow_painandsuffering",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 13) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "INSANITY")
	end,
})

offset = pclass == "DEMONHUNTER" and S or 0
ConditionCategory:RegisterCondition(91.0 - offset, "FURY", {
	text = FURY,
	min = 0,
	max = 130,
	icon = "Interface\\Icons\\ability_warlock_demonicpower",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(SPELL_POWER_FURY),
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "FURY")
	end,
})
ConditionCategory:RegisterCondition(92.0 - offset, "PAIN", {
	text = PAIN,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\ability_demonhunter_torment",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(SPELL_POWER_PAIN),
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player", "PAIN")
	end,
})

offset = pclass == "SHAMAN" and S or 0
ConditionCategory:RegisterCondition(93 - offset, "MAELSTROM", {
	text = MAELSTROM_POWER,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\spell_shaman_maelstromweapon",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 11)/(UnitPowerMax(c.Unit, 11)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "MAELSTROM"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "MAELSTROM")
	end,
})

offset = pclass == "DRUID" and S or 0
ConditionCategory:RegisterCondition(94 - offset, "LUNAR_POWER", {
	text = LUNAR_POWER,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\talentspec_druid_balance",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 11)/(UnitPowerMax(c.Unit, 11)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "LUNAR_POWER"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "LUNAR_POWER")
	end,
})


ConditionCategory:RegisterSpacer(100)

-- Resources with Percent, Abs, and Max conditions.

S = 50
offset = TMW.tContains({"PALADIN", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "MONK"}, pclass) and S or 0
ConditionCategory:RegisterCondition(103.0 - offset, "MANA", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. MANA,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_126",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 0)/(UnitPowerMax(c.Unit, 0)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "MANA"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "MANA")
	end,
})
ConditionCategory:RegisterCondition(103.1 - offset, "MANA_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. MANA,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
	icon = "Interface\\Icons\\inv_potion_126",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(103.2 - offset, "MANA_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. MANA,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 40000,
	icon = "Interface\\Icons\\inv_potion_126",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})

offset = TMW.tContains({"ROGUE", "DRUID"}, pclass) and S or 0
ConditionCategory:RegisterCondition(104.0 - offset, "ENERGY", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. ENERGY,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 3)/(UnitPowerMax(c.Unit, 3)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "ENERGY"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "ENERGY")
	end,
})
ConditionCategory:RegisterCondition(104.1 - offset, "ENERGY_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. ENERGY,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 3) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(104.2 - offset, "ENERGY_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. ENERGY,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 3) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})

offset = TMW.tContains({"WARRIOR", "DRUID"}, pclass) and S or 0
ConditionCategory:RegisterCondition(105.0 - offset, "RAGE", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. RAGE,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_120",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 1)/(UnitPowerMax(c.Unit, 1)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "RAGE"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "RAGE")
	end,
})
ConditionCategory:RegisterCondition(105.1 - offset, "RAGE_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. RAGE,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_120",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(105.2 - offset, "RAGE_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. RAGE,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_120",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})

offset = pclass == "HUNTER" and S or 0
ConditionCategory:RegisterCondition(106.0 - offset, "FOCUS", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. FOCUS,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 2)/(UnitPowerMax(c.Unit, 2)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "FOCUS"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "FOCUS")
	end,
})
ConditionCategory:RegisterCondition(106.1 - offset, "FOCUS_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. FOCUS,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 2) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(106.2 - offset, "FOCUS_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. FOCUS,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 2) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})

offset = pclass == "DEATHKNIGHT" and S or 0
ConditionCategory:RegisterCondition(107.0 - offset, "RUNIC_POWER", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. RUNIC_POWER,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 6)/(UnitPowerMax(c.Unit, 6)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "RUNIC_POWER"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "RUNIC_POWER")
	end,
})
ConditionCategory:RegisterCondition(107.1 - offset, "RUNIC_POWER_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. RUNIC_POWER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 6) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(107.2 - offset, "RUNIC_POWER_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. RUNIC_POWER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPowerMax(c.Unit, 6) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})



ConditionCategory:RegisterSpacer(200)

ConditionCategory:RegisterCondition(208.0, "ALTPOWER", {
	text = L["CONDITIONPANEL_PERCENT"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
	tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\spell_shadow_mindflay",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower(c.Unit, 10)/(UnitPowerMax(c.Unit, 10)+epsilon) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "ALTERNATE"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "ALTERNATE"),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(208.1, "ALTPOWER_ABS", {
	text = L["CONDITIONPANEL_ABSOLUTE"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
	tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
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
ConditionCategory:RegisterCondition(208.2, "ALTPOWER_MAX", {
	text = L["CONDITIONPANEL_MAX"] .. " " .. L["CONDITIONPANEL_ALTPOWER"],
	tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
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
















-- The graveyard....

ConditionCategory:RegisterCondition(0, "ECLIPSE", {
	text = L["ECLIPSE"],
	tooltip = L["CONDITIONPANEL_ECLIPSE_DESC"],
	min = -100,
	max = 100,
	texttable = setmetatable({
		[-100] = "-100 (" .. L["MOON"] .. ")",
		[100] = "100 (" .. L["SUN"] .. ")",
	}, {__index = function(tbl, k) return k end}),

	unit = PLAYER,
	icon = "Interface\\PlayerFrame\\UI-DruidEclipse",
	tcoords = {0.65625000, 0.74609375, 0.37500000, 0.55468750},
	funcstr = "DEPRECATED"
})
ConditionCategory:RegisterCondition(0, "ECLIPSE_DIRECTION", {
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
	funcstr = "DEPRECATED"
})
ConditionCategory:RegisterCondition(0, "SHADOW_ORBS", {
	text = SHADOW_ORBS,
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Priest_Shadoworbs",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = "DEPRECATED",
})
ConditionCategory:RegisterCondition(0, "RUNES", {
	text = RUNES,
	--tooltip = L["CONDITIONPANEL_RUNES_DESC"],
	unit = false,
	nooperator = true,
	noslide = true,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
	funcstr = "DEPRECATED",
})
ConditionCategory:RegisterCondition(0, "RUNESRECH", {
	text = L["CONDITIONPANEL_RUNESRECH"],
	tooltip = L["CONDITIONPANEL_RUNESRECH_DESC"],
	unit = false,
	min = 0,
	max = 3,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost",
	funcstr = "DEPRECATED",
})
ConditionCategory:RegisterCondition(0, "RUNESLOCK", {
	text = L["CONDITIONPANEL_RUNESLOCK"],
	tooltip = L["CONDITIONPANEL_RUNESLOCK_DESC"],
	unit = false,
	min = 0,
	max = 3,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy",
	funcstr = "DEPRECATED",
})
ConditionCategory:RegisterCondition(0, "BURNING_EMBERS", {
	text = BURNING_EMBERS,
	min = 0,
	max = 4,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_warlock_burningembers",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = "DEPRECATED",
})
ConditionCategory:RegisterCondition(0, "BURNING_EMBERS_FRAGMENTS", {
	text = L["BURNING_EMBERS_FRAGMENTS"],
	tooltip = L["BURNING_EMBERS_FRAGMENTS_DESC"],
	min = 0,
	max = 40,
	unit = PLAYER,
	icon = "Interface\\Icons\\INV_Elemental_Mote_Fire01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = "DEPRECATED",
})
ConditionCategory:RegisterCondition(0, "DEMONIC_FURY", {
	text = DEMONIC_FURY,
	min = 0,
	max = 1000,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_Warlock_Eradication",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = "DEPRECATED",
})