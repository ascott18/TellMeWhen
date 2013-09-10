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

-- Create an IconDataProcessor that will store the result of the duration test
TMW.Classes.IconDataProcessor:New("ALPHA_DURATIONFAILED", "alpha_durationFailed")
TMW.IconAlphaManager:AddHandler(20, "ALPHA_DURATIONFAILED")

local Hook = TMW.Classes.IconDataProcessorHook:New("ALPHA_DURATIONREQ", "DURATION")

Hook:RegisterIconDefaults{
	DurationMin				= 0,
	DurationMax				= 0,
	DurationMinEnabled		= false,
	DurationMaxEnabled		= false,
	DurationAlpha			= 0,
}
Hook:RegisterConfigPanel_XMLTemplate(222, "TellMeWhen_DurationRequirements")


Hook:RegisterCompileFunctionSegmentHook("post", function(Processor, t)
	-- GLOBALS: start, duration
	t[#t+1] = [[

	local d = duration - (TMW.time - start)
	
	local alpha_durationFailed = nil
	if
		d > 0 and ((icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax))
	then
		alpha_durationFailed = icon.DurationAlpha
	end
	
	if attributes.alpha_durationFailed ~= alpha_durationFailed then
		icon:SetInfo_INTERNAL("alpha_durationFailed", alpha_durationFailed)
		doFireIconUpdated = true
	end
	--]]
end)

Hook:ExtendMethod("OnUnimplementFromIcon", function(self, icon)
	icon:SetInfo("alpha_durationFailed", nil)
end)


TMW:RegisterCallback("TMW_ICON_NEXTUPDATE_REQUESTDURATION", function(event, icon, currentIconDuration)
	if icon.DurationMaxEnabled then
		local DurationMax = icon.DurationMax
		if DurationMax < currentIconDuration and icon.NextUpdate_Duration < DurationMax  then
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

TMW:RegisterUpgrade(60010, {
	icon = function(self, ics)
		ics.DurationAlpha = ics.ConditionAlpha

		ics.DurationMin = tonumber(ics.DurationMin) or 0
		ics.DurationMax = tonumber(ics.DurationMax) or 0
	end,
})

