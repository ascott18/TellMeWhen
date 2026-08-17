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


-- ----------------------------------------------------------------------------
-- IconModule_AuraContainer
--
-- Renders auras using Blizzard's 12.1 AuraContainer / AuraButton objects instead
-- of TMW's own scan loop + texture/cooldown/text modules.
--
-- The icon type feeds this module a static "aura spec" via the AURASPEC
-- IconDataProcessor:
--     spec = {
--         unit = "target",
--         filters = {
--             { filterString = "HARMFUL|INCLUDE_NAME_PLATE_ONLY", ... },
--             ...
--         },
--     }
--
-- ----------------------------------------------------------------------------

local Module = TMW:NewClass("IconModule_AuraContainer", "IconModule")

-- Off for every icon type unless explicitly allowed. Aura-container icon types
-- opt in with Type:SetModuleAllowance("IconModule_AuraContainer", true).
Module:SetDefaultAllowanceForTypes(false)

if TMW.wowMajorMinor < 12.1 then return end

local max = math.max
local LSM = LibStub("LibSharedMedia-3.0")
local ShouldAurasBeSecret = C_Secrets.ShouldAurasBeSecret

-- GLOBALS: AnchorUtil, AuraContainerSortDirection, AuraContainerSortMethod
local FlowDirection = AnchorUtil.FlowDirection
local FlowLayoutAxis = AnchorUtil.FlowLayoutAxis

-- The two icon states an aura-container icon carries - the auras and the underlay. Up here
-- because the button skinning needs the auras' look; the underlay section explains both.
local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_UNDERLAY = TMW.CONST.STATE.DEFAULT_HIDE

-- Masque's two profile-wide coloring options, read the same way IconModule_Texture_Colored
-- reads them so an aura button tints like the icon it stands in for.
-- GLOBALS: LibMasque
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local ColorMSQ, OnlyMSQ
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ColorMSQ = TMW.db.profile.ColorMSQ
	OnlyMSQ = TMW.db.profile.OnlyMSQ
end)

-- The container stamps every aura frame with DenyTaintedAccessWhenAurasAreSecret as soon as
-- its initializeFrame callback returns (AuraContainerCustomFrameProviderMixin:CreateFrame,
-- which defers the stamp to PLAYER_ENTERING_WORLD for frames created before login). While
-- auras are secret that stamp denies us EVERY call on the frame - not just secret-valued
-- reads - so `button:SetSize()` from tainted code is a hard error, not a taint warning. Two
-- consequences run through this file:
--   * A new button can only be skinned inside initializeFrame, before the stamp lands. Both
--     creation paths (EnsureGroup, EnsureSlot) therefore do all their frame work there.
--   * An existing button can only be re-skinned while we're allowed to touch it. While auras
--     are secret each button answers that itself (CanBeAccessedInContext) - one still waiting
--     for its stamp is fair game. Reskins that arrive at a bad time park their module here
--     and replay once the restriction lifts (leaving combat / an encounter / M+ / PvP).
-- There's no event for the flip, so poll it off TMW's update the way Common/Auras.lua does.
local pendingReskin = {}
local aurasWereSecret = ShouldAurasBeSecret()

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", function()
	local secret = ShouldAurasBeSecret()
	if secret == aurasWereSecret then
		return
	end
	aurasWereSecret = secret
	if secret then
		return
	end

	local flush = pendingReskin
	pendingReskin = {}
	for module in pairs(flush) do
		module:ReskinButtons()
	end
end)

-- A NumericRuleFormatter that mirrors TMW:FormatSeconds / the TMWFormatDuration
-- DogTag, so the AuraButton's (secret) duration text reads the same as every other
-- TMW timer: "9.9" under ten seconds, "42" under a minute, then "M:SS", "H:MM:SS",
-- "D:HH:MM:SS". Blizzard's DefaultAuraDurationFormatter (a SecondsFormatter) instead
-- renders one abbreviated unit ("1m", "2h"), which looks out of place next to the
-- rest of TMW.
--
-- Each breakpoint picks the highest threshold <= value; its components carve the value
-- into the numbers its format string consumes (Down rounding = floor, matching
-- FormatSeconds' integer fields). The sub-10 rule has no components so %.1f formats the
-- raw value.
local Down = Enum.NumericRuleFormatRounding.Down
local durationFormatter = C_StringUtil.CreateNumericRuleFormatter()
durationFormatter:SetBreakpoints({
	-- < 10s: one decimal place, e.g. "9.9" / "0.5".
	{ threshold = 0, format = "%.1f" },
	-- 10s..1m: whole seconds, e.g. "42".
	{ threshold = 10, format = "%d", components = {
		{ step = 1, rounding = Down },
	} },
	-- 1m..1h: "M:SS".
	{ threshold = 60, format = "%d:%02d", components = {
		{ div = 60, rounding = Down },
		{ mod = 60, step = 1, rounding = Down },
	} },
	-- 1h..1d: "H:MM:SS".
	{ threshold = 3600, format = "%d:%02d:%02d", components = {
		{ div = 3600, rounding = Down },
		{ div = 60, mod = 60, rounding = Down },
		{ mod = 60, step = 1, rounding = Down },
	} },
	-- 1d+: "D:HH:MM:SS".
	{ threshold = 86400, format = "%d:%02d:%02d:%02d", components = {
		{ div = 86400, rounding = Down },
		{ div = 3600, mod = 24, rounding = Down },
		{ div = 60, mod = 60, rounding = Down },
		{ mod = 60, step = 1, rounding = Down },
	} },
})


local Processor = TMW.Classes.IconDataProcessor:New("AURASPEC", "auraSpec")
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: auraSpec
	t[#t+1] = [[
	if attributes.auraSpec ~= auraSpec then
		attributes.auraSpec = auraSpec

		TMW:Fire(AURASPEC.changedEvent, icon, auraSpec)
		doFireIconUpdated = true
	end
	--]]
end

-- The AuraButton owns the cooldown, so aura-container types disable
-- IconModule_CooldownSweep - which also hides its timer settings. Reintroduce the
-- ones we honor here (reusing the shared ShowTimer/ShowTimerText settings, applied
-- to the AuraButton's cooldown in ApplyButtonSettings). This panel only shows on
-- types where the module is allowed.
Module:RegisterConfigPanel_ConstructorFunc(200, "TellMeWhen_AuraContainerTimerSettings", function(self)
	self:SetTitle(L["CONFIGPANEL_TIMER_HEADER"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 2,
		function(check)
			check:SetTexts(L["ICONMENU_SHOWTIMER"], L["ICONMENU_SHOWTIMER_DESC"])
			check:SetSetting("ShowTimer")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_SHOWTIMERTEXT"], L["ICONMENU_SHOWTIMERTEXT_DESC"])
			check:SetSetting("ShowTimerText")
		end,
	})
	self:SetAutoAdjustHeight(true)
end)

-- The AuraButton owns the duration bar too, so aura-container types disable
-- IconModule_TimerBar_BarDisplay, taking its whole panel with it. This is that panel,
-- reduced to the settings the container can actually honor - the rest need either the GCD
-- (BarGCD), control of the bar's min/max (FakeMax), or the remaining time (the gradient to
-- the middle and complete colors), and the remaining time is secret.
--
-- Bar views only; the panel hides itself entirely on the icon view, which has no bar.
Module:RegisterConfigPanel_ConstructorFunc(205, "TellMeWhen_AuraContainerBarSettings", function(self)
	self:SetTitle(L["CONFIGPANEL_TIMERBAR_BARDISPLAY_HEADER"])

	local function NewCheck(key, title, tooltip, setting)
		local check = TMW.C.Config_CheckButton:New("CheckButton", "$parent" .. key, self, "TellMeWhen_CheckTemplate")
		check:SetTexts(title, tooltip)
		check:SetSetting(setting)
		check:ClearAllPoints()
		return check
	end

	local invert = NewCheck("Invert", L["ICONMENU_INVERTBARS"], L["ICONMENU_INVERTBARDISPLAYBAR_DESC"], "BarDisplay_Invert")
	-- Stored as a StatusBarInterpolation, so the checked values are the enum's.
	local smoothing = NewCheck("Smoothing", L["ICONMENU_SMOOTHING"], L["ICONMENU_SMOOTHING_DESC"], "BarDisplay_Smoothing")
	smoothing:SetCheckedValues(1, 0)
	local reverse = NewCheck("Reverse", L["ICONMENU_REVERSEBARS"], L["ICONMENU_REVERSEBARS_DESC"], "BarDisplay_Reverse")
	local enableColors = NewCheck("EnableColors", L["COLOR_OVERRIDE_GROUP"], L["COLOR_OVERRIDE_GROUP_DESC"], "TimerBar_EnableColors")

	local startColor = TMW.C.Config_ColorButton:New("Button", "$parentStartColor", self, "TellMeWhen_ColorButtonTemplate")
	-- Just "the bar color" here rather than BarDisplay's "start color": with no gradient to
	-- run to, there's no other end for it to be the start of.
	startColor:SetTexts(L["ICONMENU_BAR_COLOR"], L["ICONMENU_BAR_COLOR_DESC"])
	startColor:SetSetting("TimerBar_StartColor")
	startColor:SetHasOpacity(true)
	startColor:ClearAllPoints()

	-- Laid out the way TellMeWhen_BarDisplayBarOptions does it: only each row's first frame
	-- gets a vertical anchor, and DistributeFrameAnchorsLaterally spreads the row and carries
	-- the y across. The rows match that panel's minus the two settings we can't honor, which
	-- leaves Fill/Flip/Override down the left and Smoothing opposite the first of them.
	invert:SetPoint("TOP", 0, -1)
	reverse:SetPoint("TOP", invert, "BOTTOM", 0, 3)
	enableColors:SetPoint("TOP", reverse, "BOTTOM", 0, 3)
	startColor:SetPoint("TOPLEFT", enableColors, "BOTTOMLEFT", 5, -3)

	invert:ConstrainLabel(smoothing)
	smoothing:ConstrainLabel(self, "RIGHT")
	reverse:ConstrainLabel(self, "RIGHT")
	enableColors:ConstrainLabel(self, "RIGHT")

	TMW.IE:DistributeFrameAnchorsLaterally(self, 2, invert, smoothing)
	TMW.IE:DistributeFrameAnchorsLaterally(self, 2, reverse)
	TMW.IE:DistributeFrameAnchorsLaterally(self, 2, enableColors)

	self:CScriptAdd("ReloadRequested", function()
		-- Not TMW.CI.gs: that's only populated while the group config is open, and this is
		-- an icon panel. Take the view from the icon's own group instead.
		local view = TMW.CI.icon.group:GetSettings().View
		if view ~= "bar" and view ~= "barv" then
			-- No bar in this view, so nothing here applies. PositionPanels re-checks
			-- IsShown after Setup and drops the panel from the column entirely.
			self:Hide()
			return
		end

		startColor:SetShown(TMW.CI.ics.TimerBar_EnableColors)

		self:AdjustHeight(6)
	end)
end)

Module:RegisterIconDefaults{
	ShowPandemic      = false,
	PandemicStyle     = "ACTVTNBORDER",
	PandemicColor     = "ffff0000",
	PandemicThickness = 2,
}

-- Pandemic indicator styles. A style is a region on the aura button whose visibility alone
-- says "this aura is in its pandemic window" - the container only ever calls SetShown on it,
-- so nothing here gets to know when the window opens.
--
-- Anything that moves has to move from a declarative AnimationGroup. Script handlers don't
-- run on descendants of the forbidden AuraButton, which rules out every OnUpdate-driven
-- effect - LibCustomGlow's pixel/autocast glows and TMW's own Animations handlers included.
--
-- Registered further down, next to the code that builds them; declared here because the
-- config panel below lists them.
local PandemicStyles = {}
local PandemicStyleOrder = {}

local function RegisterPandemicStyle(key, data)
	data.key = key
	PandemicStyles[key] = data
	PandemicStyleOrder[#PandemicStyleOrder + 1] = key
end

Module:RegisterConfigPanel_ConstructorFunc(210, "TellMeWhen_AuraContainerPandemic", function(self)
	self:SetTitle(L["CONFIGPANEL_PANDEMIC_HEADER"])

	local check = TMW.C.Config_CheckButton:New("CheckButton", "$parentShowPandemic", self, "TellMeWhen_CheckTemplate")
	self.ShowPandemic = check
	check:SetTexts(L["ICONMENU_SHOWPANDEMIC"], L["ICONMENU_SHOWPANDEMIC_DESC"])
	check:SetSetting("ShowPandemic")
	check:ClearAllPoints()
	check:SetPoint("TOPLEFT", 5, -1)

	local function Style_OnClick(button)
		TMW.CI.ics.PandemicStyle = button.value
		-- Reloading re-runs ReloadRequested below, which relays the panel out for whichever
		-- controls the newly picked style uses.
		TMW.IE:LoadIcon(1)
	end

	local styleDD = TMW.C.Config_DropDownMenu:New("Frame", "$parentPandemicStyle", self, "TMW_DropDownMenuTemplate")
	self.PandemicStyle = styleDD
	styleDD:SetTexts(L["ICONMENU_PANDEMICSTYLE"], L["ICONMENU_PANDEMICSTYLE_DESC"])
	styleDD:ClearAllPoints()
	-- Right half of the header row, sharing it with the checkbox (the same split
	-- TellMeWhen_BuffContainerSettings uses for its two filter dropdowns). Dropped by half
	-- the height difference between the two templates (30 and 20) to sit centered on the
	-- checkbox rather than riding above it.
	styleDD:SetPoint("TOPLEFT", self, "TOP", -4, -6)
	styleDD:SetPoint("RIGHT", -7, 0)
	styleDD:SetFunction(function()
		for _, key in ipairs(PandemicStyleOrder) do
			local style = PandemicStyles[key]
			local info = TMW.DD:CreateInfo()
			info.text = style.text
			info.tooltipTitle = style.text
			info.tooltipText = style.desc
			info.value = key
			info.func = Style_OnClick
			info.checked = TMW.CI.ics.PandemicStyle == key
			TMW.DD:AddButton(info)
		end
	end)

	-- Every per-style control is built once here; a style names the ones it wants in its
	-- ConfigFrames and the rest stay hidden. `stretch` marks the ones that fill the panel
	-- width - the color swatch is a fixed-size button and must not be anchored RIGHT.
	local controls = {}

	local color = TMW.C.Config_ColorButton:New("Button", "$parentPandemicColor", self, "TellMeWhen_ColorButtonTemplate")
	color:SetTexts(L["ICONMENU_PANDEMICCOLOR"], L["ICONMENU_PANDEMICCOLOR_DESC"])
	color:SetSetting("PandemicColor")
	color:SetHasOpacity(true)
	controls.Color = color

	local thickness = TMW.C.Config_Slider:New("Slider", "$parentPandemicThickness", self, "TellMeWhen_SliderTemplate")
	thickness:SetTexts(L["ICONMENU_PANDEMICTHICKNESS"], L["ICONMENU_PANDEMICTHICKNESS_DESC"])
	thickness:SetSetting("PandemicThickness")
	thickness:SetMinMaxValues(0, 10)
	thickness:SetValueStep(0.1)
	thickness:SetWheelStep(0.1)
	thickness:SetTextFormatter(TMW.C.Formatter.PIXELS, TMW.C.Formatter.F_0)
	thickness.stretch = true
	controls.Thickness = thickness

	self:CScriptAdd("ReloadRequested", function()
		for _, control in pairs(controls) do
			control:Hide()
		end

		local style = PandemicStyles[TMW.CI.ics.PandemicStyle]
		styleDD:SetText(style and style.text or NONE)

		-- Stack the style's controls down the left edge, under the header row - the checkbox
		-- is both its left-aligned and its taller frame, so it bounds the row.
		local last = check
		if style then
			for _, key in ipairs(style.ConfigFrames) do
				local control = controls[key]
				control:ClearAllPoints()
				control:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -14)
				if control.stretch then
					control:SetPoint("RIGHT", -10, 0)
				end
				control:Show()
				last = control
			end
		end

		self:AdjustHeight(6)
	end)
end)

function Module:OnNewInstance(icon)
	-- Buttons are created by the container (not us); we record each one the
	-- container hands to our initializeFrame callback so we can (re-)skin them all.
	-- Keyed by the frame itself.
	self.buttons = {}

	-- Group controllers distribute N distinct auras across the group, so they use aura
	-- GROUPS. Both pools are keyed by index: neither a group nor a slot can be removed, but
	-- their filter strings ARE mutable, so we reassign by index rather than accumulate one
	-- per filter string the icon has ever used. Unused groups are parked with maxFrameCount 0.
	self.groups = {}

	-- A single icon shows one aura, so it uses aura SLOTS instead - one frame each.
	-- Unused ones are parked with a filter matching nothing (a slot has no frame cap).
	self.slots = {}
end


-- ----------------------------------------------------------------------------
-- Per-button skinning
--
-- Each button is a container-owned AuraButton, sized to (and skinned like) the icon,
-- but placed by the container's flow layout. Its widgets (icon texture, cooldown,
-- duration bar, borders, backdrop, aura text) are built as children of the button -
-- they MUST be created as children so they inherit the button's forbidden aspects -
-- and handed to the CustomAuraButton APIs. The look is produced by MIRRORING the
-- icon's real (Masque-skinned, bordered, padded) module frames, so it matches a
-- normal TMW icon.
--
-- Everything we place on a button gets an explicit frame level from this stack (offsets
-- from the button's own level) - two of our frames landing on the same level would order
-- by creation instead. Text on top mirrors a real icon, where IconModule_Texts sits at
-- icon level + 3 while the icon square and its border sit at + 0 / + 1.
-- ----------------------------------------------------------------------------

local LEVEL_BACKDROP = 0  -- the bar views' bar backdrop
local LEVEL_ICON     = 1  -- icon holder: the icon texture and any Masque skin on it
local LEVEL_BAR      = 1  -- the bar views' duration bar (never overlaps the icon square)
local LEVEL_COOLDOWN = 2
local LEVEL_BORDER   = 3  -- icon square + bar borders
local LEVEL_PANDEMIC = 4  -- pandemic art, drawn over the icon border it frames
local LEVEL_TEXT     = 5

-- Copy `source`'s anchor points (and size) onto `region`, remapping each point's
-- relativeTo frame through `remap` (falling back to `default`). This reproduces a
-- frame the view already positioned, but anchored to the button (and its children)
-- so it stays valid on the forbidden button - no duplicated geometry math.
--
-- `divisor` (default 1) divides the copied size and offsets. Pass `region`'s own
-- SetScale factor here: SetPoint offsets are measured in the scaled frame's coordinate
-- space, so a scaled region needs its mirrored offsets divided by that scale to land at
-- the same screen positions the unscaled source occupies.
local function MirrorPoints(region, source, remap, default, divisor)
	local n = source:GetNumPoints()
	if n == 0 then
		return false
	end
	divisor = divisor or 1
	local w, h = source:GetSize()
	region:ClearAllPoints()
	region:SetSize(w / divisor, h / divisor)
	for i = 1, n do
		local point, relTo, relPoint, x, y = source:GetPoint(i)
		region:SetPoint(point, remap[relTo] or default, relPoint, x / divisor, y / divisor)
	end
	return true
end

-- Anchor a text fontstring straight from a layout string's Anchor settings, rather than
-- mirroring the Texts module's fontstring. Masque-skinned strings (SkinAs ~= "", e.g. the
-- default stacks string's "Count") are positioned by MASQUE relative to its own button, NOT
-- by the layout's SetPoint (see IconModule_Texts:SetupForIcon), so their fontstring geometry
-- is Masque's and mirrors to the wrong place on our button. The layout's Anchors are the
-- position the user actually configured, so use them directly.
--
-- Each anchor's relativeTo is resolved the way Texts:GetAnchor does, then remapped onto our
-- button and its children the same way MirrorPoints does: "" is the icon frame (-> button);
-- "$$N" points at layout string N (-> our copy of it, remap[realFsOfN]); anything else names
-- an icon-module frame, icon:GetName()..relativeTo (e.g. the TimerBar/IconContainer frames
-- the bar views mirror into remap). Unresolved names fall back to the button.
local function AnchorFromSettings(region, stringSettings, realTexts, icon, remap, button)
	local anchors = stringSettings.Anchors
	if not anchors or anchors.n == 0 then
		return false
	end
	region:ClearAllPoints()
	for _, a in TMW:InNLengthTable(anchors) do
		local relTo = a.relativeTo
		local target
		if relTo == "" then
			target = button
		elseif relTo:sub(1, 2) == "$$" then
			local index = tonumber(relTo:sub(3))
			local layout = realTexts.layoutSettings
			local relSettings = index and layout and index <= layout.n and layout[index]
			local relFs = relSettings and realTexts.fontStrings[realTexts:GetFontStringID(index, relSettings)]
			target = remap[relFs] or button
		else
			-- An icon-module frame. Resolve it to the real frame, then remap to our
			-- button-side equivalent (the bar views mirror TimerBar/IconContainer into
			-- remap); no equivalent -> the button.
			local frame = _G[icon:GetName() .. relTo]
			target = (frame and remap[frame]) or button
		end
		region:SetPoint(a.point, target, a.relativePoint, a.x, a.y)
	end
	return true
end

-- Create the button's icon holder / texture / cooldown / status bar (once). They live as
-- children of the container-owned button so they inherit its forbidden aspects.
function Module:EnsureButtonWidgets(button)
	-- The icon texture hangs off the holder Masque skins rather than off the button
	-- directly. Masque's icon skinning re-parents the region it's given onto that holder
	-- (Masque/Core/Regions/Icon.lua), and the button stamps ChangeParent on everything handed
	-- to SetIcon, which makes the re-parent a hard error rather than a no-op. Starting the
	-- texture where Masque wants it leaves nothing for that call to do, and swallowing it
	-- keeps Masque from erroring. The holder exists even without Masque - it's then just the
	-- texture's parent, covering the button (see ResetIconHolder).
	local holder = button.tmwIconHolder
	if not holder then
		holder = CreateFrame("Button", nil, button)
		holder:SetAllPoints(button)
		button.tmwIconHolder = holder
	end

	if not button.tmwIcon then
		local tex = holder:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(button)
		tex.SetParent = TMW.NULLFUNC
		button.tmwIcon = tex
	end

	if not button.tmwCooldown then
		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cd:SetAllPoints(button)
		cd:SetReverse(true)
		cd:SetFrameLevel(button:GetFrameLevel() + LEVEL_COOLDOWN)
		button.tmwCooldown = cd
	end

	if not button.tmwStatusBar then
		-- A StatusBar for the duration, used by the bar views (driven via
		-- SetDurationBar). Hidden by default; the icon view never shows it.
		local bar = CreateFrame("StatusBar", nil, button)
		bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		bar:SetAllPoints(button)
		bar:Hide()
		button.tmwStatusBar = bar
	end
end

-- Configure the button's icon texture / cooldown from the icon settings (texture
-- override suppression, ShowTimer/ShowTimerText). Runs before the view emulation,
-- which owns the icon texture's final visibility (bar views hide it when there's no
-- icon square). No frame-state reads - the button's shown state is secret.
--
-- `settingsIcon` is the icon these settings are READ from - self.icon normally, but
-- the inherited source icon for a meta icon (SetupForIcon hands us that). The view /
-- text / size still come from self.icon; only these settings are inherited.
function Module:ApplyButtonSettings(button, settingsIcon)
	settingsIcon = settingsIcon or self.icon
	local showTimer = settingsIcon.ShowTimer
	local showText = settingsIcon.ShowTimerText

	-- The button shows its own (Blizzard) tooltip from its own OnEnter, so the global
	-- tooltip settings have to be pushed onto it. IconModule_IconTooltip, which handles
	-- every other icon type, is disallowed here precisely because these already have
	-- tooltips - but they'd otherwise ignore the setting that turns them off.
	-- Taking the mouse away is the only off switch: an AuraButton has no "tooltips shown"
	-- API, only the combat one below.
	button:SetMouseMotionEnabled(TMW.db.global.ShowTooltips)
	button:SetHideTooltipInCombat(TMW.db.global.TooltipsHideInCombat)

	-- Custom Texture override: paint it onto our icon and ClearIcon so the container stops
	-- painting the aura's icon into it (the native Texture_Colored can't help - it can't evaluate
	-- overrides under our secret state and is gated hidden while the aura is present). Decide off
	-- the SETTING, not the resolved texture: neither CustomTex_OverrideTex nor attributes.texture
	-- is populated until the CustomTex hook implements (after our reskin), so Module:TEXTURE
	-- re-applies the texture once it resolves.
	button.tmwIcon:SetTexture(settingsIcon.attributes.texture)
	button.tmwIcon:Show()
	local customTex = settingsIcon and settingsIcon:GetSettings().CustomTex
	local hasTextureOverride = customTex and customTex:trim() ~= ""
	if hasTextureOverride then
		button:ClearIcon()
	else
		button:SetIcon(button.tmwIcon)
	end

	local cd = button.tmwCooldown
	if cd then
		if showTimer or showText then
			cd:Show()
			cd:SetDrawSwipe(showTimer)
			cd:SetHideCountdownNumbers(not showText)
			cd:SetDrawBling(not TMW.db.profile.HideBlizzCDBling)
			cd:SetDrawEdge(TMW.db.profile.DrawEdge)
			button:SetDurationCooldown(cd)
		else
			-- ClearDurationCooldown only drops the button's reference to our frame; it
			-- never touches the frame, so a sweep already running on it would keep
			-- playing out to its end. Stop it ourselves.
			button:ClearDurationCooldown()
			cd:Clear()
			cd:Hide()
		end
	end
end

-- Tint / desaturate the button's icon texture from the Auras state, the way
-- IconModule_Texture_Colored does it for an ordinary icon's texture. The icon's own texture
-- takes the UNDERLAY state's color instead (GetIconState publishes it and Texture_Colored
-- paints it there), so the two layers color independently, like their opacities do.
--
-- Read from settingsIcon, like the texture this tints. No secret-state branch: this is the
-- configured state rather than a runtime-arbitrated one, so there's no boolean secret to
-- evaluate a curve from - and nothing per-aura, since one skin covers every cell.
--
-- The container never touches either property on a texture handed to SetIcon (it only ever
-- calls SetTexture on it - AuraContainerUtil.SetIconTextureForAura), so this survives every
-- aura the button goes on to show.
function Module:ApplyButtonColor(button, settingsIcon)
	settingsIcon = settingsIcon or self.icon
	local c = TMW:StringToCachedRGBATable(settingsIcon.States[STATE_PRESENT].Color or "ffffffff")

	if not (LMB and OnlyMSQ) then
		button.tmwIcon:SetVertexColor(c.r, c.g, c.b, 1)
	else
		button.tmwIcon:SetVertexColor(1, 1, 1, 1)
	end
	button.tmwIcon:SetDesaturated(c.flags and c.flags.desaturate or false)

	if LMB and ColorMSQ then
		-- The holder's equivalent of icon.normaltex (IconModule_IconContainer_Masque sets that
		-- one from the same pair). Nil until Masque has skinned the holder, which is why this
		-- runs after the view emulation rather than inside ApplyButtonSettings.
		local holder = button.tmwIconHolder
		local normaltex = holder.__MSQ_NormalTexture or holder:GetNormalTexture()
		if normaltex then
			normaltex:SetVertexColor(c.r, c.g, c.b, 1)
		end
	end
end

-- Return the icon holder to its unskinned state: covering the button at the button's own
-- level, shown, since it parents the icon texture whether Masque is involved or not.
local function ResetIconHolder(button)
	local holder = button.tmwIconHolder
	holder:ClearAllPoints()
	holder:SetAllPoints(button)
	holder:SetFrameLevel(button:GetFrameLevel() + LEVEL_ICON)
	holder:Show()
end

-- Masque draws its Backdrop, Gloss and Shadow from a texture cache shared by every button in
-- the UI (Masque/Core/Regions/{Backdrop,Gloss,Shadow}.lua), moving whichever one it takes onto
-- the button it's skinning with a bare SetParent. Our holder is a child of the container-owned
-- AuraButton, and a texture born outside that subtree cannot be moved into it - it would gain
-- the button's forbidden aspects (UntrustedScriptExecution and the rest), which the engine
-- rejects outright, killing the whole skin pass and the icon setup around it.
local MASQUE_POOLED_REGIONS = { "Backdrop", "Gloss", "Shadow" }

-- Replace any pooled region Masque took from that cache with a texture created here, so its
-- next SetParent has nothing to do. Masque records the region on the holder before the
-- SetParent that fails, and only reaches for the cache when that record is empty, so a failed
-- skin leaves exactly what we need to fix it. Regions Masque didn't ask for are left alone:
-- seeding one would only be handed back to the cache when the skin turns that region off (the
-- Remove_* half of those files), for some other addon's button to choke on instead.
local function ClaimPooledMasqueRegions(holder)
	local cfg = holder._MSQ_CFG
	if not cfg then
		return false
	end

	local claimed = false
	for _, region in ipairs(MASQUE_POOLED_REGIONS) do
		local texture = cfg[region]
		if texture and texture:GetParent() ~= holder then
			cfg[region] = holder:CreateTexture()
			claimed = true
		end
	end
	return claimed
end

-- AddButton registers the holder the first time; on later calls it early-returns (already in
-- the group) without re-skinning. Masque otherwise re-scales via the frame's OnSizeChanged
-- hook, but our GetSize is a shadow updated only by the caller below - after the positioner's
-- SetSize already fired OnSizeChanged with the stale value - so the icon/cooldown scale would
-- freeze at the size from the first skin. ReSkin re-runs SkinButton now, reading the current
-- (shadowed) size, so they track the Icon width/height and border-inset changes.
local function SkinHolder(lmbGroup, holder, regions)
	lmbGroup:AddButton(holder, regions, "Legacy")
	lmbGroup:ReSkin(holder)
end

-- Masque-skin the button's holder (and the icon/cooldown handed to it), returning the
-- holder. The container-owned AuraButton can't be Masque'd directly: it's forbidden, so its
-- GetSize() reads back as a secret and Masque's UpdateScale divides by it (taint). The
-- holder (a child of the button, so it can anchor to the button and stay correctly placed -
-- group controllers included) stands in, and we shadow its GetSize with the known non-secret
-- size so Masque never touches the secret. `positioner(holder)` positions + sizes the holder
-- for the view and returns that (non-secret) size.
function Module:SkinMasqueHolder(button, lmbGroup, tex, cd, frameLevel, positioner)
	local holder = button.tmwIconHolder
	holder:Show()
	holder:SetFrameLevel(frameLevel)
	local w, h = positioner(holder)
	holder.GetSize = function() return w, h end

	-- A skin that stops on a pooled region takes the one it stopped on and tries again, so
	-- the worst case is one pass per region before the skin runs to the end.
	local regions = { Icon = tex, Cooldown = cd }
	for _ = 1, #MASQUE_POOLED_REGIONS do
		if pcall(SkinHolder, lmbGroup, holder, regions) then
			return holder
		end
		if not ClaimPooledMasqueRegions(holder) then
			break
		end
	end

	-- Every pooled region is ours and it still won't skin, so the cache isn't what's wrong.
	-- Run it unprotected and let the error be seen.
	SkinHolder(lmbGroup, holder, regions)
	return holder
end

-- Icon view: the button IS the icon square. Masque-skins it (via a holder) and borders it.
function Module:Emulate_IconView_Icon(icon, button)
	-- The button covers the icon, so text strings that anchor to the icon remap to
	-- the button. Returned for the text wiring.
	local remap = { [icon] = button }

	-- Default to bordering the button itself (no-Masque path).
	local iconRegion = button

	local lmbGroup = icon.lmbGroup
	if lmbGroup then
		iconRegion = self:SkinMasqueHolder(button, lmbGroup, button.tmwIcon, button.tmwCooldown,
			button:GetFrameLevel() + LEVEL_ICON, function(holder)
				holder:SetAllPoints(button)
				return icon:GetSize()
			end)
	else
		ResetIconHolder(button)
	end

	self:Emulate_IconModule_IconContainer(icon, button, iconRegion)
	-- The button is the icon square in this view, so the square pandemic art always fits.
	local cellW, cellH = icon:GetSize()
	self:Emulate_PandemicFX(icon, button, { frame = button, width = cellW, height = cellH })

	return remap
end

-- The bar views' StatusBar texture (the configured LSM statusbar), matching
-- IconModule_TimerBar's OnEnable.
local function GetBarTexture(icon)
	local name = icon.group.TextureName
	if not name or name == "" then
		name = TMW.db.profile.TextureName
	end
	return LSM:Fetch("statusbar", name)
end

-- A single static bar color, resolved the way TimerBar_BarDisplay:SetupColors does it: the
-- icon's own color while it overrides, else the group's, else the global one.
--
-- Static in two senses, both forced. TMW's normal bars gradient start->complete over the
-- remaining time, which needs a value that's secret here. And nothing unit-dependent (class
-- color) is possible either: this only runs while skinning a button, which the container's
-- access restriction blocks for as long as auras are secret, so a color chosen from the
-- unit would be stuck on whichever unit was current at skin time and could never follow a
-- target swap.
local function GetBarColor(icon)
	local color = TMW:GetColors("TimerBar_StartColor", "TimerBar_EnableColors",
		icon:GetSettings(), icon.group:GetSettings(), TMW.db.global)
	return TMW:StringToCachedColorMixin(color or "ffff0000"):GetRGBA()
end

-- Bar / barv views: mirror the frames the view already positioned - IconContainer's
-- Masque square and TimerBar's bar container (both laid out with the user's padding,
-- inset, flip and borders) - onto the button, remapping their relativeTo so the
-- anchors stay valid on the forbidden button: the icon -> our button, the icon square
-- -> our mirrored copy of it. The duration StatusBar fills the mirrored bar region and
-- is driven via SetDurationBar. `vertical` only selects the bar's orientation (barv).
function Module:Emulate_IconView_Bar(icon, button, vertical)
	-- Both are wanted for their frames' geometry alone, so take them disabled or unimplemented:
	-- a bar view without an icon square leaves IconContainer off, and this icon type never
	-- allows TimerBar_BarDisplay at all (the view still lays its frames out for us to mirror).
	local iconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer_Masque", true, true)
	local iconSquare = iconContainer and iconContainer.container
	local timerBar = icon:GetModuleOrModuleChild("IconModule_TimerBar_BarDisplay", true, true)
	local barRef = timerBar and timerBar.container

	-- base is the button's level (set by the container); we only order our own frames
	-- under it, from the LEVEL_* stack.
	local base = button:GetFrameLevel()

	local tex, cd, bar = button.tmwIcon, button.tmwCooldown, button.tmwStatusBar
	local lmbGroup = icon.lmbGroup
	local remap = { [icon] = button }

	cd:SetFrameLevel(base + LEVEL_COOLDOWN)
	bar:SetFrameLevel(base + LEVEL_BAR)

	-- Icon square. `iconRegion` is whatever ends up playing it (the Masque holder or
	-- the bare texture), used to anchor the recreated icon border below.
	local iconRegion
	if icon.group:GetSettingsPerView().Icon and iconSquare then
		tex:Show()
		if lmbGroup then
			-- Masque-skin the icon square via a holder sized to the mirrored square.
			iconRegion = self:SkinMasqueHolder(button, lmbGroup, tex, cd, base + LEVEL_ICON, function(holder)
				MirrorPoints(holder, iconSquare, remap, button)
				return iconSquare:GetSize()
			end)
			remap[iconSquare] = iconRegion
		else
			ResetIconHolder(button)
			MirrorPoints(tex, iconSquare, remap, button)
			MirrorPoints(cd, iconSquare, remap, button)
			remap[iconSquare] = tex
			iconRegion = tex
		end
	else
		-- No icon square at all: hiding the holder takes the icon texture and any Masque
		-- skin on it with it.
		tex:Hide()
		button.tmwIconHolder:Hide()
		button:ClearDurationCooldown()
		cd:Hide()
	end

	self:Emulate_IconModule_IconContainer(icon, button, iconRegion)
	-- The art wraps the icon square, same as in the icon view - wrapping the whole cell would
	-- put the indicator around the bar as well. With the icon square turned off there's
	-- nothing of the right shape to wrap, so no target and no indicator.
	local target
	if iconRegion then
		local iconW, iconH = iconSquare:GetSize()
		target = { frame = iconRegion, width = iconW, height = iconH }
	end
	self:Emulate_PandemicFX(icon, button, target)

	-- Duration bar: mirror the view's TimerBar container (anchored to the icon and
	-- the icon square, both remapped above). The bar is scaled to whole screen pixels
	-- so Blizzard's SetDurationBar fill animates smoothly; because that scale distorts
	-- SetPoint offsets, the mirror divides them back out (see MirrorPoints's `divisor`).
	local barScale = PixelUtil.GetPixelToUIUnitFactor() / icon:GetEffectiveScale()
	if barRef and MirrorPoints(bar, barRef, remap, button, barScale) then
		bar:Show()
		bar:SetScale(barScale)
		bar:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
		bar:SetRotatesTexture(vertical)
		bar:SetStatusBarTexture(GetBarTexture(icon))
		bar:SetStatusBarColor(GetBarColor(icon))
		bar:SetReverseFill(icon.BarDisplay_Reverse)
		button:SetDurationBar(bar, {
			direction = icon.BarDisplay_Invert and Enum.StatusBarTimerDirection.ElapsedTime
				or Enum.StatusBarTimerDirection.RemainingTime,
			interpolation = icon.BarDisplay_Smoothing,
		})

		-- Bar text (bar1/bar2 layouts) anchors to the TimerBar's bar frame; remap
		-- both it and the container to our StatusBar so the text wiring places text.
		remap[barRef] = bar
		if timerBar.bar then
			remap[timerBar.bar] = bar
		end

		self:Emulate_IconModule_Backdrop(icon, button, bar, vertical)
	else
		bar:Hide()
		if button.tmwBarBackdrop then
			button.tmwBarBackdrop:Hide()
		end
		button:ClearDurationBar()
	end

	return remap
end

-- Emulate visual aspects of the IconModule_Backdrop into the aura container.
function Module:Emulate_IconModule_Backdrop(icon, button, bar, vertical)
	local base = button:GetFrameLevel()

	local frame = button.tmwBarBackdrop
	if not frame then
		frame = CreateFrame("Frame", nil, button)
		frame.tex = frame:CreateTexture(nil, "BACKGROUND")
		frame.tex:SetAllPoints(frame)
		button.tmwBarBackdrop = frame
	end
	frame:ClearAllPoints()
	frame:SetAllPoints(bar)
	frame:SetFrameLevel(base + LEVEL_BACKDROP)
	frame:Show()

	frame.tex:SetTexture(GetBarTexture(icon))
	if vertical then
		frame.tex:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
	else
		frame.tex:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
	end
	local c = TMW:StringToCachedRGBATable(
		TMW:GetColors("BackdropColor", "BackdropColor_Enable", icon:GetSettings(), icon.group:GetSettings(), TMW.db.global)
	)
	frame.tex:SetVertexColor(c.r, c.g, c.b, 1)
	frame.tex:SetAlpha(c.a)

	local gspv = icon.group:GetSettingsPerView()
	if gspv.BorderBar and gspv.BorderBar ~= 0 then
		local border = frame.border
		if not border then
			-- Build it from the GenericBorder class (which supplies SetBorderSize/SetColor)
			-- plus the TellMeWhen_GenericBorder template (which supplies the edge textures).
			-- We instantiate in Lua rather than relying on the template's OnLoad because this
			-- border is parented to the forbidden AuraButton, and restricted frames never
			-- fire OnLoad.
			border = TMW.Classes.GenericBorder:New("Frame", nil, frame, "TellMeWhen_GenericBorder")
			frame.border = border
		end
		border:SetFrameLevel(base + LEVEL_BORDER)
		border:SetBorderSize(gspv.BorderBar)
		border:SetColor(TMW:StringToRGBA(gspv.BorderColor))
		border:Show()
	elseif frame.border then
		frame.border:Hide()
	end
end

-- Emulate visual aspects of the IconContainer into the aura container.
function Module:Emulate_IconModule_IconContainer(icon, button, iconRegion)
	local border = button.tmwIconBorder
	local gspv = icon.group:GetSettingsPerView()

	if iconRegion and gspv.BorderIcon and gspv.BorderIcon ~= 0 then
		if not border then
			border = TMW.Classes.GenericBorder:New("Frame", nil, button, "TellMeWhen_GenericBorder")
			button.tmwIconBorder = border
		end
		border:ClearAllPoints()
		border:SetAllPoints(iconRegion)
		border:SetFrameLevel(button:GetFrameLevel() + LEVEL_BORDER)
		-- Inset borders use a negative size (matching IconContainer:SetBorder).
		border:SetBorderSize(gspv.BorderInset and -gspv.BorderIcon or gspv.BorderIcon)
		border:SetColor(TMW:StringToRGBA(gspv.BorderColor))
		border:Show()
	elseif border then
		border:Hide()
	end
end

-- Blizzard's Cooldown Manager anchors its pandemic art outside the frame it surrounds -
-- 6px around a ~40px icon - so the glow reads as a halo rather than an inner border.
-- Expressed as a fraction of our own size, which varies per icon.
local PANDEMIC_OVERHANG = 0.15

-- Where a pandemic style draws, built by the view emulation and handed to the style:
--   frame   the region the art wraps
--   width   that region's size. Passed rather than read back, because the regions here are
--   height  children of the forbidden AuraButton and their GetSize is secret - it always
--           comes from the icon-side frame the button is mirroring.
--
-- Wrap `target` with the art, growing it outward by `scale` about its center.
local function AnchorPandemicRegion(region, button, target, scale)
	local w, h = target.width, target.height
	local insetX, insetY = w * (scale - 1) / 2, h * (scale - 1) / 2

	region:ClearAllPoints()
	region:SetPoint("TOPLEFT", target.frame, "TOPLEFT", -insetX, insetY)
	region:SetPoint("BOTTOMRIGHT", target.frame, "BOTTOMRIGHT", insetX, -insetY)
	region:SetFrameLevel(button:GetFrameLevel() + LEVEL_PANDEMIC)

	return w * scale, h * scale
end

RegisterPandemicStyle("ACTVTNBORDER", {
	text = L["ICONMENU_PANDEMICSTYLE_ACTVTNBORDER"],
	desc = L["ICONMENU_PANDEMICSTYLE_ACTVTNBORDER_DESC"],
	ConfigFrames = {},

	Build = function(button)
		-- IconModule_IconContainer picks this template by feature detection because it also
		-- runs on classic; this file is 12.1-only, where the post-11.1.7 name and ProcStartAnim
		-- are both a given.
		local overlay = CreateFrame("Frame", nil, button, "ActionButtonSpellAlertTemplate")

		-- Same treatment IconContainer gives it: the 10.1.5 intro animation looks wrong
		-- looping, so only ProcLoop is used and the flipbook is stopped from re-showing itself.
		overlay.ProcStartFlipbook:Hide()
		overlay.ProcStartFlipbook.Show = TMW.NULLFUNC

		overlay.ProcLoop:Play()
		return overlay
	end,

	Configure = function(icon, button, overlay, target)
		-- The overscale IconContainer gives this art, so a container aura matches a normal
		-- TMW icon wearing the same border.
		AnchorPandemicRegion(overlay, button, target, 1.4)
	end,
})

RegisterPandemicStyle("CDM", {
	text = L["ICONMENU_PANDEMICSTYLE_CDM"],
	desc = L["ICONMENU_PANDEMICSTYLE_CDM_DESC"],

	-- No color: the art carries its own, and Blizzard never tints it. Vertex color would
	-- only multiply it darker rather than recolor it.
	ConfigFrames = {},

	Build = function(button)
		local fx = CreateFrame("Frame", nil, button, "CooldownPandemicFXTemplate")

		-- The template inherits AnimateWhileShownTemplate, which starts the loop from OnShow -
		-- and scripts never fire on a descendant of the forbidden AuraButton. PlayAnims walks
		-- the frame and its children, so calling it directly reaches the group on the FX child.
		fx:PlayAnims()
		return fx
	end,

	Configure = function(icon, button, fx, target)
		AnchorPandemicRegion(fx, button, target, 1 + PANDEMIC_OVERHANG * 2)
	end,
})

RegisterPandemicStyle("BORDER", {
	text = L["ICONMENU_PANDEMICSTYLE_BORDER"],
	desc = L["ICONMENU_PANDEMICSTYLE_BORDER_DESC"],
	ConfigFrames = { "Color", "Thickness" },

	Build = function(button)
		-- Built from the class + template rather than by inheriting the template's OnLoad,
		-- which never fires here (see Emulate_IconModule_Backdrop).
		return TMW.Classes.GenericBorder:New("Frame", nil, button, "TellMeWhen_GenericBorder")
	end,

	Configure = function(icon, button, border, target)
		AnchorPandemicRegion(border, button, target, 1)
		-- Always inset (negative size, matching IconContainer:SetBorder), regardless of the
		-- group's own border inset setting: this border is drawn over an aura that already
		-- fills its cell, and container cells sit at the group's spacing - commonly 0 - so
		-- an outset border would run into the neighbouring aura.
		border:SetBorderSize(-icon.PandemicThickness)
		border:SetColor(TMW:StringToRGBA(icon.PandemicColor))
	end,
})

-- Indicator shown while an aura is inside its pandemic window - the tail of its duration
-- during which recasting carries the remainder over into the new application. The window is
-- derived from secret durations, so the AuraButton computes it and owns the indicator's
-- shown state; we only build the art and hand it over.
--
-- `target` says what to wrap and how big it is (see AnchorPandemicRegion), or is nil when the
-- view has nothing to wrap - which tears down whatever was there and draws nothing.
function Module:Emulate_PandemicFX(icon, button, target)
	local regions = button.tmwPandemicRegions
	local style = target and icon.ShowPandemic and PandemicStyles[icon.PandemicStyle]

	-- Regions are cached per style, so a button holds one for each style it has actually been
	-- configured with and switching back to a previous one reuses it.
	local cacheKey = style and style.key

	if regions then
		for key, region in pairs(regions) do
			if key ~= cacheKey then
				region:Hide()
			end
		end
	end

	-- Registrations accumulate, so drop the previous one before re-adding on a reskin.
	button:ClearPandemicRegions()

	if not style then
		return
	end

	regions = regions or {}
	button.tmwPandemicRegions = regions

	local region = regions[cacheKey]
	if not region then
		region = style.Build(button, target)
		regions[cacheKey] = region
	end

	style.Configure(icon, button, region, target)

	-- No Show() here: registering drives visibility off the current aura, which for a
	-- button with no aura (or no pandemic window) means hidden.
	button:AddPandemicRegion(region)
end

-- Mirror the icon's text layout onto the button. IconModule_Texts creates + positions its own
-- fontstring per string; we create a button-owned copy, style it from the same layout
-- settings, mirror its position, and give it a value based on the string's Aura purpose (see
-- TEXT.AuraContainerTexts): "spell"/"duration"/"stacks" are handed to the matching AuraButton
-- API, which drives them with the aura's real (secret) value, and the default takes a one-shot
-- evaluation of the display's DogTag string. The icon's own copies go dark while locked (see
-- Texts:OnKwargsUpdated) - they sit under the container and know nothing about which cells
-- actually hold an aura.
function Module:Emulate_IconModule_Texts(icon, button, remap)
	-- Disabled/unimplemented included: a reskin can run mid-setup, before the text module has
	-- been implemented into the icon for this pass (we implement at a lower order than it).
	local realTexts = icon:GetModuleOrModuleChild("IconModule_Texts", true, true)
	local layout = realTexts and realTexts.layoutSettings
	-- Keyed by IconModule_Texts' own fontstring ID: a layout can hold any number of static
	-- strings, so the Aura purpose alone doesn't identify one.
	button.tmwTexts = button.tmwTexts or {}

	-- The fontstrings live on a dedicated frame at the top of the LEVEL_* stack: the icon
	-- holder, bar and backdrop are all child frames that would otherwise draw over text
	-- placed on the button itself.
	local textFrame = button.tmwTextFrame
	if not textFrame then
		textFrame = CreateFrame("Frame", nil, button)
		button.tmwTextFrame = textFrame
	end
	textFrame:SetAllPoints(button)
	textFrame:SetFrameLevel(button:GetFrameLevel() + LEVEL_TEXT)

	-- Hide any strings we no longer use.
	for _, fs in pairs(button.tmwTexts) do
		fs.tmwUsed = nil
	end

	if layout then
		for textID, stringSettings in TMW:InNLengthTable(layout) do
			local aura = stringSettings.Aura
			local fontStringID = realTexts:GetFontStringID(textID, stringSettings)
			local realFs = realTexts.fontStrings[fontStringID]

			local auraFs = button.tmwTexts[fontStringID]
			if not auraFs then
				auraFs = textFrame:CreateFontString(nil, "OVERLAY")
				button.tmwTexts[fontStringID] = auraFs
			end
			auraFs.tmwUsed = true
			auraFs.tmwAura = aura
			auraFs:Show()

			-- Font/justify/size all come from the layout settings directly.
			auraFs:SetFont(LSM:Fetch("font", stringSettings.Name), stringSettings.Size, stringSettings.Outline)
			auraFs:SetJustifyH(stringSettings.Justify)
			auraFs:SetJustifyV(stringSettings.JustifyV)
			auraFs:SetShadowOffset(stringSettings.Shadow, -stringSettings.Shadow)
			auraFs:SetRotation(math.rad(stringSettings.Rotate or 0))
			-- 0 = auto-size to the text (default layout behavior).
			auraFs:SetWidth(stringSettings.Width)
			auraFs:SetHeight(stringSettings.Height)

			-- Position from the layout's own Anchors, not by mirroring realFs: a
			-- Masque-skinned string (SkinAs ~= "", like the stacks "Count") is
			-- positioned by Masque relative to its button, so realFs's geometry
			-- would mirror to the wrong spot. Fall back to mirroring realFs (for a
			-- string with no anchors) or a plain CENTER (no source at all) - either
			-- way it must be anchored to the button or SetSpellName/etc. rejects it.
			if not AnchorFromSettings(auraFs, stringSettings, realTexts, icon, remap, button) then
				if realFs then
					MirrorPoints(auraFs, realFs, remap, button)
					auraFs:SetWidth(stringSettings.Width)
					auraFs:SetHeight(stringSettings.Height)
				else
					auraFs:ClearAllPoints()
					auraFs:SetPoint("CENTER", button)
				end
			end

			-- Later strings can anchor to this one ($$N); redirect to our copy.
			if realFs then
				remap[realFs] = auraFs
			end

			if aura == "spell" then
				button:SetSpellName(auraFs)
			elseif aura == "duration" then
				-- Format the AuraButton's secret duration the TMW way (see durationFormatter).
				button:SetDurationText(auraFs, { textFormatter = durationFormatter })
			elseif aura == "stacks" then
				button:SetApplicationCount(auraFs, {})
			else
				-- Evaluated once, here, and left alone: DogTag would have to write to it on
				-- its own schedule, and this string is a descendant of the button, so it's
				-- off limits to us for as long as auras are secret.
				auraFs:SetText(realTexts:EvaluateDogTagText(textID))
			end
		end
	end

	for _, fs in pairs(button.tmwTexts) do
		if not fs.tmwUsed then
			fs:Hide()
			-- Unbind it from the button too, not just hide it: the button keeps its duration
			-- text binding across reconfiguration, so an abandoned string would still be
			-- driven by it.
			local aura = fs.tmwAura
			if aura == "spell" then
				button:ClearSpellName()
			elseif aura == "duration" then
				button:ClearDurationText()
			elseif aura == "stacks" then
				button:ClearApplicationCount()
			end
		end
	end
end

-- Skin one container-owned AuraButton to the current icon settings + view. Idempotent;
-- runs for each recorded button in ReskinButtons. Every button mirrors self.icon (all
-- icons in a group controller share the same view/skin/size), so it looks like a
-- normal TMW icon regardless of where the container placed it.
--
-- Callers must reach this either from an initializeFrame callback or with auras non-secret
-- (see pendingReskin) - every call below is on a frame the container restricts otherwise.
function Module:SkinButton(button)
	local icon = self.icon
	self:EnsureButtonWidgets(button)

	-- The flow layout only anchors the button (single point) + auto-sizes the
	-- container; the button itself needs an explicit size or it's 0x0. Match the cell.
	local w, h = icon:GetSize()
	if w and w > 0 then
		button:SetSize(w, h)
	end

	-- Icon/cooldown settings first; the view emulation then owns the icon texture's
	-- final visibility and the bar/border/text geometry. Timer/texture settings are
	-- read from self.settingsIcon (the inherited source for a meta icon).
	self:ApplyButtonSettings(button, self.settingsIcon)

	-- Each view registers its own emulation handler (see the view files); it skins the
	-- button for that view and returns a frame remap (icon/square/bar -> our button-
	-- owned equivalents) so the text wiring can position the aura-driven text the same way.
	local remap = self.ViewEmulationHandler and self.ViewEmulationHandler(self, icon, button)

	-- After the emulation: the Masque half of this needs the holder Masque has just skinned.
	self:ApplyButtonColor(button, self.settingsIcon)

	self:Emulate_IconModule_Texts(icon, button, remap or { [icon] = button })
end

-- ----------------------------------------------------------------------------
-- The underlay
--
-- An aura that isn't up can't be drawn - the container only ever creates a button for an
-- aura it actually found - so the only way to show anything for a missing aura is to put
-- something behind the container and let it show through. The icon's own display (its
-- texture, the IconContainer's square/border, the Backdrop and its text) already draws
-- underneath the container, so that IS the underlay; all this does is decide whether to
-- leave it up and how opaque to make it.
--
-- Its look comes from a second icon state, which reuses the old absent-state slot so
-- settings from back when this icon type still had an absent state carry over:
--   * PRESENT is the auras' opacity.
--   * UNDERLAY is the underlay's opacity, plus its tint / desaturation / texture. Those
--     ride along on the published state (see GetIconState) - while locked they only ever
--     reach the icon's own texture, which is the underlay and nothing else (an aura button
--     carries its own texture, painted in ApplyButtonSettings).
--
-- The two opacities are independent of each other, which takes some doing: alpha nests, so
-- anything put on the icon frame reaches both layers, and TMW's entire opacity pipeline -
-- the state arbitrator, conditions, group alpha inheritance, fades, config force-show -
-- arrives there as one already-collapsed number. So the icon frame carries only the more
-- opaque of the two (GetIconState) and ApplyOpacities scales each layer down from it.
-- Everything else that dims the icon still dims both layers together, which is right.
-- ----------------------------------------------------------------------------

-- The underlay's opacity, as configured. Zero means there is no underlay at all: the icon's
-- own display comes down entirely, so nothing else should bother drawing into it either.
function Module:GetUnderlayAlpha()
	return self.icon.States[STATE_UNDERLAY].Alpha or 0
end

-- The underlay is four separate frames/regions: the Texture module's texture (a child of
-- the icon, not the IconContainer), the IconContainer's container (icon square / Masque
-- skin / border), the Backdrop's container and the Texts module's container. Run
-- `fn(module, frame)` over each one that exists. Disabled modules are included: a view can
-- have left one off on its own (a bar view without an icon square), and its frame still has
-- to be handed its alpha back.
function Module:ForEachUnderlayFrame(fn)
	local icon = self.icon
	local texture = icon:GetModuleOrModuleChild("IconModule_Texture", true)
	if texture and texture.texture then
		fn(texture, texture.texture)
	end
	local iconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer", true)
	if iconContainer and iconContainer.container then
		fn(iconContainer, iconContainer.container)
	end
	local backdrop = icon:GetModuleOrModuleChild("IconModule_Backdrop", true)
	if backdrop and backdrop.container then
		fn(backdrop, backdrop.container)
	end
	local texts = icon:GetModuleOrModuleChild("IconModule_Texts", true)
	if texts and texts.container then
		fn(texts, texts.container)
	end
end

-- The state an aura-container icon publishes: the icon frame is only the carrier for the
-- two layers, so its alpha is the more opaque of them and ApplyOpacities takes each layer
-- down from there. Called by the icon type from its update function; also used for
-- controlled icons, which have no update function of their own.
--
-- The max rather than a flat 1 so realAlpha keeps meaning what it always has - "is any of
-- this visible" - which the Icon Shown/Hidden conditions, ShrinkGroup, shown-only icon
-- events and meta icon source selection all read. Both opacities at zero then still gives
-- an alpha of 0, which the state arbitrator treats as hide-no-matter-what.
function Module:GetIconState(icon)
	local underlay = icon.States[STATE_UNDERLAY]
	return {
		Alpha = max(icon.States[STATE_PRESENT].Alpha or 0, underlay.Alpha or 0),
		Color = underlay.Color,
		Texture = underlay.Texture,
	}
end

function Module:ApplyOpacities()
	local icon = self.icon
	local locked = TMW.Locked
	local aurasAlpha = icon.States[STATE_PRESENT].Alpha or 0
	-- Config mode shows the icon's own display at full opacity: there's no container over
	-- it there, so it's the icon's preview rather than an underlay.
	local underlayAlpha = 1
	if locked then
		underlayAlpha = self:GetUnderlayAlpha()
	end

	if icon:IsControlled() then
		-- A controlled icon draws nothing of its own but the underlay - the controller's
		-- container covers its cell - and it never runs the icon type's Setup or update
		-- function, so nothing publishes a state for it and it keeps the nothing-state
		-- (alpha 0) that TMW_ICON_SETUP_PRE left. Publish the controller's, but with the
		-- underlay's opacity outright: with no container here the whole icon is the
		-- underlay, so there's nothing to divide that opacity between.
		--
		-- Gated on type allowance because a meta icon can be controlling this group while
		-- borrowing an inherited aura container, and it drives its controlled icons' states
		-- itself.
		if locked and self:IsAllowedByType(icon.Type) then
			local state = self:GetIconState(icon)
			state.Alpha = underlayAlpha
			icon:SetInfo("state", state)
		end
		return
	end

	-- Each layer, relative to the icon frame's own alpha (the more opaque of the two).
	-- Both off: the published state's alpha is 0 as well, so the icon is hidden outright
	-- and there's nothing for these to be relative to.
	local carrier = max(aurasAlpha, underlayAlpha)
	local scale = carrier > 0 and 1 / carrier or 0

	-- The container is the only frame between the icon and the aura buttons, so it's where
	-- the auras' opacity goes. Idempotent - OnEnable has already made one by now.
	local container = self:EnsureContainer()
	if container then
		container:SetAlpha(aurasAlpha * scale)
	end

	-- Alpha only, never Disable. Alpha is inherited by everything under these frames, so
	-- zero hides the icon's own display as completely as disabling did, and leaves the
	-- modules for the view to decide on. Disabling here also took the module out of the
	-- icon events config for as long as it lasted - IconModule_IconContainer is what
	-- registers the activation border animation - and nothing undid it before next setup.
	self:ForEachUnderlayFrame(function(module, frame)
		frame:SetAlpha(underlayAlpha * scale)
	end)
end

-- (Re-)skin every button the container has created for us. Only the opacities apply to
-- controlled icons - the controller drives the shared container's buttons.
--
-- `settingsIcon`, when given, becomes the icon ApplyButtonSettings inherits timer/
-- texture settings from (the source icon for a meta). It's persisted so the deferred
-- reskin of a later runtime batch uses the same source.
function Module:ReskinButtons(settingsIcon)
	if not self.IsEnabled then
		return
	end

	self:ApplyOpacities()

	if self.icon:IsControlled() then
		return
	end

	self:ConfigureContainerLayout()

	-- Recorded before any deferral so a deferred replay inherits from the same source.
	if settingsIcon then
		self.settingsIcon = settingsIcon
	end

	-- While auras are secret the access restriction denies us every call on a button that
	-- carries it, so ask each one whether this (tainted) execution may touch it rather than
	-- assuming from aura secrecy alone - a button whose restriction hasn't landed yet is
	-- still skinnable. Whatever we skip replays once the restriction lifts.
	local secret = ShouldAurasBeSecret()
	for button in pairs(self.buttons) do
		if not secret or button:CanBeAccessedInContext() then
			self:SkinButton(button)
		else
			pendingReskin[self] = true
		end
	end
end


-- ----------------------------------------------------------------------------
-- Container setup + aura spec
-- ----------------------------------------------------------------------------

-- Map a group's LayoutDirection to the anchor corner, the flow growth directions and the
-- fill axis its icons use (see IconPosition_Sortable:Icon_SetPoint). The corner and the two
-- growth directions come from LayoutDirection % 4; directions 1-4 fill a row at a time
-- (horizontal axis, wrapping after Columns icons) and 5-8 fill a column at a time (vertical
-- axis, wrapping after Rows icons).
local function LayoutDirectionAnchor(layoutDirection)
	layoutDirection = layoutDirection or 1
	local axis = layoutDirection >= 5 and FlowLayoutAxis.Vertical or FlowLayoutAxis.Horizontal
	local m = layoutDirection % 4
	if m == 1 then
		return "TOPLEFT", FlowDirection.Right, FlowDirection.Down, axis
	elseif m == 2 then
		return "TOPRIGHT", FlowDirection.Left, FlowDirection.Down, axis
	elseif m == 3 then
		return "BOTTOMRIGHT", FlowDirection.Left, FlowDirection.Up, axis
	else -- m == 0 (LayoutDirection 4 / 8)
		return "BOTTOMLEFT", FlowDirection.Right, FlowDirection.Up, axis
	end
end

-- The container's flow layout. TMW's own per-icon positions can't be reproduced -
-- Blizzard owns the layout now - so we approximate with a uniform grid. Three cases:
--   * Single icon: one cell over the icon.
--   * Fixed-grid controller: pin to the group at the LayoutDirection corner (where icon
--     1 sits) so the auras land on the group's normal fixed icon positions, Columns wide.
--   * ShrinkGroup controller: pin to the group at the group's OWN anchor point (its
--     Point) so it grows from where the group is pinned - a CENTER pin expands
--     symmetrically - as auras come and go.
-- In every controller case the auras FILL in the icon layout direction (the
-- LayoutDirection corner, growth and fill axis), matching Columns/Rows and icon spacing.
function Module:ConfigureContainerLayout()
	local container = self.container
	if not container then
		return
	end
	local icon = self.icon
	local w, h = icon:GetSize()
	w = (w and w > 0) and w or 1
	h = (h and h > 0) and h or 1

	container:SetFlowLayoutPadding(0, 0, 0, 0)
	container:ClearAllPoints()

	local spacingX, spacingY = 0, 0
	local vertical = false
	local group = icon.group
	if icon:IsGroupController() then
		local gs = group:GetSettings()
		local gspv = group:GetSettingsPerView()
		spacingX = gspv.SpacingX or 0
		spacingY = gspv.SpacingY or 0

		local flowPoint, hGrow, vGrow, axis = LayoutDirectionAnchor(group.LayoutDirection)
		vertical = axis == FlowLayoutAxis.Vertical

		-- The auras fill from the LayoutDirection corner; where that block is pinned to
		-- the group differs. Fixed grid: pin to the LayoutDirection corner itself, so the
		-- auras sit on the group's normal fixed icon positions. ShrinkGroup: pin to the
		-- group's own anchor point, so the (auto-resizing) block grows from the pin.
		local anchorPoint = flowPoint
		if group.ShrinkGroup then
			anchorPoint = gs.Point and gs.Point.point or "CENTER"
		end
		container:SetPoint(anchorPoint, group, anchorPoint)
		container:SetFlowLayoutAxis(axis)
		container:SetFlowLayoutAnchorPoint(flowPoint)
		container:SetFlowLayoutGrowthDirection(hGrow, vGrow)
		-- Wrap after `Columns` cells across, or `Rows` cells down when filling by column
		-- (cell = icon size + spacing). A tiny epsilon is added to fight occasional
		-- floating point errors that cause premature wrapping that makes a line skip
		-- placing its last icon.
		if vertical then
			container:SetFlowLayoutMaximumLineSize(max(group.Rows or 1, 1) * (h + spacingY) + 0.1)
		else
			container:SetFlowLayoutMaximumLineSize(max(group.Columns or 1, 1) * (w + spacingX) + 0.1)
		end
	else
		container:SetPoint("TOPLEFT", icon, "TOPLEFT")
		container:SetFlowLayoutAxis(FlowLayoutAxis.Horizontal)
		container:SetFlowLayoutAnchorPoint("TOPLEFT")
		container:SetFlowLayoutGrowthDirection(FlowDirection.Right, FlowDirection.Down)
		container:SetFlowLayoutMaximumLineSize(w)
	end

	-- Match the group's icon spacing between cells (per active group's frames). Spacing is
	-- axis-relative: elementSpacing runs along the fill axis, lineSpacing across it. The
	-- layoutIndex keeps the pooled groups laid out in spec order - without it the container
	-- falls back to registration order, which pooling no longer keeps in step with the spec.
	for index, auraGroup in ipairs(self.groups) do
		container:SetAuraGroupLayout(auraGroup.key, {
			elementSpacing = vertical and spacingY or spacingX,
			lineSpacing = vertical and spacingX or spacingY,
			layoutIndex = index,
		})
	end
end

-- Ensure the index'th aura group exists (group controllers), point it at `filterString` and
-- return it. The pool is keyed by index rather than by filter string: a group can't be
-- removed, but its filter string is mutable (SetAuraGroupFilterString), so reassigning by
-- index avoids accumulating a group - each with its own up-front batch of frames - for every
-- filter string the icon has ever been configured with. Unused ones are parked via
-- maxFrameCount 0.
function Module:EnsureGroup(index, filterString, maxFrameCount)
	local container = self.container
	local auraGroup = self.groups[index]
	if auraGroup then
		container:SetAuraGroupFilterString(auraGroup.key, filterString)
		return auraGroup
	end

	local function initializeFrame(frame)
		self.buttons[frame] = true
		self:SkinButton(frame)
	end

	local key = "tmwGroup" .. index
	container:AddAuraGroup(key, filterString, {
		maxFrameCount = maxFrameCount,
		initializeFrame = initializeFrame,
	})

	auraGroup = { key = key }
	self.groups[index] = auraGroup
	return auraGroup
end

-- A deliberately self-contradictory filter (an aura can't be both HELPFUL and HARMFUL),
-- used to park an unused slot so it shows nothing - slots have no maxFrameCount = 0 knob.
local SLOT_PARK_FILTER = "HELPFUL|HARMFUL"

-- Ensure the index'th aura slot exists (single-aura icons), set its filter string, and
-- return its frame. Slots create ONE frame (no group batch) and are manually anchored, so
-- we place the frame over the icon and record it for skinning. The pool works like the
-- group pool above - reassigned by index across specs.
function Module:EnsureSlot(index, filterString)
	local container = self.container
	local slot = self.slots[index]
	if slot then
		container:SetAuraSlotFilterString(slot.key, filterString)
		return slot
	end

	local key = "tmwSlot" .. index

	-- Slots aren't part of the container's flow layout; anchor the frame over the icon
	-- ourselves. SkinButton sizes it. (Multiple slots on one icon overlap - a single icon
	-- is meant to show one aura; multiple OR'd ExtraFilters are the uncommon exception.)
	-- Like the group path, this all has to happen in initializeFrame - AddAuraSlot returns
	-- a frame the container has already restricted (see pendingReskin), so anchoring or
	-- skinning it off the return value errors outright whenever auras are secret.
	local function initializeFrame(frame)
		self.buttons[frame] = true
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", self.icon)
		self:SkinButton(frame)
	end

	container:AddAuraSlot(key, filterString, { initializeFrame = initializeFrame })

	-- No frame reference kept: outside its initializeFrame window there's nothing we're
	-- allowed to do with one, and the container is addressed by slot key anyway.
	slot = { key = key }
	self.slots[index] = slot
	return slot
end

function Module:DeactivateGroups()
	for i = 1, #self.groups do
		self.container:SetAuraGroupMaxFrameCount(self.groups[i].key, 0)
	end
end

function Module:DeactivateSlots()
	for i = 1, #self.slots do
		-- Note: There's no real API to deactivate a slot.
		-- Best you can do is give it junk filters.
		self.container:SetAuraSlotFilterString(self.slots[i].key, SLOT_PARK_FILTER)
	end
end

-- Create the AuraContainer if it doesn't exist yet, returning it (or nil). Controlled icons
-- never own one - the controller's shared container covers their cells.
function Module:EnsureContainer()
	local container = self.container
	if container then
		return container
	end
	if self.icon:IsControlled() then
		return nil
	end

	local icon = self.icon
	container = CreateFrame("AuraContainer", self:GetChildNameBase() .. "Container", icon, "CustomAuraContainerTemplate")
	container:SetSize(1, 1)
	container:SetFrameLevel(icon:GetFrameLevel() + TMW.CONST.FRAMELEVEL.AURACONTAINER)
	-- The buttons stack another LEVEL_* range on top of this level, so without flattening,
	-- anything meant to draw over the container would have to beat its deepest child
	-- rather than its own level.
	container:SetFlattensRenderLayers(true)
	self.container = container
	-- Anchored by one corner only (ConfigureContainerLayout picks the corner): the
	-- container auto-resizes to fit its flow-laid-out buttons, so SetAllPoints would
	-- fight that. Set a default so it's always anchored before the first layout pass.
	container:SetPoint("TOPLEFT", icon, "TOPLEFT")
	self:ConfigureContainerLayout()
	return container
end

function Module:SetAuraSpec(auraSpec)
	local icon = self.icon

	-- Controlled icons don't own a container; the controller drives the shared one.
	if icon:IsControlled() then
		return
	end

	local container = self:EnsureContainer()
	if not container then
		return
	end

	if not TMW.Locked or not auraSpec or not auraSpec.filters or #auraSpec.filters == 0 then
		-- Deactivate everything; the icon's own modules show the config preview.
		self:TeardownContainer()
		return
	end

	local filters = auraSpec.filters

	if icon:IsGroupController() then
		-- Controller: one pooled AuraGroup per filter, distributing distinct auras across
		-- the group's cells. Park any slots left from a prior standalone setup.
		self:DeactivateSlots()

		-- maxFrameCount caps PER group (no container-wide cap), so with multiple filters
		-- each contributes up to this many, flow-laid-out together by the container.
		local maxFrameCount = icon.group.numIcons
		for i = 1, #filters do
			local f = filters[i]
			local auraGroup = self:EnsureGroup(i, f.filterString, maxFrameCount)

			container:SetAuraGroupMaxFrameCount(auraGroup.key, maxFrameCount)
			container:SetAuraGroupCandidateFilters(auraGroup.key, f.candidateFilters)
			container:SetAuraGroupSortMethod(auraGroup.key, f.sortMethod, f.sortDirection)
		end
		-- Park pooled groups beyond the current filter count.
		for i = #filters + 1, #self.groups do
			container:SetAuraGroupMaxFrameCount(self.groups[i].key, 0)
		end

		self:ConfigureContainerLayout()
	else
		-- Single icon: one AuraSlot per filter string (a single frame each, not a group's
		-- 10-frame batch). Park any groups left from a prior controller setup.
		self:DeactivateGroups()

		for i = 1, #filters do
			local f = filters[i]
			local slot = self:EnsureSlot(i, f.filterString)
			container:SetAuraSlotCandidateFilters(slot.key, f.candidateFilters)
			container:SetAuraSlotSortMethod(slot.key, f.sortMethod, f.sortDirection)
		end
		-- Park pooled slots beyond the current filter count.
		for i = #filters + 1, #self.slots do
			container:SetAuraSlotFilterString(self.slots[i].key, SLOT_PARK_FILTER)
		end
	end

	container:Show()  -- undo the config-mode hide (see the disable path above)
	container:SetUnit(auraSpec.unit or "player")
	container:SetEnabled(true)

	-- Force a full re-read of the current unit's auras. SetUnit only refreshes when the
	-- unit TOKEN changes, but a target swap keeps the token ("target") while the actual
	-- unit changes - and that unit-set change is exactly why we were re-published (the
	-- icon rebuilds a fresh auraSpec table then). Without this the container keeps the
	-- previous target's cached auras.
	container:UpdateAllAuras()
end

function Module:AURASPEC(icon, auraSpec)
	self:SetAuraSpec(auraSpec)
end
Module:SetDataListener("AURASPEC")

-- attributes.texture (which folds in a Custom Texture override) is resolved by the CustomTex
-- hook, which implements AFTER our SetupForIcon reskin - so at reskin time the override may not
-- be on attributes.texture yet, and it also updates later for dynamic ($item/$spell) textures.
-- Re-apply the button icon textures whenever it changes so the override actually lands.
function Module:TEXTURE(icon, texture)
	-- ApplyButtonSettings calls SetIcon/ClearIcon on the button itself, so it's gated by the
	-- same access check a full reskin is (see pendingReskin).
	local secret = ShouldAurasBeSecret()
	for button in pairs(self.buttons) do
		if not secret or button:CanBeAccessedInContext() then
			self:ApplyButtonSettings(button, self.settingsIcon)
		else
			pendingReskin[self] = true
		end
	end
end
Module:SetDataListener("TEXTURE")

-- Meta-icon setup: `icon` is the SOURCE icon whose display this meta inherits. Its
-- timer/texture settings and aura spec come from that source; the view/size/text come
-- from self.icon (the meta). ReskinButtons records the source as self.settingsIcon so
-- the deferred skin of any runtime batch inherits from it too.
function Module:SetupForIcon(icon)
	self:ReskinButtons(icon)
	self:SetAuraSpec(icon.attributes.auraSpec)
end

-- The container's buttons outlive every icon setup - leaving config mode, a profile change, a
-- settings change - and nothing re-skins them on their own. SetupForIcon can't do it: modules
-- are set up as they're implemented, and we implement ahead of IconModule_Texts, so the layout
-- we'd mirror is still the previous pass's. Wait for the icon to finish setting up instead.
TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	local module = icon:GetModuleOrModuleChild("IconModule_AuraContainer")
	if module then
		module:ReskinButtons()
	end
end)

function Module:OnEnable()
	local icon = self.icon

	-- A controlled icon in a group-controller buffcontainer doesn't own a container;
	-- the controller's container covers this icon's cell. We stay enabled so that
	-- IconModule_Texts keeps this icon's own strings dark - the controller's buttons draw
	-- them, and only a button knows whether its cell holds an aura - but any leftover
	-- container from a prior standalone setup is torn down.
	if icon:IsControlled() then
		self:TeardownContainer()
		return
	end

	self:EnsureContainer()
end

function Module:TeardownContainer()
	if self.container then
		self:DeactivateGroups()
		self:DeactivateSlots()
		-- A disabled container drops every aura it had parsed, so this alone empties the
		-- display. The hide is what keeps it empty: the container still (re-)shows slot
		-- frames while disabled, and a child of a hidden frame doesn't render regardless.
		self.container:SetEnabled(false)
		self.container:Hide()
	end
end

function Module:OnDisable()
	-- The underlay alpha sits on frames the icon owns, so it outlives us. Hand them back at
	-- full opacity or whatever displays the icon next inherits our dimming.
	self:ForEachUnderlayFrame(function(module, frame)
		frame:SetAlpha(1)
	end)
	self:TeardownContainer()
end
