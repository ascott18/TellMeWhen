-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print
local IE = TMW.IE
local CI = TMW.CI




local TabGroup = IE:RegisterTabGroup("MAIN", TMW.L["MAIN"], 3, function(tabGroup)
	local titlePrepend = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL

	IE.Header:SetText(titlePrepend)
end)



local MainTab = IE:RegisterTab("MAIN", "CHANGELOG", "Changelog", 100)
MainTab:SetTexts(L["CHANGELOG"], L["CHANGELOG_DESC"])