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


local CNDT = TMW.CNDT -- created in TellMeWhen/conditions.lua

TMW.ID:RegisterIconDragHandler(10,
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

function CNDT:OnInitialize()
	
end

---------- Interface/Data ----------
function CNDT:LoadConfig(conditionSetName)
	local ConditionSet
	if conditionSetName then
		ConditionSet = CNDT.ConditionSets[conditionSetName]
	else
		ConditionSet = CNDT.CurrentConditionSet
	end
	
	CNDT.CurrentConditionSet = ConditionSet
	if not ConditionSet then return end
	
	if ConditionSet.useDynamicTab then
		if conditionSetName then
			TMW.IE.DynamicConditionTab:Show()
		
			-- Only click the tab if we are manually loading the conditionSet (should only happen on user input)
			TMW.IE:TabClick(TMW.IE.DynamicConditionTab)
		end
	else
		TMW.IE.DynamicConditionTab:Hide()
	end
	
	
	CNDT.settings = ConditionSet:GetSettings()	
	if not CNDT.settings then return end
	
	

	TMW.HELP:Hide("CNDT_UNIT_MISSING")
	if CNDT.settings.n > 0 then
		for i = CNDT.settings.n + 1, #CNDT do
			CNDT[i]:Clear()
		end
		CNDT:CreateGroups(CNDT.settings.n+1)

		for i in TMW:InNLengthTable(CNDT.settings) do
			CNDT[i]:Load()
		end
	else
		CNDT:Clear()
	end
	CNDT:AddRemoveHandler()
end

TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function()
	-- This is encapsulated in a function because LoadConfig excepts arg2 to be a conditionSetName,
	-- but it would end up being an event or an icon if CNDT.LoadConfig were registed as the callback.
	CNDT:LoadConfig()
end)


TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED_CHANGED", function(event, icon)
	if TMW.IE.CurrentTab == TMW.IE.DynamicConditionTab then
		TMW.IE:TabClick(TMW.IE.MainTab)
	end
end)
TMW:RegisterCallback("TMW_CONFIG_TAB_CLICKED", function(event, currentTab, oldTab)
	if oldTab == TMW.IE.DynamicConditionTab then
		TMW.IE.DynamicConditionTab:Hide()
	end
end)

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()	
	local CurrentConditionSet = CNDT.CurrentConditionSet
	
	if CurrentConditionSet and CurrentConditionSet.useDynamicTab and CurrentConditionSet.ShouldShowTab then
		if not CurrentConditionSet:ShouldShowTab() then
			if TMW.IE.CurrentTab == TMW.IE.DynamicConditionTab then
				TMW.IE:TabClick(TMW.IE.MainTab)
			else
				TMW.IE.DynamicConditionTab:Hide()
			end
		end
	else
		TMW.IE.DynamicConditionTab:Hide()
	end
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

	TMW:ScheduleUpdate(.2)
end

function CNDT:Clear()
	for i=1, #CNDT do
		CNDT[i]:Clear()
		CNDT[i]:SetTitles()
	end
	CNDT:AddRemoveHandler()
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED_CHANGED", "Clear", CNDT)

function CNDT:GetTabText(conditionSetName)
	local ConditionSet = CNDT.ConditionSets[conditionSetName] or CNDT.CurrentConditionSet
	
	local Conditions = ConditionSet:GetSettings()
	local tabText = ConditionSet.tabText

	local parenthesesAreValid, errorMessage, fmt_1, fmt_2 = CNDT:CheckParentheses(Conditions)

	if parenthesesAreValid then
		TMW.HELP:Hide("CNDT_PARENTHESES_ERROR")
	else
		TMW.HELP:Show("CNDT_PARENTHESES_ERROR", nil, TellMeWhen_IconEditor.Conditions, 0, 0, errorMessage, fmt_1, fmt_2)
	end
	
	local n = Conditions.n

	if n > 0 then
		local prefix = (not parenthesesAreValid and "|TInterface\\AddOns\\TellMeWhen\\Textures\\Alert:0:2|t|cFFFF0000" or "")
		return (prefix .. tabText .. " |cFFFF5959(" .. n .. ")")
	else
		return (tabText .. " (" .. n .. ")")
	end
end

function CNDT:SetTabText(conditionSetName)
	local ConditionSet = CNDT.ConditionSets[conditionSetName] or CNDT.CurrentConditionSet
	
	local tab = ConditionSet.useDynamicTab and TMW.IE.DynamicConditionTab or ConditionSet:GetTab()
	
	tab:SetText(CNDT:GetTabText(conditionSetName))

	if tab:IsShown() then
		PanelTemplates_TabResize(tab, -6)
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

local function AddConditionToDropDown(conditionData)	
	local info = UIDropDownMenu_CreateInfo()
	info.func = CNDT.TypeMenu_DropDown_OnClick
	info.text = conditionData.text
	info.tooltipTitle = conditionData.text
	info.tooltipText = conditionData.tooltip
	info.tooltipOnButton = true
	info.value = conditionData.value
	info.arg1 = conditionData
	info.icon = get(conditionData.icon)
	if conditionData.tcoords then
		info.tCoordLeft = conditionData.tcoords[1]
		info.tCoordRight = conditionData.tcoords[2]
		info.tCoordTop = conditionData.tcoords[3]
		info.tCoordBottom = conditionData.tcoords[4]
	end
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	
	return true
end


function CNDT:TypeMenu_DropDown()	
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		local canAddSpacer
		for k, categoryData in ipairs(CNDT.Categories) do
			
			if categoryData.spaceBefore and canAddSpacer then
				TMW.AddDropdownSpacer()
			end

			local shouldAddCategory
			local CurrentConditionSet = CNDT.CurrentConditionSet
			
			for k, conditionData in ipairs(categoryData.conditionData) do
				local shouldAdd = not get(conditionData.hidden)
				
				if CurrentConditionSet.ConditionTypeFilter then
					if not CurrentConditionSet:ConditionTypeFilter(conditionData) then
						shouldAdd = false
					end
				end
				
				if not conditionData.IS_SPACER and shouldAdd then
					shouldAddCategory = true
					break
				end
			end
			
			local info = UIDropDownMenu_CreateInfo()
			info.text = categoryData.name
			info.value = categoryData.identifier
			info.notCheckable = true
			info.hasArrow = shouldAddCategory
			info.disabled = not shouldAddCategory
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			canAddSpacer = true
			
			if categoryData.spaceAfter and canAddSpacer then
				TMW.AddDropdownSpacer()
				canAddSpacer = false
			end
		end
		
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		local categoryData = CNDT.CategoriesByID[UIDROPDOWNMENU_MENU_VALUE]
		
		local queueSpacer
		local hasAddedOneCondition
		local lastButtonWasSpacer
		
		local CurrentConditionSet = CNDT.CurrentConditionSet
		
		for k, conditionData in ipairs(categoryData.conditionData) do
			local shouldAdd = not get(conditionData.hidden)
			
			if not conditionData.IS_SPACER and CurrentConditionSet.ConditionTypeFilter then
				if not CurrentConditionSet:ConditionTypeFilter(conditionData) then
					shouldAdd = false
				end
			end
			
			if shouldAdd then
				if conditionData.IS_SPACER then
					queueSpacer = true
				else
					if hasAddedOneCondition and queueSpacer then
						TMW.AddDropdownSpacer()
						queueSpacer = false
					end
					
					AddConditionToDropDown(conditionData)
					hasAddedOneCondition = true
				end
			end
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

function CndtGroup.TypeCheck(group, conditionData)
	if conditionData then
		local unit = conditionData.unit

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

		if conditionData.name then
			group.EditBox:Show()
			if type(conditionData.name) == "function" then
				conditionData.name(group.EditBox)
				group.EditBox:GetScript("OnTextChanged")(group.EditBox)
			else
				TMW:TT(group.EditBox)
			end
			if conditionData.check then
				conditionData.check(group.Check)
				group.Check:Show()
			else
				group.Check:Hide()
			end
			TMW.SUG:EnableEditBox(group.EditBox, conditionData.useSUG, not conditionData.allowMultipleSUGEntires)

			group.Slider:SetWidth(217)
			if conditionData.noslide then
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
		if conditionData.name2 then
			group.EditBox2:Show()
			if type(conditionData.name2) == "function" then
				conditionData.name2(group.EditBox2)
				group.EditBox2:GetScript("OnTextChanged")(group.EditBox2)
			else
				TMW:TT(group.EditBox2)
			end
			if conditionData.check2 then
				conditionData.check2(group.Check2)
				group.Check2:Show()
			else
				group.Check2:Hide()
			end
			TMW.SUG:EnableEditBox(group.EditBox2, conditionData.useSUG, not conditionData.allowMultipleSUGEntires)
			group.EditBox:SetWidth(250)
			group.EditBox2:SetWidth(250)
		else
			group.Check2:Hide()
			group.EditBox2:Hide()
			TMW.SUG:DisableEditBox(group.EditBox2)
		end

		if conditionData.nooperator then
			group.TextOperator:SetText("")
			group.Operator:Hide()
		else
			group.Operator:Show()
		end

		if conditionData.noslide then
			showval = false
			group.Slider:Hide()
			group.TextValue:SetText("")
			group.ValText:Hide()
		else
			group.ValText:Show()
			group.Slider:Show()
		end

		if conditionData.showhide then
			conditionData.showhide(group, conditionData)
		end
		
		TMW:Fire("TMW_CNDT_GROUP_TYPECHECK", group, conditionData)
		
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
	condition.Operator = UIDropDownMenu_GetSelectedValue(group.Operator) or "=="
	condition.Icon = UIDropDownMenu_GetSelectedValue(group.Icon) or ""
	condition.Level = tonumber(group.Slider:GetValue()) or 0
	condition.AndOr = group.AndOr:GetValue()
	condition.Name = strtrim(group.EditBox:GetText()) or ""
	condition.Name2 = strtrim(group.EditBox2:GetText()) or ""
	condition.Checked = not not group.Check:GetChecked()
	condition.Checked2 = not not group.Check2:GetChecked()
	
	
	condition.Unit = strtrim(group.Unit:GetText()) or "player"


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

