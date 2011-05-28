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
local huge = math.huge
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures

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
	ConditionAlpha = true,
	FakeHidden = true,
	Sort = true,
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

if clientVersion >= 40200 then -- COMBAT_LOG_EVENT_UNFILTERED
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, g, _, _, _, _, _, _, _, i, n)-- tyPe, sourceGuid, spellId, spellName -- 2 NEW ARGS IN 4.2
		if p == "SPELL_CAST_SUCCESS" then
			local c = Cooldowns[g]
			c[strlowerCache[n]] = i
			c[i] = TMW.time
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = TMW.time
			local c = Cooldowns[g]
			local ci = c[i]
			if (ci and ci + 1.8 < t) or not ci then 	-- if this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS or a UNIT_SPELLCAST_SUCCEEDED then ignore it (this is just a safety window for spell travel time so that if we found the real cast start, we dont overwrite it)
				c[strlowerCache[n]] = i
				c[i] = t-1			-- hack it to make it a little bit more accurate. a max range dk deathcoil has a travel time of about 1.3 seconds, so 1 second should be a good average to be safe with travel times.
			end						-- (and really, how often are people actually going to be tracking cooldowns with cast times? there arent that many, and the ones that do exist arent that important)
		end
	end
elseif clientVersion >= 40100 then
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, g, _, _, _, _, _, i, n)-- tyPe, sourceGuid, spellId, spellName -- NEW ARG IN 4.1 BETWEEN TYPE AND SOURCEGUID
		if p == "SPELL_CAST_SUCCESS" then
			local c = Cooldowns[g]
			c[strlowerCache[n]] = i
			c[i] = TMW.time
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = TMW.time
			local c = Cooldowns[g]
			local ci = c[i]
			if (ci and ci + 1.8 < t) or not ci then 	-- if this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS or a UNIT_SPELLCAST_SUCCEEDED then ignore it (this is just a safety window for spell travel time so that if we found the real cast start, we dont overwrite it)
				c[strlowerCache[n]] = i
				c[i] = t-1			-- hack it to make it a little bit more accurate. a max range dk deathcoil has a travel time of about 1.3 seconds, so 1 second should be a good average to be safe with travel times.
			end						-- (and really, how often are people actually going to be tracking cooldowns with cast times? there arent that many, and the ones that do exist arent that important)
		end
	end
else
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, g, _, _, _, _, _, i, n)-- tyPe, Guid, spellId, spellName
		if p == "SPELL_CAST_SUCCESS" then
			local c = Cooldowns[g]
			c[strlowerCache[n]] = i
			c[i] = TMW.time
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = TMW.time
			local c = Cooldowns[g]
			local ci = c[i]
			if (ci and ci + 1.8 < t) or not ci then 	-- if this event was less than 1.8 seconds after a SPELL_CAST_SUCCESS or a UNIT_SPELLCAST_SUCCEEDED then ignore it (this is just a safety window for spell travel time so that if we found the real cast start, we dont overwrite it)
				c[strlowerCache[n]] = i
				c[i] = t-1			-- hack it to make it a little bit more accurate. a max range dk deathcoil has a travel time of about 1.3 seconds, so 1 second should be a good average to be safe with travel times.
			end						-- (and really, how often are people actually going to be tracking cooldowns with cast times? there arent that many, and the ones that do exist arent that important)
		end
	end
end

function Type:UNIT_SPELLCAST_SUCCEEDED(e, u, n, _, _, i)--Unit, spellName, spellId
	local c = Cooldowns[UnitGUID(u)]
	c[strlowerCache[n]] = i
	c[i] = TMW.time
end


					
					
local function UnitCooldown_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local unstart, unname, usename
		local Alpha, ICDDuration, Units, NameArray, OnlySeen, Sort = icon.Alpha, icon.ICDDuration, icon.Units, icon.NameArray, icon.OnlySeen, icon.Sort
		local NAL = #NameArray
		local d = Sort == -1 and huge or 0
		local UnAlpha = icon.UnAlpha
		local dobreak
		
		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				local cooldowns = Cooldowns[UnitGUID(unit)]
				for i = 1, NAL do
					local iName = NameArray[i]
					if type(iName) == "string" then
						iName = cooldowns[iName] or iName-- spell name keys have values that are the spellid of the name, we need the spellid for the texture (thats why i did it like this)
					end
					local _start
					if OnlySeen then
						_start = cooldowns[iName]
					else
						_start = cooldowns[iName] or 0
					end
					
					if _start then
						local tms = time-_start -- Time Minus Start - time since the unit's last cast of the spell (not neccesarily the time it has been on cooldown)
						local _d = tms > ICDDuration and 0 or tms -- real duration remaining on the cooldown
						if Sort then
							if _d ~= 0 then -- found an unusable cooldown
								if (Sort == 1 and d < _d) or (Sort == -1 and d > _d) then -- the duration is lower or higher than the last duration that was going to be used
									d = _d
									unname = iName
									unstart = _start
								end
							elseif not usename then -- we found the first usable cooldown
								usename = iName
								if Alpha ~= 0 then -- we care about usable cooldowns, so stop looking
									dobreak = 1
									break
								end
							end
						else
							if _d ~= 0 and not unname then -- we found the first UNusable cooldown
								unname = iName
								unstart = _start
								if Alpha == 0 then -- we DONT care about usable cooldowns, so stop looking
									dobreak = 1
									break
								end
							elseif _d == 0 and not usename then -- we found the first usable cooldown
								usename = iName
								if Alpha ~= 0 then -- we care about usable cooldowns, so stop looking
									dobreak = 1
									break
								end
							end
						end
					end
				end
				if dobreak then
					break
				end
			end
		end
		if usename and Alpha > 0 then
			icon:SetInfo(Alpha, 1, SpellTextures[usename] or "Interface\\Icons\\INV_Misc_PocketWatch_01", 0, 0)
		elseif unname then
			icon:SetInfo(UnAlpha, (not icon.ShowTimer and Alpha ~= 0) and .5 or 1, SpellTextures[unname], unstart, ICDDuration)
		else
			icon:SetAlpha(0)
		end
	end
end			


function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.Units = TMW:GetUnits(icon, icon.Unit)
	icon.Sort = icon.Sort and -icon.Sort -- i wish i could figue out why this is backwards

	for k, v in pairs(icon.NameArray) do
		-- this is for looking up the spellID in Cooldowns[GUID] - spell names are stored lowercase
		if type(v) == "string" then
			icon.NameArray[k] = strlower(v)
		end
	end
	
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
