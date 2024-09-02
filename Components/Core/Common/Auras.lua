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
local setmetatable = setmetatable

local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
local GetAuraSlots = C_UnitAuras.GetAuraSlots or UnitAuraSlots
local UnitGUID = UnitGUID

local function getOrCreate(t, k)
    local ret = t[k]
    if not ret then 
        ret = {}
        t[k] = ret
    end
    return ret
end

TMW.COMMON.Auras = CreateFrame("Frame")
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
Auras:RegisterEvent("UNIT_AURA")
Auras:SetScript("OnEvent", function(_, _, unit, unitAuraUpdateInfo)
    local unitData = data[unit]
    if not unitData then
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
            getOrCreate(lookup, name)[auraInstanceID] = isMine
            getOrCreate(lookup, spellId)[auraInstanceID] = isMine
            if dispelType then
				if dispelType == "" then
                    -- Bugfix: Enraged is an empty string.
					dispelType = "Enraged"
				end
                payload[dispelType] = eventHasMine
                getOrCreate(lookup, dispelType)[auraInstanceID] = isMine
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
                    if dispelType == "" then
                        -- Bugfix: Enraged is an empty string.
                        dispelType = "Enraged"
                    end
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
                local nameLookup = lookup[name]
                if nameLookup then
                    nameLookup[auraInstanceID] = nil
                end

                payload[spellId] = eventHasMine
                local idLookup = lookup[spellId]
                if idLookup then
                    idLookup[auraInstanceID] = nil
                end

                if dispelType then
                    if dispelType == "" then
                        -- Bugfix: Enraged is an empty string.
                        dispelType = "Enraged"
                    end
                    local dsLookup = lookup[dispelType]
                    if dsLookup then
                        dsLookup[auraInstanceID] = nil
                    end
                    payload[dispelType] = eventHasMine
                end
                instances[auraInstanceID] = nil
            end
        end
    end

    FireUnitAura(unit, payload)
end)

local registeredUnitSets = {}

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
            local isMine = 
                instance.sourceUnit == "player" or
                instance.sourceUnit == "pet"

            instances[auraInstanceID] = instance
            getOrCreate(lookup, strlowerCache[instance.name])[auraInstanceID] = isMine
            getOrCreate(lookup, instance.spellId)[auraInstanceID] = isMine
            local dispelType = instance.dispelName
            if dispelType then
                if dispelType == "" then
                    -- Bugfix: Enraged is an empty string.
                    dispelType = "Enraged"
                end
                getOrCreate(lookup, dispelType)[auraInstanceID] = isMine
            end
        end
    end
end

--- It is assumed that the caller has previously called Auras:RequestUnit(unitSet) on a
--- unitSet that contained the provided unit, and that unitSet.allUnitsChangeOnEvent == true.
function Auras.GetAuras(unit)
    local unitData = data[unit]
    if not unitData then
        local instances = {}
        local lookup = {}
        unitData = {
            instances = instances,
            lookup = lookup
        }
        data[unit] = unitData

        --print("full updating unit", unit)
        UpdateAuras(unit, instances, lookup, GetAuraSlots(unit, "HELPFUL"))
        UpdateAuras(unit, instances, lookup, GetAuraSlots(unit, "HARMFUL"))
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

        local data = C_TooltipInfo[instance.isHelpful and "GetUnitBuffByAuraInstanceID" or "GetUnitDebuffByAuraInstanceID"](unit, instance.auraInstanceID)
        
        local line = data.lines[2]
        local text = line and line.leftText or ""
        return ParseTooltipText(text, instance)
    end

else
    local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
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