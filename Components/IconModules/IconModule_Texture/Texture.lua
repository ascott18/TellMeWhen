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


	
local Texture = TMW:NewClass("IconModule_Texture", "IconModule")

function Texture:OnNewInstance(icon)
	self.texture = icon:CreateTexture(icon:GetName() .. "Texture", "BACKGROUND")
	self:SetSkinnableComponent("Icon", self.texture)
end

function Texture:OnEnable()
	self.texture:Show()
	self:SetEssentialModuleComponent("texture", self.texture)

	local icon = self.icon
	local attributes = icon.attributes
	self:TEXTURE(icon, attributes.texture)
end
function Texture:OnDisable()
	self.texture:Hide()
	self:SetEssentialModuleComponent("texture", nil)
end

function Texture:TEXTURE(icon, texture)
	self.texture:SetTexture(texture)
end
Texture:SetDataListner("TEXTURE")
	