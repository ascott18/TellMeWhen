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


local Type = TMW.Classes.IconType:New("conditionicon")
Type.name = L["ICONMENU_CNDTIC"]
Type.desc = L["ICONMENU_CNDTIC_DESC"]
Type.menuIcon = "Interface\\Icons\\inv_misc_punchcards_yellow"
Type.spacebefore = true
Type.AllowNoName = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("alpha_conditionFailed")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:UsesAttributes("conditionFailed", false)

Type:RegisterIconDefaults{
	ConditionDur			= 0,
	UnConditionDur			= 0,
	ConditionDurEnabled		= false,
	UnConditionDurEnabled  	= false,
	OnlyIfCounting			= false,
	OnlyIfNotCounting		= false,
}

TMW:RegisterUpgrade(47204, {
	icon = function(self, ics)
		if ics.Type == "conditionicon"  then
			ics.CustomTex = ics.Name or ""
			ics.Name = ""
		end
	end,
})

TMW:RegisterUpgrade(45013, {
	icon = function(self, ics)
		if ics.Type == "conditionicon" then
			ics.Alpha = 1
			ics.UnAlpha = ics.ConditionAlpha or 0
			ics.ConditionAlpha = 0
		end
	end,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_SUCCEED2"],			},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_FAIL2"],			},
})

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_ConditionIconSettings")

local function ConditionIcon_OnUpdate(icon, time)
	local ConditionObject = icon.ConditionObject
	if ConditionObject then
		local succeeded = not ConditionObject.Failed
		
		local alpha = succeeded and icon.Alpha or icon.UnAlpha

		local d, start, duration

		if succeeded and not icon.__succeeded and icon.ConditionDurEnabled then
			d = icon.ConditionDur
			start, duration = time, d

		elseif not succeeded and icon.__succeeded and icon.UnConditionDurEnabled then
			d = icon.UnConditionDur
			start, duration = time, d

		else
			local attributes = icon.attributes
			d = attributes.duration - (time - attributes.start)
			d = d > 0 and d or 0
			if d > 0 then
				start, duration = attributes.start, attributes.duration
			else
				start, duration = 0, 0
			end
		end

		if icon.OnlyIfCounting and d <= 0 then
			alpha = 0
		elseif icon.OnlyIfNotCounting and d > 0 then
			alpha = 0
		end
		
		icon:SetInfo(
			"alpha_conditionFailed; alpha; start, duration",
			nil,
			alpha,
			start, duration
		)

		icon.__succeeded = succeeded
	else
		icon:SetInfo("alpha_conditionFailed; alpha", nil, 1)
	end
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
	return ""
end


function Type:Setup(icon)
	icon:SetInfo("texture", "Interface\\Icons\\INV_Misc_QuestionMark")

	icon:SetUpdateMethod("manual")
	
	icon:SetUpdateFunction(ConditionIcon_OnUpdate)
	--icon:Update() -- dont do this!
end

function Type:DragReceived(icon, t, data, subType)	
	local ics = icon:GetSettings()

	local _, input
	if t == "spell" then
		_, input = GetSpellBookItemInfo(data, subType)
	elseif t == "item" then
		input = GetItemIcon(data)
	end
	if not input then
		return
	end

	ics.CustomTex = TMW:CleanString(input)
	return true -- signal success
end

function Type:GetIconMenuText(ics, groupID, iconID)
	local text = Type.name .. " " .. L["ICONMENU_CNDTIC_ICONMENUTOOLTIP"]:format((ics.Conditions and (ics.Conditions.n or #ics.Conditions)) or 0)
	
	return text, "", true
end

Type:Register(300)
