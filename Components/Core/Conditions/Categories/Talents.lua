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

local CNDT = TMW.CNDT
local Env = CNDT.Env
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")

local ConditionCategory = CNDT:GetCategory("TALENTS", 1.4, L["CNDTCAT_TALENTS"], true, false)


ConditionCategory:RegisterCondition(0.2,  "CLASS2", {
	text = L["CONDITIONPANEL_CLASS"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSECLASS"],
	bitFlags = (function()
		local t = {}
		for classID = 1, TMW.GetMaxClassID() do
			local name, token = TMW.GetClassInfo(classID)
			if name then
				t[classID] = {
					order = classID,
					text = PLAYER_CLASS_NO_SPEC:format(RAID_CLASS_COLORS[token].colorStr, name),
					icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
					tcoords = {
						(CLASS_ICON_TCOORDS[token][1]+.02),
						(CLASS_ICON_TCOORDS[token][2]-.02),
						(CLASS_ICON_TCOORDS[token][3]+.02),
						(CLASS_ICON_TCOORDS[token][4]-.02),
					}
				}
			end
		end
		return t
	end)(),

	icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
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
		return [[ BITFLAGSMAPANDCHECK( select(3, UnitClass(c.Unit)) or 0 ) ]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)) -- classes cant change, so this is all we should need
	end,
})

ConditionCategory:RegisterCondition(0.3,  "ROLE2", {
	text = L["CONDITIONPANEL_ROLE"],
	tooltip = L["CONDITIONPANEL_ROLE_DESC"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
		NONE = 		{order = 1, text=NONE },
		TANK = 		{order = 2, text=TANK, icon = "Interface/AddOns/TellMeWhen/Textures/TANK", },
		HEALER = 	{order = 3, text=HEALER, icon = "Interface/AddOns/TellMeWhen/Textures/HEALER", },
		DAMAGER = 	{order = 4, text=DAMAGER, icon = "Interface/AddOns/TellMeWhen/Textures/DAMAGER", },
	},

	icon = "Interface\\Addons\\TellMeWhen\\Textures\\DAMAGER",
	Env = {
		UnitGroupRolesAssigned = UnitGroupRolesAssigned,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( UnitGroupRolesAssigned(c.Unit) ) ]],
	events = function(ConditionObject, c)
		-- The unit change events should actually cover many of the changes
		-- (at least for party and raid units, but roles only exist in party and raid anyway.)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("PLAYER_ROLES_ASSIGNED"),
			ConditionObject:GenerateNormalEventString("ROLE_CHANGED_INFORM")
	end,
})


ConditionCategory:RegisterSpacer(6)

ConditionCategory:RegisterCondition(6.1,	 "UNITSPEC", {
	text = L["UIPANEL_SPECIALIZATION"],

	bitFlagTitle = L["CONDITIONPANEL_UNITSPEC_CHOOSEMENU"],
	bitFlags = (function()
		local t = {}
		for i = 1, GetNumClasses() do
			local _, class, classID = GetClassInfo(i)
			if classID then
				for j = 1, TMW.GetNumSpecializationsForClassID(classID) do
					local specID, spec, desc, icon = TMW.GetSpecializationInfoForClassID(classID, j)
					t[specID] = {
						order = specID,
						text = PLAYER_CLASS:format(RAID_CLASS_COLORS[class].colorStr, spec, LOCALIZED_CLASS_NAMES_MALE[class]),
						icon = icon,
						tcoords = CNDT.COMMON.standardtcoords
					}
				end
			end
		end
		return t
	end)(),

	icon = function() return select(4, TMW.GetSpecializationInfo(1)) end,
	tcoords = CNDT.COMMON.standardtcoords,
	unit = PLAYER,

	Env = {
		GetCurrentSpecializationID = TMW.GetCurrentSpecializationID,
	},
	funcstr = function(c)
		return [[ BITFLAGSMAPANDCHECK( GetCurrentSpecializationID() ) ]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE")
	end,
})

ConditionCategory:RegisterCondition(7,	 "SPEC", {
	text = L["UIPANEL_SPEC"],
	min = 1,
	max = 2,
	levelChecks = true,
	texttable = {
		[1] = L["UIPANEL_PRIMARYSPEC"],
		[2] = L["UIPANEL_SECONDARYSPEC"],
	},
	nooperator = true,
	unit = PLAYER,
	icon = "Interface\\Icons\\achievement_general",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetActiveTalentGroup = GetActiveTalentGroup
	},
	funcstr = [[c.Level == GetActiveTalentGroup()]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end,
})

ConditionCategory:RegisterCondition(8.1, "TREEROLE2", {
	text = L["UIPANEL_SPECIALIZATIONROLE"],
	tooltip = L["UIPANEL_SPECIALIZATIONROLE_DESC"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
		TANK =    {order = 1, text=TANK, icon = "Interface/AddOns/TellMeWhen/Textures/TANK", },
		HEALER =  {order = 2, text=HEALER, icon = "Interface/AddOns/TellMeWhen/Textures/HEALER", },
		DAMAGER = {order = 3, text=DAMAGER, icon = "Interface/AddOns/TellMeWhen/Textures/DAMAGER", },
	},

	unit = PLAYER,
	icon = "Interface\\Addons\\TellMeWhen\\Textures\\HEALER",
	Env = {
		GetCurrentSpecializationRole = TMW.GetCurrentSpecializationRole,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( GetCurrentSpecializationRole() ) ]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED"),
			ConditionObject:GenerateNormalEventString("TALENT_GROUP_ROLE_CHANGED")
	end,
})



ConditionCategory:RegisterSpacer(8.9)

Env.TalentMap = {}
function CNDT:CHARACTER_POINTS_CHANGED()
	wipe(Env.TalentMap)
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
ConditionCategory:RegisterCondition(9,	 "PTSINTAL", {
	text = L["UIPANEL_PTSINTAL"],
	min = 0,
	max = 5,
	unit = PLAYER,
	name = function(editbox)
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = "talents",
	icon = function() return select(2, GetTalentInfo(1, 1)) end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c) 
		-- this is handled externally because TalentMap is so extensive a process,
		-- and if it ends up getting processed in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("CHARACTER_POINTS_CHANGED")
		CNDT:CHARACTER_POINTS_CHANGED()

		return [[(TalentMap[c.NameString] or 0) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("CHARACTER_POINTS_CHANGED")
	end,
})


local GetGlyphSocketInfo = GetGlyphSocketInfo
function CNDT:GLYPH_UPDATED()
	local GlyphLookup = Env.GlyphLookup
	wipe(GlyphLookup)
	for i = 1, 6 do
		local _, _, spellID = GetGlyphSocketInfo(i)
		if spellID then
			GlyphLookup[spellID] = 1
			
			local name = GetSpellInfo(spellID)
			name = strlowerCache[name]
			GlyphLookup[name] = 1
		end
	end
end
ConditionCategory:RegisterCondition(11,	 "GLYPH", {
	text = L["UIPANEL_GLYPH"],
	tooltip = L["UIPANEL_GLYPH_DESC"],

	bool = true,
	
	unit = PLAYER,
	name = function(editbox)
		editbox:SetTexts(L["GLYPHTOCHECK"], L["CNDT_ONLYFIRST"])
	end,
	useSUG = "glyphs",
	icon = "Interface\\Icons\\inv_inscription_tradeskill01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(ConditionObject, c)
		-- this is handled externally because GlyphLookup is so extensive a process,
		-- and if it does get stuck in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("GLYPH_ADDED", 	 "GLYPH_UPDATED")
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
			ConditionObject:GenerateNormalEventString("GLYPH_REMOVED"),
			ConditionObject:GenerateNormalEventString("GLYPH_UPDATED")
	end,
})