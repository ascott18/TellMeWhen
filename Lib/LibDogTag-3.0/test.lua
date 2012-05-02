-- $Id: test.lua 235 2012-04-03 02:52:22Z cybeloras $

--[=[
TODO:

More comments
More documentation
]=]

--local path = (... .. "/"):gsub("\\", "/") -- Needed for Cybeloras to run this properly
local path = ""

local function escape_char(c)
	return ("\\%03d"):format(c:byte())
end

local function table_len(t)
	for i = 1, #t do
		if t[i] == nil then
			return i-1
		end
	end
	return #t
end

function pprint(...)
	print(ptostring(...))
end

local function key_sort(alpha, bravo)
	local type_alpha, type_bravo = type(alpha), type(bravo)
	if type_alpha ~= type_bravo then
		return type_alpha < type_bravo
	end
	
	if type_alpha == "string" then
		return alpha:lower() < bravo:lower()
	elseif type_alpha == "number" then
		return alpha < bravo
	elseif type_alpha == "table" then
		return tostring(alpha) < tostring(bravo)
	else
		return false
	end
end

local preserved = {
	["nil"] = true,
	["true"] = true,
	["false"] = true,
}

local first_ptostring = true
function ptostring(...)
	local t = {}
	for i = 1, select('#', ...) do
		if i > 1 then
			t[#t+1] = ",\t"
		end
		local v = select(i, ...)
		if type(v) == "string" then
			t[#t+1] = (("%q"):format(v):gsub("\\\010", "\\n"):gsub("[\001-\031\128-\255]", escape_char))
		elseif type(v) == "table" then
			t[#t+1] = "{ "
			local keys = {}
			for a in pairs(v) do
				keys[#keys+1] = a
			end
			table.sort(keys, key_sort)
			local first = true
			for _,a in ipairs(keys) do
				local b = v[a]
				if first then
					first = nil
				else
					t[#t+1] = ", "
				end
				if type(a) ~= "number" or a < 1 or a > table_len(v) then
					if type(a) == "string" and a:match("^[a-zA-Z_][a-zA-Z_0-9]*$") and not preserved[a] then
						t[#t+1] = a
						t[#t+1] = " = "
					else
						t[#t+1] = "["
						t[#t+1] = ptostring(a)
						t[#t+1] = "] = "
					end
				end
				t[#t+1] = ptostring(b)
			end
			if first then
				t[#t] = "{}"
			else
				t[#t+1] = " }"
			end
		else
			t[#t+1] = tostring(v)
		end
	end
	return table.concat(t)
end

local function is_equal(alpha, bravo)
	if type(alpha) ~= type(bravo) then
		return false
	end
	
	if type(alpha) == "number" then
		return alpha == bravo or tostring(alpha) == tostring(bravo) or math.abs(alpha - bravo) < 1e-15
	elseif type(alpha) ~= "table" then
		return alpha == bravo
	end
	
	local num = 0
	for k,v in pairs(alpha) do
		num = num + 1
		if not is_equal(v, bravo[k]) then
			return false
		end
	end
	
	for k,v in pairs(bravo) do
		num = num - 1
	end
	if num ~= 0 then
		return false
	end
	return true
end

local errors_raised = 0
function geterrorhandler()
	return function(err)
		errors_raised = errors_raised + 1
		print(debug.traceback(err, 2))
		os.exit()
	end
end

function assert_equal(alpha, bravo)
	if not is_equal(alpha, bravo) then
		error(("Assertion failed: %s == %s"):format(ptostring(alpha), ptostring(bravo)), 2)
	end
end

if not DogTag_Test_SecondTime then
	local function CreateFontString(parent, name, layer)
		local fs = {
			[0] = newproxy(), -- fake userdata
		}
		function fs:GetObjectType()
			return "FontString"
		end
		local text
		function fs:SetText(x)
			text = x
		end
		function fs:GetText()
			return text
		end
		local alpha = 1
		function fs:SetAlpha(a)
			alpha = a
		end
		function fs:GetAlpha()
			return alpha
		end
		local fontObject
		function fs:SetFontObject(object)
			fontObject = object
		end
		function fs:GetFontObject()
			return fontObject
		end
		local fontName, fontSize, fontOutline = "Fritz", 14, ""
		function fs:GetFont()
			return fontName, fontSize, fontOutline
		end
		function fs:SetFont(a, b, c)
			fontName, fontSize, fontOutline = a, b, c or ''
		end
		return fs
	end
	local frames = {}
	local frameRegisteredEvents = {}
	local ALL_EVENTS = newproxy()
	function CreateFrame(frameType, ...)
		local frame = {
			[0] = newproxy(), -- fake userdata
		}
		frames[frame] = true
		function frame:GetObjectType()
			return frameType
		end
		function frame:GetFrameType()
			return frameType
		end
		local scripts = {}
		function frame:SetScript(script, func)
			scripts[script] = func
		end
		function frame:GetScript(script)
			return scripts[script]
		end
		local events = {}
		frameRegisteredEvents[frame] = events
		function frame:RegisterEvent(event)
			events[event] = true
		end
		function frame:UnregisterEvent(event)
			events[event] = nil
		end
		function frame:UnregisterAllEvents()
			for event in pairs(events) do
				events[event] = nil
			end
		end
		function frame:RegisterAllEvents()
			events[ALL_EVENTS] = true
		end
		function frame:CreateFontString(...)
			return CreateFontString(frame, ...)
		end
		local isShown = 1
		function frame:Show()
			isShown = 1
		end
		function frame:Hide()
			isShown = nil
		end
		function frame:IsShown()
			return isShown
		end
		if frameType == "GameTooltip" then
			local owner
			function frame:SetOwner(f)
				owner = f
			end
			function frame:IsOwned(f)
				return owner == f
			end
			local fsLeft, fsRight = {}, {}
			function frame:AddFontStrings(f1, f2)
				fsLeft[#fsLeft+1] = f1
				fsRight[#fsRight+1] = f2
			end
		end
		return frame
	end

	local currentTime = 1e5 -- initial time
	function GetTime()
		return math.floor(currentTime*1000 + 0.5) / 1000
	end

	function FireOnUpdate(elapsed)
		if not elapsed then
			elapsed = 1
		end
		currentTime = currentTime + elapsed
		for frame in pairs(frames) do
			local OnUpdate = frame:GetScript("OnUpdate")
			if OnUpdate and frame:IsShown() then
				OnUpdate(frame, elapsed)
			end
		end
	end

	function FireEvent(event, ...)
		for frame in pairs(frames) do
			if frameRegisteredEvents[frame][event] or frameRegisteredEvents[frame][ALL_EVENTS] then
				local OnEvent = frame:GetScript("OnEvent")
				if OnEvent then
					OnEvent(frame, event, ...)
				end
			end
		end
	end
end

RAID_CLASS_COLORS = {
	DRUID = { r = 1, g = 0.49, b = 0.04, },
	HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
	MAGE = { r = 0.41, g = 0.8, b = 0.41 },
	PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
	PRIEST = { r = 1, g = 1, b = 1 },
	ROGUE = { r = 1, g = 0.96, b = 0.41 },
	SHAMAN = { r = 0.14, g = 0.35, b = 1 },
	WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
	WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
}

local GetMouseFocus_data = nil
function GetMouseFocus()
	return GetMouseFocus_data
end

local IsAltKeyDown_data = nil
function IsAltKeyDown()
	return IsAltKeyDown_data
end

local IsShiftKeyDown_data = nil
function IsShiftKeyDown()
	return IsShiftKeyDown_data
end

local IsControlKeyDown_data = nil
function IsControlKeyDown()
	return IsControlKeyDown_data
end

function InCombatLockdown()
	return false
end

function LoadAddOn()
end

DogTag_DEBUG = true

DAYS = "Days";
--DAYS_P1 = "Days";
DAYS_ABBR = "%d Days";
--DAYS_ABBR_P1 = "Days";
DAY_ONELETTER_ABBR = "%d d";
HOURS = "Hours";
--HOURS_P1 = "Hours";
HOURS_ABBR = "%d Hr";
--HOURS_ABBR_P1 = "Hrs";
HOUR_ONELETTER_ABBR = "%d h";
MINUTES = "Minutes"; -- Minutes of time
--MINUTES_P1 = "Minutes";
MINUTES_ABBR = "%d Min";
--MINUTES_ABBR_P1 = "Mins";
MINUTE_ONELETTER_ABBR = "%d m";
SECONDS = "Seconds"; -- Seconds of time
--SECONDS_P1 = "Seconds";
SECONDS_ABBR = "%d Sec";
--SECONDS_ABBR_P1 = "Secs";
SECOND_ONELETTER_ABBR = "%d s";

dofile(path .. "LibStub/LibStub.lua")
dofile(path .. "Localization/enUS.lua")
dofile(path .. "Helpers.lua")
dofile(path .. "LibDogTag-3.0.lua")
dofile(path .. "Parser.lua")
dofile(path .. "Compiler.lua")
dofile(path .. "Events.lua")
dofile(path .. "Categories/Math.lua")
dofile(path .. "Categories/Misc.lua")
dofile(path .. "Categories/Operators.lua")
dofile(path .. "Categories/TextManip.lua")
dofile(path .. "Cleanup.lua")

local DogTag = LibStub("LibDogTag-3.0")
local getPoolNum, setPoolNum = DogTag.getPoolNum, DogTag.setPoolNum
local parse = DogTag.parse
local standardize = DogTag.standardize

local function assert_table_usage(func, tableChange)
	local previousPoolNum = getPoolNum()
	func()
	local afterPoolNum = getPoolNum()
	local actualChange = afterPoolNum-previousPoolNum
	if tableChange ~= actualChange then
--		error(("Unexpected table usage: %d instead of expected %d"):format(actualChange, tableChange), 2)
	end
end

local function countTables(t)
	if type(t) ~= "table" then
		return 0
	end
	local n = 1
	for k, v in pairs(t) do
		n = n + countTables(k) + countTables(v)
	end
	return n
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local x = {}
	for k,v in pairs(t) do
		x[k] = deepCopy(v)
	end
	return x
end

local old_parse = parse
function parse(arg)
	local start = DogTag.getPoolNum()
	local ret = old_parse(arg)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	local num_tables = countTables(ret)
	if change ~= num_tables then
		error(("Unknown table usage: %d instead of %d"):format(change, num_tables), 2)
	end
	local r = deepCopy(ret)
	DogTag.deepDel(ret)
	return r
end

local old_standardize = standardize
function standardize(arg)
	local realStart = DogTag.getPoolNum()
	local start = realStart - countTables(arg)
	local ret = old_standardize(arg)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	local num_tables = countTables(ret)
	if change ~= num_tables then
		error(("Unknown table usage: %d instead of %d"):format(change, num_tables), 2)
	end
	DogTag.setPoolNum(realStart)
	return ret
end

DogTag:Evaluate("")

local function tuple(...)
	local x = { ... }
	local n = select('#', ...)
	return function()
		return unpack(x, 1, n)
	end
end

local old_DogTag_Evaluate = DogTag.Evaluate
function DogTag:Evaluate(...)
	local start = DogTag.getPoolNum()
	local rets = tuple(old_DogTag_Evaluate(self, ...))
	local finish = DogTag.getPoolNum()
	local change = finish - start
	if change ~= 0 then
--		error(("Unknown table usage: %d instead of %d"):format(change, 0), 2)
	end
	return rets()
end

local old_DogTag_CleanCode = DogTag.CleanCode
function DogTag:CleanCode(...)
	local start = DogTag.getPoolNum()
	local ret = old_DogTag_CleanCode(self, ...)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	if change ~= 0 then
		error(("Unknown table usage: %d instead of %d"):format(change, 0), 2)
	end
	return ret
end

DogTag:AddTag("Base", "One", {
	code = function() return 1 end,
	ret = "number",
	doc = "Return the number 1",
	example = '[One] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "StaticOne", {
	code = function() return 1 end,
	ret = "number",
	static = true,
	doc = "Return the number 1",
	example = '[One] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "Two", {
	code = function() return 2 end,
	ret = "number",
	doc = "Return the number 2",
	example = '[Two] => "2"',
	category = "Testing"
})

DogTag:AddTag("Base", "FakeOne", {
	code = function() return 100 end,
	ret = "number",
	doc = "Return the number 100",
	example = '[FakeOne] => "100"',
	category = "Testing"
})

DogTag:AddTag("Base", "PlusOne", {
	code = function(number)
		return number + 1
	end,
	arg = {
		'number', 'number', "@req"
	},
	ret = "number",
	static = true,
	doc = "Return the number 1",
	example = '[One] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "Subtract", {
	code = function(left, right)
		return left - right
	end,
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req"
	},
	ret = "number",
	doc = "Subtract right from left",
	example = '[AddNumbers(1, 2)] => "-1"',
	category = "Testing"
})

DogTag:AddTag("Base", "SubtractFive", {
	alias = [=[Subtract(number, 5)]=],
	arg = {
		'number', 'number', '@req',
	},
	doc = "Subtract 5 from number",
	example = '[SubtractFive(10)] => "5"',
	category = "Testing",
})

DogTag:AddTag("Base", "SubtractFromFive", {
	alias = [=[Subtract(right=number, left=5)]=],
	arg = {
		'number', 'number', '@req',
	},
	doc = "Subtract number from 5",
	example = '[SubtractFromFive(10)] => "-5"; [SubtractFromFive] => "5"',
	category = "Testing",
})

DogTag:AddTag("Base", "ReverseSubtract", {
	alias = [=[Subtract(right, left)]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req"
	},
	ret = "number",
	doc = "Subtract left from right",
	example = '[ReverseSubtract(1, 2)] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "AbsAlias", {
	alias = [=[number < 0 ? -number ! number]=],
	arg = {
		'number', 'number', "@req",
	},
	ret = "number",
	doc = "Get the absolute value of number",
	example = '[AbsAlias(5)] => "5"; [AbsAlias(-5)] => "5"',
	category = "Testing"
})

local GlobalCheck_data = "Hello World"

DogTag:AddTag("Base", "GlobalCheck", {
	code = function()
		return GlobalCheck_data
	end,
	ret = "string;number;nil",
	doc = "Return the results of testfunc",
	example = '[GlobalCheck] => "Hello World"',
	category = "Testing"
})

local myfunc_num = 0
function _G.myfunc()
	myfunc_num = myfunc_num + 1
	return myfunc_num
end

DogTag:AddTag("Base", "FunctionNumberCheck", {
	code = function()
		myfunc_num = myfunc_num + 1
		return myfunc_num
	end,
	ret = "number;nil",
	doc = "Return the results of myfunc",
	example = '[FunctionNumberCheck] => "1"',
	category = "Testing"
})


DogTag:AddTag("Base", "AbsoluteValue", {
	code = function(number)
		return math.abs(number)
	end,
	arg = {
		'number', 'number', "@req",
	},
	ret = "number",
	doc = "Get the absolute value of number",
	example = '[AbsoluteValue(5)] => "5"; [AbsoluteValue(-5)] => "5"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNumDefault", {
	code = function(value)
		return value
	end,
	arg = {
		'value', 'number', 50
	},
	ret = "number",
	doc = "Return the given argument or 50",
	example = '[CheckStrDefault(1)] => "1"; [CheckStrDefault] => "50"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckStrDefault", {
	code = function(value)
		return value
	end,
	arg = {
		'value', 'string', 'Value'
	},
	ret = "string",
	doc = "Return the given argument or value",
	example = '[CheckStrDefault(1)] => "1"; [CheckStrDefault] => "Value"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNilDefault", {
	code = function(value)
		return value
	end,
	arg = {
		'value', 'nil;number', false
	},
	ret = "nil;number",
	doc = "Return the given argument or nil",
	example = '[CheckNilDefault(1)] => "1"; [CheckNilDefault] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNumTuple", {
	code = function(...)
		return ("-"):join(...)
	end,
	arg = {
		'...', 'tuple-number', false
	},
	ret = "string",
	doc = "Join ... separated by dashes",
	example = '[CheckNumTuple(1)] => "1"; [CheckNumTuple] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckBooleanTuple", {
	code = function(...)
		local num = 0
		for i = 1, select('#', ...) do
			assert(type(select(i, ...)) == "boolean")
			if select(i, ...) then
				num = num + 2^(i - 1)
			end
		end
		return num
	end,
	arg = {
		'...', 'tuple-boolean', false
	},
	ret = "number",
	doc = "Return the integer formed by the bits of ...",
	example = '[CheckBooleanTuple(true, false, true)] => "5"; [CheckBooleanTuple] => "0"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNilTuple", {
	code = function(...)
		for i = 1, select('#', ...) do
			assert(not select(i, ...))
		end
		return select('#', ...)
	end,
	arg = {
		'...', 'tuple-nil', false
	},
	ret = "number",
	doc = "Return the number of nils provided",
	example = '[CheckNilTuple(nil, nil, nil)] => "3"; [CheckNilTuple] => "0"',
	category = "Testing"
})

DogTag:AddTag("Base", "TupleAlias", {
	alias = [=[CheckNumTuple(5, ...)]=],
	arg = {
		'...', 'tuple-number', false
	},
	doc = "Join ... separated by dashes",
	example = '[TupleAlias(1)] => "1"; [TupleAlias] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "OtherTupleAlias", {
	alias = [=[Subtract(...)]=],
	arg = {
		'...', 'tuple-number', false
	},
	doc = "Subtract the values of ...",
	example = '[OtherTupleAlias(5, 2)] => "3"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckAnotherNumTuple", {
	code = function(...)
		return math.max(0, ...)
	end,
	arg = {
		'...', 'tuple-number', false
	},
	ret = "string",
	doc = "Return the largest number of ...",
	globals = 'math.max',
	example = '[CheckAnotherNumTuple(1)] => "1"; [CheckAnotherNumTuple] => "0"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckStrTuple", {
	code = function(...)
		local x = ''
		for i = 1, select('#', ...) do
			x = x .. select(i, ...):gsub('[aeiou]', 'y')
		end
		return x
	end,
	arg = {
		'...', 'tuple-string', false
	},
	ret = "string",
	doc = "Join ..., replacing vowels with 'y'",
	example = '[CheckStrTuple("Hello")] => "Hylly"; [CheckStrTuple] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckAnyTuple", {
	code = function(...)
		local x = ''
		for i = 1, select('#', ...) do
			if i > 1 then
				x = x .. ";"
			end
			x = x .. type(select(i, ...)) .. ":" .. tostring(select(i, ...))
		end
		return x
	end,
	arg = {
		'...', 'tuple-string;number;nil', false
	},
	ret = "string",
})

DogTag:AddTag("Base", "Reverse", {
	code = function(value)
		return value:reverse()
	end,
	arg = {
		'value', 'string', '@req'
	},
	ret = "string",
	doc = "Reverse the characters in value",
	example = '[Reverse(Hello)] => "olleH"',
	category = "Testing",
})

DogTag:AddTag("Base", "OtherReverse", {
	code = function(value)
		if value ~= "Stuff" then
			return value:reverse()
		else
			return "ffutS"
		end
	end,
	arg = {
		'value', 'string', '@req'
	},
	ret = "string",
	doc = "Reverse the characters in value",
	example = '[OtherReverse(Hello)] => "olleH"',
	category = "Testing",
})

DogTag:AddTag("Base", "KwargAndTuple", {
	code = function(value, ...)
		local num = 0
		for i = 1, select('#', ...) do
			num = num + select(i, ...)
		end
		return value * num
	end,
	arg = {
		'value', 'number', '@req',
		'...', 'tuple-number', false
	},
	ret = 'number',
	globals = 'math.max';
	doc = "Return the maximum of ... multiplied by value",
	example = '[KwargAndTuple(5, 1, 2, 3)] => "15"',
	category = "Testing",
})

DogTag:AddTag("Base", "TupleAndKwarg", {
	code = function(value, ...)
		local num = 0
		for i = 1, select('#', ...) do
			num = num + select(i, ...)
		end
		return value * num
	end,
	arg = {
		'...', 'tuple-number', false,
		'value', 'number', '@req'
	},
	ret = 'number',
	globals = 'math.max';
	doc = "Return the maximum of ... multiplied by value",
	example = '[KwargAndTuple(5, 1, 2, 3)] => "15"',
	category = "Testing",
})

DogTag:AddTag("Base", "Type", {
	code = function(value)
		return type(value)
	end,
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = 'string',
	doc = "Return the type of value",
	example = '[Type(nil)] => "nil"; [Type("Hello")] => "string"; [Type(5)] => "number"',
	category = "Testing",
})

DogTag:AddTag("Base", "BooleanToString", {
	code = function(value)
		return tostring(value)
	end,
	arg = {
		'value', 'boolean', false
	},
	ret = 'string',
	doc = "Return true or false",
	example = '[BooleanToString(nil)] => "false"; [BooleanToString("Hello")] => "true"; [BooleanToString(5)] => "true"',
	category = "Testing",
})

DogTag:AddTag("Base", "RetNil", {
	code = function()
		return nil
	end,
	arg = {
		'value', 'nil;number;string', false
	},
	ret = 'nil',
	doc = "Return nil",
	example = '[RetNil] => ""; [RetNil(Anything)] => ""',
	category = "Testing",
})

local GlobalCheckBoolean_data = true
DogTag:AddTag("Base", "GlobalCheckBoolean", {
	code = function()
		return GlobalCheckBoolean_data
	end,
	ret = 'boolean',
	doc = "Return True or blank",
	example = '[GlobalCheckBoolean] => ""; [GlobalCheckBoolean] => "True"',
	category = "Testing",
})

DogTag:AddTag("Base", "ToString", {
	code = function(value)
		return '`' .. tostring(value or ''):reverse():reverse() .. '`'
	end,
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = 'string',
	doc = "Return value surrounded by tickmarks",
	example = '[ToString(nil)] => "``"; [ToString("Hello")] => "`Hello`"; [ToString(5)] => "`5`"',
	category = "Testing",
})

local RetSame_types
DogTag:AddTag("Base", "RetSame", {
	code = function(value)
		return value
	end,
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = function(args)
		RetSame_types = args.value.types
		return args.value.types
	end
})

DogTag:AddTag("Base", "OtherRetSame", {
	code = function(value)
		return value
	end,
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = 'number;nil;string'
})

DogTag:AddTag("Base", "DynamicCodeTest", {
	code = function(args)
		if args.value.isLiteral then
			local value = args.value.value
			return function()
				return "literal, " .. tostring(value)
			end
		else
			local value = args.value.value
			local tag = value[1] == "tag" and value[2] or value[1]
			return function()
				return "dynamic, " .. tag
			end
		end
	end,
	dynamicCode = true,
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = "string",
})

local BlizzEventTest_num = 0
DogTag:AddTag("Base", "BlizzEventTest", {
	code = function(value)
		BlizzEventTest_num = BlizzEventTest_num + 1
		return BlizzEventTest_num
	end,
	arg = {
		'value', 'string', "@req"
	},
	ret = "number",
	events = "FAKE_BLIZZARD_EVENT#$value",
	doc = "Return the results of BlizzEventTest_num after incrementing",
	example = '[BlizzEventTest] => "1"',
	category = "Testing"
})
local OtherBlizzEventTest_num = 0
DogTag:AddTag("Base", "OtherBlizzEventTest", {
	code = function()
		OtherBlizzEventTest_num = OtherBlizzEventTest_num + 1
		return OtherBlizzEventTest_num
	end,
	ret = "number",
	events = "OTHER_FAKE_BLIZZARD_EVENT",
	doc = "Return the results of OtherBlizzEventTest_num after incrementing",
	example = '[OtherBlizzEventTest] => "1"',
	category = "Testing"
})

DoubleBlizzEventTest_num = 0
DogTag:AddTag("Base", "DoubleBlizzEventTest", {
	code = function(alpha, bravo)
		DoubleBlizzEventTest_num = DoubleBlizzEventTest_num + 1
		return DoubleBlizzEventTest_num
	end,
	arg = {
		'alpha', 'string', "@req",
		'bravo', 'string', "@req",
	},
	ret = "number",
	events = "DOUBLE_BLIZZARD_EVENT#$alpha;DOUBLE_BLIZZARD_EVENT#$bravo",
	doc = "Return the results of BlizzEventTest_num after incrementing",
	example = '[BlizzEventTest] => "1"',
	category = "Testing"
})

local OtherDoubleBlizzEventTest = 0
DogTag:AddTag("Base", "OtherDoubleBlizzEventTest", {
	code = function(value)
		OtherDoubleBlizzEventTest_num = OtherDoubleBlizzEventTest_num + 1
		return OtherDoubleBlizzEventTest_num
	end,
	arg = {
		'alpha', 'string', "@req",
		'bravo', 'string', "@req",
	},
	ret = "number",
	events = "OTHER_DOUBLE_BLIZZARD_EVENT#$alpha#$bravo",
	doc = "Return the results of OtherDoubleBlizzEventTest_num after incrementing",
	example = '[OtherDoubleBlizzEventTest("alpha", "bravo")] => "1"',
	category = "Testing"
})

local LibToProvideExtraFunctionality
DogTag:AddAddonFinder("Base", "LibStub", "LibToProvideExtraFunctionality", function(lib)
	LibToProvideExtraFunctionality = lib
end)

DogTag:AddTag("Base", "ExtraFunctionalityWithLib", {
	code = function(args)
		if LibToProvideExtraFunctionality then
			return function()
				return "True"
			end
		else
			return function()
				return nil
			end
		end
	end,
	dynamicCode = true,
	ret = function(args)
		if LibToProvideExtraFunctionality then
			return "string"
		else
			return "nil"
		end
	end,
	doc = "Return True if LibToProvideExtraFunctionality is present",
	example = '[ExtraFunctionalityWithLib] => ""; [ExtraFunctionalityWithLib] => "True"',
	category = "Testing",
})

DogTag:AddTag("Base", "Thingy", {
	code = function(value)
		return value
	end,
	arg = {
		'value', 'string', '@req',
	},
	ret = "string",
	events = "THINGY_EVENT#$value",
})

DogTag:AddTag("Base", "AliasOfThingy", {
	alias = "Thingy(value=myvalue)",
	arg = {
		'myvalue', 'string', '@req',
	},
})

DogTag:AddTag("Base", "OtherAliasOfThingy", {
	alias = "Thingy(value=myvalue:Repeat(2))",
	arg = {
		'myvalue', 'string', '@req',
	},
})


collectgarbage('collect')
collectgarbage('stop')
collectgarbage('collect')
local startMemory = collectgarbage('count')
local startTime = os.clock()

assert_equal(parse("[1 - 2]"), { "-", 1, 2 })
assert_equal(parse("[1-2]"), { "-", 1, 2 })
assert_equal(parse("[1- 2]"), { "-", 1, 2 })
assert_equal(parse("[1 -2]"), { "concat", 1, -2 })
assert_equal(parse("[50 1 - 2]"), { "concat", 50, { "-", 1, 2 } })
assert_equal(parse("[50 1-2]"), { "concat", 50, { "-", 1, 2 } })
assert_equal(parse("[50 1- 2]"), { "concat", 50, { "-", 1, 2 } })
assert_equal(parse("[50 1 -2]"), { "concat", 50, 1, -2 })
assert_equal(parse("[1 - 2 50]"), { "concat", { "-", 1, 2 }, 50 })
assert_equal(parse("[1-2 50]"), { "concat", { "-", 1, 2 }, 50 })
assert_equal(parse("[1- 2 50]"), { "concat", { "-", 1, 2 }, 50 })
assert_equal(parse("[1 -2 50]"), { "concat", 1, -2, 50 })
assert_equal(parse("[25 1 - 2 50]"), { "concat", 25, { "-", 1, 2 }, 50 })
assert_equal(parse("[25 1-2 50]"), { "concat", 25, { "-", 1, 2 }, 50 })
assert_equal(parse("[25 1- 2 50]"), { "concat", 25, { "-", 1, 2 }, 50 })
assert_equal(parse("[25 1 -2 50]"), { "concat", 25, 1, -2, 50 })

assert_equal(parse("[MyTag]"), { "tag", "MyTag" })
assert_equal(DogTag:CleanCode("[MyTag]"), "[MyTag]")
assert_equal(parse("Alpha [MyTag]"), {"concat", "Alpha ", { "tag", "MyTag" } })
assert_equal(DogTag:CleanCode("Alpha [MyTag]"), "Alpha [MyTag]")
assert_equal(parse("[MyTag] Bravo"), {"concat", { "tag", "MyTag" }, " Bravo" })
assert_equal(DogTag:CleanCode("[MyTag] Bravo"), "[MyTag] Bravo")
assert_equal(parse("Alpha [MyTag] Bravo"), {"concat", "Alpha ", { "tag", "MyTag" }, " Bravo" })
assert_equal(DogTag:CleanCode("Alpha [MyTag] Bravo"), "Alpha [MyTag] Bravo")
assert_equal(parse("[Alpha][Bravo]"), { "concat", { "tag", "Alpha" }, { "tag", "Bravo" } })
assert_equal(parse("[Alpha Bravo]"), { "concat", { "tag", "Alpha" }, { "tag", "Bravo" } })
assert_equal(DogTag:CleanCode("[One][Bravo]"), "[One Bravo]")
assert_equal(parse("[Alpha][Bravo][Charlie]"), { "concat", { "tag", "Alpha" }, { "tag", "Bravo" }, { "tag", "Charlie"} })
assert_equal(parse("[Alpha Bravo Charlie]"), { "concat", { "tag", "Alpha" }, { "tag", "Bravo" }, { "tag", "Charlie"} })
assert_equal(DogTag:CleanCode("[One][Bravo][Charlie]"), "[One Bravo Charlie]")
assert_equal(DogTag:CleanCode("Alpha [Bravo][Charlie] Delta"), "Alpha [Bravo Charlie] Delta")
assert_equal(DogTag:CleanCode("[Alpha] [Bravo] [Charlie]"), "[Alpha] [Bravo] [Charlie]")
assert_equal(DogTag:CleanCode("Alpha [Bravo] [Charlie] Delta"), "Alpha [Bravo] [Charlie] Delta")

assert_equal(parse("[Alpha(Bravo)]"), { "tag", "Alpha", { "tag", "Bravo" } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo)]"), "[Alpha(Bravo)]")
assert_equal(parse("[Alpha(Bravo, Charlie)]"), { "tag", "Alpha", { "tag", "Bravo" }, { "tag", "Charlie"} })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, Charlie)]"), "[Alpha(Bravo, Charlie)]")
assert_equal(parse("[Alpha:Delta]"), { "mod", "Delta", { "tag", "Alpha" } })
assert_equal(DogTag:CleanCode("[Alpha:Delta]"), "[Alpha:Delta]")
assert_equal(parse("[Alpha:Bravo:Charlie]"), { "mod", "Charlie", { "mod", "Bravo", { "tag", "Alpha" } } })
assert_equal(DogTag:CleanCode("[Alpha:Bravo:Charlie]"), "[Alpha:Bravo:Charlie]")
assert_equal(standardize(parse("[Alpha:Delta]")), { "tag", "Delta", { "tag", "Alpha" } })
assert_equal(standardize(parse("[Alpha:Bravo:Charlie]")), { "tag", "Charlie", { "tag", "Bravo", { "tag", "Alpha" } } })
assert_equal(parse("[Alpha:Delta(Echo)]"), { "mod", "Delta", { "tag", "Alpha" }, { "tag", "Echo" } })
assert_equal(DogTag:CleanCode("[Alpha:Delta(Echo)]"), "[Alpha:Delta(Echo)]")
assert_equal(parse("[Alpha(Bravo):Delta]"), { "mod", "Delta", { "tag", "Alpha", { "tag", "Bravo"} } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo):Delta]"), "[Alpha(Bravo):Delta]")
assert_equal(parse("[Alpha(Bravo, Charlie):Delta(Echo, Foxtrot)]"), { "mod", "Delta", { "tag", "Alpha", { "tag", "Bravo"}, {"tag", "Charlie"} }, {"tag", "Echo"}, {"tag", "Foxtrot"} })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, Charlie):Delta(Echo, Foxtrot)]"), "[Alpha(Bravo, Charlie):Delta(Echo, Foxtrot)]")
assert_equal(parse("[Alpha:~Delta]"), { "~", { "mod", "Delta", { "tag", "Alpha" } } })
assert_equal(standardize(parse("[Alpha:~Delta]")), { "not", { "tag", "Delta", { "tag", "Alpha" } } })
assert_equal(standardize(parse("[not Alpha:Delta]")), { "not", { "tag", "Delta", { "tag", "Alpha" } } })
assert_equal(DogTag:CleanCode("[Alpha:~Delta]"), "[Alpha:~Delta]")
assert_equal(parse("[Alpha(Bravo, Charlie):~Delta(Echo, Foxtrot)]"), { "~", { "mod", "Delta", { "tag", "Alpha", { "tag", "Bravo"}, {"tag", "Charlie"} }, {"tag", "Echo"}, {"tag", "Foxtrot"} } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, Charlie):~Delta(Echo, Foxtrot)]"), "[Alpha(Bravo, Charlie):~Delta(Echo, Foxtrot)]")
assert_equal(parse("[Func('Alpha')]"), { "tag", "Func", {"'", "Alpha"} })
assert_equal(DogTag:CleanCode("[Func('Alpha')]"), "[Func('Alpha')]")
assert_equal(parse([=[[Func('Alp"ha')]]=]), { "tag", "Func", {"'", 'Alp"ha'} })
assert_equal(DogTag:CleanCode([=[[Func('Alp"ha')]]=]), [=[[Func('Alp"ha')]]=])

assert_equal(parse(""), { "nil" })
assert_equal(parse("['']"), { "'", '' })
assert_equal(parse('[""]'), { '"', '' })
assert_equal(parse("[nil]"), { "nil" })
assert_equal(parse("[false]"), { "false" })
assert_equal(standardize(parse("[false]")), { "nil" })
assert_equal(parse("[true]"), { "true" })
assert_equal(standardize(parse("[true]")), "True")
assert_equal(DogTag:CleanCode("[nil]"), "")
assert_equal(DogTag:CleanCode("[nil nil]"), "[nil nil]")
assert_equal(DogTag:CleanCode("[false]"), "[false]")
assert_equal(DogTag:CleanCode("[false false]"), "[false false]")
assert_equal(DogTag:CleanCode("[true]"), "[true]")
assert_equal(DogTag:CleanCode("[true true]"), "[true true]")
assert_equal(parse("['Alpha']"), { "'", "Alpha" })
assert_equal(parse('["Alpha"]'), { '"', "Alpha" })
assert_equal(DogTag:CleanCode("['Alpha']"), "Alpha")
assert_equal(DogTag:CleanCode('["Alpha"]'), "Alpha")
assert_equal(parse("[1234]"), 1234)
assert_equal(parse("['1234']"), { "'", "1234" })
assert_equal(standardize(parse("['1234']")), '1234')
assert_equal(standardize(parse("['0x1234']")), '0x1234')
assert_equal(standardize(parse("['1.000']")), '1.000')
assert_equal(standardize(parse("['1.00']")), '1.00')
assert_equal(standardize(parse("['1.0']")), '1.0')
assert_equal(standardize(parse("['1.']")), '1.')
assert_equal(standardize(parse("['1']")), '1')
assert_equal(standardize(parse("['01']")), '01')
assert_equal(standardize(parse("['001']")), '001')
assert_equal(standardize(parse("['0001']")), '0001')
assert_equal(DogTag:CleanCode("[1234]"), "1234")
assert_equal(parse("[-1234]"), -1234)
assert_equal(DogTag:CleanCode("[-1234]"), "-1234")
assert_equal(parse("[1234.5678]"), 1234.5678)
assert_equal(DogTag:CleanCode("[-1234.5678]"), "-1234.5678")
assert_equal(parse("[-1234.5678]"), -1234.5678)
assert_equal(DogTag:CleanCode("[-1234.5678]"), "-1234.5678")
assert_equal(parse("[1234e5]"), 123400000)
assert_equal(DogTag:CleanCode("[1234e5]"), "123400000")
assert_equal(parse("[1234e-5]"), 0.01234)
assert_equal(DogTag:CleanCode("[1234e-5]"), "0.01234")
assert_equal(parse("[-1234e5]"), -123400000)
assert_equal(DogTag:CleanCode("[-1234e5]"), "-123400000")
assert_equal(parse("[-1234e-5]"), -0.01234)
assert_equal(DogTag:CleanCode("[-1234e-5]"), "-0.01234")
assert_equal(DogTag:CleanCode("[1234] [5678]"), "1234 5678")
assert_equal(DogTag:CleanCode("['hello' 'there']"), "['hello' 'there']")
assert_equal(DogTag:CleanCode("[1234][5678]"), "[1234 5678]")

assert_equal(parse("['Hello [One] There']"), {"'", 'Hello [One] There'})
assert_equal(standardize(parse("['Hello [One] There']")), 'Hello [One] There')
assert_equal(DogTag:CleanCode("['Hello [One] There']"), "['Hello [One] There']")
assert_equal(DogTag:CleanCode('["Hello [One] There"]'), "[\"Hello [One] There\"]")

assert_equal(parse("[1 + 2]"), { "+", 1, 2, })
assert_equal(DogTag:CleanCode("[1 + 2]"), "[1 + 2]")
assert_equal(parse("[1 - 2]"), { "-", 1, 2, })
assert_equal(DogTag:CleanCode("[1 - 2]"), "[1 - 2]")
assert_equal(parse("[1 * 2]"), { "*", 1, 2, })
assert_equal(DogTag:CleanCode("[1 * 2]"), "[1 * 2]")
assert_equal(parse("[1 / 2]"), { "/", 1, 2, })
assert_equal(DogTag:CleanCode("[1 / 2]"), "[1 / 2]")
assert_equal(parse("[1 ^ 2]"), { "^", 1, 2, })
assert_equal(DogTag:CleanCode("[1 ^ 2]"), "[1 ^ 2]")
assert_equal(parse("[1 % 2]"), { "%", 1, 2, })
assert_equal(DogTag:CleanCode("[1 % 2]"), "[1 % 2]")
assert_equal(parse("[1 < 2]"), { "<", 1, 2 })
assert_equal(DogTag:CleanCode("[1 < 2]"), "[1 < 2]")
assert_equal(parse("[1 > 2]"), { ">", 1, 2 })
assert_equal(DogTag:CleanCode("[1 > 2]"), "[1 > 2]")
assert_equal(parse("[1 <= 2]"), { "<=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 <= 2]"), "[1 <= 2]")
assert_equal(parse("[1 >= 2]"), { ">=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 >= 2]"), "[1 >= 2]")
assert_equal(parse("[1 = 2]"), { "=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 = 2]"), "[1 = 2]")
assert_equal(parse("[1 ~= 2]"), { "~=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 ~= 2]"), "[1 ~= 2]")
assert_equal(parse("[1 and 2]"), { "and", 1, 2 })
assert_equal(DogTag:CleanCode("[1 and 2]"), "[1 and 2]")
assert_equal(parse("[1 or 2]"), { "or", 1, 2 })
assert_equal(DogTag:CleanCode("[1 or 2]"), "[1 or 2]")
assert_equal(DogTag:CleanCode("[Thing][Tag or OtherTag]"), "[Thing (Tag or OtherTag)]")
assert_equal(DogTag:CleanCode("[Thing] [Tag or OtherTag]"), "[Thing] [Tag or OtherTag]")
assert_equal(parse("[1 & 2]"), { "&", 1, 2 })
assert_equal(DogTag:CleanCode("[1 & 2]"), "[1 & 2]")
assert_equal(parse("[1 | 2]"), { "|", 1, 2 })
assert_equal(parse("[1 || 2]"), { "|", 1, 2 })
assert_equal(DogTag:CleanCode("[1 | 2]"), "[1 || 2]")
assert_equal(DogTag:CleanCode("[1 || 2]"), "[1 || 2]")
assert_equal(parse("[Alpha Bravo]"), { "concat", { "tag", "Alpha" }, { "tag", "Bravo"}, })
assert_equal(parse("[~Alpha:~Bravo]"), { "~", { "~" , { "mod", "Bravo", { "tag", "Alpha"}, }, }, })
assert_equal(DogTag:CleanCode("[One Bravo]"), "[One Bravo]")
assert_equal(parse("[1 ? 2]"), { "?", 1, 2 })
assert_equal(DogTag:CleanCode("[1?2]"), "[1 ? 2]")
assert_equal(parse("[1 ? 2 ! 3]"), { "?", 1, 2, 3 })
assert_equal(DogTag:CleanCode("[1?2!3]"), "[1 ? 2 ! 3]")
assert_equal(parse("[1?2!3?4!5]"), { "?", 1, 2, { "?", 3, 4, 5 } })
assert_equal(parse("[if 1 then 2]"), { "if", 1, 2 })
assert_equal(parse("[if(1)then(2)]"), { "if", { "(", 1}, {"(", 2} })
assert_equal(parse("[ifabc then def]"), nil)
assert_equal(parse("[if 1 then 2 end]"), { "if", 1, 2 })
assert_equal(DogTag:CleanCode("[if 1 then 2]"), "[if 1 then\n    2\nend]")
assert_equal(DogTag:CleanCode("[if 1 then 2 end]"), "[if 1 then\n    2\nend]")
assert_equal(parse("[if 1 then 2 else 3]"), { "if", 1, 2, 3 })
assert_equal(parse("[if 1 then 2 else 3 end]"), { "if", 1, 2, 3 })
assert_equal(DogTag:CleanCode("[if 1 then 2 else 3]"), "[if 1 then\n    2\nelse\n    3\nend]")
assert_equal(DogTag:CleanCode("[if 1 then 2 else 3 end]"), "[if 1 then\n    2\nelse\n    3\nend]")
assert_equal(parse("[if 1 then 2 else if 3 then 4 else 5]"), { "if", 1, 2, { "if", 3, 4, 5 } })
assert_equal(parse("[if 1 then 2 elseif 3 then 4 else 5]"), { "if", 1, 2, { "if", 3, 4, 5 } })
assert_equal(parse("[if 1 then 2 else if 3 then 4 else 5 end]"), { "if", 1, 2, { "if", 3, 4, 5 } })
assert_equal(parse("[if 1 then 2 elseif 3 then 4 else 5 end]"), { "if", 1, 2, { "if", 3, 4, 5 } })
assert_equal(DogTag:CleanCode("[if 1 then 2 else if 3 then 4 else 5]"), "[if 1 then\n    2\nelseif 3 then\n    4\nelse\n    5\nend]")
assert_equal(DogTag:CleanCode("[if 1 then 2 elseif 3 then 4 else 5]"), "[if 1 then\n    2\nelseif 3 then\n    4\nelse\n    5\nend]")
assert_equal(DogTag:CleanCode("[if 1 then 2 else if 3 then 4 else 5 end]"), "[if 1 then\n    2\nelseif 3 then\n    4\nelse\n    5\nend]")
assert_equal(DogTag:CleanCode("[if 1 then 2 elseif 3 then 4 else 5 end]"), "[if 1 then\n    2\nelseif 3 then\n    4\nelse\n    5\nend]")

assert_equal(DogTag:CleanCode("[if 1 then if 2 then 3 else 4 elseif 5 then 6 else 7]"), [=[[if 1 then
    if 2 then
        3
    else
        4
    end
elseif 5 then
    6
else
    7
end]]=])

assert_equal(DogTag:CleanCode("[if 1 then if 2 then 3 else 4 else (if 5 then 6 else 7)]"), [=[[if 1 then
    if 2 then
        3
    else
        4
    end
else
    (if 5 then
        6
    else
        7
    end)
end]]=])

assert_equal(parse("[Func('Hello' 'There')]"), { "tag", "Func", {"concat", {"'", "Hello"}, {"'", "There"}} })
assert_equal(DogTag:CleanCode("[Func('Hello' 'There')]"), "[Func('Hello' 'There')]")

assert_equal(standardize(parse("[1 & 2]")), { "and", 1, 2 })
assert_equal(standardize(parse("[1 | 2]")), { "or", 1, 2 })
assert_equal(standardize(parse("[1 || 2]")), { "or", 1, 2 })
assert_equal(standardize(parse("[1 ? 2]")), { "if", 1, 2 })
assert_equal(standardize(parse("[1 ? 2 ! 3]")), { "if", 1, 2, 3 })

assert_equal(parse("[1+2]"), { "+", 1, 2, })
assert_equal(parse("[1-2]"), { "-", 1, 2, })
assert_equal(parse("[1*2]"), { "*", 1, 2, })
assert_equal(parse("[1/2]"), { "/", 1, 2, })
assert_equal(parse("[1^2]"), { "^", 1, 2, })
assert_equal(parse("[1%2]"), { "%", 1, 2, })
assert_equal(parse("[1<2]"), { "<", 1, 2 })
assert_equal(parse("[1>2]"), { ">", 1, 2 })
assert_equal(parse("[1<=2]"), { "<=", 1, 2 })
assert_equal(parse("[1>=2]"), { ">=", 1, 2 })
assert_equal(parse("[1=2]"), { "=", 1, 2 })
assert_equal(parse("[1~=2]"), { "~=", 1, 2 })
assert_equal(parse("[1&2]"), { "&", 1, 2 })
assert_equal(parse("[1|2]"), { "|", 1, 2 })
assert_equal(parse("[1||2]"), { "|", 1, 2 })
assert_equal(parse("[1?2]"), { "?", 1, 2 })
assert_equal(parse("[1?2!3]"), { "?", 1, 2, 3 })

assert_equal(parse("[1 and 2 or 3]"), { "or", { "and", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 and 2 or 3]"), "[(1 and 2) or 3]")
assert_equal(parse("[1 or 2 and 3]"), { "and", { "or", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 or 2 and 3]"), "[(1 or 2) and 3]")
assert_equal(parse("[1 + 2 - 3]"), { "-", { "+", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 + 2 - 3]"), "[1 + 2 - 3]")
assert_equal(parse("[1 - 2 + 3]"), { "+", { "-", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 - 2 + 3]"), "[1 - 2 + 3]")
assert_equal(parse("[1 * 2 / 3]"), { "/", { "*", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 * 2 / 3]"), "[1 * 2 / 3]")
assert_equal(parse("[1 / 2 * 3]"), { "*", { "/", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 / 2 * 3]"), "[1 / 2 * 3]")
assert_equal(parse("[1 * 2 % 3]"), { "%", { "*", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 * 2 % 3]"), "[1 * 2 % 3]")
assert_equal(parse("[1 % 2 * 3]"), { "*", { "%", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 % 2 * 3]"), "[1 % 2 * 3]")

assert_equal(parse("[1 ? 2 and 3]"), { "?", 1, { "and", 2, 3 } })
assert_equal(DogTag:CleanCode("[1 ? 2 and 3]"), "[1 ? 2 and 3]")
assert_equal(parse("[1 and 2 ? 3]"), { "?", { "and", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 and 2 ? 3]"), "[1 and 2 ? 3]")
assert_equal(parse("[1 ? 2 and 3 ! 4 or 5]"), { "?", 1, { "and", 2, 3 }, { "or", 4, 5 } })
assert_equal(DogTag:CleanCode("[1 ? 2 and 3 ! 4 or 5]"), "[1 ? 2 and 3 ! 4 or 5]")
assert_equal(parse("[1 and 2 ? 3 ! 4]"), { "?", { "and", 1, 2 }, 3, 4 })
assert_equal(DogTag:CleanCode("[1 and 2 ? 3 ! 4]"), "[1 and 2 ? 3 ! 4]")
assert_equal(parse("[1 and 2 < 3]"), { "<", { "and", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 and 2 < 3]"), "[1 and 2 < 3]")
assert_equal(parse("[1 < 2 and 3]"), { "<", 1, { "and", 2, 3 } })
assert_equal(DogTag:CleanCode("[1 < 2 and 3]"), "[1 < 2 and 3]")
assert_equal(parse("[1 + 2 and 3]"), { "and", { "+", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 + 2 and 3]"), "[1 + 2 and 3]")
assert_equal(parse("[1 and 2 + 3]"), { "and", 1, { "+", 2, 3 } })
assert_equal(DogTag:CleanCode("[1 and 2 + 3]"), "[1 and 2 + 3]")
assert_equal(parse("[1 + 2 * 3]"), { "+", 1, { "*", 2, 3 }, })
assert_equal(DogTag:CleanCode("[1 + 2 * 3]"), "[1 + 2 * 3]")
assert_equal(parse("[1 * 2 + 3]"), { "+", { "*", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 * 2 + 3]"), "[1 * 2 + 3]")
assert_equal(parse("[1 * 2 ^ 3]"), { "*", 1, { "^", 2, 3 }, })
assert_equal(DogTag:CleanCode("[1 * 2 ^ 3]"), "[1 * 2 ^ 3]")
assert_equal(parse("[1 ^ 2 * 3]"), { "*", { "^", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 ^ 2 * 3]"), "[1 ^ 2 * 3]")

assert_equal(parse("[(1 ^ 2) * 3]"), { "*", { "(", { "^", 1, 2 } }, 3 })
assert_equal(parse("[[1 ^ 2] * 3]"), { "*", { "[", { "^", 1, 2 } }, 3 })
-- pointless parenthesization should stay
assert_equal(DogTag:CleanCode("[(1 ^ 2) * 3]"), "[(1 ^ 2) * 3]")
assert_equal(DogTag:CleanCode("[[1 ^ 2] * 3]"), "[[1 ^ 2] * 3]")

assert_equal(parse("[(1) * 3]"), { "*", { "(", 1 }, 3 })
assert_equal(parse("[[1] * 3]"), { "*", { "[", 1 }, 3 })

-- but parenthesization of a tag, number, or string should go away
assert_equal(DogTag:CleanCode("[(1) * 3]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[[1] * 3]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[1 * (3)]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[1 * [3]]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[Func(('Hello') 'There')]"), "[Func('Hello' 'There')]")
assert_equal(DogTag:CleanCode("[Func(['Hello'] 'There')]"), "[Func('Hello' 'There')]")
assert_equal(DogTag:CleanCode("[Func('Hello' ('There'))]"), "[Func('Hello' 'There')]")
assert_equal(DogTag:CleanCode("[Func('Hello' ['There'])]"), "[Func('Hello' 'There')]")
assert_equal(DogTag:CleanCode("[(Alpha) * Bravo]"), "[Alpha * Bravo]")
assert_equal(DogTag:CleanCode("[[Alpha] * Bravo]"), "[Alpha * Bravo]")
assert_equal(DogTag:CleanCode("[(Alpha) * Bravo]"), "[Alpha * Bravo]")
assert_equal(DogTag:CleanCode("[[Alpha] * Bravo]"), "[Alpha * Bravo]")

assert_equal(parse("[1 ^ (2 * 3)]"), { "^", 1, { "(", { "*", 2, 3 } } })
assert_equal(parse("[1 ^ [2 * 3]]"), { "^", 1, { "[", { "*", 2, 3 } } })
assert_equal(DogTag:CleanCode("[1 ^ (2 * 3)]"), "[1 ^ (2 * 3)]")
assert_equal(DogTag:CleanCode("[1 ^ [2 * 3]]"), "[1 ^ [2 * 3]]")
assert_equal(parse("[(1 + 2) * 3]"), { "*", { "(", { "+", 1, 2 } }, 3 })
assert_equal(DogTag:CleanCode("[(1 + 2) * 3]"), "[(1 + 2) * 3]")
assert_equal(parse("[1 + (2 ? 3)]"), { "+", 1, { "(", { "?", 2, 3 } } })
assert_equal(DogTag:CleanCode("[1 + (2 ? 3)]"), "[1 + (2 ? 3)]")
assert_equal(parse("[(2 ? 3 ! 4) + 1]"), { "+", { "(", { "?", 2, 3, 4 } }, 1 })
assert_equal(DogTag:CleanCode("[(2 ? 3 ! 4) + 1]"), "[(2 ? 3 ! 4) + 1]")
assert_equal(parse("[1 + (if 2 then 3)]"), { "+", 1, { "(", { "if", 2, 3 } } })
assert_equal(DogTag:CleanCode("[1 + (if 2 then 3)]"), "[1 + (if 2 then\n    3\nend)]")
assert_equal(parse("[(if 2 then 3 else 4) + 1]"), { "+", { "(", { "if", 2, 3, 4 } }, 1 })
assert_equal(DogTag:CleanCode("[(if 2 then 3 else 4) + 1]"), "[(if 2 then\n    3\nelse\n    4\nend) + 1]")

assert_equal(parse("[Alpha(Bravo + Charlie)]"), { "tag", "Alpha", { "+", {"tag", "Bravo"}, {"tag", "Charlie"} } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo + Charlie)]"), "[Alpha(Bravo + Charlie)]")
assert_equal(parse("[Alpha (Bravo + Charlie)]"), { "concat", {"tag", "Alpha"}, { "(", { "+", {"tag", "Bravo"}, {"tag", "Charlie"} } } })
assert_equal(DogTag:CleanCode("[One (Bravo + Charlie)]"), "[One (Bravo + Charlie)]")

assert_equal(parse("[not Alpha]"), { "not", { "tag", "Alpha" }, })
assert_equal(DogTag:CleanCode("[not Alpha]"), "[not Alpha]")
assert_equal(parse("[not not Alpha]"), { "not", { "not", { "tag", "Alpha" }, }, })
assert_equal(DogTag:CleanCode("[not not Alpha]"), "[not not Alpha]")
assert_equal(parse("[~Alpha]"), { "~", { "tag", "Alpha" }, })
assert_equal(DogTag:CleanCode("[~Alpha]"), "[~Alpha]")
assert_equal(parse("[~(1 > 2)]"), { "~", { "(", { ">", 1, 2 } }, })
assert_equal(DogTag:CleanCode("[~(1 > 2)]"), "[~(1 > 2)]")
assert_equal(parse("[not(1 > 2)]"), { "not", { "(", { ">", 1, 2 } }, })
assert_equal(DogTag:CleanCode("[not(1 > 2)]"), "[not (1 > 2)]")
assert_equal(standardize(parse("[~Alpha]")), { "not", { "tag", "Alpha" }, })

assert_equal(standardize(parse("[Alpha(bravo=(Charlie+2))]")), { "tag", "Alpha", kwarg = { bravo = { "+", { "tag", "Charlie" }, 2 } } })

assert_equal(parse("[Alpha(key=Bravo)]"), { "tag", "Alpha", kwarg = { key = { "tag", "Bravo" } } })
assert_equal(DogTag:CleanCode("[Alpha(key=Bravo)]"), "[Alpha(key=Bravo)]")
assert_equal(parse("[Alpha(Bravo, key=Charlie)]"), { "tag", "Alpha", { "tag", "Bravo" }, kwarg = { key = { "tag", "Charlie" } } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, key=Charlie)]"), "[Alpha(Bravo, key=Charlie)]")
assert_equal(parse("[Alpha(bravo=Charlie, delta=Echo)]"), { "tag", "Alpha", kwarg = { bravo = { "tag", "Charlie" }, delta = { "tag", "Echo" } } })
assert_equal(DogTag:CleanCode("[Alpha(bravo=Charlie, delta=Echo)]"), "[Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(DogTag:CleanCode("[Alpha(delta=Echo, bravo=Charlie)]"), "[Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(parse("[Alpha((key=Bravo))]"), { "tag", "Alpha", { "(", { "=", { "tag", "key" }, { "tag", "Bravo" } } } })
assert_equal(DogTag:CleanCode("[Alpha(key = Bravo)]"), "[Alpha(key = Bravo)]")
assert_equal(DogTag:CleanCode("[Alpha((key=Bravo))]"), "[Alpha((key = Bravo))]")
assert_equal(parse("[Class(unit='mouseovertarget')]"), { "tag", "Class", kwarg = { unit = {"'", "mouseovertarget"} } })
assert_equal(parse("[Alpha(key=Bravo, Charlie)]"), nil)
assert_equal(parse("[Alpha(Bravo Charlie)]"), { "tag", "Alpha", { "concat", { "tag", "Bravo"}, { "tag", "Charlie" } } })
assert_equal(parse("[Alpha(Bravo ' ' Charlie)]"), { "tag", "Alpha", { "concat", { "tag", "Bravo"}, {"'", " "}, { "tag", "Charlie" } } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo ' ' Charlie)]"), "[Alpha(Bravo ' ' Charlie)]")
assert_equal(DogTag:CleanCode("[Alpha(Bravo \" \" Charlie)]"), "[Alpha(Bravo \" \" Charlie)]")

assert_equal(parse("[Alpha:Bravo(key=Charlie)]"), { "mod", "Bravo", { "tag", "Alpha" }, kwarg = { key = { "tag", "Charlie" } } })
assert_equal(DogTag:CleanCode("[Alpha:Bravo(key=Charlie)]"), "[Alpha:Bravo(key=Charlie)]")
assert_equal(parse("[Alpha:Bravo(Charlie, key=Delta)]"), { "mod", "Bravo", { "tag", "Alpha" }, { "tag", "Charlie" }, kwarg = { key = { "tag", "Delta" } } })
assert_equal(DogTag:CleanCode("[Alpha:Bravo(Charlie, key=Delta)]"), "[Alpha:Bravo(Charlie, key=Delta)]")
assert_equal(parse("[Tag:Alpha(bravo=Charlie, delta=Echo)]"), { "mod", "Alpha", { "tag", "Tag" }, kwarg = { bravo = { "tag", "Charlie" }, delta = { "tag", "Echo" } } })
assert_equal(DogTag:CleanCode("[Tag:Alpha(bravo=Charlie, delta=Echo)]"), "[Tag:Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(DogTag:CleanCode("[Tag:Alpha(delta=Echo, bravo=Charlie)]"), "[Tag:Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(parse("[Tag:Alpha((key=Bravo))]"), { "mod", "Alpha", { "tag", "Tag" }, { "(", { "=", { "tag", "key" }, { "tag", "Bravo" } } } })
assert_equal(DogTag:CleanCode("[Tag:Alpha(key = Bravo)]"), "[Tag:Alpha(key = Bravo)]")
assert_equal(DogTag:CleanCode("[Tag:Alpha((key=Bravo))]"), "[Tag:Alpha((key = Bravo))]")
assert_equal(parse("[Class(unit='mouseovertarget'):ClassColor(unit='mouseovertarget')]"), { "mod", "ClassColor", { "tag", "Class", kwarg = { unit = {"'", "mouseovertarget"} } }, kwarg = { unit = {"'", "mouseovertarget"} } })

assert_equal(parse("[-MissingHP]"), { "unm", { "tag", "MissingHP" } })
assert_equal(DogTag:CleanCode("[-MissingHP]"), "[-MissingHP]")
assert_equal(parse("[-(-1)]"), { "unm", { "(", -1 } })
assert_equal(standardize(parse("[-(-1)]")), {"unm", -1})
assert_equal(standardize(parse("[-(-(-1))]")), { "unm", { "unm", -1}})
assert_equal(parse("[AbsoluteValue(-5)]"), { "tag", "AbsoluteValue", -5 })
assert_equal(parse("[(-5):AbsoluteValue]"), { "mod", "AbsoluteValue", { "(", -5 } })
assert_equal(parse("[-5:AbsoluteValue]"), { "mod", "AbsoluteValue", -5})
assert_equal(parse("[-5:AbsoluteValue:AbsoluteValue]"), { "mod", "AbsoluteValue", { "mod", "AbsoluteValue", -5} })
assert_equal(parse("[-MissingHP:AbsoluteValue]"), { "mod", "AbsoluteValue", { "unm", { "tag", "MissingHP" } } })

assert_equal(parse("[]"), nil)
assert_equal(parse("["), nil)
assert_equal(parse("hello []"), nil)
assert_equal(parse("hello ["), nil)
assert_equal(DogTag:CleanCode("[]"), "[]")
assert_equal(DogTag:CleanCode("["), "[")
assert_equal(DogTag:CleanCode("hello []"), "hello []")
assert_equal(DogTag:CleanCode("hello ["), "hello [")

assert_equal(DogTag:ColorizeCode("hello"), "|cffff7f7fhello|r")
assert_equal(DogTag:ColorizeCode("[or]"), "|cffffffff[|cffff7fffor|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[+]"), "|cffffffff[|cffff7fff+|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[~=]"), "|cffffffff[|cffff7fff~=|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[<=]"), "|cffffffff[|cffff7fff<=|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[>=]"), "|cffffffff[|cffff7fff>=|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[||]"), "|cffffffff[|cffff7fff|||cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[Tag]"), "|cffffffff[|cff00ffffTag|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("['Hello']"), "|cffffffff[|cffff7f7f'Hello'|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[Tag(Arg)]"), "|cffffffff[|cff00ffffTag|cffffffff(|cff00ffffArg|cffffffff)|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[Tag(Arg, Other)]"), "|cffffffff[|cff00ffffTag|cffffffff(|cff00ffffArg|cffffffff, |cff00ffffOther|cffffffff)|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[Tag(kw=Arg)]"), "|cffffffff[|cff00ffffTag|cffffffff(|cffff0000kw|cffff7fff=|cff00ffffArg|cffffffff)|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[Tag:Mod]"), "|cffffffff[|cff00ffffTag|cffff7fff:|cff00ff00Mod|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("hello [Tag:Mod] hello"), "|cffff7f7fhello |cffffffff[|cff00ffffTag|cffff7fff:|cff00ff00Mod|cffffffff]|cffff7f7f hello|r")
assert_equal(DogTag:ColorizeCode("[(Tag)]"), "|cffffffff[|cffffffff(|cff00ffffTag|cffffffff)|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[42]"), "|cffffffff[|cffff7f7f42|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[42.5]"), "|cffffffff[|cffff7f7f42.5|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[42e5]"), "|cffffffff[|cffff7f7f42e5|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[42.5e5]"), "|cffffffff[|cffff7f7f42.5e5|cffffffff]|r")
assert_equal(DogTag:ColorizeCode(("x"):rep(10000)), "|cffff7f7f" .. ("x"):rep(10000) .. "|r")
assert_equal(DogTag:ColorizeCode("[" .. ("x"):rep(10000) .. "]"), "|cffffffff[|cff00ffff" .. ("x"):rep(10000) .. "|cffffffff]|r")
assert_equal(DogTag:ColorizeCode("[" .. ("1"):rep(10000) .. "]"), "|cffffffff[|cffff7f7f" .. ("1"):rep(10000) .. "|cffffffff]|r")

old_DogTag_Evaluate(DogTag, "[Alpha(key=Bravo, Charlie)]")

assert_equal(DogTag:Evaluate("[Alpha(key=Bravo, Charlie)]"), "Syntax error")

assert_equal(DogTag:Evaluate("[StaticOne]"), 1)

assert_equal(DogTag:Evaluate("[One]"), 1)
assert_equal(DogTag:Evaluate("[One:PlusOne]"), 2)
assert_equal(DogTag:Evaluate("[PlusOne(One):PlusOne]"), 3)
assert_equal(DogTag:Evaluate("[PlusOne(number=One)]"), 2)
GlobalCheck_data = "Hello World"
assert_equal(DogTag:Evaluate("[GlobalCheck]"), "Hello World")
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[One] [GlobalCheck] [Two]"), "1 2")
assert_equal(DogTag:Evaluate("[One]    [Two]"), "1    2")
assert_equal(DogTag:Evaluate("    [One]    [Two]    "), "    1    2    ")
assert_equal(DogTag:Evaluate("[GlobalCheck] Hello"), "Hello")
assert_equal(DogTag:Evaluate("[GlobalCheck] [GlobalCheck] Hello"), "Hello")
assert_equal(DogTag:Evaluate("Hello [GlobalCheck]"), "Hello")
assert_equal(DogTag:Evaluate("Hello [GlobalCheck] [GlobalCheck]"), "Hello")
assert_equal(DogTag:Evaluate("[GlobalCheck] [GlobalCheck] Hello [GlobalCheck] [GlobalCheck]"), "Hello")
assert_equal(DogTag:Evaluate("[GlobalCheck] [One] [Two]"), "1 2")

myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 2)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck] [FunctionNumberCheck]"), "3 3") -- check caching

assert_equal(DogTag:Evaluate("[AbsoluteValue(5)]"), 5)
assert_equal(DogTag:Evaluate("[AbsoluteValue(-5)]"), 5)
assert_equal(DogTag:Evaluate("[5:AbsoluteValue]"), 5)
assert_equal(DogTag:Evaluate("[-5:AbsoluteValue]"), 5)

GlobalCheck_data = 2
assert_equal(DogTag:Evaluate("[GlobalCheck + One]"), 3)
assert_equal(DogTag:Evaluate("[One + GlobalCheck]"), 3)
assert_equal(DogTag:Evaluate("[GlobalCheck + GlobalCheck]"), 4)

assert_equal(DogTag:Evaluate("[PlusOne]"), [=[Arg #1 (number) req'd for PlusOne]=])
assert_equal(DogTag:Evaluate("[Unknown]"), [=[Unknown tag Unknown]=])
assert_equal(DogTag:Evaluate("[Subtract(Unknown, 2)]"), [=[Unknown tag Unknown]=])
assert_equal(DogTag:Evaluate("[Subtract]"), [=[Arg #1 (left) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(1)]"), [=[Arg #2 (right) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(right=2)]"), [=[Arg #1 (left) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(left=1)]"), [=[Arg #2 (right) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(1, 2, extra='Stuff')]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(1, 2, 3)]"), [=[Too many args for Subtract]=])
assert_equal(DogTag:Evaluate("[CheckNumDefault(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNumDefault]"), 50)
assert_equal(DogTag:Evaluate("[CheckNumDefault(50)]"), 50)
assert_equal(DogTag:Evaluate("[CheckNumDefault(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNumDefault('Test')]"), 0)
assert_equal(DogTag:Evaluate("[CheckStrDefault(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrDefault]"), "Value")
assert_equal(DogTag:Evaluate("[CheckStrDefault(50)]"), 50)
assert_equal(DogTag:Evaluate("[CheckStrDefault(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrDefault('Test')]"), "Test")
assert_equal(DogTag:Evaluate("[CheckNilDefault(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNilDefault]"), nil)
assert_equal(DogTag:Evaluate("[CheckNilDefault(50)]"), 50)
assert_equal(DogTag:Evaluate("[CheckNilDefault('Test')]"), nil)
assert_equal(DogTag:Evaluate("[CheckNilDefault(One)]"), 1)
assert_equal(DogTag:Evaluate(("x"):rep(10000)), ("x"):rep(10000))
assert_equal(DogTag:Evaluate("[" .. ("x"):rep(10000) .. "]"), "Unknown tag " .. ("x"):rep(10000))
assert_equal(DogTag:Evaluate("[" .. ("1"):rep(10000) .. "]"), 1/0)

assert_equal(DogTag:Evaluate("[1 + 2]"), 3)
assert_equal(DogTag:Evaluate("[1 - 2]"), -1)
assert_equal(DogTag:Evaluate("[1 * 2]"), 2)
assert_equal(DogTag:Evaluate("[1 / 2]"), 1/2)
assert_equal(DogTag:Evaluate("[0 / 0]"), 0) -- odd case, good for WoW
assert_equal(standardize(parse("[1 / 0]")), { "/", 1, 0 })
assert_equal(standardize(parse("[(1 / 0)]")), { "/", 1, 0 })
assert_equal(DogTag:Evaluate("[1 / 0]"), 1/0)
assert_equal(DogTag:Evaluate("[(1 / 0)]"), 1/0)
assert_equal(DogTag:Evaluate("[-1 / 0]"), -1/0)
assert_equal(DogTag:Evaluate("[-(1 / 0)]"), -1/0)
assert_equal(parse("[(1 / 0)]"), { "(", { "/", 1, 0 } })
assert_equal(DogTag:Evaluate("[5 % 3]"), 2)
assert_equal(DogTag:Evaluate("[5 ^ 3]"), 125)
assert_equal(DogTag:Evaluate("[5 < 3]"), nil)
assert_equal(DogTag:Evaluate("[3 < 5]"), 3)
assert_equal(DogTag:Evaluate("[3 < 3]"), nil)
assert_equal(DogTag:Evaluate("[5 > 3]"), 5)
assert_equal(DogTag:Evaluate("[3 > 5]"), nil)
assert_equal(DogTag:Evaluate("[3 > 3]"), nil)
assert_equal(DogTag:Evaluate("[5 <= 3]"), nil)
assert_equal(DogTag:Evaluate("[3 <= 5]"), 3)
assert_equal(DogTag:Evaluate("[3 <= 3]"), 3)
assert_equal(DogTag:Evaluate("[5 >= 3]"), 5)
assert_equal(DogTag:Evaluate("[3 >= 5]"), nil)
assert_equal(DogTag:Evaluate("[3 >= 3]"), 3)
assert_equal(DogTag:Evaluate("[1 = 1]"), 1)
assert_equal(DogTag:Evaluate("[1 = 2]"), nil)
assert_equal(DogTag:Evaluate("[1 ~= 1]"), nil)
assert_equal(DogTag:Evaluate("[1 ~= 2]"), 1)
assert_equal(DogTag:Evaluate("[1 and 2]"), 2)
assert_equal(DogTag:Evaluate("[1 or 2]"), 1)
assert_equal(DogTag:Evaluate("[(1 = 2) and 2]"), nil)
assert_equal(DogTag:Evaluate("[(1 = 2) or 2]"), 2)
assert_equal(DogTag:Evaluate("[1 & 2]"), 2)
assert_equal(DogTag:Evaluate("[1 | 2]"), 1)
assert_equal(DogTag:Evaluate("[1 || 2]"), 1)
assert_equal(DogTag:Evaluate("[(1 = 2) & 2]"), nil)
assert_equal(DogTag:Evaluate("[(1 = 2) | 2]"), 2)
assert_equal(DogTag:Evaluate("[(1 = 2) || 2]"), 2)
assert_equal(DogTag:Evaluate("[nil = 5]"), nil)
assert_equal(DogTag:Evaluate("[5 = nil]"), nil)
assert_equal(DogTag:Evaluate("[if 1 then 2]"), 2)
assert_equal(DogTag:Evaluate("[if 1 then 2 else 3]"), 2)
assert_equal(DogTag:Evaluate("[if 1 = 2 then 2]"), nil)
assert_equal(DogTag:Evaluate("[if 1 = 2 then 2 else 3]"), 3)
assert_equal(DogTag:Evaluate("[1 ? 2]"), 2)
assert_equal(DogTag:Evaluate("[1 ? 2 ! 3]"), 2)
assert_equal(DogTag:Evaluate("[1 = 2 ? 2]"), nil)
assert_equal(DogTag:Evaluate("[1 = 2 ? 2 ! 3]"), 3)
assert_equal(DogTag:Evaluate("['Hello' 'There']"), "HelloThere")
assert_equal(DogTag:Evaluate("[-(-1)]"), 1)
assert_equal(DogTag:Evaluate("[-One]"), -1)
assert_equal(DogTag:Evaluate("[not 'Hello']"), nil)
assert_equal(DogTag:Evaluate("[not not 'Hello']"), "True")
GlobalCheck_data = 'Hello World'
assert_equal(DogTag:Evaluate("[GlobalCheck]"), "Hello World")
assert_equal(DogTag:Evaluate("[not GlobalCheck]"), nil)
assert_equal(DogTag:Evaluate("[not not GlobalCheck]"), "True")
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck]"), nil)
assert_equal(DogTag:Evaluate("[not GlobalCheck]"), "True")
assert_equal(DogTag:Evaluate("[not not GlobalCheck]"), nil)
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean]"), "True")
assert_equal(DogTag:Evaluate("[not GlobalCheckBoolean]"), nil)
assert_equal(DogTag:Evaluate("[not not GlobalCheckBoolean]"), "True")
GlobalCheckBoolean_data = false
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean]"), nil)
assert_equal(DogTag:Evaluate("[not GlobalCheckBoolean]"), "True")
assert_equal(DogTag:Evaluate("[not not GlobalCheckBoolean]"), nil)
assert_equal(DogTag:Evaluate("[One + One]"), 2)
assert_equal(DogTag:Evaluate("[Subtract(1, 2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(2, 1)]"), 1)
assert_equal(DogTag:Evaluate("[Subtract(1, right=2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(2, right=1)]"), 1)
assert_equal(DogTag:Evaluate("[Subtract(left=1, right=2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(right=1, left=2)]"), 1)
assert_equal(DogTag:Evaluate("[1:Subtract(2)]"), -1)
assert_equal(DogTag:Evaluate("[2:Subtract(1)]"), 1)
assert_equal(DogTag:Evaluate("[false]"), nil)
assert_equal(DogTag:Evaluate("[not false]"), "True")
assert_equal(DogTag:Evaluate("[true]"), "True")
assert_equal(DogTag:Evaluate("[not true]"), nil)
assert_equal(DogTag:Evaluate("[nil nil]"), nil)
assert_equal(DogTag:Evaluate("[false false]"), nil)
assert_equal(DogTag:Evaluate("[nil '' false]"), nil)
assert_equal(DogTag:Evaluate("[not nil not '' not false]"), "TrueTrueTrue")
assert_equal(DogTag:Evaluate("[nil 'Hello' nil]"), "Hello")
assert_equal(DogTag:Evaluate("[nil 1234 nil]"), 1234)
assert_equal(DogTag:Evaluate("[nil 1234 One nil]"), 12341)
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[nil 1234 GlobalCheck nil]"), 12345)
GlobalCheck_data = 'Hello'
assert_equal(DogTag:Evaluate("[nil 1234 GlobalCheck nil]"), '1234Hello')
assert_equal(DogTag:Evaluate("['+' 1234]"), '+1234')

assert_equal(DogTag:Evaluate("Hello [Unknown#test]"), 'Syntax error')

myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
assert_equal(DogTag:Evaluate("[true and FunctionNumberCheck]"), 2)
assert_equal(DogTag:Evaluate("[false and FunctionNumberCheck]"), nil) -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 3)
assert_equal(DogTag:Evaluate("[true or FunctionNumberCheck]"), "True") -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[false or FunctionNumberCheck]"), 4)
assert_equal(DogTag:Evaluate("[if true then FunctionNumberCheck]"), 5)
assert_equal(DogTag:Evaluate("[if false then FunctionNumberCheck]"), nil)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 6)
assert_equal(DogTag:Evaluate("[if true then 'True' else FunctionNumberCheck]"), 'True')
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 7)
assert_equal(DogTag:Evaluate("[if false then 'True' else FunctionNumberCheck]"), 8)

myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[GlobalCheck and FunctionNumberCheck]"), 2)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck and FunctionNumberCheck]"), nil) -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 3)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[GlobalCheck or FunctionNumberCheck]"), "True") -- shouldn't call FunctionNumberCheck
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck or FunctionNumberCheck]"), 4)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[if GlobalCheck then FunctionNumberCheck]"), 5)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[if GlobalCheck then FunctionNumberCheck]"), nil)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 6)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[if GlobalCheck then 'True' else FunctionNumberCheck]"), 'True')
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 7)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[if GlobalCheck then 'True' else FunctionNumberCheck]"), 8)


assert_equal(DogTag:Evaluate("[Boolean('True' and nil:Short)]"), nil)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[Boolean(GlobalCheck and nil:Short)]"), nil)
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[Boolean(GlobalCheckBoolean and nil:Short)]"), nil)
assert_equal(DogTag:Evaluate("[Boolean('True' and 0:Hide(0):Short)]"), nil)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[Boolean(GlobalCheck and 0:Hide(0):Short)]"), nil)
assert_equal(DogTag:Evaluate("[Boolean(RetSame('True') and 0:Hide(0):Short)]"), nil)
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[Boolean(GlobalCheckBoolean and 0:Hide(0):Short)]"), nil)
assert_equal(DogTag:Evaluate("[Boolean(OtherRetSame('True') and (One - 1):Hide(0):Short)]"), nil)

assert_equal(DogTag:Evaluate("[Boolean(if 'True' then nil:Short)]"), nil)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[Boolean(if GlobalCheck then nil:Short)]"), nil)
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[Boolean(if GlobalCheckBoolean then nil:Short)]"), nil)
assert_equal(DogTag:Evaluate("[Boolean(if 'True' then 0:Hide(0):Short)]"), nil)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[Boolean(if GlobalCheck then 0:Hide(0):Short)]"), nil)
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[Boolean(if GlobalCheckBoolean then 0:Hide(0):Short)]"), nil)
assert_equal(DogTag:Evaluate("[Boolean(if OtherRetSame('True') then (One - 1):Hide(0):Short)]"), nil)


assert_equal(DogTag:Evaluate("[PlusOne(1 1)]"), 12)

assert_equal(DogTag:Evaluate("[CheckNumTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2)]"), '1-2')
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2, 3)]"), '1-2-3')
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2, 3, 'Hello')]"), '1-2-3-0')
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2, 3, One, 'Hello')]"), '1-2-3-1-0')
assert_equal(DogTag:Evaluate("[CheckNumTuple]"), nil)

assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1, 2)]"), 2)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1, 2, 3)]"), 3)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1, -2, One:PlusOne, -3)]"), 2)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple]"), 0) -- special cause it does math.max(0, ...), which should turn into math.max(0), not math.max(0, )

assert_equal(DogTag:Evaluate("[CheckStrTuple('Hello')]"), 'Hylly')
assert_equal(DogTag:Evaluate("[CheckStrTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrTuple(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrTuple('Hello', \"There\", 'Friend')]"), 'HyllyThyryFryynd')
assert_equal(DogTag:Evaluate("[CheckStrTuple]"), nil)
assert_equal(DogTag:Evaluate("[CheckStrTuple('Hello', 52, 'Friend', One)]"), 'Hylly52Fryynd1')

assert_equal(DogTag:Evaluate("[CheckBooleanTuple]"), 0)
assert_equal(DogTag:Evaluate("[CheckBooleanTuple(true, false, true)]"), 5)
assert_equal(DogTag:Evaluate("[CheckBooleanTuple(true, true, false, true)]"), 11)

assert_equal(DogTag:Evaluate("[CheckNilTuple]"), 0)
assert_equal(DogTag:Evaluate("[CheckNilTuple(true, false, true)]"), 3)
assert_equal(DogTag:Evaluate("[CheckNilTuple(true, true, false, true)]"), 4)

assert_equal(DogTag:Evaluate("[CheckAnyTuple]"), nil)
assert_equal(DogTag:Evaluate("[CheckAnyTuple(true, false, true)]"), "string:True;nil:nil;string:True")
assert_equal(DogTag:Evaluate("[CheckAnyTuple(1, 'Hello', nil)]"), "number:1;string:Hello;nil:nil")
GlobalCheck_data = 'Hello'
GlobalCheckBoolean_data = false
assert_equal(DogTag:Evaluate("[CheckAnyTuple(One, GlobalCheck, GlobalCheckBoolean)]"), "number:1;string:Hello;nil:nil")
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[CheckAnyTuple(One, GlobalCheck, GlobalCheckBoolean)]"), "number:1;string:Hello;string:True")

assert_equal(DogTag:Evaluate("[Reverse('Hello')]"), "olleH")
assert_equal(DogTag:Evaluate("[Reverse('Hello'):Reverse]"), "Hello")
assert_equal(DogTag:Evaluate("[OtherReverse('Hello')]"), "olleH")
assert_equal(DogTag:Evaluate("[OtherReverse('Hello'):OtherReverse]"), "Hello")

old_DogTag_Evaluate(DogTag, "", nil, { left = 0, right = 0 })

assert_equal(DogTag:Evaluate("[Subtract]", nil, { left = 2, right = 1 }), 1)
assert_equal(DogTag:Evaluate("[Subtract]", nil, { left = 1, right = 2 }), -1)

old_DogTag_Evaluate(DogTag, "", nil, { number = 5 })

assert_equal(DogTag:Evaluate("[PlusOne]", nil, { number = 5 }), 6)
assert_equal(DogTag:Evaluate("[PlusOne]", nil, { number = 6 }), 7)
assert_equal(DogTag:Evaluate("[PlusOne]", nil, { number = 7 }), 8)

assert_equal(DogTag:Evaluate("[KwargAndTuple]"), [=[Arg #1 (value) req'd for KwargAndTuple]=])
assert_equal(DogTag:Evaluate("[KwargAndTuple(5, 1, 2, 3)]"), 30)
assert_equal(DogTag:Evaluate("[KwargAndTuple(0.5, 2, 3, 4)]"), 4.5)

assert_equal(DogTag:Evaluate("[TupleAndKwarg]"), [=[Keyword-Arg value req'd for TupleAndKwarg]=])
assert_equal(DogTag:Evaluate("[TupleAndKwarg(2, 3, 4, value=1/4)]"), 9/4)
assert_equal(DogTag:Evaluate("[TupleAndKwarg(2, 3, 4, value=0.5)]"), 9/2)

assert_equal(parse([=[['Alpha\'Bravo']]=]), {"'", "Alpha'Bravo"})
assert_equal(parse([=[["Alpha\"Bravo"]]=]), {'"', 'Alpha"Bravo'})
assert_equal(parse([=[['Alpha\'Bravo"Charlie']]=]), {"'", "Alpha'Bravo\"Charlie"})
assert_equal(parse([=[["Alpha\"Bravo'Charlie"]]=]), {'"', 'Alpha"Bravo\'Charlie'})
assert_equal(parse([=[["\1alpha"]]=]), {'"', '\001alpha' })
assert_equal(parse([=[["\12alpha"]]=]), {'"', '\012alpha' })
assert_equal(parse([=[["\123alpha"]]=]), {'"', '\123alpha' })
assert_equal(parse([=[["\124cffff0000"]]=]), {'"', '|cffff0000' })
assert_equal(parse([=[["\124\124cffff0000"]]=]), {'"', '||cffff0000' })
assert_equal(parse([=[["\123456"]]=]), {'"', '\123' .. '456' })

assert_equal(parse([=[[Func('Alpha\'Bravo')]]=]), { "tag", "Func", {"'", "Alpha'Bravo"} })
assert_equal(parse([=[[Func("Alpha\"Bravo")]]=]), { "tag", "Func", {'"', 'Alpha"Bravo'} })
assert_equal(parse([=[[Func('Alpha\'Bravo"Charlie')]]=]), { "tag", "Func", {"'", "Alpha'Bravo\"Charlie"} })
assert_equal(parse([=[[Func("Alpha\"Bravo'Charlie")]]=]), { "tag", "Func", {'"', 'Alpha"Bravo\'Charlie'} })
assert_equal(parse([=[[Func("\124cffff0000")]]=]), { "tag", "Func", {'"', '|cffff0000'} })
assert_equal(parse([=[[Func("\124\124cffff0000")]]=]), { "tag", "Func", {'"', '||cffff0000'} })
assert_equal(parse([=[[Func("\123456")]]=]), { "tag", "Func", {'"', '\123' .. '456'} })
assert_equal(parse([=[[Func("hey\nthere")]]=]), { "tag", "Func", {'"', 'hey\nthere' }})

assert_equal(DogTag:CleanCode([=[['Alpha\'Bravo']]=]), "Alpha'Bravo")
assert_equal(DogTag:CleanCode([=[["Alpha\"Bravo"]]=]), 'Alpha"Bravo')
assert_equal(DogTag:CleanCode([=[['Alpha\'Bravo"Charlie']]=]), "Alpha'Bravo\"Charlie")
assert_equal(DogTag:CleanCode([=[["Alpha\"Bravo'Charlie"]]=]), 'Alpha"Bravo\'Charlie')
assert_equal(DogTag:CleanCode([=[["\124cffff0000"]]=]), '|cffff0000')
assert_equal(DogTag:CleanCode([=[["\124\124cffff0000"]]=]), '||cffff0000')
assert_equal(DogTag:CleanCode([=[["\123456"]]=]), '\123' .. '456')
assert_equal(DogTag:CleanCode([=[["hey\nthere"]]=]), 'hey\nthere')

assert_equal(DogTag:CleanCode([=[[Func('Alpha\'Bravo')]]=]), [=[[Func("Alpha'Bravo")]]=])
assert_equal(DogTag:CleanCode([=[[Func("Alpha\"Bravo")]]=]), [=[[Func('Alpha"Bravo')]]=])
assert_equal(DogTag:CleanCode([=[[Func('Alpha\'Bravo"Charlie')]]=]), [=[[Func('Alpha\'Bravo"Charlie')]]=])
assert_equal(DogTag:CleanCode([=[[Func("Alpha\"Bravo'Charlie")]]=]), [=[[Func("Alpha\"Bravo'Charlie")]]=])
assert_equal(DogTag:CleanCode([=[[Func("\124cffff0000")]]=]), [=[[Func("\124cffff0000")]]=])
assert_equal(DogTag:CleanCode([=[[Func("\124\124cffff0000")]]=]), [=[[Func("||cffff0000")]]=])
assert_equal(DogTag:CleanCode([=[[Func('\124cffff0000')]]=]), [=[[Func('\124cffff0000')]]=])
assert_equal(DogTag:CleanCode([=[[Func('\124\124cffff0000')]]=]), [=[[Func('||cffff0000')]]=])
assert_equal(DogTag:CleanCode([=[[Func("\123456")]]=]), [=[[Func("{456")]]=])
assert_equal(DogTag:CleanCode([=[[Func('\123456')]]=]), [=[[Func('{456')]]=])
assert_equal(DogTag:CleanCode([=[[Func('hey\nthere')]]=]), [=[[Func('hey\nthere')]]=])

assert_equal(DogTag:CleanCode([=[[Alpha][Text]]=]), [=[[Alpha][Text]]=])
assert_equal(DogTag:CleanCode([=[[Outline][Text]]=]), [=[[Outline][Text]]=])
assert_equal(DogTag:CleanCode([=[[ThickOutline][Text]]=]), [=[[ThickOutline][Text]]=])
assert_equal(DogTag:CleanCode([=[[Alpha][Text][Text]]=]), [=[[Alpha][Text Text]]=])
assert_equal(DogTag:CleanCode([=[[Outline][Text][Text]]=]), [=[[Outline][Text Text]]=])
assert_equal(DogTag:CleanCode([=[[ThickOutline][Text][Text]]=]), [=[[ThickOutline][Text Text]]=])

assert_equal(DogTag:CleanCode([=[[One?Two!Three]]=]), [=[[One ? Two ! Three]]=])
assert_equal(DogTag:CleanCode([=[[One&Two&Three]]=]), [=[[One & Two & Three]]=])
assert_equal(DogTag:CleanCode([=[[One and Two and Three]]=]), [=[[One and Two and Three]]=])
assert_equal(DogTag:CleanCode([=[[One||Two||Three]]=]), [=[[One || Two || Three]]=])
assert_equal(DogTag:CleanCode([=[[One|Two|Three]]=]), [=[[One || Two || Three]]=])
assert_equal(DogTag:CleanCode([=[[One or Two or Three]]=]), [=[[One or Two or Three]]=])
assert_equal(DogTag:CleanCode([=[[One&Two||Three]]=]), [=[[(One & Two) || Three]]=])
assert_equal(DogTag:CleanCode([=[[One and Two or Three]]=]), [=[[(One and Two) or Three]]=])
assert_equal(DogTag:CleanCode([=[[One||Two&Three]]=]), [=[[(One || Two) & Three]]=])
assert_equal(DogTag:CleanCode([=[[One or Two and Three]]=]), [=[[(One or Two) and Three]]=])

assert_equal(DogTag:CleanCode([=[[One or Two and Three]]=]), [=[[(One or Two) and Three]]=])

assert_equal(DogTag:Evaluate("[Type(nil)]"), "nil")
assert_equal(DogTag:Evaluate("[Type('Hello')]"), "string")
assert_equal(DogTag:Evaluate("[Type(5)]"), "number")
assert_equal(DogTag:Evaluate("[Type(false)]"), "nil")
assert_equal(DogTag:Evaluate("[Type(true)]"), "string")
assert_equal(DogTag:Evaluate("[Type(nil nil)]"), "nil")
assert_equal(DogTag:Evaluate("[Type(5 10)]"), "number")
assert_equal(DogTag:Evaluate("[Type(5.5 10.5)]"), "string")

-- first argument is number, despite it returning a string, it should try to coerce to number
assert_equal(DogTag:Evaluate("[Type(5:Short)]"), "number")
assert_equal(DogTag:Evaluate("[Type(5:Concatenate(0))]"), "number")

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "nil")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "string")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "number")

assert_equal(DogTag:Evaluate("[ToString(nil)]"), "``")
assert_equal(DogTag:Evaluate("[ToString('Hello')]"), "`Hello`")
assert_equal(DogTag:Evaluate("[ToString(5)]"), "`5`")
assert_equal(DogTag:Evaluate("[ToString(false)]"), "``")
assert_equal(DogTag:Evaluate("[ToString(true)]"), "`True`")

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[ToString(GlobalCheck)]"), "``")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[ToString(GlobalCheck)]"), "`Hello`")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[ToString(GlobalCheck)]"), "`5`")

assert_equal(DogTag:Evaluate("[RetSame(nil)]"), nil)
assert_equal(RetSame_types, "nil")
assert_equal(DogTag:Evaluate("[RetSame('Hello')]"), "Hello")
assert_equal(RetSame_types, "string")
assert_equal(DogTag:Evaluate("[RetSame(5)]"), 5)
assert_equal(RetSame_types, "number")
assert_equal(DogTag:Evaluate("[RetSame(false)]"), nil)
assert_equal(RetSame_types, "nil")
assert_equal(DogTag:Evaluate("[RetSame(true)]"), "True")
assert_equal(RetSame_types, "string")

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[RetSame(GlobalCheck)]"), nil)
assert_equal(RetSame_types, "nil;number;string")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[RetSame(GlobalCheck)]"), "Hello")
assert_equal(RetSame_types, "nil;number;string")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[RetSame(GlobalCheck)]"), 5)
assert_equal(RetSame_types, "nil;number;string")

assert_equal(DogTag:Evaluate("[RetSame(One)]"), 1)
assert_equal(RetSame_types, "number")
assert_equal(DogTag:Evaluate("[RetSame(CheckNilDefault(5))]"), 5)
assert_equal(RetSame_types, "nil;number")
assert_equal(DogTag:Evaluate("[RetSame(CheckNilDefault)]"), nil)
assert_equal(RetSame_types, "nil;number")

assert_equal(DogTag:Evaluate("[DynamicCodeTest(nil)]"), "literal, nil")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(5)]"), "literal, 5")
assert_equal(DogTag:Evaluate("[DynamicCodeTest('Hello')]"), "literal, Hello")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(false)]"), "literal, nil")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(true)]"), "literal, True")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(One)]"), "dynamic, One")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(GlobalCheck)]"), "dynamic, GlobalCheck")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(1 + One)]"), "dynamic, +")

local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[BlizzEventTest('player')]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[BlizzEventTest('player')]", func)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'player', 'focus')
assert_equal(fired, true)
fired = false
DogTag.clearCodes()
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
DogTag:RemoveCallback("[BlizzEventTest('player')]", func)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)

local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[BlizzEventTest]")
	assert_equal(kwargs, { value = "player" })
	fired = true
end
DogTag:AddCallback("[BlizzEventTest]", func, nil, { value = "player" })
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
DogTag.clearCodes("Base")
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'player', 'focus')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
DogTag:RemoveCallback("[BlizzEventTest]", func, nil, { value = "player" })
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)

local fired = false
local func; func = function(extra, code, nsList, kwargs)
	assert_equal(extra, "Hello")
	assert_equal(code, "[OtherBlizzEventTest]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[OtherBlizzEventTest]", func, nil, nil, "Hello")
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
DogTag:RemoveCallback("[OtherBlizzEventTest]", func, nil, nil, "Hello")
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)

local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[BlizzEventTest(GlobalCheck)]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[BlizzEventTest(GlobalCheck)]", func)
GlobalCheck_data = 'player'
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
GlobalCheck_data = 'pet'
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)
DogTag:RemoveCallback("[BlizzEventTest(GlobalCheck)]", func)
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)

local f = CreateFrame("Frame")
local fs = f:CreateFontString(nil, "ARTWORK")
assert_equal(fs:GetText(), nil)
DogTag:AddFontString(fs, f, "[One]")
assert_equal(fs:GetText(), 1)
DogTag:RemoveFontString(fs)
assert_equal(fs:GetText(), nil)

FireOnUpdate(1000)

OtherBlizzEventTest_num = 1
DogTag:AddFontString(fs, f, "[OtherBlizzEventTest]")
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(0)
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(0.04)
assert_equal(fs:GetText(), 3)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 4)
FireOnUpdate(0.01)
assert_equal(fs:GetText(), 4)
DogTag.clearCodes("Base")
FireOnUpdate(0)
assert_equal(fs:GetText(), 5)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 6)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 7)

BlizzEventTest_num = 1
GlobalCheck_data = 'player'
DogTag:AddFontString(fs, f, "[BlizzEventTest(GlobalCheck)]")
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("FAKE_BLIZZARD_EVENT", "player")
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireEvent("FAKE_BLIZZARD_EVENT", "pet")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 4)
GlobalCheck_data = 'pet'
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 4)
FireEvent("FAKE_BLIZZARD_EVENT", "pet")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 5)
GlobalCheck_data = 'player'
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 6)

BlizzEventTest_num = 1
DogTag:AddFontString(fs, f, "[BlizzEventTest]", nil, { value = 'player' })
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("FAKE_BLIZZARD_EVENT", "player")
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireEvent("FAKE_BLIZZARD_EVENT", "pet")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 4)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 4)


local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[DoubleBlizzEventTest]")
	assert_equal(kwargs, { alpha = "player", bravo = "pet" })
	fired = true
end
DogTag:AddCallback("[DoubleBlizzEventTest]", func, nil, { alpha = "player", bravo = "pet" })
FireEvent("DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
FireEvent("DOUBLE_BLIZZARD_EVENT", 'focus')
assert_equal(fired, false)
FireEvent("DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
DogTag.clearCodes("Base")
FireEvent("DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
FireEvent("DOUBLE_BLIZZARD_EVENT", 'focus')
assert_equal(fired, false)
FireEvent("DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
DogTag:RemoveCallback("[DoubleBlizzEventTest]", func, nil, { alpha = "player", bravo = "pet" })
FireEvent("DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)
FireEvent("DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)

FireOnUpdate(1000)

DoubleBlizzEventTest_num = 0
DogTag:AddFontString(fs, f, "[DoubleBlizzEventTest]", nil, { alpha = "pet", bravo = "player" })
assert_equal(fs:GetText(), 1)
FireEvent("DOUBLE_BLIZZARD_EVENT", "player")
FireOnUpdate(0)
assert_equal(fs:GetText(), 1)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
FireEvent("DOUBLE_BLIZZARD_EVENT", "pet")
FireOnUpdate(0.04)
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(0.01)
assert_equal(fs:GetText(), 3)
FireEvent("DOUBLE_BLIZZARD_EVENT", "focus")
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)


local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[OtherDoubleBlizzEventTest]")
	assert_equal(kwargs, { alpha = "player", bravo = "pet" })
	fired = true
end
DogTag:AddCallback("[OtherDoubleBlizzEventTest]", func, nil, { alpha = "player", bravo = "pet" })
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'player', 'something')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet', 'something')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'something', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'something', 'player', 'pet')
assert_equal(fired, false)
DogTag:RemoveCallback("[OtherDoubleBlizzEventTest]", func, nil, { alpha = "player", bravo = "pet" })
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet')
assert_equal(fired, false)



local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[OtherDoubleBlizzEventTest(alpha='player', bravo='pet')]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[OtherDoubleBlizzEventTest(alpha='player', bravo='pet')]", func)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'player', 'something')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet', 'something')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'something', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'something', 'player', 'pet')
assert_equal(fired, false)
DogTag:RemoveCallback("[OtherDoubleBlizzEventTest(alpha='player', bravo='pet')]", func)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet')
assert_equal(fired, false)



local fired = false
local function func(code, nsList, kwargs)
	assert_equal(code, "[OtherDoubleBlizzEventTest(alpha='player', bravo='pet')] [OtherDoubleBlizzEventTest(alpha='focus', bravo='target')]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[OtherDoubleBlizzEventTest(alpha='player', bravo='pet')] [OtherDoubleBlizzEventTest(alpha='focus', bravo='target')]", func)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'player')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'pet', 'player', 'something')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet', 'something')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'something', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'something', 'player', 'pet')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'focus')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'target')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'focus', 'focus')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'target', 'target')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'focus', 'target')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'target', 'focus')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'target', 'focus', 'something')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'focus', 'target', 'something')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'focus', 'something', 'target')
assert_equal(fired, false)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'something', 'focus', 'target')
assert_equal(fired, false)
DogTag:RemoveCallback("[OtherDoubleBlizzEventTest(alpha='player', bravo='pet')] [OtherDoubleBlizzEventTest(alpha='focus', bravo='target')]", func)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", 'player', 'pet')
assert_equal(fired, false)



OtherDoubleBlizzEventTest_num = 0
DogTag:AddFontString(fs, f, "[OtherDoubleBlizzEventTest]", nil, { alpha = "pet", bravo = "player" })
assert_equal(fs:GetText(), 1)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", "player")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", "pet")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", "player", "pet")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", "pet", "player")
FireOnUpdate(0)
assert_equal(fs:GetText(), 1)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", "player", "pet")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_DOUBLE_BLIZZARD_EVENT", "pet", "player")
FireOnUpdate(0)
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)

-- Test Math module
assert_equal(DogTag:Evaluate("[Round(0)]"), 0)
assert_equal(DogTag:Evaluate("[Round(0.5)]"), 0)
assert_equal(DogTag:Evaluate("[Round(0.500001)]"), 1)
assert_equal(DogTag:Evaluate("[Round(1)]"), 1)
assert_equal(DogTag:Evaluate("[Round(1.499999)]"), 1)
assert_equal(DogTag:Evaluate("[Round(1.5)]"), 2)

assert_equal(DogTag:Evaluate("[Floor(-0.0000000001)]"), -1)
assert_equal(DogTag:Evaluate("[Floor(0)]"), 0)
assert_equal(DogTag:Evaluate("[Floor(0.9999999999)]"), 0)
assert_equal(DogTag:Evaluate("[Floor(1)]"), 1)

assert_equal(DogTag:Evaluate("[Ceil(-0.9999999999)]"), 0)
assert_equal(DogTag:Evaluate("[Ceil(0)]"), 0)
assert_equal(DogTag:Evaluate("[Ceil(0.0000000001)]"), 1)
assert_equal(DogTag:Evaluate("[Ceil(1)]"), 1)

assert_equal(DogTag:Evaluate("[Abs(-5)]"), 5)
assert_equal(DogTag:Evaluate("[Abs(5)]"), 5)
assert_equal(DogTag:Evaluate("[Abs(0)]"), 0)

assert_equal(DogTag:Evaluate("[Sign(-5)]"), -1)
assert_equal(DogTag:Evaluate("[Sign(5)]"), 1)
assert_equal(DogTag:Evaluate("[Sign(0)]"), 0)

assert_equal(DogTag:Evaluate("[Max(1)]"), 1)
assert_equal(DogTag:Evaluate("[Max(1, 3, 4, 2)]"), 4)

assert_equal(DogTag:Evaluate("[Min(1)]"), 1)
assert_equal(DogTag:Evaluate("[Min(5, 3, 4, 2)]"), 2)

assert_equal(DogTag:Evaluate("[Pi]"), math.pi)

assert_equal(DogTag:Evaluate("[0:Deg]"), 0)
assert_equal(DogTag:Evaluate("[Deg(Pi/2)]"), 90)
assert_equal(DogTag:Evaluate("[Pi:Deg]"), 180)

assert_equal(DogTag:Evaluate("[0:Rad]"), 0)
assert_equal(DogTag:Evaluate("[90:Rad]"), math.pi/2)
assert_equal(DogTag:Evaluate("[180:Rad]"), math.pi)

assert_equal(DogTag:Evaluate("[0:Cos]"), 1)
assert_equal(DogTag:Evaluate("[(Pi/4):Cos]"), 0.5^0.5)
assert_equal(DogTag:Evaluate("[(Pi/2):Cos]"), 0)

assert_equal(DogTag:Evaluate("[0:Sin]"), 0)
assert_equal(DogTag:Evaluate("[(Pi/4):Sin]"), 0.5^0.5)
assert_equal(DogTag:Evaluate("[(Pi/2):Sin]"), 1)

assert_equal(DogTag:Evaluate("[E]"), math.exp(1))

assert_equal(DogTag:Evaluate("[1:Ln]"), 0)
assert_equal(DogTag:Evaluate("[E:Ln]"), 1)
assert_equal(DogTag:Evaluate("[[E^2]:Ln]"), 2)

assert_equal(DogTag:Evaluate("[1:Log]"), 0)
assert_equal(DogTag:Evaluate("[10:Log]"), 1)
assert_equal(DogTag:Evaluate("[100:Log]"), 2)

assert_equal(DogTag:Evaluate("[100:Percent]"), "100%")
assert_equal(DogTag:Evaluate("[50:Percent]"), "50%")
assert_equal(DogTag:Evaluate("[0:Percent]"), "0%")

assert_equal(DogTag:Evaluate("[100:Short]"), 100)
assert_equal(DogTag:Evaluate("[1000:Short]"), 1000)
assert_equal(DogTag:Evaluate("[10000:Short]"), '10.0k')
assert_equal(DogTag:Evaluate("[100000:Short]"), '100k')
assert_equal(DogTag:Evaluate("[1000000:Short]"), '1.00m')
assert_equal(DogTag:Evaluate("[10000000:Short]"), '10.0m')
assert_equal(DogTag:Evaluate("[100000000:Short]"), '100.0m')
assert_equal(DogTag:Evaluate("[-100:Short]"), -100)
assert_equal(DogTag:Evaluate("[-1000:Short]"), -1000)
assert_equal(DogTag:Evaluate("[-10000:Short]"), '-10.0k')
assert_equal(DogTag:Evaluate("[-100000:Short]"), '-100k')
assert_equal(DogTag:Evaluate("[-1000000:Short]"), '-1.00m')
assert_equal(DogTag:Evaluate("[-10000000:Short]"), '-10.0m')
assert_equal(DogTag:Evaluate("[-100000000:Short]"), '-100.0m')

assert_equal(DogTag:Evaluate("['100/1000':Short]"), '100/1000')
assert_equal(DogTag:Evaluate("['1000/10000':Short]"), '1000/10.0k')
assert_equal(DogTag:Evaluate("['10000/100000':Short]"), '10.0k/100k')
assert_equal(DogTag:Evaluate("['100000/1000000':Short]"), '100k/1.00m')
assert_equal(DogTag:Evaluate("['1000000/10000000':Short]"), '1.00m/10.0m')
assert_equal(DogTag:Evaluate("['10000000/100000000':Short]"), '10.0m/100.0m')

assert_equal(DogTag:Evaluate("[100:VeryShort]"), 100)
assert_equal(DogTag:Evaluate("[1000:VeryShort]"), '1k')
assert_equal(DogTag:Evaluate("[10000:VeryShort]"), '10k')
assert_equal(DogTag:Evaluate("[100000:VeryShort]"), '100k')
assert_equal(DogTag:Evaluate("[1000000:VeryShort]"), '1m')
assert_equal(DogTag:Evaluate("[10000000:VeryShort]"), '10m')
assert_equal(DogTag:Evaluate("[100000000:VeryShort]"), '100m')
assert_equal(DogTag:Evaluate("[-100:VeryShort]"), -100)
assert_equal(DogTag:Evaluate("[-1000:VeryShort]"), '-1k')
assert_equal(DogTag:Evaluate("[-10000:VeryShort]"), '-10k')
assert_equal(DogTag:Evaluate("[-100000:VeryShort]"), '-100k')
assert_equal(DogTag:Evaluate("[-1000000:VeryShort]"), '-1m')
assert_equal(DogTag:Evaluate("[-10000000:VeryShort]"), '-10m')
assert_equal(DogTag:Evaluate("[-100000000:VeryShort]"), '-100m')

assert_equal(DogTag:Evaluate("['100/1000':VeryShort]"), '100/1k')
assert_equal(DogTag:Evaluate("['1000/10000':VeryShort]"), '1k/10k')
assert_equal(DogTag:Evaluate("['10000/100000':VeryShort]"), '10k/100k')
assert_equal(DogTag:Evaluate("['100000/1000000':VeryShort]"), '100k/1m')
assert_equal(DogTag:Evaluate("['1000000/10000000':VeryShort]"), '1m/10m')
assert_equal(DogTag:Evaluate("['10000000/100000000':VeryShort]"), '10m/100m')

assert_equal(DogTag:Evaluate("['Hello':Upper]"), 'HELLO')
assert_equal(DogTag:Evaluate("['Hello':Lower]"), 'hello')

assert_equal(DogTag:Evaluate("['Hello':Bracket]"), '[Hello]')
assert_equal(DogTag:Evaluate("['Hello':Angle]"), '<Hello>')
assert_equal(DogTag:Evaluate("['Hello':Brace]"), '{Hello}')
assert_equal(DogTag:Evaluate("['Hello':Paren]"), '(Hello)')

assert_equal(DogTag:Evaluate("['Hello':Truncate(3)]"), 'Hel...')
assert_equal(DogTag:Evaluate("['Über':Truncate(3)]"), 'Übe...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4)]"), 'Hell...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4, true)]"), 'Hell...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4, ellipses=true)]"), 'Hell...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(5)]"), 'Hello')
assert_equal(DogTag:Evaluate("['Hello':Truncate(3, ellipses=nil)]"), 'Hel')
assert_equal(DogTag:Evaluate("['Hello':Truncate(3, ellipses=false)]"), 'Hel')
assert_equal(DogTag:Evaluate("['Über':Truncate(3, nil)]"), 'Übe')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4, nil)]"), 'Hell')
assert_equal(DogTag:Evaluate("['Hello':Truncate(5, ellipses=nil)]"), 'Hello')

assert_equal(DogTag:Evaluate("['Hello':Substring(3)]"), 'llo')
assert_equal(DogTag:Evaluate("['Über':Substring(3)]"), 'er')
assert_equal(DogTag:Evaluate("['Hello':Substring(2, 4)]"), 'ell')
assert_equal(DogTag:Evaluate("['Hello':Substring(2, 2)]"), 'e')
assert_equal(DogTag:Evaluate("['Über':Substring(2, 3)]"), 'be')
assert_equal(DogTag:Evaluate("['Über':Substring(3, 2)]"), nil)
assert_equal(DogTag:Evaluate("['Hello':Substring(-2)]"), 'lo')
assert_equal(DogTag:Evaluate("['Hello':Substring(-5)]"), 'Hello')
assert_equal(DogTag:Evaluate("['Hello':Substring(-10)]"), 'Hello')
assert_equal(DogTag:Evaluate("['Hello':Substring(-3, -2)]"), 'll')
assert_equal(DogTag:Evaluate("['Hello':Substring(2, -2)]"), 'ell')
assert_equal(DogTag:Evaluate("['Über':Substring(-2)]"), 'er')
assert_equal(DogTag:Evaluate("['Über':Substring(-4)]"), 'Über')
assert_equal(DogTag:Evaluate("['Über':Substring(-5)]"), 'Über')
assert_equal(DogTag:Evaluate("['Über':Substring(-3, -2)]"), 'be')
assert_equal(DogTag:Evaluate("['Über':Substring(2, -2)]"), 'be')

assert_equal(DogTag:Evaluate("['Hello':Repeat(0)]"), nil)
assert_equal(DogTag:Evaluate("['Hello':Repeat(1)]"), 'Hello')
assert_equal(DogTag:Evaluate("['Hello':Repeat(2)]"), 'HelloHello')
assert_equal(DogTag:Evaluate("['Hello':Repeat(2.5)]"), 'HelloHello')

assert_equal(DogTag:Evaluate("['Hello':Length]"), 5)
assert_equal(DogTag:Evaluate("['Über':Length]"), 4)

assert_equal(DogTag:Evaluate("[0:Romanize]"), "N")
assert_equal(DogTag:Evaluate("[1:Romanize]"), "I")
assert_equal(DogTag:Evaluate("[4:Romanize]"), "IV")
assert_equal(DogTag:Evaluate("[500:Romanize]"), "D")
assert_equal(DogTag:Evaluate("[1666:Romanize]"), "MDCLXVI")
assert_equal(DogTag:Evaluate("[1666666:Romanize]"), "(MDCLXV)MDCLXVI")
assert_equal(DogTag:Evaluate("[4999999:Romanize]"), "(MMMMCMXCIX)CMXCIX")
assert_equal(DogTag:Evaluate("[-1:Romanize]"), "-I")
assert_equal(DogTag:Evaluate("[-4:Romanize]"), "-IV")
assert_equal(DogTag:Evaluate("[-500:Romanize]"), "-D")
assert_equal(DogTag:Evaluate("[-1666:Romanize]"), "-MDCLXVI")
assert_equal(DogTag:Evaluate("[-1666666:Romanize]"), "-(MDCLXV)MDCLXVI")
assert_equal(DogTag:Evaluate("[-4999999:Romanize]"), "-(MMMMCMXCIX)CMXCIX")

assert_equal(DogTag:Evaluate("['%.3f':Format(1)]"), "1.000")
assert_equal(DogTag:Evaluate("['%03d':Format(1)]"), "001")
assert_equal(DogTag:Evaluate("['%.0f':Format(1.1234)]"), 1)
assert_equal(DogTag:Evaluate("['%s %s':Format('Hello', 'World')]"), "Hello World")
assert_equal(DogTag:Evaluate("['%d %d':Format('Hello', 'World')]"), "bad argument #2 to '?' (number expected, got string)")
assert_equal(DogTag:Evaluate("['%q %q':Format('Hello', 'World')]"), '"Hello" "World"')
assert_equal(DogTag:Evaluate("['%q %q %q':Format('Hello', 'World')]"), "bad argument #4 to '?' (string expected, got no value)")
assert_equal(DogTag:Evaluate("['%.1f':Format(CheckNilDefault(5))]"), "5.0")

assert_equal(DogTag:Evaluate("[0:FormatDuration('e')]"), "0 Sec")
assert_equal(DogTag:Evaluate("[0:FormatDuration('f')]"), "0s")
assert_equal(DogTag:Evaluate("[0:FormatDuration('s')]"), "0.0 Sec")
assert_equal(DogTag:Evaluate("[0:FormatDuration('c')]"), "0:00")
assert_equal(DogTag:Evaluate("[1:FormatDuration('e')]"), "1 Sec")
assert_equal(DogTag:Evaluate("[1:FormatDuration('f')]"), "1s")
assert_equal(DogTag:Evaluate("[1:FormatDuration('s')]"), "1.0 Sec")
assert_equal(DogTag:Evaluate("[1:FormatDuration('c')]"), '0:01')
assert_equal(DogTag:Evaluate("[10:FormatDuration('e')]"), "10 Sec")
assert_equal(DogTag:Evaluate("[10:FormatDuration('f')]"), "10s")
assert_equal(DogTag:Evaluate("[10:FormatDuration('s')]"), "10 Sec")
assert_equal(DogTag:Evaluate("[10:FormatDuration('c')]"), "0:10")
assert_equal(DogTag:Evaluate("[60:FormatDuration('e')]"), "1 Min")
assert_equal(DogTag:Evaluate("[60:FormatDuration('f')]"), "1m 00s")
assert_equal(DogTag:Evaluate("[60:FormatDuration('s')]"), "60 Sec")
assert_equal(DogTag:Evaluate("[60:FormatDuration('c')]"), "1:00")
assert_equal(DogTag:Evaluate("[100:FormatDuration('e')]"), "1 Min 40 Sec")
assert_equal(DogTag:Evaluate("[100:FormatDuration('f')]"), "1m 40s")
assert_equal(DogTag:Evaluate("[100:FormatDuration('s')]"), "100 Sec")
assert_equal(DogTag:Evaluate("[100:FormatDuration('c')]"), "1:40")
assert_equal(DogTag:Evaluate("[1000:FormatDuration('e')]"), "16 Min 40 Sec")
assert_equal(DogTag:Evaluate("[1000:FormatDuration('f')]"), "16m 40s")
assert_equal(DogTag:Evaluate("[1000:FormatDuration('s')]"), "16.7 Min")
assert_equal(DogTag:Evaluate("[1000:FormatDuration('c')]"), "16:40")
assert_equal(DogTag:Evaluate("[3600:FormatDuration('e')]"), "1 Hr")
assert_equal(DogTag:Evaluate("[3600:FormatDuration('f')]"), "1h 00m 00s")
assert_equal(DogTag:Evaluate("[3600:FormatDuration('s')]"), "60.0 Min")
assert_equal(DogTag:Evaluate("[3600:FormatDuration('c')]"), "1:00:00")
assert_equal(DogTag:Evaluate("[10000:FormatDuration('e')]"), "2 Hr 46 Min 40 Sec")
assert_equal(DogTag:Evaluate("[10000:FormatDuration('f')]"), "2h 46m 40s")
assert_equal(DogTag:Evaluate("[10000:FormatDuration('s')]"), "2.8 Hr")
assert_equal(DogTag:Evaluate("[10000:FormatDuration('c')]"), "2:46:40")
assert_equal(DogTag:Evaluate("[86400:FormatDuration('e')]"), "1 Days")
assert_equal(DogTag:Evaluate("[86400:FormatDuration('f')]"), "1d 00h 00m 00s")
assert_equal(DogTag:Evaluate("[86400:FormatDuration('s')]"), "24.0 Hr")
assert_equal(DogTag:Evaluate("[86400:FormatDuration('c')]"), "1d 0:00:00")
assert_equal(DogTag:Evaluate("[100000:FormatDuration('e')]"), "1 Days 3 Hr 46 Min 40 Sec")
assert_equal(DogTag:Evaluate("[100000:FormatDuration('f')]"), "1d 03h 46m 40s")
assert_equal(DogTag:Evaluate("[100000:FormatDuration('s')]"), "27.8 Hr")
assert_equal(DogTag:Evaluate("[100000:FormatDuration('c')]"), "1d 3:46:40")
assert_equal(DogTag:Evaluate("[1000000:FormatDuration('e')]"), "11 Days 13 Hr 46 Min 40 Sec")
assert_equal(DogTag:Evaluate("[1000000:FormatDuration('f')]"), "11d 13h 46m 40s")
assert_equal(DogTag:Evaluate("[1000000:FormatDuration('s')]"), "11.6 Days")
assert_equal(DogTag:Evaluate("[1000000:FormatDuration('c')]"), "11d 13:46:40")
assert_equal(DogTag:Evaluate("[100000000:FormatDuration('e')]"), "1157 Days 9 Hr 46 Min 40 Sec")
assert_equal(DogTag:Evaluate("[100000000:FormatDuration('f')]"), "1157d 09h 46m 40s")
assert_equal(DogTag:Evaluate("[100000000:FormatDuration('s')]"), "1157.4 Days")
assert_equal(DogTag:Evaluate("[100000000:FormatDuration('c')]"), "1157d 9:46:40")
assert_equal(DogTag:Evaluate("[100000000000:FormatDuration('e')]"), "1157407 Days 9 Hr 46 Min 40 Sec")
assert_equal(DogTag:Evaluate("[100000000000:FormatDuration('f')]"), "1157407d 09h 46m 40s")
assert_equal(DogTag:Evaluate("[100000000000:FormatDuration('s')]"), "1157407.4 Days")
assert_equal(DogTag:Evaluate("[100000000000:FormatDuration('c')]"), "1157407d 9:46:40")

assert_equal(DogTag:Evaluate("['Hello':Concatenate(' World')]"), "Hello World")
assert_equal(DogTag:Evaluate("['Hello':Concatenate(nil, ' World')]"), nil)
assert_equal(DogTag:Evaluate("[nil:Concatenate(' World')]"), nil)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck:Concatenate(' World')]"), nil)
assert_equal(DogTag:Evaluate("[Concatenate(false, ' World')]"), nil)
assert_equal(DogTag:Evaluate("[Concatenate('Hello', nil)]"), nil)

assert_equal(DogTag:Evaluate("[Append('Hello', ' There')]"), "Hello There")
assert_equal(DogTag:Evaluate("[Prepend('There', 'Hello ')]"), "Hello There")
assert_equal(DogTag:Evaluate("[Append('Hello', nil)]"), "Hello")
assert_equal(DogTag:Evaluate("[Prepend('There', nil)]"), "There")

assert_equal(DogTag:Evaluate("[Replace('Hello', 'e', 'u')]"), "Hullo")
assert_equal(DogTag:Evaluate("[Replace('Hello', 'ell', '')]"), "Ho")
assert_equal(DogTag:Evaluate("[Replace('Hello', 'Hello', '')]"), nil)
assert_equal(DogTag:Evaluate("[Replace('Hello there, Hello', 'Hello', 'Stop')]"), "Stop there, Stop")

assert_equal(DogTag:Evaluate("[nil:Length]"), nil)
assert_equal(DogTag:Evaluate("[false:Length]"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheck:Length]"), nil)
assert_equal(DogTag:Evaluate("[true:Length]"), 4)

assert_equal(DogTag:Evaluate("[nil:Short]"), nil)
assert_equal(DogTag:Evaluate("[false:Short]"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheck:Short]"), nil)
assert_equal(DogTag:Evaluate("[nil:Color('ff7f7f')]"), nil)
assert_equal(DogTag:Evaluate("[false:Color('ff7f7f')]"), nil)

assert_equal(DogTag:Evaluate("[BooleanToString(nil)]"), "false")
assert_equal(DogTag:Evaluate("[BooleanToString(false)]"), "false")
assert_equal(DogTag:Evaluate("[BooleanToString(true)]"), "true")
assert_equal(DogTag:Evaluate("[BooleanToString('Hello')]"), "true")
assert_equal(DogTag:Evaluate("[BooleanToString(5)]"), "true")
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[BooleanToString(GlobalCheck)]"), "false")
GlobalCheck_data = 'Hello'
assert_equal(DogTag:Evaluate("[BooleanToString(GlobalCheck)]"), "true")

GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean]"), "True")
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean & 'Hello']"), "Hello")
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean ? 'Hello']"), "Hello")
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean | 'Hello']"), "True")
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean ? 'Hello' ! 'There']"), "Hello")
GlobalCheckBoolean_data = false
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean]"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean & 'Hello']"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean ? 'Hello']"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean | 'Hello']"), "Hello")
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean ? 'Hello' ! 'There']"), "There")

GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean:PlusOne]"), 2)
GlobalCheckBoolean_data = false
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean:PlusOne]"), nil)
GlobalCheckBoolean_data = true
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean:Concatenate('!')]"), "True!")
GlobalCheckBoolean_data = false
assert_equal(DogTag:Evaluate("[GlobalCheckBoolean:Concatenate('!')]"), nil)

IsAltKeyDown_data = nil
assert_equal(DogTag:Evaluate("[Alt]"), nil)
IsAltKeyDown_data = 1
assert_equal(DogTag:Evaluate("[Alt]"), "True")
IsAltKeyDown_data = nil

IsShiftKeyDown_data = nil
assert_equal(DogTag:Evaluate("[Shift]"), nil)
IsShiftKeyDown_data = 1
assert_equal(DogTag:Evaluate("[Shift]"), "True")
IsShiftKeyDown_data = nil

IsControlKeyDown_data = nil
assert_equal(DogTag:Evaluate("[Ctrl]"), nil)
IsControlKeyDown_data = 1
assert_equal(DogTag:Evaluate("[Ctrl]"), "True")
IsControlKeyDown_data = nil

BlizzEventTest_num = 0
DogTag:AddFontString(fs, f, "[Alt ? BlizzEventTest('never')]")
assert_equal(fs:GetText(), nil)
IsAltKeyDown_data = 1
FireEvent("MODIFIER_STATE_CHANGED", "LALT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 1)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
FireEvent("MODIFIER_STATE_CHANGED", "LSHIFT")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
FireEvent("MODIFIER_STATE_CHANGED", "LCTRL")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
IsAltKeyDown_data = nil
FireEvent("MODIFIER_STATE_CHANGED", "LALT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), nil)
IsAltKeyDown_data = 1
FireEvent("MODIFIER_STATE_CHANGED", "RALT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("MODIFIER_STATE_CHANGED", "RSHIFT")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("MODIFIER_STATE_CHANGED", "RCTRL")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)

local now = GetTime()
FireOnUpdate(1)
assert_equal(DogTag:Evaluate("[CurrentTime]"), now+1)
FireOnUpdate(1)
assert_equal(DogTag:Evaluate("[CurrentTime]"), now+2)

assert_equal(DogTag:Evaluate("[Alpha(1)]"), nil)
assert_equal(select(2, DogTag:Evaluate("[Alpha(1)]")), 1)
assert_equal(select(2, DogTag:Evaluate("[Alpha(0)]")), 0)
assert_equal(select(2, DogTag:Evaluate("[Alpha(0.5)]")), 0.5)
assert_equal(select(2, DogTag:Evaluate("[Alpha(2)]")), 1)
assert_equal(select(2, DogTag:Evaluate("[Alpha(-1)]")), 0)
assert_equal(select(2, DogTag:Evaluate("[One]")), nil)

DogTag:AddFontString(fs, f, "[Alpha(0.5)]")
assert_equal(fs:GetText(), nil)
assert_equal(fs:GetAlpha(), 0.5)
DogTag:RemoveFontString(fs)
fs:SetAlpha(1)

assert_equal(DogTag:Evaluate("[Outline] Hello"), "Hello")
assert_equal(DogTag:Evaluate("[ThickOutline] Hello"), "Hello")
assert_equal(select(3, DogTag:Evaluate("[Outline] Hello")), 'OUTLINE')
assert_equal(select(3, DogTag:Evaluate("Hello")), nil)
assert_equal(select(3, DogTag:Evaluate("[ThickOutline] Hello")), 'OUTLINE, THICKOUTLINE')
assert_equal(select(3, DogTag:Evaluate("Hello")), nil)

assert_equal(DogTag:Evaluate("[Outline(1)]"), "Too many args for Outline")

DogTag:AddFontString(fs, f, "[Outline]")
assert_equal(fs:GetText(), nil)
assert_equal(fs:GetAlpha(), 1)
assert_equal(select(3, fs:GetFont()), "OUTLINE")
DogTag:RemoveFontString(fs)

DogTag:AddFontString(fs, f, "[ThickOutline]")
assert_equal(fs:GetText(), nil)
assert_equal(fs:GetAlpha(), 1)
assert_equal(select(3, fs:GetFont()), "OUTLINE, THICKOUTLINE")
DogTag:RemoveFontString(fs)

DogTag:AddFontString(fs, f, "[IsMouseOver]")
assert_equal(fs:GetText(), nil)
GetMouseFocus_data = f
assert_equal(fs:GetText(), nil)
FireOnUpdate(0)
assert_equal(fs:GetText(), "True")
FireOnUpdate(1000)
assert_equal(fs:GetText(), "True")
GetMouseFocus_data = nil
FireOnUpdate(0)
assert_equal(fs:GetText(), nil)
DogTag:RemoveFontString(fs)

assert_equal(select(3, fs:GetFont()), "")
assert_equal(fs:GetAlpha(), 1)

assert_equal(DogTag:Evaluate("['Hello':Color('ff0000')]"), "|cffff0000Hello|r")
assert_equal(DogTag:Evaluate("['There':Color('00ff00')]"), "|cff00ff00There|r")
assert_equal(DogTag:Evaluate("['Friend':Color(0, 0, 1)]"), "|cff0000ffFriend|r")
assert_equal(DogTag:Evaluate("['Broken':Color('00ff00a')]"), "|cffffffffBroken|r")
assert_equal(DogTag:Evaluate("['Large nums':Color(180, 255, -60)]"), "|cffffff00Large nums|r")

assert_equal(DogTag:Evaluate("[nil:Color('ff0000')]"), nil)
assert_equal(DogTag:Evaluate("[nil:Color(0, 0, 1)]"), nil)
assert_equal(DogTag:Evaluate("[false:Color(0, 0, 1)]"), nil)
assert_equal(DogTag:Evaluate("[true:Color(0, 0, 1)]"), "|cff0000ffTrue|r")

assert_equal(DogTag:Evaluate("[Color]"), "|r")
assert_equal(DogTag:Evaluate("[Color('ff0000')]"), "|cffff0000")
assert_equal(DogTag:Evaluate("[Color('00ff00')]"), "|cff00ff00")
assert_equal(DogTag:Evaluate("[Color(0, 0, 1)]"), "|cff0000ff")
assert_equal(DogTag:Evaluate("[Color(red=0, green=0, blue=1)]"), "|cff0000ff")
assert_equal(DogTag:Evaluate("[Color(nil, red=0, green=0, blue=1)]"), nil)
assert_equal(DogTag:Evaluate("[Color('00ff00a')]"), "|cffffffff")
assert_equal(DogTag:Evaluate("[Color(180, 255, -60)]"), "|cffffff00")

for name, color in pairs({
	White = "ffffff",
	Red = "ff0000",
	Green = "00ff00",
	Blue = "0000ff",
	Cyan = "00ffff",
	Fuchsia = "ff00ff",
	Yellow = "ffff00",
	Gray = "afafaf",
}) do
	assert_equal(DogTag:Evaluate("['Hello':" .. name .. "]"), "|cff" .. color .. "Hello|r")
	assert_equal(DogTag:Evaluate("[" .. name .. " 'Hello']"), "|cff" .. color .. "Hello")
	assert_equal(DogTag:Evaluate("[nil:" .. name .. "]"), nil)
	assert_equal(DogTag:Evaluate("[false:" .. name .. "]"), nil)
	assert_equal(DogTag:Evaluate("[true:" .. name .. "]"), "|cff" .. color .. "True|r")
end

assert_equal(DogTag:Evaluate("['Hello':Abbreviate]"), "Hello")
assert_equal(DogTag:Evaluate("['Hello World':Abbreviate]"), "HW")
assert_equal(DogTag:Evaluate("[nil:Abbreviate]"), nil)
assert_equal(DogTag:Evaluate("[false:Abbreviate]"), nil)
assert_equal(DogTag:Evaluate("[true:Abbreviate]"), "True")

assert_equal(DogTag:Evaluate("[SubtractFive(10)]"), 5)
assert_equal(DogTag:Evaluate("[SubtractFive(12)]"), 7)
assert_equal(DogTag:Evaluate("[SubtractFive(One)]"), -4)
assert_equal(DogTag:Evaluate("[SubtractFive]"), "Arg #1 (number) req'd for SubtractFive")
assert_equal(DogTag:Evaluate("[SubtractFive(number=10)]"), 5)
assert_equal(DogTag:Evaluate("[SubtractFive]", nil, { number = 10 }), 5)

assert_equal(DogTag:Evaluate("[SubtractFromFive(10)]"), -5)
assert_equal(DogTag:Evaluate("[SubtractFromFive(12)]"), -7)
assert_equal(DogTag:Evaluate("[SubtractFromFive(One)]"), 4)
assert_equal(DogTag:Evaluate("[SubtractFromFive]", nil, { number = 10 }), -5)

assert_equal(DogTag:Evaluate("[ReverseSubtract(4, 2)]"), -2)
assert_equal(DogTag:Evaluate("[ReverseSubtract(2, 4)]"), 2)
assert_equal(DogTag:Evaluate("[2:ReverseSubtract(4)]"), 2)
assert_equal(DogTag:Evaluate("[ReverseSubtract(1)]"), "Arg #2 (right) req'd for ReverseSubtract")
assert_equal(DogTag:Evaluate("[ReverseSubtract]"), "Arg #1 (left) req'd for ReverseSubtract")

assert_equal(DogTag:Evaluate("[AbsAlias(10)]"), 10)
assert_equal(DogTag:Evaluate("[AbsAlias(-10)]"), 10)

assert_equal(DogTag:Evaluate("[TupleAlias]"), 5)
assert_equal(DogTag:Evaluate("[TupleAlias(1)]"), "5-1")
assert_equal(DogTag:Evaluate("[TupleAlias(1, 2, 3)]"), "5-1-2-3")

assert_equal(DogTag:Evaluate("[OtherTupleAlias(5, 2)]"), 3)
assert_equal(DogTag:Evaluate("[OtherTupleAlias(2, 5)]"), -3)
assert_equal(DogTag:Evaluate("[OtherTupleAlias(5, 6, 7)]"), "Too many args for Subtract")
assert_equal(DogTag:Evaluate("[OtherTupleAlias(5)]"), "Arg #2 (right) req'd for Subtract")

assert_equal(DogTag:Evaluate("[5:IsIn]"), nil)
assert_equal(DogTag:Evaluate("[5:IsIn(6, 7, 8)]"), nil)
assert_equal(DogTag:Evaluate("[5:IsIn(1, 2, 3, 4, 5)]"), 5)

assert_equal(DogTag:Evaluate("[not One:RetNil]"), 1)

assert_equal(DogTag:Evaluate("[Boolean(nil)]"), nil)
assert_equal(DogTag:Evaluate("[Boolean(1)]"), "True")
assert_equal(DogTag:Evaluate("[Boolean(One)]"), "True")
assert_equal(DogTag:Evaluate("[Boolean('Hello')]"), "True")
GlobalCheck_data = 'Hello'
assert_equal(DogTag:Evaluate("[Boolean(GlobalCheck)]"), "True")
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[Boolean(GlobalCheck)]"), nil)

assert_equal(DogTag:Evaluate("[One:Hide(6, 7, 8)]"), 1)
assert_equal(DogTag:Evaluate("[One:Hide(1, 6, 7, 8)]"), nil)
assert_equal(DogTag:Evaluate("[One:Hide(2):Hide(3)]"), 1)
assert_equal(DogTag:Evaluate("[One:Hide(2):Hide(3):Hide(1)]"), nil)

GlobalCheck_data = 1
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(6, 7, 8)]"), 1)
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(1, 6, 7, 8)]"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(2):Hide(3)]"), 1)
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(2):Hide(1):Hide(3)]"), nil)
assert_equal(DogTag:Evaluate("[5:Hide(6, 7, 8)]"), 5)
assert_equal(DogTag:Evaluate("[5:Hide(1, 2, 3, 4, 5)]"), nil)

assert_equal(DogTag:Evaluate("[One:IsIn(nil)]"), nil)
assert_equal(DogTag:Evaluate("[One:IsIn(Unknown)]"), "Unknown tag Unknown")
assert_equal(DogTag:Evaluate("[not One:IsIn(nil)]"), 1)
assert_equal(DogTag:Evaluate("[not One:IsIn(Unknown)]"), "Unknown tag Unknown")
assert_equal(DogTag:Evaluate("[One:Hide(nil)]"), 1)
assert_equal(DogTag:Evaluate("[One:Hide(Unknown)]"), "Unknown tag Unknown")

assert_equal(DogTag:Evaluate("['Hello':Contains('There')]"), nil)
assert_equal(DogTag:Evaluate("['Hello':Contains('ello')]"), "Hello")
assert_equal(DogTag:Evaluate("['Hello':~Contains('There')]"), "Hello")
assert_equal(DogTag:Evaluate("['Hello':~Contains('ello')]"), nil)

GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[GlobalCheck ? 'Hello' One ! 'There' Two]"), 'Hello1')
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck ? 'Hello' One ! 'There' Two]"), 'There2')
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[(GlobalCheck ? 'Hello' One ! 'There' Two) 'Buddy']"), 'Hello1Buddy')
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[(GlobalCheck ? 'Hello' One ! 'There' Two) 'Buddy']"), 'There2Buddy')

assert_equal(DogTag:Evaluate("[FakeOne]"), 100)

DogTag:RemoveFontString(fs)

local function fix(ast)
	if type(ast) == "table" and ast[1] == "tag" then
	 	if ast[2] == "FakeOne" then
			ast[2] = "One"
		end
		assert(#ast == 2) -- don't show normal args, just kwargs
	end
	if type(ast) == "table" then
		for i = 2, #ast do
			fix(ast[i])
		end
		if ast.kwarg then
			for _,v in pairs(ast.kwarg) do
				fix(v)
			end
		end
	end
end
local function func(ast, kwargTypes)
	fix(ast)
	return ast
end
DogTag:AddCompilationStep("Base", "pre", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[FakeOne]"), 1)
DogTag:RemoveCompilationStep("Base", "pre", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[FakeOne]"), 100)
DogTag:AddCompilationStep("Base", "pre", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[FakeOne]"), 1)
DogTag:RemoveAllCompilationSteps("Base", "pre")
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[FakeOne]"), 100)
DogTag:AddCompilationStep("Base", "pre", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[FakeOne]"), 1)
DogTag:RemoveAllCompilationSteps("Base")
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[FakeOne]"), 100)
DogTag:AddCompilationStep("Base", "pre", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[PlusOne(number=FakeOne)]"), 2)
assert_equal(DogTag:Evaluate("[PlusOne(FakeOne)]"), 2)
DogTag:RemoveAllCompilationSteps("Base")
FireOnUpdate(0)

local function func(t, ast, kwargTypes, extraKwargs)
	t[#t+1] = [=[result = '`' .. tostring(result) .. '`']=]
end
DogTag:AddCompilationStep("Base", "finish", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("Hello"), '`Hello`')
DogTag:RemoveCompilationStep("Base", "finish", func)
FireOnUpdate(0)

local function func(t, ast, kwargTypes, extraKwargs)
	t[#t+1] = [=[result = '`' .. tostring(result) .. '`']=]
end
assert_equal(DogTag:Evaluate("Hello"), 'Hello')
DogTag:AddCompilationStep("Base", "finish", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("Hello"), '`Hello`')
DogTag:RemoveCompilationStep("Base", "finish", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("Hello"), 'Hello')

local function func(t, ast, kwargTypes, extraKwargs)
	t[#t+1] = [=[do assert(result == nil) return 'omgpants' end;]=]
end
assert_equal(DogTag:Evaluate("Hello"), 'Hello')
DogTag:AddCompilationStep("Base", "start", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("Hello"), 'omgpants')
DogTag:RemoveCompilationStep("Base", "start", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("Hello"), 'Hello')

local function func(ast, t, tag, tagData, kwargs, extraKwargs, compiledKwargs)
	if kwargs.number then
		t[#t+1] = [=[if ]=]
		t[#t+1] = compiledKwargs.number[1]
		t[#t+1] = [=[ < 10 then return ("Bad number: %d"):format(]=]
		t[#t+1] = compiledKwargs.number[1]
		t[#t+1] = [=[), nil;end;]=]
	end
end
assert_equal(DogTag:Evaluate("[PlusOne(One)]"), 2)
DogTag:AddCompilationStep("Base", "tag", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[PlusOne(One)]"), "Bad number: 1")
assert_equal(DogTag:Evaluate("[PlusOne(1)]"), "Bad number: 1")
assert_equal(DogTag:Evaluate("[PlusOne(10)]"), 11)
assert_equal(DogTag:Evaluate("[PlusOne(One * 10)]"), 11)
assert_equal(DogTag:Evaluate("[PlusOne(4 * 2)]"), "Bad number: 8")
DogTag:RemoveCompilationStep("Base", "tag", func)
FireOnUpdate(0)
assert_equal(DogTag:Evaluate("[PlusOne(One)]"), 2)

local function func(ast, t, u, tag, tagData, kwargs, extraKwargs, compiledKwargs, events, returns)
	if kwargs.number then
		events["SOME_EVENT"] = true
	end
end

DogTag:AddCompilationStep("Base", "tagevents", func)
FireOnUpdate(0)
BlizzEventTest_num = 0
DogTag:AddFontString(fs, f, "[BlizzEventTest('never')]")
assert_equal(fs:GetText(), 1)
FireEvent("SOME_EVENT")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 1)
DogTag:AddFontString(fs, f, "[BlizzEventTest('never') + PlusOne(-1)]")
assert_equal(fs:GetText(), 2)
FireEvent("SOME_EVENT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
DogTag:RemoveCompilationStep("Base", "tagevents", func)
FireOnUpdate(0)
assert_equal(fs:GetText(), 4)
FireEvent("SOME_EVENT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 4)

local function func(ast, t, u, tag, tagData, kwargs, extraKwargs, compiledKwargs, events, returns)
	events["FastUpdate"] = true
end
DogTag:AddCompilationStep("Base", "tagevents", func)
BlizzEventTest_num = 0
DogTag:AddFontString(fs, f, "[BlizzEventTest('never')]")
assert_equal(fs:GetText(), 1)
for i = 2, 100 do
	FireOnUpdate(0.05)
	assert_equal(fs:GetText(), i)
end
DogTag:RemoveCompilationStep("Base", "tagevents", func)

--FireOnUpdate(0.05)

local function func(ast, t, u, tag, tagData, kwargs, extraKwargs, compiledKwargs, events, returns)
	events["Update"] = true
end
DogTag:AddCompilationStep("Base", "tagevents", func)
BlizzEventTest_num = 0
DogTag:RemoveFontString(fs)
DogTag:AddFontString(fs, f, "[BlizzEventTest('never')]")
assert_equal(fs:GetText(), 1)
for i = 2, 100 do
	for j = 1, 3 do
		FireOnUpdate(0.05)
		local x = fs:GetText()
		if x ~= i and x ~= i-1 then
			error(("Bad value %d %d %d"):format(i, j, x))
		end
	end
end
DogTag:RemoveCompilationStep("Base", "tagevents", func)

local function func(ast, t, u, tag, tagData, kwargs, extraKwargs, compiledKwargs, events, returns)
	events["SlowUpdate"] = true
end
DogTag:AddCompilationStep("Base", "tagevents", func)
FireOnUpdate(0)
BlizzEventTest_num = 0
DogTag:RemoveFontString(fs)
DogTag:AddFontString(fs, f, "[BlizzEventTest('never')]")
assert_equal(fs:GetText(), 1)
for i = 2, 100 do
	for j = 1, 200 do
		FireOnUpdate(0.05)
		local x = fs:GetText()
		if x ~= i and x ~= i-1 then
			error(("Bad value %d %d %d"):format(i, j, x))
		end
	end
end
DogTag:RemoveCompilationStep("Base", "tagevents", func)

local fired = false
DogTag:AddAddonFinder("Base", "_G", "MyAddonToBeFound", function(MyAddonToBeFound)
	assert_equal(MyAddonToBeFound, _G.MyAddonToBeFound)
	fired = true
end)
assert_equal(fired, false)
FireEvent("ADDON_LOADED")
assert_equal(fired, false)
_G.MyAddonToBeFound = {}
FireEvent("ADDON_LOADED")
assert_equal(fired, true)

local fired = false
DogTag:AddAddonFinder("Base", "LibStub", "MyLibToBeFound", function(MyLibToBeFound)
	assert_equal(MyLibToBeFound, LibStub("MyLibToBeFound"))
	fired = true
end)
assert_equal(fired, false)
FireEvent("ADDON_LOADED")
assert_equal(fired, false)
LibStub:NewLibrary("MyLibToBeFound", 1)
FireEvent("ADDON_LOADED")
assert_equal(fired, true)

DogTag:AddFontString(fs, f, "[ExtraFunctionalityWithLib]")
assert_equal(fs:GetText(), nil)
assert_equal(DogTag:Evaluate("[ExtraFunctionalityWithLib]"), nil)
LibStub:NewLibrary("LibToProvideExtraFunctionality", 1)
FireEvent("ADDON_LOADED")
FireOnUpdate(0)
assert_equal(fs:GetText(), "True")
assert_equal(DogTag:Evaluate("[ExtraFunctionalityWithLib]"), "True")

local fired = false
local expectedArg = nil
local expectedNumArgs = 0
local function func(event, ...)
	assert_equal(event, "MY_EVENT")
	assert_equal(..., expectedArg)
	assert_equal(select('#', ...), expectedNumArgs)
	
	fired = true
end
DogTag:AddEventHandler("Base", "MY_EVENT", func)
FireEvent("MY_EVENT")
assert_equal(fired, true)
fired = false
expectedArg = 'alpha'
expectedNumArgs = 2
FireEvent("MY_EVENT", 'alpha', 'bravo')
assert_equal(fired, true)
fired = false
expectedArg = nil
expectedNumArgs = 0
DogTag:FireEvent("MY_EVENT")
assert_equal(fired, true)
fired = false
expectedArg = 'alpha'
expectedNumArgs = 2
DogTag:FireEvent("MY_EVENT", 'alpha', 'bravo')
assert_equal(fired, true)
fired = false
DogTag:RemoveEventHandler("Base", "MY_EVENT", func)
FireEvent("MY_EVENT")
FireEvent("MY_EVENT", 'alpha', 'bravo')
DogTag:FireEvent("MY_EVENT")
DogTag:FireEvent("MY_EVENT", 'alpha', 'bravo')
assert_equal(fired, false)

assert_equal(DogTag:Evaluate("[Thingy('hey')]"), "hey")
assert_equal(DogTag:Evaluate("[Thingy]", nil, { value = 'hey' }), "hey")
assert_equal(DogTag:Evaluate("[AliasOfThingy('hey')]"), "hey")
assert_equal(DogTag:Evaluate("[AliasOfThingy]", nil, { myvalue = 'hey' }), "hey")
assert_equal(DogTag:Evaluate("[OtherAliasOfThingy('hey')]"), "heyhey")
assert_equal(DogTag:Evaluate("[OtherAliasOfThingy]", nil, { myvalue = 'hey' }), "heyhey")

GlobalCheck_data = 1
DogTag:AddFontString(fs, f, "[Thingy('hey')] [GlobalCheck]")
assert_equal(fs:GetText(), 'hey 1')
GlobalCheck_data = 2
FireEvent("THINGY_EVENT", "Something")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 'hey 1')
FireEvent("THINGY_EVENT", "hey")
FireOnUpdate(0)
assert_equal(fs:GetText(), 'hey 1')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 'hey 2')

GlobalCheck_data = 1
DogTag:AddFontString(fs, f, "[AliasOfThingy('hey')] [GlobalCheck]")
assert_equal(fs:GetText(), 'hey 1')
GlobalCheck_data = 2
FireEvent("THINGY_EVENT", "Something")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 'hey 1')
FireEvent("THINGY_EVENT", "hey")
FireOnUpdate(0)
assert_equal(fs:GetText(), 'hey 1')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 'hey 2')

GlobalCheck_data = 1
DogTag:AddFontString(fs, f, "[OtherAliasOfThingy('hey')] [GlobalCheck]")
assert_equal(fs:GetText(), 'heyhey 1')
GlobalCheck_data = 2
FireEvent("THINGY_EVENT", "Something")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 'heyhey 1')
FireEvent("THINGY_EVENT", "heyhey")
FireOnUpdate(0)
assert_equal(fs:GetText(), 'heyhey 1')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 'heyhey 2')

GlobalCheck_data = 1
DogTag:AddFontString(fs, f, "[Thingy] [GlobalCheck]", nil, { value = 'hey' })
assert_equal(fs:GetText(), 'hey 1')
GlobalCheck_data = 2
FireEvent("THINGY_EVENT", "Something")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 'hey 1')
FireEvent("THINGY_EVENT", "hey")
FireOnUpdate(0)
assert_equal(fs:GetText(), 'hey 1')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 'hey 2')

GlobalCheck_data = 1
DogTag:AddFontString(fs, f, "[AliasOfThingy] [GlobalCheck]", nil, { myvalue = 'hey' })
assert_equal(fs:GetText(), 'hey 1')
GlobalCheck_data = 2
FireEvent("THINGY_EVENT", "Something")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 'hey 1')
FireEvent("THINGY_EVENT", "hey")
FireOnUpdate(0)
assert_equal(fs:GetText(), 'hey 1')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 'hey 2')

GlobalCheck_data = 1
DogTag:AddFontString(fs, f, "[OtherAliasOfThingy] [GlobalCheck]", nil, { myvalue = 'hey' })
assert_equal(fs:GetText(), 'heyhey 1')
GlobalCheck_data = 2
FireEvent("THINGY_EVENT", "Something")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 'heyhey 1')
FireEvent("THINGY_EVENT", "heyhey")
FireOnUpdate(0)
assert_equal(fs:GetText(), 'heyhey 1')
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 'heyhey 2')

assert_equal(DogTag:Evaluate("[(Two One) ? One]"), 1)
assert_equal(DogTag:Evaluate("[Two (One ? One)]"), 21)

assert_equal(DogTag:Evaluate("[One:Color(\"95e495\")]"), "|cff95e4951|r")
assert_equal(DogTag:Evaluate("[One:Color(\"999999\")]"), "|cff9999991|r")

assert_equal(DogTag:Evaluate("[OtherRetSame('good') ? 'hi'] ['test']"), "hi test")
assert_equal(DogTag:Evaluate("[OtherRetSame(nil) ? 'hi'] ['test']"), "test")
assert_equal(DogTag:Evaluate("[OtherRetSame('good') or nil] ['test']"), "good test")
assert_equal(DogTag:Evaluate("[OtherRetSame(nil) or 'hi'] ['test']"), "hi test")
assert_equal(DogTag:Evaluate("[OtherRetSame('good') and 'hi'] ['test']"), "hi test")
assert_equal(DogTag:Evaluate("[OtherRetSame(nil) and 'hi'] ['test']"), "test")

assert_equal(parse("[Red][Name] [Realm]"), { "concat", { "tag", "Red" }, { "tag", "Name", }, " ", { "tag", "Realm" } })
assert_equal(DogTag:CleanCode("[Red][Name] [Realm]"), "[Red Name] [Realm]")

local finalMemory = collectgarbage('count')
local finalTime = os.clock()
collectgarbage('collect')
local finalMemoryAfterCollect = collectgarbage('count')
print("Memory:", finalMemory*1024)
print("Memory after collect:", finalMemoryAfterCollect*1024)
print("Time:", finalTime)

print("LibDogTag-3.0: Tests succeeded")

if DogTag_Test_SecondTime then
	return
end

_G.MyAddonToBeFound = nil
LibStub.libs.MyLibToBeFound = nil
LibStub.minors.MyLibToBeFound = nil
LibStub.libs.LibToProvideExtraFunctionality = nil
LibStub.minors.LibToProvideExtraFunctionality = nil
DogTag_Test_SecondTime = true
LibStub.minors["LibDogTag-3.0"] = 1 -- reset version

local SpecialTag_data = nil
DogTag:AddTag("Special", "SpecialTag", {
	code = function()
		return SpecialTag_data
	end,
	ret = 'string;number;nil',
})

local SpecialEventTag_num = 0
DogTag:AddTag("Special", "SpecialEventTag", {
	code = function()
		SpecialEventTag_num = SpecialEventTag_num + 1
		return SpecialEventTag_num
	end,
	ret = 'number',
	events = "SPECIAL_EVENT"
})

DogTag:AddTag("Base", "ChangingTag", {
	code = function()
		return "Hello"
	end,
	ret = 'string',
})

SpecialAddonFinder_fired = false
DogTag:AddAddonFinder("Special", "_G", "SpecialGlobal", function()
	assert_equal(SpecialAddonFinder_fired, false)
	SpecialAddonFinder_fired = true
end)

SpecialTag_data = nil
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), nil)
SpecialTag_data = 'hey'
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), 'hey')
SpecialTag_data = 52
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), 52)

assert_equal(DogTag:Evaluate("[ChangingTag]"), "Hello")

DogTag:AddFontString(fs, f, "[SpecialEventTag]", "Special")
assert_equal(fs:GetText(), 1)
FireEvent("SPECIAL_EVENT")
assert_equal(fs:GetText(), 1)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 2)

local SpecialEventTag_Callback_fired = false
DogTag:AddCallback("[SpecialEventTag]", function(code, kwargs)
	assert_equal(code, "[SpecialEventTag]")
	assert_equal(kwargs, nil)
	SpecialEventTag_Callback_fired = true
end, "Special")

FireEvent("SPECIAL_EVENT")
assert_equal(SpecialEventTag_Callback_fired, true)

local SPECIAL_EVENT_CHECK_fired = false
DogTag:AddEventHandler("Base", "SPECIAL_EVENT_CHECK", function(event, ...)
	assert_equal(SPECIAL_EVENT_CHECK_fired, false)
	SPECIAL_EVENT_CHECK_fired = true
	assert(event == "SPECIAL_EVENT_CHECK")
	assert((...) == "Good")
end)

FireEvent("SPECIAL_EVENT_CHECK", "Good")
assert_equal(SPECIAL_EVENT_CHECK_fired, true)
SPECIAL_EVENT_CHECK_fired = false

local SPECIAL_TIMER_fired = false
DogTag:AddTimerHandler("Base", function(currentTime, num)
	SPECIAL_TIMER_fired = true
end)

FireOnUpdate(0.05)
assert_equal(SPECIAL_TIMER_fired, true)
SPECIAL_TIMER_fired = false

dofile('test.lua')

DogTag:AddTag("Base", "ChangingTag", {
	code = function()
		return "There"
	end,
	ret = 'string',
})

SpecialTag_data = nil
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), nil)
SpecialTag_data = 'hey'
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), 'hey')
SpecialTag_data = 52
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), 52)

assert_equal(DogTag:Evaluate("[ChangingTag]"), "There")

FireEvent("ADDON_LOADED")
assert_equal(SpecialAddonFinder_fired, false)
_G.SpecialGlobal = {}
FireEvent("ADDON_LOADED")
assert_equal(SpecialAddonFinder_fired, true)

local num = fs:GetText()
assert_equal(fs:GetText(), num)
FireEvent("SPECIAL_EVENT")
assert_equal(fs:GetText(), num)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), num+1)

FireEvent("SPECIAL_EVENT_CHECK", "Good")
assert_equal(SPECIAL_EVENT_CHECK_fired, true)
SPECIAL_EVENT_CHECK_fired = false

SPECIAL_TIMER_fired = false
FireOnUpdate(0.05)
assert_equal(SPECIAL_TIMER_fired, true)
SPECIAL_TIMER_fired = false

SpecialEventTag_Callback_fired = false
FireEvent("SPECIAL_EVENT")
assert_equal(SpecialEventTag_Callback_fired, true)

DogTag:ClearNamespace("Special")
FireOnUpdate(0)

SpecialEventTag_Callback_fired = false
FireEvent("SPECIAL_EVENT")
assert_equal(SpecialEventTag_Callback_fired, false)

SpecialTag_data = nil
assert_equal(DogTag:Evaluate("[SpecialTag]", "Special"), "Unknown tag SpecialTag")
