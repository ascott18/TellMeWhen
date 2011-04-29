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

local db, UPD_INTV, EFF_THR, ClockGCD, rc, mc, pr, ab
local tonumber, strlower =
	  tonumber, strlower
local UnitAura, UnitExists =
	  UnitAura, UnitExists
local print = TMW.print
local DS = TMW.DS

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	BuffOrDebuff = true,
	BuffShowWhen = true,
	OnlyMine = true,
	Unit = true,
	StackAlpha = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
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
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("buff", RelevantSettings)
Type.name = L["ICONMENU_BUFFDEBUFF"]


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	EFF_THR = db.profile.EffThreshold
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end


local function Buff_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local Units, NameArray, NameNameArray, NameDictionary, Filter, Filterh = icon.Units, icon.NameArray, icon.NameNameArray, icon.NameDictionary, icon.Filter, icon.Filterh
		local NAL = icon.NAL

		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				local buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id
				if NAL > EFF_THR then
					for z=1, 60 do --60 because i can and it breaks when there are no more buffs anyway
						buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filter)
						if not buffName
						or NameDictionary[id]
						or NameDictionary[strlower(buffName)]
						or NameDictionary[dispelType] then
							break
						end
					end
					if Filterh and not buffName then
						for z=1, 60 do
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filterh)
							if not buffName
							or NameDictionary[id]
							or NameDictionary[strlower(buffName)]
							or NameDictionary[dispelType] then
								break
							end
						end
					end
				else
					for i = 1, NAL do
						local iName = NameArray[i]
						if DS[iName] then --Enrage wont be handled here because it will always have more auras than the efficiency threshold (max 40, there are about 120 enrages i think)
							for z=1, 60 do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filter)
								if not buffName or dispelType == iName then
									break
								end
							end
							if Filterh and not buffName then
								for z=1, 60 do
									buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filterh)
									if not buffName or dispelType == iName then
										break
									end
								end
							end
						else
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, NameNameArray[i], nil, Filter)
						end
						if Filterh and not buffName then
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, NameNameArray[i], nil, Filterh)
						end
						if buffName and id ~= iName and tonumber(iName) then
							for z=1, 60 do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filter)
								if not id or id == iName then
									break
								end
							end
							if Filterh and not id then
								for z=1, 60 do
									buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, _, _, id = UnitAura(unit, z, Filterh)
									if not id or id == iName then
										break
									end
								end
							end
						end
						if buffName then
							break
						end
					end
				end
				if buffName then
					icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, iconTexture, expirationTime - duration, duration, nil, buffName, nil, count)
					return
				end
			end
		end
		icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and ab or 1, icon.FirstTexture, 0, 0, nil, icon.NameFirst)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = ((icon.BuffOrDebuff == "EITHER") and "HARMFUL")
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end
	icon:SetReverse(true)
	icon.NAL = icon.NameNameDictionary[strlower(GetSpellInfo(8921))] and EFF_THR + 2 or #icon.NameArray -- need to force any icon looking for moonfire to check all auras on the target because of a blizzard bug in 4.1.

	icon.FirstTexture = GetSpellTexture(icon.NameFirst)
	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", Buff_OnUpdate)
	icon:OnUpdate(TMW.time)
end



