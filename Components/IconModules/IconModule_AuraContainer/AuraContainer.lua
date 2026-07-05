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
--             { filterString = "HARMFUL|INCLUDE_NAME_PLATE_ONLY" },
--             ...
--         },
--     }
--
-- The number of aura buttons (and therefore how many auras show) is owned by this
-- module, not the spec: a normal icon shows one, and a group controller fills its
-- whole group with one button per icon. See GetWantedButtonCount.
-- ----------------------------------------------------------------------------


-- The AuraContainer/AuraButton frame types and the Custom*Template templates
-- live in Blizzard's Blizzard_AuraContainer addon, which may be load-on-demand.
local CONTAINER_TEMPLATE = "CustomAuraContainerTemplate"
local BUTTON_TEMPLATE = "CustomAuraButtonTemplate"

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

-- How many aura buttons this module should own. A group-controller buffcontainer
-- fills the whole group - one button per icon - so it can show that many auras at
-- once (Blizzard's container distributes matching auras across the button pool).
-- Every other icon shows a single aura.
function Module:GetWantedButtonCount()
	local icon = self.icon
	if icon:IsGroupController() then
		return icon.group.numIcons
	end
	return 1
end

function Module:EnsureButtons(count)
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
		-- owns its own texture/cooldown rather than reusing the icon's. (SetIcon is
		-- applied in ApplyButtonSettings so it can respect a texture override.) Text
		-- (spell/duration/stacks) is created on demand in WireAuraText from the
		-- layout strings flagged with an Aura purpose.
		local tex = button:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(button)
		button.tmwIcon = tex

		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cd:SetAllPoints(button)
		cd:SetReverse(true)
		cd:SetFrameLevel(button:GetFrameLevel() + 1)
		button.tmwCooldown = cd

		-- A StatusBar for the duration, used by the bar views (driven via
		-- SetDurationBar). Hidden by default; the icon view never shows it.
		local bar = CreateFrame("StatusBar", nil, button)
		bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		bar:SetAllPoints(button)
		bar:Hide()
		button.tmwStatusBar = bar

		self.container:AddAuraFrame(button)
		self.buttons[i] = button

		-- A freshly created button hasn't been laid out/skinned yet.
		self.needsLayout = true
	end
end

-- Skin a button's own regions with the icon's Masque group. Masque sizes the
-- skin against the button's explicit size, so give it one first (the same way the
-- view sizes its IconContainer before AddButton); without it Masque falls back to
-- the skin's native dimensions and the button comes out oversized. The Icon region
-- is a child of the button (created, not re-parented), so Masque only re-anchors /
-- texcoords it - none of which trips the button's forbidden aspects.
-- `icon` is the icon whose cell this button sits over (self.icon normally; a
-- group controller passes each controlled icon in turn).
function Module:SkinButton(button, icon)
	icon = icon or self.icon
	local lmbGroup = icon.lmbGroup

	-- The button covers the icon, so text strings that anchor to the icon remap to
	-- the button. Returned for WireAuraText.
	local remap = { [icon] = button }

	if lmbGroup then
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

	-- The button is the icon square in this view, so border it directly.
	self:LayoutIconBorder(icon, button, button)

	return remap
end

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

-- Lay out + skin + text-wire every button. `force` re-does them all (the setup path,
-- for when the view/Masque skin/size may have changed); otherwise it only runs when
-- EnsureButtons created new buttons or we were (re)enabled (needsLayout), so meta icons
-- swapping between same-shaped sources don't re-skin needlessly. No-op until enabled.
function Module:LayoutButtons(force)
	-- Controlled icons render through the controller's buttons, not their own, so
	-- they never own a container (see OnEnable). Nothing to lay out.
	if not self.IsEnabled or not self.container or self.icon:IsControlled() then
		return
	end

	self:EnsureButtons(self:GetWantedButtonCount())

	-- A group controller places one button over each icon in the group, so it can
	-- only be laid out once every icon in the group has been set up. The controller
	-- (icon 1) is set up first, so its own setup is too early: the group-setup-post
	-- path (which passes force) drives it. Ignore earlier, non-forced calls.
	if self.icon:IsGroupController() and not force then
		return
	end

	if not (force or self.needsLayout) then
		return
	end
	self.needsLayout = nil

	local isController = self.icon:IsGroupController()
	local group = self.icon.group
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		-- For a group controller, button i sits over group icon i; otherwise the
		-- single button sits over our own icon.
		local icon = isController and group[i] or self.icon
		if icon then
			-- Views that lay auras out themselves (bars) set self.LayoutButton in their
			-- implementor; the icon view leaves it nil and gets Masque skinning. Both
			-- return a frame remap (icon/square/bar -> our button-owned equivalents) so
			-- WireAuraText can position the aura-driven text the same way.
			local remap
			if self.LayoutButton then
				remap = self:LayoutButton(icon, button)
			else
				remap = self:SkinButton(button, icon)
			end
			self:LayoutAuraText(icon, button, remap or { [icon] = button })
		end
		-- Surplus buttons (the group shrank) get no target; Blizzard's container
		-- clears/hides any frame beyond maxFrameCount, so leave them be.
	end
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

	-- Icon square. `iconRegion` is whatever ends up playing it (the Masque holder or
	-- the bare texture), used to anchor the recreated icon border below.
	local iconRegion
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
			iconRegion = holder
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
		cd:ClearAllPoints()
		cd:SetAllPoints(button)
	end

	self:LayoutIconBorder(icon, button, iconRegion)

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
		-- both it and the container to our StatusBar so WireAuraText places text.
		remap[barRef] = bar
		if timerBar.bar then
			remap[timerBar.bar] = bar
		end

		self:LayoutBarBackdrop(icon, button, bar, vertical)
	else
		bar:Hide()
		if button.tmwBarBackdrop then
			button.tmwBarBackdrop:Hide()
		end
	end

	return remap
end

-- Recreate IconModule_Backdrop's bar backdrop + border as children of the button,
-- so they're parented to the AuraButton and hide with it when there's no aura.
-- IconModule_Backdrop is disallowed on aura-container types (buffcontainer).
--
-- Exception: in config mode (unlocked) the button is hidden (no aura is assigned),
-- so parent the backdrop to the ICON instead, so it stays visible as a preview
-- while editing. In locked mode it's a button child and hides with the aura.
function Module:LayoutBarBackdrop(icon, button, bar, vertical)
	local base = icon:GetFrameLevel()

	local frame = button.tmwBarBackdrop
	if not frame then
		frame = CreateFrame("Frame", nil, button)
		frame.tex = frame:CreateTexture(nil, "BACKGROUND")
		frame.tex:SetAllPoints(frame)
		button.tmwBarBackdrop = frame
	end
	frame:SetParent(TMW.Locked and button or icon)
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

-- Recreate IconContainer's icon-square border (BorderIcon) around the recreated icon
-- square. IconContainer_Masque is disallowed on aura-container types, so its own border
-- would never show. Parented to the button so it hides with the aura when locked;
-- re-parented to the icon in config mode (where the button is hidden) so it stays a
-- visible preview, matching LayoutBarBackdrop. `iconRegion` is whatever plays the icon
-- square in this view (the Masque holder or the bare texture); pass nil to hide it.
function Module:LayoutIconBorder(icon, button, iconRegion)
	local border = button.tmwIconBorder
	local gspv = icon.group:GetSettingsPerView()

	if iconRegion and gspv.BorderIcon and gspv.BorderIcon ~= 0 then
		if not border then
			border = TMW.Classes.GenericBorder:New("Frame", nil, button, "TellMeWhen_GenericBorder")
			button.tmwIconBorder = border
		end
		border:SetParent(TMW.Locked and button or icon)
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

-- Drive layout strings flagged with an Aura purpose (see TEXT.AuraContainerTexts)
-- with the AuraButton's real value. IconModule_Texts creates + positions its own
-- (now DogTag-less) fontstring per such string; we create a button-owned fontstring,
-- copy that string's font/justify, mirror its position onto the button, and hand it
-- to the matching AuraButton API.
function Module:LayoutAuraText(icon, button, remap)
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

				-- Look from the layout settings; position mirrored from the (now
				-- DogTag-less) Texts fontstring the layout already placed.
				auraFs:SetFont(LSM:Fetch("font", stringSettings.Name), stringSettings.Size, stringSettings.Outline)
				auraFs:SetJustifyH(stringSettings.Justify)
				auraFs:SetJustifyV(stringSettings.JustifyV)
				auraFs:SetShadowOffset(stringSettings.Shadow, -stringSettings.Shadow)
				auraFs:SetRotation(math.rad(stringSettings.Rotate or 0))

				if realFs then
					MirrorPoints(auraFs, realFs, remap, button)
					-- MirrorPoints copies the source's current size; restore the
					-- layout's intent (0 = auto-size to the text).
					auraFs:SetWidth(stringSettings.Width)
					auraFs:SetHeight(stringSettings.Height)
					-- Later strings can anchor to this one ($$N); redirect to our copy.
					remap[realFs] = auraFs
				else
					-- No source to mirror; still needs to be anchored to the button or
					-- the SetSpellName/etc. forbidden-object validation fails.
					auraFs:ClearAllPoints()
					auraFs:SetPoint("CENTER", button)
				end

				if aura == "spell" then
					button:SetSpellName(auraFs)
				elseif aura == "duration" then
					button:SetDurationText(auraFs, {})
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
				cd:SetDrawBling(not TMW.db.profile.HideBlizzCDBling)
				cd:SetDrawEdge(TMW.db.profile.DrawEdge)
				button:SetDurationCooldown(cd)
			else
				button:ClearDurationCooldown()
			end
		end
	end
end

function Module:SetAuraSpec(auraSpec)
	local container = self.container

	-- Controlled icons don't own a container; the controller drives the shared one.
	if not container or self.icon:IsControlled() then
		return
	end

	if not TMW.Locked or not auraSpec or not auraSpec.filters or #auraSpec.filters == 0 then
		container:ClearAuraFilters()
		container:SetEnabled(false)
		return
	end

	-- maxFrameCount caps the GLOBAL running count of assigned auras across all
	-- filters (see CustomAuraContainer.RefreshAuraFrames), so giving every filter the
	-- full button count lets a single filter fill the group while the pool caps the
	-- total. Any button beyond it (e.g. after the group shrank) is auto-cleared.
	local maxFrameCount = self:GetWantedButtonCount()

	container:ClearAuraFilters()
	container:SetUnit(auraSpec.unit or "player")
	container:SetEnabled(true)
	for i = 1, #auraSpec.filters do
		local f = auraSpec.filters[i]
		container:AddAuraFilter(f.filterString, { maxFrameCount = maxFrameCount })
	end
end

function Module:AURASPEC(icon, auraSpec)
	self:SetAuraSpec(auraSpec)
end
Module:SetDataListener("AURASPEC")

-- The normal setup path: Type:Setup has published the spec and OnEnable created the
-- container by now, and icon.lmbGroup exists. Apply settings and (force-)lay out once per
-- setup so Masque/view/size changes re-apply. Meta icons never reach here - they set us
-- up via SetupForIcon without a full icon setup, so SETUP_POST never fires for them.
--
-- Group controllers are the exception: their buttons sit over the OTHER icons in the
-- group, which aren't set up yet when the controller's own setup fires (icon 1 is
-- first). They lay out at TMW_GROUP_SETUP_POST instead (below), once the whole group
-- is set up.
Module:SetIconEventListner("TMW_ICON_SETUP_POST", function(self, icon)
	if not self.IsEnabled or icon:IsGroupController() then
		return
	end
	self:ApplyButtonSettings(icon)
	self:LayoutButtons(true)
end)

-- Lay out a group controller's buttons once every icon in the group has been set up.
-- Each button sits over a different icon (see LayoutButtons), so we can't do this from
-- the controller's own TMW_ICON_SETUP_POST - it fires before the rest of the group is
-- ready. Button positions are live anchors to the group icons, so this is order-safe
-- with respect to the icon-positioning group modules (which also run here).
TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(event, group)
	local controller = group.Controller
	if not controller then
		return
	end
	local module = controller.Modules and controller.Modules.IconModule_AuraContainer
	if module and module.IsEnabled then
		module:ApplyButtonSettings(controller)
		module:LayoutButtons(true)
	end
end)

function Module:SetupForIcon(icon)
	self:ApplyButtonSettings(icon)
	self:LayoutButtons()
	self:SetAuraSpec(icon.attributes.auraSpec)
end

function Module:OnEnable()
	self.needsLayout = true

	local icon = self.icon

	-- A controlled icon in a group-controller buffcontainer doesn't own a container;
	-- the controller places one of its buttons over this icon's cell. Stay enabled
	-- (so IconModule_Texts still suppresses this icon's DogTag-driven aura strings -
	-- the controller's button draws the real values) but keep any leftover container
	-- from a prior standalone setup inert.
	if icon:IsControlled() then
		if self.container then
			self.container:ClearAuraFilters()
			self.container:SetEnabled(false)
		end
		return
	end

	local container = self.container
	if not container then
		container = CreateFrame("AuraContainer", self:GetChildNameBase() .. "Container", icon, CONTAINER_TEMPLATE)
		container:SetSize(1, 1)
		container:SetAllPoints(icon)
		self.container = container
	end

	self:EnsureButtons(1)
end

function Module:OnDisable()
	local container = self.container
	if container then
		container:ClearAuraFilters()
		container:SetEnabled(false)
	end
end
