-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local _G = _G
local strlower, bit_band =
	  strlower, bit.band
local UnitGUID, GetSpellTexture, GetItemIcon =
	  UnitGUID, GetSpellTexture, GetItemIcon
local print = TMW.print
local SpellTextures = TMW.SpellTextures

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil at this stage of loading), so I will do it later too
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New("cleu")
Type.name = L["ICONMENU_CLEU"]
Type.desc = L["ICONMENU_CLEU_DESC"]
Type.usePocketWatch = 1
Type.AllowNoName = true
Type.spacebefore = true
Type.unitType = "name"


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("sourceUnit, sourceGUID")
Type:UsesAttributes("spell")
Type:UsesAttributes("alpha")
Type:UsesAttributes("destUnit, destGUID")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("extraSpell")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	SourceUnit				= "",
	DestUnit 				= "",
	SourceFlags				= 0xFFFFFFFF,
	DestFlags				= 0xFFFFFFFF,
	CLEUNoRefresh			= false,
	CLEUDur					= 5,
	CLEUEvents 				= {
		["*"] 				= false
	},
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME2"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "cleu",
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_COUNTING"], 	 },
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_NOTCOUNTING"],  },
})

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_CLEUOptions")

Type:RegisterIconEvent(61, "OnCLEUEvent", {
	text = L["SOUND_EVENT_ONCLEU"],
	desc = L["SOUND_EVENT_ONCLEU_DESC"],
})


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	pGUID = UnitGUID("player")
end)


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
	

	if icon.CLEUNoRefresh then
		local attributes = icon.attributes
		if TMW.time - attributes.start < attributes.duration then
			return
		end
	end
	
	if event == "SPELL_MISSED" and arg4 == "REFLECT" then
		-- make a fake event for spell reflects
		event = "SPELL_REFLECT"

		-- swap the source and the destination
		sourceGUID, sourceName, sourceFlags, sourceRaidFlags,    destGUID, destName, destFlags, destRaidFlags =
		destGUID, destName, destFlags, destRaidFlags,    sourceGUID, sourceName, sourceFlags, sourceRaidFlags
	elseif event == "SPELL_INTERRUPT" then
		-- fake an event that allow filtering based on the spell that caused an interrupt rather than the spell that was interrupted.
		-- fire it in addition to, not in place of, SPELL_INTERRUPT
		CLEU_OnEvent(icon, _, t, "SPELL_INTERRUPT_SPELL", h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3, arg4, arg5, ...)
	elseif event == "SPELL_DAMAGE" then
		local _, _, _, _, arg10 = ...
		if arg10 then
			-- fake an event that fires if there was a crit
			-- fire it in addition to, not in place of, SPELL_DAMAGE
			CLEU_OnEvent(icon, _, t, "SPELL_DAMAGE_CRIT", h, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3, arg4, arg5, ...)
		end
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
					sourceUnit = unit -- replace with the actual unitID
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
			tex = SpellTextures[6603]
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
			--	sourceUnit = destUnit -- clone it (wait, why? commenting this out because its stupid)
			end
		else
			spellID = arg1
			spellName = arg2
			--[[	Handy list of all events that should be handled here. Try to keep it updated

			--"RANGE_DAMAGE", -- normal
			--"RANGE_MISSED", -- normal
			--"SPELL_DAMAGE", -- normal
			--"SPELL_DAMAGE_CRIT", -- normal BUT NOT ACTUALLY AN EVENT
			--"SPELL_MISSED", -- normal
			--"SPELL_REFLECT", -- normal BUT NOT ACTUALLY AN EVENT
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

		TMW:Assert(tex or spellID)

		-- set the info that was obtained from the event.
		local unit, GUID
		if destUnit then
			unit, GUID = destUnit, destGUID
		else
			unit, GUID = sourceUnit, sourceGUID
		end

		icon:SetInfo(
			"start, duration; texture; spell; extraSpell; unit, GUID; sourceUnit, sourceGUID; destUnit, destGUID",
			TMW.time, duration or icon.CLEUDur,
			tex or SpellTextures[spellID],
			spellID or spellName,
			extraID,
			unit, GUID,
			sourceUnit, sourceGUID,
			destUnit, destGUID
		)

		-- do an immediate update because it might look stupid if
		-- half the icon changes on event and the other half changes on the next update cycle
		icon:Update(true)

		if icon.EventHandlersSet.OnCLEUEvent then
			icon:QueueEvent("OnCLEUEvent")
			icon:ProcessQueuedEvents()
		end
	end
end


local function CLEU_OnUpdate(icon, time)
	local attributes = icon.attributes
	local start = attributes.start
	local duration = attributes.duration

	if time - start > duration then
		icon:SetInfo(
			"alpha; start, duration",
			icon.UnAlpha,
			0, 0
		)
	else
		icon:SetInfo(
			"alpha; start, duration",
			icon.Alpha,
			start, duration
		)
	end

	--icon.LastUpdate = time -- sometimes we call this function whenever the hell we want ("OnEvent"), so at least have the decency to delay the next update (nevermind, might cause weird event behav)
end


function Type:Setup(icon, groupID, iconID)
	icon.NameHash = icon.Name ~= "" and TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)

	-- only define units if there are any units. we dont want to waste time iterating an empty table.
	icon.SourceUnits = icon.SourceUnit ~= "" and TMW:GetUnits(icon, icon.SourceUnit)
	icon.DestUnits = icon.DestUnit ~= "" and TMW:GetUnits(icon, icon.DestUnit)

	-- nil out flags if they are set to default (0xFFFFFFFF)
	icon.SourceFlags = icon.SourceFlags ~= 0xFFFFFFFF and icon.SourceFlags
	icon.DestFlags = icon.DestFlags ~= 0xFFFFFFFF and icon.DestFlags

	-- more efficient than checking icon.CLEUEvents[""] every OnEvent
	icon.AllowAnyEvents = icon.CLEUEvents[""]

	icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))

	-- safety mechanism
	if icon.AllowAnyEvents and not icon.SourceUnits and not icon.DestUnits and not icon.NameHash and not icon.SourceFlags and not icon.DestFlags then
		if TMW.Locked and icon.Enabled then
			TMW.Warn(L["CLEU_NOFILTERS"]:format(L["GROUPICON"]):format(TMW:GetGroupName(groupID, groupID, 1), iconID))
		end
		return
	end

	icon:SetUpdateMethod("manual")

	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	icon:SetScript("OnEvent", CLEU_OnEvent)

	icon:SetUpdateFunction(CLEU_OnUpdate)
	icon:Update()
end


Type:Register(200)


local Processor = TMW.Classes.IconDataProcessor:New("CLEU_SOURCEUNIT", "sourceUnit, sourceGUID")
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: sourceUnit, sourceGUID
	t[#t+1] = [[

	if attributes.sourceUnit ~= sourceUnit or attributes.sourceGUID ~= sourceGUID then
		attributes.sourceUnit = sourceUnit
		attributes.sourceGUID = sourceGUID

		TMW:Fire(CLEU_SOURCEUNIT.changedEvent, icon, sourceUnit, sourceGUID)
		doFireIconUpdated = true
	end
	--]]
end
Processor:RegisterDogTag("TMW", "Source", {
	code = function (groupID, iconID)
		local icon = TMW[groupID][iconID]
		if icon then
			if icon.Type ~= "cleu" then
				return ""
			else
				return icon.attributes.sourceUnit or ""
			end
		else
			return ""
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("CLEU_SOURCEUNIT"),
	ret = "string",
	doc = L["DT_DOC_Source"],
	example = ('[Source] => "target"; [Source(4, 5)] => %q; [Source:Name] => "Kobold"; [Source(4, 5):Name] => %q'):format(UnitName("player"), TMW.NAMES and TMW.NAMES:TryToAcquireName(UnitName("player"), true) or "???"),
	category = L["ICON"],
})

local Processor = TMW.Classes.IconDataProcessor:New("CLEU_DESTUNIT", "destUnit, destGUID")
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: destUnit, destGUID
	t[#t+1] = [[

	if attributes.destUnit ~= destUnit or attributes.destGUID ~= destGUID then
		attributes.destUnit = destUnit
		attributes.destGUID = destGUID

		TMW:Fire(CLEU_DESTUNIT.changedEvent, icon, destUnit, destGUID)
		doFireIconUpdated = true
	end
	--]]
end
Processor:RegisterDogTag("TMW", "Destination", {
	code = function (groupID, iconID)
		local icon = TMW[groupID][iconID]
		if icon then
			if icon.Type ~= "cleu" then
				return ""
			else
				return icon.attributes.destUnit or ""
			end
		else
			return ""
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
	},
	events = TMW:CreateDogTagEventString("CLEU_DESTUNIT"),
	ret = "string",
	doc = L["DT_DOC_Destination"],
	example = ('[Destination] => "target"; [Destination(4, 5)] => %q; [Destination:Name] => "Kobold"; [Destination(4, 5):Name] => %q'):format(UnitName("player"), TMW.NAMES and TMW.NAMES:TryToAcquireName(UnitName("player"), true) or "???"),
	category = L["ICON"],
})

local Processor = TMW.Classes.IconDataProcessor:New("CLEU_EXTRASPELL", "extraSpell")
-- Processor:CompileFunctionSegment(t) is default.
Processor:RegisterDogTag("TMW", "Extra", {
	code = function (groupID, iconID, link)
		local icon = TMW[groupID][iconID]
		if icon then
			if icon.Type ~= "cleu" then
				return ""
			else
				local name, checkcase = icon.typeData:FormatSpellForOutput(icon, icon.attributes.extraSpell, link)
				name = name or ""
				if checkcase and name ~= "" then
					name = TMW:RestoreCase(name)
				end
				return name
			end
		else
			return ""
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
		'link', 'boolean', false,
	},
	events = TMW:CreateDogTagEventString("CLEU_EXTRASPELL"),
	ret = "string",
	doc = L["DT_DOC_Extra"],
	example = ('[Extra] => %q; [Extra(link=true)] => %q; [Extra(4, 5)] => %q; [Extra(4, 5, true)] => %q'):format(GetSpellInfo(5782), GetSpellLink(5782), GetSpellInfo(5308), GetSpellLink(5308)),
	category = L["ICON"],
})
