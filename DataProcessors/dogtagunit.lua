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

local DogTag = LibStub("LibDogTag-3.0", true)

	
local Processor = TMW.Classes.IconDataProcessor:New("DOGTAGUNIT", "dogTagUnit")
Processor:AssertDependency("UNIT")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: dogTagUnit
	t[#t+1] = [[
	if attributes.dogTagUnit ~= dogTagUnit then
		attributes.dogTagUnit = dogTagUnit

		TMW:Fire(CONDITION.changedEvent, icon, dogTagUnit)
		doFireIconUpdated = true
	end
	--]]
end

TMW:RegisterCallback("TMW_ICON_DATA_CHANGED_UNIT", function(event, icon, unit)
	if icon.typeData.unitType == "unitid" then
		if not DogTag.IsLegitimateUnit[unit] then
			unit = unit and TMW.UNITS:TestUnit(unit)
			if not DogTag.IsLegitimateUnit[unit] then
				unit = "player"
			end
		end
	else
		unit = "player"
	end
	icon:SetInfo("dogTagUnit", unit)
end)
	