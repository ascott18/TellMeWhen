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


local Alpha = TMW:NewClass("IconModule_Alpha", "IconModule")

function Alpha:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	
	self:ALPHA(icon, attributes.alpha)
	self:ALPHAOVERRIDE(icon, attributes.alphaOverride)
end

function Alpha:ALPHA(icon, alpha)
	if (not icon.FadeHandlers or not icon.FadeHandlers[1]) and not icon.attributes.alphaOverride then
		icon:SetAlpha(icon.FakeHidden and 0 or alpha)
	end
end
Alpha:SetDataListner("ALPHA")

Alpha:RegisterIconDefaults{
	FakeHidden				= false,
}

function Alpha:ALPHAOVERRIDE(icon, alphaOverride)
	if alphaOverride then
		icon:SetAlpha(alphaOverride)
	else
		self:ALPHA(icon, icon.attributes.alpha)
	end
end
Alpha:SetDataListner("ALPHAOVERRIDE")
	