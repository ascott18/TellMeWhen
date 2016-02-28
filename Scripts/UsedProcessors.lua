
local BASEPATH = [[C:\Games\World Of Warcraft\Interface\AddOns\TellMeWhen\Components\IconTypes\]]

function processFile(filePath)

	local file = io.open(filePath, "r")
	local contents = file:read("*a")
	file:close()

	--print(contents)
	local t = {}
	for str in string.gmatch(contents, [[:SetInfo%(%s-["'](.-)["'],]]) do
		for attributes in string.gmatch(str, "([^;]*)") do
			attributes = attributes:gsub("^ ", ""):gsub(" $", "")
			if attributes ~= "" then
				t[attributes] = true
			end
		end
	end

	local attributesString = ""
	for attributes in pairs(t) do
		attributesString = attributesString .. [[Type:UsesAttributes("]] .. attributes .. [[")
]]
	end
	print(attributesString)
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


for line in io.open(BASEPATH .. [[includes.core.xml]], "r"):lines() do
	local path = line:match([[<Script file="(.*)"/>]])
	if path then
		local success, err = pcall(processFile, BASEPATH .. path)
		if not success then
			print(path, err)
		else
			print(path .. ": Success")
		end
	end
end
