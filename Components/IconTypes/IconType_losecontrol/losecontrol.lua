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

if not _G.C_LossOfControl then
	return
end

local GetSpellTexture, GetSpellLink, GetSpellInfo =
	  GetSpellTexture, GetSpellLink, GetSpellInfo
local GetEventInfo = C_LossOfControl.GetEventInfo
local GetNumEvents = C_LossOfControl.GetNumEvents

local print = TMW.print
local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New("losecontrol")
Type.name = L["LOSECONTROL_ICONTYPE"]	
Type.desc = L["LOSECONTROL_ICONTYPE_DESC"]
Type.menuIcon = "Interface\\Icons\\Spell_Shadow_Possession"
Type.AllowNoName = true
Type.usePocketWatch = 1
Type.hasNoGCD = true
Type.canControlGroup = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("locCategory")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	LoseContolTypes = { -- PLEASE NOTE: THIS IS SPELLED WRONG (i noticed too late to change it)
		["*"] = false,
		[""] = false,
		SCHOOL_INTERRUPT = 0,
	},
}

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_LoseControlTypes")

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x1] = { text = "|cFF00FF00" .. L["LOSECONTROL_INCONTROL"],		},
	[0x2] = { text = "|cFFFF0000" .. L["LOSECONTROL_CONTROLLOST"],		},
})



local function LoseControl_OnUpdate(icon, time)
	-- PLEASE NOTE: LoseContolTypes IS SPELLED WRONG

	local LoseContolTypes = icon.LoseContolTypes
	
	-- Be careful here. Slots that are explicitly disabled by the user are set false.
	-- Slots that are disabled internally are set nil (which could change table length).
	for eventIndex = 1, GetNumEvents() do 
		local locType, spellID, text, texture, start, _, duration, lockoutSchool = GetEventInfo(eventIndex)
		
		local isValidType = LoseContolTypes[""]
		if not isValidType then
			if locType == "SCHOOL_INTERRUPT" then
				local setting = LoseContolTypes[locType]
				if setting ~= 0 and lockoutSchool and lockoutSchool ~= 0 and bit.band(lockoutSchool, setting) ~= 0 then
					isValidType = true
				end
			else
				for locType, v in pairs(LoseContolTypes) do
					if v and _G["LOSS_OF_CONTROL_DISPLAY_" .. locType] == text then
						isValidType = true
						break
					end
				end
			end
		end
		if isValidType and not icon:YieldInfo(true, text, texture, start, duration, spellID) then
			return
		end
	end
	
	icon:YieldInfo(false)
end


function Type:HandleInfo(icon, iconToSet, category, texture, start, duration, spell)
	if category then
		iconToSet:SetInfo("alpha; texture; start, duration; spell; locCategory",
			icon.Alpha,
			texture,
			start, duration,
			spellID,
			category
		)
	else
		iconToSet:SetInfo("alpha; start, duration; spell; locCategory",
			icon.UnAlpha,
			0, 0,
			nil,
			nil
		)
	end
end


function Type:Setup(icon)
	
	icon:SetInfo("reverse; texture",
		true,
		Type:GetConfigIconTexture(icon)
	)

	icon:SetUpdateMethod("manual")
	
	icon:RegisterSimpleUpdateEvent("LOSS_OF_CONTROL_UPDATE")
	icon:RegisterSimpleUpdateEvent("LOSS_OF_CONTROL_ADDED")
	
	icon:SetUpdateFunction(LoseControl_OnUpdate)
	
	icon:Update()
end

Type:Register(102)




local Processor = TMW.Classes.IconDataProcessor:New("LOC_CATEGORY", "locCategory")
-- Processor:CompileFunctionSegment(t) is default.

Processor:RegisterDogTag("TMW", "LocType", {
	code = function(icon)
		icon = TMW.GUIDToOwner[icon]
		
		if icon then
			if icon.Type ~= "losecontrol" then
				return ""
			else
				return icon.attributes.locCategory or ""
			end
		else
			return ""
		end
	end,
	arg = {
		'icon', 'string', '@req',
	},
	events = TMW:CreateDogTagEventString("LOC_CATEGORY"),
	ret = "string",
	doc = L["DT_DOC_LocType"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = ('[LocType] => %q; [LocType(icon="TMW:icon:1I7MnrXDCz8T")] => %q'):format(LOSS_OF_CONTROL_DISPLAY_STUN, LOSS_OF_CONTROL_DISPLAY_FEAR),
	category = L["ICON"],
})