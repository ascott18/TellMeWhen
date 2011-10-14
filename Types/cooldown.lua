-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, rc, mc, pr, ab
local GetSpellCooldown, IsSpellInRange, IsUsableSpell =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local UnitRangedDamage =
	  UnitRangedDamage
local pairs =
	  pairs
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures
local mindfreeze = strlower(GetSpellInfo(47528))

local Type = {}
LibStub("AceEvent-3.0"):Embed(Type)
Type.type = "cooldown"
Type.name = L["ICONMENU_SPELLCOOLDOWN"]
Type.TypeChecks = {
	text = L["ICONMENU_COOLDOWNTYPE"],
	setting = "CooldownType",
	{ value = "spell", 			text = L["ICONMENU_SPELL"] },
	{ value = "multistate", 	text = L["ICONMENU_MULTISTATECD"], 		tooltipText = L["ICONMENU_MULTISTATECD_DESC"] },
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",  		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	CooldownType = true,
	RangeCheck = true,
	ManaCheck = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	IgnoreRunes = (pclass == "DEATHKNIGHT"),
}
Type.DisabledEvents = {
	OnUnit = true,
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end



local function AutoShot_OnEvent(icon, event, unit, _, _, _, spellID)
	if unit == "player" and spellID == 75 then
		icon.asStart = TMW.time
		icon.asDuration = UnitRangedDamage("player")
	end
end

local function AutoShot_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		
		local NameName = icon.NameName
		
		local ready = time - icon.asStart > icon.asDuration
		local inrange = icon.RangeCheck and IsSpellInRange(NameName, "target") or 1
		
		if ready and inrange then
			
			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, nil, 0, 0, NameName, nil, nil, nil, nil, nil)
		else
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
			
			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(alpha, color, nil, icon.asStart, icon.asDuration, NameName, nil, nil, nil, nil, nil)
		end
	end
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
				if IgnoreRunes and duration == 10 and NameNameArray[i] ~= mindfreeze then
					start, duration = 0, 0
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
					
					--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
					icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, SpellTextures[iName], start, duration, iName, nil, nil, nil, nil, nil)
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
			if IgnoreRunes and duration == 10 and icon.NameName ~= mindfreeze then
				start, duration = 0, 0
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

			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(alpha, color, icon.FirstTexture, start, duration, NameFirst, nil, nil, nil, nil, nil)
		else
			icon:SetInfo(0)
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

			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(alpha, color, GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark", start, duration, icon.NameFirst, nil, nil, nil, nil, nil)
		end
	end
end



function Type:Setup(icon, groupID, iconID)
	if icon.CooldownType == "spell" then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
		icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
		icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
		icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
		
		if icon.NameName == strlower(GetSpellInfo(75)) and not icon.NameArray[2] then
			icon:SetTexture(GetSpellTexture(75))
			icon.asStart = icon.asStart or 0
			icon.asDuration = icon.asDuration or 0
			
			icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
			icon:SetScript("OnEvent", AutoShot_OnEvent)
			
			icon:SetScript("OnUpdate", AutoShot_OnUpdate)
		else
			icon.FirstTexture = SpellTextures[icon.NameFirst]

			icon:SetTexture(TMW:GetConfigIconTexture(icon))
			icon:SetScript("OnUpdate", SpellCooldown_OnUpdate)
		end
		
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

function Type:IE_TypeLoaded()
	local Name = TMW.IE.Main.Name
	Name.__text = TMW.CI.IMS and L["CHOOSENAME_DIALOG_MSCD"] or L["CHOOSENAME_DIALOG"]
	Name:GetScript("OnTextChanged")(Name)
end

function Type:IE_TypeUnloaded()
	local Name = TMW.IE.Main.Name
	Name.__text = L["CHOOSENAME_DIALOG"]
	Name:GetScript("OnTextChanged")(Name)
end

TMW:RegisterIconType(Type)