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

local db, WpnEnchDurs, ClockGCD
local _G, strlower, strmatch, strtrim, select, floor, ceil =
	  _G, strlower, strmatch, strtrim, select, floor, ceil
local GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo =
	  GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo
local print = TMW.print
local UIParent = UIParent
local strlowerCache = TMW.strlowerCache


local Type = {}
Type.type = "wpnenchant"
Type.name = L["ICONMENU_WPNENCHANT"]
Type.desc = L["ICONMENU_WPNENCHANT_DESC"]
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME_WPNENCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"]
Type.chooseNameText = L["ICONMENU_CHOOSENAME_WPNENCH_DESC"]
Type.AllowNoName = true
Type.SUGType = "wpnenchant"
Type.TypeChecks = {
	text = L["ICONMENU_WPNENCHANTTYPE"],
	setting = "WpnEnchantType",
	{ value = "MainHandSlot",	text = INVTYPE_WEAPONMAINHAND },
	{ value = "SecondaryHandSlot", text = INVTYPE_WEAPONOFFHAND },
	{ value = "RangedSlot",		text = INVTYPE_THROWN },
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	HideUnequipped = true,
	WpnEnchantType = true,
	ShowCBar = true,
	CBarOffs = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
}

Type.EventDisabled_OnUnit = true
Type.EventDisabled_OnStack = true

local Parser = CreateFrame("GameTooltip", "TellMeWhen_Parser", TMW, "GameTooltipTemplate")
local function GetWeaponEnchantName(slot)
	Parser:SetOwner(UIParent, "ANCHOR_NONE")
	local has = Parser:SetInventoryItem("player", slot)

	if not has then Parser:Hide() return false end

	local i = 1
	while _G["TellMeWhen_ParserTextLeft" .. i] do
		local t = _G["TellMeWhen_ParserTextLeft" .. i]:GetText()
		if t and t ~= "" then --（） multibyte parenthesis are used in zhCN locale.
			local r = strmatch(t, "(.+)[%(%（]%d+[^%.]*[^%d]+[%)%）]") -- should work with all locales and only get the weapon enchant name, not other things (like the weapon DPS)
			
			if r then
				r = strtrim(r)
				if r ~= "" then
					return print(r)
				end
			end
		end
		i=i+1
	end
end
_G.GetWeaponEnchantName = GetWeaponEnchantName

local function UpdateWeaponEnchantInfo(slot, selectIndex)
	local has, expiration = select(selectIndex, GetWeaponEnchantInfo())
	
	if has then
		local EnchantName = GetWeaponEnchantName(slot)
		
		if EnchantName then
			expiration = expiration/1000
			local d = WpnEnchDurs[EnchantName]
			
			if d < expiration then
				WpnEnchDurs[EnchantName] = ceil(expiration)
			end
		end
	end
end

function Type:Update()
	db = TMW.db
	ClockGCD = db.profile.ClockGCD
	WpnEnchDurs = db.global.WpnEnchDurs
end

local SlotsToNumbers = {
	MainHandSlot = 1,
	SecondaryHandSlot = 4,
	RangedSlot = 7,
}

local function WpnEnchant_OnUpdate(icon, time)
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
		
		local color = icon:CrunchColor(duration)
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(icon.Alpha, color, nil, start, duration, EnchantName, nil, nil, nil, nil, nil)
	else
		local color = icon:CrunchColor()
		
		icon:SetInfo(icon.UnAlpha, color, nil, 0, 0, nil, nil, nil, nil, nil, nil) 
	end
end

local function WpnEnchant_OnEvent(icon, event, unit)
	-- this function must be declared after _OnUpdate because it references _OnUpdate from inside it.
	if unit == "player" then
		local Slot = icon.Slot
		
	--	UpdateWeaponEnchantInfo(Slot, icon.SelectIndex)
		
		local EnchantName = GetWeaponEnchantName(Slot)
		print(icon, event, unit, Slot, EnchantName)
		icon.LastEnchantName = icon.EnchantName or icon.LastEnchantName
		icon.EnchantName = EnchantName
		
		if icon.Name == "" then
			icon.CorrectEnchant = true
		elseif EnchantName then
			icon.CorrectEnchant = icon.NameHash[strlowerCache[EnchantName]]
		end
		
		local wpnTexture = GetInventoryItemTexture("player", Slot)

		icon:SetTexture(wpnTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
	
		if icon.HideUnequipped then
			if not wpnTexture then
				icon:SetInfo(0)
				icon:SetScript("OnUpdate", nil)
				return
			end
			
			local itemID = GetInventoryItemID("player", Slot)
			if itemID then
				local _, _, _, _, _, _, _, _, invType = GetItemInfo(itemID)
				if invType == "INVTYPE_HOLDABLE" or invType == "INVTYPE_RELIC" or invType == "INVTYPE_SHIELD" then
					icon:SetInfo(0)
					icon:SetScript("OnUpdate", nil)
					return
				end
			end
		end
		if not icon.OnUpdate then
			icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
		end
	end
end

function Type:Setup(icon, groupID, iconID)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.SelectIndex = SlotsToNumbers[icon.WpnEnchantType] or 1
	icon.Slot = GetInventorySlotInfo(icon.WpnEnchantType)

	UpdateWeaponEnchantInfo(icon.Slot, icon.SelectIndex)

	icon.ShowPBar = false

	icon:SetTexture(GetInventoryItemTexture("player", icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

	icon:SetReverse(true)
	
	icon.EnchantName = nil
	icon.LastEnchantName = nil
	icon.CorrectEnchant = nil		

	icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
	icon:Update()

	icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
	icon:SetScript("OnEvent", WpnEnchant_OnEvent)
	icon:OnEvent(nil, "player")
end

function Type:GetNameForDisplay(icon, data)
	return icon.LastEnchantName or data or icon.EnchantName
end

function Type:GetIconMenuText(data)
	local text = ""
	if data.WpnEnchantType == "MainHandSlot" or not data.WpnEnchantType then
		text = INVTYPE_WEAPONMAINHAND
	elseif data.WpnEnchantType == "SecondaryHandSlot" then
		text = INVTYPE_WEAPONOFFHAND
	elseif data.WpnEnchantType == "RangedSlot" then
		text = INVTYPE_THROWN
	end
	text = text .. " ((" .. L["ICONMENU_WPNENCHANT"] .. "))"
	
	local tooltip =	(data.Name and data.Name ~= "" and data.Name .. "\r\n" or "")

	return text, tooltip
end

TMW:RegisterIconType(Type)