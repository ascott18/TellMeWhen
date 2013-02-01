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

-- The point of this module is to expose the icon itself to the
-- anchorable frames list.
	
local Self = TMW:NewClass("IconModule_Self", "IconModule")

Self:RegisterAnchorableFrame("Icon")

function Self:OnNewInstance(icon)
	_G[self:GetChildNameBase() .. "Icon"] = icon
end