 -- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

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

local C_Timer, CombatLogGetCurrentEventInfo
    = C_Timer, CombatLogGetCurrentEventInfo

local Slots = {}
function TMW.GetTotemInfo(slot) 
    local info = Slots[slot]
    if not info then return false end
    local start, duration = info.start, info.duration

    if start + duration < TMW.time then
        return false
    end

    return true, info.name, start, duration, info.texture
end

local _, pClass = UnitClass("Player")

if pClass ~= "SHAMAN" then
    return
end

local FIRE = 1
local WATER = 2
local EARTH = 3
local AIR = 4

local totemsById = {
    [ 8143] = { texture = 136108, slot = EARTH, duration = 120 }, -- Tremor
    [ 8166] = { texture = 136070, slot = WATER, duration = 120 }, -- Poison Cleansing
    [ 8170] = { texture = 136019, slot = WATER, duration = 120 }, -- Disease Cleansing
    [ 8177] = { texture = 136039, slot = AIR ,  duration = 45 },  -- Grounding
    [10408] = { texture = 136098, slot = EARTH, duration = 120 }, -- Stoneskin
    [10428] = { texture = 136097, slot = EARTH, duration = 15 },  -- Stoneclaw
    [10438] = { texture = 135825, slot = FIRE,  duration = 55 },  -- Searing
    [10463] = { texture = 135127, slot = WATER, duration = 60 },  -- Healing Stream
    [10479] = { texture = 135866, slot = FIRE,  duration = 120 }, -- Frost Resistance
    [10497] = { texture = 136053, slot = WATER, duration = 60 },  -- Mana Spring
    [10538] = { texture = 135832, slot = FIRE,  duration = 120 }, -- Fire Resistance
    [10587] = { texture = 135826, slot = FIRE,  duration = 20 },  -- Magma
    [10601] = { texture = 136061, slot = AIR,   duration = 120 }, -- Nature Resistance
    [10614] = { texture = 136114, slot = AIR,   duration = 120 }, -- Windfury
    [11315] = { texture = 135824, slot = FIRE,  duration = 4 },   -- Fire Nova
    [15112] = { texture = 136022, slot = AIR,   duration = 120 }, -- Windwall
    [16387] = { texture = 136040, slot = FIRE,  duration = 120 }, -- Flametongue
    [17359] = { texture = 135861, slot = WATER, duration = 12 },  -- Mana Tide
    [25359] = { texture = 136046, slot = AIR,   duration = 120 }, -- Grace of Air
    [25361] = { texture = 136023, slot = EARTH, duration = 120 }, -- Strength of Earth
    [25908] = { texture = 136013, slot = AIR,   duration = 120 }, -- Tranquil Air
}
local totemsByName = {}
for id, info in pairs(totemsById) do
    local name = GetSpellInfo(id)
    info.name = name
    totemsByName[name] = info
end

local _, pGUID
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
    pGUID = UnitGUID("player")
end)

local function fireEvent()
    TMW:Fire("TMW_TOTEM_UPDATE")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, destName, _, _, _, spellName
            = CombatLogGetCurrentEventInfo()
            
        if sourceGUID == pGUID and cleuEvent == "SPELL_SUMMON" and spellName then
            local info = totemsByName[spellName]
            if cleuEvent == "SPELL_SUMMON" then
                Slots[info.slot] = {
                    name = info.name,
                    start = TMW.time,
                    duration = info.duration,
                    texture = info.texture
                }

                TMW:Fire("TMW_TOTEM_UPDATE")
                -- A bit lazy, but its simple and it works.
                C_Timer.After(info.duration + 0.1, fireEvent)
            end
        end
    end
end)