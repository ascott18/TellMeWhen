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



TMW.HELP:NewCode("CNDT_UNIT_MISSING", 10, false)
TMW.HELP:NewCode("CNDT_UNIT_ONLYONE", 20, false)


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
			CNDT.DynamicConditionTab:Show()
		
			-- Only click the tab if we are manually loading the conditionSet (should only happen on user input/hardware event)
			CNDT.DynamicConditionTab:ClickHandler()
			
			if ConditionSet.parentSettingType == "profile" then
				CNDT.DynamicConditionTab:SetTitleComponents(nil, nil)
			elseif ConditionSet.parentSettingType == "group" then
				CNDT.DynamicConditionTab:SetTitleComponents(nil, 1)
			else
				CNDT.DynamicConditionTab:SetTitleComponents(1, 1)
			end
			
		end
	else
		CNDT.DynamicConditionTab:Hide()
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

CNDT.DynamicConditionTab = TMW.Classes.IconEditorTab:NewTab("CNDTDYN", 25, "Conditions")
CNDT.DynamicConditionTab:SetTitleComponents()
CNDT.DynamicConditionTab:Hide()

TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED_CHANGED", function(event, icon)
	if TMW.IE.CurrentTab == CNDT.DynamicConditionTab then
		TMW.IE.MainTab:Click()
	end
end)
TMW:RegisterCallback("TMW_CONFIG_TAB_CLICKED", function(event, currentTab, oldTab)
	if oldTab == CNDT.DynamicConditionTab then
		CNDT.DynamicConditionTab:Hide()
	end
end)

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()	
	local CurrentConditionSet = CNDT.CurrentConditionSet
	
	if CurrentConditionSet and CurrentConditionSet.useDynamicTab and CurrentConditionSet.ShouldShowTab then
		if not CurrentConditionSet:ShouldShowTab() then
			if TMW.IE.CurrentTab == CNDT.DynamicConditionTab then
				TMW.IE.MainTab:Click()
			else
				CNDT.DynamicConditionTab:Hide()
			end
		end
	else
		CNDT.DynamicConditionTab:Hide()
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
		return tabText .. " (0)"
	end
	
	local parenthesesAreValid, errorMessage = CNDT:CheckParentheses(Conditions)
		
	if parenthesesAreValid then
		TMW.HELP:Hide("CNDT_PARENTHESES_ERROR")
	else
		TMW.HELP:Show{
			code = "CNDT_PARENTHESES_ERROR",
			icon = nil,
			relativeTo = TellMeWhen_IconEditor.Conditions,
			x = 0,
			y = 0,
			text = format(errorMessage)
		}
	end
	
	local n = Conditions.n

	if n > 0 then
		local prefix = (not parenthesesAreValid and "|TInterface\\AddOns\\TellMeWhen\\Textures\\Alert:0:2|t|cFFFF0000" or "")
		return prefix .. tabText .. " |cFFFF5959(" .. n .. ")"
	else
		return tabText .. " (" .. n .. ")"
	end
end

function CNDT:SetTabText(conditionSetName)
	local ConditionSet = CNDT.ConditionSets[conditionSetName] or CNDT.CurrentConditionSet
	
	local tab = ConditionSet.useDynamicTab and CNDT.DynamicConditionTab or ConditionSet:GetTab()
	
	tab:SetText(CNDT:GetTabText(conditionSetName))
	TMW:TT(tab, ConditionSet.tabText, ConditionSet.tabTooltip, 1, 1)
end


TMW:NewClass("Config_Slider_Condition", "Config_Slider")
{
	GetSettingTable = function(self)
		return self:GetParent():GetConditionSettings()
	end,


}

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
	local append = TMW.debug and not conditionData:ShouldList() and "(DBG)" or ""
	
	local info = TMW.DD:CreateInfo()
	
	info.func = CNDT.TypeMenu_DropDown_OnClick
	info.text = (conditionData.text or "??") .. append
	
	info.tooltipTitle = conditionData.text
	info.tooltipText = conditionData.tooltip
	
	info.value = conditionData.identifier
	info.arg1 = conditionData
	info.icon = get(conditionData.icon)

	info.disabled = get(conditionData.disabled)

	local group = TMW.DD:GetCurrentDropDown():GetParent()
	local conditionSettings = group:GetConditionSettings()
	info.checked = conditionData.identifier == conditionSettings.Type
	
	if conditionData.tcoords then
		info.tCoordLeft = conditionData.tcoords[1]
		info.tCoordRight = conditionData.tcoords[2]
		info.tCoordTop = conditionData.tcoords[3]
		info.tCoordBottom = conditionData.tcoords[4]
	end
	
	TMW.DD:AddButton(info)
end


function CNDT:TypeMenu_DropDown()	
	if TMW.DD.MENU_LEVEL == 1 then
		local canAddSpacer
		for k, categoryData in ipairs(CNDT.Categories) do
			
			if categoryData.spaceBefore and canAddSpacer then
				TMW.DD:AddSpacer()
			end

			local shouldAddCategory
			local CurrentConditionSet = CNDT.CurrentConditionSet
			
			for k, conditionData in ipairs(categoryData.conditionData) do
				if not conditionData.IS_SPACER then
					local shouldAdd = conditionData:ShouldList()
					
					if shouldAdd then
						shouldAddCategory = true
						break
					end
				end
			end
			
			local info = TMW.DD:CreateInfo()
			info.text = categoryData.name
			info.value = categoryData.identifier
			info.notCheckable = true
			info.hasArrow = shouldAddCategory
			info.disabled = not shouldAddCategory
			TMW.DD:AddButton(info)
			canAddSpacer = true
			
			if categoryData.spaceAfter and canAddSpacer then
				TMW.DD:AddSpacer()
				canAddSpacer = false
			end
		end
		
	elseif TMW.DD.MENU_LEVEL == 2 then
		local categoryData = CNDT.CategoriesByID[TMW.DD.MENU_VALUE]
		
		local queueSpacer
		local hasAddedOneCondition
		local lastButtonWasSpacer

		local group = TMW.DD:GetCurrentDropDown():GetParent()
		local conditionSettings = group:GetConditionSettings()
		
		local CurrentConditionSet = CNDT.CurrentConditionSet
		
		for k, conditionData in ipairs(categoryData.conditionData) do
			if conditionData.IS_SPACER then
				queueSpacer = true
			else
				local selected = conditionData.identifier == conditionSettings.Type
				local shouldAdd = selected or conditionData:ShouldList() --or TMW.debug
				
				if shouldAdd then
					if hasAddedOneCondition and queueSpacer then
						TMW.DD:AddSpacer()
						queueSpacer = false
					end
					
					AddConditionToDropDown(conditionData)
					hasAddedOneCondition = true
				end
			end
		end
	end
end

function CNDT:SelectType(CndtGroup, conditionData)

	local condition = CndtGroup:GetConditionSettings()
	if conditionData.defaultUnit and condition.Unit == "player" then
		condition.Unit = conditionData.defaultUnit
	end

	get(conditionData.applyDefaults, conditionData, condition)

	if condition.Type ~= conditionData.identifier then
		condition.Type = conditionData.identifier

		-- wipe this, since flags mean totally different things for different conditions.
		-- and having some flags set that a condition doesn't know about could screw things up.
		condition.BitFlags = 0
	end
	
	CndtGroup:LoadAndDraw()
	TMW.IE:ScheduleIconSetup()
	
	TMW.DD:CloseDropDownMenus()
end

function CNDT:TypeMenu_DropDown_OnClick(data)	
	local group = TMW.DD.OPEN_MENU:GetParent()

	CNDT:SelectType(group, data)
end


function CNDT:IconMenu_DropDown()
	if TMW.DD.MENU_LEVEL == 2 then
		for icon in TMW.DD.MENU_VALUE:InIcons() do
			if icon:IsValid() and CI.icon ~= icon and not icon:IsControlled() then
				local info = TMW.DD:CreateInfo()

				local text, textshort, tooltip = icon:GetIconMenuText()
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipText = tooltip

				info.arg1 = self
				info.value = icon
				info.func = CNDT.IconMenu_DropDown_OnClick

				local group = self:GetParent()
				local condition = group:GetConditionSettings()
				info.checked = condition.Icon == icon:GetGUID()

				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				info.icon = icon.attributes.texture
				TMW.DD:AddButton(info)
			end
		end
	elseif TMW.DD.MENU_LEVEL == 1 then
		for group in TMW:InGroups() do
			if group:ShouldUpdateIcons() then
				local info = TMW.DD:CreateInfo()
				info.text = group:GetGroupName()
				info.hasArrow = true
				info.notCheckable = true
				info.value = group
				TMW.DD:AddButton(info)
			end
		end
	end
end

function CNDT:IconMenu_DropDown_OnClick(frame)
	TMW.DD:CloseDropDownMenus()
	
	local icon = self.value
	local GUID = icon:GetGUID(true)
	
	frame:SetIcon(icon)

	local group = TMW.DD.OPEN_MENU:GetParent()
	local condition = group:GetConditionSettings()
	condition.Icon = GUID

	group:LoadAndDraw()
	TMW.IE:ScheduleIconSetup()
end


function CNDT:OperatorMenu_DropDown()
	local group = self:GetParent()
	local conditionData = group:GetConditionData()
	local conditionSettings = group:GetConditionSettings()

	for k, v in pairs(TMW.operators) do
		if (not conditionData.specificOperators or conditionData.specificOperators[v.value]) then
			local info = TMW.DD:CreateInfo()
			info.func = CNDT.OperatorMenu_DropDown_OnClick
			info.text = v.text
			info.value = v.value
			info.checked = conditionSettings.Operator == v.value
			info.tooltipTitle = v.tooltipText
			info.arg1 = self
			TMW.DD:AddButton(info)
		end
	end
end

function CNDT:OperatorMenu_DropDown_OnClick(frame)
	frame:SetUIDropdownText(self.value)
	TMW:TT(frame, self.tooltipTitle, nil, 1)
	
	local group = TMW.DD.OPEN_MENU:GetParent()
	local condition = group:GetConditionSettings()
	condition.Operator = self.value

	group:LoadAndDraw()
	TMW.IE:ScheduleIconSetup()
end

function CNDT:InBitflags(bitFlags)
	local tableValues = type(select(2, next(bitFlags))) == "table"
	return TMW:OrderedPairs(bitFlags, tableValues and TMW.OrderSort or nil, tableValues)
end

function CNDT:BitFlags_DropDown()
	local group = self:GetParent()
	local conditionData = group:GetConditionData()
	local conditionSettings = group:GetConditionSettings()

	local tableValues = type(select(2, next(conditionData.bitFlags))) == "table"

	for index, data in CNDT:InBitflags(conditionData.bitFlags) do
		local name = get(data, "text")

		local info = TMW.DD:CreateInfo()

		info.text = name

		if type(data) == "table" then
			info.tooltipTitle = name
			info.tooltipText = data.tooltip

			info.icon = data.icon

			if data.tcoords then
				info.tCoordLeft = data.tcoords[1]
				info.tCoordRight = data.tcoords[2]
				info.tCoordTop = data.tcoords[3]
				info.tCoordBottom = data.tcoords[4]
			end
		end


		info.value = index
		info.checked = CNDT:GetBitFlag(conditionSettings, index)
		info.keepShownOnClick = true
		info.isNotRadio = true
		info.func = CNDT.BitFlags_DropDown_OnClick
		info.arg1 = self

		TMW.DD:AddButton(info)

		if type(data) == "table" and data.space then
			TMW.DD:AddSpacer()
		end
	end
end

function CNDT:BitFlags_DropDown_OnClick(frame)	
	local group = frame:GetParent()
	local conditionSettings = group:GetConditionSettings()

	local index = self.value

	CNDT:ToggleBitFlag(conditionSettings, index)

	TMW.IE:ScheduleIconSetup()
	group:LoadAndDraw()
end




---------- Runes ----------
function CNDT:Rune_GetChecked()
	return self.checked
end

function CNDT:Rune_SetChecked(checked)
	if checked then
		self.checked = true
		self.Check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
	else
		self.checked = false
		self.Check:SetTexture(nil)
	end
end


---------- Parentheses ----------
CNDT.colors = setmetatable(
	{ -- hardcode the first few colors to make sure they look good
		"|cff00ff00",
		--"|cff0026ff",
		"|cffff004d",
		"|cff009bff",
		"|cffe9ff00",
		--"|cff00ff7c",
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

	self:SetPoint("TOPLEFT", CNDT[ID-1], "BOTTOMLEFT", 0, -16.5)

	--[[local p, _, rp, x, y = TMW.CNDT[1].AddDelete:GetPoint()
	self.AddDelete:ClearAllPoints()
	self.AddDelete:SetPoint(p, CNDT[ID], rp, x, y)]]
	
	self:Hide()
	
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self.Unit, "ClearFocus")
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self.EditBox, "ClearFocus")
	TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self.EditBox2, "ClearFocus")
end

function CndtGroup:LoadAndDraw()
	local conditionData = self:GetConditionData()
	local conditionSettings = self:GetConditionSettings()

	TMW.IE:ScheduleIconSetup()
	
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
			CndtGroup.Unit:SetWidth(120)
			
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


	local text = conditionData and conditionData.text or conditionSettings.Type
	local tooltip = conditionData and conditionData.tooltip
	--CndtGroup.Type:SetText("")

	if not conditionData or conditionData.identifier ~= "" then
		CndtGroup.Type.EditBox:SetText(text)
		CndtGroup.Type.EditBox:SetCursorPosition(0)
	else
		CndtGroup.Type.EditBox:SetText("")
	end

	TMW:TT(CndtGroup.Type, text, tooltip, 1, 1)
	TMW:TT(CndtGroup.Type.EditBox, text, tooltip, 1, 1)
end)

-- Operator
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if not conditionData or conditionData.nooperator then
		CndtGroup.TextOperator:SetText(nil)
		CndtGroup.Operator:Hide()
	else
		CndtGroup.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
		CndtGroup.Operator:Show()

		local v = CndtGroup.Operator:SetUIDropdownText(conditionSettings.Operator, TMW.operators)
		if v then
			TMW:TT(CndtGroup.Operator, v.tooltipText, nil, 1)
		end
	end
end)

-- Icon
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)

	if conditionData and conditionData.isicon then
		local GUID = conditionSettings.Icon
		CndtGroup.Icon:SetGUID(GUID)

		CndtGroup.TextIcon:SetText(L["ICONTOCHECK"])
		CndtGroup.Icon:Show()
		if conditionData.nooperator then
			CndtGroup.Icon:SetWidth(196)
		else
			CndtGroup.Icon:SetWidth(134)
		end
	else
		CndtGroup.TextIcon:SetText(nil)
		CndtGroup.Icon:Hide()
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
		TMW.HELP:Show{
			code = "CNDT_PARENTHESES_FIRSTSEE",
			icon = nil,
			relativeTo = CNDT[1].OpenParenthesis,
			x = 0,
			y = 0,
			text = format(TMW.L["HELP_CNDT_PARENTHESES_FIRSTSEE"])
		}
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
		TMW.HELP:Show{
			code = "CNDT_ANDOR_FIRSTSEE",
			icon = nil,
			relativeTo = CndtGroup.AndOr,
			x = 0,
			y = 0,
			text = format(TMW.L["HELP_CNDT_ANDOR_FIRSTSEE"])
		}
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
			
			CndtGroup.TextValue:SetText(nil)
			CndtGroup.ValText:Hide()
		else
			CndtGroup.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
			
			
			
			
			


			-- Don't try and format text while changing parameters because we might get some errors trying
			-- to format unexpected values
			CndtGroup.Slider:SetTextFormatter(nil)

			CndtGroup.Slider:SetValueStep(get(conditionData.step) or 1)
			CndtGroup.Slider:SetMinMaxValues(get(conditionData.min) or 0, get(conditionData.max))

			if get(conditionData.range) then
				CndtGroup.Slider:SetMode(CndtGroup.Slider.MODE_ADJUSTING)
				CndtGroup.Slider:SetRange(get(conditionData.range))
			else
				CndtGroup.Slider:SetMode(CndtGroup.Slider.MODE_STATIC)
			end
			CndtGroup.Slider:Show()
			CndtGroup.Slider:ReloadSetting()
			CndtGroup.Slider:SaveSetting()

			TMW:TT_Update(CndtGroup.Slider)


			CndtGroup.Slider:SetTextFormatter(conditionData.formatter)

			if conditionData.midt then
				local min, max = CndtGroup.Slider:GetMinMaxValues()
				local mid = ((max-min)/2)+min
				if conditionData.midt == true then
					mid = conditionData.formatter:Format(mid)
				else
					mid = get(conditionData.midt, mid)
				end

				CndtGroup.Slider:SetStaticMidText(mid)
			else
				CndtGroup.Slider:SetStaticMidText("")
			end

			local val = CndtGroup.Slider:GetValue()
			conditionData.formatter:SetFormattedText(CndtGroup.ValText, val)
			CndtGroup.ValText:Show()
			

		end
	else
		CndtGroup.TextValue:SetText(nil)
		CndtGroup.Check:Hide()
		CndtGroup.EditBox:Hide()
		CndtGroup.Check2:Hide()
		CndtGroup.EditBox2:Hide()
		CndtGroup.Slider:Hide()
		CndtGroup.ValText:Hide()
	end
end)

-- Runes
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData and conditionData.runesConfig then

		for k, rune in pairs(CndtGroup.Runes) do
			if type(rune) == "table" then
				local index = rune.key
				rune:SetChecked(CNDT:GetBitFlag(conditionSettings, index))
			end
		end

		CndtGroup.Runes:Show()
		CndtGroup.Slider:SetWidth(217)
	else
		CndtGroup.Runes:Hide()
	end
end)

-- BitFlags dropdown
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)

	if conditionData and conditionData.bitFlags then
		CndtGroup.BitFlags:Show()
		CndtGroup.BitFlagsCheck:Show()
		CndtGroup.BitFlagsSelectedText:Show()

		CndtGroup.BitFlagsCheck:SetChecked(conditionSettings.Checked)
		CndtGroup.BitFlags:SetText(conditionData.bitFlagTitle)

		CndtGroup.BitFlags:ClearAllPoints()
		if CndtGroup.Unit:IsShown() then
			CndtGroup.BitFlags:SetPoint("LEFT", CndtGroup.Unit, "RIGHT", 8, -3)
			CndtGroup.BitFlags:SetWidth(150)
			CndtGroup.Unit:SetWidth(90)
		else
			CndtGroup.BitFlags:SetPoint("TOPLEFT", CndtGroup.Type, "TOPRIGHT", 15, 0)
			CndtGroup.BitFlags:SetWidth(190)
		end

		-- Auto switch to a table if there are too many options for numeric bit flags.
		if type(conditionSettings.BitFlags) == "number" then

			local switch
			for index, _ in pairs(conditionData.bitFlags) do
				if type(index) ~= "number" or index >= 32 or index < 1 then
					switch = true
					break
				end
			end

			if switch then
				local flagsOld = conditionSettings.BitFlags
				conditionSettings.BitFlags = {}

				for index, _ in pairs(conditionData.bitFlags) do
					if type(index) == "number" and index < 32 and index >= 1 then
						local flag = bit.lshift(1, index-1)
						local flagSet = bit.band(flagsOld, flag) == flag
						conditionSettings.BitFlags[index] = flagSet and true or nil
					end
				end
			end
		end

		local text = ""
		for index, data in CNDT:InBitflags(conditionData.bitFlags) do
			local name = get(data, "text")
			local flagSet = CNDT:GetBitFlag(conditionSettings, index)

			if flagSet then
				if conditionSettings.Checked then
					local Not = L["CONDITIONPANEL_BITFLAGS_NOT"]
					if text ~= "" then
						Not = Not:lower()
					end

					name = Not .. " " .. name
				end

				if text == "" then
					text = name
				else
					text = text .. ", " .. name
				end
			end
		end

		local operator = conditionSettings.Checked and L["CONDITIONPANEL_AND"] or L["CONDITIONPANEL_OR"]
		text = text:gsub(", ([^,]*)$", ", " .. operator:lower() .. " %1")

		if text == "" then
			if conditionSettings.Checked then
				text = L["CONDITIONPANEL_BITFLAGS_ALWAYS"]
			else
				text = L["CONDITIONPANEL_BITFLAGS_NEVER"]
			end
			text = "<|cffaaaaaa" .. text .. "|r>"
		end
		CndtGroup.BitFlagsSelectedText:SetText(L["CONDITIONPANEL_BITFLAGS_SELECTED"] .. " " .. text)

	else
		CndtGroup.BitFlags:Hide()
		CndtGroup.BitFlagsCheck:Hide()
		CndtGroup.BitFlagsSelectedText:Hide()
	end

end)

-- Deprecated/Unknown
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData then
		CndtGroup.Unknown:SetText()

		if conditionData.funcstr == "DEPRECATED" then
			CndtGroup.Deprecated:SetFormattedText(TMW.L["CNDT_DEPRECATED_DESC"], get(conditionData.text))

			if CndtGroup.Deprecated:IsShown() then
				CndtGroup:SetHeight(CndtGroup:GetHeight() - CndtGroup.Deprecated:GetHeight())
				CndtGroup.Deprecated:Hide()
			end
			if not CndtGroup.Deprecated:IsShown() then
				-- Need to reset the height to 0 before calling GetStringHeight
				-- for consistency. Causes weird behavior if we don't do this.
				CndtGroup.Deprecated:SetHeight(0)
				CndtGroup.Deprecated:SetHeight(CndtGroup.Deprecated:GetStringHeight())

				CndtGroup:SetHeight(CndtGroup:GetHeight() + CndtGroup.Deprecated:GetHeight())
				CndtGroup.Deprecated:Show()
			end
		elseif not conditionData.customDeprecated then
			if CndtGroup.Deprecated:IsShown() then
				CndtGroup:SetHeight(CndtGroup:GetHeight() - CndtGroup.Deprecated:GetHeight())
				CndtGroup.Deprecated:Hide()
			end
		end
	else
		CndtGroup.Unknown:SetFormattedText(TMW.L["CNDT_UNKNOWN_DESC"], conditionSettings.Type)
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



local SUG = TMW.SUG
local strfindsug = SUG.strfindsug
local Module = SUG:NewModule("conditions", SUG:GetModule("default"), "AceEvent-3.0")
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
function Module:Table_Get()
	return CNDT.ConditionsByType
end
function Module.Sorter_ByName(a, b)
	local nameA, nameB = CNDT.ConditionsByType[a].text, CNDT.ConditionsByType[b].text
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end
function Module:Table_GetSorter()
	return self.Sorter_ByName
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	for identifier, conditionData in pairs(tbl) do
		local text = conditionData.text
		text = text and text:lower()
		if conditionData:ShouldList() and text and (strfindsug(text) or strfind(text, SUG.lastName)) then
			suggestions[#suggestions + 1] = identifier
		end
	end
end
function Module:Entry_AddToList_1(f, identifier)
	local conditionData = CNDT.ConditionsByType[identifier]

	f.Name:SetText(conditionData.text)

	f.insert = identifier

	f.tooltiptitle = conditionData.text
	f.tooltiptext = conditionData.category.name
	if conditionData.tooltip then
		f.tooltiptext = f.tooltiptext .. "\r\n\r\n" .. conditionData.tooltip
	end

	f.Icon:SetTexture(get(conditionData.icon))
	if conditionData.tcoords then
		f.Icon:SetTexCoord(unpack(conditionData.tcoords))
	end
end
function Module:Entry_OnClick(frame, button)
	local CndtGroup = SUG.Box:GetParent():GetParent()

	CNDT:SelectType(CndtGroup, CNDT.ConditionsByType[frame.insert])
	
	SUG.Box:ClearFocus()
end

