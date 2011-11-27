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

local db, UPD_INTV, EFF_THR, ClockGCD, rc, mc, pr, ab, DS
local tonumber, strlower =
	  tonumber, strlower
local UnitAura, UnitExists =
	  UnitAura, UnitExists
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local _, pclass = UnitClass("Player")
local isNumber = TMW.isNumber


local Type = {}
Type.type = "buff"
Type.name = L["ICONMENU_BUFFDEBUFF"]
Type.desc = L["ICONMENU_BUFFDEBUFF_DESC"]
Type.usePocketWatch = 1
Type.spacebefore = true
Type.SUGType = "buff"
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
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	EFF_THR = db.profile.EffThreshold
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	DS = TMW.DS
end

local huge = math.huge
local function Buff_OnUpdate(icon, time)
	if icon.LastUpdate <= time - UPD_INTV then
		icon.LastUpdate = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local Units, NameArray, NameNameArray, NameHash, Filter, Filterh, Sort, ShowTTText
		= icon.Units, icon.NameArray, icon.NameNameArray, icon.NameHash, icon.Filter, icon.Filterh, icon.Sort, icon.ShowTTText
		local NotStealable = not icon.Stealable
		local NAL = icon.NAL

		local buffName, _, iconTexture, count, dispelType, duration, expirationTime, canSteal, id, v1, v2, v3
		local useUnit
		local d = Sort == -1 and huge or 0
		for u = 1, #Units do
			local unit = Units[u]
			if UnitExists(unit) then
				if NAL > EFF_THR then
					for z=1, 60 do --60 because i can and it breaks when there are no more buffs anyway
						local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _, canSteal, _, _id, _, _, _v1, _v2, _v3 = UnitAura(unit, z, Filter)
						if not _buffName then
							break
						elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or canSteal) then
							if Sort then
								local _d = (_expirationTime == 0 and huge) or _expirationTime - time
								if d*Sort < _d*Sort then
									buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, d =
									_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _d
								end
							else
								buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3 =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3
								break
							end
						end
					end
					if Filterh and not buffName then
						for z=1, 60 do
							local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _, canSteal, _, _id, _, _, _v1, _v2, _v3 = UnitAura(unit, z, Filterh)
							if not _buffName then
								break
							elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or canSteal) then
								if Sort then
									local _d = (_expirationTime == 0 and huge) or _expirationTime - time
									if d*Sort < _d*Sort then
										buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3, d =
										_buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3, _d
									end
								else
									buffName, iconTexture, count, duration, expirationTime, id, v1, v2, v3 =
									 _buffName, _iconTexture, _count, _duration, _expirationTime, _id, _v1, _v2, _v3
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
						--local iName = strlowerCache[NameArray[i]] -- STRLOWERING IT BREAKS DISPEL TYPES!
						local iName = NameArray[i]
						if DS[iName] then --Handle dispel types. Enrage wont be handled here because it will always have more auras than the efficiency threshold (max 40, there are about 120 enrages i think), ant it shouldnt be, because it is essentially just an equiv
							for z=1, 60 do
								buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filter)
								if (not buffName) or (dispelType == iName and (NotStealable or canSteal)) then
									break
								end
							end
							if Filterh and not buffName then
								for z=1, 60 do
									buffName, _, iconTexture, count, dispelType, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filterh)
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
							for z=1, 60 do
								buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filter)
								if not id or id == iName then -- and (NotStealable or canSteal) then -- no reason to check stealable here. It will be checked right before breaking the loop. Once it finds an ID match, any spell of that ID will have the same stealable status as any other, so just match ID and dont check for stealable here. Wow, that was repetetive.
									break
								end
							end
							if Filterh and not id then
								for z=1, 60 do
									buffName, _, iconTexture, count, _, duration, expirationTime, _, canSteal, _, id, _, _, v1, v2, v3 = UnitAura(unit, z, Filterh)
									if not id or id == iName then -- and (NotStealable or canSteal) then -- no reason to check stealable here. It will be checked right before breaking the loop. Once it finds an ID match, any spell of that ID will have the same stealable status as any other, so just match ID and dont check for stealable here. Wow, that was repetetive.
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
			
			local color = icon:CrunchColor(duration)
			
			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(icon.Alpha, color, iconTexture, expirationTime - duration, duration, buffName, nil, count, count > 1 and count or "", nil, useUnit)
		else
			local color = icon:CrunchColor()
		
			icon:SetInfo(icon.UnAlpha, color, icon.FirstTexture, 0, 0, icon.NameFirst, nil, nil, nil, nil, Units[1])
		end
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon, icon.Name)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = icon.BuffOrDebuff == "EITHER" and "HARMFUL"
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end
	
	icon:SetReverse(true)
	icon.NAL = icon.NameNameHash[strlower(GetSpellInfo(8921))] and EFF_THR + 1 or #icon.NameArray
	-- need to force any icon looking for moonfire to check all auras on the target because of a blizzard bug in WoW 4.1.
	-- TODO: verify that the issue persists
	
	icon.NAL = icon.Sort and (#icon.NameArray > 1 or TMW.DS[icon.NameFirst]) and EFF_THR + 1 or icon.NAL
	-- Force icons that sort to check all because it must find check all auras
	-- in order to make a final decision on whether or not something has the highest/lowest duration.
	-- Two buffs with the same name/ID can have different durations on a unit.
	-- Normal aura checking will stop when it finds the first one and go to check the next item in NameArray.

	icon.FirstTexture = SpellTextures[icon.NameFirst]
	
	icon:SetTexture(TMW:GetConfigIconTexture(icon))

	icon:SetScript("OnUpdate", Buff_OnUpdate)
	icon:OnUpdate(TMW.time)
end

TMW:RegisterIconType(Type)

