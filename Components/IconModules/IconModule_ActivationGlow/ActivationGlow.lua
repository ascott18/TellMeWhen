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

local pairs = pairs

local SpellActivationOverlay = TMW.COMMON.SpellActivationOverlay


local ActivationGlow = TMW:NewClass("IconModule_ActivationGlow", "IconModule")

-- Only meaningful for icons that track a spell the player can cast, so icon types
-- opt in with Type:SetModuleAllowance("IconModule_ActivationGlow", true).
ActivationGlow:SetDefaultAllowanceForTypes(false)

ActivationGlow:RegisterIconDefaults{
	ShowActvtnBorder = false,
}

ActivationGlow:RegisterConfigPanel_ConstructorFunc(205, "TellMeWhen_ActivationGlowSettings", function(self)
	self:SetTitle(L["CONFIGPANEL_ACTVTNBORDER_HEADER"])

	self:BuildSimpleCheckSettingFrame({
		numPerRow = 1,
		function(check)
			check:SetTexts(L["ICONMENU_SHOWACTVTNBORDER"], L["ICONMENU_SHOWACTVTNBORDER_DESC"])
			check:SetSetting("ShowActvtnBorder")
		end,
	})

	self:SetAutoAdjustHeight(true)
end)


local EnabledModules = {}

function ActivationGlow:OnEnable()
	EnabledModules[self] = true
end

function ActivationGlow:OnDisable()
	EnabledModules[self] = nil
	self.Spells = nil

	self:SetGlowShown(false)
end

-- Modules are implemented into an icon before IconType:Setup() runs, so icon.Spells
-- isn't trustworthy until setup has finished.
ActivationGlow:SetIconEventListner("TMW_ICON_SETUP_POST", function(Module, icon)
	Module.Spells = icon.Spells

	Module:Update()
end)

function ActivationGlow:Update()
	self:SetGlowShown(self.Spells and SpellActivationOverlay.IsAnyOverlayed(self.Spells))
end

function ActivationGlow:SetGlowShown(shown)
	shown = not not shown
	if shown == self.glowShown then
		return
	end
	self.glowShown = shown

	local icon = self.icon

	if shown then
		local IconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer")
		if not IconContainer then
			-- Bar views only have a container when the group is configured to show icons.
			self.glowShown = false
			return
		end

		IconContainer:ShowOverlayGlow(self)

		-- overlay is a field created by IconContainer:ShowOverlayGlow()
		IconContainer.container.overlay:SetFrameLevel(icon:GetFrameLevel() + 3)
	else
		local IconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer", true, true)
		if IconContainer then
			IconContainer:HideOverlayGlow(self)
		end
	end
end

TMW:RegisterCallback("TMW_SPELL_UPDATE_OVERLAY", function()
	for Module in pairs(EnabledModules) do
		Module:Update()
	end
end)
