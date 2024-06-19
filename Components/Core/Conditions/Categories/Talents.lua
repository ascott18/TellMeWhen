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

local wipe = 
      wipe
local GetTalentInfo, GetNumTalents, GetGlyphLink, GetSpellInfo = 
      GetTalentInfo, GetNumTalents, GetGlyphLink, GetSpellInfo
local GetSpecializationInfo, GetNumClasses = 
      GetSpecializationInfo, GetNumClasses
local GetNumBattlefieldScores, RequestBattlefieldScoreData, GetBattlefieldScore, GetNumArenaOpponents, GetArenaOpponentSpec =
      GetNumBattlefieldScores, RequestBattlefieldScoreData, GetBattlefieldScore, GetNumArenaOpponents, GetArenaOpponentSpec
local UnitAura, IsInJailersTower, C_SpecializationInfo, GetPvpTalentInfoByID =
	  UnitAura, IsInJailersTower, C_SpecializationInfo, GetPvpTalentInfoByID
	  
local GetClassInfo = TMW.GetClassInfo
local GetMaxClassID = TMW.GetMaxClassID

local ConditionCategory = CNDT:GetCategory("TALENTS", 1.4, L["CNDTCAT_TALENTS"], true, false)





local specNameToRole = {}
local SPECS = CNDT:NewModule("Specs", "AceEvent-3.0")
function SPECS:UpdateUnitSpecs()
	local _, z = IsInInstance()

	if next(Env.UnitSpecs) then
		wipe(Env.UnitSpecs)
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end

	if z == "arena" and GetArenaOpponentSpec then
		for i = 1, GetNumArenaOpponents() do
			local unit = "arena" .. i

			local name, server = UnitName(unit)
			if name and name ~= UNKNOWN then
				local specID = GetArenaOpponentSpec(i)
				name = name .. (server and "-" .. server or "")
				Env.UnitSpecs[name] = specID
			end
		end

		TMW:Fire("TMW_UNITSPEC_UPDATE")

	elseif z == "pvp" and TMW.isRetail then
		RequestBattlefieldScoreData()

		for i = 1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)
			if name and talentSpec then
				local specID = specNameToRole[classToken][talentSpec]
				Env.UnitSpecs[name] = specID
			end
		end
		
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end
end
function SPECS:PrepareUnitSpecEvents()
	SPECS:RegisterEvent("UNIT_NAME_UPDATE",   "UpdateUnitSpecs")
	SPECS:RegisterEvent("ARENA_OPPONENT_UPDATE", "UpdateUnitSpecs")
	SPECS:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateUnitSpecs")
	SPECS:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateUnitSpecs")
	SPECS.PrepareUnitSpecEvents = TMW.NULLFUNC
end
ConditionCategory:RegisterCondition(0.1,  "UNITSPEC", {
	text = L["CONDITIONPANEL_UNITSPEC"],
	tooltip = TMW.isRetail and L["CONDITIONPANEL_UNITSPEC_DESC"] or L["CONDITIONPANEL_UNITSPEC_DESC_WRATH"],

	bitFlagTitle = L["CONDITIONPANEL_UNITSPEC_CHOOSEMENU"],
	bitFlags = (function()
		local t = {}
		for i = 1, GetMaxClassID() do
			local _, class, classID = GetClassInfo(i)
			if classID then
				specNameToRole[class] = {}
				for j = 1, TMW.GetNumSpecializationsForClassID(classID) do
					local specID, spec, desc, icon = TMW.GetSpecializationInfoForClassID(classID, j)
					specNameToRole[class][spec] = specID
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

	Env = {
		UnitSpecs = {},
		UnitSpec = function(unit)
			if UnitIsUnit(unit, "player") then
				return TMW.GetCurrentSpecializationID() or 0
			else
				local name, server = UnitName(unit)
				if name then
					name = name .. (server and "-" .. server or "")
					return Env.UnitSpecs[name] or 0
				end
			end

			return 0
		end,
	},
	funcstr = function(c)
		return [[ BITFLAGSMAPANDCHECK( UnitSpec(c.Unit) ) ]]
	end,
	events = function(ConditionObject, c)
		if c.Unit ~= "player" then
			-- Don't do these if we're definitely checking player,
			-- since there's really no reason to.
			SPECS:PrepareUnitSpecEvents()
			SPECS:UpdateUnitSpecs()
		end

		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)),
			ConditionObject:GenerateNormalEventString("TMW_UNITSPEC_UPDATE"),
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE")
	end,
})


TMW:RegisterUpgrade(73019, {
	-- Convert "CLASS" to "CLASS2"
	classes = {
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
	},
	condition = function(self, condition)
		if condition.Type == "CLASS" then
			condition.Type = "CLASS2"
			condition.Checked = false
			for i = 1, GetNumClasses() do
				local name, token, classID = GetClassInfo(i)
				if token == self.classes[condition.Level] then
					condition.BitFlags = {[i] = true}
					return
				end
			end
		end
	end,
})
ConditionCategory:RegisterCondition(0.2,  "CLASS2", {
	text = L["CONDITIONPANEL_CLASS"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSECLASS"],
	bitFlags = (function()
		local t = {}
		for classID = 1, GetMaxClassID() do
			local name, token = GetClassInfo(classID)
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


TMW:RegisterUpgrade(73019, {
	playerDungeonRoles = {
		"NONE",
		"DAMAGER",
		"HEALER",
		"TANK",
	},
	condition = function(self, condition)
		if condition.Type == "ROLE" then
			condition.Type = "ROLE2"
			condition.Checked = false
			CNDT:ConvertSliderCondition(condition, 1, #self.playerDungeonRoles, self.playerDungeonRoles)
		end
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


-- Dual Spec
if GetActiveTalentGroup then
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
else
	ConditionCategory:RegisterCondition(7,	 "SPEC", {
		text = L["UIPANEL_SPEC"],
		tooltip = L["UIPANEL_SPEC"],
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
		funcstr = "DEPRECATED",
	})
end

if GetNumSpecializations then
	ConditionCategory:RegisterCondition(8,	 "TREE", {
		old = true,
		text = L["UIPANEL_SPECIALIZATION"],
		min = 1,
		max = GetNumSpecializations,
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
end


TMW:RegisterUpgrade(80002, {
	condition = function(self, condition)
		if condition.Type == "TREEROLE" then
			condition.Type = "TREEROLE2"
			condition.Checked = false
			CNDT:ConvertSliderCondition(condition, 1, 3, {
				[1] = "TANK",
				[2] = "DAMAGER",
				[3] = "HEALER",
			})
		end
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
		if not TMW.isRetail then
			return
				ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED"),
				ConditionObject:GenerateNormalEventString("TALENT_GROUP_ROLE_CHANGED")
		elseif pclass == "WARRIOR" then
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
CNDT.Env.PvpTalentMap = {}
if C_ClassTalents then
	-- Dragonflight

	function CNDT:PLAYER_TALENT_UPDATE()
		wipe(Env.TalentMap)

		local loadoutName
		if C_ClassTalents.GetStarterBuildActive() then
			loadoutName = TALENT_FRAME_DROP_DOWN_STARTER_BUILD
		else
			local spec = TMW.GetCurrentSpecializationID()
			local realLoadout = spec and C_ClassTalents.GetLastSelectedSavedConfigID(spec)
			if realLoadout then
				local realConfigInfo = C_Traits.GetConfigInfo(realLoadout)
				if realConfigInfo then
					loadoutName = realConfigInfo.name or ""
				else
					loadoutName = TALENT_FRAME_DROP_DOWN_DEFAULT
				end
			else
				loadoutName = TALENT_FRAME_DROP_DOWN_DEFAULT
			end
		end
		
		-- This is an event because we usually have to do weird delayed updates
		-- after blizz events fire before we can receive the actual real active loadout name.
		loadoutName = loadoutName:lower()
		if loadoutName ~= Env.CurrentLoadoutName then
			Env.CurrentLoadoutName = loadoutName
			TMW:Fire("TMW_TALENT_LOADOUT_NAME_UPDATE", loadoutName)
		end

		-- A "config" is a loadout - either the current one (maybe unsaved), or a saved one.
		-- NOTE: C_ClassTalents.GetActiveConfigID returns a generic config for the curent class spec,
		-- not the actual currently selected loadout (which is only returned by )
		local configID = C_ClassTalents.GetActiveConfigID()
		if configID then
			-- will be nil on fresh characters
			local configInfo = C_Traits.GetConfigInfo(configID)

			-- I have no idea why the concept of trees exists.
			-- It seems that every class has a single tree, regardless of spec.
			for _, treeID in pairs(configInfo.treeIDs) do

				-- Nodes are circles/square in the talent tree.
				for _, nodeID in pairs(C_Traits.GetTreeNodes(treeID)) do
					local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)

					-- Entries are the choices in each node.
					-- Choice nodes have two, otherwise there's only one.
					for _, entryID in pairs(nodeInfo.entryIDs) do
						local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
						-- Definition seems a useless layer between entry and spellID.
						-- Blizzard's in-game API help about them is currently completely wrong
						-- about what fields it has. Currently the only field I see is spellID.
						local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
						local spellID = definitionInfo.spellID
						local name, _, tex = GetSpellInfo(spellID)

						-- The ranks are stored on the node, but we
						-- have to make sure that we're looking at the ranks for the
						-- currently selected entry for the talent.
						local ranks = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID == entryID and nodeInfo.ranksPurchased or 0

						local lower = name and strlowerCache[name]
						if lower then
							Env.TalentMap[lower] = ranks
							Env.TalentMap[spellID] = ranks
						end
					end
				end
			end
		end

		wipe(Env.PvpTalentMap)
		local ids = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
		for _, id in pairs(ids) do
			local _, name = GetPvpTalentInfoByID(id);
			local lower = name and strlowerCache[name]
			if lower then
				Env.PvpTalentMap[lower] = true
				Env.PvpTalentMap[id] = true
			end
		end
	end

	ConditionCategory:RegisterCondition(9,	 "TALENTLEARNED", {
		text = L["UIPANEL_TALENTLEARNED"],
		bool = true,
		funcstr = "DEPRECATED",
		upgrade = function(conditionSettings)
			-- Used to be boolean, where 0==true and 1==false.
			conditionSettings.Operator = conditionSettings.Level == 0 and ">" or "=="
			conditionSettings.Level = 0
			conditionSettings.Type = "PTSINTAL"
		end,
	})

	local initUpdate = false
	local function setupTalentEvents()
		-- this is handled externally because TalentMap is so extensive a process,
		-- and if it ends up getting processed in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
		CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
		-- APSC is needed to detect changes in spec - the others are too early I guess?
		CNDT:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE")

		local function onTraitUpdated() 
			-- I... just... you just have do to it this way, ok?
			-- Sometimes the data is available right away, sometimes you have to wait a frame.
			CNDT:PLAYER_TALENT_UPDATE()
			C_Timer.After(0, function()
				CNDT:PLAYER_TALENT_UPDATE()
			end)
		end
		
		CNDT:RegisterEvent("TRAIT_CONFIG_UPDATED", onTraitUpdated)
		CNDT:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED", onTraitUpdated)
		-- TRAIT_TREE_CHANGED needed for detecting some loadout changes,
		-- including when changing between two identical loadouts.
		-- Except obnoxiously the data isn't available immediately.
		CNDT:RegisterEvent("TRAIT_TREE_CHANGED", function() 
			C_Timer.After(0.5, function()
				CNDT:PLAYER_TALENT_UPDATE()
			end)
		end)
		if not initUpdate then
			initUpdate = true
			CNDT:PLAYER_TALENT_UPDATE()
		end
	end

	local talentEvents = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
			ConditionObject:GenerateNormalEventString("TRAIT_CONFIG_UPDATED"),
			ConditionObject:GenerateNormalEventString("TRAIT_CONFIG_LIST_UPDATED"),
			ConditionObject:GenerateNormalEventString("ACTIVE_PLAYER_SPECIALIZATION_CHANGED"),
			ConditionObject:GenerateNormalEventString("TMW_TALENT_LOADOUT_NAME_UPDATE"),
			ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
	end

	ConditionCategory:RegisterCondition(9,	 "PTSINTAL", {
		text = L["UIPANEL_PTSINTAL"],
		min = 0,
		max = 3,
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = "talents",
		icon = "Interface\\Icons\\ability_revendreth_priest",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = function(c)
			setupTalentEvents()
			return [[(TalentMap[c.Spells.First] or 0) c.Operator c.Level]]
		end,
		events = talentEvents,
	})
	
	ConditionCategory:RegisterCondition(9.1,	 "TALENTLOADOUT", {
		text = L["UIPANEL_TALENTLOADOUT"],
		bool = true,
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["UIPANEL_TALENTLOADOUT"], L["CONDITIONPANEL_NAMETOOLTIP"])
		end,
		useSUG = "talentloadout",
		allowMultipleSUGEntires = true,
		icon = "Interface\\Icons\\ability_ardenweald_druid",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = function(c)
			setupTalentEvents()
			return [[BOOLCHECK(MULTINAMECHECK( CurrentLoadoutName ))]]
		end,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("TMW_TALENT_LOADOUT_NAME_UPDATE")
		end,
	})

elseif GetNumTalentTabs then
	-- Wrath
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
			CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "CHARACTER_POINTS_CHANGED")
			CNDT:CHARACTER_POINTS_CHANGED()

			return [[(TalentMap[c.Spells.FirstString] or 0) c.Operator c.Level]]
		end,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("CHARACTER_POINTS_CHANGED"),
				ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	})
else
	-- MOP-Shadowlands
	function CNDT:PLAYER_TALENT_UPDATE()
		wipe(Env.TalentMap)
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, name, _, selected, available, _, _, _, _, _, grantedByAura = GetTalentInfo(tier, column, 1)
				local lower = name and strlowerCache[name]
				selected = selected or grantedByAura
				if lower then
					Env.TalentMap[lower] = selected
					Env.TalentMap[id] = selected
				end
			end
		end

		if GetPvpTalentInfoByID then
			wipe(Env.PvpTalentMap)
			local ids = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
			for _, id in pairs(ids) do
				local _, name = GetPvpTalentInfoByID(id);
				local lower = name and strlowerCache[name]
				if lower then
					Env.PvpTalentMap[lower] = true
					Env.PvpTalentMap[id] = true
				end
			end
		end
	end
	ConditionCategory:RegisterCondition(9,	 "TALENTLEARNED", {
		text = L["UIPANEL_TALENTLEARNED"],

		bool = true,
		
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = "talents",
		icon = function() return select(3, GetTalentInfo(1, 1, 1)) end,
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = function(c)
			-- this is handled externally because TalentMap is so extensive a process,
			-- and if it ends up getting processed in an OnUpdate condition, it could be very bad.
			CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
			CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
			CNDT:PLAYER_TALENT_UPDATE()
		
			return [[BOOLCHECK( TalentMap[LOWER(c.Spells.First)] )]]
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
		min = 0,
		max = 5,
	})
end

if GetGlyphSocketInfo then
	local GetGlyphSocketInfo = GetGlyphSocketInfo
	function CNDT:GLYPH_UPDATED()
		local GlyphLookup = Env.GlyphLookup
		wipe(GlyphLookup)
		if TMW.isCata then
			-- Cata
			for i = 1, 9 do
				local _, _, _, spellID = GetGlyphSocketInfo(i)
				if spellID then
					GlyphLookup[spellID] = 1
					
					local name = GetSpellInfo(spellID)
					name = strlowerCache[name]
					GlyphLookup[name] = 1
				end
			end
		else
			-- Wrath
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
		
			return [[BOOLCHECK( GlyphLookup[c.Spells.First] )]]
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
else
	ConditionCategory:RegisterCondition(11,	 "GLYPH", {
		text = L["UIPANEL_GLYPH"],
		tooltip = L["UIPANEL_GLYPH_DESC"],

		bool = true,
		
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["GLYPHTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		icon = "Interface\\Icons\\inv_inscription_tradeskill01",
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = "DEPRECATED",
	})
end

if GetPvpTalentInfoByID then
	ConditionCategory:RegisterCondition(10,	 "PVPTALENTLEARNED", {
		text = L["UIPANEL_PVPTALENTLEARNED"],

		bool = true,
		
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = "pvptalents",
		icon = 1322720,
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = function(c)
			-- this is handled externally because PvpTalentMap is so extensive a process,
			-- and if it ends up getting processed in an OnUpdate condition, it could be very bad.
			CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
			CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
			CNDT:PLAYER_TALENT_UPDATE()
		
			return [[BOOLCHECK( PvpTalentMap[LOWER(c.Spells.First)] )]]
		end,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("PLAYER_TALENT_UPDATE"),
				ConditionObject:GenerateNormalEventString("ACTIVE_TALENT_GROUP_CHANGED")
		end,
	})
end

ConditionCategory:RegisterSpacer(20)



if IsInJailersTower then
	local AnimaPowWatcher = TMW:NewModule("ANIMAPOW", "AceEvent-3.0")
	local currentAnimaPows = {}
	Env.CurrentAnimaPows = currentAnimaPows
	function AnimaPowWatcher:Init()
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnLocationUpdate")
		self:OnLocationUpdate()
	end
	function AnimaPowWatcher:OnLocationUpdate()
		if IsInJailersTower() and not self.watching then
			self:RegisterEvent("UNIT_AURA")
			self.watching = true
			self:UNIT_AURA(nil, "player")
		elseif not IsInJailersTower() and self.watching then
			wipe(currentAnimaPows)
			TMW:Fire("TMW_ANIMA_POWER_COUNT_CHANGED")
			self:UnregisterEvent("UNIT_AURA")
			self.watching = false
		end
	end
	function AnimaPowWatcher:UNIT_AURA(_, unit)
		if unit ~= "player" then return end

		for i=1, 300 do
			local name, _, count, _, _, _, _, _, _, spellID = UnitAura("player", i, "MAW");
			if not spellID then return end
			if count == 0 then
				count = 1;
			end

			if currentAnimaPows[spellID] ~= count then
				currentAnimaPows[spellID] = count;
				currentAnimaPows[strlowerCache[name]] = count;
				TMW:Fire("TMW_ANIMA_POWER_COUNT_CHANGED")
			end
		end
	end

	ConditionCategory:RegisterCondition(21, "ANIMAPOW", {
		text = L["CONDITIONPANEL_ANIMAPOW"],
		range = 5,
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = true,
		icon = 3528304,
		tcoords = CNDT.COMMON.standardtcoords,
		funcstr = function(c)
			AnimaPowWatcher:Init()
			return [[(CurrentAnimaPows[LOWER(c.Spells.First)] or 0) c.Operator c.Level]]
		end,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("TMW_ANIMA_POWER_COUNT_CHANGED")
		end,
	})
end

if C_Covenants then
	TMW.CovenantIcons = {
		[1] = TMW.GetSpellTexture(321076),
		[2] = TMW.GetSpellTexture(321079),
		[3] = TMW.GetSpellTexture(299206),
		[4] = TMW.GetSpellTexture(321078),
	}
	ConditionCategory:RegisterCondition(22, "COVENANT", {
		text = L["CONDITIONPANEL_COVENANT"],
		unit = PLAYER,

		bitFlags = (function()
			local t = {}
			for i, id in pairs(C_Covenants.GetCovenantIDs()) do
				local data = C_Covenants.GetCovenantData(id);
				t[i] = {
					order = i,
					text = data.name,
					icon = TMW.CovenantIcons[id],
					tcoords = CNDT.COMMON.standardtcoords,
				}
			end
			return t
		end)(),

		icon = 3257748,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			GetActiveCovenantID = C_Covenants.GetActiveCovenantID,
		},
		funcstr = function(c)
			return [[ BITFLAGSMAPANDCHECK( GetActiveCovenantID() or 0 ) ]]
		end,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("COVENANT_CHOSEN")
		end,
	})
end

if C_Soulbinds then
	ConditionCategory:RegisterCondition(23, "SOULBIND", {
		text = L["CONDITIONPANEL_SOULBIND"],
		bool = true,
		unit = PLAYER,
		name = function(editbox)
			editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		end,
		useSUG = "soulbind",
		icon = 3528291,
		tcoords = CNDT.COMMON.standardtcoords,
		Env = {
			GetActiveSoulbindID = C_Soulbinds.GetActiveSoulbindID,
		},
		funcstr = function(c)
			local id = c.Name:trim()
			if not tonumber(id) then
				for i = 1, 30 do
					local data = C_Soulbinds.GetSoulbindData(i)
					if strlowerCache[data.name] == strlowerCache[c.Name] then
						id = i
						break
					end
				end
			end
			if not tonumber(id) then
				return "false"
			end
		
			return "BOOLCHECK( GetActiveSoulbindID() == " .. id .. " )"
		end,
		events = function(ConditionObject, c)
			return
				ConditionObject:GenerateNormalEventString("SOULBIND_ACTIVATED")
		end,
	})
end

-- C_AzeriteEssence exists in wrath... gg blizz
if C_AzeriteEssence and TMW.isRetail then
	CNDT.Env.AzeriteEssenceMap = {}
	CNDT.Env.AzeriteEssenceMap_MAJOR = {}
	local C_AzeriteEssence = C_AzeriteEssence
	function CNDT:AZERITE_ESSENCE_UPDATE()
		wipe(Env.AzeriteEssenceMap)
		wipe(Env.AzeriteEssenceMap_MAJOR)
		local milestones = C_AzeriteEssence.GetMilestones()
		if not milestones then return end
		
		for _, slot in pairs(milestones) do
			if slot.unlocked then
				local equippedEssenceId = C_AzeriteEssence.GetMilestoneEssence(slot.ID)
				if equippedEssenceId then
					local essence = C_AzeriteEssence.GetEssenceInfo(equippedEssenceId)
					local name = essence.name
					local id = essence.ID

					local lower = name and strlowerCache[name]
					if lower then
						Env.AzeriteEssenceMap[lower] = true
						Env.AzeriteEssenceMap[id] = true

						-- Slot 0 is the major slot. There doesn't seem to be any other way to identify it.
						if slot.slot == 0 then 
							Env.AzeriteEssenceMap_MAJOR[lower] = true
							Env.AzeriteEssenceMap_MAJOR[id] = true
						end
					end
				end
			end
		end
	end

	for i, kind in TMW:Vararg("", "_MAJOR") do
		ConditionCategory:RegisterCondition(30 + i/10,	"AZESSLEARNED" .. kind, {
			text = L["UIPANEL_AZESSLEARNED" .. kind],
			bool = true,
			unit = PLAYER,
			name = function(editbox)
				editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
			end,
			useSUG = "azerite_essence",
			icon = "Interface\\Icons\\" .. (kind == "" and "inv_radientazeritematrix" or "spell_azerite_essence_15"),
			tcoords = CNDT.COMMON.standardtcoords,
			funcstr = function(c)
				CNDT:RegisterEvent("AZERITE_ESSENCE_UPDATE")
				CNDT:RegisterEvent("AZERITE_ESSENCE_ACTIVATED", "AZERITE_ESSENCE_UPDATE")
				CNDT:AZERITE_ESSENCE_UPDATE()
				
				return [[BOOLCHECK( AzeriteEssenceMap]] .. kind .. [[[LOWER(c.Spells.First)] )]]
			end,
			events = function(ConditionObject, c)
				return
					ConditionObject:GenerateNormalEventString("AZERITE_ESSENCE_UPDATE"),
					ConditionObject:GenerateNormalEventString("AZERITE_ESSENCE_ACTIVATED")
			end,
		})
	end
end
