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
local type =
	  type

local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName
local GetSpellBookItemInfo = TMW.GetSpellBookItemInfo

local Type = TMW.Classes.IconType:New("")
Type.name = L["ICONMENU_TYPE"]
Type.menuSpaceAfter = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


-- Not automatically generated - forced override to prevent the condition alpha slider from showing.
Type:UsesAttributes("conditionFailed", false)


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_Texts", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)

Type:RegisterConfigPanel_XMLTemplate(110, "TellMeWhen_DefaultInstructions")



function Type:Setup(icon)
	if icon.Name ~= "" then
		icon:SetInfo("texture", "Interface\\Icons\\INV_Misc_QuestionMark")
	else
		icon:SetInfo("texture", "")
	end
	icon:SetInfo("state", 0)
end

function Type:DragReceived(icon, t, data, subType, param4)
	local ics = icon:GetSettings()

	-- Take the dragged thing and create a new icon from it of the appropriate type.
	local newType, input
	if t == "spell" then
		if data == 0 and type(param4) == "number" then
			-- I don't remember the purpose of this anymore.
			-- It handles some special sort of spell, though, and is required.
			-- param4 here is a spellID, obviously.
			input = GetSpellName(param4)
		else
			
			local spellData = GetSpellBookItemInfo(data, subType)
			if not spellData or spellData.typeName ~= "SPELL" then
				return
			end
			
			local baseSpellName = GetSpellName(spellData.actionID)
			input = baseSpellName or spellData.name
		end
	
		newType = "cooldown"
	elseif t == "item" then
		input = data
		newType = "item"
	end
	if not (input and newType) then return end

	ics.Type = newType
	ics.Enabled = true
	ics.Name = TMW:CleanString(ics.Name .. ";" .. input)
	return true -- signal success
end

function Type:GetIconMenuText(ics)
	return L["NOTYPE"], ""
end

Type:Register(1)