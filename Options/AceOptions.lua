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
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))




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

				checks = {
					type = "group",
					order = 21,
					name = "",
					guiInline = true,
					dialogInline = true,
					args = {
						WarnInvalids = {
							name = L["UIPANEL_WARNINVALIDS"],
							type = "toggle",
							width = "double",
							order = 51,
						},
						ShowGUIDs = {
							name = L["SHOWGUIDS_OPTION"],
							desc = L["SHOWGUIDS_OPTION_DESC"],
							type = "toggle",
							order = 52,
						},
					},
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

	
		LibStub("AceConfig-3.0"):RegisterOptionsTable("TMWIEMain", TMW.OptionsTable)


		TMW.OptionsTableInitialize = true
	end
end
