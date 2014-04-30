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

local date = date

local CNDT = TMW.CNDT
local Env = CNDT.Env


local ConditionCategory = CNDT:GetCategory("BOSSMODS", 9.5, L["CNDTCAT_BOSSMODS"], true, false)



TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	local SUG = TMW.SUG

	local Encounters = {}

	local function scan()
		for t = 1, EJ_GetNumTiers() do
			EJ_SelectTier(t)
			local tierName = EJ_GetTierInfo(t)
			for raid = 0, 1 do
				local index = 1
				
				repeat
					local instanceID, instanceName = EJ_GetInstanceByIndex(index, raid == 1)
					if not instanceID then break end
					
					EJ_SelectInstance(instanceID)
					
					local eindex = 1
					
					repeat
						local name, description, encounterID = EJ_GetEncounterInfoByIndex(eindex)
						if not name then break end

						local _, _, _, _, bossImage = EJ_GetCreatureInfo(1, encounterID)
						
						tinsert(Encounters, {tier = tierName, instance = instanceName, name = name, index = eindex, tex = bossImage})

						eindex = eindex + 1
					until not name
					
					index = index + 1
				until not instanceID
			end
		end
	end

	local function doScan()
		if EncounterJournal then
			
			local oldTier = EJ_GetCurrentTier()
			local oldInstance = EncounterJournal.instanceID
			local oldEncounter = EncounterJournal.encounterID
			local oldDifficulty = EJ_GetDifficulty()
			
			EncounterJournal:SetScript("OnEvent", nil)
			
			scan()
			
			EJ_SelectTier(oldTier)
			if oldInstance then
				EJ_SelectInstance(oldInstance)
			end
			if oldEncounter then
				EJ_SelectEncounter(oldEncounter)
			end
			if oldDifficulty then
				EJ_SetDifficulty(oldDifficulty)
			end
			
			EncounterJournal:SetScript("OnEvent", EncounterJournal_OnEvent)
		else
			scan()
		end

		doScan = nil
		scan = nil
	end


	local Module = SUG:NewModule("bossfights", SUG:GetModule("default"))
	Module.noMin = true
	Module.showColorHelp = false
	Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
	
	function Module:Table_Get()
		if doScan then
			doScan()
		end

		return Encounters
	end

	function Module.Sorter(a, b)
		return a.name < b.name
	end
	function Module:Table_GetSorter()
		return self.Sorter
	end
	function Module:Entry_AddToList_1(f, encounter)
		f.Name:SetText(encounter.name)

		f.tooltiptitle = encounter.name
		f.tooltiptext = ENCOUNTER_JOURNAL_ENCOUNTER .. " #" .. encounter.index .. "\r\n" .. 
			encounter.instance .. "\r\n" .. 
			encounter.tier .. "\r\n\r\n" ..
			"|T" .. encounter.tex .. ":64:128:0:0|t"


		f.Icon:SetTexture(encounter.tex)
		f.Icon:SetTexCoord(32/128, (128-32)/128, 0, 1)

		f.insert = encounter.name
	end
	function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
		local lastName = SUG.lastName

		for index, encounter in pairs(tbl) do
			if strfind(encounter.name:lower(), lastName) or strfind(encounter.instance:lower(), lastName) then
				suggestions[#suggestions + 1] = encounter
			end
		end

	end
end)









local function BigWigs_timer_init()
	BigWigs_timer_init = nil

	if not BigWigsLoader then
		TMW.Warn("BigWigsLoader wasn't loaded when BigWigs timer conditions tried to initialize.")
		function Env.BigWigs_GetTimeRemaining()
			return 0, 0
		end

		return
	end

	local Timers = {}

	local function stop(module, text)
		for k = #Timers, 1, -1 do
			local t = Timers[k]
			if t.module == module and (not text or t.text == text) then
				tremove(Timers, k)
				TMW:Fire("TMW_CNDT_BOSSMODS_BIGWIGS_TIMER_CHANGED")
			elseif t.start + t.duration < TMW.time then
				tremove(Timers, k)
				TMW:Fire("TMW_CNDT_BOSSMODS_BIGWIGS_TIMER_CHANGED")
			end
		end

	end

	BigWigsLoader:RegisterMessage("BigWigs_StartBar", function(_, module, key, text, time)
			stop(module, text)
			
			tinsert(Timers, {module = module, key = key, text = text:lower(), start = TMW.time, duration = time})
			
			TMW:Fire("TMW_CNDT_BOSSMODS_BIGWIGS_TIMER_CHANGED")
	end)

	BigWigsLoader:RegisterMessage("BigWigs_StopBar", function(_, module, text)
			stop(module, text)  
	end)

	BigWigsLoader:RegisterMessage("BigWigs_StopBars", function(_, module)
			stop(module)  
	end)
	BigWigsLoader:RegisterMessage("BigWigs_OnBossDisable", function(_, module)
			stop(module)  
	end)
	BigWigsLoader:RegisterMessage("BigWigs_OnPluginDisable", function(_, module)
			stop(module)  
	end)


	function Env.BigWigs_GetTimeRemaining(text)
		for k = 1, #Timers do
			local t = Timers[k]
			
			if t.text:match(text) then
				local expirationTime = t.start + t.duration
				local remaining = (expirationTime) - TMW.time
				if remaining < 0 then remaining = 0 end
				
				return remaining, expirationTime
			end
		end
		
		return 0, 0
	end
end

ConditionCategory:RegisterCondition(1,	 "BIGWIGS_TIMER", {
	text = L["CONDITIONPANEL_BIGWIGS_TIMER"],
	tooltip = L["CONDITIONPANEL_BIGWIGS_TIMER_DESC"],

	range = 30,
	step = 0.1,
	unit = false,
	name = function(editbox) TMW:TT(editbox, "MODTIMERTOCHECK", "MODTIMERTOCHECK_DESC") editbox.label = L["MODTIMERTOCHECK"] end,
	texttable = CNDT.COMMON.absentseconds,
	icon = function()
		if not BigWigsLoader then
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end
		return "Interface\\AddOns\\BigWigs\\Textures\\icons\\core-disabled"
	end,

	tcoords = CNDT.COMMON.standardtcoords,
	disabled = function()
		return not BigWigsLoader
	end,
	funcstr = function(c)
		if BigWigs_timer_init then BigWigs_timer_init() end

		local name = format("%q", c.Name:gsub("%%", "%%%%"):lower())
		return [[BigWigs_GetTimeRemaining(]] .. name .. [[) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_CNDT_BOSSMODS_BIGWIGS_TIMER_CHANGED")
	end,
	anticipate = function(c)
		local name = format("%q", c.Name:gsub("%%", "%%%%"):lower())
		return [[local dur, expirationTime = BigWigs_GetTimeRemaining(]] .. name .. [[)

		local VALUE
		if dur and dur > 0 then
			if not expirationTime then
				VALUE = 0
			else
				VALUE = expirationTime - c.Level
				if VALUE <= time then
					VALUE = expirationTime
				end
			end
		else
			VALUE = 0
		end]]
	end,
})



local function BigWigs_engaged_init()
	BigWigs_engaged_init = nil

	if not BigWigsLoader then
		TMW.Warn("BigWigsLoader wasn't loaded when BigWigs engaged conditions tried to initialize.")

		function Env.BigWigs_IsBossEngaged()
			return nil
		end

		return
	end

	local EngagedBosses = {}


	BigWigsLoader:RegisterMessage("BigWigs_OnBossEngage", function(_, module, diff)
			EngagedBosses[module] = true

			TMW:Fire("TMW_CNDT_BOSSMODS_BIGWIGS_ENGAGED_CHANGED")
	end)
	BigWigsLoader:RegisterMessage("BigWigs_OnBossDisable", function(_, module)
			EngagedBosses[module] = nil

			TMW:Fire("TMW_CNDT_BOSSMODS_BIGWIGS_ENGAGED_CHANGED")
	end)

	function Env.BigWigs_IsBossEngaged(bossName)
		for module in pairs(EngagedBosses) do

			if module.displayName:lower():match(bossName) or module.moduleName:lower():match(bossName) then
				return module.isEngaged and 1 or nil
			end
		end
		
		return nil
	end
end

ConditionCategory:RegisterCondition(2,	 "BIGWIGS_ENGAGED", {
	text = L["CONDITIONPANEL_BIGWIGS_ENGAGED"],
	tooltip = L["CONDITIONPANEL_BIGWIGS_ENGAGED_DESC"],

	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = false,

	name = function(editbox) TMW:TT(editbox, "ENCOUNTERTOCHECK", "ENCOUNTERTOCHECK_DESC_BIGWIGS") editbox.label = L["ENCOUNTERTOCHECK"] end,
	useSUG = "bossfights",
	icon = function()
		if not BigWigsLoader then
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end
		return "Interface\\AddOns\\BigWigs\\Textures\\icons\\core-enabled"
	end,

	tcoords = CNDT.COMMON.standardtcoords,
	disabled = function()
		return not BigWigsLoader
	end,
	funcstr = function(c)
		if BigWigs_engaged_init then BigWigs_engaged_init() end

		local name = format("%q", c.Name:gsub("%%", "%%%%"):lower())
		return [[BigWigs_IsBossEngaged(]] .. name .. [[) == c.1nil]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_CNDT_BOSSMODS_BIGWIGS_ENGAGED_CHANGED")
	end,
})





ConditionCategory:RegisterSpacer(9)








local function DBM_timer_init()
	DBM_timer_init = nil
	if not DBM then
		TMW.Warn("DBM wasn't loaded when DBM timer conditions tried to initialize.")
		
		function Env.DBM_GetTimeRemaining()
			return 0, 0
		end

		return
	end

	local Timers = {}


	DBM:RegisterCallback("DBM_TimerStart", function(_, id, text, timeShitty)
		local duration = tonumber(timeShitty:match("%d+"))

		Timers[id] = {text = text:lower(), start = TMW.time, duration = duration}

		TMW:Fire("TMW_CNDT_BOSSMODS_DBM_TIMER_CHANGED")
	end)
	DBM:RegisterCallback("DBM_TimerStop", function(_, id)
		Timers[id] = nil

		TMW:Fire("TMW_CNDT_BOSSMODS_DBM_TIMER_CHANGED")
	end)


	function Env.DBM_GetTimeRemaining(text)
		for id, t in pairs(Timers) do
			if t.text:match(text) then
				local expirationTime = t.start + t.duration
				local remaining = (expirationTime) - TMW.time
				if remaining < 0 then remaining = 0 end
				
				return remaining, expirationTime
			end
		end
		
		return 0, 0
	end
end

ConditionCategory:RegisterCondition(10,	 "DBM_TIMER", {
	text = L["CONDITIONPANEL_DBM_TIMER"],
	tooltip = L["CONDITIONPANEL_DBM_TIMER_DESC"],

	range = 30,
	step = 0.1,
	unit = false,
	name = function(editbox) TMW:TT(editbox, "MODTIMERTOCHECK", "MODTIMERTOCHECK_DESC") editbox.label = L["MODTIMERTOCHECK"] end,
	texttable = CNDT.COMMON.absentseconds,
	icon = function()
		if not DBM then
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end
		return "Interface\\AddOns\\DBM-Core\\textures\\GuardTower"
	end,

	tcoords = CNDT.COMMON.standardtcoords,
	disabled = function()
		return not DBM
	end,
	funcstr = function(c)
		if DBM_timer_init then DBM_timer_init() end

		local name = format("%q", c.Name:gsub("%%", "%%%%"):lower())
		return [[DBM_GetTimeRemaining(]] .. name .. [[) c.Operator c.Level]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_CNDT_BOSSMODS_DBM_TIMER_CHANGED")
	end,
	anticipate = function(c)
		local name = format("%q", c.Name:gsub("%%", "%%%%"):lower())
		return [[local dur, expirationTime = DBM_GetTimeRemaining(]] .. name .. [[)

		local VALUE
		if dur and dur > 0 then
			if not expirationTime then
				VALUE = 0
			else
				VALUE = expirationTime - c.Level
				if VALUE <= time then
					VALUE = expirationTime
				end
			end
		else
			VALUE = 0
		end]]
	end,
})



local function DBM_engaged_init()
	DBM_engaged_init = nil
	if not DBM then
		TMW.Warn("DBM wasn't loaded when DBM engaged conditions tried to initialize.")
		
		function Env.DBM_IsBossEngaged()
			return nil
		end

		return
	end

	local EngagedBosses = {}

	hooksecurefunc(DBM, "StartCombat", function(DBM, mod, delay, event)
		if event ~= "TIMER_RECOVERY" then
			EngagedBosses[mod] = true
			TMW:Fire("TMW_CNDT_BOSSMODS_DBM_ENGAGED_CHANGED")
		end
	end)
	hooksecurefunc(DBM, "EndCombat", function(DBM, mod)
			EngagedBosses[mod] = nil
			TMW:Fire("TMW_CNDT_BOSSMODS_DBM_ENGAGED_CHANGED")
	end)


	function Env.DBM_IsBossEngaged(bossName)
		for mod in pairs(EngagedBosses) do

			if mod.localization.general.name:lower():match(bossName) or mod.id:lower():match(bossName) then
				return mod.inCombat and 1 or nil
			end
		end
		
		return nil
	end
end

ConditionCategory:RegisterCondition(11,	 "DBM_ENGAGED", {
	text = L["CONDITIONPANEL_DBM_ENGAGED"],
	tooltip = L["CONDITIONPANEL_DBM_ENGAGED_DESC"],

	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = false,

	name = function(editbox) TMW:TT(editbox, "ENCOUNTERTOCHECK", "ENCOUNTERTOCHECK_DESC_DBM") editbox.label = L["ENCOUNTERTOCHECK"] end,
	useSUG = "bossfights",
	icon = function()
		if not DBM then
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end
		return "Interface\\AddOns\\DBM-Core\\textures\\OrcTower"
	end,

	tcoords = CNDT.COMMON.standardtcoords,
	disabled = function()
		return not DBM
	end,
	funcstr = function(c)
		if DBM_engaged_init then DBM_engaged_init() end

		local name = format("%q", c.Name:gsub("%%", "%%%%"):lower())
		return [[DBM_IsBossEngaged(]] .. name .. [[) == c.1nil]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("TMW_CNDT_BOSSMODS_DBM_ENGAGED_CHANGED")
	end,
})
