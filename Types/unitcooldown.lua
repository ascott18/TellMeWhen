-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, pr, ab, rc, mc
local strlower, type =
	  strlower, type
local UnitGUID, UnitExists, GetSpellTexture =
	  UnitGUID, UnitExists, GetSpellTexture
local print = TMW.print

local clientVersion = select(4, GetBuildInfo())

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	CooldownShowWhen = true,
	ICDDuration = true,
	Unit = true,
	OnlySeen = true,
	Alpha = true,
	UnAlpha = true,
	ShowCBar = true,
	InvertBars = true,
	CBarOffs = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("unitcooldown", RelevantSettings)
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_UNITCOOLDOWN"]
Type.desc = format(L["ICONMENU_UNITCOOLDOWN_DESC"], GetSpellInfo(42292))


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end

local Cooldowns = setmetatable({}, {__index = function(t, k)
	local n = {}
	t[k] = n
	return n
end}) TMW.Cooldowns = Cooldowns

local SpellTextures = setmetatable({}, {__index = function(t, name)
	local tex = GetSpellTexture(name)
	t[name] = tex
	return tex
end})

if clientVersion >= 40100 then -- COMBAT_LOG_EVENT_UNFILTERED
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, g, _, _, _, _, _, i, n)-- tyPe, sourceGuid, spellId, spellName -- NEW ARG IN 4.1 BETWEEN TYPE AND SOURCEGUID
		if p == "SPELL_CAST_SUCCESS" then
			local c = Cooldowns[g]
			c[strlower(n)] = i
			c[i] = TMW.time
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = TMW.time
			local c = Cooldowns[g]
			local ci = c[i]
			if (ci and ci + 1.8 < t) or not ci then 	-- if this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS or a UNIT_SPELLCAST_SUCCEEDED then ignore it (this is just a safety window for spell travel time so that if we found the real cast start, we dont overwrite it)
				c[strlower(n)] = i
				c[i] = t-1			-- hack it to make it a little bit more accurate. a max range dk deathcoil has a travel time of about 1.3 seconds, so 1 second should be a good average to be safe with travel times.
			end						-- (and really, how often are people actually going to be tracking cooldowns with cast times? there arent that many, and the ones that do exist arent that important)
		end
	end
else
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, g, _, _, _, _, _, i, n)-- tyPe, Guid, spellId, spellName
		if p == "SPELL_CAST_SUCCESS" then
			local c = Cooldowns[g]
			c[strlower(n)] = i
			c[i] = TMW.time
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = TMW.time
			local c = Cooldowns[g]
			local ci = c[i]
			if (ci and ci + 1.8 < t) or not ci then 	-- if this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS or a UNIT_SPELLCAST_SUCCEEDED then ignore it (this is just a safety window for spell travel time so that if we found the real cast start, we dont overwrite it)
				c[strlower(n)] = i
				c[i] = t-1			-- hack it to make it a little bit more accurate. a max range dk deathcoil has a travel time of about 1.3 seconds, so 1 second should be a good average to be safe with travel times.
			end						-- (and really, how often are people actually going to be tracking cooldowns with cast times? there arent that many, and the ones that do exist arent that important)
		end
	end
end

function Type:UNIT_SPELLCAST_SUCCEEDED(e, u, n, _, _, i)--Unit, spellName, spellId
	local c = Cooldowns[UnitGUID(u)]
	c[strlower(n)] = i
	c[i] = TMW.time
end

local function UnitCooldown_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local unstart, unname
		local Alpha, ICDDuration, Units, NameArray, OnlySeen = icon.Alpha, icon.ICDDuration, icon.Units, icon.NameArray, icon.OnlySeen
		local NAL = #NameArray

		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				local cooldowns = Cooldowns[UnitGUID(unit)]
				for i = 1, NAL do
					local iName = NameArray[i]
					if type(iName) == "string" then
						iName = cooldowns[strlower(iName)] or iName-- spell name keys have values that are the spellid of the name, we need the spellid for the texture (thats why i did it like this)
					end

					local start
					if OnlySeen then
						start = cooldowns[iName]
					else
						start = cooldowns[iName] or 0
					end
					if start then
						if (time - start) > ICDDuration then -- off cooldown

							local t = SpellTextures[iName] or "Interface\\Icons\\INV_Misc_PocketWatch_01"

							icon:SetInfo(Alpha, 1, t, 0, 0)

							if Alpha ~= 0 then -- we care about usable cooldowns and we found one, so stop
								return
							end
						elseif not unstart then -- if we havent figured out a spell that IS on cooldown yet, then set one. that way we dont have to iterate over units and spells again if nothing is OFF cooldown
							unstart, unname = start, iName
							if Alpha == 0 then break end -- we found something on cooldown and we dont care about things that are on cooldown (break name loop)
						end
					end
				end
				if Alpha == 0 and unstart then break end -- we found something on cooldown and we dont care about things that are on cooldown (break unit loop)
			end
		end

		local UnAlpha = icon.UnAlpha
		if UnAlpha ~= 0 and unstart then
			icon:SetInfo(UnAlpha, (not icon.ShowTimer and Alpha ~= 0) and .5 or 1, SpellTextures[unname], unstart, ICDDuration)
			return
		end
		icon:SetAlpha(0)
	end
end

function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", UnitCooldown_OnUpdate)
	icon:OnUpdate(TMW.time)
end
