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

-- GLOBALS: GameTooltip_SetDefaultAnchor
local GameTooltip = GameTooltip
local UnitAffectingCombat = UnitAffectingCombat


-- Mouseover tooltips for the spell or item an icon is currently showing (#2439). Locked
-- mode only - config mode has its own tooltip, from IconModule_Tooltip, which is only
-- loaded alongside the options. Aura container icons are excluded (the AuraButtons carry
-- Blizzard's aura tooltips); IconModule_AuraContainer applies the same settings to those.
--
-- Icons are mouse-dead while locked (Icon:Setup), so nothing here runs until the user opts
-- in. The icon then takes mouse MOTION only: clicks stay with
-- IconModule_IconEventClickHandler, which owns that axis independently.
local Module = TMW:NewClass("IconModule_IconTooltip", "IconModule")

Module.dontInherit = true

-- Untyped icons have nothing to describe.
Module:SetAllowanceForType("", false)


TMW:RegisterDatabaseDefaults{
	global = {
		-- Show a tooltip for whatever an icon is tracking while the mouse is over it.
		-- Makes icons take mouse motion while TMW is locked, which they otherwise never do.
		ShowTooltips = false,

		-- Suppress those tooltips while in combat.
		TooltipsHideInCombat = false,
	},
}

-- Column 2 of the Main tab, which supplies TMW.db.global as the setting table and fires
-- a TMW:Update on save (see the PanelsRight/DescendantSettingSaved handlers in MainConfig.xml).
Module:RegisterConfigPanel_ConstructorFunc(3, "TellMeWhen_Main_Tooltips", function(self)
	self:SetTitle(L["DOMAIN_GLOBAL_NC"] .. ": " .. L["UIPANEL_ICONTOOLTIPS"])

	self:BuildSimpleCheckSettingFrame({
		numPerRow = 1,
		function(check)
			check:SetTexts(L["UIPANEL_SHOWICONTOOLTIPS"], L["UIPANEL_SHOWICONTOOLTIPS_DESC"])
			check:SetSetting("ShowTooltips")
		end,
		function(check)
			check:SetTexts(L["UIPANEL_ICONTOOLTIPS_HIDEINCOMBAT"], L["UIPANEL_ICONTOOLTIPS_HIDEINCOMBAT_DESC"])
			check:SetSetting("TooltipsHideInCombat")

			check:CScriptAdd("ReloadRequested", function()
				check:SetEnabled(TMW.db.global.ShowTooltips)
			end)
		end,
	})
end):SetPanelSet("global")


-- Does this icon draw its visibility from a secret, with one of the two branches hidden?
-- If so we can't tell whether it's actually drawn right now - realAlpha is forced to 1 for
-- secret states - and SetMouseMotionEnabled takes no secrets. A tooltip on an icon that
-- isn't drawn would give away the state the secret exists to hide.
local function IsMaybeSecretlyHidden(icon)
	local state = icon.attributes.calculatedState
	if not state or state.secretBool == nil then
		return false
	end

	local trueState, falseState = state.trueState, state.falseState
	return (trueState and trueState.Alpha == 0) or (falseState and falseState.Alpha == 0)
end

function Module:ShouldTakeMouse()
	local icon = self.icon

	if icon.FakeHidden or icon.attributes.realAlpha == 0 or IsMaybeSecretlyHidden(icon) then
		return false
	end

	-- For a controlled icon this is the group controller's type, which is also what
	-- supplied the attributes we're about to describe.
	return icon.typeData:HasTooltip(icon)
end

function Module:Update()
	local icon = self.icon

	-- Icon:Setup() disables the mouse near the end of setup, so wait for it to finish and
	-- pick this up from the TMW_ICON_SETUP_POST listener below.
	if icon.IsSettingUp then
		return
	end

	local takeMouse = self:ShouldTakeMouse()
	icon:SetMouseMotionEnabled(takeMouse)

	if not takeMouse then
		-- OnLeave doesn't fire when an icon stops taking the mouse under the cursor.
		self:HideTooltip()
	end
end

function Module:HideTooltip()
	if GameTooltip:IsOwned(self.icon) then
		GameTooltip:Hide()
	end
end

function Module:OnEnable()
	self:Update()
end

function Module:OnDisable()
	self.icon:SetMouseMotionEnabled(false)
	self:HideTooltip()
end

Module:SetIconEventListner("TMW_ICON_SETUP_POST", function(Module, icon)
	Module:Update()
end)

function Module:REALALPHA(icon, realAlpha)
	self:Update()
end
Module:SetDataListener("REALALPHA")

-- realAlpha doesn't change when an icon switches between a plain state and a secret one
-- (secret states report a realAlpha of 1), so watch the state itself too.
function Module:CALCULATEDSTATE(icon, state)
	self:Update()
end
Module:SetDataListener("CALCULATEDSTATE")

-- An icon that has nothing to describe doesn't take the mouse at all, so it has to start
-- and stop doing so as the thing it's tracking comes and goes.
function Module:SPELL(icon, spell)
	self:Update()
end
Module:SetDataListener("SPELL")


Module:SetScriptHandler("OnEnter", function(Module, icon)
	if not TMW.Locked then
		return
	end

	if TMW.db.global.TooltipsHideInCombat and UnitAffectingCombat("player") then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, icon)

	if not icon.typeData:SetTooltip(icon, GameTooltip) then
		GameTooltip:Hide()
	end
end)

Module:SetScriptHandler("OnLeave", function(Module, icon)
	Module:HideTooltip()
end)
