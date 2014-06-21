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

local _, pclass = UnitClass("Player")

local CNDT = TMW.CNDT
local Env = CNDT.Env


local ConditionCategory = CNDT:GetCategory("ATTRIBUTES_UNIT", 3, L["CNDTCAT_ATTRIBUTES_UNIT"], false, false)

ConditionCategory:RegisterCondition(1,	 "EXISTS", {
	text = L["CONDITIONPANEL_EXISTS"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	icon = "Interface\\Icons\\ABILITY_SEAL",
	tcoords = CNDT.COMMON.standardtcoords,
	defaultUnit = "target",
	Env = {
		UnitExists = UnitExists,
	},
	funcstr = function(c)
		if c.Unit == "player" then
			return [[true]]
		else
			return [[c.1nil == UnitExists(c.Unit)]]
		end
	end,
	events = function(ConditionObject, c)
		--if c.Unit == "mouseover" then
			-- THERE IS NO EVENT FOR WHEN YOU ARE NO LONGER MOUSING OVER A UNIT, SO WE CANT USE THIS
			
		--	return "UPDATE_MOUSEOVER_UNIT"
		--else
			return
				ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)) -- this should work
		--end
	end,
})
ConditionCategory:RegisterCondition(2,	 "ALIVE", {
	text = L["CONDITIONPANEL_ALIVE"],
	tooltip = L["CONDITIONPANEL_ALIVE_DESC"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	icon = "Interface\\Icons\\Ability_Vanish",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitIsDeadOrGhost = UnitIsDeadOrGhost,
	},
	funcstr = [[c.nil1 == UnitIsDeadOrGhost(c.Unit)]], -- note usage of nil1, not 1nil
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEALTH", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(3,	 "COMBAT", {
	text = L["CONDITIONPANEL_COMBAT"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	icon = "Interface\\CharacterFrame\\UI-StateIcon",
	tcoords = {0.53, 0.92, 0.05, 0.42},
	Env = {
		UnitAffectingCombat = UnitAffectingCombat,
	},
	funcstr = [[c.1nil == UnitAffectingCombat(c.Unit)]],
	events = function(ConditionObject, c)
		if c.Unit == "player" then
			return
				ConditionObject:GenerateNormalEventString("PLAYER_REGEN_ENABLED"),
				ConditionObject:GenerateNormalEventString("PLAYER_REGEN_DISABLED")
		else
			return
				ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
				ConditionObject:GenerateNormalEventString("UNIT_FLAGS", CNDT:GetUnit(c.Unit))
		end
	end,
})
ConditionCategory:RegisterCondition(4,	 "VEHICLE", {
	text = L["CONDITIONPANEL_VEHICLE"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	icon = "Interface\\Icons\\Ability_Vehicle_SiegeEngineCharge",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitHasVehicleUI = UnitHasVehicleUI,
	},
	funcstr = [[c.True == UnitHasVehicleUI(c.Unit)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_ENTERED_VEHICLE", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_EXITED_VEHICLE", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_VEHICLE", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(5,	 "PVPFLAG", {
	text = L["CONDITIONPANEL_PVPFLAG"],
	min = 0,
	max = 1,
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	icon = "Interface\\TargetingFrame\\UI-PVP-" .. UnitFactionGroup("player"),
	tcoords = {0.046875, 0.609375, 0.015625, 0.59375},
	Env = {
		UnitIsPVP = UnitIsPVP,
	},
	funcstr = [[c.1nil == UnitIsPVP(c.Unit)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_FACTION", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(6,	 "REACT", {
	text = L["ICONMENU_REACT"],
	min = 1,
	max = 2,
	defaultUnit = "target",
	texttable = {[1] = L["ICONMENU_HOSTILE"], [2] = L["ICONMENU_FRIEND"]},
	nooperator = true,
	icon = "Interface\\Icons\\Warrior_talent_icon_FuryInTheBlood",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitIsEnemy = UnitIsEnemy,
		UnitReaction = UnitReaction,
	},
	funcstr = [[(((UnitIsEnemy("player", c.Unit) or ((UnitReaction("player", c.Unit) or 5) <= 4)) and 1) or 2) == c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_FLAGS", CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_FLAGS", "player")
	end,
})
ConditionCategory:RegisterCondition(6.2, "ISPLAYER", {
	text = L["ICONMENU_ISPLAYER"],
	min = 0,
	max = 1,
	defaultUnit = "target",
	formatter = TMW.C.Formatter.BOOL,
	nooperator = true,
	icon = "Interface\\Icons\\INV_Misc_Head_Human_02",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitIsPlayer = UnitIsPlayer,
	},
	funcstr = [[UnitIsPlayer(c.Unit) == c.1nil]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit))
	end,
})


ConditionCategory:RegisterSpacer(6.5)


ConditionCategory:RegisterCondition(6.7,	 "INCHEALS", {
	text = L["INCHEALS"],
	tooltip = L["INCHEALS_DESC"],
	range = 50000,
	icon = "Interface\\Icons\\spell_holy_flashheal",
	tcoords = CNDT.COMMON.standardtcoords,
	formatter = TMW.C.Formatter.COMMANUMBER,
	Env = {
		UnitGetIncomingHeals = UnitGetIncomingHeals,
	},
	funcstr = function(c)
		return [[(UnitGetIncomingHeals(c.Unit) or 0) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_HEAL_PREDICTION", CNDT:GetUnit(c.Unit))
	end,
})


ConditionCategory:RegisterSpacer(6.9)


Env.GetUnitSpeed = GetUnitSpeed
ConditionCategory:RegisterCondition(7,	 "SPEED", {
	text = L["SPEED"],
	tooltip = L["SPEED_DESC"],
	min = 0,
	max = 500,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	icon = "Interface\\Icons\\ability_rogue_sprint",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[GetUnitSpeed(c.Unit)/]].. BASE_MOVEMENT_SPEED ..[[ c.Operator c.Level]],
	-- events = absolutely no events
})
ConditionCategory:RegisterCondition(8,	 "RUNSPEED", {
	text = L["RUNSPEED"],
	min = 0,
	max = 500,
	percent = true,
	formatter = TMW.C.Formatter.PERCENT,
	icon = "Interface\\Icons\\ability_rogue_sprint",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[select(2, GetUnitSpeed(c.Unit))/]].. BASE_MOVEMENT_SPEED ..[[ c.Operator c.Level]],
	-- events = absolutely no events
})


ConditionCategory:RegisterSpacer(8.1)


ConditionCategory:RegisterCondition(8.5, "LIBRANGECHECK", {
	text = L["CNDT_RANGE"],
	tooltip = L["CNDT_RANGE_DESC"],
	min = 0,
	max = 100,
	formatter = TMW.C.Formatter:New(function(val)
		local LRC = LibStub("LibRangeCheck-2.0")
		if not LRC then
			return val
		end

		if val == 0 then
			return L["CNDT_RANGE_PRECISE"]:format(val)
		end

		for range in LRC:GetHarmCheckers() do
			if range == val then
				return L["CNDT_RANGE_PRECISE"]:format(val)
			end
		end
		for range in LRC:GetFriendCheckers() do
			if range == val then
				return L["CNDT_RANGE_PRECISE"]:format(val)
			end
		end

		return L["CNDT_RANGE_IMPRECISE"]:format(val)
	end),

	icon = "Interface\\Icons\\ability_hunter_snipershot",
	tcoords = CNDT.COMMON.standardtcoords,

	specificOperators = {["<="] = true, [">="] = true},

	applyDefaults = function(conditionData, conditionSettings)
		local op = conditionSettings.Operator

		if not conditionData.specificOperators[op] then
			conditionSettings.Operator = "<="
		end
	end,

	funcstr = function(c, parent)
		Env.LibRangeCheck = LibStub("LibRangeCheck-2.0")
		if not Env.LibRangeCheck then
			TMW:Error("The %s condition requires LibRangeCheck-2.0")
			return "false"
		end

		if c.Operator == "<=" then
			return [[(select(2, LibRangeCheck:GetRange(c.Unit)) or huge) c.Operator c.Level]]
		elseif c.Operator == ">=" then
			return [[(LibRangeCheck:GetRange(c.Unit) or 0) c.Operator c.Level]]
		else
			TMW:Error("Bad operator %q for range check condition of %s", c.Operator, tostring(parent))
		end
	end,
	-- events = absolutely no events
})


ConditionCategory:RegisterSpacer(8.9)


ConditionCategory:RegisterCondition(9,	 "NAME", {
	text = L["CONDITIONPANEL_NAME"],
	min = 0,
	max = 1,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_NAMETOMATCH", "CONDITIONPANEL_NAMETOOLTIP") editbox.label = L["CONDITIONPANEL_NAMETOMATCH"] end,
	nooperator = true,
	formatter = TMW.C.Formatter.BOOL,
	icon = "Interface\\LFGFrame\\LFGFrame-SearchIcon-Background",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitName = UnitName,
	},
	funcstr = [[c.1nil == (strfind(c.Name, SemicolonConcatCache[UnitName(c.Unit) or ""]) and 1)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_NAME_UPDATE", CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(9.5, "NPCID", {
	text = L["CONDITIONPANEL_NPCID"],
	tooltip = L["CONDITIONPANEL_NPCID_DESC"],
	min = 0,
	max = 1,
	name = function(editbox) TMW:TT(editbox, "CONDITIONPANEL_NPCIDTOMATCH", "CONDITIONPANEL_NPCIDTOOLTIP") editbox.label = L["CONDITIONPANEL_NPCIDTOMATCH"] end,
	nooperator = true,
	formatter = TMW.C.Formatter.BOOL,
	icon = "Interface\\LFGFrame\\LFGFrame-SearchIcon-Background",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitGUID = UnitGUID,
	},
	funcstr = [[c.1nil == (strfind(c.Name, SemicolonConcatCache[tonumber((UnitGUID(c.Unit) or "0x00000000000000000"):sub(6, 10), 16)]) and 1)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit))
	end,
})
ConditionCategory:RegisterCondition(10,	 "LEVEL", {
	text = L["CONDITIONPANEL_LEVEL"],
	min = -1,
	max = GetMaxPlayerLevel() + 3,
	texttable = function(i)
		if i == -1 then
			return BOSS
		end
		return i
	end,
	icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
	tcoords = {0.05, 0.95, 0.03, 0.97},
	Env = {
		UnitLevel = UnitLevel,
	},
	funcstr = [[UnitLevel(c.Unit) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_LEVEL", CNDT:GetUnit(c.Unit))
	end,
})

local Classes = {
	"DEATHKNIGHT",
	"DRUID",
	"HUNTER",
	"MAGE",
	"PRIEST",
	"PALADIN",
	"ROGUE",
	"SHAMAN",
	"WARLOCK",
	"WARRIOR",
	"MONK",
}
ConditionCategory:RegisterCondition(11,	 "CLASS", {
	text = L["CONDITIONPANEL_CLASS"],
	min = 1,
	max = #Classes,
	texttable = function(k) return Classes[k] and LOCALIZED_CLASS_NAMES_MALE[Classes[k]] end,
	icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
	nooperator = true,
	tcoords = {
		CLASS_ICON_TCOORDS[pclass][1]+.02,
		CLASS_ICON_TCOORDS[pclass][2]-.02,
		CLASS_ICON_TCOORDS[pclass][3]+.02,
		CLASS_ICON_TCOORDS[pclass][4]-.02,
	},
	Env = {
		UnitClass = UnitClass,
	},
	funcstr = function(c)
		return [[select(2, UnitClass(c.Unit)) == "]] .. (Classes[c.Level] or "whoops") .. "\""
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)) -- classes cant change, so this is all we should need
	end,
})

local unitClassifications = {
	"normal",
	"rare",
	"elite",
	"rareelite",
	"worldboss",
}
for k, v in pairs(unitClassifications) do
	unitClassifications[v] = k
end
ConditionCategory:RegisterCondition(12,	 "CLASSIFICATION", {
	text = L["CONDITIONPANEL_CLASSIFICATION"],
	min = 1,
	max = #unitClassifications,
	defaultUnit = "target",
	texttable = function(k) return L[unitClassifications[k]] end,
	icon = "Interface\\Icons\\achievement_pvp_h_03",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		unitClassifications = unitClassifications,
		UnitClassification = UnitClassification,
	},
	funcstr = [[(unitClassifications[UnitClassification(c.Unit)] or 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("UNIT_CLASSIFICATION_CHANGED", CNDT:GetUnit(c.Unit))
	end,
})

ConditionCategory:RegisterCondition(13,	 "CREATURETYPE", {
	text = L["CONDITIONPANEL_CREATURETYPE"],
	min = 0,
	max = 1,
	defaultUnit = "target",
	name = function(editbox)
		TMW:TT(editbox, "CONDITIONPANEL_CREATURETYPE_LABEL", "CONDITIONPANEL_CREATURETYPE_DESC")
		editbox.label = L["CONDITIONPANEL_CREATURETYPE_LABEL"]
	end,
	useSUG = "creaturetype",
	allowMultipleSUGEntires = true,
	nooperator = true,
	formatter = TMW.C.Formatter.BOOL,
	icon = "Interface\\Icons\\spell_shadow_summonfelhunter",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitCreatureType = UnitCreatureType,
	},
	funcstr = [[c.1nil == (strfind(c.Name, SemicolonConcatCache[UnitCreatureType(c.Unit) or ""]) and 1)]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit))
	end,
})


ConditionCategory:RegisterSpacer(13.5)


local playerDungeonRoles = {
	"NONE",
	"DAMAGER",
	"HEALER",
	"TANK",
}
for k, v in pairs(playerDungeonRoles) do
	playerDungeonRoles[v] = k
end
ConditionCategory:RegisterCondition(14,	 "ROLE", {
	text = L["CONDITIONPANEL_ROLE"],
	min = 1,
	max = #playerDungeonRoles,
	texttable = setmetatable({}, {__index = function(t, k) return _G[playerDungeonRoles[k]] end}),
	icon = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES",
	tcoords = {GetTexCoordsForRole("DAMAGER")},
	Env = {
		playerDungeonRoles = playerDungeonRoles,
		UnitGroupRolesAssigned = UnitGroupRolesAssigned,
	},
	funcstr = [[(playerDungeonRoles[UnitGroupRolesAssigned(c.Unit)] or 1) c.Operator c.Level]],
	events = function(ConditionObject, c)
		-- the unit change events should actually cover many of the changes (at least for party and raid units, but roles only exist in party and raid anyway.)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("PLAYER_ROLES_ASSIGNED"),
			ConditionObject:GenerateNormalEventString("ROLE_CHANGED_INFORM")
	end,
})

ConditionCategory:RegisterCondition(15,	 "RAIDICON", {
	text = L["CONDITIONPANEL_RAIDICON"],
	min = 0,
	max = 8,
	texttable = setmetatable({[0]=NONE}, {__index = function(t, k) return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..k..":0|t ".._G["RAID_TARGET_"..k] end}),
	icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
	Env = {
		GetRaidTargetIndex = GetRaidTargetIndex,
	},
	funcstr = [[(GetRaidTargetIndex(c.Unit) or 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("RAID_TARGET_UPDATE")
	end,
})
ConditionCategory:RegisterCondition(16,	 "UNITISUNIT", {
	text = L["CONDITIONPANEL_UNITISUNIT"],
	tooltip = L["CONDITIONPANEL_UNITISUNIT_DESC"],
	min = 0,
	max = 1,
	nooperator = true,
	name = function(editbox) TMW:TT(editbox, "UNITTWO", "CONDITIONPANEL_UNITISUNIT_EBDESC") editbox.label = L["UNITTWO"] end,
	useSUG = "units",
	formatter = TMW.C.Formatter.BOOL,
	icon = "Interface\\Icons\\spell_holy_prayerofhealing",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitIsUnit = UnitIsUnit,
	},
	funcstr = [[UnitIsUnit(c.Unit, c.Unit2) == c.1nil]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Name))
	end,
})
ConditionCategory:RegisterCondition(17,	 "THREATSCALED", {
	text = L["CONDITIONPANEL_THREAT_SCALED"],
	tooltip = L["CONDITIONPANEL_THREAT_SCALED_DESC"],
	min = 0,
	max = 100,
	defaultUnit = "target",
	formatter = TMW.C.Formatter.PERCENT,
	icon = "Interface\\Icons\\spell_misc_emotionangry",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitDetailedThreatSituation = UnitDetailedThreatSituation,
	},
	funcstr = [[(select(3, UnitDetailedThreatSituation("player", c.Unit)) or 0) c.Operator c.Level]],
	-- events = absolutely no events
})
ConditionCategory:RegisterCondition(18,	 "THREATRAW", {
	text = L["CONDITIONPANEL_THREAT_RAW"],
	tooltip = L["CONDITIONPANEL_THREAT_RAW_DESC"],
	min = 0,
	max = 130,
	defaultUnit = "target",
	formatter = TMW.C.Formatter.PERCENT,
	icon = "Interface\\Icons\\spell_misc_emotionhappy",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		UnitDetailedThreatSituation = UnitDetailedThreatSituation,
	},
	funcstr = [[(select(4, UnitDetailedThreatSituation("player", c.Unit)) or 0) c.Operator c.Level]],
	-- events = absolutely no events
})
