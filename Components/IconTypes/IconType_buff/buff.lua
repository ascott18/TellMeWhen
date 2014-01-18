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

local EFF_THR, DS
local tonumber =
	  tonumber
local UnitAura, UnitExists =
	  TMW.UnitAura, UnitExists
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local _, pclass = UnitClass("Player")
local isNumber = TMW.isNumber
local unitsWithExistsEvent

local clientVersion = select(4, GetBuildInfo())
local wow_501 = clientVersion >= 50100

local Type = TMW.Classes.IconType:New("buff")
Type.name = L["ICONMENU_BUFFDEBUFF"]
Type.desc = L["ICONMENU_BUFFDEBUFF_DESC"]
Type.menuIcon = GetSpellTexture(774)
Type.usePocketWatch = 1
Type.spacebefore = true
Type.unitType = "unitid"
Type.hasNoGCD = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("reverse")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	Sort					= false,
	StackSort				= false,
	Unit					= "player", 
	BuffOrDebuff			= "HELPFUL", 
	Stealable				= false,     
	ShowTTText				= false,     
	OnlyMine				= false,
	HideIfNoUnits			= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "buff",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_BuffOrDebuff", function(self)
	self.Header:SetText(TMW.L["ICONMENU_BUFFTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 3,
		{
			setting = "BuffOrDebuff",
			value = "HELPFUL",
			title = "|cFF00FF00" .. L["ICONMENU_BUFF"],
		},
		{
			setting = "BuffOrDebuff",
			value = "HARMFUL",
			title = "|cFFFF0000" .. L["ICONMENU_DEBUFF"],
		},
		{
			setting = "BuffOrDebuff",
			value = "EITHER",
			title = L["ICONMENU_BOTH"],
		},
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(125, "TellMeWhen_BuffSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "OnlyMine",
			title = L["ICONMENU_ONLYMINE"],
			tooltip = L["ICONMENU_ONLYMINE_DESC"],
		},
		{
			setting = "ShowTTText",
			title = L["ICONMENU_SHOWTTTEXT"],
			tooltip = L["ICONMENU_SHOWTTTEXT_DESC"],
		},
		{
			setting = "Stealable",
			title = L["ICONMENU_STEALABLE"],
			tooltip = L["ICONMENU_STEALABLE_DESC"],
		},
		{
			setting = "HideIfNoUnits",
			title = L["ICONMENU_HIDENOUNITS"],
			tooltip = L["ICONMENU_HIDENOUNITS_DESC"],
		},
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONANY"], 	tooltipText = L["ICONMENU_PRESENTONANY_DESC"],	},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENTONALL"], 	tooltipText = L["ICONMENU_ABSENTONALL_DESC"],	},
})

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettingsWithStacks")


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	EFF_THR = TMW.db.profile.EffThreshold
	DS = TMW.DS
	unitsWithExistsEvent = TMW.UNITS.unitsWithExistsEvent
end)

local function Buff_OnEvent(icon, event, arg1)
	if event == "UNIT_AURA" then
		local Units = icon.Units
		for u = 1, #Units do
			if arg1 == Units[u] then
				icon.NextUpdateTime = 0
				return
			end
		end
	elseif event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		icon.NextUpdateTime = 0
	end
end

local huge = math.huge
local function Buff_OnUpdate(icon, time)
	-- WARNING: THIS CODE IS HORRIFYING. ENTER AT YOUR OWN RISK!
	
	
	local Units, NameArray, NameNameArray, NameHash, Filter, Filterh, Sort, StackSort
	= icon.Units, icon.NameArray, icon.NameNameArray, icon.NameHash, icon.Filter, icon.Filterh, icon.Sort, icon.StackSort
	local NotStealable = not icon.Stealable
	local NAL = #icon.NameArray

	local buffName, _, iconTexture, dispelType, duration, expirationTime, count, canSteal, id, v1, v2, v3, v4
	local useUnit
	local d = Sort == -1 and huge or 0
	local s = StackSort == -1 and huge or -1
	
	for u = 1, #Units do
		local unit = Units[u]
		if icon.UnitSet:UnitExists(unit) then
			if Sort or NAL > EFF_THR then
				for z=1, huge do
					local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _, canSteal, _, _id, _, _, _, _v1, _v2, _v3, _v4 = UnitAura(unit, z, Filter)
					_dispelType = _dispelType == "" and "Enraged" or _dispelType -- Bug: Enraged is an empty string
					if not _buffName then
						break
					elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or canSteal) then
						if Sort then
							local _d = (_expirationTime == 0 and huge) or _expirationTime - time

							if not buffName or d*Sort < _d*Sort then
								buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, v4, useUnit, d =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _v4, unit, _d
							end
						elseif StackSort then
							local _s = _count or 0

							if not buffName or s*StackSort < _s*StackSort then
								buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, v4, useUnit, s =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _v4, unit, _s
							end
						else
							buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, v4, useUnit =
							_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _v4, unit
							break
						end
					end
				end
				if Filterh and not buffName then
					for z=1, huge do
						local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _, canSteal, _, _id, _, _, _, _v1, _v2, _v3, _v4 = UnitAura(unit, z, Filterh)
						_dispelType = _dispelType == "" and "Enraged" or _dispelType -- Bug: Enraged is an empty string
						if not _buffName then
							break
						elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or canSteal) then
							if Sort then
								local _d = (_expirationTime == 0 and huge) or _expirationTime - time

								if not buffName or d*Sort < _d*Sort then
									buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, v4, useUnit, d =
									_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _v4, unit, _d
								end
							elseif StackSort then
								local _s = _count or 1

								if not buffName or s*StackSort < _s*StackSort then
									buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, v4, useUnit, s =
									_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _v4, unit, _s
								end
							else
								buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, v4, useUnit =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _v4, unit
								break
							end
						end
					end
				end
				if buffName and not Sort then
					break --  break unit loop
				end
			else
				for i = 1, NAL do
					--local iName = strlowerCache[NameArray[i]] -- STRLOWERING IT BREAKS DISPEL TYPES! it should already be strlowered, except dispel types
					local iName = NameArray[i]
					if DS[iName] then --Handle dispel types.
						for z=1, huge do
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, z, Filter)
							dispelType = dispelType == "" and "Enraged" or dispelType -- Bug: Enraged is an empty string
							if (not buffName) or (dispelType == iName and (NotStealable or canSteal)) then
								break
							end
						end
						if Filterh and not buffName then
							for z=1, huge do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, z, Filterh)
								dispelType = dispelType == "" and "Enraged" or dispelType -- Bug: Enraged is an empty string
								if (not buffName) or (dispelType == iName and (NotStealable or canSteal)) then
									break
								end
							end
						end
					else
						-- stealable checks here are done before breaking the loop
						buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, NameNameArray[i], nil, Filter)
						if Filterh and not buffName then
							buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, NameNameArray[i], nil, Filterh)
						end
					end
					if buffName and id ~= iName and isNumber[iName] then
						for z=1, huge do
							buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, z, Filter)
							if not id or id == iName then -- and (NotStealable or canSteal) then
									-- No reason to check stealable here.
									-- It will be checked right before breaking the loop.
									-- Once it finds an ID match, any spell of that ID will have the same stealable status as any other,
									-- so just match ID and dont check for stealable here. Wow, that was repetetive.
								break
							end
						end
						if Filterh and not id then
							for z=1, huge do
								buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, z, Filterh)
								if not id or id == iName then -- and (NotStealable or canSteal) then
									-- No reason to check stealable here. See above.
									break
								end
							end
						end
					end
					if buffName and (NotStealable or canSteal) then
						useUnit = unit
						break -- break spell loop
					end
				end
				if buffName and (NotStealable or canSteal) then
					break --  break unit loop
				end
			end
		end
	end
	
	if buffName then
		if icon.ShowTTText then
			--if wow_501 then
				-- WoW 5.1 moved the stupid boolean return value that used to be at the end
				-- to before the variable returns where it belongs,
				-- so we can simplify our checking a bit (no need to check variable types anymore; just check if they are non-nil).
				if v1 and v1 > 0 then
					count = v1
				elseif v2 and v2 > 0 then
					count = v2
				elseif v3 and v3 > 0 then
					count = v3
				elseif v4 and v4 > 0 then
					count = v4
				else
					count = 0
				end
		end

		icon:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID",
			icon.Alpha,
			iconTexture,
			expirationTime - duration, duration,
			count, count,
			id,
			useUnit, nil
		)
	elseif not Units[1] and icon.HideIfNoUnits then
		icon:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID",
			0,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			nil, nil
		)
	else
		icon:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID",
			icon.UnAlpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			Units[1], nil
		)
	end
end


function Type:Setup(icon)
	icon.NameFirst = TMW:GetSpellNames(icon.Name, 1, 1)
	--icon.NameName = TMW:GetSpellNames(icon.Name, 1, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon.Name, 1)
	icon.NameNameArray = TMW:GetSpellNames(icon.Name, 1, nil, 1)
	icon.NameHash = TMW:GetSpellNames(icon.Name, 1, nil, nil, 1)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = icon.BuffOrDebuff == "EITHER" and "HARMFUL"
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end

	icon.FirstTexture = SpellTextures[icon.NameFirst]

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)
	
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		
		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
	
		icon:RegisterEvent("UNIT_AURA")
	
		icon:SetScript("OnEvent", Buff_OnEvent)
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", Buff_OnEvent, icon)
	end

	icon:SetUpdateFunction(Buff_OnUpdate)
	icon:Update()
end

function Type:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local name = TMW:GetSpellNames(ics.Name, nil, 1)
		if name then
			return SpellTextures[name]
		end
	end
	return "Interface\\Icons\\INV_Misc_PocketWatch_01"
end
	
Type:Register(100)

