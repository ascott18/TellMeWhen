-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

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
local _, pclass = UnitClass("Player")
local GetSpellInfo, GetContainerItemID, GetContainerItemLink =
	  GetSpellInfo, GetContainerItemID, GetContainerItemLink
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe
local strfind, strmatch, format, gsub, strsub, strtrim, max =
	  strfind, strmatch, format, gsub, strsub, strtrim, max
local _G, GetTime = _G, GetTime
local tiptemp = {}
local ME, CNDT, IE, SUG
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
TMW.CI = {}		--current icon

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
	local metatemp = getmetatable(src) -- lets not go overwriting random metatables
	setmetatable(src, getmetatable(dest))
	for k in pairs(src) do
		if dest[k] and type(dest[k]) == "table" and type(src[k]) == "table" then
			TMW:CopyTableInPlace(src[k], dest[k])
		elseif type(src[k]) ~= "table" then
			dest[k] = src[k]
		end
	end
	setmetatable(src, metatemp) -- restore the old metatable
	return dest -- not really needed, but what the hell why not
end

local function GetLocalizedSettingString(setting, value)
	if not value or not setting then return end
	for k, v in pairs(IE.Data[setting]) do
		if v.value == value then
			return v.text
		end
	end
end

function TMW:GetIconMenuText(g, i, data)
	data = data or db.profile.Groups[tonumber(g)].Icons[tonumber(i)]

	local text = data.Name or ""
	if data.Type == "wpnenchant" then
		if data.WpnEnchantType == "MainHandSlot" then text = INVTYPE_WEAPONMAINHAND
		elseif data.WpnEnchantType == "SecondaryHandSlot" then text = INVTYPE_WEAPONOFFHAND
		elseif data.WpnEnchantType == "RangedSlot" then text = INVTYPE_THROWN end
		text = text .. " ((" .. L["ICONMENU_WPNENCHANT"] .. "))"
	elseif data.Type == "meta" then
		text = "((" .. L["ICONMENU_META"] .. "))"
	elseif data.Type == "cast" and text == "" then
		text = "((" .. L["ICONMENU_CAST"] .. "))"
	end
	local textshort = strsub(text, 1, 35)
	if strlen(text) > 35 then textshort = textshort .. "..." end
	return text, textshort
end

function TMW:GuessIconTexture(data)
	local tex = nil
	if (data.Name and data.Name ~= "" and data.Type ~= "meta" and data.Type ~= "wpnenchant") and not tex then
		local name = TMW:GetSpellNames(nil, data.Name, 1)
		if name then
			tex = GetSpellTexture(name)
			if data.Type == "cooldown" and data.CooldownType == "item" then
				tex = GetItemIcon(name) or tex
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
		return L["GROUP"] .. g
	end
	if short then return n .. " (" .. g .. ")" end
	return n .. " (" .. L["GROUP"] .. g .. ")"
end


-- --------------
-- MAIN OPTIONS
-- --------------
--[[
local coloroption = {
	name = function(info) return L[info[#info] ] end,
    desc = function(info) return L[info[#info] .. "_DESC"] end,
    type = "color",
	order = function(info) return #info end,
	set = function(info, r, g, b)
		local c = db.profile.Groups[tonumber(info[#info - 2])].Color[info[#info] ]
		c.r = r
		c.g = g
		c.b = b
		c.a = a
		--TMW:ColorUpdate()
	end,
	get = function(info)
		local c = db.profile.Groups[tonumber(info[#info - 2])].Color[info[#info] ]
		return c.r, c.g, c.b, c.a
	end,
}	]]

local checkorder = {
	-- NOTE: these are actually backwards so they sort logically in AceConfig, but have their signs switched in the actual function.
	[-1] = L["ASCENDING"],
	[1] = L["DESCENDING"],
}
local groupConfigTemplate = {
	type = "group",
	name = function(info) return TMW:GetGroupName(db.profile.Groups[tonumber(info[2])].Name, tonumber(info[2])) end,
	order = function(info) return tonumber(info[2]) end,
--		childGroups = "tab",
	args = {
	--[[	Main = {
			type = "group",
			order = 1,
			name = "MAIN",
			args = {]]
				Name = {
					name = L["UIPANEL_GROUPNAME"],
					type = "input",
					order = 1,
					set = function(info, val)
						db.profile.Groups[tonumber(info[2])].Name = strtrim(val)
						TMW:Group_Update(tonumber(info[2]))
					end,
				},
				Enabled = {
					name = L["UIPANEL_ENABLEGROUP"],
					desc = L["UIPANEL_TOOLTIP_ENABLEGROUP"],
					type = "toggle",
					order = 2,
				},
				OnlyInCombat = {
					name = L["UIPANEL_ONLYINCOMBAT"],
					desc = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"],
					type = "toggle",
					order = 3,
				},
				NotInVehicle = {
					name = L["UIPANEL_NOTINVEHICLE"],
					desc = L["UIPANEL_TOOLTIP_NOTINVEHICLE"],
					type = "toggle",
					order = 4,
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
						TMW:Group_OnDelete(tonumber(info[2]))
					end,
					confirm = true,
			--[[	},
			},]]
		},
		position = {
			type = "group",
			order = 40,
			name = L["UIPANEL_POSITION"],
			guiInline = true,
			dialogInline = true,
			set = function(info, val)
				db.profile.Groups[tonumber(info[2])].Point[info[#info]] = val
				TMW:Group_SetPos(tonumber(info[2]))
			end,
			get = function(info) return db.profile.Groups[tonumber(info[2])].Point[info[#info]] end,
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
					bigStep = 0.05,
					set = function(info, val)
						db.profile.Groups[tonumber(info[2])].Scale = val
						TMW:Group_SetPos(tonumber(info[2]))
					end,
					get = function(info) return db.profile.Groups[tonumber(info[2])].Scale end,
				},
				level = {
					name = L["UIPANEL_LEVEL"],
					type = "range",
					order = 7,
					min = 1,
					softMax = 100,
					step = 1,
					set = function(info, val)
						db.profile.Groups[tonumber(info[2])].Level = val
						TMW:Group_SetPos(tonumber(info[2]))
					end,
					get = function(info) return db.profile.Groups[tonumber(info[2])].Level end,
				},
				lock = {
					name = L["UIPANEL_LOCK"],
					desc = L["UIPANEL_LOCK_DESC"],
					type = "toggle",
					order = 11,
					set = function(info, val)
						db.profile.Groups[tonumber(info[2])].Locked = val
						TMW:Group_Update(tonumber(info[2]))
					end,
					get = function(info) return db.profile.Groups[tonumber(info[2])].Locked end
				},
				reset = {
					name = L["UIPANEL_GROUPRESET"],
					desc = L["UIPANEL_TOOLTIP_GROUPRESET"],
					type = "execute",
					order = 12,
					func = function(info) TMW:Group_ResetPosition(tonumber(info[2])) end
				},
			},
		},
	}
}
for i = 1, GetNumTalentTabs() do
	local _, name = GetTalentTabInfo(i)
	groupConfigTemplate.args["Tree"..i] = {
		type = "toggle",
		name = name,
		desc = L["UIPANEL_TREE_DESC"],
		order = 7+i,
	}
end
if #(TMW.CSN) > 0 then 		-- 	[0] (NONE) doesnt factor into the length
	groupConfigTemplate.args.stance = {
		type = "multiselect",
		name = L["UIPANEL_STANCE"],
		order = 30,
		values = TMW.CSN,
		set = function(info, key, val)
			db.profile.Groups[tonumber(info[2])].Stance[TMW.CSN[key]] = val
			TMW:Group_Update(tonumber(info[2]))
		end,
		get = function(info, key)
			return db.profile.Groups[tonumber(info[2])].Stance[TMW.CSN[key]]
		end,
	}
end

function TMW:CompileOptions() -- options
	if not TMW.InitializedOptions then
		TMW.OptionsTable = {
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
						header = {
							name = L["ICON_TOOLTIP1"] .. " " .. TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR,
							type = "header",
							order = 1,
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
						addgroup = {
							name = L["UIPANEL_ADDGROUP"],
							desc = L["UIPANEL_ADDGROUP_DESC"],
							type = "execute",
							order = 41,
							func = function()
								db.profile.NumGroups = db.profile.NumGroups + 1
								db.profile.Groups[db.profile.NumGroups].LBF = TMW:CopyWithMetatable(db.profile.Groups[db.profile.NumGroups-1].LBF)
								db.profile.Groups[db.profile.NumGroups].Enabled = true
								TMW:Update()
								TMW:CompileOptions()
							end,
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
						countfont = {
							type = "group",
							name = L["UIPANEL_FONT"],
							order = 4,
							set = function(info, val)
								db.profile.Font[info[#info]] = val
								TMW:Update()
							end,
							get = function(info) return db.profile.Font[info[#info]] end,
							args = {
								Name = {
									name = L["UIPANEL_FONT"],
									desc = L["UIPANEL_FONT_DESC"],
									type = "select",
									order = 3,
									dialogControl = 'LSM30_Font',
									values = LSM:HashTable("font"),
								},
								Size = {
									name = L["UIPANEL_FONT_SIZE"],
									desc = L["UIPANEL_FONT_SIZE_DESC"],
									type = "range",
									order = 10,
									min = 6,
									max = 26,
									step = 1,
									bigStep = 1,
								},
								Outline = {
									name = L["UIPANEL_FONT_OUTLINE"],
									desc = L["UIPANEL_FONT_OUTLINE_DESC"],
									type = "select",
									values = {
										MONOCHROME = L["OUTLINE_NO"],
										OUTLINE = L["OUTLINE_THIN"],
										THICKOUTLINE = L["OUTLINE_THICK"],
									},
									style = "dropdown",
									order = 11,
								},
								OverrideLBFPos = {
									name = L["UIPANEL_FONT_OVERRIDELBF"],
									desc = L["UIPANEL_FONT_OVERRIDELBF_DESC"],
									type = "toggle",
									order = 20,
								},
								x = {
									name = L["UIPANEL_FONT_XOFFS"],
									type = "range",
									order = 21,
									min = -30,
									max = 10,
									step = 1,
									bigStep = 1,
								},
								y = {
									name = L["UIPANEL_FONT_YOFFS"],
									type = "range",
									order = 22,
									min = -10,
									max = 30,
									step = 1,
									bigStep = 1,
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
						db.profile.Groups[tonumber(info[2])][info[#info]] = val
						TMW:Group_Update(tonumber(info[2]))
					end,
					get = function(info) return db.profile.Groups[tonumber(info[2])][info[#info]] end,
					args = {},
				},
			},
		}
		TMW.OptionsTable.args.groups.args.addgroup = TMW.OptionsTable.args.main.args.addgroup
		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
		TMW.InitializedOptions = true
	end


	for k, v in pairs(TMW.OptionsTable.args.groups.args) do
		if tonumber(k) then -- protect ["addgroup"] and any other future settings in the group header
			TMW.OptionsTable.args.groups.args[k] = nil
		end
	end

	for g = 1, TELLMEWHEN_MAXGROUPS do
		TMW.OptionsTable.args.groups.args[tostring(g)] = groupConfigTemplate
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("TellMeWhen Options", TMW.OptionsTable)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("TellMeWhen Options", 802, 400)
	if not TMW.AddedToBlizz then
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TellMeWhen Options", L["ICON_TOOLTIP1"])
		TMW.AddedToBlizz = true
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("TellMeWhen Options")
	end
end


-- -------------
-- GROUP CONFIG
-- -------------

local function Group_SizeUpdate(self)
	local uiScale = UIParent:GetScale()
	local group = self:GetParent()
	local cursorX, cursorY = GetCursorPosition(UIParent)

	-- calculate new scale
	local newXScale = group.oldScale * (cursorX/uiScale - group.oldX*group.oldScale) / (self.oldCursorX/uiScale - group.oldX*group.oldScale)
	local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (self.oldCursorY/uiScale - group.oldY*group.oldScale)
	local newScale = max(0.6, newXScale, newYScale)
	group:SetScale(newScale)

	-- calculate new frame position
	local newX = group.oldX * group.oldScale / newScale
	local newY = group.oldY * group.oldScale / newScale
	group:ClearAllPoints()
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
end

function TMW:Group_StartSizing(self)
	local group = self:GetParent()
	group.oldScale = group:GetScale()
	self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent)
	group.oldX = group:GetLeft()
	group.oldY = group:GetTop()
	self:SetScript("OnUpdate", Group_SizeUpdate)
end

function TMW:Group_StopSizing(self)
	self:SetScript("OnUpdate", nil)
	local group = self:GetParent()
	db.profile.Groups[group:GetID()]["Scale"] = group:GetScale()
	local p = db.profile.Groups[group:GetID()]["Point"]
	p.point, p.relativeTo, p.relativePoint, p.x, p.y = group:GetPoint(1)
	p.relativeTo = p.relativeTo and p.relativeTo:GetName() or "UIParent"
	p.defined = true
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TellMeWhen Options")
end

function TMW:Group_StopMoving(self)
	local group = self:GetParent()
	group:StopMovingOrSizing()
	local p = db.profile.Groups[group:GetID()]["Point"]
	p.point, p.relativeTo, p.relativePoint, p.x, p.y = group:GetPoint(1)
	p.relativeTo = p.relativeTo and p.relativeTo.GetName and p.relativeTo:GetName() or "UIParent"
	p.defined = true
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TellMeWhen Options")
end

function TMW:Group_ResetPosition(groupID)
	db.profile.Groups[groupID].Point.defined = false
	db.profile.Groups[groupID].Scale = 2.0
	db.profile.Groups[groupID].Level = 10
	LibStub("AceConfigRegistry-3.0"):NotifyChange("TellMeWhen Options")
	TMW:Group_Update(groupID)
end

function TMW:Group_OnDelete(groupID)
	tremove(db.profile.Groups, groupID)
	local warntext = ""
	for gID in pairs(db.profile.Groups) do
		for iID in pairs(db.profile.Groups[gID].Icons) do
			if db.profile.Groups[gID].Icons[iID].Conditions then
				for k, v in ipairs(db.profile.Groups[gID].Icons[iID].Conditions) do
					if v.Icon ~= "" and v.Type == "ICON" then
						local g = tonumber(strmatch(v.Icon, "TellMeWhen_Group(%d+)_Icon"))
						if g > groupID then
							db.profile.Groups[gID].Icons[iID].Conditions[k].Icon = gsub(v.Icon, "_Group" .. g, "_Group" .. g-1)
						elseif g == groupID then
							warntext = warntext .. format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[gID].Name, gID, 1), iID) .. ", "
						end
					end
				end
			end
			if db.profile.Groups[gID].Icons[iID].Type == "meta" then
				for k, v in pairs(db.profile.Groups[gID].Icons[iID].Icons) do
					if v ~= "" then
						local g =  tonumber(strmatch(v, "TellMeWhen_Group(%d+)_Icon"))
						if g > groupID then
							db.profile.Groups[gID].Icons[iID].Icons[k] = gsub(v, "_Group" .. g, "_Group" .. g-1)
						elseif g == groupID then
							warntext = warntext .. format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[gID].Name, gID, 1), iID) .. ", "
						end
					end
				end
			end
		end
	end
	if warntext ~= "" then
		TMW:Print(warntext)
	end
	db.profile.NumGroups = db.profile.NumGroups - 1
	for k, v in pairs(TMW.Icons) do
		if tonumber(strmatch(v, "TellMeWhen_Group(%d+)_Icon")) == groupID then
			tremove(TMW.Icons, k)
		end
	end
	sort(TMW.Icons, function(a, b) return TMW:GetGlobalIconID(strmatch(a, "TellMeWhen_Group(%d+)_Icon(%d+)")) < TMW:GetGlobalIconID(strmatch(b, "TellMeWhen_Group(%d+)_Icon(%d+)")) end)
	TMW:Update()
	TMW:CompileOptions()
	CloseDropDownMenus()
end


-- ----------------------
-- ICON DRAGGER
-- ----------------------

ID = TMW:NewModule("IconDragger", "AceTimer-3.0", "AceEvent-3.0") TMW.ID = ID

--dragging stuff
function ID:BAR_HIDEGRID() ID.DraggingInfo = nil end
hooksecurefunc("PickupSpellBookItem", function(...) ID.DraggingInfo = {...} end)
WorldFrame:HookScript("OnMouseDown", ID.BAR_HIDEGRID)
hooksecurefunc("ClearCursor", ID.BAR_HIDEGRID)
ID:RegisterEvent("PET_BAR_HIDEGRID", "BAR_HIDEGRID")
ID:RegisterEvent("ACTIONBAR_HIDEGRID", "BAR_HIDEGRID")

function ID:Drag_DropDown(a)
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_MOVEHERE"]
	info.notCheckable = true
	info.func = ID.Move
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_COPYHERE"]
	info.func = ID.Copy
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_SWAPWITH"]
	info.func = ID.Swap
	UIDropDownMenu_AddButton(info)

	if TMW.tContains(TMW.Icons, ID.srcicon:GetName()) then
		info.text = L["ICONMENU_APPENDCONDT"]
		info.func = ID.Condition
		UIDropDownMenu_AddButton(info)
	end

	if ID.desticon.Type == "meta" then
		info.text = L["ICONMENU_ADDMETA"]
		info.func = ID.Meta
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


-- ----------------------
-- ICON EDITOR
-- ----------------------


ME = TMW:NewModule("MetaEditor") TMW.ME = ME -- really part of the icon editor now, but im too lazy to move it over

function ME:UpOrDown(self, delta)
	local groupID, iconID = TMW.CI.g, TMW.CI.i
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
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID].Icons = db.profile.Groups[groupID].Icons[iconID].Icons or {}
	if not db.profile.Groups[groupID].Icons[iconID].Icons[1] then
		db.profile.Groups[groupID].Icons[iconID].Icons[1] = TMW.Icons[1]
		UIDropDownMenu_SetSelectedValue(TellMeWhen_MetaEditorGroup1.icon, TMW.Icons[1])
		UIDropDownMenu_SetText(TellMeWhen_MetaEditorGroup1.icon, TMW.Icons[1])
	end
	tinsert(db.profile.Groups[groupID].Icons[iconID].Icons, where, TMW.Icons[1])
	ME:Update()
end

function ME:Delete(self)
	tremove(db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].Icons, self:GetParent():GetID())
	ME:Update()
end

function ME:Update()
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID].Icons = db.profile.Groups[groupID].Icons[iconID].Icons or {}
	local settings = db.profile.Groups[groupID].Icons[iconID].Icons
	local i=1
	UIDropDownMenu_SetSelectedValue(ME[1].icon, nil)
	UIDropDownMenu_SetText(ME[1].icon, "")
	while ME[i] do
		ME[i].up:Show()
		ME[i].down:Show()
		ME[i]:Show()
		i=i+1
	end
	i=i-1 -- i is always the number of groups plus 1
	ME[1].up:Hide()
	ME[1].delete:Hide()

	for k, v in pairs(settings) do
		local mg = ME[k] or CreateFrame("Frame", "TellMeWhen_MetaEditorGroup" .. k, TellMeWhen_IconEditor.Main.Icons, "TellMeWhen_MetaEditorGroup", k)
		ME[k] = mg
		mg:Show()
		if k > 1 then
			mg:SetPoint("TOP", ME[k-1], "BOTTOM", 0, 0)
		end
		mg:SetFrameLevel(TellMeWhen_IconEditor.Main.Icons:GetFrameLevel()+1)
		UIDropDownMenu_SetSelectedValue(mg.icon, v)
		local text = TMW:GetIconMenuText(strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)"))
		UIDropDownMenu_SetText(mg.icon, text)
	end
	for f=#settings+1, i do
		ME[f]:Hide()
	end
	if settings[1] then
		ME[#settings].down:Hide()
		ME[1].delete:Hide()
	else
		ME[1].down:Hide()
	end
	if settings[2] then
		ME[1].delete:Show()
	end
	ME[1]:Show()
end

function ME:IconMenu()
	for k, v in pairs(TMW.Icons) do
		if TMW.CI.ic and v ~= TMW.CI.ic:GetName() then
			local info = UIDropDownMenu_CreateInfo()
			info.func = ME.IconMenuOnClick
			local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
			g, i = tonumber(g), tonumber(i)
			local text, textshort = TMW:GetIconMenuText(g, i)
			info.text = textshort
			info.value = v
			info.tooltipTitle = text
			info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[g].Name, g, 1), i)
			info.tooltipOnButton = true
			info.icon = _G["TellMeWhen_Group" .. g .. "_Icon" .. i].texture:GetTexture()
			info.arg1 = self
			UIDropDownMenu_AddButton(info)
		end
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function ME:IconMenuOnClick(frame)
	db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].Icons[frame:GetParent():GetID()] = self.value
	UIDropDownMenu_SetSelectedValue(frame, self.value)
end


IE = TMW:NewModule("IconEditor", "AceEvent-3.0") TMW.IE = IE
local set1 = {
	cooldown = "CooldownType",
	buff = "BuffOrDebuff",
	wpnenchant = "WpnEnchantType",
	totem = "TotemSlots",
	icd = "ICDType",
}
local set2 = {
	cooldown = "CooldownShowWhen",
	buff = "BuffShowWhen",
	reactive = "CooldownShowWhen",
	wpnenchant = "BuffShowWhen",
	totem = "BuffShowWhen",
	unitcooldown = "CooldownShowWhen",
	icd = "CooldownShowWhen",
	cast = "BuffShowWhen",
	meta = nil,
}
local checks = { --1=check box, 2=editbox, 3=slider(x100), 4=custom, table=subkeys are settings
	Name = 2,
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
	ICDDuration = 2,
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
	FakeHidden = 1,
}
local tabs = {
	[1] = "Main",
	[2] = "Conditions",
	[3] = "Group",
	--[4] = "ImpExp",
}

IE.Data = {
	-- the keys on this table need to match the settings variable names
	Type = {}, -- this will be populated by registered icon types
	CooldownType = {
		text = L["ICONMENU_COOLDOWNTYPE"],
		{ value = "spell", 			text = L["ICONMENU_SPELL"] },
		{ value = "multistate", 	text = L["ICONMENU_MULTISTATECD"], 		tooltipText = L["ICONMENU_MULTISTATECD_DESC"] },
		{ value = "item", 			text = L["ICONMENU_ITEM"] },
	},
	ICDType = {
		text = L["ICONMENU_ICDTYPE"],
		{ value = "aura", 			text = L["ICONMENU_ICDBDE"], 			tooltipText = L["ICONMENU_ICDAURA_DESC"]},
		{ value = "spellcast", 		text = L["ICONMENU_SPELLCAST"], 		tooltipText = L["ICONMENU_SPELLCAST_DESC"]},
	},
	WpnEnchantType = {
		text = L["ICONMENU_WPNENCHANTTYPE"],
		{ value = "MainHandSlot",	text = INVTYPE_WEAPONMAINHAND },
		{ value = "SecondaryHandSlot", text = INVTYPE_WEAPONOFFHAND },
		{ value = "RangedSlot",		text = INVTYPE_THROWN },
	},
	BuffOrDebuff = {
		text = L["ICONMENU_BUFFTYPE"],
		{ value = "HELPFUL", 		text = L["ICONMENU_BUFF"], 				colorCode = "|cFF00FF00" },
		{ value = "HARMFUL", 		text = L["ICONMENU_DEBUFF"], 			colorCode = "|cFFFF0000" },
		{ value = "EITHER", 		text = L["ICONMENU_BOTH"] },
	},

	BuffShowWhen = {
		text = L["ICONMENU_SHOWWHEN"],
		{ value = "present", 		text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
		{ value = "absent", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
		{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
	},
	CooldownShowWhen = {
		text = L["ICONMENU_SHOWWHEN"],
		{ value = "usable", 		text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
		{ value = "unusable", 		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
		{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
	},
	ICDShowWhen = {
		{ value = "usable", 		text = L["ICONMENU_ICDUSABLE"], },
		{ value = "unusable", 		text = L["ICONMENU_ICDUNUSABLE"], },
		{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
	},

	Unit = {
		{ value = "player", 					text = PLAYER },
		{ value = "target", 					text = TARGET },
		{ value = "targettarget", 				text = L["ICONMENU_TARGETTARGET"] },
		{ value = "focus", 						text = FOCUS },
		{ value = "focustarget", 				text = L["ICONMENU_FOCUSTARGET"] },
		{ value = "pet", 						text = PET },
		{ value = "pettarget", 					text = L["ICONMENU_PETTARGET"] },
		{ value = "mouseover", 					text = L["ICONMENU_MOUSEOVER"] },
		{ value = "mouseovertarget",			text = L["ICONMENU_MOUSEOVERTARGET"]  },
		{ value = "vehicle", 					text = L["ICONMENU_VEHICLE"] },
		{ value = "party|cFFFF0000#|r", 		text = PARTY, 			range = "|cFFFF0000#|r = 1-" .. MAX_PARTY_MEMBERS .. " (4)" },
		{ value = "raid|cFFFF0000#|r", 			text = RAID, 			range = "|cFFFF0000#|r = 1-" .. MAX_RAID_MEMBERS .. " (25)"  },
		{ value = "arena|cFFFF0000#|r",			text = ARENA, 			range = "|cFFFF0000#|r = 1-5" .. " (5)"   },
		{ value = "boss|cFFFF0000#|r", 			text = BOSS, 			range = "|cFFFF0000#|r = 1-" .. MAX_BOSS_FRAMES .. " (4)"   },
		{ value = "maintank|cFFFF0000#|r", 		text = L["MAINTANK"], 	range = "|cFFFF0000#|r = 1-" .. MAX_RAID_MEMBERS .. " (5)"   },
		{ value = "mainassist|cFFFF0000#|r", 	text = L["MAINASSIST"], range = "|cFFFF0000#|r = 1-" .. MAX_RAID_MEMBERS .. " (5)"   },
	},
}
for k, Type in pairs(TMW.OrderedTypes) do
	local data = TMW.Types[Type]
	IE.Data.Type[k] = {value = Type, text = data.name, tooltipText = data.desc}
end
if pclass == "SHAMAN" then
	IE.Data.TotemSlots = {
		text = L["TOTEMS"],
		{ text = L["FIRE"] },
		{ text = L["EARTH"] },
		{ text = L["WATER"] },
		{ text = L["AIR"] },
	}
elseif pclass == "DRUID" then
	IE.Data.TotemSlots = {
		text = L["MUSHROOMS"],
		{ text = format(L["MUSHROOM"], 1) },
		{ text = format(L["MUSHROOM"], 2) },
		{ text = format(L["MUSHROOM"], 3) },
	}
end

function IE:TabClick(self)
	PanelTemplates_Tab_OnClick(self, self:GetParent())
	PlaySound("igCharacterInfoTab")
	for id, frame in pairs(tabs) do
		if IE[frame] then
			IE[frame]:Hide()
		end
	end
	IE[tabs[self:GetID()]]:Show()
	TellMeWhen_IconEditor:Show()
end

function IE:SetupRadios()
	local t = TMW.CI.t

	if set1[t] and IE.Data[set1[t]] then
		for k, frame in pairs(IE.Main.TypeChecks) do
			if strfind(k, "Radio") then
				local info = IE.Data[set1[t]][frame:GetID()]
				if pclass == "SHAMAN" and set1[t] == "TotemSlots" and frame:GetID() > 1 then
					local p, rt, rp, x, y = frame:GetPoint(1)
					frame:SetPoint(p, rt, rp, x, 10)
				elseif frame:GetID() > 1 then
					local p, rt, rp, x, y = frame:GetPoint(1)
					frame:SetPoint(p, rt, rp, x, 4)
				end
				if info then
					frame:Show()
					frame.setting = set1[t]
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
		IE.Main.TypeChecks.text:SetText(IE.Data[set1[t]].text)
	else
		IE.Main.TypeChecks:Hide()
	end
	if set2[t] then
		for k, frame in pairs(IE.Main.WhenChecks) do
			if strfind(k, "Radio") then
				local info = IE.Data[set2[t]][frame:GetID()]
				if info then
					frame:Show()
					frame.setting = set2[t]
					frame.value = info.value
					if t == "icd" then
						info = IE.Data.ICDShowWhen[frame:GetID()]
					end
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
		if t == "cast" then
			IE.Main.WhenChecks.text:SetText(L["ICONMENU_CASTSHOWWHEN"])
		else
			IE.Main.WhenChecks.text:SetText(IE.Data[set2[t]].text)
		end
		IE.Main.WhenChecks:Show()
	else
		IE.Main.WhenChecks:Hide()
	end
	local alphainfo
	if t == "icd" then
		alphainfo = IE.Data.ICDShowWhen
	elseif set2[t] then
		alphainfo = IE.Data[set2[t]]
	end
	if alphainfo then
		IE.Main.Alpha.text:SetText((alphainfo[1].colorCode or "") .. alphainfo[1].text .. "|r")
		IE.Main.UnAlpha.text:SetText((alphainfo[2].colorCode or "") .. alphainfo[2].text .. "|r")
	else
		IE.Main.Alpha.text:SetText(L["ICONMENU_USABLE"])
		IE.Main.UnAlpha.text:SetText(L["ICONMENU_UNUSABLE"])
	end
end

function IE:ShowHide()
	local t = TMW.CI.t
	if not t then return end

	local ICDDuration = IE.Main.ICDDuration
	if t == "icd" then
		TMW:TT(ICDDuration, "CHOOSENAME_DIALOG_ICD", "CHOOSENAME_DIALOG_ICD_DESC", nil, nil, 1)
		ICDDuration.label = TMW.L["CHOOSENAME_DIALOG_ICD"]
	elseif t == "unitcooldown" then
		TMW:TT(ICDDuration, "ICONMENU_COOLDOWN", "CHOOSENAME_DIALOG_UCD_DESC", nil, nil, 1)
		ICDDuration.label = TMW.L["ICONMENU_COOLDOWN"]
	end

	for k, v in pairs(checks) do
		if (TMW.RelevantSettings[t] and TMW.RelevantSettings[t][k]) or TMW.RelevantSettings.all[k] then
			IE.Main[k]:Show()
			if IE.Main[k].SetEnabled then
				IE.Main[k]:SetEnabled(1)
			end
		else
			IE.Main[k]:Hide()
		end
	end
	local spb = IE.Main.ShowPBar
	local scb = IE.Main.ShowCBar
	if TMW.CI.t == "cooldown" and IE.Main.TypeChecks.Radio3:GetChecked() and IE.Main.TypeChecks.Radio3.value == "item" then
		TMW.CI.SoI = "item"
	else
		if TMW.CI.t == "cooldown" and IE.Main.TypeChecks.Radio2:GetChecked() and IE.Main.TypeChecks.Radio2.value == "multistate" then
			TMW.CI.IsMultiState = true
		else
			TMW.CI.IsMultiState = nil
		end
		TMW.CI.SoI = "spell"
	end
	if TMW.CI.SoI == "item" then
		spb:SetEnabled(nil)
		scb:SetEnabled(1)
		IE.Main.OnlyEquipped:Show()
		IE.Main.OnlyInBags:Show()
		IE.Main.ManaCheck:Hide()
	elseif t == "cooldown" then
		IE.Main.OnlyEquipped:Hide()
		IE.Main.OnlyInBags:Hide()
		IE.Main.ManaCheck:Show()
	end
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

	if t == "" or t == "meta" then -- override the previous shows and disables
		spb:Hide()
		scb:Hide()
		IE.Main.InvertBars:Hide()
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
		IE.Main.ICDDuration:ClearFocus()
	end
end

function IE:LoadSettings()
	local groupID, iconID = TMW.CI.g, TMW.CI.i

	for setting, settingtype in pairs(checks) do
		if settingtype == 1 then
			IE.Main[setting]:SetChecked(db.profile.Groups[groupID].Icons[iconID][setting])
			IE.Main[setting]:GetScript("OnClick")(IE.Main[setting])
		elseif settingtype == 2 then
			IE.Main[setting]:SetText(db.profile.Groups[groupID].Icons[iconID][setting])
			IE.Main[setting]:SetCursorPosition(0)
		elseif settingtype == 3 then
			IE.Main[setting]:SetValue(db.profile.Groups[groupID].Icons[iconID][setting]*100)
		elseif type(settingtype) == "table" then
			for subset, subtype in pairs(settingtype) do
				if subtype == 1 then
					IE.Main[setting][subset]:SetChecked(db.profile.Groups[groupID].Icons[iconID][subset])
				elseif subtype == 2 then
					IE.Main[setting][subset]:SetText(db.profile.Groups[groupID].Icons[iconID][subset])
					IE.Main[setting][subset]:SetCursorPosition(0)
				end
			end
		end
	end

	for _, parent in pairs({IE.Main.TypeChecks, IE.Main.WhenChecks}) do
		for k, frame in pairs(parent) do
			if strfind(k, "Radio") then
				if frame.setting == "TotemSlots" then
					frame:SetChecked(strsub(db.profile.Groups[groupID].Icons[iconID][frame.setting], frame:GetID(), frame:GetID()) == "1")
				else
					local checked = db.profile.Groups[groupID].Icons[iconID][frame.setting] == frame.value
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
	if (not TellMeWhen_IconEditor:IsShown() and not isRefresh) or (TellMeWhen_IconEditor.selectedTab == 2 and TMW.CI.t == "meta") then
		IE:TabClick(IE.MainTab)
	elseif not TellMeWhen_IconEditor:IsShown() and isRefresh then
		return
	end
	local groupID, iconID = TMW.CI.g, TMW.CI.i

	IE.Main.Name:ClearFocus()
	IE.Main.Unit:ClearFocus()
	TellMeWhen_IconEditor:SetScale(db.profile.EditorScale)

	UIDropDownMenu_SetSelectedValue(IE.Main.Type, db.profile.Groups[groupID].Icons[iconID].Type)
	TMW.CI.t = db.profile.Groups[groupID].Icons[iconID].Type
	if db.profile.Groups[groupID].Icons[iconID].Type == "" then
		UIDropDownMenu_SetText(IE.Main.Type, L["ICONMENU_TYPE"])
	else
		for k, v in pairs(IE.Data.Type) do
			if (v.value == db.profile.Groups[groupID].Icons[iconID].Type) then
				UIDropDownMenu_SetText(IE.Main.Type, v.text)
				break
			end
		end
	end

	ME:Update()
	CNDT:Load()

	IE:SetupRadios()
	IE:LoadSettings()
	IE:ShowHide()
end

function IE:Reset()
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID] = nil
	TMW:ScheduleIconUpdate(groupID, iconID)
	IE:Load()
	IE:TabClick(IE.MainTab)
end


function IE:Equiv_GenerateTips(equiv)
	local r = "" --tconcat doesnt allow me to exclude duplicates unless i make another garbage table, so lets just do this
	local tbl = TMW:SplitNames(TMW.NamesEquivLookup[equiv])
	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		if not name then
			if debug then
				error("INVALID ID FOUND: "..equiv..":"..v)
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

function IE:Equiv_DropDown()
	if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
		if TMW.BE[UIDROPDOWNMENU_MENU_VALUE] then
			for k, v in pairs(TMW.BE[UIDROPDOWNMENU_MENU_VALUE]) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = IE.Equiv_DropDown_OnClick
				info.text = L[k]
				info.tooltipTitle = k
				local text = IE:Equiv_GenerateTips(k)

				info.icon = GetSpellTexture(TMW.EquivIDLookup[k])
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
			for k, v in pairs(TMW.DS) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = IE.Equiv_DropDown_OnClick
				info.text = L[k]

				local first = strsplit(TMW.EquivIDLookup[k], ";")
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

	info.text = L["ICONMENU_DISPEL"]
	info.value = "dispel"
	UIDropDownMenu_AddButton(info)
end

function IE:Equiv_DropDown_OnClick(value)
	local e = TellMeWhen_IconEditor.Main.Name
	e:Insert(";" .. value .. ";")
	e:SetText(TMW:CleanString(e:GetText()))
	CloseDropDownMenus()
end

function IE:Type_DropDown()
	if not db then return end
	local groupID, iconID = TMW.CI.g, TMW.CI.i

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_TYPE"]
	info.value = ""
	info.checked = (info.value == db.profile.Groups[groupID].Icons[iconID].Type)
	info.func = IE.Type_Dropdown_OnClick
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	local info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.disabled = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	for k, v in pairs(IE.Data.Type) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v.text
		info.value = v.value
		if v.tooltipText then
			info.tooltipTitle = v.tooltipTitle or v.text
			info.tooltipText = v.tooltipText
			info.tooltipOnButton = true
		end
		info.checked = (info.value == db.profile.Groups[groupID].Icons[iconID].Type)
		info.func = function()
			db.profile.Groups[groupID].Icons[iconID].Type = v.value
			TMW:ScheduleIconUpdate(groupID, iconID)
			local DD = IE.Main.Type
			UIDropDownMenu_SetSelectedValue(DD, v.value)
			TMW.CI.t = v.value
			IE:SetupRadios()
			IE:LoadSettings()
			IE:ShowHide()
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end

function IE:Type_Dropdown_OnClick()
	db.profile.Groups[groupID].Icons[iconID].Type = ""
	TMW.CI.ic.texture:SetTexture(nil)
	TMW:ScheduleIconUpdate(groupID, iconID)
	UIDropDownMenu_SetSelectedValue(IE.Main.Type, "")
	TMW.CI.t = ""
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
	for k, v in pairs(IE.Data.Unit) do
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
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end

function IE:Unit_DropDown_OnClick()
	e:Insert(";" .. v.value .. ";")
	e:SetText(TMW:CleanString(e:GetText()))
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID].Unit = e:GetText()
	TMW:ScheduleIconUpdate(groupID, iconID)
	CloseDropDownMenus()
end

local deserialized = {}
function IE:Copy_DropDown()
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	local icon = TMW.CI.ic
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

		for k, v in pairs(TMW.Recieved) do -- deserialize recieved icons because we dont do it as they are recieved; AceSerializer is only embedded in _Options
			if type(k) == "string" and v then
				local success, tbl = TMW:Deserialize(k)
				if success and type(tbl) == "table" and tbl.Name and tbl.Type then -- checks to make sure that it is actually an icon because of my poor planning
					deserialized[tbl] = v
					TMW.Recieved[k] = false
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

		for profilename, profiletable in pairs(db.profiles) do
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
			for tbl, who in pairs(deserialized) do
				local info = UIDropDownMenu_CreateInfo()
				local text, textshort = TMW:GetIconMenuText(nil, nil, tbl)
				info.text = textshort
				info.value = tbl
				info.tooltipTitle = text
				info.tooltipText = who
				info.tooltipOnButton = true
				info.notCheckable = true
				info.icon = TMW:GuessIconTexture(tbl)
				info.func = function(self)
					local groupID, iconID = TMW.CI.g, TMW.CI.i
					TMW:CopyTableInPlace(self.value, db.profile.Groups[groupID].Icons[iconID])
					TMW:ScheduleIconUpdate(groupID, iconID)
					IE:Load(1)
					db.profile.HasImported = true
				end
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			return
		end
		for g, v in pairs(db.profiles[UIDROPDOWNMENU_MENU_VALUE].Groups) do
			if g <= (tonumber(db.profiles[UIDROPDOWNMENU_MENU_VALUE].NumGroups) or 10) then
				info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(db.profiles[UIDROPDOWNMENU_MENU_VALUE].Groups[g].Name, g)
				info.value = {profilename = UIDROPDOWNMENU_MENU_VALUE, groupid = g}
				info.hasArrow = true
				info.notCheckable = true
				info.tooltipTitle = L["COPYPANEL_GROUP"] .. g
				info.tooltipText = 	(L["UIPANEL_ROWS"] .. ": " .. (v.Rows or 1) .. "\r\n") ..
								L["UIPANEL_COLUMNS"] .. ": " .. (v.Columns or 4) ..
								(v.OnlyInCombat and "\r\n" .. L["UIPANEL_ONLYINCOMBAT"] or "") ..
								(v.NotInVehicle and "\r\n" .. L["UIPANEL_NOTINVEHICLE"] or "") ..
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

			TMW:CopyTableInPlace(db.profiles[n].Groups[g].Point, db.profile.Groups[groupID].Point)
			db.profile.Groups[groupID].Scale = db.profiles[n].Groups[g].Scale or TMW.Group_Defaults.Scale
			db.profile.Groups[groupID].Level = db.profiles[n].Groups[g].Level or TMW.Group_Defaults.Level

			TMW:Group_Update(groupID)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYALL"]
		info.func = function()
			local currentprofile = db:GetCurrentProfile()
			db:SetProfile(n)
			local temp = TMW:CopyWithMetatable(db.profile.Groups[g])
			db:SetProfile(currentprofile)
			wipe(db.profile.Groups[groupID])
			db.profile.Groups[groupID] = TMW:CopyWithMetatable(temp)
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
			for i, d in pairs(db.profiles[n].Groups[g].Icons) do
				local nsettings = 0
				for icondatakey, icondatadata in pairs(d) do
					if type(icondatadata) == "table" then if #icondatadata ~= 0 then nsettings = nsettings + 1 end
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

					info = UIDropDownMenu_CreateInfo()
					info.text = L["COPYICON"] .. i
					info.func = function()
						TMW:CopyTableInPlace(db.profiles[n].Groups[g].Icons[i], db.profile.Groups[groupID].Icons[iconID])
						TMW:Group_Update(groupID)
						IE:Load(1)
					end
					info.tooltipTitle = format(L["GROUPICON"], TMW:GetGroupName(db.profiles[n].Groups[g].Name, g, 1), i)
					info.tooltipText = 	((d.Name and d.Name ~= "" and d.Type ~= "meta" and d.Type ~= "wpnenchant") and d.Name .. "\r\n" or "") ..
									(GetLocalizedSettingString("Type", d.Type) or "") ..
									((d.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")
					info.tooltipOnButton = true
					info.icon = tex
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
	end
end

local cachednames = {}
function IE:GetRealNames()
	-- gets a string to set as a tooltip of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names
	local text = IE.Main.Name:GetText()
	if cachednames[TMW.CI.t .. TMW.CI.SoI .. text] then return cachednames[TMW.CI.t .. TMW.CI.SoI .. text] end

	for name in pairs(TMW.DS) do
		-- want to buy a case insensitive gsub so i dont have to do stupid stuff like this
		local t = strlower(text)
		local startpos, endpos = strfind(t, "[; ]"..strlower(name).."[; ]")
		if startpos then
			local firsthalf = strsub(text, 0, startpos-1)
			local lasthalf = strsub(text, endpos+1)
			text = firsthalf.."; (" .. L[name] .. ");"..lasthalf
		end
	end
	text = TMW:CleanString(text)
	local tbl
	
	local BEbackup = TMW.BE
	TMW.BE = TMW.OldBE -- the level of hackyness here is sickening
	-- by passing false in for arg3 (firstOnly), it creates a unique cache string and therefore a unique cache - nessecary because we arent using the real TMW.BE
	if TMW.CI.SoI == "item" then
		tbl = TMW:GetItemIDs(nil, text, false)
	else
		tbl = TMW:GetSpellNames(nil, text, false)
	end
	TMW.BE = BEbackup -- unhack
	
	local str = ""
	LBCode(tbl)
	for k, v in pairs(tbl) do
		local name, _, texture = GetSpellInfo(v)
		name = name or v
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple spellIDs.
			if k ~= #tbl then
				if #tbl > 50 then -- dont use 1 per line if there a bunch
					str = str .. (texture and ("|T" .. texture .. ":0|t") or "") .. name .. "; "
				else
					str = str .. (texture and ("|T" .. texture .. ":0|t") or "") .. name .. "; \r\n"
				end
			else
				str = str .. (texture and ("|T" .. texture .. ":0|t") or "") .. name
			end
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	cachednames[TMW.CI.t .. TMW.CI.SoI .. text] = str
	return str
end


SUG = TMW:NewModule("Suggester", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0") TMW.SUG = SUG
SUG.doUpdateItemCache = true

SUG.f = CreateFrame("Frame")
SUG.Parser = CreateFrame("GameTooltip", "TMWSUGParser", TMW, "GameTooltipTemplate")
function SUG:BAG_UPDATE()
	SUG.doUpdateItemCache = true
end
SUG:RegisterEvent("BAG_UPDATE")

SUG.NumCachePerFrame = 10
function SUG:ADDON_LOADED(event, addon)
	if addon == "TellMeWhen_Options" then
		TMWOptDB = TMWOptDB or {}

		TMWOptDB.SpellCache = TMWOptDB.SpellCache or {}
		TMWOptDB.CastCache = TMWOptDB.CastCache or {}
		TMWOptDB.ItemCache = TMWOptDB.ItemCache or {}
		TMWOptDB.ClassSpellCache = TMWOptDB.ClassSpellCache or {}
		
		for k, v in pairs(TMWOptDB) do
			SUG[k] = v
		end
		SUG.ActionCache = {} -- dont save this, it should be a list of things that are CURRENTLY on THIS CHARACTER'S action bars
		SUG.RequestedFrom = {}
		
		SUG.ClassSpellCache[pclass] = SUG.ClassSpellCache[pclass] or {}
		local _, _, offs, numspells = GetSpellTabInfo(GetNumSpellTabs())
		local ClassSpellCache = SUG.ClassSpellCache[pclass]
		for i = 1, offs + numspells do
			local _, id = GetSpellBookItemInfo(i, "player")
			if id then
				ClassSpellCache[id] = 1
			end
		end
		SUG:BuildClassSpellLookup()
		
		SUG:RegisterComm("TMWSUG")
		if RegisterAddonMessagePrefix then
			RegisterAddonMessagePrefix("TMWSUG") -- new in WoW 4.1
		end
		SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSL"), "GUILD")
		
		
		if TMWOptDB.IncompleteCache or not TMWOptDB.WoWVersion or TMWOptDB.WoWVersion < select(4, GetBuildInfo()) then
			TMWOptDB.IncompleteCache = true

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
			if TMWOptDB.WoWVersion and TMWOptDB.WoWVersion < select(4, GetBuildInfo()) then
				wipe(SUG.SpellCache)
				wipe(SUG.CastCache)
			elseif TMWOptDB.IncompleteCache then
				for id in pairs(SUG.SpellCache) do
					index = max(index, id)
				end
			end
			TMWOptDB.WoWVersion = select(4, GetBuildInfo())

			local function SpellCacher()
				for id = index, index + SUG.NumCachePerFrame do
					SUG.Suggest.Status:SetValue(id)
					if spellsFailed < 1000 then
						local name, rank, icon = GetSpellInfo(id)
						if name then
							name = strlower(name)
							if
								not Blacklist[icon] and
								rank ~= SPELL_PASSIVE and
								not strfind(name, "dnd") and
								not strfind(name, "test") and
								not strfind(name, "debug") and
								not strfind(name, "bunny") and
								not strfind(name, "visual") and
								not strfind(name, "trigger") and
								not strfind(name, "%[") and
								not strfind(name, "%%") and
								not strfind(name, "%+") and
								not strfind(name, "%?") and
								not strfind(name, "quest") and
								not strfind(name, "vehicle") and
								not strfind(name, "event") and
								not strfind(name, "camera") and
								not strfind(name, "warning") and
								not strfind(name, "i am a")
							then
								GameTooltip_SetDefaultAnchor(SUG.Parser, UIParent)
								SUG.Parser:SetSpellByID(id)
								local r, g, b = TMWSUGParserTextLeft1:GetTextColor()
								if g > .95 and r > .95 and b > .95 then
									SUG.SpellCache[id] = name
									if TMWSUGParserTextLeft2:GetText() == SPELL_CAST_CHANNELED or TMWSUGParserTextLeft3:GetText() == SPELL_CAST_CHANNELED or select(7, GetSpellInfo(id)) > 0 then
										SUG.CastCache[id] = name
									end
								end
								SUG.Parser:Hide()
								spellsFailed = 0
							end
						else
							spellsFailed = spellsFailed + 1
						end
					else
						TMWOptDB.IncompleteCache = false
						TMWOptDB.CacheLength = id
						SUG.f:SetScript("OnUpdate", nil)
						SUG.Suggest.Speed:Hide()
						SUG.Suggest.Status:Hide()

						SUG.IsCaching = nil
						SUG.SpellCache[1852] = nil -- GM spell named silenced, interferes with equiv
						SUG.SpellCache[57208] = nil -- enraged
						SUG.SpellCache[71216] = nil -- enraged
						if SUG.onCompleteCache then
							TMW.SUG.redoIfSame = 1
							SUG:NameOnCursor()
						end
						return
					end
				end
				index = index + 1 + SUG.NumCachePerFrame
			end
			SUG.f:SetScript("OnUpdate", SpellCacher)
			SUG.IsCaching = true
		end
		SUG:UnregisterEvent("ADDON_LOADED")
	end
end
SUG:RegisterEvent("ADDON_LOADED")

function SUG:UNIT_PET(event, unit)
	if unit == "player" then
		if not TMWOptDB.ClassSpellCache then return end
		if HasPetSpells() then
			local ClassSpellCache = SUG.ClassSpellCache[pclass]
			local i = 1
			while true do
				local _, id = GetSpellBookItemInfo(i, "pet")
				if id then
					ClassSpellCache[id] = 1
				else
					break
				end
				i=i+1
			end
		end
	end
end
SUG:RegisterEvent("UNIT_PET")

local commThrowaway = {}
function SUG:OnCommReceived(prefix, text, channel, who)
	if prefix ~= "TMWSUG" then return end
	if channel == "WHISPER" and who == UnitName("player") then return end
	local success, arg1, arg2, arg3, arg4, arg5 = SUG:Deserialize(text)
	if success then
		if arg1 == "RCSL" and not SUG.RequestedFrom[who] then -- only send if the player has not requested yet this session
			SUG:BuildClassSpellLookup()
			SUG:SendCommMessage("TMWSUG", SUG:Serialize("CSL", SUG.ClassSpellLength), "WHISPER", who)
			SUG.RequestedFrom[who] = true
		elseif arg1 == "CSL" then
			wipe(commThrowaway)
			local RecievedClassSpellLength = arg2
			SUG:BuildClassSpellLookup()
			for class, length in pairs(RecievedClassSpellLength) do
				if not SUG.ClassSpellLength[class] or SUG.ClassSpellLength[class] < length then
					tinsert(commThrowaway, class)
				end
			end
			if #commThrowaway > 0 then
				SUG:SendCommMessage("TMWSUG", SUG:Serialize("RCSC", commThrowaway), "WHISPER", who)
			end
		elseif arg1 == "RCSC" then
			wipe(commThrowaway)
			for _, class in pairs(arg2) do
				commThrowaway[class] = SUG.ClassSpellCache[class]
			end
			SUG:SendCommMessage("TMWSUG", SUG:Serialize("CSC", commThrowaway), "WHISPER", who)
		elseif arg1 == "CSC" then
			for class, tbl in pairs(arg2) do
				for id in pairs(tbl) do
					SUG.ClassSpellCache[class][id] = 1
				end
			end
			SUG:BuildClassSpellLookup()
		end
	end
end


function GameTooltip:SetTMWEquiv(equiv)
	GameTooltip:AddLine(L[equiv], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(IE:Equiv_GenerateTips(equiv), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
end


SUG.preTable = {}
local miscprioritize = {
	[42292] = 1, -- pvp trinket spell
}

function SUG.Sorter(a, b)
	--[[PRIORITY:
		1)	Equivalancies/Dispel Types
		2)	Abilities on player's action bar if current icon is a multistate cooldown
		3)	Player's spells (pclass)
		4)	All player spells (any class)
		5)	Miscellaneous proiritization spells
		6)	SpellID if input is an ID
		7)	If input is a name
			7a) SpellID if names are identical
			7b) Alphabetical if names are different
	]]
	
	local equivA, equivB = TMW.EquivIDLookup[a], TMW.EquivIDLookup[b]
	if equivA or equivB then
		if equivA and equivB then
			return L[a] < L[b]
		else
			return equivA
		end
	end

	if TMW.CI.IsMultiState then
		local haveA = SUG.ActionCache[a]
		local haveB = SUG.ActionCache[b]
		if (haveA and not haveB) or (haveB and not haveA) then
			return haveA
		end
	end
	if TMW.CI.SoI == "spell" then
		--player's spells (pclass)
		local t = SUG.ClassSpellCache[pclass]
		local haveA = t[a]
		local haveB = t[b]
		if (haveA and not haveB) or (haveB and not haveA) then
			return haveA
		end
		
		--all player spells (any class)
		haveA = SUG.ClassSpellLookup[a]
		haveB = SUG.ClassSpellLookup[b]
		if (haveA and not haveB) or (haveB and not haveA) then
			return haveA
		end
	end
	
	local miscA, miscB = miscprioritize[a], miscprioritize[b] -- miscprioritize
	if (miscA and not miscB) or (miscB and not miscA) then
		return miscA
	end

	if SUG.inputType == "number" then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB
		if TMW.CI.SoI == "item" then
			nameA, nameB = SUG.ItemCache[a], SUG.ItemCache[b]
		else
			nameA, nameB = SUG.SpellCache[a], SUG.SpellCache[b]
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

function SUG:StartSuggester()
	SUG.Suggesting = 1
	SUG.f:SetScript("OnUpdate", SUG.Suggester)
end

local buffEquivs = {TMW.BE.buffs, TMW.BE.debuffs}
function SUG:Suggester()
	local start = GetTime()
	if SUG.startOver then
		wipe(SUG.preTable)
		SUG.nextCacheKey = nil
		SUG.startOver = false
		if TMW.CI.t == "cast" then
			for equiv, str in pairs(TMW.BE.casts) do
				if strfind(strlower(equiv), SUG.atBeginning) or strfind(strlower(L[equiv]), SUG.atBeginning) then
					SUG.preTable[#SUG.preTable + 1] = equiv
				end
			end
		elseif TMW.CI.t == "buff" then
			for _, b in pairs(buffEquivs) do
				for equiv, str in pairs(b) do
					if strfind(strlower(equiv), SUG.atBeginning) or strfind(strlower(L[equiv]), SUG.atBeginning)  then
						SUG.preTable[#SUG.preTable + 1] = equiv
					end
				end
			end
			for dispeltype in pairs(TMW.DS) do
				if strfind(strlower(dispeltype), SUG.atBeginning) or strfind(strlower(L[dispeltype]), SUG.atBeginning)  then
					SUG.preTable[#SUG.preTable + 1] = dispeltype
				end
			end
		end
	end
	while GetTime() - start < 0.025 do -- throttle it
		local id, name
		if TMW.CI.SoI == "item" then
			id, name = next(SUG.ItemCache, SUG.nextCacheKey)
		elseif TMW.CI.t == "cast" then
			id, name = next(SUG.CastCache, SUG.nextCacheKey)
		else
			id, name = next(SUG.SpellCache, SUG.nextCacheKey)
		end
		if id then
			if SUG.inputType == "number" then
				if strfind(id, SUG.atBeginning) then
					SUG.preTable[#SUG.preTable + 1] = id
				end
			else
				if strfind(name, SUG.atBeginning) then
					SUG.preTable[#SUG.preTable + 1] = id
				end
			end
			SUG.nextCacheKey = id
		else
			SUG.nextCacheKey = nil
			SUG.f:SetScript("OnUpdate", nil)
			SUG.Suggesting = nil
			SUG.doSort = true
			SUG:SuggestingComplete()
			return
		end
	end
end

function SUG:SuggestingComplete()
	local offset = SUG.offset
	if SUG.doSort then
		sort(SUG.preTable, SUG.Sorter)
		SUG.doSort = nil
	end
	local i = 1
	while SUG[i] do
		local id = SUG.preTable[i+offset]
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

			elseif TMW.EquivIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
				--NOTE: dispel types are put in EquivIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
				local equiv = id
				local firstid = TMW.EquivIDLookup[id]

				f.Name:SetText(equiv)
				f.ID:SetText(nil)

				f.insert = equiv

				f.tooltipmethod = "SetTMWEquiv"
				f.tooltiparg = equiv

				f.Icon:SetTexture(GetSpellTexture(firstid))
				if TMW.BE.buffs[equiv] then
					f.Background:SetVertexColor(.2, .9, .2, 1) -- lightish green
				elseif TMW.BE.debuffs[equiv] then
					f.Background:SetVertexColor(.77, .12, .23, 1) -- deathknight red
				elseif TMW.BE.casts[equiv] then
					f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
				end

			elseif tonumber(id) then --sanity check
				if TMW.CI.SoI == "item" then -- if the entry is an item
					local name, link = GetItemInfo(id)

					f.Name:SetText(link)
					f.ID:SetText(id)

					f.insert = SUG.inputType == "number" and id or name

					f.tooltipmethod = "SetHyperlink"
					f.tooltiparg = link

					f.Icon:SetTexture(GetItemIcon(id))

				else -- the entry must be just a normal spell
					local name = GetSpellInfo(id)

					f.Name:SetText(name)
					f.ID:SetText(id)

					f.tooltipmethod = "SetSpellByID"
					f.tooltiparg = id

					f.insert = SUG.inputType == "number" and id or name

					f.Icon:SetTexture(GetSpellTexture(id))
					if TMW.CI.IsMultiState and SUG.ActionCache[id] then
						f.Background:SetVertexColor(0, .44, .87, 1) --color actions that are on your action bars if the type is a multistate cooldown shaman blue
					elseif SUG.ClassSpellCache[pclass][id] then
						f.Background:SetVertexColor(.41, .8, .94, 1) --color all other spells that you have in your/your pet's spellbook mage blue
					else
						for class, tbl in pairs(SUG.ClassSpellCache) do
							if tbl[id] then
								f.Background:SetVertexColor(.96, .55, .73, 1) --color all other known class spells paladin pink
								break
							end
						end
					end
				end
			end
			if miscprioritize[id] then -- override previous
				f.Background:SetVertexColor(.58, .51, .79, 1)
			end
			f:Show()
		else
			f:Hide()
		end
		i=i+1
	end
end

function SUG:NameOnCursor()
	if SUG.IsCaching then
		SUG.onCompleteCache = true
		SUG.Suggest:Show()
		return
	end
	SUG.oldLastName = SUG.lastName
	local text = IE.Main.Name:GetText()

	SUG.startpos = 0
	SUG.endpos = IE.Main.Name:GetCursorPosition()
	for i = SUG.endpos, 0, -1 do
		if strsub(text, i, i) == ";" then
			SUG.startpos = i+1
			break
		end
	end

	SUG.lastName = strsub(text, SUG.startpos, SUG.endpos)
	SUG.lastName = strlower(TMW:CleanString(SUG.lastName))

	--disable pattern matches that will break/interfere
	SUG.lastName = gsub(SUG.lastName, "%%", "%%%%")
	SUG.lastName = gsub(SUG.lastName, "%-", "%%-")
	SUG.lastName = gsub(SUG.lastName, "%[", "%%[")
	SUG.lastName = gsub(SUG.lastName, "%]", "%%]")
	SUG.lastName = gsub(SUG.lastName, "%(", "%%(")
	SUG.lastName = gsub(SUG.lastName, "%)", "%%)")


	SUG.atBeginning = "^"..SUG.lastName

	if SUG.lastName == "" or not strfind(SUG.lastName, "[^%.]") then
		SUG.Suggest:Hide()
		SUG.f:SetScript("OnUpdate", nil)
		return
	else
		SUG.Suggest:Show()
	end

	SUG.inputType = type(tonumber(SUG.lastName) or SUG.lastName)
	SUG.startOver = true
	if not (SUG.oldLastName == SUG.lastName and not SUG.redoIfSame) then
		SUG:CacheItems()
		if TMW.CI.IsMultiState then
			SUG:CacheActions()
		end

		SUG.offset = 0
		SUG:StartSuggester()
	end
end

function SUG:OnClick()
	if self.insert then
		local currenttext = IE.Main.Name:GetText()
		local start = SUG.startpos-1
		local firsthalf
		if start <= 0 then
			firsthalf = ""
		else
			firsthalf = strsub(currenttext, 0, start)
		end
		local lasthalf = strsub(currenttext, SUG.endpos+1)
		local newtext = firsthalf .. "; " .. self.insert .. "; " .. lasthalf
		IE.Main.Name:SetText(TMW:CleanString(newtext))
		IE.Main.Name:SetCursorPosition(SUG.endpos + (#tostring(self.insert) - #tostring(SUG.lastName)) + 2)
		if IE.Main.Name:GetCursorPosition() == IE.Main.Name:GetNumLetters() then -- if we are at the end of the exitbox then put a semicolon in anyway for convenience
			IE.Main.Name:SetText(IE.Main.Name:GetText().. "; ")
			IE.Main.Name:SetCursorPosition(IE.Main.Name:GetNumLetters())
		end
		SUG.Suggest:Hide()
	end
end

function SUG:CacheItems()
	for container = -2, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(container) do
			local id = GetContainerItemID(container, slot)
			if id then
				SUG.ItemCache[id] = strlower(GetItemInfo(id))
		--		local 
			end
		end
	end
	for slot = 1, 19 do
		local id = GetInventoryItemID("player", slot)
		if id then
			SUG.ItemCache[id] = strlower(GetItemInfo(id))
	--		local 
		end
	end
end

function SUG:CacheActions()
	wipe(SUG.ActionCache)
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID then
			SUG.ActionCache[spellID] = i
		end
	end
end

function SUG:BuildClassSpellLookup()
	SUG.ClassSpellLength = SUG.ClassSpellLength or {}
	SUG.ClassSpellLookup = SUG.ClassSpellLookup or {}
	for class, tbl in pairs(SUG.ClassSpellCache) do
		SUG.ClassSpellLength[class] = 0
		for id in pairs(tbl) do
			SUG.ClassSpellLookup[id] = 1
			SUG.ClassSpellLength[class] = SUG.ClassSpellLength[class] + 1
		end
	end
end

-- -----------------------
-- CONDITION EDITOR DIALOG
-- -----------------------

CNDT = TMW.CNDT

function CNDT:TypeMenuOnClick(frame, data)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	UIDropDownMenu_SetText(frame, data.text)
	local group = frame:GetParent()
	local showval = CNDT:TypeCheck(group, data)
	CNDT:SetSliderMinMax(group)
	if showval then
		CNDT:SetValText(group)
	else
		group.ValText:SetText("")
	end
	CNDT:OK()
	CloseDropDownMenus()
end

local addedcategories = {}
function CNDT:TypeMenu_DropDown()
	wipe(addedcategories)
	for k, v in pairs(CNDT.Types) do
		if ((UIDROPDOWNMENU_MENU_LEVEL == 2 and v.category == UIDROPDOWNMENU_MENU_VALUE) or (UIDROPDOWNMENU_MENU_LEVEL == 1 and not v.category)) and v.shouldshow ~= false then
			if v.spacebefore then
				local info = UIDropDownMenu_CreateInfo()
				info.text = ""
				info.isTitle = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			local info = UIDropDownMenu_CreateInfo()
			info.func = CNDT.TypeMenuOnClick
			info.text = v.text
			info.tooltipTitle = v.text
			info.tooltipText = v.tooltip
			info.tooltipOnButton = true
			info.value = v.value
			info.arg1 = self
			info.arg2 = v
			if type(v.icon) == "function" then
				info.icon = v.icon()
			else
				info.icon = v.icon
			end
			if v.tcoords then
				info.tCoordLeft = v.tcoords[1]
				info.tCoordRight = v.tcoords[2]
				info.tCoordTop = v.tcoords[3]
				info.tCoordBottom = v.tcoords[4]
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		elseif UIDROPDOWNMENU_MENU_LEVEL == 1 and v.category and not addedcategories[v.category] then
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.category
			info.value = v.category
			info.notCheckable = true
			info.hasArrow = true
			addedcategories[v.category] = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

function CNDT:UnitMenu_DropDown()
	for k, v in pairs(IE.Data.Unit) do
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
	CNDT:OK()
end

function CNDT:IconMenu_DropDown()
	for k, v in pairs(TMW.Icons) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.IconMenuOnClick
		local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g), tonumber(i)
		local text, textshort = TMW:GetIconMenuText(g, i)
		info.text = textshort
		info.value = v
		info.tooltipTitle = text
		info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[g].Name, g, 1), i)
		info.tooltipOnButton = true
		info.arg1 = self
		info.icon = TMW[g][i].texture:GetTexture()
		UIDropDownMenu_AddButton(info)
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

function CNDT:AndOrMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	CNDT:OK()
end

function CNDT:AndOrMenu_DropDown()
	for k, v in pairs(CNDT.AndOrs) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.AndOrMenuOnClick
		info.text = v.text
		info.value = v.value
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
	assert(pair)
	if rune:GetChecked() ~= nil then
		pair:SetChecked(nil)
	end
end


function CNDT:AddRemoveHandler()
	local i=1
	CNDT[1].Up:Hide()
	while CNDT[i] do
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
	if n > 0 then
		IE.ConditionTab:SetText(L["CONDITIONS"] .. " |cFFFF5959(" .. n .. ")")
	else
		IE.ConditionTab:SetText(L["CONDITIONS"] .. " (" .. n .. ")")
	end
	PanelTemplates_TabResize(IE.ConditionTab, 0, nil, nil, 600)
end

function CNDT:AddDelete(group)
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	local conditions = db.profile.Groups[groupID].Icons[iconID]["Conditions"]
	if group:IsShown() then
		tremove(conditions, group:GetID())
	else
		local condition = conditions[group:GetID()] -- cheesy way to invoke the metamethod and create a new condition table
	end
	CNDT:AddRemoveHandler()
	CNDT:Load()
end

function CNDT:UpOrDown(ID, delta)
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	local settings = db.profile.Groups[groupID].Icons[iconID].Conditions
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	CNDT:Load()
end

function CNDT:OK()
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	if not groupID then return end

	local conditions = db.profile.Groups[groupID].Icons[iconID]["Conditions"]
	local i = 1
	while CNDT[i] and CNDT[i]:IsShown() do
		local group = CNDT[i]
		local condition = conditions[i]

		condition.Type = UIDropDownMenu_GetSelectedValue(group.Type) or "HEALTH"
		condition.Unit = strtrim(group.Unit:GetText()) or "player"
		condition.Operator = UIDropDownMenu_GetSelectedValue(group.Operator) or "=="
		condition.Icon = UIDropDownMenu_GetSelectedValue(group.Icon) or ""
		condition.Level = tonumber(group.Slider:GetValue()) or 0
		condition.AndOr = UIDropDownMenu_GetSelectedValue(group.AndOr) or "AND"
		condition.Name = strtrim(group.EditBox:GetText()) or ""

		for k, rune in pairs(group.Runes) do
			if type(rune) == "table" then
				condition.Runes[rune:GetID()] = rune:GetChecked()
			end
		end

		i=i+1
	end
	while CNDT[i] and not CNDT[i]:IsShown() do
		conditions[i] = nil
		i=i+1
	end
	TMW:ScheduleIconUpdate(groupID, iconID)
end

function CNDT:Load()
	local groupID, iconID = TMW.CI.g, TMW.CI.i
	local conditions = db.profile.Groups[groupID].Icons[iconID].Conditions
	if #conditions > 0 then
		for i = #conditions, TELLMEWHEN_MAXCONDITIONS do
			CNDT:ClearGroup(CNDT[i])
		end
		CNDT:CreateGroups(#conditions+1)

		local i = 1
		while #conditions >= i do
			local group = CNDT[i]
			CNDT:SetUIDropdownText(group.Type, conditions[i].Type, CNDT.Types)
			group.Unit:SetText(conditions[i].Unit)
			group.EditBox:SetText(conditions[i].Name)
			CNDT:SetUIDropdownText(group.Icon, conditions[i].Icon, TMW.Icons)

			local v = CNDT:SetUIDropdownText(group.Operator, conditions[i].Operator, CNDT.Operators)
			TMW:TT(group.Operator, v.tooltipText, nil, 1, nil, 1)

			group.Slider:SetValue(conditions[i].Level or 0)
			CNDT:SetValText(group)

			for k, rune in pairs(group.Runes) do
				if type(rune) == "table" then
					rune:SetChecked(conditions[i].Runes[rune:GetID()])
				end
			end

			group:Show()

			if i > 1 then
				CNDT:SetUIDropdownText(group.AndOr, conditions[i].AndOr, CNDT.AndOrs)
			end
			i=i+1
		end
	else
		CNDT:ClearDialog()
	end
	CNDT:AddRemoveHandler()
end

function CNDT:ClearGroup(group)
	group.Unit:SetText("player")
	group.EditBox:SetText("")
	UIDropDownMenu_SetSelectedValue(group.Icon, "")
	CNDT:SetUIDropdownText(group.Type, "HEALTH", CNDT.Types)
	CNDT:SetUIDropdownText(group.Operator, "==", CNDT.Operators)
	CNDT:SetUIDropdownText(group.AndOr, "AND", CNDT.AndOrs)
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
	CNDT:SetSliderMinMax(group)
	CNDT:SetValText(group)
end

function CNDT:ClearDialog()
	TellMeWhen_IconEditor.Conditions.ScrollFrame.ScrollBar:Hide()
	for i=1, TELLMEWHEN_MAXCONDITIONS do
		CNDT:ClearGroup(CNDT[i])
	end
	CNDT:AddRemoveHandler()
	CNDT:SetTitles()
end


function CNDT:CreateGroups(num)
	local start = TELLMEWHEN_MAXCONDITIONS
	while CNDT[start] do
		start = start + 1
	end
	for i=start, num do
		local group = CNDT[i] or CreateFrame("Frame", "TellMeWhen_IconEditorConditionsGroupsGroup" .. i, TellMeWhen_IconEditor.Conditions.Groups, "TellMeWhen_ConditionGroup", i)
		group:SetPoint("TOPLEFT", CNDT[i-1], "BOTTOMLEFT", 0, 0)
		group.AddDelete:ClearAllPoints()
		group.AddDelete:SetPoint("TOPLEFT", CNDT[i], 12, 16)
		CNDT:ClearGroup(group)
		CNDT:SetTitles(group)
	end
	if num > TELLMEWHEN_MAXCONDITIONS then
		TELLMEWHEN_MAXCONDITIONS = num
	end
end

function CNDT:SetUIDropdownText(frame, value, tbl)
	UIDropDownMenu_SetSelectedValue(frame, value)
	local group = frame:GetParent()
	CNDT:SetSliderMinMax(group)
	if tbl == CNDT.Types then
		CNDT:TypeCheck(group, CNDT.ConditionsByType[value])
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

function CNDT:SetTitles(onlygroup)
	for i=1, TELLMEWHEN_MAXCONDITIONS do
		local group = onlygroup or CNDT[i]
		if not (group and group.TextType) then return end
		group.TextType:SetText(L["CONDITIONPANEL_TYPE"])
		group.TextUnitOrIcon:SetText(L["CONDITIONPANEL_UNIT"])
		group.TextUnitDef:SetText("")
		group.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
		group.AndOrTxt:SetText(L["CONDITIONPANEL_ANDOR"])
		group.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
		if onlygroup then return end
	end
end

function CNDT:SetValText(group)
	if TMW.Initd and group.ValText then
		local val = group.Slider:GetValue()
		local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
		if v.texttable then
			val = v.texttable[val]
		end
		group.ValText:SetText(val)
	end
end

function CNDT:SetSliderMinMax(group)
	local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
	group.Slider:SetMinMaxValues(v.min or 0, v.max or 1)
	_G[group.Slider:GetName() .. "Low"]:SetText((v.texttable and v.texttable[v.min]) or v.mint or v.min or 0)
	_G[group.Slider:GetName() .. "Mid"]:SetText(v.midt)
	_G[group.Slider:GetName() .. "High"]:SetText((v.texttable and v.texttable[v.max]) or v.maxt or v.max or 1)
end

function CNDT:TypeCheck(group, data)
	local unit = data.unit

	group.Icon:Hide() --it bugs sometimes so just do it by default
	group.Runes:Hide()
	local showval = true
	CNDT:SetTitles(group)
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
		else
			TMW:TT(group.EditBox, nil, nil, nil, nil, 1)
		end
		group.Slider:SetWidth(120)
		if data.noslide then
			group.EditBox:SetWidth(435)
		else
			group.EditBox:SetWidth(305)
		end
	else
		group.EditBox:Hide()
		group.Slider:SetWidth(440)
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
end






