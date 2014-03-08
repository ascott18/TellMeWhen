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

local StatefulAnimations = TMW:NewClass(nil, "EventHandler_WhileConditions", "EventHandler_AnimationsBase"):New("Animations2")

StatefulAnimations.AllEventHandlerData = EventAnimations.AllEventHandlerData
StatefulAnimations.NonSpecificEventHandlerData = EventAnimations.NonSpecificEventHandlerData


MapConditionObjectToEventSettings = {}
MapEventSettingsToAnimationTable = {}


TMW:RegisterCallback("TMW_ICON_ANIMATION_START", function(_, icon, table)
	local eventSettings = table.eventSettings

	if eventSettings.Type == StatefulAnimations.identifier then
		-- Store the event so we can stop it when the conditions fail.
		MapEventSettingsToAnimationTable[table.eventSettings] = table

		-- Modify the table to play infinitely
		table.Duration = math.huge
	end
end)


function StatefulAnimations:HandleConditionStateChange(eventSettingsList, failed)
	if not failed then
		for eventSettings, icon in pairs(eventSettingsList) do
			self:HandleEvent(icon, eventSettings)
		end
	else
		for eventSettings, icon in pairs(eventSettingsList) do
			local animationTable = MapEventSettingsToAnimationTable[eventSettings]
			if animationTable then
				animationTable.HALTED = true
				MapEventSettingsToAnimationTable[eventSettings] = nil
			end
		end
	end
end

