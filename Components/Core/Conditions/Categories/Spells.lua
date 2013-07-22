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
function Env.CooldownDuration(spell)
	if spell == "gcd" then
		local start, duration = GetSpellCooldown(TMW.GCDSpell)
		return duration == 0 and 0 or (duration - (TMW.time - start))
	end

	local start, duration = GetSpellCooldown(spell)
	if duration then
		return ((duration == 0 or OnGCD(duration)) and 0) or (duration - (TMW.time - start))
	end
	return 0
end

local GetSpellCharges = GetSpellCharges
function Env.RechargeDuration(spell)
	local charges, maxCharges, start, duration = GetSpellCharges(spell)
	if charges and charges ~= maxCharges then
		return (duration == 0 and 0) or (duration - (TMW.time - start))
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

local ConditionCategory = CNDT:GetCategory("SPELLSABILITIES", 4, L["CNDTCAT_SPELLSABILITIES"], true, false)

ConditionCategory:RegisterCondition(1,	 "SPELLCD", {
	text = L["SPELLCOOLDOWN"],
	range = 30,
	step = 0.1,
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "spellWithGCD",
	unit = PLAYER,
	texttable = CNDT.COMMON.usableseconds,
	icon = "Interface\\Icons\\spell_holy_divineintervention",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[CooldownDuration(c.NameFirst) c.Operator c.Level]],
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
	name = function(editbox) TMW:TT(editbox, "SPELLTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCOMP1"] end,
	name2 = function(editbox) TMW:TT(editbox, "SPELLTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCOMP2"] end,
	useSUG = "spellWithGCD",
	unit = PLAYER,
	icon = "Interface\\Icons\\spell_holy_divineintervention",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[CooldownDuration(c.NameFirst) c.Operator CooldownDuration(c.NameFirst2)]],
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

ConditionCategory:RegisterCondition(2.5, "SPELLCHARGES", {
	text = L["SPELLCHARGES"],
	tooltip = L["SPELLCHARGES_DESC"],
	range = 5,
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "spell",
	unit = PLAYER,
	icon = "Interface\\Icons\\ability_monk_roll",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellCharges = GetSpellCharges,
		GetSpellCount = GetSpellCount,
	},
	funcstr = [[(GetSpellCharges(c.NameFirst) or GetSpellCount(c.NameFirst)) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_CHARGES")
	end,	
})
ConditionCategory:RegisterCondition(2.6, "SPELLCHARGETIME", {
	text = L["SPELLCHARGETIME"],
	tooltip = L["SPELLCHARGETIME_DESC"],
	range = 30,
	step = 0.1,
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "spell",
	unit = PLAYER,
	texttable = setmetatable({[0] = CNDT.COMMON.formatSeconds(0).." ("..L["SPELLCHARGES_FULLYCHARGED"]..")"}, {__index = CNDT.COMMON.formatSeconds}),
	icon = "Interface\\Icons\\ability_warlock_handofguldan",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellCharges = GetSpellCharges,
	},
	funcstr = [[RechargeDuration(c.NameFirst) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_COOLDOWN"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE"),
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_CHARGES")
	end,
	anticipate = [[
		local _, _, start, duration = GetSpellCharges(c.NameFirst)
		local VALUE = duration and start + (duration - c.Level) or huge
	]],
})

ConditionCategory:RegisterSpacer(2.7)

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
	min = 0,
	max = 1,
	name = function(editbox) TMW:TT(editbox, "ICONMENU_REACTIVE", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	check = function(check) TMW:TT(check, "ICONMENU_IGNORENOMANA", "ICONMENU_IGNORENOMANA_DESC") end,
	useSUG = true,
	nooperator = true,
	unit = false,
	texttable = CNDT.COMMON.usableunusable,
	icon = "Interface\\Icons\\ability_warrior_revenge",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[c.1nil == ReactiveHelper(c.NameFirst, c.Checked)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE")
	end,
})
ConditionCategory:RegisterCondition(4,	 "MANAUSABLE", {
	text = L["CONDITIONPANEL_MANAUSABLE"],
	min = 0,
	max = 1,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_MANAUSABLE", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = true,
	nooperator = true,
	unit = false,
	texttable = CNDT.COMMON.usableunusable,
	icon = "Interface\\Icons\\inv_potion_137",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[c.nil1 == SpellHasNoMana(c.NameFirst)]],
	Env = {
		SpellHasNoMana = TMW.SpellHasNoMana
	},
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("SPELL_UPDATE_USABLE"),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "player")
	end,
})
ConditionCategory:RegisterCondition(5,	 "SPELLRANGE", {
	text = L["CONDITIONPANEL_SPELLRANGE"],
	min = 0,
	max = 1,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_SPELLRANGE", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
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
	min = 0,
	max = 1,
	nooperator = true,
	unit = PLAYER,
	texttable = CNDT.COMMON.bool,
	icon = "Interface\\Icons\\ability_hunter_steadyshot",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[(TMW.GCD > 0 and TMW.GCD < 1.7) == c.True]],
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
	name = function(editbox) TMW:TT(editbox, L["ITEMCOOLDOWN"], "CNDT_ONLYFIRST", 1) editbox.label = L["ITEMTOCHECK"] end,
	useSUG = "itemwithslots",
	unit = PLAYER,
	texttable = CNDT.COMMON.usableseconds,
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
	name = function(editbox) TMW:TT(editbox, "ITEMTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCOMP1"] end,
	name2 = function(editbox) TMW:TT(editbox, "ITEMTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCOMP2"] end,
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
	min = 0,
	max = 1,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_ITEMRANGE", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCHECK"] end,
	useSUG = "itemwithslots",
	nooperator = true,
	texttable = {[0] = L["INRANGE"], [1] = L["NOTINRANGE"]},
	icon = "Interface\\Icons\\ability_hunter_snipershot",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsItemInRange = IsItemInRange,
	},
	funcstr = function(c)
		return 1-c.Level .. [[ == (c.Item:IsInRange(c.Unit) or 0)]]
	end,
	-- events = absolutely none
})
ConditionCategory:RegisterCondition(14,	 "ITEMINBAGS", {
	text = L["ITEMINBAGS"],
	min = 0,
	max = 50,
	texttable = function(k) return format(ITEM_SPELL_CHARGES, k) end,
	name = function(editbox) TMW:TT(editbox, "ITEMINBAGS", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCHECK"] end,
	useSUG = "itemwithslots",
	unit = false,
	icon = "Interface\\Icons\\inv_misc_bag_08",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetItemCount = GetItemCount,
	},
	funcstr = [[c.Item:GetCount() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
	end,
})
ConditionCategory:RegisterCondition(15,	 "ITEMEQUIPPED", {
	text = L["ITEMEQUIPPED"],
	min = 0,
	max = 1,
	nooperator = true,
	texttable = CNDT.COMMON.bool,
	name = function(editbox) TMW:TT(editbox, "ITEMEQUIPPED", "CNDT_ONLYFIRST") editbox.label = L["ITEMTOCHECK"] end,
	useSUG = "itemwithslots",
	unit = false,
	icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsEquippedItem = IsEquippedItem,
	},
	funcstr = [[c.1nil == c.Item:GetEquipped()]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("BAG_UPDATE"),
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
	end,
})


ConditionCategory:RegisterSpacer(18)


ConditionCategory:RegisterCondition(19,	 "MHSWING", {
	text = L["SWINGTIMER"] .. " - " .. INVTYPE_WEAPONMAINHAND,
	range = 3,
	step = 0.1,
	unit = PLAYER,
	texttable = CNDT.COMMON.usableseconds,
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
		local start, duration = SwingDuration(]] .. GetInventorySlotInfo("MainHandSlot") .. [[)
		local VALUE = duration and start + (duration - c.Level) or huge
	]],
})
ConditionCategory:RegisterCondition(19.5,	 "OHSWING", {
	text = L["SWINGTIMER"] .. " - " .. INVTYPE_WEAPONOFFHAND,
	range = 3,
	step = 0.1,
	unit = PLAYER,
	texttable = CNDT.COMMON.usableseconds,
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
		local start, duration = SwingDuration(]] .. GetInventorySlotInfo("SecondaryHandSlot") .. [[)
		local VALUE = duration and start + (duration - c.Level) or huge
	]],
})


ConditionCategory:RegisterSpacer(20)

local totems = {}
local totemtex = {}
if pclass == "SHAMAN" then
	totems = {
		L["ICONMENU_TOTEM"] .. " - " .. L["FIRE"],
		L["ICONMENU_TOTEM"] .. " - " .. L["EARTH"],
		L["ICONMENU_TOTEM"] .. " - " .. L["WATER"],
		L["ICONMENU_TOTEM"] .. " - " .. L["AIR"],
	}
	totemtex = {
		GetSpellTexture(8227),	-- flametongue
		GetSpellTexture(78222),	-- stoneskin
		GetSpellTexture(5675),	-- mana spring
		GetSpellTexture(3738),	-- wrath of air
	}
elseif pclass == "DRUID" then
	totems = {
		format(L["MUSHROOM"], 1),
		format(L["MUSHROOM"], 2),
		format(L["MUSHROOM"], 3),
	}
	totemtex = {
		GetSpellTexture(88747),
		GetSpellTexture(88747),
		GetSpellTexture(88747),
	}
elseif pclass == "DEATHKNIGHT" then
	totems = {
		L["ICONMENU_GHOUL"]
	}
	totemtex = {
		GetSpellTexture(46584),
	}
end
function Env.TotemHelper(slot, nameString)
	local have, name, start, duration = GetTotemInfo(slot)
	if nameString and nameString ~= "" and nameString ~= ";" and name and not strfind(nameString, Env.SemicolonConcatCache[name or ""]) then
		return 0
	end
	return duration and duration ~= 0 and (duration - (TMW.time - start)) or 0
end
ConditionCategory:RegisterCondition(21,	 "TOTEM1", {
	text = totems[1],
	range = 60,
	unit = false,
	name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
	useSUG = true,
	allowMultipleSUGEntires = true,
	texttable = CNDT.COMMON.absentseconds,
	icon = totemtex[1],
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[TotemHelper(1, c.Name) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
	end,
	anticipate = function(c)
		return [[local VALUE = time + TotemHelper(1) - c.Level]]
	end,
	hidden = not totems[1],
})
ConditionCategory:RegisterCondition(22,	 "TOTEM2", {
	text = totems[2],
	range = 60,
	unit = false,
	name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
	useSUG = true,
	allowMultipleSUGEntires = true,
	texttable = CNDT.COMMON.absentseconds,
	icon = totemtex[2],
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[TotemHelper(2, c.Name) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
	end,
	anticipate = function(c)
		return [[local VALUE = time + TotemHelper(2) - c.Level]]
	end,
	hidden = not totems[2],
})
ConditionCategory:RegisterCondition(23,	 "TOTEM3", {
	text = totems[3],
	range = 60,
	unit = false,
	name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
	useSUG = true,
	allowMultipleSUGEntires = true,
	texttable = CNDT.COMMON.absentseconds,
	icon = totemtex[3],
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[TotemHelper(3, c.Name) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
	end,
	anticipate = function(c)
		return [[local VALUE = time + TotemHelper(3) - c.Level]]
	end,
	hidden = not totems[3],
})
ConditionCategory:RegisterCondition(24,	 "TOTEM4", {
	text = totems[4],
	range = 60,
	unit = false,
	name = function(editbox) TMW:TT(editbox, "CNDT_TOTEMNAME", "CNDT_TOTEMNAME_DESC") editbox.label = L["CNDT_TOTEMNAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
	useSUG = true,
	allowMultipleSUGEntires = true,
	texttable = CNDT.COMMON.absentseconds,
	icon = totemtex[4],
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[TotemHelper(4, c.Name) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TOTEM_UPDATE")
	end,
	anticipate = function(c)
		return [[local VALUE = time + TotemHelper(4) - c.Level]]
	end,
	hidden = not totems[4],
})

ConditionCategory:RegisterSpacer(30)

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
Env.UnitCast = function(unit, level, matchname)
	local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
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
	local name, _, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, _, _, _, _, endTime, _, notInterruptible = UnitChannelInfo(unit)
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
ConditionCategory:RegisterCondition(31,	 "CASTING", {
	text = L["ICONMENU_CAST"],
	min = 0,
	max = 2,
	nooperator = true,
	texttable = {
		[0] = L["CONDITIONPANEL_INTERRUPTIBLE"],
		[1] = L["ICONMENU_PRESENT"],
		[2] = L["ICONMENU_ABSENT"],
	},
	midt = true,
	icon = "Interface\\Icons\\Temp",
	tcoords = CNDT.COMMON.standardtcoords,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_CASTTOMATCH", "CONDITIONPANEL_CASTTOMATCH_DESC") editbox.label = L["CONDITIONPANEL_CASTTOMATCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"] end,
	useSUG = true,
	funcstr = [[UnitCast(c.Unit, c.Level, LOWER(c.NameName))]], -- LOWER is some gsub magic
	events = function(ConditionObject, c)
		-- holy shit... need i say more?
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_START", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_STOP", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_FAILED", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_DELAYED", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_INTERRUPTED", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_START", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_UPDATE", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_STOP", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_CHANNEL_INTERRUPTED", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_INTERRUPTIBLE", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", CNDT:GetUnit(c.Unit))
	end,
})


local CastCounts
local function CASTCOUNT_COMBAT_LOG_EVENT_UNFILTERED(e, _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _, spellID, spellName)
	if cleuEvent == "SPELL_CAST_SUCCESS" then
		spellName = spellName and strlowerCache[spellName]
		local castsForGUID = CastCounts[sourceGUID]
		
		if not castsForGUID then
			castsForGUID = {}
			CastCounts[sourceGUID] = castsForGUID
		end
		
		castsForGUID[spellName] = spellID
		castsForGUID[spellID] = (castsForGUID[spellID] or 0) + 1
	
	elseif cleuEvent == "UNIT_DIED" then
		if destFlags then
			if bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER then
				CastCounts[destGUID] = nil
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
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
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
			ConditionObject:GenerateNormalEventString("COMBAT_LOG_EVENT_UNFILTERED", nil, "SPELL_CAST_SUCCESS")
	end,
})
