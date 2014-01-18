-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local GetInventoryItemTexture, GetInventorySlotInfo, GetSpellTexture
	= GetInventoryItemTexture, GetInventorySlotInfo, GetSpellTexture
local pairs
	= pairs  
	
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

if not TMW.COMMON.SwingTimerMonitor then
	return
end

local SwingTimers = TMW.COMMON.SwingTimerMonitor.SwingTimers

local Type = TMW.Classes.IconType:New("swingtimer")
Type.name = L["ICONMENU_SWINGTIMER"]
Type.desc = L["ICONMENU_SWINGTIMER_DESC"]
Type.menuIcon = "Interface\\Icons\\INV_Gauntlets_04"
Type.hasNoGCD = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:RegisterIconDefaults{
	SwingTimerSlot			= "MainHandSlot",
}

if pclass == "HUNTER" then
	Type:RegisterConfigPanel_XMLTemplate(130, "TellMeWhen_AutoshootSwingTimerTip")
end

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_SWINGTIMER_SWINGING"],			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_SWINGTIMER_NOTSWINGING"],		},
})


Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_WeaponSlot", function(self)
	self.Header:SetText(TMW.L["ICONMENU_WPNENCHANTTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "SwingTimerSlot",
			value = "MainHandSlot",
			title = INVTYPE_WEAPONMAINHAND,
		},
		{
			setting = "SwingTimerSlot",
			value = "SecondaryHandSlot",
			title = INVTYPE_WEAPONOFFHAND,
		},
	})
end)



local function SwingTimer_OnEvent(icon, event, unit, _, _, _, spellID)
	if event == "UNIT_INVENTORY_CHANGED" then
		local wpnTexture = GetInventoryItemTexture("player", icon.Slot)
		icon:SetInfo("texture", wpnTexture or SpellTextures[15590])
	elseif event == "TMW_COMMON_SWINGTIMER_CHANGED" then
		icon.NextUpdateTime = 0
	end
end

local function SwingTimer_OnUpdate(icon, time)

	local SwingTimer = SwingTimers[icon.Slot]
	
	local ready = time - SwingTimer.startTime > SwingTimer.duration
	
	icon.NextUpdateTime = SwingTimer.startTime + SwingTimer.duration
	
	if ready then
		icon:SetInfo(
			"alpha; start, duration",
			icon.UnAlpha,
			0, 0
		)
	else
		icon:SetInfo(
			"alpha; start, duration",
			icon.Alpha,
			SwingTimer.startTime, SwingTimer.duration
		)
	end
end



function Type:Setup(icon)

	icon:SetInfo("texture", GetSpellTexture(75))
	
	icon.Slot = GetInventorySlotInfo(icon.SwingTimerSlot)

	local wpnTexture = GetInventoryItemTexture("player", icon.Slot)
	icon:SetInfo("texture", wpnTexture or SpellTextures[15590])
	
	
	TMW:RegisterCallback("TMW_COMMON_SWINGTIMER_CHANGED", SwingTimer_OnEvent, icon)
	icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
	
	icon:SetScript("OnEvent", SwingTimer_OnEvent)
	icon:SetUpdateMethod("manual")
	
	icon:SetUpdateFunction(SwingTimer_OnUpdate)
	
	
	icon:Update()
end


Type:Register(155)

