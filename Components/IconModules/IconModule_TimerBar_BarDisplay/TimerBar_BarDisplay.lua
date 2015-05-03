

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


TimerBar_BarDisplay:PostHookMethod("OnEnable", function(self)
	local icon = self.icon
	local attributes = icon.attributes
	self.Invert = self.Invert_base

	self:VALUE(icon, attributes.value, attributes.maxValue, attributes.valueColor)
end)

function TimerBar_BarDisplay:GetValue()
	-- returns value, doTerminate

	local duration = self.duration

	if duration then
		-- Display a timer.
		if self.Invert then
			if duration == 0 then
				return self.Max, true
			else
				local value = TMW.time - self.start + self.Offset
				return value, value >= self.Max
			end
		else
			if duration == 0 then
				return 0, true
			else
				local value = duration - (TMW.time - self.start) + self.Offset
				return value, value <= 0
			end
		end

	elseif self.value then
		-- Display a set value.
		if self.Invert then
			return self.value + self.Offset, false
		else
			return self.Max - self.value + self.Offset, false
		end
	else
		return 0, true
	end
end

function TimerBar_BarDisplay:VALUE(icon, value, maxValue, valueColor)
	if value and maxValue then
		self.duration = nil
		self.start = nil
		self.Invert = not self.Invert_base

		self.value = value

		local oldMax = self.Max
		self.Max = self.FakeMax or maxValue
		if oldMax ~= self.Max then
			self.bar:SetMinMaxValues(0, self.Max)
		end

		self:SetupColors(self.sourceIcon, valueColor)

		-- Force an update here since it won't get updated if the color changes and the value doesnt.
		-- This is harmless, because 99% of the the time, the value has changed, so an update would be performed anyway.
		self:UpdateValue(true)
	end
end
TimerBar_BarDisplay:SetDataListner("VALUE")

function TimerBar_BarDisplay:SetupColors(icon, valueColor)
	icon = icon or self.icon

	if icon.BarDisplay_EnableColors then
		self:SetColors(
			icon.BarDisplay_StartColor,
			icon.BarDisplay_MiddleColor,
			icon.BarDisplay_CompleteColor)

	elseif valueColor then
		if type(valueColor) == "table" and #valueColor == 3 then
			self:SetColors(unpack(valueColor))
		else
			self:SetColors(
				valueColor,
				valueColor,
				valueColor)
		end
	else
		self:SetColors(
			icon.typeData.Colors.CBS,
			icon.typeData.Colors.CBM,
			icon.typeData.Colors.CBC)
	end
end

function TimerBar_BarDisplay:SetupForIcon(sourceIcon)
	self.Invert_base = sourceIcon.BarDisplay_Invert
	self.Invert = self.Invert_base
	if self.value then
		self.Invert = not self.Invert_base
	end
	
	self.BarGCD = sourceIcon.BarDisplay_BarGCD
	if sourceIcon.typeData.hasNoGCD then
		self.BarGCD = true
	end

	self.Offset = 0

	if self.Invert_base or sourceIcon.BarDisplay_FakeMax == 0 then
		self.FakeMax = nil
	else
		self.FakeMax = sourceIcon.BarDisplay_FakeMax
	end

	self.sourceIcon = sourceIcon
	self:SetupColors(sourceIcon, sourceIcon.attributes.valueColor)
	
	self:UpdateValue(true)
end

TimerBar_BarDisplay:SetIconEventListner("TMW_ICON_SETUP_POST", function(Module, icon)
	if TMW.Locked then
		Module:UpdateTable_Register()
		
	else
		Module:UpdateTable_Unregister()
		
		Module.bar:SetValue(Module.Max)

		local co = Module.completeColor
		Module.bar:SetStatusBarColor(
			co.r,
			co.g,
			co.b,
			co.a
		)
	end
end)
