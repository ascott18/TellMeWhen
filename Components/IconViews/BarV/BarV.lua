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
							relativeTo = "IconModule_TimerBar_BarDisplayTimerBar",
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
			Icon = true,
			Flip = false,
			Padding = 0,
			BorderColor = {r=0, g=0, b=0, a=1},
			BorderBar = 0,
			BorderIcon = 0,
		}
	}
}


View:RegisterConfigTable("args.main.args", View.view, {
	type = "group",
	order = 40,
	name = View.name,
	dialogInline = true,
	guiInline = true,

	args = {
		Icon = {
			name = L["UIPANEL_BAR_SHOWICON"],
			desc = L["UIPANEL_BAR_SHOWICON_DESC"],
			type = "toggle",
			order = 1,
			set = "group_set_spv",
			get = "group_get_spv",
		},
		Flip = {
			name = L["UIPANEL_BAR_FLIP"],
			desc = L["UIPANEL_BAR_FLIP_DESC"],
			type = "toggle",
			order = 2,
			set = "group_set_spv",
			get = "group_get_spv",
		},
		Padding = {
			name = L["UIPANEL_BAR_PADDING"],
			desc = L["UIPANEL_BAR_PADDING_DESC"],
			type = "range",
			order = 11,
			softMin = -5,
			softMax = 20,
			step = 0.1,
			bigStep = 0.5,

			set = "group_set_spv",
			get = "group_get_spv",
		},

		BorderIcon = {
			name = L["UIPANEL_BAR_BORDERICON"],
			desc = L["UIPANEL_BAR_BORDERICON_DESC"],
			type = "range",
			order = 21,
			min = 0,
			max = 3,
			step = 0.1,
			bigStep = 0.5,

			set = "group_set_spv",
			get = "group_get_spv",
		},

		BorderBar = {
			name = L["UIPANEL_BAR_BORDERBAR"],
			desc = L["UIPANEL_BAR_BORDERBAR_DESC"],
			type = "range",
			order = 22,
			min = 0,
			max = 3,
			step = 0.1,
			bigStep = 0.5,

			set = "group_set_spv",
			get = "group_get_spv",
		},

		BorderColor = {
			name = L["UIPANEL_BAR_BORDERCOLOR"],
			desc = L["UIPANEL_BAR_BORDERCOLOR_DESC"],
			type = "color",
			order = 20,

			hasAlpha = true,
			set = function(info, r, g, b, a)
				local group = TMW.FindGroupFromInfo(info)
				local gspv = group:GetSettingsPerView()

				gspv[info[#info]] = {r=r, g=g, b=b, a=a}

				group:Setup()
			end,
			get = function(info)
				local group = TMW.FindGroupFromInfo(info)
				local gspv = group:GetSettingsPerView()

				local c = gspv[info[#info]]

				return c.r, c.g, c.b, c.a
			end,
		},
	},
})


View:ImplementsModule("IconModule_IconContainer_Masque", 1, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	
	Module.container:ClearAllPoints()

	Module:SetBorder(
		gspv.BorderIcon,
		gspv.BorderColor.r,
		gspv.BorderColor.g,
		gspv.BorderColor.b,
		gspv.BorderColor.a)

	local inset = gspv.BorderIcon

	if gspv.Icon then
		Module:Enable()

		Module.container:SetSize(gspv.SizeX - 2*inset, gspv.SizeX - 2*inset)
		Module.container:SetPoint(gspv.Flip and "TOPLEFT" or "BOTTOMLEFT", inset, -inset)
	end
end)

View:ImplementsModule("IconModule_Alpha", 10, true)

View:ImplementsModule("IconModule_CooldownSweep", 20, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	local IconContainer = icon.Modules.IconModule_IconContainer_Masque
	
	if gspv.Icon and (icon.ShowTimer or icon.ShowTimerText) then
		Module:Enable()
	end

	Module.cooldown:SetAllPoints(IconContainer.container)

	if IconContainer:IsIconSkinned(icon) then
		Module.cooldown:SetFrameLevel(icon:GetFrameLevel() + 3)
	else
		Module.cooldown:SetFrameLevel(icon:GetFrameLevel() + 2)
	end
end)

View:ImplementsModule("IconModule_Texture_Colored", 30, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	local IconContainer = icon.Modules.IconModule_IconContainer_Masque
	
	if gspv.Icon then
		Module:Enable()
	end

	Module.texture:SetAllPoints(IconContainer.container)
end)

View:ImplementsModule("IconModule_TimerBar_BarDisplay", 50, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()
	local IconContainer = icon.Modules.IconModule_IconContainer_Masque
	
	Module.bar:SetOrientation("VERTICAL")
	Module.bar:SetRotatesTexture(true)
	
	Module.bar:SetFrameLevel(icon:GetFrameLevel())

	local inset = gspv.BorderBar
	

	Module.bar:ClearAllPoints()
	if not gspv.Icon then
		Module.bar:SetPoint("TOPLEFT", inset, -inset)
		Module.bar:SetPoint("BOTTOMRIGHT", -inset, inset)

	elseif gspv.Flip then
		Module.bar:SetPoint("BOTTOMLEFT", inset, inset)
		Module.bar:SetPoint("BOTTOMRIGHT", -inset, inset)
		Module.bar:SetPoint("TOP", IconContainer.container, "BOTTOM", 0, -gspv.Padding - inset - gspv.BorderIcon)

	elseif not gspv.Flip then
		Module.bar:SetPoint("TOPLEFT", inset, -inset)
		Module.bar:SetPoint("TOPRIGHT", -inset, -inset)
		Module.bar:SetPoint("BOTTOM", IconContainer.container, "TOP", 0, gspv.Padding + inset + gspv.BorderIcon)
	end

	-- We can only query the size of the bar if the icon has had its position set.
	if not icon:GetPoint() or Module.bar:GetHeight() > 0 then
		Module:Enable()
	end
end)

View:ImplementsModule("IconModule_Backdrop", 51, function(Module, icon)
	local group = icon.group
	local gspv = group:GetSettingsPerView()

	Module:SetBorder(
		gspv.BorderBar,
		gspv.BorderColor.r,
		gspv.BorderColor.g,
		gspv.BorderColor.b,
		gspv.BorderColor.a)
	
	Module.container:ClearAllPoints()
	Module.container:SetAllPoints(icon.Modules.IconModule_TimerBar_BarDisplay.bar)
	Module.container:SetFrameLevel(icon:GetFrameLevel() - 2)

	-- We can only query the size of the bar if the icon has had its position set.
	if not icon:GetPoint() or Module.container:GetHeight() > 0 then
		Module:Enable()
	end
end)

View:ImplementsModule("IconModule_Texts", 70, true)






View:ImplementsModule("GroupModule_Resizer_ScaleX_SizeY", 10, true)
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