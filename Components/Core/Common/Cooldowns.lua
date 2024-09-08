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

local select, wipe, next, setmetatable 
    = select, wipe, next, setmetatable

TMW.COMMON.Cooldowns = CreateFrame("Frame")
local Cooldowns = TMW.COMMON.Cooldowns

local emptyCooldown = {}
local CachedCooldowns = {}
local CachedCharges = {}
local CachedCounts = {}

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
            chargeModRate = 1
        } or false
        CachedCharges[spell] = cached
        return cached
    end
end




if C_Spell.GetSpellCastCount then
	local C_Spell_GetSpellCastCount = C_Spell.GetSpellCastCount

    function Cooldowns.GetSpellCastCount(spell)
        local cached = CachedCounts[spell]
        if cached then return cached ~= false and cached or nil end

        cached = C_Spell_GetSpellCastCount(spell) or false
        CachedCounts[spell] = cached
        return cached
    end
else
    local GetSpellCount = _G.GetSpellCount

    function Cooldowns.GetSpellCastCount(spell)
        local cached = CachedCounts[spell]
        if cached then return cached ~= false and cached or nil end
        
        local count = GetSpellCount(spell)
        cached = count or false
        CachedCounts[spell] = cached
        return cached
    end
end



---------------------------------
-- Global Cooldown Data
---------------------------------

-- Rogue's Backstab. We don't need class spells anymore - any GCD spell works fine.
local GCDSpell = 53
TMW.GCDSpell = GCDSpell
local Cooldowns_GetSpellCooldown = Cooldowns.GetSpellCooldown
function TMW.GetGCD()
	return Cooldowns_GetSpellCooldown(GCDSpell).duration
end
local GetGCD = TMW.GetGCD

function TMW.OnGCD(d)
	if d <= 0.1 then
		-- A cd of 0.001 is Blizzard's terrible way of indicating that something's cooldown hasn't started,
		-- but is still unusable, and has a cooldown pending. It should not be considered a GCD.
		-- In general, anything less than 0.1 isn't a GCD.
		return false
	elseif d <= 1 then
		-- A cd of 1 (or less) is always a GCD (or at least isn't worth showing)
		return true
	else
		-- If the duration passed in is the same as the GCD spell then it is a GCD
		return GetGCD() == d
	end
end

Cooldowns:RegisterEvent("SPELLS_CHANGED")
Cooldowns:RegisterEvent("SPELL_UPDATE_COOLDOWN")
Cooldowns:RegisterEvent("SPELL_UPDATE_CHARGES")
Cooldowns:SetScript("OnEvent", function(self, event, action, inRange, checksRange)
    if event == "SPELL_UPDATE_COOLDOWN" then
        wipe(CachedCooldowns)

        if next(CachedCounts) then
            -- There's not a great event for GetSpellCastCount. Cooldown is the closest we can get.
            wipe(CachedCounts)
            TMW:Fire("TMW_SPELL_UPDATE_COUNT")
        end

        TMW:Fire("TMW_SPELL_UPDATE_COOLDOWN")

    elseif event == "SPELL_UPDATE_CHARGES" then
        wipe(CachedCharges)
        TMW:Fire("TMW_SPELL_UPDATE_CHARGES")

    elseif event == "SPELLS_CHANGED" then
        -- Spells may have been learned/unlearned (e.g. pvp talents activating/deactivating)
        wipe(CachedCooldowns)
        wipe(CachedCharges)
        wipe(CachedCounts)
        TMW:Fire("TMW_SPELL_UPDATE_COOLDOWN")
        TMW:Fire("TMW_SPELL_UPDATE_CHARGES")
        TMW:Fire("TMW_SPELL_UPDATE_COUNT")
    end
end)