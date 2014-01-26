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
