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

local isNumber = TMW.isNumber

local tostring = tostring


local Processor = TMW.Classes.IconDataProcessor:New("STACK", "stack, stackText")

function Processor:CompileFunctionSegment(t)
	--GLOBALS: stack, stackText
	t[#t+1] = [[
	if attributes.stack ~= stack or attributes.stackText ~= stackText then
		attributes.stack = stack
		attributes.stackText = stackText

		if EventHandlersSet.OnStack then
			icon:QueueEvent("OnStack")
		end

		TMW:Fire(STACK.changedEvent, icon, stack, stackText)
		doFireIconUpdated = true
	end
	--]]
end

Processor:RegisterIconEvent(51, "OnStack", {
	text = L["SOUND_EVENT_ONSTACK"],
	desc = L["SOUND_EVENT_ONSTACK_DESC"],
	settings = {
		Operator = true,
		Value = true,
		CndtJustPassed = true,
		PassingCndt = true,
	},
	valueName = L["STACKS"],
	conditionChecker = function(icon, eventSettings)
		local count = icon.attributes.stack
		return count and TMW.CompareFuncs[eventSettings.Operator](count, eventSettings.Value)
	end,
})
	
Processor:RegisterDogTag("TMW", "Stacks", {
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]
		
		local stacks = icon and icon.attributes.stackText or 0
		
		return isNumber[stacks] or stacks
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("STACK"),
	ret = "number",
	doc = L["DT_DOC_Stacks"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = '[Stacks] => "9"; [Stacks(icon="TMW:icon:1I7MnrXDCz8T")] => "3"',
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	if not TMW.Locked then
		icon:SetInfo("stack, stackText", nil, nil)
	end
end)

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, oldTypeData)
	icon:SetInfo("stack, stackText", nil, nil)
end)
