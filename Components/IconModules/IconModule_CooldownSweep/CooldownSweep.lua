-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local OnGCD = TMW.OnGCD
local ClockGCD

local CooldownSweep = TMW:NewClass("IconModule_CooldownSweep", "IconModule")

CooldownSweep:RegisterIconDefaults{
	ShowTimer = false,
	ShowTimerText = false,
}

CooldownSweep:RegisterConfigPanel_ConstructorFunc(200, "TellMeWhen_TimerSettings", function(self)
	self.Header:SetText(L["CONFIGPANEL_TIMER_HEADER"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 3,
		{
			setting = "ShowTimer",
			title = TMW.L["ICONMENU_SHOWTIMER"],
			tooltip = TMW.L["ICONMENU_SHOWTIMER_DESC"],
		},
		{
			setting = "ShowTimerText",
			title = TMW.L["ICONMENU_SHOWTIMERTEXT"],
			tooltip = TMW.L["ICONMENU_SHOWTIMERTEXT_DESC"],
			disabled = function()
				return not (IsAddOnLoaded("OmniCC") or IsAddOnLoaded("tullaCC") or LibStub("AceAddon-3.0"):GetAddon("LUI_Cooldown", true))
			end,
		},
	})
end)


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


function CooldownSweep:OnNewInstance(icon)
	self.cooldown = CreateFrame("Cooldown", icon:GetName() .. "Cooldown", icon, "CooldownFrameTemplate")
	self:SetSkinnableComponent("Cooldown", self.cooldown)
end

function CooldownSweep:OnEnable()
	if not TMW.ISMOP then
		-- SetDrawEdge has been removed in MOP
		self.cooldown:SetDrawEdge(TMW.db.profile.DrawEdge)
	end

	local icon = self.icon
	local attributes = icon.attributes
	self:DURATION(icon, attributes.start, attributes.duration)
	self:REVERSE(icon, attributes.reverse)
end
function CooldownSweep:OnDisable()
	self:SetCooldown(0, 0)
end

function CooldownSweep:SetupForIcon(sourceIcon)
	self.ShowTimer = sourceIcon.ShowTimer
	self.ShowTimerText = sourceIcon.ShowTimerText
	self.cooldown.noCooldownCount = not sourceIcon.ShowTimerText
end

function CooldownSweep:SetCooldown(start, duration)
	local cd = self.cooldown
	cd:SetCooldown(start, duration)
	cd.s = start
	cd.d = duration
	
	if duration > 0 then
		cd:Show() 
		cd:SetAlpha(1)
	else
		cd:Hide()
	end
end

function CooldownSweep:DURATION(icon, start, duration)
	local cd = self.cooldown
	
	if (OnGCD(duration) and ClockGCD) or (duration - (TMW.time - start)) <= 0 or duration <= 0 then
		start, duration = 0, 0
	end
	
	if cd.s ~= start or cd.d ~= duration then
		self:SetCooldown(start, duration)

		if not self.ShowTimer then
			cd:SetAlpha(0)
		end
	end
end
CooldownSweep:SetDataListner("DURATION")

function CooldownSweep:REVERSE(icon, reverse)
	self.cooldown:SetReverse(reverse)
end
CooldownSweep:SetDataListner("REVERSE")

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ClockGCD = TMW.db.profile.ClockGCD
end)

	