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

local GetSpellCooldown, GetSpellCharges, GetSpellCount, IsUsableSpell =
	  GetSpellCooldown, GetSpellCharges, GetSpellCount, IsUsableSpell
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local UnitRangedDamage =
	  UnitRangedDamage
local pairs =
	  pairs
local OnGCD = TMW.OnGCD
local SpellHasNoMana = TMW.SpellHasNoMana
local print = TMW.print
local isString = TMW.isString
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures
local mindfreeze = strlower(GetSpellInfo(47528))

local IsSpellInRange = LibStub("SpellRange-1.0").IsSpellInRange

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

local usableData = {}
local unusableData = {}
local function SpellCooldown_OnUpdate(icon, time)    
	local IgnoreRunes, RangeCheck, ManaCheck, NameArray, NameNameArray =
	icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.NameArray, icon.NameNameArray

	local usableFound, unusableFound

	for i = 1, #NameArray do
		local iName = NameArray[i]
		
		local start, duration, charges, maxCharges, stack
		if TMW.ISMOP then
			local start_charge, duration_charge
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
			local inrange, nomana = 1
			if RangeCheck then
				inrange = IsSpellInRange(iName, "target") or 1
			end
			if ManaCheck then
				nomana = SpellHasNoMana(iName)
			end
			
			if inrange == 1 and not nomana and (duration == 0 or (charges and charges > 0) or OnGCD(duration)) then --usable
				if not usableFound then
					wipe(usableData)
					usableData.alpha = icon.Alpha
					usableData.tex = SpellTextures[iName]
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
				unusableData.tex = SpellTextures[iName]
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

