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
	CLEUDur					= 5,
	CLEUEvents 				= {
		["*"] 				= false
	},
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "cleu",
})

Type:RegisterConfigPanel_XMLTemplate(130, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_COUNTING"], 		tooltipText = L["ICONMENU_COUNTING_DESC"],		 },
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_NOTCOUNTING"], 	tooltipText = L["ICONMENU_NOTCOUNTING_DESC"],	 },
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

	icon:SetScript("OnUpdate", CLEU_OnUpdate)
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

local Processor = TMW.Classes.IconDataProcessor:New("CLEU_EXTRASPELL", "extraSpell")
-- Processor:CompileFunctionSegment(t) is default.


local DogTag = LibStub("LibDogTag-3.0", true)
DogTag:AddTag("TMW", "Source", {
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
	example = ('[Source] => "target"; [Source(4, 5)] => "Cybeloras"; [Source:Name] => "Kobold"; [Source(4, 5):Name] => %q'):format(TMW.NAMES:TryToAcquireName("player", true)),
	category = L["ICON"],
})
DogTag:AddTag("TMW", "Destination", {
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
	example = ('[Destination] => "target"; [Destination(4, 5)] => "Cybeloras"; [Destination:Name] => "Kobold"; [Destination(4, 5):Name] => %q'):format(TMW.NAMES:TryToAcquireName("player", true)),
	category = L["ICON"],
})
DogTag:AddTag("TMW", "Extra", {
	code = function (groupID, iconID, link)
		local icon = TMW[groupID][iconID]
		if icon then
			if icon.Type ~= "cleu" then
				return ""
			else
				local name, checkcase = icon.typeData:GetNameForDisplay(icon, icon.attributes.extraSpell, link)
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

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()

Type.CONFIG = {}
local CONFIG = Type.CONFIG

TMW.HELP:NewCode("CLEU_WHOLECATEGORYEXCLUDED", 2, false)

hooksecurefunc("UIDropDownMenu_StartCounting", function(frame)
	if TellMeWhen_CLEUOptions then
		if	UIDROPDOWNMENU_OPEN_MENU == TellMeWhen_CLEUOptions.CLEUEvents
		or	UIDROPDOWNMENU_OPEN_MENU == TellMeWhen_CLEUOptions.SourceFlags
		or	UIDROPDOWNMENU_OPEN_MENU == TellMeWhen_CLEUOptions.DestFlags
		then
			frame.showTimer = 0.5 -- i want the dropdown to hide much quicker (default is 2) after the cursor leaves it
		end
	end
end)

CONFIG.Events = {
	"",
"SPACE",

"CAT_SWING",
	"SWING_DAMAGE", -- normal
	"SWING_MISSED", -- normal
	"SPELL_EXTRA_ATTACKS", -- normal
"SPACE",
	"RANGE_DAMAGE", -- normal
	"RANGE_MISSED", -- normal


"CAT_SPELL",
	"SPELL_DAMAGE", -- normal
	"SPELL_DAMAGE_CRIT", -- normal
	"SPELL_MISSED", -- normal
	"SPELL_REFLECT", -- normal
"SPACE",
	"SPELL_CREATE", -- normal
	"SPELL_SUMMON", -- normal
"SPACE",
	"SPELL_HEAL", -- normal
	"SPELL_RESURRECT", -- normal
"SPACE",
	"SPELL_ENERGIZE", -- normal
	"SPELL_DRAIN", -- normal
	"SPELL_LEECH", -- normal
"SPACE",
	"DAMAGE_SHIELD", -- normal
	"DAMAGE_SHIELD_MISSED", -- normal


"CAT_AURA",
	"SPELL_DISPEL",-- extraSpellID/name
	"SPELL_DISPEL_FAILED",-- extraSpellID/name
	"SPELL_STOLEN",-- extraSpellID/name
"SPACE",
	"SPELL_AURA_APPLIED", -- normal
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REFRESH", -- normal
	"SPELL_AURA_REMOVED", -- normal
	"SPELL_AURA_REMOVED_DOSE",
	"SPELL_AURA_BROKEN",

	"SPELL_AURA_BROKEN_SPELL",-- extraSpellID/name
"SPACE",
	"SPELL_PERIODIC_DAMAGE",
	"SPELL_PERIODIC_DRAIN",
	"SPELL_PERIODIC_ENERGIZE",
	"SPELL_PERIODIC_LEECH",
	"SPELL_PERIODIC_HEAL",
	"SPELL_PERIODIC_MISSED",


"CAT_CAST",
	"SPELL_CAST_FAILED",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
"SPACE",
	"SPELL_INTERRUPT",-- extraSpellID/name
	"SPELL_INTERRUPT_SPELL",-- extraSpellID/name


"CAT_MISC",
	"DAMAGE_SPLIT",
"SPACE",
	"ENCHANT_APPLIED",
	"ENCHANT_REMOVED",
"SPACE",
	"ENVIRONMENTAL_DAMAGE",
"SPACE",
	"UNIT_DIED",
	"UNIT_DESTROYED",
	"SPELL_INSTAKILL",
	"PARTY_KILL",
}
CONFIG.Flags = {
					-- "COMBATLOG_OBJECT_REACTION_MASK",
    "COMBATLOG_OBJECT_REACTION_FRIENDLY",
    "COMBATLOG_OBJECT_REACTION_NEUTRAL",
    "COMBATLOG_OBJECT_REACTION_HOSTILE",

    "SPACE",		-- "COMBATLOG_OBJECT_TYPE_MASK",
    "COMBATLOG_OBJECT_TYPE_PLAYER",
    "COMBATLOG_OBJECT_TYPE_NPC",
    "COMBATLOG_OBJECT_TYPE_PET",
    "COMBATLOG_OBJECT_TYPE_GUARDIAN",
    "COMBATLOG_OBJECT_TYPE_OBJECT",

	"SPACE",		-- "COMBATLOG_OBJECT_CONTROL_MASK",
    "COMBATLOG_OBJECT_CONTROL_PLAYER",
    "COMBATLOG_OBJECT_CONTROL_NPC",

	"SPACE",		-- "COMBATLOG_OBJECT_AFFILIATION_MASK",
    "COMBATLOG_OBJECT_AFFILIATION_MINE",
    "COMBATLOG_OBJECT_AFFILIATION_PARTY",
    "COMBATLOG_OBJECT_AFFILIATION_RAID",
    "COMBATLOG_OBJECT_AFFILIATION_OUTSIDER",

	"SPACE",		--"COMBATLOG_OBJECT_SPECIAL_MASK",
	"COMBATLOG_OBJECT_TARGET",
	"COMBATLOG_OBJECT_FOCUS",
    "COMBATLOG_OBJECT_MAINTANK",
    "COMBATLOG_OBJECT_MAINASSIST",
    "COMBATLOG_OBJECT_NONE",
}
CONFIG.BetterMasks = {
	-- some of the default masks contain bits that arent used by any flags (read: they suck), so we will make our own
	COMBATLOG_OBJECT_REACTION_MASK = bit.bor(
		COMBATLOG_OBJECT_REACTION_FRIENDLY,
		COMBATLOG_OBJECT_REACTION_NEUTRAL,
		COMBATLOG_OBJECT_REACTION_HOSTILE
	),
    COMBATLOG_OBJECT_TYPE_MASK = bit.bor(
		COMBATLOG_OBJECT_TYPE_PLAYER,
		COMBATLOG_OBJECT_TYPE_NPC,
		COMBATLOG_OBJECT_TYPE_PET,
		COMBATLOG_OBJECT_TYPE_GUARDIAN,
		COMBATLOG_OBJECT_TYPE_OBJECT
	),
	COMBATLOG_OBJECT_CONTROL_MASK = bit.bor(
		COMBATLOG_OBJECT_CONTROL_PLAYER,
		COMBATLOG_OBJECT_CONTROL_NPC
	),
	COMBATLOG_OBJECT_AFFILIATION_MASK = bit.bor(
		COMBATLOG_OBJECT_AFFILIATION_MINE,
		COMBATLOG_OBJECT_AFFILIATION_PARTY,
		COMBATLOG_OBJECT_AFFILIATION_RAID,
		COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
	),
}

function CONFIG:LoadConfig()
	if TellMeWhen_CLEUOptions then
		CONFIG:Menus_SetTexts()

		CONFIG:CheckMasks()
	end
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", CONFIG.LoadConfig, CONFIG)

function CONFIG:CheckMasks()
	TMW.HELP:Hide("CLEU_WHOLECATEGORYEXCLUDED")

	for _, key in TMW:Vararg("SourceFlags", "DestFlags") do
		if key then
			for maskName, mask in pairs(CONFIG.BetterMasks) do
				if bit.band(TMW.CI.ics[key], mask) == 0 then
					local category = L["CLEU_" .. maskName]
					TMW.HELP:Show("CLEU_WHOLECATEGORYEXCLUDED", TMW.CI.ic, TellMeWhen_CLEUOptions[key], 23, 3, L["CLEU_WHOLECATEGORYEXCLUDED"], category)
					return
				end
			end
		end
	end
end

function CONFIG:CountDisabledBits(bitfield)
	local n = 0
	for _ = 1, 32 do
		local digit = bit.band(bitfield, 1)
		bitfield = bit.rshift(bitfield, 1)
		if digit == 0 then
			n = n + 1
		end
	end
	return n
end


---------- Dropdowns ----------
function CONFIG:Menus_SetTexts()
	local n = 0
	if TMW.CI.ics.CLEUEvents[""] then
		n = L["CLEU_EVENTS_ALL"]
	else
		for k, v in pairs(TMW.CI.ics.CLEUEvents) do
			if v then
				n = n + 1
			end
		end
	end
	if n == 0 then
		n = " |cFFFF5959(0)|r |TInterface\\AddOns\\TellMeWhen\\Textures\\Alert:0:2|t"
	else
		n = " (|cff59ff59" .. n .. "|r)"
	end
	UIDropDownMenu_SetText(TellMeWhen_CLEUOptions.CLEUEvents, L["CLEU_EVENTS"] .. n)

	local n = CONFIG:CountDisabledBits(TMW.CI.ics.SourceFlags)
	if n ~= 0 then
		n = " |cFFFF5959(" .. n .. ")|r"
	else
		n = " (" .. n .. ")"
	end
	UIDropDownMenu_SetText(TellMeWhen_CLEUOptions.SourceFlags, L["CLEU_FLAGS_SOURCE"] .. n)

	local n = CONFIG:CountDisabledBits(TMW.CI.ics.DestFlags)
	if n ~= 0 then
		n = " |cFFFF5959(" .. n .. ")|r"
	else
		n = " (" .. n .. ")"
	end
	UIDropDownMenu_SetText(TellMeWhen_CLEUOptions.DestFlags, L["CLEU_FLAGS_DEST"] .. n)
end

function CONFIG:EventMenu()
	local currentCategory
	for _, event in ipairs(CONFIG.Events) do
		if event:find("^CAT_") then --and event ~= currentCategory then
			if UIDROPDOWNMENU_MENU_LEVEL == 1 then
				local info = UIDropDownMenu_CreateInfo()
				info.text = L["CLEU_" .. event]
				info.value = event
				info.notCheckable = true
				info.hasArrow = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			currentCategory = event

		elseif (UIDROPDOWNMENU_MENU_LEVEL == 1 and not currentCategory) or (UIDROPDOWNMENU_MENU_LEVEL == 2 and UIDROPDOWNMENU_MENU_VALUE == currentCategory) then
			if event == "SPACE" then

				TMW.AddDropdownSpacer()
			else
				local info = UIDropDownMenu_CreateInfo()

				info.text = L["CLEU_" .. event]

				local tooltipText = rawget(L, "CLEU_" .. event .. "_DESC")
				if tooltipText then
					info.tooltipTitle = info.text
					info.tooltipText = tooltipText
					info.tooltipOnButton = true
				end

				info.value = event
				info.checked = TMW.CI.ics.CLEUEvents[event]
				info.keepShownOnClick = true
				info.isNotRadio = true
				info.func = CONFIG.EventMenu_OnClick
				info.arg1 = self

				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
		--[[if UIDROPDOWNMENU_MENU_LEVEL == 1 and v.category and not addedThings[v.category] then
			-- addedThings IN THIS CASE is a list of categories that have been added. Add ones here that have not been added yet.

			if v.categorySpacebefore then
				TMW.AddDropdownSpacer()
			end

			local info = UIDropDownMenu_CreateInfo()
			info.text = v.category
			info.value = v.category
			info.notCheckable = true
			info.hasArrow = true
			addedThings[v.category] = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end]]
	end
	--[[
	for _, event in ipairs(CONFIG.Events) do
		local info = UIDropDownMenu_CreateInfo()

		info.text = L["CLEU_" .. event]

		info.value = event
		info.checked = TMW.CI.ics.CLEUEvents[event]
		info.keepShownOnClick = true
		info.isNotRadio = true
		info.func = CONFIG.EventMenu_OnClick
		info.arg1 = self

		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end]]
end

function CONFIG:EventMenu_OnClick(frame)
	if self.value == "" and not TMW.CI.ics.CLEUEvents[""] then -- if we are checking "Any Event" then uncheck all others
		wipe(TMW.CI.ics.CLEUEvents)
		CloseDropDownMenus()
	elseif self.value ~= "" and TMW.CI.ics.CLEUEvents[""] then -- if we are checking a specific event then uncheck "Any Event"
		TMW.CI.ics.CLEUEvents[""] = false
		CloseDropDownMenus()
	end

	TMW.CI.ics.CLEUEvents[self.value] = not TMW.CI.ics.CLEUEvents[self.value]

	CONFIG:Menus_SetTexts()
	TMW.IE:ScheduleIconSetup()
end

function CONFIG:FlagsMenu()
	CONFIG:CheckMasks()

	for _, flag in ipairs(CONFIG.Flags) do
		if flag == "SPACE" then
			TMW.AddDropdownSpacer()
		else
			local info = UIDropDownMenu_CreateInfo()

			info.text = L["CLEU_" .. flag]

			info.tooltipTitle = L["CLEU_" .. flag]
			info.tooltipText = L["CLEU_" .. flag .. "_DESC"]
			info.tooltipOnButton = true

			info.value = flag
			info.checked = bit.band(TMW.CI.ics[self.flagSet], _G[flag]) ~= _G[flag]
			info.keepShownOnClick = true
			info.isNotRadio = true
			info.func = CONFIG.FlagsMenu_OnClick
			info.arg1 = self

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

function CONFIG:FlagsMenu_OnClick(frame)
	TMW.CI.ics[frame.flagSet] = bit.bxor(TMW.CI.ics[frame.flagSet], _G[self.value])

	CONFIG:CheckMasks()

	CONFIG:Menus_SetTexts()
	TMW.IE:ScheduleIconSetup()
end

end)
