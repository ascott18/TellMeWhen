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


local LSM = LibStub("LibSharedMedia-3.0")

local issecretvalue = TMW.issecretvalue
local	pairs, wipe =
		pairs, wipe

local CurveConstants_ZeroToOne = CurveConstants and CurveConstants.ZeroToOne
local CurveConstants_Reverse = CurveConstants and CurveConstants.Reverse
local zeroDurationObject = C_DurationUtil and C_DurationUtil.CreateDuration()

local BarsToUpdate = {}


local TimerBar = TMW:NewClass("IconModule_TimerBar", "IconModule", "UpdateTableManager")
TimerBar:UpdateTable_Set(BarsToUpdate)


local settings = {
	TimerBar_StartColor    = "ffff0000",
	TimerBar_MiddleColor   = "ffffff00",
	TimerBar_CompleteColor = "ff00ff00",
	TimerBar_EnableColors  = false,
}

-- Icon defaults
TimerBar:RegisterIconDefaults(settings)

-- Group defaults
TMW:MergeDefaultsTables(settings, TMW.Group_Defaults)

-- Global defaults (global doesn't have the Enable_Colors setting)
settings.TimerBar_EnableColors = nil
TMW:MergeDefaultsTables(settings, TMW.Defaults.global)


TimerBar:RegisterConfigPanel_XMLTemplate(52, "TellMeWhen_TimerBar_GroupColors")
	:SetPanelSet("group")
	:SetColumnIndex(1)


TimerBar:RegisterConfigPanel_XMLTemplate(52, "TellMeWhen_TimerBar_GlobalColors")
	:SetPanelSet("global")



TimerBar:RegisterAnchorableFrame("TimerBar")


function TimerBar:OnNewInstance(icon)	
	self.container = CreateFrame("Frame", nil, icon)
	self.container:SetAllPoints()

	local bar = CreateFrame("StatusBar", self:GetChildNameBase() .. "TimerBar", self.container)
	bar:SetAllPoints()
	self.bar = bar
	
	self.texture = bar:CreateTexture(nil, "OVERLAY")
	bar:SetStatusBarTexture(self.texture)

	-- Overlay used in secret world to show a full bar
	-- for a zero duration.
	self.texture2 = bar:CreateTexture(nil, "OVERLAY")
	self.texture2:SetAllPoints()
	
	self.Max = 1
	bar:SetMinMaxValues(0, self.Max)
	
	self.start = 0
	self.duration = 0
	self.normalStart = 0
	self.normalDuration = 0
	self.chargeStart = 0
	self.chargeDur = 0
	self.Offset = 0
	self.__oldPercent = 0
	
	self:UpdateValue(true)
end

function TimerBar:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	
	self.bar:Show()
	local texture = icon.group.TextureName
	if texture == "" then
		texture = TMW.db.profile.TextureName
	end
	self.texture:SetTexture(LSM:Fetch("statusbar", texture))

	self.texture2:SetTexture(LSM:Fetch("statusbar", texture))
	self.texture2:SetAlpha(0)

	-- Workaround blizzard having choppy animations on bars with high scale.
	-- Set the bar's effective scale to exactly align to to screen resolution.
	self.bar:SetScale(PixelUtil.GetPixelToUIUnitFactor() / icon:GetEffectiveScale())
	
	self:SetCooldown(attributes.start, attributes.duration, attributes.durObj, attributes.chargeStart, attributes.chargeDur)
end
function TimerBar:OnDisable()
	self.__oldPercent = -1
	self.__value = -1
	self.bar:Hide()
	self:UpdateTable_Unregister()
end

function TimerBar:GetValue()
	-- returns value, doTerminate

	local Invert = self.Invert
	local durObj = self.durObj

	if durObj then
		if Invert then
			return durObj:GetElapsedDuration(), false
		else
			return durObj:GetRemainingDuration(), false
		end
	end

	local start, duration = self.start, self.duration

	if issecretvalue(duration) then
		-- Not sure why this happened once, but it did.
		-- Secret durations should always be handled by durObj above.
		return 0, true
	end

	if Invert then
		if duration == 0 then
			return self.Max, true
		else
			local value = TMW.time - start + self.Offset
			return value, value >= self.Max
		end
	else
		if duration == 0 then
			return 0, true
		else
			local value = duration - (TMW.time - start) + self.Offset
			return value, value <= 0
		end
	end
end

function TimerBar:UpdateValue(force)
	local ret = 0

	local Invert = self.Invert
	local invertColors = self.invertColors

	local value, doTerminate = self:GetValue()
	local maxValue = self.Max

	if doTerminate then
		self:UpdateTable_Unregister()
		ret = -1
		if Invert then
			value = self.Max
		else
			value = 0
		end
	end
	
	local bar = self.bar
	local durObj = self.durObj

	if issecretvalue(value) or issecretvalue(maxValue) or durObj then
		bar:SetValue(value, self.Smoothing)
		
		local valueCurveFunc = self.valueCurveFunc
		local defaultColor = invertColors and self.startColor or self.completeColor

		if valueCurveFunc then
			local rCurve, gCurve, bCurve, aCurve
			if invertColors then
				rCurve = self.rCurveInverted
				gCurve = self.gCurveInverted
				bCurve = self.bCurveInverted
				aCurve = self.aCurveInverted
			else
				rCurve = self.rCurve
				gCurve = self.gCurve
				bCurve = self.bCurve
				aCurve = self.aCurve
			end
			-- NB: When a curve is not defined, it means that all steps on it are equal,
			-- so we can just use the default color component. 
			local r = rCurve and valueCurveFunc(rCurve) or defaultColor.r
			local g = gCurve and valueCurveFunc(gCurve) or defaultColor.g
			local b = bCurve and valueCurveFunc(bCurve) or defaultColor.b
			local a = aCurve and valueCurveFunc(aCurve) or defaultColor.a
			self.texture:SetVertexColor(r, g, b, a)

			if Invert and durObj then
				-- This is the only way to set the bar to "full" when the duration is zero/expired.
				self.texture2:SetVertexColor(defaultColor:GetRGBA())
				self.texture2:SetAlphaFromBoolean(durObj:IsZero(), 1, 0)
			end

			if bar:GetReverseFill() then
				local percent = valueCurveFunc(CurveConstants_ZeroToOne)
				local inversePercent = valueCurveFunc(CurveConstants_Reverse)
				if Invert then
					percent, inversePercent = inversePercent, percent
				end

				-- Blizzard goofed (or forgot) when they implemented reverse filling,
				-- the tex coords are messed up. We'll just have to fix them ourselves.
				if bar:GetOrientation() == "VERTICAL" then
					self.texture:SetTexCoord(0, 0, percent, 0, 0, 1, percent, 1)
				else
					self.texture:SetTexCoord(inversePercent, 1, 0, 1)
				end
			end
		else
			self.bar:SetStatusBarColor(defaultColor:GetRGBA())
		end
	else
		local percent = maxValue == 0 and 0 or value / maxValue
		if percent < 0 then
			percent = 0
		elseif percent > 1 then
			percent = 1
		end

		if force or value ~= self.__value then
			local bar = self.bar
			bar:SetValue(value, self.Smoothing)

			if abs(self.__oldPercent - percent) > 0.02 then
				-- If the percentage of the bar changed by more than 2%, force an instant redraw of the texture.
				-- For some reason, blizzard defers the updating of status bar textures until sometimes 1 or 2 frames after it is set.
				self:UpdateStatusBarImmediate(percent)
			elseif bar:GetReverseFill() then
				-- Blizzard goofed (or forgot) when they implemented reverse filling,
				-- the tex coords are messed up. We'll just have to fix them ourselves.
				if bar:GetOrientation() == "VERTICAL" then
					self.texture:SetTexCoord(0, 0, percent, 0, 0, 1, percent, 1)
				else
					self.texture:SetTexCoord(1 - percent, 1, 0, 1)
				end
			end

			-- This line is here to fix an issue with the bar texture
			-- not being in the correct location/correct size if
			-- the bar is modified while it, or a parent, is hidden.
			--self.texture:GetSize()

			if value ~= 0 then
				local completeColor = self.completeColor
				local halfColor = self.halfColor
				local startColor = self.startColor

				if Invert then invertColors = not invertColors end
				if invertColors then
					completeColor, startColor = startColor, completeColor
				end
				
				-- This is multiplied by 2 because we subtract 100% if it ends up being past
				-- the point where halfColor will be used.
				-- If we don't multiply by 2, we would check if (percent > 0.5), but then
				-- we would have to multiply that percentage by 2 later anyway in order to use the
				-- full range of colors available (we would only get half the range of colors otherwise, which looks bad)
				local doublePercent = percent * 2

				if doublePercent > 1 then
					completeColor = halfColor
					doublePercent = doublePercent - 1
				else
					startColor = halfColor
				end

				local inv = 1-doublePercent

				bar:SetStatusBarColor(
					(startColor.r * doublePercent) + (completeColor.r * inv),
					(startColor.g * doublePercent) + (completeColor.g * inv),
					(startColor.b * doublePercent) + (completeColor.b * inv),
					(startColor.a * doublePercent) + (completeColor.a * inv)
				)
			end
			self.__value = value
			self.__oldPercent = percent
		end
	end
	
	return ret
end

function TimerBar:UpdateStatusBarImmediate(percent)
	local bar = self.bar
	local tex = self.texture

	if bar:GetOrientation() == "VERTICAL" then
		local height = bar:GetHeight()
		local sizePercent = height*percent


		-- tex:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
		if bar:GetReverseFill() then
			tex:SetPoint("BOTTOMLEFT", 0, height - sizePercent)
			tex:SetPoint("BOTTOMRIGHT", 0, height - sizePercent)
			tex:SetTexCoord(0, 0, percent, 0, 0, 1, percent, 1)
		else
			tex:SetPoint("TOPLEFT", 0, sizePercent - height)
			tex:SetPoint("TOPRIGHT", 0, sizePercent - height)
			tex:SetTexCoord(percent, 0, 0, 0, percent, 1, 0, 1)
		end

	else
		local width = bar:GetWidth()
		local sizePercent = width*percent

		if bar:GetReverseFill() then
			tex:SetPoint("TOPLEFT", width - sizePercent, 0)
			tex:SetPoint("BOTTOMLEFT", width - sizePercent, 0)
			tex:SetTexCoord(1 - percent, 1, 0, 1)
		else
			tex:SetPoint("TOPRIGHT", sizePercent - width, 0)
			tex:SetPoint("BOTTOMRIGHT", sizePercent - width, 0)
			tex:SetTexCoord(0, percent, 0, 1)
		end

	end
end


local function CreateColorCurves(completeValue, halfValue, startValue)
	if completeValue == halfValue and halfValue == startValue then
		return nil, nil
	end
	
	local curve = C_CurveUtil.CreateCurve()
	curve:SetType(Enum.LuaCurveType.Linear)
	curve:AddPoint(0, completeValue)
	curve:AddPoint(0.5, halfValue)
	curve:AddPoint(1, startValue)
	
	local curveInverted = C_CurveUtil.CreateCurve()
	curveInverted:SetType(Enum.LuaCurveType.Linear)
	curveInverted:AddPoint(0, startValue)
	curveInverted:AddPoint(0.5, halfValue)
	curveInverted:AddPoint(1, completeValue)
	
	return curve, curveInverted
end

function TimerBar:SetCooldown(start, duration, durObj, chargeStart, chargeDur)
	self.normalStart, self.normalDuration = start, duration
	self.chargeStart, self.chargeDur = chargeStart, chargeDur
	self.durObj = durObj
	self.value = nil
	self.valueCurveFunc = nil

	if durObj then
		if not self.BarGCD and durObj.isOnGCD then
			durObj = zeroDurationObject
			self.durObj = durObj
		end
		
		self.valueCurveFunc = function(curve)
			return durObj:EvaluateRemainingPercent(curve)
		end

		local duration = durObj:GetTotalDuration()

		if self.FakeMax then
			self.Max = self.FakeMax
		else
			self.Max = duration
		end
		self.bar:SetMinMaxValues(0, self.Max)
		self.__value = nil -- the displayed value might change when we change the max, so force an update

		self:UpdateTable_Register()
		return
	end

	if chargeDur and not issecretvalue(chargeDur) and chargeDur > 0 then
		duration = chargeDur

		self.duration = chargeDur
		self.start = chargeStart
	else
		self.duration = duration
		self.start = start
	end
	
	if not issecretvalue(duration) and duration > 0 then
		if not self.BarGCD and self.icon:OnGCD(duration) then
			self.duration = 0
		end

		self.Max = self.FakeMax or duration
		self.bar:SetMinMaxValues(0, self.Max)
		self.__value = nil -- the displayed value might change when we change the max, so force an update

		self:UpdateTable_Register()
	end
end

function TimerBar:SetColors(startColor, halfColor, completeColor)
	startColor    = startColor and TMW:StringToCachedColorMixin(startColor)
	halfColor     = halfColor and TMW:StringToCachedColorMixin(halfColor)
	completeColor = completeColor and TMW:StringToCachedColorMixin(completeColor)

	-- Skip curve creation if colors haven't changed
	if self.startColor == startColor and self.halfColor == halfColor and self.completeColor == completeColor then
		return
	end

	self.startColor    = startColor
	self.halfColor     = halfColor
	self.completeColor = completeColor

	if C_CurveUtil then
		self.rCurve, self.rCurveInverted = CreateColorCurves(completeColor.r, halfColor.r, startColor.r)
		self.gCurve, self.gCurveInverted = CreateColorCurves(completeColor.g, halfColor.g, startColor.g)
		self.bCurve, self.bCurveInverted = CreateColorCurves(completeColor.b, halfColor.b, startColor.b)
		self.aCurve, self.aCurveInverted = CreateColorCurves(completeColor.a, halfColor.a, startColor.a)
	end
end

function TimerBar:DURATION(icon, start, duration, modRate, durObj)
	self:SetCooldown(start, duration, durObj, self.chargeStart, self.chargeDur)
end
TimerBar:SetDataListener("DURATION")

function TimerBar:SPELLCHARGES(icon, charges, maxCharges, chargeStart, chargeDur)
	self:SetCooldown(self.normalStart, self.normalDuration, self.durObj, chargeStart, chargeDur)
end
TimerBar:SetDataListener("SPELLCHARGES")

function TimerBar:REVERSE(icon, reverse)
	self.invertColors = reverse
end
TimerBar:SetDataListener("REVERSE")

TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if not Locked then
		TimerBar:UpdateTable_UnregisterAll()
	end
end)

TMW:RegisterCallback("TMW_ONUPDATE_POST", function(event, time, Locked)
	local offs = 0
	for i = 1, #BarsToUpdate do
		local TimerBar = BarsToUpdate[i + offs]
		offs = offs + TimerBar:UpdateValue() -- returns -1 if the bar was unregistered, otherwise 0
	end
end)

