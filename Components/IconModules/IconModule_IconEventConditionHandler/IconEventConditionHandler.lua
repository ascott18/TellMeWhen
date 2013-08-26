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
	

local MapConditionObjectToEventSettings = {}

local Module = TMW:NewClass("IconModule_IconEventConditionHandler", "IconModule")
Module.dontInherit = true

Module:RegisterIconEvent(101, "OnCondition", {
	text = L["SOUND_EVENT_ONCONDITION"],
	desc = L["SOUND_EVENT_ONCONDITION_DESC"],
	settings = {
		IconEventOnCondition = true,
	},
})

Module:ExtendMethod("OnImplementIntoIcon", function(self, icon)
	local EventHandlersSet = icon.EventHandlersSet
	
	if EventHandlersSet.OnCondition then
		self:Enable()
	else
		self:Disable()
	end
end)

local function TMW_CNDT_OBJ_PASSING_CHANGED(event, ConditionObject, failed)
	if not failed then
		local matches = MapConditionObjectToEventSettings[ConditionObject]
		if matches then
			for eventSettings, icon in pairs(matches) do
				icon:QueueEvent(eventSettings)
				icon:ProcessQueuedEvents()
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
				ConditionObject:RequestAutoUpdates(eventSettings, true)
				
				local matches = MapConditionObjectToEventSettings[ConditionObject]
				if not matches then
					matches = {}
					MapConditionObjectToEventSettings[ConditionObject] = matches
				end
				matches[eventSettings] = icon
				
				TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", TMW_CNDT_OBJ_PASSING_CHANGED)
			end
		end
	end
end

function Module:OnDisable()
	for ConditionObject, matches in pairs(MapConditionObjectToEventSettings) do
		for eventSettings, icon in pairs(matches) do
			if icon == self.icon then
				ConditionObject:RequestAutoUpdates(eventSettings, false)
				matches[eventSettings] = nil
			end
		end
	end
end

do
	local CNDT = TMW.CNDT
	
	local InIconEventSettings
	do -- InIconEventSettings
		local states = {}
		local function getstate()
			local state = wipe(tremove(states) or {})

			state.currentEventID = 0
			
			state.extIter, state.extIterState = TMW:InIconSettings()

			return state
		end

		local function iter(state)
			state.currentEventID = state.currentEventID + 1

			if not state.currentEvents or state.currentEventID > (state.currentEvents.n or #state.currentEvents) then
				local settings, gs, groupID, iconID = state.extIter(state.extIterState)
				
				if not settings then
					tinsert(states, state)
					return
				end
				state.currentEvents = settings.Events
				state.currentEventID = 0
				
				return iter(state)
			end
			
			local eventSettings = rawget(state.currentEvents, state.currentEventID)
			
			if not eventSettings then
				return iter(state)
			end
			
			return eventSettings
		end

		InIconEventSettings = function()
			return iter, getstate()
		end
	end
	
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
		
		iterFunc = InIconEventSettings,
		iterArgs = {},

		useDynamicTab = true,
		ShouldShowTab = function(self)
			local button = TellMeWhen_IconEditorEventsEventSettingsContainerIconEventOnCondition
			
			return button and button:IsShown()
		end,
		tabText = L["EVENTCONDITIONS"],
		tabTooltip = L["EVENTCONDITIONS_TAB_DESC"],
		
	}
	CNDT:RegisterConditionSet("IconEventOnCondition", ConditionSet)
	

	TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
		
		--[[for ConditionObject, matches in pairs(MapConditionObjectToEventSettings) do
			for eventSettings, icon in pairs(matches) do
				ConditionObject:RequestAutoUpdates(eventSettings, false)
				matches[eventSettings] = nil
			end
			assert(not next(matches))
		end]]
		
		TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", TMW_CNDT_OBJ_PASSING_CHANGED)
	end)
end



