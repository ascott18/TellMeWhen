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
local strlowerCache = TMW.strlowerCache

local tonumber, pairs, ipairs, wipe, assert =
      tonumber, pairs, ipairs, wipe, assert
local strfind, strmatch, strtrim, gsub, gmatch, strsplit, abs =
      strfind, strmatch, strtrim, gsub, gmatch, strsplit, abs
local GetNumRaidMembers, GetNumPartyMembers =
      GetNumRaidMembers, GetNumPartyMembers
local UnitName, UnitExists =
      UnitName, UnitExists
local GetPartyAssignment, GetNumGroupMembers, GetNumSubgroupMembers, IsInRaid =
      GetPartyAssignment, GetNumGroupMembers, GetNumSubgroupMembers, IsInRaid

local _, pclass = UnitClass("Player")
local pname = UnitName("player")


local UNITS = TMW:NewModule("Units", "AceEvent-3.0")

TMW.UNITS = UNITS

UNITS.mtMap, UNITS.maMap = {}, {}
UNITS.gpMap = {}
UNITS.unitsWithExistsEvent = {}
local unitsWithExistsEvent = UNITS.unitsWithExistsEvent
UNITS.unitsWithBaseExistsEvent = {}

UNITS.Units = {
	{ value = "player", 			text = PLAYER .. " " .. L["PLAYER_DESC"]  		  },
	{ value = "target", 			text = TARGET 									  },
	{ value = "targettarget", 		text = L["ICONMENU_TARGETTARGET"] 				  },
	{ value = "focus", 				text = L["ICONMENU_FOCUS"] 						  },
	{ value = "focustarget", 		text = L["ICONMENU_FOCUSTARGET"] 				  },
	{ value = "pet", 				text = PET 										  },
	{ value = "pettarget", 			text = L["ICONMENU_PETTARGET"] 					  },
	{ value = "mouseover", 			text = L["ICONMENU_MOUSEOVER"] 					  },
	{ value = "mouseovertarget",	text = L["ICONMENU_MOUSEOVERTARGET"]  			  },
	{ value = "vehicle", 			text = L["ICONMENU_VEHICLE"] 					  },
	{ value = "party", 				text = PARTY, 			range = MAX_PARTY_MEMBERS },
	{ value = "raid", 				text = RAID, 			range = MAX_RAID_MEMBERS  },
	{ value = "arena",				text = ARENA, 			range = 5				  },
	{ value = "boss", 				text = BOSS, 			range = MAX_BOSS_FRAMES	  },
	{ value = "maintank", 			text = L["MAINTANK"], 	range = MAX_RAID_MEMBERS  },
	{ value = "mainassist", 		text = L["MAINASSIST"],	range = MAX_RAID_MEMBERS  },
}


local TEMP_conditionsSettingSource


-- Public Methods/Stuff:
function TMW:GetUnits(icon, setting, Conditions)
	assert(setting, "Setting was nil for TMW:GetUnits(" .. (icon and icon:GetName() or "<icon>") .. ", setting)")
	
	-- Dirty, dirty hack to make sure the function cacher generates new UnitSets for any changes in conditions
	TEMP_conditionsSettingSource = Conditions
	
	local UnitSet = UNITS:GetUnitSet(setting, TMW:Serialize(Conditions))
	
	TEMP_conditionsSettingSource = nil
	
	if UnitSet.ConditionObjects then
		for i, ConditionObject in ipairs(UnitSet.ConditionObjects) do
			ConditionObject:RequestAutoUpdates(UnitSet, true)
		end
		TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", UnitSet)
	end
	
	
	return UnitSet.exposedUnits, UnitSet
end


-- Private Methods/Stuff:
local UnitSet = TMW:NewClass("UnitSet"){
	UnitExists = function(self, unit)
		return unitsWithExistsEvent[unit] or UnitExists(unit)
	end,

	OnNewInstance = function(self, unitSettings, Conditions)		
		self.Conditions = Conditions
		
		self.unitSettings = unitSettings
		self.originalUnits = UNITS:GetOriginalUnitTable(unitSettings)
		self.updateEvents = {PLAYER_ENTERING_WORLD = true,}
		self.exposedUnits = {}
		self.allUnitsChangeOnEvent = true

		-- determine the operations that the set needs to stay updated
		for k, unit in ipairs(self.originalUnits) do
			unit = tostring(unit)
			if unit == "player" then
			--	UNITS.unitsWithExistsEvent[unit] = true -- doesnt really have an event, but do this for external checks of unitsWithExistsEvent to increase efficiency.
			-- if someone legitimately entered "playertarget" then they probably dont deserve to have increased eficiency... dont bother handling player as a base unit

			elseif unit == "target" then -- the unit exactly
				self.updateEvents.PLAYER_TARGET_CHANGED = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^target") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents.PLAYER_TARGET_CHANGED = true
				UNITS.unitsWithBaseExistsEvent[unit] = "target"
				self.allUnitsChangeOnEvent = false

			elseif unit == "pet" then -- the unit exactly
				self.updateEvents.UNIT_PET = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^pet") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents.UNIT_PET = true
				UNITS.unitsWithBaseExistsEvent[unit] = "pet"
				self.allUnitsChangeOnEvent = false

			elseif unit == "focus" then -- the unit exactly
				self.updateEvents.PLAYER_FOCUS_CHANGED = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^focus") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents.PLAYER_FOCUS_CHANGED = true
				UNITS.unitsWithBaseExistsEvent[unit] = "focus"
				self.allUnitsChangeOnEvent = false

			elseif unit:find("^raid%d+$") then -- the unit exactly
				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^raid%d+") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(raid%d+)")
				self.allUnitsChangeOnEvent = false

			elseif unit:find("^party%d+$") then -- the unit exactly
				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^party%d+") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(party%d+)")
				self.allUnitsChangeOnEvent = false

			elseif unit:find("^boss%d+$") then -- the unit exactly
				self.updateEvents.INSTANCE_ENCOUNTER_ENGAGE_UNIT = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^boss%d+") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents.INSTANCE_ENCOUNTER_ENGAGE_UNIT = true
				UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(boss%d+)")
				self.allUnitsChangeOnEvent = false

			elseif unit:find("^arena%d+$") then -- the unit exactly
				self.updateEvents.ARENA_OPPONENT_UPDATE = true
				UNITS.unitsWithExistsEvent[unit] = true
			elseif unit:find("^arena%d+") then -- the unit as a base, with something else tacked onto it.
				self.updateEvents.ARENA_OPPONENT_UPDATE = true
				UNITS.unitsWithBaseExistsEvent[unit] = unit:match("^(arena%d+)")
				self.allUnitsChangeOnEvent = false

			elseif unit:find("^maintank") or unit:find("^mainassist") then
				UNITS:UpdateTankAndAssistMap()
				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				UNITS.unitsWithExistsEvent[unit] = true
				self.hasTankAndAssistRefs = true
				UNITS.doTankAndAssistMap = true
				if not (unit:find("^maintank%d+$") or unit:find("^mainassist%d+$")) then
					self.allUnitsChangeOnEvent = false
				end
			else
				-- we found a unit and we dont really know what the fuck it is.
				-- it MIGHT be a player name (or a derrivative thereof),
				-- so register some events so that we can exchange it out with a real unitID when possible.

				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				self.updateEvents["GROUP_ROSTER_UPDATE"] = true
				self.updateEvents.UNIT_PET = true
				UNITS.doGroupedPlayersMap = true

				self.mightHaveWackyUnitRefs = true
				UNITS:UpdateGroupedPlayersMap()

				self.allUnitsChangeOnEvent = false
			end
		end

		-- Setup conditions
		if Conditions and Conditions.n > 0 then
			for k, unit in ipairs(self.originalUnits) do
				-- Get a constructor to make the ConditionObject
				local ConditionObjectConstructor = self:Conditions_GetConstructor(Conditions)
				
				-- Get a modifiable version
				local ModifiableConditions = ConditionObjectConstructor:GetPostUserModifiableConditions()
				for _, condition in TMW:InNLengthTable(ModifiableConditions) do
					condition.Unit = condition.Unit
					:gsub("^unit", unit .. "-")
					:gsub("%-%-", "-")
					:gsub("%-%-", "-")
					:trim("-")
				end
				
				-- Modifications are done. Construct the ConditionObject
				local ConditionObject = ConditionObjectConstructor:Construct()
				
				if ConditionObject then
					self.ConditionObjects = self.ConditionObjects or {}
					self.ConditionObjects[k] = ConditionObject
					self.ConditionObjects[ConditionObject] = k
				end
			end
		end		
		
		for event in pairs(self.updateEvents) do
			UNITS:RegisterEvent(event, "OnEvent")
		end

		self:Update()
	end,
	
	TMW_CNDT_OBJ_PASSING_CHANGED = function(self, event, ConditionObject, failed)
		if self.ConditionObjects[ConditionObject] then
			self:Update()
		end
	end,

	Update = function(self)
		local originalUnits, exposedUnits = self.originalUnits, self.exposedUnits
		local hasTankAndAssistRefs = self.hasTankAndAssistRefs
		local mightHaveWackyUnitRefs = self.mightHaveWackyUnitRefs
		for k = 1, #exposedUnits do
			exposedUnits[k] = nil
		end

		local ConditionObjects = self.ConditionObjects
		
		for k = 1, #originalUnits do
			local unit = originalUnits[k]
			local tankOrAssistWasSubbed, wackyUnitWasSubbed
			if hasTankAndAssistRefs then
				tankOrAssistWasSubbed = UNITS:SubstituteTankAndAssistUnit(unit, exposedUnits, #exposedUnits+1)
			end
			if mightHaveWackyUnitRefs then
				wackyUnitWasSubbed = UNITS:SubstituteGroupedUnit(unit, exposedUnits, #exposedUnits+1)
			end
			local hasExistsEvent = UNITS.unitsWithExistsEvent[unit]
			local baseUnit = UNITS.unitsWithBaseExistsEvent[unit]

			if tankOrAssistWasSubbed == nil
			and wackyUnitWasSubbed == nil
			and (not ConditionObjects or not ConditionObjects[k] or not ConditionObjects[k].Failed)
			and ((baseUnit and UnitExists(baseUnit)) or (not baseUnit and (not hasExistsEvent or UnitExists(unit))))
			then
				exposedUnits[#exposedUnits+1] = unit
			end
		end
		
		TMW:Fire("TMW_UNITSET_UPDATED", self)
	end,
}

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	for i, UnitSet in ipairs(TMW.Classes.UnitSet.instances) do
		if UnitSet.ConditionObjects then
			for i, ConditionObject in ipairs(UnitSet.ConditionObjects) do
				ConditionObject:RequestAutoUpdates(UnitSet, false)
			end
			TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", UnitSet)
		end
	end
end)

function UNITS:GetUnitSet(unitSettings, SerializedConditions)
	-- This is just a hack for the function cacher. Need a unique UnitSet for any variations in conditions.
	-- This value isn't actually used, so discard it.
	SerializedConditions = nil

	unitSettings = TMW:CleanString(unitSettings):
	lower(): -- all units should be lowercase
	gsub("[\r\n\t ]", ""):
	gsub("|cffff0000", ""): -- strip color codes (NOTE LOWERCASE)
	gsub("|r", ""):
	gsub("#", "") -- strip the # from the dropdown
	
	return UnitSet:New(unitSettings, TEMP_conditionsSettingSource)
end
TMW:MakeFunctionCached(UNITS, "GetUnitSet")

function UNITS:GetOriginalUnitTable(unitSettings)
	unitSettings = TMW:CleanString(unitSettings):
	lower(): -- all units should be lowercase
	gsub("|cffff0000", ""): -- strip color codes (NOTE LOWERCASE)
	gsub("|r", ""):
	gsub("#", "") -- strip the # from the dropdown


	--SUBSTITUTE "party" with "party1-4", etc
	for _, wholething in TMW:Vararg(strsplit(";", unitSettings)) do
		local unit = strtrim(wholething)
		for k, unitData in pairs(UNITS.Units) do
			if unitData.value == unit and unitData.range then
				unitSettings = gsub(unitSettings, wholething, unit .. "1-" .. unitData.range)
				break
			end
		end
	end

	--SUBSTITUTE RAID1-10 WITH RAID1;RAID2;RAID3;...RAID10
	for wholething, unit, firstnum, lastnum, append in gmatch(unitSettings, "(([%a%d]+) ?(%d+) ?%- ?(%d+) ?([%a%d]*)) ?;?") do
		if unit and firstnum and lastnum then

			if abs(lastnum - firstnum) > 100 then
				TMW:Print("Why on Earth would you want to track more than 100", unit, "units? I'll just ignore it and save you from possibly crashing.")
			else
				local str = ""
				local order = firstnum > lastnum and -1 or 1
				
				for i = firstnum, lastnum, order do
					str = str .. unit .. i .. append .. ";"
				end
				
				str = strtrim(str, " ;")
				wholething = gsub(wholething, "%-", "%%-") -- need to escape the dash for it to work
				unitSettings = gsub(unitSettings, wholething, str, 1)
			end
		end
	end

	local Units = TMW:SplitNames(unitSettings) -- get a table of everything

	-- REMOVE DUPLICATES
	TMW.removeTableDuplicates(Units)

	return Units
end
TMW:MakeFunctionCached(UNITS, "GetOriginalUnitTable")

function UNITS:UpdateTankAndAssistMap()
	local mtMap, maMap = UNITS.mtMap, UNITS.maMap

	wipe(mtMap)
	wipe(maMap)

	-- setup a table with (key, value) pairs as (oldnumber, newnumber)
	-- oldnumber is 7 for raid7
	-- newnumber is 1 for raid7 when the current maintank/assist is the 1st one found, 2 for the 2nd one found, etc)
	
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local raidunit = "raid" .. i
			if GetPartyAssignment("MAINTANK", raidunit) then
				mtMap[#mtMap + 1] = i
			elseif GetPartyAssignment("MAINASSIST", raidunit) then
				maMap[#maMap + 1] = i
			end
		end
	end
end

function UNITS:UpdateGroupedPlayersMap()
	local gpMap = UNITS.gpMap

	wipe(gpMap)

	gpMap[strlowerCache[pname]] = "player"
	local petname = UnitName("pet")
	if petname then
		gpMap[strlowerCache[petname]] = "pet"
	end

	-- setup a table with (key, value) pairs as (name, unitID)
	
	if IsInRaid() then
		-- Raid Players
		local numRaidMembers = GetNumGroupMembers()
		for i = 1, numRaidMembers do
			local raidunit = "raid" .. i
			local name = UnitName(raidunit)
			gpMap[strlowerCache[name]] = raidunit
		end
	
		-- Raid Pets (Process after raid players so that players with names the same as pets dont get overwritten)
		for i = 1, numRaidMembers do
			local petunit = "raidpet" .. i
			local name = UnitName(petunit)
			if name then
				-- dont overwrite a player with a pet
				gpMap[strlowerCache[name]] = gpMap[strlowerCache[name]] or petunit
			end
		end
	end
	
	-- Party Players
	local numPartyMembers = GetNumSubgroupMembers()
	for i = 1, numPartyMembers do
		local raidunit = "party" .. i
		local name = UnitName(raidunit)
		gpMap[strlowerCache[name]] = raidunit
	end
	
	-- Party Pets (Process after party players so that players with names the same as pets dont get overwritten)
	for i = 1, numPartyMembers do
		local petunit = "party" .. i
		local name = UnitName(petunit)
		if name then
			-- dont overwrite a player with a pet
			gpMap[strlowerCache[name]] = gpMap[strlowerCache[name]] or petunit
		end
	end
end

function UNITS:OnEvent(event, ...)

	if (event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") and UNITS.doTankAndAssistMap then
		UNITS:UpdateTankAndAssistMap()
	end
	if UNITS.doGroupedPlayersMap
	and (
		event == "GROUP_ROSTER_UPDATE"
		or event == "RAID_ROSTER_UPDATE"
		or event == "PARTY_MEMBERS_CHANGED"
		or event == "UNIT_PET"
	) then
		UNITS:UpdateGroupedPlayersMap()
	end

	local instances = UnitSet.instances
	for i = 1, #instances do
		local unitSet = instances[i]
		if unitSet.updateEvents[event] then
			unitSet:Update()
		end
	end
end

function UNITS:SubstituteTankAndAssistUnit(oldunit, table, key, putInvalidUnitsBack)
	if strfind(oldunit, "^maintank") then -- the old unit (maintank1)
		local newunit = gsub(oldunit, "maintank", "raid") -- the new unit (raid1) (number not changed yet)
		local oldnumber = tonumber(strmatch(newunit, "(%d+)")) -- the old number (1)
		local newnumber = oldnumber and UNITS.mtMap[oldnumber] -- the new number(7)
		if newnumber then
			table[key] = gsub(newunit, oldnumber, newnumber)
			return true
		elseif putInvalidUnitsBack then
			table[key] = oldunit
		end
		return false -- placement of this inside the if block is crucial
	elseif strfind(oldunit, "^mainassist") then
		local newunit = gsub(oldunit, "mainassist", "raid")
		local oldnumber = tonumber(strmatch(newunit, "(%d+)"))
		local newnumber = oldnumber and UNITS.maMap[oldnumber]
		if newnumber then
			table[key] = gsub(newunit, oldnumber, newnumber)
			return true
		elseif putInvalidUnitsBack then
			table[key] = oldunit
		end
		return false -- placement of this inside the if block is crucial
	end
end

function UNITS:SubstituteGroupedUnit(oldunit, table, key)
	for groupedName, groupedUnitID in pairs(UNITS.gpMap) do
		local atBeginning = "^" .. groupedName
		if strfind(oldunit, atBeginning .. "$") or strfind(oldunit, atBeginning .. "%-.") then
			table[key] = gsub(oldunit, atBeginning .. "%-?", groupedUnitID)
			return true
		end
	end
end


do--function UNITS:TestUnit(unit)
	local TestTooltip = CreateFrame("GameTooltip")
	local name, unitID
	TestTooltip:SetScript("OnTooltipSetUnit", function(self)
		name, unitID = self:GetUnit()
	end)

	function UNITS:TestUnit(unit)
		name, unitID = nil
		
		TestTooltip:SetUnit(unit)
		
		return unitID
	end
end


do
	local CNDT = TMW.CNDT
	CNDT:RegisterConditionSetImplementingClass("UnitSet")
	
	TMW:RegisterUpgrade(60344, {
		icon = function(self, ics)
			for n, condition in TMW:InNLengthTable(ics.UnitConditions) do
				condition.Unit = "unit"
			end
		end,
	})

	local ConditionSet = {
		parentSettingType = "icon",
		parentDefaults = TMW.Icon_Defaults,
		modifiedDefaults = {
			Unit = "unit",
		},
		
		settingKey = "UnitConditions",
		GetSettings = function(self)
			return TMW.CI.ics.UnitConditions
		end,
		
		iterFunc = TMW.InIconSettings,
		iterArgs = {
			[1] = TMW,
		},

		useDynamicTab = true,
		ShouldShowTab = function(self)
			return TellMeWhen_Unit and TellMeWhen_Unit:IsShown()
		end,
		tabText = L["UNITCONDITIONS"],
		tabTooltip = L["UNITCONDITIONS_TAB_DESC"],
		
		ConditionTypeFilter = function(self, conditionData)
			if conditionData.unit == nil then
				return true
			elseif conditionData.identifier == "LUA" then
				return true
			end
		end,
		TMW_CNDT_GROUP_DRAWGROUP = function(self, event, conditionGroup, conditionData, conditionSettings)
			if CNDT.CurrentConditionSet == self then
				TMW.SUG:EnableEditBox(conditionGroup.Unit, "unitconditionunits", true)
				TMW:TT(conditionGroup.Unit, "CONDITIONPANEL_UNIT", "ICONMENU_UNIT_DESC_UNITCONDITIONUNIT")
			end
		end,
	}
	TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", ConditionSet)
	CNDT:RegisterConditionSet("Unit", ConditionSet)
end