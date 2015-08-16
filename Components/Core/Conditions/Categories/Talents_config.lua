-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")


local Module = SUG:NewModule("glyphs", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	for i = 1, GetNumGlyphs() do
		local type, _, _, _, glyphID, link = GetGlyphInfo(i)
		if type ~= "header" then
			local _, name = strmatch(link, "|Hglyph:(%d+)|h%[(.*)%]|h|r")
			name = strlowerCache[name]
			self.table[i] = name
		end
	end
end
function Module:Table_Get()
	return self.table
end
function Module:Entry_AddToList_1(f, index)
	local _, _, _, texture, glyphID, link = GetGlyphInfo(index)
	local _, name = strmatch(link, "|Hglyph:(%d+)|h%[(.*)%]|h|r")

	f.Name:SetText(name)
	f.ID:SetText(glyphID)

	f.tooltipmethod = "SetGlyphByID"
	f.tooltiparg = glyphID

	f.insert = SUG.inputType == "number" and glyphID or name
	f.insert2 = SUG.inputType ~= "number" and glyphID or name

	f.Icon:SetTexture(texture)
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for index, name in pairs(tbl) do
			local _, _, _, _, id = GetGlyphInfo(index)
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = index
			end
		end
	else
		for index, name in pairs(tbl) do
			local matcher = lastName
			if #lastName < 2 then
				matcher = atBeginning
			end
			
			-- name here is Glyph of Fancy Spell
			if strfind(name, matcher) then
				suggestions[#suggestions + 1] = index
			else
			
				-- name here is Fancy Spell
				name = GetGlyphInfo(index)
				name = strlowerCache[name]
				if strfind(name, matcher) then
					suggestions[#suggestions + 1] = index
				end
			end
		end
	end
end
function Module.Sorter_Glyphs(a, b)
	if SUG.inputType == "number" then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = Module.table[a], Module.table[b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Glyphs
end



local Module = SUG:NewModule("talents", SUG:GetModule("spell"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)

	for spec = 1, MAX_TALENT_GROUPS do
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, name = GetTalentInfo(tier, column, spec)
				
				local lower = name and strlowerCache[name]
				if lower then
					self.table[id] = lower
				end
			end
		end
	end

	return self.table
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, id)
	local id, name, iconTexture = GetTalentInfoByID(id) -- restore case

	f.Name:SetText(name)
	f.ID:SetText(id)

	f.tooltipmethod = "SetHyperlink"
	f.tooltiparg = GetTalentLink(id)

	f.insert = name
	f.insert2 = id

	f.Icon:SetTexture(iconTexture)
end
Module.Entry_Colorize_1 = TMW.NULLFUNC