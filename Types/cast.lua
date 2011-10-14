-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
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


local Type = {}
Type.type = "cast"
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_CAST"]
Type.appendNameLabel = L["ICONMENU_CHOOSENAME_ORBLANK"]
Type.AllowNoName = true
Type.WhenChecks = {
	text = L["ICONMENU_CASTSHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	Interruptible = true,
	Unit = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
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

		local NameFirst, NameNameHash, Units, Interruptible = icon.NameFirst, icon.NameNameHash, icon.Units, icon.Interruptible

		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				local name, _, _, iconTexture, start, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
				local reverse = false -- must be false
				if not name then
					name, _, _, iconTexture, start, endTime, _, notInterruptible = UnitChannelInfo(unit)
					reverse = true
				end

				if name and not (notInterruptible and Interruptible) and (NameFirst == "" or NameNameHash[strlowerCache[name]]) then
					start, endTime = start/1000, endTime/1000
					local duration = endTime - start

					--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
					icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, iconTexture, start, duration, name, reverse, nil, nil, nil, unit)

					return
				end
			end
		end
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and ab or 1, nil, 0, 0, NameFirst, nil, nil, nil, nil, nil)
	end
end

function Type:GetNameForDisplay(icon, data)
	return data
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
--	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	icon:SetTexture(TMW:GetConfigIconTexture(icon))

	icon.ShowPBar = false
	icon:SetScript("OnUpdate", Cast_OnUpdate)
	icon:OnUpdate(TMW.time)
end

TMW:RegisterIconType(Type)

