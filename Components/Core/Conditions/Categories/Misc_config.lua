-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local CNDT = TMW.CNDT

local TMW = TMW
local L = TMW.L
local print = TMW.print



TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData and conditionData.isicon then
		CndtGroup.TextIcon:SetText(L["ICONTOCHECK"])
		CndtGroup.Icon:Show()
		if conditionData.nooperator then
			UIDropDownMenu_SetWidth(CndtGroup.Icon, 152)
		else
			UIDropDownMenu_SetWidth(CndtGroup.Icon, 100)
		end
	else
		CndtGroup.TextIcon:SetText(nil)
		CndtGroup.Icon:Hide()
	end
end)


TMW.IconDragger:RegisterIconDragHandler(210, -- Add as icon shown condition
	function(IconDragger, info)
		if IconDragger.desticon then
			if IconDragger.srcicon:IsValid() then
				info.text = L["ICONMENU_APPENDCONDT"]
				info.tooltipTitle = nil
				info.tooltipText = nil
				return true
			end
		end
	end,
	function(IconDragger)
		-- add a condition to the destination icon
		local Condition = CNDT:AddCondition(IconDragger.desticon:GetSettings().Conditions)

		-- set the settings
		Condition.Type = "ICON"
		Condition.Icon = IconDragger.srcicon:GetName()
	end
)