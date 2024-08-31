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

TMW.COMMON.Cooldowns = CreateFrame("Frame")
local Cooldowns = TMW.COMMON.Cooldowns

local emptyCooldown = {}
local CachedCooldowns = {}
local CachedCharges = {}

if C_Spell.GetSpellCooldown then
	local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown

    function Cooldowns.GetSpellCooldown(spell)
        local cached = CachedCooldowns[spell]
        if cached then
            if cached == false then return end
            local duration = cached.duration
            if duration ~= 0 and (duration - (TMW.time - cached.startTime)) <= 0 then
                -- Cooldown has elapsed. Discard this cache entry
            else
                return cached
            end
        end
        
        cached = C_Spell_GetSpellCooldown(spell) or false
        CachedCooldowns[spell] = cached
        return cached
    end
else
    local GetSpellCooldown = _G.GetSpellCooldown

    function Cooldowns.GetSpellCooldown(spell)
        local cached = CachedCooldowns[spell]
        if cached then
            if cached == false then return end
            local duration = cached.duration
            if duration ~= 0 and (duration - (TMW.time - cached.startTime)) <= 0 then
                -- Cooldown has elapsed. Discard this cache entry
            else
                return cached
            end
        end
        
        local startTime, duration, isEnabled, modRate = GetSpellCooldown(spell)
        cached = startTime and {
            startTime = startTime,
            duration = duration,
            isEnabled = isEnabled,
            modRate = modRate,
        } or false
        CachedCooldowns[spell] = cached
        return cached
    end
end

if C_Spell.GetSpellCharges then
	local C_Spell_GetSpellCharges = C_Spell.GetSpellCharges

    function Cooldowns.GetSpellCharges(spell)
        local cached = CachedCharges[spell]
        if cached then return cached ~= false and cached or nil end
        
        cached = C_Spell_GetSpellCharges(spell) or false
        CachedCharges[spell] = cached
        return cached
    end
else
    local GetSpellCharges = _G.GetSpellCharges

    function Cooldowns.GetSpellCharges(spell)
        local cached = CachedCharges[spell]
        if cached then return cached ~= false and cached or nil end
        
        local currentCharges, maxCharges, cooldownStartTime, cooldownDuration = GetSpellCharges(spell)
        cached = startTime and {
            currentCharges = currentCharges,
            maxCharges = maxCharges,
            cooldownStartTime = cooldownStartTime,
            cooldownDuration = cooldownDuration,
        } or false
        CachedCharges[spell] = cached
        return cached
    end
end

Cooldowns:RegisterEvent("SPELLS_CHANGED")
Cooldowns:RegisterEvent("SPELL_UPDATE_COOLDOWN")
Cooldowns:RegisterEvent("SPELL_UPDATE_CHARGES")
Cooldowns:SetScript("OnEvent", function(self, event, action, inRange, checksRange)
    if event == "SPELL_UPDATE_COOLDOWN" then
        wipe(CachedCooldowns)
        TMW:Fire("TMW_SPELL_UPDATE_COOLDOWN")

    elseif event == "SPELL_UPDATE_CHARGES" then
        wipe(CachedCharges)
        TMW:Fire("TMW_SPELL_UPDATE_CHARGES")

    elseif event == "SPELLS_CHANGED" then
        -- Spells may have been learned/unlearned (e.g. pvp talents activating/deactivating)
        wipe(CachedCooldowns)
        wipe(CachedCharges)
        TMW:Fire("TMW_SPELL_UPDATE_COOLDOWN")
        TMW:Fire("TMW_SPELL_UPDATE_CHARGES")
    end
end)