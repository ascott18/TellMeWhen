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

local CI = TMW.CI
local get = TMW.get

local _G = _G
local pairs, ipairs, wipe, tinsert, tremove, rawget, tonumber, tostring, type = 
	  pairs, ipairs, wipe, tinsert, tremove, rawget, tonumber, tostring, type
local strtrim, gsub, min, max = 
	  strtrim, gsub, min, max



-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE, UIDROPDOWNMENU_OPEN_MENU
-- GLOBALS: UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, UIDropDownMenu_SetText, UIDropDownMenu_GetSelectedValue
-- GLOBALS: CloseDropDownMenus

local operators = {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}

-- -----------------------
-- CONDITION EDITOR
-- -----------------------


local CNDT = TMW.CNDT -- created in TellMeWhen/conditions.lua
TMW.ID:RegisterIconDragHandler(10,	-- Condition
	function(ID, info)
		if ID.desticon then
			if ID.srcicon:IsValid() then
				info.text = L["ICONMENU_APPENDCONDT"]
				info.tooltipTitle = nil
				info.tooltipText = nil
				return true
			end
		end
	end,
	function(ID)
		-- add a condition to the destination icon
		local Condition = CNDT:AddCondition(TMW.db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()].Conditions)

		-- set the settings
		Condition.Type = "ICON"
		Condition.Icon = ID.srcicon:GetName()
	end
)

---------- Interface/Data ----------
function CNDT:LoadConfig(type)
	type = type or CNDT.type or "icon"
	CNDT.type, CNDT.settings = CNDT:GetTypeData(type)

	local Conditions = CNDT.settings
	if not Conditions then return end

	TMW.HELP:Hide("CNDT_UNIT_MISSING")
	if Conditions.n > 0 then
		for i = Conditions.n + 1, #CNDT do
			CNDT[i]:Clear()
		end
		CNDT:CreateGroups(Conditions.n+1)

		for i in TMW:InNLengthTable(Conditions) do
			CNDT[i]:Load()
		end
	else
		CNDT:Clear()
	end
	CNDT:AddRemoveHandler()

	if TellMeWhen_IconEditor.Conditions.ScrollFrame:GetVerticalScrollRange() == 0 then
		TellMeWhen_IconEditor.Conditions.ScrollFrame.ScrollBar:Hide()
	end
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function()
	-- This is encapsulated in a function because LoadConfig excepts arg2 to be a condition type ("group" or "icon"),
	-- but it would end up being an event or an icon if CNDT.LoadConfig were registed as the callback.
	CNDT:LoadConfig()
end)

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
		TMW.IE:ScheduleIconSetup()
	elseif CNDT.type == "group" then
		TMW[groupID]:Setup()
	end
end

function CNDT:Clear()
	for i=1, #CNDT do
		CNDT[i]:Clear()
		CNDT[i]:SetTitles()
	end
	CNDT:AddRemoveHandler()
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED_CHANGED", "Clear", CNDT)

function CNDT:SetTabText(type)
	local type, Conditions = CNDT:GetTypeData(type)

	local parenthesesAreValid, errorMessage, fmt_1, fmt_2 = CNDT:CheckParentheses(Conditions)

	if not parenthesesAreValid then
		TMW.HELP:Show("CNDT_PARENTHESES_ERROR", nil, TellMeWhen_IconEditor.Conditions, 0, 0, errorMessage, fmt_1, fmt_2)
	end
	
	local tab = (type == "icon" and TMW.IE.IconConditionTab) or TMW.IE.GroupConditionTab
	local n = Conditions.n

	if n > 0 then
		tab:SetText((not parenthesesAreValid and "|TInterface\\AddOns\\TellMeWhen_Options\\Textures\\Alert:0:2|t|cFFFF0000" or "") .. L[type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " |cFFFF5959(" .. n .. ")")
	else
		tab:SetText(L[type == "icon" and "CONDITIONS" or "GROUPCONDITIONS"] .. " (" .. n .. ")")
	end

	PanelTemplates_TabResize(tab, -6)
end

TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function(event, icon)
	CNDT:SetTabText("icon")
	CNDT:SetTabText("group")
end)
	
function CNDT:GetTypeData(type)
	if type == "icon" then
		return type, TMW.db.profile.Groups[CI.g].Icons[CI.i].Conditions
	elseif type == "group" then
		return type, TMW.db.profile.Groups[CI.g].Conditions
	else
		return CNDT.type, CNDT.settings
	end
end


---------- Dropdowns ----------
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
	info.func = CNDT.TypeMenu_DropDown_OnClick
	info.text = v.text
	info.tooltipTitle = v.text
	info.tooltipText = v.tooltip
	info.tooltipOnButton = true
	info.value = v.value
	info.arg1 = v
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
	local addedFreq = true -- FREQUENCY SUBMENU DISABLED BY SETTING THIS TRUE
	for k, v in ipairs(CNDT.Types) do

		-- add the frequently used submenu before the first condition that does not have a category
		if not v.category and not addedFreq and UIDROPDOWNMENU_MENU_LEVEL == 1 then
			TMW.AddDropdownSpacer()

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
				TMW.AddDropdownSpacer()
			end

			-- most conditions are added to the dropdown right here
			AddConditionToDropDown(v)

			if v.spaceafter then
				TMW.AddDropdownSpacer()
			end

		elseif UIDROPDOWNMENU_MENU_LEVEL == 1 and v.category and not addedThings[v.category] then
			-- addedThings IN THIS CASE is a list of categories that have been added. Add ones here that have not been added yet.

			if v.categorySpacebefore then
				TMW.AddDropdownSpacer()
			end

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

function CNDT:TypeMenu_DropDown_OnClick(data)
	TMW:SetUIDropdownText(UIDROPDOWNMENU_OPEN_MENU, self.value)
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
		elseif v.desc then
			info.tooltipTitle = v.tooltipTitle or v.text
			info.tooltipText = v.desc
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
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for icon, groupID, iconID in TMW:InIcons() do
			if icon:IsValid() and UIDROPDOWNMENU_MENU_VALUE == groupID and CI.ic ~= icon then
				local info = UIDropDownMenu_CreateInfo()

				local text, textshort, tooltip = TMW:GetIconMenuText(groupID, iconID)
				if text:sub(-2) == "))" then
					textshort = textshort .. " " .. L["fICON"]:format(iconID)
				end
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipText = L["GROUPICON"]:format(TMW:GetGroupName(groupID, groupID, 1), iconID) .. "\r\n" .. tooltip
				info.tooltipOnButton = true

				info.arg1 = self
				info.value = icon:GetName()
				info.func = CNDT.IconMenu_DropDown_OnClick

				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				info.icon = icon.attributes.texture
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then
		for group, groupID in TMW:InGroups() do
			if group:ShouldUpdateIcons() then
				local info = UIDropDownMenu_CreateInfo()
				info.text = TMW:GetGroupName(groupID, groupID, 1)
				info.hasArrow = true
				info.notCheckable = true
				info.value = groupID
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end

function CNDT:IconMenu_DropDown_OnClick(frame)
	TMW:SetUIDropdownText(frame, self.value, TMW.InIcons)
	frame.IconPreview:SetIcon(_G[self.value])
	CloseDropDownMenus()
	CNDT:Save()
end

function CNDT:OperatorMenu_DropDown()
	for k, v in pairs(operators) do
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
	TMW:SetUIDropdownText(frame, self.value)
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

function CNDT:ColorizeParentheses()
	if not TellMeWhen_IconEditor.Conditions:IsShown() then return end

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
		TMW.Classes.CndtGroup:New("Frame", "TellMeWhen_IconEditorConditionsGroupsGroup" .. i, TellMeWhen_IconEditor.Conditions.Groups, "TellMeWhen_ConditionGroup", i)
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


---------- CndtGroup Class ----------
local CndtGroup = TMW:NewClass("CndtGroup", "Frame")

function CndtGroup.OnNewInstance(group)
	local ID = group:GetID()

	CNDT[ID] = group

	group:SetPoint("TOPLEFT", CNDT[ID-1], "BOTTOMLEFT", 0, -14.5)

	local p, _, rp, x, y = TMW.CNDT[1].AddDelete:GetPoint()
	group.AddDelete:ClearAllPoints()
	group.AddDelete:SetPoint(p, CNDT[ID], rp, x, y)

	group:Clear()
	group:SetTitles()
	
	
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", "ClearFocus", group.Unit)
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", "ClearFocus", group.EditBox)
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", "ClearFocus", group.EditBox2)
end

function CndtGroup.TypeCheck(group, data)
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
			TMW.SUG:EnableEditBox(group.EditBox, data.useSUG, not data.allowMultipleSUGEntires)

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
			TMW.SUG:DisableEditBox(group.EditBox)
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
			TMW.SUG:EnableEditBox(group.EditBox2, data.useSUG, not data.allowMultipleSUGEntires)
			group.EditBox:SetWidth(250)
			group.EditBox2:SetWidth(250)
		else
			group.Check2:Hide()
			group.EditBox2:Hide()
			TMW.SUG:DisableEditBox(group.EditBox2)
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

function CndtGroup.Save(group)
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

function CndtGroup.Load(group)
	local condition = CNDT.settings[group:GetID()]
	local data = CNDT.ConditionsByType[condition.Type]

	TMW:SetUIDropdownText(group.Type, condition.Type)
	UIDropDownMenu_SetText(group.Type, data and data.text or (condition.Type .. ": UNKNOWN TYPE"))

	group:TypeCheck(data)

	group.Unit:SetText(condition.Unit)
	group.EditBox:SetText(condition.Name)
	group.EditBox2:SetText(condition.Name2)
	group.Check:SetChecked(condition.Checked)
	group.Check2:SetChecked(condition.Checked2)

	TMW:SetUIDropdownText(group.Icon, condition.Icon, TMW.InIcons)
	group.Icon.IconPreview:SetIcon(_G[condition.Icon])

	local v = TMW:SetUIDropdownText(group.Operator, condition.Operator, operators)
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

	group.AndOr:SetValue(condition.AndOr)
	group:Show()
end

function CndtGroup.Clear(group)
	group.Unit:SetText("player")
	group.EditBox:SetText("")
	group.EditBox2:SetText("")
	group.Check:SetChecked(nil)
	group.Check2:SetChecked(nil)

	TMW:SetUIDropdownText(group.Icon, "", TMW.InIcons)
	
	UIDropDownMenu_SetText(group.Type, CNDT.ConditionsByType[""].text)
	group:TypeCheck(CNDT.ConditionsByType[""])
	
	TMW:SetUIDropdownText(group.Operator, "==", operators)
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

function CndtGroup.SetValText(group)
	if group.ValText then
		local val = group.Slider:GetValue()
		local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
		if v then
			group.ValText:SetText(get(v.texttable, val) or val)
		end
	end
end

function CndtGroup.UpOrDown(group, delta)
	local ID = group:GetID()
	local settings = CNDT.settings
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	CNDT:LoadConfig()
end

function CndtGroup.AddDeleteHandler(group)
	if group:IsShown() then
		CNDT:DeleteCondition(CNDT.settings, group:GetID())
	else
		CNDT:AddCondition(CNDT.settings)
	end
	CNDT:AddRemoveHandler()
	CNDT:LoadConfig()
end

function CndtGroup.SetTitles(group)
	if not group.TextType then return end
	group.TextType:SetText(L["CONDITIONPANEL_TYPE"])
	group.TextUnitOrIcon:SetText(L["CONDITIONPANEL_UNIT"])
	group.TextUnitDef:SetText("")
	group.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
	group.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
end

function CndtGroup.SetSliderMinMax(group, level)
	-- level is passed in only when the setting is changing or being loaded
	local v = CNDT.ConditionsByType[UIDropDownMenu_GetSelectedValue(group.Type)]
	if not v then return end
	local Slider = group.Slider
	if v.range then
		local deviation = v.range/2
		local val = level or Slider:GetValue()

		local newmin = max(0, val-deviation)
		local newmax = max(deviation, val + deviation)

		Slider:SetMinMaxValues(newmin, newmax)
		Slider.Low:SetText(get(v.texttable, newmin) or newmin)
		Slider.High:SetText(get(v.texttable, newmax) or newmax)
	else
		local vmin = get(v.min)
		local vmax = get(v.max)
		Slider:SetMinMaxValues(vmin or 0, vmax or 1)
		Slider.Low:SetText(get(v.texttable, vmin) or v.mint or vmin or 0)
		Slider.High:SetText(get(v.texttable, vmax) or v.maxt or vmax or 1)
	end

	local Min, Max = Slider:GetMinMaxValues()
	local Mid
	if v.Mid == true then
		Mid = get(v.texttable, ((Max-Min)/2)+Min) or ((Max-Min)/2)+Min
	else
		Mid = get(v.midt, ((Max-Min)/2)+Min)
	end
	Slider.Mid:SetText(Mid)

	Slider.step = v.step or 1
	Slider:SetValueStep(Slider.step)
	if level then
		Slider:SetValue(level)
	end
end

