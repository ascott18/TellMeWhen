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


local Processor = TMW.Classes.IconDataProcessor:New("REVERSE", "reverse")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: reverse
	t[#t+1] = [[
	if attributes.reverse ~= reverse then
		
		TMW:Fire(REVERSE.changedEvent, icon, reverse)
		doFireIconUpdated = true

		attributes.reverse = reverse
	end
	--]]
end

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, oldTypeData)
	icon:SetInfo("reverse", nil)
end)
	