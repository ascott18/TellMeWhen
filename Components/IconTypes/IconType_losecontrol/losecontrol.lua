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

if not _G.C_LossOfControl then
	return
end

local strlower =
	  strlower
local GetSpellTexture, GetSpellLink, GetSpellInfo =
	  GetSpellTexture, GetSpellLink, GetSpellInfo
local GetEventInfo = C_LossOfControl.GetEventInfo
local GetNumEvents = C_LossOfControl.GetNumEvents

local print = TMW.print
local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New("losecontrol")
Type.name = L["LOSECONTROL_ICONTYPE"]	
Type.desc = L["LOSECONTROL_ICONTYPE_DESC"]
Type.AllowNoName = true
Type.usePocketWatch = 1


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	LoseContolTypes = {
		["*"] = false,
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

	local LoseContolTypes = icon.LoseContolTypes
	
	-- Be careful here. Slots that are explicitly disabled by the user are set false.
	-- Slots that are disabled internally are set nil (which could change table length).
	for eventIndex = 1, GetNumEvents() do 
		local locType, spellID, text, texture, start, _, duration, lockoutSchool = GetEventInfo(eventIndex)
		
		local isValidType
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
		
		if isValidType then
			icon:SetInfo("alpha; texture; start, duration; spell",
				icon.Alpha,
				texture,
				start, duration,
				spellID
			)
			return
		end
	end
	
	icon:SetInfo("alpha; texture; start, duration; spell",
		icon.UnAlpha,
		icon.FirstTexture,
		0, 0,
		nil
	)
end


function Type:Setup(icon, groupID, iconID)
	

	icon.FirstTexture = nil --TODO
	
	icon:SetInfo("reverse", true)

	icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))

	icon:SetUpdateMethod("manual")
	
	icon:RegisterSimpleUpdateEvent("LOSS_OF_CONTROL_UPDATE")
	icon:RegisterSimpleUpdateEvent("LOSS_OF_CONTROL_ADDED")
	
	icon:SetUpdateFunction(LoseControl_OnUpdate)
	icon:Update()
end

function Type:GetIconMenuText(data)
	--TODO
	--[[local text = data.Name or ""
	if text == "" then
		text = "((" .. Type.name .. "))"
	end]]

	return text, "" --data.Name and data.Name ~= ""  and data.Name .. "\r\n" or ""
end

Type:Register(102)