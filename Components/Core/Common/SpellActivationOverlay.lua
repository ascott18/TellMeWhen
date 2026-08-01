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

local ipairs, pairs, tonumber
    = ipairs, pairs, tonumber

local GetSpellName = TMW.GetSpellName
local IsSpellOverlayed = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed or _G.IsSpellOverlayed

TMW.COMMON.SpellActivationOverlay = CreateFrame("Frame")
local SpellActivationOverlay = TMW.COMMON.SpellActivationOverlay

-- Spell IDs that the game has told us are currently overlayed.
local OverlayedIds = {}
SpellActivationOverlay.OverlayedIds = OverlayedIds

-- Lowered names of the spells in OverlayedIds, mapped to the number of overlayed
-- IDs sharing that name. Blizzard will glow several IDs at once for some abilities,
-- so this can't be a plain boolean.
local OverlayedNames = {}
SpellActivationOverlay.OverlayedNames = OverlayedNames


--- Returns true if the game is currently drawing a spell activation overlay
-- (the sparkly border on the default action bars) for the given spell.
-- @param spell [number|string] A spell ID, or a spell name that has been lowercased
-- (as everything from TMW.C.SpellSet's non-"NoLower" members has been).
function SpellActivationOverlay.IsOverlayed(spell)
	if OverlayedIds[spell] or OverlayedNames[spell] then
		return true
	end

	-- The events only report changes, so an overlay that was already up before we
	-- started listening (a /reload mid-proc, usually) is only visible through the
	-- API, which needs a real spell ID.
	if IsSpellOverlayed and tonumber(spell) then
		return not not IsSpellOverlayed(spell)
	end

	return false
end

--- Returns true if any spell in a TMW.C.SpellSet currently has a spell activation overlay.
-- @param spells [TMW.C.SpellSet] A spell set as obtained from TMW:GetSpells().
function SpellActivationOverlay.IsAnyOverlayed(spells)
	-- The ID reported by the game is very often an override of the one that the user
	-- entered, so names have to be matched in addition to IDs.
	local StringHash = spells.StringHash
	for name in pairs(OverlayedNames) do
		if StringHash[name] then
			return true
		end
	end

	local Hash = spells.Hash
	for id in pairs(OverlayedIds) do
		if Hash[id] then
			return true
		end
	end

	if IsSpellOverlayed then
		for _, spell in ipairs(spells.Array) do
			if tonumber(spell) and IsSpellOverlayed(spell) then
				return true
			end
		end
	end

	return false
end


SpellActivationOverlay:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
SpellActivationOverlay:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
SpellActivationOverlay:SetScript("OnEvent", function(self, event, spellId)
	if not spellId then return end

	local shown = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"
	if (not not OverlayedIds[spellId]) == shown then
		return
	end
	OverlayedIds[spellId] = shown or nil

	local name = strlowerCache[GetSpellName(spellId)]
	if name then
		local count = (OverlayedNames[name] or 0) + (shown and 1 or -1)
		OverlayedNames[name] = count > 0 and count or nil
	end

	TMW:Fire("TMW_SPELL_UPDATE_OVERLAY", spellId, name, shown)
end)
