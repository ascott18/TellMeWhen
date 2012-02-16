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

local TMW = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", "TMW", UIParent), "TellMeWhen", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0")
TellMeWhen = TMW

local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
--L = setmetatable({}, {__index = function() return "| ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! | ! " end}) -- stress testing for text widths
TMW.L = L
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local DRData = LibStub("DRData-1.0", true)

TELLMEWHEN_VERSION = "5.0.0"
TELLMEWHEN_VERSION_MINOR = strmatch(" @project-version@", " r%d+") or ""
TELLMEWHEN_VERSION_FULL = TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR
TELLMEWHEN_VERSIONNUMBER = 50018 -- NEVER DECREASE THIS NUMBER (duh?).  IT IS ALSO ONLY INTERNAL
if TELLMEWHEN_VERSIONNUMBER > 51000 or TELLMEWHEN_VERSIONNUMBER < 50000 then return error("YOU SCREWED UP THE VERSION NUMBER OR DIDNT CHANGE THE SAFETY LIMITS") end -- safety check because i accidentally made the version number 414069 once

TELLMEWHEN_MAXGROUPS = 1 	--this is a default, used by SetTheory (addon), so dont rename
TELLMEWHEN_MAXROWS = 20


---------- Upvalues ----------
local GetSpellCooldown, GetSpellInfo, GetSpellTexture, GetSpellLink, GetSpellBookItemInfo =
	  GetSpellCooldown, GetSpellInfo, GetSpellTexture, GetSpellLink, GetSpellBookItemInfo
local GetItemInfo, GetInventoryItemID, GetItemIcon =
	  GetItemInfo, GetInventoryItemID, GetItemIcon
local GetActiveTalentGroup, GetPrimaryTalentTree, GetNumTalentTabs, GetNumTalents, GetTalentInfo =
	  GetActiveTalentGroup, GetPrimaryTalentTree, GetNumTalentTabs, GetNumTalents, GetTalentInfo
local UnitPower, UnitClass, UnitGUID, UnitName, UnitInBattleground, UnitInRaid, UnitExists =
	  UnitPower, UnitClass, UnitGUID, UnitName, UnitInBattleground, UnitInRaid, UnitExists
local PlaySoundFile, PlaySound, SendChatMessage, GetChannelList =
	  PlaySoundFile, PlaySound, SendChatMessage, GetChannelList
local GetNumRaidMembers, GetNumPartyMembers, GetRealNumRaidMembers, GetRealNumPartyMembers, GetPartyAssignment, InCombatLockdown =
	  GetNumRaidMembers, GetNumPartyMembers, GetRealNumRaidMembers, GetRealNumPartyMembers, GetPartyAssignment, InCombatLockdown
local GetNumBattlefieldScores, GetBattlefieldScore = 
	  GetNumBattlefieldScores, GetBattlefieldScore
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, next, assert, pcall, getmetatable, setmetatable, date, CopyTable =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, next, assert, pcall, getmetatable, setmetatable, date, CopyTable
local strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, min, max, ceil, floor, abs, random =
	  strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, min, max, ceil, floor, abs, random
local _G, GetTime =
	  _G, GetTime
local MikSBT, Parrot, SCT =
	  MikSBT, Parrot, SCT
local TARGET_TOKEN_NOT_FOUND, FOCUS_TOKEN_NOT_FOUND =
	  TARGET_TOKEN_NOT_FOUND, FOCUS_TOKEN_NOT_FOUND
--local CL_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local bitband = bit.band
local huge = math.huge


---------- Locals ----------
local db, updatehandler, BarGCD, ClockGCD, Locked, SndChan, FramesToFind, CNDTEnv, ColorMSQ, OnlyMSQ, AnimationList
local NAMES, EVENTS, ANIM, ANN, SND
local UPD_INTV = 0.06	--this is a default, local because i use it in onupdate functions
local runEvents, updatePBars = 1, 1
local GCD, NumShapeshiftForms, LastUpdate, LastBindTextUpdate = 0, 0, 0, 0
local IconsToUpdate, GroupsToUpdate = {}, {}
local BindTextObjsToUpdate
local loweredbackup = {}
local callbackregistry = {}
local bullshitTable = {}
local ActiveAnimations = {}
local CBarsToUpdate, PBarsToUpdate = {}, {}
local time = GetTime() TMW.time = time
local sctcolor = {r=1, b=1, g=1}
local clientVersion = select(4, GetBuildInfo())
local addonVersion = tonumber(GetAddOnMetadata("TellMeWhen", "X-Interface"))
local _, pclass = UnitClass("Player")


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

do	-- Class Lib
	TMW.Classes = {}
	local metamethods = {
		__add = true,
		__call = true,
		__concat = true,
		__div = true,
		__le = true,
		__lt = true,
		__mod = true,
		__mul = true,
		__pow = true,
		__sub = true,
		__tostring = true,
		__unm = true,
	}
	local function writeerror(self, key, value)
		TMW:Error("Cannot write value %q to key %q on class %q because an instance has already been created", value, key, self.name)
	end
	
	local function initializeClass(self)
		if not self.instances[1] then
			-- set any defined metamethods
			for k, v in pairs(self.instancemeta.__index) do
				if metamethods[k] then
					self.instancemeta[k] = v
				end
			end

			getmetatable(self).__newindex = writeerror
		end
	end
	
	local function New(self, ...)
		local instance
		if ... and self.isFrameObject then
			instance = CreateFrame(...)
		else
			instance = {}
		end

		-- if this is the first instance of the class, do some magic to it:
		initializeClass(self)

		instance.class = self
		instance.className = self.name

		setmetatable(instance, self.instancemeta)

		self.instances[#self.instances + 1] = instance

		for k, v in pairs(self.instancemeta.__index) do
			if type(k) == "string" and k:find("^OnNewInstance") then
				v(instance, ...)
			end
		end

		return instance
	end
	
	local function Embed(self, target, canOverwrite)
		-- if this is the first instance (not really an instance here, but we need to anyway) of the class, do some magic to it:
		initializeClass(self)

		self.embeds[target] = true

		for k, v in pairs(self.instancemeta.__index) do
			if target[k] and not canOverwrite then
				TMW:Error("Error embedding class %s into target %s: Field %q already exists on the target.", self.name, tostring(target:GetName() or target), k)
			else
				target[k] = v
			end
		end
		
		for k, v in pairs(self.instancemeta) do
			if type(k) == "string" and k:find("^OnNewInstance") then
				v(instance)
			end
		end

		return target
	end

	function TMW:NewClass(className, ...)
		local metatable = {__index = {}}

		local isFrameObject
		for n, v in TMW:Vararg(...) do
			local meta
			if n == 1 and not TMW.Classes[v] then
				isFrameObject = true
				meta = getmetatable(CreateFrame(v))
			elseif TMW.Classes[v] then
				meta = getmetatable(TMW.Classes[v])			
			end			
			
			if meta and meta.__index then
				for k, v in pairs(meta.__index) do
					metatable.__index[k] = metatable.__index[k] or v
				end
			end
		end
		
		metatable.__index.isFrameObject = metatable.__index.isFrameObject or isFrameObject
		metatable.__newindex = metatable.__index

		local class = {
			name = className,
			instances = {},
			embeds = {},
			New = New,
			Embed = Embed,
			instancemeta = {__index = metatable.__index},
			isFrameObject = isFrameObject,
		}

		setmetatable(class, metatable)

		TMW.Classes[className] = class

		return class
	end
end


---------- Caches ----------
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

function TMW.tDeleteItem(table, item, onlyOne)
	local i = 1
	while table[i] do
		if item == table[i] then
			tremove(table, i)
			if onlyOne then
				return
			end
		else
			i = i + 1
		end
	end
end local tDeleteItem = TMW.tDeleteItem

local function ClearScripts(f)
	f:SetScript("OnEvent", nil)
	f:SetScript("OnUpdate", nil)
	if f:HasScript("OnValueChanged") then
		f:SetScript("OnValueChanged", nil)
	end
end

function TMW.print(...)
	if TMW.debug or not TMW.VarsLoaded then
		local prefix = "|cffff0000TMW"
		if linenum then
		--	prefix = prefix..format(" %4.0f", linenum(3))
			prefix = format("|cffff0000 %s", linenum(3, 1))
		end
		prefix = prefix..":|r "
		local func = TMW.debug and TMW.debug.print or _G.print
		if ... == TMW then
			func(prefix, select(2,...))
		else
			func(prefix, ...)
		end
	end
	return ...
end
local print = TMW.print
TMW.Debug = TMW.print

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

do -- Iterators
	local mg = TELLMEWHEN_MAXGROUPS
	local mi = TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS


	do -- InConditionSettings

		local stage, currentConditions, currentCondition, ci, cg, extIter
		local function iter()

			currentCondition = currentCondition + 1

			if not currentConditions or currentCondition > (currentConditions.n or #currentConditions) then
				local settings
				settings, cg, ci = extIter()
				if not settings then
					if stage == "icon" then
						extIter = TMW:InGroupSettings()
						stage = "group"
						return iter()
					else
						return
					end
				end
				currentConditions = settings.Conditions
				currentCondition = 0
				return iter()
			end
			local condition = rawget(currentConditions, currentCondition)
			if not condition then return iter() end
			return condition, currentCondition, cg, ci -- condition data, conditionID, groupID, iconID
		end

		function TMW:InConditionSettings()
			stage = "icon"
			extIter = TMW:InIconSettings()
			currentCondition = 0
			return iter
		end
	end

	do -- InConditions

		local Conditions, ConditionID
		local function iter()
			ConditionID = ConditionID + 1

			if ConditionID > (Conditions.n  or #Conditions) then -- #Conditions enables iteration over tables that have not yet been upgraded with an n key (i.e. imported data from old versions)
				return
			end
			local Condition = Conditions[ConditionID]
			return Condition, ConditionID
		end

		function TMW:InConditions(arg)
			ConditionID = 0
			Conditions = arg
			return iter
		end
	end

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
			return rawget(db.profile.Groups, cg) and rawget(db.profile.Groups[cg].Icons,ci), cg, ci -- ics, groupID, iconID
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

		function TMW:InIcons(groupID)
			cg = groupID or 1
			ci = 0
			mg = groupID or TELLMEWHEN_MAXGROUPS
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
		local handlers = {}
		local function gethandler(...)
			local handler = wipe(tremove(handlers) or {})

			handler.i = 0
			handler.l = select("#", ...)

			for n = 1, handler.l do
				handler[n] = select(n, ...)
			end

			return handler
		end

		local function iter(handler)
			local i = handler.i
			i = i + 1
			if i > handler.l then
				tinsert(handlers, handler)
				return
			end
			handler.i = i

			return i, handler[i], handler.l
		end

		function TMW:Vararg(...)
			return iter, gethandler(...)
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
	__index = {
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
}

TMW.Types = setmetatable({}, {
	__index = function(t, k)
		if type(k) == "table" and k.class == TMW.Classes.Icon then -- if the key is an icon, then return the icon's Type table
			return t[k.Type]
		else -- if no type exists, then use the fallback (default) type
			return rawget(t, "")
		end
	end
}) local Types = TMW.Types
TMW.OrderedTypes = {}

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
			HasChangedUnit = 0,
		},
		--[[CodeSnippets = {
		},]]
		HasImported			= false,
		ConfigWarning		= true,
		VersionWarning		= true,
	},
	profile = {
	--	Version			= 	TELLMEWHEN_VERSIONNUMBER,  -- DO NOT DEFINE VERSION AS A DEFAULT, OTHERWISE WE CANT TRACK IF A USER HAS AN OLD VERSION BECAUSE IT WILL ALWAYS DEFAULT TO THE LATEST
		Locked			= 	false,
		NumGroups		=	1,
		Interval		=	UPD_INTV,
		EffThreshold	=	15,
		TextureName		= 	"Blizzard",
		DrawEdge		=	false,
		MasterSound		=	false,
		ReceiveComm		=	true,
		WarnInvalids	=	true,
		BarGCD			=	true,
		ClockGCD		=	true,
		CheckOrder		=	-1,
		SUG_atBeginning	=	true,
		ColorNames		=	true,
		AlwaysSubLinks	=	false,
	--[[	CodeSnippets = {
		},]]
		ColorMSQ	 	 = false,
		OnlyMSQ		 	 = false,

		Colors = {
			["**"] = {
				CBC = 	{r=0,	g=1,	b=0,	Override = false,	a=1,	},	-- cooldown bar complete
				CBS = 	{r=1,	g=0,	b=0,	Override = false,	a=1,	},	-- cooldown bar start

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
				SortPriorities = {
					{Method = "id",				Order =	1,	},
					{Method = "duration",		Order =	1,	},
					{Method = "stacks",			Order =	-1,	},
					{Method = "visiblealpha",	Order =	-1,	},
					{Method = "visibleshown",	Order =	-1,	},
					{Method = "alpha",			Order =	-1,	},
					{Method = "shown",			Order =	-1,	},
				},
				Point = {
					point 		  = "CENTER",
					relativeTo 	  = "UIParent",
					relativePoint = "CENTER",
					x 			  = 0,
					y 			  = 0,
				},
				Fonts = {
					["**"] = {
						Name 		   = "Arial Narrow",
						Size 		   = 12,
						x 	 		   = -2,
						y 	 		   = 2,
						point 		   = "CENTER",
						relativePoint  = "CENTER",
						Outline 	   = "THICKOUTLINE",
						OverrideLBFPos = false,
						ConstrainWidth = true,
					},
					Count = {
						ConstrainWidth = false,
						point 		   = "BOTTOMRIGHT",
						relativePoint  = "BOTTOMRIGHT",
					},
					Bind = {
						y 			  = -2,
						point 		  = "TOPLEFT",
						relativePoint = "TOPLEFT",
					},
				},
				Icons = {
					["**"] = {
						BuffOrDebuff			= "HELPFUL",
						ShowWhen				= "alpha",
						Enabled					= false,
						Name					= "",
						CustomTex				= "",
						OnlyMine				= false,
						ShowTimer				= false,
						ShowTimerText			= false,
						ShowPBar				= false,
						ShowCBar				= false,
						PBarOffs				= 0,
						CBarOffs				= 0,
						InvertBars				= false,
						Type					= "",
						Unit					= "player",
						WpnEnchantType			= "MainHandSlot",
						Alpha					= 1,
						UnAlpha					= 1,
						ConditionAlpha			= 0,
						RangeCheck				= false,
						ManaCheck				= false,
						CooldownCheck			= false,
						IgnoreRunes				= false,
						StackMin				= 0,
						StackMax				= 0,
						StackMinEnabled			= false,
						StackMaxEnabled			= false,
						DurationMin				= 0,
						DurationMax				= 0,
						DurationMinEnabled		= false,
						DurationMaxEnabled		= false,
						FakeHidden				= false,
						HideUnequipped			= false,
						Interruptible			= false,
						ICDType					= "aura",
						CheckNext				= false,
						DontRefresh				= false,
						UseActvtnOverlay		= false,
						OnlyEquipped			= false,
						EnableStacks			= false,
						OnlyInBags				= false,
						OnlySeen				= false,
						Stealable				= false,
						IgnoreNomana			= false,
						ShowTTText				= false,
						CheckRefresh			= true,
						Sort					= false,
						TotemSlots				= 2^6-1,
						BindText				= "",
						ConditionDur			= 0,
						UnConditionDur			= 0,
						ConditionDurEnabled		= false,
						UnConditionDurEnabled  	= false,
						OnlyIfCounting			= false,
						SourceUnit				= "",
						DestUnit 				= "",
						SourceFlags				= 2^32-1,
						DestFlags				= 2^32-1,
						CLEUDur					= 5,
						CLEUEvents 				= {
							["*"] 				= false
						},
						Icons					= {
							[1]					= "",
						},
						Events 					= {
							["**"] 				= {
								Sound 	  		= "None",

								Text 	  		= "",
								Channel			= "",
								Location  		= "",
								Sticky 	  		= false,
								Icon 	  		= true,
								r 		  		= 1,
								g 		  		= 1,
								b 		  		= 1,
								Size 	  		= 0,

								Animation	  	= "",
								Duration		= 0.8,
								Magnitude	  	= 10,
								ScaleMagnitude 	= 2,
								Period			= 0.4,
								Size_anim	  	= 30,
								SizeX	  		= 30,
								SizeY	  		= 30,
								Thickness	  	= 2,
								Fade	  		= true,
								Infinite  		= false,
								r_anim	  		= 1,
								g_anim	  		= 0,
								b_anim	  		= 0,
								a_anim	  		= 0.5,
								Image			= "",

								OnlyShown 		= false,
								Operator 		= "<",
								Value 			= 0,
								CndtJustPassed 	= false,
								PassingCndt		= false,
								PassThrough		= false,
								Icon			= "",
							},
							OnDuration = {
								CndtJustPassed 	= true,
								PassingCndt		= true,
							},
						},
						Conditions = {
							n 					= 0,
							["**"] = {
								AndOr 	   		= "AND",
								Type 	   		= "",
								Icon 	   		= "",
								Operator   		= "==",
								Level 	   		= 0,
								Unit 	   		= "player",
								Name 	   		= "",
								Name2 	   		= "",
								PrtsBefore 		= 0,
								PrtsAfter  		= 0,
								Checked			= false,
								Checked2   		= false,
								Runes 	   		= {},
							},
						},
					},
				},
			},
		},
	},
}
TMW.Group_Defaults 			  = TMW.Defaults.profile.Groups["**"]	-- shortcut
TMW.Icon_Defaults 			  = TMW.Group_Defaults.Icons["**"]		-- shortcut
TMW.Group_Defaults.Conditions = TMW.Icon_Defaults.Conditions		-- functional replication


TMW.GCDSpells = {
	ROGUE		= 1752, -- sinister strike
	PRIEST		= 139, -- renew
	DRUID		= 774, -- rejuvenation
	WARRIOR		= 772, -- rend
	MAGE		= 133, -- fireball
	WARLOCK		= 687, -- demon armor
	PALADIN		= 20154, -- seal of righteousness
	SHAMAN		= 324, -- lightning shield
	HUNTER		= 1978, -- serpent sting
	DEATHKNIGHT = 47541, -- death coil
} local GCDSpell = TMW.GCDSpells[pclass] TMW.GCDSpell = GCDSpell

TMW.DefaultPowerTypes = {
	ROGUE		= 3,
	PRIEST		= 0,
	DRUID		= 0,
	WARRIOR		= 1,
	MAGE		= 0,
	WARLOCK		= 0,
	PALADIN		= 0,
	SHAMAN		= 0,
	HUNTER		= 2,
	DEATHKNIGHT = 6,
} local defaultPowerType = TMW.DefaultPowerTypes[pclass]

TMW.DS = {
	Magic 	= "Interface\\Icons\\spell_fire_immolation",
	Curse 	= "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison 	= "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}

TMW.BE = {
	--Most of these are thanks to Malazee @ US-Dalaran's chart: http://forums.wow-petopia.com/download/file.php?mode=view&id=4979 and spreadsheet https://spreadsheets.google.com/ccc?key=0Aox2ZHZE6e_SdHhTc0tZam05QVJDU0lONnp0ZVgzdkE&hl=en#gid=18
	--Many more new spells/corrections were provided by Catok of Curse

	--NOTE: any id prefixed with "_" will have its localized name substituted in instead of being forced to match as an ID
	debuffs = {
		CrowdControl		= "_118;2637;33786;_1499;_19503;_19386;20066;10326;_9484;_6770;_2094;_51514;76780;_710;_5782;_6358;_49203;_605;82691", -- originally by calico0 of Curse
		Bleeding			= "_94009;_1822;_1079;9007;33745;1943;703;43104;89775",
		Incapacitated		= "20066;1776;49203",
		Feared				= "_5782;5246;_8122;10326;1513;_5484;_6789;87204;20511",
		Slowed				= "_116;_120;13810;_5116;_8056;3600;_1715;_12323;45524;_18223;_15407;_3409;26679;_51693;_2974;_58180;61391;_50434;_55741;44614;_7302;_8034;_63529;_15571", -- by algus2
		Stunned				= "_1833;_408;_91800;_5211;_56;9005;22570;19577;56626;44572;853;2812;85388;64044;20549;46968;30283;20253;65929;7922;12809;50519;91797;47481;12355;24394;83047;39796;93986;89766;54786",
		--DontMelee			= "5277;871;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",  --does somebody want to update these for me?
		--MovementSlowed	= "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Ice Trap;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
		Disoriented			= "_19503;31661;_2094;_51514;90337;88625",
		Silenced			= "_47476;78675;34490;_55021;_15487;1330;_24259;_18498;_25046;81261;31935;18425;31117",
		Disarmed			= "_51722;_676;64058;50541;91644",
		Rooted				= "_339;_122;23694;58373;64695;_19185;33395;4167;54706;50245;90327;16979;83301;83302;45334;19306;_55080;87195;63685;19387",
		Shatterable			= "122;33395;_83302;_44572;_55080;_82691", -- by algus2
		PhysicalDmgTaken	= "30070;58683;81326;50518;55749",
		SpellDamageTaken	= "_1490;65142;_85547;60433;93068;34889;24844",
		SpellCritTaken		= "17800;22959",
		BleedDamageTaken	= "33878;33876;16511;_46857;50271;35290;57386",
		ReducedAttackSpeed  = "6343;55095;58180;68055;8042;90314;50285",
		ReducedCastingSpeed = "1714;5760;31589;73975;50274;50498",
		ReducedArmor		= "_58567;91565;8647;_50498;35387",
		ReducedHealing		= "12294;13218;56112;48301;82654;30213;54680",
		ReducedPhysicalDone = "1160;99;26017;81130;702;24423",
	},
	buffs = {
		ImmuneToStun		= "642;45438;19574;48792;1022;33786;710;46924;19263;6615",
		ImmuneToMagicCC		= "642;45438;48707;19574;33786;710;46924;19263;31224;8178;23920;49039",
		IncreasedStats		= "79061;79063;90363",
		IncreasedDamage		= "75447;82930",
		IncreasedCrit		= "24932;29801;51701;51470;24604;90309",
		IncreasedAP			= "79102;53138;19506;30808",
		IncreasedSPsix		= "_79058;_61316;_52109",
		IncreasedSPten		= "77747;53646",
		IncreasedPhysHaste  = "55610;53290;8515",
		IncreasedSpellHaste = "2895;24907;49868",
		BurstHaste			= "2825;32182;80353;90355",
		BonusAgiStr			= "6673;8076;57330;93435",
		BonusStamina		= "79105;469;6307;90364",
		BonusArmor			= "465;8072",
		BonusMana			= "_79058;_61316;54424",
		ManaRegen			= "54424;79102;5677",
		BurstManaRegen		= "29166;16191;64901",
		PushbackResistance  = "19746;87717",
		Resistances			= "19891;8185",
		DefensiveBuffs		= "48707;30823;33206;47585;871;48792;498;22812;61336;5277;74001;47788;19263;6940;_12976;31850;31224;42650;86657",
		MiscHelpfulBuffs	= "89488;10060;23920;68992;31642;54428;2983;1850;29166;16689;53271;1044;31821;45182",
		DamageBuffs			= "1719;12292;85730;50334;5217;3045;77801;34692;31884;51713;49016;12472;57933;64701;86700",
	},
	casts = {
		--prefixing with _ doesnt really matter here since casts only match by ID, but it may prevent confusion if people try and use these as buff/debuff equivs
		Heals				= "50464;5185;8936;740;2050;2060;2061;32546;596;64843;635;82326;19750;331;77472;8004;1064;73920",
		PvPSpells			= "33786;339;20484;1513;982;64901;_605;453;5782;5484;79268;10326;51514;118;12051",
		Tier11Interrupts	= "_83703;_82752;_82636;_83070;_79710;_77896;_77569;_80734;_82411",
		Tier12Interrupts	= "_97202;_100094",
	},
	dr = {
	},
--[[	unlisted = {
		-- enrages were extracted using the script in the /Scripts folder (source is db.mmo-champion.com)
		-- NO LONGER NEEDED BECAUSE I DISCOVERED THE BUG!
		Enraged				= "24689;102989;18499;2687;29131;59465;39575;77238;52262;12292;54508;23257;66092;57733;58942;40076;8599;15061;15716;18501;19451;19812;22428;23128;23342;25503;26041;26051;28371;30485;31540;31915;32714;33958;34670;37605;37648;37975;38046;38166;38664;39031;41254;41447;42705;42745;43139;47399;48138;48142;48193;50420;51513;52470;54427;55285;56646;59697;59707;59828;60075;61369;63227;68541;70371;72143;72146;72147;72148;75998;76100;76862;78722;78943;80084;80467;86736;95436;95459;102134;108169;109889;5229;12880;57514;57518;14201;57516;57519;14202;57520;14203;57521;14204;57522;51170;4146;76816;90872;82033;48702;52537;49029;67233;54781;56729;53361;79420;66759;67657;67658;67659;40601;51662;60177;63848;43292;90045;92946;52071;82759;60430;81772;48391;80158;101109;101110;54475;56769;63147;62071;52610;41364;81021;81022;81016;81017;34392;55462;108566;50636;72203;49016;69052;43664;59694;91668;52461;54356;76691;81706;52309;29340;76487",
	},]]
}

TMW.EventList = {
	{
		name = "OnShow",
		text = L["SOUND_EVENT_ONSHOW"],
		desc = L["SOUND_EVENT_ONSHOW_DESC"],
	},
	{
		name = "OnHide",
		text = L["SOUND_EVENT_ONHIDE"],
		desc = L["SOUND_EVENT_ONHIDE_DESC"],
		settings = {
			OnlyShown = "FORCEDISABLED",
		},
	},
	{
		name = "OnAlphaInc",
		text = L["SOUND_EVENT_ONALPHAINC"],
		desc = L["SOUND_EVENT_ONALPHAINC_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = true,
			PassingCndt = true,
		},
		valueName = L["ALPHA"],
		valueSuffix = "%",
	},
	{
		name = "OnAlphaDec",
		text = L["SOUND_EVENT_ONALPHADEC"],
		desc = L["SOUND_EVENT_ONALPHADEC_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = true,
			PassingCndt = true,
		},
		valueName = L["ALPHA"],
		valueSuffix = "%",
	},
	{
		name = "OnStart",
		text = L["SOUND_EVENT_ONSTART"],
		desc = L["SOUND_EVENT_ONSTART_DESC"],
	},
	{
		name = "OnFinish",
		text = L["SOUND_EVENT_ONFINISH"],
		desc = L["SOUND_EVENT_ONFINISH_DESC"],
	},
	{
		name = "OnSpell",
		text = L["SOUND_EVENT_ONSPELL"],
		desc = L["SOUND_EVENT_ONSPELL_DESC"],
	},
	{
		name = "OnUnit",
		text = L["SOUND_EVENT_ONUNIT"],
		desc = L["SOUND_EVENT_ONUNIT_DESC"],
	},
	{
		name = "OnStack",
		text = L["SOUND_EVENT_ONSTACK"],
		desc = L["SOUND_EVENT_ONSTACK_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = true,
			PassingCndt = true,
		},
		valueName = L["STACKS"]
	},
	{
		name = "OnDuration",
		text = L["SOUND_EVENT_ONDURATION"],
		desc = L["SOUND_EVENT_ONDURATION_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = "FORCE",
			PassingCndt = "FORCE",
		},
		blacklistedOperators = {
			["~="] = true,
			["=="] = true,
		},
		valueName = L["DURATION"]
	},
	{
		name = "OnCLEUEvent",
		text = L["SOUND_EVENT_ONCLEU"],
		desc = L["SOUND_EVENT_ONCLEU_DESC"],
	},
	{
		name = "OnIconShow",
		text = L["SOUND_EVENT_ONICONSHOW"],
		desc = L["SOUND_EVENT_ONICONSHOW_DESC"],
		settings = {
			Icon = true,
		},
	},
	{
		name = "OnIconHide",
		text = L["SOUND_EVENT_ONICONHIDE"],
		desc = L["SOUND_EVENT_ONICONHIDE_DESC"],
		settings = {
			Icon = true,
		},
	},
}

local CompareFuncs = {
	-- harkens back to the days of the conditions of old, but it is more efficient than a big elseif chain.
	["=="] = function(a, b) return a == b  end,
	["~="] = function(a, b)  return a ~= b end,
	[">="] = function(a, b)  return a >= b end,
	["<="] = function(a, b) return a <= b  end,
	["<"] = function(a, b) return a < b  end,
	[">"] = function(a, b) return a > b end,
}


do -- hook LMB
	local meta = LMB and getmetatable(LMB:Group("TellMeWhen")).__index

	if meta and meta.Skin and meta.Disable and meta.Enable then
		local function hook(self)
			if self and self.Addon == "TellMeWhen" then
				TMW:ScheduleUpdate(.2)
			end
		end

		hooksecurefunc(meta, "Skin", hook)
		hooksecurefunc(meta, "Disable", hook)
		hooksecurefunc(meta, "Enable", hook)
		hooksecurefunc(meta, "Update", hook)
		hooksecurefunc(meta, "ReSkin", hook)
	end
end



function TMW:RegisterCallback(event, func, arg1)
	local reg = callbackregistry
	local funcsForEvent
	if reg[event] then
		funcsForEvent = reg[event]
	else
		funcsForEvent = {}
		reg[event] = funcsForEvent
	end

	if type(func) == "table" then
		arg1 = func
		func = func[event]
	end
	arg1 = arg1 or true

	
	local args
	for i = 1, #funcsForEvent do
		local tbl = funcsForEvent[i]
		if tbl.func == func then
			args = tbl
			if not tContains(args, arg1) then
				args[#args + 1] = arg1
			end
			break
		end
	end
	if not args then
		args = {func = func, arg1}
		funcsForEvent[#funcsForEvent + 1] = args
	end
end

function TMW:UnregisterCallback(event, func, arg1)
	local reg = callbackregistry

	if type(func) == "table" then
		arg1 = func
		func = func[event]
	end
	arg1 = arg1 or true

	local funcs = reg[event] and reg[event][func]
	if funcs then
		funcs[arg1] = nil
	end
end

function TMW:Fire(event, ...)
	local funcs = callbackregistry[event]

	if funcs then
		for t = 1, #funcs do
			local tbl = funcs[t]
			local method = tbl.func
			for a = 1, #tbl do
				local arg1 = tbl[a]
				if arg1 ~= true then
					method(arg1, event, ...)
				else
					method(event, ...)
				end
			end
		end
	end
end

function TMW:MakeFunctionCached(obj, method)
    local func
    if type(obj) == "table" and type(method) == "string" then
        func = obj[method]
    elseif type(obj) == "function" then
        func = obj
    else
        error("Usage: TMW:MakeFunctionCached(object/function [, method])")
    end

    local cache = {}
    local wrapper = function(...)
        -- tostringall is a Blizzard function defined in UIParent.lua
		local cachestring = strconcat(tostringall(...))
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

    return wrapper
end



-- --------------------------
-- EXECUTIVE FUNCTIONS, ETC
-- --------------------------

function TMW:OnInitialize()
	if not rawget(Types, "multistate") then
		-- this also includes upgrading from older than 3.0 (pre-Ace3 DB settings)
		StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
			--text = L["ERROR_MISSINGFILE"],
			text = L["ERROR_MISSINGFILE_NOREQ"],
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
		}
		StaticPopup_Show("TMW_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "multistate.lua")
	end

	if LibStub("LibButtonFacade", true) and select(6, GetAddOnInfo("Masque")) == "MISSING" then
		TMW.Warn("TellMeWhen no longer supports ButtonFacade. If you wish to continue to skin your icons, please upgrade to ButtonFacade's successor, Masque.")
	end

	TMW:ProcessEquivalencies()

	--------------- LSM ---------------
	LSM:Register("sound", "Rubber Ducky",  [[Sound\Doodad\Goblin_Lottery_Open01.wav]])
	LSM:Register("sound", "Cartoon FX",	[[Sound\Doodad\Goblin_Lottery_Open03.wav]])
	LSM:Register("sound", "Explosion", 	   [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.wav]])
	LSM:Register("sound", "Shing!", 	   [[Sound\Doodad\PortcullisActive_Closed.wav]])
	LSM:Register("sound", "Wham!", 		   [[Sound\Doodad\PVP_Lordaeron_Door_Open.wav]])
	LSM:Register("sound", "Simon Chime",   [[Sound\Doodad\SimonGame_LargeBlueTree.wav]])
	LSM:Register("sound", "War Drums", 	   [[Sound\Event Sounds\Event_wardrum_ogre.wav]])
	LSM:Register("sound", "Cheer", 		   [[Sound\Event Sounds\OgreEventCheerUnique.wav]])
	LSM:Register("sound", "Humm", 		   [[Sound\Spells\SimonGame_Visual_GameStart.wav]])
	LSM:Register("sound", "Short Circuit", [[Sound\Spells\SimonGame_Visual_BadPress.wav]])
	LSM:Register("sound", "Fel Portal",	[[Sound\Spells\Sunwell_Fel_PortalStand.wav]])
	LSM:Register("sound", "Fel Nova", 	   [[Sound\Spells\SeepingGaseous_Fel_Nova.wav]])
	LSM:Register("sound", "You Will Die!", [[Sound\Creature\CThun\CThunYouWillDie.wav]])

	LSM:Register("sound", "Die!", 		   [[Sound\Creature\GruulTheDragonkiller\GRULLAIR_Gruul_Slay03.wav]])
	LSM:Register("sound", "You Fail!", 	   [[Sound\Creature\Kologarn\UR_Kologarn_slay02.wav]])

	LSM:Register("sound", "TMW - Pling 1", [[Interface\Addons\TellMeWhen\Sounds\Pling1.ogg]])
	LSM:Register("sound", "TMW - Pling 2", [[Interface\Addons\TellMeWhen\Sounds\Pling2.ogg]])
	LSM:Register("sound", "TMW - Pling 3", [[Interface\Addons\TellMeWhen\Sounds\Pling3.ogg]])
	LSM:Register("sound", "TMW - Pling 4", [[Interface\Addons\TellMeWhen\Sounds\Pling4.ogg]])
	LSM:Register("sound", "TMW - Pling 5", [[Interface\Addons\TellMeWhen\Sounds\Pling5.ogg]])
	LSM:Register("sound", "TMW - Pling 6", [[Interface\Addons\TellMeWhen\Sounds\Pling6.ogg]])
	LSM:Register("sound", "TMW - Ding 1",  [[Interface\Addons\TellMeWhen\Sounds\Ding1.ogg]])
	LSM:Register("sound", "TMW - Ding 2",  [[Interface\Addons\TellMeWhen\Sounds\Ding2.ogg]])
	LSM:Register("sound", "TMW - Ding 3",  [[Interface\Addons\TellMeWhen\Sounds\Ding3.ogg]])
	LSM:Register("sound", "TMW - Ding 4",  [[Interface\Addons\TellMeWhen\Sounds\Ding4.ogg]])
	LSM:Register("sound", "TMW - Ding 5",  [[Interface\Addons\TellMeWhen\Sounds\Ding5.ogg]])
	LSM:Register("sound", "TMW - Ding 6",  [[Interface\Addons\TellMeWhen\Sounds\Ding6.ogg]])
	LSM:Register("sound", "TMW - Ding 7",  [[Interface\Addons\TellMeWhen\Sounds\Ding7.ogg]])
	LSM:Register("sound", "TMW - Ding 8",  [[Interface\Addons\TellMeWhen\Sounds\Ding8.ogg]])
	LSM:Register("sound", "TMW - Ding 9",  [[Interface\Addons\TellMeWhen\Sounds\Ding9.ogg]])




	--------------- Database ---------------
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

	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups -- need to define before upgrading
	db.profile.Version = db.profile.Version or TELLMEWHEN_VERSIONNUMBER -- this only does anything for new profiles
	if TellMeWhen_Settings or (type(db.profile.Version) == "string") or (db.profile.Version < TELLMEWHEN_VERSIONNUMBER) then
		TMW:Upgrade()
	end
	db.RegisterCallback(TMW, "OnProfileChanged",	"OnProfile") -- must set callbacks after TMW:Upgrade() because the db is overwritten there when upgrading from 3.0.0
	db.RegisterCallback(TMW, "OnProfileCopied",		"OnProfile")
	db.RegisterCallback(TMW, "OnProfileReset",		"OnProfile")
	db.RegisterCallback(TMW, "OnNewProfile",		"OnProfile")
	db.RegisterCallback(TMW, "OnProfileShutdown",	"ShutdownProfile")
	db.RegisterCallback(TMW, "OnDatabaseShutdown",	"ShutdownProfile")




	--------------- Spell Caches ---------------
	TMW.ClassSpellCache = db.global.ClassSpellCache
	local function AddID(id)
		local name, _, tex = GetSpellInfo(id)
		name = strlowerCache[name]
		if name and not SpellTextures[name] then
			SpellTextures[name] = tex
		end
	end
	for id in pairs(TMW.ClassSpellCache[pclass]) do
		-- do current class spells first to discourage overwrites
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

	TellMeWhenDB.AuraCache = TellMeWhenDB.AuraCache or {}
	TMW.AuraCache = TellMeWhenDB.AuraCache


	--------------- Events/OnUpdate ---------------
	CNDTEnv = TMW.CNDT.Env
	TMW:SetScript("OnUpdate", TMW.OnUpdate)

	TMW:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	TMW:RegisterEvent("PLAYER_ENTERING_WORLD")
	TMW:RegisterEvent("PLAYER_TALENT_UPDATE")
	TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")


	--------------- Comm ---------------
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
				t.wasPassingCondition = nil
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
	if prefix == "TMWV" and strsub(text, 1, 1) == "M" and not TMW.VersionWarned and db.global.VersionWarning then
		local major, minor, revision = strmatch(text, "M:(.*)%^m:(.*)%^R:(.*)%^")
		TMW:Debug(prefix, who, major, minor, revision)
		revision = tonumber(revision)
		if not (revision and major and minor and revision > TELLMEWHEN_VERSIONNUMBER and revision ~= 414069) then
			return
		elseif not ((minor == "" and who ~= "Cybeloras") or (tonumber(strsub(revision, 1, 3)) > tonumber(strsub(TELLMEWHEN_VERSIONNUMBER, 1, 3)) + 1)) then
			return
		end
		TMW.VersionWarned = true
		TMW:Printf(L["NEWVERSION"], major .. minor)
	elseif prefix == "TMW" and db.profile.ReceiveComm then
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


function TMW:OnUpdate(elapsed)					-- THE MAGICAL ENGINE OF DOING EVERYTHING
	time = GetTime()
	CNDTEnv.time = time
	TMW.time = time

	if LastUpdate <= time - UPD_INTV then
		LastUpdate = time
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


		if Locked then

			for i = 1, #GroupsToUpdate do
				-- GroupsToUpdate only contains groups with conditions
				local group = GroupsToUpdate[i]
				local ConditionObj = group.ConditionObj
				if ConditionObj then
					if ConditionObj.UpdateNeeded or ConditionObj.NextUpdateTime < time then
						ConditionObj:Check(group)
					end
					if ConditionObj.Failed then
						if group.__shown then
							group:Hide()
						end
					else
						if not group.__shown then
							group:Show()
						end
					end
				end
			end

			for i = 1, #IconsToUpdate do
				--local icon = IconsToUpdate[i]
				IconsToUpdate[i]:Update()
			end

			if updatePBars then
				for i = 1, #PBarsToUpdate do
					local pbar = PBarsToUpdate[i]
					pbar:SetSpell(pbar.spell) -- force an update
				end
				updatePBars = nil
			end
			
			for g = 1, #TMW do
				local group = TMW[g]
				if group.shouldSortIcons and group.iconSortNeeded then
					group:SortIcons()
					group.iconSortNeeded = nil
				end
			end
		end
	end

	if BindTextObjsToUpdate and LastBindTextUpdate <= time - 0.1 then
		LastBindTextUpdate = time
		for i = 1, #BindTextObjsToUpdate do
			BindTextObjsToUpdate[i]:Update()
		end
	end

	local cbaroffs = 0
	for i = 1, #CBarsToUpdate do
		local cbar = CBarsToUpdate[i + cbaroffs]
		cbaroffs = cbaroffs + cbar:Update()
	end

	if ActiveAnimations then
		for animatedObject, animations in next, ActiveAnimations do
			for _, animationTable in next, animations do
				-- its the magical modular tour, and its coming to take you awayyy......

				if animationTable.HALTED then
					animatedObject:Animations_Stop(animationTable)
				else
					AnimationList[animationTable.Animation].OnUpdate(animatedObject, animationTable)
				end
			end
		end
	end
end




function TMW:Update()
	if not TMW.EnteredWorld then return end

	time = GetTime() TMW.time = time
	LastUpdate = time - 10
	updatePBars = 1

	Locked = db.profile.Locked

	if not Locked then
		TMW:LoadOptions()
	end

	TMW:Fire("TMW_GLOBAL_UPDATE") -- the placement of this matters. Must be after options load, but before icons are updated

	UPD_INTV = db.profile.Interval + 0.001 -- add a very small amount so that we don't call the same icon multiple times (through metas/conditionicons) in the same frame if the interval has been set 0
	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups

	BarGCD = db.profile.BarGCD
	ClockGCD = db.profile.ClockGCD
	ColorMSQ = db.profile.ColorMSQ
	OnlyMSQ = db.profile.OnlyMSQ
	SndChan = db.profile.MasterSound and "Master" or nil


	BindTextObjsToUpdate = nil

	for key, Type in pairs(TMW.Types) do
		wipe(Type.Icons)
		Type:Update()
		Type:UpdateColors(true)
	end

	for groupID = 1, max(TELLMEWHEN_MAXGROUPS, #TMW) do
		-- cant use TMW.InGroups() because groups wont exist yet on the first call of this, so they would never be able to exists
		-- even if it shouldn't be setup (i.e. it has been deleted or the user changed profiles)
		local group = TMW[groupID] or TMW.Classes.Group:New("Frame", "TellMeWhen_Group" .. groupID, TMW, "TellMeWhen_GroupTemplate", groupID)
		group:Setup()
	end

	for key, Type in pairs(TMW.Types) do
		Type:Update(true)
	end

	if not Locked then
		TMW:DoValidityCheck()
	end

	TMW:ScheduleTimer("ForceUpdatePBars", 0.55)
	TMW:ScheduleTimer("ForceUpdatePBars", 1)
	TMW:ScheduleTimer("ForceUpdatePBars", 2)
	
	TMW:ScheduleTimer("DoWarn", 3)
end

function TMW:DoWarn()
	if not TMW.Warned then
		for k, v in ipairs(TMW.Warn) do
			TMW:Print(v)
			TMW.Warn[k] = true
		end
		TMW.Warned = true
	end
end

function TMW:GetUpgradeTable()			-- upgrade functions
	if TMW.UpgradeTable then return TMW.UpgradeTable end
	local t = {

		[48025] = {
			icon = function(ics)
				ics.Name = gsub(ics.Name, "(CrowdControl)", "%1; " .. GetSpellInfo(339))
			end,
		},
		[48017] = {
			icon = function(ics)
				-- convert from some stupid string thing i made up to a bitfield
				if type(ics.TotemSlots) == "string" then
					ics.TotemSlots = tonumber(ics.TotemSlots:reverse(), 2)
				end
			end,
		},
		[48010] = {
			icon = function(ics)
				-- OnlyShown was disabled for OnHide (not togglable anymore), so make sure that icons dont get stuck with it enabled
				local OnHide = rawget(ics.Events, "OnHide")
				if OnHide then
					OnHide.OnlyShown = false
				end
			end,
		},
		[47321] = {
			icon = function(ics)
				ics.Events["**"] = nil -- wtf?
			end,
		},
		[47320] = {
			icon = function(ics)
				for k, Event in pairs(ics.Events) do
					-- these numbers got really screwy (0.8000000119), put then back to what they should be (0.8)
					Event.Duration 	= Event.Duration  and tonumber(format("%0.1f",	Event.Duration))
					Event.Magnitude = Event.Magnitude and tonumber(format("%1f",	Event.Magnitude))
					Event.Period  	= Event.Period    and tonumber(format("%0.1f",	Event.Period))
				end
			end,
		},
		[47204] = {
			icon = function(ics)
				if ics.Type == "conditionicon"  then
					ics.CustomTex = ics.Name or ""
					ics.Name = ""
				end
			end,
		},
		[47017] = {
			icon = function(ics)
				if ics.Type == "meta"  then
					ics.FakeHidden = false
				end
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
			global = function(self)
				for newKey, oldKey in pairs(self.map) do
					local old = db.profile[oldKey]
					local new = db.profile.Colors.GLOBAL[newKey]

					if old then
						for k, v in pairs(old) do
							new[k] = v
						end

						db.profile[oldKey] = nil
					end
				end

			end,
		},
		[46604] = {
			icon = function(ics)
				if ics.CooldownType == "multistate" and ics.Type == "cooldown" then
					ics.Type = "multistate"
					ics.CooldownType = TMW.Icon_Defaults.CooldownType
				end
			end,
		},
		[46418] = {
			global = function()
				db.global.HelpSettings.ResetCount = nil
			end,
		},
		[46417] = {
			-- cant use the conditions key here because it depends on Conditions.n, which is 0 until this is ran
			-- also, dont use TMW:InConditions because it will use conditions.n, which is 0 until the upgrade is complete
			group = function(gs)
				local n = 0
				for k in pairs(gs.Conditions) do
					if type(k) == "number" then
						n = max(n, k)
					end
				end
				gs.Conditions.n = n
			end,
			icon = function(ics)
				local n = 0
				for k in pairs(ics.Conditions) do
					if type(k) == "number" then
						n = max(n, k)
					end
				end
				ics.Conditions.n = n
			end,
		},
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
				for k, condition in TMW:InConditions(ics.Conditions) do
					if type(k) == "number" and condition.Type == "CASTING" then
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
					ics.UnAlpha = ics.ConditionAlpha or 0
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
				for k, condition in pairs(ics.Conditions) do
					if type(k) == "number" then
						for k in pairs(condition) do
							if strfind(k, "Condition") then
								condition[k] = nil
							end
						end
						condition.Names = nil
					end
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
				Events.OnShow.Sound = ics.SoundOnShow or "None"
				Events.OnShow.Announce = ics.ANNOnShow or "\001"

				Events.OnHide.Sound = ics.SoundOnHide or "None"
				Events.OnHide.Announce = ics.ANNOnHide or "\001"

				Events.OnStart.Sound = ics.SoundOnStart or "None"
				Events.OnStart.Announce = ics.ANNOnStart or "\001"

				Events.OnFinish.Sound = ics.SoundOnFinish or "None"
				Events.OnFinish.Announce = ics.ANNOnFinish or "\001"

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
					if type(k) == "number" and condition.Type == "STANCE" then
						condition.Operator = "=="
					end
				end
			end,
		},
		[41008] = {
			icon = function(ics)
				for k, condition in pairs(ics.Conditions) do
					if type(k) == "number" then
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
					if type(k) == "number" then
						if condition.Type == "BUFF" then
							condition.Type = "BUFFSTACKS"
						elseif condition.Type == "DEBUFF" then
							condition.Type = "DEBUFFSTACKS"
						end
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
					if type(k) == "number" and (condition.Type == "BUFF" or condition.Type == "DEBUFF") then
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
					if type(k) == "number" and condition.Type == "CASTING" then
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
					if type(k) == "number" and condition.Type == "ITEMINBAGS" then
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
					if type(k) == "number" and condition.Type == "NAME" then
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
					if type(k) == "number" and v.Type == "ECLIPSE_DIRECTION" and v.Level == -1 then
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
						if TMW.CSN[k] then
							if v then -- everything switched in this version
								gs.Stance[TMW.CSN[k]] = false
							else
								gs.Stance[TMW.CSN[k]] = true
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
			icon = function(ics, self, groupID, iconID)
				for k in pairs(self.iconSettingsToClear) do
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
				for k, condition in ipairs(ics.Conditions) do
					if type(k) == "number" then
						for k, v in pairs(condition) do
							condition[k] = nil
							condition[k:gsub("Condition", "")] = v
						end
					end
				end
			end,
		},
		[22000] = {
			icon = function(ics)
				for k, v in ipairs(ics.Conditions) do
					if type(k) == "number" and ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
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
					if type(k) == "number" and ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
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

	TMW.UpgradeTable = {}
	for k, v in pairs(t) do
		v.Version = k
		tinsert(TMW.UpgradeTable, v)
	end
	sort(TMW.UpgradeTable, function(a, b)
		if a.priority or b.priority then
			if a.priority and b.priority then
				return a.priority < b.priority
			else
				return a.priority
			end
		end
		return a.Version < b.Version
	end)
	return TMW.UpgradeTable
end

function TMW:GlobalUpgrade()
	TellMeWhenDB.Version = TellMeWhenDB.Version or 0
	if TellMeWhenDB.Version == 414069 then TellMeWhenDB.Version = 41409 end --well, that was a mighty fine fail
	-- Begin DB upgrades that need to be done before defaults are added.
	-- Upgrades here should always do everything needed to every single profile,
	-- and remember to make sure that a table exists before going into it.

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
		if TellMeWhenDB.Version < 46413 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Groups then
					for _, gs in pairs(p.Groups) do
						if gs.Conditions then
							for k, Condition in pairs(gs.Conditions) do
								if type(k) == "number" and Condition.Type == nil then
									Condition.Type = "HEALTH"
								end
							end
						end
						if gs.Icons then
							for _, ics in pairs(gs.Icons) do
								if ics.Conditions then
									for k, Condition in pairs(ics.Conditions) do
										if type(k) == "number" and Condition.Type == nil then
											Condition.Type = "HEALTH"
										end
									end
								end
							end
						end
					end
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
	end
	TellMeWhenDB.Version = TELLMEWHEN_VERSIONNUMBER -- pre-default upgrades complete!
end

function TMW:Error(text, ...)
	text = text or ""
	text = format(text, ...)
	geterrorhandler()("TellMeWhen: " .. (text))
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
				-- upgrade global settings
				v.global(v)

			elseif groupID and not iconID and v.group then
				-- upgrade group settings
				v.group(db.profile.Groups[groupID], v, groupID)

				-- upgrade group conditions
				if v.condition then
					for condition, conditionID in TMW:InConditions(db.profile.Groups[groupID].Conditions) do
						v.condition(condition, v, conditionID, groupID)
					end
				end

			elseif iconID and groupID and v.icon then
				-- upgrade icon settings
				v.icon(db.profile.Groups[groupID].Icons[iconID], v, groupID, iconID)

				-- upgrade icon conditions
				if v.condition then
					for condition, conditionID in TMW:InConditions(db.profile.Groups[groupID].Icons[iconID].Conditions) do
						v.condition(condition, v, conditionID, groupID, iconID)
					end
				end
			end

			if global and v.postglobal then
				-- upgrade global things that should come after everything else
				v.postglobal(v)

			end
		end
	end

	if global then
		-- delegate upgrades to all groups
		for gs, groupID in TMW:InGroupSettings() do
			TMW:DoUpgrade(version, nil, groupID, nil)
		end

	elseif groupID and not iconID then
		-- delegate upgrades to all icons
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
			TMW:Error(err) -- non breaking error
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

TMW.ValidityCheckQueue = {}
function TMW:QueueValidityCheck(icon, groupID, iconID, g, i)
	if not db.profile.WarnInvalids then return end

	local str = icon .. "^" .. groupID .. "^" .. (iconID or "nil") .. "^" .. g .. "^" .. i

	TMW.ValidityCheckQueue[str] = 1
end

function TMW:DoValidityCheck()
	for str in ipairs(TMW.ValidityCheckQueue) do
		local icon, groupID, iconID, g, i = strsplit("^", str)
		if not (icon and icon:IsValid()) then
			if iconID ~= "nil" then
				TMW.Warn(format(L["CONDITIONORMETA_CHECKINGINVALID"], groupID, iconID, g, i))
			else
				TMW.Warn(format(L["CONDITIONORMETA_CHECKINGINVALID_GROUP"], groupID, g, i))
			end
		end
	end
	wipe(TMW.ValidityCheckQueue)
end

function TMW:RestoreEvents()
	runEvents = 1
end

function TMW.OnGCD(d)
	if d == 1 then return true end -- a cd of 1 is always a GCD (or at least isn't worth showing)
	if GCD > 1.7 then return false end -- weed out a cooldown on the GCD spell that might be an interupt (counterspell, mind freeze, etc)
	return GCD == d and d > 0 -- if the duration passed in is the same as the GCD spell, and the duration isnt zero, then it is a GCD
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

function TMW:COMBAT_LOG_EVENT_UNFILTERED(_, _, p,_, g, _, f, _, _, _, _, _, i)
	-- This is only used for the suggester, but i want to to be listening all the times for auras, not just when you load the options
	if p == "SPELL_AURA_APPLIED" and not TMW.AuraCache[i] then
		if --[[bitband(f, CL_PLAYER) == CL_PLAYER or]] bitband(f, CL_CONTROL_PLAYER) == CL_CONTROL_PLAYER then -- player or player-controlled unit
			TMW.AuraCache[i] = 2
		else
			TMW.AuraCache[i] = 1
		end
	end
end

function TMW:SPELL_UPDATE_USABLE()
	updatePBars = 1
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

function TMW:UNIT_POWER_FREQUENT(event, unit, powerType)
	-- powerType is an event arg
	-- powerTypeNum is a manual update arg
	if unit == "player" then
		-- these may be nil if coming from a manual update. in that case, they will be determined by the bar's settings and attributes
		local powerTypeNum = powerType and _G["SPELL_POWER_" .. powerType]
		local power = powerTypeNum and UnitPower("player", powerTypeNum)
		
		for i = 1, #PBarsToUpdate do
			local pbar = PBarsToUpdate[i]
			pbar:Update(power, powerTypeNum)
		end
	end
end

function TMW:ForceUpdatePBars()
	TMW:UNIT_POWER_FREQUENT("UNIT_POWER_FREQUENT", "player")
end

function TMW:IterateAllModules(callback, arg1, ...)
    -- callback can be a funcref or a method of Module
    -- arg1 to callback will be Module if set to "%MODULE" or if nil, otherwise it will be literal. You should probably set it to %MODULE% if callback is a method name
    -- arg2, argN are everything in the vararg.
    assert(callback, "NO CALLBACK TO CALL!")

	if self == TMW then
		-- iterate icon types (but only once, since this func is recursive
		for name, Type in pairs(TMW.Types) do
			local firstArg = arg1
			if arg1 == "%MODULE%" or not arg1 then
				firstArg = Type
			end

			local callbackfunc = callback

			if type(callbackfunc) == "string" then
				callbackfunc = Type[callbackfunc]
			end

			local arg2 = ...
			if type(arg2) == "table" and arg2.class == TMW.Classes.Icon and arg2:GetSettings().Type ~= name then
				callbackfunc = nil
			end

			if callbackfunc then
				local success, err = pcall(callbackfunc, firstArg, ...)
				if not success then
					TMW:Error(err)
				end
			end
		end
	end

    for _, Module in self:IterateModules() do
        local firstArg = arg1
        if arg1 == "%MODULE%" or not arg1 then
            firstArg = Module
        end

		local callbackfunc = callback

        if type(callbackfunc) == "string" then
            callbackfunc = Module[callbackfunc]
        end

		if callbackfunc then
			local success, err = pcall(callbackfunc, firstArg, ...)
			if not success then
				TMW:Error(err)
			end
		end

        TMW.IterateAllModules(Module, callback, arg1, ...) -- iterate the sub-modules
    end
end

function TMW:ProcessEquivalencies()
	for dispeltype, icon in pairs(TMW.DS) do
	--	SpellTextures[dispeltype] = icon
		SpellTextures[strlower(dispeltype)] = icon
	end

	if DRData then
		local myCategories = {
			ctrlstun   = "DR-ControlledStun",
			scatters   = "DR-Scatter",
			fear 	   = "DR-Fear",
			rndstun	= "DR-RandomStun",
			silence	= "DR-Silence",
			banish 	   = "DR-Banish",
			mc 		   = "DR-MindControl",
			entrapment = "DR-Entrapment",
			taunt 	   = "DR-Taunt",
			disarm 	   = "DR-Disarm",
			horror 	   = "DR-Horrify",
			cyclone	= "DR-Cyclone",
			rndroot	= "DR-RandomRoot",
			disorient  = "DR-Disorient",
			ctrlroot   = "DR-ControlledRoot",
			dragons	= "DR-DragonsBreath",
		}
		if not GetSpellInfo(74347) then -- invalid
			DRData.spells[74347] = nil
		end
		local dr = TMW.BE.dr
		for spellID, category in pairs(DRData.spells) do
			local k = myCategories[category] or TMW:Error("TMW: The DR category %q is undefined!", category)
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
				local realID = tonumber(strmatch(str, "_(%d+)"))
				if id then
					local name, _, tex = GetSpellInfo(strtrim(id, " _"))
					if name then
						TMW:LowerNames(name) -- this will insert the spell name into the table of spells for capitalization restoration.
						str = gsub(str, id, name)
						SpellTextures[realID] = tex
						SpellTextures[strlowerCache[name]] = tex

					else  -- this should never ever ever happen except in new patches if spellIDs were wrong (experience talking)
						if clientVersion >= addonVersion then -- dont warn for old clients using newer versions
							TMW:Error("Invalid spellID found: %s! Please report this on TMW's CurseForge page, especially if you are currently on the PTR!", realID)
						end
						str = gsub(str, id, realID) -- still need to substitute it to prevent recusion
					end
				end
			end
			TMW.BE[category][equiv] = str
		end
	end
end


local BindTextObj = TMW:NewClass("BindTextObj")

function BindTextObj:OnNewInstance(icon, FontObject)
	self.icon = icon
	self.FontObject = FontObject
	self.usedSubstitutions = {}
end

function BindTextObj:SetBaseString(string)
	self.baseString = string
	self.hasDuration = strfind(string, "%%[Dd]")
	self.hasAnySubstitutions = nil
	wipe(self.usedSubstitutions)
	
	-- tfmpusdkeox is every letter currently used for substitutions
	for letter in gmatch("tfmpusdkeox", "(.)") do
		if strfind(string, "%%[" .. letter:upper() .. letter .. "]") then
			self.usedSubstitutions[letter] = true
			self.hasAnySubstitutions = true
		end
	end
	
	if BindTextObjsToUpdate then
		tDeleteItem(BindTextObjsToUpdate, self, true)
	end	
	if self.hasDuration then
		BindTextObjsToUpdate = BindTextObjsToUpdate or {}
		tinsert(BindTextObjsToUpdate, self)
	end
	
	self:UpdateNonDurationSubstitutions()
end

function BindTextObj:UpdateNonDurationSubstitutions()
	self.stringWithoutDuration = TMW:InjectDataIntoString(self.baseString, self.icon, true, true, true)
	self:Update(1)
end

function BindTextObj:Update(forceDurationUpdate)
	local Text = self.stringWithoutDuration
	
	if self.hasDuration then
		local icon = self.icon
		local duration = icon.__duration - (time - icon.__start)
		if duration < 0 then
			duration = 0
		end
		if duration ~= self.lastDuration or forceDurationUpdate then
			Text = gsub(Text, "%%[Dd]", TMW:FormatSeconds(duration, duration == 0 or duration > 10, true))
			self.stringWithDuration = Text
		else
			Text = self.stringWithDuration
		end
	end
	
	if self.__currentText ~= Text then
		self.FontObject:SetText(Text)
		self.__currentText = Text
	end
end

function TMW:InjectDataIntoString(Text, icon, doBlizz, shouldColorNames, dontSubDuration, doInsertLink)
	if not Text then return Text end
	doInsertLink = doInsertLink or db.profile.AlwaysSubLinks

	--CURRENTLY USED: t, f, m, p, u, s, d, k, e, o, x

	if doBlizz then
		if strfind(Text, "%%[Tt]") then
			Text = gsub(Text, "%%[Tt]", NAMES:TryToAcquireName("target", shouldColorNames) or TARGET_TOKEN_NOT_FOUND)
			--Text = gsub(Text, "%%[Tt]", UnitName("target") or TARGET_TOKEN_NOT_FOUND)
		end
		if strfind(Text, "%%[Ff]") then
			Text = gsub(Text, "%%[Ff]", NAMES:TryToAcquireName("focus", shouldColorNames) or FOCUS_TOKEN_NOT_FOUND)
		--	Text = gsub(Text, "%%[Ff]", UnitName("focus") or FOCUS_TOKEN_NOT_FOUND)
		end
	end

	if strfind(Text, "%%[Mm]") then
		Text = gsub(Text, "%%[Mm]", NAMES:TryToAcquireName("mouseover", shouldColorNames) or L["MOUSEOVER_TOKEN_NOT_FOUND"])
	--	Text = gsub(Text, "%%[Mm]", UnitName("mouseover") or L["MOUSEOVER_TOKEN_NOT_FOUND"])
	end

	if icon then

		if icon.Type == "cleu" then
			if strfind(Text, "%%[Oo]") then
				Text = gsub(Text, "%%[Oo]", NAMES:TryToAcquireName(icon.cleu_sourceUnit, shouldColorNames) or "?")
			end
			if strfind(Text, "%%[Ee]") then
				Text = gsub(Text, "%%[Ee]", NAMES:TryToAcquireName(icon.cleu_destUnit, shouldColorNames) or "?")
			--	Text = gsub(Text, "%%[Ee]", UnitName(icon.cleu_destUnit or "") or icon.cleu_destUnit or "?")
			end
			if strfind(Text, "%%[Xx]") then
				local name, checkcase = icon.typeData:GetNameForDisplay(icon, icon.cleu_extraSpell, doInsertLink)
				name = name or "?"
				if checkcase then
					name = TMW:RestoreCase(name)
				end
				Text = gsub(Text, "%%[Xx]", name)
			end
		end

		if strfind(Text, "%%[Pp]") then
			Text = gsub(Text, "%%[Pp]", NAMES:TryToAcquireName(icon.__lastUnitName or icon.__lastUnitChecked, shouldColorNames) or "?")
		--	Text = gsub(Text, "%%[Pp]", icon.__lastUnitName or UnitName(icon.__lastUnitChecked or "") or "?")
		end
		if strfind(Text, "%%[Uu]") then
			Text = gsub(Text, "%%[Uu]", NAMES:TryToAcquireName(icon.__unitName or icon.__unitChecked, shouldColorNames) or "?")
		--	Text = gsub(Text, "%%[Uu]", icon.__unitName or UnitName(icon.__unitChecked or "") or icon.__unitChecked or "?")
		end

		if strfind(Text, "%%[Ss]") then
			local name, checkcase = icon.typeData:GetNameForDisplay(icon, icon.__spellChecked, doInsertLink)
			name = name or "?"
			if checkcase then
				name = TMW:RestoreCase(name)
			end
			Text = gsub(Text, "%%[Ss]", name)
		end
		if not dontSubDuration and strfind(Text, "%%[Dd]") then
			local duration = icon.__duration - (time - icon.__start)
			if duration < 0 then
				duration = 0
			end
			Text = gsub(Text, "%%[Dd]", TMW:FormatSeconds(duration, duration == 0 or duration > 10, true))
		end
		if strfind(Text, "%%[Kk]") then
			local count = icon.__countText or icon.__count
			if count then
				count = gsub(count, "%%", "%%%%")
			else
				count = ""
			end
			Text = gsub(Text, "%%[Kk]", count)
		end
	end

	return Text
end



local Display = TMW:NewClass("Display")

function Display:OnNewInstance(name)
	self.name = name
	
	self.Group = TMW:NewClass("Group_" .. name, "GroupParent")
	self.Icon = TMW:NewClass("Icon_" .. name, "IconParent")
end



NAMES = TMW:NewModule("Names", "AceEvent-3.0") TMW.NAMES = NAMES
NAMES.ClassColors = {}
NAMES.ClassColoredNameCache = {}

function NAMES:OnInitialize()
	local unitList = {"player"}
	NAMES.unitList = unitList

	local function addids(uid,lower,upper, append)
		if lower and upper then
			for i=lower,upper do
				unitList[#unitList+1] = uid..i..(append or "")
			end
		else
			unitList[#unitList+1] = uid..(append or "")
		end
	end

	addids("mouseover")

	addids("target")
	addids("targettarget")
	addids("targettargettarget")

	addids("pet")
	addids("pettarget")
	addids("pettargettarget")

	addids("focus")
	addids("focustarget")
	addids("focustargettarget")

	addids("arena",1,5)
	addids("boss",1,5)
	addids("party",1,4)
	addids("party",1,4,"pet")
	addids("raid",1,40)

	addids("arena",1,5,"target")
	addids("boss",1,5,"target")
	addids("party",1,4,"target")
	addids("party",1,4,"pettarget")
	addids("raid",1,40,"target")

	addids("arena",1,5,"targettarget")
	addids("boss",1,5,"targettarget")
	addids("party",1,4,"targettarget")
	addids("party",1,4,"pettargettarget")
	addids("raid",1,40,"targettarget")

	addids = nil -- into the garbage you go!

	NAMES:UpdateClassColors()

	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback(NAMES, "UpdateClassColors")
	end
	NAMES:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
	NAMES:RegisterEvent("UPDATE_WORLD_STATES", "UPDATE_BATTLEFIELD_SCORE")
	NAMES:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function NAMES:UPDATE_BATTLEFIELD_SCORE()
	for i = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, _, _, _, class = GetBattlefieldScore(i)

		NAMES.ClassColoredNameCache[name] = NAMES.ClassColors[class] .. name .. "|r"
	end
end

function NAMES:UPDATE_MOUSEOVER_UNIT()
	local name, server = UnitName("mouseover")
	if not name then return end
	if server then
		name = name .. "-" .. server
	end
	local _, class = UnitClass("mouseover")

	NAMES.ClassColoredNameCache[name] = NAMES.ClassColors[class] .. name .. "|r"
end

function NAMES:UpdateClassColors()
	for class,color in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
		NAMES.ClassColors[class] = ("|cff%02x%02x%02x"):format(color.r * 255, color.g * 255, color.b * 255)
	end
end


function NAMES:GetUnitIDFromGUID(srcGUID)
	local unitList = NAMES.unitList
	for i = 1, #unitList do
		local id = unitList[i]
		if UnitGUID(id) == srcGUID then
			return id
		end
	end
end

function NAMES:GetUnitIDFromName(name)
	local unitList = NAMES.unitList
	name = strlowerCache[name]
	for i = 1, #unitList do
		local id = unitList[i]
		local nameGuess, serverGuess = UnitName(id)
		if (serverGuess and strlowerCache[nameGuess .. "-" .. serverGuess] == name) or strlowerCache[nameGuess] == name then
			return id
		end
	end
end

function NAMES:TryToAcquireName(input, shouldColor)
	if not input then return end

	shouldColor = shouldColor and db.profile.ColorNames

	local name, server = UnitName(input or "")

	if name then	-- input was a unitID if name was obtained.
		if server and server ~= "" then
			name = name .. "-" .. server
		end
		if shouldColor then
			local _, class = UnitClass(input)
			local nameColored = (NAMES.ClassColors[class] or "") .. name .. "|r"

			NAMES.ClassColoredNameCache[name] = nameColored

			name = nameColored
		end
	else			-- input was a name.
		name = input

		if shouldColor and NAMES.ClassColoredNameCache[name] then
			return NAMES.ClassColoredNameCache[name]
		end

		local unit = NAMES:GetUnitIDFromName(input)
		if unit then
			if shouldColor then
				local _, class = UnitClass(unit)
				local nameColored = NAMES.ClassColors[class] .. name .. "|r"

				NAMES.ClassColoredNameCache[name] = nameColored

				name = nameColored
			else
				name, server = UnitName(unit)
				if server and server ~= "" then
					name = name .. "-" .. server
				end
			end
		end
	end

	return name
end



EVENTS = TMW:NewModule("Events", "AceEvent-3.0") TMW.EVENTS = EVENTS
function EVENTS:ProcessAndDelegateIconEventSettings(icon, event, eventSettings)

	local success = self:ProcessIconEventSettings(icon, event, eventSettings)

	if success and (event == "OnIconShow" or event == "OnIconHide") then
		EVENTS.iconsToHandleOnIconShowHide = EVENTS.iconsToHandleOnIconShowHide or {}
		EVENTS.iconsToHandleOnIconShowHide[icon] = icon.Enabled and true or nil
		TMW:RegisterCallback("TMW_ICON_SHOWN_CHANGED", EVENTS) -- register to EVENTS, not self.
	end

	return success
end
function EVENTS:TMW_ICON_SHOWN_CHANGED(_, ic, event)
	if Locked then
		-- ic is the icon that changed, icon is the icon that might be handling it
		--local event = (ic.__alpha or ic:GetAlpha()) > 0 and "OnIconShow" or "OnIconHide"
		local icName = ic:GetName()

		for icon in next, self.iconsToHandleOnIconShowHide do
			if icon[event] and icon[event].Icon == icName then
				icon:QueueEvent(event)
				icon:ProcessQueuedEvents()
			end
		end
	end
end

SND = EVENTS:NewModule("Sound", EVENTS) TMW.SND = SND
function SND:ProcessIconEventSettings(icon, event, eventSettings)
	local data = eventSettings.Sound
	if data == "" or data == "Interface\\Quiet.ogg" or data == "None" then
		eventSettings.SoundData = nil
	elseif strfind(data, "%.[^\\]+$") then
		eventSettings.SoundData = data
		return true
	else
		local s = LSM:Fetch("sound", data)
		if s and s ~= "Interface\\Quiet.ogg" and s ~= "" then
			eventSettings.SoundData = s
			return true
		else
			eventSettings.SoundData = nil
		end
	end
end
function SND:HandleEvent(icon, data)
	local Sound = data.SoundData
	if Sound then
		PlaySoundFile(Sound, SndChan)
		return true
	end
end


ANN = EVENTS:NewModule("Announcements", EVENTS) TMW.ANN = ANN
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
		isBlizz = 1, -- flagged to not use override %t and %f substitutions, and also not to try and color any names
		handler = function(icon, data, Text)
			local channel = "SAY"
			if UnitInBattleground("player") then
				channel = "BATTLEGROUND"
			elseif UnitInRaid("player") then
				channel = "RAID"
			elseif GetNumPartyMembers() > 1 then
				channel = "PARTY"
			end
			SendChatMessage(Text, channel)
		end,
	},
	{
		text = L["CHAT_MSG_CHANNEL"],
		desc = L["CHAT_MSG_CHANNEL_DESC"],
		channel = "CHANNEL",
		isBlizz = 1, -- flagged to not use override %t and %f substitutions, and also not to try and color any names
		defaultlocation = function() return select(2, GetChannelList()) end,
		dropdown = function()
			for i = 1, huge, 2 do
				local num, name = select(i, GetChannelList())
				if not num then break end

				local info = UIDropDownMenu_CreateInfo()
				info.func = TMW.ANN.LocDropdownFunc
				info.text = name
				info.arg1 = name
				info.value = name
				info.checked = name == TMW.ANN:GetEventSettings().Location
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end,
		ddtext = function(value)
			-- also a verification function
			for i = 1, huge, 2 do
				local num, name = select(i, GetChannelList())
				if not num then return end

				if name == value then
					return value
				end
			end
		end,
		handler = function(icon, data, Text)
			for i = 1, huge, 2 do
				local num, name = select(i, GetChannelList())
				if not num then break end
				if strlowerCache[name] == strlowerCache[data.Location] then
					SendChatMessage(Text, data.Channel, nil, num)
					break
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

			local name = "RaidWarningFrame"
			local info = UIDropDownMenu_CreateInfo()
			info.func = TMW.ANN.LocDropdownFunc
			info.text = L[name]
			info.arg1 = L[name]
			info.value = name
			info.checked = name == TMW.ANN:GetEventSettings().Location
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

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
					info.checked = name == TMW.ANN:GetEventSettings().Location
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
				i = i + 1
			end
		end,
		ddtext = function(value)
			-- also a verification function
			if value == "RaidWarningFrame" then
				return L[value]
			end

			local i = 1
			while _G["ChatFrame"..i] do
				if _G["ChatFrame"..i].name == value then
					return value
				end
				i = i + 1
			end
		end,
		handler = function(icon, data, Text)
			local Location = data.Location

			if data.Icon then
				Text = "|T" .. (icon.__tex or "") .. ":0|t " .. Text
			end

			if _G[Location] == RaidWarningFrame then
				-- workaround: blizzard's code doesnt manage colors correctly when there are 2 messages being displayed with different colors.
				Text = ("|cff%02x%02x%02x"):format(data.r * 255, data.g * 255, data.b * 255) .. Text .. "|r"

				RaidNotice_AddMessage(RaidWarningFrame, Text, bullshitTable) -- arg3 still demands a valid table for the color info, even if it is empty
			else
				local i = 1
				while _G["ChatFrame"..i] do
					local frame = _G["ChatFrame"..i]
					if Location == frame.name then
						frame:AddMessage(Text, data.r, data.g, data.b, 1)
						break
					end
					i = i+1
				end
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
			for id, name in pairs(TMW.ChannelList.SCT.frames) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = TMW.ANN.LocDropdownFunc
				info.text = name
				info.arg1 = info.text
				info.value = id
				info.checked = id == TMW.ANN:GetEventSettings().Location
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end,
		ddtext = function(value)
			if not SCT then return end
			return TMW.ChannelList.SCT.frames[value]
		end,
		handler = function(icon, data, Text)
			if SCT then
				sctcolor.r, sctcolor.g, sctcolor.b = data.r, data.g, data.b
				SCT:DisplayCustomEvent(Text, sctcolor, data.Sticky, data.Location, nil, data.Icon and icon.__tex)
			end
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
				info.checked = scrollAreaKey == TMW.ANN:GetEventSettings().Location
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
		handler = function(icon, data, Text)
			if MikSBT then
				local Size = data.Size
				if Size == 0 then Size = nil end
				MikSBT.DisplayMessage(Text, data.Location, data.Sticky, data.r*255, data.g*255, data.b*255, Size, nil, data.Icon and icon.__tex)
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
				info.checked = k == TMW.ANN:GetEventSettings().Location
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end,
		ddtext = function(value)
			if value then
				return (Parrot.GetScrollAreasChoices and Parrot:GetScrollAreasChoices() or Parrot:GetScrollAreasValidate())[value]
			end
		end,
		handler = function(icon, data, Text)
			if Parrot then
				local Size = data.Size
				if Size == 0 then Size = nil end
				Parrot:ShowMessage(Text, data.Location, data.Sticky, data.r, data.g, data.b, nil, Size, nil, data.Icon and icon.__tex)
			end
		end,
	},
	{
		text = COMBAT_TEXT_LABEL,
		desc = L["ANN_FCT_DESC"],
		channel = "FCT",
		sticky = 1,
		icon = 1,
		color = 1,
		handler = function(icon, data, Text)
			if data.Icon then
				Text = "|T" .. (icon.__tex or "") .. ":20:20:-5|t " .. Text
			end
			if SHOW_COMBAT_TEXT ~= "0" then
				if not CombatText_AddMessage then
					UIParentLoadAddOn("Blizzard_CombatText")
				end
				CombatText_AddMessage(Text, CombatText_StandardScroll, data.r, data.g, data.b, data.Sticky and "crit" or nil, false)
			end
		end,
	},
}
for k, v in pairs(TMW.ChannelList) do
	TMW.ChannelList[v.channel] = v
end local ChannelList = TMW.ChannelList
function ANN:ProcessIconEventSettings(icon, event, eventSettings)
	if eventSettings.Channel ~= "" then
		return true
	end
end
function ANN:HandleEvent(icon, data)
	local Channel = data.Channel
	if Channel ~= "" then
		local Text = data.Text
		local chandata = ChannelList[Channel]

		if not chandata then
			return
		end

		Text = TMW:InjectDataIntoString(Text, icon, not chandata.isBlizz, not chandata.isBlizz, nil, true)

		if chandata.handler then
			chandata.handler(icon, data, Text)
		elseif Text and chandata.isBlizz then
			local Location = data.Location
			if Channel == "WHISPER" then
				Location = TMW:InjectDataIntoString(Location, icon, true, false)
			end
			SendChatMessage(Text, Channel, nil, Location)
		end

		return true
	end
end


ANIM = EVENTS:NewModule("Animations", EVENTS) TMW.ANIM = ANIM
ANIM.AnimationList = {
	{
		text = NONE,
		animation = "",
	},
	{
		text = L["ANIM_SCREENSHAKE"],
		desc = L["ANIM_SCREENSHAKE_DESC"],
		animation = "SCREENSHAKE",
		Duration = true,
		Magnitude = true,

		Play = function(icon, data)
			if not WorldFrame:IsProtected() or not InCombatLockdown() then
			
				if not WorldFrame.Animations_Start then
					TMW.Classes.AnimatedObject:Embed(WorldFrame)
				end
				
				WorldFrame:Animations_Start{
					data = data,
					Start = time,
					Duration = data.Duration,

					Magnitude = data.Magnitude,
				}
			end
		end,

		OnUpdate = function(WorldFrame, table)
			local remaining = table.Duration - (time - table.Start)

			if remaining < 0 then
				WorldFrame:Animations_Stop(table)
			else
				local Amt = (table.Magnitude or 10) / (1 + 10*(300^(-(remaining))))
				local moveX = random(-Amt, Amt)
				local moveY = random(-Amt, Amt)

				WorldFrame:ClearAllPoints()
				for _, v in pairs(TMW.WorldFramePoints) do
					WorldFrame:SetPoint(v[1], v[2], v[3], v[4] + moveX, v[5] + moveY)
				end
			end
		end,
		OnStart = function(WorldFrame, table)
			if not TMW.WorldFramePoints then
				TMW.WorldFramePoints = {}
				for i = 1, WorldFrame:GetNumPoints() do
					TMW.WorldFramePoints[i] = { WorldFrame:GetPoint(i) }
				end
			end
		end,
		OnStop = function(WorldFrame, table)
			WorldFrame:ClearAllPoints()
			for _, v in pairs(TMW.WorldFramePoints) do
				WorldFrame:SetPoint(v[1], v[2], v[3], v[4], v[5])
			end
		end,
	},
	{
		text = L["ANIM_SCREENFLASH"],
		desc = L["ANIM_SCREENFLASH_DESC"],
		animation = "SCREENFLASH",
		Duration = true,
		Period = true,
		Color = true,
		Fade = true,

		Play = function(icon, data)
			local AnimationData = AnimationList[data.Animation]

			local Duration = 0
			local Period = data.Period
			if Period == 0 then
				Duration = data.Duration
			else
				while Duration < data.Duration do
					Duration = Duration + (Period * 2)
				end
			end

			-- inherit from ICONFLASH (since all the functions except Play are the same)
			if not AnimationData.OnStart then
				local ICONFLASH = AnimationList.ICONFLASH
				AnimationData.OnStart = ICONFLASH.OnStart
				AnimationData.OnUpdate = ICONFLASH.OnUpdate
				AnimationData.OnStop = ICONFLASH.OnStop
			end

			if not UIParent.Animations_Start then
				TMW.Classes.AnimatedObject:Embed(UIParent)
			end
				
			UIParent:Animations_Start{
				data = data,
				Start = time,
				Duration = Duration,

				Period = Period,
				Fade = data.Fade,
				Alpha = data.a_anim,
				r = data.r_anim,
				g = data.g_anim,
				b = data.b_anim,
			}
		end,
	},
	{
		text = L["ANIM_ICONSHAKE"],
		desc = L["ANIM_ICONSHAKE_DESC"],
		animation = "ICONSHAKE",
		Duration = true,
		Magnitude = true,
		Infinite = true,

		Play = function(icon, data)
			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = data.Infinite and huge or data.Duration,

				Magnitude = data.Magnitude,
			}
		end,

		OnUpdate = function(icon, table)
			local remaining = table.Duration - (time - table.Start)
			
			if remaining < 0 then
				-- generic expiration
				icon:Animations_Stop(table)
			else
				local Amt = (table.Magnitude or 10) / (1 + 10*(300^(-(remaining))))
				local moveX = random(-Amt, Amt)
				local moveY = random(-Amt, Amt)

				icon:SetPoint("TOPLEFT", icon.x + moveX, icon.y + moveY)
			end
		end,
		OnStop = function(icon, table)
			icon:SetPoint("TOPLEFT", icon.x, icon.y)
		end,
	},
	{
		text = L["ANIM_ICONFLASH"],
		desc = L["ANIM_ICONFLASH_DESC"],
		animation = "ICONFLASH",
		Duration = true,
		Period = true,
		Color = true,
		Fade = true,
		Infinite = true,

		Play = function(icon, data)
			local Duration = 0
			local Period = data.Period
			if data.Infinite then
				Duration = huge
			else
				if Period == 0 then
					Duration = data.Duration
				else
					while Duration < data.Duration do
						Duration = Duration + (Period * 2)
					end
				end
			end

			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = Duration,

				Period = Period,
				Fade = data.Fade,
				Alpha = data.a_anim,
				r = data.r_anim,
				g = data.g_anim,
				b = data.b_anim,
			}
		end,

		OnUpdate = function(icon, table)
			local FlashPeriod = table.Period
			local animation_flasher = icon.animation_flasher

			local timePassed = time - table.Start
			local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 1

			if table.Fade and FlashPeriod ~= 0 then
				local remainingFlash = timePassed % FlashPeriod
				if fadingIn then
					animation_flasher:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
				else
					animation_flasher:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
				end
			else
				animation_flasher:SetAlpha(fadingIn and table.Alpha or 0)
			end

			-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
			if timePassed > table.Duration then
				icon:Animations_Stop(table)
			end
		end,
		OnStart = function(icon, table)
			local animation_flasher
			if icon.animation_flasher then
				animation_flasher = icon.animation_flasher
			else
				animation_flasher = icon:CreateTexture(nil, "BACKGROUND", nil, 6)
				animation_flasher:SetAllPoints(icon.class == TMW.Classes.Icon and icon.texture)
				animation_flasher:Hide()
	
				icon.animation_flasher = animation_flasher
			end

			animation_flasher:Show()
			animation_flasher:SetTexture(table.r, table.g, table.b, 1)
		end,
		OnStop = function(icon, table)
			icon.animation_flasher:Hide()
		end,
	},
	{
		text = L["ANIM_ICONALPHAFLASH"],
		desc = L["ANIM_ICONALPHAFLASH_DESC"],
		animation = "ICONALPHAFLASH",
		Duration = true,
		Period = true,
		Fade = true,
		Infinite = true,

		Play = function(icon, data)
			local Duration = 0
			local Period = data.Period
			if data.Infinite then
				Duration = huge
			else
				if Period == 0 then
					Duration = data.Duration
				else
					while Duration < data.Duration do
						Duration = Duration + (Period * 2)
					end
				end
			end

			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = Duration,

				Period = Period,
				Fade = data.Fade,
			}
		end,

		OnUpdate = function(icon, table)
			local FlashPeriod = table.Period

			local timePassed = time - table.Start
			local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 1

			if table.Fade and FlashPeriod ~= 0 then
				local remainingFlash = timePassed % FlashPeriod
				if not fadingIn then
					icon:SetAlpha(icon.__alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
				else
					icon:SetAlpha(icon.__alpha*(remainingFlash/FlashPeriod))
				end
			else
				icon:SetAlpha(fadingIn and icon.__alpha or 0)
			end

			-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
			if timePassed > table.Duration then
				icon:Animations_Stop(table)
			end
		end,
		OnStart = function(icon, table)
			icon.FadeHandlers = icon.FadeHandlers or {}
			icon.FadeHandlers[#icon.FadeHandlers + 1] = "ICONALPHAFLASH"
		end,
		OnStop = function(icon, table)
			tDeleteItem(icon.FadeHandlers, "ICONALPHAFLASH")
		end,
	},
	{
		text = L["ANIM_ICONFADE"],
		desc = L["ANIM_ICONFADE_DESC"],
		animation = "ICONFADE",
		Duration = true,

		Play = function(icon, data)
			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = data.Duration,

				FadeDuration = data.Duration,
			}
		end,

		OnUpdate = function(icon, table)
			if not icon.FakeHidden then
				local remaining = table.Duration - (time - table.Start)

				-- generic expiration
				if remaining < 0 then
					icon:Animations_Stop(table)
				else
					local pct = remaining / table.FadeDuration
					local inv = 1-pct

					icon:SetAlpha((icon.__oldAlpha * pct) + (icon.__alpha * inv))
				end
			end
		end,
		OnStart = function(icon, table)
			icon.FadeHandlers = icon.FadeHandlers or {}
			icon.FadeHandlers[#icon.FadeHandlers + 1] = "ICONFADE"
		end,
		OnStop = function(icon, table)
			tDeleteItem(icon.FadeHandlers, "ICONFADE")
		end,


	},
	{
		text = L["ANIM_ACTVTNGLOW"],
		desc = L["ANIM_ACTVTNGLOW_DESC"],
		animation = "ACTVTNGLOW",
		Duration = true,
		Infinite = true,

		Play = function(icon, data)
			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = data.Infinite and huge or data.Duration,
			}
		end,

		OnUpdate = function(icon, table)
			if table.Duration - (time - table.Start) < 0 then
				icon:Animations_Stop(table)
			end
		end,
		OnStart = function(icon, table)
			ActionButton_ShowOverlayGlow(icon) -- dont upvalue, can be hooked (masque does, maybe others)
		end,
		OnStop = function(icon, table)
			ActionButton_HideOverlayGlow(icon) -- dont upvalue, can be hooked (masque doesn't, but maybe others)
		end,
	},
	{
		text = L["ANIM_ICONBORDER"],
		desc = L["ANIM_ICONBORDER_DESC"],
		animation = "ICONBORDER",
		Duration = true,
		Period = true,
		Color = true,
		Fade = true,
		Infinite = true,
		Size_anim = true,
		Thickness = true,

		Play = function(icon, data)
			local Duration = 0
			local Period = data.Period
			if data.Infinite then
				Duration = huge
			else
				if Period == 0 then
					Duration = data.Duration
				else
					while Duration < data.Duration do
						Duration = Duration + (Period * 2)
					end
				end
			end

			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = Duration,

				Period = Period,
				Fade = data.Fade,
				Alpha = data.a_anim,
				r = data.r_anim,
				g = data.g_anim,
				b = data.b_anim,
				Thickness = data.Thickness,
				Size = data.Size_anim,
			}
		end,

		OnUpdate = function(icon, table)
			local FlashPeriod = table.Period
			local animation_border = icon.animation_border

			local timePassed = time - table.Start
			local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 0

			if table.Fade and FlashPeriod ~= 0 then
				local remainingFlash = timePassed % FlashPeriod
				if not fadingIn then
					animation_border:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
				else
					animation_border:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
				end
			else
				animation_border:SetAlpha(fadingIn and table.Alpha or 0)
			end

			-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
			if timePassed > table.Duration then
				icon:Animations_Stop(table)
			end
		end,
		OnStart = function(icon, table)
			local animation_border
			if icon.animation_border then
				animation_border = icon.animation_border
			else
				animation_border = CreateFrame("Frame", nil, icon)
				animation_border:SetPoint("CENTER")
				icon.animation_border = animation_border
				
				local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
				animation_border.TOP = tex
				tex:SetPoint("TOPLEFT")
				tex:SetPoint("TOPRIGHT")
				
				local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
				animation_border.BOTTOM = tex
				tex:SetPoint("BOTTOMLEFT")
				tex:SetPoint("BOTTOMRIGHT")
				
				local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
				animation_border.LEFT = tex
				tex:SetPoint("TOPLEFT", animation_border.TOP, "BOTTOMLEFT")
				tex:SetPoint("BOTTOMLEFT", animation_border.BOTTOM, "TOPLEFT")
				
				local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
				animation_border.RIGHT = tex
				tex:SetPoint("TOPRIGHT", animation_border.TOP, "BOTTOMRIGHT")
				tex:SetPoint("BOTTOMRIGHT", animation_border.BOTTOM, "TOPRIGHT")
			end

			animation_border:Show()
			animation_border:SetSize(table.Size, table.Size)
			
			for _, pos in TMW:Vararg("TOP", "BOTTOM", "LEFT", "RIGHT") do
				local tex = animation_border[pos]
				
				tex:SetTexture(table.r, table.g, table.b, 1)
				tex:SetSize(table.Thickness, table.Thickness)
			end
		end,
		OnStop = function(icon, table)
			icon.animation_border:Hide()
		end,
	},
	
	
	{
		text = L["ANIM_ICONOVERLAYIMG"],
		desc = L["ANIM_ICONOVERLAYIMG_DESC"],
		animation = "ICONOVERLAYIMG",
		Duration = true,
		Period = true,
		Fade = true,
		Infinite = true,
		SizeX = true,
		SizeY = true,
		Image = true,

		Play = function(icon, data)
			local Duration = 0
			local Period = data.Period
			if data.Infinite then
				Duration = huge
			else
				if Period == 0 then
					Duration = data.Duration
				else
					while Duration < data.Duration do
						Duration = Duration + (Period * 2)
					end
				end
			end

			icon:Animations_Start{
				data = data,
				Start = time,
				Duration = Duration,

				Period = Period,
				Fade = data.Fade,
				Alpha = data.a_anim,
				SizeX = data.SizeX,
				SizeY = data.SizeY,
				Image = TMW:GetCustomTexture(data.Image),
			}
		end,

		OnUpdate = function(icon, table)
			local FlashPeriod = table.Period
			local animation_overlay = icon.animation_overlay

			local timePassed = time - table.Start
			local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 0

			if table.Fade and FlashPeriod ~= 0 then
				local remainingFlash = timePassed % FlashPeriod
				if not fadingIn then
					animation_overlay:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
				else
					animation_overlay:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
				end
			else
				animation_overlay:SetAlpha(fadingIn and table.Alpha or 0)
			end

			-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
			if timePassed > table.Duration then
				icon:Animations_Stop(table)
			end
		end,
		OnStart = function(icon, table)
			local animation_overlay
			if icon.animation_overlay then
				animation_overlay = icon.animation_overlay
			else
				animation_overlay = icon:CreateTexture(nil, "BACKGROUND", nil, 4)
				animation_overlay:SetPoint("CENTER")
				icon.animation_overlay = animation_overlay
			end

			animation_overlay:Show()
			animation_overlay:SetSize(table.SizeX, table.SizeY)
			
			animation_overlay:SetTexture(table.Image)
		end,
		OnStop = function(icon, table)
			icon.animation_overlay:Hide()
		end,
	},
	
	
	
	
	
	{
		noclick = true,
	},
	{
		text = L["ANIM_ICONCLEAR"],
		desc = L["ANIM_ICONCLEAR_DESC"],
		animation = "ICONCLEAR",

		Play = function(icon, data)
			if icon:Animations_Has() then
				for k, v in pairs(icon:Animations_Get()) do
					-- instead of just calling :Animations_Stop() right here, set this attribute so that meta icons inheriting the animation will also stop it.
					v.HALTED = true
				end
			end
		end,
	},
}	AnimationList = ANIM.AnimationList
for k, v in pairs(AnimationList) do
	if v.animation then
		AnimationList[v.animation] = v
	end
end
function ANIM:OnInitialize()
	TMW:RegisterCallback("TMW_ICON_META_INHERITED_ICON_CHANGED", self)
end
function ANIM:ProcessIconEventSettings(icon, event, eventSettings)
	if eventSettings.Animation ~= "" then
		return true
	end
end
function ANIM:HandleEvent(icon, data)
	local Animation = data.Animation
	if Animation ~= "" then

		local AnimationData = AnimationList[Animation]
		if AnimationData then
			AnimationData.Play(icon, data)
			return true
		end
	end

end
function ANIM:TMW_ICON_META_INHERITED_ICON_CHANGED(event, icon, icToUse)
	if icon:Animations_Has() then
		for k, v in next, icon:Animations_Get() do
			if v.originIcon ~= icon then
				icon:Animations_Stop(v)
			end
		end
	end
	if icToUse:Animations_Has() then
		for k, v in next, icToUse:Animations_Get() do
			icon:Animations_Start(v)
		end
	end
end

local AnimatedObject = TMW:NewClass("AnimatedObject")
function AnimatedObject:Animations_Get()
	if not self.animations then
		local t = {}
		ActiveAnimations = ActiveAnimations or {}
		ActiveAnimations[self] = t
		self.animations = t
		return t
	end
	return self.animations
end
function AnimatedObject:Animations_Has()
	return self.animations 
end
function AnimatedObject:Animations_OnUnused()
	if self.animations then
		self.animations = nil
		ActiveAnimations[self] = nil
		if not next(ActiveAnimations) then
			ActiveAnimations = nil
		end
	end
end
function AnimatedObject:Animations_Start(table)
	local Animation = table.data.Animation
	local AnimationData = Animation and AnimationList[Animation]

	if AnimationData then
		self:Animations_Get()[Animation] = table

		table.Animation = Animation
		
		-- Make sure not to overwrite this value.
		-- This is used to distingusih inherited meta animations from original animations on a metaicon.
		table.originIcon = table.originIcon or self
		--table.lastInitialize = time 

		if AnimationData.OnStart then
			AnimationData.OnStart(self, table)
		end

		-- meta inheritance
		local Icons = Types.meta.Icons
		for i = 1, #Icons do
			local ic = Icons[i]
			if ic.__currentIcon == self then
				ic:Animations_Start(table, ic)
			end
		end
	end
end
function AnimatedObject:Animations_Stop(arg1)
	local animations = self.animations
	
	if not animations then return end
	
	local Animation, table
	if type(arg1) == "table" then
		table = arg1
		Animation = table.Animation
	else
		table = animations[arg1]
		Animation = arg1
	end

	local AnimationData = AnimationList[Animation]

	if AnimationData then
		animations[Animation] = nil

		if AnimationData.OnStop then
			AnimationData.OnStop(self, table)
		end
		
		if not next(animations) then
			self:Animations_OnUnused()
		end
	end
end



local ConditionControlledObject = TMW:NewClass("ConditionControlledObject")

function ConditionControlledObject:Conditions_LoadData(Conditions)
	local obj = TMW.CNDT:GetConditionObject(self, Conditions)
	self.ConditionObj = obj
	return obj
end


-- -----------
-- GROUPS
-- -----------

local Group = TMW:NewClass("Group", "Frame", "ConditionControlledObject")

function Group.OnNewInstance(group, ...)
	local _, name, _, _, groupID = ... -- the CreateFrame args
	TMW[groupID] = group
	CNDTEnv[name] = group
	
	group.SortedIcons = {}
end

function Group.__tostring(group)
	return group:GetName()
end

function Group.ScriptSort(groupA, groupB)
	local gOrder = -db.profile.CheckOrder
	return groupA:GetID()*gOrder < groupB:GetID()*gOrder
end

function Group.SizeUpdate(resizeButton)
	-- note that arg1 (self) is resizeButton
	local group = resizeButton:GetParent()
	local uiScale = UIParent:GetScale()
	local cursorX, cursorY = GetCursorPosition()

	-- calculate new scale
	local newXScale = group.oldScale * (cursorX/uiScale - group.oldX*group.oldScale) / (resizeButton.oldCursorX/uiScale - group.oldX*group.oldScale)
	local newYScale = group.oldScale * (cursorY/uiScale - group.oldY*group.oldScale) / (resizeButton.oldCursorY/uiScale - group.oldY*group.oldScale)
	local newScale = max(0.6, newXScale, newYScale)
	group:SetScale(newScale)

	-- calculate new frame position
	local newX = group.oldX * group.oldScale / newScale
	local newY = group.oldY * group.oldScale / newScale
	group:ClearAllPoints()
	group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
end

function Group:TMW_ICON_UPDATED(event, icon)
	-- note that this callback is not inherited - it simply handles all groups
	icon.group.iconSortNeeded = true
end
TMW:RegisterCallback("TMW_ICON_UPDATED", Group)

function Group.IconSorter(iconA, iconB)
	local group = iconA.group
	local SortPriorities = group.SortPriorities
	for p = 1, #SortPriorities do
		local settings = SortPriorities[p]
		local method = settings.Method
		local order = settings.Order
		
		if Locked or method == "id" then -- force sorting by ID when unlocked
			if method == "id" then
				return iconA.ID*order < iconB.ID*order
				
			elseif method == "alpha" then
				local a, b = iconA.__alpha, iconB.__alpha
				if a ~= b then
					return a*order < b*order
				end
				
			elseif method == "visiblealpha" then
				local a, b = iconA:GetAlpha(), iconB:GetAlpha()
				if a ~= b then
					return a*order < b*order
				end
				
			elseif method == "stacks" then
				local a, b = iconA.__count or 0, iconB.__count or 0
				if a ~= b then
					return a*order < b*order
				end
				
			elseif method == "shown" then
				local a, b = (iconA.__shown and iconA.__alpha > 0) and 1 or 0, (iconB.__shown and iconB.__alpha > 0) and 1 or 0
				if a ~= b then
					return a*order < b*order
				end
				
			elseif method == "visibleshown" then
				local a, b = (iconA.__shown and iconA:GetAlpha() > 0) and 1 or 0, (iconB.__shown and iconB:GetAlpha() > 0) and 1 or 0
				if a ~= b then
					return a*order < b*order
				end
				
			elseif method == "duration" then
				local iconA__duration, iconB__duration = iconA.__duration, iconB.__duration
				local durationA = iconA__duration - (time - iconA.__start)
				local durationB = iconB__duration - (time - iconB.__start)
				
				if durationA ~= durationB then
					return durationA*order < durationB*order
				end
			end
		end
	end
end

function Group.SortIcons(group)
	local SortedIcons = group.SortedIcons
	sort(SortedIcons, group.IconSorter)
	
	for positionedID = 1, #group do
		local icon = SortedIcons[positionedID]
		
		local x, y = group:GetIconPos(positionedID)
		icon.x, icon.y = x, y -- used for shakers
		icon:SetPoint("TOPLEFT", x, y)
	end
end

Group.setscript = Group.SetScript
function Group.SetScript(group, handler, func)
	group[handler] = func
	group:setscript(handler, func)
end

Group.show = Group.Show
function Group.Show(group)
	if not group.__shown then
		group:show()
		group.__shown = 1
	end
end

Group.hide = Group.Hide
function Group.Hide(group)
	if group.__shown then
		group:hide()
		group.__shown = nil
	end
end


function Group.GetSettings(group)
	return db.profile.Groups[group:GetID()]
end

function Group.FinishCompilingConditions(group, funcstr)
	if group.OnlyInCombat then
		if funcstr == "" then
			funcstr = [[UnitAffectingCombat("player")]]
		else
			funcstr = [[(]] .. funcstr .. [[) and UnitAffectingCombat("player")]]
		end
		return funcstr, {PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true}
	else
		return funcstr
	end
end

function Group.ShouldUpdateIcons(group)
	local gs = group:GetSettings()

	if	(group:GetID() > TELLMEWHEN_MAXGROUPS) or
		(not gs.Enabled) or
		(GetActiveTalentGroup() == 1 and not gs.PrimarySpec) or
		(GetActiveTalentGroup() == 2 and not gs.SecondarySpec) or
		(GetPrimaryTalentTree() and not gs["Tree" .. GetPrimaryTalentTree()])
	then
		return false
	end

	return true
end

function Group.SetPos(group)
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
		local success, err = pcall(group.SetPoint, group, p.point, relativeTo, p.relativePoint, p.x, p.y)
		if not success and err:find("trying to anchor to itself") then
			TMW:Error(err)
			TMW:Print(L["ERROR_ANCHORSELF"]:format(L["fGROUP"]):format(TMW:GetGroupName(groupID, groupID, 1)))

			p.relativeTo = "UIParent"
			p.point = "CENTER"
			p.relativePoint = "CENTER"
			p.x = 0
			p.y = 0

			return group:SetPos()
		end
	end
	group:SetScale(s.Scale)
	local Spacing = s.Spacing
	group:SetSize(s.Columns*(30+Spacing)-Spacing, s.Rows*(30+Spacing)-Spacing)
	group:SetFrameStrata(s.Strata)
	group:SetFrameLevel(s.Level)
end

function Group.GetIconPos(group, iconID)
	local Columns, Spacing = group.Columns, group.Spacing

	--[[local row = ceil(iconID / Columns)
    local column = (iconID - 1) % Columns + 1
	return (30 + Spacing)*(column-1), -(30 + Spacing)*(row-1)]]

	return (30 + Spacing)*(((iconID - 1) % Columns)), -(30 + Spacing)*(ceil(iconID / Columns)-1)
end

function Group.Setup(group)
	local groupID = group:GetID()

	group.CorrectStance = true
	group.__shown = group:IsShown()

	for k, v in pairs(TMW.Group_Defaults) do
		group[k] = db.profile.Groups[groupID][k]
	end

	group.FontTest = not Locked and group.FontTest

	group:SetFrameLevel(group.Level)

	if group:ShouldUpdateIcons() then
		for iconID = 1, group.Rows * group.Columns do
			local icon = group[iconID] or TMW.Classes.Icon:New("Button", "TellMeWhen_Group" .. groupID .. "_Icon" .. iconID, group, "TellMeWhen_IconTemplate", iconID)

			icon:Show()
			icon:SetFrameLevel(group:GetFrameLevel() + 1)

			local x, y = group:GetIconPos(iconID)
			icon.x, icon.y = x, y -- used for shakers
			icon:SetPoint("TOPLEFT", x, y)

			local success, err = pcall(icon.Setup, icon)
			if not success then
				TMW:Error(L["GROUPICON"]:format(groupID, iconID) .. ": " .. err)
			end
		end
		for iconID = (group.Rows*group.Columns)+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
			local icon = group[iconID]
			if icon then
				icon:Hide()
				ClearScripts(icon)
			end
		end
	end

	if Locked or group.Locked then
		group.resizeButton:Hide()
	else--if not (Locked or group.Locked) then
		group.resizeButton:Show()
	end

	group:SetPos()
	group:SortIcons()
	group.shouldSortIcons = group.SortPriorities[1].Method ~= "id" and group:ShouldUpdateIcons() and group[2] and true

	-- remove the group from the list of groups that should update conditions
	tDeleteItem(GroupsToUpdate, group)
	
	if group:ShouldUpdateIcons() and Locked then
		group:Show()

		-- process any conditions the group might have
		GroupsToUpdate[#GroupsToUpdate+1] = group:Conditions_LoadData(group.Conditions) and group
	else
		if group:ShouldUpdateIcons() then
			group:Show()
		else
			group:Hide()
		end
	end
	
	-- we probably added or removed an entry from this table, so re-sort it:
	sort(GroupsToUpdate, Group.ScriptSort)
end



-- ------------------
-- ICONS
-- ------------------

local OverlayBar = TMW:NewClass("OverlayBar")

function OverlayBar:RegisterForUpdates()
	if not self.isInUpdateTable then
		tinsert(self.updateTable, self)
		self.isInUpdateTable = true
	end
end

function OverlayBar:UnregisterForUpdates()
	if self.isInUpdateTable then
		tDeleteItem(self.updateTable, self, true)
		self.isInUpdateTable = nil
	end
end



local PBar = TMW:NewClass("PBar", "StatusBar", "OverlayBar")
PBar.updateTable = PBarsToUpdate

function PBar:OnNewInstance(...)
	local _, name, icon = ... -- the CreateFrame args
	
	self.Max = 1
	self.PBarOffs = 0
	self.icon = icon
	self:SetFrameLevel(icon:GetFrameLevel() + 2)
	
	self:SetPoint("BOTTOM", icon, "CENTER", 0, 0.5)
	self:SetPoint("TOPLEFT")
	self:SetPoint("TOPRIGHT")
	
	self.texture = self:CreateTexture(nil, "OVERLAY")
	self.texture:SetAllPoints()
	self:SetStatusBarTexture(self.texture)
end

function PBar:SetAttributes(source)
	-- source should either be a PBar or an Icon.
	-- Code must maintain compatability so that both of these will work as input (keep inherited keys the same)
	
	self.InvertBars = source.InvertBars
	self.PBarOffs = source.PBarOffs or 0
	self.ShowPBar = source.ShowPBar
	
	if self.ShowPBar then
		self:Show()
	else
		self:Hide()
	end
end

function PBar:Setup()
	local icon = self.icon	

	self.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
	
	local blizzEdgeInsets = icon.group.barInsets or 0
	self:SetPoint("BOTTOM", icon.texture, "CENTER", 0, 0.5)
	self:SetPoint("TOPLEFT", icon.texture, "TOPLEFT", blizzEdgeInsets, -blizzEdgeInsets)
	self:SetPoint("TOPRIGHT", icon.texture, "TOPRIGHT", -blizzEdgeInsets, -blizzEdgeInsets)
	
	if not self.powerType then
		local powerType = defaultPowerType
		local colorinfo = PowerBarColor[powerType]
		self:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
		self.powerType = powerType
	end
	
	self:SetAttributes(icon)

	if self.ShowPBar then
		TMW:RegisterEvent("SPELL_UPDATE_USABLE")		
		TMW:RegisterEvent("UNIT_POWER_FREQUENT")
	end
end

function PBar:SetSpell(spell)
	self.spell = spell
	
	if spell then
		local _, _, _, cost, _, powerType = GetSpellInfo(spell)
		
		cost = powerType == 9 and 3 or cost or 0 -- holy power hack: always use a max of 3
		self.Max = cost
		self:SetMinMaxValues(0, cost)
		self.__value = nil -- the displayed value might change when we change the max, so force an update
		
		powerType = powerType or defaultPowerType
		if powerType ~= self.powerType then
			local colorinfo = PowerBarColor[powerType]
			self:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
			self.powerType = powerType
		end

		if not self.isInUpdateTable then
			PBarsToUpdate[#PBarsToUpdate + 1] = self
			self.isInUpdateTable = true
		end
		
		self:Update()
	elseif self.isInUpdateTable then
		local value = self.InvertBars and self.Max or 0
		self:SetValue(value)
		self.__value = value
		
		self:UnregisterForUpdates()
	end
end

function PBar:Update(power, powerTypeNum)
	if not powerTypeNum then
		powerTypeNum = self.powerType
		power = UnitPower("player", powerTypeNum)
	end
	
	if powerTypeNum == self.powerType then
	
		local Max = self.Max
		local value

		if not self.InvertBars then
			value = Max - power + self.PBarOffs
		else
			value = power + self.PBarOffs
		end

		if value > Max then
			value = Max
		elseif value < 0 then
			value = 0
		end

		if self.__value ~= value then
			self:SetValue(value)
			self.__value = value
		end
	end
end



local CBar = TMW:NewClass("CBar", "StatusBar", "OverlayBar")
CBar.updateTable = CBarsToUpdate

function CBar:OnNewInstance(...)
	local _, name, icon = ... -- the CreateFrame args
	
	self.Max = 1
	self.CBarOffs = 0
	self.icon = icon
	self:SetFrameLevel(icon:GetFrameLevel() + 2)
	self:SetMinMaxValues(0, self.Max)
	
	self.start = 0
	self.duration = 0
	
	self:SetPoint("TOP", icon, "CENTER", 0, -0.5)
	self:SetPoint("BOTTOMLEFT")
	self:SetPoint("BOTTOMRIGHT")
	
	self.texture = self:CreateTexture(nil, "OVERLAY")
	self.texture:SetAllPoints()
	self:SetStatusBarTexture(self.texture)
end

function CBar:SetAttributes(source)
	-- source should either be a CBar or an Icon.
	-- Code must maintain compatability so that both of these will work as input (keep inherited keys the same)
	
	self.InvertBars = source.InvertBars
	self.CBarOffs = source.CBarOffs or 0
	self.ShowCBar = source.ShowCBar
	
	-- THIS WONT REALLY WORK CORRECTLY
	self.startColor = source.startColor or (source.typeData and source.typeData.CBS)
	self.completeColor = source.completeColor or (source.typeData and source.typeData.CBC)
	
	if self.ShowCBar then
		self:Show()
	else
		self:Hide()
	end
	
	self:Update(1)
end

function CBar:Setup()
	local icon = self.icon
	
	self.texture:SetTexture(LSM:Fetch("statusbar", db.profile.TextureName))
	
	local blizzEdgeInsets = icon.group.barInsets or 0
	self:SetPoint("TOP", icon.texture, "CENTER", 0, -0.5)
	self:SetPoint("BOTTOMLEFT", icon.texture, "BOTTOMLEFT", blizzEdgeInsets, blizzEdgeInsets)
	self:SetPoint("BOTTOMRIGHT", icon.texture, "BOTTOMRIGHT", -blizzEdgeInsets, blizzEdgeInsets)
	
	self:SetAttributes(icon)
end

function CBar:Update(force)
	local ret = 0
	
	local value, doTerminate

	local start, duration, InvertBars = self.start, self.duration, self.InvertBars

	if InvertBars then
		if duration == 0 then
			value = self.Max
		else
			value = time - start + self.CBarOffs
		end
		doTerminate = value >= self.Max
	else
		if duration == 0 then
			value = 0
		else
			value = duration - (time - start) + self.CBarOffs
		end
		doTerminate = value <= 0
	end

	if doTerminate then
		self:UnregisterForUpdates()
		ret = -1
		if InvertBars then
			value = self.Max
		else
			value = 0
		end
	end

	if force or value ~= self.__value then
		self:SetValue(value)

		local co = self.completeColor
		local st = self.startColor

		if not InvertBars then
			-- normal
			if value ~= 0 then
				--local pct = (time - start) / duration
				local pct = value / self.Max
				local inv = 1-pct
				self:SetStatusBarColor(
					(co.r * pct) + (st.r * inv),
					(co.g * pct) + (st.g * inv),
					(co.b * pct) + (st.b * inv),
					(co.a * pct) + (st.a * inv)
				)
			--else
				-- no reason to do thisif value is 0
				-- self:SetStatusBarColor(st.r, st.g, st.b, st.a)
			end
		else
			--inverted
			if value ~= 0 then
				--local pct = (time - start) / duration
				local pct = value / self.Max
				local inv = 1-pct
				self:SetStatusBarColor(
					(co.r * pct) + (st.r * inv),
					(co.g * pct) + (st.g * inv),
					(co.b * pct) + (st.b * inv),
					(co.a * pct) + (st.a * inv)
				)
			--else
				-- no reason to do thisif value is 0
				--	self:SetStatusBarColor(co.r, co.g, co.b, co.a)
			end
		end
		self.__value = value
	end
	
	return ret
end

function CBar:SetCooldown(start, duration, isGCD)
	self.duration = duration
	self.start = start
	
	if duration > 0 then
		if isGCD and BarGCD then
			self.duration = 0
		end

		self.Max = duration
		self:SetMinMaxValues(0, duration)
		self.__value = nil -- the displayed value might change when we change the max, so force an update

		if not self.isInUpdateTable then
			CBarsToUpdate[#CBarsToUpdate + 1] = self
			self.isInUpdateTable = true
		end
	end
end




local Icon = TMW:NewClass("Icon", "Button", "ConditionControlledObject", "AnimatedObject")
Icon.IsIcon = true

-- NOT universal
function Icon.OnNewInstance(icon, ...)
	local _, name, group, _, iconID = ... -- the CreateFrame args

	icon.group = group
	icon.ID = iconID
	group[iconID] = icon
	CNDTEnv[name] = icon
	tinsert(group.SortedIcons, icon)
	
	icon.pbar = PBar:New("StatusBar", name .. "PBar", icon)
	icon.cbar = CBar:New("StatusBar", name .. "CBar", icon)

	icon.__alpha = icon:GetAlpha()
	icon.__tex = icon.texture:GetTexture()
end

-- universal
function Icon.__lt(icon1, icon2)
	local g1 = icon1.group:GetID()
	local g2 = icon2.group:GetID()
	if g1 ~= g2 then
		return g1 < g2
	else
		return icon1:GetID() < icon2:GetID()
	end
end

-- universal
function Icon.__tostring(icon)
	return icon:GetName()
end

-- universal
function Icon.ScriptSort(iconA, iconB)
	local gOrder = -db.profile.CheckOrder
	local gA = iconA.group:GetID()
	local gB = iconB.group:GetID()
	if gA == gB then
		local iOrder = -db.profile.Groups[gA].CheckOrder
		return iconA:GetID()*iOrder < iconB:GetID()*iOrder
	end
	return gA*gOrder < gB*gOrder
end

-- universal
Icon.setscript = Icon.SetScript
function Icon.SetScript(icon, handler, func, dontnil)
	if func ~= nil or not dontnil then
		icon[handler] = func
	end
	if handler ~= "OnUpdate" then
		icon:setscript(handler, func)
	else
		tDeleteItem(IconsToUpdate, icon, true)
		if func then
			IconsToUpdate[#IconsToUpdate+1] = icon
		end
		sort(IconsToUpdate, Icon.ScriptSort)
	end
end

-- universal
Icon.registerevent = Icon.RegisterEvent
function Icon.RegisterEvent(icon, event)
	icon:registerevent(event)
	icon.hasEvents = 1
end

-- universal (MAYBE)
function Icon.GetTooltipTitle(icon)
	local groupID = icon:GetParent():GetID()
	local line1 = L["ICON_TOOLTIP1"] .. " " .. format(L["GROUPICON"], TMW:GetGroupName(groupID, groupID, 1), icon:GetID())
	if icon:GetParent().Locked then
		line1 = line1 .. " (" .. L["LOCKED"] .. ")"
	end
	return line1
end

-- universal
function Icon.GetSettings(icon)
	return db.profile.Groups[icon.group:GetID()].Icons[icon:GetID()]
end

-- universal
function Icon.IsBeingEdited(icon)
	if TMW.IE and TMW.CI.ic == icon and TMW.IE.CurrentTab and TMW.IE:IsVisible() then
		return TMW.IE.CurrentTab:GetID()
	end
end

-- universal
function Icon.QueueEvent(icon, event, data)
	icon.EventsToFire[event] = data or true
	icon.eventIsQueued = true
end

-- universal (but actual event handlers (:HandleEvent()) arent)
function Icon.ProcessQueuedEvents(icon)
	if icon.EventsToFire and icon.eventIsQueued then
		for _, Module in EVENTS:IterateModules() do
			for i = 1, #TMW.EventList do
				local event = TMW.EventList[i].name
				local data = icon[event]
				local doFireAndData = icon.EventsToFire[event]
				if data and doFireAndData then

					if data.OnlyShown and icon.__alpha <= 0 then
						doFireAndData = false

						-- the same test is preformed for all modules,
						-- so we can save the result of it within the module iteration without adverse effects
						-- it actually results an a performance increase.
						icon.EventsToFire[event] = doFireAndData

					elseif data.PassingCndt and isNumber[doFireAndData] then
						doFireAndData = CompareFuncs[data.Operator](doFireAndData, data.Value)
						if data.CndtJustPassed then
							if doFireAndData ~= data.wasPassingCondition then
								data.wasPassingCondition = doFireAndData
							else
								doFireAndData = false
							end
						end

						-- the same test is preformed for all modules...
						icon.EventsToFire[event] =  doFireAndData
					end


					if doFireAndData and runEvents then
						local handled = Module:HandleEvent(icon, data)
						if handled and not data.PassThrough then
							break
						end
					end
				end
			end
		end

		wipe(icon.EventsToFire)
		icon.eventIsQueued = nil
	end
end

-- universal
function Icon.IsValid(icon)
	-- checks if the icon should be in the list of icons that can be checked in metas/conditions
	
	return icon.Enabled and icon.group:ShouldUpdateIcons()
end

-- universal
Icon.Update_Method = "auto"
function Icon.SetUpdateMethod(icon, method)
	if db.profile.DEBUG_ForceAutoUpdate then
		method = "auto"
	end
	
	icon.Update_Method = method
	
	if method == "auto" then
		-- do nothing for now.
	elseif method == "manual" then
		icon.NextUpdateTime = 0
	else
	--	error("Unknown update method " .. method)
	end
end

-- universal
Icon.NextUpdateTime = huge
function Icon.ScheduleNextUpdate(icon)
	local d = icon.__duration - (time - icon.__start)
	if d < 0 then d = 0 end
	
	local newdur = 0
	
	
	-- Duration Min/Max
	if icon.DurationMaxEnabled then
		local DurationMax = icon.DurationMax
		if DurationMax < d then
			newdur = DurationMax
		end
	end
	if icon.DurationMinEnabled then
		local DurationMin = icon.DurationMin
		if DurationMin < d and newdur < DurationMin then
			newdur = DurationMin
		end
	end
	
	-- Duration Events
	if icon.OnDuration then
		local Duration = icon.OnDuration.Value
		if Duration < d and newdur < Duration then
			newdur = Duration
		end
	end
	
	local nextUpdateTime = time + (d - newdur)
	if nextUpdateTime == time then
		nextUpdateTime = nil
	end
	icon.NextUpdateTime = nextUpdateTime
	
	--return nextUpdateTime
end


-- universal (and needs to stay that way)
function Icon.Update(icon, force, ...)
	
	if icon.__shown and (force or icon.LastUpdate <= time - UPD_INTV) then
		local Update_Method = icon.Update_Method
		icon.LastUpdate = time

		local iconUpdateNeeded = force or Update_Method == "auto" or icon.NextUpdateTime < time
		
		local ConditionObj = icon.ConditionObj
		if ConditionObj then
			if ConditionObj.UpdateNeeded or ConditionObj.NextUpdateTime < time then
				ConditionObj:Check(icon)
				iconUpdateNeeded = iconUpdateNeeded or ConditionObj.LastCheckFailed ~= ConditionObj.Failed
			elseif ConditionObj.LastUpdateTime == time then
				iconUpdateNeeded = true
			end
			
			if not icon.dontHandleConditionsExternally and not icon.hasEventHandlers and ConditionObj.Failed and (icon.ConditionAlpha or 0) == 0 then
				if icon.__alpha ~= 0 then
					icon:SetInfo(0)
				end
				return
			end
		end

		if iconUpdateNeeded then
			icon:OnUpdate(time, ...)
			if Update_Method == "manual" then
				icon:ScheduleNextUpdate()
			end
		end

	--[[	-- RE-CREATE CHECK AFTER IF YOU WANT IT BACK, BECAUSE FOR NOW, ITS DEAD]]
	end
end

-- universal (probably)
function Icon.SetTexture(icon, tex)
	--if icon.__tex ~= tex then ------dont check for this, checking is done before this method is even called
	tex = icon.OverrideTex or tex
	icon.__tex = tex
	icon.texture:SetTexture(tex)
end

-- universal (probably)
function Icon.SetReverse(icon, reverse)
	icon.__reverse = reverse
	icon.cooldown:SetReverse(reverse)
end

-- universal
function Icon.ForceSetAlpha(icon, alpha)
	icon.__alpha = alpha
	local oldalpha = icon:GetAlpha()-- For ICONFADE. much nicer than using __alpha because it will transition from what is curently visible, not what should be visible after any current fades end
	icon.__oldAlpha = oldalpha

	icon:SetAlpha(alpha)
end

-- universal (maybe, bars should handle color differently though e.g. color by school, by dispel type, etc)
function Icon.CrunchColor(icon, duration, inrange, nomana)
--[[
	CBC = 	{r=0,	g=1,	b=0		},	-- cooldown bar complete
	CBS = 	{r=1,	g=0,	b=0		},	-- cooldown bar start

	OOR	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range
	OOM	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of mana
	OORM=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range and mana

	CTA	=	{r=1,	g=1,	b=1		},	-- counting with timer always
	COA	=	{r=1,	g=1,	b=1		},	-- counting withOUT timer always
	CTS	=	{r=1,	g=1,	b=1		},	-- counting with timer somtimes
	COS	=	{r=1,	g=1,	b=1		},	-- counting withOUT timer somtimes

	NA	=	{r=1,	g=1,	b=1		},	-- not counting always
	NS	=	{r=1,	g=1,	b=1		},	-- not counting somtimes]]

	if inrange == 0 and nomana then
		return icon.typeData.OORM
	elseif inrange == 0 then
		return icon.typeData.OOR
	elseif nomana then
		return icon.typeData.OOM
	end


	local s

	if not duration or duration == 0 then
		s = "N" -- Not counting
	else
		s = "C" -- Counting
	end

	if s == "C" then
		if icon.ShowTimer then
			s = s .. "T" -- Timer
		else
			s = s .. "O" -- nOtimer
		end
	end

	if (icon.ShowWhen or "always") == "always" then
		s = s .. "A" -- Always
	else
		s = s .. "S" -- Sometimes
	end

	--assert(icon.typeData[s])

	return icon.typeData[s]
end

-- NOT universal ( try to create subroutines to handle discrepancies instead of duplicating the whole functions)
function Icon.SetInfo(icon, alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	--[[
	 icon			- the icon object to set the attributes on (frame) (but call as icon:SetInfo(alpha, ...))
	[alpha]			- the alpha to set the icon to (number); (nil) defaults to 0
	[color]			- the value(s) to call SetVertexColor with. Either a (number) that will be used as the r, g, and b; or a (table) with keys r, g, b; or (nil) to leave unchanged
	[texture]		- the texture path to set the icon to (string); or (nil) to leave unchanged
	[start]			- the start time of the cooldow/duration, as passsed to icon.cooldown:SetCooldown(start, duration); (nil) defaults to 0
	[duration]		- the duration of the cooldow/duration, as passsed to icon.cooldown:SetCooldown(start, duration); (nil) defaults to 0
	[spellChecked]	- the name or ID of the spell to be used for the icons power bar overlay (string/number)
	[reverse]		- true/false to set icon.cooldown:SetReverse(reverse), nil to not change (boolean/nil)
	[count]			- the number of stacks to be used for comparison, nil/false to hide (number/nil/false)
	[countText]		- the actual stack TEXT to be set on the icon, will use count if nil (number/string/nil/false)
	[forceupdate]	- for meta icons, will force an update on things even if args didnt change.
	[unit]			- the unit that the icon stopped checking on


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

	local somethingChanged

	alpha = alpha or 0
	duration = duration or 0
	start = start or 0

	local queueOnUnit, queueOnSpell, queueOnStack

	unit = unit or icon.Units and icon.Units[1]
	if icon.__unitChecked ~= unit then
		queueOnUnit = true
		icon.__lastUnitChecked = icon.__unitChecked
		icon.__unitChecked = unit
		
		somethingChanged = 1
	end
		
	if unit then
		local unitName = UnitName(unit)
		if icon.__unitName ~= unitName then
			queueOnUnit = true
			icon.__lastUnitName = icon.__unitName
			icon.__unitName = unitName
		
			somethingChanged = 1
		end
	end
	
	if queueOnUnit and icon.OnUnit then
		icon:QueueEvent("OnUnit")
	end

	if icon.__spellChecked ~= spellChecked then
		queueOnSpell = true
		icon.__spellChecked = spellChecked
		if icon.OnSpell then
			icon:QueueEvent("OnSpell")
		end
		
		somethingChanged = 1
	end

	if duration == 0.001 then duration = 0 end -- hardcode fix for tricks of the trade. nice hardcoding on your part too, blizzard
	local d = duration - (time - start)
	d = d > 0 and d or 0

	if icon.OnDuration then
		if d ~= icon.__lastDur then
			icon:QueueEvent("OnDuration", d)
			icon.__lastDur = d
		
			somethingChanged = 1
		end
	end

	if
		(icon.ConditionObj and not icon.dontHandleConditionsExternally and icon.ConditionObj.Failed) or 						  -- conditions failed
		(d > 0 and ((icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax))) or -- duration requirements failed
		(count and ((icon.StackMinEnabled and icon.StackMin > count) or (icon.StackMaxEnabled and count > icon.StackMax))) 		  -- stack requirements failed
	then
		alpha = alpha ~= 0 and icon.ConditionAlpha or 0 -- use the alpha setting for failed stacks/duration/conditions, but only if the icon isnt being hidden for another reason
	end

	if alpha ~= icon.__alpha then
		local oldalpha = icon.__alpha

		icon.__alpha = alpha
		icon.__oldAlpha = icon:GetAlpha() -- For ICONFADE. much nicer than using __alpha because it will transition from what is curently visible, not what should be visible after any current fades end

		if not icon.FadeHandlers or not icon.FadeHandlers[1] then
			icon:SetAlpha(icon.FakeHidden or alpha)
		end

		-- detect events that occured, and handle them if they did
		if alpha == 0 then
			if icon.OnHide then
				icon:QueueEvent("OnHide")
			end
			TMW:Fire("TMW_ICON_SHOWN_CHANGED", icon, "OnIconHide")
		elseif oldalpha == 0 then
			if icon.OnShow then
				icon:QueueEvent("OnShow")
			end
			TMW:Fire("TMW_ICON_SHOWN_CHANGED", icon, "OnIconShow")
		elseif alpha > oldalpha then
			if icon.OnAlphaInc then
				icon:QueueEvent("OnAlphaInc", alpha*100)
			end
		else -- it must be less than, because it isnt greater than and it isnt the same
			if icon.OnAlphaDec then
				icon:QueueEvent("OnAlphaDec", alpha*100)
			end
		end
		
		somethingChanged = 1
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
				if icon.OnFinish then
					icon:QueueEvent("OnFinish")
				end
			else
				if icon.OnStart then
					icon:QueueEvent("OnStart")
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

				-- cd.s is only used in this function and is used to prevent finish effect spam (and to increase efficiency) while GCDs are being triggered.
				-- icon.__start isnt used because that just records the start time passed in, which may be a GCD, so it will change frequently
				if cd.s ~= s or cd.d ~= d or forceupdate then
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
					cd.d = d
				end
			else
				cd.s = 0
				cd.d = 0
				cd:Hide()
			end
		else
			icon.cooldown:Hide()
		end

		local cbar = icon.cbar
		if cbar.ShowCBar then
			cbar:SetCooldown(start, duration, isGCD)
		end

		icon.__start = start
		icon.__duration = duration
		
		somethingChanged = 1
	end

	if icon.__count ~= count or icon.__countText ~= countText then
		queueOnStack = true
		if count then
			icon.countText:SetText(countText or count)
		else
			icon.countText:SetText(nil)
		end
		icon.__count = count
		icon.__countText = countText

		if icon.OnStack then
			icon:QueueEvent("OnStack", count)
		end
		
		somethingChanged = 1
	end

	texture = icon.OverrideTex or texture -- if a texture override is specefied, then use it instead
	if texture ~= nil and icon.__tex ~= texture then -- do this before events are processed because some text outputs use icon.__tex
		icon.__tex = texture
		icon.texture:SetTexture(texture)
		
		somethingChanged = 1
	end

	-- NO EVENT HANDLING PAST THIS POINT! -- well, actually it doesnt matter that much anymore, but they still won't be handled till the next update
	if icon.eventIsQueued then
		icon:ProcessQueuedEvents()
		
		somethingChanged = 1
	end

	if color and icon.__vrtxcolor ~= color then
		local r, g, b, d
		if type(color) == "table" then
			r, g, b, d = color.r, color.g, color.b, color.Gray
		else
			r, g, b, d = color, color, color, false
		end

		if not (LMB and OnlyMSQ) then
			icon.texture:SetVertexColor(r, g, b, 1)
		end
		icon.texture:SetDesaturated(d)

		if LMB and ColorMSQ then
			local iconnt = icon.normaltex
			if iconnt then
				iconnt:SetVertexColor(r, g, b, 1)
			end
		end

		icon.__vrtxcolor = color
		
		somethingChanged = 1
	end

	if icon.pbar.ShowPBar and (queueOnSpell or forceupdate) then
		icon.pbar:SetSpell(spellChecked)
		
	--	somethingChanged = 1 -- redundant with queueOnSpell
	end

	local BindTextObj = icon.BindTextObj
	if BindTextObj and BindTextObj.hasAnySubstitutions then
		local usedSubstitutions = BindTextObj.usedSubstitutions
		if
			(queueOnSpell and usedSubstitutions.s)							or
			(queueOnUnit  and (usedSubstitutions.u or usedSubstitutions.p))	or
			(queueOnStack and usedSubstitutions.k)
		then
			BindTextObj:UpdateNonDurationSubstitutions()
			somethingChanged = 1
		end
	end
	
	if somethingChanged then
		TMW:Fire("TMW_ICON_UPDATED", icon)
	end
end

-- universal
function Icon.FinishCompilingConditions(icon, funcstr)
	return funcstr
end


-- NOT universal ( and needs rewriting) -- TODO: rewrite texts to be dynamic instead of only having 2 static displays
function Icon.SetupText(icon, fontString, settings)
	fontString:SetWidth(settings.ConstrainWidth and icon.texture:GetWidth() or 0)
	fontString:SetFont(LSM:Fetch("font", settings.Name), settings.Size, settings.Outline)

	if LMB then
		if settings.OverrideLBFPos then
			fontString:ClearAllPoints()
			local func = fontString.__MSQ_SetPoint or fontString.SetPoint
			func(fontString, settings.point, icon, settings.relativePoint, settings.x, settings.y)

			fontString:SetJustifyH(settings.point:match("LEFT") or settings.point:match("RIGHT") or "CENTER")
		end
	else
		fontString:ClearAllPoints()
		fontString:SetPoint(settings.point, icon, settings.relativePoint, settings.x, settings.y)
	end
end






-- NOT universal
function Icon.Setup(icon)
	if not icon or not icon[0] then return end

	local iconID = icon:GetID()
	local groupID = icon.group:GetID()
	local group = icon.group
	local ics = icon:GetSettings()
	local typeData = Types[ics.Type]
	
	
	-- remove the icon from the previous type's icon list
	if icon.typeData then
		icon.typeData:UnregisterIcon(icon)
	end
	-- add the icon to this type's icon list
	icon.typeData = typeData
	typeData:RegisterIcon(icon)
	
	
	-- make sure events dont fire while, or shortly after, we are setting up
	runEvents = nil
	TMW:ScheduleTimer("RestoreEvents", max(UPD_INTV*2.1, 0.2))

	
	icon.__spellChecked = nil
	icon.__unitChecked = nil
	icon.__unitName = nil
	icon.__vrtxcolor = nil
	icon.Units = nil
	icon.ForceDisabled = nil
	icon.dontHandleConditionsExternally = nil

	for k in pairs(TMW.Icon_Defaults) do
		if typeData.RelevantSettings[k] then
			icon[k] = ics[k]
		else
			icon[k] = nil
		end
	end

	icon.hasEventHandlers = nil
	for _, eventData in ipairs(TMW.EventList) do
		local event = eventData.name
		local eventSettings = icon.Events[event]

		local thisHasEventHandlers
		for _, Module in EVENTS:IterateModules() do
			thisHasEventHandlers = Module:ProcessAndDelegateIconEventSettings(icon, event, eventSettings) or thisHasEventHandlers
		end

		icon.hasEventHandlers = icon.hasEventHandlers or thisHasEventHandlers

		if thisHasEventHandlers and not typeData["EventDisabled_" .. event] then
			icon[event] = eventSettings
			icon.EventsToFire = icon.EventsToFire or {}
		else
			icon[event] = nil
		end
	end


	-- process alpha settings
	if icon.ShowWhen == "alpha" then
		icon.UnAlpha = 0
	elseif icon.ShowWhen == "unalpha" then
		icon.Alpha = 0
	end

	-- make fake hidden easier to process in SetInfo
	icon.FakeHidden = icon.FakeHidden and 0

	if pclass ~= "DEATHKNIGHT" then
		icon.IgnoreRunes = nil
	end
	icon.OverrideTex = TMW:GetCustomTexture(icon)

	
	-- UnregisterAllEvents uses a metric fuckton of CPU, so only do it if needed
	if icon.hasEvents then
		icon:UnregisterAllEvents()
		icon.hasEvents = nil
	end
	ClearScripts(icon)
	icon:SetUpdateMethod("auto")

	-- Conditions
	icon:Conditions_LoadData(icon.Conditions)

	local cd = icon.cooldown
	cd.noCooldownCount = not icon.ShowTimerText
	cd:SetDrawEdge(db.profile.DrawEdge)
	icon:SetReverse(false)


	-- Masque skinning
	local isDefault
	icon.normaltex = icon.__MSQ_NormalTexture or icon:GetNormalTexture()
	if LMB then
		local lmbGroup = LMB:Group("TellMeWhen", format(L["fGROUP"], groupID))
		lmbGroup:AddButton(icon)
		group.SkinID = lmbGroup.SkinID or (lmbGroup.db and lmbGroup.db.SkinID)
		if lmbGroup.Disabled or (lmbGroup.db and lmbGroup.db.Disabled) then
			group.SkinID = "Blizzard"
			if not icon.normaltex:GetTexture() then
				isDefault = 1
			end
		end
	else
		isDefault = 1
	end

	if isDefault then
		group.barInsets = 1.5
		cd:SetFrameLevel(icon:GetFrameLevel() + 1)
		icon.cbar:SetFrameLevel(icon:GetFrameLevel() + 2)
		icon.pbar:SetFrameLevel(icon:GetFrameLevel() + 2)
	else
		group.barInsets = 0
		cd:SetFrameLevel(icon:GetFrameLevel() + -2)
		icon.cbar:SetFrameLevel(icon:GetFrameLevel() + -1)
		icon.pbar:SetFrameLevel(icon:GetFrameLevel() + -1)
	end

	--reset things
	--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	icon:SetInfo(0, nil, nil, nil, nil, nil, nil, nil, nil, 1, nil) -- forceupdate is set to 1 here so it doesnt return early (but this doesnt matter anymore)

	
	-- this code here needs a complete rewrite:
				-- update overlay texts
				icon:SetupText(icon.countText, group.Fonts.Count)
				icon:SetupText(icon.bindText, group.Fonts.Bind)

				if not icon.BindTextObj or icon.BindTextObj.icon == icon then
					-- need to check that the icon is the original icon because of the way that meta icons inherit bind text
					if icon.BindText and icon.BindText ~= "" then
						icon.BindTextObj = icon.BindTextObj or BindTextObj:New(icon, icon.bindText)
						
						icon.BindTextObj:SetBaseString(icon.BindText)
					elseif icon.BindTextObj then
						icon.BindTextObj:SetBaseString("")
						icon.BindTextObj = nil
					else
						icon.bindText:SetText("")
					end
				else
					icon.BindTextObj = nil
					icon.bindText:SetText("")
				end


	-- force an update
	icon.LastUpdate = 0

	-- actually run the icon's update function
	if icon.Enabled or not Locked then
		local success, err = pcall(typeData.Setup, typeData, icon, groupID, iconID)
		if not success then
			TMW:Error(L["GROUPICON"]:format(groupID, iconID) .. ": " .. err)
		end
	else
		icon:SetInfo(0)
	end

	-- if the icon is set to always hide and it isnt handling any events, then don't automatically update it.
	-- Conditions and meta icons will update it as needed.
	if icon.FakeHidden and not icon.hasEventHandlers then
		icon:SetScript("OnUpdate", nil, true)
		tDeleteItem(IconsToUpdate, icon)
		if Locked then
			icon:SetInfo(0)
		end
	end

	-- Warnings for missing durations and first-time instructions for duration syntax
	if typeData.DurationSyntax and icon:IsBeingEdited() == 1 then
		TMW.HELP:Show("ICON_DURS_FIRSTSEE", nil, TMW.IE.Main.Type, 20, 0, L["HELP_FIRSTUCD"])

		local Name = TMW.IE.Main.Name
		local s = ""
		local array = TMW:GetSpellNames(nil, Name:GetText())
		for k, v in pairs(TMW:GetSpellDurations(nil, Name:GetText())) do
			if v == 0 then
				s = s .. (s ~= "" and "; " or "") .. array[k]
			end
		end
		if s ~= "" then
			TMW.HELP:Show("ICON_DURS_MISSING", icon, Name, 0, 0, L["HELP_MISSINGDURS"], s)
		else
			TMW.HELP:Hide("ICON_DURS_MISSING")
		end
	end

	local pbar = icon.pbar
	local cbar = icon.cbar
	pbar:Setup()
	cbar:Setup()
	cbar.__value = nil
	pbar.__value = nil
	
	cbar:UnregisterForUpdates()
	if db.profile.Locked and icon.ShowCBar then
		cbar:RegisterForUpdates()
	end
	updatePBars = 1
	
	icon:Show()

	if icon.OverrideTex then icon:SetTexture(icon.OverrideTex) end

	if Locked then
		if icon.texture:GetTexture() == "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled" then
			icon:SetTexture(nil)
		end
		icon:EnableMouse(0)
		if (icon.ForceDisabled or not icon.Enabled) or (icon.Name == "" and not typeData.AllowNoName) then
			ClearScripts(icon)
			icon:Hide()
		end

		pbar:SetAlpha(.9)
		cbar:SetAlpha(.9)
	else
		ClearScripts(icon)

		local testCount, testCountText
		if group.FontTest then
			testCount, testCountText = typeData:GetFontTestValues()
		end

		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(1, 1, nil, 0, 0, icon.__spellChecked, nil, testCount, testCountText, nil, nil, icon.__unitChecked)
		icon:ForceSetAlpha(icon.Enabled and 1 or 0.5) -- force set the alpha (dont handle it with SetInfo because of all the bells and whistles

		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
		end

		cbar:UnregisterForUpdates()
		cbar:SetValue(cbar.Max)
		cbar:SetAlpha(.7)
		cbar:SetStatusBarColor(0, 1, 0, 0.5)

		pbar:UnregisterForUpdates()
		pbar:SetValue(pbar.Max)
		pbar:SetAlpha(.7)

		icon:EnableMouse(1)
	end

	icon.NextUpdateTime = 0

	TMW:Fire("TMW_ICON_SETUP", icon)
	--TMW:Fire("TMW_ICON_UPDATED", icon)
end



local IconType = TMW:NewClass("IconType")

IconType.SUGType = "spell"
IconType.leftCheckYOffset = 0
IconType.chooseNameTitle = L["ICONMENU_CHOOSENAME"]
IconType.chooseNameText  = L["CHOOSENAME_DIALOG"]
IconType.unitTitle = L["ICONMENU_UNITSTOWATCH"]
IconType.EventDisabled_OnCLEUEvent = true

do	-- IconType:InIcons(groupID)
	local cg, ci, mg, mi, Type

	local function iter()
		ci = ci + 1
		while true do
			if ci <= mi and TMW[cg] and (not TMW[cg][ci] or TMW[cg][ci].Type ~= Type.type) then
				-- the current icon is within the bounds of max number of icons
				-- the group exists
				-- the icon doesnt exist or is not the right type
				ci = ci + 1
			elseif cg < mg and (ci > mi or not TMW[cg]) then
				-- the current group is within the number of groups that exist
				-- the current icon is greater than the max number of icons, or the current group does not exist
				cg = cg + 1
				ci = 1
			elseif cg > mg then
				-- the current group exceeds the number of groups that exist
				return -- exit
			else
				break -- we found an icon. procede to return it.
			end
		end
		return TMW[cg] and TMW[cg][ci], cg, ci -- icon, groupID, iconID
	end

	function IconType:InIcons(groupID)
		cg = groupID or 1
		ci = 0
		mg = groupID or TELLMEWHEN_MAXGROUPS
		mi = TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS
		Type = self
		return iter
	end
end

function IconType:OnNewInstance()
	self.Icons = {}
end

function IconType:UpdateColors(dontSetupIcons)
	for k, v in pairs(db.profile.Colors[self.type]) do
		if v.Override then
			self[k] = v
		else
			self[k] = db.profile.Colors.GLOBAL[k]
		end
	end
	if not dontSetupIcons then
		self:SetupIcons()
	end
end

function IconType:SetupIcons()
	for i = 1, #self.Icons do
		self.Icons[i]:Setup()
	end
end

function IconType:GetNameForDisplay(icon, data, doInsertLink)
	local name = data and ((doInsertLink and GetSpellLink(data)) or GetSpellInfo(data)) or data
	return name, true
end

function IconType:DragReceived(icon, t, data, subType)
	local ics = icon:GetSettings()

	if t ~= "spell" then
		return
	end

	local _, spellID = GetSpellBookItemInfo(data, subType)
	if not spellID then
		return
	end

	ics.Name = TMW:CleanString(ics.Name .. ";" .. spellID)
	return true -- signal success
end

function IconType:GetIconMenuText(data)
	local text = data.Name or ""
	local tooltip =	""--data.Name and data.Name ~= "" and data.Name .. "\r\n" or ""

	return text, tooltip
end

function IconType:GetFontTestValues(icon)
	return nil, nil -- pretty pointless to return these nils, but i do a lot of pointless things, don't i?
end

function IconType:Register()
	local typekey = self.type
	setmetatable(self.RelevantSettings, RelevantToAll)

	if TMW.debug and rawget(Types, typekey) then
		-- for tweaking and recreating icon types inside of WowLua so that I don't have to change the typekey every time.
		typekey = typekey .. " - " .. date("%X")
		self.name = typekey
	end

	Types[typekey] = self -- put it in the main Types table
	tinsert(TMW.OrderedTypes, self) -- put it in the ordered table (used to order the type selection dropdown in the icon editor)
	return self -- why not?
end

function IconType:RegisterIcon(icon)
	self.Icons[#self.Icons + 1] = icon
end

function IconType:UnregisterIcon(icon)
	tDeleteItem(self.Icons, icon)
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
	local _, numcolon = self:gsub(":", ":") -- HACK(ish): count the number of colons in the string so that we can keep track of what multiplier we are on (since we start with the highest unit of time)
	local seconds = 0
	for num in self:gmatch(":([0-9%.]*)") do -- iterate over all units of time and their value
		if tonumber(num) and mult[numcolon] then -- make sure that it is valid (there is a number and it isnt a unit of time higher than a year)
			seconds = seconds + mult[numcolon]*num -- multiply the number of units by the number of seconds in that unit and add the appropriate amount of time to the running count
		end
		numcolon = numcolon - 1 -- decrease the current unit of time that is being worked with (even if it was an invalid unit and failed the above check)
	end
	return seconds
end

function TMW:LowerNames(str)
	-- converts a string, or all values of a table, to lowercase. Numbers are kept as numbers.
	if type(str) == "table" then -- handle a table with recursion
		for k, v in pairs(str) do
			str[k] = TMW:LowerNames(v)
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
	if type(ret) == "string" then
		if loweredbackup[ret] then
			-- dont replace names that are proper case with names that arent.
			-- Generally, assume that strings with more capitals after non-letters are more proper than ones with less
			local _, oldcount = gsub(loweredbackup[ret], "[^%a]%u", "%1")
			local _, newcount = gsub(str, "[^%a]%u", "%1")

			-- check the first letter of each string for a capital
			if strfind(loweredbackup[ret], "^%u") then
				oldcount = oldcount + 1
			end
			if strfind(str, "^%u") then
				newcount = newcount + 1
			end

			-- the new string has more than the old, so use it instead
			if newcount > oldcount then
				loweredbackup[ret] = str
			end
		else
			-- there wasn't a string beforem so set the base
			loweredbackup[ret] = str
		end
	end

	return ret
end

function TMW:RestoreCase(str)
	if loweredbackup[str] then
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

function TMW:EquivToTable(name)
	-- this function checks to see if a string is a valid equivalency. If it is, all the spells that it represents will be put into an array and returned. If it isn't, nil will be returned.

	name = strlower(name) -- everything in this function is handled as lowercase to prevent issues with user input capitalization. DONT use TMW:LowerNames() here, because the input is not the output
	local eqname, duration = strmatch(name, "(.-):([%d:%s%.]*)$") -- see if the string being checked has a duration attached to it (it really shouldn't because there is currently no point in doing so, but a user did try this and made a bug report, so I fixed it anyway
	name = eqname or name -- if there was a duration, then replace the old name with the actual name without the duration attached

	local names -- scope the variable
	for k, v in pairs(TMW.BE) do -- check in subtables ('buffs', 'debuffs', 'casts', etc)
		for equiv, str in pairs(v) do
			if strlower(equiv) == name then
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

	return tbl
end
TMW:MakeFunctionCached(TMW, "EquivToTable")

function TMW:GetSpellNames(icon, setting, firstOnly, toname, hash, keepDurations)
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
		buffNames = TMW:LowerNames(buffNames)
	end

	if hash then
		local hash = {}
		for k, v in ipairs(buffNames) do
			if toname then
				v = GetSpellInfo(v or "") or v -- turn the value into a name if needed
			end

			v = TMW:LowerNames(v)
			hash[v] = k -- put the final value in the table as well (may or may not be the same as the original value. Value should be NameArrray's key, for use with the duration table.
		end
		return hash
	end
	if toname then
		if firstOnly then
			local ret = buffNames[1] or ""
			ret = GetSpellInfo(ret) or ret -- turn the first value into a name and return it
			if icon then ret = TMW:LowerNames(ret) end
			return ret
		else
			for k, v in ipairs(buffNames) do
				buffNames[k] = GetSpellInfo(v or "") or v --convert everything to a name
			end
			if icon then TMW:LowerNames(buffNames) end
			return buffNames
		end
	end
	if firstOnly then
		local ret = buffNames[1] or ""
		return ret
	end
	return buffNames
end
TMW:MakeFunctionCached(TMW, "GetSpellNames")

function TMW:GetSpellDurations(icon, setting)
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

	return DurationArray
end
TMW:MakeFunctionCached(TMW, "GetSpellDurations")

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
		names = TMW:LowerNames(names)
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

TMW.Units = {
	{ value = "%u", 				text = L["ICONMENU_ICONUNIT"], 	desc = L["ICONMENU_ICONUNIT_DESC"], onlyCondition = true },
	{ value = "player", 			text = PLAYER .. " " .. L["PLAYER_DESC"]  		  },
	{ value = "target", 			text = TARGET 									  },
	{ value = "targettarget", 		text = L["ICONMENU_TARGETTARGET"] 				  },
	{ value = "focus", 				text = L["ICONMENU_FOCUS"] 						  },
	{ value = "focustarget", 		text = L["ICONMENU_FOCUSTARGET"] 				  },
	{ value = "pet", 				text = PET 										  },
	{ value = "pettarget", 			text = L["ICONMENU_PETTARGET"] 					  },
	{ value = "mouseover", 			text = L["ICONMENU_MOUSEOVER"] 					  },
	{ value = "mouseovertarget",	text = L["ICONMENU_MOUSEOVERTARGET"]  			  },
	{ value = "vehicle", 			text = L["ICONMENU_VEHICLE"] 					  },
	{ value = "party", 				text = PARTY, 			range = MAX_PARTY_MEMBERS },
	{ value = "raid", 				text = RAID, 			range = MAX_RAID_MEMBERS  },
	{ value = "arena",				text = ARENA, 			range = 5				  },
	{ value = "boss", 				text = BOSS, 			range = MAX_BOSS_FRAMES	  },
	{ value = "maintank", 			text = L["MAINTANK"], 	range = MAX_RAID_MEMBERS  },
	{ value = "mainassist", 		text = L["MAINASSIST"],	range = MAX_RAID_MEMBERS  },
}
function TMW:GetUnits(icon, setting, dontreplace)
	local set = TMW.UNITS:GetUnitSet(setting)
	return set.exposedUnits, set
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
	if not text then TMW:Error("No text to clean!") end
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

function TMW:StringIsInSemicolonList(list, strtofind)
	-- wheee, long function names
	strtofind = tostring(strtofind)

	for i, str in TMW:Vararg(strsplit(";", list)) do
		if strtofind == str then
			return true
		end
	end
end


function TMW:GetConfigIconTexture(icon, isItem)
	if icon.Name == "" then
		return "Interface\\Icons\\INV_Misc_QuestionMark", nil
	else

		local tbl = isItem and TMW:GetItemIDs(nil, icon.Name) or TMW:GetSpellNames(nil, icon.Name)

		for _, name in ipairs(tbl) do
			local t = isItem and GetItemIcon(name) or SpellTextures[name]
			if t then
				return t, true
			end
		end
		if Types[icon.Type].usePocketWatch then
			if icon:IsBeingEdited() == 1 then
				TMW.HELP:Show("ICON_POCKETWATCH_FIRSTSEE", nil, TMW.IE.icontexture, 0, 0, L["HELP_POCKETWATCH"])
			end
			return "Interface\\Icons\\INV_Misc_PocketWatch_01", false
		else
			return "Interface\\Icons\\INV_Misc_QuestionMark", false
		end
	end
end

TMW.TestTex = TMW:CreateTexture()
function TMW:GetCustomTexture(icon)
	local CustomTex
	if type(icon) == "table" and icon.IsIcon then
		icon.CustomTex = icon.CustomTex ~= "" and icon.CustomTex
		CustomTex = icon.CustomTex
	else
		CustomTex = icon
	end

	CustomTex = tonumber(CustomTex) or CustomTex

	if CustomTex then
		TMW.TestTex:SetTexture(SpellTextures[CustomTex])
		if not TMW.TestTex:GetTexture() then
			TMW.TestTex:SetTexture(CustomTex)
		end
		if not TMW.TestTex:GetTexture() then
			TMW.TestTex:SetTexture("Interface\\Icons\\" .. CustomTex)
		end
		return TMW.TestTex:GetTexture()
	end
end

function TMW:GetGroupName(n, g, short)
	if n and n == g then
		n = db.profile.Groups[g].Name
	end
	if (not n) or n == "" then
		if short then return g end
		return format(L["fGROUP"], g)
	end
	if short then return n .. " (" .. g .. ")" end
	return n .. " (" .. format(L["fGROUP"], g) .. ")"
end

function TMW:FormatSeconds(seconds, skipSmall, keepTrailing)
	-- note that this is different from the one in conditions.lua
	local y =  seconds / 31556925.9936
	local d = (seconds % 31556925.9936) / 86400
	local h = (seconds % 31556925.9936  % 86400) / 3600
	local m = (seconds % 31556925.9936  % 86400  % 3600) / 60
	local s = (seconds % 31556925.9936  % 86400  % 3600  % 60)

	local ns = s
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

	if y >= 1 then return format("%d:%d:%02d:%02d:%s", y, d, h, m, ns) end
	if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, ns) end
	if h >= 1 then return format("%d:%02d:%s", h, m, ns) end
	if m >= 1 then return format("%d:%s", m, ns) end

	return ns
end

function TMW:LockToggle()
	for k, v in pairs(TMW.Warn) do
		-- reset warnings so they can happen again
		if type(k) == "string" then
			TMW.Warn[k] = nil
		end
	end
	db.profile.Locked = not db.profile.Locked

	if not db.profile.Locked then
		for _, cbar in pairs(CBarsToUpdate) do
			cbar.isInUpdateTable = nil
		end
		wipe(CBarsToUpdate)
		
		for _, pbar in pairs(PBarsToUpdate) do
			pbar.isInUpdateTable = nil
		end
		wipe(PBarsToUpdate)
	end

	PlaySound("igCharacterInfoTab")
	TMW:Update()
end

function TMW:SlashCommand(str)
	local cmd, arg2, arg3 = TMW:GetArgs(str, 3)
	cmd = strlower(cmd or "")
	
	if cmd == L["CMD_ENABLE"]:lower() or cmd == "enable" then
		cmd = "enable"
	elseif cmd == L["CMD_DISABLE"]:lower() or cmd == "disable" then
		cmd = "disable"
	elseif cmd == L["CMD_TOGGLE"]:lower() or cmd == "toggle" then
		cmd = "toggle"
	elseif cmd == L["CMD_OPTIONS"]:lower() or cmd == "options" then
		cmd = "options"
	end
	
	if cmd == "options" then
		TMW:LoadOptions()
		LibStub("AceConfigDialog-3.0"):Open("TMW Options")
		
	elseif cmd == "enable" or cmd == "disable" or cmd == "toggle" then
		local groupID, iconID = tonumber(arg2), tonumber(arg3)
		
		local group = groupID and groupID <= TELLMEWHEN_MAXGROUPS and TMW[groupID]
		local icon = iconID and group and group[iconID]
		local obj = icon or group
		if obj then
			if cmd == "enable" then
				obj:GetSettings().Enabled = true
			elseif cmd == "disable" then
				obj:GetSettings().Enabled = false
			elseif cmd == "toggle" then
				obj:GetSettings().Enabled = not obj:GetSettings().Enabled
			end
			obj:Setup()
		end
		
	else
		TMW:LockToggle()
	end
end
TMW:RegisterChatCommand("tmw", "SlashCommand")
TMW:RegisterChatCommand("tellmewhen", "SlashCommand")



local UNITS = TMW:NewModule("Units", "AceEvent-3.0") TMW.UNITS = UNITS
UNITS.mtMap, UNITS.maMap = {}, {}
UNITS.unitsWithExistsEvent = {}
UNITS.unitsWithBaseExistsEvent = {}
UNITS.sets = {}
local UnitSet = TMW:NewClass("UnitSet")

function UnitSet:OnNewInstance(unitSettings)
	self.unitSettings = unitSettings
	self.originalUnits = UNITS:GetOriginalUnitTable(unitSettings)
	self.updateEvents = {}
	self.exposedUnits = {}
	self.allUnitsChangeOnEvent = true
	
	-- determine the operations that the set needs to stay updated
	for k, unit in pairs(self.originalUnits) do
		if unit == "player" then
		--	UNITS.unitsWithExistsEvent[unit] = true -- doesnt really have an event, but do this for external checks of unitsWithExistsEvent to increase efficiency.
		-- if someone legitimately entered "playertarget" then they probably dont deserve to have increased eficiency... dont bother handling player as a base unit
		
		elseif unit == "target" then -- the unit exactly
			self.updateEvents.PLAYER_TARGET_CHANGED = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^target") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.PLAYER_TARGET_CHANGED = true
			UNITS.unitsWithBaseExistsEvent[unit] = "target"
			self.allUnitsChangeOnEvent = false
			
		elseif unit == "pet" then -- the unit exactly
			self.updateEvents.UNIT_PET = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^pet") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.UNIT_PET = true
			UNITS.unitsWithBaseExistsEvent[unit] = "pet"
			self.allUnitsChangeOnEvent = false
			
		elseif unit == "focus" then -- the unit exactly
			self.updateEvents.PLAYER_FOCUS_CHANGED = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^focus") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.PLAYER_FOCUS_CHANGED = true
			UNITS.unitsWithBaseExistsEvent[unit] = "focus"
			self.allUnitsChangeOnEvent = false
		
		elseif unit:find("^raid%d+$") then -- the unit exactly
			self.updateEvents.RAID_ROSTER_UPDATE = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^raid%d+") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.RAID_ROSTER_UPDATE = true
			UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(raid%d+)")
			self.allUnitsChangeOnEvent = false
			
		elseif unit:find("^party%d+$") then -- the unit exactly
			self.updateEvents.PARTY_MEMBERS_CHANGED = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^party%d+") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.PARTY_MEMBERS_CHANGED = true
			UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(party%d+)")
			self.allUnitsChangeOnEvent = false
			
		elseif unit:find("^boss%d+$") then -- the unit exactly
			self.updateEvents.INSTANCE_ENCOUNTER_ENGAGE_UNIT = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^boss%d+") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.INSTANCE_ENCOUNTER_ENGAGE_UNIT = true
			UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(boss%d+)")
			self.allUnitsChangeOnEvent = false
			
		elseif unit:find("^arena%d+$") then -- the unit exactly
			self.updateEvents.ARENA_OPPONENT_UPDATE = true
			UNITS.unitsWithExistsEvent[unit] = true
		elseif unit:find("^arena%d+") then -- the unit as a base, with something else tacked onto it.
			self.updateEvents.ARENA_OPPONENT_UPDATE = true
			UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(arena%d+)")
			self.allUnitsChangeOnEvent = false
			
		elseif unit:find("^maintank") or unit:find("^mainassist") then
			UNITS:UpdateTankAndAssistMap()
			self.updateEvents.RAID_ROSTER_UPDATE = true
			UNITS.unitsWithExistsEvent[unit] = true
			self.hasTankAndAssistRefs = true
			UNITS.doTankAndAssistMap = true
			if not (unit:find("^maintank%d+$") or unit:find("^mainassist%d+$")) then
				self.allUnitsChangeOnEvent = false
			end
		else
			self.allUnitsChangeOnEvent = false
		end
	end

	for event in pairs(self.updateEvents) do
		UNITS:RegisterEvent(event, "OnEvent")
	end

	self:Update()
end

function UnitSet:Update()
	local originalUnits, exposedUnits = self.originalUnits, self.exposedUnits
	local hasTankAndAssistRefs = self.hasTankAndAssistRefs
	for k in next, exposedUnits do
		exposedUnits[k] = nil
	end

	for k = 1, #originalUnits do
		local oldunit = originalUnits[k]
		local success
		if hasTankAndAssistRefs then
			success = UNITS:SubstituteTankAndAssistUnit(oldunit, exposedUnits, #exposedUnits+1)
		end
		local hasExistsEvent = UNITS.unitsWithExistsEvent[oldunit]
		local baseUnit = UNITS.unitsWithBaseExistsEvent[oldunit]
		
		if success == nil and (
			(baseUnit and UnitExists(baseUnit)) or (not baseUnit and (not hasExistsEvent or UnitExists(oldunit)))
		) then
			exposedUnits[#exposedUnits+1] = oldunit
		end
	end
end



function UNITS:GetUnitSet(unitSettings)
	return UnitSet:New(unitSettings)
end
TMW:MakeFunctionCached(UNITS, "GetUnitSet")

function UNITS:GetOriginalUnitTable(unitSettings)
	unitSettings = TMW:CleanString(unitSettings):
	lower(): -- all units should be lowercase
	gsub("|cffff0000", ""): -- strip color codes (NOTE LOWERCASE)
	gsub("|r", ""):
	gsub("#", "") -- strip the # from the dropdown


	--SUBSTITUTE "party" with "party1-4", etc
	for _, wholething in TMW:Vararg(strsplit(";", unitSettings)) do
		local unit = strtrim(wholething)
		for k, v in pairs(TMW.Units) do
			if v.value == unit and v.range then
				unitSettings = gsub(unitSettings, wholething, unit .. "1-" .. v.range)
				break
			end
		end
	end

	--SUBSTITUTE RAID1-10 WITH RAID1;RAID2;RAID3;...RAID10
	local startpos, endpos = 0, 0
	for wholething, unit, firstnum, lastnum, append in gmatch(unitSettings, "((%a+) ?(%d+) ?%- ?(%d+) ?([%a]*)) ?;?") do
		if unit and firstnum and lastnum then
			local str = ""
			local order = firstnum > lastnum and -1 or 1

			if abs(lastnum - firstnum) > 100 then
				TMW:Print("Why on Earth would you want to track more than 100", unit, "units? I'll just ignore it and save you from possibly crashing.")
			else
				for i = firstnum, lastnum, order do
					str = str .. unit .. i .. append .. ";"
				end
				str = strtrim(str, " ;")
				wholething = gsub(wholething, "%-", "%%-") -- need to escape the dash for it to work
				unitSettings = gsub(unitSettings, wholething, str)
			end
		end
	end

	local Units = TMW:SplitNames(unitSettings) -- get a table of everything

	-- REMOVE DUPLICATES
	local k = #Units --start at the end of the table so that we dont remove duplicates at the beginning of the table
	while k > 0 do
		if select(2, tContains(Units, Units[k], true)) > 1 then
			tremove(Units, k) --if the current value occurs more than once then remove this entry of it
		else
			k = k - 1 --there are no duplicates, so move backwards towards zero
		end
	end

	return Units
end
TMW:MakeFunctionCached(UNITS, "GetOriginalUnitTable")

function UNITS:UpdateTankAndAssistMap()
	local mtMap, maMap = UNITS.mtMap, UNITS.maMap

	wipe(mtMap)
	wipe(maMap)

	-- setup a table with (key, value) pairs as (oldnumber, newnumber)
	-- oldnumber is 7 for raid7
	-- newnumber is 1 for raid7 when the current maintank/assist is the 1st one found, 2 for the 2nd one found, etc)
	for i = 1, GetNumRaidMembers() do
		local raidunit = "raid" .. i
		if GetPartyAssignment("MAINTANK", raidunit) then
			mtMap[#mtMap + 1] = i
		elseif GetPartyAssignment("MAINASSIST", raidunit) then
			maMap[#maMap + 1] = i
		end
	end
end

function UNITS:OnEvent(event, ...)

	if event == "RAID_ROSTER_UPDATE" and UNITS.doTankAndAssistMap then
		UNITS:UpdateTankAndAssistMap()
	end
	local instances = UnitSet.instances
	for i = 1, #instances do
		local unitSet = instances[i]
		if unitSet.updateEvents[event] then
			unitSet:Update()
		end
	end
end

function UNITS:SubstituteTankAndAssistUnit(oldunit, table, key, putInvalidUnitsBack)
	if strfind(oldunit, "^maintank") then -- the old unit (maintank1)
		local newunit = gsub(oldunit, "maintank", "raid") -- the new unit (raid1) (number not changed yet)
		local oldnumber = tonumber(strmatch(newunit, "(%d+)")) -- the old number (1)
		local newnumber = oldnumber and UNITS.mtMap[oldnumber] -- the new number(7)
		if newnumber then
			table[key] = gsub(newunit, oldnumber, newnumber)
			return true
		elseif putInvalidUnitsBack then
			table[key] = oldunit
		end
		return false -- placement of this inside the if block is crucial
	elseif strfind(oldunit, "^mainassist") then
		local newunit = gsub(oldunit, "mainassist", "raid")
		local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
		local newnumber = oldnumber and UNITS.maMap[oldnumber]
		if newnumber then
			table[key] = gsub(newunit, oldnumber, newnumber)
			return true
		elseif putInvalidUnitsBack then
			table[key] = oldunit
		end
		return false -- placement of this inside the if block is crucial
	end
end



