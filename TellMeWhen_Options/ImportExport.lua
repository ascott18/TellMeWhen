local TMW = TMW
if not TMW then return end

-- GLOBALS: TELLMEWHEN_VERSIONNUMBER
-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE
-- GLOBALS: UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, CloseDropDownMenus

local print = TMW.print
local L = TMW.L
local get = TMW.get
local AddDropdownSpacer = TMW.AddDropdownSpacer

local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, rawget =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, rawget
local strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower, floor, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower, floor, log10

local CurrentSourceOrDestinationHandler

-- -----------------------
-- DATA TYPES
-- -----------------------

local SharableDataType = TMW:NewClass("SharableDataType")
SharableDataType.types = {}

function SharableDataType:OnNewInstance(type)
	self.type = type
	SharableDataType.types[type] = self
end


---------- Database ----------
local database = SharableDataType:New("database")
function database:Import_BuildContainingDropdownEntry(result)
	-- this is currently unused. Do something with it if it ever does get used
	--(but it is unlikely that i will ever use it)
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["<DATABASE>"]
	info.value = result
	info.hasArrow = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end
function database:Import_BuildMenuData(result, editbox)
	local db = result.data
	-- current profile
	local currentProfile = TMW.db:GetCurrentProfile()
	
	assert(currentProfile)
	assert(db.profiles[currentProfile])
	
	SharableDataType.types.global:Import_BuildContainingDropdownEntry
	{
		parentResult = result,
		data = db.profiles[currentProfile],
		type = "global",
		version = db.profiles[currentProfile].Version,
		[1] = currentProfile,
	}

	AddDropdownSpacer()

	--other profiles
	for profilename, profiletable in TMW:OrderedPairs(db.profiles) do
		-- current profile and default are handled separately
		if profilename ~= currentProfile and profilename ~= "Default" then
			SharableDataType.types.global:Import_BuildContainingDropdownEntry
			{
				parentResult = result,
				data = profiletable,
				type = "global",
				version = profiletable.Version,
				[1] = profilename,
			}
		end
	end

	--default profile
	if db.profiles["Default"] and currentProfile ~= "Default" then
		SharableDataType.types.global:Import_BuildContainingDropdownEntry
		{
			parentResult = result,
			data = db.profiles.Default,
			type = "global",
			version = db.profiles.Default.Version,
			[1] = "Default",
		}
	end
end

function database:Export_SetButtonAttributes(editbox, info)
	-- CURRENTLY UNUSED
end
function database:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	-- CURRENTLY UNUSED
end


---------- Global ----------
local global = SharableDataType:New("global")

function global:Import_ImportData(editbox, data, version, noOverwrite)
	if noOverwrite then -- noOverwrite is a name in this case.

		local base = gsub(noOverwrite, " %(%d+%)$", "")
		local newnum = 1

		-- generate a new name if the profile already exists
		local newname
		while not newname or TMW.db.profiles[newname] do
			newnum = newnum + 1
			newname = base .. " (" .. newnum .. ")"
		end

		-- put the data in the profile (no reason to CTIPWM when we can just do this) and set the profile
		TMW.db.profiles[newname] = data
		TMW.db:SetProfile(newname)
	else
		TMW.db:ResetProfile()
		TMW:CopyTableInPlaceWithMeta(data, TMW.db.profile, true)
	end

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:Upgrade()
		end
	end
end
function global:Import_BuildContainingDropdownEntry(result)
	local info = UIDropDownMenu_CreateInfo()
	info.text = result[1]
	info.value = result
	info.hasArrow = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end
function global:Import_BuildMenuData(result, editbox)
	-- header
	local info = UIDropDownMenu_CreateInfo()
	info.text = result[1]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire profile - overwrite current
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_OVERWRITE"]:format(TMW.db:GetCurrentProfile())
	info.func = function()
		TMW:Import(editbox, result.data, result.version, "global")
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire profile - create new profile
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_NEW"]
	info.func = function()
		TMW:Import(editbox, result.data, result.version, "global", result[1]) -- newname forces a new profile to be created named newname
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	AddDropdownSpacer()
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["TEXTLAYOUTS"]
	info.notCheckable = true
	info.hasArrow = true
	info.value = {
		isHolderMenu = true,
		result = result,
		type = "textlayout",
	}
	info.disabled = not (result.data.TextLayouts and next(result.data.TextLayouts))
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	AddDropdownSpacer()
	
	-- group header
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_GROUPS"]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- add groups to be copied
	for groupID, gs in TMW:OrderedPairs(result.data.Groups) do
		if type(groupID) == "number" and groupID >= 1 and groupID <= (tonumber(result.data.NumGroups) or 10) then
			SharableDataType.types.group:Import_BuildContainingDropdownEntry
			{
				parentResult = result,
				data = gs,
				type = "group",
				version = result.version,
				[1] = groupID,
			}
		end
	end
	
end

global.Export_DataTypeDescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("4.6.0+")
function global:Export_SetButtonAttributes(editbox, info)
	local text = L["fPROFILE"]:format(TMW.db:GetCurrentProfile())
	info.text = text
	info.tooltipTitle = text
end
function global:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	return editbox, self.type, TMW.db.profile, TMW.Defaults.profile, TMW.db:GetCurrentProfile()
end


---------- Group ----------
local group = SharableDataType:New("group")

function group:Import_ImportData(editbox, data, version, noOverwrite, oldgroupID, destgroupID)
	if noOverwrite then
		destgroupID = TMW:Group_Add()
	end
	TMW.db.profile.Groups[destgroupID] = nil -- restore defaults, table recreated when passed in to CTIPWM
	local gs = TMW.db.profile.Groups[destgroupID]
	TMW:CopyTableInPlaceWithMeta(data, gs, true)

	-- change any meta icon components to the new group if the meta and components are/were in the same group (icon conditions, too)
	if oldgroupID then
		local srcgr, destgr = "TellMeWhen_Group"..oldgroupID, TMW[destgroupID]:GetName()

		TMW:ReconcileData(srcgr, destgr, srcgr, destgr, nil, destgroupID)
	end

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("group", version, gs, destgroupID)
		end
	end
end
function group:Import_BuildContainingDropdownEntry(result)
	local groupID = result[1]
	local gs = result.data
	local info = UIDropDownMenu_CreateInfo()
	info.text = TMW:GetGroupName(gs.Name, groupID)
	info.value = result
	info.hasArrow = true
	info.notCheckable = true
	info.tooltipTitle = format(L["fGROUP"], groupID)
	info.tooltipText = 	(L["UIPANEL_ROWS"] .. ": " .. (gs.Rows or 1) .. "\r\n") ..
					L["UIPANEL_COLUMNS"] .. ": " .. (gs.Columns or 4) ..
					((gs.PrimarySpec or gs.PrimarySpec == nil) and "\r\n" .. L["UIPANEL_PRIMARYSPEC"] or "") ..
					((gs.SecondarySpec or gs.SecondarySpec == nil) and "\r\n" .. L["UIPANEL_SECONDARYSPEC"] or "") ..
					((gs.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")
	info.tooltipOnButton = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end
function group:Import_BuildMenuData(result, editbox)
	local groupID = result[1]
	local gs = result.data
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	-- header
	local info = UIDropDownMenu_CreateInfo()
	local profilename = TMW.approachTable(result, "parentResult", 1)
	info.text = (profilename and profilename .. ": " or "") .. TMW:GetGroupName(gs.Name, groupID)
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy group position
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["COPYPOSSCALE"]
	info.func = function()
		CloseDropDownMenus()
		local destgroupID = IMPORTS.group_overwrite
		local destgs = TMW.db.profile.Groups[destgroupID]
		
		-- not a special table (["**"]), so just normally copy it.
		-- Setting it nil won't recreate it like other settings tables, so re-copy from defaults
		destgs.Point = CopyTable(TMW.Group_Defaults.Point)
		
		TMW:CopyTableInPlaceWithMeta(destgs.Point, destgs.Point, true)

		destgs.Scale = destgs.Scale or TMW.Group_Defaults.Scale
		destgs.Level = destgs.Level or TMW.Group_Defaults.Level
		TMW[destgroupID]:Setup()
	end
	info.notCheckable = true
	info.disabled = not IMPORTS.group_overwrite
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire group - overwrite current
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["OVERWRITEGROUP"]:format(IMPORTS.group_overwrite and TMW:GetGroupName(IMPORTS.group_overwrite, IMPORTS.group_overwrite, 1) or "?")
	info.func = function()
		TMW:Import(editbox, gs, result.version, "group", nil, groupID, IMPORTS.group_overwrite)
	end
	info.notCheckable = true
	info.disabled = not IMPORTS.group_overwrite
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire group - create new group
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["MAKENEWGROUP"]
	info.func = function()
		TMW:Import(editbox, gs, result.version, "group", true, groupID, IMPORTS.group_new) -- true forces a new group to be created
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	if gs.Icons and next(gs.Icons) then
		AddDropdownSpacer()

		-- icon header
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["UIPANEL_ICONS"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)


		-- add individual icons
		for iconID, ics in TMW:OrderedPairs(gs.Icons) do
			SharableDataType.types.icon:Import_BuildContainingDropdownEntry({
				data = ics,
				version = result.version,
				type = "icon",
				[1] = iconID,
			}, editbox)
		end
	end
end

group.Export_DataTypeDescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("4.6.0+")
function group:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local groupID = EXPORTS[self.type]
	
	local text = format(L["fGROUP"]:format(TMW:GetGroupName(groupID, groupID, 1)))
	info.text = text
	info.tooltipTitle = text
end
function group:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local groupID = EXPORTS[self.type]
	
	return editbox, self.type, TMW[groupID]:GetSettings(), TMW.Group_Defaults, groupID
end


---------- Icon ----------
local icon = SharableDataType:New("icon")

function icon:Import_ImportData(editbox, data, version)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	local groupID, iconID = IMPORTS.group_overwrite, IMPORTS.icon
	TMW.db.profile.Groups[groupID].Icons[iconID] = nil -- restore defaults
	local ics = TMW.db.profile.Groups[groupID].Icons[iconID]
	TMW:CopyTableInPlaceWithMeta(data, ics, true)

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("icon", version, ics, groupID, iconID)
		end
	end
end
function icon:Import_BuildContainingDropdownEntry(result, editbox)
	local ics = result.data
	local iconID = tonumber(result[1])
	local groupID = TMW.approachTable(result, "parentResult", 1)
	local profilename = TMW.approachTable(result, "parentResult", "parentResult", 1)
	local gs = TMW.approachTable(result, "parentResult", "data")
	local version = result.version
	
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	if not TMW.IE:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
		local info = UIDropDownMenu_CreateInfo()

		local tex
		local ic = TMW.db:GetCurrentProfile() == profilename and groupID and iconID and TMW[groupID] and TMW[groupID][iconID]
		if ic and ic.attributes.texture then
			tex = ic.attributes.texture
			info.value = ic -- holy shit, is this hacktastic or what?
		else
			tex = TMW:GuessIconTexture(ics)
			info.value = false
		end

		local text, textshort, tooltipText = TMW:GetIconMenuText(groupID, iconID, ics)
		if text:sub(-2) == "))" and iconID then
			textshort = textshort .. " " .. L["fICON"]:format(iconID)
		end
		info.text = textshort
		info.tooltipTitle = groupID and format(L["GROUPICON"], TMW:GetGroupName(gs and gs.Name, groupID, 1), iconID) or L["ICON"]
		info.tooltipText = tooltipText
		info.tooltipOnButton = true

		info.notCheckable = true

		info.icon = tex
		info.tCoordLeft = 0.07
		info.tCoordRight = 0.93
		info.tCoordTop = 0.07
		info.tCoordBottom = 0.93

		info.func = function()
			-- self.value is the icon (maybe, if it's a string then we aren't importing from an icon in the current profile)
			if ic and ic:IsVisible() then
				TMW.HELP:Show("ICON_IMPORT_CURRENTPROFILE", nil, editbox, 0, 0, L["HELP_IMPORT_CURRENTPROFILE"])
				TMW[IMPORTS.group_overwrite][IMPORTS.icon]:SetInfo("texture", tex)
			else
				TMW[IMPORTS.group_overwrite][IMPORTS.icon]:SetInfo("texture", nil)
			end
			
			if gs then
				TMW:PrepareIconSettingsForCopying(ics, gs)
			end
			
			TMW:Import(editbox, ics, version, "icon")
		end
		info.arg1 = ics
		info.arg2 = version

		info.disabled = not IMPORTS.icon

		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end
icon.Import_BuildMenuData = icon.Import_BuildContainingDropdownEntry

function icon:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local groupID = EXPORTS.group
	local iconID = EXPORTS.icon
	
	local text = format(L["fICON"]:format(iconID, TMW:GetGroupName(groupID, groupID, 1)))
	info.text = text
	info.tooltipTitle = text
end
function icon:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local groupID = EXPORTS.group
	local iconID = EXPORTS.icon
	
	local gs = TMW.db.profile.Groups[groupID]
	local ics = gs.Icons[iconID]
	TMW:PrepareIconSettingsForCopying(ics, gs)
	
	return editbox, self.type, ics, TMW.Icon_Defaults
end


---------- Text Layout ----------
local textlayout = SharableDataType:New("textlayout")

function textlayout:Import_ImportData(editbox, data, version, GUID)
	assert(type(GUID) == "string")
	TMW.db.profile.TextLayouts[GUID] = nil -- restore defaults
	local textlayout = TMW.db.profile.TextLayouts[GUID]
	TMW:CopyTableInPlaceWithMeta(data, textlayout, true)
	textlayout.GUID = GUID

	if textlayout.NoEdit then
		textlayout.NoEdit = false -- must be false, not nil
	end
	
	repeat
		local found
		for k, layoutSettings in pairs(TMW.db.profile.TextLayouts) do
			if layoutSettings ~= textlayout and layoutSettings.Name == textlayout.Name then
				textlayout.Name = TMW.oneUpString(textlayout.Name)
				found = true
				break
			end
		end
	until not found
	
	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("textlayout", version, GUID)
		end
	end
	TMW:Update()
end
function textlayout:Import_HolderMenuHandler(result, editbox)
	local TextLayouts = result.data.TextLayouts
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["TEXTLAYOUTS"]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	AddDropdownSpacer()
	
	if TextLayouts then
		for GUID, settings in pairs(TextLayouts) do
			self:Import_BuildContainingDropdownEntry({
				data = settings,
				type = self.type,
				version = result.version,
				[1] = GUID,
			}, editbox)
		end
	end
end
function textlayout:Import_BuildContainingDropdownEntry(result, editbox)	
	local settings = result.data
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = TMW.TEXT:GetLayoutName(settings, result[1])
	info.value = result
	info.hasArrow = true
	info.notCheckable = true
	--info.tooltipTitle = format(L["fGROUP"], groupID)
	--info.tooltipText = 
--	info.tooltipOnButton = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end
function textlayout:Import_BuildMenuData(result, editbox)
	local settings = result.data
	local GUID = result[1]
	assert(type(GUID) == "string")
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = TMW.TEXT:GetLayoutName(settings, GUID)
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	AddDropdownSpacer()
	
	if rawget(TMW.db.profile.TextLayouts, GUID) then
		-- overwrite existing
		local info = UIDropDownMenu_CreateInfo()
		info.disabled = TMW.db.profile.TextLayouts[GUID].NoEdit
		info.text = L["TEXTLAYOUTS_IMPORT"] .. " - " .. L["TEXTLAYOUTS_IMPORT_OVERWRITE"]
		info.tooltipTitle = info.text
		info.tooltipText = info.disabled and L["TEXTLAYOUTS_IMPORT_OVERWRITE_DISABLED_DESC"] or L["TEXTLAYOUTS_IMPORT_OVERWRITE_DESC"]
		info.tooltipOnButton = true
		info.tooltipWhileDisabled = true
		info.notCheckable = true
		
		info.func = function()
			TMW:Import(editbox, settings, result.version, "textlayout", GUID)
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		-- create new
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["TEXTLAYOUTS_IMPORT"] .. " - " .. L["TEXTLAYOUTS_IMPORT_CREATENEW"]
		info.tooltipTitle = info.text
		info.tooltipText = L["TEXTLAYOUTS_IMPORT_CREATENEW_DESC"]
		info.tooltipOnButton = true
		info.notCheckable = true
		
		info.func = function()
			TMW:Import(editbox, settings, result.version, "textlayout", TMW.generateGUID(12))
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	else
		-- import normally - the layout doesnt already exist
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["TEXTLAYOUTS_IMPORT"]
		info.tooltipTitle = info.text
		info.tooltipText = L["TEXTLAYOUTS_IMPORT_NORMAL_DESC"]
		info.tooltipOnButton = true
		info.notCheckable = true
		
		info.func = function()
			TMW:Import(editbox, settings, result.version, "textlayout", GUID)
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	end
	
end

textlayout.Export_DataTypeDescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("5.1.0+")
function textlayout:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local GUID = EXPORTS[self.type]
	local settings = rawget(TMW.db.profile.TextLayouts, GUID)
	
	local text = L["fTEXTLAYOUT"]:format(TMW.TEXT:GetLayoutName(settings, GUID))
	info.text = text
	info.tooltipTitle = text
end
function textlayout:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local GUID = EXPORTS[self.type]
	assert(type(GUID) == "string")
	local settings = TMW.db.profile.TextLayouts[GUID]
	
	return editbox, self.type, settings, TMW.Defaults.profile.TextLayouts["**"], GUID
end



-- -----------------------
-- IMPORT SOURCES
-- -----------------------

local ImportSource = TMW:NewClass("ImportSource")
ImportSource.types = {}
function ImportSource:OnNewInstance(type)
	self.type = type
	ImportSource.types[type] = self
end


---------- Profile ----------
do
	local Profile = ImportSource:New("Profile")
	Profile.displayText = L["IMPORT_FROMLOCAL"]
	function Profile:HandleTopLevelMenu(editbox)
		database:Import_BuildMenuData({
			data = TMW.db,
			type = "database",
			--version = TellMeWhenDB.Version, (not really)
		}, editbox)
	end
end


---------- Backup ----------
local Backup = ImportSource:New("Backup")
Backup.displayText = L["IMPORT_FROMBACKUP"]
Backup.displayDescription = L["IMPORT_FROMBACKUP_DESC"]:format(TMW.BackupDate)
function Backup:HandleTopLevelMenu(editbox)
	database:Import_BuildMenuData({
		data = TMW.Backupdb,
		type = "database",
		--version = TellMeWhenDB.Version, (not really)
	}, editbox)
end
function Backup:TMW_CONFIG_IMPORTEXPORT_DROPDOWNDRAW(event, destination)
	if destination == self then
		info = UIDropDownMenu_CreateInfo()
		info.text = "|cffff0000" .. L["IMPORT_FROMBACKUP_WARNING"]:format(TMW.BackupDate)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		AddDropdownSpacer()
	end
end
TMW:RegisterCallback("TMW_CONFIG_IMPORTEXPORT_DROPDOWNDRAW", Backup)

---------- String ----------
local String = ImportSource:New("String")
String.displayText = function(editbox)
	return (editbox.DoPulseValidString and "|cff00ff00" or "") .. L["IMPORT_FROMSTRING"]
end
String.displayDisabled = function(editbox)
	local t = strtrim(editbox:GetText())
	return not (t ~= "" and TMW:DeserializeData(t))
end
String.displayDescription = L["IMPORT_FROMSTRING_DESC"]
function String:HandleTopLevelMenu(editbox)
	local t = strtrim(editbox:GetText())
	local editboxResult = t ~= "" and TMW:DeserializeData(t)
	
	local type = SharableDataType.types[editboxResult.type]
	type:Import_BuildMenuData(editboxResult, editbox)
end


---------- Comm ----------
local Comm = ImportSource:New("Comm")
local DeserializedData = {}
Comm.displayText = L["IMPORT_FROMCOMM"]
Comm.displayDisabled = function()
	Comm:DeserializeReceivedData()
	return not (DeserializedData and next(DeserializedData))
end
function Comm:DeserializeReceivedData()
	if TMW.Received then
		 -- deserialize received comm
		for k, who in pairs(TMW.Received) do
			-- deserialize received data now because we dont do it as they are received; AceSerializer is only embedded in _Options
			if type(k) == "string" and who then
				local result = TMW:DeserializeData(k)
				if result then
					tinsert(DeserializedData, result)
					result.who = who
					TMW.Received[k] = nil
				end
			end
		end
		if not next(TMW.Received) then
			TMW.Received = nil
		end
	end
end
function Comm:HandleTopLevelMenu(editbox)
	Comm:DeserializeReceivedData()
	
	for k, result in ipairs(DeserializedData) do
		local type = SharableDataType.types[result.type]
		type:Import_BuildContainingDropdownEntry(result, editbox)
	end
end



-- -----------------------
-- EXPORT DESTINATIONS
-- -----------------------

local ExportDestination = TMW:NewClass("ExportDestination")
ExportDestination.types = {}
function ExportDestination:OnNewInstance(type)
	self.type = type
	ExportDestination.types[type] = self
end
function ExportDestination:HandleTopLevelMenu(editbox)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	for k, dataType in pairs(SharableDataType.instances) do
		if EXPORTS[dataType.type] then
			local info = UIDropDownMenu_CreateInfo()
			info.tooltipText = self.Export_DataTypeDescriptionPrepend
			if dataType.Export_DataTypeDescriptionAppend then
				info.tooltipText = info.tooltipText .. "\r\n\r\n" .. dataType.Export_DataTypeDescriptionAppend
			end
			info.tooltipOnButton = true
			info.tooltipWhileDisabled = true
			info.notCheckable = true
			
			dataType:Export_SetButtonAttributes(editbox, info)
			info.func = function()
				self:Export(dataType:Export_GetArgs(editbox, info))--editbox, type, settings, defaults, ...
			end
			
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end


---------- String ----------
local String = ExportDestination:New("String")
String.Export_DataTypeDescriptionPrepend = L["EXPORT_TOSTRING_DESC"]
function String:Export(editbox, type, settings, defaults, ...)
	TMW:ExportToString(editbox, type, settings, defaults, ...)
end
function String:SetButtonAttributes(editbox, info)
	info.text = L["EXPORT_TOSTRING"]
	info.tooltipTitle = L["EXPORT_TOSTRING"]
	info.tooltipText = L["EXPORT_TOSTRING_DESC"]
	info.hasArrow = true
end


---------- Comm ----------
local Comm = ExportDestination:New("Comm")
Comm.Export_DataTypeDescriptionPrepend = L["EXPORT_TOCOMM_DESC"]
function Comm:Export(editbox, type, settings, defaults, ...)
	TMW:ExportToComm(editbox, type, settings, defaults, ...)
end
function Comm:SetButtonAttributes(editbox, info)
	local player = strtrim(editbox:GetText())
	local playerLength = strlenutf8(player)
	info.disabled = (strfind(player, "[`~^%d!@#%$%%&%*%(%)%+=_]") or playerLength <= 1 or playerLength > 35) and true
	local text
	if player == "RAID" or player == "GUILD" then
		text = L["EXPORT_TO" .. player]
	else
		text = L["EXPORT_TOCOMM"]
		if not info.disabled then
			text = text .. ": " .. player
		end
	end
	info.text = text
	info.tooltipTitle = text
	info.tooltipText = L["EXPORT_TOCOMM_DESC"]
	info.value = "EXPORT_TOCOMM"
	info.hasArrow = not info.disabled
end



-- -----------------------
-- DROPDOWN
-- -----------------------

function TMW.IE:Copy_DropDown(...)
	local DROPDOWN = self
	local EDITBOX = DROPDOWN:GetParent()
	
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		CurrentSourceOrDestinationHandler = nil
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		assert(type(UIDROPDOWNMENU_MENU_VALUE) == "table")
		CurrentSourceOrDestinationHandler = UIDROPDOWNMENU_MENU_VALUE
	end
	
	TMW:Fire("TMW_CONFIG_IMPORTEXPORT_DROPDOWNDRAW", CurrentSourceOrDestinationHandler)
	
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		UIDROPDOWNMENU_MENU_VALUE:HandleTopLevelMenu(EDITBOX)
	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then
		----------IMPORT----------
		
		--heading
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_HEADING"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		for k, importSource in pairs(ImportSource.instances) do
			--import from local
			local info = UIDropDownMenu_CreateInfo()
			info.text = get(importSource.displayText, EDITBOX)
			if importSource.displayDescription then
				info.tooltipTitle = importSource.displayText
				info.tooltipText = importSource.displayDescription
				info.tooltipOnButton = true
				info.tooltipWhileDisabled = true
			end
			info.value = importSource
			info.notCheckable = true
			info.disabled = get(importSource.displayDisabled, EDITBOX)
			info.hasArrow = not info.disabled
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end


		AddDropdownSpacer()
		----------EXPORT----------

		--heading
		info = UIDropDownMenu_CreateInfo()
		info.text = L["EXPORT_HEADING"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		for k, exportDestination in pairs(ExportDestination.instances) do
			local info = UIDropDownMenu_CreateInfo()
			info.tooltipOnButton = true
			info.tooltipWhileDisabled = true
			info.notCheckable = true
			
			exportDestination:SetButtonAttributes(EDITBOX, info)
			
			info.value = exportDestination
			
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	elseif type(UIDROPDOWNMENU_MENU_VALUE) == "table" then
		if UIDROPDOWNMENU_MENU_VALUE.isHolderMenu then
			SharableDataType.types[UIDROPDOWNMENU_MENU_VALUE.type]:Import_HolderMenuHandler(UIDROPDOWNMENU_MENU_VALUE.result, EDITBOX)
		else
			SharableDataType.types[UIDROPDOWNMENU_MENU_VALUE.type]:Import_BuildMenuData(UIDROPDOWNMENU_MENU_VALUE, EDITBOX)
		end
	end
end