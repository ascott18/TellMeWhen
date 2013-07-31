

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
	

local TimerBar_BarDisplay = TMW:NewClass("IconModule_TimerBar_BarDisplay", "IconModule_TimerBar")

TimerBar_BarDisplay:RegisterIconDefaults{
	BarDisplay_Invert			= false,
	BarDisplay_BarGCD			= false,
	BarDisplay_FakeMax			= 0,
	BarDisplay_StartColor		= { r=1, g=0, b=0, a=1 },
	BarDisplay_MiddleColor		= { r=1, g=1, b=0, a=1 },
	BarDisplay_CompleteColor	= { r=0, g=1, b=0, a=1 },
	BarDisplay_EnableColors		= false,
}

TimerBar_BarDisplay:RegisterConfigPanel_XMLTemplate(210, "TellMeWhen_BarDisplayBarOptions")

function TimerBar_BarDisplay:SetupForIcon(sourceIcon)
	self.Invert = sourceIcon.BarDisplay_Invert
	self.BarGCD = sourceIcon.BarDisplay_BarGCD
	self.Offset = 0

	if self.Invert or sourceIcon.BarDisplay_FakeMax == 0 then
		self.FakeMax = nil
	else
		self.FakeMax = sourceIcon.BarDisplay_FakeMax
	end

	if sourceIcon.BarDisplay_EnableColors then
		self:SetColors(
			sourceIcon.BarDisplay_StartColor,
			sourceIcon.BarDisplay_MiddleColor,
			sourceIcon.BarDisplay_CompleteColor)
	else
		self:SetColors(
			sourceIcon.typeData.Colors.CBS,
			sourceIcon.typeData.Colors.CBM,
			sourceIcon.typeData.Colors.CBC)
	end
	
	self:UpdateValue(1)
end

TimerBar_BarDisplay:SetIconEventListner("TMW_ICON_SETUP_POST", function(Module, icon)
	if TMW.Locked then
		Module:UpdateTable_Register()
		
		Module.bar:SetAlpha(.95)
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
