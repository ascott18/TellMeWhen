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


TMW.Classes.GroupModule_Alpha:RegisterConfigTable("args.main.args", "Alpha", {
	name = L["UIPANEL_GROUPALPHA"],
	desc = L["UIPANEL_GROUPALPHA_DESC"],
	type = "range",
	order = 24,
	min = 0,
	max = 1,
	step = 0.01,
})
