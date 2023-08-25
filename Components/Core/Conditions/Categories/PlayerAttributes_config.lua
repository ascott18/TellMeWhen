-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache

local GetNumTrackingTypes = GetNumTrackingTypes or C_Minimap.GetNumTrackingTypes
local GetTrackingInfo = GetTrackingInfo or C_Minimap.GetTrackingInfo

local _, pclass = UnitClass("Player")



local Module = SUG:NewModule("stances", SUG:GetModule("spell"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

Module.stances = TMW.isWrath and {
	WARRIOR = {
		[2457] = 	GetSpellInfo(2457), 	-- Battle Stance
		[71] = 		GetSpellInfo(71),		-- Defensive Stance
		[2458] = 	GetSpellInfo(2458), 	-- Berserker Stance
	},
	DRUID = {
		[5487] = 	GetSpellInfo(5487), 	-- Bear Form
		[9634] = 	GetSpellInfo(9634), 	-- Dire Bear Form
		[768] = 	GetSpellInfo(768),		-- Cat Form
		[783] = 	GetSpellInfo(783),		-- Travel Form
		[1066] = 	GetSpellInfo(1066),		-- Aquatic Form
		[24858] = 	GetSpellInfo(24858), 	-- Moonkin Form
		[33891] = 	GetSpellInfo(33891), 	-- Tree of Life
		[33943] = 	GetSpellInfo(33943), 	-- Flight Form
		[40120] = 	GetSpellInfo(40120), 	-- Swift Flight Form	
	},
	PRIEST = {
		[15473] = 	GetSpellInfo(15473), 	-- Shadowform	
	},
	ROGUE = {
		[1784] = 	GetSpellInfo(1784), 	-- Stealth	
	},
	PALADIN = {
		[19746] = 	GetSpellInfo(19746), 	-- Concentration Aura
		[32223] = 	GetSpellInfo(32223), 	-- Crusader Aura
		[465] = 	GetSpellInfo(465),		-- Devotion Aura
		[19900] = 	GetSpellInfo(19891), 	-- Fire Resistance Aura
		[19898] = 	GetSpellInfo(19891), 	-- Frost Resistance Aura
		[19896] = 	GetSpellInfo(19891), 	-- Shadow Resistance Aura
		[7294] = 	GetSpellInfo(7294),		-- Retribution Aura	
	},
	DEATHKNIGHT = {
		[48266] = 	GetSpellInfo(48266), 	-- Blood
		[48263] = 	GetSpellInfo(48263), 	-- Frost
		[48265] = 	GetSpellInfo(48265), 	-- Unholy
	},
} or TMW.isClassic and {
	WARRIOR = {
		[2457] = 	GetSpellInfo(2457), 	-- Battle Stance
		[71] = 		GetSpellInfo(71),		-- Defensive Stance
		[2458] = 	GetSpellInfo(2458), 	-- Berserker Stance
	},
	DRUID = {
		[5487] = 	GetSpellInfo(5487), 	-- Bear Form
		[768] = 	GetSpellInfo(768),		-- Cat Form
		[783] = 	GetSpellInfo(783),		-- Travel Form
		[24858] = 	GetSpellInfo(24858), 	-- Moonkin Form
		[33891] = 	GetSpellInfo(33891), 	-- Incarnation: Tree of Life
	},
	PRIEST = {
		[15473] = 	GetSpellInfo(15473), 	-- Shadowform	
	},
	ROGUE = {
		[1784] = 	GetSpellInfo(1784), 	-- Stealth	
	},
} or {
	DRUID = {
		[5487] = 	GetSpellInfo(5487), 	-- Bear Form
		[768] = 	GetSpellInfo(768),		-- Cat Form
		[783] = 	GetSpellInfo(783),		-- Travel Form
		[24858] = 	GetSpellInfo(24858), 	-- Moonkin Form
		[33891] = 	GetSpellInfo(33891), 	-- Incarnation: Tree of Life
		[171745] = 	GetSpellInfo(171745), 	-- Claws of Shirvallah	
	},
	ROGUE = {
		[1784] = 	GetSpellInfo(1784), 	-- Stealth	
	},
}
function Module:Table_Get()
	return self.stances[pclass]
end
function Module:Entry_AddToList_1(f, spellID)
	if spellID == 0 then
		f.Name:SetText(NONE)

		f.tooltiptitle = NONE

		f.insert = NONE

		f.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	else
		local name, _, tex = GetSpellInfo(spellID)

		f.Name:SetText(name)

		f.tooltipmethod = TMW.GameTooltip_SetSpellByIDWithClassIcon
		f.tooltiparg = spellID

		f.insert = name

		f.Icon:SetTexture(tex)
	end
end
function Module:Table_GetNormalSuggestions(suggestions, tbl)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	for id, name in pairs(tbl) do
		if strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = id
		end
	end
end
function Module:Table_GetSpecialSuggestions_1(suggestions)
	local atBeginning = SUG.atBeginning
	if strfind(strlower(NONE), atBeginning) then
		suggestions[#suggestions + 1] = 0
	end
end



local Module = SUG:NewModule("tracking", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

local TrackingCache = {}
function Module:Table_Get()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		TrackingCache[i] = strlower(name)
	end
	
	return TrackingCache
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, id)
	local name, texture = GetTrackingInfo(id)

	f.Name:SetText(name)
	f.ID:SetText(nil)

	f.tooltiptitle = name
	
	f.insert = name

	f.Icon:SetTexture(texture)
end


if C_EquipmentSet then
	local Module = SUG:NewModule("blizzequipset", SUG:GetModule("default"))
	Module.noMin = true
	Module.showColorHelp = false
	Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

	local EquipSetCache = {}
	function Module:Table_Get()
		for i, id in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
			local name, icon = C_EquipmentSet.GetEquipmentSetInfo(id)

			EquipSetCache[id] = strlower(name)
		end
		
		return EquipSetCache
	end
	function Module:Table_GetSorter()
		return nil
	end
	function Module:Entry_AddToList_1(f, id)
		local name, icon = C_EquipmentSet.GetEquipmentSetInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltipmethod = "SetEquipmentSet"
		f.tooltiparg = name

		f.insert = name

		f.Icon:SetTexture(icon)
	end
end
