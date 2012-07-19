-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local WpnEnchDurs
local _G, strlower, strmatch, strtrim, select, floor, ceil =
	  _G, strlower, strmatch, strtrim, select, floor, ceil
local GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo =
	  GetInventoryItemTexture, GetInventorySlotInfo, GetWeaponEnchantInfo
local print = TMW.print
local UIParent = UIParent
local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New("wpnenchant")
LibStub("AceTimer-3.0"):Embed(Type)
Type.name = L["ICONMENU_WPNENCHANT"]
Type.desc = L["ICONMENU_WPNENCHANT_DESC"]
Type.AllowNoName = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	HideUnequipped			= false,
	WpnEnchantType			= "MainHandSlot",
}

Type:RegisterConfigPanel_XMLTemplate("full", 1, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME_WPNENCH"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	text = L["ICONMENU_CHOOSENAME_WPNENCH_DESC"],
	SUGType = "wpnenchant",
})

Type:RegisterConfigPanel_XMLTemplate("column", 2, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], 		 },
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"], 			 },
})

Type:RegisterConfigPanel_ConstructorFunc("column", 2, "TellMeWhen_WeaponSlot", function(self)
	self.Header:SetText(TMW.L["ICONMENU_WPNENCHANTTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "WpnEnchantType",
			value = "MainHandSlot",
			title = INVTYPE_WEAPONMAINHAND,
		},
		{
			setting = "WpnEnchantType",
			value = "SecondaryHandSlot",
			title = INVTYPE_WEAPONOFFHAND,
		},
		{
			setting = "WpnEnchantType",
			value = "RangedSlot",
			title = INVTYPE_THROWN,
		},
	})
end)

Type:RegisterConfigPanel_ConstructorFunc("column", 1, "TellMeWhen_WpnEnchantSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "HideUnequipped",
			title = L["ICONMENU_HIDEUNEQUIPPED"],
			tooltip = L["ICONMENU_HIDEUNEQUIPPED_DESC"],
		},
	})
end)

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
					return r
				end
			end
		end
		i=i+1
	end
end

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
	WpnEnchDurs = TMW.db.global.WpnEnchDurs
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

		icon:SetInfo("alpha; start, duration; spell",
			icon.Alpha,
			start, duration,
			EnchantName
		)
	else
		icon:SetInfo("alpha; start, duration; spell",
			icon.UnAlpha,
			0, 0,
			nil
		)
	end
end

local function WpnEnchant_OnEvent(icon, event, unit)
	-- this function must be declared after _OnUpdate because it references _OnUpdate from inside it.
	if not unit or unit == "player" then -- (not unit) covers calls from the timers set below
		icon.NextUpdateTime = 0
		
		local Slot = icon.Slot

		local EnchantName = GetWeaponEnchantName(Slot)
		icon.LastEnchantName = icon.EnchantName or icon.LastEnchantName
		icon.EnchantName = EnchantName

		if icon.Name == "" then
			icon.CorrectEnchant = true
		elseif EnchantName then
			icon.CorrectEnchant = icon.NameHash[strlowerCache[EnchantName]]
		elseif unit then
			-- we couldn't get an enchant name.
			-- Either we checked too early, or there is no enchant.
			-- Assume that we checked too early, and check again in a little bit.
			-- We check that unit is defined here because if we are calling from a timer, it will be false, and we dont want to endlessly chain timers.
			-- A single func calling itself in 2 timers will create perpetual performance loss to the point of lockup. (duh....)
			Type:ScheduleTimer(WpnEnchant_OnEvent, 0.1, icon)
			Type:ScheduleTimer(WpnEnchant_OnEvent, 1, icon)
		end

		local wpnTexture = GetInventoryItemTexture("player", Slot)

		icon:SetInfo("texture", wpnTexture or "Interface\\Icons\\INV_Misc_QuestionMark")

		if icon.HideUnequipped then
			if not wpnTexture then
				icon:SetInfo("alpha", 0)
				icon:SetScript("OnUpdate", nil)
				return
			end

			local itemID = GetInventoryItemID("player", Slot)
			if itemID then
				local _, _, _, _, _, _, _, _, invType = GetItemInfo(itemID)
				if invType == "INVTYPE_HOLDABLE" or invType == "INVTYPE_RELIC" or invType == "INVTYPE_SHIELD" then
					icon:SetInfo("alpha", 0)
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


	icon:SetInfo("texture; reverse",
		GetInventoryItemTexture("player", icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark",
		true
	)

	icon.EnchantName = nil
	icon.LastEnchantName = nil
	icon.CorrectEnchant = nil

	icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
	icon:Update()

	icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
	icon:SetScript("OnEvent", WpnEnchant_OnEvent)
	icon:SetUpdateMethod("manual")
	icon:OnEvent(nil, "player")
end

function Type:GetNameForDisplay(icon, data, doInsertLink)
	return icon.LastEnchantName or data or icon.EnchantName
end

function Type:GetIconMenuText(ics)
	local text = ""
	if ics.WpnEnchantType == "MainHandSlot" or not ics.WpnEnchantType then
		text = INVTYPE_WEAPONMAINHAND
	elseif ics.WpnEnchantType == "SecondaryHandSlot" then
		text = INVTYPE_WEAPONOFFHAND
	elseif ics.WpnEnchantType == "RangedSlot" then
		text = INVTYPE_THROWN
	end
	
	text = text .. " - " .. L["ICONMENU_WPNENCHANT"]

	local tooltip =	""--(data.Name and data.Name ~= "" and data.Name .. "\r\n" or "")

	return text, tooltip
end

Type:Register()