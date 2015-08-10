-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local UTIL = {}
TMW.UTIL = UTIL

-- TODO: STANDARDIZE THE CALLING FORMAT FOR FUNCTIONS IN THIS FILE.

function TMW.approachTable(t, ...)
	for i=1, select("#", ...) do
		local k = select(i, ...)
		if type(k) == "function" then
			t = k(t)
		else
			t = t[k]
		end
		if not t then return end
	end
	return t
end

function UTIL.shallowCopy(t)
	local new = {}
	for k, v in pairs(t) do
		new[k] = v
	end
	return new
end

function UTIL:CleanPath(path)
	if not path then
		return ""
	end
	
	return path:trim():gsub("\\\\", "/"):gsub("\\", "/"), nil
end


do	-- TMW:GetParser()
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3
	function TMW:GetParser()
		if not Parser then
			Parser = CreateFrame("GameTooltip")

			LT1 = Parser:CreateFontString()
			RT1 = Parser:CreateFontString()
			Parser:AddFontStrings(LT1, RT1)

			LT2 = Parser:CreateFontString()
			RT2 = Parser:CreateFontString()
			Parser:AddFontStrings(LT2, RT2)

			LT3 = Parser:CreateFontString()
			RT3 = Parser:CreateFontString()
			Parser:AddFontStrings(LT3, RT3)
		end
		return Parser, LT1, LT2, LT3, RT1, RT2, RT3
	end
end



local Formatter = TMW:NewClass("Formatter"){
	OnNewInstance = function(self, fmt)
		self.fmt = fmt
	end,

	Format = function(self, value)
		local type = type(self.fmt)

		if type == "string" then
			return string.format(self.fmt, value)
		elseif type == "table" then
			return self.fmt[value]
		elseif type == "function" then
			return self.fmt(value)
		else
			return value
		end
	end,

	SetFormattedText = function(self, frame, value)
		frame:SetText(self:Format(value))
	end,
}
Formatter:MakeInstancesWeak()

-- Some commonly used formatters.
Formatter{
	NONE = Formatter:New(TMW.NULLFUNC),
	PASS = Formatter:New(tostring),


	F_0 = Formatter:New("%.0f"),
	F_1 = Formatter:New("%.1f"),
	F_2 = Formatter:New("%.2f"),

	PERCENT = Formatter:New("%s%%"),
	PERCENT100 = Formatter:New(function(value)
		return ("%s%%"):format(value*100)
	end),
	PERCENT100_F0 = Formatter:New(function(value)
		return ("%.0f%%"):format(value*100)
	end),

	PLUSPERCENT = Formatter:New("+%s%%"),

	D_SECONDS = Formatter:New(D_SECONDS),
	S_SECONDS = Formatter:New(L["ANIM_SECONDS"]),

	PIXELS = Formatter:New(L["ANIM_PIXELS"]),

	COMMANUMBER = Formatter:New(function(k)
		k = gsub(k, "(%d)(%d%d%d)$", "%1,%2", 1)
		local found
		repeat
			k, found = gsub(k, "(%d)(%d%d%d),", "%1,%2,", 1)
		until found == 0

		return k
	end),


	TIME_COLONS = Formatter:New(function(value)
		return TMW:FormatSeconds(value, nil, 1)
	end),

	TIME_COLONS_FORCEMINS = Formatter:New(function(seconds)
		if abs(seconds) == math.huge then
			return tostring(seconds)
		end

		if seconds < 0 then
			error("This function doesn't support negative seconds")
		end
		
		local y =  seconds / 31556925
		local d = (seconds % 31556925) / 86400
		local h = (seconds % 31556925  % 86400) / 3600
		local m = (seconds % 31556925  % 86400  % 3600) / 60
		local s = (seconds % 31556925  % 86400  % 3600  % 60)

		if y >= 0x7FFFFFFE then
			return "OVERFLOW"
		end

		s = tonumber(format("%.1f", s))
		if s < 10 then
			s = "0" .. s
		end


		if y >= 1 then return format("%d:%d:%02d:%02d:%s", y, d, h, m, s) end
		if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, s) end
		if h >= 1 then return format("%d:%02d:%s", h, m, s) end
		return format("%d:%s", m, s)
	end),

	TIME_YDHMS = Formatter:New(function(seconds)
		if abs(seconds) == math.huge then
			return tostring(seconds)
		end

		if seconds < 0 then
			error("This function doesn't support negative seconds")
		end
		
		local y =  seconds / 31556926
		local d = (seconds % 31556926) / 86400
		local h = (seconds % 31556926  % 86400) / 3600
		local m = (seconds % 31556926  % 86400  % 3600) / 60
		local s = (seconds % 31556926  % 86400  % 3600  % 60)
		
		if y >= 0x7FFFFFFE then
			return "OVERFLOW"
		end
		
		
		local str = ""
		
		if y >= 1 then 
			str = str .. format("%dy", y)
		end
		if d >= 1 then 
			local fmt = DAY_ONELETTER_ABBR:gsub(" ", "")
			str = str .. " " .. format(fmt, d)
		end
		if h >= 1 then 
			local fmt = HOUR_ONELETTER_ABBR:gsub(" ", "")
			str = str .. " " .. format(fmt, h)
		end
		if m >= 1 then 
			local fmt = MINUTE_ONELETTER_ABBR:gsub(" ", "")
			str = str .. " " .. format(fmt, m)
		end

		if tonumber(format("%.1f", s)) == s then
			s = tostring(s)
		else
			s = format("%0.1f", s)
		end
		
		local fmt
		if str == "" then
			fmt = SECONDS_ABBR:gsub("%%d", "%%s"):lower()
		else
			fmt = SECOND_ONELETTER_ABBR:gsub("%%d ", "%%s"):lower()
		end
		str = str .. " " .. format(fmt, s)
		
		return str:trim()
	end),

	TIME_0ABSENT = Formatter:New(function(value)
		local s = Formatter.TIME_YDHMS:Format(value)
		if value == 0 then
			s = s .. " ("..L["ICONMENU_ABSENT"]..")"
		end
		return s
	end),
	TIME_0USABLE = Formatter:New(function(value)
		local s = Formatter.TIME_YDHMS:Format(value)
		if value == 0 then
			s = s .. " ("..L["ICONMENU_USABLE"]..")"
		end
		return s
	end),

	BOOL = Formatter:New{[0]=L["TRUE"], [1]=L["FALSE"]},
	BOOL_USABLEUNUSABLE = Formatter:New{[0]=L["ICONMENU_USABLE"], [1]=L["ICONMENU_UNUSABLE"]},
	BOOL_PRESENTABSENT = Formatter:New{[0]=L["ICONMENU_PRESENT"], [1]=L["ICONMENU_ABSENT"]},
}




do	-- TMW.shellsortDeferred
	-- From http://lua-users.org/wiki/LuaSorting - shellsort
	-- Written by Rici Lake. The author disclaims all copyright and offers no warranty.
	--
	-- This module returns a single function (not a table) whose interface is upwards-
	-- compatible with the interface to table.sort:
	--
	-- array = shellsort(array, before, n)
	-- array is an array of comparable elements to be sorted in place
	-- before is a function of two arguments which returns true if its first argument
	--    should be before the second argument in the second result. It must define
	--    a total order on the elements of array.
	--      Alternatively, before can be one of the strings "<" or ">", in which case
	--    the comparison will be done with the indicated operator.
	--    If before is omitted, the default value is "<"
	-- n is the number of elements in the array. If it is omitted, #array will be used.
	-- For convenience, shellsort returns its first argument.

	-- A036569
	local incs = { 8382192, 3402672, 1391376,
		463792, 198768, 86961, 33936,
		13776, 4592, 1968, 861, 336, 
	112, 48, 21, 7, 3, 1 }

	local execCap = 17
	local start = 0
	
	local function ssup(v, testval)
		return v < testval
	end
	
	local function ssdown(v, testval)
		return v > testval
	end
	
	local function ssgeneral(t, n, before, progressCallback, progressCallbackArg)
		local lastProgress = 100

		for idx, h in ipairs(incs) do
			local count = 1
			for i = h + 1, n do
				local v = t[i]
				for j = i - h, 1, -h do
					local testval = t[j]
					if not before(v, testval) then break end
					t[i] = testval; i = j
				end
				t[i] = v

				count = count + 1

				if (count % 200 == 0) and debugprofilestop() - start > execCap then
					local progress = #incs - idx + 1

					if progressCallback and progress ~= lastProgress then
						if progressCallbackArg then
							progressCallback(progressCallbackArg, progress)
						else
							progressCallback(progress)
						end
						lastProgress = progress
					end
					
					coroutine.yield()
				end
			end
		end
		return t
	end
	
	local coroutines = {}
	local function shellsort(t, before, n, callback, callbackArg, progressCallback, progressCallbackArg)
		n = n or #t
		if not before or before == "<" then
			ssgeneral(t, n, ssup, progressCallback, progressCallbackArg)
		elseif before == ">" then
			ssgeneral(t, n, ssdown, progressCallback, progressCallbackArg)
		else
			ssgeneral(t, n, before, progressCallback, progressCallbackArg)
		end

		if callbackArg ~= nil then
			callback(callbackArg)
		else
			callback()
		end

		coroutines[t] = nil
	end
	
	local f = CreateFrame("Frame")
	function f:OnUpdate()
		local table, co = next(coroutines)

		if table then
			if coroutine.status(co) == "dead" then
				-- This might happen if there was an error thrown before the coroutine could finish.
				coroutines[table] = nil
				return
			end
			-- dynamic execution cap based on framerate.
			-- this will keep us from dropping the user's framerate too much
			-- without doing so little sorting that the process goes super slowly.
			-- subtract a little bit to account for CPU usage for other things, like the game itself.
			execCap = 1000/max(20, GetFramerate()) - 5

			start = debugprofilestop()
			assert(coroutine.resume(co))
		end

		if not next(coroutines) then
			f:SetScript("OnUpdate", nil)
		end
	end


	-- The purpose of shellSortDeferred is to have a sort that won't
	-- lock up the game when we sort huge things.
	function TMW.shellsortDeferred(t, before, n, callback, callbackArg, progressCallback, progressCallbackArg)
		local co = coroutine.create(shellsort)
		coroutines[t] = co
		start = debugprofilestop()
		f:SetScript("OnUpdate", f.OnUpdate)
		assert(coroutine.resume(co, t, before, n, callback, callbackArg, progressCallback, progressCallbackArg))
	end
end