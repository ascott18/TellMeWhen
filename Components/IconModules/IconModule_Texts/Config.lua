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

local tonumber, tostring, type, pairs, tremove, wipe, next, setmetatable, pcall, assert, rawget, unpack, select, loadstring, error =
	  tonumber, tostring, type, pairs, tremove, wipe, next, setmetatable, pcall, assert, rawget, unpack, select, loadstring, error
local strmatch, strtrim, max =
	  strmatch, strtrim, max

-- GLOBALS: TellMeWhen_TextDisplayOptions, TELLMEWHEN_VERSIONNUMBER
-- GLOBALS: CreateFrame, IsControlKeyDown

local DogTag = LibStub("LibDogTag-3.0")
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local LSM = LibStub("LibSharedMedia-3.0")

local TEXT = TMW.TEXT
local IE = TMW.IE
local CI = TMW.CI

if not TEXT then return end

LibStub("AceHook-3.0"):Embed(TEXT)

local DEFAULT_LAYOUT_SETTINGS = TMW.db.global.TextLayouts["\000"]
TMW.db.global.TextLayouts["\000"] = nil

local DEFAULT_DISPLAY_SETTINGS = DEFAULT_LAYOUT_SETTINGS[1]
DEFAULT_LAYOUT_SETTINGS[1] = nil


TEXT.usedStrings = {}

function TEXT:GetTextLayoutSettings(GUID)
	return GUID and rawget(TMW.db.global.TextLayouts, GUID) or nil
end

function TEXT:GetStringName(settings, num, unnamed)
	local Name = strtrim(settings.StringName or "")
	
	if Name == "" then
		if unnamed then
			Name = L["TEXTLAYOUTS_UNNAMED"]
		else
			Name = L["TEXTLAYOUTS_fSTRING"]:format(num)
		end
	end
	
	return Name
end

function TEXT:GetLayoutName(settings, GUID, noDefaultWrapper)
	if GUID and not settings then
		assert(type(GUID) == "string")
		settings = TEXT:GetTextLayoutSettings(GUID)
	elseif settings and not GUID then
		GUID = settings.GUID
	elseif not settings and not GUID then
		error("You need to specify either settings or GUID for GetLayoutName")
	end
	
	assert(type(GUID) == "string")
	assert(type(settings) == "table")
	
	local Name = strtrim(settings.Name or "")
	
	if Name == "" then
		Name = L["TEXTLAYOUTS_UNNAMED"]
	end
	if settings.NoEdit and not noDefaultWrapper then
		Name = L["TEXTLAYOUTS_DEFAULTS_WRAPPER"]:format(Name)
	end
	
	return Name
end


function TEXT:CacheUsedStrings()
	for text in pairs(TEXT.usedStrings) do
		TEXT.usedStrings[text] = 0 -- set to 0, not nil, and dont wipe the table either
	end
	
	for ics, gs in TMW:InIconSettings() do
		for view, viewSettings in pairs(ics.SettingsPerView) do
		
			local GUID, layoutSettings = TEXT:GetTextLayoutForIconSettings(gs, ics, view)
			local Texts = viewSettings.Texts
			
			-- Get text displays that are used by the current layout.
			for textID = 1, layoutSettings.n do
				local text = TEXT:GetTextFromSettingsAndLayout(Texts, layoutSettings, textID)
				text = text:trim()
				TEXT.usedStrings[text] = (TEXT.usedStrings[text] or 0) + 1
			end
			
			-- Get text displays that lie outside the bounds of the current layout.
			for i, text in pairs(Texts) do
				if i > layoutSettings.n then
					text = text:trim()
					TEXT.usedStrings[text] = (TEXT.usedStrings[text] or 0) + 1
				end
			end
		end
	end
	
	TEXT.usedStrings[""] = nil
end


function TEXT.Layout_DropDown_Sort(GUID_a, GUID_b)
	local layoutSettings_a, layoutSettings_b = TEXT:GetTextLayoutSettings(GUID_a), TEXT:GetTextLayoutSettings(GUID_b)
	local NoEdit_a, NoEdit_b = layoutSettings_a.NoEdit, layoutSettings_b.NoEdit
	
	if NoEdit_a == NoEdit_b then
		-- Simple string comparison for alphabetical sorting
		return TEXT:GetLayoutName(layoutSettings_a, GUID_a) < TEXT:GetLayoutName(layoutSettings_b, GUID_b)
	else
		return NoEdit_a
	end
end

function TEXT:Layout_DropDown()
	for GUID, settings in TMW:OrderedPairs(TMW.db.global.TextLayouts, TEXT.Layout_DropDown_Sort) do
		if GUID ~= "" then
			local info = TMW.DD:CreateInfo()
			
			info.text = TEXT:GetLayoutName(settings, GUID)
			info.value = GUID
			info.checked = GUID == TEXT:GetTextLayoutForIcon(CI.icon)
			
			local displays = ""
			for i, fontStringSettings in TMW:InNLengthTable(settings) do
				displays = displays .. "\r\n" .. TEXT:GetStringName(fontStringSettings, i)
			end
			info.tooltipTitle = TEXT:GetLayoutName(settings, GUID)
			info.tooltipText = L["TEXTLAYOUTS_LAYOUTDISPLAYS"]:format(displays)
			
			info.func = TEXT.Layout_DropDown_OnClick
			
			TMW.DD:AddButton(info)
		end
	end
end

function TEXT:Layout_DropDown_OnClick()
	CI.icon:GetSettingsPerView().TextLayout = self.value
	TEXT:LoadConfig()
	IE:ScheduleIconSetup()
end


function TEXT:CopyString_DropDown()
	TEXT:CacheUsedStrings()
	
	for text, num in TMW:OrderedPairs(TEXT.usedStrings, "values", true) do
		local info = TMW.DD:CreateInfo()
		
		if #text > 50 then
			info.text = DogTag:ColorizeCode(text:sub(1, 40)) .. "..."
		else
			info.text = DogTag:ColorizeCode(text)
		end
		
		info.value = text
		
		info.tooltipTitle = L["TEXTLAYOUTS_STRINGUSEDBY"]:format(num)
		info.tooltipText = DogTag:ColorizeCode(text)
		info.notCheckable = true
		
		info.arg1 = self
		info.func = TEXT.CopyString_DropDown_OnClick
		
		TMW.DD:AddButton(info)
	end
end

function TEXT:CopyString_DropDown_OnClick(frame)
	local id = frame:GetParent():GetParent():GetID()
	
	CI.icon:GetSettingsPerView().Texts[id] = self.value
	TEXT:LoadConfig()
	IE:ScheduleIconSetup()
end

function TEXT:TestDogTagFunc(success, ...)
	if success then
		local arg1, arg2 = ...
		local numArgs = select("#", ...)
		if numArgs == 2 and arg2 == nil and type(arg1) == "string" then
			return arg1
		end
	end
end

if DogTag and DogTag.tagError then
	hooksecurefunc(DogTag, "tagError", function(_, _, text)
		TEXT.EvaluateError = text
	end)
end

local function ttText(self)
	GameTooltip:AddLine(L["TEXTLAYOUTS_STRING_SETDEFAULT_DESC"]:format(""), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	GameTooltip:AddLine(self.DefaultText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false)
	return nil
end

function TEXT:LoadConfig()
	if not TellMeWhen_TextDisplayOptions or not CI.icon then
		return
	end
	
	local Texts = CI.icon:GetSettingsPerView().Texts
	local GUID, layoutSettings, isFallback = TEXT:GetTextLayoutForIcon(CI.icon)
	
	TEXT:CacheUsedStrings()
	
	local layoutName
	if layoutSettings then
		local previousFrame
		for i, stringSettings in TMW:InNLengthTable(layoutSettings) do
			local frame = TEXT[i]
			
			local text = TEXT:GetTextFromSettingsAndLayout(Texts, layoutSettings, i)
			
			if not frame then
				frame = CreateFrame("Frame", "$parentString"..i, TellMeWhen_TextDisplayOptions, "TellMeWhen_TextDisplayGroup", i)
				TEXT[i] = frame
				frame:SetPoint("TOP", previousFrame, "BOTTOM")
			end
			
			frame:Show()

			frame.stringSettings = stringSettings

			local display_N_stringName = L["TEXTLAYOUTS_fSTRING2"]:format(i, TEXT:GetStringName(stringSettings, i, true))
			TMW:TT(frame.EditBox, display_N_stringName, "TEXTLAYOUTS_SETTEXT_DESC", 1)
			frame.EditBox.label = display_N_stringName

			frame.EditBox:SetText(text)
			frame.EditBox:GetScript("OnTextChanged")(frame.EditBox)
			
			local DefaultText = stringSettings.DefaultText
			if DefaultText == "" then
				DefaultText = L["TEXTLAYOUTS_BLANK"]
			else
				DefaultText = ("%q"):format(DogTag:ColorizeCode(DefaultText))
			end
			frame.Default.DefaultText = DefaultText
			TMW:TT(frame.Default, "TEXTLAYOUTS_STRING_SETDEFAULT", ttText, nil, 1)
			
			-- Ttest the string and its tags & syntax
			frame.Error:SetText(TMW:TestDogTagString(CI.icon, text))
			
			previousFrame = frame
			
			TEXT:SetTextDisplayContainerHeight(frame)
		end
		
		for i = max(layoutSettings.n + 1, 1), #TEXT do
			TEXT[i]:Hide()
		end
		
		TEXT:ResizeParentFrame()
		
		layoutName = TEXT:GetLayoutName(layoutSettings, GUID, true)
	else
		layoutName = "UNKNOWN LAYOUT: " .. (GUID or "<?>")
	end

	if TEXT[1] then
		TEXT[1]:SetPoint("TOPLEFT", TellMeWhen_TextDisplayOptions.Layout, "BOTTOMLEFT", 0, 16)
	end
	
	TellMeWhen_TextDisplayOptions.Layout.PickLayout:SetText("|cff666666" .. L["TEXTLAYOUTS_HEADER_LAYOUT"] .. ": |r" .. layoutName)
	
	TellMeWhen_TextDisplayOptions.Layout.Error:SetText(isFallback and L["TEXTLAYOUTS_ERROR_FALLBACK"] or nil)
	
	TMW:TT(TellMeWhen_TextDisplayOptions.Layout.LayoutSettings, "TEXTLAYOUTS_LAYOUTSETTINGS", L["TEXTLAYOUTS_LAYOUTSETTINGS_DESC"]:format(layoutName), nil, 1)
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", TEXT, "LoadConfig")

function TEXT:ResizeParentFrame()
	local layoutHeight = 45 + TellMeWhen_TextDisplayOptions.Layout.Error:GetHeight()
	
	TellMeWhen_TextDisplayOptions.Layout:SetHeight(layoutHeight)
	
	local height = layoutHeight
	
	for i = 1, #TEXT do
		if TEXT[i]:IsShown() then
			height = height + TEXT[i]:GetHeight()
		end
	end
	
	--TellMeWhen_TextDisplayOptions:SetHeight(height)
	TMW:AnimateHeightChange(TellMeWhen_TextDisplayOptions, height, 0.1)
end

function TEXT:SetTextDisplayContainerHeight(frame)
	local height = 1
	
	height = height + frame.EditBox:GetHeight()
	
	--frame.Error:SetHeight(frame.Error:GetStringHeight())
	height = height + frame.Error:GetHeight()
	
	frame:SetHeight(height)
	
	TEXT:ResizeParentFrame()
end

function TEXT:TMW_ICON_PREPARE_SETTINGS_FOR_COPY(event, ics, gs)
	if not ics.SettingsPerView then
		return
	end
	
	for view, settingsPerView in pairs(ics.SettingsPerView) do
		local GUID = settingsPerView.TextLayout
		if not GUID then
			local GUID_group = gs.SettingsPerView[view].TextLayout
			if GUID_group ~= TMW.approachTable(TMW.Group_Defaults, "SettingsPerView", view, "TextLayout") then
				GUID = GUID_group
			end
		end
		settingsPerView.TextLayout = GUID
	end
end
TMW:RegisterCallback("TMW_ICON_PREPARE_SETTINGS_FOR_COPY", TEXT)



local function deepRecScanTableForLayout(profile, GUID, table, ...)
	local n = 0

	for k, v in pairs(table) do
		if type(v) == "table" then
			n = n + deepRecScanTableForLayout(profile, GUID, v, k, ...)
		elseif v == GUID then
			local parentTableKey = select(4, ...)

			if parentTableKey == "Icons" then
				n = n + 1
			elseif parentTableKey == "Groups" then
				local groupID = select(3, ...)

				local gs = profile.Groups[groupID]

				if not TEXT.TextLayout_NumTimesUsedTemp[gs] then
					TEXT.TextLayout_NumTimesUsedTemp[gs] = true

					n = n + ((gs.Rows or 1) * (gs.Columns or 4))
				end
			end
		end
	end

	return n
end

function TEXT:GetNumTimesUsed(layoutGUID)
	TEXT.TextLayout_NumTimesUsedTemp = wipe(TEXT.TextLayout_NumTimesUsedTemp or {})
	
	local result = ""

	for profileName, profile in pairs(TMW.db.profiles) do
		local n = deepRecScanTableForLayout(profile, layoutGUID, profile)

		if n > 0 then
			if profileName == TMW.db:GetCurrentProfile() then
				profileName = "|cff7fffff" .. profileName .. "|r"
			end
			result = result .. L["TEXTLAYOUTS_DELETELAYOUT_CONFIRM_LISTING"]:format(profileName, n) .. "\r\n"
		end
	end


	wipe(TEXT.TextLayout_NumTimesUsedTemp)

	return result:trim("\r\n")
end

function TEXT:Display_IsDefault(displaySettings)
	return not not TMW:DeepCompare(DEFAULT_DISPLAY_SETTINGS, displaySettings)
end

function TEXT:Layout_IsDefault(layoutSettings)
	-- Remove the GUID from the layoutSettings, because otherwise it will always be non-default.
	local GUID = layoutSettings.GUID
	layoutSettings.GUID = ""
	
	-- safecall to avoid any disasters because layoutSettings is modified and is awaiting the restoration of its original state.
	local isDefault = TMW.safecall(TMW.DeepCompare, TMW, DEFAULT_LAYOUT_SETTINGS, layoutSettings)
	
	-- Put the GUID back in.
	layoutSettings.GUID = GUID
	
	return isDefault
end

TMW.GroupConfigTemplate.args.main.args.TextLayout = {
	name = L["TEXTLAYOUTS_SETGROUPLAYOUT"],
	desc = L["TEXTLAYOUTS_SETGROUPLAYOUT_DESC"],
	type = "select",
	values = function(info)
		local t = {}
		for GUID, layoutSettings in pairs(TMW.db.global.TextLayouts) do
			if GUID ~= "" then
				t[GUID] = TEXT:GetLayoutName(layoutSettings, GUID)
			end
		end
		setmetatable(t, {__index = function(t, k) 
			if k == "%FAKEGET%" then
				return L["TEXTLAYOUTS_SETGROUPLAYOUT_DDVALUE"]
			end
		end})
		return t
	end,
	hidden = function(info)
		local group = TMW.FindGroupFromInfo(info)

		local viewData = group and group.viewData
		
		return not viewData or not viewData:DoesImplementModule("IconModule_Texts")
	end,
	style = "dropdown",
	order = 29,
	get = function(info, val)
		return "%FAKEGET%"
	end,
	set = function(info, val)
		local group = TMW.FindGroupFromInfo(info)

		local gs = group:GetSettings()
		gs.SettingsPerView[gs.View].TextLayout = val
		
		-- the group setting is a fallback for icons, so there is no reason to set the layout for individual icons
		-- we do need to reset icons to "" so that they will fall back to the group setting, though.
		for icon in group:InIcons() do
			IE:AttemptBackup(icon)
		end
		
		for ics in group:InIconSettings() do
			local icspv = rawget(ics.SettingsPerView, gs.View)
			if icspv then
				icspv.TextLayout = nil
			end
		end
		
		for icon in group:InIcons() do
			IE:AttemptBackup(icon)
		end
		
		group:Setup()
		
		IE:Load(1)
	end,
}

local textLayoutInfo = {
	layout = 2,
	display = 3,
	stringSetting = 4,
}
local function findlayout(info)
	local layout = info[textLayoutInfo.layout]
	return layout and strmatch(layout, "#TextLayout (.*)"), layout
end
local function AddTextLayout()
	local GUID = TMW:GenerateGUID("textlayout", TMW.CONST.GUID_SIZE)
	local newLayout = TMW.db.global.TextLayouts[GUID]
	newLayout.GUID = GUID
	
	local Name = "New 1"
	repeat
		local found
		for k, layoutSettings in pairs(TMW.db.global.TextLayouts) do
			if layoutSettings.Name == Name then
				Name = TMW.oneUpString(Name)
				found = true
				break
			end
		end
	until not found
	
	newLayout.Name = Name

	return newLayout
end
local function UpdateIconsUsingTextLayout(layoutID)
	for group in TMW:InGroups() do
		for icon in group:InIcons() do
			if icon:IsVisible() and TEXT:GetTextLayoutForIcon(icon) == layoutID then
				-- setup entire groups because there is code that prevents excessive event firing
				-- when updating a whole group vs a single icon
				group:Setup()
				
				break -- break icon loop
			end
		end
	end
end
local textLayoutTemplate = {
	type = "group",
	name = function(info)
		local layout = findlayout(info)
		
		return TEXT:GetLayoutName(nil, layout)
	end,
	order = function(info)
		local layout = findlayout(info)
		local settings = TEXT:GetTextLayoutSettings(layout)
		
		if settings.NoEdit then
			return 1
		else
			return 2
		end
	end,
	disabled = function(info)
		local layout = findlayout(info)
		local stringSetting = info[textLayoutInfo.stringSetting]

		return stringSetting and TEXT:GetTextLayoutSettings(layout).NoEdit
	end,
	hidden = function(info)
		local layout = findlayout(info)
		return layout == "" or not TEXT:GetTextLayoutSettings(layout)
	end,
	args = {
		Name = {
			name = L["TEXTLAYOUTS_RENAME"],
			desc = L["TEXTLAYOUTS_RENAME_DESC"],
			type = "input",
			width = "full",
			order = 1,
			set = function(info, val)
				local layout = findlayout(info)
				TEXT:GetTextLayoutSettings(layout).Name = strtrim(val)
				TMW:Update()
				TEXT:LoadConfig()
			end,
			get = function(info)
				local layout = findlayout(info)
				return TEXT:GetTextLayoutSettings(layout).Name
			end,
			disabled = function(info)
				local layout = findlayout(info)
				return TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
		},
		addstring = {
			name = L["TEXTLAYOUTS_ADDSTRING"],
			desc = L["TEXTLAYOUTS_ADDSTRING_DESC"],
			type = "execute",
			order = 2,
			func = function(info)
				local layout = findlayout(info)
				TEXT:GetTextLayoutSettings(layout).n = TEXT:GetTextLayoutSettings(layout).n + 1

				TMW.ACEOPTIONS:NotifyChanges()
				TMW.ACEOPTIONS:CompileOptions()
				TMW:Update()
				TEXT:LoadConfig()
			end,
			disabled = function(info)
				local layout = findlayout(info)
				return TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
		},
		delete = {
			name = L["TEXTLAYOUTS_DELETELAYOUT"],
			desc = L["TEXTLAYOUTS_DELETELAYOUT_DESC"],
			type = "execute",
			order = 10,
			func = function(info)
				local layout = findlayout(info)
				
				TMW.ACEOPTIONS:LoadConfigPath(info, "textlayouts") -- MUST HAPPEN BEFORE WE NIL THE LAYOUT
				
				TMW.db.global.TextLayouts[layout] = nil
				TMW.ACEOPTIONS:CompileOptions()
				TMW:Update()
				TEXT:LoadConfig()
			end,
			disabled = function(info)
				local layout = findlayout(info)
				return TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
			confirm = function(info)
				local layout = findlayout(info)

				local layoutInUseMessage = TEXT:GetNumTimesUsed(layout)
			
				local warning = L["TEXTLAYOUTS_DELETELAYOUT_CONFIRM_BASE"]:format(TEXT:GetLayoutName(nil, layout))

				if layoutInUseMessage ~= "" then
					warning = warning .. "\r\n\r\n" .. L["TEXTLAYOUTS_DELETELAYOUT_CONFIRM_NUM2"] .. "\r\n\r\n" .. layoutInUseMessage

				elseif IsControlKeyDown() then
					return false
				end

				return warning
			end,
		},
		
		NoEditDesc = {
			name = "\r\n\r\n" .. L["TEXTLAYOUTS_NOEDIT_DESC"] .. "\r\n",
			type = "description",
			order = 100,
			disabled = false,
			hidden = function(info)
				local layout = findlayout(info)
				return not TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
		},
		
		Clone = {
			name = L["TEXTLAYOUTS_CLONELAYOUT"],
			desc = L["TEXTLAYOUTS_CLONELAYOUT_DESC"],
			type = "execute",
			width = "double",
			order = 110,
			func = function(info)
				local layout = findlayout(info)

				local GUID = TMW:GenerateGUID("textlayout", TMW.CONST.GUID_SIZE)

				local Item = TMW.Classes.SettingsItem:New("textlayout")
				Item.Settings = TEXT:GetTextLayoutSettings(layout)
				Item.Version = TELLMEWHEN_VERSIONNUMBER
				Item.Version = TELLMEWHEN_VERSIONNUMBER
				Item.ImportSource = TMW.C.ImportSource.types.Profile

				Item:SetExtra("GUID", GUID)

				Item:Import(GUID)
			end,
			disabled = function(info)
				return false
			end,
		},
		
		usedByDesc = {
			name = function(info)
				local layout = findlayout(info)
				local layoutSettings = TEXT:GetTextLayoutSettings(layout)

				if layoutSettings.NoEdit then
					return ""
				end

				if not debugstack():find("Select") then
					-- This text will probably never be seen.
					-- The reason for this is that AceConfig likes to call the name method for EVERYTHING
					return "AceConfig-3.0 has reqested information when it should not have. " .. 
					"The process to calculate what profiles are using a layout is intensive, " .. 
					"so it is only done when it really needs to be. Re-select the layout to recalculate."
				end

				local layoutInUseMessage = TEXT:GetNumTimesUsed(layout)

				if layoutInUseMessage ~= "" then
					return "\r\n" .. L["TEXTLAYOUTS_USEDBY_HEADER"] .. "\r\n\r\n" .. layoutInUseMessage .. "\r\n"
				else
					return "\r\n" .. L["TEXTLAYOUTS_USEDBY_NONE"] .. "\r\n"
				end
			end,
			type = "description",
			order = 150,
			disabled = false,
			hidden = function(info)
				local layout = findlayout(info)
				return TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
		},

		
		importExportBox = TMW.importExportBoxTemplate,
	},
}

local anchorSet = {
	name = function(info, val)
		return L["UIPANEL_ANCHORNUM"]:format(info[textLayoutInfo.stringSetting + 1])
	end,
	order = function(info)
		local anchorNum = tonumber(info[textLayoutInfo.stringSetting + 1])
		return anchorNum + 30
	end,
	type = "group",
	guiInline = true,
	dialogInline = true,			
	set = function(info, val)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		local anchorNum = tonumber(info[textLayoutInfo.stringSetting + 1])
		local setting = info[textLayoutInfo.stringSetting + 2]
		TEXT:GetTextLayoutSettings(layout)[display].Anchors[anchorNum][setting] = val
		UpdateIconsUsingTextLayout(layout)
		TEXT:LoadConfig()
	end,
	get = function(info)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		local anchorNum = tonumber(info[textLayoutInfo.stringSetting + 1])
		local setting = info[textLayoutInfo.stringSetting + 2]
		
		return TEXT:GetTextLayoutSettings(layout)[display].Anchors[anchorNum][setting]
	end,
	hidden = function(info)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		local setting = tonumber(info[textLayoutInfo.stringSetting + 1])
		return TEXT:GetTextLayoutSettings(layout)[display].Anchors.n < setting
	end,
	disabled = function(info)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		return
			TEXT:GetTextLayoutSettings(layout).NoEdit or
			(LMB and TEXT:GetTextLayoutSettings(layout)[display].SkinAs ~= "")
	end,
	order = function(info)
		return tonumber(info[textLayoutInfo.stringSetting + 1]) + 10
	end,
	args = {
		point = {
			name = L["UIPANEL_POINT"],
			desc = L["TEXTLAYOUTS_POINT_DESC"],
			type = "select",
			values = TMW.points,
			style = "dropdown",
			order = 10,
		},
		relativeTo = {
			name = L["UIPANEL_RELATIVETO"],
			desc = L["TEXTLAYOUTS_RELATIVETO_DESC"],
			type = "select",
			width = "double",
			values = function(info)
				local t = {
					[""] = L["ICON"],
				}
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				
				for i, fontStringSettings in TMW:InNLengthTable(TEXT:GetTextLayoutSettings(layout)) do
					if i ~= display then
						t["$$" .. i] = L["TEXTLAYOUTS_fSTRING3"]:format(TEXT:GetStringName(fontStringSettings, i))
					end
				end
				
				for IconModule in pairs(TMW.Classes.IconModule.inheritedBy) do
					if #IconModule.instances > 0 then
						for identifier, localizedName in pairs(IconModule.anchorableChildren) do
							if type(localizedName) == "string" then
								t[IconModule.className .. identifier] = localizedName
							end
						end
					end
				end

				return t
			end,
			style = "dropdown",
			order = 12,
		},
		relativePoint = {
			name = L["UIPANEL_RELATIVEPOINT"],
			desc = L["TEXTLAYOUTS_RELATIVEPOINT_DESC"],
			type = "select",
			values = TMW.points,
			style = "dropdown",
			order = 13,
		},
		x = {
			name = L["UIPANEL_FONT_XOFFS"],
			desc = L["UIPANEL_FONT_XOFFS_DESC"],
			type = "range",
			order = 20,
			min = -30,
			max = 30,
			step = 1,
			bigStep = 1,
		},
		y = {
			name = L["UIPANEL_FONT_YOFFS"],
			desc = L["UIPANEL_FONT_YOFFS_DESC"],
			type = "range",
			order = 21,
			min = -30,
			max = 30,
			step = 1,
			bigStep = 1,
		},
		DeleteAnchor = {
			name = L["TEXTLAYOUTS_DELANCHOR"],
			desc = L["TEXTLAYOUTS_DELANCHOR_DESC"],
			type = "execute",
			order = 40,
			func = function(info)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local Anchors = TEXT:GetTextLayoutSettings(layout)[display].Anchors
				local anchorNum = tonumber(info[textLayoutInfo.stringSetting + 1])
				
				tremove(Anchors, anchorNum)
				Anchors.n = Anchors.n - 1
				
				TMW.ACEOPTIONS:CompileOptions()
				UpdateIconsUsingTextLayout(layout)
				TEXT:LoadConfig()
			end,
			disabled = function(info)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local Anchors = TEXT:GetTextLayoutSettings(layout)[display].Anchors
				
				return Anchors.n <= 1 or TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
		},
	},
}
		
local textFontStringTemplate
textFontStringTemplate = {
	type = "group",
	name = function(info)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		
		if textFontStringTemplate.hidden(info) then
			-- The name method gets called even if the panel should be hidden
			-- so we do this to prevent settings tables for unused/undefined 
			-- font strings from being generated when they shouldn't be.
			return ""
		end

		return TEXT:GetStringName(TEXT:GetTextLayoutSettings(layout)[display], display)
	end,
	order = function(info) return tonumber(info[#info]) end,
	set = function(info, val)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		local setting = info[#info]

		TEXT:GetTextLayoutSettings(layout)[display][setting] = val

		UpdateIconsUsingTextLayout(layout)
		TEXT:LoadConfig()
	end,
	get = function(info)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])
		local setting = info[#info]

		return TEXT:GetTextLayoutSettings(layout)[display][setting]
	end,
	hidden = function(info)
		local layout = findlayout(info)
		local display = tonumber(info[textLayoutInfo.display])

		return layout and display and TEXT:GetTextLayoutSettings(layout).n < display
	end,
	args = {
		StringName = {
			name = L["TEXTLAYOUTS_RENAMESTRING"],
			desc = L["TEXTLAYOUTS_RENAMESTRING_DESC"],
			type = "input",
			order = 1,
		},
		SkinAs = {
			name = L["TEXTLAYOUTS_SKINAS"],
			desc = L["TEXTLAYOUTS_SKINAS_DESC"],
			type = "select",
			style = "dropdown",
			order = 2,
			values = TEXT.MasqueSkinnableTexts,
			set = function(info, val)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local setting = info[#info]

				assert(setting == "SkinAs")

				for id, strSettings in TMW:InNLengthTable(TEXT:GetTextLayoutSettings(layout)) do
					if strSettings[setting] == val and strSettings[setting] ~= "" then
						strSettings[setting] = ""
						TMW:Printf(L["TEXTLAYOUTS_RESETSKINAS"],
							L["TEXTLAYOUTS_SKINAS"],
							TEXT:GetStringName(strSettings, id),
							TEXT:GetStringName(TEXT:GetTextLayoutSettings(layout)[display], display)
						)
					end
				end

				TEXT:GetTextLayoutSettings(layout)[display][setting] = val

				UpdateIconsUsingTextLayout(layout)
				TEXT:LoadConfig()
			end,
			hidden = not LMB,
		},
		DefaultText = {
			name = L["TEXTLAYOUTS_DEFAULTTEXT"],
			desc = L["TEXTLAYOUTS_DEFAULTTEXT_DESC"],
			type = "input",
			width = "full",
			order = 4,
		},
		font = {
			name = L["TEXTLAYOUTS_FONTSETTINGS"],
			order = 20,
			type = "group",
			guiInline = true,
			dialogInline = true,			
			set = function(info, val)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local setting = info[#info]

				TEXT:GetTextLayoutSettings(layout)[display][setting] = val

				UpdateIconsUsingTextLayout(layout)
				TEXT:LoadConfig()
			end,
			get = function(info)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local setting = info[#info]

				return TEXT:GetTextLayoutSettings(layout)[display][setting]
			end,
			disabled = function(info)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])

				return
					TEXT:GetTextLayoutSettings(layout).NoEdit or
					(LMB and TEXT:GetTextLayoutSettings(layout)[display].SkinAs ~= "")
			end,
			args = {
				Name = {
					name = L["UIPANEL_FONTFACE"],
					desc = L["UIPANEL_FONT_DESC"],
					type = "select",
					order = 4,
					dialogControl = 'LSM30_Font',
					values = LSM:HashTable("font"),
				},
				Outline = {
					name = L["UIPANEL_FONT_OUTLINE"],
					desc = L["UIPANEL_FONT_OUTLINE_DESC"],
					type = "select",
					values = {
						[""] = L["OUTLINE_NO"],
						OUTLINE = L["OUTLINE_THIN"],
						THICKOUTLINE = L["OUTLINE_THICK"],
						MONOCHROME = L["OUTLINE_MONOCHORME"],
					},
					style = "dropdown",
					order = 1,
					disabled = function(info)
						local layout = findlayout(info)
						return TEXT:GetTextLayoutSettings(layout).NoEdit
					end,
				},
				Size = {
					name = L["UIPANEL_FONT_SIZE"],
					desc = L["UIPANEL_FONT_SIZE_DESC"],
					type = "range",
					order = 9,
					min = 6,
					softMax = 26,
					step = 1,
					bigStep = 1,
				},
				Shadow = {
					name = L["UIPANEL_FONT_SHADOW"],
					desc = L["UIPANEL_FONT_SHADOW_DESC"],
					type = "range",
					order = 10,
					min = 0,
					softMax = 3,
					step = 0.1,
					bigStep = 0.5,
				},
			},
		},
		
		position = {
			name = L["TEXTLAYOUTS_POSITIONSETTINGS"],
			order = 30,
			type = "group",
			guiInline = true,
			dialogInline = true,			
			set = function(info, val)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local setting = info[#info]

				TEXT:GetTextLayoutSettings(layout)[display][setting] = val

				UpdateIconsUsingTextLayout(layout)
				TEXT:LoadConfig()
			end,
			get = function(info)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local setting = info[#info]

				return TEXT:GetTextLayoutSettings(layout)[display][setting]
			end,
			disabled = function(info)
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])

				return
					TEXT:GetTextLayoutSettings(layout).NoEdit or
					(LMB and TEXT:GetTextLayoutSettings(layout)[display].SkinAs ~= "")
			end,
			args = {
				Justify = {
					name = L["UIPANEL_FONT_JUSTIFY"],
					desc = L["UIPANEL_FONT_JUSTIFY_DESC"],
					type = "select",
					values = TMW.justifyPoints,
					style = "dropdown",
					order = 2,
					disabled = function(info)
						local layout = findlayout(info)
						return TEXT:GetTextLayoutSettings(layout).NoEdit
					end,
				},
				JustifyV = {
					name = L["UIPANEL_FONT_JUSTIFYV"],
					desc = L["UIPANEL_FONT_JUSTIFYV_DESC"],
					type = "select",
					values = TMW.justifyVPoints,
					style = "dropdown",
					order = 3,
					disabled = function(info)
						local layout = findlayout(info)
						return TEXT:GetTextLayoutSettings(layout).NoEdit
					end,
				},
				AddAnchor = {
					name = L["TEXTLAYOUTS_ADDANCHOR"],
					desc = L["TEXTLAYOUTS_ADDANCHOR_DESC"],
					type = "execute",
					order = 4,
					func = function(info)
						local layout = findlayout(info)
						local display = tonumber(info[textLayoutInfo.display])
						local Anchors = TEXT:GetTextLayoutSettings(layout)[display].Anchors

						Anchors.n = Anchors.n + 1

						TMW.ACEOPTIONS:CompileOptions()
						UpdateIconsUsingTextLayout(layout)
						TEXT:LoadConfig()
					end,
				},


				size = {
					name = "",
					order = 1,
					type = "group",
					guiInline = true,
					dialogInline = true,
					args = {
						Width = {
							name = L["UIPANEL_FONT_WIDTH"],
							desc = L["UIPANEL_FONT_WIDTH_DESC"],
							type = "range",
							order = 1,
							min = 0,
							softMax = 60,
							step = 1,
							bigStep = 1,
						},
						Height = {
							name = L["UIPANEL_FONT_HEIGHT"],
							desc = L["UIPANEL_FONT_HEIGHT_DESC"],
							type = "range",
							order = 2,
							min = 0,
							softMax = 60,
							step = 1,
							bigStep = 1,
						},
					},
				},
			},
		},
	
		delete = {
			name = L["TEXTLAYOUTS_DELETESTRING"],
			desc = L["TEXTLAYOUTS_DELETESTRING_DESC"],
			type = "execute",
			order = 3,
			func = function(info)
				local layout, rawLayoutKey = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				
				-- MUST HAPPEN BEFORE WE REMOVE THE DISPLAY
				if TEXT:GetTextLayoutSettings(layout).n == display then
					TMW.ACEOPTIONS:LoadConfigPath(info, "textlayouts", rawLayoutKey, display - 1)
				else
					TMW.ACEOPTIONS:LoadConfigPath(info, "textlayouts", rawLayoutKey, display)
				end
				
				for i, fontStringSettings in TMW:InNLengthTable(TEXT:GetTextLayoutSettings(layout)) do
					for _, anchorSettings in TMW:InNLengthTable(fontStringSettings.Anchors) do
						local relativeTo = anchorSettings.relativeTo
						if relativeTo:sub(1, 2) == "$$" then
							relativeTo = tonumber(relativeTo:sub(3))
							if relativeTo > display then
								anchorSettings.relativeTo = "$$" .. relativeTo - 1
							elseif relativeTo == display then
								anchorSettings.relativeTo = ""
							end
						end
					end
				end
				
				tremove(TEXT:GetTextLayoutSettings(layout), display)
				TEXT:GetTextLayoutSettings(layout).n = TEXT:GetTextLayoutSettings(layout).n - 1
				
				TMW.ACEOPTIONS:CompileOptions()
				TMW.ACEOPTIONS:NotifyChanges()
				TMW:Update()
				TEXT:LoadConfig()
			end,
			disabled = function(info)
				local layout = findlayout(info)
				return textLayoutTemplate.disabled(info) or TEXT:GetTextLayoutSettings(layout).n == 1
			end,
			confirm = function(info)
			
				local layout = findlayout(info)
				local display = tonumber(info[textLayoutInfo.display])
				local displaySettings = TEXT:GetTextLayoutSettings(layout)[display]
				
				if IsControlKeyDown() then
					return false
				elseif not TEXT:Display_IsDefault(displaySettings) then
					return true
				end
				return false
			end,
		},
		
		NoEditDesc = {
			name = "\r\n" .. L["TEXTLAYOUTS_NOEDIT_DESC"] .. "\r\n",
			type = "description",
			order = 5,
			disabled = false,
			hidden = function(info)
				local layout = findlayout(info)
				return not TEXT:GetTextLayoutSettings(layout).NoEdit
			end,
		},
	},
}

local textlayouts_toplevel = {
	type = "group",
	name = L["TEXTLAYOUTS"],
	order = 20,
--[=[	set = function(info, val)
		TMW.db.profile[info[#info]] = val
		TMW:Update()
	end,
	get = function(info) return TMW.db.profile[info[#info]] end,]=]

	args = {
		addlayout = {
			name = L["TEXTLAYOUTS_ADDLAYOUT"],
			desc = L["TEXTLAYOUTS_ADDLAYOUT_DESC"],
			type = "execute",
			width = "double",
			order = 1,
			func = function(info)
				local layout = AddTextLayout()

				TMW.ACEOPTIONS:CompileOptions()
				TMW:Update()
				TEXT:LoadConfig()

				TMW.ACEOPTIONS:LoadConfigPath(info, "textlayouts", "#TextLayout " .. layout.GUID)
			end,
		},
		importExportBox = TMW.importExportBoxTemplate,
	},
}



TMW:RegisterCallback("TMW_CONFIG_MAIN_OPTIONS_COMPILE", function(event, OptionsTable)
	OptionsTable.args.textlayouts = textlayouts_toplevel
	
	-- Dynamic Text Settings --
	-- delete all current layouts
	for k, v in pairs(textlayouts_toplevel.args) do
		if v == textLayoutTemplate then
			textlayouts_toplevel.args[k] = nil
		end
	end
	for layoutID, layout in pairs(TMW.db.global.TextLayouts) do
		for fontStringID, fontString in TMW:InNLengthTable(layout) do
			-- this will expand textLayoutTemplate's args tables to the needed number
			-- unused textFontStringTemplate in it will not be removed - they are simply hidden.
			textLayoutTemplate.args[tostring(fontStringID)] = textFontStringTemplate
			
			for anchorID = 1, fontString.Anchors.n do
				-- this will expand textFontStringTemplate.args.position's args tables to the needed number
				-- unused anchorSet in it will not be removed - they are simply hidden.
				textFontStringTemplate.args.position.args[tostring(anchorID)] = anchorSet
			end
		end
		
		textlayouts_toplevel.args["#TextLayout " .. layoutID] = textLayoutTemplate
	end
end)







-- -------------------
-- IMPORT/EXPORT
-- -------------------

local textlayout = TMW.Classes.SharableDataType:New("textlayout", 15)
textlayout.extrasMap = {"GUID"}

function textlayout:Import_ImportData(Item, GUID)
	assert(type(GUID) == "string")
	
	TMW.db.global.TextLayouts[GUID] = nil -- restore defaults
	local textlayout = TMW.db.global.TextLayouts[GUID]
	TMW:CopyTableInPlaceWithMeta(Item.Settings, textlayout, true)
	textlayout.GUID = GUID

	if textlayout.NoEdit then
		textlayout.NoEdit = false -- must be false, not nil
	end
	
	repeat
		local found
		for k, layoutSettings in pairs(TMW.db.global.TextLayouts) do
			if layoutSettings ~= textlayout and layoutSettings.Name == textlayout.Name then
				textlayout.Name = TMW.oneUpString(textlayout.Name)
				found = true
				break
			end
		end
	until not found
	
	local version = Item.Version
	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("textlayout", version, textlayout, GUID)
		end
	end
	TMW:Update()
end

function textlayout:Import_CreateMenuEntry(info, Item)
	info.text = TMW.TEXT:GetLayoutName(Item.Settings, Item:GetExtra("GUID"))
end


-- Profile's text layouts
local SharableDataType_profile = TMW.Classes.SharableDataType.types.profile
SharableDataType_profile:RegisterMenuBuilder(20, function(Item_profile)

	if Item_profile.Settings.TextLayouts then
		local isGood = false
		for GUID, settings in pairs(Item_profile.Settings.TextLayouts) do
			if GUID ~= "" and settings.GUID then
				isGood = true
				break
			end
		end

		if not isGood then return end


		local SettingsBundle = TMW.Classes.SettingsBundle:New("textlayout")

		for GUID, layout in pairs(Item_profile.Settings.TextLayouts) do
			local Item = TMW.Classes.SettingsItem:New("textlayout")

			Item:SetParent(Item_profile)
			Item.Settings = layout
			Item:SetExtra("GUID", GUID)

			SettingsBundle:Add(Item)

		end

		if SettingsBundle:CreateParentedMenuEntry(L["TEXTLAYOUTS"]) then
			TMW.DD:AddSpacer()
		end
	end
end)

-- Import Layout
textlayout:RegisterMenuBuilder(1, function(Item_textlayout)
	local settings = Item_textlayout.Settings
	local GUID = Item_textlayout:GetExtra("GUID")

	assert(type(GUID) == "string")
	
	local layoutSettings = TMW.TEXT:GetTextLayoutSettings(GUID)
	
	if layoutSettings then
		-- overwrite existing
		local info = TMW.DD:CreateInfo()
		info.disabled = layoutSettings.NoEdit
		info.text = L["TEXTLAYOUTS_IMPORT"] .. " - " .. L["TEXTLAYOUTS_IMPORT_OVERWRITE"]
		info.tooltipTitle = info.text
		info.tooltipText = info.disabled and L["TEXTLAYOUTS_IMPORT_OVERWRITE_DISABLED_DESC"] or L["TEXTLAYOUTS_IMPORT_OVERWRITE_DESC"]
		info.tooltipWhileDisabled = true
		info.notCheckable = true
		
		info.func = function()
			Item_textlayout:Import(GUID)
		end
		TMW.DD:AddButton(info)
		
		-- create new
		local info = TMW.DD:CreateInfo()
		info.text = L["TEXTLAYOUTS_IMPORT"] .. " - " .. L["TEXTLAYOUTS_IMPORT_CREATENEW"]
		info.tooltipTitle = info.text
		info.tooltipText = L["TEXTLAYOUTS_IMPORT_CREATENEW_DESC"]
		info.notCheckable = true
		
		info.func = function()
			Item_textlayout:Import(TMW:GenerateGUID("textlayout", TMW.CONST.GUID_SIZE))
		end
		TMW.DD:AddButton(info)
	else
		-- import normally - the layout doesnt already exist
		local info = TMW.DD:CreateInfo()
		info.text = L["TEXTLAYOUTS_IMPORT"]
		info.tooltipTitle = info.text
		info.tooltipText = L["TEXTLAYOUTS_IMPORT_NORMAL_DESC"]
		info.notCheckable = true
		
		info.func = function()
			Item_textlayout:Import(GUID)
		end
		TMW.DD:AddButton(info)
	
	end
end)


textlayout.Export_DescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("6.0.0+")

function textlayout:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local GUID = EXPORTS[self.type]
	
	local text = L["fTEXTLAYOUT"]:format(TMW.TEXT:GetLayoutName(nil, GUID))
	info.text = text
	info.tooltipTitle = text
end

function textlayout:Export_GetArgs(editbox)
	-- settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local GUID = EXPORTS[self.type]
	assert(type(GUID) == "string")
	local settings = TMW.TEXT:GetTextLayoutSettings(GUID)
	
	return settings, TMW.Defaults.global.TextLayouts["**"], GUID
end


TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	
	import.textlayout_new = true
	
	if editbox == TMW.IE.ExportBox and CI.icon then
		local GUID = TEXT:GetTextLayoutForIcon(CI.icon)
		
		import.textlayout_overwrite = GUID
		export.textlayout = GUID
	elseif editbox.IsImportExportWidget then
		local info = editbox.obj.userdata		
		import.textlayout_overwrite = findlayout(info)
		export.textlayout = findlayout(info)
	end
end)


local function GetTextLayouts(event, strings, type, settings)
	if type == "icon" or type == "group" then
		for view, settingsPerView in pairs(settings.SettingsPerView) do
			local GUID = settingsPerView.TextLayout

			if GUID and GUID ~= "" then
				local layout = rawget(TMW.db.global.TextLayouts, GUID)
				if layout and not layout.NoEdit then
					TMW:GetSettingsStrings(strings, "textlayout", layout, TMW.Defaults.global.TextLayouts["**"], GUID)
				end
			end
		end
	end

	if type == "group" then
		for iconID, ics in pairs(settings.Icons) do
			GetTextLayouts(event, strings, "icon", ics)
		end
	end

	if type == "profile" then
		for groupID, gs in pairs(settings.Groups) do
			GetTextLayouts(event, strings, "group", gs)
		end
	end
end

TMW:RegisterCallback("TMW_EXPORT_SETTINGS_REQUESTED", GetTextLayouts)