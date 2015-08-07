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


---------- Libraries ----------
local LSM = LibStub("LibSharedMedia-3.0")
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")

-- GLOBALS: LibStub
-- GLOBALS: TMWOptDB
-- GLOBALS: TELLMEWHEN_VERSION, TELLMEWHEN_VERSION_MINOR, TELLMEWHEN_VERSION_FULL, TELLMEWHEN_VERSIONNUMBER, TELLMEWHEN_MAXROWS
-- GLOBALS: NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR, INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, SPELL_RECAST_TIME_MIN, SPELL_RECAST_TIME_SEC, NONE, SPELL_CAST_CHANNELED, NUM_BAG_SLOTS, CANCEL
-- GLOBALS: GameTooltip
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
local GetSpellTexture = TMW.GetSpellTexture
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
TMW.justifyVPoints = {
	TOP = L["TOP"],
	MIDDLE = L["CENTER"],
	BOTTOM = L["BOTTOM"],
}

TMW.operators = {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}

TMW.EquivOriginalLookup = {}
TMW.EquivFullIDLookup = {}
TMW.EquivFullNameLookup = {}
TMW.EquivFirstIDLookup = {}
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do
		TMW.EquivOriginalLookup[equiv] = str

		-- remove underscores
		str = gsub(str, "_", "")

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
		return tbl.icon and tbl.icon:GetSettings()
	elseif k == "gs" then
		return tbl.group and tbl.group:GetSettings()
	end
end}) local CI = TMW.CI		--current icon






-- ----------------------
-- WOW API HOOKS
-- ----------------------

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



---------- Misc Utilities ----------
local ScrollContainerHook_Hide = function(c) c.ScrollFrame:Hide() end
local ScrollContainerHook_Show = function(c) c.ScrollFrame:Show() end
local ScrollContainerHook_OnSizeChanged = function(c) c.ScrollFrame:Show() end
function TMW:ConvertContainerToScrollFrame(container, exteriorScrollBarPosition, scrollBarXOffs, scrollBarSizeX, leftSide)
	
	local name = container:GetName() and container:GetName() .. "ScrollFrame"
	local ScrollFrame = TMW.C.Config_ScrollFrame:New("ScrollFrame", name, container:GetParent(), "TellMeWhen_ScrollFrameTemplate")
	
	-- Make the ScrollFrame clone the container's position and size
	local x, y = container:GetSize()
	ScrollFrame:SetSize(x, y)
	for i = 1, container:GetNumPoints() do
		ScrollFrame:SetPoint(container:GetPoint(i))
	end
	

	-- Make the container be the ScrollFrame's ScrollChild.
	-- Fix its size to take the full width.
	container:ClearAllPoints()
	ScrollFrame:SetScrollChild(container)
	container:SetSize(1, 1)
	
	local relPoint = leftSide and "LEFT" or "RIGHT"
	if exteriorScrollBarPosition then
		ScrollFrame.ScrollBar:SetPoint("LEFT", ScrollFrame, relPoint, scrollBarXOffs or 0, 0)
	else
		ScrollFrame.ScrollBar:SetPoint("RIGHT", ScrollFrame, relPoint, scrollBarXOffs or 0, 0)
	end
	
	if scrollBarSizeX then
		ScrollFrame.ScrollBar:SetWidth(scrollBarSizeX)
	end
	
	container.ScrollFrame = ScrollFrame
	ScrollFrame.container = container

	hooksecurefunc(container, "Hide", ScrollContainerHook_Hide)
	hooksecurefunc(container, "Show", ScrollContainerHook_Show)
	
end

function TMW:AdjustScrollFrame(scrollFrame, targetFrame)
	local ScrollFrame
	if scrollFrame.SetVerticalScroll then
		ScrollFrame = scrollFrame
	elseif scrollFrame.ScrollFrame then
		ScrollFrame = scrollFrame.ScrollFrame
	else
		error("Couldn't find the actual scroll frame!")
	end

	if not targetFrame then return end

	if not targetFrame:GetBottom() or not ScrollFrame:GetBottom() then
		return
	end

	local targetBottom = targetFrame:GetBottom()
	local targetTop = targetFrame:GetTop()

	local scrollBottom = ScrollFrame:GetBottom()
	local scrollTop = ScrollFrame:GetTop()

	local scroll 
	if targetBottom < scrollBottom then
		-- It's too low. Scroll up.
		scroll = ScrollFrame:GetVerticalScroll() + (scrollBottom - targetBottom)

	elseif targetTop > scrollTop then
		-- It's too high. Scroll down.
		scroll = ScrollFrame:GetVerticalScroll() - (targetTop - scrollTop)
	end


	if scroll then
		local yrange = ScrollFrame:GetVerticalScrollRange()
		scroll = max(scroll, 0)
		scroll = min(scroll, ScrollFrame:GetVerticalScrollRange())

		ScrollFrame:SetVerticalScroll(scroll)
	end
end







-- -------------
-- GROUP CONFIG
-- -------------

---------- Add/Delete ----------
function TMW:Group_Delete(group)
	if InCombatLockdown() then
		-- Error if we are in combat because TMW:Update() won't update the groups instantly if we are.
		error("TMW: Can't delete groups while in combat")
	end

	TMW:ValidateType("group", "TMW:Group_Delete(group)", group, "Group")

	local domain = group.Domain
	local groupID = group.ID

	IE:LoadGroup(1, false)
	IE:LoadIcon(1, false)

	tremove(TMW.db[domain].Groups, groupID)
	TMW.db[domain].NumGroups = TMW.db[domain].NumGroups - 1

	TMW:Update()

	-- Do this again so the group list will update to reflect the missing group.
	IE:LoadGroup(1, false)
end

function TMW:Group_Add(domain, view)
	if InCombatLockdown() then
		-- Error if we are in combat because TMW:Update() won't create the group instantly if we are.
		error("TMW: Can't add groups while in combat")
	end

	TMW:ValidateType("domain", "TMW:Group_Add(domain [,view]", domain, "string")
	TMW:ValidateType("view", "TMW:Group_Add(domain [,view]", view, "string;nil")

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

	TMW.ACEOPTIONS:CompileOptions()
	TMW.ACEOPTIONS:NotifyChanges()

	return group
end

function TMW:Group_Insert(group, targetDomain, targetID)
	if InCombatLockdown() then
		-- Error if we are in combat because TMW:Update() won't update the groups instantly if we are.
		error("TMW: Can't swap groups while in combat")
	end

	TMW:ValidateType("group", "TMW:Group_Insert(group, targetDomain, targetID)", group, "Group")
	TMW:ValidateType("targetDomain", "TMW:Group_Insert(group, targetDomain, targetID)", targetDomain, "string")
	TMW:ValidateType("targetID", "TMW:Group_Insert(group, targetDomain, targetID)", targetID, "number")

	if type(TMW[targetDomain]) ~= "table" then
		error("Invalid domain to Group_Swap")
	end

	--TMW:ValidateType("group 2", "TMW:Group_Insert(group, targetDomain, targetID)", TMW[domain][targetID], "Group")
	
	-- The point of this is to keep the icon editor's
	-- current icon and group the same before and after the swap.
	local iconGUID = CI.icon and CI.icon:GetGUID()
	local groupGUID = CI.group and CI.group:GetGUID()

	IE:LoadGroup(1, false)
	IE:LoadIcon(1, false)

	local oldDomain = group.Domain

	local groupSettings = tremove(TMW.db[oldDomain].Groups, group.ID)
	tinsert(TMW.db[targetDomain].Groups, targetID, groupSettings)

	TMW.db[oldDomain].NumGroups = TMW.db[oldDomain].NumGroups - 1
	TMW.db[targetDomain].NumGroups = TMW.db[targetDomain].NumGroups + 1

	TMW:Update()

	IE:LoadGroup(1, groupGUID and TMW:GetDataOwner(groupGUID))
	IE:LoadIcon(1, iconGUID and TMW:GetDataOwner(iconGUID))
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
	IE_HEIGHT_MIN = 400,
	IE_HEIGHT_MAX = 1200,
}

function IE:OnInitialize()
	-- if the file IS required for gross functionality
	if not TMW.DROPDOWNMENU then
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
		StaticPopup_Show("TMWOPT_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "TellMeWhen_Options/TMWUIDropDownMenu.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
		return

	-- if the file is NOT required for gross functionality
	elseif not TMW.DOGTAG then
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
		if CI.icon and CI.icon.group == group then
			IE:CheckLoadedIconIsValid()
		end
	end)

	IE.history = {}
	IE.historyState = 0


	IE.MainTab = IE:RegisterTab("ICON", "MAIN", "Main", 1)
	IE.MainTab:SetTexts(L["ICON"], L["MAIN_DESC"])

	IE:RegisterTab("GROUP", "GROUPMAIN", "GroupMain", 1)
		:SetTexts(L["GROUP"], L["GROUPSETTINGS_DESC"])

	IE:RegisterTab("MAIN", "CHANGELOG", "Changelog", 100)
		:SetTexts(L["CHANGELOG"], L["CHANGELOG_DESC"])
	

	-- Create resizer
	self.resizer = TMW.Classes.Resizer_Generic:New(self)
	self.resizer:Show()
	self.resizer.scale_min = 0.4
	self.resizer.y_min = 400
	self.resizer.y_max = 1200
	self.resizer:SetModes(self.resizer.MODE_SCALE, self.resizer.MODE_SIZE)
	function self.resizer:SizeUpdated()
		TMW.IE.db.global.EditorHeight = IE:GetHeight()
		TMW.IE.db.global.EditorScale = IE:GetScale()
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
		LastChangelogVersion = 0,
		TellMeWhenDBBackupDate = 0,
		EditorScale		= 0.9,
		EditorHeight	= 600,
		ConfigWarning	= true,
		ConfigWarningN	= 0,
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
		if IE.db.sv.locale then
			for locale, ls in pairs(IE.db.sv.locale) do
				IE:DoUpgrade("locale", version, ls, locale)
			end
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

	if TMW.DBWasEmpty and IE.db.global.TellMeWhenDBBackup then
		-- TellMeWhenDB was corrupted. Restore from the backup and notify user.
		TellMeWhenDB = IE.db.global.TellMeWhenDBBackup

		TMW:InitializeDatabase()
		TMW.db.profile.Locked = false

		TMW:ScheduleUpdate(1)

		TellMeWhen_DBRestoredNofication:SetTime(IE.db.global.TellMeWhenDBBackupDate)
		TellMeWhen_DBRestoredNofication:Show()

	elseif not TMW.DBWasEmpty --[[and IE.db.global.TellMeWhenDBBackupDate + 86400 < time()]] then
		-- TellMeWhenDB was not corrupt, so back it up.
		-- I have opted against only creating the backup after the old one reaches a certain age.
		IE.db.global.TellMeWhenDBBackupDate = time()
		IE.db.global.TellMeWhenDBBackup = TellMeWhenDB
	end

	TMW:Fire("TMW_IE_DB_INITIALIZED")
	TMW:UnregisterAllCallbacks("TMW_IE_DB_INITIALIZED")
end

function IE:OnProfile(event, arg2, arg3)

	if IE.Initialized then
		TMW.ACEOPTIONS:CompileOptions() -- redo groups in the options

		-- Reload the icon editor.
		-- TODO: figure out what should happen here.
		IE:Load(1)
	
		TMW:Fire("TMW_IE_ON_PROFILE", event, arg2, arg3)
	end
end

TMW:RegisterCallback("TMW_ON_PROFILE", function(event, arg2, arg3)
	IE.db:SetProfile(TMW.db:GetCurrentProfile())
end)






TMW:NewClass("IconEditorTabBase", "Button"){

	SetTexts = function(self, title, tooltip)
		self:SetText(title)
		TMW:TT(self, title, tooltip, 1, 1)
	end,

	AdjustWidth = function(self)
		self:SetWidth(self.text:GetStringWidth() + 10)
	end,

	OnShow = function(self)
		self:AdjustWidth()
	end,
	
	OnSizeChanged = function(self)
		self:AdjustWidth()

		IE:ResizeTabs()
	end,

	METHOD_EXTENSIONS = {
		SetText = function(self, text)
			self:AdjustWidth()
		end,
	},
}

TMW:NewClass("IconEditorTabGroup", "IconEditorTabBase"){
	childrenEnabled = true,

	OnNewInstance = function(self)
		self.Tabs = {}
	end,

	OnClick = function(self)
		PlaySound("igCharacterInfoTab")

		IE.CurrentTabGroup = self

		TMW.IE.Tabs.art.pSelectedHorizontal:ClearAllPoints()
		TMW.IE.Tabs.art.pSelectedHorizontal:SetPoint("TOPLEFT", self)
		TMW.IE.Tabs.art.pSelectedHorizontal:SetPoint("TOPRIGHT", self)

		for i, tab in TMW:Vararg(TMW.IE.Tabs.secondary:GetChildren()) do
			tab:Hide()
		end
		
		local lastTab
		local firstShown
		for i = 1, #self.Tabs do
			local tab = self.Tabs[i]

			if tab:ShouldShowTab() then
				if not lastTab then
					tab:SetPoint("LEFT", tab.endPadding, 0, 0)
				else
					tab:SetPoint("LEFT", lastTab, "RIGHT", tab.interPadding, 0)
				end
				tab:SetPoint("TOP")
				tab:SetPoint("BOTTOM")

				lastTab = tab

				tab:Show()
				tab:SetFrameLevel(tab:GetParent():GetFrameLevel() + 3)
				tab:SetEnabled(self.childrenEnabled)

				firstShown = firstShown or tab
			end
		end


		if not self.childrenEnabled then
			IE.CurrentTab = nil
			local page = IE:DisplayPage(self.disabledPageKey)
			page:RequestReloadChildren()

		elseif self.currentTab and self.currentTab:IsShown() then
			self.currentTab:Click()

		elseif firstShown then
			firstShown:Click()
		else
			error("No tabs shown to click for tab group " .. self.identifier)
		end

		if not IE.CurrentTab then
			TMW.IE.Tabs.art.sSelectedHorizontal:ClearAllPoints()
			TMW.IE.Tabs.art.sSelectedHorizontal:SetPoint("TOP")
		end

		IE:ResizeTabs()
	end,

	SetChildrenEnabled = function(self, enabled)
		self.childrenEnabled = enabled

		if IE.CurrentTabGroup == self then
			self:Click()
		end
	end,

	SetDisabledPageKey = function(self, pageKey)
		self.disabledPageKey = pageKey
	end,
}

TMW:NewClass("IconEditorTab", "IconEditorTabBase"){
	
	endPadding = 6,
	interPadding = 5,

	OnClick = function(self)
		PlaySound("igCharacterInfoTab")

		if IE.CurrentTabGroup ~= self.parent then
			self.parent:Click()
		end

		local oldTab = IE.CurrentTab

		IE.CurrentTab = self
		self.parent.currentTab = self

		IE.Tabs.art.sSelectedHorizontal:ClearAllPoints()
		IE.Tabs.art.sSelectedHorizontal:SetPoint("BOTTOMLEFT", self)
		IE.Tabs.art.sSelectedHorizontal:SetPoint("BOTTOMRIGHT", self)


		local page = IE:DisplayPage(self.pageKey)
		
		TMW:Fire("TMW_CONFIG_TAB_CLICKED", self, oldTab)

		page:RequestReloadChildren()

		IE:RefreshTabs()
	end,

	ShouldShowTab = function(self)
		return true
	end,
}


IE.TabGroups = {}
function IE:RegisterTabGroup(identifier, text, order, setupHeaderFunc)
	local sig = "IE:RegisterTabGroup(identifier, text, order, setupHeaderFunc)"
	TMW:ValidateType("identifier",      sig, identifier,      "string")
	TMW:ValidateType("text",            sig, text,            "string")
	TMW:ValidateType("order",           sig, order,           "number")
	TMW:ValidateType("setupHeaderFunc", sig, setupHeaderFunc, "function")

	assert(identifier == identifier:upper(), "Tab identifiers should be all uppercase")

	if IE.TabGroups[identifier] then
		error("A tab group with the identifier " .. identifier .. " is already registered.")
	end
	
	local tab = TMW.C.IconEditorTabGroup:New("Button", nil, TMW.IE.Tabs.primary, "TellMeWhen_IE_Tab")
	TMW.IE.Tabs.primary[identifier] = tab

	tab.identifier = identifier
	tab.order = order
	tab.SetupHeader = setupHeaderFunc

	tab:SetText(text)

	IE.TabGroups[identifier] = tab

	for i, tab in ipairs(TMW.IE.Tabs.primary) do
		tab:Hide()
	end
	

	local prevTabGroup
	for identifier, tabGroup in TMW:OrderedPairs(IE.TabGroups, TMW.OrderSort, true) do
		if prevTabGroup then
			prevTabGroup:SetPoint("RIGHT", tabGroup, "LEFT", -5, 0)
		end
		tabGroup:Show()

		prevTabGroup = tabGroup
	end
	prevTabGroup:SetPoint("RIGHT", -5)

	return tab
end

function IE:RegisterTab(groupIdentifier, identifier, pageKey, order)
	local sig = "IE:RegisterTab(groupIdentifier, identifier, pageKey, order)"
	TMW:ValidateType("groupIdentifier", sig, groupIdentifier, "string")
	TMW:ValidateType("identifier",      sig, identifier,      "string")
	TMW:ValidateType("pageKey",         sig, pageKey,         "string")
	TMW:ValidateType("order",           sig, order,           "number")

	assert(identifier == identifier:upper(), "Tab identifiers should be all uppercase")

	local tabGroup = IE.TabGroups[groupIdentifier]

	if not tabGroup then
		error("Could not find tab group registered with identifier " .. groupIdentifier)
	end

	if tabGroup[identifier] then
		error("A tab with the identifier " .. identifier .. " is already registered to tab group " .. groupIdentifier)
	end

	local tab = TMW.C.IconEditorTab:New("Button", nil, TMW.IE.Tabs.secondary, "TellMeWhen_IE_Tab")
	TMW.IE.Tabs.secondary[identifier] = tab

	tab.identifier = identifier
	tab.pageKey = pageKey
	tab.order = order
	tab.parent = tabGroup

	tabGroup[identifier] = tab

	tabGroup.Tabs[#tabGroup.Tabs + 1] = tab

	TMW:SortOrderedTables(tabGroup.Tabs)

	return tab
end

function IE:ResizeTabs()
	local endPadding = TMW.C.IconEditorTab.endPadding
	local interPadding = TMW.C.IconEditorTab.interPadding

	local width = endPadding*2 - interPadding -- This was derived using magic.

	for i, tab in TMW:Vararg(TMW.IE.Tabs.secondary:GetChildren()) do
		if tab:IsShown() then
			width = width + tab:GetWidth() + interPadding
		end
	end

	TMW.IE.Tabs.secondary:SetWidth(width)
end

function IE:RefreshTabs()
	local tabGroup = IE.CurrentTabGroup

	if not tabGroup then
		for _, tabGroup in TMW:OrderedPairs(IE.TabGroups, TMW.OrderSort, true) do
			tabGroup:Click()
			return
		end
	else
		tabGroup:Click()
	end
end

function IE:CreateTabGroups()
	IE.CreateTabGroups = TMW.NULLFUNC

	local iconTabGroup = TMW.IE:RegisterTabGroup("ICON", TMW.L["ICON"], 1, function(tabGroup)
		local titlePrepend = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL
		local icon = CI.icon

		if icon then
			local group = icon.group

			local groupName = group:GetGroupName(1)
			local name = L["GROUPICON"]:format(groupName, icon.ID)
			if group.Domain == "global" then
				name = L["DOMAIN_GLOBAL"] .. " " .. name
			end
			
			IE.Header:SetText(titlePrepend .. " - " .. name)

			IE.Header:SetFontObject(GameFontNormal)

			if IE.Header:IsTruncated() then
				IE.Header:SetFontObject(GameFontNormalSmall)
				local truncAmt = 3

				-- If the header text has to be truncated,
				-- shave a little bit off of the group name until it fits.
				while IE.Header:IsTruncated() and #groupName + 4 >= truncAmt  do
					local name = L["GROUPICON"]:format(groupName:sub(1, -truncAmt - 4) .. "..." .. groupName:sub(-4), icon.ID)
					if group.Domain == "global" then
						name = L["DOMAIN_GLOBAL"] .. " " .. name
					end

					IE.Header:SetText(titlePrepend .. " - " .. name)
					truncAmt = truncAmt + 1
				end
			end

			IE.icontexture:SetTexture(icon.attributes.texture)
			IE.BackButton:Show()
			IE.ForwardsButton:Show()

			IE.Header:SetPoint("LEFT", IE.ForwardsButton, "RIGHT", 4, 0)
		end
	end)
	iconTabGroup:SetDisabledPageKey("IconNotLoaded")
	iconTabGroup:SetChildrenEnabled(false)

	local groupTabGroup = TMW.IE:RegisterTabGroup("GROUP", TMW.L["GROUP"], 2, function(tabGroup)
		local titlePrepend = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL
		
		local group = CI.group
		if group then
			local name = L["fGROUP"]:format(group:GetGroupName(1))
			if group.Domain == "global" then
				name = L["DOMAIN_GLOBAL"] .. " " .. name
			end
			IE.Header:SetText(titlePrepend .. " - " .. name)
		end
	end)
	groupTabGroup:SetDisabledPageKey("GroupNotLoaded")
	groupTabGroup:SetChildrenEnabled(false)

	TMW.IE:RegisterTabGroup("MAIN", TMW.L["MAIN"], 3, function(tabGroup)
		local titlePrepend = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL

		IE.Header:SetText(titlePrepend)
	end)
end

function IE:DisplayPage(pageKey)
	for _, otherPage in TMW:Vararg(TMW.IE.Pages:GetChildren()) do
		otherPage:Hide()
	end

	-- If no key is specified, the function was probably just being called to hide all pages.
	if not pageKey then
		return
	end

	local page = TellMeWhen_IconEditor.Pages[pageKey]
	if not page then
		TMW:Error(("Couldn't find child of TellMeWhen_IconEditor.Pages with key %q"):format(pageKey))
	end

	page:Show()

	return page
end




function IE:OnUpdate()
	local icon = CI.icon

	-- update the top of the icon editor with the information of the current icon.
	-- this is done in an OnUpdate because it is just too hard to track when the texture changes sometimes.
	-- I don't want to fill up the main addon with configuration code to notify the IE of texture changes	
	local tabGroup = IE.CurrentTabGroup
	if tabGroup then

		IE.icontexture:SetTexture(nil)
		IE.BackButton:Hide()
		IE.ForwardsButton:Hide()

		IE.Header:SetText(nil)
		IE.Header:SetPoint("LEFT", IE.icontexture, "RIGHT", 4, 0)
		IE.Header:SetFontObject(GameFontNormal)

		tabGroup:SetupHeader()

		if not IE.Header:GetText() then
			IE.Header:SetText("TellMeWhen v" .. TELLMEWHEN_VERSION_FULL)
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
		if icon:IsGroupController() then
			TMW.safecall(icon.group.Setup, icon.group)
		else
			TMW.safecall(icon.Setup, icon)
		end
	end
	wipe(IE.iconsToUpdate)

	-- check and see if the settings of the current icon have changed.
	-- if they have, create a history point (or at least try to)
	-- IMPORTANT: do this after running icon updates <because of an old antiquated reason which no longer applies, but if it ain't broke, don't fix it>
	IE:AttemptBackup(TMW.CI.icon)
end

TMW:RegisterCallback("TMW_CONFIG_TAB_CLICKED", function(event, tab)
	IE:UndoRedoChanged()

	if tab.doesIcon then
		IE.ResetButton:Enable()
	else
		IE.ResetButton:Disable()
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- GLOBALS: TellMeWhen_ConfigWarning
	if not TMW.Locked then
		if IE.db.global.ConfigWarning then
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

function IE:PositionPanels(parentPanelName, panelList)	
	TMW:SortOrderedTables(panelList)
	

	local panelColumns = TellMeWhen_IconEditor.Pages[parentPanelName].panelColumns
	for _, panelColumn in ipairs(panelColumns) do
		for _, panel in TMW:Vararg(panelColumn:GetChildren()) do
			panel:Hide()
		end
		wipe(panelColumn.currentPanels)
	end
	
	local IE_FL = IE:GetFrameLevel()

	for i, panelInfo in ipairs(panelList) do
		local frameName = panelInfo:GetFrameName()

		if not panelInfo.columnIndex or panelInfo.columnIndex < 1 or panelInfo.columnIndex > #panelColumns then	
			error("columnIndex out of bounds for panel " .. frameName)
		end
		
		local panelColumn = panelColumns[panelInfo.columnIndex]
		local panel = panelInfo:GetPanel(panelColumn)

		if panel then
			local last = panelColumn.currentPanels[#panelColumn.currentPanels]

			if type(last) == "table" then
				panel:SetPoint("TOP", last, "BOTTOM", 0, -20)
			else
				panel:SetPoint("TOP", 0, -14)
			end
			
			panel:Show()
			panel:SetFrameLevel(IE_FL + 3)

			panel:Setup(panelInfo)

			if panel:IsShown() then
				panelColumn.currentPanels[#panelColumn.currentPanels + 1] = panel
			end
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


function IE:LoadIcon(isRefresh, icon, isHistoryChange)
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
				IE.Pages.Main.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
				IE.Pages.Main.PanelsRight.ScrollFrame:SetVerticalScroll(0)
			end

			IE.TabGroups.ICON:SetChildrenEnabled(true)

		elseif icon == false then
			CI.icon = nil
			IE.TabGroups.ICON:SetChildrenEnabled(false)
		end

		TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", CI.icon, ic_old)
	end
	
	if CI.icon then
		-- This is really really important. The icon must be setup so that it has the correct components implemented
		-- so that the correct config panels will be loaded and shown for the icon.
		CI.icon:Setup()


		local panelList = {}
		for _, Component in pairs(CI.icon.Components) do
			if Component:ShouldShowConfigPanels(CI.icon) then
				for _, panelInfo in pairs(Component.ConfigPanels) do
					if panelInfo.panelSet == "icon" then
						tinsert(panelList, panelInfo)
					end
				end		
			end
		end
		IE:PositionPanels("Main", panelList)
		
		if CI.ics.Type == "" then
			IE.Pages.Main.Type:SetText(L["ICONMENU_TYPE"])
		else
			local Type = rawget(TMW.Types, CI.ics.Type)
			if Type then
				IE.Pages.Main.Type:SetText(Type.name)
			else
				IE.Pages.Main.Type:SetText(CI.ics.Type .. ": UNKNOWN TYPE")
			end
		end

		-- It is intended that this happens at the end instead of the beginning.
		-- Table accesses that trigger metamethods flesh out an icon's settings with new things that aren't there pre-load (usually)
		IE:AttemptBackup(CI.icon)

		-- TODO: get rid of this, replace with ReloadRequested cscripts
		TMW:Fire("TMW_CONFIG_ICON_LOADED", CI.icon)

		IE.Pages.Main:RequestReloadChildren()
	end
	
	IE:UndoRedoChanged()

	IE:Load(isRefresh)
end

function IE:LoadGroup(isRefresh, group)
	if group ~= nil then

		local group_old = CI.group

		if type(group) == "table" then
			PlaySound("igCharacterInfoTab")
			IE:SaveSettings()
			
			CI.group = group
			
			if group_old ~= CI.group then
				IE.Pages.GroupMain.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
				IE.Pages.GroupMain.PanelsRight.ScrollFrame:SetVerticalScroll(0)
			end

			IE.TabGroups.GROUP:SetChildrenEnabled(true)

		elseif group == false then
			CI.group = nil
			IE.TabGroups.GROUP:SetChildrenEnabled(false)
		end
	end

	
	if CI.group then
		CI.group:Setup()

		local panelList = {}
		for _, Component in pairs(CI.group.Components) do
			if Component:ShouldShowConfigPanels(CI.group) then
				for _, panelInfo in pairs(Component.ConfigPanels) do
					if panelInfo.panelSet == "group" then
						tinsert(panelList, panelInfo)
					end
				end		
			end
		end
		IE:PositionPanels("GroupMain", panelList)

		IE.Pages.GroupMain:RequestReloadChildren()
	end

	IE:Load(isRefresh)
end

function IE:Load(isRefresh)
	TMW.ACEOPTIONS:CompileOptions()

	if IE.db.global.LastChangelogVersion > 0 then		
		if IE.db.global.LastChangelogVersion < TELLMEWHEN_VERSIONNUMBER then
			if IE.db.global.LastChangelogVersion < TELLMEWHEN_FORCECHANGELOG -- forced
			or TELLMEWHEN_VERSION_MINOR == "" -- upgraded to a release version (e.g. 7.0.0 release)
			or floor(IE.db.global.LastChangelogVersion/100) < floor(TELLMEWHEN_VERSIONNUMBER/100) -- upgraded to a new minor version (e.g. 6.2.6 release -> 7.0.0 alpha)
			then
				-- Put this in a C_Timer so that it runs after all the auto tab clicking mumbo jumbo has finished.
				-- C_Timers with a delay of 0 will run after the current script finishes execution.
				-- In the case of loading the IE, it is probably an OnClick.

				-- We have to upvalue this since its about to get set to the current version.l
				local version = IE.db.global.LastChangelogVersion
				C_Timer.NewTimer(0, function()
					IE:ShowChangelog(version)	
				end)		
			else
				TMW:Printf(L["CHANGELOG_MSG"], TELLMEWHEN_VERSION_FULL)
			end

			IE.db.global.LastChangelogVersion = TELLMEWHEN_VERSIONNUMBER
		end
	else
		IE.db.global.LastChangelogVersion = TELLMEWHEN_VERSIONNUMBER
	end

	if not isRefresh then
		IE:Show()
	end
	
	if IE:GetBottom() <= 0 then
		IE.db.global.EditorScale = IE.Defaults.global.EditorScale
		IE.db.global.EditorHeight = IE.Defaults.global.EditorHeight
	end

	IE:RefreshTabs()
	

	IE:SetScale(IE.db.global.EditorScale)
	IE:SetHeight(IE.db.global.EditorHeight)

	TMW:Fire("TMW_CONFIG_LOADED")
end

function IE:CheckLoadedIconIsValid()
	if not TMW.IE:IsShown() then
		return
	end

	if not CI.icon then
		return
	elseif
		not CI.icon.group:IsValid()
		or not CI.icon:IsInRange()
		or CI.icon:IsControlled()
	then
		TMW.IE:LoadIcon(nil, false)
	end
end


function IE:Reset()	
	IE:SaveSettings() -- this is here just to clear the focus of editboxes, not to actually save things
	
	CI.icon:DisableIcon()
	
	TMW.CI.icon.group:GetSettings().Icons[CI.icon.ID] = nil
	
	TMW:Fire("TMW_ICON_SETTINGS_RESET", CI.icon)
	
	CI.icon:Setup()
	
	IE:LoadIcon(1)
end

function IE:ShowConfirmation(confirmText, desc, action)
	IE.Pages.Confirm.MiddleBand.Description:SetText(desc)

	local AcceptButton = IE.Pages.Confirm.MiddleBand.AcceptButton
	AcceptButton:SetText(confirmText)
	AcceptButton:SetWidth(AcceptButton:GetTextWidth() + 20)
	AcceptButton.Action = action

	IE:DisplayPage("Confirm")
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
	IE:LoadIcon(1)
end


---------- Settings ----------

-- These classes are declared in TellMeWhen.lua. This extends them.
TMW.C.ConfigPanelInfo {
	GetPanel = function(self, panelColumn)
		if not self.panel and _G[self:GetFrameName()] then
			self.panel = _G[self:GetFrameName()]
		end
		if self.panel then
			self.panel:SetParent(panelColumn)

			return self.panel
		end

		local success
		success, self.panel = TMW.safecall(self.MakePanel, self, panelColumn)

		if self.panel then
			self.panel.panelInfo = self
		end

		return self.panel
	end,
}

TMW.C.XmlConfigPanelInfo {
	GetFrameName = function(self)
		return self.xmlTemplateName
	end,

	MakePanel = function(self, panelColumn)
		local panel = CreateFrame("Frame", self:GetFrameName(), panelColumn, self.xmlTemplateName)

		if not panel.isLibOOInstance then
			TMW:CInit(panel)
		end

		return panel
	end,
}

TMW.C.LuaConfigPanelInfo {
	GetFrameName = function(self)
		return self.frameName
	end,

	MakePanel = function(self, panelColumn)
		local panel = TMW.C.Config_Panel:New("Frame", self:GetFrameName(), panelColumn, "TellMeWhen_OptionsModuleContainer")

		TMW.safecall(self.constructor, panel)
		
		-- no longer needed. Off to the GC!
		self.constructor = nil

		return panel
	end,
}




local CScriptProvider
local CS_SDepth = 0
local function bubble(frame, get, script, ...)
	if not frame then
		return
	end

	if frame.isLibOOInstance and frame.class.inherits[CScriptProvider] then
		if get then
			local ret = frame:CScriptCallGet(script, ...)
			if ret ~= nil then
				return ret
			end
		else
			frame:CScriptCall(script, ...)
		end
	end

	return bubble(frame:GetParent(), get, script, ...)
end

local function tunnel(frame, get, script, ...)
	if frame.isLibOOInstance and frame.class.inherits[CScriptProvider] then
		if get then
			local ret = frame:CScriptCallGet(script, ...)
			if ret ~= nil then
				return ret
			end
		else
			frame:CScriptCall(script, ...)
		end
	end

	for _, child in TMW:Vararg(frame:GetChildren()) do
		local ret = tunnel(child, get, script, ...)
		if get and ret ~= nil then
			return ret
		end
	end
end


CScriptProvider = TMW:NewClass("CScriptProvider"){
	DEBUG_MaxDepth = 25,

	CScriptTunnelGet = function(self, script, ...)
		for _, child in TMW:Vararg(frame:GetChildren()) do
			local ret = tunnel(child, true, script, ...)
			if ret then
				return ret
			end
		end
	end,
	CScriptBubbleGet = function(self, script, ...)
		return bubble(self:GetParent(), true, script, ...)
	end,
	CScriptTunnel = function(self, script, ...)
		CS_SDepth = CS_SDepth + 1

		for _, child in TMW:Vararg(self:GetChildren()) do
			tunnel(child, false, script, ...)
		end

		CS_SDepth = CS_SDepth - 1
	end,
	CScriptBubble = function(self, script, ...)
		CS_SDepth = CS_SDepth + 1

		bubble(self:GetParent(), false, script, ...)

		CS_SDepth = CS_SDepth - 1
	end,

	CScriptAdd = function(self, script, func)
		TMW:ValidateType("script", "CScriptAdd(script, func)", script, "string")
		TMW:ValidateType("func", "CScriptAdd(script, func)", func, "function")

		self.__CScripts = self.__CScripts or {}
		local existing = self.__CScripts[script]

		if existing == nil then
			self.__CScripts[script] = func
		elseif type(existing) == "function" then
			self.__CScripts[script] = {existing, func}
		else
			tinsert(existing, func)
		end
	end,

	CScriptAddPre = function(self, script, func)
		TMW:ValidateType("script", "CScriptAddPre(script, func)", script, "string")
		TMW:ValidateType("func", "CScriptAddPre(script, func)", func, "function")

		self.__CScripts = self.__CScripts or {}
		local existing = self.__CScripts[script]

		if existing == nil then
			self.__CScripts[script] = func
		elseif type(existing) == "function" then
			self.__CScripts[script] = {func, existing}
		else
			tinsert(existing, 1, func)
		end
	end,

	CScriptRemove = function(self, script, func)
		TMW:ValidateType("script", "CScriptRemove(script, func)", script, "string")
		TMW:ValidateType("func", "CScriptRemove(script, func)", func, "function;nil")

		if not self.__CScripts then
			return
		end

		if func == nil then
			self.__CScripts[script] = nil
			return
		end

		local existing = self.__CScripts[script]
		if not existing then
			return
		end

		if type(existing) == "function" then
			if existing == func then
				self.__CScripts[script] = nil
			end
		else
			TMW.tDeleteItem(existing, func, 1)
		end
	end,

	CScriptRemoveAll = function(self)
		self.__CScripts = null
	end,

	CScriptCall = function(self, script, ...)
		if not self.__CScripts then
			return
		end

		local cscript = self.__CScripts[script]
		if not cscript then
			return
		end
		
		-- If we enter 10 deep cscripts, go into emergency mode
		-- and start recording data about what is being called.
		CS_SDepth = CS_SDepth + 1
		if CS_SDepth > 10 and not self.DEBUG_Started then
			self:DEBUG_Start()
		end

		if type(cscript) == "function" then
			TMW.safecall(cscript, self, ...)
		else
			for i = 1, #cscript do
				TMW.safecall(cscript[i], self, ...)
			end
		end
		CS_SDepth = CS_SDepth - 1
	end,

	DEBUG_Start = function(self)
		if not CScriptProvider.DEBUG_Started then
			print("entering cscript debug mode")

			CScriptProvider.DEBUG_Stack = {}
			CScriptProvider.DEBUG_PrevDepth = CS_SDepth - 1

			CScriptProvider.CScriptCall_ORIGINAL = CScriptProvider.CScriptCall
			CScriptProvider.CScriptBubble_ORIGINAL = CScriptProvider.CScriptBubble
			CScriptProvider.CScriptTunnel_ORIGINAL = CScriptProvider.CScriptTunnel

			CScriptProvider:PostHookMethod("CScriptCall", self.DEBUG_CScriptCallBase)
			CScriptProvider:PostHookMethod("CScriptBubble", self.DEBUG_CScriptCallBase)
			CScriptProvider:PostHookMethod("CScriptTunnel", self.DEBUG_CScriptCallBase)

			CScriptProvider.DEBUG_Started = true
		end
	end,

	DEBUG_Stop = function(self)
		if CScriptProvider.DEBUG_Started then
			print("leaving cscript debug mode")

			CScriptProvider.DEBUG_PrevDepth = nil
			CScriptProvider.DEBUG_PrevStackFrame = nil
			CScriptProvider.DEBUG_Stack = nil

			CScriptProvider.CScriptCall = CScriptProvider.CScriptCall_ORIGINAL
			CScriptProvider.CScriptBubble = CScriptProvider.CScriptBubble_ORIGINAL
			CScriptProvider.CScriptTunnel = CScriptProvider.CScriptTunnel_ORIGINAL

			CScriptProvider.DEBUG_Started = false
		end
	end,

	DEBUG_CScriptCallBase = function(self, script, ...)
		if not CScriptProvider.DEBUG_Started then
			return
		end

		-- Only record calls that change the stack depth.
		local stackFrame = {CS_SDepth, script, tostring(self:GetName() or self.setting or self.class)}
		if CScriptProvider.DEBUG_PrevDepth ~= CS_SDepth then
			tinsert(CScriptProvider.DEBUG_Stack, CScriptProvider.DEBUG_PrevStackFrame)
			tinsert(CScriptProvider.DEBUG_Stack, stackFrame)

			CScriptProvider.DEBUG_PrevStackFrame = nil
			CScriptProvider.DEBUG_PrevDepth = CS_SDepth
		else
			-- We do this so we can get calls right before the stack depth changes,
			-- which are usually what cause it.
			CScriptProvider.DEBUG_PrevStackFrame = stackFrame
		end

		if CS_SDepth < 2 then
			print("fell out of cscript debug mode")
			-- If it fell back down below ~2, then it recovered somehow.

			CScriptProvider:DEBUG_Stop()

		elseif CS_SDepth > self.DEBUG_MaxDepth then
			-- Its gone on long enough. Report the data we got about what's going on.
			local str = ""
			for i, data in pairs(CScriptProvider.DEBUG_Stack) do
				str = str .. table.concat(data, ":") .. "\n"
			end

			CS_SDepth = 0

			CScriptProvider:DEBUG_Stop()

			error("TellMeWhen: CScript Overflow: " .. str)
		end
	end,

	CScriptCallGet = function(self, script, ...)
		if not self.__CScripts then
			return
		end

		local existing = self.__CScripts[script]
		if not existing then
			return
		end

		if type(existing) == "function" then
			return existing(self, ...)
		else
			for i = 1, #existing do
				local ret = existing[i](self, ...)
				if ret then
					return ret
				end
			end
		end
	end,
}


TMW:NewClass("Config_Frame", "Frame", "CScriptProvider"){

	-- Constructor
	OnNewInstance_Frame = function(self)

		-- Setup callbacks that will load the settings when needed.
		if self.ReloadSetting ~= TMW.NULLFUNC then
			self:CScriptAdd("ReloadRequested", self.ReloadSetting)
		end
	end,

	SetSetting = function(self, key)
		self.setting = key
	end,

	SetTexts = function(self, title, tooltip)
		self:SetTooltip(title, tooltip)
	end,
	

	-- Script Handlers
	OnEnable = function(self)
		self:SetAlpha(1)
	end,
	
	OnDisable = function(self)
		self:SetAlpha(0.2)
	end,
	

	-- Methods
	Enabled = true,
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
	
	SetTooltip = function(self, title, text)
		if self.SetMotionScriptsWhileDisabled then
			TMW:TT(self, title, text, 1, 1, nil)
		else
			TMW:TT(self, title, text, 1, 1, "IsEnabled")
		end
	end,
	
	ConstrainLabel = function(self, anchorTo, anchorPoint, x, y)
		assert(self.text, "frame does not have a self.text object to constrain.")

		if not x then
			x = -3
		end

		self.text:SetPoint("RIGHT", anchorTo, anchorPoint or "LEFT", x, y)

		self.text:SetHeight(30)
		self.text:SetMaxLines(3)
	end,

	GetSettingTable = function(self)
		return self:CScriptCallGet("SettingTableRequested") or self:CScriptBubbleGet("SettingTableRequested")
	end,

	OnSettingSaved = function(self)
		IE:SaveSettings()

		self:CScriptCall("SettingSaved")
		self:CScriptBubble("DescendantSettingSaved", self)
	end,

	RequestReloadChildren = function(self)
		self:CScriptTunnel("ReloadRequested")
	end,

	ReloadSetting = TMW.NULLFUNC
}

TMW:NewClass("Config_Panel", "Config_Frame"){
	SetHeight_base = TMW.C.Config_Panel.SetHeight,
}{
	OnNewInstance_Frame = TMW.NULLFUNC,

	OnNewInstance_Panel = function(self)
		if self:GetHeight() <= 0 then
			self:SetHeight_base(1)
		end

		self.Background:SetTexture(.66, .66, .66, 0.09)

		self.height = self:GetHeight()
	end,

	Flash = function(self, dur)
		local start = GetTime()
		local duration = 0
		local period = 0.2

		while duration < dur do
			duration = duration + (period * 2)
		end
		local ticker
		ticker = C_Timer.NewTicker(0.01, function() 
			local bg = TellMeWhen_DotwatchSettings.Background

			local timePassed = GetTime() - start
			local fadingIn = FlashPeriod == 0 or floor(timePassed/period) % 2 == 1

			if FlashPeriod ~= 0 then
				local remainingFlash = timePassed % period
				local offs
				if fadingIn then
					offs = (period-remainingFlash)/period
				else
					offs = (remainingFlash/period)
				end
				offs = offs*0.3
				bg:SetTexture(.66, .66, .66, 0.08 + offs)
			end

			if timePassed > duration then
				bg:SetTexture(.66, .66, .66, 0.08)
				ticker:Cancel()
			end	
		end)
	end,

	SetTitle = function(self, text)
		self.Header:SetText(text)

		local font, size, flags = self.Header:GetFont()
		size = 12
		self.Header:SetFont(font, size, flags)

		while size > 6 and self.Header:GetStringWidth() > self:GetWidth() - 10 do
			size = size - 1
			self.Header:SetFont(font, size, flags)
		end
	end,

	Setup = function(self, panelInfo)
		self.panelInfo = panelInfo
		if panelInfo then
			self.supplementalData = panelInfo.supplementalData
		end


		get(self.OnSetup, self, panelInfo, self.supplementalData) 

		if type(self.supplementalData) == "table" then
			self.data = self.supplementalData

			-- Cheater! (We arent getting anything)
			-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
			get(self.supplementalData.OnSetup, self, panelInfo, self.supplementalData) 
		end

		self:CScriptCall("PanelSetup", self, panelInfo)
		self:CScriptTunnel("PanelSetup", self, panelInfo)

		self:ReloadSetting()
	end,

	AdjustHeight = function(self, bottomPadding)
		if not self:GetTop() then
			return
		end

		local top = self:GetTop() * self:GetEffectiveScale()
		local lowest = top

		if not lowest or lowest < 0 then
			return
		end

		local highest = -1

		for _, child in TMW:Vararg(self:GetChildren()) do
			if child:IsShown() then
				if child:GetBottom() then
					lowest = min(lowest, child:GetBottom() * child:GetEffectiveScale())
					highest = max(highest, child:GetTop() * child:GetEffectiveScale())
				end
			end
		end

		if highest < 0 then
			return
		end

		-- If a bottom padding isn't specified, calculate it using the same gap
		-- that exists between the highest child and the top of the frame.
		bottomPadding = bottomPadding or (top - highest)
		bottomPadding = max(bottomPadding, 0)

		self:SetHeight(max(1, top - lowest + bottomPadding)/self:GetEffectiveScale())
	end,


	BuildSimpleCheckSettingFrame = function(self, arg2, arg3)
		local className, allData, objectType
		if arg3 ~= nil then
			allData = arg3
			className = arg2
		else
			allData = arg2
			className = "Config_CheckButton"
		end

		local sig = "Config_Panel:BuildSimpleCheckSettingFrame([className,] allData)"
		TMW:ValidateType("panel",     sig, self,     "Config_Panel")
		TMW:ValidateType("className", sig, className, "string")
		TMW:ValidateType("allData",   sig, allData,   "table")

		local class = TMW.Classes[className]
		local objectType = class.isFrameObject
		
		assert(class, "Couldn't find class named " .. className .. ".")
		assert(type(objectType) == "string", "Couldn't find a WoW frame object type for class named " .. className .. ".")
		
		
		local lastCheckButton
		local numFrames = 0
		local numPerRow = allData.numPerRow or min(#allData, 2)
		self.checks = {}
		for i, data in ipairs(allData) do
			if data then -- skip over falses (dont freak out about them, they are probably intentional)

				local f = class:New(objectType, nil, self, "TellMeWhen_CheckTemplate", i)
				data(f)

				-- An human-friendly-ish unique (hopefully) identifier for the frame
				if f.setting then
					self[f.setting .. (f.value ~= nil and tostring(f.value) or "")] = f
				end

				-- I would store these directly on self,
				-- but framestack breaks catastrophically when you store frames on their parent with integer keys.
				self.checks[i] = f
				
				if lastCheckButton then
					-- Anchor it to the previous check if it isn't the first one.
					if numFrames%numPerRow == 0 then
						f:SetPoint("TOP", self.checks[i-numPerRow], "BOTTOM", 0, 2)
					else
						-- This will get overwritten soon.
						--f:SetPoint("LEFT", "RIGHT", 5, 0)
					end
				else
					-- Anchor the first check to the self. The left anchor will be handled by DistributeFrameAnchorsLaterally.
					f:SetPoint("TOP", 0, -1)
				end
				lastCheckButton = f
				
				f.row = ceil(i/numPerRow)
				
				numFrames = numFrames + 1
			end
		end
		
		-- Set the bounds of the label text on all the checkboxes to prevent overlapping.
		for i = 1, #self.checks do
			local f0 = self.checks[i]
			local f1 = self.checks[i+1]
			
			if not f1 or f1.row ~= f0.row then
				f0:ConstrainLabel(self, "RIGHT")
			else
				f0:ConstrainLabel(f1)
			end
		end
		
		for i = 1, #self.checks, numPerRow do
			IE:DistributeFrameAnchorsLaterally(self, numPerRow, unpack(self.checks, i))
		end
		
		self:AdjustHeight()
		
		return self
	end,

	OnSizeChanged = function(self)
		-- This method does resizing of the header to make it fit without truncation.
		self:SetTitle(self.Header:GetText())
	end,
}

TMW:NewClass("Config_Page", "Config_Frame"){
	OnNewInstance_Page = function(self)
		self:CScriptAdd("DescendantSettingSaved", self.RequestReloadChildren)
	end,
}

TMW:NewClass("Config_ScrollFrame", "ScrollFrame", "Config_Frame"){
	edgeScrollEnabled = false,
	edgeScrollMouseCursorRange = 20,
	edgeScrollScrollDistancePerSecond = 150,

	scrollPercentage = 1/2,
	scrollStep = nil,

	OnNewInstance_ScrollFrame = function(self)
		self:EnableMouseWheel(true)
	end,

	SetEdgeScrollEnabled = function(self, enabled, range, dps)
		self.edgeScrollEnabled = enabled
		self.edgeScrollMouseCursorRange = range or self.edgeScrollMouseCursorRange
		self.edgeScrollScrollDistancePerSecond = dps or self.edgeScrollScrollDistancePerSecond
	end,

	SetWheelStepPercentage = function(self, percent)
		self.scrollPercentage = percent
		self.scrollStep = nil
	end,

	SetWheelStepAmount = function(self, amount)
		self.scrollStep = amount
		self.scrollPercentage = nil
	end,

	OnScrollRangeChanged = function(self)
		local yrange = self:GetVerticalScrollRange()

		if floor(yrange) == 0 then
			self.ScrollBar:Hide()
		else
			self.ScrollBar:Show()
		end

		if 0 >= self:GetVerticalScroll() then
			self:SetVerticalScroll(0)
		elseif self:GetVerticalScroll() > yrange then
			self:SetVerticalScroll(yrange)
		end

		local height = self:GetHeight()
		self.percentage = height / (yrange + height)

		self.ScrollBar.Thumb:SetHeight(max(height*self.percentage, 20))

		self.ScrollBar.Thumb:SetPoint("TOP", self, "TOP", 0, -(self:GetVerticalScroll() * self.percentage))


	end,

	OnVerticalScroll = function(self, offset)
		self.ScrollBar.Thumb:SetPoint("TOP", self, "TOP", 0, -(offset * self.percentage))
	end,

	OnMouseWheel = function(self, delta)
		local scrollStep = self.scrollStep or self:GetHeight() * self.scrollPercentage
		local newScroll

		if delta > 0 then
			newScroll = self:GetVerticalScroll() - scrollStep
		else
			newScroll = self:GetVerticalScroll() + scrollStep
		end

		if newScroll < 0 then
			newScroll = 0
		elseif newScroll > self:GetVerticalScrollRange() then
			newScroll = self:GetVerticalScrollRange()
		end

		self:SetVerticalScroll(newScroll)
	end,

	OnUpdate = function(self, elapsed)
		local range = self.edgeScrollMouseCursorRange

		if  self.edgeScrollEnabled
		and not self.ScrollBar.Thumb:IsDragging()
		and self:IsMouseOver(range, 0, -range, 0) -- allow the cursor to be above/below the frame, but not to the sides
		then
			local scale = self:GetEffectiveScale()
			local self_top, self_bottom = self:GetTop()*scale, self:GetBottom()*scale

			local _, cursorY = GetCursorPosition()

			local absDistance_top = abs(self_top - cursorY)
			local absDistance_bottom = abs(self_bottom - cursorY)

			local scrollStep
			if absDistance_top > absDistance_bottom then
				-- We are closer to the bottom of the frame
				if range > absDistance_bottom then
					scrollStep = -self.edgeScrollScrollDistancePerSecond*elapsed
				end
			else
				-- We are closer to the top of the frame
				if range > absDistance_top then
					scrollStep = self.edgeScrollScrollDistancePerSecond*elapsed
				end
			end

			if scrollStep then
				local newScroll = self:GetVerticalScroll() - scrollStep

				if 0 > newScroll then
					newScroll = 0
				elseif newScroll > self:GetVerticalScrollRange() then
					newScroll = self:GetVerticalScrollRange()
				end
				self:SetVerticalScroll(newScroll)
			end
		end
	end,

	OnSizeChanged = function(self)
		-- container's width doesn't get adjusted as we resize. Fix this.
		self.container:SetWidth(self:GetWidth())
	end,
}


TMW:NewClass("Config_CheckButton", "CheckButton", "Config_Frame"){
	-- Constructor
	OnNewInstance_CheckButton = function(self)
		self:SetMotionScriptsWhileDisabled(true)
	end,

	SetTexts = function(self, title, tooltip)
		if not self.label then
			self:SetLabel(title)
		end
		self:SetTooltip(title, tooltip)
	end,

	SetLabel = function(self, label)
		self.label = label
		self.text:SetText(label)
	end,


	SetSetting = function(self, key, value)
		self.setting = key
		self.value = value
	end,

	-- Script Handlers
	OnClick = function(self, button)
		local settings = self:GetSettingTable()

		local checked = not not self:GetChecked()

		if checked then
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
		end

		if settings and self.setting then
			if self.value == nil then
				settings[self.setting] = checked
			else --if checked then
				settings[self.setting] = self.value
				self:SetChecked(true)
			end

			self:OnSettingSaved()
		end
	end,
	
	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			if self.value ~= nil then
				self:SetChecked(settings[self.setting] == self.value)
			else
				self:SetChecked(settings[self.setting])
			end
		end
	end,
}

TMW:NewClass("Config_EditBox", "EditBox", "Config_Frame"){
	
	-- Constructor
	OnNewInstance_EditBox = function(self)
		self.BackgroundText:SetWidth(self:GetWidth())

		self:CScriptAdd("ClearFocus", self.ClearFocus)
	end,

	SetTexts = function(self, title, tooltip)
		if not self.label then
			self:SetLabel(title)
		end
		self:SetTooltip(title, tooltip)
	end,

	SetLabel = function(self, label)
		self.label = label
		self:GetScript("OnTextChanged")(self)
	end,
	
	UpdateLabel = function(self, label)
		local text = self:GetText()
		if text == "" then
			self.BackgroundText:SetText(self.label)
		else
			self.BackgroundText:SetText(nil)
		end
	end,


	-- Scripts
	OnEscapePressed = function(self)
		self:ClearFocus()
	end,

	OnEnterPressed = function(self)
		if self:IsMultiLine() and IsModifierKeyDown() then
			self:Insert("\r\n")
		else
			self:ClearFocus()
		end
	end,

	OnTextChanged = function(self)
		self:UpdateLabel()
	end,

	OnEditFocusGained = function(self)
		self:HighlightText()
	end,

	OnEditFocusLost = function(self, button)
		self:HighlightText(0, 0)
		self:UpdateLabel()
		self:SaveSetting()
	end,

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
	

	-- Methods
	SaveSetting = function(self)
		local settings = self:GetSettingTable()

		if settings and self.setting then
			local value = self:GetText()
			
			value = self:CScriptCallGet("ModifySettingValueRequested", value) or value

			settings[self.setting] = value

			self:OnSettingSaved()
		end
	end,

	ReloadSetting = function(self, eventMaybe)
		local settings = self:GetSettingTable()

		if settings then
			if not (eventMaybe == "TMW_CONFIG_ICON_HISTORY_STATE_CREATED" and self:HasFocus()) and self.setting then
				self:SetText(settings[self.setting] or "")
			end
			self:ClearFocus()
		end
	end,

	SetAcceptsTMWLinks = function(self, accepts, desc)
		self.acceptsTMWLinks = accepts
		self.acceptsTMWLinksDesc = accepts and desc or nil
	end,
}

TMW:NewClass("Config_TimeEditBox", "Config_EditBox"){
	
	OnEditFocusLost = function(self, button)
		local t = TMW:CleanString(self)
		if strfind(t, ":") then
			t = TMW.toSeconds(t)
		end
		t = tonumber(t) or 0
		self:SetText(t)
		self:GetScript("OnTextChanged")(self)

		self:SaveSetting()
	end,
}

TMW:NewClass("Config_EditBoxWithCheck", "Config_Frame"){
	OnNewInstance_TimeEditBoxWithCheck = function(self)
		self.EnableCheck:CScriptAdd("ReloadRequested", self.ReloadRequested)
	end,

	ReloadRequested = function(enableCheck)
		local self = enableCheck:GetParent()
		self.Duration:SetEnabled(enableCheck:GetChecked())
	end,

	SetTexts = function(self, title, tooltip)
		self.text:SetText(title)

		self.Duration:SetLabel("")
		self.Duration:SetTexts(title, tooltip)

		self.EnableCheck:SetLabel("")
		self.EnableCheck:SetTexts(ENABLE, TMW.L["GENERIC_NUMREQ_CHECK_DESC"]:format(tooltip:gsub("^%u", strlower)))
	end,

	SetSettings = function(self, enableSetting, durationSetting)
		self.EnableCheck:SetSetting(enableSetting)
		self.Duration:SetSetting(durationSetting)
	end,
}

TMW:NewClass("Config_Slider", "Slider", "Config_Frame")
{
	-- Saving base methods.
	-- This is done in a separate call to make sure it happens before 
	-- new ones overwrite the base methods.

	Show_base = TMW.C.Config_Slider.Show,
	Hide_base = TMW.C.Config_Slider.Hide,

	SetValue_base = TMW.C.Config_Slider.SetValue,
	GetValue_base = TMW.C.Config_Slider.GetValue,

	GetValueStep_base = TMW.C.Config_Slider.GetValueStep,

	GetMinMaxValues_base = TMW.C.Config_Slider.GetMinMaxValues,
	SetMinMaxValues_base = TMW.C.Config_Slider.SetMinMaxValues,
}{

	Config_EditBox_Slider = TMW:NewClass("Config_EditBox_Slider", "Config_EditBox"){
		
		-- Constructor
		OnNewInstance_EditBox_Slider = function(self)
			self:EnableMouseWheel(true)
		end,
		

		-- Scripts
		OnEditFocusLost = function(self, button)
			local text = tonumber(self:GetText()) or 0
			if text then
				self.Slider:SetValue(text)
				self.Slider:SaveSetting()
			end

			self:SetText(self.Slider:GetValue())
		end,


		OnMouseDown = function(self, button)
			if button == "RightButton" and not self.Slider:ShouldForceEditBox() then
				self.Slider:UseSlider()
			end
		end,

		OnMouseWheel = function(self, ...)
			self.Slider:GetScript("OnMouseWheel")(self.Slider, ...)
		end,

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
		

		-- Methods
		ReloadSetting = function(self)
			self:SetText(self.Slider:GetValue())
		end,
	},

	EditBoxShowing = false,

	MODE_STATIC = 1,
	MODE_ADJUSTING = 2,

	FORCE_EDITBOX_THRESHOLD = 10e5,

	range = 10,

	formatter = TMW.C.Formatter.PASS,
	extremesFormatter = TMW.C.Formatter.PASS,

	-- Constructor
	OnNewInstance_Slider = function(self)
		self.min, self.max = self:GetMinMaxValues()

		self:SetMode(self.MODE_STATIC)
		
		self:EnableMouseWheel(true)
		self:SetExtremesColor(0.25)
	end,


	SetTexts = function(self, title, tooltip)
		self.text:SetText(title)
		self:SetTooltip(title, tooltip)
	end,

	SetExtremesColor = function(self, color)
		self.Low:SetTextColor(color, color, color, 1)
		self.High:SetTextColor(color, color, color, 1)
	end,

	-- Blizzard Overrides
	GetValue = function(self)
		if self.EditBoxShowing then
			local text = self.EditBox:GetText()
			if text == "" then
				text = 0
			end

			text = tonumber(text)
			if text then
				return self:CalculateValueRoundedToStep(text)
			end
		end

		return self:CalculateValueRoundedToStep(self:GetValue_base())
	end,
	SetValue = function(self, value)
		TMW:ValidateType("value", "SetValue(value)", value, "number")

		self.__scriptFiredOnValueChanged = nil

		if value < self.min then
			value = self.min
		elseif value > self.max then
			value = self.max
		end
		value = self:CalculateValueRoundedToStep(value)

		self:UpdateRange(value)
		self:SetValue_base(value)
		if self.EditBoxShowing then
			self.EditBox:SetText(value)
		end

		if not self.__scriptFiredOnValueChanged and value ~= self:GetValue_base() then
			self:GetScript("OnValueChanged")(self, value)
		end
	end,

	GetMinMaxValues = function(self)
		local min, max = self:GetMinMaxValues_base()

		min = self:CalculateValueRoundedToStep(min)
		max = self:CalculateValueRoundedToStep(max)

		return min, max
	end,
	SetMinMaxValues = function(self, min, max)
		min = min or -math.huge
		max = max or math.huge

		if min > max then
			error("min can't be bigger than max")
		end

		self.min = min
		self.max = max

		if self.mode == self.MODE_STATIC then
			self:SetMinMaxValues_base(min, max)
		elseif not self.EditBoxShowing then
			self:UpdateRange()
		end
	end,

	GetValueStep = function(self)
		local step = self:GetValueStep_base()
		return floor((step*10^5) + .5) / 10^5
	end,

	SetWheelStep = function(self, wheelStep)
		self.wheelStep = wheelStep
	end,
	GetWheelStep = function(self)
		return self.wheelStep or self:GetValueStep()
	end,


	Show = function(self)
		if self.EditBoxShowing then
			self.EditBox:Show()
		else
			self:Show_base()
		end
	end,
	Hide = function(self)
		self:Hide_base()
		if self.EditBoxShowing then
			self.EditBox:Hide()
		end
	end,

	-- Script Handlers
	OnMinMaxChanged = function(self)
		self:UpdateTexts()
	end,

	OnValueChanged = function(self)
		if not self.__fixingValueStep then
			self.__fixingValueStep = true
			self:SetValue_base(self:GetValue())
			self.__fixingValueStep = nil
		else
			return
		end

		self.__scriptFiredOnValueChanged = true

		if self.EditBox then
			self.EditBox:SetText(self:GetValue())
		end

		if self:ShouldForceEditBox() and not self.EditBoxShowing then
			self:SaveSetting()
			self:UseEditBox()
		end

		self:UpdateTexts()
	end,

	OnMouseDown = function(self, button)
		if not self:IsEnabled() then
			return
		end

		if button == "RightButton" then
			self:UseEditBox()

			self:ReloadSetting()
		end
	end,

	OnMouseUp = function(self)
		if not self:IsEnabled() then
			return
		end

		if self.mode == self.MODE_ADJUSTING then
			self:UpdateRange()
		end
		
		self:SaveSetting()
	end,
	
	OnMouseWheel = function(self, delta)
		if self:IsEnabled() then
			if IsShiftKeyDown() then
				delta = delta*10
			end
			if IsControlKeyDown() then
				delta = delta*60
			end
			if delta == 1 or delta == -1 then
				delta = delta*(self:GetWheelStep() or 1)
			end

			local level = self:GetValue() + delta

			self:SetValue(level)

			self:SaveSetting()
		end
	end,

	-- Methods
	SetRange = function(self, range)
		self.range = range
		self:UpdateRange()
	end,
	GetRange = function(self)
		return self.range
	end,

	CalculateValueRoundedToStep = function(self, value)
		if value == math.huge or value == -math.huge then
			return value
		end
		
		local step = self:GetValueStep()

		return floor(value * (1/step) + 0.5) / (1/step)
	end,

	SetMode = function(self, mode)
		self.mode = mode

		if mode == self.MODE_STATIC then
			self:UseSlider()
		end

		self:UpdateRange()
	end,
	GetMode = function(self)
		return self.mode
	end,


	ShouldForceEditBox = function(self)
		if self:GetMode() == self.MODE_STATIC then
			return false
		elseif self:GetValue() > self.FORCE_EDITBOX_THRESHOLD then
			return true
		end
	end,

	UseEditBox = function(self)
		if self:GetMode() == self.MODE_STATIC then
			return
		end

		if not self.EditBox then
			local name = self:GetName() and self:GetName() .. "Box" or nil
			self.EditBox = self.Config_EditBox_Slider:New("EditBox", name, self:GetParent(), "TellMeWhen_InputBoxTemplate", nil, {})
			self.EditBox.Slider = self

			self.EditBox:SetPoint("TOP", self, "TOP", 0, -4)
			self.EditBox:SetPoint("LEFT", self, "LEFT", 2, 0)
			self.EditBox:SetPoint("RIGHT", self)

			self.EditBox:SetText(self:GetValue())

			if self.ttData then
				self:SetTooltip(unpack(self.ttData))
			end
		end

		if not self.EditBoxShowing then
			PlaySound("igMainMenuOptionCheckBoxOn")
			
			self.EditBoxShowing = true
			
			if self.text:GetParent() == self then
				self.text:SetParent(self.EditBox)
			end

			self.EditBox:Show()
			self:Hide_base()

			self:ReloadSetting()
		end
	end,
	UseSlider = function(self)
		if self.EditBoxShowing then
			PlaySound("igMainMenuOptionCheckBoxOn")

			self.EditBoxShowing = false

			if self.text:GetParent() == self.EditBox then
				self.text:SetParent(self)
			end

			if self.EditBox:IsShown() then
				self:Show_base()
			end
			self.EditBox:Hide()
			self:UpdateRange()

			self:ReloadSetting()
		end
	end,


	SetTextFormatter = function(self, formatter, extremesFormatter)
		TMW:ValidateType("2 (formatter)", (self:GetName() or "<unnamed>") .. ":SetTextFormatter(formatter)", formatter, "Formatter;nil")
		TMW:ValidateType("3 (extremesFormatter)", (self:GetName() or "<unnamed>") .. ":SetTextFormatter(formatter [,extremesFormatter])", extremesFormatter, "Formatter;nil")

		self.formatter = formatter or TMW.C.Formatter.PASS
		self.extremesFormatter = extremesFormatter or formatter or TMW.C.Formatter.PASS

		self:UpdateTexts()
	end,

	SetStaticMidText = function(self, text)
		self.staticMidText = text

		self:UpdateTexts()
	end,

	TT_textFunc = function(self)
		local text = self.ttData[2]

		if not text then
			text = ""
		else
			text = text .. "\r\n\r\n"
		end

		if self:GetObjectType() == "Slider" then
			if self:GetMode() == self.MODE_ADJUSTING then
				text = text .. L["CNDT_SLIDER_DESC_CLICKSWAP_TOMANUAL"]
			else
				return self.ttData[2]
			end
		else -- EditBox
			if self.Slider:ShouldForceEditBox() then
				text = text .. L["CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER_DISALLOWED"]:format(TMW.C.Formatter.COMMANUMBER:Format(self.Slider.FORCE_EDITBOX_THRESHOLD))
			else
				text = text .. L["CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER"]
			end
		end

		return text
	end,

	SetTooltip = function(self, title, text)
		self.ttData = {title, text}

		TMW:TT(self, title, self.TT_textFunc, 1, 1)

		if self.EditBox then
			TMW:TT(self.EditBox, title, self.TT_textFunc, 1, 1)
			self.EditBox.ttData = self.ttData
		end
	end,

	UpdateTexts = function(self)
		if self.staticMidText then
			self.Mid:SetText(self.staticMidText)
		else
			self.formatter:SetFormattedText(self.Mid, self:GetValue())
		end

		local minValue, maxValue = self:GetMinMaxValues()
		
		self.extremesFormatter:SetFormattedText(self.Low, minValue)
		self.extremesFormatter:SetFormattedText(self.High, maxValue)
	end,


	UpdateRange = function(self, value)
		if self.mode == self.MODE_ADJUSTING then
			local deviation = ceil(self.range/2)
			local val = value or self:GetValue()

			local newmin = min(max(self.min, val - deviation), self.max)
			local newmax = max(min(self.max, val + deviation), self.min)
			--newmax = min(newmax, self.max)

			self:SetMinMaxValues_base(newmin, newmax)
		else
			self:SetMinMaxValues_base(self.min, self.max)
		end
	end,


	SaveSetting = function(self)
		local settings = self:GetSettingTable()

		if settings and self.setting then
		
			TMW:TT_Update(self.EditBoxShowing and self.EditBox or self)

			local value = self:GetValue()
			value = self:CScriptCallGet("ModifySettingValueRequested", value) or value
			
			settings[self.setting] = value

			self:OnSettingSaved()
		end
	end,

	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings and self.setting then

			local value = settings[self.setting]
			value = self:CScriptCallGet("UnModifySettingValueRequested", value) or value

			self:SetValue(value)
		end
	end,
}

TMW:NewClass("Config_Slider_Alpha", "Config_Slider"){
	-- Constructor
	OnNewInstance_Slider_Alpha = function(self)
		self:SetMinMaxValues(0, 1)
		self:SetValueStep(0.01)
	end,


	-- Script Handlers
	OnMinMaxChanged = function(self)
		local minValue, maxValue = self:GetMinMaxValues()
		
		self.Low:SetText(minValue * 100 .. "%")
		self.High:SetText(maxValue * 100 .. "%")
		
		self:UpdateTexts()
	end,

	METHOD_EXTENSIONS = {
		OnDisable = function(self)
			self:SetValue(0)
			self:UpdateTexts() -- For the initial disable, so text doesn't go orange
		end,
	},
	

	-- Methods
	SetOrangeValue = function(self, value)
		self.setOrangeAtValue = value
	end,
	
	UpdateTexts = function(self)
		local value = self:GetValue()
				
		if value and self:IsEnabled() then
			if value == self.setOrangeAtValue then
				self.Mid:SetText("|cffff7400" .. value * 100 .. "%")
			else
				self.Mid:SetText(value * 100 .. "%")
			end
		else
			self.Mid:SetText(value * 100 .. "%")
		end
	end,
}

TMW:NewClass("Config_BitflagBase"){
	-- Constructor
	OnNewInstance_BitflagBase = function(self)
		if self:GetID() and not self:GetSettingBit() then
			self:SetSettingBitID(self:GetID())
		end
	end,

	SetSettingBit = function(self, bit)
		self.bit = bit
	end,

	GetSettingBit = function(self)
		return self.bit
	end,

	SetSettingBitID = function(self, bitID)
		self:SetSettingBit(bit.lshift(1, bitID - 1))
	end,


	-- Script Handlers
	OnClick = function(self, button)	
		local settings = self:GetSettingTable()

		if settings and self.setting and self.bit then
			settings[self.setting] = bit.bxor(settings[self.setting], self.bit)
			
			self:OnSettingSaved()
		end
	end,
	

	-- Methods
	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			self:SetChecked(bit.band(settings[self.setting], self.bit) == self.bit)
		end
	end,
}

TMW:NewClass("Config_CheckButton_BitToggle", "Config_BitflagBase", "Config_CheckButton")

TMW:NewClass("Config_Frame_WhenChecks", "Config_Frame"){
	-- Constructor
	OnNewInstance_Frame_WhenChecks = function(self)
		
		self.Check.tmwClass = "Config_CheckButton_BitToggle"
		TMW:CInit(self.Check)
		self.Check:SetSetting("ShowWhen")
				
		TMW:CInit(self.Alpha)
		self.Alpha:SetOrangeValue(0)
		self.Alpha:CScriptAdd("ReloadRequested", self.AlphaReloadRequested)

		-- Reparent the label text on the slider so that it will be at full opacity even while disabled.
		self.Alpha.text:SetParent(self)

		self:CScriptAdd("PanelSetup", self.PanelSetup)
	end,

	-- Script Handlers
	OnEnable = function(self)
		self.Check:ReloadSetting()
		self.Alpha:ReloadSetting()
	end,
	
	OnDisable = function(self)
		self.Check:Disable()
		self.Alpha:Disable()
	end,
	

	-- Methods	
	SetSettings = function(self, alphaSettingName, bit)
		self.Alpha:SetSetting(alphaSettingName)
		self.Check:SetSettingBit(bit)

		self.bit = bit
	end,

	PanelSetup = function(self, panel, panelInfo)
		local supplementalData = panelInfo.supplementalData
		
		assert(supplementalData, "Supplemental data (arg5 to RegisterConfigPanel_XMLTemplate) must be provided for TellMeWhen_WhenChecks!")
		
		-- Set the title for the frame
		panel.Header:SetText(supplementalData.text or TMW.L["ICONMENU_SHOWWHEN"])
		
		-- Numeric keys in supplementalData point to the tables that have the data for that specified bit toggle
		local supplementalDataForBit = supplementalData[self.bit]
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
			self:Show()
		else
			self:Hide()
		end
	end,

	AlphaReloadRequested = function(slider)
		local self = slider:GetParent()
		slider:SetEnabled(self.Check:GetChecked())
	end,

	ReloadSetting = function(self)
		self:GetParent():AdjustHeight()
	end,
}

TMW:NewClass("Config_ColorButton", "Button", "Config_Frame"){
	hasOpacity = false,

	colorSettingKeys = {
		r = "r",
		g = "g",
		b = "b",
		a = "a",
	},

	OnNewInstance_ColorButton = function(self)
		assert(self.background1 and self.text and self.swatch, 
			"This setting frame doesn't inherit from TellMeWhen_ColorButtonTemplate")
	end,

	SetTexts = function(self, title, tooltip)
		self:SetTooltip(title, tooltip)
		self.text:SetText(title)
	end,
	
	OnClick = function(self, button)
		local settings = self:GetSettingTable()

		local prevRGBA = {self:GetRGBA()}
		self.prevRGBA = prevRGBA

		self:GenerateMethods()

		ColorPickerFrame.func = self.colorFunc
		ColorPickerFrame.opacityFunc = self.colorFunc
		ColorPickerFrame.cancelFunc = self.cancelFunc

		ColorPickerFrame:SetColorRGB(unpack(prevRGBA))
		ColorPickerFrame.hasOpacity = self.hasOpacity
		ColorPickerFrame.opacity = 1 - prevRGBA[4]

		ColorPickerFrame:Show()
	end,

	SetHasOpacity = function(self, hasOpacity)
		self.hasOpacity = hasOpacity

		self:ReloadSetting()
	end,

	-- We have to do this for these to have access to self.
	GenerateMethods = function(self)
		self.colorFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1 - OpacitySliderFrame:GetValue()

			self:SetRGBA(r, g, b, a)
			
			self:OnSettingSaved()
		end

		self.cancelFunc = function()
			self:SetRGBA(unpack(self.prevRGBA))
			
			self:OnSettingSaved()
		end

		self.GenerateMethods = TMW.NULLFUNC
	end,

	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			self.swatch:SetTexture(self:GetRGBA())
		end
	end,

	SetColorSettingKeys = function(self, r, g, b, a)
		self.colorSettingKeysSet = true
		self.colorSettingKeys = {
			r = r or "r",
			g = g or "g",
			b = b or "b",
			a = a or "a",
		}
	end,

	GetRGBA = function(self)
		local settings = self:GetSettingTable()
		local k = self.colorSettingKeys

		local c
		if self.setting then
			c = settings[self.setting]
		elseif self.colorSettingKeysSet then
			c = settings
		end

		if not c then
			return 0, 0, 0, 0
		elseif self.hasOpacity then
			return c[k.r], c[k.g], c[k.b], c[k.a]
		else
			return c[k.r], c[k.g], c[k.b], 1
		end
	end,

	SetRGBA = function(self, r, g, b, a)
		local settings = self:GetSettingTable()
		local k = self.colorSettingKeys

		local c
		if self.setting then
			c = settings[self.setting]
		elseif self.colorSettingKeysSet then
			c = settings
		end

		c[k.r], c[k.g], c[k.b] = r, g, b

		if self.hasOpacity then
			c[k.a] = a
		end
	end,
}

TMW:NewClass("Config_Button_Rune", "Button", "Config_BitflagBase", "Config_Frame"){
	-- Constructor
	Runes = {
		"Blood",
		"Unholy",
		"Frost",
	},

	OnNewInstance_Button_Rune = function(self)
		if not self:GetRuneNumber() then
			self:SetRuneNumber(self:GetID())
		end
	end,

	GetRuneNumber = function(self)
		return self.runeNumber
	end,

	SetRuneNumber = function(self, runeNumber)
		self.runeNumber = runeNumber

		-- detect what texture should be used
		local runeType = ((self.runeNumber-1)%6)+1 -- gives 1, 2, 3, 4, 5, 6
		local runeName = self.Runes[ceil(runeType/2)] -- Gives "Blood", "Unholy", "Frost"
		
		if self.runeNumber > 6 then
			self.texture:SetTexture("Interface\\AddOns\\TellMeWhen\\Textures\\" .. runeName)
		else
			self.texture:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-" .. runeName)
		end

		self:SetSettingBitID(self.runeNumber)
	end,


	-- Methods
	checked = false,
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
}

TMW:NewClass("Config_PointSelect", "Config_Frame"){

	SetTexts = function(self, title, tooltip)
		self.Header:SetText(title)
		self:SetTooltipBody(tooltip)
	end,

	SetTooltipBody = function(self, body)
		TMW:ValidateType("2 (body)", "SetTooltipBody", body, "string")

		assert(body:find("%%s"), "tooltip body should contain a %s that will be formatted to the point.")

		for k, v in pairs(self) do
			if type(v) == "table" and v.GetObjectType and v:GetObjectType() == "CheckButton" then
				TMW:TT(v, TMW.L[k], body:format(TMW.L[k]), 1, 1)
			end
		end
	end,

	SetSelectedPoint = function(self, point)
		TMW:ValidateType("2 (point)", "SetSelectedPoint", point, "string")

		point = tostring(point):upper()

		if not self[point] then
			error("Invalid point " .. point .. " to Config_PointSelect:SetSelected(point)")
		end

		for k, v in TMW:Vararg(self:GetChildren()) do
			if v.SetChecked then
				v:SetChecked(false)
			end
		end

		self[point]:SetChecked(true)
	end,

	SelectChild = function(self, child)
		TMW:ValidateType("2 (child)", "SelectChild", child, "frame")

		for k, v in pairs(self) do
			if v == child then

				local settings = self:GetSettingTable()

				PlaySound("igMainMenuOptionCheckBoxOn")
				self:SetSelectedPoint(k)

				if settings and self.setting then
					settings[self.setting] = k

					self:OnSettingSaved()
				end

				return
			end
		end

		error("child wasn't valid")
	end,

	GetSelectedPoint = function(self)
		for k, v in pairs(self) do
			if type(v) == "table" and v.GetObjectType and v:GetObjectType() == "Button" then
				if v:GetChecked() then
					return k
				end
			end
		end
	end,
	
	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			self:SetSelectedPoint(settings[self.setting])
		end
	end,

	OnSizeChanged = function(self)
		self.CENTER:SetSize(self:GetWidth() / 3, self:GetHeight() / 3)
	end,
}


TMW:NewClass("Config_GroupListContainer", "Config_Frame"){
	OnNewInstance_GroupListContainer = function(self)
		self:CScriptAdd("GetGroupListContainer", self.GetListContainer)
	end,

	ReloadSetting = function(self)
		self:SetDraggingGroup(nil, nil, nil)
	end,

	OnHide = function(self)
		self:SetDraggingGroup(nil, nil, nil)
	end,

	SetDraggingGroup = function(self, dragGroup, targetDomain, targetID)
		self.dragGroup = dragGroup
		self.targetDomain = targetDomain
		self.targetID = targetID

		self:RequestReloadChildren()
	end,

	GetDraggingGroup = function(self)
		return self.dragGroup, self.targetDomain, self.targetID
	end,

	GetListContainer = function(self)
		return self
	end,
}

TMW:NewClass("Config_GroupList", "Config_Frame"){
	padding = 1,
	domain = "profile",

	OnNewInstance_GroupList = function(self)
		self.frames = {}
		self:SetFrameLevel(100)

		TMW:ConvertContainerToScrollFrame(self, true, 3, 6)
		self.ScrollFrame.scrollStep = 30
	end,

	SetDomain = function(self, domain)
		self.domain = domain
	end,

	GetFrame = function(self, groupID)
		local frame = self.frames[groupID]
		if not frame then
			frame = TMW.C.Config_GroupListButton:New("CheckButton", nil, self, "TellMeWhen_GroupSelectTemplate", groupID)
			self.frames[groupID] = frame
			if groupID == 1 then
				frame:SetPoint("TOP", self.AddGroup, "BOTTOM", 0, -4)
			else
				frame:SetPoint("TOP", self.frames[groupID-1], "BOTTOM", 0, 0)
			end
		end

		return frame
	end,

	ReloadSetting = function(self)
		local groupSelect = self:CScriptBubbleGet("GetGroupListContainer")

		local dragGroup, targetDomain, targetID = groupSelect:GetDraggingGroup()

		-- If we are currently dragging a group, allow edge scrolling
		-- so that users can easily get to groups beyond the currently visible ones.
		self.ScrollFrame:SetEdgeScrollEnabled(not not dragGroup)

		local groups = {}
		for groupID = 1, TMW.db[self.domain].NumGroups do
			local group = TMW[self.domain][groupID]
			if group ~= dragGroup then
				tinsert(groups, group)
			end
		end

		if targetDomain == self.domain then
			tinsert(groups, targetID, dragGroup)
		end

		for i, group in ipairs(groups) do
			local frame = self:GetFrame(i)
			
			frame:SetGroup(group)
		end

		for i = #groups + 1, #self.frames do
			self.frames[i].group = nil
			self.frames[i]:Hide()
		end
	end,

	OnShow = function(self)
		for i = 1, #self.frames do
			local frame = self.frames[i]

			if TMW.CI.group == frame.group  then
				TMW:AdjustScrollFrame(self, frame)
				return
			end
		end
	end,

	OnUpdate = function(self)
		local groupSelect = self:CScriptBubbleGet("GetGroupListContainer")

		local group, domain, ID = groupSelect:GetDraggingGroup()
		
		if group then
			-- When the cursor enters this list for the first time, stick the group at the end.
			if self.ScrollFrame:IsMouseOver() and self.domain ~= domain then
				groupSelect:SetDraggingGroup(group, self.domain, TMW.db[self.domain].NumGroups + 1)
			end
		end
	end,
}

TMW:NewClass("Config_GroupListButton", "Config_CheckButton"){
	OnNewInstance_GroupListButton = function(self)
		self.textures = {}

		self.ID:SetText(self:GetID() .. ".")

		self:RegisterForDrag("LeftButton")
	end,

	GetTexture = function(self, i)
		if not self.textures[i] then
			self.textures[i] = self:CreateTexture(nil, "OVERLAY")
			local dim = self:GetHeight() - 2
			self.textures[i]:SetSize(dim, dim)
		end

		if i == 1 then
			self.textures[i]:SetPoint("RIGHT", -1, 0)
		else
			self.textures[i]:SetPoint("RIGHT", self.textures[i-1], "LEFT", -2, 0)
		end

		self.textures[i]:Show()
		self.textures[i]:SetDesaturated(false)

		return self.textures[i]
	end,

	SetGroup = function(self, group)
		TMW:ValidateType("group", "Config_GroupListButton:SetGroup(group)", group, "Group")

		local gs = group:GetSettings()

		if gs.Name ~= "" then
			self.Name:SetText(gs.Name)
		else
			self.Name:SetText(L["TEXTLAYOUTS_UNNAMED"])
		end

		self.group = group

		self:SetChecked(TMW.CI.group == group )
		self:Show()

		local tooltipText = ""

		local textureIndex = 1
		local isSpecLimited
		local isUnavailable

		if not group:IsEnabled() then
			local tex = self:GetTexture(textureIndex)
			textureIndex = textureIndex + 1

			tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			tex:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
			tex:SetDesaturated(true)

			tooltipText = tooltipText .. "\r\n" .. L["DISABLED"]
		else
			if group.Domain == "profile" then
				-- Indicator for primary/secondary spec configuration.
				-- The massive numbers seen in SetTexCoord here are to create triangular textures.
				if not gs.PrimarySpec or not gs.SecondarySpec then
					if not gs.PrimarySpec and not gs.SecondarySpec then
						isUnavailable = true
					else
						local spec1 = GetSpecialization(false, false, 1)
						if spec1 then
							local tex = self:GetTexture(textureIndex)
							textureIndex = textureIndex + 1

							local _, name, _, texture = GetSpecializationInfo(spec1)
							tex:SetTexCoord(0.07, 0.07, 0.07, 0.93, 0.93, 0.07, 1000, -1000) -- topleft triangle of the square
							tex:SetTexture(texture)
							tex:SetDesaturated(not gs.PrimarySpec)
						end

						local spec2 = GetSpecialization(false, false, 2)
						if spec2 then
							local tex2 = self:GetTexture(textureIndex)
							textureIndex = textureIndex + 1
							tex2:SetPoint("RIGHT", tex)
							local _, name, _, texture = GetSpecializationInfo(spec2)
							tex2:SetTexCoord(1000, -1000, 0.07, 0.93, 0.93, 0.07, 0.93, 0.93) -- bottomright triangle of the square
							tex2:SetTexture(texture)
							tex2:SetDesaturated(not gs.SecondarySpec)
						end
					end
				end

				-- Indicator for talent tree (specialization) configuration.
				for i = 1, GetNumSpecializations() do
					if not gs["Tree" .. i] then
						isSpecLimited = true
						break
					end
				end
				if isSpecLimited then
					-- Iterate backwards so they appear in the correct order
					-- (since they are positioned from right to left, not left to right)
					local foundOne
					for i = GetNumSpecializations(), 1, -1 do
						if gs["Tree" .. i] then
							local _, name, _, texture = GetSpecializationInfo(i)

							local tex = self:GetTexture(textureIndex)
							textureIndex = textureIndex + 1

							tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
							tex:SetTexture(texture)
							foundOne = true
						end
					end
					if not foundOne then
						isUnavailable = true
					end
				end
			end

			-- Indicator for role configuration.
			if not isSpecLimited and gs.Role ~= 0x7 then
				if gs.Role == 0 then
					isUnavailable = true
				else
					for bitID, role in TMW:Vararg("DAMAGER", "HEALER", "TANK") do
						if bit.band(gs.Role, bit.lshift(1, bitID - 1)) > 0 then
							local tex = self:GetTexture(textureIndex)
							textureIndex = textureIndex + 1

							tex:SetTexture("Interface\\Addons\\TellMeWhen\\Textures\\" .. role)
						end
					end
				end
			end

			if isUnavailable then
				local tex = self:GetTexture(textureIndex)
				textureIndex = textureIndex + 1

				tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
				tex:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")

				tooltipText = tooltipText .. "\r\n" .. L["GROUP_UNAVAILABLE"]
			end
		end

		tooltipText = tooltipText .. "\r\n\r\n" .. L["GROUPSELECT_TOOLTIP"]
		tooltipText = tooltipText:trim(" \t\r\n")

		TMW:TT(self, group:GetGroupName(1), tooltipText, 1, 1)

		if textureIndex > 1 then
			self.Name:SetPoint("RIGHT", self.textures[textureIndex-1], "LEFT", -3, 0)
		else
			self.Name:SetPoint("RIGHT", -3, 0)
		end


		for i = textureIndex, #self.textures do
			self.textures[i]:Hide()
		end
	end,

	OnDragStart = function(self)
		print("OnDragStart", self)
		local groupSelect = self:CScriptBubbleGet("GetGroupListContainer")
		
		groupSelect:SetDraggingGroup(self.group, self.group.Domain, self.group.ID)
	end,

	OnDragStop = function(self)
		print("OnDragStop", self)
		local groupSelect = self:CScriptBubbleGet("GetGroupListContainer")
		
		local group, domain, ID = groupSelect:GetDraggingGroup()
		groupSelect:SetDraggingGroup(nil, nil, nil)

		TMW:Group_Insert(group, domain, ID)

		-- It will be hidden when the global update happens.
		-- We should keep it shown, though.
		groupSelect:Show()
	end,

	OnUpdate = function(self)
		local list = self:GetParent()
		local groupSelect = self:CScriptBubbleGet("GetGroupListContainer")

		local group, domain, ID = groupSelect:GetDraggingGroup()
		
		if group then
			if self:IsMouseOver() and self.group ~= group then

				groupSelect:SetDraggingGroup(group, list.domain, self:GetID())
				GameTooltip:Hide()
			elseif not IsMouseButtonDown() then
				self:OnDragStop()
			end
		end
	end,
}


function IE:SaveSettings()
	IE:CScriptTunnel("ClearFocus")

	TMW:Fire("TMW_CONFIG_SAVE_SETTINGS")
end


---------- Equivalancies ----------
function IE:Equiv_GenerateTips(equiv)
	local IDs = TMW:SplitNames(TMW.EquivFullIDLookup[equiv])
	local original = TMW:SplitNames(TMW.EquivOriginalLookup[equiv])

	for k, v in pairs(IDs) do
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

		-- If this spell is tracked only by ID, add the ID in parenthesis
		local originalSpell = tostring(original[k])
		if originalSpell:sub(1, 1) ~= "_" then
			name = format("%s |cff7f6600(%d)|r", name, originalSpell)
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
	for _, typeData in ipairs(TMW.OrderedTypes) do
		if CI.ics.Type == typeData.type or not get(typeData.hidden) then
			if typeData.menuSpaceBefore then
				TMW.DD:AddSpacer()
			end

			local info = TMW.DD:CreateInfo()
			
			info.text = get(typeData.name)
			info.value = typeData.type
			
			local allowed = typeData:IsAllowedByView(CI.icon.viewData.view)
			info.disabled = not allowed

			local desc = get(typeData.desc)
				
			if not allowed then
				desc = (desc and desc .. "\r\n\r\n" or "") .. L["ICONMENU_TYPE_DISABLED_BY_VIEW"]:format(CI.icon.viewData.name)
			end

			if typeData.canControlGroup then
				desc = (desc and desc .. "\r\n\r\n" or "") .. L["ICONMENU_TYPE_CANCONTROL"]
			end

			if desc then
				info.tooltipTitle = typeData.tooltipTitle or info.text
				info.tooltipText = desc
				info.tooltipWhileDisabled = true
			end
			
			info.checked = (info.value == CI.ics.Type)
			info.func = IE.Type_Dropdown_OnClick
			info.arg1 = typeData
			
			info.icon = get(typeData.menuIcon)
			info.tCoordLeft = 0.07
			info.tCoordRight = 0.93
			info.tCoordTop = 0.07
			info.tCoordBottom = 0.93
				
			TMW.DD:AddButton(info)

			if typeData.menuSpaceAfter then
				TMW.DD:AddSpacer()
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

	CI.icon:SetInfo("texture", nil)

	local oldType = CI.ics.Type
	CI.ics.Type = self.value

	TMW:Fire("TMW_CONFIG_ICON_TYPE_CHANGED", CI.icon, CI.ics.Type, oldType)
	
	CI.icon:Setup()
	
	IE:LoadIcon(1)
end


---------- Tooltips ----------
--local cachednames = {}
function IE:GetRealNames(Name)
	-- gets a table of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names

	local outTable = {}

	local text = TMW:CleanString(Name)
	
	local CI_typeData = Types[CI.ics.Type]
	local checksItems = CI_typeData.checksItems
	
	-- Note 11/12/12 (WoW 5.0.4) - caching causes incorrect results with "replacement spells" after switching specs like the corruption/immolate pair 
	--if cachednames[CI.ics.Type .. SoI .. text] then return cachednames[CI.ics.Type .. SoI .. text] end

	local tbl
	if checksItems then
		tbl = TMW:GetItems(text)
	else
		tbl = TMW:GetSpells(text).Array
	end
	local durations = TMW:GetSpells(text).Durations

	local Cache = TMW:GetModule("SpellCache"):GetCache()
	
	for k, v in pairs(tbl) do
		local name, texture
		if checksItems then
			name = v:GetName() or v.what or ""
			texture = v:GetIcon()
		else
			name, _, texture = GetSpellInfo(v)
			texture = texture or GetSpellTexture(name or v)
			
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

			texture = texture or GetSpellTexture(name)
		end

		local dur = ""
		if CI_typeData.DurationSyntax or durations[k] > 0 then
			dur = ": "..TMW:FormatSeconds(durations[k])
		end

		local str = (texture and ("|T" .. texture .. ":0|t") or "") .. name .. dur

		if type(v) == "number" and tonumber(name) ~= v then
			str = str .. format(" |cff7f6600(%d)|r", v)
		end

		tinsert(outTable,  str)
	end

	return outTable
end

function GameTooltip:TMW_AddSpellBreakdown(tbl)
	if #tbl <= 0 then
		return
	end

	GameTooltip:AddLine(" ")

	local numLines = GameTooltip:NumLines()
	
	-- Need to do this so that we can get the widths of the lines.
	GameTooltip:Show()
	
	
	local longest = 100
	for i = 1, numLines do
		longest = max(longest, _G["GameTooltipTextLeft" .. i]:GetWidth())
	end


	-- Completely unscientific adjustment to prevent extremely tall tooltips:
	longest = max(longest, #tbl*3)

	
	local numLines = numLines + 1
	
	local i = 1
	
	while i <= #tbl do
		while _G["GameTooltipTextLeft" .. numLines]:GetStringWidth() < longest and i <= #tbl do
			local fs = _G["GameTooltipTextLeft" .. numLines]
			local s = tostring(tbl[i]):trim(" ")
			if fs:GetText() == nil then
				GameTooltip:AddLine(s, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, nil)
			else
				fs:SetText(fs:GetText() .. "; " .. s)
			end
			i = i + 1
		end
		numLines = numLines + 1
	end
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

	TMW.DD:CloseDropDownMenus()

	TMW:Fire("TMW_IMPORT_PRE", SettingsItem, ...)
	
	local SharableDataType = TMW.approachTable(TMW, "Classes", "SharableDataType", "types", SettingsItem.Type)
	if SharableDataType and SharableDataType.Import_ImportData then
		SharableDataType:Import_ImportData(SettingsItem, ...)

		TMW:Update()
		-- TODO: figure out what should happen here.
		IE:Load(1)
		
		TMW:Print(L["IMPORT_SUCCESSFUL"])
	else
		TMW:Print(L["IMPORTERROR_INVALIDTYPE"])
	end

	TMW:Fire("TMW_IMPORT_POST", SettingsItem, ...)
	
	TMW.ACEOPTIONS:CompileOptions()
	TMW.ACEOPTIONS:NotifyChanges()
end

function TMW:ImportPendingConfirmation(SettingsItem, luaDetections, callArgsAfterSuccess)
	TellMeWhen_ConfirmImportedLuaDialog:StartConfirmations(SettingsItem, luaDetections, callArgsAfterSuccess)
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

			import.group_overwrite = CI.icon.group
			export.group = CI.icon.group

		elseif IE.CurrentTab.doesGroup then	
			import.group_overwrite = CI.group
			export.group = CI.group
		end
	end
end)

TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox.IsImportExportWidget then
		local info = editbox.obj.userdata
		
		import.group_overwrite = TMW.FindGroupFromInfo(info)
		export.group = TMW.FindGroupFromInfo(info)
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
		path = path .. v .. "."
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
			if icon.lastChangePath == result and IE.RapidSettings[changedSetting] and icon.historyState > 1 then
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

	TMW.CI.icon.group:GetSettings().Icons[CI.icon.ID] = nil -- recreated when passed into CTIPWM
	TMW:CopyTableInPlaceWithMeta(icon.history[icon.historyState], CI.ics)
	
	CI.icon:Setup() -- do an immediate setup for good measure
	
	TMW:Fire("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", icon)

	TMW.DD:CloseDropDownMenus()
	IE:LoadIcon(1)
	
	IE:UndoRedoChanged()
end


---------- Interface ----------
function IE:UndoRedoChanged()
	if not IE.CurrentTab or not IE.CurrentTab.doesIcon then
		IE.UndoButton:Disable()
		IE.RedoButton:Disable()

		return
	end

	local icon = CI.icon

	if icon then
		if not icon.historyState or icon.historyState - 1 < 1 then
			IE.UndoButton:Disable()
		else
			IE.UndoButton:Enable()
		end

		if not icon.historyState or icon.historyState + 1 > #icon.history then
			IE.RedoButton:Disable()
		else
			IE.RedoButton:Enable()
		end
	end
end


---------- Back/Fowards ----------
function IE:DoBackForwards(direction)
	if not IE.history[IE.historyState + direction] then return end -- not valid, so don't try

	IE.historyState = IE.historyState + direction

	TMW.DD:CloseDropDownMenus()
	IE:LoadIcon(nil, IE.history[IE.historyState], true)

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
-- CHANGELOG
-- ----------------------

local changelogEnd = "<p align='center'>|cff666666To see the changelog for versions up to v" ..
(TMW.CHANGELOG_LASTVER or "???") .. ", click the tab below again.|r</p>"
local changelogEndAll = "<p align='center'>|cff666666For older versions, visit TellMeWhen's AddOn page on Curse.com|r</p><br/>"

function IE:ShowChangelog(lastVer)

	IE.TabGroups.MAIN.CHANGELOG:Click()

	if not lastVer then lastVer = 0 end

	local CHANGELOGS = IE:ProcessChangelogData()

	local texts = {}

	for version, text in TMW:OrderedPairs(CHANGELOGS, nil, nil, true) do
		if lastVer >= version then
			if lastVer > 0 then
				text = text:gsub("</h1>", " (" .. L["CHANGELOG_LAST_VERSION"] .. ")</h1>")
			end
				
			tinsert(texts, text)
			break
		else
			tinsert(texts, text)
		end
	end

	-- The intro text, before any actual changelog entries
	tinsert(texts, 1, "<p align='center'>|cff999999" .. L["CHANGELOG_INFO2"]:format(TELLMEWHEN_VERSION_FULL) .. "|r</p>")

	if lastVer > 0 then
		tinsert(texts, changelogEnd .. changelogEndAll)
	else
		tinsert(texts, changelogEndAll)
	end

	local Container = IE.Pages.Changelog.Container

	local body = format("<html><body>%s</body></html>", table.concat(texts, "<br/>"))
	Container.HTML:SetText(body)

	-- This has to be stored because there is no GetText method.
	Container.HTML.text = body

	IE.Pages.Changelog.ScrollFrame:SetVerticalScroll(0)
	Container:GetScript("OnSizeChanged")(Container)
end

local function htmlEscape(char)
	if char == "&" then
		return "&amp;"
	elseif char == "<" then
		return "&lt;"
	elseif char == ">" then
		return "&gt;"
	end
end

local bulletColors = {
	"4FD678",
	"2F99FF",
	"F62FAD",
}

local function bullets(b, text)
	local numDashes = #b 
	
	if numDashes <= 0 then
		return "><p>" .. text .. "</p><"
	end

	local color = bulletColors[(numDashes-1) % #bulletColors + 1]
	
	-- This is not a regular space. It is U+2002 - EN SPACE
	local dashes = (" "):rep(numDashes) .. "•"

	return "><p>|cFF" .. color .. dashes .. " |r" .. text .. "</p><"
end

local CHANGELOGS
function IE:ProcessChangelogData()
	if CHANGELOGS then
		return CHANGELOGS
	end

	CHANGELOGS = {}

	if not TMW.CHANGELOG then
		TMW:Error("There was an error loading TMW's changelog data.")
		TMW:Print("There was an error loading TMW's changelog data.")

		return CHANGELOGS
	end

	local log = TMW.CHANGELOG

	log = log:gsub("([&<>])", htmlEscape)        
	log = log:trim(" \t\r\n")

	-- Replace 4 equals with h2
	log = log:gsub("[ \t]*====(.-)====[ \t]*", "<h2>%1</h2>")

	-- Replace 3 equals with h1, formatting as a version name
	log = log:gsub("[ \t]*===(.-)===[ \t]*", "<h1>TellMeWhen %1</h1>")

	-- Remove extra space after closing header tags
	log = log:gsub("(</h.>)%s*", "%1")

	-- Remove extra space before opening header tags.
	log = log:gsub("%s*(<h.>)", "%1")

	-- Convert newlines to <br/>
	log = log:gsub("\r\n", "<br/>")
	log = log:gsub("\n", "<br/>")

	-- Put a break at the end for the next gsub - it relies on a tag of some kind
	-- being at the end of each line.
	log = log .. "<br/>"

	-- Convert asterisks to colored dashes
	log = log:gsub(">%s*(*+)%s*(.-)<", bullets)

	-- Remove double breaks 
	log = log:gsub("<br/><br/>", "<br/>")

	-- Remove breaks between paragraphs
	log = log:gsub("</p><br/><p>", "</p><p>")

	-- Add breaks between paragraphs and h2ss
	-- Put an empty paragraph in since they are smaller than a full break.
	log = log:gsub("</p>%s*<h2>", "</p><p> </p><h2>")

	-- Add a "General" header before the first paragraph after an h1
	log = log:gsub("</h1>%s*<p>", "</h1><h2>General</h2><p>")

	-- Make the phrase "IMPORTANT" be red.
	log = log:gsub("IMPORTANT", "|cffff0000IMPORTANT|r")


	local subStart, subEnd = 0, 0
	repeat
		local done

		-- Find the start of a version
		subStart, endH1 = log:find("<h1>", subEnd)

		-- Find the start of the next version
		subEnd = log:find("<h1>", endH1)

		if not subEnd then
			-- We're at the end of the data. Set the length of the data as the end position.
			subEnd = #log
			done = true
		else
			-- We want to end just before the start of the next version.
			subEnd = subEnd - 1
		end

		local versionString = log:match("TellMeWhen v([0-9%.]+)", subStart):gsub("%.", "")
		local versionNumber = tonumber(versionString) * 100
		
		-- A full version's changelog is between subStart and subEnd. Store it.
		CHANGELOGS[versionNumber] = log:sub(subStart, subEnd)
	until done

	-- Send this out to the garbage collector
	TMW.CHANGELOG = nil

	return CHANGELOGS
end


