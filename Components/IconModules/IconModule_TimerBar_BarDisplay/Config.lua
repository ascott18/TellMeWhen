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

local get = TMW.get
local CI = TMW.CI


local Module = TMW.Classes.IconModule_TimerBar_BarDisplay

TMW:NewClass("SettingTimerBar_BarDisplay_ColorButton", "Button", "SettingFrameBase"){
	
	OnCreate = function(self)
		assert(self.background and self.text and self:GetNormalTexture(), 
			"This setting frame doesn't inherit from the thing that it should have inherited from")

		self.text:SetText(get(self.data.label or self.data.title))
	end,
	
	OnClick = function(self, button)
		local prevColor = CI.ics[self.setting]
		self.prevColor = prevColor

		self:GenerateMethods()

		ColorPickerFrame.func = self.colorFunc
		ColorPickerFrame.opacityFunc = self.colorFunc
		ColorPickerFrame.cancelFunc = self.cancelFunc

		ColorPickerFrame:SetColorRGB(prevColor.r, prevColor.g, prevColor.b)
		ColorPickerFrame.hasOpacity = true
		ColorPickerFrame.opacity = 1 - prevColor.a

		ColorPickerFrame:Show()
	end,

	-- We have to do this for these to have access to self.
	GenerateMethods = function(self)
		self.colorFunc = function()
			local ics = CI.ics

			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1 - OpacitySliderFrame:GetValue()

			ics[self.setting] = {r=r, g=g, b=b, a=a}

			self:ReloadSetting()

			TMW.IE:ScheduleIconSetup()
		end

		self.cancelFunc = function()
			CI.ics[self.setting] = self.prevColor

			self:ReloadSetting()

			TMW.IE:ScheduleIconSetup()
		end

		self.GenerateMethods = TMW.NULLFUNC
	end,

	ReloadSetting = function(self)
		local icon = CI.icon
		if icon then
			local c = icon:GetSettings()[self.setting]

			self:GetNormalTexture():SetVertexColor(c.r, c.g, c.b, 1)
			self.background:SetAlpha(c.a)

			self:CheckInteractionStates()
		end
	end,
}


TMW.IconDragger:RegisterIconDragHandler(250, -- Copy Bar Colors
	function(IconDragger, info)
		local srcicon = IconDragger.srcicon
		local desticon = IconDragger.desticon


		if desticon and srcicon:GetModuleOrModuleChild(Module.className) and desticon:GetModuleOrModuleChild(Module.className) then
			info.text = L["ICONMENU_COPYCOLORS_BARDISPLAY"]
			info.tooltipTitle = info.text
			info.tooltipText = L["ICONMENU_COPYCOLORS_BARDISPLAY_DESC"]:format(
				srcicon:GetIconName(true), desticon:GetIconName(true))

			return true
		end
	end,
	function(IconDragger)
		-- copy the settings
		local srcics = IconDragger.srcicon:GetSettings()
		local destics = IconDragger.desticon:GetSettings()

		for i, setting in TMW:Vararg("StartColor", "MiddleColor", "CompleteColor") do
			setting = "BarDisplay_" .. setting
			destics[setting] = TMW:CopyWithMetatable(srcics[setting])
		end

		destics.BarDisplay_EnableColors = srcics.BarDisplay_EnableColors
	end
)

TMW.HELP:NewCode("COLOR_COPY_DRAG", 100, true)
