-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local Type = rawget(TMW.Types, "buffcontainer")

if not Type then return end

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_UNDERLAY = TMW.CONST.STATE.DEFAULT_HIDE

-- Shared with the runtime half in buffcontainer.lua, which owns all three.
local SortMethods, SortOrder = Type.SortMethods, Type.SortOrder
local GetDetection, GetLimitations = Type.GetDetection, Type.GetLimitations

-- What TellMeWhen_TextPanel breaks lines on.
local LINE = "\r\n"


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "buffcontainer",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

local function CurrentIconDetectsAbsence()
	if not TMW.CI.ics then return false end
	local _, blockers = GetDetection(TMW.CI.ics, TMW.CI.icon)
	return not blockers
end

-- What the current settings get wrong or give up, and nothing else - every limit this type
-- carries is conditional, and the panel takes itself out entirely when none of them bite.
-- There's no line for the good case: the state below is labelled Absent rather than Underlay
-- whenever detection is running, which says it in the place it applies.
Type:RegisterConfigPanel_XMLTemplate(110, "TellMeWhen_TextPanel", {
	frameName = "TellMeWhen_BuffContainerLimitations",
	OnSetup = function(self)
		-- The layout shows every panel, calls Setup, then checks IsShown() to decide whether it
		-- joins the column, so Setup is the one place a panel can take itself out. It runs on
		-- every reload, so the panel comes back the moment something does go wrong.
		local _, blockers = GetDetection(TMW.CI.ics, TMW.CI.icon)
		if not blockers and not GetLimitations(TMW.CI.ics) then
			self:Hide()
			return
		end

		self:SetTitle(L["ICONMENU_BUFFDEBUFF_CONTAINER_CAVEATS"])

		-- OnSetup runs on every icon load and CScriptAdd doesn't dedupe.
		if self.tmwLimitationsPanelBuilt then return end
		self.tmwLimitationsPanelBuilt = true

		self:CScriptAdd("ReloadRequested", function(panel)
			local sections = {}

			local limits, advice = GetLimitations(TMW.CI.ics)
			if limits then
				local section = "|cffff5959" .. table.concat(limits, LINE) .. "|r"
				if advice then
					section = section .. LINE .. "|cffcccccc" .. advice .. "|r"
				end
				sections[#sections + 1] = section
			end

			local _, blockers = GetDetection(TMW.CI.ics, TMW.CI.icon)
			if blockers then
				sections[#sections + 1] = "|cffff5959" .. L["ICONMENU_AURACONTAINER_CDM_OFF"] .. "|r" .. LINE
					.. "|cffcccccc" .. table.concat(blockers, LINE) .. "|r"
			end

			panel.text:SetText(table.concat(sections, LINE .. LINE))
		end)
	end,
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_BuffOrDebuffContainer", function(self)
	self:SetTitle(TMW.L["ICONMENU_BUFFTYPE"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 2,
		function(check)
			check:SetTexts("|cFF00FF00" .. L["ICONMENU_BUFF"], nil)
			check:SetSetting("BuffOrDebuff", "HELPFUL")
		end,
		function(check)
			check:SetTexts("|cFFFF0000" .. L["ICONMENU_DEBUFF"], nil)
			check:SetSetting("BuffOrDebuff", "HARMFUL")
		end,
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(125, "TellMeWhen_BuffContainerSettings", function(self)
	-- The base name, not Type.name: the "(combat ready)" half is there to tell the two
	-- Buff/Debuff types apart in the type dropdown, and the panel heading isn't choosing.
	self:SetTitle(L["ICONMENU_BUFFDEBUFF"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 2,
		function(check)
			check:SetTexts(L["ICONMENU_ONLYMINE"], L["ICONMENU_ONLYMINE_DESC"])
			check:SetSetting("OnlyMine")
		end,
		function(check)
			-- Helpful auras only (see BuildAuraSpec / candidateFilters.isStealable).
			check:SetTexts(L["ICONMENU_STEALABLE"], L["ICONMENU_STEALABLE_DESC"])
			check:SetSetting("Stealable")
		end,
	})

	local AuraFilterKeys = {
		"Important",
		"CrowdControl",
		"BigDefensive",
		"ExternalDefensive",
		"RaidPlayerDispellable",
		"Raid",
		"RaidInCombat",
	}

	local AuraFilterData = {}
	for _, key in ipairs(AuraFilterKeys) do
		local filterValue = AuraUtil.AuraFilters[key]
		if filterValue then
			local localeBase = "ICONMENU_AURAFILTER_" .. filterValue
			table.insert(AuraFilterData, {
				key = filterValue,
				text = L[localeBase],
				desc = L[localeBase .. "_DESC"]
			})
		end
	end

	if #AuraFilterData > 0 then
		local function ExtraFilter_OnClick(button, dropdown)
			local filterKey = button.value
			TMW.CI.ics.ExtraFilter[filterKey] = not TMW.CI.ics.ExtraFilter[filterKey]
			dropdown:OnSettingSaved()
		end
		
		self.ExtraFilter = TMW.C.Config_DropDownMenu:New("Frame", "$parentAuraFilter", self, "TMW_DropDownMenuTemplate")
		self.ExtraFilter:SetTexts(L["ICONMENU_AURAFILTER"], L["ICONMENU_AURAFILTER_DESC"])
		self.ExtraFilter:SetWidth(200)
		self.ExtraFilter:SetFunction(function(dropdown)
			for _, filter in ipairs(AuraFilterData) do
				local info = TMW.DD:CreateInfo()
				info.text = filter.text
				info.tooltipTitle = filter.text
				info.tooltipText = filter.desc
				info.value = filter.key
				info.func = ExtraFilter_OnClick
				info.arg1 = dropdown
				info.keepShownOnClick = true
				info.isNotRadio = true
				info.checked = TMW.CI.ics.ExtraFilter[filter.key]
				
				TMW.DD:AddButton(info)
			end
		end)

		-- Left half of a shared row with the dispel-type filter (anchored to our right).
		self.ExtraFilter:ClearAllPoints()
		self.ExtraFilter:SetPoint("TOPLEFT", self.OnlyMine, "BOTTOMLEFT", 0, -0)
		self.ExtraFilter:SetPoint("RIGHT", self, "CENTER", -4, 0)

		self:CScriptAdd("ReloadRequested", function(self, panel, panelInfo)
			local n = 0
			for k, v in pairs(TMW.CI.ics.ExtraFilter) do
				if v then
					n = n + 1
				end
			end

			if n == 0 then
				self.ExtraFilter:SetText(L["ICONMENU_AURAFILTER"] .. ": " .. NONE)
			else
				self.ExtraFilter:SetText(L["ICONMENU_AURAFILTER"] .. ": |cFFFF5959" .. n)
			end
		end)
	end

	-- Dispel-type filter (candidateFilters.includeDispelTypes). The filter is a plain
	-- map keyed by auraData.dispelName, so TMW.DS (dispel name -> icon) is exactly the
	-- set of valid keys.
	local function DispelType_OnClick(button, dropdown)
		local ics = TMW.CI.ics
		ics.DispelType[button.value] = not ics.DispelType[button.value]
		dropdown:OnSettingSaved()
	end

	self.DispelType = TMW.C.Config_DropDownMenu:New("Frame", "$parentDispelType", self, "TMW_DropDownMenuTemplate")
	self.DispelType:SetTexts(L["ICONMENU_DISPELTYPE"], L["ICONMENU_DISPELTYPE_DESC"])
	self.DispelType:SetWidth(200)
	self.DispelType:SetFunction(function(dropdown)
		for dispelType, texture in TMW:OrderedPairs(TMW.DS) do
			local info = TMW.DD:CreateInfo()
			info.text = dispelType
			info.icon = texture
			info.value = dispelType
			info.func = DispelType_OnClick
			info.arg1 = dropdown
			info.keepShownOnClick = true
			info.isNotRadio = true
			info.checked = TMW.CI.ics.DispelType[dispelType]

			TMW.DD:AddButton(info)
		end
	end)
	self.DispelType:ClearAllPoints()
	if self.ExtraFilter then
		-- Right half of the aura-filters row.
		self.DispelType:SetPoint("TOPLEFT", self.ExtraFilter, "TOPRIGHT", 8, 0)
	else
		self.DispelType:SetPoint("TOPLEFT", self.OnlyMine, "BOTTOMLEFT", 0, -8)
	end
	self.DispelType:SetPoint("RIGHT", -7, 0)

	self:CScriptAdd("ReloadRequested", function()
		local n = 0
		for _, v in pairs(TMW.CI.ics.DispelType) do
			if v then n = n + 1 end
		end
		if n == 0 then
			self.DispelType:SetText(L["ICONMENU_DISPELTYPE"] .. ": " .. NONE)
		else
			self.DispelType:SetText(L["ICONMENU_DISPELTYPE"] .. ": |cFFFF5959" .. n)
		end
	end)

	-- Max-duration cutoff (candidateFilters.maxDuration). 0 = no limit.
	local slider = TMW.C.Config_Slider:New("Slider", "$parentAuraMaxDuration", self, "TellMeWhen_SliderTemplate")
	self.AuraMaxDuration = slider
	slider:SetTexts(L["ICONMENU_DURATIONMAX"], L["ICONMENU_DURATIONMAX_DESC"])
	slider:ClearAllPoints()
	-- Below the filter row, spanning full width from its left element's bottom.
	slider:SetPoint("TOPLEFT", self.ExtraFilter or self.DispelType, "BOTTOMLEFT", 0, -14)
	slider:SetPoint("RIGHT", -10, 0)
	slider:SetSetting("AuraMaxDuration")
	slider:SetTextFormatter(TMW.C.Formatter.TIME_YDHMS)
	slider:SetMode(slider.MODE_ADJUSTING)
	slider:SetMinMaxValues(0, math.huge)
	slider:SetRange(120)
	slider:SetValueStep(1)

	-- The order the shown auras are placed in, below everything that decides which auras
	-- those are.
	local function Sort_OnClick(button, dropdown)
		TMW.CI.ics.AuraSort = button.value
		dropdown:OnSettingSaved()
	end

	self.AuraSort = TMW.C.Config_DropDownMenu:New("Frame", "$parentAuraSort", self, "TMW_DropDownMenuTemplate")
	self.AuraSort:SetTexts(L["ICONMENU_AURACONTAINER_SORT"], L["ICONMENU_AURACONTAINER_SORT_DESC"])
	self.AuraSort:ClearAllPoints()
	self.AuraSort:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -14)
	self.AuraSort:SetPoint("RIGHT", -7, 0)
	self.AuraSort:SetFunction(function(dropdown)
		for _, key in ipairs(SortOrder) do
			local sort = SortMethods[key]
			local info = TMW.DD:CreateInfo()
			info.text = sort.text
			info.tooltipTitle = sort.text
			info.tooltipText = sort.desc
			info.value = key
			info.func = Sort_OnClick
			info.arg1 = dropdown
			info.checked = TMW.CI.ics.AuraSort == key
			TMW.DD:AddButton(info)
		end
	end)

	self:CScriptAdd("ReloadRequested", function()
		local sort = SortMethods[TMW.CI.ics.AuraSort]
		self.AuraSort:SetText(L["ICONMENU_AURACONTAINER_SORT"] .. ": " .. (sort and sort.text or NONE))
	end)

	self:AdjustHeight(6)
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[ STATE_PRESENT  ] = { text = "|cFF00FF00" .. L["ICONMENU_AURACONTAINER_AURAS"],     tooltipText = L["ICONMENU_AURACONTAINER_AURAS_DESC"],     },
	-- One settings slot, two meanings, so the label follows whichever is live.
	[ STATE_UNDERLAY ] = {
		-- Absent is the same red the other types give their absent state; the underlay is a
		-- backdrop rather than a state of the aura, so it stays grey.
		text = function()
			return CurrentIconDetectsAbsence()
				and ("|cFFFF0000" .. L["ICONMENU_AURACONTAINER_ABSENT"])
				or ("|cFF7F7F7F" .. L["ICONMENU_AURACONTAINER_UNDERLAY"])
		end,
		tooltipText = function()
			return CurrentIconDetectsAbsence() and L["ICONMENU_AURACONTAINER_ABSENT_DESC"] or L["ICONMENU_AURACONTAINER_UNDERLAY_DESC"]
		end,
	},
})
