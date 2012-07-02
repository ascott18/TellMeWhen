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


local Processor = TMW.Classes.IconDataProcessor:New("NOMANA", "noMana")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: noMana
	t[#t+1] = [[
	
	if attributes.noMana ~= noMana then
		attributes.noMana = noMana

		TMW:Fire(NOMANA.changedEvent, icon, noMana)
		doFireIconUpdated = true
	end
	--]]
end
	