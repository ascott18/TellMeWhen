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
local strlowerCache = TMW.strlowerCache

local select, wipe, setmetatable 
    = select, wipe, setmetatable

local GetSpellName = TMW.GetSpellName

TMW.COMMON.SpellRange = CreateFrame("Frame")
local SpellRange = TMW.COMMON.SpellRange

if not C_ActionBar or not C_ActionBar.EnableActionRangeCheck then
    -- Older clients, Pre-11.0
    local IsSpellInRange = LibStub("SpellRange-1.0").IsSpellInRange
    function SpellRange.IsSpellInRange(spell, unit)
        local ret = IsSpellInRange(spell, unit)
        if ret == 1 then return true end
        if ret == 0 then return false end
        return ret
    end

    function SpellRange.HasRangeEvents(spell)
        return false
    end

    return
end

SpellRange.IsSpellInRange = C_Spell.IsSpellInRange

SpellRange:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
SpellRange:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")

local SpellsToActions = {}
SpellRange.SpellsToActions = SpellsToActions
local ActionToSpells = {}
SpellRange.ActionToSpells = ActionToSpells

local EnabledSpells = {}
local EnabledActions = {}

local CachedRange = {}
SpellRange.CachedRange = CachedRange

local IsSpellInRange = C_Spell.IsSpellInRange
function SpellRange.IsSpellInRange(spell, unit) 
    if unit and unit ~= "target" then
        return IsSpellInRange(spell, unit)
    end

    local actions = SpellsToActions[spell]
    if actions then
        for i = 1, #actions do
            local action = actions[i]
            local range = CachedRange[action]
            if range then
                if range[2] == false then
                    -- range[2] holds "checksRange", e.g. if range is currently relevant to the action.
                    -- It is false if you have no target, or hostile spells on friendly targets, etc.
                    return nil
                else
                    return range[1]
                end
            end
        end
        
        -- Cache miss, but the spell does map to an action, so populate the cache.
        -- This path happens if `CachedRange` has been wiped and we haven't yet seen an event.
        local inRange = IsSpellInRange(spell, unit)
        local action = actions[1]
        if inRange == nil then
            CachedRange[action] = { false, false }
        else
            CachedRange[action] = { inRange, true }
        end
        return inRange
    end
    
    -- Total cache miss, spell isn't on action bars
    return IsSpellInRange(spell, unit)
end


local function MapSpellToAction(identifier, action)
    local actions = SpellsToActions[identifier]
    if not actions then 
        SpellsToActions[identifier] = { action }
    elseif not TMW.tContains(actions, action) then
        actions[#actions+1] = action
    end
end

local function UpdateActionSlots() 
    wipe(SpellsToActions)
    wipe(ActionToSpells)
    wipe(CachedRange)

    -- 200 chosen arbitrarily.
    -- There's definitely more than 144 action slots.
    -- Ive seen actions as high as 180
    for action = 1, 200 do
        local actionType, id, subType = GetActionInfo(action);
        if actionType == "spell" or subType == "spell" then
            local overrideId = C_Spell.GetOverrideSpell(id);
            local baseId = FindBaseSpellByID(id);

            local normalName = strlowerCache[(GetSpellName(id))]
            local overrideName = strlowerCache[(GetSpellName(overrideId))]
            local baseName = strlowerCache[(GetSpellName(baseId))]

            MapSpellToAction(id, action)
            MapSpellToAction(normalName, action)
            MapSpellToAction(overrideId, action)
            MapSpellToAction(baseId, action)
            MapSpellToAction(normalName, action)
            MapSpellToAction(overrideName, action)
            MapSpellToAction(baseName, action)

            ActionToSpells[action] = {
                [id] = true,
                [overrideId] = true,
                [baseId] = true,
                [normalName] = true,
                [overrideName] = true,
                [baseName] = true,
            }

            -- If a spell we previously requested has moved to a new action,
            -- enable that new action.
            if not EnabledActions[action] then
                for spell in pairs(ActionToSpells[action]) do
                    if EnabledSpells[spell] then
                        EnabledActions[action] = true
                        C_ActionBar.EnableActionRangeCheck(action, true)
                    end
                end
            end
        end
    end
end

SpellRange:SetScript("OnEvent", function(self, event, action, inRange, checksRange)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        UpdateActionSlots()
    elseif event == "ACTION_RANGE_CHECK_UPDATE" then
        CachedRange[action] = { inRange, checksRange }
        TMW:Fire("TMW_SPELL_UPDATE_RANGE")
    end
end)

function SpellRange.HasRangeEvents(spell)
    EnabledSpells[spell] = true
    local actions = SpellsToActions[spell]
    if actions then
        for i = 1, #actions do
            local action = actions[i]
            
            if not EnabledActions[action] then
                EnabledActions[action] = true
                C_ActionBar.EnableActionRangeCheck(action, true)
            end
        end

        return true
    end
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", UpdateActionSlots)