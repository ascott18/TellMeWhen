-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

TMW.WidthCol1 = 170

---------- Libraries ----------
local LSM = LibStub("LibSharedMedia-3.0")
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
LibStub("AceSerializer-3.0"):Embed(TMW)


---------- Upvalues ----------
local TMW = TMW
local db = TMW.db
local L = TMW.L
local GetSpellInfo, GetContainerItemID, GetContainerItemLink =
	  GetSpellInfo, GetContainerItemID, GetContainerItemLink
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next
local strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower, floor, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower, floor, log10
local _G, GetTime = _G, GetTime
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures
local print = TMW.print
local Types = TMW.Types
local ME, CNDT, IE, SUG, ID, SND, ANN, HELP, HIST
local CNDT = TMW.CNDT -- created in TellMeWhen/conditions.lua


---------- Locals ----------
local _, pclass = UnitClass("Player")
local tiptemp = {}
local approachTable, get

---------- Globals ----------
BINDING_HEADER_TELLMEWHEN = L["ICON_TOOLTIP1"] 
BINDING_NAME_TELLMEWHEN_ICONEDITOR_UNDO = L["UNDO_ICON"] 
BINDING_NAME_TELLMEWHEN_ICONEDITOR_REDO = L["REDO_ICON"] 


---------- Data ----------
local points = {
	TOPLEFT = L["TOPLEFT"],
	TOP = L["TOP"],
	TOPRIGHT = L["TOPRIGHT"],
	LEFT = L["LEFT"],
	CENTER = L["CENTER"],
	RIGHT = L["RIGHT"],
	BOTTOMLEFT = L["BOTTOMLEFT"],
	BOTTOM = L["BOTTOM"],
	BOTTOMRIGHT = L["BOTTOMRIGHT"],
}
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

local EquivFullIDLookup = {}
local EquivFullNameLookup = {}
local EquivFirstIDLookup = {}
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do

		-- create the lookup tables first, so that we can have the first ID even if it will be turned into a name
		EquivFirstIDLookup[equiv] = strsplit(";", str) -- this is used to display them in the list (tooltip, name, id display)

		EquivFullIDLookup[equiv] = ";" .. str
		local tbl = TMW:SplitNames(str)
		for k, v in pairs(tbl) do
			tbl[k] = GetSpellInfo(v) or v
		end
		EquivFullNameLookup[equiv] = ";" .. table.concat(tbl, ";")
	end
end
for dispeltype, icon in pairs(TMW.DS) do
	EquivFirstIDLookup[dispeltype] = icon
end


---------- Miscellaneous ----------
TMW.Backupdb = CopyTable(TellMeWhenDB)
TMW.BackupDate = date("%I:%M:%S %p")

TMW.CI = setmetatable({}, {__index = function(tbl, k)
	if k == "ics" then
		-- take no chances with errors occuring here
		return tbl.ic and tbl.ic:GetSettings()
	elseif k == "gs" then
		-- take no chances with errors occuring here
		return approachTable(TMW.db, "profile", "Groups", tbl.g)
	elseif k == "SoI" then -- spell or item
		local ics = tbl.ics
		if ics and ics.Type == "item" then
			return "item"
		end
		return "spell"
	end
end}) local CI = TMW.CI		--current icon

local DEFAULT_ICON_SETTINGS = db.profile.Groups[0].Icons[0]
db.profile.Groups[0] = nil



-- ----------------------
-- WOW API HOOKS
-- ----------------------

GameTooltip.TMW_OldAddLine = GameTooltip.AddLine
function GameTooltip:AddLine(text, r, g, b, wrap, ...)
	-- this fixes the problem where tooltips in blizz dropdowns dont wrap, nor do they have a setting to do it.
	-- Pretty hackey fix, but it works
	-- Only force the wrap option if the current dropdown has wrapTooltips set true, the dropdown is shown, and the mouse is over the dropdown menu (not DDL.isCounting)
	local DDL = DropDownList1
	if DDL and not DDL.isCounting and DDL.dropdown and DDL.dropdown.wrapTooltips and DDL:IsShown() then
		wrap = 1
	end
	self:TMW_OldAddLine(text, r, g, b, wrap, ...)
end

function GameTooltip:TMW_SetEquiv(equiv)
	GameTooltip:AddLine(L[equiv], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(IE:Equiv_GenerateTips(equiv), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
end

local old_ChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(...)
	-- attempt to extract data from shift-clicking things (chat links, spells, items, etc) and insert it into the icon editor
	local text = ...
	local Type, id = strmatch(text, "|H(.-):(%d+)")
	if not id then return false end
	
	if ANN.EditBox:HasFocus() then
		-- just flat out put the link into the ANN editbox if it is focued. The ability to yell out clickable links is cool.
		ANN.EditBox:Insert(text)
	
		-- notify success
		return true
	elseif IE.Main.Name:HasFocus() then
		if CI.t == "item" and Type ~= "item" then
			-- notify failure if the icon is an item cooldown icon and the link is not an item link
			return false
		elseif CI.t ~= "item" and Type ~= "spell" and Type ~= "enchant" then
			-- notify failure if the icon is not an item cooldown and the link isn't a spell or enchant link
			-- DONT just check (CI.t ~= "item" and Type == "item") because there are link types we want to exclude, like achievements.
			return false
		end
		
		-- fun text insertion code
		local Name = IE.Main.Name
		
		-- find the next semicolon in the string
		local NameText = Name:GetText()
		local start = #NameText
		for i = Name:GetCursorPosition(), start, 1 do
			if strsub(NameText, i, i) == ";" then
				start = i+1
				break
			end
		end
		
		-- put the cursor right after the semicolon
		Name:SetCursorPosition(start)
		-- insert the text
		IE.Main.Name:Insert("; " .. id .. "; ")
		-- clean the text
		TMW:CleanString(IE.Main.Name)
		-- put the cursor after the newly inserted text
		Name:SetCursorPosition(start + #id + 2)
		
		-- notify success
		return true
	elseif IE.Main.CustomTex:HasFocus() then
		-- if the custom texture box is active,
		-- attempt to extract either a spellID or a texture path from the data to use.
		local tex
		if Type == "spell" or Type == "enchant" then
			-- spells and enchants can just use their spellID
			tex = id
		elseif Type == "item" then
			-- items must get the texture path
			tex = GetItemIcon(id)
		elseif Type == "achievement" then
			-- achievements also must get their texture path
			tex = select(10, GetAchievementInfo(id))
		end
		if tex then
			-- clean off the first part of the path, it does not need to be saved
			-- it will be appended when the texture is used.
			tex = gsub(tex, "INTERFACE\\ICONS\\", "")
			tex = gsub(tex, "Interface\\Icons\\", "")
			
			-- set the text
			IE.Main.CustomTex:SetText(tex)
			
			-- notify success
			return true
		end
	end
	return old_ChatEdit_InsertLink(...)
end



-- ----------------------
-- GENERAL CONFIG FUNCTIONS
-- ----------------------

function approachTable(t, ...)
	for i=1, select("#", ...) do
		local k = select(i, ...)
		if type(k) == "function" then
			t = k(t)
		else
			t = t[k]
		end
		if not t then return end
	end
	return t
end

function get(value, ...)
	local type = type(value)
	if type == "function" then
		return value(...)
	elseif type == "table" then
		return value[...]
	else
		return value
	end
end


---------- Tooltips ----------
local function TTOnEnter(self)
	if self.__title or self.__text then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(get(self.__title), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
		GameTooltip:AddLine(get(self.__text), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, not self.__noWrapTooltipText)
		GameTooltip:Show()
	end
end
local function TTOnLeave(self)
	GameTooltip:Hide()
end
function TMW:TT(f, title, text, actualtitle, actualtext)
	-- setting actualtitle or actualtext true cause it to use exactly what is passed in for title or text as the text in the tooltip
	-- if these variables arent set, then it will attempt to see if the string is a global variable (e.g. "MAXIMUM")
	-- if they arent set and it isnt a global, then it must be a TMW localized string, so use that
	if title then
		f.__title = (actualtitle and title) or _G[title] or L[title]
	else
		f.__title = title
	end
	
	if text then
		f.__text = (actualtext and text) or _G[text] or L[text]
	else
		f.__text = text
	end
	
	if not f.__ttHooked then
		f.__ttHooked = 1
		f:HookScript("OnEnter", TTOnEnter)
		f:HookScript("OnLeave", TTOnLeave)
	else
		if not f:GetScript("OnEnter") then
			f:HookScript("OnEnter", TTOnEnter)
		end
		if not f:GetScript("OnLeave") then
			f:HookScript("OnLeave", TTOnLeave)
		end
	end
end


---------- Table Copying ----------
function TMW:CopyWithMetatable(settings)
	local copy = {}
	for k, v in pairs(settings) do
		if type(v) == "table" then
			copy[k] = TMW:CopyWithMetatable(v)
		else
			copy[k] = v
		end
	end
	return setmetatable(copy, getmetatable(settings))
end

function TMW:CopyTableInPlaceWithMeta(src, dest)
	--src and dest must have congruent data structure, otherwise shit will blow up. There are no safety checks to prevent this.
	local metatemp = getmetatable(src) -- lets not go overwriting random metatables
	setmetatable(src, getmetatable(dest))
	for k in pairs(src) do
		if dest[k] and type(dest[k]) == "table" and type(src[k]) == "table" then
			TMW:CopyTableInPlaceWithMeta(src[k], dest[k])
		elseif type(src[k]) ~= "table" then
			dest[k] = src[k]
		end
	end
	setmetatable(src, metatemp) -- restore the old metatable
	return dest -- not really needed, but what the hell why not
end


---------- Icon Utilities ----------
function TMW:GetIconMenuText(g, i, data)
	data = data or db.profile.Groups[tonumber(g)].Icons[tonumber(i)]

	local Type = data.Type or ""
	local typeData = Types[Type]
	
	local text, tooltip = typeData:GetIconMenuText(data)
	
	text = text == "" and L["UNNAMED"] or text
	local textshort = strsub(text, 1, 35)
	if strlen(text) > 35 then textshort = textshort .. "..." end

	tooltip =	tooltip ..
				((Types[Type].name) or "") ..
				((data.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")

	return text, textshort, tooltip
end

function TMW:GuessIconTexture(data)
	local tex = nil
	if (data.Name and data.Name ~= "" and data.Type ~= "meta" and data.Type ~= "wpnenchant" and data.Type ~= "runes") and not tex then
		local name = data.CustomTex or TMW:GetSpellNames(nil, data.Name, 1)
		if name then
			if data.Type == "item" then
				tex = GetItemIcon(name) or tex
			else
				tex = SpellTextures[name]
			end
		end
	end
	if data.Type == "cast" and not tex then tex = "Interface\\Icons\\Temp"
	elseif data.Type == "buff" and not tex then tex = "Interface\\Icons\\INV_Misc_PocketWatch_01"
	elseif data.Type == "meta" and not tex then tex = "Interface\\Icons\\LevelUpIcon-LFD"
	elseif data.Type == "runes" and not tex then tex = "Interface\\Icons\\Spell_Deathknight_BloodPresence"
	elseif data.Type == "wpnenchant" and not tex then tex = GetInventoryItemTexture("player", GetInventorySlotInfo(data.WpnEnchantType or "MainHandSlot")) or GetInventoryItemTexture("player", "MainHandSlot") end
	if not tex then tex = "Interface\\Icons\\INV_Misc_QuestionMark" end
	return tex
end


---------- Dropdown Utilities ----------
function TMW:SetUIDropdownText(frame, value, tbl)
	if frame.selectedValue ~= value or not frame.selectedValue then
		UIDropDownMenu_SetSelectedValue(frame, value)
	end

	if tbl == CNDT.Types then
		frame:GetParent():TypeCheck(CNDT.ConditionsByType[value])
	elseif tbl == TMW.Icons then
		for k, v in pairs(tbl) do
			if v == value then
				UIDropDownMenu_SetText(frame, TMW:GetIconMenuText(nil, nil, _G[v]))
				return _G[v]
			end
		end
		local gID, iID = strmatch(value, "(%d+).*(%d+)")
		if gID and iID then
			UIDropDownMenu_SetText(frame, format(L["GROUPICON"], TMW:GetGroupName(gID, gID, 1), iID))
			return
		end
	end
	for k, v in pairs(tbl) do
		if v.value == value then
			UIDropDownMenu_SetText(frame, v.text)
			return v
		end
	end
	UIDropDownMenu_SetText(frame, "")
end

local function AddDropdownSpacer()
	local info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end



-- --------------
-- MAIN OPTIONS
-- --------------

---------- Data/Templates ----------
local function findid(info)
	for i = #info, 1, -1 do
		local n = tonumber(strmatch(info[i], "Group (%d+)"))
		if n then return n end
	end
end
local checkorder = {
	-- NOTE: these are actually backwards so they sort logically in AceConfig, but have their signs switched in the actual function (1 = -1; -1 = 1).
	[-1] = L["ASCENDING"],
	[1] = L["DESCENDING"],
}
local fontorder = {
	Count = 40,
	Bind = 50,
}
local fontDisabled = function(info)
	if not LMB then
		return false
	end
	return not db.profile.Groups[findid(info)].Fonts[info[#info-1]].OverrideLBFPos
end
local importExportBoxTemplate = {
	name = L["IMPORT_EXPORT"],
	type = "input",
	order = 200,
	width = "full",
	dialogControl = "TMW-ImportExport",
	get = function() end,
	set = function() end,
	--hidden = function() return IE.ExportBox:IsVisible() end,
}
local groupFontConfigTemplate = {
	type = "group",
	name = function(info) return L["UIPANEL_FONT_" .. info[#info]] end,
	order = function(info) return fontorder[info[#info]] end,
	set = function(info, val)
		local g = findid(info)
		db.profile.Groups[g].Fonts[info[#info-1]][info[#info]] = val
		if info[#info-1] == "Count" then
			TMW[g].FontTest = 1
		end
		TMW:Group_Update(g)
	end,
	get = function(info)
		return db.profile.Groups[findid(info)].Fonts[info[#info-1]][info[#info]]
	end,
	args = {
		Name = {
			name = L["UIPANEL_FONTFACE"],
			desc = L["UIPANEL_FONT_DESC"],
			type = "select",
			order = 1,
			dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"),
		},
		Outline = {
			name = L["UIPANEL_FONT_OUTLINE"],
			desc = L["UIPANEL_FONT_OUTLINE_DESC"],
			type = "select",
			values = {
				[""] = L["OUTLINE_NO"],
				OUTLINE = L["OUTLINE_THIN"],
				THICKOUTLINE = L["OUTLINE_THICK"],
				MONOCHORME = L["OUTLINE_MONOCHORME"],
			},
			style = "dropdown",
			order = 5,
		},
		Size = {
			name = L["UIPANEL_FONT_SIZE"],
			desc = L["UIPANEL_FONT_SIZE_DESC"],
			type = "range",
			order = 9,
			min = 6,
			softMax = 26,
			step = 1,
			bigStep = 1,
		},
		point = {
			name = L["UIPANEL_POINT"],
			type = "select",
			values = points,
			style = "dropdown",
			order = 10,
			disabled = fontDisabled,
		},
		relativePoint = {
			name = L["UIPANEL_RELATIVEPOINT"],
			type = "select",
			values = points,
			style = "dropdown",
			order = 13,
			disabled = fontDisabled,
		},
		ConstrainWidth = {
			name = L["UIPANEL_FONT_CONSTRAINWIDTH"],
			desc = L["UIPANEL_FONT_CONSTRAINWIDTH_DESC"],
			type = "toggle",
			order = 15,
		},
		x = {
			name = L["UIPANEL_FONT_XOFFS"],
			type = "range",
			order = 20,
			min = -30,
			max = 30,
			step = 1,
			bigStep = 1,
			disabled = fontDisabled,
		},
		y = {
			name = L["UIPANEL_FONT_YOFFS"],
			type = "range",
			order = 21,
			min = -30,
			max = 30,
			step = 1,
			bigStep = 1,
			disabled = fontDisabled,
		},
		OverrideLBFPos = {
			name = L["UIPANEL_FONT_OVERRIDELBF"],
			desc = L["UIPANEL_FONT_OVERRIDELBF_DESC"],
			type = "toggle",
			width = "double",
			order = 50,
			hidden = not (LMB),
		},
	},
}
local groupConfigTemplate = {
	type = "group",
	childGroups = "tab",
	name = function(info) local g=findid(info) return TMW:GetGroupName(g, g) end,
	order = function(info) return findid(info) end,
	args = {
		main = {
			type = "group",
			name = L["MAIN"],
			order = 1,
			args = {
				Enabled = {
					name = L["UIPANEL_ENABLEGROUP"],
					desc = L["UIPANEL_TOOLTIP_ENABLEGROUP"],
					type = "toggle",
					order = 1,
				},
				Name = {
					name = L["UIPANEL_GROUPNAME"],
					type = "input",
					order = 2,
					width = "double",
					set = function(info, val)
						local g = findid(info)
						db.profile.Groups[g].Name = strtrim(val)
						TMW:Group_Update(g)
					end,
				},
				OnlyInCombat = {
					name = L["UIPANEL_ONLYINCOMBAT"],
					desc = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"],
					type = "toggle",
					order = 3,
				},
				PrimarySpec = {
					name = L["UIPANEL_PRIMARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_PRIMARYSPEC"],
					type = "toggle",
					order = 6,
				},
				SecondarySpec = {
					name = L["UIPANEL_SECONDARYSPEC"],
					desc = L["UIPANEL_TOOLTIP_SECONDARYSPEC"],
					type = "toggle",
					order = 7,
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
				Spacing = {
					name = L["UIPANEL_ICONSPACING"],
					desc = L["UIPANEL_ICONSPACING_DESC"],
					type = "range",
					order = 22,
					min = -5,
					softMax = 20,
					step = 0.1,
					bigStep = 1,
				},
				CheckOrder = {
					name = L["CHECKORDER"],
					desc = L["CHECKORDER_ICONDESC"],
					type = "select",
					values = checkorder,
					style = "dropdown",
					order = 24,
				},
				delete = {
					name = L["UIPANEL_DELGROUP"],
					desc = L["UIPANEL_DELGROUP_DESC"],
					type = "execute",
					order = 50,
					func = function(info)
						TMW:Group_Delete(findid(info))
					end,
					disabled = function()
						return db.profile.NumGroups == 1
					end,
					confirm = function(info)
						if IsControlKeyDown() then
							return false
						elseif TMW:Group_HasIconData(findid(info)) then
							return true
						end
						return false
					end,
				},
				ImportExport = importExportBoxTemplate,
			},
		},
		Count = groupFontConfigTemplate,
		Bind = groupFontConfigTemplate,
		position = {
			type = "group",
			order = 2,
			name = L["UIPANEL_POSITION"],
			set = function(info, val)
				local g = findid(info)
				db.profile.Groups[g].Point[info[#info]] = val
				TMW[g]:SetPos()
			end,
			get = function(info)
				return db.profile.Groups[findid(info)].Point[info[#info]]
			end,
			args = {
				point = {
					name = L["UIPANEL_POINT"],
					type = "select",
					values = points,
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
					type = "select",
					values = points,
					style = "dropdown",
					order = 3,
				},
				x = {
					name = L["UIPANEL_FONT_XOFFS"],
					type = "range",
					order = 4,
					softMin = -500,
					softMax = 500,
					step = 1,
					bigStep = 1,
				},
				y = {
					name = L["UIPANEL_FONT_YOFFS"],
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
						db.profile.Groups[g].Scale = val
						TMW[g]:SetPos()
					end,
					get = function(info) return db.profile.Groups[findid(info)].Scale end,
				},
				Level = {
					name = L["UIPANEL_LEVEL"],
					type = "range",
					order = 7,
					min = 1,
					softMax = 100,
					step = 1,
					set = function(info, val)
						local g = findid(info)
						db.profile.Groups[g].Level = val
						TMW[g]:SetPos()
					end,
					get = function(info) return db.profile.Groups[findid(info)].Level end,
				},
				Strata = {
					name = L["UIPANEL_STRATA"],
					type = "select",
					style = "dropdown",
					order = 8,
					set = function(info, val)
						local g = findid(info)
						db.profile.Groups[g].Strata = stratas[val]
						TMW[g]:SetPos()
					end,
					get = function(info)
						local val = db.profile.Groups[findid(info)].Strata
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
						db.profile.Groups[g].Locked = val
						TMW:Group_Update(g)
					end,
					get = function(info) return db.profile.Groups[findid(info)].Locked end
				},
				reset = {
					name = L["UIPANEL_GROUPRESET"],
					desc = L["UIPANEL_TOOLTIP_GROUPRESET"],
					type = "execute",
					order = 50,
					func = function(info) TMW:Group_ResetPosition(findid(info)) end
				},
			},
		},
	}
}

local colorOrder = {
	"CBS",
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
				return order
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
				local WhenChecks = TMW.Types[info[#info-2]].WhenChecks
				local fmt = WhenChecks and WhenChecks.text or L["ICONMENU_SHOWWHEN"]
				
				return L["COLOR_" .. info[#info-1] .. "_DESC"]:format(fmt)
			end,
			type = "color",
			order = 2,
			--width = "double",
			hasAlpha = false,
			set = function(info, r, g, b, a)
				local c = db.profile.Colors[info[#info-2]][info[#info-1]]
				
				c.r = r c.g = g c.b = b c.a = a
				c.Override = true
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				local base = db.profile.Colors[info[#info-2]][info[#info-1]]
				local c = base
				if not base.Override then
				--	c = db.profile.Colors["GLOBAL"][info[#info-1]] -- i don't like this. too confusing to see the color change when checking and unchecking the setting
				end
				
				return c.r, c.g, c.b, c.a
			end,
			disabled = function(info)
				return not db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL"
			end
		},
		override = {
			name = L["COLOR_OVERRIDEDEFAULT"],
			desc = L["COLOR_OVERRIDEDEFAULT_DESC"],
			type = "toggle",
			width = "half",
			order = 1,
			set = function(info, val)
				db.profile.Colors[info[#info-2]][info[#info-1]].Override = val
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				return db.profile.Colors[info[#info-2]][info[#info-1]].Override
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
				db.profile.Colors[info[#info-2]][info[#info-1]].Gray = val
				TMW.Types[info[#info-2]]:UpdateColors()
			end,
			get = function(info)
				return db.profile.Colors[info[#info-2]][info[#info-1]].Gray
			end,
			disabled = function(info)
				return strsub(info[#info-1], 1, 2) == "CB" or (not db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL")
			end
		},
		reset = {
			name = RESET,
			desc = L["COLOR_RESET_DESC"],
			type = "execute",
			width = "half",
			order = 10,
			func = function(info)
				db.profile.Colors[info[#info-2]][info[#info-1]] = CopyTable(TellMeWhen.Defaults.profile.Colors["**"][info[#info-1]])
			end,
		--[=[	disabled = function(info)
				return not db.profile.Colors[info[#info-2]][info[#info-1]].Override and info[#info-2] ~= "GLOBAL"
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
		
		for order, type in pairs(TMW.OrderedTypes) do
			if type.type == this then
				return order
			end
		end
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
					t = L["COLOR_HEADER"]:format(TMW.Types[this].name)
				end
				return t .. "\r\n"
			end,
		}
	}
}

for k, v in pairs(colorOrder) do
	if strsub(v, 1, 2) == "CB" then
		colorIconTypeTemplate.args[v] = CopyTable(colorTemplate)
		colorIconTypeTemplate.args[v].args.color.hasAlpha = true
	else
		colorIconTypeTemplate.args[v] = colorTemplate
	end
end

for i = 1, GetNumTalentTabs() do
	local _, name = GetTalentTabInfo(i)
	groupConfigTemplate.args.main.args["Tree"..i] = {
		type = "toggle",
		name = name,
		desc = L["UIPANEL_TREE_DESC"],
		order = 7+i,
	}
end


---------- Options Table Compilation ----------
function TMW:CompileOptions()
	if not TMW.OptionsTable then
		TMW.OptionsTable = {
			name = L["ICON_TOOLTIP1"] .. " " .. TELLMEWHEN_VERSION_FULL,
			type = "group",
			args = {
				main = {
					type = "group",
					name = L["UIPANEL_MAINOPT"],
					order = 1,
					set = function(info, val)
						db.profile[info[#info]] = val
						TMW:Update()
					end,
					get = function(info) return db.profile[info[#info]] end,
					args = {
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
								BarGCD = {
									name = L["UIPANEL_BARIGNOREGCD"],
									desc = L["UIPANEL_BARIGNOREGCD_DESC"],
									type = "toggle",
									order = 21,
								},
								ClockGCD = {
									name = L["UIPANEL_CLOCKIGNOREGCD"],
									desc = L["UIPANEL_CLOCKIGNOREGCD_DESC"],
									type = "toggle",
									order = 22,
								},
								DrawEdge = {
									name = L["UIPANEL_DRAWEDGE"],
									desc = L["UIPANEL_DRAWEDGE_DESC"],
									type = "toggle",
									order = 40,
								},
								MasterSound = {
									name = L["SOUND_USEMASTER"],
									desc = L["SOUND_USEMASTER_DESC"],
									type = "toggle",
									order = 41,
								},
								WarnInvalids = {
									name = L["UIPANEL_WARNINVALIDS"],
									type = "toggle",
									order = 50,
								},
								ReceiveComm = {
									name = L["ALLOWCOMM"],
									type = "toggle",
									order = 51,
								},
								VersionWarning = {
									name = L["ALLOWVERSIONWARN"],
									type = "toggle",
									order = 52,
									set = function(info, val)
										db.global[info[#info]] = val
									end,
									get = function(info) return db.global[info[#info]] end,
								},
							},
						},
						CheckOrder = {
							name = L["CHECKORDER"],
							desc = L["CHECKORDER_GROUPDESC"],
							type = "select",
							values = checkorder,
							style = "dropdown",
							order = 30,
						},
						resetall = {
							name = L["UIPANEL_ALLRESET"],
							desc = L["UIPANEL_TOOLTIP_ALLRESET"],
							type = "execute",
							order = 51,
							confirm = true,
							func = function() db:ResetProfile() end,
						},
						importexport = importExportBoxTemplate,
						Colors = {
							type = "group",
							name = L["UIPANEL_COLORS"],
							order = 3,
							childGroups = "tree",
							args = {},
						},
						--[==[coloropts = {
							type = "group",
							name = L["UIPANEL_COLORS"],
							order = 3,
							set = function(info, r, g, b, a) local c = db.profile[info[#info]] c.r = r c.g = g c.b = b c.a = a end,
							get = function(info) local c = db.profile[info[#info]] return c.r, c.g, c.b, c.a end,
							args = {
								CDSTColor = {
									name = L["UIPANEL_COLOR_STARTED"],
									desc = L["UIPANEL_COLOR_STARTED_DESC"],
									type = "color",
									order = 31,
									hasAlpha = true,
								},
						--		AOA = colorTemplate,
								CDCOColor = {
									name = L["UIPANEL_COLOR_COMPLETE"],
									desc = L["UIPANEL_COLOR_COMPLETE_DESC"],
									type = "color",
									order = 32,
									hasAlpha = true,
								},
								OORColor = {
									name = L["UIPANEL_COLOR_OOR"],
									desc = L["UIPANEL_COLOR_OOR_DESC"],
									type = "color",
									order = 37,
									hasAlpha = true,
								},
								OOMColor = {
									name = L["UIPANEL_COLOR_OOM"],
									desc = L["UIPANEL_COLOR_OOM_DESC"],
									type = "color",
									order = 38,
									hasAlpha = true,
								},
								desc = {
									name = L["UIPANEL_COLOR_DESC"],
									type = "description",
									order = 40,
								},
								PRESENTColor = {
									name = L["UIPANEL_COLOR_PRESENT"],
									desc = L["UIPANEL_COLOR_PRESENT_DESC"],
									type = "color",
									order = 45,
									hasAlpha = false,
								},
								ABSENTColor = {
									name = L["UIPANEL_COLOR_ABSENT"],
									desc = L["UIPANEL_COLOR_ABSENT_DESC"],
									type = "color",
									order = 47,
									hasAlpha = false,
								},
							},]==]
					},
				},
				groups = {
					type = "group",
					name = L["UIPANEL_GROUPS"],
					order = 2,
					set = function(info, val)
						local g = findid(info)
						db.profile.Groups[g][info[#info]] = val
						TMW:Group_Update(g)
					end,
					get = function(info) return db.profile.Groups[findid(info)][info[#info]] end,
					args = {
						addgroupgroup = {
							type = "group",
							name = L["UIPANEL_ADDGROUP"],
							args = {
								addgroup = {
									name = L["UIPANEL_ADDGROUP"],
									desc = L["UIPANEL_ADDGROUP_DESC"],
									type = "execute",
									order = 41,
									handler = TMW,
									func = "Group_Add",
								},
								importexport = importExportBoxTemplate,
							},
						},
					},
				},
			},
		}
		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
		TMW.OptionsTable.args.profiles.args = CopyTable(TMW.OptionsTable.args.profiles.args) -- dont copy the entire table because it contains a reference to db ... and will copy the entire db.
		TMW.OptionsTable.args.profiles.args.importexportdesc = {
			order = 90,
			type = "description",
			name = "\r\n" .. L["IMPORT_EXPORT_DESC_INLINE"],
			--hidden = function() return IE.ExportBox:IsVisible() end,
		}
		TMW.OptionsTable.args.profiles.args.importexport = importExportBoxTemplate
	end


	for k, v in pairs(TMW.OptionsTable.args.groups.args) do
		if strfind(k, "Group %d+") then -- protect ["addgroup"] and any other future settings in the group header
			TMW.OptionsTable.args.groups.args[k] = nil
		end
	end

	for g = 1, TELLMEWHEN_MAXGROUPS do
		TMW.OptionsTable.args.groups.args["Group " .. g] = groupConfigTemplate
	end
	TMW.OptionsTable.args.groups.args.addgroupgroup.order = TELLMEWHEN_MAXGROUPS + 1
	
	TMW.OptionsTable.args.main.args.Colors.args.GLOBAL = colorIconTypeTemplate
	for k, Type in pairs(TMW.Types) do
		if not Type.NoColorSettings then
			TMW.OptionsTable.args.main.args.Colors.args[k] = colorIconTypeTemplate
		end
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW Options", TMW.OptionsTable)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("TMW Options", 781, 512)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW IEOptions", TMW.OptionsTable)
	if not TMW.AddedToBlizz then
		TMW.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TMW Options", L["ICON_TOOLTIP1"])
	end
end



-- -------------
-- GROUP CONFIG
-- -------------

---------- Position ----------
local Ruler = CreateFrame("Frame")
local function GetAnchoredPoints(group)
	local p = TMW.db.profile.Groups[group:GetID()].Point

	local relframe = _G[p.relativeTo] or UIParent
	local point, relativePoint = p.point, p.relativePoint
	
	if relframe == UIParent then
		-- use the smart anchor points provided by UIParent anchoring if it is being used
		local _
		point, _, relativePoint = group:GetPoint(1)
	end

	Ruler:ClearAllPoints()
	Ruler:SetPoint("TOPLEFT", group, point)
	Ruler:SetPoint("BOTTOMRIGHT", relframe, relativePoint)

	local X = Ruler:GetWidth()/UIParent:GetScale()/group:GetScale()
	local Y = Ruler:GetHeight()/UIParent:GetScale()/group:GetScale()
	return point, relframe:GetName(), relativePoint, -X, Y
end

local function Group_SizeUpdate(resizeButton)
	local uiScale = UIParent:GetScale()
	local group = resizeButton:GetParent()
	local cursorX, cursorY = GetCursorPosition()

	-- calculate new scale
	local newXScale = group.oldScale * (cursorX/uiScale - group.oldX*group.oldScale) / (resizeButton.oldCursorX/uiScale - group.oldX*group.oldScale)
	local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (resizeButton.oldCursorY/uiScale - group.oldY*group.oldScale)
	local newScale = max(0.6, newXScale, newYScale)
	group:SetScale(newScale)

	-- calculate new frame position
	local newX = group.oldX * group.oldScale / newScale
	local newY = group.oldY * group.oldScale / newScale
	group:ClearAllPoints()
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
end

function TMW:Group_StartSizing(resizeButton)
	local group = resizeButton:GetParent()
	group.oldScale = group:GetScale()
	resizeButton.oldCursorX, resizeButton.oldCursorY = GetCursorPosition(UIParent)
	group.oldX = group:GetLeft()
	group.oldY = group:GetTop()
	resizeButton:SetScript("OnUpdate", Group_SizeUpdate)
end

function TMW:Group_StopSizing(resizeButton)
	resizeButton:SetScript("OnUpdate", nil)
	local group = resizeButton:GetParent()
	db.profile.Groups[group:GetID()].Scale = group:GetScale()
	local p = db.profile.Groups[group:GetID()].Point
	p.point, p.relativeTo, p.relativePoint, p.x, p.y = GetAnchoredPoints(group)
	group:SetPos()
	IE:NotifyChanges()
end

function TMW:Group_StopMoving(group)
	group:StopMovingOrSizing()
	ID.isMoving = nil
	local p = db.profile.Groups[group:GetID()].Point
	p.point, p.relativeTo, p.relativePoint, p.x, p.y = GetAnchoredPoints(group)
	group:SetPos()
	IE:NotifyChanges()
end

function TMW:Group_ResetPosition(groupID)
	for k, v in pairs(TMW.Group_Defaults.Point) do
		db.profile.Groups[groupID].Point[k] = v
	end
	db.profile.Groups[groupID].Scale = 1
	IE:NotifyChanges()
	TMW:Group_Update(groupID)
end


---------- Add/Delete ----------
function TMW:Group_Delete(groupID)
	if db.profile.NumGroups == 1 then
		return
	end
	
	for id = groupID + 1, db.profile.NumGroups do
		local source = "TellMeWhen_Group" .. id
		local destination = "TellMeWhen_Group" .. id - 1
		
		-- check for groups exactly
	    TMW:ReconcileData(source, destination)
		
		-- check for any icons of a group.
		TMW:ReconcileData(source, destination, source .. "_Icon", destination .. "_Icon")
	end
	
	tremove(db.profile.Groups, groupID)
	db.profile.NumGroups = db.profile.NumGroups - 1
	for k, v in pairs(TMW.Icons) do
		if tonumber(strmatch(v, "TellMeWhen_Group(%d+)")) == groupID then
			TMW:InvalidateIcon(k)
		end
	end
	
	TMW:Update()
	IE:Load()
	TMW:CompileOptions()
	IE:NotifyChanges()
	CloseDropDownMenus()
end

function TMW:Group_Add()
	local groupID = db.profile.NumGroups + 1
	db.profile.NumGroups = groupID
	db.profile.Groups[db.profile.NumGroups].Enabled = true
	TMW:Update()
	
	TMW:Group_Update(groupID)
	TMW:CompileOptions()
	IE:NotifyChanges("groups", "Group " .. groupID)
	return groupID, TMW[groupID]
end


---------- Etc ----------
function TMW:Group_HasIconData(groupID)
	local has = false
	for ics in TMW:InIconSettings(groupID) do
		if not IE:DeepCompare(DEFAULT_ICON_SETTINGS, ics) then
			has = true
			break
		end
	end
	
	return has
end

-- ----------------------
-- ICON DRAGGER
-- ----------------------

ID = TMW:NewModule("IconDragger", "AceTimer-3.0", "AceEvent-3.0") TMW.ID = ID

function ID:OnInitialize()
	hooksecurefunc("PickupSpellBookItem", function(...) ID.DraggingInfo = {...} end)
	WorldFrame:HookScript("OnMouseDown", function() -- this contains other bug fix stuff too
		ID.DraggingInfo = nil
		ID.F:Hide()
		ID.IsDragging = nil
		if ID.isMoving then
			TMW:Group_StopMoving(ID.isMoving)
		end
	end)
	hooksecurefunc("ClearCursor", ID.BAR_HIDEGRID)
	ID:RegisterEvent("PET_BAR_HIDEGRID", "BAR_HIDEGRID")
	ID:RegisterEvent("ACTIONBAR_HIDEGRID", "BAR_HIDEGRID")
	
	
	ID.DD.wrapTooltips = 1
end

function ID:BAR_HIDEGRID()
	ID.DraggingInfo = nil 
end


---------- Spell/Item Dragging ----------
function ID:SpellItemToIcon(icon)
	local t, data, subType
	local input
	if not (CursorHasSpell() or CursorHasItem()) and ID.DraggingInfo then
		t = "spell"
		data, subType = unpack(ID.DraggingInfo)
	else
		t, data, subType = GetCursorInfo()
	end
	ID.DraggingInfo = nil
	
	-- create a backup before doing things
	IE:AttemptBackup(icon)
	
	-- handle the drag based on icon type
	local success = icon.typeData:DragReceived(icon, t, data, subType)
	if not success then
		return
	end
	
	ClearCursor()
	TMW:Icon_Update(icon)
	IE:Load(1)
end


---------- Icon Dragging ----------
function ID:DropDown()
	local info = UIDropDownMenu_CreateInfo()
	info.func = ID.Handler
	info.notCheckable = true
	info.tooltipOnButton = true
	
	if ID.desticon then
		-- Move
		info.text = L["ICONMENU_MOVEHERE"]
		info.tooltipTitle = nil
		info.tooltipText = nil
		info.arg1 = "Move"
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		-- Copy
		info.text = L["ICONMENU_COPYHERE"]
		info.tooltipTitle = nil
		info.tooltipText = nil
		info.arg1 = "Copy"
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		-- Swap
		info.text = L["ICONMENU_SWAPWITH"]
		info.tooltipTitle = nil
		info.tooltipText = nil
		info.arg1 = "Swap"
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		if TMW:IsIconValid(ID.srcicon) then
			-- Condition
			info.text = L["ICONMENU_APPENDCONDT"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			info.arg1 = "Condition"
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Meta
			if ID.desticon.Type == "meta" then
				info.text = L["ICONMENU_ADDMETA"]
				info.tooltipTitle = nil
				info.tooltipText = nil
				info.arg1 = "Meta"
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
	
	-- Anchor
	do
		local name, desc
		
		local srcname = L["fGROUP"]:format(TMW:GetGroupName(ID.srcicon.group:GetID(), ID.srcicon.group:GetID(), 1))
			
		if ID.desticon and ID.srcicon.group:GetID() ~= ID.desticon.group:GetID() then
			local destname = L["fGROUP"]:format(TMW:GetGroupName(ID.desticon.group:GetID(), ID.desticon.group:GetID(), 1))
			name = L["ICONMENU_ANCHORTO"]:format(destname)
			desc = L["ICONMENU_ANCHORTO_DESC"]:format(srcname, destname, destname, srcname)
			
		elseif ID.destFrame then
			if ID.destFrame == WorldFrame and ID.srcicon.group.Point.relativeTo ~= "UIParent" then
				name = L["ICONMENU_ANCHORTO_UIPARENT"]
				desc = L["ICONMENU_ANCHORTO_UIPARENT_DESC"]
				
			elseif ID.destFrame ~= WorldFrame then
				local destname = ID.destFrame:GetName()
				name = L["ICONMENU_ANCHORTO"]:format(destname)
				desc = L["ICONMENU_ANCHORTO_DESC"]:format(srcname, destname, destname, srcname)
			end
		end
	
		if name then
			info.text = name
			info.tooltipTitle = name
			info.tooltipText = desc
			info.arg1 = "Anchor"
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
	
	-- Split
	if ID.destFrame then
		info.text = L["ICONMENU_SPLIT"]
		info.tooltipTitle = L["ICONMENU_SPLIT"]
		info.tooltipText = L["ICONMENU_SPLIT_DESC"]
		info.arg1 = "Split"
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end

	info.text = CANCEL
	info.tooltipTitle = nil
	info.tooltipText = nil
	info.func = nil
	info.arg1 = nil
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	UIDropDownMenu_JustifyText(self, "LEFT")
end

function ID:Start(icon)
	local scale = icon.group:GetScale()*0.85
	ID.F:SetScript("OnUpdate", function()
		local x, y = GetCursorPosition()
		ID.texture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale )
		ID.back:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale )
	end)
	ID.F:SetScale(scale)
	local t = TMW[ID.srcicon.group:GetID()][ID.srcicon:GetID()].texture:GetTexture()
	ID.texture:SetTexture(t)
	if t then
		ID.back:Hide()
	else
		ID.back:Show()
	end
	ID.F:Show()
	ID.IsDragging = true
end

function ID:SetIsDraggingFalse()
	ID.IsDragging = false
end

function ID:CompleteDrag(script, icon)

	ID.F:SetScript("OnUpdate", nil)
	ID.F:Hide()
	ID:ScheduleTimer("SetIsDraggingFalse", 0.1)
	
	icon = icon or GetMouseFocus()
	
	-- icon here is the destination
	if ID.IsDragging then
		
		if type(icon) == "table" and icon.base == TMW.IconBase then -- if the frame that got the drag is an icon, set the destination stuff.
			ID.desticon = icon
			ID.destFrame = nil
			
			if script == "OnDragStop" then -- wait for OnDragReceived
				return
			end
			
			if ID.desticon.group:GetID() == ID.srcicon.group:GetID() and ID.desticon:GetID() == ID.srcicon:GetID() then
				return
			end
			
			UIDropDownMenu_SetAnchor(ID.DD, 0, 0, "TOPLEFT", icon, "BOTTOMLEFT")
		else
			ID.desticon = nil
			ID.destFrame = icon -- not actually an icon. just some frame.
			local cursorX, cursorY = GetCursorPosition()
			local UIScale = UIParent:GetScale()
			UIDropDownMenu_SetAnchor(ID.DD, cursorX/UIScale, cursorY/UIScale, nil, UIParent, "BOTTOMLEFT")
		end
		
		if not DropDownList1:IsShown() or UIDROPDOWNMENU_OPEN_MENU ~= ID.DD then
			if not ID.DD.Initialized then
				UIDropDownMenu_Initialize(ID.DD, ID.DropDown, "DROPDOWN")
				ID.DD.Initialized = true
			end
			ToggleDropDownMenu(1, nil, ID.DD)
		end
	end
end


---------- Icon Handler ----------
function ID:Handler(method)
	-- close the menu
	CloseDropDownMenus()
	
	-- save misc. settings
	IE:SaveSettings()
	
	-- attempt to create a backup before doing anything
	IE:AttemptBackup(ID.srcicon)
	IE:AttemptBackup(ID.desticon)
	
	-- finally, invoke the method to handle the operation.
	ID[method](ID)
	
	-- then, update things
	TMW:Update()
	IE:Load(1)
end


---------- Icon Methods ----------
function ID:Move()
	-- move the actual settings
	db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()] = db.profile.Groups[ID.srcicon.group:GetID()].Icons[ID.srcicon:GetID()]
	db.profile.Groups[ID.srcicon.group:GetID()].Icons[ID.srcicon:GetID()] = nil
	
	-- preserve buff/debuff/other types textures
	ID.desticon.texture:SetTexture(ID.srcicon.texture:GetTexture())

	local srcicon, desticon = tostring(ID.srcicon), tostring(ID.desticon)
	
	TMW:ReconcileData(srcicon, desticon)
end

function ID:Copy()
	-- copy the settings
	db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()] = TMW:CopyWithMetatable(db.profile.Groups[ID.srcicon.group:GetID()].Icons[ID.srcicon:GetID()])
	
	-- preserve buff/debuff/other types textures
	ID.desticon.texture:SetTexture(ID.srcicon.texture:GetTexture()) 
end

function ID:Swap()
	-- swap the actual settings
	local dest = db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()]
	db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()] = db.profile.Groups[ID.srcicon.group:GetID()].Icons[ID.srcicon:GetID()]
	db.profile.Groups[ID.srcicon.group:GetID()].Icons[ID.srcicon:GetID()] = dest
	
	-- preserve buff/debuff/other types textures
	local desttex = ID.desticon.texture:GetTexture() 
	ID.desticon.texture:SetTexture(ID.srcicon.texture:GetTexture())
	ID.srcicon.texture:SetTexture(desttex)

	local srcicon, desticon = tostring(ID.srcicon) .. "$", tostring(ID.desticon) .. "$"
	
	TMW:ReconcileData(srcicon, desticon, nil, nil, true)
end

function TMW:ReconcileData(source, destination, matchSource, matchDestination, swap)
	-- update any changed icons that meta icons are checking
	for ics in TMW:InIconSettings() do
		for k, ic in pairs(ics.Icons) do
			if type(ic) == "string" then
				local string = ic
			
				if matchSource and string:find(matchSource) then
					ics.Icons[k] = string:gsub(source, destination)
				elseif not matchSource and source == string then
					ics.Icons[k] = destination
				elseif swap and matchDestination and string:find(matchDestination) then
					ics.Icons[k] = string:gsub(destination, source)
				elseif swap and not matchDestination and destination == string then
					ics.Icons[k] = source
				end
			end
		end
	end
	
	-- update any changed icons in conditions
	for Condition in TMW:InConditionSettings() do
		if Condition.Icon ~= "" and type(Condition.Icon) == "string" then
			local string = Condition.Icon
			
			if matchSource and string:find(matchSource) then
				Condition.Icon = string:gsub(source, destination)
			elseif not matchSource and source == string then
				Condition.Icon = destination
			elseif swap and matchDestination and string:find(matchDestination) then
				Condition.Icon = string:gsub(destination, source)
			elseif swap and not matchDestination and destination == string then
				Condition.Icon = source
			end
		end
	end
	
	-- update any anchors
	for gs, gID in TMW:InGroupSettings() do
		if type(gs.Point.relativeTo) == "string" then
			local string = gs.Point.relativeTo
			
			if matchSource and string:find(matchSource) then
				gs.Point.relativeTo = string:gsub(source, destination)
			elseif not matchSource and source == string then
				gs.Point.relativeTo = destination
			elseif swap and matchDestination and string:find(matchDestination) then
				gs.Point.relativeTo = string:gsub(destination, source)
			elseif swap and not matchDestination and destination == string then
				gs.Point.relativeTo = source
			end
		end
	end
	
	--TMW:Update()
end

function ID:Meta()
	tinsert(db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()].Icons, ID.srcicon:GetName())
end

function ID:Condition()
	-- add a condition to the destination icon
	local Condition = CNDT:AddCondition(db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()].Conditions)
	
	-- set the settings
	Condition.Type = "ICON"
	Condition.Icon = ID.srcicon:GetName()
end

function ID:Anchor()
	if ID.desticon then
		-- we are anchoring to another TMW group, so dont operate on the same group.
		if ID.desticon.group == ID.srcicon.group then
			return
		end
		
		-- set the setting
		ID.srcicon.group.Point.relativeTo = ID.desticon.group:GetName()
	else
		local name = ID.destFrame:GetName()
		-- we are anchoring to some other frame entirely.
		if ID.destFrame == WorldFrame then
			-- If it was dragged to WorldFrame then reset the anchor to UIParent (the text in the dropdown is custom for this circumstance)
			name = "UIParent"
		elseif ID.destFrame == ID.srcicon.group then
			-- this should never ever ever ever ever ever ever ever ever happen.
			return
		elseif not ID.destFrame:GetName() then
			-- make sure it actually has a name
			return
		end
		
		-- set the setting
		ID.srcicon.group.Point.relativeTo = name
	end
	
	-- do adjustments and positioning
	-- i cheat. we didnt really stop moving anything, but i'm going to hijack this function anyway.
	TMW:Group_StopMoving(ID.srcicon.group)
end

function ID:Split()	
	local groupID, group = TMW:Group_Add()
	
	
	-- back up the icon data of the source group
	local SOURCE_ICONS = db.profile.Groups[ID.srcicon.group:GetID()].Icons
	-- nullify it (we don't want to copy it)
	db.profile.Groups[ID.srcicon.group:GetID()].Icons = nil
	
	-- copy the source group.
	-- pcall so that, in the rare event of some unforseen error, we don't lose the user's settings (they haven't yet been restored)
	local success, err = pcall(TMW.CopyTableInPlaceWithMeta, TMW, db.profile.Groups[ID.srcicon.group:GetID()], db.profile.Groups[groupID])
	
	-- restore the icon data of the source group
	db.profile.Groups[ID.srcicon.group:GetID()].Icons = SOURCE_ICONS
	-- now it is safe to error since we restored the old settings
	assert(success, err)
	
	
	local gs = db.profile.Groups[groupID]
	--gs.Icons = blankIcons
	
	-- group tweaks
	gs.Rows = 1
	gs.Columns = 1
	gs.Name = ""
	
	-- adjustments and positioning
	local p = gs.Point
	p.point, p.relativeTo, p.relativePoint, p.x, p.y = ID.texture:GetPoint(2)
	p.x, p.y = p.x/UIParent:GetScale()*.85, p.y/UIParent:GetScale()*.85
	p.relativeTo = "UIParent"
	TMW:Group_StopMoving(ID.srcicon.group)
	
	
	TMW:Group_Update(groupID)
	
	-- move the actual icon
	-- move the actual settings
	gs.Icons[1] = ID.srcicon.group.Icons[ID.srcicon:GetID()]
	ID.srcicon.group.Icons[ID.srcicon:GetID()] = nil
	
	-- preserve buff/debuff/other types textures
	group[1].texture:SetTexture(ID.srcicon.texture:GetTexture())

	local srcicon, desticon = tostring(ID.srcicon), tostring(group[1])
	
	TMW:ReconcileData(srcicon, desticon)
	
	TMW:Group_Update(groupID)
end



-- ----------------------
-- META EDITOR
-- ----------------------

ME = TMW:NewModule("MetaEditor") TMW.ME = ME -- really part of the icon editor now, but im too lazy to move it over

function ME:Update()
	local groupID, iconID = CI.g, CI.i
	local settings = CI.ics.Icons
	UIDropDownMenu_SetSelectedValue(ME[1].icon, nil)
	UIDropDownMenu_SetText(ME[1].icon, "")

	for k, v in pairs(settings) do
		local mg = ME[k] or CreateFrame("Frame", "TellMeWhen_IconEditorMainIcons" .. k, IE.Main.Icons.ScrollFrame.Icons, "TellMeWhen_MetaGroup", k)
		ME[k] = mg
		mg:Show()
		ME[k].up:Show()
		ME[k].down:Show()
		if k > 1 then
			mg:SetPoint("TOP", ME[k-1], "BOTTOM", 0, 0)
		end
		mg:SetFrameLevel(IE.Main.Icons:GetFrameLevel()+2)
		
		TMW:SetUIDropdownText(mg.icon, v, TMW.Icons)
		
		mg.icontexture:SetTexture(_G[v] and _G[v].texture:GetTexture())
	end

	for f=#settings+1, #ME do
		ME[f]:Hide()
	end
	ME[1].up:Hide()
	ME[1]:Show()

	if settings[1] then
		ME[#settings].down:Hide()
		ME[1].delete:Hide()
	else
		ME[1].down:Hide()
	end

	if settings[2] then
		ME[1].delete:Show()
	else
		ME[1].delete:Hide()
	end

	if IE.Main.Icons.ScrollFrame:GetVerticalScrollRange() == 0 then
		IE.Main.Icons.ScrollFrame.ScrollBar:Hide()
	end
end


---------- Click Handlers ----------
function ME:UpOrDown(self, delta)
	local groupID, iconID = CI.g, CI.i
	local settings = db.profile.Groups[groupID].Icons[iconID].Icons
	local ID = self:GetParent():GetID()
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	ME:Update()
end

function ME:Insert(where)
	CI.ics.Icons[1] = CI.ics.Icons[1] or TMW.Icons[1]
	tinsert(CI.ics.Icons, where, TMW.Icons[1])
	ME:Update()
end

function ME:Delete(self)
	tremove(db.profile.Groups[CI.g].Icons[CI.i].Icons, self:GetParent():GetID())
	ME:Update()
end


---------- Dropdown ----------
local addedGroups = {}
function ME:IconMenu()
	sort(TMW.Icons, TMW.IconsSort)
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for k, v in ipairs(TMW.Icons) do
			local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
			g, i = tonumber(g), tonumber(i)
			if UIDROPDOWNMENU_MENU_VALUE == g and CI.ic and v ~= CI.ic:GetName() then
				local info = UIDropDownMenu_CreateInfo()
				info.func = ME.IconMenuOnClick
				local text, textshort = TMW:GetIconMenuText(g, i)
				info.text = textshort
				info.value = v
				info.tooltipTitle = text
				info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(g, g, 1), i)
				info.tooltipOnButton = true
				info.arg1 = self
				info.icon = TMW[g][i].texture:GetTexture()
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then
		wipe(addedGroups)
		for k, v in ipairs(TMW.Icons) do
			local g = tonumber(strmatch(v, "TellMeWhen_Group(%d+)"))
			if not addedGroups[g] and v ~= CI.ic:GetName() then
				local info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(g, g, 1)
				info.hasArrow = true
				info.notCheckable = true
				info.value = g
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				addedGroups[g] = true
			end
		end
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function ME:IconMenuOnClick(frame)
	db.profile.Groups[CI.g].Icons[CI.i].Icons[frame:GetParent():GetID()] = self.value
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	ME:Update()
	CloseDropDownMenus()
end



-- ----------------------
-- ICON EDITOR
-- ----------------------

IE = TMW:NewModule("IconEditor", "AceEvent-3.0") TMW.IE = IE
IE.Checks = {
	--1=check box,
	--2=editbox,
	--3=slider(x100),
	--4=custom,
	--table=subkeys are settings
	Name = 2,
	BindText = 2,
	CustomTex = 2,
	Icons = 4,
	Sort = 4,
	Unit = 2,
	ShowPBar = {
		ShowPBar = 1,
		PBarOffs = 2,
	},
	ShowCBar = {
		ShowCBar = 1,
		CBarOffs = 2,
	},
	InvertBars = 1,
	Enabled = 1,
	CheckNext = 1,
	DurationMin = 2,
	DurationMax = 2,
	DurationMinEnabled = 1,
	DurationMaxEnabled = 1,
	ConditionDur = 2,
	UnConditionDur = 2,
	ConditionDurEnabled = 1,
	UnConditionDurEnabled = 1,
	StackMin = 2,
	StackMax = 2,
	StackMinEnabled = 1,
	StackMaxEnabled = 1,
	Alpha = 3,
	UnAlpha = 3,
	ConditionAlpha = 3,
	FakeHidden = 1,
	OnlyIfCounting = 1,
}
IE.LeftChecks = {
	-- these are the settings that can be found on the left side of the icon editor.
	-- because there are so many of them, frames are made dynamically and repurposed as needed
	{
		setting = "ShowTimer",
		title = L["ICONMENU_SHOWTIMER"],
		tooltip = L["ICONMENU_SHOWTIMER_DESC"],
	},
	{
		setting = "ShowTimerText",
		title = L["ICONMENU_SHOWTIMERTEXT"],
		tooltip = L["ICONMENU_SHOWTIMERTEXT_DESC"],
		disabled = function()
			return not (IsAddOnLoaded("OmniCC") or IsAddOnLoaded("tullaCC"))
		end,
	},
	{
		setting = "OnlyMine",
		title = L["ICONMENU_ONLYMINE"],
		tooltip = L["ICONMENU_ONLYMINE_DESC"],
	},
	{
		setting = "ShowTTText",
		title = L["ICONMENU_SHOWTTTEXT"],
		tooltip = L["ICONMENU_SHOWTTTEXT_DESC"],
	},
	{
		setting = "Stealable",
		title = L["ICONMENU_STEALABLE"],
		tooltip = L["ICONMENU_STEALABLE_DESC"],
	},
	{
		setting = "UseActvtnOverlay",
		title = L["ICONMENU_USEACTIVATIONOVERLAY"],
		tooltip = L["ICONMENU_USEACTIVATIONOVERLAY_DESC"],
	},
	{
		setting = "IgnoreNomana",
		title = L["ICONMENU_IGNORENOMANA"],
		tooltip = L["ICONMENU_IGNORENOMANA_DESC"],
	},
	{
		setting = "CheckRefresh",
		title = L["ICONMENU_CHECKREFRESH"],
		tooltip = L["ICONMENU_CHECKREFRESH_DESC"],
	},
	{
		setting = "OnlySeen",
		title = L["ICONMENU_ONLYSEEN"],
		tooltip = L["ICONMENU_ONLYSEEN_DESC"],
	},
	{
		setting = "DontRefresh",
		title = L["ICONMENU_DONTREFRESH"],
		tooltip = L["ICONMENU_DONTREFRESH_DESC"],
	},
	{
		setting = "Interruptible",
		title = L["ICONMENU_ONLYINTERRUPTIBLE"],
		tooltip = L["ICONMENU_ONLYINTERRUPTIBLE_DESC"],
	},
	{
		setting = "OnlyInBags",
		title = L["ICONMENU_ONLYBAGS"],
		tooltip = L["ICONMENU_ONLYBAGS_DESC"],
	},
	{
		setting = "OnlyEquipped",
		title = L["ICONMENU_ONLYEQPPD"],
		tooltip = L["ICONMENU_ONLYEQPPD_DESC"],
		clickhook = function(self, button)
			if CI.ics and self:GetParent().OnlyInBags then
				local checked = not not self:GetChecked()
				if checked then
					self:GetParent().OnlyInBags:SetChecked(true)
					self:GetParent().OnlyInBags:Disable()
					CI.ics.OnlyInBags = checked
				else
					self:GetParent().OnlyInBags:Enable()
				end
			end
		end,
	},
	{
		setting = "HideUnequipped",
		title = L["ICONMENU_HIDEUNEQUIPPED"],
		tooltip = L["ICONMENU_HIDEUNEQUIPPED_DESC"],
	},
	{
		setting = "EnableStacks",
		title = L["ICONMENU_SHOWSTACKS"],
		tooltip = L["ICONMENU_SHOWSTACKS_DESC"],
	},
	{
		setting = "RangeCheck",
		title = L["ICONMENU_RANGECHECK"],
		tooltip = L["ICONMENU_RANGECHECK_DESC"],
	},
	{
		setting = "ManaCheck",
		title = L["ICONMENU_MANACHECK"],
		tooltip = L["ICONMENU_MANACHECK_DESC"],
	},
	{
		setting = "CooldownCheck",
		title = L["ICONMENU_COOLDOWNCHECK"],
		tooltip = L["ICONMENU_COOLDOWNCHECK_DESC"],
		clickhook = function(self, button)
			local IgnoreRunes = self:GetParent().IgnoreRunes
			if not IgnoreRunes then return end
			if self:GetChecked() or TMW.CI.t ~= "reactive" then
				IgnoreRunes:Enable()
			else
				IgnoreRunes:Disable()
			end
		end,
	},
	{
		setting = "IgnoreRunes",
		title = L["ICONMENU_IGNORERUNES"],
		tooltip = L["ICONMENU_IGNORERUNES_DESC"],
		disabledtooltip = L["ICONMENU_IGNORERUNES_DESC_DISABLED"],
	},
}
IE.Tabs = {
	[1] = "Main",
	[2] = "Conditions",
	[3] = "Sound",
	[4] = "Announcements",
	[5] = "Conditions",
	[6] = "MainOptions",
}

function IE:OnInitialize()

	-- they see me clonin'... they hatin'...
	-- (make TMW.IE be the same as IE)
	-- IE[0] = TellMeWhen_IconEditor[0] (already done in .xml)
	local meta = CopyTable(getmetatable(IE))
	meta.__index = getmetatable(TellMeWhen_IconEditor).__index
	setmetatable(IE, meta)
	
	IE:SetScript("OnUpdate", IE.OnUpdate)
	IE.iconsToUpdate = {}
end

function IE:OnUpdate()
	-- self is IE, not IE, but since i made them the same thing, it doesnt matter
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	local icon = TMW.CI.ic
	
	if not groupID then
		return
	end
	
	-- update the top of the icon editor with the information of the current icon.
	-- this is done in an OnUpdate because it is just too hard to track when the texture changes sometimes.
	-- I don't want to fill up the main addon with configuration code to notify the IE of texture changes
	self.FS1:SetFormattedText(TMW.L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), iconID)
	if icon then
		self.icontexture:SetTexture(icon.texture:GetTexture())
	end
	
	-- run updates for any icons that are queued
	for icon in pairs(IE.iconsToUpdate) do
		TMW:Icon_Update(tremove(IE.iconsToUpdate, 1))
	end
	
	-- check and see if the settings of the current icon have changed.
	-- if they have, create a history point (or at least try to)
	-- IMPORTANT: do this after running icon updates because SoundData is stored in the event table, which makes 2 changes over 2 frames in 1 user action, which screws thing up
	IE:AttemptBackup(icon)
end


---------- Interface ----------
function IE:Load(isRefresh, icon)
	if type(icon) == "table" then
		HELP:HideForIcon(CI.ic)
		PlaySound("igCharacterInfoTab")
		IE:SaveSettings()
		CNDT:Clear()
		CI.i = icon:GetID()
		CI.g = icon:GetParent():GetID()
		CI.ic = icon
		CI.t = icon.Type
	end
	if not IE:IsShown() then
		if isRefresh then
			return
		else
			IE:TabClick(IE.MainTab)
		end
	end

	local groupID, iconID = CI.g, CI.i
	if not groupID or not iconID then return end

	IE.ExportBox:SetText("")
	IE:SetScale(db.global.EditorScale)

	IE.Main.Name:SetLabels(TMW.Types[CI.t].chooseNameTitle, TMW.Types[CI.t].chooseNameText)
	IE.Main.Name:GetScript("OnTextChanged")(IE.Main.Name)
	
	if IE.Main.Type.selectedValue ~= CI.t then
		UIDropDownMenu_SetSelectedValue(IE.Main.Type, CI.t)
	end
	
	CI.t = db.profile.Groups[groupID].Icons[iconID].Type
	if CI.t == "" then
		UIDropDownMenu_SetText(IE.Main.Type, L["ICONMENU_TYPE"])
	else
		local Type = rawget(TMW.Types, CI.t)
		if Type then
			UIDropDownMenu_SetText(IE.Main.Type, Type.name)
		else
			UIDropDownMenu_SetText(IE.Main.Type, "UNKNOWN TYPE: " .. CI.t)
		end
	end
	CNDT:SetTabText("icon")
	CNDT:SetTabText("group")
	CNDT:Load()

	ME:Update()
	
	SND:Load()
	ANN:Load()

	IE:SetupRadios()
	IE:LoadSettings()
	IE:ShowHide()
	
	IE:ScheduleIconUpdate(CI.ic)
	
	HELP:ShowNext()
	
	-- It is intended that this happens at the end instead of the beginning.
	-- Table accesses that trigger metamethods flesh out an icon's settings with new things that aren't there pre-load (usually)
	if icon then
		IE:AttemptBackup(CI.ic)
	end
	IE:UndoRedoChanged()
end

function IE:TabClick(self)
	-- invoke blizzard's tab click function to set the apperance of all the tabs
	PanelTemplates_Tab_OnClick(self, self:GetParent())
	PlaySound("igCharacterInfoTab")
	
	-- hide all tabs' frames, including the current tab so that the OnHide and OnShow scripts fire
	for id, frame in pairs(IE.Tabs) do
		if IE[frame] then
			IE[frame]:Hide()
		end
	end
	
	-- state the current tab.
	-- this is used in many other places, including inside some OnShow scripts, so it MUST go before the :Show()s below
	IE.CurrentTab = self
	
	-- show the selected tab's frame
	IE[IE.Tabs[self:GetID()]]:Show()
	-- show the icon editor
	IE:Show()
	
	-- special handling for certain tabs. TODO: move this somewhere else.
	if self:GetID() == TMW.ICCNDTTab then
		-- the icon condition tab
		CNDT:Load("icon")
		
	elseif self:GetID() == TMW.GRCNDTTab then
		-- the group condition tab
		CNDT:Load("group")
		
	elseif self:GetID() == TMW.MOTab then
		-- the group settings tab
		TMW:CompileOptions()
		IE:NotifyChanges("groups", "Group " .. CI.g)
		LibStub("AceConfigDialog-3.0"):Open("TMW IEOptions", IE.MainOptionsWidget)
	end
	
	HELP:ShowNext() -- should happen after conditions are loaded
end

function IE:NotifyChanges(...)
	-- this is used to select the same group in all open TMW configuration windows
	-- the path (...) is a list of keys in TMW.OptionsTable that leads to the desired group
	
	local hasPath = ...
	
	-- Notify standalone options panels of a change (Blizzard, slash command, LDB)
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TMW Options")
	if hasPath then
		LibStub("AceConfigDialog-3.0"):SelectGroup("TMW Options", ...)
	end
	
	-- Notify the group settings tab in the icon editor of any changes
	-- the order here is very specific and breaks if you change it. (:Open(), :SelectGroup(), :NotifyChange())
	if IE.MainOptionsWidget and IE.MainOptions:IsShown() then
		LibStub("AceConfigDialog-3.0"):Open("TMW IEOptions", IE.MainOptionsWidget)
		if hasPath then
			LibStub("AceConfigDialog-3.0"):SelectGroup("TMW IEOptions", ...)
		end
		LibStub("AceConfigRegistry-3.0"):NotifyChange("TMW IEOptions")
	end
end

function IE:ShowHide()
	local t = CI.t
	if not t then return end

	for k, v in pairs(IE.Checks) do
		if Types[t].RelevantSettings[k] and IE.Main[k] then
			IE.Main[k]:Show()
			if IE.Main[k].SetEnabled then
				IE.Main[k]:SetEnabled(1)
			end
		else
			IE.Main[k]:Hide()
		end
	end

	for name, Type in pairs(Types) do
		if name ~= t and Type.IE_TypeUnloaded then
			Type:IE_TypeUnloaded()
		end
	end
	if Types[t].IE_TypeLoaded then
		Types[t]:IE_TypeLoaded()
	end

	local spb = IE.Main.ShowPBar
	local scb = IE.Main.ShowCBar
	if Types[t].HideBars then -- override the previous shows and disables
		spb:Hide()
		scb:Hide()
		IE.Main.InvertBars:Hide()
	else
		if not spb:IsShown() then
			spb:Show()
			spb:SetEnabled(nil)
		end
		if not scb:IsShown() then
			scb:Show()
			scb:SetEnabled(nil)
		end
		IE.Main.InvertBars:Enable()
		if not (spb.enabled or scb.enabled) then
			IE.Main.InvertBars:Show()
			IE.Main.InvertBars:Disable()
		end

		spb.PBarOffs:SetEnabled(spb.ShowPBar:GetChecked())
		scb.CBarOffs:SetEnabled(scb.ShowCBar:GetChecked())
	end

end

function IE:Reset()
	local groupID, iconID = CI.g, CI.i
	IE:SaveSettings() -- this is here just to clear the focus of editboxes, not to actually save things
	db.profile.Groups[groupID].Icons[iconID] = nil
	IE:ScheduleIconUpdate(CI.ic)
	IE:Load(1)
	IE:TabClick(IE.MainTab)
	HELP:HideForIcon(CI.ic)
end


---------- Settings ----------
function IE:LeftCheck_OnEnable()
	-- self is the check box frame, not IE
	self:SetAlpha(1)
	if self.data.disabledtooltip then
		TMW:TT(f, self.data.title, self.data.tooltip, 1, 1)
	end
end
function IE:LeftCheck_OnDisable()
	self:SetAlpha(0.4)
	if self.data.disabledtooltip then
		TMW:TT(f, self.data.title, self.data.disabledtooltip, 1, 1)
	end
end
function IE:LeftCheck_OnClick(button)
	if CI.ics and self.setting then
		CI.ics[self.setting] = not not self:GetChecked()
		IE:ScheduleIconUpdate(CI.ic)
	end
	get(self.data.clickhook, self, button) -- cheater! (we arent getting anything, im using this as a wrapper so i dont have to see if the function exists)
end

function IE:LoadSettings()
	local groupID, iconID = CI.g, CI.i
	local ics = CI.ics
	for setting, settingtype in pairs(IE.Checks) do
		local f = IE.Main[setting]
		if settingtype == 1 then
			f:SetChecked(ics[setting])
			f:GetScript("OnClick")(f)
		elseif settingtype == 2 then
			f:SetText(ics[setting] or "")
			f:SetCursorPosition(0)
		elseif settingtype == 3 then
			f:SetValue(ics[setting]*100)
		elseif type(settingtype) == "table" then
			for subset, subtype in pairs(settingtype) do
				if subtype == 1 then
					f[subset]:SetChecked(ics[subset])
				elseif subtype == 2 then
					f[subset]:SetText(ics[subset])
					f[subset]:SetCursorPosition(0)
				end
			end
		end
	end

	local leftCheckNum = 1
	for k, f in pairs(IE.Main.LeftChecks) do
		if not tonumber(k) then
			IE.Main.LeftChecks[k] = nil
		end
	end
	for k, data in pairs(IE.LeftChecks) do
		local setting = data.setting
		if Types[CI.t].RelevantSettings[setting] and not get(data.hidden) then
			local f = IE.Main.LeftChecks[leftCheckNum]
			if not f then
				f = CreateFrame("CheckButton", "TellMeWhen_IconEditorMainLeftChecks" .. leftCheckNum, TMW.IE.Main.LeftChecks, "TellMeWhen_CheckTemplate", leftCheckNum)
				IE.Main.LeftChecks[leftCheckNum] = f
				if leftCheckNum == 1 then
					f:SetPoint("TOPLEFT")
				else
					f:SetPoint("TOP", IE.Main.LeftChecks[leftCheckNum-1], "BOTTOM", 0, 6)
				end
				f.text:SetWidth(TMW.WidthCol1)
				f:SetScript("OnEnable", IE.LeftCheck_OnEnable)
				f:SetScript("OnDisable", IE.LeftCheck_OnDisable)
				f:SetScript("OnClick", IE.LeftCheck_OnClick)
				f:SetMotionScriptsWhileDisabled(true)
			end
			
			f:Show()
			f.data = data
			f.setting = setting
			IE.Main.LeftChecks[setting] = f
			f.text:SetText(data.title)
			TMW:TT(f, data.title, data.tooltip, 1, 1)
			f:SetChecked(ics[setting])
			if get(data.disabled) then
				f:Enable() -- force scripts
				f:Disable()
			else
				f:Enable()
			end
			leftCheckNum = leftCheckNum + 1
		end
	end
	for i = leftCheckNum, #IE.Main.LeftChecks do
		IE.Main.LeftChecks[i]:Hide()
	end
	for k, f in pairs(IE.Main.LeftChecks) do
		if not tonumber(k) then
			f:GetScript("OnClick")(f)
		end
	end
		
	for _, parent in TMW:Vararg(CI.t ~= "runes" and IE.Main.TypeChecks, IE.Main.WhenChecks, IE.Main.Sort) do
		if parent then
			for k, frame in pairs(parent) do
				if strfind(k, "Radio") then
					if frame.setting == "TotemSlots" then
						frame:SetChecked(strsub(ics[frame.setting], frame:GetID(), frame:GetID()) == "1")
					else
						local checked = ics[frame.setting] == frame.value
						frame:SetChecked(checked)
						if checked and parent == IE.Main.WhenChecks then
							if frame:GetID() == 1 then
								IE.Main.Alpha:Enable()
								IE.Main.UnAlpha:Disable()
							elseif frame:GetID() == 2 then
								IE.Main.Alpha:Disable()
								IE.Main.UnAlpha:Enable()
							elseif frame:GetID() == 3 then
								IE.Main.Alpha:Enable()
								IE.Main.UnAlpha:Enable()
							end
						end
					end
				end
			end
		end
	end
	IE.Main.TypeChecks.Runes:Hide()
	if CI.t == "runes" then
		for k, frame in pairs(IE.Main.TypeChecks.Runes) do
			if k ~= 0 then
				frame:SetChecked(strsub(ics.TotemSlots, frame:GetID(), frame:GetID()) == "1")
			end
		end
		IE.Main.TypeChecks.Runes:Show()
	end
end

function IE:SetupRadios()
	local t = CI.t
	local Type = Types[t]
	if Type and Type.TypeChecks then
		for k, frame in pairs(IE.Main.TypeChecks) do
			if strfind(k, "Radio") then
				local info = Type.TypeChecks[frame:GetID()]
				if frame:GetID() > 1 then
					if #Type.TypeChecks > 3 then
						local p, rt, rp, x, y = frame:GetPoint(1)
						frame:SetPoint(p, rt, rp, x, 11)
					else
						local p, rt, rp, x, y = frame:GetPoint(1)
						frame:SetPoint(p, rt, rp, x, 5)
					end
				end
				if info then
					frame:Show()
					frame.setting = Type.TypeChecks.setting
					frame.value = info.value
					frame.text:SetText((info.colorCode or "") .. info.text .. "|r")
					if info.tooltipText then
						TMW:TT(frame, info.text, info.tooltipText, 1, 1)
					else
						frame:SetScript("OnEnter", nil)
					end
				else
					frame:Hide()
				end
			end
		end
		IE.Main.TypeChecks:Show()
		IE.Main.TypeChecks.text:SetText(Type.TypeChecks.text)
	else
		IE.Main.TypeChecks:Hide()
	end
	if Type and Type.WhenChecks then
		for k, frame in pairs(IE.Main.WhenChecks) do
			if strfind(k, "Radio") then
				local info = Type.WhenChecks[frame:GetID()]
				if info then
					frame:Show()
					frame.setting = "ShowWhen"
					frame.value = info.value
					frame.text:SetText((info.colorCode or "") .. info.text .. "|r")
					if info.tooltipText then
						TMW:TT(frame, info.text, info.tooltipText, 1)
					else
						frame:SetScript("OnEnter", nil)
					end
				else
					frame:Hide()
				end
			end
		end
		IE.Main.WhenChecks.text:SetText(Type.WhenChecks.text)
		IE.Main.WhenChecks:Show()
	else
		IE.Main.WhenChecks:Hide()
	end

	local alphainfo = Type and Type.WhenChecks
	if alphainfo then
		IE.Main.Alpha.text:SetText((alphainfo[1].colorCode or "") .. alphainfo[1].text .. "|r")
		IE.Main.UnAlpha.text:SetText((alphainfo[2].colorCode or "") .. alphainfo[2].text .. "|r")
	else
		IE.Main.Alpha.text:SetText(L["ICONMENU_USABLE"])
		IE.Main.UnAlpha.text:SetText(L["ICONMENU_UNUSABLE"])
	end
end

function IE:SaveSettings()
	for k, t in pairs(IE.Checks) do
		if t == 2 then
			IE.Main[k]:ClearFocus()
		end
	end
	ANN.EditBox:ClearFocus()
	SND.Custom:ClearFocus()
	if IE:IsShown() then
		for i, frame in ipairs(CNDT) do
			frame.Unit:ClearFocus()
			frame.EditBox:ClearFocus()
			frame.EditBox2:ClearFocus()
		end
	end
end


---------- Equivalancies ----------
local equivTipCache = {}
function IE:Equiv_GenerateTips(equiv)
	if equivTipCache[equiv] then return equivTipCache[equiv] end
	local r = "" --tconcat doesnt allow me to exclude duplicates unless i make another garbage table, so lets just do this
	local tbl = TMW:SplitNames(EquivFullIDLookup[equiv])
	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		if not name then
			if TMW.debug then
				TMW:Error("INVALID ID FOUND: "..equiv..":"..v)
			else
				name = v
				texture = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
		end
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple ranks.
			r = r .. "|T" .. texture .. ":0|t" .. name .. "\r\n"
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	r = strtrim(r, "\r\n ;")
	equivTipCache[equiv] = r
	return r
end

local function equivSorter(a, b)
	if a == "IncreasedSPsix" and b == "IncreasedSPten" then
		return true
	elseif b == "IncreasedSPsix" and a == "IncreasedSPten" then
		return false
	else
		return L[a] < L[b]
	end
end
function IE:Equiv_DropDown()
	if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
		if TMW.BE[UIDROPDOWNMENU_MENU_VALUE] then
			for k, v in TMW:OrderedPairs(TMW.BE[UIDROPDOWNMENU_MENU_VALUE], equivSorter) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = IE.Equiv_DropDown_OnClick
				info.text = L[k]
				info.tooltipTitle = k
				local text = IE:Equiv_GenerateTips(k)

				info.icon = TMW.SpellTextures[EquivFirstIDLookup[k]]
				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93

				info.tooltipText = text
				info.tooltipOnButton = true
				info.value = k
				info.arg1 = k
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, 2)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == "dispel" then
			for k, v in TMW:OrderedPairs(TMW.DS) do
				local v = TMW.DS[k]
				local info = UIDropDownMenu_CreateInfo()
				info.func = IE.Equiv_DropDown_OnClick
				info.text = L[k]

				local first = strsplit(EquivFirstIDLookup[k], ";")
				info.icon = v
				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93

				info.value = k
				info.arg1 = k
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, 2)
			end
		end
		return
	end

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_BUFF"]
	info.value = "buffs"
	info.hasArrow = true
	info.colorCode = "|cFF00FF00"
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	--some stuff is reused for this one
	info.text = L["ICONMENU_DEBUFF"]
	info.value = "debuffs"
	info.colorCode = "|cFFFF0000"
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_CASTS"]
	info.value = "casts"
	info.colorCode = nil
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_DRS"]
	info.value = "dr"
	info.colorCode = nil
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_DISPEL"]
	info.value = "dispel"
	UIDropDownMenu_AddButton(info)
end

function IE:Equiv_DropDown_OnClick(value)
	local e = IE.Main.Name
	e:Insert("; " .. value .. "; ")
	local new = TMW:CleanString(e)
	e:SetText(new)
	local _, position = strfind(new, gsub(value, "([%-])", "%%%1"))
	position = tonumber(position) + 2
	
	-- WARNING: lame coding from here to the end of this function.
	e:SetFocus()
	e:ClearFocus()
	e:SetFocus()
	e:HighlightText(0, 0)
	e:SetCursorPosition(position)
	CloseDropDownMenus()
end


---------- Dropdowns ----------
function IE:Type_DropDown()
	if not db then return end
	local groupID, iconID = CI.g, CI.i
	
	for _, Type in ipairs(TMW.OrderedTypes) do -- order in the order in which they are loaded in the .toc file
		if not Type.hidden then
			if Type.spacebefore then
				AddDropdownSpacer()
			end
			
			local info = UIDropDownMenu_CreateInfo()
			info.text = Type.name
			info.value = Type.type
			if Type.desc then
				info.tooltipTitle = Type.tooltipTitle or Type.name
				info.tooltipText = Type.desc
				info.tooltipOnButton = true
			end
			info.checked = (info.value == db.profile.Groups[groupID].Icons[iconID].Type)
			info.func = IE.Type_Dropdown_OnClick
			info.arg1 = Type
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			if Type.spaceafter then
				AddDropdownSpacer()
			end
		end
	end
end

function IE:Type_Dropdown_OnClick()
	CI.ics.Type = self.value
	CI.ic.texture:SetTexture(nil)
	IE:ScheduleIconUpdate(CI.ic)
	UIDropDownMenu_SetSelectedValue(IE.Main.Type, self.value)
	CI.t = self.value
	SUG.redoIfSame = 1
	SUG.Suggest:Hide()
	HELP:HideForIcon(CI.ic)
	IE:Load(1)
end

function IE:Unit_DropDown()
	if not db then return end
	local e = IE.Main.Unit
	if not e:HasFocus() then
		e:HighlightText()
	end
	for k, v in pairs(TMW.Units) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v.text
		info.value = v.value
		if v.range then
			info.tooltipTitle = v.tooltipTitle or v.text
			info.tooltipText = "|cFFFF0000#|r = 1-" .. v.range
			info.tooltipOnButton = true
		end
		info.notCheckable = true
		info.func = IE.Unit_DropDown_OnClick
		info.arg1 = v
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end

function IE:Unit_DropDown_OnClick(v)
	local e = IE.Main.Unit
	local ins = v.value
	if v.range then
		ins = v.value .. "|cFFFF0000#|r"
	end
	e:Insert(";" .. ins .. ";")
	TMW:CleanString(e)
	CI.ics.Unit = e:GetText()
	IE:ScheduleIconUpdate(CI.ic)
	CloseDropDownMenus()
end


---------- Tooltips ----------
local cachednames = {}
function IE:GetRealNames() -- TODO: MODULARIZE THIS
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(IE.Main.Name)
	if cachednames[CI.t .. CI.SoI .. text] then return cachednames[CI.t .. CI.SoI .. text] end

	local tbl
	TMW:HackEquivs()
	local GetSpellInfo = GetSpellInfo
	if CI.SoI == "item" then
		tbl = TMW:GetItemIDs(nil, text)
	else
		tbl = TMW:GetSpellNames(nil, text)
	end
	local durations = Types[CI.t].DurationSyntax and TMW:GetSpellDurations(nil, text) -- needs to happen before unhacking
	TMW:UnhackEquivs()
	
	local str = ""
	local numadded = 0
	local numlines = 50
	local numperline = ceil(#tbl/numlines)
	
	for k, v in pairs(tbl) do
		local name, texture
		if CI.SoI == "item" then
			name = GetItemInfo(v) or v or ""
			texture = GetItemIcon(v)
		else
			name, _, texture = GetSpellInfo(v)
			texture = texture or SpellTextures[name or v]
			if not name and SUG.SpellCache then
				local lowerv = strlower(v)
				for id, lowername in pairs(SUG.SpellCache) do
					if lowername == lowerv then
						local newname, _, newtex = GetSpellInfo(id)
						name = newname
						if not texture then
							texture = newtex
						end
						break
					end
				end
			end
			name = name or v or ""
			texture = texture or SpellTextures[name]
		end
		
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple spellIDs.
			numadded = numadded + 1
			local dur = Types[CI.t].DurationSyntax and " ("..TMW:FormatSeconds(durations[k])..")" or ""
			str = str ..
			(texture and ("|T" .. texture .. ":0|t") or "") ..
			name ..
			dur ..
			"; " ..
			(floor(numadded/numperline) == numadded/numperline and "\r\n" or "")
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	str = strtrim(str, "\r\n ;")
	cachednames[CI.t .. CI.SoI .. text] = str
	return str
end

local cachedunits = {}
function IE:GetRealUnits()
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(IE.Main.Unit)
	if cachedunits[text] then return cachedunits[text] end

	local tbl = TMW:GetUnits(nil, text, true)
	
	local str = ""
	local numadded = 0
	local numlines = 50
	local numperline = ceil(#tbl/numlines)
	
	for k, v in pairs(tbl) do
		
		if not tiptemp[v] then --prevents display of the same name twice when there are multiple units... or something. I copy-pasted this.
			numadded = numadded + 1
			str = str ..
			v ..
			"; " ..
			(floor(numadded/numperline) == numadded/numperline and "\r\n" or "")
		end
		tiptemp[v] = true
	end
	wipe(tiptemp)
	str = strtrim(str, "\r\n ;")
	cachedunits[text] = str
	return str
end


---------- Icon Update Scheduler ----------
function IE:ScheduleIconUpdate(groupID, iconID)
	-- this is a handler to prevent the spamming of Icon_Update and creating excessive garbage.
	local icon
	if type(groupID) == "table" then --allow omission of icon
		icon = groupID
	else
		icon = TMW[groupID] and TMW[groupID][iconID]
	end
	if not icon then
		icon = CI.ic
	end
	if not TMW.tContains(IE.iconsToUpdate, icon) then
		tinsert(IE.iconsToUpdate, icon)
	end
end



-- -----------------------
-- IMPORT/EXPORT
-- -----------------------

---------- Data Type Handlers ----------
TMW.ImportFunctions = {
	icon = function(data, version, noOverwrite)
		local groupID, iconID = CI.g, CI.i
		db.profile.Groups[groupID].Icons[iconID] = nil -- restore defaults, table recreated when passed in to CTIPWM
		TMW:CopyTableInPlaceWithMeta(data, db.profile.Groups[groupID].Icons[iconID])
		
		if version then
			if version > TELLMEWHEN_VERSIONNUMBER then
				TMW:Print(L["FROMNEWERVERSION"])
			else
				TMW:DoUpgrade(version, nil, groupID, iconID)
			end
		end
	end,
	group = function(data, version, noOverwrite, oldgroupID)
		local groupID = CI.g
		if noOverwrite then
			groupID = TMW:Group_Add()
		end
		db.profile.Groups[groupID] = nil -- restore defaults, table recreated when passed in to CTIPWM
		local gs = db.profile.Groups[groupID]
		TMW:CopyTableInPlaceWithMeta(data, gs)
		
		-- change any meta icon components to the new group if the meta and components are/were in the same group (icon conditions, too)
		if oldgroupID then
			local srcgr, destgr = "TellMeWhen_Group"..oldgroupID, TMW[groupID]:GetName()
			for ics in TMW:InIconSettings(groupID) do
			
				-- update meta icons within the group
				for k, ic in pairs(ics.Icons) do
					if ic:find(srcgr) then
						ics.Icons[k] = ic:gsub(srcgr, destgr)
					end
				end
				
				-- update the conditions of icons within the group
				for Condition in TMW:InConditions(ics.Conditions) do
					if Condition.Icon:find(srcgr) then
						Condition.Icon = Condition.Icon:gsub(srcgr, destgr)
					end
				end
			end
			
			-- update group conditions
			for Condition in TMW:InConditions(gs.Conditions) do
				if Condition.Icon:find(srcgr) then
					Condition.Icon = Condition.Icon:gsub(srcgr, destgr)
				end
			end
		end
	
		if version then
			if version > TELLMEWHEN_VERSIONNUMBER then
				TMW:Print(L["FROMNEWERVERSION"])
			else
				TMW:DoUpgrade(version, nil, groupID)
			end
		end
	end,
	global = function(data, version, noOverwrite)
		if noOverwrite then -- noOverwrite is a name in this case.
		
			local base = gsub(noOverwrite, " %(%d+%)$", "")
			local newnum = 2
			
			-- generate a new name if the profile already exists
			local newname = base .. " (" .. newnum .. ")"
			while db.profiles[newname] do
				newnum = newnum + 1
				newname = base .. " (" .. newnum .. ")"
			end
			
			-- this will create a new profile if one by this name does not exist
			db:SetProfile(newname)
		else
			db:ResetProfile()
		end
		TMW:CopyTableInPlaceWithMeta(data, db.profile)
		
		if version then
			if version > TELLMEWHEN_VERSIONNUMBER then
				TMW:Print(L["FROMNEWERVERSION"])
			else
				TMW:DoUpgrade(version, true)
			end
		end
	end,
}


---------- Main Functions ----------
function TMW:Import(data, version, type, ...)
	assert(data, "Missing data to import")
	assert(version, "Missing version of data")
	assert(type, "No data type specified!")
	CloseDropDownMenus()
	local groupID, iconID = CI.g, CI.i
	local importfunc = TMW.ImportFunctions[type]
	if importfunc then
		importfunc(data, version, ...)

		TMW:Update()
		IE:Load(1)
	else
		TMW:Print(L["IMPORTERROR_INVALIDTYPE"])
	end
	TMW:ScheduleTimer("CompileOptions", 0.1) -- i dont know why i have to delay it, but I do.
end

function TMW:ExportToString(editbox, ...)
	local s = TMW:GetSettingsString(...)
	s = TMW:MakeSerializedDataPretty(s)
	TMW.LastExportedString = s
	editbox:SetText(s)
	editbox:HighlightText()
	editbox:SetFocus()
	CloseDropDownMenus()
end

function TMW:ExportToComm(editbox, ...)
	local player = strtrim(editbox:GetText())
	if player and #player > 1 then -- and #player < 13 you can send to cross server people in a battleground ("Cybeloras-Mal'Ganis"), so it can be more than 13
		local s = TMW:GetSettingsString(...)

		TMW:SendCommMessage("TMW", s, "WHISPER", player, "BULK", editbox.callback, editbox)
	end
end


---------- Serialization ----------
function TMW:SerializeData(data, type, ...)
	-- nothing more than a wrapper for AceSerializer-3.0
	assert(data, "No data to serialize!")
	assert(type, "No data type specified!")
	return TMW:Serialize(data, TELLMEWHEN_VERSIONNUMBER, " ~", type, ...)
end

function TMW:MakeSerializedDataPretty(string)
	return string:
	gsub("(^[^tT%d][^^]*^[^^]*)", "%1 "): -- add spaces to clean it up a little
	gsub("%^ ^", "^^") -- remove double space at the end
end

function TMW:DeserializeData(string)	
	local success, data, version, spaceControl, type, arg1, arg2, arg3, arg4, arg5 = TMW:Deserialize(string)
	if not success then
		-- corrupt/incomplete string
		return nil
	end
	
	if not version then
		-- if the version is not included in the data,
		-- then it must have been before the first version that included versions in export strings/comm,
		-- so just take a guess that it was the first version that had version checks with it.
		version = 41403
	end
	
	if version <= 45809 and not type and data.Type then
		-- 45809 was the last version to contain untyped data messages.
		-- It only supported icon imports/exports, so the type has to be an icon.
		type = "icon"
	end
	
	if not TMW.ImportFunctions[type] then
		-- unknown data type
		return nil
	end
	
	if spaceControl then
		if spaceControl:find("`|") then
			-- EVERYTHING is fucked up. try really hard to salvage it. It probably won't be completely successful
			return TMW:DeserializeData(string:gsub("`", "~`"):gsub("~`|", "~`~|"))	
		elseif spaceControl:find("`") then
			-- if spaces have become corrupt, then reformat them and... re-deserialize (lol)
			return TMW:DeserializeData(string:gsub("`", "~`"))	
		elseif spaceControl:find("~|") then
			-- if pipe characters have been screwed up by blizzard's cute little method of escaping things combined with AS-3.0's cute way of escaping things, try to fix them.
			return TMW:DeserializeData(string:gsub("~||", "~|"))	
		end
	end
	
	
	-- finally, we have everything we need. create a result object and return it.
	local result = {
		data = data,
		type = type,
		version = version,
		arg1 = arg1,
		arg2 = arg2,
		arg3 = arg3,
		arg4 = arg4,
		arg5 = arg5,
	}
	
	return result
end


---------- Settings Manipulation ----------
function TMW:GetSettingsString(type, settings, defaults, ...)
	assert(settings, "No data to serialize!")
	assert(type, "No data type specified!")
	assert(defaults, "No defaults specified!")
	
	-- ... contains additional data that may or may not be used/needed
	IE:SaveSettings()
	settings = CopyTable(settings)
	settings = TMW:CleanSettings(type, settings, defaults)
	return TMW:SerializeData(settings, type, ...)
end

function TMW:CleanDefaults(settings, defaults, blocker)
	-- make sure and pass in a COPY of the settings, not the original settings
	-- the following function is a slightly modified version of the one that AceDB uses to strip defaults.

	-- remove all metatables from the db, so we don't accidentally create new sub-tables through them
	setmetatable(settings, nil)
	-- loop through the defaults and remove their content
	for k,v in pairs(defaults) do
		if k == "*" or k == "**" then
			if type(v) == "table" then
				-- Loop through all the actual k,v pairs and remove
				for key, value in pairs(settings) do
					if type(value) == "table" then
						-- if the key was not explicitly specified in the defaults table, just strip everything from * and ** tables
						if defaults[key] == nil and (not blocker or blocker[key] == nil) then
							TMW:CleanDefaults(value, v)
							-- if the table is empty afterwards, remove it
							if next(value) == nil then
								settings[key] = nil
							end
						-- if it was specified, only strip ** content, but block values which were set in the key table
						elseif k == "**" then
							TMW:CleanDefaults(value, v, defaults[key])
						end
					end
				end
			elseif k == "*" then
				-- check for non-table default
				for key, value in pairs(settings) do
					if defaults[key] == nil and v == value then
						settings[key] = nil
					end
				end
			end
		elseif type(v) == "table" and type(settings[k]) == "table" then
			-- if a blocker was set, dive into it, to allow multi-level defaults
			TMW:CleanDefaults(settings[k], v, blocker and blocker[k])
			if next(settings[k]) == nil then
				settings[k] = nil
			end
		else
			-- check if the current value matches the default, and that its not blocked by another defaults table
			if settings[k] == defaults[k] and (not blocker or blocker[k] == nil) then
				settings[k] = nil
			end
		end
	end
	return settings
end

function TMW:CleanSettings(type, settings, defaults)
	local DatabaseCleanup = TMW.DatabaseCleanups[type]
	if DatabaseCleanup then
		DatabaseCleanup(settings)
	end
	return TMW:CleanDefaults(settings, defaults)
end


---------- Dropdown ----------
function IE:Copy_DropDown_Icon_OnClick(ics, version)
	-- self.value is the icon (maybe, if it's a string then we aren't importing from an icon in the current profile)
	if type(self.value) == "table" and self.value.base == TMW.IconBase and self.value:IsVisible() then
		TMW.HELP:Show("ICON_IMPORT_CURRENTPROFILE", nil, IE.ExportBox, 0, 0, L["HELP_IMPORT_CURRENTPROFILE"])
	end
	TMW[CI.g][CI.i]:SetTexture(nil)
	
	TMW:Import(ics, version, "icon")
end

function IE:AddIconToCopyDropdown(ics, groupID, iconID, profilename, group_src, version_src, force)
	if force or (tonumber(iconID) and not IE:DeepCompare(DEFAULT_ICON_SETTINGS, ics)) then
		info = UIDropDownMenu_CreateInfo()
		
		local tex
		local ic = groupID and iconID and TMW[groupID] and TMW[groupID][iconID]
		if db:GetCurrentProfile() == profilename and ic and ic.texture:GetTexture() then
			tex = ic.texture:GetTexture()
			info.value = ic -- holy shit, is this hacktastic or what?
		else
			tex = TMW:GuessIconTexture(ics)
			info.value = false
		end
		
		local text, textshort, tooltipText = TMW:GetIconMenuText(nil, nil, ics)
		info.text = textshort
		info.tooltipTitle = groupID and format(L["GROUPICON"], TMW:GetGroupName(group_src and group_src.Name, groupID, 1), iconID) or L["ICON"]
		info.tooltipText = tooltipText
		info.tooltipOnButton = true
		
		info.notCheckable = true
		
		info.icon = tex
		info.tCoordLeft = 0.07
		info.tCoordRight = 0.93
		info.tCoordTop = 0.07
		info.tCoordBottom = 0.93
		
		info.func = IE.Copy_DropDown_Icon_OnClick
		info.arg1 = ics
		info.arg2 = version_src
		
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end

local DeserializedData = {}
function IE:Copy_DropDown(...)
	local DROPDOWN = self
	local EDITBOX = DROPDOWN:GetParent()
	if not CI.ic then
		TMW.IE:Load(1, TMW:InIcons()()) -- hack to get the first icon that exists
	end
	local info
	
	if TMW.Received then
		 -- deserialize received comm
		for k, who in pairs(TMW.Received) do
			-- deserialize received data because we dont do it as they are received; AceSerializer is only embedded in _Options
			if type(k) == "string" and who then
				local result = TMW:DeserializeData(k)
				if result then
					tinsert(DeserializedData, result)
					result.who = who
					TMW.Received[k] = nil
				end
			end
		end
		if not next(TMW.Received) then
			TMW.Received = nil
		end
	end
	
	local t = strtrim(EDITBOX:GetText())
	local editboxResult = t ~= "" and TMW:DeserializeData(t)
	t = nil -- we dont want any accidents...

	
	if type(UIDROPDOWNMENU_MENU_VALUE) == "string" and (strfind(UIDROPDOWNMENU_MENU_VALUE, "^IMPORT_BACKUP") or strfind(UIDROPDOWNMENU_MENU_VALUE, "^IMPORT_FROMBACKUP")) then
		info = UIDropDownMenu_CreateInfo()
		info.text = "|cffff0000" .. L["IMPORT_FROMBACKUP_WARNING"]:format(TMW.BackupDate)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		AddDropdownSpacer()
	end
	
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then -- main menu
		----------IMPORT----------
		
		--heading
		info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_HEADING"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		--import from local
		info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_FROMLOCAL"]
		info.value = "IMPORT_FROMLOCAL"
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		--import from string
		info = UIDropDownMenu_CreateInfo()
		info.text = (EDITBOX.DoPulseValidString and "|cff00ff00" or "") .. L["IMPORT_FROMSTRING"]
		info.tooltipTitle = L["IMPORT_FROMSTRING"]
		info.tooltipText = L["IMPORT_FROMSTRING_DESC"]
		info.tooltipOnButton = true
		info.tooltipWhileDisabled = true
		local type = editboxResult and editboxResult.type
		local value
		if type == "global" then
			value = "IMPORT_PROFILE_%EDITBOX"
		elseif type == "group" and editboxResult.arg1 then
			value = "IMPORT_PROFILE_%EDITBOX_" .. editboxResult.arg1
		elseif type == "icon" then
			value = "IMPORT_FROMSTRING_ICON"
		end
		info.value = value
		info.hasArrow = true
		info.notCheckable = true
		info.disabled = not editboxResult
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		--import from comm
		info = UIDropDownMenu_CreateInfo()
		info.text = (TMW.DoPulseReceivedComm and "|cff33ff33" or "") ..  L["IMPORT_FROMCOMM"]
		info.value = "IMPORT_FROMCOMM"
		info.tooltipTitle = L["IMPORT_FROMCOMM"]
		info.tooltipText = L["IMPORT_FROMCOMM_DESC"]
		info.tooltipOnButton = true
		info.tooltipWhileDisabled = true
		info.hasArrow = true
		info.notCheckable = true
		info.disabled = not next(DeserializedData)
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		--import from backup
		info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_FROMBACKUP"]
		info.tooltipTitle = L["IMPORT_FROMBACKUP"]
		info.tooltipText = L["IMPORT_FROMBACKUP_DESC"]:format(TMW.BackupDate)
		info.tooltipOnButton = true
		info.tooltipWhileDisabled = true
		info.value = "IMPORT_FROMBACKUP"
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		
		AddDropdownSpacer()
		----------EXPORT----------
		
		--heading
		info = UIDropDownMenu_CreateInfo()
		info.text = L["EXPORT_HEADING"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		--export to string
		info = UIDropDownMenu_CreateInfo()
		info.text = L["EXPORT_TOSTRING"]
		info.tooltipTitle = L["EXPORT_TOSTRING"]
		info.tooltipText = L["EXPORT_TOSTRING_DESC"]
		info.tooltipOnButton = true
		info.value = "EXPORT_TOSTRING"
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		--export to comm
		info = UIDropDownMenu_CreateInfo()
		info.text = L["EXPORT_TOCOMM"]
		info.tooltipTitle = L["EXPORT_TOCOMM"]
		info.tooltipText = L["EXPORT_TOCOMM_DESC"]
		info.tooltipOnButton = true
		info.tooltipWhileDisabled = true
		info.value = "EXPORT_TOCOMM"
		info.hasArrow = true
		info.notCheckable = true
		local player = strtrim(EDITBOX:GetText())
		info.disabled = strfind(player, "[`~^%d]") or #player <= 1
		
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
	
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
	
		if UIDROPDOWNMENU_MENU_VALUE == "IMPORT_FROMLOCAL" or UIDROPDOWNMENU_MENU_VALUE == "IMPORT_FROMBACKUP" then
			local prefix
			if UIDROPDOWNMENU_MENU_VALUE == "IMPORT_FROMLOCAL" then
				prefix = "IMPORT_PROFILE_"
			else
				prefix = "IMPORT_BACKUP_"
			end
			-- current profile
			local currentProfile = db:GetCurrentProfile()
			if db.profiles[currentProfile] then
				info = UIDropDownMenu_CreateInfo()
				info.text = currentProfile
				info.value = prefix .. currentProfile
				info.hasArrow = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end

			AddDropdownSpacer()
			
			--other profiles
			for profilename, profiletable in TMW:OrderedPairs(db.profiles) do
				local profiletable = profile_src
				if profilename ~= currentProfile and profilename ~= "Default" then -- current profile and default are handled separately
					info = UIDropDownMenu_CreateInfo()
					info.text = profilename
					info.value = prefix .. profilename
					info.hasArrow = true
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
			
			--default profile
			if db.profiles["Default"] and currentProfile ~= "Default" then
				info = UIDropDownMenu_CreateInfo()
				info.text = "Default"
				info.value = prefix .. "Default"
				info.hasArrow = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
		
		if UIDROPDOWNMENU_MENU_VALUE == "IMPORT_FROMSTRING_ICON" and editboxResult then
			IE:AddIconToCopyDropdown(editboxResult.data, nil, nil, nil, nil, editboxResult.version, true)
			
		end
		
		if UIDROPDOWNMENU_MENU_VALUE == "IMPORT_FROMCOMM" then
			TMW.DoPulseReceivedComm = nil
			DROPDOWN.Dummy.Glow.Anim:Finish()
			
			for i, result in ipairs(DeserializedData) do
				if result.type == "icon" then
					IE:AddIconToCopyDropdown(result.data, nil, nil, nil, nil, result.version, true)
				else
					info = UIDropDownMenu_CreateInfo()
					info.text = result.arg1
					local value = "IMPORT_FROMCOMM_ICON"
					if result.type == "global" then
						value = "IMPORT_PROFILE_%COMM" .. i
					elseif result.type == "group" then
						assert(result.arg1, "Missing groupID for group import")
						value = "IMPORT_PROFILE_%COMM" .. i .. "_" .. result.arg1
						info.text = TMW:GetGroupName(result.data.Name, result.arg1)
					end
					info.value = value
					info.hasArrow = true
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
		
		if UIDROPDOWNMENU_MENU_VALUE == "EXPORT_TOCOMM" then
		
			-- icon to comm
			info = UIDropDownMenu_CreateInfo()
			local text = format(L["fICON"]:format(CI.i, TMW:GetGroupName(CI.g, CI.g, 1)))
			info.text = text
			info.tooltipTitle = text
			info.tooltipText = L["EXPORT_TOCOMM_DESC"]
			info.tooltipOnButton = true
			info.notCheckable = true
			info.func = function(...)
				TMW:ExportToComm(EDITBOX, "icon", TMW.CI.ics, TMW.Icon_Defaults)
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			-- group to comm
			info = UIDropDownMenu_CreateInfo()
			local text = format(L["fGROUP"]:format(TMW:GetGroupName(CI.g, CI.g, 1)))
			info.text = text
			info.tooltipTitle = text
			info.tooltipText = L["EXPORT_TOCOMM_DESC"] .. "\r\n\r\n" .. L["EXPORT_SPECIALDESC"]
			info.tooltipOnButton = true
			info.notCheckable = true
			info.func = function()
				TMW:ExportToComm(EDITBOX, "group", TMW.CI.gs, TMW.Group_Defaults, CI.g)
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			-- global to comm
			info = UIDropDownMenu_CreateInfo()
			info.text = L["fPROFILE"]:format(db:GetCurrentProfile())
			info.tooltipTitle = L["fPROFILE"]:format(db:GetCurrentProfile())
			info.tooltipText = L["EXPORT_TOCOMM_DESC"] .. "\r\n\r\n" .. L["EXPORT_SPECIALDESC"]
			info.tooltipOnButton = true
			info.notCheckable = true
			info.func = function()
				TMW:ExportToComm(EDITBOX, "global", TMW.db.profile, TMW.Defaults.profile, TMW.db:GetCurrentProfile())
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
		
		if UIDROPDOWNMENU_MENU_VALUE == "EXPORT_TOSTRING" then
		
			-- icon to string
			info = UIDropDownMenu_CreateInfo()
			local text = format(L["fICON"]:format(CI.i, TMW:GetGroupName(CI.g, CI.g, 1)))
			info.text = text
			info.tooltipTitle = text
			info.tooltipText = L["EXPORT_TOSTRING_DESC"]
			info.tooltipOnButton = true
			info.notCheckable = true
			info.func = function()
				TMW:ExportToString(EDITBOX, "icon", TMW.CI.ics, TMW.Icon_Defaults)
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			-- group to string
			info = UIDropDownMenu_CreateInfo()
			local text = format(L["fGROUP"]:format(TMW:GetGroupName(CI.g, CI.g, 1)))
			info.text = text
			info.tooltipTitle = text
			info.tooltipText = L["EXPORT_TOSTRING_DESC"] .. "\r\n\r\n" .. L["EXPORT_SPECIALDESC"]
			info.tooltipOnButton = true
			info.notCheckable = true
			info.func = function()
				TMW:ExportToString(EDITBOX, "group", TMW.CI.gs, TMW.Group_Defaults, CI.g)
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			-- global to string
			info = UIDropDownMenu_CreateInfo()
			info.text = L["fPROFILE"]:format(db:GetCurrentProfile())
			info.tooltipTitle = L["fPROFILE"]:format(db:GetCurrentProfile())
			info.tooltipText = L["EXPORT_TOSTRING_DESC"] .. "\r\n\r\n" .. L["EXPORT_SPECIALDESC"]
			info.tooltipOnButton = true
			info.notCheckable = true
			info.func = function()
				TMW:ExportToString(EDITBOX, "global", TMW.db.profile, TMW.Defaults.profile, db:GetCurrentProfile())
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end

	if not UIDROPDOWNMENU_MENU_VALUE then return end
	if type(UIDROPDOWNMENU_MENU_VALUE) ~= "string" then return end
	
	local IMPORT, PROFILE, profilename, groupID = strsplit("_", UIDROPDOWNMENU_MENU_VALUE)
	if IMPORT ~= "IMPORT" then return end
	groupID = tonumber(groupID)
	local profile_src, version_src, group_src, icon_src
	local result
	local commID = profilename and strmatch(profilename, "%COMM(%d+)")
	if profilename == "%EDITBOX" then
		result = editboxResult
	elseif commID then
		result = DeserializedData[tonumber(commID)]
	end
	if result then
		if result.type == "global" then
			profile_src = result.data
			group_src = profile_src.Groups[groupID]
			profilename = result.arg1
		elseif result.type == "group" then
			group_src = result.data
			profilename = nil
		elseif result.type == "icon" then
			icon_src = result.data
		end
		version_src = result.version
	else
		if PROFILE == "PROFILE" then
			profile_src = db.profiles[profilename]
		elseif PROFILE == "BACKUP" then
			profile_src = TMW.Backupdb.profiles[profilename]
		end
		if not profile_src then return end
		group_src = profile_src and groupID and profile_src.Groups[groupID]
		local VersionSetting = profile_src.Version
		version_src = #gsub(VersionSetting, "[^%d]", "") >= 5 and tonumber(VersionSetting) or TELLMEWHEN_VERSIONNUMBER
	end
	
	if groupID then
		-- header
		info = UIDropDownMenu_CreateInfo()
		info.text = (profilename and profilename .. ": " or "") .. TMW:GetGroupName(group_src.Name, groupID)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		-- copy group position
		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYGROUP"] .. " - " .. L["COPYPOSSCALE"]
		info.func = function()
			CloseDropDownMenus()
			
			local dest = db.profile.Groups[CI.g]
			dest.Point = CopyTable(TMW.Group_Defaults.Point) -- not a special table (["**"]), so just normally copy it. Setting it nil won't recreate it like other settings tables, so re-copy from defaults
			TMW:CopyTableInPlaceWithMeta(group_src.Point, dest.Point)

			dest.Scale = group_src.Scale or TMW.Group_Defaults.Scale
			dest.Level = group_src.Level or TMW.Group_Defaults.Level
			TMW:Group_Update(CI.g)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		-- copy entire group - overwrite current
		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYGROUP"] .. " - " .. L["OVERWRITEGROUP"]:format(TMW:GetGroupName(CI.g, CI.g, 1))
		info.func = function()
			TMW:Import(group_src, version_src, "group", nil, groupID)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		-- copy entire group - create new group
		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYGROUP"] .. " - " .. L["MAKENEWGROUP"]
		info.func = function()
			TMW:Import(group_src, version_src, "group", true, groupID) -- true forces a new group to be created
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		if group_src.Icons and #group_src.Icons > 0 then
			AddDropdownSpacer()
			
			-- icon header
			info = UIDropDownMenu_CreateInfo()
			info.text = L["UIPANEL_ICONS"]
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			
			-- add individual icons
			for iconID, ics in TMW:OrderedPairs(group_src.Icons) do
				IE:AddIconToCopyDropdown(ics, groupID, iconID, profilename, group_src, version_src)
			end
		end
	elseif profilename and profile_src then
		-- header
		info = UIDropDownMenu_CreateInfo()
		info.text = profilename
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
		-- copy entire profile - overwrite current
		info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_OVERWRITE"]:format(db:GetCurrentProfile())
		info.func = function()
			TMW:Import(profile_src, version_src, "global")
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		-- copy entire profile - create new profile
		info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_NEW"]
		info.func = function()
			TMW:Import(profile_src, version_src, "global", profilename) -- newname forces a new profile to be created named newname
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		AddDropdownSpacer()
		-- group header
		info = UIDropDownMenu_CreateInfo()
		info.text = L["UIPANEL_GROUPS"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
		-- add groups to be copied
		for groupID, v in TMW:OrderedPairs(profile_src.Groups) do
			if type(groupID) == "number" and groupID >= 1 and groupID <= (tonumber(profile_src.NumGroups) or 10) then -- group was a string once, so lets just be safe
				info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(profile_src.Groups[groupID].Name, groupID)
				info.value = UIDROPDOWNMENU_MENU_VALUE .. "_" .. groupID
				info.hasArrow = true
				info.notCheckable = true
				info.tooltipTitle = format(L["fGROUP"], groupID)
				info.tooltipText = 	(L["UIPANEL_ROWS"] .. ": " .. (v.Rows or 1) .. "\r\n") ..
								L["UIPANEL_COLUMNS"] .. ": " .. (v.Columns or 4) ..
								((v.PrimarySpec or v.PrimarySpec == nil) and "\r\n" .. L["UIPANEL_PRIMARYSPEC"] or "") ..
								((v.SecondarySpec or v.SecondarySpec == nil) and "\r\n" .. L["UIPANEL_SECONDARYSPEC"] or "") ..
								((v.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")
				info.tooltipOnButton = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
	
end



-- ----------------------
-- UNDO/REDO
-- ----------------------

IE.RapidSettings = {
	-- settings that can be changed very rapidly, i.e. via mouse wheel or in a color picker
	r = true,
	g = true,
	b = true,
	Size = true,
	Level = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
}


---------- Comparison ----------
function IE:DeepCompare(t1, t2, ...)
	-- heavily modified version of http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
	
	-- attempt direct comparison
	if t1 == t2 then
		return true, ...
	end
	
	-- if the values are not the same (they made it through the check above) AND they are not both tables, then they cannot be the same, so exit.
	local ty1 = type(t1)
	if ty1 ~= "table" or ty1 ~= type(t2) then
		return false, ...
	end
	
	-- compare table values
	
	-- compare table 1 with table 2
	for k1, v1 in pairs(t1) do
		local v2 = t2[k1]
		
		-- don't bother calling DeepCompare on the values if they are the same - it will just return true.
		-- Only call it if the values are different (they are either 2 tables, or they actually are different non-table values)
		-- by adding the (v1 ~= v2) check, efficiency is increased by about 300%.
		if v1 ~= v2 and not IE:DeepCompare(v1, v2, k1, ...) then
		
			-- it only reaches this point if there is a difference between the 2 tables somewhere
			-- so i dont feel bad about calling DeepCompare with the same args again
			-- i need to because the key of the setting that changed is in there, and AttemptBackup needs that key
			return IE:DeepCompare(v1, v2, k1, ...)
		end
	end
	
	-- compare table 2 with table 1
	for k2, v2 in pairs(t2) do
		local v1 = t1[k2]
		
		-- see comments for t1
		if v1 ~= v2 and not IE:DeepCompare(v1, v2, k2, ...) then
			return IE:DeepCompare(v1, v2, k2, ...)
		end
	end
	
	return true, ...
end

function IE:GetCompareResultsPath(match, ...)
	if match then
		return true
	end
	local path = ""
	local setting
	for i, v, size in TMW:Vararg(...) do
		if i == 1 then
			setting = v
		end
		path = path .. v .. "\001"
	end
	return path, setting
end


---------- DoStuff ----------
function IE:AttemptBackup(icon)
	if not icon then return end
	
	if not icon.history then
		-- create the needed infrastructure for storing icon history if it does not exist.
		-- this includes creating the first history point
		icon.history = {TMW:CopyWithMetatable(icon:GetSettings())}
		icon.historyState = #icon.history
	
		-- notify the undo and redo buttons that there was a change so they can :Enable() or :Disable()
		IE:UndoRedoChanged()
	else
		-- the needed stuff for undo and redu already exists, so lets delve into the meat of the process.
		
		-- compare the current icon settings with what we have in the currently used history point
		-- the currently used history point may or may not be the most recent settings of the icon, but we want to check ics against what is being used.
		-- result is either (true) if there were no changes in the settings, or a string representing the key path to the first setting change that was detected.
		--(it was likely only one setting that changed, but not always)
		local result, changedSetting = IE:GetCompareResultsPath(IE:DeepCompare(icon.history[icon.historyState], icon:GetSettings()))
		if type(result) == "string" then
			-- if we are using an old history point (i.e. we hit undo a few times and then made a change), 
			-- delete all history points from the current one forward so that we dont jump around wildly when undoing and redoing
			for i = icon.historyState + 1, #icon.history do
				icon.history[i] = nil
			end
			
			-- if the last setting that was changed is the same as the most recent setting that was changed,
			-- and if the setting is one that can be changed very rapidly,
			-- delete the previous history point so that we dont murder our memory usage and piss off the user as they undo a number from 1 to 10, 0.1 per click.
			if icon.lastChangePath == result and IE.RapidSettings[changedSetting] then
				icon.history[#icon.history] = nil
				icon.historyState = #icon.history
			end
			icon.lastChangePath = result
			
			-- finally, create the newest history point.
			-- we copy with with the metatable so that when doing comparisons against the current icon settings, we can invoke metamethods.
			-- this is needed because otherwise an empty event table (icon:GetSettings().Events) will not match a fleshed out one that has no non-default data in it.
			icon.history[#icon.history + 1] = TMW:CopyWithMetatable(icon:GetSettings())
			
			-- set the history state to the latest point
			icon.historyState = #icon.history
			-- notify the undo and redo buttons that there was a change so they can :Enable() or :Disable()
			IE:UndoRedoChanged()
		end
	end
end

function IE:DoUndoRedo(direction)
	local icon = CI.ic
	
	if not icon.history[icon.historyState + direction] then return end -- not valid, so don't try
		
	icon.historyState = icon.historyState + direction
	
	db.profile.Groups[CI.g].Icons[CI.i] = nil -- recreated when passed into CTIPWM	
	TMW:CopyTableInPlaceWithMeta(icon.history[icon.historyState], db.profile.Groups[CI.g].Icons[CI.i])
	
	TMW:Icon_Update(CI.ic) -- do an immediate update for good measure
	
	IE:Load(1)
end


---------- Interface ----------
function IE:UndoRedoChanged()
	local icon = TMW.CI.ic
	if not icon then return end
	
	if icon.historyState - 1 < 1 then
		IE.UndoButton:Disable()
		IE.CanUndo = false
	else
		IE.UndoButton:Enable()
		IE.CanUndo = true
	end
	
	if icon.historyState + 1 > #icon.history then
		IE.RedoButton:Disable()
		IE.CanRedo = false
	else
		IE.RedoButton:Enable()
		IE.CanRedo = true
	end
end



-- ----------------------
-- EVENTS
-- ----------------------

local EVENTS = TMW:NewModule("Events") TMW.EVENTS = EVENTS

function EVENTS:SetEventSettings()
	local EventSettings = self.EventSettings
	local eventData = self.Events[self.currentEventID].eventData
	
	EventSettings.EventName:SetText(eventData.text) --L["EVENTS_SETTINGS_HEADER_SUB"]:format(eventData.text))
	
	local Settings = TMW.CI.ics.Events[self.currentEvent]
	local settingsUsedByEvent = eventData.settings
	
	--hide settings
	EventSettings.Operator	 	 :Hide()
	EventSettings.Value		 	 :Hide()
	EventSettings.CndtJustPassed :Hide()
	EventSettings.PassingCndt	 :Hide()
	
	--set settings
	EventSettings.PassThrough	 :SetChecked(Settings.PassThrough)
	EventSettings.OnlyShown	 	 :SetChecked(Settings.OnlyShown)
	EventSettings.CndtJustPassed :SetChecked(Settings.CndtJustPassed)
	EventSettings.PassingCndt	 :SetChecked(Settings.PassingCndt)
	EventSettings.Value		 	 :SetText(Settings.Value)
	
	--show settings
	if settingsUsedByEvent then
		for setting, state in pairs(settingsUsedByEvent) do
			if state == "FORCE" then
				EventSettings[setting]:Disable()
				EventSettings[setting]:SetAlpha(1)
			else
				EventSettings[setting]:Enable()
			end
			EventSettings[setting]:Show()
		end
	end
	
	if EventSettings.PassingCndt				:GetChecked() then
		EventSettings.Operator.ValueLabel		:SetFontObject(GameFontHighlight)
		EventSettings.Operator					:Enable()
		EventSettings.Value						:Enable()
		if not settingsUsedByEvent.CndtJustPassed == "FORCE" then
			EventSettings.CndtJustPassed		:Enable()
		end
	else
		EventSettings.Operator.ValueLabel		:SetFontObject(GameFontDisable)
		EventSettings.Operator					:Disable()
		EventSettings.Value						:Disable()
		EventSettings.CndtJustPassed			:Disable()
	end
	
	EventSettings.Operator.ValueLabel:SetText(eventData.valueName)
	EventSettings.Value.ValueLabel:SetText(eventData.valueSuffix)
	
	local v = TMW:SetUIDropdownText(EventSettings.Operator, Settings.Operator, CNDT.Operators)
	if v then
		TMW:TT(EventSettings.Operator, v.tooltipText, nil, 1)
	end	
end

function EVENTS:OperatorMenu_DropDown()
	local Module = self:GetParent():GetParent().module
	local eventData = Module.Events[Module.currentEventID].eventData
	
	for k, v in pairs(CNDT.Operators) do
		if not eventData.blacklistedOperators or not eventData.blacklistedOperators[v.value] then
			local info = UIDropDownMenu_CreateInfo()
			info.func = EVENTS.OperatorMenu_DropDown_OnClick
			info.text = v.text
			info.value = v.value
			info.tooltipTitle = v.tooltipText
			info.tooltipOnButton = true
			info.arg1 = self
			UIDropDownMenu_AddButton(info)
		end
	end
end

function EVENTS:OperatorMenu_DropDown_OnClick(frame)
	local Module = frame:GetParent():GetParent().module
	
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	
	TMW.CI.ics.Events[Module.currentEvent].Operator = self.value
	TMW:TT(frame, self.tooltipTitle, nil, 1)
end

function EVENTS:SetupEventButtons(template, globalDescKey)
	local Events = self.Events
	local previousFrame
	
	--[[local yAdjustTitle, yAdjustText = 0, 0 -- not needed for now
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		yAdjustTitle, yAdjustText = 3, -3
	end]]
	
	for i, eventData in ipairs(TMW.EventList) do
		local frame = CreateFrame("Button", Events:GetName().."Event"..i, Events, template, i)
		Events[i] = frame
		frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT")
		frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
		
		local p, t, r, x, y = frame.EventName:GetPoint()
		frame.EventName:SetPoint(p, t, r, x, y --[[+ yAdjustTitle]])
		local p, t, r, x, y = frame.DataText:GetPoint()
		frame.DataText:SetPoint(p, t, r, x, y --[[+ yAdjustText]])
		
		frame.event = eventData.name
		frame.eventData = eventData
		
		frame.EventName:SetText(eventData.text .. ":")
		
		frame.normalDesc = eventData.desc --.. "\r\n\r\n" .. L[globalDescKey]
		TMW:TT(frame, eventData.text, frame.normalDesc, 1, 1)
		
		previousFrame = frame
	end
	
	Events[1]:SetPoint("TOPLEFT", Events, "TOPLEFT", 0, 0)
	Events[1]:SetPoint("TOPRIGHT", Events, "TOPRIGHT", 0, 0)
	Events:SetHeight(#Events*Events[1]:GetHeight())
end

function EVENTS:EnableAndDisableEvents()
	local DisabledEvents = Types[CI.ic].DisabledEvents
	local oldID = self.currentEventID
	for i, frame in ipairs(self.Events) do
		if DisabledEvents[frame.event] then
			frame:Disable()
			frame.DataText:SetText(L["SOUND_EVENT_DISABLEDFORTYPE"])
			TMW:TT(frame, frame.eventData.text, L["SOUND_EVENT_DISABLEDFORTYPE_DESC"]:format(Types[CI.t].name), 1, 1)
			
			if oldID == i then
				oldID = oldID + 1
			end
		else
			TMW:TT(frame, frame.eventData.text, frame.normalDesc, 1, 1)
			frame:Enable()
			self:SetupEventDisplay(i)
		end
	end
	
	return oldID
end

function EVENTS:ChooseEvent(id)
	self.currentEventID = id
	self.currentEvent = self.Events[id].event

	local eventFrame = self.Events[id]
	for i, f in ipairs(self.Events) do
		f.selected = nil
		f:UnlockHighlight()
		f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end
	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	
	return eventFrame
end

function EVENTS:GetDisplayInfo(event)

	-- event is either a string ("OnShow") or a frame id (1)
	
	-- determine eventID or eventString, whichever is unknown.
	local eventID
	local eventString
	if type(event) == "string" then
		eventString = event
		for id, frame in ipairs(self.Events) do
			if frame.event == eventString then
				eventID = id
				break
			end
		end
	else
		eventID = event
		eventString = self.Events[eventID].event
	end
	
	return eventID, eventString
end

function EVENTS:Load()
	local oldID = self:EnableAndDisableEvents()
	
	if oldID and oldID > 0 then
		oldID = oldID % #self.Events
		if oldID == 0 then
			oldID = #self.Events
		end
		self:SelectEvent(oldID)
	end
	self:SetTabText()
	
	if CI.ics then
		self:SetEventSettings()
	end
end

function EVENTS:SetTabText()
	local n = self:GetNumUsedEvents()
	
	if n > 0 then
		self.tab:SetText(self.tabText .. " |cFFFF5959(" .. n .. ")")
	else
		self.tab:SetText(self.tabText .. " (" .. n .. ")")
	end
	PanelTemplates_TabResize(self.tab, -6)
end



-- ----------------------
-- SOUNDS
-- ----------------------

SND = TMW:NewModule("Sound", EVENTS) TMW.SND = SND
SND.tabText = L["SOUND_TAB"]
SND.LSM = LSM

function SND:OnInitialize()
	SND.tab = IE.SoundTab

	local Sounds = SND.Sounds
	Sounds.Header:SetText(L["SOUND_SOUNDTOPLAY"])
	local previous = Sounds.None
	SND[0] = previous
	previous:SetPoint("TOPLEFT", Sounds, "TOPLEFT", 0, 0)
	previous:SetPoint("TOPRIGHT", Sounds, "TOPRIGHT", 0, 0)
	previous.Name:SetText(NONE)
	previous.Play:Hide()
	previous.soundfile = ""
	previous.soundname = "None"
	for i=1, floor(Sounds:GetHeight()/Sounds.None:GetHeight()) - 1 do
		local f = CreateFrame("Button", Sounds:GetName().."Sound"..i, Sounds, "TellMeWhen_SoundSelectButton", i)
		Sounds[i] = f
		f:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
		f:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, 0)
		previous = f
	end
	SND:SetSoundsOffset(0)
	
	
	SND:SetupEventButtons("TellMeWhen_SoundEvent", "SOUND_EVENT_GLOBALDESC")
	
	local Events = SND.Events
	Events.Header:SetText(L["SOUND_EVENTS"])
	SND:SelectEvent(1)	
	
	SND.Sounds.ScrollBar:SetValue(0)
end


---------- Events ----------
function SND:SelectEvent(id)
	local eventFrame = SND:ChooseEvent(id)
	
	if CI.ics then
		SND:SelectSound(CI.ics.Events[eventFrame.event].Sound)
		SND:SetEventSettings()
	end
end

function SND:SetupEventDisplay(event)
	local eventID, eventString = SND:GetDisplayInfo(event)
	
	local name = CI.ics.Events[eventString].Sound
	
	if name == "None" then
		name = "|cff808080" .. NONE
	end
	
	SND.Events[eventID].DataText:SetText(name)
end


---------- Sounds ----------
function SND:SetSoundsOffset(offs)
	if not SND.List or #LSM:List("sound")-1 ~= #SND.List then
		SND.List = CopyTable(LSM:List("sound"))
		
		for k, v in pairs(SND.List) do
			if v == "None" then
				tremove(SND.List, k)
				break
			end
		end
		sort(SND.List, function(a, b)
			local TMWa = strsub(a, 1, 3) == "TMW"
			local TMWb = strsub(b, 1, 3) == "TMW"
			if TMWa or TMWb then
				if TMWa and TMWb then
					return a < b
				else
					return TMWa
				end
			else
				return a < b
			end

		end)
	end
	SND.offs = offs

	for i=1, #SND.Sounds do
		local f = SND.Sounds[i]
		if f then
			local n = i + offs
			local name = SND.List[n]
			if name then
				f.soundname = name
				f.Name:SetText(name)
				f.soundfile = LSM:Fetch("sound", name)
				f:Show()
				if n == SND.selectedListID then
					f:LockHighlight()
					f:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
				else
					f:UnlockHighlight()
					f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
				end
			else
				f:Hide()
			end
			f.listID = n
		end
	end

	if max(0, #SND.List - #SND.Sounds) == 0 then
		SND.Sounds.ScrollBar:Hide()
	else
		SND.Sounds.ScrollBar:SetMinMaxValues(0, #SND.List - #SND.Sounds)
	end
end

function SND:SelectSound(name)
	if not name then return end
	local soundFrame, listID

	for k, listname in ipairs(SND.List) do
		if listname == name then
			listID = k
			break
		end
	end

	if listID and (listID > SND.Sounds[#SND.Sounds].listID or listID < SND.Sounds[1].listID) then
		SND.Sounds.ScrollBar:SetValue(listID-1)
	else
		 SND:SetSoundsOffset(SND.offs)
	end

	for i, frame in ipairs(SND.Sounds) do
		if frame.soundname == name then
			soundFrame = frame
		end
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end

	SND.selectedListID = 0
	SND.Custom.selected = nil
	SND.Custom.Background:Hide()
	SND.Custom.Background:SetVertexColor(1, 1, 1, 1)
	SND.Custom:SetText("")
	SND.Sounds.None:UnlockHighlight()
	SND.Sounds.None:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)

	if name == "None" then
		SND.selectedListID = -1 -- lame
		SND.Sounds.None:LockHighlight()
		SND.Sounds.None:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif soundFrame then
		SND.selectedListID = soundFrame.listID
		soundFrame:LockHighlight()
		soundFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif strfind(name, "%.[^\\]+$") then
		SND.Custom.selected = 1
		SND.Custom.Background:Show()
		SND.Custom.Background:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		SND.Custom:SetText(name)
	end
	
	SND:SetTabText()
end


---------- Interface ----------
function SND:GetNumUsedEvents()
	local n = 0
	for i, f in ipairs(SND.Events) do
		local v = CI.ics.Events[f.event].Sound
		if v == "" or v == "Interface\\Quiet.ogg" or v == "None" then
			-- none
		elseif strfind(v, "%.[^\\]+$") then
			n = n + 1
		else
			local s = LSM:Fetch("sound", v)
			if s and s ~= "Interface\\Quiet.ogg" and s ~= "" then
				n = n + 1
			else
				--fail
			end
		end
	end
	
	return n
end



-- ----------------------
-- ANNOUNCEMENTS
-- ----------------------

ANN = TMW:NewModule("Announcements", EVENTS) TMW.ANN = ANN
ANN.tabText = L["ANN_TAB"]
local ChannelLookup = TMW.ChannelLookup

function ANN:OnInitialize()
	ANN.tab = IE.AnnounceTab
	
	local Events = ANN.Events
	local Channels = ANN.Channels
	
	Events.Header:SetText(L["SOUND_EVENTS"])
	Channels.Header:SetText(L["ANN_CHANTOUSE"])
	
	-- create event frames
	ANN:SetupEventButtons("TellMeWhen_AnnounceEvent", "ANN_EVENT_GLOBALDESC")
	
	-- create channel frames
	local previousFrame
	local offs = 0
	for i, channelData in ipairs(TMW.ChannelList) do
		if not channelData.hidden then
			i = i + offs
			local frame = CreateFrame("Button", Channels:GetName().."Channel"..i, Channels, "TellMeWhen_ChannelSelectButton", i)
			Channels[i] = frame
			frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
			frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
			frame:Show()
			
			frame.channel = channelData.channel
			
			frame.Name:SetText(channelData.text)
			TMW:TT(frame, channelData.text, channelData.desc, 1, 1)
			
			previousFrame = frame
		else
			offs = offs - 1
		end
	end
	
	Channels[1]:SetPoint("TOPLEFT", Channels, "TOPLEFT", 0, 0)
	Channels[1]:SetPoint("TOPRIGHT", Channels, "TOPRIGHT", 0, 0)
	
	Channels:SetHeight(#Channels*Channels[1]:GetHeight())
	
	ANN:SelectEvent(1)	
end


---------- Events ----------
function ANN:SelectEvent(id)
	ANN.EditBox:ClearFocus()
	
	local eventFrame = ANN:ChooseEvent(id)
	
	if CI.ics then
		local EventSettings = CI.ics.Events[eventFrame.event]
		ANN:SelectChannel(EventSettings.Channel)
		ANN.EditBox:SetText(EventSettings.Text)
		ANN:SetEventSettings()
	end
end

function ANN:SetupEventDisplay(event)
	local eventID, eventString = ANN:GetDisplayInfo(event)
	
	local channel = CI.ics.Events[eventString].Channel
	local channelsettings = ChannelLookup[channel]
	
	if channelsettings then
		local text = channelsettings.text
		if text == NONE then
			text = "|cff808080" .. text
		end
		ANN.Events[eventID].DataText:SetText(text)
	end
end


---------- Channels ----------
function ANN:SelectChannel(channel)
	local EventSettings = CI.ics.Events[ANN.Events[ANN.currentEventID].event]
	local channelFrame

	for i=1, #ANN.Channels do
		local f = ANN.Channels[i]
		if f then
			if f.channel == channel then
				channelFrame = f
			end
			f.selected = nil
			f:UnlockHighlight()
			f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
		end
	end
	ANN.currentChannelSetting = channel

	local channelsettings = ChannelLookup[channel]
	if channelsettings then
		if channelsettings.sticky then
			ANN.Sticky:SetChecked(EventSettings.Sticky)
			ANN.Sticky:Show()
		else
			ANN.Sticky:Hide()
		end
		if channelsettings.icon then
			ANN.Icon:SetChecked(EventSettings.Icon)
			ANN.Icon:Show()
		else
			ANN.Icon:Hide()
		end
		if channelsettings.defaultlocation then
			local defaultlocation = get(channelsettings.defaultlocation)
			local location = EventSettings.Location
			location = location and location ~= "" and location or defaultlocation
			location = channelsettings.ddtext(location) and location or defaultlocation
			EventSettings.Location = location
			local loc = channelsettings.ddtext(location)
			UIDropDownMenu_SetSelectedValue(ANN.Location, location)
			UIDropDownMenu_SetText(ANN.Location, loc)
			ANN.Location:Show()
		else
			ANN.Location:Hide()
		end
		if channelsettings.color then
			local r, g, b = EventSettings.r, EventSettings.g, EventSettings.b
			ANN.Color:GetNormalTexture():SetVertexColor(r, g, b, 1)
			ANN.Color:Show()
		else
			ANN.Color:Hide()
		end
		if channelsettings.size then
			ANN.Size:SetValue(EventSettings.Size)
			ANN.Size:Show()
		else
			ANN.Size:Hide()
		end
		if channelsettings.editbox then
			ANN.WhisperTarget:SetText(EventSettings.Location)
			ANN.WhisperTarget:Show()
		else
			ANN.WhisperTarget:Hide()
		end
	end

	if channelFrame then
		channelFrame:LockHighlight()
		channelFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end
	if ANN.currentEventID and channelsettings then
		local text = channelsettings.text
		if text == NONE then
			text = "|cff808080" .. text
		end
		ANN.Events[ANN.currentEventID].DataText:SetText(text)
	end
	ANN:SetTabText()
end


---------- Interface ----------
function ANN:GetNumUsedEvents()
	local n = 0
	for i = 1, #ANN.Events do
		local f = ANN.Events[i]
		local channel = CI.ics.Events[f.event].Channel
		if channel and #channel > 2 and channel ~= "None" then
			n = n + 1
		end
	end
	
	return n
end

function ANN:LocDropdownFunc(text)
	UIDropDownMenu_SetSelectedValue(ANN.Location, self.value)
	UIDropDownMenu_SetText(ANN.Location, text)
	CI.ics.Events[ANN.currentEvent].Location = self.value
end

function ANN:DropDown()
	local channelSettings = ChannelLookup[ANN.currentChannelSetting]
	if channelSettings and channelSettings.dropdown then
		channelSettings.dropdown()
	end
end



-- ----------------------
-- SUGGESTER
-- ----------------------

SUG = TMW:NewModule("Suggester", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0") TMW.SUG = SUG


---------- Locals/Data ----------
local SUGIsNumberInput
local SUGpreTable = {}
local SUGPlayerSpells = {}
local pclassSpellCache, ClassSpellLookup, AuraCache, ItemCache, SpellCache, CastCache, CurrentItems
local TrackingCache = {}
for i = 1, GetNumTrackingTypes() do
	local name, _, active = GetTrackingInfo(i)
	TrackingCache[i] = strlower(name)
end


---------- Initialization/Database/Spell Caching ----------
function SUG:OnInitialize()	
	TMWOptDB = TMWOptDB or {}

	CNDT:CURRENCY_DISPLAY_UPDATE() -- im in ur SUG, hijackin' ur OnInitialize

	TMWOptDB.SpellCache = TMWOptDB.SpellCache or {}
	TMWOptDB.CastCache = nil -- not used anymore, spells are validated as they are displayed now.
	TMWOptDB.ItemCache = TMWOptDB.ItemCache or {}
	TMWOptDB.AuraCache = TMWOptDB.AuraCache or {}
	TMWOptDB.ClassSpellCache = nil -- this is old, get rid of it
	
	CurrentItems = {}

	for k, v in pairs(TMWOptDB) do
		SUG[k] = v
	end
	SUG.ClassSpellCache = TMW.ClassSpellCache -- just in case

	if TMW.AuraCache ~= SUG.AuraCache then -- desprate attempt to fix the problem where the aura cache randomly decides to reset itself. LATER: YAY, I FIGURED IT OUT. I was calling SUG:OnInitialize() in some testing, which was causing it to delete all of its keys. this check will prevent that from now on.
		for k, v in pairs(TMW.AuraCache) do
			-- import into the options DB and take it out of the main DB
			SUG.AuraCache[k] = SUG.AuraCache[k] or v or SUG.AuraCache[k]
			TMW.AuraCache[k] = nil
		end
		TMW.AuraCache = SUG.AuraCache -- make new inserts go into the optionDB and this table
	end

	SUG.RequestedFrom = {}
	SUG.commThrowaway = {}
	SUG.Box = IE.Main.Name
	
	SUG:PLAYER_TALENT_UPDATE()
	SUG:BuildClassSpellLookup() -- must go before the local versions (ClassSpellLookup) are defined
	SUG.doUpdateItemCache = true

	SUG:RegisterComm("TMWSUG")
	SUG:RegisterEvent("PLAYER_TALENT_UPDATE")
	SUG:RegisterEvent("PLAYER_ENTERING_WORLD")
	SUG:RegisterEvent("UNIT_PET")
	SUG:RegisterEvent("BAG_UPDATE")
	SUG:RegisterEvent("BANKFRAME_OPENED", "BAG_UPDATE")
	SUG:RegisterEvent("GET_ITEM_INFO_RECEIVED")

	if IsInGuild() then
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "GUILD")
	end

	pclassSpellCache,				ClassSpellLookup,		AuraCache,		ItemCache,		SpellCache =
	TMW.ClassSpellCache[pclass],	SUG.ClassSpellLookup,	SUG.AuraCache,	SUG.ItemCache,	SUG.SpellCache

	SUG:PLAYER_ENTERING_WORLD()

	local _, _, _, clientVersion = GetBuildInfo()
	if TMWOptDB.IncompleteCache or not TMWOptDB.WoWVersion or TMWOptDB.WoWVersion < clientVersion then
		local didrunhook
		IE:HookScript("OnShow", function()
			if didrunhook then return end
			
			do	--validate all old items in the item cache
			
				-- function to call once data about items has been collected from the server
				function SUG:ValidateItemIDs()
					--all data should be in by now, see what actually exists.
					for id in pairs(ItemCache) do
						if not GetItemInfo(id) then
							ItemCache[id] = nil
						end
					end
					SUG.ValidateItemIDs = nil
				end
					
				--start the requests
				for id in pairs(ItemCache) do
					GetItemInfo(id)
				end
				
				SUG:ScheduleTimer("ValidateItemIDs", 60)
			end
					
					
			TMWOptDB.IncompleteCache = true
			SUG.NumCachePerFrame = 1

			local Blacklist = {
				["Interface\\Icons\\Trade_Alchemy"] = true,
				["Interface\\Icons\\Trade_BlackSmithing"] = true,
				["Interface\\Icons\\Trade_BrewPoison"] = true,
				["Interface\\Icons\\Trade_Engineering"] = true,
				["Interface\\Icons\\Trade_Engraving"] = true,
				["Interface\\Icons\\Trade_Fishing"] = true,
				["Interface\\Icons\\Trade_Herbalism"] = true,
				["Interface\\Icons\\Trade_LeatherWorking"] = true,
				["Interface\\Icons\\Trade_Mining"] = true,
				["Interface\\Icons\\Trade_Tailoring"] = true,
				["Interface\\Icons\\INV_Inscription_Tradeskill01"] = true,
				["Interface\\Icons\\Temp"] = true,
			}
			
			local index, spellsFailed = 0, 0
			
			TMWOptDB.CacheLength = TMWOptDB.CacheLength or 11000
			
			SUG.Suggest.Status:Show()
			SUG.Suggest.Status.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
			SUG.Suggest.Status:SetMinMaxValues(1, TMWOptDB.CacheLength)
			SUG.Suggest.Speed:Show()
			SUG.Suggest.Finish:Show()
			
			if TMWOptDB.WoWVersion and TMWOptDB.WoWVersion < clientVersion then
				wipe(SUG.SpellCache)
			elseif TMWOptDB.IncompleteCache then
				for id in pairs(SUG.SpellCache) do
					index = max(index, id)
				end
			end
			TMWOptDB.WoWVersion = clientVersion

			local Parser, LT1 = SUG:GetParser()
			
			local SPELL_CAST_CHANNELED = SPELL_CAST_CHANNELED
			local yield, resume = coroutine.yield, coroutine.resume

			local function SpellCacher()
				
				while spellsFailed < 1000 do
					
					local name, rank, icon = GetSpellInfo(index)
					if name then
						name = strlower(name)
						
						local fail = 
						Blacklist[icon] or
						strfind(name, "dnd") or
						strfind(name, "test") or
						strfind(name, "debug") or
						strfind(name, "bunny") or
						strfind(name, "visual") or
						strfind(name, "trigger") or
						strfind(name, "[%[%%%+%?]") or -- no brackets, plus signs, percent signs, or question marks
						strfind(name, "quest") or
						strfind(name, "vehicle") or
						strfind(name, "event") or
						strfind(name, ":%s?%d") or -- interferes with colon duration syntax
						strfind(name, "camera") or
						strfind(name, "dmg")
						
						if not fail then
							if index ~= 109388 then -- critical error if this gets set. See ticket 313. TODO: Check and see if this is still broken
								Parser:SetOwner(UIParent, "ANCHOR_NONE") -- must set the owner before text can be obtained.
								Parser:SetSpellByID(index)
							end
							local r, g, b = LT1:GetTextColor()
							if g > .95 and r > .95 and b > .95 then
								SpellCache[index] = name
							end
							spellsFailed = 0
						end
					else
						spellsFailed = spellsFailed + 1
					end
					index = index + 1
					
					if index % SUG.NumCachePerFrame == 0 then
						SUG.Suggest.Status:SetValue(index)
						yield()
					end
				end
			end
			local co = coroutine.create(SpellCacher)
			
			local f = CreateFrame("Frame")
			f:SetScript("OnUpdate", function()
				if not resume(co) then
					TMWOptDB.IncompleteCache = false
					TMWOptDB.CacheLength = index
					
					f:SetScript("OnUpdate", nil)
					
					SUG.Suggest.Speed:Hide()
					SUG.Suggest.Status:Hide()
					SUG.Suggest.Finish:Hide()
					
					
					SpellCache[1852] = nil -- GM spell named silenced, interferes with equiv
					SpellCache[47923] = nil -- spell named stunned, interferes
					SpellCache[65918] = nil -- spell named stunned, interferes
					SpellCache[78320] = nil -- spell named stunned, interferes
					SpellCache[71216] = nil -- enraged
					SpellCache[59208] = nil -- enraged
					SpellCache[100000] = GetSpellInfo(100000) and strlower(GetSpellInfo(100000)) -- filted out by default but this spell really needs to be in the list because of how cool it is
					
					SUG.IsCaching = nil
					if SUG.onCompleteCache then
						SUG.onCompleteCache = nil
						TMW.SUG.redoIfSame = 1
						SUG:NameOnCursor()
					end

					co = nil
					Parser:Hide()
					collectgarbage()
				end
			end)
			SUG.IsCaching = true
			didrunhook = true
		end)
	end
end

do
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3
	function SUG:GetParser()
		if not Parser then
			Parser = CreateFrame("GameTooltip")
			
			LT1 = Parser:CreateFontString()
			RT1 = Parser:CreateFontString()
			Parser:AddFontStrings(LT1, RT1)
			
			LT2 = Parser:CreateFontString()
			RT2 = Parser:CreateFontString()
			Parser:AddFontStrings(LT2, RT2)
			
			LT3 = Parser:CreateFontString()
			RT3 = Parser:CreateFontString()
			Parser:AddFontStrings(LT3, RT3)
		end
		return Parser, LT1, LT2, LT3, RT1, RT2, RT3
	end
end

---------- Events ----------
function SUG:UNIT_PET(event, unit)
	if unit == "player" and HasPetSpells() then
		local Cache = TMW.ClassSpellCache.PET
		local i = 1
		while true do
			local _, id = GetSpellBookItemInfo(i, "pet")
			if id then
				Cache[id] = pclass
			else
				break
			end
			i=i+1
		end
		SUG.updatePlayerSpells = 1
	end
end

function SUG:PLAYER_ENTERING_WORLD()
	local NumRealRaidMembers = GetRealNumRaidMembers()
	local NumRealPartyMembers = GetRealNumPartyMembers()
	local NumRaidMembers = GetNumRaidMembers()

	if (NumRealRaidMembers > 0) and (NumRealRaidMembers ~= (SUG.OldNumRealRaidMembers or 0)) then
		SUG.OldNumRealRaidMembers = NumRealRaidMembers
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "RAID")

	elseif (NumRealRaidMembers == 0) and (NumRealPartyMembers > 0) and (NumRealPartyMembers ~= (SUG.OldNumRealPartyMembers or 0)) then
		SUG.OldNumRealPartyMembers = NumRealPartyMembers
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "PARTY")

	elseif UnitInBattleground("player") and (NumRaidMembers ~= (SUG.OldNumRaidMembers or 0)) then
		SUG.OldNumRaidMembers = NumRaidMembers
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "BATTLEGROUND")
	end

end

function SUG:PLAYER_TALENT_UPDATE()
	local t = TMW.ClassSpellCache[pclass]
	local _, RACIAL = GetSpellInfo(20572) -- blood fury, we need the localized "Racial" string
	local  _, _, _, endgeneral = GetSpellTabInfo(1)
	local _, _, offs, numspells = GetSpellTabInfo(4)
	local _, race = UnitRace("player")
	for i = 1, offs + numspells do
		local _, id = GetSpellBookItemInfo(i, "player")
		if id then
			local name, rank = GetSpellInfo(id)
			if rank == RACIAL then
				TMW.ClassSpellCache.RACIAL[id] = race
			elseif i > endgeneral then
				t[id] = 1
			end
		end
	end
	SUG.updatePlayerSpells = 1
end

function SUG:BAG_UPDATE()
	SUG.doUpdateItemCache = true
end

function SUG:GET_ITEM_INFO_RECEIVED()
	if SUG.CurrentModule and SUG.CurrentModule.moduleName:find("item") then
		SUG:SuggestingComplete()
	end
end


---------- Comm ----------
function SUG:OnCommReceived(prefix, text, channel, who)
	if prefix ~= "TMWSUG" or who == UnitName("player") then return end
	local success, arg1, arg2 = SUG:Deserialize(text)
	if success then
		if arg1 == "RCSL" and not SUG.RequestedFrom[who] then -- only send if the player has not requested yet this session
			SUG:BuildClassSpellLookup()
			SUG:SendCommMessage("TMWSUG", SUG:Serialize("CSL", SUG.ClassSpellLength), "WHISPER", who)
			SUG.RequestedFrom[who] = true
		elseif arg1 == "CSL" then
			wipe(SUG.commThrowaway)
			local RecievedClassSpellLength = arg2
			SUG:BuildClassSpellLookup()
			if not RecievedClassSpellLength.RACIAL then return end -- VERY IMPORTANT - OLD VERSIONS WILL NOT HAVE THE RACIAL TABLE, THIS IS HOW I AM GOING TO DISTINGUISH BETWEEN OLD AND NEW VERSIONS (NEW VERSION BEING 4.4.1+; STORES CLASS SPELLS IN DB.PROFILE.GLOBAL)
			for class, length in pairs(RecievedClassSpellLength) do
				if (not SUG.ClassSpellLength[class]) or (SUG.ClassSpellLength[class] < length) then
					tinsert(SUG.commThrowaway, class)
				end
			end
			if #SUG.commThrowaway > 0 then
				SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSC", SUG.commThrowaway), "WHISPER", who)
			end
		elseif arg1 == "RCSC" then
			wipe(SUG.commThrowaway)
			for _, class in pairs(arg2) do
				SUG.commThrowaway[class] = TMW.ClassSpellCache[class]
			end
			SUG:SendCommMessage("TMWSUG", SUG:Serialize("CSC", SUG.commThrowaway), "WHISPER", who)
		elseif arg1 == "CSC" then
			for class, tbl in pairs(arg2) do
				for id, val in pairs(tbl) do
					TMW.ClassSpellCache[class][id] = val
				end
			end
			SUG:BuildClassSpellLookup()
		end
	elseif TMW.debug then
		TMW:Error(arg1)
	end
end


---------- Suggesting ----------
function SUG:DoSuggest()
	wipe(SUGpreTable)
	
	local tbl = SUG.CurrentModule:Table_Get()
	
	
	SUG.CurrentModule:Table_GetNormalSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	SUG.CurrentModule:Table_GetEquivSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	SUG.CurrentModule:Table_GetSpecialSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	
	SUG:SuggestingComplete(1)
end

function SUG:SuggestingComplete(doSort)
	SUG.offset = min(SUG.offset, max(0, #SUGpreTable-#SUG+1))
	local offset = SUG.offset
	
	if doSort then
		sort(SUGpreTable, SUG.CurrentModule:Table_GetSorter())
	end

	local i = 1
	local InvalidEntries = rawget(SUG.CurrentModule, "InvalidEntries")
	if not InvalidEntries then
		SUG.CurrentModule.InvalidEntries = {}
		InvalidEntries = SUG.CurrentModule.InvalidEntries
	end
	
	while SUG[i] do
		local key = i + SUG.offset
		local id = SUGpreTable[key]
		while id do
			if InvalidEntries[id] == nil then
				InvalidEntries[id] = not SUG.CurrentModule:Entry_IsValid(id)
			end
			if InvalidEntries[id] then
				tremove(SUGpreTable, key)
				id = SUGpreTable[key]
				SUG.offset = min(SUG.offset, max(0, #SUGpreTable-#SUG+1))
			else
				break
			end
		end
		
		local f = SUG[i]
		
		f.insert = nil
		f.insert2 = nil
		f.tooltipmethod = nil
		f.tooltiparg = nil
		f.tooltiptitle = nil
		f.tooltiptext = nil
		f.tooltiptext = nil
		f.overrideInsertID = nil
		f.overrideInsertName = nil
		f.Background:SetVertexColor(0, 0, 0, 0)
		
		if SUG.CurrentModule.noTexture then
			f.Icon:SetWidth(0.00001)
		else
			f.Icon:SetWidth(f.Icon:GetHeight())
		end
		
		if id then
			local addFunc = 1
			while true do
				local Entry_AddToList = SUG.CurrentModule["Entry_AddToList_" .. addFunc]
				if not Entry_AddToList then
					break
				end
				
				Entry_AddToList(SUG.CurrentModule, f, id)
				
				if f.insert then
					break
				end
				
				addFunc = addFunc + 1
			end
			
			local colorizeFunc = 1
			while true do
				local Entry_Colorize = SUG.CurrentModule["Entry_Colorize_" .. colorizeFunc]
				if not Entry_Colorize then
					break
				end
				
				Entry_Colorize(SUG.CurrentModule, f, id)
				
				colorizeFunc = colorizeFunc + 1
			end
			
			f:Show()
		else
			f:Hide()
		end
		i=i+1
	end
	
	if SUG.mousedOver then
		SUG.mousedOver:GetScript("OnEnter")(SUG.mousedOver)
	end
end

function SUG:NameOnCursor(isClick)
	if SUG.IsCaching then
		SUG.onCompleteCache = true
		SUG.Suggest:Show()
		return
	end
	SUG.oldLastName = SUG.lastName
	local text = SUG.Box:GetText()

	SUG.startpos = 0
	for i = SUG.Box:GetCursorPosition(), 0, -1 do
		if strsub(text, i, i) == ";" then
			SUG.startpos = i+1
			break
		end
	end
	
	if isClick then
		SUG.endpos = #text
		for i = SUG.startpos, #text do
			if strsub(text, i, i) == ";" then
				SUG.endpos = i-1
				break
			end
		end
	else
		SUG.endpos = SUG.Box:GetCursorPosition()
	end
	

	SUG.lastName = strlower(TMW:CleanString(strsub(text, SUG.startpos, SUG.endpos)))
	
	if strfind(SUG.lastName, ":[%d:%s%.]*$") then
		SUG.lastName, SUG.duration = strmatch(SUG.lastName, "(.-):([%d:%s%.]*)$")
		SUG.duration = strtrim(SUG.duration, " :;.")
		if SUG.duration == "" then
			SUG.duration = nil
		end
	else
		SUG.duration = nil
	end

	if not TMW.debug then
		-- do not escape the almighty wildcards if testing
		SUG.lastName = gsub(SUG.lastName, "([%*%.])", "%%%1")
	end
	-- always escape parentheses, brackets, percent signs, minus signs, plus signs
	SUG.lastName = gsub(SUG.lastName, "([%(%)%%%[%]%-%+])", "%%%1")

	SUG.atBeginning = "^"..SUG.lastName

	
	if not SUG.CurrentModule.noMin and (SUG.lastName == "" or not strfind(SUG.lastName, "[^%.]")) then
		SUG.Suggest:Hide()
		return
	else
		SUG.Suggest:Show()
	end
	
	if SUG.updatePlayerSpells then
		wipe(SUGPlayerSpells)
		for k, v in pairs(pclassSpellCache) do
			SUGPlayerSpells[k] = 1
		end
		for k, v in pairs(TMW.ClassSpellCache.PET) do
			if v == pclass then
				SUGPlayerSpells[k] = 1
			end
		end
		local _, race = UnitRace("player")
		for k, v in pairs(TMW.ClassSpellCache.RACIAL) do
			if v == race then
				SUGPlayerSpells[k] = 1
			end
		end
		SUG.updatePlayerSpells = nil
	end

	SUG.inputType = type(tonumber(SUG.lastName) or SUG.lastName)
	SUGIsNumberInput = SUG.inputType == "number"

	if SUG.oldLastName ~= SUG.lastName or SUG.redoIfSame then
		SUG.redoIfSame = nil

		SUG.offset = 0
		SUG:DoSuggest()
	end

end


---------- Item/Action Caching ----------
function SUG:CacheItems()
	if not SUG.doUpdateItemCache then return end
	
	wipe(CurrentItems)
	
	for container = -2, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(container) do
			local id = GetContainerItemID(container, slot)
			if id then
				local name = GetItemInfo(id)
				name = name and strlower(name)
				
				CurrentItems[id] = name
				ItemCache[id] = name
			end
		end
	end
	
	for slot = 1, 19 do
		local id = GetInventoryItemID("player", slot)
		if id then
			local name = GetItemInfo(id)
			name = name and strlower(name)
			
			CurrentItems[id] = name
			ItemCache[id] = name
		end
	end
	
	for id, name in pairs(CurrentItems) do
		CurrentItems[name] = id
	end
	
	SUG.doUpdateItemCache = nil
end

function SUG:BuildClassSpellLookup()
	SUG.ClassSpellLength = SUG.ClassSpellLength or {}
	SUG.ClassSpellLookup = SUG.ClassSpellLookup or {}
	for class, tbl in pairs(TMW.ClassSpellCache) do
		SUG.ClassSpellLength[class] = 0
		for id in pairs(tbl) do
			SUG.ClassSpellLookup[id] = 1
			SUG.ClassSpellLength[class] = SUG.ClassSpellLength[class] + 1
		end
	end
end


---------- Editbox Hooking ----------
local EditboxHooks = {
	OnEditFocusLost = function(self)
		if self.SUG_Enabled then
			SUG.Suggest:Hide()
		end
	end,
	OnEditFocusGained = function(self)
		if self.SUG_Enabled then
			local newModule = SUG:GetModule(self.SUG_type)
			SUG.redoIfSame = SUG.CurrentModule ~= newModule
			SUG.Box = self
			SUG.CurrentModule = newModule
			SUG:NameOnCursor()
		end
	end,
	OnTextChanged = function(self, userInput)
		if userInput and self.SUG_Enabled then
			SUG.redoIfSame = nil
			SUG:NameOnCursor()
		end
	end,
	OnMouseUp = function(self)
		if self.SUG_Enabled then
			SUG:NameOnCursor(1)
		end
	end,
}
function SUG:EnableEditBox(editbox, inputType, onlyOneEntry)
	editbox.SUG_Enabled = 1
	
	inputType = get(inputType)
	inputType = (inputType == true and "spell") or inputType
	if not inputType then
		return SUG:DisableEditBox(editbox)
	end
	editbox.SUG_type = inputType
	editbox.SUG_onlyOneEntry = onlyOneEntry
	
	if not editbox.SUG_hooked then
		for k, v in pairs(EditboxHooks) do
			editbox:HookScript(k, v)
		end
		editbox.SUG_hooked = 1
	end

	if editbox:HasFocus() then
		EditboxHooks.OnEditFocusGained(editbox) -- force this to rerun becase we may be calling from within the editbox's script
	end
end

function SUG:DisableEditBox(editbox)
	editbox.SUG_Enabled = nil
end


---------- Miscellaneous ----------
function SUG:ColorHelp(frame)
	GameTooltip_SetDefaultAnchor(GameTooltip, frame)
	GameTooltip:AddLine(L["SUG_TOOLTIPTITLE"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:AddLine(L["SUG_DISPELTYPES"], 1, .49, .04, 1)
	GameTooltip:AddLine(L["SUG_BUFFEQUIVS"], .2, .9, .2, 1)
	GameTooltip:AddLine(L["SUG_DEBUFFEQUIVS"], .77, .12, .23, 1)
	GameTooltip:AddLine(L["SUG_OTHEREQUIVS"], 1, .96, .41, 1)
	GameTooltip:AddLine(L["SUG_MSCDONBARS"], 0, .44, .87, 1)
	GameTooltip:AddLine(L["SUG_PLAYERSPELLS"], .41, .8, .94, 1)
	GameTooltip:AddLine(L["SUG_CLASSSPELLS"], .96, .55, .73, 1)
	GameTooltip:AddLine(L["SUG_PLAYERAURAS"], .79, .30, 1, 1)
	GameTooltip:AddLine(L["SUG_NPCAURAS"], .78, .61, .43, 1)
	GameTooltip:AddLine(L["SUG_MISC"], .58, .51, .79, 1)
	GameTooltip:Show()
end


local Module = SUG:NewModule("default")

function Module:Table_Get()
	return SpellCache
end

function Module.Sorter_ByName(a, b)
	local nameA, nameB = SUG.SortTable[a], SUG.SortTable[b]
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end

function Module:Table_GetSorter()
	if SUG.inputType == "number" then
		return nil -- use the default sort func
	else
		SUG.SortTable = self:Table_Get()
		return self.Sorter_ByName
	end
end

function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName
	local semiLN = ";" .. lastName
	local long = #lastName > 2
	
	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for id in pairs(tbl) do
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	else
		for id, name in pairs(tbl) do
			if strfind(name, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
end

function Module:Table_GetEquivSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName
	local semiLN = ";" .. lastName
	local long = #lastName > 2
	
	for _, tbl in TMW:Vararg(...) do
		for equiv in pairs(tbl) do
			if 	(long and (
					(strfind(strlowerCache[equiv], lastName)) or
					(strfind(strlowerCache[L[equiv]], lastName)) or
					(not SUGIsNumberInput and strfind(strlowerCache[EquivFullNameLookup[equiv]], semiLN)) or
					(SUGIsNumberInput and strfind(EquivFullIDLookup[equiv], semiLN))
			)) or
				(not long and (
					(strfind(strlowerCache[equiv], atBeginning)) or
					(strfind(strlowerCache[L[equiv]], atBeginning))
			)) then
				suggestions[#suggestions + 1] = equiv
			end
		end
	end
end

function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)

end

function Module:Entry_OnClick(frame, button)
	local insert
	if button == "RightButton" and frame.insert2 then
		insert = frame.insert2
	else
		insert = frame.insert
	end
	self:Entry_Insert(insert)
end

function Module:Entry_Insert(insert)
	if insert then
		insert = tostring(insert)
		if SUG.Box.SUG_onlyOneEntry then
			SUG.Box:SetText(TMW:CleanString(insert))
			SUG.Box:ClearFocus()
			return 
		end
		
		-- determine the text before an after where we will be inserting to
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
		local lasthalf = strsub(currenttext, SUG.endpos+1)
		
		-- the entire text with the insertion added in
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf
		-- clean it up
		SUG.Box:SetText(TMW:CleanString(newtext))
		
		-- put the cursor after the newly inserted text
		local _, newPos = SUG.Box:GetText():find(insert:gsub("([%(%)%%%[%]%-%+%.%*])", "%%%1"), max(0, SUG.startpos-1))
		if newPos then
			SUG.Box:SetCursorPosition(newPos + 2)
		end
		
		-- if we are at the end of the exitbox then put a semicolon in anyway for convenience
		if SUG.Box:GetCursorPosition() == #SUG.Box:GetText() then 
			SUG.Box:SetText(SUG.Box:GetText() .. "; ")
		end
		
		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end

function Module:Entry_IsValid(id)
	return true
end


local Module = SUG:NewModule("item", SUG:GetModule("default"))

function Module:Table_Get()
	SUG:CacheItems()
	
	return ItemCache
end

function Module:Entry_AddToList_1(f, id)
	if id > INVSLOT_LAST_EQUIPPED then
		local name, link = GetItemInfo(id)
		
		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText(id)

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(id))
	end
end


local Module = SUG:NewModule("itemwithslots", SUG:GetModule("item"))
Module.Slots = {}

function Module:Entry_AddToList_2(f, id)
	if id <= INVSLOT_LAST_EQUIPPED then
		local itemID = GetInventoryItemID("player", id) -- get the itemID of the slot
		local link = GetInventoryItemLink("player", id)
		
		f.overrideInsertID = L["SUG_INSERTITEMSLOT"]
		
		local name = GetItemInfo(itemID)
	
		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText("(" .. id .. ")")

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(itemID))
	end
end

function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local itemID = GetInventoryItemID("player", i) -- get the itemID of the slot
		self.Slots[i] = itemID and GetItemInfo(itemID)
	end
	
	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for id in pairs(self.Slots) do
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	else
		for id, name in pairs(self.Slots) do
			if strfind(strlower(name), atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
end

function Module:Entry_Colorize_1(f, id)
	if id <= INVSLOT_LAST_EQUIPPED then
		f.Background:SetVertexColor(.58, .51, .79, 1) -- color item slots warlock purple
	end
end

function Module.Sorter_ByName(a, b)
	local haveA, haveB = Module.Slots[a], Module.Slots[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end
	
	local nameA, nameB = ItemCache[a], ItemCache[b]
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end



local Module = SUG:NewModule("spell", SUG:GetModule("default"))

function Module:Table_Get()
	return SpellCache
end

function Module.Sorter_Spells(a, b)
	local haveA, haveB = EquivFirstIDLookup[a], EquivFirstIDLookup[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	--player's spells (pclass)
	local haveA, haveB = SUGPlayerSpells[a], SUGPlayerSpells[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	--all player spells (any class)
	local haveA, haveB = ClassSpellLookup[a], ClassSpellLookup[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	elseif not (haveA or haveB) then

		local haveA, haveB = AuraCache[a], AuraCache[b] -- Auras
		if haveA and haveB and haveA ~= haveB then -- if both are auras (kind doesnt matter) AND if they are different aura types, then compare the types
			return haveA > haveB -- greater than is intended.. player auras are 2 while npc auras are 1, player auras should go first
		elseif (haveA and not haveB) or (haveB and not haveA) then --otherwise, if only one of them is an aura, then prioritize the one that is an aura
			return haveA
		end
		--if they both were auras, and they were auras of the same type (player, NPC) then procede on to the rest of the code to sort them by name/id
	end
	
	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = SpellCache[a], SpellCache[b]
			
		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end

function Module:Table_GetSorter()
	return self.Sorter_Spells
end

function Module:Entry_AddToList_1(f, id)
	if tonumber(id) then --sanity check
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.Icon:SetTexture(SpellTextures[id])
	end
end

function Module:Entry_Colorize_1(f, id)
	if SUGPlayerSpells[id] then
		f.Background:SetVertexColor(.41, .8, .94, 1) --color all other spells that you have in your/your pet's spellbook mage blue
		return
	else
		for class, tbl in pairs(TMW.ClassSpellCache) do
			if tbl[id] then
				f.Background:SetVertexColor(.96, .55, .73, 1) --color all other known class spells paladin pink
				return
			end
		end
	end
	
	local whoCasted = SUG.AuraCache[id]
	if whoCasted == 1 then
		f.Background:SetVertexColor(.78, .61, .43, 1) -- color known NPC auras warrior brown
	elseif whoCasted == 2 then
		f.Background:SetVertexColor(.79, .30, 1, 1) -- color known PLAYER auras a bright pink ish pruple ish color that is similar to paladin pink but has sufficient contrast for distinguishing
	end
end


local Module = SUG:NewModule("cooldown", SUG:GetModule("spell"))

function Module:Table_Get()
	return SpellCache, TMW.BE.gcd
end

function Module:Entry_AddToList_2(f, id)
	if TMW.BE.gcd[id] then
		local equiv = id
		id = EquivFirstIDLookup[id]
		
		local name = GetSpellInfo(id)

		f.Name:SetText(L["GCD"])
		f.ID:SetText(nil)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = equiv

		f.Icon:SetTexture(SpellTextures[id])
	end
end

function Module:Entry_Colorize_2(f, id)
	if TMW.BE.gcd[id] then
		f.Background:SetVertexColor(.58, .51, .79, 1) -- color item slots warlock purple
	end
end



local Module = SUG:NewModule("texture", SUG:GetModule("spell"))

function Module:Entry_AddToList_1(f, id)
	if tonumber(id) then --sanity check
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id
 
		if pclassSpellCache[id] --[[name and GetSpellTexture(name)]] then
			f.insert = SUG.inputType == "number" and id or name
			f.insert2 = SUG.inputType ~= "number" and id or name
		else
			f.insert = id
		end

		f.Icon:SetTexture(SpellTextures[id])
	end
end


local Module = SUG:NewModule("spellwithduration", SUG:GetModule("spell"))
Module.doAddColon = true
local MATCH_RECAST_TIME_MIN = SPELL_RECAST_TIME_MIN:gsub("%%%.3g", "(%%d+)")
local MATCH_RECAST_TIME_SEC = SPELL_RECAST_TIME_SEC:gsub("%%%.3g", "(%%d+)")

function Module:Entry_OnClick(f, button)
	local insert
	
	local spellID = f.tooltiparg
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3 = SUG:GetParser()
	Parser:SetOwner(UIParent, "ANCHOR_NONE")
	Parser:SetSpellByID(spellID)
	
	local dur
	
	for _, text in TMW:Vararg(RT2:GetText(), RT3:GetText()) do
		if text then
			
			local mins = text:match(MATCH_RECAST_TIME_MIN)
			local secs = text:match(MATCH_RECAST_TIME_SEC)
			if mins then
				dur = mins .. ":00"
			elseif secs then
				dur = secs
			end
			
			if dur then
				break
			end
		end
	end
	if spellID == 42292 then -- pvp trinket override
		dur = "2:00"
	end
	
	if button == "RightButton" and f.insert2 then
		insert = f.insert2
	else
		insert = f.insert
	end
	
	self:Entry_Insert(insert, dur)
end

function Module:Entry_Insert(insert, duration)
	if insert then
		insert = tostring(insert)
		if SUG.Box.SUG_onlyOneEntry then
			SUG.Box:SetText(TMW:CleanString(insert))
			SUG.Box:ClearFocus()
			return 
		end
		
		-- determine the text before an after where we will be inserting to
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
		local lasthalf = strsub(currenttext, SUG.endpos+1)
		
		-- determine if we should add a colon to the inserted text. a colon should be added if:
			-- one existed before (the user clicked on a spell with a duration defined or already typed it in)
			-- the module requests (requires) one
		local doAddColon = SUG.duration or SUG.CurrentModule.doAddColon
		
		-- determine if there is an actual duration to be added to the inserted spell
		local hasDurationData = duration or SUG.duration
		
		-- the entire text to be inserted in
		local insert = (doAddColon and insert .. ": " .. (hasDurationData or "")) or insert
		
		-- the entire text with the insertion added in
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf
		
		
		SUG.Box:SetText(TMW:CleanString(newtext))
		
		-- put the cursor after the newly inserted text
		local _, newPos = SUG.Box:GetText():find(insert:gsub("([%(%)%%%[%]%-%+%.%*])", "%%%1"), max(0, SUG.startpos-1))
		newPos = newPos or #SUG.Box:GetText()
		SUG.Box:SetCursorPosition(newPos + 2)
		
		-- if we are at the end of the exitbox then put a semicolon in anyway for convenience
		if SUG.Box:GetCursorPosition() == #SUG.Box:GetText() then 
			SUG.Box:SetText(SUG.Box:GetText() .. (doAddColon and not hasDurationData and " " or "") .. "; ")
		end
		
		-- if we added a colon but there was no duration information inserted, move the cursor back 2 characters so the user can type it in quickly
		if doAddColon and not hasDurationData then
			SUG.Box:SetCursorPosition(SUG.Box:GetCursorPosition() - 2)
		end
		
		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end


--[[local Module = SUG:NewModule("cooldownwithduration", SUG:GetModule("spellwithduration"))

i dont like filtering things out like this.
There are reasons for someone to track a spell in a UCD icon that does not have a cooldown in the tooltip.
Plus, exceptions are needed for pvp trinkets and such

function Module:Entry_IsValid(id)
	if id == 42292 then -- pvp trinket override
		return true
	end
	
	
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3 = SUG:GetParser()
	Parser:SetOwner(UIParent, "ANCHOR_NONE")
	Parser:SetSpellByID(id)
	
	for _, text in TMW:Vararg(RT2:GetText(), RT3:GetText()) do
		if text and (text:match(MATCH_RECAST_TIME_MIN) or text:match(MATCH_RECAST_TIME_SEC)) then
			return true
		end
	end
end]]



local Module = SUG:NewModule("cast", SUG:GetModule("spell"))

function Module:Table_Get()
	return SpellCache, TMW.BE.casts
end

function Module:Entry_AddToList_2(f, id)
	if TMW.BE.casts[id] then
		-- the entry is an equivalacy
		-- id is the equivalency name (e.g. Tier11Interrupts)
		local firstid = EquivFirstIDLookup[id]

		f.Name:SetText(id)
		f.ID:SetText(nil)

		f.insert = id

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = id

		f.Icon:SetTexture(SpellTextures[firstid])
	end
end

function Module:Entry_Colorize_2(f, id)
	if TMW.BE.casts[id] then
		f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
	end
end

function Module:Entry_IsValid(id)
	if TMW.BE.casts[id] then
		return true
	end
	
	local _, _, _, _, _, _, castTime = GetSpellInfo(id)
	if not castTime then
		return false
	elseif castTime > 0 then
		return true
	end
	
	local Parser, LT1, LT2, LT3 = SUG:GetParser()
	
	Parser:SetOwner(UIParent, "ANCHOR_NONE") -- must set the owner before text can be obtained.
	Parser:SetSpellByID(id)
	
	if LT2:GetText() == SPELL_CAST_CHANNELED or LT3:GetText() == SPELL_CAST_CHANNELED then
		return true
	end
end



local Module = SUG:NewModule("multistate", SUG:GetModule("spell"))
Module.ActionCache = {}

function Module:Table_Get()
	wipe(self.ActionCache)
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID then
			self.ActionCache[spellID] = i
		end
	end
	
	return SpellCache
end

function Module:Entry_Colorize_2(f, id)
	if self.ActionCache[id] then
		f.Background:SetVertexColor(0, .44, .87, 1) --color actions that are on your action bars shaman blue
	end
end

function Module.Sorter_Spells(a, b)
	--MSCDs
	local haveA, haveB = Module.ActionCache[a], Module.ActionCache[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end
	
	--player's spells (pclass)
	local haveA, haveB = SUGPlayerSpells[a], SUGPlayerSpells[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	--all player spells (any class)
	local haveA, haveB = ClassSpellLookup[a], ClassSpellLookup[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	elseif not (haveA or haveB) then

		local haveA, haveB = AuraCache[a], AuraCache[b] -- Auras
		if haveA and haveB and haveA ~= haveB then -- if both are auras (kind doesnt matter) AND if they are different aura types, then compare the types
			return haveA > haveB -- greater than is intended.. player auras are 2 while npc auras are 1, player auras should go first
		elseif (haveA and not haveB) or (haveB and not haveA) then --otherwise, if only one of them is an aura, then prioritize the one that is an aura
			return haveA
		end
		--if they both were auras, and they were auras of the same type (player, NPC) then procede on to the rest of the code to sort them by name/id
	end
	
	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = SpellCache[a], SpellCache[b]
			
		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end

function Module:Table_GetSorter()
	return self.Sorter_Spells
end


local Module = SUG:NewModule("buff", SUG:GetModule("spell"))

function Module:Table_Get()
	return SpellCache, TMW.BE.buffs, TMW.BE.debuffs
end

function Module:Entry_Colorize_2(f, id)
	if TMW.DS[id] then
		f.Background:SetVertexColor(1, .49, .04, 1) -- druid orange
	elseif TMW.BE.buffs[id] then
		f.Background:SetVertexColor(.2, .9, .2, 1) -- lightish green
	elseif TMW.BE.debuffs[id] then
		f.Background:SetVertexColor(.77, .12, .23, 1) -- deathknight red
	end
end

function Module:Entry_AddToList_2(f, id)
	if TMW.DS[id] then -- if the entry is a dispel type (magic, poison, etc)
		local dispeltype = id

		f.Name:SetText(dispeltype)
		f.ID:SetText(nil)

		f.insert = dispeltype

		f.tooltiptitle = dispeltype
		f.tooltiptext = L["ICONMENU_DISPEL"]

		f.Icon:SetTexture(TMW.DS[id])

	elseif EquivFirstIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
		--NOTE: dispel types are put in EquivFirstIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
		local equiv = id
		local firstid = EquivFirstIDLookup[id]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[firstid])
	end
end

function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for dispeltype in pairs(TMW.DS) do
		if strfind(strlowerCache[dispeltype], atBeginning) or strfind(strlowerCache[L[dispeltype]], atBeginning)  then
			suggestions[#suggestions + 1] = dispeltype
		end
	end
end


local Module = SUG:NewModule("dr", SUG:GetModule("spell"))

function Module:Table_Get()
	return SpellCache, TMW.BE.dr
end

function Module:Entry_Colorize_2(f, id)
	if TMW.BE.dr[id] then
		f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
	end
end

function Module:Entry_AddToList_2(f, id)
	if EquivFirstIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
		--NOTE: dispel types are put in EquivFirstIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
		local equiv = id
		local firstid = EquivFirstIDLookup[id]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[firstid])
	end
end



local Module = SUG:NewModule("wpnenchant", SUG:GetModule("default"), "AceEvent-3.0")
Module.noMin = true

Module.ItemIDs = {
	-- item enhancements
	43233,	--Deadly Poison
	3775,	--Crippling Poison
	5237,	--Mind-Numbing Poison
	43235,	--Wound Poison
	43231,	--Instant Poison
	
	31535,	--Bloodboil Poison
	
	3829,	--Frost Oil
	3824,	--Shadow Oil -- good
	
	36899,	--Exceptional Mana Oil
	22521,	--Superior Mana Oil -- good
	20748,	--Brilliant Mana Oil -- good
	20747,	--Lesser Mana Oil -- good
	20745,	--Minor Mana Oil -- good
	
	22522,	--Superior Wizard Oil -- good
	20749,	--Brilliant Wizard Oil -- good
	20750,	--Wizard Oil -- good
	20746,	--Lesser Wizard Oil -- good
	20744,	--Minor Wizard Oil -- good
	
	
	34539,	--Righteous Weapon Coating
	34538,	--Blessed Weapon Coating
	
	--23123,	--Blessed Wizard Oil
	
	--23576,	--Greater Ward of Shielding
	--23575,	--Lesser Ward of Shielding
	
	--25521,	--Greater Rune of Warding
	--23559,	--Lesser Rune of Warding
	
	--7307,	--Flesh Eating Worm
	
	--46006,	--Glow Worm
	--6529,	--Shiny Bauble
	--6532,	--Bright Baubles
	--67404,	--Glass Fishing Bobber
	--69907,	--Corpse Worm
	--62673,	--Feathered Lure
	--34861,	--Sharpened Fish Hook
	--6533,	--Aquadynamic Fish Attractor
	--6530,	--Nightcrawlers
	--68049,	--Heat-Treated Spinning Lure
	--6811,	--Aquadynamic Fish Lens
	
	--12643,	--Dense Weightstone
	--3241,	--Heavy Weightstone
	--7965,	--Solid Weightstone
	--3240,	--Coarse Weightstone
	--28420,	--Fel Weightstone
	--28421,	--Adamantite Weightstone
	--3239,	--Rough Weightstone
	
	--23529,	--Adamantite Sharpening Stone
	--7964,	--Solid Sharpening Stone
	--23122,	--Consecrated Sharpening Stone
	--2871,	--Heavy Sharpening Stone
	--23528,	--Fel Sharpening Stone
	--2862,	--Rough Sharpening Stone
	--2863,	--Coarse Sharpening Stone
	--12404,	--Dense Sharpening Stone
	--18262,	--Elemental Sharpening Stone
	
	-- ZHTW:
	-- weightstone: 平衡石
	-- sharpening stone: 磨刀石
	--25679,	--Comfortable Insoles
}

Module.SpellIDs = {
	-- Shaman Enchants
	8024,	--Flametongue Weapon
	8033,	--Frostbrand Weapon
	8232,	--Windfury Weapon
	51730,	--Earthliving Weapon
	8017,	--Rockbiter Weapon
}

function Module:OnInitialize()
	self.Items = {}
	self.Spells = {}
	self.Table = {}
	self.SpellLookup = {}
	
	
	self:Etc_DoItemLookups()		
	
	for k, id in pairs(self.SpellIDs) do
		local name = GetSpellInfo(id)
		for _, enchant in TMW:Vararg(strsplit("|", L["SUG_MATCH_WPNENCH_ENCH"])) do
			local dobreak
			enchant = name:match(enchant)
			if enchant then
				for ench in pairs(TMW.db.global.WpnEnchDurs) do
					if strfind(strlower(ench), strlower(enchant:gsub("([%%%[%]%-%+])", "%%%1"))) then
						-- the enchant was found in the list of known enchants, so add it
						self.Spells[ench] = id
						dobreak = 1
						break
					end
				end
				if dobreak then
					break
				elseif GetLocale() ~= "ruRU" or (GetLocale() == "koKR" and id ~= 51730) then
					-- the enchant was not found in the list of known enchants, so take a guess and add it (but not for ruRU because it is just screwed up
					-- koKR is screwed up for earthliving, so dont try it either
					self.Spells[enchant] = id
				end
			end
		end
	end
	
	for k, v in pairs(self.Spells) do
		if self.Table[k] then
			TMW:Error("Attempted to add spellID %d, but an item already has that id.", nil, k)
		else
			self.Table[k] = v
		end
	end
	
	for k, v in pairs(TMW.db.global.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end
	
	for name in pairs(self.Table) do
		self:Etc_GetTexture(name) -- cache textures for the spell breakdown tooltip
	end
end

function Module:Etc_DoItemLookups()
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
	
	for k, id in pairs(self.ItemIDs) do
		local name = GetItemInfo(id)
		if name then
			self.Items[name] = id
		else
			self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "Etc_DoItemLookups")
		end
	end
	
	for k, v in pairs(self.Items) do
		self.Table[k] = v
	end
end

function Module:Table_Get()
	SUG:CacheItems()
	
	for k, v in pairs(TMW.db.global.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end
	
	return self.Table
end

function Module:Entry_AddToList(f, name)
	if self.Spells[name] then
		local id = self.Spells[name]
		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = name
	elseif self.Items[name] then
		local id = CurrentItems[strlowerCache[name]] or self.Items[name]
		local name, link = GetItemInfo(id)

		f.Name:SetText(link:gsub("[%[%]]", ""))
		f.ID:SetText(nil)

		f.insert = name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link
	else
		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltiptitle = name

		f.insert = name
	end
	
	f.Icon:SetTexture(self:Etc_GetTexture(name))
end

function Module:Etc_GetTexture(name)
	local tex
	if self.Spells[name] then
		tex = SpellTextures[self.Spells[name]]
	elseif self.Items[name] then
		tex = GetItemIcon(self.Items[name])
	else
		if name:match(L["SUG_PATTERNMATCH_FISHINGLURE"]) then
			tex = "Interface\\Icons\\inv_fishingpole_02"
		elseif name:match(L["SUG_PATTERNMATCH_WEIGHTSTONE"]) then
			tex = "Interface\\Icons\\inv_stone_weightstone_02"
		elseif name:match(L["SUG_PATTERNMATCH_SHARPENINGSTONE"]) then
			tex = "Interface\\Icons\\inv_stone_sharpeningstone_01"
		end
	end
	
	name = strlower(name)
	SpellTextures[name] = SpellTextures[name] or tex
	
	return tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function Module.Sorter(a, b)
	local haveA = Module.Spells[a] and SUGPlayerSpells[Module.Spells[a]]
	local haveB = Module.Spells[b] and SUGPlayerSpells[Module.Spells[b]]
	
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end
	
	local haveA = Module.Items[a] and (CurrentItems[ strlowerCache[ a ]] )
	local haveB = Module.Items[b] and (CurrentItems[ strlowerCache[ b ]] )
	
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end
	
	-- its a very small table to sort, so i can get away with this
	local haveA = rawget(TMW.db.global.WpnEnchDurs, a)
	local haveB = rawget(TMW.db.global.WpnEnchDurs, b)
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end
	
	
	local nameA, nameB = Module.Table[a], Module.Table[b]
		
	if a == b then
		--sort identical names by ID
		return Module.Table[a] < Module.Table[b]
	else
		--sort by name
		return a < b
	end
	
end

function Module:Table_GetSorter()
	SUG.doUpdateItemCache = true
	SUG:CacheItems()
	return self.Sorter
end

function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	
	for name, id in pairs(tbl) do
		if SUG.inputType == "number" or strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = name
		end
	end
end

function Module:Entry_Colorize_1(f, name)
	if SUGPlayerSpells[Module.Spells[name]] or (CurrentItems[ strlowerCache[ name ]]) then
		f.Background:SetVertexColor(.41, .8, .94, 1) --color all spells and items that you have mage blue
	elseif rawget(TMW.db.global.WpnEnchDurs, name) then
		f.Background:SetVertexColor(.79, .30, 1, 1) -- color all known weapon enchants purple
	end
end



local Module = SUG:NewModule("tracking", SUG:GetModule("default"))
Module.noMin = true

function Module:Table_Get()
	return TrackingCache
end

function Module:Table_GetSorter()
	return nil
end

function Module:Entry_AddToList_1(f, id)
	local name, texture = GetTrackingInfo(id)

	f.Name:SetText(name)
	f.ID:SetText(nil)

	f.insert = name

	f.Icon:SetTexture(texture)
end




-- -----------------------
-- CONDITION EDITOR
-- -----------------------


---------- Interface/Data ----------
function CNDT:Load(type)
	type = type or CNDT.type or "icon"
	CNDT.type, CNDT.settings = CNDT:GetTypeData(type)
	
	local Conditions = CNDT.settings
	if not Conditions then return end
	
	HELP:Hide("CNDT_UNIT_MISSING")
	if Conditions.n > 0 then
		for i = Conditions.n + 1, #CNDT do
			CNDT[i]:Clear()
		end
		CNDT:CreateGroups(Conditions.n+1)

		for i=1, Conditions.n do
			CNDT[i]:Load()
		end
	else
		CNDT:Clear()
	end
	CNDT:AddRemoveHandler()
	
	if IE.Conditions.ScrollFrame:GetVerticalScrollRange() == 0 then
		TMW.IE.Conditions.ScrollFrame.ScrollBar:Hide()
	end
end

function CNDT:Save()
	local groupID, iconID = CI.g, CI.i
	if not groupID then return end

	local Conditions = CNDT.settings
	
	for i, group in ipairs(CNDT) do
		if group:IsShown() then
			group:Save()
		else
			Conditions[i] = nil
		end
	end

	if CNDT.type == "icon" then
		IE:ScheduleIconUpdate(CI.ic)
	elseif CNDT.type == "group" then
		TMW:Group_Update(groupID)
	end
end

function CNDT:Clear()
	for i=1, #CNDT do
		CNDT[i]:Clear()
		CNDT[i]:SetTitles()
	end
	CNDT:AddRemoveHandler()
end

function CNDT:SetTabText(type)
	local type, Conditions = CNDT:GetTypeData(type)
	
	CNDT:CheckParentheses(type)
	
	local tab = (type == "icon" and IE.IconConditionTab) or IE.GroupConditionTab
	local n = Conditions.n
	
	if n > 0 then
		tab:SetText((CNDT[type.."invalid"] and "|TInterface\\AddOns\\TellMeWhen_Options\\Textures\\Alert:0:2|t|cFFFF0000" or "") .. L[type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " |cFFFF5959(" .. n .. ")")
	else
		tab:SetText(L[type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " (" .. n .. ")")
	end
	
	PanelTemplates_TabResize(tab, -6)
end

function CNDT:GetTypeData(type)
	if type == "icon" then
		return type, db.profile.Groups[CI.g].Icons[CI.i].Conditions
	elseif type == "group" then
		return type, db.profile.Groups[CI.g].Conditions
	else
		return CNDT.type, CNDT.settings
	end
end


---------- Dropdowns ----------
local addedThings = {}
local usedCount = {}
local addedGroups = {}
local commonConditions = {
	"COMBAT",
	"VEHICLE",
	"HEALTH",
	"DEFAULT",
	"STANCE",
}

local function AddConditionToDropDown(v)
	if not v or v.hidden then return end
	local info = UIDropDownMenu_CreateInfo()
	info.func = CNDT.TypeMenu_DropDown_OnClick
	info.text = v.text
	info.tooltipTitle = v.text
	info.tooltipText = v.tooltip
	info.tooltipOnButton = true
	info.value = v.value
	info.arg1 = frame
	info.arg2 = v
	info.icon = get(v.icon)
	if v.tcoords then
		info.tCoordLeft = v.tcoords[1]
		info.tCoordRight = v.tcoords[2]
		info.tCoordTop = v.tcoords[3]
		info.tCoordBottom = v.tcoords[4]
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

function CNDT:TypeMenu_DropDown()
	
	-- populate the "frequently used" submenu
	if UIDROPDOWNMENU_MENU_LEVEL == 2 and UIDROPDOWNMENU_MENU_VALUE == "FREQ" then
		
		-- num is a count of how many we have added. We dont want to add more than maxNum things to the menu
		local num, maxNum = 0, 20
		
		-- addedThings IN THIS CASE is a list of conditions that have been added to avoid duplicates between the two sources for the list (see below)
		wipe(addedThings)
		
		-- add the conditions that should always be at the top of the list
		for _, k in ipairs(commonConditions) do
			AddConditionToDropDown(CNDT.ConditionsByType[k])
			addedThings[k] = 1
			num = num + 1
			if num > maxNum then break end
		end
		
		-- usedCount is a list of how many times a condition has been used.
		-- We want to add the ones that get used the most to the rest of the menu
		wipe(usedCount)
		for Condition in TMW:InConditionSettings() do
			usedCount[Condition.Type] = (usedCount[Condition.Type] or 0) + 1
		end
		
		-- add the most used conditions to the list
		for k, n in TMW:OrderedPairs(usedCount, "values", true) do
			if not addedThings[k] and n > 1 then
				AddConditionToDropDown(CNDT.ConditionsByType[k])
				addedThings[k] = 1
				num = num + 1
				if num > maxNum then break end
			end
		end
	end
	
	wipe(addedThings)
	local addedFreq
	for k, v in ipairs(CNDT.Types) do
		
		-- add the frequently used submenu before the first condition that does not have a category
		if not v.category and not addedFreq and UIDROPDOWNMENU_MENU_LEVEL == 1 then
			AddDropdownSpacer()
				
			local info = UIDropDownMenu_CreateInfo()
			info.text = L["CNDTCAT_FREQUENTLYUSED"]
			info.value = "FREQ"
			info.notCheckable = true
			info.hasArrow = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			addedFreq = true
		end
		
		if ((UIDROPDOWNMENU_MENU_LEVEL == 2 and v.category == UIDROPDOWNMENU_MENU_VALUE) or (UIDROPDOWNMENU_MENU_LEVEL == 1 and not v.category)) and not v.hidden then
			if v.spacebefore then
				AddDropdownSpacer()
			end
			
			-- most conditions are added to the dropdown right here
			AddConditionToDropDown(v)
			
		elseif UIDROPDOWNMENU_MENU_LEVEL == 1 and v.category and not addedThings[v.category] then
			-- addedThings IN THIS CASE is a list of categories that have been added. Add ones here that have not been added yet.
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.category
			info.value = v.category
			info.notCheckable = true
			info.hasArrow = true
			addedThings[v.category] = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

function CNDT:TypeMenu_DropDown_OnClick(frame, data)
	UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
	UIDropDownMenu_SetText(UIDROPDOWNMENU_OPEN_MENU, data.text)
	local group = UIDROPDOWNMENU_OPEN_MENU:GetParent()
	local showval = group:TypeCheck(data)
	if data.defaultUnit then
		group.Unit:SetText(data.defaultUnit)
	end
	group:SetSliderMinMax()
	if showval then
		group:SetValText()
	else
		group.ValText:SetText("")
	end
	CNDT:Save()
	CloseDropDownMenus()
end

function CNDT:UnitMenu_DropDown()
	for k, v in pairs(TMW.Units) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.UnitMenu_DropDown_OnClick
		if v.range then
			info.tooltipTitle = v.tooltipTitle or v.text
			info.tooltipText = "|cFFFF0000#|r = 1-" .. v.range
			info.tooltipOnButton = true
		end
		info.text = v.text
		info.value = v.value
		info.hasArrow = v.hasArrow
		info.notCheckable = true
		info.arg1 = self
		info.arg2 = v
		UIDropDownMenu_AddButton(info)
	end
end

function CNDT:UnitMenu_DropDown_OnClick(frame, v)
	local ins = v.value
	if v.range then
		ins = v.value .. "|cFFFF0000#|r"
	end
	frame:GetParent():SetText(ins)
	CNDT:Save()
	CloseDropDownMenus()
end

function CNDT:IconMenu_DropDown()
	sort(TMW.Icons, TMW.IconsSort)
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for k, v in ipairs(TMW.Icons) do
			local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
			g, i = tonumber(g), tonumber(i)
			if UIDROPDOWNMENU_MENU_VALUE == g and CI.ic ~= TMW[g][i] then
				local info = UIDropDownMenu_CreateInfo()
				info.func = CNDT.IconMenu_DropDown_OnClick
				local text, textshort = TMW:GetIconMenuText(g, i)
				info.text = textshort
				info.value = v
				info.tooltipTitle = text
				info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(g, g, 1), i)
				info.tooltipOnButton = true
				info.arg1 = self
				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				info.icon = TMW[g][i].texture:GetTexture()
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then
		wipe(addedGroups)
		for k, v in ipairs(TMW.Icons) do
			local g = tonumber(strmatch(v, "TellMeWhen_Group(%d+)"))
			if not addedGroups[g] then
				local info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(g, g, 1)
				info.hasArrow = true
				info.notCheckable = true
				info.value = g
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				addedGroups[g] = true
			end
		end
	end
end

function CNDT:IconMenu_DropDown_OnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	CloseDropDownMenus()
	CNDT:Save()
end

function CNDT:OperatorMenu_DropDown()
	for k, v in pairs(CNDT.Operators) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.OperatorMenu_DropDown_OnClick
		info.text = v.text
		info.value = v.value
		info.tooltipTitle = v.tooltipText
		info.tooltipOnButton = true
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
end

function CNDT:OperatorMenu_DropDown_OnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	TMW:TT(frame, self.tooltipTitle, nil, 1)
	CNDT:Save()
end


---------- Runes ----------
function CNDT:RuneHandler(rune)
	local id = rune:GetID()
	local pair
	if id > 6 then
		pair = _G[gsub(rune:GetName(), "Death", "")]
	else
		pair = _G[rune:GetName() .. "Death"]
	end
	if rune:GetChecked() ~= nil then
		pair:SetChecked(nil)
	end
end

function CNDT:Rune_GetChecked()
	return self.checked
end

function CNDT:Rune_SetChecked(checked)
	self.checked = checked
	if checked then
		self.Check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
	elseif checked == nil then
		self.Check:SetTexture(nil)
	elseif checked == false then
		self.Check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
	end
end


---------- Parentheses ----------
CNDT.colors = setmetatable(
	{ -- hardcode the first few colors to make sure they look good
		"|cff00ff00",
		"|cff0026ff",
		"|cffff004d",
		"|cff009bff",
		"|cffff00c2",
		"|cffe9ff00",
		"|cff00ff7c",
		"|cffff6700",
		"|cffaf79ff",
	},
	{ __index = function(t, k)
		-- start reusing colors
		if k < 1 then return "" end
		while k >= #t do
			k = k - #t
		end
		return rawget(t, k) or ""
end})
	
function CNDT:CheckParentheses(type)
	local type, settings = CNDT:GetTypeData(type)
	
	local numclose, numopen, runningcount = 0, 0, 0
	local unopened = 0
	
	for Condition in TMW:InConditions(settings) do
		for i = 1, Condition.PrtsBefore do
			numopen = numopen + 1
			runningcount = runningcount + 1
			if runningcount < 0 then unopened = unopened + 1 end
		end
		for i = 1, Condition.PrtsAfter do
			numclose = numclose + 1
			runningcount = runningcount - 1
			if runningcount < 0 then unopened = unopened + 1 end
		end
	end
	
	if numopen ~= numclose then
		local typeNeeded, num
		if numopen > numclose then
			typeNeeded, num = ")", numopen-numclose
		else
			typeNeeded, num = "(", numclose-numopen
		end
		HELP:Show("CNDT_PARENTHESES_ERROR", nil, TMW.IE.Conditions, 0, 0, L["PARENTHESIS_WARNING1"], num, L["PARENTHESIS_TYPE_" .. typeNeeded])
		
		CNDT[type.."invalid"] = 1
	elseif unopened > 0 then
	
		HELP:Show("CNDT_PARENTHESES_ERROR", nil, TMW.IE.Conditions, 0, 0, L["PARENTHESIS_WARNING2"], unopened)
		
		CNDT[type.."invalid"] = 1
	else
		HELP:Hide("CNDT_PARENTHESES_ERROR")
		CNDT[type.."invalid"] = nil
	end
end	

function CNDT:ColorizeParentheses()
	if not IE.Conditions:IsShown() then return end
	
	CNDT.Parens = wipe(CNDT.Parens or {})
	
	for k, v in ipairs(CNDT) do
		if v:IsShown() then
			if v.OpenParenthesis:IsShown() then
				for k, v in ipairs(v.OpenParenthesis) do
					v.text:SetText("|cff222222" .. v.type)
					if v:GetChecked() then
						tinsert(CNDT.Parens, v)
					end
				end
			end
			
			if v.CloseParenthesis:IsShown() then
				for k = #v.CloseParenthesis, 1, -1 do
					local v = v.CloseParenthesis[k]
					v.text:SetText("|cff222222" .. v.type)
					if v:GetChecked() then
						tinsert(CNDT.Parens, v)
					end
				end
			end
		end
	end
	
	while true do
		local numopen, nestinglevel, open, currentcolor = 0, 0
		for i, v in ipairs(CNDT.Parens) do
			if v == true then
				nestinglevel = nestinglevel + 1
			elseif v == false then
				nestinglevel = nestinglevel - 1
			elseif v.type == "(" then
				numopen = numopen + 1
				nestinglevel = nestinglevel + 1
				if not open then
					open = i
					CNDT.Parens[open].text:SetText(CNDT.colors[nestinglevel] .. "(")
					currentcolor = nestinglevel
				end
			else
				numopen = numopen - 1
				nestinglevel = nestinglevel - 1
				if open and numopen == 0 then
					CNDT.Parens[i].text:SetText(CNDT.colors[currentcolor] .. ")")
					CNDT.Parens[i] = false
					break
				end
			end		
		end
		if open then
			CNDT.Parens[open] = true
		else
			break
		end
	end
	for i, v in ipairs(CNDT.Parens) do
		if type(v) == "table" then
			v.text:SetText(v.type)
		end
	end
	
	CNDT:SetTabText()
end	


---------- Condition Groups ----------
function CNDT:AddRemoveHandler()
	local i=1
	CNDT[1].Up:Hide()
	while CNDT[i] do
		CNDT[i].CloseParenthesis:Show()
		CNDT[i].OpenParenthesis:Show()
		CNDT[i].Down:Show()
		if CNDT[i+1] then
			if CNDT[i]:IsShown() then
				CNDT[i+1].AddDelete:Show()
			else
				CNDT[i]:Hide()
				CNDT[i+1].AddDelete:Hide()
				CNDT[i+1]:Hide()
				if i > 1 then
					CNDT[i-1].Down:Hide()
				end
			end
		else -- this handles the last one in the frame
			if CNDT[i]:IsShown() then
				CNDT:CreateGroups(i+1)
			else
				if i > 1 then
					CNDT[i-1].Down:Hide()
				end
			end
		end
		i=i+1
	end

	local n = 1
	while CNDT[n] and CNDT[n]:IsShown() do
		n = n + 1
	end
	n = n - 1

	if n < 3 then
		for i = 1, n do
			CNDT[i].CloseParenthesis:Hide()
			CNDT[i].OpenParenthesis:Hide()
		end
	end
	
	CNDT:ColorizeParentheses()
end

function CNDT:CreateGroups(num)
	local start = #CNDT + 1
	
	for i=start, num do
		local group = CNDT[i] or CreateFrame("Frame", "TellMeWhen_IconEditorConditionsGroupsGroup" .. i, TellMeWhen_IconEditor.Conditions.Groups, "TellMeWhen_ConditionGroup", i)
		for k, v in pairs(CNDT.GroupBase) do
			group[k] = v
		end
		
		group:SetPoint("TOPLEFT", CNDT[i-1], "BOTTOMLEFT", 0, -14.5)
		local p, _, rp, x, y = TMW.CNDT[1].AddDelete:GetPoint()
		group.AddDelete:ClearAllPoints()
		group.AddDelete:SetPoint(p, CNDT[i], rp, x, y)
		group:Clear()
		group:SetTitles()
	end
end

function CNDT:AddCondition(Conditions)
	Conditions.n = Conditions.n + 1
	return Conditions[Conditions.n]
end

function CNDT:DeleteCondition(Conditions, n)
	Conditions.n = Conditions.n - 1
	return tremove(Conditions, n)
end


---------- Group Class ----------
CNDT.GroupBase = {}

function CNDT.GroupBase.TypeCheck(group, data)
	if data then
		local unit = data.unit

		group.Icon:Hide() --it bugs sometimes so just do it by default
		group.Runes:Hide()
		local showval = true
		group:SetTitles()
		group.Unit:Show()
		if unit then
			group.Unit:Hide()
			group.TextUnitDef:SetText(unit)
		elseif unit == false then -- must be == false
			group.TextUnitOrIcon:SetText(nil)
			group.Unit:Hide()
			group.TextUnitDef:SetText(nil)
		end

		if data.name then
			group.EditBox:Show()
			if type(data.name) == "function" then
				data.name(group.EditBox)
				group.EditBox:GetScript("OnTextChanged")(group.EditBox)
			else
				TMW:TT(group.EditBox)
			end
			if data.check then
				data.check(group.Check)
				group.Check:Show()
			else
				group.Check:Hide()
			end
			SUG:EnableEditBox(group.EditBox, data.useSUG, true)
			
			group.Slider:SetWidth(217)
			if data.noslide then
				group.EditBox:SetWidth(520)
			else
				group.EditBox:SetWidth(295)
			end
		else
			group.EditBox:Hide()
			group.Check:Hide()
			group.Slider:SetWidth(522)
			SUG:DisableEditBox(group.EditBox)
		end
		if data.name2 then
			group.EditBox2:Show()
			if type(data.name2) == "function" then
				data.name2(group.EditBox2)
				group.EditBox2:GetScript("OnTextChanged")(group.EditBox2)
			else
				TMW:TT(group.EditBox2)
			end
			if data.check2 then
				data.check2(group.Check2)
				group.Check2:Show()
			else
				group.Check2:Hide()
			end
			SUG:EnableEditBox(group.EditBox2, data.useSUG, true)
			group.EditBox:SetWidth(250)
			group.EditBox2:SetWidth(250)
		else
			group.Check2:Hide()
			group.EditBox2:Hide()
			SUG:DisableEditBox(group.EditBox2)
		end
		
		if data.nooperator then
			group.TextOperator:SetText("")
			group.Operator:Hide()
		else
			group.Operator:Show()
		end
		
		if data.noslide then
			showval = false
			group.Slider:Hide()
			group.TextValue:SetText("")
			group.ValText:Hide()
		else
			group.ValText:Show()
			group.Slider:Show()
		end
		
		if data.showhide then
			data.showhide(group, data)
		end
		return showval
	else
		group.Unit:Hide()
		group.Check:Hide()
		group.EditBox:Hide()
		group.Check:Hide()
		group.Operator:Hide()
		group.ValText:Hide()
		group.Slider:Hide()
		
		group.TextUnitOrIcon:SetText(nil)
		group.TextUnitDef:SetText(nil)
		group.TextOperator:SetText(nil)
		group.TextValue:SetText(nil)
	
	end
end

function CNDT.GroupBase.Save(group)
	local condition = CNDT.settings[group:GetID()]
	
	condition.Type = UIDropDownMenu_GetSelectedValue(group.Type) or ""
	condition.Unit = strtrim(group.Unit:GetText()) or "player"
	condition.Operator = UIDropDownMenu_GetSelectedValue(group.Operator) or "=="
	condition.Icon = UIDropDownMenu_GetSelectedValue(group.Icon) or ""
	condition.Level = tonumber(group.Slider:GetValue()) or 0
	condition.AndOr = group.AndOr:GetValue()
	condition.Name = strtrim(group.EditBox:GetText()) or ""
	condition.Name2 = strtrim(group.EditBox2:GetText()) or ""
	condition.Checked = not not group.Check:GetChecked()
	condition.Checked2 = not not group.Check2:GetChecked()
	
	
	for k, rune in pairs(group.Runes) do
		if type(rune) == "table" then
			condition.Runes[rune:GetID()] = rune:GetChecked()
		end
	end

	local n = 0
	if group.OpenParenthesis:IsShown() then
		for k, frame in pairs(group.OpenParenthesis) do
			if type(frame) == "table" and frame:GetChecked() then
				n = n + 1
			end
		end
	end
	condition.PrtsBefore = n

	n = 0
	if group.CloseParenthesis:IsShown() then
		for k, frame in pairs(group.CloseParenthesis) do
			if type(frame) == "table" and frame:GetChecked() then
				n = n + 1
			end
		end
	end
	condition.PrtsAfter = n
end

function CNDT.GroupBase.Load(group)
	local condition = CNDT.settings[group:GetID()]
	local data = CNDT.ConditionsByType[condition.Type]
	if group.Type.selectedValue ~= condition.Type then
		UIDropDownMenu_SetSelectedValue(group.Type, condition.Type)
	end
	UIDropDownMenu_SetText(group.Type, data and data.text or ("UNKNOWN TYPE: " .. condition.Type))
	
	group:TypeCheck(data)
	
	group.Unit:SetText(condition.Unit)
	group.EditBox:SetText(condition.Name)
	group.EditBox2:SetText(condition.Name2)
	group.Check:SetChecked(condition.Checked)
	group.Check2:SetChecked(condition.Checked2)
	
	TMW:SetUIDropdownText(group.Icon, condition.Icon, TMW.Icons)
	
	local v = TMW:SetUIDropdownText(group.Operator, condition.Operator, CNDT.Operators)
	if v then
		TMW:TT(group.Operator, v.tooltipText, nil, 1)
	end
	
	group:SetSliderMinMax(condition.Level or 0)
	group:SetValText()
	
	for k, rune in pairs(group.Runes) do
		if type(rune) == "table" then
			rune:SetChecked(condition.Runes[rune:GetID()])
		end
	end
	for k, frame in pairs(group.OpenParenthesis) do
		if type(frame) == "table" then
			group.OpenParenthesis[k]:SetChecked(condition.PrtsBefore >= k)
		end
	end
	for k, frame in pairs(group.CloseParenthesis) do
		if type(frame) == "table" then
			group.CloseParenthesis[k]:SetChecked(condition.PrtsAfter >= k)
		end
	end
	if CNDT[group:GetID() + 1] then
		group.CloseParenthesis:SetPoint("RIGHT", CNDT[group:GetID() + 1].AndOr, "LEFT", -5, 0)
	end
	
	group.AndOr:SetValue(condition.AndOr)
	group:Show()
end

function CNDT.GroupBase.Clear(group)
	group.Unit:SetText("player")
	group.EditBox:SetText("")
	group.EditBox2:SetText("")
	group.Check:SetChecked(nil)
	group.Check2:SetChecked(nil)
	if group.Icon.selectedValue ~= "" then
		UIDropDownMenu_SetSelectedValue(group.Icon, "")
	end
	TMW:SetUIDropdownText(group.Type, "", CNDT.Types)
	TMW:SetUIDropdownText(group.Operator, "==", CNDT.Operators)
	group.AndOr:SetValue("AND")
	for k, rune in pairs(group.Runes) do
		if type(rune) == "table" then
			rune:SetChecked(nil)
		end
	end
	group.Slider:SetValue(0)
	group:Hide()
	group.Unit:Show()
	group.Operator:Show()
	group.Icon:Hide()
	group.Runes:Hide()
	group.EditBox:Hide()
	group.EditBox2:Hide()
	group:SetSliderMinMax()
	group:SetValText()
end

function CNDT.GroupBase.SetValText(group)
	if TMW.Initd and group.ValText then
		local val = group.Slider:GetValue()
		local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
		if v then
			group.ValText:SetText(get(v.texttable, val) or val)
		end
	end
end

function CNDT.GroupBase.UpOrDown(group, delta)
	local ID = group:GetID()
	local settings = CNDT.settings
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	CNDT:Load()
end

function CNDT.GroupBase.AddDeleteHandler(group)
	if group:IsShown() then
		CNDT:DeleteCondition(CNDT.settings, group:GetID())
	else
		CNDT:AddCondition(CNDT.settings)
	end
	CNDT:AddRemoveHandler()
	CNDT:Load()
end

function CNDT.GroupBase.SetTitles(group)
	if not group.TextType then return end
	group.TextType:SetText(L["CONDITIONPANEL_TYPE"])
	group.TextUnitOrIcon:SetText(L["CONDITIONPANEL_UNIT"])
	group.TextUnitDef:SetText("")
	group.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
	group.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
end

function CNDT.GroupBase.SetSliderMinMax(group, level)
	-- level is passed in only when the setting is changing or being loaded
	local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
	if not v then return end
	local Slider = group.Slider
	local vmin = get(v.min)
	local vmax = get(v.max)
	if v.range then
		local deviation = v.range/2
		local val = level or Slider:GetValue()

		local newmin = max(0, val-deviation)
		local newmax = max(deviation, val + deviation)

		Slider:SetMinMaxValues(newmin, newmax)
		Slider.Low:SetText(get(v.texttable, newmin) or newmin)
		Slider.High:SetText(get(v.texttable, newmax) or newmax)
	else
		Slider:SetMinMaxValues(vmin or 0, vmax or 1)
		Slider.Low:SetText(get(v.texttable, vmin) or v.mint or vmin or 0)
		Slider.High:SetText(get(v.texttable, vmax) or v.maxt or vmax or 1)
	end
		
	local Min, Max, midt = Slider:GetMinMaxValues()
	if v.midt == true then
		midt = get(v.texttable, ((Max-Min)/2)+Min) or ((Max-Min)/2)+Min
	else
		midt = get(v.midt, ((Max-Min)/2)+Min)
	end
	Slider.Mid:SetText(midt)
		
	Slider.step = v.step or 1
	Slider:SetValueStep(Slider.step)
	if level then
		Slider:SetValue(level)
	end
end




-- -----------------------
-- HELP
-- -----------------------


HELP = TMW:NewModule("Help", "AceTimer-3.0") TMW.HELP = HELP

HELP.Codes = {
	"ICON_POCKETWATCH_FIRSTSEE",
	
	"ICON_DURS_FIRSTSEE",
	"ICON_DURS_MISSING",
	
	"ICON_IMPORT_CURRENTPROFILE",
	
	"ICON_DR_MISMATCH",
	"ICON_MS_NOTFOUND",
	"ICON_ICD_NATURESGRACE",
	
	"ICON_UNIT_MISSING",
	
	"CNDT_UNIT_MISSING",
	"CNDT_PARENTHESES_ERROR",
	
	"SND_INVALID_CUSTOM",
}

HELP.OnlyOnce = {
	ICON_DURS_FIRSTSEE = true,
	ICON_POCKETWATCH_FIRSTSEE = true,
	ICON_IMPORT_CURRENTPROFILE = true,
}

function HELP:OnInitialize()
	HELP.Frame = IE.Help
	HELP.Queued = {}
end


---------- External Usage ----------
function HELP:Show(code, icon, frame, x, y, text, ...)
	-- handle the code, determine the ID of the code.
	assert(type(code) == "string")
	local codeID
	for i, c in pairs(HELP.Codes) do
		if c == code then
			codeID = i
			break
		end
	end
	assert(codeID, format("Code %q is not defined", code))
	-- we can now safely proceded to process and queue the help
	
	-- retrieve or create the data table
	local help = wipe(HELP.Queued[code] or {})
	
	-- add the text format args to the data
	for i = 1, select('#', ...) do
		help[i] = select(i, ...)
	end
	-- add other data
	help.code = code
	help.codeID = codeID
	help.icon = icon
	help.frame = frame
	help.x = x
	help.y = y
	help.text = text
	-- if the frame has the CreateTexture method, then it can be made the parent.
	-- Otherwise, the frame is actually a texture/font/etc object, so set its parent as the parent.
	help.parent = help.frame.CreateTexture and help.frame or help.frame:GetParent()
	
	-- determine if the code has a setting associated to only show it once.
	help.setting = HELP.OnlyOnce[code] and code
	
	-- if it does and it has already been set true, then we dont need to show anything, so quit.
	if help.setting and db.global.HelpSettings[help.setting] then
		HELP.Queued[code] = nil
		help = nil
		return
	end
	
	-- if the code is the same as what is currently shown, then replace what is currently being shown.
	if HELP.showingHelp and HELP.showingHelp.code == code then
		HELP.showingHelp = nil
	end
	
	-- everything should be in order, so add the help to the queue.
	HELP:Queue(help)
	
	-- notify that this help will eventually be shown
	return 1
end

function HELP:Hide(code)
	if HELP.Queued[code] then
		HELP.Queued[code] = nil
	elseif HELP.showingHelp and HELP.showingHelp.code == code then
		HELP.showingHelp = nil
		HELP:ShowNext()
	end
end

function HELP:GetShown()
	return HELP.showingHelp and HELP.showingHelp.code
end

---------- Queue Management ----------
function HELP:Queue(help)
	-- add the help to the queue
	HELP.Queued[help.code] = help
	
	-- notify the engine to start
	HELP:ShowNext()
end

function HELP:OnClose()
	HELP.showingHelp = nil
	HELP:ShowNext()
end

function HELP:ShouldShowHelp(help)
	if help.icon and not help.icon:IsBeingEdited() then
		return false
	elseif not help.parent:IsVisible() then
		return false
	end
	return true
end

function HELP:ShowNext()
	-- if there nothing currently being displayed, hide the frame.
	if not HELP.showingHelp then
		HELP.Frame:Hide()
	end
	
	-- if we are already showing something, then don't overwrite it.
	if HELP.showingHelp then
		-- but if the current help should not be shown, then stop showing it, but stick it back in the queue to try again later
		if not HELP:ShouldShowHelp(HELP.showingHelp) then
			local current = HELP.showingHelp
			HELP.showingHelp = nil
			HELP:Queue(current)
		end
		return
	end
	
	-- if there isn't a next help to show, then dont try.
	if not next(HELP.Queued) then
		return
	end
	
	-- calculate the next help in line based on the order of HELP.Codes
	local help
	for order, code in ipairs(HELP.Codes) do
		if HELP.Queued[code] and HELP:ShouldShowHelp(HELP.Queued[code]) then
			help = HELP.Queued[code]
			break
		end
	end
	
	if not help then
		return
	end
	
	-- show the frame with the data
	local text = format(help.text, unpack(help))
	
	HELP.Frame:ClearAllPoints()
	HELP.Frame:SetPoint("TOPRIGHT", help.frame, "LEFT", (help.x or 0) - 30, (help.y or 0) + 28)
	HELP.Frame.text:SetText(text)
	HELP.Frame:SetHeight(HELP.Frame.text:GetHeight() + 38)
	HELP.Frame:SetWidth(min(250, HELP.Frame.text:GetStringWidth() + 30))
	
	local parent = help.frame.CreateTexture and help.frame or help.frame:GetParent() -- if the frame has the CreateTexture method, then it can be made the parent. Otherwise, the frame is actually a texture/font/etc object, so set 
	HELP.Frame:SetParent(parent)
	HELP.Frame:Show()
	
	
	-- if the help had a setting associated, set it now
	if help.setting then
		db.global.HelpSettings[help.setting] = true
	end
	
	-- remove the help from the queue and set it as the current help
	HELP.Queued[help.code] = nil
	HELP.showingHelp = help
end

function HELP:HideForIcon(icon)
	for code, help in pairs(HELP.Queued) do
		if help.icon == icon then
			HELP.Queued[code] = nil
		end
	end
	if HELP.showingHelp and HELP.showingHelp.icon == icon then
		HELP.showingHelp = nil
		HELP:ShowNext()
	end
end







