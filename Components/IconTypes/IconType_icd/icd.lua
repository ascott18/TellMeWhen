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
local UnitGUID = 
	  UnitGUID

local GetSpellTexture = TMW.GetSpellTexture
local strlowerCache = TMW.strlowerCache

local pGUID = nil -- UnitGUID() returns nil at load time, so we set this later.


local Type = TMW.Classes.IconType:New("icd")
Type.name = L["ICONMENU_ICD"]
Type.desc = L["ICONMENU_ICD_DESC"]
Type.menuIcon = GetSpellTexture(28093)
Type.usePocketWatch = 1
Type.DurationSyntax = 1
Type.hasNoGCD = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("start, duration")
Type:UsesAttributes("spell")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes



Type:RegisterIconDefaults{
	-- Determines what will trigger the start of the internal cooldown.
	-- Values are "aura", "spellcast", or "caststart"
	ICDType					= "aura",

	-- True if the icon should not refresh its timer
	-- if a trigger is found while the timer is already running.
	DontRefresh				= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "spellwithduration",
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 		},
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_ICDType", function(self)
	self.Header:SetText(TMW.L["ICONMENU_ICDTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 1,
		{
			setting = "ICDType",
			value = "aura",
			title = TMW.L["ICONMENU_ICDBDE"],
			tooltip = TMW.L["ICONMENU_ICDAURA_DESC"],
		},
		{
			setting = "ICDType",
			value = "spellcast",
			title = TMW.L["ICONMENU_SPELLCAST_COMPLETE"],
			tooltip = TMW.L["ICONMENU_SPELLCAST_COMPLETE_DESC"],
		},
		{
			setting = "ICDType",
			value = "caststart",
			title = TMW.L["ICONMENU_SPELLCAST_START"],
			tooltip = TMW.L["ICONMENU_SPELLCAST_START_DESC"],
		},
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_ICDSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "DontRefresh",
			title = L["ICONMENU_DONTREFRESH"],
			tooltip = L["ICONMENU_DONTREFRESH_DESC"],
		},
	})
end)


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- UnitGUID() returns nil at load time, so we need to run this later in order to get pGUID.
	-- TMW_GLOBAL_UPDATE is good enough.
	pGUID = UnitGUID("player")
end)


local function ICD_OnEvent(icon, event, ...)
	local valid, spellID, spellName, _

	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local cevent, GUID
		_, cevent, _, GUID, _, _, _, _, _, _, _, spellID, spellName = ...

		valid = GUID == pGUID and (
			cevent == "SPELL_AURA_APPLIED" or
			cevent == "SPELL_AURA_REFRESH" or
			cevent == "SPELL_ENERGIZE" or
			cevent == "SPELL_AURA_APPLIED_DOSE" or
			cevent == "SPELL_SUMMON" or
			cevent == "SPELL_DAMAGE" or
			cevent == "SPELL_MISSED"
		)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then
		local unit
		unit, spellName, _, _, spellID = ...

		valid = unit == "player"
	end

	if valid then
		local NameHash = icon.Spells.Hash
		local Key = NameHash[spellID] or NameHash[strlowerCache[spellName]]
		if Key and not (icon.DontRefresh and (TMW.time - icon.ICDStartTime) < icon.Spells.Durations[Key]) then
			-- Make sure we don't reset a running timer if we shouldn't.
			-- If everything is good, record the data about this event and schedule an icon update.

			icon.ICDStartTime = TMW.time
			icon.ICDDuration = icon.Spells.Durations[Key]
			icon:SetInfo("spell; texture", 
				icon.ICDID,
				GetSpellTexture(spellID)
			)
			icon.NextUpdateTime = 0
		end
	end
end

local function ICD_OnUpdate(icon, time)

	local ICDStartTime = icon.ICDStartTime
	local ICDDuration = icon.ICDDuration

	if time - ICDStartTime > ICDDuration then
		-- If the timer has expire, used the timer-expired alpha.
		icon:SetInfo("alpha; start, duration",
			icon.Alpha,
			0, 0
		)
	else
		-- If the timer is still running, use the timer-running alpha.
		icon:SetInfo("alpha; start, duration",
			icon.UnAlpha,
			ICDStartTime, ICDDuration
		)
	end
end

function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)

	icon.ICDStartTime = icon.ICDStartTime or 0
	icon.ICDDuration = icon.ICDDuration or 0

	icon:SetInfo("texture", Type:GetConfigIconTexture(icon))



	-- Setup events and update functions.
	if icon.ICDType == "spellcast" then
		icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	elseif icon.ICDType == "caststart" then
		icon:RegisterEvent("UNIT_SPELLCAST_START")
		icon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	elseif icon.ICDType == "aura" then
		icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	icon:SetScript("OnEvent", ICD_OnEvent)

	icon:SetUpdateMethod("manual")
	
	icon:SetUpdateFunction(ICD_OnUpdate)
	icon:Update()
end


Type:Register(50)