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



local Hook = TMW.Classes.IconDataProcessorHook:New("TEXTURE_CUSTOMTEX", "TEXTURE")

Hook:RegisterIconDefaults{
	CustomTex				= "",
}

Hook:RegisterConfigPanel_XMLTemplate(190, "TellMeWhen_CustomTex")

Hook:RegisterCompileFunctionSegmentHook("pre", function(Processor, t)
	-- GLOBALS: texture
	t[#t+1] = [[
	texture = icon.OverrideTex or texture -- if a texture override is specified, then use it instead
	--]]
end)

function Hook:OnImplementIntoIcon(icon)
	icon.OverrideTex = TMW:GetTexturePathFromSetting(icon.CustomTex)
end
