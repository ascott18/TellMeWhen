-- Script to extract currency information 

-- lua distribution used is at: http://w3.impa.br/~diego/software/luasocket/
-- includes LuaSocket library
 
 
local http = require("socket.http")
local string = require("string")

local file = io.open("B:\\Games\\World Of Warcraft\\Interface\\AddOns\\TellMeWhen\\Scripts\\Currencies.lua", "w")

local str = "{\n"
--[[ -- THIS IS TO GET COMPLETE DATA, BUT I DECIDED I JUST WANT TO GET THE VALID IDS AND GET THE DATA FROM THE GAME.
local formatstr = [=[	{
		id = %d,
		itemid = %s,
		name = %s,
		icon = %s,
	},
]=]
local locales = {
	"en",
	"de",
	"es",
	"fr",
	"ru",
}

local hasItemID = {}

local allformat = "http://%s.wowhead.com/currencies"
local itemxmlformat = "http://%s.wowhead.com/item=%s&xml"
for _, domain in ipairs(locales) do

	local src = http.request(string.format(allformat, domain))
	local start = string.find(src, "id:%d+,category", start)
	
	file:write("\n----"..domain.."----")
	while string.find(src, "id:(%d+),category", start) do
		local name = "\"" .. string.match(src, "name:'(.-)',icon", start) .. "\""
		local id = string.match(src, "id:(%d+),category", start)
		local itemsrc = http.request(string.format(itemxmlformat, domain, name))
		local itemid = string.match(itemsrc, [==[<item id="(%d+)">]==])
		
		if domain == "en" then
			icon = "\"" .. string.match(src, "icon:'(.-)'}", start) .. "\""
			
			local itemsrc = http.request(string.format(itemxmlformat, domain, name))
			local itemid = string.match(itemsrc, [==[<item id="(%d+)">]==])
			str = str .. string.format(formatstr, id, itemid or "nil", name, icon)
			if itemid then
				hasItemID[id] = itemid
			end
			print(domain, id, name, icon)
			file:write("\nL[\"CURRENCY" .. id .. "\"] = " .. name)
		elseif not hasItemID[id] then
			print(domain, name)
			file:write("\nL[\"CURRENCY" .. id .. "\"] = " .. name)
		end
		
		s, start = string.find(src, "icon:'(.-)'}", start)
	end
end
]]


local src = http.request("http://www.wowhead.com/currencies")
local start = string.find(src, "id:%d+,category", start)

while string.find(src, "id:(%d+),category", start) do
	local name = string.match(src, "name:'(.-)',icon", start)
	local id = string.match(src, "id:(%d+),category", start)
	str = str .. "\t" .. id .. ",\t--" .. name .. "\n"
	print(id)
	
	s, start = string.find(src, "icon:'(.-)'}", start)
end
	
str = str .. "}"

file:write(str)