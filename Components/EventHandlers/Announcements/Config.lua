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

local ipairs = 
	  ipairs
	  
local CI = TMW.CI

-- GLOBALS: CreateFrame, NONE, NORMAL_FONT_COLOR, UIDropDownMenu_SetText


local EVENTS = TMW.EVENTS
local ANN = TMW.ANN
ANN.handlerName = L["ANN_TAB"]

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function(event)
	TMW:ConvertContainerToScrollFrame(ANN.ConfigContainer.ConfigFrames)

end)




---------- Events ----------
function ANN:GetChannelFrame(frameID, previousFrame)
	local ChannelList = self.ConfigContainer.ChannelList
	
	local frame = ChannelList[frameID]
	if not frame then
		frame = CreateFrame("Button", ChannelList:GetName().."Channel"..frameID, ChannelList, "TellMeWhen_ChannelSelectButton", frameID)
		ChannelList[frameID] = frame
		frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
		frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
	end
	return frame
end

local channelsToDisplay = {}
function ANN:LoadSettingsForEventID(id)
	ANN.ConfigContainer.EditBox:ClearFocus()
	
	wipe(channelsToDisplay)
	
	local ChannelList = self.ConfigContainer.ChannelList

	-- create channel frames
	local previousFrame
	local frameID = 0
	for i, eventHandlerData in ipairs(self.NonSpecificEventHandlerData) do
		local channelData = eventHandlerData.channelData
		tinsert(channelsToDisplay, channelData)
	end
	
	for i, GenericComponent in ipairs(CI.ic.Components) do
		if GenericComponent.EventHandlerData then
			for i, eventHandlerData in ipairs(GenericComponent.EventHandlerData) do
				if eventHandlerData.eventHandler == self then
					tinsert(channelsToDisplay, eventHandlerData.channelData)
				end
			end
		end
	end
	
	TMW:SortOrderedTables(channelsToDisplay)
	
	local frameID = 0
	for _, channelData in ipairs(channelsToDisplay) do
		if not get(channelData.hidden) then
			frameID = frameID + 1
			local frame = self:GetChannelFrame(frameID, previousFrame)
			frame:Show()

			frame.channel = channelData.channel

			frame.Name:SetText(channelData.text)
			TMW:TT(frame, channelData.text, channelData.desc, 1, 1)

			previousFrame = frame
		end
	end
	
	for i = #channelsToDisplay + 1, #ChannelList do
		ChannelList[i]:Hide()
	end

	if ChannelList[1] then
		ChannelList[1]:SetPoint("TOPLEFT", ChannelList, "TOPLEFT", 0, 0)
		ChannelList[1]:SetPoint("TOPRIGHT", ChannelList, "TOPRIGHT", 0, 0)
		
		ChannelList:Show()
	else
		ChannelList:Hide()
	end
	
	
	local EventSettings = EVENTS:GetEventSettings()
	ANN:SelectChannel(EventSettings.Channel)
	ANN.ConfigContainer.EditBox:SetText(EventSettings.Text)
end

function ANN:SetupEventDisplay(eventID)
	if not eventID then return end

	local EventSettings = EVENTS:GetEventSettings(eventID)
	local channel = EventSettings.Channel
	local channelsettings = ANN.AllChannelsByChannel[channel]


	if channelsettings then
		local chan = channelsettings.text
		local data = EventSettings.Text
		if data == "" then
			data = "|cff808080" .. L["ANN_NOTEXT"] .. "|r"
		elseif chan == NONE then
			data = "|cff808080" .. chan .. "|r"
		end
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.handlerName .. ":|r " .. data)
	else
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.handlerName .. ":|r UNKNOWN: " .. (channel or "?"))
	end
end


---------- ChannelList ----------
function ANN:SelectChannel(channel)
	local EventSettings = EVENTS:GetEventSettings()
	local channelFrame

	local ConfigFrames = ANN.ConfigContainer.ConfigFrames
	
	for i=1, #ANN.ConfigContainer.ChannelList do
		local f = ANN.ConfigContainer.ChannelList[i]
		if f and f:IsShown() then
			if f.channel == channel then
				channelFrame = f
			end
			f.selected = nil
			f:UnlockHighlight()
			f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
		end
	end
	self.currentChannelSetting = channel

	local channelsettings = ANN.AllChannelsByChannel[channel]
	if channelsettings then
		if channelsettings.sticky then
			ConfigFrames.Sticky:SetChecked(EventSettings.Sticky)
			ConfigFrames.Sticky:Show()
		else
			ConfigFrames.Sticky:Hide()
		end
		
		if channelsettings.icon then
			ConfigFrames.ShowIconTex:SetChecked(EventSettings.Icon)
			ConfigFrames.ShowIconTex:Show()
		else
			ConfigFrames.ShowIconTex:Hide()
		end
		
		if channelsettings.defaultlocation then
			local defaultlocation = get(channelsettings.defaultlocation)
			local location = EventSettings.Location
			
			location = location and location ~= "" and location or defaultlocation
			location = channelsettings.ddtext(location) and location or defaultlocation
			
			EventSettings.Location = location
			local loc = channelsettings.ddtext(location)
			
			ConfigFrames.Location.selectedValue = location
			UIDropDownMenu_SetText(ConfigFrames.Location, loc)
			
			ConfigFrames.Location:Show()
		else
			ConfigFrames.Location:Hide()
		end
		if channelsettings.color then
			local r, g, b = EventSettings.r, EventSettings.g, EventSettings.b
			ConfigFrames.Color:GetNormalTexture():SetVertexColor(r, g, b, 1)
			ConfigFrames.Color:Show()
		else
			ConfigFrames.Color:Hide()
		end
		if channelsettings.size then
			ConfigFrames.Size:SetValue(EventSettings.Size)
			ConfigFrames.Size:Show()
		else
			ConfigFrames.Size:Hide()
		end
		if channelsettings.editbox then
			ConfigFrames.WhisperTarget:SetText(EventSettings.Location)
			ConfigFrames.WhisperTarget:Show()
		else
			ConfigFrames.WhisperTarget:Hide()
		end
	end

	if channelFrame then
		channelFrame:LockHighlight()
		channelFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end

	self:SetupEventDisplay(self.currentEventID)
end


---------- Interface ----------
function ANN:Location_DropDown()
	local channelSettings = ANN.AllChannelsByChannel[ANN.currentChannelSetting]
	if channelSettings and channelSettings.dropdown then
		channelSettings.dropdown()
	end
end
function ANN:Location_DropDown_OnClick(text)
	local dropdown = self
	
	local ConfigFrames = ANN.ConfigContainer.ConfigFrames
	
	ConfigFrames.Location.selectedValue = dropdown.value
	UIDropDownMenu_SetText(ConfigFrames.Location, text)	
	
	EVENTS:GetEventSettings().Location = dropdown.value
end

