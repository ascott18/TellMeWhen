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

local _, pclass = UnitClass("player")

local print = TMW.print

local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName
local GetSpellTexture = TMW.GetSpellTexture
local GetSpellCharges = TMW.COMMON.Cooldowns.GetSpellCharges
local GetSpellCooldown = TMW.COMMON.Cooldowns.GetSpellCooldown
local GetSpellCastCount = TMW.COMMON.Cooldowns.GetSpellCastCount
local IsUsableSpell = TMW.COMMON.SpellUsable.IsUsableSpell

local spellTextureCache = TMW.spellTextureCache
local strlowerCache = TMW.strlowerCache
local OnGCD = TMW.OnGCD
local GetRuneCooldownDuration = TMW.GetRuneCooldownDuration

local SpellRange = TMW.COMMON.SpellRange
local IsSpellInRange = SpellRange.IsSpellInRange

local Type = TMW.Classes.IconType:New("reactive")
Type.name = L["ICONMENU_REACTIVE"]
Type.desc = L["ICONMENU_REACTIVE_DESC"]
Type.menuIcon = "Interface\\Icons\\ability_warrior_revenge"

local STATE_USABLE           = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_UNUSABLE         = TMW.CONST.STATE.DEFAULT_HIDE
local STATE_UNUSABLE_NORANGE = TMW.CONST.STATE.DEFAULT_NORANGE
local STATE_UNUSABLE_NOMANA  = TMW.CONST.STATE.DEFAULT_NOMANA

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("spell")
Type:UsesAttributes("charges, maxCharges, chargeStart, chargeDur")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)




Type:RegisterIconDefaults{
	-- Cause an ability to be treated as reactive if there is an activation border on it on the action bars.
	UseActvtnOverlay		= false,

	-- Cause an ability to be treated as reactive ONLY IF there is an activation border on it on the action bars.
	OnlyActvtnOverlay		= false,

	-- Cause the avility to be considered unusable of it is on cooldown.
	CooldownCheck			= false,

	-- Don't treat the ability as unusable if there is only a lack of power to use it.
	IgnoreNomana			= false,

	-- True to prevent rune cooldowns from causing the ability to be deemed unusable.
	IgnoreRunes				= false,

	-- True to cause the icon to act as unusable when the ability is out of range.
	RangeCheck				= false,

	-- True to cause the icon to act as unusable when the ability lacks power to be used.
	ManaCheck				= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	text = L["CHOOSENAME_DIALOG"] .. "\r\n\r\n" .. L["CHOOSENAME_DIALOG_PETABILITIES"],
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_USABLE]           = { text = "|cFF00FF00" .. L["ICONMENU_READY"],   },
	[STATE_UNUSABLE]         = { text = "|cFFFF0000" .. L["ICONMENU_NOTREADY"], },
	[STATE_UNUSABLE_NORANGE] = { text = "|cFFFFff00" .. L["ICONMENU_OORANGE"], requires = "RangeCheck" },
	[STATE_UNUSABLE_NOMANA]  = { text = "|cFFFFff00" .. L["ICONMENU_OOPOWER"], requires = "ManaCheck" },
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_ReactiveSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_USEACTIVATIONOVERLAY"], L["ICONMENU_USEACTIVATIONOVERLAY_DESC"])
			check:SetSetting("UseActvtnOverlay")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_ONLYACTIVATIONOVERLAY"], L["ICONMENU_ONLYACTIVATIONOVERLAY_DESC"])
			check:SetSetting("OnlyActvtnOverlay")
			check:CScriptAdd("ReloadRequested", function()
				check:SetEnabled(TMW.CI.ics.UseActvtnOverlay)
			end)
		end,
		function(check)
			check:SetTexts(L["ICONMENU_IGNORENOMANA"], L["ICONMENU_IGNORENOMANA_DESC"])
			check:SetSetting("IgnoreNomana")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_RANGECHECK"], L["ICONMENU_RANGECHECK_DESC"])
			check:SetSetting("RangeCheck")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_MANACHECK"], L["ICONMENU_MANACHECK_DESC"])
			check:SetSetting("ManaCheck")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_COOLDOWNCHECK"], L["ICONMENU_COOLDOWNCHECK_DESC"])
			check:SetSetting("CooldownCheck")
		end,
		pclass == "DEATHKNIGHT" and function(check)
			check:SetSetting("IgnoreRunes")

			check:CScriptAdd("ReloadRequested", function()
				check:SetEnabled(TMW.CI.ics.CooldownCheck)
				if TMW.CI.ics.CooldownCheck then
					check:SetTexts(L["ICONMENU_IGNORERUNES"], L["ICONMENU_IGNORERUNES_DESC"])
				else
					check:SetTexts(L["ICONMENU_IGNORERUNES"], L["ICONMENU_IGNORERUNES_DESC_DISABLED"])
				end
			end)
		end,
	})
end)


local function Reactive_OnEvent(icon, event, arg1)
	if event == "TMW_SPELL_UPDATE_USABLE" then
		if not arg1 then
			icon.NextUpdateTime = 0
		else
			local NameArray = icon.Spells.Array;
			for _, spell in pairs(NameArray) do
				if arg1[spell] then
					icon.NextUpdateTime = 0
					return
				end
			end
		end

	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"
	    or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE"
	then
		-- If icon.UseActvtnOverlay == true, treat the icon as usable if the spell has an activation overlay glow.
		if icon.Spells.First == arg1 or strlowerCache[GetSpellName(arg1)] == icon.Spells.FirstString then
			icon.activationOverlayActive = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"
			icon.NextUpdateTime = 0
		end
	end
end

local emptyTable = {}
local offCooldown = { startTime = 0, duration = 0 }
local mindfreeze = GetSpellName(47528) and strlower(GetSpellName(47528))
local function Reactive_OnUpdate(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local NameArray, RangeCheck, ManaCheck, CooldownCheck, IgnoreRunes, IgnoreNomana, UseActvtnOverlay, OnlyActvtnOverlay =
	 icon.Spells.Array, icon.RangeCheck, icon.ManaCheck, icon.CooldownCheck, icon.IgnoreRunes, icon.IgnoreNomana, icon.UseActvtnOverlay, icon.OnlyActvtnOverlay

	local activationOverlayActive = icon.activationOverlayActive

	-- These variables will hold all the attributes that we pass to SetInfo().
	local inrange, noMana, cooldown, CD, usable, charges, stack, start_charge, duration_charge

	local numChecked = 1
	local runeCD = IgnoreRunes and GetRuneCooldownDuration()
	

	for i = 1, #NameArray do
		local iName = NameArray[i]
		numChecked = i
		

		cooldown = GetSpellCooldown(iName)
		charges = GetSpellCharges(iName) or emptyTable
		stack = charges and charges.currentCharges or GetSpellCastCount(iName)
		
		if cooldown then
			local duration = cooldown.duration
			inrange, CD = true, nil

			if RangeCheck then
				inrange = IsSpellInRange(iName, "target")
				if inrange == nil then
					inrange = true
				end
			end

			usable, noMana = IsUsableSpell(iName)
			if IgnoreNomana then
				usable = usable or noMana
			end

			if not ManaCheck then
				noMana = nil
			end

			if CooldownCheck then
				if IgnoreRunes and duration == runeCD and iName ~= mindfreeze and iName ~= 47528 then
					-- DK abilities that are on cooldown because of runes are always reported
					-- as having a cooldown duration of 10 seconds. We use this fact to filter out rune cooldowns.
					
					-- In Wrath, mind Freeze has an actual CD of 10 seconds though, and doesn't cost runes,
					-- so it is excluded from this logic.
					cooldown = offCooldown
					duration = 0
				end
				CD = not (duration == 0 or OnGCD(duration))
			end

			if UseActvtnOverlay and OnlyActvtnOverlay then
				usable = activationOverlayActive
			else
				usable = activationOverlayActive or usable
			end
			if usable and not CD and not noMana and inrange then --usable
				icon:SetInfo("state; texture; start, duration, modRate; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
					STATE_USABLE,
					spellTextureCache[iName],
					cooldown.startTime, cooldown.duration, cooldown.modRate,
					charges.currentCharges, charges.maxCharges, charges.cooldownStartTime, charges.cooldownDuration,
					stack, stack,
					iName		
				)
				return
			end
		end
	end

	-- if there is more than 1 spell that was checked
	-- then we need to get these again for the first spell,
	-- otherwise reuse the values obtained above since they are just for the first one
	local NameFirst = icon.Spells.First
	if numChecked > 1 then

		cooldown = GetSpellCooldown(NameFirst)
		charges = GetSpellCharges(NameFirst) or emptyTable
		stack = charges and charges.currentCharges or GetSpellCastCount(NameFirst)

		if IgnoreRunes and (cooldown and cooldown.duration) == runeCD and NameFirst ~= mindfreeze and NameFirst ~= 47528 then
			-- DK abilities that are on cooldown because of runes are always reported
			-- as having a cooldown duration of 10 seconds. We use this fact to filter out rune cooldowns.
			
			-- In Wrath, mind Freeze has an actual CD of 10 seconds though, and doesn't cost runes,
			-- so it is excluded from this logic.
			cooldown = offCooldown
		end

		inrange, noMana = true, nil
		if RangeCheck then
			inrange = IsSpellInRange(NameFirst, "target")
			if inrange == nil then
				inrange = true
			end
		end
		if ManaCheck then
			usable, noMana = IsUsableSpell(NameFirst)
		end
	end
	
	if cooldown then
		icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
			not inrange and STATE_UNUSABLE_NORANGE or noMana and STATE_UNUSABLE_NOMANA or STATE_UNUSABLE,
			icon.FirstTexture,
			cooldown.startTime, cooldown.duration,
			charges.currentCharges, charges.maxCharges, charges.cooldownStartTime, charges.cooldownDuration,
			stack, stack,
			NameFirst
		)
	else
		icon:SetInfo("state", 0)
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, true)

	icon.forceUsable = nil

	icon.FirstTexture = GetSpellTexture(icon.Spells.First)

	icon:SetInfo("texture", Type:GetConfigIconTexture(icon))
	
	if pclass ~= "DEATHKNIGHT" then
		icon.IgnoreRunes = nil
	end
	
	local isManual = true
	if icon.RangeCheck then
		for _, spell in pairs(icon.Spells.Array) do
			if not SpellRange.HasRangeEvents(spell) then
				isManual = false
				break
			end
		end
	end

	-- Register events and setup update functions
	icon:SetScript("OnEvent", Reactive_OnEvent)

	if icon.UseActvtnOverlay then
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	end
	
	if isManual then
		-- Normally we'd need to watch SPELLS_CHANGED to handle updates to `icon.Spells`,
		-- but it gets handled by proxy through TMW_SPELL_UPDATE_USABLE.

		icon:RegisterEvent("TMW_SPELL_UPDATE_USABLE")
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
	
		icon:SetUpdateMethod("manual")
	end
	
	icon:SetUpdateFunction(Reactive_OnUpdate)
	icon:Update()
end

Type:Register(70)
