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
local tonumber, pairs, format =
	  tonumber, pairs, format
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsVisible = UnitIsVisible
local GetAuraDuration = C_UnitAuras.GetAuraDuration

local Auras = TMW.COMMON.Auras
local GetAuraDataByIndex = Auras.GetAuraDataByIndex

local ShouldAurasBeSecret = C_Secrets and C_Secrets.ShouldAurasBeSecret

local GetSpellInfo = TMW.GetSpellInfo
local GetSpellTexture = TMW.GetSpellTexture
local strlowerCache = TMW.strlowerCache
local isNumber = TMW.isNumber
local empty = {}

local issecretvalue = TMW.issecretvalue
local clientHasSecrets = TMW.clientHasSecrets

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

	-- Hide the icon while auras are secret.
	HideWhileSecret			= false,
}



Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	-- The buffcheck suggester exists to steer toward spell IDs, which only buys anything where
	-- auras can be secret. Everywhere else a name is as good as an ID, so leave the shared
	-- module - and the insertion the user is used to - alone.
	SUGType = clientHasSecrets and "buffcheck" or "buffNoDS",
})

if clientHasSecrets then
	Auras.RegisterSecrecyPanel(Type, 102, "TellMeWhen_BuffCheckSecrets")
end

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
		function(check)
			-- Its own description: the shared one explains the setting as a workaround for TMW
			-- not being able to tell whether an aura will be secret, which it now can.
			check:SetTexts(L["ICONMENU_HIDEWHILESECRET"], L["ICONMENU_HIDEWHILESECRET_BUFFCHECK_DESC"])
			check:SetSetting("HideWhileSecret")
			check:SetShown(clientHasSecrets)
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
	if icon.HideWhileSecret and C_Secrets.ShouldAurasBeSecret() then
		-- Force hide icon
		icon:YieldInfo(false, nil)
		return
	end

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
				elseif issecretvalue(instance.spellId) then
					-- Skip secret auras
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

local GetAuras = Auras.GetAuras
local function BuffCheck_OnUpdate_Packed(icon, time)
	-- Gated on there actually being a spell we can't read rather than on being
	-- restricted at all: an icon whose spells are every one of them readable does
	-- its whole job under restriction, and hiding it would throw that away.
	if icon.HideWhileSecret and icon.HasUnreadableSpell and ShouldAurasBeSecret() then
		-- Force hide icon
		icon:YieldInfo(false, nil)
		return
	end

	-- Upvalue things that will be referenced a lot in our loops.
	local Units, SpellsArray, KindKey
		= icon.Units, icon.Spells.Array, icon.KindKey
	local NotOnlyMine = not icon.OnlyMine

	-- While restricted, Auras backs the lookups below with GetUnitAuraBySpellID
	-- and GetAuraDataBySpellName, which return nothing "if querying a unit that is
	-- not visible (eg. party members on other maps)". Unchecked that reads here as
	-- "missing every buff", which is this icon type's entire output.
	local requireVisible = clientHasSecrets and ShouldAurasBeSecret()

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
		if icon.UnitSet:UnitExists(unit) and not UnitIsDeadOrGhost(unit)
		and (not requireVisible or UnitIsVisible(unit)) then
			local auras = GetAuras(unit)
			local lookup, instances = auras.lookup, auras.instances
			
			local foundOnUnit = false
			
			for i = 1, #SpellsArray do
				local spell = SpellsArray[i]
				for auraInstanceID, isMine in next, lookup[spell] do
					local instance = instances[auraInstanceID]

					if 
						(not KindKey or instance[KindKey])
					and	(NotOnlyMine or isMine)
					then
						foundOnUnit = true
						local remaining = 
							(issecretvalue(instance.expirationTime) and huge) or
							(instance.expirationTime == 0 and huge) or
							((instance.expirationTime - time) / instance.timeMod)
	
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

		local start, durObj
		if clientHasSecrets and ShouldAurasBeSecret() then
			-- GetAuraDuration is off limits outright while auras are restricted: it's guarded by
			-- RequiresUnitAuraAccess, a blanket "does this caller get aura data at all" check
			-- that errors for tainted callers - not the per-aura RequiresNonSecretAura that let
			-- us read this instance in the first place. Every path that yields an instance while
			-- restricted found it non-secret, so its own timing values are real numbers.
			if issecretvalue(instance.duration) then
				-- Match secret state of unknown start so secret tests don't mismatch between start + duration
				start = secretwrap(0)
				-- Ensure non-nil durObj so we don't attempt SetCooldown with secrets.
				durObj = C_DurationUtil.CreateDuration()
			else
				start = instance.expirationTime - instance.duration
			end
		elseif clientHasSecrets then
			durObj = GetAuraDuration(unit, instance.auraInstanceID)
			if durObj then
				start = durObj:GetStartTime()
			else
				start = 0
				if issecretvalue(instance.duration) then
					-- Match secret state of unknown start so secret tests don't mismatch between start + duration
					start = secretwrap(start)
					-- Ensure non-nil durObj so we don't attempt SetCooldown with secrets.
					durObj = C_DurationUtil.CreateDuration()
				end
			end
		else
			start = instance.expirationTime - instance.duration
		end

		-- ID is defined if we didn't find any units that are missing all the auras being checked for.
		-- In this case, the data is for the first matching aura found on the first unit checked.
		iconToSet:SetInfo("state; texture; start, duration, modRate, durObj; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			STATE_PRESENT,
			instance.icon,
			start, instance.duration, instance.timeMod, durObj,
			instance.applications, instance.applications,
			instance.spellId,
			unit, nil,
			instance.sourceUnit, nil
		)
	end
end

function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)
	if not clientHasSecrets then
		icon.HideWhileSecret = false
	end
	
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

	-- The AuraData field that says an aura is the kind we're checking for, for the paths that
	-- test an instance instead of passing a filter string to the game.
	icon.KindKey = nil
	if icon.BuffOrDebuff == "HELPFUL" then
		icon.KindKey = "isHelpful"
	elseif icon.BuffOrDebuff == "HARMFUL" then
		icon.KindKey = "isHarmful"
	end

	-- Whether any entry is one the game won't let us read under restriction. That belongs to the
	-- spells rather than to the current restriction state, so it resolves once here.
	icon.HasUnreadableSpell = false
	if clientHasSecrets then
		icon.HasUnreadableSpell = Auras.HasUnreadableSpell(icon.Name)

		-- A name this client can't resolve to a spell ID - another class's buff, most likely,
		-- since name lookups only cover spells you know. Already counted as unreadable above;
		-- found again here because the warning needs to name the entry.
		local array = icon.Spells.ArrayNoLower
		local unresolved
		for i = 1, #array do
			local identifier = array[i]
			if type(identifier) ~= "number" and not select(7, GetSpellInfo(identifier)) then
				unresolved = identifier
				break
			end
		end

		-- An entry that doesn't resolve is one the config panel can't classify, and one the
		-- name lookup can't match either. Point at the field naming it, since nothing about the
		-- icon's behaviour would otherwise say why it never finds that spell.
		-- GLOBALS: TellMeWhen_ChooseName
		if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
			TMW.HELP:Hide("ICONTYPE_BUFFCHECK_NAMENOTID")
			if unresolved then
				TMW.HELP:Show{
					code = "ICONTYPE_BUFFCHECK_NAMENOTID",
					codeOrder = 2,
					icon = icon,
					relativeTo = TellMeWhen_ChooseName,
					x = 0,
					y = 0,
					text = format(L["HELP_BUFFCHECK_NAMENOTID"], tostring(unresolved))
				}
			end
		end
	end



	icon.FirstTexture = GetSpellTexture(icon.Spells.First)

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)
	


	-- Setup events and update functions.
	icon:SetUpdateFunction(BuffCheck_OnUpdate)
	if icon.UnitSet.allUnitsChangeOnEvent and icon.Enabled then
		icon:SetUpdateMethod("manual")
		icon:SetScript("OnEvent", Buff_OnEvent)
		icon:RegisterEvent(icon.UnitSet.event)

		local canUsePacked, auraEvent = Auras:RequestUnits(icon.UnitSet)
		icon.auraEvent = auraEvent
		icon:RegisterEvent(auraEvent)

		if canUsePacked then
			icon:SetUpdateFunction(BuffCheck_OnUpdate_Packed)
		end
	end

	icon:Update()
end
	
Type:Register(212)

