-- NEEDS manual REVIEW
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

local db
local ipairs, strlower =
	  ipairs, strlower
local UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID =
	  UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID
local print = TMW.print
local strlowerCache = TMW.strlowerCache
local unitsWithExistsEvent

local Type = TMW.Classes.IconType:New()
LibStub("AceEvent-3.0"):Embed(Type)
Type.type = "cast"
Type.name = L["ICONMENU_CAST"]
Type.desc = L["ICONMENU_CAST_DESC"]
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"]
Type.SUGType = "cast"
Type.AllowNoName = true
Type.usePocketWatch = 1
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

Type.EventDisabled_OnStack = true

local events = {	
	UNIT_SPELLCAST_START = true,
	UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_FAILED = true,
	UNIT_SPELLCAST_DELAYED = true,
	UNIT_SPELLCAST_INTERRUPTED = true,
	UNIT_SPELLCAST_CHANNEL_START = true,
	UNIT_SPELLCAST_CHANNEL_UPDATE = true,
	UNIT_SPELLCAST_CHANNEL_STOP = true,
	UNIT_SPELLCAST_CHANNEL_INTERRUPTED = true,
	UNIT_SPELLCAST_INTERRUPTIBLE = true,
	UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
}

function Type:Update()
	db = TMW.db
	unitsWithExistsEvent = TMW.UNITS.unitsWithExistsEvent
end

local function Cast_OnEvent(icon, event, arg1)
	if events[event] then -- a unit cast event
		local Units = icon.Units
		for u = 1, #Units do
			if arg1 == Units[u] then
				icon.NextUpdateTime = 0
				return
			end
		end
	else -- a unit changed event
		icon.NextUpdateTime = 0
	end
end

local function Cast_OnUpdate(icon, time)
	local NameFirst, NameNameHash, Units, Interruptible = icon.NameFirst, icon.NameNameHash, icon.Units, icon.Interruptible

	for u = 1, #Units do
		local unit = Units[u]
		if unitsWithExistsEvent[unit] or UnitExists(unit) then -- if unitsWithExistsEvent[unit] is true then the unit is managed by TMW's unit framework, so we dont need to check that it exists.
			local name, _, _, iconTexture, start, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
			local reverse = false -- must be false
			if not name then
				name, _, _, iconTexture, start, endTime, _, notInterruptible = UnitChannelInfo(unit)
				reverse = true
			end

			if name and not (notInterruptible and Interruptible) and (NameFirst == "" or NameNameHash[strlowerCache[name]]) then
				start, endTime = start/1000, endTime/1000
				local duration = endTime - start

				local color = icon:CrunchColor(duration)

				--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
				icon:SetInfo(icon.Alpha, color, iconTexture, start, duration, name, reverse, nil, nil, nil, unit)

				return
			end
		end
	end
	local color = icon:CrunchColor()

	--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
	icon:SetInfo(icon.UnAlpha, color, nil, 0, 0, NameFirst, nil, nil, nil, nil, Units[1])
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
--	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)

	icon:SetTexture(TMW:GetConfigIconTexture(icon))
	
	local UnitSet
	icon.Units, UnitSet = TMW:GetUnits(icon, icon.Unit)
	icon.TableToIterate = icon.Units
	
	if UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		for event in pairs(UnitSet.updateEvents) do
			icon:RegisterEvent(event)
		end
	
		for event in pairs(events) do
			icon:RegisterEvent(event)
		end
	
		icon:SetScript("OnEvent", Cast_OnEvent)
	end

	icon.ShowPBar = false
	icon:SetScript("OnUpdate", Cast_OnUpdate)
	icon:Update()
end

function Type:GetNameForDisplay(icon, data)
	return data and GetSpellLink(data) or data, 1
end

function Type:GetIconMenuText(data)
	local text = data.Name or ""
	if text == "" then
		text = "((" .. L["ICONMENU_CAST"] .. "))"
	end

	return text, data.Name and data.Name ~= "" and data.Name .. "\r\n" or ""
end

Type:Register()

