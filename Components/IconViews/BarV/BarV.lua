-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--        Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--        Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local ceil = ceil

local View = TMW.Classes.IconView:New("barv")

View.name = L["UIPANEL_GROUPTYPE_BARV"]
View.desc = L["UIPANEL_GROUPTYPE_BARV_DESC"]

TMW:RegisterDatabaseDefaults{
	global = {
		TextLayouts = {
			bar2 = {
				Name = L["TEXTLAYOUTS_DEFAULTS_BAR2"],
				GUID = "bar2",
				NoEdit = true,
				n = 2,
				
				-- Bar Layout 2
				{    -- [1] Duration        
					StringName = L["TEXTLAYOUTS_DEFAULTS_DURATION"],
					DefaultText = "[Duration(gcd=true):TMWFormatDuration]",    
					Anchors = {
						{
							point = "TOP",
							relativePoint = "TOP",
							y = -1,
						}, -- [1]
					},
				},
				{    -- [2] Spell
					StringName = L["TEXTLAYOUTS_DEFAULTS_SPELL"],        
					DefaultText = "[Spell] [Stacks:Hide(0):Paren]",
					
					Rotate = 90,
					Justify = "LEFT",
					Anchors = {
						{
							x = 3,
							y = -12,
							point = "BOTTOMLEFT",
							relativeTo = "IconModule_TimerBar_BarDisplayTimerBar",
							relativePoint = "BOTTOMLEFT",
						}, -- [1]
						{
							point = "RIGHT",
							relativeTo = "$$1",
							relativePoint = "LEFT",
						}, -- [2]
					},
				},
			},
		},
	},
}


View:RegisterGroupDefaults{
	SettingsPerView = {
		barv = {
			TextLayout = "bar2",
			SizeX = 20,
			SizeY = 100,
		}
	}
}


View:ImplementsModule("IconModule_Alpha", 10, true)
View:ImplementsModule("IconModule_CooldownSweep", 20, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	if icon.ShowTimer or icon.ShowTimerText then
		Module:Enable()
	end
	Module.cooldown:SetSize(gspv.SizeX, gspv.SizeX)
end)
View:ImplementsModule("IconModule_Backdrop", 25, true)
View:ImplementsModule("IconModule_Texture_Colored", 30, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	Module:Enable()
	Module.texture:SetSize(gspv.SizeX, gspv.SizeX)
end)
View:ImplementsModule("IconModule_TimerBar_BarDisplay", 50, function(Module, icon)
	Module:Enable()

	Module.bar:SetOrientation("VERTICAL")
	Module.bar:SetRotatesTexture(true)
end)
View:ImplementsModule("IconModule_Texts", 570, true)
View:ImplementsModule("IconModule_IconContainer_Masque", 100, function(Module, icon)
	local Modules = icon.Modules
	local Masque = Module
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	

	local CooldownSweep = Modules.IconModule_CooldownSweep
	if CooldownSweep then
		CooldownSweep.cooldown:SetAllPoints(Masque.container)
	end

	local IconModule_Texture_Colored = Modules.IconModule_Texture_Colored
	IconModule_Texture_Colored.texture:SetAllPoints(Masque.container)



	Masque.container:ClearAllPoints()
	Masque.container:SetSize(gspv.SizeX, gspv.SizeX)
	Masque.container:SetPoint("BOTTOMLEFT")
	Masque:Enable()
	
	---------- Skin-Dependent Module Layout ----------
	local TimerBar_BarDisplay = Modules.IconModule_TimerBar_BarDisplay
	
	if CooldownSweep then
		if Masque.isDefaultSkin then
			CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 3)
		else
			CooldownSweep.cooldown:SetFrameLevel(icon:GetFrameLevel() + 2)
		end
	end
	
	TimerBar_BarDisplay.bar:SetFrameLevel(icon:GetFrameLevel() + -0)
	
	TimerBar_BarDisplay.bar:ClearAllPoints()
	TimerBar_BarDisplay.bar:SetPoint("TOPLEFT")
	TimerBar_BarDisplay.bar:SetPoint("TOPRIGHT")
	TimerBar_BarDisplay.bar:SetPoint("BOTTOM", Masque.container, "TOP")
	
	local Backdrop = Modules.IconModule_Backdrop
	Backdrop.container:ClearAllPoints()
	Backdrop.container:SetAllPoints(TimerBar_BarDisplay.bar)
	Backdrop.container:SetFrameLevel(icon:GetFrameLevel() - 2)
end)

View:ImplementsModule("GroupModule_Resizer_ScaleX_SizeY", 10, function(Module, group)
	if TMW.Locked or group.Locked then
		Module:Disable()
	else
		Module:Enable()
	end
end)
View:ImplementsModule("GroupModule_IconPosition_Sortable", 20, true)


function View:Icon_SetSize(icon)
	icon:SetSize(self:Icon_GetSize(icon))
end

function View:Icon_Setup(icon)
	self:Icon_SetSize(icon)
end

function View:Group_Setup(group)
	self:Group_SetSize(group)
	
	for icon in group:InIcons() do
		self:Icon_Setup(icon)
	end
end

function View:Icon_GetSize(icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	return gspv.SizeX, gspv.SizeY
end

function View:Group_SetSize(group)
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	
	group:SetSize(gs.Columns*(gspv.SizeX+gspv.SpacingX)-gspv.SpacingX, gs.Rows*(gspv.SizeY+gspv.SpacingY)-gspv.SpacingY)
end

function View:Group_OnCreate(gs)
	-- gs.Rows, gs.Columns = gs.Columns, gs.Rows
end

View:Register(20)