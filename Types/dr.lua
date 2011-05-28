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

local db, UPD_INTV, ClockGCD, pr, ab, rc, mc
local strlower, type =
	  strlower, type
local UnitGUID, UnitExists, GetSpellTexture =
	  UnitGUID, UnitExists, GetSpellTexture
local print = TMW.print
local huge = math.huge
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures

local clientVersion = select(4, GetBuildInfo())

local DRData = LibStub("DRData-1.0", true)
if not DRData then return end
local DRSpells = DRData.spells
local DRReset = DRData.RESET_TIME

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	CooldownShowWhen = true,
	Unit = true,
	Alpha = true,
	UnAlpha = true,
	ShowCBar = true,
	InvertBars = true,
	CBarOffs = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	ConditionAlpha = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("dr", RelevantSettings)
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_DR"]
--Type.desc = format(L["ICONMENU_DR_DESC"], GetSpellInfo(42292))


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end

local SpellTextures = TMW.SpellTextures

local function func(icon, g, i)
	local DRamt = icon.DRamt
	if DRamt ~= 0 then
		icon.DRamt = DRamt > 25 and DRamt/2 or 0
		icon.DRduration = 18
		icon.DRstart = TMW.time
		icon.DRtex = SpellTextures[i]
	end
end

local DR_OnEvent
if clientVersion >= 40200 then -- COMBAT_LOG_EVENT_UNFILTERED
	DR_OnEvent = function(icon, _, _, p, _, _, _, _, _, g, _, _, _, i, n, _, t)-- tyPe, Guid, spellId, spellName, auraType -- 2 NEW ARGS IN 4.2
		if t == "DEBUFF" and (p == "SPELL_AURA_REFRESH" or p == "SPELL_AURA_REMOVED") then
			local ND = icon.NameDictionary
			if ND[i] or ND[strlowerCache[n]] then
				func(icon, g, i)
			end
		end
	end
elseif clientVersion >= 40100 then
	DR_OnEvent = function(icon, _, _, p, _, _, _, _, g, _, _, i, n, _, t)-- tyPe, Guid, spellId, spellName, auraType -- NEW ARG IN 4.1 BETWEEN TYPE AND SOURCEGUID
		if t == "DEBUFF" and (p == "SPELL_AURA_REFRESH" or p == "SPELL_AURA_REMOVED") then
			local ND = icon.NameDictionary
			if ND[i] or ND[strlowerCache[n]] then
				func(icon, g, i)
			end
		end
	end
else
	DR_OnEvent = function(icon, _, _, p, _, _, _, g, _, _, i, n, _, t)-- tyPe, Guid, spellId, spellName, auraType
		if t == "DEBUFF" and (p == "SPELL_AURA_REFRESH" or p == "SPELL_AURA_REMOVED") then
			local ND = icon.NameDictionary
			if ND[i] or ND[strlowerCache[n]] then
				func(icon, g, i)
			end
		end
	end
end


local function DR_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local Alpha, UnAlpha, Units = icon.Alpha, icon.UnAlpha, icon.Units
		
		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				if icon.DRstart + icon.DRduration <= time then
					icon.DRamt = 100
					icon:SetInfo(Alpha, 1, icon.DRtex, 0, 0)
					if Alpha > 0 then
						return
					end
				else
					local DRamt = icon.DRamt
					icon:SetInfo(UnAlpha, (not icon.ShowTimer and Alpha ~= 0) and .5 or 1, icon.DRtex, icon.DRstart, icon.DRduration, nil, nil, nil, DRamt, DRamt .. "%")
					if UnAlpha > 0 then
						return
					end
				end
			end
		end
		icon:SetAlpha(0)
	end
end			


function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)
	
	icon.DRstart = icon.DRstart or 0
	icon.DRduration = icon.DRduration or 0
	icon.DRamt = icon.DRamt or 1

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnEvent", DR_OnEvent)
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	icon:SetScript("OnUpdate", DR_OnUpdate)
	icon:OnUpdate(TMW.time)
end
