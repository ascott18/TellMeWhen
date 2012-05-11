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

function View:Icon_Setup(icon)
	local group = icon.group
	
	---------- Alpha ----------
	local Alpha = icon:ImplementModule("IconModule_Alpha")
	Alpha:SetEssential(true)
	
	---------- CooldownSweep ----------
	local CooldownSweep = icon:ImplementModule("IconModule_CooldownSweep")
	if icon.ShowTimer or icon.ShowTimerText then
		CooldownSweep:Enable()
	end
	CooldownSweep.cooldown:SetSize(30, 30)
	CooldownSweep.cooldown:SetPoint("CENTER")

	---------- Texture ----------
	local Texture = icon:ImplementModule("IconModule_Texture_Colored")
	Texture:SetEssential(true)
	Texture.texture:SetSize(30, 30)
	Texture.texture:SetPoint("CENTER")
	
	---------- PowerBarOverlay ----------
	local PowerBarOverlay = icon:ImplementModule("IconModule_PowerBar")
	if icon.ShowPBar then
		PowerBarOverlay:Enable()
	end
	icon.pbar_overlay = PowerBarOverlay.bar
	
	---------- TimerBarOverlay ----------
	local TimerBarOverlay = icon:ImplementModule("IconModule_TimerBar_Overlay")
	if icon.ShowCBar then
		TimerBarOverlay:Enable()
	end
	
	---------- Texts ----------
	local Texts = icon:ImplementModule("IconModule_Texts")
	Texts:Enable()	

	---------- Masque ----------
	icon.normaltex = icon.__MSQ_NormalTexture or icon:GetNormalTexture()
	if LMB then
		icon.isDefaultSkin = nil
		local lmbGroup = LMB:Group("TellMeWhen", L["fGROUP"]:format(group:GetID()))
		
		-- we need to :RemoveButton before :AddButton because AddButton will return early if the button is already skinned
		-- lmbButtonData may have changed since it was last skinned, so we need to make sure that we reskin every time
		lmbGroup:RemoveButton(icon, true)
		lmbGroup:AddButton(icon, icon.lmbButtonData)
		
		if lmbGroup.Disabled or (lmbGroup.db and lmbGroup.db.Disabled) then
			if not icon.normaltex:GetTexture() then
				icon.isDefaultSkin = 1
			end
		end
	else
		icon.isDefaultSkin = 1
	end

	---------- Skin-Dependent Module Layout ----------
	if icon.isDefaultSkin then
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 1)
		PowerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + 2)
		TimerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + 2)
	else
		CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + -2)
		PowerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + -1)
		TimerBarOverlay.bar:SetFrameLevel(icon:GetFrameLevel() + -1)
	end
	
	local insets = icon.isDefaultSkin and 1.5 or 0
	TimerBarOverlay.bar:SetPoint("TOP", Texture.texture, "CENTER", 0, -0.5)
	TimerBarOverlay.bar:SetPoint("BOTTOMLEFT", Texture.texture, "BOTTOMLEFT", insets, insets)
	TimerBarOverlay.bar:SetPoint("BOTTOMRIGHT", Texture.texture, "BOTTOMRIGHT", -insets, insets)
	
	PowerBarOverlay.bar:SetPoint("BOTTOM", Texture.texture or icon, "CENTER", 0, 0.5)
	PowerBarOverlay.bar:SetPoint("TOPLEFT", Texture.texture or icon, "TOPLEFT", insets, -insets)
	PowerBarOverlay.bar:SetPoint("TOPRIGHT", Texture.texture or icon, "TOPRIGHT", -insets, -insets)
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
	
	local x, y
	
	if LayoutDirection >= 5 then
		local Rows = group.Rows
		
		local row = (positionID - 1) % Rows + 1
		local column = ceil(positionID / Rows)
		x, y = (30 + Spacing)*(column-1), (30 + Spacing)*(row-1)
	else
		local Columns = group.Columns
		
		local row = ceil(positionID / Columns)
		local column = (positionID - 1) % Columns + 1
		x, y = (30 + Spacing)*(column-1), (30 + Spacing)*(row-1)
	end
	
	if LayoutDirection % 4 == 1 then
		icon.pos, icon.x, icon.y = "TOPLEFT", x, -y
	elseif LayoutDirection % 4 == 2 then
		icon.pos, icon.x, icon.y = "TOPRIGHT", -x, -y
	elseif LayoutDirection % 4 == 3 then
		icon.pos, icon.x, icon.y = "BOTTOMRIGHT", -x, y
	elseif LayoutDirection % 4 == 0 then
		icon.pos, icon.x, icon.y = "BOTTOMLEFT", x, y
	end
	
	icon:ClearAllPoints()
	icon:SetPoint(icon.pos, icon.x, icon.y)
end

View:Register()

