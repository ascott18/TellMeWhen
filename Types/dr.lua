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
local DRSpells = DRData.spells
local DRReset = DRData.RESET_TIME

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	CooldownShowWhen = true,
	ICDDuration = true,
	Unit = true,
	Alpha = true,
	UnAlpha = true,
	ShowCBar = true,
	InvertBars = true,
	CBarOffs = true,
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

local DRs = setmetatable({}, {__index = function(t, k)
	local n = {
		start = 0,
		duration = 0,
		amt = 1,
	}
	t[k] = n
	return n
end}) TMW.DRs = DRs

local SpellTextures = TMW.SpellTextures

local function func(g, i)
	local dr = DRs[g]
	print(dr.amt, g, i)
	local amt = dr.amt
	if amt ~= 0 then
		dr.amt = amt > .25 and amt/2 or 0
		dr.duration = DRReset
		dr.start = TMW.time
		dr.id = i
		dr.tex = SpellTextures[i]
		print(dr.amt, dr.start, dr.duration)
	--	icon:SetInfo(icon.UnAlpha, (not icon.ShowTimer and icon.Alpha ~= 0) and .5 or 1, SpellTextures[i], DRReset + time, DRReset, nil, nil, nil, amt)
	end
end


if clientVersion >= 40200 then -- COMBAT_LOG_EVENT_UNFILTERED
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, _, _, _, _, g, _, _, _, i, n, _, t)-- tyPe, Guid, spellId, spellName, auraType -- 2 NEW ARGS IN 4.2
		if (p == "SPELL_AURA_REFRESH" or p == "SPELL_AURA_APPLIED") and t == "DEBUFF" and DRSpells[i] then
			func(g, i)
		end
	end
elseif clientVersion >= 40100 then
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, _, _, _, g, _, _, i, n, _, t)-- tyPe, Guid, spellId, spellName, auraType -- NEW ARG IN 4.1 BETWEEN TYPE AND SOURCEGUID
		if (p == "SPELL_AURA_REFRESH" or p == "SPELL_AURA_REMOVED") and t == "DEBUFF" and DRSpells[i] then
			func(g, i)
		end
	end
else
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, _, _, g, _, _, i, n, _, t)-- tyPe, Guid, spellId, spellName, auraType
		if (p == "SPELL_AURA_REFRESH" or p == "SPELL_AURA_REMOVED") and t == "DEBUFF" and DRSpells[i] then
			func(g, i)
		end
	end
end


local function DR_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local Alpha, Units = icon.Alpha, icon.Units
		
		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				local dr = DRs[UnitGUID(unit)]
				if dr.start + dr.duration <= time then
					dr.amt = 1
					icon:SetInfo(Alpha, 1, dr.tex, 0, 0)
					if Alpha > 0 then
						print("RET")
						return
					end
				else
					icon:SetInfo(icon.UnAlpha, (not icon.ShowTimer and icon.Alpha ~= 0) and .5 or 1, dr.tex, dr.start, dr.duration, nil, nil, nil, dr.amt)
					if Alpha == 0 then
						print("RET")
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
	icon.Units = TMW:GetUnits(icon, icon.Unit)
	
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", DR_OnUpdate)
	icon:OnUpdate(TMW.time)
end
