-- Script to extract enrage spells from db.mmo-champion.com

-- there are a few that arent spells anymore
-- make sure and delete those (look at the tooltip on the name editbox in the icon editor when you hold down a mod key))

-- lua distribution used is at: http://w3.impa.br/~diego/software/luasocket/
-- includes LuaSocket library
 
 
local http = require("socket.http")

local src = http.request("http://db.mmo-champion.com/spells/?dispel_type=9")

local t = {}

for id in string.gmatch(src, "'id': (%d+)") do
	t[#t+1] = id
end

str = table.concat(t, ";")
print(str)

io.open("B:\\Games\\World Of Warcraft\\Interface\\AddOns\\TellMeWhen\\Scripts\\Enrages.txt", "w"):write(str)