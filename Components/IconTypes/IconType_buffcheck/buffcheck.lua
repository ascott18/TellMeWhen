-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local tonumber, pairs =
	  tonumber, pairs
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex

local GetSpellTexture = TMW.GetSpellTexture
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber
local empty = {}

local Type = TMW.Classes.IconType:New("buffcheck")
Type.name = L["ICONMENU_BUFFCHECK"]
Type.desc = L["ICONMENU_BUFFCHECK_DESC"]
Type.menuIcon = GetSpellTexture(111922) or GetSpellTexture(1243)
Type.usePocketWatch = 1
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_HIDE
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_SHOW

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("reverse")
Type:UsesAttributes("auraSourceUnit, auraSourceGUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)



Type:RegisterIconDefaults{
	-- The unit(s) to check for auras
	Unit					= "player", 

	-- What type of aura to check for. Values are "HELPFUL" or "HARMFUL".
	-- "EITHER" is not supported by this icon type, although this setting is shared with Buff/Debuff icon types.
	BuffOrDebuff			= "HELPFUL", 

	-- Only check auras casted by the player. Appends "|PLAYER" to the UnitAura filter.
	OnlyMine				= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "buffNoDS",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_BuffOrDebuff2", function(self)
	self:SetTitle(TMW.L["ICONMENU_BUFFTYPE"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 2,
		function(check)
			check:SetTexts("|cFF00FF00" .. L["ICONMENU_BUFF"], nil)
			check:SetSetting("BuffOrDebuff", "HELPFUL")
		end,
		function(check)
			check:SetTexts("|cFFFF0000" .. L["ICONMENU_DEBUFF"], nil)
			check:SetSetting("BuffOrDebuff", "HARMFUL")
		end,
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(125, "TellMeWhen_BuffCheckSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_ONLYMINE"], L["ICONMENU_ONLYMINE_DESC"])
			check:SetSetting("OnlyMine")
		end,
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_ABSENT] =  { text = "|cFFFF0000" .. L["ICONMENU_ABSENTONANY"],	tooltipText = L["ICONMENU_ABSENTONANY_DESC"],	},
	[STATE_PRESENT] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONALL"],	tooltipText = L["ICONMENU_PRESENTONALL_DESC"], 	},
})



local function Buff_OnEvent(icon, event, arg1, arg2, arg3)
	if event == icon.auraEvent and icon.UnitSet.UnitsLookup[arg1] then
		-- Used by Dragonflight+

		-- arg2: updatedAuras = { [name | id | dispelType] = mightBeMine(bool) }
		if arg2 then
			local Hash, OnlyMine = icon.Spells.Hash, icon.OnlyMine
			for identifier, mightBeMine in next, arg2 do
				if Hash[identifier] and (mightBeMine or not OnlyMine) then
					icon.NextUpdateTime = 0
					return
				end
			end
		else
			icon.NextUpdateTime = 0
		end
	elseif event == icon.UnitSet.event then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	end
end

local huge = math.huge
local function BuffCheck_OnUpdate(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local Units, Hash, Filter
	= icon.Units, icon.Spells.Hash, icon.Filter
	
	local AbsentAlpha = icon.States[STATE_ABSENT].Alpha
	local PresentAlpha = icon.States[STATE_PRESENT].Alpha

	-- These variables will hold all the attributes that we pass to YieldInfo().
	local foundInstance, foundUnit
	local curSortDur = huge

	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		-- Also don't check dead units since the point of this icon type is to check for
		-- raid members that are missing raid buffs.
		if icon.UnitSet:UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			
			local foundOnUnit = false
			for index = 1, huge do
				local instance = GetAuraDataByIndex(unit, index, Filter)
				if not instance then
					-- No more auras on the unit. Break spell loop.
					break
				elseif Hash[instance.spellId] or Hash[strlowerCache[instance.name]] then
					foundOnUnit = true
					local remaining = (instance.expirationTime == 0 and huge) or ((instance.expirationTime - time) / instance.timeMod)

					-- This icon type automatically sorts by lowest duration.
					if not foundInstance or remaining < curSortDur then
						-- If we haven't found anything yet, or if this aura beats the previous by sort order, then use it.
						foundInstance = instance
						foundUnit = unit
						curSortDur = remaining
					end

					if PresentAlpha == 0 then
						-- We aren't displaying present auras,
						-- so don't bother continuing to look after we've found something.
						break
					end
				end
			end

			if not foundOnUnit and AbsentAlpha > 0 and not icon:YieldInfo(true, unit) then
				-- If we didn't find a matching aura, and the icon is set to show when we don't find something
				-- then report what unit it was. This is the primary point of the icon - to find units that are missing everything.
				-- If icon:YieldInfo() returns false, it means we don't need to keep harvesting data.
				return
			end
		end
	end

	-- We didn't find any units that were missing all the auras being checked.
	-- So, report the lowest duration aura that we did find.
	icon:YieldInfo(false, foundUnit, foundInstance)
end

local GetAuras = TMW.COMMON.Auras.GetAuras
local function BuffCheck_OnUpdate_Packed(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local Units, SpellsArray, KindKey
		= icon.Units, icon.Spells.Array, icon.KindKey
	local NotOnlyMine = not icon.OnlyMine
	
	local AbsentAlpha = icon.States[STATE_ABSENT].Alpha
	local PresentAlpha = icon.States[STATE_PRESENT].Alpha

	-- These variables will hold all the attributes that we pass to YieldInfo().
	local foundInstance, foundUnit
	local curSortDur = huge

	for u = 1, #Units do
		local unit = Units[u]
		-- UnitSet:UnitExists(unit) is an improved UnitExists() that returns early if the unit
		-- is known by TMW.UNITS to definitely exist.
		-- Also don't check dead units since the point of this icon type is to check for
		-- raid members that are missing raid buffs.
		if icon.UnitSet:UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			local auras = GetAuras(unit)
			local lookup, instances = auras.lookup, auras.instances
			
			local foundOnUnit = false
			
			for i = 1, #SpellsArray do
				local spell = SpellsArray[i]
				for auraInstanceID, isMine in next, auras.lookup[spell] or empty do
					local instance = instances[auraInstanceID]

					if 
						(not KindKey or instance[KindKey])
					and	(NotOnlyMine or isMine)
					then
						foundOnUnit = true
						local remaining = (instance.expirationTime == 0 and huge) or ((instance.expirationTime - time) / instance.timeMod)
	
						-- If we haven't found anything yet, or if this aura beats the previous by sort order, then use it.
						if not foundInstance or remaining < curSortDur then
							foundInstance = instance
							foundUnit = unit
							curSortDur = remaining
						end

						if PresentAlpha == 0 then
							-- We aren't displaying present auras,
							-- so don't bother continuing to look after we've found something.
							break
						end
					end
				end

				if foundOnUnit and PresentAlpha == 0 then
					-- We aren't displaying present auras,
					-- so don't bother continuing to look after we've found something.
					break
				end
			end

			if not foundOnUnit and AbsentAlpha > 0 and not icon:YieldInfo(true, unit) then
				-- If we didn't find a matching aura, and the icon is set to show when we don't find something
				-- then report what unit it was. This is the primary point of the icon - to find units that are missing everything.
				-- If icon:YieldInfo() returns false, it means we don't need to keep harvesting data.
				return
			end
		end
	end

	-- We didn't find any units that were missing all the auras being checked.
	-- So, report the lowest duration aura that we did find.
	if foundInstance then
		icon:YieldInfo(false, foundUnit, foundInstance)
	else
		icon:YieldInfo(false, nil)
	end
end

function Type:HandleYieldedInfo(icon, iconToSet, unit, instance)
	if not unit then
		-- Unit is nil if the icon didn't check any living units.
		iconToSet:SetInfo("state; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			0,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.Spells.First,
			nil, nil,
			nil, nil
		)
	elseif not instance then
		-- ID is nil if we found a unit that is missing all of the auras that are being checked for.
		iconToSet:SetInfo("state; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			STATE_ABSENT,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.Spells.First,
			unit, nil,
			nil, nil
		)
	elseif instance then
		-- ID is defined if we didn't find any units that are missing all the auras being checked for.
		-- In this case, the data is for the first matching aura found on the first unit checked.
		iconToSet:SetInfo("state; texture; start, duration, modRate; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			STATE_PRESENT,
			instance.icon,
			instance.expirationTime - instance.duration, instance.duration, instance.timeMod,
			instance.applications, instance.applications,
			instance.spellId,
			unit, nil,
			instance.sourceUnit, nil
		)
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)


	-- This icon can't check both buffs and debuffs, but it reuses this setting from buff/debuff icons.
	-- So, if it is set to EITHER, then reset it to HELPFUL.
	if icon.BuffOrDebuff == "EITHER" then
		icon:GetSettings().BuffOrDebuff = "HELPFUL"
		icon.BuffOrDebuff = "HELPFUL"
	end
	

	-- Setup the filter that will be used by UnitAura in the icon's update function.
	icon.Filter = icon.BuffOrDebuff
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
	end



	icon.FirstTexture = GetSpellTexture(icon.Spells.First)

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)
	


	-- Setup events and update functions.
	icon:SetUpdateFunction(BuffCheck_OnUpdate)
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		icon:SetScript("OnEvent", Buff_OnEvent)
		icon:RegisterEvent(icon.UnitSet.event)

		local canUsePacked, auraEvent = TMW.COMMON.Auras:RequestUnits(icon.UnitSet)
		icon.auraEvent = auraEvent
		icon:RegisterEvent(auraEvent)

		if canUsePacked then
			icon:SetUpdateFunction(BuffCheck_OnUpdate_Packed)
		end
	end

	icon:Update()
end
	
Type:Register(101)

