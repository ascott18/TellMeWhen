-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local strlower, type, wipe, pairs =
	  strlower, type, wipe, pairs
local UnitGUID, IsInInstance =
	  UnitGUID, IsInInstance
local print = TMW.print
local huge = math.huge
local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures

local clientVersion = select(4, GetBuildInfo())


local Type = TMW.Classes.IconType:New("unitcooldown")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_UNITCOOLDOWN"]
Type.desc = L["ICONMENU_UNITCOOLDOWN_DESC"]
Type.usePocketWatch = 1
Type.DurationSyntax = 1
Type.unitType = "unitid"

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	Unit					= "player", 
	OnlySeen				= false,
	Sort					= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "spellwithduration",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 		},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_UnitCooldownSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "OnlySeen",
			title = L["ICONMENU_ONLYSEEN"],
			tooltip = L["ICONMENU_ONLYSEEN_DESC"],
		},
	})
end)

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettings")

local ManualIcons = {}


local Cooldowns = setmetatable({}, {__index = function(t, k)
	local n = {}
	t[k] = n
	return n
end}) TMW.Cooldowns = Cooldowns

local resetsOnCast = {
	[23989] = TMW.ISMOP and { -- Readiness
		[120697] = 1, -- Lynx Rush
		[19574] = 1, -- Bestial Wrath
		[6991] = 1, -- Feed Pet
		[53271] = 1, -- Master's Call
		[82726] = 1, -- Fervor
		[3674] = 1, -- Black Arrow
		[13809] = 1, -- Ice Trap
		[13813] = 1, -- Explosive Trap
		[53351] = 1, -- Kill Shot
		[19503] = 1, -- Scatter Shot
		[19386] = 1, -- Wyvern Sting
		[19263] = 1, -- Deterrence
		[130392] = 1, -- Blink Strike
		[3045] = 1, -- Rapid Fire
		[1499] = 1, -- Freezing Trap
		[131894] = 1, -- A Murder of Crows
		[53301] = 1, -- Explosive Shot
		[109304] = 1, -- Exhilaration
		[34490] = 1, -- Silencing Shot
		[109248] = 1, -- Binding Shot
		[5116] = 1, -- Concussive Shot
		[34600] = 1, -- Snake Trap
		[34477] = 1, -- Misdirection
		[51753] = 1, -- Camouflage
		[20736] = 1, -- Distracting Shot
		[120679] = 1, -- Dire Beast
		[34026] = 1, -- Kill Command
		-- [121818] = 1, -- Stampeded (5 min cd, doesn't get reset)
		[5384] = 1, -- Feign Death
		[19577] = 1, -- Intimidation
		[1543] = 1, -- Flare
		[781] = 1, -- Disengage
		[53209] = 1, -- Chimera Shot
		[109259] = 1, -- Powershot
		[117050] = 1, -- Glaive Toss
		[120360] = 1, -- Barrrage
	} or {
		[19386] = 1,
		[3674] = 1,
		[19503] = 1,
		[53209] = 1,
		[34490] = 1,
		[19577] = 1,
		[53271] = 1,
		[19263] = 1,
		[781] = 1,
		[5116] = 1,
		[53351] = 1,
		[3045] = 1,
		[3034] = 1,
		[34026] = 1,
		[60192] = 1,
		[34600] = 1,
		[1499] = 1,
		[13809] = 1,
		[13795] = 1,
		[1543] = 1,
		[19434] = 1,
		[20736] = 1,
		[19306] = 1,
		[3044] = 1,
		[34477] = 1,
		[2973] = 1,
		[53301] = 1,
		[2643] = 1,
	},
	
	[108285] = { -- Call of the Elements
		[108269] = 1, -- Capacitor Totem
		[8177] = 1, -- Grounding Totem
		[51485] = 1, -- Earthgrab Totem
		[8143] = 1, -- Tremor Totem
		[5394] = 1, -- Healing Stream Totem
	},
	[11129] = { -- Combustion
		[108853] = 1, -- Inferno Blast
	},
	[11958] = { -- coldsnap
		[44572] = 1,
		[31687] = TMW.ISNOTMOP,
		[11426] = TMW.ISNOTMOP,
		[12472] = TMW.ISNOTMOP,
		[45438] = TMW.ISNOTMOP,
		[120] = 1,
		[122] = 1,
	},
	[14185] = { --prep
		[5277] = 1, -- Evasion
		[2983] = 1, -- Sprint
		[1856] = 1, -- Vanish
		[51722] = 1, -- Dismantle
		[36554] = TMW.ISNOTMOP, -- Shadowstep
		[1766] = TMW.ISNOTMOP, -- Kick
		[76577] = TMW.ISNOTMOP, -- Smoke Bomb
		[31224] = TMW.ISMOP, -- Cloak of Shadows
	},
	[60970] = TMW.ISNOTMOP and { --some warrior thing that resets intercept
		[20252] = 1,
	},
	[50334] = { --druid berserk or something
		[33878] = 1,
		[33917] = 1,
	},
}
local resetsOnAura = {
	[81162] = { -- Will of the Necropolis
		[48982] = 1, -- Rune Tap
	},
	[93622] = { -- Mangle! (from lacerate and thrash)
		[33878] = 1, -- Mangle
	},
	[48517] = TMW.ISNOTMOP and { -- solar eclipse
		[16886] = 1, -- Nature's Grace
	},
	[48518] = TMW.ISMOP and { -- lunar eclipse
		[48505] = 1, -- Starfall
	} or {
		[16886] = 1, -- Nature's Grace
	},
	[64343] = TMW.ISNOTMOP and { -- impact
		[2136] = 1, -- Fire Blast
	},
	[50227] = { -- Sword and Board
		[23922] = 1, -- Shield Slam
	},
	[59578] = { -- The Art of War
		[879] = 1, -- Exorcism
	},
	[52437] = { -- Sudden Death
		[86346] = 1, -- Colossus Smash
	},
	[124430] = { -- Divine Insight (Shadow version)
		[8092] = 1, -- Mind Blast
	},
	[77762] = { -- Lava Surge
		[51505] = 1, -- Lava Burst
	},
	[93400] = { -- Shooting Stars
		[78674] = 1, -- Starsurge
	},
	[32216] = { -- Victorious
		[103840] = 1, -- Impending Victory
	},
}
local spellBlacklist = {
	[50288] = TMW.ISMOP, -- Starfall damage effect, causes the cooldown to be off by 10 seconds and prevents proper resets when tracking by name.
}


function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName)
	if cleuEvent == "SPELL_CAST_SUCCESS"
	or cleuEvent == "SPELL_AURA_APPLIED"
	or cleuEvent == "SPELL_AURA_REFRESH"
	or cleuEvent == "SPELL_DAMAGE"
	or cleuEvent == "SPELL_HEAL"
	or cleuEvent == "SPELL_MISSED"
	then
	
		if spellBlacklist[spellID] then
			return
		end
		
		spellName = spellName and strlowerCache[spellName]
		local cooldownsForGUID = Cooldowns[sourceGUID]
		
		if cleuEvent == "SPELL_AURA_APPLIED" and resetsOnAura[spellID] then
			for id in pairs(resetsOnAura[spellID]) do
				if cooldownsForGUID[id] then
					-- dont set it to 0 if it doesnt exist so we dont make spells that havent been seen suddenly act like they have been seen
					-- on the other hand, dont set things to nil or it will look like they haven't been seen.
					cooldownsForGUID[id] = 0
					
					-- Force update all icons. Too hard to check each icon to see if they were tracking the spellIDs that were reset,
					-- or if they were tracking the names of the spells that were reset.
					for k = 1, #ManualIcons do
						ManualIcons[k].NextUpdateTime = 0
					end
				end
			end
		end
		
		-- DONT ELSEIF HERE
		if cleuEvent == "SPELL_CAST_SUCCESS" then
			if resetsOnCast[spellID] then
				for id in pairs(resetsOnCast[spellID]) do
					if cooldownsForGUID[id] then
						-- dont set it to 0 if it doesnt exist so we dont make spells that havent been seen suddenly act like they have been seen
						-- on the other hand, dont set things to nil or it will look like they haven't been seen.
						cooldownsForGUID[id] = 0
						
						-- Force update all icons. Too hard to check each icon to see if they were tracking the spellIDs that were reset,
						-- or if they were tracking the names of the spells that were reset.
						for k = 1, #ManualIcons do
							ManualIcons[k].NextUpdateTime = 0
						end
					end
				end
			end
			cooldownsForGUID[spellName] = spellID
			cooldownsForGUID[spellID] = TMW.time
		else
			local time = TMW.time
			local storedTimeForSpell = cooldownsForGUID[spellID]
			
			-- If this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS
			-- or a UNIT_SPELLCAST_SUCCEEDED then ignore it.
			-- (This is just a safety window for spell travel time so that
			-- if we found the real cast start, we dont overwrite it)
			-- (And really, how often are people actually going to be tracking cooldowns with cast times?
			-- There arent that many, and the ones that do exist arent that important)
			if not storedTimeForSpell or storedTimeForSpell + 1.8 < time then
				cooldownsForGUID[spellName] = spellID
				
				-- Hack it to make it a little bit more accurate.
				-- A max range dk deathcoil has a travel time of about 1.3 seconds,
				-- so 1 second should be a good average to be safe with travel times.
				cooldownsForGUID[spellID] = time-1			
			end
		end
		
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.NameHash
			if NameHash and NameHash[spellID] or NameHash[spellName] then
				icon.NextUpdateTime = 0
			end
		end
	end
end

function Type:UNIT_SPELLCAST_SUCCEEDED(event, unit, spellName, _, _, spellID)
	local sourceGUID = UnitGUID(unit)
	if sourceGUID then
		-- For some reason, this is firing for unit "npc," (yes, there is a comma there).
		-- It also seems to fire for "npc" without a comma, so ignore that too it it doesnt have a GUID.
		-- Obviously this is invalid, but if you find anything else invalid then scream about it too.
		-- Addendum 6-17-12: Fired for arena1 and GUID was nil. Seems this is a more common issue than I though,
		-- so remove all errors and just ignore things without GUIDs.
		
		local c = Cooldowns[sourceGUID]
		spellName = strlowerCache[spellName]
		
		c[spellName] = spellID
		c[spellID] = TMW.time
		
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.NameHash
			if NameHash and NameHash[spellID] or NameHash[spellName] then
				icon.NextUpdateTime = 0
			end
		end
	end
end

-- wiping cooldowns for arenas
local isArena
local resetForArena = {}
function Type:PLAYER_ENTERING_WORLD()
	local _, zoneType = IsInInstance()
	local wasArena = isArena
	isArena = zoneType == "arena"
	if isArena and not wasArena then
		wipe(resetForArena)
		Type:RegisterEvent(TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "RAID_ROSTER_UPDATE", "RAID_ROSTER_UPDATE")
		Type:RegisterEvent("ARENA_OPPONENT_UPDATE")
	elseif not isArena then
		Type:UnregisterEvent(TMW.ISMOP and "GROUP_ROSTER_UPDATE" or "RAID_ROSTER_UPDATE", "RAID_ROSTER_UPDATE")
		Type:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	end
end
Type:RegisterEvent("PLAYER_ENTERING_WORLD")
Type:RegisterEvent("ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD")

function Type:RAID_ROSTER_UPDATE()
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

local function UnitCooldown_OnEvent(icon, event, arg1)
	if event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		icon.NextUpdateTime = 0
	end
end

local function UnitCooldown_OnUpdate(icon, time)
	local unstart, unname, unduration, usename, dobreak, useUnit, unUnit
	local Alpha, NameArray, OnlySeen, Sort, Durations, Units = icon.Alpha, icon.NameArray, icon.OnlySeen, icon.Sort, icon.Durations, icon.Units
	local NAL = #NameArray
	local d = Sort == -1 and huge or 0
	
	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local cooldowns = GUID and Cooldowns[GUID]

		if cooldowns then
			for i = 1, NAL do
				local iName = NameArray[i]
				if not isNumber[iName] then
					iName = cooldowns[iName] or iName-- spell name keys have values that are the spellid of the name, we need the spellid for the texture (thats why i did it like this)
				end
				local _start
				if OnlySeen then
					_start = cooldowns[iName]
				else
					_start = cooldowns[iName] or 0
				end

				if _start then
					local _duration = Durations[i]
					local tms = time - _start -- Time Minus Start - time since the unit's last cast of the spell (not neccesarily the time it has been on cooldown)
					local _d = (tms > _duration) and 0 or _duration - tms -- real duration remaining on the cooldown

					if Sort then
						if _d ~= 0 then -- found an unusable cooldown
							if (Sort == 1 and d < _d) or (Sort == -1 and d > _d) then -- the duration is lower or higher than the last duration that was going to be used
								d = _d
								unname = iName
								unstart = _start
								unduration = _duration
								unUnit = unit
							end
						else -- we found the first usable cooldown
							if not usename then
								usename = iName
								useUnit = unit
							end
						end
					else
						if _d ~= 0 and not unname then -- we found the first UNusable cooldown
							unname = iName
							unstart = _start
							unduration = _duration
							unUnit = unit
							if Alpha == 0 then -- we DONT care about usable cooldowns, so stop looking
								dobreak = 1
								break
							end
						elseif _d == 0 and not usename then -- we found the first usable cooldown
							usename = iName
							useUnit = unit
							if Alpha ~= 0 then -- we care about usable cooldowns, so stop looking
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

	if usename and Alpha > 0 then
		icon:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			icon.Alpha,
			SpellTextures[usename] or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			0, 0,
			usename,
			useUnit, nil
		)
	elseif unname then
		icon:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			icon.UnAlpha,
			SpellTextures[unname],
			unstart, unduration,
			unname,
			unUnit, nil
		)
	else
		icon:SetInfo("alpha", 0)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)

	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)
	
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
		
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", UnitCooldown_OnEvent, icon)
	end
	
	-- THIS DOESNT REALLY BELONG HERE, BUT IT NEEDS TO BE HERE SO IT ALWAYS GETS UPDATED PROPERLY.
	wipe(ManualIcons)
	for i = 1, #Type.Icons do
		local ic = Type.Icons[i]
		if ic.Update_Method == "manual" then
			ManualIcons[#ManualIcons + 1] = ic
		end
	end

	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))

	icon:SetUpdateFunction(UnitCooldown_OnUpdate)
	icon:Update()
end


Type:Register(40)