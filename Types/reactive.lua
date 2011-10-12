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

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, pr, ab, rc, mc
local GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellInfo =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellInfo
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures
local mindfreeze = strlower(GetSpellInfo(47528))


local Type = {}
Type.type = "reactive"
Type.name = L["ICONMENU_REACTIVE"]
Type.desc = L["ICONMENU_REACTIVE_DESC"]
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 		text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	RangeCheck = true,
	ManaCheck = true,
	CooldownCheck = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	UseActvtnOverlay = true,
	IgnoreNomana = true,
	IgnoreRunes = (pclass == "DEATHKNIGHT"),
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end


local function Reactive_OnEvent(icon, event, spell)

	if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
		if icon.NameFirst == spell or GetSpellInfo(spell) == icon.NameName then
			icon.Usable = true
		end
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		if icon.NameFirst == spell or GetSpellInfo(spell) == icon.NameName then
			icon.Usable = false
		end
	end
end

local function Reactive_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, nomana, start, duration, CD, usable = 1
		local NameArray, NameNameArray, RangeCheck, ManaCheck, CooldownCheck, IgnoreRunes, Usable, IgnoreNomana =
		 icon.NameArray, icon.NameNameArray, icon.RangeCheck, icon.ManaCheck, icon.CooldownCheck, icon.IgnoreRunes, icon.Usable, icon.IgnoreNomana

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
				usable = Usable or usable
				if usable and not CD and not nomana and inrange == 1 then --usable

					--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
					icon:SetInfo(icon.Alpha, 1, SpellTextures[iName], start, duration, iName, nil, nil, nil, nil, nil, nil)

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

			local alpha, color
			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					alpha, color = icon.UnAlpha*rc.a, rc
				elseif nomana then
					alpha, color = icon.UnAlpha*mc.a, mc
				else
					alpha, color = icon.UnAlpha, 0.5
				end
			else
				alpha, color = icon.UnAlpha, 1
			end
			
			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(alpha, color, icon.FirstTexture, start, duration, NameFirst, nil, nil, nil, nil, nil, nil)
		else
			icon:SetInfo(0)
		end
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, true)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.Usable = false

	icon.FirstTexture = SpellTextures[icon.NameFirst]

	if icon.UseActvtnOverlay then
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
		icon:SetScript("OnEvent", Reactive_OnEvent)
	end

	icon:SetTexture(TMW:GetConfigIconTexture(icon))

	icon:SetScript("OnUpdate", Reactive_OnUpdate)
	icon:OnUpdate(TMW.time)
end

TMW:RegisterIconType(Type)
