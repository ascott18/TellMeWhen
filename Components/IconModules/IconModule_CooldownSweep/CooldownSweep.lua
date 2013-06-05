-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local OnGCD = TMW.OnGCD

local CooldownSweep = TMW:NewClass("IconModule_CooldownSweep", "IconModule")

CooldownSweep:RegisterIconDefaults{
	ShowTimer = false,
	ShowTimerText = false,
	ShowTimerTextnoOCC = false,
	ClockGCD = false,
}

CooldownSweep:RegisterConfigPanel_ConstructorFunc(200, "TellMeWhen_TimerSettings", function(self)
	self.Header:SetText(L["CONFIGPANEL_TIMER_HEADER"])
	TMW.HELP:NewCode("IE_TIMERTEXTHANDLER_MISSING", nil, true)
	
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 2,
		{
			setting = "ShowTimer",
			title = L["ICONMENU_SHOWTIMER"],
			tooltip = L["ICONMENU_SHOWTIMER_DESC"],
		},
		{
			setting = "ShowTimerText",
			title = L["ICONMENU_SHOWTIMERTEXT"],
			tooltip = L["ICONMENU_SHOWTIMERTEXT_DESC"],
			OnState = function(self)
				if TMW.CI.ics.ShowTimerText then
					if	not (OmniCC or IsAddOnLoaded("OmniCC")) -- Tukui is handled by OmniCC == true
					and	not IsAddOnLoaded("tullaCC")
					and	not LibStub("AceAddon-3.0"):GetAddon("LUI_Cooldown", true)
					then
					 TMW.HELP:Show("IE_TIMERTEXTHANDLER_MISSING", nil, self, 0, 0, L["HELP_IE_TIMERTEXTHANDLER_MISSING"])
					end
				end			
			end,
		},
		{
			setting = "ClockGCD",
			title = L["ICONMENU_ALLOWGCD"],
			tooltip = L["ICONMENU_ALLOWGCD_DESC"],
			disabled = function(self)
				return not TMW.CI.ics.ShowTimer and not TMW.CI.ics.ShowTimerText and not TMW.CI.ics.ShowTimerTextnoOCC
			end,
		},
		{
			setting = "ShowTimerTextnoOCC",
			title = L["ICONMENU_SHOWTIMERTEXT_NOOCC"],
			tooltip = L["ICONMENU_SHOWTIMERTEXT_NOOCC_DESC"],
			hidden = function()
				return not IsAddOnLoaded("ElvUI")
			end,
			disabled = function(self)
				return not TMW.CI.ics.ShowTimer
			end,
		},
	})
end)


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

TMW:RegisterCallback("TMW_DB_PRE_DEFAULT_UPGRADES", function()
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
	
	self:SetSkinnableComponent("Cooldown", self.cooldown)
end

function CooldownSweep:OnDisable()
	local cd = self.cooldown
	
	cd.start, cd.duration = 0, 0
	cd.charges, cd.maxCharges = nil, nil
	
	self:UpdateCooldown()
end

function CooldownSweep:SetupForIcon(icon)
	self.ShowTimer = icon.ShowTimer
	self.ShowTimerText = icon.ShowTimerText
	self.ShowTimerTextnoOCC = icon.ShowTimerTextnoOCC
	self.ClockGCD = icon.ClockGCD
	
	local tukui = IsAddOnLoaded("Tukui")
	local elvui = IsAddOnLoaded("ElvUI")
	
	if tukui then
		-- Tukui forcibly disables its own timers if OmniCC is installed, so no worry about overlap.
		self.cooldown.noCooldownCount = not icon.ShowTimerText
		self.cooldown.noOCC = not icon.ShowTimerText
	elseif elvui then
		self.cooldown.noCooldownCount = not icon.ShowTimerText -- For OmniCC/tullaCC/most other cooldown count mods (I think LUI uses this too)
		self.cooldown.noOCC = not icon.ShowTimerTextnoOCC -- For ElvUI
	else
		self.cooldown.noCooldownCount = not icon.ShowTimerText -- For OmniCC/tullaCC/most other cooldown count mods (I think LUI uses this too)
	end
	--[[
	self.cooldown.noCooldownCount = not icon.ShowTimerText -- For OmniCC/tullaCC/most other cooldown count mods (I think LUI uses this too)
	self.cooldown.noOCC = not icon.ShowTimerTextnoOCC -- For ElvUI
	]]
	
	local attributes = icon.attributes
	
	
	self:DURATION(icon, attributes.start, attributes.duration)
	self:SPELLCHARGES(icon, attributes.charges, attributes.maxCharges)
	self:REVERSE(icon, attributes.reverse)
end

function CooldownSweep:UpdateCooldown()
	local cd = self.cooldown
	local duration = cd.duration
	
	cd:SetCooldown(cd.start, duration, cd.charges, cd.maxCharges)
	
	if duration > 0 then
		cd:Show()
		cd:SetAlpha(self.ShowTimer and 1 or 0)
	else
		cd:Hide()
	end

	if not self.ShowTimer then
		cd:SetAlpha(0)
	end
end

function CooldownSweep:DURATION(icon, start, duration)
	local cd = self.cooldown
	
	if (not self.ClockGCD and OnGCD(duration)) or (duration - (TMW.time - start)) <= 0 or duration <= 0 then
		start, duration = 0, 0
	end
	
	if cd.start ~= start or cd.duration ~= duration then
		cd.start = start
		cd.duration = duration
		
		self:UpdateCooldown()
	end
end
CooldownSweep:SetDataListner("DURATION")

function CooldownSweep:SPELLCHARGES(icon, charges, maxCharges)
	local cd = self.cooldown
	
	if cd.charges ~= charges or cd.maxCharges ~= maxCharges then
		cd.charges = charges
		cd.maxCharges = maxCharges
		
		self:UpdateCooldown()
	end
end
CooldownSweep:SetDataListner("SPELLCHARGES")

function CooldownSweep:REVERSE(icon, reverse)
	self.cooldown:SetReverse(reverse)
end
CooldownSweep:SetDataListner("REVERSE")

	