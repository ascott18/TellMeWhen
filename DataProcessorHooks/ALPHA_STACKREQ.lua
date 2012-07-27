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


-- Create an IconDataProcessor that will store the result of the stack test
TMW.Classes.IconDataProcessor:New("ALPHA_STACKSFAILED", "alpha_stackFailed")
TMW.IconAlphaManager:AddHandler(30, "ALPHA_STACKSFAILED")

local Hook = TMW.Classes.IconDataProcessorHook:New("ALPHA_STACKREQ", "STACK")

Hook:RegisterCompileFunctionSegmentHook("post", function(Processor, t)
	-- GLOBALS: stack
	t[#t+1] = [[
	
	local alpha_stackFailed = nil
	if
		stack and ((icon.StackMinEnabled and icon.StackMin > stack) or (icon.StackMaxEnabled and stack > icon.StackMax))
	then
		alpha_stackFailed = icon.StackAlpha
	end
	
	if attributes.alpha_stackFailed ~= alpha_stackFailed then
		icon:SetInfo_INTERNAL("alpha_stackFailed", alpha_stackFailed)
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
Hook:RegisterConfigPanel_XMLTemplate(225, "TellMeWhen_StackRequirements")
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