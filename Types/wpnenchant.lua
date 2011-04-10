-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, CUR_TIME, UPD_INTV, WpnEnchDurs, ClockGCD, pr, ab, rc, mc
local _G, strlower, strmatch, strtrim, select, floor =
	  _G, strlower, strmatch, strtrim, select, floor
local GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo =
	  GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	HideUnequipped = true,
	WpnEnchantType = true,
	BuffShowWhen = true,
	Alpha = true,
	UnAlpha = true,
	ShowCBar = true,
	CBarOffs = true,
	ConditionAlpha = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("wpnenchant", RelevantSettings, L["ICONMENU_WPNENCHANT"])
Type.name = L["ICONMENU_WPNENCHANT"]
Type.desc = L["ICONMENU_WPNENCHANT_DESC"]

local Parser = CreateFrame("GameTooltip", "TellMeWhen_Parser", TMW, "GameTooltipTemplate")
local function GetWeaponEnchantName(slot)
	GameTooltip_SetDefaultAnchor(Parser, UIParent)
	local has = Parser:SetInventoryItem("player", slot)

	if not has then Parser:Hide() return false end

	local i = 1
	while _G["TellMeWhen_ParserTextLeft" .. i] do
		local t = _G["TellMeWhen_ParserTextLeft" .. i]:GetText()
		if t and t ~= "" then
			local r = strmatch(t, "([^%(]*)%((%d+)[^%.].*%)") -- should work with all locales and only get the weapon enchant name, not other things (like the weapon DPS)
			if r then
				r = strtrim(r)
				if r ~= "" then
					Parser:Hide()
					return r
				end
			end
		end
		i=i+1
	end
	Parser:Hide()
end

Type:SetScript("OnUpdate", function()
	CUR_TIME = TMW.CUR_TIME
end)

function Type:Update()
	CUR_TIME = TMW.CUR_TIME
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	WpnEnchDurs = db.profile.WpnEnchDurs
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end

local SlotsToNumbers = {
	MainHandSlot = 1,
	SecondaryHandSlot = 4,
	RangedSlot = 7,
}


local function WpnEnchant_OnEvent(icon, event, unit)
	if unit == "player" then
		icon:SetTexture(GetInventoryItemTexture("player", icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

		local EnchantName = GetWeaponEnchantName(icon.Slot)
		icon.EnchantName = EnchantName
		if icon.Name == "" then
			icon.CorrectEnchant = true
		else
			if EnchantName then
				icon.CorrectEnchant = icon.NameDictionary[strlower(EnchantName)]
			end
		end
	end
end

local function WpnEnchant_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		if icon.CndtCheck and icon.CndtCheck() then return end
		local has, expiration = select(icon.SelectIndex, GetWeaponEnchantInfo())
		if has and icon.CorrectEnchant then
			local Alpha = icon.Alpha
			if Alpha == 0 then
				icon:SetAlpha(0)
				return
			end
			expiration = expiration/1000
			
			if (icon.DurationMinEnabled and icon.DurationMin > expiration) or (icon.DurationMaxEnabled and expiration > icon.DurationMax) then
				icon:SetAlpha(0)
				return
			end
			local duration
			local EnchantName = icon.EnchantName
			if EnchantName then
				local d = WpnEnchDurs[EnchantName]
				if d < expiration then
					WpnEnchDurs[EnchantName] = expiration
					duration = expiration
				else
					duration = d
				end
			else
				duration = expiration
			end
			local start = floor(CUR_TIME - duration + expiration)

			if icon.UnAlpha ~= 0 then
				icon:SetVertexColor(pr)
			else
				icon:SetVertexColor(1)
			end
			icon:SetAlpha(Alpha)

			if icon.ShowTimer then
				icon:SetCooldown(start, duration)
			end
			if icon.ShowCBar then
				icon:CDBarStart(start, duration)
			end
		else
			local UnAlpha = icon.UnAlpha
			if UnAlpha == 0 then
				icon:SetAlpha(0)
				return
			end
			if icon.Alpha ~= 0 then
				icon:SetVertexColor(ab)
			else
				icon:SetVertexColor(1)
			end
			icon:SetAlpha(UnAlpha)
			icon:SetCooldown(0, 0)
			icon:CDBarStop()
		end
	end
end

Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.SelectIndex = SlotsToNumbers[icon.WpnEnchantType] or 1
	icon.Slot = GetInventorySlotInfo(icon.WpnEnchantType)

	icon.ShowPBar = false

	icon:SetTexture(GetInventoryItemTexture("player", icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")
	
	icon:SetReverse(true)

	icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
	icon:SetScript("OnEvent", WpnEnchant_OnEvent)
	icon:OnEvent(nil, "player")

	icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
	icon:OnUpdate()
end

