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

local OnGCD = TMW.OnGCD

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local pairs, wipe = 
      pairs, wipe

local CooldownSweep = TMW:NewClass("IconModule_CooldownSweep", "IconModule")

CooldownSweep:RegisterIconDefaults{
	ShowTimer = false,
	ShowTimerText = false,
	ShowTimerTextnoOCC = false,
	InvertTimer = false,
	ClockGCD = false,
}

TMW:RegisterDatabaseDefaults{
	profile = {
		ForceNoBlizzCC = false,
		HideBlizzCDBling = true,
		DrawEdge = false,
	},
}

CooldownSweep:RegisterConfigPanel_ConstructorFunc(200, "TellMeWhen_TimerSettings", function(self)
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
		function(check)
			check:SetTexts(L["ICONMENU_INVERTTIMER"], L["ICONMENU_INVERTTIMER_DESC"])
			check:SetSetting("InvertTimer")

			check:CScriptAdd("ReloadRequested", function()
				check:SetEnabled(TMW.CI.ics.ShowTimer)
			end)
		end,
		function(check)
			check:SetTexts(L["ICONMENU_ALLOWGCD"], L["ICONMENU_ALLOWGCD_DESC"])
			check:SetSetting("ClockGCD")

			check:CScriptAdd("ReloadRequested", function()
				check:SetShown(not TMW.CI.icon.typeData.hasNoGCD)

				check:SetEnabled(TMW.CI.ics.ShowTimer or TMW.CI.ics.ShowTimerText or TMW.CI.ics.ShowTimerTextnoOCC)
			end)
		end,
		function(check)
			check:SetTexts(L["ICONMENU_SHOWTIMERTEXT_NOOCC"], L["ICONMENU_SHOWTIMERTEXT_NOOCC_DESC"])
			check:SetSetting("ShowTimerTextnoOCC")

			check:CScriptAdd("ReloadRequested", function()				
				check:SetShown(IsAddOnLoaded("ElvUI"))

				check:SetEnabled(TMW.CI.ics.ShowTimer)
			end)
		end,
	})

	self:SetAutoAdjustHeight(true)
end)

CooldownSweep:RegisterConfigPanel_ConstructorFunc(8, "TellMeWhen_TimerSettings_Main", function(self)
	self:SetTitle(L["DOMAIN_PROFILE"] .. ": " ..  L["CONFIGPANEL_TIMER_HEADER"])
	
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 1,
		function(check)
			check:SetTexts(L["UIPANEL_DRAWEDGE"], L["UIPANEL_DRAWEDGE_DESC"])
			check:SetSetting("DrawEdge")
		end,
		function(check)
			check:SetTexts(L["UIPANEL_FORCEDISABLEBLIZZ"], L["UIPANEL_FORCEDISABLEBLIZZ_DESC"])
			check:SetSetting("ForceNoBlizzCC")
		end,
		function(check)
			check:SetTexts(L["UIPANEL_HIDEBLIZZCDBLING"], L["UIPANEL_HIDEBLIZZCDBLING_DESC"])
			check:SetSetting("HideBlizzCDBling")
		end,
	})
end):SetPanelSet("profile")


TMW:RegisterUpgrade(60436, {
	icon = function(self, ics)
		ics.ShowTimerTextnoOCC = ics.ShowTimerText
	end,
})

TMW:RegisterUpgrade(60315, {
	icon = function(self, ics)
		-- Pull the setting from the profile settings, since this setting is now per-icon
		-- Also, the setting changed from "Ignore" to "Allow", so flip the boolean too.
		
		-- Old default value was true, so make sure we use true if the setting is nil from having been the same as default.
		local old = TMW.db.profile.ClockGCD
		if old == nil then
			old = true
		end
		
		ics.ClockGCD = not old
	end,
})

TMW:RegisterUpgrade(45608, {
	icon = function(self, ics)
		if not ics.ShowTimer then
			ics.ShowTimerText = false
		end
	end,
})

TMW:RegisterCallback("TMW_DB_PRE_DEFAULT_UPGRADES", function() -- 45607
	-- The default for ShowTimerText changed from true to false in v45607
	-- So, if the user is upgrading to this version, and ShowTimerText is nil,
	-- then it must have previously been set to true, causing Ace3DB not to store it,
	-- so explicity set it as true to make sure it doesn't change just because the default changed.
	
	if TellMeWhenDB.profiles and TellMeWhenDB.Version < 45607 then
		for _, p in pairs(TellMeWhenDB.profiles) do
			if p.Groups then
				for _, gs in pairs(p.Groups) do
					if gs.Icons then
						for _, ics in pairs(gs.Icons) do
							if ics.ShowTimerText == nil then
								ics.ShowTimerText = true
							end
						end
					end
				end
			end
		end
	end
end)

CooldownSweep:RegisterAnchorableFrame("Cooldown")

function CooldownSweep:OnNewInstance(icon)
	self.cooldown = CreateFrame("Cooldown", self:GetChildNameBase() .. "Cooldown", icon, "CooldownFrameTemplate")

	-- cooldown2 displays charges.
	self.cooldown2 = CreateFrame("Cooldown", self:GetChildNameBase() .. "Cooldown2", icon, "CooldownFrameTemplate")
	
	-- Let OmniCC detect this as the charge cooldown frame.
	-- https://github.com/ascott18/TellMeWhen/issues/1784
	icon.chargeCooldown = self.cooldown2
	
	self:SetSkinnableComponent("Cooldown", self.cooldown)
	self:SetSkinnableComponent("ChargeCooldown", self.cooldown2)
end

local NeedsUpdate = {}


function CooldownSweep:OnDisable()
	self.start = 0
	self.duration = 0
	self.charges = 0
	self.maxCharges = 0
	self.chargeStart = 0
	self.chargeDur = 0
	
	self:UpdateCooldown()
end

local omnicc_loaded = IsAddOnLoaded("OmniCC")
local tullacc_loaded = IsAddOnLoaded("tullaCC")
local shouldShowBling

function CooldownSweep:SetupForIcon(icon)
	self.ShowTimer = icon.ShowTimer
	self.ShowTimerText = icon.ShowTimerText
	self.ShowTimerTextnoOCC = icon.ShowTimerTextnoOCC
	self.InvertTimer = icon.InvertTimer
	
	self.ClockGCD = icon.ClockGCD
	if icon.typeData.hasNoGCD then
		self.ClockGCD = true
	end
	
	-- For OmniCC/tullaCC/most other cooldown count mods (I think LUI uses this too)
	self.cooldown.noCooldownCount = not icon.ShowTimerText
	self.cooldown2.noCooldownCount = not icon.ShowTimerText 
	if ElvUI and ElvUI[1] and ElvUI[1].CooldownEnabled and ElvUI[1].RegisterCooldown then
		if icon.ShowTimerTextnoOCC then
			ElvUI[1]:RegisterCooldown(self.cooldown, "TellMeWhen")
		else
			ElvUI[1]:ToggleCooldown(self.cooldown, icon.ShowTimerTextnoOCC);
		end
	end

	-- new in WoW 6.0
	local hideNumbers
	if omnicc_loaded
	or tullacc_loaded
	or TMW.db.profile.ForceNoBlizzCC
	or LibStub("AceAddon-3.0"):GetAddon("LUI_Cooldown", true)
	then
		hideNumbers = true
	else
		hideNumbers = not self.ShowTimerText
	end

	self.cooldown:SetHideCountdownNumbers(hideNumbers)
	self.cooldown:SetDrawEdge(self.ShowTimer and TMW.db.profile.DrawEdge)
	self.cooldown:SetDrawSwipe(self.ShowTimer)

	shouldShowBling = not TMW.db.profile.HideBlizzCDBling
	self.cooldown:SetDrawBling(shouldShowBling)
	self.blingShown = shouldShowBling
	if shouldShowBling and not self.hookedBling then
		self.hookedBling = true

		-- Workaround https://github.com/ascott18/TellMeWhen/issues/2065
		-- because the bling effect entirely ignores the alpha of its ancestor tree.
		-- So, hide the bling at the moment of CD finish if the icon is hidden.
		self.cooldown:SetScript("OnCooldownDone", function()
			if shouldShowBling and self.cooldown:GetEffectiveAlpha() > 0 then
				if not self.blingShown then
					self.blingShown = true
					self.cooldown:SetDrawBling(true)
				end
			elseif self.blingShown then
				self.blingShown = false
				self.cooldown:SetDrawBling(false)
			end
		end)
	end

	self.cooldown2:SetHideCountdownNumbers(hideNumbers)
	self.cooldown2:SetDrawEdge(self.ShowTimer)
	self.cooldown2:SetDrawSwipe(false)
	self.cooldown2:SetDrawBling(false)

	-- https://github.com/ascott18/TellMeWhen/issues/1914:
	-- If a meta icon switches between hidden/shown timer text
	-- but does not switch to an actual different duration,
	-- OmniCC will see that the duration is the same and elect to
	-- do nothing. This fixes that.
	if OmniCC and OmniCC.Cooldown and OmniCC.Cooldown.Refresh then
		OmniCC.Cooldown.Refresh(self.cooldown, true)
		OmniCC.Cooldown.Refresh(self.cooldown2, true)
	end


	local attributes = icon.attributes
	
	self:DURATION(icon, attributes.start, attributes.duration)
	self:SPELLCHARGES(icon, attributes.charges, attributes.maxCharges, attributes.chargeStart, attributes.chargeDur)
	self:REVERSE(icon, attributes.reverse)
end

function CooldownSweep:UpdateCooldown()
	local cd = self.cooldown
	local icon = self.icon

	local duration = self.duration


	local mainStart, mainDuration
	local otherStart, otherDuration = 0, 0

	if self.maxCharges ~= 0 and self.charges == 0 then
		mainStart, mainDuration = self.chargeStart, self.chargeDur
	else
		mainStart, mainDuration = self.start, duration
		if self.charges ~= self.maxCharges then
			otherStart, otherDuration = self.chargeStart, self.chargeDur
		end
	end

	if mainDuration > 0 then
		if self.ShowTimer then
			cd:SetDrawEdge(TMW.db.profile.DrawEdge)
			cd:SetDrawSwipe(true)
		else
			cd:SetDrawEdge(false)
			cd:SetDrawSwipe(false)
		end

		cd:SetCooldown(mainStart, mainDuration)
		cd:Show()
	else
		cd:SetCooldown(0, 0)
	end

	-- Handle charges of spells that aren't completely depleted.
	local cd2 = self.cooldown2
	if otherDuration > 0 then
		cd2:SetCooldown(otherStart, otherDuration)
		cd2:Show()
	else
		cd2:SetCooldown(0, 0)
	end
end

function CooldownSweep:DURATION(icon, start, duration)
	if (not self.ClockGCD and OnGCD(duration)) or (duration - (TMW.time - start)) <= 0 or duration <= 0 then
		start, duration = 0, 0
	end
	
	if self.start ~= start or self.duration ~= duration then
		self.start = start
		self.duration = duration
		
		NeedsUpdate[self] = true
	end
end
CooldownSweep:SetDataListener("DURATION")

function CooldownSweep:SPELLCHARGES(icon, charges, maxCharges, chargeStart, chargeDur)
	self.charges = charges or 0
	self.maxCharges = maxCharges or 0
	self.chargeStart = chargeStart or 0
	self.chargeDur = chargeDur or 0
	
	NeedsUpdate[self] = true
end
CooldownSweep:SetDataListener("SPELLCHARGES")

function CooldownSweep:REVERSE(icon, reverse)
	if self.InvertTimer then
		reverse = not reverse
	end

	self.cooldown:SetReverse(reverse)
end
CooldownSweep:SetDataListener("REVERSE")


TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", function()
	for module in pairs(NeedsUpdate) do
		module.cooldown:Clear()
		module:UpdateCooldown()
	end
	wipe(NeedsUpdate)
end)