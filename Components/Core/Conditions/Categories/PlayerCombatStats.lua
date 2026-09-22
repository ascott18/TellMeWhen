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
local issecretvalue = TMW.issecretvalue

local CNDT = TMW.CNDT
local Env = CNDT.Env

local min, format = min, format

local function Unsecret(func)
	if not func or not TMW.clientHasSecrets then return func end

	return function(...)
		local ret = func(...)
		return issecretvalue(ret) and 0 or ret
	end
end

Env.UnitStat = Unsecret(UnitStat)
Env.GetHaste = Unsecret(GetHaste)
Env.GetExpertise = Unsecret(GetExpertise)
Env.GetCritChance = Unsecret(GetCritChance)
Env.GetSpellCritChance = Unsecret(GetSpellCritChance)
Env.GetMasteryEffect = Unsecret(GetMasteryEffect)
Env.GetSpellBonusDamage = Unsecret(GetSpellBonusDamage)
Env.GetSpellBonusHealing = Unsecret(GetSpellBonusHealing)

if not TMW.clientHasSecrets then
	Env.GetManaRegen = GetManaRegen
else
	Env.GetManaRegen = function()
		local base, combat = GetManaRegen()
		if issecretvalue(base) then return 0, 0 end
		return base, combat
	end
end

-- Stats that arrived with Warlords. Their STAT_* strings don't exist on older clients,
-- so these can't even be registered there.
local hasWarlordsStats = TMW.ClassicExpansionAtLeast(LE_EXPANSION_WARLORDS_OF_DRAENOR)

-- Stats that Warlords took away.
local hasPreWarlordsStats = TMW.ClassicExpansionAtMost(LE_EXPANSION_MISTS_OF_PANDARIA)

-- Ranged weapons stopped having stats of their own in Mists.
local hasRangedStats = hasPreWarlordsStats
	and UnitRangedAttackPower and GetRangedCritChance and GetRangedHaste


TMW:RegisterUpgrade(71008, {
	replacements = {
		RANGEAP = "MELEEAP",
		RANGEDCRIT = "MELEECRIT",
		RANGEDHASTE = "MELEEHASTE",
		SPELLHEALING = "SPELLDMG",
		SPELLCRIT = "MELEECRIT",
		SPELLHASTE = "MELEEHASTE",
	},
	condition = function(self, condition)
		if self.replacements[condition.Type] then
			condition.Type = self.replacements[condition.Type]
		end
	end,
})


local ConditionCategory = CNDT:GetCategory("STATS", 6, L["CNDTCAT_STATS"], true, true)

ConditionCategory:RegisterCondition(1,	 "STRENGTH", {
	text = _G["SPELL_STAT1_NAME"],
	range = 2000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_nature_strength",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[UnitStat("player", 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(2,	 "AGILITY", {
	text = _G["SPELL_STAT2_NAME"],
	range = 2000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_holy_blessingofagility",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[UnitStat("player", 2) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(3,	 "STAMINA", {
	text = _G["SPELL_STAT3_NAME"],
	range = 2000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_holy_wordfortitude",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[UnitStat("player", 3) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
ConditionCategory:RegisterCondition(4,	 "INTELLECT", {
	text = _G["SPELL_STAT4_NAME"],
	range = 2000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_holy_magicalsentry",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[UnitStat("player", 4) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})


ConditionCategory:RegisterSpacer(5)


ConditionCategory:RegisterCondition(6,	 "MELEECRIT", {
	text = STAT_CRITICAL_STRIKE,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_CriticalStrike",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[max(GetCritChance(), GetSpellCritChance(2))/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
	end,
})
ConditionCategory:RegisterCondition(7,	 "MELEEHASTE", {
	text = STAT_HASTE,
	percent = true,
	formatter = TMW.C.Formatter.PLUSPERCENT,
	min = 0,
	range = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_nature_bloodlust",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[GetHaste()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_ATTACK_SPEED", "player")
	end,
})
if GetMasteryEffect and TMW.ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) then
	ConditionCategory:RegisterCondition(8,	 "MASTERY", {
		text = STAT_MASTERY,
		min = 0,
		range = 100,
		formatter = TMW.C.Formatter.PERCENT,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_holy_championsbond",
		tcoords = CNDT.COMMON.standardtcoords,
		maybeSecret = true,
		funcstr = [[GetMasteryEffect() c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("MASTERY_UPDATE")
		end,
	})
end

-- Expertise stopped being a player stat in Warlords. Settings that name it still exist, so
-- where it's gone it stays as a deprecated stub.
if CR_EXPERTISE then
	if GetExpertise and hasPreWarlordsStats then
		ConditionCategory:RegisterCondition(9,	 "EXPERTISE", {
			text = _G["COMBAT_RATING_NAME"..CR_EXPERTISE],
			min = 0,
			max = 100,
			unit = PLAYER,
			icon = "Interface\\Icons\\ability_rogue_shadowstrikes",
			tcoords = CNDT.COMMON.standardtcoords,
			maybeSecret = true,
			funcstr = [[GetExpertise() c.Operator c.Level]],
			events = function(ConditionObject, c)
				return
					ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
			end,
		})
	else
		ConditionCategory:RegisterCondition(9,	 "EXPERTISE", {
			text = _G["COMBAT_RATING_NAME"..CR_EXPERTISE],
			funcstr = "DEPRECATED",
			min = 0,
			range = 100,
		})
	end
end


ConditionCategory:RegisterSpacer(10)


ConditionCategory:RegisterCondition(11,	"SPIRIT", {
	text = _G["SPELL_STAT5_NAME"],
	range = 2000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_shadow_burningspirit",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[UnitStat("player", 5) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})
if hasWarlordsStats then
	-- Multistrike came and went inside Warlords, so it's a stub everywhere.
	ConditionCategory:RegisterCondition(13, "MULTISTRIKE", {
		text = STAT_MULTISTRIKE,
		min = 0,
		range = 50,
		step = 0.1,
		formatter = TMW.C.Formatter.PERCENT,
		unit = PLAYER,
		icon = "Interface\\Icons\\Ability_UpgradeMoonGlaive",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = "DEPRECATED",
	})
	ConditionCategory:RegisterCondition(14, "LIFESTEAL", {
		text = STAT_LIFESTEAL,
		min = 0,
		range = 10,
		step = 0.1,
		formatter = TMW.C.Formatter.PERCENT,
		unit = PLAYER,
		icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = [[GetLifesteal() c.Operator c.Level]],
		Env = {
			GetLifesteal = Unsecret(GetLifesteal),
		},
		maybeSecret = true,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("LIFESTEAL_UPDATE")
		end,
	})
	ConditionCategory:RegisterCondition(15, "VERSATILITY", {
		text = STAT_VERSATILITY,
		min = 0,
		range = 50,
		step = 0.1,
		formatter = TMW.C.Formatter.PERCENT,
		unit = PLAYER,
		icon = "Interface\\Icons\\achievement_dungeon_icecrown_frostmourne",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = [[GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE) c.Operator c.Level]],
		Env = {
			CR_VERSATILITY_DAMAGE_DONE = CR_VERSATILITY_DAMAGE_DONE,
			GetCombatRatingBonus = Unsecret(GetCombatRatingBonus),
			GetVersatilityBonus = Unsecret(GetVersatilityBonus),
		},
		maybeSecret = true,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE")
		end,
	})
	ConditionCategory:RegisterCondition(16, "AVOIDANCE", {
		text = STAT_AVOIDANCE,
		min = 0,
		range = 10,
		step = 0.1,
		formatter = TMW.C.Formatter.PERCENT,
		unit = PLAYER,
		icon = "Interface\\Icons\\spell_shadow_shadowward",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = [[GetAvoidance() c.Operator c.Level]],
		Env = {
			GetAvoidance = Unsecret(GetAvoidance),
		},
		maybeSecret = true,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("AVOIDANCE_UPDATE")
		end,
	})
end


if hasRangedStats then
	ConditionCategory:RegisterSpacer(20)

	local UnitRangedAttackPower = UnitRangedAttackPower
	ConditionCategory:RegisterCondition(21, "RANGEAP", {
		text = RANGED_ATTACK_POWER,
		range = 5000,
		unit = PLAYER,
		formatter = TMW.C.Formatter.COMMANUMBER,
		icon = "Interface\\Icons\\inv_weapon_bow_12",
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			RANGEAP_UnitAttackPower = function(unit)
				local base, pos, neg = UnitRangedAttackPower(unit)
				if issecretvalue(base) then return 0 end
				return base + pos + neg
			end,
		},
		maybeSecret = true,
		funcstr = [[RANGEAP_UnitAttackPower("player") c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_RANGED_ATTACK_POWER", "player")
		end,
	})
end


ConditionCategory:RegisterSpacer(30)

local UnitAttackPower = UnitAttackPower
ConditionCategory:RegisterCondition(30.5, "MELEEAP", {
	-- Only worth calling out as melee where there's a ranged one to tell it apart from.
	text = hasRangedStats and MELEE_ATTACK_POWER or STAT_ATTACK_POWER,
	range = 5000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\INV_Sword_04",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		MELEEAP_UnitAttackPower = function(unit)
			local base, pos, neg = UnitAttackPower(unit)
			if issecretvalue(base) then return 0 end
			return base + pos + neg
		end,
	},
	maybeSecret = true,
	funcstr = [[MELEEAP_UnitAttackPower("player") c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_ATTACK_POWER", "player")
	end,
})


if MAX_SPELL_SCHOOLS ~= 7 then
	TMW:Error("MAX_SPELL_SCHOOLS has changed, so the spell school dependent conditions need updating")
end
local GetSpellBonusDamage = GetSpellBonusDamage
ConditionCategory:RegisterCondition(31,	 "SPELLDMG", {
	text = STAT_SPELLPOWER,
	range = 5000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_fire_flamebolt",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		SPELLDMG_GetSpellBonusDamage = function()
			local val = GetSpellBonusDamage(2)
			if issecretvalue(val) then return 0 end
			return min(
				val,
				GetSpellBonusDamage(3),
				GetSpellBonusDamage(4),
				GetSpellBonusDamage(5),
				GetSpellBonusDamage(6),
				GetSpellBonusDamage(7)
			)
		end,
	},
	maybeSecret = true,
	funcstr = [[SPELLDMG_GetSpellBonusDamage() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_DAMAGE_DONE_MODS"),
			ConditionObject:GenerateNormalEventString("SPELL_POWER_CHANGED") --TMW.ISMOP
	end,
})


ConditionCategory:RegisterCondition(35,	 "MANAREGEN", {
	text = MANA_REGEN,
	range = 1000/5,
	unit = PLAYER,
	texttable = function(k) return format(L["MP5"], TMW.C.Formatter.COMMANUMBER:Format(k)*5) end,
	icon = "Interface\\Icons\\spell_magic_managain",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[GetManaRegen() c.Operator c.Level]], -- anyone know of an event that can be reliably listened to to get this?
})
ConditionCategory:RegisterCondition(36,	 "MANAREGENCOMBAT", {
	text = MANA_REGEN_COMBAT,
	range = 1000/5,
	unit = PLAYER,
	texttable = function(k) return format(L["MP5"], TMW.C.Formatter.COMMANUMBER:Format(k)*5) end,
	icon = "Interface\\Icons\\spell_frost_summonwaterelemental",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[select(2, GetManaRegen()) c.Operator c.Level]],
})


ConditionCategory:RegisterSpacer(40)

local UnitArmor = UnitArmor
ConditionCategory:RegisterCondition(41, "ARMOR", {
	text = ARMOR,
	range = 5000,
	unit = PLAYER,
	formatter = TMW.C.Formatter.COMMANUMBER,
	icon = "Interface\\Icons\\spell_holy_devotionaura",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		-- The second return is what the character sheet shows; the rest break it down.
		ARMOR_UnitArmor = function(unit)
			local _, effective = UnitArmor(unit)
			return issecretvalue(effective) and 0 or effective
		end,
	},
	maybeSecret = true,
	funcstr = [[ARMOR_UnitArmor("player") c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_RESISTANCES", "player"),
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})

Env.GetDodgeChance = Unsecret(GetDodgeChance)
ConditionCategory:RegisterCondition(42, "DODGE", {
	text = STAT_DODGE,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_nature_invisibilty",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[GetDodgeChance()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})

Env.GetParryChance = Unsecret(GetParryChance)
ConditionCategory:RegisterCondition(43, "PARRY", {
	text = STAT_PARRY,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_parry",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[GetParryChance()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})

Env.GetBlockChance = Unsecret(GetBlockChance)
ConditionCategory:RegisterCondition(44, "BLOCK", {
	text = STAT_BLOCK,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_defend",
	tcoords = CNDT.COMMON.standardtcoords,
	maybeSecret = true,
	funcstr = [[GetBlockChance()/100 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("COMBAT_RATING_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_STATS", "player")
	end,
})

-- Defense skill is gone from retail entirely, API and all.
if UnitDefenseSkill then
	local UnitDefenseSkill = UnitDefenseSkill
	ConditionCategory:RegisterCondition(45, "DEFENSE", {
		text = DEFENSE,
		range = 200,
		unit = PLAYER,
		formatter = TMW.C.Formatter.COMMANUMBER,
		icon = "Interface\\Icons\\ability_warrior_defensivestance",
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			-- The sheet shows base plus modifier, and the modifier can be negative.
			DEFENSE_UnitDefenseSkill = function(unit)
				local base, modifier = UnitDefenseSkill(unit)
				if issecretvalue(base) then return 0 end
				return base + modifier
			end,
		},
		maybeSecret = true,
		funcstr = [[DEFENSE_UnitDefenseSkill("player") c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_STATS", "player"),
				ConditionObject:GenerateNormalEventString("SKILL_LINES_CHANGED")
		end,
	})
end
