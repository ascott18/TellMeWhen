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

local SNIPPETS = TMW.SNIPPETS



local function getSnippetSettings(info)
	for i = #info, 1, -1 do
		local n = strmatch(info[i], "#Snippet (%d+)")
		n = tonumber(n)
		
		if n then
			local db = TMW.db[info[i-1]].CodeSnippets			
			
			return db[n], info[i-1], n
		end
	end
end


local snippetTemplate = {
	type = "group",
	name = function(info)
		local snippet = getSnippetSettings(info)
		return snippet.Name
	end,
	order = function(info)
		local snippet = getSnippetSettings(info)
		return snippet.Order
	end,
	set = function(info, val)
		local snippet = getSnippetSettings(info)
		snippet[info[#info]] = val
	end,
	get = function(info)
		local snippet = getSnippetSettings(info)
		return snippet[info[#info]]
	end,
	args = {
		Enabled = {
			name = L["CODESNIPPET_AUTORUN"],
			type = "toggle",
			order = 1,
			width = "full",
		},
		Name = {
			name = L["CODESNIPPET_RENAME"],
			desc = L["CODESNIPPET_RENAME_DESC"],
			type = "input",
			--width = "double",
			order = 2,
			set = function(info, val)
				local snippet = getSnippetSettings(info)
				snippet.Name = strtrim(val)
			end,
		},
		Order = {
			name = L["CODESNIPPET_ORDER"],
			desc = L["CODESNIPPET_ORDER_DESC"],
			type = "input",
			--width = "half",
			order = 3,
			set = function(info, val)
				val = tonumber(val)
				if not val then
					return
				end
				
				local snippet = getSnippetSettings(info)
				snippet.Order = val
			end,
			get = function(info)
				local snippet = getSnippetSettings(info)
				return tostring(snippet[info[#info]])
			end,
		},
		
		runnow = {
			name = L["CODESNIPPET_RUNNOW"],
			desc = L["CODESNIPPET_RUNNOW_DESC"],
			type = "execute",
			order = 4,
			func = function(info)
				local snippet, scope, id = getSnippetSettings(info)
				
				SNIPPETS:RunSnippet(snippet)
			end,
			confirm = function(info)
				local snippet = getSnippetSettings(info)
				
				if IsControlKeyDown() then
					return false
				elseif SNIPPETS:HasRanSnippet(snippet) then
					return L["CODESNIPPET_RUNNOW_CONFIRM"]:format(snippet.Name)
				end
				
				return false
			end,
		},
		
		error = {
			order = 10,
			type = "description",
			name = function(info)
				local snippet = getSnippetSettings(info)
				
				local func, err = loadstring(snippet.Code, "")
				
				if func then
					return ""
				else
					err = err:gsub("%[string \"\"%]", "line")
					local line = tonumber(err:match("line:(%d+):"))
					
					local code = snippet.Code
					code = code:gsub("\r\n", "\n"):gsub("\r", "\n")
					local lineText = select(line, strsplit("\n", code)) or ""
					
					lineText = lineText:trim(" \t\r\n")
					if #lineText > 25 then
						lineText = lineText:sub(1, 25) .. "..."
					end
					
					return "|cffee0000ERROR: " .. err:gsub("line:(%d+):", "line %1 (\"" .. lineText .. "\"):")
				end
			end,
		},
		
		Code = {
			name = L["CODESNIPPET_CODE"],
			desc = L["CODESNIPPET_CODE_DESC"],
			type = "input",
			width = "full",
			multiline = 20,
			order = 11,
		},
		
		delete = {
			name = L["CODESNIPPET_DELETE"],
			desc = L["CODESNIPPET_DELETE_DESC"],
			type = "execute",
			order = 20,
			func = function(info)
				local snippet, scope, id = getSnippetSettings(info)
				
				SNIPPETS:DeleteSnippet(scope, id)
				
				TMW.ACEOPTIONS:LoadConfigPath(info, "snippets", scope) -- might need to happen before we delete the snippet?
				
				TMW.ACEOPTIONS:CompileOptions()
				TMW:Update()
			end,
			confirm = function(info)
				local snippet = getSnippetSettings(info)
			
				if snippet.Code:trim() == "" then
					return false
				elseif IsControlKeyDown() then
					return false
				end
				
				return L["CODESNIPPET_DELETE_CONFIRM"]:format(snippet.Name)
			end,
		},
		
		ImportExport = TMW.importExportBoxTemplate,
	},
}

local addSnippetButton = {
	name = L["CODESNIPPET_ADD"],
	type = "execute",
	width = "full",
	order = 1,
	func = function(info)
		local scope = info[#info-1]
		
		SNIPPETS:AddSnippet(scope)
		
		TMW.ACEOPTIONS:LoadConfigPath(info, "snippets", scope) -- might need to happen before we add the snippet?
		
		TMW.ACEOPTIONS:CompileOptions()
		TMW:Update()
	end,
}
local snippetDesc = {
	order = 0,
	type = "description",
	name = L["CODESNIPPETS_DESC"] .. "\r\n\r\n",
}

local allSnippets = {
	type = "group",
	name = L["CODESNIPPETS_TITLE"],
	order = 50,
	args = {
		desc = snippetDesc,
		
		global = {
			type = "group",
			name = L["CODESNIPPET_GLOBAL"],
			order = 1,
			args = {
				desc = snippetDesc,
				addSnippet = addSnippetButton,
			},
		},
		profile = {
			type = "group",
			name = L["CODESNIPPET_PROFILE"],
			order = 2,
			args = {
				desc = snippetDesc,
				addSnippet = addSnippetButton,
			},
		},
	},
}


TMW:RegisterCallback("TMW_CONFIG_MAIN_OPTIONS_COMPILE", function(event, OptionsTable)
	OptionsTable.args.snippets = allSnippets
		
	for n, scope in TMW:Vararg("global", "profile") do
		local settingsParent = allSnippets.args[scope]
		
		for k, v in pairs(settingsParent.args) do
			if v == snippetTemplate then
				settingsParent.args[k] = nil
			end
		end
		
		for k = 1, TMW.db[scope].CodeSnippets.n do
			settingsParent.args["#Snippet " .. k] = snippetTemplate
		end
	end
	
end)

function SNIPPETS:AddSnippet(scope)
	local parent = TMW.db[scope].CodeSnippets
	parent.n = parent.n + 1
	
	return parent[parent.n]
end

function SNIPPETS:DeleteSnippet(scope, id)
	local parent = TMW.db[scope].CodeSnippets
	
	tremove(parent, id)
	
	parent.n = parent.n - 1
end






-- -----------------------
-- IMPORT/EXPORT
-- -----------------------

local codesnippet = TMW.Classes.SharableDataType:New("codesnippet", 20)

function codesnippet:Import_ImportData(Item, domain)
	assert(type(domain) == "string")
	
	local snippet = SNIPPETS:AddSnippet(domain)
	
	TMW:CopyTableInPlaceWithMeta(Item.Settings, snippet, true)

	local version = Item.Version
	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("codesnippet", version, snippet)
		end
	end
	
	TMW:Update()
end

function codesnippet:Import_CreateMenuEntry(info, Item)
	info.text = Item.Settings.Name or L["CODESNIPPETS_DEFAULTNAME"]
end


-- Profile Snippets
local SharableDataType_profile = TMW.Classes.SharableDataType.types.profile
SharableDataType_profile:RegisterMenuBuilder(19, function(Item_profile)

	if Item_profile.Settings.CodeSnippets then
		local SettingsBundle = TMW.Classes.SettingsBundle:New("codesnippet")

		for n, snippet in TMW:InNLengthTable(Item_profile.Settings.CodeSnippets) do
			if snippet then

				local Item = TMW.Classes.SettingsItem:New("codesnippet")

				Item:SetParent(Item_profile)
				Item.Settings = snippet

				SettingsBundle:Add(Item)

			end
		end

		if SettingsBundle:CreateParentedMenuEntry(L["CODESNIPPETS"]) then
			TMW.AddDropdownSpacer()
		end
	end
end)

-- Import Snippet
codesnippet:RegisterMenuBuilder(1, function(Item_codesnippet)	
	local IMPORTS, EXPORTS = Item_codesnippet:GetEditBox():GetAvailableImportExportTypes()
	
	-- Import as global snippet
	if IMPORTS.codesnippet_global then
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["CODESNIPPETS_IMPORT_GLOBAL"]
		info.tooltipTitle = info.text
		info.tooltipText = L["CODESNIPPETS_IMPORT_GLOBAL_DESC"]
		info.tooltipOnButton = true
		info.notCheckable = true
		
		info.func = function()
			Item_codesnippet:Import("global")
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
	
	-- Import as profile snippet
	if IMPORTS.codesnippet_profile then
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["CODESNIPPETS_IMPORT_PROFILE"]
		info.tooltipTitle = info.text
		info.tooltipText = L["CODESNIPPETS_IMPORT_PROFILE_DESC"]
		info.tooltipOnButton = true
		info.notCheckable = true
		
		info.func = function()
			Item_codesnippet:Import("profile")
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end)


codesnippet.Export_DescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("6.2.0+")

function codesnippet:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local settings = EXPORTS[self.type]
	
	local text = L["fCODESNIPPET"]:format(settings.Name)
	info.text = text
	info.tooltipTitle = text
end

function codesnippet:Export_GetArgs(editbox)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	
	local settings = EXPORTS[self.type]
	
	-- settings, defaults, ...
	return settings, SNIPPETS.Snippet_Defaults["**"]
end


TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	
	import.codesnippet_global = true
	import.codesnippet_profile = true
	
	if editbox.IsImportExportWidget then
		local info = editbox.obj.userdata
		
		export.codesnippet = getSnippetSettings(info)
	end
end)

