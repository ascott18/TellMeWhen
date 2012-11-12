-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local strlower =
	  strlower
local print = TMW.print
local SpellTextures = TMW.SpellTextures

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New("icd")
Type.name = L["ICONMENU_ICD"]
Type.desc = L["ICONMENU_ICD_DESC"]
Type.usePocketWatch = 1
Type.DurationSyntax = 1

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("start, duration")
Type:UsesAttributes("spell")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	ICDType					= "aura",
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
	pGUID = UnitGUID("player")
end)


local function ICD_OnEvent(icon, event, ...)
	local valid, i, n, _
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local p, g -- make these local separate from i and n
		_, p, _, g, _, _, _, _, _, _, _, i, n = ...

		valid = g == pGUID and (p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_ENERGIZE" or p == "SPELL_AURA_APPLIED_DOSE" or p == "SPELL_SUMMON" or p == "SPELL_DAMAGE" or p == "SPELL_MISSED")
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then
		valid, n, _, _, i = ... -- I cheat. valid is actually a unitID here.

		valid = valid == "player"
	end

	if valid then
		local NameHash = icon.NameHash
		local Key = NameHash[i] or NameHash[strlowerCache[n]]
		if Key and not (icon.DontRefresh and (TMW.time - icon.ICDStartTime) < icon.Durations[Key]) then

			icon.ICDStartTime = TMW.time
			icon.ICDDuration = icon.Durations[Key]
			icon:SetInfo("spell; texture", 
				icon.ICDID,
				SpellTextures[i]
			)
			icon.NextUpdateTime = 0
		end
	end
end

local function ICD_OnUpdate(icon, time)

	local ICDStartTime = icon.ICDStartTime
	local ICDDuration = icon.ICDDuration

	if time - ICDStartTime > ICDDuration then
		icon:SetInfo("alpha; start, duration",
			icon.Alpha,
			0, 0
		)
	else
		icon:SetInfo("alpha; start, duration",
			icon.UnAlpha,
			ICDStartTime, ICDDuration
		)
	end
end

function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameHash = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.NameNameArray = TMW:GetSpellNames(icon, icon.Name, nil, 1)
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)

	icon.ICDStartTime = icon.ICDStartTime or 0
	icon.ICDDuration = icon.ICDDuration or 0

	icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))

	--[[ keep these events per icon isntead of global like unitcooldowns are so that ...
	well i had a reason here but it didnt make sense when i came back and read it a while later. Just do it. I guess.]]
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