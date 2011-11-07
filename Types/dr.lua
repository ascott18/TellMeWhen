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
local strlower, bitband =
	  strlower, bit.band
local UnitGUID =
	  UnitGUID
local print = TMW.print
local huge = math.huge
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures
local CL_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_PET = COMBATLOG_OBJECT_CONTROL_PLAYER

local clientVersion = select(4, GetBuildInfo())

local DRData = LibStub("DRData-1.0", true)
if not DRData then 
	error("TMW: The Diminishing Returns icon type requires DRData-1.0. It is embedded within TellMeWhen - you probably just need to restart the game.")
end
local DRSpells = DRData.spells
local DRReset = 18
local PvEDRs = {}
for spellID, category in pairs(DRSpells) do
	if DRData.pveDR[category] then
		PvEDRs[spellID] = 1
	end
end


local Type = {}
Type.type = "dr"
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_DR"]
Type.desc = L["ICONMENU_DR_DESC"]
Type.usePocketWatch = 1
Type.SUGType = "dr"
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_DRABSENT"], 		colorCode = "|cFF00FF00" },
	{ value = "unalpha",		text = L["ICONMENU_DRPRESENT"], 	colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	Unit = true,
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
	CheckRefresh = true,
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

local function DR_OnEvent(icon, _, _, p, ...)
	if p == "SPELL_AURA_REMOVED" or p == "SPELL_AURA_APPLIED" or (icon.CheckRefresh and p == "SPELL_AURA_REFRESH") then
		local g, f, i, n, t, _
		if clientVersion >= 40200 then
			_, _, _, _, _, g, _, f, _, i, n, _, t = ...
		elseif clientVersion >= 40100 then
			_, _, _, _, g, _, f, i, n, _, t = ...
		else
			_, _, _, g, _, f, i, n, _, t = ...
		end
		if t == "DEBUFF" then
			local ND = icon.NameHash
			if ND[i] or ND[strlowerCache[n]] then
				if PvEDRs[i] or bitband(f, CL_PLAYER) == CL_PLAYER or bitband(f, CL_PET) == CL_PET then
					local dr = icon[g]
					if p == "SPELL_AURA_APPLIED" then
						if dr and dr.start + dr.duration <= TMW.time then
							dr.start = 0
							dr.duration = 0
							dr.amt = 100
						end
					else
						if not dr then
							dr = {
								amt = 50,
								start = TMW.time,
								duration = DRReset,
								tex = SpellTextures[i]
							}
							icon[g] = dr
						else
							local amt = dr.amt
							if amt and amt ~= 0 then
								dr.amt = amt > 25 and amt/2 or 0
								dr.duration = DRReset
								dr.start = TMW.time
								dr.tex = SpellTextures[i]
							end
						end
					end
				end
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
			local dr = icon[UnitGUID(unit)]
			
			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			if dr then
				if dr.start + dr.duration <= time then
					icon:SetInfo(Alpha, 1, dr.tex, 0, 0, icon.firstCategory, nil, nil, nil, nil, unit)
					if Alpha > 0 then
						return
					end
				else
					local amt = dr.amt
					icon:SetInfo(UnAlpha, (not icon.ShowTimer and Alpha ~= 0) and .5 or 1, dr.tex, dr.start, dr.duration, icon.firstCategory, nil, amt, amt .. "%", nil, unit)
					if UnAlpha > 0 then
						return
					end
				end
			else
				icon:SetInfo(Alpha, 1, icon.FirstTexture, 0, 0, icon.firstCategory, nil, nil, nil, nil, unit)
				if Alpha > 0 then
					return
				end
			end
		end
		icon:SetInfo(0)
	end
end

function Type:GetNameForDisplay(icon, data)
	return data and (L[data] or gsub(data, "DR%-", ""))
end

local categoryTEMP = setmetatable({}, {
	__index = function(t, k)
		-- a ghetto sort mechanism
		local len = 1
		for k, v in pairs(t) do
			len = len + 1
		end
		local str = format("%3.0f\001", len)
		t[k] = str
		return str
	end
})

local function CheckCategories(icon)
	wipe(categoryTEMP)
	local firstCategory, doWarn
	local append = ""
	
	for i, IDorName in ipairs(icon.NameArray) do
		for category, str in pairs(TMW.BE.dr) do
			if TMW:StringIsInSemicolonList(str, IDorName) or TMW:GetSpellNames(icon, str, nil, 1, 1)[IDorName] then
				if not firstCategory then
					firstCategory = category
					icon.firstCategory = category
				end
				categoryTEMP[category] = categoryTEMP[category] .. ";" .. TMW:RestoreCase(IDorName)
				if firstCategory ~= category then
					doWarn = true
				end
			end
		end
	end
	
	if next(categoryTEMP) then
		for category, string in TMW:OrderedPairs(categoryTEMP, "values") do
			string = strmatch(string, ".*\001(.*)")
			append = append .. format("\r\n\r\n%s:\r\n%s", L[category], TMW:CleanString(string))
		end
	end
	
	if icon:IsBeingEdited() == 1 then
		if doWarn then
			TMW.HELP:Show("ICON_DR_MISMATCH", icon, TMW.IE.Main.Name, 0, 0, L["WARN_DRMISMATCH"]..append)
		else
			TMW.HELP:Hide("ICON_DR_MISMATCH")
		end
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)
	icon.FirstTexture = SpellTextures[icon.NameFirst]

	-- Do the Right Thing and tell people if their DRs mismatch
	CheckCategories(icon)
	
	icon:SetTexture(TMW:GetConfigIconTexture(icon))

	icon:SetScript("OnEvent", DR_OnEvent)
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	icon:SetScript("OnUpdate", DR_OnUpdate)
	icon:OnUpdate(TMW.time)
end

TMW:RegisterIconType(Type)