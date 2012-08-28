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
IconContainer_Masque.isDefaultSkin = 1


if not LMB then
	-- IconModule_IconContainer_Masque will just be a clone of IconModule_IconContainer at this point.
	-- No need to load any of the Masque-handling code it Masque isn't installed, so just leave it as a clone.
	return
end


do
	-- I absolutely hate that this exists.
	-- But, if it doesn't, when switching profiles or skins or a whole shitload of other stuff,
	-- icons will end up looking like total shit. I almost regret ever implementing Masque into TMW.
	-- Having it implemented is almost worse than the bombardment of requests to have it implemented.
	
	local meta = getmetatable(LMB:Group("TellMeWhen")).__index

	if meta and meta.Skin and meta.Disable and meta.Enable then
		local function hook(self)
			if self and self.Addon == "TellMeWhen" then
				TMW:ScheduleUpdate(.2)
			end
		end

		hooksecurefunc(meta, "Skin", hook)
		hooksecurefunc(meta, "Disable", hook)
		hooksecurefunc(meta, "Enable", hook)
		hooksecurefunc(meta, "Update", hook)
		hooksecurefunc(meta, "ReSkin", hook)
	end
end

function IconContainer_Masque:OnNewInstance_IconContainer_Masque(icon)
	self.lmbGroup = LMB:Group("TellMeWhen", L["fGROUP"]:format(icon.group:GetID()))
end

function IconContainer_Masque:SetupForIcon(icon)
	if icon ~= self.icon then
		local icnt = icon.normaltex
		local iconnt = self.icon.normaltex
		if icnt and iconnt then
			iconnt:SetVertexColor(icnt:GetVertexColor())
		end
	end
end

IconContainer_Masque:ExtendMethod("OnEnable", function(self)
	local icon = self.icon
	local container = self.container
	
	-- I really really hate the fact that this exists. But, oh well. At least it works more than 26.8% of the time.
	icon.normaltex = container.__MSQ_NormalTexture or container:GetNormalTexture()
	
	self.isDefaultSkin = nil
	
	local lmbGroup = self.lmbGroup
	lmbGroup:AddButton(container, icon.lmbButtonData)
	
	if lmbGroup.Disabled or (lmbGroup.db and lmbGroup.db.Disabled) then
		if icon.normaltex and not icon.normaltex:GetTexture() then
			self.isDefaultSkin = 1
		end
	end
end)

IconContainer_Masque:ExtendMethod("OnDisable", function(self)
	self.lmbGroup:RemoveButton(self.container, true)
	
	self.isDefaultSkin = 1
end)