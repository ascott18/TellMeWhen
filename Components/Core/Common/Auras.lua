-- --------------------
-- TellMeWhen
-- Originally by NephMakes

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
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber

local LARGE_NUMBER_SEPERATOR = LARGE_NUMBER_SEPERATOR
local DECIMAL_SEPERATOR = DECIMAL_SEPERATOR

local select = select
local wipe = wipe
local setmetatable = setmetatable
local rawget, rawset = rawget, rawset
local issecretvalue = TMW.issecretvalue

local IsAuraFilteredOutByInstanceID = C_UnitAuras.IsAuraFilteredOutByInstanceID
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
local GetAuraSlots = C_UnitAuras.GetAuraSlots or UnitAuraSlots
local GetUnitAuraBySpellID = C_UnitAuras.GetUnitAuraBySpellID
local GetAuraDataBySpellName = C_UnitAuras.GetAuraDataBySpellName
local ShouldAurasBeSecret = C_Secrets and C_Secrets.ShouldAurasBeSecret
local UnitGUID = TMW.UnitGUID

local GetSpellInfo = TMW.GetSpellInfo

TMW.COMMON.Auras = CreateFrame("Frame")
local Auras = TMW.COMMON.Auras

-- When the client has secret value restrictions, unit tokens can be secret values
-- that cause C_UnitAuras.GetAuraDataByIndex to throw an error because it receives
-- a player/pet name instead of a valid unit token. Wrap in pcall to safely return nil.
if TMW.clientHasSecrets then
    local _GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
    function Auras.GetAuraDataByIndex(unit, index, filter)
        if ShouldAurasBeSecret() then
            -- Reading auras by index, slot, or instance ID is a hard error
            -- while auras are secret. It's only while they're secret, though -
            -- consumers that aren't aura icons (dotwatch, the anima power
            -- watcher) do all their work outside that and still need this.
            return nil
        end
        local ok, result = pcall(_GetAuraDataByIndex, unit, index, filter)
        if ok then return result end
    end
else
	Auras.GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
end

--[[

Design notes:
This cannot be keyed by GUID because a particular GUID could fall off of any available unitID
and stop receiving aura updates, and we would have no way of knowing that GUID's data is stale.

data = {
    [unitID] = {
        instances = {
            [instanceId] = auraData
        },
        lookup = {
            [name | id | dispelType] = {
                [instanceId] = 1
            }
        }
    }
}

A unit's entry is built one of two ways, and which one it is doesn't change what consumers
see - they read `lookup` and `instances` either way.

Unrestricted, it's enumerated: every aura on the unit is scanned in once and then kept current
from the UNIT_AURA deltas.

While C_Secrets.ShouldAurasBeSecret(), enumeration isn't available at all (see "Restricted
mode" below), so the entry is filled in one identifier at a time as it's asked for, and carries
two extra fields:

    restricted = true,      -- which of the two shapes this is
    resolved = {
        [lookupKey] = { auraInstanceID, applications, expirationTime, isMine } -- last answer
    }

`resolved` doubles as the set of identifiers worth re-reading when UNIT_AURA says the unit
changed: a key is in there because something asked about it, and nothing asks about an aura
no icon or condition is watching.

]]
local data = {}
Auras.data = data

-- Optimization: have specific events for the most common units
-- to avoid all consumers having to listen to all UNIT_AURA events.
local dedicatedEventUnits = {
    player = "TMW_UNIT_AURA_PLAYER",
    target = "TMW_UNIT_AURA_TARGET",
    pet = "TMW_UNIT_AURA_PET",
}
local function FireUnitAura(unit, payload)
    local dedicatedEvent = dedicatedEventUnits[unit]
    if dedicatedEvent then
        TMW:Fire(dedicatedEvent, unit, payload)
    end
    TMW:Fire("TMW_UNIT_AURA", unit, payload)
end

local function AugmentInstance(unit, auraInstance)
    auraInstance.isMine = auraInstance.sourceUnit == "player" or auraInstance.sourceUnit == "pet"
    if auraInstance.dispelName == "" or auraInstance.dispelName == "Enrage" then
        -- Bugfix: Enraged is an empty string (2026 finally fixed to "Enrage").
        auraInstance.dispelName = "Enraged"
    end
end

-- False on clients with no secret restrictions, where the enumerating path always
-- runs and none of this is needed.
local useRestrictedLookups = TMW.clientHasSecrets
    and GetUnitAuraBySpellID
    and GetAuraDataBySpellName

-- The regular AugmentInstance can't run here: its secret-aware half is built on
-- IsAuraFilteredOutByInstanceID, which is an instance-ID read. Everything
-- needed is on the instance itself anyway.
local function AugmentRestrictedInstance(instance)
    local sourceUnit = instance.sourceUnit
    instance.isMine = not issecretvalue(sourceUnit)
        and (sourceUnit == "player" or sourceUnit == "pet")
        or false

    local dispelName = instance.dispelName
    if not issecretvalue(dispelName) and (dispelName == "" or dispelName == "Enrage") then
        -- Bugfix: Enraged is an empty string (2026 finally fixed to "Enrage").
        instance.dispelName = "Enraged"
    end

    -- buff.lua tests this directly, and TMW never does anything with a secret
    -- isStealable.
    if issecretvalue(instance.isStealable) then
        instance.isStealable = false
    end
end

-- Drops every unit's cache and tells consumers to rebuild it. Collected before
-- firing because consumers answer by calling GetAuras, which puts units back into
-- `data`, and growing a table you're in the middle of iterating is undefined.
local scratchUnits = {}
local function WipeAllUnits()
    local n = 0
    for unit in pairs(data) do
        n = n + 1
        scratchUnits[n] = unit
    end

    for i = 1, n do
        local unit = scratchUnits[i]
        scratchUnits[i] = nil
        data[unit] = nil
        FireUnitAura(unit)
    end
end

local OnUnitAura
if TMW.clientHasSecrets then
    local blocked = false

    -- There's no event for the restriction flipping, so watch it off TMW's update.
    TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", function()
        local newBlocked = ShouldAurasBeSecret()
        if blocked ~= newBlocked then
            blocked = newBlocked

            -- Everything cached was built by whichever mode we just left, and the
            -- two modes don't hold the same shape of data, so none of it carries
            -- over in either direction. Consumers repopulate on the event - which
            -- while restricted is also what puts identifiers back into the unit's
            -- resolved set, so UNIT_AURA knows what to look at.
            --print("wiping all units (restriction changed)")
            WipeAllUnits()
        end
    end)

    local AugmentInstance_base = AugmentInstance
    AugmentInstance = function(unit, auraInstance)
        local auraInstanceID = auraInstance.auraInstanceID

        if not issecretvalue(auraInstance.expirationTime) then
            -- Whole aura is non-secret. Just apply normal non-secret augments and bail.
            AugmentInstance_base(unit, auraInstance)
            return
        end

        if useRestrictedLookups and ShouldAurasBeSecret() then
            -- Everything below is an instance-ID read, which errors outright here. Restricted
            -- mode has its own augment and doesn't come through this function; what can is a
            -- UNIT_AURA landing in the tick between the restriction turning on and the handler
            -- above noticing it.
            AugmentRestrictedInstance(auraInstance)
            return
        end

        -- just avoid ugly secret checks in buff.lua for stealable.
        -- We never do anything in TMW with secret `isStealable`.
        auraInstance.isStealable = false

        -- Unsecret some fields that have no business being secret
        local helpful = not IsAuraFilteredOutByInstanceID(unit, auraInstanceID, "HELPFUL|INCLUDE_NAME_PLATE_ONLY")
        auraInstance.isMine = not IsAuraFilteredOutByInstanceID(unit, auraInstanceID,
            "PLAYER|INCLUDE_NAME_PLATE_ONLY" .. (helpful and "|HELPFUL" or "|HARMFUL")
        )
    end

end

-- ---------------------------------------------------------------------------
-- Restricted mode
--
-- While auras are secret in 12.1, every aura read that takes an index, a slot,
-- or an auraInstanceID errors outright, and UNIT_AURA's payload is entirely
-- secret. The only reads that survive are by identifier - GetUnitAuraBySpellID
-- and GetAuraDataBySpellName - which hand back real data for spells Blizzard
-- flags non-secret and nothing at all for the rest.
--
-- A unit's auras therefore can't be enumerated, only interrogated one
-- identifier at a time. `lookup` resolves its keys on demand, and the keys that
-- have been asked for are what UNIT_AURA re-reads: nothing looks up an identifier
-- unless some icon or condition is watching it, so the set maintains itself and
-- no consumer has to register anything.
--
-- Consumers see the same shape either way. What they lose while restricted is
-- what the identifier reads can't express: dispel types (no way to look one
-- up), the second and later copies of a spell (only the first comes back), and
-- any spell Blizzard flags secret, whose absence is indistinguishable from a
-- spell that simply isn't there.
-- ---------------------------------------------------------------------------

local issecrettable = issecrettable or TMW.NULLFUNC

-- Lookup keys are lowercased spell names, and GetAuraDataBySpellName matches
-- case-sensitively, so ask the game for its own spelling. RestoreCase is the
-- fallback for a name this client can't resolve - another class's buff, where
-- the best we have is whatever the user typed.
local canonicalNames = setmetatable({}, { __index = function(t, key)
    local name = GetSpellInfo(key) or TMW:RestoreCase(key)
    t[key] = name
    return name
end })

-- Returns the aura matching `key` on `unit`, or nil. A nil is not proof of
-- absence: a spell whose aura is secret answers exactly the way one that isn't
-- there does. Only C_Secrets.GetSpellAuraSecrecy can tell those apart, and only
-- for spells flagged NeverSecret.
local function QueryIdentifier(unit, key)
    if type(key) == "number" then
        -- Takes no filter, so kind and source are tested off the instance by
        -- whoever asked. Returns only the first instance of the spell.
        return GetUnitAuraBySpellID(unit, key)
    end

    -- Nothing looks an aura up by dispel type; that takes enumeration.
    if TMW.DS[key] then
        return nil
    end

    -- Matched by name rather than by the ID it resolves to: one name covers several
    -- spell IDs, and the enumerating path matched on instance.name.
    local name = canonicalNames[key]
    return GetAuraDataBySpellName(unit, name, "HELPFUL")
        or GetAuraDataBySpellName(unit, name, "HARMFUL")
end

-- Whether `instance` still matches what `state` recorded. Only the fields a
-- consumer could notice a change in: identity, stacks, and expiry. A field that
-- came back secret records as nil, since it can't be compared and can't drive a
-- condition either.
local function MatchesState(state, instance)
    if state.auraInstanceID ~= instance.auraInstanceID then
        return false
    end

    local applications = instance.applications
    if issecretvalue(applications) then
        if state.applications ~= nil then return false end
    elseif state.applications ~= applications then
        return false
    end

    local expirationTime = instance.expirationTime
    if issecretvalue(expirationTime) then
        if state.expirationTime ~= nil then return false end
    elseif state.expirationTime ~= expirationTime then
        return false
    end

    return true
end

-- Brings `key` up to date on this unit, and reports whether anything a consumer
-- could see has changed. The only writer of a restricted unitData - both the lookup
-- metatable and the UNIT_AURA refresh come through here.
local function RefreshIdentifier(unit, unitData, key)
    local lookup, instances, resolved = unitData.lookup, unitData.instances, unitData.resolved

    local entry = rawget(lookup, key)
    if not entry then
        entry = {}
        rawset(lookup, key, entry)
    end

    local state = resolved[key]
    if not state then
        state = {}
        resolved[key] = state
    end

    local instance = QueryIdentifier(unit, key)
    if instance and (
        -- A spell that reads back, but off a unit we aren't allowed to read.
        -- Nothing here can key a table or be branched on, so it's no use to
        -- anyone - and the table itself has to be tested before it's indexed.
        issecrettable(instance)
        or issecretvalue(instance.auraInstanceID)
        or issecretvalue(instance.isHelpful)
    ) then
        instance = nil
    end

    local previousID = state.auraInstanceID
    -- Reported alongside the change so that an aura going away still tells an
    -- OnlyMine consumer it was theirs. By the time the payload is built the
    -- instance is gone, so this is the only record of it.
    local wasMine = state.isMine

    if not instance then
        if previousID == nil then
            return false
        end

        instances[previousID] = nil
        wipe(entry)
        state.auraInstanceID, state.applications, state.expirationTime, state.isMine = nil, nil, nil, nil
        return true, wasMine
    end

    local changed = previousID == nil or not MatchesState(state, instance)

    if previousID ~= nil and previousID ~= instance.auraInstanceID then
        instances[previousID] = nil
    end

    -- Restored even when nothing changed: every query hands back a fresh table,
    -- and consumers read their fields straight off the stored instance.
    AugmentRestrictedInstance(instance)
    instances[instance.auraInstanceID] = instance
    wipe(entry)
    entry[instance.auraInstanceID] = instance.isMine

    local applications = instance.applications
    local expirationTime = instance.expirationTime
    state.auraInstanceID = instance.auraInstanceID
    state.applications = not issecretvalue(applications) and applications or nil
    state.expirationTime = not issecretvalue(expirationTime) and expirationTime or nil
    state.isMine = instance.isMine

    return changed, wasMine or instance.isMine
end

local function CreateRestrictedUnitData(unit)
    local unitData
    unitData = {
        instances = {},
        -- [lookupKey] = the last answer's identity, stacks, and expiry. Also the set
        -- of identifiers UNIT_AURA re-reads - a key is in here because something
        -- asked about it.
        resolved = {},
        restricted = true,
    }
    unitData.lookup = setmetatable({}, { __index = function(t, key)
        RefreshIdentifier(unit, unitData, key)
        return rawget(t, key)
    end })
    return unitData
end

-- Re-reads every identifier anyone has asked about on this unit and fires
-- TMW_UNIT_AURA with the usual payload for the ones that moved. Driven by
-- UNIT_AURA: the delta is unreadable while restricted, but the event still names
-- the unit, which is all this needs to know when to look again.
local function RefreshRestrictedUnit(unit, unitData)
    local payload

    for key in pairs(unitData.resolved) do
        local changed, mightBeMine = RefreshIdentifier(unit, unitData, key)
        if changed then
            payload = payload or {}
            -- Same shape the enumerating path fires: the value says whether what
            -- changed might have been ours.
            payload[key] = mightBeMine or false
        end
    end

    -- Fired after the walk. Firing runs conditions synchronously, and a condition
    -- answers by calling GetAuras, which adds keys to `resolved` - growing a table
    -- you're in the middle of iterating is undefined.
    if payload then
        FireUnitAura(unit, payload)
    end
end

OnUnitAura = function(unit, unitAuraUpdateInfo)
    local unitData = data[unit]

    if unitData and unitData.restricted then
        -- The delta is unreadable, but which unit changed isn't, and that's enough:
        -- re-read the identifiers anyone asked about on it. Passing the event
        -- straight through instead would make every consumer of the unit
        -- re-evaluate on every UNIT_AURA whether or not anything they watch moved.
        RefreshRestrictedUnit(unit, unitData)
        return
    end

    if not unitData or issecretvalue(unitAuraUpdateInfo.isFullUpdate) then
        -- we have no cached unit data for this unitID,
        -- probably because the unitID recently changed to another unit
        -- so there's no compelling reason to process the event.

        -- Still fire TMW_UNIT_AURA because even things in TMW that don't use Auras:GetAuras 
        -- do use TMW_UNIT_AURA in order to avoid the excessive allocations from blizz's UNIT_AURA
        FireUnitAura(unit)
        return
    end

    if unitAuraUpdateInfo.isFullUpdate then
        data[unit] = nil
        FireUnitAura(unit)
        return
    end

    local instances = unitData.instances
    local lookup = unitData.lookup

    -- Payload is a lookup table sent as the event payload of TMW_UNIT_AURA,
    -- with the structure { [name | id | dispelType] = mightBeMine(bool) }
    local payload = {}
    -- Because `payload` is flat, we might override a `true` isMine flag
    -- with a `false` isMine flag later on in the event for some name/id.
    -- So, short of tracking this status per payload key (which would require
    -- extra table lookups, we just track if the event had /something/ that was mine,
    -- which is usually good enough.)
    local eventHasMine = false

    local added = unitAuraUpdateInfo.addedAuras
    if added then
        for i = 1, #added do
            local instance = added[i]
            local auraInstanceID = instance.auraInstanceID

            instances[auraInstanceID] = instance

            AugmentInstance(unit, instance)

            if not issecretvalue(instance.name) then
                local name = strlowerCache[instance.name]
                local spellId = instance.spellId
                local isMine = instance.isMine
                eventHasMine = eventHasMine or isMine
                
                --print("added", unit, name, auraInstanceID)

                payload[name] = eventHasMine
                payload[spellId] = eventHasMine
                lookup[name][auraInstanceID] = isMine
                lookup[spellId][auraInstanceID] = isMine

                local dispelType = instance.dispelName
                if dispelType and not issecretvalue(dispelType) then
                    payload[dispelType] = eventHasMine
                    lookup[dispelType][auraInstanceID] = isMine
                end
            end
        end
    end

    local updated = unitAuraUpdateInfo.updatedAuraInstanceIDs
    if updated then
        for i = 1, #updated do
            local auraInstanceID = updated[i]
            local instance = GetAuraDataByAuraInstanceID(unit, auraInstanceID)
            if not instance then
                -- Sometimes, updated really means removed!
                -- Except the remove will still happen, so don't actually remove here. Just do nothing.
                -- Example: When Voidform (shadow priest, 194249) expires,
                -- it is fired as an update but it has already been removed at that point and GADBAIID will return nil

                -- local oldInstance = instances[auraInstanceID]
                -- print("UPDATED AURA INSTANCE NIL", unit, auraInstanceID, oldInstance, oldInstance and oldInstance.name, oldInstance and oldInstance.spellId)
            else
                instances[auraInstanceID] = instance

                AugmentInstance(unit, instance)

                if not issecretvalue(instance.name) then
                    local name = strlowerCache[instance.name]
                    local spellId = instance.spellId
                    local dispelType = instance.dispelName
                    local isMine = instance.isMine
                    eventHasMine = eventHasMine or isMine

                    --print("updated", unit, name, auraInstanceID)

                    payload[name] = eventHasMine
                    payload[spellId] = eventHasMine
                    if dispelType and not issecretvalue(dispelType) then
                        payload[dispelType] = eventHasMine
                    end
                end
            end
        end
    end

    local removed = unitAuraUpdateInfo.removedAuraInstanceIDs
    if removed then
        for i = 1, #removed do
            local auraInstanceID = removed[i]
            local instance = instances[auraInstanceID]

            -- Sometimes the instance won't exist, for unknown reasons.
            if instance then
                if not issecretvalue(instance.name) then
                    local name = strlowerCache[instance.name]
                    local spellId = instance.spellId
                    local dispelType = instance.dispelName
                    local isMine = instance.isMine
                    eventHasMine = eventHasMine or isMine
                        
                    --print("remove", unit, name, auraInstanceID)

                    payload[name] = eventHasMine
                    lookup[name][auraInstanceID] = nil

                    payload[spellId] = eventHasMine
                    lookup[spellId][auraInstanceID] = nil

                    if dispelType and not issecretvalue(dispelType) then
                        lookup[dispelType][auraInstanceID] = nil
                        payload[dispelType] = eventHasMine
                    end
                end
                instances[auraInstanceID] = nil
            end
        end
    end

    FireUnitAura(unit, payload)
end


Auras:RegisterEvent("PLAYER_ENTERING_WORLD")
-- Auras:RegisterEvent("PLAYER_TARGET_CHANGED")
-- Auras:RegisterUnitEvent("UNIT_TARGET", "player")
Auras:SetScript("OnEvent", function (self, event, ...)
    if event == "UNIT_AURA" then
        OnUnitAura(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(data)
    end
end)



local function TMW_UNITSET_UPDATED(event, unitSet)
    local originalUnits = unitSet.originalUnits
    local auraKnownUnits = unitSet.auraKnownUnits
    local auraKnownUnitGuids = unitSet.auraKnownUnitGuids
    local translatedUnits = unitSet.translatedUnits
    local UnitsLookup = unitSet.UnitsLookup

    for i = 1, #originalUnits do
        local currentUnit = translatedUnits[i]
        local exists = UnitsLookup[currentUnit]
            
        if not exists then
            -- this unit is gone. the auras module formerly knew this unit as auraKnownUnits[i],
            -- which is what this originalUnit used to translate into before it stopped existing.
            local oldKnownUnit = auraKnownUnits[i]
            if oldKnownUnit then
                --print("wiping unit (gone)", currentUnit)
                data[oldKnownUnit] = nil
                auraKnownUnits[i] = nil
                auraKnownUnitGuids[i] = nil
            end
        else
            local guid = UnitGUID(currentUnit)
            auraKnownUnits[i] = currentUnit
            if issecretvalue(guid) then
                -- ¯\_(ツ)_/¯
                data[currentUnit] = nil
            else
                if guid ~= auraKnownUnitGuids[i] then
                    -- The unitID is now referring to a different entity.
                    -- Clear out its saved auras so they'll be repopulated
                    -- the next time someone asks for that unit's auras.
                    --print("wiping unit (new guid)", currentUnit)
                    auraKnownUnitGuids[i] = guid
                    data[currentUnit] = nil
                end
            end
        end
    end
end

local needsAllUnits = false
local registeredUnits = {}
local registeredUnitSets = {}

function Auras:RequestUnits(unitSet)
    if type(unitSet) == "string" then
        -- Allow a unit string to be passed directly.
        _, unitSet = TMW:GetUnits(nil, unitSet)
    else
        -- Get the pure unit set in case the one we were given had conditions attached.
        _, unitSet = TMW:GetUnits(nil, unitSet.unitSettings)
    end

    if not registeredUnitSets[unitSet] then 
        registeredUnitSets[unitSet] = true
        TMW:RegisterCallback(unitSet.event, TMW_UNITSET_UPDATED)
        unitSet.auraKnownUnits = {}
        unitSet.auraKnownUnitGuids = {}

        if needsAllUnits then
            -- pass
        elseif not unitSet.allUnitsChangeOnEvent or unitSet.hasSpecialUnitRefs then
            needsAllUnits = true
        else
            for i = 1, #unitSet.originalUnits do
                local unit = unitSet.originalUnits[i]
                if not tContains(registeredUnits, unit) then
                    tinsert(registeredUnits, unit)
                end
                if #registeredUnits > 4 then
                    -- RegisterUnitEvent maxes out at 4 units.
                    -- That's enough to cover efficiency for the most common player/target/pet/focus.
                    -- If people are tracking more than that, they're probably tracking LOTS more, like raid 1-40.
                    needsAllUnits = true
                    break
                end
            end
        end

        if needsAllUnits then
            Auras:RegisterEvent("UNIT_AURA")
        else
            Auras:RegisterUnitEvent("UNIT_AURA", unpack(registeredUnits))
        end
    end

    if not unitSet.allUnitsChangeOnEvent then
        return false, "TMW_UNIT_AURA"
    elseif dedicatedEventUnits[unitSet.unitSettings] then
        return true, dedicatedEventUnits[unitSet.unitSettings]
    else
        return true, "TMW_UNIT_AURA"
    end
end

local function UpdateAuras(unit, instances, lookup, continuationToken, ...)
    local n = select('#', ...)

    for i = 1, n do
        local slot = select(i, ...)
        local instance = GetAuraDataBySlot(unit, slot)

        -- Check `if instance` because sometimes GetAuraSlots returns invalid slots I guess?
        -- Only ever seen this happen in arena.
        if instance then
            local auraInstanceID = instance.auraInstanceID

            AugmentInstance(unit, instance)

            --print("scanned", unit, instance.name, auraInstanceID)

            instances[auraInstanceID] = instance
            if not issecretvalue(instance.name) then
                local isMine = instance.isMine
                
                lookup[strlowerCache[instance.name]][auraInstanceID] = isMine
                lookup[instance.spellId][auraInstanceID] = isMine
                local dispelType = instance.dispelName
                if dispelType and not issecretvalue(dispelType) then
                    lookup[dispelType][auraInstanceID] = isMine
                end
            end
        end
    end
end

local lookupMeta = {
    __index = function(t, k)
        local ret = {}
        t[k] = ret
        return ret
    end
}

--- It is assumed that the caller has previously called Auras:RequestUnit(unitSet) on a
--- unitSet that contained the provided unit, and that unitSet.allUnitsChangeOnEvent == true.
function Auras.GetAuras(unit)
    local unitData = data[unit]
    if not unitData then
        if useRestrictedLookups and ShouldAurasBeSecret() then
            -- Nothing can be enumerated right now. Hand back a table that
            -- resolves whatever it's asked for, one identifier at a time.
            unitData = CreateRestrictedUnitData(unit)
            data[unit] = unitData
            return unitData
        end

        local instances = {}
        local lookup = setmetatable({}, lookupMeta)
        unitData = {
            instances = instances,
            lookup = lookup
        }
        data[unit] = unitData

        --print("full updating unit", unit)

        -- INCLUDE_NAME_PLATE_ONLY adds additional auras that are otherwise hidden,
        -- like 1226662 Crusading Strikes (ret pally hidden buff)
        UpdateAuras(unit, instances, lookup, GetAuraSlots(unit, "HELPFUL|INCLUDE_NAME_PLATE_ONLY"))
        UpdateAuras(unit, instances, lookup, GetAuraSlots(unit, "HARMFUL|INCLUDE_NAME_PLATE_ONLY"))
    end
    return unitData
end


local function ParseTooltipText(text, instance)
    instance.tmwTooltipNumbers = {}

    local index = 0
    local last = -1
    local number, start
    repeat
        start, last, number = (text):find("([0-9%" .. LARGE_NUMBER_SEPERATOR .. "]+%" .. DECIMAL_SEPERATOR .. "?[0-9]*)", last + 1)
        if number then
            -- Remove large number separators
            number = number:gsub("%" .. LARGE_NUMBER_SEPERATOR, "")
            -- Normalize decimal separators
            number = number:gsub("%" .. DECIMAL_SEPERATOR, ".")
            number = number:trim(".")
            
            index = index + 1
            instance.tmwTooltipNumbers[index] = isNumber[number]
        end
    until not number

    return instance.tmwTooltipNumbers
end

if C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID then

    function Auras.ParseTooltip(unit, instance)
        if instance.tmwTooltipNumbers then
            -- Return cached value if available
            return instance.tmwTooltipNumbers
        end

        -- The second test is the 12.1 restriction: these are instance-ID reads,
        -- so they're off limits while auras are secret even for an instance we
        -- were allowed to look up by identifier.
        if issecretvalue(instance.spellId) or ShouldAurasBeSecret() then
            instance.tmwTooltipNumbers = {}
            return instance.tmwTooltipNumbers
        end

        local data = C_TooltipInfo[instance.isHelpful and "GetUnitBuffByAuraInstanceID" or "GetUnitDebuffByAuraInstanceID"](unit, instance.auraInstanceID)

        local line = data and data.lines and data.lines[2]
        local text = line and line.leftText or ""
        return ParseTooltipText(text, instance)
    end

else
    local GetAuraDataByIndex = Auras.GetAuraDataByIndex
    local Parser, LT1, LT2 = TMW:GetParser()

    function Auras.ParseTooltip(unit, instance, auraIndex) 
        if instance.tmwTooltipNumbers then
            -- Return cached value if available
            return instance.tmwTooltipNumbers
        end

        local filter = instance.isHelpful and "HELPFUL" or "HARMFUL"

        instance.tmwTooltipNumbers = {}
        if not auraIndex then

            -- Because classic doesn't have a way to set a tooltip from an aura instance,
            -- we have to go find the index of the aura on the unit

            for i = 1, 100 do
                local data = GetAuraDataByIndex(unit, i, filter)
                if not data then return end

                if data.auraInstanceID == instance.auraInstanceID then
                    auraIndex = i
                    break
                end
            end
        end

        if auraIndex then
            Parser:SetOwner(UIParent, "ANCHOR_NONE")
            Parser:SetUnitAura(unit, auraIndex, filter)
            local text = LT2:GetText() or ""
            Parser:Hide()

            return ParseTooltipText(text, instance)
        end
    
        return instance.tmwTooltipNumbers
    end

end


-- ---------------------------------------------------------------------------
-- Config: which of an icon's spells stay readable while auras are secret
-- ---------------------------------------------------------------------------

if TMW.clientHasSecrets then
    local GetSpellAuraSecrecy = C_Secrets.GetSpellAuraSecrecy
    local SECRECY_NEVER = Enum.SecrecyLevel and Enum.SecrecyLevel.NeverSecret

    --- Classifies every entry of `spellString` by whether the game will let TMW read that
    --- spell's aura while auras are secret - which is what separates an entry an icon still
    --- checks under restriction from one that reads as absent there. Returns two lists of
    --- display strings: the readable entries, and the rest with their reasons.
    ---
    --- Deliberately not routed through SpellCache, even though the icon editor has it and
    --- could name the spell behind an ID the runtime can't resolve: what matters here is
    --- what the icon will actually manage at runtime.
    function Auras.ClassifySpells(spellString)
        local array = TMW:GetSpells(spellString, false).ArrayNoLower
        local readable, unreadable = {}, {}

        for i = 1, #array do
            local identifier = array[i]
            local label, reason = tostring(identifier), nil

            if TMW.DS[identifier] then
                -- Finding an aura by dispel type takes enumeration, which is the thing
                -- restriction removes, whatever the auras behind it are flagged.
                reason = L["UIPANEL_BUFFCHECK_SECRETS_DISPELTYPE"]
            else
                -- Fill in whichever half of the pair wasn't typed, so every row reads
                -- "Name (ID)". ID -> name always works; name -> ID only for spells this
                -- character knows, which is the whole thing this panel is here to report.
                local name, spellID
                if type(identifier) == "number" then
                    spellID = identifier
                    name = GetSpellInfo(identifier)
                else
                    name = identifier
                    spellID = select(7, GetSpellInfo(identifier))
                end

                if name and spellID then
                    label = name .. " (" .. spellID .. ")"
                end

                if not spellID then
                    -- A name this character's client can't resolve - another class's buff,
                    -- usually.
                    reason = L["UIPANEL_BUFFCHECK_SECRETS_UNRESOLVED"]
                elseif GetSpellAuraSecrecy(spellID) ~= SECRECY_NEVER then
                    reason = L["UIPANEL_BUFFCHECK_SECRETS_RESTRICTED"]
                end
            end

            if reason then
                unreadable[#unreadable + 1] = label .. " |cff808080- " .. reason .. "|r"
            else
                readable[#readable + 1] = label
            end
        end

        return readable, unreadable
    end

    --- Whether anything in `spellString` is something the game won't let TMW read while auras
    --- are secret: a spell flagged secret, a name this client can't resolve, a dispel type, or
    --- nothing at all, which means every aura on the unit. The same rule ClassifySpells sorts
    --- by, without building the display strings - this one runs per icon Setup rather than
    --- only while the icon editor is open.
    function Auras.HasUnreadableSpell(spellString)
        local array = TMW:GetSpells(spellString, false).ArrayNoLower

        -- Nothing entered means every aura on the unit, which takes enumeration.
        if #array == 0 then
            return true
        end

        for i = 1, #array do
            local identifier = array[i]
            if TMW.DS[identifier] then
                return true
            end

            local spellID = identifier
            if type(spellID) ~= "number" then
                spellID = select(7, GetSpellInfo(identifier))
            end
            if not spellID or GetSpellAuraSecrecy(spellID) ~= SECRECY_NEVER then
                return true
            end
        end

        return false
    end

    --- Registers the ClassifySpells breakdown as a config panel on `Type` - the whole of what
    --- that type has to say about combat, so it isn't paired with a separate warning. Belongs
    --- below the name field, not above it: every line of it is about what was entered there.
    --- Each type passes its own frameName, since panels are looked up and reused by that name.
    ---
    --- `opts` carries what differs between types:
    ---   trackAll - display string for the blank-name case, which means every aura on the unit
    ---              and so needs the enumeration restriction removes. Types that require a name
    ---              omit it, and the panel hides itself when nothing has been entered.
    ---   advice   - line appended whenever something can't be read. May contain hyperlinks;
    ---              TellMeWhen_TextPanel's OnHyperlinkClick handles TMW_ICONTYPE ones.
    function Auras.RegisterSecrecyPanel(Type, order, frameName, opts)
        Type:RegisterConfigPanel_XMLTemplate(order, "TellMeWhen_TextPanel", {
            frameName = frameName,
            OnSetup = function(self)
                -- The layout shows every panel, calls Setup, then checks IsShown() to decide
                -- whether it joins the column - so Setup is the one place a panel can take
                -- itself out. Never the reverse: showing from a later reload puts it back on
                -- screen with no place in the column, anchored to the top of it, on top of
                -- whatever is really there.
                local readable, unreadable = Auras.ClassifySpells(TMW.CI.ics.Name)
                if #readable == 0 and #unreadable == 0 and not (opts and opts.trackAll) then
                    -- Nothing entered and nothing to say about it. The title on its own would
                    -- just be an empty panel.
                    self:Hide()
                    return
                end

                -- OnSetup runs on every icon load and CScriptAdd doesn't dedupe, so the
                -- handler below would otherwise stack up one copy per load.
                if self.tmwSecrecyPanelBuilt then return end
                self.tmwSecrecyPanelBuilt = true

                -- Not the shared "Restricted in Combat" title: the panel is a breakdown, and
                -- most of the time the answer it gives is that nothing here is restricted.
                self:SetTitle(L["UIPANEL_BUFFCHECK_SECRETS_TITLE"])
                self:SetHyperlinksEnabled(true)

                -- Recomputed on every reload rather than set once: the verdict is per spell,
                -- and the spell list changes as the user types into the name box.
                self:CScriptAdd("ReloadRequested", function(panel)
                    -- Read from the settings rather than from icon.Spells: this fires while
                    -- the name box is being edited, before the icon has been set up again.
                    local readable, unreadable = Auras.ClassifySpells(TMW.CI.ics.Name)

                    if #readable == 0 and #unreadable == 0 and opts and opts.trackAll then
                        -- Rendered as the single unreadable entry rather than as its own
                        -- paragraph, so it picks up the same heading and advice as any spell
                        -- that can't be read.
                        unreadable[1] = opts.trackAll
                    end

                    -- Same two headings whatever the spell list holds, so the panel reads as
                    -- a breakdown rather than as a verdict that only appears when something
                    -- is wrong. A heading with nothing under it is dropped.
                    local sections = {}
                    if #unreadable > 0 then
                        sections[#sections + 1] = "|cffff5959" .. L["UIPANEL_BUFFCHECK_SECRETS_UNREADABLE"] .. "|r\r\n"
                            .. table.concat(unreadable, "\r\n")
                    end
                    if #readable > 0 then
                        sections[#sections + 1] = "|cff00ff00" .. L["UIPANEL_BUFFCHECK_SECRETS_READABLE"] .. "|r\r\n"
                            .. table.concat(readable, "\r\n")
                    end
                    if #unreadable > 0 and opts and opts.advice then
                        sections[#sections + 1] = opts.advice
                    end

                    panel.text:SetText(table.concat(sections, "\r\n\r\n"))
                end)
            end,
        })
    end
end