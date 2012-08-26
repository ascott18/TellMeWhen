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

local clientVersion = select(4, GetBuildInfo())
local CL_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local bitband = bit.band


TMW:RegisterDatabaseDefaults{
	global = {
		AuraCache	= {
			["*"] = {},
		},
	},
}
local AuraCache = TMW:NewModule("AuraCache", "AceEvent-3.0")

local Cache
local OptionsAreLoaded


-- PUBLIC:

AuraCache.CONST = {
	AURA_TYPE_NONPLAYER = 1,
	AURA_TYPE_PLAYER = 2,
}

--[[ Returns the main cache table. Structure:
Cache = {
	[spellID] = AuraCache.CONST.AURA_TYPE_NONPLAYER,
	[spellID] = AuraCache.CONST.AURA_TYPE_PLAYER,
}
]]
function AuraCache:GetCache()
	if not Cache then
		error("AuraCache is not yet initialized", 2)
	elseif not OptionsAreLoaded then
		error("AuraCache is only designed to work when TMW_Options is loaded.", 2)
	end
	
	return Cache
end

-- END PUBLIC




-- PRIVATE:

TMW:RegisterCallback("TMW_DB_INITIALIZED", function()
	-- This is the old aura cache.
	-- Storing it directly in the DB is a terrible practice, so just start again from scratch.
	-- (Users experiencing this wipe for the first time are probably loading in fresh with MoP anyway)
	TellMeWhenDB.AuraCache = nil
	
	Cache = TMW.db.global.AuraCache
	
	-- Always be listening for new auras,
	-- store them in the main DB until the options DB is loaded.	
	AuraCache:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	-- Dump auras into the optionsDB
	TMWOptDB.AuraCache = TMWOptDB.AuraCache or {}
	
	if Cache == TMW.db.global.AuraCache then
		for k, v in pairs(Cache) do
			-- import into the options DB and take it out of the main DB
			TMWOptDB.AuraCache[k] = TMWOptDB.AuraCache[k] or v or TMWOptDB.AuraCache[k]
			Cache[k] = nil
		end
		
		-- Switch the pointer to the cache to the optionsDB
		Cache = TMWOptDB.AuraCache
	end
	
	-- Wipe the aura cache if user is running a new expansion (expansions have drastic spell changes)
	local XPac = tonumber(strsub(clientVersion, 1, 1))
	if TMWOptDB.XPac_AuraCache ~= XPac then
		wipe(TMWOptDB.AuraCache)
		TMWOptDB.XPac_AuraCache = XPac
	end
	
	OptionsAreLoaded = true
end)

function AuraCache:COMBAT_LOG_EVENT_UNFILTERED(_, _, p,_, g, _, f, _, _, _, _, _, i)
	if p == "SPELL_AURA_APPLIED" and not Cache[i] then
		if bitband(f, CL_CONTROL_PLAYER) == CL_CONTROL_PLAYER then
			Cache[i] = self.CONST.AURA_TYPE_PLAYER
		else
			Cache[i] = self.CONST.AURA_TYPE_NONPLAYER
		end
	end
end


-- END PRIVATE

