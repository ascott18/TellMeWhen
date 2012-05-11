-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local type = type

local ColorMSQ, OnlyMSQ

local Texture_Colored = TMW:NewClass("IconModule_Texture_Colored", "IconModule_Texture")

Texture_Colored:ExtendMethod("OnEnable", function(self)
	local icon = self.icon
	local attributes = icon.attributes
	self:COLOR(icon, attributes.color)	
end)

function Texture_Colored:COLOR(icon, color)
	local texture = self.texture
	local r, g, b, d
	if type(color) == "table" then
		r, g, b, d = color.r, color.g, color.b, color.Gray
	else
		r, g, b, d = color, color, color, false
	end
	
	if not (LMB and OnlyMSQ) then
		texture:SetVertexColor(r, g, b, 1)
	end
	texture:SetDesaturated(d)
	
	if LMB and ColorMSQ then
		local iconnt = icon.normaltex
		if iconnt then
			iconnt:SetVertexColor(r, g, b, 1)
		end
	end
end
Texture_Colored:SetDataListner("COLOR")


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ColorMSQ = TMW.db.profile.ColorMSQ
	OnlyMSQ = TMW.db.profile.OnlyMSQ
end)