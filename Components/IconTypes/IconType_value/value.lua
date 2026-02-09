-- --------------------
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
local clientHasSecrets = TMW.clientHasSecrets
local UnitPower, UnitPowerMax, UnitPowerType, UnitPowerDisplayMod, GetComboPoints, MAX_COMBO_POINTS
    = UnitPower, UnitPowerMax, UnitPowerType, UnitPowerDisplayMod, GetComboPoints, MAX_COMBO_POINTS

local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent

local pairs
	= pairs  
	
local _, pclass = UnitClass("Player")
local GetSpellTexture = TMW.GetSpellTexture

local getHealthCurveFunc = TMW:MakeSingleArgFunctionCached(function(unit)
	return function(curve)
		return UnitHealthPercent(unit, true, curve)
	end
end)

local getPowerCurveFunc = TMW:MakeNArgFunctionCached(2, function(unit, powerType)
	return function(curve)
		return UnitPowerPercent(unit, powerType, true, curve)
	end
end)

-- Helper to create a step curve with three zones for value thresholds
local CreateCurve = C_CurveUtil and C_CurveUtil.CreateCurve
local CreateColorCurve = C_CurveUtil and C_CurveUtil.CreateColorCurve

local function createThreeZoneCurve(CreateCurve, minPct, maxPct, lowVal, okVal, highVal)
	local curve = CreateCurve()
	curve:SetType(Enum.LuaCurveType.Step)
	curve:AddPoint(0, lowVal)
	curve:AddPoint(minPct, okVal)
	curve:AddPoint(maxPct + 0.0001, highVal) -- Epsilon added so this acts as `>` and not `>=`.
	return curve
end

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
local STATE_VALUE_LOW = 10
local STATE_VALUE_HIGH = 11

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

	-- Threshold for when the value is considered "low"
	ValuePctMin       = 30,
	ValuePctMinEnabled = false,

	-- Threshold for when the value is considered "high"
	ValuePctMax       = 70,
	ValuePctMaxEnabled = false,
}



Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_VALUE_HIGH] = {
		text = function()
			return "|cFFFFFF00" .. L["ICONMENU_VALUE_HIGH"]:format(TMW.CI.ics.ValuePctMax)
		end,
		requires = "ValuePctMaxEnabled",
		order = 1
	},
	[STATE_VALUE_LOW] = {
		text = function()
			return "|cFFFFFF00" .. L["ICONMENU_VALUE_LOW"]:format(TMW.CI.ics.ValuePctMin)
		end,
		requires = "ValuePctMinEnabled",
		order = 2
	},
	[STATE_UNITFOUND]  = { text = "|cFF00FF00" .. L["ICONMENU_VALUE_HASUNIT"], order = 3 },
	[STATE_NOUNIT]     = { text = "|cFFFF0000" .. L["ICONMENU_VALUE_NOUNIT"], order = 4 },
})

Type:RegisterConfigPanel_ConstructorFunc(100, "TellMeWhen_ValueSettings", function(self)
	self:SetTitle(L["ICONMENU_VALUE_POWERTYPE"])

	local types = {
		{ order = -3, id = -2, name = L["CONDITIONPANEL_POWER"], },
		{ order = -2, id = -4, name = L["CONDITIONPANEL_CLASS_POWER"], },
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

	if ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) then
		types[#types+1] = { order = 7,  id = Enum.PowerType.SoulShards, name = SOUL_SHARDS_POWER, }
		types[#types+1] = { order = 8,  id = Enum.PowerType.HolyPower, name = HOLY_POWER, }
		types[#types+1] = { order = 16,  id = Enum.PowerType.Alternate, name = L["CONDITIONPANEL_ALTPOWER"], }
	end
	
	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		types[#types+1] = { order = 9,  id = Enum.PowerType.Chi, name = CHI_POWER; }
	end

	-- Shadow Orbs: Cataclysm through Warlords
	if ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) 
	and ClassicExpansionAtMost(LE_EXPANSION_WARLORDS_OF_DRAENOR) then
		types[#types+1] = { order = 21, id = Enum.PowerType.ShadowOrbs,   name = SHADOW_ORBS }
	end

	-- Burning Embers & Demonic Fury: MoP through Warlords
	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) 
	and ClassicExpansionAtMost(LE_EXPANSION_WARLORDS_OF_DRAENOR) then
		types[#types+1] = { order = 22, id = Enum.PowerType.DemonicFury,   name = DEMONIC_FURY }
		types[#types+1] = { order = 23, id = Enum.PowerType.BurningEmbers, name = BURNING_EMBERS }
	end

	if ClassicExpansionAtLeast(LE_EXPANSION_LEGION) then
		types[#types+1] = { order = 10,  id = Enum.PowerType.Maelstrom, name = MAELSTROM_POWER, }
		types[#types+1] = { order = 11,  id = Enum.PowerType.ArcaneCharges, name = ARCANE_CHARGES_POWER, }
		types[#types+1] = { order = 12,  id = Enum.PowerType.LunarPower, name = LUNAR_POWER, }
		types[#types+1] = { order = 13,  id = Enum.PowerType.Insanity, name = INSANITY_POWER, }
		types[#types+1] = { order = 14,  id = Enum.PowerType.Fury, name = FURY, }
		types[#types+1] = { order = 15,  id = Enum.PowerType.Pain, name = PAIN, }
	end

	if ClassicExpansionAtLeast(LE_EXPANSION_DRAGONFLIGHT) then
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
			if data.id == 0 then
				TMW.DD:AddSpacer()
			end
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
	self.ValueFragments:ClearAllPoints()
	self.ValueFragments:SetPoint("TOPLEFT", self.PowerType, "BOTTOMLEFT", 0, -2)

	self:AdjustHeight(-5)
end)

Type:RegisterConfigPanel_XMLTemplate(107, "TellMeWhen_ValuePcts")

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
PowerBarColor[Enum.PowerType.ArcaneCharges] = PowerBarColor["ARCANE_CHARGES"]
-- Better mana color from Blizzard_ClassNameplateBar
PowerBarColor[Enum.PowerType.Mana] = { r = 0.1, g = 0.25, b = 1.00, a = 1 }


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

local comboPointsPerTarget = ClassicExpansionAtMost(LE_EXPANSION_MISTS_OF_PANDARIA)

local function Value_OnUpdate(icon, time)
	local PowerType = icon.PowerType
	local ValueFragments = icon.ValueFragments
	local Units = icon.Units

	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		if icon.UnitSet:UnitExists(unit) then

			local value, maxValue, valueColor, valueCurveFunc
			if PowerType == -1 then
				value, maxValue, valueColor = UnitHealth(unit), UnitHealthMax(unit), PowerBarColor[PowerType]
				if clientHasSecrets then
					valueCurveFunc = getHealthCurveFunc(unit)
				end
			elseif PowerType == -3 then
				value, maxValue, valueColor = UnitStagger(unit) or 0, UnitHealthMax(unit), PowerBarColor[PowerType]
			elseif comboPointsPerTarget and PowerType == Enum.PowerType.ComboPoints then
				-- combo points
				value, maxValue, valueColor = GetComboPoints("player", unit), MAX_COMBO_POINTS, PowerBarColor[PowerType]
			else
				local pt = PowerType
				if pt == -2 then
					pt = UnitPowerType(unit)
				end
				if pt == Enum.PowerType.ComboPoints then
					unit = "player"
				end
				
				value, maxValue, valueColor = UnitPower(unit, pt, ValueFragments), UnitPowerMax(unit, pt, ValueFragments), PowerBarColor[pt]

				if ValueFragments then
					local mod = UnitPowerDisplayMod(pt)
					value = value / mod
					maxValue = maxValue / mod
				end

				if clientHasSecrets then
					valueCurveFunc = getPowerCurveFunc(unit, pt)
				end
			end

			if not icon:YieldInfo(true, unit, value, maxValue, valueColor, valueCurveFunc) then
				return
			end
		end
	end

	icon:YieldInfo(false)
end

function Type:HandleYieldedInfo(icon, iconToSet, unit, value, maxValue, valueColor, valueCurveFunc)
	if unit then
		local state = STATE_UNITFOUND

		local minEnabled = icon.ValuePctMinEnabled
		local maxEnabled = icon.ValuePctMaxEnabled
		if minEnabled or maxEnabled then
			if valueCurveFunc then
				-- Secret values: evaluate pre-created curves, storing results in state
				state = {
					valueThresholdState = true,
					Alpha = valueCurveFunc(icon.thresholdAlphaCurve),
					Color = valueCurveFunc(icon.thresholdColorCurve),
					Desaturation = valueCurveFunc(icon.thresholdDesatCurve),
				}
			else
				-- Non-secret values: we can do direct comparison
				local pct = maxValue > 0 and (value / maxValue) or 0
				local minPct = minEnabled and (icon.ValuePctMin / 100) or 0
				local maxPct = maxEnabled and (icon.ValuePctMax / 100) or 1

				if minEnabled and pct < minPct then
					state = STATE_VALUE_LOW
				elseif maxEnabled and pct > maxPct then
					state = STATE_VALUE_HIGH
				end
			end
		end

		iconToSet:SetInfo("state; value, maxValue, valueColor, valueCurveFunc; unit, GUID",
			state,
			value, maxValue, valueColor, valueCurveFunc,
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

	icon:SetInfo("texture; reverse", "Interface/Icons/inv_potion_49", true)

	icon.thresholdAlphaCurve = nil
	icon.thresholdColorCurve = nil
	icon.thresholdDesatCurve = nil
	
	local minEnabled = icon.ValuePctMinEnabled
	local maxEnabled = icon.ValuePctMaxEnabled
	if (minEnabled or maxEnabled) and clientHasSecrets then
		local minPct = minEnabled and (icon.ValuePctMin / 100) or 0
		local maxPct = maxEnabled and (icon.ValuePctMax / 100) or 1

		local lowState = icon.States[minEnabled and STATE_VALUE_LOW or STATE_UNITFOUND]
		local okState = icon.States[STATE_UNITFOUND]
		local highState = icon.States[maxEnabled and STATE_VALUE_HIGH or STATE_UNITFOUND]

		icon.thresholdAlphaCurve = createThreeZoneCurve(CreateCurve, minPct, maxPct, lowState.Alpha, okState.Alpha, highState.Alpha)

		local lowColor = TMW:StringToCachedColorMixin(lowState.Color)
		local okColor = TMW:StringToCachedColorMixin(okState.Color)
		local highColor = TMW:StringToCachedColorMixin(highState.Color)
		icon.thresholdColorCurve = createThreeZoneCurve(CreateColorCurve, minPct, maxPct, lowColor, okColor, highColor)

		icon.thresholdDesatCurve = createThreeZoneCurve(CreateCurve, minPct, maxPct,
			lowColor.flags.desaturate and 1 or 0,
			okColor.flags.desaturate and 1 or 0,
			highColor.flags.desaturate and 1 or 0
		)
	end

	if icon.PowerType == -4 then
		if ClassicExpansionAtLeast(LE_EXPANSION_LEGION) and pclass == "MAGE" and TMW.GetCurrentSpecialization() == SPEC_MAGE_ARCANE then
			icon.PowerType = Enum.PowerType.ArcaneCharges
		elseif pclass == "MONK" and TMW.GetCurrentSpecialization() == SPEC_MONK_WINDWALKER then
			icon.PowerType = Enum.PowerType.Chi
		else
			local ClassPowers = {
				PALADIN = ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) and Enum.PowerType.HolyPower,
				WARLOCK = ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) and Enum.PowerType.SoulShards,
				EVOKER = Enum.PowerType.Essence,
			}
			icon.PowerType = ClassPowers[pclass] or -2
		end
	end
	
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
			icon:RegisterEvent(ClassicExpansionAtLeast(LE_EXPANSION_SHADOWLANDS) and "UNIT_HEALTH" or "UNIT_HEALTH_FREQUENT")
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

