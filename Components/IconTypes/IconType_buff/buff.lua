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
local tonumber, pairs, type, format, select =
	  tonumber, pairs, type, format, select
local UnitAura =
	  UnitAura

local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber

-- GLOBALS: TellMeWhen_ChooseName


local Type = TMW.Classes.IconType:New("buff")
Type.name = L["ICONMENU_BUFFDEBUFF"]
Type.desc = L["ICONMENU_BUFFDEBUFF_DESC"]
Type.menuIcon = GetSpellTexture(774)
Type.usePocketWatch = 1
Type.menuSpaceBefore = true
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
	-- Sort the auras found by duration
	Sort					= false,

	-- Sort the aruas found by stacks
	StackSort				= false,

	-- The unit(s) to check for auras
	Unit					= "player", 

	-- What type of aura to check for. Values are "HELPFUL", "HARMFUL", or "EITHER".
	-- EITHER is handled specially by TMW by having looping a second time for a second filter (FilterH in the code).
	BuffOrDebuff			= "HELPFUL", 

	-- Only check stealable auras. This DOES function for non-mages.
	Stealable				= false,

	-- Show variable text. This is the extra return values at the end of UnitAura.
	-- It includes things like the strength of a shield spell. 
	-- The first non-zero value from those variables will be reported as the icon's stack count.
	ShowTTText				= false,

	-- Only check auras casted by the player. Appends "|PLAYER" to the UnitAura filter.
	OnlyMine				= false,

	-- Hide the icon if TMW's unit system left icon.Units empty.
	-- This can happen, for example, if checking only raid units while not in a raid.
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

	self.ShowTTText = TMW.C.Config_DropDownMenu:New("Frame", "$parentShowTTText", self, "TMW_DropDownMenuTemplate", nil, {
		title = L["ICONMENU_SHOWTTTEXT2"],
		tooltip = L["ICONMENU_SHOWTTTEXT_DESC2"],
		clickFunc = function(button, arg1)
			TMW.CI.ics.ShowTTText = arg1
			TMW.IE:Load(1)
		end,
		func = function(self)
			local info = TMW.DD:CreateInfo()
			info.text = L["ICONMENU_SHOWTTTEXT_STACKS"]
			info.tooltipTitle = info.text
			info.tooltipText = L["ICONMENU_SHOWTTTEXT_STACKS_DESC"]
			info.func = self.data.clickFunc
			info.arg1 = false
			info.checked = info.arg1 == TMW.CI.ics.ShowTTText
			TMW.DD:AddButton(info)

			local info = TMW.DD:CreateInfo()
			info.text = L["ICONMENU_SHOWTTTEXT_FIRST"]
			info.tooltipTitle = info.text
			info.tooltipText = L["ICONMENU_SHOWTTTEXT_FIRST_DESC"]
			info.func = self.data.clickFunc
			info.arg1 = true
			info.checked = info.arg1 == TMW.CI.ics.ShowTTText
			TMW.DD:AddButton(info)

			TMW.DD:AddSpacer()

			for _, var in TMW:Vararg(1, 2, 3) do
				local info = TMW.DD:CreateInfo()
				info.text = L["ICONMENU_SHOWTTTEXT_VAR"]:format(var)
				info.tooltipTitle = info.text
				info.tooltipText = L["ICONMENU_SHOWTTTEXT_VAR_DESC"]
				info.func = self.data.clickFunc
				info.arg1 = var
				info.checked = info.arg1 == TMW.CI.ics.ShowTTText
				TMW.DD:AddButton(info)
			end
		end,
	})
	self.ShowTTText:SetWidth(135)
	self.ShowTTText:SetDropdownAnchor("TOPRIGHT", self.ShowTTText.Middle, "BOTTOMRIGHT")
	TMW.IE:DistributeFrameAnchorsLaterally(self, 2, self.HideIfNoUnits, self.ShowTTText)
	self.HideIfNoUnits:ConstrainLabel(self.ShowTTText)
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



local NOT_ACTUALLY_SPELLSTEALABLE = {
	-- Nice API, Blizzard. <3

	[43438] = true,	-- Ice Block
	[642] = true,	-- Divine Shield
}


local function Buff_OnEvent(icon, event, arg1)
	if event == "UNIT_AURA" then
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

local huge = math.huge
local function Buff_OnUpdate(icon, time)
	
	-- Upvalue things that will be referenced a lot in our loops.
	local Units, NameArray, NameStringArray, NameHash, Filter, Filterh, DurationSort, StackSort
	= icon.Units, icon.Spells.Array, icon.Spells.StringArray, icon.Spells.Hash, icon.Filter, icon.Filterh, icon.Sort, icon.StackSort
	local NotStealable = not icon.Stealable

	-- These variables will hold all the attributes that we pass to YieldInfo().
	local buffName, iconTexture, duration, expirationTime, caster, count, canSteal, id, v1, v2, v3, useUnit, _

	local doesSort = DurationSort or StackSort

	-- Initial values for the vars that track the duration/stack of the aura that currently occupies buffName and related locals.
	-- If we are sorting by smallest duration, we intitialize these to math.huge so that the first thing we find is definitely smaller.
	local curSortDur = DurationSort == -1 and huge or 0
	local curSortStacks = StackSort == -1 and huge or -1
	
	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		if icon.UnitSet:UnitExists(unit) then

			if icon.buffdebuff_iterateByAuraIndex then
				-- If we are sorting, or if the icon's number of auras checked exceeds the efficiency threshold, or if we are checking dispel types,
				-- then check every aura on the unit instead of checking the unit for every aura we are checking.
				

				local index, stage = 1, 1
				local useFilter = Filter

				while true do
					local _buffName, _, _iconTexture, _count, _dispelType, _duration, _expirationTime, _caster, canSteal, _, _id, _, _, _, _v1, _v2, _v3 = UnitAura(unit, index, useFilter)
					index = index + 1
					
					-- Bugfix: Enraged is an empty string.
					if _dispelType == "" then
						_dispelType = "Enraged"
					end

					if not _buffName then
						-- If we reached the end of auras found for Filter, and icon.BuffOrDebuff == "EITHER", switch to Filterh
						-- iff we sort or haven't found anything yet.
						if stage == 1 and Filterh and (doesSort or not buffName) then
							index, stage = 1, 2
							useFilter = Filterh
						else
							-- Break UnitAura loop (while true do ...)
							break
						end

					elseif (NameHash[_id] or NameHash[_dispelType] or NameHash[strlowerCache[_buffName]]) and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[_id])) then
						if DurationSort then
							local remaining = (_expirationTime == 0 and huge) or _expirationTime - time

							if not buffName or curSortDur*DurationSort < remaining*DurationSort then
								-- DurationSort is either 1 or -1, so multiply by it to get the correct ordering. (multiplying by a negative flips inequalities)
								-- If we haven't found anything yet, or if this aura beats the previous by sort order, then use it.
								 buffName,  iconTexture,  count,  duration,  expirationTime,  caster,  id,  v1,  v2,  v3, useUnit, curSortDur =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _caster, _id, _v1, _v2, _v3, unit,    remaining
							end
						elseif StackSort then
							local stack = _count or 0

							if not buffName or curSortStacks*StackSort < stack*StackSort then
								-- StackSort is either 1 or -1, so multiply by it to get the correct ordering. (multiplying by a negative flips inequalities)
								-- If we haven't found anything yet, or if this aura beats the previous by sort order, then use it.
								 buffName,  iconTexture,  count,  duration,  expirationTime,  caster,  id,  v1,  v2,  v3, useUnit, curSortStacks =
								_buffName, _iconTexture, _count, _duration, _expirationTime, _caster, _id, _v1, _v2, _v3, unit,    stack
							end
						else
							-- We aren't sorting, and we haven't found anything yet, so record this
							 buffName,  iconTexture,  count,  duration,  expirationTime,  caster,  id,  v1,  v2,  v3, useUnit =
							_buffName, _iconTexture, _count, _duration, _expirationTime, _caster, _id, _v1, _v2, _v3, unit

							-- We don't need to look for anything else. Stop looking.
							break
						end
					end
				end


				if buffName and not doesSort then
					break --  break unit loop
				end
			else

				for i = 1, #NameArray do
					local iName = NameArray[i]

					buffName, _, iconTexture, count, _, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3 = UnitAura(unit, NameStringArray[i], nil, Filter)
					if Filterh and not buffName then
						buffName, _, iconTexture, count, _, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3 = UnitAura(unit, NameStringArray[i], nil, Filterh)
					end

					if buffName and id ~= iName and isNumber[iName] then
						-- We got a match by name, but we were checking by ID and the match doesn't match by ID,
						-- so iterate over the unit's auras and find a matching ID.

						local index, stage = 1, 1
						local useFilter = Filter

						while true do
							buffName, _, iconTexture, count, _, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3 = UnitAura(unit, index, useFilter)
							index = index + 1

							if not id then
								-- If we reached the end of auras found for Filter, and icon.BuffOrDebuff == "EITHER", switch to Filterh
								-- iff we sort or haven't found anything yet.
								if stage == 1 and Filterh then
									index, stage = 1, 2
									useFilter = Filterh
								else
									-- Break while true loop (inner spell loop)
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
						-- We found a spell that will work for us.
						-- This half of the code doesn't handle sorting or anything,
						-- so break out of the loops right away.
						useUnit = unit
						break -- break spell loop
					end
				end
				if useUnit then
					break --  break unit loop
				end
			end
		end
	end
	
	icon:YieldInfo(true, useUnit, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3)
end

local function Buff_OnUpdate_Controller(icon, time)
	
	-- Upvalue things that will be used in our loops.
	local Units, NameFirst, NameHash, Filter, Filterh
	= icon.Units, icon.Spells.First, icon.Spells.Hash, icon.Filter, icon.Filterh
	local NotStealable = not icon.Stealable
	
	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		if icon.UnitSet:UnitExists(unit) then

			local index, stage = 1, 1
			local filter = Filter

			while true do
				local buffName, _, iconTexture, count, dispelType, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3 = UnitAura(unit, index, filter)
				index = index + 1
				
				-- Bugfix: Enraged is an empty string.
				if dispelType == "" then
					dispelType = "Enraged"
				end

				if not buffName then
					-- If we reached the end of auras found for filter, and icon.BuffOrDebuff == "EITHER", switch to Filterh
					-- iff we sort or haven't found anything yet.
					if stage == 1 and Filterh and not buffName then
						index, stage = 1, 2
						filter = Filterh
					else
						break
					end

				elseif  (NameFirst == '' or NameHash[id] or NameHash[dispelType] or NameHash[strlowerCache[buffName]])
					and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[id]))
				then
					
					if not icon:YieldInfo(true, unit, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3) then
						-- YieldInfo returns true if we need to keep harvesting data. Otherwise, it returns false.
						return
					end
				end
			end
		end
	end

	-- Signal the group controller that we are at the end of our data harvesting.
	icon:YieldInfo(false)
end
function Type:HandleYieldedInfo(icon, iconToSet, unit, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3)
	local Units = icon.Units

	-- Check that unit is defined here in order to determine if we found something.
	-- If icon.buffdebuff_iterateByAuraIndex == false, the code there might return a buffName
	-- that shouldn't actually be used because it didn't pass checks for stealable.
	-- Unit is only defined there (as useUnit) once something is found that definitely matches.
	-- It is a bit bad that the code works this way, but it is nicer than manually nilling out all of the yielded info
	-- after determining that no matching auras were found.
	if unit then
		if icon.ShowTTText then
			if icon.ShowTTText == true then
				if v1 and v1 > 0 then
					count = v1
				elseif v2 and v2 > 0 then
					count = v2
				elseif v3 and v3 > 0 then
					count = v3
				else
					count = 0
				end
			else
				-- icon.ShowTTText is a number if it isn't false and it isn't true
				count = select(icon.ShowTTText, v1, v2, v3)
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
			icon.Spells.First,
			nil, nil,
			nil, nil
		)

	else
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			icon.UnAlpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.Spells.First,
			Units[1], nil,
			nil, nil
		)
	end
end

local aurasWithNoSourceReported = {
	-- Mists:
	GetSpellInfo(104993),	-- Jade Spirit
	GetSpellInfo(116660),	-- River's Song
	GetSpellInfo(120032),	-- Dancing Steel
	GetSpellInfo(116631),	-- Colossus
	GetSpellInfo(104423),	-- Windsong
	GetSpellInfo(109085),	-- Blastington's

	-- Warlords:
	GetSpellInfo(156060),	-- Megawatt Filament
	GetSpellInfo(156055),	-- Oglethorpe's Missile Splitter
	GetSpellInfo(173288),	-- Hemet's Heartseeker (maybe unused?)
	GetSpellInfo(159679),	-- Mark of Blackrock
	GetSpellInfo(159678),	-- Mark of Shadowmoon
	GetSpellInfo(159676),	-- Mark of the Frostwolf
	GetSpellInfo(159239),	-- Mark of the Shattered Hand
	GetSpellInfo(159234),	-- Mark of the Thunderlord
	GetSpellInfo(159675),	-- Mark of Warsong
	nil,	-- Terminate with nil to prevent all Warsong's return values from filling the table
}



-- This IDP is used to hold the source of the aura being repoted by the icon. Used by the [AuraSource] DogTag.
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
	icon.Spells = TMW:GetSpells(icon.Name, false)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)


	-- Setup the filters for UnitAura.
	-- Filterh is used as the filter in a second loop through if the icon is checking both buffs and debuffs.
	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = icon.BuffOrDebuff == "EITHER" and "HARMFUL"
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end



	icon.buffdebuff_iterateByAuraIndex = false

	-- Sorting is only handled if this value is true.
	-- EffThreshold is a value that determines if we will switch to iterating by index instead of
	-- iterating by spell if we are checking a large number of spells.
	if icon.DurationSort or icon.StackSort or #icon.Spells.Array > TMW.db.profile.EffThreshold then
		icon.buffdebuff_iterateByAuraIndex = true
	end

	for k, spell in pairs(icon.Spells.StringArray) do
		if TMW.DS[spell] then
			-- Dispel types are only handled in the part of the code that is ran if this var is true.
			icon.buffdebuff_iterateByAuraIndex = true
		end
	end



	-- There are lots of spells (RPPM enchants) that don't report a source.
	-- Because of this, you can't track them while OnlyMine is enabled.
	-- So, tell the user about this so I can stop getting millions of comments from confused people.
	-- GLOBALS: TellMeWhen_ChooseName
	if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
		TMW.HELP:Hide("ICONTYPE_BUFF_NOSOURCERPPM")
		if icon.OnlyMine then
			for _, badSpell in pairs(aurasWithNoSourceReported) do
				if type(badSpell) == "string" and icon.Spells.StringHash[badSpell:lower()] then
					TMW.HELP:Show{
						code = "ICONTYPE_BUFF_NOSOURCERPPM",
						codeOrder = 2,
						icon = icon,
						relativeTo = TellMeWhen_ChooseName,
						x = 0,
						y = 0,
						text = format(L["HELP_BUFF_NOSOURCERPPM"], badSpell)
					}
					break
				end
			end
		end
	end



	icon.FirstTexture = SpellTextures[icon.Spells.First]

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)
	


	-- Setup events and update functions.
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
	
Type:Register(100)

