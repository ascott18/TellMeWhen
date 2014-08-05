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

local CNDT = TMW.CNDT
local Env = CNDT.Env
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")

local clientVersion = select(4, GetBuildInfo())
local wow_502 = clientVersion >= 50200

local IsInInstance, GetInstanceDifficulty, GetNumShapeshiftForms, GetShapeshiftFormInfo = 
	  IsInInstance, GetInstanceDifficulty, GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetTalentInfo, GetNumTalentTabs, GetNumTalents, GetGlyphLink, TMW_GetSpellInfo = 
	  GetTalentInfo, GetNumTalentTabs, GetNumTalents, GetGlyphLink, TMW_GetSpellInfo
local GetPetActionInfo, GetNumTrackingTypes, GetTrackingInfo = 
	  GetPetActionInfo, GetNumTrackingTypes, GetTrackingInfo
	  
	  
local ConditionCategory = CNDT:GetCategory("ATTRIBUTES_PLAYER", 2, L["CNDTCAT_ATTRIBUTES_PLAYER"], true, false)

ConditionCategory:RegisterCondition(1,	 "INSTANCE", {	-- old
	text = L["CONDITIONPANEL_INSTANCETYPE"],

	old = true,

	min = 0,
	max = 11,
	unit = false,
	texttable = {
		[0] = NONE,
		[1] = BATTLEGROUND,
		[2] = ARENA,
		[3] = DUNGEON_DIFFICULTY_5PLAYER,
		[4] = DUNGEON_DIFFICULTY_5PLAYER_HEROIC,
		[5] = RAID_DIFFICULTY_10PLAYER,
		[6] = RAID_DIFFICULTY_25PLAYER,
		[7] = RAID_DIFFICULTY_10PLAYER_HEROIC,
		[8] = RAID_DIFFICULTY_25PLAYER_HEROIC,
		[9] = RAID_FINDER,
		[10] = CHALLENGE_MODE,
		[11] = RAID_DIFFICULTY_40PLAYER,
	},
	icon = "Interface\\Icons\\Spell_Frost_Stun",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetZoneType = function()
			local _, z = IsInInstance()
			local instanceDifficulty
			
			if wow_502 then
				_, _, instanceDifficulty = GetInstanceInfo()
			else
				instanceDifficulty = GetInstanceDifficulty() - 1
			end
			
			if z == "pvp" then
				-- Battleground (1)
				return 1
			elseif z == "arena" then
				-- Arena (2)
				return 2
			elseif instanceDifficulty == 0 then
				-- None (0)
				return 0
			else
				-- 5 man normal (3)
				-- 5 man heroic (4)
				-- 10 man normal (5)
				-- 25 man normal (6)
				-- 10 man heroic (7)
				-- 25 man heroic (8)
				-- LFR (9)
				-- Challenge Mode (10)
				-- 40 man (11)
				return 2 + instanceDifficulty --3-11
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
ConditionCategory:RegisterCondition(1,	 "INSTANCE2", {
	text = L["CONDITIONPANEL_INSTANCETYPE"],

	unit = false,
	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU"]:format(L["CONDITIONPANEL_INSTANCETYPE"]),
	bitFlags = {
		------ DON'T REMOVE ANYTHING WITHOUT REPLACING IT WITH AN EXPLICIT NIL! ------
		L["CONDITIONPANEL_INSTANCETYPE_NONE"],												--[ 1,  0x0     ]
		BATTLEGROUND,																		--[ 2,  0x1     ]
		ARENA,																				--[ 3,  0x2     ]
		DUNGEON_DIFFICULTY_5PLAYER,															--[ 4,  0x4     ]
		DUNGEON_DIFFICULTY_5PLAYER_HEROIC,													--[ 5,  0x8     ]
		L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_10PLAYER),			--[ 6,  0x10    ]
		L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_25PLAYER),			--[ 7,  0x20    ]
		L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_10PLAYER_HEROIC),	--[ 8,  0x40    ]
		L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_25PLAYER_HEROIC),	--[ 9,  0x80    ]
		L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_FINDER),						--[ 10, 0x100   ]
		CHALLENGE_MODE,																		--[ 11, 0x200   ]
		L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_40PLAYER),			--[ 12, 0x400   ]
		HEROIC_SCENARIO,																	--[ 13, 0x800   ]
		GUILD_CHALLENGE_TYPE4,																--[ 14, 0x1000  ] (regular scenario)
		format("%s (%s)", PLAYER_DIFFICULTY1, FLEX_RAID),									--[ 15, 0x2000  ] (Warlords Normal Flex)
		format("%s (%s)", PLAYER_DIFFICULTY2, FLEX_RAID),									--[ 16, 0x4000  ] (Warlords Heroic Flex)
		PLAYER_DIFFICULTY6,																	--[ 17, 0x8000  ] (Warlords Mythic)
		format("%s (%s)", PLAYER_DIFFICULTY3, FLEX_RAID),									--[ 18, 0x10000 ] (Warlords LFR Flex)
	},

	icon = "Interface\\Icons\\Spell_Frost_Stun",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetZoneType2 = function()
			local _, z = IsInInstance()
			local instanceDifficulty
			
			if wow_502 then
				_, _, instanceDifficulty = GetInstanceInfo()
			else
				instanceDifficulty = GetInstanceDifficulty() - 1
			end
			
			if z == "pvp" then
				-- Battleground (2)
				return 2
			elseif z == "arena" then
				-- Arena (3)
				return 3
			elseif instanceDifficulty == 0 then
				-- None (1)
				return 1
			else
				-- 5 man normal (4)
				-- 5 man heroic (5)
				-- 10 man normal (6)
				-- 25 man normal (7)
				-- 10 man heroic (8)
				-- 25 man heroic (9)
				-- LFR (10)
				-- Challenge Mode (11)
				-- 40 man (12)
				if instanceDifficulty <= 9 then
					return 3 + instanceDifficulty -- 4-12
				end

				-- heroic scenario (13)
				-- scenario (14)
				if instanceDifficulty <= 12 then
					return 2 + instanceDifficulty --13-14
				end

				-- Normal Flex (15)
				-- Heroic Flex (16)
				-- Mythic (17)
				-- LFR Flex (18)
				return 1 + instanceDifficulty
			end
		end,
	},
	funcstr = [[BITFLAGSMAPANDCHECK(GetZoneType2())]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("ZONE_CHANGED_NEW_AREA"),
			ConditionObject:GenerateNormalEventString("PLAYER_DIFFICULTY_CHANGED")
	end,
})


ConditionCategory:RegisterCondition(2,	 "GROUP", {		-- old
	text = L["CONDITIONPANEL_GROUPTYPE"],
	old = true,

	min = 0,
	max = 2,
	midt = true,
	unit = false,
	texttable = {[0] = SOLO, [1] = PARTY, [2] = RAID},
	icon = "Interface\\Calendar\\MeetingIcon",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsInRaid = IsInRaid,
		IsInGroup = IsInGroup,
	},
	funcstr = [[((IsInRaid() and 2) or (IsInGroup() and 1) or 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("GROUP_ROSTER_UPDATE")
	end,
})
ConditionCategory:RegisterCondition(2,	 "GROUP2", {
	text = L["CONDITIONPANEL_GROUPTYPE"],

	unit = false,
	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU"]:format(L["CONDITIONPANEL_GROUPTYPE"]),
	bitFlags = {
		------ DON'T REMOVE ANYTHING WITHOUT REPLACING IT WITH AN EXPLICIT NIL! ------
		SOLO,			--[ 1,  0x0    ]
		PARTY,			--[ 2,  0x1    ]
		RAID,			--[ 3,  0x2    ]
	},

	icon = "Interface\\Calendar\\MeetingIcon",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsInRaid = IsInRaid,
		IsInGroup = IsInGroup,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( ((IsInRaid() and 3) or (IsInGroup() and 2) or 1) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("GROUP_ROSTER_UPDATE")
	end,
})

ConditionCategory:RegisterCondition(2.1, "GROUPSIZE", {
	text = L["CONDITIONPANEL_GROUPSIZE"],
	tooltip = L["CONDITIONPANEL_GROUPSIZE_DESC"],
	min = 0,
	max = 40,
	icon = "Interface\\Icons\\spell_deathknight_armyofthedead",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetInstanceInfo = GetInstanceInfo,
	},
	funcstr = [[select(9, GetInstanceInfo()) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("INSTANCE_GROUP_SIZE_CHANGED"),
			ConditionObject:GenerateNormalEventString("UPDATE_INSTANCE_INFO")
	end,
})

ConditionCategory:RegisterSpacer(2.5)

ConditionCategory:RegisterCondition(3,	 "MOUNTED", {
	text = L["CONDITIONPANEL_MOUNTED"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_Mount_Charger",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsMounted = IsMounted,
	},
	funcstr = [[BOOLCHECK( IsMounted() )]],
})
ConditionCategory:RegisterCondition(4,	 "SWIMMING", {
	text = L["CONDITIONPANEL_SWIMMING"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsSwimming = IsSwimming,
	},
	funcstr = [[BOOLCHECK( IsSwimming() )]],
	--events = absolutely no events (SPELL_UPDATE_USABLE is close, but not close enough)
})
ConditionCategory:RegisterCondition(5,	 "RESTING", {
	text = L["CONDITIONPANEL_RESTING"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\CHARACTERFRAME\\UI-StateIcon",
	tcoords = {0.0625, 0.453125, 0.046875, 0.421875},
	Env = {
		IsResting = IsResting,
	},
	funcstr = [[BOOLCHECK( IsResting() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_UPDATE_RESTING"),
			ConditionObject:GenerateNormalEventString("PLAYER_ENTERING_WORLD")
	end,
})
ConditionCategory:RegisterCondition(5.2, "INPETBATTLE", {
	text = L["CONDITIONPANEL_INPETBATTLE"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\pet_type_critter",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsInBattle = C_PetBattles.IsInBattle,
	},
	funcstr = [[BOOLCHECK( IsInBattle() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PET_BATTLE_OPENING_START"),
			ConditionObject:GenerateNormalEventString("PET_BATTLE_CLOSE")
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
	HUNTER = 13165, 	-- Aspect of the Fox
	DEATHKNIGHT = 48263,-- Blood Presence
	PALADIN = 105361, 	-- Seal of Command
	WARLOCK = 103958, 	-- Metamorphosis
	MONK = 103985, 		-- Fierce Tiger
}
ConditionCategory:RegisterCondition(6,	 "STANCE", {
	text = 	pclass == "HUNTER" and L["ASPECT"] or
			pclass == "PALADIN" and L["SEAL"] or
			pclass == "DEATHKNIGHT" and L["PRESENCE"] or
			pclass == "DRUID" and L["SHAPESHIFT"] or
			--pclass == "WARRIOR" and L["STANCE"] or
			--pclass == "MONK" and L["STANCE"] or
			L["STANCE"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	name = function(editbox)
		TMW:TT(editbox, "STANCE", "STANCE_DESC")
		editbox.label = L["STANCE_LABEL"]
	end,
	useSUG = "stances",
	allowMultipleSUGEntires = true,
	unit = PLAYER,
	icon = function()
		return GetSpellTexture(FirstStances[pclass] or FirstStances.WARRIOR) or GetSpellTexture(FirstStances.WARRIOR)
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
	funcstr = [[BOOLCHECK( (strfind(c.Name, SemicolonConcatCache[GetShapeshiftForm() or ""]) and 1) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UPDATE_SHAPESHIFT_FORM")
	end,
	hidden = not FirstStances[pclass],
})


ConditionCategory:RegisterSpacer(6.5)


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
		GetActiveSpecGroup = GetActiveSpecGroup,
	},
	funcstr = [[c.Level == GetActiveSpecGroup()]],
	events = function(ConditionObject, c)
		return
			--ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			--ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})

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


local SpeclizationRoles = {
	TANK = 1,
	DAMAGER = 2,
	HEALER = 3,
}
ConditionCategory:RegisterCondition(8.1, "TREEROLE", {
	text = L["UIPANEL_SPECIALIZATIONROLE"],
	tooltip = L["UIPANEL_SPECIALIZATIONROLE_DESC"],
	min = 1,
	max = 3,
	midt = true,
	texttable = function(i)
		for k, v in pairs(SpeclizationRoles) do
			if i == v then
				return _G[k]
			end
		end
	end,
	unit = PLAYER,
	icon = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES",
	tcoords = {GetTexCoordsForRole("HEALER")},
	Env = {
		GetSpecialization = GetSpecialization,
		GetSpecializationInfo = GetSpecializationInfo,
		SpeclizationRoles = SpeclizationRoles,
	},
	funcstr = [[(SpeclizationRoles[select(6, GetSpecializationInfo(GetSpecialization() or 0))] or 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED")
	end,
})


ConditionCategory:RegisterSpacer(8.9)

CNDT.Env.TalentMap = {}
function CNDT:PLAYER_TALENT_UPDATE()
	for tier = 1, MAX_TALENT_TIERS do
		for column = 1, NUM_TALENT_COLUMNS do
			local id, name, _, selected = GetTalentInfo(tier, column, GetActiveSpecGroup())
			local lower = name and strlowerCache[name]
			if lower then
				Env.TalentMap[lower] = selected and 1 or nil
				Env.TalentMap[id] = selected and 1 or nil
			end
		end
	end
end
ConditionCategory:RegisterCondition(9,	 "TALENTLEARNED", {
	text = L["UIPANEL_TALENTLEARNED"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "SPELLTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "talents",
	icon = function() return select(2, GetTalentInfo(1, 1, 1)) end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(ConditionObject, c)
		-- this is handled externally because TalentMap is so extensive a process,
		-- and if it ends up getting processed in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
		CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
		CNDT:PLAYER_TALENT_UPDATE()
	
		return [[BOOLCHECK( TalentMap[LOWER(c.NameFirst)] )]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})
ConditionCategory:RegisterCondition(10,	 "PTSINTAL", {
	-- THIS CONDITION IS OUTDATED, BUT DON'T DELETE IT!
	-- IT HANDLES UPGRADES TO THE MOP VERSION OF IT!
	text = L["UIPANEL_PTSINTAL"],
	min = 0,
	max = 5,
	hidden = true,
	funcstr = function(c)
		-- Hack that will automatically upgrade to the MOP version of the condition when it is processed.
		-- This upgrade is kinda bad because we went from a number comparison to a boolean check, but we should at least put the level down to a valid value.
		-- Users are going to need to redo their conditions anyway for gameplay reasons, so I'm not to worried about a poor upgrade here.
		
		c.Type = "TALENTLEARNED"
		if c.Level > 1 then
			c.Level = 0
		end
		return CNDT.ConditionsByType.TALENTLEARNED.funcstr
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
			GlyphLookup[glyphID] = 1
			
			local name = TMW_GetSpellInfo(spellID)
			name = strlowerCache[name]
			GlyphLookup[name] = 1
		end
	end
end
ConditionCategory:RegisterCondition(11,	 "GLYPH", {
	text = L["UIPANEL_GLYPH"],
	tooltip = L["UIPANEL_GLYPH_DESC"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "GLYPHTOCHECK", "CNDT_ONLYFIRST") editbox.label = L["GLYPHTOCHECK"] end,
	nooperator = true,
	useSUG = "glyphs",
	icon = "Interface\\Icons\\inv_inscription_tradeskill01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(ConditionObject, c)
		-- this is handled externally because GlyphLookup is so extensive a process,
		-- and if it does get stuck in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("GLYPH_ADDED", 	 "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_DISABLED", "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_ENABLED",  "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_REMOVED",  "GLYPH_UPDATED")
		CNDT:RegisterEvent("GLYPH_UPDATED",  "GLYPH_UPDATED")
		CNDT:GLYPH_UPDATED()
	
		return [[BOOLCHECK( GlyphLookup[c.NameFirst] )]]
	end,
	Env = {
		GlyphLookup = {},
	},
	events = function(ConditionObject, c)
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
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PET,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_AUTOCAST", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = true,
	icon = "Interface\\Icons\\ability_physical_taunt",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellAutocast = GetSpellAutocast,
	},
	funcstr = [[BOOLCHECK( select(2, GetSpellAutocast(c.NameName)) )]],
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
			return 3
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
	hidden = pclass ~= "HUNTER",
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_PET", "player"),
			ConditionObject:GenerateNormalEventString("PET_SPECIALIZATION_CHANGED")
	end,
})
ConditionCategory:RegisterCondition(15,	 "PETTREE", {
	-- THIS CONDITION IS OUTDATED, BUT DON'T DELETE IT!
	-- IT HANDLES UPGRADES TO THE MOP VERSION OF IT!
	text = L["CONDITIONPANEL_PETTREE"],
	min = 409,
	max = 411,
	funcstr = function(c)
		-- Brilliant hack that will automatically upgrade to the MOP version of the condition when it is processed.
		
		c.Type = "PETSPEC"
		
		if c.Level == 409 then -- old tenacity
			c.Level = 2 -- new tenacity
		elseif c.Level == 410 then -- old ferocity
			c.Level = 1 -- new ferocity
		elseif c.Level == 411 then -- old cunning
			c.Level = 3 -- new cunning
		end
		
		return CNDT.ConditionsByType.PETSPEC.funcstr
	end,
	hidden = true,
})


ConditionCategory:RegisterSpacer(15.5)


Env.Tracking = {}
function CNDT:MINIMAP_UPDATE_TRACKING()
	wipe(Env.Tracking)
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		Env.Tracking[strlower(name)] = active and 1 or nil
	end
end
ConditionCategory:RegisterCondition(16,	 "TRACKING", {
	text = L["CONDITIONPANEL_TRACKING"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_TRACKING", "CNDT_ONLYFIRST") editbox.label = L["SPELLTOCHECK"] end,
	useSUG = "tracking",
	icon = "Interface\\MINIMAP\\TRACKING\\None",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(ConditionObject, c)
		-- this event handling it is really extensive, so keep it in a handler separate from the condition
		CNDT:RegisterEvent("MINIMAP_UPDATE_TRACKING")
		CNDT:MINIMAP_UPDATE_TRACKING()
	
		return [[BOOLCHECK( Tracking[c.NameName] )]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("MINIMAP_UPDATE_TRACKING")
	end,
})



ConditionCategory:RegisterSpacer(17)


ConditionCategory:RegisterCondition(18,	 "BLIZZEQUIPSET", {
	text = L["CONDITIONPANEL_BLIZZEQUIPSET"],
	tooltip = L["CONDITIONPANEL_BLIZZEQUIPSET_DESC"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_BLIZZEQUIPSET_INPUT", "CONDITIONPANEL_BLIZZEQUIPSET_INPUT_DESC") editbox.label = L["EQUIPSETTOCHECK"] end,
	useSUG = "blizzequipset",
	icon = "Interface\\Icons\\inv_box_04",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetEquipmentSetInfoByName = GetEquipmentSetInfoByName,
	},
	funcstr = [[BOOLCHECK( select(3, GetEquipmentSetInfoByName(c.NameRaw)) )]],
	events = function(ConditionObject, c)
		return
			--ConditionObject:GenerateNormalEventString("EQUIPMENT_SWAP_FINISHED") -- this doesn't fire late enough to get updated returns from GetEquipmentSetInfoByName
			ConditionObject:GenerateNormalEventString("BAG_UPDATE"), -- this is slightly overkill, but it is the first event that fires when the return value of GetEquipmentSetInfoByName has changed
			ConditionObject:GenerateNormalEventString("EQUIPMENT_SETS_CHANGED") -- this is needed to handle saving an equipment set that is alredy equipped
	end,
})

