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

--[[todo list/notes (this really should be here, but im in a hurry)
Parsing tooltips for numbers (recaptured mana, empowered shadows) - in the icon type's onupdate, call a function to scan a unit/index/filter (unit should probably be player only)
-the parser listens to UNIT_AURA to determine if the tooltip/data needs updating - if it does, update it, if not, then return cached data
-create the tooltip as a child of the icon
]]


if not TMW then return end

local TMW = TMW
local db = TMW.db
local debug = TMW.debug

-- -----------------------
-- LOCALS/GLOBALS/UTILITIES
-- -----------------------

TELLMEWHEN_MAXCONDITIONS = 1 --this is a default
TELLMEWHEN_COLUMN1WIDTH = 170


local LSM = LibStub("LibSharedMedia-3.0")
LibStub("AceSerializer-3.0"):Embed(TMW)
local L = TMW.L
local LBF = LibStub("LibButtonFacade", true)
local LMB = LibMasque and LibMasque("Button")
local _, pclass = UnitClass("Player")
local GetSpellInfo, GetContainerItemID, GetContainerItemLink =
	  GetSpellInfo, GetContainerItemID, GetContainerItemLink
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next
local strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower =
	  strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures
local _G, GetTime = _G, GetTime
local tiptemp = {}
local Types = TMW.Types
local ME, CNDT, IE, SUG, ID, SND, ANN
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
local print = TMW.print

local function approachTable(...)
    local t = ...
    if not t then return end
    for i=2, select("#", ...) do
        t = t[select(i, ...)]
        if not t then return end
    end
    return t
end

local function get(value, ...)
	local type = type(value)
	if type == "function" then
		return value(...)
	elseif type == "table" then
		return value[...]
	else
		return value
	end
end

TMW.CI = setmetatable({}, {__index = function(tbl, k)
	if k == "ics" then
		-- take no chances with errors occuring here
		return approachTable(TMW.db, "profile", "Groups", tbl.g, "Icons", tbl.i)
	elseif k == "SoI" then -- spell or item
		local ics = tbl.ics
		if ics and ics.Type == "cooldown" and ics.CooldownType == "item" then
			return "item"
		end
		return "spell"
	elseif k == "IMS" then -- IsMultiState
		local ics = TMW.CI.ics
		return ics and ics.Type == "cooldown" and ics.CooldownType == "multistate"
	end
end}) local CI = TMW.CI		--current icon

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

function TMW:CopyTableInPlace(src, dest)
	--src and dest must have congruent data structure, otherwise shit will blow up
	for k in pairs(src) do
		if dest[k] and type(dest[k]) == "table" and type(src[k]) == "table" then
			TMW:CopyTableInPlace(src[k], dest[k])
		elseif type(src[k]) ~= "table" then
			dest[k] = src[k]
		end
	end
	return dest -- not really needed, but what the hell why not
end

function TMW:CopyTableInPlaceWithMeta(src, dest)
	--src and dest must have congruent data structure, otherwise shit will blow up
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

function TMW:GetIconMenuText(g, i, data)
	data = data or db.profile.Groups[tonumber(g)].Icons[tonumber(i)]

	local text = data.Name or ""
	if data.Type == "wpnenchant" and text == "" then
		if data.WpnEnchantType == "MainHandSlot" or not data.WpnEnchantType then text = INVTYPE_WEAPONMAINHAND
		elseif data.WpnEnchantType == "SecondaryHandSlot" then text = INVTYPE_WEAPONOFFHAND
		elseif data.WpnEnchantType == "RangedSlot" then text = INVTYPE_THROWN end
		text = text .. " ((" .. L["ICONMENU_WPNENCHANT"] .. "))"
	elseif data.Type == "meta" then
		text = "((" .. L["ICONMENU_META"] .. "))"
	elseif data.Type == "cast" and text == "" then
		text = "((" .. L["ICONMENU_CAST"] .. "))"
	elseif data.Type == "totem" and text == "" then
		text = "((" .. L["ICONMENU_TOTEM"] .. "))"
	end
	text = text == "" and L["UNNAMED"] or text
	local textshort = strsub(text, 1, 35)
	if strlen(text) > 35 then textshort = textshort .. "..." end

	local tooltip =	((data.Name and data.Name ~= "" and data.Type ~= "meta" and data.Type ~= "wpnenchant") and data.Name .. "\r\n" or "") ..
					((Types[data.Type] and Types[data.Type].name) or "") ..
					((data.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")

	return text, textshort, tooltip
end

function TMW:GuessIconTexture(data)
	local tex = nil
	if (data.Name and data.Name ~= "" and data.Type ~= "meta" and data.Type ~= "wpnenchant") and not tex then
		local name = TMW:GetSpellNames(nil, data.Name, 1)
		if name then
			if data.Type == "cooldown" and data.CooldownType == "item" then
				tex = GetItemIcon(name) or tex
			else
				tex = SpellTextures[name]
			end
		end
	end
	if data.Type == "cast" and not tex then tex = "Interface\\Icons\\Temp"
	elseif data.Type == "buff" and not tex then tex = "Interface\\Icons\\INV_Misc_PocketWatch_01"
	elseif data.Type == "meta" and not tex then tex = "Interface\\Icons\\LevelUpIcon-LFD"
	elseif data.Type == "wpnenchant" and not tex then tex = GetInventoryItemTexture("player", GetInventorySlotInfo(data.WpnEnchantType or "MainHandSlot")) or GetInventoryItemTexture("player", "MainHandSlot") end
	if not tex then tex = "Interface\\Icons\\INV_Misc_QuestionMark" end
	return tex
end

function TMW:GetGroupName(n, g, short)
	if (not n) or n == "" then
		if short then return g end
		return format(L["fGROUP"], g)
	end
	if short then return n .. " (" .. g .. ")" end
	return n .. " (" .. format(L["fGROUP"], g) .. ")"
end

function TMW:CleanIconSettings(settings)
	TMW.DatabaseCleanups.icon(settings)
	return TMW:CleanDefaults(settings, TMW.Icon_Defaults)
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
	end
	for k, v in pairs(tbl) do
		if v.value == value then
			UIDropDownMenu_SetText(frame, v.text)
			return v
		end
	end
	UIDropDownMenu_SetText(frame, "")
end

GameTooltip.OldAddLine = GameTooltip.AddLine
function GameTooltip:AddLine(text, r, g, b, wrap, ...)
	-- this fixes the problem where tooltips in blizz dropdowns dont wrap, nor do they have a setting to do it.
	-- Pretty hackey fix, but it works
	-- Only force the wrap option if the current dropdown has wrapTooltips set true, the dropdown is shown, and the mouse is over the dropdown menu (not DDL.isCounting)
	local DDL = DropDownList1
	if DDL and not DDL.isCounting and DDL.dropdown and DDL.dropdown.wrapTooltips and DDL:IsShown() then
		wrap = 1
	end
	self:OldAddLine(text, r, g, b, wrap, ...)
end

-- --------------
-- MAIN OPTIONS
-- --------------

local function findid(info)
	for i = #info, 0, -1 do
		local n = tonumber(strmatch(info[i], "Group (%d+)"))
		if n then return n end
	end
end

local checkorder = {
	-- NOTE: these are actually backwards so they sort logically in AceConfig, but have their signs switched in the actual function (1 = -1; -1 = 1).
	[-1] = L["ASCENDING"],
	[1] = L["DESCENDING"],
}
local groupConfigTemplate = {
	type = "group",
	childGroups = "tab",
	name = function(info) local g=findid(info) return TMW:GetGroupName(db.profile.Groups[g].Name, g) end,
	order = function(info) return findid(info) end,
	args = {
		main = {
			type = "group",
			name = L["MAIN"],
			order = 1,
			args = {
				Name = {
					name = L["UIPANEL_GROUPNAME"],
					type = "input",
					order = 1,
					width = "full",
					set = function(info, val)
						local g = findid(info)
						db.profile.Groups[g].Name = strtrim(val)
						TMW:Group_Update(g)
					end,
				},
				Enabled = {
					name = L["UIPANEL_ENABLEGROUP"],
					desc = L["UIPANEL_TOOLTIP_ENABLEGROUP"],
					type = "toggle",
					order = 2,
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
					min = 0,
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
						TMW:Group_OnDelete(findid(info))
					end,
					confirm = true,
				},
			},
		},
		countfont = {
			type = "group",
			name = L["UIPANEL_FONT"],
			order = 39,
			set = function(info, val)
				local g = findid(info)
				db.profile.Groups[g].Font[info[#info]] = val
				TMW[g].FontTest = 1
				TMW:Group_Update(g)
			end,
			get = function(info)
				return db.profile.Groups[findid(info)].Font[info[#info]]
			end,
			args = {
				Size = {
					name = L["UIPANEL_FONT_SIZE"],
					desc = L["UIPANEL_FONT_SIZE_DESC"],
					type = "range",
					order = 1,
					min = 6,
					softMax = 26,
					step = 1,
					bigStep = 1,
				},
				x = {
					name = L["UIPANEL_FONT_XOFFS"],
					type = "range",
					order = 10,
					min = -30,
					max = 10,
					step = 1,
					bigStep = 1,
				},
				y = {
					name = L["UIPANEL_FONT_YOFFS"],
					type = "range",
					order = 20,
					min = -10,
					max = 30,
					step = 1,
					bigStep = 1,
				},
				Name = {
					name = L["UIPANEL_FONTFACE"],
					desc = L["UIPANEL_FONT_DESC"],
					type = "select",
					order = 30,
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
					},
					style = "dropdown",
					order = 40,
				},
				OverrideLBFPos = {
					name = L["UIPANEL_FONT_OVERRIDELBF"],
					desc = L["UIPANEL_FONT_OVERRIDELBF_DESC"],
					type = "toggle",
					order = 50,
					hidden = not (LibStub("LibButtonFacade", true) or (LibMasque and LibMasque("Button"))),
				},
			},
		},
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
				level = {
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
				lock = {
					name = L["UIPANEL_LOCK"],
					desc = L["UIPANEL_LOCK_DESC"],
					type = "toggle",
					order = 11,
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
					order = 12,
					func = function(info) TMW:Group_ResetPosition(findid(info)) end
				},
			},
		},
	}
}
for i = 1, GetNumTalentTabs() do
	local _, name = GetTalentTabInfo(i)
	groupConfigTemplate.args.main.args["Tree"..i] = {
		type = "toggle",
		name = name,
		desc = L["UIPANEL_TREE_DESC"],
		order = 7+i,
	}
end

function TMW:CompileOptions() -- options
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
							func = function() db:ResetProfile() TMW:Update() end,
						},
						coloropts = {
							type = "group",
							name = L["UIPANEL_COLORS"],
							order = 3,
							set = function(info, r, g, b, a) local c = db.profile[info[#info]] c.r = r c.g = g c.b = b c.a = a TMW:ColorUpdate() end,
							get = function(info) local c = db.profile[info[#info]] return c.r, c.g, c.b, c.a end,
							args = {
								CDSTColor = {
									name = L["UIPANEL_COLOR_STARTED"],
									desc = L["UIPANEL_COLOR_STARTED_DESC"],
									type = "color",
									order = 31,
									hasAlpha = true,
								},
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
							},
						},
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
									func = function()
										-- this wins by a landside as the most disgusting hack i have ever done.
										-- hopefully, this will only be called when the frame shows itself.
										local groupID = db.profile.NumGroups + 1
										db.profile.NumGroups = groupID
										db.profile.Groups[db.profile.NumGroups].Enabled = true
										TMW:Update()
										local stub = LMB or LBF
										if stub then
											local parent = stub:Group("TellMeWhen")
											local group = stub:Group("TellMeWhen", format(L["fGROUP"], groupID))

											group.SkinID, group.Gloss, group.Backdrop, group.Colors =
											parent.SkinID, parent.Gloss, parent.Backdrop, parent.Colors

											group:ReSkin()
										end
										TMW:Group_Update(groupID)
										TMW:CompileOptions()
										IE:NotifyChanges("groups", "Group " .. groupID)
									end,
								},
							},
						},
					},
				},
			},
		}
		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
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

	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW Options", TMW.OptionsTable)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("TMW Options", 781, 512)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TMW IEOptions", TMW.OptionsTable)
	if not TMW.AddedToBlizz then
		TMW.AddedToBlizz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TMW Options", L["ICON_TOOLTIP1"])
	end
	IE:NotifyChanges()
end


-- -------------
-- GROUP CONFIG
-- -------------

local Ruler = CreateFrame("Frame")
local function GetAnchoredPoints(group)
    local p = TMW.db.profile.Groups[group:GetID()].Point
    Ruler:ClearAllPoints()
    Ruler:SetPoint("TOPLEFT", group, p.point)
    
    local relframe = _G[p.relativeTo] or UIParent
    Ruler:SetPoint("BOTTOMRIGHT", relframe, p.relativePoint)
    
    local X = Ruler:GetWidth()/UIParent:GetScale()/group:GetScale()
    local Y = Ruler:GetHeight()/UIParent:GetScale()/group:GetScale()
    return p.point, relframe:GetName(), p.relativePoint, -X, Y
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

function TMW:Group_OnDelete(groupID)
	tremove(db.profile.Groups, groupID)
	local warntext = ""
	for gID, gs in pairs(db.profile.Groups) do
		for iID, ics in pairs(gs.Icons) do
			if ics.Conditions then
				for k, v in ipairs(ics.Conditions) do
					if v.Icon ~= "" and v.Type == "ICON" then
						local g = tonumber(strmatch(v.Icon, "TellMeWhen_Group(%d+)_Icon"))
						if g > groupID then
							ics.Conditions[k].Icon = gsub(v.Icon, "_Group" .. g, "_Group" .. g-1)
						elseif g == groupID then
							warntext = warntext .. format(L["GROUPICON"], TMW:GetGroupName(gs.Name, gID, 1), iID) .. ", "
						end
					end
				end
			end
			if ics.Type == "meta" then
				for k, v in pairs(ics.Icons) do
					if v ~= "" then
						local g =  tonumber(strmatch(v, "TellMeWhen_Group(%d+)_Icon"))
						if g > groupID then
							ics.Icons[k] = gsub(v, "_Group" .. g, "_Group" .. g-1)
						elseif g == groupID then
							warntext = warntext .. format(L["GROUPICON"], TMW:GetGroupName(gs.Name, gID, 1), iID) .. ", "
						end
					end
				end
			end
		end
	end
	if warntext ~= "" then
		TMW:Print(strsub(warntext, 1, -3))
	end
	db.profile.NumGroups = db.profile.NumGroups - 1
	for k, v in pairs(TMW.Icons) do
		if tonumber(strmatch(v, "TellMeWhen_Group(%d+)")) == groupID then
			TMW:InvalidateIcon(k)
		end
	end
	TMW:Update()
	TMW:CompileOptions()
	CloseDropDownMenus()
end


-- ----------------------
-- ICON DRAGGER
-- ----------------------

ID = TMW:NewModule("IconDragger", "AceTimer-3.0", "AceEvent-3.0") TMW.ID = ID

function ID:OnInitialize()
	--dragging stuff
	function ID:BAR_HIDEGRID() ID.DraggingInfo = nil end
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

function ID:Drag_DropDown(a)
	local info = UIDropDownMenu_CreateInfo()
	local append = ""
	if ID.desticon.texture:GetTexture() ~= "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled" then
		append = "|TInterface\\AddOns\\TellMeWhen_Options\\Textures\\Alert:0:2|t"
	end
	
	info.text = L["ICONMENU_MOVEHERE"] .. append
	info.notCheckable = true
	info.func = ID.Move
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_COPYHERE"] .. append
	info.func = ID.Copy
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_SWAPWITH"]
	info.func = ID.Swap
	UIDropDownMenu_AddButton(info)

	if TMW:IsIconValid(ID.srcicon) then
		info.text = L["ICONMENU_APPENDCONDT"]
		info.func = ID.Condition
		UIDropDownMenu_AddButton(info)

		if ID.desticon.Type == "meta" then
			info.text = L["ICONMENU_ADDMETA"]
			info.func = ID.Meta
			UIDropDownMenu_AddButton(info)
		end
	end
	
	if ID.srcgroupID ~= ID.destgroupID then
		info.text = L["ICONMENU_ANCHOR"]:format(TMW:GetGroupName(db.profile.Groups[ID.destgroupID].Name, ID.destgroupID, 1))
		info.func = ID.Anchor
		UIDropDownMenu_AddButton(info)
	end

	info.text = CANCEL
	info.func = nil
	UIDropDownMenu_AddButton(info)

	UIDropDownMenu_JustifyText(self, "LEFT")
end

function ID:SpellItemToIcon(groupID, iconID)
	local t, data, subType
	local input
	if not (CursorHasSpell() or CursorHasItem()) and ID.DraggingInfo then
		t = "spell"
		data, subType = unpack(ID.DraggingInfo)
	else
		t, data, subType = GetCursorInfo()
	end
	ID.DraggingInfo = nil

	if t == "spell" then
		_, input = GetSpellBookItemInfo(data, subType)
	elseif t == "item" then
		input = data
	end
	if not input then return end
	local icondata = db.profile.Groups[groupID].Icons[iconID]
	icondata.Name = TMW:CleanString(icondata.Name .. ";" .. input)
	if icondata.Type == "" then
		icondata.Type = "cooldown"
		icondata.CooldownType = t
		icondata.Enabled = true
	end
	ClearCursor()
	TMW:Icon_Update(TMW[groupID][iconID])
	IE:Load(1)
end

function ID:Start(icon)
	local scale = icon.group:GetScale()*0.85
	ID.F:SetScript("OnUpdate", function()
		local x, y = GetCursorPosition()
		ID.texture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale )
		ID.back:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale )
	end)
	ID.F:SetScale(scale)
	local t = TMW[ID.srcgroupID][ID.srciconID].texture:GetTexture()
	ID.texture:SetTexture(t)
	if t then
		ID.back:Hide()
	else
		ID.back:Show()
	end
	ID.F:Show()
	ID.IsDragging = true
end

function ID:CompleteDrag(icon) -- icon here is the destination
	if ID.IsDragging then
		ID.desticon = icon
		ID.desticonID = icon:GetID()
		ID.destgroupID = icon.group:GetID()
		ID:Stop()

		if ID.destgroupID == ID.srcgroupID and ID.desticonID == ID.srciconID then return end

		UIDropDownMenu_Initialize(ID.DD, ID.Drag_DropDown, "DROPDOWN")
		UIDropDownMenu_SetAnchor(ID.DD, 0, 0, "TOPLEFT", icon, "BOTTOMLEFT")
		ToggleDropDownMenu(1, nil, ID.DD)
	end
end

function ID:Stop()
	ID.F:SetScript("OnUpdate", nil)
	ID.F:Hide()
	ID:ScheduleTimer("SetIsDraggingFalse", 0.1)
end

function ID:SetIsDraggingFalse()
	ID.IsDragging = false
end

function ID:Move()
	if ID.destgroupID == ID.srcgroupID and ID.desticonID == ID.srciconID then return end
	IE:SaveSettings()
	db.profile.Groups[ID.destgroupID].Icons[ID.desticonID] = db.profile.Groups[ID.srcgroupID].Icons[ID.srciconID]
	db.profile.Groups[ID.srcgroupID].Icons[ID.srciconID] = nil
	ID.desticon.texture:SetTexture(ID.srcicon.texture:GetTexture()) -- preserve buff/debuff/other types textures

	-- update meta icons and icon shown conditions
	local srcicon, desticon = tostring(ID.srcicon), tostring(ID.desticon)
	for ics in TMW:InIconSettings() do
		for k, ic in pairs(ics.Icons) do
			if ic == srcicon then
				ics.Icons[k] = desticon
			end
		end
		for k, condition in pairs(ics.Conditions) do
			if condition.Icon == srcicon then
				condition.Icon = desticon
			end
		end
	end

	TMW:Update()
end

function ID:Copy()
	if ID.destgroupID == ID.srcgroupID and ID.desticonID == ID.srciconID then return end
	IE:SaveSettings()
	db.profile.Groups[ID.destgroupID].Icons[ID.desticonID] = TMW:CopyWithMetatable(db.profile.Groups[ID.srcgroupID].Icons[ID.srciconID])
	ID.desticon.texture:SetTexture(ID.srcicon.texture:GetTexture()) -- preserve buff/debuff/other types textures
	TMW:Update()
end

function ID:Swap()
	if ID.destgroupID == ID.srcgroupID and ID.desticonID == ID.srciconID then return end
	IE:SaveSettings()
	local dest = db.profile.Groups[ID.destgroupID].Icons[ID.desticonID]
	db.profile.Groups[ID.destgroupID].Icons[ID.desticonID] = db.profile.Groups[ID.srcgroupID].Icons[ID.srciconID]
	db.profile.Groups[ID.srcgroupID].Icons[ID.srciconID] = dest
	local desttex = ID.desticon.texture:GetTexture() -- preserve buff/debuff/other types textures
	ID.desticon.texture:SetTexture(ID.srcicon.texture:GetTexture())
	ID.srcicon.texture:SetTexture(desttex)

	-- update meta icons and icon shown conditions
	local srcicon, desticon = tostring(ID.srcicon), tostring(ID.desticon)
	for ics in TMW:InIconSettings() do
		for k, ic in pairs(ics.Icons) do
			if ic == tostring(ID.srcicon) then
				ics.Icons[k] = desticon
			elseif ic == desticon then
				ics.Icons[k] = srcicon
			end
		end
		for k, condition in pairs(ics.Conditions) do
			if condition.Icon == srcicon then
				condition.Icon = desticon
			elseif condition.Icon == desticon then
				condition.Icon = srcicon
			end
		end
	end

	TMW:Update()
end

function ID:Meta()
	if ID.destgroupID == ID.srcgroupID and ID.desticonID == ID.srciconID then return end
	IE:SaveSettings()
	tinsert(db.profile.Groups[ID.destgroupID].Icons[ID.desticonID].Icons, ID.srcicon:GetName())
	TMW:Update()
end

function ID:Condition()
	if ID.destgroupID == ID.srcgroupID and ID.desticonID == ID.srciconID then return end
	IE:SaveSettings()

	local conditions = db.profile.Groups[ID.destgroupID].Icons[ID.desticonID].Conditions
	local condition = conditions[#conditions + 1]
	condition.Type = "ICON"
	condition.Icon = ID.srcicon:GetName()

	TMW:Update()
end

ID.FS = CreateFrame("GameTooltip", "TMWIDFS")
function ID:Anchor()
	if ID.destgroupID == ID.srcgroupID then return end
	db.profile.Groups[ID.srcgroupID].Point.relativeTo = TMW[ID.destgroupID]:GetName()
	TMW:Group_StopMoving(TMW[ID.srcgroupID]) -- i cheat
	TMW:Update()
end

-- ----------------------
-- ICON EDITOR
-- ----------------------

ME = TMW:NewModule("MetaEditor") TMW.ME = ME -- really part of the icon editor now, but im too lazy to move it over

function ME:OnInitialize()
	ME[1] = TellMeWhen_IconEditorMainIcons1
end

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

end

local addedGroups = {} -- this is also used for the condition icon menu, but its just a throwaway, so whatever
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
				info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[g].Name, g, 1), i)
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
				info.text = TMW:GetGroupName(db.profile.Groups[g].Name, g, 1)
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


IE = TMW:NewModule("IconEditor", "AceEvent-3.0") TMW.IE = IE
IE.Checks = { --1=check box, 2=editbox, 3=slider(x100), 4=custom, table=subkeys are settings
	Name = 2,
	CustomTex = 2,
	RangeCheck = 1,
	ManaCheck = 1,
	CooldownCheck = 1,
	IgnoreRunes = 1,
	OnlyMine = 1,
	HideUnequipped = 1,
	OnlyInBags = 1,
	ShowTimer = 1,
	ShowTimerText = 1,
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
	Interruptible = 1,
	Enabled = 1,
	CheckNext = 1,
	UseActvtnOverlay = 1,
	OnlyEquipped = 1,
	OnlySeen = 1,
	DurationMin = 2,
	DurationMax = 2,
	DurationMinEnabled = 1,
	DurationMaxEnabled = 1,
	StackMin = 2,
	StackMax = 2,
	StackMinEnabled = 1,
	StackMaxEnabled = 1,
	Alpha = 3,
	UnAlpha = 3,
	ConditionAlpha = 3,
	FakeHidden = 1,
	DontRefresh = 1,
	EnableStacks = 1,
	CheckRefresh = 1,
	Stealable = 1,
}
IE.Tabs = {
	[1] = "Main",
	[2] = "Conditions",
	[3] = "Sound",
	[4] = "Announcements",
	[5] = "Conditions",
	[6] = "MainOptions",
}
IE.Units = {
	{ value = "player", 					text = PLAYER .. " " .. L["PLAYER_DESC"]  },
	{ value = "target", 					text = TARGET },
	{ value = "targettarget", 				text = L["ICONMENU_TARGETTARGET"] },
	{ value = "focus", 						text = L["ICONMENU_FOCUS"] },
	{ value = "focustarget", 				text = L["ICONMENU_FOCUSTARGET"] },
	{ value = "pet", 						text = PET },
	{ value = "pettarget", 					text = L["ICONMENU_PETTARGET"] },
	{ value = "mouseover", 					text = L["ICONMENU_MOUSEOVER"] },
	{ value = "mouseovertarget",			text = L["ICONMENU_MOUSEOVERTARGET"]  },
	{ value = "vehicle", 					text = L["ICONMENU_VEHICLE"] },
	{ value = "party|cFFFF0000#|r", 		text = PARTY, 			range = "|cFFFF0000#|r = 1-" .. MAX_PARTY_MEMBERS},
	{ value = "raid|cFFFF0000#|r", 			text = RAID, 			range = "|cFFFF0000#|r = 1-" .. MAX_RAID_MEMBERS},
	{ value = "arena|cFFFF0000#|r",			text = ARENA, 			range = "|cFFFF0000#|r = 1-5"},
	{ value = "boss|cFFFF0000#|r", 			text = BOSS, 			range = "|cFFFF0000#|r = 1-" .. MAX_BOSS_FRAMES},
	{ value = "maintank|cFFFF0000#|r", 		text = L["MAINTANK"], 	range = "|cFFFF0000#|r = 1-" .. MAX_RAID_MEMBERS},
	{ value = "mainassist|cFFFF0000#|r", 	text = L["MAINASSIST"], range = "|cFFFF0000#|r = 1-" .. MAX_RAID_MEMBERS},
}

function IE:TabClick(self)
	PanelTemplates_Tab_OnClick(self, self:GetParent())
	PlaySound("igCharacterInfoTab")
	for id, frame in pairs(IE.Tabs) do
		if IE[frame] then
			IE[frame]:Hide()
		end
	end
	if self:GetID() == TMW.ICCNDTTab then
		CNDT.settings = db.profile.Groups[CI.g].Icons[CI.i].Conditions
		CNDT.type = "icon"
		CNDT:Load()
	elseif self:GetID() == TMW.GRCNDTTab then
		CNDT.settings = db.profile.Groups[CI.g].Conditions
		CNDT.type = "group"
		CNDT:Load()
	end
	IE[IE.Tabs[self:GetID()]]:Show()
	TellMeWhen_IconEditor:Show()
end

function IE:NotifyChanges(...)
	local hasPath = ...
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TMW Options")
	if hasPath then
		LibStub("AceConfigDialog-3.0"):SelectGroup("TMW Options", ...)
	end
	if TMW.IE.MainOptionsWidget then
		LibStub("AceConfigDialog-3.0"):Open("TMW IEOptions", TMW.IE.MainOptionsWidget)
		if hasPath then
			LibStub("AceConfigDialog-3.0"):SelectGroup("TMW IEOptions", ...)
		end
	end
end

function IE:SetupRadios()
	local t = CI.t
	local Type = Types[t]
	if Type and Type.TypeChecks then
		for k, frame in pairs(IE.Main.TypeChecks) do
			if strfind(k, "Radio") then
				local info = Type.TypeChecks[frame:GetID()]
				if pclass == "SHAMAN" and Type.TypeChecks.setting == "TotemSlots" and frame:GetID() > 1 then
					local p, rt, rp, x, y = frame:GetPoint(1)
					frame:SetPoint(p, rt, rp, x, 10)
				elseif frame:GetID() > 1 then
					local p, rt, rp, x, y = frame:GetPoint(1)
					frame:SetPoint(p, rt, rp, x, 5)
				end
				if info then
					frame:Show()
					frame.setting = Type.TypeChecks.setting
					frame.value = info.value
					frame.text:SetText((info.colorCode or "") .. info.text .. "|r")
					if info.tooltipText then
						TMW:TT(frame, info.text, info.tooltipText, 1, 1, 1)
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
						TMW:TT(frame, info.text, info.tooltipText, 1, 1, 1)
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

function IE:ShowHide()
	local t = CI.t
	if not t then return end

	for k, v in pairs(IE.Checks) do
		if Types[t].RelevantSettings[k] then
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
	if Types[t] and Types[t].IE_TypeLoaded then
		Types[t]:IE_TypeLoaded()
	end

	local spb = IE.Main.ShowPBar
	local scb = IE.Main.ShowCBar
	if Types[t] and Types[t].HideBars then -- override the previous shows and disables
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

	local stt = IE.Main.ShowTimerText
	if IE.Main.ShowTimer:GetChecked() and (IsAddOnLoaded("OmniCC") or IsAddOnLoaded("tullaCC")) then
		stt:Enable()
	else
		stt:Disable()
	end
end

function IE:SaveSettings()
	if TellMeWhen_IconEditor:IsShown() then
		IE.Main.Name:ClearFocus()
		IE.Main.Unit:ClearFocus()
	end
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
			f:SetText(ics[setting])
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

	for _, parent in pairs({IE.Main.TypeChecks, IE.Main.WhenChecks, IE.Main.Sort}) do
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

function IE:Load(isRefresh)
	if (not TellMeWhen_IconEditor:IsShown() and not isRefresh) or (TellMeWhen_IconEditor.selectedTab == 2 and CI.t == "meta") then
		IE:TabClick(IE.MainTab)
	elseif not TellMeWhen_IconEditor:IsShown() and isRefresh then
		return
	end

	local groupID, iconID = CI.g, CI.i

	IE.Main.Name:ClearFocus()
	IE.Main.Unit:ClearFocus()
	IE.Main.ExportBox:SetText("")
	TellMeWhen_IconEditor:SetScale(db.profile.EditorScale)

	UIDropDownMenu_SetSelectedValue(IE.Main.Type, db.profile.Groups[groupID].Icons[iconID].Type)
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

	local eq2 = TellMeWhen_IconEditor.selectedTab == TMW.ICCNDTTab
	CNDT.settings = eq2 and db.profile.Groups[groupID].Conditions or db.profile.Groups[groupID].Icons[iconID].Conditions
	CNDT.type = eq2 and "group" or "icon"
	CNDT:Load()

	CNDT.settings = eq2 and db.profile.Groups[groupID].Icons[iconID].Conditions or db.profile.Groups[groupID].Conditions
	CNDT.type = eq2 and "icon" or "group"
	CNDT:Load()


	ME:Update()
	SND:Load()
	ANN:Load()

	IE:SetupRadios()
	IE:LoadSettings()
	IE:ShowHide()
end

function IE:Reset()
	local groupID, iconID = CI.g, CI.i
	IE:SaveSettings() -- this is here just to clear the focus of editboxes, not to actually save things
	db.profile.Groups[groupID].Icons[iconID] = nil
	IE:ScheduleIconUpdate(groupID, iconID)
	IE:Load(1)
	IE:TabClick(IE.MainTab)
end

function IE:ShowHelp(text, frame, x, y)
	IE.Help:ClearAllPoints()
	IE.Help:SetPoint("TOPRIGHT", frame, "LEFT", (x or 0) - 30, (y or 0) + 28)
	IE.Help.text:SetText(text)
	IE.Help:SetHeight(IE.Help.text:GetHeight() + 38)
	IE.Help:SetParent(frame)
	IE.Help:Show()
end

function IE:Equiv_GenerateTips(equiv)
	local r = "" --tconcat doesnt allow me to exclude duplicates unless i make another garbage table, so lets just do this
	local tbl = TMW:SplitNames(EquivFullIDLookup[equiv])
	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		if not name then
			if TMW.debug then
				geterrorhandler()("INVALID ID FOUND: "..equiv..":"..v)
			else
				name = v
				texture = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
		end
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple ranks.
			if k ~= #tbl then
				r = r .. "|T" .. texture .. ":0|t" .. name .. "\r\n"
			else
				r = r .. "|T" .. texture .. ":0|t" .. name
			end
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	return r
end

local equivSorted
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
	equivSorted = equivSorted and wipe(equivSorted) or {}
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
	local new = TMW:CleanString(e:GetText())
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

function IE:Type_DropDown()
	if not db then return end
	local groupID, iconID = CI.g, CI.i

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_TYPE"]
	info.value = ""
	info.checked = info.value == db.profile.Groups[groupID].Icons[iconID].Type
	info.func = IE.Type_Dropdown_OnClick
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	local info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.disabled = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	for _, Type in ipairs(TMW.OrderedTypes) do -- order in the order in which they are loaded in the .toc file
		if not Type.hidden then
			local info = UIDropDownMenu_CreateInfo()
			info.text = Type.nameOverride or Type.name
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
		end
	end
end

function IE:Type_Dropdown_OnClick()
	local groupID, iconID = CI.g, CI.i
	db.profile.Groups[groupID].Icons[iconID].Type = self.value
	CI.ic.texture:SetTexture(nil)
	IE:ScheduleIconUpdate(groupID, iconID)
	UIDropDownMenu_SetSelectedValue(IE.Main.Type, self.value)
	CI.t = self.value
	SUG.redoIfSame = 1
	SUG.Suggest:Hide()
	IE:SetupRadios()
	IE:LoadSettings()
	IE:ShowHide()
end

function IE:Unit_DropDown()
	if not db then return end
	local e = TellMeWhen_IconEditor.Main.Unit
	if not e:HasFocus() then
		e:HighlightText()
	end
	for k, v in pairs(IE.Units) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v.text
		info.value = v.value
		if v.range then
			info.tooltipTitle = v.tooltipTitle or v.text
			info.tooltipText = v.range
			info.tooltipOnButton = true
		end
		info.notCheckable = true
		info.func = IE.Unit_DropDown_OnClick
		info.arg1 = self
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end

function IE:Unit_DropDown_OnClick()
	local e = IE.Main.Unit
	e:Insert(";" .. self.value .. ";")
	e:SetText(TMW:CleanString(e:GetText()))
	local groupID, iconID = CI.g, CI.i
	db.profile.Groups[groupID].Icons[iconID].Unit = e:GetText()
	IE:ScheduleIconUpdate(groupID, iconID)
	CloseDropDownMenus()
end

function IE:ImpExp_DropDown()
	if not db then return end
	local e = TMW.IE.Main.ExportBox


	local info = UIDropDownMenu_CreateInfo()
	info.text = L["TOPLAYER"]
	info.tooltipTitle = L["TOPLAYER"]
	info.tooltipText = L["TOPLAYER_DESC"]
	info.tooltipOnButton = true
	info.notCheckable = true
	info.func = function()
		IE:SaveSettings()
		local player = strtrim(e:GetText())
		if player and player ~= "" and #player > 1 and #player < 13 then
			local settings = CopyTable(db.profile.Groups[CI.g].Icons[CI.i])
			TMW:CleanIconSettings(settings)
			local s = TMW:Serialize(settings, TELLMEWHEN_VERSIONNUMBER)

			TMW:SendCommMessage("TMW", s, "WHISPER", player, "BULK", e.callback, e)
		end
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["TOSTRING"]
	info.tooltipTitle = L["TOSTRING"]
	info.tooltipText = L["TOSTRING_DESC"]
	info.tooltipOnButton = true
	info.notCheckable = true
	info.func = function()
		IE:SaveSettings()
		local settings = CopyTable(db.profile.Groups[CI.g].Icons[CI.i])
		TMW:CleanIconSettings(settings)
		local s = TMW:Serialize(settings, TELLMEWHEN_VERSIONNUMBER):
		gsub("(^[^tT%d][^^]*^[^^]*)", "%1 "): -- add spaces to clean it up a little
		gsub("%^ ^", "^^") -- remove double space at the end
		e:SetText(s)
		e:HighlightText()
		e:SetFocus()
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["FROMSTRING"]
	info.tooltipTitle = L["FROMSTRING"]
	info.tooltipText = L["FROMSTRING_DESC"]
	info.tooltipOnButton = true
	info.notCheckable = true
	info.func = function()
		local t = strtrim(e:GetText())
		if t and t ~= "" then
			t = t:gsub("||", "|")
			local success, settings, version = TMW:Deserialize(t)
			if not success then
				error("There was an error processing the string. Ensure that you copied the entire string from the source.")
			end
			e:SetText("")
			e:ClearFocus()
			CloseDropDownMenus()
			local groupID, iconID = CI.g, CI.i

			db.profile.Groups[groupID].Icons[iconID] = nil -- restore defaults, table recreated when passed in to CTIPWM
			TMW:CopyTableInPlaceWithMeta(settings, db.profile.Groups[groupID].Icons[iconID])

			if version then
				if version > TELLMEWHEN_VERSIONNUMBER then
					TMW:Print(L["FROMNEWERVERSION"])
				else
					for k, v in ipairs(TMW:GetUpgradeTable()) do
						if version < k and v.icon then
							v.icon(db.profile.Groups[groupID].Icons[iconID], groupID, iconID)
						end
					end
				end
			end

			IE:ScheduleIconUpdate(groupID, iconID)
			IE:Load(1)
		end
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

local deserialized = {}
function IE:Copy_DropDown()
	local groupID, iconID = CI.g, CI.i
	local icon = CI.ic
	if not (icon and icon.Conditions) then return end
	local info

	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		local current = db:GetCurrentProfile()
		if db.profiles[current] then
			info = UIDropDownMenu_CreateInfo()
			info.text = current
			info.value = current
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

		if TMW.Recieved then
			for k, v in pairs(TMW.Recieved) do -- deserialize recieved icons because we dont do it as they are recieved; AceSerializer is only embedded in _Options
				if type(k) == "string" and v then
					local success, tbl, version = TMW:Deserialize(k)
					if success and type(tbl) == "table" and tbl.Name and tbl.Type then -- checks to make sure that it is actually an icon because of my poor planning
						deserialized[tbl] = version or TELLMEWHEN_VERSIONNUMBER
						TMW.Recieved[k] = false
					end
				end
			end
		end
		if next(deserialized) then
			info = UIDropDownMenu_CreateInfo()
			info.text = L["RECEIVED"]
			info.value = "Imports"
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

		if next(deserialized) or db.profiles[current] then
			info = UIDropDownMenu_CreateInfo()
			info.text = ""
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

		for profilename, profiletable in TMW:OrderedPairs(db.profiles) do
			local profiletable = db.profiles[profilename]
			if not (profilename == current or profilename == "Default") then
				info = UIDropDownMenu_CreateInfo()
				info.text = profilename
				info.value = profilename
				info.hasArrow = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
		if db.profiles["Default"] then
			info = UIDropDownMenu_CreateInfo()
			info.text = "Default"
			info.value = "Default"
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end

	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == "Imports" then
			for tbl, version in pairs(deserialized) do
				local info = UIDropDownMenu_CreateInfo()
				local text, textshort, tooltipText = TMW:GetIconMenuText(nil, nil, tbl)
				info.text = textshort
				info.value = tbl
				info.tooltipTitle = text
				info.tooltipText = tooltipText
				info.tooltipOnButton = true
				info.notCheckable = true
				info.icon = TMW:GuessIconTexture(tbl)
				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				
				info.func = function(self)
					CloseDropDownMenus()
					local groupID, iconID = CI.g, CI.i

					db.profile.Groups[groupID].Icons[iconID] = nil -- restore defaults, table recreated when passed in to CTIPWM
					TMW:CopyTableInPlaceWithMeta(self.value, db.profile.Groups[groupID].Icons[iconID])
					if version > TELLMEWHEN_VERSIONNUMBER then
						TMW:Print(L["FROMNEWERVERSION"])
					else
						for k, v in ipairs(TMW:GetUpgradeTable()) do
							if version < k and v.icon then
								v.icon(db.profile.Groups[groupID].Icons[iconID], groupID, iconID)
							end
						end
					end

					IE:ScheduleIconUpdate(groupID, iconID)
					IE:Load(1)
					db.global.HasImported = true
				end
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			return
		end
		for g, v in TMW:OrderedPairs(db.profiles[UIDROPDOWNMENU_MENU_VALUE].Groups) do
			if g <= (tonumber(db.profiles[UIDROPDOWNMENU_MENU_VALUE].NumGroups) or 10) then
				info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(db.profiles[UIDROPDOWNMENU_MENU_VALUE].Groups[g].Name, g)
				info.value = {profilename = UIDROPDOWNMENU_MENU_VALUE, groupid = g}
				info.hasArrow = true
				info.notCheckable = true
				info.tooltipTitle = format(L["fGROUP"], g)
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

	if UIDROPDOWNMENU_MENU_LEVEL == 3 then
		local g = UIDROPDOWNMENU_MENU_VALUE.groupid
		local n = UIDROPDOWNMENU_MENU_VALUE.profilename

		info = UIDropDownMenu_CreateInfo()
		info.text = n .. ": " .. TMW:GetGroupName(db.profiles[n].Groups[g].Name, g)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYPOS"]
		info.func = function()
			CloseDropDownMenus()

			db.profile.Groups[groupID].Point = nil -- restore defaults, table recreated when passed in to CTIPWM
			TMW:CopyTableInPlaceWithMeta(db.profiles[n].Groups[g].Point, db.profile.Groups[groupID].Point)

			db.profile.Groups[groupID].Scale = db.profiles[n].Groups[g].Scale or TMW.Group_Defaults.Scale
			db.profile.Groups[groupID].Level = db.profiles[n].Groups[g].Level or TMW.Group_Defaults.Level
			TMW:Group_Update(groupID)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYALL"]
		info.func = function()
			CloseDropDownMenus()

			db.profile.Groups[groupID] = nil -- restore defaults, table recreated when passed in to CTIPWM
			TMW:CopyTableInPlaceWithMeta(db.profiles[n].Groups[g], db.profile.Groups[groupID])
			TMW:Group_Update(groupID)
			IE:Load(1)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		if db.profiles[n].Groups[g].Icons and #db.profiles[n].Groups[g].Icons > 0 then

			info = UIDropDownMenu_CreateInfo()
			info.text = ""
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			for i, d in TMW:OrderedPairs(db.profiles[n].Groups[g].Icons) do
				local nsettings = 0
				for icondatakey, icondatadata in pairs(d) do
					if type(icondatadata) == "table" then if next(icondatadata) then nsettings = nsettings + 1 end
					elseif TMW.Icon_Defaults[icondatakey] ~= icondatadata then
						nsettings = nsettings + 1
					end
				end
				if nsettings > 0 and tonumber(i) then
					local tex
					local ic = TMW[g] and TMW[g][i]
					if db:GetCurrentProfile() == n and ic and ic.texture:GetTexture() then
						tex = ic.texture:GetTexture()
					else
						tex = TMW:GuessIconTexture(d)
					end

					local text, textshort, tooltipText = TMW:GetIconMenuText(nil, nil, d)
					info = UIDropDownMenu_CreateInfo()
					info.text = textshort
					info.tooltipTitle = format(L["GROUPICON"], TMW:GetGroupName(db.profiles[n].Groups[g].Name, g, 1), i)
					info.tooltipText = tooltipText
					info.tooltipOnButton = true
					info.icon = tex
					info.tCoordLeft = 0.07
					info.tCoordRight = 0.93
					info.tCoordTop = 0.07
					info.tCoordBottom = 0.93
					info.notCheckable = true
					info.func = function()
						CloseDropDownMenus()

						db.profile.Groups[groupID].Icons[iconID] = nil -- restore defaults, table recreated when passed in to CTIPWM
						TMW:CopyTableInPlaceWithMeta(db.profiles[n].Groups[g].Icons[i], db.profile.Groups[groupID].Icons[iconID])
						local version = #tostring(gsub(db.profiles[n].Version, "[^%d]", "")) >= 5 and tonumber(db.profiles[n].Version)
						if version then
							if version > TELLMEWHEN_VERSIONNUMBER then
								TMW:Print(L["FROMNEWERVERSION"])
							else
								for k, v in ipairs(TMW:GetUpgradeTable()) do
									if version < k and v.icon then
										v.icon(db.profile.Groups[groupID].Icons[iconID], groupID, iconID)
									end
								end
							end
						end

						TMW[groupID][iconID]:SetTexture(nil)
						TMW:Group_Update(groupID)
						IE:Load(1)
					end
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
	end
end


local function formatSeconds(seconds)
	-- note that this is different from the one in conditions.lua
	local d =  seconds / 86400
	local h = (seconds % 86400) / 3600
	local m = (seconds % 86400  % 3600) / 60
	local s =  seconds % 86400  % 3600  % 60

	s = tonumber(format("%.1f", s))
	local ns = s
	if s < 10 then
		ns = "0" .. s
	end

	if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, ns) end
	if h >= 1 then return format("%d:%02d:%s", h, m, ns) end
	if m >= 1 then return format("%d:%s", m, ns) end
	return s
end
local cachednames = {}
function IE:GetRealNames()
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = TMW:CleanString(IE.Main.Name:GetText())
	if cachednames[CI.t .. CI.SoI .. text] then return cachednames[CI.t .. CI.SoI .. text] end

	local tbl
	local BEbackup = TMW.BE
	TMW.BE = TMW.OldBE -- the level of hackyness here is sickening. Note that OldBE does not contain the enrage equiv (intended so we dont flood the tooltip)
	if CI.SoI == "item" then
		tbl = TMW:GetItemIDs(nil, text, false)
	else
		tbl = TMW:GetSpellNames(nil, text)
	end
	local durations = Types[CI.t].DurationSyntax and TMW:GetSpellDurations(nil, text) -- needs to happen before unhacking
	TMW.BE = BEbackup -- unhack
	
	local str = ""
	numadded = 0
	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		name = name or v
		texture = texture or SpellTextures[name]
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple spellIDs.
			numadded = numadded + 1
			local time = Types[CI.t].DurationSyntax and " ("..formatSeconds(durations[k])..")" or ""
			str = str .. (texture and ("|T" .. texture .. ":0|t") or "") .. name .. time .. (k ~= #tbl and "; " or "") -- :0:0:-7
			local numlines = 60
			if #tbl > numlines then -- dont use 1 per line if there's a bunch
				local numperline = ceil(#tbl/numlines)
				str = str .. (floor(numadded/numperline) == numadded/numperline and "\r\n" or "")
			end
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	cachednames[CI.t .. CI.SoI .. text] = str
	return str
end

local IconUpdater = CreateFrame("Frame")
local iconsToUpdate = {}
local function UpdateIcons()
	for icon in pairs(iconsToUpdate) do
		TMW:Icon_Update(tremove(iconsToUpdate, 1))
	end
	IconUpdater:SetScript("OnUpdate", nil)
end
function IE:ScheduleIconUpdate(icon, groupID, iconID)
	-- this is a handler to prevent the spamming of Icon_Update and creating excessive garbage.
	if type(icon) == "number" then --allow omission of icon
		iconID = groupID
		groupID = icon
		icon = TMW[groupID] and TMW[groupID][iconID]
	end
	if not icon then return end
	if not TMW.tContains(iconsToUpdate, icon) then
		tinsert(iconsToUpdate, icon)
	end
	IconUpdater:SetScript("OnUpdate", UpdateIcons)
end


-- ----------------------
-- SOUNDS
-- ----------------------

SND = TMW:NewModule("Sound") TMW.SND = SND
SND.LSM = LSM
SND.List = CopyTable(LSM:List("sound"))
TMW.EventList = {
	{
		name = "OnShow",
		text = L["SOUND_EVENT_ONSHOW"],
		desc = L["SOUND_EVENT_ONSHOW_DESC"],
	},
	{
		name = "OnHide",
		text = L["SOUND_EVENT_ONHIDE"],
		desc = L["SOUND_EVENT_ONHIDE_DESC"],
	},
	{
		name = "OnStart",
		text = L["SOUND_EVENT_ONSTART"],
		desc = L["SOUND_EVENT_ONSTART_DESC"],
	},
	{
		name = "OnFinish",
		text = L["SOUND_EVENT_ONFINISH"],
		desc = L["SOUND_EVENT_ONFINISH_DESC"],
	},
	{
		name = "OnAlphaInc",
		text = L["SOUND_EVENT_ONALPHAINC"],
		desc = L["SOUND_EVENT_ONALPHAINC_DESC"],
	},
	{
		name = "OnAlphaDec",
		text = L["SOUND_EVENT_ONALPHADEC"],
		desc = L["SOUND_EVENT_ONALPHADEC_DESC"],
	},
}
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

function SND:SetSoundsOffset(offs)
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

function SND:SelectEvent(id)
	SND.currentEventID = id
	SND.currentEvent = SND.Events[id].event

	local eventFrame = SND.Events[id]
	for i=1, #SND.Events do
		local f = SND.Events[i]
		f.selected = nil
		f:UnlockHighlight()
		f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end
	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)

	if CI.ics then
		SND:SelectSound(CI.ics.Events[eventFrame.event].Sound)
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
	end

	for i=1, #SND.Sounds do
		local f = SND.Sounds[i]
		if f.soundname == name then
			soundFrame = f
		end
		f.selected = nil
		f:UnlockHighlight()
		f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
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
	SND.Events[SND.currentEventID].SoundName:SetText(name)
	SND:SetTabText()
end

function SND:Load()
	local oldID = SND.currentEventID
	for i = #SND.Events, 1, -1 do
		SND:SelectEvent(i)
	end
	if oldID then
		SND:SelectEvent(oldID)
	end
	SND:SetTabText()
end

function SND:SetTabText()
	local groupID, iconID = CI.g, CI.i
	local n = 0
	for i = 1, #SND.Events do
		local f = SND.Events[i]
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
	if n > 0 then
		IE.SoundTab:SetText(L["SOUND_TAB"] .. " |cFFFF5959(" .. n .. ")")
	else
		IE.SoundTab:SetText(L["SOUND_TAB"] .. " (" .. n .. ")")
	end
	PanelTemplates_TabResize(IE.SoundTab, -6)
end

function SND:OnInitialize()
	local Events = SND.Events
	Events.Header:SetText(L["SOUND_EVENTS"])
	local previous
	for i=1, #TMW.EventList do
		local f = CreateFrame("Button", Events:GetName().."Event"..i, Events, "TellMeWhen_SoundEvent", i)
		Events[i] = f
		f:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
		f:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT")
		f.event = TMW.EventList[i].name
		f.setting = "Sound" .. f.event
		f.EventName:SetText(TMW.EventList[i].text)
		TMW:TT(f, TMW.EventList[i].text, TMW.EventList[i].desc, 1, 1)
		previous = f
	end
	Events[1]:SetPoint("TOPLEFT", Events, "TOPLEFT", 0, 0)
	Events[1]:SetPoint("TOPRIGHT", Events, "TOPRIGHT", 0, 0)
	Events:SetHeight(#Events*Events[1]:GetHeight())
	SND:SelectEvent(1)	
	
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
	for i=1, floor(Sounds:GetHeight())/Sounds.None:GetHeight() do
		local f = CreateFrame("Button", Sounds:GetName().."Sound"..i, Sounds, "TellMeWhen_SoundSelectButton", i)
		Sounds[i] = f
		f:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
		f:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, 0)
		previous = f
	end
	SND:SetSoundsOffset(0)
	
	SND.Sounds.ScrollBar:SetValue(0)
end


-- ----------------------
-- ANNOUNCEMENTS
-- ----------------------

ANN = TMW:NewModule("Announcements") TMW.ANN = ANN
local ChannelLookup = TMW.ChannelLookup

function ANN:OnInitialize()
	local Events = ANN.Events
	Events.Header:SetText(L["SOUND_EVENTS"])
	local previous
	for i=1, #TMW.EventList do
		local f = CreateFrame("Button", Events:GetName().."Event"..i, Events, "TellMeWhen_AnnounceEvent", i)
		Events[i] = f
		f:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
		f:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT")
		f.event = TMW.EventList[i].name
		f.EventName:SetText(TMW.EventList[i].text)
		TMW:TT(f, TMW.EventList[i].text, TMW.EventList[i].desc, 1, 1)
		previous = f
	end
	Events[1]:SetPoint("TOPLEFT", Events, "TOPLEFT", 0, 0)
	Events[1]:SetPoint("TOPRIGHT", Events, "TOPRIGHT", 0, 0)
	Events:SetHeight(#Events*Events[1]:GetHeight())
	
	local Channels = ANN.Channels
	Channels.Header:SetText(L["ANN_CHANTOUSE"])
	local previous
	local offs = 0
	for i, t in ipairs(TMW.ChannelList) do
		if not t.hidden then
			i = i + offs
			local f = CreateFrame("Button", Channels:GetName().."Channel"..i, Channels, "TellMeWhen_ChannelSelectButton", i)
			Channels[i] = f
			f:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
			f:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, 0)
			previous = f
			f.channel = t.channel
			f.Name:SetText(t.text)
			f:Show()
			TMW:TT(f, t.text, t.addon, 1, 1)
		else
			offs = offs - 1
		end
	end
	Channels[1]:SetPoint("TOPLEFT", Channels, "TOPLEFT", 0, 0)
	Channels[1]:SetPoint("TOPRIGHT", Channels, "TOPRIGHT", 0, 0)
	Channels:SetHeight(#Channels*Channels[1]:GetHeight())
end

function ANN:SelectEvent(id)
	ANN.Editbox:ClearFocus()
	ANN.currentEventID = id
	ANN.currentEvent = ANN.Events[id].event

	local eventFrame = ANN.Events[id]
	for i=1, #ANN.Events do
		local f = ANN.Events[i]
		f.selected = nil
		f:UnlockHighlight()
		f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end
	eventFrame.selected = 1
	eventFrame:LockHighlight()
	eventFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)

	if CI.ics then
		local EventSettings = CI.ics.Events[eventFrame.event]
		ANN:SelectChannel(EventSettings.Channel)
		ANN.Editbox:SetText(EventSettings.Text)
	end
end

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
			local location = EventSettings.Location
			location = location and location ~= "" and location or channelsettings.defaultlocation
			location = channelsettings.ddtext(location) and location or channelsettings.defaultlocation
			EventSettings.Location = location
			loc = channelsettings.ddtext(location)
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
			ANN.EditBox:SetText(EventSettings.Location)
			ANN.EditBox:Show()
		else
			ANN.EditBox:Hide()
		end
	end

	if channelFrame then
		channelFrame:LockHighlight()
		channelFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end
	if ANN.currentEventID and channelsettings then
		ANN.Events[ANN.currentEventID].ChannelName:SetText(channelsettings.text)
	end
	ANN:SetTabText()
end

function ANN:Load()
	local oldID = ANN.currentEventID
	for i = #ANN.Events, 1, -1 do
		ANN:SelectEvent(i)
	end
	if oldID then
		ANN:SelectEvent(oldID)
	end
	ANN:SetTabText()
end

function ANN:SetTabText()
	local n = 0
	for i = 1, #ANN.Events do
		local f = ANN.Events[i]
		local channel = CI.ics.Events[f.event].Channel
		if channel and #channel > 2 and channel ~= "None" then
			n = n + 1
		end
	end
	if n > 0 then
		IE.AnnounceTab:SetText(L["ANN_TAB"] .. " |cFFFF5959(" .. n .. ")")
	else
		IE.AnnounceTab:SetText(L["ANN_TAB"] .. " (0)")
	end
	PanelTemplates_TabResize(IE.AnnounceTab, -6)
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

SUG = TMW:NewModule("Suggester", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0") TMW.SUG = SUG
local inputType
local SUGIMS, SUGSoI
local SUGpreTable = {}
local SUGPlayerSpells = {}
local ActionCache, pclassSpellCache, ClassSpellLookup, AuraCache, ItemCache, SpellCache, CastCache
local TrackingCache = {}
for i = 1, GetNumTrackingTypes() do
	local name, _, active = GetTrackingInfo(i)
	TrackingCache[i] = strlower(name)
end

function SUG:OnInitialize()
	TMWOptDB = TMWOptDB or {}

	CNDT:CURRENCY_DISPLAY_UPDATE() -- im in ur SUG, hijackin' ur OnInitialize

	TMWOptDB.SpellCache = TMWOptDB.SpellCache or {}
	TMWOptDB.CastCache = TMWOptDB.CastCache or {}
	TMWOptDB.ItemCache = TMWOptDB.ItemCache or {}
	TMWOptDB.AuraCache = TMWOptDB.AuraCache or {}
	TMWOptDB.ClassSpellCache = nil -- this is old, get rid of it

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

	SUG.ActionCache = {} -- dont save this, it should be a list of things that are CURRENTLY on THIS CHARACTER'S action bars
	SUG.RequestedFrom = {}
	SUG.commThrowaway = {}
	SUG.Box = IE.Main.Name
	
	SUG:PLAYER_TALENT_UPDATE()
	SUG:BuildClassSpellLookup() -- must go before the local versions (ClassSpellLookup) are defined
	SUG.doUpdateItemCache = true
	SUG.doUpdateActionCache = true

	SUG:RegisterComm("TMWSUG")
	SUG:RegisterEvent("PLAYER_TALENT_UPDATE")
	SUG:RegisterEvent("PLAYER_ENTERING_WORLD")
	SUG:RegisterEvent("UNIT_PET")
	SUG:RegisterEvent("BAG_UPDATE")
	SUG:RegisterEvent("BANKFRAME_OPENED", "BAG_UPDATE")
	SUG:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

	if IsInGuild() then
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "GUILD")
	end

	ActionCache, pclassSpellCache, ClassSpellLookup, AuraCache, ItemCache, SpellCache, CastCache =
	SUG.ActionCache, TMW.ClassSpellCache[pclass], SUG.ClassSpellLookup, SUG.AuraCache, SUG.ItemCache, SUG.SpellCache, SUG.CastCache

	SUG:PLAYER_ENTERING_WORLD()

	local _, _, _, clientVersion = GetBuildInfo()
	if TMWOptDB.IncompleteCache or not TMWOptDB.WoWVersion or TMWOptDB.WoWVersion < clientVersion then
		local didrunhook
		TellMeWhen_IconEditor:HookScript("OnShow", function()
			if didrunhook then return end
			TMWOptDB.IncompleteCache = true
			SUG.NumCachePerFrame = 1 -- 0 is actually 1. Yeah, i know, its lame. I'm lazy.

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
			TMWOptDB.CacheLength = TMWOptDB.CacheLength or 100000
			SUG.Suggest.Status:Show()
			SUG.Suggest.Status.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
			SUG.Suggest.Status:SetMinMaxValues(1, TMWOptDB.CacheLength)
			SUG.Suggest.Speed:Show()
			if TMWOptDB.WoWVersion and TMWOptDB.WoWVersion < clientVersion then
				wipe(SUG.SpellCache)
				wipe(SUG.CastCache)
			elseif TMWOptDB.IncompleteCache then
				for id in pairs(SUG.SpellCache) do
					index = max(index, id)
				end
			end
			TMWOptDB.WoWVersion = clientVersion

			local Parser = CreateFrame("GameTooltip", "TMWSUGParser", TMW, "GameTooltipTemplate")
			local f = CreateFrame("Frame")
			local function SpellCacher()
				for id = index, index + SUG.NumCachePerFrame - 1 do
					SUG.Suggest.Status:SetValue(id)
					if spellsFailed < 1000 then
						local name, rank, icon, _, _, _, castTime = GetSpellInfo(id)
						if name then
							name = strlower(name)
							if
								not Blacklist[icon] and
								not strfind(name, "dnd") and
								not strfind(name, "test") and
								not strfind(name, "debug") and
								not strfind(name, "bunny") and
								not strfind(name, "visual") and
								not strfind(name, "trigger") and
								not strfind(name, "[%[%%%+%?]") and -- no brackets, plus signs, percent signs, or question marks
								not strfind(name, "quest") and
								not strfind(name, "vehicle") and
								not strfind(name, "event") and
								not strfind(name, ":%s?%d") and -- interferes with colon duration syntax
								not strfind(name, "camera")
							then
								GameTooltip_SetDefaultAnchor(Parser, UIParent)
								Parser:SetSpellByID(id)
								local r, g, b = TMWSUGParserTextLeft1:GetTextColor()
								if g > .95 and r > .95 and b > .95 then
									SUG.SpellCache[id] = name
									if TMWSUGParserTextLeft2:GetText() == SPELL_CAST_CHANNELED or TMWSUGParserTextLeft3:GetText() == SPELL_CAST_CHANNELED or castTime > 0 then
										SUG.CastCache[id] = name
									end
								end
								Parser:Hide()
								spellsFailed = 0
							end
						else
							spellsFailed = spellsFailed + 1
						end
					else
						TMWOptDB.IncompleteCache = false
						TMWOptDB.CacheLength = id
						f:SetScript("OnUpdate", nil)
						SUG.Suggest.Speed:Hide()
						SUG.Suggest.Status:Hide()

						SUG.IsCaching = nil
						SUG.SpellCache[1852] = nil -- GM spell named silenced, interferes with equiv
						SUG.SpellCache[71216] = nil -- enraged
						if SUG.onCompleteCache then
							SUG.onCompleteCache = nil
							TMW.SUG.redoIfSame = 1
							SUG:NameOnCursor()
						end
						collectgarbage()
						return
					end
				end
				index = index + SUG.NumCachePerFrame
			end
			f:SetScript("OnUpdate", SpellCacher)
			SUG.IsCaching = true
			didrunhook = true
		end)
	end
end

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
	for i = 1, offs + numspells do
		local _, id = GetSpellBookItemInfo(i, "player")
		if id then
			local name, rank = GetSpellInfo(id)
			if rank == RACIAL then
				TMW.ClassSpellCache.RACIAL[id] = UnitRace("player")
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

function SUG:ACTIONBAR_SLOT_CHANGED()
	SUG.doUpdateActionCache = true
end

function SUG:OnCommReceived(prefix, text, channel, who)
	print(text, channel, who)
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
				for id in pairs(tbl) do
					TMW.ClassSpellCache[class][id] = 1
				end
			end
			SUG:BuildClassSpellLookup()
		end
	elseif TMW.debug then
		geterrorhandler()(arg1)
	end
end

function GameTooltip:SetTMWEquiv(equiv)
	GameTooltip:AddLine(L[equiv], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(IE:Equiv_GenerateTips(equiv), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
end

function SUG.Sorter(a, b)
	--[[PRIORITY:
		1)	Equivalancies/Dispel Types
		2)	Abilities on player's action bar if current icon is a multistate cooldown
		3)	Player's spells (pclass)
		4)	All player spells (any class)
		5)	Known auras
			5a) Player Auras
			5b) NPC Auras
		6)	SpellID if input is an ID
		7)	If input is a name
			7a) Alphabetical if names are different
			7b) SpellID if names are identical
	]]

	local haveA, haveB = EquivFirstIDLookup[a], EquivFirstIDLookup[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	if SUGIMS then
		local haveA, haveB = ActionCache[a], ActionCache[b]
		if (haveA and not haveB) or (haveB and not haveA) then
			return haveA
		end
	end

	if SUGSoI == "spell" then
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
	end

	if inputType == "number" or SUGSoI == "tracking" then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB
		if SUGSoI == "item" then
			nameA, nameB = ItemCache[a], ItemCache[b]
		else
			nameA, nameB = SpellCache[a], SpellCache[b]
		end
		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end

function SUG:DoSuggest()
	SUGSoI = SUG.overrideSoI or CI.SoI
	local atBeginning = SUG.atBeginning
	local overrideSoI = SUG.overrideSoI
	local t = CI.t
	local lastName = SUG.lastName
	local semiLN = ";"..lastName
	local long = #lastName > 2
	wipe(SUGpreTable)
	if not overrideSoI then
		for _, tbl in TMW:Vararg((t == "dr" and TMW.BE.dr) or (t == "cast" and TMW.BE.casts) or (t == "buff" and TMW.BE.buffs), (t == "buff" and TMW.BE.debuffs)) do
			if not tbl then break end
			for equiv in pairs(tbl) do
				if 	(long and (
						(strfind(strlowerCache[equiv], lastName)) or
						(strfind(strlowerCache[L[equiv]], lastName)) or
						((inputType == "string" and strfind(strlowerCache[EquivFullNameLookup[equiv]], semiLN)) or
						(inputType == "number" and strfind(EquivFullIDLookup[equiv], semiLN))))
				) or
					(not long and (
						(strfind(strlowerCache[equiv], atBeginning)) or
						(strfind(strlowerCache[L[equiv]], atBeginning)))
				) then
					SUGpreTable[#SUGpreTable + 1] = equiv
				end
			end
		end
		
		if t == "buff" then
			for dispeltype in pairs(TMW.DS) do
				if strfind(strlowerCache[dispeltype], atBeginning) or strfind(strlowerCache[L[dispeltype]], atBeginning)  then
					SUGpreTable[#SUGpreTable + 1] = dispeltype
				end
			end
		end
	end
	
	local tbl
	if SUGSoI == "item" then
		tbl = ItemCache
	elseif SUGSoI == "tracking" then
		tbl = TrackingCache
	elseif t == "cast" and not overrideSoI then
		tbl = CastCache
	else
		tbl = SpellCache
	end
	
	for id, name in pairs(tbl) do
		if inputType == "number" then
			if strfind(id, atBeginning) then
				SUGpreTable[#SUGpreTable + 1] = id
			end
		else
			if strfind(name, atBeginning) then
				SUGpreTable[#SUGpreTable + 1] = id
			end
		end
	end
	
	SUG:SuggestingComplete(1)
end

function SUG:SuggestingComplete(doSort)
	SUG.offset = min(SUG.offset, max(0, #SUGpreTable-#SUG+1))
	local offset = SUG.offset
	SUGSoI = SUG.overrideSoI or CI.SoI
	SUGIMS = CI.IMS
	if doSort then
		sort(SUGpreTable, SUG.Sorter)
	end

	local i = 1
	while SUG[i] do
		local id = SUGpreTable[i+offset]
		local f = SUG[i]
		if id then
			f.Background:SetVertexColor(0, 0, 0, 0)
			if TMW.DS[id] then -- if the entry is a dispel type (magic, poison, etc)
				local dispeltype = id

				f.Name:SetText(dispeltype)
				f.ID:SetText(nil)

				f.insert = dispeltype

				f.tooltipmethod = nil
				f.tooltiptitle = dispeltype
				f.tooltiptext = L["ICONMENU_DISPEL"]

				f.Icon:SetTexture(TMW.DS[id])
				f.Background:SetVertexColor(1, .49, .04, 1) -- druid orange

			elseif EquivFirstIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
				--NOTE: dispel types are put in EquivFirstIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
				local equiv = id
				local firstid = EquivFirstIDLookup[id]

				f.Name:SetText(equiv)
				f.ID:SetText(nil)

				f.insert = equiv

				f.tooltipmethod = "SetTMWEquiv"
				f.tooltiparg = equiv

				f.Icon:SetTexture(SpellTextures[firstid])
				if TMW.BE.buffs[equiv] then
					f.Background:SetVertexColor(.2, .9, .2, 1) -- lightish green
				elseif TMW.BE.debuffs[equiv] then
					f.Background:SetVertexColor(.77, .12, .23, 1) -- deathknight red
				elseif TMW.BE.casts[equiv] or TMW.BE.dr[equiv] then
					f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
				end

			elseif tonumber(id) then --sanity check
				if SUGSoI == "item" then -- if the entry is an item
					local name, link = GetItemInfo(id)

					f.Name:SetText(link)
					f.ID:SetText(id)

					f.insert = inputType == "number" and id or name

					f.tooltipmethod = "SetHyperlink"
					f.tooltiparg = link

					f.Icon:SetTexture(GetItemIcon(id))

				elseif SUGSoI == "tracking" then 
					local name, texture = GetTrackingInfo(id)

					f.Name:SetText(name)
					f.ID:SetText(nil)

					f.insert = name

					f.tooltipmethod = nil
					f.tooltiparg = nil

					f.Icon:SetTexture(texture)

				else -- the entry must be just a normal spell
					local name = GetSpellInfo(id)

					f.Name:SetText(name)
					f.ID:SetText(id)

					f.tooltipmethod = "SetSpellByID"
					f.tooltiparg = id

					f.insert = inputType == "number" and id or name

					f.Icon:SetTexture(SpellTextures[id])
					if SUGIMS and SUG.ActionCache[id] then
						f.Background:SetVertexColor(0, .44, .87, 1) --color actions that are on your action bars if the type is a multistate cooldown shaman blue
					elseif SUGPlayerSpells[id] then
						f.Background:SetVertexColor(.41, .8, .94, 1) --color all other spells that you have in your/your pet's spellbook mage blue
					else
						for class, tbl in pairs(TMW.ClassSpellCache) do
							if tbl[id] then
								f.Background:SetVertexColor(.96, .55, .73, 1) --color all other known class spells paladin pink
								break
							end
						end
					end
				end
			end
			local whoCasted = (SUGSoI == "spell") and SUG.AuraCache[id]
			if whoCasted then
				local r, g, b, a = f.Background:GetVertexColor()
				if a < .5 then -- only if nothing else has colored the entry yet
					if whoCasted == 1 then
						f.Background:SetVertexColor(.78, .61, .43, 1) -- color known NPC auras warrior brown
					elseif whoCasted == 2 then
						f.Background:SetVertexColor(.79, .30, 1, 1) -- color known PLAYER auras a bright pink ish pruple ish color that is similar to paladin pink but has sufficient contrast for distinguishing
					end
				end
			end
			f:Show()
		else
			f:Hide()
		end
		i=i+1
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
	else
		SUG.duration = nil
	end

	--disable pattern matches that will break/interfere, but dont do it for me because I will just manually escape things if they show up for whatever reason. I want them for debugging, blah blah blah
	if not TMW.debug then
		SUG.lastName = gsub(SUG.lastName, "([%(%)%*%%%[%]%-])", "%%%1")
	end


	SUG.atBeginning = "^"..SUG.lastName

	
	if (not TMW.debug and #SUG.lastName < 2) or SUG.lastName == "" or not strfind(SUG.lastName, "[^%.]") then
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
		for k, v in pairs(TMW.ClassSpellCache.RACIAL) do
			if v == UnitRace("player") then
				SUGPlayerSpells[k] = 1
			end
		end
		SUG.updatePlayerSpells = nil
	end

	inputType = type(tonumber(SUG.lastName) or SUG.lastName)

	if SUG.oldLastName ~= SUG.lastName or SUG.redoIfSame then
		SUG.redoIfSame = nil
		SUG:CacheItems()
		if CI.IMS then
			SUG:CacheActions()
		end

		SUG.offset = 0
		SUG:DoSuggest()
	end

end

function SUG:OnClick()
	if self.insert then
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf
		if start <= 0 then
			firsthalf = ""
		else
			firsthalf = strsub(currenttext, 0, start)
		end
		local lasthalf = strsub(currenttext, SUG.endpos+1)
		
		local addcolon = (SUG.duration or (Types[CI.t].DurationSyntax and not SUG.overrideSoI))
		local insert = (addcolon and self.insert .. ": " .. (SUG.duration or "")) or self.insert
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf
		SUG.Box:SetText(TMW:CleanString(newtext))
		SUG.Box:SetCursorPosition(SUG.endpos + (#tostring(insert) - #tostring(SUG.lastName)))
		
		local offset = 0
		if SUG.Box:GetCursorPosition() == SUG.Box:GetNumLetters() and not SUG.overrideSoI then -- if we are at the end of the exitbox then put a semicolon in anyway for convenience
			SUG.Box:SetText(SUG.Box:GetText().. (addcolon and " " or "") .. "; ")
			offset = 2 
		elseif SUG.overrideSoI then
			SUG.Box:ClearFocus()
		end
		if addcolon then
			SUG.Box:SetCursorPosition(SUG.Box:GetCursorPosition() - offset)
		end
		SUG.Suggest:Hide()
	end
end

function SUG:CacheItems()
	if not SUG.doUpdateItemCache then return end
	for container = -2, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(container) do
			local id = GetContainerItemID(container, slot)
			if id then
				ItemCache[id] = strlower(GetItemInfo(id))
			end
		end
	end
	for slot = 1, 19 do
		local id = GetInventoryItemID("player", slot)
		if id then
			ItemCache[id] = strlower(GetItemInfo(id))
		end
	end
	SUG.doUpdateItemCache = nil
end

function SUG:CacheActions()
	if not SUG.doUpdateActionCache then return end
	wipe(ActionCache)
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID then
			ActionCache[spellID] = i
		end
	end
	SUG.doUpdateActionCache = nil
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

function SUG:EnableEditbox(editbox, inputType, setOverride)
	editbox.SUG_Enabled = 1
	
	inputType = get(inputType)
	inputType = (inputType == true and "spell") or inputType
	if not inputType then
		return SUG:DisableEditbox(editbox)
	end
	editbox.SUG_type = inputType
	editbox.SUG_setOverride = setOverride
	
	--[[SUG.redoIfSame = 1
	SUG.Box = editbox
	SUG.overrideSoI = setOverride and inputType
	SUG:NameOnCursor()]]
	
	if not editbox.SUG_hooked then
		editbox:HookScript("OnEditFocusLost", function(self)
			if self.SUG_Enabled then
				SUG.Suggest:Hide()
			end
		end)
		editbox:HookScript("OnEditFocusGained", function(self)
			if self.SUG_Enabled then
				SUG.redoIfSame = nil
				SUG.Box = self
				SUG.overrideSoI = self.SUG_setOverride and self.SUG_type
				SUG:NameOnCursor()
			end
		end)
		editbox:HookScript("OnTextChanged", function(self, userInput)
			if userInput and self.SUG_Enabled then
				SUG.redoIfSame = nil
				SUG:NameOnCursor()
			end
		end)
		editbox:HookScript("OnMouseUp", function(self)
			if self.SUG_Enabled then
				SUG:NameOnCursor(1)
			end
		end)
		editbox.SUG_hooked = 1
	end

end

function SUG:DisableEditbox(editbox)
	editbox.SUG_Enabled = nil
end


-- -----------------------
-- CONDITION EDITOR DIALOG
-- -----------------------

CNDT = TMW.CNDT

function CNDT:TypeMenuOnClick(frame, data)
	UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
	UIDropDownMenu_SetText(UIDROPDOWNMENU_OPEN_MENU, data.text)
	local group = UIDROPDOWNMENU_OPEN_MENU:GetParent()
	local showval = group:TypeCheck(data)
	group:SetSliderMinMax()
	if showval then
		group:SetValText()
	else
		group.ValText:SetText("")
	end
	CNDT:OK()
	CloseDropDownMenus()
end

local addedThings = {}
local usedCount = {}
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
	info.func = CNDT.TypeMenuOnClick
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
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["CNDTCAT_FREQUENTLYUSED"]
		info.value = "FREQ"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = ""
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
	
	if UIDROPDOWNMENU_MENU_LEVEL == 2 and UIDROPDOWNMENU_MENU_VALUE == "FREQ" then
		local num = 0
		wipe(addedThings)
		for _, k in ipairs(commonConditions) do
			AddConditionToDropDown(CNDT.ConditionsByType[k])
			addedThings[k] = 1
			num = num + 1
			if num > 20 then break end
		end
		wipe(usedCount)
		for ics in TMW:InIconSettings() do
			for k, condition in pairs(ics.Conditions) do
				usedCount[condition.Type] = (usedCount[condition.Type] or 0) + 1
			end
		end
		for k, n in TMW:OrderedPairs(usedCount, "values", true) do
			if not addedThings[k] then
				AddConditionToDropDown(CNDT.ConditionsByType[k])
				addedThings[k] = 1
				num = num + 1
				if num > 20 then break end
			end
		end
	end
	
	wipe(addedThings)
	for k, v in ipairs(CNDT.Types) do
		if ((UIDROPDOWNMENU_MENU_LEVEL == 2 and v.category == UIDROPDOWNMENU_MENU_VALUE) or (UIDROPDOWNMENU_MENU_LEVEL == 1 and not v.category)) and not v.hidden then
			if v.spacebefore then
				local info = UIDropDownMenu_CreateInfo()
				info.text = ""
				info.isTitle = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			
			AddConditionToDropDown(v)
		elseif UIDROPDOWNMENU_MENU_LEVEL == 1 and v.category and not addedThings[v.category] then
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

function CNDT:UnitMenu_DropDown()
	for k, v in pairs(IE.Units) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = function(self, frame)
			frame:GetParent():SetText(v.value)
			CNDT:OK()
		end
		if v.range then
			info.tooltipTitle = v.tooltipTitle or v.text
			info.tooltipText = v.range
			info.tooltipOnButton = true
		end
		info.text = v.text
		info.value = v.value
		info.hasArrow = v.hasArrow
		info.notCheckable = true
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
end

function CNDT:IconMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	CloseDropDownMenus()
	CNDT:OK()
end

function CNDT:IconMenu_DropDown()
	sort(TMW.Icons, TMW.IconsSort)
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for k, v in ipairs(TMW.Icons) do
			local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
			g, i = tonumber(g), tonumber(i)
			if UIDROPDOWNMENU_MENU_VALUE == g then
				local info = UIDropDownMenu_CreateInfo()
				info.func = CNDT.IconMenuOnClick
				local text, textshort = TMW:GetIconMenuText(g, i)
				info.text = textshort
				info.value = v
				info.tooltipTitle = text
				info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[g].Name, g, 1), i)
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
				info.text = TMW:GetGroupName(db.profile.Groups[g].Name, g, 1)
				info.hasArrow = true
				info.notCheckable = true
				info.value = g
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				addedGroups[g] = true
			end
		end
	end
end

function CNDT:OperatorMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	TMW:TT(frame, self.tooltipTitle, nil, 1, nil, 1)
	CNDT:OK()
end

function CNDT:OperatorMenu_DropDown()
	for k, v in pairs(CNDT.Operators) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.OperatorMenuOnClick
		info.text = v.text
		info.value = v.value
		info.tooltipTitle = v.tooltipText
		info.tooltipOnButton = true
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
end

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

function CNDT:ValidateParenthesis()
	if not IE.Conditions:IsShown() then return end
	local numclose, numopen, runningcount = 0, 0, 0
	local unopened
	for k, v in ipairs(CNDT) do
		if v:IsShown() then
			if v.OpenParenthesis:IsShown() then
				for k, v in ipairs(v.OpenParenthesis) do
					if v:GetChecked() then
						numopen = numopen + 1
						runningcount = runningcount + 1
					end
					if runningcount < 0 then unopened = 1 end
				end
			end
			if v.CloseParenthesis:IsShown() then
				for k, v in ipairs(v.CloseParenthesis) do
					if v:GetChecked() then
						numclose = numclose + 1
						runningcount = runningcount - 1
					end
					if runningcount < 0 then unopened = 1 end
				end
			end
		end
	end

	if numopen ~= numclose then
		local suffix = ""
		if numopen > numclose then
			suffix = " +" .. numopen-numclose .. " '('"
		else
			suffix = " +" .. numclose-numopen .. " ')'"
		end
		IE.Conditions.Warning:SetText(L["PARENTHESISWARNING"] .. suffix)
		CNDT.invalid = 1
	elseif unopened then
		IE.Conditions.Warning:SetText(L["PARENTHESISWARNING2"])
		CNDT.invalid = 1
	else
		IE.Conditions.Warning:SetText(nil)
		CNDT.invalid = nil
	end

	local n = 1
	while CNDT[n] and CNDT[n]:IsShown() do
		n = n + 1
	end
	n = n - 1

	local tab = (CNDT.type == "icon" and IE.IconConditionTab) or IE.GroupConditionTab
	if n > 0 then
		tab:SetText((CNDT.invalid and "|TInterface\\AddOns\\TellMeWhen_Options\\Textures\\Alert:0:2|t|cFFFF0000" or "") .. L[CNDT.type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " |cFFFF5959(" .. n .. ")")
	else
		tab:SetText(L[CNDT.type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " (" .. n .. ")")
	end
	PanelTemplates_TabResize(tab, -6)
end

function CNDT:CreateGroups(num)
	local start = TELLMEWHEN_MAXCONDITIONS
	while CNDT[start] do
		start = start + 1
	end
	for i=start, num do
		local group = CNDT[i] or CreateFrame("Frame", "TellMeWhen_IconEditorConditionsGroupsGroup" .. i, TellMeWhen_IconEditor.Conditions.Groups, "TellMeWhen_ConditionGroup", i)
		for k, v in pairs(CNDT.AddIns) do
			group[k] = v
		end
		
		group:SetPoint("TOPLEFT", CNDT[i-1], "BOTTOMLEFT", 0, -16)
		group.AddDelete:ClearAllPoints()
		local p, _, rp, x, y = TMW.CNDT[1].AddDelete:GetPoint()
		group.AddDelete:SetPoint(p, CNDT[i], rp, x, y)
		group:Clear()
		group:SetTitles()
	end
	if num > TELLMEWHEN_MAXCONDITIONS then
		TELLMEWHEN_MAXCONDITIONS = num
	end
end

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

	local tab = (CNDT.type == "icon" and IE.IconConditionTab) or IE.GroupConditionTab
	if n > 0 then
		tab:SetText((CNDT.invalid and "|TInterface\\AddOns\\TellMeWhen_Options\\Textures\\Alert:0:2|t|cFFFF0000" or "") .. L[CNDT.type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " |cFFFF5959(" .. n .. ")")
	else
		tab:SetText(L[CNDT.type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " (" .. n .. ")")
	end
	PanelTemplates_TabResize(tab, -6)
end

function CNDT:OK()
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
		IE:ScheduleIconUpdate(groupID, iconID)
	elseif CNDT.type == "group" then
		TMW:Group_Update(groupID)
	end
end

function CNDT:Load()
	local Conditions = CNDT.settings
	IE.Conditions.Warning:SetText(nil)

	if Conditions and #Conditions > 0 then
		for i = #Conditions, TELLMEWHEN_MAXCONDITIONS do
			CNDT[i]:Clear()
		end
		CNDT:CreateGroups(#Conditions+1)

		for i=1, #Conditions do
			CNDT[i]:Load()
		end
	else
		CNDT:ClearDialog()
	end
	CNDT:AddRemoveHandler()
end

function CNDT:ClearDialog()
	for i=1, TELLMEWHEN_MAXCONDITIONS do
		CNDT[i]:Clear()
		CNDT[i]:SetTitles()
	end
	CNDT:AddRemoveHandler()
end

CNDT.AddIns = {}
local AddIns = CNDT.AddIns

function AddIns.TypeCheck(group, data)
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
				TMW:TT(group.EditBox, nil, nil, nil, nil, 1)
			end
			if data.check then
				data.check(group.Check)
				group.Check:Show()
			else
				group.Check:Hide()
			end
			SUG:EnableEditbox(group.EditBox, data.useSUG, true)
			
			group.Slider:SetWidth(200)
			if data.noslide then
				group.EditBox:SetWidth(520)
			else
				group.EditBox:SetWidth(312)
			end
		else
			group.EditBox:Hide()
			group.Check:Hide()
			group.Slider:SetWidth(523)
			SUG:DisableEditbox(group.EditBox)
		end
		if data.name2 then
			group.EditBox2:Show()
			if type(data.name2) == "function" then
				data.name2(group.EditBox2)
				group.EditBox2:GetScript("OnTextChanged")(group.EditBox2)
			else
				TMW:TT(group.EditBox2, nil, nil, nil, nil, 1)
			end
			if data.check2 then
				data.check2(group.Check2)
				group.Check2:Show()
			else
				group.Check2:Hide()
			end
			SUG:EnableEditbox(group.EditBox2, data.useSUG, true)
			group.EditBox:SetWidth(250)
			group.EditBox2:SetWidth(250)
		else
			group.Check2:Hide()
			group.EditBox2:Hide()
			SUG:DisableEditbox(group.EditBox2)
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

function AddIns.Save(group)
	local condition = CNDT.settings[group:GetID()]
	
	condition.Type = UIDropDownMenu_GetSelectedValue(group.Type) or "HEALTH"
	condition.Unit = strtrim(group.Unit:GetText()) or "player"
	condition.Operator = UIDropDownMenu_GetSelectedValue(group.Operator) or "=="
	condition.Icon = UIDropDownMenu_GetSelectedValue(group.Icon) or ""
	condition.Level = tonumber(group.Slider:GetValue()) or 0
	condition.AndOr = group.And:GetChecked() and "AND" or "OR"
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

function AddIns.Load(group)

	local condition = CNDT.settings[group:GetID()]
	local data = CNDT.ConditionsByType[condition.Type]

	UIDropDownMenu_SetSelectedValue(group.Type, condition.Type)
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
		TMW:TT(group.Operator, v.tooltipText, nil, 1, nil, 1)
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

	group.And:SetChecked(condition.AndOr == "AND")
	group.Or:SetChecked(condition.AndOr == "OR")

	group:Show()

end

function AddIns.Clear(group)
	group.Unit:SetText("player")
	group.EditBox:SetText("")
	group.EditBox2:SetText("")
	group.Check:SetChecked(nil)
	group.Check2:SetChecked(nil)
	if group.Icon.selectedValue ~= "" then
		UIDropDownMenu_SetSelectedValue(group.Icon, "")
	end
	TMW:SetUIDropdownText(group.Type, "HEALTH", CNDT.Types)
	TMW:SetUIDropdownText(group.Operator, "==", CNDT.Operators)
	group.And:SetChecked(1)
	group.Or:SetChecked(nil)
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

function AddIns.SetValText(group)
	if TMW.Initd and group.ValText then
		local val = group.Slider:GetValue()
		local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
		if v then
			group.ValText:SetText(get(v.texttable, val) or val)
		end
	end
end

function AddIns.UpOrDown(group, delta)
	local ID = group:GetID()
	local settings = CNDT.settings
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	CNDT:Load()
end

function AddIns.AddDeleteHandler(group)
	if group:IsShown() then
		tremove(CNDT.settings, group:GetID())
	else
		local condition = CNDT.settings[group:GetID()] -- cheesy way to invoke the metamethod and create a new condition table
	end
	CNDT:AddRemoveHandler()
	CNDT:Load()
end

function AddIns.SetTitles(group)
	if not group.TextType then return end
	group.TextType:SetText(L["CONDITIONPANEL_TYPE"])
	group.TextUnitOrIcon:SetText(L["CONDITIONPANEL_UNIT"])
	group.TextUnitDef:SetText("")
	group.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
	group.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
end

function AddIns.SetSliderMinMax(group, level)
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
		_G[Slider:GetName() .. "Low"]:SetText(get(v.texttable, newmin) or newmin)
		_G[Slider:GetName() .. "Mid"]:SetText(nil)
		_G[Slider:GetName() .. "High"]:SetText(get(v.texttable, newmax) or newmax)
	else
		Slider:SetMinMaxValues(vmin or 0, vmax or 1)
		_G[Slider:GetName() .. "Low"]:SetText(get(v.texttable, vmin) or v.mint or vmin or 0)
		_G[Slider:GetName() .. "Mid"]:SetText(v.midt)
		_G[Slider:GetName() .. "High"]:SetText(get(v.texttable, vmax) or v.maxt or vmax or 1)
	end
	Slider.step = v.step or 1
	Slider:SetValueStep(Slider.step)
	if level then
		Slider:SetValue(level)
	end
end








