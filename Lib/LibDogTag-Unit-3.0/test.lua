--[[
TODO:

AddonVersion? - probably not gonna do this
]]

if not DogTag_Unit_SecondTime then
	local old_dofile = dofile

	function dofile(file)
		return old_dofile("../LibDogTag-3.0/" .. file)
	end
	old_dofile('../LibDogTag-3.0/test.lua')
	dofile = old_dofile
end

local DogTag = LibStub("LibDogTag-3.0")

local units = {
	player = {
		name = "Me",
		class = "Hunter",
		creatureType = "Humanoid",
		hp = 1500,
		maxhp = 2000,
		mp = 100,
		maxmp = 100,
		exists = true,
		friend = true,
		level = 10,
		race = "Tauren",
		sex = 3,
		guild = "Southsea Buccaneers",
		guildRank = "Guild Leader",
		pvpRank = "Knight",
		reaction = 5,
		powerType = 0,
	},
	pet = {
		name = "Mypet",
		class = "Warrior",
		creatureFamily = "Cat",
		creatureType = "Beast",
		hp = 0,
		maxhp = 1000,
		exists = true,
		friend = true,
		level = 9,
		powerType = 2,
	},
	target = {
		name = "Mytarget",
		realm = "Other Realm",
		class = "Warrior",
		creatureType = "Humanoid",
		hp = 2500,
		maxhp = 2500,
		exists = true,
		friend = false,
		level = 15,
		classification = 'worldboss',
		reaction = 3,
		isPlayer = true,
		powerType = 1,
	},
	pettarget = {
		name = "Mypettarget",
		class = "Paladin",
		creatureType = "Humanoid",
		hp = 50,
		maxhp = 100,
		exists = true,
		friend = false,
	},
	focus = {
		exists = false,
	},
	mouseover = {
		exists = false,
	}
}

local IsLegitimateUnit = { player = true, target = true, focus = true, pet = true, playerpet = true, mouseover = true, npc = true, NPC = true }
for i = 1, 4 do
	IsLegitimateUnit["party" .. i] = true
	IsLegitimateUnit["partypet" .. i] = true
	IsLegitimateUnit["party" .. i .. "pet"] = true
end
for i = 1, 40 do
	IsLegitimateUnit["raid" .. i] = true
	IsLegitimateUnit["raidpet" .. i] = true
	IsLegitimateUnit["raid" .. i .. "pet"] = true
end
setmetatable(IsLegitimateUnit, { __index = function(self, key)
	if type(key) ~= "string" then
		return false
	end
	if key:match("target$") then
		self[key] = self[key:sub(1, -7)]
		return self[key]
	end
	self[key] = false
	return false
end, __call = function(self, key)
	return self[key]
end})

function UnitExists(unit)
	if not IsLegitimateUnit(unit) then
		error(("Not a legitimate unit: %q"):format(unit), 2)
	end
	return units[unit] and units[unit].exists
end

function UnitHealth(unit)
	if not IsLegitimateUnit(unit) then
		error(("Not a legitimate unit: %q"):format(unit), 2)
	end
	return units[unit] and units[unit].hp
end

function UnitHealthMax(unit)
	if not IsLegitimateUnit(unit) then
		error(("Not a legitimate unit: %q"):format(unit), 2)
	end
	return units[unit] and units[unit].maxhp
end

function UnitMana(unit)
	if not IsLegitimateUnit(unit) then
		error(("Not a legitimate unit: %q"):format(unit), 2)
	end
	return units[unit] and units[unit].mp
end

function UnitManaMax(unit)
	if not IsLegitimateUnit(unit) then
		error(("Not a legitimate unit: %q"):format(unit), 2)
	end
	return units[unit] and units[unit].maxmp
end

function UnitIsUnit(alpha, bravo)
	if not IsLegitimateUnit(alpha) then
		error(("Not a legitimate unit: %q"):format(alpha), 2)
	end
	if not IsLegitimateUnit(bravo) then
		error(("Not a legitimate unit: %q"):format(bravo), 2)
	end
	return units[alpha] and units[bravo] and units[alpha] == units[bravo]
end

function UnitIsFriend(alpha, bravo)
	if alpha ~= 'player' then
	 	if bravo == 'player' then
			return UnitIsFriend(bravo, alpha)
		else
			return nil
		end
	end
	return units[bravo] and units[bravo].friend
end

function UnitCanAttack(alpha, bravo)
	return not UnitIsFriend(alpha, bravo)
end

function UnitPowerType(unit)
	return units[unit] and (units[unit].powerType or 0)
end

function UnitName(unit)
	if units[unit] then
		return units[unit].name, units[unit].realm
	end
end

function UnitClass(unit)
	if units[unit] then
		local class = units[unit].class or "Warrior"
		return class, class:upper()
	end
end

UnitClassBase = UnitClass

function UnitGUID(unit)
	return units[unit] and units[unit].guid or "0x0000000000000000"
end

function UnitLevel(unit)
	return units[unit] and (units[unit].level or 0)
end

function GetRealmName()
	return "My Realm"
end

function UnitCreatureFamily(unit)
	return units[unit] and units[unit].creatureFamily
end

function UnitCreatureType(unit)
	return units[unit] and (units[unit].creatureType or "Humanoid")
end

function UnitRace(unit)
	return units[unit] and (units[unit].race or "Human")
end

function UnitSex(unit)
	return units[unit] and (units[unit].sex or 2)
end

function GetGuildInfo(unit)
	if units[unit] then
		return units[unit].guild, units[unit].guildRank
	end
end

function UnitIsPlayer(unit)
	return unit == "player" or units[unit] and units[unit].isPlayer
end

function UnitPlayerControlled(unit)
	return unit == "player" or unit == "pet" or units[unit] and (units[unit].isPlayer or units[unit].isPet)
end

function UnitPlayerOrPetInRaid(unit)
	return unit == "player" or unit == "pet"
end

function UnitClassification(unit)
	return units[unit] and units[unit].classification or "normal"
end

function UnitPVPName(unit)
	if units[unit] and units[unit].pvpRank then
		return units[unit].pvpRank .. " " .. units[unit].name
	else
		return units[unit].name
	end
end

function UnitIsPVP(unit)
	return units[unit] and units[unit].isPvP
end

function UnitIsTapped(unit)
	return units[unit] and units[unit].tapped
end

function UnitIsTappedByPlayer(unit)
	return units[unit] and units[unit].tappedByPlayer
end

function UnitIsDead(unit)
	return units[unit] and units[unit].hp == 0
end

function UnitReaction(alpha, bravo)
	if alpha ~= "player" then
		if bravo == "player" then
			return UnitReaction(bravo, alpha)
		end
		return 4
	end
	return units[bravo] and (units[bravo].reaction or 4)
end

function GetNumPartyMembers()
	return 0
end

function GetNumRaidMembers()
	return 0
end

function UnitIsConnected(unit)
	return UnitExists(unit)
end

function UnitIsAFK(unit)
	return nil
end
function UnitIsDeadOrGhost(unit)
	return nil
end

UnitReactionColor = {
	{ r = 1, g = 0, b = 0 },
	{ r = 1, g = 0, b = 0 },
	{ r = 1, g = 0.5, b = 0 },
	{ r = 1, g = 1, b = 0 },
	{ r = 0, g = 1, b = 0 },
	{ r = 0, g = 1, b = 0 },
	{ r = 0, g = 1, b = 0 },
}

function UnitIsCharmed(unit)
	return nil
end

function UnitIsVisible(unit)
	return units[unit] and units[unit].exists
end

function GetDifficultyColor(number)
	local playerLevel = units.player.level
	if playerLevel >= number+5 then
		return { r = 0.5, g = 0.5, b = 0.5 }
	elseif playerLevel >= number+3 then
		return { r = 0.25, g = 0.75, b = 0.25 }
	elseif playerLevel >= number-2 then
		return { r = 1, g = 1, b = 0 }
	elseif playerLevel >= number-4 then
		return { r = 1, g = 0.5, b = 0.25 }
	else
		return { r = 1, g = 0.1, b = 0.1 }
	end
end

function GetWatchedFactionInfo()
	return "Exodar", 5, 1000, 5000, 3000
end

function IsResting()
	return nil
end

function UnitIsPartyLeader(unit)
	return unit == "player"
end

function UnitAffectingCombat(unit)
	return unit == "player" or unit == "target"
end

function IsInGuild()
	return nil
end

PET_HAPPINESS3 = "Happy"
PET_HAPPINESS2 = "Content"
PET_HAPPINESS1 = "Unhappy"

_G.FACTION_STANDING_LABEL5 = "Normal"
_G.FACTION_STANDING_LABEL6 = "Friendly"

_G.FAILED = "Failed"
_G.INTERRUPTED = "Interrupted"

_G.MAX_PLAYER_LEVEL = 70
_G.UNKNOWN = "Unknown"
_G.PVP_RANK_10_1 = "Warlord"

_G.UNITNAME_TITLE_CHARM = "%s's Minion"; -- %s is the name of the unit's charmer
_G.UNITNAME_TITLE_COMPANION = "%s's Companion";
_G.UNITNAME_TITLE_CREATION = "%s's Creation";
_G.UNITNAME_TITLE_GUARDIAN = "%s's Guardian";
_G.UNITNAME_TITLE_MINION = "%s's Minion";
_G.UNITNAME_TITLE_PET = "%s's Pet"; -- %s is the name of the unit's summoner

function GetComboPoints()
	return 0
end

function GetSpellInfo(num)
	return "Spell_" .. num
end

function UnitIsFeignDeath(unit)
	return nil
end

dofile("Localization/enUS.lua")
dofile("LibDogTag-Unit-3.0.lua")
dofile("Categories/Auras.lua")
dofile("Categories/Cast.lua")
dofile("Categories/Characteristics.lua")
dofile("Categories/DruidMana.lua")
dofile("Categories/Experience.lua")
dofile("Categories/GuildNote.lua")
dofile("Categories/Health.lua")
dofile("Categories/Misc.lua")
dofile("Categories/Power.lua")
dofile("Categories/Range.lua")
dofile("Categories/Reputation.lua")
dofile("Categories/Status.lua")
dofile("Categories/Talent.lua")
dofile("Categories/Threat.lua")
dofile("Categories/TooltipScanning.lua")
dofile("Cleanup.lua")

local MyUnit_data = "player"
DogTag:AddTag("Unit", "MyUnit", {
	code = function()
		return MyUnit_data
	end,
	ret = "string",
})

local MyValue_data = nil
DogTag:AddTag("Unit", "MyValue", {
	code = function()
		return MyValue_data
	end,
	ret = "nil;number;string",
})

assert_equal(DogTag:Evaluate("[HP('player')]"), "Unknown tag HP")

assert_equal(DogTag:Evaluate("[HP('player')]", "Unit"), 1500)
assert_equal(DogTag:Evaluate("[HP(unit='player')]", "Unit"), 1500)
assert_equal(DogTag:Evaluate("[HP]", "Unit", { unit = 'player'}), 1500)
assert_equal(DogTag:Evaluate("[MaxHP('player')]", "Unit"), 2000)
assert_equal(DogTag:Evaluate("[MaxHP(unit='player')]", "Unit"), 2000)
assert_equal(DogTag:Evaluate("[PercentHP(unit='player')]", "Unit"), 75)
assert_equal(DogTag:Evaluate("[MissingHP(unit='player')]", "Unit"), 500)
assert_equal(DogTag:Evaluate("[FractionalHP(unit='player')]", "Unit"), "1500/2000")
assert_equal(DogTag:Evaluate("[IsMaxHP(unit='player')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[HP(unit='pettarget', known=true)]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[MissingHP(unit='pettarget', known=true)]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[FractionalHP(unit='pettarget', known=true)]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[HP('target')]", "Unit"), 2500)
assert_equal(DogTag:Evaluate("[MaxHP('target')]", "Unit"), 2500)
assert_equal(DogTag:Evaluate("[IsMaxHP(unit='target')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[HP]", "Unit", { unit = 'target'}), 2500)
assert_equal(DogTag:Evaluate("[MaxHP]", "Unit", { unit = 'target'}), 2500)

assert_equal(DogTag:Evaluate("[HP('focus')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[MaxHP('focus')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[HP]", "Unit", { unit = 'focus'}), nil)
assert_equal(DogTag:Evaluate("[MaxHP]", "Unit", { unit = 'focus'}), nil)

assert_equal(DogTag:Evaluate("[HP('fakeunit')]", "Unit"), 'Bad unit: "fakeunit"')
assert_equal(DogTag:Evaluate("[HP(unit='fakeunit')]", "Unit"), 'Bad unit: "fakeunit"')
assert_equal(DogTag:Evaluate("[MaxHP('fakeunit')]", "Unit"), 'Bad unit: "fakeunit"')
assert_equal(DogTag:Evaluate("[MaxHP(unit='fakeunit')]", "Unit"), 'Bad unit: "fakeunit"')
assert_equal(DogTag:Evaluate("[HP]", "Unit", { unit = 'fakeunit'}), 'Bad unit: "fakeunit"')
assert_equal(DogTag:Evaluate("[MaxHP]", "Unit", { unit = 'fakeunit'}), 'Bad unit: "fakeunit"')
assert_equal(DogTag:Evaluate("[HP]", "Unit", { unit = 50 }), 'Bad unit: "50"')

MyUnit_data = "player"
assert_equal(DogTag:Evaluate("[HP(MyUnit)]", "Unit"), 1500)
MyUnit_data = "target"
assert_equal(DogTag:Evaluate("[HP(MyUnit)]", "Unit"), 2500)
MyUnit_data = "focus"
assert_equal(DogTag:Evaluate("[HP(MyUnit)]", "Unit"), nil)
MyUnit_data = "fakeunit"
assert_equal(DogTag:Evaluate("[HP(MyUnit)]", "Unit"), 'Bad unit: "fakeunit"')
MyValue_data = "fakeunit"
assert_equal(DogTag:Evaluate("[HP(MyValue)]", "Unit"), 'Bad unit: "fakeunit"')
MyValue_data = 50
assert_equal(DogTag:Evaluate("[HP(MyValue)]", "Unit"), 'Bad unit: "50"')
assert_equal(DogTag:Evaluate("[HP(nil)]", "Unit"), nil)
MyValue_data = nil
assert_equal(DogTag:Evaluate("[HP(MyValue)]", "Unit"), nil)

local frame = CreateFrame("Frame")
local fs = frame:CreateFontString(nil, "ARTWORK")
DogTag:AddFontString(fs, frame, "[HP]", "Unit", { unit = "player" })
assert_equal(fs:GetText(), 1500)
units.player.hp = 1600
FireEvent("UNIT_HEALTH", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 1600)

DogTag:AddFontString(fs, frame, "[HP]", "Unit", { unit = "target" })
assert_equal(fs:GetText(), 2500)
units.target.hp = 2000
units.target.maxhp = 2000
FireEvent("PLAYER_TARGET_CHANGED", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 2000)
units.target.hp = 2500
units.target.maxhp = 2500
FireEvent("PLAYER_TARGET_CHANGED", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 2500)

assert_equal(DogTag:Evaluate("[HPColor(unit='target')]", "Unit"), "|cff00ff00")
assert_equal(DogTag:Evaluate("[HPColor(unit='pet')]", "Unit"), "|cffff0000")
assert_equal(DogTag:Evaluate("[HPColor(unit='player')]", "Unit"), "|cff65ff00")

assert_equal(DogTag:Evaluate("['Hello':HPColor(unit='target')]", "Unit"), "|cff00ff00Hello|r")
assert_equal(DogTag:Evaluate("['Hello':HPColor(unit='pet')]", "Unit"), "|cffff0000Hello|r")
assert_equal(DogTag:Evaluate("['Hello':HPColor(unit='player')]", "Unit"), "|cff65ff00Hello|r")

DogTag:AddFontString(fs, frame, "[HP]", "Unit", { unit = "mouseover" })
assert_equal(fs:GetText(), nil)
units.mouseover.hp = 100
units.mouseover.maxhp = 100
units.mouseover.exists = true
FireEvent("UPDATE_MOUSEOVER_UNIT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 100)
units.mouseover.hp = 80
FireEvent("UNIT_HEALTH", "mouseover")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 80)
FireEvent("UNIT_HEALTH", "target")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 80)
local old_target = units.target
units.target = units.mouseover
FireEvent("PLAYER_TARGET_CHANGED")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 80)
units.mouseover.hp = 60
FireEvent("UNIT_HEALTH", "target")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 60)
units.target = old_target
FireEvent("PLAYER_TARGET_CHANGED")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 60)
units.mouseover.hp = 100
FireEvent("UNIT_HEALTH", "target")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 60)
FireEvent("UNIT_HEALTH", "mouseover")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 100)
units.mouseover.hp = 80
FireEvent("PLAYER_ENTERING_WORLD")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 80)

DogTag:AddFontString(fs, frame, "[HP]", "Unit", { unit = "mouseovertarget" })
assert_equal(fs:GetText(), nil)
FireOnUpdate(0.25)
assert_equal(fs:GetText(), nil)
units.mouseovertarget = {
	exists = true,
	hp = 10,
	maxhp = 15,
}
FireOnUpdate(0.2)
assert_equal(fs:GetText(), nil)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 10)
units.mouseovertarget = nil
FireOnUpdate(0.2)
assert_equal(fs:GetText(), 10)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), nil)

DogTag:AddFontString(fs, frame, "[HP(unit='mouseovertarget')]", "Unit")
assert_equal(fs:GetText(), nil)
FireOnUpdate(0.25)
assert_equal(fs:GetText(), nil)
units.mouseovertarget = {
	exists = true,
	hp = 10,
	maxhp = 15,
}
FireOnUpdate(0.2)
assert_equal(fs:GetText(), nil)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 10)
units.mouseovertarget = nil
FireOnUpdate(0.2)
assert_equal(fs:GetText(), 10)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), nil)

units.mouseover.exists = false
DogTag:AddFontString(fs, frame, "[HP]", "Unit", { unit = "mouseover" })
assert_equal(fs:GetText(), nil)
units.mouseover.exists = true
units.mouseover.hp = 10
units.mouseover.maxhp = 15
FireEvent("UPDATE_MOUSEOVER_UNIT")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 10)
units.mouseover.exists = false
FireEvent("PLAYER_ENTERING_WORLD")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 10)

assert_equal(DogTag:Evaluate("[IsFriend('player')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[IsFriend('target')]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[IsEnemy('player')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[IsEnemy('target')]", "Unit"), "True")

assert_equal(DogTag:Evaluate("[CanAttack('player')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[CanAttack('target')]", "Unit"), "True")

assert_equal(DogTag:Evaluate("[Name('player')]", "Unit"), "Me")
assert_equal(DogTag:Evaluate("[Name('target')]", "Unit"), "Mytarget")
assert_equal(DogTag:Evaluate("[Name('mouseovertarget')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[Name]", "Unit", { unit = 'mouseovertarget' }), "Mouse-over's target")

assert_equal(DogTag:Evaluate("[Exists('player')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[Exists('target')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[Exists('mouseovertarget')]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[Realm('player')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[Realm('target')]", "Unit"), "Other Realm")

assert_equal(DogTag:Evaluate("[NameRealm('player')]", "Unit"), "Me")
assert_equal(DogTag:Evaluate("[NameRealm('target')]", "Unit"), "Mytarget-Other Realm")

assert_equal(DogTag:Evaluate("[Level('player')]", "Unit"), 10)
assert_equal(DogTag:Evaluate("[Level('target')]", "Unit"), 15)
assert_equal(DogTag:Evaluate("[Level('pettarget')]", "Unit"), "??")

units.player.level = 70
assert_equal(DogTag:Evaluate("[IsMaxLevel('player')]", "Unit"), "True")
units.player.level = 10
assert_equal(DogTag:Evaluate("[IsMaxLevel('target')]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[Class('player')]", "Unit"), "Hunter")
assert_equal(DogTag:Evaluate("[Class('pet')]", "Unit"), "Warrior")

assert_equal(DogTag:Evaluate("[Creature('player')]", "Unit"), "Humanoid")
assert_equal(DogTag:Evaluate("[Creature('pet')]", "Unit"), "Cat")

assert_equal(DogTag:Evaluate("[CreatureType('player')]", "Unit"), "Humanoid")
assert_equal(DogTag:Evaluate("[CreatureType('pet')]", "Unit"), "Beast")

assert_equal(DogTag:Evaluate("[Classification('player')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[Classification('target')]", "Unit"), "Boss")

assert_equal(DogTag:Evaluate("[Race('player')]", "Unit"), "Tauren")
assert_equal(DogTag:Evaluate("[Race('target')]", "Unit"), "Human")

assert_equal(DogTag:Evaluate("[Sex('player')]", "Unit"), "Female")
assert_equal(DogTag:Evaluate("[Sex('target')]", "Unit"), "Male")

assert_equal(DogTag:Evaluate("[GuildRank('player')]", "Unit"), "Guild Leader")
assert_equal(DogTag:Evaluate("[GuildRank('target')]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[IsPlayer('player')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[IsPlayer('pet')]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[IsPet('player')]", "Unit"), nil)
assert_equal(DogTag:Evaluate("[IsPet('pet')]", "Unit"), "True")

assert_equal(DogTag:Evaluate("[IsPlayerOrPet('player')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[IsPlayerOrPet('pet')]", "Unit"), "True")
assert_equal(DogTag:Evaluate("[IsPlayerOrPet('pettarget')]", "Unit"), nil)

assert_equal(DogTag:Evaluate("[PvPRank(unit='player')]", "Unit"), "Knight")
assert_equal(DogTag:Evaluate("[NameRealm('player'):PvPRank(unit='player')]", "Unit"), "Knight Me")

assert_equal(DogTag:Evaluate("[HostileColor(unit='player')]", "Unit"), "|cff3071bf") -- civilian
assert_equal(DogTag:Evaluate("[HostileColor(unit='target')]", "Unit"), "|cffe22d4b") -- hostile reaction

assert_equal(DogTag:Evaluate("[AggroColor(unit='player')]", "Unit"), "|cff00ff00") -- friendly reaction
assert_equal(DogTag:Evaluate("[AggroColor(unit='target')]", "Unit"), "|cffff7f00") -- hostile reaction

assert_equal(DogTag:Evaluate("[ClassColor(unit='player')]", "Unit"), "|cffaad372") -- hunter color
assert_equal(DogTag:Evaluate("[ClassColor(unit='pet')]", "Unit"), "|cffc69b6d") -- warrior color

assert_equal(DogTag:Evaluate("[DifficultyColor(unit='player')]", "Unit"), "|cffffff00") -- yellow
assert_equal(DogTag:Evaluate("[DifficultyColor(unit='pet')]", "Unit"), "|cffffff00") -- yellow
assert_equal(DogTag:Evaluate("[DifficultyColor(unit='target')]", "Unit"), "|cffff1919") -- red

assert_equal(DogTag:Evaluate("[Guid(unit='player')]", "Unit"), "0x0000000000000000")

assert_equal(DogTag:Evaluate("[HasMP]", "Unit", { unit = 'player' }), "True")
assert_equal(DogTag:Evaluate("[MP]", "Unit", { unit = 'player' }), 100)
assert_equal(DogTag:Evaluate("[MaxMP]", "Unit", { unit = 'player' }), 100)
assert_equal(DogTag:Evaluate("[IsMaxMP]", "Unit", { unit = 'player' }), "True")
assert_equal(DogTag:Evaluate("[~IsMaxMP]", "Unit", { unit = 'player' }), nil)
assert_equal(DogTag:Evaluate("[~MaxMP]", "Unit", { unit = 'player' }), nil)
assert_equal(DogTag:Evaluate("[IsMaxMP:IsMana]", "Unit", { unit = 'player' }), "Bad unit: \"True\"")

assert_equal(DogTag:Evaluate("[Guild]", "Unit", { unit = 'target' }), nil)
assert_equal(DogTag:Evaluate("[Guild(unit='player')]", "Unit", { unit = 'target' }), "Southsea Buccaneers")
assert_equal(DogTag:Evaluate("[Guild = 'player':Guild]", "Unit", { unit = 'target' }), nil)
assert_equal(DogTag:Evaluate("[Guild:Angle]", "Unit", { unit = 'target' }), nil)
assert_equal(DogTag:Evaluate("[Guild = 'player':Guild] [Guild:Angle]", "Unit", { unit = 'target' }), nil)

assert_equal(DogTag:Evaluate("[IsMana]", "Unit", { unit = 'player' }), "True")
assert_equal(DogTag:Evaluate("[~IsMana]", "Unit", { unit = 'player' }), nil)
assert_equal(DogTag:Evaluate("[IsMana]", "Unit", { unit = 'target' }), nil)
assert_equal(DogTag:Evaluate("[~IsMana]", "Unit", { unit = 'target' }), "True")

assert_equal(DogTag:Evaluate("[[~IsMaxMP:~IsMana] ? PercentMP:Percent] [IsMana ? MaxMP:VeryShort:Prepend(\"| \")]", "Unit", { unit = 'target' }), "Bad unit: \"True\"")
assert_equal(DogTag:Evaluate("[One + NameRealm]", "Unit", { unit = 'target' }), 1)

--[Guild = "player":Guild] [Guild(unit="mouseover"):Angle]

print("LibDogTag-Unit-3.0: Tests succeeded")

if DogTag_Unit_SecondTime then
	return
end
DogTag_Unit_SecondTime = true
LibStub.minors["LibDogTag-Unit-3.0"] = 1
dofile('test.lua')