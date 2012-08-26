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


TMW:NewClass("GroupModule_Resizer", "GroupModule", "Resizer_Generic"){
	tooltipTitle = L["RESIZE"],
	
	METHOD_EXTENSIONS = {
		OnImplementIntoGroup = function(self)
			local group = self.group
			
			local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
			
			if not GroupModule_GroupPosition then
				error("Implementing GroupModule_Resizer, or a derivative thereof, requies that GroupModule_GroupPosition, or a derivative thereof, be implemented. This may involve changing the implementation order of _Resizer.")
			end
		
			self.resizeButton:SetFrameLevel(group:GetFrameLevel() + 3)
			
			self.resizeButton.__noWrapTooltipText = true
			TMW:TT(self.resizeButton, self.tooltipTitle, self.tooltipText, 1, 1)
		end,
	},
	
	OnEnable = function(self)
		self:Show()
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
}
