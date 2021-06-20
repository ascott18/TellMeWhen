-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

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
Type.menuIcon = GetSpellTexture(31687)
Type.usePocketWatch = 1
Type.AllowNoName = true
Type.hasNoGCD = true
Type.canControlGroup = true

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_HIDE

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:RegisterIconDefaults{
	States = {
	},

	-- Sort the guardians by duration
	Sort					= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "guardian",
	noBreakdown = true,
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	text = L["ICONMENU_GUARDIAN_CHOOSENAME_DESC"],
})

Type:RegisterConfigPanel_ConstructorFunc(170, "TellMeWhen_GuardianSortSettings", function(self)
	self:SetTitle(TMW.L["SORTBY"])

	self:BuildSimpleCheckSettingFrame({
		numPerRow = 3,
		function(check)
			check:SetTexts(TMW.L["SORTBYNONE"], TMW.L["SORTBYNONE_DESC"])
			check:SetSetting("Sort", false)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTASC"], TMW.L["ICONMENU_SORTASC_DESC"])
			check:SetSetting("Sort", -1)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTDESC"], TMW.L["ICONMENU_SORTDESC_DESC"])
			check:SetSetting("Sort", 1)
		end,
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[ STATE_PRESENT ] = { order = 2, text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], },
	[ STATE_ABSENT  ] = { order = 3, text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],  },
})

local function Info(duration, spell, triggerMatch, extraData)
	local data = {
		duration = duration,
		texture = GetSpellTexture(spell),
		triggerSpell = spell,
		triggerMustMatch = triggerMatch,
	}
	if extraData then
		for k, v in pairs(extraData) do
			data[k] = v
		end
	end
	return data
end

Type.GuardianInfo = {
	[510] = Info(45, 31687, false), -- Water Elemental
	[19668] = Info(15, 34433, false), -- Shadowfiend
	[15438] = Info(120, 32982, false), -- Fire ele totem
	[15352] = Info(120, 2062, false), -- Earth ele totem
	[89] = Info(60 * 5, 1122, false), -- Inferno (warlock)
	[1964] = Info(30, 33831, false, { countable = true }), -- Treants (force of nature, druid)
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

local function GetNPCID(GUID)
	local id = tonumber(GUID:match(".-%-%d+%-%d+%-%d+%-%d+%-(%d+)") or 0)
	return id
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

		self.npcID = GetNPCID(GUID)
		local info = GuardianInfo[self.npcID]
		self.info = info

		self.countable = info.countable
		self.duration = info.duration
		self.texture = info.texture
	end,

	Empower = function(self)
		self.duration = self.duration + 15
		self.empowerStart = TMW.time
		self.empowerDuration = 15
	end,

	GetTimeRemaining = function(self)
		local start = self.summonedAt
		local duration = self.duration

		local guardianRemaining = duration - (TMW.time - start)

		if guardianRemaining > 0 then
			local displayedRemaining = guardianRemaining

			return start, duration, displayedRemaining, guardianRemaining
		else
			return 0, 0, 0, 0
		end
	end,
}



function Type:COMBAT_LOG_EVENT_UNFILTERED(e)
	local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
	
	if event == "SPELL_SUMMON" then
		local npcID = GetNPCID(destGUID)
		local info = GuardianInfo[npcID]
		if info and sourceGUID == pGUID and (spellID == info.triggerSpell or not info.triggerMustMatch) then
			Guardians[destGUID] = Guardian:New(destGUID, destName)
		else
			return
		end
	elseif event == "UNIT_DIED" or event == "SPELL_INSTAKILL" then
		Guardians[destGUID] = nil
	else
		-- Sometimes on the first summon after logging in, the name of a guardian will be "Unknown" in the log.
		-- If it was wrong and we're now seeing the correct name (because the guardian did something), then correct it.
		local existingGuardian = Guardians[sourceGUID]
		if existingGuardian and existingGuardian.name == UNKNOWN and sourceName ~= UNKNOWN then
			print("fixed guardian name", sourceName)
			existingGuardian.name = sourceName
			existingGuardian.nameLower = strlowerCache[sourceName]
		else
			-- Don't fall through and trigger icon updates.
			return
		end
	end

	for k = 1, #ManualIcons do
		ManualIcons[k].NextUpdateTime = 0
	end
end

local function YieldMatchedGuardian(icon, count, Guardian)
	local presentAlpha = icon.States[STATE_PRESENT].Alpha
	local start, duration, displayedRemaining, guardianRemaining = Guardian:GetTimeRemaining()
	if guardianRemaining > 0 then

		if presentAlpha > 0 and not icon:YieldInfo(true, STATE_PRESENT, start, duration, Guardian.texture, Guardian.countable and count or nil) then
			return false
		end
	end
	return true
end

local function OnUpdate(icon, time)
	local NameHash = icon.NPCs.Hash
	local presentAlpha = icon.States[STATE_PRESENT].Alpha

	local count = nil
	if not icon:IsGroupController() then
		count = 0
		-- Non-controlled icons should show the number of active ones right on the icon.
		-- Controlled icons show this based on the number of icons shown.

		for _, Guardian in pairs(Guardians) do

			-- If the guardian matches the icon's name/id filters, and it would be shown based on opacity filters,
			-- the include it in the count.
			if (icon.Name == "" or NameHash[Guardian.nameLower] or NameHash[Guardian.npcID]) then
				local _, _, _, guardianRemaining = Guardian:GetTimeRemaining()

				if ((presentAlpha > 0 and guardianRemaining > 0)) then
					count = count + 1
				end
			end
		end
	end

	if icon.Sort == false then
		-- Iterate in order that NPCs were inputted so that different types stay grouped together.
		-- Dummy max limit of 1 if there is no name filter.

		local NPCs = icon.NPCs.Array
		for i = 1, icon.Name == "" and 1 or #NPCs do
			local iName = NPCs[i]

			for GUID, Guardian in pairs(Guardians) do
				if icon.Name == "" or Guardian.nameLower == iName or Guardian.npcID == iName then
					if not YieldMatchedGuardian(icon, count, Guardian) then
						return
					end
				end
			end
		end
	else
		for GUID, Guardian in TMW:OrderedPairs(Guardians, icon.GuardianCompareFunc, true) do
			if icon.Name == "" or NameHash[Guardian.nameLower] or NameHash[Guardian.npcID] then
				if not YieldMatchedGuardian(icon, count, Guardian) then
					return
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

	local sort = icon.Sort
	icon.GuardianCompareFunc = sort ~= false and function(a, b)
		local _, aRemain, bRemain
		local _, _, aRemain = a:GetTimeRemaining()
		local _, _, bRemain = b:GetTimeRemaining()

		return aRemain*sort > bRemain*sort
	end or nil
	
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	TMW:RegisterCallback("TMW_ICON_DISABLE", Type)
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

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- UnitGUID() returns nil at load time, so we need to run this later in order to get pGUID.
	-- TMW_GLOBAL_UPDATE is good enough.
	pGUID = UnitGUID("player")
	Type:RefreshNames()

	Type:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)

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

