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
local GetAuraDataByIndex = TMW.COMMON.Auras.GetAuraDataByIndex

-- Aura lookups by identifier, which survive secrets in a way enumeration doesn't: both are
-- guarded by RequiresNonSecretAura, which returns no values instead of erroring, so a spell
-- Blizzard flags as never secret reads back as real data even under restrictions.
local GetUnitAuraBySpellID = C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID
local GetAuraDataBySpellName = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
local ShouldAurasBeSecret = C_Secrets and C_Secrets.ShouldAurasBeSecret
local GetSpellAuraSecrecy = C_Secrets and C_Secrets.GetSpellAuraSecrecy
local SECRECY_NEVER = Enum.SecrecyLevel and Enum.SecrecyLevel.NeverSecret

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



-- Report, per entry, whether Blizzard lets us read that spell's aura while auras are secret -
-- which is what decides whether the icon may ever call it MISSING. Mirrors what Setup does, so
-- what the panel claims is what the update function will actually do: an entry is readable only
-- when it resolves to a spell ID that Blizzard flags never secret. Returns two lists of display
-- strings, the readable ones and the rest (each with its reason).
--
-- Deliberately not routed through SpellCache, even though the icon editor has it and could name
-- the spell behind an ID the runtime can't resolve: what matters here is what Setup will
-- actually manage at runtime, and telling the user otherwise would be a nicer-looking lie.
local function ClassifySpellsForConfig(spellString)
	local array = TMW:GetSpells(spellString, false).ArrayNoLower
	local readable, unreadable = {}, {}

	for i = 1, #array do
		local identifier = array[i]

		-- Fill in whichever half of the pair wasn't typed, so every row reads "Name (ID)".
		-- ID -> name always works; name -> ID only for spells this character knows, which is
		-- the whole thing this panel is here to report.
		local name, spellID
		if type(identifier) == "number" then
			spellID = identifier
			name = GetSpellInfo(identifier)
		else
			name = identifier
			spellID = select(7, GetSpellInfo(identifier))
		end

		local label = (name and spellID and name .. " (" .. spellID .. ")") or tostring(identifier)

		if not spellID then
			-- A name this character's client can't resolve - another class's buff, usually.
			unreadable[#unreadable + 1] = label .. " |cff808080- " .. L["UIPANEL_BUFFCHECK_SECRETS_UNRESOLVED"] .. "|r"
		elseif GetSpellAuraSecrecy(spellID) ~= SECRECY_NEVER then
			unreadable[#unreadable + 1] = label .. " |cff808080- " .. L["UIPANEL_BUFFCHECK_SECRETS_RESTRICTED"] .. "|r"
		else
			readable[#readable + 1] = label
		end
	end

	return readable, unreadable
end

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	-- The buffcheck suggester exists to steer toward spell IDs, which only buys anything where
	-- auras can be secret. Everywhere else a name is as good as an ID, so leave the shared
	-- module - and the insertion the user is used to - alone.
	SUGType = clientHasSecrets and "buffcheck" or "buffNoDS",
})

-- Below the name field, not above it: every line of it is about what was entered there.
if clientHasSecrets then
	Type:RegisterConfigPanel_XMLTemplate(102, "TellMeWhen_TextPanel", {
		frameName = "TellMeWhen_BuffCheckSecrets",
		OnSetup = function(self)
			-- Not the shared "Restricted in Combat" title: the panel is a breakdown, and most of
			-- the time the answer it gives is that nothing here is restricted.
			self:SetTitle(L["UIPANEL_BUFFCHECK_SECRETS_TITLE"])

			-- Recomputed on every reload rather than set once: the verdict is per spell, and the
			-- spell list changes as the user types into the name box.
			self:CScriptAdd("ReloadRequested", function(panel)
				-- Read from the settings rather than from icon.Spells: this fires while the name
				-- box is being edited, before the icon has been set up again.
				local readable, unreadable = ClassifySpellsForConfig(TMW.CI.ics.Name)

				-- Same two headings whatever the spell list holds, so the panel reads as a
				-- breakdown rather than as a verdict that appears only when something is wrong.
				-- A heading with nothing under it is dropped.
				local sections = {}
				if #unreadable > 0 then
					sections[#sections + 1] = "|cffff5959" .. L["UIPANEL_BUFFCHECK_SECRETS_UNREADABLE"] .. "|r\r\n"
						.. table.concat(unreadable, "\r\n")
				end
				if #readable > 0 then
					sections[#sections + 1] = "|cff00ff00" .. L["UIPANEL_BUFFCHECK_SECRETS_READABLE"] .. "|r\r\n"
						.. table.concat(readable, "\r\n")
				end

				panel.text:SetText(table.concat(sections, "\r\n\r\n"))
			end)
		end,
	})
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

local GetAuras = TMW.COMMON.Auras.GetAuras
local function BuffCheck_OnUpdate_Packed(icon, time)
	if icon.HideWhileSecret and C_Secrets.ShouldAurasBeSecret() then
		-- Force hide icon
		icon:YieldInfo(false, nil)
		return
	end

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

-- Enumerating a unit's auras finds nothing that's secret, and this icon type's whole job -
-- deciding a unit is MISSING something - can't be built on an enumeration that silently drops
-- entries: the loops above skip every secret aura, so under restrictions they conclude that
-- every unit is missing everything.
--
-- Looking each tracked spell up by identifier survives that. GetUnitAuraBySpellID and
-- GetAuraDataBySpellName are guarded by RequiresNonSecretAura, which returns no values rather
-- than raising a blocked-action error, so a spell Blizzard flags as never secret (raid buffs
-- and the like) reads back as real, comparable data even inside an instance.
--
-- An aura that comes back is present, full stop. It's the nil that's ambiguous - absent, or
-- present but unreadable - so a unit is reported as missing something only when every nil it
-- produced came from a spell we know we were allowed to read.
--
-- Only reached from the dispatcher below, and only while auras are restricted. That's what
-- makes the readable test a bare comparison against NeverSecret: under restrictions, that flag
-- is the only thing that keeps a spell readable.
local function BuffCheck_OnUpdate_Identifiers(icon, time)
	if icon.HideWhileSecret and icon.HasUnreadableSpell then
		-- Force hide icon. Gated on there actually being a spell we can't read rather than on
		-- being restricted at all: an icon whose spells are every one of them readable does its
		-- whole job in here, and hiding it would be throwing that away for nothing.
		icon:YieldInfo(false, nil)
		return
	end

	-- Upvalue things that will be referenced a lot in our loops.
	local Units, Identifiers, Secrecy, Filter, KindKey
		= icon.Units, icon.SpellIdentifiers, icon.SpellSecrecy, icon.Filter, icon.KindKey
	local NotOnlyMine = not icon.OnlyMine

	local AbsentAlpha = icon.States[STATE_ABSENT].Alpha
	local PresentAlpha = icon.States[STATE_PRESENT].Alpha

	-- These variables will hold all the attributes that we pass to YieldInfo().
	local foundInstance, foundUnit
	local curSortDur = huge

	for u = 1, #Units do
		local unit = Units[u]
		-- The existence and death checks the enumerating paths do, plus visibility.
		-- GetUnitAuraBySpellID is documented as also returning nil "if querying a unit that is
		-- not visible (eg. party members on other maps)", which would otherwise read here as
		-- "missing every buff". GetAuraDataBySpellName carries no such note, but it's the same
		-- lookup by a different key, so assume the same of it.
		if icon.UnitSet:UnitExists(unit) and UnitIsVisible(unit) and not UnitIsDeadOrGhost(unit) then

			local foundOnUnit = false
			-- Cleared by any spell we can't tell present from absent, which bars this unit
			-- from being reported as missing anything.
			local allReadable = true

			for i = 1, #Identifiers do
				-- Ask regardless of what we believe about the spell's secrecy: an answer that
				-- comes back is proof enough that the aura was readable, whatever we guessed.
				--
				-- A name only matches when this client can resolve it, the same limit that stops
				-- Setup from classifying it - GetAuraDataBySpellName finds nothing for another
				-- class's buff even when the aura is demonstrably there and the ID would find it.
				-- So an unresolvable name contributes nothing here, and the config panel says so.
				local identifier = Identifiers[i]
				local instance
				if type(identifier) == "number" then
					-- Takes no filter, so the kind/source tests happen below - and it returns
					-- only the FIRST instance, so a second copy from a different caster is
					-- invisible to OnlyMine.
					instance = GetUnitAuraBySpellID(unit, identifier)
				else
					instance = GetAuraDataBySpellName(unit, identifier, Filter)
				end

				if instance then
					if (not KindKey or instance[KindKey])
					and (NotOnlyMine or instance.sourceUnit == "player")
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
							-- We aren't displaying present auras, so don't bother continuing to
							-- look after we've found something. allReadable no longer matters -
							-- this unit isn't missing everything, so it can't be reported absent.
							break
						end
					end
				elseif Secrecy[i] ~= SECRECY_NEVER then
					-- Nothing came back, and nothing promises this spell was readable, so absent
					-- and present-but-secret can't be told apart. (A spell we resolved as never
					-- secret falls through: its nil is a real absence.)
					allReadable = false
				end
			end

			if not foundOnUnit and allReadable and AbsentAlpha > 0 and not icon:YieldInfo(true, unit) then
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

-- Whether auras are secret follows combat and instances, not settings, so the choice between
-- enumerating and looking up by identifier can't be made once at setup. The enumerating paths
-- still do more wherever they can run - every instance of a spell rather than just the first,
-- and a spell entered as an ID matched against an aura with the same name - so they keep the
-- job for as long as they can actually see the auras.
local function BuffCheck_OnUpdate_Secretable(icon, time)
	if ShouldAurasBeSecret() then
		return BuffCheck_OnUpdate_Identifiers(icon, time)
	end
	return icon.EnumerationUpdateFunction(icon, time)
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

	-- What the by-identifier path looks each spell up by, plus the secrecy Blizzard assigns it.
	-- That level belongs to the spell, not to the current restriction state, so it resolves once
	-- here rather than per update.
	--
	-- A name this client can't resolve to a spell ID - another class's buff, most likely, since
	-- name lookups only cover spells you know - has no level to look up and stays nil. Such an
	-- entry is dead weight under restrictions: GetAuraDataBySpellName can't match it either, so
	-- it finds nothing AND blocks any absent report, since we can't prove what its nil meant.
	-- The config panel calls those out, which is the only real fix - use the spell ID.
	icon.SpellIdentifiers = nil
	icon.SpellSecrecy = nil
	if clientHasSecrets and GetUnitAuraBySpellID then
		local identifiers, secrecy = {}, {}
		local array = icon.Spells.ArrayNoLower
		for i = 1, #array do
			local identifier = array[i]

			local spellID = identifier
			if type(spellID) ~= "number" then
				-- GetAuraDataBySpellName matches case-sensitively, so prefer the game's own
				-- spelling over whatever case was typed. Only available for a name that
				-- resolves; the rest go in as typed, which is the best we have.
				local canonicalName, _, _, _, _, _, resolvedID = GetSpellInfo(identifier)
				if resolvedID then
					identifier = canonicalName
				end
				spellID = resolvedID
			end

			identifiers[i] = identifier
			if spellID then
				secrecy[i] = GetSpellAuraSecrecy(spellID)
			end
		end
		icon.SpellIdentifiers = identifiers
		icon.SpellSecrecy = secrecy

		-- One unreadable spell blocks the absent report for every unit (see allReadable), so the
		-- icon would keep showing "present" while only half checking. HideWhileSecret is the
		-- opt-out from that, and this is what it keys off.
		icon.HasUnreadableSpell = false
		for i = 1, #identifiers do
			if secrecy[i] ~= SECRECY_NEVER then
				icon.HasUnreadableSpell = true
				break
			end
		end

		-- An entry with no secrecy is one this client couldn't resolve, and the icon can never
		-- call it missing - which is the whole job. Point at the field naming the entry, since
		-- nothing about the icon's behaviour would otherwise say why it stopped reporting.
		-- GLOBALS: TellMeWhen_ChooseName
		if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
			TMW.HELP:Hide("ICONTYPE_BUFFCHECK_NAMENOTID")
			for i = 1, #identifiers do
				if not secrecy[i] then
					TMW.HELP:Show{
						code = "ICONTYPE_BUFFCHECK_NAMENOTID",
						codeOrder = 2,
						icon = icon,
						relativeTo = TellMeWhen_ChooseName,
						x = 0,
						y = 0,
						text = format(L["HELP_BUFFCHECK_NAMENOTID"], tostring(identifiers[i]))
					}
					break
				end
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

		local canUsePacked, auraEvent = TMW.COMMON.Auras:RequestUnits(icon.UnitSet)
		icon.auraEvent = auraEvent
		icon:RegisterEvent(auraEvent)

		if canUsePacked then
			icon:SetUpdateFunction(BuffCheck_OnUpdate_Packed)
		end
	end

	-- Hand whichever enumerating path was chosen to the dispatcher, which uses it while the
	-- auras are actually visible to us and falls back to identifier lookups when they aren't.
	if icon.SpellIdentifiers then
		icon.EnumerationUpdateFunction = icon.UpdateFunction
		icon:SetUpdateFunction(BuffCheck_OnUpdate_Secretable)
	end

	icon:Update()
end
	
Type:Register(212)

