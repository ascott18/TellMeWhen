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
local IsUsableSpell = C_Spell.IsSpellUsable or _G.IsUsableSpell
local IsUsableAction = IsUsableAction

TMW.COMMON.SpellUsable = CreateFrame("Frame")
local SpellUsable = TMW.COMMON.SpellUsable
local Actions = TMW.COMMON.Actions

-- todo: can we feature detect hasPreciseActionEvents?
local hasPreciseActionEvents = select(4, GetBuildInfo()) >= 110000

if hasPreciseActionEvents then
    SpellUsable:RegisterEvent("ACTION_USABLE_CHANGED")
else
    SpellUsable:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
end
SpellUsable:RegisterEvent("SPELLS_CHANGED")
SpellUsable:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
SpellUsable:RegisterEvent("SPELL_UPDATE_USABLE")

local SpellsToActions = Actions.SpellsToActions
local ActionToSpells = Actions.ActionToSpells
local EnabledSpells = {}
local EnabledActions = {}

local CachedActions = {}
SpellUsable.CachedActions = CachedActions
local CachedNonActions = {}
SpellUsable.CachedNonActions = CachedNonActions

function SpellUsable.IsUsableSpell(spell)

    local actions = SpellsToActions[spell]
    if actions then
        -- If the spell is an action, use actionbar data.
        -- On clients with ACTION_USABLE_CHANGED, we can get precise, surgical events for actions,
        -- and even on clients without ACTION_USABLE_CHANGED, ACTIONBAR_UPDATE_USABLE is
        -- more well-behaved than SPELL_UPDATE_USABLE, firing far fewer superfluous updates.
        for i = 1, #actions do
            local action = actions[i]
            local usable = CachedActions[action]
            if usable then
                return usable.usable, usable.noMana
            end
        end
        
        -- Cache miss, but the spell does map to an action, so populate the cache.
        -- This path happens if `CachedRange` has been wiped and we haven't yet seen an event.
        local action = actions[1]
        local usable, noMana = IsUsableAction(action)
        CachedActions[action] = { usable = usable, noMana = noMana }
        return usable, noMana
    else
        -- Spell is not a known actionbar action. Have to use the plain spell APIs.
        local usable = CachedNonActions[spell]
        if usable then
            return usable.usable, usable.noMana
        end
        
        local usable, noMana = IsUsableSpell(spell)
        CachedNonActions[spell] = { usable = usable, noMana = noMana }
        return usable, noMana
    end
end

SpellUsable:SetScript("OnEvent", function(self, event, payload)
    -- Lookup table of all the spells that were changed 
    -- that is sent as the payload of TMW_SPELL_UPDATE_USABLE.
    local spells = {}

    if event == "SPELLS_CHANGED" then
        -- SPELLS_CHANGED covers occurrences like pvp talents becoming available/unavailable
        -- when pvp combat is engaged/disengaged.
        -- It effects both actionbar and non-actionbar spells.
        -- Since its fairly infrequent, just easier to wipe all caches.

        wipe(CachedActions)
        wipe(CachedNonActions)
        TMW:Fire("TMW_SPELL_UPDATE_USABLE")
        return

    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        -- When actions are dragged around the actionbar,
        -- or when a spell becomes a different spell in combat (e.g. void eruption/void bolt),
        -- or also just regular power updates for some arbitrary abilities (Soul cleave, shield of the righteous, arcane shot, to name a few).
        local action = payload
        local data = CachedActions[action]
        
        if not data then 
            -- Nobody was listening to this action if it isn't cached,
            -- so we don't care that it just changed.
            return
        end

        local usable, noMana = IsUsableAction(action)
        if data.usable ~= usable or data.noMana ~= noMana then
            data.usable = usable
            data.noMana = noMana

            local actionSpells = ActionToSpells[action]
            if actionSpells then
                for spell in pairs(actionSpells) do
                    spells[spell] = true
                end
            end
        end

    elseif event == "ACTION_USABLE_CHANGED" then
        -- Precise action updates. Added in WoW 11.0.
        for _, payloadSpell in pairs(payload) do
            -- payloadSpell is { usable: boolean, noMana: boolean }
            local action = payloadSpell.slot
            CachedActions[action] = payloadSpell
            
            local actionSpells = ActionToSpells[action]
            if actionSpells then
                for spell in pairs(actionSpells) do
                    spells[spell] = true
                end
            end
        end

    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        -- Imprecise action updates. Some action changed, but we don't know what.
        -- NOTE: this event is only registered if ACTION_USABLE_CHANGED isn't available.
        for action, data in pairs(CachedActions) do
            local usable, noMana = IsUsableAction(action)
            if data.usable ~= usable or data.noMana ~= noMana then
                data.usable = usable
                data.noMana = noMana

                local actionSpells = ActionToSpells[action]
                if actionSpells then
                    for spell in pairs(actionSpells) do
                        spells[spell] = true
                    end
                end
            end
        end

    elseif event == "SPELL_UPDATE_USABLE" then
        -- Some spell might have changed, but we don't know which.
        -- Check all the ones that have been asked for to see which spells (if any) it was.
        for spell, data in pairs(CachedNonActions) do
            local usable, noMana = IsUsableSpell(spell)
            if data.usable ~= usable or data.noMana ~= noMana then
                data.usable = usable
                data.noMana = noMana

                spells[spell] = true
            end
        end
        -- todo: do we still have to listen to UNIT_POWER_FREQUENT?
        -- In all my testing, it doesn't seem so - SPELL_UPDATE_USABLE is sufficient for all spells.
    end

    if next(spells) then
        TMW:Fire("TMW_SPELL_UPDATE_USABLE", spells)
    end
end)

-- Legacy backwards-compat for anything that might be using this
function TMW.SpellHasNoMana(spell)
	local _, noMana = SpellUsable.IsUsableSpell(spell)
	return noMana
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
    wipe(CachedActions)
    wipe(CachedNonActions)
end)