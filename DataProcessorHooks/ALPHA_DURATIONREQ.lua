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

local Hook = TMW.Classes.IconDataProcessorHook:New("ALPHA_DURATIONREQ", "ALPHA")
Hook:RegisterProcessorRequirement("DURATION")
Hook:RegisterCompileFunctionSegmentHook("pre", function(Processor, t)
	-- GLOBALS: alpha, start, duration
	t[#t+1] = [[

	local d = (duration or attributes.duration or 0) - (TMW.time - (start or attributes.start or 0))
	
	if
		d > 0 and ((icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax))
	then
		alpha = alpha ~= 0 and icon.DurationAlpha or 0 -- use the alpha setting for failed duration, but only if the icon isnt being hidden for another reason
	end
	--]]
end)
Hook:RegisterIconDefaults{
	DurationMin				= 0,
	DurationMax				= 0,
	DurationMinEnabled		= false,
	DurationMaxEnabled		= false,
	DurationAlpha			= 0,
}
Hook:RegisterConfigPanel_XMLTemplate("column", 3, "TellMeWhen_DurationRequirements")

TMW:RegisterCallback("TMW_ICON_NEXTUPDATE_REQUESTDURATION", function(event, icon, currentIconDuration)
	local attributes = icon.attributes
	if icon.DurationMaxEnabled then
		local DurationMax = icon.DurationMax
		if DurationMax < currentIconDuration then
			icon.NextUpdate_Duration = DurationMax
		end
	end
	if icon.DurationMinEnabled then
		local DurationMin = icon.DurationMin
		if DurationMin < currentIconDuration and icon.NextUpdate_Duration < DurationMin then
			icon.NextUpdate_Duration = DurationMin
		end
	end
end)

Hook:RegisterUpgrade(60010, {
	icon = function(self, ics)
		ics.DurationAlpha = ics.ConditionAlpha
	end,
})

