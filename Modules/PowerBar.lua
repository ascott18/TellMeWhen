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
local _, pclass = UnitClass("Player")
local	GetSpellInfo, UnitPower =
		GetSpellInfo, UnitPower
local PowerBarColor = PowerBarColor
local	pairs, wipe, _G =
		pairs, wipe, _G

local defaultPowerTypes = {
	ROGUE		= 3,
	PRIEST		= 0,
	DRUID		= 0,
	WARRIOR		= 1,
	MAGE		= 0,
	WARLOCK		= 0,
	PALADIN		= 0,
	SHAMAN		= 0,
	HUNTER		= 2,
	DEATHKNIGHT = 6,
}
local defaultPowerType = defaultPowerTypes[pclass]

local PBarsToUpdate = {}

local PBar = TMW:NewClass("PBar", "StatusBar", "UpdateTableManager", "AceEvent-3.0", "AceTimer-3.0")
PBar:UpdateTable_Set(PBarsToUpdate)

function PBar:OnNewInstance(...)
	local _, name, icon = ... -- the CreateFrame args
	
	self.Max = 1
	self.PBarOffs = 0
	self.icon = icon
	self:SetFrameLevel(icon:GetFrameLevel() + 2)
	
	self:SetPoint("BOTTOM", icon, "CENTER", 0, 0.5)
	self:SetPoint("TOPLEFT")
	self:SetPoint("TOPRIGHT")
	
	self.texture = self:CreateTexture(nil, "OVERLAY")
	self.texture:SetAllPoints()
	self:SetStatusBarTexture(self.texture)
end

function PBar:SetAttributes(source)
	-- source should either be a PBar or an Icon.
	-- Code must maintain compatability so that both of these will work as input (keep inherited keys the same)
	
	self.InvertBars = source.InvertBars
	self.PBarOffs = source.PBarOffs or 0
	self.ShowPBar = source.ShowPBar
	
	if self.ShowPBar then
		self:Show()
	else
		self:Hide()
	end
end

function PBar:Setup()
	local icon = self.icon	

	self.texture:SetTexture(LSM:Fetch("statusbar", TMW.db.profile.TextureName))
	
	local blizzEdgeInsets = icon.group.barInsets or 0
	self:SetPoint("BOTTOM", icon.texture, "CENTER", 0, 0.5)
	self:SetPoint("TOPLEFT", icon.texture, "TOPLEFT", blizzEdgeInsets, -blizzEdgeInsets)
	self:SetPoint("TOPRIGHT", icon.texture, "TOPRIGHT", -blizzEdgeInsets, -blizzEdgeInsets)
	
	if not self.powerType then
		local powerType = defaultPowerType
		local colorinfo = PowerBarColor[powerType]
		self:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
		self.powerType = powerType
	end
	
	self:SetAttributes(icon)

	if self.ShowPBar then
		-- register on PBar, not self
		PBar:RegisterEvent("SPELL_UPDATE_USABLE")
		PBar:RegisterEvent("UNIT_POWER_FREQUENT")
	end
end

function PBar:SetSpell(spell)
	self.spell = spell
	
	if spell then
		local _, _, _, cost, _, powerType = GetSpellInfo(spell)
		
		cost = powerType == 9 and 3 or cost or 0 -- holy power hack: always use a max of 3
		self.Max = cost
		self:SetMinMaxValues(0, cost)
		self.__value = nil -- the displayed value might change when we change the max, so force an update
		
		powerType = powerType or defaultPowerType
		if powerType ~= self.powerType then
			local colorinfo = PowerBarColor[powerType]
			self:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
			self.powerType = powerType
		end

		if not self.UpdateTable_IsInUpdateTable then
			PBarsToUpdate[#PBarsToUpdate + 1] = self
			self.UpdateTable_IsInUpdateTable = true
		end
		
		self:Update()
	elseif self.UpdateTable_IsInUpdateTable then
		local value = self.InvertBars and self.Max or 0
		self:SetValue(value)
		self.__value = value
		
		self:UpdateTable_Unregister()
	end
end

function PBar:Update(power, powerTypeNum)
	if not powerTypeNum then
		powerTypeNum = self.powerType
		power = UnitPower("player", powerTypeNum)
	end
	
	if powerTypeNum == self.powerType then
	
		local Max = self.Max
		local value

		if not self.InvertBars then
			value = Max - power + self.PBarOffs
		else
			value = power + self.PBarOffs
		end

		if value > Max then
			value = Max
		elseif value < 0 then
			value = 0
		end

		if self.__value ~= value then
			self:SetValue(value)
			self.__value = value
		end
	end
end



local updatePBars


function PBar:ForceUpdatePBars()
	PBar:UNIT_POWER_FREQUENT("UNIT_POWER_FREQUENT", "player")
end

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED", function(event, time, Locked)
	if Locked and updatePBars then
		for i = 1, #PBarsToUpdate do
			local pbar = PBarsToUpdate[i]
			pbar:SetSpell(pbar.spell) -- force an update
		end
		updatePBars = nil
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event, Locked)
	updatePBars = 1

	PBar:ScheduleTimer("ForceUpdatePBars", 0.55)
	PBar:ScheduleTimer("ForceUpdatePBars", 1)
	PBar:ScheduleTimer("ForceUpdatePBars", 2)	
end)

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	updatePBars = 1
	
	local pbar = icon.pbar
	if pbar then
		pbar:Setup()
		pbar.__value = nil

		if TMW.db.profile.Locked then
			pbar:SetAlpha(.9)
		else
			pbar:UpdateTable_Unregister()
			pbar:SetValue(pbar.Max)
			pbar:SetAlpha(.7)
		end
		
		if icon.isDefaultSkin then
			icon.pbar:SetFrameLevel(icon:GetFrameLevel() + 2)
		else
			icon.pbar:SetFrameLevel(icon:GetFrameLevel() + -1)
		end
	end
end)

TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if not Locked then
		for _, pbar in pairs(PBarsToUpdate) do
			pbar.UpdateTable_IsInUpdateTable = nil
		end
		wipe(PBarsToUpdate)
	end
end)

TMW:RegisterCallback("TMW_ICON_META_INHERITED_ICON_CHANGED", function(event, icon, icToUse)
	icon.pbar:SetAttributes(icToUse.pbar)
end)

function PBar:SPELL_UPDATE_USABLE()
	updatePBars = 1
end


function PBar:UNIT_POWER_FREQUENT(event, unit, powerType)
	-- powerType is an event arg
	if unit == "player" then
		-- these may be nil if coming from a manual update. in that case, they will be determined by the bar's settings and attributes
		local powerTypeNum = powerType and _G["SPELL_POWER_" .. powerType]
		local power = powerTypeNum and UnitPower("player", powerTypeNum)
		
		for i = 1, #PBarsToUpdate do
			local pbar = PBarsToUpdate[i]
			pbar:Update(power, powerTypeNum)
		end
	end
end