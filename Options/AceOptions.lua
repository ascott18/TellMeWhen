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


local LSM = LibStub("LibSharedMedia-3.0")




local ACEOPTIONS = TMW:NewModule("AceOptions", "AceEvent-3.0")
TMW.ACEOPTIONS = ACEOPTIONS

function ACEOPTIONS:RegisterTab(parentIdentifier, order, appName, scale)
	local tab = TMW.IE:RegisterTab(parentIdentifier, appName:upper(), "MainOptions", order)
	
	tab:PostHookMethod("ClickHandler", function(self)
		TMW.ACEOPTIONS:CompileOptions()

		LibStub("AceConfigDialog-3.0"):Open(appName, TMW.IE.MainOptionsWidget)

		IE.Panels.MainOptions:SetScale(scale)
	end)

	return tab
end

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	IE.MainOptionsTab = ACEOPTIONS:RegisterTab("MAIN", 20, "TMWIEMain", 0.75)
	IE.MainOptionsTab:SetTitleComponents(false, false)
	IE.MainOptionsTab:SetText(TMW.L["UIPANEL_MAINOPT"])
	TMW:TT(IE.MainOptionsTab, "UIPANEL_MAINOPT", "GROUPADDONSETTINGS_DESC")


	local GroupOptionsTab = ACEOPTIONS:RegisterTab("GROUP", 1, "TMWIEGroup", 1)
	GroupOptionsTab:SetTitleComponents(false, true)
	GroupOptionsTab:SetText(TMW.L["GROUP"])
	TMW:TT(GroupOptionsTab, "GROUP", "GROUPSETTINGS_DESC")
	GroupOptionsTab:PostHookMethod("ClickHandler", function(self)
		if TMW.CI.group then
			ACEOPTIONS:LoadConfigGroup("TMWIEGroup", TMW.CI.group)
		end
	end)
end)

function ACEOPTIONS:LoadConfigGroup(info, group)
	local slug = "#Group " .. group.ID .. group.Domain

	TMW.ACEOPTIONS:LoadConfigPath(info, "groups_" .. group.Domain, slug)
end

function ACEOPTIONS:LoadConfigPath(info, ...)
	-- info is a standard ACD info table, or a string that represents the appName (like TMWStandalone)
	-- the path (...) is a list of keys in TMW.OptionsTable that leads to the desired group

	local appName = type(info) == "table" and info.appName or info
	assert(appName, "Couldn't determine appName to load the path in")


	LibStub("AceConfigDialog-3.0"):SelectGroup(appName, tostringall(...))

	TMW.ACEOPTIONS:NotifyChanges()
end

function ACEOPTIONS:NotifyChanges()
	-- this is used to refresh all open TMW configuration windows

	-- Notify standalone options panels of a change (Blizzard, slash command, LDB)
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TMWStandalone")

	-- Notify the group settings tab in the icon editor of any changes
	if IE.MainOptionsWidget and IE.MainOptionsWidget:GetUserDataTable().appName and IE.Panels.MainOptions:IsShown() then
		-- :Open() is used instead of :NotifyChanges because :NotifyChanges() only works for standalone ACD windows.
		LibStub("AceConfigDialog-3.0"):Open(IE.MainOptionsWidget:GetUserDataTable().appName, IE.MainOptionsWidget)
	end
end












-- ------------------------------------------
-- MAIN OPTIONS
-- ------------------------------------------

---------- Data/Templates ----------
local function FindGroupFromInfo(info)
	if info.appName == "TMWIEGroup" then
		return TMW.CI.group
	end

	for i = #info, 1, -1 do
		local n, domain = strmatch(info[i], "#Group (%d+)(.+)")
		if n and domain then
			return TMW[domain][tonumber(n)]
		end
	end
end TMW.FindGroupFromInfo = FindGroupFromInfo

local checkorder = {
	-- NOTE: these are actually backwards so they sort logically in AceConfig, but have their signs switched in the actual function (1 = -1; -1 = 1).
	[-1] = L["ASCENDING"],
	[1] = L["DESCENDING"],
}

local importExportBoxTemplate = {
	name = L["IMPORT_EXPORT"],
	type = "input",
	order = 200,
	width = "full",
	dialogControl = "TMW-ImportExport",
	get = function() end,
	set = function() end,
	--hidden = function() return IE.ExportBox:IsVisible() end,
} TMW.importExportBoxTemplate = importExportBoxTemplate

local specializationSettingHidden = function(info)
	local group = FindGroupFromInfo(info)
	if group.Domain == "global" then
		return true
	end
	return false
end

local common = {}
function common:group_set(info, val)
	local group = FindGroupFromInfo(info)
	local gspv = group:GetSettings()

	gspv[info[#info]] = val

	group:Setup()
end
function common:group_get(info)
	local group = FindGroupFromInfo(info)
	local gspv = group:GetSettings()
	
	return gspv[info[#info]]
end

function common:group_set_spv(info, val)
	local group = FindGroupFromInfo(info)
	local gspv = group:GetSettingsPerView()

	gspv[info[#info]] = val

	group:Setup()
end
function common:group_get_spv(info)
	local group = FindGroupFromInfo(info)
	local gspv = group:GetSettingsPerView()
	
	return gspv[info[#info]]
end

TMW.GroupConfigTemplate = {
	type = "group",
	handler = common,
	childGroups = "tab",
	name = function(info)
		local group = FindGroupFromInfo(info)
		if not group then 
			return ""
		elseif group.Name ~= "" then
			return group:GetGroupName(1)
		else
			return group:GetGroupName()
		end
	end,
	order = function(info)
		local group = FindGroupFromInfo(info)
		if not group then
			return 0
		end

		local offs = 0
		if group.Domain == "profile" then
			offs = 1000
		end

		return group:GetID() + offs
	end,
	set = function(info, val)
		local group = FindGroupFromInfo(info)
		
		group:GetSettings()[info[#info]] = val
		group:Setup()
	end,
	get = function(info)
		local group = FindGroupFromInfo(info)

		return group:GetSettings()[info[#info]]
	end,
	hidden = function(info)
		local group = FindGroupFromInfo(info)
		if not group then
			return true
		end
	end,
	args = {
		main = {
			type = "group",
			name = L["MAIN"],
			desc = L["UIPANEL_MAIN_DESC"],
			order = 1,
			args = {
				Enabled = {
					name = L["UIPANEL_ENABLEGROUP"],
					desc = L["UIPANEL_TOOLTIP_ENABLEGROUP"],

					type = "toggle",
					order = 1,
					width = "full",
					set = function(info, val)
						local group = FindGroupFromInfo(info)
						
						group:GetSettings().Enabled = val

						group:Setup()
					end,
					get = function(info)
						local group = FindGroupFromInfo(info)

						return group:GetSettings().Enabled
					end,
				},
				EnabledProfile = {
					name = function(info)
						local group = FindGroupFromInfo(info)

						return L["UIPANEL_ENABLEGROUP_FORPROFILE"]:format(TMW.db:GetCurrentProfile())
					end,
					desc = L["UIPANEL_TOOLTIP_ENABLEGROUP_GLOBAL_DESC"],

					type = "toggle",
					order = 1.5,
					width = "full",
					set = function(info, val)
						local group = FindGroupFromInfo(info)
						
						if group.Domain == "global" then
							group:GetSettings().EnabledProfiles[TMW.db:GetCurrentProfile()] = val
						end

						group:Setup()
					end,
					get = function(info)
						local group = FindGroupFromInfo(info)

						if group.Domain == "global" then
							return group:GetSettings().EnabledProfiles[TMW.db:GetCurrentProfile()]
						end
					end,

					hidden = function(info)
						local group = FindGroupFromInfo(info)

						return group.Domain ~= "global"
					end,
				},


				Name = {
					name = L["UIPANEL_GROUPNAME"],
					type = "input",
					order = 2,
					width = "full",
					set = function(info, val)
						local group = FindGroupFromInfo(info)

						group:GetSettings().Name = strtrim(val)
						group:Setup()
					end,
				},
				OnlyInCombat = {
					name = L["UIPANEL_ONLYINCOMBAT"],
					desc = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"],
					type = "toggle",
					order = 4,
				},
				PrimarySpec = {
					name = L["UIPANEL_PRIMARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_PRIMARYSPEC"],
					type = "toggle",
					order = 7,
					hidden = specializationSettingHidden,
				},
				SecondarySpec = {
					name = L["UIPANEL_SECONDARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_SECONDARYSPEC"],
					type = "toggle",
					order = 8,
					hidden = specializationSettingHidden,
				},
				Columns = {
					name = L["UIPANEL_COLUMNS"],
					desc = L["UIPANEL_TOOLTIP_COLUMNS"],
					type = "range",
					order = 20,
					min = 1,
					max = TELLMEWHEN_MAXROWS,
					step = 1,
					bigStep = 1,
				},
				Rows = {
					name = L["UIPANEL_ROWS"],
					desc = L["UIPANEL_TOOLTIP_ROWS"],
					type = "range",
					order = 21,
					min = 1,
					max = TELLMEWHEN_MAXROWS,
					step = 1,
					bigStep = 1,
				},
				
				CheckOrder = {
					name = L["CHECKORDER"],
					desc = L["CHECKORDER_ICONDESC"],
					type = "select",
					values = checkorder,
					style = "dropdown",
					order = 26,
				},
				View = {
					name = L["UIPANEL_GROUPTYPE"],
					desc = L["UIPANEL_GROUPTYPE_DESC"],
					type = "group",
					dialogInline = true,
					guiInline = true,
					order = 30,
					get = function(info)
						local group = FindGroupFromInfo(info)
						return group:GetSettings()[info[#info-1]] == info[#info]
					end,
					set = function(info)
						local group = FindGroupFromInfo(info)
						group:GetSettings()[info[#info-1]] = info[#info]
						
						-- This intentional. Double setup is needed for dealing with Masque bullshit,
						-- Second setup is addon-wide so that all icons and groups can become aware of the new view if needed.
						group:Setup()
						TMW:Update()
						
						IE:Load(1)
					end,
					args = {}
				},
				moveup = {
					name = L["UIPANEL_GROUPMOVEUP"],
					desc = L["UIPANEL_GROUPMOVEUP_DESC"],
					type = "execute",
					order = 48,
					func = function(info)
						local group = FindGroupFromInfo(info)
						local domain = group.Domain

						TMW:Group_Swap(domain, group.ID, group.ID - 1)

						TMW.ACEOPTIONS:LoadConfigGroup(info, TMW[domain][group.ID-1])
					end,
					disabled = function(info)
						return FindGroupFromInfo(info).ID == 1
					end,
				},
				movedown = {
					name = L["UIPANEL_GROUPMOVEDOWN"],
					desc = L["UIPANEL_GROUPMOVEDOWN_DESC"],
					type = "execute",
					order = 49,
					func = function(info)
						local group = FindGroupFromInfo(info)
						local domain = group.Domain

						TMW:Group_Swap(domain, group.ID, group.ID + 1)

						TMW.ACEOPTIONS:LoadConfigGroup(info, TMW[domain][group.ID+1])
					end,
					disabled = function(info)
						local group = FindGroupFromInfo(info)
						return group.ID == TMW.db[group.Domain].NumGroups
					end,
				},
				delete = {
					name = L["UIPANEL_DELGROUP"],
					--desc = L["UIPANEL_DELGROUP_DESC2"],
					type = "execute",
					order = 50,
					func = function(info)
						local group = FindGroupFromInfo(info)
						local domain = group.Domain


						if TMW[domain][group.ID-1] then
							TMW.ACEOPTIONS:LoadConfigGroup(info, TMW[domain][group.ID-1])
						elseif TMW[domain][group.ID] then
							TMW.ACEOPTIONS:LoadConfigGroup(info, TMW[domain][group.ID])
						end

						TMW:Group_Delete(group)
					end,
					confirm = function(info)
						--if IsControlKeyDown() then
						--	return false
						--else
						if TMW:Group_HasIconData(FindGroupFromInfo(info)) then
							return true
						end
						return false
					end,
				},
				switchDomain = {
					name = function(info)
						local group = FindGroupFromInfo(info)
						if group.Domain == "global" then
							return L["DOMAIN_PROFILE_SWITCHTO"]:format(TMW.db:GetCurrentProfile())
						else
							return L["DOMAIN_GLOBAL_SWITCHTO"]
						end
					end,
					desc = function(info)
						local group = FindGroupFromInfo(info)
						if group.Domain == "profile" then
							return L["GLOBAL_GROUP_GENERIC_DESC"]
						end
					end,
					type = "execute",
					width = "full",
					order = 60,
					func = function(info)
						local group = FindGroupFromInfo(info)
						group:SwitchDomain()

						IE:Load(1)
						TMW.ACEOPTIONS:NotifyChanges()
					end,
				},
				ImportExport = importExportBoxTemplate,
			},
		},
		position = {
			type = "group",
			order = 20,
			name = L["UIPANEL_POSITION"],
			desc = L["UIPANEL_POSITION_DESC"],
			args = {
			},
		},
	}
}

for i, role in TMW:Vararg("DAMAGER", "HEALER", "TANK") do
	local settingBit = bit.lshift(1, i-1)
	TMW.GroupConfigTemplate.args.main.args[role] = {
		type = "toggle",
		name = L["ROLEf"]:format(_G[role]),
		desc = L["UIPANEL_ROLE_DESC"],
		order = 9+i,
		set = function(info, val)
			local group = FindGroupFromInfo(info)
			local gs = group:GetSettings()

			gs.Role = bit.bxor(gs.Role, settingBit)

			group:Setup()
		end,
		get = function(info)
			local group = FindGroupFromInfo(info)

			return bit.band(group:GetSettings().Role, settingBit) == settingBit
		end,
	}
end
local addGroupFunctionGroup = {
	type = "group",
	name = L["UIPANEL_ADDGROUP"],
	dialogInline = true,
	guiInline = true,
	order = 40,
	args = {},
}
local addGroupButton = {
	name = function(info)
		return TMW.Views[info[#info]].name
	end,
	desc = L["UIPANEL_ADDGROUP_DESC"],
	type = "execute",
	width = "double",
	order = function(info)
		return TMW.Views[info[#info]].order
	end,
	func = function(info)
		for i = #info, 1, -1 do
			local domain = strmatch(info[i], "groups_(.+)")

			if domain then
				local group = TMW:Group_Add(domain, info[#info])

				TMW.ACEOPTIONS:LoadConfigGroup(info, group)
				return
			end
		end
	end,
}
local viewSelectToggle = {
	name = function(info)
		return TMW.Views[info[#info]].name
	end,
	desc = function(info)
		return TMW.Views[info[#info]].desc
	end,
	type = "toggle",
	order = function(info)
		return TMW.Views[info[#info]].order
	end,
}

local colorOrder = {
	"CBS",
	"CBM",
	"CBC",

	"OOR",
	"OOM",
	"OORM",

	"CTA",
	"COA",
	"CTS",
	"COS",

	"NA",
	"NS",
}
local colorTemplate = {
	type = "group",
	name = "",
	guiInline = true,
	dialogInline = true,
	width = "full",
	order = function(info)
		local this = info[#info]
		for order, key in pairs(colorOrder) do
			if key == this then
				return order + 10
			end
		end
	end,

	args = {
		header = {
			order = 0,
			type = "header",
			name = function(info)
				return L["COLOR_" .. info[#info-1]]
			end,
		},
		color = {
			name = L["COLOR_COLOR"],
			desc = function(info)
				return L["COLOR_" .. info[#info-1] .. "_DESC"]
			end,
			type = "color",
			order = 2,
			--width = "double",
			hasAlpha = function(info)
				return strsub(info[#info-1], 1, 2) == "CB"
			end,
			set = function(info, r, g, b, a)
				local c = TMW.db.profile.Colors[info[#info-2]][info[#info-1]]

				c.r = r c.g = g c.b = b c.a = a
				c.Override = true
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				local base = TMW.db.profile.Colors[info[#info-2]][info[#info-1]]
				local c = base
				if not base.Override then
				--	c = TMW.db.profile.Colors["GLOBAL"][info[#info-1]] -- i don't like this. too confusing to see the color change when checking and unchecking the setting
				end

				return c.r, c.g, c.b, c.a
			end,
			disabled = function(info)
				return not TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL"
			end
		},
		override = {
			name = L["COLOR_OVERRIDEDEFAULT"],
			desc = L["COLOR_OVERRIDEDEFAULT_DESC"],
			type = "toggle",
			width = "half",
			order = 1,
			set = function(info, val)
				TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override = val
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				return TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override
			end,
			hidden = function(info)
				return info[#info-2] == "GLOBAL"
			end,
		},
		gray = {
			name = L["COLOR_DESATURATE"],
			desc = L["COLOR_DESATURATE_DESC"],
			type = "toggle",
			width = "half",
			order = 3,
			set = function(info, val)
				TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Gray = val
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				return TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Gray
			end,
			disabled = function(info)
				return strsub(info[#info-1], 1, 2) == "CB" or (not TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL")
			end
		},
		reset = {
			name = RESET,
			desc = L["COLOR_RESET_DESC"],
			type = "execute",
			width = "half",
			order = 10,
			func = function(info)
				TMW.db.profile.Colors[info[#info-2]][info[#info-1]] = CopyTable(TMW.Defaults.profile.Colors["**"][info[#info-1]])
			end,
		--[=[	disabled = function(info)
				return not TMW.db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL"
			end]=]
		},
	},
}
local colorIconTypeTemplate = {
	type = "group",
	name = function(info)
		if info[#info] == "GLOBAL" then
			return L["COLOR_DEFAULT"]
		end
		return TMW.Types[info[#info]].name
	end,
	order = function(info)
		local this = info[#info]

		if this == "GLOBAL" then
			return 0
		end

		for order, type in ipairs(TMW.OrderedTypes) do
			if type.type == this then
				return order
			end
		end
	end,

	--only inherited by ColorMSQ and OnlyMSQ:
	set = function(info, val)
		TMW.db.profile[info[#info]] = val
		TMW:Update()
	end,
	get = function(info)
		return TMW.db.profile[info[#info]]
	end,

	args = {
		desc = {
			order = 0,
			type = "description",
			name = function(info)
				local this = info[#info-1]
				local t

				if this == "GLOBAL" then
					t = L["COLOR_HEADER_DEFAULT"]
				else
					t = L["COLOR_HEADER"]:format(TMW.Types[this].name, "?")-- 2nd param is to prevent errors incase StaticFormats errors
				end
				return t .. "\r\n"
			end,
		},

		ColorMSQ = {
			name = L["COLOR_MSQ_COLOR"],
			desc = L["COLOR_MSQ_COLOR_DESC"],
			type = "toggle",
			order = 1,
			hidden = function(info)
				return not LMB or info[#info-1] ~= "GLOBAL"
			end,
		},
		OnlyMSQ = {
			name = L["COLOR_MSQ_ONLY"],
			desc = L["COLOR_MSQ_ONLY_DESC"],
			type = "toggle",
			width = "double",
			order = 2,
			hidden = function(info)
				return not LMB or info[#info-1] ~= "GLOBAL"
			end,
			disabled = function(info)
				return not TMW.db.profile.ColorMSQ
			end,
		},
		ColorGCD = {
			name = L["COLOR_IGNORE_GCD"],
			desc = L["COLOR_IGNORE_GCD_DESC"],
			type = "toggle",
			order = 3,
			hidden = function(info)
				return not LMB or info[#info-1] ~= "GLOBAL"
			end,
		},
	}
}
for k, v in pairs(colorOrder) do
	colorIconTypeTemplate.args[v] = colorTemplate
end

TMW.OptionsTable = {
	name = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL,
	type = "group",
	handler = common,
	args = {
		main = {
			type = "group",
			name = L["UIPANEL_MAINOPT"],
			order = 1,
			set = function(info, val)
				TMW.db.profile[info[#info]] = val
				TMW:ScheduleUpdate(0.4)
			end,
			get = function(info) return TMW.db.profile[info[#info]] end,
			args = {
				AllowCombatConfig = {
					name = L["UIPANEL_COMBATCONFIG"],
					desc = L["UIPANEL_COMBATCONFIG_DESC"],
					type = "toggle",
					order = 2.5,
					confirm = function(info)
						return not TMW.db.global[info[#info]]
					end,
					set = function(info, val)
						TMW.db.global[info[#info]] = val
					end,
					get = function(info) return TMW.db.global[info[#info]] end,
				},
				Locked = {
					name = L["UIPANEL_LOCKUNLOCK"],
					desc = L["UIPANEL_SUBTEXT2"],
					type = "toggle",
					order = 2,
				},
				TextureName = {
					name = L["UIPANEL_BARTEXTURE"],
					type = "select",
					order = 3,
					dialogControl = 'LSM30_Statusbar',
					values = LSM:HashTable("statusbar"),
				},
				sliders = {
					type = "group",
					order = 9,
					name = "",
					guiInline = true,
					dialogInline = true,
					args = {
						Interval = {
							name = L["UIPANEL_UPDATEINTERVAL"],
							desc = L["UIPANEL_TOOLTIP_UPDATEINTERVAL"],
							type = "range",
							order = 9,
							min = 0,
							max = 0.5,
							step = 0.01,
							bigStep = 0.01,
						},
						EffThreshold = {
							name = L["UIPANEL_EFFTHRESHOLD"],
							desc = L["UIPANEL_EFFTHRESHOLD_DESC"],
							type = "range",
							order = 10,
							min = 0,
							max = 40,
							step = 1,
						},
					},
				},
				checks = {
					type = "group",
					order = 21,
					name = "",
					guiInline = true,
					dialogInline = true,
					args = {
						DEBUG_ForceAutoUpdate = {
							name = "DEBUG: FORCE AUTO UPDATES",
							desc = "TMW v5 introduced new code that manages updates much more efficiently, only updating icons when they need to be updated. Check this to disable this feature in order to compare between the old method and the new method to see if there are any discrepancies that may be indicative of a bug.",
							type = "toggle",
							order = 1,
							hidden = true,
						},
						--[[ColorNames = {
							name = L["COLORNAMES"],
							desc = L["COLORNAMES_DESC"],
							type = "toggle",
							order = 42,
						},]]
						--[[AlwaysSubLinks = {
							-- unused
							name = L["ALWAYSSUBLINKS"],
							desc = L["ALWAYSSUBLINKS_DESC"],
							type = "toggle",
							order = 43,
						},]]
						--[[SUG_atBeginning = {
							-- I really doubt that anyone uses this setting at all.
							-- Going to hide it and see if anyone complains.
							
							name = L["SUG_ATBEGINING"],
							desc = L["SUG_ATBEGINING_DESC"],
							width = "double",
							type = "toggle",
							order = 44,
						},]]
						ReceiveComm = {
							name = L["ALLOWCOMM"],
							desc = L["ALLOWCOMM_DESC"],
							type = "toggle",
							order = 50,
						},
						WarnInvalids = {
							name = L["UIPANEL_WARNINVALIDS"],
							type = "toggle",
							width = "double",
							order = 51,
						},
						VersionWarning = {
							name = L["ALLOWVERSIONWARN"],
							type = "toggle",
							order = 52,
							set = function(info, val)
								TMW.db.global[info[#info]] = val
							end,
							get = function(info) return TMW.db.global[info[#info]] end,
						},
						ShowGUIDs = {
							name = L["SHOWGUIDS_OPTION"],
							desc = L["SHOWGUIDS_OPTION_DESC"],
							type = "toggle",
							order = 52,
							set = function(info, val)
								TMW.db.global[info[#info]] = val
							end,
							get = function(info) return TMW.db.global[info[#info]] end,
						},
					},
				},

				SoundChannel = {
					name = L["SOUND_CHANNEL"],
					desc = L["SOUND_CHANNEL_DESC"],
					type = "select",
					values = {
						-- GLOBALS: SOUND_VOLUME, MUSIC_VOLUME, AMBIENCE_VOLUME
						SFX = SOUND_VOLUME,
						Music = MUSIC_VOLUME,
						Ambience = AMBIENCE_VOLUME,
						Dialog = DIALOG_VOLUME,
						Master = L["SOUND_CHANNEL_MASTER"],
					},
					order = 29,
				},
				CheckOrder = {
					name = L["CHECKORDER"],
					desc = L["CHECKORDER_GROUPDESC"],
					type = "select",
					values = checkorder,
					style = "dropdown",
					order = 30,
				},
				--[[resetall = {
					name = L["UIPANEL_ALLRESET"],
					desc = L["UIPANEL_TOOLTIP_ALLRESET"],
					type = "execute",
					order = 51,
					confirm = true,
					func = function() TMW.db:ResetProfile() end,
				},]]
				importexport = importExportBoxTemplate,

				deleteNonCurrentLocaleData = {
					name = ("Delete non-essential cached data for non-%s locales."):format(GetLocale()),
					desc = "TellMeWhen_Options caches some data about WoW's spells for each locale that you play in. You can safely delete that data for other locales to free up space.",
					type = "execute",
					width = "full",
					order = 1000,
					func = function(info)
						local currentLocale = GetLocale():lower()

						for locale in pairs(TMW.IE.db.sv.locale) do
							if locale ~= currentLocale then
								TMW.IE.db.sv.locale[locale] = nil
								TMW:Printf("Deleted cache for locale %s", locale)
							end
						end
					end,
					hidden = function(info)
						local locale = TMW.IE.db.sv.locale
						-- This evaluates to nil when there is only one locale in the table
						return next(locale, next(locale)) == nil
					end,
				},
			},
		},

		colors = {
			type = "group",
			name = L["UIPANEL_COLORS"],
			desc = L["UIPANEL_COLORS_DESC"],
			order = 10,
			childGroups = "tree",
			args = {},
		},
		
		groups_global = {
			type = "group",
			name = L["UIPANEL_GROUPS"] .. " - " .. L["DOMAIN_GLOBAL"],
			desc = L["UIPANEL_GROUPS_GLOBAL_DESC"],
			order = 30,
			args = {
				addgroup = addGroupFunctionGroup,
				importexport = importExportBoxTemplate,
				addgroupgroup = {
					type = "group",
					name = L["UIPANEL_ADDGROUP"],
					order = 2000,
					args = {
						addgroup = addGroupFunctionGroup,
						importexport = importExportBoxTemplate,
					},
				},
			},
		},
		
		groups_profile = {
			type = "group",
			name = L["UIPANEL_GROUPS"] .. " - " .. L["DOMAIN_PROFILE"],
			desc = L["UIPANEL_GROUPS_DESC"],
			order = 31,
			args = {
				addgroup = addGroupFunctionGroup,
				importexport = importExportBoxTemplate,
				addgroupgroup = {
					type = "group",
					name = L["UIPANEL_ADDGROUP"],
					order = math.huge,
					args = {
						addgroup = addGroupFunctionGroup,
						importexport = importExportBoxTemplate,
					},
				},
			},
		},
	},
}

---------- Options Table Compilation ----------
function TMW.ACEOPTIONS:CompileOptions()

	if TMW:AssertOptionsInitialized() then
		return
	end

	if not TMW.OptionsTableInitialized then


		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(TMW.db)
		
		-- dont copy the entire profiles table because it contains a reference to db
		TMW.OptionsTable.args.profiles.args = CopyTable(TMW.OptionsTable.args.profiles.args)
		
		TMW.OptionsTable.args.profiles.args.importexportdesc = {
			order = 90,
			type = "description",
			name = "\r\n" .. L["IMPORT_EXPORT_DESC_INLINE"],
			--hidden = function() return IE.ExportBox:IsVisible() end,
		}
		TMW.OptionsTable.args.profiles.args.importexport = importExportBoxTemplate


		-- Dynamic Icon View Settings --
		for view in pairs(TMW.Views) do
			TMW.GroupConfigTemplate.args.main.args.View.args[view] = viewSelectToggle
			addGroupFunctionGroup.args[view] = addGroupButton
		end


		-- Talent Tree group options
		local parent = TMW.GroupConfigTemplate.args.main.args
		
		for i = 1, GetNumSpecializations() do
			local _, name = GetSpecializationInfo(i)
			parent["Tree"..i] = {
				type = "toggle",
				name = L["TREEf"]:format(name),
				desc = L["UIPANEL_TREE_DESC"],
				order = 12+i,
				hidden = specializationSettingHidden,
			}
		end
	

		-- Dynamic Color Settings --
		TMW.OptionsTable.args.colors.args.GLOBAL = colorIconTypeTemplate
		for k, Type in pairs(TMW.Types) do
			if not Type.NoColorSettings then
				TMW.OptionsTable.args.colors.args[k] = colorIconTypeTemplate
			end
		end


	
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMWIEMain", TMW.OptionsTable)
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMWIEGroup", TMW.GroupConfigTemplate)
		
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMWStandalone", TMW.OptionsTable)
		LibStub("AceConfigDialog-3.0"):SetDefaultSize("TMWStandalone", 781, 512)


		TMW.OptionsTableInitialize = true
	end


	-- Dynamic Group Settings --
	for _, domain in TMW:Vararg("profile", "global") do
		local args = TMW.OptionsTable.args["groups_"..domain].args

		for k, v in pairs(args) do
			if v == TMW.GroupConfigTemplate then
				args[k] = nil
			end
		end

		for g = 1, TMW.db[domain].NumGroups do
			args["#Group " .. g .. domain] = TMW.GroupConfigTemplate
		end
	end
	
	TMW:Fire("TMW_CONFIG_MAIN_OPTIONS_COMPILE", TMW.OptionsTable)

	
	if not TMW.AddedToBlizz then
		-- GLOBALS: INTERFACEOPTIONS_ADDONCATEGORIES, InterfaceAddOnsList_Update
		for k, v in pairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
			if v.name == "TellMeWhen" and not v.obj then
				tremove(INTERFACEOPTIONS_ADDONCATEGORIES, k)
				InterfaceAddOnsList_Update()
				break
			end
		end

		TMW.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TMWStandalone", "TellMeWhen")
		
		if TMW.AddedToBlizz and not TMW.ALLOW_LOCKDOWN_CONFIG then
			local canShow = true
			
			IE:RegisterEvent("PLAYER_REGEN_DISABLED", function()
				canShow = false
				TMW.AddedToBlizz:Hide()
			end)
			
			IE:RegisterEvent("PLAYER_REGEN_ENABLED", function()
				canShow = true
				if InterfaceOptionsFramePanelContainer.displayedPanel == TMW.AddedToBlizz then
					TMW.AddedToBlizz:Show()
				end
			end)

			TMW.AddedToBlizz:HookScript("OnShow", function(self)
				if not canShow then
					self:Hide()
				end
			end)
		end
	end
end
