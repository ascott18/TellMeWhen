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

local View = TMW.Classes.IconView:New("bar")

TMW.Defaults.profile.TextLayouts.bar1 = {
	Name = L["TEXTLAYOUTS_DEFAULTS_BAR1"],
	GUID = "bar1",
	NoEdit = true,
	n = 2,
	-- Default Layout 1
	{	-- [1] Stacks
		x 	 		  	= -2,
		y 	 		  	= 2,
		ConstrainWidth	= false,
		point			= "BOTTOMRIGHT",
		relativePoint	= "BOTTOMRIGHT",
		
		StringName		= L["TEXTLAYOUTS_DEFAULTS_STACKS"],
		DefaultText		= "[Stacks:Hide('0', '1')]",
		SkinAs			= "Count",
	},
	{	-- [2] Duration
		x 	 		  	= -2,
		y 	 		  	= 0,
		ConstrainWidth	= true,
		point			= "RIGHT",
		relativePoint	= "RIGHT",
		
		StringName		= L["TEXTLAYOUTS_DEFAULTS_DURATION"],
		DefaultText		= "[Duration:TMWFormatDuration]",
	},
}

View:RegisterIconDefaults{
	SettingsPerView = {
		bar = {
			TextLayout = "bar1",
			Texts = {
				"[Stacks:Hide('0', '1')]",
				"[Duration:TMWFormatDuration]",
			}
		}
	}
}
View:RegisterGroupDefaults{
	SettingsPerView = {
		bar = {
			TextLayout = "bar1",
			SizeX = 140,
			SizeY = 20,
		}
	}
}


View:ImplementsModule("IconModule_Alpha", 10, function(Module, icon)
	Module:SetEssential(true)
end)
View:ImplementsModule("IconModule_CooldownSweep", 20, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	if icon.ShowTimer or icon.ShowTimerText then
		Module:Enable()
	end
	Module.cooldown:ClearAllPoints()
	Module.cooldown:SetPoint("LEFT", icon)
	Module.cooldown:SetSize(gspv.SizeY, gspv.SizeY)
end)
View:ImplementsModule("IconModule_Texture_Colored", 30, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	Module:SetEssential(true)
	Module.texture:ClearAllPoints()
	Module.texture:SetPoint("LEFT", icon)
	Module.texture:SetSize(gspv.SizeY, gspv.SizeY)
end)
View:ImplementsModule("IconModule_TimerBar_BarDisplay", 50, function(Module, icon)
	Module:Enable()
end)
View:ImplementsModule("IconModule_Texts", 70, function(Module, icon)
	Module:Enable()
end)
View:ImplementsModule("IconModule_Masque", 100, function(Module, icon)
	local Modules = icon.Modules
	local Masque = Module
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	Masque.container:ClearAllPoints()
	Masque.container:SetSize(gspv.SizeY, gspv.SizeY)
	Masque.container:SetPoint("LEFT")
	Masque:Enable()

	---------- Skin-Dependent Module Layout ----------
	local CooldownSweep = Modules.IconModule_CooldownSweep
	local TimerBar_BarDisplay = Modules.IconModule_TimerBar_BarDisplay
	
	if Masque.isDefaultSkin then
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 3)
		TimerBar_BarDisplay.bar:SetFrameLevel(icon:GetFrameLevel() + 2)
	else
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 2)
		TimerBar_BarDisplay.bar:SetFrameLevel(icon:GetFrameLevel() + -1)
	end
	
	TimerBar_BarDisplay.bar:ClearAllPoints()
	TimerBar_BarDisplay.bar:SetPoint("TOPRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("BOTTOMRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("LEFT", Masque.container, "RIGHT")
end)

View:ImplementsModule("GroupModule_Resizer", 10, true)
	
function View:Icon_SetSize(icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	icon:SetSize(gspv.SizeX, gspv.SizeY)
end

function View:Icon_Setup(icon)
	self:Icon_SetSize(icon)
end
function View:Icon_UnSetup(icon)

end

function View:Group_Setup(group)
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	
	group:SetScale(gs.Scale)
	group:SetSize(gs.Columns*(gspv.SizeX+gspv.SpacingX)-gspv.SpacingX, gs.Rows*(gspv.SizeY+gspv.SpacingY)-gspv.SpacingY)
	
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
	
	local x, y = (gspv.SizeX + gspv.SpacingX)*(column-1), (gspv.SizeY + gspv.SpacingY)*(row-1)
	
	
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

function View:Group_SetSizeAndScale(group)
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	
	group:SetScale(gs.Scale)
	group:SetSize(gs.Columns*(gspv.SizeX+gspv.SpacingX)-gspv.SpacingX, gs.Rows*(gspv.SizeY+gspv.SpacingY)-gspv.SpacingY)
end

function View:Group_SetupMacroAppearance(group)
	self:Group_SetSizeAndScale(group)
	
	for icon in TMW:InIcons(group.ID) do
		self:Icon_SetSize(icon)
	end
	
	group:SortIcons()
end

local UPD_INTV = 1
function View.Group_SizeUpdate(resizeButton)
	--[[ Notes:
	--	arg1 (self) is resizeButton
		
	--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
		More specifically, it means that it does not depend on the scale of either the group nor UIParent.
	]]
	local self = resizeButton.module
	
	local group = self.group
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	local uiScale = UIParent:GetScale()
	
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
	
	
    -- Calculate new bar width
	local std_newFrameWidth = std_cursorX - self.std_oldLeft
	local std_spacing = gspv.SpacingX*group:GetEffectiveScale()
	local std_newWidth = (std_newFrameWidth + std_spacing)/gs.Columns - std_spacing
	local newWidth = std_newWidth/group:GetEffectiveScale()
	newWidth = max(gspv.SizeY, newWidth)
	gspv.SizeX = newWidth
	
	if not self.LastUpdate or self.LastUpdate <= TMW.time - UPD_INTV then
		-- Update the group completely very infrequently because of the high CPU usage.
		
		self.LastUpdate = TMW.time
		
		-- This needs to be done before we :Setup() or otherwise bad things happen.
		group:CalibrateAnchors()
	
		group:Setup()
	else
		-- Only do the things that will determine most of the group's appearance on every frame.
		
		View:Group_SetSizeAndScale(group)
		
		for icon in TMW:InIcons(group.ID) do
			View:Icon_SetSize(icon)
		end
		
		group:SortIcons()
	end
end


View:Register()

