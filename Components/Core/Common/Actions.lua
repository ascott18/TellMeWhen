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

TMW.COMMON.Actions = CreateFrame("Frame")
local Actions = TMW.COMMON.Actions

Actions:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

local SpellsToActions = {}
Actions.SpellsToActions = SpellsToActions
local ActionToSpells = {}
Actions.ActionToSpells = ActionToSpells

function Actions.GetActionsForSpell(spell)
    return SpellsToActions[spell]
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

    -- 200 chosen arbitrarily.
    -- There's definitely more than 144 action slots.
    -- Ive seen actions as high as 180
    for action = 1, 200 do
        local actionType, id, subType = GetActionInfo(action);
        if actionType == "spell" and id and id ~= 0 then
            -- Don't allow for `or subType == "spell" ` for now.
            -- This allows macros to be registered as the provider for a spell,
            -- but I can just imagine people with weird @focus macros
            -- wondering why their icon doesn't update sometimes.

            MapSpellToAction(id, action)
            local spells = {
                [id] = true,
            }

            local normalName = strlowerCache[GetSpellName(id)]
            if normalName then
                spells[normalName] = true
                MapSpellToAction(normalName, action)
            end

            -- https://github.com/ascott18/TellMeWhen/issues/2198
            -- Sometimes, FindBaseSpellByID can return `nil`.
            local baseId = FindBaseSpellByID(id);
            if baseId then
                spells[baseId] = true
                MapSpellToAction(baseId, action)
                if baseName then
                    local baseName = strlowerCache[GetSpellName(baseId)]
                    MapSpellToAction(baseName, action)
                end
            end

            if C_Spell.GetOverrideSpell then
                
                local overrideId = C_Spell.GetOverrideSpell(id);
                if overrideId then
                    MapSpellToAction(overrideId, action)
                    spells[overrideId] = true

                    -- overrideName being nil was the root cause of https://github.com/ascott18/TellMeWhen/issues/2208
                    local overrideName = strlowerCache[GetSpellName(overrideId)]
                    if overrideName then
                        MapSpellToAction(overrideName, action)
                        spells[overrideName] = true
                    end
                end
            end

            ActionToSpells[action] = spells
        end
    end

    TMW:Fire("TMW_ACTIONS_UPDATED")
end

Actions:SetScript("OnEvent", function(self, event, action, inRange, checksRange)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        UpdateActionSlots()
    end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", UpdateActionSlots)