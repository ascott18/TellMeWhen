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
		-- OnlyShown was disabled for OnHide (not togglable anymore), so make sure that icons dont get stuck with it enabled
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
		
		-- delegate to events
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


-- [INTERNAL]
function EventHandler:TestEvent(eventID)
	if not self.testable then
		return
	end
	
	local eventSettings = EVENTS:GetEventSettings(eventID)

	return self:HandleEvent(TMW.CI.icon, eventSettings)
end

	
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function(_, icon)
	wipe(icon.EventHandlersSet)
	
	-- make sure events dont fire while, or shortly after, we are setting up
	-- Don't set nil because that will make it fall back on the class-defined value
	icon.runEvents = false
	
	EVENTS:CancelTimer(icon.runEventsTimerHandler, 1)
	icon.runEventsTimerHandler = EVENTS.ScheduleTimer(icon, "RestoreEvents", TMW.UPD_INTV*2.1)
end)	

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(_, icon)
	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		local event = eventSettings.Event
		if event then
			local Handler = EventHandler:GetEventHandler(eventSettings.Type)
			
			local thisHasEventHandlers = Handler and Handler:ProcessIconEventSettings(event, eventSettings)

			if thisHasEventHandlers then
				TMW:Fire("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", icon, event, eventSettings)
				
				if event ~= "WCSP" then
					icon.EventHandlersSet[event] = true
					icon.EventsToFire = icon.EventsToFire or {}
				end
			end
		end
	end
end)

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", function(event, time, Locked)
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
	wipe(TMW.Classes.Icon.QueuedIcons)
end)


TMW:NewClass("EventHandler_ColumnConfig", "EventHandler"){
	OnNewInstance_ColumnConfig = function(self)
		self.ConfigFrameData = {}
	end,
}




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

		TMW:RegisterCallback("TMW_ICON_DISABLE", self)
		TMW:RegisterCallback("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", self)
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

		if eventSettings.OnlyShown then
			local condition = ConditionObjectConstructor:Modify_WrapExistingAndAppendNew()

			condition.Type = "ICON"
			condition.Icon = icon:GetGUID()
		end

		local ConditionObject = ConditionObjectConstructor:Construct()

		if ConditionObject then
			ConditionObject:RequestAutoUpdates(eventSettings, true)
			
			local matches = self.MapConditionObjectToEventSettings[ConditionObject]
			if not matches then
				matches = {}
				self.MapConditionObjectToEventSettings[ConditionObject] = matches
			end
			matches[eventSettings] = icon
			
			TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", self)

			-- Do this right now so the animation is always up-to-date with the state
			self:TMW_CNDT_OBJ_PASSING_CHANGED(nil, ConditionObject, ConditionObject.Failed)
		end
	end,

	TMW_CNDT_OBJ_PASSING_CHANGED = function(self, _, ConditionObject, failed)
		local matches = self.MapConditionObjectToEventSettings[ConditionObject]

		if TMW.Locked and matches then
			self:HandleConditionStateChange(matches, failed)
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
		for eventSettings, timerTable in pairs(self.RunningTimers) do
			if timerTable.icon == icon then
				timerTable.halted = true
			end
		end
	end,

	TMW_ONUPDATE_POST = function(self, event, time, Locked)
		if Locked then
			for eventSettings, timerTable in pairs(self.RunningTimers) do
				if not timerTable.halted and timerTable.nextRun < time then
					if eventSettings.Frequency > 0 then
						-- Test if Frequency > 0 before starting loop because otherwise it will be infinite.
						while timerTable.nextRun < time do
							timerTable.nextRun = timerTable.nextRun + eventSettings.Frequency
						end
					end

					self:HandleEvent(timerTable.icon, eventSettings)
				end
			end
		end
	end,

	HandleConditionStateChange = function(self, eventSettingsList, failed)
		if not failed then
			for eventSettings, icon in pairs(eventSettingsList) do
				local timerTable = self.RunningTimers[eventSettings]
				if not timerTable then
					self.RunningTimers[eventSettings] = {icon = icon, nextRun = TMW.time}
				else
					local Frequency = eventSettings.Frequency

					timerTable.halted = false
					if timerTable.nextRun < TMW.time then
						timerTable.nextRun = TMW.time
					end
				end
			end
		else
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