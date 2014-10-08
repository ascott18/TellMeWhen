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
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local type, wipe, pairs, rawget =
	  type, wipe, pairs, rawget
local UnitGUID, IsInInstance =
	  UnitGUID, IsInInstance
local bit_band = bit.band

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local huge = math.huge

local pGUID = nil -- UnitGUID() returns nil at load time, so we set this later.

local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures



local Type = TMW.Classes.IconType:New("dotwatch")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_DOTWATCH"]
Type.desc = L["ICONMENU_DOTWATCH_DESC"]
Type.menuIcon = GetSpellTexture(589)
Type.usePocketWatch = 1
Type.unitType = "name"
Type.canControlGroup = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes



--Type:RegisterIconDefaults{}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	OnSetup = function(self, panelInfo, supplementalData)
		self:SetLabels(L["ICONMENU_CHOOSENAME2"], nil)
	end,

	SUGType = "buff",
})

--[[Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})]]

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[ 0x2 ] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONANY"], 	tooltipText = L["ICONMENU_PRESENTONANY_DESC"],	},
	[ 0x1 ] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENTONALL"], 	tooltipText = L["ICONMENU_ABSENTONALL_DESC"],	},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_DotwatchSettings", function(self)
	self.Header:SetText(Type.name)

	self.OnSetup = function(self, panelInfo, supplementalData)
		if TMW.CI.icon:IsGroupController() then
			self:Hide()
		else
			self:Show()
			self.Header:SetText("Make me a Group controller")
		end
	end
end)

--[[Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettings", {
	hidden = function(self)
		return TMW.CI.icon:IsGroupController()
	end,
})]]


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- UnitGUID() returns nil at load time, so we need to run this later in order to get pGUID.
	-- TMW_GLOBAL_UPDATE is good enough.
	pGUID = UnitGUID("player")
end)



-- Holds all unitcooldown icons whose update method is "manual" (not "auto")
-- Since the event handling for this icon type is all done by a single handler that operates on all icons,
-- we need to know which icons we need to queue an update for when something changes.
local ManualIcons = {}
local ManualIconsManager = TMW.Classes.UpdateTableManager:New()
ManualIconsManager:UpdateTable_Set(ManualIcons)


-- Holds the cooldowns of all known units. Structure is:
--[[ Cooldowns = {
	[GUID] = {
		[spellID] = lastCastTime,
		[spellName] = spellID,
		...
	},
	...
}
]]


local Auras = setmetatable({}, {__index = function(t, k)
	local n = {}
	t[k] = n
	return n
end})

--TODO: debug only
TMW.Auras = Auras

local BaseDurations = {[589] = 18}


local AllUnits = TMW:GetUnits(nil, [[
	player;
	mouseover;

	target;
	targettarget;
	targettargettarget;

	focus;
	focustarget;
	focustargettarget;

	pet;
	pettarget;
	pettargettarget;

	arena1-5;
	arena1-5target;
	arena1-5targettarget;

	boss1-5;
	boss1-5target;
	boss1-5targettarget;

	party1-4;
	party1-4target;
	party1-4targettarget;

	raid1-40;
	raid1-40target;
	raid1-40targettarget]]
)
local function ScanAllUnits(GUID, spellName, spellID)
	for i = 1, #AllUnits do
		local unit = AllUnits[i]
		if GUID == UnitGUID(unit) then
			buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, spellName, nil, "PLAYER")
			if not buffName then
				buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, spellName, nil, "HARMFUL|PLAYER")
			end

			if buffName and id ~= spellID then
				-- We got a match by name, but not by ID,
				-- so iterate over the unit's auras and find a matching ID.

				local index, stage = 1, 1
				local filter = "PLAYER"

				while true do
					buffName, _, _, _, _, duration, expirationTime, _, _, _, id = UnitAura(unit, index, Filter)
					index = index + 1

					if not id then
						-- If we reached the end of auras found for buffs, switch to debuffs
						if stage == 1 then
							index, stage = 1, 2
							filter = "HARMFUL|PLAYER"
						else
							-- Break while true loop (spell loop)
							break
						end
					end
				end
			end

			if id then
				-- Record the base duration of the aura for future use.
				BaseDurations[spellID] = duration

				return duration
			end

			return
		end
	end
end


C_Timer.NewTicker(30, function() 
	-- Cleanup function - occasionally get rid of units that aren't active.
	for GUID, auras in pairs(Auras) do
		if not next(auras) then
			Auras[GUID] = nil
		else
			local isGood = false
			for _, aura in pairs(auras) do
				if type(aura) == "table" and aura:Remaining() > 0 then
					isGood = true
					break
				end
			end
			if not isGood then
				Auras[GUID] = nil
			end
		end
	end
end)



local FALLBACK_DURATION = 15
local MAX_REFRESH_AMOUNT = 1.3

local Aura = TMW:NewClass("Aura"){
	spellID = 0,
	spellName = "",
	start = 0,
	duration = 0,
	unitName = "",
	GUID = "",

	OnNewInstance = function(self, spellID, destGUID, destName)
		self.GUID = destGUID
		self.unitName = destName

		self.spellID = spellID
		self.spellName = GetSpellInfo(spellID)
		self.start = TMW.time
		local duration = BaseDurations[spellID]
		if not duration then
			-- ScanAllUnits will try and determine the base duration of the effect.
			duration = ScanAllUnits(destGUID, self.spellName, spellID)
		end

		-- TODO: debug only.
		if not duration then
			print("using fallback duration for " .. spellID)
		end
		self.duration = duration or FALLBACK_DURATION
	end,

	Remaining = function(self)
		return self.duration - (TMW.time - self.start)
	end,

	Refresh = function(self)
		local base = BaseDurations[self.spellID] or FALLBACK_DURATION
		local remaining = self:Remaining()

		self.refreshed = true
		self.start = TMW.time
		self.duration = min(base*MAX_REFRESH_AMOUNT, remaining+base)
	end,
}
Aura:MakeInstancesWeak()


function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, cleuEvent, _, sourceGUID, _, _, _, destGUID, destName, _, _, spellID, spellName)
	if sourceGUID == pGUID 
	and	(cleuEvent == "SPELL_AURA_APPLIED"
	or cleuEvent == "SPELL_AURA_REFRESH"
	or cleuEvent == "SPELL_AURA_REMOVED")
	then
	
		spellName = spellName and strlowerCache[spellName]
		local aurasOnGUID = Auras[destGUID]

		if cleuEvent == "SPELL_AURA_REMOVED" then
			aurasOnGUID[spellName] = nil
			aurasOnGUID[spellID] = nil
		else
			-- Map the spellName to the spellID.
			aurasOnGUID[spellName] = spellID


			local aura = aurasOnGUID[spellID]

			if cleuEvent == "SPELL_AURA_REFRESH" then
				if not aura then
					error("no aura found for refresh of " .. spellName .. " " .. spellID)
				end

				aura:Refresh()
			else -- SPELL_AURA_APPLIED
				aura = Aura:New(spellID, destGUID, destName)
				aurasOnGUID[spellID] = aura
			end
		end

		-- Update any icons that are interested in the aura that we just handled
		for k = 1, #ManualIcons do
			local icon = ManualIcons[k]
			local NameHash = icon.Spells.Hash
			if NameHash and (NameHash[spellID] or NameHash[spellName]) then
				icon.NextUpdateTime = 0
			end
		end
			
	elseif cleuEvent == "UNIT_DIED" and destGUID then
		Auras[destGUID] = nil
	end
end



local function Dotwatch_OnUpdate_Controller(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local Alpha, UnAlpha, NameArray =
	icon.Alpha, icon.UnAlpha, icon.Spells.Array
		
	for GUID, auras in pairs(Auras) do
		local unit = nil
		for i = 1, #NameArray do
			local iName = NameArray[i]
			if not isNumber[iName] then
				-- spell name keys have values that are the spellid of the name,
				-- we need the spellid for the texture (thats why i did it like this)
				iName = auras[iName] or iName
			end

			local aura = auras[iName]

			if aura then
				local start = aura.start
				local duration = aura.duration

				local remaining = duration - (time - start)

				if remaining > 0 then
					if Alpha > 0 and not icon:YieldInfo(true, iName, start, duration, aura.unitName, GUID, Alpha) then
						-- YieldInfo returns true if we need to keep harvesting data. Otherwise, it returns false.
						return
					end

				else
					auras[iName] = nil
				end
			end
		end
	end

	-- Signal the group controller that we are at the end of our data harvesting.
	icon:YieldInfo(false)
end

function Type:HandleYieldedInfo(icon, iconToSet, name, start, duration, unit, GUID, alpha)
	if name then
		iconToSet:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			alpha,
			SpellTextures[name] or "Interface\\Icons\\INV_Misc_PocketWatch_01",
			start, duration,
			name,
			unit, GUID
		)
	else
		iconToSet:SetInfo("alpha; texture; start, duration; spell; unit, GUID",
			icon.UnAlpha,
			icon.FirstTexture,
			0, 0,
			icon.Spells.First,
			nil, nil
		)
	end
end


function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)	

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)


	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


	icon.FirstTexture = SpellTextures[icon.Spells.First]

	icon:SetUpdateMethod("manual")
	ManualIconsManager:UpdateTable_Register(icon)
		

	if icon:IsGroupController() then
		icon:SetUpdateFunction(Dotwatch_OnUpdate_Controller)
	else
		error("can't use dotwatch as a non-unit controller")
	--	icon:SetUpdateFunction(UnitCooldown_OnUpdate)
	end

	icon:Update()
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function(event, icon)
	Type:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end)

TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
	ManualIconsManager:UpdateTable_Unregister(icon)
end)

Type:Register(40)