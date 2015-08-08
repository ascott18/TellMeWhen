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

local floor, min, max, strsub, strfind = 
	  floor, min, max, strsub, strfind
local pairs, ipairs, sort, tremove, CopyTable = 
	  pairs, ipairs, sort, tremove, CopyTable
	  
local CI = TMW.CI

-- GLOBALS: CreateFrame, NONE, NORMAL_FONT_COLOR



local EVENTS = TMW.EVENTS
local Timer = EVENTS:GetEventHandler("Timer")

Timer.handlerName = L["EVENTHANDLER_TIMER_TAB"]
Timer.handlerDesc = L["EVENTHANDLER_TIMER_TAB_DESC"]
--Timer.testable = false

local operations = {
	{ text = L["OPERATION_TRESET"], 	tooltip = L["OPERATION_TRESET_DESC"], 	 value = "reset"	},
	{ text = L["OPERATION_TSTART"], 	tooltip = L["OPERATION_TSTART_DESC"], 	 value = "start"	},
	{ text = L["OPERATION_TRESTART"],	tooltip = L["OPERATION_TRESTART_DESC"],	 value = "restart"	},
	{ text = L["OPERATION_TPAUSE"], 	tooltip = L["OPERATION_TPAUSE_DESC"], 	 value = "pause"	},
	{ text = L["OPERATION_TSTOP"], 		tooltip = L["OPERATION_TSTOP_DESC"], 	 value = "stop"		},
}


---------- Events ----------
function Timer:LoadSettingsForEventID(eventID)
	local eventSettings = EVENTS:GetEventSettings(eventID)

	self.ConfigContainer.Operation:SetUIDropdownText(eventSettings.TimerOperation, operations)
	
	self.ConfigContainer.Header:SetText(TMW.L["EVENTS_SETTINGS_TIMER_HEADER"])

	self.ConfigContainer.Counter:SetText(eventSettings.Counter)
end

function Timer:SetupEventDisplay(eventID)
	if not eventID then return end

	local eventSettings = EVENTS:GetEventSettings(eventID)


	local Counter = eventSettings.Counter
	local TimerOperation = eventSettings.TimerOperation
	local opText = TimerOperation
	for k, v in pairs(operations) do
		if v.value == TimerOperation then
			opText = v.text
			break
		end
	end

	local str = opText .. " "
	if Counter == "" then
		str = str .. "|cff808080<No Timer>"
	else
		str = str .. Counter
	end
	
	-- TODO: all of these methods (SetupEventDisplay) should return these values, not set them directly.
	EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["EVENTHANDLER_TIMER_TAB"] .. ":|r " .. str)
end


function Timer:OperationMenu_DropDown()
	for k, v in pairs(operations) do
		local info = TMW.DD:CreateInfo()
		info.func = Timer.OperationMenu_DropDown_OnClick
		info.text = v.text
		info.tooltipTitle = v.text
		info.tooltipText = v.tooltip
		info.checked = v.value == EVENTS:GetEventSettings().TimerOperation
		info.value = v.value
		info.arg1 = self
		TMW.DD:AddButton(info)
	end
end

function Timer:OperationMenu_DropDown_OnClick(frame)
	frame:SetUIDropdownText(self.value, operations)
	
	local eventSettings = EVENTS:GetEventSettings()
	eventSettings.TimerOperation = self.value

	TMW.EVENTS:LoadConfig()
end




local SUG = TMW.SUG
local Module = SUG:NewModule("timerName", SUG:GetModule("counterName")) -- EWWW DEPENDENCIES
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local lastName = SUG.lastName


	for eventSettings in EVENTS:InIconEventSettings() do
		if eventSettings.Type == "Timer"
			and eventSettings.Counter ~= ""
			and strfind(eventSettings.Counter, lastName)
			and not TMW.tContains(suggestions, eventSettings.Counter)
		then
			suggestions[#suggestions + 1] = eventSettings.Counter
		end
	end
end