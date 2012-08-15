-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local ipairs, strlower =
	  ipairs, strlower
local GetSpellLink, GetSpellInfo, UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID =
	  GetSpellLink, GetSpellInfo, UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID
local print = TMW.print
local strlowerCache = TMW.strlowerCache
local unitsWithExistsEvent

local Type = TMW.Classes.IconType:New("cast")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_CAST"]
Type.desc = L["ICONMENU_CAST_DESC"]
Type.AllowNoName = true
Type.usePocketWatch = 1
Type.unitType = "unitid"

Type:RegisterIconDefaults{
	Unit					= "player", 
	Interruptible			= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "cast",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit")

Type:RegisterConfigPanel_XMLTemplate(130, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_CASTSHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], 	},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"], 		},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_CastSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "Interruptible",
			title = L["ICONMENU_ONLYINTERRUPTIBLE"],
			tooltip = L["ICONMENU_ONLYINTERRUPTIBLE_DESC"],
		},
	})
end)

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

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

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	unitsWithExistsEvent = TMW.UNITS.unitsWithExistsEvent
end)

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

				icon:SetInfo(
					"alpha; texture; start, duration; reverse; spell; unit, GUID",
					icon.Alpha,
					iconTexture,
					start, duration,
					reverse,
					name,
					unit, nil
				)

				return
			end
		end
	end

	icon:SetInfo(
		"alpha; start, duration; spell; unit, GUID",
		icon.UnAlpha,
		0, 0,
		NameFirst,
		Units[1], nil
	)
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
--	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)

	icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))
	
	local UnitSet
	icon.Units, UnitSet = TMW:GetUnits(icon, icon.Unit)
	
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

	icon:SetScript("OnUpdate", Cast_OnUpdate)
	icon:Update()
end

function Type:GetNameForDisplay(icon, data, doInsertLink)
	return data and ((doInsertLink and GetSpellLink(data)) or GetSpellInfo(data)) or data, 1
end

function Type:GetIconMenuText(data, groupID, iconID)
	local text = data.Name or ""
	if text == "" then
		text = L["fICON"]:format(iconID) .. " - " .. Type.name
	end

	return text, ""--data.Name and data.Name ~= "" and data.Name .. "\r\n" or ""
end

Type:Register(150)

