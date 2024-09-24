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

local CNDT = TMW.CNDT
local Env = CNDT.Env

local _, pclass = UnitClass("Player")

local wow_900 = select(4, GetBuildInfo()) >= 90000
local GetSpellName = TMW.GetSpellName

Env.UnitHealth = UnitHealth
Env.UnitHealthMax = UnitHealthMax
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

local healthEvent = wow_900 and "UNIT_HEALTH" or "UNIT_HEALTH_FREQUENT"

ConditionCategory:RegisterCondition(1.0, "HEALTH", {
	text = HEALTH .. " - " .. L["CONDITIONPANEL_PERCENT"],
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
			ConditionObject:GenerateNormalEventString(healthEvent, CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(1.1, "HEALTH_ABS", {
	text = HEALTH .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 100000,
	icon = "Interface\\Icons\\inv_alchemy_elixir_05",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitHealth(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString(healthEvent, CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(1.2, "HEALTH_MAX", {
	text = HEALTH .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 100000,
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

if GetPetHappiness then
	ConditionCategory:RegisterCondition(2,	 "HAPPINESS", {
		-- poor translation to other languages, but better than just HAPPINESS on its own.
		text = PET .. " " .. HAPPINESS,
		
		bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEVALUES"],
		bitFlags = {
			[1] = PET_HAPPINESS1,
			[2] = PET_HAPPINESS2,
			[3] = PET_HAPPINESS3
		},

		unit = PET,
		icon = "Interface\\PetPaperDollFrame\\UI-PetHappiness",
		tcoords = {0.390625, 0.5491, 0.03, 0.3305},
		Env = {
			GetPetHappiness = GetPetHappiness,
		},
		funcstr = [[ BITFLAGSMAPANDCHECK( GetPetHappiness() or 0 ) ]],
		hidden = pclass ~= "HUNTER",
		events = function(ConditionObject, c)
			return
				ConditionObject:GetUnitChangedEventString(CNDT:GetUnit("pet")),
				ConditionObject:GenerateNormalEventString("UNIT_HAPPINESS", "pet"),
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "pet")
		end,
	})
end




ConditionCategory:RegisterSpacer(3)


if TMW.isRetail or TMW.isCata then
	ConditionCategory:RegisterCondition(23, "SOUL_SHARDS", {
		text = SOUL_SHARDS_POWER,
		min = 0,
		max = 6,
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.SoulShards),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "SOUL_SHARDS")
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
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.HolyPower),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "HOLY_POWER")
		end,
		hidden = pclass ~= "PALADIN",
	})
end

-- Private Class Resources (other players can't see them)
if TMW.isRetail then
	ConditionCategory:RegisterCondition(23.1, "SOUL_SHARD_FRAGMENTS", {
		text = L["RESOURCE_FRAGMENTS"]:format(SOUL_SHARDS_POWER),
		min = 0,
		max = 60,
		unit = PLAYER,
		icon = "Interface\\Icons\\inv_misc_gem_amethyst_02",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d, true) c.Operator c.Level]]):format(Enum.PowerType.SoulShards),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "SOUL_SHARDS")
		end,
		hidden = pclass ~= "WARLOCK",
	})
	ConditionCategory:RegisterCondition(25, "RUNES2", {
		text = L["CONDITIONPANEL_RUNES"],
		tooltip = L["CONDITIONPANEL_RUNES_DESC3"],
		unit = false,
		min = 0,
		max = 6,
		icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
		Env = {
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
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Chi),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "CHI")
		end,
		hidden = pclass ~= "MONK",
	})
	ConditionCategory:RegisterCondition(26.1, "STAGGER", {
		text = GetSpellName(115069) .. " - " .. L["CONDITIONPANEL_PERCENTOFMAXHP"],
		percent = true,
		formatter = TMW.C.Formatter.PERCENT,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = 611419,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			UnitStagger = UnitStagger,
		},
		funcstr = [[(UnitStagger("player") or 0) / (UnitHealthMax("player")+epsilon) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_ABSORB_AMOUNT_CHANGED", "player"),
				ConditionObject:GenerateNormalEventString("UNIT_MAXHEALTH", "player")
		end,
		hidden = pclass ~= "MONK",
	})
	ConditionCategory:RegisterCondition(26.15, "STAGGER_CURPCT", {
		text = GetSpellName(115069) .. " - " .. L["CONDITIONPANEL_PERCENTOFCURHP"],
		percent = true,
		formatter = TMW.C.Formatter.PERCENT,
		min = 0,
		max = 100,
		unit = PLAYER,
		icon = 611419,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			UnitStagger = UnitStagger,
		},
		funcstr = [[(UnitStagger("player") or 0) / (UnitHealth("player")+epsilon) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_ABSORB_AMOUNT_CHANGED", "player"),
				ConditionObject:GenerateNormalEventString(healthEvent, "player")
		end,
		hidden = pclass ~= "MONK",
	})
	ConditionCategory:RegisterCondition(26.2, "STAGGER_ABS", {
		text = GetSpellName(115069) .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
		min = 0,
		range = 1000000,
		unit = PLAYER,
		icon = 611419,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			UnitStagger = UnitStagger,
		},
		funcstr = [[(UnitStagger("player") or 0) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_ABSORB_AMOUNT_CHANGED", "player")
		end,
		hidden = pclass ~= "MONK",
	})
	local offset = TMW.tContains({"ROGUE", "DRUID"}, pclass) and 0 or 62
	ConditionCategory:RegisterCondition(27 + offset, "COMBO", {
		text = L["CONDITIONPANEL_COMBO"],
		min = 0,
		max = 10,
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_rogue_eviscerate",
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			UnitPower = UnitPower,
		},
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.ComboPoints),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "COMBO_POINTS")
		end,
	})
	ConditionCategory:RegisterCondition(28, "ARCANE_CHARGES", {
		text = ARCANE_CHARGES_POWER,
		min = 0,
		max = 4,
		icon = "Interface\\Icons\\spell_arcane_arcanetorrent",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.ArcaneCharges),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "ARCANE_CHARGES")
		end,
		hidden = pclass ~= "MAGE",
	})
	ConditionCategory:RegisterCondition(29, "ESSENCE", {
		text = POWER_TYPE_ESSENCE,
		min = 0,
		max = 6,
		icon = "Interface\\Icons\\ability_evoker_essenceburst",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Essence),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "ESSENCE")
		end,
		hidden = pclass ~= "EVOKER" or not Enum.PowerType.Essence,
	})
else
	local function runeFuncstrHelper(c)
		local str = ""
		for i = 1, 6 do
			--[[
				[1] = blood
				[2] = unholy
				[3] = frost

				[4] = death blood
				[5] = death unholy
				[6] = death frost
			]]
			local checked = CNDT:GetBitFlag(c, i)

			if checked then
				local death = false
				local bothTypes
				if i > 3 then
					death = true
					i = i - 3
					bothTypes = CNDT:GetBitFlag(c, i)
				else
					bothTypes = CNDT:GetBitFlag(c, i+3)
				end

				-- An index of 2 corresponds to runes 3 and 4, for example.
				-- An index of 3 corresponds to runes 5 and 6.
				local runeID1 = i*2 - 1
				local runeID2 = runeID1 + 1

				for _, runeID in TMW:Vararg(runeID1, runeID2) do
					-- If we aren't on death runes in our outer loop,
					-- or if we are only checking one type of this rune slot, 
					-- put the plus now.
					if not (death and bothTypes) then
						str = str .. [[ + ]]
					end

					-- If we're checking both runes of this slot, we don't need to check if
					-- the rune is a death rune (because we would check again to see if it isn't a death rune),
					-- which is completely redundant.
					if not bothTypes then
						str = str .. [[ (GetRuneType(]]..runeID..[[)]]
						str = str .. (death and "=" or "~") .. [[=4 and ]]
					end

					-- If we aren't on death runes in our outer loop,
					-- or if we are only checking one type of this rune slot, 
					-- then check the count of this rune slot.

					-- If we ARE on death runes, and we are checking both types of this slot,
					-- then don't check for this, because it will already exist in the string,
					-- which would cause double counting.
					if not (death and bothTypes) then
						if bothTypes then
							-- We still need the parenthesis that was excluded earlier.
							str = str .. "("
						end

						if c.Type == "RUNES2" then
							str = str .. [[GetRuneCount(]]..runeID..[[) or 0)]]

						elseif c.Type == "RUNESRECH" then
							str = str .. [[IsRuneRecharging(]]..runeID..[[,]] .. (runeID == runeID1 and runeID2 or runeID1) .. [[) and 1 or 0)]]

						elseif c.Type == "RUNESLOCK" then
							-- This is more efficient to be in a helper function (otherwise it would require 3 calls to GetRuneCooldown)
							-- We can't do simple comparison to see if the start time is in the future to check if a rune is locked
							-- because this doesn't work all the time (sometimes a cooldown down rune will report a start slightly in the future
							-- right when it starts).
							str = str .. [[IsRuneLocked(]]..runeID..[[,]] .. (runeID == runeID1 and runeID2 or runeID1) .. [[) and 1 or 0)]]
						end
					end
				end
			end
		end
		if str == "" then
			return [[true]]
		else
			return "" .. str:trim("+ ") .. " c.Operator c.Level" 
		end
	end
	local function GetRuneCount(runeSlot)
		local start = GetRuneCooldown(runeSlot)
		return start == 0 and 1 or 0
	end
	local function IsRuneLocked(runeSlot, otherSlot)
		local start = GetRuneCooldown(runeSlot)
		if start == 0 then
			-- This rune is ready, so it isn't locked.
			return false
		else
			local start2 = GetRuneCooldown(otherSlot)
			if start2 == 0 then
				-- The other rune is ready, so this one is ready or recharging.
				return false
			end
			if start > start2 then
				-- Both runes aren't ready, and this one has a start time after the other,
				-- so it must be locked.
				return true
			end
		end
		
		return false
	end
	local function IsRuneRecharging(runeSlot, otherSlot)
		local start = GetRuneCooldown(runeSlot)
		if start == 0 then
			-- This rune is ready, so it isn't recharging.
			return false
		else
			local start2 = GetRuneCooldown(otherSlot)
			if start2 == 0 then
				-- The other rune is ready, and this one isn't, so it must be recharging.
				return true
			end
			if start < start2 then
				-- Both runes aren't ready, and this one has a start time before the other,
				-- so it must be recharging (the other one is locked).
				return true
			end
		end
		
		return false
	end

	ConditionCategory:RegisterCondition(15.1, "RUNES2", {
		text = L["CONDITIONPANEL_RUNES"],
		tooltip = L["CONDITIONPANEL_RUNES_DESC3"] .. "\r\n\r\n" .. L["CONDITIONPANEL_RUNES_DESC_GENERIC"],
		unit = false,
		runesConfig = true,
		min = 0,
		max = 6,
		icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
		Env = {
			GetRuneType = GetRuneType,
			GetRuneCount = GetRuneCount,
		},
		funcstr = runeFuncstrHelper,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("RUNE_POWER_UPDATE"),
				ConditionObject:GenerateNormalEventString("RUNE_TYPE_UPDATE")
		end,
		hidden = pclass ~= "DEATHKNIGHT",
	})
	ConditionCategory:RegisterCondition(15.2, "RUNESRECH", {
		text = L["CONDITIONPANEL_RUNESRECH"],
		tooltip = L["CONDITIONPANEL_RUNESRECH_DESC"] .. "\r\n\r\n" .. L["CONDITIONPANEL_RUNES_DESC_GENERIC"],
		unit = false,
		runesConfig = true,
		min = 0,
		max = 3,
		icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost",
		Env = {
			GetRuneType = GetRuneType,
			GetRuneCount = GetRuneCount,
			IsRuneRecharging = IsRuneRecharging,
		},
		funcstr = runeFuncstrHelper,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("RUNE_POWER_UPDATE"),
				ConditionObject:GenerateNormalEventString("RUNE_TYPE_UPDATE")
		end,
		hidden = pclass ~= "DEATHKNIGHT",
	})
		
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
end

ConditionCategory:RegisterSpacer(30)
ConditionCategory:RegisterSpacer(70)


-- Public Class Resources that don't need percent/abs/max conditions
local S = 80
local offset
if TMW.isRetail then
	offset = pclass == "PRIEST" and S or 0
	ConditionCategory:RegisterCondition(90.0 - offset, "INSANITY", {
		text = INSANITY_POWER,
		min = 0,
		max = 150, -- 150 with talent Voidtouched
		icon = "Interface\\Icons\\spell_shadow_painandsuffering",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Insanity),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "INSANITY"),
				ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "INSANITY")
		end,
	})

	offset = pclass == "DEMONHUNTER" and S or 0
	ConditionCategory:RegisterCondition(91.0 - offset, "FURY", {
		text = FURY,
		min = 0,
		range = 200,
		icon = "Interface\\Icons\\ability_warlock_demonicpower",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Fury),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "FURY"),
				ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "FURY")
		end,
	})
	ConditionCategory:RegisterCondition(92.0 - offset, "PAIN", {
		text = PAIN,
		min = 0,
		range = 200,
		icon = "Interface\\Icons\\ability_demonhunter_torment",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Pain),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "PAIN"),
				ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "PAIN")
		end,
	})

	offset = pclass == "SHAMAN" and S or 0
	ConditionCategory:RegisterCondition(93 - offset, "MAELSTROM", {
		text = MAELSTROM_POWER,
		min = 0,
		max = 200,
		icon = "Interface\\Icons\\spell_shaman_maelstromweapon",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Maelstrom),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "MAELSTROM"),
				ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "MAELSTROM")
		end,
	})

	offset = pclass == "DRUID" and S or 0
	ConditionCategory:RegisterCondition(94 - offset, "LUNAR_POWER", {
		text = LUNAR_POWER,
		min = 0,
		max = 130, -- Druid tier set increases this to 130
		icon = "Interface\\Icons\\talentspec_druid_balance",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.LunarPower),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "LUNAR_POWER"),
				ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "LUNAR_POWER")
		end,
	})
end

ConditionCategory:RegisterSpacer(100)

-- Resources with Percent, Abs, and Max conditions.

S = 50
ConditionCategory:RegisterCondition(102.0, "DEFAULT", {
	text = L["CONDITIONPANEL_POWER"] .. " - " .. L["CONDITIONPANEL_PERCENT"],
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
ConditionCategory:RegisterCondition(102.1, "DEFAULT_ABS", {
	text = L["CONDITIONPANEL_POWER"] .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
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
ConditionCategory:RegisterCondition(102.2, "DEFAULT_MAX", {
	text = L["CONDITIONPANEL_POWER"] .. " - " .. L["CONDITIONPANEL_MAX"],
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

offset = TMW.tContains({"PALADIN", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "MONK", not TMW.isRetail and "HUNTER" or nil}, pclass) and S or 0
ConditionCategory:RegisterCondition(103.0 - offset, "MANA", {
	text = MANA .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_126",
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
	icon = "Interface\\Icons\\inv_potion_126",
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
	icon = "Interface\\Icons\\inv_potion_126",
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
	icon = "Interface\\Icons\\inv_potion_125",
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
	icon = "Interface\\Icons\\inv_potion_125",
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
	icon = "Interface\\Icons\\inv_potion_125",
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
	icon = "Interface\\Icons\\inv_potion_120",
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
	icon = "Interface\\Icons\\inv_potion_120",
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
	icon = "Interface\\Icons\\inv_potion_120",
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
	icon = "Interface\\Icons\\inv_potion_124",
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
	icon = "Interface\\Icons\\inv_potion_124",
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
	icon = "Interface\\Icons\\inv_potion_124",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Focus),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "FOCUS")
	end,
})

offset = pclass == "DEATHKNIGHT" and S or 0
ConditionCategory:RegisterCondition(107.0 - offset, "RUNIC_POWER", {
	text = RUNIC_POWER .. " - " .. L["CONDITIONPANEL_PERCENT"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d)/(UnitPowerMax(c.Unit, %d)+epsilon) c.Operator c.Level]]):format(Enum.PowerType.RunicPower, Enum.PowerType.RunicPower),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "RUNIC_POWER"),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "RUNIC_POWER")
	end,
})
ConditionCategory:RegisterCondition(107.1 - offset, "RUNIC_POWER_ABS", {
	text = RUNIC_POWER .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPower(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.RunicPower),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "RUNIC_POWER")
	end,
})
ConditionCategory:RegisterCondition(107.2 - offset, "RUNIC_POWER_MAX", {
	text = RUNIC_POWER .. " - " .. L["CONDITIONPANEL_MAX"],
	formatter = TMW.C.Formatter.COMMANUMBER,
	min = 0,
	range = 200,
	icon = "Interface\\Icons\\inv_potion_128",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.RunicPower),
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "RUNIC_POWER")
	end,
})




if TMW.isRetail or TMW.isCata then
	ConditionCategory:RegisterSpacer(200)
	-- Altpower was added in cata
	ConditionCategory:RegisterCondition(208.0, "ALTPOWER", {
		text = L["CONDITIONPANEL_ALTPOWER"] .. " - " .. L["CONDITIONPANEL_PERCENT"],
		tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
		percent = true,
		formatter = TMW.C.Formatter.PERCENT,
		min = 0,
		max = 100,
		icon = "Interface\\Icons\\spell_shadow_mindflay",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower(c.Unit, %d)/(UnitPowerMax(c.Unit, %d)+epsilon) c.Operator c.Level]]):format(Enum.PowerType.Alternate, Enum.PowerType.Alternate),
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
		text = L["CONDITIONPANEL_ALTPOWER"] .. " - " .. L["CONDITIONPANEL_ABSOLUTE"],
		tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
		formatter = TMW.C.Formatter.COMMANUMBER,
		min = 0,
		range = 200,
		icon = "Interface\\Icons\\spell_shadow_mindflay",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPower(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Alternate),
		events = function(ConditionObject, c)
			return
				ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit), "ALTERNATE"),
				ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", CNDT:GetUnit(c.Unit))
		end,
	})
	ConditionCategory:RegisterCondition(208.2, "ALTPOWER_MAX", {
		text = L["CONDITIONPANEL_ALTPOWER"] .. " - " .. L["CONDITIONPANEL_MAX"],
		tooltip = L["CONDITIONPANEL_ALTPOWER_DESC"],
		formatter = TMW.C.Formatter.COMMANUMBER,
		min = 0,
		range = 200,
		icon = "Interface\\Icons\\spell_shadow_mindflay",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = ([[UnitPowerMax(c.Unit, %d) c.Operator c.Level]]):format(Enum.PowerType.Alternate),
		events = function(ConditionObject, c)
			return
				ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit), "ALTERNATE"),
				ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_SHOW", CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_POWER_BAR_HIDE", CNDT:GetUnit(c.Unit))
		end,
	})
end

if TMW.isCata then
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
		funcstr = ([[UnitPower("player", %d) c.Operator c.Level]]):format(Enum.PowerType.Balance),
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player", "BALANCE")
		end,
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
		funcstr = "c.Level == (GetEclipseDirection() == 'sun' and 1 or 0)",

		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("ECLIPSE_DIRECTION_CHANGE")
		end,
	})
end















-- The graveyard....

ConditionCategory:RegisterCondition(0, "SHADOW_ORBS", {
	text = SHADOW_ORBS,
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Priest_Shadoworbs",
	tcoords = CNDT.COMMON.standardtcoords,
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