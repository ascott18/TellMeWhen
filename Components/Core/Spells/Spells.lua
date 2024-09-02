-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local type, pairs, gsub, strfind, strmatch, strsplit, strtrim, tonumber, tremove, ipairs, tinsert, CopyTable, setmetatable =
	  type, pairs, gsub, strfind, strmatch, strsplit, strtrim, tonumber, tremove, ipairs, tinsert, CopyTable, setmetatable
local tconcat = table.concat
local GetSpellName = TMW.GetSpellName
local GetSpellInfo = TMW.GetSpellInfo
local GetSpellTexture = TMW.GetSpellTexture

local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("player")





---------------------------------
-- Spell String Parsing Functions
---------------------------------

-- These functions are as old as TMW itself (except for duration stuff). They have changed much over the years,
-- but they're one of the few things that are still here in some form.


local function splitSpellAndDuration(str)
	-- A space is optionally allowed before the semicolon 
	-- to support French, which likes spaces around semicolons.
	local spell, duration = strmatch(str, "(.-)%s?:([%d:%s%.]*)$")
	if not spell then
		return str, 0
	end
	if not duration then
		duration = 0
	else
		duration = tonumber( TMW.toSeconds(duration:trim(" :;.")) )
	end

	return spell:trim(" "), duration
end

local function parseSpellsString(setting, doLower, keepDurations)

	local spells = TMW:SplitNames(setting) -- Get a table of everything

	--INSERT EQUIVALENCIES
	--start at the end of the table, that way we dont have to worry
	--about increasing the key of spells to work with every time we insert something
	local k = #spells
	while k > 0 do
		local eqtt = TMW:EquivToTable(spells[k]) -- Get the table form of the equivalency string
		if eqtt then
			local n = k	--point to start inserting the values at
			tremove(spells, k)	--take the actual equavalancey itself out, because it isnt an actual spell name or anything
			for z, x in ipairs(eqtt) do
				tinsert(spells, n, x)	--put the names into the main table
				n = n + 1	--increment the point of insertion
			end
		else
			k = k - 1	--there is no equivalency to insert, so move backwards one key towards zero to the next key
		end
	end
	
	if doLower then
		spells = TMW:LowerNames(spells)
	end

	-- REMOVE DUPLICATES
	TMW.tRemoveDuplicates(spells)


	-- Remove entries that the user has chosed to omit by using a "-" prefix.
	local k = #spells
	while k > 0 do
		local v = spells[k]
		if (type(v) == "string" and v:match("^%-")) or (type(v) == "number" and v < 0) then

			tremove(spells, k)

			local thingToRemove = tostring(v):match("^%-%s*(.*)"):lower()
			local spellToRemove, durationToRemove = splitSpellAndDuration(thingToRemove)

			local i = 1
			local removed
			while spells[i] do
				local name = tostring(spells[i]):lower()
				local spell, duration = splitSpellAndDuration(name)
				
				if spellToRemove == spell and durationToRemove == duration then
					tremove(spells, i)
					removed = true
				else
					i = i + 1
				end
			end

			if not removed then
				TMW:Printf(L["SPELL_EQUIV_REMOVE_FAILED"], thingToRemove, tconcat(spells, "; "))
			end
		else
			-- The entry was valid, so move backwards towards the beginning.
			k = k - 1
		end
	end

	-- Remove invalid SpellIDs
	for k = #spells, 1, -1 do
		local v = spells[k]
		local spell, duration = splitSpellAndDuration(v)
		if (tonumber(spell) or 0) >= 2^31 or duration >= 2^31 then
			-- Invalid spellID or duration. Remove it to prevent integer overflow errors.
			tremove(spells, k)
			TMW:Warn(L["ERROR_INVALID_SPELLID2"]:format(v))
		end
	end


	-- REMOVE SPELL DURATIONS (FOR UNIT COOLDOWNS/ICDs)
	-- THIS MUST HAPPEN LAST or else the duration array and spell array can get mismatched.
	if not keepDurations then
		for k, buffName in pairs(spells) do
			local spell, duration = splitSpellAndDuration(buffName)
			spells[k] = tonumber(spell) or spell
		end
	end

	return spells
end
parseSpellsString = TMW:MakeNArgFunctionCached(3, parseSpellsString)

-- IDs of spells that can't be tracked properly because of blizzard bugs.
local fixSpellMap = { 
	[382266] = function()
		-- Evoker https://github.com/ascott18/TellMeWhen/issues/2212
		-- Fire Breath + font of magic
		if 
			not IsPlayerSpell(382266) -- The fire breath ID reported by blizzard is actually unlearned
		and not IsPlayerSpell(408083) -- Font of magic (augmentation) talent unlearned
		and not IsPlayerSpell(411212) -- Font of magic (devastation) talent unlearned
		and not IsPlayerSpell(375783) -- Font of magic (preservation) talent unlearned
		then
			return 357208 -- Fire breath without font of magic
		end
	end,
}

local function getSpellNames(setting, doLower, firstOnly, convert, hash, allowRenaming)
	local spells = parseSpellsString(setting, doLower, false)

	-- spells MUST BE COPIED because the return from parseSpellsString is cached.
	spells = CopyTable(spells)

	if allowRenaming or convert == "id" then
		for k, v in ipairs(spells) do
			-- Doesn't matter if the input is a name or an ID.
			-- We need to map it to an ID to fix blizzard bugs

			-- As of WoW 11.0, we have to always replace spells with the result of GetOverrideSpell.
			-- Even the most simple spells like "Thrash" don't work anymore without this:
			--    GetSpellInfo("Thrash") returns spellID 106832,
			--    but the spellID that actually has Thrash's cooldown is 77758.
			--    Thrash is NOT a "replacement spell", so this is bizarre.
			--    Fortunately, GetOverrideSpell returns 77758 for both "Thrash" and 106832.

			if C_Spell and C_Spell.GetOverrideSpell then
				local spellID = C_Spell.GetOverrideSpell(v or "")
				if spellID and spellID ~= 0 then
					if fixSpellMap[spellID] then
						-- Attempt to fix blizzard bugs like https://github.com/Stanzilla/WoWUIBugs/issues/354
						local newSpell = fixSpellMap[spellID]()
						if newSpell then
							print("fixing bugged spell", v, spellID, "=>", newSpell)
							spells[k] = newSpell
						else 
							spells[k] = spellID
						end
					else
						spells[k] = spellID
					end
				end
			end
		end
	end

	if hash then
		local hash = {}
		for k, v in ipairs(spells) do
			if convert == "name" and (allowRenaming or tonumber(v)) then
				v = GetSpellName(v or "") or v -- Turn the value into a name if needed
			end

			if doLower then
				v = TMW:LowerNames(v)
			end

			-- Put the final value in the table as well (may or may not be the same as the original value).
			-- Value should be NameArrray's key, for use with the duration table.
			hash[v] = k	
		end
		return hash
	end

	if convert == "name" then
		if firstOnly then
			-- Turn the first value into a name and return it
			local ret = spells[1] or ""
			if (allowRenaming or tonumber(ret)) then
				ret = GetSpellName(ret) or ret 
			end

			if doLower then
				ret = TMW:LowerNames(ret)
			end

			return ret
		else
			-- Convert everything to a name
			for k, v in ipairs(spells) do
				if (allowRenaming or tonumber(v)) then
					spells[k] = GetSpellName(v or "") or v 
				end
			end

			if doLower
				then TMW:LowerNames(spells)
			end

			return spells
		end
	end

	if firstOnly then
		local ret = spells[1] or ""
		return ret
	end

	return spells
end

local function getSpellDurations(setting)
	local NameArray = parseSpellsString(setting, false, true)

	local DurationArray = CopyTable(NameArray)

	-- EXTRACT SPELL DURATIONS
	for k, buffName in pairs(NameArray) do
		local dur = strmatch(buffName, ".-:([%d:%s%.]*)$")
		if not dur then
			DurationArray[k] = 0
		else
			DurationArray[k] = tonumber( TMW.toSeconds(dur:trim(" :;.")) )
		end
	end

	return DurationArray
end






---------------------------------
-- TMW.C.SpellSet
---------------------------------

local tableArgs = {
	--						lower,	first,	toName,	hash
	First				= { 1,		1,		nil,	nil	},
	FirstString			= { 1,		1,		"name",	nil },
	FirstId			    = { 1,		1,		"id",	nil },
	Array				= { 1,		nil,	nil,	nil },
	StringArray			= { 1,		nil,	"name",	nil	},
	Hash				= { 1,		nil,	nil, 	1	},
	StringHash			= { 1,		nil,	"name",	1	},

	--						lower,	first,	toName,	hash
	FirstNoLower		= { nil,	1,		nil,	nil },
	FirstStringNoLower	= { nil,	1,		"name",	nil	},
	ArrayNoLower		= { nil,	nil,	nil,	nil	},
	StringArrayNoLower	= { nil,	nil,	"name",	nil	},
	HashNoLower			= { nil,	nil,	nil, 	1	},
	StringHashNoLower	= { nil,	nil,	"name",	1	},

	-- DUrations is kept in this table because it should also be cleared
	-- every time the cache needs to be reset (handled in the :Wipe() method).
	-- It is handled specially, though.
	Durations = true,
}
local __index_old = nil

local RenamingSpellSetInstances = {}
setmetatable(RenamingSpellSetInstances, {__mode='kv'})

TMW:NewClass("SpellSet"){
	OnFirstInstance = function(self)
		self:MakeInstancesWeak()

		__index_old = self.instancemeta.__index
		local meta = {}
		for k, v in pairs(self.instancemeta) do
			meta[k] = v
		end
		meta.__index = self.__index
		
		self.betterMeta = meta
	end,

	OnNewInstance = function(self, name, allowRenaming)
	 	allowRenaming = not not allowRenaming -- make sure its a boolean

		self.Name = name
		self.AllowRenaming = allowRenaming
		if allowRenaming then
			RenamingSpellSetInstances[self] = true
		end
		setmetatable(self, self.betterMeta)
	end,

	__index = function(self, k)
		local v = __index_old[k]
		if v then
			return v
		end
		
		if k == "Durations" then
			self[k] = getSpellDurations(self.Name)
			return self[k]
		end

		local args = tableArgs[k]
		if args then
			self[k] = getSpellNames(self.Name, args[1], args[2], args[3], args[4], self.AllowRenaming)
			return self[k]
		end
	end,

	Wipe = function(self)
		for k, v in pairs(self) do
			if tableArgs[k] then
				self[k] = nil
			end 
		end
	end,
}

TMW:MakeNArgFunctionCached(2, TMW.C.SpellSet, "New")

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- We need to wipe the stored objects/strings on every TMW_GLOBAL_UPDATE because of issues with
	-- spells that replace other spells in different specs, like Corruption/Immolate.
	-- TMW_GLOBAL_UPDATE might fire a little too often for this, but it is a surefire way to prevent issues that should
	-- hold up through out all future game updates because TMW_GLOBAL_UPDATE should always react to any changes in spec/talents/etc

	for _, instance in pairs(TMW.C.SpellSet.instances) do
		instance:Wipe()
	end
end)

if C_Spell and C_Spell.GetOverrideSpell then
	-- When spell overrides might change,
	-- we need to wipe all the data about spell overrides that are cached on SpellSet instances
	-- so the can be recalculated. For example, Void Eruption <-> Void Bolt.
	-- This used to work automatically through GetSpellCooldown prior to WoW 11.0,
	-- but now we have to manage spell overrides ourselves.
	TMW:RegisterEvent("SPELLS_CHANGED", function()
		for instance in pairs(RenamingSpellSetInstances) do
			instance:Wipe()
		end
	end)
end


--- Returns an instance of {{{TMW.C.SpellSet}}} for the given spellString.
-- The following can be accessed as members of the {{{TMW.C.SpellSet}}}:
-- * 
-- * {{{SpellSet.First}}} - The first spell in the spellString.
-- * {{{SpellSet.FirstString}}} - The first spell in the spellString, converted to a name if given as an ID.
-- * {{{SpellSet.Array}}} - An array of all spells in the spellString.
-- * {{{SpellSet.StringArray}}} - SpellSet.Array with any spellIDs converted to names.
-- * {{{SpellSet.Hash}}} - A dictionary of all spells in the spellString, with the values in the table being their index in the spellString (and their index in indexed tables of the SpellSet).
-- * {{{SpellSet.StringHash}}} - SpellSet.Hash with any spellIDs converted to names.
-- * {{{SpellSet.Durations}}} - An array of all the durations of spells in the spellString using the "Spell: Duration" syntax. Filled with zeroes for spells that don't use the duration synxtax.
-- Furthermore, all of the above, with the exception of SpellSet.Durations, may also have "NoLower" appended to prevent strlower()ing of any strings. E.g. {{{SpellSet.StringArrayNoLower}}}.

-- @arg spellString [string] A semicolon-delimited list of spells that
-- will be parsed and made available in various forms by the {{{TMW.C.SpellSet}}}.
-- @arg allowRenaming [boolean] True if the SpellSet should attempt to rename spells
-- that were inputted by name but have different names because of the player's currently learned spells.
-- @return [TMW.C.SpellSet] An instance of {{{TMW.C.SpellSet}}} for the requested spells.
function TMW:GetSpells(spellString, allowRenaming)
	TMW:ValidateType("2 (spellString)", "TMW:GetSpells(spellString, allowRenaming)", spellString, "string;number")

	-- Make sure that allowRenaming is a boolean.
	allowRenaming = not not allowRenaming

	return TMW.C.SpellSet:New(spellString, allowRenaming)
end

-- Slightly redundant with the caching on SpellSet:New,
-- but also makes things slightly faster by skipping a stack level or two.
TMW:MakeNArgFunctionCached(2, TMW, "GetSpells")





---------------------------------
-- Misc Spell Name Helper Funcs
---------------------------------

local loweredbackup = {}
--- Converts a string, or all values of a table, to lowercase. Numbers are kept as numbers.
-- The original case is saved so that it can be used by TMW:RestoreCase() to restore the capitalization of spells that have been lowered.
-- @arg str [string|table] The string or table of spell names to strlower.
-- @return Returns what was passed in after strlowering it.
function TMW:LowerNames(str)
	
	if type(str) == "table" then -- Handle a table with recursion
		for k, v in pairs(str) do
			str[k] = TMW:LowerNames(v)
		end
		return str
	end

	local str_lower = strlowerCache[str]
	-- Dispel types retain their capitalization. Restore it here.
	for ds in pairs(TMW.DS) do
		if strlowerCache[ds] == str_lower then
			return ds
		end
	end

	if type(str_lower) == "string" then
		if loweredbackup[str_lower] then
			-- Dont replace names that are proper case with names that arent.
			-- Generally, assume that strings with more capitals after non-letters are more proper than ones with less
			local _, oldcount = gsub(loweredbackup[str_lower], "[^%a]%u", "%1")
			local _, newcount = gsub(str, "[^%a]%u", "%1")

			-- Check the first letter of each string for a capital
			if strfind(loweredbackup[str_lower], "^%u") then
				oldcount = oldcount + 1
			end
			if strfind(str, "^%u") then
				newcount = newcount + 1
			end

			-- The new string has more than the old, so use it instead
			if newcount > oldcount then
				loweredbackup[str_lower] = str
			end
		else
			-- There wasn't a string before, so set the base
			loweredbackup[str_lower] = str
		end
	end

	return str_lower
end

--- Attempts to restore the capitalization of a spell name that has been strlowered.
-- Numbers are returned immediately. Otherwise, the cache of lowered names from TMW:LowerNames() 
-- is checked, and if it isn't in there, TMW.strlowerCache is scanned for an original string.
function TMW:RestoreCase(str)
	if type(str) == "number" then
		return str
	elseif loweredbackup[str] then
		return loweredbackup[str], str
	else
		for original, lowered in pairs(strlowerCache) do
			if lowered == str then
				return original, str
			end
		end
		return str
	end
end

--- Generates a table of all the spells contained in a spell equivalency.
-- @arg name [string] The equivalency to generate a table for.
-- @return Returns the table of all the spells of the equivalency if it was valid, or nil if it wasn't.
function TMW:EquivToTable(name)

	-- Everything in this function is handled as lowercase to prevent issues with user input capitalization.
	-- DONT use TMW:LowerNames() here, because the input is not the output
	name = strlowerCache[name]


	-- See if the string being checked has a duration attached to it
	-- (It really shouldn't because there is currently no point in doing so,
	-- But a user did try this and made a bug report, so I fixed it anyway
	local eqname, duration = strmatch(name, "(.-):([%d:%s%.]*)$") 

	-- If there was a duration, then replace the old name with the actual name without the duration attached
	name = eqname or name 

	local tbl

	-- Iterate over all of TMW.BE's sub-categories ('buffs', 'debuffs', 'casts', etc)
	for k, v in pairs(TMW.BE) do
		-- Iterate over each equivalency in the category
		for equiv, t in pairs(v) do
			if strlowerCache[equiv] == name then
				-- We found a matching equivalency, so stop searching.
				tbl = t
				break
			end
		end
		if tbl then break end
	end

	-- If we didnt find an equivalency string then get out
	if not tbl then return end

	-- For each spell in the equivalency:
	for a, b in pairs(tbl) do
		-- Take off trailing spaces
		local new = strtrim(b) 

		-- Make sure it is a number if it can be
		new = tonumber(new) or new 

		-- Tack on the duration that should be applied to all spells if there was a duration
		if duration then 
			new = new .. ":" .. duration
		end

		-- Done. Stick the new value in the return table.
		tbl[a] = new
	end

	return tbl
end
TMW:MakeSingleArgFunctionCached(TMW, "EquivToTable")













---------------------------------
-- Constant spell data
---------------------------------
if TMW.isCata then
	if pclass == "PALADIN" then
		local name = GetSpellName(26573) 
		TMW.COMMON.CurrentClassTotems = {
			name = name,
			desc = L["ICONMENU_TOTEM_GENERIC_DESC"]:format(name),
			{
				hasVariableNames = false,
				name = GetSpellName(26573), --consecration
				texture = GetSpellTexture(26573)
			}
		}
	elseif pclass == "DEATHKNIGHT" then
		local npcName = function(npcID)
			local cachedName = TMW:TryGetNPCName(npcID)
			return function()
				if cachedName then return cachedName end
				cachedName = TMW:TryGetNPCName(npcID)
				return cachedName
			end
		end
		local name = GetSpellName(46584)
		TMW.COMMON.CurrentClassTotems = {
			name = name,
			desc = function() return L["ICONMENU_TOTEM_GENERIC_DESC"]:format(name) end,
			texture = GetSpellTexture(49206),
			[1] = { -- Risen Ghoul
				hasVariableNames = false,
				name = npcName(26125),
				texture = GetSpellTexture(46584),
			},
			-- Ebon Gargoyle is NOT a totem in cata
		}
	elseif pclass == "SHAMAN" then
		TMW.COMMON.CurrentClassTotems = {
			name = L["ICONMENU_TOTEM"],
			desc = L["ICONMENU_TOTEM_DESC"],
			{
				hasVariableNames = true,
				name = L["FIRE"],
				texture = GetSpellTexture(8227), -- flametongue
			},
			{
				hasVariableNames = true,
				name = L["EARTH"],
				texture = GetSpellTexture(8072), -- stoneskin
			},
			{
				hasVariableNames = true,
				name = L["WATER"],
				texture = GetSpellTexture(5675), -- mana spring
			},
			{
				hasVariableNames = true,
				name = L["AIR"],
				texture = GetSpellTexture(8512), -- windfury
			},
		}
	else
		TMW.COMMON.CurrentClassTotems = {
			name = L["ICONMENU_TOTEM"],
			desc = L["ICONMENU_TOTEM_DESC"],
			{
				hasVariableNames = true,
				name = L["GENERICTOTEM"]:format(1),
				texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
			},
			{
				hasVariableNames = true,
				name = L["GENERICTOTEM"]:format(2),
				texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
			},
			{
				hasVariableNames = true,
				name = L["GENERICTOTEM"]:format(3),
				texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
			},
			{
				hasVariableNames = true,
				name = L["GENERICTOTEM"]:format(4),
				texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
			},
			{
				hasVariableNames = true,
				name = L["GENERICTOTEM"]:format(5),
				texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
			},
		}
	end

elseif not TMW.isRetail then
	TMW.COMMON.CurrentClassTotems = {
		name = L["ICONMENU_TOTEM"],
		desc = L["ICONMENU_TOTEM_DESC"],
		{
			hasVariableNames = true,
			name = L["FIRE"],
			texture = GetSpellTexture(8227), -- flametongue
		},
		{
			hasVariableNames = true,
			name = L["EARTH"],
			texture = GetSpellTexture(8072), -- stoneskin
		},
		{
			hasVariableNames = true,
			name = L["WATER"],
			texture = GetSpellTexture(5675), -- mana spring
		},
		{
			hasVariableNames = true,
			name = L["AIR"],
			texture = GetSpellTexture(8512), -- windfury
		},
	}

	TMW.COMMON.TotemBaseNames = {}
	TMW.COMMON.TotemRanks = {}
	local numerals = {
		[1]="I",
		[2]="II",
		[3]="III",
		[4]="IV",
		[5]="V",
		[6]="VI",
		[7]="VII",
		[8]="VIII",
		[9]="IX",
		[10]="X",
		[11]="XI",
		[12]="XII",
		[13]="XIII",
		[14]="XIV",
		[15]="XV",
	}
	local function Totem(spellID, rank)
		local data = {
			spellID = spellID,
			rankNumber = rank,
			rankRoman = numerals[rank]
		}
		
		data.spellName = GetSpellName(spellID)
		if not data.spellName then
			if not TMW.isClassic then
				-- don't debug on classic - we use wrath's data and filter out totems that don't exist
				TMW:Debug("Bad totem ID: " .. spellID)
			end
			return
		end
		data.spellNameLower = strlower(data.spellName)
		data.totemName = data.spellName
		if rank > 1 then
			data.totemName = data.totemName .. " " .. numerals[rank]
		end
		data.totemNameLower = strlower(data.totemName)

		TMW.COMMON.TotemRanks[spellID] = data
		TMW.COMMON.TotemRanks[data.totemNameLower] = data

		if not TMW.COMMON.TotemBaseNames[data.spellNameLower] then
			TMW.COMMON.TotemBaseNames[data.spellNameLower] = data
			TMW.COMMON.TotemBaseNames[spellID] = data
		end
	end

	if TMW.isClassic then
		Totem(1535, 1)  -- Fire Nova Totem
		Totem(8498, 2)  -- Fire Nova Totem
		Totem(8499, 3)  -- Fire Nova Totem
		Totem(11314, 4)  -- Fire Nova Totem
		Totem(11315, 5)  -- Fire Nova Totem

		Totem(8835, 1)  -- Grace of Air Totem
		Totem(10627, 2)  -- Grace of Air Totem
		Totem(25359, 3)  -- Grace of Air Totem

		Totem(8166, 1)  -- Poison Cleansing Totem
		Totem(25908, 1)  -- Tranquil Air Totem

		Totem(10613, 2)  -- Windfury Totem
		Totem(10614, 3)  -- Windfury Totem

		Totem(15107, 1)  -- Windwall Totem
		Totem(15111, 2)  -- Windwall Totem
		Totem(15112, 3)  -- Windwall Totem
	end

	Totem(8170, 1)  -- Cleansing Totem
	Totem(2062, 1)  -- Earth Elemental Totem
	Totem(2484, 1)  -- Earthbind Totem
	Totem(2894, 1)  -- Fire Elemental Totem
	Totem(30706, 7) -- Totem of Wrath
	Totem(8143, 1)  -- Tremor Totem
	Totem(8512, 1)  -- Windfury Totem
	Totem(3738, 1)  -- Wrath of Air Totem
	Totem(8177, 1)  -- Grounding Totem
	Totem(6495, 1)  -- Sentry Totem

	Totem(8184, 1)  -- Fire Resistance Totem
	Totem(10537, 2) -- Fire Resistance Totem
	Totem(10538, 3) -- Fire Resistance Totem
	Totem(25563, 4) -- Fire Resistance Totem
	Totem(58737, 5) -- Fire Resistance Totem
	Totem(58739, 6) -- Fire Resistance Totem

	Totem(8227, 1)  -- Flametongue Totem
	Totem(8249, 2)  -- Flametongue Totem
	Totem(10526, 3) -- Flametongue Totem
	Totem(16387, 4) -- Flametongue Totem
	Totem(25557, 5) -- Flametongue Totem
	Totem(58649, 6) -- Flametongue Totem
	Totem(58652, 7) -- Flametongue Totem
	Totem(58656, 8) -- Flametongue Totem

	Totem(8181, 1)  -- Frost Resistance Totem
	Totem(10478, 2) -- Frost Resistance Totem
	Totem(10479, 3) -- Frost Resistance Totem
	Totem(25560, 4) -- Frost Resistance Totem
	Totem(58741, 5) -- Frost Resistance Totem
	Totem(58745, 6) -- Frost Resistance Totem

	Totem(5394, 1)  -- Healing Stream Totem
	Totem(6375, 2)  -- Healing Stream Totem
	Totem(6377, 3)  -- Healing Stream Totem
	Totem(10462, 4) -- Healing Stream Totem
	Totem(10463, 5) -- Healing Stream Totem
	Totem(25567, 6) -- Healing Stream Totem
	Totem(58755, 7) -- Healing Stream Totem
	Totem(58756, 8) -- Healing Stream Totem
	Totem(58757, 9) -- Healing Stream Totem

	Totem(8190, 1)  -- Magma Totem
	Totem(10585, 2) -- Magma Totem
	Totem(10586, 3) -- Magma Totem
	Totem(10587, 4) -- Magma Totem
	Totem(25552, 5) -- Magma Totem
	Totem(58731, 6) -- Magma Totem
	Totem(58734, 7) -- Magma Totem

	Totem(5675, 1)  -- Mana Spring Totem
	Totem(10495, 2) -- Mana Spring Totem
	Totem(10496, 3) -- Mana Spring Totem
	Totem(10497, 4) -- Mana Spring Totem
	Totem(25570, 5) -- Mana Spring Totem
	Totem(58771, 6) -- Mana Spring Totem
	Totem(58773, 7) -- Mana Spring Totem
	Totem(58774, 8) -- Mana Spring Totem

	Totem(16190, 1) -- Mana Tide Totem

	Totem(10595, 1) -- Nature Resistance Totem
	Totem(10600, 2) -- Nature Resistance Totem
	Totem(10601, 3) -- Nature Resistance Totem
	Totem(25574, 4) -- Nature Resistance Totem
	Totem(58746, 5) -- Nature Resistance Totem
	Totem(58749, 6) -- Nature Resistance Totem

	Totem(3599, 1)  -- Searing Totem
	Totem(6363, 2)  -- Searing Totem
	Totem(6364, 3)  -- Searing Totem
	Totem(6365, 4)  -- Searing Totem
	Totem(10437, 5) -- Searing Totem
	Totem(10438, 6) -- Searing Totem
	Totem(25533, 7) -- Searing Totem
	Totem(58699, 8) -- Searing Totem
	Totem(58703, 9) -- Searing Totem
	Totem(58704, 10) -- Searing Totem

	Totem(5730, 1)  -- Stoneclaw Totem
	Totem(6390, 2)  -- Stoneclaw Totem
	Totem(6391, 3)  -- Stoneclaw Totem
	Totem(6392, 4)  -- Stoneclaw Totem
	Totem(10427, 5) -- Stoneclaw Totem
	Totem(10428, 6) -- Stoneclaw Totem
	Totem(25525, 7) -- Stoneclaw Totem
	Totem(58580, 8) -- Stoneclaw Totem
	Totem(58581, 9) -- Stoneclaw Totem
	Totem(58582, 10) -- Stoneclaw Totem

	Totem(8071, 1)  -- Stoneskin Totem
	Totem(8154, 2)  -- Stoneskin Totem
	Totem(8155, 3)  -- Stoneskin Totem
	Totem(10406, 4) -- Stoneskin Totem
	Totem(10407, 5) -- Stoneskin Totem
	Totem(10408, 6) -- Stoneskin Totem
	Totem(25508, 7) -- Stoneskin Totem
	Totem(25509, 8) -- Stoneskin Totem
	Totem(58751, 9) -- Stoneskin Totem
	Totem(58753, 10) -- Stoneskin Totem

	Totem(8075, 1)  -- Strength of Earth Totem
	Totem(8160, 2)  -- Strength of Earth Totem
	Totem(8161, 3)  -- Strength of Earth Totem
	Totem(10442, 4) -- Strength of Earth Totem
	Totem(25361, 5) -- Strength of Earth Totem
	Totem(25528, 6) -- Strength of Earth Totem
	Totem(57622, 7) -- Strength of Earth Totem
	Totem(58643, 8) -- Strength of Earth Totem
else

	local genericTotemSlots = {
		{
			hasVariableNames = true,
			name = L["GENERICTOTEM"]:format(1),
			texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
		},
		{
			hasVariableNames = true,
			name = L["GENERICTOTEM"]:format(2),
			texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
		},
		{
			hasVariableNames = true,
			name = L["GENERICTOTEM"]:format(3),
			texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
		},
		{
			hasVariableNames = true,
			name = L["GENERICTOTEM"]:format(4),
			texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
		},
		{
			hasVariableNames = true,
			name = L["GENERICTOTEM"]:format(5),
			texture = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
		},
	}

	if pclass == "PALADIN" then
		local name = GetSpellName(26573) .. " & " .. GetSpellName(114158)
		TMW.COMMON.CurrentClassTotems = {
			name = name,
			desc = L["ICONMENU_TOTEM_GENERIC_DESC"]:format(name),
			{
				hasVariableNames = false,
				name = GetSpellName(26573), --consecration
				texture = GetSpellTexture(26573)
			},
			{
				hasVariableNames = false,
				name = GetSpellName(114158), --light's hammer
				texture = GetSpellTexture(114158)
			}
		}
	elseif pclass == "DEATHKNIGHT" then
		local npcName = function(npcID)
			local cachedName = TMW:TryGetNPCName(npcID)
			return function()
				if cachedName then return cachedName end
				cachedName = TMW:TryGetNPCName(npcID)
				return cachedName
			end
		end
		local name = GetSpellName(49206)
		TMW.COMMON.CurrentClassTotems = {
			name = name,
			desc = function() return L["ICONMENU_TOTEM_GENERIC_DESC"]:format(name) end,
			texture = GetSpellTexture(49206),
			[3] = { -- Ebon Gargoyle
				hasVariableNames = false,
				name = npcName(27829),
				texture = GetSpellTexture(49206),
			}
		}
	else
		-- This includes shamans now in Legion - the elements of totems is no longer a notion.
		TMW.COMMON.CurrentClassTotems = {
			name = L["ICONMENU_TOTEM"],
			desc = L["ICONMENU_TOTEM_DESC"],
		}
		TMW:CopyTableInPlaceUsingDestinationMeta(genericTotemSlots, TMW.COMMON.CurrentClassTotems, true)
	end

end


TMW.DS = {
	Magic 	= "Interface\\Icons\\spell_fire_immolation",
	Curse 	= "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison 	= "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}

local function ProcessEquivalencies()
	TMW.EquivOriginalLookup = {}
	TMW.EquivFullIDLookup = {}
	TMW.EquivFullNameLookup = {}
	TMW.EquivFirstIDLookup = {}

	TMW:Fire("TMW_EQUIVS_PROCESSING")
	TMW:UnregisterAllCallbacks("TMW_EQUIVS_PROCESSING")

	for dispeltype, texture in pairs(TMW.DS) do
		TMW.EquivFirstIDLookup[dispeltype] = texture
		TMW.SpellTexturesMetaIndex[strlower(dispeltype)] = texture
	end

	for category, b in pairs(TMW.BE) do
		for equiv, tbl in pairs(b) do
			TMW.EquivOriginalLookup[equiv] = CopyTable(tbl)
			TMW.EquivFirstIDLookup[equiv] = abs(tbl[1])
			TMW.EquivFullIDLookup[equiv] = ""
			TMW.EquivFullNameLookup[equiv] = ""

			-- turn all negative IDs into their localized name.
			-- When defining equavalancies, dont put a negative on every single one,
			-- but do use it for spells that do not have any other spells with the same name and different effects.

			for i, spellID in pairs(tbl) do

				local realSpellID = abs(spellID)
				local name, _, tex = GetSpellInfo(realSpellID)

				TMW.EquivFullIDLookup[equiv] = TMW.EquivFullIDLookup[equiv] .. ";" .. realSpellID
				TMW.EquivFullNameLookup[equiv] = TMW.EquivFullNameLookup[equiv] .. ";" .. (name or realSpellID)

				if spellID < 0 then

					-- name will be nil if the ID isn't a valid spell (possibly the spell was removed in a patch).
					if name then
						-- this will insert the spell name into the table of spells for capitalization restoration.
						TMW:LowerNames(name)

						-- map the spell's name and ID to its texture for the spell texture cache
						TMW.SpellTexturesMetaIndex[realSpellID] = tex
						TMW.SpellTexturesMetaIndex[TMW.strlowerCache[name]] = tex

						tbl[i] = name
					else
						TMW:Debug("Invalid spellID found: %s (%s - %s)!", realSpellID, category, equiv)

						tbl[i] = realSpellID
					end
				else
					tbl[i] = realSpellID
				end
			end

			for _, spell in pairs(tbl) do
				if type(spell) == "number" and not GetSpellName(spell) then
					TMW:Debug("Invalid spellID found: %s (%s - %s)!",
						spell, category, equiv)
				end
			end
		end
	end
end

TMW:RegisterCallback("TMW_INITIALIZE", ProcessEquivalencies)
