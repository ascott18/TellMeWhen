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
	

TMW:NewClass("Resizer_Generic"){
	
	OnNewInstance_Resizer = function(self, parent)
		self.parent = parent
		
		assert(self.SizeUpdate, ("%q cannot be instantiated. You must derive a class from it so that you can define a SizeUpdate method."):format(self.className))
		
		self.resizeButton = CreateFrame("Button", nil, parent, "TellMeWhen_ResizeButton")
		
		-- Default module state is disabled, but default frame state is shown,
		-- so initially we need to hide the button so that the two states agree with eachother.
		self.resizeButton:Hide()
		
		self.resizeButton.module = self
		
		self.resizeButton:SetScript("OnMouseDown", self.StartSizing)
		self.resizeButton:SetScript("OnMouseUp", self.StopSizing)
		
		-- A new function is requied for each resizeButton/parent combo because it has to be able to reference both.
		parent:HookScript("OnSizeChanged", function(parent)
			local scale = 1.6 / parent:GetEffectiveScale()
			scale = max(scale, 0.6)
			self.resizeButton:SetScale(scale)
		end)
	end,

	Show = function(self)
		self.resizeButton:Show()
	end,
	Hide = function(self)
		self.resizeButton:Hide()
	end,
	
	GetStandardizedCoordinates = function(self)
		local parent = self.parent
		local scale = parent:GetEffectiveScale()
		
		return
			parent:GetLeft()*scale,
			parent:GetRight()*scale,
			parent:GetTop()*scale,
			parent:GetBottom()*scale
	end,
	GetStandardizedCursorCoordinates = function(self)
		-- This method is rather pointless (its just a wrapper),
		-- but having consistency is nice so that I don't have to remember if the coords returned
		-- are comparable to other Standardized coordinates/sizes
		return GetCursorPosition()    
	end,
	GetStandardizedSize = function(self)
		local parent = self.parent
		local x, y = parent:GetSize()
		local scale = parent:GetEffectiveScale()
		
		return x*scale, y*scale
	end,
	
	StartSizing = function(resizeButton, button)
		local self = resizeButton.module
		local parent = self.parent
		
		self.std_oldLeft, self.std_oldRight, self.std_oldTop, self.std_oldBottom = self:GetStandardizedCoordinates()
		self.std_oldWidth, self.std_oldHeight = self:GetStandardizedSize()
		
		self.oldScale = parent:GetScale()
		self.oldUIScale = UIParent:GetScale()
		self.oldEffectiveScale = parent:GetEffectiveScale()
		
		self.oldX, self.oldY = parent:GetLeft(), parent:GetTop()

		self.button = button
		
		if button == "RightButton" and self.SizeUpdate_RightButton then
			resizeButton:SetScript("OnUpdate", self.SizeUpdate_RightButton)
		else
			resizeButton:SetScript("OnUpdate", self.SizeUpdate)
		end
	end,
	
	StopSizing = function(resizeButton)
		resizeButton:SetScript("OnUpdate", nil)
	end,
}
