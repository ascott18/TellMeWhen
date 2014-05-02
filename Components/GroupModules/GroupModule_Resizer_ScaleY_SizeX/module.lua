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


TMW:NewClass("GroupModule_Resizer_ScaleY_SizeX", "GroupModule_Resizer"){
	tooltipText = L["RESIZE_TOOLTIP_SCALEY_SIZEX"],
	UPD_INTV = 1,
	LastUpdate = 0,

	scale_min = 0.25,

	OnNewInstance_GroupModule_Resizer_ScaleY_SizeX = function(self)
		self:SetModes(self.MODE_SIZE, self.MODE_SCALE)
	end,

	SizeUpdated = function(self)
		local group = self.group
		local gs = group:GetSettings()
		local gspv = group:GetSettingsPerView()

		-- Scale
		gs.Scale = group:GetScale()


		local std_spacing = gspv.SpacingX*group:GetEffectiveScale()

		-- Width has already been set by SizeUpdate(). Get it with GetStandardizedSize().
		local std_newFrameWidth = self:GetStandardizedSize()
		local std_newWidth = (std_newFrameWidth + std_spacing)/gs.Columns - std_spacing
		local newWidth = std_newWidth/group:GetEffectiveScale()

		newWidth = max(gspv.SizeY, newWidth)
		gspv.SizeX = newWidth
		

		-- Update size settings for the group.
		-- This needs to be done before we :Setup() or otherwise bad things happen.
		local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
		GroupModule_GroupPosition:UpdatePositionAfterMovement()
			
		if self.LastUpdate <= TMW.time - self.UPD_INTV then
			-- Update the group completely very infrequently because of the high CPU usage.
			
			self.LastUpdate = TMW.time
		
			group:Setup()
		else
			-- Don't setup icons most of the time. Only setup the group.
			
			group:Setup(true)
		end

		self:HideTexture()
	end,
}
