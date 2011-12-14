
local AUTO_FIND_TOC = nil--"./"
local FILE_BLACKLIST = {"^localization", "^lib"}

local PATH_TO_ADDONS = "B:/Games/World Of Warcraft/Interface/AddOns/"
local ADDONS = {
	"TellMeWhen",
	"TellMeWhen_Options",
}

local localizedKeys = {}

for _, ADDON_NAME in pairs(ADDONS) do
	local PATH_TO_ADDON_FOLDER = PATH_TO_ADDONS .. ADDON_NAME .. "/"
	local TOC_FILE = PATH_TO_ADDON_FOLDER .. ADDON_NAME .. ".toc"

	-- No more modifying!
	local OS_TYPE = os.getenv("HOME") and "linux" or "windows"



	-- Find the TOC now
	if( AUTO_FIND_TOC ) then
		local pipe = OS_TYPE == "windows" and io.popen(string.format("dir /B \"%s\"", AUTO_FIND_TOC)) or io.popen(string.format("ls -1 \"%s\"", AUTO_FIND_TOC))
		if( type(pipe) == "userdata" ) then
			for file in pipe:lines() do
				if( string.match(file, "(.+)%.toc") ) then
					TOC_FILE = file
					break
				end
			end

			pipe:close()
			if( not TOC_FILE ) then print("Failed to auto detect toc file.") end
		else
			print("Failed to auto find toc, cannot run dir /B or ls -1")
		end
	end

	if( not TOC_FILE ) then
		while( not TOC_FILE ) do
			io.stdout:write("TOC path: ")
			TOC_FILE = io.stdin:read("*line")
			TOC_FILE = TOC_FILE ~= "" and TOC_FILE or nil
			if( TOC_FILE ) then
				local file = io.open(TOC_FILE)
				if( file ) then
					file:close()
					break
				else
					print(string.format("%s does not exist.", TOC_FILE))
				end
			end
		end
	end

	print("")
	print("")
	print(string.format("Using TOC file %s", TOC_FILE:gsub(PATH_TO_ADDONS, "")))
	print("")

	-- Parse through the TOC file so we know what to scan
	local ignore
	for line in io.lines(TOC_FILE) do
		line = string.gsub(line, "\r", "")
		
		if( string.match(line, "#@no%-lib%-strip@") ) then
			ignore = true
		elseif( string.match(line, "#@end%-no%-lib%-strip@") ) then
			ignore = nil
		end
			
		if( not ignore and (string.match(line, "%.lua") or string.match(line, "%.xml")) ) then
			-- Make sure it's a valid file
			local blacklist
			for _, check in pairs(FILE_BLACKLIST) do
				if( string.match(string.lower(line), check) ) then
					blacklist = true
					break
				end
			end
		
			-- File checks out, scrap everything
			if( not blacklist ) then
				-- Fix slashes
				if( OS_TYPE == "linux" ) then
					line = string.gsub(line, "\\", "/")
				end
				line = PATH_TO_ADDON_FOLDER .. line
				local keys = 0
				
				local contents = io.open(line):read("*all")
			
				--for match in string.gmatch(contents, "L%[\"(.-)\".-%]") do -- this line wont detect TMW:TT() calls
				for match in string.gmatch(contents, "\"(.-)\".-") do
					if( not localizedKeys[match] ) then keys = keys + 1 end
					localizedKeys[match] = true
				end
				
				print(string.format("%s (%d keys)", line:gsub(PATH_TO_ADDONS, ""), keys))
			end
		end
	end
end


-- Compile all of the localization we found into string form
local totalLocalizedKeys = 0
local localization = ""
for key in pairs(localizedKeys) do
	localization = string.format("%s\nL[\"%s\"] = true", localization, key, key)
	totalLocalizedKeys = totalLocalizedKeys + 1
end
if( totalLocalizedKeys == 0 ) then
	print("Warning, failed to find any localizations, perhaps you messed up a configuration variable?")
	return
end



print("")
print(string.format("Found %d keys and/or strings total", totalLocalizedKeys))

-- read the locale file
local L = {}
function LibStub()
	local AceLocale = {}
	function AceLocale:NewLocale()
		return L
	end
	return AceLocale
end
dofile(PATH_TO_ADDONS .. "TellMeWhen/Localization/TellMeWhen-enUS.lua")
-- all current locale is now stored in L
local unused = {}
for k, v in pairs(L) do
	if
		not localizedKeys[k] and
		not strfind(k, "%l") and
		not strfind(k, "STRATA")
	then
		unused[k] = true
	end
end

local unusedString = ""
local totalUnusedStrings = 0
for key in pairs(unused) do
	unusedString = string.format("%s\n%s", unusedString, key)
	totalUnusedStrings = totalUnusedStrings + 1
end

print("")
print("")
print(string.format("Found %d unused keys total", totalUnusedStrings))
print("")
print("")

io.open(PATH_TO_ADDONS .. "TellMeWhen/Scripts/UNUSEDLOCALE.lua", "w"):write(unusedString)


