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


local Processor = TMW.Classes.IconDataProcessor:New("ALPHA", "alpha")
Processor:AssertDependency("DURATION")
Processor:AssertDependency("STACK")
Processor:AssertDependency("SHOWN")

Processor:RegisterIconEvent{	-- OnShow
	name = "OnShow",
	text = L["SOUND_EVENT_ONSHOW"],
	desc = L["SOUND_EVENT_ONSHOW_DESC"],
}
Processor:RegisterIconEvent{	-- OnHide
	name = "OnHide",
	text = L["SOUND_EVENT_ONHIDE"],
	desc = L["SOUND_EVENT_ONHIDE_DESC"],
	settings = {
		OnlyShown = "FORCEDISABLED",
	},
}
Processor:RegisterIconEvent{	-- OnAlphaInc
	name = "OnAlphaInc",
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
		return TMW.CompareFuncs[eventSettings.Operator](icon.attributes.alpha * 100, eventSettings.Value)
	end,
}
Processor:RegisterIconEvent{	-- OnAlphaDec
	name = "OnAlphaDec",
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
		return TMW.CompareFuncs[eventSettings.Operator](icon.attributes.alpha * 100, eventSettings.Value)
	end,
}
	
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: alpha
	t[#t+1] = [[
	alpha = alpha or 0
	
	if alpha ~= attributes.alpha then
		local oldalpha = attributes.alpha

		attributes.alpha = alpha
		
		-- For ICONFADE. much nicer than using __alpha because it will transition from what is curently visible,
		-- not what should be visible after any current fades end
		-- TODO: maybe do this differently? 
		-- TODO: (misplaced note) more closely assocate icon events with data processors
		-- TODO: (misplaced note) more closely assocate icon animaions with data processors
		attributes.actualAlphaAtLastChange = icon:GetAlpha()

		-- detect events that occured, and handle them if they did
		if alpha == 0 then
			if EventHandlersSet.OnHide then
				icon:QueueEvent("OnHide")
			end
		elseif oldalpha == 0 then
			if EventHandlersSet.OnShow then
				icon:QueueEvent("OnShow")
			end
		elseif alpha > oldalpha then
			if EventHandlersSet.OnAlphaInc then
				icon:QueueEvent("OnAlphaInc")
			end
		else -- it must be less than, because it isnt greater than and it isnt the same
			if EventHandlersSet.OnAlphaDec then
				icon:QueueEvent("OnAlphaDec")
			end
		end

		TMW:Fire(ALPHA.changedEvent, icon, alpha, oldalpha)
		doFireIconUpdated = true
	end
	--]]
end

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	if not TMW.Locked then
		icon:SetInfo("alpha", 0)
	end
end)

Processor:RegisterDogTag("TMW", "IsShown", {	
	code = function (groupID, iconID, link)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		if icon then
			local attributes = icon.attributes
			return not not attributes.shown and attributes.alpha > 0
		else
			return false
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("SHOWN", "ALPHA"),
	ret = "boolean",
	doc = L["DT_DOC_IsShown"],
	example = '[IsShown] => "true"; [IsShown(icon=3, group=2)] => "false"',
	category = L["ICON"],
})
Processor:RegisterDogTag("TMW", "Opacity", {	
	code = function (groupID, iconID, link)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		if icon then
			return icon.attributes.alpha
		else
			return 0
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("ALPHA"),
	ret = "boolean",
	doc = L["DT_DOC_Opacity"],
	example = '[IsShown] => "true"; [IsShown(icon=3, group=2)] => "false"',
	category = L["ICON"],
})


