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
local UnitRangedDamage =
	  UnitRangedDamage
local pairs, wipe, strlower =
	  pairs, wipe, strlower

local OnGCD = TMW.OnGCD
local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName
local GetSpellTexture = TMW.GetSpellTexture
local spellTextureCache = TMW.spellTextureCache
local IsUsableSpell = TMW.COMMON.SpellUsable.IsUsableSpell
local GetSpellCharges = TMW.COMMON.Cooldowns.GetSpellCharges
local GetSpellCooldown = TMW.COMMON.Cooldowns.GetSpellCooldown
local GetSpellCastCount = TMW.COMMON.Cooldowns.GetSpellCastCount
local GetRuneCooldownDuration = TMW.GetRuneCooldownDuration

local _, pclass = UnitClass("Player")

local IsSpellInRange = TMW.COMMON.SpellRange.IsSpellInRange


local Type = TMW.Classes.IconType:New("cooldown")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_SPELLCOOLDOWN"]
Type.desc = L["ICONMENU_SPELLCOOLDOWN_DESC"]
Type.menuIcon = "Interface\\Icons\\spell_holy_divineintervention"

local STATE_USABLE           = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_UNUSABLE         = TMW.CONST.STATE.DEFAULT_HIDE
local STATE_UNUSABLE_NORANGE = TMW.CONST.STATE.DEFAULT_NORANGE
local STATE_UNUSABLE_NOMANA  = TMW.CONST.STATE.DEFAULT_NOMANA

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("spell")
Type:UsesAttributes("charges, maxCharges, chargeStart, chargeDur")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)



Type:RegisterIconDefaults{
	-- True to cause the icon to act as unusable when the ability is out of range.
	RangeCheck				= false,

	-- True to cause the icon to act as unusable when the ability lacks power to be used.
	ManaCheck				= false,

	-- True to treat the spell as unusable if it is on the GCD.
	GCDAsUnusable			= false,

	-- True to prevent rune cooldowns from causing the ability to be deemed unusable.
	IgnoreRunes				= false,
}

TMW:RegisterUpgrade(80004, {
	icon = function(self, ics)
		-- Multistate cooldown icon type has been removed (no longer needed)
		-- We added a flag to icon settings that used to be multistate cooldowns in case an emergency rollback was needed.
		-- It never ended up being needed, so now we can remove this flag.
		ics.wasmscd = nil
	end,
})
TMW:RegisterUpgrade(72022, {
	icon = function(self, ics)
		-- Multistate cooldown icon type has been removed (no longer needed)
		if ics.Type == "multistate" then
			ics.Type = "cooldown"
			ics.IgnoreRunes = false -- mscd icons didnt have this setting. Make sure it is disabled.
		end
	end,
})


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	text = L["CHOOSENAME_DIALOG"] .. "\r\n\r\n" .. L["CHOOSENAME_DIALOG_PETABILITIES"],
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_USABLE]           = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], order = 3, },
	[STATE_UNUSABLE]         = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], order = 4, },
	[STATE_UNUSABLE_NORANGE] = { text = "|cFFFFff00" .. L["ICONMENU_OORANGE"], requires = "RangeCheck", order = 1 },
	[STATE_UNUSABLE_NOMANA]  = { text = "|cFFFFff00" .. L["ICONMENU_OOPOWER"], requires = "ManaCheck", order = 2 },
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_CooldownSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_RANGECHECK"], L["ICONMENU_RANGECHECK_DESC"])
			check:SetSetting("RangeCheck")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_MANACHECK"], L["ICONMENU_MANACHECK_DESC"])
			check:SetSetting("ManaCheck")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_GCDASUNUSABLE"], L["ICONMENU_GCDASUNUSABLE_DESC"])
			check:SetSetting("GCDAsUnusable")
		end,
		pclass == "DEATHKNIGHT" and function(check)
			check:SetTexts(L["ICONMENU_IGNORERUNES"], L["ICONMENU_IGNORERUNES_DESC"])
			check:SetSetting("IgnoreRunes")
		end,
	})
end)



local function AutoShot_OnEvent(icon, event, unit, _, spellID)
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
		if inrange == nil then
			inrange = true
		end
	end

	if ready and inrange then
		icon:SetInfo(
			"state; start, duration; spell",
			STATE_USABLE,
			0, 0,
			NameString
		)
	else
		icon:SetInfo(
			"state; start, duration; spell",
			not inrange and STATE_UNUSABLE_NORANGE or STATE_UNUSABLE,
			icon.asStart, asDuration,
			NameString
		)
	end
end

local function SpellCooldown_OnEvent(icon, event, payload) 
	if event == "TMW_SPELL_UPDATE_USABLE" then
		if not payload then
			icon.NextUpdateTime = 0
		else
			for _, spell in pairs(icon.Spells.Array) do
				if payload[spell] then
					icon.NextUpdateTime = 0
					return
				end
			end
		end
	end
end

local _
local emptyTable = {}
local offCooldown = { startTime = 0, duration = 0 }
local usableData = {}
local unusableData = {}
local mindfreeze = GetSpellName(47528) and strlower(GetSpellName(47528))
local function SpellCooldown_OnUpdate(icon, time)    
	-- Upvalue things that will be referenced a lot in our loops.
	local IgnoreRunes, RangeCheck, ManaCheck, GCDAsUnusable, NameArray =
	icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.GCDAsUnusable, icon.Spells.Array

	local usableAlpha = icon.States[STATE_USABLE].Alpha
	local runeCD = IgnoreRunes and GetRuneCooldownDuration()

	local usableFound, unusableFound

	for i = 1, #NameArray do
		local iName = NameArray[i]
		
		local cooldown = GetSpellCooldown(iName)
		local charges = GetSpellCharges(iName)
		local stack = charges and charges.currentCharges or GetSpellCastCount(iName)

		
		if cooldown then
			local duration = cooldown.duration
			if IgnoreRunes and duration == runeCD and iName ~= mindfreeze and iName ~= 47528  then
				-- DK abilities that are on cooldown because of runes are always reported
				-- as having a cooldown duration of 10 seconds. We use this fact to filter out rune cooldowns.
				
				-- In Wrath, mind Freeze has an actual CD of 10 seconds though, and doesn't cost runes,
				-- so it is excluded from this logic.
				cooldown = offCooldown
				duration = 0
			end

			local inrange, noMana = true, nil
			if RangeCheck then
				inrange = IsSpellInRange(iName, "target")
				if inrange == nil then
					inrange = true
				end
			end
			if ManaCheck then
				_, noMana = IsUsableSpell(iName)
			end
			

			-- We store all our data in tables here because we need to keep track of both the first
			-- usable cooldown and the first unusable cooldown found. We can't always determine which we will
			-- use until we've found one of each. 
			if
				inrange and not noMana and (
					-- If the cooldown duration is 0 and there arent charges, then its usable
					(duration == 0 and not charges)
					-- If the spell has charges and they aren't all depeleted, its usable
					or (charges and charges.currentCharges > 0)
					-- If we're just on a GCD, its usable
					or (not GCDAsUnusable and OnGCD(duration))
				)
			then --usable
				if not usableFound then
					--wipe(usableData)
					usableData.state = STATE_USABLE
					usableData.iName = iName
					usableData.stack = stack
					usableData.charges = charges or emptyTable
					usableData.cooldown = cooldown
					
					usableFound = true
					
					if usableAlpha > 0 then
						break
					end
				end
			elseif not unusableFound then
				--wipe(unusableData)
				unusableData.state = 
					not inrange and STATE_UNUSABLE_NORANGE or 
					noMana and STATE_UNUSABLE_NOMANA or 
					STATE_UNUSABLE
				unusableData.iName = iName
				unusableData.stack = stack
				unusableData.charges = charges or emptyTable
				unusableData.cooldown = cooldown
				
				unusableFound = true
				
				if usableAlpha == 0 then
					break
				end
			end
		end
	end
	
	local dataToUse
	if usableFound and usableAlpha > 0 then
		dataToUse = usableData
	elseif unusableFound then
		dataToUse = unusableData
	elseif usableFound then
		dataToUse = usableData
	end
	
	if dataToUse then
		local cooldown = dataToUse.cooldown
		local charges = dataToUse.charges
		icon:SetInfo(
			"state; texture; start, duration, modRate; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
			dataToUse.state,
			spellTextureCache[dataToUse.iName],
			cooldown.startTime, cooldown.duration, cooldown.modRate,
			charges.currentCharges, charges.maxCharges, charges.cooldownStartTime, charges.cooldownDuration,
			dataToUse.stack, dataToUse.stack,
			dataToUse.iName
		)
	else
		icon:SetInfo("state", 0)
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, true)
	
	if pclass ~= "DEATHKNIGHT" then
		icon.IgnoreRunes =  nil
	end
	
	if icon.Spells.FirstString == strlower(GetSpellName(75)) and not icon.Spells.Array[2] then
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
		icon:Update()
		
		return
	end

	icon.FirstTexture = GetSpellTexture(icon.Spells.First)
	
	icon:SetInfo("texture; reverse; spell", Type:GetConfigIconTexture(icon), false, icon.Spells.First)
	
	local isManual = true
	if icon.RangeCheck then
		for _, spell in pairs(icon.Spells.Array) do
			if not TMW.COMMON.SpellRange.HasRangeEvents(spell) then
				isManual = false
				break
			end
		end
	end
	
	if isManual then
		local hasActionEvent = true
		for _, spell in pairs(icon.Spells.Array) do
			if not TMW.COMMON.Actions.GetActionsForSpell(spell) then
				hasActionEvent = false
				break
			end
		end

		icon:SetScript("OnEvent", SpellCooldown_OnEvent)
		
		icon:RegisterSimpleUpdateEvent("TMW_SPELL_UPDATE_COOLDOWN")
		icon:RegisterSimpleUpdateEvent("TMW_SPELL_UPDATE_CHARGES")
		if icon.RangeCheck then
			icon:RegisterSimpleUpdateEvent("TMW_SPELL_UPDATE_RANGE")
		end
		if icon.IgnoreRunes then
			if GetRuneType then
				icon:RegisterSimpleUpdateEvent("RUNE_TYPE_UPDATE")
			end
			icon:RegisterSimpleUpdateEvent("RUNE_POWER_UPDATE")
		end    
		if icon.ManaCheck then
			icon:RegisterEvent("TMW_SPELL_UPDATE_USABLE")
		end
		
		icon:SetUpdateMethod("manual")
	end
	
	icon:SetUpdateFunction(SpellCooldown_OnUpdate)
	icon:Update()
end


Type:Register(10)

