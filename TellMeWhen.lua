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
--L = setmetatable({}, {__index = function() return ("| ! "):rep(12) end}) -- stress testing for text widths
TMW.L = L
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")
local DRData = LibStub("DRData-1.0", true)

local DogTag = LibStub("LibDogTag-3.0", true)

TELLMEWHEN_VERSION = "6.0.1"
TELLMEWHEN_VERSION_MINOR = strmatch(" @project-version@", " r%d+") or ""
TELLMEWHEN_VERSION_FULL = TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR
TELLMEWHEN_VERSIONNUMBER = 60101 -- NEVER DECREASE THIS NUMBER (duh?).  IT IS ALSO ONLY INTERNAL
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
local GetPartyAssignment, InCombatLockdown, IsInGuild =
      GetPartyAssignment, InCombatLockdown, IsInGuild
local GetNumBattlefieldScores, GetBattlefieldScore =
      GetNumBattlefieldScores, GetBattlefieldScore
local GetCursorPosition, GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn =
      GetCursorPosition, GetAddOnInfo, IsAddOnLoaded, LoadAddOn, EnableAddOn
local IsInGroup, IsInRaid, GetNumGroupMembers = -- MoP functions
	  IsInGroup, IsInRaid, GetNumGroupMembers
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
local updatehandler, Locked
local UPD_INTV = 0.06	--this is a default, local because i use it in onupdate functions
local GCD, LastUpdate = 0, 0
local IconsToUpdate, GroupsToUpdate = {}, {}
local loweredbackup = {}
local time = GetTime() TMW.time = time
local clientVersion = select(4, GetBuildInfo())
local addonVersion = tonumber(GetAddOnMetadata("TellMeWhen", "X-Interface"))
TMW.ISMOP = clientVersion >= 50000
local _, pclass = UnitClass("Player")
local pname = UnitName("player")


--TODO: (misplaced note) export any needed text layouts with icons that need them

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
end})

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

function TMW.removeTableDuplicates(table)
	--start at the end of the table so that we dont remove duplicates at the beginning of the table
	local k = #table
	while k > 0 do
		local first, num = tContains(table, table[k], true)
		if num > 1 then
			-- if the current value occurs more than once then remove this entry of it
			tremove(table, k)
		else
			-- there are no duplicates, so move backwards towards zero
			k = k - 1 
		end
	end

end

function TMW.OrderSort(a, b)
	return a.order < b.order
end

function TMW:SortOrderedTables(parentTable)
	sort(parentTable, TMW.OrderSort)
end

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
local safecall = TMW.safecall

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

function TMW:ValidateType(argN, methodName, var, reqType, errLvl)
	local varType = type(var)
	
	local isGood, foundMatch = true, false
	for _, reqType in TMW:Vararg(strsplit(";", reqType)) do
		local negate = reqType:sub(1, 1) == "!"
		local reqType = negate and reqType:sub(2) or reqType
		reqType = reqType:trim(" ")
		
		if reqType == "frame" and varType == "table" and type(var[0]) == "userdata" then
			varType = "frame"
		end
		
		if negate then
			if varType == reqType then
				isGood = false
				break
			end
		else
			if varType == reqType then
				foundMatch = true
			end
		end
	end
	
	if not isGood or not foundMatch then
		error(("Bad argument #%s to %q. %s expected, got %s"):format(argN, methodName, reqType, varType), 3 + (errLvl or 0))
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
		assert(length and length > 6, "GUID length must be more than 6")
		
		-- the first 6 characters are based off of the current time.
		-- anything after the first 6 are random.
		
		-- a length of 10 gives		57289761 possible GUIDs at that exact milisecond the function was called. 
		-- a length of 12 gives 433626201009 possible GUIDs at that exact milisecond the function was called.
		
		-- _G.time is used to get UNIX time. GetTime is used to add millisecond precision,
		-- although it is important to note that the milliseconds have nothing to do with UNIX time.
		local currentTime = _G.time() + (time - floor(time))
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

			state.cg = cg	-- Current Group
			state.ci = ci	-- Current Icon
			state.mg = mg	-- Max Group
			state.mi = mi	-- Max Icon

			return state
		end

		local function iter(state)
			local ci = state.ci
			ci = ci + 1	-- at least increment the icon
			while true do
				if ci <= state.mi and state.cg <= state.mg and TMW.db.profile.Groups[state.cg].Icons and not rawget(TMW.db.profile.Groups[state.cg].Icons, ci) then
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
				local val_a, val_b = sortByValues[a], sortByValues[b]
				if val_a ~= val_b then
					a, b = val_a, val_b
				end
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
	-- because quite frankly, i hate the way LibCallback works.
	local callbackregistry = {}
	function TMW:RegisterCallback(event, func, arg1)
		TMW:ValidateType("2 (event)", "TMW:RegisterCallback(event, func, arg1)", event, "string")
		if not event:find("^TMW_") then
			-- All TMW events must begin with TMW_
			error("TMW events must begin with 'TMW_'", 2)
		end
		
		
		local funcsForEvent
		if callbackregistry[event] then
			funcsForEvent = callbackregistry[event]
		else
			funcsForEvent = {}
			callbackregistry[event] = funcsForEvent
		end
		
		local type_func, type_arg1 = type(func), type(arg1)
		
		if type_func == "string" then
			if type_arg1 == "table" then
				func = arg1[func]
			else
				error("A string was supplied as the function, but a table was not supplied that the function could be pulled from.", 2)
			end
		elseif type_func == "table" then
			if type_arg1 == "nil" then
				arg1 = func
				func = func[event]
			else
				error("If arg3 (func) is a table, arg4 cannot be defined.", 2)
			end
		end
		arg1 = arg1 or true
		
		if type(func) ~= "function" then
			error("We tried really hard, but we couldn't figure the function you wanted to register as the callback!", 2)
		end
		
		

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
							safecall(method, arg1, event, ...)
						else
							safecall(method, event, ...)
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
				safecall(v, instance, ...)
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
					safecall(v, instance, ...)
				end
			end
		end
		
		
		-- now check for the function that exactly matches. this should be called last because
		-- it should be the function that handles the real class being instantiated, not any inherited classes
		local normalFunc = instance[func]
		if normalFunc then
			safecall(normalFunc, instance, ...)
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
	
	local inherit = function(self, source)		
		if source then
			local metatable = getmetatable(self)
			
			local index, didInherit
			if TMW.Classes[source] then
				callFunc(TMW.Classes[source], TMW.Classes[source], "OnClassInherit", self)
				index = getmetatable(TMW.Classes[source]).__index
				didInherit = true
			elseif LibStub(source, true) then
				local lib = LibStub(source, true)
				if lib.Embed then
					lib:Embed(metatable.__index)
					didInherit = true
				else
					error(("Library %q does not hasourcee an Embed method"):format(source), 2)
				end
			elseif type(source) == "table" then
				index = source
				didInherit = true
			else
				local success, frame = pcall(CreateFrame, source)
				if success and frame then
					-- Need to do hide the frame or else if we made an editbox,
					-- it will block all keyboard input for some reason
					frame:Hide()
	
					self.isFrameObject = source or self.isFrameObject
					rawset(self, "isFrameObject", rawget(self, "isFrameObject") or source)
					
					metatable.__index.isFrameObject = metatable.__index.isFrameObject or source
					
					index = getmetatable(frame).__index
					didInherit = true
				end
			end

			if not didInherit then
				error(("Could not figure out how to inherit %s into class %s. Are you sure it exists?"):format(source, self.className), 3)
			end
			
			if index then
				for k, source in pairs(index) do
					metatable.__index[k] = metatable.__index[k] or source
				end
			end
		end
	end
	
	function TMW:NewClass(className, ...)
		TMW:ValidateType(2, "TMW:NewClass()", className, "string")
		
		if TMW.Classes[className] then
			error("TMW: A class with name " .. className .. " already exists. You can't overwrite existing classes, so pick a different name", 2)
		end
		
		local metatable = {
			__index = {},
			__call = __call,
		}
		
		local class = {
			className = className,
			instances = {},
			inherits = {},
			inheritedBy = {},
			embeds = {},
			isTMWClass = true,
		}

		class.instancemeta = {__index = metatable.__index}
		
		setmetatable(class, metatable)
		metatable.__newindex = metatable.__index

		for n, v in TMW:Vararg(TMW.Classes.Class and "Class", ...) do
			--TMW.Warn(strconcat(tostringall(n, v, className, ...)))
		--	if v then
				inherit(class, v)
		---	end
		end

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
				if target[k] and target[k] ~= v and not canOverwrite then
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
		
		Inherit = function(self, source)
			self:AssertSelfIsClass()
		
			inherit(self, source)
		end,
		
		InheritTable = function(self, sourceClass, tableKey)
			TMW:ValidateType(2, "Class:InheritTable()", sourceClass, "table")
			TMW:ValidateType(3, "Class:InheritTable()", tableKey, "string")
			
			self[tableKey] = {}
			for k, v in pairs(sourceClass[tableKey]) do
				self[tableKey][k] = v
			end
			
			-- not needed to return the table, but helpful because
			-- sometimes i set a variable to the result by mistake,
			-- and if i forget that this doesnt work then i spend a long time debugging
			-- trying to figure out why a single attributes table
			-- is shared by all icons... yeah, i did that once.
			return self[tableKey]
		end,
		
		CallFunc = function(self, funcName, ...)
			if self.isTMWClass then
				callFunc(self, self, funcName)
			else
				callFunc(self.class, self, funcName, ...)
			end
		end,
		
		OnClassInherit_Class = function(self, newClass)
			for class in pairs(self.inherits) do
				newClass.inherits[class] = true
				class.inheritedBy[newClass] = true
			end
			
			newClass.inherits[self] = true
			self.inheritedBy[newClass] = true
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
		UnitConditions = true,
		ShowWhen = true,
		Alpha = true,
		UnAlpha = true,
	}
}

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

TMW.Defaults = {
	global = {
		EditorScale		= 0.9,
		EditorHeight	= 600,
		WpnEnchDurs	= {
			["*"] = 0,
		},
		HelpSettings = {
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
				LayoutDirection = 1,
				Tree1 			= true,
				Tree2 			= true,
				Tree3 			= true,
				Tree4 			= true,
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
							}
						},
						Events 					= {
							n					= 0,
							["**"] 				= {
								OnlyShown 		= false,
								Operator 		= "<",
								Value 			= 0,
								CndtJustPassed 	= false,
								PassingCndt		= false,
								PassThrough		= true,
								Icon			= "",
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


TMW.GCDSpells = TMW.ISMOP and {
	ROGUE		= 1752,		-- sinister strike
	PRIEST		= 585,		-- smite
	DRUID		= 5176,		-- wrath
	WARRIOR		= 103840,	-- victory rush
	MAGE		= 44614,	-- frostfire bolt
	WARLOCK		= 686,		-- shadow bolt
	PALADIN		= 105361,	-- seal of command
	SHAMAN		= 403,		-- lightning bolt
	HUNTER		= 3044,		-- arcane shot
	DEATHKNIGHT = 47541,	-- death coil
	MONK		= 100780,	-- jab
} or {
	ROGUE		= 1752,		-- sinister strike
	PRIEST		= 139, 		-- renew
	DRUID		= 774, 		-- rejuvenation
	WARRIOR		= 772, 		-- rend
	MAGE		= 133, 		-- fireball
	WARLOCK		= 687, 		-- demon armor
	PALADIN		= 20154,	-- seal of righteousness
	SHAMAN		= 324,		-- lightning shield
	HUNTER		= 1978,		-- serpent sting
	DEATHKNIGHT = 47541,	-- death coil
}

local GCDSpell = TMW.GCDSpells[pclass] TMW.GCDSpell = GCDSpell


TMW.DS = {
	Magic 	= "Interface\\Icons\\spell_fire_immolation",
	Curse 	= "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison 	= "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}

TMW.BE = TMW.ISMOP and {
	--Most of these are thanks to Malazee @ US-Dalaran's chart: http://forums.wow-petopia.com/download/file.php?mode=view&id=4979 and spreadsheet https://spreadsheets.google.com/ccc?key=0Aox2ZHZE6e_SdHhTc0tZam05QVJDU0lONnp0ZVgzdkE&hl=en#gid=18
	--Major credit to Wowhead (http://www.wowhead.com/guide=1100) for MoP spells
	--Also credit to Damien of Icy Veins (http://www.icy-veins.com/forums/topic/512-mists-of-pandaria-raid-buffs-and-debuffs/) for some MoP spells
	--Many more new spells/corrections were provided by Catok of Curse

	--NOTE: any id prefixed with "_" will have its localized name substituted in instead of being forced to match as an ID
	debuffs = {
		-- NEW IN 6.0.0:
		
		-- VERIFIED 6.0.0:
		ReducedArmor		= "113746",
		PhysicalDmgTaken	= "81326;35290;50518;57386;55749",
		SpellDamageTaken	= "58410;1490;34889;24844",
		ReducedPhysicalDone = "115798;50256;24423",
		ReducedCastingSpeed = "31589;73975;5761;109466;50274;90314;126402;58604",
		ReducedHealing		= "115804",
		Stunned				= "_1833;_408;_91800;_113801;5211;_56;9005;22570;19577;24394;56626;44572;_853;64044;_20549;46968;107102;132168;_30283;_7922;50519;91797;_89766;54786;105593;120086;117418;115001;_131402;108194;117526;105771;_122057;113953;118905",
		Incapacitated		= "20066;1776;_6770;115078",
		Rooted				= "_339;_122;_64695;_19387;33395;_4167;54706;50245;90327;16979;45334;_87194;63685;102359;_128405;116706;123407;115197",
		Disarmed			= "_51722;_676;64058;50541;91644;117368",
		Silenced			= "_47476;_78675;_34490;_55021;_15487;_1330;_24259;_18498;_25046;31935;31117;102051;116709",
		Shatterable			= "122;33395;_44572;_82691", -- by algus2
		Disoriented			= "_19503;31661;_2094;_51514;90337;88625",
		Slowed				= "_116;_120;_13810;_5116;_8056;_3600;_1715;_12323;116095;_115180;45524;_18223;_15407;_3409;26679;_58180;61391;44614;_7302;_8034;_63529;_15571;_7321;_7992;123586", -- by algus2 
		Feared				= "_5782;5246;_8122;10326;1513;111397;_5484;_6789;_87204;20511;112928;113004;113792",
		Bleeding			= "_1822;_1079;9007;33745;1943;_703;_115767;89775;_11977;106830;77758",
		
		-- EXISTING WAS CHECKED, DIDN'T LOOK FOR NEW ONES YET:
		CrowdControl		= "_118;2637;33786;113506;_1499;_19503;_19386;20066;10326;_9484;_6770;_2094;_51514;76780;_710;_5782;_6358;_605;_82691;115078", -- originally by calico0 of Curse
		
		--DontMelee			= "5277;871;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",  --does somebody want to update these for me?
		--MovementSlowed	= "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Ice Trap;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
	},
	buffs = {
		-- NEW IN 6.0.0:
		IncreasedMastery	= "19740;116956;93435;128997",
		IncreasedSP			= "1459;61316;77747;109773;126309",
		
		-- VERIFIED 6.0.0:
		IncreasedAP			= "57330;19506;6673",
		IncreasedPhysHaste  = "55610;113742;30809;128432;128433",
		IncreasedStats		= "1126;115921;20217;90363",
		BonusStamina		= "21562;103127;469;90364",
		IncreasedSpellHaste = "24907;15473;51470",
		IncreasedCrit		= "17007;1459;61316;97229;24604;90309;126373;126309;116781",
		
		-- EXISTING WAS CHECKED, DIDN'T LOOK FOR NEW ONES YET:
		ImmuneToStun		= "642;45438;19574;48792;1022;33786;710;46924;19263;6615",
		ImmuneToMagicCC		= "642;45438;48707;19574;33786;710;46924;19263;31224;8178;23920;49039",
		BurstHaste			= "2825;32182;80353;90355",
		BurstManaRegen		= "29166;16191;64901",
		DefensiveBuffs		= "48707;30823;33206;47585;871;48792;498;22812;61336;5277;74001;47788;19263;6940;31850;31224;42650;86657;118038;115176;115308;120954;115295",
		MiscHelpfulBuffs	= "96267;10060;23920;68992;54428;2983;1850;29166;16689;53271;1044;31821;45182",
		DamageBuffs			= "1719;12292;85730;50334;5217;3045;77801;34692;31884;51713;49016;12472;57933;86700",
	},
	casts = {
		--TODO: UPDATE Heals and PvPSpells for 6.0.0
		--prefixing with _ doesnt really matter here since casts only match by name, but it may prevent confusion if people try and use these as buff/debuff equivs
		Heals				= "50464;5185;8936;740;2050;2060;2061;32546;596;64843;635;82326;19750;331;77472;8004;1064;73920;124682;115175;116694",
		PvPSpells			= "33786;339;20484;1513;982;64901;_605;5782;5484;10326;51514;118;12051",
		Tier11Interrupts	= "_83703;_82752;_82636;_83070;_79710;_77896;_77569;_80734;_82411",
		Tier12Interrupts	= "_97202;_100094",
	},
	dr = {},
} or
{
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
		IncreasedSP			= "_79058;_61316;_52109;77747;53646", -- Backwards compatibility for MoP
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
	-- actually more efficient than a big elseif chain.
	["=="] = function(a, b) return a == b  end,
	["~="] = function(a, b) return a ~= b end,
	[">="] = function(a, b) return a >= b end,
	["<="] = function(a, b) return a <= b  end,
	["<"] = function(a, b) return a < b  end,
	[">"] = function(a, b) return a > b end,
}
TMW.EventList = {}


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
		--local cachestring = TMW:Serialize(...)
		
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
	if  (not self.__ttshowchecker or TMW.get(self[self.__ttshowchecker], self))
	and (self.__title or self.__text)
	then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(TMW.get(self.__title, self), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
		GameTooltip:AddLine(TMW.get(self.__text, self), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, not self.__noWrapTooltipText)
		GameTooltip:Show()
	end
end
local function TTOnLeave(self)
	GameTooltip:Hide()
end

function TMW:TT(f, title, text, actualtitle, actualtext, showchecker)
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

function TMW:TT_Update(f)
	if f:IsMouseOver() and f:IsVisible() then
		f:GetScript("OnLeave")(f)
		if not f.IsEnabled or f:IsEnabled() or f:GetMotionScriptsWhileDisabled() then
			f:GetScript("OnEnter")(f)
		end
	end
end


---------- Table Copying ----------
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

function TMW.deepcopy(object)
	-- http://lua-users.org/wiki/CopyTable
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
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

function TMW:MergeDefaultsTables(src, dest)
	--src and dest must have congruent data structure, otherwise shit will blow up.
	-- There are no safety checks to prevent this.
	
	for k in pairs(src) do
		local src_type, dest_type = type(src[k]), type(dest[k])
		if dest[k] and dest_type == "table" and src_type == "table" then
			TMW:MergeDefaultsTables(src[k], dest[k])
			
		elseif dest_type ~= "nil" and src_type ~= dest_type then
			error(("Type mismatch in merging db default tables! Key: %q; Source type: %q; Destination type: %q"):format(k, src_type, dest_type), 3)
			
		else
			dest[k] = src[k]
		end
	end
	
	return dest -- not really needed, but what the hell why not
end


-- --------------------------
-- EXECUTIVE FUNCTIONS, ETC
-- --------------------------

function TMW:OnInitialize()
	LoadAddOn("LibDogTag-3.0")
	
	if not TMW.Classes.IconView then
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
		StaticPopup_Show("TMW_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "IconView.lua")
		return -- if required, return here
	end

	if LibStub("LibButtonFacade", true) and select(6, GetAddOnInfo("Masque")) == "MISSING" then
		TMW.Warn("TellMeWhen no longer supports ButtonFacade. If you wish to continue to skin your icons, please upgrade to ButtonFacade's successor, Masque.")
	end

	TMW:ProcessEquivalencies()

	--------------- Events/OnUpdate ---------------
	TMW:SetScript("OnUpdate", TMW.OnUpdate)

	TMW:RegisterEvent("PLAYER_ENTERING_WORLD")
	TMW:RegisterEvent("PLAYER_LOGIN")
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
	
	TMW:Fire("TMW_DB_INITIALIZING")

	--------------- Database ---------------
	if type(TellMeWhenDB) ~= "table" then
		-- TellMeWhenDB might not exist if this is a fresh install
		-- or if the user is upgrading from a really old version that uses TellMeWhen_Settings.
		TellMeWhenDB = {Version = TELLMEWHEN_VERSIONNUMBER}
	end
	
	-- Handle upgrades that need to be done before defaults are added to the database.
	-- Primary purpose of this is to properly upgrade settings if a default has changed.
	TMW:GlobalUpgrade()

	TMW.Initialized = true
	
	-- Initialize the database
	TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
	
	-- Handle normal upgrades after the database has been initialized.
	TMW:Upgrade()

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
	
	TMW:Fire("TMW_DB_INITIALIZED")
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
				t.wasPassingCondition = nil --TODO: make this unnecessary
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
	TMW.time = time

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

	TMW:Fire("TMW_ONUPDATE_POST", time, Locked)
end

function TMW:Update()
	TMW:Initialize()
	
	time = GetTime() TMW.time = time
	LastUpdate = 0

	Locked = TMW.db.profile.Locked
	TMW.Locked = Locked

	if not TMW:CheckCanDoLockedAction() then
		return
	end
	
	if not Locked then
		TMW:LoadOptions()
	end
	
	TMW:Fire("TMW_GLOBAL_UPDATE") -- the placement of this matters. Must be after options load, but before icons are updated

	-- Add a very small amount so that we don't call the same icon multiple times
	-- in the same frame if the interval has been set 0.
	UPD_INTV = TMW.db.profile.Interval + 0.001

	for key, Type in pairs(TMW.Types) do
		Type:UpdateColors(true)
	end

	for groupID = 1, max(TMW.db.profile.NumGroups, #TMW) do
		-- cant use TMW.InGroups() because groups wont exist yet on the first call of this, so they would never be able to exists
		-- even if it shouldn't be setup (i.e. it has been deleted or the user changed profiles)
		local group = TMW[groupID] or TMW.Classes.Group:New("Frame", "TellMeWhen_Group" .. groupID, TMW, "TellMeWhen_GroupTemplate", groupID)
		TMW.safecall(group.Setup, group)
	end

	if not Locked then
		TMW:DoValidityCheck()
	end

	TMW:ScheduleTimer("DoWarn", 3)

	TMW:Fire("TMW_GLOBAL_UPDATE_POST")
end

TMW:RegisterEvent("PLAYER_REGEN_DISABLED", function()
	if TMW.ISMOP and not TMW.Locked and TMW.Initialized then
		TMW:LockToggle()
	end
end)

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
				for _, eventSettings in ipairs(Events) do -- dont use InNLengthTable here
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
		[40100] = {
			profile = function(self)
				TMW.db.profile["BarGCD"] = true
				TMW.db.profile["ClockGCD"] = true
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

	-- This will very rarely actually set anything.
	-- TellMeWhenDB.Version is set when then DB is first created,
	-- but, if this setting doesn't yet exist then the user has a really old version
	-- from before TellMeWhenDB.Version existed, so set it to 0 so we make sure to do all of the upgrades here
	TellMeWhenDB.Version = TellMeWhenDB.Version or 0
	
	
	if TellMeWhenDB.Version == 414069 then TellMeWhenDB.Version = 41409 end --well, that was a mighty fine fail
	-- Begin DB upgrades that need to be done before defaults are added.
	-- Upgrades here should always do everything needed to every single profile,
	-- and remember to check if a table exists before iterating/indexing it.

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
	
	TMW:Fire("TMW_DB_PRE_DEFAULT_UPGRADES")
	
	TellMeWhenDB.Version = TELLMEWHEN_VERSIONNUMBER -- pre-default upgrades complete!
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

		TMW:DoUpgrade("global", TellMeWhenDB.Version)
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
		TMW:DoUpgrade("profile", TMW.db.profile.Version)
	elseif type == "profile" then
		-- delegate to groups
		for gs, groupID in TMW:InGroupSettings() do
			TMW:DoUpgrade("group", version, gs, groupID)
		end
		
		--All Upgrades Complete
		TMW.db.profile.Version = TELLMEWHEN_VERSIONNUMBER
	elseif type == "group" then
		local gs, groupID = ...
		
		-- delegate to icons
		for ics, groupID, iconID in TMW:InIconSettings(groupID) do
			TMW:DoUpgrade("icon", version, ics, groupID, iconID)
		end
	end
	
	TMW.HaveUpgradedOnce = true
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
	if d <= 1 then return true end -- a cd of 1 (or less) is always a GCD (or at least isn't worth showing)
	if GCD > 1.7 then return false end -- weed out a cooldown on the GCD spell that might be an interupt (counterspell, mind freeze, etc)
	return GCD == d and d > 0 -- if the duration passed in is the same as the GCD spell, and the duration isnt zero, then it is a GCD
end

function TMW.SpellHasNoMana(spell)
    local _, _, _, cost, _, powerType = GetSpellInfo(spell)
    if powerType then
        local power = UnitPower("player", powerType)
        if power < cost then
			return 1
		end
    end
end

function TMW:PLAYER_ENTERING_WORLD()
	TMW.EnteredWorld = true
	
	if not TMW.debug then
		-- Don't send version broadcast messages in developer mode.
		
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "GUILD")
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "RAID")
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "PARTY")
		TMW:SendCommMessage("TMWV", "M:" .. TELLMEWHEN_VERSION .. "^m:" .. TELLMEWHEN_VERSION_MINOR .. "^R:" .. TELLMEWHEN_VERSIONNUMBER .. "^", "BATTLEGROUND")
	end
end

function TMW:PLAYER_LOGIN()
	if TMW.ISMOP then
		TMW:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	else
		TMW:RegisterEvent("PLAYER_TALENT_UPDATE", "PLAYER_SPECIALIZATION_CHANGED")
		TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED")
	end
	
	-- Yeah,  I do it twice. Masque is a heap of broken shit and doesn't work unless its done twice.
	TMW:Update()
	TMW:Update()
end


function TMW:PLAYER_SPECIALIZATION_CHANGED()
	if not InCombatLockdown() then
		TMW:ScheduleUpdate(.2)
	end
	--TMW:Update()
	
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
			rndstun			= "DR-RandomStun", -- TMW.ISMOP - DOESN'T EXIST IN MOP
			silence			= "DR-Silence",
			banish 			= "DR-Banish",
			mc 				= "DR-MindControl",
			entrapment		= "DR-Entrapment",
			taunt 			= "DR-Taunt",
			disarm			= "DR-Disarm",
			horror			= "DR-Horrify",
			cyclone			= "DR-Cyclone",
			rndroot			= "DR-RandomRoot", -- TMW.ISMOP - DOESN'T EXIST IN MOP
			disorient		= "DR-Disorient",
			ctrlroot		= "DR-ControlledRoot",
			dragons			= "DR-DragonsBreath",
			bindelemental	= "DR-BindElemental",
			charge			= "DR-Charge",
			intercept		= "DR-Intercept", -- TMW.ISMOP - DOESN'T EXIST IN MOP
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
						
						if clientVersion >= addonVersion then -- dont warn for old clients using newer versions
							TMW:Error("Invalid spellID found: %s (%s - %s)! Please report this on TMW's CurseForge page, especially if you are currently on the PTR!", realID, category, equiv)
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
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	
	target = target or self

	local oldLength = #self.UpdateTable_UpdateTable

	if not tContains(self.UpdateTable_UpdateTable, target) then
		tinsert(self.UpdateTable_UpdateTable, target)
		
		self:UpdateTable_PerformAutoSort()
		
		if oldLength == 0 and self.UpdateTable_OnUsed then
			self:UpdateTable_OnUsed()
		end
	end
end
function UpdateTableManager:UpdateTable_Unregister(target)
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	
	target = target or self

	local oldLength = #self.UpdateTable_UpdateTable

	TMW.tDeleteItem(self.UpdateTable_UpdateTable, target, true)
	
	if oldLength ~= #self.UpdateTable_UpdateTable then
		self:UpdateTable_PerformAutoSort()
		
		if oldLength > 0 and #self.UpdateTable_UpdateTable == 0 and self.UpdateTable_OnUnused then
			self:UpdateTable_OnUnused()
		end
	end
end
function UpdateTableManager:UpdateTable_UnregisterAll()
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	local oldLength = #self.UpdateTable_UpdateTable
	
	wipe(self.UpdateTable_UpdateTable)
	
	if oldLength > 0 and self.UpdateTable_OnUnused then
		self:UpdateTable_OnUnused()
	end
end
function UpdateTableManager:UpdateTable_Sort(func)
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	
	sort(self.UpdateTable_UpdateTable, func)
end
function UpdateTableManager:UpdateTable_SetAutoSort(func)
	self.UpdateTable_DoAutoSort = not not func
	if type(func) == "function" then
		self.UpdateTable_DoAutoSort = true
		self.UpdateTable_AutoSortFunc = func
	elseif func == true then
		self.UpdateTable_DoAutoSort = true
		self.UpdateTable_AutoSortFunc = nil
	else
		self.UpdateTable_DoAutoSort = false
	end
end
function UpdateTableManager:UpdateTable_PerformAutoSort()
	if self.UpdateTable_DoAutoSort then
		self:UpdateTable_Sort(self.UpdateTable_AutoSortFunc)
	end
end




local EventHandler = TMW:NewClass("EventHandler", "AceEvent-3.0", "AceTimer-3.0")
TMW.EVENTS = EventHandler
local QueuedIcons = {}
EventHandler.instancesByName = {}

TMW:RegisterUpgrade(50020, {
	-- Upgrade from the old event system that only allowed one event of each type per icon.
	icon = function(self, ics)
		local Events = ics.Events
		for event, eventSettings in pairs(CopyTable(Events)) do -- dont use InNLengthTable here
			if type(event) == "string" and event ~= "n" then
				local addedAnEvent
				for eventHandlerName, EventHandler in pairs(TMW.Classes.EventHandler.instancesByName) do
					local hasHandlerOfType = EventHandler:ProcessIconEventSettings(event, eventSettings)
					if type(rawget(Events, "n") or 0) == "table" then
						Events.n = 0
					end
					if hasHandlerOfType then
						Events.n = (rawget(Events, "n") or 0) + 1
						Events[Events.n] = CopyTable(eventSettings)
						Events[Events.n].Type = eventHandlerName
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
})

function TMW:GetEventHandler(eventHandlerName)
	return EventHandler.instancesByName[eventHandlerName]
end

function TMW:RegisterEventHandlerData(eventHandlerName, ...)
	local EventHandler = TMW:GetEventHandler(eventHandlerName)
	
	if EventHandler then
		EventHandler:RegisterEventHandlerDataNonSpecific(...)
	else
		local args = {...}
		TMW:RegisterCallback("TMW_CLASS_EventHandler_INSTANCE_NEW", function(event, class, EventHandler)
			if EventHandler.eventHandlerName == eventHandlerName then
				EventHandler:RegisterEventHandlerDataNonSpecific(unpack(args))
			end
		end)
	end
end


function EventHandler:OnNewInstance_EventHandler(eventHandlerName)
	self.eventHandlerName = eventHandlerName
	self.AllEventHandlerData = {}
	self.NonSpecificEventHandlerData = {}
	
	EventHandler.instancesByName[eventHandlerName] = self
end

function EventHandler:RegisterEventHandlerDataTable(eventHandlerData)
	-- This function simply makes sure that we can keep track of all eventHandlerData that has been registed.
	-- Without it, we would have to search through every single IconComponent when an event is fired to get this data.
	
	-- Feel free to extend this method in instances of EventHandler to make it easier to perform these data lookups.
	-- But, this method should probably never be called by anything except the event core (no third-party calls)
	
	TMW:ValidateType("eventHandlerData.eventHandler", "EventHandler:RegisterEventHandlerDataTable(eventHandlerData)", eventHandlerData.eventHandler, "table")
	TMW:ValidateType("eventHandlerData.eventHandlerName", "EventHandler:RegisterEventHandlerDataTable(eventHandlerData)", eventHandlerData.eventHandlerName, "string")
	
	TMW.safecall(self.OnRegisterEventHandlerDataTable, self, eventHandlerData, unpack(eventHandlerData))
	
	tinsert(self.AllEventHandlerData, eventHandlerData)
end

function EventHandler:RegisterEventHandlerDataNonSpecific(...)
	-- Registers event handler data that isn't tied to a specific IconComponent.
	-- This method may be overwritten in instances of EventHandler with a method that throws an error if nonspecific event handler data (not tied to an IconComponent) isn't supported.
	
	self:AssertSelfIsInstance()
	
	local eventHandlerData = {
		eventHandler = self,
		eventHandlerName = self.eventHandlerName,
		...,
	}
	
	self:RegisterEventHandlerDataTable(eventHandlerData)
	
	tinsert(self.NonSpecificEventHandlerData, eventHandlerData)
end

function EventHandler:RegisterEventDefaults(defaults)
	assert(type(defaults) == "table", "arg1 to RegisterGroupDefaults must be a table")
	
	if TMW.Initialized then
		error(("Defaults for EventHandler %q are being registered too late. They need to be registered before the database is initialized."):format(self.name or "<??>"))
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, TMW.Icon_Defaults.Events["**"])
end
	
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function(_, icon)
	wipe(icon.EventHandlersSet)

	for _, eventSettings in TMW:InNLengthTable(icon.Events) do
		local event = eventSettings.Event
		if event then
			local EventHandler = TMW:GetEventHandler(eventSettings.Type, true)
			
			local thisHasEventHandlers = EventHandler and EventHandler:ProcessIconEventSettings(event, eventSettings)

			if thisHasEventHandlers then
				TMW:Fire("TMW_ICON_EVENTS_PROCESSED_EVENT_FOR_USE", icon, event, eventSettings)
					
				icon.EventHandlersSet[event] = true
				icon.EventsToFire = icon.EventsToFire or {}
			end
		end
	end
end)

TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", function(event, time, Locked)
	if Locked and QueuedIcons[1] then
		sort(QueuedIcons, TMW.Classes.Icon.ScriptSort)
		for i = 1, #QueuedIcons do
			local icon = QueuedIcons[i]
			safecall(icon.ProcessQueuedEvents, icon)
		end
		wipe(QueuedIcons)
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", function(event, time, Locked)
	wipe(QueuedIcons)
end)

local runEvents = 1
local runEventsTimerHandler
function TMW:RestoreEvents()
	runEvents = 1
end
TMW:RegisterCallback("TMW_ICON_SETUP_PRE", function()
	-- make sure events dont fire while, or shortly after, we are setting up
	runEvents = nil
	
	TMW:CancelTimer(runEventsTimerHandler, 1)
	runEventsTimerHandler = TMW:ScheduleTimer("RestoreEvents", UPD_INTV*2.1)
end)









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
	

	GetModuleOrModuleChild = function(self, moduleName, allowDisabled)
		local Modules = self.Modules
		
		local Module = Modules[moduleName]
		if Module and (allowDisabled or Module.IsEnabled) then
			return Module
		else
			local ModuleClassToSearchFor = TMW.Classes[moduleName]
			
			if not ModuleClassToSearchFor then
				error(("Class %q does not exist! (ModuleImplementor:GetModuleOrModuleChild(moduleName))"):format(moduleName), 2)
			end
			
			for _, Module in pairs(Modules) do
				if Module.class.inherits[ModuleClassToSearchFor] and (allowDisabled or Module.IsEnabled) then
					return Module
				end
			end
		end
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

local Group = TMW:NewClass("Group", "Frame", "UpdateTableManager", "GenericModuleImplementor")
Group:UpdateTable_Set(GroupsToUpdate)

function Group.OnNewInstance(group, ...)
	local _, name, _, _, groupID = ... -- the CreateFrame args
	TMW[groupID] = group

	group.ID = groupID
	group.SortedIcons = {}
	group.SortedIconsManager = UpdateTableManager:New()
	group.SortedIconsManager:UpdateTable_Set(group.SortedIcons)
end

function Group.__tostring(group)
	return group:GetName()
end

function Group.ScriptSort(groupA, groupB)
	local gOrder = -TMW.db.profile.CheckOrder
	return groupA.ID*gOrder < groupB.ID*gOrder
end
Group:UpdateTable_SetAutoSort(Group.ScriptSort)
TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", "UpdateTable_PerformAutoSort", Group)

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
				local a, b = attributesA.realAlpha, attributesB.realAlpha
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
				local a, b = (attributesA.shown and attributesA.realAlpha > 0) and 1 or 0, (attributesB.shown and attributesB.realAlpha > 0) and 1 or 0
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

--TODO: make group icon sorting into a group module. Icon placement in general should be handled by a module.
-- Also make icon sorting itself much more modular (to allow extensions)
function Group.SortIcons(group)
	local SortedIcons = group.SortedIcons
	sort(SortedIcons, group.IconSorter)

	for positionedID = 1, #SortedIcons do
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
	local ConditionObject = group.ConditionObject
	local ShouldUpdateIcons = group:ShouldUpdateIcons()
	if (ConditionObject and ConditionObject.Failed) or (not ShouldUpdateIcons) then
		group:Hide()
	elseif ShouldUpdateIcons then
		group:Show()
	end
end

function Group.TMW_CNDT_OBJ_PASSING_CHANGED(group, event, ConditionObject, failed)
	if group.ConditionObject == ConditionObject then
		group:Update()
	end
end

TMW:RegisterCallback("TMW_CONFIG_ICON_RECONCILIATION_REQUESTED",
function(event, replace, limitSourceGroup)
	for gs, groupID in TMW:InGroupSettings() do
		if not limitSourceGroup or groupID == limitSourceGroup then
			if type(gs.Point.relativeTo) == "string" then
				replace(gs.Point, "relativeTo")
			end
		end
	end
end)

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

	local GetActiveTalentGroup = GetActiveTalentGroup
	local GetPrimaryTalentTree = GetPrimaryTalentTree
	if TMW.ISMOP then
		GetActiveTalentGroup = GetActiveSpecGroup
		GetPrimaryTalentTree = GetSpecialization
	end

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




function Group.Setup_Conditions(group)
	-- Clear out/reset any previous conditions and condition-related stuff on the group
	group.ConditionObject = nil
	TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", group)
	
	-- Determine if we should process conditions
	if group:ShouldUpdateIcons() and Locked and group.Conditions_GetConstructor then
		-- Get a constructor to make the ConditionObject
		local ConditionObjectConstructor = group:Conditions_GetConstructor(group.Conditions)
		
		-- If the group is set to only show in combat, add a condition to handle it.
		if group.OnlyInCombat then
			local combatCondition = ConditionObjectConstructor:Modify_WrapExistingAndAppendNew()
			combatCondition.Type = "COMBAT"		
		end
		
		-- Modifications are done. Construct the ConditionObject
		group.ConditionObject = ConditionObjectConstructor:Construct()
		
		if group.ConditionObject then
			-- Setup the event handler and the update table if a ConditionObject was returned
			-- (meaning that there are conditions that need to be checked)
			group:UpdateTable_Register()
	
			TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", group)
		else
			group:UpdateTable_Unregister()
		end
	else
		group:UpdateTable_Unregister()
	end
end
	
function Group.Setup(group)
	local gs = group:GetSettings()
	local groupID = group:GetID()
	
	for k, v in pairs(TMW.Group_Defaults) do
		group[k] = TMW.db.profile.Groups[groupID][k]
	end
	
	group.__shown = group:IsShown()
	
	group.numIcons = group.Rows * group.Columns
	
	local viewData_old = group.viewData
	local viewData = TMW.Views[gs.View]
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
		for iconID = 1, group.numIcons do
			local icon = group[iconID]
			if not icon then
				icon = TMW.Classes.Icon:New("Button", group:GetName() .. "_Icon" .. iconID, group, "TellMeWhen_IconTemplate", iconID)
			end

			TMW.safecall(icon.Setup, icon)
		
			group.SortedIconsManager:UpdateTable_Register(icon)
		end

		for iconID = group.numIcons+1, #group do
			local icon = group[iconID]
			icon:DisableIcon()
			group.SortedIconsManager:UpdateTable_Unregister(icon)
		end
		group.shouldSortIcons = group.SortPriorities[1].Method ~= "id" and group.numIcons > 1
	else
		for iconID = 1, #group do
			local icon = group[iconID]
			icon:DisableIcon()
			group.SortedIconsManager:UpdateTable_Unregister(icon)
		end
		group.shouldSortIcons = false
	end

	group:SortIcons()

	group:Setup_Conditions()

	group:Update()
	
	TMW:Fire("TMW_GROUP_SETUP_POST", group)
end

 

-- ------------------
-- ICONS
-- ------------------


local Icon = TMW:NewClass("Icon", "Button", "UpdateTableManager", "GenericModuleImplementor")
Icon:UpdateTable_Set(IconsToUpdate)
Icon.IsIcon = true
Icon.attributes = {}
	
function Icon.OnNewInstance(icon, ...)
	local _, name, group, _, iconID = ... -- the CreateFrame args

	icon.group = group
	icon.ID = iconID
	group[iconID] = icon
	
	icon.EventHandlersSet = {}
	icon.EssentialModuleComponents = {}
	icon.lmbButtonData = {}
	icon.position = {}
	icon.anchorableChildren = {}
	
	icon.attributes = icon:InheritTable(Icon, "attributes")
end

function Icon.__lt(icon1, icon2)
	local g1 = icon1.group.ID
	local g2 = icon2.group.ID
	if g1 ~= g2 then
		return g1 < g2
	else
		return icon1.ID < icon2.ID
	end
end

function Icon.__tostring(icon)
	return icon:GetName()
end

function Icon.ScriptSort(iconA, iconB)
	local gOrder = -TMW.db.profile.CheckOrder
	local gA = iconA.group.ID
	local gB = iconB.group.ID
	if gA == gB then
		local iOrder = -TMW.db.profile.Groups[gA].CheckOrder
		return iconA.ID*iOrder < iconB.ID*iOrder
	end
	return gA*gOrder < gB*gOrder
end
Icon:UpdateTable_SetAutoSort(Icon.ScriptSort)
TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", "UpdateTable_PerformAutoSort", Icon)

Icon.SetScript_Blizz = Icon.SetScript
function Icon.SetScript(icon, handler, func)
	icon[handler] = func
	icon:SetScript_Blizz(handler, func)
end

function Icon.CheckUpdateTableRegistration(icon)
	if icon.UpdateFunction then
		icon:UpdateTable_Register()
	else
		icon:UpdateTable_Unregister()
	end
end

function Icon.SetUpdateFunction(icon, func)
	
	icon.UpdateFunction = func
	
	if not icon.IsSettingUp then
		icon:CheckUpdateTableRegistration()
	end
end

Icon.RegisterEvent_Blizz = Icon.RegisterEvent
function Icon.RegisterEvent(icon, event)
	icon:RegisterEvent_Blizz(event)
	icon.hasEvents = 1
end

Icon.UnregisterAllEvents_Blizz = Icon.UnregisterAllEvents
function Icon.UnregisterAllEvents(icon, event)
	-- UnregisterAllEvents_Blizz uses a metric fuckton of CPU, so only do it if needed
	if icon.hasEvents then
		icon:UnregisterAllEvents_Blizz()
		icon.hasEvents = nil
	end
end

function Icon.OnShow(icon)
	icon:SetInfo("shown", true)
end
function Icon.OnHide(icon)
	icon:SetInfo("shown", false)
end

function Icon.GetSettings(icon)
	return TMW.db.profile.Groups[icon.group:GetID()].Icons[icon:GetID()]
end

function Icon.GetSettingsPerView(icon, view)
	view = view or icon.group:GetSettings().View
	return icon:GetSettings().SettingsPerView[view]
end

function Icon.IsBeingEdited(icon)
	if TMW.IE and TMW.CI.ic == icon and TMW.IE.CurrentTab and TMW.IE:IsVisible() then
		return TMW.IE.CurrentTab:GetID()
	end
end

local activeModuleChildren = {}
function Icon.GetActiveModuleChildrenNames(icon)
	wipe(activeModuleChildren)
	
	for moduleName, Module in pairs(icon.Modules) do
		if Module.IsImplemented then
			for name in pairs(Module.anchorableChildren) do
				tinsert(activeModuleChildren, moduleName .. name)
			end
		end
	end
	
	return unpack(activeModuleChildren)
end

function Icon.GetModuleChildFrame(icon, identifier)
	return _G[icon:GetName() .. identifier]
end


function Icon.QueueEvent(icon, arg1)
	icon.EventsToFire[arg1] = true
	icon.eventIsQueued = true
	
	QueuedIcons[#QueuedIcons + 1] = icon
end

function Icon.IsValid(icon)
	-- checks if the icon should be in the list of icons that can be checked in metas/conditions

	return icon.Enabled and icon:GetID() <= icon.group.Rows*icon.group.Columns and icon.group:IsValid()
end

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


local IconEventUpdateEngine = CreateFrame("Frame")
TMW.IconEventUpdateEngine = IconEventUpdateEngine
IconEventUpdateEngine.UpdateEvents = setmetatable({}, {__index = function(self, event)
	self[event] = {}
	return self[event]
end})
IconEventUpdateEngine:SetScript("OnEvent", function(self, event, arg1)
	local iconsForEvent = self.UpdateEvents[event]
	for icon, arg1ToMatch in pairs(iconsForEvent) do
		if arg1ToMatch == true or arg1ToMatch == arg1 then
			icon.NextUpdateTime = 0
		end
	end
end)
function Icon.RegisterSimpleUpdateEvent(icon, event, arg1)
	arg1 = arg1 or true
	
	local iconsForEvent = IconEventUpdateEngine.UpdateEvents[event]
	local existing = iconsForEvent[icon]
	if existing and existing ~= arg1 then
		error("Can't change the arg that you are checking for an event without unregistering first", 2)
	end
	iconsForEvent[icon] = arg1
	IconEventUpdateEngine:RegisterEvent(event)
end
function Icon.UnregisterSimpleUpdateEvent(icon, event)
	local iconsForEvent = rawget(IconEventUpdateEngine.UpdateEvents, event)
	if iconsForEvent then
		iconsForEvent[icon] = nil
		if not next(iconsForEvent) then
			IconEventUpdateEngine:UnregisterEvent(event)
		end
	end
end
function Icon.UnregisterAllSimpleUpdateEvents(icon)
	for event, iconsForEvent in pairs(IconEventUpdateEngine.UpdateEvents) do
		iconsForEvent[icon] = nil
		if not next(iconsForEvent) then
			IconEventUpdateEngine:UnregisterEvent(event)
		end
	end
end


function Icon.Update(icon, force, ...)
	local attributes = icon.attributes
	
	if attributes.shown and (force or icon.LastUpdate <= time - UPD_INTV) then
		local Update_Method = icon.Update_Method
		icon.LastUpdate = time

		local ConditionObject = icon.ConditionObject
		if ConditionObject then
			-- The condition check needs to come before we determine iconUpdateNeeded because
			-- checking a condition may set NextUpdateTime to 0 if the condition passing state changes.
			if ConditionObject.UpdateNeeded or ConditionObject.NextUpdateTime < time then
				ConditionObject:Check()
			end
		end

		local iconUpdateNeeded = force or Update_Method == "auto" or icon.NextUpdateTime < time

		if iconUpdateNeeded then
			icon:UpdateFunction(time, ...)
			if Update_Method == "manual" then
				icon:ScheduleNextUpdate()
			end
		end
	end
end

function Icon.TMW_CNDT_OBJ_PASSING_CHANGED(icon, event, ConditionObject, failed)
	-- failed is boolean, never nil. nil is used for the conditionFailed attribute if there are no conditions on the icon.
	if icon.ConditionObject == ConditionObject then
		icon.NextUpdateTime = 0
		-- alpha is set here to force an update on it
		icon:SetInfo("conditionFailed", failed)
	end
end

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
				if EventSettings.OnlyShown and icon.attributes.realAlpha <= 0 then
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
					local EventHandler = TMW:GetEventHandler(EventSettings.Type, true)
					if EventHandler then
						local handled = EventHandler:HandleEvent(icon, EventSettings)
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

function Icon.DisableIcon(icon)
	
	icon:UnregisterAllEvents()
	icon:UnregisterAllSimpleUpdateEvents()
	ClearScripts(icon)
	icon:SetUpdateFunction(nil)
	icon:Hide()

	icon:DisableAllModules()
	
	if icon.typeData then
		icon.typeData:UnimplementFromIcon(icon)
	end
	
	if icon.viewData then
		icon.viewData:UnimplementFromIcon(icon)
	end
	
	TMW:Fire("TMW_ICON_DISABLE", icon)
end

function Icon.Setup(icon)
	if not icon or not icon[0] then return end
	
	local iconID = icon:GetID()
	local group = icon.group
	local groupID = group:GetID()
	local ics = icon:GetSettings()
	local typeData = TMW.Types[ics.Type]
	local viewData = group.viewData
	
	if not group:ShouldUpdateIcons() then return end
	
	icon.IsSettingUp = true
	
	local typeData_old = icon.typeData
	
	icon:DisableIcon()
	
	icon.viewData = viewData
	icon.typeData = typeData	

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
	icon.ConditionObject = ConditionObjectConstructor:Construct()
	
	if icon.ConditionObject then
		TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", icon)
		icon:SetInfo("conditionFailed", icon.ConditionObject.Failed)
	else
		TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", icon)
		icon:SetInfo("conditionFailed", nil)
	end

	-- force an update
	icon.LastUpdate = 0
	
	-- actually run the icon's update function
	if icon.Enabled or not Locked then
	
		------------ Icon Type ------------
		typeData:ImplementIntoIcon(icon)
		
		if icon.typeData ~= typeData_old then
			TMW:Fire("TMW_ICON_TYPE_CHANGED", icon, typeData, typeData_old)
		end		
		
		------------ Icon View ------------
		viewData:ImplementIntoIcon(icon)
		viewData:Icon_Setup(icon)
		
		
		TMW.safecall(typeData.Setup, typeData, icon, groupID, iconID)
	else
		icon:DisableIcon()
	end

	icon.NextUpdateTime = 0

	if Locked then	
		icon:SetInfo("alphaOverride", nil)
		if icon.attributes.texture == "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled" then
			icon:SetInfo("texture", "")
		end
		icon:EnableMouse(0)
	else
		icon:Show()
		ClearScripts(icon)
		icon:SetUpdateFunction(nil)
		
		icon:SetInfo(
			"alphaOverride; start, duration; stack, stackText",
			icon.Enabled and 1 or 0.5,
			0, 0,
			nil, nil
		)
		
		if icon.attributes.texture == "" then
			icon:SetInfo("texture", "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
		end

		icon:EnableMouse(1)
	end
	
	icon:CheckUpdateTableRegistration()

	TMW:Fire("TMW_ICON_SETUP_POST", icon)
	
	icon.IsSettingUp = nil
end

function Icon.SetupAllModulesForIcon(icon, sourceIcon)
	for moduleName, Module in pairs(icon.Modules) do
		if Module.SetupForIcon and Module.IsEnabled and not Module.dontInherit then
			TMW.safecall(Module.SetupForIcon, Module, sourceIcon)
		end
	end
end

function Icon.SetModulesToEnabledStateOfIcon(icon, sourceIcon)
	local sourceModules = sourceIcon.Modules
	for moduleName, Module in pairs(icon.Modules) do
		if Module.IsImplemented and not Module.dontInherit then
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

TMW.IconAlphaManager = {
	AlphaHandlers = {},
	
	HandlerSorter = function(a, b)
		return a.order < b.order
	end,
	
	UPDATE = function(self, event, icon)
		local attributes = icon.attributes
		local AlphaHandlers = self.AlphaHandlers
		
		local handlerToUse
		
		for i = 1, #AlphaHandlers do
			local handler = AlphaHandlers[i]
			
			local alpha = attributes[handler.attribute]
			
			if alpha == 0 then
				-- If an alpha is set to 0, then the icon should be hidden no matter what, 
				-- so use it as the final alpha value and stop looking for more.
				-- This functionality has existed in TMW since practically day one, by the way. So don't be clever and remove it.
				handlerToUse = handler
				break
			elseif alpha ~= nil then
				if handler.haltImmediatelyIfFound then
					-- This is currently only used for ALPHAOVERRIDE
					handlerToUse = handler
					break
				elseif not handlerToUse then
					-- If we found an alpha value that isn't nil and we haven't figured out
					-- an alpha value to use yet, use this one, but keep looking for 0 values.
					handlerToUse = handler
				end
			end
		end
		
		if handlerToUse then			
			-- realAlpha stores the alpha that the icon should be showing, before FakeHidden.
			icon:SetInfo_INTERNAL("realAlpha", attributes[handlerToUse.attribute])
		end
	end,
	
	SetupHandler = function(handler)
		local self = handler.self
		
		local IconDataProcessor = TMW.ProcessorsByName[handler.processorName]
		if IconDataProcessor then
			if IconDataProcessor.NumAttributes ~= 1 then
				error("IconModule_Alpha handlers cannot check IconDataProcessors that have more than one attribute!")
			end
			
			handler.attribute = IconDataProcessor.attributesStringNoSpaces
			
			TMW:RegisterCallback(IconDataProcessor.changedEvent, "UPDATE", self)
			
			TMW:UnregisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", self.SetupHandler, handler)
		end
	end,

	-- PUBLIC METHOD (ish)
	AddHandler = function(self, order, processorName, haltImmediatelyIfFound)
		TMW:ValidateType(2, "IconAlphaManager:AddHandler()", order, "number")
		TMW:ValidateType(3, "IconAlphaManager:AddHandler()", processorName, "string")
		
		local handler = {
			self = self,
			order = order,
			processorName = processorName,
			haltImmediatelyIfFound = haltImmediatelyIfFound,
		}
		
		tinsert(self.AlphaHandlers, handler)
		
		sort(self.AlphaHandlers, self.HandlerSorter)
		
		if TMW.ProcessorsByName[processorName] then
			self.SetupHandler(handler)
		else
			TMW:RegisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", self.SetupHandler, handler)
		end
		
	end,	
}

function TMW:RegisterDatabaseDefaults(defaults)
	assert(type(defaults) == "table", "arg1 to RegisterProfileDefaults must be a table")
	
	if TMW.Initialized then
		error("Defaults are being registered too late. They need to be registered before the database is initialized.", 2)
	end
		
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, TMW.Defaults)
end

TMW.RapidSettings = {
	-- settings that can be changed very rapidly, i.e. via mouse wheel or in a color picker
	-- consecutive changes of these settings will be ignored by the undo/redo module
	r = true,
	g = true,
	b = true,
	a = true,
	Size = true,
	Level = true,
	Alpha = true,
	UnAlpha = true,
}
function TMW:RegisterRapidSetting(setting)
	TMW.RapidSettings[setting] = true
end

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
	
	RegisterConfigPanel = function(self, order, panelType, supplementalData)
		self:AssertIsProtectedCall("Use the RegisterConfigPanel_<type> functions instead.")
		
		local t = {
			component = self,
			panelType = panelType,
			order = order,
			supplementalData = supplementalData,
		}
		
		self.ConfigPanels[#self.ConfigPanels + 1] = t
		return t
	end,
	RegisterConfigPanel_XMLTemplate = function(self, order, xmlTemplateName, supplementalData)
		TMW:ValidateType(2, "GenericComponent:RegisterConfigPanel_XMLTemplate()", order, "number")
		TMW:ValidateType(3, "GenericComponent:RegisterConfigPanel_XMLTemplate()", xmlTemplateName, "string")
		
		local t = self:RegisterConfigPanel(order, "XMLTemplate", supplementalData)
		
		t.xmlTemplateName = xmlTemplateName
	end,
	RegisterConfigPanel_ConstructorFunc = function(self, order, frameName, func, supplementalData)
		TMW:ValidateType(2, "GenericComponent:RegisterConfigPanel_XMLTemplate()", order, "number")
		TMW:ValidateType(3, "GenericComponent:RegisterConfigPanel_ConstructorFunc()", frameName, "string")
		TMW:ValidateType(4, "GenericComponent:RegisterConfigPanel_ConstructorFunc()", func, "function")
		
		local t = self:RegisterConfigPanel(order, "ConstructorFunc", supplementalData)
		
		t.frameName = frameName
		t.func = func
	end,
	ShouldShowConfigPanels = function(self, icon)
		-- Defaults to true. Subclasses of GenericComponent can overwrite this function for their own usage.
		return true
	end,
	
	RegisterDogTag = function(self, ...)
		-- just a wrapper so that i don't have to LibStub DogTag everywhere
		DogTag:AddTag(...)
	end,
	
	RegisterIconEvent = function(self, order, event, eventData)
		TMW:ValidateType("2 (order)", "[GenericComponent]:RegisterIconEvent()", order, "number")
		TMW:ValidateType("3 (event)", "[GenericComponent]:RegisterIconEvent()", event, "string")
		TMW:ValidateType("4 (eventData)", "[GenericComponent]:RegisterIconEvent()", eventData, "table")
		
		TMW:ValidateType("event", "eventData", eventData.event, "nil")
		TMW:ValidateType("order", "eventData", eventData.order, "nil")
		
		TMW:ValidateType("text", "eventData", eventData.text, "string;nil")
		TMW:ValidateType("desc", "eventData", eventData.desc, "string;nil")
		TMW:ValidateType("settings", "eventData", eventData.settings, "table;nil")
		TMW:ValidateType("valueName", "eventData", eventData.valueName, "string;nil")
		TMW:ValidateType("conditionChecker", "eventData", eventData.conditionChecker, "function;nil")
		
		eventData.event = event
		eventData.order = order
		
		if TMW.EventList[event] then
			error(("An event with the event identifier %q already exists!"):format(event), 2)
		end
		
		TMW.EventList[#TMW.EventList + 1] = eventData
		TMW.EventList[event] = eventData
		
		self.IconEvents[#self.IconEvents + 1] = eventData
	end,
	
}

TMW:NewClass("IconComponent", "GenericComponent"){
	IconSettingDefaults = {},
	EventHandlerData = {},
	
	OnClassInherit_IconComponent = function(self, newClass)
		newClass:InheritTable(self, "IconSettingDefaults")
		newClass:InheritTable(self, "EventHandlerData")
	end,
	OnNewInstance_IconComponent = function(self)
		self:InheritTable(self.class, "IconSettingDefaults")
	end,
	
	RegisterEventHandlerData = function(self, eventHandlerName, ...)
		local EventHandler = TMW:GetEventHandler(eventHandlerName)
		local eventHandlerData = {
			eventHandler = EventHandler,
			eventHandlerName = eventHandlerName,
			...,
		}
		
		if EventHandler then
			EventHandler:RegisterEventHandlerDataTable(eventHandlerData)
			
			tinsert(self.EventHandlerData, eventHandlerData)
		else
			TMW:RegisterCallback("TMW_CLASS_EventHandler_INSTANCE_NEW", function(event, class, EventHandler)
				if EventHandler.eventHandlerName == eventHandlerName then
					eventHandlerData.eventHandler = EventHandler
		
					EventHandler:RegisterEventHandlerDataTable(eventHandlerData)
					
					tinsert(self.EventHandlerData, eventHandlerData)
				end
			end)
		end
	end,
	
	RegisterIconDefaults = function(self, defaults)
		assert(type(defaults) == "table", "arg1 to RegisterIconDefaults must be a table")
		
		if TMW.Initialized then
			error(("Defaults for module %q are being registered too late. They need to be registered before the database is initialized."):format(self.name))
		end
		
		-- Copy the defaults into the main defaults table.
		TMW:MergeDefaultsTables(defaults, TMW.Icon_Defaults)
		
		-- Copy the defaults into defaults for this component. Used to implement relevant settings.
		TMW:MergeDefaultsTables(defaults, self.IconSettingDefaults)
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
				TMW.safecall(self.OnImplementIntoIcon, self, icon)
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
		TMW:MergeDefaultsTables(defaults, TMW.Group_Defaults)
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
TMW:NewClass("IconDataProcessorComponent", "IconComponent"){
	SIUVs = {},
	
	DeclareUpValue = function(self, variables, ...)
		assert(type(variables) == "string", "IconDataProcessor:DeclareUpValue(variables, ...) - variables must be a string")
		self.SIUVs[#self.SIUVs+1] = {
			variables = variables,
			...,
		}
	end,
	
	CreateDogTagEventString = function(self)
		return TMW:CreateDogTagEventString(self.name)
	end,
}

local IconDataProcessor = TMW:NewClass("IconDataProcessor", "IconDataProcessorComponent"){
	UsedTokens = {},
	NumAttributes = 0,
	
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
				self.NumAttributes = self.NumAttributes + 1
			end
		end
		
		TMW.ProcessorsByName[self.name] = self
		self:DeclareUpValue(name, self)
		self:DeclareUpValue(attributes) -- do this to prevent accidental leaked global accessing
		
		self.changedEvent = "TMW_ICON_DATA_CHANGED_" .. name
		
		TMW:ClearSetInfoFunctionCache()
	end,
	AssertDependency = function(self, dependency)
		if not TMW.ProcessorsByName[dependency] then
			error(("Dependency %q of processor %q was not found!"):format(dependency, self.name), 2)
		end
	end,
	CompileFunctionHooks = function(self, t, orderRequested)
		for _, ProcessorHook in ipairs(self.hooks) do
			for func, order in pairs(ProcessorHook.funcs) do
				if order == orderRequested then
					t[#t+1] = "\n"
					TMW.safecall(func, self, t)
					t[#t+1] = "\n"
				end
			end
		end
	end,

	CompileFunctionSegment = function(self, t)
		if self.NumAttributes ~= 1 then
			error(("IconDataProcessor %q must declare its own CompileFunctionSegment method if it doesn't have only one attribute"):format(self.name))
		end
		
		local attribute = self.attributesStringNoSpaces
		
		t[#t+1] = [[if attributes.]]
		t[#t+1] = attribute
		t[#t+1] = [[ ~= ]]
		t[#t+1] = attribute
		t[#t+1] = [[ then
			attributes.]]
			t[#t+1] = attribute
			t[#t+1] = [[ = ]]
			t[#t+1] = attribute
			t[#t+1] = [[

			TMW:Fire("]]
			t[#t+1] = self.changedEvent
			t[#t+1] = [[", icon, ]]
			t[#t+1] = attribute
			t[#t+1] = [[)
			doFireIconUpdated = true
		end
		--]]
	end,
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

local function SetInfo_GenerateFunction(signature, isInternal)
	local originalSignature = signature
	
	signature = signature:gsub(" ", "")
	
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
		local match
		for _, Processor in ipairs(IconDataProcessor.instances) do
		
			match = signature:match("^(" .. Processor.attributesStringNoSpaces .. ")$") -- The attribute string is the only one in the signature
				 or	signature:match("^(" .. Processor.attributesStringNoSpaces .. ";)") -- The attribute string is the first one in the signature
				 or	signature:match("(;" .. Processor.attributesStringNoSpaces .. ")$") -- The attribute string is the last one in the signature
				 or	signature:match(";(" .. Processor.attributesStringNoSpaces .. ";)") -- The attribute string is in the middle of the signature
				 
			if match then
				t[#t+1] = "local Processor = "
				t[#t+1] = Processor.name
				t[#t+1] = "\n"
				
				-- Process any hooks that should go before the main function segment
				Processor:CompileFunctionHooks(t, "pre")
				
				Processor:CompileFunctionSegment(t)
				
				-- Process any hooks that should go after the main function segment
				Processor:CompileFunctionHooks(t, "post")
				
				t[#t+1] = "\n\n"  
				
				signature = signature:gsub(match, "", 1)
				
				break
			end
		end
		if not match then
			error(("Couldn't find a signature match for the beginning of signature %q from %q"):format(signature, originalSignature), 4)
		end
	end
	
	if isInternal then
		t[#t+1] = [[
			return doFireIconUpdated
		end -- "return function(icon, ...)"
		]]
	else
		t[#t+1] = [[
			if doFireIconUpdated then
				TMW:Fire("TMW_ICON_UPDATED", icon)
			end
		end -- "return function(icon, ...)"
		]]
	end
	
	local funcstr = table.concat(t)
	if TMW.debug then
		funcstr = TMW.debug.enumLines(funcstr)
		TMW.debug.SetInfoFuncsToFuncStrs[tostring(isInternal) .. originalSignature] = funcstr
	end
	local func = assert(loadstring(funcstr, "SetInfo " .. originalSignature))()
	
	return func
end

local SetInfoFuncs = setmetatable({}, { __index = function(self, signature)
	-- Check and see if we already made a function for this signature, just with different spacing.
	local signature_no_spaces = signature:gsub(" ", "")
	if rawget(self, signature_no_spaces) then
		local func = self[signature_no_spaces]
		
		-- If there was a function, cache it for the original signature also so that we don't go through this lookup process every time.
		self[signature] = func
		return func
	end
	
	local func = SetInfo_GenerateFunction(signature, nil)
	
	self[signature] = func
	self[signature:gsub(" ", "")] = func
	
	return func
end})
function Icon.SetInfo(icon, signature, ...)
	SetInfoFuncs[signature](icon, ...)
end

local SetInfoInternalFuncs = setmetatable({}, { __index = function(self, signature)
	-- Check and see if we already made a function for this signature, just with different spacing.
	local signature_no_spaces = signature:gsub(" ", "")
	if rawget(self, signature_no_spaces) then
		local func = self[signature_no_spaces]
		
		-- If there was a function, cache it for the original signature also so that we don't go through this lookup process every time.
		self[signature] = func
		return func
	end
	
	local func = SetInfo_GenerateFunction(signature, true)
	
	self[signature] = func
	self[signature:gsub(" ", "")] = func
	
	return func
end})
-- SetInfo_INTERNAL doesn't fire TMW_ICON_UPDATED because it is always called from within SetInfo (inside IconDataProcessorHooks).
-- SetInfo will fire it at the end (and only once, isntead of multiple times), so SetInfo_INTERNAL shouldn't fire it.
-- It returns doFireIconUpdated, which should be handled as needed if SetInfo_INTERNAL is being called inside a hook.
-- It can (and should, obviously) be ignored if being called from the changedEvent of an IconDataProcessor.
function Icon.SetInfo_INTERNAL(icon, signature, ...)
	SetInfoInternalFuncs[signature](icon, ...)
end
function TMW:ClearSetInfoFunctionCache()
	wipe(SetInfoFuncs)
	wipe(SetInfoInternalFuncs)
	InheritAllFunc = nil
end

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
				TMW.safecall(self.class.OnUsed, self.class)
			end
			
			if self.OnEnable then
				TMW.safecall(self.OnEnable, self)
			end
		end
	end,
	Disable = function(self)
		self:AssertSelfIsInstance()
		
		if self.IsEnabled then
			self.IsEnabled = false
			self.class.NumberEnabled = self.class.NumberEnabled - 1
			if self.class.NumberEnabled == 0 and self.class.OnUnused then
				TMW.safecall(self.class.OnUnused, self.class)
			end
			
			if self.OnDisable then
				TMW.safecall(self.OnDisable, self)
			end
		end
	end,
	
	SetScriptHandler = function(self, script, func)
		self:AssertSelfIsClass()
		
		TMW:ValidateType(2, "Module:SetScriptHandler()", script, "string")
		
		self.ScriptHandlers[script] = func
	end,
	GetScriptHandler = function(self, script)
	--	self:AssertSelfIsClass() -- doesnt need to be class. No harm in just looking this up for an instance.
		
		TMW:ValidateType(2, "Module:GetScriptHandler()", script, "string")
		
		return self.ScriptHandlers[script]
	end,

	SetImplementorForView = function(self, viewName, order, implementorFunc)
		self:AssertSelfIsClass()
		
		local IconView = TMW.Views[viewName]
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
}

TMW:NewClass("IconModule", "IconComponent", "ObjectModule"){
	EventListners = {},
	ViewImplementors = {},
	TypeAllowances = {},
	anchorableChildren = {},
	
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
		
		for name in pairs(self.anchorableChildren) do
			local identifier = className .. name
			
			local localizedName = rawget(L, identifier)
			if not localizedName then
				TMW:Error("Localized name for %q is missing! (TMW.L[%q])", identifier, identifier)
			end
			
			self.anchorableChildren[name] = localizedName
		end
	end,
	OnClassInherit_IconModule = function(self, newClass)		
		newClass:InheritTable(self, "EventListners")
		newClass:InheritTable(self, "ViewImplementors")
		newClass:InheritTable(self, "TypeAllowances")
		newClass:InheritTable(self, "anchorableChildren")
		
		newClass.defaultAllowanceForTypes = self.defaultAllowanceForTypes
	end,
	
	OnImplementIntoIcon = function(self, icon)
		self.IsImplemented = true
		
		local implementationData = self.implementationData
		local implementorFunc = implementationData.implementorFunc
		
		if type(implementorFunc) == "function" then
			implementorFunc(self, icon)
		end
		
		if self.IsEnabled and self.SetupForIcon then
			TMW.safecall(self.SetupForIcon, self, icon)
		end
	end,
	
	OnUnimplementFromIcon = function(self, icon)
		self.IsImplemented = nil
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
	
	SetDataListner = function(self, processorName, func)
		-- func: false to remove the data listner; nil to search for it 
		self:AssertSelfIsClass()
		
		local Processor = TMW.ProcessorsByName[processorName]
		assert(Processor, ("Couldn't find IconDataProcessor named %q"):format(tostring(processorName)))			
		
		if func == nil then
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
	
	SetEssentialModuleComponent = function(self, identifier, component)	--TODO: deprecate this. replace it with the new list of anchored points things that i wanted to do.
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

	GetChildNameBase = function(self)
		self:AssertSelfIsInstance()
		
		return self.icon:GetName() .. self.className
	end,
	RegisterAnchorableFrame = function(self, name)
		self:AssertSelfIsClass()
		TMW:ValidateType("2 (name)", "IconModule:RegisterAnchorableFrame(name)", name, "string")
		
		self.anchorableChildren[name] = true
	end,
	UnregisterAnchorableFrame = function(self, name)
		self:AssertSelfIsClass()
		TMW:ValidateType("2 (name)", "IconModule:UnregisterAnchorableFrame(name)", name, "string")
		
		self.anchorableChildren[name] = nil
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
					TMW.safecall(self.class.OnUsed, self.class)
				end
				
				if self.OnEnable then
					TMW.safecall(self.OnEnable, self)
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
				TMW.safecall(self.class.OnUnused, self.class)
			end
			
			if self.OnDisable then
				TMW.safecall(self.OnDisable, self)
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
		
		if type(implementorFunc) == "function" then
			implementorFunc(self, group)
		end
	end,
}



local IconType = TMW:NewClass("IconType", "IconComponent")
IconType.UsedAttributes = {}

function IconType:OnNewInstance(type)
	self.type = type
	self.Icons = {}
	self.UsedProcessors = {}
	self.Colors = {}
	
	self:InheritTable(self.class, "UsedAttributes")
end

function IconType:UpdateColors(dontSetupIcons)
	for k, v in pairs(TMW.db.profile.Colors[self.type]) do
		if v.Override then
			self.Colors[k] = v
		else
			self.Colors[k] = TMW.db.profile.Colors.GLOBAL[k]
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

function IconType:FormatSpellForOutput(icon, data, doInsertLink)
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

function IconType:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local name = TMW:GetSpellNames(nil, ics.Name, 1)
		if name then
			return SpellTextures[name]
		end
	end
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

function IconType:Register(order)
	TMW:ValidateType("2 (order)", "IconView:Register(order)", order, "number")
	
	local typekey = self.type
	
	self.order = order
	
	self.RelevantSettings = self.RelevantSettings or {}
	setmetatable(self.RelevantSettings, RelevantToAll)

	if TMW.debug and rawget(TMW.Types, typekey) then
		-- for tweaking and recreating icon types inside of WowLua so that I don't have to change the typekey every time.
		typekey = typekey .. " - " .. date("%X")
		self.name = typekey
	end

	TMW.Types[typekey] = self -- put it in the main Types table
	tinsert(TMW.OrderedTypes, self) -- put it in the ordered table (used to order the type selection dropdown in the icon editor)
	TMW:SortOrderedTables(TMW.OrderedTypes)
	
	-- Try to find processors for the attributes declared for the icon type.
	-- It should find most since default processors are loaded before icon types.
	self:UpdateUsedProcessors()
	
	-- Listen for any new processors, too, and update when they are created.
	TMW:RegisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", "UpdateUsedProcessors", self)
	
	return self -- why not?
end

function IconType:UsesAttributes(attributesString, uses)
	if uses == false then
		self.UsedAttributes[attributesString] = nil
	else
		self.UsedAttributes[attributesString] = true
	end
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



IconType:UsesAttributes("alpha")
IconType:UsesAttributes("alphaOverride")
IconType:UsesAttributes("realAlpha") -- this is implied by the mere existance of IconAlphaManager
IconType:UsesAttributes("conditionFailed")

--TODO: (misplaced note): implement something like IconModule:RegisterAnchor(frame, identifier, localizedName) so that other modules can anchor to it (mainly texts)


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
	TMW.removeTableDuplicates(buffNames)

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
	if icon.Name == "" and not TMW.Types[icon.Type].AllowNoName then
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
		
		if TMW.Types[icon.Type].usePocketWatch then
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
	n = tonumber(n) or n
	g = tonumber(g) or g
	
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
	if TMW.ISMOP and InCombatLockdown() and TMW.Locked then
		TMW:Print(L["ERROR_NO_LOCKTOGGLE_IN_LOCKDOWN"])
		return
	end

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

function TMW:CheckCanDoLockedAction()
	if TMW.ISMOP and InCombatLockdown() then
		TMW:Print(L["ERROR_NO_SLASH_IN_LOCKDOWN"])
		return false
	end
	return true
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
		
		if TMW:CheckCanDoLockedAction() then
			TMW:LoadOptions()
			LibStub("AceConfigDialog-3.0"):Open("TMW Options")
		end
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




	