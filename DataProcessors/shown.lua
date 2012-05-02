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


local Processor = TMW.Classes.IconDataProcessor:New("SHOWN", "shown")
Processor.dontInherit = true

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: shown
	t[#t+1] = [[
	if attributes.shown ~= shown then
		
		TMW:Fire(SHOWN.changedEvent, icon, shown)
		doFireIconUpdated = true

		attributes.shown = shown
	end
	--]]
end
