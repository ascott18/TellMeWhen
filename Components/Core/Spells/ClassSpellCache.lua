-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local _, pclass = UnitClass("Player")
local clientVersion = select(4, GetBuildInfo())
local XPac = tonumber(strsub(clientVersion, 1, 1))

TMW:RegisterDatabaseDefaults{
	global = {
		ClassSpellCache	= {
			["*"] = {},
		},
	},
}

local ClassSpellCache = TMW:NewModule("ClassSpellCache", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")

ClassSpellCache.CONST = {
	-- COMM_SLUG includes the current xpac number as a safety net to prevent corruption
	-- this really shouldn't be possible, because two people on the same server can't possibly be playing different patches,
	-- but if it ain't broke, don't fix it.
	COMM_SLUG = "TMWClassSpells" .. XPac,
}


local Cache = {}
local ClassSpellLength = {}
local PlayerSpells = {}
local ClassSpellLookup = {}

local updatePlayerSpells = 1



-- PUBLIC:

-- Contains a dictionary of spellIDs that are player spells.
function ClassSpellCache:GetSpellLookup()
	ClassSpellCache:BuildClassSpellLookup()
	
	return ClassSpellLookup
end

-- Returns a dictionary of spellIDs that (should) belong to the current player.
function ClassSpellCache:GetPlayerSpells()
	if updatePlayerSpells then
		wipe(PlayerSpells)
		for k, v in pairs(Cache[pclass]) do
			PlayerSpells[k] = 1
		end
		for k, v in pairs(Cache.PET) do
			if v == pclass then
				PlayerSpells[k] = 1
			end
		end
		local _, race = UnitRace("player")
		for k, v in pairs(Cache.RACIAL) do
			if v == race then
				PlayerSpells[k] = 1
			end
		end
		updatePlayerSpells = nil
	end
	
	return PlayerSpells
end

--[[ Returns the main cache table. Structure:
Cache = {
	[class] = {
		[spellID] = 1,
	},
	PET = {
		[spellID] = class,
	},
	RACIAL = {
		[spellID] = race,
	},
}
]]
function ClassSpellCache:GetCache()
	return Cache
end

-- END PUBLIC





-- PRIVATE:

function ClassSpellCache:TMW_DB_INITIALIZED()
	-- Wipe the spell cache if user is running a new expansion (expansions have drastic spell changes)
	if TMW.db.global.XPac_ClassSpellCache ~= XPac then
		wipe(TMW.db.global.ClassSpellCache)
		TMW.db.global.XPac_ClassSpellCache = XPac
	end
	
	Cache = TMW.db.global.ClassSpellCache
	
	-- Adds a spell's texture to the texture cache by name
	-- so that we can get textures by spell name much more frequently,
	-- reducing the usage of question mark and pocketwatch icons.
	local function AddID(id)
		local name, _, tex = GetSpellInfo(id)
		name = TMW.strlowerCache[name]
		if name and not TMW.SpellTexturesMetaIndex[name] then
			TMW.SpellTexturesMetaIndex[name] = tex
		end
	end
	
	-- Spells of the user's class should be prioritized.
	for id in pairs(Cache[pclass]) do
		AddID(id)
	end
	
	-- Next comes spells of all other classes.
	for class, tbl in pairs(Cache) do
		if class ~= pclass and class ~= "PET" then
			for id in pairs(tbl) do
				AddID(id)
			end
		end
	end
	
	-- Pets are last because there are some overlapping names with class spells
	-- and we don't want to overwrite the textures for class spells with ones for pet spells.
	for id in pairs(Cache.PET) do
		AddID(id)
	end
	
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:PLAYER_TALENT_UPDATE()
	
	self:BuildClassSpellLookup()	

	self:RegisterComm(self.CONST.COMM_SLUG)
	
	if IsInGuild() then
		self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("RCSL"), "GUILD")
	end
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:PLAYER_ENTERING_WORLD()
	
	self:RegisterEvent("UNIT_PET")
end
TMW:RegisterCallback("TMW_DB_INITIALIZED", ClassSpellCache)


------ Comm ------
local RequestedFrom = {}
local commThrowaway = {}

function ClassSpellCache:OnCommReceived(prefix, text, channel, who)
	if prefix ~= self.CONST.COMM_SLUG
	or who == UnitName("player")
	then
		return
	end
	
	local success, arg1, arg2 = self:Deserialize(text)
	
	if success then
		if arg1 == "RCSL" and not RequestedFrom[who] then
			-- Request Class Spell Length
			-- Only respond if the source player has not requested yet this session.
			
			self:BuildClassSpellLookup()
			self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("CSL", ClassSpellLength), "WHISPER", who)
			RequestedFrom[who] = true
		elseif arg1 == "CSL" then
			-- Class Spell Length
			wipe(commThrowaway)
			local RecievedClassSpellLength = arg2
			
			self:BuildClassSpellLookup()
			
			for class, length in pairs(RecievedClassSpellLength) do
				if (not ClassSpellLength[class]) or (ClassSpellLength[class] < length) then
					tinsert(commThrowaway, class)
				end
			end
			if #commThrowaway > 0 then
				self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("RCSC", commThrowaway), "WHISPER", who)
			end
			
		elseif arg1 == "RCSC" then
			-- Request Class Spell Cache
			-- arg2 is a list of requested classes/etc (HUNTER, PALADIN, RACIAL, PET, etc)
			
			TMW:Debug("RCSC from %s: %s", who, text)
			
			wipe(commThrowaway)
			for _, class in pairs(arg2) do
				commThrowaway[class] = Cache[class]
			end
			self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("CSC", commThrowaway), "WHISPER", who)
		elseif arg1 == "CSC" then
			-- Class Spell Cache
			for class, tbl in pairs(arg2) do
				for id, val in pairs(tbl) do
					Cache[class][id] = val
				end
			end
			
			self:BuildClassSpellLookup()
		end
	elseif TMW.debug then
		TMW:Error(arg1)
	end
end

function ClassSpellCache:PLAYER_ENTERING_WORLD()
	self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("RCSL"), "RAID")
	self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("RCSL"), "PARTY")
	self:SendCommMessage(self.CONST.COMM_SLUG, self:Serialize("RCSL"), "BATTLEGROUND")
end


local _, RACIAL = GetSpellInfo(20572) -- blood fury, we need the localized "Racial" string
	
function ClassSpellCache:PLAYER_TALENT_UPDATE()	
	local  _, _, _, endgeneral = GetSpellTabInfo(1)
	local _, _, offs, numspells = GetSpellTabInfo(GetNumSpellTabs())
	local _, race = UnitRace("player")
	
	for i = 1, offs + numspells do
		local type, id = GetSpellBookItemInfo(i, "player")
		if id and (type == "SPELL" or type == "FUTURESPELL") then
			local name, rank = GetSpellInfo(id)
			if rank == RACIAL then
				Cache.RACIAL[id] = race
			elseif i > endgeneral then
				Cache[pclass][id] = 1
			end
		end
	end
	
	updatePlayerSpells = 1
	self:BuildClassSpellLookup()
end

function ClassSpellCache:UNIT_PET(event, unit)
	if unit == "player" and HasPetSpells() then
		local Cache = Cache.PET
		local i = 1
		while true do
			local _, id = GetSpellBookItemInfo(i, "pet")
			if id then
				Cache[id] = pclass
			else
				break
			end
			i=i+1
		end
		
		updatePlayerSpells = 1
		self:BuildClassSpellLookup()
	end
end

function ClassSpellCache:BuildClassSpellLookup()
	for class, tbl in pairs(Cache) do
		ClassSpellLength[class] = 0
		for id in pairs(tbl) do
			ClassSpellLookup[id] = 1
			ClassSpellLength[class] = ClassSpellLength[class] + 1
		end
	end
end


-- END PRIVATE
