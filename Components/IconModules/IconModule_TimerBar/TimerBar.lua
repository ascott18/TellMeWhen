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
local LSM = LibStub("LibSharedMedia-3.0")
local	pairs, wipe =
		pairs, wipe
local BarsToUpdate = {}

local StatusBarTexture

local TimerBar = TMW:NewClass("IconModule_TimerBar", "IconModule", "UpdateTableManager")
TimerBar:UpdateTable_Set(BarsToUpdate)

TimerBar:RegisterAnchorableFrame("TimerBar")

function TimerBar:OnNewInstance(icon)	
	local bar = CreateFrame("StatusBar", self:GetChildNameBase() .. "TimerBar", icon)
	self.bar = bar
	
	self.texture = bar:CreateTexture(nil, "OVERLAY")
	self.texture:SetAllPoints()
	bar:SetStatusBarTexture(self.texture)
	
	self.Max = 1
	bar:SetMinMaxValues(0, self.Max)
	
	self:SetColors(TMW.Types[""].CBS, TMW.Types[""].CBC)
	
	self.start = 0
	self.duration = 0
	self.Offset = 0
	
	self:UpdateValue(1)
end

function TimerBar:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	
	self.bar:Show()
	self.texture:SetTexture(StatusBarTexture)
	
	self:DURATION(icon, attributes.start, attributes.duration)
end
function TimerBar:OnDisable()
	self.bar:Hide()
	self:UpdateTable_Unregister()
end

function TimerBar:UpdateValue(force)
	local ret = 0
	
	local value, doTerminate

	local start, duration, Invert = self.start, self.duration, self.Invert

	if Invert then
		if duration == 0 then
			value = self.Max
		else
			value = TMW.time - start + self.Offset
		end
		doTerminate = value >= self.Max
	else
		if duration == 0 then
			value = 0
		else
			value = duration - (TMW.time - start) + self.Offset
		end
		doTerminate = value <= 0
	end

	if doTerminate then
		self:UpdateTable_Unregister()
		ret = -1
		if Invert then
			value = self.Max
		else
			value = 0
		end
	end

	if force or value ~= self.__value then
		self.bar:SetValue(value)

		if value ~= 0 then
			local co = self.completeColor
			local st = self.startColor
			
			local pct = value / self.Max
			local inv = 1-pct
			self.bar:SetStatusBarColor(
				(co.r * pct) + (st.r * inv),
				(co.g * pct) + (st.g * inv),
				(co.b * pct) + (st.b * inv),
				(co.a * pct) + (st.a * inv)
			)
		end
		self.__value = value
	end
	
	return ret
end

function TimerBar:SetCooldown(start, duration, isGCD)
	self.duration = duration
	self.start = start
	
	if duration > 0 then
		if isGCD and not self.BarGCD then
			self.duration = 0
		end

		self.Max = duration
		self.bar:SetMinMaxValues(0, duration)
		self.__value = nil -- the displayed value might change when we change the max, so force an update

		self:UpdateTable_Register()
	end
end

function TimerBar:SetColors(startColor, completeColor)
	self.startColor = startColor
	self.completeColor = completeColor
end

function TimerBar:DURATION(icon, start, duration)
	self:SetCooldown(start, duration, TMW.OnGCD(duration))
end
TimerBar:SetDataListner("DURATION")



TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if not Locked then
		TimerBar:UpdateTable_UnregisterAll()
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event)
	StatusBarTexture = LSM:Fetch("statusbar", TMW.db.profile.TextureName)
end)

TMW:RegisterCallback("TMW_ONUPDATE_POST", function(event, time, Locked)
	local offs = 0
	for i = 1, #BarsToUpdate do
		local TimerBar = BarsToUpdate[i + offs]
		offs = offs + TimerBar:UpdateValue() -- returns -1 if the bar was unregistered, otherwise 0
	end
end)

