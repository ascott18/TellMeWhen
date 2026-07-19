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

-- The container stamps every aura frame with DenyTaintedAccessWhenAurasAreSecret the moment
-- its initializeFrame callback returns (AuraContainerCustomFrameProviderMixin:CreateFrame).
-- While auras are secret that denies us EVERY call on the frame - not just secret-valued
-- reads - so `button:SetSize()` from tainted code is a hard error, not a taint warning. Two
-- consequences run through this file:
--   * A new button can only be skinned inside initializeFrame, before the stamp lands. Both
--     creation paths (EnsureGroup, EnsureSlot) therefore do all their frame work there.
--   * An existing button can only be re-skinned while auras aren't secret. Reskins that
--     arrive at a bad time park their module here and replay once the restriction lifts
--     (leaving combat / an encounter / M+ / PvP).
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

function Module:OnNewInstance(icon)
	-- Buttons are created by the container (not us); we record each one the
	-- container hands to our initializeFrame callback so we can (re-)skin them all.
	-- Keyed by the frame itself.
	self.buttons = {}

	-- Group controllers distribute N distinct auras across the group, so they use aura
	-- GROUPS (keyed by filter string; the string is immutable and groups can't be removed,
	-- so we add each once and toggle maxFrameCount to (de)activate). 
	self.groups = {}
	
	-- A single icon shows one aura, so it uses aura SLOTS instead - one frame each.
	-- Slots are a fixed pool keyed by index (their filter string IS mutable, so we
	-- reassign rather than accumulate); unused ones are parked with a filter matching none.
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
-- ----------------------------------------------------------------------------

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

-- Create the button's icon texture / cooldown / status bar (once). They live as
-- children of the container-owned button so they inherit its forbidden aspects.
function Module:EnsureButtonWidgets(button)
	if not button.tmwIcon then
		local tex = button:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(button)
		button.tmwIcon = tex
	end

	if not button.tmwCooldown then
		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cd:SetAllPoints(button)
		cd:SetReverse(true)
		cd:SetFrameLevel(button:GetFrameLevel() + 1)
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

-- Get-or-create the button's Masque holder and Masque-skin the given icon/cooldown into
-- it, returning the holder. The container-owned AuraButton can't be Masque'd directly:
-- it's forbidden, so its GetSize() reads back as a secret and Masque's UpdateScale divides
-- by it (taint). The holder (a child of the button, so it can anchor to the button and
-- stay correctly placed - group controllers included) stands in, and we shadow its GetSize
-- with the known non-secret size so Masque never touches the secret. `positioner(holder)`
-- positions + sizes the holder for the view and returns that (non-secret) size.
function Module:SkinMasqueHolder(button, lmbGroup, tex, cd, frameLevel, positioner)
	local holder = button.tmwIconHolder
	if not holder then
		holder = CreateFrame("Button", nil, button)
		button.tmwIconHolder = holder
	end
	holder:Show()
	holder:SetFrameLevel(frameLevel)
	local w, h = positioner(holder)
	holder.GetSize = function() return w, h end
	-- AddButton registers the holder the first time; on later calls it early-returns
	-- (already in the group) without re-skinning. Masque otherwise re-scales via the
	-- frame's OnSizeChanged hook, but our GetSize is a shadow updated only just above -
	-- after the positioner's SetSize already fired OnSizeChanged with the stale value - so
	-- the icon/cooldown scale would freeze at the size from the first skin. ReSkin re-runs
	-- SkinButton now, reading the current (shadowed) size, so they track the Icon
	-- width/height and border-inset changes.
	lmbGroup:AddButton(holder, { Icon = tex, Cooldown = cd }, "Legacy")
	lmbGroup:ReSkin(holder)
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
			button:GetFrameLevel() + 1, function(holder)
				holder:SetAllPoints(button)
				return icon:GetSize()
			end)
	elseif button.tmwIconHolder then
		button.tmwIconHolder:Hide()
	end

	self:Emulate_IconModule_IconContainer(icon, button, iconRegion)

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

-- A single static bar color. TMW's normal bar gradients start->complete over the
-- remaining time, but we can't do that here (the remaining time is secret), so we
-- use the "full" (start) color, or the unit's class color if configured.
local function GetBarColor(icon)
	local spec = icon.attributes.auraSpec
	local unit = spec and spec.unit
	if icon.BarDisplay_ClassColor and unit then
		local _, class = UnitClass(unit)
		local c = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
		if c then
			return c.r, c.g, c.b, 1
		end
	end
	return TMW:StringToCachedColorMixin(icon.TimerBar_StartColor or "ffff0000"):GetRGBA()
end

-- Bar / barv views: mirror the frames the view already positioned - IconContainer's
-- Masque square and TimerBar's bar container (both laid out with the user's padding,
-- inset, flip and borders) - onto the button, remapping their relativeTo so the
-- anchors stay valid on the forbidden button: the icon -> our button, the icon square
-- -> our mirrored copy of it. The duration StatusBar fills the mirrored bar region and
-- is driven via SetDurationBar. `vertical` only selects the bar's orientation (barv).
function Module:Emulate_IconView_Bar(icon, button, vertical)
	local Modules = icon.Modules
	local iconContainer = Modules.IconModule_IconContainer_Masque
	local iconSquare = iconContainer and iconContainer.container
	local timerBar = Modules.IconModule_TimerBar_BarDisplay
	local barRef = timerBar and timerBar.container

	-- Frame levels within the button: the fill/backdrop sit below the cooldown, and
	-- the button's own children stay below the (button-owned) text frame. base is the
	-- button's level (set by the container); we only order the children under it.
	local base = button:GetFrameLevel()

	local tex, cd, bar = button.tmwIcon, button.tmwCooldown, button.tmwStatusBar
	local lmbGroup = icon.lmbGroup
	local remap = { [icon] = button }

	cd:SetFrameLevel(base + 2)
	bar:SetFrameLevel(base + 1)

	-- Icon square. `iconRegion` is whatever ends up playing it (the Masque holder or
	-- the bare texture), used to anchor the recreated icon border below.
	local iconRegion
	if icon.group:GetSettingsPerView().Icon and iconSquare then
		tex:Show()
		if lmbGroup then
			-- Masque-skin the icon square via a holder sized to the mirrored square.
			iconRegion = self:SkinMasqueHolder(button, lmbGroup, tex, cd, base + 1, function(holder)
				MirrorPoints(holder, iconSquare, remap, button)
				return iconSquare:GetSize()
			end)
			remap[iconSquare] = iconRegion
		else
			MirrorPoints(tex, iconSquare, remap, button)
			MirrorPoints(cd, iconSquare, remap, button)
			remap[iconSquare] = tex
			iconRegion = tex
		end
	else
		tex:Hide()
		if button.tmwIconHolder then
			button.tmwIconHolder:Hide()
		end
		button:ClearDurationCooldown()
		cd:Hide()
	end

	self:Emulate_IconModule_IconContainer(icon, button, iconRegion)

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
		button:SetDurationBar(bar, {direction = Enum.StatusBarTimerDirection.RemainingTime})

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
	frame:SetParent(button)
	frame:ClearAllPoints()
	frame:SetAllPoints(bar)
	frame:SetFrameLevel(base)          -- behind the bar's fill (base + 1)
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
		border:SetFrameLevel(base + 2)  -- on top of the bar
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
		border:SetParent(button)
		border:ClearAllPoints()
		border:SetAllPoints(iconRegion)
		border:SetFrameLevel(button:GetFrameLevel() + 4)  -- on top of the icon square
		-- Inset borders use a negative size (matching IconContainer:SetBorder).
		border:SetBorderSize(gspv.BorderInset and -gspv.BorderIcon or gspv.BorderIcon)
		border:SetColor(TMW:StringToRGBA(gspv.BorderColor))
		border:Show()
	elseif border then
		border:Hide()
	end
end

-- Drive text strings flagged with an Aura purpose (see TEXT.AuraContainerTexts)
-- with the AuraButton's real value. IconModule_Texts creates + positions its own
-- fontstring per such string; we create a aura-button-owned fontstring,
-- copy that string's font/justify, mirror its position onto the button, and hand it
-- to the matching AuraButton API.
function Module:Emulate_IconModule_Texts(icon, button, remap)
	local realTexts = icon.Modules and icon.Modules.IconModule_Texts
	local layout = realTexts and realTexts.layoutSettings
	button.tmwAuraText = button.tmwAuraText or {}

	-- The fontstrings live on a dedicated frame above everything else on the button
	-- (the bar/backdrop are child frames that would otherwise draw over button-layer
	-- text). Matches where IconModule_Texts sits (icon frame level + 3).
	local textFrame = button.tmwTextFrame
	if not textFrame then
		textFrame = CreateFrame("Frame", nil, button)
		button.tmwTextFrame = textFrame
	end
	textFrame:SetAllPoints(button)
	textFrame:SetFrameLevel(button:GetFrameLevel() + 3)

	-- Hide any strings we no longer use.
	for _, fs in pairs(button.tmwAuraText) do
		fs.tmwUsed = nil
	end

	if layout then
		for textID, stringSettings in TMW:InNLengthTable(layout) do
			local aura = stringSettings.Aura
			if aura and aura ~= "" then
				local realFs = realTexts.fontStrings[realTexts:GetFontStringID(textID, stringSettings)]

				local auraFs = button.tmwAuraText[aura]
				if not auraFs then
					auraFs = textFrame:CreateFontString(nil, "OVERLAY")
					button.tmwAuraText[aura] = auraFs
				end
				auraFs.tmwUsed = true
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
					button:SetDurationText(auraFs, { formatter = durationFormatter })
				elseif aura == "stacks" then
					button:SetApplicationCount(auraFs, {})
				end
			end
		end
	end

	for _, fs in pairs(button.tmwAuraText) do
		if not fs.tmwUsed then
			fs:Hide()
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

	self:Emulate_IconModule_Texts(icon, button, remap or { [icon] = button })
end

-- (Re-)skin every button the container has created for us. No-op
-- for controlled icons - the controller drives the shared container's buttons.
--
-- `settingsIcon`, when given, becomes the icon ApplyButtonSettings inherits timer/
-- texture settings from (the source icon for a meta). It's persisted so the deferred
-- reskin of a later runtime batch uses the same source.
function Module:ReskinButtons(settingsIcon)
	if not self.IsEnabled or self.icon:IsControlled() then
		return
	end

	-- IconContainer and Backdrop are emulated into the aura buttons
	-- so the show/hide according to aura presence. They're still used in config mode,
	-- but need to be disabled in locked mode so the aura buttons can take over.
	local locked = TMW.Locked
	local iconContainer = self.icon:GetModuleOrModuleChild("IconModule_IconContainer")
	if iconContainer then
		if locked then iconContainer:Disable() else iconContainer:Enable() end
	end

	local backdrop = self.icon:GetModuleOrModuleChild("IconModule_Backdrop")
	if backdrop then
		if locked then backdrop:Disable() else backdrop:Enable() end
	end

	local texture = self.icon:GetModuleOrModuleChild("IconModule_Texture")
	if texture then
		if locked then texture:Disable() else texture:Enable() end
	end

	self:ConfigureContainerLayout()

	-- Recorded before the secret bail so a deferred replay inherits from the same source.
	if settingsIcon then
		self.settingsIcon = settingsIcon
	end

	-- Every button here already carries the access restriction (see pendingReskin).
	if ShouldAurasBeSecret() then
		pendingReskin[self] = true
		return
	end
	for button in pairs(self.buttons) do
		self:SkinButton(button)
	end
end


-- ----------------------------------------------------------------------------
-- Container setup + aura spec
-- ----------------------------------------------------------------------------

-- Map a group's LayoutDirection to the anchor corner + flow growth directions its
-- icons use (see IconPosition_Sortable:Icon_SetPoint). Only the corner and the two
-- growth axes are honored (from LayoutDirection % 4); the row-vs-column fill order of
-- directions 5-8 isn't reproduced - Blizzard's flow layout is always row-major - so a
-- column-major group is approximated by the matching corner/axes.
local function LayoutDirectionAnchor(layoutDirection)
	local m = (layoutDirection or 1) % 4
	if m == 1 then
		return "TOPLEFT", FlowDirection.Right, FlowDirection.Down
	elseif m == 2 then
		return "TOPRIGHT", FlowDirection.Left, FlowDirection.Down
	elseif m == 3 then
		return "BOTTOMRIGHT", FlowDirection.Left, FlowDirection.Up
	else -- m == 0 (LayoutDirection 4 / 8)
		return "BOTTOMLEFT", FlowDirection.Right, FlowDirection.Up
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
-- LayoutDirection corner + growth), matching Columns and icon spacing.
function Module:ConfigureContainerLayout()
	local container = self.container
	if not container then
		return
	end
	local icon = self.icon
	local w, h = icon:GetSize()
	w = (w and w > 0) and w or 1
	h = (h and h > 0) and h or 1

	container:SetAuraLayoutPadding(0, 0, 0, 0)
	container:ClearAllPoints()

	local spacingX, spacingY = 0, 0
	local group = icon.group
	if icon:IsGroupController() then
		local gs = group:GetSettings()
		local gspv = group:GetSettingsPerView()
		spacingX = gspv.SpacingX or 0
		spacingY = gspv.SpacingY or 0

		local flowPoint, hGrow, vGrow = LayoutDirectionAnchor(group.LayoutDirection)
		local columns = max(group.Columns or 1, 1)

		-- The auras fill from the LayoutDirection corner; where that block is pinned to
		-- the group differs. Fixed grid: pin to the LayoutDirection corner itself, so the
		-- auras sit on the group's normal fixed icon positions. ShrinkGroup: pin to the
		-- group's own anchor point, so the (auto-resizing) block grows from the pin.
		local anchorPoint = flowPoint
		if group.ShrinkGroup then
			anchorPoint = gs.Point and gs.Point.point or "CENTER"
		end
		container:SetPoint(anchorPoint, group, anchorPoint)
		container:SetAuraLayoutAnchorPoint(flowPoint)
		container:SetAuraLayoutGrowthDirection(hGrow, vGrow)
		-- Wrap after `columns` cells (cell = icon size + spacing).
		-- A tiny epsilon is added to fight occasional floating point errors that
		-- cause premature wrapping that makes a row skip placing its last icon.
		container:SetAuraLayoutRowWidth(columns * (w + spacingX) + 0.1)
	else
		container:SetPoint("TOPLEFT", icon, "TOPLEFT")
		container:SetAuraLayoutAnchorPoint("TOPLEFT")
		container:SetAuraLayoutGrowthDirection(FlowDirection.Right, FlowDirection.Down)
		container:SetAuraLayoutRowWidth(w)
	end

	-- Match the group's icon spacing between cells (per active group's frames).
	for filterString in pairs(self.groups) do
		container:SetAuraGroupLayout(filterString, {
			elementSpacingX = spacingX,
			elementSpacingY = spacingY,
		})
	end
end

-- Ensure an aura group exists for `filterString`. Groups are added once (the filter
-- string is immutable and groups can't be removed) and (de)activated via maxFrameCount.
function Module:EnsureGroup(filterString, maxFrameCount)
	local container = self.container
	if self.groups[filterString] then
		return
	end

	local function initializeFrame(frame)
		self.buttons[frame] = true
		self:SkinButton(frame)
	end

	container:AddAuraGroup(filterString, filterString, {
		maxFrameCount = maxFrameCount,
		initializeFrame = initializeFrame,
	})
	self.groups[filterString] = true
end

-- A deliberately self-contradictory filter (an aura can't be both HELPFUL and HARMFUL),
-- used to park an unused slot so it shows nothing - slots have no maxFrameCount = 0 knob.
local SLOT_PARK_FILTER = "HELPFUL|HARMFUL"

-- Ensure the index'th aura slot exists (single-aura icons), set its filter string, and
-- return its frame. Slots create ONE frame (no group batch) and are manually anchored, so
-- we place the frame over the icon and record it for skinning. The slot pool is reused
-- across specs: a slot's filter string is mutable, so we reassign by index rather than
-- accumulate one per (unremovable) filter string the way groups must.
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
	for filterString in pairs(self.groups) do
		self.container:SetAuraGroupMaxFrameCount(filterString, 0)
	end
end

function Module:DeactivateSlots()
	for i = 1, #self.slots do
		-- Note: There's no real API to deactivate a slot.
		-- Best you can do is give it junk filters.
		self.container:SetAuraSlotFilterString(self.slots[i].key, SLOT_PARK_FILTER)
	end
end

-- Create the AuraContainer if it doesn't exist yet, returning it (or nil). Deferred
-- while in combat: the container is a secure/forbidden frame, and one created during
-- combat has its OnLoad deferred, leaving its internal state (dirtyFlags / event lists)
-- nil - so the first SetAuraLayout*/SetEnabled call on it errors. SetAuraSpec runs every
-- update, so the first update out of combat creates it. Controlled icons never own one.
function Module:EnsureContainer()
	local container = self.container
	if container then
		return container
	end
	if self.icon:IsControlled() or InCombatLockdown() then
		return nil
	end

	local icon = self.icon
	container = CreateFrame("AuraContainer", self:GetChildNameBase() .. "Container", icon, "CustomAuraContainerTemplate")
	container:SetSize(1, 1)
	container:SetFrameLevel(icon:GetFrameLevel() + 5)
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

	-- NB: Container creation deferred while in combat (see EnsureContainer); 
	-- the next out-of-combat update creates it and re-runs this.
	local container = self:EnsureContainer()
	if not container then
		return
	end

	if not TMW.Locked or not auraSpec or not auraSpec.filters or #auraSpec.filters == 0 then
		-- Deactivate everything; the icon's own modules show the config preview. Hiding the
		-- whole container is what actually clears the display: a child of a hidden frame
		-- doesn't render regardless of its own shown state, so it doesn't matter that the
		-- container keeps (re-)showing individual slot frames while disabled.
		self:TeardownContainer()
		return
	end

	local filters = auraSpec.filters

	if icon:IsGroupController() then
		-- Controller: one AuraGroup per filter string, distributing distinct auras across
		-- the group's cells. Park any slots left from a prior standalone setup.
		self:DeactivateSlots()

		-- maxFrameCount caps PER group (no container-wide cap), so with multiple filters
		-- each contributes up to this many, flow-laid-out together by the container.
		local maxFrameCount = icon.group.numIcons
		local wanted = {}
		for i = 1, #filters do
			local f = filters[i]
			local filterString = f.filterString
			wanted[filterString] = true
			self:EnsureGroup(filterString, maxFrameCount)

			container:SetAuraGroupMaxFrameCount(filterString, maxFrameCount)
			container:SetAuraGroupCandidateFilters(filterString, f.candidateFilters)
			if f.sortMethod then
				container:SetAuraGroupSortMethod(filterString, f.sortMethod, f.sortDirection)
			end
		end
		-- Deactivate groups whose filter string is no longer in the spec.
		for filterString in pairs(self.groups) do
			if not wanted[filterString] then
				container:SetAuraGroupMaxFrameCount(filterString, 0)
			end
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
			if f.sortMethod then
				container:SetAuraSlotSortMethod(slot.key, f.sortMethod, f.sortDirection)
			end
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
	-- ApplyButtonSettings calls SetIcon/ClearIcon on the button itself, so it's restricted
	-- while auras are secret just like a full reskin (see pendingReskin).
	if ShouldAurasBeSecret() then
		pendingReskin[self] = true
		return
	end
	for button in pairs(self.buttons) do
		self:ApplyButtonSettings(button, self.settingsIcon)
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

function Module:OnEnable()
	local icon = self.icon

	-- A controlled icon in a group-controller buffcontainer doesn't own a container;
	-- the controller's container covers this icon's cell. Stay enabled (so
	-- IconModule_Texts still suppresses this icon's DogTag-driven aura strings - the
	-- controller's buttons draw the real values) but keep any leftover container from
	-- a prior standalone setup inert.
	if icon:IsControlled() then
		self:Disable()
		return
	end

	-- Create the container now if we can; if we're in combat it's deferred to the first
	-- out-of-combat update (see EnsureContainer).
	self:EnsureContainer()
end

function Module:TeardownContainer()
	if self.container then
		self:DeactivateGroups()
		self:DeactivateSlots()
		self.container:SetEnabled(false)
		self.container:Hide()
	end
end

function Module:OnDisable()
	self:TeardownContainer()
end
