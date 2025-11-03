-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local UpdateManager = TMW.Classes.UpdateTableManager:New()
UpdateManager:UpdateTable_Set()
local ByConditionObject = UpdateManager:UpdateTable_CreateIndexedView("ByConditionObject", function(target) return target.ConditionObject end)
local ByIcon = UpdateManager:UpdateTable_CreateIndexedView("ByIcon", function(target) return target.icon end)

local Module = TMW:NewClass("IconModule_IconEventConditionHandler", "IconModule")
Module:SetAllowanceForType("", false)
Module.dontInherit = true

Module:RegisterIconEvent(3, "OnCondition", {
	category = L["EVENT_CATEGORY_CONDITION"],
	text = L["SOUND_EVENT_ONCONDITION"],
	desc = L["SOUND_EVENT_ONCONDITION_DESC"],
	settings = {
		IconEventOnCondition = true,
	},
})

Module:PostHookMethod("OnImplementIntoIcon", function(self, icon)
	local EventHandlersSet = icon.EventHandlersSet
	
	if EventHandlersSet.OnCondition then
		self:Enable()
	else
		self:Disable()
	end
end)

local function TMW_ICON_DATA_CHANGED_SHOWN(event, icon, shown)
	local targets = ByIcon[icon]
	if targets then
		for _, target in ipairs(targets) do
			target.ConditionObject:RequestAutoUpdates(target.eventSettingsProxy, shown)
		end
	end
end

local function TMW_CNDT_OBJ_PASSING_CHANGED(event, ConditionObject, failed)
	if not failed then
		local targets = ByConditionObject[ConditionObject]
		if targets then
			for _, target in ipairs(targets) do
				local icon = target.icon
				-- Only trigger events while the icon is shown
				if icon.attributes.shown then
					icon:QueueEvent(target.eventSettingsProxy.__proxyRef)
					icon:ProcessQueuedEvents()
				end
			end
		end
	end
end

function Module:OnEnable()
	local icon = self.icon
	
	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		if eventSettings.Event == "OnCondition" then
			local ConditionObjectConstructor = icon:Conditions_GetConstructor(eventSettings.OnConditionConditions)
			local ConditionObject = ConditionObjectConstructor:Construct()
		
			if ConditionObject then
				local eventSettingsProxy = TMW.C.EventHandler:Proxy(eventSettings, icon)
				
				-- Create a target object and register it with the shared UpdateManager
				local target = {
					icon = icon,
					eventSettingsProxy = eventSettingsProxy,
					ConditionObject = ConditionObject
				}
				
				UpdateManager:UpdateTable_Register(target)
				
				-- Trigger the shown event handler to start watching for updates (if needed)
				TMW_ICON_DATA_CHANGED_SHOWN(nil, icon, icon.attributes.shown)
				
				TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", TMW_CNDT_OBJ_PASSING_CHANGED)
				TMW:RegisterCallback("TMW_ICON_DATA_CHANGED_SHOWN", TMW_ICON_DATA_CHANGED_SHOWN)
			end
		end
	end
end

function Module:OnDisable()
	-- Use the shared indexed view to find all targets for this icon
	local targets = ByIcon[self.icon]
	
	if targets then
		-- Copy the targets array since we'll be modifying the indexed view during unregistration
		for _, target in ipairs(TMW.shallowCopy(targets)) do
			target.ConditionObject:RequestAutoUpdates(target.eventSettingsProxy, false)
			UpdateManager:UpdateTable_Unregister(target)
		end
	end
end


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", TMW_CNDT_OBJ_PASSING_CHANGED)
	TMW:UnregisterCallback("TMW_ICON_DATA_CHANGED_SHOWN", TMW_ICON_DATA_CHANGED_SHOWN)
end)


local ConditionSet = {
	parentSettingType = "iconEventHandler",
	parentDefaults = TMW.Icon_Defaults.Events["**"],
	
	settingKey = "OnConditionConditions",
	GetSettings = function(self)
		local currentEventID = TMW.EVENTS.currentEventID
		if currentEventID then
			return TMW.CI.ics.Events[currentEventID].OnConditionConditions
		end
	end,
	
	iterFunc = TMW.EVENTS.InIconEventSettings,
	iterArgs = {TMW.EVENTS},

	useDynamicTab = true,
	ShouldShowTab = function(self)
		local button = TellMeWhen_IconEditor.Pages.Events.EventSettingsContainer.IconEventOnCondition
		
		return button and button:IsShown()
	end,
	tabText = L["EVENTCONDITIONS"],
	tabTooltip = L["EVENTCONDITIONS_TAB_DESC"],
	
}
TMW.CNDT:RegisterConditionSet("IconEventOnCondition", ConditionSet)
