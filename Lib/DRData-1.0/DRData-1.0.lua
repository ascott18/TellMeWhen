local major = "DRData-1.0"
local minor = 1009
assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

local L = {
	["Banish"] = "Banish",
	["Controlled stuns"] = "Controlled stuns",
	["Cyclone"] = "Cyclone",
	["Disarms"] = "Disarms",
	["Disorients"] = "Disorients",
	["Entrapment"] = "Entrapment",
	["Fears"] = "Fears",
	["Horrors"] = "Horrors",
	["Mind Control"] = "Mind Control",
	["Random roots"] = "Random roots",
	["Random stuns"] = "Random stuns",
	["Controlled roots"] = "Controlled roots",
	["Scatter Shot"] = "Scatter Shot",
	["Dragon's Breath"] = "Dragon's Breath",
	["Silences"] = "Silences",
	["Taunts"] = "Taunts",
	["Bind Elemental"] = "Bind Elemental",
	["Charge"] = "Charge",
	["Intercept"] = "Intercept"
}

if GetLocale() == "frFR" then
	L["Banish"] = "Bannissement"
	L["Controlled stuns"] = "Etourdissements contrôlés"
	L["Cyclone"] = "Cyclone"
	L["Disarms"] = "Désarmements"
	L["Disorients"] = "Désorientations"
	L["Entrapment"] = "Piège"
	L["Fears"] = "Peurs"
	L["Horrors"] = "Horreurs"
	L["Mind Control"] = "Contrôle mental"
	L["Random roots"] = "Immobilisations aléatoires"
	L["Random stuns"] = "Etourdissemensts aléatoires"
	L["Controlled roots"] = "Immobilisations contrôlées"
	L["Scatter Shot"] = "Flèche de dispersion"
	L["Dragon's Breath"] = "Souffle du dragon"
	L["Silences"] = "Silences"
	L["Taunts"] = "Provocations"
end

-- How long before DR resets
-- While everyone will tell you it's 15 seconds, it's actually 16 - 20 seconds with 18 being a decent enough average
Data.RESET_TIME = 18

-- List of spellID -> DR category
Data.spells = {
	--[[ TAUNT ]]--
	[  355] = "taunt", -- Taunt (Warrior)
	[53477] = "taunt", -- Taunt (Hunter tenacity pet)
	[ 6795] = "taunt", -- Growl (Druid)
	[56222] = "taunt", -- Dark Command
	[62124] = "taunt", -- Hand of Reckoning
	[31790] = "taunt", -- Righteous Defense
	[20736] = "taunt", -- Distracting Shot
	[ 1161] = "taunt", -- Challenging Shout
	[ 5209] = "taunt", -- Challenging Roar
	[57603] = "taunt", -- Death Grip
	[36213] = "taunt", -- Angered Earth -- FIXME: NPC ability ?
	[17735] = "taunt", -- Suffering (Voidwalker)
	[58857] = "taunt", -- Twin Howl (Spirit wolves)

	--[[ DISORIENTS ]]--
	[49203] = "disorient", -- Hungering Cold
	[ 6770] = "disorient", -- Sap
	[ 1776] = "disorient", -- Gouge
	[51514] = "disorient", -- Hex
	[ 9484] = "disorient", -- Shackle Undead
	[  118] = "disorient", -- Polymorph
	[28272] = "disorient", -- Polymorph (pig)
	[28271] = "disorient", -- Polymorph (turtle)
	[61305] = "disorient", -- Polymorph (black cat)
	[61025] = "disorient", -- Polymorph (serpent) -- FIXME: gone ?
	[61721] = "disorient", -- Polymorph (rabbit)
	[61780] = "disorient", -- Polymorph (turkey)
	[ 3355] = "disorient", -- Freezing Trap
	[19386] = "disorient", -- Wyvern Sting
	[20066] = "disorient", -- Repentance
	[90337] = "disorient", -- Bad Manner (Monkey) -- FIXME: to check
	[ 2637] = "disorient", -- Hibernate
	[82676] = "disorient", -- Ring of Frost

	--[[ SILENCES ]]--
	[50479] = "silence", -- Nether Shock (Nether ray)
	[ 1330] = "silence", -- Garrote
	[25046] = "silence", -- Arcane Torrent (Energy version)
	[28730] = "silence", -- Arcane Torrent (Mana version)
	[50613] = "silence", -- Arcane Torrent (Runic power version)
	[69179] = "silence", -- Arcane Torrent (Rage version)
	[80483] = "silence", -- Arcane Torrent (Focus version)
	[15487] = "silence", -- Silence
	[34490] = "silence", -- Silencing Shot
	[18425] = "silence", -- Improved Kick (rank 1)
	[86759] = "silence", -- Improved Kick (rank 2)
	[18469] = "silence", -- Improved Counterspell (rank 1)
	[55021] = "silence", -- Improved Counterspell (rank 2)
	[24259] = "silence", -- Spell Lock (Felhunter)
	[47476] = "silence", -- Strangulate
	[18498] = "silence", -- Gag Order (Warrior talent)
	[81261] = "silence", -- Solar Beam
	[31935] = "silence", -- Avenger's Shield

	--[[ DISARMS ]]--
	[91644] = "disarm", -- Snatch (Bird of Prey)
	[51722] = "disarm", -- Dismantle
	[  676] = "disarm", -- Disarm
	[64058] = "disarm", -- Psychic Horror (Disarm effect)
	[50541] = "disarm", -- Clench (Scorpid)

	--[[ FEARS ]]--
	[ 2094] = "fear", -- Blind
	[ 5782] = "fear", -- Fear (Warlock)
	[ 6358] = "fear", -- Seduction (Succubus)
	[ 5484] = "fear", -- Howl of Terror
	[ 8122] = "fear", -- Psychic Scream
	[ 1513] = "fear", -- Scare Beast
	[10326] = "fear", -- Turn Evil
	[ 5246] = "fear", -- Intimidating Shout (main target)
	[20511] = "fear", -- Intimidating Shout (secondary targets)

	--[[ CONTROL STUNS ]]--
	[89766] = "ctrlstun", -- Axe Toss (Felguard)
	[50519] = "ctrlstun", -- Sonic Blast (Bat)
	[12809] = "ctrlstun", -- Concussion Blow
	[46968] = "ctrlstun", -- Shockwave
	[  853] = "ctrlstun", -- Hammer of Justice
	[ 5211] = "ctrlstun", -- Bash
	[24394] = "ctrlstun", -- Intimidation
	[22570] = "ctrlstun", -- Maim
	[  408] = "ctrlstun", -- Kidney Shot
	[20549] = "ctrlstun", -- War Stomp
	[20252] = "ctrlstun", -- Intercept
	[20253] = "ctrlstun", -- Intercept
	[44572] = "ctrlstun", -- Deep Freeze
	[30283] = "ctrlstun", -- Shadowfury
	[ 2812] = "ctrlstun", -- Holy Wrath
	[22703] = "ctrlstun", -- Inferno Effect
	[54785] = "ctrlstun", -- Demon Leap (Warlock)
	[47481] = "ctrlstun", -- Gnaw (Ghoul)
	[93433] = "ctrlstun", -- Burrow Attack (Worm)
	[56626] = "ctrlstun", -- Sting (Wasp)
	[85388] = "ctrlstun", -- Throwdown
	[ 1833] = "ctrlstun", -- Cheap Shot
	[ 9005] = "ctrlstun", -- Pounce
	[88625] = "ctrlstun", -- Holy Word: Chastise

	--[[ RANDOM STUNS ]]--
	[64343] = "rndstun", -- Impact
	[39796] = "rndstun", -- Stoneclaw Stun
	[11210] = "rndstun", -- Improved Polymorph (rank 1)
	[12592] = "rndstun", -- Improved Polymorph (rank 2)

	--[[ ROOTS ]]--
	[33395] = "ctrlroot", -- Freeze (Water Elemental)
	[50041] = "ctrlroot", -- Chilblains
	[50245] = "ctrlroot", -- Pin (Crab)
	[  122] = "ctrlroot", -- Frost Nova
	[  339] = "ctrlroot", -- Entangling Roots
	[19975] = "ctrlroot", -- Nature's Grasp (Uses different spellIDs than Entangling Roots for the same spell)
	[51485] = "ctrlroot", -- Earth's Grasp
	[63374] = "ctrlroot", -- Frozen Power
	[ 4167] = "ctrlroot", -- Web (Spider)
	[54706] = "ctrlroot", -- Venom Web Spray (Silithid)
	[19306] = "ctrlroot", -- Counterattack
	[90327] = "ctrlroot", -- Lock Jaw (Dog)
	[11190] = "ctrlroot", -- Improved Cone of Cold (rank 1)
	[12489] = "ctrlroot", -- Improved Cone of Cold (rank 2)

	--[[ RANDOM ROOTS ]]--
	[23694] = "rndroot", -- Improved Hamstring -- FIXME: to check
	[44745] = "rndroot", -- Shattered Barrier (rank 1)
	[54787] = "rndroot", -- Shattered Barrier (rank 2)

	--[[ HORROR ]]--
	[ 6789] = "horror", -- Death Coil
	[64044] = "horror", -- Psychic Horror

	--[[ MISC ]]--
	[19503] = "scatters",      -- Scatter Shot
	[31661] = "dragons",       -- Dragon's Breath
	[  605] = "mc",            -- Mind Control
	[  710] = "banish",        -- Banish
	[19185] = "entrapment",    -- Entrapment
	[33786] = "cyclone",       -- Cyclone
	[76780] = "bindelemental", -- Bind Elemental
	[  100] = "charge",        -- Charge
	[20252] = "intercept",     -- Intercept
}

-- DR Category names
Data.categoryNames = {
	["banish"] = L["Banish"],
	["ctrlstun"] = L["Controlled stuns"],
	["cyclone"] = L["Cyclone"],
	["disarm"] = L["Disarms"],
	["disorient"] = L["Disorients"],
	["entrapment"] = L["Entrapment"],
	["fear"] = L["Fears"],
	["horror"] = L["Horrors"],
	["mc"] = L["Mind Control"],
	["rndroot"] = L["Random roots"],
	["rndstun"] = L["Random stuns"],
	["ctrlroot"] = L["Controlled roots"],
	["scatters"] = L["Scatter Shot"],
	["dragons"] = L["Dragon's Breath"],
	["silence"] = L["Silences"],
	["taunt"] = L["Taunts"],
	["bindelemental"] = L["Bind Elemental"],
	["charge"] = L["Charge"],
	["intercept"] = L["Intercept"],
}

-- Categories that have DR in PvE as well as PvP
Data.pveDR = {
	["ctrlstun"] = true,
	["rndstun"] = true,
	["taunt"] = true,
	["cyclone"] = true,
}

-- Public APIs
-- Category name in something usable
function Data:GetCategoryName(cat)
	return cat and Data.categoryNames[cat] or nil
end

-- Spell list
function Data:GetSpells()
	return Data.spells
end

-- Seconds before DR resets
function Data:GetResetTime()
	return Data.RESET_TIME
end

-- Get the category of the spellID
function Data:GetSpellCategory(spellID)
	return spellID and Data.spells[spellID] or nil
end

-- Does this category DR in PvE?
function Data:IsPVE(cat)
	return cat and Data.pveDR[cat] or nil
end

-- List of categories
function Data:GetCategories()
	return Data.categoryNames
end

-- Next DR, if it's 1.0, next is 0.50, if it's 0.[50] = "ctrlroot",next is 0.[25] = "ctrlroot",and such
function Data:NextDR(diminished)
	if( diminished == 1 ) then
		return 0.50
	elseif( diminished == 0.50 ) then
		return 0.25
	end

	return 0
end

--[[ EXAMPLES ]]--
-- This is how you would track DR easily, you're welcome to do whatever you want with the below functions

--[[
local trackedPlayers = {}
local function debuffGained(spellID, destName, destGUID, isEnemy, isPlayer)
	-- Not a player, and this category isn't diminished in PVE, as well as make sure we want to track NPCs
	local drCat = DRData:GetSpellCategory(spellID)
	if( not isPlayer and not DRData:IsPVE(drCat) ) then
		return
	end

	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	-- See if we should reset it back to undiminished
	local tracked = trackedPlayers[destGUID][drCat]
	if( tracked and tracked.reset <= GetTime() ) then
		tracked.diminished = 1.0
	end
end

local function debuffFaded(spellID, destName, destGUID, isEnemy, isPlayer)
	local drCat = DRData:GetSpellCategory(spellID)
	if( not isPlayer and not DRData:IsPVE(drCat) ) then
		return
	end

	if( not trackedPlayers[destGUID] ) then
		trackedPlayers[destGUID] = {}
	end

	if( not trackedPlayers[destGUID][drCat] ) then
		trackedPlayers[destGUID][drCat] = { reset = 0, diminished = 1.0 }
	end

	local time = GetTime()
	local tracked = trackedPlayers[destGUID][drCat]

	tracked.reset = time + DRData:GetResetTime()
	tracked.diminished = DRData:NextDR(tracked.diminished)

	-- Diminishing returns changed, now you can do an update
end

local function resetDR(destGUID)
	-- Reset the tracked DRs for this person
	if( trackedPlayers[destGUID] ) then
		for cat in pairs(trackedPlayers[destGUID]) do
			trackedPlayers[destGUID][cat].reset = 0
			trackedPlayers[destGUID][cat].diminished = 1.0
		end
	end
end

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

local eventRegistered = {["SPELL_AURA_APPLIED"] = true, ["SPELL_AURA_REFRESH"] = true, ["SPELL_AURA_REMOVED"] = true, ["PARTY_KILL"] = true, ["UNIT_DIED"] = true}
local function COMBAT_LOG_EVENT_UNFILTERED(self, event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( not eventRegistered[eventType] ) then
		return
	end

	-- Enemy gained a debuff
	if( eventType == "SPELL_AURA_APPLIED" ) then
		if( auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) ) then
			local isPlayer = ( bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER )
			debuffGained(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE), isPlayer)
		end

	-- Enemy had a debuff refreshed before it faded, so fade + gain it quickly
	elseif( eventType == "SPELL_AURA_REFRESH" ) then
		if( auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) ) then
			local isPlayer = ( bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER )
			local isHostile = (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE)
			debuffFaded(spellID, destName, destGUID, isHostile, isPlayer)
			debuffGained(spellID, destName, destGUID, isHostile, isPlayer)
		end

	-- Buff or debuff faded from an enemy
	elseif( eventType == "SPELL_AURA_REMOVED" ) then
		if( auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) ) then
			local isPlayer = ( bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER )
			debuffFaded(spellID, destName, destGUID, (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE), isPlayer)
		end

	-- Don't use UNIT_DIED inside arenas due to accuracy issues, outside of arenas we don't care too much
	elseif( ( eventType == "UNIT_DIED" and select(2, IsInInstance()) ~= "arena" ) or eventType == "PARTY_KILL" ) then
		resetDR(destGUID)
	end
end]]
