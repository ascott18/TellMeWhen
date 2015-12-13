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

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local type = type
local bitband = bit.band

local OnGCD = TMW.OnGCD

local ColorMSQ, OnlyMSQ

local Texture_Colored = TMW:NewClass("IconModule_Texture_Colored", "IconModule_Texture")

function Texture_Colored:SetupForIcon(icon)
	self.ShowTimer = icon.ShowTimer
	self:UPDATE(icon)
end

local COLOR_UNLOCKED = {
	Color = "ffffffff",
	Gray = false,
}
function Texture_Colored:UPDATE(icon)
	local state = icon.attributes.state


	local color
	if not TMW.Locked or state == 0 or not state then
		color = "ffffffff"
	elseif state then
		color = icon.States[state].Color
	end
	
	local texture = self.texture
	local c = TMW:StringToCachedRGBATable(color)
	
	if not (LMB and OnlyMSQ) then
		texture:SetVertexColor(c.r, c.g, c.b, 1)
	else
		texture:SetVertexColor(1, 1, 1, 1)
	end

	texture:SetDesaturated(c.flags and c.flags.desaturate or false)
	
	if LMB and ColorMSQ then
		local iconnt = icon.normaltex
		if iconnt then
			iconnt:SetVertexColor(c.r, c.g, c.b, 1)
		end
	end
end

Texture_Colored:SetDataListner("STATE", Texture_Colored.UPDATE)


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ColorMSQ = TMW.db.profile.ColorMSQ
	OnlyMSQ = TMW.db.profile.OnlyMSQ
end)