-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L

local DogTag = LibStub("LibDogTag-3.0", true)
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local LSM = LibStub("LibSharedMedia-3.0")

local pairs, wipe = pairs, wipe

local Texts = TMW:NewClass("IconModule_Texts", "IconModule", "EssentialIconModule", "MasqueSkinnableIconModule")
function Texts:OnNewInstance(icon)
	self.kwargs = {}
	self.fontStrings = {}
	
	-- we need to make sure that all strings that are Masque skinnable are always created
	-- so that skinning isnt really weird and awkward.
	-- If Masque isn't installed, then don't bother - we will create them normally on demand.
	if LMB then
		for key in pairs(TMW.MasqueSkinnableTexts) do
			if key ~= "" then
				local fontString = self:CreateFontString(key)
				self:SetSkinnableComponent(key, fontString)
			end
		end
	end
end
function Texts:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	self:DOGTAGUNIT(icon, attributes.dogTagUnit)
end
function Texts:OnDisable()
	for i = 1, #self do
		local fontString = self[i]
		
		DogTag:RemoveFontString(fontString)			
		fontString:Hide()
	end
end
function Texts:CreateFontString(id)
	local icon = self.icon
	local fontString = icon:CreateFontString(nil, "ARTWORK", "NumberFontNormalSmall")
	self.fontStrings[id] = fontString
	return fontString
end
function Texts:SetupForIcon(sourceIcon)
	local icon = self.icon

	local Texts = sourceIcon:GetSettingsPerView().Texts
	local _, layoutSettings = sourceIcon:GetTextLayout()
	self.layoutSettings = layoutSettings
	self.Texts = Texts
	
	wipe(self.kwargs)
	self.kwargs.icon = sourceIcon.ID
	self.kwargs.group = sourceIcon.group.ID
	self.kwargs.unit = sourceIcon.attributes.dogTagUnit
	self.kwargs.color = TMW.db.profile.ColorNames
	
	for _, fontString in pairs(self.fontStrings) do
		DogTag:RemoveFontString(fontString)
		fontString:Hide()
	end
		
	if layoutSettings then				
		for fontStringID, fontStringSettings in TMW:InNLengthTable(layoutSettings) do
			local SkinAs = fontStringSettings.SkinAs
			fontStringID = self:GetFontStringID(fontStringID, fontStringSettings)
			
			local fontString = self.fontStrings[fontStringID] or self:CreateFontString(fontStringID)
			fontString:Show()
			fontString.settings = fontStringSettings
			
			fontString:SetWidth(fontStringSettings.ConstrainWidth and (icon.EssentialModuleComponents.texture or icon):GetWidth() or 0)
	
			if not LMB or SkinAs == "" then
				-- Position
				fontString:ClearAllPoints()
				local func = fontString.__MSQ_SetPoint or fontString.SetPoint
				func(fontString, fontStringSettings.point, icon, fontStringSettings.relativePoint, fontStringSettings.x, fontStringSettings.y)

				fontString:SetJustifyH(fontStringSettings.point:match("LEFT") or fontStringSettings.point:match("RIGHT") or "CENTER")
				
				-- Font
				fontString:SetFont(LSM:Fetch("font", fontStringSettings.Name), fontStringSettings.Size, fontStringSettings.Outline)
			end
		end
	end
	
	self:OnKwargsUpdated()
end
function Texts:GetFontStringID(fontStringID, fontStringSettings)
	local SkinAs = fontStringSettings.SkinAs
	if SkinAs ~= "" then
		fontStringID = SkinAs
	end
	return fontStringID
end
function Texts:OnKwargsUpdated()
	if self.layoutSettings then
		for fontStringID, fontStringSettings in TMW:InNLengthTable(self.layoutSettings) do
			local fontString = self.fontStrings[self:GetFontStringID(fontStringID, fontStringSettings)]
			if fontString then
				local styleString = ""
				if fontStringSettings.Outline == "OUTLINE" or fontStringSettings.Outline == "THICKOUTLINE" or fontStringSettings.Outline == "MONOCHROME" then
					styleString = styleString .. ("[%s]"):format(fontStringSettings.Outline)
				end	
				
				DogTag:AddFontString(fontString, self.icon, styleString .. self.Texts[fontStringID], "Unit;TMW", self.kwargs)
				DogTag:UpdateFontString(fontString)
			end
		end
	end
end

function Texts:DOGTAGUNIT(icon, dogTagUnit)
	self.kwargs.unit = dogTagUnit
	self:OnKwargsUpdated()
end
Texts:SetDataListner("DOGTAGUNIT")