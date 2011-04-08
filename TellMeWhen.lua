-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune
-- Cybeloras of Mal'Ganis
-- --------------------

-- -------------
-- ADDON GLOBALS AND LOCALS
-- -------------

TMW = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame"), "TellMeWhen", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceComm-3.0")
local TMW = TMW
TMW.Print = TMW.Print or _G.print
TMW.Warn = setmetatable({}, {__call = function(tbl, text)
	if TMW.Warned then
		TMW:Print(text)
	else
		tbl[text] = true
	end
end})
TMW.Icons = {}
TMW.Recieved = {}
TMW.OrderedTypes = {}

local db
local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
--setmetatable({}, {__index = function() return "! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !" end}) -- stress testing for text widths
TMW.L = L
local LBF = LibStub("LibButtonFacade", true)
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

TELLMEWHEN_VERSION = "4.0.1"
TELLMEWHEN_VERSION_MINOR = " beta"
TELLMEWHEN_VERSIONNUMBER = 40103
TELLMEWHEN_MAXGROUPS = 10 	--this is a default, used by SetTheory (addon), so dont rename
TELLMEWHEN_MAXROWS = 20
TELLMEWHEN_MAXCONDITIONS = 1 --this is a default
local UPD_INTV = 0.05	--this is a default, local because i use it in onupdate functions
local EFFICIENCY_THRESHOLD = 15	--this is too

local GetSpellCooldown, GetSpellInfo =
	  GetSpellCooldown, GetSpellInfo
local GetItemInfo, GetInventoryItemID =
	  GetItemInfo, GetInventoryItemID
local GetShapeshiftForm, GetNumShapeshiftForms, GetShapeshiftFormInfo =
	  GetShapeshiftForm, GetNumShapeshiftForms, GetShapeshiftFormInfo
local UnitPower, UnitAffectingCombat, UnitHasVehicleUI =
	  UnitPower, UnitAffectingCombat, UnitHasVehicleUI
local GetNumRaidMembers =
	  GetNumRaidMembers
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget
local strfind, strmatch, format, gsub, strsub, strtrim, strsplit, strlower, min, max, ceil, floor =
	  strfind, strmatch, format, gsub, strsub, strtrim, strsplit, strlower, min, max, ceil, floor
local GetTime, debugstack = GetTime, debugstack
local _G = _G
local _, pclass = UnitClass("Player")
local st, co, talenthandler, BarGCD, ClockGCD, Locked, CNDT, doUpdateIcons
local GCD, NumShapeshiftForms, UpdateTimer = 0, 0, 0
local CUR_TIME = GetTime(); TMW.CUR_TIME = CUR_TIME
local updateicons, unitsToChange = {}, {}


function TMW.tContains(table, item)
	local firstkey
	local num = 0
	for k, v in pairs(table) do
		if v == item then
			num = num + 1
			firstkey = firstkey or k
		end
	end
	return firstkey, num
end local tContains = TMW.tContains
local function ClearScripts(f)
	f:SetScript("OnEvent", nil)
	f:SetScript("OnUpdate", nil)
	if f:HasScript("OnValueChanged") then
		f:SetScript("OnValueChanged", nil)
	end
end

function TMW.print(...)
	if TMW.debug or not TMW.VarsLoaded then
		if ... == TMW then
			print("|cffff0000TMW:|r ", select(2,...))
		else
			print("|cffff0000TMW:|r ", ...)
		end
	end
end
local print = TMW.print

do -- Iterators
	local mg = TELLMEWHEN_MAXGROUPS
	local mi = TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS

	do -- InIconSettings
		local cg = 1
		local ci = 0
		local function iter()
			ci = ci + 1	-- at least increment the icon
			while true do
				if ci <= mi and rawget(db.profile.Groups, cg) and not rawget(db.profile.Groups[cg].Icons, ci) then
					--if there is another icon and the group is valid but the icon settings dont exist, move to the next icon
					ci = ci + 1
				elseif cg <= mg and (ci > mi or not rawget(db.profile.Groups, cg)) then
					-- if there is another group and either the icon exceeds the max or the group has no settings, move to the next group
					cg = cg + 1
					ci = 1
				elseif cg > mg then
					-- if there isnt another group, then stop
					return
				else
					-- we finally found something valid, so use it
					break
				end
			end
			return rawget(db.profile.Groups, cg) and rawget(db.profile.Groups[cg].Icons,ci), cg, ci -- setting table, groupID, iconID
		end

		function TMW.InIconSettings()
			cg = 1
			ci = 0
			mg = TELLMEWHEN_MAXGROUPS
			mi = TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS
			return iter
		end
	end

	do -- InGroupSettings
		local cg = 0
		local function iter()
			cg = cg + 1
			return rawget(db.profile.Groups, cg), cg -- setting table, groupID
		end

		function TMW.InGroupSettings()
			cg = 0
			mg = TELLMEWHEN_MAXGROUPS
			return iter
		end
	end

	do -- InIcons
		local cg = 1
		local ci = 0
		local function iter()
			ci = ci + 1
			while true do
				if ci <= mi and TMW[cg] and not TMW[cg][ci] then
					ci = ci + 1
				elseif cg < mg and (ci > mi or not TMW[cg]) then
					cg = cg + 1
					ci = 1
				elseif cg > mg then
					return
				else
					break
				end
			end
			return TMW[cg] and TMW[cg][ci], cg, ci -- icon, groupID, iconID
		end

		function TMW.InIcons()
			cg = 1
			ci = 0
			mg = TELLMEWHEN_MAXGROUPS
			mi = TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS
			return iter
		end
	end

	do -- InGroups
		local cg = 0
		local function iter()
			cg = cg + 1
			return TMW[cg], cg -- group, groupID
		end

		function TMW.InGroups()
			cg = 0
			mg = TELLMEWHEN_MAXGROUPS
			return iter
		end
	end

	do -- vararg
		local i, t, l = 0, {}
		local function iter(...)
			i = i + 1
			if i > l then return end
			return i, t[i]
		end

		function TMW.Vararg(...)
			i = 0
			wipe(t)
			l = select("#", ...)
			for n = 1, l do
				t[n] = select(n, ...)
			end
			return iter
		end

	end
end

TMW.RelevantSettings = {
	all = {
		Enabled = true,
		Type = true,
		Conditions = true,
	},
}

TMW.DeletedIconSettings = {
	OORColor = true,
	OOMColor = true,
	Color = true,
	ColorOverride = true,
	UnColor = true,
	DurationAndCD = true,
	Shapeshift = true, -- i used this one during some initial testing for shapeshifts
	UnitReact = true,
}

TMW.Defaults = {
	profile = {
--	Version 	= 	TELLMEWHEN_VERSIONNUMBER,  -- DO NOT DEFINE VERSION AS A DEFAULT, OTHERWISE WE CANT TRACK IF A USER HAS AN OLD VERSION BECAUSE IT WILL ALWAYS DEFAULT TO THE LATEST
	Locked 		= 	false,
	NumGroups	=	10,
	Interval	=	UPD_INTV,
	EffThreshold=	EFFICIENCY_THRESHOLD,
	CDCOColor 	= 	{r=0, g=1, b=0, a=1},
	CDSTColor 	= 	{r=1, g=0, b=0, a=1},
	PRESENTColor=	{r=1, g=1, b=1, a=1},
	ABSENTColor	=	{r=1, g=0.35, b=0.35, a=1},
	OORColor	=	{r=0.5, g=0.5, b=0.5, a=1},
	OOMColor	=	{r=0.5, g=0.5, b=0.5, a=1},
	TextureName = 	"Blizzard",
	DrawEdge	=	false,
	TestOn 		= 	false,
	HasImported	=	false,
	ReceiveComm	=	true,
	WarnInvalids=	true,
	Font 		= 	{
		Name = "Arial Narrow",
		Size = 12,
		Outline = "THICKOUTLINE",
		x = -2,
		y = 2,
		OverrideLBFPos = false,
	},
	WpnEnchDurs	=	{
		["*"] = 0,
	},
	EditorScale	=	0.9,
	CheckOrder	=	-1,
	Groups 		= 	{
		[1] = {
			Enabled			= true,
		},
		["**"] = {
			Enabled			= false,
			Locked			= false,
			Name			= "",
			Scale			= 2.0,
			Level			= 10,
			Rows			= 1,
			Columns			= 4,
			Spacing			= 0,
			CheckOrder		= -1,
			OnlyInCombat	= false,
			NotInVehicle	= false,
			PrimarySpec		= true,
			SecondarySpec	= true,
			Tree1			= true,
			Tree2			= true,
			Tree3			= true,
			Stance = {
				["*"] = true
			},
			Point = {
				point = "TOPLEFT",
				relativeTo = "UIParent",
				relativePoint = "TOPLEFT",
				x = 50,
				y = -50,
				defined = false,
			},
			LBF	= {
				Gloss = 0,
				Colors = {},
				Backdrop = false,
				SkinID = "Blizzard",
			},
			--[[Colors = { -- not going to implement this unless people actually want it.
				CCO = 	{r=0,	g=1,	b=0		},	-- cooldown bar complete
				CST = 	{r=1,	g=0,	b=0		},	-- cooldown bar start
				OOR	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range
				OOM	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of mana

				PTA	=	{r=1,	g=1,	b=1		},	-- presnt/usable with timer always
				POA	=	{r=1,	g=1,	b=1		},	-- presnt/usable withOUT timer always
				PTS	=	{r=1,	g=1,	b=1		},	-- presnt/usable with timer somtimes
				POS	=	{r=1,	g=1,	b=1		},	-- presnt/usable withOUT timer somtimes

				ATA	=	{r=1,	g=1,	b=1		},	-- absent/unusable with timer always
				AOA	=	{r=1,	g=1,	b=1		},	-- absent/unusable withOUT timer always
				ATS	=	{r=1,	g=1,	b=1		},	-- absent/unusable with timer somtimes
				AOS	=	{r=1,	g=1,	b=1		},	-- absent/unusable withOUT timer somtimes
			},]]
			Icons = {
				["**"] = {
					BuffOrDebuff		= "HELPFUL",
					BuffShowWhen		= "present",
					CooldownShowWhen	= "usable",
					CooldownType		= "spell",
					Enabled				= false,
					Name				= "",
					OnlyMine			= false,
					ShowTimer			= false,
					ShowTimerText		= true,
					ShowPBar			= false,
					ShowCBar			= false,
					PBarOffs			= 0,
					CBarOffs			= 0,
					InvertBars			= false,
					Type				= "",
					Unit				= "player",
					WpnEnchantType		= "MainHandSlot",
					Icons				= {},
					Alpha				= 1,
					UnAlpha				= 1,
				--	ConditionAlpha		= 0,
					RangeCheck			= false,
					ManaCheck			= false,
					CooldownCheck		= false,
				--	StackAlpha			= 0,
					StackMin			= 0,
					StackMax			= 0,
					StackMinEnabled		= false,
					StackMaxEnabled		= false,
					DurationMin			= 0,
					DurationMax			= 0,
					DurationMinEnabled	= false,
					DurationMaxEnabled	= false,
				--	DurationAlpha		= 0,
					FakeHidden			= false,
					HideUnequipped		= false,
					Interruptible		= false,
					ICDType				= "aura",
					ICDDuration			= 45,
					ICDShowWhen			= "usable",
					CheckNext			= false,
					UseActvtnOverlay	= false,
					OnlyEquipped		= false,
					OnlyInBags			= false,
					OnlySeen			= false,
					TotemSlots			= "1111",
					Conditions = {
						["**"] = {
							AndOr = "AND",
							Type = "HEALTH",
							Icon = "",
							Operator = "==",
							Level = 0,
							Unit = "player",
							Name = "",
							Runes = {},
						},
					},
				},
			},
		},
	},
	},
}
TMW.Group_Defaults = TMW.Defaults.profile.Groups["**"]
TMW.Icon_Defaults = TMW.Group_Defaults.Icons["**"]

TMW.DS = {
	Magic = "Interface\\Icons\\spell_fire_immolation",
	Curse = "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison = "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}

TMW.BE = {	--Much of these are thanks to Malazee @ US-Dalaran's chart: http://forums.wow-petopia.com/download/file.php?mode=view&id=4979 and spreadsheet https://spreadsheets.google.com/ccc?key=0Aox2ZHZE6e_SdHhTc0tZam05QVJDU0lONnp0ZVgzdkE&hl=en#gid=18
	--NOTE: any id prefixed with "_" will have its localized name substituted in instead of being forced to match as an ID
	debuffs = {
		CrowdControl = "339;2637;33786;_118;_1499;19503;19386;20066;10326;9484;6770;2094;51514;76780;710;5782;6358", -- by calico0 of Curse
		Bleeding = "9007;1822;1079;33745;1943;703;94009;43104;89775",
		Incapacitated = "1776;20066;49203",
		Feared = "5782;5246;8122;10326;1513;5484;6789;87204",
		Stunned = "1833;408;91800;5211;9005;22570;19577;56626;44572;82691;853;2812;85388;64044;20549;46968;30283;20252;65929;7922;12809;50519",
		--DontMelee = "5277;871;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",  --does somebody want to update these for me?
		--MovementSlowed = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Ice Trap;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
		Disoriented = "19503;31661;2094;51514;90337",
		Silenced = "_47476;78675;34490;_55021;_15487;1330;_24259;_18498;_25046",
		Disarmed = "_51722;_676;64058;50541;91644",
		Rooted = "_339;_122;23694;58373;64695;_19185;33395;4167;54706;50245;90327;16979;83301;83302",
		PhysicalDmgTaken = "30070;58683;81326;50518;55749",
		SpellDamageTaken = "93068;1490;65142;85547;60433;34889;24844",
		SpellCritTaken = "17800;22959",
		BleedDamageTaken = "33878;33876;16511;46857;50271;35290;57386",
		ReducedAttackSpeed = "6343;55095;58180;68055;8042;90314;50285",
		ReducedCastingSpeed = "1714;5760;31589;73975;50274;50498",
		ReducedArmor = "8647;50498;35387;91565;58567",
		ReducedHealing = "12294;13218;56112;48301;82654;30213;54680",
		ReducedPhysicalDone = "1160;99;26017;81130;702;24423",
	},
	buffs = {
		ImmuneToStun = "642;45438;34471;19574;48792;1022;33786;710",
		ImmuneToMagicCC = "642;45438;34471;19574;33786;710",
		IncreasedStats = "79061;79063;90363",
		IncreasedDamage = "75447;82930",
		IncreasedCrit = "24932;29801;51701;51470;24604;90309",
		IncreasedAP = "79102;53138;19506;30808",
		IncreasedSPsix = "79058;52109",
		IncreasedSPten = "77747;53646",
		IncreasedPhysHaste = "55610;53290;8515",
		IncreasedSpellHaste = "2895;24907;49868",
		BurstHaste = "2825;32182;80353;90355",
		BonusAgiStr = "6673;8076;57330;93435",
		BonusStamina = "79105;469;6307;90364",
		BonusArmor = "465;8072",
		BonusMana = "79058;54424",
		ManaRegen = "54424;79102;5677",
		BurstManaRegen = "29166;16191;64901",
		PushbackResistance = "19746;87717",
		Resistances = "19891;8185",
	},
	casts = {
		Heals = "50464;5185;8936;740;2050;2060;2061;32546;596;64843;635;82326;19750;331;77472;8004;1064;73920",
		PvPSpells = "33786;339;20484;1513;982;64901;605;453;5782;5484;79268;10326;51514;118;12051",
		Tier11Interrupts = "83703;86166;86167;86168;_82752;82636;83070;92454;92455;92456;79710;77896;77569;80734",
	},
	unlisted = {
		-- enrages were extracted from http://db.mmo-champion.com/spells/?dispel_type=9  (hint: view the page source) (there are a few that arent spells anymore, make sure and delete those (look at the tooltip on the name editbox in the editor when you hold down a mod key))
		Enraged = "24689;18499;29131;59465;39575;77238;52262;12292;54508;23257;66092;57733;58942;40076;8599;15061;15716;18501;19451;19812;22428;23128;23342;25503;26041;26051;28371;30485;31540;31915;32714;33958;34670;37605;37648;37975;38046;38166;38664;39031;41254;41447;42705;42745;43139;47399;48138;48142;48193;50420;51513;52470;54427;55285;56646;59697;59707;59828;60075;61369;63227;68541;70371;72143;72146;72147;72148;75998;76100;76862;78722;78943;80084;80467;86736;95436;95459;5229;12880;57514;57518;14201;57516;57519;14202;57520;51170;4146;76816;90872;82033;48702;52537;49029;67233;54781;56729;53361;79420;66759;67657;67658;67659;40601;60177;43292;90045;92946;52071;82759;60430;81772;48391;80158;54475;56769;63147;62071;52610;41364;81021;81022;81016;81017;34392;55462;50636;72203;49016;69052;43664;59694;91668;52461;54356;76691;81706;52309;29340;76487",
		raid = "raid1;raid2;raid3;raid4;raid5;raid6;raid7;raid8;raid9;raid10;raid11;raid12;raid13;raid14;raid15;raid16;raid17;raid18;raid19;raid20;raid21;raid22;raid23;raid24;raid25",
		party = "party1;party2;party3;party4",
		arena = "arena1;arena2;arena3;arena4;arena5",
		boss = "boss1;boss;boss3;boss4",
		maintank = "maintank1;maintank2;maintank3;maintank4;maintank5",
		mainassist = "mainassist1;mainassist2;mainassist3;mainassist4;mainassist5",
	},
}

TMW.EquivIDLookup = {}
TMW.NamesEquivLookup = {}
TMW.OldBE = CopyTable(TMW.BE)
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do
	
		-- create the lookup tables first, so that we can have the first ID even if it will be turned into a name
		local first = strsplit(";", str)
		first = strtrim(first, "; _")
			
		TMW.EquivIDLookup[equiv] = first -- this is used to display them in the list (tooltip, name, id display)
		TMW.OldBE[category][equiv] = gsub(str, "_", "") -- this is used to put icons into tooltips
		TMW.NamesEquivLookup[equiv] = TMW.OldBE[category][equiv]
		
		-- turn all IDs prefixed with "_" into their localized name. Dont do this on every single one, but do use it for spells that do not have any other spells with the same name but different effects.
		
		while strfind(str, "_") do
			local id = strmatch(str, "_%d+")
			if id then
				local name = GetSpellInfo(strtrim(id, " _"))
				str = gsub(str, id, name)
			end
		end
		
		TMW.BE[category][equiv] = str
	end
end
for dispeltype, icon in pairs(TMW.DS) do
	TMW.EquivIDLookup[dispeltype] = icon
end

TMW.GCDSpells = {
	ROGUE=1752, -- sinister strike
	PRIEST=139, -- renew
	DRUID=774, -- rejuvenation
	WARRIOR=772, -- rend
	MAGE=133, -- fireball
	WARLOCK=687, -- demon armor
	PALADIN=20154, -- seal of righteousness
	SHAMAN=324, -- lightning shield
	HUNTER=1978, -- serpent sting
	DEATHKNIGHT=47541, -- death coil
} local GCDSpell = TMW.GCDSpells[pclass]

TMW.ZoneTypes = {
	[0] = NONE,
	[1] = BATTLEGROUND,
	[2] = ARENA,
	[3] = DUNGEON_DIFFICULTY1,
	[4] = DUNGEON_DIFFICULTY2,
	[5] = RAID_DIFFICULTY1,
	[6] = RAID_DIFFICULTY2,
	[7] = RAID_DIFFICULTY3,
	[8] = RAID_DIFFICULTY4,
}

TMW.Cooldowns = setmetatable({}, {__index = function(t, k)
	local n = {}
	t[k] = n
	return n
end})

TMW.Scripts = {} local Scripts = TMW.Scripts

do -- STANCES
	TMW.Stances = {
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
	}

	TMW.CSN = {
		[0] = NONE,
	}

	for k, v in ipairs(TMW.Stances) do
		if v.class == pclass then
			local z = GetSpellInfo(v.id)
			tinsert(TMW.CSN, z)
		end
	end
end local CSN = TMW.CSN


-- --------------------------
-- EXECUTIVE FUNCTIONS, ETC
-- --------------------------


StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
	text = "A complete restart of WoW is required to use TellMeWhen "..TELLMEWHEN_VERSION..TELLMEWHEN_VERSION_MINOR..". Would you like to restart WoW now?", --not worth translating imo, most people will never see it by the time it gets translated.
	button1 = EXIT_GAME,
	button2 = CANCEL,
	OnAccept = ForceQuit,
	OnCancel = function() StaticPopup_Hide("TMW_RESTARTNEEDED") end,
	timeout = 0,
	showAlert = true,
	whileDead = true,
}

if LBF then
	local function SkinCallback(arg1, SkinID, Gloss, Backdrop, Group, Button, Colors)
		if Group and SkinID then
			local groupID = tonumber(strmatch(Group, "%d+")) --Group is a string like "Group 5", so cant use :GetID()
			db.profile.Groups[groupID]["LBF"]["SkinID"] = SkinID
			db.profile.Groups[groupID]["LBF"]["Gloss"] = Gloss
			db.profile.Groups[groupID]["LBF"]["Backdrop"] = Backdrop
			db.profile.Groups[groupID]["LBF"]["Colors"] = Colors
		end
		if not TMW.DontRun then
			TMW:Update()
		else
			TMW.DontRun = false
		end
	end

	LBF:RegisterSkinCallback("TellMeWhen", SkinCallback, TMW)
end

function TMW:OnInitialize()
	CNDT = TMW.CNDT
	if not CNDT then
		-- this also includes upgrading from older than 3.0 (pre-Ace3 DB settings)
		TMW.Warn("A complete restart of WoW is required to use TellMeWhen "..TELLMEWHEN_VERSION..TELLMEWHEN_VERSION_MINOR..". (conditions.lua not found)")
		StaticPopup_Show("TMW_RESTARTNEEDED")
	end

	if type(TellMeWhenDB) ~= "table" then TellMeWhenDB = {} end
	TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
	db = TMW.db

	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups -- need to define before upgrading

	db.profile.Version = db.profile.Version or TELLMEWHEN_VERSIONNUMBER -- this only does anything for new profiles
	if TellMeWhen_Settings or (type(db.profile.Version) == "string") or (db.profile.Version < TELLMEWHEN_VERSIONNUMBER) then
		TMW:Upgrade()
	end
	db.RegisterCallback(TMW, "OnProfileChanged", "OnProfile") -- must set callbacks after TMW:Upgrade() because the db is overwritten there when upgrading from 3.0.0
	db.RegisterCallback(TMW, "OnProfileCopied", "OnProfile")
	db.RegisterCallback(TMW, "OnProfileReset", "OnProfile")
	db.RegisterCallback(TMW, "OnNewProfile", "OnProfile")

	CreateFrame("Frame", nil, InterfaceOptionsFrame):SetScript("OnShow", function()
		TMW:LoadOptions()
	end)

	if LBF then
		LBF:RegisterSkinCallback("TellMeWhen", TellMeWhen_SkinCallback, self)
	end
	TMW:RegisterEvent("PLAYER_ENTERING_WORLD")

	if db.profile.ReceiveComm then
		TMW:RegisterComm("TMW")
		if RegisterAddonMessagePrefix then
			RegisterAddonMessagePrefix("TMW") -- new in WoW 4.1
		end
	end
	 
	if IsInGuild() then
		TMW:SendCommMessage("TMW", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "GUILD")
	end

	TMW.VarsLoaded = true
end

function TMW:OnProfile()
	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups -- need to define before upgrading
	db.profile.Version = db.profile.Version or TELLMEWHEN_VERSIONNUMBER -- this is for new profiles
	if (type(db.profile.Version) == "string") or db.profile.Version < TELLMEWHEN_VERSIONNUMBER then
		TMW:Upgrade()
	end
	for icon in TMW:InIcons() do
		icon:SetTexture(nil)
	end
	TMW:Update()
	TMW:LoadOptions()
end

function TMW:OnTalentUpdate()
	TMW:CancelTimer(talenthandler, 1)
	talenthandler = TMW:ScheduleTimer("Update", 1)
end

function TMW:OnCommReceived(prefix, text, channel, who)
	if prefix ~= "TMW" then return end
	if channel == "GUILD" then
		if TMW.debug then
			print(prefix, text, channel, who)
		end
		if strsub(text, 1, 1) == "R" then
			local major, minor, revision = strmatch(text, "M:(.*)%^m:(.*)%^R:(.*)%^")
			revision = tonumber(revision)
			if revision and major and minor and revision > TELLMEWHEN_VERSIONNUMBER and not TMW.VersionWarned then
				TMW.VersionWarned = true
				TMW:Printf(L["NEWVERSION"], major .. minor)
			end
		end
	elseif channel == "WHISPER" and db.profile.ReceiveComm then
		TMW.Recieved[text] = who or true
		if who then
			if db.profile.HasImported then
				TMW:Printf(L["MESSAGERECIEVE_SHORT"], who)
			else
				TMW:Printf(L["MESSAGERECIEVE"], who)
			end
		end
	end
end

function TMW:OnUpdate()
	CUR_TIME = GetTime()
	TMW.CUR_TIME = CUR_TIME
	if UpdateTimer <= CUR_TIME - UPD_INTV then
		UpdateTimer = CUR_TIME
		_, GCD=GetSpellCooldown(GCDSpell)
		for i = 1, #Scripts do
			local icon = Scripts[i]
			if icon.__shown and icon.group.__shown then
				icon:OnUpdate(CUR_TIME)
			end
		end
		if doUpdateIcons then
			for icon in pairs(updateicons) do
				TMW:Icon_Update(icon)
			end
			wipe(updateicons)
			doUpdateIcons = false
		end

		if TMW.DoWipeAC then
			wipe(TMW.AlreadyChecked)
		end
	end
end


function TMW:Update()
	if not (TMW.EnteredWorld and TMW.VarsLoaded) then return end

	if not TMW.Warned then
		TMW.Warned = true
		for k, v in pairs(TMW.Warn) do
			TMW:Print(k)
		end
	end

	Locked = db.profile.Locked
	CNDT.Env.Locked = Locked
	TMW.DoWipeAC = false
	if not Locked then
		TMW:LoadOptions()
	end
	if TMW.IE then
		TMW.IE:SaveSettings()
	end

	UPD_INTV = db.profile.Interval
	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups
	CNDT.Env.CurrentSpec = GetActiveTalentGroup()
	CNDT.Env.CurrentTree = GetPrimaryTalentTree()
	NumShapeshiftForms = GetNumShapeshiftForms()
	for _, Type in pairs(TMW.Types) do
		Type:Update()
	end

	BarGCD = db.profile["BarGCD"]
	ClockGCD = db.profile["ClockGCD"]

	for group in TMW.InGroups() do
		group:Hide()
	end
	TMW:ColorUpdate() -- r

	wipe(TMW.Icons)

	for groupID = 1, TELLMEWHEN_MAXGROUPS do -- dont use TMW.InGroups()
		TMW:Group_Update(groupID)
	end

	if not Locked then
		TMW:CheckForInvalidIcons()
	end

	if TMW.IE then
		TMW.IE:Load(1) -- for reloading icon editor after copying/dragging something onto an icon in case the icon copied to is the current icon
	end

	TMW.Initd = true
end

function TMW:Upgrade()
	
	if TellMeWhen_Settings then -- needs to be the first one
		TMW:Print()
		for k, v in pairs(TellMeWhen_Settings) do
			db.profile[k] = v
		end
		TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
		db = TMW.db
		db.profile.Version = TellMeWhen_Settings.Version
		TellMeWhen_Settings = nil
	end
	
	if type(db.profile.Version) == "string" then
		local v = gsub(db.profile.Version, "[^%d]", "") -- remove decimals
		v = v..strrep("0", 5-#v)	-- append zeroes to create a 5 digit number
		db.profile.Version = tonumber(v)
	end
	
	--[[if db.profile.Version < 11400 then
		db:ResetProfile()
		return
	end]]
	if db.profile.Version < 12000 then
		db.profile.Spec = nil
	end
	if db.profile.Version < 15300 then
		for ics in TMW.InIconSettings() do
			if ics.Alpha > 1 then
				ics.Alpha = (ics.Alpha / 100)
			else
				ics.Alpha = 1
			end
		end
	end
	if db.profile.Version < 15400 then
		for ics in TMW.InIconSettings() do
			if ics["Alpha"] == 0.01 then ics["Alpha"] = 1 end
		end
	end
	if db.profile.Version < 20100 then
		local needtowarn = ""
		for ics, groupID, iconID in TMW.InIconSettings() do
			for k, v in ipairs(ics.Conditions) do
				v.ConditionLevel = tonumber(v.ConditionLevel) or 0
				if ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
					needtowarn = needtowarn .. (format(L["GROUPICON"], groupID, iconID)) .. ";  "
					v.ConditionLevel = ceil((v.ConditionLevel/100)*3)
				end
			end
		end
		if needtowarn ~= "" then
			TMW.Warn(L["HPSSWARN"] .. " " .. needtowarn)
		end
	end
	if db.profile.Version < 21200 then
		for ics in TMW.InIconSettings() do
			if ics.WpnEnchantType == "thrown" then
				ics.WpnEnchantType = "RangedSlot"
			elseif ics.WpnEnchantType == "offhand" then
				ics.WpnEnchantType = "SecondaryHandSlot"
			elseif ics.WpnEnchantType == "mainhand" then --idk why this would happen, but you never know
				ics.WpnEnchantType = "MainHandSlot"
			end
		end
	end
	if db.profile.Version < 22000 then
		for ics in TMW.InIconSettings() do
			if ics.Conditions then
				for k, v in ipairs(ics.Conditions) do
					if ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
						v.ConditionLevel = 0
					end
				end
			end
		end
	end
	if db.profile.Version < 22010 then
		for ics in TMW.InIconSettings() do
			for i, condition in ipairs(ics.Conditions) do
				for k, v in pairs(condition) do
					condition[gsub(k, "Condition", "")] = v
				end
			end
		end
	end
	if db.profile.Version < 22100 then
		for ics in TMW.InIconSettings() do
			if ics.UnitReact and ics.UnitReact ~= 0 then
				tinsert(ics.Conditions, {
					Type = "REACT",
					Level = ics.UnitReact,
					Unit = "target",
				})
			end
		end
	end
	if db.profile.Version < 23000 then
		for ics in TMW.InIconSettings() do
			if ics.StackMin ~= TMW.Icon_Defaults.StackMin then
				ics.StackMinEnabled = true
			end
			if ics.StackMax ~= TMW.Icon_Defaults.StackMax then
				ics.StackMaxEnabled = true
			end
		end
	end
	if db.profile.Version < 24000 then
		for ics in TMW.InIconSettings() do
			ics.Name = gsub(ics.Name, "StunnedOrIncapacitated", "Stunned;Incapacitated")
			ics.Name = gsub(ics.Name, "IncreasedSPboth", "IncreasedSPsix;IncreasedSPten")
			if ics.Type == "darksim" then
				ics.Type = "multistatecd"
				ics.Name = "77606"
			end
		end
	end
	if db.profile.Version < 24100 then
		for ics in TMW.InIconSettings() do
			if ics.Type == "meta" and type(ics.Icons) == "table" then
				--make values the data, not the keys, so that we can customize the order that they are checked in
				for k, v in pairs(ics.Icons) do
					tinsert(ics.Icons, k)
					ics.Icons[k] = nil
				end
			end
		end
	end
	if db.profile.Version < 30000 then
		db.profile.NumGroups = 10
		db.profile.Condensed = nil
		db.profile.NumCondits = nil
		db.profile.DSN = nil
		db.profile.UNUSEColor = nil
		db.profile.USEColor = nil
		if db.profile.Font.Outline == "THICK" then db.profile.Font.Outline = "THICKOUTLINE" end --oops
		
		for gs in TMW.InGroupSettings() do
			gs.Point.defined = true
			gs.LBFGroup = nil
			for k, v in pairs(gs.Stance) do
				if CSN[k] then
					if v then
						gs.Stance[CSN[k]] = false
					else
						gs.Stance[CSN[k]] = true
					end
					gs.Stance[k] = true
				end
			end
		end
		for ics, groupID, iconID in TMW.InIconSettings() do
			for k in pairs(TMW.DeletedIconSettings) do
				ics[k] = nil
			end
			
			-- this is part of the old CondenseSettings (but modified slightly), just to get rid of values that are defined in the saved variables that dont need to be (basically, they were set automatically on accident, most of them in early versions)
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
				db.profile.Groups[groupID].Icons[iconID] = nil
			end
		end
	end
	if db.profile.Version < 40000 then
		db.profile.Spacing = nil
		db.profile.Locked = false
		
		for gs in TMW.InGroupSettings() do
			gs.Spacing = db.profile.Spacing or 0
		end
		
		for ics in TMW.InIconSettings() do
			if ics.Type == "icd" then
				ics.CooldownShowWhen = ics.ICDShowWhen
				ics.ICDShowWhen = "usable" -- default, to make it go away safely
			end
		end
	end
	if db.profile.Version < 40010 then -- beta4
		for ics in TMW.InIconSettings() do
			if ics.Type == "multistatecd" then
				ics.Type = "cooldown"
				ics.CooldownType = "multistate"
			end
		end
	end
	if db.profile.Version < 40060 then -- beta6
		db.profile.Texture = nil --now i get the texture from LSM the right way instead of saving the texture path
	end
	if db.profile.Version < 40080 then -- beta8
		for gs in TMW.InGroupSettings() do
			if not gs.Stance[L["NONE"]] or not gs.Stance[L["CASTERFORM"]] then
				gs.Stance[L["NONE"]] = true
				gs.Stance[L["CASTERFORM"]] = true
				gs.Stance[NONE] = false -- change it to something that will probably never change
			end
		end
		
		local needtowarn = ""
		for ics, groupID, iconID in TMW.InIconSettings() do
			ics.StackMin = floor(ics.StackMin)
			ics.StackMax = floor(ics.StackMax)
			if (ics.StackMaxEnabled and ics.StackMax == 0) or (ics.DurationMaxEnabled and ics.DurationMax == 0) then -- i changed the default values
				needtowarn = needtowarn .. (format(L["GROUPICON"], groupID, iconID)) .. ";  "
			end
			for k, v in pairs(ics.Conditions) do
				if v.Type == "ECLIPSE_DIRECTION" and v.Level == -1 then
					v.Level = 0
				end
			end
		end
		if needtowarn ~= "" then
			TMW.Warn("The following icons may have had their maximum stacks and/or duration modified, you may wish to check them: " .. needtowarn)
		end
		db.profile.Revision = 77
	end
	
	if db.profile.Version < 40010 then
		for ics in TMW.InIconSettings() do
			for k, condition in pairs(ics.Conditions) do
				if condition.Type == "NAME" then
					condition.Value = 0
				end
			end
		end
		db.profile["BarGCD"] = true
		db.profile["ClockGCD"] = true
	end

	--All Upgrades Complete
	db.profile.Version = TELLMEWHEN_VERSIONNUMBER
end

function TMW:LoadOptions()
	local loaded, reason = LoadAddOn("TellMeWhen_Options")
	if not loaded then
		local err = L["LOADERROR"] .. _G["ADDON_"..reason]
		TMW:Print(err)
		error(err, 0)
	end
	TMW:CompileOptions()
end

function TMW:CheckForInvalidIcons()
	if not db.profile.WarnInvalids then return end
	for gID, gs in pairs(db.profile.Groups) do
		local group = TMW[gID]
		if group and group.Enabled and group.CorrectSpec then
			for iID, is in pairs(gs.Icons) do
				if is.Enabled then
					for k, v in ipairs(is.Conditions) do
						if v.Icon ~= "" and v.Type == "ICON" then
							if not tContains(TMW.Icons, v.Icon) then
								local g, i = strmatch(v.Icon, "TellMeWhen_Group(%d+)_Icon(%d+)")
								g, i = tonumber(g), tonumber(i)
								TMW.Warn(format(L["CONDITIONORMETA_CHECKINGINVALID"], gID, iID, g, i))
							end
						end
					end
					if is.Type == "meta" then
						for k, v in pairs(is.Icons) do
							if not tContains(TMW.Icons, v) then
								local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
								g, i = tonumber(g), tonumber(i)
								TMW.Warn(format(L["CONDITIONORMETA_CHECKINGINVALID"], gID, iID, g, i))
							end
						end
					end
				end
			end
		end
	end
end

function TMW:ColorUpdate()
	st = db.profile.CDSTColor
	co = db.profile.CDCOColor
end


function TMW:PLAYER_ENTERING_WORLD()
	if not TMW.VarsLoaded then return end
	TMW.EnteredWorld = true
	TMW:RegisterEvent("PLAYER_TALENT_UPDATE", "OnTalentUpdate")
	TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "OnTalentUpdate")
	TMW:SetScript("OnUpdate", TMW.OnUpdate)
end

local mtTranslations, maTranslations = {}, {}
function TMW:RAID_ROSTER_UPDATE()
	wipe(mtTranslations)
	wipe(maTranslations)
	local mtN = 1
	local maN = 1
	--setup a table with (key, value) pairs as (oldnumber, newnumber) (oldnumber is 7 for raid7, newnumber is 1 for raid7 when the current maintank/assist is the first one found, 2 for the 2nd one found, etc)
	for i = 1, GetNumRaidMembers() do
		raidunit = "raid" .. i
		if GetPartyAssignment("MAINTANK", raidunit) then
			mtTranslations[mtN] = i
			mtN = mtN + 1
		elseif GetPartyAssignment("MAINASSIST", raidunit) then
			maTranslations[maN] = i
			maN = maN + 1
		end
	end
	
	for original, Units in pairs(unitsToChange) do
		wipe(Units) -- clear unit translations so that we arent referencing incorrect units
		for k, oldunit in ipairs(original) do
			if strfind(oldunit, "maintank") then -- the old unit (maintank1)
				local newunit = gsub(oldunit, "maintank", "raid") -- the new unit (raid7)
				local oldnumber = tonumber(strmatch(newunit, "(%d+)")) -- the old number (7)
				local newnumber = oldnumber and mtTranslations[oldnumber] -- the new number(1)
				if newnumber then
					Units[#Units+1] = gsub(newunit, oldnumber, newnumber)
			--	else -- dont put an invalid unit back into the table, that is just pointless
				--	Units[#Units+1] = oldunit
				end
			elseif strfind(oldunit, "mainassist") then
				local newunit = gsub(oldunit, "mainassist", "raid")
				local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
				local newnumber = oldnumber and maTranslations[oldnumber]
				if newnumber then
					Units[#Units+1] = gsub(newunit, oldnumber, newnumber)
				end
			else
				Units[#Units+1] = oldunit
			end
		end
	end
	local Env = CNDT.Env
	for oldunit in pairs(Env) do
		if strfind(oldunit, "maintank") then
			local newunit = gsub(oldunit, "maintank", "raid")
			local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
			local newnumber = oldnumber and mtTranslations[oldnumber]
			if newnumber then
				Env[oldunit] = gsub(newunit, oldnumber, newnumber)
			else
				Env[oldunit] = oldunit
			end
		elseif strfind(oldunit, "mainassist") then
			local newunit = gsub(oldunit, "mainassist", "raid")
			local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
			local newnumber = oldnumber and maTranslations[oldnumber]
			if newnumber then
				Env[oldunit] = gsub(u, oldnumber, newnumber)
			else
				Env[oldunit] = oldunit
			end
		end
	end
	
end


-- -----------
-- GROUP FRAME
-- -----------

function TMW:GetShapeshiftForm()
	-- very hackey function because of inconsistencies in blizzard's GetShapeshiftForm
	local i = GetShapeshiftForm()
	if pclass == "WARLOCK" and i == 2 then  --metamorphosis is index 2 for some reason
		i = 1
	end
	if pclass == "ROGUE" and i >= 2 then	--vanish and shadow dance return 3 when active, vanish returns 2 when shadow dance isnt learned. Just treat everything as stealth
		i = 1
	end
	if i > NumShapeshiftForms then 	--many classes return an invalid number on login, but not anymore!
		i = 0
	end
	return i or 0
end local GetShapeshiftForm = TMW.GetShapeshiftForm

local GroupAddIns
local function CreateGroup(groupID)
	local group = CreateFrame("Frame", "TellMeWhen_Group" .. groupID, UIParent, "TellMeWhen_GroupTemplate", groupID)
	TMW[groupID] = group
	group:SetID(groupID)
	group.__shown = group:IsShown()
	
	for k, v in pairs(GroupAddIns) do
		if type(group[k]) == "function" then -- if the method already exists on the icon
			group[strlower(k)] = group[k] -- store the old method as the lowercase same name
		end
		group[k] = v
	end
	return group
end

local function Group_StanceCheck(group)
	if not group.CorrectSpec then
		return
	end
	if #(CSN) == 0 then group.CorrectStance = true return end

	local index = GetShapeshiftForm()

	if index == 0 then
		if db.profile.Groups[group:GetID()]["Stance"][CSN[0]] then
			group.CorrectStance = true
		else
			group.CorrectStance = false
		end
	elseif index then
		local _, name = GetShapeshiftFormInfo(index)
		local groupID = group:GetID()
		for k, v in ipairs(CSN) do
			if v == name then
				if db.profile.Groups[groupID]["Stance"][name] then
					group.CorrectStance = true
				else
					group.CorrectStance = false
				end
			end
		end
	end
end

local function Group_ShowHide(group)
	local OnlyInCombat = group.OnlyInCombat
	local NotInVehicle = group.NotInVehicle

	if group.CorrectStance then
		if OnlyInCombat and NotInVehicle then
			if UnitAffectingCombat("player") then
				if UnitHasVehicleUI("player") then
					group:Hide()
				else
					group:Show()
				end
			else
				group:Hide()
			end
		elseif OnlyInCombat then
			if UnitAffectingCombat("player") then
				group:Show()
			else
				group:Hide()
			end
		elseif NotInVehicle then
			if UnitHasVehicleUI("player") then
				group:Hide()
			else
				group:Show()
			end
		else
			group:Show()
		end
	else
		group:Hide()
	end
end

local function Group_OnEvent(group, event, unit)
	if event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
		Group_StanceCheck(group)
	end
	if (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and unit ~= "player" then return end
	Group_ShowHide(group)
end

function TMW:Group_SetPos(groupID)
	local group = TMW[groupID]
	local s = db.profile.Groups[groupID]
	local p = s.Point
	group:ClearAllPoints()
	if p.defined and p.x then
		local relativeTo = _G[p.relativeTo] or "UIParent"
		group:SetPoint(p.point, relativeTo, p.relativePoint, p.x, p.y)
	else
		local groupID=groupID-1
		local xoffs = 50 + 135*floor(groupID/10)
		local yoffs = (floor(groupID/10)*-10)+groupID
		group:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", xoffs, (-50 - (30*yoffs)))
	end
	group:SetScale(s.Scale)
	local Spacing = s.Spacing
	group:SetSize(s.Columns*(30+Spacing)-Spacing, s.Rows*(30+Spacing)-Spacing)
	group:SetFrameLevel(s.Level)
end

function TMW:Group_Update(groupID)
	local group = TMW[groupID] or CreateGroup(groupID)
	group.CorrectStance = true

	for k, v in pairs(TMW.Group_Defaults) do
		group[k] = db.profile.Groups[groupID][k]
	end

	group.CorrectSpec = true
	if (GetActiveTalentGroup()==1 and not group.PrimarySpec) or (GetActiveTalentGroup()==2 and not group.SecondarySpec) or (GetPrimaryTalentTree() and not group["Tree" .. GetPrimaryTalentTree()]) then
		group.CorrectSpec = false
	end

	if LBF then
		TMW.DontRun = true
		local lbfs = db.profile.Groups[groupID]["LBF"]
		LBF:Group("TellMeWhen", L["GROUP"] .. groupID)
		if lbfs.SkinID then
			LBF:Group("TellMeWhen", L["GROUP"] .. groupID):Skin(lbfs.SkinID, lbfs.Gloss, lbfs.Backdrop, lbfs.Colors)
		end
	end

	group:SetFrameLevel(group.Level)
	local Spacing = group.Spacing
	if group.Enabled and group.CorrectSpec then
		for row = 1, group.Rows do
			for column = 1, group.Columns do
				local iconID = (row-1)*group.Columns + column
				local icon = group[iconID] or TMW:CreateIcon(group, groupID, iconID)

				icon:Show()
				icon:SetFrameLevel(group:GetFrameLevel() + 1)
				if column > 1 then
					icon:SetPoint("TOPLEFT", group[iconID-1], "TOPRIGHT", Spacing, 0)
				elseif row > 1 and column == 1 then
					icon:SetPoint("TOPLEFT", group[iconID-group.Columns], "BOTTOMLEFT", 0, -Spacing)
				elseif iconID == 1 then
					icon:SetPoint("TOPLEFT", group, "TOPLEFT")
				end
				TMW:Icon_Update(icon)
			end
		end
		for iconID = group.Rows*group.Columns+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
			local icon = TMW[groupID][iconID]
			if icon then
				icon:Hide()
				ClearScripts(icon)
			end
		end

		group.resizeButton:SetPoint("BOTTOMRIGHT", group[group.Rows*group.Columns], "BOTTOMRIGHT", 3, -3)

		if Locked or group.Locked then
			group.resizeButton:Hide()
		elseif not (Locked or group.Locked) then
			group.resizeButton:Show()
		end
	end

	TMW:Group_SetPos(groupID)

	if group.OnlyInCombat then
		group:RegisterEvent("PLAYER_REGEN_ENABLED")
		group:RegisterEvent("PLAYER_REGEN_DISABLED")
		group:RegisterEvent("PLAYER_ALIVE")
		group:RegisterEvent("PLAYER_DEAD")
		group:RegisterEvent("PLAYER_UNGHOST")
	end
	if group.NotInVehicle then
		group:RegisterEvent("UNIT_ENTERED_VEHICLE")
		group:RegisterEvent("UNIT_EXITED_VEHICLE")
	end

	if group.Enabled and group.CorrectSpec and Locked then
		if #(CSN) > 0 and tContains(group.Stance, false) then
			group:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
			group:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
			Group_StanceCheck(group)
		end
		Group_ShowHide(group)
	else
		group:UnregisterAllEvents()
		if group.Enabled and group.CorrectSpec then
			group:Show()
		else
			group:Hide()
		end
	end

	group:SetScript("OnEvent", Group_OnEvent)
end


-- ------------------
-- ICON SCRIPTS, ETC
-- ------------------

local function OnGCD(d)
	if d == 1 then return true end -- a cd of 1 is always a GCD (or at least isn't worth showing)
	if GCD > 1.7 then return false end -- weed out a cooldown on the GCD spell that might be an interupt (counterspell, mind freeze, etc)
	return GCD == d and d > 0 -- if the duration passed in is the same as the GCD spell, and the duration isnt zero, then it is a GCD
end	TMW.OnGCD = OnGCD

local function SetAlpha(icon, alpha)
	icon.FakeAlpha = alpha
	if alpha ~= icon.__alpha then
		if icon.FakeHidden then
			icon:setalpha(0) -- setalpha(lowercase) is the old, raw SetAlpha. Use it to override FakeAlpha, although this really should never happen ourside of here
			icon.__alpha = 0
		else
			icon:setalpha(alpha)
			icon.__alpha = alpha
		end
	end
end

local function ScriptSort(iconA, iconB)
	local gOrder = -db.profile.CheckOrder
	local gA = iconA.group:GetID()
	local gB = iconB.group:GetID()
	if gA == gB then
		local iOrder = -db.profile.Groups[gA].CheckOrder
		return iconA:GetID()*iOrder < iconB:GetID()*iOrder
	end
	return gA*gOrder < gB*gOrder
end
local function SetScript(icon, handler, func)
	icon[handler] = func
	if handler ~= "OnUpdate" then
		icon:setscript(handler, func)
	else
		tDeleteItem(Scripts, icon)
		if func then
			Scripts[#Scripts+1] = icon
		end
		sort(Scripts, ScriptSort)
	end
end

local function SetCooldown(icon, start, duration, reverse)
	if icon.__start ~= start then
		icon.__start = start
		icon.__duration = duration
		if duration > 0 then
			local cd = icon.cooldown
			cd:SetCooldown(start, duration)
			if reverse ~= nil then -- must be ~= nil
				icon.__reverse = reverse
				cd:SetReverse(reverse)
			end
			cd:Show() --cd:SetAlpha(1) to use omnicc's finish effects properly, but im leaving it alone for now.
		else
			icon.cooldown:Hide()-- cd:SetAlpha(0)
		end
	end
end

local function SetTexture(icon, tex)
	if icon.__tex ~= tex then
		icon.__tex = tex
		icon.texture:SetTexture(tex)
	end
end

local function SetVertexColor(icon, info)
	if icon.__vrtxinfo ~= info then
		icon.__vrtxinfo = info
		if type(info) == "table" then
			icon.texture:SetVertexColor(info.r, info.g, info.b, 1)
		else
			icon.texture:SetVertexColor(info, info, info, 1)
		end
	end

end

local function SetStack(icon, count)
	if icon.__count ~= count then
		icon.__count = count
		if count and count > 1 then
			icon.countText:SetText(count)
		else
			icon.countText:SetText(nil)
		end
	end
end

local function SetReverse(icon, reverse)
	icon.__reverse = reverse
	icon.cooldown:SetReverse(reverse)
end

local function Show(icon)
	icon.__shown = true
	icon:show()
end

local function Hide(icon)
	icon.__shown = false
	icon:hide()
end

local function CDBarOnUpdate(bar)
	local duration = bar.duration
	if bar.InvertBars then
		if duration == 0 then
			bar:SetValue(bar.Max)
		else
			bar:SetMinMaxValues(0, duration)
			bar.Max = duration
			bar:SetValue(CUR_TIME - bar.start + bar.offset)
		end
	else
		if duration == 0 then
			bar:SetValue(0)
		else
			bar:SetMinMaxValues(0,  duration)
			bar.Max = duration
			bar:SetValue(duration - (CUR_TIME - bar.start) + bar.offset)
		end
	end
end

local function CDBarOnValueChanged(bar)
	local start = bar.start
	local duration = bar.duration
	local pct
	if not bar.InvertBars then
		if duration ~= 0 then
			pct = (CUR_TIME - start) / duration
			local inv = 1-pct
			bar.texture:SetTexCoord(0, min(inv, 1), 0, 1)
			bar:SetStatusBarColor(
				(co.r*pct) + (st.r * inv),
				(co.g*pct) + (st.g * inv),
				(co.b*pct) + (st.b * inv),
				(co.a*pct) + (st.a * inv)
			)
		end
	else
		--inverted
		if duration == 0 then
			bar:SetStatusBarColor(co.r, co.g, co.b, co.a)
			bar.texture:SetTexCoord(0, 1, 0, 1)
		else
			pct = (CUR_TIME - start) / duration
			local inv = 1-pct
			bar.texture:SetTexCoord(0, min(pct, 1), 0, 1)
			bar:SetStatusBarColor(
				(co.r*pct) + (st.r * inv),
				(co.g*pct) + (st.g * inv),
				(co.b*pct) + (st.b * inv),
				(co.a*pct) + (st.a * inv)
			)
		end
	end
end

local function CDBarStart(icon, start, duration, buff)
	local bar = icon.cooldownbar
	if start ~= bar.start then
		bar.start = start
		if OnGCD(duration) and BarGCD and not buff then
			duration = 0
		end
		bar.duration = duration
		bar.InvertBars = bar.icon.InvertBars
		if not bar.UpdateSet then
			bar:SetScript("OnUpdate", CDBarOnUpdate)
			bar.UpdateSet = true
		end
	end
end

local function CDBarStop(icon, override)
	local bar = icon.cooldownbar
	if bar.UpdateSet or override then
		bar:SetScript("OnUpdate", nil)
		bar.UpdateSet = false
		if bar.icon.InvertBars then
			bar:SetValue(bar.Max)
		else
			bar:SetValue(0)
		end
	end
end

local function PwrBarOnUpdate(bar)
	local power = UnitPower("player", bar.powerType) + bar.offset
	if not bar.InvertBars then
		bar:SetValue(bar.Max - power)
	else
		bar:SetValue(power)
	end
end

local function PwrBarOnValueChanged(bar, val)
	bar.texture:SetTexCoord(0, max(0, val/bar.Max), 0, 1)
end

local function PwrBarStart(icon, name)
	local bar = icon.powerbar
	bar.name = name
	local cost
	_, _, _, cost, _, bar.powerType = GetSpellInfo(name)
	if cost then
		bar:SetMinMaxValues(0, cost)
		bar.Max = cost
		bar.InvertBars = bar.icon.InvertBars
		if not bar.UpdateSet then
			bar:SetScript("OnUpdate", PwrBarOnUpdate)
			bar.UpdateSet = true
		end
	end
end

local function PwrBarStop(icon, override)
	local bar = icon.powerbar
	if bar.UpdateSet or override then
		bar:SetScript("OnUpdate", nil)
		bar.UpdateSet = false
		if bar.icon.InvertBars then
			bar:SetValue(bar.Max)
		else
			bar:SetValue(0)
		end
	end
end

local IconAddIns = {
	SetAlpha		= 	SetAlpha,
	SetScript		= 	SetScript,
	SetCooldown		= 	SetCooldown,
	CDBarStart		= 	CDBarStart,
	CDBarStop		= 	CDBarStop,
	PwrBarStart		= 	PwrBarStart,
	PwrBarStop		= 	PwrBarStop,
	SetTexture		=	SetTexture,
	SetVertexColor	=	SetVertexColor,
	SetStack		=	SetStack,
	SetReverse		=	SetReverse,
	Show			=	Show,
	Hide			=	Hide,
}

local IconMetamethods = {
	__lt = function(icon1, icon2)
		local g1 = icon1.group:GetID()
		local g2 = icon2.group:GetID()
		if g1 ~= g2 then
			return g1 < g2
		else
			return icon1:GetID() < icon2:GetID()
		end
	end,
	__tostring = function(icon)
		return icon:GetName() or ""
	end
}

GroupAddIns = {
	Show			=	Show,
	Hide			=	Hide,
}

-- -------------
-- ICON FUNCTIONS
-- -------------

TMW.Types = {
	[""] = {
		Setup = function(Type, icon)
			if icon.Name ~= "" then
				icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			else
				icon:SetTexture(nil)
			end
		end,
		Update = function() end
	},
}	TMW.RelevantSettings[""] = {Name = true}


function TMW:CreateIcon(group, groupID, iconID)
	local icon = CreateFrame("Button", "TellMeWhen_Group" .. groupID .. "_Icon" .. iconID, group, "TellMeWhen_IconTemplate", iconID)
	icon.group = group
	group[iconID] = icon
	group.__shown = icon:IsShown()
	CNDT.Env[icon:GetName()] = icon
	local mt = getmetatable(icon)
	for k, v in pairs(IconMetamethods) do
		mt[k] = v
	end
	for k, v in pairs(IconAddIns) do
		if type(icon[k]) == "function" then -- if the method already exists on the icon
			icon[strlower(k)] = icon[k] -- store the old method as the lowercase same name
		end
		icon[k] = v
	end
	return icon
end

function TMW:RegisterIconType(Type, relevantSettings)
	local t = CreateFrame("Frame")
	TMW.Types[Type] = t
	tinsert(TMW.OrderedTypes, Type)
	TMW.RelevantSettings[Type] = relevantSettings
	return t
end

local function Icon_Bars_Update(icon)
	local width, height = icon:GetSize()
	local pbar = icon.powerbar
	local cbar = icon.cooldownbar
	icon.Width = tonumber(icon.Width) or 36*0.9 	--hack to prevent these fields from being functions (see http://www.tukui.org/forums/topic.php?id=9071&view=all and Width = <function> defined @Interface\AddOns\Tukui\core\api.lua:61)
	icon.Height = tonumber(icon.Height) or 36*0.9
	if icon.ShowPBar and icon.NameFirst then
		local _, _, _, cost, _, powerType = GetSpellInfo(icon.NameFirst)
		cost = cost or 0
		pbar:SetSize(width*(icon.Width/36), ((height / 2)*(icon.Height/36))-0.5)
		pbar:SetMinMaxValues(0, cost)
		pbar.Max = cost
		pbar.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
		if powerType then
			local colorinfo = PowerBarColor[powerType]
			pbar:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
		end
		pbar:Show()
		pbar.offset = icon.PBarOffs or 0
		pbar.InvertBars = icon.InvertBars
		icon.PBarOffs = nil --reduce table clutter, we dont need this anymore
		pbar:SetScript("OnValueChanged", PwrBarOnValueChanged)
	else
		pbar:Hide()
	end
	if icon.ShowCBar then
		cbar:SetSize(width*(icon.Width/36), ((height / 2)*(icon.Height/36))-0.5)
		cbar.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
		cbar:SetMinMaxValues(0, 1)
		cbar.Max = 1
		cbar:Show()
		cbar.offset = icon.CBarOffs or 0
		cbar.start = cbar.start or 0
		cbar.duration = cbar.duration or 0
		icon.CBarOffs = nil --reduce table clutter, we dont need this anymore
	--	cbar:SetFrameLevel(icon:GetFrameLevel() - 1)
		cbar.InvertBars = icon.InvertBars
		cbar:SetScript("OnValueChanged", CDBarOnValueChanged)
	else
		cbar:Hide()
	end
end

local function IconsSort(a, b)
	return TMW:GetGlobalIconID(strmatch(a, "TellMeWhen_Group(%d+)_Icon(%d+)")) < TMW:GetGlobalIconID(strmatch(b, "TellMeWhen_Group(%d+)_Icon(%d+)"))
end

function TMW:Icon_Update(icon)
	if not icon then return end
	local iconID = icon:GetID()
	local groupID = icon.group:GetID()

	for k in pairs(TMW.Icon_Defaults) do 	--lets clear any settings that might get left behind.
		icon[k] = nil
	end

	for k in pairs(TMW.RelevantSettings.all) do
		icon[k] = db.profile.Groups[groupID].Icons[iconID][k]
	end
	if TMW.RelevantSettings[icon.Type] then
		for k in pairs(TMW.RelevantSettings[icon.Type]) do
			icon[k] = db.profile.Groups[groupID].Icons[iconID][k]
		end
	end

	icon.Width			= icon.Width or 36*0.9
	icon.Height			= icon.Height or 36*0.9
	icon.UpdateTimer 	= 0
	icon.FakeAlpha 		= 0
	if pclass ~= "DEATHKNIGHT" then
		icon.IgnoreRunes = nil
	end

	icon:UnregisterAllEvents()
	ClearScripts(icon)

	if icon.DurationMinEnabled or icon.DurationMaxEnabled then
		icon.DurationEnabled = true
	else
		icon.DurationEnabled = false
	end
	icon:SetStack(nil)
	if #(icon.Conditions) > 0 and Locked then -- dont define conditions if we are unlocked so that i dont have to deal with meta icons checking icons during config. I think i solved this somewhere else too without thinking about it, but what the hell
		TMW.CNDT:ProcessConditions(icon)
	else
		icon.CndtCheck = nil
	end
	if icon.Enabled and icon.group.Enabled then
		if not tContains(TMW.Icons, icon:GetName()) then tinsert(TMW.Icons, icon:GetName()) end
	else
		local k = tContains(TMW.Icons, icon:GetName())
		if k then tremove(TMW.Icons, k) end
	end
	sort(TMW.Icons, IconsSort)

	local cd = icon.cooldown
	cd.noCooldownCount = not icon.ShowTimerText
	cd:SetDrawEdge(db.profile.DrawEdge)
	icon:SetReverse(false)
	

	local f = db.profile.Font
	local ct = icon.countText
	ct:SetFont(LSM:Fetch("font", f.Name), f.Size, f.Outline)
	if LBF then
		TMW.DontRun = true -- TMW:Update() is ran in the LBF skin callback, which just causes an infinite loop. This tells it not to
		local lbfs = db.profile.Groups[groupID].LBF
		LBF:Group("TellMeWhen", L["GROUP"] .. groupID):AddButton(icon)
		local SkID = lbfs.SkinID or "Blizzard"
		local tbl = LBF:GetSkins()
		if tbl and SkID and tbl[SkID] then
			if SkID == "Blizzard" then --blizzard needs custom overlay bar sizes because of the borders, other skins might like to use this too
				icon.Width = tbl[SkID].Icon.Width*0.9
				icon.Height = tbl[SkID].Icon.Height*0.9
			else
				icon.Width = tonumber(tbl[SkID].Icon.Width) or 36*0.9 		-- possible error here causing this to be a function? 	EDIT: nevermind, it was being caused by Tukui and is fixed in Icon_Bars_Update
				icon.Height = tonumber(tbl[SkID].Icon.Height) or 36*0.9		-- (attempt to perform arithmetic on field 'Width' (a function value)) (occured in Icon_Bars_Update where the CBar size is set)
			end
		end

		if f.OverrideLBFPos then
			ct:ClearAllPoints()
			ct:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", f.x, f.y)
		end
		ct:SetFont(LSM:Fetch("font", f.Name), tbl[SkID].Count.FontSize or f.Size, f.Outline)
		
		cd:SetFrameLevel(icon:GetFrameLevel() - 2)
		icon.cooldownbar:SetFrameLevel(icon:GetFrameLevel() -1)
		icon.powerbar:SetFrameLevel(icon:GetFrameLevel() - 1)
	else
		ct:ClearAllPoints()
		ct:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", f.x, f.y)
		cd:SetFrameLevel(icon:GetFrameLevel() + 1)
		icon.cooldownbar:SetFrameLevel(icon:GetFrameLevel() + 2)
		icon.powerbar:SetFrameLevel(icon:GetFrameLevel() + 2)
	end

	icon.__alpha = nil -- force an alpha update
	icon.__tex = "qq i got reset" -- force a texture update
	if not (Locked and not icon.Enabled) then
		if icon.CooldownShowWhen == "usable" or icon.BuffShowWhen == "present" then
			icon.UnAlpha = 0
		elseif icon.CooldownShowWhen == "unusable" or icon.BuffShowWhen == "absent" then
			icon.Alpha = 0
		end

		if TMW.Types[icon.Type] then
			TMW.Types[icon.Type]:Setup(icon, groupID, iconID)
		else
			if icon.Name ~= "" then
				icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			else
				icon:SetTexture(nil)
			end
		end
	end

	if icon.FakeHidden then
		tDeleteItem(Scripts, icon) -- remove it from the list of scripts to run on update, but dont call SetScript on it because that will remove it and set icon.OnUpdate to nil, which is called by conditions/metas
	end

	icon:SetCooldown(0, 0)

	Icon_Bars_Update(icon, groupID, iconID)
	icon:Show()
	local pbar = icon.powerbar
	local cbar = icon.cooldownbar
	if Locked then
		icon:DisableDrawLayer("BACKGROUND")
		icon:EnableMouse(0)
		if (not icon.Enabled) or (icon.Name == "" and not TMW.Types[icon.Type].AllowNoName) then
			ClearScripts(icon)
			icon:Hide()
		end
		pbar:SetValue(0)
		pbar:SetAlpha(.9)
		if icon.InvertBars then
			cbar:SetValue(cbar.Max)
		else
			cbar:SetValue(0)
		end
		cbar:SetAlpha(.9)
	else
		ClearScripts(icon)
		if icon.Enabled then
			icon:setalpha(1.0)
		else
			icon:setalpha(0.4)
		end
		if not icon.texture:GetTexture() then
			icon:EnableDrawLayer("BACKGROUND")
		else
			icon:DisableDrawLayer("BACKGROUND")
		end
		ClearScripts(cbar)
		cbar.UpdateSet = false
		cbar:SetValue(cbar.Max)
		cbar:SetAlpha(.7)
		cbar:SetStatusBarColor(0, 1, 0, 0.5)
		cbar.texture:SetTexCoord(0, 1, 0, 1)

		ClearScripts(pbar)
		pbar.UpdateSet = false
		pbar:SetValue(2000000)
		pbar:SetAlpha(.7)
		pbar.texture:SetTexCoord(0, 1, 0, 1)

		icon:EnableMouse(1)
		icon:SetVertexColor(1)
		if icon.Type == "meta" then
			cbar:SetValue(0)
			pbar:SetValue(0)
		end
	end
end

function TMW:ScheduleIconUpdate(icon, groupID, iconID)
	-- this is a handler to prevent the spamming of Icon_Update and creating excessive garbage.
	if type(icon) == "number" then --allow omission of icon
		iconID = groupID
		groupID = icon
		assert(groupID ~= 0)
		icon = TMW[groupID] and TMW[groupID][iconID]
	end
	if not icon then return end
	updateicons[icon] = true
	doUpdateIcons = true
end


-- ------------------
-- NAME/ETC FUNCTIONS
-- ------------------

local eqttcache = {}
function TMW:EquivToTable(name)
	name = strlower(name)
	local names
	for k, v in pairs(TMW.BE) do -- check in subtables ('buffs', 'debuffs', 'casts', etc)
		for equiv, str in pairs(v) do
			if strlower(equiv) == name then
				names = str
				break
			end
		end
		if names then break end
	end
	if not names then return end -- if we didnt find an equivalency string then gtfo
	
	if eqttcache[names] then return eqttcache[names] end -- if we already made a table of this string, then use it
	
	local tbl = { strsplit(";", names) } -- split the string into a table
	for a, b in pairs(tbl) do
		local new = strtrim(b) -- take off trailing spaces
		tbl[a] = tonumber(new) or new -- make sure it is a number if it can be
	end
	eqttcache[names] = tbl
	return tbl
end

local gsncache = {}
function TMW:GetSpellNames(icon, setting, firstOnly, toname, dictionary)
	local cachestring = setting .. tostring(firstOnly) .. tostring(toname) .. tostring(dictionary) -- a unique key for the cache table, turn possible nils into strings
	if gsncache[cachestring] then return gsncache[cachestring] end --why make a bunch of tables and do a bunch of stuff if we dont need to
	
	local buffNames = TMW:SplitNames(setting) -- get a table of everything

	--INSERT EQUIVALENCIES
	local k = #buffNames --start at the end of the table, that way we dont have to worry about increasing the key of buffNames to work with every time we insert something
	while k > 0 do
		local eqtt = TMW:EquivToTable(buffNames[k]) -- get the table form of the equivalency string
		if eqtt then
			local n = k	--point to start inserting the values at
			tremove(buffNames, k)	--take the actual equavalancey itself out, because it isnt an actual spell name or anything
			for z, x in ipairs(eqtt) do
				tinsert(buffNames, n, x)	--put the names into the main table
				n = n + 1	--increment the point of insertion
			end
		else
			k = k - 1	--there is no equivalency to insert, so move backwards one key towards zero to the next key
		end
	end

	-- REMOVE DUPLICATES
	local k = #buffNames --start at the end of the table so that we dont remove duplicates at the beginning of the table
	while k > 0 do
		if select(2, tContains(buffNames, buffNames[k])) > 1 then
			tremove(buffNames, k) --if the current value occurs more than once then remove this entry of it
		else
			k = k - 1 --there are no duplicates, so move backwards towards zero
		end
	end

	if dictionary then
		local dictionary = {}
		for k, v in ipairs(buffNames) do
			if toname then
				v = GetSpellInfo(v or "") or v -- turn the value into a name if needed
			end
			if type(v) == "string" then -- all dictionary table lookups use the lowercase string to negate case sensitivity
				v = strlower(v)
			end
			dictionary[v] = true -- put the final value in the table as well (may or may not be the same as the original value
		end
		gsncache[cachestring] = dictionary
		return dictionary
	end
	if toname then
		if firstOnly then
			local ret = GetSpellInfo(buffNames[1] or "") or buffNames[1] -- turn the first value into a name and return it
			gsncache[cachestring] = ret
			return ret
		else
			for k, v in ipairs(buffNames) do
				buffNames[k] = GetSpellInfo(v or "") or v --convert everything to a name
			end
			gsncache[cachestring] = buffNames
			return buffNames
		end
	end
	if firstOnly then
		gsncache[cachestring] = buffNames[1] or ""
		return buffNames[1] or ""
	end
	gsncache[cachestring] = buffNames
	return buffNames
end

function TMW:GetItemIDs(icon, setting, firstOnly, toname)
	-- note: these cannot be cached because of slotIDs
	
	local names = TMW:SplitNames(setting)

	for k, item in ipairs(names) do
		item = strtrim(item) -- trim trailing spaces
		local itemID = tonumber(item) --if it is a number then it might be the itemID if them item
		if not itemID then -- if it wasnt a number then we need to get the itemID of the item
			local _, itemLink = GetItemInfo(item) -- the itemID can be found in the itemlink
			if itemLink then
				itemID = strmatch(itemLink, ":(%d+)") -- extract the itemID from the link
			end
		elseif itemID <= 19 then -- if the itemID was <= 19 then it must be a slotID
			itemID = GetInventoryItemID("player", itemID) -- get the itemID of the slot
		end
		names[k] = tonumber(itemID) or 0 -- finally, put the itemID into the return table
	end

	for k, v in pairs(names) do
		if v == 0 then
			tremove(names, k)
		end
	end

	if toname then
		for k, v in ipairs(names) do
			names[k] = GetItemInfo(v or "") or v -- convert things to names
		end
		if firstOnly then
			return names[1] or 0
		end
		return names
	end
	if firstOnly then
		return names[1] or 0
	end
	return names
end

local unitcache = {}
function TMW:GetUnits(icon, setting)
	if unitcache[setting] then return unitcache[setting] end --why make a bunch of tables and do a bunch of stuff if we dont need to

	setting = TMW:CleanString(setting)
	local Units = TMW:SplitNames(setting) -- get a table of everything

	--INSERT EQUIVALENCIES
	local k = #Units --start at the end of the table, that way we dont have to worry about increasing the key of Units to work with every time we insert something
	while k > 0 do
		local eqtt = TMW:EquivToTable(Units[k]) -- get the table form of the equivalency string
		if eqtt then
			local n = k	--point to start inserting the values at
			tremove(Units, k)	--take the actual equavalancey itself out, because it isnt an actual unit or anything
			for z, x in ipairs(eqtt) do
				tinsert(Units, n, x)	--put the names into the main table
				n = n + 1	--increment the point of insertion
			end
		else
			k = k - 1	--there is no equivalency to insert, so move backwards one key towards zero to the next key
		end
	end

	-- REMOVE DUPLICATES
	local k = #Units --start at the end of the table so that we dont remove duplicates at the beginning of the table
	while k > 0 do
		if select(2, tContains(Units, Units[k])) > 1 then
			tremove(Units, k) --if the current value occurs more than once then remove this entry of it
		else
			k = k - 1 --there are no duplicates, so move backwards towards zero
		end
	end

	--DETECT maintank#, mainassist#, etc, and make them substitute in real unitIDs -- MUST BE LAST
	for k, unit in pairs(Units) do
		if strfind(unit, "^maintank") or strfind(unit, "^mainassist") then
			local original = CopyTable(Units) 	-- copy the original unit table so we know what units to scan for when they may have changed
			unitsToChange[original] = Units 	-- store the table that will be getting changed with the original
			TMW:RegisterEvent("RAID_ROSTER_UPDATE")
			TMW:RAID_ROSTER_UPDATE()
		end
	end

	unitcache[setting] = Units
	return Units
end

function TMW:CleanString(text)
	text = strtrim(text, "; \t\r\n")-- remove all leading and trailing semicolons, spaces, tabs, and newlines
	while strfind(text, " ;") do
		text = gsub(text, " ;", "; ") -- remove all spaces followed by semicolons
	end
	while strfind(text, ";  ") do
		text = gsub(text, ";  ", "; ") -- remove all double spaces between entries
	end
	while strfind(text, ";;") do
		text = gsub(text, ";;", ";") -- remove all double semicolons
	end
	return text
end

function TMW:SplitNames(input)
	input = TMW:CleanString(input)
	local tbl = { strsplit(";", input) }

	for a, b in ipairs(tbl) do
		local new = strtrim(b) --remove spaces from the beginning and end of each name
		tbl[a] = tonumber(new) or new -- turn it into a number if it is one
	end
	return tbl
end

function TMW:DoSetTexture(icon)
	-- used to determine if the texture of an icon should be changed during config (basically, if it's a default texture used for unknowns then try and change it)
	local t = icon.texture:GetTexture()
	if not t or
	t == "Interface\\Icons\\INV_Misc_PocketWatch_01" or
	t == "Interface\\Icons\\INV_Misc_QuestionMark" or
	t == "Interface\\Icons\\Temp" then
		return true
	end
end

function TMW:GetGlobalIconID(g, i)
	i = tostring(i) -- cant take the length of a number
	return tonumber(g .. strrep("0", 3-#i) .. i) -- add zeroes to the beginning of the iconID so that there cant be any duplicate globalIDs
	--for example, 111 could be group1icon11 or group11icon1, whereas 11001 is surely group11icon1 and 1011 is surely group1icon11
end

function TMW:TT(f, title, text, actualtitle, actualtext, override)
	-- setting actualtitle or actualtext true cause it to use exactly what is passed in for title or text as the text in the tooltip
	-- if these variables arent set, then it will attempt to see if the string is a global variable (e.g. "MAXIMUM")
	-- if they arent set and it isnt a global, then it must be a TMW localized string, so use that
	if title then
		title = (actualtitle and title) or _G[title] or L[title]
	end
	if text then
		text = (actualtext and text) or _G[text] or L[text]
	end
	local show = function(self)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(title, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
		GameTooltip:AddLine(text, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		GameTooltip:Show()
	end
	local hide = function()
		GameTooltip:Hide()
	end
	if override then -- completely overwrite the old enter and leave scripts if the tooltip can be changed on a frame, rather than a set it and forget it tooltip
		f:SetScript("OnEnter", show)
		f:SetScript("OnLeave", hide)
	else
		f:HookScript("OnEnter", show)
		f:HookScript("OnLeave", hide)
	end
end

function TMW:LockToggle()
	db.profile.Locked = not db.profile.Locked
	PlaySound("igCharacterInfoTab")
	TMW:Update()
end

function TMW:SlashCommand(str)
	local cmd = TMW:GetArgs(str)
	cmd = strlower(cmd or "")
	if cmd == strlower(L["CMD_OPTIONS"]) or cmd == "options" then --allow unlocalized "options" too
		TMW:LoadOptions()
		LibStub("AceConfigDialog-3.0"):Open("TellMeWhen Options")
	else
		TMW:LockToggle()
	end
end
TMW:RegisterChatCommand("tmw", "SlashCommand")
TMW:RegisterChatCommand("tellmewhen", "SlashCommand")


