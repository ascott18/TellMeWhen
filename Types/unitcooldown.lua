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

local db, CUR_TIME, UPD_INTV, ClockGCD, pr, ab, rc, mc
local ipairs, strlower, type =
	  ipairs, strlower, type
local UnitGUID, UnitExists, GetSpellTexture =
	  UnitGUID, UnitExists, GetSpellTexture

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

Type:SetScript("OnUpdate", function()
	CUR_TIME = TMW.CUR_TIME
end)

function Type:Update()
	CUR_TIME = TMW.CUR_TIME
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

if clientVersion >= 40100 then -- COMBAT_LOG_EVENT_UNFILTERED
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, g, _, _, _, _, _, i, n)-- tyPe, sourceGuid, spellId, spellName -- NEW ARG IN 4.1 BETWEEN TYPE AND SOURCEGUID
		if p == "SPELL_CAST_SUCCESS" then
			local c = Cooldowns[g]
			c[strlower(n)] = i
			c[i] = CUR_TIME
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = CUR_TIME
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
			c[i] = CUR_TIME
		elseif p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_DAMAGE" or p == "SPELL_HEAL" or p == "SPELL_MISSED" then
			local t = CUR_TIME
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
	c[i] = CUR_TIME
end

local function UnitCooldown_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local unstart, unname
		local Alpha, ICDDuration = icon.Alpha, icon.ICDDuration

		for _, unit in ipairs(icon.Units) do
			if UnitExists(unit) then
				local cooldowns = Cooldowns[UnitGUID(unit)]
				for i, iName in ipairs(icon.NameArray) do
					local start
					if type(iName) == "string" then
						iName = cooldowns[strlower(iName)] or iName-- spell name keys have values that are the spellid of the name, we need the spellid for the texture (thats why i did it like this)
						if icon.OnlySeen then
							start = cooldowns[iName]
						else
							start = cooldowns[iName] or 0
						end
					else
						if icon.OnlySeen then
							start = cooldowns[iName]
						else
							start = cooldowns[iName] or 0
						end
					end
					if start then
						if (CUR_TIME - start) > ICDDuration then -- off cooldown

							icon:SetCooldown(0, 0)
							if icon.ShowCBar then
								icon:CDBarStart(start, ICDDuration)
							end
							icon:SetVertexColor(1)
							icon:SetAlpha(Alpha)

							icon:SetTexture((iName and (GetSpellTexture(iName) )) or "Interface\\Icons\\INV_Misc_PocketWatch_01")

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
		if icon.UnAlpha ~= 0 and unstart then
			local d = ICDDuration - (CUR_TIME - unstart)
			if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
				icon:SetAlpha(0)
				return
			end

			if icon.ShowTimer then
				icon:SetCooldown(unstart, ICDDuration)
			end
			if icon.ShowCBar then
				icon:CDBarStart(unstart, ICDDuration)
			end

			if not icon.ShowTimer and Alpha ~= 0 then
				icon:SetVertexColor(0.5)
			else
				icon:SetVertexColor(1)
			end
			local t = GetSpellTexture(unname)
			if t then
				icon:SetTexture(t)
			end

			icon:SetAlpha(icon.UnAlpha)
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
	icon:OnUpdate()
end
