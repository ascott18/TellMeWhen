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
	

local Module = TMW:NewClass("IconModule_IconDragger", "IconModule")

function Module:OnNewInstance_IconDragger(icon)
	icon:RegisterForDrag("LeftButton", "RightButton")
end

Module:SetScriptHandler("OnMouseDown", function(Module, icon)
	local IconDragger = TMW.IconDragger
	
	if not TMW.Locked and IconDragger then		
		IconDragger.DraggingInfo = nil
		IconDragger.DraggerFrame:Hide()
		IconDragger.IsDragging = nil
	end
end)

Module:SetScriptHandler("OnDragStart", function(Module, icon, button)
	if not TMW.Locked and button == "RightButton" and TMW.IconDragger then
		TMW.IconDragger:Start(icon)
	end
end)

Module:SetScriptHandler("OnReceiveDrag", function(Module, icon)
	if TMW.IconDragger then
		TMW.IconDragger:CompleteDrag("OnReceiveDrag", icon)
	end
end)

Module:SetScriptHandler("OnDragStop", function(Module, icon)
	if TMW.IconDragger and TMW.IconDragger.IsDragging then
		TMW.IconDragger:CompleteDrag("OnDragStop")
	end
end)

