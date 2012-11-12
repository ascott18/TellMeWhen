

-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print
	

local TimerBar_BarDisplay = TMW:NewClass("IconModule_TimerBar_BarDisplay", "IconModule_TimerBar")

TimerBar_BarDisplay:RegisterIconDefaults{
	BarDisplay_BarGCD		= false,
}

TimerBar_BarDisplay:RegisterConfigPanel_ConstructorFunc(210, "TellMeWhen_TimerBar_BarDisplay_Settings", function(self)
	self.Header:SetText(L["CONFIGPANEL_TIMERBAR_BARDISPLAY_HEADER"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 2,
		{
			setting = "BarDisplay_BarGCD",
			title = TMW.L["ICONMENU_ALLOWGCD"],
			tooltip = TMW.L["ICONMENU_ALLOWGCD_DESC"],
		},
	})
end)

function TimerBar_BarDisplay:SetupForIcon(sourceIcon)
	self.Invert = false
	self.BarGCD = sourceIcon.BarDisplay_BarGCD
	self.Offset = 0
	if not sourceIcon.typeData then
		error("sourceIcon.typeData was nil. Why did this happen? (Please tell Cybeloras)")
	end
	self:SetColors(sourceIcon.typeData.Colors.CBS, sourceIcon.typeData.Colors.CBC)--TODO: this module needs the option to be able to color itself
	
	self:UpdateValue(1)
end

TimerBar_BarDisplay:SetIconEventListner("TMW_ICON_SETUP_POST", function(Module, icon)
	if TMW.Locked then
		Module:UpdateTable_Register()
		
		Module.bar:SetAlpha(.9)
	else
		Module:UpdateTable_Unregister()
		
		Module.bar:SetValue(Module.Max)
		Module.bar:SetAlpha(.6)
		local co = Module.completeColor			
		Module.bar:SetStatusBarColor(
			co.r,
			co.g,
			co.b,
			co.a
		)
	end
end)
