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


local Processor = TMW.Classes.IconDataProcessor:New("PRESUSABLE", "presentOrUsable")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: presentOrUsable
	t[#t+1] = [[
	
	if attributes.presentOrUsable ~= presentOrUsable then
		attributes.presentOrUsable = presentOrUsable		
		
		TMW:Fire(PRESUSABLE.changedEvent, icon, presentOrUsable)
		doFireIconUpdated = true
	end
	--]]
end
	