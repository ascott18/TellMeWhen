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

local FindGroupFromInfo = TMW.FindGroupFromInfo


TMW.Classes.GroupModule_IconPosition:RegisterConfigTable("args.main.args", "SpacingX", {
	name = L["UIPANEL_ICONSPACINGX"],
	desc = L["UIPANEL_ICONSPACING_DESC"],
	type = "range",
	order = 22,
	softMin = -5,
	softMax = 20,
	step = 0.1,
	bigStep = 1,
	set = "group_set_spv",
	get = "group_get_spv",
})
TMW.Classes.GroupModule_IconPosition:RegisterConfigTable("args.main.args", "SpacingY", {
	name = L["UIPANEL_ICONSPACINGY"],
	desc = L["UIPANEL_ICONSPACING_DESC"],
	type = "range",
	order = 23,
	softMin = -5,
	softMax = 20,
	step = 0.1,
	bigStep = 1,
	set = "group_set_spv",
	get = "group_get_spv",
})
