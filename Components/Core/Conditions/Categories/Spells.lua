﻿-- --------------------
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

Env.GetSpellCooldown = GetSpellCooldown
Env.GetItemCooldown = GetItemCooldown


local GetSpellCooldown = GetSpellCooldown
function Env.CooldownDuration(spell, gcdAsUnusable)
	if spell == "gcd" then
		local start, duration = GetSpellCooldown(TMW.GCDSpell)
		return duration == 0 and 0 or (duration - (TMW.time - start))
	end

	local start, duration = GetSpellCooldown(spell)
	if duration then
		return ((duration == 0 or (not gcdAsUnusable and OnGCD(duration))) and 0) or (duration - (TMW.time - start))
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
	funcstr = [[CooldownDuration(c.NameFirst, c.Checked) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE")
	end,
	anticipate = [[
		local start, duration = GetSpellCooldown(c.GCDReplacedNameFirst)
		local VALUE = duration and start + (duration - c.Level) or huge
	]],
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
	funcstr = [[CooldownDuration(c.NameFirst, c.Checked) c.Operator CooldownDuration(c.NameFirst2, c.Checked2)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE")
	end,
	-- what a shitty anticipate func
	anticipate = [[
		local start, duration = GetSpellCooldown(c.GCDReplacedNameFirst)
		local start2, duration2 = GetSpellCooldown(c.GCDReplacedNameFirst2)
		local VALUE
		if duration and duration2 then
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

ConditionCategory:RegisterSpacer(2.4)

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

			module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",
			function()
				local _, e, _, sourceGuid, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
				if e == "SPELL_CAST_SUCCESS" and sourceGuid == pGUID then
					Env.LastPlayerCastName = strlower(spellName)
					TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
				end
			end)
		end

		if c.Level == 1 then
			return [[LastPlayerCastName ~= LOWER(c.NameString)]]
		end
		return [[LastPlayerCastName == LOWER(c.NameString)]]
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

local IsUsableSpell = IsUsableSpell
function Env.ReactiveHelper(NameFirst, Checked)
	local usable, nomana = IsUsableSpell(NameFirst)
	if Checked then
		return usable or nomana
	else
		return usable
	end
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
	funcstr = [[BOOLCHECK( ReactiveHelper(c.NameFirst, c.Checked) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE")
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
		IsCurrentSpell = IsCurrentSpell,
	},
	funcstr = [[BOOLCHECK( IsCurrentSpell(c.NameFirst) )]],
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
		IsAutoRepeatSpell = IsAutoRepeatSpell,
	},
	funcstr = [[BOOLCHECK( IsAutoRepeatSpell(c.NameFirst) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("START_AUTOREPEAT_SPELL"),
			ConditionObject:GenerateNormalEventString("STOP_AUTOREPEAT_SPELL")
	end,
})


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
	icon = "Interface\\Icons\\inv_potion_72",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[not BOOLCHECK( SpellHasNoMana(c.NameFirst) )]],
	Env = {
		SpellHasNoMana = TMW.SpellHasNoMana
	},
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE"),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player")
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
	icon = "Interface\\Icons\\inv_potion_74",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[(GetSpellCost(c.NameFirst) or 0) c.Operator c.Level]],
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
	useSUG = true,
	nooperator = true,
	texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
	icon = "Interface\\Icons\\ability_hunter_snipershot",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsSpellInRange = LibStub("SpellRange-1.0").IsSpellInRange,
	},
	funcstr = function(c)
		return 1-c.Level .. [[ == (IsSpellInRange(c.NameFirst, c.Unit) or 0)]]
	end,
})
ConditionCategory:RegisterCondition(6,	 "GCD", {
	text = L["GCD_ACTIVE"],
	bool = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_fire_flamebolt",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[BOOLCHECK( (TMW.GCD > 0 and TMW.GCD < 1.7) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE")
	end,
	anticipate = [[
		local start, duration = GetSpellCooldown(TMW.GCDSpell)
		local VALUE = start + duration -- the time at which we need to update again. (when the GCD ends)
	]],
})

ConditionCategory:RegisterSpacer(10)

local GetItemCooldown = GetItemCooldown
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
		local start, duration = c.Item:GetCooldown()
		local VALUE = duration and start + (duration - c.Level) or huge
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
	-- what a shitty anticipate func
	anticipate = [[
		local start, duration = c.Item:GetCooldown()
		local start2, duration2 = c.Item2:GetCooldown()
		local VALUE
		if duration and duration2 then
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

function Env.TotemHelper(slot, nameString)
	local have, name, start, duration = GetTotemInfo(slot)
	if nameString and nameString ~= "" and nameString ~= ";" and name and not strfind(nameString, Env.SemicolonConcatCache[name or ""]) then
		return 0
	end
	return duration and duration ~= 0 and (duration - (TMW.time - start)) or 0
end

function Env.TotemHelperAny(nameString)
	for slot = 1, 10 do
		local have, name, start, duration = GetTotemInfo(slot)
		if have == nil then
			return 0 -- `have` will be nil if the slot doesn't exist.
		end

		if
			have and (
				-- If we're not filtering by name,
				(not nameString or nameString == "" or nameString == ";")
				-- Or we are filtering by name and the name matches
				or (name and strfind(nameString, Env.SemicolonConcatCache[name]))
			)
		then
			-- Then return the time of this totem as the result.
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
	useSUG = true,
	allowMultipleSUGEntires = true,
	formatter = TMW.C.Formatter.TIME_0ABSENT,
	icon = "Interface\\ICONS\\spell_nature_brilliance",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[TotemHelperAny(c.NameStrings) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
	end,
	anticipate = function(c)
		return [[local VALUE = time + TotemHelperAny(c.NameStrings) - c.Level]]
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
		useSUG = true,
		allowMultipleSUGEntires = true,
		formatter = TMW.C.Formatter.TIME_0ABSENT,
		icon = totem and totem.texture or "Interface\\ICONS\\ability_shaman_tranquilmindtotem",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = [[TotemHelper(]] .. i .. ((not totem or totem.hasVariableNames) and [[, c.NameString]] or "") .. [[) c.Operator c.Level]],
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
	local name = UnitCastingInfo(unit)
	if not name then
		name = UnitChannelInfo(unit)
	end
	name = strlowerCache[name]
	if matchname == "" and name then
		matchname = name
	end
	if level == 0 or level == 1 then -- present
		return name == matchname
	else -- absent
		return name ~= matchname
	end
end
Env.UnitCastTime = function(unit, level, matchname)
	local name, _, _, _, endTime = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, endTime = UnitChannelInfo(unit)
	end
	name = strlowerCache[name]
	if matchname == "" and name then
		matchname = name
	end
	local remaining = endTime and endTime/1000 - TMW.time or 0
	if level == 0 or level == 1 then -- present
		return name == matchname and remaining or 0
	else -- absent
		return name ~= matchname and remaining or 0
	end
end
ConditionCategory:RegisterCondition(31,	 "CASTING", {
	text = L["ICONMENU_CAST"],
	min = 1,
	max = 2,
	levelChecks = true,
	nooperator = true,
	texttable = {
		-- [0] = L["CONDITIONPANEL_INTERRUPTIBLE"],
		[1] = L["ICONMENU_PRESENT"],
		[2] = L["ICONMENU_ABSENT"],
	},
	icon = "Interface\\Icons\\Temp",
	tcoords = CNDT.COMMON.standardtcoords,
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_CASTTOMATCH"], L["CONDITIONPANEL_CASTTOMATCH_DESC"])
		editbox:SetLabel(L["CONDITIONPANEL_CASTTOMATCH"])
	end,
	useSUG = true,
	funcstr = [[UnitCast(c.Unit, c.Level, LOWER(c.NameString))]], -- LOWER is some gsub magic
	events = function(ConditionObject, c)
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
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_STOP", CNDT:GetUnit(c.Unit))
	end,
})





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
		
		-- castsForGUID[spellName] = spellID
		castsForGUID[spellName] = (castsForGUID[spellName] or 0) + 1
		TMW:Fire("TMW_CNDT_CASTCOUNT_UPDATE")
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
		
		-- if not isNumber[spell] then
		-- 	spell = casts[spell] or spell -- spell name keys have values that are spellIDs
		-- end
		return casts[spell] or 0
	end
	
	return Env.UnitCastCount(...)
end
ConditionCategory:RegisterCondition(32,	 "CASTCOUNT", {
	text = L["CONDITIONPANEL_CASTCOUNT"],
	tooltip = L["CONDITIONPANEL_CASTCOUNT_DESC"],
	range = 10,
	icon = "Interface\\Icons\\Temp",
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
	end,
	useSUG = true,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function()
		 -- attempt initialization if it hasn't been done already
		Env.UnitCastCount("none", "none")
		
		return [[UnitCastCount(c.Unit, c.NameFirst) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("TMW_CNDT_CASTCOUNT_UPDATE")
	end,
})
