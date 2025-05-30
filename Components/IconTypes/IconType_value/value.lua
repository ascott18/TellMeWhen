﻿-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local UnitPower, UnitPowerMax, UnitPowerType, UnitPowerDisplayMod, GetComboPoints, MAX_COMBO_POINTS
    = UnitPower, UnitPowerMax, UnitPowerType, UnitPowerDisplayMod, GetComboPoints, MAX_COMBO_POINTS

local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

local pairs
	= pairs  
	
local _, pclass = UnitClass("Player")
local GetSpellTexture = TMW.GetSpellTexture



local Type = TMW.Classes.IconType:New("value")
Type.name = L["ICONMENU_VALUE"]
Type.desc = L["ICONMENU_VALUE_DESC"]
Type.menuIcon = "Interface/Icons/inv_potion_49"
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true
Type.menuSpaceBefore = true
Type.barIsValue = true

local STATE_UNITFOUND = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_NOUNIT = TMW.CONST.STATE.DEFAULT_HIDE

Type:SetAllowanceForView("icon", false)


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("value, maxValue, valueColor")
Type:UsesAttributes("state")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)


Type:RegisterIconDefaults{
	-- The unit to check for resources
	Unit					= "player", 

	-- The power type to display from the unit.
	-- -2 is the default resouce type. -1 is health.
	PowerType				= -2,

	-- Whether to represent value fragments, or only whole value increments.
	ValueFragments          = false,
}



Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_UNITFOUND] = { text = "|cFF00FF00" .. L["ICONMENU_VALUE_HASUNIT"], },
	[STATE_NOUNIT]    = { text = "|cFFFF0000" .. L["ICONMENU_VALUE_NOUNIT"],  },
})

Type:RegisterConfigPanel_ConstructorFunc(100, "TellMeWhen_ValueSettings", function(self)
	self:SetTitle(L["ICONMENU_VALUE_POWERTYPE"])

	local types = {
		{ order = -2, id = -2, name = L["CONDITIONPANEL_POWER"], },
		{ order = -1, id = -1, name = HEALTH, },
	    { order = 1,  id = Enum.PowerType.Mana, name = MANA, },
		{ order = 2,  id = Enum.PowerType.Rage, name = RAGE, },
		{ order = 3,  id = Enum.PowerType.Energy, name = ENERGY, },
		{ order = 4,  id = Enum.PowerType.ComboPoints, name = COMBO_POINTS, },
		{ order = 5,  id = Enum.PowerType.Focus, name = FOCUS, },
		{ order = 6,  id = Enum.PowerType.RunicPower, name = RUNIC_POWER, }
	}

	if UnitStagger then
		types[#types+1] = { order = 20,  id = -3, name = STAGGER or "Stagger", }
	end

	if TMW.isCataOrGreater then
		types[#types+1] = { order = 7,  id = Enum.PowerType.SoulShards, name = SOUL_SHARDS_POWER, }
		types[#types+1] = { order = 8,  id = Enum.PowerType.HolyPower, name = HOLY_POWER, }
		types[#types+1] = { order = 16,  id = Enum.PowerType.Alternate, name = L["CONDITIONPANEL_ALTPOWER"], }
	end
	
	if TMW.isMopOrGreater then
		types[#types+1] = { order = 9,  id = Enum.PowerType.Chi, name = CHI_POWER; }
	end

	if TMW.isMop then
		types[#types+1] = { order = 21,  id = Enum.PowerType.ShadowOrbs, name = SHADOW_ORBS, }
		types[#types+1] = { order = 22,  id = Enum.PowerType.DemonicFury, name = DEMONIC_FURY, }
		types[#types+1] = { order = 23,  id = Enum.PowerType.BurningEmbers, name = BURNING_EMBERS, }
	end

	if TMW.isRetail then
		types[#types+1] = { order = 10,  id = Enum.PowerType.Maelstrom, name = MAELSTROM_POWER, }
		types[#types+1] = { order = 11,  id = Enum.PowerType.ArcaneCharges, name = ARCANE_CHARGES_POWER, }
		types[#types+1] = { order = 12,  id = Enum.PowerType.LunarPower, name = LUNAR_POWER, }
		types[#types+1] = { order = 13,  id = Enum.PowerType.Insanity, name = INSANITY_POWER, }
		types[#types+1] = { order = 14,  id = Enum.PowerType.Fury, name = FURY, }
		types[#types+1] = { order = 15,  id = Enum.PowerType.Pain, name = PAIN, }
		types[#types+1] = { order = 17,  id = Enum.PowerType.Essence, name = POWER_TYPE_ESSENCE, }
	end


	self.PowerType = TMW.C.Config_DropDownMenu:New("Frame", "$parent", self, "TMW_DropDownMenuTemplate")

	self.PowerType:SetTexts(L["ICONMENU_VALUE_POWERTYPE"], L["ICONMENU_VALUE_POWERTYPE_DESC"])
	local function DropdownOnClick(button, arg1)
		TMW.CI.ics.PowerType = arg1
		self.PowerType:SetText(button.value)
		TMW.IE:LoadIcon(1)
	end
	self.PowerType:SetFunction(function(self)
		for _, data in TMW:OrderedPairs(types, TMW.OrderSort, true) do
			if data.id then
				local info = TMW.DD:CreateInfo()
				info.text = data.name
				info.func = DropdownOnClick
				info.arg1 = data.id
				info.checked = info.arg1 == TMW.CI.ics.PowerType
				TMW.DD:AddButton(info)
			end
		end
	end)

	self:SetHeight(36)
	-- self.PowerType:SetDropdownAnchor("TOPRIGHT", self.PowerType.Middle, "BOTTOMRIGHT")
	self.PowerType:SetPoint("TOPLEFT", 5, -5)
	self.PowerType:SetPoint("RIGHT", -5, 0)

	self:CScriptAdd("ReloadRequested", function()
		for k, v in pairs(types) do
			if v.id == TMW.CI.ics.PowerType then
				self.PowerType:SetText(v.name)
			end
		end
	end)
end)

Type:RegisterConfigPanel_ConstructorFunc(105, "TellMeWhen_ValueCheckSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_VALUEFRAGMENTS"], L["ICONMENU_VALUEFRAGMENTS_DESC"])
			check:SetSetting("ValueFragments")
			check:CScriptAdd("ReloadRequested", function()
				local settings = self:GetSettingTable()
				-- pcall because this function doesn't accept invalid values.
				local success, powerMod = pcall(UnitPowerDisplayMod, settings.PowerType)
				check:SetEnabled(success and powerMod > 1 or false)
			end)
		end,
	})
end)

TMW:RegisterUpgrade(72011, {
	icon = function(self, ics)
		if ics.PowerType == 100 then
			ics.PowerType = SPELL_POWER_COMBO_POINTS
		end
	end,
})



local PowerBarColor = CopyTable(PowerBarColor)
for k, v in pairs(PowerBarColor) do
	v.a = 1
end
PowerBarColor[-1] = {{r=1, g=0, b=0, a=1}, {r=1, g=1, b=0, a=1}, {r=0, g=1, b=0, a=1}}
PowerBarColor[-3] = {{r=0, g=1, b=0, a=1}, {r=1, g=1, b=0, a=1}, {r=1, g=0, b=0, a=1}}

local function Value_OnEvent(icon, event, arg1, arg2)
	if event == icon.UnitSet.event then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	elseif arg2 == "COMBO_POINTS" or icon.UnitSet.UnitsLookup[arg1] then
		-- COMBO_POINTS fires for the player, but the unit being checked by the icon
		-- will almost always be "target" (https://github.com/ascott18/TellMeWhen/issues/1918)
		icon.NextUpdateTime = 0
	end
end

local function Value_OnUpdate(icon, time)
	local PowerType = icon.PowerType
	local ValueFragments = icon.ValueFragments
	local Units = icon.Units

	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		if icon.UnitSet:UnitExists(unit) then

			local value, maxValue, valueColor
			if PowerType == -1 then
				value, maxValue, valueColor = UnitHealth(unit), UnitHealthMax(unit), PowerBarColor[PowerType]
			elseif PowerType == -3 then
				value, maxValue, valueColor = UnitStagger(unit) or 0, UnitHealthMax(unit), PowerBarColor[PowerType]
			elseif not TMW.isRetail and PowerType == Enum.PowerType.ComboPoints then
				-- combo points
				value, maxValue, valueColor = GetComboPoints("player", unit), MAX_COMBO_POINTS, PowerBarColor[PowerType]
			else
				if PowerType == -2 then
					PowerType = UnitPowerType(unit)
				end
				if PowerType == Enum.PowerType.ComboPoints then
					unit = "player"
				end
				
				value, maxValue, valueColor = UnitPower(unit, PowerType, ValueFragments), UnitPowerMax(unit, PowerType, ValueFragments), PowerBarColor[PowerType]

				if ValueFragments then
					local mod = UnitPowerDisplayMod(PowerType)
					value = value / mod
					maxValue = maxValue / mod
				end
			end

			if not icon:YieldInfo(true, unit, value, maxValue, valueColor) then
				return
			end
		end
	end

	icon:YieldInfo(false)
end

function Type:HandleYieldedInfo(icon, iconToSet, unit, value, maxValue, valueColor)
	if unit then
		iconToSet:SetInfo("state; value, maxValue, valueColor; unit, GUID",
			STATE_UNITFOUND,
			value, maxValue, valueColor,
			unit, nil
		)
	else
		iconToSet:SetInfo("state; value, maxValue, valueColor; unit, GUID",
			STATE_NOUNIT,
			0, 0, nil,
			nil, nil
		)
	end
end


function Type:Setup(icon)
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	icon:SetInfo("texture", "Interface/Icons/inv_potion_49")
	
	icon:SetUpdateMethod("auto")

	-- Event-based updates for this icon type are 
	-- at best a net equal to interval updates.
	-- Event-based updates have the added downside of
	-- not being quite as responsive to rapidly-changing values.

	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		icon:SetScript("OnEvent", Value_OnEvent)
		
		if icon.PowerType == -3 then
			icon:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
			icon:RegisterEvent("UNIT_MAXHEALTH")
		elseif icon.PowerType == -1 then
			icon:RegisterEvent(not TMW.isRetail and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH")
			icon:RegisterEvent("UNIT_MAXHEALTH")
		elseif icon.PowerType == -2 then
			icon:RegisterEvent("UNIT_POWER_FREQUENT")
			icon:RegisterEvent("UNIT_MAXPOWER")
			icon:RegisterEvent("UNIT_DISPLAYPOWER")
		else
			icon:RegisterEvent("UNIT_POWER_FREQUENT")
			icon:RegisterEvent("UNIT_MAXPOWER")
		end
	
		icon:RegisterEvent(icon.UnitSet.event)
	end
	
	icon:SetUpdateFunction(Value_OnUpdate)
	
	
	icon:Update()
end

Type:Register(157)

