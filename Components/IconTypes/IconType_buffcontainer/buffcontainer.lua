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
Type.stackedVisibilityUnknown = true

local Auras = TMW.COMMON.Auras

Type:UsesAttributes("state")
Type:UsesAttributes("auraSpec")
Type:UsesAttributes("texture")


Type:SetModuleAllowance("IconModule_AuraContainer", true)

-- Time displays live entirely inside the aura container. 
-- There's nothing we need from in config mode nor locked mode.
Type:SetModuleAllowance("IconModule_CooldownSweep", false)
Type:SetModuleAllowance("IconModule_TimerBar_BarDisplay", false)
-- Overlay bars aren't meaningfully possible.
-- Technically TimerBar is on icon views, but whatever.
Type:SetModuleAllowance("IconModule_PowerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
-- The container's AuraButtons cover the icon and bring Blizzard's own aura tooltips with them.
Type:SetModuleAllowance("IconModule_IconTooltip", false)

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

	-- The order shown auras are placed in. A key of the SortMethods table below.
	-- Not the shared Sort setting: that one is false/-1/1 across seven other icon types.
	AuraSort				= "DEFAULT",

	-- Hide auras whose maximum duration exceeds this many seconds (0 = no limit).
	-- Maps to candidateFilters.maxDuration (which also implicitly hides permanent auras).
	AuraMaxDuration			= 0,

	-- Restrict to these dispel types, keyed by dispel name. None selected = no dispel-type restriction.
	DispelType				= { ["*"] = false },
}

-- 12.1.0 stored the max-duration cutoff as DurationMax, which is Alpha_DurationReq's setting.
-- Copy rather than move: on an icon that was converted from a type with a duration requirement,
-- DurationMax is that requirement's value and has to stay behind for it.
TMW:RegisterUpgrade(12010103, {
	icon = function(self, ics)
		if ics.Type == "buffcontainer" and ics.DurationMax then
			ics.AuraMaxDuration = ics.DurationMax
		end
	end,
})

-- 12.1.0-12.1.3 ordered these icons with the shared Sort setting (false / -1 / 1), which
-- has more orders to choose from here than it does anywhere else and so moved to AuraSort.
-- Copy rather than move, like AuraMaxDuration above: Sort is still the setting every other
-- icon type reads, and has to stay behind for whatever this icon gets converted to next.
-- Sort == false needs no entry - it maps to AuraSort's own default.
TMW:RegisterUpgrade(12010401, {
	icon = function(self, ics)
		if ics.Type ~= "buffcontainer" then return end

		if ics.Sort == -1 then
			ics.AuraSort = "DUR_LOW"
		elseif ics.Sort == 1 then
			ics.AuraSort = "DUR_HIGH"
		end
	end,
})

-- The orders the AuraSort setting offers, mapped onto the container's per-group sort.
--
-- The "Only" comparators are used throughout (ExpirationOnly over Expiration, NameOnly over
-- Name): the plain ones sort player-cast, priority and self-applicable auras ahead of each
-- other first, the way Blizzard's unit frames do, and only then by the thing that was asked
-- for. UnitFrameDebuff is absent because it sorts on a field that only exists under the
-- ProcessAura processing policy, which this container doesn't use - every aura would compare
-- equal and it would behave as DEFAULT.
--
-- ENTERED is not a comparator. It splits the icon's spell IDs into one aura group each, laid
-- out in the order they were entered (see BuildAuraSpec); the method named here is the one
-- each of those groups uses to pick between several instances of its own spell.
local SortMethods = {
	DEFAULT   = { method = "Default",            direction = "Normal"  },
	ENTERED   = { method = "Default",            direction = "Normal"  },
	DUR_LOW   = { method = "ExpirationOnly",     direction = "Normal"  },
	DUR_HIGH  = { method = "ExpirationOnly",     direction = "Reverse" },
	NAME_AZ   = { method = "NameOnly",           direction = "Normal"  },
	NAME_ZA   = { method = "NameOnly",           direction = "Reverse" },
	OLDEST    = { method = "AuraInstanceIDOnly", direction = "Normal"  },
	NEWEST    = { method = "AuraInstanceIDOnly", direction = "Reverse" },
}

local SortOrder = { "DEFAULT", "ENTERED", "DUR_LOW", "DUR_HIGH", "NAME_AZ", "NAME_ZA", "OLDEST", "NEWEST" }

for key, sort in pairs(SortMethods) do
	sort.sortMethod = AuraContainerSortMethod[sort.method]
	sort.sortDirection = AuraContainerSortDirection[sort.direction]
	sort.text = L["ICONMENU_AURACONTAINER_SORT_" .. key]
	sort.desc = L["ICONMENU_AURACONTAINER_SORT_" .. key .. "_DESC"]
end

Type.SortMethods, Type.SortOrder = SortMethods, SortOrder

local function AuraKind(buffOrDebuff)
	return buffOrDebuff == "HARMFUL" and "HARMFUL" or "HELPFUL"
end

-- Tokens whose side never changes, keyed without the trailing index. group1-40 substitutes
-- to raid/party/player. Absent = follows whoever is there: focus, mouseover, X's target.
local unitKinds = {
	player = "HELPFUL",
	pet = "HELPFUL",
	vehicle = "HELPFUL",
	party = "HELPFUL",
	raid = "HELPFUL",
	group = "HELPFUL",
	maintank = "HELPFUL",
	mainassist = "HELPFUL",
	target = "HARMFUL",
	arena = "HARMFUL",
	boss = "HARMFUL",
}

local function UnitAuraKind(unit)
	if not unit then return nil end
	local base = unit:gsub("%d+$", "")
	return unitKinds[base]
end

-- The spell IDs to watch, plus every reason detection isn't running. The IDs hold until the
-- next setup; two blockers don't, so GetKnownAbsent re-tests those. Takes `ics` so it can
-- answer while the name box is still being typed into.
local function GetDetection(ics, icon)
	local blockers, shapeOk = nil, true

	local function Block(reason)
		blockers = blockers or {}
		blockers[#blockers + 1] = reason
	end

	-- Blocks until the icon is configured differently, unlike the two that come back alone.
	local function BlockShape(reason)
		shapeOk = false
		Block(reason)
	end

	-- A controller's cells fill and empty independently; this is one answer per icon.
	if icon and icon:IsGroupController() then
		BlockShape(L["ICONMENU_AURACONTAINER_CDM_CONTROLLER"])
	end

	-- originalUnits, not icon.Units: that drops units that don't exist right now.
	local _, unitSet = TMW:GetUnits(nil, ics.Unit)
	local unit = unitSet.originalUnits[1]
	if not Auras.GetCDMAuraKind(unit) then
		BlockShape(L["ICONMENU_AURACONTAINER_CDM_UNIT"])
	elseif unit == "player" and AuraKind(ics.BuffOrDebuff) == "HARMFUL" then
		-- The only fixed mismatch. On any other unit it follows the target, so it's
		-- GetKnownAbsent's to catch.
		BlockShape(L["ICONMENU_AURACONTAINER_CDM_SELFDEBUFF"])
	end

	-- Inverted: the CDM only sees your own auras, so it's Only Mine being off that breaks it.
	if not ics.OnlyMine then
		BlockShape(format(L["ICONMENU_AURACONTAINER_CDM_REQUIREON"], L["ICONMENU_ONLYMINE"]))
	end
	if ics.Stealable then
		BlockShape(format(L["ICONMENU_AURACONTAINER_CDM_REQUIREOFF"], L["ICONMENU_STEALABLE"]))
	end
	if ics.AuraMaxDuration and ics.AuraMaxDuration > 0 then
		BlockShape(format(L["ICONMENU_AURACONTAINER_CDM_REQUIREOFF"], L["ICONMENU_DURATIONMAX"]))
	end
	for _, on in pairs(ics.ExtraFilter) do
		if on then
			BlockShape(format(L["ICONMENU_AURACONTAINER_CDM_REQUIREOFF"], L["ICONMENU_AURAFILTER"]))
			break
		end
	end
	for _, on in pairs(ics.DispelType) do
		if on then
			BlockShape(format(L["ICONMENU_AURACONTAINER_CDM_REQUIREOFF"], L["ICONMENU_DISPELTYPE"]))
			break
		end
	end

	local spells
	local array = TMW:GetSpells(ics.Name, false).ArrayNoLower
	if #array == 0 then
		BlockShape(L["ICONMENU_AURACONTAINER_CDM_NOSPELLS"])
	end
	for i = 1, #array do
		local id = tonumber(array[i])
		if not id then
			-- No reason given: GetLimitations already says the entry is being ignored.
			shapeOk = false
		else
			if not Auras.IsCDMTracked(id) then
				Block(format(L["ICONMENU_AURACONTAINER_CDM_UNTRACKED"], TMW.GetSpellName(id) or id))
			end
			spells = spells or {}
			spells[#spells + 1] = id
		end
	end

	return shapeOk and spells or nil, blockers
end

Type.GetDetection = GetDetection

-- The limits this configuration actually hits, plus advice on fixing them. The advice is
-- separate so the panel doesn't colour it like a limit.
local function GetLimitations(ics)
	local limits, advice

	local function Limit(text)
		limits = limits or {}
		limits[#limits + 1] = text
	end

	local array = TMW:GetSpells(ics.Name, false).ArrayNoLower
	local hasID, hasName = false, false
	for i = 1, #array do
		if tonumber(array[i]) then
			hasID = true
		else
			hasName = true
			Limit(format(L["ICONMENU_BUFFDEBUFF_CONTAINER_NAMENOTID"], tostring(array[i])))
		end
	end
	if hasName then
		advice = format(L["ICONMENU_BUFFDEBUFF_CONTAINER_IDTOOLTIP"], L["SHOWAURASPELLIDS_OPTION"])
	end

	local _, unitSet = TMW:GetUnits(nil, ics.Unit)
	local units = unitSet.originalUnits

	-- A kind/side mismatch makes Blizzard drop includeSpellIDs, so the icon quietly shows
	-- every aura. Only a fact where the token settles the side; otherwise state the rule.
	if hasID then
		local unitKind = UnitAuraKind(units[1])
		if not unitKind then
			Limit(L["ICONMENU_BUFFDEBUFF_CONTAINER_IDFILTER"])
		elseif unitKind ~= AuraKind(ics.BuffOrDebuff) then
			Limit(unitKind == "HELPFUL"
				and L["ICONMENU_BUFFDEBUFF_CONTAINER_IDDEBUFFS"]
				or L["ICONMENU_BUFFDEBUFF_CONTAINER_IDBUFFS"])
		end
	end

	if #units > 1 then
		Limit(L["ICONMENU_BUFFDEBUFF_CONTAINER_ONEUNIT"])
	end

	return limits, advice
end
Type.GetLimitations = GetLimitations

local function BuildAuraSpec(icon)
	-- No unit to watch (e.g. no target) -> no spec; the module hides its display.
	local unit = icon.Units[1]
	if not unit then
		return nil
	end

	local filters = {}

	-- Numeric spell IDs from the Name field (names aren't filterable yet). Kept in entry
	-- order too - the ENTERED sort gives each one its own group, in that order.
	local includeSpellIDs, hasSpellIDs
	local orderedSpellIDs = {}
	for _, entry in ipairs(icon.Spells.Array) do
		local id = tonumber(entry)
		if id then
			includeSpellIDs = includeSpellIDs or {}
			if not includeSpellIDs[id] then
				orderedSpellIDs[#orderedSpellIDs + 1] = id
			end
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

	local maxDuration = (icon.AuraMaxDuration and icon.AuraMaxDuration > 0) and icon.AuraMaxDuration or nil

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

	-- The sort is applied per group/slot, so it rides on each filter entry below. Every
	-- order names a method rather than leaving one unset: groups and slots are pooled and
	-- reused across specs, so an unset method leaves the icon's previous sort in place.
	local sort = SortMethods[icon.AuraSort] or SortMethods.DEFAULT
	local sortMethod, sortDirection = sort.sortMethod, sort.sortDirection

	-- One filter string: the category, |PLAYER (Only Mine), any selected ExtraFilters
	-- (IMPORTANT, CrowdControl, ...), and |INCLUDE_NAME_PLATE_ONLY. Pipe-joined flags are
	-- OR'd by the UnitAura filter grammar, so listing several ExtraFilters matches auras
	-- passing any of them (same as buff.lua's CheckExtraFilter) - all in a single group/slot.
	-- They could maybe be separate filters if there was a container-level aura dedupe,
	-- but there isn't.
	local filterString = harmful and "HARMFUL" or "HELPFUL"
	if icon.OnlyMine then
		filterString = filterString .. "|PLAYER"
	end
	for k, v in pairs(icon.ExtraFilter) do
		if v and tContains(AuraUtil.AuraFilters, k) then
			filterString = filterString .. "|" .. k
		end
	end
	filterString = filterString .. "|INCLUDE_NAME_PLATE_ONLY"

	-- The entered order isn't a comparator - Blizzard only accepts its own, and the addon
	-- side of the container has no way to supply one. It falls out of the layout instead:
	-- one group per spell ID, each holding only that spell, laid out in filter order by
	-- IconModule_AuraContainer. A group with nothing in it
	-- contributes no spacing and forces no new line, so absent spells close up rather than
	-- leaving a hole - which is why this can't be built out of aura slots, whose frames
	-- hold their position whether or not they have an aura.
	--
	-- Two things have to be true before splitting, or it's worse than not splitting:
	--
	--   * A group controller, for somewhere to put the cells. A standalone icon draws its
	--     auras stacked on its one cell, so N groups would pile up on each other.
	--   * Spell IDs that actually filter. Blizzard drops includeSpellIDs entirely for
	--     helpful auras on units you can't assist and harmful auras on units you can
	--     (AuraContainerUtil.CanApplyIdentityCandidateFilters). With one group per spell
	--     that's not "the filter did nothing", it's every aura matching every group and
	--     showing once per spell listed.
	--
	-- Each group caps at the group's icon count, the same as the single unsplit group does,
	-- so the order an icon is shown in never decides whether it's shown - a spell up from
	-- two sources fills two cells here just as it would under any other order.
	--
	-- Nothing bounds the total, and nothing can: maxFrameCount caps each group on its own
	-- and Blizzard has no container-wide cap, so enough spells draws them past the grid.
	-- Capping the group count here would only trade that for silently dropping the spells
	-- past the cutoff, off a cell count this spec isn't told about when it changes. The
	-- setting's tooltip warns instead.
	-- Mirrors AuraContainerUtil.CanApplyIdentityCandidateFilters, minus its per-aura
	-- never-secret exemption. The extra args stop immune/uninteractable states (in a
	-- vehicle, mid-teleport) from reading as can't-assist.
	local canAssist = UnitCanAssist("player", unit, true, true)
	local spellIDsAreFiltered
	if harmful then
		spellIDsAreFiltered = not canAssist
	else
		spellIDsAreFiltered = canAssist or UnitIsPlayerControlledOrGroupMember(unit)
	end

	local entered = hasSpellIDs
		and icon.AuraSort == "ENTERED"
		and icon:IsGroupController()
		and spellIDsAreFiltered

	if entered then
		for i = 1, #orderedSpellIDs do
			local perSpell = {}
			for k, v in pairs(cf) do
				perSpell[k] = v
			end
			perSpell.includeSpellIDs = { [orderedSpellIDs[i]] = true }

			filters[i] = {
				filterString = filterString,
				candidateFilters = perSpell,
				sortMethod = sortMethod,
				sortDirection = sortDirection,
			}
		end
	else
		filters[1] = {
			filterString = filterString,
			candidateFilters = cf,
			sortMethod = sortMethod,
			sortDirection = sortDirection,
		}
	end

	return {
		unit = unit,
		filters = filters,

		-- No UNIT_AURA is fired for these units (mouseover, targettarget, ...), so the
		-- container would sit forever on whatever it parsed when the unit was set.
		polled = not icon.UnitSet.allUnitsChangeOnEvent,
	}
end

-- True when every one of the icon's spells is gone, nil when the CDM can't say.
local function GetKnownAbsent(icon)
	local spells = icon.CDMSpells
	if not spells then
		return nil
	end

	-- The configured unit: with no target icon.Units is empty, but the CDM still reads that
	-- slot as harmful and finds nothing, which is an absence.
	local unit = icon.UnitSet.originalUnits[1]
	if Auras.GetCDMAuraKind(unit) ~= AuraKind(icon.BuffOrDebuff) then
		return nil
	end

	local absent = true
	for i = 1, #spells do
		local state = Auras.GetCDMAuraState(spells[i])
		if state == nil then
			return nil
		elseif state then
			absent = false
		end
	end

	return absent
end

-- The icon type's only job in this mode is to publish the spec via SetInfo;
-- IconModule_AuraContainer consumes it and owns the container, and the container
-- handles ongoing UNIT_AURA updates itself. The state we publish is the module's too - it
-- describes the icon frame that carries the auras and the underlay, not either of them on
-- its own, so the module builds it. One table per outcome, built at setup, so the STATE
-- processor can tell a real change from a no-op.
local function Buff_OnUpdate_AuraContainer(icon, time)
	local knownAbsent = GetKnownAbsent(icon)
	if knownAbsent ~= icon.AuraContainerKnownAbsent then
		icon.AuraContainerKnownAbsent = knownAbsent
		-- Nothing else re-derives how the opacity divides between the two layers.
		local module = icon:GetModuleOrModuleChild("IconModule_AuraContainer", true)
		if module then
			module:ApplyOpacities()
		end
	end

	local state = icon.AuraContainerState
	if knownAbsent ~= nil then
		state = knownAbsent and icon.AuraContainerStateAbsent or icon.AuraContainerStatePresent
	end

	icon:SetInfo("state; auraSpec", state, BuildAuraSpec(icon))

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
-- added/removed) or when the Cooldown Manager reports an aura coming or going; ongoing aura
-- changes on the current unit are the container's job, not ours.
local function Buff_OnEvent_AuraContainer(icon, event)
	if event == icon.UnitSet.event or event == "TMW_CDM_AURA_CHANGED" then
		icon.NextUpdateTime = 0
	end
end

function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)

	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)
	icon.FirstTexture = GetSpellTexture(icon.Spells.First)

	local Module = TMW.C.IconModule_AuraContainer
	icon.AuraContainerState = Module:GetIconState(icon)
	icon.AuraContainerStatePresent = Module:GetIconState(icon, false)
	icon.AuraContainerStateAbsent = Module:GetIconState(icon, true)

	icon.CDMSpells = GetDetection(icon:GetSettings(), icon)
	icon.AuraContainerKnownAbsent = nil

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)

	icon:SetUpdateMethod("manual")
	icon:SetUpdateFunction(Buff_OnUpdate_AuraContainer)

	-- The container tracks UNIT_AURA itself; we only re-publish the spec when
	-- the unit set changes (e.g. target swap).
	icon:SetScript("OnEvent", Buff_OnEvent_AuraContainer)
	icon:RegisterEvent(icon.UnitSet.event)
	if icon.CDMSpells then
		icon:RegisterEvent("TMW_CDM_AURA_CHANGED")
	end

	-- BuildAuraSpec drops anything that isn't a number, so a name entered here matches
	-- nothing at all and does it quietly. Say so rather than leave the user guessing.
	--
	-- A dispel type gets its own message. The suggestion list can't turn it into a spell ID
	-- the way it can a spell name, because it isn't one - the Dispel Type filter is where it
	-- goes, and that filter does work in combat.
	-- GLOBALS: TellMeWhen_ChooseName
	if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
		TMW.HELP:Hide("ICONTYPE_BUFFCONTAINER_NAMENOTID")

		local badName, badDispelType
		for _, entry in ipairs(icon.Spells.Array) do
			if TMW.DS[entry] then
				badDispelType = badDispelType or entry
			elseif not tonumber(entry) then
				badName = badName or entry
			end
		end

		if badDispelType or badName then
			TMW.HELP:Show{
				code = "ICONTYPE_BUFFCONTAINER_NAMENOTID",
				codeOrder = 2,
				icon = icon,
				relativeTo = TellMeWhen_ChooseName,
				x = 0,
				y = 0,
				-- The dispel type wins when both are present: it's the one with somewhere
				-- to send the user.
				text = badDispelType
					and format(L["HELP_BUFFCONTAINER_DISPELTYPE"], badDispelType, L["ICONMENU_DISPELTYPE"])
					or format(L["HELP_BUFFCONTAINER_NAMENOTID"], badName, L["SHOWAURASPELLIDS_OPTION"])
			}
		end
	end

	icon:Update()
end

Type:Register(210)