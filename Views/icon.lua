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
local print = TMW.print

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))

local ceil = ceil

local View = TMW.Classes.IconView:New("icon")

local ICON_SIZE = 30

TMW.Defaults.profile.TextLayouts.icon1 = {
	Name = L["TEXTLAYOUTS_DEFAULTS_ICON1"],
	GUID = "icon1",
	NoEdit = true,
	n = 2,
	-- Default Layout 1
	{	-- [1] Bind
		x 	 		  	= -2,
		y 			 	= -2,
		point 		 	= "TOPLEFT",
		relativePoint	= "TOPLEFT",
		
		StringName		= L["TEXTLAYOUTS_DEFAULTS_BINDINGLABEL"],
		DefaultText		= "",
		SkinAs			= "HotKey",
	},
	{	-- [2] Stacks
		x 	 		  	= -2,
		y 	 		  	= 2,
		ConstrainWidth	= false,
		point			= "BOTTOMRIGHT",
		relativePoint	= "BOTTOMRIGHT",
		
		StringName		= L["TEXTLAYOUTS_DEFAULTS_STACKS"],
		DefaultText		= "[Stacks:Hide('0', '1')]",
		SkinAs			= "Count",
	},
}

View:RegisterIconDefaults{
	SettingsPerView = {
		icon = {
			TextLayout = "icon1",
			Texts = {
				"",
				"[Stacks:Hide('0', '1')]",
			}
		}
	}
}

View:RegisterGroupDefaults{
	SettingsPerView = {
		icon = {
			TextLayout = "icon1",
			SizeX = ICON_SIZE,
			SizeY = ICON_SIZE,
		}
	}
}

View:ImplementsModule("IconModule_Alpha", 10, function(Module, icon)
	Module:SetEssential(true)
end)
View:ImplementsModule("IconModule_CooldownSweep", 20, function(Module, icon)
	if icon.ShowTimer or icon.ShowTimerText then
		Module:Enable()
	end
	
	Module.cooldown:ClearAllPoints()
	Module.cooldown:SetSize(ICON_SIZE, ICON_SIZE)
	Module.cooldown:SetPoint("CENTER", icon)
end)
View:ImplementsModule("IconModule_Texture_Colored", 30, function(Module, icon)
	Module:SetEssential(true)
	
	Module.texture:ClearAllPoints()
	Module.texture:SetSize(ICON_SIZE, ICON_SIZE)
	Module.texture:SetPoint("CENTER", icon)
end)
View:ImplementsModule("IconModule_PowerBar_Overlay", 40, function(Module, icon)
	if icon.ShowPBar then
		Module:Enable()
	end
end)
View:ImplementsModule("IconModule_TimerBar_Overlay", 50, function(Module, icon)
	if icon.ShowCBar then
		Module:Enable()
	end
end)
View:ImplementsModule("IconModule_Texts", 60, function(Module, icon)
	Module:Enable()
end)
View:ImplementsModule("IconModule_Masque", 100, function(Module, icon)
	local Modules = icon.Modules
	local Masque = Module
	
	Masque:Enable()
	Masque.container:ClearAllPoints()
	Masque.container:SetAllPoints()	

	---------- Skin-Dependent Module Layout ----------
	local CooldownSweep = Modules.IconModule_CooldownSweep
	local PowerBar_Overlay = Modules.IconModule_PowerBar_Overlay
	local TimerBar_Overlay = Modules.IconModule_TimerBar_Overlay
	local IconModule_Texture_Colored = Modules.IconModule_Texture_Colored
	
	local frameLevelOffset
	if Masque.isDefaultSkin then
		frameLevelOffset = Masque.isDefaultSkin and 1 or -2
	else
		frameLevelOffset = -2
	end
	
	if CooldownSweep then
		CooldownSweep.cooldown:SetFrameLevel( icon:GetFrameLevel() + 0 + frameLevelOffset)
	end
	
	local insets = Masque.isDefaultSkin and 1.5 or 0
	local anchorTo = IconModule_Texture_Colored and IconModule_Texture_Colored.texture or icon
	if TimerBar_Overlay then
		TimerBar_Overlay.bar:SetFrameLevel(icon:GetFrameLevel() + 1 + frameLevelOffset)
		TimerBar_Overlay.bar:ClearAllPoints()
		TimerBar_Overlay.bar:SetPoint("TOP", anchorTo, "CENTER", 0, -0.5)
		TimerBar_Overlay.bar:SetPoint("BOTTOMLEFT", anchorTo, "BOTTOMLEFT", insets, insets)
		TimerBar_Overlay.bar:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMRIGHT", -insets, insets)
	end
	
	if PowerBar_Overlay then
		PowerBar_Overlay.bar:SetFrameLevel(icon:GetFrameLevel() + 1 + frameLevelOffset)
		PowerBar_Overlay.bar:ClearAllPoints()
		PowerBar_Overlay.bar:SetPoint("BOTTOM", anchorTo, "CENTER", 0, 0.5)
		PowerBar_Overlay.bar:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", insets, -insets)
		PowerBar_Overlay.bar:SetPoint("TOPRIGHT", anchorTo, "TOPRIGHT", -insets, -insets)
	end
end)


View:ImplementsModule("GroupModule_Resizer", 10, true)
	
function View:Icon_Setup(icon)
	icon:SetSize(ICON_SIZE, ICON_SIZE)
end
function View:Icon_UnSetup(icon)
end

function View:Icon_SetPoint(icon, positionID)
	--[[
		ABBR	DIR 1, DIR 2	VAL		VAL%4
		RD		RIGHT, DOWN 	1		1 (normal)
		LD		LEFT, DOWN		2		2
		LU		LEFT, UP		3		3
		RU		RIGHT, UP		4		0
		DR		DOWN, RIGHT		5		1
		DL		DOWN, LEFT		6		2
		UL		UP, LEFT		7		3
		UR		UP, RIGHT		8		0
	]]
	
	local group = icon.group
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	local LayoutDirection = group.LayoutDirection
	
	local row, column
	
	if LayoutDirection >= 5 then
		local Rows = group.Rows
		
		row = (positionID - 1) % Rows + 1
		column = ceil(positionID / Rows)
	else
		local Columns = group.Columns
		
		row = ceil(positionID / Columns)
		column = (positionID - 1) % Columns + 1
	end
	
	local x, y = (ICON_SIZE + gspv.SpacingX)*(column-1), (ICON_SIZE + gspv.SpacingY)*(row-1)
	
	
	local position = icon.position
	position.relativeTo = group
	
	if LayoutDirection % 4 == 1 then
		position.point, position.relativePoint = "TOPLEFT", "TOPLEFT"
		position.x, position.y = x, -y
	elseif LayoutDirection % 4 == 2 then
		position.point, position.relativePoint = "TOPRIGHT", "TOPRIGHT"
		position.x, position.y = -x, -y
	elseif LayoutDirection % 4 == 3 then
		position.point, position.relativePoint = "BOTTOMRIGHT", "BOTTOMRIGHT"
		position.x, position.y = -x, y
	elseif LayoutDirection % 4 == 0 then
		position.point, position.relativePoint = "BOTTOMLEFT", "BOTTOMLEFT"
		position.x, position.y = x, y
	end
	
	icon:ClearAllPoints()
	icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x, position.y)
end

function View:Group_Setup(group)
	
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	
	group:SetScale(gs.Scale)
	group:SetSize(gs.Columns*(ICON_SIZE+gspv.SpacingX)-gspv.SpacingX, gs.Rows*(ICON_SIZE+gspv.SpacingY)-gspv.SpacingY)
	
	local Resizer = group.Modules.GroupModule_Resizer
	Resizer:Enable()
	if TMW.Locked or group.Locked then
		Resizer.resizeButton:Hide()
	else
		Resizer.resizeButton:Show()
	end
end

function View:Group_UnSetup(group)
	
end

function View.Group_SizeUpdate(resizeButton)
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
	
	local newScale = max(0.6, newScaleX, newScaleY)
	--[[
		Holy shit. Look at this wicked sick dimensional analysis:
		
		std_newHeight	oldScale
		------------- X	-------- = newScale
		std_oldHeight	    1

		'std_Height' cancels out 'std_Height', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
		I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
		(which is why I am rewriting it right now)
	]]

	-- Set the scale that we just determined.
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
end

	
View:Register()

