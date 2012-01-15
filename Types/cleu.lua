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
local bit_band = bit.band
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
Type.SUGType = "spell"
Type.spacebefore = true
-- Type.leftCheckYOffset = -130 -- nevermind


Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha",			text = L["ICONMENU_COUNTING"], 		tooltipText = L["ICONMENU_COUNTING_DESC"],		colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_NOTCOUNTING"], 	tooltipText = L["ICONMENU_NOTCOUNTING_DESC"],	colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	CLEUEvents = true,
	CLEUDur = true,
	SourceUnit = true,
	DestUnit = true,
	SourceFlags = true,
	DestFlags = true,
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

local EventsWithoutSpells = {
	ENCHANT_APPLIED = true,
	ENCHANT_REMOVED = true,
	SWING_DAMAGE = true,
	SWING_MISSED = true,
	UNIT_DIED = true,
	UNIT_DESTROYED = true,
	UNIT_DISSIPATES = true,
	PARTY_KILL = true,
	ENVIRONMENTAL_DAMAGE = true,
}

local function CLEU_OnEvent(icon, _, t, event, h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3, arg4, arg5, ...)

	if event == "SPELL_MISSED" and arg4 == "REFLECT" then
		-- make a fake event for spell reflects
		event = "SPELL_REFLECT"
		
		-- swap the source and the destination
		local a, b, c, d = sourceGUID, sourceName, sourceFlags, sourceRaidFlags
		sourceGUID, sourceName, sourceFlags, sourceRaidFlags = destGUID, destName, destFlags, destRaidFlags
		destGUID, destName, destFlags, destRaidFlags = a, b, c, d
	elseif event == "SPELL_INTERRUPT" then
		-- fake an event that allow filtering based on the spell that caused an interrupt rather than the spell that was interrupted.
		-- fire it in addition to, not in place of, SPELL_INTERRUPT
		CLEU_OnEvent(icon, _, t, "SPELL_INTERRUPT_SPELL", h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3, arg4, arg5, ...)
	end
	
	if icon.AllowAnyEvents or icon.CLEUEvents[event] then
	
		if sourceName and sourceFlags and icon.SourceFlags then
			if bit_band(icon.SourceFlags, sourceFlags) ~= sourceFlags then
				return
			end
		end
		
		if destName and destFlags and icon.DestFlags then
			if bit_band(icon.DestFlags, destFlags) ~= destFlags then
				return
			end
		end
		
		local SourceUnits = icon.SourceUnits
		local sourceUnit = sourceName
		if SourceUnits and sourceName then
			local matched
			for i = 1, #SourceUnits do
				local unit = SourceUnits[i]
				local sourceName = strlowerCache[sourceName]
				if unit == sourceName then -- match by name
					matched = 1
					break
				elseif UnitGUID(unit) == sourceGUID then
					destUnit = unit -- replace with the actual unitID
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
				if unit == destName then -- match by name
					matched = 1
					break
				elseif UnitGUID(unit) == destGUID then
					destUnit = unit -- replace with the actual unitID
					matched = 1
					break
				end
			end
			if not matched then
				return
			end
		end
		
		--local spellID, spellName = arg1, arg2 -- this may or may not be true, depends on the event
			
		local tex, spellID, spellName, extraID, extraName
		if event == "SWING_DAMAGE" or event == "SWING_MISSED" then
			spellName = ACTION_SWING
			-- dont define spellID here so that ACTION_SWING will be used in %s substitutions
			tex = GetSpellTexture(6603)
		elseif event == "ENCHANT_APPLIED" or event == "ENCHANT_REMOVED" then
			spellID = arg1
			spellName = arg2
			tex = GetItemIcon(arg2)
		elseif event == "SPELL_INTERRUPT" or event == "SPELL_DISPEL" or event == "SPELL_DISPEL_FAILED" or event == "SPELL_STOLEN" then
			extraID = arg1 -- the spell used (kick, cleanse, spellsteal)
			extraName = arg2
			spellID = arg4 -- the other spell (polymorph, greater heal, arcane intellect, corruption)
			spellName = arg5
			tex = SpellTextures[spellID]
		elseif event == "SPELL_AURA_BROKEN_SPELL" or event == "SPELL_INTERRUPT_SPELL" then
			extraID = arg4 -- the spell that broke it
			extraName = arg5
			spellID = arg1 -- the spell that was broken
			spellName = arg2
			tex = SpellTextures[spellID]
		elseif event == "ENVIRONMENTAL_DAMAGE" then
			spellName = _G["ACTION_ENVIRONMENTAL_DAMAGE_" .. arg1]
			tex = EnvironmentalTextures[arg1] or "Interface\\Icons\\INV_Misc_QuestionMark" -- arg1 is
		elseif event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "UNIT_DISSIPATES" or event == "PARTY_KILL" then
			spellName = L["CLEU_DIED"]
			tex = "Interface\\Icons\\Ability_Rogue_FeignDeath"
			if not sourceUnit then
				sourceUnit = destUnit -- clone it
			end
		else
			spellID = arg1
			spellName = arg2
			--[[--"RANGE_DAMAGE", -- normal
			--"RANGE_MISSED", -- normal
			--"SPELL_DAMAGE", -- normal
			--"SPELL_MISSED", -- normal
			--"SPELL_REFLECT", -- normal BUT  NOT ACTUALLY AN EVENT
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
			--"SPELL_CAST_FAILED" -- normal
			--"SPELL_CAST_START" -- normal
			--"SPELL_CAST_SUCCESS" -- normal
			]]
		end
		tex = tex or SpellTextures[spellID] or SpellTextures[spellName] -- [spellName] should never be used, but whatever
	
		local NameHash = icon.NameHash
		local duration
		if NameHash and not EventsWithoutSpells[event] then
			local key = (NameHash[spellID] or NameHash[strlowerCache[spellName]])
			if not key then
				return
			else
				duration = icon.Durations[key]
				if duration == 0 then
					duration = nil
				end
			end
		end
		
		-- bind text updating
		if icon.cleu_sourceUnit ~= sourceUnit and icon.UpdateBindText_SourceUnit then
			icon:UpdateBindText()
		elseif icon.cleu_destUnit ~= destUnit and icon.UpdateBindText_DestUnit then
			icon:UpdateBindText()
		elseif icon.cleu_extraSpell ~= extraID and icon.UpdateBindText_ExtraSpell then
			icon:UpdateBindText()
		end
		
		icon.cleu_start = TMW.time
		icon.cleu_duration = duration or icon.CLEUDur
		icon.cleu_spell = spellID or spellName -- perfer ID over name, but events without real names (DIED, ENVIRONMENTAL_DAMAGE, SWING) dont have spellIDs, so pass the spellName the be displayed on the icon
		
		icon.cleu_sourceUnit = sourceUnit 
		icon.cleu_destUnit = destUnit 
		icon.cleu_extraSpell = extraID 
		
		if icon.OnCLEUEvent then
			icon.EventsToFire.OnCLEUEvent = true
		end
		
		icon:Update(TMW.time, true, tex)
			
		-- all checks complete. procede to do shit.
		--print(CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, t, event, h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3, arg4, ...))
	--	print("Event Passed", spellName, sourceName, destName, event)
	end
end

local function CLEU_OnUpdate(icon, time, tex)
	-- tex is passed in when calling from OnEvent, otherwise its nil (causing there to be no update)
	
	local start = icon.cleu_start
	local duration = icon.cleu_duration

	--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	if time - start > duration then
		local color = icon:CrunchColor()
		
		icon:SetInfo(icon.UnAlpha, color, tex, 0, 0, icon.cleu_spell, nil, nil, nil, nil, icon.cleu_destUnit or icon.cleu_sourceUnit)
	else
		local color = icon:CrunchColor(duration)
		
		icon:SetInfo(icon.Alpha, color, tex, start, duration, icon.cleu_spell, nil, nil, nil, nil, icon.cleu_destUnit or icon.cleu_sourceUnit)
	end
	
	icon.LastUpdate = time -- sometimes we call this function whenever the hell we want ("OnEvent"), so at least have the decency to delay the next update
end

function Type:Setup(icon, groupID, iconID)
	icon.NameHash = icon.Name ~= "" and TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)	
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)
	
	-- only define units if there are any units. we dont want to waste time iterating an empty table.
	icon.SourceUnits = icon.SourceUnit ~= "" and TMW:GetUnits(icon, icon.SourceUnit)
	icon.DestUnits = icon.DestUnit ~= "" and TMW:GetUnits(icon, icon.DestUnit)
	
	-- nil out flags if they are set to default (2^32-1)
	icon.SourceFlags = icon.SourceFlags ~= 2^32-1 and icon.SourceFlags
	icon.DestFlags = icon.DestFlags ~= 2^32-1 and icon.DestFlags
	
	-- more efficient than checking icon.CLEUEvents[""] every OnEvent
	icon.AllowAnyEvents = icon.CLEUEvents[""]
	
	-- check for when bind texts should be updated (these are unique to cleu, so they are handled here, not in TMW:Icon_Update()
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
	
	local tex, otherArgWhichLacksADecentName = TMW:GetConfigIconTexture(icon)
	if otherArgWhichLacksADecentName == nil then
		tex = "Interface\\Icons\\INV_Misc_PocketWatch_01"
	end
	icon:SetTexture(tex)
	
	-- type-specific data that events and OnUpdate use
	icon.cleu_start = icon.cleu_start or 0
	icon.cleu_duration = icon.cleu_duration or 0
	icon.cleu_spell = nil
	
	-- type-specific data that events use
	icon.cleu_sourceUnit = nil
	icon.cleu_destUnit = nil
	icon.cleu_extraSpell = nil
	
	-- safety mechanism
	if icon.AllowAnyEvents and not icon.SourceUnits and not icon.DestUnits and not icon.NameHash and not icon.SourceFlags and not icon.DestFlags then
		if db.profile.Locked and icon.Enabled then
			TMW.Warn(L["CLEU_NOFILTERS"]:format(L["GROUPICON"]:format(TMW:GetGroupName(groupID, groupID, 1), iconID)))
		end
		return
	end
	
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	icon:SetScript("OnEvent", CLEU_OnEvent)
	
	icon:SetScript("OnUpdate", CLEU_OnUpdate)
	icon:Update()
end


TMW:RegisterIconType(Type)