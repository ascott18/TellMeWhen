-- Script to extract class spells 

 
 
local http = require "socket.http"
local json = require "json"

local outFile = io.open("CSC.lua", "w")
if not outFile then
	print("CANT OPEN OUTFILE")
end

local out = "local Cache = {\n"

local blacklist = {
	[165201] = true,
}






-------------------------------------------------------
------------------- CLASS SPELLS ----------------------
for i = 1, 11 do
	print(i)

	out = out .. "\t[" .. i .. "] = {"

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

out = out .. "\tPET = {"
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








-------------------------------------------------------
-------------------- RACIALS -----------------------

local raceMapFix = {
	-- These are missing races.
	[107072] = {24},
	[107073] = {24},
	[107074] = {24},
	[107076] = {24},
	[107079] = {24},
}
local noClassReq = {
	-- Worgen racials have massive class req fields for no reason.
	[68975] = true,
	[68976] = true,
	[68978] = true,
	[68992] = true,
	[68996] = true,
	[87840] = true,
	[94293] = true,
}
out = out .. "\tRACIAL = {"
local content = http.request("http://www.wowhead.com/spells=-4")
local data = json.decode(content:match("var listviewspells = (%b[])"), nil)
for k, v in pairs(data) do
	if not blacklist[v.id] then
		if not v.races then
			v.races = raceMapFix[v.id]
		end
		if not v.races then
			print("Unknown racial", v.id, v.name)
		else
			if v.reqclass and not noClassReq[v.id] then
				out = out .. "[" .. v.id .. "]={" .. v.races[1] .. "," .. (v.reqclass or 0) .. "},"
			else
				out = out .. "[" .. v.id .. "]=" .. v.races[1] .. ","
			end
		end
	end
end
out = out .. "},\n"









out = out .. "}"

print(out)



outFile:write(out)