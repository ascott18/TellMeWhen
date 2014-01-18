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

local format = format
local isNumber = TMW.isNumber

local Processor = TMW.Classes.IconDataProcessor:New("DURATION", "start, duration")
Processor:DeclareUpValue("OnGCD", TMW.OnGCD)

TMW.Classes.Icon.attributes.start = 0
TMW.Classes.Icon.attributes.duration = 0

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

		local realDuration = icon.typeData:OnGCD(duration) and 0 or duration -- the duration of the cooldown, ignoring the GCD
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


function Processor:OnImplementIntoIcon(icon)
	if icon.EventHandlersSet.OnDuration then
		for _, EventSettings in TMW:InNLengthTable(icon.Events) do
			if EventSettings.Event == "OnDuration" then
				self:RegisterDurationTrigger(icon, EventSettings.Value)
			end
		end
	end
end





---------------------------------
-- Duration triggers
---------------------------------

-- Duration triggers. Register a duration trigger to cause a call to
-- icon:SetInfo("start, duration", icon.attributes.start, icon.attributes.duration)
-- when the icon reaches the specified duration.
local DurationTriggers = {}
Processor.DurationTriggers = DurationTriggers
function Processor:RegisterDurationTrigger(icon, duration)
	if not DurationTriggers[icon] then
		DurationTriggers[icon] = {}
	end

	if not TMW.tContains(DurationTriggers[icon], duration) then
		tinsert(DurationTriggers[icon], duration)
	end
end

function Processor:OnUnimplementFromIcon(icon)
	if DurationTriggers[icon] then
		wipe(DurationTriggers[icon])
	end
end

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", function(event, time, Locked)
	for icon, durations in pairs(DurationTriggers) do
		if #durations > 0 then
			local lastCheckedDuration = durations.last or 0

			local currentIconDuration = icon.attributes.duration - (time - icon.attributes.start)
			if currentIconDuration < 0 then currentIconDuration = 0 end
			
			-- If the duration didn't change (i.e. it is 0) then don't even try.
			if currentIconDuration == lastCheckedDuration then
				break
			end

			for i = 1, #durations do
				local durationToCheck = durations[i]
				if currentIconDuration <= durationToCheck and -- Make sure we are at or have passed the duration we want to trigger at
					(lastCheckedDuration > durationToCheck -- Make sure that we just reached this duration (so it doesn't continually fire)
					or lastCheckedDuration < currentIconDuration -- or make sure that the duration increased since the last time we checked the triggers.
				) then
					icon:SetInfo("start, duration", icon.attributes.start, icon.attributes.duration)
					break
				end
			end
			durations.last = currentIconDuration
		end
	end
end)






local OnGCD = TMW.OnGCD
Processor:RegisterDogTag("TMW", "Duration", {
	code = function(icon, gcd)
		icon = TMW.GUIDToOwner[icon]

		if icon then
			local attributes = icon.attributes
			local duration = attributes.duration
			
			local remaining = duration - (TMW.time - attributes.start)
			if remaining <= 0 or (not gcd and icon.typeData:OnGCD(duration)) then
				return 0
			end

			-- cached version of tonumber()
			return isNumber[format("%.1f", remaining)] or 0
		else
			return 0
		end
	end,
	arg = {
		'icon', 'string', '@req',
		'gcd', 'boolean', true,
	},
	events = "FastUpdate",
	ret = "number",
	doc = L["DT_DOC_Duration"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = '[Duration] => "1.435"; [Duration(gcd=false)] => "0"; [Duration:TMWFormatDuration] => "1.4"; [Duration(icon="TMW:icon:1I7MnrXDCz8T")] => "97.32156"; [Duration(icon="TMW:icon:1I7MnrXDCz8T"):TMWFormatDuration] => "1:37"',
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	if not TMW.Locked then
		icon:SetInfo("start, duration", 0, 0)
	end
end)
