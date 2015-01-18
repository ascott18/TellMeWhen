-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local GetSpellInfo, GetSpellCooldown, GetSpellCharges, GetSpellCount, IsUsableSpell =
	  GetSpellInfo, GetSpellCooldown, GetSpellCharges, GetSpellCount, IsUsableSpell
local UnitRangedDamage =
	  UnitRangedDamage
local pairs, wipe, strlower =
	  pairs, wipe, strlower

local OnGCD = TMW.OnGCD
local SpellHasNoMana = TMW.SpellHasNoMana
local GetSpellTexture = TMW.GetSpellTexture

local _, pclass = UnitClass("Player")

local IsSpellInRange = LibStub("SpellRange-1.0").IsSpellInRange



local Type = TMW.Classes.IconType:New("cooldown")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_SPELLCOOLDOWN"]
Type.desc = L["ICONMENU_SPELLCOOLDOWN_DESC"]
Type.menuIcon = "Interface\\Icons\\spell_holy_divineintervention"


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("charges, maxCharges")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("noMana")
Type:UsesAttributes("inRange")
Type:UsesAttributes("reverse")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)



Type:RegisterIconDefaults{
	-- True to cause the icon to act as unusable when the ability is out of range.
	RangeCheck				= false,

	-- True to cause the icon to act as unusable when the ability lacks power to be used.
	ManaCheck				= false,

	-- True to prevent rune cooldowns from causing the ability to be deemed unusable.
	IgnoreRunes				= false,
}

TMW:RegisterUpgrade(72022, {
	icon = function(self, ics)
		-- Multistate cooldown icon type has been removed (no longer needed)
		if ics.Type == "multistate" then
			ics.Type = "cooldown"
			ics.IgnoreRunes = false -- mscd icons didnt have this setting. Make sure it is disabled.
			ics.wasmscd = true -- flag this so we can undo this change if we need to. TODO: remove this flag from all icons when we're sure this is an OK change.
			-- also TODO: remove static formats and localization strings for things that were used for mscd.
		end
	end,
})


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	text = L["CHOOSENAME_DIALOG"] .. "\r\n\r\n" .. L["CHOOSENAME_DIALOG_PETABILITIES"],
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"],			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"],		},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_CooldownSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "RangeCheck",
			title = L["ICONMENU_RANGECHECK"],
			tooltip = L["ICONMENU_RANGECHECK_DESC"],
		},
		{
			setting = "ManaCheck",
			title = L["ICONMENU_MANACHECK"],
			tooltip = L["ICONMENU_MANACHECK_DESC"],
		},
		pclass == "DEATHKNIGHT" and {
			setting = "IgnoreRunes",
			title = L["ICONMENU_IGNORERUNES"],
			tooltip = L["ICONMENU_IGNORERUNES_DESC"],
		},
	})
end)



local function AutoShot_OnEvent(icon, event, unit, _, _, _, spellID)
	if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" and spellID == 75 then
		-- When an autoshot happens, set the timer for the next one.

		icon.asStart = TMW.time
		-- The first return of UnitRangedDamage() is ranged attack speed.
		icon.asDuration = UnitRangedDamage("player")
		icon.NextUpdateTime = 0
	end
end

local function AutoShot_OnUpdate(icon, time)

	local NameString = icon.Spells.FirstString
	local asDuration = icon.asDuration

	local ready = time - icon.asStart > asDuration
	local inrange = true
	if icon.RangeCheck then
		inrange = IsSpellInRange(NameString, "target")
		if inrange == 1 or inrange == nil then
			inrange = true
		else
			inrange = false
		end
	end

	if ready and inrange then
		icon:SetInfo(
			"alpha; start, duration; spell; inRange",
			icon.Alpha,
			0, 0,
			NameString,
			inrange
		)
	else
		icon:SetInfo(
			"alpha; start, duration; spell; inRange",
			icon.UnAlpha,
			icon.asStart, asDuration,
			NameString,
			inrange
		)
	end
end


local usableData = {}
local unusableData = {}
local function SpellCooldown_OnUpdate(icon, time)    
	-- Upvalue things that will be referenced a lot in our loops.
	local IgnoreRunes, RangeCheck, ManaCheck, NameArray, NameStringArray =
	icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.Spells.Array, icon.Spells.StringArray

	local usableFound, unusableFound

	for i = 1, #NameArray do
		local iName = NameArray[i]
		
		local start, duration, stack
		
		local charges, maxCharges, start_charge, duration_charge = GetSpellCharges(iName)
		if charges then
			if charges < maxCharges then
				-- If the ability has charges and isn't at max charges, 
				-- the timer on the icon should be the time until the next charge is gained.
				start, duration = start_charge, duration_charge
			else
				start, duration = GetSpellCooldown(iName)
			end
			stack = charges
		else
			start, duration = GetSpellCooldown(iName)
			stack = GetSpellCount(iName)
		end
		
		if duration then
			if IgnoreRunes and duration == 10 then
				-- DK abilities that are on cooldown because of runes are always reported
				-- as having a cooldown duration of 10 seconds. We use this fact to filter out rune cooldowns.
				-- We used to have to make sure the ability being checked wasn't Mind Freeze before doing this,
				-- but Mind Freeze has a 15 second cooldown now (instead of 10), so we don't have to worry.
				start, duration = 0, 0
			end

			local inrange, nomana = true, nil
			if RangeCheck then
				inrange = IsSpellInRange(iName, "target")
				if inrange == 1 or inrange == nil then
					inrange = true
				else
					inrange = false
				end
			end
			if ManaCheck then
				nomana = SpellHasNoMana(iName)
			end
			

			-- We store all our data in tables here because we need to keep track of both the first
			-- usable cooldown and the first unusable cooldown found. We can't always determine which we will
			-- use until we've found one of each. 
			if inrange and not nomana and (duration == 0 or (charges and charges > 0) or OnGCD(duration)) then --usable
				if not usableFound then
					wipe(usableData)
					usableData.alpha = icon.Alpha
					usableData.tex = GetSpellTexture(iName)
					usableData.inrange = inrange
					usableData.nomana = nomana
					usableData.iName = iName
					usableData.stack = stack
					usableData.charges = charges
					usableData.maxCharges = maxCharges
					usableData.start = start
					usableData.duration = duration
					
					usableFound = true
					
					if icon.Alpha > 0 then
						break
					end
				end
			elseif not unusableFound then
				wipe(unusableData)
				unusableData.alpha = icon.UnAlpha
				unusableData.tex = GetSpellTexture(iName)
				unusableData.inrange = inrange
				unusableData.nomana = nomana
				unusableData.iName = iName
				unusableData.stack = stack
				unusableData.charges = charges
				unusableData.maxCharges = maxCharges
				unusableData.start = start
				unusableData.duration = duration
				
				unusableFound = true
				
				if icon.Alpha == 0 then
					break
				end
			end
		end
	end
	
	local dataToUse
	if usableFound and icon.Alpha > 0 then
		dataToUse = usableData
	elseif unusableFound then
		dataToUse = unusableData
	end
	
	if dataToUse then
		icon:SetInfo(
			"alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell; inRange; noMana",
			dataToUse.alpha,
			dataToUse.tex,
			dataToUse.start, dataToUse.duration,
			dataToUse.charges, dataToUse.maxCharges,
			dataToUse.stack, dataToUse.stack,
			dataToUse.iName,
			dataToUse.inrange,
			dataToUse.nomana
		)
	else
		icon:SetInfo("alpha", 0)
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, true)
	
	if pclass ~= "DEATHKNIGHT" then
		icon.IgnoreRunes =  nil
	end
	
	if icon.Spells.FirstString == strlower(GetSpellInfo(75)) and not icon.Spells.Array[2] then
		-- Auto shot needs special handling - it isn't a regular cooldown, so it gets its own update function.
		icon:SetInfo("texture", GetSpellTexture(75))
		icon.asStart = icon.asStart or 0
		icon.asDuration = icon.asDuration or 0
		
		if not icon.RangeCheck then
			icon:SetUpdateMethod("manual")
		end
		
		icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		icon:SetScript("OnEvent", AutoShot_OnEvent)
		
		icon:SetUpdateFunction(AutoShot_OnUpdate)
	else
		icon.FirstTexture = GetSpellTexture(icon.Spells.First)
		
		icon:SetInfo("texture; reverse; spell", Type:GetConfigIconTexture(icon), false, icon.Spells.First)
		
		
		if not icon.RangeCheck then
			-- There are no events for when you become in range/out of range for a spell

			icon:RegisterSimpleUpdateEvent("SPELL_UPDATE_COOLDOWN")
			icon:RegisterSimpleUpdateEvent("SPELL_UPDATE_USABLE")
			icon:RegisterSimpleUpdateEvent("SPELL_UPDATE_CHARGES")
			if icon.IgnoreRunes then
				icon:RegisterSimpleUpdateEvent("RUNE_POWER_UPDATE")
				icon:RegisterSimpleUpdateEvent("RUNE_TYPE_UPDATE")
			end    
			if icon.ManaCheck then
				icon:RegisterSimpleUpdateEvent("UNIT_POWER_FREQUENT", "player")
				-- icon:RegisterSimpleUpdateEvent("SPELL_UPDATE_USABLE")-- already registered
			end
			
			icon:SetUpdateMethod("manual")
		end
		
		icon:SetUpdateFunction(SpellCooldown_OnUpdate)
	end
	
	icon:Update()
end


Type:Register(10)

