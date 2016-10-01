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

local pGUID
local _, pclass = UnitClass("Player")
local GetSpellTexture = TMW.GetSpellTexture
local strlowerCache = TMW.strlowerCache

local Type = TMW.Classes.IconType:New("guardian")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_GUARDIAN"]
Type.desc = L["ICONMENU_GUARDIAN_DESC"]
Type.menuIcon = GetSpellTexture(211158)
Type.usePocketWatch = 1
Type.AllowNoName = true
Type.hasNoGCD = true
Type.canControlGroup = true
Type.hidden = pclass ~= "WARLOCK"

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_HIDE
local STATE_PRESENT_EMPOWERED = "g_emp" 

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:RegisterIconDefaults{
	States = {
		[STATE_PRESENT_EMPOWERED] = {Alpha = 1}
	},

	-- Pick what duration to show.
	-- "guardian" will only show the duration of the guardian.
	-- "empower" will only show the duration of empower.
	-- "either" will show one or the other.
	GuardianDuration		= "guardian"
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "guardian",
	noBreakdown = true,
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	text = L["ICONMENU_GUARDIAN_CHOOSENAME_DESC"],
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_GuardianDuration", function(self)
	self:SetTitle(TMW.L["ICONMENU_GUARDIAN_DUR"])
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 3,
		function(check)
			check:SetTexts(L["ICONMENU_GUARDIAN_DUR_GUARDIAN"], nil)
			check:SetSetting("GuardianDuration", "guardian")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_GUARDIAN_DUR_EMPOWER"], nil)
			check:SetSetting("GuardianDuration", "empower")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_GUARDIAN_DUR_EITHER"], L["ICONMENU_GUARDIAN_DUR_EITHER_DESC"])
			check:SetSetting("GuardianDuration", "either")
		end,
	})
end)

if pclass == "WARLOCK" then
	Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
		[ STATE_PRESENT_EMPOWERED  ] = { order = 1, text = "|cFF00FF00" .. L["ICONMENU_PRESENT"] .. " - " .. L["ICONMENU_GUARDIAN_EMPOWERED"],  },
		[ STATE_PRESENT ] = { order = 2, text = "|cFF00FF00" .. L["ICONMENU_PRESENT"] .. " - " .. L["ICONMENU_GUARDIAN_UNEMPOWERED"], },
		[ STATE_ABSENT  ] = { order = 3, text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],  },
	})
else
	Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
		[ STATE_PRESENT ] = { order = 2, text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], },
		[ STATE_ABSENT  ] = { order = 3, text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],  },
	})
end


Type.GuardianInfo = {
	-- Dreadstalker
	[ 98035] = {
		duration = 12,
		texture = GetSpellTexture(104316),
		triggerSpell = 104316,
	}, 
	-- Wild Imp (Call Dreadstalkers w/ improved dreadstalkers)
	[ 99737] = {
		duration = 12,
		texture = GetSpellTexture(211158),
		triggerSpell = 196272,
	}, 
	-- Wild Imp (HoG)
	[ 55659] = {
		duration = 12,
		texture = GetSpellTexture(211158),
		triggerSpell = 105174,
	}, 
	-- Doomguard
	[ 11859] = {
		duration = 25,
		texture = GetSpellTexture(18540),
		triggerSpell = 18540,
	},  
	-- Infernal
	[    89] = {
		duration = 25,
		texture = GetSpellTexture(1122),
		triggerSpell = 1122,
	},
	-- Darkglare
	[103673] = {
		duration = 12,
		texture = GetSpellTexture(205180),
		triggerSpell = 205180,
	}, 
}
local GuardianInfo = Type.GuardianInfo

function Type:RefreshNames()
	for npcID, data in pairs(GuardianInfo) do
		if not data.nameKnown then
			local Parser, LT1 = TMW:GetParser()
			Parser:SetOwner(UIParent, "ANCHOR_NONE")
			Parser:SetHyperlink(("unit:Creature-0-0-0-0-%d"):format(npcID))
			local name = LT1:GetText()
			Parser:Hide()

			if not name or name == "" then
				name = "NPC ID " .. npcID
			else
				data.nameKnown = true
			end
			data.name = name
			data.nameLower = strlowerCache[name]
		end
	end
end

-- Holds all icons that we need to update.
-- Since the event handling for this icon type is all done by a single handler that operates on all icons,
-- we need to know which icons we need to queue an update for when something changes.
local ManualIcons = {}
local ManualIconsManager = TMW.Classes.UpdateTableManager:New()
ManualIconsManager:UpdateTable_Set(ManualIcons)

local function GetGuardianID(GUID)
	local id = tonumber(GUID:match(".-%-%d+%-%d+%-%d+%-%d+%-(%d+)") or 0)

	if GuardianInfo[id] then
		return id
	end
end

local Guardians = {}
Type.Guardians = Guardians -- for debugging
local Guardian = TMW:NewClass(){
	OnNewInstance = function(self, GUID, name)
		self.summonedAt = TMW.time
		self.GUID = GUID
		self.name = name
		self.nameLower = strlowerCache[name]
		self.empowerStart = 0
		self.empowerDuration = 0

		self.npcID = GetGuardianID(GUID)

		self.duration = GuardianInfo[self.npcID].duration
		self.texture = GuardianInfo[self.npcID].texture
	end,	

	Empower = function(self)
		local remaining = self.empowerDuration - (TMW.time - self.empowerStart)
		if remaining < 0 then remaining = 0 end

		-- Add the duration of empower to the remaining duration
		remaining = remaining + 12
		-- Cap off the duration at +30% (for refreshes)
		remaining = min(12*1.3, remaining)

		self.empowerStart = TMW.time
		self.empowerDuration = remaining
	end,
}



function Type:COMBAT_LOG_EVENT_UNFILTERED(e, _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID)
	if event == "SPELL_SUMMON" and GetGuardianID(destGUID) and sourceGUID == pGUID then
		Guardians[destGUID] = Guardian:New(destGUID, destName)
	elseif (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and sourceGUID == pGUID and spellID == 193396 then
		local Guardian = Guardians[destGUID]
		if Guardian then
			Guardian:Empower()
		end
	elseif event == "UNIT_DIED" then
		Guardians[destGUID] = nil
	else
		return
	end

	for k = 1, #ManualIcons do
		ManualIcons[k].NextUpdateTime = 0
	end
end

local function OnUpdate(icon, time)
	local NPCs = icon.NPCs.Array
	local presentAlpha = icon.States[STATE_PRESENT].Alpha
	local empowerAlpha = icon.States[STATE_PRESENT_EMPOWERED].Alpha


	local count = nil
	if not icon:IsControlled() then
		count = 0
		-- Non-controlled icons should show the number of active ones right on the icon.
		-- Controlled icons show this based on the number of icons shown.
		for _, Guardian in pairs(Guardians) do

			local empowerStart = Guardian.empowerStart
			local empowerDuration = Guardian.empowerDuration

			local empowerRemaining = empowerDuration - (time - empowerStart)

			-- If the guardian matches the icon's name/id filters, and it would be shown based on opacity filters,
			-- the include it in the count.
			if (icon.Name == "" or Guardian.nameLower == iName or Guardian.npcID == iName)
			and ((presentAlpha > 0 and empowerRemaining <= 0) or (empowerAlpha > 0 and empowerRemaining > 0)) then
				count = count + 1
			end
		end
	end

	-- Iterate in order that NPCs were inputted so that different types stay grouped together.
	-- Dummy max limit of 1 if there is no name filter.
	for i = 1, icon.Name == "" and 1 or #NPCs do
		local iName = NPCs[i]

		for GUID, Guardian in pairs(Guardians) do
			local start = Guardian.summonedAt
			local duration = Guardian.duration

			local remaining = duration - (time - start)

			if remaining > 0 then
				if icon.Name == "" or Guardian.nameLower == iName or Guardian.npcID == iName then

					local empowerStart = Guardian.empowerStart
					local empowerDuration = Guardian.empowerDuration

					local empowerRemaining = empowerDuration - (time - empowerStart)

					if icon.GuardianDuration == "guardian" then
						-- keep the start/duration from the guardian that are set above
					elseif icon.GuardianDuration == "empower" then
						start, duration = empowerStart, empowerDuration
					else
						-- Show empower if appropriate - otherwise show the guardian's timer.
						if empowerRemaining > 0 and remaining > empowerRemaining then
							-- There is longer on the guardian than there is on empower. Show empower.
							start, duration = empowerStart, empowerDuration
						end
					end

					if empowerRemaining > 0 then
						if empowerAlpha > 0 and not icon:YieldInfo(true, STATE_PRESENT_EMPOWERED, start, duration, Guardian.texture, count) then
							return
						end
					else
						if presentAlpha > 0 and not icon:YieldInfo(true, STATE_PRESENT, start, duration, Guardian.texture, count) then
							return
						end
					end
				end
			end
		end
	end

	icon:YieldInfo(false)
end

function Type:HandleYieldedInfo(icon, iconToSet, state, start, duration, texture, count)
	if state then
		iconToSet:SetInfo("state; texture; start, duration; stack, stackText",
			state,
			texture,
			start, duration,
			count, count
		)
	else
		iconToSet:SetInfo("state; texture; start, duration; stack, stackText",
			STATE_ABSENT,
			icon.FirstTexture,
			0, 0,
			nil, nil
		)
	end
end




function Type:Setup(icon)
	-- Get "Spells"
	icon.NPCs = TMW:GetSpells(icon.Name, false)

	icon.FirstTexture = self:GuessIconTexture(icon:GetSettings())

	icon:SetInfo("texture; reverse", icon.FirstTexture, true)
	
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	TMW:RegisterCallback("TMW_ICON_DISABLE", Type)
	TMW:RegisterCallback("TMW_GLOBAL_UPDATE", Type)
	TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", Type)

	icon:SetUpdateMethod("manual")
	ManualIconsManager:UpdateTable_Register(icon)
	icon:SetUpdateFunction(OnUpdate)

	icon:Update()
end



function Type:TMW_ONUPDATE_TIMECONSTRAINED_PRE(event, time)
	local needUpdate = false

	for GUID, Guardian in pairs(Guardians) do
		local remaining = Guardian.duration - (time - Guardian.summonedAt)
		if remaining <= 0 then
			Guardians[GUID] = nil
			needUpdate = true
		end
	end

	if needUpdate then
		for k = 1, #ManualIcons do
			ManualIcons[k].NextUpdateTime = 0
		end
	end
end

function Type:TMW_GLOBAL_UPDATE()
	-- UnitGUID() returns nil at load time, so we need to run this later in order to get pGUID.
	-- TMW_GLOBAL_UPDATE is good enough.
	pGUID = UnitGUID("player")
	Type:RefreshNames()

	Type:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function Type:TMW_ICON_DISABLE(event, icon)
	ManualIconsManager:UpdateTable_Unregister(icon)
end

function Type:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local NPCs = TMW:GetSpells(ics.Name, false)

		for _, name in ipairs(NPCs.Array) do
			if type(name) == "number" and GuardianInfo[name] then
				return GuardianInfo[name].texture
			elseif type(name) == "string" then
				for k, v in pairs(GuardianInfo) do
					if v.nameLower == name then
						return v.texture
					end
				end
			end
		end
	end

	return "Interface\\Icons\\INV_Misc_PocketWatch_01"
end

	
Type:Register(119)

