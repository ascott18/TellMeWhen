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


TMW:NewClass("IconEditor_Resizer_ScaleX_SizeY", "Resizer_Generic"){
	tooltipText = L["RESIZE_TOOLTIP"],
	UPD_INTV = 1,
	tooltipTitle = L["RESIZE"],
	
	OnEnable = function(self)
		self:Show()
		self.resizeButton:HookScript("OnShow", function(self)
			self:SetFrameLevel(self:GetParent():GetFrameLevel() + 5)
		end)
		TMW:TT(self.resizeButton, self.tooltipTitle, self.tooltipText, 1, 1)
	end,
	
	OnDisable = function(self)
		self:Hide()
	end,	
	
	SizeUpdate = function(resizeButton)
		--[[ Notes:
		--	arg1 (self) is resizeButton
			
		--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
			More specifically, it means that it does not depend on the scale of either the parent nor UIParent.
		]]
		local self = resizeButton.module
		
		local parent = self.parent
		local uiScale = UIParent:GetScale()
		
		local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()

		
		
		-- Calculate and set new scale:
		local std_newWidth = abs(self.std_oldLeft - std_cursorX)
		local ratio_SizeChangeX = std_newWidth/self.std_oldWidth
		local newScale = ratio_SizeChangeX*self.oldScale
		newScale = max(0.4, newScale)
		--[[
			Holy shit. Look at this wicked sick dimensional analysis:
			
			std_newWidth	oldScale
			------------- X	-------- = newScale
			std_oldWidth	    1

			'std_Width' cancels out 'std_Width', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
			I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
			(which is why I am rewriting it right now)
		]]

		-- Set the scale that we just determined. This is critical because we have to parent:GetEffectiveScale()
		-- in order to determine the proper width, which depends on the current scale of the parent.
		parent:SetScale(newScale)
		TMW.IE.db.global.EditorScale = newScale
		
		
		-- We have all the data needed to find the new position of the parent.
		-- It must be recalculated because otherwise it will scale relative to where it is anchored to,
		-- instead of being relative to the parent's top left corner, which is what it is supposed to be.
		-- I don't remember why this calculation here works, so lets just leave it alone.
		-- Note that it will be re-re-calculated once we are done resizing.
		local newX = self.oldX * self.oldScale / newScale
		local newY = self.oldY * self.oldScale / newScale
		parent:ClearAllPoints()
		parent:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
		
		
		-- Calculate new width
		local std_newFrameHeight = abs(std_cursorY - self.std_oldTop)
		local newHeight = std_newFrameHeight/parent:GetEffectiveScale()
		newHeight = max(TMW.IE.CONST.IE_HEIGHT_MIN, newHeight)
		newHeight = min(TMW.IE.CONST.IE_HEIGHT_MAX, newHeight)
		
		parent:SetHeight(newHeight)
		TMW.IE.db.global.EditorHeight = newHeight
	end,
}