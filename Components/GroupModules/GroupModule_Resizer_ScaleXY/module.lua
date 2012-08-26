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

TMW:NewClass("GroupModule_Resizer_ScaleXY", "GroupModule_Resizer"){
	tooltipText = L["RESIZE_TOOLTIP_SCALEXY"],
	
	SizeUpdate = function(resizeButton)
		--[[ Notes:
		--	arg1 (self) is resizeButton
			
		--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
			More specifically, it means that it does not depend on the scale of either the group nor UIParent.
		]]
		local self = resizeButton.module
		
		local group = self.group
		local gs = group:GetSettings()
		
		local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()
		
		-- Calculate & set new scale:
		local std_newWidth = std_cursorX - self.std_oldLeft
		local ratio_SizeChangeX = std_newWidth/self.std_oldWidth
		local newScaleX = ratio_SizeChangeX*self.oldScale
		
		local std_newHeight = self.std_oldTop - std_cursorY
		local ratio_SizeChangeY = std_newHeight/self.std_oldHeight
		local newScaleY = ratio_SizeChangeY*self.oldScale
		
		--[[
			Holy shit. Look at this wicked sick dimensional analysis:
			
			std_newHeight	oldScale
			------------- X	-------- = newScale
			std_oldHeight	    1

			'std_Height' cancels out 'std_Height', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
			I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
			(which is why I am rewriting it right now)
		]]
		
		local newScale
		if IsControlKeyDown() then
			-- Uses the smaller of the two scales.
			newScale = min(newScaleX, newScaleY)
			newScale = max(0.6, newScale)
		else
			-- Uses the larger of the two scales.
			newScale = max(0.6, newScaleX, newScaleY)
		end

		-- Set the scale that we just determined.
		gs.Scale = newScale
		group:SetScale(newScale)

		
		-- We have all the data needed to find the new position of the group.
		-- It must be recalculated because otherwise it will scale relative to where it is anchored to,
		-- instead of being relative to the group's top left corner, which is what it is supposed to be.
		-- I don't remember why this calculation here works, so lets just leave it alone.
		
		-- Note that it will be re-re-calculated once we are done resizing,
		-- and this data will be intercepted by GroupModule_GroupPosition
		local newX = self.oldX * self.oldScale / newScale
		local newY = self.oldY * self.oldScale / newScale
		
		group:ClearAllPoints()
		group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
	end
}
