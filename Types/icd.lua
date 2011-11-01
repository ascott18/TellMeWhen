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

local db, UPD_INTV, pr, ab
local strlower =
	  strlower
local print = TMW.print
local SpellTextures = TMW.SpellTextures

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache


local Type = {}
Type.type = "icd"
Type.name = L["ICONMENU_ICD"]
Type.desc = L["ICONMENU_ICD_DESC"]
Type.usePocketWatch = 1
Type.DurationSyntax = 1
Type.TypeChecks = {
	setting = "ICDType",
	text = L["ICONMENU_ICDTYPE"],
	{ value = "aura", 			text = L["ICONMENU_ICDBDE"], 				tooltipText = L["ICONMENU_ICDAURA_DESC"]},
	{ value = "spellcast", 		text = L["ICONMENU_SPELLCAST_COMPLETE"], 	tooltipText = L["ICONMENU_SPELLCAST_COMPLETE_DESC"]},
	{ value = "caststart", 		text = L["ICONMENU_SPELLCAST_START"], 		tooltipText = L["ICONMENU_SPELLCAST_START_DESC"]},
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	ICDType = true,
	DontRefresh = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
}
Type.DisabledEvents = {
	OnUnit = true,
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	pGUID = UnitGUID("player")
end


local function ICD_OnEvent(icon, event, ...)
	local valid, i, n, _
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local p, g
		if clientVersion >= 40200 then
			_, p, _, g, _, _, _, _, _, _, _, i, n = ...
		elseif clientVersion >= 40100 then
			_, p, _, g, _, _, _, _, _, i, n = ...
		else
			_, p, g, _, _, _, _, _, i, n = ...
		end
		valid = g == pGUID and (p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_ENERGIZE" or p == "SPELL_AURA_APPLIED_DOSE" or p == "SPELL_SUMMON")
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then
		valid, n, _, _, i = ... -- I cheat. valid is actually a unitID here.
		valid = valid == "player"
	end
	
	if valid then
		local NameHash = icon.NameHash
		local Key = NameHash[i] or NameHash[strlowerCache[n]]
		if Key and not (icon.DontRefresh and (TMW.time - icon.ICDStartTime) < icon.Durations[Key]) then
			local t = SpellTextures[i]
			if t ~= icon.__tex then icon:SetTexture(t) end

			icon.ICDStartTime = TMW.time
			icon.ICDDuration = icon.Durations[Key]
			icon.ICDID = i
		end
	end
end

local function ICD_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local ICDStartTime = icon.ICDStartTime
		local ICDDuration = icon.ICDDuration

		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		if time - ICDStartTime > ICDDuration then
			icon:SetInfo(icon.Alpha, 1, nil, 0, 0, icon.ICDID, nil, nil, nil, nil, nil)
		else
			icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and (icon.ShowTimer and 1 or .5) or 1, nil, ICDStartTime, ICDDuration, icon.ICDID, nil, nil, nil, nil, nil)
		end
	end
end

function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)

	icon.ICDStartTime = icon.ICDStartTime or 0
	icon.ICDDuration = icon.ICDDuration or 0
	
	--[[ keep these events per icon isntead of global like unitcooldowns are so that ...
	well i had a reason here but it didnt make sense when i came back and read it a while later. Just do it. I guess.]]
	if icon.ICDType == "spellcast" then
		icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	elseif icon.ICDType == "caststart" then
		icon:RegisterEvent("UNIT_SPELLCAST_START")
		icon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	elseif icon.ICDType == "aura" then
		icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	icon:SetScript("OnEvent", ICD_OnEvent)

	icon:SetTexture(TMW:GetConfigIconTexture(icon))

	icon:SetScript("OnUpdate", ICD_OnUpdate)
	icon:OnUpdate(TMW.time)
end

function Type:DragReceived(icon, t, data, subType)
	local ics = icon.ics
	
	if t ~= "spell" then
		return
	end
	
	local _, spellID = GetSpellBookItemInfo(data, subType)
	if not spellID then
		return
	end
	
	ics.Name = TMW:CleanString(ics.Name .. ";" .. spellID)
	if TMW.CI.ic ~= icon then
		TMW.IE:Load(nil, icon)
		TMW.IE:TabClick(TMW.IE.MainTab)
	end
	return true -- signal success
end


TMW:RegisterIconType(Type)