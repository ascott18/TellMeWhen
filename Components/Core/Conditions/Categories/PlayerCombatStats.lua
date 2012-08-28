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
local L = TMW.L
local print = TMW.print

local CNDT = TMW.CNDT
local Env = CNDT.Env

local min, format = min, format

Env.UnitStat = UnitStat
Env.UnitAttackPower = UnitAttackPower
Env.UnitRangedAttackPower = UnitRangedAttackPower
Env.UnitSpellHaste = UnitSpellHaste
Env.GetMeleeHaste = GetMeleeHaste
Env.GetRangedHaste = GetRangedHaste
Env.GetExpertise = GetExpertise
Env.GetCritChance = GetCritChance
Env.GetRangedCritChance = GetRangedCritChance
Env.GetSpellCritChance = GetSpellCritChance
Env.GetMastery = GetMastery
Env.GetSpellBonusDamage = GetSpellBonusDamage
Env.GetSpellBonusHealing = GetSpellBonusHealing
	
local ConditionCategory = CNDT:GetCategory("STATS", 6, L["CNDTCAT_STATS"], true, false)

ConditionCategory:RegisterCondition(1,	 "STRENGTH", {
	text = _G["SPELL_STAT1_NAME"],
	category = L["CNDTCAT_STATS"],
	categorySpacebefore = true,
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_nature_strength",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitStat("player", 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(2,	 "AGILITY", {
	text = _G["SPELL_STAT2_NAME"],
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_holy_blessingofagility",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitStat("player", 2) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(3,	 "STAMINA", {
	text = _G["SPELL_STAT3_NAME"],
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_holy_wordfortitude",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitStat("player", 3) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(4,	 "INTELLECT", {
	text = _G["SPELL_STAT4_NAME"],
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_holy_magicalsentry",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitStat("player", 4) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(5,	 "SPIRIT", {
	text = _G["SPELL_STAT5_NAME"],
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_shadow_burningspirit",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitStat("player", 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(6,	 "MASTERY", {
	text = STAT_MASTERY,
	category = L["CNDTCAT_STATS"],
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_holy_championsbond",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetMastery() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("MASTERY_UPDATE")
	end,
})

ConditionCategory:RegisterSpacer(10)

local UnitAttackPower = UnitAttackPower
ConditionCategory:RegisterCondition(11,	 "MELEEAP", {
	text = MELEE_ATTACK_POWER,
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\INV_Sword_04",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitAttackPower = function(unit)
			local base, pos, neg = UnitAttackPower(unit)
			return base + pos + neg
		end,
	},
	funcstr = [[UnitAttackPower("player") c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_ATTACK_POWER", "player")
	end,
})

ConditionCategory:RegisterCondition(12,	 "MELEECRIT", {
	text = L["MELEECRIT"],
	category = L["CNDTCAT_STATS"],
	percent = true,
	texttable = CNDT.COMMON.pluspercent,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_CriticalStrike",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetCritChance()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
	end,
})
ConditionCategory:RegisterCondition(13,	 "MELEEHASTE", {
	text = L["MELEEHASTE"],
	category = L["CNDTCAT_STATS"],
	percent = true,
	texttable = CNDT.COMMON.pluspercent,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_nature_bloodlust",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetMeleeHaste()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_ATTACK_SPEED", "player")
	end,
})
ConditionCategory:RegisterCondition(14,	 "EXPERTISE", {
	text = _G["COMBAT_RATING_NAME"..CR_EXPERTISE],
	category = L["CNDTCAT_STATS"],
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_rogue_shadowstrikes",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetExpertise() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
	end,
})

ConditionCategory:RegisterSpacer(20)

ConditionCategory:RegisterCondition(21,	 "RANGEAP", {
	text = RANGED_ATTACK_POWER,
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\INV_Weapon_Bow_07",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitRangedAttackPower("player") c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_RANGED_ATTACK_POWER", "player")
	end,
})
ConditionCategory:RegisterCondition(22,	 "RANGEDCRIT", {
	text = L["RANGEDCRIT"],
	category = L["CNDTCAT_STATS"],
	percent = true,
	texttable = CNDT.COMMON.pluspercent,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_CriticalStrike",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetRangedCritChance()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
	end,
})
ConditionCategory:RegisterCondition(23,	 "RANGEDHASTE", {
	text = L["RANGEDHASTE"],
	category = L["CNDTCAT_STATS"],
	percent = true,
	texttable = CNDT.COMMON.pluspercent,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_hunter_runningshot",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetRangedHaste()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_RANGEDDAMAGE", "player")
	end,
})

ConditionCategory:RegisterSpacer(30)

if MAX_SPELL_SCHOOLS ~= 7 then
	TMW:Error("MAX_SPELL_SCHOOLS has changed, so the spell school dependent conditions need updating")
end

local GetSpellBonusDamage = GetSpellBonusDamage
ConditionCategory:RegisterCondition(31,	 "SPELLDMG", {
	text = STAT_SPELLDAMAGE,
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_fire_flamebolt",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellBonusDamage = function()
			return min(
				GetSpellBonusDamage(2),
				GetSpellBonusDamage(3),
				GetSpellBonusDamage(4),
				GetSpellBonusDamage(5),
				GetSpellBonusDamage(6),
				GetSpellBonusDamage(7)
			)
		end,
	},
	funcstr = [[GetSpellBonusDamage() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_DAMAGE_DONE_MODS"),
			ConditionObject:GenerateNormalEventString("SPELL_POWER_CHANGED") --TMW.ISMOP
	end,
})

ConditionCategory:RegisterCondition(32,	 "SPELLHEALING", {
	text = STAT_SPELLHEALING,
	category = L["CNDTCAT_STATS"],
	range = 5000,
	unit = PLAYER,
	texttable = CNDT.COMMON.commanumber,
	icon = "Interface\\Icons\\spell_nature_healingtouch",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetSpellBonusHealing() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_DAMAGE_DONE_MODS")
	end,
})

local GetSpellCritChance = GetSpellCritChance
ConditionCategory:RegisterCondition(33,	 "SPELLCRIT", {
	text = L["SPELLCRIT"],
	category = L["CNDTCAT_STATS"],
	min = 0,
	max = 100,
	percent = true,
	texttable = CNDT.COMMON.pluspercent,
	unit = PLAYER,
	icon = "Interface\\Icons\\inv_gizmo_supersappercharge",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellCritChance = function()
			return min(
				GetSpellCritChance(2),
				GetSpellCritChance(3),
				GetSpellCritChance(4),
				GetSpellCritChance(5),
				GetSpellCritChance(6),
				GetSpellCritChance(7)
			)
		end,
	},
	funcstr = [[GetSpellCritChance() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
	end,
})

ConditionCategory:RegisterCondition(34,	 "SPELLHASTE", {
	text = L["SPELLHASTE"],
	category = L["CNDTCAT_STATS"],
	min = 0,
	max = 100,
	percent = true,
	texttable = CNDT.COMMON.pluspercent,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_mage_timewarp",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitSpellHaste("player")/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_SPELL_HASTE", "player")
	end,
})

Env.GetManaRegen = GetManaRegen
ConditionCategory:RegisterCondition(35,	 "MANAREGEN", {
	text = MANA_REGEN,
	category = L["CNDTCAT_STATS"],
	range = 1000/5,
	unit = PLAYER,
	texttable = function(k) return format(L["MP5"], CNDT.COMMON.commanumber(k)*5) end,
	icon = "Interface\\Icons\\spell_magic_managain",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetManaRegen() c.Operator c.Level]], -- anyone know of an event that can be reliably listened to to get this?
	-- events = EVENTS NEEDED FOR THIS!! TODO
})
ConditionCategory:RegisterCondition(36,	 "MANAREGENCOMBAT", {
	text = MANA_REGEN_COMBAT,
	category = L["CNDTCAT_STATS"],
	range = 1000/5,
	unit = PLAYER,
	texttable = function(k) return format(L["MP5"], CNDT.COMMON.commanumber(k)*5) end,
	icon = "Interface\\Icons\\spell_frost_summonwaterelemental",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[select(2, GetManaRegen()) c.Operator c.Level]],
	-- events = EVENTS NEEDED FOR THIS!! TODO
})

