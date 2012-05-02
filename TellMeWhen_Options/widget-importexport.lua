--[[-----------------------------------------------------------------------------
Import/Export Box Widget
-------------------------------------------------------------------------------]]
local Type, Version = "TMW-ImportExport", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local dummyfunc = function() end

local methods = {
	["OnAcquire"] = function(self)
		-- height is controlled by SetLabel
		self:SetWidth(200)
		self:SetDisabled(false)
	end,
	
	["OnRelease"] = function(self)
		self:ClearFocus()
	end,
	
	["SetDisabled"] = dummyfunc,
	
	["SetText"] = dummyfunc,
	
	["GetText"] = function(self, text)
		return self.editbox:GetText()
	end,
	
	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,-18)
			self:SetHeight(44)
			self.alignoffset = 40
		else
			self.label:SetText("")
			self.label:Hide()
			self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,0)
			self:SetHeight(26)
			self.alignoffset = 22
		end
	end,
	
	["ClearFocus"] = function(self)
		self.editbox:ClearFocus()
	end,
	
	["SetFocus"] = function(self)
		self.editbox:SetFocus()
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local num  = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetHeight(26)
	frame:Hide()
	
	local editbox = CreateFrame("EditBox", "TellMeWhen_ImpExpBox"..num, frame, "TellMeWhen_ExportBoxTemplate")
	--editbox:SetPoint("BOTTOMLEFT", 6, 0)
	editbox:SetPoint("TOPLEFT", 6, 0)
	editbox:SetPoint("RIGHT", -18, 0)
	editbox.IsImportExportWidget = true
	
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 0, -2)
	label:SetPoint("TOPRIGHT", 0, -2)
	label:SetJustifyH("LEFT")
	label:SetHeight(18)
	
	local widget = {
		alignoffset = 30,
		editbox     = editbox,
		frame       = frame,
		label       = label,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	editbox.obj = widget
	
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)


