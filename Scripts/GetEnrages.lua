-- Script to extract enrage spells from db.mmo-champion.com

-- there are a few that arent spells anymore
-- make sure and delete those (look at the tooltip on the name editbox in the icon editor when you hold down a mod key))

-- lua distribution used is at: http://w3.impa.br/~diego/software/luasocket/
-- includes LuaSocket library
 
 
local http = require("socket.http")
local string = require("string")

local url = "http://db.mmo-champion.com/spells/?dispel_type=9"

local src = http.request(url)

local start = string.find(src, "'id': %d+", start)
local str = ""
while string.find(src, "'id': (%d+)", start) do
	id = string.match(src, "'id': (%d+)", start)
	s, start = string.find(src, "'id': %d+", start)
	str = str .. ";" .. id
end
str = string.sub(str, 2)

io.open("B:\\Games\\World Of Warcraft\\Interface\\AddOns\\TellMeWhen\\Scripts\\Enrages.txt", "w"):write(str)