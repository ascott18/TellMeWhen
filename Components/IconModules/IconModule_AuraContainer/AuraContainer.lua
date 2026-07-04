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

local max = math.max
local LSM = LibStub("LibSharedMedia-3.0")

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

-- The bar backdrop color, matching IconModule_Backdrop:SetupForIcon.
local function GetBackdropColor(icon)
	local color = TMW:GetColors("BackdropColor", "BackdropColor_Enable",
		icon:GetSettings(), icon.group:GetSettings(), TMW.db.global)
	return TMW:StringToCachedRGBATable(color)
end

-- ----------------------------------------------------------------------------
-- IconModule_AuraContainer
--
-- Renders auras using Blizzard's 12.1 AuraContainer / AuraButton objects instead
-- of TMW's own scan loop + texture/cooldown/text modules.
--
-- This is the ONLY aura display path that keeps working while auras are secret
-- (combat, encounters, M+, PvP), because the AuraContainer reads and filters the
-- aura data internally and only ever hands the addon presentation widgets. The
-- tradeoff is that addon code never sees the aura data: the container can only
-- filter by broad category (HELPFUL/HARMFUL/PLAYER/IMPORTANT/dispel/...), NOT by
-- a specific spell id or name, and TMW cannot react to presence/absence,
-- sort, run conditions, or feed DogTags from it.
--
-- The icon type feeds this module a static "aura spec" via the AURASPEC
-- IconDataProcessor:
--     spec = {
--         unit = "target",
--         filters = {
--             { filterString = "HARMFUL|INCLUDE_NAME_PLATE_ONLY", maxFrameCount = 1 },
--             ...
--         },
--     }
-- ----------------------------------------------------------------------------


-- The AuraContainer/AuraButton frame types and the Custom*Template templates
-- live in Blizzard's Blizzard_AuraContainer addon, which may be load-on-demand.
local CONTAINER_TEMPLATE = "CustomAuraContainerTemplate"
local BUTTON_TEMPLATE = "CustomAuraButtonTemplate"

local LoadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn

local blizzAddonChecked, blizzAddonAvailable
local function IsBlizzardAuraContainerAvailable()
	if blizzAddonChecked then
		return blizzAddonAvailable
	end
	blizzAddonChecked = true

	-- AuraContainerInbound is the global table exported by Blizzard_AuraContainer.
	if not AuraContainerInbound and LoadAddOn then
		LoadAddOn("Blizzard_AuraContainer")
	end
	blizzAddonAvailable = AuraContainerInbound ~= nil
	return blizzAddonAvailable
end


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


local Module = TMW:NewClass("IconModule_AuraContainer", "IconModule")

-- Off for every icon type unless explicitly allowed. Aura-container icon types
-- opt in with Type:SetModuleAllowance("IconModule_AuraContainer", true).
Module:SetDefaultAllowanceForTypes(false)

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
	self.buttons = {}
	-- Container is created lazily the first time the module is actually used,
	-- so icons that never opt in don't allocate an AuraContainer frame.
end

function Module:EnsureContainer()
	if self.container then
		return true
	end
	if not IsBlizzardAuraContainerAvailable() then
		return false
	end

	local icon = self.icon
	local container = CreateFrame("AuraContainer", self:GetChildNameBase() .. "Container", icon, CONTAINER_TEMPLATE)

	container:SetSize(1, 1)
	container:SetAllPoints(icon)
	self.container = container
	return true
end

function Module:EnsureButtons(count)
	if not self.container then
		return
	end

	local icon = self.icon
	for i = #self.buttons + 1, count do
		local button = CreateFrame("AuraButton", nil, self.container, BUTTON_TEMPLATE)
		button:SetAllPoints(self.container)
		button:SetFrameLevel(icon:GetFrameLevel() + 5)

		-- The AuraButton drives its own (secret) show/hide based on whether an
		-- aura is assigned. We don't want it intercepting mouse from the icon's
		-- own click/drag handling, so leave input disabled.
		button:EnableMouse(false)

		-- Widgets handed to an AuraButton must be CREATED as children of it:
		-- re-parenting an existing region onto the button is banned, since it
		-- can't inherit the button's forbidden aspects that way. So each button
		-- owns its own texture/cooldown/count rather than reusing the icon's.
		-- (SetIcon is applied in ApplyButtonSettings so it can respect a texture
		-- override.)
		local tex = button:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(button)
		button.tmwIcon = tex

		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cd:SetAllPoints(button)
		cd:SetReverse(true)
		cd:SetDrawBling(not TMW.db.profile.HideBlizzCDBling)
		cd:SetDrawEdge(TMW.db.profile.DrawEdge)
		cd:SetFrameLevel(button:GetFrameLevel() + 1)
		button.tmwCooldown = cd

		local countText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		button.tmwCountText = countText

		-- A StatusBar for the duration, used by the bar views (driven via
		-- SetDurationBar). Hidden by default; the icon view never shows it.
		local bar = CreateFrame("StatusBar", nil, button)
		bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		bar:SetAllPoints(button)
		bar:Hide()
		button.tmwStatusBar = bar

		self.container:AddAuraFrame(button)
		self.buttons[i] = button
	end
end

-- Skin a button's own regions with the icon's Masque group. Masque sizes the
-- skin against the button's explicit size, so give it one first (the same way the
-- view sizes its IconContainer before AddButton); without it Masque falls back to
-- the skin's native dimensions and the button comes out oversized. The Icon region
-- is a child of the button (created, not re-parented), so Masque only re-anchors /
-- texcoords it - none of which trips the button's forbidden aspects.
function Module:SkinButton(button)
	local icon = self.icon
	local lmbGroup = icon.lmbGroup
	if not lmbGroup then
		return
	end

	local w, h = icon:GetSize()
	if w and w > 0 then
		button:ClearAllPoints()
		button:SetSize(w, h)
		button:SetPoint("CENTER", icon)
	end

	lmbGroup:AddButton(button, {
		Icon = button.tmwIcon,
		Cooldown = button.tmwCooldown,
	}, "Legacy")
end

-- Copy `source`'s anchor points (and size) onto `region`, remapping each point's
-- relativeTo frame through `remap` (falling back to `default`). This reproduces a
-- frame the view already positioned, but anchored to the button (and its children)
-- so it stays valid on the forbidden button - no duplicated geometry math.
local function MirrorPoints(region, source, remap, default)
	local n = source:GetNumPoints()
	if n == 0 then
		return false
	end
	region:ClearAllPoints()
	region:SetSize(source:GetSize())
	for i = 1, n do
		local point, relTo, relPoint, x, y = source:GetPoint(i)
		region:SetPoint(point, remap[relTo] or default, relPoint, x, y)
	end
	return true
end

-- Lay a button out for the bar / barv views: the button spans the whole cell, the
-- aura texture/cooldown sit over the icon square, and the duration StatusBar fills
-- the bar region (driven via SetDurationBar). Rather than duplicate the views'
-- geometry we MIRROR the frames they already positioned - IconContainer's square
-- and TimerBar's container - remapping their relativeTo so the anchors stay valid
-- on the forbidden button: the icon -> our button, the icon square -> our mirrored
-- copy of it. `vertical` only selects the bar's orientation (barv).
function Module:LayoutButtonForBar(icon, button, vertical)
	local Modules = icon.Modules
	local iconContainer = Modules.IconModule_IconContainer_Masque
	local iconSquare = iconContainer and iconContainer.container
	local timerBar = Modules.IconModule_TimerBar_BarDisplay
	local barRef = timerBar and timerBar.container

	button:ClearAllPoints()
	button:SetAllPoints(icon)

	-- Frame levels: EnsureButtons put the button at icon+5, but IconModule_Texts
	-- sits at icon+3, so the bar would draw over the bar's text. TMW's own bar sits
	-- at the icon's frame level; keep the whole button (and its children) below the
	-- text. The button sits at the icon's base level so its children can occupy
	-- base..base+2 (the backdrop needs to be BELOW the bar, and a child can't go
	-- below its parent). Set children explicitly - lowering the parent doesn't
	-- cascade to children created earlier.
	local base = icon:GetFrameLevel()
	button:SetFrameLevel(base)

	local tex, cd, bar = button.tmwIcon, button.tmwCooldown, button.tmwStatusBar
	local lmbGroup = icon.lmbGroup
	local remap = { [icon] = button }

	cd:SetFrameLevel(base + 2)
	bar:SetFrameLevel(base + 1)

	-- Icon square.
	if icon.group:GetSettingsPerView().Icon and iconSquare then
		tex:Show()
		if lmbGroup then
			-- Masque-skin the icon square. The button spans the whole cell, so we
			-- can't AddButton the button itself (Masque would size the icon to the
			-- cell); instead a holder sized to the square is the Masque button, and
			-- Masque anchors + skins the icon/cooldown within it.
			local holder = button.tmwIconHolder
			if not holder then
				holder = CreateFrame("Button", nil, button)
				button.tmwIconHolder = holder
			end
			holder:Show()
			holder:SetFrameLevel(base + 1)
			MirrorPoints(holder, iconSquare, remap, button)
			lmbGroup:AddButton(holder, { Icon = tex, Cooldown = cd }, "Legacy")
			remap[iconSquare] = holder
		else
			MirrorPoints(tex, iconSquare, remap, button)
			MirrorPoints(cd, iconSquare, remap, button)
			remap[iconSquare] = tex
		end
	else
		tex:Hide()
		if button.tmwIconHolder then
			button.tmwIconHolder:Hide()
		end
		cd:ClearAllPoints()
		cd:SetAllPoints(button)
	end

	-- Duration bar: mirror the view's TimerBar container (anchored to the icon and
	-- the icon square, both remapped above).
	if barRef and MirrorPoints(bar, barRef, remap, button) then
		bar:Show()
		bar:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
		bar:SetRotatesTexture(vertical)
		bar:SetStatusBarTexture(GetBarTexture(icon))
		bar:SetStatusBarColor(GetBarColor(icon))
		-- Workaround blizzard having choppy animations on bars with high scale.
		-- Set the bar's effective scale to exactly align to to screen resolution.
		bar:SetScale(PixelUtil.GetPixelToUIUnitFactor() / icon:GetEffectiveScale())
		button:SetDurationBar(bar, {direction = Enum.StatusBarTimerDirection.RemainingTime})

		self:LayoutBarBackdrop(icon, button, bar, vertical)
	else
		bar:Hide()
		if button.tmwBarBackdrop then
			button.tmwBarBackdrop:Hide()
		end
	end
end

-- Recreate IconModule_Backdrop's bar backdrop + border as children of the button,
-- so they're parented to the AuraButton and hide with it when there's no aura.
-- IconModule_Backdrop is disallowed on aura-container types (buffcontainer).
function Module:LayoutBarBackdrop(icon, button, bar, vertical)
	local base = icon:GetFrameLevel()

	local frame = button.tmwBarBackdrop
	if not frame then
		frame = CreateFrame("Frame", nil, button)
		frame.tex = frame:CreateTexture(nil, "BACKGROUND")
		frame.tex:SetAllPoints(frame)
		button.tmwBarBackdrop = frame
	end
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
	local c = GetBackdropColor(icon)
	frame.tex:SetVertexColor(c.r, c.g, c.b, 1)
	frame.tex:SetAlpha(c.a)

	local gspv = icon.group:GetSettingsPerView()
	if gspv.BorderBar and gspv.BorderBar ~= 0 then
		local border = frame.border
		if not border then
			border = CreateFrame("Frame", nil, frame, "TellMeWhen_GenericBorder")
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

-- Configure each button's texture/cooldown/count display from the icon settings.
function Module:ApplyButtonSettings(icon)
	local showTimer = icon.ShowTimer
	local showText = icon.ShowTimerText

	-- If the icon has a texture override configured (Custom Texture), let
	-- IconModule_Texture_Colored show it on the icon and suppress the container's
	-- own aura icon so the override wins.
	local hasTextureOverride = icon.CustomTex and icon.CustomTex:trim() ~= ""

	for i = 1, #self.buttons do
		local button = self.buttons[i]

		if hasTextureOverride then
			button:ClearIcon()
			button.tmwIcon:Hide()
		else
			button.tmwIcon:Show()
			button:SetIcon(button.tmwIcon)
		end

		local cd = button.tmwCooldown

		if cd then
			if showTimer or showText then
				cd:SetDrawSwipe(showTimer)
				cd:SetHideCountdownNumbers(not showText)
				button:SetDurationCooldown(cd)
			else
				button:ClearDurationCooldown()
			end
		end

		button:SetApplicationCount(button.tmwCountText, {})
	end
end

-- Fully stand the container down: clear the display, then stop tracking.
-- Shared by Configure's no-spec path and OnDisable.
--
-- ClearAuraFilters FIRST so the SetEnabled(false) parse runs over an empty filter
-- set (trivial) instead of re-parsing every real filter on the way out. We never
-- Hide - visibility follows the icon (the container is a 1x1 child), and toggling
-- Hide would just cost another full parse via OnHide; SetEnabled(false) alone
-- unregisters UNIT_AURA (ShouldRegisterForEvents = IsVisible() and IsEnabled()).
function Module:StandDown()
	local container = self.container
	if container then
		container:ClearAuraFilters()
		container:SetEnabled(false)
	end
end

-- The single authority for the container's live state, driven entirely by the
-- spec: a valid spec brings it up (enabled + tracking); anything else (no spec
-- yet, config mode, misconfigured) stands it down.
function Module:Configure(icon)
	local spec = icon.attributes.auraSpec
	-- The container is a live-play display, so also stand it down in config mode
	-- (unlocked): BuildAuraSpec always returns a valid spec, so without this the
	-- container keeps tracking and showing real auras while you're editing.
	if not TMW.Locked or not spec or not spec.filters or #spec.filters == 0 then
		self:StandDown()
		return
	end

	if not self:EnsureContainer() then
		return
	end
	local container = self.container

	-- Create enough buttons to satisfy the largest per-filter frame count.
	local count = 1
	for i = 1, #spec.filters do
		count = max(count, spec.filters[i].maxFrameCount or 1)
	end
	self:EnsureButtons(count)
	self:ApplyButtonSettings(icon)

	-- Efficient ordering (each of Show/Hide/SetUnit/SetEnabled/AddAuraFilter that
	-- changes state triggers a full ParseAllAuras):
	--  * We never Show/Hide - the container inherits the icon's visibility, and
	--    `enabled` is our on/off. Registration is IsVisible() and IsEnabled().
	--  * ClearAuraFilters first, so the SetUnit/SetEnabled parses run over an empty
	--    filter set (trivial). SetUnit before SetEnabled so we register once for the
	--    right unit. On a target swap both are no-ops (guarded by ~=), so the only
	--    real work is the ClearAuraFilters + AddAuraFilter re-parse.
	--  * Add the real filters LAST; those are the only full-cost parses. The final
	--    AddAuraFilter is what populates the buttons.
	--
	-- SetUnit / ClearAuraFilters / AddAuraFilter are SECURE DELEGATES
	-- (ApplySecureDelegatesToTable), so their bodies run UNTAINTED and the
	-- ParseAllAuras they trigger can legally reach the container's private
	-- partition. We must NOT call container:UpdateAllAuras() directly: external
	-- resolution lands on the non-delegated private override and errors under taint.
	container:ClearAuraFilters()
	container:SetUnit(spec.unit or "player")
	container:SetEnabled(true)
	for i = 1, #spec.filters do
		local f = spec.filters[i]
		container:AddAuraFilter(f.filterString, { maxFrameCount = f.maxFrameCount or 1 })
	end
end

function Module:AURASPEC(icon, auraSpec)
	if self.IsEnabled then
		self:Configure(icon)
	end
end
Module:SetDataListener("AURASPEC")

-- Skin at SETUP_POST - the same hook IconContainer_Masque uses for its own
-- skinning. This is the first point where both things we need exist: the buttons
-- (created lazily from the spec in Type:Setup, after all modules implement) and
-- icon.lmbGroup. It also runs once per setup, so Masque skin changes re-apply
-- without us re-skinning on every target swap.
Module:SetIconEventListner("TMW_ICON_SETUP_POST", function(self, icon)
	if not self.IsEnabled then
		return
	end
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		-- Views that lay auras out themselves (bars) set self.LayoutButton in their
		-- implementor; the icon view leaves it nil and gets Masque skinning.
		if self.LayoutButton then
			self:LayoutButton(icon, button)
		else
			self:SkinButton(button)
		end
	end
end)

function Module:SetupForIcon(icon)
	self:Configure(icon)
end

function Module:OnEnable()
	-- Cleared each setup; the view's implementor re-sets it (bar views) or leaves
	-- it nil (icon view -> Masque skinning in SETUP_POST).
	self.LayoutButton = nil
	self:Configure(self.icon)
end

function Module:OnDisable()
	self:StandDown()
end
