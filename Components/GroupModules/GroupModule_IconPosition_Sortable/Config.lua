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


---------------------
-- Layout Direction
---------------------

TMW.Classes.GroupModule_IconPosition_Sortable:RegisterConfigTable("args.main.args", "LayoutDirection", {
	name = L["LAYOUTDIRECTION"],
	desc = L["LAYOUTDIRECTION_DESC"],
	type = "select",
	values = {
		L["LAYOUTDIRECTION_1"],
		L["LAYOUTDIRECTION_2"],
		L["LAYOUTDIRECTION_3"],
		L["LAYOUTDIRECTION_4"],
		L["LAYOUTDIRECTION_5"],
		L["LAYOUTDIRECTION_6"],
		L["LAYOUTDIRECTION_7"],
		L["LAYOUTDIRECTION_8"],
	},  
	style = "dropdown",
	order = 27,
})


---------------------
-- Sorting
---------------------

local groupSortPriorities = {
	"id",
	"duration",
	"stacks",
	"visiblealpha",
	"visibleshown",
	"alpha",
	"shown",
}

local groupSortValues = {
	L["UIPANEL_GROUPSORT_id"],
	L["UIPANEL_GROUPSORT_duration"],
	L["UIPANEL_GROUPSORT_stacks"],
	L["UIPANEL_GROUPSORT_visiblealpha"],
	L["UIPANEL_GROUPSORT_visibleshown"],
	L["UIPANEL_GROUPSORT_alpha"],
	L["UIPANEL_GROUPSORT_shown"],
}

local groupSortMethodTemplate -- this pre-declaraion is intentional
groupSortMethodTemplate = {
	type = "group",
	name = function(info)
		return ""
	end,
	order = function(info)
		return 50+ tonumber(info[#info])
	end,
	disabled = function(info, priorityID)
		local group = FindGroupFromInfo(info)
		local priorityID = priorityID or tonumber(info[#info-1])

		for k, v in pairs(group:GetSettings().SortPriorities) do
			if k < priorityID and v.Method == "id" then
				return true
			end
		end
	end,
	dialogInline = true,
	guiInline = true,
	args = {
		method = {
			name = function(info)
				local priorityID = tonumber(info[#info-1])
				return L["UIPANEL_GROUPSORT_METHODNAME"]:format(priorityID)
			end,
			desc = function(info)
				local group = FindGroupFromInfo(info)

				local priorityID = tonumber(info[#info-1])
				local Method = group:GetSettings().SortPriorities[priorityID].Method

				local desc = L["UIPANEL_GROUPSORT_METHODNAME_DESC"]:format(priorityID) .. "\r\n\r\n" .. L["UIPANEL_GROUPSORT_" .. Method .. "_DESC"]
				if groupSortMethodTemplate.disabled(info, priorityID) then
					desc = desc .. "\r\n\r\n" .. L["UIPANEL_GROUPSORT_METHODDISABLED_DESC"]
				end
				return desc
			end,
			type = "select",
			width = "double",
			values = groupSortValues,
			style = "dropdown",
			order = 1,
			get = function(info)
				local group = FindGroupFromInfo(info)

				local priorityID = tonumber(info[#info-1])
				local Method = group:GetSettings().SortPriorities[priorityID].Method

				for k, v in pairs(groupSortPriorities) do
					if Method == v then
						return k
					end
				end
			end,
			set = function(info, val)
				local group = FindGroupFromInfo(info)
				local gs = group:GetSettings()

				local priorityID = tonumber(info[#info-1])
				local oldPriority = gs.SortPriorities[priorityID]

				for k, v in pairs(gs.SortPriorities) do
					if v.Method == groupSortPriorities[val] then
						gs.SortPriorities[k] = oldPriority
						gs.SortPriorities[priorityID] = v
						break
					end
				end

				group:Setup()
			end,
		},
		OrderAscending = {
			name = L["UIPANEL_GROUPSORT_SORTASCENDING"],
			desc = L["UIPANEL_GROUPSORT_SORTASCENDING_DESC"],
			type = "toggle",
			width = "half",
			order = 2,
			get = function(info)
				local group = FindGroupFromInfo(info)
				local priorityID = tonumber(info[#info-1])

				return group:GetSettings().SortPriorities[priorityID].Order == 1
			end,
			set = function(info)
				local group = FindGroupFromInfo(info)
				local priorityID = tonumber(info[#info-1])

				group:GetSettings().SortPriorities[priorityID].Order = 1
				group:Setup()
			end,
		},
		OrderDescending = {
			name = L["UIPANEL_GROUPSORT_SORTDESCENDING"],
			desc = L["UIPANEL_GROUPSORT_SORTDESCENDING_DESC"],
			type = "toggle",
			width = "half",
			order = 3,
			get = function(info)
				local group = FindGroupFromInfo(info)
				local priorityID = tonumber(info[#info-1])

				return group:GetSettings().SortPriorities[priorityID].Order == -1
			end,
			set = function(info)
				local group = FindGroupFromInfo(info)
				local priorityID = tonumber(info[#info-1])
				
				group:GetSettings().SortPriorities[priorityID].Order = -1
				group:Setup()
			end,
		},
	}
}

local Sorting_args = {
	quick_default = {
		name = L["UIPANEL_GROUP_QUICKSORT_DEFAULT"],
		desc = L["UIPANEL_GROUP_QUICKSORT_DEFAULT_DESC"],
		type = "execute",
		order = 10,
		func = function(info)
			local group = FindGroupFromInfo(info)
			local gs = group:GetSettings()

			for priorityID, priority in TMW:Vararg("id") do
				local oldPriority = gs.SortPriorities[priorityID]

				for k, v in pairs(gs.SortPriorities) do
					if v.Method == priority then
						gs.SortPriorities[k] = oldPriority
						gs.SortPriorities[priorityID] = v
						break
					end
				end
			end

			group:Setup()
		end,
	},
	quick_duration = {
		name = L["UIPANEL_GROUP_QUICKSORT_DURATION"],
		desc = L["UIPANEL_GROUP_QUICKSORT_DURATION_DESC"],
		type = "execute",
		order = 11,
		func = function(info)
			local group = FindGroupFromInfo(info)
			local gs = group:GetSettings()

			for priorityID, priority in TMW:Vararg("visibleshown", "duration", "id") do
				local oldPriority = gs.SortPriorities[priorityID]

				for k, v in pairs(gs.SortPriorities) do
					if v.Method == priority then
						gs.SortPriorities[k] = oldPriority
						gs.SortPriorities[priorityID] = v
						break
					end
				end
			end

			group:Setup()
		end,
	},
	
}
for i = 1, #TMW.Group_Defaults.SortPriorities do
	Sorting_args[tostring(i)] = groupSortMethodTemplate
end

TMW.Classes.GroupModule_IconPosition_Sortable:RegisterConfigTable("args", "Sorting", {
	name = L["UIPANEL_GROUPSORT"],
	desc = L["UIPANEL_GROUPSORT_DESC"],
	type = "group",
	order = 10,
	args = Sorting_args,
})
