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
local GetSpellInfo, UnitPower =
	  GetSpellInfo, UnitPower
local pairs, wipe, _G =
	  pairs, wipe, _G
local PowerBarColor = PowerBarColor
local tContains = TMW.tContains

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

local PowerBar = TMW:NewClass("PowerBar", "StatusBar", "UpdateTableManager", "AceEvent-3.0", "AceTimer-3.0")
PowerBar:UpdateTable_Set(PBarsToUpdate)

function PowerBar:OnNewInstance(...)
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

function PowerBar:SetAttributes(source)
	-- source should either be a PowerBar or an Icon.
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

function PowerBar:Setup()
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
		-- register on PowerBar, not self
		PowerBar:RegisterEvent("SPELL_UPDATE_USABLE")
		PowerBar:RegisterEvent("UNIT_POWER_FREQUENT")
	end
end

function PowerBar:SetSpell(spell)
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

		self:UpdateTable_Register()
		
		self:Update()
	elseif tContains(self.UpdateTable_UpdateTable, self) then
		local value = self.InvertBars and self.Max or 0
		self:SetValue(value)
		self.__value = value
		
		self:UpdateTable_Unregister()
	end
end

function PowerBar:Update(power, powerTypeNum)
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


function PowerBar:ForceUpdatePBars()
	PowerBar:UNIT_POWER_FREQUENT("UNIT_POWER_FREQUENT", "player")
end

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED", function(event, time, Locked)
	if Locked and updatePBars then
		for i = 1, #PBarsToUpdate do
			local pbar_overlay = PBarsToUpdate[i]
			pbar_overlay:SetSpell(pbar_overlay.spell) -- force an update
		end
		updatePBars = nil
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event)
	updatePBars = 1

	PowerBar:ScheduleTimer("ForceUpdatePBars", 0.55)
	PowerBar:ScheduleTimer("ForceUpdatePBars", 1)
	PowerBar:ScheduleTimer("ForceUpdatePBars", 2)	
end)

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	updatePBars = 1
	
	local pbar_overlay = icon.pbar_overlay
	if pbar_overlay then
		pbar_overlay:Setup()
		pbar_overlay.__value = nil

		if TMW.db.profile.Locked then
			pbar_overlay:SetAlpha(.9)
		else
			pbar_overlay:UpdateTable_Unregister()
			pbar_overlay:SetValue(pbar_overlay.Max)
			pbar_overlay:SetAlpha(.7)
		end
		
		if icon.isDefaultSkin then
			icon.pbar_overlay:SetFrameLevel(icon:GetFrameLevel() + 2)
		else
			icon.pbar_overlay:SetFrameLevel(icon:GetFrameLevel() + -1)
		end
	end
end)

TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if not Locked then
		PowerBar:UpdateTable_UnregisterAll()
	end
end)

TMW:RegisterCallback("TMW_ICON_META_INHERITED_ICON_CHANGED", function(event, icon, icToUse)
	icon.pbar_overlay:SetAttributes(icToUse.pbar_overlay)
end)

TMW:RegisterCallback("TMW_ICON_SPELL_CHANGED", function(event, icon, spellChecked)
	local pbar_overlay = icon.pbar_overlay
	if pbar_overlay and pbar_overlay.ShowPBar then
		pbar_overlay:SetSpell(spellChecked)
	end
end)
	
	
function PowerBar:SPELL_UPDATE_USABLE()
	updatePBars = 1
end


function PowerBar:UNIT_POWER_FREQUENT(event, unit, powerType)
	-- powerType is an event arg
	if unit == "player" then
		-- these may be nil if coming from a manual update. in that case, they will be determined by the bar's settings and attributes
		local powerTypeNum = powerType and _G["SPELL_POWER_" .. powerType]
		local power = powerTypeNum and UnitPower("player", powerTypeNum)
		
		for i = 1, #PBarsToUpdate do
			local pbar_overlay = PBarsToUpdate[i]
			pbar_overlay:Update(power, powerTypeNum)
		end
	end
end