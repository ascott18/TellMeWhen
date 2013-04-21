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

local sort, type, pairs
	= sort, type, pairs
local UnitAffectingCombat, GetActiveSpecGroup, GetSpecialization
	= UnitAffectingCombat, GetActiveSpecGroup, GetSpecialization


--- {{{TMW.Classes.Group}}} is the class of all Icons.
-- 
-- Group inherits explicitly from {{{Blizzard.Frame}}} and from {{{TMW.Classes.GenericModuleImplementor}}}, and implicitly from the classes that it inherits. 
-- 
-- Group is the class of all TMW groups, which serve as a container for TMW icons. The job of a group is to size & position icons and to provide functionality that can affect multiple icons at once, such as only showing in certain specs. They provide all the methods needed for setup and updating themselves and the icons within them. Icons themselves do not create or provide any child frames or layers - this is functionality that is given to Group Modules & individual icons.
-- 
-- @class file
-- @name Group.lua


-- -----------
-- GROUPS
-- -----------

local Group = TMW:NewClass("Group", "Frame", "UpdateTableManager", "GenericModuleImplementor")
Group:UpdateTable_Set(TMW.GroupsToUpdate)


do	-- TMW.CNDT implementation
	local tab
	
	TMW.CNDT:RegisterConditionSetImplementingClass("Group")
	TMW.CNDT:RegisterConditionSet("Group", {
		parentSettingType = "group",
		parentDefaults = TMW.Group_Defaults,
		
		settingKey = "Conditions",
		GetSettings = function(self)
			if TMW.CI.g then
				return TMW.db.profile.Groups[TMW.CI.g].Conditions
			end
		end,
		
		iterFunc = TMW.InGroupSettings,
		iterArgs = {
			[1] = TMW,
		},
		
		GetTab = function(self)
			return tab
		end,
		tabText = L["GROUPCONDITIONS"],
		tabTooltip = L["GROUPCONDITIONS_DESC"],
	})
	
	TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
		tab = TMW.Classes.IconEditorTab:NewTab(15, "Conditions")
		tab:SetTitleComponents(nil, 1)
		
		tab:ExtendMethod("ClickHandler", function()
			TMW.CNDT:LoadConfig("Group")
		end)
	end)
end

-- [INTERNAL]
function Group.OnNewInstance(group, ...)
	local _, name, _, _, groupID = ... -- the CreateFrame args
	TMW[groupID] = group

	group.ID = groupID
end

-- [INTERNAL]
function Group.__tostring(group)
	return group:GetName()
end

-- [INTERNAL]
function Group.ScriptSort(groupA, groupB)
	local gOrder = -TMW.db.profile.CheckOrder
	return groupA.ID*gOrder < groupB.ID*gOrder
end
Group:UpdateTable_SetAutoSort(Group.ScriptSort)
TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", "UpdateTable_PerformAutoSort", Group)



-- [INTERNAL]
Group.SetScript_Blizz = Group.SetScript
function Group.SetScript(group, handler, func)
	group[handler] = func
	group:SetScript_Blizz(handler, func)
end

-- [INTERNAL]
Group.Show_Blizz = Group.Show
function Group.Show(group)
	if not group.__shown then
		TMW:Fire("TMW_GROUP_SHOW_PRE", group)
		group:Show_Blizz()
		group.__shown = 1
		TMW:Fire("TMW_GROUP_SHOW_POST", group)
	end
end

-- [INTERNAL]
Group.Hide_Blizz = Group.Hide
function Group.Hide(group)
	if group.__shown then
		TMW:Fire("TMW_GROUP_HIDE_PRE", group)
		group:Hide_Blizz()
		group.__shown = nil
		TMW:Fire("TMW_GROUP_HIDE_POST", group)
	end
end

-- [INTERNAL]
function Group.Update(group)
	local ConditionObject = group.ConditionObject
	
	local allConditionsPassed = true
	if ConditionObject and ConditionObject.Failed then
		allConditionsPassed = false
	elseif TMW.Locked and group.OnlyInCombat and not UnitAffectingCombat("player") then
		allConditionsPassed = false
	elseif not group:ShouldUpdateIcons() then
		allConditionsPassed = false
	end
	
	if allConditionsPassed then
		group:Show()
	else
		group:Hide()
	end
end

-- [INTERNAL]
function Group.OnEvent(group, event)
	group:Update()
end

-- [INTERNAL]
function Group.TMW_CNDT_OBJ_PASSING_CHANGED(group, event, ConditionObject, failed)
	if group.ConditionObject == ConditionObject then
		group:Update()
	end
end


--- Returns the settings table that holds the settings for the group.
-- @name Group:GetSettings
-- @paramsig
-- @return [{{{TMW.Group_Defaults}}}] The settings table that holds the settings for the group.
-- @usage local gs = group:GetSettings()
-- print(group:GetName() .. "'s enabled setting is set to " .. gs.Enabled)
function Group.GetSettings(group)
	return TMW.db.profile.Groups[group:GetID()]
end

--- Returns the settings table that holds the view-specific settings for the group.
-- @name Group:GetSettingsPerView
-- @paramsig view
-- @param [string|nil] The identifier of the {{{TMW.Classes.IconView}}} to get settings for, or nil to use the group's current view.
-- @return [{{{TMW.Group_Defaults.SettingsPerView[view]}}}] The settings table that holds the view-specific settings for the group.
-- @usage local icspv = group:GetSettingsPerView()
-- 
-- local icspv = group:GetSettingsPerView("bar")
function Group.GetSettingsPerView(group, view)
	local gs = group:GetSettings()
	view = view or gs.View
	return gs.SettingsPerView[view]
end

--- Gets whether or not the group's icons should be updated based on the group's settings
-- @name Group:GetSettingsPerView
-- @paramsig
-- @return [boolean] True if the group should show and update its icons; otherwise false.
function Group.ShouldUpdateIcons(group)
	local gs = group:GetSettings()

	if	(group:GetID() > TMW.db.profile.NumGroups) or
		(not group.viewData) or
		(not gs.Enabled) or
		(GetActiveSpecGroup() == 1 and not gs.PrimarySpec) or
		(GetActiveSpecGroup() == 2 and not gs.SecondarySpec) or
		(GetSpecialization() and not gs["Tree" .. GetSpecialization()])
	then
		return false
	end

	return true
end

--- Checks if the group is valid to be checked in meta icons & conditions.
-- Currently just a wrapper around Group:ShouldUpdateIcons()
-- @paramsig
-- @return [boolean] True if the group should show and update its icons; otherwise false.
function Group.IsValid(group)
	-- checks if the group can be checked in metas/conditions

	return group:ShouldUpdateIcons()
end



-- [INTERNAL]
function Group.Setup_Conditions(group)
	-- Clear out/reset any previous conditions and condition-related stuff on the group
	group.ConditionObject = nil
	TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", group)
	
	-- Determine if we should process conditions
	if group:ShouldUpdateIcons() and TMW.Locked and group.Conditions_GetConstructor then
		-- Get a constructor to make the ConditionObject
		local ConditionObjectConstructor = group:Conditions_GetConstructor(group.Conditions)
		
		-- Construct the ConditionObject
		group.ConditionObject = ConditionObjectConstructor:Construct()
		
		if group.ConditionObject then
			-- Setup the event handler and the update table if a ConditionObject was returned
			-- (meaning that there are conditions that need to be checked)
			group:UpdateTable_Register()
	
			TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", group)
		else
			group:UpdateTable_Unregister()
		end
	else
		group:UpdateTable_Unregister()
	end
end


--- Completely sets up a group.
-- 
-- Implements all requested {{{TMW.Classes.GroupComponent}}}s, processes settings, sets up conditions, and then sets up all the icons that it contains.
-- 
-- This method should not be called manually while TellMeWhen is locked. It may be called liberally from wherever you see fit when in configuration mode.
-- @name Icon:Setup
-- @paramsig noIconSetup
-- @param noIconSetup [boolean] True to prevent the group from setting up all of its icons. Nil/false to update all icons along with the group.
function Group.Setup(group, noIconSetup)
	local gs = group:GetSettings()
	local groupID = group:GetID()
	
	for k, v in pairs(TMW.Group_Defaults) do
		group[k] = TMW.db.profile.Groups[groupID][k]
	end
	
	group.__shown = group:IsShown()
	
	group.numIcons = group.Rows * group.Columns
	
	local viewData_old = group.viewData
	local viewData = TMW.Views[gs.View]
	group.viewData = viewData

	TMW:Fire("TMW_GROUP_SETUP_PRE", group)
	
	group:DisableAllModules()
	
	-- Setup the groups's view:
	
	-- UnSetup the old view
	if viewData_old then
		if viewData_old ~= viewData and viewData_old.Group_UnSetup then
			viewData_old:Group_UnSetup(group)
		end
		
		viewData_old:UnimplementFromGroup(group)
	end
	
	-- Setup the current view
	viewData:ImplementIntoGroup(group)
	if viewData then
		viewData:Group_Setup(group)
	end
		
	if group:ShouldUpdateIcons() then
		if not noIconSetup then
			-- Setup icons
			for iconID = 1, group.numIcons do
				local icon = group[iconID]
				if not icon then
					icon = TMW.Classes.Icon:New("Button", group:GetName() .. "_Icon" .. iconID, group, "TellMeWhen_IconTemplate", iconID)
				end

				TMW.safecall(icon.Setup, icon)
			end

			for iconID = group.numIcons+1, #group do
				local icon = group[iconID]
				icon:DisableIcon()
			end
		end
	else
		for iconID = 1, #group do
			local icon = group[iconID]
			icon:DisableIcon()
		end
	end

	group:Setup_Conditions()
	
	if group.OnlyInCombat then
		group:RegisterEvent("PLAYER_REGEN_ENABLED")
		group:RegisterEvent("PLAYER_REGEN_DISABLED")
		group:SetScript("OnEvent", group.OnEvent)
	else
		group:SetScript("OnEvent", nil)
	end

	group:Update()
	
	TMW:Fire("TMW_GROUP_SETUP_POST", group)
end

 
