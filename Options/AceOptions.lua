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
	
	tab:HookScript("OnClick", function(self)
		TMW.ACEOPTIONS:CompileOptions()

		LibStub("AceConfigDialog-3.0"):Open(appName, TMW.IE.MainOptionsWidget)

		IE.Pages.MainOptions:SetScale(scale)
	end)

	return tab
end

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	IE.MainOptionsTab = ACEOPTIONS:RegisterTab("MAIN", 20, "TMWIEMain", 0.89)
	IE.MainOptionsTab:SetText(TMW.L["UIPANEL_MAINOPT"])
	TMW:TT(IE.MainOptionsTab, "UIPANEL_MAINOPT", "ADDONSETTINGS_DESC")
end)

function ACEOPTIONS:LoadConfigGroup(info, group)
	local slug = "#Group " .. group.ID .. group.Domain

	TMW.ACEOPTIONS:LoadConfigPath(info, "groups_" .. group.Domain, slug)
end

function ACEOPTIONS:LoadConfigPath(info, ...)
	-- info is a standard ACD info table, or a string that represents the appName
	-- the path (...) is a list of keys in TMW.OptionsTable that leads to the desired group

	local appName = type(info) == "table" and info.appName or info
	assert(appName, "Couldn't determine appName to load the path in")


	LibStub("AceConfigDialog-3.0"):SelectGroup(appName, tostringall(...))

	TMW.ACEOPTIONS:NotifyChanges()
end

function ACEOPTIONS:NotifyChanges()
	-- this is used to refresh all open TMW configuration windows

	-- Notify the group settings tab in the icon editor of any changes
	if IE.MainOptionsWidget and IE.MainOptionsWidget:GetUserDataTable().appName and IE.Pages.MainOptions:IsShown() then
		-- :Open() is used instead of :NotifyChanges because :NotifyChanges() only works for standalone ACD windows.
		LibStub("AceConfigDialog-3.0"):Open(IE.MainOptionsWidget:GetUserDataTable().appName, IE.MainOptionsWidget)
	end
end












-- ------------------------------------------
-- MAIN OPTIONS
-- ------------------------------------------

---------- Data/Templates ----------
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

				c.Color = TMW:RGBAToString(r, g, b, a)
				c.Override = true

				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				local c = TMW.db.profile.Colors[info[#info-2]][info[#info-1]]

				return TMW:StringToRGBA(c.Color)
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


		-- Dynamic Color Settings --
		TMW.OptionsTable.args.colors.args.GLOBAL = colorIconTypeTemplate
		for k, Type in pairs(TMW.Types) do
			if not Type.NoColorSettings then
				TMW.OptionsTable.args.colors.args[k] = colorIconTypeTemplate
			end
		end
	
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMWIEMain", TMW.OptionsTable)


		TMW.OptionsTableInitialize = true
	end
	
	TMW:Fire("TMW_CONFIG_MAIN_OPTIONS_COMPILE", TMW.OptionsTable)

end
