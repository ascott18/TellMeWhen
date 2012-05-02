-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L

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

Processor:AddDogTag("TMW", "Stacks", {
	code = function (groupID, iconID)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		return icon and tostring(icon.attributes.stackText or 0) or "0"
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("STACK"),
	ret = "string",
	doc = "Returns the current stacks of the icon",
	example = '[Stacks] => "9"; [Stacks(4, 5)] => "3"',
	category = "Icon"
})

TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function(event, icon)
	if not TMW.Locked then
		icon:SetInfo("stack, stackText", nil, nil)
	end
end)
