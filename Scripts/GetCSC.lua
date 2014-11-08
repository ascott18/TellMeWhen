-- Script to extract class spells 

 
 
local http = require "socket.http"
local json = require "json"

local out = "Cache = {"

local blacklist = {
	[165201] = true,
}




-------------------------------------------------------
------------------- CLASS SPELLS ----------------------
for i = 1, 11 do
	print(i)

	out = out .. "[" .. i .. "] = {"

	local content = http.request("http://www.wowhead.com/class=" .. i)

	local data = json.decode(content:match("name: LANG.tab_spells.-data: (%b[])"), nil)
	for k, v in pairs(data) do
		if v.cat == 7 or v.cat == -12 or v.cat == -2 and not blacklist[v.id] then
			out = out .. v.id .. ","
		end
	end

	out = out .. "},\n"
end








-------------------------------------------------------
-------------------- PET SPELLS -----------------------
local petClasses = {
	3, -- hunter
	6, -- dk
	7, -- shaman
	9, -- lock
}

out = out .. "PET = {"
for _, classID in pairs(petClasses) do
	local content = http.request("http://www.wowhead.com/spells=-3." .. classID)
	local data = json.decode(content:match("var listviewspells = (%b[])"), nil)
	for k, v in pairs(data) do
		if not blacklist[v.id] then
			out = out .. "[" .. v.id .. "]=" .. classID .. ","
		end
	end
	
end
out = out .. "},\n"









out = out .. "}"

print(out)



io.open("B:\\Games\\World Of Warcraft\\Interface\\AddOns\\TellMeWhen\\Scripts\\CSC.lua", "w"):write(out)