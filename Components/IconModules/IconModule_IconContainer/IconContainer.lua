﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

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

local IconContainer = TMW:NewClass("IconModule_IconContainer", "IconModule")

IconContainer:RegisterAnchorableFrame("IconContainer")

function IconContainer:OnNewInstance_IconContainer(icon)	
	local container = CreateFrame("Button", self:GetChildNameBase() .. "IconContainer", icon)
	
	container:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	container:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

	self.container = container
	container.module = self
	
	container:EnableMouse(false)
end

function IconContainer:OnEnable()
	local icon = self.icon
	local container = self.container
	
	if not container:IsShown() then
		container:Show()
	end
	
	container:SetFrameLevel(icon:GetFrameLevel())
end

function IconContainer:OnDisable()
	self:SetBorder(0, "ffffffff")
end

function IconContainer:OnDisableDelayed()
	self.container:Hide()
end

function IconContainer:SetBorder(size, color, inset)
	if not self.border and size ~= 0 then
		self.border = CreateFrame("Frame", nil, self.container, "TellMeWhen_GenericBorder")
	end

	if inset then size = -size end

	if self.border then
		self.border:SetBorderSize(size)
		self.border:SetColor(TMW:StringToRGBA(color))
	end
end





-- SpellActivationAlert animation handling:
local unusedOverlayGlows = {}
local numOverlays = 0
if CreateFrame("Frame", nil, UIParent, "ActionBarButtonSpellActivationAlert").ProcStartAnim then
	-- Wow 10.1.5+
	function IconContainer:ShowOverlayGlow()
		local container = self.container

		if not self.overlay then
			self.overlay = CreateFrame("Frame", nil, container, "ActionBarButtonSpellActivationAlert")

			-- The intro animation to the new activation alert animation in wow 10.1.5 is extremely weird,
			-- so we're electing to not use it and only use the loop animation (ProcLoop).
			self.overlay.ProcStartFlipbook:Hide()

			-- Remove the default OnHide script that stops the animation when the overlay hides, 
			-- as otherwise the animation will stop if the parent group hides, e.g. when leaving and entering combat rapidly.
			self.overlay:SetScript("OnHide", nil)

			-- Since we're disregarding the intro, add an alpha fade-in:
			self.fadeIn = self.overlay:CreateAnimationGroup()
			local alphaFade = self.fadeIn:CreateAnimation("Alpha")
			alphaFade:SetDuration(0.2)
			alphaFade:SetFromAlpha(0)
			alphaFade:SetToAlpha(1)

			local frameWidth, frameHeight = container:GetSize()
			self.overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
			self.overlay:SetPoint("CENTER", container, "CENTER", 0, 0)
			self.overlay:Hide()
			
		end
		if not self.overlay:IsShown() then
			self.overlay:Show()
			self.overlay.ProcLoop:Play()
			self.fadeIn:Play()
		end
	end

	function IconContainer:HideOverlayGlow()
		if self.overlay then
			self.overlay.ProcStartAnim:Stop()
			self.overlay.ProcLoop:Stop()
		end
		self.overlay:Hide()
	end
else

	-- Legacy:
	local function OverlayGlowAnimOutFinished(animGroup)
		local overlay = animGroup:GetParent();
		local container = overlay:GetParent();
		overlay:Hide();
		tinsert(unusedOverlayGlows, overlay);
		container.module.overlay = nil;
	end
	local function OverlayOnHide(overlay)
		if ( overlay.animOut:IsPlaying() ) then
			overlay.animOut:Stop();
			OverlayGlowAnimOutFinished(overlay.animOut);
		end
	end

	function IconContainer:GetOverlayGlow()
		local overlay = tremove(unusedOverlayGlows);
		if ( not overlay ) then
			numOverlays = numOverlays + 1;
			overlay = CreateFrame("Frame", "TMW_ActionButtonOverlay" .. numOverlays, UIParent, "ActionBarButtonSpellActivationAlert");


			-- Override scripts from the blizzard template:
			-- We do this so we don't have to duplicate the template as well.
			overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished)
			overlay:SetScript("OnHide", OverlayOnHide)
		end
		return overlay;
	end

	function IconContainer:ShowOverlayGlow()
		local container = self.container
		local overlay = self.overlay

		if ( self.overlay ) then
			if ( self.overlay.animOut:IsPlaying() ) then
				self.overlay.animOut:Stop();
				self.overlay.animIn:Play();
			end
		else
			overlay = self:GetOverlayGlow();
			self.overlay = overlay
			local frameWidth, frameHeight = container:GetSize();
			self.overlay:SetParent(container);
			self.overlay:ClearAllPoints();
			--Make the height/width available before the next frame:
			self.overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4);
			self.overlay:SetPoint("TOPLEFT", container, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2);
			self.overlay:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2);
			self.overlay.animIn:Play();
		end
	end

	function IconContainer:HideOverlayGlow()
		local container = self.container

		if ( self.overlay ) then
			if ( self.overlay.animIn:IsPlaying() ) then
				self.overlay.animIn:Stop();
			end
			if ( container:IsVisible() ) then
				self.overlay.animOut:Play();
			else
				OverlayGlowAnimOutFinished(self.overlay.animOut);	--We aren't shown anyway, so we'll instantly hide it.
			end
		end
	end
end


IconContainer:RegisterEventHandlerData("Animations", 60, "ACTVTNGLOW", {
	text = L["ANIM_ACTVTNGLOW"],
	desc = L["ANIM_ACTVTNGLOW_DESC"],
	ConfigFrames = {
		"Duration",
		"Infinite",
		"Scale"
	},

	Play = function(icon, eventSettings)
		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Scale = eventSettings.Scale,
			Duration = eventSettings.Infinite and math.huge or eventSettings.Duration,
		}
	end,

	OnUpdate = function(icon, table)
		if table.Duration - (TMW.time - table.Start) < 0 then
			icon:Animations_Stop(table)
		end
	end,
	OnStart = function(icon, table)
		local IconModule_IconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer")
		local container = IconModule_IconContainer.container
		
		IconModule_IconContainer:ShowOverlayGlow()
		
		-- overlay is a field created by IconModule_IconContainer:ShowOverlayGlow()
		IconModule_IconContainer.overlay:SetScale(table.Scale)
		IconModule_IconContainer.overlay:SetFrameLevel(icon:GetFrameLevel() + 3)
	end,
	OnStop = function(icon, table)
		local IconModule_IconContainer = icon:GetModuleOrModuleChild("IconModule_IconContainer", true, true)
		
		IconModule_IconContainer:HideOverlayGlow()
	end,
})






IconContainer:SetScriptHandler("OnEnter", function(Module, icon)
	Module.container:LockHighlight()
end)
IconContainer:SetScriptHandler("OnLeave", function(Module, icon)
	Module.container:UnlockHighlight()
	Module.container:SetButtonState("NORMAL")
end)
IconContainer:SetScriptHandler("OnMouseDown", function(Module, icon)
	Module.container:SetButtonState("PUSHED")
end)
IconContainer:SetScriptHandler("OnMouseUp", function(Module, icon)
	Module.container:SetButtonState("NORMAL")
end)



