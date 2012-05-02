-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L

local OnGCD = TMW.OnGCD
local ClockGCD

local CooldownSweep = TMW:NewClass("IconModule_CooldownSweep", "IconModule", "EssentialIconModule", "MasqueSkinnableIconModule")

function CooldownSweep:OnNewInstance(icon)
	self.cooldown = CreateFrame("Cooldown", icon:GetName() .. "Cooldown", icon, "CooldownFrameTemplate")
	self:SetSkinnableComponent("Cooldown", self.cooldown)
end

function CooldownSweep:OnEnable()
	self.cooldown:SetDrawEdge(TMW.db.profile.DrawEdge)
	self:SetEssentialModuleComponent("cooldown", self.cooldown)

	local icon = self.icon
	local attributes = icon.attributes
	self:DURATION(icon, attributes.start, attributes.duration)
	self:REVERSE(icon, attributes.reverse)
end
function CooldownSweep:OnDisable()
	self:SetCooldown(0, 0)
	self:SetEssentialModuleComponent("cooldown", nil)
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

	