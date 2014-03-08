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

local huge = math.huge
local next, pairs, ipairs, type, assert, tinsert, sort =
	  next, pairs, ipairs, type, assert, tinsert, sort
local random, floor =
	  random, floor
local InCombatLockdown =
	  InCombatLockdown
	  
-- GLOBALS: UIParent, CreateFrame

local EventAnimations = TMW.Classes.EventHandler.instancesByName.Animations

local StatefulAnimations = TMW.Classes.EventHandler_AnimationsBase:New("Animations2")
StatefulAnimations.isTriggeredByEvents = false

StatefulAnimations.AllEventHandlerData = EventAnimations.AllEventHandlerData
StatefulAnimations.NonSpecificEventHandlerData = EventAnimations.NonSpecificEventHandlerData


MapConditionObjectToEventSettings = {}
MapEventSettingsToAnimationTable = {}




local function TMW_CNDT_OBJ_PASSING_CHANGED(_, ConditionObject, failed)
	local matches = MapConditionObjectToEventSettings[ConditionObject]
	
	if TMW.Locked and matches then
		if not failed then
			for eventSettings, icon in pairs(matches) do
				self:HandleEvent(icon, eventSettings)
			end
		else
			for eventSettings, icon in pairs(matches) do
				local animationTable = MapEventSettingsToAnimationTable[eventSettings]
				if animationTable then
					animationTable.HALTED = true
					MapEventSettingsToAnimationTable[eventSettings] = nil
				end
			end
		end
	end
end


TMW:RegisterCallback("TMW_ICON_ANIMATION_START", function(_, icon, table)
	local eventSettings = table.eventSettings

	if eventSettings.Type == StatefulAnimations.identifier then
		-- Store the event so we can stop it when the conditions fail.
		MapEventSettingsToAnimationTable[table.eventSettings] = table

		-- Modify the table to play infinitely
		table.Duration = math.huge
	end
end)

TMW:RegisterCallback("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", function(_, icon, iconEvent, eventSettings)

	local ConditionObjectConstructor = icon:Conditions_GetConstructor(eventSettings.OnConditionConditions)
	local ConditionObject = ConditionObjectConstructor:Construct()

	if ConditionObject then
		ConditionObject:RequestAutoUpdates(eventSettings, true)
		
		local matches = MapConditionObjectToEventSettings[ConditionObject]
		if not matches then
			matches = {}
			MapConditionObjectToEventSettings[ConditionObject] = matches
		end
		matches[eventSettings] = icon
		
		TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", TMW_CNDT_OBJ_PASSING_CHANGED)

		-- Do this right now so the animation is always up-to-date with the state
		TMW_CNDT_OBJ_PASSING_CHANGED(nil, ConditionObject, ConditionObject.Failed)
	end
end)

TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon, soft)
	for ConditionObject, matches in pairs(MapConditionObjectToEventSettings) do
		for eventSettings, ic in pairs(matches) do
			if ic == icon then
				ConditionObject:RequestAutoUpdates(eventSettings, false)
				matches[eventSettings] = nil
			end
		end
	end
end)




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





