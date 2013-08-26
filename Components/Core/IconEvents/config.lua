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

function TMW.Classes.EventHandler:TestEvent(eventID)
	local eventSettings = EVENTS:GetEventSettings(eventID)

	self:HandleEvent(TMW.CI.ic, eventSettings)
end

EVENTS.CONST = {
	EVENT_INVALID_REASON_MISSINGHANDLER = 1,
	EVENT_INVALID_REASON_MISSINGCOMPONENT = 2,
	EVENT_INVALID_REASON_MISSINGEVENT = 3,
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


function EVENTS:LoadConfig()
	local EventHandlerFrames = self.EventHandlerFrames
	local previousFrame

	local yAdjustTitle, yAdjustText = 0, 0
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		yAdjustTitle, yAdjustText = 3, -3
	end

	
	local oldID = max(1, self.currentEventID or 1)

	local didLoad
	for i = 1, TMW.CI.ics.Events.n do
		-- This wizard magic allows us to iterate over all eventIDs, 
		-- starting with the currently selected one (oldID)
		-- So, for example, if oldID == 3 and TMW.CI.ics.Events.n == 6,
		-- eventID will be iterated as 3, 4, 5, 6, 1, 2
		local eventID = ((i-2+oldID) % TMW.CI.ics.Events.n) + 1
		i = nil -- i should not be used after this point since it won't correspond to any meaningful data.


		-- Get the frame that this event will be listed in.
		local frame = self.EventHandlerFrames[eventID]
		if not frame then
			-- If the frame doesn't exist, then create it.
			frame = CreateFrame("Button", EventHandlerFrames:GetName().."Event"..eventID, EventHandlerFrames, "TellMeWhen_Event", eventID)
			EventHandlerFrames[eventID] = frame

			frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT")
			frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")

			local p, t, r, x, y = frame.EventName:GetPoint(1)
			frame.EventName:SetPoint(p, t, r, x, y + yAdjustTitle)
			local p, t, r, x, y = frame.EventName:GetPoint(2)
			frame.EventName:SetPoint(p, t, r, x, y + yAdjustTitle)
			local p, t, r, x, y = frame.DataText:GetPoint(1)
			frame.DataText:SetPoint(p, t, r, x, y + yAdjustText)
			local p, t, r, x, y = frame.DataText:GetPoint(2)
			frame.DataText:SetPoint(p, t, r, x, y + yAdjustText)
		end
		previousFrame = frame
		frame:Show()


		-- Check if this eventID is valid, and load it if it is.
		local isValid, reason = EVENTS:IsEventIDValid(eventID)
		local eventSettings = TMW.CI.ics.Events[eventID]
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

			frame.normalDesc = eventData.desc .. "\r\n\r\n" .. L["EVENTS_HANDLERS_GLOBAL_DESC"]
			TMW:TT(frame, eventData.text, frame.normalDesc, 1, 1)

			-- This delegates the setup of frame.DataText to the event handler
			-- so that it can put useful information about the user's settings
			-- (e.g. "Sound: TMW - Pling3" or "Animation: Icon: Shake")
			local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventID)
			EventHandler:SetupEventDisplay(eventID)

			-- If we have not yet loaded an event for this configuration load,
			-- then load this event. The proper event settings and event handler
			-- configuration will be shown and setup with stored settings.
			if not didLoad then
				EVENTS:LoadEventID(eventID)
				didLoad = true
			end

		else
			frame:Disable()

			if reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGHANDLER then
				-- The handler (E.g. Sound, Animation, etc.) of the event settings was not found.
				frame.DataText:SetText("|cFFFF5050UNKNOWN HANDLER:|r " .. tostring(EVENTS:GetEventSettings(eventID).Type))
			elseif reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGEVENT then
				-- The event (E.g. "OnSomethingHappened") was not found
				frame.DataText:SetText("|cFFFF5050UNKNOWN EVENT|r")
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
		for _, EventHandler in ipairs(TMW.Classes.EventHandler.instances) do
			EventHandler.ConfigContainer:Hide()
		end
		self.EventSettingsContainer:Hide()
		IE.Events.HelpText:Show()
	end

	-- Set the text on the tab that will show how many used events we have.
	self:SetTabText()
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", EVENTS, "LoadConfig")

function EVENTS:LoadEventID(eventID)
	-- Loads the configuration for the specified e
	local eventFrame = self.EventHandlerFrames[eventID]
	
	EVENTS.currentEventID = eventID ~= 0 and eventID or nil

	for _, EventHandler in ipairs(TMW.Classes.EventHandler.instances) do
		EventHandler.ConfigContainer:Hide()
	end
	IE.Events.HelpText:Show()
	
	local EventHandler = self:GetEventHandlerForEventSettings(eventID)
	if EventHandler then
		EventHandler.ConfigContainer:Show()
		IE.Events.HelpText:Hide()
		
		EVENTS.currentEventHandler = EventHandler
		
		EventHandler:LoadSettingsForEventID(eventID)
		EVENTS:LoadEventSettings()
	end

	IE.Events.ScrollFrame.adjustmentQueued = true

	if not eventFrame or eventID == 0 or not eventFrame:IsShown() then
		return
	end

	for i, frame in ipairs(self.EventHandlerFrames) do
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetAlpha(0.1)
	end
	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetAlpha(0.2)
	
end

function EVENTS:LoadEventSettings()
	local EventSettingsContainer = self.EventSettingsContainer

	if not EVENTS.currentEventID then
		EventSettingsContainer:Hide()
		return
	end
	EventSettingsContainer:Show()

	local eventData = self.EventHandlerFrames[EVENTS.currentEventID].eventData

	IE.Events.EventSettingsContainerEventName:SetText("(" .. EVENTS.currentEventID .. ") " .. eventData.text)

	local Settings = self:GetEventSettings()
	local settingsUsedByEvent = eventData.settings
	
	TMW:Fire("TMW_CONFIG_EVENTS_SETTINGS_SETUP_PRE")

	--hide settings
	EventSettingsContainer.Operator	 	 		:Hide()
	EventSettingsContainer.Value		 	 	:Hide()
	EventSettingsContainer.CndtJustPassed 		:Hide()
	EventSettingsContainer.PassingCndt	 		:Hide()
	EventSettingsContainer.Icon			 		:Hide()

	--set settings
	EventSettingsContainer.PassThrough	 		:SetChecked(Settings.PassThrough)
	EventSettingsContainer.OnlyShown	 		:SetChecked(Settings.OnlyShown)
	EventSettingsContainer.CndtJustPassed 		:SetChecked(Settings.CndtJustPassed)
	EventSettingsContainer.PassingCndt	 		:SetChecked(Settings.PassingCndt)
	EventSettingsContainer.Value		 	 	:SetText(Settings.Value)

	TMW:SetUIDropdownGUIDText(EventSettingsContainer.Icon, Settings.Icon, L["CHOOSEICON"])
	EventSettingsContainer.Icon.IconPreview:SetIcon(TMW.GUIDToOwner[Settings.Icon])

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

	local v = TMW:SetUIDropdownText(EventSettingsContainer.Operator, Settings.Operator, TMW.operators)
	if v then
		TMW:TT(EventSettingsContainer.Operator, v.tooltipText, nil, 1)
	end
	
	TMW:Fire("TMW_CONFIG_EVENTS_SETTINGS_SETUP_POST")
end



function EVENTS:AdjustScrollFrame()
	local ScrollFrame = IE.Events.ScrollFrame
	local eventFrame = self.EventHandlerFrames[self.currentEventID]

	if not eventFrame then return end

	if eventFrame:GetBottom() and eventFrame:GetBottom() < ScrollFrame:GetBottom() then
		ScrollFrame.ScrollBar:SetValue(ScrollFrame.ScrollBar:GetValue() + (ScrollFrame:GetBottom() - eventFrame:GetBottom()))
	elseif eventFrame:GetTop() and eventFrame:GetTop() > ScrollFrame:GetTop() then
		ScrollFrame.ScrollBar:SetValue(ScrollFrame.ScrollBar:GetValue() - (eventFrame:GetTop() - ScrollFrame:GetTop()))
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



function EVENTS:IsEventIDValid(id)
	local validEvents = EVENTS:GetValidEvents()
	
	local eventSettings = EVENTS:GetEventSettings(id)
	
	if not TMW.EventList[eventSettings.Event] then
		-- The event does not exist
		return false, EVENTS.CONST.EVENT_INVALID_REASON_MISSINGEVENT
		
	elseif validEvents[eventSettings.Event] then
		local Module = EVENTS:GetEventHandlerForEventSettings(eventSettings)
		if Module then
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

	return TMW.CI.ics.Events[eventID or EVENTS.currentEventID]
end

function EVENTS:GetNumUsedEvents()
	local n = 0

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

function EVENTS:GetValidEvents()
	local ValidEvents = EVENTS.ValidEvents
	
	ValidEvents = wipe(ValidEvents or {})
	
	for _, Component in ipairs(TMW.CI.ic.Components) do
		for _, eventData in ipairs(Component.IconEvents) do
			-- Put it in the table as an indexed field.
			ValidEvents[#ValidEvents+1] = eventData
			
			-- Put it in the table keyed by the event, for lookups.
			ValidEvents[eventData.event] = eventData
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
			local info = UIDropDownMenu_CreateInfo()
			info.func = EVENTS.OperatorMenu_DropDown_OnClick
			info.text = v.text
			info.value = v.value
			info.tooltipTitle = v.tooltipText
			info.tooltipOnButton = true
			info.arg1 = frame
			UIDropDownMenu_AddButton(info)
		end
	end
end
function EVENTS.OperatorMenu_DropDown_OnClick(button, frame)
	TMW:SetUIDropdownText(frame, button.value)

	EVENTS:GetEventSettings().Operator = button.value
	TMW:TT(frame, button.tooltipTitle, nil, 1)
end

function EVENTS.IconMenu_DropDown(frame)
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for icon, groupID, iconID in TMW:InIcons(UIDROPDOWNMENU_MENU_VALUE) do
			if icon:IsValid() and TMW.CI.ic ~= icon then
				local info = UIDropDownMenu_CreateInfo()

				local text, textshort, tooltip = TMW:GetIconMenuText(groupID, iconID, icon:GetSettings())
				if text:sub(-2) == "))" then
					textshort = textshort .. " " .. L["fICON"]:format(iconID)
				end
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipText = format(L["GROUPICON"], icon.group:GetGroupName(1), iconID) .. "\r\n" .. tooltip
				info.tooltipOnButton = true

				info.value = icon
				info.arg1 = frame
				info.func = EVENTS.IconMenu_DropDown_OnClick
				info.checked = EVENTS:GetEventSettings().Icon == icon:GetGUID()

				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				info.icon = icon.attributes.texture

				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then
		for group, groupID in TMW:InGroups() do
			if group:ShouldUpdateIcons() then
				local info = UIDropDownMenu_CreateInfo()
				info.text = group:GetGroupName()
				info.hasArrow = true
				info.notCheckable = true
				info.value = groupID
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end
function EVENTS.IconMenu_DropDown_OnClick(button, frame)
	CloseDropDownMenus()


	local icon = button.value
	local GUID = icon:GetGUID(true)

	TMW:SetUIDropdownGUIDText(frame, GUID, L["CHOOSEICON"])
	frame.IconPreview:SetIcon(icon)

	EVENTS:GetEventSettings().Icon = GUID
end

function EVENTS.AddEvent_Dropdown(frame)
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		for _, eventData in ipairs(EVENTS:GetValidEvents()) do
			local info = UIDropDownMenu_CreateInfo()

			info.text = get(eventData.text)
			info.tooltipTitle = get(eventData.text)
			info.tooltipText = get(eventData.desc)
			
			info.tooltipOnButton = true

			info.value = eventData.event
			info.hasArrow = true
			info.notCheckable = true
			info.keepShownOnClick = true

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for i, EventHandler in ipairs(TMW.Classes.EventHandler.instances) do
			local info = UIDropDownMenu_CreateInfo()

			info.text = EventHandler.handlerName

			info.value = EventHandler.eventHandlerName
			info.func = EVENTS.AddEvent_Dropdown_OnClick
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = EventHandler.eventHandlerName
			info.notCheckable = true

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end
function EVENTS.AddEvent_Dropdown_OnClick(button, event, type)
	TMW.CI.ics.Events.n = TMW.CI.ics.Events.n + 1

	local eventID = TMW.CI.ics.Events.n
	local eventSettings = EVENTS:GetEventSettings(eventID)

	eventSettings.Event = event
	eventSettings.Type = type

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(eventSettings)
	end

	EVENTS:LoadConfig()

	EVENTS:LoadEventID(eventID)

	CloseDropDownMenus()
end

function EVENTS:ChangeEvent_Dropdown()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		local eventButton = self:GetParent()
		
		for _, eventData in ipairs(EVENTS:GetValidEvents()) do
			local info = UIDropDownMenu_CreateInfo()

			info.text = get(eventData.text)
			info.tooltipTitle = get(eventData.text)
			info.tooltipText = get(eventData.desc)
			
			info.tooltipOnButton = true

			info.value = eventData.event
			info.checked = eventData.event == eventButton.event
			info.func = EVENTS.ChangeEvent_Dropdown_OnClick
			info.keepShownOnClick = false
			info.arg1 = eventButton
			info.arg2 = eventData.event

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end
function EVENTS:ChangeEvent_Dropdown_OnClick(eventButton, event)
	local n = eventButton:GetID()
	local eventSettings = TMW.CI.ics.Events[n]

	eventSettings.Event = event

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(eventSettings)
	end

	EVENTS:LoadConfig()

	CloseDropDownMenus()
end





