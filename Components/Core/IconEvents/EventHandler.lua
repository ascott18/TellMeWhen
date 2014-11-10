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

TMW.EVENTS = {}
local EVENTS = TMW.EVENTS
LibStub("AceTimer-3.0"):Embed(EVENTS)


TMW.Icon_Defaults.Events = {
	n					= 0,
	["**"] 				= {
		OnlyShown 		= false,
		Operator 		= "<",
		Value 			= 0,
		CndtJustPassed 	= false,
		PassingCndt		= false,
		PassThrough		= true,
		Frequency		= 1,
		Event			= "", -- the event being handled (e.g "OnDurationChanged")
		Type			= "", -- the event handler handling the event (e.g. "Sound")
	},
}


TMW:RegisterUpgrade(70077, {
	-- OnIconShow and OnIconShow were removed in favor of using OnCondition
	iconEventHandler = function(self, eventSettings)
		local conditions = eventSettings.OnConditionConditions

		if eventSettings.Event == "OnIconShow" then
			eventSettings.Event = "OnCondition"
			-- Reset conditions just in case
			wipe(conditions)
			conditions.n = 1

			local condition = conditions[1]
			condition.Type = "ICON"
			condition.Icon = eventSettings.Icon or ""
			condition.Level = 0
		elseif eventSettings.Event == "OnIconHide" then
			eventSettings.Event = "OnCondition"
			-- Reset conditions just in case
			wipe(conditions)
			conditions.n = 1

			local condition = conditions[1]
			condition.Type = "ICON"
			condition.Icon = eventSettings.Icon or ""
			condition.Level = 1
		end
		eventSettings.Icon = nil
	end,
})
TMW:RegisterUpgrade(50020, {
	-- Upgrade from the old event system that only allowed one event of each type per icon.
	icon = function(self, ics)
		local Events = ics.Events
		for event, eventSettings in pairs(CopyTable(Events)) do -- dont use InNLengthTable here
			if type(event) == "string" and event ~= "n" then
				local addedAnEvent
				for identifier, EventHandler in pairs(TMW.Classes.EventHandler.instancesByName) do
					local hasHandlerOfType = EventHandler:ProcessIconEventSettings(event, eventSettings)
					if type(rawget(Events, "n") or 0) == "table" then
						Events.n = 0
					end
					if hasHandlerOfType then
						Events.n = (rawget(Events, "n") or 0) + 1
						Events[Events.n] = CopyTable(eventSettings)
						Events[Events.n].Type = identifier
						Events[Events.n].Event = event
						Events[Events.n].PassThrough = true

						addedAnEvent = true
					end
				end

				-- the last new event added for each original event should retain
				-- the original PassThrough setting instead of being forced to be true (Events[Events.n].PassThrough = true)
				-- in order to retain previous functionality
				if addedAnEvent then
					Events[Events.n].PassThrough = eventSettings.PassThrough
				end
				Events[event] = nil
			end
		end
	end,
})
TMW:RegisterUpgrade(48010, {
	icon = function(self, ics)
		-- OnlyShown was disabled for OnHide (not togglable anymore),
		-- so make sure that icons dont get stuck with it enabled
		local OnHide = rawget(ics.Events, "OnHide")
		if OnHide then
			OnHide.OnlyShown = false
		end
	end,
})
TMW:RegisterUpgrade(47321, {
	icon = function(self, ics)
		ics.Events["**"] = nil -- wtf?
	end,
})
TMW:RegisterUpgrade(47320, {
	iconEventHandler = function(self, eventSettings)
		-- these numbers got really screwy with FP errors (shit like 0.8000000119), put then back to what they should be (0.8)
		eventSettings.Duration 	= eventSettings.Duration  and tonumber(format("%0.1f",	eventSettings.Duration))
		eventSettings.Magnitude = eventSettings.Magnitude and tonumber(format("%1f",	eventSettings.Magnitude))
		eventSettings.Period  	= eventSettings.Period    and tonumber(format("%0.1f",	eventSettings.Period))
	end,
})
TMW:RegisterCallback("TMW_DB_PRE_DEFAULT_UPGRADES", function()
	-- The default value of eventSettings.PassThrough changed from false to true.
	if TellMeWhenDB.profiles and TellMeWhenDB.Version < 50035 then
		for _, p in pairs(TellMeWhenDB.profiles) do
			if p.Groups then
				for _, gs in pairs(p.Groups) do
					if gs.Icons then
						for _, ics in pairs(gs.Icons) do
							if ics.Events then
								for k, eventSettings in pairs(ics.Events) do
									if type(eventSettings) == "table" and eventSettings.PassThrough == nil then
										eventSettings.PassThrough = false
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)


TMW:RegisterCallback("TMW_UPGRADE_REQUESTED", function(event, type, version, ...)
	if type == "icon" then
		local ics, gs, iconID = ...
		
		-- Delegate the upgrade to eventSettings.
		for eventID, eventSettings in TMW:InNLengthTable(ics.Events) do
			TMW:DoUpgrade("iconEventHandler", version, eventSettings, eventID, ics)
		end
	end
end)


local EventHandler = TMW:NewClass("EventHandler")
EventHandler.testable = true
EventHandler.instancesByName = {}
EventHandler.orderedInstances = {}

--- Gets an EventHandler instance by name
-- You may also use {{{TMW.EVENTS:GetEventHandler(identifier)}}} to accomplish the same thing.
-- @param identifier [string] The identifier of the event handler being requested.
-- @return [EventHandler|nil] The requested EventHandler instance, or nil if it was not found.
function EventHandler:GetEventHandler(identifier)
	self:AssertSelfIsClass()
	
	return EventHandler.instancesByName[identifier]
end

--- Gets an EventHandler instance by name.
-- Wrapper around EventHandler:GetEventHandler(identifier)
-- @param identifier [string] The identifier of the event handler being requested.
-- @return [EventHandler|nil] The requested EventHandler instance, or nil if it was not found.
function EVENTS:GetEventHandler(identifier)
	return EventHandler:GetEventHandler(identifier)
end


do	-- EVENTS:InIconEventSettings
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
			local ics = state.extIter(state.extIterState)
			
			if not ics then
				tinsert(states, state)
				return
			end
			state.currentEvents = ics.Events
			state.currentEventID = 0
			
			return iter(state)
		end
		
		local eventSettings = rawget(state.currentEvents, state.currentEventID)
		
		if not eventSettings then
			return iter(state)
		end
		
		return eventSettings
	end

	--- Iterates over all event settings of icons in the current profile, and in global groups.
	-- Returns only eventSettings for each event setting.
	function EVENTS:InIconEventSettings()
		return iter, getstate()
	end
end



--- Creates a new EventHandler.
-- @name EventHandler:New
-- @param identifier [string] An identifier for the event handler.
function EventHandler:OnNewInstance_EventHandler(identifier, order)
	self.identifier = identifier
	self.order = order
	self.AllEventHandlerData = {}
	self.NonSpecificEventHandlerData = {}
	
	EventHandler.instancesByName[identifier] = self

	tinsert(EventHandler.orderedInstances, self)
	TMW:SortOrderedTables(EventHandler.orderedInstances)
end

-- [INTERNAL]
function EventHandler:RegisterEventHandlerDataTable(eventHandlerData)
	-- This function simply makes sure that we can keep track of all eventHandlerData that has been registed.
	-- Without it, we would have to search through every single IconComponent when an event is fired to get this data.
	
	-- Feel free to extend this method in instances of EventHandler to make it easier to perform these data lookups.
	-- But, this method should probably never be called by anything except the event core (no third-party calls)
	
	self:AssertSelfIsInstance()
	
	TMW:ValidateType("eventHandlerData.eventHandler", "EventHandler:RegisterEventHandlerDataTable(eventHandlerData)", eventHandlerData.eventHandler, "table")
	TMW:ValidateType("eventHandlerData.identifier", "EventHandler:RegisterEventHandlerDataTable(eventHandlerData)", eventHandlerData.identifier, "string")
	
	TMW.safecall(self.OnRegisterEventHandlerDataTable, self, eventHandlerData, unpack(eventHandlerData))

	for i = 1, #eventHandlerData do
		-- This stuff has been processed, so it is safe to get rid of it now.
		eventHandlerData[i] = nil
	end
	
	tinsert(self.AllEventHandlerData, eventHandlerData)
end

--- Registers event handler data that isn't tied to a specific IconComponent.
-- This method may be overwritten in instances of EventHandler with a method that throws an error if nonspecific event handler data (not tied to an IconComponent) isn't supported.
function EventHandler:RegisterEventHandlerDataNonSpecific(...)	
	self:AssertSelfIsInstance()
	
	local eventHandlerData = {
		eventHandler = self,
		identifier = self.identifier,
		...,
	}
	
	self:RegisterEventHandlerDataTable(eventHandlerData)
	
	tinsert(self.NonSpecificEventHandlerData, eventHandlerData)
end

--- Registers default settings for icon events
-- @param defaults [table] The defaults table that will be merged into {{{TMW.Icon_Defaults.Events["**"]}}}
-- @usage -- Example usage in the Announcements event handler:
--  Announcements:RegisterEventDefaults{
--    Text = "",
--    Channel = "",
--    Location = "",
--    Sticky = false,
--    ShowIconTex = true,
--    r = 1,
--    g = 1,
--    b = 1,
--    Size = 0,
--  }
function EventHandler:RegisterEventDefaults(defaults)
	assert(type(defaults) == "table", "arg1 to RegisterGroupDefaults must be a table")
		
	if TMW.InitializedDatabase then
		error(("Defaults for EventHandler %q are being registered too late. They need to be registered before the database is initialized."):format(self.name or "<??>"))
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, TMW.Icon_Defaults.Events["**"])
end


--- Tests the event. Triggered by clicking on the test button in the config UI.
function EventHandler:TestEvent(eventID)
	if not self.testable then
		return
	end
	
	local eventSettings = EVENTS:GetEventSettings(eventID)

	return self:HandleEvent(TMW.CI.icon, eventSettings)
end

	
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function(_, icon)
	-- Setup all of an icon's event handlers.

	wipe(icon.EventHandlersSet)

	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		local event = eventSettings.Event
		if event then
			local Handler = EventHandler:GetEventHandler(eventSettings.Type)
			
			-- Check if the event actually is configured to do something.
			local thisHasEventHandlers = Handler and Handler:ProcessIconEventSettings(event, eventSettings)

			if thisHasEventHandlers then
				-- The event is good. Fire an event to let people know that the icon has this event.
				TMW:Fire("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", icon, event, eventSettings)

				icon.EventHandlersSet[event] = true
				icon.EventsToFire = icon.EventsToFire or {}
			end
		end
	end
	
	-- make sure events dont fire while, or shortly after, we are setting up
	-- Don't set nil because that will make it fall back on the class-defined value
	icon.runEvents = false
	
	EVENTS:CancelTimer(icon.runEventsTimerHandler, 1)
	icon.runEventsTimerHandler = EVENTS.ScheduleTimer(icon, "RestoreEvents", TMW.UPD_INTV*2.1)
end)

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", function(event, time, Locked)
	-- Process all events that were queued in the current update cycle.
	-- This is done all at once because some events (OnCondition) might be triggered by changes in other icons,
	-- and we want everything to happen at the same time so that the firing order makes sense.

	local Icon = TMW.Classes.Icon
	local QueuedIcons = Icon.QueuedIcons
	
	if Locked and QueuedIcons[1] then
		sort(QueuedIcons, Icon.ScriptSort)
		for i = 1, #QueuedIcons do
			local icon = QueuedIcons[i]
			TMW.safecall(icon.ProcessQueuedEvents, icon)
		end
		wipe(QueuedIcons)
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", function(event, time, Locked)
	-- Wipe all queued events when we do a complete update of TMW
	-- in order to kill any events that got queued while setting up an icon (OnShow, etc).
	
	wipe(TMW.Classes.Icon.QueuedIcons)
end)


-- Base class for EventHandlers that have sub-handlers (e.g. animations and announcements).
TMW:NewClass("EventHandler_ColumnConfig", "EventHandler"){
	OnNewInstance_ColumnConfig = function(self)
		self.ConfigFrameData = {}
	end,
}






-------------------------------------------
-- While Condition Set Passing handling
-------------------------------------------
--[[
While Condition Set Passing (WCSP) is very tightly integrated with TMW.C.EventHandler
because it has very different behavior for different event handlers. Event handlers
need to be aware of what to do when the conditions start passing, and what to do
when they start failing. Animations triggered by WCSP must start/stop based on the
state of conditions, while other event handlers trigger repeatedly while
conditions are passing (EventHandler_WhileConditions_Repetitive)
]]

if TMW.C.IconType then
	error("Bad load order! TMW.C.IconType shouldn't exist at this point!")
end
TMW:RegisterCallback("TMW_CLASS_NEW", function(event, class)
	if class.className == "IconType" then
		class:RegisterIconEvent(1000, "WCSP", {
			text = L["SOUND_EVENT_WHILECONDITION"],
			desc = L["SOUND_EVENT_WHILECONDITION_DESC"],
			settings = {
				SimplyShown = true,
				IconEventWhileCondition = true,
			}
		})

		TMW:UnregisterThisCallback()
	end
end)


TMW:NewClass("EventHandler_WhileConditions", "EventHandler"){
	supportWCSP = true,

	OnNewInstance_WhileConditions = function(self)
		self.MapConditionObjectToEventSettings = {}
		self.UpdatesQueued = {}

		TMW:RegisterCallback("TMW_ICON_DISABLE", self)
		TMW:RegisterCallback("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", self)
		TMW:RegisterCallback("TMW_ICON_SETUP_POST", self)
	end,


	TMW_ICON_DISABLE = function(self, _, icon, soft)
		for ConditionObject, matches in pairs(self.MapConditionObjectToEventSettings) do
			for eventSettings, ic in pairs(matches) do
				if ic == icon then
					ConditionObject:RequestAutoUpdates(eventSettings, false)
					matches[eventSettings] = nil
				end
			end
		end
	end,

	TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE = function(self, _, icon, iconEvent, eventSettings)
		if eventSettings.Type ~= self.identifier or eventSettings.Event ~= "WCSP" then
			return
		end

		local ConditionObjectConstructor = icon:Conditions_GetConstructor(eventSettings.OnConditionConditions)

		-- If the OnlyShown setting is enabled, add a condition to check that the icon is shown.
		-- It is possible that the condition set is empty, in which case this will be the only condition.
		if eventSettings.OnlyShown then
			local condition = ConditionObjectConstructor:Modify_WrapExistingAndAppendNew()

			condition.Type = "ICON"
			condition.Icon = icon:GetGUID()
		end

		local ConditionObject = ConditionObjectConstructor:Construct()

		-- ConditionObject is nil if there were no conditions at all.
		if ConditionObject then
			-- We won't request updates manually - let the condition engine take care of updating.
			ConditionObject:RequestAutoUpdates(eventSettings, true)
			
			-- Associate the condition object with the event settings and the icon that the event settings are from.
			local matches = self.MapConditionObjectToEventSettings[ConditionObject]
			if not matches then
				matches = {}
				self.MapConditionObjectToEventSettings[ConditionObject] = matches
			end
			matches[eventSettings] = icon
			
			-- Listen for changes in condition state so that we can ask
			-- the event handler to do what it needs to do.
			TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", self)


			-- Check condition state right now so the animation is always up-to-date with the state.
			-- This might end up not doing anything since this code is called during TMW_ICON_SETUP_PRE
			self:CheckState(ConditionObject)

			-- Queue an update during TMW_ICON_SETUP_POST, 
			-- because animations might be missing required icon components when this is triggered.
			self.UpdatesQueued[ConditionObject] = true
		end
	end,

	TMW_ICON_SETUP_POST = function(self, _, icon)
		-- Run updates for anything that is queued. 
		-- There should only be one icon worth of ConditionObjects in here,
		-- since TMW_ICON_SETUP_PRE and TMW_ICON_SETUP_POST are always called in pairs.
		for ConditionObject in pairs(self.UpdatesQueued) do
			self:CheckState(ConditionObject)
		end
		wipe(self.UpdatesQueued)
	end,

	TMW_CNDT_OBJ_PASSING_CHANGED = function(self, _, ConditionObject, failed)
		self:CheckState(ConditionObject)
	end,

	CheckState = function(self, ConditionObject)
		local matches = self.MapConditionObjectToEventSettings[ConditionObject]

		if TMW.Locked and matches then
			-- If TMW is locked, and there are eventSettings that are using this ConditionObject,
			-- then have the event handler do what needs to be done for all of the matching eventSettings.
			self:HandleConditionStateChange(matches, ConditionObject.Failed)
		end
	end,
}


TMW:NewClass("EventHandler_WhileConditions_Repetitive", "EventHandler_WhileConditions"){
	frequencyMinimum = 0.2,

	OnNewInstance_WhileConditions_Repetitive = function(self)
		self.RunningTimers = {}

		TMW:RegisterCallback("TMW_ONUPDATE_POST", self)
		TMW:RegisterCallback("TMW_ICON_DISABLE", self, "TMW_ICON_DISABLE_2")
	end,

	TMW_ICON_DISABLE_2 = function(self, _, icon, soft)
		-- Halt all of the timers for an icon when it is disabled.
		for eventSettings, timerTable in pairs(self.RunningTimers) do
			if timerTable.icon == icon then
				timerTable.halted = true
			end
		end
	end,

	TMW_ONUPDATE_POST = function(self, event, time, Locked)
		-- Check all events to see if we should handle them again.
		if Locked then
			for eventSettings, timerTable in pairs(self.RunningTimers) do
				if not timerTable.halted and timerTable.nextRun < time then

					-- Increment the timer until it has passed the current time.
					if eventSettings.Frequency > 0 then
						-- Test if Frequency > 0 before starting loop because otherwise it will be infinite.
						while timerTable.nextRun < time do
							timerTable.nextRun = timerTable.nextRun + eventSettings.Frequency
						end
					end

					-- Actually handle the event.
					self:HandleEvent(timerTable.icon, eventSettings)
				end
			end
		end
	end,

	HandleConditionStateChange = function(self, eventSettingsList, failed)
		if not failed then
			-- Conditions are passing.
			-- Start/resume timers for all the eventSettings that are attached to the conditions.
			for eventSettings, icon in pairs(eventSettingsList) do
				local timerTable = self.RunningTimers[eventSettings]

				if not timerTable then
					-- Create a timer if there wasn't already one for the eventSettings.
					self.RunningTimers[eventSettings] = {icon = icon, nextRun = TMW.time}
				else
					-- Resume the timer if it was previously halted due to failing conditions.
					timerTable.halted = false

					-- Fast-foward the timer to right now, so that it triggers immediately.
					if timerTable.nextRun < TMW.time then
						timerTable.nextRun = TMW.time
					end
				end
			end
		else
			-- Conditions are failing.
			-- Halt all the timers for the eventSettings which rely on these conditions.
			for eventSettings, icon in pairs(eventSettingsList) do
				if self.RunningTimers[eventSettings] then
					self.RunningTimers[eventSettings].halted = true
				end
			end
		end
	end,
}


do
	local CNDT = TMW.CNDT
	
	
	local ConditionSet = {
		parentSettingType = "iconEventHandler",
		parentDefaults = TMW.Icon_Defaults.Events["**"],
		
		-- This uses the same settings as the On Condition Set Passing event to prevent clutter.
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
			local button = TellMeWhen_IconEditor.Events.EventSettingsContainer.IconEventWhileCondition
			
			return button and button:IsShown()
		end,
		tabText = L["EVENT_WHILECONDITIONS"],
		tabTooltip = L["EVENT_WHILECONDITIONS_TAB_DESC"],
		
	}
	CNDT:RegisterConditionSet("IconEventWhileCondition", ConditionSet)
	
end