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

local findid = TMW.FindGroupIDFromInfo



local set = function(info, val)
	local g = findid(info)
	
	local gs = TMW.db.profile.Groups[g]
	gs.SettingsPerView[gs.View][info[#info]] = val
	
	local Module = TMW[g]:GetModuleOrModuleChild("GroupModule_IconPosition")
	
	if Module then
		Module:PositionIcons()
	end
end
local get = function(info)
	local g = findid(info)
	local gs = TMW.db.profile.Groups[g]
	return gs.SettingsPerView[gs.View][info[#info]]
end

TMW.Classes.GroupModule_IconPosition:RegisterConfigTable("args.main.args", "SpacingX", {
	name = L["UIPANEL_ICONSPACINGX"],
	desc = L["UIPANEL_ICONSPACING_DESC"],
	type = "range",
	order = 22,
	min = -5,
	softMax = 20,
	step = 0.1,
	bigStep = 1,
	set = set,
	get = get,
})
TMW.Classes.GroupModule_IconPosition:RegisterConfigTable("args.main.args", "SpacingY", {
	name = L["UIPANEL_ICONSPACINGY"],
	desc = L["UIPANEL_ICONSPACING_DESC"],
	type = "range",
	order = 23,
	min = -5,
	softMax = 20,
	step = 0.1,
	bigStep = 1,
	set = set,
	get = get,
})
