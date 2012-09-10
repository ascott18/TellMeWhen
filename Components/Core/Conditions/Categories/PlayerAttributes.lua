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

local CNDT = TMW.CNDT
local Env = CNDT.Env
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")

local IsInInstance, GetInstanceDifficulty, GetNumShapeshiftForms, GetShapeshiftFormInfo = 
	  IsInInstance, GetInstanceDifficulty, GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetTalentInfo, GetNumTalentTabs, GetNumTalents, GetGlyphLink, GetSpellInfo = 
	  GetTalentInfo, GetNumTalentTabs, GetNumTalents, GetGlyphLink, GetSpellInfo
local GetPetActionInfo, GetNumTrackingTypes, GetTrackingInfo = 
	  GetPetActionInfo, GetNumTrackingTypes, GetTrackingInfo
	  
	  
local ConditionCategory = CNDT:GetCategory("ATTRIBUTES_PLAYER", 2, L["CNDTCAT_ATTRIBUTES_PLAYER"], true, false)

ConditionCategory:RegisterCondition(1,	 "INSTANCE", {
	text = L["CONDITIONPANEL_INSTANCETYPE"],
	min = 0,
	max = 9,
	unit = false,
	texttable = {
		[0] = NONE,
		[1] = BATTLEGROUND,
		[2] = ARENA,
		[3] = DUNGEON_DIFFICULTY1,
		[4] = DUNGEON_DIFFICULTY2,
		[5] = RAID_DIFFICULTY1,
		[6] = RAID_DIFFICULTY2,
		[7] = RAID_DIFFICULTY3,
		[8] = RAID_DIFFICULTY4,
		[9] = RAID_FINDER,
	},
	icon = "Interface\\Icons\\Spell_Frost_Stun",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetZoneType = function()
			local _, z = IsInInstance()
			if z == "pvp" then
				return 1
			elseif z == "arena" then
				return 2
			elseif z == "party" then
				return 2 + GetInstanceDifficulty() --3-4
			elseif z == "raid" then
				if IsPartyLFG() then
					return 9
				else
					return 4 + GetInstanceDifficulty() --5-8
				end
			else
				return 0
			end
		end,
	},
	funcstr = [[GetZoneType() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("ZONE_CHANGED_NEW_AREA"),
			ConditionObject:GenerateNormalEventString("PLAYER_DIFFICULTY_CHANGED")
	end,
})
ConditionCategory:RegisterCondition(2,	 "GROUP", {
	text = L["CONDITIONPANEL_GROUPTYPE"],
	min = 0,
	max = 2,
	midt = true,
	unit = false,
	texttable = {[0] = SOLO, [1] = PARTY, [2] = RAID},
	icon = "Interface\\Calendar\\MeetingIcon",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsInRaid = IsInRaid, -- TMW.ISMOP
		IsInGroup = IsInGroup, -- TMW.ISMOP
		GetNumRaidMembers = GetNumRaidMembers, -- not TMW.ISMOP
		GetNumPartyMembers = GetNumPartyMembers, -- not TMW.ISMOP
	},
	funcstr = TMW.ISMOP and [[((IsInRaid() and 2) or (IsInGroup() and 1) or 0) c.Operator c.Level]] or
		[[((GetNumRaidMembers() > 0 and 2) or (GetNumPartyMembers() > 0 and 1) or 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		if TMW.ISMOP then
			return
				ConditionObject:GenerateNormalEventString("GROUP_ROSTER_UPDATE")
		else
			return
				ConditionObject:GenerateNormalEventString("PARTY_MEMBERS_CHANGED"),
				ConditionObject:GenerateNormalEventString("RAID_ROSTER_UPDATE")
		end
	end,
})

ConditionCategory:RegisterSpacer(2.5)

ConditionCategory:RegisterCondition(3,	 "MOUNTED", {
	text = L["CONDITIONPANEL_MOUNTED"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_Mount_Charger",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsMounted = IsMounted,
	},
	funcstr = [[c.1nil == IsMounted()]],
})
ConditionCategory:RegisterCondition(4,	 "SWIMMING", {
	text = L["CONDITIONPANEL_SWIMMING"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsSwimming = IsSwimming,
	},
	funcstr = [[c.1nil == IsSwimming()]],
	--events = absolutely no events (SPELL_UPDATE_USABLE is close, but not close enough)
})
ConditionCategory:RegisterCondition(5,	 "RESTING", {
	text = L["CONDITIONPANEL_RESTING"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\CHARACTERFRAME\\UI-StateIcon",
	tcoords = {0.0625, 0.453125, 0.046875, 0.421875},
	Env = {
		IsResting = IsResting,
	},
	funcstr = [[c.1nil == IsResting()]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_UPDATE_RESTING"),
			ConditionObject:GenerateNormalEventString("PLAYER_ENTERING_WORLD")
	end,
})

local NumShapeshiftForms
local GetShapeshiftForm = GetShapeshiftForm
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	NumShapeshiftForms = GetNumShapeshiftForms()
end)


ConditionCategory:RegisterSpacer(5.5)

local FirstStances = {
	WARRIOR = 2457, 	-- Battle Stance
	DRUID = 5487, 		-- Bear Form
	PRIEST = 15473, 	-- Shadowform
	ROGUE = 1784, 		-- Stealth
	HUNTER = 82661, 	-- Aspect of the Fox
	DEATHKNIGHT = 48263,-- Blood Presence
	PALADIN = TMW.ISMOP and 105361 or 19746, 	-- Seal of Command/Concentration Aura
	WARLOCK = 103958, 	-- Metamorphosis
	MONK = 103985, 		-- Fierce Tiger
}
ConditionCategory:RegisterCondition(6,	 "STANCE", {
	text = 	pclass == "HUNTER" and L["ASPECT"] or
			pclass == "PALADIN" and (TMW.ISMOP and L["SEAL"] or L["AURA"]) or
			pclass == "DEATHKNIGHT" and L["PRESENCE"] or
			pclass == "DRUID" and L["SHAPESHIFT"] or
			--pclass == "WARRIOR" and L["STANCE"] or
			--pclass == "MONK" and L["STANCE"] or
			L["STANCE"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	name = function(editbox)
		TMW:TT(editbox, "STANCE", "STANCE_DESC")
		editbox.label = L["STANCE_LABEL"]
	end,
	useSUG = "stances",
	allowMultipleSUGEntires = true,
	unit = PLAYER,
	icon = function()
		return GetSpellTexture(FirstStances[pclass] or FirstStances.WARRIOR)
	end,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetShapeshiftForm = function()
			-- very hackey function because of inconsistencies in blizzard's GetShapeshiftForm
			local i = GetShapeshiftForm()
			if pclass == "ROGUE" and i > 1 then	--vanish and shadow dance return 3 when active, vanish returns 2 when shadow dance isnt learned. Just treat everything as stealth
				i = 1
			end
			if i > NumShapeshiftForms then 	--many Classes return an invalid number on login, but not anymore!
				i = 0
			end

			if i == 0 then
				return NONE
			else
				local _, name = GetShapeshiftFormInfo(i)
				return name or ""
			end
		end
	},
	funcstr = [[c.1nil == (strfind(c.Name, SemicolonConcatCache[GetShapeshiftForm() or ""]) and 1)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UPDATE_SHAPESHIFT_FORM")
	end,
	hidden = not FirstStances[pclass],
})

ConditionCategory:RegisterCondition(7,	 "SPEC", {
	text = L["UIPANEL_SPEC"],
	min = 1,
	max = 2,
	texttable = {
		[1] = L["UIPANEL_PRIMARYSPEC"],
		[2] = L["UIPANEL_SECONDARYSPEC"],
	},
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\achievement_general",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetActiveTalentGroup = GetActiveTalentGroup,
		GetActiveSpecGroup = GetActiveSpecGroup, --ISMOP
	},
	funcstr = TMW.ISMOP and [[c.Level == GetActiveSpecGroup()]] or [[c.Level == GetActiveTalentGroup()]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})

if TMW.ISMOP then
	ConditionCategory:RegisterCondition(8,	 "TREE", {
		text = L["UIPANEL_SPECIALIZATION"],
		min = 1,
		max = GetNumSpecializations,
		midt = true,
		texttable = function(i) return select(2, GetSpecializationInfo(i)) end,
		unit = PLAYER,
		icon = function() return select(4, GetSpecializationInfo(1)) end,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			GetSpecialization = GetSpecialization
		},
		funcstr = [[(GetSpecialization() or 0) c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED")
		end,
	})
else
	ConditionCategory:RegisterCondition(8,	 "TREE", {
		text = L["UIPANEL_TREE"],
		min = 1,
		max = 3,
		midt = true,
		texttable = function(i) return select(2, GetTalentTabInfo(i)) end,
		unit = PLAYER,
		icon = function() return select(4, GetTalentTabInfo(1)) end,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			GetPrimaryTalentTree = GetPrimaryTalentTree
		},
		funcstr = [[GetPrimaryTalentTree() c.Operator c.Level]],
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	})
end



CNDT.Env.TalentMap = {}
function CNDT:PLAYER_TALENT_UPDATE()
	if TMW.ISMOP then
		for talent = 1, MAX_NUM_TALENTS do
			local name, _, _, _, selected = GetTalentInfo(talent)
			local lower = name and strlowerCache[name]
			if lower then
				Env.TalentMap[lower] = selected and 1 or nil
			end
		end
	else
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				local name, _, _, _, rank = GetTalentInfo(tab, talent)
				local lower = name and strlowerCache[name]
				if lower then
					Env.TalentMap[lower] = rank or 0
				end
			end
		end
	end
end
ConditionCategory:RegisterCondition(9,	 "TALENTLEARNED", {
	text = L["UIPANEL_TALENTLEARNED"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "talents",
	icon = function() return select(2, GetTalentInfo(1)) end,
	tcoords = CNDT.COMMON.standardtcoords,
	hidden = not TMW.ISMOP,
	funcstr = [[TalentMap[LOWER(c.NameName)] == c.1nil]],
	events = function(ConditionObject, c)
		-- this is handled externally because TalentMap is so extensive a process,
		-- and if it does get stuck in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
		CNDT:PLAYER_TALENT_UPDATE()
		
		-- we still only need to update the condition when talents change, though.
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})
ConditionCategory:RegisterCondition(10,	 "PTSINTAL", {
	text = L["UIPANEL_PTSINTAL"],
	min = 0,
	max = 5,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "talents",
	icon = function() return select(2, GetTalentInfo(1, 1)) end,
	tcoords = CNDT.COMMON.standardtcoords,
	hidden = TMW.ISMOP,
	funcstr = function(c)
		-- Brilliant hack that will automatically upgrade to the MOP version of the condition when it is processed.
		-- This upgrade is kinda bad because we went from a number comparison to a boolean check, but we should at least put the level down to a valid value.
		-- Users are going to need to redo their conditions anyway for gameplay reasons, so I'm not to worried about a poor upgrade here.
		if TMW.ISMOP then
			c.Type = "TALENTLEARNED"
			if c.Level > 1 then
				c.Level = 0
			end
			return CNDT.ConditionsByType.TALENTLEARNED.funcstr
		else
			return [[(TalentMap[LOWER(c.NameName)] or 0) c.Operator c.Level]]
		end
	end,
	events = function(ConditionObject, c)
		-- this is handled externally because TalentMap is so extensive a process,
		-- and if it does get stuck in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
		CNDT:PLAYER_TALENT_UPDATE()
		
		-- we still only need to update the condition when talents change, though.
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})




local GetGlyphSocketInfo = GetGlyphSocketInfo
function CNDT:GLYPH_UPDATED()
	local GlyphLookup = Env.GlyphLookup
	wipe(GlyphLookup)
	for i = 1, NUM_GLYPH_SLOTS do
		local _, _, _, spellID = GetGlyphSocketInfo(i)
		local link = GetGlyphLink(i)
		local glyphID = tonumber(strmatch(link, "|H.-:(%d+)"))
		
		if glyphID then
			GlyphLookup[glyphID] = true
			
			local name = GetSpellInfo(spellID)
			name = strlowerCache[name]
			GlyphLookup[name] = true
		end
	end
end
ConditionCategory:RegisterCondition(11,	 "GLYPH", {
	text = L["UIPANEL_GLYPH"],
	tooltip = L["UIPANEL_GLYPH_DESC"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "GLYPHTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["GLYPHTOCHECK"] end,
	nooperator = true,
	useSUG = "glyphs",
	icon = "Interface\\Icons\\inv_inscription_tradeskill01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GlyphLookup[c.NameFirst] == c.True]],
	Env = {
		GlyphLookup = {},
	},
	events = function(ConditionObject, c)
		-- this is handled externally because GlyphLookup is so extensive a process,
		-- and if it does get stuck in an OnUpdate condition, it could be very bad.

		CNDT:RegisterEvent("GLYPH_ADDED", 	 "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_DISABLED", "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_ENABLED",  "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_REMOVED",  "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_UPDATED",  "GLYPH_UPDATED")
		CNDT:GLYPH_UPDATED()
		-- we still only need to update the condition when glyphs change, though.
		
		return
			ConditionObject:GenerateNormalEventString("GLYPH_ADDED"),
			ConditionObject:GenerateNormalEventString("GLYPH_DISABLED"),
			ConditionObject:GenerateNormalEventString("GLYPH_ENABLED"),
			ConditionObject:GenerateNormalEventString("GLYPH_REMOVED"),
			ConditionObject:GenerateNormalEventString("GLYPH_UPDATED")
	end,
})

ConditionCategory:RegisterSpacer(11.5)

ConditionCategory:RegisterCondition(12,	 "AUTOCAST", {
	text = L["CONDITIONPANEL_AUTOCAST"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = PET,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_AUTOCAST", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = true,
	icon = "Interface\\Icons\\ability_physical_taunt",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellAutocast = GetSpellAutocast,
	},
	funcstr = [[select(2, GetSpellAutocast(c.NameName)) == c.1nil]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PET_BAR_UPDATE")
	end,
})

local PetModes = {
	select(4, GetBuildInfo()) >= 40200 and "PET_MODE_ASSIST" or "PET_MODE_AGGRESSIVE",
	"PET_MODE_DEFENSIVE",
	"PET_MODE_PASSIVE",
}
for k, v in pairs(PetModes) do
	PetModes[v] = k
end
ConditionCategory:RegisterCondition(13,	 "PETMODE", {
	text = L["CONDITIONPANEL_PETMODE"],
	min = 1,
	max = 3,
	midt = true,
	texttable = function(k) return _G[PetModes[k]] end,
	unit = PET,
	icon = PET_ASSIST_TEXTURE,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetActivePetMode = function()
			for i = NUM_PET_ACTION_SLOTS, 1, -1 do -- go backwards since they are probably at the end of the action bar
				local name, _, _, isToken, isActive = GetPetActionInfo(i)
				if isToken and isActive and PetModes[name] then
					return PetModes[name]
				end
			end
		end,
	},
	funcstr = [[GetActivePetMode() c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PET_BAR_UPDATE")
	end,
})

ConditionCategory:RegisterCondition(14,	 "PETSPEC", {
	text = L["CONDITIONPANEL_PETSPEC"],
	min = 0,
	max = 3,
	midt = true,
	texttable = {
		[0] = NONE,
		L["PET_TYPE_FEROCITY"],
		L["PET_TYPE_TENACITY"],
		L["PET_TYPE_CUNNING"],
	},
	unit = PET,
	icon = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpecialization = GetSpecialization
	},
	funcstr = [[(GetSpecialization(nil, true) or 0) c.Operator c.Level]],
	hidden = pclass ~= "HUNTER" or not TMW.ISMOP,
	--events = function(ConditionObject, c)
	--MAYBE WRONG EVENTS, CHECK BEFORE UNCOMMENTING
	--	return
	--		ConditionObject:GenerateNormalEventString("UNIT_PET", "player")
	--end,
})
ConditionCategory:RegisterCondition(15,	 "PETTREE", {
	text = L["CONDITIONPANEL_PETTREE"],
	min = 409,
	max = 411,
	midt = true,
	texttable = {
		[409] = L["PET_TYPE_TENACITY"],
		[410] = L["PET_TYPE_FEROCITY"],
		[411] = L["PET_TYPE_CUNNING"],
	},
	unit = PET,
	icon = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetTalentTabInfo = GetTalentTabInfo
	},
	funcstr = function(c)
		-- Brilliant hack that will automatically upgrade to the MOP version of the condition when it is processed.
		if TMW.ISMOP then
			c.Type = "PETSPEC"
			
			if c.Level == 409 then -- old tenacity
				c.Level = 2 -- new tenacity
			elseif c.Level == 410 then -- old ferocity
				c.Level = 1 -- new ferocity
			elseif c.Level == 411 then -- old cunning
				c.Level = 3 -- new cunning
			end
			
			return CNDT.ConditionsByType.PETSPEC.funcstr
		else
			return [[(GetTalentTabInfo(1, nil, 1) or 0) c.Operator c.Level]]
		end
	end,
	hidden = pclass ~= "HUNTER" or TMW.ISMOP,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_PET", "player")
	end,
})


ConditionCategory:RegisterSpacer(15.5)


Env.Tracking = {}
function CNDT:MINIMAP_UPDATE_TRACKING()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		Env.Tracking[strlower(name)] = active
	end
end
ConditionCategory:RegisterCondition(16,	 "TRACKING", {
	text = L["CONDITIONPANEL_TRACKING"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_TRACKING", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "tracking",
	icon = "Interface\\MINIMAP\\TRACKING\\None",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[Tracking[c.NameName] == c.1nil]],
	events = function(ConditionObject, c)
		-- this event handling it is really extensive, so keep it in a separate process
		CNDT:RegisterEvent("MINIMAP_UPDATE_TRACKING")
		CNDT:MINIMAP_UPDATE_TRACKING()
		
		-- Tell the condition to also update when MINIMAP_UPDATE_TRACKING fires
		return
			ConditionObject:GenerateNormalEventString("MINIMAP_UPDATE_TRACKING")
	end,
})

