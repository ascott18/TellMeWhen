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
	
	SizeUpdate = function(resizeButton)
		--[[ Notes:
		--	arg1 (self) is resizeButton
			
		--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
			More specifically, it means that it does not depend on the scale of either the group nor UIParent.
		]]
		local self = resizeButton.module
		
		local group = self.group
		local gs = group:GetSettings()
		local gspv = group:GetSettingsPerView()
		
		local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()

		
		
		-- Calculate & set new scale:
		local std_newHeight = self.std_oldTop - std_cursorY
		local ratio_SizeChangeY = std_newHeight/self.std_oldHeight
		local newScale = ratio_SizeChangeY*self.oldScale
		newScale = max(0.25, newScale)
		--[[
			Holy shit. Look at this wicked sick dimensional analysis:
			
			std_newHeight	oldScale
			------------- X	-------- = newScale
			std_oldHeight	    1

			'std_Height' cancels out 'std_Height', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
			I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
			(which is why I am rewriting it right now)
		]]

		-- Set the scale that we just determined. This is critical because we have to group:GetEffectiveScale()
		-- in order to determine the proper width, which depends on the current scale of the group.
		gs.Scale = newScale
		group:SetScale(newScale)
		
		
		-- We have all the data needed to find the new position of the group.
		-- It must be recalculated because otherwise it will scale relative to where it is anchored to,
		-- instead of being relative to the group's top left corner, which is what it is supposed to be.
		-- I don't remember why this calculation here works, so lets just leave it alone.
		-- Note that it will be re-re-calculated once we are done resizing.
		local newX = self.oldX * self.oldScale / newScale
		local newY = self.oldY * self.oldScale / newScale
		group:ClearAllPoints()
		group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
		
		
		-- Calculate new width
		local std_newFrameWidth = std_cursorX - self.std_oldLeft
		local std_spacing = gspv.SpacingX*group:GetEffectiveScale()
		local std_newWidth = (std_newFrameWidth + std_spacing)/gs.Columns - std_spacing
		local newWidth = std_newWidth/group:GetEffectiveScale()
		newWidth = max(gspv.SizeY, newWidth)
		gspv.SizeX = newWidth
		
		if not self.LastUpdate or self.LastUpdate <= TMW.time - self.UPD_INTV then
			-- Update the group completely very infrequently because of the high CPU usage.
			
			self.LastUpdate = TMW.time
			
			-- This needs to be done before we :Setup() or otherwise bad things happen.
			local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
			GroupModule_GroupPosition:UpdatePositionAfterMovement()
		
			group:Setup()
		else
			-- Only do the things that will determine most of the group's appearance on every frame.
			
			group.viewData:Group_SetupMacroAppearance(group)
		end
	end,
}
