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
		pcall(LoadAddOn, "Blizzard_AuraContainer")
	end
	blizzAddonAvailable = AuraContainerInbound ~= nil
	return blizzAddonAvailable
end


-- ----------------------------------------------------------------------------
-- AURASPEC IconDataProcessor: carries the static aura-display spec table.
-- The value is a plain table rebuilt by the icon type each Setup, so identity
-- comparison is sufficient to detect changes.
-- ----------------------------------------------------------------------------
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

Module:RegisterIconDefaults{
	-- When true, the icon renders auras via Blizzard's AuraContainer/AuraButton
	-- objects (see file header). Only meaningful on aura icon types; harmless
	-- (always false / ignored) elsewhere.
	UseAuraContainer = false,
}


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
	local ok, container = pcall(
		CreateFrame, "AuraContainer", self:GetChildNameBase() .. "Container", icon, CONTAINER_TEMPLATE
	)
	if not ok or not container then
		return false
	end

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
		pcall(button.EnableMouse, button, false)

		-- All widgets handed to an AuraButton must be parented to and anchored
		-- to that button so they inherit its forbidden Parent/Layout aspects.
		-- Creating them as children of the button satisfies this by construction.
		local tex = button:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(button)
		button.tmwIcon = tex
		button:SetIcon(tex)

		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cd:SetAllPoints(button)
		button.tmwCooldown = cd

		local durText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		durText:SetPoint("CENTER", button, "CENTER")
		button.tmwDurationText = durText

		local countText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		button.tmwCountText = countText

		self.container:AddAuraFrame(button)
		self.buttons[i] = button
	end
end

-- Wire up (or tear down) each button's duration display according to the icon's
-- timer settings. The application-count text is always wired since the button
-- itself hides it when there are no stacks.
function Module:ApplyButtonSettings(icon)
	for i = 1, #self.buttons do
		local button = self.buttons[i]

		if icon.ShowTimer then
			button.tmwCooldown:SetDrawSwipe(true)
			button:SetDurationCooldown(button.tmwCooldown)
		else
			button:ClearDurationCooldown()
		end

		if icon.ShowTimerText then
			button:SetDurationText(button.tmwDurationText, {})
		else
			button:ClearDurationText()
			button.tmwDurationText:SetText("")
		end

		button:SetApplicationCount(button.tmwCountText, {})
	end
end

function Module:Configure(icon)
	local spec = icon.attributes.auraSpec
	if not spec or not spec.filters or #spec.filters == 0 then
		if self.container then
			self.container:ClearAuraFilters()
		end
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

	-- SetUnit / ClearAuraFilters / AddAuraFilter are SECURE DELEGATES
	-- (ApplySecureDelegatesToTable), so their bodies run UNTAINTED and the
	-- ParseAllAuras they trigger can legally reach the container's private
	-- partition. That's what populates the buttons - and re-running this on a
	-- unit-set change (target swap) re-parses for the new unit. We must NOT call
	-- container:UpdateAllAuras() directly: external resolution lands on the
	-- non-delegated private override and errors under taint.
	container:SetUnit(spec.unit or "player")
	container:ClearAuraFilters()
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

function Module:SetupForIcon(icon)
	self:Configure(icon)
end

function Module:OnEnable()
	if self:EnsureContainer() then
		self.container:Show()
		self:Configure(self.icon)
	end
end

function Module:OnDisable()
	if self.container then
		self.container:SetEnabled(false)
		self.container:ClearAuraFilters()
		self.container:Hide()
	end
end


-- ----------------------------------------------------------------------------
-- Diagnostics: dumps an AuraContainer icon's state. Address the icon by
-- group/index so we don't open the editor (which re-runs Setup and masks the
-- bug):  /tmwac global 1 3   or   /tmwac global[1][3]
-- With no args, falls back to the icon open in the editor.
-- ----------------------------------------------------------------------------
local function safecall(f, ...)
	if type(f) ~= "function" then return "<no method>" end
	local ok, r = pcall(f, ...)
	if ok then return tostring(r) end
	return "err:" .. tostring(r)
end

SLASH_TMWAC1 = "/tmwac"
SlashCmdList.TMWAC = function(msg)
	local icon
	local domain, groupNum, iconNum = (msg or ""):lower():match("(%a+)%D+(%d+)%D+(%d+)")
	if domain and groupNum and iconNum then
		local prefix = domain == "global" and "TellMeWhen_GlobalGroup" or "TellMeWhen_Group"
		local name = prefix .. groupNum .. "_Icon" .. iconNum
		icon = _G[name]
		if not icon then
			print("TMWAC: no frame named " .. name)
			return
		end
	else
		icon = TMW.CI and TMW.CI.icon
	end
	if not icon then
		print("TMWAC: no icon (use '/tmwac global 1 3', or open one in the editor).")
		return
	end

	local m = icon.Modules and icon.Modules.IconModule_AuraContainer
	print("TMWAC: icon =", tostring(icon), "UseAuraContainer =", tostring(icon.UseAuraContainer))
	if not m then
		print("  no IconModule_AuraContainer on this icon.")
		return
	end
	print("  module IsEnabled =", tostring(m.IsEnabled), " #buttons =", m.buttons and #m.buttons or 0)

	local c = m.container
	if not c then
		print("  container not created (Blizzard_AuraContainer unavailable?).")
		return
	end

	print("  container IsShown =", safecall(c.IsShown, c), " IsVisible =", safecall(c.IsVisible, c))
	print("  container IsEnabled =", safecall(c.IsEnabled, c), " GetUnit =", safecall(c.GetUnit, c))
	print("  container IsEventRegistered(UNIT_AURA) =", safecall(c.IsEventRegistered, c, "UNIT_AURA"))

	local spec = icon.attributes.auraSpec
	if not spec then
		print("  no auraSpec attribute set.")
		return
	end
	for i = 1, #spec.filters do
		local fs = spec.filters[i].filterString
		local n = "?"
		local ok, auras = pcall(C_UnitAuras.GetUnitAuras, spec.unit, fs)
		if ok and type(auras) == "table" then
			n = #auras
		elseif ok then
			n = "secret/non-table"
		end
		print(("  filter[%d] %q unit=%s -> GetUnitAuras count = %s"):format(i, fs, tostring(spec.unit), tostring(n)))
	end
end
