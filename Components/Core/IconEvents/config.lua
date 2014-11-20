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

local get = TMW.get

local EVENTS = TMW.EVENTS
local IE = TMW.IE


EVENTS.CONST = {
	EVENT_INVALID_REASON_MISSINGHANDLER = 1,
	EVENT_INVALID_REASON_MISSINGCOMPONENT = 2,
	EVENT_INVALID_REASON_MISSINGEVENT = 3,
	EVENT_INVALID_REASON_NOEVENT = 4,
}

local EventsTab = TMW.Classes.IconEditorTab:NewTab("ICONEVENTS", 10, "Events")
EventsTab:SetText(TMW.L["EVENTS_TAB"])
TMW:TT(EventsTab, "EVENTS_TAB", "EVENTS_TAB_DESC")



---------- Icon Dragger ----------
TMW.IconDragger:RegisterIconDragHandler(120, -- Copy Event Handlers
	function(IconDragger, info)
		local n = IconDragger.srcicon:GetSettings().Events.n

		if IconDragger.desticon and n > 0 then
			info.text = L["ICONMENU_COPYEVENTHANDLERS"]:format(n)
			info.tooltipTitle = info.text
			info.tooltipText = L["ICONMENU_COPYEVENTHANDLERS_DESC"]:format(
				IconDragger.srcicon:GetIconName(true), n, IconDragger.desticon:GetIconName(true))
			
			return true
		end
	end,
	function(IconDragger)
		-- copy the settings
		local srcics = IconDragger.srcicon:GetSettings()
		
		IconDragger.desticon:GetSettings().Events = TMW:CopyWithMetatable(srcics.Events)
	end
)

TMW:NewClass("Config_Base_Event"){
	OnNewInstance_Base_Event = function(self, data)
		TMW:RegisterCallback("TMW_CONFIG_EVENTS_SETTINGS_SETUP_PRE", self, "ReloadSetting")
	end,

	GetSettingTable = function(self)
		return TMW.CI.ics and EVENTS:GetEventSettings()
	end,
}

TMW:NewClass("Config_CheckButton_Event", "Config_Base_Event", "Config_CheckButton"){

	METHOD_EXTENSIONS = {
		OnClick = function(self, button)
			EVENTS:LoadEventSettings()
		end,
	},

	CheckInteractionStates = TMW.NULLFUNC,
}

TMW:NewClass("Config_Slider_Event", "Config_Base_Event", "Config_Slider"){
	OnNewInstance_Slider_Event = function(self)
		local color = 34/0xFF
		self.Low:SetTextColor(color, color, color, 1)
		self.High:SetTextColor(color, color, color, 1)
	end,

	CheckInteractionStates = TMW.NULLFUNC,
}

TMW:NewClass("Config_EditBox_Event", "Config_Base_Event", "Config_EditBox"){
	METHOD_EXTENSIONS = {
		SaveSetting = function(self, button)
			EVENTS:LoadConfig()
		end,
	},
}


function EVENTS:LoadConfig()
	local EventHandlerFrames = EVENTS.EventHandlerFrames
	local previousFrame

	local yAdjustTitle, yAdjustText = 0, 0
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		yAdjustTitle, yAdjustText = 3, -3
	end

	
	local oldID = max(1, EVENTS.currentEventID or 1)

	local didLoad
	for i = 1, TMW.CI.ics.Events.n do
		-- This wizard magic allows us to iterate over all eventIDs, 
		-- starting with the currently selected one (oldID)
		-- So, for example, if oldID == 3 and TMW.CI.ics.Events.n == 6,
		-- eventID will be iterated as 3, 4, 5, 6, 1, 2
		local eventID = ((i-2+oldID) % TMW.CI.ics.Events.n) + 1
		i = nil -- i should not be used after this point since it won't correspond to any meaningful data.


		-- Get the frame that this event will be listed in.
		local frame = EVENTS.EventHandlerFrames[eventID]
		if not frame then
			-- If the frame doesn't exist, then create it.
			frame = CreateFrame("Button", EventHandlerFrames:GetName().."Event"..eventID, EventHandlerFrames, "TellMeWhen_Event", eventID)
			EventHandlerFrames[eventID] = frame

			frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -0.5)
			frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, -0.5)

			local p, t, r, x, y = frame.EventName:GetPoint(1)
			frame.EventName:SetPoint(p, t, r, x, y + yAdjustTitle)
			local p, t, r, x, y = frame.EventName:GetPoint(2)
			frame.EventName:SetPoint(p, t, r, x, y + yAdjustTitle)

			local p, t, r, x, y = frame.DataText:GetPoint(1)
			frame.DataText:SetPoint(p, t, r, x, y + yAdjustText)
			local p, t, r, x, y = frame.DataText:GetPoint(2)
			frame.DataText:SetPoint(p, t, r, x, y + yAdjustText)

			frame.DataText:SetWordWrap(false)
		end
		previousFrame = frame
		frame:Show()


		-- Check if this eventID is valid, and load it if it is.
		local isValid, reason = EVENTS:IsEventIDValid(eventID)
		local eventSettings = EVENTS:GetEventSettings(eventID)
		local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventSettings)
		local eventData = TMW.EventList[eventSettings.Event]

		
		-- If we have the event's data, set the event name of the frame to the localized name of the event.
		-- If we don't have the event's data, set the event name of the raw identifier of the event.
		if eventData then
			frame.EventName:SetText(eventID .. ") " .. eventData.text)
		else
			frame.EventName:SetText(eventID .. ") " .. eventSettings.Event)
		end

		if isValid then
			-- The event is valid and all needed components were found,
			-- so set up the button.

			frame:Enable()


			frame.event = eventData.event
			frame.eventData = eventData

			local desc = eventData.desc .. "\r\n\r\n" .. L["EVENTS_HANDLERS_GLOBAL_DESC"]
			TMW:TT(frame, eventData.text, desc, 1, 1)


			-- This delegates the setup of frame.DataText to the event handler
			-- so that it can put useful information about the user's settings
			-- (e.g. "Sound: TMW - Pling3" or "Animation: Icon: Shake")
			local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventID)
			EventHandler:SetupEventDisplay(eventID)

			if EventHandler.testable then
				frame.Play:Enable()
			else
				frame.Play:Disable()
			end

			-- If we have not yet loaded an event for this configuration load,
			-- then load this event. The proper event settings and event handler
			-- configuration will be shown and setup with stored settings.
			-- This is the reason why we start with the currently selected eventID.
			if not didLoad then
				EVENTS:LoadEventID(eventID)
				didLoad = true
			end

		else
			frame:Disable()
			TMW:TT(frame, nil, nil)

			if reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGHANDLER then
				-- The handler (E.g. Sound, Animation, etc.) of the event settings was not found.
				frame.DataText:SetText("|cFFFF5050UNKNOWN HANDLER:|r " .. tostring(EVENTS:GetEventSettings(eventID).Type))

			elseif reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGEVENT then
				-- The event (E.g. "OnSomethingHappened") was not found
				frame.DataText:SetText("|cFFFF5050UNKNOWN EVENT|r")

			elseif reason == EVENTS.CONST.EVENT_INVALID_REASON_NOEVENT then
				-- The handler is unconfigured
				-- This is a non-critical error, so we format the error message nicely for the user.
				frame.DataText:SetText(L["SOUND_EVENT_NOEVENT"])
				frame:Enable()

			elseif reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGCOMPONENT then
				-- The event was found, but it is not available for the current icon's configuration.
				-- This is a non-critical error, so we format the error message nicely for the user.
				frame.DataText:SetText(L["SOUND_EVENT_DISABLEDFORTYPE"])
				TMW:TT(frame, eventData.text, L["SOUND_EVENT_DISABLEDFORTYPE_DESC2"]:format(TMW.Types[TMW.CI.ics.Type].name), 1, 1)
			end
		end
	end

	-- Hide unused frames
	for i = max(TMW.CI.ics.Events.n + 1, 1), #EventHandlerFrames do
		EventHandlerFrames[i]:Hide()
	end

	-- Position the first frame
	if EventHandlerFrames[1] then
		EventHandlerFrames[1]:SetPoint("TOPLEFT", EventHandlerFrames, "TOPLEFT", 0, 0)
		EventHandlerFrames[1]:SetPoint("TOPRIGHT", EventHandlerFrames, "TOPRIGHT", 0, 0)
	end

	-- Set the height of the first 
	local frame1Height = EventHandlerFrames[1] and EventHandlerFrames[1]:GetHeight() or 0
	EventHandlerFrames:SetHeight(max(TMW.CI.ics.Events.n*frame1Height, 1))

	-- If an event handler's configuration was not loaded for an event,
	-- hide all handler configuration panels
	if not didLoad then
		EVENTS:ShowHandlerPickerButtons()
		--IE.Events.HelpText:Show()
	end

	EVENTS:SetTabText()
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", EVENTS, "LoadConfig")

function EVENTS:LoadEventID(eventID)
	-- Loads the configuration for the specified eventID
	local eventFrame = eventID and EVENTS.EventHandlerFrames[eventID]
	
	EVENTS.currentEventID = eventID ~= 0 and eventID or nil

	for i, frame in ipairs(EVENTS.EventHandlerFrames) do
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetAlpha(0.1)
	end


	for _, EventHandler in pairs(TMW.Classes.EventHandler.instancesByName) do
		EventHandler.ConfigContainer:Hide()
	end
	EVENTS.EventSettingsContainer:Hide()
	--IE.Events.HelpText:Show()


	if not eventFrame or eventID == 0 or not eventFrame:IsShown() then
		return
	end

	EVENTS:HidePickerButtons()
	
	local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventID)
	if EventHandler then
		EVENTS.EventSettingsContainer:Show()
		EventHandler.ConfigContainer:Show()
		
		EVENTS.currentEventHandler = EventHandler
		
		EventHandler:LoadSettingsForEventID(eventID)
		EVENTS:LoadEventSettings()
	end


	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetAlpha(0.2)
end

function EVENTS:LoadEventSettings()
	local EventSettingsContainer = EVENTS.EventSettingsContainer

	if not EVENTS.currentEventID then
		EventSettingsContainer:Hide()
		return
	end

	local eventSettings = EVENTS:GetEventSettings()
	local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventSettings)

	EventSettingsContainer:Show()

	--hide settings
	EventSettingsContainer.PassThrough				:Hide()
	EventSettingsContainer.SimplyShown				:Hide()
	EventSettingsContainer.OnlyShown				:Hide()
	EventSettingsContainer.Operator					:Hide()
	EventSettingsContainer.Value					:Hide()
	EventSettingsContainer.CndtJustPassed			:Hide()
	EventSettingsContainer.PassingCndt				:Hide()
	EventSettingsContainer.Frequency				:Hide()
	EventSettingsContainer.IconEventWhileCondition	:Hide()

	TMW:Fire("TMW_CONFIG_EVENTS_SETTINGS_SETUP_PRE")


	local eventData = EVENTS:GetEventData()

	if eventData then
		IE.Events.EventSettingsContainerEventName:SetText("(" .. EVENTS.currentEventID .. ") " .. eventData.text)

		if eventSettings.Event == "WCSP" then
			if EventHandler.frequencyMinimum then
				EventSettingsContainer.Frequency:Show()

				EventSettingsContainer.Frequency:SetMinMaxValues(EventHandler.frequencyMinimum, math.huge)
				EventSettingsContainer.Frequency:ReloadSetting()
			end
		else
			EventSettingsContainer.PassThrough:Show()
			EventSettingsContainer.OnlyShown:Show()
		end

		--load settings
		EventSettingsContainer.Value:SetText(eventSettings.Value)
		

		local settingsUsedByEvent = eventData.settings

		--show settings as needed
		for setting, frame in pairs(EventSettingsContainer) do
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

		if EventSettingsContainer.PassingCndt				:GetChecked() then
			EventSettingsContainer.Operator.ValueLabel		:SetFontObject(GameFontHighlight)
			EventSettingsContainer.Operator					:Enable()
			EventSettingsContainer.Value					:Enable()
			if settingsUsedByEvent and not settingsUsedByEvent.CndtJustPassed == "FORCE" then
				EventSettingsContainer.CndtJustPassed		:Enable()
			end
		else
			EventSettingsContainer.Operator.ValueLabel		:SetFontObject(GameFontDisable)
			EventSettingsContainer.Operator					:Disable()
			EventSettingsContainer.Value					:Disable()
			EventSettingsContainer.CndtJustPassed			:Disable()
		end

		EventSettingsContainer.Operator.ValueLabel:SetText(eventData.valueName)
		EventSettingsContainer.Value.ValueLabel:SetText(eventData.valueSuffix)

		local v = EventSettingsContainer.Operator:SetUIDropdownText(eventSettings.Operator, TMW.operators)
		if v then
			TMW:TT(EventSettingsContainer.Operator, v.tooltipText, nil, 1)
		end
	end

	
	TMW:Fire("TMW_CONFIG_EVENTS_SETTINGS_SETUP_POST")
end



function EVENTS:LoadHandlerPickerButtons()
	local previousFrame

	-- Handler pickers
	local HandlerPickers = IE.Events.HandlerPickers
	for i, EventHandler in ipairs(TMW.Classes.EventHandler.orderedInstances) do

		local frame = HandlerPickers[i]
		if not frame then
			-- If the frame doesn't exist, then create it.
			frame = CreateFrame("Button", HandlerPickers:GetName().."Picker"..i, HandlerPickers, "TellMeWhen_HandlerPicker", i)
			HandlerPickers[i] = frame

			if i == 1 then
				frame:SetPoint("TOP")
			else
				frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -10)
			end
		end

		frame.handlerIdentifier = EventHandler.identifier
		frame.Title:SetText(EventHandler.handlerName)
		frame.Desc:SetText(EventHandler.handlerDesc or "<No Description>")

		TMW:TT(frame, EventHandler.handlerName, "EVENTS_HANDLER_ADD_DESC", 1, nil)

		previousFrame = frame
	end
end

function EVENTS:LoadEventPickerButtons()
	local previousFrame

	-- Event (Trigger) pickers
	local EventPickers = IE.Events.EventPickers
	for i, frame in ipairs(EventPickers) do
		frame:Hide()
	end

	local EventHandler = EVENTS:GetEventHandler(EVENTS.pickedHandler)
	for i, eventData in ipairs(EVENTS:GetValidEvents(EventHandler)) do

		local frame = EventPickers[i]
		if not frame then
			-- If the frame doesn't exist, then create it.
			frame = CreateFrame("Button", EventPickers:GetName().."Picker"..i, EventPickers, "TellMeWhen_EventPicker", i)
			EventPickers[i] = frame
		end

		if i == 1 then
			frame:SetPoint("TOP")
		else
			frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -1)
		end

		frame:Show()
		frame.event = eventData.event
		frame.Title:SetText(get(eventData.text))
		TMW:TT(frame, eventData.text, eventData.desc, 1, 1)

		previousFrame = frame
	end
end

function EVENTS:ShowHandlerPickerButtons()
	EVENTS.pickedHandler = nil

	EVENTS:LoadHandlerPickerButtons()
	EVENTS:LoadEventID(nil)

	IE.Events.AddEvent:LockHighlight()
	IE.Events.AddEvent:GetHighlightTexture():SetAlpha(0.2)

	IE.Events.HandlerPickers:Show()
	IE.Events.EventPickers:Hide()
end

function EVENTS:ShowEventPickerButtons()
	EVENTS:LoadEventPickerButtons()

	IE.Events.HandlerPickers:Hide()
	IE.Events.EventPickers:Show()
end 

function EVENTS:HidePickerButtons()
	IE.Events.AddEvent:UnlockHighlight()
	IE.Events.AddEvent:GetHighlightTexture():SetAlpha(0.1)

	IE.Events.HandlerPickers:Hide()
	IE.Events.EventPickers:Hide()
end

function EVENTS:PickEvent(event)
	local handlerIdentifier = EVENTS.pickedHandler

	TMW.CI.ics.Events.n = TMW.CI.ics.Events.n + 1

	local eventID = TMW.CI.ics.Events.n
	local eventSettings = EVENTS:GetEventSettings(eventID)

	eventSettings.Event = event
	eventSettings.Type = handlerIdentifier

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(eventSettings)
	end

	EVENTS:LoadConfig()

	EVENTS:LoadEventID(eventID)

	TMW.DD:CloseDropDownMenus()
end




function EVENTS:AdjustScrollFrame()
	local ScrollFrame = EVENTS.EventHandlerFrames.ScrollFrame
	local eventFrame = EVENTS.EventHandlerFrames[EVENTS.currentEventID]

	if not eventFrame then return end

	if eventFrame:GetBottom() and eventFrame:GetBottom() < ScrollFrame:GetBottom() then
		ScrollFrame:SetVerticalScroll(ScrollFrame:GetVerticalScroll() + (ScrollFrame:GetBottom() - eventFrame:GetBottom()))
	elseif eventFrame:GetTop() and eventFrame:GetTop() > ScrollFrame:GetTop() then
		ScrollFrame:SetVerticalScroll(ScrollFrame:GetVerticalScroll() - (eventFrame:GetTop() - ScrollFrame:GetTop()))
	end
end

function EVENTS:SetTabText()
	local n = EVENTS:GetNumUsedEvents()

	if n > 0 then
		EventsTab:SetText(L["EVENTS_TAB"] .. " |cFFFF5959(" .. n .. ")")
	else
		EventsTab:SetText(L["EVENTS_TAB"] .. " (" .. n .. ")")
	end
end
TMW:RegisterCallback("TMW_CONFIG_LOADED", EVENTS, "SetTabText")



function EVENTS:IsEventIDValid(id)
	local eventSettings = EVENTS:GetEventSettings(id)

	local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventSettings)

	local validEvents = EVENTS:GetValidEvents(EventHandler)


	if eventSettings.Event == "" then
		-- The event is not set
		return false, EVENTS.CONST.EVENT_INVALID_REASON_NOEVENT

	elseif not TMW.EventList[eventSettings.Event] then
		-- The event does not exist
		return false, EVENTS.CONST.EVENT_INVALID_REASON_MISSINGEVENT
		
	end

	if validEvents[eventSettings.Event] then
		if EventHandler then
			-- This event is valid and can be loaded
			return true, 0
		else
			-- The event handler could not be found
			return false, EVENTS.CONST.EVENT_INVALID_REASON_MISSINGHANDLER
		end
	else
		-- The event is not valid for the current icon configuration
		return false, EVENTS.CONST.EVENT_INVALID_REASON_MISSINGCOMPONENT
	end

end

function EVENTS:GetEventSettings(eventID)

	return TMW.CI.ics and TMW.CI.ics.Events[eventID or EVENTS.currentEventID]
end

function EVENTS:GetEventData(event)
	if not event then
		event = EVENTS:GetEventSettings().Event
	end

	return TMW.EventList[event]
end

function EVENTS:GetNumUsedEvents()
	local n = 0

	if not TMW.CI.ics then
		return 0
	end

	for i, eventSettings in TMW:InNLengthTable(TMW.CI.ics.Events) do
		local Module = EVENTS:GetEventHandlerForEventSettings(eventSettings)

		if Module then
			local has = Module:ProcessIconEventSettings(eventSettings.Event, eventSettings)
			if has then
				n = n + 1
			end
		end
	end

	return n
end

function EVENTS:GetEventHandlerForEventSettings(arg1)
	local eventSettings
	if type(arg1) == "table" then
		eventSettings = arg1
	else
		eventSettings = EVENTS:GetEventSettings(arg1)
	end

	if eventSettings then
		return TMW.EVENTS:GetEventHandler(eventSettings.Type)
	end
end

function EVENTS:GetValidEvents(EventHandler)
	TMW:ValidateType("2 (EventHandler)", "EVENTS:GetValidEvents(EventHandler)", EventHandler, "EventHandler")

	local ValidEvents = EVENTS.ValidEvents
	
	ValidEvents = wipe(ValidEvents or {})
	
	for _, Component in ipairs(TMW.CI.icon.Components) do
		for _, eventData in ipairs(Component.IconEvents) do

			-- Don't include WhileConditionSetPassing if the event handler doesn't support it.
			if eventData.event ~= "WCSP" or EventHandler.supportWCSP then
				-- Put it in the table as an indexed field.
				ValidEvents[#ValidEvents+1] = eventData
				
				-- Put it in the table keyed by the event, for lookups.
				ValidEvents[eventData.event] = eventData
			end
		end
	end
	
	TMW:SortOrderedTables(ValidEvents)
	
	return ValidEvents
end



function EVENTS:UpOrDown(button, delta)
	local ID = button:GetID()
	local settings = TMW.CI.ics.Events

	local curdata = settings[ID]
	local destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata

	EVENTS:LoadConfig()
end

function EVENTS.OperatorMenu_DropDown(frame)
	local eventData = EVENTS.EventHandlerFrames[EVENTS.currentEventID].eventData

	for k, v in pairs(TMW.operators) do
		if not eventData.blacklistedOperators or not eventData.blacklistedOperators[v.value] then
			local info = TMW.DD:CreateInfo()
			info.func = EVENTS.OperatorMenu_DropDown_OnClick
			info.text = v.text
			info.value = v.value
			info.tooltipTitle = v.tooltipText
			info.arg1 = frame
			TMW.DD:AddButton(info)
		end
	end
end
function EVENTS.OperatorMenu_DropDown_OnClick(button, frame)
	frame:SetUIDropdownText(button.value)

	EVENTS:GetEventSettings().Operator = button.value
	TMW:TT(frame, button.tooltipTitle, nil, 1)
end


function EVENTS:ChangeEvent_Dropdown()
	if TMW.DD.MENU_LEVEL == 1 then
		local eventButton = EVENTS:GetParent()
		local eventID = eventButton:GetID()
		local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventID)

		
		for _, eventData in ipairs(EVENTS:GetValidEvents(EventHandler)) do
			local info = TMW.DD:CreateInfo()

			info.text = get(eventData.text)
			info.tooltipTitle = get(eventData.text)
			info.tooltipText = get(eventData.desc)
			

			info.value = eventData.event
			info.checked = eventData.event == eventButton.event
			info.func = EVENTS.ChangeEvent_Dropdown_OnClick
			info.keepShownOnClick = false
			info.arg1 = eventButton
			info.arg2 = eventData.event

			TMW.DD:AddButton(info)
		end
	end
end
function EVENTS:ChangeEvent_Dropdown_OnClick(eventButton, event)
	local eventID = eventButton:GetID()
	local eventSettings = EVENTS:GetEventSettings(eventID)

	eventSettings.Event = event

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(eventSettings)
	end

	EVENTS:LoadConfig()

	TMW.DD:CloseDropDownMenus()
end



local ColumnConfig = TMW.C.EventHandler_ColumnConfig

function ColumnConfig:GetListItemFrame(frameID)
	local SubHandlerList = self.ConfigContainer.SubHandlerList
	
	local frame = SubHandlerList[frameID]
	if not frame then
		frame = CreateFrame("Button", SubHandlerList:GetName().."Item"..frameID, SubHandlerList, "TellMeWhen_EventHandler_SubHandlerListButton", frameID)
		SubHandlerList[frameID] = frame

		local previousFrame = frameID > 1 and SubHandlerList[frameID - 1] or nil
		frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
		frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
	end

	frame.EventHandler = self

	return frame
end


function ColumnConfig:GetSubHandler(eventID)
	local subHandlerIdentifier = EVENTS:GetEventSettings(eventID)[self.subHandlerSettingKey]
	local subHandlerData = self.AllSubHandlersByIdentifier[subHandlerIdentifier]

	return subHandlerData, subHandlerIdentifier
end

local subHandlersToDisplay = {}
function ColumnConfig:LoadSettingsForEventID(id)
	local SubHandlerList = self.ConfigContainer.SubHandlerList
		
	wipe(subHandlersToDisplay)
	
	for i, subHandlerDataParent in ipairs(self.NonSpecificEventHandlerData) do
		tinsert(subHandlersToDisplay, subHandlerDataParent)
	end
	
	for i, GenericComponent in ipairs(TMW.CI.icon.Components) do
		if GenericComponent.EventHandlerData then
			for i, subHandlerDataParent in ipairs(GenericComponent.EventHandlerData) do
				if subHandlerDataParent.identifier == self.subHandlerDataIdentifier then
					tinsert(subHandlersToDisplay, subHandlerDataParent)
				end
			end
		end
	end
	
	TMW:SortOrderedTables(subHandlersToDisplay)
	
	local frameID = 0
	for _, subHandlerDataParent in ipairs(subHandlersToDisplay) do
		if not get(subHandlerDataParent.subHandlerData.hidden) then
			frameID = frameID + 1
			local frame = self:GetListItemFrame(frameID)
			frame:Show()

			local animationData = subHandlerDataParent.subHandlerData
			frame.subHandlerData = animationData
			frame.subHandlerIdentifier = animationData.subHandlerIdentifier

			frame.Name:SetText(animationData.text)
			TMW:TT(frame, animationData.text, animationData.desc, 1, 1)
		end
	end
	
	for i = #subHandlersToDisplay + 1, #SubHandlerList do
		SubHandlerList[i]:Hide()
	end

	if SubHandlerList[1] then
		SubHandlerList[1]:SetPoint("TOPLEFT", SubHandlerList, "TOPLEFT", 0, 0)
		SubHandlerList[1]:SetPoint("TOPRIGHT", SubHandlerList, "TOPRIGHT", 0, 0)
		
		SubHandlerList:Show()
	else
		SubHandlerList:Hide()
	end
	
	
	local EventSettings = EVENTS:GetEventSettings(id)
	self:SelectSubHandler(EventSettings[self.subHandlerSettingKey])
end

function ColumnConfig:SetSubHandler(subHandlerIdentifier)
	local subHandlerData = self.AllSubHandlersByIdentifier[subHandlerIdentifier]

	if TMW.CI.ics then
		local old = TMW.EVENTS:GetEventSettings()[self.subHandlerSettingKey]
		if old ~= subHandlerIdentifier then

			TMW.EVENTS:GetEventSettings()[self.subHandlerSettingKey] = subHandlerIdentifier
			TMW.IE:ScheduleIconSetup()


			TMW.EVENTS:LoadConfig()
			local eventSettings = EVENTS:GetEventSettings()
			if subHandlerData.applyDefaultsToSetting then
				subHandlerData.applyDefaultsToSetting(eventSettings)
			end


			self:SelectSubHandler(subHandlerIdentifier)
		end
	end
end

function ColumnConfig:SelectSubHandler(subHandlerIdentifier)
	local subHandlerListButton
	
	for i=1, #self.ConfigContainer.SubHandlerList do
		local f = self.ConfigContainer.SubHandlerList[i]
		if f and f:IsShown() then
			if f.subHandlerIdentifier == subHandlerIdentifier then
				subHandlerListButton = f
			end
			f.selected = nil
			f:UnlockHighlight()
			f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
		end
	end

	local subHandlerData = self.AllSubHandlersByIdentifier[subHandlerIdentifier]
	self.currentSubHandlerData = subHandlerData

	self:SetupConfig(subHandlerData)

	if subHandlerListButton then
		subHandlerListButton:LockHighlight()
		subHandlerListButton:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end

	self:SetupEventDisplay(self.currentEventID)
end

function ColumnConfig:RegisterConfigFrame(identifier, configFrameData)
	configFrameData.identifier = identifier
	TMW:ValidateType("identifier", "RegisterConfigFrame(identifier, configFrameData)", identifier, "string")
	
	TMW:ValidateType("configFrameData.frame", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.frame, "string;frame")
	TMW:ValidateType("configFrameData.Load", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.Load, "function")
	
	TMW:ValidateType("configFrameData.topPadding", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.topPadding, "number;nil")
	TMW:ValidateType("configFrameData.bottomPadding", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.bottomPadding, "number;nil")
	
	self.ConfigFrameData[identifier] = configFrameData
end

-- Override this method for handlers that need to blacklist a setting.
function ColumnConfig:IsFrameBlacklisted(frameName)
	return false
end

function ColumnConfig:SetupConfig(subHandlerData)
	local desiredFrames = subHandlerData.ConfigFrames
	local subHandlerIdentifier = subHandlerData.subHandlerIdentifier

	local EventSettings = EVENTS:GetEventSettings()
	local Frames = self.ConfigContainer.ConfigFrames

	assert(Frames, self.className .. " doesn't have a ConfigFrames table!")
	
	for configFrameIdentifier, configFrameData in pairs(self.ConfigFrameData) do
		
		local frame = configFrameData.frame
		if type(frame) == "string" then
			frame = Frames[frame]
		end
		if frame then
			frame:Hide()
		end
	end

	if not desiredFrames then
		return
	end

	local lastFrame, lastFrameBottomPadding
	for i, configFrameIdentifier in ipairs(desiredFrames) do
		if not self:IsFrameBlacklisted(configFrameIdentifier) then
			local configFrameData = self.ConfigFrameData[configFrameIdentifier]
			
			if not configFrameData then
				TMW:Error("Values in ConfigFrames for event handler %q must resolve to a table registered via EventHandler_ColumnConfig:RegisterConfigFrame()", subHandlerIdentifier)
			else
				local frame = configFrameData.frame
				if type(frame) == "string" then
					frame = Frames[frame]
					if not frame then
						TMW:Error("Couldn't find child of %s with key %q for event handler %q", Frames:GetName(), configFrameData.frame, subHandlerIdentifier)
					end
				end
				
				local yOffset = (configFrameData.topPadding or 0) + (lastFrameBottomPadding or 0)
				
				if lastFrame then
					frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -yOffset)
				else
					frame:SetPoint("TOP", Frames, "TOP", 0, -yOffset - 5)
				end
				frame:Show()
				lastFrame = frame
				
				TMW.safecall(configFrameData.Load, configFrameData, frame, EventSettings)
				
				lastFrameBottomPadding = configFrameData.bottomPadding
			end
		end
	end	
end


function ColumnConfig.Load_Generic_Slider(configFrameData, frame, EventSettings)
	frame:ReloadSetting()

	if configFrameData.text then
		frame.text:SetText(configFrameData.text)
		frame:SetTooltip(configFrameData.text, configFrameData.desc)
	end

	frame:Enable()
end

function ColumnConfig.Load_Generic_Check(configFrameData, frame, EventSettings)
	frame:SetChecked(EventSettings[configFrameData.identifier])

	frame.setting = configFrameData.identifier

	if configFrameData.text then
		frame.text:SetText(configFrameData.text)
		TMW:TT(frame, configFrameData.text, configFrameData.desc, 1, 1)
	end
end