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
	n = 3,
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
	{	-- [3] Duration
		x 	 		  	= -2,
		y 	 		  	= 0,
		ConstrainWidth	= true,
		point			= "RIGHT",
		relativePoint	= "RIGHT",
		
		StringName		= L["TEXTLAYOUTS_DEFAULTS_DURATION"],
		DefaultText		= "[Duration:TMWFormatDuration:Hide('0.0')]",
	},
}
View.defaultTextLayout = "bar1"

View:ImplementsModule("IconModule_Alpha", true)
View:ImplementsModule("IconModule_CooldownSweep", true)
View:ImplementsModule("IconModule_Texture_Colored", true)
View:ImplementsModule("IconModule_TimerBar_BarDisplay", true)
View:ImplementsModule("IconModule_Texts", true)
View:ImplementsModule("IconModule_Masque", true)
	
function View:Icon_Setup(icon)
	icon:SetSize(100, 30)
	local group = icon.group
	
	---------- Alpha ----------
	local Alpha = icon.Modules.IconModule_Alpha
	Alpha:SetEssential(true)
	
	---------- CooldownSweep ----------
	local CooldownSweep = icon.Modules.IconModule_CooldownSweep
	if icon.ShowTimer or icon.ShowTimerText then
		CooldownSweep:Enable()
	end
	CooldownSweep.cooldown:ClearAllPoints()
	CooldownSweep.cooldown:SetPoint("LEFT")
	CooldownSweep.cooldown:SetSize(30, 30)

	---------- Texture ----------
	local Texture = icon.Modules.IconModule_Texture_Colored
	Texture:SetEssential(true)
	Texture.texture:ClearAllPoints()
	Texture.texture:SetPoint("LEFT")
	Texture.texture:SetSize(30, 30)
	
	---------- TimerBarOverlay ----------
	local TimerBar_BarDisplay = icon.Modules.IconModule_TimerBar_BarDisplay
	TimerBar_BarDisplay:Enable()
	TimerBar_BarDisplay.bar:SetPoint("TOPRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("BOTTOMRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("LEFT", Texture.texture, "RIGHT")
	
	---------- Texts ----------
	local Texts = icon.Modules.IconModule_Texts
	Texts:Enable()
	
	-- [=[
	---------- Masque ----------
	local Masque = icon.Modules.IconModule_Masque
	Masque.container:ClearAllPoints()
	Masque.container:SetSize(30, 30)
	Masque.container:SetPoint("LEFT")
	Masque:Enable()
	--]=]

	---------- Skin-Dependent Module Layout ----------
	if Masque.isDefaultSkin then
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 3)
		TimerBar_BarDisplay.bar:SetFrameLevel(icon:GetFrameLevel() + 2)
	else
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 2)
		TimerBar_BarDisplay.bar:SetFrameLevel(icon:GetFrameLevel() + -1)
	end
	--local insets = Masque.isDefaultSkin and 1.5 or 0
	TimerBar_BarDisplay.bar:SetPoint("TOPRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("BOTTOMRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("LEFT", Masque.container, "RIGHT")
end
function View:Icon_UnSetup(icon)
	if LMB then
		local lmbGroup = LMB:Group("TellMeWhen", L["fGROUP"]:format(icon.group:GetID()))
		lmbGroup:RemoveButton(icon.stupidBullshit, true)
	end
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
	local Spacing = group.Spacing
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
	
	local x, y = (100 + Spacing)*(column-1), (30 + Spacing)*(row-1)
	
	
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

View:Register()

