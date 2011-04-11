-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, time, UPD_INTV, pr, ab
local strlower =
	  strlower
local GetSpellTexture =
	  GetSpellTexture
local print = TMW.print

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local clientVersion = select(4, GetBuildInfo())

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	ICDType = true,
	ICDDuration = true,
	CooldownShowWhen = true,
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


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	pGUID = UnitGUID("player")
end


local ICD_OnEvent
if clientVersion >= 40100 then
	ICD_OnEvent = function(icon, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, event, _, sourceGUID, _, _, _, _, _, spellID, spellName = ... --NEW ARG ADDED BETWEEN EVENT AND SOURCEGUID IN 4.1
			if sourceGUID == pGUID and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_ENERGIZE") then
				if icon.NameDictionary[spellID] or icon.NameDictionary[strlower(spellName)] then
					icon:SetTexture(GetSpellTexture(spellID))
					icon.StartTime = TMW.time
				end
			end
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
			local unit, spellName, _, _, spellID = ...
			if unit == "player" then
				if icon.NameDictionary[spellID] or icon.NameDictionary[strlower(spellName)] then
					icon:SetTexture(GetSpellTexture(spellID))
					icon.StartTime = TMW.time
				end
			end
		end
	end
else
	ICD_OnEvent = function(icon, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, event, sourceGUID, _, _, _, _, _, spellID, spellName = ...
			if sourceGUID == pGUID and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_ENERGIZE") then
				local NameDictionary = icon.NameDictionary
				if NameDictionary[spellID] or NameDictionary[strlower(spellName)] then
					icon:SetTexture(GetSpellTexture(spellID))
					icon.StartTime = TMW.time
				end
			end
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
			local unit, spellName, _, _, spellID = ...
			if unit == "player" then
				local NameDictionary = icon.NameDictionary
				if NameDictionary[spellID] or NameDictionary[strlower(spellName)] then
					icon:SetTexture(GetSpellTexture(spellID))
					icon.StartTime = TMW.time
				end
			end
		end
	end
end

local function ICD_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local timesince = time - icon.StartTime
		local ICDDuration = icon.ICDDuration

		local d = ICDDuration - timesince
		if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
			icon:SetAlpha(0)
			return
		end
		if icon.ShowCBar then
			icon:CDBarStart(icon.StartTime, ICDDuration)
		end
		if timesince > ICDDuration then
			icon:SetVertexColor(1)
			icon:SetAlpha(icon.Alpha)
			icon:SetCooldown(0, 0)
			return
		else
			if icon.Alpha ~= 0 then
				if not icon.ShowTimer then
					icon:SetVertexColor(0.5)
					icon:SetAlpha(icon.UnAlpha)
				else
					icon:SetVertexColor(1)
					icon:SetAlpha(icon.UnAlpha)
				end
			else
				icon:SetVertexColor(1)
				icon:SetAlpha(icon.UnAlpha)
			end
			if icon.ShowTimer then
				icon:SetCooldown(icon.StartTime, ICDDuration)
			end
			return
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
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", ICD_OnUpdate)
	icon:OnUpdate(GetTime() + 1)
end


