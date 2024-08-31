-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local type, wipe, pairs, rawget =
	  type, wipe, pairs, rawget
local UnitGUID, IsInInstance =
	  UnitGUID, IsInInstance
local bit_band = bit.band

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local huge = math.huge

local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache
local GetSpellTexture = TMW.GetSpellTexture
local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName

local classSpellNameCache



local Type = TMW.Classes.IconType:New("unitcooldown")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_UNITCOOLDOWN"]
Type.desc = L["ICONMENU_UNITCOOLDOWN_DESC"]
Type.menuIcon = GetSpellTexture(19263)
Type.usePocketWatch = 1
Type.DurationSyntax = 1
Type.unitType = "unitid"
Type.canControlGroup = true

local STATE_USABLE = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_USABLE_ALL = 10
local STATE_UNUSABLE = TMW.CONST.STATE.DEFAULT_HIDE

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("spell")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes



Type:RegisterIconDefaults{
	-- The unit(s) to check for cooldowns
	Unit					= "player", 

	-- False to allow all spells
	-- True to only show abilities if the unit has used the ability at least once.
	-- "class" to only show abilities if the unit's class has the ability.
	OnlySeen				= false,

	-- Sort the cooldowns found by duration
	Sort					= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "spellwithduration",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_USABLE_ALL] = { text = "|cFF00FF00" .. L["ICONMENU_ALLSPELLS"], tooltipText = L["ICONMENU_ALLSPELLS_DESC"], order = 1},
	[STATE_USABLE] =     { text = "|cFF00FF00" .. L["ICONMENU_ANYSPELLS"], tooltipText = L["ICONMENU_ANYSPELLS_DESC"], order = 2},
	[STATE_UNUSABLE] =   { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"],  tooltipText = L["ICONMENU_UNUSABLE_DESC"], order = 3},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_UnitCooldownSettings", function(self)
	self:SetTitle(L["ICONMENU_ONLYSEEN_HEADER"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 2,
		function(check)
			check:SetTexts(L["ICONMENU_ONLYSEEN_ALL"], L["ICONMENU_ONLYSEEN_ALL_DESC"])
			check:SetSetting("OnlySeen", false)
		end,
		function(check)
			check:SetTexts(L["ICONMENU_ONLYSEEN"], L["ICONMENU_ONLYSEEN_DESC"])
			check:SetSetting("OnlySeen", true)
		end,
		function(check)
			check:SetTexts(L["ICONMENU_ONLYSEEN_CLASS"], L["ICONMENU_ONLYSEEN_CLASS_DESC"])
			check:SetSetting("OnlySeen", "class")
		end,
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(170, "TellMeWhen_UCDSortSettings", function(self)
	self:SetTitle(TMW.L["SORTBY"])

	self:BuildSimpleCheckSettingFrame({
		numPerRow = 3,
		function(check)
			check:SetTexts(TMW.L["SORTBYNONE"], TMW.L["SORTBYNONE_DESC"])
			check:SetSetting("Sort", false)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTASC"], TMW.L["ICONMENU_SORTASC_DESC"])
			check:SetSetting("Sort", -1)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTDESC"], TMW.L["ICONMENU_SORTDESC_DESC"])
			check:SetSetting("Sort", 1)
		end,
	})

	self:CScriptAdd("PanelSetup", function()
		if TMW.CI.icon:IsGroupController() then
			self:Hide()
		end
	end)
end)



-- Holds all unitcooldown icons whose update method is "manual" (not "auto")
-- Since the event handling for this icon type is all done by a single handler that operates on all icons,
-- we need to know which icons we need to queue an update for when something changes.
local ManualIcons = {}
local ManualIconsManager = TMW.Classes.UpdateTableManager:New()
ManualIconsManager:UpdateTable_Set(ManualIcons)


-- Holds the cooldowns of all known units. Structure is:
--[[ Cooldowns = {
	[GUID] = {
		[spellName] = lastCastTime,
		...
	},
	...
}
]]
local Cooldowns = setmetatable({}, {__index = function(t, k)
	local n = {}
	t[k] = n
	return n
end})



local resetsOnCast = {
	
	[23989] = { -- readiness
		[19263] = 1, -- Deterrence
		[5384] = 1, -- Feign
		-- Freezing Trap
		[1499] = 1,
		[14310] = 1,
		[14311] = 1,
		-- Frost Trap
		[13809] = 1,
		-- Immolation Trap
		[13795] = 1,
		[14302] = 1,
		[14303] = 1,
		[14304] = 1,
		[14305] = 1,
	},

	[12472] = { -- coldsnap
		-- cone of cold
		[120] = 1,
		[8492] = 1,
		[10159] = 1,
		[10160] = 1,
		[10161] = 1,

		-- frost ward
		[6143] = 1,
		[8461] = 1,
		[8462] = 1,
		[10177] = 1,
		[28609] = 1,
		[11189] = 1,
		[28332] = 1,

		-- frost nova
		[122] = 1,
		[865] = 1,
		[6131] = 1,
		[10230] = 1,

		-- Ice Block (does this really reset?)
		[11958] = 1,

		-- Ice Barrier
		[11426] = 1,
		[13031] = 1,
		[13032] = 1,
		[13033] = 1,
	},
	
	[14185] = { --prep
		[2094] = 1, -- Blind
		[5277] = 1, -- Evasion
		[2983] = 1, -- Sprint
		[1856] = 1, -- Vanish
		[8643] = 1, -- Kidney Shot
		[11286] = 1, -- Gouge
		[14177] = 1, -- Cold Blood
		[14183] = 1, -- Premeditation
		[1766] = 1, -- Kick
		-- Probably missing some other ones
	},
}

-- Map to names, since classic doesn't provide spellIDs to CLEU
resetsOnCast = TMW.map(resetsOnCast, function(v, k)
	return TMW.map(v, function(v, k)
		return v, strlowerCache[GetSpellName(k)]
	end), strlowerCache[GetSpellName(k)]
end)

-- local resetsOnAura = {
	
-- }
-- local spellBlacklist = {
-- 	[50288] = 1, -- Starfall damage effect, causes the cooldown to be off by 10 seconds and prevents proper resets when tracking by name.
-- }


function Type:COMBAT_LOG_EVENT_UNFILTERED(e)
	local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()
	
	if cleuEvent == "SPELL_CAST_SUCCESS"
	or cleuEvent == "SPELL_AURA_APPLIED"
	or cleuEvent == "SPELL_AURA_REFRESH"
	or cleuEvent == "SPELL_DAMAGE"
	or cleuEvent == "SPELL_HEAL"
	or cleuEvent == "SPELL_MISSED"
	then
		
		spellName = spellName and strlowerCache[spellName]
		local cooldownsForGUID = Cooldowns[sourceGUID]

		if cleuEvent == "SPELL_CAST_SUCCESS" then
			if resetsOnCast[spellName] then
				for name in pairs(resetsOnCast[spellName]) do
					if cooldownsForGUID[name] then
						-- dont set it to 0 if it doesnt exist so we dont make spells that havent been seen suddenly act like they have been seen
						-- on the other hand, dont set things to nil or it will look like they haven't been seen.
						cooldownsForGUID[name] = 0
						
						-- Force update all icons. Too hard to check each icon to see if they were tracking the spellIDs that were reset,
						-- or if they were tracking the names of the spells that were reset.
						for k = 1, #ManualIcons do
							ManualIcons[k].NextUpdateTime = 0
						end
					end
				end
			end


			cooldownsForGUID[spellName] = TMW.time
		else
			local time = TMW.time
			local storedTimeForSpell = cooldownsForGUID[spellName]
			
			-- If this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS
			-- or a UNIT_SPELLCAST_SUCCEEDED then ignore it.
			-- (This is just a safety window for spell travel time so that
			-- if we found the real cast start, we dont overwrite it)
			-- (And really, how often are people actually going to be tracking cooldowns with cast times?
			-- There arent that many, and the ones that do exist arent that important)
			if not storedTimeForSpell or storedTimeForSpell + 1.8 < time then
				-- Hack it to make it a little bit more accurate.
				-- A max range dk deathcoil has a travel time of about 1.3 seconds,
				-- so 1 second should be a good average to be safe with travel times.
				cooldownsForGUID[spellName] = time-1
			end
		end
		
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.Spells.StringHash
			if NameHash and NameHash[spellName] then
				icon.NextUpdateTime = 0
			end
		end
	elseif cleuEvent == "UNIT_DIED" then
		if destFlags then
			if bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= COMBATLOG_OBJECT_TYPE_PLAYER then
				-- Don't reset the cooldowns of a player if they die. Only NPCs.
				Cooldowns[destGUID] = nil
			end
		end
	end
end

function Type:UNIT_SPELLCAST_SUCCEEDED(event, unit, _, spellID)
	local sourceGUID = UnitGUID(unit)
	if sourceGUID then
		-- For some reason, this is firing for unit "npc," (yes, there is a comma there).
		-- It also seems to fire for "npc" without a comma, so ignore that too it it doesnt have a GUID.
		-- Obviously this is invalid, but if you find anything else invalid then scream about it too.
		
		-- Addendum 6-17-12: Fired for arena1 and GUID was nil. Seems this is a more common issue than I though,
		-- so remove all errors and just ignore things without GUIDs.
		
		local c = Cooldowns[sourceGUID]
		local spellName = GetSpellName(spellID)
		spellName = strlowerCache[spellName]
		
		c[spellName] = TMW.time
		
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.Spells.StringHash
			if NameHash and (NameHash[spellName]) then
				icon.NextUpdateTime = 0
			end
		end
	end
end



-- Wipe cooldowns for arena enemies:
local isArena
local resetForArena = {}
function Type:PLAYER_ENTERING_WORLD()
	local _, zoneType = IsInInstance()
	local wasArena = isArena
	isArena = zoneType == "arena"
	if isArena and not wasArena then
		wipe(resetForArena)
		Type:RegisterEvent("GROUP_ROSTER_UPDATE")
		Type:RegisterEvent("ARENA_OPPONENT_UPDATE")
	elseif not isArena then
		Type:UnregisterEvent("GROUP_ROSTER_UPDATE")
		Type:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	end
end
Type:RegisterEvent("PLAYER_ENTERING_WORLD")
Type:RegisterEvent("ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD")

function Type:GROUP_ROSTER_UPDATE()
	for i = 1, 40 do
		local GUID = UnitGUID("raid" .. i)
		if not GUID then
			return
		elseif not resetForArena[GUID] then
			wipe(Cooldowns[GUID])
			resetForArena[GUID] = 1
		end
	end
end

function Type:ARENA_OPPONENT_UPDATE()
	for i = 1, 5 do
		local GUID = UnitGUID("arena" .. i)
		if not GUID then
			return
		elseif not resetForArena[GUID] then
			wipe(Cooldowns[GUID])
			resetForArena[GUID] = 1
		end
	end
end
-- End arena enemy cooldown reset code.



local function UnitCooldown_OnEvent(icon, event, arg1)
	if event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	end
end

local BLANKTABLE = {}

local function UnitCooldown_OnUpdate(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local NameArray, OnlySeen, Sort, Durations, Units =
	icon.Spells.StringArray, icon.OnlySeen, icon.Sort, icon.Spells.Durations, icon.Units
	
	local usableAlpha = icon.States[STATE_USABLE].Alpha
	local usableAllAlpha = icon.States[STATE_USABLE_ALL].Alpha

	-- These variables will hold all the attributes that we pass to SetInfo().
	local unstart, unname, unduration, usename, dobreak, useUnit, unUnit
	
	-- Initial values for the vars that track the duration/stack of the aura that currently occupies unname and related locals.
	-- If we are sorting by smallest duration, we intitialize to math.huge so that the first thing we find is definitely smaller.
	local curSortDur = Sort == -1 and huge or 0

	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local cooldowns = GUID and rawget(Cooldowns, GUID)

		if u == 1 and GUID and not cooldowns and OnlySeen ~= true then
			-- If this is the first unit, use a blank cooldowns table for it if it doesn't exist
			-- so that we can still find the first usable spell.
			-- Such a dirty, dirty hack.
			cooldowns = BLANKTABLE
		end

		if cooldowns then
			for i = 1, #NameArray do
				local spellName = NameArray[i]

				local start
				if OnlySeen == true then
					-- If we only want cooldowns that have been seen,
					-- don't default to 0 if it isn't in the table.
					start = cooldowns[spellName]
				elseif OnlySeen == "class" then
					local _, class = UnitClass(unit)

					-- we allow (not classSpellNameCache[class]) because of ticket 1144
					if not classSpellNameCache[class] or classSpellNameCache[class][spellName] then
						start = cooldowns[spellName] or 0
					end
				else
					start = cooldowns[spellName] or 0
				end

				if start then
					local duration = Durations[i]
					local remaining = duration - (time - start)
					if remaining < 0 then remaining = 0 end

					if Sort then
						if remaining ~= 0 then
							-- Found an unusable cooldown
							-- Sort is either 1 or -1, so multiply by it to get the correct ordering.
							-- (multiplying by a negative flips inequalities)
							if curSortDur*Sort < remaining*Sort then
								curSortDur = remaining
								unname = spellName
								unstart = start
								unduration = duration
								unUnit = unit
							end
						else
							-- We found the first usable cooldown
							if not usename then
								usename = spellName
								useUnit = unit
							end
						end
					else
						if remaining ~= 0 and not unname then
							-- We found the first UNusable cooldown
							unname = spellName
							unstart = start
							unduration = duration
							unUnit = unit

							-- We DONT care about usable cooldowns, so stop looking
							if usableAlpha == 0 and usableAllAlpha == 0 then
								dobreak = 1
								break
							end
						elseif remaining == 0 and not usename then
							-- We found the first usable cooldown
							usename = spellName
							useUnit = unit

							-- We care about usable cooldowns (but not all of them), so stop looking
							if usableAlpha > 0 and usableAllAlpha == 0 then
								dobreak = 1
								break
							end
						end
					end
				end
			end
			if dobreak then
				break
			end
		end
	end
	
	if usename and usableAllAlpha > 0 and not unname then
		icon:SetInfo("state; texture; start, duration; spell; unit, GUID",
			STATE_USABLE_ALL,
			GetSpellTexture(usename) or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			0, 0,
			usename,
			useUnit, nil
		)

	elseif usename and usableAlpha > 0 then
		icon:SetInfo("state; texture; start, duration; spell; unit, GUID",
			STATE_USABLE,
			GetSpellTexture(usename) or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			0, 0,
			usename,
			useUnit, nil
		)

	elseif unname then
		icon:SetInfo("state; texture; start, duration; spell; unit, GUID",
			STATE_UNUSABLE,
			GetSpellTexture(unname),
			unstart, unduration,
			unname,
			unUnit, nil
		)

	else
		icon:SetInfo("state", 0)
	end
end

local function UnitCooldown_OnUpdate_Controller(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local NameArray, OnlySeen, Durations, Units =
	icon.Spells.StringArray, icon.OnlySeen, icon.Spells.Durations, icon.Units
	
	local usableAlpha = icon.States[STATE_USABLE].Alpha
	local unusableAlpha = icon.States[STATE_UNUSABLE].Alpha

	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local cooldowns = GUID and rawget(Cooldowns, GUID)

		if u == 1 and GUID and not cooldowns and OnlySeen ~= true then
			-- If this is the first unit, use a blank cooldowns table for it if it doesn't exist
			-- so that we can still find the first usable spell.
			-- Such a dirty, dirty hack.
			cooldowns = BLANKTABLE
		end

		if cooldowns then
			for i = 1, #NameArray do
				local spellName = NameArray[i]

				local start
				if OnlySeen == true then
					-- If we only want cooldowns that have been seen,
					-- don't default to 0 if it isn't in the table.
					start = cooldowns[spellName]
				elseif OnlySeen == "class" then
					local _, class = UnitClass(unit)

					if classSpellNameCache[class][spellName] then
						start = cooldowns[spellName] or 0
					end
				else
					start = cooldowns[spellName] or 0
				end

				if start then
					local duration = Durations[i]
					local remaining = duration - (time - start)
					if remaining < 0 then remaining = 0 end

					if remaining ~= 0 then
						if unusableAlpha > 0 and not icon:YieldInfo(true, spellName, start, duration, unit, GUID, STATE_UNUSABLE) then
							-- YieldInfo returns true if we need to keep harvesting data. Otherwise, it returns false.
							return
						end

					else
						if usableAlpha > 0 and not icon:YieldInfo(true, spellName, 0, 0, unit, GUID, STATE_USABLE) then
							-- YieldInfo returns true if we need to keep harvesting data. Otherwise, it returns false.
							return
						end
					end
				end
			end
		end
	end

	-- Signal the group controller that we are at the end of our data harvesting.
	icon:YieldInfo(false)
end
function Type:HandleYieldedInfo(icon, iconToSet, name, start, duration, unit, GUID, state)
	if name then
		iconToSet:SetInfo("state; texture; start, duration; spell; unit, GUID",
			state,
			GetSpellTexture(name) or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			start, duration,
			name,
			unit, GUID
		)
	else
		iconToSet:SetInfo("state", 0)
	end

end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)

	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)
	

	icon:SetInfo("texture", Type:GetConfigIconTexture(icon))



	-- Setup event handling to catch unit spellcasts and such.
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	if icon.OnlySeen == "class" then
		classSpellNameCache = TMW:GetModule("ClassSpellCache"):GetNameCache()
	end

	-- Setup icon events and update functions.
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		ManualIconsManager:UpdateTable_Register(icon)
		
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", UnitCooldown_OnEvent, icon)
	end

	if icon:IsGroupController() then
		icon:SetUpdateFunction(UnitCooldown_OnUpdate_Controller)
	else
		icon:SetUpdateFunction(UnitCooldown_OnUpdate)
	end

	icon:Update()
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event, icon)
	Type:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end)

TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
	ManualIconsManager:UpdateTable_Unregister(icon)
end)

Type:Register(40)