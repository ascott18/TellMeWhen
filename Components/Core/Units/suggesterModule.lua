-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local UnitName, UnitClass, IsInRaid, GetNumGroupMembers, GetNumSubgroupMembers =
	  UnitName, UnitClass, IsInRaid, GetNumGroupMembers, GetNumSubgroupMembers
local GetNumRaidMembers, GetNumPartyMembers =
	  GetNumRaidMembers, GetNumPartyMembers
local strsub, select, pairs, strfind, wipe, strlower =
	  strsub, select, pairs, strfind, wipe, strlower

local SUG = TMW.SUG

local Module = SUG:NewModule("units", SUG:GetModule("default"))
Module.noMin = true
Module.noTexture = true
Module.table = TMW.UNITS.Units

function Module:Table_Get()
	return self.table
end

function Module:Entry_AddToList_1(f, index)

	local isSpecial = strsub(index, 1, 1) == "%"
	local prefix = isSpecial and strsub(index, 1, 2)
	
	if not isSpecial then
		local unitData = self.table[index]
		local unit = unitData.value
		

		if unitData.range then
			f.tooltiptitle = unitData.tooltipTitle or unitData.text
			f.tooltiptext = "|cFFFF0000#|r = 1-" .. unitData.range
			
			unit = unit .. " 1-" .. unitData.range
		elseif unitData.desc then
			f.tooltiptitle = unitData.tooltipTitle or unitData.text
			f.tooltiptext = unitData.desc
		end
		
		f.Name:SetText(unit)
		f.insert = unit
	else
	
		if prefix == "%P" then
			local name = strsub(index, 3)
			
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass(name))]
			
			-- GLOBALS: CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS
			if color.colorStr then
				color = "|c" .. color.colorStr
			else
				color = ("|cff%02x%02x%02x"):format(color.r * 0xFF, color.g * 0xFF, color.b * 0xFF)
			end
	
			f.Name:SetText(color .. name)
			f.insert = name
			
		elseif prefix == "%A" then
			local name = SUG.lastName_unmodified
			--name = name:gsub("^(%a)", strupper)
			f.Name:SetText(name)
			f.insert = name
		end
	end
	
	if not f.tooltiptitle then
		f.tooltiptitle = f.insert
	end
end

function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	
	for index, unitData in pairs(tbl) do
		--if strfind(unitData.value, atBeginning) then
			suggestions[#suggestions + 1] = index
	--	end
	end
end

function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	self:UpdateGroupedPlayersMap()
	
	for name in pairs(self.groupedPlayers) do
		if SUG.inputType == "number" or strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = "%P" .. name
		end
	end
	
	if #SUG.lastName > 0 then
		suggestions[#suggestions + 1] = "%A"
	end
	
	TMW.removeTableDuplicates(suggestions)
end

function Module.Sorter_Units(a, b)
	--sort by name
	
	local special_a, special_b = strsub(a, 1, 1), strsub(b, 1, 1)
	local prefix_a, prefix_b = strsub(a, 1, 2), strsub(b, 1, 2)
	
	local haveA, haveB = prefix_a == "%A", prefix_b == "%A"
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end
	
	local haveA, haveB = special_a ~= "%", special_b ~= "%"
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end
	
	local haveA, haveB = prefix_a == "%P", prefix_b == "%P"
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end
	
	--sort by index/alphabetical/whatever
	return a < b
end

function Module:Table_GetSorter()
	return self.Sorter_Units
end

Module.groupedPlayers = {}
function Module:UpdateGroupedPlayersMap()
	local groupedPlayers = self.groupedPlayers

	wipe(groupedPlayers)
	
	local numRaidMembers, numPartyMembers
	if TMW.ISMOP then
		numRaidMembers = IsInRaid() and GetNumGroupMembers() or 0
		
		numPartyMembers = GetNumSubgroupMembers()
	else		
		numRaidMembers = GetNumRaidMembers()
		
		numPartyMembers = GetNumPartyMembers()
	end	
	
	groupedPlayers[UnitName("player")] = true
	if UnitName("pet") then
		groupedPlayers[UnitName("pet")] = true
	end
	
	-- Raid Players
	for i = 1, numRaidMembers do
		local name = UnitName("raid" .. i)
		groupedPlayers[name] = true
	end
	
	-- Party Players
	for i = 1, numPartyMembers do
		local name = UnitName("party" .. i)
		groupedPlayers[name] = true
	end
end

