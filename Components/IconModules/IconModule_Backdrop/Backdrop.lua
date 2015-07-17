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

local LSM = LibStub("LibSharedMedia-3.0")

	
local Backdrop = TMW:NewClass("IconModule_Backdrop", "IconModule")

Backdrop:RegisterIconDefaults{
	BackdropColor		= { r=0.2, g=0.2, b=0.2, a=0.5 },
}

TMW:RegisterUpgrade(72411, {
	icon = function(self, ics)
		-- These values were accidentally switched in code.
		-- Swap them when upgrading to keep the user's old color.
		ics.BackdropColor.g, ics.BackdropColor.b =
		ics.BackdropColor.b, ics.BackdropColor.g
	end,
})

TMW:RegisterUpgrade(72330, {
	icon = function(self, ics)
		ics.BackdropColor.a = ics.BackdropAlpha or 0.5
	end,
})


Backdrop:RegisterConfigPanel_XMLTemplate(216, "TellMeWhen_BackdropOptions")

--Backdrop:RegisterAnchorableFrame("Backdrop")

function Backdrop:OnNewInstance(icon)
	self.container = CreateFrame("Frame", nil, icon)
	self.backdrop = self.container:CreateTexture(self:GetChildNameBase() .. "Backdrop", "BACKGROUND", nil, -8)
	self.backdrop:SetAllPoints(self.container)
	self.backdrop:Show()
	--self:SetSkinnableComponent("NULL", self.backdrop)
end

function Backdrop:OnEnable()
	self.container:Show()
end
function Backdrop:OnDisable()
	self.container:Hide()
end

function Backdrop:SetBorder(size, r, g, b, a)
	if not self.border then
		self.border = CreateFrame("Frame", nil, self.container, "TellMeWhen_GenericBorder")
	end

	self.border:SetSize(size)
	self.border:SetColor(r, g, b, a)
end

function Backdrop:SetupForIcon(icon)
	self.backdrop:SetTexture(LSM:Fetch("statusbar", TMW.db.profile.TextureName))
	
	local c = icon.BackdropColor
	self.backdrop:SetVertexColor(c.r, c.g, c.b, 1)
	self.backdrop:SetAlpha(c.a)
end
	