-- Script to extract currency information 

-- lua distribution used is at: http://w3.impa.br/~diego/software/luasocket/
-- includes LuaSocket library
 
 
local http = require("socket.http")
local str = [[{
	-- item enhancements
	--IMPORTANT: COMMENT OUT ANY FISHING LURES. THEY DO NOT USE A NORMAL TOOLTIP
]]

local src = http.request("http://www.wowhead.com/items=0.-3?filter=qu=1:2:3:4:5:6:7")
local t = {}
local n = 0
--{"classs":0,"id":20844,"level":60,"name":"6Deadly Poison","reqclass":8,"reqlevel":60,"slot":0,"subclass":-3,firstseenpatch: 0,cost:[0]},
for id, level, name in string.gmatch(src, [==[{"classs":0,"id":(%d+),"level":(%d+),"name":"(.-)",.-}]==]) do
	name = name:match("([%a %-]+)")
	if (t[name] and t[name].level < level) or not t[name] then
		t[name]={name = name, id = id, level = level}
	end
	n = n + 1
end
print(n)
n = 0
for k,v in pairs(t) do
	str = str .. "\t" .. v.id .. ",\t--" .. v.name .. "\n"
	n = n + 1
end

print(n)

str = str .. [[}


{
	-- shaman enchants
]]

local src = http.request("http://www.wowhead.com/spells=7.7?filter=na=weapon;cr=9;crs=8;crv=0")
local n = 0
for id, name in string.gmatch(src, [==[%[(%d+)%]={name_enus:'(.-)']==]) do
	str = str .. "\t" .. id .. ",\t--" .. name .. "\n"
	n = n + 1
end
print(n)
print(str)



str = str .. [[}]]
io.open("B:\\Games\\World Of Warcraft\\Interface\\AddOns\\TellMeWhen\\Scripts\\WeaponAugments.lua", "w"):write(str)