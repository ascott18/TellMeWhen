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

local CI = TMW.CI
local get = TMW.get

local _G = _G
local pairs, ipairs, wipe, tinsert, tremove, rawget, tonumber, tostring, type = 
	  pairs, ipairs, wipe, tinsert, tremove, rawget, tonumber, tostring, type
local strtrim, gsub, min, max = 
	  strtrim, gsub, min, max

local SLIDER_INPUTBOX_ENABLEALL = false -- toggle for allowing the right-click slider input box for all conditions, or just those with a range (and no max value)
local AUTO_LOAD_SLIDERINPUTBOX_THRESHOLD = 10e5
L["CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER_DISALLOWED"] = L["CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER_DISALLOWED"]:format(BreakUpLargeNumbers(AUTO_LOAD_SLIDERINPUTBOX_THRESHOLD))

-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE, UIDROPDOWNMENU_OPEN_MENU
-- GLOBALS: UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, UIDropDownMenu_SetText, UIDropDownMenu_GetSelectedValue
-- GLOBALS: CloseDropDownMenus


local CNDT = TMW.CNDT -- created in TellMeWhen/conditions.lua


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
		
			-- Only click the tab if we are manually loading the conditionSet (should only happen on user input/hardware event)
			TMW.IE:TabClick(TMW.IE.DynamicConditionTab)
		end
	else
		TMW.IE.DynamicConditionTab:Hide()
	end
	
	
	CNDT.settings = ConditionSet:GetSettings()	
	if not CNDT.settings then return end
	
	
	TMW.HELP:Hide("CNDT_UNIT_MISSING")
	
	local n = CNDT.settings.n
	
	for i = n + 1, #CNDT do
		CNDT[i]:Hide()
	end
		
	if n > 0 then
		CNDT:CreateGroups(n+1)

		for i in TMW:InNLengthTable(CNDT.settings) do
			CNDT[i]:Show()
			CNDT[i]:LoadAndDraw()
		end
	end
	
	local AddCondition = TellMeWhen_IconEditor.Conditions.Groups.AddCondition
	AddCondition:SetPoint("TOPLEFT", CNDT[n+1])
	AddCondition:SetPoint("TOPRIGHT", CNDT[n+1])
	
	CNDT:ColorizeParentheses()
end

TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function()
	-- This is encapsulated in a function because LoadConfig excepts arg2 to be a conditionSetName,
	-- but it would end up being an event or an icon if CNDT.LoadConfig were registed as the callback.
	CNDT:LoadConfig()
end)



-- Dynamic Conditions Tab handling
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



function CNDT:GetTabText(conditionSetName)
	local ConditionSet = CNDT.CurrentConditionSet
	if conditionSetName then
		ConditionSet = CNDT.ConditionSets[conditionSetName]
	end
	
	if not ConditionSet then
		return "<ERROR: SET NOT FOUND!>"
	end
	
	local Conditions = ConditionSet:GetSettings()
	local tabText = ConditionSet.tabText
	
	if not Conditions then
		return "<ERROR: SETTINGS NOT FOUND!>"
	end
	
	local parenthesesAreValid, errorMessage = CNDT:CheckParentheses(Conditions)
		
	if parenthesesAreValid then
		TMW.HELP:Hide("CNDT_PARENTHESES_ERROR")
	else
		TMW.HELP:Show("CNDT_PARENTHESES_ERROR", nil, TellMeWhen_IconEditor.Conditions, 0, 0, errorMessage)
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
	TMW:TT(tab, ConditionSet.tabText, ConditionSet.tabTooltip, 1, 1)

	if tab:IsShown() then
		PanelTemplates_TabResize(tab, -6)
	end
end



function CNDT:ValidateLevelForCondition(level, conditionType)
	local conditionData = CNDT.ConditionsByType[conditionType]
	
	if not conditionData then
		return level
	end
	
	level = tonumber(level) or 0
	
	-- Round to the nearest step
	local step = get(conditionData.step) or 1
	level = floor(level * (1/step) + 0.5) / (1/step)
	
	-- Constrain to min/max
	local vmin = get(conditionData.min or 0)
	local vmax = get(conditionData.max)
	if vmin and level < vmin then
		level = vmin
	elseif vmax and level > vmax then
		level = vmax
	end
	
	--level = max(level, 0)
	
	return level
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
	local append = TMW.debug and get(conditionData.hidden) and "(DBG)" or ""
	
	local info = UIDropDownMenu_CreateInfo()
	
	info.func = CNDT.TypeMenu_DropDown_OnClick
	info.text = (conditionData.text or "??") .. append
	
	info.tooltipTitle = conditionData.text
	info.tooltipText = conditionData.tooltip
	info.tooltipOnButton = true
	
	info.value = conditionData.identifier
	info.arg1 = conditionData
	info.icon = get(conditionData.icon)
	
	if conditionData.tcoords then
		info.tCoordLeft = conditionData.tcoords[1]
		info.tCoordRight = conditionData.tcoords[2]
		info.tCoordTop = conditionData.tcoords[3]
		info.tCoordBottom = conditionData.tcoords[4]
	end
	
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
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
			local shouldAdd = not get(conditionData.hidden) --or TMW.debug
			
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
	UIDROPDOWNMENU_OPEN_MENU.selectedValue = self.value
	UIDropDownMenu_SetText(UIDROPDOWNMENU_OPEN_MENU, data.text)
	
	local group = UIDROPDOWNMENU_OPEN_MENU:GetParent()
	
	local condition = group:GetConditionSettings()
	if data.defaultUnit and condition.Unit == "player" then
		condition.Unit = data.defaultUnit
	end
	condition.Type = self.value
	
	group:LoadAndDraw()
	group:SetSliderMinMax()
	
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
				info.text = TMW:GetGroupName(groupID, groupID)
				info.hasArrow = true
				info.notCheckable = true
				info.value = groupID
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end

function CNDT:IconMenu_DropDown_OnClick(frame)
	TMW:SetUIDropdownIconText(frame, self.value)
	frame.IconPreview:SetIcon(_G[self.value])
	CloseDropDownMenus()
	
	local group = UIDROPDOWNMENU_OPEN_MENU:GetParent()
	local condition = group:GetConditionSettings()
	condition.Icon = self.value
end


function CNDT:OperatorMenu_DropDown()
	for k, v in pairs(TMW.operators) do
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
	
	local group = UIDROPDOWNMENU_OPEN_MENU:GetParent()
	local condition = group:GetConditionSettings()
	condition.Operator = self.value
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
		"|cffe9ff00",
		"|cff00ff7c",
		"|cffff6700",
		"|cffaf79ff",
		"|cffff00c2",
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
function CNDT:CreateGroups(num)
	local start = #CNDT + 1

	for i=start, num do
		TMW.Classes.CndtGroup:New("Frame", "TellMeWhen_IconEditorConditionsGroupsGroup" .. i, TellMeWhen_IconEditor.Conditions.Groups, "TellMeWhen_ConditionGroup", i)
	end
end

function CNDT:AddCondition(Conditions)
	Conditions.n = Conditions.n + 1
	
	TMW:Fire("TMW_CNDT_CONDITION_ADDED", Conditions[Conditions.n])
	
	return Conditions[Conditions.n]
end

function CNDT:DeleteCondition(Conditions, n)
	Conditions.n = Conditions.n - 1
	
	TMW:Fire("TMW_CNDT_CONDITION_DELETED", n)
	
	return tremove(Conditions, n)
end


---------- CndtGroup Class ----------
local CndtGroup = TMW:NewClass("CndtGroup", "Frame")

function CndtGroup:OnNewInstance()
	local ID = self:GetID()
	
	CNDT[ID] = self

	self:SetPoint("TOPLEFT", CNDT[ID-1], "BOTTOMLEFT", 0, -14.5)

	--[[local p, _, rp, x, y = TMW.CNDT[1].AddDelete:GetPoint()
	self.AddDelete:ClearAllPoints()
	self.AddDelete:SetPoint(p, CNDT[ID], rp, x, y)]]
	
	self:Hide()
	
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", "ClearFocus", self.Unit)
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", "ClearFocus", self.EditBox)
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", "ClearFocus", self.EditBox2)
end

function CndtGroup:LoadAndDraw()
	local conditionData = self:GetConditionData()
	local conditionSettings = self:GetConditionSettings()
	
	TMW:Fire("TMW_CNDT_GROUP_DRAWGROUP", self, conditionData, conditionSettings)
end

-- LoadAndDraw handlers:
-- Unit
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData then
		local unit = conditionData.unit
	
		if unit == nil then
			-- Normal unit input and configuration
			CndtGroup.Unit:Show()
			CndtGroup.Unit:SetText(conditionSettings.Unit)
			
			CndtGroup.TextUnitDef:SetText(nil)
			CndtGroup.TextUnit:SetText(L["CONDITIONPANEL_UNIT"])
			
			-- Set default behavior for the editbox. This all may be overridden by other callbacks if needed.
			TMW.SUG:EnableEditBox(CndtGroup.Unit, "units", true)
			CndtGroup.Unit.label = "|cFFFF5050" .. TMW.L["CONDITIONPANEL_UNIT"] .. "!|r"
			TMW:TT(CndtGroup.Unit, "CONDITIONPANEL_UNIT", "ICONMENU_UNIT_DESC_CONDITIONUNIT")
			
		elseif unit == false then
			-- No unit, hide editbox and static text
			CndtGroup.Unit:Hide()
			
			CndtGroup.TextUnit:SetText(nil)
			CndtGroup.TextUnitDef:SetText(nil)
			
		elseif type(unit) == "string" then
			-- Static text in place of the editbox
			CndtGroup.Unit:Hide()
			
			CndtGroup.TextUnit:SetText(L["CONDITIONPANEL_UNIT"])
			CndtGroup.TextUnitDef:SetText(unit)
		end
	else
		CndtGroup.Unit:Hide()
		
		CndtGroup.TextUnit:SetText(nil)
		CndtGroup.TextUnitDef:SetText(nil)
	end
end)

-- Type
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	CndtGroup.Type:Show()
	CndtGroup.TextType:SetText(L["CONDITIONPANEL_TYPE"])

	CndtGroup.Type.selectedValue = conditionSettings.Type
	UIDropDownMenu_SetText(CndtGroup.Type, conditionData and conditionData.text or (conditionSettings.Type .. ": UNKNOWN TYPE"))
end)

-- Operator
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if not conditionData or conditionData.nooperator then
		CndtGroup.TextOperator:SetText(nil)
		CndtGroup.Operator:Hide()
	else
		CndtGroup.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
		CndtGroup.Operator:Show()

		local v = TMW:SetUIDropdownText(CndtGroup.Operator, conditionSettings.Operator, TMW.operators)
		if v then
			TMW:TT(CndtGroup.Operator, v.tooltipText, nil, 1)
		end
	end
end)

-- Icon
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)


	TMW:SetUIDropdownIconText(CndtGroup.Icon, conditionSettings.Icon)
	CndtGroup.Icon.IconPreview:SetIcon(_G[conditionSettings.Icon])
end)

-- Runes
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)

	for k, rune in pairs(CndtGroup.Runes) do
		if type(rune) == "table" then
			rune:SetChecked(conditionSettings.Runes[rune:GetID()])
		end
	end
end)

-- Parentheses
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)

	for k, frame in pairs(CndtGroup.OpenParenthesis) do
		if type(frame) == "table" then
			CndtGroup.OpenParenthesis[k]:SetChecked(conditionSettings.PrtsBefore >= k)
		end
	end
	for k, frame in pairs(CndtGroup.CloseParenthesis) do
		if type(frame) == "table" then
			CndtGroup.CloseParenthesis[k]:SetChecked(conditionSettings.PrtsAfter >= k)
		end
	end
	
	if CNDT.settings.n >= 3 then
		CndtGroup.CloseParenthesis:Show()
		CndtGroup.OpenParenthesis:Show()
	else
		CndtGroup.CloseParenthesis:Hide()
		CndtGroup.OpenParenthesis:Hide()
	end
	
	if CndtGroup:GetID() == 3 and CndtGroup:IsVisible() then
		TMW.HELP:Show("CNDT_PARENTHESES_FIRSTSEE", nil, CNDT[1].OpenParenthesis, 0, 0, TMW.L["HELP_CNDT_PARENTHESES_FIRSTSEE"])
	end
end)
TMW.HELP:NewCode("CNDT_PARENTHESES_FIRSTSEE", 101, true)

-- Up/Down
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)

	local ID = CndtGroup:GetID()
	local n = CNDT.settings.n
	
	if ID == 1 then
		CndtGroup.Up:Hide()
	else
		CndtGroup.Up:Show()
	end
	if ID == n then
		CndtGroup.Down:Hide()
	else
		CndtGroup.Down:Show()
	end
end)

-- And/Or
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)

	CndtGroup.AndOr:SetValue(conditionSettings.AndOr)
	
	if CndtGroup:GetID() == 2 and CndtGroup:IsVisible() then
		TMW.HELP:Show("CNDT_ANDOR_FIRSTSEE", nil, CndtGroup.AndOr, 0, 0, TMW.L["HELP_CNDT_ANDOR_FIRSTSEE"])
	end
end)
TMW.HELP:NewCode("CNDT_ANDOR_FIRSTSEE", 100, true)

-- Second Row
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData then
		if conditionData.name then
			CndtGroup.EditBox:Show()
			CndtGroup.EditBox:SetText(conditionSettings.Name)
		
			if type(conditionData.name) == "function" then
				conditionData.name(CndtGroup.EditBox)
				CndtGroup.EditBox:GetScript("OnTextChanged")(CndtGroup.EditBox)
			else
				TMW:TT(CndtGroup.EditBox, nil, nil)
			end
			if conditionData.check then
				conditionData.check(CndtGroup.Check)
				CndtGroup.Check:Show()
				CndtGroup.Check:SetChecked(conditionSettings.Checked)
			else
				CndtGroup.Check:Hide()
			end
			TMW.SUG:EnableEditBox(CndtGroup.EditBox, conditionData.useSUG, not conditionData.allowMultipleSUGEntires)

			CndtGroup.Slider:SetWidth(217)
			if conditionData.noslide then
				CndtGroup.EditBox:SetWidth(520)
			else
				CndtGroup.EditBox:SetWidth(295)
			end
		else
			CndtGroup.EditBox:Hide()
			CndtGroup.Check:Hide()
			CndtGroup.Slider:SetWidth(522)
			TMW.SUG:DisableEditBox(CndtGroup.EditBox)
		end
		
		if conditionData.name2 then
			CndtGroup.EditBox2:Show()
			CndtGroup.EditBox2:SetText(conditionSettings.Name2)
		
			if type(conditionData.name2) == "function" then
				conditionData.name2(CndtGroup.EditBox2)
				CndtGroup.EditBox2:GetScript("OnTextChanged")(CndtGroup.EditBox2)
			else
				TMW:TT(CndtGroup.EditBox2, nil, nil)
			end
			if conditionData.check2 then
				conditionData.check2(CndtGroup.Check2)
				CndtGroup.Check2:Show()
				CndtGroup.Check2:SetChecked(conditionSettings.Checked2)
			else
				CndtGroup.Check2:Hide()
			end
			TMW.SUG:EnableEditBox(CndtGroup.EditBox2, conditionData.useSUG, not conditionData.allowMultipleSUGEntires)
			CndtGroup.EditBox:SetWidth(250)
			CndtGroup.EditBox2:SetWidth(250)
		else
			CndtGroup.Check2:Hide()
			CndtGroup.EditBox2:Hide()
			TMW.SUG:DisableEditBox(CndtGroup.EditBox2)
		end

		

		if conditionData.noslide then
			CndtGroup.Slider:Hide()
			CndtGroup.SliderInputBox:Hide()
			
			CndtGroup.TextValue:SetText(nil)
			CndtGroup.ValText:Hide()
		else
			CndtGroup.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
			
			
			CndtGroup:SetSliderMinMax(conditionSettings.Level or 0)
			
			local val = conditionSettings.Level
			
			CndtGroup.ValText:SetText(get(conditionData.texttable, val) or val)
			CndtGroup.ValText:Show()
			
			-- If neither the slider or input box are already shown, show the slider
			-- (don't show the slider unconditionally because otherwise every time :LoadAndDraw() is called the editbox will be hidden)
			if not CndtGroup.Slider:IsShown() and not CndtGroup.SliderInputBox:IsShown() then
				CndtGroup.Slider:Show()
			end
			
			
			TMW:TT(CndtGroup.SliderInputBox, nil, "CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER")
			CndtGroup.SliderInputBox.__noWrapTooltipText = true
			
			if CndtGroup:GetSliderEditBoxAllowance() then
				-- Show the tooltip hinting about toggling if toggling is possible.
				TMW:TT(CndtGroup.Slider, nil, "CNDT_SLIDER_DESC_CLICKSWAP_TOMANUAL")
				
				if not CndtGroup:GetSliderAllowance() then
					TMW:TT(CndtGroup.SliderInputBox, nil, "CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER_DISALLOWED")
					CndtGroup.SliderInputBox.__noWrapTooltipText = nil
					CndtGroup.SliderInputBox:Show()
				end
			else
				-- Otherwise, don't include the part about toggling
				TMW:TT(CndtGroup.Slider, nil, nil)
				
				-- Switch back to the slider.
				CndtGroup.Slider:Show()
			end
			
			TMW:TT_Update(CndtGroup.Slider)
			TMW:TT_Update(CndtGroup.SliderInputBox)

		end
	else
		CndtGroup.TextValue:SetText(nil)
		CndtGroup.Check:Hide()
		CndtGroup.EditBox:Hide()
		CndtGroup.Check2:Hide()
		CndtGroup.EditBox2:Hide()
		CndtGroup.Slider:Hide()
		CndtGroup.SliderInputBox:Hide()
		CndtGroup.ValText:Hide()
	end

end)


function CndtGroup:UpOrDown(delta)
	local ID = self:GetID()
	local settings = CNDT.settings
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	CNDT:LoadConfig()
end

function CndtGroup:DeleteHandler()
	CNDT:DeleteCondition(CNDT.settings, self:GetID())
	CNDT:LoadConfig()
end

function CndtGroup:SetSliderMinMax(level)
	-- level is passed in only when the setting is changing or being loaded
	
	local data = self:GetConditionData()
	if not data then return end
	
	level = level and CNDT:ValidateLevelForCondition(level, data.identifier)
	
	local Slider = self.Slider
	local SliderInputBox = self.SliderInputBox
	
	
	if data.range then
		local deviation = get(data.range)/2
		local val = level or Slider:GetValue()

		local newmin = max(0, val-deviation)
		local newmax = max(deviation, val + deviation)

		Slider:SetMinMaxValues(newmin, newmax)
		Slider.Low:SetText(get(data.texttable, newmin) or newmin)
		Slider.High:SetText(get(data.texttable, newmax) or newmax)
	else
		local vmin = get(data.min)
		local vmax = get(data.max)
		Slider:SetMinMaxValues(vmin or 0, vmax or 1)
		Slider.Low:SetText(get(data.texttable, vmin) or data.mint or vmin or 0)
		Slider.High:SetText(get(data.texttable, vmax) or data.maxt or vmax or 1)
	end

	local Min, Max = Slider:GetMinMaxValues()
	local Mid
	if data.Mid == true then
		Mid = get(data.texttable, ((Max-Min)/2)+Min) or ((Max-Min)/2)+Min
	else
		Mid = get(data.midt, ((Max-Min)/2)+Min)
	end
	Slider.Mid:SetText(Mid)

	Slider:SetValueStep(get(data.step) or 1)
	
	if level then
		Slider:SetValue(level)
		SliderInputBox:SetText(level)
		
		self:GetConditionSettings().Level = level
	end
	
	return level
end

function CndtGroup:GetSliderEditBoxAllowance()
	local conditionData = self:GetConditionData()
	return conditionData.range or SLIDER_INPUTBOX_ENABLEALL
end

function CndtGroup:GetSliderAllowance()
	local conditionSettings = self:GetConditionSettings()
	return not self:GetSliderEditBoxAllowance() or conditionSettings.Level <= AUTO_LOAD_SLIDERINPUTBOX_THRESHOLD
end


function CndtGroup:GetConditionSettings()
	if CNDT.settings then
		return CNDT.settings[self:GetID()]
	end
end

function CndtGroup:GetConditionData()
	local condition = self:GetConditionSettings()
	if condition then
		return CNDT.ConditionsByType[condition.Type]
	end
end


