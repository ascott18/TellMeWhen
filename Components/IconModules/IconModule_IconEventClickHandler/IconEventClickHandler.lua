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
	

local Module = TMW:NewClass("IconModule_IconEventClickHandler", "IconModule")
Module:SetAllowanceForType("", false)
Module.dontInherit = true

Module:RegisterIconEvent(91, "OnLeftClick", {
	text = L["SOUND_EVENT_ONLEFTCLICK"],
	desc = L["SOUND_EVENT_ONLEFTCLICK_DESC"],
})
Module:RegisterIconEvent(92, "OnRightClick", {
	text = L["SOUND_EVENT_ONRIGHTCLICK"],
	desc = L["SOUND_EVENT_ONRIGHTCLICK_DESC"],
})

Module:PostHookMethod("OnImplementIntoIcon", function(self, icon)
	local EventHandlersSet = icon.EventHandlersSet
	
	if EventHandlersSet.OnLeftClick or EventHandlersSet.OnRightClick then
		self:Enable()
	else
		self:Disable()
	end
end)

function Module:OnEnable()
	self.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function Module:OnDisable()
	-- No reason to unregister from clicks.
	-- Would just end up interfering with something else that needs clicks to be registered.
end

Module:SetIconEventListner("TMW_ICON_SETUP_POST", function(Module, icon)
	-- This only runs if the module is enabled and we actually need click interation on the icon so that it can handle the events as needed.
	
	icon:EnableMouse(1)
end)

Module:SetScriptHandler("OnClick", function(Module, icon, button)
	if TMW.Locked then
		if button == "LeftButton" and icon.EventHandlersSet.OnLeftClick then
			icon:QueueEvent("OnLeftClick")
			icon:ProcessQueuedEvents()
		elseif button == "RightButton" and icon.EventHandlersSet.OnRightClick then
			icon:QueueEvent("OnRightClick")
			icon:ProcessQueuedEvents()
		end
	end
end)



