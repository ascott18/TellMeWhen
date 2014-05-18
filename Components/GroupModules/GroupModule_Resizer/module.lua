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


TMW:NewClass("GroupModule_Resizer", "GroupModule", "Resizer_Generic"){
	tooltipTitle = L["RESIZE"],
	
	METHOD_EXTENSIONS = {
		OnImplementIntoGroup = function(self)
			local group = self.group
			
			local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
			
			if not GroupModule_GroupPosition then
				error("Implementing GroupModule_Resizer (or a derivative) requies that GroupModule_GroupPosition (or a derivative) already be implemented.")
			end
		
			self.resizeButton:SetFrameLevel(group:GetFrameLevel() + 3)
			
			self.resizeButton.__noWrapTooltipText = true
			TMW:TT(self.resizeButton, self.tooltipTitle, self.tooltipText .. "\r\n" .. L["RESIZE_TOOLTIP_CHANGEDIMS"], 1, 1)
		end,

		StartSizing = function(resizeButton)
			local self = resizeButton.module
			local group = self.group

			self.oldColumns, self.oldRows = group.Columns, group.Rows

			if self.button == "RightButton" then
				group:ClearAllPoints()
				group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.oldX, self.oldY)
			end
		end,
	},
	
	OnEnable = function(self)
		self:Show()
		self:ShowTexture()
	end,
	
	OnDisable = function(self)
		-- Don't hide if we are dragging, because then the OnMouseUp script won't fire when we finish.
		-- This module is never really being disabled unless we are LockToggle()-ing TMW,
		-- and we probably aren't dragging anything when that happens.
		if not self.resizeButton:GetScript("OnUpdate") then
			self:Hide()
		end
	end,

	StopSizing = function(resizeButton)
		local self = resizeButton.module
		local group = self.group
		
		resizeButton:SetScript("OnUpdate", nil)
	
		local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
		GroupModule_GroupPosition:UpdatePositionAfterMovement()
		
		group:Setup()
		
		TMW.IE:NotifyChanges()
	end,

	SizeUpdate_RightButton = function(resizeButton)
		local self = resizeButton.module
		local group = self.group

		local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()

		-- Calculate new number of columns and groups:
		local std_newWidth = std_cursorX - self.std_oldLeft
		local ratio_SizeChangeX = std_newWidth/self.std_oldWidth
		local newColumns = floor(self.oldColumns * ratio_SizeChangeX + 0.5)
		newColumns = min(TELLMEWHEN_MAXROWS, max(1, newColumns))
		
		local std_newHeight = self.std_oldTop - std_cursorY
		local ratio_SizeChangeY = std_newHeight/self.std_oldHeight
		local newRows = floor(self.oldRows * ratio_SizeChangeY + 0.5)
		newRows = min(TELLMEWHEN_MAXROWS, max(1, newRows))
		
		if newColumns ~= group.Columns or newRows ~= group.Rows then
			local gs = group:GetSettings()

			local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
			GroupModule_GroupPosition:UpdatePositionAfterMovement()


			local GroupModule_IconPosition = group:GetModuleOrModuleChild("GroupModule_IconPosition")
			GroupModule_IconPosition:AdjustIconsForModNumRowsCols(newRows - group.Rows, newColumns - group.Columns)


			gs.Rows = newRows
			gs.Columns = newColumns
	
			group:Setup()

		end
	end,
}
