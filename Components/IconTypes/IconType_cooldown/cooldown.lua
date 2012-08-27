-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local ClockGCD
local GetSpellCooldown, GetSpellCharges, GetSpellCount, IsSpellInRange, IsUsableSpell =
	  GetSpellCooldown, GetSpellCharges, GetSpellCount, IsSpellInRange, IsUsableSpell
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local UnitRangedDamage =
	  UnitRangedDamage
local pairs =
	  pairs
local OnGCD = TMW.OnGCD
local SpellHasNoMana = TMW.SpellHasNoMana
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures
local mindfreeze = strlower(GetSpellInfo(47528))

local Type = TMW.Classes.IconType:New("cooldown")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_SPELLCOOLDOWN"]
Type.desc = L["ICONMENU_SPELLCOOLDOWN_DESC"]


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
	RangeCheck				= false,
	ManaCheck				= false,
	IgnoreRunes				= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	text = L["CHOOSENAME_DIALOG"] .. "\r\n\r\n" .. L["CHOOSENAME_DIALOG_PETABILITIES"],
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 		},
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


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ClockGCD = TMW.db.profile.ClockGCD
end)



local function AutoShot_OnEvent(icon, event, unit, _, _, _, spellID)
	if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" and spellID == 75 then
		icon.asStart = TMW.time
		icon.asDuration = UnitRangedDamage("player")
		icon.NextUpdateTime = 0
	end
end

local function AutoShot_OnUpdate(icon, time)

	local NameName = icon.NameName
	local asDuration = icon.asDuration

	local ready = time - icon.asStart > asDuration
	local inrange = icon.RangeCheck and IsSpellInRange(NameName, "target") or 1

	if ready and inrange == 1 then
		icon:SetInfo(
			"alpha; start, duration; spell; inRange",
			icon.Alpha,
			0, 0,
			NameName,
			inrange
		)
	else
		icon:SetInfo(
			"alpha; start, duration; spell; inRange",
			icon.UnAlpha,
			icon.asStart, asDuration,
			NameName,
			inrange
		)
	end
end


local function SpellCooldown_OnEvent(icon, event, unit)
	if event ~= "UNIT_POWER_FREQUENT" or unit == "player" then
		icon.NextUpdateTime = 0
	end
end

local function SpellCooldown_OnUpdate(icon, time)
	local n, inrange, nomana, start, duration, charges, maxCharges, stack, start_charge, duration_charge = 1
	local IgnoreRunes, RangeCheck, ManaCheck, NameArray, NameNameArray =
	icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.NameArray, icon.NameNameArray

	for i = 1, #NameArray do
		local iName = NameArray[i]
		n = i
		
		if TMW.ISMOP then
			charges, maxCharges, start_charge, duration_charge = GetSpellCharges(iName)
			if charges then
				if charges < maxCharges then
					start, duration = start_charge, duration_charge
				else
					start, duration = GetSpellCooldown(iName)
				end
				stack = charges
			else
				start, duration = GetSpellCooldown(iName)
				stack = GetSpellCount(iName)
			end
		else
			start, duration = GetSpellCooldown(iName)
		end
		
		if duration then
			if IgnoreRunes and duration == 10 and NameNameArray[i] ~= mindfreeze then
				start, duration = 0, 0
			end
			inrange, nomana = 1
			if RangeCheck then
				inrange = IsSpellInRange(NameNameArray[i], "target") or 1
			end
			if ManaCheck then
				nomana = SpellHasNoMana(iName)
			end
			
			if inrange == 1 and not nomana and (duration == 0 or (charges and charges > 0) or OnGCD(duration)) then --usable
				icon:SetInfo(
					"alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell; inRange; noMana",
					icon.Alpha,
					SpellTextures[iName],
					start, duration,
					charges, maxCharges,
					stack, stack,
					iName,
					inrange,
					nomana
				)
				return
			end
		end
	end

	local NameFirst = icon.NameFirst
	if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
		
		if TMW.ISMOP then
			charges, maxCharges, start_charge, duration_charge = GetSpellCharges(NameFirst)
			if charges then
				if charges < maxCharges then
					start, duration = start_charge, duration_charge
				else
					start, duration = GetSpellCooldown(NameFirst)
				end
				stack = charges
			else
				start, duration = GetSpellCooldown(NameFirst)
				stack = GetSpellCount(NameFirst)
			end
		else
			start, duration = GetSpellCooldown(NameFirst)
		end
		
		inrange, nomana = 1
		if RangeCheck then
			inrange = IsSpellInRange(icon.NameName, "target") or 1
		end
		if ManaCheck then
			nomana = SpellHasNoMana(NameFirst)
		end
		if IgnoreRunes and duration == 10 and icon.NameName ~= mindfreeze then
			start, duration = 0, 0
		end
	end
	if duration then
		icon:SetInfo(
			"alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell; inRange; noMana",
			icon.UnAlpha,
			icon.FirstTexture,
			start, duration,
			charges, maxCharges,
			stack, stack,
			NameFirst,
			inrange,
			nomana
		)
	else
		icon:SetInfo("alpha", 0)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)

	if icon.NameName == strlower(GetSpellInfo(75)) and not icon.NameArray[2] then
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
		icon.FirstTexture = SpellTextures[icon.NameFirst]

		icon:SetInfo("texture; reverse", TMW:GetConfigIconTexture(icon), false)
		
		
		if not icon.RangeCheck then
			icon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
			icon:RegisterEvent("SPELL_UPDATE_USABLE")
			icon:RegisterEvent("SPELL_UPDATE_CHARGES")
			if icon.IgnoreRunes then
				icon:RegisterEvent("RUNE_POWER_UPDATE")
				icon:RegisterEvent("RUNE_TYPE_UPDATE")
			end	
			if icon.ManaCheck then
				icon:RegisterEvent("UNIT_POWER_FREQUENT")
				-- icon:RegisterEvent("SPELL_UPDATE_USABLE")-- already registered
			end
		
			icon:SetScript("OnEvent", SpellCooldown_OnEvent)
			icon:SetUpdateMethod("manual")
		end
	
		icon:SetUpdateFunction(SpellCooldown_OnUpdate)
	end

	icon:Update()
end


Type:Register(10)