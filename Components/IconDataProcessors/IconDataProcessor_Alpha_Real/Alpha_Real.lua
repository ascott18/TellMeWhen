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


local Processor = TMW.Classes.IconDataProcessor:New("REALALPHA", "realAlpha")
Processor.dontInherit = true
Processor:AssertDependency("SHOWN")

TMW.Classes.Icon.attributes.realAlpha = 0

Processor:RegisterIconEvent(11, "OnShow", {
	text = L["SOUND_EVENT_ONSHOW"],
	desc = L["SOUND_EVENT_ONSHOW_DESC"],
})
Processor:RegisterIconEvent(12, "OnHide", {
	text = L["SOUND_EVENT_ONHIDE"],
	desc = L["SOUND_EVENT_ONHIDE_DESC"],
	settings = {
		OnlyShown = "FORCEDISABLED",
	},
})
Processor:RegisterIconEvent(13, "OnAlphaInc", {
	text = L["SOUND_EVENT_ONALPHAINC"],
	desc = L["SOUND_EVENT_ONALPHAINC_DESC"],
	settings = {
		Operator = true,
		Value = true,
		CndtJustPassed = true,
		PassingCndt = true,
	},
	valueName = L["ALPHA"],
	valueSuffix = "%",
	conditionChecker = function(icon, eventSettings)
		return TMW.CompareFuncs[eventSettings.Operator](icon.attributes.realAlpha * 100, eventSettings.Value)
	end,
})
Processor:RegisterIconEvent(14, "OnAlphaDec", {
	text = L["SOUND_EVENT_ONALPHADEC"],
	desc = L["SOUND_EVENT_ONALPHADEC_DESC"],
	settings = {
		Operator = true,
		Value = true,
		CndtJustPassed = true,
		PassingCndt = true,
	},
	valueName = L["ALPHA"],
	valueSuffix = "%",
	conditionChecker = function(icon, eventSettings)
		return TMW.CompareFuncs[eventSettings.Operator](icon.attributes.realAlpha * 100, eventSettings.Value)
	end,
})

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: realAlpha
	t[#t+1] = [[
	if realAlpha ~= attributes.realAlpha then
		local oldalpha = attributes.realAlpha or 0

		attributes.realAlpha = realAlpha

		-- detect events that occured, and handle them if they did
		if realAlpha == 0 then
			if EventHandlersSet.OnHide then
				icon:QueueEvent("OnHide")
			end
		elseif oldalpha == 0 then
			if EventHandlersSet.OnShow then
				icon:QueueEvent("OnShow")
			end
		elseif realAlpha > oldalpha then
			if EventHandlersSet.OnAlphaInc then
				icon:QueueEvent("OnAlphaInc")
			end
		else -- it must be less than, because it isnt greater than and it isnt the same
			if EventHandlersSet.OnAlphaDec then
				icon:QueueEvent("OnAlphaDec")
			end
		end

		TMW:Fire(REALALPHA.changedEvent, icon, realAlpha, oldalpha)
		doFireIconUpdated = true
	end
	--]]
end

Processor:RegisterDogTag("TMW", "IsShown", {	
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]

		if icon then
			local attributes = icon.attributes
			return not not attributes.shown and attributes.realAlpha > 0
		else
			return false
		end
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("SHOWN", "REALALPHA"),
	ret = "boolean",
	doc = L["DT_DOC_IsShown"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = '[IsShown] => "true"; [IsShown(icon="TMW:icon:1I7MnrXDCz8T")] => "false"',
	category = L["ICON"],
})
Processor:RegisterDogTag("TMW", "Opacity", {	
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]
		
		if icon then
			return icon.attributes.realAlpha
		else
			return 0
		end
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("REALALPHA"),
	ret = "number",
	doc = L["DT_DOC_Opacity"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = '[Opacity] => "1"; [Opacity(icon="TMW:icon:1I7MnrXDCz8T")] => "0.42"',
	category = L["ICON"],
})
