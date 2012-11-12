-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

TMW.WidthCol1 = 150

---------- Libraries ----------
local LSM = LibStub("LibSharedMedia-3.0")
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local DogTag = LibStub("LibDogTag-3.0", true)

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
local GetSpellInfo, GetContainerItemID, GetContainerItemLink =
	  GetSpellInfo, GetContainerItemID, GetContainerItemLink
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, pcall, assert, rawget, rawset, unpack, select =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, pcall, assert, rawget, rawset, unpack, select
local strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10
local GetItemInfo, GetItemIcon, GetInventoryItemID, GetInventoryItemLink, GetInventoryItemTexture, GetInventorySlotInfo, GetContainerNumSlots =
	  GetItemInfo, GetItemIcon, GetInventoryItemID, GetInventoryItemLink, GetInventoryItemTexture, GetInventorySlotInfo, GetContainerNumSlots
local GetNumTrackingTypes, GetTrackingInfo =
	  GetNumTrackingTypes, GetTrackingInfo
local GetBuildInfo, IsInGuild, UnitInBattleground, UnitRace, UnitName =
	  GetBuildInfo, IsInGuild, UnitInBattleground, UnitRace, UnitName
local GetSpellBookItemInfo, HasPetSpells, GetSpellTabInfo, GetActionInfo =
	  GetSpellBookItemInfo, HasPetSpells, GetSpellTabInfo, GetActionInfo
local GetNumTalentTabs, GetNumTalents, GetTalentInfo, GetTalentLink =
	  GetNumTalentTabs, GetNumTalents, GetTalentInfo, GetTalentLink
local GetCursorPosition, GetCursorInfo, GetMouseFocus, CursorHasSpell, CursorHasItem, ClearCursor =
	  GetCursorPosition, GetCursorInfo, GetMouseFocus, CursorHasSpell, CursorHasItem, ClearCursor
local _G, bit, CopyTable, hooksecurefunc, IsAddOnLoaded, IsMacClient, GetLocale, GetAchievementInfo, IsControlKeyDown, PlaySound =
	  _G, bit, CopyTable, hooksecurefunc, IsAddOnLoaded, IsMacClient, GetLocale, GetAchievementInfo, IsControlKeyDown, PlaySound
local _G = _G
local bit = bit
local CopyTable = CopyTable
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures
local print = TMW.print
local Types = TMW.Types
local IE, ID, TEXT


---------- Locals ----------
local _, pclass = UnitClass("Player")
local tiptemp = {}
local get = TMW.get

---------- Globals ----------
--GLOBALS: BINDING_HEADER_TELLMEWHEN, BINDING_NAME_TELLMEWHEN_ICONEDITOR_UNDO, BINDING_NAME_TELLMEWHEN_ICONEDITOR_REDO
BINDING_HEADER_TELLMEWHEN = L["ICON_TOOLTIP1"]
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

local operators = {
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
	if k == "ics" then
		-- take no chances with errors occuring here
		return tbl.ic and tbl.ic:GetSettings()
	elseif k == "gs" then
		-- take no chances with errors occuring here
		return TMW.approachTable(TMW.db, "profile", "Groups", tbl.g)
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
	
	Call = function(self, text, linkType, linkID)
		if self.editbox:HasFocus() then
			return TMW.safecall(self.func, self, text, linkType, linkID)
		end
	end,
}

local old_ChatEdit_InsertLink = ChatEdit_InsertLink
local function hook_ChatEdit_InsertLink(text)	
	if type(text) ~= "string" then
		return false
	end
	
	local Type, id = strmatch(text, "|H(.-):(%d+)")
	
	if not id then return false end

	for _, instance in pairs(TMW.Classes.ChatEdit_InsertLink_Hook.instances) do
		local executionSuccess, insertResult = instance:Call(text, Type, id)
		if executionSuccess then
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
function TMW:GetIconMenuText(g, i, ics)
	ics = ics or TMW.db.profile.Groups[tonumber(g)].Icons[tonumber(i)]

	local Type = ics.Type or ""
	local typeData = Types[Type]

	local text, tooltip, dontShorten = typeData:GetIconMenuText(ics, g, i)

	text = text == "" and L["UNNAMED"] or text
	local textshort = not dontShorten and strsub(text, 1, 40) or text

	if strlen(text) > 40 and not dontShorten then
		textshort = textshort .. "..."
	end

	tooltip =	tooltip ..
				((typeData.name) or "") ..
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
	-- TODO: this function is absolutely horrifying. Do not use it for anything, and remove its usage everywhere.
	frame.selectedValue = value

	if tbl then
		if tbl == TMW.InIcons and type(value) == "string" then
			for icon in TMW:InIcons() do
				if icon:GetName() == value then
					local g, i = strmatch(value, "TellMeWhen_Group(%d+)_Icon(%d+)")
					UIDropDownMenu_SetText(frame, TMW:GetIconMenuText(tonumber(g), tonumber(i), icon:GetSettings()))
					return icon
				end
			end
			local gID, iID = strmatch(value, "TellMeWhen_Group(%d+)_Icon(%d+)")
			if gID and iID then
				UIDropDownMenu_SetText(frame, format(L["GROUPICON"], TMW:GetGroupName(gID, gID, 1), iID))
				return
			else
				local gID = tonumber(strmatch(value, "TellMeWhen_Group(%d+)$"))
				if gID then
					UIDropDownMenu_SetText(frame, TMW:GetGroupName(gID, gID))
					return
				end
			end
			UIDropDownMenu_SetText(frame, text)
			return
		end
		for k, v in pairs(tbl) do
			if v.value == value then
				UIDropDownMenu_SetText(frame, v.text)
				return v
			end
		end
	end
	UIDropDownMenu_SetText(frame, text or value)
end

function TMW.AddDropdownSpacer()
	local info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

function TMW:SetIconPreviewIcon(icon)
	if not icon or not icon.IsIcon then
		self:Hide()
		return
	end

	local groupID = icon.group:GetID()
	TMW:TT(self, format(L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), icon:GetID()), "ICON_TOOLTIP2NEWSHORT", 1, nil)
	self.icon = icon
	self.texture:SetTexture(icon and icon.attributes.texture)
	self:Show()
end


---------- Misc Utilities ----------
do -- TMW:ReconcileData()
	local isRunning
	local source_use, destination_use, matchSource_use, matchDestination_use, swap_use
	
	
	local function replace(table, key)
		assert(isRunning, "TMW:ReconcileData() isn't running!")
		
		TMW:ValidateType(1, "replace()", table, "table")
		assert(key ~= nil, "TMW: replace() - arg2 (key) cannot be nil")
		
		local string = table[key]

		if matchSource_use and string:find(matchSource_use) then
			table[key] = string:gsub(source_use, destination_use)
		elseif not matchSource_use and source_use == string then
			table[key] = destination_use
		elseif swap_use and matchDestination_use and string:find(matchDestination_use) then
			table[key] = string:gsub(destination_use, source_use)
		elseif swap_use and not matchDestination_use and destination_use == string then
			table[key] = source_use
		end
	end

	function TMW:ReconcileData(source, destination, matchSource, matchDestination, swap, limitSourceGroup)
		assert(not isRunning)
		isRunning = true
		
		assert(source)
		assert(destination)
		
		source_use, destination_use, matchSource_use, matchDestination_use, swap_use =
		source,		destination,	 matchSource,	  matchDestination,		swap

		TMW:Fire("TMW_CONFIG_ICON_RECONCILIATION_REQUESTED", replace, limitSourceGroup)
		
		isRunning = false
	end
end

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
	-- TODO
	f:SetHeight(endHeight)
	do return end
	
	if not f.__animateHeightHooked2 then
		f.__animateHeightHooked2 = true
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

-- --------------
-- MAIN OPTIONS
-- --------------

---------- Data/Templates ----------
local function findid(info)
	for i = #info, 1, -1 do
		local n = tonumber(strmatch(info[i], "#Group (%d+)"))
		if n then return n end
	end
end TMW.FindGroupIDFromInfo = findid
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

local groupSortPriorities = {
	"id",
	"duration",
	"stacks",
	"visiblealpha",
	"visibleshown",
	"alpha",
	"shown",
}
local groupSortValues = {
	L["UIPANEL_GROUPSORT_id"],
	L["UIPANEL_GROUPSORT_duration"],
	L["UIPANEL_GROUPSORT_stacks"],
	L["UIPANEL_GROUPSORT_visiblealpha"],
	L["UIPANEL_GROUPSORT_visibleshown"],
	L["UIPANEL_GROUPSORT_alpha"],
	L["UIPANEL_GROUPSORT_shown"],
}
local groupSortMethodTemplate -- this is intentional
groupSortMethodTemplate = {
	type = "group",
	name = function(info)
		return ""
	end,
	order = function(info)
		return tonumber(info[#info])
	end,
	disabled = function(info, priorityID)
		local g = findid(info)
		local priorityID = priorityID or tonumber(info[#info-1])
		for k, v in pairs(TMW.db.profile.Groups[g].SortPriorities) do
			if k < priorityID and v.Method == "id" then
				return true
			end
		end
	end,
	dialogInline = true,
	guiInline = true,
	args = {
		method = {
			name = function(info)
				local priorityID = tonumber(info[#info-1])
				return L["UIPANEL_GROUPSORT_METHODNAME"]:format(priorityID)
			end,
			desc = function(info)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				local Method = TMW.db.profile.Groups[g].SortPriorities[priorityID].Method

				local desc = L["UIPANEL_GROUPSORT_METHODNAME_DESC"]:format(priorityID) .. "\r\n\r\n" .. L["UIPANEL_GROUPSORT_" .. Method .. "_DESC"]
				if groupSortMethodTemplate.disabled(info, priorityID) then
					desc = desc .. "\r\n\r\n" .. L["UIPANEL_GROUPSORT_METHODDISABLED_DESC"]
				end
				return desc
			end,
			type = "select",
			width = "double",
			values = groupSortValues,
			style = "dropdown",
			order = 1,
			get = function(info)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				local Method = TMW.db.profile.Groups[g].SortPriorities[priorityID].Method
				for k, v in pairs(groupSortPriorities) do
					if Method == v then
						return k
					end
				end
			end,
			set = function(info, val)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				local oldPriority = TMW.db.profile.Groups[g].SortPriorities[priorityID]
				local newPriority
				for k, v in pairs(TMW.db.profile.Groups[g].SortPriorities) do
					if v.Method == groupSortPriorities[val] then
						TMW.db.profile.Groups[g].SortPriorities[k] = oldPriority
						TMW.db.profile.Groups[g].SortPriorities[priorityID] = v
						break
					end
				end
				TMW[g]:Setup()
			end,
		},
		OrderAscending = {
			name = L["UIPANEL_GROUPSORT_SORTASCENDING"],
			desc = L["UIPANEL_GROUPSORT_SORTASCENDING_DESC"],
			type = "toggle",
			width = "half",
			order = 2,
			get = function(info)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				return TMW.db.profile.Groups[g].SortPriorities[priorityID].Order == 1
			end,
			set = function(info)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				TMW.db.profile.Groups[g].SortPriorities[priorityID].Order = 1
				TMW[g]:Setup()
			end,
		},
		OrderDescending = {
			name = L["UIPANEL_GROUPSORT_SORTDESCENDING"],
			desc = L["UIPANEL_GROUPSORT_SORTDESCENDING_DESC"],
			type = "toggle",
			width = "half",
			order = 3,
			get = function(info)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				return TMW.db.profile.Groups[g].SortPriorities[priorityID].Order == -1
			end,
			set = function(info)
				local g = findid(info)
				local priorityID = tonumber(info[#info-1])
				TMW.db.profile.Groups[g].SortPriorities[priorityID].Order = -1
				TMW[g]:Setup()
			end,
		},
	}
}
TMW.GroupConfigTemplate = {
	type = "group",
	childGroups = "tab",
	name = function(info) local g=findid(info) return TMW:GetGroupName(g, g) end,
	order = function(info) return findid(info) end,
	args = {
		main = {
			type = "group",
			name = L["MAIN"],
			desc = L["UIPANEL_MAIN_DESC"],
			order = 1,
			args = {
				Enabled = {
					name = L["UIPANEL_ENABLEGROUP"],
					desc = L["UIPANEL_TOOLTIP_ENABLEGROUP"],
					type = "toggle",
					order = 1,
				},
				Name = {
					name = L["UIPANEL_GROUPNAME"],
					type = "input",
					order = 2,
					width = "double",
					set = function(info, val)
						local g = findid(info)
						TMW.db.profile.Groups[g].Name = strtrim(val)
						TMW[g]:Setup()
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
					order = 6,
				},
				SecondarySpec = {
					name = L["UIPANEL_SECONDARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_SECONDARYSPEC"],
					type = "toggle",
					order = 7,
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
				SpacingX = {
					name = L["UIPANEL_ICONSPACINGX"],
					desc = L["UIPANEL_ICONSPACING_DESC"],
					type = "range",
					order = 22,
					min = -5,
					softMax = 20,
					step = 0.1,
					bigStep = 1,
					set = function(info, val)
						local g = findid(info)
						local gs = TMW.db.profile.Groups[g]
						gs.SettingsPerView[gs.View][info[#info]] = val
						TMW[g]:Setup()
					end,
					get = function(info)
						local g = findid(info)
						local gs = TMW.db.profile.Groups[g]
						return gs.SettingsPerView[gs.View][info[#info]]
					end,
				},
				SpacingY = {
					name = L["UIPANEL_ICONSPACINGY"],
					desc = L["UIPANEL_ICONSPACING_DESC"],
					type = "range",
					order = 23,
					min = -5,
					softMax = 20,
					step = 0.1,
					bigStep = 1,
					set = function(info, val)
						local g = findid(info)
						local gs = TMW.db.profile.Groups[g]
						gs.SettingsPerView[gs.View][info[#info]] = val
						TMW[g]:Setup()
					end,
					get = function(info)
						local g = findid(info)
						local gs = TMW.db.profile.Groups[g]
						return gs.SettingsPerView[gs.View][info[#info]]
					end,
				},
				
				CheckOrder = {
					name = L["CHECKORDER"],
					desc = L["CHECKORDER_ICONDESC"],
					type = "select",
					values = checkorder,
					style = "dropdown",
					order = 26,
				},
				LayoutDirection = {
					name = L["LAYOUTDIRECTION"],
					desc = L["LAYOUTDIRECTION_DESC"],
					type = "select",
					values = {
						L["LAYOUTDIRECTION_1"],
						L["LAYOUTDIRECTION_2"],
						L["LAYOUTDIRECTION_3"],
						L["LAYOUTDIRECTION_4"],
						L["LAYOUTDIRECTION_5"],
						L["LAYOUTDIRECTION_6"],
						L["LAYOUTDIRECTION_7"],
						L["LAYOUTDIRECTION_8"],
					},  
					style = "dropdown",
					order = 27,
				},
				View = {
					name = L["UIPANEL_GROUPTYPE"],
					desc = L["UIPANEL_GROUPTYPE_DESC"],
					type = "group",
					dialogInline = true,
					guiInline = true,
					order = 30,
					get = function(info)
						local g = findid(info)
						return TMW.db.profile.Groups[g][info[#info-1]] == info[#info]
					end,
					set = function(info)
						local g = findid(info)
						TMW.db.profile.Groups[g][info[#info-1]] = info[#info]
						TMW[g]:Setup()
						TMW[g]:Setup()
						IE:Load(1)
						TMW:CompileOptions()
					end,
					args = {}
				},
				moveup = {
					name = L["UIPANEL_GROUPMOVEUP"],
					desc = L["UIPANEL_GROUPMOVEUP_DESC"],
					type = "execute",
					order = 48,
					func = function(info)
						TMW:Group_Swap(findid(info), findid(info) - 1)
						IE:NotifyChanges("groups", "#Group " .. findid(info) - 1)
					end,
					disabled = function(info)
						return findid(info) == 1
					end,
				},
				movedown = {
					name = L["UIPANEL_GROUPMOVEDOWN"],
					desc = L["UIPANEL_GROUPMOVEDOWN_DESC"],
					type = "execute",
					order = 49,
					func = function(info)
						TMW:Group_Swap(findid(info), findid(info) + 1)
						IE:NotifyChanges("groups", "#Group " .. findid(info) + 1)
					end,
					disabled = function(info)
						return findid(info) == TMW.db.profile.NumGroups
					end,
				},
				delete = {
					name = L["UIPANEL_DELGROUP"],
					desc = L["UIPANEL_DELGROUP_DESC"],
					type = "execute",
					order = 50,
					func = function(info)
						TMW:Group_Delete(findid(info))
					end,
					disabled = function()
						return TMW.db.profile.NumGroups == 1
					end,
					confirm = function(info)
						if IsControlKeyDown() then
							return false
						elseif TMW:Group_HasIconData(findid(info)) then
							return true
						end
						return false
					end,
				},
				ImportExport = importExportBoxTemplate,
			},
		},

		Sorting = {
			name = L["UIPANEL_GROUPSORT"],
			desc = L["UIPANEL_GROUPSORT_DESC"],
			type = "group",
			order = 10,
			args = (function()
				-- cheesy (or clever) inline dynamic table generation
				local t = {}
				for i = 1, #TMW.Group_Defaults.SortPriorities do
					t[tostring(i)] = groupSortMethodTemplate
				end
				return t
			end)()
		},
	}
}

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
		local groupID, group = TMW:Group_Add()
		
		local gs = TMW.db.profile.Groups[groupID]
		gs.View = info[#info]
		TMW:Update()
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


---------- Options Table Compilation ----------
function TMW:CompileOptions()
	if not TMW.OptionsTable then
		TMW.OptionsTable = {
			name = L["ICON_TOOLTIP1"] .. " " .. TELLMEWHEN_VERSION_FULL,
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
								DrawEdge = {
									name = L["UIPANEL_DRAWEDGE"],
									desc = L["UIPANEL_DRAWEDGE_DESC"],
									type = "toggle",
									order = 40,
									hidden = TMW.ISMOP, -- Cooldown:SetDrawEdge was removed in MoP
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
									order = 41,
								},
								ColorNames = {
									name = L["COLORNAMES"],
									desc = L["COLORNAMES_DESC"],
									type = "toggle",
									order = 42,
								},
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
							},
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
				
				groups = {
					type = "group",
					name = L["UIPANEL_GROUPS"],
					desc = L["UIPANEL_GROUPS_DESC"],
					order = 30,
					set = function(info, val)
						local g = findid(info)
						TMW.db.profile.Groups[g][info[#info]] = val
						TMW[g]:Setup()
					end,
					get = function(info) return TMW.db.profile.Groups[findid(info)][info[#info]] end,
					args = {
						addgroup = addGroupFunctionGroup,
						importexport = importExportBoxTemplate,
						addgroupgroup = {
							type = "group",
							name = L["UIPANEL_ADDGROUP"],
							args = {
								addgroup = addGroupFunctionGroup,
								importexport = importExportBoxTemplate,
							},
						},
					},
				},
			},
		}
		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(TMW.db)
		TMW.OptionsTable.args.profiles.args = CopyTable(TMW.OptionsTable.args.profiles.args) -- dont copy the entire table because it contains a reference to db ... and will copy the entire TMW.db.
		TMW.OptionsTable.args.profiles.args.importexportdesc = {
			order = 90,
			type = "description",
			name = "\r\n" .. L["IMPORT_EXPORT_DESC_INLINE"],
			--hidden = function() return IE.ExportBox:IsVisible() end,
		}
		TMW.OptionsTable.args.profiles.args.importexport = importExportBoxTemplate
	end

	-- Dynamic Icon View Settings --
	for view in pairs(TMW.Views) do
		TMW.GroupConfigTemplate.args.main.args.View.args[view] = viewSelectToggle
		addGroupFunctionGroup.args[view] = addGroupButton
	end

	-- Dynamic Group Settings --
	for k, v in pairs(TMW.OptionsTable.args.groups.args) do
		if v == TMW.GroupConfigTemplate then
			TMW.OptionsTable.args.groups.args[k] = nil
		end
	end
	for g = 1, TMW.db.profile.NumGroups do
		TMW.OptionsTable.args.groups.args["#Group " .. g] = TMW.GroupConfigTemplate
	end
	
	local parent = TMW.GroupConfigTemplate.args.main.args
	if TMW.ISMOP then
		for i = 1, GetNumSpecializations() do
			local _, name = GetSpecializationInfo(i)
			parent["Tree"..i] = parent["Tree"..i] or {
				type = "toggle",
				name = name,
				desc = L["UIPANEL_TREE_DESC"],
				order = 7+i,
			}
		end
	else
		for i = 1, GetNumTalentTabs() do
			local _, name = GetTalentTabInfo(i)
			parent["Tree"..i] = parent["Tree"..i] or {
				type = "toggle",
				name = name,
				desc = L["UIPANEL_TREE_DESC"],
				order = 7+i,
			}
		end
	end

	TMW.OptionsTable.args.groups.args.addgroupgroup.order = TMW.db.profile.NumGroups + 1

	
	-- Dynamic Color Settings --
	TMW.OptionsTable.args.colors.args.GLOBAL = colorIconTypeTemplate
	for k, Type in pairs(TMW.Types) do
		if not Type.NoColorSettings then
			TMW.OptionsTable.args.colors.args[k] = colorIconTypeTemplate
		end
	end
	
	TMW:Fire("TMW_CONFIG_MAIN_OPTIONS_COMPILE", TMW.OptionsTable)

	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW Options", TMW.OptionsTable)
	if not TMW.defaultSizeOfTMWOptionsSet then
		TMW.defaultSizeOfTMWOptionsSet = 1
		LibStub("AceConfigDialog-3.0"):SetDefaultSize("TMW Options", 781, 512)
	end
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW IEOptions", TMW.OptionsTable)
	if not TMW.AddedToBlizz then
		TMW.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TMW Options", L["ICON_TOOLTIP1"])
	end
end



-- -------------
-- GROUP CONFIG
-- -------------

---------- Add/Delete ----------
function TMW:Group_Delete(groupID)
	if TMW.db.profile.NumGroups == 1 then
		return
	end

	for id = groupID + 1, TMW.db.profile.NumGroups do
		local source = "TellMeWhen_Group" .. id
		local destination = "TellMeWhen_Group" .. id - 1

		-- check for groups exactly
		TMW:ReconcileData(source, destination)

		-- check for any icons of a group.
		TMW:ReconcileData(source, destination, source .. "_Icon", destination .. "_Icon")
	end

	tremove(TMW.db.profile.Groups, groupID)
	TMW.db.profile.NumGroups = TMW.db.profile.NumGroups - 1

	TMW:Update()
	IE:Load(1)
	TMW:CompileOptions()
	IE:NotifyChanges()
	CloseDropDownMenus()
end

function TMW:Group_Add()
	local groupID = TMW.db.profile.NumGroups + 1
	TMW.db.profile.NumGroups = groupID
	TMW.db.profile.Groups[TMW.db.profile.NumGroups].Enabled = true
	TMW:Update()

	TMW:CompileOptions()
	IE:NotifyChanges("groups", "#Group " .. groupID)
	return groupID, TMW[groupID]
end

function TMW:Group_Swap(groupID1, groupID2)
	local source = "TellMeWhen_Group" .. groupID1
	local destination = "TellMeWhen_Group" .. "TEMP"

	TMW:ReconcileData(source, destination)
	TMW:ReconcileData(source, destination, source .. "_Icon", destination .. "_Icon")

	local source = "TellMeWhen_Group" .. groupID2
	local destination = "TellMeWhen_Group" .. groupID1

	TMW:ReconcileData(source, destination)
	TMW:ReconcileData(source, destination, source .. "_Icon", destination .. "_Icon")
	
	
	local source = "TellMeWhen_Group" .. "TEMP"
	local destination = "TellMeWhen_Group" .. groupID2
	TMW:ReconcileData(source, destination)
	TMW:ReconcileData(source, destination, source .. "_Icon", destination .. "_Icon")

	local Groups = TMW.db.profile.Groups
	Groups[groupID1], Groups[groupID2] = Groups[groupID2], Groups[groupID1]
    
    TMW:Update()
	IE:Load(1)
	TMW:CompileOptions()
	IE:NotifyChanges()
end


---------- Etc ----------
function TMW:Group_HasIconData(groupID)
	for ics in TMW:InIconSettings(groupID) do
		if not IE:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
			return true
		end
	end

	return false
end


-- ----------------------
-- ICON DRAGGER
-- ----------------------

ID = TMW:NewModule("IconDragger", "AceTimer-3.0", "AceEvent-3.0") TMW.ID = ID

function ID:OnInitialize()
	hooksecurefunc("PickupSpellBookItem", function(...) ID.DraggingInfo = {...} end)
	WorldFrame:HookScript("OnMouseDown", function() -- this contains other bug fix stuff too
		ID.DraggingInfo = nil
		ID.F:Hide()
		ID.IsDragging = nil
	end)
	hooksecurefunc("ClearCursor", ID.BAR_HIDEGRID)
	ID:RegisterEvent("PET_BAR_HIDEGRID", "BAR_HIDEGRID")
	ID:RegisterEvent("ACTIONBAR_HIDEGRID", "BAR_HIDEGRID")


	ID.DD.wrapTooltips = 1
end

function ID:BAR_HIDEGRID()
	ID.DraggingInfo = nil
end


---------- Spell/Item Dragging ----------
function ID:SpellItemToIcon(icon, func, arg1)
	if not icon.IsIcon then
		return
	end

	local t, data, subType, param4
	local input
	if not (CursorHasSpell() or CursorHasItem()) and ID.DraggingInfo then
		t = "spell"
		data, subType = unpack(ID.DraggingInfo)
	else
		t, data, subType, param4 = GetCursorInfo()
	end
	ID.DraggingInfo = nil

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


---------- Icon Dragging ----------
function ID:DropDown()
	for i, handlerData in ipairs(ID.Handlers) do
		local info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true
		info.tooltipOnButton = true
		
		local shouldAddButton = handlerData.dropdownFunc(ID, info)
		
		info.func = ID.Handler
		info.arg1 = handlerData.actionFunc
		
		if shouldAddButton then
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end	
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = CANCEL
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	UIDropDownMenu_JustifyText(self, "LEFT")
end

function ID:Start(icon)
	ID.srcicon = icon

	local scale = icon.group:GetScale()*0.85
	ID.F:SetScript("OnUpdate", function()
		local x, y = GetCursorPosition()
		ID.texture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale )
		ID.back:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale )
	end)
	ID.F:SetScale(scale)
	local t = ID.srcicon.attributes.texture
	ID.texture:SetTexture(t)
	if t and t ~= "" then
		ID.back:Hide()
	else
		ID.back:Show()
	end
	ID.F:Show()
	ID.IsDragging = true
	end

function ID:SetIsDraggingFalse()
	ID.IsDragging = false
end

function ID:CompleteDrag(script, icon)

	ID.F:SetScript("OnUpdate", nil)
	ID.F:Hide()
	ID:ScheduleTimer("SetIsDraggingFalse", 0.1)

	icon = icon or GetMouseFocus()

	-- icon here is the destination
	if ID.IsDragging then

		if type(icon) == "table" and icon.IsIcon then -- if the frame that got the drag is an icon, set the destination stuff.

			ID.desticon = icon
			ID.destFrame = nil

			if script == "OnDragStop" then -- wait for OnDragReceived
				return
			end

			if ID.desticon.group:GetID() == ID.srcicon.group:GetID() and ID.desticon:GetID() == ID.srcicon:GetID() then
				return
			end

			UIDropDownMenu_SetAnchor(ID.DD, 0, 0, "TOPLEFT", icon, "BOTTOMLEFT")

		else
			ID.desticon = nil
			ID.destFrame = icon -- not actually an icon. just some frame.
			local cursorX, cursorY = GetCursorPosition()
			local UIScale = UIParent:GetScale()
			UIDropDownMenu_SetAnchor(ID.DD, cursorX/UIScale, cursorY/UIScale, nil, UIParent, "BOTTOMLEFT")
		end

		if not DropDownList1:IsShown() or UIDROPDOWNMENU_OPEN_MENU ~= ID.DD then
			if not ID.DD.Initialized then
				UIDropDownMenu_Initialize(ID.DD, ID.DropDown, "DROPDOWN")
				ID.DD.Initialized = true
			end
			ToggleDropDownMenu(1, nil, ID.DD)
		end
	end
end

ID.Handlers = {}
function ID:RegisterIconDragHandler(order, dropdownFunc, actionFunc)
	TMW:ValidateType("2 (order)", "ID:RegisterIconDragHandler(order, dropdownFunc, actionFunc)", order, "number")
	TMW:ValidateType("3 (func)", "ID:RegisterIconDragHandler(order, dropdownFunc, actionFunc)", dropdownFunc, "function")
	TMW:ValidateType("4 (func)", "ID:RegisterIconDragHandler(order, dropdownFunc, actionFunc)", actionFunc, "function")
	
	tinsert(ID.Handlers, {
		order = order,
		dropdownFunc = dropdownFunc,
		actionFunc = actionFunc,
	})
	
	TMW:SortOrderedTables(ID.Handlers)
end

ID:RegisterIconDragHandler(1,	-- Move
	function(ID, info)
		if ID.desticon then
			info.text = L["ICONMENU_MOVEHERE"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(ID)
		-- move the actual settings
		local srcgs = ID.srcicon.group:GetSettings()
		local srcics = ID.srcicon:GetSettings()
		
		TMW:PrepareIconSettingsForCopying(srcics, srcgs)
		
		ID.desticon.group:GetSettings().Icons[ID.desticon:GetID()] = srcgs.Icons[ID.srcicon:GetID()]
		srcgs.Icons[ID.srcicon:GetID()] = nil
		

		-- preserve buff/debuff/other types textures
		ID.desticon:SetInfo("texture", ID.srcicon.attributes.texture)

		local srcicon, desticon = tostring(ID.srcicon), tostring(ID.desticon)

		TMW:ReconcileData(srcicon, desticon)
	end
)
ID:RegisterIconDragHandler(2,	-- Copy
	function(ID, info)
		if ID.desticon then
			info.text = L["ICONMENU_COPYHERE"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(ID)
		-- copy the settings
		local srcgs = ID.srcicon.group:GetSettings()
		local srcics = ID.srcicon:GetSettings()
		TMW:PrepareIconSettingsForCopying(srcics, srcgs)
		
		ID.desticon.group:GetSettings().Icons[ID.desticon:GetID()] = TMW:CopyWithMetatable(srcics)

		-- preserve buff/debuff/other types textures
		ID.desticon:SetInfo("texture", ID.srcicon.attributes.texture)
	end
)
ID:RegisterIconDragHandler(3,	-- Swap
	function(ID, info)
		if ID.desticon then
			info.text = L["ICONMENU_SWAPWITH"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(ID)
		-- swap the actual settings
		local destgs = ID.desticon.group:GetSettings()
		local destics = ID.desticon:GetSettings()
		local srcgs = ID.srcicon.group:GetSettings()
		local srcics = ID.srcicon:GetSettings()
		TMW:PrepareIconSettingsForCopying(destics, destgs)
		TMW:PrepareIconSettingsForCopying(srcics, srcgs)
		
		destgs.Icons[ID.desticon:GetID()] = srcics
		srcgs.Icons[ID.srcicon:GetID()] = destics

		-- preserve buff/debuff/other types textures
		local desttex = ID.desticon.attributes.texture
		ID.desticon:SetInfo("texture", ID.srcicon.attributes.texture)
		ID.srcicon:SetInfo("texture", desttex)

		local srcicon, desticon = tostring(ID.srcicon), tostring(ID.desticon)

		TMW:ReconcileData(srcicon, desticon, srcicon .. "$", desticon .. "$", true)
	end
)


ID:RegisterIconDragHandler(40,	-- Split
	function(ID, info)
		if ID.destFrame then
			info.text = L["ICONMENU_SPLIT"]
			info.tooltipTitle = L["ICONMENU_SPLIT"]
			info.tooltipText = L["ICONMENU_SPLIT_DESC"]
			return true
		end
	end,
	function(ID)
		local groupID, group = TMW:Group_Add()


		-- back up the icon data of the source group
		local SOURCE_ICONS = TMW.db.profile.Groups[ID.srcicon.group:GetID()].Icons
		-- nullify it (we don't want to copy it)
		TMW.db.profile.Groups[ID.srcicon.group:GetID()].Icons = nil

		-- copy the source group.
		-- pcall so that, in the rare event of some unforseen error, we don't lose the user's settings (they haven't yet been restored)
		local success, err = pcall(TMW.CopyTableInPlaceWithMeta, TMW, TMW.db.profile.Groups[ID.srcicon.group:GetID()], TMW.db.profile.Groups[groupID])

		-- restore the icon data of the source group
		TMW.db.profile.Groups[ID.srcicon.group:GetID()].Icons = SOURCE_ICONS
		-- now it is safe to error since we restored the old settings
		assert(success, err)


		local gs = TMW.db.profile.Groups[groupID]
		--gs.Icons = blankIcons

		-- group tweaks
		gs.Rows = 1
		gs.Columns = 1
		gs.Name = ""

		-- adjustments and positioning
		local p = gs.Point
		p.point, p.relativeTo, p.relativePoint, p.x, p.y = ID.texture:GetPoint(2)
		p.x, p.y = p.x/UIParent:GetScale()*.85, p.y/UIParent:GetScale()*.85
		p.relativeTo = "UIParent"
		TMW:Group_StopMoving(ID.srcicon.group)


		TMW[groupID]:Setup()

		-- move the actual icon
		-- move the actual settings
		gs.Icons[1] = ID.srcicon.group.Icons[ID.srcicon:GetID()]
		ID.srcicon.group.Icons[ID.srcicon:GetID()] = nil

		-- preserve buff/debuff/other types textures
		if group and group[1] then
			group[1]:SetInfo("texture", ID.srcicon.attributes.texture)
		end

		local srcicon, desticon = tostring(ID.srcicon), tostring("TellMeWhen_Group" .. groupID .. "_Icon1")

		TMW:ReconcileData(srcicon, desticon)

		TMW[groupID]:Setup()
	end
)

---------- Icon Handler ----------
function ID:Handler(method)
	-- close the menu
	CloseDropDownMenus()

	-- save misc. settings
	IE:SaveSettings()

	-- attempt to create a backup before doing anything
	IE:AttemptBackup(ID.srcicon)
	IE:AttemptBackup(ID.desticon)

	-- finally, invoke the method to handle the operation.
	method(ID)

	-- then, update things
	TMW:Update()
	IE:Load(1)
end








-- ----------------------
-- ICON EDITOR
-- ----------------------

IE = TMW:NewModule("IconEditor", "AceEvent-3.0", "AceTimer-3.0") TMW.IE = IE
IE.Tabs = {}

IE.CONST = {
	TAB_OFFS_X = -18,
}

function IE:OnInitialize()
	-- Shittily initialize the database. Perhaps one day this will be a real Ace3DB. Till then, its just a table.
	TMWOptDB = TMWOptDB or {}

	-- Make TMW.IE be the same as IE.
	-- IE[0] = TellMeWhen_IconEditor[0] (already done in .xml)
	local meta = CopyTable(getmetatable(IE))
	meta.__index = getmetatable(TellMeWhen_IconEditor).__index
	setmetatable(IE, meta)

	IE:HookScript("OnShow", function()
		TMW:RegisterCallback("TMW_ONUPDATE_POST", IE)
	end)
	IE:HookScript("OnHide", function()
		TMW:UnregisterCallback("TMW_ONUPDATE_POST", IE)
	end)
	IE:SetScript("OnUpdate", IE.OnUpdate)
	IE.iconsToUpdate = {}

	IE.history = {}
	IE.historyState = 0

	TMW:NewClass("IconEditor_Resizer_ScaleX_SizeY", "Resizer_Generic"){
		tooltipText = TMW.L["RESIZE_TOOLTIP"],
		UPD_INTV = 1,
		tooltipTitle = TMW.L["RESIZE"],
		
		OnEnable = function(self)
			self.resizeButton:Show()
		end,
		
		OnDisable = function(self)
			self.resizeButton:Hide()
		end,	
		
		SizeUpdate = function(resizeButton)
			--[[ Notes:
			--	arg1 (self) is resizeButton
				
			--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
				More specifically, it means that it does not depend on the scale of either the parent nor UIParent.
			]]
			local self = resizeButton.module
			
			local parent = self.parent
			local uiScale = UIParent:GetScale()
			
			local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()

			
			
			-- Calculate and set new scale:
			local std_newWidth = abs(self.std_oldLeft - std_cursorX)
			local ratio_SizeChangeX = std_newWidth/self.std_oldWidth
			local newScale = ratio_SizeChangeX*self.oldScale
			newScale = max(0.4, newScale)
			--[[
				Holy shit. Look at this wicked sick dimensional analysis:
				
				std_newWidth	oldScale
				------------- X	-------- = newScale
				std_oldWidth	    1

				'std_Width' cancels out 'std_Width', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
				I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
				(which is why I am rewriting it right now)
			]]

			-- Set the scale that we just determined. This is critical because we have to parent:GetEffectiveScale()
			-- in order to determine the proper width, which depends on the current scale of the parent.
			parent:SetScale(newScale)
			TMW.db.global.EditorScale = newScale
			
			
			-- We have all the data needed to find the new position of the parent.
			-- It must be recalculated because otherwise it will scale relative to where it is anchored to,
			-- instead of being relative to the parent's top left corner, which is what it is supposed to be.
			-- I don't remember why this calculation here works, so lets just leave it alone.
			-- Note that it will be re-re-calculated once we are done resizing.
			local newX = self.oldX * self.oldScale / newScale
			local newY = self.oldY * self.oldScale / newScale
			parent:ClearAllPoints()
			parent:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
			
			
			-- Calculate new width
			local std_newFrameHeight = abs(std_cursorY - self.std_oldTop)
			local newHeight = std_newFrameHeight/parent:GetEffectiveScale()
			newHeight = max(400, newHeight)
			newHeight = min(1200, newHeight)
			
			parent:SetHeight(newHeight)
			TMW.db.global.EditorHeight = newHeight
		end,
	}

	self.resizer = TMW.Classes.IconEditor_Resizer_ScaleX_SizeY:New(self)
	self.resizer:Show()
	self.resizer.resizeButton:SetScale(2)
	
	TMW:Fire("TMW_OPTIONS_LOADED")
end

function IE:OnUpdate()
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	local icon = TMW.CI.ic

	if not groupID then
		return
	end

	-- update the top of the icon editor with the information of the current icon.
	-- this is done in an OnUpdate because it is just too hard to track when the texture changes sometimes.
	-- I don't want to fill up the main addon with configuration code to notify the IE of texture changes
	local titlePrepend = L["ICON_TOOLTIP1"] .. " v" .. TELLMEWHEN_VERSION_FULL .. " - "
	
	if IE.CurrentTab:GetID() > #IE.Tabs - 2 then
		-- the last 2 tabs are group config, so dont show icon info
		self.FS1:SetFormattedText(titlePrepend .. L["fGROUP"], TMW:GetGroupName(groupID, groupID, 1))
		self.icontexture:SetTexture(nil)
		self.BackButton:Hide()
		self.ForwardsButton:Hide()
	else
		self.FS1:SetFormattedText(titlePrepend .. L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), iconID)
		if icon then
			self.icontexture:SetTexture(icon.attributes.texture)
		end
		self.BackButton:Show()
		self.ForwardsButton:Show()
	end
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
	IE:AttemptBackup(TMW.CI.ic)
end

function IE:TMW_GLOBAL_UPDATE()
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
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", IE)

IE:RegisterEvent("PLAYER_REGEN_DISABLED", function()
	if not TMW.ALLOW_LOCKDOWN_CONFIG then
		IE:Hide()
		LibStub("AceConfigDialog-3.0"):Close("TMW Options")
	end
end)

function IE:RegisterTab(tab, attachedFrame)
	local id = #IE.Tabs + 1
	
	if id == 1 then
		tab:SetPoint("BOTTOMLEFT", 0, -30)
	else
		tab:SetPoint("LEFT", IE.Tabs[id - 1], "RIGHT", IE.CONST.TAB_OFFS_X, 0)
	end
	IE.Tabs[id] = tab
	tab:SetID(id)
	tab.attachedFrame = attachedFrame
end

---------- Interface ----------
IE.AllDisplayPanels = {}
local panelList = {}

function IE:PositionPanels()
	for _, frame in pairs(IE.AllDisplayPanels) do
		frame:Hide()
	end
	
	wipe(panelList)
	for _, Component in pairs(CI.ic.Components) do
		if Component:ShouldShowConfigPanels(CI.ic) then
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
			
			frame.Background:SetTexture(hue, hue, hue)
			frame.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0.10)
			
			frame:Show()
			
			TMW:Fire("TMW_CONFIG_PANEL_SETUP", frame, panelInfo)
		end	
	end	
	
	local IE_FL = IE:GetFrameLevel()
	for i = 1, #ParentLeft do
		ParentLeft[i]:SetFrameLevel(IE_FL + (#ParentLeft-i+1)*10)
	end
	for i = 1, #ParentRight do
		ParentRight[i]:SetFrameLevel(IE_FL + (#ParentRight-i+1)*10)
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
	if type(icon) == "table" then
		PlaySound("igCharacterInfoTab")
		IE:SaveSettings()
		
		local ic_old = CI.ic
		
		CI.i = icon:GetID()
		CI.g = icon.group:GetID()
		CI.ic = icon

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
		
		if ic_old ~= CI.ic then
			IE.Main.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
			IE.Main.PanelsRight.ScrollFrame:SetVerticalScroll(0)
		end
		
		TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", icon, ic_old)
	end
	if not IE:IsShown() then
		if isRefresh then
			return
		else
			IE:TabClick(IE.MainTab)
		end
	end

	local groupID, iconID = CI.g, CI.i
	if not groupID or not iconID then
		return
	elseif
		not CI.ic.group:IsValid()
		or not CI.ic:IsInRange()
	then
		return IE:LoadFirstValidIcon()
	end

	-- This is really really important. The icon must be setup so that it has the correct components implemented
	-- so that the correct config panels will be loaded and shown for the icon.
	CI.ic:Setup()
	
	IE.ExportBox:SetText("")
	IE:SetScale(TMW.db.global.EditorScale)
	IE:SetHeight(TMW.db.global.EditorHeight)

	CI.ics.Type = CI.ics.Type
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
	
	IE:PositionPanels()
	
	TMW:Fire("TMW_CONFIG_ICON_LOADED", CI.ic)
	
	IE:ScheduleIconSetup()
	
	-- It is intended that this happens at the end instead of the beginning.
	-- Table accesses that trigger metamethods flesh out an icon's settings with new things that aren't there pre-load (usually)
	if icon then
		IE:AttemptBackup(CI.ic)
	end
	IE:UndoRedoChanged()
end

function IE:LoadFirstValidIcon()
	for icon in TMW:InIcons() do
		-- hack to get the first icon that exists and is shown
		if icon:IsVisible() then
			return IE:Load(1, icon)
		end
	end
	
	TMW.IE:Hide()
end
	
function IE:TabClick(self)
	-- invoke blizzard's tab click function to set the apperance of all the tabs
	PanelTemplates_Tab_OnClick(self, self:GetParent())
	PlaySound("igCharacterInfoTab")

	-- hide all tabs' frames, including the current tab so that the OnHide and OnShow scripts fire
	for id, tab in ipairs(IE.Tabs) do
		local frame = tab.attachedFrame
		if TellMeWhen_IconEditor[frame] then
			TellMeWhen_IconEditor[frame]:Hide()
		end
	end

	local oldTab = IE.CurrentTab
	
	-- state the current tab.
	-- this is used in many other places, including inside some OnShow scripts, so it MUST go before the :Show()s below
	IE.CurrentTab = self

	-- show the selected tab's frame
	if TellMeWhen_IconEditor[self.attachedFrame] then
		TellMeWhen_IconEditor[self.attachedFrame]:Show()
	else
		TMW:Error(("Couldn't find child of TellMeWhen_IconEditor with key %q"):format(self.attachedFrame))
	end
	-- show the icon editor
	IE:Show()

	-- special handling for certain tabs.
	if self.OnClick then
		self:OnClick()
	end
	
	TMW:Fire("TMW_CONFIG_TAB_CLICKED", IE.CurrentTab, oldTab)
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

function IE:IsSettingRelevantToIcon(icon, setting)
	if icon.typeData.RelevantSettings[setting] ~= nil then
		return icon.typeData.RelevantSettings[setting]
	end
	for i, Component in ipairs(icon.Components) do
		if Component.IconSettingDefaults[setting] ~= nil then
			return true
		end
	end
end

function IE:Reset()
	local groupID, iconID = CI.g, CI.i
	
	IE:SaveSettings() -- this is here just to clear the focus of editboxes, not to actually save things
	
	TMW.db.profile.Groups[groupID].Icons[iconID] = nil
	
	TMW:Fire("TMW_ICON_SETTINGS_RESET", CI.ic)
	
	CI.ic:Setup()
	
	IE:Load(1)
	
	IE:TabClick(IE.MainTab)
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
			elseif checked then
				CI.ics[self.setting] = self.data.value
			end
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnClick, self, button) 
	end,
	OnCreate = function(self)
		self.text:SetText(self.data.label or self.data.title)
		self:SetMotionScriptsWhileDisabled(true)
	end,
	
	ConstrainLabel = function(self, anchorTo, anchorPoint, ...)
		self.text:SetPoint("RIGHT", anchorTo, anchorPoint or "LEFT", ...)
		
		-- Have to do this or else the text won't multiline/wordwrap when it should.
		-- 30 is just an arbitrarily large number. 
		self.text:SetHeight(30)
		self.text:SetMaxLines(3)
	end,
	
	ReloadSetting = function(self)
		local icon = CI.ic
		
		if icon then
			if self.data.value ~= nil then
				self:SetChecked(icon:GetSettings()[self.setting] == self.data.value)
			else
				self:SetChecked(icon:GetSettings()[self.setting])
			end
			self:CheckInteractionStates()
			self:OnClick("LeftButton")
		end
	end,
}
TMW:NewClass("SettingSlider", "Slider", "SettingFrameBase"){
	-- This class sucks. I didn't even finish writing it. If you need it for something, write it youself. Sorry.
	-- TODO: maybe finish writing this?
	
	OnValueChanged = function(self, value)
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
		local icon = CI.ic
		
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
			local icon = CI.ic
			
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
		local icon = CI.ic
		
		if icon and not self.fakeNextSetValue then
			CI.ics[self.setting] = value / 100
			IE:ScheduleIconSetup()
		end
		
		self:UpdateValueText()
	end,
	
	ReloadSetting = function(self)
		local icon = CI.ic
		
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
		local icon = CI.ic
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
		local runeType = gsub(self:GetName(), self:GetParent():GetName(), "")
		runeType = gsub(runeType, "%d", "")
		self.texture:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-" .. runeType)
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
		TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self.ClearFocus, self)
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
	
	ReloadSetting = function(self)
		local icon = CI.ic
		if icon then
			if self.setting then
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
	TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", "ReloadSetting", frame)
	TMW:RegisterCallback("TMW_CONFIG_ICON_HISTORY_STATE_CREATED", "ReloadSetting", frame)
	TMW:RegisterCallback("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", "ReloadSetting", frame)

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
	if equivTipCache[equiv] then return equivTipCache[equiv] end
	local r = "" --tconcat doesnt allow me to exclude duplicates unless i make another garbage table, so lets just do this
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
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple ranks.
			r = r .. "|T" .. texture .. ":0|t" .. name .. "\r\n"
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	r = strtrim(r, "\r\n ;")
	equivTipCache[equiv] = r
	return r
end

--[=[
local function equivSorter(a, b)
	if a == "IncreasedSPsix" and b == "IncreasedSPten" then
		return true
	elseif b == "IncreasedSPsix" and a == "IncreasedSPten" then
		return false
	else
		return L[a] < L[b]
	end
end
function IE:Equiv_DropDown()
	if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
		if TMW.BE[UIDROPDOWNMENU_MENU_VALUE] then
			for k, v in TMW:OrderedPairs(TMW.BE[UIDROPDOWNMENU_MENU_VALUE], equivSorter) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = IE.Equiv_DropDown_OnClick
				info.text = L[k]
				local text = IE:Equiv_GenerateTips(k)

				info.icon = TMW.SpellTextures[TMW.EquivFirstIDLookup[k]]
				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93

				info.tooltipTitle = k
				info.tooltipText = text
				info.tooltipOnButton = true
				info.value = k
				info.arg1 = k
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, 2)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == "dispel" then
			for k, v in TMW:OrderedPairs(TMW.DS) do
				local v = TMW.DS[k]
				local info = UIDropDownMenu_CreateInfo()
				info.func = IE.Equiv_DropDown_OnClick
				info.text = L[k]

				local first = strsplit(TMW.EquivFirstIDLookup[k], ";")
				info.icon = v
				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93

				info.value = k
				info.arg1 = k
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, 2)
			end
		end
		return
	end

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_BUFF"]
	info.value = "buffs"
	info.hasArrow = true
	info.colorCode = "|cFF00FF00"
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	--some stuff is reused for this one
	info.text = L["ICONMENU_DEBUFF"]
	info.value = "debuffs"
	info.colorCode = "|cFFFF0000"
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_CASTS"]
	info.value = "casts"
	info.colorCode = nil
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_DRS"]
	info.value = "dr"
	info.colorCode = nil
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_DISPEL"]
	info.value = "dispel"
	UIDropDownMenu_AddButton(info)
end

function IE:Equiv_DropDown_OnClick(value)
	error("Sorry, but this dropdown is currently defunct. Please use the suggetion list or type things in manually") --TODO: remove this ( the dropdown) probably
	-- TODO: tie this closer to the choosename panel
	local e = IE.Panels.Name
	e:Insert("; " .. value .. "; ")
	local new = TMW:CleanString(e)
	e:SetText(new)
	local _, position = strfind(new, gsub(value, "([%-])", "%%%1"))
	position = tonumber(position) + 2

	-- WARNING: lame coding from here to the end of this function.
	e:SetFocus()
	e:ClearFocus()
	e:SetFocus()
	e:HighlightText(0, 0)
	e:SetCursorPosition(position)
	CloseDropDownMenus()
end
]=]

---------- Dropdowns ----------
function IE:Type_DropDown()
	if not TMW.db then return end
	local groupID, iconID = CI.g, CI.i

	for _, Type in ipairs(TMW.OrderedTypes) do -- order in the order in which they are loaded in the .toc file
		local tempshow = CI.ics.Type == Type.type and Type.hidden
		if tempshow or not Type.hidden then
			if Type.spacebefore then
				TMW.AddDropdownSpacer()
			end

			local info = UIDropDownMenu_CreateInfo()
			info.text = Type.name
			info.value = Type.type
			if Type.desc then
				info.tooltipTitle = Type.tooltipTitle or Type.name
				info.tooltipText = Type.desc
				info.tooltipOnButton = true
			end
			info.checked = (info.value == TMW.db.profile.Groups[groupID].Icons[iconID].Type)
			info.func = IE.Type_Dropdown_OnClick
			info.arg1 = Type
			info.disabled = tempshow
			info.tooltipWhileDisabled = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			if Type.spaceafter then
				TMW.AddDropdownSpacer()
			end
		end
	end
end

function IE:Type_Dropdown_OnClick()
	CI.ics.Type = self.value
	CI.ic:SetInfo("texture", nil)

	CI.ics.Type = self.value
	
	CI.ic:Setup()
	
	IE:Load(1)
end


---------- Tooltips ----------
local cachednames = {}
function IE:GetRealNames(Name) -- TODO: MODULARIZE THIS
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(Name)
	
	local SoI = CI.ics.Type == "item" and "item" or "spell"
	
	if cachednames[CI.ics.Type .. SoI .. text] then return cachednames[CI.ics.Type .. SoI .. text] end

	local tbl
	local GetSpellInfo = GetSpellInfo
	if SoI == "item" then
		tbl = TMW:GetItemIDs(nil, text)
	else
		tbl = TMW:GetSpellNames(nil, text)
	end
	local durations = Types[CI.ics.Type].DurationSyntax and TMW:GetSpellDurations(nil, text)

	local str = ""
	local numadded = 0
	local numlines = 50
	local numperline = ceil(#tbl/numlines)

	local Cache = TMW:GetModule("SpellCache"):GetCache()
	
	for k, v in pairs(tbl) do
		local name, texture
		if SoI == "item" then
			name = GetItemInfo(v) or v or ""
			texture = GetItemIcon(v)
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
	cachednames[CI.ics.Type .. SoI .. text] = str
	return str
end


---------- Icon Update Scheduler ----------
function IE:ScheduleIconSetup(groupID, iconID)
	-- this is a handler to prevent the spamming of icon:Setup() and creating excessive garbage.
	local icon
	if type(groupID) == "table" then --allow omission of icon
		icon = groupID
	else
		icon = TMW[groupID] and TMW[groupID][iconID]
	end
	if not icon then
		icon = CI.ic
	end
	if not TMW.tContains(IE.iconsToUpdate, icon) then
		tinsert(IE.iconsToUpdate, icon)
	end
end




-- -----------------------
-- IMPORT/EXPORT
-- -----------------------

---------- High-level Functions ----------
function TMW:Import(editbox, settings, version, type, ...)
	assert(settings, "Missing settings to import")
	assert(version, "Missing version of settings")
	assert(type, "No settings type specified!")
	CloseDropDownMenus()

	TMW:Fire("TMW_IMPORT_PRE", editbox, settings, version, type, ...)
	
	local SharableDataType = TMW.approachTable(TMW, "Classes", "SharableDataType", "types", type)
	if SharableDataType and SharableDataType.Import_ImportData then
		SharableDataType:Import_ImportData(editbox, settings, version, ...)

		TMW:Update()
		IE:Load(1)
		
		TMW:Print(L["IMPORT_SUCCESSFUL"])
	else
		TMW:Print(L["IMPORTERROR_INVALIDTYPE"])
	end

	TMW:Fire("TMW_IMPORT_POST", editbox, settings, version, type, ...)
	
	--TMW:ScheduleTimer("CompileOptions", 0.2) -- i dont know why i have to delay it, but I do.
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
	gsub("(^[^tT%d][^^]*^[^^]*)", "%1 "): -- add spaces to clean it up a little
	gsub("%^ ^", "^^") -- remove double space at the end
end

function TMW:DeserializeData(string)
	local success, data, version, spaceControl, type = TMW:Deserialize(string)
	
	if not success then
		-- corrupt/incomplete string
		return nil
	end

	if spaceControl then
		if spaceControl:find("`|") then
			-- EVERYTHING is fucked up. try really hard to salvage it. It probably won't be completely successful
			return TMW:DeserializeData(string:gsub("`", "~`"):gsub("~`|", "~`~|"))
		elseif spaceControl:find("`") then
			-- if spaces have become corrupt, then reformat them and... re-deserialize (lol)
			return TMW:DeserializeData(string:gsub("`", "~`"))
		elseif spaceControl:find("~|") then
			-- if pipe characters have been screwed up by blizzard's cute little method of escaping things combined with AS-3.0's cute way of escaping things, try to fix them.
			return TMW:DeserializeData(string:gsub("~||", "~|"))
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


---------- Settings Manipulation ----------
function TMW:GetSettingsString(type, settings, defaults, ...)
	assert(settings, "No data to serialize!")
	assert(type, "No data type specified!")
	assert(defaults, "No defaults specified!")

	-- ... contains additional data that may or may not be used/needed
	IE:SaveSettings()
	settings = CopyTable(settings)
	settings = TMW:CleanSettings(type, settings, defaults)
	return TMW:SerializeData(settings, type, ...)
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
	local DatabaseCleanup = TMW.DatabaseCleanups[type]
	if DatabaseCleanup then
		DatabaseCleanup(settings)
	end
	return TMW:CleanDefaults(settings, defaults)
end


---------- Dropdown ----------


TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox == TMW.IE.ExportBox then		
		import.group_overwrite = CI.g
		export.group = CI.g
		
		if IE.CurrentTab:GetID() <= 4 then
			import.icon = CI.i
			export.icon = CI.i
		end
	end
end)

TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox.IsImportExportWidget then
		local info = editbox.obj.userdata
		
		import.group_overwrite = findid(info)
		export.group = findid(info)
	end
end)


-- ----------------------
-- UNDO/REDO
-- ----------------------


---------- Comparison ----------
function IE:DeepCompare(t1, t2, ...)
	-- heavily modified version of http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3

	-- attempt direct comparison
	if t1 == t2 then
		return true, ...
	end

	-- if the values are not the same (they made it through the check above) AND they are not both tables, then they cannot be the same, so exit.
	local ty1 = type(t1)
	if ty1 ~= "table" or ty1 ~= type(t2) then
		return false, ...
	end

	-- compare table values

	-- compare table 1 with table 2
	for k1, v1 in pairs(t1) do
		local v2 = t2[k1]

		-- don't bother calling DeepCompare on the values if they are the same - it will just return true.
		-- Only call it if the values are different (they are either 2 tables, or they actually are different non-table values)
		-- by adding the (v1 ~= v2) check, efficiency is increased by about 300%.
		if v1 ~= v2 and not IE:DeepCompare(v1, v2, k1, ...) then

			-- it only reaches this point if there is a difference between the 2 tables somewhere
			-- so i dont feel bad about calling DeepCompare with the same args again
			-- i need to because the key of the setting that changed is in there, and AttemptBackup needs that key
			return IE:DeepCompare(v1, v2, k1, ...)
		end
	end

	-- compare table 2 with table 1
	for k2, v2 in pairs(t2) do
		local v1 = t1[k2]

		-- see comments for t1
		if v1 ~= v2 and not IE:DeepCompare(v1, v2, k2, ...) then
			return IE:DeepCompare(v1, v2, k2, ...)
		end
	end

	return true, ...
end

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
		-- the needed stuff for undo and redu already exists, so lets delve into the meat of the process.

		-- compare the current icon settings with what we have in the currently used history point
		-- the currently used history point may or may not be the most recent settings of the icon, but we want to check ics against what is being used.
		-- result is either (true) if there were no changes in the settings, or a string representing the key path to the first setting change that was detected.
		--(it was likely only one setting that changed, but not always)
		local result, changedSetting = IE:GetCompareResultsPath(IE:DeepCompare(icon.history[icon.historyState], icon:GetSettings()))
		if type(result) == "string" then
			-- if we are using an old history point (i.e. we hit undo a few times and then made a change),
			-- delete all history points from the current one forward so that we dont jump around wildly when undoing and redoing
			for i = icon.historyState + 1, #icon.history do
				icon.history[i] = nil
			end

			-- if the last setting that was changed is the same as the most recent setting that was changed,
			-- and if the setting is one that can be changed very rapidly,
			-- delete the previous history point so that we dont murder our memory usage and piss off the user as they undo a number from 1 to 10, 0.1 per click.
			if icon.lastChangePath == result and TMW.RapidSettings[changedSetting] then
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
	local icon = CI.ic
	
	IE:UndoRedoChanged()

	if not icon.history[icon.historyState + direction] then return end -- not valid, so don't try

	icon.historyState = icon.historyState + direction

	TMW.db.profile.Groups[CI.g].Icons[CI.i] = nil -- recreated when passed into CTIPWM
	TMW:CopyTableInPlaceWithMeta(icon.history[icon.historyState], TMW.db.profile.Groups[CI.g].Icons[CI.i])
	
	CI.ic:Setup() -- do an immediate setup for good measure
	
	TMW:Fire("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", icon)

	CloseDropDownMenus()
	IE:Load(1)
	
	IE:UndoRedoChanged()
end


---------- Interface ----------
function IE:UndoRedoChanged()
	local icon = CI.ic
	
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



-- ----------------------
-- EVENTS
-- ----------------------

local EVENTS = TMW.EVENTS

function EVENTS:SetupEventSettings()
	local EventSettings = self.EventSettings

	if not EVENTS.currentEventID then return end

	local eventData = self.EventList[EVENTS.currentEventID].eventData

	self.EventSettingsEventName:SetText("(" .. EVENTS.currentEventID .. ") " .. eventData.text)

	local Settings = self:GetEventSettings()
	local settingsUsedByEvent = eventData.settings
	
	TMW:Fire("TMW_CONFIG_EVENTS_SETTINGS_SETUP_PRE")

	--hide settings
	EventSettings.Operator	 	 		:Hide()
	EventSettings.Value		 	 		:Hide()
	EventSettings.CndtJustPassed 		:Hide()
	EventSettings.PassingCndt	 		:Hide()
	EventSettings.Icon			 		:Hide()

	--set settings
	EventSettings.PassThrough	 :SetChecked(Settings.PassThrough)
	EventSettings.OnlyShown	 	 :SetChecked(Settings.OnlyShown)
	EventSettings.CndtJustPassed :SetChecked(Settings.CndtJustPassed)
	EventSettings.PassingCndt	 :SetChecked(Settings.PassingCndt)
	EventSettings.Value		 	 :SetText(Settings.Value)

	TMW:SetUIDropdownText(EventSettings.Icon, Settings.Icon, TMW.InIcons, L["CHOOSEICON"])
	EventSettings.Icon.IconPreview:SetIcon(_G[Settings.Icon])

	--show settings
	for setting, frame in pairs(EventSettings) do
		if type(frame) == "table" then
			local state = settingsUsedByEvent and settingsUsedByEvent[setting]

			if state == "FORCE" then
				frame:Disable()
				frame:SetAlpha(1)
			elseif state == "FORCEDISABLED" then
				frame:Disable()
				frame:SetAlpha(0.4)
			else
				frame:SetAlpha(1)
				if frame.Enable then
					frame:Enable()
				end
			end
			if state then
				frame:Show()
			end
		end
	end

	if EventSettings.PassingCndt				:GetChecked() then
		EventSettings.Operator.ValueLabel		:SetFontObject(GameFontHighlight)
		EventSettings.Operator					:Enable()
		EventSettings.Value						:Enable()
		if settingsUsedByEvent and not settingsUsedByEvent.CndtJustPassed == "FORCE" then
			EventSettings.CndtJustPassed		:Enable()
		end
	else
		EventSettings.Operator.ValueLabel		:SetFontObject(GameFontDisable)
		EventSettings.Operator					:Disable()
		EventSettings.Value						:Disable()
		EventSettings.CndtJustPassed			:Disable()
	end

	EventSettings.Operator.ValueLabel:SetText(eventData.valueName)
	EventSettings.Value.ValueLabel:SetText(eventData.valueSuffix)

	local v = TMW:SetUIDropdownText(EventSettings.Operator, Settings.Operator, operators)
	if v then
		TMW:TT(EventSettings.Operator, v.tooltipText, nil, 1)
	end
	
	TMW:Fire("TMW_CONFIG_EVENTS_SETTINGS_SETUP_POST")
end

function EVENTS:OperatorMenu_DropDown()
	-- self is not Module
	local Module = TMW.EVENTS.currentEventHandler
	local eventData = Module.EventList[EVENTS.currentEventID].eventData

	for k, v in pairs(operators) do
		if not eventData.blacklistedOperators or not eventData.blacklistedOperators[v.value] then
			local info = UIDropDownMenu_CreateInfo()
			info.func = EVENTS.OperatorMenu_DropDown_OnClick
			info.text = v.text
			info.value = v.value
			info.tooltipTitle = v.tooltipText
			info.tooltipOnButton = true
			info.arg1 = self
			UIDropDownMenu_AddButton(info)
		end
	end
end
function EVENTS:OperatorMenu_DropDown_OnClick(frame)
	local dropdown = self
	local self = TMW.EVENTS.currentEventHandler

	TMW:SetUIDropdownText(frame, dropdown.value)

	self:GetEventSettings().Operator = dropdown.value
	TMW:TT(frame, dropdown.tooltipTitle, nil, 1)
end

function EVENTS:IconMenu_DropDown()
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for icon, groupID, iconID in TMW:InIcons() do
			if icon:IsValid() and UIDROPDOWNMENU_MENU_VALUE == groupID and CI.ic ~= icon then
				local info = UIDropDownMenu_CreateInfo()

				local text, textshort, tooltip = TMW:GetIconMenuText(groupID, iconID)
				if text:sub(-2) == "))" then
					textshort = textshort .. " " .. L["fICON"]:format(iconID)
				end
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), iconID) .. "\r\n" .. tooltip
				info.tooltipOnButton = true

				info.value = icon:GetName()
				info.arg1 = self
				info.func = EVENTS.IconMenu_DropDown_OnClick

				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				info.icon = icon.attributes.texture

				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then
		for group, groupID in TMW:InGroups() do
			if group:ShouldUpdateIcons() then
				local info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(groupID, groupID)
				info.hasArrow = true
				info.notCheckable = true
				info.value = groupID
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end
function EVENTS:IconMenu_DropDown_OnClick(frame)
	local dropdown = self
	local self = TMW.EVENTS.currentEventHandler

	TMW:SetUIDropdownText(frame, dropdown.value, TMW.InIcons)
	CloseDropDownMenus()

	frame.IconPreview:SetIcon(_G[dropdown.value])

	self:GetEventSettings().Icon = dropdown.value
end

function EVENTS:AddEvent_Dropdown()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		EVENTS:BuildListOfValidEvents()
		
		for _, eventData in ipairs(EVENTS.ValidEvents) do
			local info = UIDropDownMenu_CreateInfo()

			info.text = get(eventData.text)
			info.tooltipTitle = get(eventData.text)
			info.tooltipText = get(eventData.desc)
			
			info.tooltipOnButton = true

			info.value = eventData.event
			info.hasArrow = true
			info.notCheckable = true
			info.keepShownOnClick = true

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for i, EventHandler in ipairs(EVENTS.instances) do
			local info = UIDropDownMenu_CreateInfo()

			info.text = EventHandler.tabText
		--[[	info.tooltipTitle = get(eventData.text)
			info.tooltipText = get(eventData.desc)
			info.tooltipOnButton = true]]

			info.value = EventHandler.eventHandlerName
			info.hasAlpha = true
			info.func = EVENTS.AddEvent_Dropdown_OnClick
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = EventHandler.eventHandlerName
			info.notCheckable = true

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end
function EVENTS:AddEvent_Dropdown_OnClick(event, type)
	CI.ics.Events.n = CI.ics.Events.n + 1

	local n = CI.ics.Events.n
	local EventSettings = CI.ics.Events[n]

	EventSettings.Event = event
	EventSettings.Type = type

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(EventSettings)
	end

	EVENTS:LoadConfig()

	local Module = EVENTS:GetEventHandlerForEventSettings(n)
	if Module then
		Module:LoadSettingsForEventID(n)
	end

	CloseDropDownMenus()
end

function EVENTS:ChangeEvent_Dropdown()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		EVENTS:BuildListOfValidEvents()
		
		local eventButton = self:GetParent()
		
		for _, eventData in ipairs(EVENTS.ValidEvents) do
			local info = UIDropDownMenu_CreateInfo()

			info.text = get(eventData.text)
			info.tooltipTitle = get(eventData.text)
			info.tooltipText = get(eventData.desc)
			
			info.tooltipOnButton = true

			info.value = eventData.event
			info.checked = eventData.event == eventButton.event
			info.func = EVENTS.ChangeEvent_Dropdown_OnClick
			info.keepShownOnClick = false
			info.arg1 = eventButton
			info.arg2 = eventData.event

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end
function EVENTS:ChangeEvent_Dropdown_OnClick(eventButton, event)
	local n = eventButton:GetID()
	local EventSettings = CI.ics.Events[n]

	EventSettings.Event = event

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(EventSettings)
	end

	EVENTS:LoadConfig()

	CloseDropDownMenus()
end

function EVENTS:CreateEventButtons(globalDescKey)
	local EventList = self.EventList
	local previousFrame

	local yAdjustTitle, yAdjustText = 0, 0
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		yAdjustTitle, yAdjustText = 3, -3
	end
	local Settings = self:GetEventSettings()

	for i, eventSettings in TMW:InNLengthTable(CI.ics.Events) do
		local eventData = TMW.EventList[eventSettings.Event]
		local frame = EventList[i]
		if not frame then
			frame = CreateFrame("Button", EventList:GetName().."Event"..i, EventList, "TellMeWhen_Event", i)
			EventList[i] = frame
			frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT")
			frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")

			local p, t, r, x, y = frame.EventName:GetPoint(1)
			frame.EventName:SetPoint(p, t, r, x, y + yAdjustTitle)
			local p, t, r, x, y = frame.EventName:GetPoint(2)
			frame.EventName:SetPoint(p, t, r, x, y + yAdjustTitle)
			local p, t, r, x, y = frame.DataText:GetPoint(1)
			frame.DataText:SetPoint(p, t, r, x, y + yAdjustText)
			local p, t, r, x, y = frame.DataText:GetPoint(2)
			frame.DataText:SetPoint(p, t, r, x, y + yAdjustText)
		end

		if eventData then
			frame:Show()

			frame.event = eventData.event
			frame.eventData = eventData

			frame.EventName:SetText(i .. ") " .. eventData.text)

			frame.normalDesc = eventData.desc .. "\r\n\r\n" .. L["EVENTS_HANDLERS_GLOBAL_DESC"]
			TMW:TT(frame, eventData.text, frame.normalDesc, 1, 1)
		else
			frame.EventName:SetText(i .. ") UNKNOWN EVENT: " .. tostring(eventSettings.Event))
			frame:Disable()

		end
		previousFrame = frame
	end

	for i = max(CI.ics.Events.n + 1, 1), #EventList do
		EventList[i]:Hide()
	end

	if EventList[1] then
		EventList[1]:SetPoint("TOPLEFT", EventList, "TOPLEFT", 0, 0)
		EventList[1]:SetPoint("TOPRIGHT", EventList, "TOPRIGHT", 0, 0)
	end

	EventList:SetHeight(max(CI.ics.Events.n*(EventList[1] and EventList[1]:GetHeight() or 0), 1))
end

function EVENTS:EnableAndDisableEvents()
	local oldID = EVENTS.currentEventID

	self:BuildListOfValidEvents()
	
	for i, frame in ipairs(self.EventList) do
		if frame:IsShown() then
			if self.ValidEvents[frame.event] then
				TMW:TT(frame, frame.eventData.text, frame.normalDesc, 1, 1)
				frame:Enable()
				local Module = EVENTS:GetEventHandlerForEventSettings(i)
				if Module then
					Module:SetupEventDisplay(i)
				else
					frame.DataText:SetText("UNKNOWN TYPE: " .. tostring(EVENTS:GetEventSettings(i).Type))
				end
			else
				frame:Disable()
				frame.DataText:SetText(L["SOUND_EVENT_DISABLEDFORTYPE"])
				TMW:TT(frame, frame.eventData.text, L["SOUND_EVENT_DISABLEDFORTYPE_DESC2"]:format(Types[CI.ics.Type].name), 1, 1)

				if oldID == i then
					oldID = oldID + 1
				end
			end
		end
	end

	return oldID
end

function EVENTS:GetEventHandlerForEventSettings(arg1)
	local eventSettings
	if type(arg1) == "table" then
		eventSettings = arg1
	else
		eventSettings = EVENTS:GetEventSettings(arg1)
	end

	if eventSettings then
		return TMW:GetEventHandler(eventSettings.Type, true)
	end
end

function EVENTS:ChooseEvent(id)
	local eventFrame = self.EventList[id]

	EVENTS.currentEventID = id ~= 0 and id or nil

	for _, EventHandler in ipairs(EVENTS.instances) do
		EventHandler.ConfigContainer:Hide()
	end
	local EventHandler = self:GetEventHandlerForEventSettings()
	if EventHandler then
		EventHandler.ConfigContainer:Show()
		EVENTS.currentEventHandler = EventHandler
	end

	if not eventFrame or id == 0 or not eventFrame:IsShown() then
		return
	end

	for i, frame in ipairs(self.EventList) do
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end
	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)

	IE.Events.ScrollFrame.adjustmentQueued = true
	
	return eventFrame
end

function EVENTS:AdjustScrollFrame()
	local ScrollFrame = IE.Events.ScrollFrame
	local eventFrame = self.EventList[self.currentEventID]

	if not eventFrame then return end

	if eventFrame:GetBottom() and eventFrame:GetBottom() < ScrollFrame:GetBottom() then
		ScrollFrame.ScrollBar:SetValue(ScrollFrame.ScrollBar:GetValue() + (ScrollFrame:GetBottom() - eventFrame:GetBottom()))
	elseif eventFrame:GetTop() and eventFrame:GetTop() > ScrollFrame:GetTop() then
		ScrollFrame.ScrollBar:SetValue(ScrollFrame.ScrollBar:GetValue() - (eventFrame:GetTop() - ScrollFrame:GetTop()))
	end
end

function EVENTS:GetNumUsedEvents()
	local n = 0
	for i = 1, #self.EventList do
		local f = self.EventList[i]
		local Module = EVENTS:GetEventHandlerForEventSettings(i)
		if Module then
			local has = Module:ProcessIconEventSettings(f.event, self:GetEventSettings(i))
			if has then
				n = n + 1
			end
		end
	end

	return n
end

function EVENTS:LoadConfig()
	self:CreateEventButtons()

	local oldID = self:EnableAndDisableEvents()

	if oldID and oldID > 0 then
		if CI.ics.Events.n ~= 0 then
			-- make sure we dont get any NaN...
			-- apparently blizzard decided to allow division by zero again,
			-- but sometimes, you cant set an index of NaN (1%0) on a table in some clients.
			-- I can in mine, so idk what the fuck is going on
			-- t = ({[5%0] = 1})[400]	yields 1 (at any index, not just 400... what the hell?
			-- See ticket 444 - lsjyzjl is getting "table index is NaN" from AceDB
			oldID = oldID % CI.ics.Events.n
		else
			oldID = 0
		end
		if oldID == 0 then
			oldID = CI.ics.Events.n
		end
	else
		oldID = 1
	end

	if CI.ics.Events.n <= 0 then
		self.EventSettings:Hide()
	else
		self.EventSettings:Show()
	end

	for _, EventHandler in ipairs(EVENTS.instances) do
		EventHandler.ConfigContainer:Hide()
	end
	local EventHandler = self:GetEventHandlerForEventSettings(oldID)
	if EventHandler then
		EventHandler:LoadSettingsForEventID(oldID)
	end

	--[[if IE.Events.ScrollFrame:GetVerticalScrollRange() == 0 then
		IE.Events.ScrollFrame.ScrollBar:Hide()
	end]]

	self:SetTabText()
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", "LoadConfig", EVENTS)

function EVENTS:SetTabText()
	local n = self:GetNumUsedEvents()

	if n > 0 then
		IE.EventsTab:SetText(L["EVENTS_TAB"] .. " |cFFFF5959(" .. n .. ")")
	else
		IE.EventsTab:SetText(L["EVENTS_TAB"] .. " (" .. n .. ")")
	end
	PanelTemplates_TabResize(IE.EventsTab, -6)
end

function EVENTS:GetEventSettings(eventID)

	return CI.ics.Events[eventID or EVENTS.currentEventID]
end

function EVENTS:TestEvent(eventID)
	local eventSettings = self:GetEventSettings(eventID)

	self:HandleEvent(CI.ic, eventSettings)
end

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	EVENTS.EventList = IE.Events.EventList
	EVENTS.EventSettings = IE.Events.EventSettings
end)

function EVENTS:BuildListOfValidEvents()
	self.ValidEvents = wipe(self.ValidEvents or {})
	
	for _, Component in ipairs(CI.ic.Components) do
		for _, eventData in ipairs(Component.IconEvents) do
			-- Put it in the table as an indexed field.
			self.ValidEvents[#self.ValidEvents+1] = eventData
			
			-- Put it in the table keyed by the event, for lookups.
			self.ValidEvents[eventData.event] = eventData
		end
	end
	
	TMW:SortOrderedTables(self.ValidEvents)
end

function EVENTS:UpOrDown(button, delta)
	local ID = button:GetID()
	local settings = CI.ics.Events

	local curdata = settings[ID]
	local destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata

	EVENTS:LoadConfig()
end




