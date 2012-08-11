-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
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


local ANN = TMW.ANN
ANN.tabText = L["ANN_TAB"]


TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	local Events = ANN.Events
	local ChannelList = ANN.ConfigContainer.ChannelList

	ChannelList.Header:SetText(L["ANN_CHANTOUSE"])

	-- create event frames

	-- create channel frames
	local previousFrame
	local offs = 0
	for i, channelData in ipairs(ANN.AllChannelsOrdered) do --TODO TEMP DEBUG HACK AHHH BAD CODE this shouldn't use ANN.AllChannelsByChannel
		if not get(channelData.hidden) then
			i = i + offs
			local frame = CreateFrame("Button", ChannelList:GetName().."Channel"..i, ChannelList, "TellMeWhen_ChannelSelectButton", i)
			ChannelList[i] = frame
			frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
			frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
			frame:Show()

			frame.channel = channelData.channel

			frame.Name:SetText(channelData.text)
			TMW:TT(frame, channelData.text, channelData.desc, 1, 1)

			previousFrame = frame
		else
			offs = offs - 1
		end
	end

	if ChannelList[1] then
		ChannelList[1]:SetPoint("TOPLEFT", ChannelList, "TOPLEFT", 0, 0)
		ChannelList[1]:SetPoint("TOPRIGHT", ChannelList, "TOPRIGHT", 0, 0)
	
		ChannelList:SetHeight(#ChannelList*ChannelList[1]:GetHeight())
		
		ChannelList:Show()
	else
		ChannelList:Hide()
	end
end
)


---------- Events ----------
function ANN:LoadSettingsForEventID(id)
	ANN.ConfigContainer.EditBox:ClearFocus()

	local eventFrame = self:ChooseEvent(id)

	if CI.ics and eventFrame then
		local EventSettings = self:GetEventSettings()
		ANN:SelectChannel(EventSettings.Channel)
		ANN.ConfigContainer.EditBox:SetText(EventSettings.Text)
		ANN:SetupEventSettings()
	end
end

function ANN:SetupEventDisplay(eventID)
	if not eventID then return end

	local EventSettings = self:GetEventSettings(eventID)
	local channel = EventSettings.Channel
	local channelsettings = ANN.AllChannelsByChannel[channel]

	if channelsettings then
		local chan = channelsettings.text
		local data = EventSettings.Text
		if chan == NONE then
			data = "|cff808080" .. chan .. "|r"
		end
		self.Events[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r " .. data)
	else
		self.Events[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r UNKNOWN: " .. (channel or "?"))
	end
end


---------- ChannelList ----------
function ANN:SelectChannel(channel)
	local EventSettings = self:GetEventSettings()
	local channelFrame

	for i=1, #ANN.ConfigContainer.ChannelList do
		local f = ANN.ConfigContainer.ChannelList[i]
		if f then
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
			ANN.ConfigContainer.Sticky:SetChecked(EventSettings.Sticky)
			ANN.ConfigContainer.Sticky:Show()
		else
			ANN.ConfigContainer.Sticky:Hide()
		end
		if channelsettings.icon then
			ANN.ConfigContainer.ShowIconTex:SetChecked(EventSettings.Icon)
			ANN.ConfigContainer.ShowIconTex:Show()
		else
			ANN.ConfigContainer.ShowIconTex:Hide()
		end
		if channelsettings.defaultlocation then
			local defaultlocation = get(channelsettings.defaultlocation)
			local location = EventSettings.Location
			location = location and location ~= "" and location or defaultlocation
			location = channelsettings.ddtext(location) and location or defaultlocation
			EventSettings.Location = location
			local loc = channelsettings.ddtext(location)
			TMW:SetUIDropdownText(ANN.ConfigContainer.Location, location)
			UIDropDownMenu_SetText(ANN.ConfigContainer.Location, loc)
			ANN.ConfigContainer.Location:Show()
		else
			ANN.ConfigContainer.Location:Hide()
		end
		if channelsettings.color then
			local r, g, b = EventSettings.r, EventSettings.g, EventSettings.b
			ANN.ConfigContainer.Color:GetNormalTexture():SetVertexColor(r, g, b, 1)
			ANN.ConfigContainer.Color:Show()
		else
			ANN.ConfigContainer.Color:Hide()
		end
		if channelsettings.size then
			ANN.ConfigContainer.Size:SetValue(EventSettings.Size)
			ANN.ConfigContainer.Size:Show()
		else
			ANN.ConfigContainer.Size:Hide()
		end
		if channelsettings.editbox then
			ANN.ConfigContainer.WhisperTarget:SetText(EventSettings.Location)
			ANN.ConfigContainer.WhisperTarget:Show()
		else
			ANN.ConfigContainer.WhisperTarget:Hide()
		end
	end

	if channelFrame then
		channelFrame:LockHighlight()
		channelFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end

	--self:SetupEventDisplay(EVENTS.currentEventID)
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
	
	TMW:SetUIDropdownText(ANN.ConfigContainer.Location, dropdown.value)
	UIDropDownMenu_SetText(ANN.ConfigContainer.Location, text)
	ANN:GetEventSettings().Location = dropdown.value
end

