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

local Hook = TMW.Classes.IconDataProcessorHook:New("ALPHA_CONDITIONREQ", "ALPHA")
Hook:RegisterProcessorRequirement("CONDITION")

Hook:RegisterIconDefaults{
	ConditionAlpha			= 0,
}
Hook:RegisterRapidSetting("ConditionAlpha")

Hook:RegisterCompileFunctionSegmentHook("pre", function(Processor, t)
	-- GLOBALS: alpha, conditionFailed
	t[#t+1] = [[
	
	-- We need a new variable name to prevent conflicts (which is what cndts_failed is)
	
	-- First, try to get it from the function call (it may also be getting set right now)
	local cndts_failed = conditionFailed
	-- If we didn't get it just now, then get the stored value from attributes
	if cndts_failed == nil then
		cndts_failed = attributes.conditionFailed
	end
	
	if
		cndts_failed and not icon.dontHandleConditionsExternally
	then
		 -- use the alpha setting for failed conditions, but only if the icon isnt being hidden for another reason
		alpha = alpha ~= 0 and icon.ConditionAlpha or 0
	end
	--]]
end)

Hook:RegisterUpgrade(41005, {
	icon = function(self, ics)
		ics.ConditionAlpha = 0
	end,
})

