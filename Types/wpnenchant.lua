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

local db, UPD_INTV, WpnEnchDurs, ClockGCD, pr, ab, rc, mc
local _G, strlower, strmatch, strtrim, select, floor =
	  _G, strlower, strmatch, strtrim, select, floor
local GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo =
	  GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo
local print = TMW.print
local UIParent = UIParent

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
	Parser:SetOwner(UIParent, "ANCHOR_NONE");
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


function Type:Update()
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



local function WpnEnchant_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		if icon.CndtCheck and icon.CndtCheck() then return end
		local has, expiration = select(icon.SelectIndex, GetWeaponEnchantInfo())
		if has and icon.CorrectEnchant then
			expiration = expiration/1000

			local duration
			local EnchantName = icon.EnchantName
			if EnchantName then
				local d = WpnEnchDurs[EnchantName]
				if d < expiration then
					WpnEnchDurs[EnchantName] = ceil(expiration)
					duration = expiration
				else
					duration = d
				end
			else
				duration = expiration
			end
			local start = floor(time - duration + expiration)

			icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, nil, start, duration)
		else
			icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and ab or 1, nil, 0, 0)
		end
	end
end


local function WpnEnchant_OnEvent(icon, event, unit)
	if unit == "player" then
		local wpnTexture = GetInventoryItemTexture("player", icon.Slot)

		local t = wpnTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
		if t ~= icon.__tex then icon:SetTexture(t) end

		if not wpnTexture and icon.HideUnequipped then
			icon:SetAlpha(0)
			if icon.OnUpdate then
				icon:SetScript("OnUpdate", nil)
			end
		elseif not icon.OnUpdate then
			icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
		end
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

Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.SelectIndex = SlotsToNumbers[icon.WpnEnchantType] or 1
	icon.Slot = GetInventorySlotInfo(icon.WpnEnchantType)

	icon.ShowPBar = false

	icon:SetTexture(GetInventoryItemTexture("player", icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

	icon:SetReverse(true)

	icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
	icon:OnUpdate(TMW.time)

	icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
	icon:SetScript("OnEvent", WpnEnchant_OnEvent)
	icon:OnEvent(nil, "player")
end

