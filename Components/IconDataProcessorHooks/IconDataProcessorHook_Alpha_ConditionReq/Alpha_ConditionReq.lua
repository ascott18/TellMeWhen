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




local Hook = TMW.Classes.IconDataProcessorHook:New("ALPHA_CONDITIONREQ", "CONDITION")

Hook:RegisterIconDefaults{
	ConditionAlpha			= 0, --TODO: ConditionAlpha has no config panel. Make one and register it to this hook.
}
Hook:RegisterRapidSetting("ConditionAlpha")

Hook:RegisterConfigPanel_XMLTemplate(229, "TellMeWhen_ConditionRequirements")


local Processor = TMW.Classes.IconDataProcessor:New("ALPHA_CONDITIONFAILED", "alpha_conditionFailed")
Processor.dontInherit = true
TMW.IconAlphaManager:AddHandler(10, "ALPHA_CONDITIONFAILED")

-- This IconDataProcessorHook does not RegisterCompileFunctionSegmentHook(). 
-- Since it only really matters when conditionFailed changes, we listen to CONDITION's changedEvent,
-- and call SetInfo_INTERNAL to set alpha_conditionFailed as needed.
TMW:RegisterCallback(TMW.ProcessorsByName.CONDITION.changedEvent, function(event, icon, conditionFailed)
	if conditionFailed then
		icon:SetInfo_INTERNAL("alpha_conditionFailed", icon.ConditionAlpha)
	else
		icon:SetInfo_INTERNAL("alpha_conditionFailed", nil)
	end
end)


Hook:ExtendMethod("OnImplementIntoIcon", function(self, icon)
	if icon.attributes.conditionFailed then
		icon:SetInfo("alpha_conditionFailed", icon.ConditionAlpha)
	else
		icon:SetInfo("alpha_conditionFailed", nil)
	end
end)

Hook:ExtendMethod("OnUnimplementFromIcon", function(self, icon)
	icon:SetInfo("alpha_conditionFailed", nil)
end)

TMW:RegisterUpgrade(41005, {
	icon = function(self, ics)
		ics.ConditionAlpha = 0
	end,
})

