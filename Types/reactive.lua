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

local db, time, UPD_INTV, ClockGCD, pr, ab, rc, mc
local GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellTexture, GetSpellInfo =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell, GetSpellTexture, GetSpellInfo
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	CooldownShowWhen = true,
	RangeCheck = true,
	ManaCheck = true,
	CooldownCheck = true,
	ShowPBar = true,
	PBarOffs = true,
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
	UseActvtnOverlay = true,
	IgnoreRunes = (pclass == "DEATHKNIGHT"),
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("reactive", RelevantSettings)
Type.name = L["ICONMENU_REACTIVE"]
Type.desc = L["ICONMENU_REACTIVE_DESC"]


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end


local function Reactive_OnEvent(icon, event, spell)

	if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
		if icon.NameFirst == spell or GetSpellInfo(spell) == icon.NameName then
			icon.Usable = true
		end
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		if icon.NameFirst == spell or GetSpellInfo(spell) == icon.NameName then
			icon.Usable = false
		end
	end
end

local function Reactive_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, nomana, start, duration, isGCD, CD, usable = 1
		local NameArray, NameNameArray, RangeCheck, ManaCheck, CooldownCheck, IgnoreRunes, Usable =
		 icon.NameArray, icon.NameNameArray, icon.RangeCheck, icon.ManaCheck, icon.CooldownCheck, icon.IgnoreRunes, icon.Usable
		
		for i = 1, #NameArray do
			local iName = NameArray[i]
			n = i
			start, duration = GetSpellCooldown(iName)
			if duration then
				inrange, CD = 1
				if RangeCheck then
					inrange = IsSpellInRange(NameNameArray[i], "target") or 1
				end
				usable, nomana = IsUsableSpell(iName)
				if not ManaCheck then
					nomana = nil
				end
				isGCD = OnGCD(duration)
				if CooldownCheck then
					if IgnoreRunes then
						if start == GetSpellCooldown(45477) or start == GetSpellCooldown(45462) or start == GetSpellCooldown(45902) then
							start, duration = 0, 0
						end
					end
					CD = not (duration == 0 or isGCD)
				end
				usable = Usable or usable
				if usable and not CD and not nomana and inrange == 1 then --usable
					if icon.Alpha == 0 then
						icon:SetAlpha(0)
						return
					end

					local t = GetSpellTexture(iName)
					if t then
						icon:SetTexture(t)
					end

					icon:SetVertexColor(1)
					icon:SetAlpha(icon.Alpha)

					if not icon.ShowTimer or (ClockGCD and isGCD) then
						icon:SetCooldown(0, 0)
					else
						icon:SetCooldown(start, duration)
					end

					if icon.ShowCBar then
						icon:CDBarStart(start, duration)
					end
					if icon.ShowPBar then
						icon:PwrBarStart(iName)
					end

					return
				end
			end
		end
		if icon.UnAlpha == 0 then
			icon:SetAlpha(0)
			return
		end
		if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
			start, duration = GetSpellCooldown(icon.NameFirst)
			if icon.IgnoreRunes then
				if start == GetSpellCooldown(45477) or start == GetSpellCooldown(45462) or start == GetSpellCooldown(45902) then
					start, duration = 0, 0
				end
			end
			inrange, nomana = 1
			if icon.RangeCheck then
				inrange = IsSpellInRange(icon.NameName, "target") or 1
			end
			if icon.ManaCheck then
				_, nomana = IsUsableSpell(icon.NameFirst)
			end
			isGCD = OnGCD(duration)
		end
		if duration then
			local d = duration - (time - start)
			if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
				icon:SetAlpha(0)
				return
			end

			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					icon:SetVertexColor(rc)
					icon:SetAlpha(icon.UnAlpha*rc.a)
				elseif nomana then
					icon:SetVertexColor(mc)
					icon:SetAlpha(icon.UnAlpha*mc.a)
				else
					icon:SetVertexColor(0.5)
					icon:SetAlpha(icon.UnAlpha)
				end
			else
				icon:SetVertexColor(1)
				icon:SetAlpha(icon.UnAlpha)
			end

			if icon.FirstTexture then
				icon:SetTexture(icon.FirstTexture)
			end

			if not icon.ShowTimer or (ClockGCD and isGCD) then
				icon:SetCooldown(0, 0)
			else
				icon:SetCooldown(start, duration)
			end

			if icon.ShowCBar then
				icon:CDBarStart(start, duration)
			end
			if icon.ShowPBar then
				icon:PwrBarStart(icon.NameFirst)
			end

			return
		else
			icon:Hide()
			return
		end
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, true)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.Usable = false

	icon.FirstTexture = GetSpellTexture(icon.NameFirst)

	if icon.UseActvtnOverlay then
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		icon:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
		icon:SetScript("OnEvent", Reactive_OnEvent)
	end

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end

	icon:SetScript("OnUpdate", Reactive_OnUpdate)
	icon:OnUpdate(GetTime() + 1)
end


