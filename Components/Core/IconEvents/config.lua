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
}

local EventsTab = TMW.Classes.IconEditorTab:NewTab(10, "Events")
EventsTab:SetText(TMW.L["EVENTS_TAB"])
TMW:TT(EventsTab, "EVENTS_TAB", "EVENTS_TAB_DESC")


function EVENTS:LoadConfig()
	self:CreateEventButtons()
	
	local oldID = max(1, self.currentEventID or 1)

	local didLoad
	for i = 1, TMW.CI.ics.Events.n do
		-- This wizard magic allows us to iterate over all eventIDs, 
		-- starting with the currently selected one (oldID)
		-- So, for example, if oldID == 3 and TMW.CI.ics.Events.n == 6,
		-- eventID will be iterated as 3, 4, 5, 6, 1, 2
		local eventID = ((i-2+oldID) % TMW.CI.ics.Events.n) + 1
		local frame = self.EventHandlerFrames[eventID]
		
		-- Check if this eventID is valid, and load it if it is.
		local isValid, reason = EVENTS:IsEventIDValid(eventID)
		
		if isValid then
			if not didLoad then
				EVENTS:LoadEventID(eventID)
				didLoad = true
			end
			
			local EventHandler = EVENTS:GetEventHandlerForEventSettings(eventID)
			EventHandler:SetupEventDisplay(eventID)
			frame:Enable()
		else
			frame:Disable()
			
			if reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGHANDLER then
				frame.DataText:SetText("|cFFFF5050UNKNOWN TYPE:|r " .. tostring(EVENTS:GetEventSettings(i).Type))
			elseif reason == EVENTS.CONST.EVENT_INVALID_REASON_MISSINGCOMPONENT then
				frame.DataText:SetText(L["SOUND_EVENT_DISABLEDFORTYPE"])
				TMW:TT(frame, frame.eventData.text, L["SOUND_EVENT_DISABLEDFORTYPE_DESC2"]:format(TMW.Types[TMW.CI.ics.Type].name), 1, 1)
			end
		end
	end
	
	if not didLoad then
		for _, EventHandler in ipairs(TMW.Classes.EventHandler.instances) do
			EventHandler.ConfigContainer:Hide()
		end
		self.EventSettingsContainer:Hide()
		IE.Events.HelpText:Show()
	end


	self:SetTabText()
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", "LoadConfig", EVENTS)

function EVENTS:LoadEventID(id)
	local eventFrame = self.EventHandlerFrames[id]
	
	EVENTS.currentEventID = id ~= 0 and id or nil

	for _, EventHandler in ipairs(TMW.Classes.EventHandler.instances) do
		EventHandler.ConfigContainer:Hide()
	end
	IE.Events.HelpText:Show()
	
	local EventHandler = self:GetEventHandlerForEventSettings(id)
	if EventHandler then
		EventHandler.ConfigContainer:Show()
		IE.Events.HelpText:Hide()
		
		EVENTS.currentEventHandler = EventHandler
		
		EventHandler:LoadSettingsForEventID(id)
		EVENTS:LoadEventSettings()
	end

	IE.Events.ScrollFrame.adjustmentQueued = true

	if not eventFrame or id == 0 or not eventFrame:IsShown() then
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

	TMW:SetUIDropdownIconText(EventSettingsContainer.Icon, Settings.Icon, L["CHOOSEICON"])
	EventSettingsContainer.Icon.IconPreview:SetIcon(_G[Settings.Icon])

	--show settings
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



function EVENTS:CreateEventButtons()
	local EventHandlerFrames = self.EventHandlerFrames
	local previousFrame

	local yAdjustTitle, yAdjustText = 0, 0
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		yAdjustTitle, yAdjustText = 3, -3
	end
	local Settings = self:GetEventSettings()

	for i, eventSettings in TMW:InNLengthTable(TMW.CI.ics.Events) do
		local eventData = TMW.EventList[eventSettings.Event]
		local frame = EventHandlerFrames[i]
		
		if not frame then
			frame = CreateFrame("Button", EventHandlerFrames:GetName().."Event"..i, EventHandlerFrames, "TellMeWhen_Event", i)
			EventHandlerFrames[i] = frame
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

		if eventData then
			frame:Show()

			frame.event = eventData.event
			frame.eventData = eventData

			frame.EventName:SetText(i .. ") " .. eventData.text)

			frame.normalDesc = eventData.desc .. "\r\n\r\n" .. L["EVENTS_HANDLERS_GLOBAL_DESC"]
			TMW:TT(frame, eventData.text, frame.normalDesc, 1, 1)
		else
			frame.EventName:SetText(i .. ") UNKNOWN EVENT: " .. tostring(eventSettings.Event))
			frame:Disable()

		end
		previousFrame = frame
	end

	for i = max(TMW.CI.ics.Events.n + 1, 1), #EventHandlerFrames do
		EventHandlerFrames[i]:Hide()
	end

	if EventHandlerFrames[1] then
		EventHandlerFrames[1]:SetPoint("TOPLEFT", EventHandlerFrames, "TOPLEFT", 0, 0)
		EventHandlerFrames[1]:SetPoint("TOPRIGHT", EventHandlerFrames, "TOPRIGHT", 0, 0)
	end

	EventHandlerFrames:SetHeight(max(TMW.CI.ics.Events.n*(EventHandlerFrames[1] and EventHandlerFrames[1]:GetHeight() or 0), 1))
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
	local n = self:GetNumUsedEvents()

	if n > 0 then
		EventsTab:SetText(L["EVENTS_TAB"] .. " |cFFFF5959(" .. n .. ")")
	else
		EventsTab:SetText(L["EVENTS_TAB"] .. " (" .. n .. ")")
	end
end



function EVENTS:IsEventIDValid(id)
	local ValidEvents = EVENTS:GetValidEvents()
	
	local EventSettings = EVENTS:GetEventSettings(id)
	
	if ValidEvents[EventSettings.Event] then
		local Module = EVENTS:GetEventHandlerForEventSettings(EventSettings)
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
	for i = 1, #self.EventHandlerFrames do
		local f = self.EventHandlerFrames[i]
		local Module = EVENTS:GetEventHandlerForEventSettings(i)
		if Module then
			local has = Module:ProcessIconEventSettings(f.event, self:GetEventSettings(i))
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
		for icon, groupID, iconID in TMW:InIcons() do
			if icon:IsValid() and UIDROPDOWNMENU_MENU_VALUE == groupID and TMW.CI.ic ~= icon then
				local info = UIDropDownMenu_CreateInfo()

				local text, textshort, tooltip = TMW:GetIconMenuText(groupID, iconID)
				if text:sub(-2) == "))" then
					textshort = textshort .. " " .. L["fICON"]:format(iconID)
				end
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), iconID) .. "\r\n" .. tooltip
				info.tooltipOnButton = true

				info.value = icon:GetName()
				info.arg1 = frame
				info.func = EVENTS.IconMenu_DropDown_OnClick

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
				info.text = TMW:GetGroupName(groupID, groupID)
				info.hasArrow = true
				info.notCheckable = true
				info.value = groupID
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end
function EVENTS.IconMenu_DropDown_OnClick(button, frame)
	TMW:SetUIDropdownIconText(frame, button.value)
	CloseDropDownMenus()

	frame.IconPreview:SetIcon(_G[button.value])

	EVENTS:GetEventSettings().Icon = button.value
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
	local EventSettings = EVENTS:GetEventSettings(eventID)

	EventSettings.Event = event
	EventSettings.Type = type

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(EventSettings)
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
	local EventSettings = TMW.CI.ics.Events[n]

	EventSettings.Event = event

	local eventData = TMW.EventList[event]
	if eventData and eventData.applyDefaultsToSetting then
		eventData.applyDefaultsToSetting(EventSettings)
	end

	EVENTS:LoadConfig()

	CloseDropDownMenus()
end





