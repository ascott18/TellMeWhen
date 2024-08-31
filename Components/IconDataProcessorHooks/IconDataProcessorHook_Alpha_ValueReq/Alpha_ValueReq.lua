-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print


TMW.CONST.STATE.DEFAULT_VALUEFAILED = 102
local STATE = TMW.CONST.STATE.DEFAULT_VALUEFAILED

local floor = floor

local Hook = TMW.Classes.IconDataProcessorHook:New("STATE_VALUEREQ", "VALUE")

Hook:RegisterConfigPanel_XMLTemplate(225, "TellMeWhen_ValueRequirements")

Hook:RegisterIconDefaults{
	ValueMin				= 0,
	ValueMax				= 0,
	ValueMinEnabled			= false,
	ValueMaxEnabled			= false,
}

-- Create an IconDataProcessor that will store the result of the value test
local Processor = TMW.Classes.IconDataProcessor:New("STATE_VALUEFAILED", "state_valueFailed")
Processor.dontInherit = true
Processor:RegisterAsStateArbitrator(30, Hook, false, function(icon)
	local ics = icon:GetSettings()
	if not ics.ValueMinEnabled and not ics.ValueMaxEnabled then
		return nil
	end

	local text = ""
	if ics.ValueMinEnabled then
		text = L["VALUE"] .. " < " .. ics.ValueMin
	end
	if ics.ValueMaxEnabled then
		if ics.ValueMinEnabled then
			text = text .. " " .. L["CONDITIONPANEL_OR"]:lower() .. " "
		end
		text = text .. L["VALUE"] .. " > " .. ics.ValueMax
	end
	
	return {
		[STATE] = { text = text, tooltipText = L["VALUEALPHA_DESC"]},
	}
end)

Hook:DeclareUpValue("STATE_DEFAULT_VALUEFAILED",  STATE)
Hook:RegisterCompileFunctionSegmentHook("post", function(Processor, t)
	-- GLOBALS: value
	t[#t+1] = [[
	-- Only run if doFireIconUpdated is set. We use it to detect if `value` might have changed.
	-- If `value` didn't change, we definitely don't need to run this.
	if doFireIconUpdated then
		local state_valueFailed = nil
		if
			value and ((icon.ValueMinEnabled and icon.ValueMin > value) or (icon.ValueMaxEnabled and value > icon.ValueMax))
		then
			state_valueFailed = icon.States[STATE_DEFAULT_VALUEFAILED]
		end
		
		if attributes.state_valueFailed ~= state_valueFailed then
			icon:SetInfo_INTERNAL("state_valueFailed", state_valueFailed)
			doFireIconUpdated = true
		end
	end
	--]]
end)