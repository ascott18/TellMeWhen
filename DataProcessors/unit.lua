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
local print = TMW.print


local Processor = TMW.Classes.IconDataProcessor:New("UNIT", "unit, GUID")
Processor.SIUVs[#Processor.SIUVs+1] = "local UnitGUID = UnitGUID"
Processor.SIUVs[#Processor.SIUVs+1] = "local playerGUID = UnitGUID('player')"

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: unit, GUID
	t[#t+1] = [[
	
	GUID = GUID or (unit and (unit == "player" and playerGUID or UnitGUID(unit)))
	
	if attributes.unit ~= unit or attributes.GUID ~= GUID then
		local previousUnit = attributes.unit
		attributes.previousUnit = previousUnit
		attributes.unit = unit
		attributes.GUID = GUID

		if EventHandlersSet.OnUnit then
			icon:QueueEvent("OnUnit")
		end
		
		TMW:Fire(UNIT.changedEvent, icon, unit, previousUnit, GUID)
		doFireIconUpdated = true
	end
	--]]
end

Processor:AddDogTag("TMW", "Unit", {
	code = function (groupID, iconID)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		if icon then
			return icon.attributes.unit or ""
		else
			return ""
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("UNIT"),
	ret = "string",
	doc = L["DT_DOC_Unit"],
	example = '[Unit] => "target"; [Unit(4, 5)] => "focus"; [Unit:Name] => "Kobold"; [Unit(4, 5):Name] => "Gamon"',
	category = L["ICON"],
})
Processor:AddDogTag("TMW", "PreviousUnit", {
	code = function (groupID, iconID)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		if icon then
			return icon.__lastUnitChecked or ""
		else
			return ""
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("UNIT"),
	ret = "string",
	doc = L["DT_DOC_PreviousUnit"],
	example = '[PreviousUnit] => "target"; [PreviousUnit(4, 5)] => "focus"; [PreviousUnit:Name] => "Kobold"; [PreviousUnit(4, 5):Name] => "Gamon"',
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, oldTypeData)
	icon:SetInfo("unit, GUID", nil, nil)
end)
