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


local Processor = TMW.Classes.IconDataProcessor:New("CONDITION", "conditionFailed")
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: conditionFailed
	t[#t+1] = [[
	if attributes.conditionFailed ~= conditionFailed then
		attributes.conditionFailed = conditionFailed

		TMW:Fire(CONDITION.changedEvent, icon, conditionFailed)
		doFireIconUpdated = true
	end
	--]]
end
