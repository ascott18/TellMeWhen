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

local db
local strlower =
	  strlower
local print = TMW.print
local SpellTextures = TMW.SpellTextures

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache


local Type = {}
Type.type = "cleu"
Type.name = L["ICONMENU_CLEU"]
Type.desc = L["ICONMENU_CLEU_DESC"]
Type.usePocketWatch = 1
Type.AllowNoName = true
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"]
--Type.DurationSyntax = 1
Type.SUGType = "spell"
Type.leftCheckYOffset = -100
--[[Type.TypeChecks = {
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
}]]
Type.RelevantSettings = {
	CLEUEvents = true,
	SourceUnit = true,
	DestUnit = true,
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
	OnStack = true,
}


function Type:Update()
	db = TMW.db
	pGUID = UnitGUID("player")
end


local function CLEU_OnEvent(icon, _, _, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local spellID, spellName, spellSchool = ...
	if icon.AllowAnyEvents or icon.CLEUEvents[event] then
		local SourceUnits = icon.SourceUnits
		if SourceUnits then
			local matched
			for i = 1, #SourceUnits do
				local unit = SourceUnits[i]
				local sourceName = strlowerCache[sourceName]
				if unit == sourceName or UnitGUID(unit) == sourceGUID then
					matched = 1
					break
				end
			end
			if not matched then
				return
			end
		end
		
		local DestUnits = icon.DestUnits
		if DestUnits then
			local matched
			for i = 1, #DestUnits do
				local unit = DestUnits[i]
				local destName = strlowerCache[destName]
				if unit == destName or UnitGUID(unit) == destGUID then
					matched = 1
					break
				end
			end
			if not matched then
				return
			end
		end
		
		local NameHash = icon.NameHash
		if NameHash then
			if not (NameHash[strlowerCache[spellName]] or NameHash[spellID]) then
				return
			end
		end
		
		-- all checks complete. procede to do shit.
		print("Event Passed", spellName, sourceName, destName, event)
	end
end

local function ICD_OnUpdate(icon, time)
--[[
	local ICDStartTime = icon.ICDStartTime
	local ICDDuration = icon.ICDDuration

	--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	if time - ICDStartTime > ICDDuration then
		local color = icon:CrunchColor()
		
		icon:SetInfo(icon.Alpha, color, nil, 0, 0, icon.ICDID, nil, nil, nil, nil, nil)
	else
		local color = icon:CrunchColor(ICDDuration)
		
		icon:SetInfo(icon.UnAlpha, color, nil, ICDStartTime, ICDDuration, icon.ICDID, nil, nil, nil, nil, nil)
	end]]
end
local naturesGrace = strlower(GetSpellInfo(16886))

function Type:Setup(icon, groupID, iconID)
	icon.NameHash = icon.Name ~= "" and TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	
	icon.SourceUnits = icon.SourceUnit ~= "" and TMW:GetUnits(icon, icon.SourceUnit)
	icon.DestUnits = icon.DestUnit ~= "" and TMW:GetUnits(icon, icon.DestUnit)
	
	icon.AllowAnyEvents = icon.CLEUEvents[""]
	if icon.AllowAnyEvents and not icon.SourceUnits and not icon.DestUnits and not icon.NameHash then
		TMW:Error("No filters detected for " .. icon:GetName()) -- TODO: SOMETHING BETTER THAN THIS
		return
	end
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	icon:SetScript("OnEvent", CLEU_OnEvent)
	
	--[=[icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
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

	icon:SetTexture(TMW:GetConfigIconTexture(icon))

	icon:SetScript("OnUpdate", ICD_OnUpdate)
	icon:Update()]=]
end

function Type:DragReceived(icon, t, data, subType)
	--[[local ics = icon:GetSettings()
	
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
	return true -- signal success]]
end


TMW:RegisterIconType(Type)