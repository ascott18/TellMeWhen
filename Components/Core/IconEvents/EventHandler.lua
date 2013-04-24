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
		Icon			= "",
	},
}


TMW:RegisterUpgrade(50020, {
	-- Upgrade from the old event system that only allowed one event of each type per icon.
	icon = function(self, ics)
		local Events = ics.Events
		for event, eventSettings in pairs(CopyTable(Events)) do -- dont use InNLengthTable here
			if type(event) == "string" and event ~= "n" then
				local addedAnEvent
				for eventHandlerName, EventHandler in pairs(TMW.Classes.EventHandler.instancesByName) do
					local hasHandlerOfType = EventHandler:ProcessIconEventSettings(event, eventSettings)
					if type(rawget(Events, "n") or 0) == "table" then
						Events.n = 0
					end
					if hasHandlerOfType then
						Events.n = (rawget(Events, "n") or 0) + 1
						Events[Events.n] = CopyTable(eventSettings)
						Events[Events.n].Type = eventHandlerName
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
		local ics, groupID, iconID = ...
		
		-- delegate to events
		for eventID, eventSettings in TMW:InNLengthTable(ics.Events) do
			TMW:DoUpgrade("iconEventHandler", version, eventSettings, eventID, groupID, iconID)
		end
	end
end)


local EventHandler = TMW:NewClass("EventHandler")
EventHandler.instancesByName = {}

--- Gets an EventHandler instance by name
-- You may also use {{{TMW.EVENTS:GetEventHandler(eventHandlerName)}}} to accomplish the same thing.
-- @param eventHandlerName [string] The identifier of the event handler being requested.
-- @return [EventHandler|nil] The requested EventHandler instance, or nil if it was not found.
function EventHandler:GetEventHandler(eventHandlerName)
	self:AssertSelfIsClass()
	
	return EventHandler.instancesByName[eventHandlerName]
end


function EVENTS:GetEventHandler(eventHandlerName)
	return EventHandler:GetEventHandler(eventHandlerName)
end



--- Creates a new EventHandler.
-- @name EventHandler:New
-- @param eventHandlerName [string] An identifier for the event handler.
function EventHandler:OnNewInstance_EventHandler(eventHandlerName)
	self.eventHandlerName = eventHandlerName
	self.AllEventHandlerData = {}
	self.NonSpecificEventHandlerData = {}
	
	EventHandler.instancesByName[eventHandlerName] = self
end

-- [INTERNAL]
function EventHandler:RegisterEventHandlerDataTable(eventHandlerData)
	-- This function simply makes sure that we can keep track of all eventHandlerData that has been registed.
	-- Without it, we would have to search through every single IconComponent when an event is fired to get this data.
	
	-- Feel free to extend this method in instances of EventHandler to make it easier to perform these data lookups.
	-- But, this method should probably never be called by anything except the event core (no third-party calls)
	
	self:AssertSelfIsInstance()
	
	TMW:ValidateType("eventHandlerData.eventHandler", "EventHandler:RegisterEventHandlerDataTable(eventHandlerData)", eventHandlerData.eventHandler, "table")
	TMW:ValidateType("eventHandlerData.eventHandlerName", "EventHandler:RegisterEventHandlerDataTable(eventHandlerData)", eventHandlerData.eventHandlerName, "string")
	
	TMW.safecall(self.OnRegisterEventHandlerDataTable, self, eventHandlerData, unpack(eventHandlerData))
	
	tinsert(self.AllEventHandlerData, eventHandlerData)
end

--- Registers event handler data that isn't tied to a specific IconComponent.
-- This method may be overwritten in instances of EventHandler with a method that throws an error if nonspecific event handler data (not tied to an IconComponent) isn't supported.
function EventHandler:RegisterEventHandlerDataNonSpecific(...)	
	self:AssertSelfIsInstance()
	
	local eventHandlerData = {
		eventHandler = self,
		eventHandlerName = self.eventHandlerName,
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

	
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function(_, icon)
	wipe(icon.EventHandlersSet)

	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		local event = eventSettings.Event
		if event then
			local Handler = EventHandler:GetEventHandler(eventSettings.Type)
			
			local thisHasEventHandlers = Handler and Handler:ProcessIconEventSettings(event, eventSettings)

			if thisHasEventHandlers then
				TMW:Fire("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", icon, event, eventSettings)
				
				icon.EventHandlersSet[event] = true
				icon.EventsToFire = icon.EventsToFire or {}
			end
		end
	end
	
	-- make sure events dont fire while, or shortly after, we are setting up
	icon.runEvents = nil
	
	EVENTS:CancelTimer(icon.runEventsTimerHandler, 1)
	icon.runEventsTimerHandler = EVENTS.ScheduleTimer(icon, "RestoreEvents", TMW.UPD_INTV*2.1)
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

