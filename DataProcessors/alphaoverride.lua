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


local Processor = TMW.Classes.IconDataProcessor:New("ALPHAOVERRIDE", "alphaOverride")
Processor.dontInherit = true
Processor:AssertDependency("ALPHA")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: alphaOverride
	t[#t+1] = [[
	if alphaOverride ~= attributes.alphaOverride then
	
		attributes.alphaOverride = alphaOverride
		attributes.actualAlphaAtLastChange = icon:GetAlpha()

		TMW:Fire(ALPHAOVERRIDE.changedEvent, icon, alphaOverride)
		doFireIconUpdated = true
	end
	--]]
end
	