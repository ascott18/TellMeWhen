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

ConditionCategory:RegisterCondition(1,	 "HEALTH", {
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
ConditionCategory:RegisterCondition(2,	 "DEFAULT", {
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
ConditionCategory:RegisterCondition(3,	 "MANA", {
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
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(4,	 "ENERGY", {
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
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(5,	 "RAGE", {
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
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(6,	 "FOCUS", {
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
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(7,	 "RUNIC_POWER", {
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
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_MAXPOWER", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(8,	 "ALTPOWER", {
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
	midt = true,
	texttable = setmetatable({
		[-100] = "-100 (" .. L["MOON"] .. ")",
		[100] = "100 (" .. L["SUN"] .. ")",
	}, {__index = function(tbl, k) return k end}),

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



ConditionCategory:RegisterCondition(15,	 "RUNES", {
	old = true,
	customDeprecated = true,

	text = RUNES,
	--tooltip = L["CONDITIONPANEL_RUNES_DESC"],
	unit = false,
	nooperator = true,
	noslide = true,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
	Env = {
		GetRuneType = GetRuneType,
		GetRuneCount = GetRuneCount,
	},
	funcstr = function(c) -- sub-constructor function
		-- This condiion is now deprecated. The code to run it is still here because
		-- the new one is quite different, and I can't do an automatic upgrade.
		local str = ""
		if c.Runes then
			for k, v in pairs(c.Runes) do
				if v ~= nil then
					str = str .. "and" .. (v==false and " not" or "")
					if k > 6 then
						k=k-6
						str = str .. [[(GetRuneType(]]..k..[[)==4 and GetRuneCount(]]..k..[[)==1)]]
					else
						if c.Checked then
							str = str .. [[(GetRuneType(]]..k..[[)~=4 and GetRuneCount(]]..k..[[)==1)]]
						else
							str = str .. [[(GetRuneCount(]]..k..[[)==1)]]
						end
					end
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
	if conditionData and conditionData.identifier == "RUNES" then
		local runes = conditionSettings.Runes
		local str = "This condition has been replaced by the Rune Count condition.\n\n" ..
		"This condition will still function as it did, but is no longer configurable. Here is your old configuration:\n\n"
		if runes then
			for k, v in pairs(runes) do
				local slot = k
				local death = ""
				if slot > 6 then
					slot = slot - 6
					death = "Death "
				end
				str = str .. death
				if slot == 1 or slot == 2 then
					str = str .. "Blood " .. slot .. ", "
				elseif slot == 3 or slot == 4 then
					str = str .. "Unholy " .. slot-2 .. ", "
				elseif slot == 5 or slot == 6 then
					str = str .. "Frost " .. slot-4 .. ", "
				end
			end
		else
			str = str .. "<No Runes Selected>"
		end

		CndtGroup.Deprecated:SetFormattedText(str:trim(" ,"))


		if CndtGroup.Deprecated:IsShown() then
			CndtGroup:SetHeight(CndtGroup:GetHeight() - CndtGroup.Deprecated:GetHeight())
			CndtGroup.Deprecated:Hide()
		end
		if not CndtGroup.Deprecated:IsShown() then
			-- Need to reset the height to 0 before calling GetStringHeight
			-- for consistency. Causes weird behavior if we don't do this.
			CndtGroup.Deprecated:SetHeight(0)
			CndtGroup.Deprecated:SetHeight(CndtGroup.Deprecated:GetStringHeight())

			CndtGroup:SetHeight(CndtGroup:GetHeight() + CndtGroup.Deprecated:GetHeight())
			CndtGroup.Deprecated:Show()
		end
	end
end)


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
	max = 6,
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
ConditionCategory:RegisterCondition(15.3, "RUNESLOCK", {
	text = L["CONDITIONPANEL_RUNESLOCK"],
	tooltip = L["CONDITIONPANEL_RUNESLOCK_DESC"] .. "\r\n\r\n" .. L["CONDITIONPANEL_RUNES_DESC_GENERIC"],
	unit = false,
	runesConfig = true,
	min = 0,
	max = 6,
	icon = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy",
	Env = {
		GetRuneType = GetRuneType,
		GetRuneCooldown = GetRuneCooldown,
		IsRuneLocked = IsRuneLocked,
	},
	funcstr = runeFuncstrHelper,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("RUNE_POWER_UPDATE"),
			ConditionObject:GenerateNormalEventString("RUNE_TYPE_UPDATE")
	end,
	hidden = pclass ~= "DEATHKNIGHT",
})



ConditionCategory:RegisterCondition(15.5, "CHI", {
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

ConditionCategory:RegisterCondition(16,	 "COMBO", {
	text = L["CONDITIONPANEL_COMBO"],
	min = 0,
	max = 5,
	unit = TARGET,
	icon = "Interface\\Icons\\ability_rogue_eviscerate",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitPower = UnitPower,
	},
	funcstr = [[UnitPower("player", 4) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_COMBO_POINTS", "player")
	end,
})

ConditionCategory:RegisterCondition(17,	 "SHADOW_ORBS", {
	text = SHADOW_ORBS,
	min = 0,
	max = 5,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Priest_Shadoworbs",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[UnitPower("player", 13) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_POWER", "player")
	end,
	hidden = pclass ~= "PRIEST",
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
	hidden = pclass ~= "WARLOCK",
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
	hidden = pclass ~= "WARLOCK",
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
	hidden = pclass ~= "WARLOCK",
})

ConditionCategory:RegisterSpacer(40)

ConditionCategory:RegisterCondition(41,	 "HEALTH_ABS", {
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
ConditionCategory:RegisterCondition(42,	 "DEFAULT_ABS", {
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
ConditionCategory:RegisterCondition(43,	 "MANA_ABS", {
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
ConditionCategory:RegisterCondition(44,	 "ENERGY_ABS", {
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
ConditionCategory:RegisterCondition(45,	 "RAGE_ABS", {
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
ConditionCategory:RegisterCondition(46,	 "FOCUS_ABS", {
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
ConditionCategory:RegisterCondition(47,	 "RUNIC_POWER_ABS", {
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
ConditionCategory:RegisterCondition(48,	 "ALTPOWER_ABS", {
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

ConditionCategory:RegisterSpacer(60)

ConditionCategory:RegisterCondition(61,	 "HEALTH_MAX", {
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
ConditionCategory:RegisterCondition(62,	 "DEFAULT_MAX", {
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
ConditionCategory:RegisterCondition(63,	 "MANA_MAX", {
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
ConditionCategory:RegisterCondition(64,	 "ENERGY_MAX", {
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
ConditionCategory:RegisterCondition(65,	 "RAGE_MAX", {
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
ConditionCategory:RegisterCondition(66,	 "FOCUS_MAX", {
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
ConditionCategory:RegisterCondition(67,	 "RUNIC_POWER_MAX", {
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
ConditionCategory:RegisterCondition(68,	 "ALTPOWER_MAX", {
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

