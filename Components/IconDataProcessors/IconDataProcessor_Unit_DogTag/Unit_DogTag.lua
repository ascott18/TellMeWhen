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

local DogTag = LibStub("LibDogTag-3.0", true)

-- The way that this processor works is really sleezy.
-- Basically, we create a processor just to reserve an attribute name and event and all that fun stuff,
-- and so that we have an event that can be listened to by an IconModule.
	
local Processor = TMW.Classes.IconDataProcessor:New("DOGTAGUNIT", "dogTagUnit")
Processor:AssertDependency("UNIT")


--Here's the hook (the real crux of the whole thing)

local Hook = TMW.Classes.IconDataProcessorHook:New("UNIT_DOGTAGUNIT", "UNIT")

Hook:DeclareUpValue("DogTag", DogTag)
Hook:DeclareUpValue("TMW_UNITS", TMW.UNITS)

Hook:RegisterCompileFunctionSegmentHook("post", function(Processor, t)
	-- GLOBALS: unit
	t[#t+1] = [[
	local dogTagUnit
	
	if icon.typeData.unitType == "unitid" then
		dogTagUnit = unit
		if not DogTag.IsLegitimateUnit[dogTagUnit] then
			dogTagUnit = dogTagUnit and TMW_UNITS:TestUnit(dogTagUnit)
			if not DogTag.IsLegitimateUnit[dogTagUnit] then
				dogTagUnit = ""
			end
		end
	else
		dogTagUnit = ""
	end
	
	if attributes.dogTagUnit ~= dogTagUnit then
		doFireIconUpdated = icon:SetInfo_INTERNAL("dogTagUnit", dogTagUnit) or doFireIconUpdate
	end
	--]]
end)

	