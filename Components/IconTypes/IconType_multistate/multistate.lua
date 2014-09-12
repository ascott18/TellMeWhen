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
local pairs, tonumber, strmatch, format =
	  pairs, tonumber, strmatch, format
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo, GetActionCharges, GetActionCount =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo, GetActionCharges, GetActionCount
local GetSpellLink, UnitRangedDamage  =
	  GetSpellLink, UnitRangedDamage

local OnGCD = TMW.OnGCD

-- GLOBALS: TellMeWhen_ChooseName


local Type = TMW.Classes.IconType:New("multistate")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_MULTISTATECD"]
Type.desc = L["ICONMENU_MULTISTATECD_DESC"]
Type.menuIcon = "Interface\\Icons\\Spell_Holy_ConsumeMagic"


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("noMana")
Type:UsesAttributes("spell")
Type:UsesAttributes("charges, maxCharges")
Type:UsesAttributes("inRange")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)




Type:RegisterIconDefaults{
	-- True to cause the icon to act as unusable when the ability is out of range.
	RangeCheck				= false,

	-- True to cause the icon to act as unusable when the ability lacks power to be used.
	ManaCheck				= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME_MULTISTATE"],
	text = L["CHOOSENAME_DIALOG_MSCD"],
	SUGType = "multistate",
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"], 			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], 		},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_MultistateSettings", function(self)
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



local function MultiStateCD_OnEvent(icon, event)
	if event == "ACTIONBAR_SLOT_CHANGED" then
		-- Check the current slot first, because it probably didnt change
		local actionType, spellID = GetActionInfo(icon.Slot) 


		if actionType == "spell" and spellID == icon.Names.First then
			-- Indeed, it didn't change. All is well, so do nothing.
		else
			-- The action we want to check isn't in that slot anymore.
			-- Search for it, and update the slot that it is in.
			for i=1, 120 do
				local actionType, spellID = GetActionInfo(i)
				if actionType == "spell" and spellID == icon.Names.First then
					icon.Slot = i
					break
				end
			end
		end
	end

	-- Queue an icon update no matter what the event is.
	icon.NextUpdateTime = 0
end


local function MultiStateCD_OnUpdate(icon, time)

	local Slot = icon.Slot
	
	local start, duration, stack
	
	local charges, maxCharges, start_charge, duration_charge = GetActionCharges(Slot)
	if charges then
		if charges < maxCharges then
			start, duration = start_charge, duration_charge
		else
			start, duration = GetActionCooldown(Slot)
		end
		stack = charges
	else
		start, duration = GetActionCooldown(Slot)
		stack = GetActionCount(Slot)
	end	
		
	
	if duration then	
		local inrange, nomana, _ = 1

		if icon.RangeCheck then
			inrange = IsActionInRange(Slot, "target") or 1
		end
		if icon.ManaCheck then
			_, nomana = IsUsableAction(Slot)
		end

		local actionType, spellID = GetActionInfo(Slot)
		spellID = actionType == "spell" and spellID or icon.Names.First

		if (duration == 0 or OnGCD(duration)) and inrange == 1 and not nomana then
			icon:SetInfo("alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell; inRange; noMana",
				icon.Alpha,
				GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark",
				start, duration,
				charges, maxCharges,
				stack, stack,
				spellID,
				inrange,
				nomana
			)
		else
			icon:SetInfo("alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell; inRange; noMana",
				icon.UnAlpha,
				GetActionTexture(Slot) or "Interface\\Icons\\INV_Misc_QuestionMark",
				start, duration,
				charges, maxCharges,
				stack, stack,
				spellID,
				inrange,
				nomana
			)
		end
	end
end


function Type:Setup(icon)
	icon.Names = TMW:GetSpellNamesProxy(icon.Name, true)
	local originalNameFirst = icon.Names.First


	-- This icon type requires a spellID. Make one if the user didn't give us one.
	if icon.Names.First and icon.Names.First ~= "" and GetSpellLink(icon.Names.First) and not tonumber(icon.Names.First) then
		local ID = strmatch(GetSpellLink(icon.Names.First), ":(%d+)") -- extract the spellID from the link
		icon.Names = TMW:GetSpellNamesProxy(ID, true)
	end


	-- Reset the slot, and then call our OnEvent handler to obtain the correct action slot.
	icon.Slot = 0
	MultiStateCD_OnEvent(icon, "ACTIONBAR_SLOT_CHANGED")

	if icon:IsBeingEdited() == "MAIN" then
		-- icon.Slot was just obtained by the OnEvent method call.
		-- If it is still 0, that means the ability that the player wants to track
		-- is not on their action bars.
		if icon.Slot == 0 and originalNameFirst and originalNameFirst ~= "" and TellMeWhen_ChooseName then
			TMW.HELP:Show{
				code = "ICON_MS_NOTFOUND",
				codeOrder = 5,
				icon = icon,
				relativeTo = TellMeWhen_ChooseName,
				x = 0,
				y = 0,
				text = format(L["HELP_MS_NOFOUND"], TMW:RestoreCase(originalNameFirst))
			}
		else
			TMW.HELP:Hide("ICON_MS_NOTFOUND")
		end
	end

	icon:SetInfo("texture", GetActionTexture(icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")

	icon:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	icon:SetScript("OnEvent", MultiStateCD_OnEvent)
	
	if not icon.RangeCheck then
		icon:RegisterSimpleUpdateEvent("ACTIONBAR_UPDATE_COOLDOWN")
		icon:RegisterSimpleUpdateEvent("ACTIONBAR_UPDATE_USABLE")
		
		icon:SetUpdateMethod("manual")
	end
	
	icon:SetUpdateFunction(MultiStateCD_OnUpdate)
	icon:Update()
end


Type:Register(60)




