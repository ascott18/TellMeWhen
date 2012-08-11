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

local IconContainer = TMW:NewClass("IconModule_IconContainer", "IconModule")

function IconContainer:OnNewInstance_IconContainer(icon)	
	local container = CreateFrame("Button", nil, icon)
	
	self.container = container
	
	container:EnableMouse(false)
end

function IconContainer:OnEnable()
	local icon = self.icon
	local container = self.container
	
	container:Show()
	
	container:SetFrameLevel(icon:GetFrameLevel())
end

function IconContainer:OnDisable()
	self.container:Hide()
end

IconContainer:RegisterEventHandlerData("Animations", 60, "ACTVTNGLOW", {
	-- GLOBALS: ActionButton_ShowOverlayGlow, ActionButton_HideOverlayGlow
	text = L["ANIM_ACTVTNGLOW"],
	desc = L["ANIM_ACTVTNGLOW_DESC"],
	Duration = true,
	Infinite = true,

	Play = function(icon, eventSettings)
		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = eventSettings.Infinite and math.huge or eventSettings.Duration,
		}
	end,

	OnUpdate = function(icon, table)
		if table.Duration - (TMW.time - table.Start) < 0 then
			icon:Animations_Stop(table)
		end
	end,
	OnStart = function(icon, table)
		local IconModule_IconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer")
		local container = IconModule_IconContainer.container
		
		ActionButton_ShowOverlayGlow(container)
		
		-- overlay is a field created by ActionButton_ShowOverlayGlow
		container.overlay:SetFrameLevel(icon:GetFrameLevel() + 3)
	end,
	OnStop = function(icon, table)
		local IconModule_IconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer")
		
		ActionButton_HideOverlayGlow(IconModule_IconContainer.container)
	end,
})


