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

local db, ClockGCD, rc, mc, pr, ab
local GetSpellCooldown, IsSpellInRange, IsUsableSpell =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local UnitRangedDamage =
	  UnitRangedDamage
local pairs =
	  pairs
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures
local mindfreeze = strlower(GetSpellInfo(47528))

local Type = {}
LibStub("AceEvent-3.0"):Embed(Type)
Type.type = "cooldown"
Type.name = L["ICONMENU_SPELLCOOLDOWN"]
Type.desc = L["ICONMENU_SPELLCOOLDOWN_DESC"]
Type.chooseNameText  = L["CHOOSENAME_DIALOG"] .. "\r\n\r\n" .. L["CHOOSENAME_DIALOG_PETABILITIES"]

Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",  		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	RangeCheck = true,
	ManaCheck = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	IgnoreRunes = (pclass == "DEATHKNIGHT"),
}
Type.DisabledEvents = {
	OnUnit = true,
	OnStack = true,
}


function Type:Update()
	db = TMW.db
	ClockGCD = db.profile.ClockGCD
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end



local function AutoShot_OnEvent(icon, event, unit, _, _, _, spellID)
	if unit == "player" and spellID == 75 then
		icon.asStart = TMW.time
		icon.asDuration = UnitRangedDamage("player")
	end
end

local function AutoShot_OnUpdate(icon, time)
	
	local NameName = icon.NameName
	local asDuration = icon.asDuration
	
	local ready = time - icon.asStart > asDuration
	local inrange = icon.RangeCheck and IsSpellInRange(NameName, "target") or 1
	
	if ready and inrange == 1 then
		local color = icon:CrunchColor()
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, nil, 0, 0, NameName, nil, nil, nil, nil, nil)
	else
		
		local color = icon:CrunchColor(asDuration > 0 and asDuration, inrange)
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(icon.UnAlpha, color, nil, icon.asStart, asDuration, NameName, nil, nil, nil, nil, nil)
	end
end


local function SpellCooldown_OnUpdate(icon, time)

	local n, inrange, nomana, start, duration, isGCD = 1
	local IgnoreRunes, RangeCheck, ManaCheck, NameArray, NameNameArray = icon.IgnoreRunes, icon.RangeCheck, icon.ManaCheck, icon.NameArray, icon.NameNameArray

	for i = 1, #NameArray do
		local iName = NameArray[i]
		n = i
		start, duration = GetSpellCooldown(iName)
		if duration then
			if IgnoreRunes and duration == 10 and NameNameArray[i] ~= mindfreeze then
				start, duration = 0, 0
			end
			inrange, nomana = 1
			if RangeCheck then
				inrange = IsSpellInRange(NameNameArray[i], "target") or 1
			end
			if ManaCheck then
				_, nomana = IsUsableSpell(iName)
			end
			isGCD = (ClockGCD or duration ~= 0) and OnGCD(duration)
			if inrange == 1 and not nomana and (duration == 0 or isGCD) then --usable
			
				local color = icon:CrunchColor()
				--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
				icon:SetInfo(icon.Alpha, color, SpellTextures[iName], start, duration, iName, nil, nil, nil, nil, nil)
				return
			end
		end
	end

	local NameFirst = icon.NameFirst
	if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
		start, duration = GetSpellCooldown(NameFirst)
		inrange, nomana = 1
		if RangeCheck then
			inrange = IsSpellInRange(icon.NameName, "target") or 1
		end
		if ManaCheck then
			_, nomana = IsUsableSpell(NameFirst)
		end
		if IgnoreRunes and duration == 10 and icon.NameName ~= mindfreeze then
			start, duration = 0, 0
		end
		isGCD = OnGCD(duration)
	end
	if duration then

		local color = icon:CrunchColor(duration, inrange, nomana)
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(icon.UnAlpha, color, icon.FirstTexture, start, duration, NameFirst, nil, nil, nil, nil, nil)
	else
		icon:SetInfo(0)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	
	if icon.NameName == strlower(GetSpellInfo(75)) and not icon.NameArray[2] then
		icon:SetTexture(GetSpellTexture(75))
		icon.asStart = icon.asStart or 0
		icon.asDuration = icon.asDuration or 0
		
		icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		icon:SetScript("OnEvent", AutoShot_OnEvent)
		
		icon:SetScript("OnUpdate", AutoShot_OnUpdate)
	else
		icon.FirstTexture = SpellTextures[icon.NameFirst]

		icon:SetTexture(TMW:GetConfigIconTexture(icon))
		icon:SetScript("OnUpdate", SpellCooldown_OnUpdate)
	end
	
	icon:Update()
end


TMW:RegisterIconType(Type)