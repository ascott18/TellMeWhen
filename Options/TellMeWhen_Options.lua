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
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, coroutine, pcall, assert, rawget, rawset, unpack, select =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, coroutine, pcall, assert, rawget, rawset, unpack, select
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
local IE, SUG, ID, HELP, EVENTS, TEXT


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
local stratas = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	"TOOLTIP",
}
local strataDisplay = {}
for k, v in pairs(stratas) do
	strataDisplay[k] = L["STRATA_"..v]
end
local operators = {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}

local EquivFullIDLookup = {}
local EquivFullNameLookup = {}
local EquivFirstIDLookup = {}
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do

		-- create the lookup tables first, so that we can have the first ID even if it will be turned into a name
		EquivFirstIDLookup[equiv] = strsplit(";", str) -- this is used to display them in the list (tooltip, name, id display)

		EquivFullIDLookup[equiv] = ";" .. str
		local tbl = TMW:SplitNames(str)
		for k, v in pairs(tbl) do
			tbl[k] = GetSpellInfo(v) or v
		end
		EquivFullNameLookup[equiv] = ";" .. table.concat(tbl, ";")
	end
end
for dispeltype, icon in pairs(TMW.DS) do
	EquivFirstIDLookup[dispeltype] = icon
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
	elseif k == "SoI" then -- spell or item (antiquated, but not yet deprecated).. TODO: deprecate this
		local ics = tbl.ics
		if ics and ics.Type == "item" then
			return "item"
		end
		return "spell"
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

-- TODO: modularize this (to icon types)
function TMW:GuessIconTexture(ics)
	local tex

	if ics.CustomTex then
		tex = TMW:GetTexturePathFromSetting(ics.CustomTex)
	end

	if (ics.Name and ics.Name ~= "" and ics.Type ~= "meta" and ics.Type ~= "wpnenchant" and ics.Type ~= "runes") and not tex then
		local name = TMW:GetSpellNames(nil, ics.Name, 1)
		if name then
			if ics.Type == "item" then
				tex = GetItemIcon(name) or tex
			else
				tex = SpellTextures[name]
			end
		end
	end
	if ics.Type == "cast" and not tex then tex = "Interface\\Icons\\Temp"
	elseif ics.Type == "buff" and not tex then tex = "Interface\\Icons\\INV_Misc_PocketWatch_01"
	elseif ics.Type == "meta" and not tex then tex = "Interface\\Icons\\LevelUpIcon-LFD"
	elseif ics.Type == "runes" and not tex then tex = "Interface\\Icons\\Spell_Deathknight_BloodPresence"
	elseif ics.Type == "wpnenchant" and not tex then tex = GetInventoryItemTexture("player", GetInventorySlotInfo(ics.WpnEnchantType or "MainHandSlot")) or GetInventoryItemTexture("player", "MainHandSlot") end
	if not tex then tex = "Interface\\Icons\\INV_Misc_QuestionMark" end
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
					UIDropDownMenu_SetText(frame, TMW:GetIconMenuText(tonumber(g), tonumber(i), icon))
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
				--[==[Type = {
					name = L["UIPANEL_GROUPTYPE"],
					desc = L["UIPANEL_GROUPTYPE_DESC"],
					type = "group",
					dialogInline = true,
					guiInline = true,
					order = 23,
					get = function(info)
						local g = findid(info)
						return TMW.db.profile.Groups[g][info[#info-1]] == info[#info]
					end,
					set = function(info)
						local g = findid(info)
						TMW.db.profile.Groups[g][info[#info-1]] = info[#info]
						TMW[g]:Setup()
					end,
					args = {
						icon = {
							name = L["UIPANEL_GROUPTYPE_ICON"],
							desc = L["UIPANEL_GROUPTYPE_ICON_DESC"],
							type = "toggle",
							order = 1,
						},
						bar = {
							name = L["UIPANEL_GROUPTYPE_BAR"],
							desc = L["UIPANEL_GROUPTYPE_BAR_DESC"],
							type = "toggle",
							order = 2,
						},
					}
				},]==]
				
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
		position = {
			type = "group",
			order = 20,
			name = L["UIPANEL_POSITION"],
			desc = L["UIPANEL_POSITION_DESC"],
			set = function(info, val)
				local g = findid(info)
				TMW.db.profile.Groups[g].Point[info[#info]] = val
				TMW[g]:SetPos()
			end,
			get = function(info)
				return TMW.db.profile.Groups[findid(info)].Point[info[#info]]
			end,
			args = {
				point = {
					name = L["UIPANEL_POINT"],
					desc = L["UIPANEL_POINT_DESC"],
					type = "select",
					values = points,
					style = "dropdown",
					order = 1,
				},
				relativeTo = {
					name = L["UIPANEL_RELATIVETO"],
					desc = L["UIPANEL_RELATIVETO_DESC"],
					type = "input",
					order = 2,
				},
				relativePoint = {
					name = L["UIPANEL_RELATIVEPOINT"],
					desc = L["UIPANEL_RELATIVEPOINT_DESC"],
					type = "select",
					values = points,
					style = "dropdown",
					order = 3,
				},
				x = {
					name = L["UIPANEL_FONT_XOFFS"],
					desc = L["UIPANEL_FONT_XOFFS_DESC"],
					type = "range",
					order = 4,
					softMin = -500,
					softMax = 500,
					step = 1,
					bigStep = 1,
				},
				y = {
					name = L["UIPANEL_FONT_YOFFS"],
					desc = L["UIPANEL_FONT_YOFFS_DESC"],
					type = "range",
					order = 5,
					softMin = -500,
					softMax = 500,
					step = 1,
					bigStep = 1,
				},
				scale = {
					name = L["UIPANEL_SCALE"],
					type = "range",
					order = 6,
					min = 0.6,
					softMax = 10,
					bigStep = 0.01,
					set = function(info, val)
						local g = findid(info)
						TMW.db.profile.Groups[g].Scale = val
						TMW[g]:SetPos()
					end,
					get = function(info) return TMW.db.profile.Groups[findid(info)].Scale end,
				},
				Level = {
					name = L["UIPANEL_LEVEL"],
					type = "range",
					order = 7,
					min = 1,
					softMax = 100,
					step = 1,
					set = function(info, val)
						local g = findid(info)
						TMW.db.profile.Groups[g].Level = val
						TMW[g]:SetPos()
					end,
					get = function(info) return TMW.db.profile.Groups[findid(info)].Level end,
				},
				Strata = {
					name = L["UIPANEL_STRATA"],
					type = "select",
					style = "dropdown",
					order = 8,
					set = function(info, val)
						local g = findid(info)
						TMW.db.profile.Groups[g].Strata = stratas[val]
						TMW[g]:SetPos()
					end,
					get = function(info)
						local val = TMW.db.profile.Groups[findid(info)].Strata
						for k, v in pairs(stratas) do
							if v == val then
								return k
							end
						end
					end,
					values = strataDisplay,
				},
				lock = {
					name = L["UIPANEL_LOCK"],
					desc = L["UIPANEL_LOCK_DESC"],
					type = "toggle",
					order = 40,
					set = function(info, val)
						local g = findid(info)
						TMW.db.profile.Groups[g].Locked = val
						TMW[g]:Setup()
					end,
					get = function(info) return TMW.db.profile.Groups[findid(info)].Locked end
				},
				reset = {
					name = L["UIPANEL_GROUPRESET"],
					desc = L["UIPANEL_TOOLTIP_GROUPRESET"],
					type = "execute",
					order = 50,
					func = function(info) TMW:Group_ResetPosition(findid(info)) end
				},
			},
		},
	}
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
				local WhenChecks = TMW.Types[info[#info-2]].WhenChecks
				local fmt = WhenChecks and WhenChecks.text or L["ICONMENU_SHOWWHEN"]

				return L["COLOR_" .. info[#info-1] .. "_DESC"]:format(fmt)
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
					t = L["COLOR_HEADER"]:format(TMW.Types[this].name)
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
	}
}

for k, v in pairs(colorOrder) do
	colorIconTypeTemplate.args[v] = colorTemplate
end
if TMW.ISMOP then
	for i = 1, GetNumSpecializations() do
		local _, name = GetSpecializationInfo(i)
		TMW.GroupConfigTemplate.args.main.args["Tree"..i] = {
			type = "toggle",
			name = name,
			desc = L["UIPANEL_TREE_DESC"],
			order = 7+i,
		}
	end
else
	for i = 1, GetNumTalentTabs() do
		local _, name = GetTalentTabInfo(i) --MOP DEPRECIATED, COMPAT CODE IN PLACE
		TMW.GroupConfigTemplate.args.main.args["Tree"..i] = {
			type = "toggle",
			name = name,
			desc = L["UIPANEL_TREE_DESC"],
			order = 7+i,
		}
	end
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
								BarGCD = {
									name = L["UIPANEL_BARIGNOREGCD"],
									desc = L["UIPANEL_BARIGNOREGCD_DESC"],
									type = "toggle",
									order = 21,
								},
								ClockGCD = {
									name = L["UIPANEL_CLOCKIGNOREGCD"],
									desc = L["UIPANEL_CLOCKIGNOREGCD_DESC"],
									type = "toggle",
									order = 22,
								},
								DrawEdge = { -- Cooldown:SetDrawEdge was removed in MoP
									name = L["UIPANEL_DRAWEDGE"],
									desc = L["UIPANEL_DRAWEDGE_DESC"],
									type = "toggle",
									order = 40,
									hidden = TMW.ISMOP,
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
								AlwaysSubLinks = {
									name = L["ALWAYSSUBLINKS"],
									desc = L["ALWAYSSUBLINKS_DESC"],
									type = "toggle",
									order = 43,
								},
								SUG_atBeginning = {
									name = L["SUG_ATBEGINING"],
									desc = L["SUG_ATBEGINING_DESC"],
									width = "double",
									type = "toggle",
									order = 44,
								},
								ReceiveComm = {
									name = L["ALLOWCOMM"],
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
						resetall = {
							name = L["UIPANEL_ALLRESET"],
							desc = L["UIPANEL_TOOLTIP_ALLRESET"],
							type = "execute",
							order = 51,
							confirm = true,
							func = function() TMW.db:ResetProfile() end,
						},
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
						addgroupgroup = {
							type = "group",
							name = L["UIPANEL_ADDGROUP"],
							args = {
								addgroup = {
									name = L["UIPANEL_ADDGROUP"],
									desc = L["UIPANEL_ADDGROUP_DESC"],
									type = "execute",
									order = 41,
									handler = TMW,
									func = "Group_Add",
								},
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

	-- Dynamic Group Settings --
	for k, v in pairs(TMW.OptionsTable.args.groups.args) do
		if v == TMW.GroupConfigTemplate then
			TMW.OptionsTable.args.groups.args[k] = nil
		end
	end
	for g = 1, TMW.db.profile.NumGroups do
		TMW.OptionsTable.args.groups.args["#Group " .. g] = TMW.GroupConfigTemplate
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
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("TMW Options", 781, 512)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW IEOptions", TMW.OptionsTable)
	if not TMW.AddedToBlizz then
		TMW.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TMW Options", L["ICON_TOOLTIP1"])
	end
end



-- -------------
-- GROUP CONFIG
-- -------------

---------- Position ----------
local Ruler = CreateFrame("Frame")
function TMW:GetAnchoredPoints(group)
	local p = TMW.db.profile.Groups[group:GetID()].Point

	local relframe = _G[p.relativeTo] or UIParent
	local point, relativePoint = p.point, p.relativePoint

	if relframe == UIParent then
		-- use the smart anchor points provided by UIParent anchoring if it is being used
		local _
		point, _, relativePoint = group:GetPoint(1)
	end

	Ruler:ClearAllPoints()
	Ruler:SetPoint("TOPLEFT", group, point)
	Ruler:SetPoint("BOTTOMRIGHT", relframe, relativePoint)

	local X = Ruler:GetWidth()/UIParent:GetScale()/group:GetScale()
	local Y = Ruler:GetHeight()/UIParent:GetScale()/group:GetScale()
	return point, relframe:GetName(), relativePoint, -X, Y
end

function TMW:Group_StopMoving(group)
	group:StopMovingOrSizing()
	
	ID.isMoving = nil
	group:CalibrateAnchors()
	
	group:SetPos()
	
	IE:NotifyChanges()
end

function TMW:Group_ResetPosition(groupID)
	for k, v in pairs(TMW.Group_Defaults.Point) do
		TMW.db.profile.Groups[groupID].Point[k] = v
	end
	TMW.db.profile.Groups[groupID].Scale = 1
	IE:NotifyChanges()
	TMW[groupID]:Setup()
end


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
	IE:Load()
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
		if ID.isMoving then
			TMW:Group_StopMoving(ID.isMoving)
		end
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

	local t, data, subType
	local input
	if not (CursorHasSpell() or CursorHasItem()) and ID.DraggingInfo then
		t = "spell"
		data, subType = unpack(ID.DraggingInfo)
	else
		t, data, subType = GetCursorInfo()
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
		success = func(arg1, icon, t, data, subType)
	else
		success = icon.typeData:DragReceived(icon, t, data, subType)
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

ID:RegisterIconDragHandler(30,	-- Anchor
	function(ID, info)
		do
			local name, desc

			local srcname = L["fGROUP"]:format(TMW:GetGroupName(ID.srcicon.group:GetID(), ID.srcicon.group:GetID(), 1))

			if ID.desticon and ID.srcicon.group:GetID() ~= ID.desticon.group:GetID() then
				local destname = L["fGROUP"]:format(TMW:GetGroupName(ID.desticon.group:GetID(), ID.desticon.group:GetID(), 1))
				name = L["ICONMENU_ANCHORTO"]:format(destname)
				desc = L["ICONMENU_ANCHORTO_DESC"]:format(srcname, destname, destname, srcname)

			elseif ID.destFrame and ID.destFrame:GetName() then
				if ID.destFrame == WorldFrame and ID.srcicon.group.Point.relativeTo ~= "UIParent" then
					name = L["ICONMENU_ANCHORTO_UIPARENT"]
					desc = L["ICONMENU_ANCHORTO_UIPARENT_DESC"]

				elseif ID.destFrame ~= WorldFrame then
					local destname = ID.destFrame:GetName()
					name = L["ICONMENU_ANCHORTO"]:format(destname)
					desc = L["ICONMENU_ANCHORTO_DESC"]:format(srcname, destname, destname, srcname)
				end
			end

			if name then
				info.text = name
				info.tooltipTitle = name
				info.tooltipText = desc
				return true
			end
		end
	end,
	function(ID)
		if ID.desticon then
			-- we are anchoring to another TMW group, so dont operate on the same group.
			if ID.desticon.group == ID.srcicon.group then
				return
			end

			-- set the setting
			ID.srcicon.group.Point.relativeTo = ID.desticon.group:GetName()
		else
			local name = ID.destFrame:GetName()
			-- we are anchoring to some other frame entirely.
			if ID.destFrame == WorldFrame then
				-- If it was dragged to WorldFrame then reset the anchor to UIParent (the text in the dropdown is custom for this circumstance)
				name = "UIParent"
			elseif ID.destFrame == ID.srcicon.group then
				-- this should never ever ever ever ever ever ever ever ever happen.
				return
			elseif not ID.destFrame:GetName() then
				-- make sure it actually has a name
				return
			end

			-- set the setting
			ID.srcicon.group.Point.relativeTo = name
		end

		-- do adjustments and positioning
		-- i cheat. we didnt really stop moving anything, but i'm going to hijack this function anyway.
		TMW:Group_StopMoving(ID.srcicon.group)
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
		group[1]:SetInfo("texture", ID.srcicon.attributes.texture)

		local srcicon, desticon = tostring(ID.srcicon), tostring(group[1])

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


function IE:OnInitialize()

	-- they see me clonin'... they hatin'...
	-- (make TMW.IE be the same as IE)
	-- IE[0] = TellMeWhen_IconEditor[0] (already done in .xml)
	local meta = CopyTable(getmetatable(IE))
	meta.__index = getmetatable(TellMeWhen_IconEditor).__index
	setmetatable(IE, meta)

	IE:SetScript("OnUpdate", IE.OnUpdate)
	IE.iconsToUpdate = {}

	IE.history = {}
	IE.historyState = 0

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

	-- run updates for any icons that are queued
	for i, icon in ipairs(IE.iconsToUpdate) do
	--	icon:Setup()
		TMW.safecall(icon.Setup, icon)
	end
	wipe(IE.iconsToUpdate)

	-- check and see if the settings of the current icon have changed.
	-- if they have, create a history point (or at least try to)
	-- IMPORTANT: do this after running icon updates <because of an old antiquated reason which no longer applies, but if it ain't broke, don't fix it>
	IE:AttemptBackup(icon)
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


function IE:RegisterTab(tab, attachedFrame)
	local id = #IE.Tabs + 1
	
	if id == 1 then
		tab:SetPoint("BOTTOMLEFT", 0, -30)
	else
		tab:SetPoint("LEFT", IE.Tabs[id - 1], "RIGHT", -18, 0)
	end
	IE.Tabs[id] = tab
	tab:SetID(id)
	tab.attachedFrame = attachedFrame
end

---------- Interface ----------
IE.ALLDISPLAYTABFRAMES = {}

local panelList = {}

local GetColorForFrameName
do
	local t = {}
	GetColorForFrameName = function(key)
		-- This function isn't supposed to make sense.
		-- It just generates pseudorandom numbers that are always the same given an input.
		key = key:lower()
		wipe(t)
		local len = #key
		local seglen = floor(len/3)
		local currentField = 1
		for i = 1, len do
			local byte = strbyte(key:sub(i, i)) - 90
			
			t[currentField] = (t[currentField] or 0) + byte + byte^(i-((currentField-1)*seglen))
			if i%seglen == 0 then
				currentField = currentField + 1 
			end
			if currentField == 4 then
				break
			end
		end
		
		local maxVal = max(t[1], t[2], t[3])
		for i, v in pairs(t) do
			t[i] = v/maxVal
		end
		
		return t[1], t[2], t[3], 0.06
	end
end

function IE:PositionPanels()
	wipe(panelList)
	for _, Component in pairs(CI.ic.Components) do
		if Component:ShouldShowConfigPanels(CI.ic) then
			for _, panelInfo in pairs(Component.ConfigPanels) do
				tinsert(panelList, panelInfo)
			end		
		end
	end
	
	for i = 1, #IE.Main.PanelListing do
		IE.Main.PanelListing[i]:Hide()
	end
	
	TMW:SortOrderedTables(panelList)
	
	local lastFrame
	
	for i, panelInfo in ipairs(panelList) do
		local frame
		-- Get the frame for the panel if it already exists, or create it if it doesn't.
		if panelInfo.panelType == "XMLTemplate" then
			frame = IE.ALLDISPLAYTABFRAMES[panelInfo.xmlTemplateName]
			
			if not frame then
				frame = CreateFrame("Frame", panelInfo.xmlTemplateName, TellMeWhen_IconEditorMainScrollFrame, panelInfo.xmlTemplateName)
				IE.ALLDISPLAYTABFRAMES[panelInfo.xmlTemplateName] = frame
			end
		elseif panelInfo.panelType == "ConstructorFunc" then
			frame = IE.ALLDISPLAYTABFRAMES[panelInfo] 
			
			if not frame then
				frame = CreateFrame("Frame", panelInfo.frameName, TellMeWhen_IconEditorMainScrollFrame, "TellMeWhen_OptionsModuleContainer")
				
				IE.ALLDISPLAYTABFRAMES[panelInfo] = frame
				TMW.safecall(panelInfo.func, frame)
			end
		end
		
		local GenericComponent = panelInfo.component
		
		local R, G, B
		if GenericComponent.className == "IconType" then
			R, G, B = 0.3, 1, 0.5
		elseif GenericComponent.className:find("IconModule") then
			R, G, B = 0.3, 0.4, 1
		elseif GenericComponent.className:find("GroupModule") then
			R, G, B = 0.6, 0.4, 1
		elseif GenericComponent.className:find("IconDataProcessor") then -- IconDataProcessor and IconDataProcessorHook
			--R, G, B = 1, 0.3, 0.3
			R, G, B = 0.3, 0.4, 1
		else
			print("TMW: UNHANDLED CONFIG PANEL CLASS: ", GenericComponent.className)
			R, G, B = 1, 1, 1
		end
		
		frame.Background:SetTexture(R, G, B)
		frame.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0.10)
		
		if lastFrame then
			frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -10)
		else
			frame:SetPoint("TOP", 20, -7)
		end
		lastFrame = frame
		
		frame:Show()
		
		TMW:Fire("TMW_CONFIG_PANEL_SETUP", frame, panelInfo)
		
		local panelListingFrame = IE.Main.PanelListing:GetListing(i)
		panelListingFrame:SetText(frame.Header:GetText())
		panelListingFrame.Background:SetTexture(R, G, B)
		panelListingFrame:Show()
		
		panelListingFrame.frame = frame
		frame.panelListingFrame = panelListingFrame
	end	
end

function IE:OptionsModuleContainer_OnUpdate(self)
	local Background = self.Background
	
	if Background.START_ANIM then
		ANIM_PERIOD = 0.5
		ANIM_DURATION = 2
	
		local Duration = 0
		
		while ANIM_DURATION > Duration do
			Duration = Duration + (ANIM_PERIOD * 2)
		end

		Background.Start = TMW.time
		Background.Duration = Duration
		Background.Period = ANIM_PERIOD
		
		Background.START_ANIM = nil
		Background.IS_PLAYING = true
	end
	
	if Background.IS_PLAYING then
		local FlashPeriod = Background.Period

		local timePassed = TMW.time - Background.Start
		local fadingIn = floor(timePassed/FlashPeriod) % 2 == 1

		local remainingFlash = timePassed % FlashPeriod
		local multiplier
		if fadingIn then
			multiplier = (FlashPeriod-remainingFlash)/FlashPeriod
		else
			multiplier = remainingFlash/FlashPeriod
		end
		
		multiplier = multiplier*1.5
		
		local min = 0.05 + 0.05 * multiplier
		local max = 0.10 + 0.10 * multiplier
		
		self.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, min, 1, 1, 1, max)

		if timePassed > Background.Duration then
			self.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0.10)
			Background.IS_PLAYING = nil
		end
		
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
		HELP:HideForIcon(CI.ic)
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
			IE.Main.ScrollFrame:SetVerticalScroll(0)
		end
		
		TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", icon)
	end
	if not IE:IsShown() then
		if isRefresh then
			return
		else
			IE:TabClick(IE.MainTab)
		end
	end

	local groupID, iconID = CI.g, CI.i
	if not groupID or not iconID then return end

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

	
	
	
	
	
	
	-- TODO: this code is very crude (if you didnt noticed when you saw ALLDISPLAYTABFRAMES. Please clean it up before releasing)
	for _, frame in pairs(IE.ALLDISPLAYTABFRAMES) do
		frame:Hide()
	end
	
	IE:PositionPanels()
	
	
	
	
	TMW:Fire("TMW_CONFIG_ICON_LOADED", CI.ic)

	local t = CI.ics.Type
	if t then
		for name, Type in pairs(Types) do
			if name ~= t and Type.IE_TypeUnloaded then
				TMW.safecall(Type.IE_TypeUnloaded, Type)
			end
		end
		if Types[t].IE_TypeLoaded then
			TMW.safecall(Types[t].IE_TypeLoaded, Types[t])
		end
	end
	
	IE:ScheduleIconSetup()

	HELP:ShowNext()
	
	-- It is intended that this happens at the end instead of the beginning.
	-- Table accesses that trigger metamethods flesh out an icon's settings with new things that aren't there pre-load (usually)
	if icon then
		IE:AttemptBackup(CI.ic)
	end
	IE:UndoRedoChanged()

	if IE.Main.ScrollFrame:GetVerticalScrollRange() == 0 then
		IE.Main.ScrollFrame.ScrollBar:Hide()
	end
end

function IE:LoadFirstValidIcon()
	for icon in TMW:InIcons() do
		-- hack to get the first icon that exists and is shown
		if icon:IsVisible() then
			TMW.IE:Load(1, icon)
			return
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

	HELP:ShowNext() -- should happen after conditions are loaded
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
	IE:ScheduleIconSetup()
	IE:Load(1)
	IE:TabClick(IE.MainTab)
	HELP:HideForIcon(CI.ic)
end



TMW:NewClass("IconEditor_Resizer_ScaleX_SizeY", "Resizer_Generic"){
	tooltipText = L["RESIZE_TOOLTIP"],
	UPD_INTV = 1,
	tooltipTitle = L["RESIZE"],
	
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

		
		
		-- Calculate & set new scale:
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


---------- Settings ----------

TMW:NewClass("SettingFrameBase"){
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
		self:SetAlpha(0.4)
		
		if self.data.disabledtooltip then
			self:SetTooltip(self.data.title, self.data.disabledtooltip)
		end
	end,
	
	SetTooltip = function(self, title, text)
		TMW:TT(self, title, text, 1, 1)
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
		
		local color = 34/255
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

TMW:NewClass("SettingTotemButton", "CheckButton", "SettingFrameBase", "BitflagSettingFrameBase"){
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
		OnDisable = function(self)
			self:ClearFocus()
		end,
	},
	
	OnCreate_EditboxBase = function(self)
		TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self.ClearFocus, self)
	end,
	
	IsEnabled = function(self)
		return self.Enabled
	end,
	SetEnabled = function(self, enabled)
		self:EnableKeyboard(enabled)
		self:EnableMouse(enabled)
		
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
					self.Alpha.text:SetText(supplementalDataForBit.text)
					self.Alpha:SetTooltip(supplementalDataForBit.text, supplementalDataForBit.tooltipText)
					
					self.Check:SetTooltip(supplementalDataForBit.text, supplementalDataForBit.tooltipText)
				end
			end
		end)
	end,
	
	--TODO: put these four functions in their own class and have both this class and SettingEditBox inherit from it (they share the same functions with only a small extension needed for SettingEditBox
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
	local numPerRow = allData.numPerRow or min(#allData, 3)
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
					f:SetPoint("LEFT", lastCheckButton.text, "RIGHT", 5, 0)
				end
			else
				-- Anchor the first check to the parent. The left anchor will be handled by DistributeFrameAnchorsLaterally.
				f:SetPoint("TOP", 0, -6)
			end
			lastCheckButton = f

			f.text:SetWidth(TMW.WidthCol1)
			
			numFrames = numFrames + 1
		end
	end
	
	TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function()
		for i = 1, #parent, numPerRow do
			IE:DistributeFrameAnchorsLaterally(parent, numPerRow, unpack(parent, i))
		end
	end)
	
	parent:SetHeight(16 + ceil(numFrames/numPerRow)*24)
	
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
	local tbl = TMW:SplitNames(EquivFullIDLookup[equiv])
	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		if not name then
			if TMW.debug then
				TMW:Error("INVALID ID FOUND: %s:%s", equiv, v)
			else
				name = v
				texture = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
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

				info.icon = TMW.SpellTextures[EquivFirstIDLookup[k]]
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

				local first = strsplit(EquivFirstIDLookup[k], ";")
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
	-- TODO: tie this closer to the choosename panel
	local e = IE.MainScrollFrame.Name
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


---------- Dropdowns ----------
function IE:Type_DropDown()
	if not TMW.db then return end
	local groupID, iconID = CI.g, CI.i

	for _, Type in ipairs(TMW.OrderedTypes) do -- order in the order in which they are loaded in the .toc file
		if not Type.hidden then
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

	SUG.redoIfSame = 1
	SUG.Suggest:Hide()
	HELP:HideForIcon(CI.ic)
	IE:Load(1)
end

function IE:Unit_DropDown()
	if not TMW.db then return end
	local e = self:GetParent()
	if not e:HasFocus() then
		e:HighlightText()
	end
	for k, v in pairs(TMW.Units) do
		if not v.onlyCondition then
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.text
			info.value = v.value
			if v.range then
				info.tooltipTitle = v.tooltipTitle or v.text
				info.tooltipText = "|cFFFF0000#|r = 1-" .. v.range
				info.tooltipOnButton = true
			end
			info.notCheckable = true
			info.func = IE.Unit_DropDown_OnClick
			info.arg1 = v
			info.arg2 = e
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

function IE:Unit_DropDown_OnClick(v, e)
	local ins = v.value
	if v.range then
		ins = v.value .. "|cFFFF0000#|r"
	end
	e:Insert(";" .. ins .. ";")
	TMW:CleanString(e)
	IE:ScheduleIconSetup()
	CloseDropDownMenus()
end


---------- Tooltips ----------
local cachednames = {}
function IE:GetRealNames(Name) -- TODO: MODULARIZE THIS
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(Name)
	if cachednames[CI.ics.Type .. CI.SoI .. text] then return cachednames[CI.ics.Type .. CI.SoI .. text] end

	local tbl
	local GetSpellInfo = GetSpellInfo
	if CI.SoI == "item" then
		tbl = TMW:GetItemIDs(nil, text)
	else
		tbl = TMW:GetSpellNames(nil, text)
	end
	local durations = Types[CI.ics.Type].DurationSyntax and TMW:GetSpellDurations(nil, text)

	local str = ""
	local numadded = 0
	local numlines = 50
	local numperline = ceil(#tbl/numlines)

	for k, v in pairs(tbl) do
		local name, texture
		if CI.SoI == "item" then
			name = GetItemInfo(v) or v or ""
			texture = GetItemIcon(v)
		else
			name, _, texture = GetSpellInfo(v)
			texture = texture or SpellTextures[name or v]
			if not name and SUG.SpellCache then
				local lowerv = strlower(v)
				for id, lowername in pairs(SUG.SpellCache) do
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
	cachednames[CI.ics.Type .. CI.SoI .. text] = str
	return str
end

local cachedunits = {}
function IE:GetRealUnits(editbox)
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(editbox)
	if cachedunits[text] then return cachedunits[text] end

	local tbl = TMW.UNITS:GetOriginalUnitTable(text)

	local str = ""
	local numadded = 0
	local numlines = 50
	local numperline = ceil(#tbl/numlines)

	for k, v in pairs(tbl) do

		if not tiptemp[v] then --prevents display of the same name twice when there are multiple units... or something. I copy-pasted this.
			numadded = numadded + 1
			str = str ..
			v ..
			"; " ..
			(floor(numadded/numperline) == numadded/numperline and "\r\n" or "")
		end
		tiptemp[v] = true
	end
	wipe(tiptemp)
	str = strtrim(str, "\r\n ;")
	cachedunits[text] = str
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

	local SharableDataType = TMW.approachTable(TMW, "Classes", "SharableDataType", "types", type)
	if SharableDataType and SharableDataType.Import_ImportData then
		SharableDataType:Import_ImportData(editbox, settings, version, ...)

		TMW:Update()
		IE:Load(1)
	else
		TMW:Print(L["IMPORTERROR_INVALIDTYPE"])
	end
	
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

EVENTS = TMW.EVENTS

function EVENTS:SetupEventSettings()
	local EventSettings = self.EventSettings

	if not EVENTS.currentEventID then return end

	local eventData = self.Events[EVENTS.currentEventID].eventData

	EventSettings.EventName:SetText(eventData.text)

	local Settings = self:GetEventSettings()
	local settingsUsedByEvent = eventData.settings

	--hide settings
	EventSettings.Operator	 	 :Hide()
	EventSettings.Value		 	 :Hide()
	EventSettings.CndtJustPassed :Hide()
	EventSettings.PassingCndt	 :Hide()
	EventSettings.Icon			 :Hide()

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
		if not settingsUsedByEvent.CndtJustPassed == "FORCE" then
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
end

function EVENTS:OperatorMenu_DropDown()
	-- self is not Module
	local Module = TMW.EVENTS.currentEventHandler
	local eventData = Module.Events[EVENTS.currentEventID].eventData

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
				info.text = TMW:GetGroupName(groupID, groupID, 1)
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
			if info.disabled then
				info.tooltipText = L["SOUND_EVENT_DISABLEDFORTYPE_DESC"]:format(Types[CI.ics.Type].name)
			else
				info.tooltipText = get(eventData.desc)
			end
			info.tooltipWhileDisabled = true
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

function EVENTS:CreateEventButtons(globalDescKey)
	local Events = self.Events
	local previousFrame

	local yAdjustTitle, yAdjustText = 0, 0
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		yAdjustTitle, yAdjustText = 3, -3
	end
	local Settings = self:GetEventSettings()

	for i, eventSettings in TMW:InNLengthTable(CI.ics.Events) do
		local eventData = TMW.EventList[eventSettings.Event]
		local frame = Events[i]
		if not frame then
			frame = CreateFrame("Button", Events:GetName().."Event"..i, Events, "TellMeWhen_Event", i)
			Events[i] = frame
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

			frame.EventName:SetText(eventData.text)

			frame.normalDesc = eventData.desc .. "\r\n\r\n" .. L["EVENTS_HANDLERS_GLOBAL_DESC"]
			TMW:TT(frame, eventData.text, frame.normalDesc, 1, 1)
		else
			frame.EventName:SetText("UNKNOWN EVENT: " .. tostring(eventSettings.Event))
			frame:Disable()

		end
		previousFrame = frame
	end

	for i = max(CI.ics.Events.n + 1, 1), #Events do
		Events[i]:Hide()
	end

	if Events[1] then
		Events[1]:SetPoint("TOPLEFT", Events, "TOPLEFT", 0, 0)
		Events[1]:SetPoint("TOPRIGHT", Events, "TOPRIGHT", 0, 0)
	end

	Events:SetHeight(max(CI.ics.Events.n*(Events[1] and Events[1]:GetHeight() or 0), 1))
end

function EVENTS:EnableAndDisableEvents()
	local oldID = EVENTS.currentEventID

	self:BuildListOfValidEvents()
	
	for i, frame in ipairs(self.Events) do
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
				TMW:TT(frame, frame.eventData.text, L["SOUND_EVENT_DISABLEDFORTYPE_DESC"]:format(Types[CI.ics.Type].name), 1, 1)

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
	local eventFrame = self.Events[id]

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

	for i, f in ipairs(self.Events) do
		f.selected = nil
		f:UnlockHighlight()
		f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end
	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)

	IE.Events.ScrollFrame.adjustmentQueued = true

	return eventFrame
end

function EVENTS:AdjustScrollFrame()
	local ScrollFrame = IE.Events.ScrollFrame
	local eventFrame = self.Events[self.currentEventID]

	if not eventFrame then return end

	if eventFrame:GetBottom() and eventFrame:GetBottom() < ScrollFrame:GetBottom() then
		ScrollFrame.ScrollBar:SetValue(ScrollFrame.ScrollBar:GetValue() + (ScrollFrame:GetBottom() - eventFrame:GetBottom()))
	elseif eventFrame:GetTop() and eventFrame:GetTop() > ScrollFrame:GetTop() then
		ScrollFrame.ScrollBar:SetValue(ScrollFrame.ScrollBar:GetValue() - (eventFrame:GetTop() - ScrollFrame:GetTop()))
	end
end

function EVENTS:GetNumUsedEvents()
	local n = 0
	for i = 1, #self.Events do
		local f = self.Events[i]
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

	if IE.Events.ScrollFrame:GetVerticalScrollRange() == 0 then
		IE.Events.ScrollFrame.ScrollBar:Hide()
	end

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
	EVENTS.Events = IE.Events.Events
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







-- ----------------------
-- SUGGESTER
-- ----------------------

SUG = TMW:NewModule("Suggester", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0") TMW.SUG = SUG


---------- Locals/Data ----------
local SUGIsNumberInput
local SUGpreTable = {}
local SUGPlayerSpells = {}
local pclassSpellCache, ClassSpellLookup, AuraCache, ItemCache, SpellCache, CastCache, CurrentItems
local TrackingCache = {}


---------- Initialization/Database/Spell Caching ----------
function SUG:OnInitialize()
	TMWOptDB = TMWOptDB or {}

	TMWOptDB.SpellCache = TMWOptDB.SpellCache or {}
	TMWOptDB.CastCache = nil -- not used anymore, spells are validated as they are displayed now.
	TMWOptDB.ItemCache = TMWOptDB.ItemCache or {}
	TMWOptDB.AuraCache = TMWOptDB.AuraCache or {}
	TMWOptDB.ClassSpellCache = nil -- this is old, get rid of it

	CurrentItems = {}

	for k, v in pairs(TMWOptDB) do
		SUG[k] = v
	end
	SUG.ClassSpellCache = TMW.ClassSpellCache -- just in case

	if TMW.AuraCache ~= SUG.AuraCache then -- desprate attempt to fix the problem where the aura cache randomly decides to reset itself. LATER: YAY, I FIGURED IT OUT. I was calling SUG:OnInitialize() in some testing, which was causing it to delete all of its keys. this check will prevent that from now on.
		for k, v in pairs(TMW.AuraCache) do
			-- import into the options DB and take it out of the main DB
			SUG.AuraCache[k] = SUG.AuraCache[k] or v or SUG.AuraCache[k]
			TMW.AuraCache[k] = nil
		end
		TMW.AuraCache = SUG.AuraCache -- make new inserts go into the optionDB and this table
	end

	SUG.RequestedFrom = {}
	SUG.commThrowaway = {}

	SUG:PLAYER_TALENT_UPDATE()
	SUG:BuildClassSpellLookup() -- must go before the local versions (ClassSpellLookup) are defined
	SUG.doUpdateItemCache = true

	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		TrackingCache[i] = strlower(name)
	end

	SUG:RegisterComm("TMWSUG")
	SUG:RegisterEvent("PLAYER_TALENT_UPDATE")
	SUG:RegisterEvent("PLAYER_ENTERING_WORLD")
	SUG:RegisterEvent("UNIT_PET")
	SUG:RegisterEvent("BAG_UPDATE")
	SUG:RegisterEvent("BANKFRAME_OPENED", "BAG_UPDATE")
	SUG:RegisterEvent("GET_ITEM_INFO_RECEIVED")

	if IsInGuild() then
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "GUILD")
	end

	pclassSpellCache,				ClassSpellLookup,		AuraCache,		ItemCache,		SpellCache =
	TMW.ClassSpellCache[pclass],	SUG.ClassSpellLookup,	SUG.AuraCache,	SUG.ItemCache,	SUG.SpellCache

	SUG:PLAYER_ENTERING_WORLD()

	local _, _, _, clientVersion = GetBuildInfo()
	if TMWOptDB.IncompleteCache or not TMWOptDB.WoWVersion or TMWOptDB.WoWVersion < clientVersion then
		local didrunhook
		IE:HookScript("OnShow", function()
			if didrunhook then return end

			do	--validate all old items in the item cache

				-- function to call once data about items has been collected from the server
				function SUG:ValidateItemIDs()
					--all data should be in by now, see what actually exists.
					for id in pairs(ItemCache) do
						if not GetItemInfo(id) then
							ItemCache[id] = nil
						end
					end
					SUG.ValidateItemIDs = nil
				end

				--start the requests
				for id in pairs(ItemCache) do
					GetItemInfo(id)
				end

				SUG:ScheduleTimer("ValidateItemIDs", 60)
			end


			TMWOptDB.IncompleteCache = true
			SUG.NumCachePerFrame = 10

			local Blacklist = {
				["Interface\\Icons\\Trade_Alchemy"] = true,
				["Interface\\Icons\\Trade_BlackSmithing"] = true,
				["Interface\\Icons\\Trade_BrewPoison"] = true,
				["Interface\\Icons\\Trade_Engineering"] = true,
				["Interface\\Icons\\Trade_Engraving"] = true,
				["Interface\\Icons\\Trade_Fishing"] = true,
				["Interface\\Icons\\Trade_Herbalism"] = true,
				["Interface\\Icons\\Trade_LeatherWorking"] = true,
				["Interface\\Icons\\Trade_Mining"] = true,
				["Interface\\Icons\\Trade_Tailoring"] = true,
				["Interface\\Icons\\INV_Inscription_Tradeskill01"] = true,
				["Interface\\Icons\\Temp"] = true,
			}
			
			local function findword(str, word)
				if not strfind(str, word) then
					return nil
				else
					if
						strfind(str, "%A" .. word .. "%A") or	-- in the middle
						strfind(str, "^" .. word .. "%A") or	-- at the beginning
						strfind(str, "%A" .. word .. "$")		-- at the end
					then
						return true
					end
				end
			end
			
			local index, spellsFailed = 0, 0

			TMWOptDB.CacheLength = TMWOptDB.CacheLength or 11000

			SUG.Suggest.Status:Show()
			SUG.Suggest.Status.texture:SetTexture(LSM:Fetch("statusbar", TMW.db.profile.TextureName))
			SUG.Suggest.Status:SetMinMaxValues(1, TMWOptDB.CacheLength)
			SUG.Suggest.Speed:Show()
			SUG.Suggest.Finish:Show()

			if TMWOptDB.WoWVersion and TMWOptDB.WoWVersion < clientVersion then
				wipe(SUG.SpellCache)
			elseif TMWOptDB.IncompleteCache then
				for id in pairs(SUG.SpellCache) do
					index = max(index, id)
				end
			end
			TMWOptDB.WoWVersion = clientVersion

			local Parser, LT1 = SUG:GetParser()

			local SPELL_CAST_CHANNELED = SPELL_CAST_CHANNELED
			local yield, resume = coroutine.yield, coroutine.resume

			local function SpellCacher()

				while spellsFailed < 1500 do
				
					local name, rank, icon = GetSpellInfo(index)
					if name then
						name = strlower(name)

						local fail =
						Blacklist[icon] or
						findword(name, "dnd") or
						findword(name, "test") or
						findword(name, "debug") or
						findword(name, "bunny") or
						findword(name, "visual") or
						findword(name, "trigger") or
						strfind(name, "[%[%%%+%?]") or -- no brackets, plus signs, percent signs, or question marks
						findword(name, "vehicle") or
						findword(name, "event") or
						findword(name, "quest") or
						strfind(name, ":%s?%d") or -- interferes with colon duration syntax
						findword(name, "camera") or
						findword(name, "dmg")

						if not fail then
							Parser:SetOwner(UIParent, "ANCHOR_NONE") -- must set the owner before text can be obtained.
							Parser:SetSpellByID(index)
							local r, g, b = LT1:GetTextColor()
							if g > .95 and r > .95 and b > .95 then
								SpellCache[index] = name
							end
							spellsFailed = 0
						end
					else
						spellsFailed = spellsFailed + 1
					end
					index = index + 1

					if index % SUG.NumCachePerFrame == 0 then
						SUG.Suggest.Status:SetValue(index)
						yield()
					end
				end
			end
			local co = coroutine.create(SpellCacher)

			local f = CreateFrame("Frame")
			f:SetScript("OnUpdate", function()
				if not resume(co) then
					TMWOptDB.IncompleteCache = false
					TMWOptDB.CacheLength = index

					f:SetScript("OnUpdate", nil)

					SUG.Suggest.Speed:Hide()
					SUG.Suggest.Status:Hide()
					SUG.Suggest.Finish:Hide()


					SpellCache[1852] = nil -- GM spell named silenced, interferes with equiv
					SpellCache[47923] = nil -- spell named stunned, interferes
					SpellCache[65918] = nil -- spell named stunned, interferes
					SpellCache[78320] = nil -- spell named stunned, interferes
					SpellCache[71216] = nil -- enraged, interferes
					SpellCache[59208] = nil -- enraged, interferes
					SpellCache[100000] = GetSpellInfo(100000) and strlower(GetSpellInfo(100000)) -- filted out by default but this spell really needs to be in the list because of how cool it is

					SUG.IsCaching = nil
					if SUG.onCompleteCache then
						SUG.onCompleteCache = nil
						TMW.SUG.redoIfSame = 1
						SUG:NameOnCursor()
					end

					co = nil
					Parser:Hide()
					collectgarbage()
				end
			end)
			SUG.IsCaching = true
			didrunhook = true
		end)
	end
end

do	-- SUG:GetParser()
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3
	function SUG:GetParser()
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

---------- Events ----------
function SUG:UNIT_PET(event, unit)
	if unit == "player" and HasPetSpells() then
		local Cache = TMW.ClassSpellCache.PET
		local i = 1
		while true do
			local _, id = GetSpellBookItemInfo(i, "pet")
			if id then
				Cache[id] = pclass
			else
				break
			end
			i=i+1
		end
		SUG.updatePlayerSpells = 1
	end
end

function SUG:PLAYER_ENTERING_WORLD()
	SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "RAID")
	SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "PARTY")
	SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "BATTLEGROUND")
end

function SUG:PLAYER_TALENT_UPDATE()
	local t = TMW.ClassSpellCache[pclass]
	local _, RACIAL = GetSpellInfo(20572) -- blood fury, we need the localized "Racial" string
	local  _, _, _, endgeneral = GetSpellTabInfo(1)
	local _, _, offs, numspells = GetSpellTabInfo(4)
	local _, race = UnitRace("player")
	for i = 1, offs + numspells do
		local _, id = GetSpellBookItemInfo(i, "player")
		if id then
			local name, rank = GetSpellInfo(id)
			if rank == RACIAL then
				TMW.ClassSpellCache.RACIAL[id] = race
			elseif i > endgeneral then
				t[id] = 1
			end
		end
	end
	SUG.updatePlayerSpells = 1
end

function SUG:BAG_UPDATE()
	SUG.doUpdateItemCache = true
end

function SUG:GET_ITEM_INFO_RECEIVED()
	if SUG.CurrentModule and SUG.CurrentModule.moduleName:find("item") then
		SUG:SuggestingComplete()
	end
end


---------- Comm ----------
function SUG:OnCommReceived(prefix, text, channel, who)
	if prefix ~= "TMWSUG" or who == UnitName("player") then return end
	local success, arg1, arg2 = SUG:Deserialize(text)
	if success then
		if arg1 == "RCSL" and not SUG.RequestedFrom[who] then -- only send if the player has not requested yet this session
			SUG:BuildClassSpellLookup()
			SUG:SendCommMessage("TMWSUG", SUG:Serialize("CSL", SUG.ClassSpellLength), "WHISPER", who)
			SUG.RequestedFrom[who] = true
		elseif arg1 == "CSL" then
			wipe(SUG.commThrowaway)
			local RecievedClassSpellLength = arg2
			SUG:BuildClassSpellLookup()
			if not RecievedClassSpellLength.RACIAL then return end -- VERY IMPORTANT - OLD VERSIONS WILL NOT HAVE THE RACIAL TABLE, THIS IS HOW I AM GOING TO DISTINGUISH BETWEEN OLD AND NEW VERSIONS (NEW VERSION BEING 4.4.1+; STORES CLASS SPELLS IN DB.PROFILE.GLOBAL)
			for class, length in pairs(RecievedClassSpellLength) do
				if (not SUG.ClassSpellLength[class]) or (SUG.ClassSpellLength[class] < length) then
					tinsert(SUG.commThrowaway, class)
				end
			end
			if #SUG.commThrowaway > 0 then
				SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSC", SUG.commThrowaway), "WHISPER", who)
			end
		elseif arg1 == "RCSC" then
			wipe(SUG.commThrowaway)
			for _, class in pairs(arg2) do
				SUG.commThrowaway[class] = TMW.ClassSpellCache[class]
			end
			SUG:SendCommMessage("TMWSUG", SUG:Serialize("CSC", SUG.commThrowaway), "WHISPER", who)
		elseif arg1 == "CSC" then
			for class, tbl in pairs(arg2) do
				for id, val in pairs(tbl) do
					TMW.ClassSpellCache[class][id] = val
				end
			end
			SUG:BuildClassSpellLookup()
		end
	elseif TMW.debug then
		TMW:Error(arg1)
	end
end


---------- Suggesting ----------
function SUG:DoSuggest()
	wipe(SUGpreTable)

	local tbl = SUG.CurrentModule:Table_Get()


	SUG.CurrentModule:Table_GetNormalSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	SUG.CurrentModule:Table_GetEquivSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	SUG.CurrentModule:Table_GetSpecialSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())

	SUG:SuggestingComplete(1)
end

function SUG:SuggestingComplete(doSort)
	local numFramesNeeded = TMW.SUG:GetNumFramesNeeded()

	if doSort and not SUG.CurrentModule.dontSort then
		sort(SUGpreTable, SUG.CurrentModule:Table_GetSorter())
	end

	local i = 1
	local InvalidEntries = rawget(SUG.CurrentModule, "InvalidEntries")
	if not InvalidEntries then
		SUG.CurrentModule.InvalidEntries = {}
		InvalidEntries = SUG.CurrentModule.InvalidEntries
	end

	for id = 1, numFramesNeeded do
		SUG:GetFrame(id)
	end
	
	while SUG[i] do
		local id
		while true do
		
			-- Here is how this horrifying line of code works:
			-- numSuggestionsWithoutFrames = #SUGpreTable - numFramesNeeded
			-- numSuggestionsWithoutFramesPlusOneBlankAtEnd = numSuggestionsWithoutFrames + 1
			-- numSuggestionsWithoutFramesPlusOneBlankAtEnd shouldn't be less than zero
			-- the offset can't be more than the numSuggestionsWithoutFramesPlusOneBlankAtEnd
			SUG.offset = min(SUG.offset, max(0, #SUGpreTable-numFramesNeeded+1))
			
			local key = i + SUG.offset
			id = SUGpreTable[key]
			
			if not id then
				break
			end
			if InvalidEntries[id] == nil then
				InvalidEntries[id] = not SUG.CurrentModule:Entry_IsValid(id)
			end
			if InvalidEntries[id] then
				tremove(SUGpreTable, key)
			else
				break
			end
		end

		local f = SUG[i]

		f.insert = nil
		f.insert2 = nil
		f.tooltipmethod = nil
		f.tooltiparg = nil
		f.tooltiptitle = nil
		f.tooltiptext = nil
		f.tooltiptext = nil
		f.overrideInsertID = nil
		f.overrideInsertName = nil
		f.Background:SetVertexColor(0, 0, 0, 0)

		if SUG.CurrentModule.noTexture then
			f.Icon:SetWidth(0.00001)
		else
			f.Icon:SetWidth(f.Icon:GetHeight())
		end

		if id and i <= numFramesNeeded then
			local addFunc = 1
			while true do
				local Entry_AddToList = SUG.CurrentModule["Entry_AddToList_" .. addFunc]
				if not Entry_AddToList then
					break
				end

				Entry_AddToList(SUG.CurrentModule, f, id)

				if f.insert then
					break
				end

				addFunc = addFunc + 1
			end

			local colorizeFunc = 1
			while true do
				local Entry_Colorize = SUG.CurrentModule["Entry_Colorize_" .. colorizeFunc]
				if not Entry_Colorize then
					break
				end

				Entry_Colorize(SUG.CurrentModule, f, id)

				colorizeFunc = colorizeFunc + 1
			end

			f:Show()
		else
			f:Hide()
		end
		i=i+1
	end

	if SUG.mousedOver then
		SUG.mousedOver:GetScript("OnEnter")(SUG.mousedOver)
	end
end

function SUG:NameOnCursor(isClick)
	if SUG.IsCaching then
		SUG.onCompleteCache = true
		SUG.Suggest:Show()
		return
	end
	SUG.oldLastName = SUG.lastName
	local text = SUG.Box:GetText()

	SUG.startpos = 0
	for i = SUG.Box:GetCursorPosition(), 0, -1 do
		if strsub(text, i, i) == ";" then
			SUG.startpos = i+1
			break
		end
	end

	if isClick then
		SUG.endpos = #text
		for i = SUG.startpos, #text do
			if strsub(text, i, i) == ";" then
				SUG.endpos = i-1
				break
			end
		end
	else
		SUG.endpos = SUG.Box:GetCursorPosition()
	end


	SUG.lastName = strlower(TMW:CleanString(strsub(text, SUG.startpos, SUG.endpos)))

	if strfind(SUG.lastName, ":[%d:%s%.]*$") then
		SUG.lastName, SUG.duration = strmatch(SUG.lastName, "(.-):([%d:%s%.]*)$")
		SUG.duration = strtrim(SUG.duration, " :;.")
		if SUG.duration == "" then
			SUG.duration = nil
		end
	else
		SUG.duration = nil
	end

	if not TMW.debug then
		-- do not escape the almighty wildcards if testing
		SUG.lastName = gsub(SUG.lastName, "([%*%.])", "%%%1")
	end
	-- always escape parentheses, brackets, percent signs, minus signs, plus signs
	SUG.lastName = gsub(SUG.lastName, "([%(%)%%%[%]%-%+])", "%%%1")

	if TMW.db.profile.SUG_atBeginning then
		SUG.atBeginning = "^" .. SUG.lastName
	else
		SUG.atBeginning = SUG.lastName
	end


	if not SUG.CurrentModule.noMin and (SUG.lastName == "" or not strfind(SUG.lastName, "[^%.]")) then
		SUG.Suggest:Hide()
		return
	else
		SUG.Suggest:Show()
	end

	if SUG.updatePlayerSpells then
		wipe(SUGPlayerSpells)
		for k, v in pairs(pclassSpellCache) do
			SUGPlayerSpells[k] = 1
		end
		for k, v in pairs(TMW.ClassSpellCache.PET) do
			if v == pclass then
				SUGPlayerSpells[k] = 1
			end
		end
		local _, race = UnitRace("player")
		for k, v in pairs(TMW.ClassSpellCache.RACIAL) do
			if v == race then
				SUGPlayerSpells[k] = 1
			end
		end
		SUG.updatePlayerSpells = nil
	end

	SUG.inputType = type(tonumber(SUG.lastName) or SUG.lastName)
	SUGIsNumberInput = SUG.inputType == "number"

	if SUG.oldLastName ~= SUG.lastName or SUG.redoIfSame then
		SUG.redoIfSame = nil

		SUG.offset = 0
		SUG:DoSuggest()
	end

end


---------- Item/Action Caching ----------
function SUG:CacheItems()
	if not SUG.doUpdateItemCache then return end

	wipe(CurrentItems)

	for container = -2, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(container) do
			local id = GetContainerItemID(container, slot)
			if id then
				local name = GetItemInfo(id)
				name = name and strlower(name)

				CurrentItems[id] = name
				ItemCache[id] = name
			end
		end
	end

	for slot = 1, 19 do
		local id = GetInventoryItemID("player", slot)
		if id then
			local name = GetItemInfo(id)
			name = name and strlower(name)

			CurrentItems[id] = name
			ItemCache[id] = name
		end
	end

	for id, name in pairs(CurrentItems) do
		CurrentItems[name] = id
	end

	SUG.doUpdateItemCache = nil
end

function SUG:BuildClassSpellLookup()
	SUG.ClassSpellLength = SUG.ClassSpellLength or {}
	SUG.ClassSpellLookup = SUG.ClassSpellLookup or {}
	for class, tbl in pairs(TMW.ClassSpellCache) do
		SUG.ClassSpellLength[class] = 0
		for id in pairs(tbl) do
			SUG.ClassSpellLookup[id] = 1
			SUG.ClassSpellLength[class] = SUG.ClassSpellLength[class] + 1
		end
	end
end


---------- Editbox Hooking ----------
local EditboxHooks = {
	OnEditFocusLost = function(self)
		if self.SUG_Enabled then
			SUG.Suggest:Hide()
		end
	end,
	OnEditFocusGained = function(self)
		if self.SUG_Enabled then
			local newModule = SUG:GetModule(self.SUG_type)
			SUG.redoIfSame = SUG.CurrentModule ~= newModule
			SUG.Box = self
			SUG.CurrentModule = newModule
			SUG.Suggest.Header:SetText(SUG.CurrentModule.headerText)
			SUG:NameOnCursor()
		end
	end,
	OnTextChanged = function(self, userInput)
		if userInput and self.SUG_Enabled then
			SUG.redoIfSame = nil
			SUG:NameOnCursor()
		end
	end,
	OnMouseUp = function(self)
		if self.SUG_Enabled then
			SUG:NameOnCursor(1)
		end
	end,
	OnTabPressed = function(self)
		if self.SUG_Enabled and SUG[1] and SUG[1].insert and SUG[1]:IsVisible() and not SUG.CurrentModule.noTab then
			SUG[1]:Click("LeftButton")
		end
	end,
}
function SUG:EnableEditBox(editbox, inputType, onlyOneEntry)
	editbox.SUG_Enabled = 1

	inputType = get(inputType)
	inputType = (inputType == true and "spell") or inputType
	if not inputType then
		return SUG:DisableEditBox(editbox)
	end
	editbox.SUG_type = inputType
	editbox.SUG_onlyOneEntry = onlyOneEntry

	if not editbox.SUG_hooked then
		for k, v in pairs(EditboxHooks) do
			editbox:HookScript(k, v)
		end
		editbox.SUG_hooked = 1
	end

	if editbox:HasFocus() then
		EditboxHooks.OnEditFocusGained(editbox) -- force this to rerun becase we may be calling from within the editbox's script
	end
end

function SUG:DisableEditBox(editbox)
	editbox.SUG_Enabled = nil
end


---------- Miscellaneous ----------
function SUG:ColorHelp(frame)
	GameTooltip_SetDefaultAnchor(GameTooltip, frame)
	GameTooltip:AddLine(SUG.CurrentModule.helpText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	if SUG.CurrentModule.showColorHelp then
		GameTooltip:AddLine(L["SUG_DISPELTYPES"], 1, .49, .04, 1)
		GameTooltip:AddLine(L["SUG_BUFFEQUIVS"], .2, .9, .2, 1)
		GameTooltip:AddLine(L["SUG_DEBUFFEQUIVS"], .77, .12, .23, 1)
		GameTooltip:AddLine(L["SUG_OTHEREQUIVS"], 1, .96, .41, 1)
		GameTooltip:AddLine(L["SUG_MSCDONBARS"], 0, .44, .87, 1)
		GameTooltip:AddLine(L["SUG_PLAYERSPELLS"], .41, .8, .94, 1)
		GameTooltip:AddLine(L["SUG_CLASSSPELLS"], .96, .55, .73, 1)
		GameTooltip:AddLine(L["SUG_PLAYERAURAS"], .79, .30, 1, 1)
		GameTooltip:AddLine(L["SUG_NPCAURAS"], .78, .61, .43, 1)
		GameTooltip:AddLine(L["SUG_MISC"], .58, .51, .79, 1)
	end
	GameTooltip:Show()
end

function SUG:GetNumFramesNeeded()
	return floor(TMW.SUG.Suggest:GetHeight()/TMW.SUG[1]:GetHeight()) - 2
end

function SUG:GetFrame(id)
	local Suggest = TMW.SUG.Suggest
	if TMW.SUG[id] then
		return TMW.SUG[id]
	end
	
	local f = CreateFrame("Button", Suggest:GetName().."Item"..id, Suggest, "TellMeWhen_SpellSuggestTemplate", id)
	TMW.SUG[id] = f
	f:SetWidth(Suggest:GetWidth()-20)
	
	if TMW.SUG[id-1] then
		f:SetPoint("TOP", TMW.SUG[id-1], "BOTTOM", 0, 0)
	end
	
	return f
end

---------- Suggester Modules ----------
local Module = SUG:NewModule("default")
Module.headerText = L["SUGGESTIONS"]
Module.helpText = L["SUG_TOOLTIPTITLE"]
Module.showColorHelp = true
function Module:Table_Get()
	return SpellCache
end
function Module.Sorter_ByName(a, b)
	local nameA, nameB = SUG.SortTable[a], SUG.SortTable[b]
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end
function Module:Table_GetSorter()
	if SUG.inputType == "number" then
		return nil -- use the default sort func
	else
		SUG.SortTable = self:Table_Get()
		return self.Sorter_ByName
	end
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for id in pairs(tbl) do
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	else
		for id, name in pairs(tbl) do
			if strfind(name, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
end
function Module:Table_GetEquivSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName
	local semiLN = ";" .. lastName
	local long = #lastName > 2

	for _, tbl in TMW:Vararg(...) do
		for equiv in pairs(tbl) do
			if 	(long and (
					(strfind(strlowerCache[equiv], lastName)) or
					(strfind(strlowerCache[L[equiv]], lastName)) or
					(not SUGIsNumberInput and strfind(strlowerCache[EquivFullNameLookup[equiv]], semiLN)) or
					(SUGIsNumberInput and strfind(EquivFullIDLookup[equiv], semiLN))
			)) or
				(not long and (
					(strfind(strlowerCache[equiv], atBeginning)) or
					(strfind(strlowerCache[L[equiv]], atBeginning))
			)) then
				suggestions[#suggestions + 1] = equiv
			end
		end
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)

end
function Module:Entry_OnClick(frame, button)
	local insert
	if button == "RightButton" and frame.insert2 then
		insert = frame.insert2
	else
		insert = frame.insert
	end
	self:Entry_Insert(insert)
end
function Module:Entry_Insert(insert)
	if insert then
		insert = tostring(insert)
		if SUG.Box.SUG_onlyOneEntry then
			SUG.Box:SetText(TMW:CleanString(insert))
			SUG.Box:ClearFocus()
			return
		end

		-- determine the text before an after where we will be inserting to
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
		local lasthalf = strsub(currenttext, SUG.endpos+1)


		-- DURATION STUFF:
		-- determine if we should add a colon to the inserted text. a colon should be added if:
			-- one existed before (the user clicked on a spell with a duration defined or already typed it in)
			-- the module requests (requires) one
		local doAddColon = SUG.duration or SUG.CurrentModule.doAddColon

		-- determine if there is an actual duration to be added to the inserted spell
		local hasDurationData = SUG.duration

		if doAddColon then
		-- the entire text to be inserted in
			insert = insert .. ": " .. (hasDurationData or "")
		end


		-- the entire text with the insertion added in
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf
		-- clean it up
		SUG.Box:SetText(TMW:CleanString(newtext))

		-- put the cursor after the newly inserted text
		local _, newPos = SUG.Box:GetText():find(insert:gsub("([%(%)%%%[%]%-%+%.%*])", "%%%1"), max(0, SUG.startpos-1))
		if newPos then
			SUG.Box:SetCursorPosition(newPos + 2)
		end

		-- if we are at the end of the editbox then put a semicolon in anyway for convenience
		if SUG.Box:GetCursorPosition() == #SUG.Box:GetText() then
			local append = "; "
			if doAddColon then
				append = (not hasDurationData and " " or "") .. append
			end
			SUG.Box:SetText(SUG.Box:GetText() .. append)
		end

		-- if we added a colon but there was no duration information inserted, move the cursor back 2 characters so the user can type it in quickly
		if doAddColon and not hasDurationData then
			SUG.Box:SetCursorPosition(SUG.Box:GetCursorPosition() - 2)
		end

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end
function Module:Entry_IsValid(id)
	return true
end

--[==[
local Module = SUG:NewModule("textsubs", SUG:GetModule("default"))
Module.headerText = L["SUGGESTIONS_SUBSTITUTIONS"]
Module.helpText = L["SUG_TOOLTIPTITLE_TEXTSUBS"]
Module.showColorHelp = false
Module.dontSort = true
Module.noMin = true
Module.noTexture = true
Module.noTab = true
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	suggestions[#suggestions + 1] = "d" -- Duration

	local typeData = Types[CI.ics.Type]

	if not typeData.EventDisabled_OnUnit then
		suggestions[#suggestions + 1] = "u" -- current Unit
		suggestions[#suggestions + 1] = "p" -- Previous unit
	end
	if not typeData.EventDisabled_OnSpell then
		suggestions[#suggestions + 1] = "s" -- Spell
	end
	if not typeData.EventDisabled_OnStack then
		suggestions[#suggestions + 1] = "k" -- stacK
	end

	if CI.ics.Type == "cleu" then
		for _, letter in TMW:Vararg("o", "e", "x") do -- sOurceunit, dEstunit, eXtraspell
			suggestions[#suggestions + 1] = letter
		end
	end
end
function Module:Entry_Insert(insert)
	if insert then
		insert = tostring(insert)
		SUG.Box:Insert(insert)

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end
function Module:Entry_AddToList_1(f, letter)
	--f.Name:SetText(L["SUG_SUBSTITUTION_" .. letter])
	f.Name:SetText("THE TEXTSUBS SUG MODULE IS DEPRECIATED. WHY IS IT STILL BEING USED?")
	--f.ID:SetText("%" .. letter)
--
	f.insert = ""--"%" .. letter
	--f.overrideInsertName = L["SUG_INSERTTEXTSUB"]

--	f.tooltiptitle = L["SUG_SUBSTITUTION_" .. letter]
--	f.tooltiptext = L["SUG_SUBSTITUTION_" .. letter .. "_DESC"]

--	f.Icon:SetTexture(GetItemIcon(id))
end


local Module = SUG:NewModule("textsubsANN", SUG:GetModule("textsubs"))
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	for _, letter in TMW:Vararg("t", "f", "m") do -- Target, Focus, Mouseover
		suggestions[#suggestions + 1] = letter
	end
end


local Module = SUG:NewModule("textsubsANNWhisper", SUG:GetModule("textsubsANN"))
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local typeData = Types[CI.ics.Type]

	if not typeData.EventDisabled_OnUnit then
		suggestions[#suggestions + 1] = "u" -- current Unit
		suggestions[#suggestions + 1] = "p" -- Previous unit
	end

	if CI.ics.Type == "cleu" then
		suggestions[#suggestions + 1] = "o" -- sOurceunit
		suggestions[#suggestions + 1] = "e" -- dEstunit
	end
end
]==]

local Module = SUG:NewModule("item", SUG:GetModule("default"))
function Module:Table_Get()
	SUG:CacheItems()

	return ItemCache
end
function Module:Entry_AddToList_1(f, id)
	if id > INVSLOT_LAST_EQUIPPED then
		local name, link = GetItemInfo(id)

		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText(id)

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(id))
	end
end


local Module = SUG:NewModule("itemwithslots", SUG:GetModule("item"))
Module.Slots = {}
function Module:Entry_AddToList_2(f, id)
	if id <= INVSLOT_LAST_EQUIPPED then
		local itemID = GetInventoryItemID("player", id) -- get the itemID of the slot
		local link = GetInventoryItemLink("player", id)

		f.overrideInsertID = L["SUG_INSERTITEMSLOT"]

		local name = GetItemInfo(itemID)

		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText("(" .. id .. ")")

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(itemID))
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local itemID = GetInventoryItemID("player", i) -- get the itemID of the slot
		self.Slots[i] = itemID and GetItemInfo(itemID)
	end

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for id in pairs(self.Slots) do
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	else
		for id, name in pairs(self.Slots) do
			if strfind(strlower(name), atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
end
function Module:Entry_Colorize_1(f, id)
	if id <= INVSLOT_LAST_EQUIPPED then
		f.Background:SetVertexColor(.58, .51, .79, 1) -- color item slots warlock purple
	end
end
function Module.Sorter_ByName(a, b)
	local haveA, haveB = Module.Slots[a], Module.Slots[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	local nameA, nameB = ItemCache[a], ItemCache[b]
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end


local Module = SUG:NewModule("spell", SUG:GetModule("default"))
function Module:Table_Get()
	return SpellCache
end
function Module.Sorter_Spells(a, b)
	if a == "GCD" or b == "GCD" then
		return a == "GCD"
	end

	local haveA, haveB = EquivFirstIDLookup[a], EquivFirstIDLookup[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	--player's spells (pclass)
	local haveA, haveB = SUGPlayerSpells[a], SUGPlayerSpells[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	--all player spells (any class)
	local haveA, haveB = ClassSpellLookup[a], ClassSpellLookup[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	elseif not (haveA or haveB) then

		local haveA, haveB = AuraCache[a], AuraCache[b] -- Auras
		if haveA and haveB and haveA ~= haveB then -- if both are auras (kind doesnt matter) AND if they are different aura types, then compare the types
			return haveA > haveB -- greater than is intended.. player auras are 2 while npc auras are 1, player auras should go first
		elseif (haveA and not haveB) or (haveB and not haveA) then --otherwise, if only one of them is an aura, then prioritize the one that is an aura
			return haveA
		end
		--if they both were auras, and they were auras of the same type (player, NPC) then procede on to the rest of the code to sort them by name/id
	end

	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = SpellCache[a], SpellCache[b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		elseif nameA and nameB then
			--sort by name
			return nameA < nameB
		else
			return nameA
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Spells
end
function Module:Entry_AddToList_1(f, id)
	if tonumber(id) then --sanity check
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.Icon:SetTexture(SpellTextures[id])
	end
end
function Module:Entry_Colorize_1(f, id)
	if SUGPlayerSpells[id] then
		f.Background:SetVertexColor(.41, .8, .94, 1) --color all other spells that you have in your/your pet's spellbook mage blue
		return
	else
		for class, tbl in pairs(TMW.ClassSpellCache) do
			if tbl[id] then
				f.Background:SetVertexColor(.96, .55, .73, 1) --color all other known class spells paladin pink
				return
			end
		end
	end

	local whoCasted = SUG.AuraCache[id]
	if whoCasted == 1 then
		f.Background:SetVertexColor(.78, .61, .43, 1) -- color known NPC auras warrior brown
	elseif whoCasted == 2 then
		f.Background:SetVertexColor(.79, .30, 1, 1) -- color known PLAYER auras a bright pink ish pruple ish color that is similar to paladin pink but has sufficient contrast for distinguishing
	end
end


local Module = SUG:NewModule("talents", SUG:GetModule("spell"))
Module.noMin = true
Module.table = {}
function Module:OnInitialize()
	if TMW.ISMOP then
		for talent = 1, MAX_NUM_TALENTS do
			local name = GetTalentInfo(talent)
			local lower = name and strlowerCache[name]
			if lower then
				self.table[lower] = talent
			end
		end
	else
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				local name, tex = GetTalentInfo(tab, talent)
				local lower = name and strlowerCache[name]
				if lower then
					self.table[lower] = {tab, talent, tex}
				end
			end
		end
	end
end
function Module:Table_Get()
	return self.table
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, name)
	if TMW.ISMOP then
		local talent = self.table[name]
		local name, tex = GetTalentInfo(talent) -- restore case

		f.Name:SetText(name)

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = GetTalentLink(talent)

		f.insert = name

		f.Icon:SetTexture(tex)
	else
		local data = self.table[name]
		name = GetTalentInfo(data[1], data[2]) -- restore case

		f.Name:SetText(name)

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = GetTalentLink(data[1], data[2])

		f.insert = name

		f.Icon:SetTexture(data[3])
	end
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for name in pairs(tbl) do
		if strfind(name, atBeginning) then
			suggestions[#suggestions + 1] = name
		end
	end
end


local Module = SUG:NewModule("glyphs", SUG:GetModule("default"))
Module.noMin = true
Module.table = {}
function Module:OnInitialize()
	for i = 1, GetNumGlyphs() do
		local type, _, _, _, glyphID, link = GetGlyphInfo(i)
		if type ~= "header" then
			local _, name = strmatch(link, "|Hglyph:(%d+)|h%[(.*)%]|h|r")
			name = strlowerCache[name]
			self.table[i] = name
		end
	end
end
function Module:Table_Get()
	return self.table
end
function Module:Entry_AddToList_1(f, index)
	local _, _, _, texture, glyphID, link = GetGlyphInfo(index)
	local _, name = strmatch(link, "|Hglyph:(%d+)|h%[(.*)%]|h|r")

	f.Name:SetText(name)
	f.ID:SetText(glyphID)

	f.tooltipmethod = "SetGlyphByID"
	f.tooltiparg = glyphID

	f.insert = SUG.inputType == "number" and glyphID or name
	f.insert2 = SUG.inputType ~= "number" and glyphID or name

	f.Icon:SetTexture(texture)
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for index, name in pairs(tbl) do
			local _, _, _, _, id = GetGlyphInfo(index)
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = index
			end
		end
	else
		for index, name in pairs(tbl) do
			-- name here is Glyph of Fancy Spell
			if strfind(name, atBeginning) then
				suggestions[#suggestions + 1] = index
			else
			
				-- name here is Fancy Spell
				name = GetGlyphInfo(index)
				name = strlowerCache[name]
				if strfind(name, atBeginning) then
					suggestions[#suggestions + 1] = index
				end
			end
		end
	end
end
function Module.Sorter_Glyphs(a, b)
	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = Module.table[a], Module.table[b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Glyphs
end


local Module = SUG:NewModule("spellWithGCD", SUG:GetModule("spell"))
function Module:Table_GetSpecialSuggestions(suggestions)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName


	if strfind("gcd", atBeginning) or strfind(L["GCD"]:lower(), atBeginning) then
		suggestions[#suggestions + 1] = "GCD"
	end
end
function Module:Entry_AddToList_2(f, id)
	if id == "GCD" then
		local equiv = id
		id = TMW.GCDSpell --EquivFirstIDLookup[id]

		local name = GetSpellInfo(id)

		f.Name:SetText(L["GCD"])
		f.ID:SetText(nil)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = equiv

		f.Icon:SetTexture(SpellTextures[id])
	end
end
function Module:Entry_Colorize_2(f, id)
	if id == "GCD" then
		f.Background:SetVertexColor(.58, .51, .79, 1) -- color item slots warlock purple
	end
end


local Module = SUG:NewModule("texture", SUG:GetModule("spell"))
function Module:Entry_AddToList_1(f, id)
	if tonumber(id) then --sanity check
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = id
		if pclassSpellCache[id] and name and GetSpellTexture(name) then
			f.insert2 = name
		end

		f.Icon:SetTexture(SpellTextures[id])
	end
end


local Module = SUG:NewModule("spellwithduration", SUG:GetModule("spell"))
Module.doAddColon = true
local MATCH_RECAST_TIME_MIN, MATCH_RECAST_TIME_SEC
function Module:OnInitialize()
	MATCH_RECAST_TIME_MIN = SPELL_RECAST_TIME_MIN:gsub("%%%.3g", "([%%d%%.]+)")
	MATCH_RECAST_TIME_SEC = SPELL_RECAST_TIME_SEC:gsub("%%%.3g", "([%%d%%.]+)")
end
function Module:Entry_OnClick(f, button)
	local insert

	local spellID = f.tooltiparg
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3 = SUG:GetParser()
	Parser:SetOwner(UIParent, "ANCHOR_NONE")
	Parser:SetSpellByID(spellID)

	local dur

	for _, text in TMW:Vararg(RT2:GetText(), RT3:GetText()) do
		if text then

			local mins = text:match(MATCH_RECAST_TIME_MIN)
			local secs = text:match(MATCH_RECAST_TIME_SEC)
			if mins then
				dur = mins .. ":00"
			elseif secs then
				dur = secs
			end

			if dur then
				break
			end
		end
	end
	if spellID == 42292 then -- pvp trinket override
		dur = "2:00"
	end

	if button == "RightButton" and f.insert2 then
		insert = f.insert2
	else
		insert = f.insert
	end

	self:Entry_Insert(insert, dur)
end
function Module:Entry_Insert(insert, duration)
	if insert then
		insert = tostring(insert)
		if SUG.Box.SUG_onlyOneEntry then
			SUG.Box:SetText(TMW:CleanString(insert))
			SUG.Box:ClearFocus()
			return
		end

		-- determine the text before an after where we will be inserting to
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
		local lasthalf = strsub(currenttext, SUG.endpos+1)

		-- determine if we should add a colon to the inserted text. a colon should be added if:
			-- one existed before (the user clicked on a spell with a duration defined or already typed it in)
			-- the module requests (requires) one
		local doAddColon = SUG.duration or SUG.CurrentModule.doAddColon

		-- determine if there is an actual duration to be added to the inserted spell
		local hasDurationData = duration or SUG.duration

		-- the entire text to be inserted in
		local insert = (doAddColon and insert .. ": " .. (hasDurationData or "")) or insert

		-- the entire text with the insertion added in
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf


		SUG.Box:SetText(TMW:CleanString(newtext))

		-- put the cursor after the newly inserted text
		local _, newPos = SUG.Box:GetText():find(insert:gsub("([%(%)%%%[%]%-%+%.%*])", "%%%1"), max(0, SUG.startpos-1))
		newPos = newPos or #SUG.Box:GetText()
		SUG.Box:SetCursorPosition(newPos + 2)

		-- if we are at the end of the editbox then put a semicolon in anyway for convenience
		if SUG.Box:GetCursorPosition() == #SUG.Box:GetText() then
			SUG.Box:SetText(SUG.Box:GetText() .. (doAddColon and not hasDurationData and " " or "") .. "; ")
		end

		-- if we added a colon but there was no duration information inserted, move the cursor back 2 characters so the user can type it in quickly
		if doAddColon and not hasDurationData then
			SUG.Box:SetCursorPosition(SUG.Box:GetCursorPosition() - 2)
		end

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end


local Module = SUG:NewModule("cast", SUG:GetModule("spell"))
function Module:Table_Get()
	return SpellCache, TMW.BE.casts
end
function Module:Entry_AddToList_2(f, id)
	if TMW.BE.casts[id] then
		-- the entry is an equivalacy
		-- id is the equivalency name (e.g. Tier11Interrupts)
		local equiv = id
		id = EquivFirstIDLookup[equiv]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv
		f.overrideInsertName = L["SUG_INSERTEQUIV"]

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[id])
	end
end
function Module:Entry_Colorize_2(f, id)
	if TMW.BE.casts[id] then
		f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
	end
end
function Module:Entry_IsValid(id)
	if TMW.BE.casts[id] then
		return true
	end

	local _, _, _, _, _, _, castTime = GetSpellInfo(id)
	if not castTime then
		return false
	elseif castTime > 0 then
		return true
	end

	local Parser, LT1, LT2, LT3 = SUG:GetParser()

	Parser:SetOwner(UIParent, "ANCHOR_NONE") -- must set the owner before text can be obtained.
	Parser:SetSpellByID(id)

	if LT2:GetText() == SPELL_CAST_CHANNELED or LT3:GetText() == SPELL_CAST_CHANNELED then
		return true
	end
end


local Module = SUG:NewModule("multistate", SUG:GetModule("spell"))
Module.ActionCache = {}
function Module:Table_Get()
	wipe(self.ActionCache)
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID then
			self.ActionCache[spellID] = i
		end
	end

	return SpellCache
end
function Module:Entry_Colorize_2(f, id)
	if self.ActionCache[id] then
		f.Background:SetVertexColor(0, .44, .87, 1) --color actions that are on your action bars shaman blue
	end
end
function Module.Sorter_Spells(a, b)
	--MSCDs
	local haveA, haveB = Module.ActionCache[a], Module.ActionCache[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	--player's spells (pclass)
	local haveA, haveB = SUGPlayerSpells[a], SUGPlayerSpells[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	--all player spells (any class)
	local haveA, haveB = ClassSpellLookup[a], ClassSpellLookup[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	elseif not (haveA or haveB) then

		local haveA, haveB = AuraCache[a], AuraCache[b] -- Auras
		if haveA and haveB and haveA ~= haveB then -- if both are auras (kind doesnt matter) AND if they are different aura types, then compare the types
			return haveA > haveB -- greater than is intended.. player auras are 2 while npc auras are 1, player auras should go first
		elseif (haveA and not haveB) or (haveB and not haveA) then --otherwise, if only one of them is an aura, then prioritize the one that is an aura
			return haveA
		end
		--if they both were auras, and they were auras of the same type (player, NPC) then procede on to the rest of the code to sort them by name/id
	end

	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = SpellCache[a], SpellCache[b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Spells
end


local Module = SUG:NewModule("buff", SUG:GetModule("spell"))
function Module:Table_Get()
	return SpellCache, TMW.BE.buffs, TMW.BE.debuffs
end
function Module:Entry_Colorize_2(f, id)
	if TMW.DS[id] then
		f.Background:SetVertexColor(1, .49, .04, 1) -- druid orange
	elseif TMW.BE.buffs[id] then
		f.Background:SetVertexColor(.2, .9, .2, 1) -- lightish green
	elseif TMW.BE.debuffs[id] then
		f.Background:SetVertexColor(.77, .12, .23, 1) -- deathknight red
	end
end
function Module:Entry_AddToList_2(f, id)
	if TMW.DS[id] then -- if the entry is a dispel type (magic, poison, etc)
		local dispeltype = id

		f.Name:SetText(dispeltype)
		f.ID:SetText(nil)

		f.insert = dispeltype

		f.tooltiptitle = dispeltype
		f.tooltiptext = L["ICONMENU_DISPEL"]

		f.Icon:SetTexture(TMW.DS[id])

	elseif EquivFirstIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
		--NOTE: dispel types are put in EquivFirstIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
		local equiv = id
		local firstid = EquivFirstIDLookup[id]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv
		f.overrideInsertName = L["SUG_INSERTEQUIV"]

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[firstid])
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for dispeltype in pairs(TMW.DS) do
		if strfind(strlowerCache[dispeltype], atBeginning) or strfind(strlowerCache[L[dispeltype]], atBeginning)  then
			suggestions[#suggestions + 1] = dispeltype
		end
	end
end

local Module = SUG:NewModule("cleu", SUG:GetModule("buff"))
function Module:Table_Get()
	return SpellCache, TMW.BE.buffs, TMW.BE.debuffs, TMW.BE.casts
end
function Module:Entry_Colorize_3(f, id)
	if TMW.BE.casts[id] then
		f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
end




local Module = SUG:NewModule("dr", SUG:GetModule("spell"))
function Module:Table_Get()
	return SpellCache, TMW.BE.dr
end
function Module:Entry_Colorize_2(f, id)
	if TMW.BE.dr[id] then
		f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
	end
end
function Module:Entry_AddToList_2(f, id)
	if EquivFirstIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
		--NOTE: dispel types are put in EquivFirstIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
		local equiv = id
		local firstid = EquivFirstIDLookup[id]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv
		f.overrideInsertName = L["SUG_INSERTEQUIV"]

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[firstid])
	end
end


local Module = SUG:NewModule("wpnenchant", SUG:GetModule("default"), "AceEvent-3.0")
Module.noMin = true
Module.ItemIDs = {
	-- item enhancements
	43233,	--Deadly Poison
	3775,	--Crippling Poison
	5237,	--Mind-Numbing Poison
	43235,	--Wound Poison
	43231,	--Instant Poison

	31535,	--Bloodboil Poison

	3829,	--Frost Oil
	3824,	--Shadow Oil -- good

	36899,	--Exceptional Mana Oil
	22521,	--Superior Mana Oil -- good
	20748,	--Brilliant Mana Oil -- good
	20747,	--Lesser Mana Oil -- good
	20745,	--Minor Mana Oil -- good

	22522,	--Superior Wizard Oil -- good
	20749,	--Brilliant Wizard Oil -- good
	20750,	--Wizard Oil -- good
	20746,	--Lesser Wizard Oil -- good
	20744,	--Minor Wizard Oil -- good


	34539,	--Righteous Weapon Coating
	34538,	--Blessed Weapon Coating

	--23123,	--Blessed Wizard Oil

	--23576,	--Greater Ward of Shielding
	--23575,	--Lesser Ward of Shielding

	--25521,	--Greater Rune of Warding
	--23559,	--Lesser Rune of Warding

	--7307,	--Flesh Eating Worm

	--46006,	--Glow Worm
	--6529,	--Shiny Bauble
	--6532,	--Bright Baubles
	--67404,	--Glass Fishing Bobber
	--69907,	--Corpse Worm
	--62673,	--Feathered Lure
	--34861,	--Sharpened Fish Hook
	--6533,	--Aquadynamic Fish Attractor
	--6530,	--Nightcrawlers
	--68049,	--Heat-Treated Spinning Lure
	--6811,	--Aquadynamic Fish Lens

	--12643,	--Dense Weightstone
	--3241,	--Heavy Weightstone
	--7965,	--Solid Weightstone
	--3240,	--Coarse Weightstone
	--28420,	--Fel Weightstone
	--28421,	--Adamantite Weightstone
	--3239,	--Rough Weightstone

	--23529,	--Adamantite Sharpening Stone
	--7964,	--Solid Sharpening Stone
	--23122,	--Consecrated Sharpening Stone
	--2871,	--Heavy Sharpening Stone
	--23528,	--Fel Sharpening Stone
	--2862,	--Rough Sharpening Stone
	--2863,	--Coarse Sharpening Stone
	--12404,	--Dense Sharpening Stone
	--18262,	--Elemental Sharpening Stone

	-- ZHTW:
	-- weightstone: 平衡石
	-- sharpening stone: 磨刀石
	--25679,	--Comfortable Insoles
}
Module.SpellIDs = {
	-- Shaman Enchants
	8024,	--Flametongue Weapon
	8033,	--Frostbrand Weapon
	8232,	--Windfury Weapon
	51730,	--Earthliving Weapon
	8017,	--Rockbiter Weapon
}
function Module:OnInitialize()
	self.Items = {}
	self.Spells = {}
	self.Table = {}
	self.SpellLookup = {}


	self:Etc_DoItemLookups()

	for k, id in pairs(self.SpellIDs) do
		local name = GetSpellInfo(id)
		for _, enchant in TMW:Vararg(strsplit("|", L["SUG_MATCH_WPNENCH_ENCH"])) do
			local dobreak
			enchant = name:match(enchant)
			if enchant then
				for ench in pairs(TMW.db.global.WpnEnchDurs) do
					if ench:lower():find(enchant:gsub("([%%%[%]%-%+])", "%%%1"):lower()) then
						-- the enchant was found in the list of known enchants, so add it
						self.Spells[ench] = id
						dobreak = 1
						break
					end
				end
				if dobreak then
					break
				elseif GetLocale() ~= "ruRU" or (GetLocale() == "koKR" and id ~= 51730) then
					-- the enchant was not found in the list of known enchants, so take a guess and add it (but not for ruRU because it is just screwed up
					-- koKR is screwed up for earthliving, so dont try it either
					self.Spells[enchant] = id
				end
			end
		end
	end

	for k, v in pairs(self.Spells) do
		if self.Table[k] then
			TMW:Error("Attempted to add spellID %d, but an item already has that id.", k)
		else
			self.Table[k] = v
		end
	end

	for k, v in pairs(TMW.db.global.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end

	for name in pairs(self.Table) do
		self:Etc_GetTexture(name) -- cache textures for the spell breakdown tooltip
	end
end
function Module:Etc_DoItemLookups()
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")

	for k, id in pairs(self.ItemIDs) do
		local name = GetItemInfo(id)
		if name then
			self.Items[name] = id
		else
			self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "Etc_DoItemLookups")
		end
	end

	for k, v in pairs(self.Items) do
		self.Table[k] = v
	end
end
function Module:Table_Get()
	SUG:CacheItems()

	for k, v in pairs(TMW.db.global.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end

	return self.Table
end
function Module:Entry_AddToList_1(f, name)
	if self.Spells[name] then
		local id = self.Spells[name]
		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = name
	elseif self.Items[name] then
		local id = CurrentItems[strlowerCache[name]] or self.Items[name]
		local name, link = GetItemInfo(id)

		f.Name:SetText(link:gsub("[%[%]]", ""))
		f.ID:SetText(nil)

		f.insert = name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link
	else
		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltiptitle = name

		f.insert = name
	end

	f.Icon:SetTexture(self:Etc_GetTexture(name))
end
function Module:Etc_GetTexture(name)
	local tex
	if self.Spells[name] then
		tex = SpellTextures[self.Spells[name]]
	elseif self.Items[name] then
		tex = GetItemIcon(self.Items[name])
	else
		if name:match(L["SUG_PATTERNMATCH_FISHINGLURE"]) then
			tex = "Interface\\Icons\\inv_fishingpole_02"
		elseif name:match(L["SUG_PATTERNMATCH_WEIGHTSTONE"]) then
			tex = "Interface\\Icons\\inv_stone_weightstone_02"
		elseif name:match(L["SUG_PATTERNMATCH_SHARPENINGSTONE"]) then
			tex = "Interface\\Icons\\inv_stone_sharpeningstone_01"
		end
	end

	name = strlower(name)
	SpellTextures[name] = SpellTextures[name] or tex

	return tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end
function Module.Sorter(a, b)
	local haveA = Module.Spells[a] and SUGPlayerSpells[Module.Spells[a]]
	local haveB = Module.Spells[b] and SUGPlayerSpells[Module.Spells[b]]

	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	local haveA = Module.Items[a] and (CurrentItems[ strlowerCache[ a ]] )
	local haveB = Module.Items[b] and (CurrentItems[ strlowerCache[ b ]] )

	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	-- its a very small table to sort, so i can get away with this
	local haveA = rawget(TMW.db.global.WpnEnchDurs, a)
	local haveB = rawget(TMW.db.global.WpnEnchDurs, b)
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end


	local nameA, nameB = Module.Table[a], Module.Table[b]

	if a == b then
		--sort identical names by ID
		return Module.Table[a] < Module.Table[b]
	else
		--sort by name
		return a < b
	end

end
function Module:Table_GetSorter()
	SUG.doUpdateItemCache = true
	SUG:CacheItems()
	return self.Sorter
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for name, id in pairs(tbl) do
		if SUG.inputType == "number" or strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = name
		end
	end
end
function Module:Entry_Colorize_1(f, name)
	if SUGPlayerSpells[Module.Spells[name]] or (CurrentItems[ strlowerCache[ name ]]) then
		f.Background:SetVertexColor(.41, .8, .94, 1) --color all spells and items that you have mage blue
	elseif rawget(TMW.db.global.WpnEnchDurs, name) then
		f.Background:SetVertexColor(.79, .30, 1, 1) -- color all known weapon enchants purple
	end
end


local Module = SUG:NewModule("tracking", SUG:GetModule("default"))
Module.noMin = true
function Module:Table_Get()
	return TrackingCache
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, id)
	local name, texture = GetTrackingInfo(id)

	f.Name:SetText(name)
	f.ID:SetText(nil)

	f.insert = name

	f.Icon:SetTexture(texture)
end




-- -----------------------
-- HELP
-- -----------------------


HELP = TMW:NewModule("Help", "AceTimer-3.0") TMW.HELP = HELP

HELP.Codes = {
	"ICON_POCKETWATCH_FIRSTSEE",

	"ICON_DURS_FIRSTSEE",
	"ICON_DURS_MISSING",

	"ICON_IMPORT_CURRENTPROFILE",
	"ICON_EXPORT_DOCOPY",

	"ICON_DR_MISMATCH",
	"ICON_MS_NOTFOUND",
	"ICON_ICD_NATURESGRACE",

	"ICON_UNIT_MISSING",

	"CNDT_UNIT_MISSING",
	"CNDT_PARENTHESES_ERROR",

	"SND_INVALID_CUSTOM",
}

HELP.OnlyOnce = {
	ICON_DURS_FIRSTSEE = true,
	ICON_POCKETWATCH_FIRSTSEE = true,
	ICON_IMPORT_CURRENTPROFILE = true,
	ICON_EXPORT_DOCOPY = true,
}

function HELP:OnInitialize()
	HELP.Frame = IE.Help
	HELP.Queued = {}
end


---------- External Usage ----------
function HELP:Show(code, icon, frame, x, y, text, ...)
	-- handle the code, determine the ID of the code.
	assert(type(code) == "string")
	local codeID
	for i, c in pairs(HELP.Codes) do
		if c == code then
			codeID = i
			break
		end
	end
	assert(codeID, format("Code %q is not defined", code))
	-- we can now safely proceded to process and queue the help

	-- retrieve or create the data table
	local help = wipe(HELP.Queued[code] or {})

	-- add the text format args to the data
	for i = 1, select('#', ...) do
		help[i] = select(i, ...)
	end
	-- add other data
	help.code = code
	help.codeID = codeID
	help.icon = icon
	help.frame = frame
	help.x = x
	help.y = y
	help.text = text
	-- if the frame has the CreateTexture method, then it can be made the parent.
	-- Otherwise, the frame is actually a texture/font/etc object, so set its parent as the parent.
	help.parent = help.frame.CreateTexture and help.frame or help.frame:GetParent()

	-- determine if the code has a setting associated to only show it once.
	help.setting = HELP.OnlyOnce[code] and code

	-- if it does and it has already been set true, then we dont need to show anything, so quit.
	if help.setting and TMW.db.global.HelpSettings[help.setting] then
		HELP.Queued[code] = nil
		help = nil
		return
	end

	-- if the code is the same as what is currently shown, then replace what is currently being shown.
	if HELP.showingHelp and HELP.showingHelp.code == code then
		HELP.showingHelp = nil
	end

	-- everything should be in order, so add the help to the queue.
	HELP:Queue(help)

	-- notify that this help will eventually be shown
	return 1
end

function HELP:Hide(code)
	if HELP.Queued[code] then
		HELP.Queued[code] = nil
	elseif HELP.showingHelp and HELP.showingHelp.code == code then
		HELP.showingHelp = nil
		HELP:ShowNext()
	end
end

function HELP:GetShown()
	return HELP.showingHelp and HELP.showingHelp.code
end

function HELP:NewCode(code, order, OnlyOnce)
	assert(code, "HELP:NewCode() - arg1 must be a string, not nil.")
	assert(not TMW.tContains(HELP.Codes, code), "HELP code " .. code .. " is already registered!")
	
	if order then
		tinsert(HELP.Codes, order, code)
	else
		tinsert(HELP.Codes, code)
	end
	
	if OnlyOnce then
		HELP.OnlyOnce[code] = true
	end
end

---------- Queue Management ----------
function HELP:Queue(help)
	-- add the help to the queue
	HELP.Queued[help.code] = help

	-- notify the engine to start
	HELP:ShowNext()
end

function HELP:OnClose()
	HELP.showingHelp = nil
	HELP:ShowNext()
end

function HELP:ShouldShowHelp(help)
	if help.icon and not help.icon:IsBeingEdited() then
		return false
	elseif not help.parent:IsVisible() then
		return false
	end
	return true
end

function HELP:ShowNext()
	-- if there nothing currently being displayed, hide the frame.
	if not HELP.showingHelp then
		HELP.Frame:Hide()
	end

	-- if we are already showing something, then don't overwrite it.
	if HELP.showingHelp then
		-- but if the current help should not be shown, then stop showing it, but stick it back in the queue to try again later
		if not HELP:ShouldShowHelp(HELP.showingHelp) then
			local current = HELP.showingHelp
			HELP.showingHelp = nil
			HELP:Queue(current)
		end
		return
	end

	-- if there isn't a next help to show, then dont try.
	if not next(HELP.Queued) then
		return
	end

	-- calculate the next help in line based on the order of HELP.Codes
	local help
	for order, code in ipairs(HELP.Codes) do
		if HELP.Queued[code] and HELP:ShouldShowHelp(HELP.Queued[code]) then
			help = HELP.Queued[code]
			break
		end
	end

	if not help then
		return
	end

	-- show the frame with the data
	local text = format(help.text, unpack(help))

	HELP.Frame:ClearAllPoints()
	HELP.Frame:SetPoint("TOPRIGHT", help.frame, "LEFT", (help.x or 0) - 30, (help.y or 0) + 28)
	HELP.Frame.text:SetText(text)
	HELP.Frame:SetHeight(HELP.Frame.text:GetHeight() + 38)
	HELP.Frame:SetWidth(min(250, HELP.Frame.text:GetStringWidth() + 30))

	local parent = help.frame.CreateTexture and help.frame or help.frame:GetParent() -- if the frame has the CreateTexture method, then it can be made the parent. Otherwise, the frame is actually a texture/font/etc object, so set
	HELP.Frame:SetParent(parent)
	HELP.Frame:Show()


	-- if the help had a setting associated, set it now
	if help.setting then
		TMW.db.global.HelpSettings[help.setting] = true
	end

	-- remove the help from the queue and set it as the current help
	HELP.Queued[help.code] = nil
	HELP.showingHelp = help
end

function HELP:HideForIcon(icon)
	for code, help in pairs(HELP.Queued) do
		if help.icon == icon then
			HELP.Queued[code] = nil
		end
	end
	if HELP.showingHelp and HELP.showingHelp.icon == icon then
		HELP.showingHelp = nil
		HELP:ShowNext()
	end
end










--TODO: needs its own file



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

local TMW = TMW
local L = TMW.L
	

local Module = TMW:NewClass("IconModule_GroupDragger", "IconModule")

function Module:OnNewInstance_GroupDragger(icon)
	icon:RegisterForDrag("LeftButton", "RightButton")
end

Module:SetScriptHandler("OnDragStop", function(Module, icon)
	if TMW.ID.isMoving then
		TMW:Group_StopMoving(TMW.ID.isMoving)
	end
end)

Module:SetScriptHandler("OnDragStart", function(Module, icon, button)
	if button == "LeftButton" then
		local group = icon:GetParent()
		if not TMW.Locked and not group.Locked then
			group:StartMoving()
			TMW.ID.isMoving = group
		end
	end
	if TMW.IE then
		TMW.IE:ScheduleIconSetup(icon)
	end
end)

Module:SetScriptHandler("OnMouseUp", function(Module, icon, button)
	if not TMW.Locked then
		if TMW.ID.isMoving then
			TMW:Group_StopMoving(TMW.ID.isMoving)
		end
	end
end)

























--TODO: separate files for all of this crap








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

local TMW = TMW
local L = TMW.L
	

local Module = TMW:NewClass("IconModule_RecieveSpellDrags", "IconModule")

Module:SetScriptHandler("OnClick", function(Module, icon, button)
	if not TMW.Locked and TMW.ID and button == "LeftButton" then
		TMW.ID:SpellItemToIcon(icon)
	end
end)
Module:SetScriptHandler("OnReceiveDrag", function(Module, icon, button)
	if not TMW.Locked and TMW.ID then
		TMW.ID:SpellItemToIcon(icon)
	end
end)












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

local TMW = TMW
local L = TMW.L
	

local Module = TMW:NewClass("IconModule_IconEditorLoader", "IconModule")

Module:SetScriptHandler("OnMouseUp", function(Module, icon, button)
	if not TMW.Locked then
		if button == "RightButton" then
			TMW.IE:Load(nil, icon)
		end
		TMW.IE:ScheduleIconSetup(icon)
	end
end)


















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

local TMW = TMW
local L = TMW.L
	

local Module = TMW:NewClass("IconModule_IconDragger", "IconModule")

function Module:OnNewInstance_IconDragger(icon)
	icon:RegisterForDrag("LeftButton", "RightButton")
end

Module:SetScriptHandler("OnMouseDown", function(Module, icon)
	if not TMW.Locked then
		local ID = TMW.ID
		if not ID then return end
		ID.DraggingInfo = nil
		ID.F:Hide()
		ID.IsDragging = nil
	end
end)

Module:SetScriptHandler("OnDragStart", function(Module, icon, button)
	if button == "RightButton" and TMW.ID then
		TMW.ID:Start(icon)
	end
	if TMW.IE then
		TMW.IE:ScheduleIconSetup(icon)
	end
end)

Module:SetScriptHandler("OnReceiveDrag", function(Module, icon)
	if TMW.ID then
		TMW.ID:CompleteDrag("OnReceiveDrag", icon)
	end
end)

Module:SetScriptHandler("OnDragStop", function(Module, icon)
	if TMW.ID and TMW.ID.IsDragging then
		TMW.ID:CompleteDrag("OnDragStop")
	end
end)












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

local TMW = TMW
local L = TMW.L
	

local Module = TMW:NewClass("IconModule_Tooltip", "IconModule")
local title_default = function(icon)
	local groupID = icon.group:GetID()
	
	local line1 =
		L["ICON_TOOLTIP1"] ..
		" " ..
		format(L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), icon:GetID())
		
	if icon.group.Locked then
		line1 = line1 .. " (" .. L["LOCKED"] .. ")"
	end
	
	return line1
end
Module.title = title_default

local text_default = L["ICON_TOOLTIP2NEW"]
Module.text = text_default

Module:ExtendMethod("OnUnimplementFromIcon", function(self)
	self:SetTooltipTitle(title_default, true)
	self:SetTooltipText(text_default, true)
end)

function Module:OnDisable()
	if self.icon:IsMouseOver() and self.icon:IsVisible() then
		GameTooltip:Hide()
	end
end

function Module:SetTooltipTitle(title, dontUpdate)
	self.title = title
	
	-- this should work, even though this tooltip isn't manged by TMW's tooltip handler
	-- (TT_Update is really generic)
	if not dontUpdate then
		TMW:TT_Update(self.icon)
	end
end
function Module:SetTooltipText(text, dontUpdate)
	self.text = text
	
	-- this should work, even though this tooltip isn't manged by TMW's tooltip handler
	-- (TT_Update is really generic)
	if not dontUpdate then
		TMW:TT_Update(self.icon)
	end
end

Module:SetScriptHandler("OnEnter", function(Module, icon)
	GameTooltip_SetDefaultAnchor(GameTooltip, icon)
	GameTooltip:AddLine(TMW.get(Module.title, icon), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
	GameTooltip:AddLine(TMW.get(Module.text, icon), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false)
	GameTooltip:Show()
end)

Module:SetScriptHandler("OnLeave", function(Module, icon)
	GameTooltip:Hide()
end)




