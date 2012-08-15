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

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))

local IconContainer_Masque = TMW:NewClass("IconModule_IconContainer_Masque", "IconModule_IconContainer")

function IconContainer_Masque:OnNewInstance_IconContainer_Masque(icon)
	if LMB then
		self.lmbGroup = LMB:Group("TellMeWhen", L["fGROUP"]:format(icon.group:GetID()))
	end
end

IconContainer_Masque:ExtendMethod("OnEnable", function(self)
	local icon = self.icon
	local container = self.container
	
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
end)

IconContainer_Masque:ExtendMethod("OnDisable", function(self)
	if LMB then
		self.lmbGroup:RemoveButton(self.container, true)
	end
	self.isDefaultSkin = 1
end)