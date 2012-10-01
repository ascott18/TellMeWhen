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

local findid = TMW.FindGroupIDFromInfo
local stratas = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	"TOOLTIP",
}
local strataDisplay = {}
for k, v in pairs(stratas) do
	strataDisplay[k] = L["STRATA_"..v]
end

TMW.GroupConfigTemplate.args.position = {
	type = "group",
	order = 20,
	name = L["UIPANEL_POSITION"],
	desc = L["UIPANEL_POSITION_DESC"],
	set = function(info, val)
		local g = findid(info)
		TMW.db.profile.Groups[g].Point[info[#info]] = val
		
		local Module = TMW[g]:GetModuleOrModuleChild("GroupModule_GroupPosition")
		
		if Module then
			Module:SetPos()
		end
	end,
	get = function(info)
		return TMW.db.profile.Groups[findid(info)].Point[info[#info]]
	end,
	hidden = function(info)
		local g = findid(info)
		
		return not TMW[g]:GetModuleOrModuleChild("GroupModule_GroupPosition", true)
	end,
	args = {
		point = {
			name = L["UIPANEL_POINT"],
			desc = L["UIPANEL_POINT_DESC"],
			type = "select",
			values = TMW.points,
			style = "dropdown",
			order = 1,
		},
		relativeTo = {
			name = L["UIPANEL_RELATIVETO"],
			desc = L["UIPANEL_RELATIVETO_DESC"],
			type = "input",
			order = 2,
		},
		relativePoint = {
			name = L["UIPANEL_RELATIVEPOINT"],
			desc = L["UIPANEL_RELATIVEPOINT_DESC"],
			type = "select",
			values = TMW.points,
			style = "dropdown",
			order = 3,
		},
		x = {
			name = L["UIPANEL_FONT_XOFFS"],
			desc = L["UIPANEL_FONT_XOFFS_DESC"],
			type = "range",
			order = 4,
			softMin = -500,
			softMax = 500,
			step = 1,
			bigStep = 1,
		},
		y = {
			name = L["UIPANEL_FONT_YOFFS"],
			desc = L["UIPANEL_FONT_YOFFS_DESC"],
			type = "range",
			order = 5,
			softMin = -500,
			softMax = 500,
			step = 1,
			bigStep = 1,
		},
		scale = {
			name = L["UIPANEL_SCALE"],
			type = "range",
			order = 6,
			min = 0.6,
			softMax = 10,
			bigStep = 0.01,
			set = function(info, val)
				local g = findid(info)
				TMW.db.profile.Groups[g].Scale = val
		
				local Module = TMW[g]:GetModuleOrModuleChild("GroupModule_GroupPosition")
				
				if Module then
					Module:SetPos()
				end
			end,
			get = function(info) return TMW.db.profile.Groups[findid(info)].Scale end,
		},
		Level = {
			name = L["UIPANEL_LEVEL"],
			type = "range",
			order = 7,
			min = 5,
			softMax = 100,
			step = 1,
			set = function(info, val)
				local g = findid(info)
				TMW.db.profile.Groups[g].Level = val
		
				local Module = TMW[g]:GetModuleOrModuleChild("GroupModule_GroupPosition")
				
				if Module then
					Module:SetPos()
				end
			end,
			get = function(info) return TMW.db.profile.Groups[findid(info)].Level end,
		},
		Strata = {
			name = L["UIPANEL_STRATA"],
			type = "select",
			style = "dropdown",
			order = 8,
			set = function(info, val)
				local g = findid(info)
				TMW.db.profile.Groups[g].Strata = stratas[val]
		
				local Module = TMW[g]:GetModuleOrModuleChild("GroupModule_GroupPosition")
				
				if Module then
					Module:SetPos()
				end
			end,
			get = function(info)
				local val = TMW.db.profile.Groups[findid(info)].Strata
				for k, v in pairs(stratas) do
					if v == val then
						return k
					end
				end
			end,
			values = strataDisplay,
		},
		lock = {
			name = L["UIPANEL_LOCK"],
			desc = L["UIPANEL_LOCK_DESC"],
			type = "toggle",
			order = 40,
			set = function(info, val)
				local g = findid(info)
				TMW.db.profile.Groups[g].Locked = val
		
				TMW[g]:Setup()
			end,
			get = function(info) return TMW.db.profile.Groups[findid(info)].Locked end
		},
		reset = {
			name = L["UIPANEL_GROUPRESET"],
			desc = L["UIPANEL_TOOLTIP_GROUPRESET"],
			type = "execute",
			order = 50,
			func = function(info) TMW:Group_ResetPosition(findid(info)) end
		},
	},
}
	