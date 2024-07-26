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
local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName

local _, pclass = UnitClass("Player")



local Module = SUG:NewModule("stances", SUG:GetModule("spell"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

Module.stances = (TMW.isWrath or TMW.isCata) and {
	WARRIOR = {
		[2457] = 	GetSpellName(2457), 	-- Battle Stance
		[71] = 		GetSpellName(71),		-- Defensive Stance
		[2458] = 	GetSpellName(2458), 	-- Berserker Stance
	},
	DRUID = {
		[5487] = 	GetSpellName(5487), 	-- Bear Form
		[9634] = 	GetSpellName(9634), 	-- Dire Bear Form
		[768] = 	GetSpellName(768),		-- Cat Form
		[783] = 	GetSpellName(783),		-- Travel Form
		[1066] = 	GetSpellName(1066),		-- Aquatic Form
		[24858] = 	GetSpellName(24858), 	-- Moonkin Form
		[33891] = 	GetSpellName(33891), 	-- Tree of Life
		[33943] = 	GetSpellName(33943), 	-- Flight Form
		[40120] = 	GetSpellName(40120), 	-- Swift Flight Form	
	},
	PRIEST = {
		[15473] = 	GetSpellName(15473), 	-- Shadowform	
	},
	ROGUE = {
		[1784] = 	GetSpellName(1784), 	-- Stealth	
	},
	PALADIN = {
		[19746] = 	GetSpellName(19746), 	-- Concentration Aura
		[32223] = 	GetSpellName(32223), 	-- Crusader Aura
		[465] = 	GetSpellName(465),		-- Devotion Aura
		[19900] = 	GetSpellName(19891), 	-- Fire Resistance Aura
		[19898] = 	GetSpellName(19891), 	-- Frost Resistance Aura
		[19896] = 	GetSpellName(19891), 	-- Shadow Resistance Aura
		[7294] = 	GetSpellName(7294),		-- Retribution Aura	
	},
	DEATHKNIGHT = {
		[48266] = 	GetSpellName(48266), 	-- Blood
		[48263] = 	GetSpellName(48263), 	-- Frost
		[48265] = 	GetSpellName(48265), 	-- Unholy
	},
} or TMW.isClassic and {
	WARRIOR = {
		[2457] = 	GetSpellName(2457), 	-- Battle Stance
		[71] = 		GetSpellName(71),		-- Defensive Stance
		[2458] = 	GetSpellName(2458), 	-- Berserker Stance
	},
	DRUID = {
		[5487] = 	GetSpellName(5487), 	-- Bear Form
		[768] = 	GetSpellName(768),		-- Cat Form
		[783] = 	GetSpellName(783),		-- Travel Form
		[24858] = 	GetSpellName(24858), 	-- Moonkin Form
	},
	PRIEST = {
		[15473] = 	GetSpellName(15473), 	-- Shadowform	
	},
	ROGUE = {
		[1784] = 	GetSpellName(1784), 	-- Stealth	
	},
} or {
	DRUID = {
		[5487] = 	GetSpellName(5487), 	-- Bear Form
		[768] = 	GetSpellName(768),		-- Cat Form
		[783] = 	GetSpellName(783),		-- Travel Form
		[24858] = 	GetSpellName(24858), 	-- Moonkin Form
		[33891] = 	GetSpellName(33891), 	-- Incarnation: Tree of Life
		[171745] = 	GetSpellName(171745), 	-- Claws of Shirvallah	
	},
	ROGUE = {
		[1784] = 	GetSpellName(1784), 	-- Stealth	
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
if C_Minimap and C_Minimap.GetTrackingInfo then
	local GetTrackingInfo = C_Minimap.GetTrackingInfo
	local GetNumTrackingTypes = C_Minimap.GetNumTrackingTypes
	-- Wow 11.0+
	
	function Module:Table_Get()
		for i = 1, GetNumTrackingTypes() do
			local data = GetTrackingInfo(i)
			TrackingCache[i] = strlower(data.name)
		end
		
		return TrackingCache
	end

	function Module:Entry_AddToList_1(f, id)
		local info = GetTrackingInfo(id)
	
		f.Name:SetText(info.name)
		f.ID:SetText(nil)
	
		f.tooltiptitle = info.name
		
		f.insert = info.name
	
		f.Icon:SetTexture(info.texture)
	end

elseif GetNumTrackingTypes and GetTrackingInfo and GetNumTrackingTypes() > 0 then
	function Module:Table_Get()
		for i = 1, GetNumTrackingTypes() do
			local name, _, active = GetTrackingInfo(i)
			TrackingCache[i] = strlower(name)
		end
		
		return TrackingCache
	end

	function Module:Entry_AddToList_1(f, id)
		local name, texture = GetTrackingInfo(id)
	
		f.Name:SetText(name)
		f.ID:SetText(nil)
	
		f.tooltiptitle = name
		
		f.insert = name
	
		f.Icon:SetTexture(texture)
	end
else
	-- WoW Classic
	for _, id in pairs{
		2580, -- Find Minerals
		2383, -- Find Herbs
		2481, -- Find Treasure
		1494, -- Track Beasts
		19878, -- Track Demons
		19879, -- Track Dragonkin
		19880, -- Track Elementals
		19882, -- Track Giants
		19885, -- Track Hidden
		5225, -- Track Humanoids (druid)
		19883, -- Track Humanoids
		19884, -- Track Undead
	} do
		local name = GetSpellName(id)
		TrackingCache[id] = strlower(name)
	end

	function Module:Table_Get()
		return TrackingCache
	end

	function Module:Entry_AddToList_1(f, id)
		local name, _, texture = GetSpellInfo(id)
	
		f.Name:SetText(name)
		f.ID:SetText(nil)
	
		f.tooltiptitle = name
		
		f.insert = name
	
		f.Icon:SetTexture(texture)
	end
end
function Module:Table_GetSorter()
	return nil
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
