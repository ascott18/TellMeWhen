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

local format = format
local isNumber = TMW.isNumber

local Processor = TMW.Classes.IconDataProcessor:New("DURATION", "start, duration")
Processor:DeclareUpValue("OnGCD", TMW.OnGCD)

TMW.Classes.Icon.attributes.start = 0
TMW.Classes.Icon.attributes.duration = 0

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: start, duration
	t[#t+1] = [[
	duration = duration or 0
	start = start or 0
	
	if duration == 0.001 then duration = 0 end -- hardcode fix for tricks of the trade. nice hardcoding on your part too, blizzard
	local d
	if start == TMW.time then
		d = duration
	else
		d = duration - (TMW.time - start)
	end
	d = d > 0 and d or 0

	if EventHandlersSet.OnDuration then
		if d ~= icon.__lastDur then
			icon:QueueEvent("OnDuration")
			icon.__lastDur = d
		end
	end

	if attributes.start ~= start or attributes.duration ~= duration then

		local realDuration = OnGCD(duration) and 0 or duration -- the duration of the cooldown, ignoring the GCD
		if icon.__realDuration ~= realDuration then
			-- detect events that occured, and handle them if they did
			if realDuration == 0 then
				if EventHandlersSet.OnFinish then
					icon:QueueEvent("OnFinish")
				end
			else
				if EventHandlersSet.OnStart then
					icon:QueueEvent("OnStart")
				end
			end
			icon.__realDuration = realDuration
		end

		attributes.start = start
		attributes.duration = duration

		TMW:Fire(DURATION.changedEvent, icon, start, duration, d)
		doFireIconUpdated = true
	end
	--]]
end

Processor:RegisterIconEvent(21, "OnStart", {
	text = L["SOUND_EVENT_ONSTART"],
	desc = L["SOUND_EVENT_ONSTART_DESC"],
})

Processor:RegisterIconEvent(22, "OnFinish", {
	text = L["SOUND_EVENT_ONFINISH"],
	desc = L["SOUND_EVENT_ONFINISH_DESC"],
})

Processor:RegisterIconEvent(23, "OnDuration", {
	text = L["SOUND_EVENT_ONDURATION"],
	desc = L["SOUND_EVENT_ONDURATION_DESC"],
	settings = {
		Operator = true,
		Value = true,
		CndtJustPassed = "FORCE",
		PassingCndt = "FORCE",
	},
	blacklistedOperators = {
		["~="] = true,
		["=="] = true,
	},
	valueName = L["DURATION"],
	conditionChecker = function(icon, eventSettings)
		local attributes = icon.attributes
		local d = attributes.duration - (TMW.time - attributes.start)
		d = d > 0 and d or 0

		return TMW.CompareFuncs[eventSettings.Operator](d, eventSettings.Value)
	end,
	applyDefaultsToSetting = function(EventSettings)
		EventSettings.CndtJustPassed = true
		EventSettings.PassingCndt = true
	end,
})


TMW:RegisterCallback("TMW_ICON_NEXTUPDATE_REQUESTDURATION", function(event, icon, currentIconDuration)
	if icon.EventHandlersSet.OnDuration then
		for _, EventSettings in TMW:InNLengthTable(icon.Events) do
			if EventSettings.Event == "OnDuration" then
				local Duration = EventSettings.Value
				if Duration < currentIconDuration and icon.NextUpdate_Duration < Duration then
					icon.NextUpdate_Duration = Duration
				end
			end
		end
	end
end)


local OnGCD = TMW.OnGCD
Processor:RegisterDogTag("TMW", "Duration", {
	code = function (groupID, iconID, gcd)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		if icon then
			local attributes = icon.attributes
			local duration = attributes.duration
			
			local remaining = duration - (TMW.time - attributes.start)
			if remaining <= 0 or (not gcd and OnGCD(duration)) then
				return 0
			end

			-- cached version of tonumber()
			return isNumber[format("%.1f", remaining)] or 0
		else
			return 0
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
		'gcd', 'boolean', true,
	},
	events = "FastUpdate",
	ret = "number",
	doc = L["DT_DOC_Duration"],
	example = '[Duration] => "1.435"; [Duration(gcd=false)] => "0"; [Duration:TMWFormatDuration] => "1.4"; [Duration(4, 5)] => "97.32156"; [Duration(4, 5):TMWFormatDuration] => "1:37"',
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	icon.__realDuration = icon.__realDuration or 0
	if not TMW.Locked then
		icon:SetInfo("start, duration", 0, 0)
	end
end)
