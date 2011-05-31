-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, pr, ab
local ipairs, strlower =
	  ipairs, strlower
local UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID =
	  UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID
local print = TMW.print
local strlowerCache = TMW.strlowerCache

local clientVersion = select(4, GetBuildInfo())

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	ShowWhen = true,
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
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_CAST"]
Type.WhenChecks = {
	text = L["ICONMENU_CASTSHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end

local function Cast_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local NameFirst, NameNameDictionary, Units, Interruptible = icon.NameFirst, icon.NameNameDictionary, icon.Units, icon.Interruptible
		
		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				local name, _, _, iconTexture, start, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
				local reverse = false -- must be false
				if not name then
					name, _, _, iconTexture, start, endTime, _, notInterruptible = UnitChannelInfo(unit)
					reverse = true
				end

				if name and not (notInterruptible and Interruptible) and (NameFirst == "" or NameNameDictionary[strlowerCache[name]]) then
					start, endTime = start/1000, endTime/1000
					local duration = endTime - start

					icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, iconTexture, start, duration, nil, nil, reverse)

					return
				end
			end
		end
		icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and ab or 1, nil, 0, 0)
	end
end



Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
--	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\Temp")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\Temp")
	end

	icon.ShowPBar = false
	icon:SetScript("OnUpdate", Cast_OnUpdate)
	icon:OnUpdate(TMW.time)
end



