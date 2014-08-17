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

local EFF_THRESHOLD, DS
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
Type.canControlGroup = true
Type.name = L["ICONMENU_BUFFDEBUFF"]
Type.desc = L["ICONMENU_BUFFDEBUFF_DESC"]
Type.menuIcon = GetSpellTexture(774)
Type.usePocketWatch = 1
Type.spacebefore = true
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("spell")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("reverse")
Type:UsesAttributes("auraSourceUnit, auraSourceGUID")
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
	OnSetup = function(self, panelInfo, supplementalData)
		if TMW.CI.icon:IsGroupController() then
			self:SetLabels(L["ICONMENU_CHOOSENAME2"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"], nil)
		else
			self:SetLabels(L["ICONMENU_CHOOSENAME2"], nil)
		end
	end,

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
	[ 0x2 ] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONANY"], 	tooltipText = L["ICONMENU_PRESENTONANY_DESC"],	},
	[ 0x1 ] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENTONALL"], 	tooltipText = L["ICONMENU_ABSENTONALL_DESC"],	},
})

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettingsWithStacks", {
	hidden = function(self)
		return TMW.CI.icon:IsGroupController()
	end,
})


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	EFF_THRESHOLD = TMW.db.profile.EffThreshold
	DS = TMW.DS
	unitsWithExistsEvent = TMW.UNITS.unitsWithExistsEvent
end)


local NOT_ACTUALLY_SPELLSTEALABLE = {
	[43438] = true,	-- Ice Block
	[642] = true,	-- Divine Shield
}


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
	
	local Units, NameArray, NameStringArray, NameHash, Filter, Filterh, DurationSort, StackSort
	= icon.Units, icon.Names.Array, icon.Names.StringArray, icon.Names.Hash, icon.Filter, icon.Filterh, icon.Sort, icon.StackSort
	local NotStealable = not icon.Stealable
	local NAL = #icon.Names.Array

	local buffName, _, iconTexture, dispelType, duration, expirationTime, caster, count, canSteal, id, v1, v2, v3, v4
	local useUnit

	local doesSort = DurationSort or StackSort
	local d = DurationSort == -1 and huge or 0
	local s = StackSort == -1 and huge or -1
	
	for u = 1, #Units do
		local unit = Units[u]
		if icon.UnitSet:UnitExists(unit) then

			if icon.buffdebuff_iterateByAuraIndex then
				-- If we are sorting, or if the icon's number of auras checked exceeds EFF_THRESHOLD, or if we are checking dispel types
				-- then check every aura on the unit instead of checking the unit for every aura we are checking.
				

				local index, stage = 1, 1
				local filter = Filter

				while true do
					local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _caster, canSteal, _, _id, _, _, _, _v1, _v2, _v3, _v4 = UnitAura(unit, index, filter)
					index = index + 1
					
					-- Bugfix: Enraged is an empty string.
					if _dispelType == "" then
						_dispelType = "Enraged"
					end

					if not _buffName then
						if stage == 1 and Filterh and (doesSort or not buffName) then
							index, stage = 1, 2
							filter = Filterh
						else
							break
						end

					elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[_id])) then
						if DurationSort then
							local _d = (_expirationTime == 0 and huge) or _expirationTime - time

							if not buffName or d*DurationSort < _d*DurationSort then
								-- If we haven't found anything yet, or if this aura beats the previous by sort order, then use it.
								 buffName,  iconTexture,  count,  duration,  expirationTime,  caster,  id,  v1,  v2,  v3,  v4, useUnit, d =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _caster, _id, _v1, _v2, _v3, _v4, unit,   _d
							end
						elseif StackSort then
							local _s = _count or 0

							if not buffName or s*StackSort < _s*StackSort then
								-- If we haven't found anything yet, or if this aura beats the previous by sort order, then use it.
								 buffName,  iconTexture,  count,  duration,  expirationTime,  caster,  id,  v1,  v2,  v3,  v4, useUnit, s =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _caster, _id, _v1, _v2, _v3, _v4, unit,   _s
							end
						else
							-- We aren't sorting, and we haven't found anything yet, so record this
							 buffName,  iconTexture,  count,  duration,  expirationTime,  caster,  id,  v1,  v2,  v3,  v4, useUnit =
							_buffName, _iconTexture, _count, _duration, _expirationTime, _caster, _id, _v1, _v2, _v3, _v4, unit

							-- We don't need to look for anything else. Stop looking.
							break
						end
					end
				end


				if buffName and not doesSort then
					break --  break unit loop
				end
			else

				for i = 1, NAL do
					local iName = NameArray[i]

					buffName, _, iconTexture, count, _, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, NameStringArray[i], nil, Filter)
					if Filterh and not buffName then
						buffName, _, iconTexture, count, _, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, NameStringArray[i], nil, Filterh)
					end

					if buffName and id ~= iName and isNumber[iName] then
						-- We got a match by name, but we were checking by ID and the match doesn't match by ID,
						-- so iterate over the unit's auras and find a matching ID.

						local index, stage = 1, 1
						local filter = Filter

						while true do
							buffName, _, iconTexture, count, _, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, index, Filter)
							index = index + 1

							if not id then
								if stage == 1 and Filterh then
									index, stage = 1, 2
									filter = Filterh
								else
									break
								end
							elseif id == iName then -- and (NotStealable or canSteal) then
									-- No reason to check stealable here.
									-- It will be checked right before breaking the loop.
									-- Once it finds an ID match, any spell of that ID will have the same stealable status as any other,
									-- so just match ID and dont check for stealable here.
								break
							end
						end
					end

					if buffName and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[id])) then
						useUnit = unit
						break -- break spell loop
					end
				end
				if buffName and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[id])) then
					break --  break unit loop
				end
			end
		end
	end
	
	icon:YieldInfo(true, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3, v4, useUnit)
end

local function Buff_OnUpdate_Controller(icon, time)
	
	local Units, NameHash, Filter, Filterh
	= icon.Units, icon.Names.Hash, icon.Filter, icon.Filterh
	local NotStealable = not icon.Stealable
	
	for u = 1, #Units do
		local unit = Units[u]
		if icon.UnitSet:UnitExists(unit) then

			local index, stage = 1, 1
			local filter = Filter

			while true do
				local buffName, _, iconTexture, count, dispelType, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, index, filter)
				index = index + 1
				
				-- Bugfix: Enraged is an empty string.
				if dispelType == "" then
					dispelType = "Enraged"
				end

				if not buffName then
					if stage == 1 and Filterh and not buffName then
						index, stage = 1, 2
						filter = Filterh
					else
						break
					end

				elseif  (icon.Names.First == '' or NameHash[id] or NameHash[dispelType] or NameHash[strlowerCache[buffName]])
					and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[id]))
				then
					
					if not icon:YieldInfo(true, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3, v4, unit) then
						return
					end
				end
			end
		end
	end

	icon:YieldInfo(false)
end
function Type:HandleYieldedInfo(icon, iconToSet, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3, v4, unit)
	local Units = icon.Units
	if buffName then
		if icon.ShowTTText then
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

		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			icon.Alpha,
			iconTexture,
			expirationTime - duration, duration,
			count, count,
			id,
			unit, nil,
			caster, nil
		)

	elseif not Units[1] and icon.HideIfNoUnits then
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			0,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.Names.First,
			nil, nil,
			nil, nil
		)

	else
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			icon.UnAlpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.Names.First,
			Units[1], nil,
			nil, nil
		)
	end
end

local aurasWithNoSourceReported = {
	TMW_GetSpellInfo(104993),	-- Jade Spirit
	TMW_GetSpellInfo(116660),	-- River's Song
	TMW_GetSpellInfo(120032),	-- Dancing Steel
	TMW_GetSpellInfo(116631),	-- Colossus
	TMW_GetSpellInfo(104423),	-- Windsong
	nil,	-- Terminate with nil to prevent all Windsong's return values from filling the table
}


local Processor = TMW.Classes.IconDataProcessor:New("BUFF_SOURCEUNIT", "auraSourceUnit, auraSourceGUID")
function Processor:CompileFunctionSegment(t)
	-- GLOBALS: auraSourceUnit, auraSourceGUID
	t[#t+1] = [[
	
	auraSourceGUID = auraSourceGUID or (unit and (unit == "player" and playerGUID or UnitGUID(unit)))
	
	if attributes.auraSourceUnit ~= auraSourceUnit or attributes.auraSourceGUID ~= auraSourceGUID then
		attributes.auraSourceUnit = auraSourceUnit
		attributes.auraSourceGUID = auraSourceGUID
		
		TMW:Fire(BUFF_SOURCEUNIT.changedEvent, icon, auraSourceUnit, auraSourceGUID)
		doFireIconUpdated = true
	end
	--]]
end
Processor:RegisterDogTag("TMW", "AuraSource", {
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]
		
		if icon then
			if icon.Type ~= "buff" then
				return ""
			else
				return icon.attributes.auraSourceUnit or ""
			end
		else
			return ""
		end
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("BUFF_SOURCEUNIT"),
	ret = "string",
	doc = L["DT_DOC_AuraSource"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = ('[AuraSource] => "target"; [AuraSource:Name] => "Kobold"; [AuraSource(icon="TMW:icon:1I7MnrXDCz8T")] => %q; [AuraSource(icon="TMW:icon:1I7MnrXDCz8T"):Name] => %q'):format(UnitName("player"), TMW.NAMES and TMW.NAMES:TryToAcquireName("player", true) or "???"),
	category = L["ICON"],
})



function Type:Setup(icon)
	icon.Names = TMW:GetSpellNamesProxy(icon.Name, false)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = icon.BuffOrDebuff == "EITHER" and "HARMFUL"
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end

	local isEditing
	if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
		TMW.HELP:Hide("ICONTYPE_BUFF_NOSOURCERPPM")
		isEditing = true
	end

	icon.buffdebuff_iterateByAuraIndex = false
	if doesSort or #icon.Names.Array > EFF_THRESHOLD then
		icon.buffdebuff_iterateByAuraIndex = true
	end

	for k, spell in pairs(icon.Names.StringArray) do
		if icon.OnlyMine and isEditing then
			for _, badSpell in pairs(aurasWithNoSourceReported) do
				if type(badSpell) == "string" and badSpell:lower() == spell then
					TMW.HELP:Show{
						code = "ICONTYPE_BUFF_NOSOURCERPPM",
						codeOrder = 2,
						icon = icon,
						relativeTo = TellMeWhen_ChooseName,
						x = 0,
						y = 0,
						text = format(L["HELP_BUFF_NOSOURCERPPM"], TMW:RestoreCase(icon.Names.Array[k]))
					}
					break
				end
			end
		end

		if TMW.DS[spell] then
			icon.buffdebuff_iterateByAuraIndex = true
		end
	end

	icon.FirstTexture = SpellTextures[icon.Names.First]

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

	if icon:IsGroupController() then
		icon:SetUpdateFunction(Buff_OnUpdate_Controller)
	else
		icon:SetUpdateFunction(Buff_OnUpdate)
	end

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

