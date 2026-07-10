-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

if TMW.wowMajorMinor < 12.1 then return end

local print = TMW.print
local tonumber, pairs, type, format, select =
	  tonumber, pairs, type, format, select

local GetSpellTexture = TMW.GetSpellTexture

local AuraContainerSortMethod = _G.AuraContainerSortMethod
local AuraContainerSortDirection = _G.AuraContainerSortDirection

local Type = TMW.Classes.IconType:New("buffcontainer")
Type.name = L["ICONMENU_BUFFDEBUFF_CONTAINER"]
Type.desc = L["ICONMENU_BUFFDEBUFF_CONTAINER_DESC"]
Type.menuIcon = GetSpellTexture(172)
Type.usePocketWatch = 1
Type.AllowNoName = true
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_HIDE

Type:UsesAttributes("state")
Type:UsesAttributes("auraSpec")
Type:UsesAttributes("texture")

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)

-- The AuraButtons own the cooldown swipe, so disable TMW's version; its timer
-- settings are reintroduced on IconModule_AuraContainer. Texture_Colored stays
-- allowed so its texture override keeps working - IconModule_AuraContainer
-- suppresses its own aura icon when an override is configured.
Type:SetModuleAllowance("IconModule_AuraContainer", true)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)
-- In the bar views the AuraButton owns the duration bar (via SetDurationBar) and
-- recreates the backdrop/border as its own children, so both hide with the aura.
-- Disable TMW's versions of both.
Type:SetModuleAllowance("IconModule_TimerBar_BarDisplay", false)

Type:RegisterIconDefaults{
	-- The unit(s) to check for auras
	Unit					= "player",

	-- What type of aura to check for: "HELPFUL" or "HARMFUL". There's no "both" - no single
	-- aura filter string matches both categories, and two groups have no shared frame cap
	-- so they overflow the icon (see BuildAuraSpec). A legacy "EITHER" is treated as HELPFUL.
	BuffOrDebuff			= "HELPFUL",

	-- Only check auras casted by the player. Appends "|PLAYER" to the UnitAura filter.
	OnlyMine				= false,

	-- Filter auras by specific ExtraFilters (IMPORTANT, CROWD_CONTROL, etc.)
	ExtraFilter				= { ["*"] = false },

	-- Only show stealable auras. Helpful auras only (candidateFilters.isStealable).
	Stealable				= false,

	-- Sort shown auras by remaining duration: false / 1 (longest first) / -1 (shortest
	-- first). Maps to AuraContainerSortMethod.Expiration.
	Sort					= false,

	-- Hide auras whose maximum duration exceeds this many seconds (0 = no limit).
	-- Maps to candidateFilters.maxDuration (which also implicitly hides permanent auras).
	DurationMax				= 0,

	-- Restrict to these dispel types, keyed by dispel name ("Magic"/"Curse"/"Poison"/
	-- "Disease"). None selected = no dispel-type restriction.
	DispelType				= { ["*"] = false },
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "buffNoDS",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(110, "TellMeWhen_TextPanel", {
	frameName = "TellMeWhen_BuffContainerLimitations",
	OnSetup = function(self)
		self:SetTitle(L["ICONMENU_BUFFDEBUFF_CONTAINER_LIMITATIONS"])
		self.text:SetText(L["ICONMENU_BUFFDEBUFF_CONTAINER_LIMITATIONS_DESC"])
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
	self:SetTitle(Type.name)
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
	local slider = TMW.C.Config_Slider:New("Slider", "$parentDurationMax", self, "TellMeWhen_SliderTemplate")
	self.DurationMax = slider
	slider:SetTexts(L["ICONMENU_DURATIONMAX"], L["ICONMENU_DURATIONMAX_DESC"])
	slider:ClearAllPoints()
	-- Below the filter row, spanning full width from its left element's bottom.
	slider:SetPoint("TOPLEFT", self.ExtraFilter or self.DispelType, "BOTTOMLEFT", 0, -14)
	slider:SetPoint("RIGHT", -10, 0)
	slider:SetSetting("DurationMax")
	slider:SetTextFormatter(TMW.C.Formatter.TIME_YDHMS)
	slider:SetMode(slider.MODE_ADJUSTING)
	slider:SetMinMaxValues(0, math.huge)
	slider:SetRange(120)
	slider:SetValueStep(1)

	self:AdjustHeight(6)
end)

-- Sort shown auras by remaining duration (buff.lua's Sort, minus stack sort - the
-- container has no stack sort method).
Type:RegisterConfigPanel_ConstructorFunc(170, "TellMeWhen_BuffContainerSort", function(self)
	self:SetTitle(TMW.L["SORTBY"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 3,
		function(check)
			check:SetTexts(TMW.L["SORTBYNONE_DURATION"], TMW.L["SORTBYNONE_DESC"])
			check:SetSetting("Sort", false)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTASC"], TMW.L["ICONMENU_SORTASC_DESC"])
			check:SetSetting("Sort", -1)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTDESC"], TMW.L["ICONMENU_SORTDESC_DESC"])
			check:SetSetting("Sort", 1)
		end,
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[ STATE_PRESENT ] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONANY"], tooltipText = L["ICONMENU_PRESENTONANY_DESC"],	},
})

-- Build the aura-display spec consumed by IconModule_AuraContainer.
--
-- The AuraContainer filters by category (the filter string) plus a set of per-filter
-- candidate filters the container evaluates internally:
--   * Spell IDs (from numeric entries in the Name field). Aura spell IDs don't map to
--     learned-spell overrides, so only entries the user typed as raw IDs are usable -
--     names can't be filtered yet (pending Blizzard support). The container itself only
--     honors spell-ID matching for buffs on assistable units and debuffs on
--     non-assistable units, so it silently no-ops for debuffs-on-friendly / buffs-on-
--     enemy; we send it on every filter and let the container gate.
--   * Stealable (helpful auras only - a harmful filter with isStealable shows nothing).
--   * Max duration and dispel types.
-- Sorting (by remaining duration) is a container-level sort method, shared by all filters.
local function BuildAuraSpec(icon)
	-- No unit to watch (e.g. no target) -> no spec; the module hides its display.
	local unit = icon.Units[1]
	if not unit then
		return nil
	end

	local filters = {}

	-- Numeric spell IDs from the Name field (names aren't filterable yet).
	local includeSpellIDs, hasSpellIDs
	for _, entry in ipairs(icon.Spells.Array) do
		local id = tonumber(entry)
		if id then
			includeSpellIDs = includeSpellIDs or {}
			includeSpellIDs[id] = true
			hasSpellIDs = true
		end
	end

	-- Selected dispel types (keyed by dispel name).
	local includeDispelTypes
	for dispelType, on in pairs(icon.DispelType) do
		if on then
			-- TMW has always used "Enraged", but WoW 12.1 finally fixed this from emptystring to "Enrage".
			if dispelType == "Enraged" then dispelType = "Enrage" end

			includeDispelTypes = includeDispelTypes or {}
			includeDispelTypes[dispelType] = true
		end
	end

	local maxDuration = (icon.DurationMax and icon.DurationMax > 0) and icon.DurationMax or nil

	-- Only HELPFUL or HARMFUL - there's no "both". No single aura filter string matches
	-- both categories (a category-less string and "HELPFUL|HARMFUL" both match nothing),
	-- and two separate filter groups would overflow a one-cell icon / a controller's grid
	-- (the container has no container-wide frame cap). A legacy "EITHER" -> HELPFUL.
	local harmful = icon.BuffOrDebuff == "HARMFUL"

	-- Candidate filters, or nil when nothing is restricted (so the group keeps its default,
	-- unrestricted filters). isStealable is helpful-only - on a harmful filter it hides all.
	local cf
	if hasSpellIDs then cf = cf or {}; cf.includeSpellIDs = includeSpellIDs end
	if includeDispelTypes then cf = cf or {}; cf.includeDispelTypes = includeDispelTypes end
	if maxDuration then cf = cf or {}; cf.maxDuration = maxDuration end
	if not harmful and icon.Stealable then cf = cf or {}; cf.isStealable = true end

	-- Base filter: category, plus |PLAYER (Only Mine) and |INCLUDE_NAME_PLATE_ONLY.
	local base = harmful and "HARMFUL" or "HELPFUL"
	if icon.OnlyMine then
		base = base .. "|PLAYER"
	end
	base = base .. "|INCLUDE_NAME_PLATE_ONLY"

	-- Selected ExtraFilters (IMPORTANT, CrowdControl, ...) are OR'd - one filter entry each;
	-- with none selected, the bare category filter.
	local extras = icon.ExtraFilters
	if extras then
		for i = 1, #extras do
			filters[#filters + 1] = { filterString = extras[i] .. "|" .. base, candidateFilters = cf }
		end
	else
		filters[#filters + 1] = { filterString = base, candidateFilters = cf }
	end

	-- Duration sort. Use ExpirationOnly (pure remaining-time order) rather than Expiration,
	-- which - like Blizzard's default unit-frame sort - floats player-cast / priority /
	-- self-applicable auras to the front before considering duration. Map the icon's Sort
	-- (1 = longest first, -1 = shortest first, matching buff.lua) onto the sort direction.
	-- (Verify direction in-game - flip the Normal/Reverse choice if reversed.) Always emit
	-- a method (Default when off) so turning Sort off reverts the group.
	local sortMethod = AuraContainerSortMethod.Default
	local sortDirection = AuraContainerSortDirection.Normal
	if icon.Sort then
		sortMethod = AuraContainerSortMethod.ExpirationOnly
		sortDirection = icon.Sort == -1 and AuraContainerSortDirection.Normal or AuraContainerSortDirection.Reverse
	end

	return {
		unit = unit,
		filters = filters,
		sortMethod = sortMethod,
		sortDirection = sortDirection,
	}
end

-- The icon type's only job in this mode is to publish the spec via SetInfo;
-- IconModule_AuraContainer consumes it and owns the container, and the container
-- handles ongoing UNIT_AURA updates itself. We hold a shown state so the
-- AuraButtons are free to show/hide their own contents.
local function Buff_OnUpdate_AuraContainer(icon, time)
	icon:SetInfo("state; auraSpec", STATE_PRESENT, BuildAuraSpec(icon))

	if icon:IsGroupController() then
		-- As a group controller we don't harvest aura data ourselves - Blizzard's
		-- AuraContainer does, and it owns each button's show/hide - so there's no
		-- per-icon info to YieldInfo(). Claim every icon in the group directly so
		-- the controller path (Icon:Update) doesn't force the controlled icons to
		-- alpha 0. That matters most for the controller icon itself (icon 1), which
		-- parents the shared container: hiding it would hide every aura button.
		-- IconModule_AuraContainer fills the group with one button per icon.
		icon.__controlledIconIndex = icon.group.numIcons
	end
end

-- We only need to re-publish when the unit set changes (target swap, units
-- added/removed); ongoing aura changes on the current unit are the container's
-- job, not ours.
local function Buff_OnEvent_AuraContainer(icon, event)
	if event == icon.UnitSet.event then
		icon.NextUpdateTime = 0
	end
end

function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)
	
	icon.ExtraFilters = nil
	for k, v in pairs(icon.ExtraFilter) do
		if v and tContains(AuraUtil.AuraFilters, k) then
			icon.ExtraFilters = icon.ExtraFilters or {}
			tinsert(icon.ExtraFilters, k)
		end
	end
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)
	icon.FirstTexture = GetSpellTexture(icon.Spells.First)

	icon:SetInfo("texture; reverse", TMW.Locked and "" or Type:GetConfigIconTexture(icon), true)

	icon:SetUpdateMethod("manual")
	icon:SetUpdateFunction(Buff_OnUpdate_AuraContainer)

	-- The container tracks UNIT_AURA itself; we only re-publish the spec when
	-- the unit set changes (e.g. target swap).
	icon:SetScript("OnEvent", Buff_OnEvent_AuraContainer)
	icon:RegisterEvent(icon.UnitSet.event)

	icon:Update()
	if TMW.Locked then
		icon:SetInfo("auraSpec", nil)
	end
end
	
Type:Register(100)

