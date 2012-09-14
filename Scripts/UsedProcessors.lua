
function processFile(filePath)

local file = io.open(filePath, "r")
local contents = file:read("*a")
file:close()

--print(contents)
local t = {}
for str in string.gmatch(contents, [[icon:SetInfo%(.-"(.-)",]]) do
	local temp = {string.split(";", str)}
	for i, attributes in pairs(temp) do
		t[attributes:trim()] = true
	end
end

local attributesString = ""
for attributes in pairs(t) do
	attributesString = attributesString .. [[Type:UsesAttributes("]] .. attributes .. [[")
]]
end
assert(contents:find([[
-- AUTOMATICALLY GENERATED: UsesAttributes
.*
-- END AUTOMATICALLY GENERATED: UsesAttributes]]), "Couldn't find section 'AUTOMATICALLY GENERATED: UsesAttributes'")

local newContents = contents:gsub([[
-- AUTOMATICALLY GENERATED: UsesAttributes
.*
-- END AUTOMATICALLY GENERATED: UsesAttributes]],
[[
-- AUTOMATICALLY GENERATED: UsesAttributes
]].. attributesString .. [[
-- END AUTOMATICALLY GENERATED: UsesAttributes]])

if newContents ~= contents then
	local file = io.open(filePath, "w")
	print("Writing to file...")
	file:write(newContents)
	file:close()
end
end


for line in io.open([[C:\Program Files\World Of Warcraft\Interface\AddOns\TellMeWhen\Components\IconTypes\includes.core.xml]], "r"):lines() do
	local type = line:match([[<Include file="IconType_(.*)\includes.core.xml"/>]])
	if type then
		local path = "IconType_" .. type .. "\\" .. type .. ".lua"
		if path then
			local success, err = pcall(processFile, [[C:\Program Files\World Of Warcraft\Interface\AddOns\TellMeWhen\Components\IconTypes\]] .. path)
			if not success then
				print(path, err)
			else
				print(path .. ": Success")
			end
		end
	end
end
