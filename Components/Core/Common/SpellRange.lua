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

local select, wipe, setmetatable 
    = select, wipe, setmetatable

local GetSpellName = TMW.GetSpellName

TMW.COMMON.SpellRange = CreateFrame("Frame")
local SpellRange = TMW.COMMON.SpellRange
local Actions = TMW.COMMON.Actions

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

SpellRange:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")

local SpellsToActions = Actions.SpellsToActions
local ActionToSpells = Actions.ActionToSpells
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

TMW:RegisterCallback("TMW_ACTIONS_UPDATED", function()
    wipe(CachedRange)

    for action, spells in pairs(ActionToSpells) do
        -- If a spell we previously requested has moved to a new action,
        -- enable that new action.
        if not EnabledActions[action] then
            for spell in pairs(spells) do
                if EnabledSpells[spell] then
                    EnabledActions[action] = true
                    C_ActionBar.EnableActionRangeCheck(action, true)
                end
            end
        end
    end

    TMW:Fire("TMW_SPELL_UPDATE_RANGE")
end)

SpellRange:SetScript("OnEvent", function(self, event, action, inRange, checksRange)
    if event == "ACTION_RANGE_CHECK_UPDATE" then
        CachedRange[action] = { inRange, checksRange }
        -- We don't bother with a payload for this event because range check updates
        -- are quite uncommon in combat, so it just isn't worth it.
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