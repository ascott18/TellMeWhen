-- ---------------------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- ---------------------------------


-- ---------------------------------
-- ADDON GLOBALS AND LOCALS
-- ---------------------------------

TELLMEWHEN_VERSION = "7.2.5"

TELLMEWHEN_VERSION_MINOR = ""
local projectVersion = "@project-version@" -- comes out like "6.2.2-21-g4e91cee"
if projectVersion:find("project%-version") then
	TELLMEWHEN_VERSION_MINOR = "dev"
elseif strmatch(projectVersion, "%-%d+%-") then
	TELLMEWHEN_VERSION_MINOR = ("r%d (%s)"):format(strmatch(projectVersion, "%-(%d+)%-(.*)"))
end

TELLMEWHEN_VERSION_FULL = TELLMEWHEN_VERSION .. " " .. TELLMEWHEN_VERSION_MINOR
TELLMEWHEN_VERSIONNUMBER = 72504 -- NEVER DECREASE THIS NUMBER (duh?).  IT IS ALSO ONLY INTERNAL (for versioning of)

TELLMEWHEN_FORCECHANGELOG = 72008 -- if the user hasn't seen the changelog until at least this version, show it to them.

if TELLMEWHEN_VERSIONNUMBER > 73000 or TELLMEWHEN_VERSIONNUMBER < 72000 then
	-- safety check because i accidentally made the version number 414069 once
	return error("YOU SCREWED UP THE VERSION NUMBER OR DIDNT CHANGE THE SAFETY LIMITS")
end 

TELLMEWHEN_MAXROWS = 20

-- Put required libs here: (If they fail to load, they will make all of TMW fail to load)
local AceDB = LibStub("AceDB-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
local LibOO = LibStub("LibOO-1.0")

_G.TMW = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", "TMW", UIParent), "TellMeWhen", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0")
_G.TellMeWhen = _G.TMW
local TMW = _G.TMW

local DogTag = LibStub("LibDogTag-3.0", true)

if false then
	 -- stress testing for text widths
	local s = ""
	for i = 1, 20 do
		s = s .. i .. ", "
	end
	L = setmetatable({}, {__index = function() return s end})
end

TMW.L = L

-- Tables that will hold groups from each domain.
TMW.global = {}
TMW.profile = {}


-- Setup LibOO.
TMW.Classes = LibOO:GetNamespace("TellMeWhen")
TMW.C = TMW.Classes -- shortcut

-- These two methods are to replace the methods that used to be defined
-- directly back when LibOO was written exclusively for TMW.
function TMW:NewClass(...)
	return TMW.Classes:NewClass(...)
end
function TMW:CInit(self, ...)
	local className = self.tmwClass
	if not className then
		error("tmwClass value not defined for " .. self:GetName() or "<unnamed>.")
	end

	local class = TMW.Classes[className]
	if not class then
		error("No class found named " .. className)
	end

	class:NewFromExisting(self, ...)
end

-- Callbacks to replicate the functionality of the old events
-- that were fired by LibOO when it was written exclusively for TMW.
TMW.Classes:RegisterCallback("OnNewClass", function(event, class)
	return TMW:Fire("TMW_CLASS_NEW", class)
end)
TMW.Classes:RegisterCallback("OnNewInstance", function(event, class, instance)
	return TMW:Fire("TMW_CLASS_" .. class.className .. "_INSTANCE_NEW", class, instance)
end)




-- GLOBALS: LibStub
-- GLOBALS: TellMeWhenDB, TellMeWhen_Settings
-- GLOBALS: TELLMEWHEN_VERSION, TELLMEWHEN_VERSION_MINOR, TELLMEWHEN_VERSION_FULL, TELLMEWHEN_VERSIONNUMBER, TELLMEWHEN_MAXROWS
-- GLOBALS: UIParent, CreateFrame, collectgarbage, geterrorhandler 

---------- Upvalues ----------
local GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell =
	  GetSpellCooldown, GetSpellInfo, GetSpellTexture, IsUsableSpell
local InCombatLockdown, GetTalentInfo, GetActiveSpecGroup =
	  InCombatLockdown, GetTalentInfo, GetActiveSpecGroup
local UnitPower, UnitClass, UnitName, UnitAura =
	  UnitPower, UnitClass, UnitName, UnitAura
local IsInGuild, IsInGroup, IsInInstance =
	  IsInGuild, IsInGroup, IsInInstance
local GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn, GetBuildInfo =
	  GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn, GetBuildInfo
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, rawset, assert, pcall, error, getmetatable, setmetatable, loadstring, unpack, debugstack
local strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random =
	  strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, strjoin, max, ceil, floor, random
local _G, coroutine, table, GetTime, CopyTable =
	  _G, coroutine, table, GetTime, CopyTable
local tostringall = tostringall

---------- Locals ----------
local Locked
local UPD_INTV = 0.06	--this is a default, local because i use it in onupdate functions
local GCD = 0
local LastUpdate = 0

local time = GetTime() TMW.time = time

local clientVersion = select(4, GetBuildInfo())
local addonVersion = tonumber(GetAddOnMetadata("TellMeWhen", "X-Interface"))

local _, pclass = UnitClass("Player")







---------------------------------
-- Important Tables
---------------------------------

TMW.Types = setmetatable({}, {
	__index = function(t, k)
		-- if no type exists, then use the fallback (default) type
		return rawget(t, "")
	end
})
TMW.OrderedTypes = {}

TMW.Views = setmetatable({}, {
	__index = function(t, k)
		return rawget(t, "icon")
	end
})
TMW.OrderedViews = {}

TMW.EventList = {}

TMW.COMMON = {}

TMW.CONST = {
	GUID_SIZE = 12,
}

TMW.IconsToUpdate, TMW.GroupsToUpdate = {}, {}
local IconsToUpdate = TMW.IconsToUpdate
local GroupsToUpdate = TMW.GroupsToUpdate





---------------------------------
-- Default Settings
---------------------------------

TMW.Defaults = {
	global = {
		HelpSettings = {
		},
		HasImported			= false,
		VersionWarning		= true,
		AllowCombatConfig	= false,
		ShowGUIDs			= false,

		NumGroups			=	0,
		-- Groups = {} -- this will be set to the profile group defaults in a second.
	},
	profile = {
	--	Version			= 	TELLMEWHEN_VERSIONNUMBER,  -- DO NOT DEFINE VERSION AS A DEFAULT, OTHERWISE WE CANT TRACK IF A USER HAS AN OLD VERSION BECAUSE IT WILL ALWAYS DEFAULT TO THE LATEST
		Locked			= 	false,
		NumGroups		=	1,
		Interval		=	UPD_INTV,
		EffThreshold	=	15,
		TextureName		= 	"Blizzard",
		SoundChannel	=	"SFX",
		ReceiveComm		=	true,
		WarnInvalids	=	false,
		CheckOrder		=	-1,
		--SUG_atBeginning	=	true,
		ColorNames		=	true,
		--AlwaysSubLinks	=	false,
		ColorMSQ	 	= false,
		OnlyMSQ		 	= false,
		ColorGCD		= true,

		Colors = {
			["**"] = {
				CBC = 	{r=0,	g=1,	b=0,	Override = false,	a=1,	},	-- cooldown bar complete
				CBS = 	{r=1,	g=0,	b=0,	Override = false,	a=1,	},	-- cooldown bar start
				CBM = 	{r=1,	g=1,	b=0,	Override = false,	a=1,	},	-- cooldown bar middle

				OOR	=	{r=0.5,	g=0.5,	b=0.5,	Override = false,			},	-- out of range
				OOM	=	{r=0.5,	g=0.5,	b=0.5,	Override = false,			},	-- out of mana
				OORM=	{r=0.5,	g=0.5,	b=0.5,	Override = false,			},	-- out of range and mana

				CTA	=	{r=1,	g=1,	b=1,	Override = false,			},	-- counting with timer always
				COA	=	{r=0.5,	g=0.5,	b=0.5,	Override = false,			},	-- counting withOUT timer always
				CTS	=	{r=1,	g=1,	b=1,	Override = false,			},	-- counting with timer somtimes
				COS	=	{r=1,	g=1,	b=1,	Override = false,			},	-- counting withOUT timer somtimes

				NA	=	{r=1,	g=1,	b=1,	Override = false,			},	-- not counting always
				NS	=	{r=1,	g=1,	b=1,	Override = false,			},	-- not counting somtimes
			},
		},
		Groups 		= 	{
			["**"] = {
				GUID			= "",
				Controlled		= false,
				Enabled			= true,
				EnabledProfiles	= {
					 -- Only used by global groups
					["*"]		= true,
				},
				OnlyInCombat	= false,
				Locked			= false,
				View			= "icon",
				Name			= "",
				Strata			= "MEDIUM",
				Rows			= 1,
				Columns			= 4,
				CheckOrder		= -1,
				PrimarySpec		= true,
				SecondarySpec	= true,
				Tree1 			= true,
				Tree2 			= true,
				Tree3 			= true,
				Tree4 			= true,
				Role 			= 0x7,
				SettingsPerView	= {
					["**"] = {
					}
				},
				Icons = {
					["**"] = {
						GUID				= "",
						ShowWhen			= 0x2, -- bit order: x, x, alpha, unalpha
						Enabled				= false,
						Name				= "",
						Type				= "",
						Alpha				= 1,
						UnAlpha				= 1,
						SettingsPerView		= {
							["**"] = {
							}
						},
					},
				},
			},
		},
	},
}

TMW.Defaults.global.Groups = TMW.Defaults.profile.Groups
TMW.Group_Defaults 	 = TMW.Defaults.profile.Groups["**"]
TMW.Icon_Defaults 	 = TMW.Group_Defaults.Icons["**"]

function TMW:RegisterDatabaseDefaults(defaults)
	assert(type(defaults) == "table", "arg1 to RegisterProfileDefaults must be a table")
	
	if TMW.InitializedDatabase then
		error("Defaults are being registered too late. They need to be registered before the database is initialized.", 2)
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, TMW.Defaults)
end

function TMW:MergeDefaultsTables(src, dest)
	--src and dest must have congruent data structure, otherwise shit will blow up.
	-- There are no safety checks to prevent this.
	
	for k in pairs(src) do
		local src_type, dest_type = type(src[k]), type(dest[k])
		if dest[k] and dest_type == "table" and src_type == "table" then
			TMW:MergeDefaultsTables(src[k], dest[k])
			
		elseif dest_type ~= "nil" and src[k] ~= dest[k] then
			error(("Mismatch in merging db default tables! Setting Key: %q; Source: %q (%s); Destination: %q (%s)")
				:format(k, tostring(src[k]), src_type, tostring(dest[k]), dest_type), 3)
			
		else
			dest[k] = src[k]
		end
	end
	
	return dest -- not really needed, but what the hell why not
end





---------------------------------
-- Equivalencies & Dispel Types
---------------------------------

TMW.BE = {
	--Most of these are thanks to Malazee @ US-Dalaran's chart: http://forums.wow-petopia.com/download/file.php?mode=view&id=4979 and spreadsheet https://spreadsheets.google.com/ccc?key=0Aox2ZHZE6e_SdHhTc0tZam05QVJDU0lONnp0ZVgzdkE&hl=en#gid=18
	--Major credit to Wowhead (http://www.wowhead.com/guide=1100) for MoP spells
	--Also credit to Damien of Icy Veins (http://www.icy-veins.com/forums/topic/512-mists-of-pandaria-raid-buffs-and-debuffs/) for some MoP spells
	--Many more new spells/corrections were provided by Catok of Curse

	--NOTE: any id prefixed with "_" will have its localized name substituted in instead of being forced to match as an ID
	debuffs = {
		Silenced			= "_47476;_78675;_15487;_1330;114238;_18498;_25046;31935;31117;102051",
		ReducedHealing		= "115804",

		Stunned				= "_1833;_408;_91800;_113801;5211;22570;19577;24394;44572;_853;_20549;46968;132168;_30283;_7922;64044;91797;_25;_89766;105593;120086;117418;157997;115001;_131402;108194;117526;118905;119392;119381;118345;132169;163505",
		Incapacitated		= "99;3355;_19386;20066;_118;1776;_6770;115078;115268;107079;31661;82691;123393;_137460;88625;_51514",
		Rooted				= "_339;_122;_64695;_19387;33395;16979;45334;_87194;63685;102359;_128405;116706;107566;96294;105771;53148;_114404;170996",
		Shatterable			= "122;33395;_44572;_82691;63685;102051", -- by algus2
		Disoriented			= "31661;_2094;_51514;99;123393",
		Slowed				= "_116;_120;_13810;_5116;_8056;_3600;_1715;_12323;116095;_20170;_31589;115000;_115180;45524;50435;51490;_15407;_3409;26679;_58180;61391;44614;_7302;_63529;_15571;_7321;_7992;123586;47960;129923", -- by algus2 
		Feared				= "_5782;5246;_8122;10326;_137143;_5484;_6789;_87204",
		Bleeding			= "_1822;_1079;33745;1943;_703;_115767;_11977;106830;77758;155722;16511",
		
		CrowdControl		= "_118;33786;_1499;_19386;20066;10326;_9484;_6770;_2094;_51514;_710;_5782;_6358;_605;_82691;115078;115268;107079", -- originally by calico0 of Curse
		
	},
	buffs = {
		IncreasedMastery	= "155522;24907;19740;116956;93435;160039;128997;160073;160198",
		IncreasedHaste  	= "55610;49868;116956;113742;160003;135678;160074;128432;160203",
		IncreasedSP			= "1459;61316;109773;126309;90364;160205",
		IncreasedAP			= "57330;19506;6673",
		IncreasedStats		= "1126;20217;90363;115921;116781;159988;160017;160077;72586;160206",
		IncreasedVersatility= "55610;1126;167187;167188;159735;35290;160045;50518;57386;160077;172967",
		IncreasedMultistrike= "166916;49868;113742;109773;58604;34889;57386;24844;172968",
		BonusStamina		= "21562;166928;469;90364;160003;160014;111922;160199",
		IncreasedCrit		= "24932;1459;61316;116781;97229;24604;90309;126373;126309;160052;160200",
		BurstHaste			= "2825;32182;80353;90355;146555;160452",
		
		-- From l337g0g0 of Curse:
		DamageShield		= "_17;_11426;116849;115295;114908;110913;108416;112048;86273;114214;47753;65148;108008;1463;108366;115635;77535;145441;152118;173260;169373",
		
		ImmuneToStun		= "642;45438;48792;1022;33786;710;46924;_19263;6615",
		ImmuneToMagicCC		= "642;45438;48707;33786;710;46924;_19263;31224;8178;23920;49039;114028",
		DefensiveBuffs		= "48707;30823;33206;47585;871;48792;498;22812;61336;5277;74001;47788;_19263;6940;31850;31224;42650;86657;118038;115176;115308;120954;115295;51271;12975;97463;102342;114039",
		MiscHelpfulBuffs	= "10060;23920;68992;2983;1850;53271;1044;31821;45182;114028",
		SpeedBoosts			= "54861;121557;_2983;_61684;68992;108843;65081;118922;137573;2379;58875;133278;85499;96268;137452;111400;116841;119085;7840;5118;13159;2645;_77761",
		DamageBuffs			= "1719;12292;50334;5217;3045;77801;31884;51713;12472;57933;51271;_107574;114050;114051;113858;113861;113860;112071",
	},
	casts = {
		--prefixing with _ doesnt really matter here since casts only match by name,
		-- but it may prevent confusion if people try and use these as buff/debuff equivs
		Heals				= "5185;8936;740;2060;2061;32546;596;64843;82326;19750;77472;8004;1064;73920;124682;115175;116694;33076;120517;121135;48438;116670;114163;85222;85673",
		PvPSpells			= "33786;339;20484;982;_605;5782;5484;10326;51514;118;12051;20066",
		Tier11Interrupts	= "_83703;_82752;_82636;_83070;_79710;_77896;_77569;_80734;_82411",
		Tier12Interrupts	= "_97202;_100094",
	},
}

TMW.DS = {
	Magic 	= "Interface\\Icons\\spell_fire_immolation",
	Curse 	= "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison 	= "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}

function TMW:ProcessEquivalencies()
	for dispeltype, icon in pairs(TMW.DS) do
	--	SpellTexturesMetaIndex[dispeltype] = icon
		TMW.SpellTexturesMetaIndex[strlower(dispeltype)] = icon
	end
	
	TMW:Fire("TMW_EQUIVS_PROCESSING")
	
	TMW:UnregisterAllCallbacks("TMW_EQUIVS_PROCESSING")
	TMW.ProcessEquivalencies = nil

	-- TMW.OldBE is used by TellMeWhen_Options.lua to create some tables to allow reverse-lookups
	-- of equavalancies for things like the suggestion list.
	TMW.OldBE = CopyTable(TMW.BE)
	
	for category, b in pairs(TMW.OldBE) do
		for equiv, str in pairs(b) do

			-- turn all IDs prefixed with "_" into their localized name.
			-- When defining equavalancies, dont put a _ on every single one,
			-- but do use it for spells that do not have any other spells with the same name and different effects.
			
			while strfind(str, "_") do
				local idWithUnderscore = strmatch(str, "_%d+")
				local idWithoutUnderscore = tonumber(strmatch(str, "_(%d+)"))
				
				if idWithUnderscore then
					local name, _, tex = GetSpellInfo(idWithoutUnderscore)
					
					-- name will be nil if the ID isn't a valid spell (possibly the spell was removed in a patch).
					if name then
						-- this will insert the spell name into the table of spells for capitalization restoration.
						TMW:LowerNames(name) 
						
						-- replace the underscored spellID with the name substitution
						str = gsub(str, idWithUnderscore, name, 1)
						
						-- map the spell's name and ID to its texture for the spell texture cache
						TMW.SpellTexturesMetaIndex[idWithoutUnderscore] = tex
						TMW.SpellTexturesMetaIndex[TMW.strlowerCache[name]] = tex

					else
						
						if clientVersion >= addonVersion then -- only warn for newer clients using older versions
							TMW:Debug("Invalid spellID found: %s (%s - %s)!",
							idWithoutUnderscore, category, equiv)
						end
						
						-- substitute it back in without the underscore to prevent recusion
						str = gsub(str, idWithUnderscore, idWithoutUnderscore, 1)
					end
				end
			end
			local t = TMW:SplitNames(str)
			for _, spell in pairs(t) do
				if type(spell) == "number" and not GetSpellInfo(spell) then
					TMW:Debug("Invalid spellID found: %s (%s - %s)!",
						spell, category, equiv)
				end
			end

			TMW.BE[category][equiv] = str
		end
	end
end





---------------------------------
-- Global Cooldown Data
---------------------------------

TMW.GCDSpells = {
	ROGUE		= 1752,		-- sinister strike
	PRIEST		= 585,		-- smite
	DRUID		= 5176,		-- wrath
	WARRIOR		= 5308,		-- execute
	MAGE		= 44614,	-- frostfire bolt
	WARLOCK		= 686,		-- shadow bolt
	PALADIN		= 105361,	-- seal of command
	SHAMAN		= 403,		-- lightning bolt
	HUNTER		= 3044,		-- arcane shot
	DEATHKNIGHT = 47541,	-- death coil
	MONK		= 100780,	-- jab
}

local GCDSpell = TMW.GCDSpells[pclass]
TMW.GCDSpell = GCDSpell
TMW.GCD = 0

function TMW.OnGCD(d)
	if d == 0.001 then
		-- A cd of 0.001 is Blizzard's terrible way of indicating that something's cooldown hasn't started,
		-- but is still unusable, and has a cooldown pending. It should not be considered a GCD.
		return false
	elseif d <= 1 then
		-- A cd of 1 (or less) is always a GCD (or at least isn't worth showing)
		return true
	elseif GCD > 1.7 then
		-- Weed out a cooldown on the GCD spell that might be an interupt (counterspell, mind freeze, etc)
		return false
	else
		-- If the duration passed in is the same as the GCD spell,
		-- and the duration isnt zero, then it is a GCD
		return GCD == d and d > 0 
	end
end





---------------------------------
-- Caches
---------------------------------


TMW.strlowerCache = setmetatable(
{}, {
	__mode = "kv",
	__index = function(t, i)
		if not i then return end
		local o
		if type(i) == "number" then
			o = i
		else
			o = strlower(i)
		end
		t[i] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
}) local strlowerCache = TMW.strlowerCache

TMW.isNumber = setmetatable(
{}, {
	__mode = "kv",
	__index = function(t, i)
		if not i then return false end
		local o = tonumber(i) or false
		t[i] = o
		return o
end})


TMW.SpellTexturesMetaIndex = {
	--hack for pvp tinkets
	[42292] = "Interface\\Icons\\inv_jewelry_trinketpvp_0" .. (UnitFactionGroup("player") == "Horde" and "2" or "1"),
	[strlowerCache[GetSpellInfo(42292)]] = "Interface\\Icons\\inv_jewelry_trinketpvp_0" .. (UnitFactionGroup("player") == "Horde" and "2" or "1"),
}
local SpellTexturesMetaIndex = TMW.SpellTexturesMetaIndex

function TMW.GetSpellTexture(spell)
	if not spell then return end

	return
		GetSpellTexture(spell) or
		SpellTexturesMetaIndex[spell] or
		rawget(SpellTexturesMetaIndex, strlowerCache[spell])
end
local GetSpellTexture = TMW.GetSpellTexture




---------------------------------
-- Function Caching
---------------------------------

local cacheMetatable = {
	__mode == 'kv'
}

function TMW:MakeFunctionCached(obj, method)
	local func
	if type(obj) == "table" and type(method) == "string" then
		func = obj[method]
	elseif type(obj) == "function" then
		func = obj
	else
		error("Usage: TMW:MakeFunctionCached(object/function [, method])")
	end

	local cache = setmetatable({}, cacheMetatable)
	local wrapper = function(...)
		local cachestring = strjoin("\031", tostringall(...))
		
		if cache[cachestring] then
			return cache[cachestring]
		end

		local arg1, arg2 = func(...)
		if arg2 ~= nil then
			error("Cannot cache functions with more than 1 return arg")
		end

		cache[cachestring] = arg1

		return arg1
	end

	if type(obj) == "table" then
		obj[method] = wrapper
	end

	return wrapper, cache
end

function TMW:MakeSingleArgFunctionCached(obj, method)
	-- MakeSingleArgFunctionCached is MUCH more efficient than MakeFunctionCached
	-- and should be used whenever there is only 1 input arg
	local func, firstarg
	if type(obj) == "table" and type(method) == "string" then
		func = obj[method]
		firstarg = obj
	elseif type(obj) == "function" then
		func = obj
	else
		error("Usage: TMW:MakeFunctionCached(object/function [, method])", 2)
	end

	local cache = setmetatable({}, cacheMetatable)
	local wrapper = function(arg1In, arg2In)
		local param1, param2 = arg1In, arg2In
		if firstarg and firstarg == arg1In then
			param1 = arg1In
			arg1In = arg2In
		elseif arg2In ~= nil then
			error("Cannot MakeSingleArgFunctionCached functions with more than 1 arg", 2)
		end
		
		if cache[arg1In] then
			return cache[arg1In]
		end

		local arg1Out, arg2Out = func(param1, param2)
		if arg2Out ~= nil then
			error("Cannot cache functions with more than 1 return arg", 2)
		end

		cache[arg1In] = arg1Out

		return arg1Out
	end

	if type(obj) == "table" then
		obj[method] = wrapper
	end

	return wrapper
end





---------------------------------
-- Table Utilities
---------------------------------

function TMW.tContains(table, item, returnNum)
	local firstkey
	local num = 0
	for k, v in pairs(table) do
		if v == item then
			if not returnNum then
				-- Return only the key of the first match
				return k
			else
				num = num + 1
				firstkey = firstkey or k
			end
		end
	end

	-- Return the key of the first match and also the total number of matches
	return firstkey, num
end local tContains = TMW.tContains

function TMW.tDeleteItem(table, item, onlyOne)
	local i = 1
	local removed
	while table[i] do
		if item == table[i] then
			tremove(table, i)
			if onlyOne then
				return true
			end
			removed = true
		else
			i = i + 1
		end
	end

	return removed
end local tDeleteItem = TMW.tDeleteItem

function TMW.tRemoveDuplicates(table)

	local offs = 0

	-- Start at the end of the table so that we don't remove duplicates from the beginning
	for k = #table, 1, -1 do

		-- offs is adjusted each time something is removed so that we don't waste time
		-- searching for nil values when the table is shifted by a duplicate removal
		k = k + offs

		-- If we have reached the beginning of the table, we are done.
		if k <= 0 then
			return table
		end
		
		-- item is the value being searched for
		local item = table[k]

		-- prevIndex tracks the last index where the searched-for value was found
		local prevIndex

		-- Once again start the iteration from the end because we don't want to have to 
		-- deal with index shifting when we remove a value
		for i = #table, 1, -1 do
			if table[i] == item then

				-- We found a match. If there has already been another match, remove that match 
				-- and record this match as being the first one (closes to index 0) in the table.
				if prevIndex then
					tremove(table, prevIndex)
					offs = offs - 1
				end

				-- Queue this match for removal should we find another match closer to the beginning.
				prevIndex = i
			end
		end
	end

	-- Done. Return the table for ease-of-use.
	return table
end

function TMW.OrderSort(a, b)
	a = a.Order or a.order
	b = b.Order or b.order
	if a and b then
		return a < b
	else
		error("Missing 'order' or 'Order' key for values of OrderedTable")
	end
end
function TMW:SortOrderedTables(parentTable)
	sort(parentTable, TMW.OrderSort)
	return parentTable
end

function TMW:CopyWithMetatable(source)
	-- This is basically deepcopy without recursion prevention
	
	local dest = {}
	for k, v in pairs(source) do
		if type(v) == "table" then
			dest[k] = TMW:CopyWithMetatable(v)
		else
			dest[k] = v
		end
	end
	return setmetatable(dest, getmetatable(source))
end

function TMW:CopyTableInPlaceWithMeta(src, dest, allowUnmatchedSourceTables)
	--src and dest must have congruent data structure, otherwise shit will blow up. There are no safety checks to prevent this.
	local metatemp = getmetatable(src) -- lets not go overwriting random metatables
	setmetatable(src, getmetatable(dest))
	for k in pairs(src) do
		if type(dest[k]) == "table" and type(src[k]) == "table" then
			TMW:CopyTableInPlaceWithMeta(src[k], dest[k], allowUnmatchedSourceTables)
		elseif allowUnmatchedSourceTables and type(dest[k]) ~= "table" and type(src[k]) == "table" then
			dest[k] = {}
			TMW:CopyTableInPlaceWithMeta(src[k], dest[k], allowUnmatchedSourceTables)
		elseif type(src[k]) ~= "table" then
			dest[k] = src[k]
		end
	end
	setmetatable(src, metatemp) -- restore the old metatable
	return dest -- not really needed, but what the hell why not
end

function TMW:DeepCompare(t1, t2, ...)
	-- heavily modified version of http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3

	-- attempt direct comparison
	if t1 == t2 then
		return true, ...
	end

	-- if the values are not the same (they made it through the check above) AND they are not both tables, then they cannot be the same, so exit.
	local ty1 = type(t1)
	if ty1 ~= "table" or ty1 ~= type(t2) then
		return false, ...
	end

	-- compare table values

	-- compare table 1 with table 2
	for k1, v1 in pairs(t1) do
		local v2 = t2[k1]

		-- don't bother calling DeepCompare on the values if they are the same - it will just return true.
		-- Only call it if the values are different (they are either 2 tables, or they actually are different non-table values)
		-- by adding the (v1 ~= v2) check, efficiency is increased by about 300%.
		if v1 ~= v2 and not TMW:DeepCompare(v1, v2, k1, ...) then

			-- it only reaches this point if there is a difference between the 2 tables somewhere
			-- so i dont feel bad about calling DeepCompare with the same args again
			-- i need to because the key of the setting that changed is in there, and AttemptBackup needs that key
			return TMW:DeepCompare(v1, v2, k1, ...)
		end
	end

	-- compare table 2 with table 1
	for k2, v2 in pairs(t2) do
		local v1 = t1[k2]

		-- see comments for t1
		if v1 ~= v2 and not TMW:DeepCompare(v1, v2, k2, ...) then
			return TMW:DeepCompare(v1, v2, k2, ...)
		end
	end

	return true, ...
end




---------------------------------
-- Output & Errors
---------------------------------

TMW.Print = TMW.Print or _G.print
TMW.Warn = setmetatable(
{}, {
	__call = function(tbl, text)
		if tbl[text] then
			return
		elseif TMW.Warned then
			TMW:Print(text)
			tbl[text] = true
		elseif not TMW.tContains(tbl, text) then
			tinsert(tbl, text)
		end
end})

function TMW:DoInitialWarn()
	for k, v in ipairs(TMW.Warn) do
		TMW:Print(v)
		TMW.Warn[k] = true
	end
	
	TMW.Warned = true
	TMW.DoInitialWarn = TMW.NULLFUNC
end

function TMW.print(...)
	if TMW.debug or not TMW.Initialized or TELLMEWHEN_VERSION_MINOR == "dev" then
		local prefix = "|cffff0000TMW"
		-- GLOBALS: linenum
		if linenum then
		--	prefix = prefix..format(" %4.0f", linenum(3))
			prefix = format("|cffff0000 %s", linenum(3, 1))
		end

		prefix = prefix..":|r "
		local func = TMW.debug and TMW.debug.print or _G.print
		if ... == TMW then
			prefix = "s" .. prefix
			func(prefix, select(2,...))
		else
			func(prefix, ...)
		end
	end
	return ...
end
local print = TMW.print

function TMW:Debug(...)
	if TMW.debug or not TMW.Initialized then
		TMW.print(format(...))
	end
end

function TMW:Error(text, ...)
	text = text or ""
	local success, result = pcall(format, text, ...)
	if success then
		text = result
	end
	geterrorhandler()("TellMeWhen: " .. text)
end

function TMW:Assert(statement, text, ...)
	if not statement then
		text = text or "Assertion Failed!"
		local success, result = pcall(format, text, ...)
		if success then
			text = result
		end
		geterrorhandler()("TellMeWhen: " .. text)
	end
end

function TMW:ValidateType(argN, methodName, var, reqType)
	local varType = type(var)
	
	local isGood, foundMatch = true, false
	for _, reqType in TMW:Vararg(strsplit(";", reqType)) do
		-- Upvalue varType here so that we can change it within the loop body
		-- without having to redefine it for the references outside the loop.
		local varType = varType

		local negate = reqType:sub(1, 1) == "!"
		local reqType = negate and reqType:sub(2) or reqType
		reqType = reqType:trim(" ")
		
		if varType == "table" then
			if type(rawget(var, 0)) == "userdata" then
				if reqType == "frame" or reqType == "widget" then
					varType = reqType
				elseif var:IsObjectType(reqType) then
					varType = reqType
				end
			end
			if TMW.C[reqType] then
				local varMeta = getmetatable(var)
				if varMeta and varMeta.__index and varMeta.__index.isLibOOInstance then
					local reqClass = TMW.C[reqType]
					if var.class == reqClass or var.class.inherits[reqClass] then
						varType = reqType
					end
				end
			end
		end
		
		if negate then
			if varType == reqType then
				isGood = false
				break
			else
				foundMatch = true
			end
		else
			if varType == reqType then
				foundMatch = true
			end
		end
	end

	if not isGood or not foundMatch then
	
		local varTypeName = varType
		if varType == "table" then
			local varMeta = getmetatable(var)
			if varMeta and varMeta.__index and varMeta.__index.isLibOOInstance then
				varTypeName = "TMW.C." .. var.className
			elseif type(rawget(var, 0)) == "userdata" then
				varTypeName = "frame (" .. var:GetObjectType() .. ")"
			end
		end


		error(("Bad argument #%s to %q. %s expected, got %s (%s)"):format(argN, methodName, reqType, varTypeName, tostring(var) or "[noval]"), 3)
	end
end





---------------------------------
-- Misc. Utilities
---------------------------------

function TMW.get(value, ...)
	local type = type(value)
	if type == "function" then
		return value(...)
	elseif type == "table" then
		return value[...]
	else
		return value
	end
end

function TMW.NULLFUNC()
	-- Do nothing
end

function TMW.oneUpString(string)
	if string:find("%d+") then
		local num = tonumber(string:match("(%d+)"))
		if num then
			string = string:gsub(("(%d+)"), num + 1, 1)
			return string
		end
	end
	return string .. " 2"
end

TMW.CompareFuncs = {
	-- actually more efficient than a big elseif chain.
	["=="] = function(a, b) return a == b  end,
	["~="] = function(a, b) return a ~= b end,
	[">="] = function(a, b) return a >= b end,
	["<="] = function(a, b) return a <= b  end,
	["<"] = function(a, b) return a < b  end,
	[">"] = function(a, b) return a > b end,
}

do	-- TMW.safecall
	--[[
		xpcall safecall implementation
	]]
	local xpcall = xpcall

	local function errorhandler(err)
		return geterrorhandler()(err)
	end

	local function CreateDispatcher(argCount)
		local code = [[
			local xpcall, eh = ...
			local method, ARGS
			local function call() return method(ARGS) end
		
			local function dispatch(func, ...)
				method = func
				if not method then return end
				ARGS = ...
				return xpcall(call, eh)
			end
		
			return dispatch
		]]
		
		local ARGS = {}
		for i = 1, argCount do ARGS[i] = "arg"..i end
		ARGS = table.concat(ARGS, ", ")
		code = code:gsub("ARGS", ARGS)
		return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
	end

	local Dispatchers = setmetatable({}, {__index=function(self, argCount)
		local dispatcher = CreateDispatcher(argCount)
		rawset(self, argCount, dispatcher)
		return dispatcher
	end})
	Dispatchers[0] = function(func)
		return xpcall(func, errorhandler)
	end

	function TMW.safecall(func, ...)
		-- I don't check if func is a function here because i hope that whoever calls it
		-- is smart enough not to do stupid shit. If they arent, they will figure it out when it errors.
		--  if type(func) == "function" then
			return Dispatchers[select('#', ...)](func, ...)
		-- end
	end
end
local safecall = TMW.safecall



-- This code is here to prevent other addons from resetting
-- the high-precision timer. It isn't fool-proof (if someone upvalues debugprofilestart
-- then this won't have an effect on calls to that upvalue), but it helps.
local start_old = debugprofilestart
local lastReset = 0
function _G.debugprofilestart()
	lastReset = lastReset + debugprofilestop()

	return start_old()
end

function _G.debugprofilestop_SAFE()
	return debugprofilestop() + lastReset    
end
local debugprofilestop = debugprofilestop_SAFE





---------------------------------
-- Iterator Functions
---------------------------------

do -- InNLengthTable
	local states = {}
	local function getstate(k, t)
		local state = wipe(tremove(states) or {})

		state.k = k
		state.t = t

		return state
	end

	local function iter(state)
		state.k = state.k + 1

		if state.k > (state.t.n or #state.t) then -- #t enables iteration over tables that have not yet been upgraded with an n key (i.e. imported data from old versions)
			tinsert(states, state)
			return
		end
	--	return state.t[state.k], state.k --OLD, STUPID IMPLEMENTATION
		return state.k, state.t[state.k]
	end

	--- Iterates over an array-style table that has a key "n" to indicate the length of the table.
	-- Returns (key, value) pairs for each iteration.
	function TMW:InNLengthTable(arg)
		if arg then
			return iter, getstate(0, arg)
		else
			error("Bad argument #1 to 'TMW:InNLengthTable(arg)'. Expected table, got nil.", 2)
		end
	end
end

do -- InIconSettings
	local states = {}
	local function getstate(domain, groupID)
		local state = wipe(tremove(states) or {})

		if not (domain and groupID) then
			state.gsIter, state.gsState = TMW:InGroupSettings()
			state.groupSettings, state.domain, state.groupID = state.gsIter(state.gsState)
		else
			state.groupSettings, state.domain, state.groupID = TMW.db[domain].Groups[groupID], domain, groupID
		end

		state.iconID = 0

		state.maxIconID = TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS

		return state
	end

	local function iter(state)
		local iconID = state.iconID
		iconID = iconID + 1	-- at least increment the icon

		while true do
			if not state.groupSettings then
				-- if there isnt another group, then stop
				tinsert(states, state)
				return
			elseif iconID <= state.maxIconID and not rawget(state.groupSettings.Icons, iconID) then
				-- if the icon settings dont exist and there is another icon, move to the next icon
				iconID = iconID + 1
			elseif iconID > state.maxIconID then
				if state.gsIter then
					state.groupSettings, state.domain, state.groupID = state.gsIter(state.gsState)
					iconID = 0
				else
					state.groupSettings = nil
				end
			else
				-- we finally found something valid, so use it
				break
			end
		end

		state.iconID = iconID
		local gs = state.groupSettings
		return gs.Icons[iconID], gs, state.domain, state.groupID, iconID -- ics, gs, domain, groupID, iconID
	end

	--- Iterates over icon settings in the current profile
	-- @param domain [string|nil] If groupID is also defined, it will restrict this iteration to a single group.
	-- @param groupID [number|nil] If domain is also defined, it will restrict this iteration to a single group.
	-- @return Iterator that will return (iconSettings, groupSettings, domain, groupID, iconID) for each iteration.
	function TMW:InIconSettings(domain, groupID)
		return iter, getstate(domain, groupID)
	end
end

do -- InGroupSettings
	local states = {}
	local function getstate(cg, mg)
		local state = wipe(tremove(states) or {})

		state.domain = "global"
		state.cg = 0
		state.mg = TMW.db[state.domain].NumGroups

		return state
	end

	local function iter(state)
		state.cg = state.cg + 1

		if state.cg > state.mg then
			if state.domain == "global" then
				state.domain = "profile"
				state.cg = 0
				state.mg = TMW.db[state.domain].NumGroups

				return iter(state)
			end

			tinsert(states, state)
			return
		end

		return TMW.db[state.domain].Groups[state.cg], state.domain, state.cg -- group settings, domain, groupID
	end

	--- Iterates over group settings in the current profile
	-- @return Iterator that will return (groupSettings, domain, groupID) for each iteration.
	function TMW:InGroupSettings()
		return iter, getstate()
	end
end

do -- InGroups
	local states = {}
	local function getstate(cg, mg)
		local state = wipe(tremove(states) or {})

		state.domain = "global"
		state.cg = 0
		state.mg = #TMW[state.domain]

		return state
	end

	local function iter(state)
		state.cg = state.cg + 1

		if state.cg > state.mg then
			if state.domain == "global" then
				state.domain = "profile"
				state.cg = 0
				state.mg = #TMW[state.domain]

				return iter(state)
			end

			tinsert(states, state)
			return
		end

		return TMW[state.domain][state.cg], state.domain, state.cg -- group, domain, groupID
	end

	--- Iterates over all groups that have been created by TellMeWhen.
	-- @return Iterator that will return (group, domain, groupID) for each iteration.
	function TMW:InGroups()
		return iter, getstate()
	end
end

do -- vararg
	local states = {}
	local function getstate(...)
		local state = wipe(tremove(states) or {})

		state.i = 0
		state.l = select("#", ...)

		for n = 1, state.l do
			state[n] = select(n, ...)
		end

		return state
	end

	local function iter(state)
		local i = state.i
		i = i + 1
		if i > state.l then
			tinsert(states, state)
			return
		end
		state.i = i

		return i, state[i], state.l
	end

	--- Iterates over each variable in a vararg.
	-- @return Iterator that will return (i, var, totalNumVars) for each iteration.
	function TMW:Vararg(...)
		return iter, getstate(...)
	end
end

do -- ordered pairs

	local tables = {}
	local unused = {}

	local sortByValues, compareFunc, reverse

	-- An alternative comparison function that can handle mismatched types.
	local function betterCompare(a, b)
		local ta, tb = type(a), type(b)
		if ta ~= tb then
			if reverse then
				return ta > tb
			end
			return ta < tb
		elseif ta == "number" or ta == "string" then
			if reverse then
				return a > b
			end
			return a < b
		elseif ta == "boolean" then
			if reverse then
				return b == true
			end
			return a == true
		else
			if reverse then
				return tostring(a) > tostring(b)
			end
			return tostring(a) < tostring(b)
		end
	end

	local function sorter(a, b)
		if sortByValues then
			a, b = sortByValues[a], sortByValues[b]
		end

		if compareFunc then
			return compareFunc(a, b)
		end

		if reverse then
			return a > b
		end
		return a < b

		--return compare(a, b)
	end

	local function orderedNext(t, state)
		local orderedIndex = tables[t]
		
		if state == nil then
			local key = orderedIndex[1]
			return key, t[key]
		end

		local key
		for i = 1, #orderedIndex do
			if orderedIndex[i] == state then
				key = orderedIndex[i+1]
				break
			end
		end

		if key then
			return key, t[key]
		end

		unused[#unused+1] = wipe(orderedIndex)
		tables[t] = nil
		return
	end

	--- Iterates over the table in an ordered fashion, without modifying the table.
	-- @param t [table] The table to iterate over
	-- @param compare [function|nil] The comparison function that will be used for sorting the keys or values of the table. Defaults to regular ascending order.
	-- @param byValues [boolean|nil] True to have the iteration order based on values (values will be passed to the compare function if defined), false/nil to sort by keys.
	-- @param rev [boolean|nil] True to reverse the sorted order of the iteration.
	-- @return Iterator that will return (key, value) for each iteration.
	function TMW:OrderedPairs(t, compare, byValues, rev)
		if not next(t) then
			return TMW.NULLFUNC
		end

		local orderedIndex = tremove(unused) or {}
		local type_comparand = nil
		for key, value in pairs(t) do
			orderedIndex[#orderedIndex + 1] = key

			-- Determine the types of what we're comparing by.
			-- If we find more than one type, use betterCompare since it handles type mismatches.
			if compare == nil then
				local oldType = type_comparand
				if byValues then
					type_comparand = type(value)
				else
					type_comparand = type(key)
				end
				if oldType ~= type_comparand then
					compare = compare or betterCompare
				end
			end
		end

		reverse = rev
		compareFunc = compare

		if byValues then
			sortByValues = t
		else
			sortByValues = nil
		end

		sort(orderedIndex, sorter)
		tables[t] = orderedIndex

		return orderedNext, t
	end
end






---------------------------------
-- Callback lib
---------------------------------

do
	-- because quite frankly, i hate the way CallbackHandler-1.0 works.
	local callbackregistry = {}
	local firingsInProgress = 0
	TMW.callbackregistry=callbackregistry
	
	local function removeNils(table)
		local numNils = 0
		
		for i = 1, table.n do
			local v = table[i]
			if v == nil then
				numNils = numNils + 1
			else
				table[i - numNils] = v
			end
		end
		
		for i = table.n - numNils + 1, table.n do
			table[i] = nil
		end
		
		table.n = #table
	end
	
	local function DetermineFuncAndArg(event, func, arg1)
		
		if not event:find("^TMW_") then
			-- All TMW events must begin with TMW_
			error("TMW events must begin with 'TMW_'", 3)
		end

		if type(func) == "table" then
			local object = func
			func = object[arg1 or event]
			arg1 = object
		end
		
		if type(func) ~= "function" then
			error("Couldn't find the function to register as a callback.", 3)
		end

		return func, arg1
	end

	--- Register a callback that will automatically unregister itself after it runs.
	function TMW:RegisterRunonceCallback(event, func, arg1)
		TMW:ValidateType("2 (event)", "TMW:RegisterRunonceCallback(event, func, arg1)", event, "string")
		TMW:ValidateType("3 (func)", "TMW:RegisterRunonceCallback(event, func, arg1)", func, "function;table")
		TMW:ValidateType("4 (arg1)", "TMW:RegisterRunonceCallback(event, func, arg1)", arg1, "!boolean")

		func, arg1 = DetermineFuncAndArg(event, func, arg1)	

		local function RunonceWrapper(...)
			safecall(func, ...)
			TMW:UnregisterCallback(event, RunonceWrapper, arg1)
		end

		TMW:RegisterCallback(event, RunonceWrapper, arg1)
	end

	--- Register a callback with TMW.
	-- Possible call signatures are:
	-- - TMW:RegisterCallback("TMW_EVENT", function() ... end) - Will call function(...)
	-- - TMW:RegisterCallback("TMW_EVENT", function(arg) ... end, arg) - Will call function(arg, ...)
	-- - TMW:RegisterCallback("TMW_EVENT", table) - Will call table:TMW_EVENT(...)
	-- - TMW:RegisterCallback("TMW_EVENT", table, funcName) - Will call table[funcName](table, ...)
	function TMW:RegisterCallback(event, func, arg1)
		TMW:ValidateType("2 (event)", "TMW:RegisterCallback(event, func, arg1)", event, "string")
		TMW:ValidateType("3 (func)", "TMW:RegisterCallback(event, func, arg1)", func, "function;table")
		TMW:ValidateType("4 (arg1)", "TMW:RegisterCallback(event, func, arg1)", arg1, "!boolean")
		

		func, arg1 = DetermineFuncAndArg(event, func, arg1)
		arg1 = arg1 or true

		local funcsForEvent
		if callbackregistry[event] then
			funcsForEvent = callbackregistry[event]
		else
			funcsForEvent = {}
			callbackregistry[event] = funcsForEvent
		end	

		local args
		for i = 1, #funcsForEvent do
			local tbl = funcsForEvent[i]
			if tbl.func == func then
				args = tbl
				local found
				for i = 1, args.n do
					if args[i] == arg1 then
						found = true
						break
					end
				end
				if not found then
					args.n = args.n + 1
					args[args.n] = arg1
				end
				break
			end
		end
		if not args then
			args = {func = func, n = 1, arg1}
			funcsForEvent[#funcsForEvent + 1] = args
		end
	end

	--- Unregister a callback from TMW.
	-- Call signature should be the same as how TMW:RegisterCallback() was called to register the callback. 
	function TMW:UnregisterCallback(event, func, arg1)
		TMW:ValidateType("2 (event)", "TMW:RegisterCallback(event, func, arg1)", event, "string")
		TMW:ValidateType("3 (func)", "TMW:RegisterCallback(event, func, arg1)", func, "function;table")
		TMW:ValidateType("4 (arg1)", "TMW:RegisterCallback(event, func, arg1)", arg1, "!boolean")
		

		func, arg1 = DetermineFuncAndArg(event, func, arg1)
		arg1 = arg1 or true

		local funcs = callbackregistry[event]
		if funcs then
			for t = 1, #funcs do
				local tbl = funcs[t]
				if tbl and tbl.func == func then
					for i = 1, tbl.n do
						if tbl[i] == arg1 then
							tbl[i] = nil
						end
					end
					
					if firingsInProgress == 0 then
						removeNils(tbl)
						if tbl.n == 0 then
							wipe(tbl)
							tremove(funcs, t)
						end
					end
					
					break
				end
			end
		end
	end
	
	--- Unregisters all callbacks for a given event.
	-- @param event [string] The event to unregister all callbacks from.
	function TMW:UnregisterAllCallbacks(event)
		
		local funcs = callbackregistry[event]
		if funcs then
			for k, v in pairs(funcs) do
				wipe(v)
			end
			wipe(funcs)
			callbackregistry[event] = nil
		end
	end
	
	local curEvent, curFunc, curArg1
	--- Fires an event, calling all relevant callbacks
	-- @param event [string] A string, beginning with "TMW_", that represents the event.
	-- @param ... [...] The parameters to be passed to the callbacks.
	function TMW:Fire(event, ...)
		local funcs = callbackregistry[event]

		if funcs then
			local oldFiringsInProgress = firingsInProgress
			firingsInProgress = firingsInProgress + 1
			
			local funcsNeedsFix
			for t = 1, #funcs do
				local tbl = funcs[t]
				local method = tbl and tbl.func
				
				if method then
					local tblNeedsFix
					
					for index = 1, tbl.n do
						local arg1 = tbl[index]
						
						local old_curEvent, old_curFunc, old_curArg1 = curEvent, curFunc, curArg1

						curEvent, curFunc, curArg1 = event, method, nil

						if arg1 == nil then
							tblNeedsFix = true
						elseif arg1 ~= true then
							curArg1 = arg1
							safecall(method, arg1, event, ...)
						else
							safecall(method, event, ...)
						end

						-- Restore previous values so that UnregisterThisCallback still works after a nested callback call
						curEvent, curFunc, curArg1 = old_curEvent, old_curFunc, old_curArg1
					end
					
					if tblNeedsFix then
						removeNils(tbl)
						if tbl.n == 0 then
							funcsNeedsFix = true
						end
					end
				end
			end
			
			if funcsNeedsFix then
				for t = #funcs, 1, -1 do
					if funcs[t].n == 0 then
						wipe(funcs[t])
						tremove(funcs, t)
					end
				end
				if #funcs == 0 then
					callbackregistry[event] = nil
				end
			end
			
			firingsInProgress = oldFiringsInProgress
		end
	end

	--- Unregisters the currently firing callback. Works with nested callbacks.
	function TMW:UnregisterThisCallback()
		TMW:UnregisterCallback(curEvent, curFunc, curArg1)
	end
end





---------------------------------
-- Tooltips
---------------------------------

local function TTOnEnter(self)
	if  (not self.__ttshowchecker or TMW.get(self[self.__ttshowchecker], self))
	and (self.__title or self.__text)
	then
		TMW:TT_Anchor(self)
		if self.__ttMinWidth then
			GameTooltip:SetMinimumWidth(self.__ttMinWidth)
		end
		GameTooltip:AddLine(TMW.get(self.__title, self), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
		local text = TMW.get(self.__text, self)
		if text then
			GameTooltip:AddLine(text, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, not self.__noWrapTooltipText)
		end
		GameTooltip:Show()
	end
end
local function TTOnLeave(self)
	GameTooltip:Hide()
end

function TMW:TT_Anchor(f)
	GameTooltip:SetOwner(f, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", 0, 0)
end

function TMW:TT(f, title, text, actualtitle, actualtext, showchecker)
	-- setting actualtitle or actualtext true cause it to use exactly what is passed in for title or text as the text in the tooltip
	-- if these variables arent set, then it will attempt to see if the string is a global variable (e.g. "MAXIMUM")
	-- if they arent set and it isnt a global, then it must be a TMW localized string, so use that

	TMW:ValidateType(2, "TMW:TT()", f, "frame")
	
	f.__title = TMW:TT_Parse(title, actualtitle)
	f.__text = TMW:TT_Parse(text, actualtext)
	
	f.__ttshowchecker = showchecker

	if not f.__ttHooked then
		f.__ttHooked = 1
		f:HookScript("OnEnter", TTOnEnter)
		f:HookScript("OnLeave", TTOnLeave)
	else
		if not f:GetScript("OnEnter") then
			f:HookScript("OnEnter", TTOnEnter)
		end
		if not f:GetScript("OnLeave") then
			f:HookScript("OnLeave", TTOnLeave)
		end
	end
end

function TMW:TT_Parse(text, literal)
	if text then
		return (literal and text) or _G[text] or L[text]
	else
		return text
	end
end

function TMW:TT_Copy(src, dest)
	TMW:TT(dest, src.__title, src.__text, 1, 1, src.__ttshowchecker)
end

function TMW:TT_Update(f)
	if GetMouseFocus() == f and f:IsMouseOver() and f:IsVisible() then
		f:GetScript("OnLeave")(f)
		if not f.IsEnabled or f:IsEnabled() or (f:IsObjectType("Button") and f:GetMotionScriptsWhileDisabled()) then
			f:GetScript("OnEnter")(f)
		end
	end
end










-- -------------------------------------------------------------------------------------------------
-- |                                                                                               |
-- |                                       MAIN ADDON FUNCTIONS                                    |
-- |                                                                                               |
-- -------------------------------------------------------------------------------------------------








---------------------------------
-- Initialization
---------------------------------

-- ADDON ENTRY POINT: EVERYTHING STARTS FROM HERE!
function TMW:PLAYER_LOGIN()
	TMW:UnregisterEvent("PLAYER_LOGIN")
	TMW.PLAYER_LOGIN = nil

	-- Check for wrong WoW version
	if select(4, GetBuildInfo()) < 60000 then
		-- GLOBALS: StaticPopupDialogs, StaticPopup_Show, EXIT_GAME, CANCEL, ForceQuit
		local version = GetBuildInfo()
		StaticPopupDialogs["TMW_BADWOWVERSION"] = {
			text = "TellMeWhen %s is not compatible with WoW %s. Please downgrade TellMeWhen or wait for a patch to WoW 6.0.2.", 
			button1 = OKAY,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMW_BADWOWVERSION", TELLMEWHEN_VERSION_FULL, version)
		return

	-- if the file IS required for gross functionality
	elseif not TMW.Classes or not TMW.Classes.IconDataProcessor or not TMW.Classes.IconDataProcessor.ProcessorsByName.SHOWN then
		-- this also includes upgrading from older than 3.0 (pre-Ace3 DB settings)
		-- GLOBALS: StaticPopupDialogs, StaticPopup_Show, EXIT_GAME, CANCEL, ForceQuit
		StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE"], 
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMW_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "TellMeWhen/Components/Core/IconDataProcessors.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
		return

	-- if the file is NOT required for gross functionality
	elseif not TMW.DOGTAG then
		StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE_NOREQ"], 
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMW_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "TellMeWhen/Components/Core/Common/DogTags/DogTags.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
	end
	


	TMW:UpdateTalentTextureCache()
	TMW:ProcessEquivalencies()


	
	
	TMW:RegisterEvent("BARBER_SHOP_OPEN")
	TMW:RegisterEvent("BARBER_SHOP_CLOSE")
	TMW:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	-- There was a time where we did not register PLAYER_TALENT_UPDATE because it fired way too much (See ticket 949)
	-- We definitely need it in Warlords, though, because PLAYER_SPECIALIZATION_CHANGED doesnt happen as often.
	TMW:RegisterEvent("PLAYER_TALENT_UPDATE", "PLAYER_SPECIALIZATION_CHANGED")
	TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED")




	
	TMW:InitializeDatabase()
	
	-- DEFAULT_ICON_SETTINGS is used for comparisons against a blank icon setup,
	-- most commonly used to see if the user has configured an icon at all.
	TMW.DEFAULT_ICON_SETTINGS = TMW.db.profile.Groups[0].Icons[0]
	TMW.db.profile.Groups[0] = nil
	



	
	--------------- Communications ---------------
	-- Channel TMW is used for sharing data.
	-- ReceiveComm is a setting that allows users to disable receiving shared data.
	if TMW.db.profile.ReceiveComm then
		TMW:RegisterComm("TMW")
	end
	
	-- Channel TMWV is used for version notifications.
	TMW:RegisterComm("TMWV")
	-- PLAYER_ENTERING_WORLD handles sending version warnings
	TMW:RegisterEvent("PLAYER_ENTERING_WORLD")





	
	TMW:Fire("TMW_INITIALIZE")
	TMW:UnregisterAllCallbacks("TMW_INITIALIZE")
	
	TMW.Initialized = true
	
	TMW:SetScript("OnUpdate", TMW.OnUpdate)
	TMW:Update()
end
TMW:RegisterEvent("PLAYER_LOGIN")


function TMW:InitializeDatabase()
	
	TMW.InitializedDatabase = true
	
	TMW:Fire("TMW_DB_INITIALIZING")
	TMW:UnregisterAllCallbacks("TMW_DB_INITIALIZING")
	
	--------------- Database ---------------
	if type(TellMeWhenDB) ~= "table" then
		-- TellMeWhenDB might not exist if this is a fresh install
		-- or if the user is upgrading from a really old version that uses TellMeWhen_Settings.
		TellMeWhenDB = {Version = TELLMEWHEN_VERSIONNUMBER}
		TMW.DBWasEmpty = true
	end
	

	-- This will very rarely actually set anything.
	-- TellMeWhenDB.Version is set when then DB is first created,
	-- but, if this setting doesn't yet exist then the user has a really old version
	-- from before TellMeWhenDB.Version existed, so set it to 0 so we make sure to do all of the upgrades here
	TellMeWhenDB.Version = TellMeWhenDB.Version or 0
	
	-- Handle upgrades that need to be done before defaults are added to the database.
	-- Primary purpose of this is to properly upgrade settings if a default has changed.
	TMW:RawUpgrade()
	
	-- Initialize the database
	TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
	
	if TellMeWhen_Settings then
		for k, v in pairs(TellMeWhen_Settings) do
			TMW.db.profile[k] = v
		end
		TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
		TMW.db.profile.Version = TellMeWhen_Settings.Version
		TellMeWhen_Settings = nil
	end
	
	TMW.db.RegisterCallback(TMW, "OnProfileChanged",	"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnProfileCopied",		"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnProfileReset",		"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnNewProfile",		"OnProfile")
	
	-- Handle normal upgrades after the database has been initialized.
	TMW:UpgradeGlobal()
	TMW:UpgradeProfile()
	
	TMW:Fire("TMW_DB_INITIALIZED")

	if not TMW.DBWasEmpty then
		-- If the DB is empty, it might get re-initialized,
		-- so only unregister these if it wasn't empty
		TMW:UnregisterAllCallbacks("TMW_DB_INITIALIZED")
		TMW.InitializeDatabase = nil
		TMW.RawUpgrade = nil
		TMW.UpgradeGlobal = nil
	end
end




---------------------------------
-- GUID Functions
---------------------------------

TMW.PreviousGUIDToOwner = {}
TMW.GUIDToOwner = {}

do
	local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz=_"

	-- This is here for collision prevention
	local previousGUIDs = setmetatable({},
	{
		__mode='kv',
		__index=function(t, k) t[k] = {} return t[k] end
	})

	-- This is here to keep the most recent table from getting GC'd
	local lastPreviousGUIDsTable

	local lastDecimalSeconds

	function TMW.generateGUID(length)
		-- Start with the current time as a base.
		-- octalStr will get something like "012226556045"
		local time = _G.time()
		local octalStr = format("%.12o", time)
		
		-- Super-precision timer. Divide by 1000 to get seconds.
		local timeMsPrecise = debugprofilestop() / 1000


		if timeMsPrecise > 5 then
			-- If the high precision timer has less than 5 seconds on it,
			-- some other addon is probably resetting it. If this is the case,
			-- skip over this whole process. It will be replaced with random data.


			-- Remove the whole seconds, leaving only the decimal seconds.
			timeMsPrecise = timeMsPrecise - floor(timeMsPrecise)

			-- Take the first nine decimal points of the timer and remove "0." from the start
			local decimalSeconds = format("%.9f", timeMsPrecise):gsub("0%.", "")
			

			if lastDecimalSeconds ~= decimalSeconds then
				-- Format the decimal seconds as octal.
				-- octalStr now looks something like "0122265560456407207044"

				-- We only want to do this if decimalSeconds is different from the value
				-- that it was the last time a GUID was generated. It might be the same if
				-- the high-precision timer isn't working properly (see below).
				-- If this conditional statement fails, the void left will get filled with
				-- random numbers, which is fine.
				octalStr = octalStr .. format("%.10o", decimalSeconds)
			end

			-- We keep track of this in order to work around issues where the high-precision timer
			-- isn't giving us highly-precise time. Usually this happens because GetCVar("timingMethod") == "1"
			lastDecimalSeconds = decimalSeconds

		end
		
		-- If we need more characters, fill the rest with random numbers
		while #octalStr < length * 2 do
			octalStr = octalStr .. random(0, 7)
		end
		
		local GUID = ""

		-- For every two octal numbers (6 bits), take their value and get the corresponding
		-- base64 value from the chars string.
		for segment in octalStr:sub(1, length*2):gmatch("..") do
			local value = tonumber(segment, 8) + 1
			GUID = GUID .. chars:sub(value, value)
		end

		-- Some reports of collisions are coming in. Let's try to prevent them:
		if previousGUIDs[time][GUID] then
			return TMW.generateGUID(length)
		end
		previousGUIDs[time][GUID] = true

		-- Set this to prevent the most recent table from getting GC'd
		lastPreviousGUIDsTable = previousGUIDs[time]

		return GUID
	end
end

function TMW:GenerateGUID(type, length)
	return "TMW:" .. type .. ":" .. TMW.generateGUID(length)
end

function TMW:ParseGUID(GUID)
	return strmatch(GUID, "TMW:([a-z]+):(.*)")
end

function TMW:DeclareDataOwner(GUID, object)
	local old = TMW.GUIDToOwner[GUID]

	if old and object and old ~= object then
		if old:GetGUID() == object:GetGUID() then
			TMW:PickNewGUIDForOne(old, object)
		end
	end

	TMW.GUIDToOwner[GUID] = object
end

function TMW:GetDataOwner(GUID)
	return TMW.GUIDToOwner[GUID]
end

function TMW:GetSettingsFromGUID(GUID)
	if not GUID or GUID == "" then
		return nil
	end

	local owner = TMW.GUIDToOwner[GUID] or TMW.PreviousGUIDToOwner[GUID]
	if owner and owner:GetGUID() == GUID then
		return owner:GetSettings(), owner
	end

	local dataType = TMW:ParseGUID(GUID)

	if not dataType then
		return nil
	end

	local iter
	if dataType == "icon" then
		iter = TMW.InIconSettings
	elseif dataType == "group" then
		iter = TMW.InGroupSettings
	else
		TMW:Error("Unsupported GUID type for TMW:GetSettingsFromGUID() - %q", GUID)
		return nil
	end

	if iter then
		for settings, a, b, c in iter(TMW) do
			if settings.GUID == GUID then
				return settings, nil, a, b, c
			end
		end
	end
end

function TMW:PickNewGUIDForOne(first, second)
	if (not TMW.IE) or TMW.Locked then
		return
	end

	local dialog = TellMeWhen_GUIDConflictResolveDialog

	if dialog:IsShown() then
		return 
	end

	dialog.GUID = first:GetGUID()

	if dialog:IsIgnored(dialog.GUID) then
		return
	end

	dialog.First.object = first
	dialog.First:SetFormattedText(L["GUIDCONFLICT_REGENERATE"], first:GetFullName())
	TMW:TT(dialog.First, dialog.First:GetText(), nil, 1, nil)

	dialog.Second.object = second
	dialog.Second:SetFormattedText(L["GUIDCONFLICT_REGENERATE"], second:GetFullName())
	TMW:TT(dialog.Second, dialog.Second:GetText(), nil, 1, nil)

	dialog:Show()

end




---------------------------------
-- Upgrade Functions
---------------------------------

TMW.UpgradeTable = {}
TMW.UpgradeTableByVersions = {}

function TMW:GetBaseUpgrades()			-- upgrade functions
	return {

		[71020] = {
			icon = function(self, ics)
				ics.Name = ics.Name:gsub("IncreasedPhysHaste", "IncreasedHaste")
				ics.Name = ics.Name:gsub("IncreasedSpellHaste", "IncreasedHaste")
			end,
		},

		[70001] = {
			global = function(self)
				local currentProfile = TMW.db:GetCurrentProfile()

				TMW.db:SetProfile(currentProfile)

				for name, p in pairs(TMW.db.profiles) do
					if name ~= currentProfile then
						TMW.safecall(TMW.db.SetProfile, TMW.db, name)
					end
				end

				TMW.db:SetProfile(currentProfile)

				TMW:Print("Finished one-time upgrade of all profiles to v7.0.0.")

				collectgarbage()
			end,

			recursiveReplaceReferences = function(self, table, GUIDmap)
				for k, v in pairs(table) do
					if type(v) == "table" then
						self:recursiveReplaceReferences(v, GUIDmap)
					elseif GUIDmap[v] then
						local GUID = GUIDmap[v][2].GUID
						if GUID == "" or not GUID then
							GUID = TMW:GenerateGUID(GUIDmap[v][1], TMW.CONST.GUID_SIZE)
						end
						GUIDmap[v][2].GUID = GUID
						table[k] = GUID
					end
				end
			end,

			runGUIDUpgrade = function(self, func, data, ...)
				local GUIDmap = {}

				func(self, GUIDmap, data, ...)

				self:recursiveReplaceReferences(data, GUIDmap)
			end,

			guidupgrade_profile = function(self, GUIDmap, profile)
				for groupID, gs in pairs(profile.Groups) do
					self:guidupgrade_group(GUIDmap, gs, groupID)
				end
			end,

			guidupgrade_group = function(self, GUIDmap, gs, groupID)
				local GUID = TMW:GenerateGUID("group", TMW.CONST.GUID_SIZE)
				gs.GUID = GUID

				-- This will be set when importing a group from an external source.
				-- The purpose is to help maintain icon references between icons in the same group
				-- (this functionality used to be preformed by TMW:ReconcileData())
				if type(gs.__UPGRADEHELPER_OLDGROUPID) == "number" then
					groupID = gs.__UPGRADEHELPER_OLDGROUPID
				end
				gs.__UPGRADEHELPER_OLDGROUPID = nil

				GUIDmap["TellMeWhen_Group" .. groupID] = {"group", gs}

				for iconID, ics in pairs(gs.Icons) do
					GUIDmap["TellMeWhen_Group" .. groupID .. "_Icon" .. iconID] = {"icon", ics}
				end

				return GUID
			end,

			IsIconDefault = function(ics)
				return TMW:DeepCompare(ics, TMW.DEFAULT_ICON_SETTINGS)
			end,

			profile = function(self, profile)
				self:runGUIDUpgrade(self.guidupgrade_profile, profile)
			end,
			group = function(self, gs, domain, groupID)
				if gs.GUID == "" then
					self:runGUIDUpgrade(self.guidupgrade_group, gs, groupID)
				end
			end,
		},

		[62304] = {
			profile = function(self)
				for k, v in pairs(TMW.db.profile.Colors) do
					if not (
						(v.CBC.r == 0 and v.CBC.g == 1 and v.CBC.b == 0 and 
						 v.CBS.r == 1 and v.CBS.g == 0 and v.CBS.b == 0)  
					or	(v.CBC.r == 1 and v.CBC.g == 0 and v.CBC.b == 0 and 
						 v.CBS.r == 0 and v.CBS.g == 1 and v.CBS.b == 0))
					then
						v.CBM.r = (v.CBC.r + v.CBS.r) / 2
						v.CBM.g = (v.CBC.g + v.CBS.g) / 2
						v.CBM.b = (v.CBC.b + v.CBS.b) / 2
					end

					v.CBM.a = (v.CBC.a + v.CBS.a) / 2

					if v.CBC.Override and v.CBS.Override then
						v.CBM.Override = true
					end
				end
			end
		},
		[60027] = {
			icon = function(self, ics)
				ics.Name = ics.Name:gsub("IncreasedSPsix", "IncreasedSP")
				ics.Name = ics.Name:gsub("IncreasedSPten", "IncreasedSP")
			end,
		},
		[60012] = {
			global = function(self)
				TMW.db.global.HelpSettings.HasChangedUnit = nil
			end,
		},
		[60008] = {
			icon = function(self, ics)
				if ics.ShowWhen == "alpha" or ics.ShowWhen == nil then
					ics.ShowWhen = 0x2
				elseif ics.ShowWhen == "unalpha" then
					ics.ShowWhen = 0x1
				elseif ics.ShowWhen == "always" then
					ics.ShowWhen = 0x3
				end
			end,
		},
		[51023] = {
			icon = function(self, ics)
				ics.InvertBars = nil
			end,
		},
		[51006] = {
			profile = function(self)
				if TMW.db.profile.MasterSound then
					TMW.db.profile.SoundChannel = "Master"
				else
					TMW.db.profile.SoundChannel = "SFX"
				end
				TMW.db.profile.MasterSound = nil
			end,
		},
		[51002] = {
			translations = {
				t = "['target':Name]",
				f = "['focus':Name]",
				m = "['mouseover':Name]",
				u = "[Unit:Name]",
				p = "[PreviousUnit:Name]",
				s = "[Spell]",
				k = "[Stacks]",
				d = "[Duration:TMWFormatDuration]",
				o = "[Source:Name]",
				e = "[Destination:Name]",
				x = "[Extra]",
			},
			translateString = function(self, string)
				for originalLetter, translation in pairs(self.translations) do
					string = string:gsub("%%[" .. originalLetter .. originalLetter:upper() .. "]", translation)
				end
				return string
			end,
		},
		[50028] = {
			icon = function(self, ics)
				local Events = ics.Events
				
				-- dont use InNLengthTable here
				--(we need to make sure to do it to everything, not just events that are currently valid. Just in case...)
				for _, eventSettings in ipairs(Events) do
					local eventData = TMW.EventList[eventSettings.Event]
					if eventData and eventData.applyDefaultsToSetting then
						eventData.applyDefaultsToSetting(eventSettings)
					end
				end
			end,
		},
		[48025] = {
			icon = function(self, ics)
				ics.Name = gsub(ics.Name, "(CrowdControl)", "%1; " .. GetSpellInfo(339))
			end,
		},
		[47002] = {
			map = {
				CBS = "CDSTColor",
				CBC = "CDCOColor",
				OOR = "OORColor",
				OOM = "OOMColor",
				OORM = "OORColor",

				-- i didn't upgrade these 2 because they suck
				--PRESENTColor =	{r=1, g=1, b=1, a=1},
				--ABSENTColor	 =	{r=1, g=0.35, b=0.35, a=1},
			},
			
			profile = function(self)
				for newKey, oldKey in pairs(self.map) do
					local old = TMW.db.profile[oldKey]
					local new = TMW.db.profile.Colors.GLOBAL[newKey]

					if old then
						for k, v in pairs(old) do
							new[k] = v
						end

						TMW.db.profile[oldKey] = nil
					end
				end

				TMW.db.profile.PRESENTColor = nil
				TMW.db.profile.ABSENTColor = nil

				TMW.db.profile.Color = nil
				TMW.db.profile.UnColor = nil

			end,
		},
		[46605] = {
			-- Added 8-10-12 (Noticed CooldownType cluttering up old upgrades; this setting isn't used anymore.)
			icon = function(self, ics)
				ics.CooldownType = nil
			end,
		},
		[46604] = {
			icon = function(self, ics)
				if ics.CooldownType == "multistate" and ics.Type == "cooldown" then
					ics.Type = "multistate"
					ics.CooldownType = TMW.Icon_Defaults.CooldownType
				end
			end,
		},
		[46418] = {
			global = function(self)
				TMW.db.global.HelpSettings.ResetCount = nil
			end,
		},
		[46202] = {
			icon = function(self, ics)
				if ics.CooldownType == "item" and ics.Type == "cooldown" then
					ics.Type = "item"
					ics.CooldownType = TMW.Icon_Defaults.CooldownType
				end
			end,
		},
		[45605] = {
			global = function(self)
				if TMW.db.global.SeenNewDurSyntax then
					TMW.db.global.HelpSettings.NewDurSyntax = TMW.db.global.SeenNewDurSyntax
					TMW.db.global.SeenNewDurSyntax = nil
				end
			end,
		},
		--[[[45402] = {
			group = function(self, gs)
				gs.OnlyInCombat = false
			end,
		},]]
		[45008] = {
			group = function(self, gs)
				-- Desc: Transfers stack text settings from the old gs.Font table to the new gs.Fonts.Count table
				if gs.Font then
					gs.Fonts = gs.Fonts or {}
					gs.Fonts.Count = gs.Fonts.Count or {}
					for k, v in pairs(gs.Font) do
						gs.Fonts.Count[k] = v
						gs.Font[k] = nil
					end
				end
			end,
		},
		[44009] = {
			profile = function(self)
				TMW.db.profile.HasImported = nil
			end,
		},
		[44003] = {
			icon = function(self, ics)
				if ics.Type == "unitcooldown" or ics.Type == "icd" then
					local duration = ics.ICDDuration or 45 -- 45 was the old default
					ics.Name = TMW:CleanString(gsub(ics.Name..";", ";", ": "..duration.."; "))
					ics.ICDDuration = nil
				end
			end,
		},
		[44002] = {
			icon = function(self, ics)
				if ics.Type == "autoshot" then
					ics.Type = "cooldown"
					ics.CooldownType = "spell"
					ics.Name = 75
				end
			end,
		},
		[43002] = {
			WhenChecks = {
				cooldown = "CooldownShowWhen",
				buff = "BuffShowWhen",
				reactive = "CooldownShowWhen",
				wpnenchant = "BuffShowWhen",
				totem = "BuffShowWhen",
				unitcooldown = "CooldownShowWhen",
				dr = "CooldownShowWhen",
				icd = "CooldownShowWhen",
				cast = "BuffShowWhen",
			},
			Defaults = {
				CooldownShowWhen	= "usable",
				BuffShowWhen		= "present",
			},
			Conversions = {
				usable		= "alpha",
				present		= "alpha",
				unusable	= "unalpha",
				absent		= "unalpha",
				always		= "always",
			},
			
			icon = function(self, ics)
				local setting = self.WhenChecks[ics.Type]
				if setting then
					ics.ShowWhen = self.Conversions[ics[setting] or self.Defaults[setting]] or ics[setting] or self.Defaults[setting]
				end
				ics.CooldownShowWhen = nil
				ics.BuffShowWhen = nil
			end,
		},
		[43001] = {
			profile = function(self)
				-- at first glance, this should be a group upgrade,
				-- but it is actually a profile upgrade.
				-- we dont want to do it to individual groups that have been imported
				-- because TMW.db.profile.Font wont exist at that point.
				-- we only want to do it to groups that exist in whatever profile is being upgraded
				if TMW.db.profile.Font then
					for gs, domain in TMW:InGroupSettings() do
						if domain == "profile" then
							gs.Font = gs.Font or {}
							for k, v in pairs(TMW.db.profile.Font) do
								gs.Font[k] = v
							end
						end
					end
					TMW.db.profile.Font = nil
				end
			end,
		},
		[41301] = {
			stances = {
				{class = "WARRIOR", 	id = 2457}, 	-- Battle Stance
				{class = "WARRIOR", 	id = 71}, 		-- Defensive Stance
				{class = "WARRIOR", 	id = 2458}, 	-- Berserker Stance

				{class = "DRUID", 		id = 5487}, 	-- Bear Form
				{class = "DRUID", 		id = 768}, 		-- Cat Form
				{class = "DRUID", 		id = 1066}, 	-- Aquatic Form
				{class = "DRUID", 		id = 783}, 		-- Travel Form
				{class = "DRUID", 		id = 24858}, 	-- Moonkin Form
				{class = "DRUID", 		id = 33891}, 	-- Tree of Life
				{class = "DRUID", 		id = 33943}, 	-- Flight Form
				{class = "DRUID", 		id = 40120}, 	-- Swift Flight Form

				{class = "PRIEST", 		id = 15473}, 	-- Shadowform

				{class = "ROGUE", 		id = 1784}, 	-- Stealth

				{class = "HUNTER", 		id = 82661}, 	-- Aspect of the Fox
				{class = "HUNTER", 		id = 13165}, 	-- Aspect of the Hawk
				{class = "HUNTER", 		id = 5118}, 	-- Aspect of the Cheetah
				{class = "HUNTER", 		id = 13159}, 	-- Aspect of the Pack
				{class = "HUNTER", 		id = 20043}, 	-- Aspect of the Wild

				{class = "DEATHKNIGHT", id = 48263}, 	-- Blood Presence
				{class = "DEATHKNIGHT", id = 48266}, 	-- Frost Presence
				{class = "DEATHKNIGHT", id = 48265}, 	-- Unholy Presence

				{class = "PALADIN", 	id = 19746}, 	-- Concentration Aura
				{class = "PALADIN", 	id = 32223}, 	-- Crusader Aura
				{class = "PALADIN", 	id = 465}, 		-- Devotion Aura
				{class = "PALADIN", 	id = 19891}, 	-- Resistance Aura
				{class = "PALADIN", 	id = 7294}, 	-- Retribution Aura

				{class = "WARLOCK", 	id = 47241}, 	-- Metamorphosis
			},
	
			setupcsn = function(self)
				self.CSN = {
					[0]	= NONE,
				}

				for _, stanceData in ipairs(self.stances) do
					if stanceData.class == pclass then
						local stanceName = GetSpellInfo(stanceData.id)
						tinsert(self.CSN, stanceName)
					end
				end

				for i, stanceName in pairs(self.CSN) do
					self.CSN[stanceName] = i
				end

			end,

			group = function(self, gs)
				if not self.CSN then
					self:setupcsn()
				end
				
				local Conditions = gs.Conditions

				if gs.NotInVehicle then
					local condition = Conditions[#Conditions + 1]
					condition.Type = "VEHICLE"
					condition.Level = 1
					gs.NotInVehicle = nil
				end
				if gs.Stance then
					local nume = {}
					local numd = {}
					for id = 0, #self.CSN do
						local sn = self.CSN[id]
						local en = gs.Stance[sn]
						if en == false then
							tinsert(numd, id)
						elseif en == nil or en == true then
							tinsert(nume, id)
						end
					end
					if #nume ~= 0 then
						local start = #Conditions + 1
						if #nume <= ceil(#self.CSN/2) then

							for _, value in ipairs(nume) do
								local condition = Conditions[#Conditions + 1]
								condition.Type = "STANCE"
								condition.Operator = "=="
								condition.Level = value
								condition.AndOr = "OR"
							end
							Conditions[start].AndOr = "AND"
							if #Conditions > #nume then
								Conditions[start].PrtsBefore = 1
								Conditions[#Conditions].PrtsAfter = 1
							end
						elseif #numd > 0 then

							for _, value in ipairs(numd) do
								local condition = Conditions[#Conditions + 1]
								condition.Type = "STANCE"
								condition.Operator = "~="
								condition.Level = value
								condition.AndOr = "AND"
							end
							if #Conditions > #numd then
								Conditions[start].PrtsBefore = 1
								Conditions[#Conditions].PrtsAfter = 1
							end
						end
					end
					gs.Stance = nil
				end
			end,
		},
		[40124] = {
			profile = function(self)
				TMW.db.profile.Revision = nil-- unused
			end,
		},
		[40111] = {
			icon = function(self, ics)
				ics.Unit = TMW:CleanString((ics.Unit .. ";"):	-- it wont change things at the end of the unit string without a character after the unit at the end
				gsub("raid[^%d]", "raid1-25;"):
				gsub("party[^%d]", "party1-4;"):
				gsub("arena[^%d]", "arena1-5;"):
				gsub("boss[^%d]", "boss1-4;"):
				gsub("maintank[^%d]", "maintank1-5;"):
				gsub("mainassist[^%d]", "mainassist1-5;"))
			end,
		},
		[40080] = {
			group = function(self, gs)
				if gs.Stance and (gs.Stance[L["NONE"]] == false or gs.Stance[L["CASTERFORM"]] == false) then
					gs.Stance[L["NONE"]] = nil
					gs.Stance[L["CASTERFORM"]] = nil
					-- GLOBALS: NONE
					gs.Stance[NONE] = false
				end
			end,
		},
		[40060] = {
			profile = function(self)
				TMW.db.profile.Texture = nil --now i get the texture from LSM the right way instead of saving the texture path
			end,
		},
		[40010] = {
			icon = function(self, ics)
				if ics.Type == "multistatecd" then
					ics.Type = "cooldown"
					ics.CooldownType = "multistate"
				end
			end,
		},
		[40001] = {
			profile = function(self)
				TMW.db.profile.Spacing = nil
			end,
		},
		[40000] = {
			profile = function(self)
				TMW.db.profile.Locked = false
			end,
			group = function(self, gs)
				gs.Spacing = TMW.db.profile.Spacing or 0
			end,
			icon = function(self, ics)
				if ics.Type == "icd" then
					ics.CooldownShowWhen = ics.ICDShowWhen or "usable"
					ics.ICDShowWhen = nil
				end
			end,
		},
		[30000] = {
			profile = function(self)
				TMW.db.profile.NumGroups = 10
				TMW.db.profile.Condensed = nil
				TMW.db.profile.NumCondits = nil
				TMW.db.profile.DSN = nil
				TMW.db.profile.UNUSEColor = nil
				TMW.db.profile.USEColor = nil
				
				if TMW.db.profile.Font and TMW.db.profile.Font.Outline == "THICK" then
					TMW.db.profile.Font.Outline = "THICKOUTLINE"
				end
			end,
			
			stances = {
				{class = "WARRIOR", 	id = 2457}, 	-- Battle Stance
				{class = "WARRIOR", 	id = 71}, 		-- Defensive Stance
				{class = "WARRIOR", 	id = 2458}, 	-- Berserker Stance

				{class = "DRUID", 		id = 5487}, 	-- Bear Form
				{class = "DRUID", 		id = 768}, 		-- Cat Form
				{class = "DRUID", 		id = 1066}, 	-- Aquatic Form
				{class = "DRUID", 		id = 783}, 		-- Travel Form
				{class = "DRUID", 		id = 24858}, 	-- Moonkin Form
				{class = "DRUID", 		id = 33891}, 	-- Tree of Life
				{class = "DRUID", 		id = 33943}, 	-- Flight Form
				{class = "DRUID", 		id = 40120}, 	-- Swift Flight Form

				{class = "PRIEST", 		id = 15473}, 	-- Shadowform

				{class = "ROGUE", 		id = 1784}, 	-- Stealth

				{class = "HUNTER", 		id = 82661}, 	-- Aspect of the Fox
				{class = "HUNTER", 		id = 13165}, 	-- Aspect of the Hawk
				{class = "HUNTER", 		id = 5118}, 	-- Aspect of the Cheetah
				{class = "HUNTER", 		id = 13159}, 	-- Aspect of the Pack
				{class = "HUNTER", 		id = 20043}, 	-- Aspect of the Wild

				{class = "DEATHKNIGHT", id = 48263}, 	-- Blood Presence
				{class = "DEATHKNIGHT", id = 48266}, 	-- Frost Presence
				{class = "DEATHKNIGHT", id = 48265}, 	-- Unholy Presence

				{class = "PALADIN", 	id = 19746}, 	-- Concentration Aura
				{class = "PALADIN", 	id = 32223}, 	-- Crusader Aura
				{class = "PALADIN", 	id = 465}, 		-- Devotion Aura
				{class = "PALADIN", 	id = 19891}, 	-- Resistance Aura
				{class = "PALADIN", 	id = 7294}, 	-- Retribution Aura

				{class = "WARLOCK", 	id = 47241}, 	-- Metamorphosis
			},
	
			setupcsn = function(self)
				self.CSN = {
					[0]	= NONE,
				}

				for _, stanceData in ipairs(self.stances) do
					if stanceData.class == pclass then
						local stanceName = GetSpellInfo(stanceData.id)
						tinsert(self.CSN, stanceName)
					end
				end

				for i, stanceName in pairs(self.CSN) do
					self.CSN[stanceName] = i
				end

			end,

			group = function(self, gs)
				gs.LBFGroup = nil
				
				if not self.CSN then
					self:setupcsn()
				end
				
				if gs.Stance then
					for k, v in pairs(gs.Stance) do
						if self.CSN[k] then
							if v then -- everything switched in this version
								gs.Stance[self.CSN[k]] = false
							else
								gs.Stance[self.CSN[k]] = true
							end
							gs.Stance[k] = nil
						end
					end
				end
			end,
			iconSettingsToClear = {
				OORColor = true,
				OOMColor = true,
				Color = true,
				ColorOverride = true,
				UnColor = true,
				DurationAndCD = true,
				Shapeshift = true, -- i used this one during some initial testing for shapeshifts
				UnitReact = true,
			},
			icon = function(self, ics, gs, iconID)
				for k in pairs(self.iconSettingsToClear) do
					ics[k] = nil
				end

				-- this is part of the old CondenseSettings (but modified slightly),
				-- just to get rid of values that are defined in the saved variables that dont need to be
				-- (basically, they were set automatically on accident, most of them in early versions)
				local nondefault = 0
				local n = 0
				for s, v in pairs(ics) do
					if (type(v) ~= "table" and v ~= TMW.Icon_Defaults[s]) or (type(v) == "table" and #v ~= 0) then
						nondefault = nondefault + 1
						if (s == "Enabled") or (s == "ShowTimerText") then
							n = n+1
						end
					end
				end
				if n == nondefault then
					gs.Icons[iconID] = nil
				end
			end,
		},
		[24000] = {
			icon = function(self, ics)
				ics.Name = gsub(ics.Name, "StunnedOrIncapacitated", "Stunned;Incapacitated")
				
				-- Changed in 60027 to "IncreasedSP" instead of "IncreasedSPsix;IncreasedSPten"
				--ics.Name = gsub(ics.Name, "IncreasedSPboth", "IncreasedSPsix;IncreasedSPten")
				ics.Name = gsub(ics.Name, "IncreasedSPboth", "IncreasedSP")
				
				
				if ics.Type == "darksim" then
					ics.Type = "multistatecd"
					ics.Name = "77606"
				end
			end,
		},
		[22100] = {
			icon = function(self, ics)
				if ics.UnitReact and ics.UnitReact ~= 0 then
					local condition = ics.Conditions[#ics.Conditions + 1]
					condition.Type = "REACT"
					condition.Level = ics.UnitReact
					condition.Unit = "target"
				end
			end,
		},
		[21200] = {
			icon = function(self, ics)
				if ics.WpnEnchantType == "thrown" then
					ics.WpnEnchantType = "RangedSlot"
				elseif ics.WpnEnchantType == "offhand" then
					ics.WpnEnchantType = "SecondaryHandSlot"
				elseif ics.WpnEnchantType == "mainhand" then --idk why this would happen, but you never know
					ics.WpnEnchantType = "MainHandSlot"
				end
			end,
		},
		[15400] = {
			icon = function(self, ics)
				if ics.Alpha == 0.01 then ics.Alpha = 1 end
			end,
		},
		[15300] = {
			icon = function(self, ics)
				if ics.Alpha > 1 then
					ics.Alpha = (ics.Alpha / 100)
				else
					ics.Alpha = 1
				end
			end,
		},
		[12000] = {
			profile = function(self)
				TMW.db.profile.Spec = nil
			end,
		},

	}
end

function TMW:RegisterUpgrade(version, data)
	assert(not data.Version, "Upgrade data cannot store a value with key 'Version' because it is a reserved key.")
	
	if TMW.HaveUpgradedOnce then
		error("Upgrades are being registered too late. They need to be registered before any upgrades occur.", 2)
	end
	
	local upgradeSet = TMW.UpgradeTableByVersions[version]
	if upgradeSet then
		-- An upgrade set already exists for this version, so we need to merge the two.
		for k, v in pairs(data) do
			if upgradeSet[k] ~= nil then
				if type(v) == "function" then
					-- If we already have a function with the same key (E.g. 'icon' or 'group')
					-- then hook the existing function so that both run
					hooksecurefunc(upgradeSet, k, v)
				else
					-- If we already have data with the same key (some kind of helper data for the upgrade)
					-- then raise an error because there will certainly be conflicts.
					error(("A value with key %q already exists for upgrades for version %d. Please choose a different key to store it in to prevent conflicts.")
					:format(k, version), 2)
				end
			else
				-- There was nothing already in place, so just stick it in the upgrade set as-is.
				upgradeSet[k] = v
			end
		end
	else
		-- An upgrade set doesn't exist for this version,
		-- so just use the table that was passed in and process it as a new upgrade set.
		data.Version = version
		TMW.UpgradeTableByVersions[version] = data
		tinsert(TMW.UpgradeTable, data)
	end
end

function TMW.UpgradeTableSorter(a, b)
	if a.priority or b.priority then
		if a.priority and b.priority then
			return a.priority < b.priority
		else
			return a.priority
		end
	end
	return a.Version < b.Version
end
function TMW:SortUpgradeTable()
	sort(TMW.UpgradeTable, TMW.UpgradeTableSorter)
end

function TMW:GetUpgradeTable()	
	if TMW.GetBaseUpgrades then		
		for version, data in pairs(TMW:GetBaseUpgrades()) do
			TMW:RegisterUpgrade(version, data)
		end
		
		TMW.GetBaseUpgrades = nil
	end
	
	TMW:SortUpgradeTable()
	
	return TMW.UpgradeTable
end


function TMW:DoUpgrade(type, version, ...)
	assert(_G.type(type) == "string")
	assert(_G.type(version) == "number")
	
	-- upgrade the actual requested setting
	for k, v in ipairs(TMW:GetUpgradeTable()) do
		if v.Version > version then
			if v[type] then
				v[type](v, ...)
			end
		end
	end
	
	TMW:Fire("TMW_UPGRADE_REQUESTED", type, version, ...)

	-- delegate out to sub-types
	if type == "global" then
		-- delegate to locale
		if TMW.db.sv.locale then
			for locale, ls in pairs(TMW.db.sv.locale) do
				TMW:DoUpgrade("locale", version, ls, locale)
			end
		end

		-- delegate to groups
		for gs, domain, groupID in TMW:InGroupSettings() do
			if domain == type then
				TMW:DoUpgrade("group", version, gs, domain, groupID)
			end
		end
	
		--All Global Upgrades Complete
		TellMeWhenDB.Version = TELLMEWHEN_VERSIONNUMBER

	elseif type == "profile" then
		-- delegate to groups
		for gs, domain, groupID in TMW:InGroupSettings() do
			if domain == type then
				TMW:DoUpgrade("group", version, gs, domain, groupID)
			end
		end
		
		--All Profile Upgrades Complete
		TMW.db.profile.Version = TELLMEWHEN_VERSIONNUMBER

	elseif type == "group" then
		local gs, domain, groupID = ...
		
		-- delegate to icons
		for ics, gs, domain, groupID, iconID in TMW:InIconSettings(domain, groupID) do
			TMW:DoUpgrade("icon", version, ics, gs, iconID)
		end
	end
	
	TMW.HaveUpgradedOnce = true
end


function TMW:RawUpgrade()
	
	if TellMeWhenDB.Version == 414069 then
		 -- Well, that was a mighty fine fail that this happened.
		TellMeWhenDB.Version = 41409
	end


	-- Begin DB upgrades that need to be done before defaults are added.
	-- Upgrades here should always do everything needed to every single profile,
	-- and remember to check if a table exists before iterating/indexing it.

	if TellMeWhenDB.profiles then
		if TellMeWhenDB.Version < 41402 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Groups then
					for _, gs in pairs(p.Groups) do
						if gs.Point then
							gs.Point.point = gs.Point.point or "TOPLEFT"
							gs.Point.relativePoint = gs.Point.relativePoint or "TOPLEFT"
						end
					end
				end
			end
		end
		if TellMeWhenDB.Version < 41410 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Version == 414069 then
					p.Version = 41409
				end
				if type(p.Version) == "string" then
					local v = gsub(p.Version, "[^%d]", "") -- remove decimals
					v = v..strrep("0", 5-#v)	-- append zeroes to create a 5 digit number
					p.Version = tonumber(v)
				end
				if type(p.Version) == "number" and p.Version < 41401 and not p.NumGroups then -- 41401 is intended here, i already did a crapper version of this upgrade
					p.NumGroups = 10
				end
			end
		end
		
		if TellMeWhenDB.Version < 46407 then
			local HelpSettings = TellMeWhenDB.global and TellMeWhenDB.global.HelpSettings

			if HelpSettings then
				HelpSettings.ICON_DURS_FIRSTSEE = HelpSettings.NewDurSyntax
				HelpSettings.NewDurSyntax = nil

				HelpSettings.ICON_POCKETWATCH_FIRSTSEE = HelpSettings.PocketWatch
				HelpSettings.PocketWatch = nil
			end
		end

		if TellMeWhenDB.Version < 70001 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Groups then
					for groupID, gs in pairs(p.Groups) do
						if gs.Enabled == nil then
							if groupID == 1 then
								gs.Enabled = true
							else
								gs.Enabled = false
							end
						end
					end
				end
			end
		end
	end
	
	TMW:Fire("TMW_DB_PRE_DEFAULT_UPGRADES")
	TMW:UnregisterAllCallbacks("TMW_DB_PRE_DEFAULT_UPGRADES")
end

function TMW:UpgradeGlobal()
	if TellMeWhenDB.Version < TELLMEWHEN_VERSIONNUMBER then
		TMW:DoUpgrade("global", TellMeWhenDB.Version, TMW.db.global)
	end
end

function TMW:UpgradeProfile()
	-- Set the version for the current profile to the current version if it is a new profile.
	TMW.db.profile.Version = TMW.db.profile.Version or TELLMEWHEN_VERSIONNUMBER
	
	if type(TMW.db.profile.Version) == "string" then
		local v = gsub(TMW.db.profile.Version, "[^%d]", "") -- remove decimals
		v = v..strrep("0", 5-#v)	-- append zeroes to create a 5 digit number
		TMW.db.profile.Version = tonumber(v)
	end
	
	if TMW.db.profile.Version < TELLMEWHEN_VERSIONNUMBER then
		TMW:DoUpgrade("profile", TMW.db.profile.Version, TMW.db.profile, TMW.db:GetCurrentProfile())
	end
end





---------------------------------
-- Update Functions
---------------------------------

do	-- TMW:OnUpdate()

	local updateInProgress, shouldSafeUpdate
	local start
	local inCombatLockdown = 1

	-- Limit in milliseconds for each OnUpdate cycle.
	local CoroutineLimit = 50

	TMW:RegisterEvent("UNIT_FLAGS", function(event, unit)
		if unit == "player" then
			inCombatLockdown = InCombatLockdown()
		end
	end)

	local function checkYield()
		if inCombatLockdown and debugprofilestop() - start > CoroutineLimit then
			TMW:Debug("OnUpdate yielded early at %s", time)

			coroutine.yield()
		end
	end

	-- This is the main update engine of TMW.
	local function OnUpdate()
		while true do
			time = GetTime()
			TMW.time = time

			if updateInProgress then
				-- If the previous update cycle didn't finish (updateInProgress is still true)
				-- then we should enable safecalling icon updates in order to prevent catastrophic failure of the whole addon
				-- if only one icon or icon type is malfunctioning.
				if not shouldSafeUpdate then
					TMW:Debug("Update error detected. Switching to safe update mode!")
				end
				shouldSafeUpdate = true
			end
			updateInProgress = true
			
			TMW:Fire("TMW_ONUPDATE_PRE", time, Locked)
			
			if LastUpdate <= time - UPD_INTV then
				LastUpdate = time
				_, GCD=GetSpellCooldown(GCDSpell)
				TMW.GCD = GCD

				TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_PRE", time, Locked)
				
				if Locked then
					for i = 1, #GroupsToUpdate do
						-- GroupsToUpdate only contains groups with conditions
						local group = GroupsToUpdate[i]
						local ConditionObject = group.ConditionObject
						if ConditionObject and (ConditionObject.UpdateNeeded or ConditionObject.NextUpdateTime < time) then
							ConditionObject:Check()
							checkYield()
						end
					end
			
					if shouldSafeUpdate then
						for i = 1, #IconsToUpdate do
							local icon = IconsToUpdate[i]
							safecall(icon.Update, icon)
							checkYield()
						end
					else
						for i = 1, #IconsToUpdate do
							--local icon = IconsToUpdate[i]
							IconsToUpdate[i]:Update()
							checkYield()
						end
					end
				end

				TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_POST", time, Locked)
			end

			updateInProgress = nil
			
			checkYield()

			TMW:Fire("TMW_ONUPDATE_POST", time, Locked)

			coroutine.yield()
		end
	end

	
	local Coroutine
	function TMW:OnUpdate()
		start = debugprofilestop()

		if not Coroutine or coroutine.status(Coroutine) == "dead" then
			if Coroutine then
				TMW:Debug("Rebirthed OnUpdate coroutine at %s", time)
			end

			Coroutine = coroutine.create(OnUpdate)
		end

		assert(coroutine.resume(Coroutine))
	end
end


function TMW:UpdateNormally()	
	if not TMW.Initialized then
		return
	end
	
	time = GetTime()
	TMW.time = time
	LastUpdate = 0

	
	if not TMW.db.profile.Locked then
		TMW:LoadOptions()

		if TMW:AssertOptionsInitialized() then
			TMW.db.profile.Locked = true
		end
	end

	TMW.Locked = TMW.db.profile.Locked
	Locked = TMW.Locked
	
	wipe(TMW.PreviousGUIDToOwner)
	for k, v in pairs(TMW.GUIDToOwner) do
		TMW.PreviousGUIDToOwner[k] = v
	end
	wipe(TMW.GUIDToOwner)
	
	-- Add a very small amount so that we don't call the same icon multiple times
	-- in the same frame if the interval has been set 0.
	UPD_INTV = TMW.db.profile.Interval + 0.001
	TMW.UPD_INTV = UPD_INTV
	
	TMW:Fire("TMW_GLOBAL_UPDATE") -- the placement of this matters. Must be after options load, but before icons are updated

	for key, Type in pairs(TMW.Types) do
		Type:UpdateColors(true)
	end



	for groupID = 1, max(TMW.db.profile.NumGroups, #TMW.profile) do
		-- Cant use TMW.InGroups() because groups wont exist yet on the first call of this.
		local group = TMW.profile[groupID] or
			TMW.Classes.Group:New("Frame", "TellMeWhen_Group" .. groupID, TMW, "TellMeWhen_GroupTemplate", groupID)

		group.Domain = "profile"
		TMW[group.Domain][groupID] = group

		TMW.safecall(group.Setup, group)
	end

	for groupID = 1, max(TMW.db.global.NumGroups, #TMW.global) do
		-- Cant use TMW.InGroups() because groups wont exist yet on the first call of this.
		local group = TMW.global[groupID] or
			TMW.Classes.Group:New("Frame", "TellMeWhen_GlobalGroup" .. groupID, TMW, "TellMeWhen_GlobalGroupTemplate", groupID)

		group.Domain = "global"
		TMW[group.Domain][groupID] = group

		TMW.safecall(group.Setup, group)
	end



	if not Locked then
		TMW:DoValidityCheck()
	end

	TMW:ScheduleTimer("DoInitialWarn", 3)

	TMW:Fire("TMW_GLOBAL_UPDATE_POST")
end

do -- TMW:UpdateViaCoroutine()

	-- Blizzard's execution cap in combat is 200ms.
	-- We will be extra safe and go for 100ms.
	-- But actually, we will use 50ms, because somehow we are still getting extremely rare 'script ran too long' errors
	local COROUTINE_MAX_TIME_PER_FRAME = 50

	local NumCoroutinesQueued = 0
	local CoroutineStartTime
	local UpdateCoroutine

	local safecall_safe = TMW.safecall

	local function safecall_coroutine(func, ...)
		return true, func(...)
	end

	local function CheckCoroutineTermination()
		if UpdateCoroutine and debugprofilestop() - CoroutineStartTime > COROUTINE_MAX_TIME_PER_FRAME then
			coroutine.yield(UpdateCoroutine)
		end
	end

	local function OnUpdateDuringCoroutine(self)
		-- This is an OnUpdate script, but don't be too concerned with performance because it is only used
		-- when lock toggling in combat. Safety of the code (don't let it error!) is far more important than performance here.
		time = GetTime()
		TMW.time = time
		
		CoroutineStartTime = debugprofilestop()
		
		--if not IsAddOnLoaded("TellMeWhen_Options") then
		--	error("TellMeWhen_Options was not loaded before a coroutine update happened. It is supposed to load before PLAYER_ENTERING_WORLD if the AllowCombatConfig setting is enabled!")
		--end
		
		if NumCoroutinesQueued == 0 then
			TMW.safecall = safecall_safe
			safecall = safecall_safe
			
			--TMW:Print(L["SAFESETUP_COMPLETE"])
			TMW:Fire("TMW_SAFESETUP_COMPLETE")
			
			TMW:SetScript("OnUpdate", TMW.OnUpdate)
		else
			-- Yielding a coroutine inside a pcall/xpcall isn't permitted,
			-- so we will just have to temporarily throw all error protection out the window.
			TMW.safecall = safecall_coroutine
			safecall = safecall_coroutine
			
			if not UpdateCoroutine then
				UpdateCoroutine = coroutine.create(TMW.UpdateNormally)
				CheckCoroutineTermination() -- Make sure we haven't already exceeded this frame's threshold (from loading options, creating the coroutine, etc.)
			end
			
			TMW:RegisterCallback("TMW_ICON_SETUP_POST", CheckCoroutineTermination)
			TMW:RegisterCallback("TMW_GROUP_SETUP_POST", CheckCoroutineTermination)

			
			if coroutine.status(UpdateCoroutine) == "dead" then
				UpdateCoroutine = nil
				NumCoroutinesQueued = NumCoroutinesQueued - 1
			else
				local success, err = coroutine.resume(UpdateCoroutine)
				if not success then
					--TMW:Printf(L["SAFESETUP_FAILED"], err)
					TMW:Fire("TMW_SAFESETUP_COMPLETE")
					TMW:Error(err)
				end
			end
			
			TMW:UnregisterCallback("TMW_ICON_SETUP_POST", CheckCoroutineTermination)
			TMW:UnregisterCallback("TMW_GROUP_SETUP_POST", CheckCoroutineTermination)
		end
	end

	function TMW:UpdateViaCoroutine()
		if NumCoroutinesQueued == 0 then
			--TMW:Print(L["SAFESETUP_TRIGGERED"])
			TMW:Fire("TMW_SAFESETUP_TRIGGERED")
			TMW:SetScript("OnUpdate", OnUpdateDuringCoroutine)
		end
		NumCoroutinesQueued = NumCoroutinesQueued + 1
	end

	TMW:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		if TMW.Initialized then
			if not TMW.ALLOW_LOCKDOWN_CONFIG and not TMW.Locked then
				TMW:LockToggle()
			end
		end
	end)

	do
		-- Auto-loads options if AllowCombatConfig is enabled.
		TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
			if TMW.db.global.AllowCombatConfig then
				TMW:UnregisterThisCallback()
				TMW.ALLOW_LOCKDOWN_CONFIG = true
				TMW:LoadOptions()
			end
		end)
	end
end

-- TMW:Update() sets up all groups, icons, and anything else.
function TMW:Update()
	if InCombatLockdown() then
		TMW:UpdateViaCoroutine()
	else
		TMW:UpdateNormally()
	end
end


local updateHandler
function TMW:ScheduledUpdateHandler()
	if TMW:CheckCanDoLockedAction(false) then
		TMW:Update()
	else
		-- We can't update now. Try again in 5 seconds.
		TMW:ScheduleUpdate(5)
	end
end

function TMW:ScheduleUpdate(delay)
	TMW:CancelTimer(updateHandler, 1)
	updateHandler = TMW:ScheduleTimer("ScheduledUpdateHandler", delay or 1)
end

function TMW:UpdateTalentTextureCache()
	for spec = 1, MAX_TALENT_GROUPS do
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, name, tex = GetTalentInfo(tier, column, GetActiveSpecGroup())

				local lower = name and strlowerCache[name]
				
				if lower then
					SpellTexturesMetaIndex[lower] = tex
				end
			end
		end
	end
end

function TMW:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then
		return
	end

	if not InCombatLockdown() then
		TMW:ScheduleUpdate(.2)
		--TMW:Update()

		TMW:UpdateTalentTextureCache()
	end
end

function TMW:OnProfile(event, arg2, arg3)

	for group, domain in TMW:InGroups() do
		if domain == "profile" then
			for icon in group:InIcons() do
				icon:SetInfo("texture", "")
			end
		end
	end
	
	TMW:UpgradeProfile()

	TMW:Update()
	
	if event == "OnProfileChanged" then
		TMW:Printf(L["PROFILE_LOADED"], arg3)
	end
	
	TMW:Fire("TMW_ON_PROFILE", event, arg2, arg3)
end

function TMW:BARBER_SHOP_OPEN()
	TMW:Hide()
end

function TMW:BARBER_SHOP_CLOSE()
	TMW:Show()
end





---------------------------------
-- Configuration
---------------------------------

function TMW:CheckCanDoLockedAction(message)
	if InCombatLockdown() and not TMW.ALLOW_LOCKDOWN_CONFIG then
		if message ~= false then
			TMW:Print(message or L["ERROR_ACTION_DENIED_IN_LOCKDOWN"])
		end
		return false
	end
	return true
end

function TMW:AssertOptionsInitialized()
	if not TMW.IE or not TMW.IE.Initialized then
		TMW:Print(L["ERROR_NOTINITIALIZED_OPT_NO_ACTION"])
		
		return true
	end

	return false
end

function TMW:LockToggle()
	if not TMW:CheckCanDoLockedAction(L["ERROR_NO_LOCKTOGGLE_IN_LOCKDOWN"]) then
		return
	end
	
	for k, v in pairs(TMW.Warn) do
		-- reset warnings so they can happen again
		if type(k) == "string" then
			TMW.Warn[k] = nil
		end
	end
	TMW.db.profile.Locked = not TMW.db.profile.Locked

	TMW.Locked = TMW.db.profile.Locked

	TMW:Fire("TMW_LOCK_TOGGLED", TMW.db.profile.Locked)

	PlaySound("igCharacterInfoTab")
	TMW:Update()
end

function TMW:SlashCommand(str)
	if not TMW.Initialized then
		TMW:Print(L["ERROR_NOTINITIALIZED_NO_ACTION"])
		return
	end
	
	local cmd, arg2, arg3, arg4 = TMW:GetArgs(str, 4)
	cmd = strlower(cmd or "")

	if cmd == L["CMD_ENABLE"]:lower() then
		cmd = "enable"
	elseif cmd == L["CMD_DISABLE"]:lower() then
		cmd = "disable"
	elseif cmd == L["CMD_TOGGLE"]:lower() then
		cmd = "toggle"
	elseif cmd == L["CMD_PROFILE"]:lower() then
		cmd = "profile"
	elseif cmd == L["CMD_OPTIONS"]:lower() then
		cmd = "options"
	elseif cmd == L["CMD_CHANGELOG"]:lower() then
		cmd = "changelog"
	end

	if cmd == "options" then
		if TMW:CheckCanDoLockedAction() then
			TMW:LoadOptions()

			if TMW:AssertOptionsInitialized() then
				return
			end

			LibStub("AceConfigDialog-3.0"):Open("TMWStandalone")
		end
	elseif cmd == "profile" then
		if TMW.db.profiles[arg2] then
			TMW.db:SetProfile(arg2)
		else
			TMW:Printf(L["CMD_PROFILE_INVALIDPROFILE"], arg2)
			if not arg2:find(" ") then
				TMW:Print(L["CMD_PROFILE_INVALIDPROFILE_SPACES"])
			end
		end
	elseif cmd == "enable" or cmd == "disable" or cmd == "toggle" then
		local groupID, iconID = tonumber(arg2), tonumber(arg3)
		local domain = "profile"

		if not groupID and arg2 and (arg2:lower() == "global" or arg2:lower() == "profile") then
			domain = arg2:lower()
			groupID, iconID = tonumber(arg3), tonumber(arg4)
		end

		if groupID and (groupID > TMW.db[domain].NumGroups or not TMW[domain][groupID]) then
			TMW:Printf("groupID out of range: %d", groupID)
			return
		end

		local obj = groupID and TMW[domain][groupID]
		if iconID then
			if #obj == 0 then
				TMW:Printf("Specified group has not created its icons yet.", iconID)
				return
			elseif iconID > #obj then
				TMW:Printf("iconID out of range: %d", iconID)
				return
			end
			obj = iconID and obj and obj[iconID]
		end

		if obj then
			if cmd == "enable" then
				obj:GetSettings().Enabled = true
			elseif cmd == "disable" then
				obj:GetSettings().Enabled = false
			elseif cmd == "toggle" then
				obj:GetSettings().Enabled = not obj:GetSettings().Enabled
			end
			obj:Setup() -- obj is an icon or a group
		else
			TMW:Print("Bad syntax. Usage: /tmw [enable||disable||toggle] [profile||global] groupID iconID")
		end

	elseif cmd == "changelog" then
		if not TMW.IE then
			if TMW:CheckCanDoLockedAction() then
				TMW:LoadOptions()

				if TMW:AssertOptionsInitialized() then
					return
				end
			end
		end
		if TMW.IE then
			TMW.IE:ShowChangelog(0)
		end
	else
		TMW:LockToggle()
	end
end
TMW:RegisterChatCommand("tmw", "SlashCommand")
TMW:RegisterChatCommand("tellmewhen", "SlashCommand")

function TMW:LoadOptions(recursed)
	--[[ Here's the story of some taint. A better version is at
		http://www.wowace.com/addons/chinchilla/tickets/177-positioning-scaling-minimap-cluster-taints-other-addons/

		TellMeWhen_Options is getting blamed for tainting the item buttons in the quest log.
		I spent a huge amount of time trying to debug this. What it seems to come down to is that TMW
		is somehow tainting OBJECTIVE_TRACKER_UPDATE_REASON and OBJECTIVE_TRACKER_UPDATE_ID,
		which eventually cascades and taints the var that holds the item for a line in the
		quest tracker, which causes UseQuestLogSpecialItem() to get blocked due to taint.

		This taint is happening through these 3 paths:
			Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ObjectiveTracker.lua:995 ObjectiveTracker_Update()
			Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_QuestObjectiveTracker.lua:115 QuestObjectiveTracker_FinishGlowAnim()
			<unnamed>:OnFinished()
		and
			Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ObjectiveTracker.lua:996 ObjectiveTracker_Update()
			Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_QuestObjectiveTracker.lua:115 QuestObjectiveTracker_FinishGlowAnim()
			<unnamed>:OnFinished()
		and
			Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ObjectiveTracker.lua:996 ObjectiveTracker_Update()
			Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_QuestObjectiveTracker.lua:129 QuestObjectiveTracker_FinishFadeOutAnim()
			<unnamed>:OnFinished()

		There is another way that TMW_Options can introduce taint, but this is only when shift-clicking
		on items in the quest log - TMW's ChatEdit_InsertLink hook taints execution, which will taint ACTIVE_CHAT_EDIT_BOX,
		which then tains execution when calling ChatEdit_GetActiveWindow(), which will cause UseQuestLogSpecialItem() to
		be blocked when holding the shift key (Blizzard_QuestObjectiveTracker.lua:192).

		That taint isn't really the issue, though (its sill an issue, but we don't really care). The issue is
		that regular use of quest items is getting blocked. After hours upon hours of debugging, it turns out that
		for some unknown reason, the loading of TellMeWhen_Options is triggering ObjectiveTrackerFrame's OnSizeChanged to fire.
		This function in turn calls ObjectiveTracker_Update(), and there's a fairly good chance that this will be the first time
		that it is called, so it ends up being TMW_Options that initializes a lot of the quest tracker (if TMW_Options is loading immediately).

		Here's that full call stack:
			[string "TMWOPT_taint debug"]:45: in function <[string "TMWOPT_taint debug"]:43>
			[C]: in function `ObjectiveTracker_Update'
			...zzard_ObjectiveTracker\Blizzard_ObjectiveTracker.lua:700: in function <...zzard_ObjectiveTracker\Blizzard_ObjectiveTracker.lua:699>
			[C]: ?
			Interface\AddOns\TellMeWhen\TellMeWhen.lua:3574: in function `LoadOptions'
			Interface\AddOns\TellMeWhen\TellMeWhen.lua:3164: in function `UpdateNormally'
			Interface\AddOns\TellMeWhen\TellMeWhen.lua:3335: in function `Update'
			Interface\AddOns\TellMeWhen\TellMeWhen.lua:1857: in function `?'
			...Ons\Ace3\CallbackHandler-1.0\CallbackHandler-1.0.lua:147: in function <...Ons\Ace3\CallbackHandler-1.0\CallbackHandler-1.0.lua:147>
			[string "safecall Dispatcher[1]"]:4: in function <[string "safecall Dispatcher[1]"]:4>
			[C]: ?
			[string "safecall Dispatcher[1]"]:13: in function `?'
			...Ons\Ace3\CallbackHandler-1.0\CallbackHandler-1.0.lua:92: in function `Fire'
			Interface\AddOns\Ace3\AceEvent-3.0\AceEvent-3.0.lua:120: in function <Interface\AddOns\Ace3\AceEvent-3.0\AceEvent-3.0.lua:119>

		It is worth noting that the taint never happens right away. I don't know what exactly triggers it,
		but it never happens until I've been questing for an hour or so. Because the taint is coming from the 
		OnFinished animation script handlers, I suspect I just have to complete a whole bunch of quests until the stars align and it taints.

		After tearing apart a ton of TellMeWhen_Options for several more hours, I eventually came down to a single thing
		that will reliably cause ObjectiveTrackerFrame:OnSizeChanged to fire due to TMW_Options. Brace yourselves for this:

		With a huge amount of TMW_Options code deleted from the includes.config.xml files, it finally came down to adding/removing 
		the configuration panel for the Sound icon event handler. Even if I replaced it with just "<Frame/>" in the xml file,
		the taint still happened. But, after removing it, the taint stopped. Now, this same action DOES NOT affect the taint
		without the very specific set of files that were not being loaded. I have absolutely no clue why this is what was able to "toggle" the taint,
		but it was. After doing further debugging, it ALWAYS happens immediately after that frame is created, but before the next frame is created.

		So, in further attempts to debug what was going on, I thought to add a call to ObjectiveTracker:GetSize() so I could see what the size was BEFORE
		the OnSizeChanged handler was getting called, so I could see if the size really was changing. And guess what? It doesn't get called anymore after
		I added that in. So, that's the story of why the next line of code exists.

	Addendum:
		After a lot more testing, it turns out that this issue always happens at the same time as the first time that TellMeWhen_Options creates
		a frame in xml (doesn't happen when creating a frame in a Lua file). If TellMeWhen_Options is loaded at the very end of this file,
		the issue doesn't happen. If it is loaded in an ADDON_LOADED handlers after TMW finishes loading, it does happen.
		
		It also only happens when my minimap addon (Chinchilla) is loaded, and is allowed to scale and/or re-position the MinimapCluster.

		I've asked Chinchilla's author to add calls to ObjectiveTrackerFrame:GetSize() so that Chinchilla gets blamed for the taint instead of TMW_Options.
		If TellMeWhen calls ObjectiveTrackerFrame:GetSize(), it will just be TellMeWhen that gets blamed for the taint.

	Addendum 2:
		Despite the changes made to Chinchilla, the issue still happens. It doesn't blame TMW_Options every time, though - sometimes
		it will blame other addons instead. I'm not sure that this bug can ever be fixed unless Blizzard lesses the restrictions on UseQuestLogItemSpecial().
		

	]]

	if IsAddOnLoaded("TellMeWhen_Options") then
		return true
	end
	if not TMW.Initialized then
		TMW:Print(L["ERROR_NOTINITIALIZED_NO_LOAD"])
		return 
	end
	if InCombatLockdown() then
		TMW:Print("Error: Cannot load options while in combat lockdown. Preliminary safety checks were incomplete - this message is a last resort check.")
		return;
	end

	TMW:Print(L["LOADINGOPT"])

	local loaded, reason = LoadAddOn("TellMeWhen_Options")
	if not loaded then
		if reason == "DISABLED" and not recursed then -- prevent accidental recursion
			TMW:Print(L["ENABLINGOPT"])
			EnableAddOn("TellMeWhen_Options")
			TMW:LoadOptions(1)
		else
			local err = L["LOADERROR"] .. _G["ADDON_"..reason]
			TMW:Print(err)
			TMW:Error(err) -- non breaking error
		end
	else
		TMW.ACEOPTIONS:CompileOptions()
		collectgarbage()
	end
end





---------------------------------
-- Version Warnings
---------------------------------

function TMW:PLAYER_ENTERING_WORLD()
	-- Don't send version broadcast messages in developer mode.
	if TELLMEWHEN_VERSION_MINOR ~= "dev" then
		local versionCommString = "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^"
		
		if IsInGuild() then
			TMW:SendCommMessage("TMWV", versionCommString, "GUILD")
		end
		if IsInRaid(LE_PARTY_CATEGORY_HOME) then
			TMW:SendCommMessage("TMWV", versionCommString, "RAID")
		end
		if IsInGroup() then
			TMW:SendCommMessage("TMWV", versionCommString, "PARTY")
		end
		if IsInInstance() then
			TMW:SendCommMessage("TMWV", versionCommString, "INSTANCE_CHAT")
		end
	end
end

function TMW:OnCommReceived(prefix, text, channel, who)
	if prefix == "TMWV" and strsub(text, 1, 1) == "M" and not TMW.VersionWarned and TMW.db.global.VersionWarning then
		local major, minor, revision = strmatch(text, "M:(.*)%^m:(.*)%^R:(.*)%^")
		revision = tonumber(revision)
		
		TMW:Debug("%s has v%s%s (%s)", who, major, minor, revision)
		
		if
			not (revision and major and minor)
			or revision <= TELLMEWHEN_VERSIONNUMBER
			or revision == 414069
			or minor ~= "" and TELLMEWHEN_VERSION_MINOR == ""
		then
			-- If some of the data is missing (i dont know why it would be),
			-- or if the notified revision is less than the currently installed revision,
			-- or if the notified revision is 414069 (the time I fucked up the version number),
			-- or if the notification is from an alpha version and the installed version is not an alpha version,
			-- then don't notify.
			return
		end
		
		TMW.VersionWarned = true
		TMW:Printf(L["NEWVERSION"], major .. minor)
		
	-- Handles data transmission (icons, groups, profiles, etc)
	elseif prefix == "TMW" and TMW.db.profile.ReceiveComm then
		TMW.Received = TMW.Received or {}
		TMW.Received[text] = who or true

		if who then
			TMW.DoPulseReceivedComm = true
			if TMW.db.global.HasImported then
				TMW:Printf(L["MESSAGERECIEVE_SHORT"], who)
			else
				TMW:Printf(L["MESSAGERECIEVE"], who)
			end
		end
	end
end











-- -------------------------------------------------------------------------------------------------
-- |                                                                                               |
-- |                            SPECIALIZED UTILITY AND HELPER FUNCTIONS                           |
-- |                                                                                               |
-- -------------------------------------------------------------------------------------------------









---------------------------------
-- Icon/Group Helper Functions
---------------------------------

TMW.ValidityCheckQueue = {}

function TMW:QueueValidityCheck(checker, checkee, description, ...)
	if not TMW.db.profile.WarnInvalids then return end
	
	tinsert(TMW.ValidityCheckQueue, {checker, checkee, description:format(...)})
end

function TMW:DoValidityCheck()
	for n, tbl in pairs(TMW.ValidityCheckQueue) do
		local checkerIn, checkeeIn, description = unpack(tbl)
		
		local checker, checkee = checkerIn, checkeeIn
		local checkerName = "???"
		
		local message = description .. " "
		local shouldWarn = true
		
		if type(checker) == "string" then
			checker = TMW.GUIDToOwner[checkerIn]
			if not checker then
				TMW:Error("Invalid checker was passed to QueueValidityCheck: %q", checkerIn)
				checkerName = "UNKNOWN" .. (TMW.debug and " " .. checkerIn)
			end
		end
		
		if type(checker) == "table" then
			local group
			if checker.class == TMW.Classes.Icon then
				checkerName = checker:GetIconName(true)

				if not checker.Enabled then
					shouldWarn = false
				end
				if not checker.group:ShouldUpdateIcons() then
					shouldWarn = false
				end

			elseif checker.class == TMW.Classes.Group then
				checkerName = checker:GetGroupName()

				if not checker:ShouldUpdateIcons() then
					shouldWarn = false
				end
			end
		end
		
		message = message .. checkerName
		
		
		if type(checkeeIn) == "string" and TMW:ParseGUID(checkeeIn) then
			checkee = TMW.GUIDToOwner[checkeeIn]
			if not checkee then
				
			end
		end
		
		local checkeeName
		if type(checkee) == "table" then
			if checkee.class == TMW.Classes.Icon then
				checkeeName = checkee:GetIconName(true)
			elseif checkee.class == TMW.Classes.Group then
				checkeeName = checkee:GetGroupName()
			end
			
			if not checkee.IsValid then
				error("checkee does not have an IsValid method: " .. tostring(checkeeIn))
			end
			
			if checkee:IsValid() then
				shouldWarn = false
			end
		end
		
		if checkeeName then
			message = message .. "  (" .. checkeeName .. ") "
		end
		
		message = message .. " " .. L["VALIDITY_ISINVALID"]
		
		if shouldWarn then
			TMW.Warn(message)
		end
	end
	
	wipe(TMW.ValidityCheckQueue)
end


function TMW:GetGroupName(name, groupID, short)
	if (not name) or name == "" then
		if short then
			return groupID
		end
		return format(L["fGROUP"], groupID)
	end

	if short then
		return name .. " (" .. groupID .. ")"
	end

	return name .. " (" .. format(L["fGROUP"], groupID) .. ")"
end





---------------------------------
-- WoW API Helpers
---------------------------------

function TMW.SpellHasNoMana(spell)
	-- TODO: in warlords, you can't determine spell costs anymore. Thanks, blizzard!
	-- This function used to get the spell cost, and determine usability from that, 
	-- but we can't do that anymore. It was a more reliable method because IsUsableSpell
	-- was broken for some abilities (like Jab)

	local _, nomana = IsUsableSpell(spell)
	return nomana
end

local GLADIATOR_STANCE = GetSpellInfo(156291)
function TMW.GetCurrentSpecializationRole()
	-- Watch for PLAYER_SPECIALIZATION_CHANGED for changes to this func's return, and to
	-- UPDATE_SHAPESHIFT_FORM if the player is a warrior.
	local currentSpec = GetSpecialization()
	if not currentSpec then
		return nil
	end

	local _, _, _, _, _, role = GetSpecializationInfo(currentSpec)
	if role == "TANK" and UnitAura("player", GLADIATOR_STANCE) then
		return "DAMAGER"
	end
	return role
end



---------------------------------
-- Generic String Utilities
---------------------------------

local mult = {
	1,						-- seconds per second
	60,						-- seconds per minute
	60*60,					-- seconds per hour
	60*60*24,				-- seconds per day
	60*60*24*365.242199,	-- seconds per year
}
function TMW.toSeconds(str)
	-- converts a string (e.g. "1:45:37") into the number of seconds that it represents (eg. 6337)
	str = ":" .. str:trim(": ") -- a colon is needed at the beginning so that gmatch will catch the first unit of time in the string (minutes, hours, etc)
	local _, numcolon = str:gsub(":", ":") -- count the number of colons in the string so that we can keep track of what multiplier we are on (since we start with the highest unit of time)
	local seconds = 0
	
	for num in str:gmatch(":([0-9%.]*)") do -- iterate over all units of time and their value
		if tonumber(num) and mult[numcolon] then -- make sure that it is valid (there is a number and it isnt a unit of time higher than a year)
			seconds = seconds + mult[numcolon]*num -- multiply the number of units by the number of seconds in that unit and add the appropriate amount of time to the running count
		end
		numcolon = numcolon - 1 -- decrease the current unit of time that is being worked with (even if it was an invalid unit and failed the above check)
	end
	
	return seconds
end

local function replace(text, find, rep)
	-- using this allows for the replacement of ";	   " to "; " in one external call
	assert(not strfind(rep, find), "RECURSION DETECTED: FIND=".. find.. " REP=".. rep)
	while strfind(text, find) do
		text = gsub(text, find, rep)
	end
	return text
end
function TMW:CleanString(text)
	local frame
	if type(text) == "table" and text.GetText then
		frame = text
		text = text:GetText()
	end
	if not text then error("No text to clean!") end
	text = strtrim(text, "; \t\r\n")-- remove all leading and trailing semicolons, spaces, tabs, and newlines
	text = replace(text, "[^:] ;", "; ") -- remove all spaces before semicolons
	text = replace(text, "; ", ";") -- remove all spaces after semicolons
	text = replace(text, ";;", ";") -- remove all double semicolons
	text = replace(text, " :", ":") -- remove all single spaces before colons
	text = replace(text, ":  ", ": ") -- remove all double spaces after colons (DONT REMOVE ALL DOUBLE SPACES EVERYWHERE, SOME SPELLS HAVE TYPO'd NAMES WITH 2 SPACES!)
	text = gsub(text, ";", "; ") -- add spaces after all semicolons. Never used to do this, but it just looks so much better (DONT USE replace!).
	if frame then
		frame:SetText(text)
	end
	return text
end

function TMW:SplitNames(input)
	input = TMW:CleanString(input)
	local tbl = { strsplit(";", input) }
	if #tbl == 1 and tbl[1] == "" then
		tbl[1] = nil
	end

	for a, b in ipairs(tbl) do
		local new = strtrim(b) --remove spaces from the beginning and end of each name
		tbl[a] = tonumber(new) or new -- turn it into a number if it is one
	end
	return tbl
end

TMW.SplitNamesCached = TMW.SplitNames
TMW:MakeSingleArgFunctionCached(TMW, "SplitNamesCached")



function TMW:FormatSeconds(seconds, skipSmall, keepTrailing)
	if abs(seconds) == math.huge then
		return tostring(seconds)
	end

	local y =  seconds / 31556926
	local d = (seconds % 31556926) / 86400
	local h = (seconds % 31556926  % 86400) / 3600
	local m = (seconds % 31556926  % 86400  % 3600) / 60
	local s = (seconds % 31556926  % 86400  % 3600  % 60)

	local ns
	if skipSmall then
		ns = format("%d", s)
	else
		ns = format("%.1f", s)
		if not keepTrailing then
			ns = tonumber(ns)
		end
	end
	if s < 10 and seconds >= 60 then
		ns = "0" .. ns
	end

	if y >= 0x7FFFFFFE then
		return format("OVERFLOW:%d:%02d:%02d:%s", d, h, m, ns)
	end

	if y >= 1 then return format("%d:%d:%02d:%02d:%s", y, d, h, m, ns) end
	if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, ns) end
	if h >= 1 then return format("%d:%02d:%s", h, m, ns) end
	if m >= 1 then return format("%d:%s", m, ns) end

	return ns
end









--TMW.TestTex = TMW:CreateTexture()
function TMW:GetTexturePathFromSetting(setting)
	setting = tonumber(setting) or setting
		
	if setting and setting ~= "" then
		-- See http://us.battle.net/wow/en/forum/topic/5977979895#1 for the resoning behind this stupid shit right here.
		if GetSpellTexture(setting) then
			return GetSpellTexture(setting)
		end
		if strfind(setting, "[\\/]") then -- if there is a slash in it, then it is probably a full path
			return setting:gsub("/", "\\")
		else
			-- if there isn't a slash in it, then it is probably be a wow icon in interface\icons.
			-- it still might be a file in wow's root directory, but fuck, there is no way to tell for sure
			return "Interface\\Icons\\" .. setting
		end
		
		--[[
		-- Pre-MOP code for testing valid textures.
		-- Kept here in a comment for ease of restoring it should it ever start working again.
		
		TMW.TestTex:SetTexture(GetSpellTexture(setting))
		if not TMW.TestTex:GetTexture() then
			TMW.TestTex:SetTexture(setting)
		end
		if not TMW.TestTex:GetTexture() then
			TMW.TestTex:SetTexture("Interface\\Icons\\" .. setting)
		end
		return TMW.TestTex:GetTexture()
		]]
			
	end
end








---------------------------------
-- User-Defined Lua Import Detection
---------------------------------

local detectors = {}
function TMW:RegisterLuaImportDetector(func)
	detectors[func] = true
end

local function recursivelyDetectLua(results, table, ...)
	if type(table) == "table" then
		for func in pairs(detectors) do
			local success, code, name = TMW.safecall(func, table, ...)

			if success and code then
				tinsert(results, {code = code, name = name})
			end
		end

        for a, b in pairs(table) do
            recursivelyDetectLua(results, b, a, ...)
        end
    end
end
function TMW:DetectImportedLua(table)
	local results = {}

	recursivelyDetectLua(results, table)

	if #results == 0 then
		return nil
	end

	return results
end