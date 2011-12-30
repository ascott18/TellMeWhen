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
Type.DurationSyntax = 1
Type.SUGType = "spell"
Type.leftCheckYOffset = -110
--[[Type.TypeChecks = {
	setting = "ICDType",
	text = L["ICONMENU_ICDTYPE"],
	{ value = "aura", 			text = L["ICONMENU_ICDBDE"], 				tooltipText = L["ICONMENU_ICDAURA_DESC"]},
	{ value = "spellcast", 		text = L["ICONMENU_SPELLCAST_COMPLETE"], 	tooltipText = L["ICONMENU_SPELLCAST_COMPLETE_DESC"]},
	{ value = "caststart", 		text = L["ICONMENU_SPELLCAST_START"], 		tooltipText = L["ICONMENU_SPELLCAST_START_DESC"]},
}]]
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha",			text = L["ICONMENU_NOTCOUNTING"], 		tooltipText = L["ICONMENU_NOTCOUNTING_DESC"],	colorCode = "|cFFFF0000" },
	{ value = "unalpha", 		text = L["ICONMENU_COUNTING"], 			tooltipText = L["ICONMENU_COUNTING_DESC"],		colorCode = "|cFF00FF00" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
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

Type.EventDisabled_OnStack = true
Type.EventDisabled_OnCLEUEvent = false



function Type:Update()
	db = TMW.db
	pGUID = UnitGUID("player")
end
local EnvironmentalTextures = {
	DROWNING = "Interface\\Icons\\Spell_Shadow_DemonBreath",
	FALLING = GetSpellTexture(130),
	FATIGUE = "Interface\\Icons\\Ability_Suffocate",
	FIRE = GetSpellTexture(84668),
	LAVA = GetSpellTexture(90373),
	SLIME = GetSpellTexture(49870),
}



local function CLEU_OnEvent(icon, _, t, event, h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	if icon.AllowAnyEvents or icon.CLEUEvents[event] then
	
		local SourceUnits = icon.SourceUnits
		local sourceUnit = sourceName
		if SourceUnits and sourceName then
			local matched
			for i = 1, #SourceUnits do
				local unit = SourceUnits[i]
				local sourceName = strlowerCache[sourceName]
				if unit == sourceName or UnitGUID(unit) == sourceGUID then
					sourceUnit = unit
					matched = 1
					break
				end
			end
			if not matched then
				return
			end
		end
		
		local DestUnits = icon.DestUnits
		local destUnit = destName
		if DestUnits and destName then
			local matched
			for i = 1, #DestUnits do
				local unit = DestUnits[i]
				local destName = strlowerCache[destName]
				if unit == destName or UnitGUID(unit) == destGUID then
					destUnit = unit
					matched = 1
					break
				end
			end
			if not matched then
				return
			end
		end
		
		local NameHash = icon.NameHash
		local duration = icon.Duration
		if NameHash then
			local key = NameHash[""] or NameHash[strlowerCache[spellName]] or NameHash[spellID]
			if not key then
				return
			end
			duration = icon.Durations[key]
		end
		
		local spellID = ...
			
		local spell, tex, extra
		-- sourceUnit, destUnit
		if event == "SPELL_CAST_FAILED" or event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" then
			spell = spellID
		elseif event == "SWING_DAMAGE" or event == "SWING_MISSED" then
			spell = ACTION_SWING
			tex = GetSpellTexture(6603)
		elseif event == "ENCHANT_APPLIED" or event == "ENCHANT_REMOVED" then
			local enchantName, itemID = ...
			spell = enchantName
			tex = GetItemIcon(itemID)
		elseif event == "SPELL_INTERRUPT" or event == "SPELL_DISPEL" or event == "SPELL_DISPEL_FAILED" or event == "SPELL_AURA_BROKEN_SPELL" or event == "SPELL_AURA_STOLEN" then
			local _, _, _, extraID = ...
			extra = extraID
			if icon.UseExtraID then
				tex = SpellTextures[extraID]
			else
				tex = SpellTextures[spellID]
			end
			spell = spellID
		elseif event == "ENVIRONMENTAL_DAMAGE" then
			spell = _G["ACTION_ENVIRONMENTAL_DAMAGE_"..spellID]
			tex = EnvironmentalTextures[spellID] or "Interface\\Icons\\INV_Misc_QuestionMark" -- spellID is actually environmentalType
		elseif event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "UNIT_DISSIPATES" or event == "PARTY_KILL" then
			spell = L["CLEU_DIED"]
			tex = "Interface\\Icons\\Ability_Rogue_FeignDeath"
		else
			spell = spellID
			--"RANGE_DAMAGE", -- normal
			--"RANGE_MISSED", -- normal
			--"SPELL_DAMAGE", -- normal
			--"SPELL_MISSED", -- normal
			--"SPELL_EXTRA_ATTACKS", -- normal
			--"SPELL_HEAL", -- normal
			--"SPELL_ENERGIZE", -- normal
			--"SPELL_DRAIN", -- normal
			--"SPELL_LEECH", -- normal
			--"SPELL_AURA_APPLIED", -- normal
			--"SPELL_AURA_REFRESH", -- normal
			--"SPELL_AURA_REMOVED", -- normal
	
			--"SPELL_PERIODIC_DAMAGE", -- normal
			--"SPELL_PERIODIC_DRAIN", -- normal
			--"SPELL_PERIODIC_ENERGIZE", -- normal
			--"SPELL_PERIODIC_LEECH", -- normal
			--"SPELL_PERIODIC_HEAL", -- normal
			--"SPELL_PERIODIC_MISSED", -- normal
			--"DAMAGE_SHIELD", -- normal
			--"DAMAGE_SHIELD_MISSED", -- normal
			--"DAMAGE_SPLIT", -- normal
			--"SPELL_INSTAKILL", -- normal 
			--"SPELL_SUMMON" -- normal
			--"SPELL_RESURRECT" -- normal
			--"SPELL_CREATE" -- normal
			--"SPELL_DURABILITY_DAMAGE" -- normal
			--"SPELL_DURABILITY_DAMAGE_ALL" -- normal
			--"SPELL_AURA_BROKEN" -- normal
			--"SPELL_AURA_APPLIED_DOSE"					--SEMI-NORMAL, CONSIDER SPECIAL IMPLEMENTATION
			--"SPELL_AURA_REMOVED_DOSE"					--SEMI-NORMAL, CONSIDER SPECIAL IMPLEMENTATION
		end
		tex = tex or SpellTextures[spell] or SpellTextures[spellID]
	
		-- bind text updating
		if icon.cleu_sourceUnit ~= sourceUnit and icon.UpdateBindText_SourceUnit then
			icon:UpdateBindText()
		elseif icon.cleu_destUnit ~= destUnit and icon.UpdateBindText_DestUnit then
			icon:UpdateBindText()
		elseif icon.cleu_extraSpell ~= extra and icon.UpdateBindText_ExtraSpell then
			icon:UpdateBindText()
		end
		
		icon.cleu_start = TMW.time
		print(duration, 0)
		icon.cleu_duration = duration or 0
		icon.cleu_spell = spell
		
		icon.cleu_sourceUnit = sourceUnit 
		icon.cleu_destUnit = destUnit 
		icon.cleu_extraSpell = extra 
		
		if icon.OnCLEUEvent then
			icon.EventsToFire.OnCLEUEvent = true
		end
		
		icon:OnUpdate(TMW.time, tex)
		
		print(event, spell, "|T" .. tex .. ":0|t", sourceUnit, destUnit, extra)
			
		-- all checks complete. procede to do shit.
		--print(CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, t, event, h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...))
	--	print("Event Passed", spellName, sourceName, destName, event)
	end
end

local function CLEU_OnUpdate(icon, time, tex)
	-- tex is passed in when calling from OnEvent, otherwise its nil
	
	local start = icon.cleu_start
	local duration = icon.cleu_duration

	--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	if time - start > duration then
		local color = icon:CrunchColor()
		
		icon:SetInfo(icon.Alpha, color, tex, 0, 0, icon.cleu_spell, nil, nil, nil, nil, icon.cleu_destUnit or icon.cleu_sourceUnit)
	else
		local color = icon:CrunchColor(duration)
		
		icon:SetInfo(icon.UnAlpha, color, tex, start, duration, icon.cleu_spell, nil, nil, nil, nil, icon.cleu_destUnit or icon.cleu_sourceUnit)
	end
	
	icon.LastUpdate = time -- sometimes we call this function whenever the hell we want ("OnEvent"), so at least have the decency to delay the next update
end
local naturesGrace = strlower(GetSpellInfo(16886))

function Type:Setup(icon, groupID, iconID)
	icon.NameHash = icon.Name ~= "" and TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
--	icon.NameArray = icon.Name ~= "" and TMW:GetSpellNames(icon, icon.Name)
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)
	
	icon.SourceUnits = icon.SourceUnit ~= "" and TMW:GetUnits(icon, icon.SourceUnit)
	icon.DestUnits = icon.DestUnit ~= "" and TMW:GetUnits(icon, icon.DestUnit)
	
	icon.AllowAnyEvents = icon.CLEUEvents[""]
	
	icon.UpdateBindText_SourceUnit = nil
	icon.UpdateBindText_DestUnit = nil
	icon.UpdateBindText_ExtraSpell = nil
	if icon.BindText then
		if strfind(icon.BindText, "%%[Oo]") then
			icon.UpdateBindText_Any = true
			icon.UpdateBindText_SourceUnit = nil
		end
		if strfind(icon.BindText, "%%[Ee]") then
			icon.UpdateBindText_Any = true
			icon.UpdateBindText_DestUnit = nil
		end
		if strfind(icon.BindText, "%%[Xx]") then
			icon.UpdateBindText_Any = true
			icon.UpdateBindText_ExtraSpell = nil
		end
	end
	
	if icon.AllowAnyEvents and not icon.SourceUnits and not icon.DestUnits and not icon.NameHash then
		TMW:Error("No filters detected for " .. icon:GetName()) -- TODO: SOMETHING BETTER THAN THIS
		return
	end
	
	
	icon.cleu_start = icon.cleu_start or 0
	icon.cleu_duration = icon.cleu_duration or 0
	
	icon.cleu_spell = nil

	icon.cleu_sourceUnit = nil
	icon.cleu_destUnit = nil
	icon.cleu_extraSpell = nil
	
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	icon:SetScript("OnEvent", CLEU_OnEvent)
	
	icon:SetTexture(TMW:GetConfigIconTexture(icon))
	
	icon:SetScript("OnUpdate", CLEU_OnUpdate)
	icon:Update()
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