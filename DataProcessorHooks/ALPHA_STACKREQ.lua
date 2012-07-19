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


local Hook = TMW.Classes.IconDataProcessorHook:New("ALPHA_STACKREQ", "ALPHA")
Hook:RegisterProcessorRequirement("STACK")
Hook:RegisterCompileFunctionSegmentHook("pre", function(Processor, t)
	-- GLOBALS: alpha, stack
	t[#t+1] = [[
	local stack = stack or attributes.stack
	if
		stack and ((icon.StackMinEnabled and icon.StackMin > stack) or (icon.StackMaxEnabled and stack > icon.StackMax))
	then
		alpha = alpha ~= 0 and icon.StackAlpha or 0 -- use the alpha setting for failed stacks/duration/conditions, but only if the icon isnt being hidden for another reason
	end
	--]]
end)
Hook:RegisterIconDefaults{
	StackMin				= 0,
	StackMax				= 0,
	StackMinEnabled			= false,
	StackMaxEnabled			= false,
	StackAlpha				= 0,
}
Hook:RegisterConfigPanel_XMLTemplate("column", 3, "TellMeWhen_StackRequirements")
Hook:RegisterUpgrade(40080, {
	icon = function(self, ics)
		ics.StackMin = floor(ics.StackMin)
		ics.StackMax = floor(ics.StackMax)
	end,
})
Hook:RegisterUpgrade(23000, {
	icon = function(self, ics)
		if ics.StackMin ~= TMW.Icon_Defaults.StackMin then
			ics.StackMinEnabled = true
		end
		if ics.StackMax ~= TMW.Icon_Defaults.StackMax then
			ics.StackMaxEnabled = true
		end
	end,
})
Hook:RegisterUpgrade(60010, {
	icon = function(self, ics)
		ics.StackAlpha = ics.ConditionAlpha
	end,
})