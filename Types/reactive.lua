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

local GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellInfo =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellInfo
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local mindfreeze = strlower(GetSpellInfo(47528))


local Type = TMW.Classes.IconType:New("reactive")
Type.name = L["ICONMENU_REACTIVE"]
Type.desc = L["ICONMENU_REACTIVE_DESC"]

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("noMana")
Type:UsesAttributes("inRange")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	UseActvtnOverlay		= false,
	CooldownCheck			= false,
	IgnoreNomana			= false,
	RangeCheck				= false,
	ManaCheck				= false,
	IgnoreRunes				= false,
}

Type:RegisterConfigPanel_XMLTemplate("full", 1, "TellMeWhen_ChooseName", {
	text = L["CHOOSENAME_DIALOG"] .. "\r\n\r\n" .. L["CHOOSENAME_DIALOG_PETABILITIES"],
})

Type:RegisterConfigPanel_XMLTemplate("column", 2, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 		},
})

Type:RegisterConfigPanel_ConstructorFunc("column", 1, "TellMeWhen_ReactiveSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "UseActvtnOverlay",
			title = L["ICONMENU_USEACTIVATIONOVERLAY"],
			tooltip = L["ICONMENU_USEACTIVATIONOVERLAY_DESC"],
		},
		{
			setting = "IgnoreNomana",
			title = L["ICONMENU_IGNORENOMANA"],
			tooltip = L["ICONMENU_IGNORENOMANA_DESC"],
		},
		{
			setting = "CooldownCheck",
			title = L["ICONMENU_COOLDOWNCHECK"],
			tooltip = L["ICONMENU_COOLDOWNCHECK_DESC"],
		},
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
			disabledtooltip = L["ICONMENU_IGNORERUNES_DESC_DISABLED"],
			disabled = function(self)
				return not TMW.CI.ics.CooldownCheck
			end,
		},
	})
end)


function Type:Update()
end


local function Reactive_OnEvent(icon, event, arg1)
	if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		if icon.NameFirst == arg1 or strlowerCache[GetSpellInfo(arg1)] == icon.NameName then
			icon.forceUsable = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"
			icon.NextUpdateTime = 0
		end
	elseif event ~= "UNIT_POWER_FREQUENT" or arg1 == "player" then
		icon.NextUpdateTime = 0
	end
end

local function Reactive_OnUpdate(icon, time)

	local n, inrange, nomana, start, duration, CD, usable = 1
	local NameArray, NameNameArray, RangeCheck, ManaCheck, CooldownCheck, IgnoreRunes, forceUsable, IgnoreNomana =
	 icon.NameArray, icon.NameNameArray, icon.RangeCheck, icon.ManaCheck, icon.CooldownCheck, icon.IgnoreRunes, icon.forceUsable, icon.IgnoreNomana

	for i = 1, #NameArray do
		local iName = NameArray[i]
		n = i
		start, duration = GetSpellCooldown(iName)
		if duration then
			inrange, CD = 1
			if RangeCheck then
				inrange = IsSpellInRange(NameNameArray[i], "target") or 1
			end
			usable, nomana = IsUsableSpell(iName)
			if IgnoreNomana then
				usable = usable or nomana
			end
			if not ManaCheck then
				nomana = nil
			end
			if CooldownCheck then
				if IgnoreRunes and duration == 10 and NameNameArray[i] ~= mindfreeze then
					start, duration = 0, 0
				end
				CD = not (duration == 0 or OnGCD(duration))
			end
			usable = forceUsable or usable
			if usable and not CD and not nomana and inrange == 1 then --usable
				icon:SetInfo("alpha; texture; start, duration; spell; inRange; noMana",
					icon.Alpha,
					SpellTextures[iName],
					start, duration,
					iName,
					inrange,
					nomana
				)
				return
			end
		end
	end

	local NameFirst = icon.NameFirst
	if n > 1 then -- if more than 1 spell was checked, we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
		start, duration = GetSpellCooldown(NameFirst)
		if IgnoreRunes and duration == 10 and icon.NameName ~= mindfreeze then
			start, duration = 0, 0
		end
		inrange, nomana = 1
		if RangeCheck then
			inrange = IsSpellInRange(icon.NameName, "target") or 1
		end
		if ManaCheck then
			_, nomana = IsUsableSpell(NameFirst)
		end
	end
	if duration then
		icon:SetInfo("alpha; texture; start, duration; spell; inRange; noMana",
			icon.UnAlpha,
			icon.FirstTexture,
			start, duration,
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
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, true)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.forceUsable = nil

	icon.FirstTexture = SpellTextures[icon.NameFirst]

	icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))
	
	
	if icon.UseActvtnOverlay then
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
		icon:SetScript("OnEvent", Reactive_OnEvent)
	end
	
	if not icon.RangeCheck then
		icon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		icon:RegisterEvent("SPELL_UPDATE_USABLE")
		if icon.IgnoreRunes then
			icon:RegisterEvent("RUNE_POWER_UPDATE")
			icon:RegisterEvent("RUNE_TYPE_UPDATE")
		end	
		if icon.ManaCheck then
			icon:RegisterEvent("UNIT_POWER_FREQUENT")
			-- icon:RegisterEvent("SPELL_UPDATE_USABLE") -- already registered
		end
	
		icon:SetScript("OnEvent", Reactive_OnEvent)
		icon:SetUpdateMethod("manual")
	end
	
	icon:SetScript("OnUpdate", Reactive_OnUpdate)
	icon:Update()
end

Type:Register()
