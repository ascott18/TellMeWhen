-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, pr, ab
local strlower =
	  strlower
local GetSpellTexture =
	  GetSpellTexture
local print = TMW.print
local SpellTextures = TMW.SpellTextures

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	ICDType = true,
	ICDDuration = true,
	DontRefresh = true,
	ShowWhen = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("icd", RelevantSettings)
Type.name = L["ICONMENU_ICD"]
Type.desc = L["ICONMENU_ICD_DESC"]
Type.TypeChecks = {
	setting = "ICDType",
	text = L["ICONMENU_ICDTYPE"],
	{ value = "aura", 			text = L["ICONMENU_ICDBDE"], 			tooltipText = L["ICONMENU_ICDAURA_DESC"]},
	{ value = "spellcast", 		text = L["ICONMENU_SPELLCAST"], 		tooltipText = L["ICONMENU_SPELLCAST_DESC"]},
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 		text = L["ICONMENU_ICDUSABLE"], },
	{ value = "unalpha",  		text = L["ICONMENU_ICDUNUSABLE"], },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	pGUID = UnitGUID("player")
end


local function ICD_OnEvent(icon, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local p, g, i, n, _
		if clientVersion >= 40200 then
			_, p, _, g, _, _, _, _, _, _, _, i, n = ...
		elseif clientVersion >= 40100 then
			_, p, _, g, _, _, _, _, _, i, n = ...
		else
			_, p, _, g, _, _, _, _, i, n = ...
		end
		if g == pGUID and (p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_ENERGIZE" or p == "SPELL_AURA_APPLIED_DOSE") then
			local NameDictionary = icon.NameDictionary
			if (NameDictionary[i] or NameDictionary[strlowerCache[n]]) and not (icon.DontRefresh and (TMW.time - icon.StartTime) < icon.ICDDuration) then
				local t = SpellTextures[i]
				if t ~= icon.__tex then icon:SetTexture(t) end

				icon.StartTime = TMW.time
			end
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local u, n, _, _, i = ...
		if u == "player" then
			local NameDictionary = icon.NameDictionary
			if (NameDictionary[i] or NameDictionary[strlowerCache[n]]) and not (icon.DontRefresh and (TMW.time - icon.StartTime) < icon.ICDDuration) then
				local t = SpellTextures[i]
				if t ~= icon.__tex then icon:SetTexture(t) end

				icon.StartTime = TMW.time
			end
		end
	end
end

local function ICD_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local StartTime = icon.StartTime
		local timesince = time - StartTime
		local ICDDuration = icon.ICDDuration

		local d = ICDDuration - timesince
		if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
			icon:SetAlpha(0)
			return
		end

		if timesince > ICDDuration then
			icon:SetInfo(icon.Alpha, 1, nil, 0, 0)
		else
			icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and (icon.ShowTimer and 1 or .5) or 1, nil, StartTime, ICDDuration)
		end
	end
end

function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)

	icon.StartTime = icon.ICDDuration

	--[[ keep these events per icon isntead of global like unitcooldowns so that we dont start mixing and matching icon.
	also so that we only process icon for the player and nobody else, because that is all we care about here.
	technically, unitcooldown can track ICDs too, but not as accurately all the time, and unitcooldown's events dont consider SPELL_ENERGIZE.]]
	if icon.ICDType == "spellcast" then
		icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	elseif icon.ICDType == "aura" then
		icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	icon:SetScript("OnEvent", ICD_OnEvent)

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif SpellTextures[icon.NameFirst] then 
		icon:SetTexture(SpellTextures[icon.NameFirst])
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", ICD_OnUpdate)
	icon:OnUpdate(TMW.time)
end


