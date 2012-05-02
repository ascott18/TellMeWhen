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


local Processor = TMW.Classes.IconDataProcessor:New("COLOR", "color")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: color
	t[#t+1] = [[
	
	if attributes.color ~= color then
		attributes.color = color

		TMW:Fire(COLOR.changedEvent, icon, color)
		doFireIconUpdated = true
	end
	--]]
end

TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function(event, icon)
	if not TMW.Locked then
		icon:SetInfo("color", 1)
	end
end)
	