-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local pairs, ipairs =
	  pairs, ipairs
local GetSpellLink, GetSpellInfo, UnitCastingInfo, UnitChannelInfo =
	  GetSpellLink, GetSpellInfo, UnitCastingInfo, UnitChannelInfo

local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New("cast")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_CAST"]
Type.desc = L["ICONMENU_CAST_DESC"]
Type.menuIcon = "Interface\\Icons\\Temp"
Type.AllowNoName = true
Type.usePocketWatch = 1
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_HIDE

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("state")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)




Type:RegisterIconDefaults{
	-- The unit(s) to check for casts
	Unit					= "player", 

	-- True if the icon should only check interruptible casts.
	Interruptible			= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "cast",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	--text = L["ICONMENU_CASTSHOWWHEN"],
	[STATE_PRESENT] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], },
	[STATE_ABSENT]  = { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],  },
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_CastSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_ONLYINTERRUPTIBLE"], L["ICONMENU_ONLYINTERRUPTIBLE_DESC"])
			check:SetSetting("Interruptible")
		end,
	})
end)



-- The unit spellcast events that the icon will register.
-- We keep them in a table because there's a fuckload of them.
local events = {
	UNIT_SPELLCAST_START = true,
	UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_SUCCEEDED = true,
	UNIT_SPELLCAST_FAILED = true,
	UNIT_SPELLCAST_FAILED_QUIET = true,
	UNIT_SPELLCAST_DELAYED = true,
	UNIT_SPELLCAST_INTERRUPTED = true,
	UNIT_SPELLCAST_CHANNEL_START = true,
	UNIT_SPELLCAST_CHANNEL_UPDATE = true,
	UNIT_SPELLCAST_CHANNEL_STOP = true,
	UNIT_SPELLCAST_CHANNEL_INTERRUPTED = true,
	UNIT_SPELLCAST_INTERRUPTIBLE = true,
	UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
}


local function Cast_OnEvent(icon, event, arg1)
	if events[event] then
		-- A UNIT_SPELLCAST_ event
		-- See if the icon is checking the unit. If so, schedule an update for the icon.
		local Units = icon.Units
		for u = 1, #Units do
			if arg1 == Units[u] then
				icon.NextUpdateTime = 0
				return
			end
		end
	elseif event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	end
end

local function Cast_OnUpdate(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local NameFirst, NameStringHash, Units, Interruptible =
	icon.Spells.First, icon.Spells.StringHash, icon.Units, icon.Interruptible

	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		if icon.UnitSet:UnitExists(unit) then

			local name, _, _, iconTexture, start, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
			-- Reverse is used to reverse the timer sweep masking behavior. Regular casts should have it be false.
			local reverse = false

			-- There is no regular spellcast. Check for a channel.
			if not name then
				name, _, _, iconTexture, start, endTime, _, notInterruptible = UnitChannelInfo(unit)
				-- Channeled casts should reverse the timer sweep behavior.
				reverse = true
			end

			if name and not (notInterruptible and Interruptible) and (NameFirst == "" or NameStringHash[strlowerCache[name]]) then
				
				-- Times reported by the cast APIs are in milliseconds for some reason.
				start, endTime = start/1000, endTime/1000
				local duration = endTime - start

				if not icon:YieldInfo(true, name, unit, iconTexture, start, duration, reverse) then
					-- If icon:YieldInfo() returns false, it means we don't need to keep harvesting data.
					return
				end
			end
		end
	end

	-- Signal the group controller that we are at the end of our data harvesting.
	icon:YieldInfo(false)
end

function Type:HandleYieldedInfo(icon, iconToSet, spell, unit, texture, start, duration, reverse)
	if spell then
		-- There was a spellcast or channel present on one of the icon's units.
		iconToSet:SetInfo(
			"state; texture; start, duration; reverse; spell; unit, GUID",
			STATE_PRESENT,
			texture,
			start, duration,
			reverse,
			spell,
			unit, nil
		)
	else
		-- There were no casts detected.
		iconToSet:SetInfo(
			"state; start, duration; spell; unit, GUID",
			STATE_ABSENT,
			0, 0,
			icon.Spells.First,
			icon.Units[1], nil
		)
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)



	icon:SetInfo("texture", Type:GetConfigIconTexture(icon))
	


	-- Setup events and update functions.
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")

		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
	
		-- Register the UNIT_SPELLCAST_ events
		for event in pairs(events) do
			icon:RegisterEvent(event)
		end
	
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", Cast_OnEvent, icon)
		icon:SetScript("OnEvent", Cast_OnEvent)
	end

	icon:SetUpdateFunction(Cast_OnUpdate)
	icon:Update()
end

function Type:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local name = TMW:GetSpells(ics.Name).First
		if name then
			return TMW.GetSpellTexture(name)
		end
	end
	return "Interface\\Icons\\Temp"
end

Type:Register(150)

