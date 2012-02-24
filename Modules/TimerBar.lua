-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local LSM = LibStub("LibSharedMedia-3.0")
local	pairs, wipe =
		pairs, wipe
local CBarsToUpdate = {}

local BarGCD

local TimerBar = TMW:NewClass("TimerBar", "StatusBar", "UpdateTableManager")
TimerBar:UpdateTable_Set(CBarsToUpdate)

function TimerBar:OnNewInstance(...)
	local _, name, icon = ... -- the CreateFrame args
	
	self.Max = 1
	self.CBarOffs = 0
	self.icon = icon
	self:SetFrameLevel(icon:GetFrameLevel() + 2)
	self:SetMinMaxValues(0, self.Max)
	
	self.start = 0
	self.duration = 0
	
	self:SetPoint("TOP", icon, "CENTER", 0, -0.5)
	self:SetPoint("BOTTOMLEFT")
	self:SetPoint("BOTTOMRIGHT")
	
	self.texture = self:CreateTexture(nil, "OVERLAY")
	self.texture:SetAllPoints()
	self:SetStatusBarTexture(self.texture)
end

function TimerBar:SetAttributes(source)
	-- source should either be a TimerBar or an Icon.
	-- Code must maintain compatability so that both of these will work as input (keep inherited keys the same)
	
	self.InvertBars = source.InvertBars
	self.CBarOffs = source.CBarOffs or 0
	self.ShowCBar = source.ShowCBar
	
	-- THIS WONT REALLY WORK CORRECTLY
	self.startColor = source.startColor or (source.typeData and source.typeData.CBS)
	self.completeColor = source.completeColor or (source.typeData and source.typeData.CBC)
	
	if self.ShowCBar then
		self:Show()
	else
		self:Hide()
	end
	
	self:Update(1)
end

function TimerBar:Setup()
	local icon = self.icon
	
	self.texture:SetTexture(LSM:Fetch("statusbar", TMW.db.profile.TextureName))
	
	local blizzEdgeInsets = icon.group.barInsets or 0
	self:SetPoint("TOP", icon.texture, "CENTER", 0, -0.5)
	self:SetPoint("BOTTOMLEFT", icon.texture, "BOTTOMLEFT", blizzEdgeInsets, blizzEdgeInsets)
	self:SetPoint("BOTTOMRIGHT", icon.texture, "BOTTOMRIGHT", -blizzEdgeInsets, blizzEdgeInsets)
	
	self:SetAttributes(icon)
end

function TimerBar:Update(force)
	local time = TMW.time
	local ret = 0
	
	local value, doTerminate

	local start, duration, InvertBars = self.start, self.duration, self.InvertBars

	if InvertBars then
		if duration == 0 then
			value = self.Max
		else
			value = time - start + self.CBarOffs
		end
		doTerminate = value >= self.Max
	else
		if duration == 0 then
			value = 0
		else
			value = duration - (time - start) + self.CBarOffs
		end
		doTerminate = value <= 0
	end

	if doTerminate then
		self:UpdateTable_Unregister()
		ret = -1
		if InvertBars then
			value = self.Max
		else
			value = 0
		end
	end

	if force or value ~= self.__value then
		self:SetValue(value)

		local co = self.completeColor
		local st = self.startColor

		if not InvertBars then
			-- normal
			if value ~= 0 then
				--local pct = (time - start) / duration
				local pct = value / self.Max
				local inv = 1-pct
				self:SetStatusBarColor(
					(co.r * pct) + (st.r * inv),
					(co.g * pct) + (st.g * inv),
					(co.b * pct) + (st.b * inv),
					(co.a * pct) + (st.a * inv)
				)
			--else
				-- no reason to do thisif value is 0
				-- self:SetStatusBarColor(st.r, st.g, st.b, st.a)
			end
		else
			--inverted
			if value ~= 0 then
				--local pct = (time - start) / duration
				local pct = value / self.Max
				local inv = 1-pct
				self:SetStatusBarColor(
					(co.r * pct) + (st.r * inv),
					(co.g * pct) + (st.g * inv),
					(co.b * pct) + (st.b * inv),
					(co.a * pct) + (st.a * inv)
				)
			--else
				-- no reason to do thisif value is 0
				--	self:SetStatusBarColor(co.r, co.g, co.b, co.a)
			end
		end
		self.__value = value
	end
	
	return ret
end

function TimerBar:SetCooldown(start, duration, isGCD)
	self.duration = duration
	self.start = start
	
	if duration > 0 then
		if isGCD and BarGCD then -- TODO: upvalue BarGCD
			self.duration = 0
		end

		self.Max = duration
		self:SetMinMaxValues(0, duration)
		self.__value = nil -- the displayed value might change when we change the max, so force an update

		self:UpdateTable_Register()
	end
end




TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event)
	BarGCD = TMW.db.profile.BarGCD
end)

TMW:RegisterCallback("TMW_ONUPDATE", function(event, time, Locked)
	local offs = 0
	for i = 1, #CBarsToUpdate do
		local cbar_overlay = CBarsToUpdate[i + offs]
		offs = offs + cbar_overlay:Update() -- returns -1 if the cbar was unregistered, otherwise 0
	end
end)

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	local cbar_overlay = icon.cbar_overlay
	if cbar_overlay then
		cbar_overlay:Setup()
		cbar_overlay.__value = nil

		cbar_overlay:UpdateTable_Unregister()
		if TMW.db.profile.Locked and icon.ShowCBar then
			cbar_overlay:UpdateTable_Register()
		end
		
		if TMW.db.profile.Locked then
			cbar_overlay:SetAlpha(.9)
		else
			cbar_overlay:UpdateTable_Unregister()
			cbar_overlay:SetValue(cbar_overlay.Max)
			cbar_overlay:SetAlpha(.7)
			cbar_overlay:SetStatusBarColor(0, 1, 0, 0.5)
		end
		
		if icon.isDefaultSkin then
			icon.cbar_overlay:SetFrameLevel(icon:GetFrameLevel() + 2)
		else
			icon.cbar_overlay:SetFrameLevel(icon:GetFrameLevel() + -1)
		end
	end
end)

TMW:RegisterCallback("TMW_ICON_META_INHERITED_ICON_CHANGED", function(event, icon, icToUse)
	icon.cbar_overlay:SetAttributes(icToUse.cbar_overlay)
end)

TMW:RegisterCallback("TMW_ICON_COOLDOWN_CHANGED", function(event, icon, start, duration, isGCD, reverse)
	local cbar_overlay = icon.cbar_overlay
	if cbar_overlay and cbar_overlay.ShowCBar then
		cbar_overlay:SetCooldown(start, duration, isGCD)
	end
end)

TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if not Locked then
		TimerBar:UpdateTable_UnregisterAll()
	end
end)
