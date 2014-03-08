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

local CI = TMW.CI

local pairs, ipairs, max = 
	  pairs, ipairs, max

 -- GLOBALS: CreateFrame, NORMAL_FONT_COLOR, NONE

local EVENTS = TMW.EVENTS
local StatefulAnimations = TMW.EVENTS:GetEventHandler("Animations2")
StatefulAnimations.handlerName = L["ANIM_TAB_STATEFUL"]

local EventAnimations = TMW.Classes.EventHandler.instancesByName.Animations

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	StatefulAnimations.ConfigContainer = EventAnimations.ConfigContainer
	StatefulAnimations.ConfigFrameData = EventAnimations.ConfigFrameData
end)


---------- Events ----------
function StatefulAnimations:IsFrameBlacklisted(frameName)
	return frameName == "Duration" or frameName == "Infinite"
end


function StatefulAnimations:SetupEventDisplay(eventID)
	if not eventID then return end

	local subHandlerData, subHandlerIdentifier = self:GetSubHandler(eventID)

	EVENTS.EventHandlerFrames[eventID].EventName:SetText(eventID .. ") " .. L["SOUND_EVENT_WHILECONDITION"])

	if subHandlerData then
		local text = subHandlerData.text
		if text == NONE then
			text = "|cff808080" .. text
		end

		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["ANIM_TAB"] .. ":|r " .. text)
	else
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["ANIM_TAB"] .. ":|r UNKNOWN: " .. (subHandlerIdentifier or "?"))
	end
end

TMW:RegisterCallback("TMW_CONFIG_EVENTS_SETTINGS_SETUP_PRE", function()
	local button = TMW.IE.Events.EventSettingsContainer.IconEventWhileCondition

	button:Hide()

	local EventHandler = EVENTS:GetEventHandlerForEventSettings()

	if EventHandler == StatefulAnimations then
		button:Show()
	end



	TMW.IE.Events.EventSettingsContainerEventName:SetText("(" .. EVENTS.currentEventID .. ") " .. L["SOUND_EVENT_WHILECONDITION"])

end)

