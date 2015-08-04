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
local GetTalentInfo, GetNumTalentTabs, GetNumTalents, GetGlyphLink, GetSpellInfo = 
	  GetTalentInfo, GetNumTalentTabs, GetNumTalents, GetGlyphLink, GetSpellInfo
local GetPetActionInfo, GetNumTrackingTypes, GetTrackingInfo = 
	  GetPetActionInfo, GetNumTrackingTypes, GetTrackingInfo
	  
	  
local ConditionCategory = CNDT:GetCategory("ATTRIBUTES_PLAYER", 2, L["CNDTCAT_ATTRIBUTES_PLAYER"], true, false)




TMW:RegisterUpgrade(73019, {
	condition = function(self, condition)
		if condition.Type == "INSTANCE" then
			condition.Type = "INSTANCE2"
			condition.Checked = false
			-- We give a metatable to add one to the indexes because the indexes did shift +1 from the old to the new condition.
			CNDT:ConvertSliderCondition(condition, 0, 11, setmetatable({}, {__index=function(s,k) return k+1 end}))
		end
	end,
})
local actuallyOutsideMapIDs = {
	[1116] = true,	-- 	Draenor (gets reported as an instance if you were in your garrison and left)

	[1152] = true,	-- 	FW Horde Garrison Level 1
	[1330] = true,	-- 	FW Horde Garrison Level 2
	[1153] = true,	-- 	FW Horde Garrison Level 3
	[1154] = true,	-- 	FW Horde Garrison Level 4
	[1158] = true,	-- 	SMV Alliance Garrison Level 1
	[1331] = true,	-- 	SMV Alliance Garrison Level 2
	[1159] = true,	-- 	SMV Alliance Garrison Level 3
	[1160] = true,	-- 	SMV Alliance Garrison Level 4
}
ConditionCategory:RegisterCondition(1,	 "INSTANCE2", {
	text = L["CONDITIONPANEL_INSTANCETYPE"],
	tooltip = L["CONDITIONPANEL_INSTANCETYPE_DESC"],

	unit = false,
	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
		[01] = {order=01, text=L["CONDITIONPANEL_INSTANCETYPE_NONE"],                                space=true,   }, -- None (Outside)
		[02] = {order=02, text=BATTLEGROUND,                                                                       }, -- Battleground
		[03] = {order=03, text=ARENA,                                                                space=true,   }, -- Arena


		[04] = {order=10, text=DUNGEON_DIFFICULTY_5PLAYER,                                                         }, -- 5-player
		[05] = {order=11, text=DUNGEON_DIFFICULTY_5PLAYER_HEROIC,                                                  }, -- 5-player Heroic
		[11] = {order=12, text=format("%s (%s)", DUNGEON_DIFFICULTY_5PLAYER, CHALLENGE_MODE),                      }, -- Challenge Mode 5-man
		[24] = {order=13, text=format("%s (%s)", DUNGEON_DIFFICULTY_5PLAYER, PLAYER_DIFFICULTY_TIMEWALKER or "TW"),}, -- Warlords 5-man Timewalker
		[23] = {order=14, text=format("%s (%s)", DUNGEON_DIFFICULTY_5PLAYER, PLAYER_DIFFICULTY6),    space=true,   }, -- Warlords 5-man Mythic


		[14] = {order=17, text=GUILD_CHALLENGE_TYPE4,                                                              }, -- Normal scenario
		[13] = {order=18, text=HEROIC_SCENARIO,                                                      space=true,   }, -- Heroic scenario


		[18] = {order=21, text=format("%s (%s)", PLAYER_DIFFICULTY3, FLEX_RAID),                                   }, -- Warlords LFR Flex
		[15] = {order=22, text=format("%s (%s)", PLAYER_DIFFICULTY1, FLEX_RAID),                                   }, -- Warlords Normal Flex
		[16] = {order=23, text=format("%s (%s)", PLAYER_DIFFICULTY2, FLEX_RAID),                                   }, -- Warlords Heroic Flex
		[17] = {order=24, text=PLAYER_DIFFICULTY6,                                                   space=true,   }, -- Warlords Mythic

		[10] = {order=31, text=L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_FINDER),                        }, -- LFR (legacy, non-flex)
		[06] = {order=32, text=L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_10PLAYER),           }, -- 10-player raid (legacy)
		[07] = {order=33, text=L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_25PLAYER),           }, -- 25-player raid (legacy)
		[08] = {order=34, text=L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_10PLAYER_HEROIC),    }, -- 10-player heroic raid (legacy)
		[09] = {order=35, text=L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_25PLAYER_HEROIC),    }, -- 25-player heroic raid (legacy)
		[12] = {order=36, text=L["CONDITIONPANEL_INSTANCETYPE_LEGACY"]:format(RAID_DIFFICULTY_40PLAYER),           }, -- 40-man raid (legacy)

	},

	icon = "Interface\\Icons\\Spell_Frost_Stun",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetZoneType2 = function()
			local _, z = IsInInstance()
			local instanceDifficulty
			
			if wow_502 then
				_, _, instanceDifficulty, _, _, _, _, instanceMapID = GetInstanceInfo()

				-- Fix mapIDs that are really outside, but get reported wrong.
				if actuallyOutsideMapIDs[instanceMapID] then
					instanceDifficulty = 0
				end
			else
				instanceDifficulty = GetInstanceDifficulty() - 1
			end
			
			if z == "pvp" then
				-- Battleground           (__ -> 02)
				return 2
			elseif z == "arena" then
				-- Arena                  (__ -> 03)
				return 3
			elseif instanceDifficulty == 0 then
				-- None                   (__ -> 01)
				return 1
			else
				-- 5 man normal           (01 -> 04)
				-- 5 man heroic           (02 -> 05)
				-- 10 man normal          (03 -> 06)
				-- 25 man normal          (04 -> 07)
				-- 10 man heroic          (05 -> 08)
				-- 25 man heroic          (06 -> 09)
				-- LFR                    (07 -> 10)
				-- Challenge Mode         (08 -> 11)
				-- 40 man                 (09 -> 12)
				if instanceDifficulty <= 9 then
					return 3 + instanceDifficulty
				end

				-- heroic scenario        (11 -> 13)
				-- scenario               (12 -> 14)
				if instanceDifficulty <= 12 then
					return 2 + instanceDifficulty
				end

				-- Normal Flex            (14 -> 15)
				-- Heroic Flex            (15 -> 16)
				-- Mythic                 (16 -> 17)
				-- LFR Flex               (17 -> 18)
				if instanceDifficulty <= 17 then
					return 1 + instanceDifficulty
				end


				-- 40 man Event raid      (18 -> 12) (level 100 molten core, remap to 40 man raid)
				if instanceDifficulty == 18 then
					return 12
				end

				-- 5 man Event dungeon    (19 -> 04) (level 90 UBRS at WoD launch, remap to 5 man dungeon)
				if instanceDifficulty == 19 then
					return 4
				end

				-- Skip 19 so we can end this legacy silliness of keeping things sequential
				-- (A relic from the days when this condition was slider-based).

				-- 25 man Event scenario  (20 -> 20) (unused)
				-- Mythic 5 man           (23 -> 23)
				-- Timewalker 5 man       (24 -> 24)
				return instanceDifficulty
			end
		end,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( GetZoneType2() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("ZONE_CHANGED_NEW_AREA"),
			ConditionObject:GenerateNormalEventString("PLAYER_DIFFICULTY_CHANGED")
	end,
})



ConditionCategory:RegisterCondition(1.5, "ZONEPVP", {
	text = L["CONDITIONPANEL_ZONEPVP"],
	tooltip = L["CONDITIONPANEL_ZONEPVP_DESC"],

	unit = false,
	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
	    none = 		{order=1, text=NONE,},
	    sanctuary = {order=2, text=SANCTUARY_TERRITORY:trim("()（）"),},
	    friendly = 	{order=3, text=FACTION_CONTROLLED_TERRITORY:format(FRIENDLY):trim("()（）"),},
	    contested = {order=4, text=CONTESTED_TERRITORY:trim("()（）"),},
	    hostile = 	{order=5, text=FACTION_CONTROLLED_TERRITORY:format(HOSTILE):trim("()（）"),},
	    combat = 	{order=6, text=COMBAT_ZONE:trim("()（）"),},
		-- Only use the TMW translation if it exists for arena (ffa):
	    arena = 	{order=7, text=rawget(L, "CONDITIONPANEL_ZONEPVP_FFA") or FREE_FOR_ALL_TERRITORY:trim("()（）"), },
	},

	icon = "Interface\\Icons\\inv_bannerpvp_01",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetZonePVPInfo = GetZonePVPInfo,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( GetZonePVPInfo() or "none" )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("ZONE_CHANGED_NEW_AREA"),
			ConditionObject:GenerateNormalEventString("ZONE_CHANGED_INDOORS"),
			ConditionObject:GenerateNormalEventString("ZONE_CHANGED")
	end,
})


TMW:RegisterUpgrade(73019, {
	condition = function(self, condition)
		if condition.Type == "GROUP" then
			condition.Type = "GROUP2"
			condition.Checked = false
			-- We give a metatable to add one to the indexes because the indexes did shift +1 from the old to the new condition.
			CNDT:ConvertSliderCondition(condition, 0, 2, setmetatable({}, {__index=function(s,k) return k+1 end}))
		end
	end,
})
ConditionCategory:RegisterCondition(2,	 "GROUP2", {
	text = L["CONDITIONPANEL_GROUPTYPE"],
	tooltip = L["CONDITIONPANEL_GROUPTYPE_DESC"],

	unit = false,
	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
		[1] = SOLO,
		[2] = PARTY,
		[3] = RAID,
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
	unit = false,
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

ConditionCategory:RegisterCondition(5.3, "OVERRBAR", {
	text = L["CONDITIONPANEL_OVERRBAR"],
	tooltip = L["CONDITIONPANEL_OVERRBAR_DESC"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_Vehicle_SiegeEngineCharge",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		HasOverrideActionBar = HasOverrideActionBar,
	},
	funcstr = [[BOOLCHECK( HasOverrideActionBar() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UPDATE_OVERRIDE_ACTIONBAR")
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
	DEATHKNIGHT = 48263,-- Blood Presence
	PALADIN = 105361, 	-- Seal of Command
	WARLOCK = 103958, 	-- Metamorphosis
	MONK = 103985, 		-- Fierce Tiger
}
ConditionCategory:RegisterCondition(6,	 "STANCE", {
	text = 	pclass == "PALADIN" and L["SEAL"] or
			pclass == "DEATHKNIGHT" and L["PRESENCE"] or
			pclass == "DRUID" and L["SHAPESHIFT"] or
			-- pclass == "HUNTER" and L["ASPECT"] or -- aspects aren't stances anymore.
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
	tooltip = L["UIPANEL_SPEC"],
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
			--ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED", "player"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})

ConditionCategory:RegisterCondition(8,	 "TREE", {
	old = true,
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
			ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED", "player")
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
	icon = "Interface\\Addons\\TellMeWhen\\Textures\\HEALER",
	Env = {
		GetCurrentSpecializationRole = TMW.GetCurrentSpecializationRole,
		SpeclizationRoles = SpeclizationRoles,
	},
	funcstr = [[(SpeclizationRoles[GetCurrentSpecializationRole()] or 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		if pclass == "WARRIOR" then
			return
				ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED", "player"),
				ConditionObject:GenerateNormalEventString("UPDATE_SHAPESHIFT_FORM")-- Check for gladiator stance.
		else
			return
				ConditionObject:GenerateNormalEventString("PLAYER_SPECIALIZATION_CHANGED", "player")
		end
	end,
})


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
	icon = function() return select(3, GetTalentInfo(1, 1, 1)) end,
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
ConditionCategory:RegisterCondition(9,	 "PTSINTAL", {
	text = L["UIPANEL_PTSINTAL"],
	funcstr = "DEPRECATED",
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
			
			local name = GetSpellInfo(spellID)
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
	tooltip = L["CONDITIONPANEL_AUTOCAST_DESC"],
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
	funcstr = [[BOOLCHECK( select(2, GetSpellAutocast(c.NameString)) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PET_BAR_UPDATE")
	end,
})



TMW:RegisterUpgrade(73019, {
	condition = function(self, condition)
		if condition.Type == "PETMODE" then
			condition.Type = "PETMODE2"
			condition.Checked = false
			-- We give a metatable to add one to the indexes because the indexes did shift +1 from the old to the new condition.
			CNDT:ConvertSliderCondition(condition, 1, 3)
		end
	end,
})
local PetModes = {
	PET_MODE_ASSIST = 1,
	PET_MODE_DEFENSIVE = 2,
	PET_MODE_PASSIVE = 3,
}
ConditionCategory:RegisterCondition(13.1, "PETMODE2", {
	text = L["CONDITIONPANEL_PETMODE"],
	tooltip = L["CONDITIONPANEL_PETMODE_DESC"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
		[0] = L["CONDITIONPANEL_PETMODE_NONE"],
		[1] = PET_MODE_ASSIST,
		[2] = PET_MODE_DEFENSIVE,
		[3] = PET_MODE_PASSIVE
	},

	unit = false,
	icon = PET_ASSIST_TEXTURE,
	tcoords = CNDT.COMMON.standardtcoords,

	Env = {
		GetActivePetMode2 = function()
			for i = NUM_PET_ACTION_SLOTS, 1, -1 do -- go backwards since they are probably at the end of the action bar
				local name, _, _, isToken, isActive = GetPetActionInfo(i)
				if isToken and isActive and PetModes[name] then
					return PetModes[name]
				end
			end
			return 0
		end,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( GetActivePetMode2() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_PET", "player"),
			ConditionObject:GenerateNormalEventString("PET_BAR_UPDATE")
	end,
})

TMW:RegisterUpgrade(73019, {
	condition = function(self, condition)
		if condition.Type == "PETSPEC" then
			condition.Type = "PETSPEC2"
			condition.Checked = false
			CNDT:ConvertSliderCondition(condition, 0, 3)
		end
	end,
})
ConditionCategory:RegisterCondition(14.1, "PETSPEC2", {
	text = L["CONDITIONPANEL_PETSPEC"],
	tooltip = L["CONDITIONPANEL_PETSPEC_DESC"],

	bitFlagTitle = L["CONDITIONPANEL_UNITSPEC_CHOOSEMENU"],
	bitFlags = {
		[0] = NONE,
		[1] = L["PET_TYPE_FEROCITY"],
		[2] = L["PET_TYPE_TENACITY"],
		[3] = L["PET_TYPE_CUNNING"]
	},

	hidden = pclass ~= "HUNTER",
	unit = false,
	icon = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
	tcoords = CNDT.COMMON.standardtcoords,

	Env = {
		GetSpecialization = GetSpecialization
	},
	funcstr = [[BITFLAGSMAPANDCHECK( GetSpecialization(nil, true) or 0 )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_PET", "player"),
			ConditionObject:GenerateNormalEventString("PET_SPECIALIZATION_CHANGED")
	end,
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
	tooltip = L["CONDITIONPANEL_TRACKING_DESC"],
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
	
		return [[BOOLCHECK( Tracking[c.NameString] )]]
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

