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
	

local Module = TMW:NewClass("IconModule_IconDragger", "IconModule")

function Module:OnNewInstance_IconDragger(icon)
	icon:RegisterForDrag("LeftButton", "RightButton")
end

Module:SetScriptHandler("OnMouseDown", function(Module, icon)
	if not TMW.Locked then
		local ID = TMW.ID
		if not ID then return end
		ID.DraggingInfo = nil
		ID.F:Hide()
		ID.IsDragging = nil
	end
end)

Module:SetScriptHandler("OnDragStart", function(Module, icon, button)
	if not TMW.Locked and button == "RightButton" and TMW.ID then
		TMW.ID:Start(icon)
	end
end)

Module:SetScriptHandler("OnReceiveDrag", function(Module, icon)
	if TMW.ID then
		TMW.ID:CompleteDrag("OnReceiveDrag", icon)
	end
end)

Module:SetScriptHandler("OnDragStop", function(Module, icon)
	if TMW.ID and TMW.ID.IsDragging then
		TMW.ID:CompleteDrag("OnDragStop")
	end
end)

