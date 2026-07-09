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

-- GLOBALS: TellMeWhen_ChooseName

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

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)
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

	-- What type of aura to check for. Values are "HELPFUL", "HARMFUL", or "EITHER".
	-- EITHER is handled specially by TMW by having looping a second time for a second filter (FilterH in the code).
	BuffOrDebuff			= "HELPFUL",

	-- Only check auras casted by the player. Appends "|PLAYER" to the UnitAura filter.
	OnlyMine				= false,

	-- Filter auras by specific ExtraFilters (IMPORTANT, CROWD_CONTROL, etc.)
	ExtraFilter				= { ["*"] = false },
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "buff",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_BuffOrDebuff", function(self)
	self:SetTitle(TMW.L["ICONMENU_BUFFTYPE"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 3,
		function(check)
			check:SetTexts("|cFF00FF00" .. L["ICONMENU_BUFF"], nil)
			check:SetSetting("BuffOrDebuff", "HELPFUL")
		end,
		function(check)
			check:SetTexts("|cFFFF0000" .. L["ICONMENU_DEBUFF"], nil)
			check:SetSetting("BuffOrDebuff", "HARMFUL")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_BOTH"], nil)
			check:SetSetting("BuffOrDebuff", "EITHER")
		end,
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(125, "TellMeWhen_BuffContainerSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_ONLYMINE"], L["ICONMENU_ONLYMINE_DESC"])
			check:SetSetting("OnlyMine")
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

		self.ExtraFilter:ClearAllPoints()
		self.ExtraFilter:SetPoint("TOPLEFT", self.OnlyMine, "BOTTOMLEFT", 0, -0)
		self.ExtraFilter:SetPoint("RIGHT", -7, 0)
		
		self:CScriptAdd("ReloadRequested", function(self, panel, panelInfo)
			local n = 0
			for k, v in pairs(TMW.CI.ics.ExtraFilter) do
				if v then
					n = n + 1
				end
			end
			
			if n == 0 then
				self.ExtraFilter:SetText(L["ICONMENU_AURAFILTER_NONE"])
			else
				self.ExtraFilter:SetText(L["ICONMENU_AURAFILTER"] .. ": |cFFFF5959" .. n)
			end
		end)
	end

	self:AdjustHeight(3)
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[ STATE_PRESENT ] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONANY"], tooltipText = L["ICONMENU_PRESENTONANY_DESC"],	},
})

-- Build the aura-display spec consumed by IconModule_AuraContainer.
-- The AuraContainer can only filter by category, so the icon's spell list is
-- intentionally ignored here - it shows everything matching the configured
-- buff/debuff kind, Only Mine, and Aura Filter selections.
local function BuildAuraSpec(icon)
	local filters = {}

	-- Selected ExtraFilters (IMPORTANT, CrowdControl, ...) are OR'd, so each one
	-- becomes its own AddAuraFilter entry. With none selected we add the bare
	-- category filter.
	local extras = icon.ExtraFilters

	local function addKind(kind)
		local base = kind
		if icon.OnlyMine then
			base = base .. "|PLAYER"
		end
		base = base .. "|INCLUDE_NAME_PLATE_ONLY"

		if extras then
			for i = 1, #extras do
				filters[#filters + 1] = { filterString = extras[i] .. "|" .. base }
			end
		else
			filters[#filters + 1] = { filterString = base }
		end
	end

	if icon.BuffOrDebuff == "HELPFUL" or icon.BuffOrDebuff == "EITHER" then
		addKind("HELPFUL")
	end
	if icon.BuffOrDebuff == "HARMFUL" or icon.BuffOrDebuff == "EITHER" then
		addKind("HARMFUL")
	end

	return {
		-- Use the configured unit TOKEN, not icon.Units[1]: the resolved Units
		-- list only contains units that currently exist, so at login with no
		-- target it would be empty and silently fall back to "player". The token
		-- (e.g. "target") is stable, and the container tracks it as it changes.
		unit = icon.UnitSet.unitSettings or icon.Units[1] or "player",
		filters = filters,
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

