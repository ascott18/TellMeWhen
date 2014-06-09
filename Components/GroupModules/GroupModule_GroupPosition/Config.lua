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


TMW.Classes.GroupModule_GroupPosition:RegisterConfigTable("args.position.args", "Position", {
	type = "group",
	order = 5,
	name = "",
	desc = "",
	set = function(info, val)
		local group = FindGroupFromInfo(info)

		group:GetSettings().Point[info[#info]] = val
		
		local Module = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
		
		if Module then
			Module:SetPos()
		end
	end,
	get = function(info)
		local group = FindGroupFromInfo(info)

		return group:GetSettings().Point[info[#info]]
	end,
	dialogInline = true,
	guiInline = true,
	
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
			desc = function(info)
				local group = FindGroupFromInfo(info)
				local relativeTo = group:GetSettings().Point[info[#info]]

				local desc = L["UIPANEL_RELATIVETO_DESC"]

				if TMW:ParseGUID(relativeTo) == "group" then
					desc = desc .. "\r\n\r\n" .. L["UIPANEL_RELATIVETO_DESC_GUIDINFO"]
				end
				
				return desc
			end,
			type = "input",
			width = "double",
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
	},
})

TMW.Classes.GroupModule_GroupPosition:RegisterConfigTable("args.position.args", "scaleAndStrata", {
	type = "group",
	order = 10,
	name = "",
	desc = "",
	set = function(info, val)
		local group = FindGroupFromInfo(info)

		group:GetSettings()[info[#info]] = val

		local Module = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
		
		if Module then
			Module:SetPos()
		end
	end,
	get = function(info)
		local group = FindGroupFromInfo(info)

		return group:GetSettings()[info[#info]]
	end,
	dialogInline = true,
	guiInline = true,
	
	args = {
		
		Scale = {
			name = L["UIPANEL_SCALE"],
			type = "range",
			order = 6,
			min = 0.6,
			softMax = 10,
			bigStep = 0.01,
		},
		Level = {
			name = L["UIPANEL_LEVEL"],
			type = "range",
			order = 7,
			min = 5,
			softMax = 100,
			step = 1,
		},
		Strata = {
			name = L["UIPANEL_STRATA"],
			type = "select",
			style = "dropdown",
			order = 8,
			set = function(info, val)
				local group = FindGroupFromInfo(info)
				group:GetSettings()[info[#info]] = stratas[val]
		
				local Module = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
				
				if Module then
					Module:SetPos()
				end
			end,
			get = function(info)
				local group = FindGroupFromInfo(info)

				local val = group:GetSettings()[info[#info]]
				for k, v in pairs(stratas) do
					if v == val then
						return k
					end
				end
			end,
			values = strataDisplay,
		},
	},
})

TMW.Classes.GroupModule_GroupPosition:RegisterConfigTable("args.position.args", "reset", {
	name = L["UIPANEL_GROUPRESET"],
	desc = L["UIPANEL_TOOLTIP_GROUPRESET"],
	type = "execute",
	order = 50,
	func = function(info)
		local group = FindGroupFromInfo(info)
		local gs = group:GetSettings()
		
		for k, v in pairs(TMW.Group_Defaults.Point) do
			gs.Point[k] = v
		end
		gs.Scale = 1
		gs.Locked = false
		
		TMW.ACEOPTIONS:NotifyChanges()
		group:Setup()
	end,
})




TMW.Classes.SharableDataType.types.group:RegisterMenuBuilder(10, function(Item_group)
	local gs = Item_group.Settings
	local IMPORTS, EXPORTS = Item_group:GetEditBox():GetAvailableImportExportTypes()

	-- copy group position
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["COPYPOSSCALE"]
	info.func = function()
		CloseDropDownMenus()
		local destgroup = IMPORTS.group_overwrite
		local destgs = destgroup:GetSettings()
		
		-- Restore all default settings first.
		-- Not a special table (["**"]), so just normally copy it.
		-- Setting it nil won't recreate it like other settings tables, so re-copy from defaults.
		destgs.Point = CopyTable(TMW.Group_Defaults.Point)
		
		TMW:CopyTableInPlaceWithMeta(gs.Point, destgs.Point, true)

		destgs.Scale = gs.Scale or TMW.Group_Defaults.Scale
		destgs.Level = gs.Level or TMW.Group_Defaults.Level
		
		destgroup:Setup()
	end
	info.notCheckable = true
	info.disabled = not IMPORTS.group_overwrite
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end)

