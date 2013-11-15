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

TMW.WidthCol1 = 150

---------- Libraries ----------
local LSM = LibStub("LibSharedMedia-3.0")
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")

-- GLOBALS: LibStub
-- GLOBALS: TMWOptDB
-- GLOBALS: TELLMEWHEN_VERSION, TELLMEWHEN_VERSION_MINOR, TELLMEWHEN_VERSION_FULL, TELLMEWHEN_VERSIONNUMBER, TELLMEWHEN_MAXROWS
-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE, UIDROPDOWNMENU_OPEN_MENU
-- GLOBALS: UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, UIDropDownMenu_SetText, UIDropDownMenu_GetSelectedValue, UIDropDownMenu_Initialize, UIDropDownMenu_JustifyText, UIDropDownMenu_SetAnchor, UIDropDownMenu_StartCounting
-- GLOBALS: CloseDropDownMenus, ToggleDropDownMenu, DropDownList1
-- GLOBALS: NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR, INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, SPELL_RECAST_TIME_MIN, SPELL_RECAST_TIME_SEC, NONE, SPELL_CAST_CHANNELED, NUM_BAG_SLOTS, CANCEL
-- GLOBALS: GameTooltip, GameTooltip_SetDefaultAnchor
-- GLOBALS: UIParent, WorldFrame, TellMeWhen_IconEditor, GameFontDisable, GameFontHighlight, CreateFrame, collectgarbage 
-- GLOBALS: PanelTemplates_TabResize, PanelTemplates_Tab_OnClick

---------- Upvalues ----------
local TMW = TMW
local L = TMW.L
local GetSpellInfo =
	  GetSpellInfo
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, pcall, assert, rawget, rawset, unpack, select =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, pcall, assert, rawget, rawset, unpack, select
local strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10
local GetCursorPosition, GetCursorInfo, CursorHasSpell, CursorHasItem, ClearCursor =
	  GetCursorPosition, GetCursorInfo, CursorHasSpell, CursorHasItem, ClearCursor
local _G, bit, CopyTable, hooksecurefunc, IsAddOnLoaded, IsControlKeyDown, PlaySound =
	  _G, bit, CopyTable, hooksecurefunc, IsAddOnLoaded, IsControlKeyDown, PlaySound

local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures
local print = TMW.print
local Types = TMW.Types
local IE


---------- Locals ----------
local _, pclass = UnitClass("Player")
local tiptemp = {}
local get = TMW.get

---------- Globals ----------
--GLOBALS: BINDING_HEADER_TELLMEWHEN, BINDING_NAME_TELLMEWHEN_ICONEDITOR_UNDO, BINDING_NAME_TELLMEWHEN_ICONEDITOR_REDO
BINDING_HEADER_TELLMEWHEN = "TellMeWhen"
BINDING_NAME_TELLMEWHEN_ICONEDITOR_UNDO = L["UNDO_ICON"]
BINDING_NAME_TELLMEWHEN_ICONEDITOR_REDO = L["REDO_ICON"]


---------- Data ----------
local points = {
	TOPLEFT = L["TOPLEFT"],
	TOP = L["TOP"],
	TOPRIGHT = L["TOPRIGHT"],
	LEFT = L["LEFT"],
	CENTER = L["CENTER"],
	RIGHT = L["RIGHT"],
	BOTTOMLEFT = L["BOTTOMLEFT"],
	BOTTOM = L["BOTTOM"],
	BOTTOMRIGHT = L["BOTTOMRIGHT"],
} TMW.points = points

TMW.justifyPoints = {
	LEFT = L["LEFT"],
	CENTER = L["CENTER"],
	RIGHT = L["RIGHT"],
}

TMW.operators = {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}

TMW.EquivFullIDLookup = {}
TMW.EquivFullNameLookup = {}
TMW.EquivFirstIDLookup = {}
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do

		-- create the lookup tables first, so that we can have the first ID even if it will be turned into a name
		TMW.EquivFirstIDLookup[equiv] = strsplit(";", str) -- this is used to display them in the list (tooltip, name, id display)

		TMW.EquivFullIDLookup[equiv] = ";" .. str
		local tbl = TMW:SplitNames(str)
		for k, v in pairs(tbl) do
			tbl[k] = GetSpellInfo(v) or v
		end
		TMW.EquivFullNameLookup[equiv] = ";" .. table.concat(tbl, ";")
	end
end
for dispeltype, icon in pairs(TMW.DS) do
	TMW.EquivFirstIDLookup[dispeltype] = icon
end



---------- Miscellaneous ----------
TMW.Backupdb = CopyTable(TellMeWhenDB)
TMW.BackupDate = date("%I:%M:%S %p")

TMW.CI = setmetatable({}, {__index = function(tbl, k)
	if k == "ic" then
		return tbl.icon
	elseif k == "group" then
		return tbl.icon and tbl.icon.group
	elseif k == "ics" then
		return tbl.icon and tbl.icon:GetSettings()
	elseif k == "gs" then
		-- take no chances with errors occuring here
		return tbl.group and tbl.group:GetSettings()
	end
end}) local CI = TMW.CI		--current icon



-- ----------------------
-- WOW API HOOKS
-- ----------------------

-- Dropdown tooltip wrapping.
GameTooltip.TMW_OldAddLine = GameTooltip.AddLine
function GameTooltip:AddLine(text, r, g, b, wrap, ...)
	-- this fixes the problem where tooltips in blizz dropdowns dont wrap, nor do they have a setting to do it.
	-- Pretty hackey fix, but it works
	-- Only force the wrap option if the current dropdown has wrapTooltips set true, the dropdown is shown, and the mouse is over the dropdown menu (not DDL.isCounting)
	local DDL = DropDownList1
	if DDL and not DDL.isCounting and DDL.dropdown and DDL.dropdown.wrapTooltips and DDL:IsShown() then
		wrap = 1
	end
	self:TMW_OldAddLine(text, r, g, b, wrap, ...)
end

function GameTooltip:TMW_SetEquiv(equiv)
	GameTooltip:AddLine(L[equiv], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(IE:Equiv_GenerateTips(equiv), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
end


-- GLOBALS: ChatEdit_InsertLink
TMW:NewClass("ChatEdit_InsertLink_Hook"){
	OnNewInstance = function(self, editbox, func)		
		TMW:ValidateType(2, "ChatEdit_InsertLink_Hook:New()", editbox, "frame")
		TMW:ValidateType(3, "ChatEdit_InsertLink_Hook:New()", func, "function")
		
		self.func = func
		self.editbox = editbox
	end,
	
	Call = function(self, text, linkType, linkData)
		if self.editbox:HasFocus() then
			return TMW.safecall(self.func, self, text, linkType, linkData)
		end
	end,
}

local old_ChatEdit_InsertLink = ChatEdit_InsertLink
local function hook_ChatEdit_InsertLink(text)	
	if type(text) ~= "string" then
		return false
	end
	
	local Type, data = strmatch(text, "|H(.-):(.-)|h")
	
	for _, instance in pairs(TMW.Classes.ChatEdit_InsertLink_Hook.instances) do
		local executionSuccess, insertResult = instance:Call(text, Type, data)
		if executionSuccess and insertResult then
			return insertResult
		end
	end
	
	return false
end

function ChatEdit_InsertLink(...)
	local executionSuccess, insertSuccess = TMW.safecall(hook_ChatEdit_InsertLink, ...)
	if executionSuccess and insertSuccess then
		return insertSuccess
	else
		return old_ChatEdit_InsertLink(...)
	end
end


-- ----------------------
-- GENERAL CONFIG FUNCTIONS
-- ----------------------

function TMW.approachTable(t, ...)
	for i=1, select("#", ...) do
		local k = select(i, ...)
		if type(k) == "function" then
			t = k(t)
		else
			t = t[k]
		end
		if not t then return end
	end
	return t
end

---------- Icon Utilities ----------
function TMW:GetIconMenuText(ics)
	local Type = ics.Type or ""
	local typeData = Types[Type]

	local text, tooltip, dontShorten = typeData:GetIconMenuText(ics)
	text = tostring(text)
	
	tooltip = tooltip or ""
	
	text = text == "" and (L["UNNAMED"] .. ((Type ~= "" and typeData and (" - " .. typeData.name) or ""))) or text
	local textshort = not dontShorten and strsub(text, 1, 40) or text

	if strlen(text) > 40 and not dontShorten then
		textshort = textshort .. "..."
	end

	tooltip =	tooltip ..
				((Type ~= "" and typeData.name) or "") ..
				((ics.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")

	return text, textshort, tooltip
end

function TMW:GuessIconTexture(ics)
	local tex

	if ics.CustomTex then
		tex = TMW:GetTexturePathFromSetting(ics.CustomTex)
	end
	
	if not tex then
		tex = TMW.Types[ics.Type]:GuessIconTexture(ics)
	end
	
	if not tex then
		tex = "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	
	return tex
end

function TMW:PrepareIconSettingsForCopying(ics, gs)
	TMW:Fire("TMW_ICON_PREPARE_SETTINGS_FOR_COPY", ics, gs)
end

function TMW.IconsSort(a, b)
	local icon1, icon2 = _G[a], _G[b]
	local g1 = icon1.group:GetID()
	local g2 = icon2.group:GetID()
	if g1 ~= g2 then
		return g1 < g2
	else
		return icon1:GetID() < icon2:GetID()
	end
end


---------- Dropdown Utilities ----------
function TMW:SetUIDropdownText(frame, value, tbl, text)
	frame.selectedValue = value

	if tbl then
		for k, v in pairs(tbl) do
			if v.value == value then
				UIDropDownMenu_SetText(frame, v.text)
				return v
			end
		end
	end
	UIDropDownMenu_SetText(frame, text or value)
end

function TMW:SetUIDropdownGUIDText(frame, GUID, text)
	frame.selectedValue = GUID

	local owner = TMW.GUIDToOwner[GUID]
	local type = TMW:ParseGUID(GUID)

	if owner then
		if type == "icon" then
			local icon = owner

			UIDropDownMenu_SetText(frame, icon:GetIconMenuText())

			return icon

		elseif type == "group" then
			local group = owner

			UIDropDownMenu_SetText(frame, group:GetGroupName())

			return group
		end

	elseif GUID and GUID ~= "" then
		if type == "icon" then
			text = L["UNKNOWN_ICON"]
		elseif type == "group" then
			text = L["UNKNOWN_GROUP"]
		else
			text = L["UNKNOWN_UNKNOWN"]
		end
	end
	
	UIDropDownMenu_SetText(frame, text)
end

local spacerInfo = {
	text = "",
	isTitle = true,
	notCheckable = true,
}
function TMW.AddDropdownSpacer()
	UIDropDownMenu_AddButton(spacerInfo, UIDROPDOWNMENU_MENU_LEVEL)
end

function TMW.SetIconPreviewIcon(self, icon)
	if not icon or not icon.IsIcon then
		self:Hide()
		return
	end

	local desc = L["ICON_TOOLTIP2NEWSHORT"]

	if TMW.db.global.ShowGUIDs then
		desc = desc .. "\r\n\r\n|cffffffff" .. (not icon.TempGUID and (icon:GetGUID() .. "\r\n") or "") .. icon.group:GetGUID()
	end

	TMW:TT(self, icon:GetIconName(), desc, 1, 1)
	self.icon = icon
	self.texture:SetTexture(icon and icon.attributes.texture)
	self:Show()
end

function TMW.SetUIDropdownGUID(self, GUID)
	local icon = TMW.GUIDToOwner[GUID]

	TMW:SetUIDropdownGUIDText(self, GUID, L["CHOOSEICON"])
	self.IconPreview:SetIcon(icon)
end

function TMW.SetUIDropdownIcon(self, icon)
	local GUID = icon:GetGUID()

	TMW:SetUIDropdownGUIDText(self, GUID, L["CHOOSEICON"])
	self.IconPreview:SetIcon(icon)
end


---------- DogTag Utilities ----------
do
	local DogTag = LibStub("LibDogTag-3.0")
	local EvaluateError

	local function test(success, ...)
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
			EvaluateError = text
		end)
	end

	-- Tests a dogtag string. Returns a string if there is an error.
	function TMW:TestDogTagString(icon, text, ns, kwargs)
		icon:Setup()
		
		ns = ns or "TMW;Unit;Stats"
		kwargs = kwargs or {
			icon = icon.ID,
			group = icon.group.ID,
			unit = icon.attributes.dogTagUnit,
		}

		-- Test the string and its tags & syntax

		-- These operations are required when passing true as the 4th param (notDebug)
		-- notDebug has to be true because otherwise DogTag will throw errors if the
		-- user's input contains newlines. 
		local kwargTypes = DogTag.kwargsToKwargTypes[kwargs]
		ns = DogTag.fixNamespaceList[ns]

		local funcString = DogTag:CreateFunctionFromCode(text, ns, kwargs, true)
		local func = loadstring(funcString)
		local success, newfunc = pcall(func)

		if not success then
			return "CRITICAL ERROR: " .. newfunc
		end

		func = func and success and newfunc

		if not func then
			return
		end

		local tagError = test(pcall(func, kwargs))

		if tagError then
			return "ERROR: " .. tagError
		else
			EvaluateError = nil
			DogTag:Evaluate(text, ns, kwargs)

			if EvaluateError then
				return "CRITICAL ERROR: " .. EvaluateError
			end
		end
	end
end

---------- Misc Utilities ----------
function TMW:ConvertContainerToScrollFrame(container, exteriorScrollBarPosition, scrollBarXOffs, scrollBarSizeX)
    
    
    local ScrollFrame = CreateFrame("ScrollFrame", container:GetName() .. "ScrollFrame", container:GetParent(), "TellMeWhen_ScrollFrameTemplate")
    
    local x, y = container:GetSize()
    ScrollFrame:SetSize(x, y)
    for i = 1, container:GetNumPoints() do
        ScrollFrame:SetPoint(container:GetPoint(i))
    end
    
    container:ClearAllPoints()
    
    ScrollFrame:SetScrollChild(container)
    container:SetSize(x, 1)
	
	if exteriorScrollBarPosition then
		ScrollFrame.ScrollBar:SetPoint("LEFT", ScrollFrame, "RIGHT", scrollBarXOffs or 0, 0)
	else
		ScrollFrame.ScrollBar:SetPoint("RIGHT", ScrollFrame, "RIGHT", scrollBarXOffs or 0, 0)
	end
	
	if scrollBarSizeX then
		ScrollFrame.ScrollBar:SetWidth(scrollBarSizeX)
	end
    
    container.ScrollFrame = ScrollFrame
    ScrollFrame.container = container
    
end

function TMW:AnimateHeightChange(f, endHeight, duration)
	
	-- This function currently disabled because of frame level issues.
	-- Top frames need to be above lower frames, but editboxes seem to go underneath everything for some reason.
	-- It doesn't look awful, but I'm going to leave it disabled till I decide otherwise.
	f:SetHeight(endHeight)
	do return end
	
	if not f.__animateHeightHooked then
		f.__animateHeightHooked = true
		f:HookScript("OnUpdate", function(f)
				if f.__animateHeight_duration then
					if TMW.time - f.__animateHeight_startTime > f.__animateHeight_duration then
						f.__animateHeight_duration = nil
						f:SetHeight(f.__animateHeight_end)
						return  
					end
					
					local pct = (TMW.time - f.__animateHeight_startTime)/f.__animateHeight_duration
					
					f:SetHeight((pct*f.__animateHeight_delta)+f.__animateHeight_start)
				end
		end)    
	end
	
	f.__animateHeight_start = f:GetHeight()
	f.__animateHeight_end = endHeight
	f.__animateHeight_delta = f.__animateHeight_end - f.__animateHeight_start
	f.__animateHeight_startTime = TMW.time
	f.__animateHeight_duration = duration
end

do	-- TMW:GetParser()
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3
	function TMW:GetParser()
		if not Parser then
			Parser = CreateFrame("GameTooltip")

			LT1 = Parser:CreateFontString()
			RT1 = Parser:CreateFontString()
			Parser:AddFontStrings(LT1, RT1)

			LT2 = Parser:CreateFontString()
			RT2 = Parser:CreateFontString()
			Parser:AddFontStrings(LT2, RT2)

			LT3 = Parser:CreateFontString()
			RT3 = Parser:CreateFontString()
			Parser:AddFontStrings(LT3, RT3)
		end
		return Parser, LT1, LT2, LT3, RT1, RT2, RT3
	end
end




-- --------------
-- MAIN OPTIONS
-- --------------

---------- Data/Templates ----------
local function FindGroupFromInfo(info)
	for i = #info, 1, -1 do
		local n = strmatch(info[i], "#Group (%d+)")
		if n then
			local domain = strmatch(info[i-1], "groups_(.+)")

			return TMW[domain][tonumber(n)]
		end
	end
end TMW.FindGroupFromInfo = FindGroupFromInfo

local checkorder = {
	-- NOTE: these are actually backwards so they sort logically in AceConfig, but have their signs switched in the actual function (1 = -1; -1 = 1).
	[-1] = L["ASCENDING"],
	[1] = L["DESCENDING"],
}
local fontorder = {
	Count = 40,
	Bind = 50,
}
local importExportBoxTemplate = {
	name = L["IMPORT_EXPORT"],
	type = "input",
	order = 200,
	width = "full",
	dialogControl = "TMW-ImportExport",
	get = function() end,
	set = function() end,
	--hidden = function() return IE.ExportBox:IsVisible() end,
} TMW.importExportBoxTemplate = importExportBoxTemplate

local specializationSettingHidden = function(info)
	local group = FindGroupFromInfo(info)
	if group.Domain == "global" then
		return true
	end
	return false
end

TMW.GroupConfigTemplate = {
	type = "group",
	childGroups = "tab",
	name = function(info)
		local group = FindGroupFromInfo(info)
		if group.Name ~= "" then
			return group:GetGroupName(1)
		else
			return group:GetGroupName()
		end
	end,
	order = function(info)
		local group = FindGroupFromInfo(info)
		return group and group:GetID() or 0
	end,
	set = function(info, val)
		local group = FindGroupFromInfo(info)
		
		group:GetSettings()[info[#info]] = val
		group:Setup()
	end,
	get = function(info)
		local group = FindGroupFromInfo(info)

		return group:GetSettings()[info[#info]]
	end,
	args = {
		main = {
			type = "group",
			name = L["MAIN"],
			desc = L["UIPANEL_MAIN_DESC"],
			order = 1,
			args = {
				Enabled = {
					name = function(info)
						local group = FindGroupFromInfo(info)

						if group.Domain == "global" then
							return L["UIPANEL_ENABLEGROUP_FORPROFILE"]:format(TMW.db:GetCurrentProfile())
						elseif group.Domain == "profile" then
							return L["UIPANEL_ENABLEGROUP"]
						end
					end,
					desc = function(info)
						local group = FindGroupFromInfo(info)

						if group.Domain == "global" then
							return L["UIPANEL_TOOLTIP_ENABLEGROUP_GLOBAL_DESC"]
						elseif group.Domain == "profile" then
							return L["UIPANEL_TOOLTIP_ENABLEGROUP"]
						end
					end,

					type = "toggle",
					order = 1,
					width = "full",
					set = function(info, val)
						local group = FindGroupFromInfo(info)
						
						if group.Domain == "global" then
							group:GetSettings().EnabledProfiles[TMW.db:GetCurrentProfile()] = val
						elseif group.Domain == "profile" then
							group:GetSettings().Enabled = val
						end

						group:Setup()
					end,
					get = function(info)
						local group = FindGroupFromInfo(info)

						if group.Domain == "global" then
							return group:GetSettings().EnabledProfiles[TMW.db:GetCurrentProfile()]
						elseif group.Domain == "profile" then
							return group:GetSettings().Enabled
						end
					end,
				},
				Name = {
					name = L["UIPANEL_GROUPNAME"],
					type = "input",
					order = 2,
					width = "full",
					set = function(info, val)
						local group = FindGroupFromInfo(info)

						group:GetSettings().Name = strtrim(val)
						group:Setup()
					end,
				},
				OnlyInCombat = {
					name = L["UIPANEL_ONLYINCOMBAT"],
					desc = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"],
					type = "toggle",
					order = 4,
				},
				PrimarySpec = {
					name = L["UIPANEL_PRIMARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_PRIMARYSPEC"],
					type = "toggle",
					order = 7,
					hidden = specializationSettingHidden,
				},
				SecondarySpec = {
					name = L["UIPANEL_SECONDARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_SECONDARYSPEC"],
					type = "toggle",
					order = 8,
					hidden = specializationSettingHidden,
				},
				Columns = {
					name = L["UIPANEL_COLUMNS"],
					desc = L["UIPANEL_TOOLTIP_COLUMNS"],
					type = "range",
					order = 20,
					min = 1,
					max = TELLMEWHEN_MAXROWS,
					step = 1,
					bigStep = 1,
				},
				Rows = {
					name = L["UIPANEL_ROWS"],
					desc = L["UIPANEL_TOOLTIP_ROWS"],
					type = "range",
					order = 21,
					min = 1,
					max = TELLMEWHEN_MAXROWS,
					step = 1,
					bigStep = 1,
				},
				
				CheckOrder = {
					name = L["CHECKORDER"],
					desc = L["CHECKORDER_ICONDESC"],
					type = "select",
					values = checkorder,
					style = "dropdown",
					order = 26,
				},
				View = {
					name = L["UIPANEL_GROUPTYPE"],
					desc = L["UIPANEL_GROUPTYPE_DESC"],
					type = "group",
					dialogInline = true,
					guiInline = true,
					order = 30,
					get = function(info)
						local group = FindGroupFromInfo(info)
						return group:GetSettings()[info[#info-1]] == info[#info]
					end,
					set = function(info)
						local group = FindGroupFromInfo(info)
						group:GetSettings()[info[#info-1]] = info[#info]
						
						-- This intentional. Double setup is needed for dealing with Masque bullshit,
						-- Second setup is addon-wide so that all icons and groups can become aware of the new view if needed.
						group:Setup()
						TMW:Update()
						
						IE:Load(1)
					end,
					args = {}
				},
				moveup = {
					name = L["UIPANEL_GROUPMOVEUP"],
					desc = L["UIPANEL_GROUPMOVEUP_DESC"],
					type = "execute",
					order = 48,
					func = function(info)
						local domain = FindGroupFromInfo(info).Domain

						TMW:Group_Swap(domain, FindGroupFromInfo(info).ID, FindGroupFromInfo(info).ID - 1)

						IE:NotifyChanges("groups_" .. domain, "#Group " .. FindGroupFromInfo(info).ID - 1)
					end,
					disabled = function(info)
						return FindGroupFromInfo(info).ID == 1
					end,
				},
				movedown = {
					name = L["UIPANEL_GROUPMOVEDOWN"],
					desc = L["UIPANEL_GROUPMOVEDOWN_DESC"],
					type = "execute",
					order = 49,
					func = function(info)
						local domain = FindGroupFromInfo(info).Domain

						TMW:Group_Swap(domain, FindGroupFromInfo(info).ID, FindGroupFromInfo(info).ID + 1)

						IE:NotifyChanges("groups_" .. domain, "#Group " .. FindGroupFromInfo(info).ID + 1)
					end,
					disabled = function(info)
						local group = FindGroupFromInfo(info)
						return group.ID == TMW.db[group.Domain].NumGroups
					end,
				},
				delete = {
					name = L["UIPANEL_DELGROUP"],
					desc = L["UIPANEL_DELGROUP_DESC2"],
					type = "execute",
					order = 50,
					func = function(info)
						local group = FindGroupFromInfo(info)
						TMW:Group_Delete(group)
					end,
					confirm = function(info)
						if IsControlKeyDown() then
							return false
						elseif TMW:Group_HasIconData(FindGroupFromInfo(info)) then
							return true
						end
						return false
					end,
				},
				switchDomain = {
					name = function(info)
						local group = FindGroupFromInfo(info)
						if group.Domain == "global" then
							return L["DOMAIN_PROFILE_SWITCHTO"]:format(TMW.db:GetCurrentProfile())
						else
							return L["DOMAIN_GLOBAL_SWITCHTO"]
						end
					end,
					desc = function(info)
						local group = FindGroupFromInfo(info)
						if group.Domain == "profile" then
							return L["GLOBAL_GROUP_GENERIC_DESC"]
						end
					end,
					type = "execute",
					width = "full",
					order = 60,
					func = function(info)
						local group = FindGroupFromInfo(info)
						group:SwitchDomain()

						IE:Load(1)
						IE:NotifyChanges()
					end,
				},
				ImportExport = importExportBoxTemplate,
			},
		},
		position = {
			type = "group",
			order = 20,
			name = L["UIPANEL_POSITION"],
			desc = L["UIPANEL_POSITION_DESC"],
			args = {
				lock = {
					name = L["UIPANEL_LOCK"],
					desc = L["UIPANEL_LOCK_DESC"],
					type = "toggle",
					order = 40,
					set = function(info, val)
						local group = FindGroupFromInfo(info)

						group:GetSettings().Locked = val
				
						group:Setup()
					end,
					get = function(info)
						local group = FindGroupFromInfo(info)

						return group:GetSettings().Locked
					end
				},
			},
		},
	}
}

for i, role in TMW:Vararg("DAMAGER", "HEALER", "TANK") do
	local settingBit = bit.lshift(1, i-1)
	TMW.GroupConfigTemplate.args.main.args[role] = {
		type = "toggle",
		name = L["ROLEf"]:format(_G[role]),
		desc = L["UIPANEL_ROLE_DESC"],
		order = 9+i,
		set = function(info, val)
			local group = FindGroupFromInfo(info)
			local gs = group:GetSettings()

			gs.Role = bit.bxor(gs.Role, settingBit)

			group:Setup()
		end,
		get = function(info)
			local group = FindGroupFromInfo(info)

			return bit.band(group:GetSettings().Role, settingBit) == settingBit
		end,
	}
end
local addGroupFunctionGroup = {
	type = "group",
	name = L["UIPANEL_ADDGROUP"],
	dialogInline = true,
	guiInline = true,
	order = 40,
	args = {},
}
local addGroupButton = {
	name = function(info)
		return TMW.Views[info[#info]].name
	end,
	desc = L["UIPANEL_ADDGROUP_DESC"],
	type = "execute",
	width = "double",
	order = function(info)
		return TMW.Views[info[#info]].order
	end,
	func = function(info)
		for i = #info, 1, -1 do
			local domain = strmatch(info[i], "groups_(.+)")

			if domain then
				return TMW:Group_Add(domain, info[#info])
			end
		end
	end,
}
local viewSelectToggle = {
	name = function(info)
		return TMW.Views[info[#info]].name
	end,
	desc = function(info)
		return TMW.Views[info[#info]].desc
	end,
	type = "toggle",
	order = function(info)
		return TMW.Views[info[#info]].order
	end,
}

local colorOrder = {
	"CBS",
	"CBM",
	"CBC",

	"OOR",
	"OOM",
	"OORM",

	"CTA",
	"COA",
	"CTS",
	"COS",

	"NA",
	"NS",
}
local colorTemplate = {
	type = "group",
	name = "",
	guiInline = true,
	dialogInline = true,
	width = "full",
	order = function(info)
		local this = info[#info]
		for order, key in pairs(colorOrder) do
			if key == this then
				return order + 10
			end
		end
	end,

	args = {
		header = {
			order = 0,
			type = "header",
			name = function(info)
				return L["COLOR_" .. info[#info-1]]
			end,
		},
		color = {
			name = L["COLOR_COLOR"],
			desc = function(info)
				return L["COLOR_" .. info[#info-1] .. "_DESC"]
			end,
			type = "color",
			order = 2,
			--width = "double",
			hasAlpha = function(info)
				return strsub(info[#info-1], 1, 2) == "CB"
			end,
			set = function(info, r, g, b, a)
				local c = TMW.db.profile.Colors[info[#info-2]][info[#info-1]]

				c.r = r c.g = g c.b = b c.a = a
				c.Override = true
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				local base = TMW.db.profile.Colors[info[#info-2]][info[#info-1]]
				local c = base
				if not base.Override then
				--	c = TMW.db.profile.Colors["GLOBAL"][info[#info-1]] -- i don't like this. too confusing to see the color change when checking and unchecking the setting
				end

				return c.r, c.g, c.b, c.a
			end,
			disabled = function(info)
				return not TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL"
			end
		},
		override = {
			name = L["COLOR_OVERRIDEDEFAULT"],
			desc = L["COLOR_OVERRIDEDEFAULT_DESC"],
			type = "toggle",
			width = "half",
			order = 1,
			set = function(info, val)
				TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override = val
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				return TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override
			end,
			hidden = function(info)
				return info[#info-2] == "GLOBAL"
			end,
		},
		gray = {
			name = L["COLOR_DESATURATE"],
			desc = L["COLOR_DESATURATE_DESC"],
			type = "toggle",
			width = "half",
			order = 3,
			set = function(info, val)
				TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Gray = val
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				return TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Gray
			end,
			disabled = function(info)
				return strsub(info[#info-1], 1, 2) == "CB" or (not TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL")
			end
		},
		reset = {
			name = RESET,
			desc = L["COLOR_RESET_DESC"],
			type = "execute",
			width = "half",
			order = 10,
			func = function(info)
				TMW.db.profile.Colors[info[#info-2]][info[#info-1]] = CopyTable(TMW.Defaults.profile.Colors["**"][info[#info-1]])
			end,
		--[=[	disabled = function(info)
				return not TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL"
			end]=]
		},
	},
}
local colorIconTypeTemplate = {
	type = "group",
	name = function(info)
		if info[#info] == "GLOBAL" then
			return L["COLOR_DEFAULT"]
		end
		return TMW.Types[info[#info]].name
	end,
	order = function(info)
		local this = info[#info]

		if this == "GLOBAL" then
			return 0
		end

		for order, type in ipairs(TMW.OrderedTypes) do
			if type.type == this then
				return order
			end
		end
	end,

	--only inherited by ColorMSQ and OnlyMSQ:
	set = function(info, val)
		TMW.db.profile[info[#info]] = val
		TMW:Update()
	end,
	get = function(info)
		return TMW.db.profile[info[#info]]
	end,

	args = {
		desc = {
			order = 0,
			type = "description",
			name = function(info)
				local this = info[#info-1]
				local t

				if this == "GLOBAL" then
					t = L["COLOR_HEADER_DEFAULT"]
				else
					t = L["COLOR_HEADER"]:format(TMW.Types[this].name, "?")-- 2nd param is to prevent errors incase StaticFormats errors
				end
				return t .. "\r\n"
			end,
		},

		ColorMSQ = {
			name = L["COLOR_MSQ_COLOR"],
			desc = L["COLOR_MSQ_COLOR_DESC"],
			type = "toggle",
			order = 1,
			hidden = function(info)
				return not LMB or info[#info-1] ~= "GLOBAL"
			end,
		},
		OnlyMSQ = {
			name = L["COLOR_MSQ_ONLY"],
			desc = L["COLOR_MSQ_ONLY_DESC"],
			type = "toggle",
			width = "double",
			order = 2,
			hidden = function(info)
				return not LMB or info[#info-1] ~= "GLOBAL"
			end,
			disabled = function(info)
				return not TMW.db.profile.ColorMSQ
			end,
		},
		ColorGCD = {
			name = L["COLOR_IGNORE_GCD"],
			desc = L["COLOR_IGNORE_GCD_DESC"],
			type = "toggle",
			order = 3,
			hidden = function(info)
				return not LMB or info[#info-1] ~= "GLOBAL"
			end,
		},
	}
}
for k, v in pairs(colorOrder) do
	colorIconTypeTemplate.args[v] = colorTemplate
end


		TMW.OptionsTable = {
			name = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL,
			type = "group",
			args = {
				main = {
					type = "group",
					name = L["UIPANEL_MAINOPT"],
					order = 1,
					set = function(info, val)
						TMW.db.profile[info[#info]] = val
						TMW:ScheduleUpdate(0.4)
					end,
					get = function(info) return TMW.db.profile[info[#info]] end,
					args = {
						AllowCombatConfig = {
							name = L["UIPANEL_COMBATCONFIG"],
							desc = L["UIPANEL_COMBATCONFIG_DESC"],
							type = "toggle",
							order = 2.5,
							confirm = function(info)
								return not TMW.db.global[info[#info]]
							end,
							set = function(info, val)
								TMW.db.global[info[#info]] = val
							end,
							get = function(info) return TMW.db.global[info[#info]] end,
						},
						Locked = {
							name = L["UIPANEL_LOCKUNLOCK"],
							desc = L["UIPANEL_SUBTEXT2"],
							type = "toggle",
							order = 2,
						},
						TextureName = {
							name = L["UIPANEL_BARTEXTURE"],
							type = "select",
							order = 3,
							dialogControl = 'LSM30_Statusbar',
							values = LSM:HashTable("statusbar"),
						},
						sliders = {
							type = "group",
							order = 9,
							name = "",
							guiInline = true,
							dialogInline = true,
							args = {
								Interval = {
									name = L["UIPANEL_UPDATEINTERVAL"],
									desc = L["UIPANEL_TOOLTIP_UPDATEINTERVAL"],
									type = "range",
									order = 9,
									min = 0,
									max = 0.5,
									step = 0.01,
									bigStep = 0.01,
								},
								EffThreshold = {
									name = L["UIPANEL_EFFTHRESHOLD"],
									desc = L["UIPANEL_EFFTHRESHOLD_DESC"],
									type = "range",
									order = 10,
									min = 0,
									max = 40,
									step = 1,
								},
							},
						},
						checks = {
							type = "group",
							order = 21,
							name = "",
							guiInline = true,
							dialogInline = true,
							args = {
								DEBUG_ForceAutoUpdate = {
									name = "DEBUG: FORCE AUTO UPDATES",
									desc = "TMW v5 introduced new code that manages updates much more efficiently, only updating icons when they need to be updated. Check this to disable this feature in order to compare between the old method and the new method to see if there are any discrepancies that may be indicative of a bug.",
									type = "toggle",
									order = 1,
									hidden = true,
								},
								--[[ColorNames = {
									name = L["COLORNAMES"],
									desc = L["COLORNAMES_DESC"],
									type = "toggle",
									order = 42,
								},]]
								--[[AlwaysSubLinks = {
									-- unused
									name = L["ALWAYSSUBLINKS"],
									desc = L["ALWAYSSUBLINKS_DESC"],
									type = "toggle",
									order = 43,
								},]]
								--[[SUG_atBeginning = {
									-- I really doubt that anyone uses this setting at all.
									-- Going to hide it and see if anyone complains.
									
									name = L["SUG_ATBEGINING"],
									desc = L["SUG_ATBEGINING_DESC"],
									width = "double",
									type = "toggle",
									order = 44,
								},]]
								ReceiveComm = {
									name = L["ALLOWCOMM"],
									desc = L["ALLOWCOMM_DESC"],
									type = "toggle",
									order = 50,
								},
								WarnInvalids = {
									name = L["UIPANEL_WARNINVALIDS"],
									type = "toggle",
									width = "double",
									order = 51,
								},
								VersionWarning = {
									name = L["ALLOWVERSIONWARN"],
									type = "toggle",
									order = 52,
									set = function(info, val)
										TMW.db.global[info[#info]] = val
									end,
									get = function(info) return TMW.db.global[info[#info]] end,
								},
								ShowGUIDs = {
									name = L["SHOWGUIDS_OPTION"],
									desc = L["SHOWGUIDS_OPTION_DESC"],
									type = "toggle",
									order = 52,
									set = function(info, val)
										TMW.db.global[info[#info]] = val
									end,
									get = function(info) return TMW.db.global[info[#info]] end,
								},
							},
						},

						SoundChannel = {
							name = L["SOUND_CHANNEL"],
							desc = L["SOUND_CHANNEL_DESC"],
							type = "select",
							values = {
								-- GLOBALS: SOUND_VOLUME, MUSIC_VOLUME, AMBIENCE_VOLUME
								SFX = SOUND_VOLUME,
								Music = MUSIC_VOLUME,
								Ambience = AMBIENCE_VOLUME,
								Master = L["SOUND_CHANNEL_MASTER"],
							},
							order = 29,
						},
						CheckOrder = {
							name = L["CHECKORDER"],
							desc = L["CHECKORDER_GROUPDESC"],
							type = "select",
							values = checkorder,
							style = "dropdown",
							order = 30,
						},
						--[[resetall = {
							name = L["UIPANEL_ALLRESET"],
							desc = L["UIPANEL_TOOLTIP_ALLRESET"],
							type = "execute",
							order = 51,
							confirm = true,
							func = function() TMW.db:ResetProfile() end,
						},]]
						importexport = importExportBoxTemplate,

						deleteNonCurrentLocaleData = {
							name = ("Delete non-essential cached data for non-%s locales."):format(GetLocale()),
							desc = "TellMeWhen_Options caches some data about WoW's spells for each locale that you play in. You can safely delete that data for other locales to free up space.",
							type = "execute",
							width = "full",
							order = 1000,
							func = function(info)
								local currentLocale = GetLocale():lower()

								for locale in pairs(TMW.IE.db.sv.locale) do
									if locale ~= currentLocale then
										TMW.IE.db.sv.locale[locale] = nil
										TMW:Printf("Deleted cache for locale %s", locale)
									end
								end
							end,
							hidden = function(info)
								local locale = TMW.IE.db.sv.locale
								-- This evaluates to nil when there is only one locale in the table
								return next(locale, next(locale)) == nil
							end,
						},
					},
				},

				colors = {
					type = "group",
					name = L["UIPANEL_COLORS"],
					desc = L["UIPANEL_COLORS_DESC"],
					order = 10,
					childGroups = "tree",
					args = {},
				},
				
				groups_global = {
					type = "group",
					name = L["UIPANEL_GROUPS"] .. " - " .. L["DOMAIN_GLOBAL"],
					desc = L["UIPANEL_GROUPS_GLOBAL_DESC"],
					order = 30,
					args = {
						addgroup = addGroupFunctionGroup,
						importexport = importExportBoxTemplate,
						addgroupgroup = {
							type = "group",
							name = L["UIPANEL_ADDGROUP"],
							order = 2000,
							args = {
								addgroup = addGroupFunctionGroup,
								importexport = importExportBoxTemplate,
							},
						},
					},
				},
				
				groups_profile = {
					type = "group",
					name = L["UIPANEL_GROUPS"] .. " - " .. L["DOMAIN_PROFILE"],
					desc = L["UIPANEL_GROUPS_DESC"],
					order = 31,
					args = {
						addgroup = addGroupFunctionGroup,
						importexport = importExportBoxTemplate,
						addgroupgroup = {
							type = "group",
							name = L["UIPANEL_ADDGROUP"],
							order = math.huge,
							args = {
								addgroup = addGroupFunctionGroup,
								importexport = importExportBoxTemplate,
							},
						},
					},
				},
			},
		}

---------- Options Table Compilation ----------
function TMW:CompileOptions()

	if TMW:AssertOptionsInitialized() then
		return
	end

	if not TMW.OptionsTableInitialized then


		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(TMW.db)
		
		-- dont copy the entire profiles table because it contains a reference to db
		TMW.OptionsTable.args.profiles.args = CopyTable(TMW.OptionsTable.args.profiles.args)
		
		TMW.OptionsTable.args.profiles.args.importexportdesc = {
			order = 90,
			type = "description",
			name = "\r\n" .. L["IMPORT_EXPORT_DESC_INLINE"],
			--hidden = function() return IE.ExportBox:IsVisible() end,
		}
		TMW.OptionsTable.args.profiles.args.importexport = importExportBoxTemplate


		-- Dynamic Icon View Settings --
		for view in pairs(TMW.Views) do
			TMW.GroupConfigTemplate.args.main.args.View.args[view] = viewSelectToggle
			addGroupFunctionGroup.args[view] = addGroupButton
		end


		-- Talent Tree group options
		local parent = TMW.GroupConfigTemplate.args.main.args
		
		for i = 1, GetNumSpecializations() do
			local _, name = GetSpecializationInfo(i)
			parent["Tree"..i] = {
				type = "toggle",
				name = L["TREEf"]:format(name),
				desc = L["UIPANEL_TREE_DESC"],
				order = 12+i,
				hidden = specializationSettingHidden,
			}
		end
	

		-- Dynamic Color Settings --
		TMW.OptionsTable.args.colors.args.GLOBAL = colorIconTypeTemplate
		for k, Type in pairs(TMW.Types) do
			if not Type.NoColorSettings then
				TMW.OptionsTable.args.colors.args[k] = colorIconTypeTemplate
			end
		end


	
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW IEOptions", TMW.OptionsTable)
		
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW Options", TMW.OptionsTable)
		LibStub("AceConfigDialog-3.0"):SetDefaultSize("TMW Options", 781, 512)


		TMW.OptionsTableInitialize = true
	end


	-- Dynamic Group Settings --
	for _, domain in TMW:Vararg("profile", "global") do
		local args = TMW.OptionsTable.args["groups_"..domain].args

		for k, v in pairs(args) do
			if v == TMW.GroupConfigTemplate then
				args[k] = nil
			end
		end

		for g = 1, TMW.db[domain].NumGroups do
			args["#Group " .. g] = TMW.GroupConfigTemplate
		end
	end
	
	TMW:Fire("TMW_CONFIG_MAIN_OPTIONS_COMPILE", TMW.OptionsTable)

	
	if not TMW.AddedToBlizz then
		-- GLOBALS: INTERFACEOPTIONS_ADDONCATEGORIES, InterfaceAddOnsList_Update
		for k, v in pairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
			if v.name == "TellMeWhen" and not v.obj then
				tremove(INTERFACEOPTIONS_ADDONCATEGORIES, k)
				InterfaceAddOnsList_Update()
				break
			end
		end

		TMW.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TMW Options", "TellMeWhen")
		
		if TMW.AddedToBlizz and not TMW.ALLOW_LOCKDOWN_CONFIG then
			local canShow = true
			
			IE:RegisterEvent("PLAYER_REGEN_DISABLED", function()
				canShow = false
				TMW.AddedToBlizz:Hide()
			end)
			
			IE:RegisterEvent("PLAYER_REGEN_ENABLED", function()
				canShow = true
				if InterfaceOptionsFramePanelContainer.displayedPanel == TMW.AddedToBlizz then
					TMW.AddedToBlizz:Show()
				end
			end)

			TMW.AddedToBlizz:HookScript("OnShow", function(self)
				if not canShow then
					self:Hide()
				end
			end)
		end
	end
end



-- -------------
-- GROUP CONFIG
-- -------------

---------- Add/Delete ----------
function TMW:Group_Delete(group)
	local domain = group.Domain
	local groupID = group.ID

	tremove(TMW.db[domain].Groups, groupID)
	TMW.db[domain].NumGroups = TMW.db[domain].NumGroups - 1


	-- Delay these updates to try and avoid these errors: 
	-- AceConfigDialog-3.0-58.lua:804: attempt to index field "rootframe" (a nil value) 
	TMW:ScheduleTimer(function()
		TMW:Update()

		IE:Load(1)
		IE:NotifyChanges()
	end, 0.1)

	CloseDropDownMenus()
end

function TMW:Group_Add(domain, view)
	local groupID = TMW.db[domain].NumGroups + 1

	TMW.db[domain].NumGroups = groupID

	local gs = TMW.db[domain].Groups[groupID]

	if view then
		gs.View = view
		
		local viewData = TMW.Views[view]
		if viewData then
			viewData:Group_OnCreate(gs)
		end
	end

	TMW:Update()

	local group = TMW[domain][groupID]

	TMW:CompileOptions()
	IE:NotifyChanges("groups_" .. domain, "#Group " .. groupID)

	return group
end

function TMW:Group_Swap(domain, groupID1, groupID2)
	local Groups = TMW.db[domain].Groups
	Groups[groupID1], Groups[groupID2] = Groups[groupID2], Groups[groupID1]
    
    TMW:Update()

	IE:Load(1)
	IE:NotifyChanges()
end


---------- Etc ----------
function TMW:Group_HasIconData(group)
	for ics in group:InIconSettings() do
		if not TMW:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
			return true
		end
	end

	return false
end





-- ----------------------
-- ICON EDITOR
-- ----------------------

IE = TMW:NewModule("IconEditor", "AceEvent-3.0", "AceTimer-3.0") TMW.IE = IE
IE.Tabs = {}

IE.CONST = {
	TAB_OFFS_X = -18,
	IE_HEIGHT_MIN = 400,
	IE_HEIGHT_MAX = 1200,
}

function IE:OnInitialize()
	-- if the file IS required for gross functionality
	if not TMW.Classes then
		-- GLOBALS: StaticPopupDialogs, StaticPopup_Show, EXIT_GAME, CANCEL, ForceQuit
		StaticPopupDialogs["TMWOPT_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE_OPT"], 
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMWOPT_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "path/to/file.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
		return

	-- if the file is NOT required for gross functionality
	elseif not TMW.DOGTAGS then
		StaticPopupDialogs["TMWOPT_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE_OPT_NOREQ"], 
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMWOPT_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "TellMeWhen/Components/Core/Common/DogTags/config.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
	end

	TMW:Fire("TMW_OPTIONS_LOADING")
	TMW:UnregisterAllCallbacks("TMW_OPTIONS_LOADING")

	-- Make TMW.IE be the same as IE.
	-- IE[0] = TellMeWhen_IconEditor[0] (already done in .xml)
	local meta = CopyTable(getmetatable(IE))
	meta.__index = getmetatable(TellMeWhen_IconEditor).__index
	setmetatable(IE, meta)


	hooksecurefunc("PickupSpellBookItem", function(...) IE.DraggingInfo = {...} end)
	WorldFrame:HookScript("OnMouseDown", function()
		IE.DraggingInfo = nil
	end)
	hooksecurefunc("ClearCursor", IE.BAR_HIDEGRID)
	IE:RegisterEvent("PET_BAR_HIDEGRID", "BAR_HIDEGRID")
	IE:RegisterEvent("ACTIONBAR_HIDEGRID", "BAR_HIDEGRID")


	IE:InitializeDatabase()


	IE:HookScript("OnShow", function()
		TMW:RegisterCallback("TMW_ONUPDATE_POST", IE)
	end)
	IE:HookScript("OnHide", function()
		TMW:UnregisterCallback("TMW_ONUPDATE_POST", IE)
	end)
	IE:SetScript("OnUpdate", IE.OnUpdate)
	IE.iconsToUpdate = {}

	TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(event, group)
		if CI.group == group then
			IE:CheckLoadedIconIsValid()
		end
	end)

	IE.history = {}
	IE.historyState = 0

	IE:CreateTabs()
	
	if TMW.Classes.IconEditor_Resizer_ScaleX_SizeY then
		self.resizer = TMW.Classes.IconEditor_Resizer_ScaleX_SizeY:New(self)
		self.resizer:OnEnable()
		self.resizer.resizeButton:SetScale(2)
	end

	IE.Initialized = true

	TMW:Fire("TMW_OPTIONS_LOADED")
	TMW:UnregisterAllCallbacks("TMW_OPTIONS_LOADED")
	IE.OnInitialize = nil
end




---------------------------------
-- Database Management
---------------------------------

IE.Defaults = {
	global = {
		EditorScale		= 0.9,
		EditorHeight	= 600,
		ConfigWarning	= true,
	},
}

IE.UpgradeTable = {}
IE.UpgradeTableByVersions = {}

function IE:RegisterDatabaseDefaults(defaults)
	assert(type(defaults) == "table", "arg1 to RegisterProfileDefaults must be a table")
	
	if IE.InitializedDatabase then
		error("Defaults are being registered too late. They need to be registered before the database is initialized.", 2)
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, IE.Defaults)
end

function IE:GetBaseUpgrades()			-- upgrade functions
	return {
		[62218] = {
			global = function(self)
				IE.db.global.EditorScale = TMW.db.global.EditorScale or 0.9
				TMW.db.global.EditorScale = nil
				
				IE.db.global.EditorHeight = TMW.db.global.EditorHeight or 600
				TMW.db.global.EditorHeight = nil
				
				IE.db.global.ConfigWarning = TMW.db.global.ConfigWarning or true
				TMW.db.global.ConfigWarning = nil
				
			end,
			profile = function(self)
				-- Do Stuff
			end,
		},
	}
end

function IE:RegisterUpgrade(version, data)
	assert(not data.Version, "Upgrade data cannot store a value with key 'Version' because it is a reserved key.")
	
	if IE.HaveUpgradedOnce then
		error("Upgrades are being registered too late. They need to be registered before any upgrades occur.", 2)
	end
	
	local upgradeSet = IE.UpgradeTableByVersions[version]
	if upgradeSet then
		-- An upgrade set already exists for this version, so we need to merge the two.
		for k, v in pairs(data) do
			if upgradeSet[k] ~= nil then
				if type(v) == "function" then
					-- If we already have a function with the same key (E.g. 'icon' or 'group')
					-- then hook the existing function so that both run
					hooksecurefunc(upgradeSet, k, v)
				else
					-- If we already have data with the same key (some kind of helper data for the upgrade)
					-- then raise an error because there will certainly be conflicts.
					error(("A value with key %q already exists for upgrades for version %d. Please choose a different key to store it in to prevent conflicts.")
					:format(k, version), 2)
				end
			else
				-- There was nothing already in place, so just stick it in the upgrade set as-is.
				upgradeSet[k] = v
			end
		end
	else
		-- An upgrade set doesn't exist for this version,
		-- so just use the table that was passed in and process it as a new upgrade set.
		data.Version = version
		IE.UpgradeTableByVersions[version] = data
		tinsert(IE.UpgradeTable, data)
	end
end

function IE:SortUpgradeTable()
	sort(IE.UpgradeTable, TMW.UpgradeTableSorter)
end

function IE:GetUpgradeTable()	
	if IE.GetBaseUpgrades then		
		for version, data in pairs(IE:GetBaseUpgrades()) do
			IE:RegisterUpgrade(version, data)
		end
		
		IE.GetBaseUpgrades = nil
	end
	
	IE:SortUpgradeTable()
	
	return IE.UpgradeTable
end


function IE:DoUpgrade(type, version, ...)
	assert(_G.type(type) == "string")
	assert(_G.type(version) == "number")
	
	-- upgrade the actual requested setting
	for k, v in ipairs(IE:GetUpgradeTable()) do
		if v.Version > version then
			if v[type] then
				v[type](v, ...)
			end
		end
	end
	
	TMW:Fire("TMW_IE_UPGRADE_REQUESTED", type, version, ...)

	-- delegate out to sub-types
	if type == "global" then
	
		-- delegate to locale
		for locale, ls in pairs(IE.db.locale) do
			IE:DoUpgrade("locale", version, ls, locale)
		end
	
		--All Global Upgrades Complete
		TMWOptDB.Version = TELLMEWHEN_VERSIONNUMBER
	elseif type == "profile" then
		
		-- Put any sub-type upgrade delegation here...
		

		
		--All Profile Upgrades Complete
		IE.db.profile.Version = TELLMEWHEN_VERSIONNUMBER
	end
	
	IE.HaveUpgradedOnce = true
end


function IE:RawUpgrade()

	IE.RawUpgrade = nil
	

	-- Begin DB upgrades that need to be done before defaults are added.
	-- Upgrades here should always do everything needed to every single profile,
	-- and remember to check if a table exists before iterating/indexing it.

	if TMWOptDB and TMWOptDB.profiles then
		--[[
		if TMWOptDB.Version < 41402 then
			...

			for _, p in pairs(TMWOptDB.profiles) do
				...
			end
		end
		]]
		
	end
	
	TMW:Fire("TMW_IE_DB_PRE_DEFAULT_UPGRADES")
	TMW:UnregisterAllCallbacks("TMW_IE_DB_PRE_DEFAULT_UPGRADES")
end

function IE:UpgradeGlobal()
	if TMWOptDB.Version < TELLMEWHEN_VERSIONNUMBER then
		IE:DoUpgrade("global", TMWOptDB.Version, IE.db.global)
	end

	-- This function isn't needed anymore
	IE.UpgradeGlobal = nil
end

function IE:UpgradeProfile()
	-- Set the version for the current profile to the current version if it is a new profile.
	IE.db.profile.Version = IE.db.profile.Version or TELLMEWHEN_VERSIONNUMBER
		
	if TMWOptDB.Version < TELLMEWHEN_VERSIONNUMBER then
		IE:DoUpgrade("global", TMWOptDB.Version, IE.db.global)
	end
	
	if IE.db.profile.Version < TELLMEWHEN_VERSIONNUMBER then
		IE:DoUpgrade("profile", IE.db.profile.Version, IE.db.profile)
	end
end


function IE:InitializeDatabase()
	
	IE.InitializeDatabase = nil
	
	IE.InitializedDatabase = true
	
	TMW:Fire("TMW_IE_DB_INITIALIZING")
	TMW:UnregisterAllCallbacks("TMW_IE_DB_INITIALIZING")
	
	--------------- Database ---------------
	local TMWOptDB_alias
	if TMWOptDB and TMWOptDB.Version == nil then
		-- if TMWOptDB.Version is nil then we are upgrading from a version from before
		-- AceDB-3.0 was used for the options settings.

		TMWOptDB_alias = TMWOptDB

		-- Overwrite the old database (we will restore from the alias in a second)
		-- 62216 was the first version to use AceDB-3.0
		_G.TMWOptDB = {Version = 62216}

	elseif type(TMWOptDB) ~= "table" then
		-- TMWOptDB might not exist if this is a fresh install
		-- or if the user is upgrading from a really old version that doesn't use TMWOptDB.
		_G.TMWOptDB = {Version = TELLMEWHEN_VERSIONNUMBER}
	end
	
	
	-- Handle upgrades that need to be done before defaults are added to the database.
	-- Primary purpose of this is to properly upgrade settings if a default has changed.
	IE:RawUpgrade()
	
	-- Initialize the database
	IE.db = AceDB:New("TMWOptDB", IE.Defaults)
	
	if TMWOptDB_alias then
		for k, v in pairs(TMWOptDB_alias) do
			IE.db.global[k] = v
		end
		
		IE.db = AceDB:New("TMWOptDB", IE.Defaults)
	end
	
	IE.db.RegisterCallback(IE, "OnProfileChanged",	"OnProfile")
	IE.db.RegisterCallback(IE, "OnProfileCopied",	"OnProfile")
	IE.db.RegisterCallback(IE, "OnProfileReset",	"OnProfile")
	IE.db.RegisterCallback(IE, "OnNewProfile",		"OnProfile")
	
	-- Handle normal upgrades after the database has been initialized.
	IE:UpgradeGlobal()
	IE:UpgradeProfile()
	
	TMW:Fire("TMW_DB_INITIALIZED")
	TMW:UnregisterAllCallbacks("TMW_DB_INITIALIZED")
end

function IE:OnProfile(event, arg2, arg3)

	if IE.Initialized then
		TMW:CompileOptions() -- redo groups in the options
	end

	-- Reload the icon editor.
	IE:Load(1)
	
	TMW:Fire("TMW_IE_ON_PROFILE", event, arg2, arg3)
end

TMW:RegisterCallback("TMW_ON_PROFILE", function(event, arg2, arg3)
	IE.db:SetProfile(TMW.db:GetCurrentProfile())
end)

 



TMW:NewClass("IconEditorTab", "Button"){
	
	NewTab = function(self, identifier, order, attachedFrame)
		self:AssertSelfIsClass()
		
		TMW:ValidateType("2 (identifier)", "IconEditorTab:NewTab(identifier, order, attachedFrame)", identifier, "string")
		TMW:ValidateType("3 (order)", "IconEditorTab:NewTab(identifier, order, attachedFrame)", order, "number")
		TMW:ValidateType("4 (attachedFrame)", "IconEditorTab:NewTab(identifier, order, attachedFrame)", attachedFrame, "string")
		
		tab = self:New("Button", "TellMeWhen_IconEditorTab" .. #IE.Tabs + 1, TellMeWhen_IconEditor, "CharacterFrameTabButtonTemplate")
		
		tab.doesIcon = 1
		tab.doesGroup = 1
	
		tab.identifier = identifier
		tab.order = order
		tab.attachedFrame = attachedFrame
		
		IE.Tabs[#IE.Tabs + 1] = tab
		tab:SetID(#IE.Tabs)
		
		TellMeWhen_IconEditor.numTabs = #IE.Tabs
		
		TMW:SortOrderedTables(IE.Tabs)
		
		
		for id, tab in pairs(IE.Tabs) do
			if id == 1 then
				tab:SetPoint("BOTTOMLEFT", 0, -30)
			else
				tab:SetPoint("LEFT", IE.Tabs[id - 1], "RIGHT", IE.CONST.TAB_OFFS_X, 0)
			end
		end
		
		PanelTemplates_TabResize(tab, -6)
				
		return tab
	end,
	
	OnClick = function(self)
		if self.doesGroup and not CI.icon then
			self:ClickHandlerBase(IE.NotLoadedMessage)
		else
			IE.NotLoadedMessage:Hide()
			self:ClickHandler()
		end
	end,
	
	ClickHandlerBase = function(self, frame)
		-- invoke blizzard's tab click function to set the apperance of all the tabs
		PanelTemplates_Tab_OnClick(self, self:GetParent())
		PlaySound("igCharacterInfoTab")

		-- hide all tabs' frames, including the current tab so that the OnHide and OnShow scripts fire
		for _, tab in ipairs(IE.Tabs) do
			local frame = tab.attachedFrame
			if TellMeWhen_IconEditor[frame] then
				TellMeWhen_IconEditor[frame]:Hide()
			end
		end
		IE.NotLoadedMessage:Hide()

		local oldTab = IE.CurrentTab
		
		-- state the current tab.
		-- this is used in many other places, including inside some OnShow scripts, so it MUST go before the :Show()s below
		IE.CurrentTab = self

		-- show the selected tab's frame
		if frame then
			frame:Show()
		end
		-- show the icon editor
		IE:Show()
		
		TMW:Fire("TMW_CONFIG_TAB_CLICKED", IE.CurrentTab, oldTab)
	end,
	
	ClickHandler = function(self)
		local frame = TellMeWhen_IconEditor[self.attachedFrame]
		if not frame then
			TMW:Error(("Couldn't find child of TellMeWhen_IconEditor with key %q"):format(self.attachedFrame))
		end

		self:ClickHandlerBase(frame)
	end,
	
	OnShow = function(self)
		PanelTemplates_TabResize(self, -6)
		self:SetFrameLevel(self:GetParent():GetFrameLevel() - 1)
	end,
	OnHide = function(self)
		self:SetWidth(TMW.IE.CONST.TAB_OFFS_X)
	end,
	
	OnSizeChanged = function(self)
		PanelTemplates_TabResize(self, -6)
	end,
	
	SetTitleComponents = function(self, doesIcon, doesGroup)
		self.doesIcon = doesIcon
		self.doesGroup = doesGroup
	end,
	
	METHOD_EXTENSIONS = {
		SetText = function(self, text)
			PanelTemplates_TabResize(self, -6)
		end,
	}
}

function IE:CreateTabs()
	IE.MainTab = TMW.Classes.IconEditorTab:NewTab("MAIN", 1, "Main")
	IE.MainTab:SetText(TMW.L["MAIN"])
	TMW:TT(IE.MainTab, "MAIN", "MAIN_DESC")
	
	
	IE.MainOptionsTab = TMW.Classes.IconEditorTab:NewTab("GROUPOPTS", 20, "MainOptions")
	IE.MainOptionsTab:SetTitleComponents()
	IE.MainOptionsTab:SetText(TMW.L["GROUPADDONSETTINGS"])
	TMW:TT(IE.MainOptionsTab, "GROUPADDONSETTINGS", "GROUPADDONSETTINGS_DESC")
	
	IE.MainOptionsTab:ExtendMethod("ClickHandler", function()
		TMW:CompileOptions()

		if CI.group then
			LibStub("AceConfigDialog-3.0"):Open("TMW IEOptions", TMW.IE.MainOptionsWidget)
			LibStub("AceConfigDialog-3.0"):SelectGroup("TMW IEOptions", "groups_" .. TMW.CI.group.Domain, "#Group " .. TMW.CI.group.ID)
			LibStub("AceConfigRegistry-3.0"):NotifyChange("TMW IEOptions")
		end

		LibStub("AceConfigDialog-3.0"):Open("TMW IEOptions", TMW.IE.MainOptionsWidget)
	end)		
end

function IE:OnUpdate()
	local icon = CI.icon

	-- update the top of the icon editor with the information of the current icon.
	-- this is done in an OnUpdate because it is just too hard to track when the texture changes sometimes.
	-- I don't want to fill up the main addon with configuration code to notify the IE of texture changes
	local titlePrepend = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL
	
	local tab = IE.CurrentTab

	if icon and tab.doesGroup and tab.doesIcon then
		-- For IconEditor tabs that can configure icons

		local groupName = icon.group:GetGroupName(1)
		local name = L["GROUPICON"]:format(groupName, icon.ID)
		if icon.group.Domain == "global" then
			name = L["DOMAIN_GLOBAL"] .. " " .. name
		end
		
		self.Header:SetText(titlePrepend .. " - " .. name)

		self.Header:SetFontObject(GameFontNormal)

		if self.Header:IsTruncated() then
			self.Header:SetFontObject(GameFontNormalSmall)
			local truncAmt = 3
			while self.Header:IsTruncated() and truncAmt < #groupName + 4 do


				local name = L["GROUPICON"]:format(groupName:sub(1, -truncAmt - 4) .. "..." .. groupName:sub(-4), icon.ID)
				if icon.group.Domain == "global" then
					name = L["DOMAIN_GLOBAL"] .. " " .. name
				end

				self.Header:SetText(titlePrepend .. " - " .. name)
				truncAmt = truncAmt + 1
			end
		end

		if icon then
			self.icontexture:SetTexture(icon.attributes.texture)
		end
		self.BackButton:Show()
		self.ForwardsButton:Show()

		self.Header:SetPoint("LEFT", self.ForwardsButton, "RIGHT", 4, 0)
	else
		-- For IconEditor tabs that can't configure icons (tabs handled here might not configure groups either)
		self.icontexture:SetTexture(nil)
		self.BackButton:Hide()
		self.ForwardsButton:Hide()

		-- Setting this relative to icontexture makes it roughly centered
		-- (it gets offset to the left by the exit button)
		self.Header:SetPoint("LEFT", self.icontexture, "RIGHT", 4, 0)
		
		if CI.group and tab.doesGroup then
			-- for group config tabs, don't show icon info. Just show group info.
			local name = L["fGROUP"]:format(CI.group:GetGroupName(1))
			if icon.group.Domain == "global" then
				name = L["DOMAIN_GLOBAL"] .. " " .. name
			end
			self.Header:SetText(titlePrepend .. " - " .. name)
		else
			self.Header:SetText(titlePrepend)
		end
	end
	
	
	if IE.isMoving then
		local cursorCurrentX, cursorCurrentY = GetCursorPosition()
		local deltaX, deltaY = IE.cursorStartX - cursorCurrentX, IE.cursorStartY - cursorCurrentY
		
		local scale = IE:GetEffectiveScale()
		deltaX, deltaY = deltaX/scale, deltaY/scale
		
		local a, b, c = IE:GetPoint()
		IE:ClearAllPoints()
		IE:SetPoint(a, b, c, IE.startX - deltaX, IE.startY - deltaY)
	end
end

function IE:BAR_HIDEGRID()
	IE.DraggingInfo = nil
end

function IE:TMW_ONUPDATE_POST(...)
	-- run updates for any icons that are queued
	for i, icon in ipairs(IE.iconsToUpdate) do
		TMW.safecall(icon.Setup, icon)
	end
	wipe(IE.iconsToUpdate)

	-- check and see if the settings of the current icon have changed.
	-- if they have, create a history point (or at least try to)
	-- IMPORTANT: do this after running icon updates <because of an old antiquated reason which no longer applies, but if it ain't broke, don't fix it>
	IE:AttemptBackup(TMW.CI.icon)
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- GLOBALS: TellMeWhen_ConfigWarning
	if not TMW.Locked then
		if TMW.db.global.ConfigWarning then
			TellMeWhen_ConfigWarning:Show()
		else
			TellMeWhen_ConfigWarning:Hide()
		end
	else
		TellMeWhen_ConfigWarning:Hide()
	end

	IE:SaveSettings()
end)

TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function()
	-- GLOBALS: TellMeWhen_NoGroupsWarning
	if not TMW.Locked then
		for group in TMW:InGroups() do
			if group:IsVisible() then
				TellMeWhen_NoGroupsWarning:Hide()
				return
			end
		end

		TellMeWhen_NoGroupsWarning:Show()
	else
		TellMeWhen_NoGroupsWarning:Hide()
	end
end)

IE:RegisterEvent("PLAYER_REGEN_DISABLED", function()
	if not TMW.ALLOW_LOCKDOWN_CONFIG then
		IE:Hide()
		LibStub("AceConfigDialog-3.0"):Close("TMW Options")
	end
end)

TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if Locked and not CI.icon then
		IE:Hide()
	end
end)

function IE:StartMoving()
	IE.startX, IE.startY = select(4, IE:GetPoint())
	IE.cursorStartX, IE.cursorStartY = GetCursorPosition()
	IE.isMoving = true
end

function IE:StopMovingOrSizing()
	IE.isMoving = false
end


---------- Interface ----------
IE.AllDisplayPanels = {}
local panelList = {}

function IE:PositionPanels()
	for _, frame in pairs(IE.AllDisplayPanels) do
		frame:Hide()
	end
	
	if not CI.icon then
		return
	end

	wipe(panelList)
	for _, Component in pairs(CI.icon.Components) do
		if Component:ShouldShowConfigPanels(CI.icon) then
			for _, panelInfo in pairs(Component.ConfigPanels) do
				tinsert(panelList, panelInfo)
			end		
		end
	end
	
	TMW:SortOrderedTables(panelList)
	
	local ParentLeft, ParentRight = TellMeWhen_IconEditorMainPanelsLeft, TellMeWhen_IconEditorMainPanelsRight
	for i = 1, #ParentLeft do
		ParentLeft[i] = nil
	end
	for i = 1, #ParentRight do
		ParentRight[i] = nil
	end
	
	for i, panelInfo in ipairs(panelList) do
		local GenericComponent = panelInfo.component
		
		local parent
		if GenericComponent.className == "IconType" then 
			parent = ParentLeft
		else
			parent = ParentRight
		end
		
		local frame
		-- Get the frame for the panel if it already exists, or create it if it doesn't.
		if panelInfo.panelType == "XMLTemplate" then
			frame = IE.AllDisplayPanels[panelInfo.xmlTemplateName]
			
			if not frame then
				local _
				_, frame = TMW.safecall(CreateFrame, "Frame", panelInfo.xmlTemplateName, parent, panelInfo.xmlTemplateName)
				--frame:SetScale(0.9)
				IE.AllDisplayPanels[panelInfo.xmlTemplateName] = frame
			end
		elseif panelInfo.panelType == "ConstructorFunc" then
			frame = IE.AllDisplayPanels[panelInfo] 
			
			if not frame then
				frame = CreateFrame("Frame", panelInfo.frameName, parent, "TellMeWhen_OptionsModuleContainer")
				--frame:SetScale(0.9)
				IE.AllDisplayPanels[panelInfo] = frame
				TMW.safecall(panelInfo.func, frame)
			end
		end
		
		if frame then
			if type(parent[#parent]) == "table" then
				frame:SetPoint("TOP", parent[#parent], "BOTTOM", 0, -11)
			else
				frame:SetPoint("TOP", 0, -10)
			end
			parent[#parent + 1] = frame
			
			local hue = 1/1.5
			
			frame.Background:SetTexture(hue, hue, hue) -- HUEHUEHUE
			frame.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0.10)
			
			frame:Show()
			
			TMW:Fire("TMW_CONFIG_PANEL_SETUP", frame, panelInfo)
		end	
	end	
	
	local IE_FL = IE:GetFrameLevel()
	for i = 1, #ParentLeft do
		ParentLeft[i]:SetFrameLevel(IE_FL + 3) --(#ParentLeft-i+1)*3)
	end
	for i = 1, #ParentRight do
		ParentRight[i]:SetFrameLevel(IE_FL + 3) --(#ParentRight-i+1)*3)
	end
end

function IE:DistributeFrameAnchorsLaterally(parent, numPerRow, ...)
	local numChildFrames = select("#", ...)
	
	local parentWidth = parent:GetWidth()
	local paddingPerSide = 5 -- constant
	local parentWidth_padded = parentWidth - paddingPerSide*2
	
	local widthPerFrame = parentWidth_padded/numPerRow
	
	local lastChild
	for i = 1, numChildFrames do
		local child = select(i, ...)
		
		local yOffset = 0
		for i = 1, child:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = child:GetPoint(i)
			if point == "LEFT" then
				yOffset = y or 0
				break
			end
		end
		
		if lastChild then
			child:SetPoint("LEFT", lastChild, "RIGHT", widthPerFrame - lastChild:GetWidth(), yOffset)
		else
			child:SetPoint("LEFT", paddingPerSide, yOffset)
		end
		lastChild = child
	end
end

function IE:Load(isRefresh, icon, isHistoryChange)
	TMW:CompileOptions()

	if icon ~= nil then
		local ic_old = CI.icon

		if type(icon) == "table" then
			PlaySound("igCharacterInfoTab")
			IE:SaveSettings()
			
			CI.icon = icon

			if IE.history[#IE.history] ~= icon and not isHistoryChange then
				-- if we are using an old history point (i.e. we hit back a few times and then loaded a new icon),
				-- delete all history points from the current one forward so that we dont jump around wildly when backing and forwarding
				for i = IE.historyState + 1, #IE.history do
					IE.history[i] = nil
				end

				IE.history[#IE.history + 1] = icon

				-- set the history state to the latest point
				IE.historyState = #IE.history
				-- notify the back and forwards buttons that there was a change so they can :Enable() or :Disable()
				IE:BackFowardsChanged()
			end
			
			if ic_old ~= CI.icon then
				IE.Main.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
				IE.Main.PanelsRight.ScrollFrame:SetVerticalScroll(0)
			end


		elseif icon == false then
			CI.icon = nil
		end

		if IE.CurrentTab then
			IE.CurrentTab:OnClick()
		else
			IE.MainTab:OnClick()
		end

		TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", CI.icon, ic_old)
	end

	if not IE:IsShown() then
		if isRefresh then
			return
		else
			IE:Show()
		end
	end
	
	if 0 > IE:GetBottom() then
		IE.db.global.EditorScale = IE.Defaults.global.EditorScale
		IE.db.global.EditorHeight = IE.Defaults.global.EditorHeight
	end
	
	IE:SetScale(IE.db.global.EditorScale)
	IE:SetHeight(IE.db.global.EditorHeight)

	
	if CI.icon then
		-- This is really really important. The icon must be setup so that it has the correct components implemented
		-- so that the correct config panels will be loaded and shown for the icon.
		CI.icon:Setup()

		IE:PositionPanels()
		
		if CI.ics.Type == "" then
			UIDropDownMenu_SetText(IE.Main.Type, L["ICONMENU_TYPE"])
		else
			local Type = rawget(TMW.Types, CI.ics.Type)
			if Type then
				UIDropDownMenu_SetText(IE.Main.Type, Type.name)
			else
				UIDropDownMenu_SetText(IE.Main.Type, CI.ics.Type .. ": UNKNOWN TYPE")
			end
		end

		IE.ResetButton:Enable()

		IE:ScheduleIconSetup()

		-- It is intended that this happens at the end instead of the beginning.
		-- Table accesses that trigger metamethods flesh out an icon's settings with new things that aren't there pre-load (usually)
		if icon then
			IE:AttemptBackup(CI.icon)
		end

		TMW:Fire("TMW_CONFIG_ICON_LOADED", CI.icon)
	else
		IE.ResetButton:Disable()
	end
	
	IE:UndoRedoChanged()

	TMW:Fire("TMW_CONFIG_LOADED")
end

function IE:CheckLoadedIconIsValid()
	if not TMW.IE:IsShown() then
		return
	end

	if not CI.icon then
		return
	elseif
		not CI.group:IsValid()
		or not CI.icon:IsInRange()
	then
		TMW.IE:Load(nil, false)
	end
end

function IE:NotifyChanges(...)
	-- this is used to select the same group in all open TMW configuration windows
	-- the path (...) is a list of keys in TMW.OptionsTable that leads to the desired group

	local hasPath = ...

	-- Notify standalone options panels of a change (Blizzard, slash command, LDB)
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TMW Options")
	if hasPath then
		LibStub("AceConfigDialog-3.0"):SelectGroup("TMW Options", tostringall(...))
	end

	-- Notify the group settings tab in the icon editor of any changes
	-- the order here is very specific and breaks if you change it. (:Open(), :SelectGroup(), :NotifyChange())
	if IE.MainOptionsWidget and IE.MainOptions:IsShown() then
		LibStub("AceConfigDialog-3.0"):Open("TMW IEOptions", IE.MainOptionsWidget)
		if hasPath then
			LibStub("AceConfigDialog-3.0"):SelectGroup("TMW IEOptions", tostringall(...))
		end
		LibStub("AceConfigRegistry-3.0"):NotifyChange("TMW IEOptions")
	end
end

function IE:Reset()	
	IE:SaveSettings() -- this is here just to clear the focus of editboxes, not to actually save things
	
	CI.icon:DisableIcon()
	
	TMW.CI.gs.Icons[CI.icon.ID] = nil
	
	TMW:Fire("TMW_ICON_SETTINGS_RESET", CI.icon)
	
	CI.icon:Setup()
	
	IE:Load(1)
	
	IE.MainTab:Click()
end


---------- Spell/Item Dragging ----------
function IE:SpellItemToIcon(icon, func, arg1)
	if not icon.IsIcon then
		return
	end

	local t, data, subType, param4
	local input
	if not (CursorHasSpell() or CursorHasItem()) and IE.DraggingInfo then
		t = "spell"
		data, subType = unpack(IE.DraggingInfo)
	else
		t, data, subType, param4 = GetCursorInfo()
	end
	IE.DraggingInfo = nil

	if not t then
		return
	end

	IE:SaveSettings()

	-- create a backup before doing things
	IE:AttemptBackup(icon)

	-- handle the drag based on icon type
	local success
	if func then
		success = func(arg1, icon, t, data, subType, param4)
	else
		success = icon.typeData:DragReceived(icon, t, data, subType, param4)
	end
	if not success then
		return
	end

	ClearCursor()
	icon:Setup()
	IE:Load(1)
end


---------- Settings ----------

TMW:NewClass("SettingFrameBase"){
	IsEnabled = true,
	
	CheckDisabled = function(self)
		if get(self.data.disabled, self) then
			self:Disable()
		else
			self:Enable()
		end
	end,
	
	CheckHidden = function(self)
		if get(self.data.hidden, self) then
			self:Hide()
		else
			self:Show()
		end
	end,
	
	CheckInteractionStates = function(self)
		self:CheckDisabled()
		self:CheckHidden()
	end,
	
	OnEnable = function(self)
		self:SetAlpha(1)
		
		if self.data.disabledtooltip then
			self:SetTooltip(self.data.title, self.data.tooltip)
		end
	end,
	
	OnDisable = function(self)
		self:SetAlpha(0.2)
		
		if self.data.disabledtooltip then
			self:SetTooltip(self.data.title, self.data.disabledtooltip)
		end
	end,
	
	SetTooltip = function(self, title, text)
		TMW:TT(self, title, text, 1, 1, "IsEnabled")
	end,
	
	ConstrainLabel = function(self, anchorTo, anchorPoint, ...)
		assert(self.text, "frame does not have a self.text object to constrain.")

		self.text:SetPoint("RIGHT", anchorTo, anchorPoint or "LEFT", ...)
		
		-- Have to do this or else the text won't multiline/wordwrap when it should.
		-- 30 is just an arbitrarily large number.
		self.text:SetHeight(30)
		self.text:SetMaxLines(3)
	end,
	
	OnCreate_SettingFrameBase = function(self)
		self:SetTooltip(self.data.title, self.data.tooltip)
	end,
}
TMW:NewClass("SettingCheckButton", "CheckButton", "SettingFrameBase"){
	OnClick = function(self, button)
		if CI.ics and self.setting then
			local checked = not not self:GetChecked()
			
			if self.data.value == nil then
				CI.ics[self.setting] = checked
			else --if checked then
				CI.ics[self.setting] = self.data.value
				self:SetChecked(true)
			end
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnClick, self, button) 

		self:OnState()
	end,
	OnCreate = function(self)
		self.text:SetText(get(self.data.label or self.data.title))
		self:SetMotionScriptsWhileDisabled(true)
	end,

	OnState = function(self)
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnState, self) 
	end,
	
	ConstrainLabel = function(self, anchorTo, anchorPoint, ...)
		self.text:SetPoint("RIGHT", anchorTo, anchorPoint or "LEFT", ...)
		
		-- Have to do this or else the text won't multiline/wordwrap when it should.
		-- 30 is just an arbitrarily large number.
		self.text:SetHeight(30)
		self.text:SetMaxLines(3)
	end,
	
	ReloadSetting = function(self)
		local icon = CI.icon
		
		if icon then
			if self.data.value ~= nil then
				self:SetChecked(icon:GetSettings()[self.setting] == self.data.value)
			else
				self:SetChecked(icon:GetSettings()[self.setting])
			end
			self:CheckInteractionStates()
			self:OnState()
		end
	end,
}
TMW:NewClass("SettingSlider", "Slider", "SettingFrameBase"){
	-- This class may be incomplete for any implementations you might need.
	-- Inherit from it and finish/override any methods that you need to.
	
	OnValueChanged = function(self)
		if TMW:Do504SliderBugFix(self) then return end
		value = self:GetValue()

		if CI.ics and self.setting then
		
			value = get(self.data.ModifySettingValue, self, value) or value
			
			CI.ics[self.setting] = value
			
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnValueChanged, self) 
	end,
	OnCreate = function(self)
		self:SetMinMaxValues(self.data.min, self.data.max)
		self:SetValueStep(self.data.step or 1)
		
		self.text:SetText(self.data.label or self.data.title)
		
		self:EnableMouseWheel(true)
	end,
	
	ReloadSetting = function(self)
		local icon = CI.icon
		
		if icon then
			self:SetValue(icon:GetSettings()[self.setting])
			
			self:CheckInteractionStates()
		end
	end,
	
	OnMouseWheel = function(self, delta)
		if self:IsEnabled() then
			self:SetValue(self:GetValue() + delta)
		end
	end,
}

TMW:NewClass("SettingSlider_Alpha", "SettingSlider"){
	METHOD_EXTENSIONS = {
		OnEnable = function(self)
			local icon = CI.icon
			
			if icon then
				self:SetValue(icon:GetSettings()[self.setting]*100)
		
				self:UpdateValueText()
			end
		end,
		OnDisable = function(self)
			self:FakeSetValue(0)
		end,
	},
	
	FakeSetValue = function(self, value)
		self.fakeNextSetValue = 1
		self:SetValue(value)
		self.fakeNextSetValue = nil
		
		self:UpdateValueText()
	end,
	
	OnCreate = function(self)
		self:SetMinMaxValues(0, 100)
		self:SetValueStep(1)
		
		self.text:SetText(self.data.label or self.data.title)
		
		self:EnableMouseWheel(true)
	end,
	
	OnMinMaxChanged = function(self)
		local minValue, maxValue = self:GetMinMaxValues()
		
		self.Low:SetText(minValue .. "%")
		self.High:SetText(maxValue .. "%")
		
		local color = 34/0xFF
		self.Low:SetTextColor(color, color, color, 1)
		self.High:SetTextColor(color, color, color, 1)
		
		self:UpdateValueText()
	end,
	
	UpdateValueText = function(self)
		local value = self:GetValue()
		
		if type(value) ~= "number" then
			return
		end
		
		if self:IsEnabled() then
			if value/100 == self.data.setOrangeAtValue then
				self.Mid:SetText("|cffff7400" .. value .. "%")
			else
				self.Mid:SetText(value .. "%")
			end
		else
			self.Mid:SetText(value .. "%")
		end
	end,
	
	OnValueChanged = function(self, value)
		if TMW:Do504SliderBugFix(self) then return end
		value = self:GetValue()

		local icon = CI.icon
		
		if icon and not self.fakeNextSetValue then
			CI.ics[self.setting] = value / 100
			IE:ScheduleIconSetup()
		end
		
		self:UpdateValueText()
	end,
	
	ReloadSetting = function(self)
		local icon = CI.icon
		
		if icon then
			self:SetValue(icon:GetSettings()[self.setting]*100)
		
			self:UpdateValueText()			
			self:CheckInteractionStates()
		end
	end,
}



TMW:NewClass("BitflagSettingFrameBase"){
	OnClick = function(self, button)		
		if CI.ics and self.setting then
			CI.ics[self.setting] = bit.bxor(CI.ics[self.setting], self.bit)
			
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnClick, self, button) 
	end,
	
	OnCreate_BitflagSettingFrameBase = function(self)
		if self.data.bit then
			self.bit = self.data.bit
		else
			local bitID = self.data.value or self:GetID()
			assert(bitID, "Couldn't figure out what bit frame " .. self:GetName() .. " is supposed to operate on!")
			
			self.bit = bit.lshift(1, (self.data.value or self:GetID()) - 1)
		end
	end,
	
	ReloadSetting = function(self)
		local icon = CI.icon
		if icon then
			self:SetChecked(bit.band(icon:GetSettings()[self.setting], self.bit) == self.bit)
		end
		
		self:CheckInteractionStates()
	end,
}

TMW:NewClass("SettingTotemButton", "BitflagSettingFrameBase", "SettingCheckButton"){
	OnCreate = TMW.Classes.SettingCheckButton.OnCreate,
}

TMW:NewClass("SettingRuneButton", "Button", "SettingFrameBase", "BitflagSettingFrameBase"){
	GetChecked = function(self)
		return self.checked
	end,
	SetChecked = function(self, checked)
		self.checked = checked
		if checked then
			self.Check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
		else
			self.Check:SetTexture(nil)
		end
	end,
	OnCreate = function(self)
		-- detect what texture should be used
		local runeName = gsub(self:GetName(), self:GetParent():GetName(), "")
		local runeType, death = runeName:match("(.*)%d(.*)")
		
		if death and death ~= "" then
			self.texture:SetTexture("Interface\\AddOns\\TellMeWhen\\Textures\\" .. runeType)
		else
			self.texture:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-" .. runeType)
		end
		
	end,
}

TMW:NewClass("SettingEditBox", "EditBox", "SettingFrameBase"){
	METHOD_EXTENSIONS = {
		OnEnable = function(self)
			self:EnableMouse(true)
			self:EnableKeyboard(true)
		end,
		OnDisable = function(self)
			self:ClearFocus()
			self:EnableMouse(false)
			self:EnableKeyboard(false)
		end,
	},
	
	OnCreate_EditboxBase = function(self)
		TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self, "ClearFocus")
	end,
	
	OnEditFocusLost = function(self, button)
		if CI.ics and self.setting then
			local value
			if self.data.doCleanString then
				value = TMW:CleanString(self)
			else
				value = self:GetText()
			end
			
			value = get(self.data.ModifySettingValue, self, value) or value
			
			CI.ics[self.setting] = value
		
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnEditFocusLost, self, button) 
	end,
	OnTextChanged = function(self, button)		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnTextChanged, self, button) 
	end,
	
	ReloadSetting = function(self, eventMaybe)
		local icon = CI.icon
		if icon then
			if not (eventMaybe == "TMW_CONFIG_ICON_HISTORY_STATE_CREATED" and self:HasFocus()) and self.setting then
				self:SetText(icon:GetSettings()[self.setting])
			end
			self:CheckInteractionStates()
			self:ClearFocus()
		end
	end,
}

TMW:NewClass("SettingWhenCheckSet", "Frame", "SettingFrameBase"){
	OnCreate = function(self)
		assert(self.Alpha and self.Check, "Couldn't find the children that are supposed to exist. Are you sure that the frame you are making into a SettingWhenCheckSet inherits from TellMeWhen_WhenCheckSet?")
		
		local data = self.data
		
		-- ShowWhen toggle
		assert(data.bit, "SettingWhenCheckSet's data table must declare a bit flag to be toggled in ics.ShowWhen! (data.bit)")
		
		IE:CreateSettingFrameFromData(self.Check, "SettingTotemButton", {
			setting = "ShowWhen",
			bit = data.bit,
		})
		
		
		-- Alpha slider
		assert(data.alphaSettingName, "SettingWhenCheckSet's data table must declare an alpha setting to be used! (data.alphaSettingName)")
		
		IE:CreateSettingFrameFromData(self.Alpha, "SettingSlider_Alpha", {
			setting = data.alphaSettingName,
			setOrangeAtValue = data.setOrangeAtValue or 0,
			disabled = function(self)
				local ics = TMW.CI.ics
				if ics then
					return bit.band(ics.ShowWhen, data.bit) == 0
				end
			end,
		})
		
		-- Reparent the label text on the slider so that it will be at full opacity even while disabled.
		self.Alpha.text:SetParent(self)

		local parent = self:GetParent()
		TMW:RegisterCallback("TMW_CONFIG_PANEL_SETUP", function(event, frame, panelInfo)
			if frame == parent then
				local supplementalData = panelInfo.supplementalData
				
				assert(supplementalData, "Supplemental data (arg5 to RegisterConfigPanel_XMLTemplate) must be provided for TellMeWhen_WhenChecks!")
				
				-- Set the title for the frame
				parent.Header:SetText(supplementalData.text)
				
				-- Numeric keys in supplementalData point to the tables that have the data for that specified bit toggle
				local supplementalDataForBit = supplementalData[data.bit]
				if supplementalDataForBit then
					self.Check:SetTooltip(
						L["ICONMENU_SHOWWHEN_SHOWWHEN_WRAP"]:format(supplementalDataForBit.text),
						supplementalDataForBit.tooltipText or L["ICONMENU_SHOWWHEN_SHOW_GENERIC_DESC"]
					)
					
					self.Alpha.text:SetText(supplementalDataForBit.text)
					self.Alpha:SetTooltip(
						L["ICONMENU_SHOWWHEN_OPACITYWHEN_WRAP"]:format(supplementalDataForBit.text),
						supplementalDataForBit.tooltipText or L["ICONMENU_SHOWWHEN_OPACITY_GENERIC_DESC"]
					)
				end
			end
		end)
	end,
	
	IsEnabled = function(self)
		return self.Enabled
	end,
	SetEnabled = function(self, enabled)		
		if self.Enabled ~= enabled then
			self.Enabled = enabled
			if enabled then
				self:OnEnable()
			else
				self:OnDisable()
			end
		end
	end,
	Enable = function(self)
		self:SetEnabled(true)
	end,
	Disable = function(self)
		self:SetEnabled(false)
	end,
	
	OnEnable = function(self)
		self.Check:CheckInteractionStates()
		self.Alpha:CheckInteractionStates()
	end,
	
	OnDisable = function(self)
		self.Check:Disable()
		self.Alpha:Disable()
	end,
	
	ReloadSetting = function(self)
		-- Bad Things happen if this isn't defined
	end,
	
	OnCreate_SettingFrameBase = function() end, -- this is the default function that sets the toltip on the frame. We don't want a tooltip on the whole thing.
}


function IE:CreateSettingFrameFromData(frame, arg2, arg3)
	local objectType = frame:GetObjectType()
	
	local className, data
	if arg3 ~= nil then
		data = arg3
		className = arg2
	else
		data = arg2
		className = "Setting" .. objectType
	end
	
	local class = TMW.Classes[className]
	
	assert(class, "Couldn't find class named " .. className .. " to use for " .. objectType .. (frame:GetName() or "<unnamed>") .. ".")
	assert(type(className) == "string", "Usage: IE:CreateSettingFrameFromData(frame, [, className], data)")
	assert(type(data) == "table", "Usage: IE:CreateSettingFrameFromData(frame, [, className], data)")
	
	-- Embed the class into the frame.
	class:Embed(frame, true)
	
	-- Setup callbacks that will load the settings when needed.
	TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", frame, "ReloadSetting")
	TMW:RegisterCallback("TMW_CONFIG_ICON_HISTORY_STATE_CREATED", frame, "ReloadSetting")
	TMW:RegisterCallback("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", frame, "ReloadSetting")

	-- set appearance and settings
	frame.data = data
	frame.setting = data.setting
	frame:Show()
	
	frame:CallFunc("OnCreate")
end

function IE:BuildSimpleCheckSettingFrame(parent, arg2, arg3)
	local className, allData, objectType
	if arg3 ~= nil then
		allData = arg3
		className = arg2
	else
		allData = arg2
		className = "SettingCheckButton"
	end
	local class = TMW.Classes[className]
	local objectType = class.isFrameObject
	
	assert(class, "Couldn't find class named " .. className .. ".")
	assert(type(objectType) == "string", "Couldn't find a WoW frame object type for class named " .. className .. ".")
	assert(type(className) == "string", "Usage: IE:BuildSimpleCheckSettingFrame(parent, [, className], allData)")
	assert(type(allData) == "table", "Usage: IE:BuildSimpleCheckSettingFrame(parent, [, className], allData)")
	
	
	local lastCheckButton
	local numFrames = 0
	local numPerRow = allData.numPerRow or min(#allData, 2)
	for i, data in ipairs(allData) do
		if data ~= nil and data ~= false then -- skip over nils/false (dont freak out about them, they are probably intentional)
		
			assert(type(data) == "table", "All values in allData must be tables!")
			
			local setting = data.setting -- the setting that the check will handle
			-- the setting is used by the current icon type, and doesnt have an override that is "hiding" the check, so procede to set it up
			
			-- An human-friendly-ish unique (hopefully) identifier for the frame
			local identifier = setting .. (data.value ~= nil and tostring(data.value) or "")
			
			local f = parent[identifier]
			if not f then
				f = CreateFrame(objectType, parent:GetName() .. identifier, parent, "TellMeWhen_CheckTemplate")
				parent[identifier] = f
				parent[i] = f
				IE:CreateSettingFrameFromData(f, className, data)
			end
			
			if lastCheckButton then
				-- Anchor it to the previous check if it isn't the first one.
				if numFrames%numPerRow == 0 then
					f:SetPoint("TOP", parent[i-numPerRow], "BOTTOM", 0, 2)
				else
					-- This will get overwritten soon.
					--f:SetPoint("LEFT", "RIGHT", 5, 0)
				end
			else
				-- Anchor the first check to the parent. The left anchor will be handled by DistributeFrameAnchorsLaterally.
				f:SetPoint("TOP", 0, -1)
			end
			lastCheckButton = f
			
			f.row = ceil(i/numPerRow)
			
			numFrames = numFrames + 1
		end
	end
	
	-- Set the bounds of the label text on all the checkboxes to prevent overlapping.
	for i = 1, #parent do
		local f0 = parent[i]
		local f1 = parent[i+1]
		
		if not f1 or f1.row ~= f0.row then
			f0:ConstrainLabel(parent, "RIGHT", -1, 0)
		else
			f0:ConstrainLabel(f1)
		end
	end
	
	TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function()
		for i = 1, #parent, numPerRow do
			IE:DistributeFrameAnchorsLaterally(parent, numPerRow, unpack(parent, i))
		end		
	end)
	
	parent:SetHeight(ceil(numFrames/numPerRow)*30)
	
	return parent
end

function IE:SaveSettings()	
	TMW:Fire("TMW_CONFIG_SAVE_SETTINGS")
end


---------- Equivalancies ----------
local equivTipCache = {}
function IE:Equiv_GenerateTips(equiv)
	local tbl = TMW:SplitNames(TMW.EquivFullIDLookup[equiv])

	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		if not name then
			if TMW.debug then
				TMW:Error("INVALID ID FOUND: %s:%s", equiv, v)
				name = "INVALID " .. v
			else
				name = v
			end
			texture = "Interface\\Icons\\INV_Misc_QuestionMark"
		end

		tiptemp[name] = tiptemp[name] or "|T" .. texture .. ":0|t" .. name
	end

	local r = ""
	for name, line in TMW:OrderedPairs(tiptemp) do
		r = r .. line .. "\r\n"
	end

	r = strtrim(r, "\r\n ;")
	wipe(tiptemp)
	return r
end
TMW:MakeSingleArgFunctionCached(IE, "Equiv_GenerateTips")


---------- Dropdowns ----------
function IE:Type_DropDown()
	for _, Type in ipairs(TMW.OrderedTypes) do -- order in the order in which they are loaded in the .toc file
		if CI.ics.Type == Type.type or not get(Type.hidden) then
			if Type.spacebefore then
				TMW.AddDropdownSpacer()
			end

			local info = UIDropDownMenu_CreateInfo()
			
			info.text = get(Type.name)
			info.value = Type.type
			
			local desc = get(Type.desc)
			if desc then
				info.tooltipTitle = Type.tooltipTitle or info.text
				info.tooltipText = desc
				info.tooltipOnButton = true
			end
			
			info.checked = (info.value == CI.ics.Type)
			info.func = IE.Type_Dropdown_OnClick
			info.arg1 = Type
			
			info.disabled = tempshow
			info.tooltipWhileDisabled = true
			
			info.icon = get(Type.menuIcon)
			info.tCoordLeft = 0.07
			info.tCoordRight = 0.93
			info.tCoordTop = 0.07
			info.tCoordBottom = 0.93
				
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			if Type.spaceafter then
				TMW.AddDropdownSpacer()
			end
		end
	end
end

function IE:Type_Dropdown_OnClick()
	-- Automatically enable the icon when the user chooses an icon type
	-- when the icon was of the default (unconfigured) type.
	if CI.ics.Type == "" then
		CI.ics.Enabled = true
	end

	CI.ics.Type = self.value
	CI.icon:SetInfo("texture", nil)

	CI.ics.Type = self.value
	
	CI.icon:Setup()
	
	IE:Load(1)
end


---------- Tooltips ----------
--local cachednames = {}
function IE:GetRealNames(Name, icon)
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(Name)
	
	local CI_typeData = Types[CI.ics.Type]
	local SoI = CI_typeData.checksItems and "item" or "spell"
	
	-- Note 11/12/12 (WoW 5.0.4) - caching causes incorrect results with "replacement spells" after switching specs like the corruption/immolate pair 
	--if cachednames[CI.ics.Type .. SoI .. text] then return cachednames[CI.ics.Type .. SoI .. text] end

	local tbl
	if SoI == "item" then
		tbl = TMW:GetItems(text)
	else
		tbl = TMW:GetSpellNames(text, 1)
	end
	local durations = CI_typeData.DurationSyntax and TMW:GetSpellDurations(text)

	local str = ""
	local numadded = 0
	local numlines = 50
	local numperline = ceil(#tbl/numlines)

	local Cache = TMW:GetModule("SpellCache"):GetCache()
	
	for k, v in pairs(tbl) do
		local name, texture
		if SoI == "item" then
			name = v:GetName() or v.what or ""
			texture = v:GetIcon()
		else
			name, _, texture = GetSpellInfo(v)
			texture = texture or SpellTextures[name or v]
			
			if not name and Cache then
				local lowerv = strlower(v)
				for id, lowername in pairs(Cache) do
					if lowername == lowerv then
						local newname, _, newtex = GetSpellInfo(id)
						name = newname
						if not texture then
							texture = newtex
						end
						break
					end
				end
			end
			
			name = name or v or ""
			texture = texture or SpellTextures[name]
		end

		if not tiptemp[name] then --prevents display of the same name twice when there are multiple spellIDs.
			numadded = numadded + 1
			local dur = Types[CI.ics.Type].DurationSyntax and " ("..TMW:FormatSeconds(durations[k])..")" or ""
			str = str ..
			(texture and ("|T" .. texture .. ":0|t") or "") ..
			name ..
			dur ..
			"; " ..
			(floor(numadded/numperline) == numadded/numperline and "\r\n" or "")
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	str = strtrim(str, "\r\n ;")
	--cachednames[CI.ics.Type .. SoI .. text] = str
	return str
end


---------- Icon Update Scheduler ----------
function IE:ScheduleIconSetup(icon)
	-- this is a handler to prevent the spamming of icon:Setup().
	if not icon then
		icon = CI.icon
	end

	if not TMW.tContains(IE.iconsToUpdate, icon) then
		tinsert(IE.iconsToUpdate, icon)
	end
end




-- -----------------------
-- IMPORT/EXPORT
-- -----------------------

---------- High-level Functions ----------
function TMW:Import(SettingsItem, ...)
	local settings = SettingsItem.Settings
	local version = SettingsItem.Version
	local type = SettingsItem.Type

	assert(settings, "Missing settings to import")
	assert(version, "Missing version of settings")
	assert(type, "No settings type specified!")

	CloseDropDownMenus()

	TMW:Fire("TMW_IMPORT_PRE", SettingsItem, ...)
	
	local SharableDataType = TMW.approachTable(TMW, "Classes", "SharableDataType", "types", SettingsItem.Type)
	if SharableDataType and SharableDataType.Import_ImportData then
		SharableDataType:Import_ImportData(SettingsItem, ...)

		TMW:Update()
		IE:Load(1)
		
		TMW:Print(L["IMPORT_SUCCESSFUL"])
	else
		TMW:Print(L["IMPORTERROR_INVALIDTYPE"])
	end

	TMW:Fire("TMW_IMPORT_POST", SettingsItem, ...)
	
	TMW:CompileOptions()
	IE:NotifyChanges()
end


---------- Serialization ----------
function TMW:SerializeData(data, type, ...)
	-- nothing more than a wrapper for AceSerializer-3.0
	assert(data, "No data to serialize!")
	assert(type, "No data type specified!")
	return TMW:Serialize(data, TELLMEWHEN_VERSIONNUMBER, " ~", type, ...)
end

function TMW:MakeSerializedDataPretty(string)
	return string:
	gsub("(^[^tT%d][^^]*^[^^]*)", "%1 "): -- add spaces between tables to clean it up a little
	gsub("~J", "~J "): -- ~J is the escape for a newline
	gsub("%^ ^", "^^") -- remove double space at the end
end

function TMW:DeserializeDatum(string)
	local success, data, version, spaceControl, type = TMW:Deserialize(string)
	
	if not success or not data then
		-- corrupt/incomplete string
		return nil
	end

	if spaceControl then
		if spaceControl:find("`|") then
			-- EVERYTHING is fucked up. try really hard to salvage it. It probably won't be completely successful
			return TMW:DeserializeDatum(string:gsub("`", "~`"):gsub("~`|", "~`~|"))
		elseif spaceControl:find("`") then
			-- if spaces have become corrupt, then reformat them and... re-deserialize (lol)
			return TMW:DeserializeDatum(string:gsub("`", "~`"))
		elseif spaceControl:find("~|") then
			-- if pipe characters have been screwed up by blizzard's cute little method of escaping things combined with AS-3.0's cute way of escaping things, try to fix them.
			return TMW:DeserializeDatum(string:gsub("~||", "~|"))
		end
	end

	if not version then
		-- if the version is not included in the data,
		-- then it must have been before the first version that included versions in export strings/comm,
		-- so just take a guess that it was the first version that had version checks with it.
		version = 41403
	end

	if version <= 45809 and not type and data.Type then
		-- 45809 was the last version to contain untyped data messages.
		-- It only supported icon imports/exports, so the type has to be an icon.
		type = "icon"
	end

	if version <= 60032 and type == "global" then
		-- 60032 was the last version that used "global" as the identifier for "profile"
		type = "profile"
	end

	if not TMW.Classes.SharableDataType.types[type] then
		-- unknown data type
		return nil
	end


	-- finally, we have everything we need. create a result object and return it.
	local result = {
		data = data,
		type = type,
		version = version,
		select(6, TMW:Deserialize(string)), -- capture all extra args
	}

	return result
end

function TMW:DeserializeData(str)
	if not str then 
		return
	end

	local results

	str = gsub(str, "[%c ]", "")

	for string in gmatch(str, "(^%d+.-^^)") do
		results = results or {}

		local result = TMW:DeserializeDatum(string)

		tinsert(results, result)
	end

	return results
end


---------- Settings Manipulation ----------
function TMW:GetSettingsString(type, settings, defaults, ...)
	assert(settings, "No data to serialize!")
	assert(type, "No data type specified!")
	assert(defaults, "No defaults specified!")

	-- ... contains additional data that may or may not be used/needed
	settings = CopyTable(settings)
	settings = TMW:CleanSettings(type, settings, defaults)
	return TMW:SerializeData(settings, type, ...)
end

function TMW:GetSettingsStrings(strings, type, settings, defaults, ...)
	assert(settings, "No data to serialize!")
	assert(type, "No data type specified!")
	assert(defaults, "No defaults specified!")

	IE:SaveSettings()
	local strings = strings or {}

	local string = TMW:GetSettingsString(type, settings, defaults, ...)
	if not TMW.tContains(strings, string) then
		tinsert(strings, string)

		TMW:Fire("TMW_EXPORT_SETTINGS_REQUESTED", strings, type, settings)
	end

	TMW.tRemoveDuplicates(strings)

	return strings
end

function TMW:CleanDefaults(settings, defaults, blocker)
	-- make sure and pass in a COPY of the settings, not the original settings
	-- the following function is a slightly modified version of the one that AceDB uses to strip defaults.

	-- remove all metatables from the db, so we don't accidentally create new sub-tables through them
	setmetatable(settings, nil)
	-- loop through the defaults and remove their content
	for k,v in pairs(defaults) do
		if k == "*" or k == "**" then
			if type(v) == "table" then
				-- Loop through all the actual k,v pairs and remove
				for key, value in pairs(settings) do
					if type(value) == "table" then
						-- if the key was not explicitly specified in the defaults table, just strip everything from * and ** tables
						if defaults[key] == nil and (not blocker or blocker[key] == nil) then
							TMW:CleanDefaults(value, v)
							-- if the table is empty afterwards, remove it
							if next(value) == nil then
								settings[key] = nil
							end
						-- if it was specified, only strip ** content, but block values which were set in the key table
						elseif k == "**" then
							TMW:CleanDefaults(value, v, defaults[key])
						end
					end
				end
			elseif k == "*" then
				-- check for non-table default
				for key, value in pairs(settings) do
					if defaults[key] == nil and v == value then
						settings[key] = nil
					end
				end
			end
		elseif type(v) == "table" and type(settings[k]) == "table" then
			-- if a blocker was set, dive into it, to allow multi-level defaults
			TMW:CleanDefaults(settings[k], v, blocker and blocker[k])
			if next(settings[k]) == nil then
				settings[k] = nil
			end
		else
			-- check if the current value matches the default, and that its not blocked by another defaults table
			if settings[k] == defaults[k] and (not blocker or blocker[k] == nil) then
				settings[k] = nil
			end
		end
	end
	return settings
end

function TMW:CleanSettings(type, settings, defaults)
	return TMW:CleanDefaults(settings, defaults)
end


---------- Dropdown ----------


TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox == TMW.IE.ExportBox then	
		
		if IE.CurrentTab.doesGroup then	
			import.group_overwrite = CI.group
			export.group = CI.group
		end
		
		if IE.CurrentTab.doesIcon then
			import.icon = CI.icon
			export.icon = CI.icon
		end
	end
end)

TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox.IsImportExportWidget then
		local info = editbox.obj.userdata
		
		import.group_overwrite = FindGroupFromInfo(info)
		export.group = FindGroupFromInfo(info)
	end
end)



-- ----------------------
-- UNDO/REDO
-- ----------------------


IE.RapidSettings = {
	-- settings that can be changed very rapidly, i.e. via mouse wheel or in a color picker
	-- consecutive changes of these settings will be ignored by the undo/redo module
	r = true,
	g = true,
	b = true,
	a = true,
	Size = true,
	Level = true,
	Alpha = true,
	UnAlpha = true,
	GUID = true,
}
function IE:RegisterRapidSetting(setting)
	IE.RapidSettings[setting] = true
end

---------- Comparison ----------
function IE:GetCompareResultsPath(match, ...)
	if match then
		return true
	end
	local path = ""
	local setting
	for i, v in TMW:Vararg(...) do
		if i == 1 then
			setting = v
		end
		path = path .. v .. "\001"
	end
	return path, setting
end


---------- DoStuff ----------
function IE:AttemptBackup(icon)
	if not icon then return end

	if not icon.history then
		-- create the needed infrastructure for storing icon history if it does not exist.
		-- this includes creating the first history point
		icon.history = {TMW:CopyWithMetatable(icon:GetSettings())}
		icon.historyState = #icon.history

		-- notify the undo and redo buttons that there was a change so they can :Enable() or :Disable()
		IE:UndoRedoChanged()
	else
		-- the needed stuff for undo and redo already exists, so lets delve into the meat of the process.

		-- compare the current icon settings with what we have in the currently used history point
		-- the currently used history point may or may not be the most recent settings of the icon, but we want to check ics against what is being used.
		-- result is either (true) if there were no changes in the settings, or a string representing the key path to the first setting change that was detected.
		--(it was likely only one setting that changed, but not always)
		local result, changedSetting = IE:GetCompareResultsPath(TMW:DeepCompare(icon.history[icon.historyState], icon:GetSettings()))
		if type(result) == "string" then
			-- if we are using an old history point (i.e. we hit undo a few times and then made a change),
			-- delete all history points from the current one forward so that we dont jump around wildly when undoing and redoing
			for i = icon.historyState + 1, #icon.history do
				icon.history[i] = nil
			end

			-- if the last setting that was changed is the same as the most recent setting that was changed,
			-- and if the setting is one that can be changed very rapidly,
			-- delete the previous history point so that we dont murder our memory usage and piss off the user as they undo a number from 1 to 10, 0.1 per click.
			if icon.lastChangePath == result and IE.RapidSettings[changedSetting] then
				icon.history[#icon.history] = nil
				icon.historyState = #icon.history
			end
			icon.lastChangePath = result

			-- finally, create the newest history point.
			-- we copy with with the metatable so that when doing comparisons against the current icon settings, we can invoke metamethods.
			-- this is needed because otherwise an empty event table (icon:GetSettings().Events) will not match a fleshed out one that has no non-default data in it.
			icon.history[#icon.history + 1] = TMW:CopyWithMetatable(icon:GetSettings())

			-- set the history state to the latest point
			icon.historyState = #icon.history
			-- notify the undo and redo buttons that there was a change so they can :Enable() or :Disable()
			IE:UndoRedoChanged()
			
			TMW:Fire("TMW_CONFIG_ICON_HISTORY_STATE_CREATED", icon)
		end
	end
end

function IE:DoUndoRedo(direction)
	local icon = CI.icon
	
	IE:UndoRedoChanged()

	if not icon.history[icon.historyState + direction] then return end -- not valid, so don't try

	icon.historyState = icon.historyState + direction

	TMW.CI.gs.Icons[CI.icon.ID] = nil -- recreated when passed into CTIPWM
	TMW:CopyTableInPlaceWithMeta(icon.history[icon.historyState], CI.ics)
	
	CI.icon:Setup() -- do an immediate setup for good measure
	
	TMW:Fire("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", icon)

	CloseDropDownMenus()
	IE:Load(1)
	
	IE:UndoRedoChanged()
end


---------- Interface ----------
function IE:UndoRedoChanged()
	local icon = CI.icon
	
	if icon then
		if not icon.historyState or icon.historyState - 1 < 1 then
			IE.UndoButton:Disable()
			IE.CanUndo = false
		else
			IE.UndoButton:Enable()
			IE.CanUndo = true
		end

		if not icon.historyState or icon.historyState + 1 > #icon.history then
			IE.RedoButton:Disable()
			IE.CanRedo = false
		else
			IE.RedoButton:Enable()
			IE.CanRedo = true
		end
	end
end


---------- Back/Fowards ----------
function IE:DoBackForwards(direction)
	if not IE.history[IE.historyState + direction] then return end -- not valid, so don't try

	IE.historyState = IE.historyState + direction

	CloseDropDownMenus()
	IE:Load(nil, IE.history[IE.historyState], true)

	IE:BackFowardsChanged()
end

function IE:BackFowardsChanged()
	if IE.historyState - 1 < 1 then
		IE.BackButton:Disable()
		IE.CanBack = false
	else
		IE.BackButton:Enable()
		IE.CanBack = true
	end

	if IE.historyState + 1 > #IE.history then
		IE.ForwardsButton:Disable()
		IE.CanFowards = false
	else
		IE.ForwardsButton:Enable()
		IE.CanFowards = true
	end
end








