-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local UnitRangedDamage  =
	  UnitRangedDamage
local pairs =
	  pairs
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

local Type = TMW.Classes.IconType:New("multistate")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_MULTISTATECD"]
Type.desc = L["ICONMENU_MULTISTATECD_DESC"]
Type.SUGType = "multistate"
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME_MULTISTATE"]
Type.chooseNameText = L["CHOOSENAME_DIALOG_MSCD"]
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			 },
	{ value = "unalpha",  		text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 			 },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("noMana")
Type:UsesAttributes("inRange")
Type:UsesAttributes("color")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type.EventDisabled_OnUnit = true
Type.EventDisabled_OnStack = true

Type:RegisterIconDefaults{
	RangeCheck				= false,
	ManaCheck				= false,
}

Type:RegisterConfigPanel_XMLTemplate("full", 1, "TellMeWhen_ChooseName")

Type:RegisterConfigPanel_ConstructorFunc("column", 1, "TellMeWhen_MultistateSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "RangeCheck",
			title = L["ICONMENU_RANGECHECK"],
			tooltip = L["ICONMENU_RANGECHECK_DESC"],
		},
		{
			setting = "ManaCheck",
			title = L["ICONMENU_MANACHECK"],
			tooltip = L["ICONMENU_MANACHECK_DESC"],
		},
	})
end)


function Type:Update()
end


local function MultiStateCD_OnEvent(icon, event)
	if event == "ACTIONBAR_SLOT_CHANGED" then
		local actionType, spellID = GetActionInfo(icon.Slot) -- check the current slot first, because it probably didnt change
		if actionType == "spell" and spellID == icon.NameFirst then
			-- do nothing
		else
			for i=1, 120 do
				local actionType, spellID = GetActionInfo(i)
				if actionType == "spell" and spellID == icon.NameFirst then
					icon.Slot = i
					break
				end
			end
		end
	end
	icon.NextUpdateTime = 0
end

local function MultiStateCD_OnUpdate(icon, time)

	local Slot = icon.Slot
	local start, duration = GetActionCooldown(Slot)
	if duration then

		local inrange, nomana = 1

		if icon.RangeCheck then
			inrange = IsActionInRange(Slot, "target") or 1
		end
		if icon.ManaCheck then
			_, nomana = IsUsableAction(Slot)
		end

		local actionType, spellID = GetActionInfo(Slot)
		spellID = actionType == "spell" and spellID or icon.NameFirst

		if (duration == 0 or OnGCD(duration)) and inrange == 1 and not nomana then
			icon:SetInfo("alpha; color; texture; start, duration; spell; inRange; noMana",
				icon.Alpha,
				icon:CrunchColor(),
				GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark",
				start, duration,
				spellID,
				inrange,
				nomana
			)
		else
			icon:SetInfo("alpha; color; texture; start, duration; spell; inRange; noMana",
				icon.UnAlpha,
				icon:CrunchColor(duration, inrange, nomana),
				GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark",
				start, duration,
				spellID,
				inrange,
				nomana
			)
		end
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	local originalNameFirst = icon.NameFirst

	if icon.NameFirst and icon.NameFirst ~= "" and GetSpellLink(icon.NameFirst) and not tonumber(icon.NameFirst) then
		icon.NameFirst = tonumber(strmatch(GetSpellLink(icon.NameFirst), ":(%d+)")) -- extract the spellID from the link
	end

	icon.Slot = 0
	MultiStateCD_OnEvent(icon, "ACTIONBAR_SLOT_CHANGED") -- the placement of this matters. so does the event arg

	if icon:IsBeingEdited() == 1 then
		if icon.Slot == 0 and originalNameFirst and originalNameFirst ~= "" then
			TMW.HELP:Show("ICON_MS_NOTFOUND", icon, TMW.IE.Main.Name, 0, 0, L["HELP_MS_NOFOUND"], TMW:RestoreCase(originalNameFirst))
		else
			TMW.HELP:Hide("ICON_MS_NOTFOUND")
		end
	end

	icon:SetInfo("texture", GetActionTexture(icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

	icon:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	icon:SetScript("OnEvent", MultiStateCD_OnEvent)
	
	icon:SetUpdateMethod("manual")
	
	icon:SetScript("OnUpdate", MultiStateCD_OnUpdate)
	icon:Update()
end


Type:Register()




