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
local error = error
	

local Module = TMW:NewClass("IconModule_IconEventClickHandler", "IconModule")
	
function Module:OnNewInstance_IconEventClickHandler(icon)
	icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

Module:SetIconScriptHandler("OnClick", function(Module, icon, button)
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
	
Module:RegisterIconEvent{	-- OnLeftClick
	name = "OnLeftClick",
	text = L["SOUND_EVENT_ONLEFTCLICK"],
	desc = L["SOUND_EVENT_ONLEFTCLICK_DESC"],
}
Module:RegisterIconEvent{	-- OnRightClick
	name = "OnRightClick",
	text = L["SOUND_EVENT_ONRIGHTCLICK"],
	desc = L["SOUND_EVENT_ONRIGHTCLICK_DESC"],
}



