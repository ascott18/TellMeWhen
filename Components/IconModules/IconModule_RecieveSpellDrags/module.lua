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
	

local Module = TMW:NewClass("IconModule_RecieveSpellDrags", "IconModule")

Module:SetScriptHandler("OnClick", function(Module, icon, button)
	if not TMW.Locked and TMW.ID and button == "LeftButton" then
		TMW.ID:SpellItemToIcon(icon)
	end
end)

Module:SetScriptHandler("OnReceiveDrag", function(Module, icon, button)
	if not TMW.Locked and TMW.ID then
		TMW.ID:SpellItemToIcon(icon)
	end
end)


