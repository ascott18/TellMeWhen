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

local db, CUR_TIME, UPD_INTV, pr, ab
local ipairs, strlower =
	  ipairs, strlower
local UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID =
	  UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID

local clientVersion = select(4, GetBuildInfo())

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	BuffShowWhen = true,
	Interruptible = true,
	Unit = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("cast", RelevantSettings)
Type.name = L["ICONMENU_CAST"]
LibStub("AceEvent-3.0"):Embed(Type)

Type:SetScript("OnUpdate", function()
	CUR_TIME = TMW.CUR_TIME
end)

function Type:Update()
	CUR_TIME = TMW.CUR_TIME
	db = TMW.db
	UPD_INTV = db.profile.Interval
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end

local Casts = {} TMW.Casts = Casts
if clientVersion >= 40100 then -- COMBAT_LOG_EVENT_UNFILTERED
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, _, g, _, _, _, _, _, i)-- tyPe, sourceGuid, spellId -- NEW ARG IN 4.1 BETWEEN TYPE AND SOURCEGUID
		if p == "SPELL_CAST_START" then
			Casts[g] = i
		elseif p == "SPELL_CAST_FAILED" or p == "SPELL_CAST_SUCCESS" then
			Casts[g] = nil
		end
	end
else
	function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, p, g, _, _, _, _, _, i)-- tyPe, Guid, spellId
		if p == "SPELL_CAST_START" then
			Casts[g] = i
		elseif p == "SPELL_CAST_FAILED" or p == "SPELL_CAST_SUCCESS" then
			Casts[g] = nil
		end
	end
end

local function Cast_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		
		local NameFirst, NameDictionary, Interruptible = icon.NameFirst, icon.NameDictionary, icon.Interruptible
		for _, unit in ipairs(icon.Units) do
			if UnitExists(unit) then
				local name, _, _, iconTexture, start, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
				local reverse = false
				if not name then
					name, _, _, iconTexture, start, endTime, _, notInterruptible = UnitChannelInfo(unit)
					reverse = true
				end

				if name and not (notInterruptible and icon.Interruptible) and (NameFirst == "" or NameDictionary[strlower(name)] or NameDictionary[Casts[UnitGUID(unit)]]) then
					local Alpha = icon.Alpha
					if Alpha == 0 then
						icon:SetAlpha(0)
						return
					end
					
					local d = endTime - CUR_TIME
					if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
						icon:SetAlpha(0)
						return
					end
					
					icon:SetTexture(iconTexture)
					icon:SetAlpha(Alpha)

					if icon.UnAlpha ~= 0 then
						icon:SetVertexColor(pr)
					else
						icon:SetVertexColor(1)
					end
					start, endTime = start/1000, endTime/1000
					local duration = endTime - start

					if icon.ShowTimer then
						icon:SetCooldown(start, duration, reverse)
					end
					if icon.ShowCBar then
						icon:CDBarStart(start, duration, true)
					end

					return
				end
			end
		end
		local UnAlpha = icon.UnAlpha
		if UnAlpha == 0 then
			icon:SetAlpha(0)
			return
		end
		if icon.ShowCBar then
			icon:CDBarStop()
		end

		icon:SetAlpha(UnAlpha)
		if icon.Alpha ~= 0 then
			icon:SetVertexColor(ab)
		else
			icon:SetVertexColor(1)
		end

		if icon.ShowTimer then
			icon:SetCooldown(0, 0)
		end
	end
end



Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
--	icon.NameNameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	for name in pairs(icon.NameDictionary) do
		if type(name) == "number" then
			Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
	
	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\Temp")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\Temp")
	end

	icon.ShowPBar = false
	icon:SetScript("OnUpdate", Cast_OnUpdate)
	icon:OnUpdate()
end



