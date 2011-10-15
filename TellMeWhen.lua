-- ---------------------------------
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
-- ---------------------------------

-- ---------------------------------
-- ADDON GLOBALS AND LOCALS
-- ---------------------------------

local TMW = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", "TMW", UIParent), "TellMeWhen", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceComm-3.0")
TellMeWhen = TMW

local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
--L = setmetatable({}, {__index = function() return "| ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! " end}) -- stress testing for text widths
TMW.L = L
local LBF = LibStub("LibButtonFacade", true)
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local DRData = LibStub("DRData-1.0", true)

TELLMEWHEN_VERSION = "4.6.3"
TELLMEWHEN_VERSION_MINOR = strmatch(" @project-version@", " r%d+") or ""
TELLMEWHEN_VERSION_FULL = TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR
TELLMEWHEN_VERSIONNUMBER = 46301 -- NEVER DECREASE THIS NUMBER (duh?).  IT IS ALSO ONLY INTERNAL
if TELLMEWHEN_VERSIONNUMBER > 47000 or TELLMEWHEN_VERSIONNUMBER < 46000 then return error("YOU SCREWED UP THE VERSION NUMBER OR DIDNT CHANGE THE SAFETY LIMITS") end -- safety check because i accidentally made the version number 414069 once

TELLMEWHEN_MAXGROUPS = 1 	--this is a default, used by SetTheory (addon), so dont rename
TELLMEWHEN_MAXROWS = 20

---------- Upvalues ----------
local GetSpellCooldown, GetSpellInfo, GetSpellTexture =
	  GetSpellCooldown, GetSpellInfo, GetSpellTexture
local GetShapeshiftForm, GetNumRaidMembers, GetPartyAssignment =
	  GetShapeshiftForm, GetNumRaidMembers, GetPartyAssignment
local UnitPower, PowerBarColor =
	  UnitPower, PowerBarColor
local PlaySoundFile, SendChatMessage =
	  PlaySoundFile, SendChatMessage
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, tDeleteItem = --tDeleteItem is a blizzard function defined in UIParent.lua
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, tDeleteItem
local strfind, strmatch, format, gsub, strsub, strtrim, strsplit, strlower, min, max, ceil, floor =
	  strfind, strmatch, format, gsub, strsub, strtrim, strsplit, strlower, min, max, ceil, floor
local _G, GetTime =
	  _G, GetTime
local MikSBT, Parrot, SCT =
	  MikSBT, Parrot, SCT
local CL_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_PET = COMBATLOG_OBJECT_CONTROL_PLAYER
local bitband = bit.band

---------- Locals ----------
local db, st, co, updatehandler, BarGCD, ClockGCD, Locked, CNDT, SndChan, FramesToFind, UnitsToUpdate, CNDTEnv
local UPD_INTV = 0.06	--this is a default, local because i use it in onupdate functions
local runEvents, updatePBar = 1, 1
local GCD, NumShapeshiftForms, UpdateTimer = 0, 0, 0
local IconUpdateFuncs, GroupUpdateFuncs, unitsToChange = {}, {}, {}
local GroupBase, IconBase = {}, {}
local loweredbackup = {}
local time = GetTime() TMW.time = time
local sctcolor = {r=1, b=1, g=1}
local clientVersion = select(4, GetBuildInfo())
local addonVersion = tonumber(GetAddOnMetadata("TellMeWhen", "X-Interface"))
local _, pclass = UnitClass("Player")

TMW.Print = TMW.Print or _G.print
TMW.Warn = setmetatable(
{}, {
	__call = function(tbl, text)
		if TMW.Warned then
			TMW:Print(text)
		elseif not TMW.tContains(tbl, text) then
			tinsert(tbl, text)
		end
end})

TMW.strlowerCache = setmetatable(
{}, {
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

TMW.SpellTextures = setmetatable(
{
	--hack for pvp tinkets
	[42292] = "Interface\\Icons\\inv_jewelry_trinketpvp_0" .. (UnitFactionGroup("player") == "Horde" and "2" or "1"),
	[strlowerCache[GetSpellInfo(42292)]] = "Interface\\Icons\\inv_jewelry_trinketpvp_0" .. (UnitFactionGroup("player") == "Horde" and "2" or "1"),
},
{
	__index = function(t, name)
		if not name then return end
		-- rawget the strlower because hardcoded entries (talents, mainly) are put into the table as lowercase
		local tex = rawget(t, strlowerCache[name]) or GetSpellTexture(name)
		
		t[name] = tex
		return tex
	end,
	__call = function(t, i)
		return t[i]
	end,
}) local SpellTextures = TMW.SpellTextures

TMW.isNumber = setmetatable(
{}, {
	__index = function(t, i)
		local o = tonumber(i) or false
		t[i] = o
		return o
end}) local isNumber = TMW.isNumber

TMW.Icons = {}
TMW.IconsLookup = {}
TMW.OrderedTypes = {}

function TMW.tContains(table, item, returnNum)
	local firstkey
	local num = 0
	for k, v in pairs(table) do
		if v == item then
			if not returnNum then
				return k
			else
				num = num + 1
				firstkey = firstkey or k
			end
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
	return ...
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
					-- if there is another group and either the icon exceeds the max or the group has no settings, move to the first icon of the next group
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

		function TMW:InIconSettings(groupID)
			cg = groupID or 1
			ci = 0
			mg = groupID or TELLMEWHEN_MAXGROUPS
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

		function TMW:InGroupSettings()
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

		function TMW:InIcons()
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

		function TMW:InGroups()
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

		function TMW:Vararg(...)
			i = 0
			wipe(t)
			l = select("#", ...)
			for n = 1, l do
				t[n] = select(n, ...)
			end
			return iter
		end
	end

	do -- ordered pairs

		local tables = {}
		local unused = {}
		
		local sortByValues, reverse
		local function sorter(a, b)
			if sortByValues then
				a, b = sortByValues[a], sortByValues[b]
			end
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

		local function next(t, state)
			if state == nil then
			
				local key = tables[t][1]
				return key, t[key]
			end
			
			local key
			for i = 1, #tables[t] do
				if tables[t][i] == state then
					key = tables[t][i+1]
					break
				end
			end

			if key then
				return key, t[key]
			end

			unused[#unused+1] = wipe(tables[t])
			tables[t] = nil
			return
		end

		function TMW:OrderedPairs(t, func, rev)
			local orderedIndex = tremove(unused) or {}
			for key in pairs(t) do
				orderedIndex[#orderedIndex + 1] = key
			end
			reverse = rev
			if func == "values" then
				func = sorter
				sortByValues = t
			else
				sortByValues = nil
			end
			sort(orderedIndex, func or sorter)
			tables[t] = orderedIndex
			
			return next, t
		end
	end
end

local RelevantToAll = {
	-- (or almost all, use false to override)
	Enabled = true,
	Name = true,
	Type = true,
	Events = true,
	Conditions = true,
	BindText = true,
	CustomTex = true,
	ShowTimer = true,
	ShowTimerText = true,
	ShowWhen = true,
	FakeHidden = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true
}

local Types = setmetatable({}, {
	__index = function(t, k)
		if type(k) == "table" and k.base == IconBase then -- if the key is an icon, then return the icon's Type table
			return t[k.Type]
		else -- if no type exists, then use the fallback (default) type
			return t[""]
		end
	end
})
TMW.Types = Types

TMW.Defaults = {
	global = {
		EditorScale	=	0.9,
		WpnEnchDurs	= {
			["*"] = 0,
		},
		ClassSpellCache	= {
			["*"] = {},
		},
		HelpSettings = {
			ResetCount = 0,
		},
		CodeSnippets = {
		},
		HasImported			= false,
		ConfigWarning		= true,
	},
	profile = {
	--	Version 	= 	TELLMEWHEN_VERSIONNUMBER,  -- DO NOT DEFINE VERSION AS A DEFAULT, OTHERWISE WE CANT TRACK IF A USER HAS AN OLD VERSION BECAUSE IT WILL ALWAYS DEFAULT TO THE LATEST
		Locked 		= 	false,
		NumGroups	=	1,
		Interval	=	UPD_INTV,
		EffThreshold=	15,
		CDCOColor 	= 	{r=0, g=1, b=0, a=1},
		CDSTColor 	= 	{r=1, g=0, b=0, a=1},
		PRESENTColor=	{r=1, g=1, b=1, a=1},
		ABSENTColor	=	{r=1, g=0.35, b=0.35, a=1},
		OORColor	=	{r=0.5, g=0.5, b=0.5, a=1},
		OOMColor	=	{r=0.5, g=0.5, b=0.5, a=1},
		TextureName = 	"Blizzard",
		DrawEdge	=	false,
		MasterSound	=	false,
		ReceiveComm	=	true,
		WarnInvalids=	true,
		BarGCD		=	true,
		ClockGCD	=	true,
		CheckOrder	=	-1,
		CodeSnippets = {
		},
		Groups 		= 	{
			[1] = {
				Enabled			= true,
			},
			["**"] = {
				Enabled			= false,
				OnlyInCombat	= false,
				Locked			= false,
				Name			= "",
				Strata			= "MEDIUM",
				Scale			= 2.0,
				Level			= 10,
				Rows			= 1,
				Columns			= 4,
				Spacing			= 0,
				CheckOrder		= -1,
				PrimarySpec		= true,
				SecondarySpec	= true,
				Tree1			= true,
				Tree2			= true,
				Tree3			= true,
				Point = {
					point = "CENTER",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					x = 0,
					y = 0,
				},
				LBF	= {
					Gloss = 0,
					Colors = {},
					Backdrop = false,
					SkinID = "Blizzard",
				},
				Fonts = {
					["**"] = {
						Name = "Arial Narrow",
						Size = 12,
						x = -2,
						y = 2,
						point = "CENTER",
						relativePoint = "CENTER",
						Outline = "THICKOUTLINE",
						OverrideLBFPos = false,
						ConstrainWidth = true,
					},
					Count = {
						ConstrainWidth = false,
						point = "BOTTOMRIGHT",
						relativePoint = "BOTTOMRIGHT",
					},
					Bind = {
						y = -2,
						point = "TOPLEFT",
						relativePoint = "TOPLEFT",
					},
				},
				Icons = {
					["**"] = {
						BuffOrDebuff		= "HELPFUL",
						ShowWhen			= "alpha",
						CooldownType		= "spell",
						Enabled				= false,
						Name				= "",
						CustomTex			= "",
						OnlyMine			= false,
						ShowTimer			= false,
						ShowTimerText		= false,
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
						ConditionAlpha		= 0,
						RangeCheck			= false,
						ManaCheck			= false,
						CooldownCheck		= false,
						IgnoreRunes			= false,
						StackMin			= 0,
						StackMax			= 0,
						StackMinEnabled		= false,
						StackMaxEnabled		= false,
						DurationMin			= 0,
						DurationMax			= 0,
						DurationMinEnabled	= false,
						DurationMaxEnabled	= false,
						FakeHidden			= false,
						HideUnequipped		= false,
						Interruptible		= false,
						ICDType				= "aura",
						CheckNext			= false,
						DontRefresh			= false,
						UseActvtnOverlay	= false,
						OnlyEquipped		= false,
						EnableStacks		= false,
						OnlyInBags			= false,
						OnlySeen			= false,
						Stealable			= false,
						IgnoreNomana		= false,
						ShowTTText			= false,
						CheckRefresh		= true,
						TotemSlots			= "111111",
						BindText			= "",
						ConditionDur		= 0,
						UnConditionDur		= 0,
						ConditionDurEnabled	= false,
						UnConditionDurEnabled= false,
						OnlyIfCounting		= false,
						Events = {
							["**"] = {
								Sound = "None",
								Text = "",
								Channel = "",
								Location = "",
								Sticky = false,
								Icon = true,
								r = 1,
								g = 1,
								b = 1,
								Size = 0,
							},
						},
						Conditions = {
							["**"] = {
								AndOr = "AND",
								Type = "HEALTH",
								Icon = "",
								Operator = "==",
								Level = 0,
								Unit = "player",
								Name = "",
								Name2 = "",
								PrtsBefore = 0,
								PrtsAfter = 0,
								Checked = false,
								Checked2 = false,
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
TMW.Group_Defaults.Conditions = TMW.Icon_Defaults.Conditions

TMW.DS = {
	Magic = "Interface\\Icons\\spell_fire_immolation",
	Curse = "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison = "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}
for dispeltype, icon in pairs(TMW.DS) do
	SpellTextures[dispeltype] = icon
end
TMW.BE = {
	--Much of these are thanks to Malazee @ US-Dalaran's chart: http://forums.wow-petopia.com/download/file.php?mode=view&id=4979 and spreadsheet https://spreadsheets.google.com/ccc?key=0Aox2ZHZE6e_SdHhTc0tZam05QVJDU0lONnp0ZVgzdkE&hl=en#gid=18
	--Many more new spells/corrections were provided by Catok of Curse
	--NOTE: any id prefixed with "_" will have its localized name substituted in instead of being forced to match as an ID
	debuffs = {
		CrowdControl = "_118;_339;2637;33786;_1499;_19503;_19386;20066;10326;_9484;_6770;_2094;_51514;76780;_710;_5782;_6358;_49203;_605;82691", -- originally by calico0 of Curse
		Bleeding = "_94009;_1822;_1079;9007;33745;1943;703;43104;89775",
		Incapacitated = "20066;1776;49203",
		Feared = "_5782;5246;_8122;10326;1513;_5484;_6789;87204",
		Slowed = "_116;_120;_15571;13810;_5116;_8056;3600;_1715;_12323;45524;_18223;_15407;_3409;26679;_51693;_2974;_58180;61391;_50434;_55741;44614;_7302;_8034;_63529", -- by algus2
		Stunned = "_1833;_408;_91800;_5211;_56;9005;22570;19577;56626;44572;853;2812;85388;64044;20549;46968;30283;20253;65929;7922;12809;50519;91797;47481;12355;24394;83047;39796;93986;89766;54786",
		--DontMelee = "5277;871;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",  --does somebody want to update these for me?
		--MovementSlowed = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Ice Trap;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
		Disoriented = "_19503;31661;_2094;_51514;90337;88625",
		Silenced = "_47476;78675;34490;_55021;_15487;1330;_24259;_18498;_25046;81261;31935;18425;31117",
		Disarmed = "_51722;_676;64058;50541;91644",
		Rooted = "_339;_122;23694;58373;64695;_19185;33395;4167;54706;50245;90327;16979;83301;83302;45334;19306;55080;87195;63685;19387",
		PhysicalDmgTaken = "30070;58683;81326;50518;55749",
		SpellDamageTaken = "_1490;65142;_85547;60433;93068;34889;24844",
		SpellCritTaken = "17800;22959",
		BleedDamageTaken = "33878;33876;16511;_46857;50271;35290;57386",
		ReducedAttackSpeed = "6343;55095;58180;68055;8042;90314;50285",
		ReducedCastingSpeed = "1714;5760;31589;73975;50274;50498",
		ReducedArmor = "58567;91565;8647;50498;35387",
		ReducedHealing = "12294;13218;56112;48301;82654;30213;54680",
		ReducedPhysicalDone = "1160;99;26017;81130;702;24423",
	},
	buffs = {
		ImmuneToStun = "642;45438;34471;19574;48792;1022;33786;710;46924;19263;47585",
		ImmuneToMagicCC = "642;45438;34471;19574;33786;710;46924;19263;47585;31224;8178;23920;49039",
		IncreasedStats = "79061;79063;90363",
		IncreasedDamage = "75447;82930",
		IncreasedCrit = "24932;29801;51701;51470;24604;90309",
		IncreasedAP = "79102;53138;19506;30808",
		IncreasedSPsix = "_79058;_61316;_52109",
		IncreasedSPten = "77747;53646",
		IncreasedPhysHaste = "55610;53290;8515",
		IncreasedSpellHaste = "2895;24907;49868",
		BurstHaste = "2825;32182;80353;90355",
		BonusAgiStr = "6673;8076;57330;93435",
		BonusStamina = "79105;469;6307;90364",
		BonusArmor = "465;8072",
		BonusMana = "_79058;_61316;54424",
		ManaRegen = "54424;79102;5677",
		BurstManaRegen = "29166;16191;64901",
		PushbackResistance = "19746;87717",
		Resistances = "19891;8185",
		DefensiveBuffs = "48707;30823;33206;47585;871;48792;498;22812;61336;5277;74001;47788;19263;6940;_12976;31850",
		MiscHelpfulBuffs = "89488;10060;23920;68992;31642;54428;2983;1850;29166;16689;53271;1044;31821;45182",
		DamageBuffs = "1719;12292;85730;50334;5217;3045;77801;34692;31884;51713;49016;12472",
	},
	casts = {
		--prefixing with _ doesnt really matter here since casts only match by ID, but it may prevent confusion if people try and use these as buff/debuff equivs
		Heals = "50464;5185;8936;740;2050;2060;2061;32546;596;64843;635;82326;19750;331;77472;8004;1064;73920",
		PvPSpells = "33786;339;20484;1513;982;64901;_605;453;5782;5484;79268;10326;51514;118;12051",
		Tier11Interrupts = "_83703;_82752;_82636;_83070;_79710;_77896;_77569;_80734;_82411",
		Tier12Interrupts = "_97202;_100094",
	},
	dr = {
	},
	unlisted = {
		-- enrages were extracted using the script in the /Scripts folder (source is db.mmo-champion.com)
		Enraged = "24689;18499;2687;29131;59465;39575;77238;52262;12292;54508;23257;66092;57733;58942;40076;8599;15061;15716;18501;19451;19812;22428;23128;23342;25503;26041;26051;28371;30485;31540;31915;32714;33958;34670;37605;37648;37975;38046;38166;38664;39031;41254;41447;42705;42745;43139;47399;48138;48142;48193;50420;51513;52470;54427;55285;56646;59697;59707;59828;60075;61369;63227;68541;70371;72143;72146;72147;72148;75998;76100;76862;78722;78943;80084;80467;86736;95436;95459;5229;12880;57514;57518;14201;57516;57519;14202;57520;14203;57521;14204;57522;51170;4146;76816;90872;82033;48702;52537;49029;67233;54781;56729;53361;79420;66759;67657;67658;67659;40601;51662;60177;63848;43292;90045;92946;52071;82759;60430;81772;48391;80158;101109;101110;54475;56769;63147;62071;52610;41364;81021;81022;81016;81017;34392;55462;50636;72203;49016;69052;43664;59694;91668;52461;54356;76691;81706;52309;29340;76487",
	},
}
if DRData then
	local myCategories = {
		ctrlstun = "DR-ControlledStun",
		scatters = "DR-Scatter",
		fear = "DR-Fear",
		rndstun = "DR-RandomStun",
		silence = "DR-Silence",
		banish = "DR-Banish",
		mc = "DR-MindControl",
		entrapment = "DR-Entrapment",
		taunt = "DR-Taunt",
		disarm = "DR-Disarm",
		horror = "DR-Horrify",
		cyclone = "DR-Cyclone",
		rndroot = "DR-RandomRoot",
		disorient = "DR-Disorient",
		ctrlroot = "DR-ControlledRoot",
		dragons = "DR-DragonsBreath",
	}
	if not GetSpellInfo(74347) then -- invalid
		DRData.spells[74347] = nil
	end
	local dr = TMW.BE.dr
	for spellID, category in pairs(DRData.spells) do
		local k = myCategories[category] or TMW:Error("TMW: The DR category %q is undefined!", 0, category)
		dr[k] = (dr[k] and (dr[k] .. ";" .. spellID)) or tostring(spellID)
	end
end
TMW.OldBE = CopyTable(TMW.BE)
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do
		b[equiv] = gsub(str, "_", "") -- REMOVE UNDERSCORES FROM OLDBE
		
		-- turn all IDs prefixed with "_" into their localized name. Dont do this on every single one, but do use it for spells that do not have any other spells with the same name but different effects.
		while strfind(str, "_") do
			local id = strmatch(str, "_%d+") -- id includes the underscore, trimmed off below
			if id then
				local name = GetSpellInfo(strtrim(id, " _"))
				if name then
					str = gsub(str, id, name)
				else  -- this should never ever ever happen except in new patches if spellIDs were wrong (experience talking)
					local newID = strtrim(id, " _")
					if clientVersion >= addonVersion then -- dont warn for old clients using newer versions
						TMW:Error("Invalid spellID found: " .. newID .. "! Please report this on TMW's CurseForge page, especially if you are currently on the PTR!")
					end
					str = gsub(str, id, newID) -- still need to substitute it to prevent recusion
				end
			end
		end
		TMW.BE[category][equiv] = str
	end
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

TMW.ChannelList = {
	{
		text = NONE,
		channel = "",
	},
	{
		text = CHAT_MSG_SAY,
		channel = "SAY",
		isBlizz = 1,
	},
	{
		text = CHAT_MSG_YELL,
		channel = "YELL",
		isBlizz = 1,
	},
	{
		text = WHISPER,
		channel = "WHISPER",
		isBlizz = 1,
		editbox = 1,
	},
	{
		text = CHAT_MSG_PARTY,
		channel = "PARTY",
		isBlizz = 1,
	},
	{
		text = CHAT_MSG_RAID,
		channel = "RAID",
		isBlizz = 1,
	},
	{
		text = CHAT_MSG_RAID_WARNING,
		channel = "RAID_WARNING",
		isBlizz = 1,
	},
	{
		text = CHAT_MSG_BATTLEGROUND,
		channel = "BATTLEGROUND",
		isBlizz = 1,
	},
	{
		text = L["CHAT_MSG_SMART"],
		desc = L["CHAT_MSG_SMART_DESC"],
		channel = "SMART",
		isBlizz = 1, -- flagged to not use override %t and %f substitutions
	},
	{
		text = L["CHAT_MSG_CHANNEL"],
		desc = L["CHAT_MSG_CHANNEL_DESC"],
		channel = "CHANNEL",
		isBlizz = 1, -- flagged to not use override %t and %f substitutions
		defaultlocation = function() return select(2, GetChannelList()) end,
		dropdown = function()
			for i = 1, math.huge, 2 do
				local num, name = select(i, GetChannelList())
				if not num then break end
				
				local info = UIDropDownMenu_CreateInfo()
				info.func = TMW.ANN.LocDropdownFunc
				info.text = name
				info.arg1 = name
				info.value = name
				info.checked = name == TMW.CI.ics.Events[TMW.ANN.currentEvent].Location
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL) 
			end
		end,
		ddtext = function(value)
			-- also a verification function
			for i = 1, math.huge, 2 do
				local num, name = select(i, GetChannelList())
				if not num then return end
				
				if name == value then
					return value
				end
			end
		end,
	},
	{
		text = CHAT_MSG_GUILD,
		channel = "GUILD",
		isBlizz = 1,
	},
	{
		text = CHAT_MSG_OFFICER,
		channel = "OFFICER",
		isBlizz = 1,
	},
	{
		text = CHAT_MSG_EMOTE,
		channel = "EMOTE",
		isBlizz = 1,
	},
	{
		text = L["CHAT_FRAME"],
		channel = "FRAME",
		icon = 1,
		color = 1,
		defaultlocation = function() return DEFAULT_CHAT_FRAME.name end,
		dropdown = function()
			local i = 1
			while _G["ChatFrame"..i] do 
				local _, _, _, _, _, _, shown, _, docked = FCF_GetChatWindowInfo(i);
				if shown or docked then
					local name = _G["ChatFrame"..i].name
					local info = UIDropDownMenu_CreateInfo()
					info.func = TMW.ANN.LocDropdownFunc
					info.text = name
					info.arg1 = name
					info.value = name
					info.checked = name == TMW.CI.ics.Events[TMW.ANN.currentEvent].Location
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL) 
				end
				i = i + 1
			end
		end,
		ddtext = function(value)
			-- also a verification function
			local i = 1
			while _G["ChatFrame"..i] do 
				if _G["ChatFrame"..i].name == value then
					return value
				end
				i = i + 1
			end
		end,
	},
	{
		text = "Scrolling Combat Text",
		channel = "SCT",
		hidden = not (SCT and SCT:IsEnabled()),
		sticky = 1,
		icon = 1,
		color = 1,
		defaultlocation = SCT and SCT.FRAME1,
		frames = SCT and {
			[SCT.FRAME1] = "Frame 1",
			[SCT.FRAME2] = "Frame 2",
			[SCT.FRAME3 or SCT.MSG] = "SCTD", -- cheesy, i know
			[SCT.MSG] = "Messages",
		},
		dropdown = function()
			if not SCT then return end
			for id, name in pairs(TMW.ChannelLookup.SCT.frames) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = TMW.ANN.LocDropdownFunc
				info.text = name
				info.arg1 = info.text
				info.value = id
				info.checked = id == TMW.CI.ics.Events[TMW.ANN.currentEvent].Location
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end,
		ddtext = function(value)
			if not SCT then return end
			return TMW.ChannelLookup.SCT.frames[value]
		end,
	},
	{
		text = "MikSBT",
		channel = "MSBT",
		hidden = not MikSBT,
		sticky = 1,
		icon = 1,
		color = 1,
		size = 1,
		defaultlocation = "Notification",
		dropdown = function()
			for scrollAreaKey, scrollAreaName in MikSBT:IterateScrollAreas() do
				local info = UIDropDownMenu_CreateInfo()
				info.text = scrollAreaName
				info.value = scrollAreaKey
				info.checked = scrollAreaKey == TMW.CI.ics.Events[TMW.ANN.currentEvent].Location
				info.func = TMW.ANN.LocDropdownFunc
				info.arg1 = scrollAreaName
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end,
		ddtext = function(value)
			if value then
				return MikSBT and select(2, MikSBT:IterateScrollAreas())[value]
			end
		end,
	},
	{
		text = "Parrot",
		channel = "PARROT",
		hidden = not (Parrot and ((Parrot.IsEnabled and Parrot:IsEnabled()) or Parrot:IsActive())),
		sticky = 1,
		icon = 1,
		color = 1,
		size = 1,
		defaultlocation = "Notification",
		dropdown = function()
			local areas = Parrot.GetScrollAreasChoices and Parrot:GetScrollAreasChoices() or Parrot:GetScrollAreasValidate()
			for k, n in pairs(areas) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = n
				info.value = k
				info.func = TMW.ANN.LocDropdownFunc
				info.arg1 = n
				info.checked = k == TMW.CI.ics.Events[TMW.ANN.currentEvent].Location
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end,
		ddtext = function(value)
			if value then
				return (Parrot.GetScrollAreasChoices and Parrot:GetScrollAreasChoices() or Parrot:GetScrollAreasValidate())[value]
			end
		end,
	},
}
TMW.ChannelLookup = {}
for k, v in pairs(TMW.ChannelList) do
	TMW.ChannelLookup[v.channel] = v
end local ChannelLookup = TMW.ChannelLookup

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


if LBF then
	local function SkinCallback(arg1, SkinID, Gloss, Backdrop, Group, Button, Colors)
		if Group and SkinID then
			local groupID = tonumber(strmatch(Group, "%d+")) --Group is a string like "Group 5", so cant use :GetID()
			if groupID then
				db.profile.Groups[groupID]["LBF"]["SkinID"] = SkinID
				db.profile.Groups[groupID]["LBF"]["Gloss"] = Gloss
				db.profile.Groups[groupID]["LBF"]["Backdrop"] = Backdrop
				db.profile.Groups[groupID]["LBF"]["Colors"] = Colors
			end
		end
		if not TMW.DontRun then
			TMW:Update()
		end
	end

	LBF:RegisterSkinCallback("TellMeWhen", SkinCallback, TMW)
end

function TMW:OnInitialize()
	CNDT = TMW.CNDT
	if not rawget(Types, "item") then
		-- this also includes upgrading from older than 3.0 (pre-Ace3 DB settings)
		StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE"],
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
		}
		StaticPopup_Show("TMW_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "item.lua")
	end

	if type(TellMeWhenDB) ~= "table" then
		TellMeWhenDB = {Version = TELLMEWHEN_VERSIONNUMBER}
	end
	TMW:GlobalUpgrade() -- must happen before the db is created

	TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
	db = TMW.db
	local XPac = tonumber(strsub(clientVersion, 1, 1))
	db.global.XPac = db.global.XPac or XPac
	if db.global.XPac ~= XPac then
		wipe(db.global.ClassSpellCache)
	end

	LSM:Register("sound", "Rubber Ducky", [[Sound\Doodad\Goblin_Lottery_Open01.wav]])
	LSM:Register("sound", "Cartoon FX", [[Sound\Doodad\Goblin_Lottery_Open03.wav]])
	LSM:Register("sound", "Explosion", [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.wav]])
	LSM:Register("sound", "Shing!", [[Sound\Doodad\PortcullisActive_Closed.wav]])
	LSM:Register("sound", "Wham!", [[Sound\Doodad\PVP_Lordaeron_Door_Open.wav]])
	LSM:Register("sound", "Simon Chime", [[Sound\Doodad\SimonGame_LargeBlueTree.wav]])
	LSM:Register("sound", "War Drums", [[Sound\Event Sounds\Event_wardrum_ogre.wav]])
	LSM:Register("sound", "Cheer", [[Sound\Event Sounds\OgreEventCheerUnique.wav]])
	LSM:Register("sound", "Humm", [[Sound\Spells\SimonGame_Visual_GameStart.wav]])
	LSM:Register("sound", "Short Circuit", [[Sound\Spells\SimonGame_Visual_BadPress.wav]])
	LSM:Register("sound", "Fel Portal", [[Sound\Spells\Sunwell_Fel_PortalStand.wav]])
	LSM:Register("sound", "Fel Nova", [[Sound\Spells\SeepingGaseous_Fel_Nova.wav]])
	LSM:Register("sound", "You Will Die!", [[Sound\Creature\CThun\CThunYouWillDie.wav]])

	LSM:Register("sound", "Die!", [[Sound\Creature\GruulTheDragonkiller\GRULLAIR_Gruul_Slay03.wav]])
	LSM:Register("sound", "You Fail!", [[Sound\Creature\Kologarn\UR_Kologarn_slay02.wav]])
	
	LSM:Register("sound", "TMW - Pling 1", [[Interface\Addons\TellMeWhen\Sounds\Pling1.ogg]])
	LSM:Register("sound", "TMW - Pling 2", [[Interface\Addons\TellMeWhen\Sounds\Pling2.ogg]])
	LSM:Register("sound", "TMW - Pling 3", [[Interface\Addons\TellMeWhen\Sounds\Pling3.ogg]])
	LSM:Register("sound", "TMW - Pling 4", [[Interface\Addons\TellMeWhen\Sounds\Pling4.ogg]])
	LSM:Register("sound", "TMW - Pling 5", [[Interface\Addons\TellMeWhen\Sounds\Pling5.ogg]])
	LSM:Register("sound", "TMW - Pling 6", [[Interface\Addons\TellMeWhen\Sounds\Pling6.ogg]])
	LSM:Register("sound", "TMW - Ding 1", [[Interface\Addons\TellMeWhen\Sounds\Ding1.ogg]])
	LSM:Register("sound", "TMW - Ding 2", [[Interface\Addons\TellMeWhen\Sounds\Ding2.ogg]])
	LSM:Register("sound", "TMW - Ding 3", [[Interface\Addons\TellMeWhen\Sounds\Ding3.ogg]])
	LSM:Register("sound", "TMW - Ding 4", [[Interface\Addons\TellMeWhen\Sounds\Ding4.ogg]])
	LSM:Register("sound", "TMW - Ding 5", [[Interface\Addons\TellMeWhen\Sounds\Ding5.ogg]])
	LSM:Register("sound", "TMW - Ding 6", [[Interface\Addons\TellMeWhen\Sounds\Ding6.ogg]])
	LSM:Register("sound", "TMW - Ding 7", [[Interface\Addons\TellMeWhen\Sounds\Ding7.ogg]])
	LSM:Register("sound", "TMW - Ding 8", [[Interface\Addons\TellMeWhen\Sounds\Ding8.ogg]])
	LSM:Register("sound", "TMW - Ding 9", [[Interface\Addons\TellMeWhen\Sounds\Ding9.ogg]])

	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups -- need to define before upgrading

	db.profile.Version = db.profile.Version or TELLMEWHEN_VERSIONNUMBER -- this only does anything for new profiles
	if TellMeWhen_Settings or (type(db.profile.Version) == "string") or (db.profile.Version < TELLMEWHEN_VERSIONNUMBER) then
		TMW:Upgrade()
	end
	db.RegisterCallback(TMW, "OnProfileChanged", "OnProfile") -- must set callbacks after TMW:Upgrade() because the db is overwritten there when upgrading from 3.0.0
	db.RegisterCallback(TMW, "OnProfileCopied", "OnProfile")
	db.RegisterCallback(TMW, "OnProfileReset", "OnProfile")
	db.RegisterCallback(TMW, "OnNewProfile", "OnProfile")
	db.RegisterCallback(TMW, "OnProfileShutdown", "ShutdownProfile")
	db.RegisterCallback(TMW, "OnDatabaseShutdown", "ShutdownProfile")
	
	
	TMW.ClassSpellCache = db.global.ClassSpellCache
	local function AddID(id)
		local name, _, tex = GetSpellInfo(id)
		name = strlowerCache[name]
		if name and not SpellTextures[name] then
			SpellTextures[name] = tex
		end
	end
	for id in pairs(TMW.ClassSpellCache[pclass]) do
		-- do current class's spells first to discourage overwrites
		AddID(id)
	end
	for class, tbl in pairs(TMW.ClassSpellCache) do
		if class ~= pclass and class ~= "PET" then
			for id in pairs(tbl) do
				AddID(id)
			end
		end
	end
	for id in pairs(TMW.ClassSpellCache.PET) do
		-- do pets last so pet spells dont take the place of class spells
		AddID(id)
	end


	if LBF then
		LBF:RegisterSkinCallback("TellMeWhen", TellMeWhen_SkinCallback, self)
	end
	TellMeWhenDB.AuraCache = TellMeWhenDB.AuraCache or {}
	TMW.AuraCache = TellMeWhenDB.AuraCache
	TMW:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	TMW:RegisterEvent("PLAYER_ENTERING_WORLD")
	TMW:RegisterEvent("PLAYER_TALENT_UPDATE")
	TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

	if db.profile.ReceiveComm then
		TMW:RegisterComm("TMW")
	end
	TMW:RegisterComm("TMWV")

	if IsInGuild() then
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "GUILD")
	end
	TMW:PLAYER_ENTERING_WORLD()

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
	TMW.IE:Load(1, TMW:InIcons()()) -- hack to get the first icon that exists
	
	if TMW.CompileOptions then TMW:CompileOptions() end -- redo groups in the options
end

TMW.DatabaseCleanups = {
	icon = function(ics)
		if ics.Events then
			for _, t in pairs(ics.Events) do
				t.SoundData = nil
			end
		end
	end,
}
function TMW:ShutdownProfile()
	-- get rid of settings that are stored in database tables for convenience, but dont need to be kept.
	for ics in TMW:InIconSettings() do
		TMW.DatabaseCleanups.icon(ics)
	end
end

function TMW:ScheduleUpdate(delay)
	TMW:CancelTimer(updatehandler, 1)
	updatehandler = TMW:ScheduleTimer("Update", delay)
end

function TMW:OnCommReceived(prefix, text, channel, who)
	if prefix == "TMWV" and strsub(text, 1, 1) == "M" and not TMW.VersionWarned then
		local major, minor, revision = strmatch(text, "M:(.*)%^m:(.*)%^R:(.*)%^")
		print(prefix, who, major, minor, revision)
		revision = tonumber(revision)
		if not (revision and major and minor and revision > TELLMEWHEN_VERSIONNUMBER and revision ~= 414069) then
			return
		elseif not ((minor == "" and who ~= "Cybeloras") or (tonumber(strsub(revision, 1, 3)) > tonumber(strsub(TELLMEWHEN_VERSIONNUMBER, 1, 3)) + 1)) then
			return
		end
		TMW.VersionWarned = true
		TMW:Printf(L["NEWVERSION"], major .. minor)
	elseif prefix == "TMW" and channel == "WHISPER" and db.profile.ReceiveComm then
		TMW.Received = TMW.Received or {}
		TMW.Received[text] = who or true
		if who then
			TMW.DoPulseReceivedComm = true
			if db.global.HasImported then
				TMW:Printf(L["MESSAGERECIEVE_SHORT"], who)
			else
				TMW:Printf(L["MESSAGERECIEVE"], who)
			end
		end
	end
end

function TMW:OnUpdate() -- this is where all icon OnUpdate scripts are actually called
	time = GetTime()
	CNDTEnv.time = time
	TMW.time = time
	if UpdateTimer <= time - UPD_INTV then
		UpdateTimer = time
		_, GCD=GetSpellCooldown(GCDSpell)
		CNDTEnv.GCD = GCD
		
		if FramesToFind then
			-- I hate to do this, but this is the only way to detect frames that are created by an upvalued CreateFrame (*cough* VuhDo) (Unless i raw hook it, but CreateFrame should probably be secure)
			for group, frameName in pairs(FramesToFind) do
				if _G[frameName] then
					group:SetPos()
					FramesToFind[group] = nil
					if not next(FramesToFind) then
						FramesToFind = nil
						break
					end
				end
			end
		end
		if not Locked then return end
		
		for i = 1, #GroupUpdateFuncs do
			local CndtCheck = GroupUpdateFuncs[i].CndtCheck
			if CndtCheck then
				CndtCheck()
			end
		end

		for i = 1, #IconUpdateFuncs do
			local icon = IconUpdateFuncs[i]
			if icon.__shown then
				icon:OnUpdate(time)
			end
		end

		if TMW.DoWipeAC then
			wipe(TMW.AlreadyChecked)
		end
		updatePBar = nil
		if UnitsToUpdate then
			wipe(UnitsToUpdate)
		end
	end
end


function TMW:Update()
	if not (TMW.EnteredWorld and TMW.VarsLoaded) then return end

	if not TMW.Warned then
		TMW.Warned = true
		for k, v in ipairs(TMW.Warn) do
			TMW:Print(v)
		end
	end
	
	TMW.DontRun = true -- TMW:Update() is ran in the LBF skin callback, which just causes an infinite loop. This tells it not to

	time = GetTime() TMW.time = time
	UpdateTimer = time - 10
	runEvents = nil
	updatePBar = 1

	Locked = db.profile.Locked
	CNDTEnv = CNDT.Env
	CNDTEnv.Locked = Locked
	TMW.DoWipeAC = false
	if not Locked then
		TMW:LoadOptions()
		if db.global.ConfigWarning then -- oh no! confguration code in the main addon!
			TellMeWhen_ConfigWarning:Show()
		else
			TellMeWhen_ConfigWarning:Hide()
		end
	else
		if TellMeWhen_ConfigWarning then
			TellMeWhen_ConfigWarning:Hide()
		end
	end
	TMW:SetScript("OnUpdate", TMW.OnUpdate)

	if TMW.IE then
		TMW.IE:SaveSettings()
	end

	UPD_INTV = db.profile.Interval
	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups
	CNDTEnv.CurrentSpec = GetActiveTalentGroup()
	CNDTEnv.CurrentTree = GetPrimaryTalentTree()
	NumShapeshiftForms = GetNumShapeshiftForms()

	BarGCD = db.profile.BarGCD
	ClockGCD = db.profile.ClockGCD
	SndChan = db.profile.MasterSound and "Master" or nil

	for group in TMW.InGroups() do
		group:Hide()
	end
	TMW:ColorUpdate()

	wipe(TMW.Icons)
	wipe(TMW.IconsLookup)

	for groupID = 1, TELLMEWHEN_MAXGROUPS do -- dont use TMW.InGroups() because that will setup every group that exists, even if it shouldn't be setup (i.e. it has been deleted or the user changed profiles)
		TMW:Group_Update(groupID)
	end

	if not Locked then
		TMW:CheckForInvalidIcons()
	end

	time = GetTime() TMW.time = time
	TMW:ScheduleTimer("RestoreSound", UPD_INTV*2.1)
	TMW.Initd = true
	TMW.DontRun = false
end

local upgradeTable
function TMW:GetUpgradeTable() -- upgrade functions
	if upgradeTable then return upgradeTable end
	local t = {
	
		[46202] = {
			icon = function(ics)
				if ics.CooldownType == "item" and ics.Type == "cooldown" then
					ics.Type = "item"
					ics.CooldownType = TMW.Icon_Defaults.CooldownType
				end
			end,
		},
		[45802] = {
			icon = function(ics)
				for i, condition in pairs(ics.Conditions) do
					if condition.Type == "CASTING" then
						condition.Name = ""
					end
				end
			end,
		},
		[45608] = {
			icon = function(ics)
				if not ics.ShowTimer then
					ics.ShowTimerText = false
				end
			end,
		},
		[45605] = {
			global = function()
				if db.global.SeenNewDurSyntax then
					db.global.HelpSettings.NewDurSyntax = db.global.SeenNewDurSyntax
					db.global.SeenNewDurSyntax = nil
				end
			end,
		},
		[45402] = {
			group = function(gs)
				gs.OnlyInCombat = false
			end,
		},
		[45013] = {
			icon = function(ics)
				if ics.Type == "conditionicon" then
					ics.Alpha = 1
					ics.UnAlpha = ics.ConditionAlpha
					ics.ConditionAlpha = 0
				end
			end,
		},
		[45008] = {
			group = function(gs)
				if gs.Font then
					for k, v in pairs(gs.Font) do
						gs.Fonts.Count[k] = v
						gs.Font[k] = nil
					end
				end
			end,
		},
		[44202] = {
			icon = function(ics)
				ics.Conditions["**"] = nil
			end,
		},
		[44009] = {
			global = function()
				if type(db.profile.WpnEnchDurs) == "table" then
					for k, v in pairs(db.profile.WpnEnchDurs) do
						db.global.WpnEnchDurs[k] = max(db.global.WpnEnchDurs[k] or 0, v)
					end
					db.profile.WpnEnchDurs = nil
				end
				db.profile.HasImported = nil
			end,
		},
		[44003] = {
			icon = function(ics)
				if ics.Type == "unitcooldown" or ics.Type == "icd" then
					local duration = ics.ICDDuration or 45 -- 45 was the old default
					ics.Name = TMW:CleanString(gsub(ics.Name..";", ";", ": "..duration.."; "))
					ics.ICDDuration = nil
				end
			end,
		},
		[44002] = {
			icon = function(ics)
				if ics.Type == "autoshot" then
					ics.Type = "cooldown"
					ics.CooldownType = "spell"
					ics.Name = 75
				end
			end,
		},
		[43009] = {
			icon = function(ics)
				for k, v in pairs(ics.Events) do
					if v.Location == "FRAME1" then
						v.Location = 1
					elseif v.Location == "FRAME2" then
						v.Location = 2
					elseif v.Location == "MSG" then
						v.Location = 10
					end
				end
			end,
		},
		[43005] = {
			icon = function(ics)
				ics.ANN = nil -- whoops, forgot to to this a while back when ANN was replaced with the new event data structure
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
			icon = function(ics, self)
				local setting = self.WhenChecks[ics.Type]
				if setting then
					ics.ShowWhen = self.Conversions[ics[setting] or self.Defaults[setting]] or ics[setting] or self.Defaults[setting]
				end
				ics.CooldownShowWhen = nil
				ics.BuffShowWhen = nil
			end,
		},
		[43001] = {
			group = function(gs)
				if db.profile.Font then
					gs.Font = gs.Font or {}
					for k, v in pairs(db.profile.Font) do
						gs.Font[k] = v
					end
				end
			end,
			postglobal = function()
				db.profile.Font = nil
			end
		},
		[42105] = {
			-- cleanup some old stuff that i noticed is sticking around in my settings, probably in other peoples' settings too
			icon = function(ics)
				for _, condition in pairs(ics.Conditions) do
					for k in pairs(condition) do
						if strfind(k, "Condition") then
							condition[k] = nil
						end
					end
					condition.Names = nil
				end
				for _, t in pairs(ics.Events) do
					if t.Sound == "" then -- major screw up
						t.Sound = "None"
					end
				end
			end,
		},
		[42103] = {
			icon = function(ics)
				for _, t in pairs(ics.Events) do
					if t.Announce then
						t.Text, t.Channel = strsplit("\001", t.Announce)
						t.Announce = nil
					end
				end
			end,
		},
		[42102] = {
			icon = function(ics)
				local Events = ics.Events
				Events.OnShow = {
					Sound = ics.SoundOnShow or "None",
					Announce = ics.ANNOnShow or "\001",
				}
				Events.OnHide = {
					Sound = ics.SoundOnHide or "None",
					Announce = ics.ANNOnHide or "\001",
				}
				Events.OnStart = {
					Sound = ics.SoundOnStart or "None",
					Announce = ics.ANNOnStart or "\001",
				}
				Events.OnFinish = {
					Sound = ics.SoundOnFinish or "None",
					Announce = ics.ANNOnFinish or "\001",
				}
				ics.SoundOnShow		= nil
				ics.SoundOnHide		= nil
				ics.SoundOnStart	= nil
				ics.SoundOnFinish	= nil
				ics.ANNOnShow		= nil
				ics.ANNOnHide		= nil
				ics.ANNOnStart		= nil
				ics.ANNOnFinish		= nil
			end,
		},
		[41402] = {
			group = function(gs)
				gs.Point.defined = nil
			end,
		},
		[41301] = {
			group = function(gs)
				local Conditions = gs.Conditions

				if gs.OnlyInCombat then
					local condition = Conditions[#Conditions + 1]
					condition.Type = "COMBAT"
					condition.Level = 0
					gs.OnlyInCombat = nil
				end
				if gs.NotInVehicle then
					local condition = Conditions[#Conditions + 1]
					condition.Type = "VEHICLE"
					condition.Level = 1
					gs.NotInVehicle = nil
				end
				if gs.Stance then
					local nume = {}
					local numd = {}
					for id = 0, #TMW.CSN do
						local sn = TMW.CSN[id]
						local en = gs.Stance[sn]
						if en == false then
							tinsert(numd, id)
						elseif en == nil or en == true then
							tinsert(nume, id)
						end
					end
					if #nume ~= 0 then
						local start = #Conditions + 1
						if #nume <= ceil(#TMW.CSN/2) then

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
		[41206] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "STANCE" then
						condition.Operator = "=="
					end
				end
			end,
		},
		[41008] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "SPELLCD" or condition.Type == "ITEMCD" then
						if condition.Level == 0 then
							condition.Operator = "=="
						elseif condition.Level == 1 then
							condition.Operator = ">"
							condition.Level = 0
						end
					elseif condition.Type == "MAINHAND" or condition.Type == "OFFHAND" or condition.Type == "THROWN" then
						if condition.Level == 0 then
							condition.Operator = ">"
						elseif condition.Level == 1 then
							condition.Operator = "=="
							condition.Level = 0
						end
					end
				end
			end,
		},
		[41005] = {
			icon = function(ics)
				ics.ConditionAlpha = 0
			end,
		},
		[41004] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "BUFF" then
						condition.Type = "BUFFSTACKS"
					elseif condition.Type == "DEBUFF" then
						condition.Type = "DEBUFFSTACKS"
					end
				end
			end,
		},
		[40124] = {
			global = function()
				db.profile.Revision = nil-- unused
			end,
		},
		[40115] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "BUFF" or condition.Type == "DEBUFF" then
						if condition.Level == 0 then
							condition.Operator = ">"
						elseif condition.Level == 1 then
							condition.Operator = "=="
							condition.Level = 0
						end
					end
				end
			end,
		},
		[40112] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "CASTING" then
						condition.Level = condition.Level + 1
					end
				end
			end,
		},
		[40111] = {
			icon = function(ics)
				ics.Unit = TMW:CleanString((ics.Unit .. ";"):	-- it wont change things at the end of the unit string without a character after the unit at the end
				gsub("raid[^%d]", "raid1-25;"):
				gsub( "party[^%d]", "party1-4;"):
				gsub("arena[^%d]", "arena1-5;"):
				gsub("boss[^%d]", "boss1-4;"):
				gsub("maintank[^%d]", "maintank1-5;"):
				gsub("mainassist[^%d]", "mainassist1-5;"))
			end,
		},
		[40106] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "ITEMINBAGS" then
						if condition.Level == 0 then
							condition.Operator = ">"
						elseif condition.Level == 1 then
							condition.Operator = "=="
							condition.Level = 0
						end
					end
				end
			end,
		},
		[40100] = {
			global = function()
				db.profile["BarGCD"] = true
				db.profile["ClockGCD"] = true
			end,
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if condition.Type == "NAME" then
						condition.Level = 0
					end
				end
			end,
		},
		[40080] = {
			group = function(gs)
				if gs.Stance and (gs.Stance[L["NONE"]] == false or gs.Stance[L["CASTERFORM"]] == false) then
					gs.Stance[L["NONE"]] = nil
					gs.Stance[L["CASTERFORM"]] = nil
					gs.Stance[NONE] = false
				end
			end,
			icon = function(ics)
				ics.StackMin = floor(ics.StackMin)
				ics.StackMax = floor(ics.StackMax)
				for k, v in pairs(ics.Conditions) do
					if v.Type == "ECLIPSE_DIRECTION" and v.Level == -1 then
						v.Level = 0
					end
				end
			end,
		},
		[40060] = {
			global = function()
				db.profile.Texture = nil --now i get the texture from LSM the right way instead of saving the texture path
			end,
		},
		[40010] = {
			icon = function(ics)
				if ics.Type == "multistatecd" then
					ics.Type = "cooldown"
					ics.CooldownType = "multistate"
				end
			end,
		},
		[40000] = {
			global = function()
				db.profile.Spacing = nil
				db.profile.Locked = false
			end,
			group = function(gs)
				gs.Spacing = db.profile.Spacing or 0
			end,
			icon = function(ics)
				if ics.Type == "icd" then
					ics.CooldownShowWhen = ics.ICDShowWhen or "usable"
					ics.ICDShowWhen = nil
				end
			end,
		},
		[30000] = {
			global = function()
				db.profile.NumGroups = 10
				db.profile.Condensed = nil
				db.profile.NumCondits = nil
				db.profile.DSN = nil
				db.profile.UNUSEColor = nil
				db.profile.USEColor = nil
				if db.profile.Font and db.profile.Font.Outline == "THICK" then db.profile.Font.Outline = "THICKOUTLINE" end --oops
			end,
			group = function(gs)
				gs.LBFGroup = nil
				if gs.Stance then
					for k, v in pairs(gs.Stance) do
						if CSN[k] then
							if v then -- everything switched in this version
								gs.Stance[CSN[k]] = false
							else
								gs.Stance[CSN[k]] = true
							end
							gs.Stance[k] = nil
						end
					end
				end
			end,
			icon = function(ics, self, groupID, iconID)
				for k in pairs({
					OORColor = true,
					OOMColor = true,
					Color = true,
					ColorOverride = true,
					UnColor = true,
					DurationAndCD = true,
					Shapeshift = true, -- i used this one during some initial testing for shapeshifts
					UnitReact = true,
				}) do
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
			end,
		},
		[24100] = {
			icon = function(ics)
				if ics.Type == "meta" and type(ics.Icons) == "table" then
					--make values the data, not the keys, so that we can customize the order that they are checked in
					for k, v in pairs(ics.Icons) do
						tinsert(ics.Icons, k)
						ics.Icons[k] = nil
					end
				end
			end,
		},
		[24000] = {
			icon = function(ics)
				ics.Name = gsub(ics.Name, "StunnedOrIncapacitated", "Stunned;Incapacitated")
				ics.Name = gsub(ics.Name, "IncreasedSPboth", "IncreasedSPsix;IncreasedSPten")
				if ics.Type == "darksim" then
					ics.Type = "multistatecd"
					ics.Name = "77606"
				end
			end,
		},
		[23000] = {
			icon = function(ics)
				if ics.StackMin ~= TMW.Icon_Defaults.StackMin then
					ics.StackMinEnabled = true
				end
				if ics.StackMax ~= TMW.Icon_Defaults.StackMax then
					ics.StackMaxEnabled = true
				end
			end,
		},
		[22100] = {
			icon = function(ics)
				if ics.UnitReact and ics.UnitReact ~= 0 then
					local condition = ics.Conditions[#ics.Conditions + 1]
					condition.Type = "REACT"
					condition.Level = ics.UnitReact
					condition.Unit = "target"
				end
			end,
		},
		[22010] = {
			icon = function(ics)
				for i, condition in ipairs(ics.Conditions) do
					for k, v in pairs(condition) do
						condition[k] = nil
						condition[k:gsub("Condition", "")] = v
					end
				end
			end,
		},
		[22000] = {
			icon = function(ics)
				for k, v in ipairs(ics.Conditions) do
					if ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
						v.ConditionLevel = 0
					end
				end
			end,
		},
		[21200] = {
			icon = function(ics)
				if ics.WpnEnchantType == "thrown" then
					ics.WpnEnchantType = "RangedSlot"
				elseif ics.WpnEnchantType == "offhand" then
					ics.WpnEnchantType = "SecondaryHandSlot"
				elseif ics.WpnEnchantType == "mainhand" then --idk why this would happen, but you never know
					ics.WpnEnchantType = "MainHandSlot"
				end
			end,
		},
		[20100] = {
			icon = function(ics)
				for k, v in ipairs(ics.Conditions) do
					v.ConditionLevel = tonumber(v.ConditionLevel) or 0
					if ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
						v.ConditionLevel = ceil((v.ConditionLevel/100)*3)
					end
				end
			end,
		},
		[15400] = {
			icon = function(ics)
				if ics.Alpha == 0.01 then ics.Alpha = 1 end
			end,
		},
		[15300] = {
			icon = function(ics)
				if ics.Alpha > 1 then
					ics.Alpha = (ics.Alpha / 100)
				else
					ics.Alpha = 1
				end
			end,
		},
		[12000] = {
			global = function()
				db.profile.Spec = nil
			end,
		},

	}

	upgradeTable = {}
	for k, v in pairs(t) do
		v.Version = k
		tinsert(upgradeTable, v)
	end
	sort(upgradeTable, function(a, b)
		if a.priority or b.priority then
			if a.priority and b.priority then
				return a.priority < b.priority
			else
				return a.priority
			end
		end
		return a.Version < b.Version
	end)
	return upgradeTable
end

function TMW:GlobalUpgrade()
	TellMeWhenDB.Version = TellMeWhenDB.Version or 0
	if TellMeWhenDB.Version == 414069 then TellMeWhenDB.Version = 41409 end --well, that was a mighty fine fail
	-- Begin DB upgrades that need to be done before defaults are added. Upgrades here should always do everything needed to every single profile, and remember to make sure that a table exists before going into it.

	if TellMeWhenDB.profiles then
		if TellMeWhenDB.Version < 41402 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Groups then
					for _, g in pairs(p.Groups) do
						if g.Point then
							g.Point.point = g.Point.point or "TOPLEFT"
							g.Point.relativePoint = g.Point.relativePoint or "TOPLEFT"
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
		
		if TellMeWhenDB.Version < 45607 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Groups then
					for _, gs in pairs(p.Groups) do
						if gs.Icons then
							for _, ics in pairs(gs.Icons) do
								if ics.ShowTimerText == nil then
									ics.ShowTimerText = true
								end
							end
						end
					end
				end
			end
		end
	end
	TellMeWhenDB.Version = TELLMEWHEN_VERSIONNUMBER -- pre-default upgrades complete!
end

function TMW:Error(text, level, ...)
	text = text or ""
	text = format(text, ...)
	geterrorhandler()("TellMeWhen: " .. (text), level)
end

function TMW:Upgrade()
	if TellMeWhen_Settings then -- needs to be first
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
	
	TMW:DoUpgrade(db.profile.Version, true)

	--All Upgrades Complete
	db.profile.Version = TELLMEWHEN_VERSIONNUMBER
end

function TMW:DoUpgrade(version, global, groupID, iconID)
	for k, v in ipairs(TMW:GetUpgradeTable()) do
		if v.Version > version then
			if global and v.global then
				v.global(v)
			elseif groupID and not iconID and v.group then
				v.group(db.profile.Groups[groupID], v, groupID)
			elseif iconID and groupID and v.icon then
				v.icon(db.profile.Groups[groupID].Icons[iconID], v, groupID, iconID)
			end
			if global and v.postglobal then
				v.postglobal(v)
			end
		end
	end
	
	if global then
		for gs, groupID in TMW:InGroupSettings() do
			TMW:DoUpgrade(version, nil, groupID, nil)
		end
	elseif groupID and not iconID then
		for ics, groupID, iconID in TMW:InIconSettings(groupID) do
			TMW:DoUpgrade(version, nil, groupID, iconID)
		end
	end
end

function TMW:LoadOptions(recursed)
	if IsAddOnLoaded("TellMeWhen_Options") then
		return true
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
			TMW:Error(err, 0) -- non breaking error
		end
	else
		for k, v in pairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
			if v.name == "TellMeWhen" and not v.obj then
				tremove(INTERFACEOPTIONS_ADDONCATEGORIES, k)
				InterfaceAddOnsList_Update()
				break
			end
		end
		TMW:CompileOptions()
		collectgarbage()
	end
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
							if not TMW:IsIconValid(v.Icon) then
								local g, i = strmatch(v.Icon, "TellMeWhen_Group(%d+)_Icon(%d+)")
								g, i = tonumber(g), tonumber(i)
								TMW.Warn(format(L["CONDITIONORMETA_CHECKINGINVALID"], gID, iID, g, i))
							end
						end
					end
					if is.Type == "meta" then
						for k, v in pairs(is.Icons) do
							if not TMW:IsIconValid(v) then
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

function TMW:RestoreSound()
	runEvents = 1
end

function TMW:PLAYER_ENTERING_WORLD()
	if not TMW.VarsLoaded then return end
	TMW.EnteredWorld = true

	local NumRealRaidMembers = GetRealNumRaidMembers()
	local NumRealPartyMembers = GetRealNumPartyMembers()
	local NumRaidMembers = GetNumRaidMembers()

	if (NumRealRaidMembers > 0) and (NumRealRaidMembers ~= (TMW.OldNumRealRaidMembers or 0)) then
		TMW.OldNumRealRaidMembers = NumRealRaidMembers
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "RAID")

	elseif (NumRealRaidMembers == 0) and (NumRealPartyMembers > 0) and (NumRealPartyMembers ~= (TMW.OldNumRealPartyMembers or 0)) then
		TMW.OldNumRealPartyMembers = NumRealPartyMembers
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "PARTY")

	elseif UnitInBattleground("player") and (NumRaidMembers ~= (TMW.OldNumRaidMembers or 0)) then
		TMW.OldNumRaidMembers = NumRaidMembers
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "BATTLEGROUND")
	end
end

local mtTranslations, maTranslations = {}, {}
function TMW:RAID_ROSTER_UPDATE()
	wipe(mtTranslations)
	wipe(maTranslations)
	local mtN = 1
	local maN = 1
	-- setup a table with (key, value) pairs as (oldnumber, newnumber)
	-- oldnumber is 7 for raid7
	-- newnumber is 1 for raid7 when the current maintank/assist is the 1st one found, 2 for the 2nd one found, etc)
	for i = 1, GetNumRaidMembers() do
		local raidunit = "raid" .. i
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
			else -- it isnt a special unit, so put it back in as normal
				Units[#Units+1] = oldunit
			end
		end
	end
	for oldunit in pairs(CNDTEnv) do
		if strfind(oldunit, "maintank") then
			local newunit = gsub(oldunit, "maintank", "raid")
			local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
			local newnumber = oldnumber and mtTranslations[oldnumber]
			if newnumber then
				CNDTEnv[oldunit] = gsub(newunit, oldnumber, newnumber)
			else
				CNDTEnv[oldunit] = oldunit
			end
		elseif strfind(oldunit, "mainassist") then
			local newunit = gsub(oldunit, "mainassist", "raid")
			local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
			local newnumber = oldnumber and maTranslations[oldnumber]
			if newnumber then
				CNDTEnv[oldunit] = gsub(u, oldnumber, newnumber)
			else
				CNDTEnv[oldunit] = oldunit
			end
		end
	end
end

function TMW:COMBAT_LOG_EVENT_UNFILTERED(_, _, p, ...)
	-- This is only used for the suggester, but i want to to be listening all the times for auras, not just when you load the options
	if p == "SPELL_AURA_APPLIED" then
		local g, i, f, _
		if clientVersion >= 40200 then
			_, g, _, f, _, _, _, _, _, i = ...
		elseif clientVersion >= 40100 then
			_, g, _, f, _, _, _, i = ...
		else
			g, _, f, _, _, _, i = ...
		end
		if not TMW.AuraCache[i] then
			if bitband(f, CL_PLAYER) == CL_PLAYER or bitband(f, CL_PET) == CL_PET then -- player or pet
				TMW.AuraCache[i] = 2
			else
				TMW.AuraCache[i] = 1
			end
		end
	end
end

function TMW:SPELL_UPDATE_USABLE()
	updatePBar = 1
end

function TMW:PLAYER_TALENT_UPDATE()
	if not TMW.AddedTalentsToTextures then
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				local name, tex = GetTalentInfo(tab, talent)
				local lower = name and strlowerCache[name]
				if lower then
					SpellTextures[lower] = tex
				end
			end
		end
		TMW.AddedTalentsToTextures = 1
	end
	TMW:ScheduleUpdate(1)
end

function TMW:ACTIVE_TALENT_GROUP_CHANGED()
	TMW:ScheduleUpdate(1)
end

function TMW:ValidateIcon(icon)
	-- adds the icon to the list of icons that can be checked in metas/conditions
	if type(icon) == "string" then icon = _G[icon] end
	if not TMW.IconsLookup[icon] then
		tinsert(TMW.Icons, icon:GetName())
		TMW.IconsLookup[icon] = 1
	end
end
function TMW:InvalidateIcon(icon)
	-- removes the icon from the list of icons that can be checked in metas/conditions
	if type(icon) == "string" then icon = _G[icon] end
	if TMW.IconsLookup[icon] then
		local k = tContains(TMW.Icons, icon:GetName())
		if k then tremove(TMW.Icons, k) end
		TMW.IconsLookup[icon] = nil
	end
end
function TMW:IsIconValid(icon)
	-- checks if the icon is in the list of icons that can be checked in metas/conditions
	if type(icon) == "string" then icon = _G[icon] end
	return TMW.IconsLookup[icon]
end

-- -----------
-- GROUPS
-- -----------

function GroupScriptSort(groupA, groupB)
	local gOrder = -db.profile.CheckOrder
	return groupA:GetID()*gOrder < groupB:GetID()*gOrder
end

function GroupBase.SetScript(group, handler, func)
	group[handler] = func
	if handler ~= "OnUpdate" then
		group:setscript(handler, func)
	else
		tDeleteItem(GroupUpdateFuncs, group)
		if func then
			GroupUpdateFuncs[#GroupUpdateFuncs+1] = group
			sort(GroupUpdateFuncs, GroupScriptSort)
		end
	end
end

function GroupBase.Show(group)
	if not group.__shown then
		group:show()
		group.__shown = 1
	end
end

function GroupBase.Hide(group)
	if group.__shown then
		group:hide()
		group.__shown = nil
	end
end

function GroupBase.SetPos(group)
	local groupID = group:GetID()
	local s = db.profile.Groups[groupID]
	local p = s.Point
	group:ClearAllPoints()
	if p.relativeTo == "" then
		p.relativeTo = "UIParent"
	end
	p.relativeTo = type(p.relativeTo) == "table" and p.relativeTo:GetName() or p.relativeTo
	local relativeTo = _G[p.relativeTo]
	if not relativeTo then
		FramesToFind = FramesToFind or {}
		FramesToFind[group] = p.relativeTo
		group:SetPoint("CENTER", UIParent)
	else
		group:SetPoint(p.point, relativeTo, p.relativePoint, p.x, p.y)
	end
	group:SetScale(s.Scale)
	local Spacing = s.Spacing
	group:SetSize(s.Columns*(30+Spacing)-Spacing, s.Rows*(30+Spacing)-Spacing)
	group:SetFrameStrata(s.Strata)
	group:SetFrameLevel(s.Level)
end

function TMW:GetShapeshiftForm()
	-- very hackey function because of inconsistencies in blizzard's GetShapeshiftForm
	local i = GetShapeshiftForm()
	if pclass == "WARLOCK" and i == 2 then  --metamorphosis is index 2 for some reason
		i = 1
	elseif pclass == "ROGUE" and i >= 2 then	--vanish and shadow dance return 3 when active, vanish returns 2 when shadow dance isnt learned. Just treat everything as stealth
		i = 1
	end
	if i > NumShapeshiftForms then 	--many classes return an invalid number on login, but not anymore!
		i = 0
	end
	return i or 0
end local GetShapeshiftForm = TMW.GetShapeshiftForm

local function CreateGroup(groupID)
	local group = CreateFrame("Frame", "TellMeWhen_Group" .. groupID, TMW, "TellMeWhen_GroupTemplate", groupID)
	TMW[groupID] = group
	CNDTEnv[group:GetName()] = group
	group.base = GroupBase

	for k, v in pairs(GroupBase) do
		if type(group[k]) == "function" then -- if the method already exists on the icon
			group[strlower(k)] = group[k] -- store the old method as the lowercase same name
		end
		group[k] = v
	end
	return group
end

function TMW:Group_Update(groupID)
	local group = TMW[groupID] or CreateGroup(groupID)
	group.CorrectStance = true
	group.__shown = group:IsShown()

	for k, v in pairs(TMW.Group_Defaults) do
		group[k] = db.profile.Groups[groupID][k]
	end

	group.CorrectSpec = true
	if (GetActiveTalentGroup()==1 and not group.PrimarySpec) or (GetActiveTalentGroup()==2 and not group.SecondarySpec) or (GetPrimaryTalentTree() and not group["Tree" .. GetPrimaryTalentTree()]) then
		group.CorrectSpec = false
	end

	if LMB then
		db.profile.Groups[groupID].LBF = nil -- if people get masque then they dont need these settings anymore. If they want to downgrade then they will just have to set things up again, sorry
	elseif LBF then
		local lbfs = db.profile.Groups[groupID]["LBF"]
		LBF:Group("TellMeWhen", format(L["fGROUP"], groupID))
		if lbfs.SkinID then
			LBF:Group("TellMeWhen", format(L["fGROUP"], groupID)):Skin(lbfs.SkinID, lbfs.Gloss, lbfs.Backdrop, lbfs.Colors)
		end
	end
	group.FontTest = (not Locked) and group.FontTest

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
				local success, err = pcall(TMW.Icon_Update, TMW, icon)
				if not success then
					TMW:Error(L["GROUPICON"]:format(groupID, iconID) .. ": " .. err)
				end
			end
		end
		for iconID = (group.Rows*group.Columns)+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
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

	group:SetPos()

	if group.Enabled and group.CorrectSpec and Locked then
		group:Show()
		if #group.Conditions > 0 or group.OnlyInCombat then
			group:SetScript("OnUpdate", CNDT:ProcessConditions(group)) -- dont be alarmed, this is handled by GroupSetScript
		else
			group:SetScript("OnUpdate", nil)
		end
	else
		group:SetScript("OnUpdate", nil)
		if group.Enabled and group.CorrectSpec then
			group:Show()
		else
			group:Hide()
		end
	end
end


-- ------------------
-- ICONS
-- ------------------

local function LMBSkinHook(self)
	if self and self.Addon == "TellMeWhen" then
		TMW:ScheduleUpdate(.2)
	end
end local hookedLMBSkin

local function OnGCD(d)
	if d == 1 then return true end -- a cd of 1 is always a GCD (or at least isn't worth showing)
	if GCD > 1.7 then return false end -- weed out a cooldown on the GCD spell that might be an interupt (counterspell, mind freeze, etc)
	return GCD == d and d > 0 -- if the duration passed in is the same as the GCD spell, and the duration isnt zero, then it is a GCD
end	TMW.OnGCD = OnGCD

local function IconScriptSort(iconA, iconB)
	local gOrder = -db.profile.CheckOrder
	local gA = iconA.group:GetID()
	local gB = iconB.group:GetID()
	if gA == gB then
		local iOrder = -db.profile.Groups[gA].CheckOrder
		return iconA:GetID()*iOrder < iconB:GetID()*iOrder
	end
	return gA*gOrder < gB*gOrder
end

local function CDBarOnUpdate(bar)
	local duration = bar.duration
	if bar.InvertBars then
		if duration == 0 then
			bar:SetValue(bar.Max)
		else
			bar:SetMinMaxValues(0, duration)
			bar.Max = duration
			bar:SetValue(time - bar.start + bar.offset)
		end
	else
		if duration == 0 then
			bar:SetValue(0)
		else
			bar:SetMinMaxValues(0,  duration)
			bar.Max = duration
			bar:SetValue(duration - (time - bar.start) + bar.offset)
		end
	end
end

local function CDBarOnValueChanged(bar)
	local start = bar.start
	local duration = bar.duration
	local pct
	if not bar.InvertBars then
		if duration ~= 0 then
			pct = (time - start) / duration
			local inv = 1-pct
			bar:SetStatusBarColor(
				(co.r * pct) + (st.r * inv),
				(co.g * pct) + (st.g * inv),
				(co.b * pct) + (st.b * inv),
				(co.a * pct) + (st.a * inv)
			)
		end
	else
		--inverted
		if duration == 0 then
			bar:SetStatusBarColor(co.r, co.g, co.b, co.a)
		else
			pct = (time - start) / duration
			local inv = 1-pct
			bar:SetStatusBarColor(
				(co.r * pct) + (st.r * inv),
				(co.g * pct) + (st.g * inv),
				(co.b * pct) + (st.b * inv),
				(co.a * pct) + (st.a * inv)
			)
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

function IconBase.SetAlpha(icon, alpha)
	if alpha ~= icon.__alpha then
		if alpha == 0 then
			local data = icon.OnHide
			if data then
				icon:HandleEvent(data)
			end
		elseif icon.__alpha == 0 then
			local data = icon.OnShow
			if data then
				icon:HandleEvent(data)
			end
		elseif alpha > icon.__alpha then
			local data = icon.OnAlphaInc
			if data then
				icon:HandleEvent(data)
			end
		else -- it must be less than, because it isnt greater than and it isnt the same --if alpha < icon.__alpha then
			local data = icon.OnAlphaDec
			if data then
				icon:HandleEvent(data)
			end
		end
		icon:setalpha(icon.FakeHidden or alpha) -- setalpha(lowercase) is the old, raw SetAlpha.
		icon.__alpha = alpha
	end
end

function IconBase.SetScript(icon, handler, func, dontnil)
	if func ~= nil or not dontnil then
		icon[handler] = func
	end
	if handler ~= "OnUpdate" then
		icon:setscript(handler, func)
	else
		tDeleteItem(IconUpdateFuncs, icon)
		if func then
			IconUpdateFuncs[#IconUpdateFuncs+1] = icon
		end
		sort(IconUpdateFuncs, IconScriptSort)
	end
end

function IconBase.SetTexture(icon, tex)
	--if icon.__tex ~= tex then ------dont check for this, checking is done before this method is even called
	tex = icon.OverrideTex or tex
	icon.__tex = tex
	icon.texture:SetTexture(tex)
end

function IconBase.SetReverse(icon, reverse)
	icon.__reverse = reverse
	icon.cooldown:SetReverse(reverse)
end

function IconBase.UpdateBindText(icon)
	icon.bindText:SetText(TMW:InjectDataIntoString(icon.BindText, icon))
end

function IconBase.IsBeingEdited(icon)
	if TMW.IE and TMW.CI.ic == icon and TMW.IE.CurrentTab and TellMeWhen_IconEditor:IsVisible() then
		return TMW.IE.CurrentTab:GetID()
	end
end

function IconBase.RegisterEvent(icon, event)
	icon:registerevent(event)
	icon.__hasEvents = 1
end

function IconBase.HandleEvent(icon, data, played, announced)
	if not runEvents then return end
	local Sound = data.SoundData
	if Sound and not played then
		PlaySoundFile(Sound, SndChan)
		played = 1
	end
	local Channel = data.Channel
	if Channel ~= "" and not announced then
		local Text = data.Text
		local chandata = ChannelLookup[Channel]
		
		Text = TMW:InjectDataIntoString(Text, icon, not (chandata and chandata.isBlizz))
		
		if Channel == "MSBT" then
			if MikSBT then
				local Size = data.Size
				if Size == 0 then Size = nil end
				MikSBT.DisplayMessage(Text, data.Location, data.Sticky, data.r*255, data.g*255, data.b*255, Size, nil, data.Icon and icon.__tex)
			end
		elseif Channel == "SCT" then
			if SCT then
				sctcolor.r, sctcolor.g, sctcolor.b = data.r, data.g, data.b
				SCT:DisplayCustomEvent(Text, sctcolor, data.Sticky, data.Location, nil, data.Icon and icon.__tex)
			end
		elseif Channel == "PARROT" then
			if Parrot then
				local Size = data.Size
				if Size == 0 then Size = nil end
				Parrot:ShowMessage(Text, data.Location, data.Sticky, data.r, data.g, data.b, nil, Size, nil, data.Icon and icon.__tex)
			end
		elseif Channel == "FRAME" then
			local i = 1
			while _G["ChatFrame"..i] do
				local frame = _G["ChatFrame"..i]
				local Location = data.Location
				if Location == frame.name then
					if data.Icon then
						Text = "|T" .. (icon.__tex or "") .. ":0|t " .. Text
					end
					frame:AddMessage(Text, data.r, data.g, data.b, 1)
					break
				end
				i = i+1
			end
		elseif Channel == "SMART" then
			local channel = "SAY"
			if UnitInBattleground("player") then
				channel = "BATTLEGROUND"
			elseif UnitInRaid("player") then
				channel = "RAID"
			elseif GetNumPartyMembers() > 1 then
				channel = "PARTY"
			end
			SendChatMessage(Text, channel)
			
		elseif Channel == "CHANNEL" then
			for i = 1, math.huge, 2 do
				local num, name = select(i, GetChannelList())
				if not num then break end
				if strlowerCache[name] == strlowerCache[data.Location] then
					SendChatMessage(Text, Channel, nil, num)
					break
				end
			end
			
		else
			if Text and chandata and chandata.isBlizz then
				SendChatMessage(Text, Channel, nil, data.Location)
			end
		end
		announced = 1
	end
	return played, announced
end

function IconBase.SetInfo(icon, alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	-- icon				- the icon object to set the attributes on (frame) (but call as icon:SetInfo(alpha, ...) , nil, nil)
	-- [alpha]			- the alpha to set the icon to (number); (nil) defaults to 0
	-- [color]			- the value(s) to call SetVertexColor with. Either a (number) that will be used as the r, g, and b; or a (table) with keys r, g, b; or (nil) to leave unchanged
	-- [texture]		- the texture path to set the icon to (string); or (nil) to leave unchanged
	-- [start]			- the start time of the cooldow/duration, as passsed to icon.cooldown:SetCooldown(start, duration); (nil) defaults to 0
	-- [duration]		- the duration of the cooldow/duration, as passsed to icon.cooldown:SetCooldown(start, duration); (nil) defaults to 0
	-- [spellChecked]	- the name or ID of the spell to be used for the icons power bar overlay (string/number)
	-- [reverse]		- true/false to set icon.cooldown:SetReverse(reverse), nil to not change (boolean/nil)
	-- [count]			- the number of stacks to be used for comparison, nil/false to hide (number/nil/false)
	-- [countText]		- the actual stack TEXT to be set on the icon, will use count if nil (number/string/nil/false)
	-- [forceupdate]	- for meta icons, will force an update on things even if args didnt change.
	-- [unit]			- the unit that the icon stopped checking on
	
	--[[
		TO ADD AN ARG: (Notepad++)
		1) Ctrl+F
		2) Find regex		([^\-]+icon:SetInfo\(.*)\)
		3) Replace with		\1, nil)
		4) Find normal		alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit
		5) Replace with		alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit, NEWARG
			where newarg is the newarg
		6) IMPORTANT: Update the meta icon with the new arg
		6) Handle arg in here
	]]
		
	local played, announced

	alpha = alpha or 0
	duration = duration or 0
	start = start or 0
	
	local queueOnUnit, queueOnSpell
	
	unit = unit or (icon.Units and icon.Units[1] or "player")
	if icon.__unitChecked ~= unit then
		queueOnUnit = true
		icon.__unitChecked = unit
		if unit then
			icon.__oldUnitName = UnitName(unit)
		end
	elseif unit then
		local unitName = UnitName(unit)
		if icon.__oldUnitName ~= unitName then
			queueOnUnit = true
			icon.__oldUnitName = unitName
		end
	end
	
	if icon.__spellChecked ~= spellChecked then
		queueOnSpell = true
		icon.__spellChecked = spellChecked
	end
	
	if (queueOnSpell or queueOnUnit) and icon.doUpdateBindText then
		icon:UpdateBindText()
	end
	
	if duration == 0.001 then duration = 0 end -- hardcode fix for tricks of the trade. nice hardcoding, blizzard
	local d = duration - (time - start)

	if
		(icon.CndtFailed) or -- conditions failed
		(d > 0 and ((icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax))) or -- duration requirements failed
		(count and ((icon.StackMinEnabled and icon.StackMin > count) or (icon.StackMaxEnabled and count > icon.StackMax))) -- stack requirements failed
	then
		alpha = alpha ~= 0 and icon.ConditionAlpha or 0 -- use the alpha setting for failed stacks/duration/conditions, but only if the alpha isnt being hidden for another reason
	end
	
	texture = icon.OverrideTex or texture -- if a texture override is specefied, then use it instead
	if texture ~= nil and icon.__tex ~= texture then -- do this before events are processed because some text outputs use icon.__tex
		icon.__tex = texture
		icon.texture:SetTexture(texture)
	end

	if alpha ~= icon.__alpha then
		-- detect events that occured, and handle them if they did
		if alpha == 0 then
			local data = icon.OnHide
			if data then
				played, announced = icon:HandleEvent(data)
			end
		elseif icon.__alpha == 0 then
			local data = icon.OnShow
			if data then
				played, announced = icon:HandleEvent(data)
			end
		elseif alpha > icon.__alpha then
			local data = icon.OnAlphaInc
			if data then
				played, announced = icon:HandleEvent(data)
			end
		else -- it must be less than, because it isnt greater than and it isnt the same
			local data = icon.OnAlphaDec
			if data then
				played, announced = icon:HandleEvent(data)
			end
		end
		
		icon:setalpha(icon.FakeHidden or alpha) -- setalpha(lowercase) is the old, raw SetAlpha.
		icon.__alpha = alpha
	end

	if icon.__start ~= start or icon.__duration ~= duration or forceupdate then
		local isGCD
		if duration == 1 then
			isGCD = true
		elseif GCD > 1.7 then
			isGCD = false
		else
			isGCD = (GCD == duration and duration > 0)
		end

		local realDuration = isGCD and 0 or duration -- the duration of the cooldown, ignoring the GCD
		if icon.__realDuration ~= realDuration then
			-- detect events that occured, and handle them if they did
			if realDuration == 0 then
				local data = icon.OnFinish
				if data then
					played, announced = icon:HandleEvent(data, played, announced)
				end
			else
				local data = icon.OnStart
				if data then
					played, announced = icon:HandleEvent(data, played, announced)
				end
			end
			icon.__realDuration = realDuration
		end

		if icon.ShowTimer or icon.ShowTimerText then
			local cd = icon.cooldown
			if duration > 0 then
				local s, d = start, duration

				if isGCD and ClockGCD then
					s, d = 0, 0
				end

				-- cd.s is only used in this function and is used to prevent finish effect spam (and to increase efficiency) while GCDs are being triggered. icon.__start isnt used because that just records the start time passed in, which may be a GCD, so it will change frequently
				if cd.s ~= s or forceupdate then
					cd:SetCooldown(s, d)
					cd:Show()
					if not icon.ShowTimer then
						cd:SetAlpha(0)
					end
					if reverse ~= nil and icon.__reverse ~= reverse then -- must be ( ~= nil )
						icon.__reverse = reverse
						cd:SetReverse(reverse)
					end
					cd.s = s
				end
			else
				cd.s = 0
				cd:Hide()
			end
		else
			icon.cooldown:Hide()
		end

		if icon.ShowCBar then
			local bar = icon.cbar
			bar.duration = duration
			bar.start = start
			bar.InvertBars = icon.InvertBars
			if duration > 0 then
				if isGCD and BarGCD then
					bar.duration = 0
				end

				if not bar.UpdateSet then
					bar:SetScript("OnUpdate", CDBarOnUpdate)
					bar.UpdateSet = true
				end
			else
				if bar.UpdateSet then
					bar:SetScript("OnUpdate", nil)
					bar.UpdateSet = false
				end
				if bar.InvertBars then
					bar:SetValue(bar.Max)
				else
					bar:SetValue(0)
				end
			end
		end

		icon.__start = start
		icon.__duration = duration
	end

	local data = queueOnSpell and icon.OnSpell
	if data then
		played, announced = icon:HandleEvent(data, played, announced)
	end
	
	local data = queueOnUnit and icon.OnUnit
	if data then
		played, announced = icon:HandleEvent(data, played, announced)
	end
	
	
	-- NO EVENT HANDLING PAST THIS POINT!
	if alpha == 0 then
		return
	end

	if icon.__vrtxcolor ~= color and color then
		if type(color) == "table" then
			icon.texture:SetVertexColor(color.r, color.g, color.b, 1)
		else
			icon.texture:SetVertexColor(color, color, color, 1)
		end
		icon.__vrtxcolor = color
	end

	if icon.ShowPBar and (updatePBar or queueOnSpell or forceupdate) then
		if spellChecked then
			local _, _, _, cost, _, powerType = GetSpellInfo(spellChecked)
			if cost then
				local pbar = icon.pbar
				cost = powerType == 9 and 3 or cost
				pbar.Max = cost
				pbar.InvertBars = icon.InvertBars

				if powerType ~= pbar.powerType then
					local colorinfo = PowerBarColor[powerType]
					pbar:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
					pbar.powerType = powerType
				end

				pbar:SetMinMaxValues(0, cost)
				if not pbar.UpdateSet then
					pbar:SetScript("OnUpdate", PwrBarOnUpdate)
					PwrBarOnUpdate(pbar)
					pbar.UpdateSet = true
				end
				pbar:SetMinMaxValues(0, cost)
			end
		elseif icon.pbar.UpdateSet then
			local pbar = icon.pbar
			pbar:SetScript("OnUpdate", nil)
			pbar.UpdateSet = false
			pbar:SetValue(icon.InvertBars and pbar.Max or 0)
		end
	end

	if icon.__count ~= count or icon.__countText ~= countText then
		if count then
			icon.countText:SetText(countText or count)
		else
			icon.countText:SetText(nil)
		end
		icon.__count = count
		icon.__countText = countText
	end

end

local iconMT = {
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
		return icon:GetName() or tostring(icon)
	end,
	__index = getmetatable(CreateFrame("Button")).__index,
}


local TypeBase = {}
local typeMT = {
	__index = TypeBase,
}

TypeBase.DisabledEvents = {}
function TypeBase:GetNameForDisplay(icon, data)
	local name = data and GetSpellInfo(data) or data
	return name, true
end

function TMW:RegisterIconType(Type)
	local typekey = Type.type
	setmetatable(Type, typeMT)
	for setting, b in pairs(RelevantToAll) do
		-- merge settings that are relevant to all (or most) icon types into the RelevantSettings table.
		-- values that are explicitly set false have been disabled for the icon type, so only set something on the table if the current value is nil.
		if Type.RelevantSettings[setting] == nil then -- must be == nil
			Type.RelevantSettings[setting] = b
		end
	end
	
	if TMW.debug and rawget(Types, typekey) then
		-- for tweaking and recreating icon types inside of WowLua so that I don't have to change the typekey every time.
		typekey = typekey .. " - " .. date("%X")
		Type.name = typekey
	end
	
	Types[typekey] = Type -- put it in the main Types table
	tinsert(TMW.OrderedTypes, Type) -- put it in the ordered types table (used to order the type selection dropdown in the icon editor)
	return Type -- why not?
end

function TMW:CreateIcon(group, groupID, iconID)
	local icon = CreateFrame("Button", "TellMeWhen_Group" .. groupID .. "_Icon" .. iconID, group, "TellMeWhen_IconTemplate", iconID)
	icon.group = group
	group[iconID] = icon
	CNDTEnv[icon:GetName()] = icon
	icon.base = IconBase
	
	setmetatable(icon, iconMT)
	for k, v in pairs(IconBase) do
		if type(icon[k]) == "function" then -- if the method already exists on the icon
			icon[strlower(k)] = icon[k] -- store the old method as the lowercase same name
		end
		icon[k] = v
	end
	return icon
end

function TMW.IconsSort(a, b)
	local icon1, icon2 = _G[a], _G[b]
	local g1 = icon1.group:GetID()
	local g2 = icon2.group:GetID()
	if g1 ~= g2 then
		return g1 < g2
	else
		return icon1:GetID() < icon2:GetID()
	end
end

function TMW:Icon_UpdateBars(icon)
	local blizzEdgeInsets = icon.group.barInsets or 0
	local pbar = icon.pbar
	local cbar = icon.cbar
	if icon.ShowPBar and icon.NameFirst then
		TMW:RegisterEvent("SPELL_UPDATE_USABLE")
		pbar:SetPoint("BOTTOM", icon.texture, "CENTER", 0, 0.5)
		pbar:SetPoint("TOPLEFT", icon.texture, "TOPLEFT", blizzEdgeInsets, -blizzEdgeInsets)
		pbar:SetPoint("TOPRIGHT", icon.texture, "TOPRIGHT", -blizzEdgeInsets, -blizzEdgeInsets)
		
		local _, _, _, cost, _, powerType = GetSpellInfo(icon.NameFirst)
		cost = cost or 0
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
	else
		pbar:Hide()
	end
	if icon.ShowCBar then
		cbar.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
		cbar:SetPoint("TOP", icon.texture, "CENTER", 0, -0.5)
		cbar:SetPoint("BOTTOMLEFT", icon.texture, "BOTTOMLEFT", blizzEdgeInsets, blizzEdgeInsets)
		cbar:SetPoint("BOTTOMRIGHT", icon.texture, "BOTTOMRIGHT", -blizzEdgeInsets, blizzEdgeInsets)
		cbar:SetMinMaxValues(0, 1)
		cbar.Max = 1
		cbar:Show()
		cbar.offset = icon.CBarOffs or 0
		cbar.start = cbar.start or 0
		cbar.duration = cbar.duration or 0
		icon.CBarOffs = nil --reduce table clutter, we dont need this anymore
		cbar.InvertBars = icon.InvertBars
		cbar:SetScript("OnValueChanged", CDBarOnValueChanged)
	else
		cbar:Hide()
	end
end

function TMW:Icon_Update(icon)
	if not icon then return end
	
	if TMW.IE and not TMW.IE.Help.current.noclose then
		TMW.IE.Help:Hide()
	end

	local iconID = icon:GetID()
	local groupID = icon.group:GetID()
	local group = icon.group
	local ics = db.profile.Groups[groupID].Icons[iconID]
	local typeData = Types[ics.Type]
	icon.typeData = typeData

	local dontreassign
	if not runEvents then
		dontreassign = true
	else
		runEvents = nil
	end

	icon.__previousNameFirst = icon.NameFirst -- used to detect changes in the name that would cause a texture change
	icon.__spellChecked = nil
	icon.__unitChecked = nil
	icon.__oldUnitName = nil
	icon.Units = nil
	
	for k in pairs(TMW.Icon_Defaults) do
		icon[k] = nil --lets clear any settings that might get left behind.
	end

	for k, v in pairs(typeData.RelevantSettings) do
		icon[k] = v and ics[k]
	end

	local dontremove
	for event, tbl in pairs(icon.Events) do
		for key, data in pairs(tbl) do
			if key == "Sound" then
				if data == "" or data == "Interface\\Quiet.ogg" or data == "None" then
					tbl.SoundData = nil
				elseif strfind(data, "%.[^\\]+$") then
					tbl.SoundData = data
					dontremove = 1
				else
					local s = LSM:Fetch("sound", data)
					if s and s ~= "Interface\\Quiet.ogg" and s ~= "" then
						tbl.SoundData = s
						dontremove = 1
					else
						tbl.SoundData = nil
					end
				end
			elseif key == "Channel" and data ~= "" then
				dontremove = 1
			end
		end
		if tbl.SoundData or tbl.Channel ~= "" and not typeData.DisabledEvents[event] then
			icon[event] = tbl
		else
			icon[event] = nil
		end
	end

	icon.UpdateTimer 	= 0
	icon.FakeHidden = icon.FakeHidden and 0
	if pclass ~= "DEATHKNIGHT" then
		icon.IgnoreRunes = nil
	end
	icon.OverrideTex = TMW:GetCustomTexture(icon)

	if icon.__hasEvents then
		-- UnregisterAllEvents uses a ton of CPU
		icon:UnregisterAllEvents()
		icon.__hasEvents = nil
	end
	ClearScripts(icon)

	if #icon.Conditions > 0 and Locked then -- dont define conditions if we are unlocked so that i dont have to deal with meta icons checking icons during config. I think i solved this somewhere else too without thinking about it, but what the hell
		CNDT:ProcessConditions(icon)
	else
		icon.CndtCheck = nil
	end

	if icon.Enabled and group.Enabled then
		TMW:ValidateIcon(icon)
	else
		TMW:InvalidateIcon(icon)
	end

	local cd = icon.cooldown
	cd.noCooldownCount = not icon.ShowTimerText
	cd:SetDrawEdge(db.profile.DrawEdge)
	icon:SetReverse(false)

	
	local ctf = group.Fonts.Count
	local countText = icon.countText
	local btf = group.Fonts.Bind
	local bindText = icon.bindText
	local isDefault
	countText:SetFont(LSM:Fetch("font", ctf.Name), ctf.Size, ctf.Outline)
	bindText:SetFont(LSM:Fetch("font", btf.Name), btf.Size, btf.Outline)
	icon:UpdateBindText()
	icon.__normaltex = icon.__LBF_Normal or icon.__MSQ_NormalTexture or icon:GetNormalTexture()
	if LMB then
		local g = LMB:Group("TellMeWhen", format(L["fGROUP"], groupID))
		if not hookedLMBSkin and g.Skin and g.Disable and g.Enable then
			hooksecurefunc(g, "Skin", LMBSkinHook)
			hooksecurefunc(g, "Disable", LMBSkinHook)
			hooksecurefunc(g, "Enable", LMBSkinHook)
			hookedLMBSkin = 1
		end
		g:AddButton(icon)
		group.SkinID = g.SkinID or (g.db and g.db.SkinID)
		if g.Disabled or (g.db and g.db.Disabled) then
			group.SkinID = "Blizzard"
			if not icon.__normaltex:GetTexture() then
				isDefault = 1
			end
		end
	elseif LBF then
		local lbfs = db.profile.Groups[groupID].LBF
		local g = LBF:Group("TellMeWhen", format(L["fGROUP"], groupID))
		g:AddButton(icon)

		group.SkinID = lbfs.SkinID or g.SkinID or (g.db and g.db.SkinID) or "Blizzard" -- i dont think LBF ever had (g.db and g.db.SkinID), but whatever
		if group.SkinID == "Blizzard" then
			icon.__normaltex:Hide()
			isDefault = 1
		end
		local tbl = LBF:GetSkins()
		if tbl and tbl[group.SkinID] then
			countText:SetFont(LSM:Fetch("font", ctf.Name), tbl and tbl[group.SkinID].Count.FontSize or ctf.Size, ctf.Outline)
			bindText:SetFont(LSM:Fetch("font", btf.Name), tbl and tbl[group.SkinID].Count.FontSize or btf.Size, btf.Outline)
		end
	else
		countText:ClearAllPoints()
		countText:SetPoint(ctf.point, icon, ctf.relativePoint, ctf.x, ctf.y)
		bindText:ClearAllPoints()
		bindText:SetPoint(btf.point, icon, btf.relativePoint, btf.x, btf.y)
		isDefault = 1
	end
	
	icon.cbar:SetFrameLevel(icon:GetFrameLevel() + 1)
	icon.pbar:SetFrameLevel(icon:GetFrameLevel() + 1)
	
	if LMB or LBF then
		if ctf.OverrideLBFPos then
			countText:ClearAllPoints()
			local func = countText.__MSQ_SetPoint or countText.SetPoint
			func(countText, ctf.point, icon, ctf.relativePoint, ctf.x, ctf.y)
		end
		if btf.OverrideLBFPos then
			bindText:ClearAllPoints()
			local func = bindText.__MSQ_SetPoint or bindText.SetPoint
			func(bindText, btf.point, icon, btf.relativePoint, btf.x, btf.y)
		end
		icon.cbar:SetFrameLevel(icon:GetFrameLevel())
		icon.pbar:SetFrameLevel(icon:GetFrameLevel())
	end
	countText:SetWidth(ctf.ConstrainWidth and icon.texture:GetWidth() or 0)
	bindText:SetWidth(btf.ConstrainWidth and icon.texture:GetWidth() or 0)

	if isDefault then
		group.barInsets = 1.5
		cd:SetFrameLevel(icon:GetFrameLevel() + 1)
		icon.cbar:SetFrameLevel(icon:GetFrameLevel() + 2)
		icon.pbar:SetFrameLevel(icon:GetFrameLevel() + 2)
	else
		group.barInsets = 0
	end
	
	icon.__previcon = nil
	icon.__alpha = -1
	icon.__count = nil
	icon.__countText = nil
	icon.countText:SetText(nil)
	icon.__tex = icon.texture:GetTexture()
	icon.__realDuration = icon.__realDuration or 0
	icon.CndtFailed = nil
	icon.ConditionAlpha = icon.ConditionAlpha or 0
	
	icon.doUpdateBindText = icon.BindText and strfind(icon.BindText, "%%[SsUu]")
	
	if icon.ShowWhen == "alpha" then
		icon.UnAlpha = 0
	elseif icon.ShowWhen == "unalpha" then
		icon.Alpha = 0
	end
	
	TMW.time = GetTime()
	if icon.Enabled or not Locked then
		Types[icon.Type]:Update()
		local success, err = pcall(Types[icon.Type].Setup, Types[icon.Type], icon, groupID, iconID)
		if not success then
			TMW:Error(L["GROUPICON"]:format(groupID, iconID) .. ": " .. err)
		end
	else
		icon:SetAlpha(0)
	end
	
	if icon.FakeHidden and not dontremove then
		icon:SetScript("OnUpdate", nil, true)
		tDeleteItem(IconUpdateFuncs, icon)
		if Locked then
			icon:SetAlpha(0)
		end
	end

	icon.__previousNameFirst = nil -- not needed now

	TMW:Icon_UpdateBars(icon, groupID, iconID)
	icon:Show()
	local pbar = icon.pbar
	local cbar = icon.cbar
	if icon.OverrideTex then icon:SetTexture(icon.OverrideTex) end 
	if Locked then
		if icon.texture:GetTexture() == "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled" then
			icon:SetTexture(nil)
		end
		icon:EnableMouse(0)
		if (not icon.Enabled) or (icon.Name == "" and not Types[icon.Type].AllowNoName) then
			ClearScripts(icon)
			icon:Hide()
		end

		pbar:SetValue(100)
	--	pbar:SetValue(0)
		pbar:SetAlpha(.9)
		if icon.ShowPar then
			PwrBarOnUpdate(pbar)
		end
		if icon.InvertBars then
			cbar:SetValue(cbar.Max)
		else
			cbar:SetValue(0)
		end
		cbar:SetAlpha(.9)
		if icon.ShowCBar then
			CDBarOnUpdate(cbar)
			CDBarOnValueChanged(cbar)
		end
	else
		ClearScripts(icon)

		local testCount, testCountText
		if group.FontTest then
			if icon.Type == "buff" then
				testCount = random(1, 20)
			elseif icon.Type == "dr" then
				local rand = random(1, 3)
				testCount = rand == 1 and 0 or rand == 2 and 25 or rand == 3 and 50
				testCountText = testCount.."%"
			elseif icon.Type == "meta" then
				-- its the best of both worlds!
				local rand = random(1, 23)
				testCount = rand == 1 and 0 or rand == 2 and 25 or rand == 3 and 50 or rand - 3
				if rand < 4 then
					testCountText = testCount.."%"
				end
			end
		end
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(1, 1, nil, 0, 0, icon.__spellChecked, nil, testCount, testCountText, nil, nil, icon.__unitChecked) -- alpha is set to 1 here so it doesnt return early
		if icon.Enabled then
			icon:setalpha(1)
		else
			icon:setalpha(0.5)
		end
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
		end

		ClearScripts(cbar)
		cbar.UpdateSet = false
		cbar:SetValue(cbar.Max)
		cbar:SetAlpha(.7)
		cbar:SetStatusBarColor(0, 1, 0, 0.5)

		ClearScripts(pbar)
		pbar.UpdateSet = false
		pbar:SetValue(2000000)
		pbar:SetAlpha(.7)

		icon:EnableMouse(1)
		if icon.Type == "meta" then
			-- meta icons shouln't show bars in config, even though they are force enabled. I hate to do it like this
			cbar:SetValue(0)
			pbar:SetValue(0)
		end
	end
	if not dontreassign then
		TMW:ScheduleTimer("RestoreSound", UPD_INTV*2.1)
	end
	
end

function TMW:InjectDataIntoString(Text, icon, doBlizz)
	if not Text then return Text end
	
	if doBlizz then
		if strfind(Text, "%%[Tt]") then
			Text = gsub(Text, "%%[Tt]", UnitName("target") or TARGET_TOKEN_NOT_FOUND)
		end
		if strfind(Text, "%%[Ff]") then
			Text = gsub(Text, "%%[Ff]", UnitName("focus") or FOCUS_TOKEN_NOT_FOUND)
		end
	end
	
	if strfind(Text, "%%[Mm]") then
		Text = gsub(Text, "%%[Mm]", UnitName("mouseover") or L["MOUSEOVER_TOKEN_NOT_FOUND"])
	end
	
	if icon then
		if strfind(Text, "%%[Uu]") then
			Text = gsub(Text, "%%[Uu]", icon.__oldUnitName or UnitName(icon.__unitChecked or "") or "?")
		end
		
		if strfind(Text, "%%[Ss]") then
			local name, checkcase = icon.typeData:GetNameForDisplay(icon, icon.__spellChecked)
			name = name or "?"
			if checkcase then
				name = loweredbackup[name] or name
			end
			Text = gsub(Text, "%%[Ss]", name)
		end
	end
	
	return Text
end

-- ------------------
-- NAME/ETC FUNCTIONS
-- ------------------

local mult = {
	1,						-- seconds per second
	60,						-- seconds per minute
	60*60,					-- seconds per hour
	60*60*24,				-- seconds per day
	60*60*24*365.242199,	-- seconds per year
}
function string:toseconds()
	-- converts a string (e.g. "1:45:37") into the number of seconds that it represents (eg. 6337)
	self = ":" .. self:trim(": ") -- a colon is needed at the beginning so that gmatch will catch the first unit of time in the string (minutes, hours, etc)
	local _, numcolon = self:gsub(":", ":") -- HACK: count the number of colons in the string so that we can keep track of what multiplier we are on (since we start with the highest unit of time)
	local seconds = 0 
	for num in self:gmatch(":([0-9%.]*)") do -- iterate over all units of time and their value
		if tonumber(num) and mult[numcolon] then -- make sure that it is valid (there is a number and it isnt a unit of time higher than a year)
			seconds = seconds + mult[numcolon]*num -- multiply the number of units by the number of seconds in that unit and add the appropriate amount of time to the running count
		end
		numcolon = numcolon - 1 -- decrease the current unit of time that is being worked with (even if it was an invalid unit and failed the above check)
	end
	return seconds 
end

function TMW:lowerNames(str)
	-- converts a string, or all values of a table, to lowercase. Numbers are kept as numbers.
	if type(str) == "table" then -- handle a table with recursion
		for k, v in pairs(str) do
			str[k] = TMW:lowerNames(v)
		end
		return str
	end
	
	-- Dispel types retain their capitalization. Restore it here.
	for ds in pairs(TMW.DS) do
		if strlower(ds) == strlower(str) then
			return ds
		end
	end
	
	local ret = tonumber(str) or strlower(str)
	loweredbackup[ret] = str
	
	return ret
end

local function getCacheString(...)
	-- returns a string containing all args
	-- tostringall is a Blizzard function defined in UIParent.lua
	return strconcat(tostringall(...))
end

local eqttcache = {}
function TMW:EquivToTable(name)
	-- this function checks to see if a string is a valid equivalency. If it is, all the spells that it represents will be put into an array and returned. If it isn't, nil will be returned.
	local cachestring = getCacheString(name, TMW.BE)
	if eqttcache[cachestring] then return eqttcache[cachestring] end -- if we already made a table of this string, then reuse it to not create garbage
	
	name = strlower(name) -- everything in this function is handled as lowercase to prevent issues with user input capitalization. DONT use TMW:lowerNames() here.
	local eqname, duration = strmatch(name, "(.-):([%d:%s%.]*)$") -- see if the string being checked has a duration attached to it (it really shouldn't because there is currently no point in doing so, but a user did try this and made a bug report, so I fixed it anyway
	name = eqname or name -- if there was a duration, then replace the old name with the actual name without the duration attached
	
	local names -- scope the variable
	for k, v in pairs(TMW.BE) do -- check in subtables ('buffs', 'debuffs', 'casts', etc)
		for equiv, str in pairs(v) do
			if strlower(equiv) == name and (TMW.BE ~= TMW.OldBE or equiv ~= "Enraged") then -- dont expand the enrage equiv if we are hacking with OldBE
				names = str
				break -- break subtable loop
			end
		end
		if names then break end -- break main loop
	end
	
	if not names then return end -- if we didnt find an equivalency string then get out
	

	local tbl = { strsplit(";", names) } -- split the string into a table
	for a, b in pairs(tbl) do
		local new = strtrim(b) -- take off trailing spaces
		new = tonumber(new) or new -- make sure it is a number if it can be
		if duration then -- tack on the duration that should be applied to all spells if there was one
			new = new .. ":" .. duration
		end
		tbl[a] = new -- stick it in the table
	end
	
	eqttcache[cachestring] = tbl -- cache the end result
	
	return tbl
end

local gsncache = {}
function TMW:GetSpellNames(icon, setting, firstOnly, toname, hash, keepDurations)
	local cachestring = getCacheString(icon, setting, firstOnly, toname, hash, keepDurations, TMW.BE) -- a unique key for the cache table, turn possible nils into strings
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
		local first, num = tContains(buffNames, buffNames[k], true)
		if num > 1 then
			tremove(buffNames, k) --if the current value occurs more than once then remove this entry of it
		else
			k = k - 1 --there are no duplicates, so move backwards towards zero
		end
	end
	
	-- REMOVE SPELL DURATIONS (FOR UNIT COOLDOWNS/ICDs)
	if not keepDurations then
		for k, buffName in pairs(buffNames) do
			if strfind(buffName, ":[%d:%s%.]*$") then
				local new = strmatch(buffName, "(.-):[%d:%s%.]*$")
				buffNames[k] = tonumber(new) or new -- turn it into a number if it is one
			end
		end
	end
	if icon then
		buffNames = TMW:lowerNames(buffNames)
	end

	if hash then
		local hash = {}
		for k, v in ipairs(buffNames) do
			if toname then
				v = GetSpellInfo(v or "") or v -- turn the value into a name if needed
			end
			
			v = TMW:lowerNames(v)
			hash[v] = k -- put the final value in the table as well (may or may not be the same as the original value. Value should be NameArrray's key, for use with the duration table.
		end
		gsncache[cachestring] = hash
		return hash
	end
	if toname then
		if firstOnly then
			local ret = buffNames[1] or ""
			ret = GetSpellInfo(ret) or ret -- turn the first value into a name and return it
			if icon then ret = TMW:lowerNames(ret) end
			gsncache[cachestring] = ret
			return ret
		else
			for k, v in ipairs(buffNames) do
				buffNames[k] = GetSpellInfo(v or "") or v --convert everything to a name
			end
			if icon then TMW:lowerNames(buffNames) end
			gsncache[cachestring] = buffNames
			return buffNames
		end
	end
	if firstOnly then
		local ret = buffNames[1] or ""
		gsncache[cachestring] = ret
		return ret
	end
	gsncache[cachestring] = buffNames
	return buffNames
end

local gsdcache = {}
function TMW:GetSpellDurations(icon, setting)
	if gsdcache[setting] then return gsdcache[setting] end --why make a bunch of tables and do a bunch of stuff if we dont need to
	
	local NameArray = TMW:GetSpellNames(icon, setting, nil, nil, nil, 1)
	local DurationArray = CopyTable(NameArray)
	
	-- EXTRACT SPELL DURATIONS
	for k, buffName in pairs(NameArray) do
		DurationArray[k] = strmatch(buffName, ".-:([%d:%s%.]*)$")
		if not DurationArray[k] then
			DurationArray[k] = 0
		else
			DurationArray[k] = tonumber(DurationArray[k]:trim(" :;."):toseconds())
		end
	end
	
	gsdcache[setting] = DurationArray
	return DurationArray
end

function TMW:GetItemIDs(icon, setting, firstOnly, toname)
	-- note: these cannot be cached because of slotIDs

	
	local names = TMW:SplitNames(setting)
	-- REMOVE SPELL DURATIONS (FOR WHATEVER REASON THE USER MIGHT HAVE PUT THEM IN FOR ITEMS)
	for k, item in pairs(names) do
		if strfind(item, ":[%d:%s%.]*$") then
			local new = strmatch(item, "(.-):[%d:%s%.]*$")
			names[k] = tonumber(new) or new -- turn it into a number if it is one
		end
	end
	if icon then
		names = TMW:lowerNames(names)
	end
	
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
TMW.Units = {
	{ value = "player", 			text = PLAYER .. " " .. L["PLAYER_DESC"]  },
	{ value = "target", 			text = TARGET },
	{ value = "targettarget", 		text = L["ICONMENU_TARGETTARGET"] },
	{ value = "focus", 				text = L["ICONMENU_FOCUS"] },
	{ value = "focustarget", 		text = L["ICONMENU_FOCUSTARGET"] },
	{ value = "pet", 				text = PET },
	{ value = "pettarget", 			text = L["ICONMENU_PETTARGET"] },
	{ value = "mouseover", 			text = L["ICONMENU_MOUSEOVER"] },
	{ value = "mouseovertarget",	text = L["ICONMENU_MOUSEOVERTARGET"]  },
	{ value = "vehicle", 			text = L["ICONMENU_VEHICLE"] },
	{ value = "party", 				text = PARTY, 			range = MAX_PARTY_MEMBERS},
	{ value = "raid", 				text = RAID, 			range = MAX_RAID_MEMBERS},
	{ value = "arena",				text = ARENA, 			range = 5},
	{ value = "boss", 				text = BOSS, 			range = MAX_BOSS_FRAMES},
	{ value = "maintank", 			text = L["MAINTANK"], 	range = MAX_RAID_MEMBERS},
	{ value = "mainassist", 		text = L["MAINASSIST"], range = MAX_RAID_MEMBERS},
}
function TMW:GetUnits(icon, setting, dontreplace)
	local cachestring = getCacheString(setting, dontreplace)
	if unitcache[cachestring] then return unitcache[cachestring] end --why make a bunch of tables and do a bunch of stuff if we dont need to

	setting = TMW:CleanString(setting):
	lower(): -- all units should be lowercase
	gsub("|cffff0000", ""): -- strip color codes (NOTE LOWERCASE)
	gsub("|r", ""):
	gsub("#", "") -- strip the # from the dropdown
	
	
	--SUBSTITUTE "party" with "party1-4", etc
	for _, wholething in TMW:Vararg(strsplit(";", setting)) do
		local unit = strtrim(wholething)
		for k, v in pairs(TMW.Units) do
			if v.value == unit and v.range then
				setting = gsub(setting, wholething, unit .. "1-" .. v.range)
				break
			end
		end
	end
	
	--SUBSTITUTE RAID1-10 WITH RAID1;RAID2;RAID3;...RAID10
	local startpos, endpos = 0, 0
	for wholething, unit, firstnum, lastnum in gmatch(setting, "((%a+) ?(%d+) ?%- ?(%d+)) ?;?") do
		if unit and firstnum and lastnum then
			local str = ""
			local order = firstnum > lastnum and -1 or 1

			if abs(lastnum - firstnum) > 100 then
				TMW:Print("Why on Earth would you want to track more than 100", unit, "units? I'll just ignore it and save you from possibly crashing.")
			else
				for i = firstnum, lastnum, order do
					str = str .. unit .. i .. ";"
				end
				str = strtrim(str, " ;")
				wholething = gsub(wholething, "%-", "%%-") -- need to escape the dash for it to work
				setting = gsub(setting, wholething, str)
			end
		end
	end

	local Units = TMW:SplitNames(setting) -- get a table of everything

	-- REMOVE DUPLICATES
	local k = #Units --start at the end of the table so that we dont remove duplicates at the beginning of the table
	while k > 0 do
		if select(2, tContains(Units, Units[k], true)) > 1 then
			tremove(Units, k) --if the current value occurs more than once then remove this entry of it
		else
			k = k - 1 --there are no duplicates, so move backwards towards zero
		end
	end

	if not dontreplace then -- flag to set to not put it into the replacement engine. Used for shift-hover tooltips (maybe)
		--DETECT maintank#, mainassist#, etc, and make them substitute in real unitIDs -- MUST BE LAST
		for k, unit in pairs(Units) do
			if strfind(unit, "^maintank") or strfind(unit, "^mainassist") then
				local original = CopyTable(Units) 	-- copy the original unit table so we know what units to scan for when they may have changed
				unitsToChange[original] = Units 	-- store the table that will be getting changed with the original
				TMW:RegisterEvent("RAID_ROSTER_UPDATE")
				TMW:RAID_ROSTER_UPDATE()
				break
			end
		end
	end

	unitcache[cachestring] = Units
	return Units
end

local function replace(text, find, rep)
	-- using this allows for the replacement of ";       " to "; " in one external call
	assert(not strfind(rep, find), "RECURSION DETECTED: FIND=".. find.. " REP=".. rep)
	while strfind(text, find) do
		text = gsub(text, find, rep)
	end
	return text
end
function TMW:CleanString(text)
	local isFrame
	if type(text) == "table" and text.GetText then
		isFrame = text
		text = text:GetText()
	end
	if not text then TMW:Error("No text to clean!") end
	text = strtrim(text, "; \t\r\n")-- remove all leading and trailing semicolons, spaces, tabs, and newlines
	text = replace(text, "[^:] ;", "; ") -- remove all spaces before semicolons
	text = replace(text, "; ", ";") -- remove all spaces after semicolons
	text = replace(text, ";;", ";") -- remove all double semicolons
	text = replace(text, " :", ":") -- remove all single spaces before colons
	text = replace(text, ":  ", ": ") -- remove all double spaces after colons (DONT REMOVE ALL DOUBLE SPACES EVERYWHERE, SOME SPELLS HAVE TYPO'd NAMES WITH 2 SPACES!)
	text = gsub(text, ";", "; ") -- add spaces after all semicolons. Never used to do this, but it just looks so much better (DONT USE replace!).
	if isFrame then
		isFrame:SetText(text)
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

function TMW:GetConfigIconTexture(icon, isItem)
	if icon.Name == "" then
		return "Interface\\Icons\\INV_Misc_QuestionMark", nil
	else
	
		local BEbackup = TMW.BE
		TMW.BE = TMW.OldBE
		-- the level of hackyness here is sickening. Note that OldBE does not contain the enrage equiv
		
		local tbl = isItem and TMW:GetItemIDs(nil, icon.Name) or TMW:GetSpellNames(nil, icon.Name)
		TMW.BE = BEbackup -- unhack
	
		for _, name in ipairs(tbl) do
			local t = isItem and GetItemIcon(name) or SpellTextures[name]
			if t then
				return t, true
			end
		end
		if Types[icon.Type].usePocketWatch then
			if TMW.IE and TMW.CI.ic == icon and not db.global.HelpSettings.PocketWatch and TellMeWhen_IconEditor:IsShown() then
				TMW.IE:ShowHelp(L["HELP_POCKETWATCH"], TMW.IE.icontexture, 0, 0, true)
				db.global.HelpSettings.PocketWatch = 1
			end
			return "Interface\\Icons\\INV_Misc_PocketWatch_01", false
		else
			return "Interface\\Icons\\INV_Misc_QuestionMark", false
		end
	end
end

TMW.TestTex = TMW:CreateTexture()
function TMW:GetCustomTexture(icon)
	icon.CustomTex = icon.CustomTex ~= "" and icon.CustomTex
	if icon.CustomTex then
		TMW.TestTex:SetTexture(SpellTextures[icon.CustomTex])
		if not TMW.TestTex:GetTexture() then
			TMW.TestTex:SetTexture(icon.CustomTex)
		end
		if not TMW.TestTex:GetTexture() then
			TMW.TestTex:SetTexture("Interface\\Icons\\" .. icon.CustomTex)
		end
		return TMW.TestTex:GetTexture()
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
		LibStub("AceConfigDialog-3.0"):Open("TMW Options")
	else
		TMW:LockToggle()
	end
end
TMW:RegisterChatCommand("tmw", "SlashCommand")
TMW:RegisterChatCommand("tellmewhen", "SlashCommand")


