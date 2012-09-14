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


local Processor = TMW.Classes.IconDataProcessor:New("INRANGE", "inRange")

-- Values:
	-- 0 - Not in range
	-- 1 - In range
	-- nil - Unknown/unspecified/unreported/unobtainable/un/un/un/unetc.
	
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: inRange
	t[#t+1] = [[
	
	if attributes.inRange ~= inRange then
		if inRange ~= nil and inRange ~= 1 and inRange ~= 0 then
			error("Icon attribute inRange must be 0, 1, or nil!", 3)
		end
		attributes.inRange = inRange

		TMW:Fire(INRANGE.changedEvent, icon, inRange)
		doFireIconUpdated = true
	end
	--]]
end

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	if not TMW.Locked then
		icon:SetInfo("inRange", nil)
	end
end)
	