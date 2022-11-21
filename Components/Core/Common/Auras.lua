-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

if not TMW or not C_UnitAuras then return end


local TMW = TMW
local L = TMW.L
local print = TMW.print
local strlowerCache = TMW.strlowerCache

local select = select
local setmetatable = setmetatable

local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
local UnitAuraSlots = UnitAuraSlots
local UnitGUID = UnitGUID

if not GetAuraDataByAuraInstanceID then return end

TMW.COMMON.Auras = {}
local Auras = TMW.COMMON.Auras


--[[

Design notes:
This cannot be keyed by GUID because a particular GUID fall off of any available unitID
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

]]
local data = {}
Auras.data = data

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:SetScript("OnEvent", function(_, _, unit, unitAuraUpdateInfo)
    local unitData = data[unit]
    if not unitData then
        -- we have no cached unit data for this unitID,
        -- probably because the unitID recently changed to another unit
        -- so there's no compelling reason to process the event.

        -- Still fire TMW_UNIT_AURA because even things in TMW that don't use Auras:GetAuras 
        -- do use TMW_UNIT_AURA in order to avoid the excessive allocations from blizz's UNIT_AURA
        TMW:Fire("TMW_UNIT_AURA", unit)
        return
    end

    if unitAuraUpdateInfo.isFullUpdate then
        data[unit] = nil
        TMW:Fire("TMW_UNIT_AURA", unit)
        return
    end

    local instances = unitData.instances
    local lookup = unitData.lookup

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

            local name = strlowerCache[instance.name]
            local spellId = instance.spellId
            local dispelType = instance.dispelName
            local isMine = 
                instance.sourceUnit == "player" or
                instance.sourceUnit == "pet"
            eventHasMine = eventHasMine or isMine
            
            --print("added", unit, name, auraInstanceID)

            payload[name] = eventHasMine
            payload[spellId] = eventHasMine
            lookup[name][auraInstanceID] = isMine
            lookup[spellId][auraInstanceID] = isMine
            if dispelType then
                payload[dispelType] = eventHasMine
                lookup[dispelType][auraInstanceID] = isMine
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

                local name = strlowerCache[instance.name]
                local spellId = instance.spellId
                local dispelType = instance.dispelName
                local isMine = 
                    instance.sourceUnit == "player" or
                    instance.sourceUnit == "pet"
                eventHasMine = eventHasMine or isMine

                --print("updated", unit, name, auraInstanceID)

                payload[name] = eventHasMine
                payload[spellId] = eventHasMine
                if dispelType then
                    payload[dispelType] = eventHasMine
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
                local name = strlowerCache[instance.name]
                local spellId = instance.spellId
                local dispelType = instance.dispelName
                local isMine = 
                    instance.sourceUnit == "player" or
                    instance.sourceUnit == "pet"
                eventHasMine = eventHasMine or isMine
                    
                --print("remove", unit, name, auraInstanceID)

                payload[name] = eventHasMine
                payload[spellId] = eventHasMine
                lookup[name][auraInstanceID] = nil
                lookup[spellId][auraInstanceID] = nil
                if dispelType then
                    payload[dispelType] = eventHasMine
                    lookup[dispelType][auraInstanceID] = nil
                end
                instances[auraInstanceID] = nil
            end
        end
    end

    TMW:Fire("TMW_UNIT_AURA", unit, payload)
end)

local registeredUnitSets = {}

TMW:RegisterCallback("TMW_UNITSET_UPDATED", function(event, unitSet)
    if registeredUnitSets[unitSet] then
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
                if guid ~= auraKnownUnitGuids[i] then
                    -- The unitID is now referring to a different entity.
                    -- Clear out its saved auras so they'll be repopulated
                    -- the next time someone asks for that unit's auras.
                    auraKnownUnitGuids[i] = guid
                    --print("wiping unit (new guid)", currentUnit)
                    data[currentUnit] = nil
                end
            end
        end
    end
end)

function Auras:RequestUnits(unitSet)
    -- Get the pure unit set in case the one we were given had conditions attached.
    unitSet = TMW.UNITS:GetUnitSet(unitSet.unitSettings)
    if not registeredUnitSets[unitSet] then
        registeredUnitSets[unitSet] = true
        unitSet.auraKnownUnits = {}
        unitSet.auraKnownUnitGuids = {}
    end
    return unitSet.allUnitsChangeOnEvent
end

local function UpdateAuras(unit, instances, lookup, continuationToken, ...)
    local n = select('#', ...)

    for i = 1, n do
        local slot = select(i, ...)
        local instance = GetAuraDataBySlot(unit, slot)
        local auraInstanceID = instance.auraInstanceID
        local isMine = 
            instance.sourceUnit == "player" or
            instance.sourceUnit == "pet"

        instances[auraInstanceID] = instance
        lookup[strlowerCache[instance.name]][auraInstanceID] = isMine
        lookup[instance.spellId][auraInstanceID] = isMine
        if instance.dispelName then
            lookup[instance.dispelName][auraInstanceID] = isMine
        end
    end
end

local lookupMeta = {__index = function(t, k)
	t[k] = {}
	return t[k]
end}

--- It is assumed that the caller has previously called Auras:RequestUnit(unitSet) on a
--- unitset that contained the provided unit, and that unitSet.allUnitsChangeOnEvent == true.
function Auras.GetAuras(unit)
    local unitData = data[unit]
    if not unitData then
        local instances = {}
        local lookup = setmetatable({}, lookupMeta)
        unitData = {
            instances = instances,
            lookup = lookup
        }
        data[unit] = unitData

        --print("full updating unit", unit)
        UpdateAuras(unit, instances, lookup, UnitAuraSlots(unit, "HELPFUL"))
        UpdateAuras(unit, instances, lookup, UnitAuraSlots(unit, "HARMFUL"))
    end
    return unitData
end