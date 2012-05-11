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


local Processor = TMW.Classes.IconDataProcessor:New("TEXTURE", "texture")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: texture
	t[#t+1] = [[
	texture = icon.OverrideTex or texture -- if a texture override is specified, then use it instead
	if texture ~= nil and attributes.texture ~= texture then
		attributes.texture = texture

		TMW:Fire(TEXTURE.changedEvent, icon, texture)
		doFireIconUpdated = true
	end
	--]]
end
