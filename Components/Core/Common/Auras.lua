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
local issecretvalue = TMW.issecretvalue

local IsAuraFilteredOutByInstanceID = C_UnitAuras.IsAuraFilteredOutByInstanceID
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
local GetAuraSlots = C_UnitAuras.GetAuraSlots or UnitAuraSlots
local UnitGUID = UnitGUID

local GetSpellName = TMW.GetSpellName

TMW.COMMON.Auras = CreateFrame("Frame")
local Auras = TMW.COMMON.Auras

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

]]
local data = {}
local cdmData = { player = {}, target = {} }
Auras.data = data
Auras.cdmData = cdmData

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

function Auras.SpellHasCDMHook(spell)
    return false
end

local ApplyCDMData
local OnUnitAura
if TMW.clientHasSecrets then

    local blockedUnits = {}
    local ShouldAurasBeSecret = C_Secrets.ShouldAurasBeSecret
    local blocked = false

    TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", function()
        local newBlocked = ShouldAurasBeSecret()
        if blocked ~= newBlocked then
            blocked = newBlocked

            if blocked then
                for unit in pairs(data) do
                    blockedUnits[unit] = true
                    data[unit] = nil
                    FireUnitAura(unit)
                end
            else
                for unit in pairs(blockedUnits) do
                    data[unit] = nil
                    FireUnitAura(unit)
                end
                blockedUnits = {}
            end
        end
    end)

    ApplyCDMData = function(unit, auraInstance)
        if unit == "target" or unit == "player" then
            local data = cdmData[unit][auraInstance.auraInstanceID]
            if data 
                -- Don't apply to already non-secret auras
                and issecretvalue(auraInstance.expirationTime)
                -- Don't apply CDM data to other players' auras
                -- that happen to have reused an auraInstanceID
                -- that currently or previously belonged to one of our auras
                -- on a different unit, since auraInstanceIds are only unique per-unit.
                and not IsAuraFilteredOutByInstanceID(unit, auraInstance.auraInstanceID, data.filter)
            then
                -- print("Applying CDM data to", unit, data.spellId, data.name)
                auraInstance.spellId = data.spellId
                auraInstance.name = data.name
                auraInstance.sourceUnit = "player"
                auraInstance.isHelpful = unit == "player"
                auraInstance.isHarmful = unit == "target"
                -- just avoid ugly secret checks in buff.lua for stealable.
                -- if secret we would assume false anyway.
                auraInstance.isStealable = false
            end
        end
    end

    local hookedFrames = {}
    local function HookFrame(viewer, frame)
        if not frame.SetAuraInstanceInfo or hookedFrames[frame] then
            return
        end

        hookedFrames[frame] = true

        -- -- Add hooks for ShowPandemicStateFrame and HidePandemicStateFrame
        -- hooksecurefunc(frame, "ShowPandemicStateFrame", function(frame)
        --     local spellID = frame.cooldownInfo.spellID
        --     local auraInstanceID = frame.auraInstanceID
        --     print("Pandemic! at the disco", spellID, auraInstanceID)
        -- end)

        hooksecurefunc(frame, "SetAuraInstanceInfo", function(frame, cdmAuraInstance)
            local spellID = frame.cooldownInfo.spellID
            local auraInstanceID = cdmAuraInstance.auraInstanceID
            local unit = frame.auraDataUnit
            local unitData = cdmData[unit]

            local existing = unitData[auraInstanceID]
            if existing and existing.spellId == spellID then
                -- Already have up-to-date aura identity.
                return
            end
            
            -- Before collecting, we need to trigger a remove of the old aura with this instance ID
            -- because the reuse of instance IDs means the lookup tables might experience
            -- an aura seemingly changing its name/id, which will prevent old lookups
            -- from properly purging when the aura expires.
            OnUnitAura(unit, {
                isFullUpdate = false,
                removedAuraInstanceIDs = { auraInstanceID }
            })

            -- Always collect CDM data even if not blocked
            -- so that its ready to go if we become blocked.
            -- print("Collecting CDM data for", unit, spellID, GetSpellName(spellID))
            unitData[auraInstanceID] = {
                spellId = spellID,
                name = GetSpellName(spellID),
                filter = "PLAYER|" .. (unit == "player" and "HELPFUL" or "HARMFUL"),
            }
            
            -- Re-populate lookups with the new non-secret CDM data.
            OnUnitAura(unit, {
                isFullUpdate = false,
                addedAuras = { GetAuraDataByAuraInstanceID(unit, auraInstanceID) }
            })
        end)
    end

    local viewers = {
        EssentialCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer,
        UtilityCooldownViewer
    }
    -- Remove nil viewers
    for i = #viewers, 1, -1 do
        if not viewers[i] then
            table.remove(viewers, i)
        end
    end

    local function SpellHasCDMHook(spell)
        if not CVarCallbackRegistry:GetCVarValueBool("cooldownViewerEnabled") then
            -- Don't try to show frames if CDM is disabled.
            return false
        end

        -- If viewer hasn't shown yet, hooks might not be in place.
        -- Can't do this, it will taint
        -- for _, viewer in pairs(viewers) do
        --     local shown = viewer:IsShown()
        --     if not shown then
        --         viewer:Show()
        --         viewer:Hide()
        --     end
        -- end
        
        for frame in pairs(hookedFrames) do
            -- frame.cooldownID is a canary for whether the frame is active in its pool.
            -- It gets cleared when items are released from the pool.
            if frame.cooldownID and frame.cooldownInfo and (
                frame.cooldownInfo.spellID == spell or 
                GetSpellName(frame.cooldownInfo.spellID):lower() == tostring(spell):lower()
            ) then
                return true
            end
        end
        return false
    end

    function Auras.SpellHasCDMHook(spell)
        local _, result = TMW.safecall(SpellHasCDMHook, spell)
        return result
    end
    
    local function ApplyViewerOverride(viewer)
        local settingName = viewer.systemIndex
        local layoutName = EditModeManagerFrame:GetActiveLayoutInfo().layoutName
        if not TMW.db then return end

        -- DONT call UpdateSystemSettingShowTooltips, it will taint.
        viewer:UpdateSystemSettingOpacity()
        if EditModeManagerFrame:IsEditModeActive() then
            return
        end

        if TMW.db.global.EditModeLayouts[layoutName].CDMHide[settingName] then
            viewer:SetAlpha(0)
            -- DONT call SetTooltipsShown, it will taint.
            -- Instead, manually iterate and disable mouse motion so tooltips don't appears on invisible frames.
            for itemFrame in viewer.itemFramePool:EnumerateActive() do
                itemFrame:SetMouseMotionEnabled(false);
            end
        end
    end

    TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", function()
        for _, viewer in pairs(viewers) do
            TMW.safecall(ApplyViewerOverride, viewer)
        end
    end)

    -- Add an extra setting checkbox to edit mode on the CDM frames we want to be hidable.
    local check = CreateFrame("CheckButton", "TMWEditModeCDMHide", EditModeSystemSettingsDialog.Settings, "EditModeSettingCheckboxTemplate")
    check.Label:SetText("TMW: Always Hide")
    check.layoutIndex = 15
    TMW:TT(check, "UIPANEL_HIDE_CDM", "UIPANEL_HIDE_CDM_DESC")
    TMW:TT(check.Button, "UIPANEL_HIDE_CDM", "UIPANEL_HIDE_CDM_DESC")

    -- Add the checkbox to the edit mode dialog when appropriate
    hooksecurefunc(EditModeSystemSettingsDialog, "AttachToSystemFrame", function(self, systemFrame)
        if not tContains(viewers, systemFrame) then
            -- Not a CDM viewer
            check:Hide()
            self.Settings:Layout()
            self:Layout()
            return
        end

        local layoutName = EditModeManagerFrame:GetActiveLayoutInfo().layoutName
        local settingTable = TMW.db.global.EditModeLayouts[layoutName].CDMHide
        local settingName = systemFrame.systemIndex

        check:SetPoint("TOPLEFT")
        check:Show()
        check.Button:SetChecked(settingTable[settingName] or false)
        check.Button:SetScript("OnClick", function(btn)
            settingTable[settingName] = btn:GetChecked()

            ApplyViewerOverride(systemFrame)
        end)

        self.Settings:Layout()
        self:Layout()
    end)

    TMW.safecall(function()
        for _, viewer in pairs(viewers) do
            hooksecurefunc(viewer, "OnAcquireItemFrame", HookFrame)
            hooksecurefunc(viewer, "RefreshLayout", ApplyViewerOverride)

            for _, frame in TMW:Vararg(viewer:GetChildren()) do
                HookFrame(viewer, frame)
            end
        end
    end)
end

OnUnitAura = function(unit, unitAuraUpdateInfo)
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

            if ApplyCDMData then
                ApplyCDMData(unit, instance)
            end

            if not issecretvalue(instance.name) then
                local name = strlowerCache[instance.name]
                local spellId = instance.spellId
                local isMine = 
                    instance.sourceUnit == "player" or
                    instance.sourceUnit == "pet"
                eventHasMine = eventHasMine or isMine
                
                --print("added", unit, name, auraInstanceID)

                payload[name] = eventHasMine
                payload[spellId] = eventHasMine
                lookup[name][auraInstanceID] = isMine
                lookup[spellId][auraInstanceID] = isMine

                local dispelType = instance.dispelName
                if dispelType and not issecretvalue(dispelType) then
                    if dispelType == "" then
                        -- Bugfix: Enraged is an empty string.
                        dispelType = "Enraged"
                    end
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

                if ApplyCDMData then
                    ApplyCDMData(unit, instance)
                end

                if not issecretvalue(instance.name) then
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
                    if dispelType and not issecretvalue(dispelType) then
                        if dispelType == "" then
                            -- Bugfix: Enraged is an empty string.
                            dispelType = "Enraged"
                        end
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
                    local isMine = 
                        instance.sourceUnit == "player" or
                        instance.sourceUnit == "pet"
                    eventHasMine = eventHasMine or isMine
                        
                    --print("remove", unit, name, auraInstanceID)

                    payload[name] = eventHasMine
                    lookup[name][auraInstanceID] = nil

                    payload[spellId] = eventHasMine
                    lookup[spellId][auraInstanceID] = nil

                    if dispelType and not issecretvalue(dispelType) then
                        if dispelType == "" then
                            -- Bugfix: Enraged is an empty string.
                            dispelType = "Enraged"
                        end
                        lookup[dispelType][auraInstanceID] = nil
                        payload[dispelType] = eventHasMine
                    end
                end
                instances[auraInstanceID] = nil
                if cdmData and cdmData[unit] then
                    cdmData[unit][auraInstanceID] = nil
                end
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
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- We cannot clear CDM data on target change because
        -- https://github.com/Stanzilla/WoWUIBugs/issues/815
        -- causes an unpleasant user experience if you switch targets
        -- back and forth quickly.
        -- wipe(cdmData.target)
    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(data)
        wipe(cdmData.player)
        wipe(cdmData.target)
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

        if not unitSet.allUnitsChangeOnEvent then
            needsAllUnits = true
        elseif not needsAllUnits then
            for i = 1, #unitSet.originalUnits do
                local unit = unitSet.originalUnits[i]
                if not TMW.tContains(registeredUnits, unit) then
                    tinsert(registeredUnits, unit)
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

            if ApplyCDMData then
                ApplyCDMData(unit, instance)
            end

            instances[auraInstanceID] = instance
            if not issecretvalue(instance.name) then
                local isMine = 
                instance.sourceUnit == "player" or
                instance.sourceUnit == "pet"
                
                lookup[strlowerCache[instance.name]][auraInstanceID] = isMine
                lookup[instance.spellId][auraInstanceID] = isMine
                local dispelType = instance.dispelName
                if dispelType and not issecretvalue(dispelType) then
                    if dispelType == "" then
                        -- Bugfix: Enraged is an empty string.
                        dispelType = "Enraged"
                    end
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
        local instances = {}
        local lookup = setmetatable({}, lookupMeta)
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

        if issecretvalue(instance.spellId) then
            instance.tmwTooltipNumbers = {}
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