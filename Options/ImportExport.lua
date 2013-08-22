local TMW = TMW
if not TMW then return end

-- GLOBALS: TELLMEWHEN_VERSIONNUMBER
-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE
-- GLOBALS: UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, CloseDropDownMenus

local print = TMW.print
local L = TMW.L
local get = TMW.get

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

function SharableDataType:OnNewInstance(type, order)
	TMW:ValidateType("2 (type)", "SharableDataType:New(type, order)", type, "string")
	TMW:ValidateType("3 (order)", "SharableDataType:New(type, order)", order, "number")
	
	self.type = type
	self.order = order
	SharableDataType.types[type] = self
	self.MenuBuilders = {}
end
function SharableDataType:RegisterMenuBuilder(order, func)
	tinsert(self.MenuBuilders, {
		order = order,
		func = func,
	})
	
	TMW:SortOrderedTables(self.MenuBuilders)
end
function SharableDataType:RunMenuBuilders(result, editbox)
	for i, data in ipairs(self.MenuBuilders) do
		TMW.safecall(data.func, self, result, editbox)
	end
end

function SharableDataType:Import_ImportData(_, data, version, GUID)
	assert(type(GUID) == "string")

	if not TMW.DatabaseTypes[self.type] then
		error("You must override Import_ImportData for types that don't match with a database type.")
	end

	TMW:CheckInData(GUID)
	TMW.db.global.Trunk[self.type][GUID] = TMW:CopyWithoutMetatable(data)

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade(self.type, version, textlayout, GUID)
		end
	end
	TMW:Update()
end





---------- Database ----------
local database = SharableDataType:New("database", 0)
function database:Import_BuildContainingDropdownEntry(result)
	-- this is currently unused. Do something with it if it ever does get used
	--(but it is unlikely that i will ever use it)
	error("UNIMPLEMENTED!")
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["<DATABASE>"]
	info.value = result
	info.hasArrow = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end
database.Import_BuildMenuData = database.RunMenuBuilders


function database:Export_SetButtonAttributes(editbox, info)
	-- CURRENTLY UNUSED
end
function database:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	-- CURRENTLY UNUSED
end






---------- Profile ----------
local profile = SharableDataType:New("profile", 10)

function profile:Import_ImportData(editbox, data, version, noOverwrite)
	if noOverwrite then -- noOverwrite is a name in this case.

		-- generate a new name if the profile already exists
		local newname = noOverwrite
		while TMW.db.profiles[newname] do
			newname = TMW.oneUpString(newname)
		end

		-- put the data in the profile (no reason to CTIPWM when we can just do this) and set the profile
		TMW.db.profiles[newname] = CopyTable(data)
		TMW.db:SetProfile(newname)
	else
		TMW.db:ResetProfile()
		TMW:CopyTableInPlaceWithMeta(data, TMW.db.profile, true)
	end

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:UpgradeProfile()
		end
	end
end
function profile:Import_BuildContainingDropdownEntry(result)
	local info = UIDropDownMenu_CreateInfo()
	info.text = result[1]
	info.value = result
	info.hasArrow = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

profile.Import_BuildMenuData = profile.RunMenuBuilders

database:RegisterMenuBuilder(10, function(self, result, editbox)
	
	local db = result.data
	-- current profile
	local currentProfile = TMW.db:GetCurrentProfile()
	
	assert(currentProfile)
	
	-- This might not evaluate to true if the import type is the backup database and this profile didn't exist when backup was created
	if db.profiles[currentProfile] then
		SharableDataType.types.profile:Import_BuildContainingDropdownEntry({
			parentResult = result,
			data = db.profiles[currentProfile],
			type = "profile",
			version = db.profiles[currentProfile].Version,
			[1] = currentProfile,
		}, editbox)

		TMW.AddDropdownSpacer()
	end
end)
database:RegisterMenuBuilder(20, function(self, result, editbox)
	local db = result.data
	local currentProfile = TMW.db:GetCurrentProfile()
	
	--other profiles
	for profilename, profiletable in TMW:OrderedPairs(db.profiles) do
		-- current profile and default are handled separately
		if profilename ~= currentProfile and profilename ~= "Default" then
			SharableDataType.types.profile:Import_BuildContainingDropdownEntry({
				parentResult = result,
				data = profiletable,
				type = "profile",
				version = profiletable.Version,
				[1] = profilename,
			}, editbox)
		end
	end
end)
database:RegisterMenuBuilder(30, function(self, result, editbox)
	local db = result.data
	local currentProfile = TMW.db:GetCurrentProfile()
	
	--default profile
	if db.profiles["Default"] and currentProfile ~= "Default" then
		SharableDataType.types.profile:Import_BuildContainingDropdownEntry({
			parentResult = result,
			data = db.profiles.Default,
			type = "profile",
			version = db.profiles.Default.Version,
			[1] = "Default",
		}, editbox)
	end
end)

profile:RegisterMenuBuilder(1, function(self, result, editbox)
	-- header
	local info = UIDropDownMenu_CreateInfo()
	info.text = result[1]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end)

profile:RegisterMenuBuilder(10, function(self, result, editbox)
	-- copy entire profile - overwrite current
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_OVERWRITE"]:format(TMW.db:GetCurrentProfile())
	info.func = function()
		TMW:Import(editbox, result.data, result.version, "profile")
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire profile - create new profile
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_NEW"]
	info.func = function()
		TMW:Import(editbox, result.data, result.version, "profile", result[1]) -- newname forces a new profile to be created named newname
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	TMW.AddDropdownSpacer()
end)

profile.Export_DescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("6.0.3+")
function profile:Export_SetButtonAttributes(editbox, info)
	local text = L["fPROFILE"]:format(TMW.db:GetCurrentProfile())
	info.text = text
	info.tooltipTitle = text
end
function profile:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	return editbox, self.type, TMW.db.profile, TMW.Defaults.profile, TMW.db:GetCurrentProfile()
end







---------- Group ----------
local group = SharableDataType:New("group", 20)
local NUM_GROUPS_PER_SUBMENU = 10


function group:Import_ImportData(editbox, data, version, createNewGroup, oldgroupID, destgroup)
	if createNewGroup then
		destgroup = TMW:Group_Add()
	end

	local GUID = destgroup:GetGUID()
	TMW:DeleteData(GUID)

	
	if version < 70001 and type(oldgroupID) == "number" then
		GUID = TMW:RunUpgradeFromOld(oldgroupID, data, "group", TellMeWhenDB.global.Trunk)
	elseif version > 70000 and type(oldgroupID) == "string" then
		GUID = oldgroupID
	end

	TMW.db.profile.Groups[destgroup.ID] = GUID
	local gs = TMW:GetData(GUID)

	if type(oldgroupID) ~= "number" then
		TMW:DeleteData(GUID)
		TMW:CopyTableInPlaceWithMeta(data, gs, true)
	end

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("group", version, gs, GUID)
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
group.Import_BuildMenuData = group.RunMenuBuilders

profile:RegisterMenuBuilder(40, function(self, result, editbox)
	-- group header
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_GROUPS"]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	local hasMadeOneHolderMenu
	
	local startID, lastID = 1
	
	local numGroups = tonumber(result.data.NumGroups) or 10
	
	if numGroups > NUM_GROUPS_PER_SUBMENU then
		for groupID = 1, numGroups do
			if not startID then
				startID = groupID
			end
				
			-- Check to see if we have enough icons to build a holder menu.
			if groupID % NUM_GROUPS_PER_SUBMENU == 0 then
				
				group:MakeHolderMenu(result, startID, groupID)
				
				-- nil out startID so that it will be set again for the next valid group found,
				-- which will be the start of the next holder menu.
				startID = nil
			end
			
			-- lastID will hold the last groupID that is valid in the group once the loop ends.
			-- It's recorded so that we don't need to loop back over the icons again to figure this out.
			lastID = groupID
		end
		
		-- Create a holder menu for any remaining icons that didn't get one inside the loop, if needed.
		if startID then			
			group:MakeHolderMenu(result, startID, lastID)
		end
	else
		-- If there would only be one submenu, don't create submenus, and instead just put all groups directly in.
		for groupID, gs in TMW:OrderedPairs(result.data.Groups) do
			if type(groupID) == "number" and groupID >= 1 and groupID <= (tonumber(result.data.NumGroups) or 10) then
				SharableDataType.types.group:Import_BuildContainingDropdownEntry({
					parentResult = result,
					data = gs,
					type = "group",
					version = result.version,
					[1] = groupID,
				}, editbox)
				
			end
		end
	end
end)

function group:MakeHolderMenu(result, startID, endID)	
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_GROUPS"] .. ": " .. startID .. " - " .. endID
	info.notCheckable = true
	info.hasArrow = true
	
	-- This table will be stored in UIDROPDOWNMENU_MENU_VALUE when this holder menu is expanded.
	-- It is also passed as arg4 to Import_HolderMenuHandler(self, result, editbox, holderMenuData)
	info.value = {
		isHolderMenu = true,
		result = result,
		type = "group",
		startID = startID,
		endID = endID,
	}
	
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)	
end

function group:Import_HolderMenuHandler(result, editbox, holderMenuData)
	-- Header
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_GROUPS"] .. ": " .. holderMenuData.startID .. " - " .. holderMenuData.endID
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	TMW.AddDropdownSpacer()
	
	-- Add icons to the holder menu.
	for groupID, gs in TMW:OrderedPairs(result.data.Groups) do
	
		-- Check to see if this group is within the range specified by the holder menu that is being built.
		if type(groupID) == "number" and groupID >= 1 and groupID <= (tonumber(result.data.NumGroups) or 10) 
			and groupID >= holderMenuData.startID and groupID <= holderMenuData.endID then
		
			SharableDataType.types.group:Import_BuildContainingDropdownEntry({
				parentResult = result,
				data = gs,
				type = "group",
				version = result.version,
				[1] = groupID,
			}, editbox)
		end
	end
end

group:RegisterMenuBuilder(1, function(self, result, editbox)
	local groupID = result[1]
	local gs = result.data
	
	-- header
	local info = UIDropDownMenu_CreateInfo()
	local profilename = TMW.approachTable(result, "parentResult", 1)
	--info.text = (profilename and profilename .. ": " or "") .. TMW:GetGroupName(gs.Name, groupID)
	info.text = TMW:GetGroupName(gs.Name, groupID)
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end)

group:RegisterMenuBuilder(20, function(self, result, editbox)
	local groupID = result[1]
	local gs = result.data
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()

	-- copy entire group - overwrite current
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["OVERWRITEGROUP"]:format(IMPORTS.group_overwrite and IMPORTS.group_overwrite:GetGroupName(1) or "?")
	info.func = function()
		TMW:Import(editbox, gs, result.version, "group", false, groupID, IMPORTS.group_overwrite)
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
end)

group.Export_DescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("4.6.0+")
function group:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local group = EXPORTS[self.type]
	
	local text = L["fGROUP"]:format(group:GetGroupName(1))
	info.text = text
	info.tooltipTitle = text
end
function group:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local group = EXPORTS[self.type]
	
	return editbox, self.type, group:GetSettings(), TMW.Group_Defaults, group:GetGUID()
end





---------- Icon ----------
local icon = SharableDataType:New("icon", 30)
local NUM_ICONS_PER_SUBMENU = 10

function icon:Import_ImportData(editbox, data, version, GUID)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	if not GUID then
		GUID = TMW:GenerateGUID(self.type, TMW.CONST.GUID_SIZE)
	end

	local icon = IMPORTS.icon
	local group = icon.group

	TMW:DeleteData(icon:GetGUID())
	TMW:StoreData(GUID, data)
	group.Icons[icon.ID] = GUID

	local ics = icon:GetSettings()

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("icon", version, icon:GetSettings(), GUID)
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
		else
			tex = TMW:GuessIconTexture(ics)
		end

		local text, textshort, tooltipText = TMW:GetIconMenuText(groupID, iconID, ics)
		if text:sub(-2) == "))" and iconID then
			textshort = textshort .. " " .. L["fICON"]:format(iconID)
		end
		info.text = textshort
		info.tooltipTitle = (groupID and format(L["GROUPICON"], TMW:GetGroupName(gs and gs.Name, groupID, 1), iconID)) or (iconID and L["fICON"]:format(iconID)) or L["ICON"]
		info.tooltipOnButton = true
			
		info.disabled = not IMPORTS.icon
		if info.disabled then
			info.tooltipText = L["IMPORT_ICON_DISABLED_DESC"]
			info.tooltipWhileDisabled = true
		else
			info.tooltipText = tooltipText
		end

		info.notCheckable = true

		info.icon = tex
		info.tCoordLeft = 0.07
		info.tCoordRight = 0.93
		info.tCoordTop = 0.07
		info.tCoordBottom = 0.93

		info.func = function()
			if ic and ic:IsVisible() then
				TMW.HELP:Show("ICON_IMPORT_CURRENTPROFILE", nil, editbox, 0, 0, L["HELP_IMPORT_CURRENTPROFILE"])
				IMPORTS.icon:SetInfo("texture", tex)
			else
				IMPORTS.icon:SetInfo("texture", nil)
			end
			
			if gs then
				TMW:PrepareIconSettingsForCopying(ics, gs)
			end
			
			TMW:Import(editbox, ics, version, "icon")
		end
		info.arg1 = ics
		info.arg2 = version

		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end
icon.Import_BuildMenuData = icon.Import_BuildContainingDropdownEntry

function icon:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	local text = L["fICON"]:format(EXPORTS.icon.ID)
	info.text = text
	info.tooltipTitle = text
end
function icon:Export_GetArgs(editbox, info)
	--editbox, type, settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	local icon = EXPORTS.icon
	local gs = icon.group:GetSettings()
	local ics = icon:GetSettings()
	TMW:PrepareIconSettingsForCopying(ics, gs)
	
	return editbox, self.type, ics, TMW.Icon_Defaults, icon:GetGUID()
end

function icon:MakeHolderMenu(result, startID, endID)
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_ICONS"] .. ": " .. startID .. " - " .. endID
	info.notCheckable = true
	info.hasArrow = true
	
	-- This table will be stored in UIDROPDOWNMENU_MENU_VALUE when this holder menu is expanded.
	-- It is also passed as arg4 to Import_HolderMenuHandler(self, result, editbox, holderMenuData)
	info.value = {
		isHolderMenu = true,
		result = result,
		type = "icon",
		startID = startID,
		endID = endID,
	}
	
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)	
end

group:RegisterMenuBuilder(30, function(self, result, editbox)
	local gs = result.data
	
	if not gs.Icons then
		return
	end
	
	local hasMadeOneHolderMenu
	
	local startID, lastID
	local count = 0
	
	local shouldBuildHolders = false
	local precount = 0
	for iconID, ics in TMW:OrderedPairs(gs.Icons) do
	
		-- Ignore icons that are just blank/default icons.
		if not TMW.IE:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
			precount = precount + 1
		end
		if precount > NUM_ICONS_PER_SUBMENU then
			shouldBuildHolders = true
			break
		end
	end
	
	if shouldBuildHolders then
		for iconID, ics in TMW:OrderedPairs(gs.Icons) do
		
			-- Ignore icons that are just blank/default icons.
			if not TMW.IE:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
			
				-- If we haven't found an icon to start the current holder menu with, use this one.
				if not startID then
					startID = iconID
				end
				
				count = count + 1
				
				-- Check to see if we have enough icons to build a holder menu.
				if count % NUM_ICONS_PER_SUBMENU == 0 then
				
					-- Add a spacer and header if we haven't added one yet.
					if not hasMadeOneHolderMenu then
						TMW.AddDropdownSpacer()
						
						local info = UIDropDownMenu_CreateInfo()
						info.text = L["UIPANEL_ICONS"]
						info.isTitle = true
						info.notCheckable = true
						UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
						
						hasMadeOneHolderMenu = true
					end
					
					icon:MakeHolderMenu(result, startID, iconID)
					
					-- nil out startID so that it will be set again for the next valid icon found,
					-- which will be the start of the next holder menu.
					startID = nil
				end
				
				-- lastID will hold the last iconID that is valid in the group once the loop ends.
				-- It's recorded so that we don't need to loop back over the icons again to figure this out.
				lastID = iconID
			end
		end
		
		-- Create a holder menu for any remaining icons that didn't get one inside the loop, if needed.
		if startID then
			-- Add a spacer and header if we haven't added one yet.
			if not hasMadeOneHolderMenu then
				TMW.AddDropdownSpacer()
				
				local info = UIDropDownMenu_CreateInfo()
				info.text = L["UIPANEL_ICONS"]
				info.isTitle = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
						
				--hasMadeOneHolderMenu = true -- doesn't matter at this point
			end
			
			icon:MakeHolderMenu(result, startID, lastID)
		end	
	elseif precount > 0 then
		TMW.AddDropdownSpacer()
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["UIPANEL_ICONS"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		for iconID, ics in TMW:OrderedPairs(gs.Icons) do
		
			-- The icon was in range, so create a result object for the icon and build a dropdown entry for it.
			SharableDataType.types.icon:Import_BuildContainingDropdownEntry({
				data = ics,
				version = result.version,
				type = "icon",
				[1] = iconID,
			}, editbox)
		end
	end	
end)

function icon:Import_HolderMenuHandler(result, editbox, holderMenuData)	
	local groupID = result[1]
	local gs = result.data

	-- Header
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_ICONS"] .. ": " .. holderMenuData.startID .. " - " .. holderMenuData.endID
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	TMW.AddDropdownSpacer()
	
	-- Add icons to the holder menu.
	for iconID, ics in TMW:OrderedPairs(gs.Icons) do
	
		-- Check to see if this icon is within the range specified by the holder menu that is being built.
		if iconID >= holderMenuData.startID and iconID <= holderMenuData.endID then
		
			-- The icon was in range, so create a result object for the icon and build a dropdown entry for it.
			SharableDataType.types.icon:Import_BuildContainingDropdownEntry({
				data = ics,
				version = result.version,
				type = "icon",
				[1] = iconID,
			}, editbox)
		end
	end
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
local Profile = ImportSource:New("Profile")
Profile.displayText = L["IMPORT_FROMLOCAL"]
function Profile:HandleTopLevelMenu(editbox)
	database:Import_BuildMenuData({
		data = TMW.db,
		type = "database",
		--version = TellMeWhenDB.Version, (not really)
	}, editbox)
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
		local info = UIDropDownMenu_CreateInfo()
		info.text = "|cffff0000" .. L["IMPORT_FROMBACKUP_WARNING"]:format(TMW.BackupDate)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		TMW.AddDropdownSpacer()
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
local function DestinationsOrderedSort(a, b)
	return SharableDataType.instances[a].order < SharableDataType.instances[b].order
end

local ExportDestination = TMW:NewClass("ExportDestination")
ExportDestination.types = {}
function ExportDestination:OnNewInstance(type)
	self.type = type
	ExportDestination.types[type] = self
end
function ExportDestination:HandleTopLevelMenu(editbox)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	for k, dataType in TMW:OrderedPairs(SharableDataType.instances, DestinationsOrderedSort) do
		if EXPORTS[dataType.type] then
			local info = UIDropDownMenu_CreateInfo()
			info.tooltipText = self.Export_DescriptionPrepend
			if dataType.Export_DescriptionAppend then
				info.tooltipText = info.tooltipText .. "\r\n\r\n" .. dataType.Export_DescriptionAppend
			end
			info.tooltipOnButton = true
			info.tooltipWhileDisabled = true
			info.notCheckable = true
			
			dataType:Export_SetButtonAttributes(editbox, info)
			
			-- Color everything before the first colon a light blue (highlights the type of data being exported, for clarity)
			info.text = info.text:gsub("^(.-):", "|cff00ffff%1|r:")
			
			info.func = function()
				self:Export(dataType:Export_GetArgs(editbox, info))--editbox, type, settings, defaults, ...
			end
			
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end


---------- String ----------
local String = ExportDestination:New("String")
String.Export_DescriptionPrepend = L["EXPORT_TOSTRING_DESC"]
function String:Export(editbox, type, settings, defaults, ...)
	local s = TMW:GetSettingsString(type, settings, defaults, ...)
	s = TMW:MakeSerializedDataPretty(s)
	TMW.LastExportedString = s
	editbox:SetText(s)
	editbox:HighlightText()
	editbox:SetFocus()
	CloseDropDownMenus()
	TMW.HELP:Show("ICON_EXPORT_DOCOPY", nil, editbox, 0, 0, L["HELP_EXPORT_DOCOPY_" .. (IsMacClient() and "MAC" or "WIN")])
end
function String:SetButtonAttributes(editbox, info)
	info.text = L["EXPORT_TOSTRING"]
	info.tooltipTitle = L["EXPORT_TOSTRING"]
	info.tooltipText = L["EXPORT_TOSTRING_DESC"]
	info.hasArrow = true
end


---------- Comm ----------
local Comm = ExportDestination:New("Comm")
Comm.Export_DescriptionPrepend = L["EXPORT_TOCOMM_DESC"]
function Comm:Export(editbox, type, settings, defaults, ...)
	local player = strtrim(editbox:GetText())
	if player and #player > 1 then -- and #player < 13 you can send to cross server people in a battleground ("Cybeloras-Mal'Ganis"), so it can be more than 13
		local s = TMW:GetSettingsString(type, settings, defaults, ...)

		if player == "RAID" or player == "GUILD" then -- note the upper case
			TMW:SendCommMessage("TMW", s, player, nil, "BULK", editbox.callback, editbox)
		else
			TMW:SendCommMessage("TMW", s, "WHISPER", player, "BULK", editbox.callback, editbox)
		end
	end
	
	CloseDropDownMenus()
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


		TMW.AddDropdownSpacer()
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
			SharableDataType.types[UIDROPDOWNMENU_MENU_VALUE.type]:Import_HolderMenuHandler(UIDROPDOWNMENU_MENU_VALUE.result, EDITBOX, UIDROPDOWNMENU_MENU_VALUE)
		else
			SharableDataType.types[UIDROPDOWNMENU_MENU_VALUE.type]:Import_BuildMenuData(UIDROPDOWNMENU_MENU_VALUE, EDITBOX)
		end
	end
end







