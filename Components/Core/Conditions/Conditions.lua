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
local Env

-- -----------------------
-- LOCALS/GLOBALS/UTILITIES
-- -----------------------

local L = TMW.L
local _, pclass = UnitClass("Player")

local tostring, type, pairs, ipairs, tremove, unpack, select, tonumber, wipe, assert, next, loadstring, setfenv, setmetatable =
	  tostring, type, pairs, ipairs, tremove, unpack, select, tonumber, wipe, assert, next, loadstring, setfenv, setmetatable
local strlower, min, max, gsub, strfind, strsub, strtrim, format, strmatch, strsplit, strrep =
	  strlower, min, max, gsub, strfind, strsub, strtrim, format, strmatch, strsplit, strrep
local NONE = NONE

local _G = _G
local print = TMW.print
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber
local huge = math.huge

local time = GetTime()
	
local CNDT = TMW:NewModule("Conditions", "AceEvent-3.0", "AceSerializer-3.0") TMW.CNDT = CNDT
CNDT.SpecialUnitsUsed = {}

local functionCache = {} CNDT.functionCache = functionCache

TMW.Condition_Defaults = {
	n 					= 0,
	["**"] = {
		AndOr 	   		= "AND",
		Type 	   		= "",
		Icon 	   		= "",
		Operator   		= "==",
		Level 	   		= 0,
		Unit 	   		= "player",
		Name 	   		= "",
		Name2 	   		= "",
		PrtsBefore 		= 0,
		PrtsAfter  		= 0,
		Checked			= false,
		Checked2   		= false,
		Runes 	   		= {},
	},
}
setmetatable(TMW.Condition_Defaults["**"], {
	__newindex = function(self, k, v)
		if TMW.Initialized then
			error("New condition defaults cannot be added after the database has already been initialized", 2)
		end
		TMW:Fire("TMW_CNDT_DEFAULTS_NEWVAL", k, v)
		rawset(self, k, v)
	end,
})

function CNDT:RegisterConditionDefaults(self, defaults)
	assert(type(defaults) == "table", "arg1 to RegisterGroupDefaults must be a table")
	
	if TMW.Initialized then
		error(("Defaults for conditions are being registered too late. They need to be registered before the database is initialized."):format(self.name or "<??>"))
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, TMW.Condition_Defaults["**"])
end


TMW:RegisterUpgrade(60026, {
	stances = {
		{class = "WARRIOR", 	id = 2457}, 	-- Battle Stance
		{class = "WARRIOR", 	id = 71}, 		-- Defensive Stance
		{class = "WARRIOR", 	id = 2458}, 	-- Berserker Stance

		{class = "DRUID", 		id = 5487}, 	-- Bear Form
		{class = "DRUID", 		id = 768}, 		-- Cat Form
		{class = "DRUID", 		id = 1066}, 	-- Aquatic Form
		{class = "DRUID", 		id = 783}, 		-- Travel Form
		{class = "DRUID", 		id = 24858}, 	-- Moonkin Form
		{class = "DRUID", 		id = 33891}, 	-- Tree of Life
		{class = "DRUID", 		id = 33943}, 	-- Flight Form
		{class = "DRUID", 		id = 40120}, 	-- Swift Flight Form

		{class = "PRIEST", 		id = 15473}, 	-- Shadowform

		{class = "ROGUE", 		id = 1784}, 	-- Stealth

		{class = "HUNTER", 		id = 82661}, 	-- Aspect of the Fox
		{class = "HUNTER", 		id = 13165}, 	-- Aspect of the Hawk
		{class = "HUNTER", 		id = 5118}, 	-- Aspect of the Cheetah
		{class = "HUNTER", 		id = 13159}, 	-- Aspect of the Pack
		{class = "HUNTER", 		id = 20043}, 	-- Aspect of the Wild

		{class = "DEATHKNIGHT", id = 48263}, 	-- Blood Presence
		{class = "DEATHKNIGHT", id = 48266}, 	-- Frost Presence
		{class = "DEATHKNIGHT", id = 48265}, 	-- Unholy Presence

		{class = "PALADIN", 	id = 19746}, 	-- Concentration Aura
		{class = "PALADIN", 	id = 32223}, 	-- Crusader Aura
		{class = "PALADIN", 	id = 465}, 		-- Devotion Aura
		{class = "PALADIN", 	id = 19891}, 	-- Resistance Aura
		{class = "PALADIN", 	id = 7294}, 	-- Retribution Aura

		{class = "WARLOCK", 	id = 47241}, 	-- Metamorphosis
		
		--[[{class = "MONK", 		id = 115069}, 	-- Sturdy Ox
		{class = "MONK", 		id = 115070}, 	-- Wise Serpent
		{class = "MONK", 		id = 103985}, 	-- Fierce Tiger]]
	},
	
	setupcsn = function(self)
		self.CSN = {
			[0]	= NONE,
		}

		for _, stanceData in ipairs(self.stances) do
			if stanceData.class == pclass then
				local stanceName = GetSpellInfo(stanceData.id)
				tinsert(self.CSN, stanceName)
			end
		end

		for i, stanceName in pairs(self.CSN) do
			self.CSN[stanceName] = i
		end

	end,
	condition = function(self, condition)
		if condition.Type == "STANCE" then
			if not self.CSN then
				self:setupcsn()
			end
			
			-- Make sure that there actually are stances for this class
			if self.CSN[1] then
				condition.Name = ""
				
				if condition.Operator == "==" then
					condition.Name = self.CSN[condition.Level]
					condition.Level = 0 -- true
				elseif condition.Operator == "~=" then
					condition.Name = self.CSN[condition.Level]
					condition.Level = 1 -- false
				elseif condition.Operator:find(">") then
					condition.Name = ""
					
					-- If the operator is >= then include the condition at condition.Level
					-- If the operator is > then start on the condition immediately after condition.Level
					local startOffset = condition.Operator:find("=") and 0 or 1
					
					for i = condition.Level + startOffset, #self.CSN do
						condition.Name = condition.Name .. self.CSN[i] .. "; "
					end
					condition.Name = condition.Name:sub(1, -3) -- trim off the ending semicolon and space
					
					condition.Level = 0 -- true
				elseif condition.Operator:find("<") then
					condition.Name = ""
					
					-- If the operator is >= then include the condition at condition.Level
					-- If the operator is > then start on the condition immediately before condition.Level
					local startOffset = condition.Operator:find("=") and 0 or 1
					
					-- Iterate backwards towards 1
					for i = condition.Level - startOffset, 1, -1 do
						condition.Name = condition.Name .. self.CSN[i] .. "; "
					end
					condition.Name = condition.Name:sub(1, -3) -- trim off the ending semicolon and space
					
					condition.Level = 0 -- true
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(51008, {
	condition = function(self, condition)
		if condition.Type == "TOTEM1"
		or condition.Type == "TOTEM2"
		or condition.Type == "TOTEM3"
		or condition.Type == "TOTEM4"
		then
			condition.Name = ""
		end
	end,
})
TMW:RegisterUpgrade(46417, {
	-- cant use the conditions key here because it depends on Conditions.n, which is 0 until this is ran
	-- also, dont use TMW:InNLengthTable because it will use conditions.n, which is 0 until the upgrade is complete
	group = function(self, gs)
		local n = 0
		for k in pairs(gs.Conditions) do
			if type(k) == "number" then
				n = max(n, k)
			end
		end
		gs.Conditions.n = n
	end,
	icon = function(self, ics)
		local n = 0
		for k in pairs(ics.Conditions) do
			if type(k) == "number" then
				n = max(n, k)
			end
		end
		ics.Conditions.n = n
	end,
})
TMW:RegisterCallback("TMW_DB_PRE_DEFAULT_UPGRADES", function() -- 46413
	-- The default condition type changed from "HEALTH" to "" in v46413
	-- So, if the user is upgrading to this version, and Condition.Type is nil,
	-- then it must have previously been set to "HEALTH", causing Ace3DB not to store it,
	-- so explicity set it as "HEALTH" to make sure it doesn't change just because the default changed.
	
	if TellMeWhenDB.profiles and TellMeWhenDB.Version < 46413 then
		for _, p in pairs(TellMeWhenDB.profiles) do
			if p.Groups then
				for _, gs in pairs(p.Groups) do
					if gs.Conditions then
						for k, Condition in pairs(gs.Conditions) do
							if type(k) == "number" and Condition.Type == nil then
								Condition.Type = "HEALTH"
							end
						end
					end
					if gs.Icons then
						for _, ics in pairs(gs.Icons) do
							if ics.Conditions then
								for k, Condition in pairs(ics.Conditions) do
									if type(k) == "number" and Condition.Type == nil then
										Condition.Type = "HEALTH"
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)
TMW:RegisterUpgrade(45802, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "CASTING" then
				condition.Name = ""
			end
		end
	end,
})
TMW:RegisterUpgrade(44202, {
	icon = function(self, ics)
		ics.Conditions["**"] = nil
	end,
})
TMW:RegisterUpgrade(42105, {
	-- cleanup some old stuff that i noticed is sticking around in my settings, probably in other peoples' settings too
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" then
				for k in pairs(condition) do
					if strfind(k, "Condition") then
						condition[k] = nil
					end
				end
				condition.Names = nil
			end
		end
	end,
})
TMW:RegisterUpgrade(41206, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "STANCE" then
				condition.Operator = "=="
			end
		end
	end,
})
TMW:RegisterUpgrade(41008, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" then
				if condition.Type == "SPELLCD" or condition.Type == "ITEMCD" then
					if condition.Level == 0 then
						condition.Operator = "=="
					elseif condition.Level == 1 then
						condition.Operator = ">"
						condition.Level = 0
					end
				elseif condition.Type == "MAINHAND" or condition.Type == "OFFHAND" or condition.Type == "THROWN" then
					if condition.Level == 0 then
						condition.Operator = ">"
					elseif condition.Level == 1 then
						condition.Operator = "=="
						condition.Level = 0
					end
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(41004, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" then
				if condition.Type == "BUFF" then
					condition.Type = "BUFFSTACKS"
				elseif condition.Type == "DEBUFF" then
					condition.Type = "DEBUFFSTACKS"
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(40115, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and (condition.Type == "BUFF" or condition.Type == "DEBUFF") then
				if condition.Level == 0 then
					condition.Operator = ">"
				elseif condition.Level == 1 then
					condition.Operator = "=="
					condition.Level = 0
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(40112, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "CASTING" then
				condition.Level = condition.Level + 1
			end
		end
	end,
})
TMW:RegisterUpgrade(40106, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "ITEMINBAGS" then
				if condition.Level == 0 then
					condition.Operator = ">"
				elseif condition.Level == 1 then
					condition.Operator = "=="
					condition.Level = 0
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(40100, {
	icon = function(self, ics)
		for k, condition in pairs(ics.Conditions) do
			if type(k) == "number" and condition.Type == "NAME" then
				condition.Level = 0
			end
		end
	end,
})
TMW:RegisterUpgrade(40080, {
	icon = function(self, ics)
		for k, v in pairs(ics.Conditions) do
			if type(k) == "number" and v.Type == "ECLIPSE_DIRECTION" and v.Level == -1 then
				v.Level = 0
			end
		end
	end,
})
TMW:RegisterUpgrade(22010, {
	icon = function(self, ics)
		for k, condition in ipairs(ics.Conditions) do
			if type(k) == "number" then
				for k, v in pairs(condition) do
					condition[k] = nil
					condition[k:gsub("Condition", "")] = v
				end
			end
		end
	end,
})
TMW:RegisterUpgrade(22000, {
	icon = function(self, ics)
		for k, v in ipairs(ics.Conditions) do
			if type(k) == "number" and ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
				v.ConditionLevel = 0
			end
		end
	end,
})
TMW:RegisterUpgrade(20100, {
	icon = function(self, ics)
		for k, v in ipairs(ics.Conditions) do
			v.ConditionLevel = tonumber(v.ConditionLevel) or 0
			if type(k) == "number" and ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
				v.ConditionLevel = ceil((v.ConditionLevel/100)*3)
			end
		end
	end,
})




function CNDT:RAID_ROSTER_UPDATE()
	TMW.UNITS:UpdateTankAndAssistMap()
	for oldunit in pairs(Env) do
		if CNDT.SpecialUnitsUsed[oldunit] then
			TMW.UNITS:SubstituteTankAndAssistUnit(oldunit, Env, oldunit, true)
		end
	end
end

Env = {
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	strlower = strlower,
	strlowerCache = TMW.strlowerCache,
	strfind = strfind,
	floor = floor,
	select = select,
	min = min,
	
	print = TMW.print,
	type = type,
	time = TMW.time,
	huge = math.huge,
	epsilon = 1e-255,

	TMW = TMW,
	GCDSpell = TMW.GCDSpell,
} CNDT.Env = Env

TMW:RegisterCallback("TMW_ONUPDATE_PRE", function(event, time_arg)
	time = time_arg
	Env.time = time_arg
end)

Env.SemicolonConcatCache = setmetatable(
{}, {
	__index = function(t, i)
		if not i then return end

		local o = ";" .. strlowerCache[i] .. ";"
		
		-- escape ()[]-+*. since the purpose of this is to be the 2nd arg to strfind
		o = o:gsub("([%(%)%%%[%]%-%+%*%.])", "%%%1")
		
		t[i] = o
		return o
	end,
})


local function formatSeconds(seconds, arg2)
	if type(seconds) == "table" then -- if i set it directly as a metamethod
		seconds = arg2
	end
	local y =  seconds / 31556925.9936
	local d = (seconds % 31556925.9936) / 86400
	local h = (seconds % 31556925.9936 % 86400) / 3600
	local m = (seconds % 31556925.9936 % 86400  % 3600) / 60
	local s = (seconds % 31556925.9936 % 86400  % 3600  % 60)

	s = tonumber(format("%.1f", s))
	if s < 10 then
		s = "0" .. s
	end

	if y >= 1 then return format("%d:%d:%02d:%02d:%s", y, d, h, m, s) end
	if d >= 1 then return format("%d:%02d:%02d:%s", d, h, m, s) end
	if h >= 1 then return format("%d:%02d:%s", h, m, s) end
	return format("%d:%s", m, s)
end

-- preset text tables that are frequently used
CNDT.COMMON = {}
CNDT.COMMON.commanumber = function(k)
	k = gsub(k, "(%d)(%d%d%d)$", "%1,%2", 1)
	local found
	repeat
		k, found = gsub(k, "(%d)(%d%d%d),", "%1,%2,", 1)
	until found == 0

	return k
end
CNDT.COMMON.percent = function(k) return k.."%" end
CNDT.COMMON.pluspercent = function(k) return "+"..k.."%" end
CNDT.COMMON.bool = {[0] = L["TRUE"],[1] = L["FALSE"],}
CNDT.COMMON.usableunusable = {[0] = L["ICONMENU_USABLE"],[1] = L["ICONMENU_UNUSABLE"],}
CNDT.COMMON.presentabsent = {[0] = L["ICONMENU_PRESENT"],[1] = L["ICONMENU_ABSENT"],}
CNDT.COMMON.absentseconds = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_ABSENT"]..")"}, {__index = formatSeconds})
CNDT.COMMON.usableseconds = setmetatable({[0] = formatSeconds(0).." ("..L["ICONMENU_USABLE"]..")"}, {__index = formatSeconds})
CNDT.COMMON.standardtcoords = {0.07, 0.93, 0.07, 0.93}

CNDT.Categories = {}
CNDT.CategoriesByID = {}
CNDT.ConditionsByType = {}

TMW:NewClass("ConditionCategory"){
	OnNewInstance = function(self, identifier, order, name, spaceBefore, spaceAfter)
		self.identifier = identifier
		self.order = order
		self.name = name
		
		self.spaceBefore = spaceBefore
		self.spaceAfter = spaceAfter
		
		self.conditionData = {}
	
		tinsert(CNDT.Categories, self)
		TMW:SortOrderedTables(CNDT.Categories)
		
		CNDT.CategoriesByID[identifier] = self
	end,
	
	RegisterCondition = function(self, order, value, conditionData)
		TMW:ValidateType("2 (order)", "ConditionCategory:RegisterCondition()", order, "number")
		TMW:ValidateType("3 (value)", "ConditionCategory:RegisterCondition()", value, "string")
		TMW:ValidateType("4 (conditionData)", "ConditionCategory:RegisterCondition()", conditionData, "table")
		
		TMW:ValidateType("funcstr", "conditionData", conditionData.funcstr, "string;function")
		
		if CNDT.ConditionsByType[value] then
			error(("Condition %q already exists."):format(value), 2)
		end
		
		conditionData.categoryIdentifier = self.identifier
		conditionData.value = value
		conditionData.order = order
		
		tinsert(self.conditionData, conditionData)
		TMW:SortOrderedTables(self.conditionData)
		
		CNDT.ConditionsByType[value] = conditionData
	end,
	
	RegisterSpacer = function(self, order)
		TMW:ValidateType("2 (order)", "ConditionCategory:RegisterCondition()", order, "number")
		
		local conditionData = {
			IS_SPACER = true,
			order = order
		}
		
		tinsert(self.conditionData, conditionData)
		TMW:SortOrderedTables(self.conditionData)
	end,
}

function CNDT:GetCategory(identifier, order, categoryName, spaceBefore, spaceAfter)
	TMW:ValidateType("2 (identifier)", "CNDT:GetCategory()", identifier, "string")
	
	if CNDT.CategoriesByID[identifier] then
		return CNDT.CategoriesByID[identifier]
	end
	
	TMW:ValidateType("3 (order)", "CNDT:GetCategory()", order, "number")
	TMW:ValidateType("4 (categoryName)", "CNDT:GetCategory()", categoryName, "string")
	
	return TMW.Classes.ConditionCategory:New(identifier, order, categoryName, spaceBefore, spaceAfter)
end


	
local EnvMeta = {
	__index = _G,
	--__newindex = _G,
} TMW.CNDT.EnvMeta = EnvMeta

function CNDT:TMW_GLOBAL_UPDATE()
	Env.Locked = TMW.Locked
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", CNDT)

function CNDT:TMW_GLOBAL_UPDATE_POST()
	for _, ConditionObject in pairs(TMW.Classes.ConditionObject.instances) do
		ConditionObject:Check()
	end
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", CNDT)

TMW:RegisterCallback("TMW_CONFIG_ICON_RECONCILIATION_REQUESTED", function(event, replace, limitSourceGroup)
	for Condition, _, groupID in TMW:InConditionSettings() do
		if not limitSourceGroup or groupID == limitSourceGroup then
			if Condition.Icon ~= "" and type(Condition.Icon) == "string" then
				replace(Condition, "Icon")
			end
		end
	end
end)

local function strWrap(string)
	local num = isNumber[string]
	if num then
		return num
	else
		return format("%q", string)
	end
end

function CNDT:GetUnit(setting)
	return TMW.UNITS:GetOriginalUnitTable(setting)[1] or ""
end

function CNDT:DoConditionSubstitutions(conditionData, condition, thisstr)
	for _, append in TMW:Vararg("2", "") do -- Unit2 MUST be before Unit
		if strfind(thisstr, "c.Unit" .. append) then
			local unit
			if append == "2" then
				unit = CNDT:GetUnit(condition.Name)
			elseif append == "" then
				unit = CNDT:GetUnit(condition.Unit)
			end
			if (strfind(unit, "maintank") or strfind(unit, "mainassist")) then
				thisstr = gsub(thisstr, "c.Unit" .. append,		unit) -- sub it in as a variable
				Env[unit] = unit
				CNDT.SpecialUnitsUsed[unit] = true
				CNDT:RegisterEvent(TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "RAID_ROSTER_UPDATE", "RAID_ROSTER_UPDATE")
				CNDT:RAID_ROSTER_UPDATE()
			else
				thisstr = gsub(thisstr, "c.Unit" .. append,	"\"" .. unit .. "\"") -- sub it in as a string
			end
		end
	end

	local name = gsub((condition.Name or ""), "; ", ";")
	name = gsub(name, " ;", ";")
	name = ";" .. name .. ";"
	name = gsub(name, ";;", ";")
	name = strtrim(name)
	name = strlower(name)

	local name2 = gsub((condition.Name2 or ""), "; ", ";")
	name2 = gsub(name2, " ;", ";")
	name2 = ";" .. name2 .. ";"
	name2 = gsub(name2, ";;", ";")
	name2 = strtrim(name2)
	name2 = strlower(name2)

	thisstr = thisstr:
	gsub("c.Level", 		conditionData.percent and condition.Level/100 or condition.Level):
	gsub("c.Checked", 		tostring(condition.Checked)):
	gsub("c.Operator", 		condition.Operator):
	gsub("c.NameFirst2", 	strWrap(TMW:GetSpellNames(nil, name2, 1))): --Name2 must be before Name
	gsub("c.NameName2", 	strWrap(TMW:GetSpellNames(nil, name2, 1, 1))):
	gsub("c.ItemID2", 		strWrap(TMW:GetItemIDs(nil, name2, 1))):
	gsub("c.Name2", 		strWrap(name2)):

	gsub("c.NameFirst", 	strWrap(TMW:GetSpellNames(nil, name, 1))):
	gsub("c.NameName", 		strWrap(TMW:GetSpellNames(nil, name, 1, 1))):
	gsub("c.ItemID", 		strWrap(TMW:GetItemIDs(nil, name, 1))):
	gsub("c.Name", 			strWrap(name)):

	gsub("c.True", 			tostring(condition.Level == 0)):
	gsub("c.False", 		tostring(condition.Level == 1)):
	gsub("c.1nil", 			condition.Level == 0 and 1 or "nil"):
	gsub("c.nil1", 			condition.Level == 1 and 1 or "nil"): -- reverse 1nil

	gsub("LOWER%((.-)%)",	strlower) -- fun gsub magic stuff

	-- extra fun stuff
	if thisstr:find("c.GCDReplacedNameFirst2") then
		local name = TMW:GetSpellNames(nil, name2, 1)
		if name == "gcd" then
			name = TMW.GCDSpell
		end
		thisstr = thisstr:gsub("c.GCDReplacedNameFirst2", "\"" .. name .. "\"")
	end
	if thisstr:find("c.GCDReplacedNameFirst") then
		local name = TMW:GetSpellNames(nil, name, 1)
		if name == "gcd" then
			name = TMW.GCDSpell
		end
		thisstr = thisstr:gsub("c.GCDReplacedNameFirst", "\"" .. name .. "\"")
	end

	return thisstr
end

function CNDT:IsUnitEventUnit(unit)
	if unit == "player" then
		return ""
	elseif unit == "target" then
		return "PLAYER_TARGET_CHANGED"
	elseif unit == "pet" then
		return "UNIT_PET|'player'"
	elseif unit == "focus" then
		return "PLAYER_FOCUS_CHANGED"
	elseif unit:find("^raid%d+$") then
		return TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "RAID_ROSTER_UPDATE"
	elseif unit:find("^party%d+$") then
		return TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "PARTY_MEMBERS_CHANGED"
	elseif unit:find("^boss%d+$") then
		return "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
	elseif unit:find("^arena%d+$") then
		return "ARENA_OPPONENT_UPDATE"
	end
	
	return "OnUpdate"
end


function CNDT:GetConditionCheckFunctionString(parent, Conditions)
	local funcstr = ""
	
	if not CNDT:CheckParentheses(Conditions) then
		return ""
	end

	for n, condition in TMW:InNLengthTable(Conditions) do
		local t = condition.Type
		local conditionData = CNDT.ConditionsByType[t]
		
		local andor
		if n == 1 then
			andor = ""
		elseif condition.AndOr == "OR" then
			andor = "or "
		elseif condition.AndOr == "AND" then
			andor = "and"
		end

		if condition.Operator == "~|=" or condition.Operator == "|="  or condition.Operator == "||=" then
			condition.Operator = "~=" -- fix potential corruption from importing a string (a single | becaomes || when pasted, "~=" in encoded as "~|=")
		end

		local thiscondtstr
		if conditionData then
		
			-- Add in anything that the condition wants to include in Env
			if conditionData.Env then
				for k, v in pairs(conditionData.Env) do
					local existingValue = rawget(Env, k)
					if existingValue ~= nil and existingValue ~= v then
						TMW:Error("Condition " .. t .. " tried to write values to Env different than those that were already in it.")
					else
						Env[k] = v
					end
				end
				
				-- nil it, because we don't want to add it again if we are storing a table that will be updated to hold some data.
				conditionData.Env = nil
			end
		
			thiscondtstr = conditionData.funcstr
			if type(thiscondtstr) == "function" then
				thiscondtstr = thiscondtstr(condition, parent)
			end
		end
		
		thiscondtstr = thiscondtstr or "true"
		
		local thisstr = andor .. "(" .. strrep("(", condition.PrtsBefore) .. thiscondtstr .. strrep(")", condition.PrtsAfter)  .. ")"

		if conditionData then
			thisstr = CNDT:DoConditionSubstitutions(conditionData, condition, thisstr)
		end
		
		funcstr = funcstr .. "    " .. thisstr .. " -- " .. n .. "_" .. condition.Type .. "\r\n"
	end
	
	if funcstr ~= "" then
		-- Well, what the fuck? Apparently this code here doesn't work in MoP. I have to do it on a single line for some strange reason.
		-- Aannnnnnddd what the fuck now it works again. See r540 commit message for more info.
		-- Aannnnnnddd im switching back to single line because multiline [[long strings]] aren't playing nice at all in debugging dumps/prints
		
		-- funcstr = [[local ConditionObject = ...
		-- return ( ]] .. funcstr .. [[ )]]
		
		funcstr = "local ConditionObject = ... \r\n return (\r\n " .. funcstr .. " )"
	end
	
	return funcstr
end




local ConditionObject = TMW:NewClass("ConditionObject")
ConditionObject.numArgsForEventString = 1

function ConditionObject:OnNewInstance(Conditions, conditionString)
	self.conditionString = conditionString

	self.AutoUpdateRequests = {}
	self.RequestedEvents = {}
	
	self.UpdateNeeded = true
	self.NextUpdateTime = huge
	self.UpdateMethod = "OnUpdate"
	
	local types = ""
	if TMW.debug then
		types = tostring(self):gsub("table: ", "_0x")
	end
	for n, condition in TMW:InNLengthTable(Conditions) do
		types = types .. "_" .. condition.Type
	end
	
	local func, err = loadstring(conditionString, "Condition" .. types)
	if func then
		func = setfenv(func, TMW.CNDT.Env)
		self.CheckFunction = setfenv(func, TMW.CNDT.Env)
	elseif err then
		TMW:Error(err)
	end
	
	self:CompileUpdateFunction(Conditions)
	
	self:Check()
end

local argCheckerStringsReusable = {}
function ConditionObject:CompileUpdateFunction(Conditions)
	local argCheckerStrings = wipe(argCheckerStringsReusable)
	local numAnticipatorResults = 0
	local anticipatorstr = ""

	for _, c in TMW:InNLengthTable(Conditions) do
		local t = c.Type
		local v = CNDT.ConditionsByType[t]
		if v and v.events then
			local voidNext
			for n, argCheckerString in TMW:Vararg(TMW.get(v.events, self, c)) do
				if argCheckerString == false or argCheckerString == nil then
					return
				elseif type(argCheckerString) == "string" then
					if argCheckerString == "OnUpdate" then
						return
					elseif argCheckerString == "" then
						TMW:Error("Condition.events shouldn't return blank strings! (From condition %q). Return STRING 'false' if you don't want the condition to update OnUpdate but it also has no events (basically, if it is static).", t)
					else
						argCheckerStrings[argCheckerString] = true
					end
				end
			end
		else
			return
		end

		-- handle code that anticipates when a change in state will occur.
		-- this is usually used to predict when a duration threshold will be used, but you could really use it for whatever you want.
		if v.anticipate then
			numAnticipatorResults = numAnticipatorResults + 1

			local thisstr = TMW.get(v.anticipate, c) -- get the anticipator string from the condition data
			thisstr = CNDT:DoConditionSubstitutions(v, c, thisstr) -- substitute in any user settings

			-- append a check to make sure that the smallest value out of all anticipation checks isnt less than the current time.
			thisstr = thisstr .. [[
			
			if VALUE <= time then
				VALUE = huge
			end
			]]

			-- change VALUE to the appropriate ANTICIPATOR_RESULT#
			thisstr = thisstr:gsub("VALUE", "ANTICIPATOR_RESULT" .. numAnticipatorResults)

			anticipatorstr = anticipatorstr .. "\r\n" .. thisstr
		end
	end

	if not next(argCheckerStrings) then
		return
	end

	local doesAnticipate
	if anticipatorstr ~= "" then
		local allVars = ""
		for i = 1, numAnticipatorResults do
			allVars = allVars .. "ANTICIPATOR_RESULT" .. i .. ","
		end
		allVars = allVars:sub(1, -2)

		anticipatorstr = anticipatorstr .. ([[
		local nextTime = %s
		if nextTime == 0 then
			nextTime = huge
		end
		ConditionObject.NextUpdateTime = nextTime]]):format((numAnticipatorResults == 1 and allVars or "min(" .. allVars .. ")"))

		doesAnticipate = true
	end

	self.UpdateMethod = "OnEvent" --DEBUG: COMMENTING THIS LINE FORCES ALL CONDITIONS TO BE ONUPDATE DRIVEN
	if TMW.db.profile.DEBUG_ForceAutoUpdate then
		self.UpdateMethod = "OnUpdate"
	end
	
	-- Begin creating the final string that will be used to make the function.
	local funcstr = [[
	if not event then
		return
	elseif (]]
	
	-- Compile all of the arg checker strings into one single composite that can be checked in an (if ... then) statement.
	local argCheckerStringComposite = ""
	for argCheckerString in pairs(argCheckerStrings) do
		if argCheckerString ~= "" then
			argCheckerStringComposite = argCheckerStringComposite .. [[(]] .. argCheckerString .. [[) or ]]
		end
	end
	
	if argCheckerStringComposite ~= "" then
		-- If any arg checkers were added to the composite (it isnt a blank string),
		-- trim off the final ") or " at the end of it.
		argCheckerStringComposite = argCheckerStringComposite:sub(1, -5)
	else
		-- The arg checker string should never ever be blank. Raise an error if it was.
		TMW:Error("The arg checker string compiled for ConditionObject %s was blank. This should not have happened.", tostring(self))
	end

	-- Tack on the composite arg checker string to the function, and then close the elseif that it goes into.
	funcstr = funcstr .. argCheckerStringComposite .. [[) then
		if ConditionObject.doesAutoUpdate then
			ConditionObject:Check()
		else
			ConditionObject.UpdateNeeded = true
		end
	end]]

	-- Add the anticipator function string to the beginning of the function string, before event handling happens.
	funcstr = anticipatorstr .. "\r\n" .. funcstr
	
	-- Finally, create the header of the function that will get all of the args passed into it.
	local argHeader = [[local ConditionObject, event]]
	for i = 1, self.numArgsForEventString do 
		argHeader = argHeader .. [[, arg]] .. i
	end
	
	-- argHeader now looks like: local ConditionObject, event, arg1, arg2, arg3, ..., argN
	
	-- Set the variables that accept the args to the vararg with all of the function input,
	-- and tack on the body of the function
	funcstr = argHeader .. [[ = ...
	]] .. funcstr

	
	local func, err = loadstring(funcstr, tostring(self) .. " Condition Events")
	if func then
		func = setfenv(func, Env)
	elseif err then
		TMW:Error(err)
	end
	
	self.updateString = funcstr

	self.AnticipateFunction = doesAnticipate and func
	self.UpdateFunction = func

	-- Register the events and the object with the UpdateEngine
	self:RegisterForUpdating()
end

function ConditionObject:Check()
	if self.CheckFunction then
	
		if self.UpdateMethod == "OnEvent" then
			self.UpdateNeeded = nil
			
			if self.AnticipateFunction then
				self:AnticipateFunction()
			end
		end
		
		if self.NextUpdateTime < time then
			self.NextUpdateTime = huge
		end
		
		local failed = not self:CheckFunction()
		if self.Failed ~= failed then
			self.Failed = failed
			TMW:Fire("TMW_CNDT_OBJ_PASSING_CHANGED", self, failed)
		end
	end
end

function ConditionObject:RequestAutoUpdates(parent, doRequest)
	if doRequest then
		if not next(self.AutoUpdateRequests) then
			self.doesAutoUpdate = true
			self:RegisterForUpdating()
		end
		
		self.AutoUpdateRequests[parent] = true
	else
		self.AutoUpdateRequests[parent] = nil
		
		if not next(self.AutoUpdateRequests) then
			self.doesAutoUpdate = false
			--self:UnregisterForUpdating()
		end
	end
end

function ConditionObject:RegisterForUpdating()
	CNDT.UpdateEngine:RegisterObject(self)
end

function ConditionObject:UnregisterForUpdating()
	CNDT.UpdateEngine:UnregisterObject(self)
end

function ConditionObject:SetNumEventArgs(num)
	self.numArgsForEventString = max(self.numArgsForEventString, num)
end

function ConditionObject:RequestEvent(event)
	-- Note that this function does not actually register the event with CNDT.UpdateEngine
	-- It simply tells the object that it needs to register the event with CNDT.UpdateEngine
	-- once processing is done and it has been determined that the entire condition set can be event driven
	-- (if it has no OnUpdate conditions in it)
	self.RequestedEvents[event] = true
end

function ConditionObject:GenerateNormalEventString(event, ...)
	self:RequestEvent(event)
	self:SetNumEventArgs(select("#", ...))
	
	local str = "event == '"
    str = str .. event
    str = str .. "'"
    
	for n, arg in TMW:Vararg(...) do
		
		local arg_type = type(arg)
		if 
			arg_type ~= "number" and 
			arg_type ~= "string" and 
			arg_type ~= "boolean" and 
			arg_type ~= "nil" 
		then
			TMW:Error("Unsupported event arg type: " .. arg_type)
		elseif arg ~= nil then
			str = str .. " and arg"
			str = str .. n
			str = str .. " == "
			
			if arg_type == "string" then
				str = str .. "'"
				str = str .. arg
				str = str .. "'"
			else -- number, boolean
				str = str .. tostring(arg)
			end
		end
	end
	
	return str
end

function ConditionObject:GetUnitChangedEventString(unit)
	if unit == "player" then
		-- Returning false (as a string, not a boolean) won't cause responses to any events,
		-- and it also won't make the ConditionObject default to being OnUpdate driven.
		
		return "false"
	elseif unit == "target" then
		return self:GenerateNormalEventString("PLAYER_TARGET_CHANGED")
	elseif unit == "pet" then
		return self:GenerateNormalEventString("UNIT_PET", "player")
	elseif unit == "focus" then
		return self:GenerateNormalEventString("PLAYER_FOCUS_CHANGED")
	elseif unit:find("^raid%d+$") then
		return self:GenerateNormalEventString(TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "RAID_ROSTER_UPDATE")
	elseif unit:find("^party%d+$") then
		return self:GenerateNormalEventString(TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "PARTY_MEMBERS_CHANGED")
	elseif unit:find("^boss%d+$") then
		return self:GenerateNormalEventString("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	elseif unit:find("^arena%d+$") then
		return self:GenerateNormalEventString("ARENA_OPPONENT_UPDATE")
	end
	
	return false
end


local ConditionObjectConstructor = TMW:NewClass("ConditionObjectConstructor"){
	status = "ready",
	
	GetStatus = function(self)
		return self.status
	end,
	LoadParentAndConditions = function(self, parent, Conditions)
		-- Loads the parent and the Condition settings that will be used to
		-- construct a ConditionObject.
		
		assert(self.status == "ready", "Cannot :LoadParentAndConditions() to a ConditionObjectConstructor whose status is not 'ready'!")
		
		self.parent = parent
		self.Conditions = Conditions
		self.ConditionsToConstructWith = Conditions
		
		self.status = "loaded"
	end,
	ResetModifiableConditionsBase = function(self)
		self.ModifiableConditionsBase.n = 0
		for k, v in pairs(self.ModifiableConditionsBase) do
			if type(k) == "number" then
				TMW:CopyTableInPlaceWithMeta(TMW.Condition_Defaults["**"], v)
			end
		end
	end,
	GetPostUserModifiableConditions = function(self)
		-- Returns a copy of the settings table that was defined through :LoadConditions()
		-- that can be modified without changing user settings. If this modified version of the conditions is created,
		-- it will be used to :Construct() the ConditionObject instead of the original conditions.
		
		if self.ModifiableConditions then
			return self.ModifiableConditions
		end
		if not self.ModifiableConditionsBase then
			self.ModifiableConditionsBase = TMW:CopyWithMetatable(self.Conditions)
		end
		
		self:ResetModifiableConditionsBase()
		
		self.ModifiableConditions = TMW:CopyTableInPlaceWithMeta(self.Conditions, self.ModifiableConditionsBase)
		self.ConditionsToConstructWith = self.ModifiableConditions
		
		return self.ModifiableConditions
	end,
	
	Modify_AppendNew = function(self)
		-- Adds a single condition to the end.
		-- Returns this condition so that it can be manually configured however necessary.
		
		local ModifiableConditions = self:GetPostUserModifiableConditions()
		local mod = ModifiableConditions -- Alias for brevity
		
		mod.n = mod.n + 1
		
		return mod[mod.n]
	end,
	Modify_WrapExistingAndAppendNew = function(self)
		-- Wraps all existing conditions in parenthesis (if needed) and adds a single condition to the end.
		-- Returns this condition so that it can be manually configured however necessary.
		
		local ModifiableConditions = self:GetPostUserModifiableConditions()
		local mod = ModifiableConditions -- Alias for brevity
		
		mod.n = mod.n + 1
		if mod.n > 2 then
			mod[1].PrtsBefore = mod[1].PrtsBefore + 1
			mod[mod.n-1].PrtsAfter = mod[mod.n-1].PrtsAfter + 1
		end
		
		return mod[mod.n]
	end,
		
	Construct = function(self)
		-- Constructs and returns a ConditionObject that will reflect any modifications
		-- that were done through the ConditionObjectConstructor.
		
		local ConditionObject = CNDT:GetConditionObject(self.parent, self.ConditionsToConstructWith)
		
		self:Terminate()
		
		return ConditionObject
	end,
	Terminate = function(self)
		-- Terminates the ConditionObjectConstructor and prepares it for reuse.
		-- This is automatically called after performing :Construct().
		
		self.parent = nil
		self.Conditions = nil
		self.ConditionsToConstructWith = nil
		self.ModifiableConditions = nil
		
		if self.ModifiableConditionsBase then
			self:ResetModifiableConditionsBase()
		end
		
		self.status = "ready"
	end,
}



-- Public:
function CNDT:GetConditionObjectConstructor()
	for _, instance in pairs(ConditionObjectConstructor.instances) do
		if instance:GetStatus() == "ready" then
			return instance
		end
	end
	
	return ConditionObjectConstructor:New()
end

function CNDT:GetConditionObject(parent, Conditions)
	local conditionString = CNDT:GetConditionCheckFunctionString(parent, Conditions)
	
	if conditionString and conditionString ~= "" then
		local instances = ConditionObject.instances
		for i = 1, #instances do
			local instance = instances[i]
			if instance.conditionString == conditionString then
				return instance
			end
		end
		return ConditionObject:New(Conditions, conditionString)
	end
end

function CNDT:CheckParentheses(settings)

	local numclose, numopen, runningcount = 0, 0, 0
	local unopened = 0

	for _, Condition in TMW:InNLengthTable(settings) do
		for i = 1, Condition.PrtsBefore do
			numopen = numopen + 1
			runningcount = runningcount + 1
			if runningcount < 0 then unopened = unopened + 1 end
		end
		for i = 1, Condition.PrtsAfter do
			numclose = numclose + 1
			runningcount = runningcount - 1
			if runningcount < 0 then unopened = unopened + 1 end
		end
	end

	if numopen ~= numclose then
		local typeNeeded, num
		if numopen > numclose then
			typeNeeded, num = ")", numopen-numclose
		else
			typeNeeded, num = "(", numclose-numopen
		end
		
		return false, L["PARENTHESIS_WARNING1"], num, L["PARENTHESIS_TYPE_" .. typeNeeded]
	elseif unopened > 0 then
		
		return false, L["PARENTHESIS_WARNING2"], unopened
	else
		
		return true
	end
end



-- Private:
CNDT.UpdateEngine = CreateFrame("Frame")

function CNDT.UpdateEngine:CreateUpdateTableManager()
	local manager = TMW.Classes.UpdateTableManager:New()
	
	manager:UpdateTable_Set()
	
	return manager.UpdateTable_UpdateTable, manager
end

TMW:NewClass("EventUpdateTableManager", "UpdateTableManager"){
	OnNewInstance_EventUpdateTableManager = function(self, event)
		self.event = event
		self:UpdateTable_Set()
	end,
	
	UpdateTable_OnUsed = function(self)
		CNDT.UpdateEngine:RegisterEvent(self.event)
	end,
	UpdateTable_OnUnused = function(self)
		CNDT.UpdateEngine:UnregisterEvent(self.event)
	end,

}
function CNDT.UpdateEngine:CreateEventUpdateTableManager(event)
	local manager = TMW.Classes.EventUpdateTableManager:New(event)
	
	return manager.UpdateTable_UpdateTable, manager
end

local OnUpdate_UpdateTable, OnUpdate_UpdateTableManager = CNDT.UpdateEngine:CreateUpdateTableManager()
local OnAnticipate_UpdateTable, OnAnticipate_UpdateTableManager = CNDT.UpdateEngine:CreateUpdateTableManager()

CNDT.UpdateEngine.EventUpdateTables = {}
CNDT.UpdateEngine.EventUpdateTableManagers = {}

function CNDT.UpdateEngine:RegisterObjForOnEvent(ConditionObject)
	for event in pairs(ConditionObject.RequestedEvents) do
		self:RegisterObjForEvent(ConditionObject, event)
	end
	
	if ConditionObject.AnticipateFunction and ConditionObject.doesAutoUpdate then
		OnAnticipate_UpdateTableManager:UpdateTable_Register(ConditionObject)
	end
end
function CNDT.UpdateEngine:RegisterObjForEvent(ConditionObject, event)
	
	if event:find("^TMW_") then
		TMW:RegisterCallback(event, ConditionObject.UpdateFunction, ConditionObject)
	else		
		local UpdateTableManager = CNDT.UpdateEngine.EventUpdateTableManagers[event]
		if not UpdateTableManager then
			local UpdateTable
			UpdateTable, UpdateTableManager = self:CreateEventUpdateTableManager(event)
			
			CNDT.UpdateEngine.EventUpdateTableManagers[event] = UpdateTableManager
			CNDT.UpdateEngine.EventUpdateTables[event] = UpdateTable
		end
		
		UpdateTableManager:UpdateTable_Register(ConditionObject)		
	end	
end

function CNDT.UpdateEngine:UnregisterObjForOnEvent(ConditionObject)
	for event in pairs(ConditionObject.RequestedEvents) do
		self:UnregisterObjForEvent(ConditionObject, event)
	end
	
	if ConditionObject.AnticipateFunction then
		OnAnticipate_UpdateTableManager:UpdateTable_Unregister(ConditionObject)
	end
end
function CNDT.UpdateEngine:UnregisterObjForEvent(ConditionObject, event)
	if event:find("^TMW_") then
		TMW:UnregisterCallback(event, ConditionObject.UpdateFunction, ConditionObject)
	else
		local UpdateTableManager = CNDT.UpdateEngine.EventUpdateTableManagers[event]
		if UpdateTableManager then
			UpdateTableManager:UpdateTable_Unregister(ConditionObject)
		end
	end
end

function CNDT.UpdateEngine:OnEvent(event, ...)
	local UpdateTable = self.EventUpdateTables[event]
	
	if UpdateTable then
		for i = 1, #UpdateTable do
			local ConditionObject = UpdateTable[i]
			ConditionObject:UpdateFunction(event, ...)
		end
	end
end
CNDT.UpdateEngine:SetScript("OnEvent", CNDT.UpdateEngine.OnEvent)



function CNDT.UpdateEngine:RegisterObjForOnUpdate(ConditionObject)
	OnUpdate_UpdateTableManager:UpdateTable_Register(ConditionObject)
end
function CNDT.UpdateEngine:UnregisterObjForOnUpdate(ConditionObject)
	OnUpdate_UpdateTableManager:UpdateTable_Unregister(ConditionObject)
end

function CNDT.UpdateEngine:OnUpdate(event, time, Locked)
	if Locked then
		for i = 1, #OnUpdate_UpdateTable do
			local ConditionObject = OnUpdate_UpdateTable[i]
			
			ConditionObject:Check()
		end
		
		for i = 1, #OnAnticipate_UpdateTable do
			local ConditionObject = OnAnticipate_UpdateTable[i]
			if ConditionObject.NextUpdateTime < time then
				ConditionObject:Check()
			end
		end
	end

end
TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", "OnUpdate", CNDT.UpdateEngine)

-- Top level methods for auto-updating, still private because they are called by ConditionObject
function CNDT.UpdateEngine:RegisterObject(ConditionObject)
	if ConditionObject.UpdateMethod == "OnUpdate" then
		self:RegisterObjForOnUpdate(ConditionObject)
		
	elseif ConditionObject.UpdateMethod == "OnEvent" then
		self:RegisterObjForOnEvent(ConditionObject)
	end
end
function CNDT.UpdateEngine:UnregisterObject(ConditionObject)
	if ConditionObject.UpdateMethod == "OnUpdate" then
		self:UnregisterObjForOnUpdate(ConditionObject)
		
	elseif ConditionObject.UpdateMethod == "OnEvent" then
		self:UnregisterObjForOnEvent(ConditionObject)
	end
end

-- End Private


TMW:NewClass("ConditionImplementor"){
	OnNewInstance_ConditionImplementor = function(self)
		if self.GetName then
			Env[self:GetName()] = self
		end
	end,
	Conditions_GetConstructor = function(self, Conditions)
		local ConditionObjectConstructor = TMW.CNDT:GetConditionObjectConstructor()
		
		ConditionObjectConstructor:LoadParentAndConditions(self, Conditions)
		
		return ConditionObjectConstructor
	end,
}






CNDT.ConditionSets = {}
local ConditionSets = CNDT.ConditionSets

function CNDT:RegisterConditionSet(identifier, conditionSetData)
	local data = conditionSetData
	
	TMW:ValidateType("2 (identifier)", "CNDT:RegisterConditionSet()", identifier, "string")
	TMW:ValidateType("3 (conditionSetData)", "CNDT:RegisterConditionSet()", data, "table")
	
	TMW:ValidateType("parentSettingType", "conditionSetData", data.parentSettingType, "string")
	TMW:ValidateType("parentDefaults", "conditionSetData", data.parentDefaults, "table")
	TMW:ValidateType("modifiedDefaults", "conditionSetData", data.modifiedDefaults, "table;nil")
	
	TMW:ValidateType("settingKey", "conditionSetData", data.settingKey, "number;string")
	TMW:ValidateType("GetSettings", "conditionSetData", data.GetSettings, "function")
	
	TMW:ValidateType("iterFunc", "conditionSetData", data.iterFunc, "function")
	TMW:ValidateType("iterArgs", "conditionSetData", data.iterArgs, "table;nil")
	
	TMW:ValidateType("useDynamicTab", "conditionSetData", data.useDynamicTab, "boolean;nil")
	TMW:ValidateType("GetTab", "conditionSetData", data.GetTab, "function;nil")
	TMW:ValidateType("ShouldShowTab", "conditionSetData", data.ShouldShowTab, "function;nil")
	TMW:ValidateType("tabText", "conditionSetData", data.tabText, "string")
	
	if ConditionSets[identifier] then
		error(("A condition set is already registered with the identifier %q"):format(identifier), 2)
	end
	
	if TMW.Initialized then
		error(("ConditionSet %q is being registered too late. It needs to be registered before the database is initialized."):format(self.name or "<??>"))
	end
	
	data.identifier = identifier
	
	local defaults = TMW.Condition_Defaults
	if data.modifiedDefaults then
		defaults = CopyTable(defaults)
		TMW:CopyTableInPlaceWithMeta(data.modifiedDefaults, defaults["**"], true)
		TMW:RegisterCallback("TMW_CNDT_DEFAULTS_NEWVAL", function(event, k, v)
			defaults["**"][k] = v
		end)
	end
	data.parentDefaults[data.settingKey] = defaults
	
	ConditionSets[identifier] = data
	
	TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function(event, icon)
		CNDT:SetTabText(identifier)
	end)
end
function CNDT:RegisterConditionImplementingClass(className)
	TMW:ValidateType("2 (className)", "CNDT:RegisterConditionImplementingClass()", className, "string")
	
	if not TMW.Classes[className] then
		error(("No class named %q exists to embed ConditionImplementor into."):format(className), 2)
	end
	
	TMW.Classes[className]:Inherit("ConditionImplementor")
end


CNDT:RegisterConditionImplementingClass("Icon")
CNDT:RegisterConditionSet("Icon", {
	parentSettingType = "icon",
	parentDefaults = TMW.Icon_Defaults,
	
	settingKey = "Conditions",
	GetSettings = function(self)
		if TMW.CI.ics then
			return TMW.CI.ics.Conditions
		end
	end,
	
	iterFunc = TMW.InIconSettings,
	iterArgs = {
		[1] = TMW,
	},
	
	GetTab = function(self)
		return TMW.IE.IconConditionTab
	end,
	tabText = L["CONDITIONS"],
})

CNDT:RegisterConditionImplementingClass("Group")
CNDT:RegisterConditionSet("Group", {
	parentSettingType = "group",
	parentDefaults = TMW.Group_Defaults,
	
	settingKey = "Conditions",
	GetSettings = function(self)
		if TMW.CI.g then
			return TMW.db.profile.Groups[TMW.CI.g].Conditions
		end
	end,
	
	iterFunc = TMW.InGroupSettings,
	iterArgs = {
		[1] = TMW,
	},
	
	GetTab = function(self)
		return TMW.IE.GroupConditionTab
	end,
	tabText = L["GROUPCONDITIONS"],
})

TMW:RegisterCallback("TMW_UPGRADE_REQUESTED", function(event, type, version, ...)
	local parentSettings = ...
	
	for identifier, conditionSetData in pairs(ConditionSets) do
		if conditionSetData.parentSettingType == type then
			
			for conditionID, condition in TMW:InNLengthTable(parentSettings[conditionSetData.settingKey]) do
				TMW:DoUpgrade("condition", version, condition, conditionID)
			end
			
		end
	end
	
end)


do -- InConditionSettings
	local states = {}
	local function getstate()
		local state = wipe(tremove(states) or {})

		state.currentConditionSetKey, state.currentConditionSet = next(ConditionSets)
		state.currentConditionID = 0
		
		state.extIter, state.extIterState = state.currentConditionSet.iterFunc(unpack(state.currentConditionSet.iterArgs))

		return state
	end

	local function iter(state)
		state.currentConditionID = state.currentConditionID + 1

		if not state.currentConditions or state.currentConditionID > (state.currentConditions.n or #state.currentConditions) then
			local settings
			settings, state.cg, state.ci = state.extIter(state.extIterState)
			
			if not settings then
				state.currentConditionSetKey, state.currentConditionSet = next(ConditionSets, state.currentConditionSetKey)
				if state.currentConditionSetKey then
					state.extIter, state.extIterState = state.currentConditionSet.iterFunc(unpack(state.currentConditionSet.iterArgs))
					
					return iter(state)
				else
					tinsert(states, state)
					return
				end
			end
			state.currentConditions = settings[state.currentConditionSet.settingKey]
			state.currentConditionID = 0
			
			return iter(state)
		end
		
		local condition = rawget(state.currentConditions, state.currentConditionID)
		
		if not condition then
			return iter(state)
		end
		
		return condition, state.currentConditionID, state.cg, state.ci -- condition data, conditionID, groupID, iconID
	end

	function TMW:InConditionSettings()
		return iter, getstate()
	end
end

