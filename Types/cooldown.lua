-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, rc, mc
local GetSpellCooldown, IsSpellInRange, IsUsableSpell =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell
local GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon, GetItemCount =
	  GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon, GetItemCount
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	ShowWhen = true,
	CooldownType = true,
	RangeCheck = true,
	ManaCheck = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	IgnoreRunes = (pclass == "DEATHKNIGHT"),
	OnlyEquipped = true,
	OnlyInBags = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("cooldown", RelevantSettings)
Type.name = L["ICONMENU_COOLDOWN"]
Type.TypeChecks = {
	text = L["ICONMENU_COOLDOWNTYPE"],
	setting = "CooldownType",
	{ value = "spell", 			text = L["ICONMENU_SPELL"] },
	{ value = "multistate", 	text = L["ICONMENU_MULTISTATECD"], 		tooltipText = L["ICONMENU_MULTISTATECD_DESC"] },
	{ value = "item", 			text = L["ICONMENU_ITEM"] },
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",  		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end



local function SpellCooldown_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, nomana, start, duration, isGCD = 1
		local IgnoreRunes, RangeCheck, ManaCheck, NameArray, NameNameArray = icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.NameArray, icon.NameNameArray

		for i = 1, #NameArray do
			local iName = NameArray[i]
			n = i
			start, duration = GetSpellCooldown(iName)
			if duration then
				if IgnoreRunes then
					if start == GetSpellCooldown(45477) or start == GetSpellCooldown(45462) or start == GetSpellCooldown(45902) then
						start, duration = 0, 0
					end
				end
				inrange, nomana = 1
				if RangeCheck then
					inrange = IsSpellInRange(NameNameArray[i], "target") or 1
				end
				if ManaCheck then
					_, nomana = IsUsableSpell(iName)
				end
				isGCD = (ClockGCD or duration ~= 0) and OnGCD(duration)
				if inrange == 1 and not nomana and (duration == 0 or isGCD) then --usable
					icon:SetInfo(icon.Alpha, 1, SpellTextures[iName], start, duration, true, iName)
					return
				end
			end
		end

		local NameFirst = icon.NameFirst
		if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
			start, duration = GetSpellCooldown(NameFirst)
			inrange, nomana = 1
			if RangeCheck then
				inrange = IsSpellInRange(icon.NameName, "target") or 1
			end
			if ManaCheck then
				_, nomana = IsUsableSpell(NameFirst)
			end
			if IgnoreRunes then
				if start == GetSpellCooldown(45477) or start == GetSpellCooldown(45462) or start == GetSpellCooldown(45902) then
					start, duration = 0, 0
				end
			end
			isGCD = OnGCD(duration)
		end
		if duration then

			local alpha, color
			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					alpha, color = icon.UnAlpha*rc.a, rc
				elseif nomana then
					alpha, color = icon.UnAlpha*mc.a, mc
				elseif not icon.ShowTimer then
					alpha, color = icon.UnAlpha, 0.5
				else
					alpha, color = icon.UnAlpha, 1
				end
			else
				alpha, color = icon.UnAlpha, 1
			end

			icon:SetInfo(alpha, color, icon.FirstTexture, start, duration, true, NameFirst)
		else
			icon:Hide()
		end
	end
end


local function ItemCooldown_OnEvent(icon)
	-- the reason for doing it like this is because this event will fire several times at once sometimes,
	-- but there is no reason to recheck things until they are needed next.
	icon.DoUpdateIDs = true
end

local function ItemCooldown_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		if icon.DoUpdateIDs then
			local Name = icon.Name
			icon.NameFirst = TMW:GetItemIDs(icon, Name, 1)
			icon.NameArray = TMW:GetItemIDs(icon, Name)
			icon.DoUpdateIDs = nil
		end

		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, equipped, start, duration, isGCD = 1
		local RangeCheck, OnlyEquipped, OnlyInBags, NameArray = icon.RangeCheck, icon.OnlyEquipped, icon.OnlyInBags, icon.NameArray
		for i = 1, #NameArray do
			local iName = NameArray[i]
			n = i
			start, duration = GetItemCooldown(iName)
			if duration then
				inrange, equipped = 1, true
				if RangeCheck then
					inrange = IsItemInRange(iName, "target") or 1
				end
				if OnlyEquipped and not IsEquippedItem(iName) then
					equipped = false
				end
				if equipped and OnlyInBags and (GetItemCount(iName) == 0) then
					equipped = false
				end
				isGCD = OnGCD(duration)
				if equipped and inrange == 1 and (duration == 0 or isGCD) then --usable

					icon:SetInfo(icon.Alpha, 1, GetItemIcon(iName) or "Interface\\Icons\\INV_Misc_QuestionMark", start, duration, true)

					return
				end
			end
		end

		local NameFirst2
		if OnlyInBags then
			for i = 1, #NameArray do
				local iName = NameArray[i]
				if (OnlyEquipped and IsEquippedItem(iName)) or (not OnlyEquipped and GetItemCount(iName) > 0) then
					NameFirst2 = iName
					break
				end
			end
			if not NameFirst2 then
				icon:SetAlpha(0)
				return
			end
		else
			NameFirst2 = icon.NameFirst
		end
		if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
			start, duration = GetItemCooldown(NameFirst2)
			inrange = 1
			if RangeCheck then
				inrange = IsItemInRange(NameFirst2, "target") or 1
			end
			isGCD = OnGCD(duration)
		end
		if duration then

			local alpha, color
			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					alpha, color = icon.UnAlpha*rc.a, rc
				elseif not icon.ShowTimer then
					alpha, color = icon.UnAlpha, 0.5
				else
					alpha, color = icon.UnAlpha, 1
				end
			else
				alpha, color = icon.UnAlpha, 1
			end
			icon:SetInfo(alpha, color, GetItemIcon(NameFirst2), start, duration, true)
		else
			icon:SetAlpha(0)
		end
	end
end


local function MultiStateCD_OnEvent(icon)
	local actionType, spellID = GetActionInfo(icon.Slot) -- check the current slot first, because it probably didnt change
		if actionType == "spell" and spellID == icon.NameFirst then
		return
	end
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID == icon.NameFirst then
			icon.Slot = i
			return
		end
	end

end

local function MultiStateCD_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local Slot = icon.Slot
		local start, duration = GetActionCooldown(Slot)
		if duration then

			local inrange, nomana = 1

			if icon.RangeCheck then
				inrange = IsActionInRange(Slot, "target") or 1
			end
			if icon.ManaCheck then
				_, nomana = IsUsableAction(Slot)
			end


			local alpha, color
			if (duration == 0 or OnGCD(duration)) and inrange == 1 and not nomana then
				alpha, color = icon.Alpha, 1
			elseif icon.Alpha ~= 0 then
				if inrange ~= 1 then
					alpha, color = icon.UnAlpha*rc.a, rc
				elseif nomana then
					alpha, color = icon.UnAlpha*mc.a, mc
				elseif not icon.ShowTimer then
					alpha, color = icon.UnAlpha, 0.5
				else
					alpha, color = icon.UnAlpha, 1
				end
			else
				alpha, color = icon.UnAlpha, 1
			end

			icon:SetInfo(alpha, color, GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark", start, duration, true, icon.NameFirst)
		end
	end
end



function Type:Setup(icon, groupID, iconID)
	if icon.CooldownType == "spell" then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
		icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
		icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
		icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
		icon.FirstTexture = SpellTextures[icon.NameFirst]

		if icon.Name == "" then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		elseif icon.FirstTexture then
			icon:SetTexture(icon.FirstTexture)
		elseif TMW:DoSetTexture(icon) then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
		icon:SetScript("OnUpdate", SpellCooldown_OnUpdate)
		icon:OnUpdate(TMW.time)
	end
	if icon.CooldownType == "item" then
		icon.NameFirst = TMW:GetItemIDs(icon, icon.Name, 1)
		icon.NameArray = TMW:GetItemIDs(icon, icon.Name)

		if not icon.NameFirst or icon.NameFirst == 0 then
			icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
			icon:SetScript("OnEvent", ItemCooldown_OnEvent)
		else
			for _, n in ipairs(TMW:SplitNames(icon.Name)) do
				n = tonumber(strtrim(n))
				if n and n <= 19 then
					icon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
					icon:SetScript("OnEvent", ItemCooldown_OnEvent)
					break
				end
			end
		end

		icon.ShowPBar = nil
		if icon.OnlyEquipped then
			icon.OnlyInBags = true
		end

		local itemTexture = GetItemIcon(icon.NameFirst)
		if itemTexture then
			icon:SetTexture(itemTexture)
		else
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end

		icon:SetScript("OnUpdate", ItemCooldown_OnUpdate)
		icon:OnUpdate(TMW.time)
	end
	if icon.CooldownType == "multistate" then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)

		if icon.NameFirst and icon.NameFirst ~= "" and GetSpellLink(icon.NameFirst) and not tonumber(icon.NameFirst) then
			icon.NameFirst = tonumber(strmatch(GetSpellLink(icon.NameFirst), ":(%d+)")) -- extract the spellID from the link
		end
		icon.Slot = 0
		for i=1, 120 do
			local actionType, spellID = GetActionInfo(i)
			if actionType == "spell" and spellID == icon.NameFirst then
				icon.Slot = i
				break
			end
		end

		icon:SetTexture(GetActionTexture(icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

		icon:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		icon:SetScript("OnEvent", MultiStateCD_OnEvent)

		icon:SetScript("OnUpdate", MultiStateCD_OnUpdate)
		icon:OnUpdate(TMW.time)
	end
end




