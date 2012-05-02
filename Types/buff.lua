-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local EFF_THR, DS
local tonumber, strlower =
	  tonumber, strlower
local UnitAura, UnitExists =
	  UnitAura, UnitExists
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local _, pclass = UnitClass("Player")
local isNumber = TMW.isNumber
local unitsWithExistsEvent


local Type = TMW.Classes.IconType:New()
Type.type = "buff"
Type.name = L["ICONMENU_BUFFDEBUFF"]
Type.desc = L["ICONMENU_BUFFDEBUFF_DESC"]
Type.usePocketWatch = 1
Type.spacebefore = true
Type.SUGType = "buff"
Type.unitType = "unitid"
Type.TypeChecks = {
	text = L["ICONMENU_BUFFTYPE"],
	setting = "BuffOrDebuff",
	{ value = "HELPFUL", 		text = L["ICONMENU_BUFF"], 				colorCode = "|cFF00FF00" },
	{ value = "HARMFUL", 		text = L["ICONMENU_DEBUFF"], 			colorCode = "|cFFFF0000" },
	{ value = "EITHER", 		text = L["ICONMENU_BOTH"] },
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	BuffOrDebuff = true,
	OnlyMine = true,
	Unit = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Sort = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	ShowTTText = true,
	Stealable = pclass == "MAGE",
}



function Type:Update()
	EFF_THR = TMW.db.profile.EffThreshold
	DS = TMW.DS
	unitsWithExistsEvent = TMW.UNITS.unitsWithExistsEvent
end

local function Buff_OnEvent(icon, event, arg1)
	if event == "UNIT_AURA" then
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

local huge = math.huge
local function Buff_OnUpdate(icon, time)

	local Units, NameArray, NameNameArray, NameHash, Filter, Filterh, Sort
	= icon.Units, icon.NameArray, icon.NameNameArray, icon.NameHash, icon.Filter, icon.Filterh, icon.Sort
	local NotStealable = not icon.Stealable
	local NAL = icon.NAL

	local buffName, _, iconTexture, count, dispelType, duration, expirationTime, canSteal, id, v1, v2, v3
	local useUnit
	local d = Sort == -1 and huge or 0
	for u = 1, #Units do
		local unit = Units[u]
		if unitsWithExistsEvent[unit] or UnitExists(unit) then -- if unitsWithExistsEvent[unit] is true then the unit is managed by TMW's unit framework, so we dont need to check that it exists.
			if Sort or NAL > EFF_THR then
				for z=1, huge do --huge because i can and it breaks when there are no more buffs anyway
					local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _, canSteal, _, _id, _, _, _v1, _v2, _v3 = UnitAura(unit, z, Filter)
					_dispelType = _dispelType == "" and "Enraged" or _dispelType -- Bug: Enraged is an empty string
					if not _buffName then
						break
					elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or canSteal) then
						if Sort then
							local _d = (_expirationTime == 0 and huge) or _expirationTime - time
							if d*Sort < _d*Sort then
								buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, useUnit, d =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, unit, _d
							end
						else
							buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, useUnit =
							_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, unit
							break
						end
					end
				end
				if Filterh and not buffName then
					for z=1, huge do
						local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _, canSteal, _, _id, _, _, _v1, _v2, _v3 = UnitAura(unit, z, Filterh)
						_dispelType = _dispelType == "" and "Enraged" or _dispelType -- Bug: Enraged is an empty string
						if not _buffName then
							break
						elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or canSteal) then
							if Sort then
								local _d = (_expirationTime == 0 and huge) or _expirationTime - time
								if d*Sort < _d*Sort then
									buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, useUnit, d =
									_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, unit, _d
								end
							else
								buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, useUnit =
								 _buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, unit
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
							buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filter)
							dispelType = dispelType == "" and "Enraged" or dispelType -- Bug: Enraged is an empty string
							if (not buffName) or (dispelType == iName and (NotStealable or canSteal)) then
								break
							end
						end
						if Filterh and not buffName then
							for z=1, huge do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filterh)
								dispelType = dispelType == "" and "Enraged" or dispelType -- Bug: Enraged is an empty string
								if (not buffName) or (dispelType == iName and (NotStealable or canSteal)) then
									break
								end
							end
						end
					else
						-- stealable checks here are done before breaking the loop
						buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, NameNameArray[i], nil, Filter)
						if Filterh and not buffName then
							buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, NameNameArray[i], nil, Filterh)
						end
					end
					if buffName and id ~= iName and isNumber[iName] then
						for z=1, huge do
							buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filter)
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
								buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filterh)
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
		if icon.ShowTTText and v1 then
			if v1 > 0 then
				count = v1
			elseif v2 > 0 then
				count = v2
			elseif v3 > 0 then
				count = v3
			else
				count = 0
			end
		end

		icon:SetInfo("alpha; color; texture; start, duration; stack, stackText; spell; unit, GUID",
			icon.Alpha,
			icon:CrunchColor(duration),
			iconTexture,
			expirationTime - duration, duration,
			count, count,
			id,
			useUnit, nil
		)
	else
		icon:SetInfo("alpha; color; texture; start, duration; stack, stackText; spell; unit, GUID",
			icon.UnAlpha,
			icon:CrunchColor(),
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			Units[1], nil
		)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	--icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	
	local UnitSet
	icon.Units, UnitSet = TMW:GetUnits(icon, icon.Unit)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = icon.BuffOrDebuff == "EITHER" and "HARMFUL"
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end
	
	icon.NAL = icon.NameNameHash[strlower(GetSpellInfo(8921))] and EFF_THR + 1 or #icon.NameArray
	-- need to force any icon looking for moonfire to check all auras on the target because of a blizzard bug in WoW 4.1.
	-- TODO: verify that the issue persists

	-- icon.NAL = icon.Sort and EFF_THR + 1 or icon.NAL
	-- NOTE: we dont do this anymore because this is checked directly in the function instead of doing stupid shit like this.
	-- Force icons that sort to check all because it must find check all auras
	-- in order to make a final decision on whether or not something has the highest/lowest duration.
	-- Two buffs with the same name/ID can have different durations on a unit.
	-- Normal aura checking will stop when it finds the first one and go to check the next item in NameArray.

	icon.FirstTexture = SpellTextures[icon.NameFirst]

	icon:SetInfo("texture; reverse", TMW:GetConfigIconTexture(icon), true)
	
	if UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		for event in pairs(UnitSet.updateEvents) do
			icon:RegisterEvent(event)
		end
	
		icon:RegisterEvent("UNIT_AURA")
	
		icon:SetScript("OnEvent", Buff_OnEvent)
	end

	icon:SetScript("OnUpdate", Buff_OnUpdate)
	icon:Update()
end

Type:Register()

