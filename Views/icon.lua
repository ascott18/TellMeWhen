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
View.defaultTextLayout = "icon1"

View:ImplementsModule("IconModule_Alpha", true)
View:ImplementsModule("IconModule_CooldownSweep", true)
View:ImplementsModule("IconModule_Texture_Colored", true)
View:ImplementsModule("IconModule_PowerBar_Overlay", true)
View:ImplementsModule("IconModule_TimerBar_Overlay", true)
View:ImplementsModule("IconModule_Texts", true)
View:ImplementsModule("IconModule_Masque", true)
View:ImplementsModule("GroupModule_Resizer", true)
	
function View:Icon_Setup(icon)
	local group = icon.group
	icon:SetSize(30, 30)
	
	---------- Alpha ----------
	local Alpha = icon.Modules.IconModule_Alpha
	Alpha:SetEssential(true)
	
	---------- CooldownSweep ----------
	local CooldownSweep = icon.Modules.IconModule_CooldownSweep
	if icon.ShowTimer or icon.ShowTimerText then
		CooldownSweep:Enable()
	end
	CooldownSweep.cooldown:ClearAllPoints()
	CooldownSweep.cooldown:SetSize(30, 30)
	CooldownSweep.cooldown:SetPoint("CENTER", icon)

	---------- Texture ----------
	local Texture = icon.Modules.IconModule_Texture_Colored
	Texture:SetEssential(true)
	Texture.texture:ClearAllPoints()
	Texture.texture:SetPoint("CENTER", icon)
	Texture.texture:SetSize(30, 30)
	
	---------- PowerBarOverlay ----------
	local PowerBarOverlay = icon.Modules.IconModule_PowerBar_Overlay
	if icon.ShowPBar then
		PowerBarOverlay:Enable()
	end
	
	---------- TimerBarOverlay ----------
	local TimerBarOverlay = icon.Modules.IconModule_TimerBar_Overlay
	if icon.ShowCBar then
		TimerBarOverlay:Enable()
	end
	
	---------- Texts ----------
	local Texts = icon.Modules.IconModule_Texts
	Texts:Enable()

	---------- Masque ----------
	local Masque = icon.Modules.IconModule_Masque
	Masque:Enable()
	Masque.container:ClearAllPoints()
	Masque.container:SetAllPoints()	

	---------- Skin-Dependent Module Layout ----------
	if Masque.isDefaultSkin then
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 1)
		PowerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + 2)
		TimerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + 2)
	else
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + -2)
		PowerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + -1)
		TimerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + -1)
	end
	
	local insets = Masque.isDefaultSkin and 1.5 or 0
	TimerBarOverlay.bar:SetPoint("TOP", Texture.texture, "CENTER", 0, -0.5)
	TimerBarOverlay.bar:SetPoint("BOTTOMLEFT", Texture.texture, "BOTTOMLEFT", insets, insets)
	TimerBarOverlay.bar:SetPoint("BOTTOMRIGHT", Texture.texture, "BOTTOMRIGHT", -insets, insets)
	
	PowerBarOverlay.bar:SetPoint("BOTTOM", Texture.texture or icon, "CENTER", 0, 0.5)
	PowerBarOverlay.bar:SetPoint("TOPLEFT", Texture.texture or icon, "TOPLEFT", insets, -insets)
	PowerBarOverlay.bar:SetPoint("TOPRIGHT", Texture.texture or icon, "TOPRIGHT", -insets, -insets)
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
	
	local x, y = (30 + gspv.SpacingX)*(column-1), (30 + gspv.SpacingY)*(row-1)
	
	
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
	group:SetSize(gs.Columns*(30+gspv.SpacingX)-gspv.SpacingX, gs.Rows*(30+gspv.SpacingY)-gspv.SpacingY)
	
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

