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

local Masque = TMW:NewClass("IconModule_Masque", "IconModule")

function Masque:OnNewInstance(icon)	
	local container = CreateFrame("Button", nil, icon)
	self.container = container
	container:EnableMouse(false)
	if LMB then
		self.lmbGroup = LMB:Group("TellMeWhen", L["fGROUP"]:format(icon.group:GetID()))
	end
end

function Masque:OnEnable()
	local icon = self.icon
	local container = self.container
	container:SetFrameLevel(icon:GetFrameLevel())
	
	icon.normaltex = container.__MSQ_NormalTexture or container:GetNormalTexture()
	if LMB then
		self.isDefaultSkin = nil
		
		local lmbGroup = self.lmbGroup
		lmbGroup:AddButton(container, icon.lmbButtonData)
		
		if lmbGroup.Disabled or (lmbGroup.db and lmbGroup.db.Disabled) then
			if not icon.normaltex:GetTexture() then
				self.isDefaultSkin = 1
			end
		end
	else
		self.isDefaultSkin = 1
	end
end
function Masque:OnDisable()
	if LMB then
		self.lmbGroup:RemoveButton(self.container, true)
	end
	self.isDefaultSkin = 1
end