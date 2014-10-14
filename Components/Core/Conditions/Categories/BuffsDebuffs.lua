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
local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache

local UnitAura = UnitAura

function Env.AuraStacks(unit, name, nameString, filter)
	local isID = isNumber[name]
	
	local buffName, _, _, count, _, _, _, _, _, _, id = UnitAura(unit, nameString, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			buffName, _, _, count, _, _, _, _, _, _, id = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	if not buffName then
		return 0
	elseif buffName and count == 0 then
		return 1
	else
		return count
	end
end

function Env.AuraCount(unit, nameRaw, filter)
	local n = 0
	local names = TMW:GetSpells(nameRaw).Hash
	

	for z = 1, 200 do
		local buffName, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, z, filter)
		if not buffName then
			return n
		elseif names[id] or names[strlowerCache[buffName]] then
			n = n + 1
		end
	end

	return n
end

function Env.AuraDur(unit, name, nameString, filter)
	local isID = isNumber[name]
	
	local buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, nameString, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	
	if not buffName then
		return 0, 0, 0
	else
		return expirationTime == 0 and huge or expirationTime - TMW.time, duration, expirationTime
	end
end

function Env.AuraPercent(unit, name, nameString, filter)
	local isID = isNumber[name]
	
	local buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, nameString, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	
	if not buffName then
		return 0
	else
		return expirationTime == 0 and 1 or ((expirationTime - TMW.time) / duration)
	end
end

function Env.AuraTooltipNumber(unit, name, nameString, filter)
	local isID = isNumber[name]
	
	local _, _, _, _, _, _, _, _, _, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, nameString, nil, filter)
	if isID and id and id ~= isID then
		for z = 1, 60 do
			_, _, _, _, _, _, _, _, _, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, z, filter)
			if not id or id == isID then
				break
			end
		end
	end
	
	--if v1 then
		if v1 and v1 > 0 then
			return v1
		elseif v2 and v2 > 0 then
			return v2
		elseif v3 and v3 > 0 then
			return v3
		elseif v4 and v4 > 0 then
			return v4
		end
	--end
	return 0
end



local ConditionCategory = CNDT:GetCategory("BUFFSDEBUFFS", 5, L["CNDTCAT_BUFFSDEBUFFS"], false, false)

ConditionCategory:RegisterCondition(1,	 "BUFFDUR", {
	text = L["ICONMENU_BUFF"] .. " - " .. L["DURATION"],
	range = 30,
	step = 0.1,
	name = function(editbox) TMW:TT(editbox, "BUFFTOCHECK", "BUFFCNDT_DESC") editbox.label = L["BUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	formatter = TMW.C.Formatter.TIME_0ABSENT,
	icon = "Interface\\Icons\\spell_nature_rejuvenation",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraDur(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
	anticipate = function(c)
		return [[local dur, duration, expirationTime = AuraDur(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[")
		local VALUE
		if dur and dur > 0 then
			VALUE = expirationTime and expirationTime - c.Level or 0
		else
			VALUE = 0
		end]]
	end,
})
ConditionCategory:RegisterCondition(2.5, "BUFFPERC", {
	text = L["ICONMENU_BUFF"] .. " - " .. L["DURATION"] .. " - " .. L["PERCENTAGE"],
	min = 0,
	max = 100,
	percent = true,
	name = function(editbox) TMW:TT(editbox, "BUFFTOCHECK", "BUFFCNDT_DESC") editbox.label = L["BUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	formatter = TMW.C.Formatter.PERCENT,
	icon = "Interface\\Icons\\spell_holy_circleofrenewal",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraPercent(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
	anticipate = function(c)
		return [[local dur, duration, expirationTime = AuraDur(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[")
		local VALUE
		if dur and dur > 0 then
			VALUE = expirationTime and (expirationTime - c.Level*duration) or 0
		else
			VALUE = 0
		end]]
	end,
})
ConditionCategory:RegisterCondition(2,	 "BUFFDURCOMP", {
	text = L["ICONMENU_BUFF"] .. " - " .. L["DURATION"] .. " - " .. L["COMPARISON"],
	noslide = true,
	name = function(editbox) TMW:TT(editbox, "BUFFTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["BUFFTOCOMP1"] end,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	name2 = function(editbox) TMW:TT(editbox, "BUFFTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["BUFFTOCOMP2"] end,
	check2 = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	useSUG = true,
	icon = "Interface\\Icons\\spell_nature_rejuvenation",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraDur(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator AuraDur(c.Unit, c.NameFirst2, c.NameString2, "HELPFUL]] .. (c.Checked2 and " PLAYER" or "") .. [[")]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(3,	 "BUFFSTACKS", {
	text = L["ICONMENU_BUFF"] .. " - " .. L["STACKS"],
	range = 20,
	name = function(editbox) TMW:TT(editbox, "BUFFTOCHECK", "BUFFCNDT_DESC") editbox.label = L["BUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
	icon = "Interface\\Icons\\inv_misc_herb_felblossom",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraStacks(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(4,	 "BUFFTOOLTIP", {
	text = L["ICONMENU_BUFF"] .. " - " .. L["TOOLTIPSCAN"],
	tooltip = L["TOOLTIPSCAN_DESC"],
	range = 500,
	--texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
	name = function(editbox) TMW:TT(editbox, "BUFFTOCHECK", "TOOLTIPSCAN_DESC") editbox.label = L["BUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	icon = "Interface\\Icons\\inv_elemental_primal_mana",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraTooltipNumber(c.Unit, c.NameFirst, c.NameString, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(5,	 "BUFFNUMBER", {
	text = L["ICONMENU_BUFF"] .. " - " .. L["NUMAURAS"],
	tooltip = L["NUMAURAS_DESC"],
	min = 0,
	max = 20,
	name = function(editbox) TMW:TT(editbox, "BUFFTOCHECK", "CNDT_MULTIPLEVALID") editbox.label = L["BUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	texttable = function(k) return format(L["ACTIVE"], k) end,
	icon = "Interface\\Icons\\ability_paladin_sacredcleansing",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraCount(c.Unit, c.NameRaw, "HELPFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(8)

ConditionCategory:RegisterCondition(9,	 "ABSORBAMT", {
	text = L["ABSORBAMT"],
	tooltip = L["ABSORBAMT_DESC"],
	range = 50000,
	icon = "Interface\\Icons\\spell_holy_powerwordshield",
	formatter = TMW.C.Formatter.COMMANUMBER,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitGetTotalAbsorbs = UnitGetTotalAbsorbs,
	},
	funcstr = function(c)
		return [[UnitGetTotalAbsorbs(c.Unit) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_ABSORB_AMOUNT_CHANGED", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(10)

ConditionCategory:RegisterCondition(11,	 "DEBUFFDUR", {
	text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATION"],
	range = 30,
	step = 0.1,
	name = function(editbox) TMW:TT(editbox, "DEBUFFTOCHECK", "BUFFCNDT_DESC") editbox.label = L["DEBUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	formatter = TMW.C.Formatter.TIME_0ABSENT,
	icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraDur(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
	anticipate = function(c)
		return [[local dur, duration, expirationTime = AuraDur(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[")
		local VALUE
		if dur and dur > 0 then
			VALUE = expirationTime and expirationTime - c.Level or 0
		else
			VALUE = 0
		end]]
	end,
})
ConditionCategory:RegisterCondition(12.5,"DEBUFFPERC", {
	text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATION"] .. " - " .. L["PERCENTAGE"],
	min = 0,
	max = 100,
	percent = true,
	name = function(editbox) TMW:TT(editbox, "DEBUFFTOCHECK", "BUFFCNDT_DESC") editbox.label = L["DEBUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	formatter = TMW.C.Formatter.PERCENT,
	icon = "Interface\\Icons\\spell_priest_voidshift",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraPercent(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
	anticipate = function(c)
		return [[local dur, duration, expirationTime = AuraDur(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[")
		local VALUE
		if dur and dur > 0 then
			VALUE = expirationTime and (expirationTime - c.Level*duration) or 0
		else
			VALUE = 0
		end]]
	end,
})
ConditionCategory:RegisterCondition(12,	 "DEBUFFDURCOMP", {
	text = L["ICONMENU_DEBUFF"] .. " - " .. L["DURATION"] .. " - " .. L["COMPARISON"],
	noslide = true,
	name = function(editbox) TMW:TT(editbox, "DEBUFFTOCOMP1", "CNDT_ONLYFIRST") editbox.label = L["DEBUFFTOCOMP1"] end,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	name2 = function(editbox) TMW:TT(editbox, "DEBUFFTOCOMP2", "CNDT_ONLYFIRST") editbox.label = L["DEBUFFTOCOMP2"] end,
	check2 = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	useSUG = true,
	icon = "Interface\\Icons\\spell_shadow_abominationexplosion",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraDur(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator AuraDur(c.Unit, c.NameFirst2, c.NameString2, "HARMFUL]] .. (c.Checked2 and " PLAYER" or "") .. [[")]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
	-- anticipate: no anticipator is needed because the durations will always remain the same relative to eachother until at least a UNIT_AURA fires
})
ConditionCategory:RegisterCondition(13,	 "DEBUFFSTACKS", {
	text = L["ICONMENU_DEBUFF"] .. " - " .. L["STACKS"],
	range = 20,
	name = function(editbox) TMW:TT(editbox, "DEBUFFTOCHECK", "BUFFCNDT_DESC") editbox.label = L["DEBUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	texttable = setmetatable({[0] = format(STACKS, 0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = function(tbl, k) return format(STACKS, k) end}),
	icon = "Interface\\Icons\\ability_warrior_sunder",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraStacks(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(14,	 "DEBUFFTOOLTIP", {
	text = L["ICONMENU_DEBUFF"] .. " - " .. L["TOOLTIPSCAN"],
	tooltip = L["TOOLTIPSCAN_DESC"],
	range = 500,
	--texttable = {[0] = "0 ("..L["ICONMENU_ABSENT"]..")"},
	name = function(editbox) TMW:TT(editbox, "DEBUFFTOCHECK", "TOOLTIPSCAN_DESC") editbox.label = L["DEBUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	icon = "Interface\\Icons\\spell_shadow_lifedrain",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraTooltipNumber(c.Unit, c.NameFirst, c.NameString, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(15,	 "DEBUFFNUMBER", {
	text = L["ICONMENU_DEBUFF"] .. " - " .. L["NUMAURAS"],
	tooltip = L["NUMAURAS_DESC"],
	min = 0,
	max = 20,
	name = function(editbox) TMW:TT(editbox, "DEBUFFTOCHECK", "CNDT_MULTIPLEVALID") editbox.label = L["DEBUFFTOCHECK"] end,
	useSUG = true,
	check = function(check) TMW:TT(check, "ONLYCHECKMINE", "ONLYCHECKMINE_DESC") end,
	texttable = function(k) return format(L["ACTIVE"], k) end,
	icon = "Interface\\Icons\\spell_deathknight_frostfever",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		return [[AuraCount(c.Unit, c.NameRaw, "HARMFUL]] .. (c.Checked and " PLAYER" or "") .. [[") c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_AURA", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterSpacer(20)

Env.GetWeaponEnchantInfo = GetWeaponEnchantInfo
ConditionCategory:RegisterCondition(21,	 "MAINHAND", {
	text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_WEAPONMAINHAND,
	range = 120,
	unit = false,
	formatter = TMW.C.Formatter.TIME_0ABSENT,
	icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_14" end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[(select(2, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
	end,
	anticipate = [[local _, dur = GetWeaponEnchantInfo()
		local VALUE = time + ((dur or 0)/1000) - c.Level]],
})
ConditionCategory:RegisterCondition(22,	 "OFFHAND", {
	text = L["ICONMENU_WPNENCHANT"] .. " - " .. INVTYPE_WEAPONOFFHAND,
	range = 120,
	unit = false,
	formatter = TMW.C.Formatter.TIME_0ABSENT,
	icon = function() return GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")) or "Interface\\Icons\\inv_weapon_shortblade_15" end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[(select(5, GetWeaponEnchantInfo()) or 0)/1000 c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_INVENTORY_CHANGED", "player")
	end,
	anticipate = [[local _, _, _, _, dur = GetWeaponEnchantInfo()
		local VALUE = time + ((dur or 0)/1000) - c.Level]],
})
