local root = [[B:\Games\World Of Warcraft\Interface\AddOns\TellMeWhen\]]
local paths = {
	[[TellMeWhen.xml]],
	[[TellMeWhen_Options\TellMeWhen_Options.xml]],
}
for _, path in pairs(paths) do
	local filepath = root .. path
	local t = io.open(filepath):read("*all")
	local orig = t
	print("\r\n" .. filepath)
	print("Start length:", #t)
	t = t:gsub(" ?>\n\t-<Offset>\n\t-<AbsDimension ([^\r\n]-) ?/>\n\t-</Offset>\n\t-</Anchor>", " %1/>")
	t = t:gsub(" ?>\n\t-<Offset ([^\r\n]-) ?/>\n\t-</Anchor>", " %1/>")
	t = t:gsub(" ?>\n\t-<AbsDimension ([^\r\n]-) ?/>\n\t-</Size>", " %1/>")
	t = t:gsub(" ?relativeTo=\"$parent\"", "")
	t = t:gsub(" x=\"0\"", "")
	t = t:gsub(" y=\"0\"", "")
	t = t:gsub(" />", "/>")

	local fmtstr = "(<Anchor point=\"%s\"[^\r\n]-)relativePoint=\"%s\" ?([^\r\n]-/>\n)"
	local tbl = {
		"LEFT",
		"RIGHT",
		"CENTER",
		"TOP",
		"BOTTOM",
		"TOPLEFT",
		"TOPRIGHT",
		"BOTTOMLEFT",
		"BOTTOMRIGHT",
	}
	for _, str in pairs(tbl) do
		t = t:gsub(fmtstr:format(str, str), "%1%2")
	end

	print("Ending length:", #t)
	if t ~= orig then
		io.open(filepath, "w"):write(t)
	else
		print("No changes made")
	end
end