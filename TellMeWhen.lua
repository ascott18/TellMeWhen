-- ---------------------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- ---------------------------------

-- ---------------------------------
-- ADDON GLOBALS AND LOCALS
-- ---------------------------------

local TMW = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", "TMW", UIParent), "TellMeWhen", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0")
TellMeWhen = TMW
-- TMW is set globally through CreateFrame

local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
--L = setmetatable({}, {__index = function() return ("| ! "):rep(14) end}) -- stress testing for text widths
TMW.L = L
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local DRData = LibStub("DRData-1.0", true)

local DogTag = LibStub("LibDogTag-3.0", true)

TELLMEWHEN_VERSION = "6.0.0"
TELLMEWHEN_VERSION_MINOR = strmatch(" @project-version@", " r%d+") or ""
TELLMEWHEN_VERSION_FULL = TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR
TELLMEWHEN_VERSIONNUMBER = 60011 -- NEVER DECREASE THIS NUMBER (duh?).  IT IS ALSO ONLY INTERNAL
if TELLMEWHEN_VERSIONNUMBER > 61001 or TELLMEWHEN_VERSIONNUMBER < 60000 then return error("YOU SCREWED UP THE VERSION NUMBER OR DIDNT CHANGE THE SAFETY LIMITS") end -- safety check because i accidentally made the version number 414069 once

TELLMEWHEN_MAXROWS = 20

-- GLOBALS: TellMeWhen, LibStub
-- GLOBALS: TellMeWhenDB, TellMeWhen_Settings
-- GLOBALS: TELLMEWHEN_VERSION, TELLMEWHEN_VERSION_MINOR, TELLMEWHEN_VERSION_FULL, TELLMEWHEN_VERSIONNUMBER, TELLMEWHEN_MAXROWS
-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo
-- GLOBALS: UIParent, CreateFrame, collectgarbage, geterrorhandler 

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
local GetPartyAssignment, InCombatLockdown, IsInGuild =
      GetPartyAssignment, InCombatLockdown, IsInGuild
local GetNumBattlefieldScores, GetBattlefieldScore =
      GetNumBattlefieldScores, GetBattlefieldScore
local GetCursorPosition, GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn =
      GetCursorPosition, GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, next, assert, pcall, error, getmetatable, setmetatable, date, CopyTable, table, loadstring, rawset, debugstack =
      tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, select, wipe, rawget, next, assert, pcall, error, getmetatable, setmetatable, date, CopyTable, table, loadstring, rawset, debugstack
local strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, min, max, ceil, floor, abs, random =
      strfind, strmatch, format, gsub, gmatch, strsub, strtrim, strsplit, strlower, strrep, strchar, strconcat, min, max, ceil, floor, abs, random
local _G, GetTime =
      _G, GetTime
local CL_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local tostringall = tostringall
local bitband = bit.band
local huge = math.huge

---------- Locals ----------
local updatehandler, Locked, SndChan, FramesToFind, CNDTEnv, AnimationList
local NAMES, EVENTS, ANIM, ANN, SND
local UPD_INTV = 0.06	--this is a default, local because i use it in onupdate functions
local GCD, NumShapeshiftForms, LastUpdate, LastBindTextUpdate = 0, 0, 0, 0
local IconsToUpdate, GroupsToUpdate = {}, {}
local loweredbackup = {}
local callbackregistry = {}
local bullshitTable = {}
local ActiveAnimations = {}
local time = GetTime() TMW.time = time
local sctcolor = {r=1, b=1, g=1}
local clientVersion = select(4, GetBuildInfo())
local addonVersion = tonumber(GetAddOnMetadata("TellMeWhen", "X-Interface"))
TMW.ISMOP = clientVersion >= 50000
local _, pclass = UnitClass("Player")
local pname = UnitName("player")


if TMW.ISMOP then
	GetActiveTalentGroup = GetActiveSpecGroup
	GetPrimaryTalentTree = GetSpecialization
	local IsInGroup, IsInRaid, GetNumGroupMembers = 
	      IsInGroup, IsInRaid, GetNumGroupMembers
end

--TODO: (misplaced note) export any needed text layouts with icons that need them
--TODO: (misplaced note) change the way that icon events are fired. Consider using TMW's event framework to capture them instead of manual firings from within data processors.

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

function TMW.oneUpString(string)
	if string:find("%d+") then
		local num = tonumber(string:match("(%d+)"))
		if num then
			string = string:gsub(("(%d+)"), num + 1, 1)
			return string
		end
	end
end

local function ClearScripts(f)
	f:SetScript("OnEvent", nil)
	f:SetScript("OnUpdate", nil)
	if f:HasScript("OnValueChanged") then
		f:SetScript("OnValueChanged", nil)
	end
end

function TMW.print(...)
	if TMW.debug or not TMW.Initialized then
		local prefix = "|cffff0000TMW"
		-- GLOBALS: linenum
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
function TMW:Debug(...)
	TMW.print(format(...))
end

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

do -- TMW.generateGUID(length)
	local chars = {}
	for i = 33, 122 do
		if i ~= 94 and charbyte ~= 96 then
			chars[#chars + 1] = strchar(i)    
		end 
	end
	
	function TMW.generateGUID(length)
		assert(length and length > 6)
		
		-- the first 6 characters are based off of the current time.
		-- anything after the first 6 are random.
		
		-- a length of 10 gives		57289761 possible GUIDs at that exact milisecond the function was called. 
		-- a length of 12 gives 433626201009 possible GUIDs at that exact milisecond the function was called. 
		local currentTime = _G.time() + (GetTime() - floor(GetTime()))
		currentTime = format("%0.2f", currentTime)
		currentTime = gsub(currentTime, "%.", "")
		
		local GUID = ""
		for digits in gmatch(currentTime, "(..?)") do
			local len = #digits
			local percent = tonumber(digits)/(10^len)
			
			local char = chars[floor((#chars-1)*percent) + 1]
			GUID = GUID .. char
		end
		
		while #GUID < length do
			GUID = GUID .. chars[random(#chars)]
		end
		
		return strsub(GUID, 1, length)
	end
end

do -- Iterators

	do -- InConditionSettings
		local states = {}
		local function getstate(stage, currentCondition, extIter, extIterState)
			local state = wipe(tremove(states) or {})

			state.stage = stage
			state.extIter = extIter
			state.extIterState = extIterState
			state.currentCondition = currentCondition

			return state
		end

		local function iter(state)
			state.currentCondition = state.currentCondition + 1

			if not state.currentConditions or state.currentCondition > (state.currentConditions.n or #state.currentConditions) then
				local settings
				settings, state.cg, state.ci = state.extIter(state.extIterState)
				if not settings then
					if state.stage == "icon" then
						state.extIter, state.extIterState = TMW:InGroupSettings()
						state.stage = "group"
						return iter(state)
					else
						tinsert(states, state)
						return
					end
				end
				state.currentConditions = settings.Conditions
				state.currentCondition = 0
				return iter(state)
			end
			local condition = rawget(state.currentConditions, state.currentCondition)
			if not condition then return iter(state) end
			return condition, state.currentCondition, state.cg, state.ci -- condition data, conditionID, groupID, iconID
		end

		function TMW:InConditionSettings()
			return iter, getstate("icon", 0, TMW:InIconSettings())
		end
	end

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

		function TMW:InNLengthTable(arg)
			if arg then
				return iter, getstate(0, arg)
			else
				error("Bag argument #1 to 'TMW:InNLengthTable(arg)'. Expected table, got nil.")
			end
		end
	end

	do -- InIconSettings
		local states = {}
		local function getstate(cg, ci, mg, mi)
			local state = wipe(tremove(states) or {})

			state.cg = cg
			state.ci = ci
			state.mg = mg
			state.mi = mi

			return state
		end

		local function iter(state)
			local ci = state.ci
			ci = ci + 1	-- at least increment the icon
			while true do
				if ci <= state.mi and state.cg <= state.mg and not rawget(TMW.db.profile.Groups[state.cg].Icons, ci) then
					--if there is another icon and the group is valid but the icon settings dont exist, move to the next icon
					ci = ci + 1
				elseif state.cg <= state.mg and ci > state.mi then
					-- if there is another group and the icon exceeds the max, move to the first icon of the next group
					state.cg = state.cg + 1
					ci = 1
				elseif state.cg > state.mg then
					-- if there isnt another group, then stop
					tinsert(states, state)
					return
				else
					-- we finally found something valid, so use it
					break
				end
			end
			state.ci = ci
			return TMW.db.profile.Groups[state.cg].Icons[ci], state.cg, ci -- ics, groupID, iconID
		end

		function TMW:InIconSettings(groupID)
			return iter, getstate(groupID or 1, 0, groupID or TMW.db.profile.NumGroups, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS)
		end
	end

	do -- InGroupSettings
		local states = {}
		local function getstate(cg, mg)
			local state = wipe(tremove(states) or {})

			state.cg = cg
			state.mg = mg

			return state
		end

		local function iter(state)
			state.cg = state.cg + 1
			if state.cg > state.mg then
				tinsert(states, state)
				return
			end
			return TMW.db.profile.Groups[state.cg], state.cg -- setting table, groupID
		end

		function TMW:InGroupSettings()
			return iter, getstate(0, TMW.db.profile.NumGroups)
		end
	end

	do -- InIcons
		local states = {}
		local function getstate(cg, ci, mg, mi)
			local state = wipe(tremove(states) or {})

			state.cg = cg
			state.ci = ci
			state.mg = mg
			state.mi = mi

			return state
		end

		local function iter(state)
			state.ci = state.ci + 1
			while true do
				if state.ci <= state.mi and TMW[state.cg] and not TMW[state.cg][state.ci] then
					state.ci = state.ci + 1
				elseif state.cg < state.mg and (state.ci > state.mi or not TMW[state.cg]) then
					state.cg = state.cg + 1
					state.ci = 1
				elseif state.cg > state.mg then
					tinsert(states, state)
					return
				else
					break
				end
			end
			return TMW[state.cg] and TMW[state.cg][state.ci], state.cg, state.ci -- icon, groupID, iconID
		end

		function TMW:InIcons(groupID)
			return iter, getstate(groupID or 1, 0, groupID or TMW.db.profile.NumGroups, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS)
		end
	end

	do -- InGroups
		local states = {}
		local function getstate(cg, mg)
			local state = wipe(tremove(states) or {})

			state.cg = cg
			state.mg = mg

			return state
		end

		local function iter(state)
			local cg = state.cg + 1
			state.cg = cg
			if cg > state.mg then
				tinsert(states, state)
				return
			end
			return TMW[cg], cg -- group, groupID
		end

		function TMW:InGroups()
			return iter, getstate(0, TMW.db.profile.NumGroups)
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

		function TMW:Vararg(...)
			return iter, getstate(...)
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

do -- Callback Lib
	function TMW:RegisterCallback(event, func, arg1)
		local funcsForEvent
		if callbackregistry[event] then
			funcsForEvent = callbackregistry[event]
		else
			funcsForEvent = {}
			callbackregistry[event] = funcsForEvent
		end

		if type(func) == "table" then
			arg1 = func
			func = assert(func[event], ("Couldn't find method %q on table %q!"):format(event, tostring(func.GetName and func[0] and func:GetName() or func.name or func)))
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
		if type(func) == "table" then
			local object = func
			arg1 = object
			func = object[event]
		end
		arg1 = arg1 or true

		local funcs = callbackregistry[event]
		if funcs then
			for t = 1, #funcs do
				local tbl = funcs[t]
				if tbl.func == func then
					tDeleteItem(tbl, arg1)
				end
			end
		end
	end
	
	function TMW:Fire(event, ...)
		local funcs = callbackregistry[event]

		if funcs then
			for t = 1, #funcs do
				local tbl = funcs[t]
				local method = tbl.func
				if method then
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
	end
end

do -- Class Lib
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
	
	local function callFunc(class, instance, func, ...)
	
		-- check for all functions that dont match exactly, like OnNewInstance_1, _2, _3, ...
		-- functions can be named whatever you want, but a numbering system helps make sure that
		-- they are called in the order that you want them to be called in
		for k, v in pairs(class.instancemeta.__index) do
			if type(k) == "string" and k:find("^" .. func) and k ~= func then
				v(instance, ...)
			end
		end
		
		if instance.isTMWClassInstance then
			-- If this is being called on an instance of a class instead of a class,
			-- search the instance itself for matching functions too.
			-- This will never step on the toes of class.instancemeta.__index because
			-- iterating over an instance will only yield things explicity set on an instance -
			-- it will never directly contain anything inherited from a class.
			for k, v in pairs(instance) do
				if type(k) == "string" and k:find("^" .. func) and k ~= func then
					v(instance, ...)
				end
			end
		end
		
		
		-- now check for the function that exactly matches. this should be called last because
		-- it should be the function that handles the real class being instantiated, not any inherited classes
		local normalFunc = instance[func]
		if normalFunc then
			normalFunc(instance, ...)
		end
	end

	local function initializeClass(self)
		if not self.instances[1] then
			-- set any defined metamethods
			for k, v in pairs(self.instancemeta.__index) do
				if metamethods[k] then
					self.instancemeta[k] = v
				end
			end
			
			callFunc(self, self, "OnFirstInstance")
		end
	end
	
	local __call = function(self, arg)
		-- allow something like TMW:NewClass("Name"){Foo = function() end, Bar = 5}
		if type(arg) == "table" then
			for k, v in pairs(arg) do
				if k == "METHOD_EXTENSIONS" and type(v) == "table" then
					for methodName, func in pairs(v) do
						self:ExtendMethod(methodName, func)
					end
				else
					self[k] = v
				end
			end
		end
		return self
	end
	
	function TMW:NewClass(className, ...)
		local metatable = {
			__index = {},
			__call = __call,
		}
		
		local class = {
			className = className,
			instances = {},
			embeds = {},
			isTMWClass = true,
		}

		class.instancemeta = {__index = metatable.__index}
		
		setmetatable(class, metatable)
		metatable.__newindex = metatable.__index

		local isFrameObject
		for n, v in TMW:Vararg("Class", ...) do
			local index
			if TMW.Classes[v] then
				callFunc(TMW.Classes[v], TMW.Classes[v], "OnClassInherit", class)
				index = getmetatable(TMW.Classes[v]).__index
			elseif LibStub(v, true) then
				local lib = LibStub(v, true)
				if lib.Embed then
					lib:Embed(metatable.__index)
				else
					TMW:Error("Library %q does not have an Embed method", v)
				end
			elseif type(v) == "table" then
				index = v
			elseif n == 2 then
				local success, frame = pcall(CreateFrame, v)
				if success and frame then
					-- Need to do hide the frame or else if we made an editbox,
					-- it will block all keyboard input for some reason
					frame:Hide()
					isFrameObject = v
					
					index = getmetatable(frame).__index
				end
			end

			if index then
				for k, v in pairs(index) do
					metatable.__index[k] = metatable.__index[k] or v
				end
			end
		end
		
		class.isFrameObject = isFrameObject or class.isFrameObject
		rawset(class, "isFrameObject", rawget(class, "isFrameObject") or isFrameObject)
		
		metatable.__index.isFrameObject = metatable.__index.isFrameObject or isFrameObject

		TMW.Classes[className] = class
		
		TMW:Fire("TMW_CLASS_NEW", class)

		return class
	end
	
	-- Define the base class. All other classes implicitly inherit from this class.
	TMW:NewClass("Class"){
		New = function(self, ...)
			local instance
			if ... and self.isFrameObject then
				instance = CreateFrame(...)
			else
				instance = {}
			end

			-- if this is the first instance of the class, do some magic to it:
			initializeClass(self)

			instance.class = self
			instance.className = self.className
			instance.isTMWClassInstance = true

			setmetatable(instance, self.instancemeta)

			self.instances[#self.instances + 1] = instance
			
			for k, v in pairs(self.instancemeta.__index) do
				if self.isFrameObject and instance.HasScript and instance:HasScript(k) then
					instance:HookScript(k, v)
				end
			end

			callFunc(self, instance, "OnNewInstance", ...)
			
			TMW:Fire("TMW_CLASS_" .. self.className .. "_INSTANCE_NEW", self, instance)
			
			return instance
		end,

		Embed = function(self, target, canOverwrite)
			-- if this is the first instance (not really an instance here, but we need to anyway) of the class, do some magic to it:
			initializeClass(self)

			self.embeds[target] = true

			for k, v in pairs(self.instancemeta.__index) do
				if target[k] and not canOverwrite then
					TMW:Error("Error embedding class %s into target %s: Field %q already exists on the target.", self.className, tostring(target:GetName() or target), k)
				else
					target[k] = v
				end
			end
			
			for k, v in pairs(self.instancemeta.__index) do
				if self.isFrameObject and target.HasScript and target:HasScript(k) then
					target:HookScript(k, v)
				end
			end

			callFunc(self, target, "OnNewInstance")

			target.class = self
			target.className = self.className
			
			return target
		end,

		Disembed = function(self, target, clearDifferentValues)
			self.embeds[target] = false

			for k, v in pairs(self.instancemeta.__index) do
				if (target[k] == v) or (target[k] and clearDifferentValues) then
					target[k] = nil
				else
					TMW:Error("Error disembedding class %s from target %s: Field %q should exist on the target, but it doesnt.", self.className, tostring(target:GetName() or target), k)
				end
			end

			return target
		end,

		ExtendMethod = function(self, method, newFunction)
			local existingFunction = self[method]
			if existingFunction then
				self[method] = function(...)
					existingFunction(...)
					newFunction(...)
				end
			else
				self[method] = newFunction
			end
		end,
		
		AssertSelfIsClass = function(self)
			assert(self.isTMWClass, ("Caller must be the class %q, not an instance of the class"):format(self.className))
		end,
		
		AssertSelfIsInstance = function(self)
			assert(self.isTMWClassInstance, ("Caller must be an instance of the class %q, not the class itself"):format(self.className))
		end,
		
		AssertIsProtectedCall = function(self, message)
			-- debugstack can be a bit heavy on CPU usage, so use this sparingly
			
			local lineOne, lineTwo = ("\n"):split(debugstack(2))
			
			local func = lineOne:match("in function `(.*)'")
			local caller = lineTwo:match("in function `(.*)'")
			
			if not self[caller] then
				local method = self.className .. ":" .. func .. "()"
				if message then
					message = method .. " is a protected method and can only be called by methods within its own class. " .. message
				else
					message = method .. " is a protected method and can only be called by methods within its own class."
				end
				error(message, 3)
			end        
		end,
		
		InheritTable = function(self, sourceClass, tableKey)
			sourceClass:AssertSelfIsClass()
			
			self[tableKey] = {}
			for k, v in pairs(sourceClass[tableKey]) do
				self[tableKey][k] = v
			end
		end,
		
		CallFunc = function(self, funcName, ...)
			if self.isTMWClass then
				callFunc(self, self, funcName)
			else
				callFunc(self.class, self, funcName, ...)
			end
		end,
	}
end


local RelevantToAll = {
	__index = {
		SettingsPerView = true,
		Enabled = true,
		Name = true,
		Type = true,
		Events = true,
		Conditions = true,
		ShowWhen = true,
		Alpha = true,
		UnAlpha = true,
		ConditionAlpha = true
	}
}

TMW.Types = setmetatable({}, {
	__index = function(t, k)
		if type(k) == "table" and k.class == TMW.Classes.Icon then -- if the key is an icon, then return the icon's Type table
			TMW:Error("Type lookup by icon is depreciated. Lookup by icon type instead.")
			return t[k.Type]
		else -- if no type exists, then use the fallback (default) type
			return rawget(t, "")
		end
	end
}) local Types = TMW.Types
TMW.OrderedTypes = {}

TMW.Views = setmetatable({}, {
	__index = function(t, k)
		return rawget(t, "icon")
	end
}) local Views = TMW.Views
TMW.OrderedViews = {}

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
		DrawEdge		=	not TMW.ISMOP and false,
		SoundChannel	=	"SFX",
		ReceiveComm		=	true,
		WarnInvalids	=	false,
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
		TextLayouts = {
			["**"] = { -- layout defaults
				n					= 1,
				Name				= "",
				GUID				= "",
				NoEdit				= false,
				["**"] = { -- fontString defaults
					StringName		= "",
					Name 		  	= "Arial Narrow",
					Size 		  	= 12,
					x 	 		  	= 0,
					y 	 		  	= 0,
					point 		  	= "CENTER",
					relativePoint 	= "CENTER",
					Outline 	  	= "THICKOUTLINE",
					ConstrainWidth	= true,
					
					DefaultText		= "",
					SkinAs			= "",
				},
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
				View			= "icon",
				Name			= "",
				Strata			= "MEDIUM",
				Scale			= 2.0,
				Level			= 10,
				Rows			= 1,
				Columns			= 4,
				CheckOrder		= -1,
				PrimarySpec		= true,
				SecondarySpec	= true,
				Tree1			= true,
				Tree2			= true,
				Tree3			= true,
				LayoutDirection = 1,
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
				SettingsPerView			= {
					["**"] = {
						TextLayout		= "icon1",
						SpacingX		= 0,
						SpacingY		= 0,
					}
				},
				Icons = {
					["**"] = {
						ShowWhen				= 0x2, -- bit order: 0, 0, alpha, unalpha
						Enabled					= false,
						Name					= "",
						Type					= "",
						Alpha					= 1,
						UnAlpha					= 1,
						Icons					= {
							[1]					= "",
						},
						SettingsPerView			= {
							["**"] = {
								TextLayout		= "icon1",
								Texts = {
									["*"] 		= "",
								}
							}
						},
						Events 					= {
							n					= 0,
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
								PassThrough		= true,
								Icon			= "",
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
	MONK		= 100780, -- jab
} local GCDSpell = TMW.GCDSpells[pclass] TMW.GCDSpell = GCDSpell


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
		--prefixing with _ doesnt really matter here since casts only match by name, but it may prevent confusion if people try and use these as buff/debuff equivs
		Heals				= "50464;5185;8936;740;2050;2060;2061;32546;596;64843;635;82326;19750;331;77472;8004;1064;73920",
		PvPSpells			= "33786;339;20484;1513;982;64901;_605;453;5782;5484;79268;10326;51514;118;12051",
		Tier11Interrupts	= "_83703;_82752;_82636;_83070;_79710;_77896;_77569;_80734;_82411",
		Tier12Interrupts	= "_97202;_100094",
	},
	dr = {},
}

TMW.CompareFuncs = {
	-- harkens back to the days of the conditions of old, but it is actually more efficient than a big elseif chain.
	["=="] = function(a, b) return a == b  end,
	["~="] = function(a, b) return a ~= b end,
	[">="] = function(a, b) return a >= b end,
	["<="] = function(a, b) return a <= b  end,
	["<"] = function(a, b) return a < b  end,
	[">"] = function(a, b) return a > b end,
}
TMW.EventList = {
	{	-- OnIconShow
		name = "OnIconShow",
		text = L["SOUND_EVENT_ONICONSHOW"],
		desc = L["SOUND_EVENT_ONICONSHOW_DESC"],
		settings = {
			Icon = true,
		},
	},
	{	-- OnIconHide
		name = "OnIconHide",
		text = L["SOUND_EVENT_ONICONHIDE"],
		desc = L["SOUND_EVENT_ONICONHIDE_DESC"],
		settings = {
			Icon = true,
		},
	},
} for k, v in pairs(TMW.EventList) do TMW.EventList[v.name] = v end


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

function TMW:MakeSingleArgFunctionCached(obj, method)
	-- MakeSingleArgFunctionCached is MUCH more efficient than MakeFunctionCached
	-- and should be used whenever there is only 1 input arg
    local func
    if type(obj) == "table" and type(method) == "string" then
        func = obj[method]
    elseif type(obj) == "function" then
        func = obj
    else
        error("Usage: TMW:MakeFunctionCached(object/function [, method])")
    end

    local cache = {}
    local wrapper = function(arg1In, arg2In)
        if arg2In ~= nil then
            error("Cannot MakeSingleArgFunctionCached functions with more than 1 arg")
        end
		
        if cache[arg1In] then
            return cache[arg1In]
        end

        local arg1Out, arg2Out = func(arg1In)
        if arg2Out ~= nil then
            error("Cannot cache functions with more than 1 return arg")
        end

        cache[arg1In] = arg1Out

        return arg1Out
    end

    if type(obj) == "table" then
        obj[method] = wrapper
    end

    return wrapper
end



--[[-------- Tooltips ----------
	This used to be part of TellMeWhen_Options,
	but it is so much easier to have it here in case an icon/group module wants to use it.
]]
local function TTOnEnter(self)
	if self.__title or self.__text then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(TMW.get(self.__title, self), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
		GameTooltip:AddLine(TMW.get(self.__text, self), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, not self.__noWrapTooltipText)
		GameTooltip:Show()
	end
end
local function TTOnLeave(self)
	GameTooltip:Hide()
end

function TMW:TT(f, title, text, actualtitle, actualtext)
	-- setting actualtitle or actualtext true cause it to use exactly what is passed in for title or text as the text in the tooltip
	-- if these variables arent set, then it will attempt to see if the string is a global variable (e.g. "MAXIMUM")
	-- if they arent set and it isnt a global, then it must be a TMW localized string, so use that
	
	TMW:ValidateType(2, "TMW:TT()", f, "frame")
	
	if title then
		f.__title = (actualtitle and title) or _G[title] or L[title]
	else
		f.__title = title
	end

	if text then
		f.__text = (actualtext and text) or _G[text] or L[text]
	else
		f.__text = text
	end

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

function TMW:TT_Update(f)
	if f:IsMouseOver() and f:IsVisible() then
		f:GetScript("OnLeave")(f)
		if not f.IsEnabled or f:IsEnabled() or f:GetMotionScriptsWhileDisabled() then
			f:GetScript("OnEnter")(f)
		end
	end
end


---------- Table Copying ----------
function TMW:CopyWithMetatable(settings)
	local copy = {}
	for k, v in pairs(settings) do
		if type(v) == "table" then
			copy[k] = TMW:CopyWithMetatable(v)
		else
			copy[k] = v
		end
	end
	return setmetatable(copy, getmetatable(settings))
end

function TMW:CopyTableInPlaceWithMeta(src, dest, allowUnmatchedSourceTables)
	--src and dest must have congruent data structure, otherwise shit will blow up. There are no safety checks to prevent this.
	local metatemp = getmetatable(src) -- lets not go overwriting random metatables
	setmetatable(src, getmetatable(dest))
	for k in pairs(src) do
		if dest[k] and type(dest[k]) == "table" and type(src[k]) == "table" then
			TMW:CopyTableInPlaceWithMeta(src[k], dest[k], allowUnmatchedSourceTables)
		elseif type(src[k]) ~= "table" or allowUnmatchedSourceTables then
			dest[k] = src[k]
		end
	end
	setmetatable(src, metatemp) -- restore the old metatable
	return dest -- not really needed, but what the hell why not
end

function TMW:WipeTableDataRetainStructure(tbl)
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			TMW:WipeTableDataRetainStructure(v)
		else
			tbl[k] = nil
		end
	end
end


-- --------------------------
-- EXECUTIVE FUNCTIONS, ETC
-- --------------------------

function TMW:OnInitialize()
	LoadAddOn("LibDogTag-3.0")
	if not rawget(Views, "icon") then
		-- this also includes upgrading from older than 3.0 (pre-Ace3 DB settings)
		-- GLOBALS: StaticPopupDialogs, StaticPopup_Show, EXIT_GAME, CANCEL, ForceQuit
		StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE"], -- if the file is required for functionality
			--text = L["ERROR_MISSINGFILE_NOREQ"], -- if the file is NOT required for functionality
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMW_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "Views\\icon.lua")
		return -- if required, return here
	end

	if LibStub("LibButtonFacade", true) and select(6, GetAddOnInfo("Masque")) == "MISSING" then
		TMW.Warn("TellMeWhen no longer supports ButtonFacade. If you wish to continue to skin your icons, please upgrade to ButtonFacade's successor, Masque.")
	end

	TMW:ProcessEquivalencies()

	--------------- LSM ---------------
	LSM:Register("sound", "Rubber Ducky",  [[Sound\Doodad\Goblin_Lottery_Open01.wav]])
	LSM:Register("sound", "Cartoon FX",	   [[Sound\Doodad\Goblin_Lottery_Open03.wav]])
	LSM:Register("sound", "Explosion", 	   [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.wav]])
	LSM:Register("sound", "Shing!", 	   [[Sound\Doodad\PortcullisActive_Closed.wav]])
	LSM:Register("sound", "Wham!", 		   [[Sound\Doodad\PVP_Lordaeron_Door_Open.wav]])
	LSM:Register("sound", "Simon Chime",   [[Sound\Doodad\SimonGame_LargeBlueTree.wav]])
	LSM:Register("sound", "War Drums", 	   [[Sound\Event Sounds\Event_wardrum_ogre.wav]])
	LSM:Register("sound", "Cheer", 		   [[Sound\Event Sounds\OgreEventCheerUnique.wav]])
	LSM:Register("sound", "Humm", 		   [[Sound\Spells\SimonGame_Visual_GameStart.wav]])
	LSM:Register("sound", "Short Circuit", [[Sound\Spells\SimonGame_Visual_BadPress.wav]])
	LSM:Register("sound", "Fel Portal",    [[Sound\Spells\Sunwell_Fel_PortalStand.wav]])
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

	--------------- Events/OnUpdate ---------------
	CNDTEnv = TMW.CNDT.Env
	TMW:SetScript("OnUpdate", TMW.OnUpdate)

	TMW:RegisterEvent("PLAYER_ENTERING_WORLD")
	TMW:RegisterEvent("PLAYER_TALENT_UPDATE")
	TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
end

function TMW:Initialize()
	-- Everything in this function is either database initialization
	-- or other initialization processes that depend on the database being initialized.
	
	-- This all used to be handled in the OnInitialize method, but with the advent of 
	-- fully modular icon modules and types, we need to be able to handle default settings
	-- and setting upgrades from 3rd-party addons that load after TMW, and this isn't possible
	-- if upgrades and database initialization is done before those addons have a chance to load.
	
	if TMW.Initialized then 
		return
	end
	TMW.Initialized = true

	--------------- Database ---------------
	if type(TellMeWhenDB) ~= "table" then
		-- TellMeWhenDB might not exist if this is a fresh install
		-- or if the user is upgrading from a really old version that uses TellMeWhen_Settings.
		TellMeWhenDB = {Version = TELLMEWHEN_VERSIONNUMBER}
	end
	
	-- Handle upgrades that need to be done before defaults are added to the database.
	-- Primary purpose of this is to properly upgrade settings if a default has changed.
	TMW:GlobalUpgrade()

	-- Initialize the database
	TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
	
	-- Wipe the spell cache if user is running a new expansion (expansions have drastic spell changes)
	local XPac = tonumber(strsub(clientVersion, 1, 1))
	TMW.db.global.XPac = TMW.db.global.XPac or XPac
	if TMW.db.global.XPac ~= XPac then
		wipe(TMW.db.global.ClassSpellCache)
	end
	
	-- Handle normal upgrades after the database has been initialized.
	TMW:Upgrade()

	-- DEFAULT_ICON_SETTINGS is used for comparisons against a blank icon setup,
	-- most commonly used to see if the user has configured an icon at all.
	TMW.DEFAULT_ICON_SETTINGS = TMW.db.profile.Groups[0].Icons[0]
	TMW.db.profile.Groups[0] = nil


	
	--------------- Spell Caches ---------------
	TMW.ClassSpellCache = TMW.db.global.ClassSpellCache
	
	-- Adds a spell's texture to the texture cache by name
	-- so that we can get textures by spell name much more frequently,
	-- reducing the usage of question mark and pocketwatch icons.
	local function AddID(id)
		local name, _, tex = GetSpellInfo(id)
		name = strlowerCache[name]
		if name and not SpellTextures[name] then
			SpellTextures[name] = tex
		end
	end
	
	-- Spells of the user's class should be prioritized.
	for id in pairs(TMW.ClassSpellCache[pclass]) do
		AddID(id)
	end
	
	-- Next comes spells of all other classes.
	for class, tbl in pairs(TMW.ClassSpellCache) do
		if class ~= pclass and class ~= "PET" then
			for id in pairs(tbl) do
				AddID(id)
			end
		end
	end
	
	-- Pets are last because there are some overlapping names with class spells
	-- and we don't want to overwrite the textures for class spells with ones for pet spells.
	for id in pairs(TMW.ClassSpellCache.PET) do
		AddID(id)
	end

	-- Setup aura caching. It is currently only used for the spell suggestion list,
	-- but the code for it is in the main addon so that we can catch auras all the time.
	TellMeWhenDB.AuraCache = TellMeWhenDB.AuraCache or {}
	TMW.AuraCache = TellMeWhenDB.AuraCache
	TMW:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	
	
	
	--------------- Communications ---------------
	
	-- Channel TMW is used for sharing data.
	-- ReceiveComm is a setting that allows users to disable receiving shared data.
	if TMW.db.profile.ReceiveComm then
		TMW:RegisterComm("TMW")
	end
	
	-- Channel TMWV is used for version notifications.
	TMW:RegisterComm("TMWV")

	-- Send a version notification to the user's guild.
	if IsInGuild() then
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "GUILD")
	end
end

function TMW:OnProfile()
	for icon in TMW:InIcons() do
		icon:SetInfo("texture", "")
	end
	
	TMW:Upgrade()

	TMW:Update()
	
	-- LoadFirstValidIcon must happen through a timer to avoid interference with AceConfigDialog callbacks getting broken when
	-- we reload the icon editor. (AceConfigDialog-3.0\AceConfigDialog-3.0-57.lua:804: attempt to index field "rootframe" (a nil value))
	TMW.IE:ScheduleTimer("LoadFirstValidIcon", 0.1)

	if TMW.CompileOptions then
		TMW:CompileOptions() -- redo groups in the options
	end
end

TMW.DatabaseCleanups = {
	icon = function(ics, groupID, iconID)
		if ics.Events then
			for _, t in TMW:InNLengthTable(ics.Events) do
				t.SoundData = nil
				t.wasPassingCondition = nil
			end
		end
	end,
}
function TMW:ShutdownProfile()
	-- get rid of settings that are stored in database tables for convenience, but dont need to be kept.
	for ics, groupID, iconID in TMW:InIconSettings() do
		TMW.DatabaseCleanups.icon(ics, groupID, iconID)
	end
end

function TMW:ScheduleUpdate(delay)
	TMW:CancelTimer(updatehandler, 1)
	updatehandler = TMW:ScheduleTimer("Update", delay or 1)
end

function TMW:OnCommReceived(prefix, text, channel, who)
	if prefix == "TMWV" and strsub(text, 1, 1) == "M" and not TMW.VersionWarned and TMW.db.global.VersionWarning then
		local major, minor, revision = strmatch(text, "M:(.*)%^m:(.*)%^R:(.*)%^")
		TMW:Debug("%s has v%s%s (%s)", who, major, minor, revision)
		revision = tonumber(revision)
		if not (revision and major and minor and revision > TELLMEWHEN_VERSIONNUMBER and revision ~= 414069) then
			return
		elseif not ((minor == "" and who ~= "Cybeloras") or (tonumber(strsub(revision, 1, 3)) > tonumber(strsub(TELLMEWHEN_VERSIONNUMBER, 1, 3)) + 1)) then
			return
		end
		TMW.VersionWarned = true
		TMW:Printf(L["NEWVERSION"], major .. minor)
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


function TMW:OnUpdate()					-- THE MAGICAL ENGINE OF DOING EVERYTHING
	time = GetTime()
	CNDTEnv.time = time
	TMW.time = time

	if LastUpdate <= time - UPD_INTV then
		LastUpdate = time
		_, GCD=GetSpellCooldown(GCDSpell)
		CNDTEnv.GCD = GCD
		TMW.GCD = GCD

		TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_PRE", time, Locked)
		
		if Locked then
			for i = 1, #GroupsToUpdate do
				-- GroupsToUpdate only contains groups with conditions
				local group = GroupsToUpdate[i]
				local ConditionObj = group.ConditionObj
				if ConditionObj and (ConditionObj.UpdateNeeded or ConditionObj.NextUpdateTime < time) then
					ConditionObj:Check(group)
				end
			end
	
			for i = 1, #IconsToUpdate do
				--local icon = IconsToUpdate[i]
				IconsToUpdate[i]:Update()
			end

			for g = 1, #TMW do
				local group = TMW[g]
				if group.shouldSortIcons and group.iconSortNeeded then
					group:SortIcons()
					group.iconSortNeeded = nil
				end
			end
		end

		TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_POST", time, Locked)
	end

	TMW:Fire("TMW_ONUPDATE", time, Locked)
end


function TMW:Update()
	TMW:Initialize()
	
	time = GetTime() TMW.time = time
	LastUpdate = 0

	Locked = TMW.db.profile.Locked
	TMW.Locked = Locked

	if not Locked then
		TMW:LoadOptions()
	end
	
	TMW:Fire("TMW_GLOBAL_UPDATE") -- the placement of this matters. Must be after options load, but before icons are updated

	UPD_INTV = TMW.db.profile.Interval + 0.001 -- add a very small amount so that we don't call the same icon multiple times (through metas/conditionicons) in the same frame if the interval has been set 0

	SndChan = TMW.db.profile.SoundChannel

	for key, Type in pairs(TMW.Types) do
		--wipe(Type.Icons)
		Type:Update()
		Type:UpdateColors(true)
	end

	for groupID = 1, max(TMW.db.profile.NumGroups, #TMW) do
		-- cant use TMW.InGroups() because groups wont exist yet on the first call of this, so they would never be able to exists
		-- even if it shouldn't be setup (i.e. it has been deleted or the user changed profiles)
		local group = TMW[groupID] or TMW.Classes.Group:New("Frame", "TellMeWhen_Group" .. groupID, TMW, "TellMeWhen_GroupTemplate", groupID)
		TMW.safecall(group.Setup, group)
	end

	for key, Type in pairs(TMW.Types) do
		Type:Update(true)
	end

	if not Locked then
		TMW:DoValidityCheck()
	end

	TMW:ScheduleTimer("DoWarn", 3)

	TMW:Fire("TMW_GLOBAL_UPDATE_POST")
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


TMW.UpgradeTable = {}
TMW.UpgradeTableByVersions = {}
function TMW:GetBaseUpgrades()			-- upgrade functions
	return {
		[60008] = {
			icon = function(self, ics, ...)
				if ics.ShowWhen == "alpha" or ics.ShowWhen == nil then
					ics.ShowWhen = 0x2
				elseif ics.ShowWhen == "unalpha" then
					ics.ShowWhen = 0x1
				elseif ics.ShowWhen == "always" then
					ics.ShowWhen = 0x3
				end
			end,
		},
		[60005] = {
			group = function(self, gs)
				gs.SettingsPerView.icon.SpacingX = gs.Spacing or 0
				gs.SettingsPerView.icon.SpacingY = gs.Spacing or 0
				gs.Spacing = nil
			end,
		},
		[51023] = {
			icon = function(self, ics)
				ics.InvertBars = nil
			end,
		},
		[51019] = {
			textlayout = function(self, settings, GUID)
				-- I don't know why this layout exists, but I know it was my fault, so I am going to delete it.
				if GUID == "icon" and settings.GUID == "" then
					TMW.db.profile.TextLayouts[GUID] = nil
					TMW.Warn("TMW has deleted the invalid text layout keyed as 'icon' that was probably causing errors for you. If you were using it on any of your icons, then I apologize, but you probably weren't because it probably wasn't even named")
				end
			end,
		},
		[51008] = {
			condition = function(self, condition)
				if condition.Type == "TOTEM1"
				or condition.Type == "TOTEM2"
				or condition.Type == "TOTEM3"
				or condition.Type == "TOTEM4"
				then
					condition.Name = ""
				end
			end,
		},
		[51006] = {
			global = function(self)
				if TMW.db.profile.MasterSound then
					TMW.db.profile.SoundChannel = "Master"
				else
					TMW.db.profile.SoundChannel = "SFX"
				end
				TMW.db.profile.MasterSound = nil
			end,
		},
		[51003] = {
			pairs = {
				"Bind",
				"Count",
			},
			Count = {
				ConstrainWidth  = false,
				point           = "BOTTOMRIGHT",
				relativePoint   = "BOTTOMRIGHT",
				
				Name            = "Arial Narrow",
				Size            = 12,
				x               = -2,
				y               = 2,
				Outline         = "THICKOUTLINE",
			},
			Bind = {
				y               = -2,
				point           = "TOPLEFT",
				relativePoint   = "TOPLEFT",
				
				Name            = "Arial Narrow",
				Size            = 12,
				x               = -2,
				Outline         = "THICKOUTLINE",
				ConstrainWidth  = true,
			},
			deepcompare = function(self,t1,t2)
				local ty1 = type(t1)
				local ty2 = type(t2)
				if ty1 ~= ty2 then return false end
				-- non-table types can be directly compared
				if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
				for k1,v1 in pairs(t1) do
					local v2 = t2[k1]
					if v2 == nil or not self:deepcompare(v1,v2) then return false end
				end
				for k2,v2 in pairs(t2) do
					local v1 = t1[k2]
					if v1 == nil or not self:deepcompare(v1,v2) then return false end
				end
				return true
			end,
			SetLayoutToGroup = function(self, groupID, GUID)
				TMW.db.profile.Groups[groupID].SettingsPerView.icon.TextLayout = GUID
				-- the group setting is a fallback for icons, so there is no reason to set the layout for individual icons
				for ics in TMW:InIconSettings(groupID) do
					ics.SettingsPerView.icon.TextLayout = ""
				end
			end,
			
			group = function(self, gs, groupID)
				local layout = TMW.db.profile.TextLayouts[0]
				TMW.db.profile.TextLayouts[0] = nil
				layout.n = 2
				
				layout[1].StringName = L["TEXTLAYOUTS_DEFAULTS_BINDINGLABEL"]
				layout[1].SkinAs = "HotKey" 
				
				layout[2].StringName = L["TEXTLAYOUTS_DEFAULTS_STACKS"]
				layout[2].DefaultText = "[Stacks:Hide('0', '1')]"
				layout[2].SkinAs = "Count"
				
				for i = 1, layout.n do
					local fontStringSettings = layout[i]
					local settingsKey = self.pairs[i]
					local source = gs.Fonts and gs.Fonts[settingsKey]
					for _, setting in TMW:Vararg(
						"Name" ,
						"Size",
						"x",
						"y",
						"point",
						"relativePoint",
						"Outline",
						"OverrideLBFPos",
						"ConstrainWidth"
					) do
						if not source or source[setting] == nil then
							fontStringSettings[setting] = self[settingsKey][setting]
						else
							fontStringSettings[setting] = source[setting]
						end
					end
					
					if fontStringSettings.OverrideLBFPos then
						fontStringSettings.SkinAs = ""
						fontStringSettings.OverrideLBFPos = nil
					end
					
					-- this typo (MONOCHORME) has probably been here at least a year and nobody has noticed... until now
					if fontStringSettings.Outline == "MONOCHORME" then
						fontStringSettings.Outline = "MONOCHROME"
					end
				end
				
				for GUID, layoutSettings in pairs(TMW.db.profile.TextLayouts) do
					if layoutSettings ~= layout then
						local name, GUID, noedit = layoutSettings.Name, layoutSettings.GUID, layoutSettings.NoEdit
						layoutSettings.Name, layoutSettings.GUID, layoutSettings.NoEdit = "", "", false
						
						local isDuplicate = self:deepcompare(layoutSettings, layout)
						
						layoutSettings.Name, layoutSettings.GUID, layoutSettings.NoEdit = name, GUID, noedit
						
						if isDuplicate then
							self:SetLayoutToGroup(groupID, GUID)
							return
						end
					end
				end
				
				local GUID = TMW.generateGUID(12)
				TMW.db.profile.TextLayouts[GUID] = layout
				layout.GUID = GUID
				local Name = L["TEXTLAYOUTS_DEFAULTS_ICON1"]
				repeat
					local found
					for k, layoutSettings in pairs(TMW.db.profile.TextLayouts) do
						if layoutSettings.Name == Name then
							Name = TMW.oneUpString(Name) or GUID -- fallback on the GUID if we cant increment the name for some reason
							found = true
							break
						end
					end
				until not found
				
				layout.Name = Name
				self:SetLayoutToGroup(groupID, GUID)
				
			--	gs.Fonts = nil --TODO: don't nil this yet, i just might revert this whole system. once you get to release time, create a new upgrade to nil this
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
			
			icon = function(self, ics)
				local BindText = ics.BindText or ""
				if ics.Type ~= "meta" and ics.Type ~= "" then
					ics.SettingsPerView.icon.Texts[1] = self:translateString(BindText)
				end
				ics.BindText = nil
				
				ics.SettingsPerView.icon.Texts[2] = "[Stacks:Hide('0', '1')]"
				
				for _, eventSettings in TMW:InNLengthTable(ics.Events) do
					eventSettings.Text = self:translateString(eventSettings.Text)
					if eventSettings.Channel == "WHISPER" then
						eventSettings.Location = self:translateString(eventSettings.Location)
					end
				end
			end,
		},
		[50028] = {
			icon = function(self, ics)
				local Events = ics.Events
				for _, eventSettings in ipairs(Events) do -- dont use InNLengthTable here
					local eventData = TMW.EventList[eventSettings.Event]
					if eventData and eventData.applyDefaultsToSetting then
						eventData.applyDefaultsToSetting(eventSettings)
					end
				end
			end,
		},
		[50020] = {
			icon = function(self, ics)
				local Events = ics.Events
				for event, eventSettings in pairs(CopyTable(Events)) do -- dont use InNLengthTable here
					if type(event) == "string" and event ~= "n" then
						local addedAnEvent
						for moduleName, Module in EVENTS:IterateModules() do
							local hasHandlerOfType = Module:ProcessIconEventSettings(event, eventSettings)
							if type(rawget(Events, "n") or 0) == "table" then
								Events.n = 0
							end
							if hasHandlerOfType then
								Events.n = (rawget(Events, "n") or 0) + 1
								Events[Events.n] = CopyTable(eventSettings)
								Events[Events.n].Type = moduleName
								Events[Events.n].Event = event
								Events[Events.n].PassThrough = true

								addedAnEvent = true
							end
						end

						-- the last new event added for each original event should retain
						-- the original PassThrough setting instead of being forced to be true (Events[Events.n].PassThrough = true)
						-- in order to retain previous functionality
						if addedAnEvent then
							Events[Events.n].PassThrough = eventSettings.PassThrough
						end
						Events[event] = nil
					end
				end
			end,
		},
		[48025] = {
			icon = function(self, ics)
				ics.Name = gsub(ics.Name, "(CrowdControl)", "%1; " .. GetSpellInfo(339))
			end,
		},
		[48010] = {
			icon = function(self, ics)
				-- OnlyShown was disabled for OnHide (not togglable anymore), so make sure that icons dont get stuck with it enabled
				local OnHide = rawget(ics.Events, "OnHide")
				if OnHide then
					OnHide.OnlyShown = false
				end
			end,
		},
		[47321] = {
			icon = function(self, ics)
				ics.Events["**"] = nil -- wtf?
			end,
		},
		[47320] = {
			icon = function(self, ics)
				for _, Event in TMW:InNLengthTable(ics.Events) do
					-- these numbers got really screwy (0.8000000119), put then back to what they should be (0.8)
					Event.Duration 	= Event.Duration  and tonumber(format("%0.1f",	Event.Duration))
					Event.Magnitude = Event.Magnitude and tonumber(format("%1f",	Event.Magnitude))
					Event.Period  	= Event.Period    and tonumber(format("%0.1f",	Event.Period))
				end
			end,
		},
		[47204] = {
			icon = function(self, ics)
				if ics.Type == "conditionicon"  then
					ics.CustomTex = ics.Name or ""
					ics.Name = ""
				end
			end,
		},
		--[[
		-- Commented out 6-22-12 - Meta icons can be FakeHidden as of a long time ago, so there is no reason to do this anymore
		[47017] = {
			icon = function(self, ics)
				if ics.Type == "meta"  then
					ics.FakeHidden = false
				end
			end,
		},]]
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
					local old = TMW.db.profile[oldKey]
					local new = TMW.db.profile.Colors.GLOBAL[newKey]

					if old then
						for k, v in pairs(old) do
							new[k] = v
						end

						TMW.db.profile[oldKey] = nil
					end
				end

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
		[46417] = {
			-- cant use the conditions key here because it depends on Conditions.n, which is 0 until this is ran
			-- also, dont use TMW:InNLengthTable because it will use conditions.n, which is 0 until the upgrade is complete
			group = function(self, gs)
				local n = 0
				for k in pairs(gs.Conditions) do
					if type(k) == "number" then
						n = max(n, k)
					end
				end
				gs.Conditions.n = n
			end,
			icon = function(self, ics)
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
			icon = function(self, ics)
				if ics.CooldownType == "item" and ics.Type == "cooldown" then
					ics.Type = "item"
					ics.CooldownType = TMW.Icon_Defaults.CooldownType
				end
			end,
		},
		[45802] = {
			icon = function(self, ics)
				for k, condition in TMW:InNLengthTable(ics.Conditions) do
					if type(k) == "number" and condition.Type == "CASTING" then
						condition.Name = ""
					end
				end
			end,
		},
		[45608] = {
			icon = function(self, ics)
				if not ics.ShowTimer then
					ics.ShowTimerText = false
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
		[45013] = {
			icon = function(self, ics)
				if ics.Type == "conditionicon" then
					ics.Alpha = 1
					ics.UnAlpha = ics.ConditionAlpha or 0
					ics.ConditionAlpha = 0
				end
			end,
		},
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
		[44202] = {
			icon = function(self, ics)
				ics.Conditions["**"] = nil
			end,
		},
		[44009] = {
			global = function(self)
				if type(TMW.db.profile.WpnEnchDurs) == "table" then
					for k, v in pairs(TMW.db.profile.WpnEnchDurs) do
						TMW.db.global.WpnEnchDurs[k] = max(TMW.db.global.WpnEnchDurs[k] or 0, v)
					end
					TMW.db.profile.WpnEnchDurs = nil
				end
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
		[43009] = {
			icon = function(self, ics)
				for _, v in TMW:InNLengthTable(ics.Events) do
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
			icon = function(self, ics)
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
			global = function(self)
				-- at first glance, this should be a group upgrade,
				-- but it is actually a global upgrade.
				-- we dont want to do it to individual groups that have been imported
				-- because TMW.db.profile.Font wont exist at that point.
				-- we only want to do it to groups that exist in whatever profile is being upgraded
				if TMW.db.profile.Font then
					for gs in TMW:InGroupSettings() do
						gs.Font = gs.Font or {}
						for k, v in pairs(TMW.db.profile.Font) do
							gs.Font[k] = v
						end
					end
					TMW.db.profile.Font = nil
				end
			end,
		},
		[42105] = {
			-- cleanup some old stuff that i noticed is sticking around in my settings, probably in other peoples' settings too
			icon = function(self, ics)
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
				for _, t in TMW:InNLengthTable(ics.Events) do
					if t.Sound == "" then -- major screw up
						t.Sound = "None"
					end
				end
			end,
		},
		[42103] = {
			icon = function(self, ics)
				for _, t in TMW:InNLengthTable(ics.Events) do
					if t.Announce then
						t.Text, t.Channel = strsplit("\001", t.Announce)
						t.Announce = nil
					end
				end
			end,
		},
		[42102] = {
			icon = function(self, ics)
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
			group = function(self, gs)
				gs.Point.defined = nil
			end,
		},
		[41301] = {
			group = function(self, gs)
				local Conditions = gs.Conditions

				--[[if gs.OnlyInCombat then
					local condition = Conditions[#Conditions + 1]
					condition.Type = "COMBAT"
					condition.Level = 0
					gs.OnlyInCombat = nil
				end]]
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
			icon = function(self, ics)
				for k, condition in pairs(ics.Conditions) do
					if type(k) == "number" and condition.Type == "STANCE" then
						condition.Operator = "=="
					end
				end
			end,
		},
		[41008] = {
			icon = function(self, ics)
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
		[41004] = {
			icon = function(self, ics)
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
			global = function(self)
				TMW.db.profile.Revision = nil-- unused
			end,
		},
		[40115] = {
			icon = function(self, ics)
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
			icon = function(self, ics)
				for k, condition in pairs(ics.Conditions) do
					if type(k) == "number" and condition.Type == "CASTING" then
						condition.Level = condition.Level + 1
					end
				end
			end,
		},
		[40111] = {
			icon = function(self, ics)
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
			icon = function(self, ics)
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
			global = function(self)
				TMW.db.profile["BarGCD"] = true
				TMW.db.profile["ClockGCD"] = true
			end,
			icon = function(self, ics)
				for k, condition in pairs(ics.Conditions) do
					if type(k) == "number" and condition.Type == "NAME" then
						condition.Level = 0
					end
				end
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
			icon = function(self, ics)
				for k, v in pairs(ics.Conditions) do
					if type(k) == "number" and v.Type == "ECLIPSE_DIRECTION" and v.Level == -1 then
						v.Level = 0
					end
				end
			end,
		},
		[40060] = {
			global = function(self)
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
			global = function(self)
				TMW.db.profile.Spacing = nil
			end,
		},
		[40000] = {
			global = function(self)
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
			global = function(self)
				TMW.db.profile.NumGroups = 10
				TMW.db.profile.Condensed = nil
				TMW.db.profile.NumCondits = nil
				TMW.db.profile.DSN = nil
				TMW.db.profile.UNUSEColor = nil
				TMW.db.profile.USEColor = nil
				if TMW.db.profile.Font and TMW.db.profile.Font.Outline == "THICK" then TMW.db.profile.Font.Outline = "THICKOUTLINE" end --oops
			end,
			group = function(self, gs)
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
			icon = function(self, ics, groupID, iconID)
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
					TMW.db.profile.Groups[groupID].Icons[iconID] = nil
				end
			end,
		},
		[24100] = {
			icon = function(self, ics)
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
			icon = function(self, ics)
				ics.Name = gsub(ics.Name, "StunnedOrIncapacitated", "Stunned;Incapacitated")
				ics.Name = gsub(ics.Name, "IncreasedSPboth", "IncreasedSPsix;IncreasedSPten")
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
		[22010] = {
			icon = function(self, ics)
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
			icon = function(self, ics)
				for k, v in ipairs(ics.Conditions) do
					if type(k) == "number" and ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
						v.ConditionLevel = 0
					end
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
		[20100] = {
			icon = function(self, ics)
				for k, v in ipairs(ics.Conditions) do
					v.ConditionLevel = tonumber(v.ConditionLevel) or 0
					if type(k) == "number" and ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
						v.ConditionLevel = ceil((v.ConditionLevel/100)*3)
					end
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
			global = function(self)
				TMW.db.profile.Spec = nil
			end,
		},

	}
end

function TMW:RegisterUpgrade(version, data)
	assert(not data.Version, "Upgrade data cannot store a value with key 'Version' because it is a reserved key.")
	
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
					:format(k, version))
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
function TMW:UpdateUpgradeTable()
	sort(TMW.UpgradeTable, TMW.UpgradeTableSorter)
end
function TMW:GetUpgradeTable()	
	if not TMW.ProcessedBaseUpgrades then		
		for version, data in pairs(TMW:GetBaseUpgrades()) do
			TMW:RegisterUpgrade(version, data)
		end
		
		TMW.ProcessedBaseUpgrades = true
	end
	
	TMW:UpdateUpgradeTable()
	
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
		if TellMeWhenDB.Version < 50035 then
			for _, p in pairs(TellMeWhenDB.profiles) do
				if p.Groups then
					for _, gs in pairs(p.Groups) do
						if gs.Icons then
							for _, ics in pairs(gs.Icons) do
								if ics.Events then
									for k, eventSettings in pairs(ics.Events) do
										if type(eventSettings) == "table" and eventSettings.PassThrough == nil then
											eventSettings.PassThrough = false
										end
									end
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



do	-- TMW.safecall
	-- (Please please please don't ever use this anywhere that efficiency matters, because honestly, its atrocious. One of the things that I really don't like about Ace3)
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
		-- is smart enough to check when they need it so we dont need to check when we probably dont need to.
		--  if type(func) == "function" then
			return Dispatchers[select('#', ...)](func, ...)
		-- end
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
	
	if reqType == "frame" and varType == "table" and type(var[0]) == "userdata" then
		varType = "frame"
	end
	if varType ~= reqType then
		error(("Bad argument #%d to %q. %s expected, got %s"):format(argN, methodName, reqType, varType), 3)
	end
	
end



function TMW:Upgrade()
	-- Set the version for the current profile to the current version if it is a new profile.
	TMW.db.profile.Version = TMW.db.profile.Version or TELLMEWHEN_VERSIONNUMBER
	
	if TellMeWhen_Settings or (type(TMW.db.profile.Version) == "string") or (TMW.db.profile.Version < TELLMEWHEN_VERSIONNUMBER) then
		if TellMeWhen_Settings then -- needs to be first
			for k, v in pairs(TellMeWhen_Settings) do
				TMW.db.profile[k] = v
			end
			TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
			TMW.db.profile.Version = TellMeWhen_Settings.Version
			TellMeWhen_Settings = nil
		end
		if type(TMW.db.profile.Version) == "string" then
			local v = gsub(TMW.db.profile.Version, "[^%d]", "") -- remove decimals
			v = v..strrep("0", 5-#v)	-- append zeroes to create a 5 digit number
			TMW.db.profile.Version = tonumber(v)
		end

		TMW:DoUpgrade("global", TMW.db.profile.Version)
	end
	
	-- Must set callbacks after TMW:Upgrade() because the db is overwritten there when upgrading from 3.0.0
	TMW.db.RegisterCallback(TMW, "OnProfileChanged",	"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnProfileCopied",		"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnProfileReset",		"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnNewProfile",		"OnProfile")
	TMW.db.RegisterCallback(TMW, "OnProfileShutdown",	"ShutdownProfile")
	TMW.db.RegisterCallback(TMW, "OnDatabaseShutdown",	"ShutdownProfile")
end

function TMW:DoUpgrade(type, version, ...)
	assert(_G.type(type) == "string")
	assert(_G.type(version) == "number")
	
	TMW.HaveUpgradedOnce = true
	
	-- upgrade the actual requested setting
	for k, v in ipairs(TMW:GetUpgradeTable()) do
		if v.Version > version then
			if v[type] then
				v[type](v, ...)
			end
		end
	end

	-- delegate out to sub-types
	if type == "global" then
		-- delegate to groups
		for gs, groupID in TMW:InGroupSettings() do
			TMW:DoUpgrade("group", version, gs, groupID)
		end
		
		-- delegate to textlayouts
		for GUID, settings in pairs(TMW.db.profile.TextLayouts) do
			TMW:DoUpgrade("textlayout", version, settings, GUID)
		end
		
		--All Upgrades Complete
		TMW.db.profile.Version = TELLMEWHEN_VERSIONNUMBER
	elseif type == "group" then
		local gs, groupID = ...
		
		-- delegate to icons
		for ics, groupID, iconID in TMW:InIconSettings(groupID) do
			TMW:DoUpgrade("icon", version, ics, groupID, iconID)
		end
		
		-- delegate to conditions
		for conditionID, condition in TMW:InNLengthTable(gs.Conditions) do
			TMW:DoUpgrade("condition", version, condition, conditionID, groupID)
		end
		
	elseif type == "icon" then
		local ics, groupID, iconID = ...
		-- delegate to conditions
		for conditionID, condition in TMW:InNLengthTable(ics.Conditions) do
			TMW:DoUpgrade("condition", version, condition, conditionID, groupID, iconID)
		end
		
	elseif type == "textlayout" then
		-- no delegating needed
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
		-- GLOBALS: INTERFACEOPTIONS_ADDONCATEGORIES, InterfaceAddOnsList_Update
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
	if not TMW.db.profile.WarnInvalids then return end

	local str = icon .. "^" .. groupID .. "^" .. (iconID or "nil") .. "^" .. g .. "^" .. i

	TMW.ValidityCheckQueue[str] = 1
end

function TMW:DoValidityCheck()
	for str in pairs(TMW.ValidityCheckQueue) do
		local icon, groupID, iconID, g, i = strsplit("^", str)
		icon = _G[icon]
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

function TMW.OnGCD(d)
	if d == 1 then return true end -- a cd of 1 is always a GCD (or at least isn't worth showing)
	if GCD > 1.7 then return false end -- weed out a cooldown on the GCD spell that might be an interupt (counterspell, mind freeze, etc)
	return GCD == d and d > 0 -- if the duration passed in is the same as the GCD spell, and the duration isnt zero, then it is a GCD
end local OnGCD = TMW.OnGCD

function TMW:PLAYER_ENTERING_WORLD()
	TMW.EnteredWorld = true
	
	TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "RAID")
	TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "PARTY")
	TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "BATTLEGROUND")
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

function TMW:PLAYER_TALENT_UPDATE()
	if not TMW.AddedTalentsToTextures then
		if TMW.ISMOP then
			for talent = 1, MAX_NUM_TALENTS do
				local name, tex = GetTalentInfo(talent)
				local lower = name and strlowerCache[name]
				if lower then
					SpellTextures[lower] = tex
				end
			end
		else
			for tab = 1, GetNumTalentTabs() do
				for talent = 1, GetNumTalents(tab) do
					local name, tex = GetTalentInfo(tab, talent)
					local lower = name and strlowerCache[name]
					if lower then
						SpellTextures[lower] = tex
					end
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

function TMW:ProcessEquivalencies()
	for dispeltype, icon in pairs(TMW.DS) do
	--	SpellTextures[dispeltype] = icon
		SpellTextures[strlower(dispeltype)] = icon
	end

	if DRData then
		local myCategories = {
			ctrlstun		= "DR-ControlledStun",
			scatters		= "DR-Scatter",
			fear 			= "DR-Fear",
			rndstun			= "DR-RandomStun",
			silence			= "DR-Silence",
			banish 			= "DR-Banish",
			mc 				= "DR-MindControl",
			entrapment		= "DR-Entrapment",
			taunt 			= "DR-Taunt",
			disarm			= "DR-Disarm",
			horror			= "DR-Horrify",
			cyclone			= "DR-Cyclone",
			rndroot			= "DR-RandomRoot",
			disorient		= "DR-Disorient",
			ctrlroot		= "DR-ControlledRoot",
			dragons			= "DR-DragonsBreath",
			bindelemental	= "DR-BindElemental",
			charge			= "DR-Charge",
			intercept		= "DR-Intercept",
		}
		-- correction for ring of frost
		DRData.spells[82691] = DRData.spells[82676]
		--DRData.spells[82676] = nil -- dont feel like doing this. it technically isn't invalid, just incorrect, so I won't mess with it
		
		local dr = TMW.BE.dr
		for spellID, category in pairs(DRData.spells) do
			local k = myCategories[category] or TMW:Error("The DR category %q is undefined!", category)
			if k then
				dr[k] = (dr[k] and (dr[k] .. ";" .. spellID)) or tostring(spellID)
			end
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
						
						
						-- TODO: REINSTATE THIS CHECK AND UPDATE ALL EQUIVS FOR MOP
						if clientVersion >= addonVersion then -- dont warn for old clients using newer versions
						--	TMW:Error("Invalid spellID found: %s! Please report this on TMW's CurseForge page, especially if you are currently on the PTR!", realID)
						end
						
						
						str = gsub(str, id, realID) -- still need to substitute it to prevent recusion
					end
				end
			end
			TMW.BE[category][equiv] = str
		end
	end
end


local UpdateTableManager = TMW:NewClass("UpdateTableManager")
function UpdateTableManager:UpdateTable_Set(table)
	self.UpdateTable_UpdateTable = table or {} -- create an anonymous table if one wasnt passed in
end
function UpdateTableManager:UpdateTable_Register(target)
	assert(self.UpdateTable_UpdateTable, "No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	target = target or self

	local oldLength = #self.UpdateTable_UpdateTable

	if not tContains(self.UpdateTable_UpdateTable, target) then
		tinsert(self.UpdateTable_UpdateTable, target)
	
		if oldLength == 0 and self.UpdateTable_OnUsed then
			self:UpdateTable_OnUsed()
		end
	end
end
function UpdateTableManager:UpdateTable_Unregister(target)
	assert(self.UpdateTable_UpdateTable, "No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	target = target or self

	local oldLength = #self.UpdateTable_UpdateTable

	TMW.tDeleteItem(self.UpdateTable_UpdateTable, target, true)
	
	if oldLength > 0 and #self.UpdateTable_UpdateTable == 0 and self.UpdateTable_OnUnused then
		self:UpdateTable_OnUnused()
	end
end
function UpdateTableManager:UpdateTable_UnregisterAll()
	assert(self.UpdateTable_UpdateTable, "No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")

	local oldLength = #self.UpdateTable_UpdateTable
	
	wipe(self.UpdateTable_UpdateTable)
	
	if oldLength > 0 and self.UpdateTable_OnUnused then
		self:UpdateTable_OnUnused()
	end
end
function UpdateTableManager:UpdateTable_Sort(func)
	assert(self.UpdateTable_UpdateTable, "No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")

	sort(self.UpdateTable_UpdateTable, func)
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

	addids("focus")
	addids("focustarget")
	addids("focustargettarget")

	addids("pet")
	addids("pettarget")
	addids("pettargettarget")

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
		CUSTOM_CLASS_COLORS:RegisterCallback("UpdateClassColors", NAMES)
	end
	NAMES:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
	NAMES:RegisterEvent("UPDATE_WORLD_STATES", "UPDATE_BATTLEFIELD_SCORE")
	NAMES:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function NAMES:UPDATE_BATTLEFIELD_SCORE()
	for i = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, _, _, _, class = GetBattlefieldScore(i)
		if name and class then -- sometimes this returns nil??
			NAMES.ClassColoredNameCache[name] = NAMES.ClassColors[class] .. name .. "|r"
		end
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
	-- GLOBALS: CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS
	for class, color in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
		if color.colorStr then
			NAMES.ClassColors[class] = color.colorStr
		else
			NAMES.ClassColors[class] = ("|cff%02x%02x%02x"):format(color.r * 255, color.g * 255, color.b * 255)
		end
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

function NAMES:GetUnitIDFromGUID(GUID)
	local unitList = NAMES.unitList
	for i = 1, #unitList do
		local id = unitList[i]
		local guidGuess = UnitGUID(id)
		if guidGuess and guidGuess == GUID then
			return id
		end
	end
end

--[[function NAMES:TryToAcquireUnit(input, isName)
	if not input then return end

	local name, server
	if not isName then
		name, server = UnitName(input or "")
	end

	if name then
		-- input was a unitID if name was obtained.
		return input
	else
		-- input was a name.
		name = input

		local unit = NAMES:GetUnitIDFromName(input)
		if unit then
			return unit
		end
	end
end]]


function NAMES:TryToAcquireName(input, shouldColor, isName)
	if not input then return end

	local name, server
	if not isName then
		name, server = UnitName(input or "")
	end

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
				local colorString = NAMES.ClassColors[class]
				local nameColored = name
				if colorString then 
					nameColored = NAMES.ClassColors[class] .. name .. "|r"

					NAMES.ClassColoredNameCache[name] = nameColored
				end
				
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



EVENTS = TMW:NewModule("Events", "AceEvent-3.0", "AceTimer-3.0") TMW.EVENTS = EVENTS
EVENTS.QueuedIcons = {}
do
	EVENTS.OnIconShowHideHandlers = {}
	EVENTS.OnIconShowHideManager = UpdateTableManager:New()
	EVENTS.OnIconShowHideManager:UpdateTable_Set(EVENTS.OnIconShowHideHandlers)
end
function EVENTS:ProcessAndDelegateIconEventSettings(icon, event, eventSettings)
	local success = self:ProcessIconEventSettings(event, eventSettings)

	if success and (event == "OnIconShow" or event == "OnIconHide") then
		if icon.Enabled then
			self.OnIconShowHideManager:UpdateTable_Register(icon)
			TMW:RegisterCallback("TMW_ICON_DATA_CHANGED_ALPHA", EVENTS) -- register to EVENTS, not self.
		end
	end

	return success
end

function EVENTS:TMW_ICON_DATA_CHANGED_ALPHA(_, ic, alpha, oldalpha)
	if Locked then
		-- ic is the icon that changed, icon is the icon that might be handling it
		
		local event
		if alpha == 0 then
			event = "OnIconHide"
		elseif oldalpha == 0 then
			event = "OnIconShow"
		end
		
		local icName = ic:GetName()

		local tbl = self.OnIconShowHideHandlers
		for i = 1, #tbl do
			local icon = tbl[i]
			if icon.EventHandlersSet[event] then
				for _, EventSettings in TMW:InNLengthTable(icon.Events) do
					if EventSettings.Event == event and EventSettings.Icon == icName then
						icon:QueueEvent(EventSettings)
					end
				end
			end
		end
	end
end
function EVENTS:TMW_ICON_SETUP_PRE(_, icon)
	self.OnIconShowHideManager:UpdateTable_Unregister(icon)

	wipe(icon.EventHandlersSet)

	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		local event = eventSettings.Event
		if event then
			local thisHasEventHandlers
			local Module = self:GetModule(eventSettings.Type, true)
			if Module then
				thisHasEventHandlers = Module:ProcessAndDelegateIconEventSettings(icon, event, eventSettings)
			end

			if thisHasEventHandlers then
				icon.EventHandlersSet[event] = true
				icon.EventsToFire = icon.EventsToFire or {}
			end
		end
	end
end
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", EVENTS)
function EVENTS:TMW_ICON_SETUP_POST(_, icon)
	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		local event = eventSettings.Event
		if event == "OnLeftClick" then
			icon:EnableMouse(1)
		elseif event == "OnRightClick" then
			icon:EnableMouse(1)
		end
	end
end
TMW:RegisterCallback("TMW_ICON_SETUP_POST", EVENTS)

function EVENTS:TMW_ONUPDATE_TIMECONSTRAINED_POST(event, time, Locked)
	local QueuedIcons = self.QueuedIcons
	if Locked and QueuedIcons[1] then
		sort(QueuedIcons, TMW.Classes.Icon.ScriptSort)
		for i = 1, #QueuedIcons do
			local icon = QueuedIcons[i]
			icon:ProcessQueuedEvents()
		end
		wipe(QueuedIcons)
	end
end
TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", EVENTS)

local runEvents = 1
function EVENTS:RestoreEvents()
	runEvents = 1
end
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function()
	-- make sure events dont fire while, or shortly after, we are setting up
	runEvents = nil
	EVENTS:ScheduleTimer("RestoreEvents", max(UPD_INTV*2.1, 0.2))
end)


SND = EVENTS:NewModule("Sound", EVENTS) TMW.SND = SND
function SND:ProcessIconEventSettings(event, eventSettings)
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
			elseif IsInRaid() then
				channel = "RAID"
			elseif IsInGroup() then
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
		-- GLOBALS: DEFAULT_CHAT_FRAME, FCF_GetChatWindowInfo
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
				Text = "|T" .. (icon.attributes.texture or "") .. ":0|t " .. Text
			end

			-- GLOBALS: RaidWarningFrame, RaidNotice_AddMessage
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
		-- GLOBALS: SCT
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
				SCT:DisplayCustomEvent(Text, sctcolor, data.Sticky, data.Location, nil, data.Icon and icon.attributes.texture)
			end
		end,
	},
	{
		-- GLOBALS: MikSBT
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
				MikSBT.DisplayMessage(Text, data.Location, data.Sticky, data.r*255, data.g*255, data.b*255, Size, nil, data.Icon and icon.attributes.texture)
			end
		end,
	},
	{
		-- GLOBALS: Parrot
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
				Parrot:ShowMessage(Text, data.Location, data.Sticky, data.r, data.g, data.b, nil, Size, nil, data.Icon and icon.attributes.texture)
			end
		end,
	},
	{
		-- GLOBALS: CombatText_AddMessage, CombatText_StandardScroll, SHOW_COMBAT_TEXT
		text = COMBAT_TEXT_LABEL,
		desc = L["ANN_FCT_DESC"],
		channel = "FCT",
		sticky = 1,
		icon = 1,
		color = 1,
		handler = function(icon, data, Text)
			if data.Icon then
				Text = "|T" .. (icon.attributes.texture or "") .. ":20:20:-5|t " .. Text
			end
			if SHOW_COMBAT_TEXT ~= "0" then
				if not CombatText_AddMessage then
					-- GLOBALS: UIParentLoadAddOn
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
function ANN:ProcessIconEventSettings(event, eventSettings)
	if eventSettings.Channel ~= "" then
		return true
	end
end
ANN.kwargs = {}
function ANN:HandleEvent(icon, data)
	local Channel = data.Channel
	if Channel ~= "" then
		local Text = data.Text
		local chandata = ChannelList[Channel]

		if not chandata then
			return
		end

		wipe(ANN.kwargs)
		ANN.kwargs.icon = icon.ID
		ANN.kwargs.group = icon.group.ID
		ANN.kwargs.unit = icon.attributes.dogTagUnit
		ANN.kwargs.link = true
		ANN.kwargs.color = not chandata.isBlizz and TMW.db.profile.ColorNames

		if chandata.handler then
			Text = DogTag:Evaluate(Text, "Unit;TMW", ANN.kwargs)
			chandata.handler(icon, data, Text)
		elseif Text and chandata.isBlizz then
			local Location = data.Location
			Text = Text:gsub("Name", "nameforceuncolored")
			Text = DogTag:Evaluate(Text, "Unit;TMW", ANN.kwargs)
			if Channel == "WHISPER" then
				wipe(ANN.kwargs)
				ANN.kwargs.icon = icon.ID
				ANN.kwargs.group = icon.group.ID
				ANN.kwargs.unit = icon.attributes.dogTagUnit
				ANN.kwargs.link = false
				ANN.kwargs.color = false
				Location = DogTag:Evaluate(Location, "Unit;TMW", ANN.kwargs)
				Location = Location:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") -- strip color codes
			end
			SendChatMessage(Text, Channel, nil, Location)
		end

		return true
	end
end


ANIM = EVENTS:NewModule("Animations", EVENTS) TMW.ANIM = ANIM
ANIM.AnimationList = {
	{ -- NONE
		text = NONE,
		animation = "",
	},
	{ -- SCREENSHAKE
		-- GLOBALS: WorldFrame
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
	{ -- SCREENFLASH
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
	{ -- ICONSHAKE
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

				local position = icon.position
				icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x + moveX, position.y + moveY)
			end
		end,
		OnStop = function(icon, table)
			local position = icon.position
			icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x, position.y)
		end,
	},
	{ -- ICONFLASH
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
				
				-- this will fallback on icon if there isnt a texture or icon isnt an icon
				animation_flasher:SetAllPoints(icon.class == TMW.Classes.Icon and icon.EssentialModuleComponents.texture or icon)
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
	{ -- ICONALPHAFLASH
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
					icon:SetAlpha(icon.attributes.alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
				else
					icon:SetAlpha(icon.attributes.alpha*(remainingFlash/FlashPeriod))
				end
			else
				icon:SetAlpha(fadingIn and icon.attributes.alpha or 0)
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
	{ -- ICONFADE
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

					icon:SetAlpha((icon.attributes.actualAlphaAtLastChange * pct) + (icon.attributes.alpha * inv))
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
	{ -- ACTVTNGLOW
		-- GLOBALS: ActionButton_ShowOverlayGlow, ActionButton_HideOverlayGlow
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
			icon.overlay:SetFrameLevel(icon:GetFrameLevel() + 3)
		end,
		OnStop = function(icon, table)
			ActionButton_HideOverlayGlow(icon) -- dont upvalue, can be hooked (masque doesn't, but maybe others)
		end,
	},
	{ -- ICONBORDER
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
	{ -- ICONOVERLAYIMG
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
				Image = TMW:GetTexturePathFromSetting(data.Image),
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
	{ -- (spacer)
		noclick = true,
	},
	{ -- ICONCLEAR
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
	TMW:RegisterCallback("TMW_ONUPDATE", self)
end
function ANIM:ProcessIconEventSettings(event, eventSettings)
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
function ANIM:TMW_ONUPDATE()
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



TMW:NewClass("ConditionImplementor"){
	Conditions_GetConstructor = function(self, Conditions)
		local ConditionObjectConstructor = TMW.CNDT:GetConditionObjectConstructor()
		
		ConditionObjectConstructor:LoadParentAndConditions(self, Conditions)
		
		return ConditionObjectConstructor
	end,
}

TMW:NewClass("GenericComponentImplementor"){
	OnNewInstance_GenericComponentImplementor = function(self)
		self.Components = {}
		self.ComponentsLookup = {}
	end,
}
TMW:NewClass("GenericModuleImplementor", "GenericComponentImplementor"){
	OnNewInstance_GenericModuleImplementor = function(self)
		self.Modules = {}
	end,
	
	DisableAllModules = function(self)
		for moduleName, Module in pairs(self.Modules) do
			Module:Disable()
		end
	end,
}

-- -----------
-- GROUPS
-- -----------

local Group = TMW:NewClass("Group", "Frame", "UpdateTableManager", "ConditionImplementor", "GenericModuleImplementor")
Group:UpdateTable_Set(GroupsToUpdate)

function Group.OnNewInstance(group, ...)
	local _, name, _, _, groupID = ... -- the CreateFrame args
	TMW[groupID] = group
	CNDTEnv[name] = group

	group.ID = groupID
	group.SortedIcons = {}
end

function Group.__tostring(group)
	return group:GetName()
end

function Group.ScriptSort(groupA, groupB)
	local gOrder = -TMW.db.profile.CheckOrder
	return groupA:GetID()*gOrder < groupB:GetID()*gOrder
end

function Group:TMW_ICON_UPDATED(event, icon)
	-- note that this callback is not inherited - it simply handles all groups
	icon.group.iconSortNeeded = true
end
TMW:RegisterCallback("TMW_ICON_UPDATED", Group)

function Group.IconSorter(iconA, iconB)
	local group = iconA.group
	local SortPriorities = group.SortPriorities
	
	local attributesA = iconA.attributes
	local attributesB = iconB.attributes
	
	for p = 1, #SortPriorities do
		local settings = SortPriorities[p]
		local method = settings.Method
		local order = settings.Order

		if Locked or method == "id" then
			-- Force sorting by ID when unlocked.
			-- Don't force the first one to be "id" because it also depends on the order that the user has set.
			
			if method == "id" then
				return iconA.ID*order < iconB.ID*order

			elseif method == "alpha" then
				local a, b = attributesA.alpha, attributesB.alpha
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "visiblealpha" then
				local a, b = iconA:GetAlpha(), iconB:GetAlpha()
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "stacks" then
				local a, b = attributesA.stack or 0, attributesB.stack or 0
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "shown" then
				local a, b = (attributesA.shown and attributesA.alpha > 0) and 1 or 0, (attributesB.shown and attributesB.alpha > 0) and 1 or 0
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "visibleshown" then
				local a, b = (attributesA.shown and iconA:GetAlpha() > 0) and 1 or 0, (attributesB.shown and iconB:GetAlpha() > 0) and 1 or 0
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "duration" then				
				local durationA = attributesA.duration - (time - attributesA.start)
				local durationB = attributesB.duration - (time - attributesB.start)

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
		icon.viewData:Icon_SetPoint(icon, positionedID)
	end
end

Group.SetScript_Blizz = Group.SetScript
function Group.SetScript(group, handler, func)
	group[handler] = func
	group:SetScript_Blizz(handler, func)
end

Group.Show_Blizz = Group.Show
function Group.Show(group)
	if not group.__shown then
		group:Show_Blizz()
		group.__shown = 1
	end
end

Group.Hide_Blizz = Group.Hide
function Group.Hide(group)
	if group.__shown then
		group:Hide_Blizz()
		group.__shown = nil
	end
end

function Group.Update(group)
	local ConditionObj = group.ConditionObj
	local ShouldUpdateIcons = group:ShouldUpdateIcons()
	if (ConditionObj and ConditionObj.Failed) or (not ShouldUpdateIcons) then
		group:Hide()
	elseif ShouldUpdateIcons then
		group:Show()
	end
end

function Group.TMW_CNDT_OBJ_PASSING_CHANGED(group, event, ConditionObj, failed)
	if group.ConditionObj == ConditionObj then
		group:Update()
	end
end




function Group.GetSettings(group)
	return TMW.db.profile.Groups[group:GetID()]
end

function Group.GetSettingsPerView(group, view)
	local gs = group:GetSettings()
	view = view or gs.View
	return gs.SettingsPerView[view]
end

function Group.ShouldUpdateIcons(group)
	local gs = group:GetSettings()

	if	(group:GetID() > TMW.db.profile.NumGroups) or
		(not group.viewData) or
		(not gs.Enabled) or
		(GetActiveTalentGroup() == 1 and not gs.PrimarySpec) or
		(GetActiveTalentGroup() == 2 and not gs.SecondarySpec) or
		(GetPrimaryTalentTree() and not gs["Tree" .. GetPrimaryTalentTree()])
	then
		return false
	end

	return true
end

function Group.IsValid(group)
	-- checks if the group can be checked in metas/conditions

	return group:ShouldUpdateIcons()
end


function Group.CalibrateAnchors(group)
	assert(TMW.GetAnchoredPoints, "Why is group:CalibrateAnchors() being called when TellMeWhen_Options isn't loaded?")
	
	local gs = group:GetSettings()
	
	local p = gs.Point
	p.point, p.relativeTo, p.relativePoint, p.x, p.y = TMW:GetAnchoredPoints(group)
end

function Group.DetectFrame(group, event, time, Locked)
	local frameToFind = group.frameToFind
	if _G[frameToFind] then
		group:SetPos()
		TMW:UnregisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", group.DetectFrame, group)
	end
end

function Group.SetPos(group)
	local groupID = group:GetID()
	local s = TMW.db.profile.Groups[groupID]
	local p = s.Point
	group:ClearAllPoints()
	if p.relativeTo == "" then
		p.relativeTo = "UIParent"
	end
	p.relativeTo = type(p.relativeTo) == "table" and p.relativeTo:GetName() or p.relativeTo
	local relativeTo = _G[p.relativeTo]
	if not relativeTo then
		group.frameToFind = p.relativeTo
		TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", group.DetectFrame, group)
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
	
	group:SetFrameStrata(s.Strata)
	group:SetFrameLevel(s.Level)
end


function Group.Setup_Conditions(group)
	-- Clear out any old conditions and condition-related stuff
	
	group.ConditionObj = nil
	TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", group)
	group:UpdateTable_Unregister(group)
	
	-- Determine if we should process conditions
	if group:ShouldUpdateIcons() and Locked then
		-- Get a constructor to make the ConditionObj
		local ConditionObjectConstructor = group:Conditions_GetConstructor(group.Conditions)
		
		-- If the group is set to only show in combat, add a condition to handle it.
		if group.OnlyInCombat then
			local combatCondition = ConditionObjectConstructor:Modify_WrapExistingAndAppendNew()
			combatCondition.Type = "COMBAT"		
		end
		
		-- Modifications are done. Construct the ConditionObj
		group.ConditionObj = ConditionObjectConstructor:Construct()
		
		if group.ConditionObj then
			-- Setup the event handler and the update table if a ConditionObj was returned
			-- (meaning that there are conditions that need to be checked)
			group:UpdateTable_Register()
			
	
			TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", group)
		end
	end

	-- We probably added or removed an entry from the update table, so re-sort it
	group:UpdateTable_Sort(Group.ScriptSort)
end
	
function Group.Setup(group)
	local gs = group:GetSettings()
	local groupID = group:GetID()
	
	for k, v in pairs(TMW.Group_Defaults) do
		group[k] = TMW.db.profile.Groups[groupID][k]
	end
	
	group.__shown = group:IsShown()
	
	local viewData_old = group.viewData
	local viewData = Views[gs.View]
	group.viewData = viewData

	TMW:Fire("TMW_GROUP_SETUP_PRE", group)
	
	group:DisableAllModules()
	
	if group:ShouldUpdateIcons() then
		-- Setup the groups's view:
		
		-- UnSetup the old view
		if viewData_old then
			if viewData_old ~= viewData and viewData_old.Group_UnSetup then
				viewData_old:Group_UnSetup(group)
			end
			
			viewData_old:UnimplementFromGroup(group)
		end
		
		-- Setup the current view
		viewData:ImplementIntoGroup(group)
		if viewData then
			viewData:Group_Setup(group)
		end
		
		-- Setup icons
		for iconID = 1, group.Rows * group.Columns do
			local icon = group[iconID]
			if not icon then
				icon = TMW.Classes.Icon:New("Button", group:GetName() .. "_Icon" .. iconID, group, "TellMeWhen_IconTemplate", iconID)
			end

			TMW.safecall(icon.Setup, icon)
		end

		for iconID = (group.Rows*group.Columns)+1, #group do
			local icon = group[iconID]
			icon:DisableIcon()
		end
	else
		for iconID = 1, #group do
			local icon = group[iconID]
			icon:DisableIcon()
		end
	end

	group:SetPos()
	group:SortIcons()
	group.shouldSortIcons = group.SortPriorities[1].Method ~= "id" and group:ShouldUpdateIcons() and group[2] and true

	group:Setup_Conditions()

	group:Update()
	
	TMW:Fire("TMW_GROUP_SETUP_POST", group)
end



-- ------------------
-- ICONS
-- ------------------


local Icon = TMW:NewClass("Icon", "Button", "UpdateTableManager", "ConditionImplementor", "AnimatedObject", "GenericModuleImplementor")
Icon:UpdateTable_Set(IconsToUpdate)
Icon.IsIcon = true

-- universal
function Icon.OnNewInstance(icon, ...)
	local _, name, group, _, iconID = ... -- the CreateFrame args

	icon.group = group
	icon.ID = iconID
	group[iconID] = icon
	CNDTEnv[name] = icon
	tinsert(group.SortedIcons, icon)
	
	icon.EventHandlersSet = {}
	icon.EssentialModuleComponents = {}
	icon.lmbButtonData = {}
	icon.position = {}
	
	
	icon.attributes = {
		start = 0,
		duration = 0,
		alpha = icon:GetAlpha(),
		shown = icon:IsShown(),
		color = 1,
	}
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
	local gOrder = -TMW.db.profile.CheckOrder
	local gA = iconA.group:GetID()
	local gB = iconB.group:GetID()
	if gA == gB then
		local iOrder = -TMW.db.profile.Groups[gA].CheckOrder
		return iconA:GetID()*iOrder < iconB:GetID()*iOrder
	end
	return gA*gOrder < gB*gOrder
end

-- universal
Icon.SetScript_Blizz = Icon.SetScript
function Icon.SetScript(icon, handler, func, dontnil)
	if func ~= nil or not dontnil then
		icon[handler] = func
	end
	if handler ~= "OnUpdate" then
		icon:SetScript_Blizz(handler, func)
	else
		icon:UpdateTable_Unregister(icon)
		if func then
			icon:UpdateTable_Register()
		end
		icon:UpdateTable_Sort(icon.ScriptSort)
	end
end

-- universal
Icon.RegisterEvent_Blizz = Icon.RegisterEvent
function Icon.RegisterEvent(icon, event)
	icon:RegisterEvent_Blizz(event)
	icon.hasEvents = 1
end

-- universal
Icon.UnregisterAllEvents_Blizz = Icon.UnregisterAllEvents
function Icon.UnregisterAllEvents(icon, event)
	-- UnregisterAllEvents uses a metric fuckton of CPU, so only do it if needed
	if icon.hasEvents then
		icon:UnregisterAllEvents_Blizz()
		icon.hasEvents = nil
	end
end

-- universal
function Icon.OnShow(icon)
	icon:SetInfo("shown", true)
end
function Icon.OnHide(icon)
	icon:SetInfo("shown", false)
end

-- universal
function Icon.GetSettings(icon)
	return TMW.db.profile.Groups[icon.group:GetID()].Icons[icon:GetID()]
end

-- universal
function Icon.GetSettingsPerView(icon, view)
	view = view or icon.group:GetSettings().View
	return icon:GetSettings().SettingsPerView[view]
end

-- universal
function Icon.IsBeingEdited(icon)
	if TMW.IE and TMW.CI.ic == icon and TMW.IE.CurrentTab and TMW.IE:IsVisible() then
		return TMW.IE.CurrentTab:GetID()
	end
end

-- universal
function Icon.QueueEvent(icon, arg1)
	icon.EventsToFire[arg1] = true
	icon.eventIsQueued = true
	
	EVENTS.QueuedIcons[#EVENTS.QueuedIcons + 1] = icon
end

-- universal
function Icon.IsValid(icon)
	-- checks if the icon should be in the list of icons that can be checked in metas/conditions

	return icon.Enabled and icon:GetID() <= icon.group.Rows*icon.group.Columns and icon.group:IsValid()
end

-- universal
Icon.Update_Method = "auto"
function Icon.SetUpdateMethod(icon, method)
	if TMW.db.profile.DEBUG_ForceAutoUpdate then
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
	local attributes = icon.attributes
	local currentIconDuration = attributes.duration - (time - attributes.start)
	if currentIconDuration < 0 then currentIconDuration = 0 end

	icon.NextUpdate_Duration = 0
	
	--[[
		Fire an event that requests whatever is listening to it to add in its
		two cents about when the next update should be.
		Callback handlers for this event should set icon.NextUpdate_Duration to the duration remaining
		on the icon at which an update is needed.
	]]
	TMW:Fire("TMW_ICON_NEXTUPDATE_REQUESTDURATION", icon, currentIconDuration)

	local nextUpdateTime = time + (currentIconDuration - icon.NextUpdate_Duration)
	if nextUpdateTime == time then
		nextUpdateTime = nil
	end
	icon.NextUpdateTime = nextUpdateTime
end


-- universal
function Icon.Update(icon, force, ...)
	local attributes = icon.attributes
	
	if attributes.shown and (force or icon.LastUpdate <= time - UPD_INTV) then
		local Update_Method = icon.Update_Method
		icon.LastUpdate = time

		local ConditionObj = icon.ConditionObj
		if ConditionObj then
			-- the condition check needs to come before we determine iconUpdateNeeded because checking a condition may set NextUpdateTime to 0 if the condition changes
			if ConditionObj.UpdateNeeded or ConditionObj.NextUpdateTime < time then
				ConditionObj:Check(icon)
			end
		end

		local iconUpdateNeeded = force or Update_Method == "auto" or icon.NextUpdateTime < time

		if iconUpdateNeeded then
			icon:OnUpdate(time, ...)
			if Update_Method == "manual" then
				icon:ScheduleNextUpdate()
			end
		end
	end
end

function Icon.TMW_CNDT_OBJ_PASSING_CHANGED(icon, event, ConditionObj, failed)
	-- failed is boolean, never nil. nil is used for the conditionFailed attribute if there are no conditions on the icon.
	if icon.ConditionObj == ConditionObj then
		icon.NextUpdateTime = 0
		-- alpha is set here to force an update on it
		icon:SetInfo("alpha; conditionFailed", icon.attributes.alpha, failed)
	end
end

-- universal (probably)
function Icon.SetTexture(icon, tex)
	TMW:Error([[icon:SetTexture is depreciated. Use icon:SetInfo("texture", texture) instead]])
end

-- universal (but actual event handlers (:HandleEvent()) arent (probably, mainly animations))
function Icon.ProcessQueuedEvents(icon)
	local EventsToFire = icon.EventsToFire
	if EventsToFire and icon.eventIsQueued then
		local handledOne
		for i = 1, (icon.Events.n or 0) do
			-- settings to check for in EventsToFire
			local EventSettingsFromIconSettings = icon.Events[i]
			local event = EventSettingsFromIconSettings.Event

			local EventSettings
			if EventsToFire[EventSettingsFromIconSettings] or EventsToFire[event] then
				-- we should process EventSettingsFromIconSettings
				EventSettings = EventSettingsFromIconSettings
			end
			local eventData = TMW.EventList[event]
			if eventData and EventSettings then
				local shouldProcess = true
				if EventSettings.OnlyShown and icon.attributes.alpha <= 0 then
					shouldProcess = false

				elseif EventSettings.PassingCndt then
					local conditionChecker = eventData.conditionChecker
					local conditionResult
					if conditionChecker then
						conditionResult = conditionChecker(icon, EventSettings)
					end
					if EventSettings.CndtJustPassed then
						if conditionResult ~= EventSettings.wasPassingCondition then
							EventSettings.wasPassingCondition = conditionResult
						else
							conditionResult = false
						end
					end
					shouldProcess = conditionResult
				end

				if shouldProcess and runEvents and icon.attributes.shown then
					local Module = EVENTS:GetModule(EventSettings.Type, true)
					if Module then
						local handled = Module:HandleEvent(icon, EventSettings)
						if handled then
							if not EventSettings.PassThrough then
								break
							end
							handledOne = true
						end
					end
				end
			end
		end

		wipe(EventsToFire)
		icon.eventIsQueued = nil
		if handledOne then
			TMW:Fire("TMW_ICON_UPDATED", icon)
		end
	end
end

-- universal
function Icon.GetTextLayout(icon, view)
	-- view is optional, defaults to the current view
	local GUID = icon:GetSettingsPerView(view).TextLayout
	if GUID == "" then
		GUID = icon.group:GetSettingsPerView(view).TextLayout
	end
	local layoutSettings = GUID and rawget(TMW.db.profile.TextLayouts, GUID)
	
	if not layoutSettings then
		local DefaultsPerView = TMW.Icon_Defaults.SettingsPerView
		GUID = view and DefaultsPerView[view] and DefaultsPerView[view].TextLayout
		if not GUID or GUID == "" then
			GUID = DefaultsPerView["**"].TextLayout
		end
		assert(GUID)
		layoutSettings = rawget(TMW.db.profile.TextLayouts, GUID)
		assert(layoutSettings)
		
		local groupID = icon.group.ID
		local iconID = icon.ID
		TMW.Warn(L["ERROR_MISSINGLAYOUT"]:format(L["GROUPICON"]):format(TMW:GetGroupName(groupID, groupID, 1), iconID))
	end
	
	return GUID, layoutSettings	
end

function Icon.DisableIcon(icon)

	icon:DisableAllModules()
	
	icon:UnregisterAllEvents()
	ClearScripts(icon)
	icon:Hide()
	
	TMW:Fire("TMW_ICON_DISABLE", icon)
end

-- universal
function Icon.Setup(icon)
	if not icon or not icon[0] then return end

	local iconID = icon:GetID()
	local group = icon.group
	local groupID = group:GetID()
	local ics = icon:GetSettings()
	local typeData = Types[ics.Type]
	local viewData = Views[group:GetSettings().View]
	
	local viewData_old = icon.viewData
	icon.viewData = viewData
	
	local typeData_old = icon.typeData
	icon.typeData = typeData
	
	icon.dontHandleConditionsExternally = nil --TODO: figure out a way to eliminate this.
	

	icon:UnregisterAllEvents()
	ClearScripts(icon)	
	icon:SetUpdateMethod("auto")

	for k in pairs(TMW.Icon_Defaults) do
		if typeData.RelevantSettings[k] then
			icon[k] = ics[k]
		else
			icon[k] = nil
		end
	end

	-- process alpha settings
	if icon.ShowWhen then
		if bitband(icon.ShowWhen, 0x1) == 0 then
			icon.UnAlpha = 0
		elseif bitband(icon.ShowWhen, 0x2) == 0 then
			icon.Alpha = 0
		end
	end

	
	icon:Show()
	icon:SetFrameLevel(group:GetFrameLevel() + 1)

	TMW:Fire("TMW_ICON_SETUP_PRE", icon)

	-- Conditions
	local ConditionObjectConstructor = icon:Conditions_GetConstructor(icon.Conditions)
	icon.ConditionObj = ConditionObjectConstructor:Construct()
	
	if icon.ConditionObj then
		TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", icon)
		icon:SetInfo("conditionFailed", icon.ConditionObj.Failed)
	else
		TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", icon)
		icon:SetInfo("conditionFailed", nil)
	end

	-- force an update
	icon.LastUpdate = 0
	
	icon:DisableAllModules()
	
	-- actually run the icon's update function
	if icon.Enabled or not Locked then
	
		------------ Icon Type ------------
		if typeData_old then
			typeData_old:UnimplementFromIcon(icon)
		end
		typeData:ImplementIntoIcon(icon)
		
		if icon.typeData ~= typeData_old then		
			TMW:Fire("TMW_ICON_TYPE_CHANGED", icon, typeData, typeData_old)
		end
		
		
		------------ Icon View ------------		
		if viewData_old then
			viewData_old:UnimplementFromIcon(icon)
			
			if viewData_old.Icon_UnSetup then
				-- Call the old view's Icon_UnSetup if it has one (in most cases, it shouldn't.)
				-- All unloading/UnSetup/Disabling should be handled by individual modules. 
				viewData_old:Icon_UnSetup(icon)
			end
		end
		viewData:Icon_Setup(icon)
		viewData:ImplementIntoIcon(icon)		
		
		
		TMW.safecall(typeData.Setup, typeData, icon, groupID, iconID)
	else
		icon:SetInfo("alpha", 0)
	end

	icon.NextUpdateTime = 0

	if Locked then	
		icon:SetInfo("alphaOverride", nil)
		if icon.attributes.texture == "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled" then
			icon:SetInfo("texture", "")
		end
		icon:EnableMouse(0)
		if not icon.Enabled or (icon.Name == "" and not typeData.AllowNoName) then
			ClearScripts(icon)
			icon:Hide()
		else
			icon:Show()
		end
		if icon.OnUpdate then
			icon:Update()
		end
	else
		icon:Show()
		ClearScripts(icon)
		
		icon:SetInfo(
			"alphaOverride; color; start, duration; stack, stackText",
			icon.Enabled and 1 or 0.5,
			1,
			0, 0,
			nil, nil
		)
		
		if icon.attributes.texture == "" then
			icon:SetInfo("texture", "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
		end

		icon:EnableMouse(1)
	end

	TMW:Fire("TMW_ICON_SETUP_POST", icon)
end

function Icon.SetupAllModulesForIcon(icon, sourceIcon)
	for moduleName, Module in pairs(icon.Modules) do
		if Module.SetupForIcon then
			Module:SetupForIcon(sourceIcon)
		end
	end
end

-- universal (this is for meta icons)
function Icon.SetModulesToActiveStateOfIcon(icon, sourceIcon)
	local sourceModules = sourceIcon.Modules
	for moduleName, Module in pairs(icon.Modules) do
		if Module.IsImplemented then
			local sourceModule = sourceModules[moduleName]
			if sourceModule then
				if sourceModule.IsEnabled then
					Module:Enable(true)
				else
					Module:Disable()
				end
			else
				Module:Disable()
			end
		end
	end
end
	

TMW:NewClass("NamedInstances"){
	-- this isnt actually used (it is inherited from, but instancesByName isnt used anywhere. see if we could benefit by using it somewhere (i bet we can; i wrote it for a reason) (TODO)
	OnClassInherit_NamedInstances = function(self, newClass)
		newClass.instancesByName = {}
	end,
	OnNewInstance_NamedInstances = function(self, name)
		self.instancesByName[name] = self
	end,
}

TMW.RapidSettings = {
	-- settings that can be changed very rapidly, i.e. via mouse wheel or in a color picker
	-- consecutive changes of these settings will be ignored by the undo/redo module
	r = true,
	g = true,
	b = true,
	a = true,
	r_anim = true,
	g_anim = true,
	b_anim = true,
	a_anim = true,
	Size = true,
	Level = true,
	Alpha = true,
	UnAlpha = true,
	Duration = true,
	Magnitude = true,
	Period = true,
}

TMW:NewClass("GenericComponent"){
	ConfigPanels = {},
	IconEvents = {},
	OnClassInherit_GenericComponent = function(self, newClass)
		newClass:InheritTable(self, "ConfigPanels")
		newClass:InheritTable(self, "IconEvents")
	end,
	OnNewInstance_GenericComponent = function(self)
		self:InheritTable(self.class, "ConfigPanels")
		self:InheritTable(self.class, "IconEvents")
	end,
	
	
	RegisterConfigPanel = function(self, size, preferredColumn, panelType, supplementalData)
		self:AssertIsProtectedCall("Use the RegisterConfigPanel_<type> functions instead.")
		
		assert(size == "column" or size == "full", "GenericComponent:RegisterConfigPanel() - 'size' (arg2) - Expected 'column' or 'full'")
		
		local t = {
			self = self,
			panelType = panelType,
			size = size,
			preferredColumn = preferredColumn,
			supplementalData = supplementalData,
		}
		if size == "full" then
			t.preferredColumn = 1
		end
		
		self.ConfigPanels[#self.ConfigPanels + 1] = t
		return t
	end,
	RegisterConfigPanel_XMLTemplate = function(self, size, preferredColumn, xmlTemplateName, supplementalData)
		TMW:ValidateType(2, "GenericComponent:RegisterConfigPanel_XMLTemplate()", size, "string")
		TMW:ValidateType(4, "GenericComponent:RegisterConfigPanel_XMLTemplate()", xmlTemplateName, "string")
		
		local t = self:RegisterConfigPanel(size, preferredColumn, "XMLTemplate", supplementalData)
		
		t.xmlTemplateName = xmlTemplateName
	end,
	RegisterConfigPanel_ConstructorFunc = function(self, size, preferredColumn, frameName, func, supplementalData)
		TMW:ValidateType(2, "GenericComponent:RegisterConfigPanel_XMLTemplate()", size, "string")
		TMW:ValidateType(4, "GenericComponent:RegisterConfigPanel_XMLTemplate()", frameName, "string")
		TMW:ValidateType(5, "GenericComponent:RegisterConfigPanel_XMLTemplate()", func, "function")
		
		local t = self:RegisterConfigPanel(size, preferredColumn, "ConstructorFunc", supplementalData)
		
		t.frameName = frameName
		t.func = func
	end,
	ShouldShowConfigPanels = function(self, icon)
		-- Defaults to true. Subclasses of GenericComponent can overwrite this function for their own usage.
		return true
	end,
	
	RegisterRapidSetting = function(self, setting)
		TMW.RapidSettings[setting] = true
	end,
	
	RegisterUpgrade = function(self, version, data)
		if TMW.HaveUpgradedOnce then
			error(("Upgrades for module %q are being registered too late. They need to be registered before any upgrades occur."):format(self.name))
		end
		
		TMW:RegisterUpgrade(version, data)
	end,
	
	RegisterDogTag = function(self, ...)
		-- just a wrapper so that i don't have to LibStub DogTag everywhere
		DogTag:AddTag(...)
	end,
	
	RegisterIconEvent = function(self, data)
		--TODO: add validation for required fields, etc, etc.
		TMW.EventList[#TMW.EventList + 1] = data
		TMW.EventList[data.name] = data
		self.IconEvents[#self.IconEvents + 1] = data
	
	end,
	
}

TMW:NewClass("IconComponent", "GenericComponent"){
	IconSettingDefaults = {},
	OnClassInherit_IconComponent = function(self, newClass)
		newClass:InheritTable(self, "IconSettingDefaults")
	end,
	OnNewInstance_IconComponent = function(self)
		self:InheritTable(self.class, "IconSettingDefaults")
	end,
	
	RegisterIconDefaults = function(self, defaults, forceRelevant)
		assert(type(defaults) == "table", "arg1 to RegisterIconDefaults must be a table")
		
		if TMW.Initialized then
			error(("Defaults for module %q are being registered too late. They need to be registered before the database is initialized."):format(self.name))
		end
		
		-- Copy the defaults into the main defaults table.
		TMW:CopyTableInPlaceWithMeta(defaults, TMW.Icon_Defaults, true)
		-- Copy the defaults into defaults for this component. Used to implement relevant settings.
		TMW:CopyTableInPlaceWithMeta(defaults, self.IconSettingDefaults, true)
		
		-- Add the settings to the RelevantToAll table so that they can be accessed directly from the icon.
		if forceRelevant then
			for settingKey in pairs(defaults) do
				RelevantToAll.__index[settingKey] = true
			end
		end
	end,
	
	ImplementIntoIcon = function(self, icon)
		if not icon.ComponentsLookup[self] then
			local ics = icon:GetSettings()
			
			for setting in pairs(self.IconSettingDefaults) do
				if icon[setting] ~= nil and type(ics[setting]) ~= "table" then
					TMW:Error("Possible setting conflict detected! Setting %q, with value %q, trying to be implemented by %q, already exists as %q", setting, tostring(ics[setting]), self.name or self.className or "??", tostring(icon[setting]))
				end
				icon[setting] = ics[setting]
			end
			
			icon.Components[#icon.Components+1] = self
			icon.ComponentsLookup[self] = true
			
			if self.OnImplementIntoIcon then
				self:OnImplementIntoIcon(icon)
			end
		end
	end,
	
	UnimplementFromIcon = function(self, icon)
		if icon.ComponentsLookup[self] then
		
			tDeleteItem(icon.Components, self, true)
			icon.ComponentsLookup[self] = nil
			
			if self.OnUnimplementFromIcon then
				self:OnUnimplementFromIcon(icon)
			end
		end
	end,
}

TMW:NewClass("GroupComponent", "GenericComponent"){
	RegisterGroupDefaults = function(self, defaults)
		assert(type(defaults) == "table", "arg1 to RegisterGroupDefaults must be a table")
		
		if TMW.Initialized then
			error(("Defaults for component %q are being registered too late. They need to be registered before the database is initialized."):format(self.name or "<??>"))
		end
		
		-- Copy the defaults into the main defaults table.
		TMW:CopyTableInPlaceWithMeta(defaults, TMW.Group_Defaults, true)
	end,
	
	ImplementIntoGroup = function(self, group)
		if not group.ComponentsLookup[self] then
			group.ComponentsLookup[self] = true
			group.Components[#group.Components+1] = self
		
			if self.OnImplementIntoGroup then
				self:OnImplementIntoGroup(group)
			end
		end
	end,
	
	UnimplementFromGroup = function(self, group)
		if group.ComponentsLookup[self] then
		
			tDeleteItem(group.Components, self, true)
			group.ComponentsLookup[self] = nil
			
			if self.OnUnimplementFromGroup then
				self:OnUnimplementFromGroup(group)
			end
		end
	end,
}


TMW.ProcessorsByName = {}
TMW:NewClass("IconDataProcessorComponent", "IconComponent", "NamedInstances"){
	SIUVs = {},
	
	DeclareUpValue = function(self, variables, ...)
		assert(type(variables) == "string", "IconDataProcessor:DeclareUpValue(variables, ...) - variables must be a string")
		self.SIUVs[#self.SIUVs+1] = {
			variables = variables,
			...,
		}
	end,
}

local IconDataProcessor = TMW:NewClass("IconDataProcessor", "IconDataProcessorComponent"){
	UsedTokens = {},
	OnNewInstance = function(self, name, attributes)
		assert(name, "Name is required for an IconDataProcessor!")
		assert(attributes, "Attributes are required for an IconDataProcessor!")
		
		self.hooks = {}
		
		for i, instance in pairs(self.class.instances) do
			if instance.name == name then
				error(("Processor %q already exists!"):format(self.name))
			elseif instance.attributesString == attributes then
				error(("Processor with attributes %q already exists!"):format(self.name))
			end
		end
		
		self.name = name
		self.attributesString = attributes
		self.attributesStringNoSpaces = attributes:gsub(" ", "")
		
		for _, attribute in TMW:Vararg(strsplit(",", self.attributesStringNoSpaces)) do
			if self.UsedTokens[attribute] then
				error(("Attribute token %q is already in use by %q!"):format(attribute, self.UsedTokens[attribute].name))
			else
				self.UsedTokens[attribute] = self
			end
		end
		
		TMW.ProcessorsByName[self.name] = self
		self:DeclareUpValue(name, self)
		self:DeclareUpValue(attributes) -- do this to prevent accidental leaked global accessing
		
		self.changedEvent = "TMW_ICON_DATA_CHANGED_" .. name
		
		TMW:ClearSetInfoFunctionCache()
	end,
	AssertDependency = function(self, dependency)
		assert(TMW.ProcessorsByName[dependency], ("Dependency %q of processor %q was not found!"):format(dependency, self.name))
	end,
	CreateDogTagEventString = function(self)
		return TMW:CreateDogTagEventString(self.name)
	end,
	CompileFunctionHooks = function(self, t, orderRequested)
		for _, ProcessorHook in ipairs(self.hooks) do
			for func, order in pairs(ProcessorHook.funcs) do
				if order == orderRequested then
					t[#t+1] = "\n"
					func(self, t)
					t[#t+1] = "\n"
				end
			end
		end
	end
}
IconDataProcessor:DeclareUpValue("TMW", TMW)
IconDataProcessor:DeclareUpValue("print", print)
IconDataProcessor:DeclareUpValue("ProcessorsByName", TMW.ProcessorsByName)
IconDataProcessor:DeclareUpValue("type", type)

TMW:NewClass("IconDataProcessorHook", "IconDataProcessorComponent"){
	OnNewInstance = function(self, name, processorToHook)
		TMW:ValidateType(2, "IconDataProcessorHook:New()", name, "string")
		TMW:ValidateType(3, "IconDataProcessorHook:New()", processorToHook, "string")
		
		local Processor = TMW.ProcessorsByName[processorToHook]
		assert(Processor, "IconDataProcessorHook:New() unable to find IconDataProcessor named " .. processorToHook)
		
		self.name = name
		self.processorToHook = processorToHook
		self.Processor = Processor
		self.Processor.hooks[#self.Processor.hooks+1] = self
		self.funcs = {}
		self.processorRequirements = {}
		
		self:RegisterProcessorRequirement(processorToHook)
	end,
	RegisterCompileFunctionSegmentHook = function(self, order, func)
		-- These hooks are not much of hooks at all,
		-- since they go directly in the body of the function
		-- and can modify input variables before they are processed.
		
		assert(order == "pre" or order == "post", "RegisterCompileFunctionSegmentHook: arg1 must be either 'pre' or 'post'")
		
		self.funcs[func] = order
		
		TMW:ClearSetInfoFunctionCache()
	end,
	RegisterProcessorRequirement = function(self, processorName)
		self.processorRequirements[processorName] = true
	end,
}
--TODO: make condition implementation into a module. part of this will be making sure that setinfo'alpha' is called when condition state changes.
local InheritAllFunc
function Icon.InheritDataFromIcon(iconDestination, iconSource)
	if not InheritAllFunc then
		local attributes = {}
		local attributesSplit = {}
	
		for _, Processor in pairs(IconDataProcessor.instances) do
			if not Processor.dontInherit then
				attributes[#attributes+1] = Processor.attributesStringNoSpaces
				for _, attribute in TMW:Vararg(strsplit(",", Processor.attributesStringNoSpaces)) do
					attributesSplit[#attributesSplit+1] = attribute
				end
			end
		end
		
		local t = {}
		t[#t+1] = "local iconDestination, iconSource = ..."
		t[#t+1] = "\n"
		t[#t+1] = "local attributes = iconSource.attributes"
		t[#t+1] = "\n"
		t[#t+1] = "iconDestination:SetInfo('"
		t[#t+1] = table.concat(attributes, "; ")
		t[#t+1] = "', "
		t[#t+1] = "attributes."
		t[#t+1] = table.concat(attributesSplit, ", attributes.")
		t[#t+1] = ")"
		
		InheritAllFunc = assert(loadstring(table.concat(t)))
	end
	
	InheritAllFunc(iconDestination, iconSource)
end


local function enumLines(text)
	text = text:gsub("\r\n", "\n"):gsub("\t", "    ")
	local lines = {("\n"):split(text)}
	local t = {}
	local indent = 0
	for i, v in ipairs(lines) do
		if v:match("end;?$") or v:match("else$") or v:match("^ *elseif") then
			indent = indent - 1
		end
		for j = 1, indent do
			t[#t+1] = "    "
		end
		t[#t+1] = v:gsub(";\s*$", "")
		t[#t+1] = " -- "
		t[#t+1] = i
		t[#t+1] = "\n"
		if v:match("then$") or v:match("do$") or v:match("else$") or v:match("function%(.-%)") then
			indent = indent + 1
		end
	end
	local s = table.concat(t)
	return s
end
local SetInfoFuncs = setmetatable({}, { __index = function(self, signature)
	assert(type(signature) == "string", --TODO: remove this check after 9/1/2012
	("(Bad argument #3 to icon:SetInfo(signature, ...) - Expected string, got %s. (SetInfo changed in v5.1.0 - are you still using the old SetInfo format?)"):format(type(signature)))
	
	local originalSignature = signature
	
	signature = signature:gsub(" ", "")
	if rawget(self, signature) then
		return self[signature]    
	end    
	
	local t = {} -- taking a page from DogTag's book on compiling functions
	
	-- Declare all upvalues
	for UVSetID, UVSet in ipairs(IconDataProcessor.SIUVs) do
		t[#t+1] = "local "
		t[#t+1] = UVSet.variables
		t[#t+1] = " = "
		for referenceID, reference in ipairs(UVSet) do
			t[#t+1] = "TMW.Classes.IconDataProcessor.SIUVs["
			t[#t+1] = UVSetID
			t[#t+1] = "]["
			t[#t+1] = referenceID
			t[#t+1] = "]"
			t[#t+1] = ", "
		end
		t[#t] = nil -- remove the final ", " (if there were any references) or the " = " (if there weren't)
		t[#t+1] = "\n"
	end
		
	t[#t+1] = "\n"
	
	t[#t+1] = "\n"
	t[#t+1] = "return function(icon, "
	t[#t+1] = originalSignature:trim(" ,;"):gsub("  ", " "):gsub(";", ",")
	t[#t+1] = ")"
	t[#t+1] = "\n\n"
	t[#t+1] = [[
		local attributes, EventHandlersSet = icon.attributes, icon.EventHandlersSet
		local doFireIconUpdated
	]]
	
	while #signature > 0 do
		local found
		for _, Processor in ipairs(IconDataProcessor.instances) do
			found = signature:find(Processor.attributesStringNoSpaces .. "$") or signature:find(Processor.attributesStringNoSpaces .. ";")
			if found then
				t[#t+1] = "local Processor = "
				t[#t+1] = Processor.name
				t[#t+1] = "\n"
				
				-- Process any hooks that should go before the main function segment
				Processor:CompileFunctionHooks(t, "pre")
				
				Processor:CompileFunctionSegment(t)
				
				-- Process any hooks that should go after the main function segment
				Processor:CompileFunctionHooks(t, "post")
				
				t[#t+1] = "\n\n"  
				
				signature = signature:gsub(Processor.attributesStringNoSpaces .. ";?", "", 1)
				
				break
			end
		end
		if not found then
			error(("Couldn't find a signature match for the beginning of signature %q from %q"):format(signature, originalSignature), 3)
		end
	end
	
	t[#t+1] = [[
		if doFireIconUpdated then
			TMW:Fire("TMW_ICON_UPDATED", icon)
		end
	end -- "return function(icon, ...)"
	]]
	
	local funcstr = table.concat(t)
	funcstr = enumLines(funcstr)
	if TMW.SetInfoFuncsToFuncStrs then
		TMW.SetInfoFuncsToFuncStrs[originalSignature] = funcstr
	end
	local func = assert(loadstring(funcstr, "SetInfo " .. originalSignature))()
	self[originalSignature] = func
	self[originalSignature:gsub(" ", "")] = func
	
	return func
end})
function Icon.SetInfo(icon, signature, ...)
	SetInfoFuncs[signature](icon, ...)
end
function TMW:ClearSetInfoFunctionCache()
	wipe(SetInfoFuncs)
	InheritAllFunc = nil
end
TMW.SetInfoFuncsToFuncStrs = {} --DEBUG

local DogTagEventHandler = function(event, icon)
	DogTag:FireEvent(event, icon.group.ID, icon.ID)
end
function TMW:CreateDogTagEventString(...)
	local eventString = ""
	for i, dataProcessorName in TMW:Vararg(...) do
		local Processor = TMW.ProcessorsByName[dataProcessorName]
		TMW:RegisterCallback(Processor.changedEvent, DogTagEventHandler)
		if i > 1 then
			eventString = eventString .. ";"
		end
		eventString = eventString .. Processor.changedEvent .. "#$group#$icon"
	end
	return eventString
end


TMW:NewClass("ObjectModule"){
	ScriptHandlers = {},
	
	OnNewInstance_ObjectModule = function(self, parent)
		local className = self.className
		
		for script, func in pairs(self.ScriptHandlers) do
			parent:HookScript(script, function(parent, ...)
				local Module = parent.Modules[className]
				if Module and Module.IsEnabled then
					func(Module, parent, ...)
				end
			end)
		end
	end,
	
	OnClassInherit_ObjectModule = function(self, newClass)
		newClass.NumberEnabled = 0
		
		newClass:InheritTable(self, "ScriptHandlers")
	end,
	
	Enable = function(self)
		self:AssertSelfIsInstance()
		
		if not self.IsEnabled then
			self.IsEnabled = true
			self.class.NumberEnabled = self.class.NumberEnabled + 1
			if self.class.NumberEnabled == 1 and self.class.OnUsed then
				self.class:OnUsed()
			end
			
			if self.OnEnable then
				self:OnEnable()
			end
		end
	end,
	Disable = function(self)
		self:AssertSelfIsInstance()
		
		if self.IsEnabled then
			self.IsEnabled = false
			self.class.NumberEnabled = self.class.NumberEnabled - 1
			if self.class.NumberEnabled == 0 and self.class.OnUnused then
				self.class:OnUnused()
			end
			
			if self.OnDisable then
				self:OnDisable()
			end
		end
	end,
	
	SetScriptHandler = function(self, script, func)
		self:AssertSelfIsClass()
		
		TMW:ValidateType(2, "Module:GetScriptHandler()", script, "string")
		
		self.ScriptHandlers[script] = func
	end,
	GetScriptHandler = function(self, script)
	--	self:AssertSelfIsClass() -- doesnt need to be class. No harm in just looking this up for an instance.
		
		TMW:ValidateType(2, "Module:GetScriptHandler()", script, "string")
		
		return self.ScriptHandlers[script]
	end,
}

TMW:NewClass("IconModule", "IconComponent", "ObjectModule"){
	EventListners = {},
	ViewImplementors = {},
	TypeAllowances = {},
	
	defaultAllowanceForTypes = true,
	OnNewInstance_1_IconModule = function(self, icon)
		icon.Modules[self.className] = self
		self.icon = icon
	end,
	OnFirstInstance_IconModule = function(self)
		local className = self.className
		
		for event, func in pairs(self.EventListners) do
			TMW:RegisterCallback(event, function(event, icon, ...)
				local Module = icon.Modules[className]
				if Module and Module.IsEnabled then
					func(Module, icon, ...)
				end
			end)
		end
	end,
	OnClassInherit_IconModule = function(self, newClass)		
		newClass:InheritTable(self, "EventListners")
		newClass:InheritTable(self, "ViewImplementors")
		newClass:InheritTable(self, "TypeAllowances")
		newClass.defaultAllowanceForTypes = self.defaultAllowanceForTypes
	end,
	
	OnImplementIntoIcon = function(self, icon)
		self.IsImplemented = true
		
		local implementationData = self.implementationData
		local implementorFunc = implementationData.implementorFunc
		
		-- implementorFunc is either true if the module is setup within IconView:Icon_Setup(),
		-- or it is a function if that function should be called in order to setup the module.
		if type(implementorFunc) == "function" then
			implementorFunc(self, icon)
		end
		
		if self.SetupForIcon then
			self:SetupForIcon(icon)
		end
	end,
	
	OnUnimplementFromIcon = function(self, icon)
		self.IsImplemented = nil
	end,
	
	SetDataListner = function(self, processorName, ...)
		self:AssertSelfIsClass()
		
		local Processor = TMW.ProcessorsByName[processorName]
		assert(Processor, ("Couldn't find IconDataProcessor named %q"):format(tostring(processorName)))			
		
		-- we need to make sure nil wasn't passed in.
		-- if nil was passed in, then we should nil the handler
		-- if nothing was passed in, then we should search for the func to use
		local func = ...
		if select("#", ...) == 0 and not func then
			func = self[processorName]
		end
		
		self:SetIconEventListner(Processor.changedEvent, func)
	end,
	GetDataListner = function(self, processorName)
		self:AssertSelfIsClass()
		
		local Processor = TMW.ProcessorsByName[processorName]
		assert(Processor, ("Couldn't find IconDataProcessor named %q"):format(tostring(processorName)))			
		
		return self:GetIconEventListner(Processor.changedEvent)
	end,
	
	SetIconEventListner = function(self, event, func)
		self:AssertSelfIsClass()
		
		assert(event)
		
		self.EventListners[event] = func
	end,
	GetIconEventListner = function(self, event)
		assert(event)
		
		return self.EventListners[event]
	end,
	
	SetEssentialModuleComponent = function(self, identifier, component)	--TODO: deprecate this
		self:AssertSelfIsInstance()
		
		assert(identifier)
		if component and self.icon.EssentialModuleComponents[identifier] then
			TMW:Error("Icon %s already has an essential module component with identifier %q", tostring(self.icon), identifier)
		end
		self.icon.EssentialModuleComponents[identifier] = component
	end,
	SetSkinnableComponent = function(self, component, frame)
		self:AssertSelfIsInstance()
		
		assert(not self.icon.lmbButtonData[component])
		self.icon.lmbButtonData[component] = frame
	end,

	ImplementForAllViews = function(self, implementorFunc)
		self:AssertSelfIsClass()
		
		self.ViewImplementors.ALL = implementorFunc
	end,
	
	SetImplementorForView = function(self, view, order, implementorFunc)
		self:AssertSelfIsClass()
		
		local IconView = Views[viewName]
		local moduleName = self.className
		
		if IconView then
			IconView:ImplementsModule(moduleName, order, implementorFunc)
		else
			TMW:RegisterCallback("TMW_VIEW_REGISTERED", function(event, IconView)
				if IconView.view == viewName then
					IconView:ImplementsModule(moduleName, order, implementorFunc)
				end
			end)
		end
	end,
	
	SetAllowanceForType = function(self, typeName, allow)
		self:AssertSelfIsClass()
		
		TMW:ValidateType(2, "IconModule:SetAllowanceForType()", typeName, "string")
		
		-- allow cannot be nil
		TMW:ValidateType(3, "IconModule:SetAllowanceForType()", allow, "boolean")
		
		if self.TypeAllowances[typeName] == nil then
			self.TypeAllowances[typeName] = allow
		else
			TMW:Error("You cannot set a module's type allowance once it has already been declared by either a module or an icon type.")
		end
	end,
	SetDefaultAllowanceForTypes = function(self, allow)
		self:AssertSelfIsClass()
		
		self.defaultAllowanceForTypes = allow
	end,
	
	IsAllowedByType = function(self, iconType)
		local typeAllowance = self.TypeAllowances[iconType]
		if typeAllowance ~= nil then
			return typeAllowance
		else
			return self.defaultAllowanceForTypes
		end
	end,
	
	Enable = function(self, ignoreTypeAllowances)
		self:AssertSelfIsInstance()
		
		if not self.IsEnabled then
			if ignoreTypeAllowances or self:IsAllowedByType(self.icon.Type) then
				self.IsEnabled = true
				
				self.class.NumberEnabled = self.class.NumberEnabled + 1
				if self.class.NumberEnabled == 1 and self.class.OnUsed then
					self.class:OnUsed()
				end
				
				if self.OnEnable then
					self:OnEnable()
				end
			end
		end
	end,
	Disable = function(self)
		self:AssertSelfIsInstance()
		
		if self.IsEnabled then
			self.IsEnabled = false
			self.class.NumberEnabled = self.class.NumberEnabled - 1
			if self.class.NumberEnabled == 0 and self.class.OnUnused then
				self.class:OnUnused()
			end
			
			if self.OnDisable then
				self:OnDisable()
			end
		end
	end,

	ShouldShowConfigPanels = function(self, icon)
		assert(icon == self.icon)
		
		return self:IsAllowedByType(icon.Type)
	end,
}

TMW:NewClass("GroupModule", "GroupComponent", "ObjectModule"){
	ViewImplementors = {},
	OnNewInstance_1_GroupModule = function(self, group)
		group.Modules[self.className] = self
		self.group = group
	end,
	OnClassInherit_GroupModule = function(self, newClass)		
		newClass:InheritTable(self, "ViewImplementors")
	end,
	
	ImplementForAllViews = function(self, implementorFunc)
		self:AssertSelfIsClass()
		
		self.ViewImplementors.ALL = implementorFunc
	end,
	
	SetImplementorForViews = function(self, implementorFunc, ...)
		self:AssertIsProtectedCall()
		
		for i, viewName in TMW:Vararg(...) do
			self.ViewImplementors[viewName] = implementorFunc
		end
	end,
	DisallowForViews = function(self, ...)
		self:AssertSelfIsClass()
		
		self:SetImplementorForViews(false, ...)
	end,
	ImplementForViews = function(self, implementorFunc, ...)
		self:AssertSelfIsClass()
		
		self:SetImplementorForViews(implementorFunc, ...)
	end,
	
	OnImplementIntoGroup = function(self, group)
		local implementationData = self.implementationData
		local implementorFunc = implementationData.implementorFunc
		
		-- implementorFunc is either true if the module is setup within IconView:Group_Setup(),
		-- or it is a function if that function should be called in order to setup the module.
		if type(implementorFunc) == "function" then
			implementorFunc(self, group)
		end
	end,
}

TMW:NewClass("GroupModule_Resizer", "GroupModule"){
	tooltipTitle = L["RESIZE"],
	
	METHOD_EXTENSIONS = {
		OnImplementIntoGroup = function(self)
			self.resizeButton:SetFrameLevel(self.group:GetFrameLevel() + 2)
			
			TMW:TT(self.resizeButton, self.tooltipTitle, self.tooltipText, 1, 1)
		end,
	},
	
	OnNewInstance_Resizer = function(self, group)
		assert(self.className ~= "GroupModule_Resizer", "GroupModule_Resizer cannot be instantiated. You must derive a class from it so that you can define a SizeUpdate method.")
		
		self.resizeButton = CreateFrame("Button", nil, group, "TellMeWhen_GroupTemplate_ResizeButton")
		
		-- Default module state is disabled, but default frame state is shown, so initially we need to hide the button.
		self.resizeButton:Hide()
		
		self.resizeButton.module = self
		
		self.resizeButton:SetScript("OnMouseDown", self.StartSizing)
		self.resizeButton:SetScript("OnMouseUp", self.StopSizing)
	end,
	
	OnEnable = function(self)
		self.resizeButton:Show()
	end,
	
	OnDisable = function(self)
		self.resizeButton:Hide()
	end,
	
	GetStandardizedCoordinates = function(self)
		local group = self.group
		local scale = group:GetEffectiveScale()
		
		return
			group:GetLeft()*scale,
			group:GetRight()*scale,
			group:GetTop()*scale,
			group:GetBottom()*scale
	end,
	GetStandardizedCursorCoordinates = function(self)
		-- This method is rather pointless (its just a wrapper),
		-- but having consistency is nice so that I don't have to remember if the coords returned
		-- are comparable to other Standardized coordinates/sizes
		return GetCursorPosition()    
	end,
	GetStandardizedSize = function(self)
		local group = self.group
		local x, y = group:GetSize()
		local scale = group:GetEffectiveScale()
		
		return x*scale, y*scale
	end,

	StartSizing = function(resizeButton)
		local self = resizeButton.module
		local group = self.group
		
		self.std_oldLeft, self.std_oldRight, self.std_oldTop, self.std_oldBottom = self:GetStandardizedCoordinates()
		self.std_oldWidth, self.std_oldHeight = self:GetStandardizedSize()
		
		self.oldScale = group:GetScale()
		self.oldUIScale = UIParent:GetScale()
		self.oldEffectiveScale = group:GetEffectiveScale()
		
		self.oldX, self.oldY = group:GetLeft(), group:GetTop()
		
		resizeButton:SetScript("OnUpdate", self.SizeUpdate)
	end,
	StopSizing = function(resizeButton)
		local self = resizeButton.module
		local group = self.group
		
		resizeButton:SetScript("OnUpdate", nil)
		
		group:CalibrateAnchors()
		
		group:SetPos()
		
		TMW.IE:NotifyChanges()
	end,
}
TMW:NewClass("GroupModule_Resizer_ScaleXY", "GroupModule_Resizer"){
	tooltipText = L["RESIZE_TOOLTIP_SCALEXY"],
	
	SizeUpdate = function(resizeButton)
		--[[ Notes:
		--	arg1 (self) is resizeButton
			
		--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
			More specifically, it means that it does not depend on the scale of either the group nor UIParent.
		]]
		local self = resizeButton.module
		
		local group = self.group
		local gs = group:GetSettings()
		
		local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()
		
		-- Calculate & set new scale:
		local std_newWidth = std_cursorX - self.std_oldLeft
		local ratio_SizeChangeX = std_newWidth/self.std_oldWidth
		local newScaleX = ratio_SizeChangeX*self.oldScale
		
		local std_newHeight = self.std_oldTop - std_cursorY
		local ratio_SizeChangeY = std_newHeight/self.std_oldHeight
		local newScaleY = ratio_SizeChangeY*self.oldScale
		
		--[[
			Holy shit. Look at this wicked sick dimensional analysis:
			
			std_newHeight	oldScale
			------------- X	-------- = newScale
			std_oldHeight	    1

			'std_Height' cancels out 'std_Height', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
			I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
			(which is why I am rewriting it right now)
		]]
		
		local newScale
		if IsControlKeyDown() then
			-- Uses the smaller of the two scales.
			newScale = min(newScaleX, newScaleY)
			newScale = max(0.6, newScale)
		else
			-- Uses the larger of the two scales.
			newScale = max(0.6, newScaleX, newScaleY)
		end

		-- Set the scale that we just determined.
		gs.Scale = newScale
		group:SetScale(newScale)

		
		-- We have all the data needed to find the new position of the group.
		-- It must be recalculated because otherwise it will scale relative to where it is anchored to,
		-- instead of being relative to the group's top left corner, which is what it is supposed to be.
		-- I don't remember why this calculation here works, so lets just leave it alone.
		-- Note that it will be re-re-calculated once we are done resizing.
		local newX = self.oldX * self.oldScale / newScale
		local newY = self.oldY * self.oldScale / newScale
		
		group:ClearAllPoints()
		group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
	end
}
TMW:NewClass("GroupModule_Resizer_ScaleY_SizeX", "GroupModule_Resizer"){
	tooltipText = L["RESIZE_TOOLTIP_SCALEY_SIZEX"],
	UPD_INTV = 1,
	
	SizeUpdate = function(resizeButton)
		--[[ Notes:
		--	arg1 (self) is resizeButton
			
		--	The 'std_' that prefixes a lot of variables means that it is comparable with all other 'std_' variables.
			More specifically, it means that it does not depend on the scale of either the group nor UIParent.
		]]
		local self = resizeButton.module
		
		local group = self.group
		local gs = group:GetSettings()
		local gspv = group:GetSettingsPerView()
		local uiScale = UIParent:GetScale()
		
		local std_cursorX, std_cursorY = self:GetStandardizedCursorCoordinates()

		
		
		-- Calculate & set new scale:
		local std_newHeight = self.std_oldTop - std_cursorY
		local ratio_SizeChangeY = std_newHeight/self.std_oldHeight
		local newScale = ratio_SizeChangeY*self.oldScale
		newScale = max(0.25, newScale)
		--[[
			Holy shit. Look at this wicked sick dimensional analysis:
			
			std_newHeight	oldScale
			------------- X	-------- = newScale
			std_oldHeight	    1

			'std_Height' cancels out 'std_Height', and 'old' cancels out 'old', leaving us with 'new' and 'Scale'!
			I just wanted to make sure I explained why this shit works, because this code used to be confusing as hell
			(which is why I am rewriting it right now)
		]]

		-- Set the scale that we just determined. This is critical because we have to group:GetEffectiveScale()
		-- in order to determine the proper width, which depends on the current scale of the group.
		gs.Scale = newScale
		group:SetScale(newScale)
		
		
		-- We have all the data needed to find the new position of the group.
		-- It must be recalculated because otherwise it will scale relative to where it is anchored to,
		-- instead of being relative to the group's top left corner, which is what it is supposed to be.
		-- I don't remember why this calculation here works, so lets just leave it alone.
		-- Note that it will be re-re-calculated once we are done resizing.
		local newX = self.oldX * self.oldScale / newScale
		local newY = self.oldY * self.oldScale / newScale
		group:ClearAllPoints()
		group:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
		
		
		-- Calculate new width
		local std_newFrameWidth = std_cursorX - self.std_oldLeft
		local std_spacing = gspv.SpacingX*group:GetEffectiveScale()
		local std_newWidth = (std_newFrameWidth + std_spacing)/gs.Columns - std_spacing
		local newWidth = std_newWidth/group:GetEffectiveScale()
		newWidth = max(gspv.SizeY, newWidth)
		gspv.SizeX = newWidth
		
		if not self.LastUpdate or self.LastUpdate <= time - self.UPD_INTV then
			-- Update the group completely very infrequently because of the high CPU usage.
			
			self.LastUpdate = time
			
			-- This needs to be done before we :Setup() or otherwise bad things happen.
			group:CalibrateAnchors()
		
			group:Setup()
		else
			-- Only do the things that will determine most of the group's appearance on every frame.
			
			group.viewData:Group_SetSizeAndScale(group)
			
			for icon in TMW:InIcons(group.ID) do
				group.viewData:Icon_SetSize(icon)
			end
			
			group:SortIcons()
		end
	end
}


local IconType = TMW:NewClass("IconType", "IconComponent", "NamedInstances")

do	-- IconType:InIcons(groupID)
	local states = {}
	local function getstate(cg, ci, mg, mi, type)
		local state = wipe(tremove(states) or {})

		state.cg = cg
		state.ci = ci
		state.mg = mg
		state.mi = mi
		state.type = type

		return state
	end

	local function iter(s)
		s.ci = s.ci + 1
		while true do
			if s.ci <= s.mi and TMW[s.cg] and (not TMW[s.cg][s.ci] or TMW[s.cg][s.ci].Type ~= s.type) then
				s.ci = s.ci + 1
			elseif s.cg < s.mg and (s.ci > s.mi or not TMW[s.cg]) then
				s.cg = s.cg + 1
				s.ci = 1
			elseif s.cg > s.mg then
				tinsert(states, s)
				return
			else
				break
			end
		end
		return TMW[s.cg] and TMW[s.cg][s.ci], s.cg, s.ci -- icon, groupID, iconID
	end

	function IconType:InIcons(groupID)
		return iter, getstate(groupID or 1, 0, groupID or TMW.db.profile.NumGroups, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS, self)
	end
end

function IconType:OnNewInstance(type)
	self.type = type
	self.Icons = {}
	self.UsedAttributes = {}
	self.UsedProcessors = {}
end

function IconType:UpdateColors(dontSetupIcons)
	for k, v in pairs(TMW.db.profile.Colors[self.type]) do
		if v.Override then
			self[k] = v
		else
			self[k] = TMW.db.profile.Colors.GLOBAL[k]
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
	if data then
		local name
		if doInsertLink then
			name = GetSpellLink(data)
		else
			name = GetSpellInfo(data)
		end
		if name then
			return name
		end
	end
	
	return data, true
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

function IconType:Register()
	local typekey = self.type
	
	self.RelevantSettings = self.RelevantSettings or {}
	setmetatable(self.RelevantSettings, RelevantToAll)

	if TMW.debug and rawget(Types, typekey) then
		-- for tweaking and recreating icon types inside of WowLua so that I don't have to change the typekey every time.
		typekey = typekey .. " - " .. date("%X")
		self.name = typekey
	end

	Types[typekey] = self -- put it in the main Types table
	tinsert(TMW.OrderedTypes, self) -- put it in the ordered table (used to order the type selection dropdown in the icon editor)
	
	-- Try to find processors for the attributes declared for the icon type.
	-- It should find most since default processors are loaded before icon types.
	self:UpdateUsedProcessors()
	
	-- Listen for any new processors, too, and update when they are created.
	TMW:RegisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", self.UpdateUsedProcessors, self)
	
	return self -- why not?
end

function IconType:UsesAttributes(attributesString)
	self.UsedAttributes[attributesString] = true
end

function IconType:UpdateUsedProcessors()
	for _, Processor in ipairs(IconDataProcessor.instances) do
		if self.UsedAttributes[Processor.attributesString] then
			self.UsedAttributes[Processor.attributesString] = nil
			self.UsedProcessors[Processor] = true
		end
	end
end

function IconType:OnImplementIntoIcon(icon)
	self.Icons[#self.Icons + 1] = icon

	-- Implement all of the Processors that the Icon Type uses into the icon.
	for Processor in pairs(self.UsedProcessors) do
		Processor:ImplementIntoIcon(icon)
	end
	
	
	-- ProcessorHook:ImplementIntoIcon() needs to happen in a separate loop, 
	-- and not as a method extension of Processor:ImplementIntoIcon(),
	-- because ProcessorHooks need to check and see if the icon is implementing
	-- all of the Processors that the hook has required for the hook to implement itself.
	-- If this were to happen in the first loop here, then it would frequently fail because
	-- dependencies might not be implemented before the hook would get implemented.
	for Processor in pairs(self.UsedProcessors) do
		for _, ProcessorHook in ipairs(Processor.hooks) do
		
			-- Assume that we have found all of the Processors that we need until we can't find one.
			local foundAllProcessors = true
			
			-- Loop over all Processor requirements for this ProcessorHook
			for processorRequirementName in pairs(ProcessorHook.processorRequirements) do
				-- Get the actual Processor instance
				local Processor = TMW.ProcessorsByName[processorRequirementName]
				
				-- If the Processor doesn't exist or the icon doesn't implement it,
				-- fail the test and break the loop.
				if not Processor or not tContains(icon.Components, Processor) then
					foundAllProcessors = false
					break
				end
			end
			
			-- Everything checked out, so implement it into the icon.
			if foundAllProcessors then
				ProcessorHook:ImplementIntoIcon(icon)
			end
		end
	end
end

function IconType:OnUnimplementFromIcon(icon)
	tDeleteItem(self.Icons, icon)
	
	-- Unimplement all of the Processors that the Icon Type uses from the icon.
	for Processor in pairs(self.UsedProcessors) do
	
		-- ProcessorHooks are fine being unimplemented in the same loop since there
		-- is no verification or anything like there is when imeplementing them
		for _, ProcessorHook in ipairs(Processor.hooks) do
			ProcessorHook:UnimplementFromIcon(icon)
		end
		
		Processor:UnimplementFromIcon(icon)
	end
end
--TODO: (misplaced note): implement something like IconModule:RegisterAnchor(frame, identifier, localizedName) so that other modules can anchor to it (mainly texts)
function IconType:SetModuleAllowance(moduleName, allow)
	local IconModule = TMW.Classes[moduleName]
	
	if IconModule and IconModule.SetAllowanceForType then
		IconModule:SetAllowanceForType(self.type, allow)
	elseif not IconModule then
		TMW:RegisterCallback("TMW_CLASS_NEW", function(event, class)
			if class.className == moduleName and class.SetAllowanceForType then
				local IconModule = class
				IconModule:SetAllowanceForType(self.type, allow)
			end
		end)
	end
end

function Icon.IsModuleImplemented(icon, moduleName)
	return icon.Modules[moduleName]
end


local IconView = TMW:NewClass("IconView", "GroupComponent", "IconComponent", "NamedInstances")
IconView.ModuleImplementors = {}
--TODO: consider making all icon views classes instead of just instances of IconView. Create an instance of the class that can be used as a view when :Register() is called.
function IconView:OnNewInstance(view)
	self.view = view
	self.name = view
	
	TMW.Icon_Defaults.SettingsPerView[view] = {}
	self.IconDefaultsPerView = TMW.Icon_Defaults.SettingsPerView[view]
	self:InheritTable(self.class, "ModuleImplementors")
end

function IconView:Register()
	local viewkey = self.view

	if TMW.debug and rawget(Views, viewkey) then
		-- for tweaking and recreating icon views inside of WowLua so that I don't have to change the viewkey every time.
		viewkey = viewkey .. " - " .. date("%X")
		self.name = viewkey
	end

	Views[viewkey] = self -- put it in the main Views table
	tinsert(TMW.OrderedViews, self) -- put it in the ordered table (used to order the type selection dropdown in the icon editor)

	TMW:Fire("TMW_VIEW_REGISTERED", self)
	
	return self -- why not?
end

local function SortModuleImplementors(a, b)
	return a.order < b.order
end
function IconView:ImplementsModule(module, order, implementorFunc)
	TMW:ValidateType(2, "IconView:ImplementsModule()", module, "string")
	TMW:ValidateType(3, "IconView:ImplementsModule()", order, "number")
	
	self.ModuleImplementors[#self.ModuleImplementors+1] = {
		order = order,
		moduleName = module,
		implementorFunc = implementorFunc,
	}
	
	sort(self.ModuleImplementors, SortModuleImplementors)
end

function IconView:OnImplementIntoGroup(group)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		local implementorFunc = implementationData.implementorFunc
		-- implementorFunc is either true if the module is setup within IconView:Group_Setup(),
		-- or it is a function if that function should be called in order to setup the module.
		
		-- Get the class of the module that we might be implementing.
		local ModuleClass = moduleName:find("GroupModule") and TMW.Classes[moduleName]
		
		-- If the class exists and the module should be implemented, then do it.
		if implementorFunc and ModuleClass then
		
			-- Check to see if an instance of the Module already exists for the group before creating one.
			local Module = group.Modules[moduleName]
			if not Module then
				Module = ModuleClass:New(group)
			end
			
			Module.implementationData = implementationData
			
			-- Implement the Module into the group
			Module:ImplementIntoGroup(group)
		end
	end
end

function IconView:OnImplementIntoIcon(icon)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		local implementorFunc = implementationData.implementorFunc
		
		-- implementorFunc is either true if the module is setup within IconView:Icon_Setup(),
		-- or it is a function if that function should be called in order to setup the module.
		
		-- Get the class of the module that we might be implementing.
		local ModuleClass = moduleName:find("IconModule") and TMW.Classes[moduleName]
			
		-- If the class exists and the module should be implemented, then proceed to check Processor requirements.
		if implementorFunc and ModuleClass then
		
			-- Check to see if an instance of the Module already exists for the icon before creating one.
			local Module = icon.Modules[moduleName]
			if not Module then
				Module = ModuleClass:New(icon)
			end
			
			Module.implementationData = implementationData
			
			-- Implement the module into the icon.
			Module:ImplementIntoIcon(icon)
		end
	end
end

function IconView:OnUnimplementFromGroup(group)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		
		-- Make sure that the module is a GroupModule		
		local Module = moduleName:find("GroupModule") and group.Modules[moduleName]
		
		if Module then
			Module:UnimplementFromGroup(group)
			Module.implementationData = nil
		end
	end
end

function IconView:OnUnimplementFromIcon(icon)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		
		-- Make sure that the module is a IconModule
		local Module = moduleName:find("IconModule") and icon.Modules[moduleName]
		
		if Module then
			Module:UnimplementFromIcon(icon)
			Module.implementationData = nil
		end
	end
end

IconView:ImplementsModule("IconModule_IconEventClickHandler", 10, function(Module) Module:Enable() end)

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

function TMW:GetSpellNames(icon, setting, firstOnly, toname, GUID, keepDurations)
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

	if GUID then
		local GUID = {}
		for k, v in ipairs(buffNames) do
			if toname then
				v = GetSpellInfo(v or "") or v -- turn the value into a name if needed
			end

			v = TMW:LowerNames(v)
			GUID[v] = k -- put the final value in the table as well (may or may not be the same as the original value. Value should be NameArrray's key, for use with the duration table.
		end
		return GUID
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
function TMW:GetUnits(icon, setting)
	assert(setting, "Setting was nil for TMW:GetUnits(" .. icon:GetName() .. ", setting)")
	
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
	if icon.Name == "" and not Types[icon.Type].AllowNoName then
		return "Interface\\Icons\\INV_Misc_QuestionMark", nil
	else
	
		if icon.Name ~= "" then
			local tbl = isItem and TMW:GetItemIDs(nil, icon.Name) or TMW:GetSpellNames(nil, icon.Name)

			for _, name in ipairs(tbl) do
				local t = isItem and GetItemIcon(name) or SpellTextures[name]
				if t then
					return t, true
				end
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
function TMW:GetTexturePathFromSetting(setting)
	setting = tonumber(setting) or setting
		
	if setting and setting ~= "" then
		if TMW.ISMOP then
			-- See http://us.battle.net/wow/en/forum/topic/5977979895#1 for the resoning behind this stupid shit right here.
			if SpellTextures[setting] then
				return SpellTextures[setting]
			end
			if strfind(setting, "[\\/]") then -- if there is a slash in it, then it is probably a full path
				return setting
			else
				-- if there isn't a slash in it, then it is probably be a wow icon in interface\icons.
				-- it still might be a file in wow's root directory, but fuck, there is no way to tell for sure
				return "Interface\\Icons\\" .. setting
			end
		else
			TMW.TestTex:SetTexture(SpellTextures[setting])
			if not TMW.TestTex:GetTexture() then
				TMW.TestTex:SetTexture(setting)
			end
			if not TMW.TestTex:GetTexture() then
				TMW.TestTex:SetTexture("Interface\\Icons\\" .. setting)
			end
			return TMW.TestTex:GetTexture()
		end
	end
end

function TMW:GetGroupName(n, g, short)
	if n and n == g then
		n = TMW.db.profile.Groups[g].Name
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
	TMW.db.profile.Locked = not TMW.db.profile.Locked

	TMW:Fire("TMW_LOCK_TOGGLED", TMW.Locked)

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

		local group = groupID and groupID <= TMW.db.profile.NumGroups and TMW[groupID]
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
			obj:Setup() -- obj is an icon or a group
		end

	else
		TMW:LockToggle()
	end
end
TMW:RegisterChatCommand("tmw", "SlashCommand")
TMW:RegisterChatCommand("tellmewhen", "SlashCommand")



local UNITS = TMW:NewModule("Units", "AceEvent-3.0") TMW.UNITS = UNITS
UNITS.mtMap, UNITS.maMap = {}, {}
UNITS.gpMap = {}
UNITS.unitsWithExistsEvent = {}
UNITS.unitsWithBaseExistsEvent = {}

local UnitSet = TMW:NewClass("UnitSet"){

	OnNewInstance = function(self, unitSettings)
		self.unitSettings = unitSettings
		self.originalUnits = UNITS:GetOriginalUnitTable(unitSettings)
		self.updateEvents = {PLAYER_ENTERING_WORLD = true,}
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
				-- we found a unit and we dont really know what the fuck it is.
				-- it MIGHT be a player name (or a derrivative thereof),
				-- so register some events so that we can exchange it out with a real unitID when possible.

				self.updateEvents.RAID_ROSTER_UPDATE = true
				self.updateEvents.PARTY_MEMBERS_CHANGED = true
				self.updateEvents.UNIT_PET = true
				UNITS.doGroupedPlayersMap = true

				self.mightHaveWackyUnitRefs = true
				UNITS:UpdateGroupedPlayersMap()

				self.allUnitsChangeOnEvent = false
			end
		end

		for event in pairs(self.updateEvents) do
			UNITS:RegisterEvent(event, "OnEvent")
		end

		self:Update()
	end,

	Update = function(self)
		local originalUnits, exposedUnits = self.originalUnits, self.exposedUnits
		local hasTankAndAssistRefs = self.hasTankAndAssistRefs
		local mightHaveWackyUnitRefs = self.mightHaveWackyUnitRefs
		for k = 1, #exposedUnits do
			exposedUnits[k] = nil
		end

		for k = 1, #originalUnits do
			local oldunit = originalUnits[k]
			local tankOrAssistWasSubbed, wackyUnitWasSubbed
			if hasTankAndAssistRefs then
				tankOrAssistWasSubbed = UNITS:SubstituteTankAndAssistUnit(oldunit, exposedUnits, #exposedUnits+1)
			end
			if mightHaveWackyUnitRefs then
				wackyUnitWasSubbed = UNITS:SubstituteGroupedUnit(oldunit, exposedUnits, #exposedUnits+1)
			end
			local hasExistsEvent = UNITS.unitsWithExistsEvent[oldunit]
			local baseUnit = UNITS.unitsWithBaseExistsEvent[oldunit]

			if tankOrAssistWasSubbed == nil and wackyUnitWasSubbed == nil and (
				(baseUnit and UnitExists(baseUnit)) or (not baseUnit and (not hasExistsEvent or UnitExists(oldunit)))
			) then
				exposedUnits[#exposedUnits+1] = oldunit
			end
		end
	end,

}

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
	
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local raidunit = "raid" .. i
			if GetPartyAssignment("MAINTANK", raidunit) then
				mtMap[#mtMap + 1] = i
			elseif GetPartyAssignment("MAINASSIST", raidunit) then
				maMap[#maMap + 1] = i
			end
		end
	end
end

if TMW.ISMOP then
	function UNITS:UpdateGroupedPlayersMap()
		local gpMap = UNITS.gpMap

		wipe(gpMap)

		gpMap[strlowerCache[pname]] = "player"
		local petname = UnitName("pet")
		if petname then
			gpMap[strlowerCache[petname]] = "pet"
		end

		-- setup a table with (key, value) pairs as (name, unitID)
		
		if IsInRaid() then
			-- Raid Players
			local numRaidMembers = GetNumGroupMembers()
			for i = 1, numRaidMembers do
				local raidunit = "raid" .. i
				local name = UnitName(raidunit)
				gpMap[strlowerCache[name]] = raidunit
			end
		
			-- Raid Pets (Process after raid players so that players with names the same as pets dont get overwritten)
			for i = 1, numRaidMembers do
				local petunit = "raidpet" .. i
				local name = UnitName(petunit)
				if name then
					-- dont overwrite a player with a pet
					gpMap[strlowerCache[name]] = gpMap[strlowerCache[name]] or petunit
				end
			end
		end
		
		-- Party Players
		local numPartyMembers = GetNumSubgroupMembers()
		for i = 1, numPartyMembers do
			local raidunit = "party" .. i
			local name = UnitName(raidunit)
			gpMap[strlowerCache[name]] = raidunit
		end
		
		-- Party Pets (Process after party players so that players with names the same as pets dont get overwritten)
		for i = 1, numPartyMembers do
			local petunit = "party" .. i
			local name = UnitName(petunit)
			if name then
				-- dont overwrite a player with a pet
				gpMap[strlowerCache[name]] = gpMap[strlowerCache[name]] or petunit
			end
		end
	end
else
	function UNITS:UpdateGroupedPlayersMap()
		local gpMap = UNITS.gpMap

		wipe(gpMap)

		gpMap[strlowerCache[pname]] = "player"
		local petname = UnitName("pet")
		if petname then
			gpMap[strlowerCache[petname]] = "pet"
		end

		-- setup a table with (key, value) pairs as (name, unitID)
		
		-- Raid Players
		local numRaidMembers = GetNumRaidMembers()
		for i = 1, numRaidMembers do
			local raidunit = "raid" .. i
			local name = UnitName(raidunit)
			gpMap[strlowerCache[name]] = raidunit
		end
	
		-- Raid Pets (Process after raid players so that players with names the same as pets dont get overwritten)
		for i = 1, numRaidMembers do
			local petunit = "raidpet" .. i
			local name = UnitName(petunit)
			if name then
				-- dont overwrite a player with a pet
				gpMap[strlowerCache[name]] = gpMap[strlowerCache[name]] or petunit
			end
		end
		
		-- Party Players
		local numPartyMembers = GetNumPartyMembers()
		for i = 1, numPartyMembers do
			local raidunit = "party" .. i
			local name = UnitName(raidunit)
			gpMap[strlowerCache[name]] = raidunit
		end
		
		-- Party Pets (Process after party players so that players with names the same as pets dont get overwritten)
		for i = 1, numPartyMembers do
			local petunit = "party" .. i
			local name = UnitName(petunit)
			if name then
				-- dont overwrite a player with a pet
				gpMap[strlowerCache[name]] = gpMap[strlowerCache[name]] or petunit
			end
		end
	end
end

function UNITS:OnEvent(event, ...)

	if event == "RAID_ROSTER_UPDATE" and UNITS.doTankAndAssistMap then
		UNITS:UpdateTankAndAssistMap()
	end
	if UNITS.doGroupedPlayersMap and (event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "UNIT_PET") then
		UNITS:UpdateGroupedPlayersMap()
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

function UNITS:SubstituteGroupedUnit(oldunit, table, key--[[, putInvalidUnitsBack]])
	for groupedName, groupedUnitID in pairs(UNITS.gpMap) do
		local atBeginning = "^" .. groupedName
		if strfind(oldunit, atBeginning .. "$") or strfind(oldunit, atBeginning .. "%-.") then
			table[key] = gsub(oldunit, atBeginning .. "%-?", groupedUnitID)
			return true
		end
	end
	--if putInvalidUnitsBack then
	--	table[key] = oldunit
	--end
end

do	-- UNITS:TestUnit(unit)
	local TestTooltip = CreateFrame("GameTooltip")
	local name, unitID
	TestTooltip:SetScript("OnTooltipSetUnit", function(self) name, unitID = self:GetUnit() end)
	function UNITS:TestUnit(unit)
		name, unitID = nil
		TestTooltip:SetUnit(unit)
	--	return name, unitID
		return unitID
	end
end


-- TODO: IMPORTANT: ALLOW FOR SOME WAY TO EASILY SET LAYOUT DEFAULTS TO MANY DISPLAYS AT ONCE

DogTag:AddTag("TMW", "TMWFormatDuration", {
	code = TMW:MakeSingleArgFunctionCached(function(seconds)
		return TMW:FormatSeconds(seconds, seconds == 0 or seconds > 10, true)
	end),
	arg = {
		'seconds', 'number', '@req',
	},
	ret = "string",
	static = true,
	doc = L["DT_DOC_TMWFormatDuration"],
	example = '[0.54:TMWFormatDuration] => "0.5"; [20:TMWFormatDuration] => "20"; [80:TMWFormatDuration] => "1:20"; [10000:TMWFormatDuration] => "2:46:40"',
	category = L["TEXTMANIP"]
})

NAMES:UpdateClassColors()
DogTag:AddTag("TMW", "Name", {
	code = function(unit, color)
		return NAMES:TryToAcquireName(unit, color)
	end,
	arg = {
		'unit', 'string;undef', 'player',
		'color', 'boolean', true,
	},
	ret = "string",
	doc = L["DT_DOC_Name"],
	events = "UNIT_NAME_UPDATE#$unit",
	example = ('[Name] => %q; [Name(color=false)] => %q; [Name(unit="Randomdruid")] => %q'):
		format(NAMES:TryToAcquireName("player", true), NAMES:TryToAcquireName("player", false), NAMES.ClassColors.DRUID .. "Randomdruid|r")
	,
	category = L["MISCELLANEOUS"],
})
DogTag:AddTag("TMW", "NameForceUncolored", {
	code = function(unit)
		return NAMES:TryToAcquireName(unit, false)
	end,
	arg = {
		'unit', 'string;undef', 'player',
	},
	ret = "string",
	events = "UNIT_NAME_UPDATE#$unit",
	noDoc = true,
})

--TODO: add dogtag tags to SUG
	