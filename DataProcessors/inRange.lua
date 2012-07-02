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


local Processor = TMW.Classes.IconDataProcessor:New("INRANGE", "inRange")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: inRange
	t[#t+1] = [[
	
	if attributes.inRange ~= inRange then
		attributes.inRange = inRange

		TMW:Fire(INRANGE.changedEvent, icon, inRange)
		doFireIconUpdated = true
	end
	--]]
end
	