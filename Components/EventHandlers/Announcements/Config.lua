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

-- GLOBALS: CreateFrame, NONE, NORMAL_FONT_COLOR


local EVENTS = TMW.EVENTS
local Announcements = EVENTS:GetEventHandler("Announcements")

Announcements.handlerName = L["ANN_TAB"]
Announcements.handlerDesc = L["ANN_TAB_DESC"]


TMW:RegisterCallback("TMW_OPTIONS_LOADED", function(event)
	TMW:ConvertContainerToScrollFrame(Announcements.ConfigContainer.ConfigFrames)

	Announcements.ConfigContainer.SubHandlerListHeader:SetText(TMW.L["ANN_CHANTOUSE"])
	Announcements.ConfigContainer.SettingsHeader:SetText(L["ANIM_ANIMSETTINGS"])

end)



---------- Events ----------
function Announcements:SetupEventDisplay(eventID)
	if not eventID then return end

	local EventSettings = EVENTS:GetEventSettings(eventID)
	local subHandlerData, subHandlerIdentifier = self:GetSubHandler(eventID)

	if subHandlerData then
		local chanName = subHandlerData.text
		local data = EventSettings.Text
		if data == "" then
			data = "|cff808080" .. L["ANN_NOTEXT"] .. "|r"
		elseif chanName == NONE then
			data = "|cff808080" .. chanName .. "|r"
		end
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.handlerName .. ":|r " .. data)
	else
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.handlerName .. ":|r UNKNOWN: " .. (subHandlerIdentifier or "?"))
	end
end

Announcements:PostHookMethod("LoadSettingsForEventID", function(self, id)
	local EventSettings = EVENTS:GetEventSettings(id)
	
	self.ConfigContainer.EditBox:SetText(EventSettings.Text)
	self.ConfigContainer.EditBox.Error:SetText(TMW:TestDogTagString(CI.icon, EventSettings.Text))
end)





---------- Interface ----------
function Announcements:Location_DropDown()
	local channelData = Announcements.currentSubHandlerData
	if channelData and channelData.dropdown then
		channelData.dropdown()
	end
end
function Announcements:Location_DropDown_OnClick(text)
	local dropdown = self
	
	local ConfigFrames = Announcements.ConfigContainer.ConfigFrames
	
	ConfigFrames.Location.selectedValue = dropdown.value
	ConfigFrames.Location:SetText(text)	
	
	EVENTS:GetEventSettings().Location = dropdown.value
end


local Load_Generic_Slider = Announcements.Load_Generic_Slider
local Load_Generic_Check = Announcements.Load_Generic_Check


local Announcements = EVENTS:GetEventHandler("Announcements")


Announcements:RegisterConfigFrame("Location", {
	frame = "Location",
	topPadding = 14,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		local channelData = Announcements.currentSubHandlerData

		local defaultlocation = get(channelData.defaultlocation)
		local location = EventSettings.Location
		
		location = location and location ~= "" and location or defaultlocation
		location = channelData.ddtext(location) and location or defaultlocation
		
		EventSettings.Location = location
		local loc = channelData.ddtext(location)
		
		frame.selectedValue = location
		frame:SetText(loc)
			
	end,
})

Announcements:RegisterConfigFrame("WhisperTarget", {
	frame = "WhisperTarget",
	topPadding = 14,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		frame:SetText(EventSettings.Location)
	end,
})

Announcements:RegisterConfigFrame("Sticky", {
	frame = "Sticky",
	--topPadding = 13,
	--bottomPadding = 13,

	text = L["ANN_STICKY"],

	Load = Load_Generic_Check,
})

Announcements:RegisterConfigFrame("ShowIconTex", {
	frame = "ShowIconTex",
	--topPadding = 13,
	--bottomPadding = 13,

	text = L["ANN_SHOWICON"],
	desc = L["ANN_SHOWICON_DESC"],

	Load = Load_Generic_Check,
})

Announcements:RegisterConfigFrame("Color", {
	frame = "Color",
	topPadding = 4,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		local r, g, b = EventSettings.r, EventSettings.g, EventSettings.b
		frame:GetNormalTexture():SetVertexColor(r, g, b, 1)
	end,
})

TMW.IE:RegisterRapidSetting("Size")
Announcements:RegisterConfigFrame("Size", {
	frame = "Size",
	topPadding = 13,
	bottomPadding = 13,

	text = L["FONTSIZE"],
	
	Load = Load_Generic_Slider,
})

TMW.IE:RegisterRapidSetting("TextDuration")
Announcements:RegisterConfigFrame("TextDuration", {
	frame = "TextDuration",
	topPadding = 13,
	bottomPadding = 13,

	text = L["DURATION"],
	
	Load = Load_Generic_Slider,
})



