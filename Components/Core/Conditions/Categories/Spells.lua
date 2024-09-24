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
local get = TMW.get

local _, pclass = UnitClass("player")

local CNDT = TMW.CNDT
local Env = CNDT.Env

local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache
local OnGCD = TMW.OnGCD

local GetTotemInfo = GetTotemInfo
local UnitGUID = UnitGUID
local max, strfind, format = max, strfind, format
local bit_band = bit.band

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER

local GetSpellCooldown = TMW.COMMON.Cooldowns.GetSpellCooldown
local GetSpellCharges = TMW.COMMON.Cooldowns.GetSpellCharges
local GetSpellCastCount = TMW.COMMON.Cooldowns.GetSpellCastCount
Env.GetSpellCooldown = GetSpellCooldown
Env.GetSpellCharges = GetSpellCharges
Env.GetSpellCastCount = GetSpellCastCount

local GetSpellName = TMW.GetSpellName
local GetSpellInfo = TMW.GetSpellInfo

local GetItemCooldown = GetItemCooldown or (C_Item and C_Item.GetItemCooldown) or (C_Container and C_Container.GetItemCooldown)

function Env.CooldownDuration(spell, gcdAsUnusable)
	if spell == "gcd" then
		local cooldown = GetSpellCooldown(TMW.GCDSpell)
		local duration = cooldown.duration
		return duration == 0 and 0 or ((duration - (TMW.time - cooldown.startTime)) / cooldown.modRate)
	end

	local cooldown = GetSpellCooldown(spell)
	if cooldown then
		local duration = cooldown.duration
		return 
			((duration == 0 or (not gcdAsUnusable and OnGCD(duration))) and 0) or 
			((duration - (TMW.time - cooldown.startTime)) / cooldown.modRate)
	end
	return 0
end

function Env.RechargeDuration(spell)
	local charges = GetSpellCharges(spell)
	if charges and charges.currentCharges ~= charges.maxCharges then
		local duration = charges.cooldownDuration
		return (duration == 0 and 0) or ((duration - (TMW.time - charges.cooldownStartTime)) / charges.chargeModRate)
	end
	return 0
end

local SwingTimers = TMW.COMMON.SwingTimerMonitor.SwingTimers
function Env.SwingDuration(slot)
	local SwingTimer = SwingTimers[slot]
	
	if SwingTimer then
		return max(SwingTimer.duration - (TMW.time - SwingTimer.startTime), 0)
	end
	return 0
end
function Env.SwingInfo(slot)
	local SwingTimer = SwingTimers[slot]
	if SwingTimer then
		return SwingTimer.startTime, SwingTimer.duration
	end
	return nil, nil
end

local ConditionCategory = CNDT:GetCategory("SPELLSABILITIES", 4, L["CNDTCAT_SPELLSABILITIES"], true, false)

ConditionCategory:RegisterCondition(1,	 "SPELLCD", {
	text = L["SPELLCOOLDOWN"],
	min = 0,
	range = 30,
	step = 0.1,
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
	end,
	check = function(check)
		check:SetTexts(L["ICONMENU_GCDASUNUSABLE"], L["ICONMENU_GCDASUNUSABLE_DESC"])
	end,
	useSUG = "spellWithGCD",
	unit = PLAYER,
	formatter = TMW.C.Formatter.TIME_0USABLE,
	icon = "Interface\\Icons\\spell_holy_divineintervention",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[CooldownDuration(c.OwnSpells.First, c.Checked) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_COOLDOWN")
	end,
	anticipate = function(c)
		local str = [[
			local cooldown = GetSpellCooldown(c.OwnSpells.First)
			local VALUE = cooldown and cooldown.startTime + (cooldown.duration - (c.Level*cooldown.modRate)) or huge
		]]
		if TMW:GetSpells(c.Name).First == "gcd" then
			str = str:gsub("c.OwnSpells.First", TMW.GCDSpell)
		end
		return str
	end,
})
ConditionCategory:RegisterCondition(2,	 "SPELLCDCOMP", {
	text = L["SPELLCOOLDOWN"] .. " - " .. L["COMPARISON"],
	noslide = true,
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCOMP1"], L["CNDT_ONLYFIRST"])
	end,
	check = function(check)
		check:SetTexts(L["ICONMENU_GCDASUNUSABLE"], L["ICONMENU_GCDASUNUSABLE_DESC"])
	end,
	name2 = function(editbox)
		editbox:SetTexts(L["SPELLTOCOMP2"], L["CNDT_ONLYFIRST"])
	end,
	check2 = function(check)
		check:SetTexts(L["ICONMENU_GCDASUNUSABLE"], L["ICONMENU_GCDASUNUSABLE_DESC"])
	end,
	useSUG = "spellWithGCD",
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_holy_divineintervention",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[CooldownDuration(c.OwnSpells.First, c.Checked) c.Operator CooldownDuration(c.OwnSpells2.First, c.Checked2)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_COOLDOWN")
	end,
	anticipate = function(c)
		local str = [[
			local cooldown = GetSpellCooldown(c.OwnSpells.First)
			local cooldown2 = GetSpellCooldown(c.OwnSpells2.First)
			local duration = cooldown and cooldown.duration
			local duration2 = cooldown2 and cooldown2.duration
			local VALUE
			if duration and duration2 then
				local v1, v2 = cooldown.startTime + duration, cooldown2.startTime + duration2
				VALUE = v1 < v2 and v1 or v2
			elseif duration then
				VALUE = cooldown.startTime + duration
			elseif duration2 then
				VALUE = cooldown2.startTime + duration2
			else
				VALUE = huge
			end
		]]
		if TMW:GetSpells(c.Name).First == "gcd" then
			str = str:gsub("c.OwnSpells.First", TMW.GCDSpell)
		end
		if TMW:GetSpells(c.Name2).First == "gcd" then
			str = str:gsub("c.OwnSpells2.First", TMW.GCDSpell)
		end
		return str
	end,
})

ConditionCategory:RegisterSpacer(2.4)

if TMW.isRetail then
	ConditionCategory:RegisterCondition(2.5, "SPELLCHARGES", {
		text = L["SPELLCHARGES"],
		tooltip = L["SPELLCHARGES_DESC"],
		min = 0,
		range = 5,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = "spell",
		unit = PLAYER,
		icon = "Interface\\Icons\\ability_monk_roll",
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			GetSpellChargesOrCount = function(spell)
				local charges = GetSpellCharges(spell)
				if charges then return charges.currentCharges end
				return GetSpellCastCount(spell)
			end,
		},
		funcstr = [[(GetSpellChargesOrCount(c.OwnSpells.First)) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_CHARGES"),
				ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_COUNT")
		end,	
	})
	ConditionCategory:RegisterCondition(2.6, "SPELLCHARGETIME", {
		text = L["SPELLCHARGETIME"],
		tooltip = L["SPELLCHARGETIME_DESC"],
		min = 0,
		range = 30,
		step = 0.1,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = "spell",
		unit = PLAYER,
		formatter = TMW.C.Formatter:New(function(value)
			local s = TMW.C.Formatter.TIME_YDHMS:Format(value)
			if value == 0 then
				s = s .. " ("..L["SPELLCHARGES_FULLYCHARGED"]..")"
			end
			return s
		end),
		icon = "Interface\\Icons\\ability_warlock_handofguldan",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = [[RechargeDuration(c.OwnSpells.First) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_CHARGES")
		end,
		anticipate = [[
			local data = GetSpellCharges(c.OwnSpells.First)
			local VALUE = data and data.cooldownDuration and data.cooldownStartTime + (data.cooldownDuration - (c.Level*data.chargeModRate)) or huge
		]],
	})
end

ConditionCategory:RegisterSpacer(2.7)

ConditionCategory:RegisterCondition(2.8, "LASTCAST", {
	text = L["CONDITIONPANEL_LASTCAST"],
	bool = true,
	nooperator = true,
	unit = PLAYER,
	texttable = {
		[0] = L["CONDITIONPANEL_LASTCAST_ISSPELL"],
		[1] = L["CONDITIONPANEL_LASTCAST_ISNTSPELL"],
	},
	icon = "Interface\\Icons\\Temp",
	tcoords = CNDT.COMMON.standardtcoords,
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
	end,
	useSUG = true,
	funcstr = function(c)
		local module = CNDT:GetModule("LASTCAST", true)
		if not module then
			module = CNDT:NewModule("LASTCAST", "AceEvent-3.0")

			local pGUID = UnitGUID("player")
			assert(pGUID, "pGUID was null when func string was generated!")

			local blacklist = {
				[204255] = true, -- Soul Fragment (happens after casting Sheer for DH tanks)
				[324260] = true -- Sinful Revelation (https://github.com/ascott18/TellMeWhen/issues/1831)
			}

			module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",
			function()
				local _, e, _, sourceGuid, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
				if e == "SPELL_CAST_SUCCESS" and sourceGuid == pGUID and not blacklist[spellID] then
					Env.LastPlayerCastName = strlower(spellName)
					Env.LastPlayerCastID = spellID
					TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
				end
			end)

			-- Spells that don't work with CLEU and must be tracked with USS.
			local ussSpells = {
				[189110] = true, -- Infernal Strike (DH)
				[189111] = true, -- Infernal Strike (DH)
				[195072] = true, -- Fel Rush (DH)
			}
			module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",
			function(_, unit, _, spellID)
				if unit == "player" and ussSpells[spellID] and not blacklist[spellID] then
					Env.LastPlayerCastName = strlower(GetSpellName(spellID))
					Env.LastPlayerCastID = spellID
					TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
				end
			end)
		end

		if c.Level == 1 then
			return [[LastPlayerCastName ~= LOWER(c.Spells.First) and LastPlayerCastID ~= c.Spells.First]] 
		end
		return [[LastPlayerCastName == LOWER(c.Spells.First) or LastPlayerCastID == c.Spells.First]] 
	end,
	events = function(ConditionObject, c)
		local pGUID = UnitGUID("player")
		assert(pGUID, "pGUID was null when event string was generated!")
		
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit("player")),
			ConditionObject:GenerateNormalEventString("TMW_CNDT_LASTCAST_UPDATED")
	end,
})

ConditionCategory:RegisterSpacer(2.9)

local IsUsableSpell = TMW.COMMON.SpellUsable.IsUsableSpell
function Env.ReactiveHelper(NameFirst, Checked)
	local usable, noMana = IsUsableSpell(NameFirst)
	if Checked then
		return usable or noMana
	else
		return usable
	end
end

ConditionCategory:RegisterCondition(2.95, "SPELL_LEARNED", {
	text = L["SPELL_LEARNED"],
	tooltip = L["SPELL_LEARNED_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["SPELL_LEARNED"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	unit = false,
	formatter = TMW.C.Formatter.BOOL,
	icon = 237558,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellName = TMW.GetSpellName
	},
	-- In Classic SoD, IsPlayerSpell doesn't work for rune abilities (always returns false).
	-- However, GetSpellInfo with a name input only returns the player's spells.
	funcstr = [[BOOLCHECK( GetSpellName(c.Spells.FirstString) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELLS_CHANGED")
	end,
})

if C_Spell.GetOverrideSpell then
ConditionCategory:RegisterCondition(2.97, "SPELL_OVERRIDE", {
	text = L["SPELL_OVERRIDE"],
	tooltip = L["SPELL_OVERRIDE_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["SPELL_OVERRIDE_BASE"], L["CNDT_ONLYFIRST"])
	end,
	name2 = function(editbox)
		editbox:SetTexts(L["SPELL_OVERRIDE_TARGET"], L["CNDT_ONLYFIRST"])
	end,
	useSUG = true,
	unit = false,
	formatter = TMW.C.Formatter.BOOL,
	icon = 1112939,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetOverrideSpell = C_Spell.GetOverrideSpell,
		GetSpellName = TMW.GetSpellName
	},
	funcstr = function(c)
		if isNumber[c.Name2] then
			return [[BOOLCHECK( GetOverrideSpell(c.Spells.First) == c.Spells2.First )]]
		else
			return [[BOOLCHECK( strlowerCache[GetSpellName(GetOverrideSpell(c.Spells.First) or "")] == c.Spells2.First )]]
		end
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELLS_CHANGED")
	end,
})
end

ConditionCategory:RegisterCondition(3,	 "REACTIVE", {
	text = L["SPELLREACTIVITY"],
	tooltip = L["REACTIVECNDT_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["ICONMENU_REACTIVE"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	check = function(check)
		check:SetTexts(L["ICONMENU_IGNORENOMANA"], L["ICONMENU_IGNORENOMANA_DESC"])
	end,
	useSUG = true,
	unit = false,
	formatter = TMW.C.Formatter.BOOL_USABLEUNUSABLE,
	icon = "Interface\\Icons\\ability_warrior_revenge",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[BOOLCHECK( ReactiveHelper(c.OwnSpells.First, c.Checked) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_USABLE")
	end,
})
ConditionCategory:RegisterCondition(3.1, "CURRENTSPELL", {
	text = L["CONDITIONPANEL_CURRENTSPELL"],
	tooltip = L["CONDITIONPANEL_CURRENTSPELL_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	unit = false,
	formatter = TMW.C.Formatter.BOOL,
	icon = "Interface\\Icons\\ability_rogue_ambush",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell or IsCurrentSpell,
	},
	funcstr = [[BOOLCHECK( IsCurrentSpell(c.OwnSpells.First) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("CURRENT_SPELL_CAST_CHANGED")
	end,
})
ConditionCategory:RegisterCondition(3.2, "AUTOSPELL", {
	text = L["CONDITIONPANEL_AUTOSPELL"],
	tooltip = L["CONDITIONPANEL_AUTOSPELL_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	unit = false,
	formatter = TMW.C.Formatter.BOOL,
	icon = 135467,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsAutoRepeatSpell = C_Spell and C_Spell.IsAutoRepeatSpell or IsAutoRepeatSpell,
	},
	funcstr = [[BOOLCHECK( IsAutoRepeatSpell(c.OwnSpells.First) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("START_AUTOREPEAT_SPELL"),
			ConditionObject:GenerateNormalEventString("STOP_AUTOREPEAT_SPELL")
	end,
})

if IsSpellOverlayed then
ConditionCategory:RegisterCondition(3.5,  "OVERLAYED", {
	text = L["CONDITIONPANEL_OVERLAYED"],
	tooltip = L["CONDITIONPANEL_OVERLAYED_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_OVERLAYED"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	unit = false,
	icon = "Interface\\Icons\\inv_shield_05",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsSpellOverlayed = IsSpellOverlayed,
		OverlayedNameMap = {}
	},
	funcstr = function(c)
		local module = CNDT:GetModule("OVERLAYED", true)
		if not module then
			module = CNDT:NewModule("OVERLAYED", "AceEvent-3.0")

			local function handleEvent(event, arg1)
				Env.OverlayedNameMap[strlowerCache[GetSpellName(arg1)]] = arg1
			end

			module:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", handleEvent)
			module:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", handleEvent)
		end

		return [[BOOLCHECK( IsSpellOverlayed(OverlayedNameMap[c.Spells.First] or (isNumber[c.Spells.First] and c.Spells.First) or 0) )]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE"),
			ConditionObject:GenerateNormalEventString("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"),
			ConditionObject:GenerateNormalEventString("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	end,
})
end

ConditionCategory:RegisterCondition(4,	 "MANAUSABLE", {
	text = L["CONDITIONPANEL_MANAUSABLE"],
	tooltip = L["CONDITIONPANEL_MANAUSABLE_DESC"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_MANAUSABLE"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	unit = false,
	formatter = TMW.C.Formatter.BOOL_USABLEUNUSABLE,
	icon = "Interface\\Icons\\inv_potion_137",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[not BOOLCHECK( SpellHasNoMana(c.OwnSpells.First) )]],
	Env = {
		SpellHasNoMana = function(spell)
			local _, noMana = IsUsableSpell(spell)
			return noMana
		end
	},
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_USABLE")
	end,
})
ConditionCategory:RegisterCondition(4.5, "SPELLCOST", {
	text = L["CONDITIONPANEL_SPELLCOST"],
	tooltip = L["CONDITIONPANEL_SPELLCOST_DESC"],

	min = 0,
	range = 200,
	
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_SPELLCOST"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	unit = false,
	icon = "Interface\\Icons\\inv_potion_125",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[(GetSpellCost(c.OwnSpells.First) or 0) c.Operator c.Level]],
	Env = {
		GetSpellCost = TMW.GetSpellCost
	},
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE")
	end,
})
ConditionCategory:RegisterCondition(5,	 "SPELLRANGE", {
	text = L["CONDITIONPANEL_SPELLRANGE"],
	bool = true,
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_SPELLRANGE"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	defaultUnit = "target",
	useSUG = true,
	nooperator = true,
	texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
	icon = "Interface\\Icons\\ability_hunter_snipershot",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsSpellInRange = TMW.COMMON.SpellRange.IsSpellInRange,
	},
	funcstr = function(c)
		return [[BOOLCHECK( IsSpellInRange(c.OwnSpells.First, c.Unit) )]]
	end,
	events = function(ConditionObject, c)
		local SpellRange = TMW.COMMON.SpellRange
		local spells = TMW:GetSpells(c.Name, true)
		
		if c.Unit == "target" and SpellRange.HasRangeEvents(spells.First) then
			return ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_RANGE")
		end
		return nil
	end,
})
ConditionCategory:RegisterCondition(6,	 "GCD", {
	text = L["GCD_ACTIVE"],
	bool = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_hunter_steadyshot",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[BOOLCHECK( (TMW.GetGCD() > 0 and TMW.GetGCD() < 1.7) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_SPELL_UPDATE_COOLDOWN")
	end,
	anticipate = [[
		local cooldown = GetSpellCooldown(TMW.GCDSpell)
		local VALUE = cooldown.startTime + cooldown.duration -- the time at which we need to update again. (when the GCD ends)
	]],
})

ConditionCategory:RegisterSpacer(10)

function Env.ItemCooldownDuration(itemID)
	local start, duration = GetItemCooldown(itemID)
	if duration then
		return ((duration == 0 or OnGCD(duration)) and 0) or (duration - (TMW.time - start))
	end
	return 0
end

ConditionCategory:RegisterCondition(11,	 "ITEMCD", {
	text = L["ITEMCOOLDOWN"],
	range = 30,
	step = 0.1,
	name = function(editbox)
		editbox:SetTexts(L["ITEMCOOLDOWN"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["ITEMTOCHECK"])
	end,
	useSUG = "itemwithslots",
	unit = PLAYER,
	formatter = TMW.C.Formatter.TIME_0USABLE,
	icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[c.Item:GetCooldownDurationNoGCD() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE_COOLDOWN")
	end,
	anticipate = [[
		local start, duration, enable = c.Item:GetCooldown()
		local VALUE = (enable == 1 or enable == true) and duration and start + (duration - c.Level) or huge
	]],
})
ConditionCategory:RegisterCondition(12,	 "ITEMCDCOMP", {
	text = L["ITEMCOOLDOWN"] .. " - " .. L["COMPARISON"],
	noslide = true,
	name = function(editbox)
		editbox:SetTexts(L["ITEMTOCOMP1"], L["CNDT_ONLYFIRST"])
	end,
	name2 = function(editbox)
		editbox:SetTexts(L["ITEMTOCOMP2"], L["CNDT_ONLYFIRST"])
	end,
	useSUG = "itemwithslots",
	unit = PLAYER,
	icon = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[c.Item:GetCooldownDurationNoGCD() c.Operator c.Item2:GetCooldownDurationNoGCD()]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE_COOLDOWN")
	end,
	anticipate = [[
		local start, duration, enable = c.Item:GetCooldown()
		local start2, duration2, enable2 = c.Item2:GetCooldown()
		local VALUE
		if enable == 0 or enable == false or enable2 == 0 or enable2 == false then
			VALUE = huge
		elseif duration and duration2 then
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
})
ConditionCategory:RegisterCondition(13,	 "ITEMRANGE", {
	text = L["CONDITIONPANEL_ITEMRANGE"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_ITEMRANGE"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["ITEMTOCHECK"])
	end,
	useSUG = "itemwithslots",
	nooperator = true,
	texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
	icon = "Interface\\Icons\\ability_hunter_snipershot",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[ BOOLCHECK( c.Item:IsInRange(c.Unit) ) ]]
	end,
	-- events = absolutely none
})
ConditionCategory:RegisterCondition(14,	 "ITEMINBAGS", {
	text = L["ITEMINBAGS"],
	min = 0,
	range = 25,
	step = 0.1,
	name = function(editbox)
		editbox:SetTexts(L["ITEMINBAGS"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["ITEMTOCHECK"])
	end,
	useSUG = "itemwithslots",
	unit = false,
	icon = "Interface\\Icons\\inv_misc_bag_08",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[c.Item:GetCount() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player"),

			-- apparently, using a charge of a healthstone doesn't fire either of the other two events.
			-- BAG_UPDATE_COOLDOWN fires way too often for my liking, but I guess we don't have a choice.
			ConditionObject:GenerateNormalEventString("BAG_UPDATE_COOLDOWN") 
	end,
})
ConditionCategory:RegisterCondition(15,	 "ITEMEQUIPPED", {
	text = L["ITEMEQUIPPED"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["ITEMEQUIPPED"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["ITEMTOCHECK"])
	end,
	useSUG = "itemwithslots",
	unit = false,
	icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[BOOLCHECK( c.Item:GetEquipped() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
	end,
})
ConditionCategory:RegisterCondition(16,	 "ITEMSPELL", {
	text = L["ITEMSPELL"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["ITEMSPELL"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["ITEMTOCHECK"])
	end,
	useSUG = "itemwithslots",
	unit = false,
	icon = "Interface\\Icons\\inv_misc_bone_elfskull_01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[BOOLCHECK( c.Item:HasUseEffect() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
	end,
})


ConditionCategory:RegisterSpacer(18)


ConditionCategory:RegisterCondition(19,	 "MHSWING", {
	text = L["SWINGTIMER"] .. " - " .. INVTYPE_WEAPONMAINHAND,
	min = 0,
	range = 3,
	step = 0.1,
	unit = PLAYER,
	formatter = TMW.C.Formatter.TIME_0USABLE,
	icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_14" end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[SwingDuration(]] .. GetInventorySlotInfo("MainHandSlot") .. [[) c.Operator c.Level]],
	events = function(ConditionObject, c)
		ConditionObject:RequestEvent("TMW_COMMON_SWINGTIMER_CHANGED")
		ConditionObject:SetNumEventArgs(1)
		
		return
			"event == 'TMW_COMMON_SWINGTIMER_CHANGED' and arg1.slot == " .. GetInventorySlotInfo("MainHandSlot")
	end,
	hidden = not TMW.COMMON.SwingTimerMonitor,
	anticipate = [[
		local start, duration = SwingInfo(]] .. GetInventorySlotInfo("MainHandSlot") .. [[)
		local VALUE = duration and start + (duration - c.Level) or huge
	]],
})
ConditionCategory:RegisterCondition(19.5,	 "OHSWING", {
	text = L["SWINGTIMER"] .. " - " .. INVTYPE_WEAPONOFFHAND,
	min = 0,
	range = 3,
	step = 0.1,
	unit = PLAYER,
	formatter = TMW.C.Formatter.TIME_0USABLE,
	icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_15" end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[SwingDuration(]] .. GetInventorySlotInfo("SecondaryHandSlot") .. [[) c.Operator c.Level]],
	events = function(ConditionObject, c)
		ConditionObject:RequestEvent("TMW_COMMON_SWINGTIMER_CHANGED")
		ConditionObject:SetNumEventArgs(1)
		
		return
			"event == 'TMW_COMMON_SWINGTIMER_CHANGED' and arg1.slot == " .. GetInventorySlotInfo("SecondaryHandSlot")
	end,
	hidden = not TMW.COMMON.SwingTimerMonitor,
	anticipate = [[
		local start, duration = SwingInfo(]] .. GetInventorySlotInfo("SecondaryHandSlot") .. [[)
		local VALUE = duration and start + (duration - c.Level) or huge
	]],
})


ConditionCategory:RegisterSpacer(20)

local totemData = TMW.COMMON.CurrentClassTotems
local totemRanks = TMW.COMMON.TotemRanks or {}

function Env.TotemHelper(slot, spellSet)
	local _, totemName, start, duration = GetTotemInfo(slot)
	local totemNameLower = strlowerCache[totemName]
	local totemInfo = totemRanks[totemNameLower]

	local matchAny = not spellSet or spellSet.Name == ""
	local Hash = not matchAny and spellSet.Hash
	
	if
		start ~= 0 and
		totemName and
		(
			matchAny or
			Hash[totemNameLower] or
			(totemInfo and (
				-- By totem name, (e.g. "Searing Totem III")
				Hash[totemInfo.totemNameLower] or
				-- or by spellID,
				Hash[totemInfo.spellID] or
				-- Or by the spell name (which is the same as the rank 1 totem name) (e.g. "Searing Totem")
				Hash[totemInfo.spellNameLower])
			)
		)
	then
		return duration and duration ~= 0 and (duration - (TMW.time - start)) or 0
	end
	return 0
end

function Env.TotemHelperAny(spellSet)
	local matchAny = spellSet.Name == ""
	local Hash = not matchAny and spellSet.Hash
	
	for slot = 1, 10 do
		local have, totemName, start, duration = GetTotemInfo(slot)
		if have == nil then
			return 0 -- `have` will be nil if the slot doesn't exist.
		end
		
		local totemNameLower = strlowerCache[totemName]
		local totemInfo = totemRanks[totemNameLower]

		if
			start ~= 0 and
			totemName and
			(
				matchAny or
				Hash[totemNameLower] or
				(totemInfo and (
					-- By totem name, (e.g. "Searing Totem III")
					Hash[totemInfo.totemNameLower] or
					-- or by spellID,
					Hash[totemInfo.spellID] or
					-- Or by the spell name (which is the same as the rank 1 totem name) (e.g. "Searing Totem")
					Hash[totemInfo.spellNameLower])
				)
			)
		then
			return duration and duration ~= 0 and (duration - (TMW.time - start)) or 0
		end
		-- If the above condition didn't succeeed, continue on to the next totem.
	end

	-- No results were found.
	return 0
end



ConditionCategory:RegisterCondition(20.1,	 "TOTEM_ANY", {
	text = L["GENERICTOTEM_ANY"],
	tooltip = L["ICONMENU_TOTEM_DESC"],
	min = 0,
	range = 60,
	unit = false,
	name = function(editbox)
		editbox:SetTexts(L["CNDT_TOTEMNAME"], L["CNDT_TOTEMNAME_DESC"])
		editbox:SetLabel(L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"])
	end,
	useSUG = TMW.COMMON.TotemRanks and "totem" or "spell",
	allowMultipleSUGEntires = true,
	formatter = TMW.C.Formatter.TIME_0ABSENT,
	icon = "Interface\\ICONS\\spell_nature_groundingtotem",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[TotemHelperAny(c.Spells) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
	end,
	anticipate = function(c)
		return [[local VALUE = time + TotemHelperAny(c.Spells) - c.Level]]
	end,
})

for i = 1, 5 do
	local totem = totemData[i]
	ConditionCategory:RegisterCondition(20 + i,	 "TOTEM" .. i, {
		text = totem and totem.name or L["GENERICTOTEM"]:format(i),
		tooltip = totemData.desc or L["ICONMENU_TOTEM_DESC"],
		min = 0,
		range = 60,
		unit = false,
		name = (not totem or totem.hasVariableNames) and function(editbox)
			editbox:SetTexts(L["CNDT_TOTEMNAME"], L["CNDT_TOTEMNAME_DESC"])
			editbox:SetLabel(L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"])
		end,
		useSUG = TMW.COMMON.TotemRanks and "totem" or "spell",
		allowMultipleSUGEntires = true,
		formatter = TMW.C.Formatter.TIME_0ABSENT,
		icon = totem and totem.texture or "Interface\\ICONS\\spell_nature_groundingtotem",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = [[TotemHelper(]] .. i .. ((not totem or totem.hasVariableNames) and [[, c.Spells]] or "") .. [[) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
		end,
		anticipate = function(c)
			return [[local VALUE = time + TotemHelper(]] .. i .. [[) - c.Level]]
		end,
		hidden = not totem,
	})
end


ConditionCategory:RegisterSpacer(30)

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo

Env.UnitCast = function(unit, level, matchname)
	local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
	end
	name = strlowerCache[name]
	if matchname == "" and name then
		matchname = name
	end
	if level == 0 then -- only interruptible
		return not notInterruptible and name == matchname
	elseif level == 1 then -- present
		return name == matchname
	else -- absent
		return name ~= matchname
	end
end

Env.UnitCastTime = function(unit, level, matchname)
	-- This function was added for use in Lua conditions.
	-- There's intentionally no condition using it.
	local name, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, endTime, _, notInterruptible = UnitChannelInfo(unit)
	end
	name = strlowerCache[name]
	if matchname == "" and name then
		matchname = name
	end
	local remaining = endTime and endTime/1000 - TMW.time or 0
	if level == 0 then -- only interruptible
		return not notInterruptible and name == matchname and remaining or 0
	elseif level == 1 then -- present
		return name == matchname and remaining or 0
	else -- absent
		return name ~= matchname and remaining or 0
	end
end

Env.UnitCastPercent = function(unit, matchname)
	local name, _, _, start, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, start, endTime, _, notInterruptible = UnitChannelInfo(unit)
	end
	if not name then 
		return 0, nil
	end
	if matchname ~= "" and strlowerCache[name] ~= matchname then
		return 0, nil
	end
	local remaining = endTime and endTime/1000 - TMW.time or 0
	local duration = endTime/1000 - start/1000
	-- second return value is the percent-per-second, used by anticipate
	return 1 - (remaining / duration), 1 / duration
end

local castEvents = function(ConditionObject, c)
	return
		ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_START", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_STOP", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_SUCCEEDED", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_FAILED", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_FAILED_QUIET", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_DELAYED", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_INTERRUPTED", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_START", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_UPDATE", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_STOP", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_INTERRUPTIBLE", CNDT:GetUnit(c.Unit)),
		ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", CNDT:GetUnit(c.Unit)),
		GetUnitEmpowerStageDuration and ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_EMPOWER_START", CNDT:GetUnit(c.Unit)) or "false",
		GetUnitEmpowerStageDuration and ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_EMPOWER_UPDATE", CNDT:GetUnit(c.Unit)) or "false",
		GetUnitEmpowerStageDuration and ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_EMPOWER_STOP", CNDT:GetUnit(c.Unit)) or "false"
end

ConditionCategory:RegisterCondition(31,	 "CASTING", {
	text = L["ICONMENU_CAST"],
	tooltip = L["ICONMENU_CAST_DESC"],
	min = TMW.isClassic and 1 or 0,
	max = 2,
	levelChecks = true,
	nooperator = true,
	texttable = {
		[0] = L["CONDITIONPANEL_INTERRUPTIBLE"],
		[1] = L["ICONMENU_PRESENT"],
		[2] = L["ICONMENU_ABSENT"],
	},
	icon = "Interface\\Icons\\Temp",
	tcoords = CNDT.COMMON.standardtcoords,
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_CASTTOMATCH"], L["CONDITIONPANEL_CASTTOMATCH_DESC"])
		editbox:SetLabel(L["CONDITIONPANEL_CASTTOMATCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"])
	end,
	useSUG = true,
	funcstr = [[UnitCast(c.Unit, c.Level, c.Spells.FirstString)]],
	events = castEvents,
})

ConditionCategory:RegisterCondition(31.1,	 "CASTPERCENT", {
	text = L["ICONMENU_CAST_PERCENT"],
	tooltip = L["ICONMENU_CAST_PERCENT_DESC"],
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	min = 0,
	max = 100,
	icon = "Interface\\Icons\\Temp",
	tcoords = CNDT.COMMON.standardtcoords,
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_CASTTOMATCH"], L["CONDITIONPANEL_CASTTOMATCH_DESC"])
		editbox:SetLabel(L["CONDITIONPANEL_CASTTOMATCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"])
	end,
	useSUG = true,
	funcstr = [[UnitCastPercent(c.Unit, c.Spells.FirstString) c.Operator c.Level]],
	events = castEvents,
	anticipate = [[
		local percent, percentPerSecond = UnitCastPercent(c.Unit, c.Spells.FirstString)
		local VALUE = 
			percentPerSecond == nil and huge or 
			((c.Level - percent) / percentPerSecond) + time
	]],
})

local GetUnitEmpowerStageDuration = GetUnitEmpowerStageDuration
local GetUnitEmpowerHoldAtMaxTime = GetUnitEmpowerHoldAtMaxTime
if GetUnitEmpowerStageDuration then
	function Env.GetCurrentEmpowerStage(unit, matchname)
		-- all of the function calls in this function combined,
		-- assuming the worst case of current cast is on its last stage,
		-- use less CPU than a single UnitAura call.
		-- So perf here isn't an issue and no caching is needed here.
		local name, _, _, start, _, _, _, _, _, numStages = UnitChannelInfo(unit);

		if not numStages or numStages == 0 or (matchname ~= "" and strlowerCache[name] ~= matchname) then
			return 0, 0
		end

		local stageEnd = start/1000
		local time = TMW.time
		for i = 0, numStages - 1 do
			local duration = GetUnitEmpowerStageDuration(unit, i)
			stageEnd = stageEnd + duration/1000
			if stageEnd > time then
				return i, stageEnd
			end
		end
		return numStages, stageEnd + GetUnitEmpowerHoldAtMaxTime(unit)/1000
	end

	ConditionCategory:RegisterCondition(31.2,  "EMPOWEREDSTAGE", {
		text = L["EMPOWEREDSTAGE"],
		tooltip = L["EMPOWEREDSTAGE_DESC"],
		useSUG = "spell",	
		name = function(editbox)
			editbox:SetTexts(L["CONDITIONPANEL_CASTTOMATCH"], L["CONDITIONPANEL_CASTTOMATCH_DESC"])
			editbox:SetLabel(L["CONDITIONPANEL_CASTTOMATCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"])
		end,
		min = 0,
		max = 5,
		icon = "Interface\\Icons\\inv_10_enchanting2_elementalswirl_color1",

		tcoords = CNDT.COMMON.standardtcoords,

		funcstr = [[GetCurrentEmpowerStage(c.Unit, c.Spells.FirstString) c.Operator c.Level]],
		anticipate = [[
			-- Doesn't anticpiate the specific stage we're looking for.
			-- Only the next stage change. Which is plenty good enough.
			local _, VALUE = GetCurrentEmpowerStage(c.Unit, c.Spells.FirstString)
		]],

		events = function(ConditionObject, c)
			return
				ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_EMPOWER_START", CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_EMPOWER_UPDATE", CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_EMPOWER_STOP", CNDT:GetUnit(c.Unit))
		end,
	})
end




local CastCounts
local function CASTCOUNT_COMBAT_LOG_EVENT_UNFILTERED()
	local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()
	if cleuEvent == "SPELL_CAST_SUCCESS" then
		spellName = spellName and strlowerCache[spellName]
		local castsForGUID = CastCounts[sourceGUID]
		
		if not castsForGUID then
			castsForGUID = {}
			CastCounts[sourceGUID] = castsForGUID
		end
		
		castsForGUID[spellName] = spellID
		castsForGUID[spellID] = (castsForGUID[spellID] or 0) + 1
		TMW:Fire("TMW_CNDT_CASTCOUNT_UPDATE")
	
	elseif cleuEvent == "UNIT_DIED" then
		if destFlags then
			if bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER then
				CastCounts[destGUID] = nil
				TMW:Fire("TMW_CNDT_CASTCOUNT_UPDATE")
			end
		end
	end
end
function Env.UnitCastCount(...)
	CastCounts = {}
	CNDT.CastCounts = CastCounts
	CNDT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", CASTCOUNT_COMBAT_LOG_EVENT_UNFILTERED)
	
	Env.UnitCastCount = function(unit, spell)
		local GUID = UnitGUID(unit)
		if not GUID then
			return 0
		end
		
		local casts = CastCounts[GUID]
		
		if not casts then
			return 0
		end
		
		if not isNumber[spell] then
			spell = casts[spell] or spell -- spell name keys have values that are spellIDs
		end
		return casts[spell] or 0
	end
	
	return Env.UnitCastCount(...)
end
ConditionCategory:RegisterCondition(32,	 "CASTCOUNT", {
	text = L["CONDITIONPANEL_CASTCOUNT"],
	tooltip = L["CONDITIONPANEL_CASTCOUNT_DESC"],
	range = 10,
	icon = "Interface\\Icons\\spell_nature_lightningoverload",
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
	end,
	useSUG = true,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function()
		-- attempt initialization if it hasn't been done already
		Env.UnitCastCount("none", "none")
		
		return [[UnitCastCount(c.Unit, c.Spells.First) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("TMW_CNDT_CASTCOUNT_UPDATE")
	end,
})