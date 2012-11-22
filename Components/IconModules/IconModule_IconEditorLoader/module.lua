-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print
	

local Module = TMW:NewClass("IconModule_IconEditorLoader", "IconModule")



local icons = {}
local DD = CreateFrame("Frame", nil, UIParent, "TMW_DropDownMenuTemplate")
DD:Hide()
DD.wrapTooltips = 1
local function Dropdown_OnClick(button, icon)
	icon.group:Raise()
	TMW.IE:Load(nil, icon)
end
DD.initialize = function(dropdown)
	for i, icon in pairs(icons) do
		local groupID, iconID = icon.group.ID, icon.ID
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["GROUPICON"]:format(TMW:GetGroupName(groupID, groupID, 1), iconID)
		
		local text, textshort, tooltip = TMW:GetIconMenuText(groupID, iconID, icon:GetSettings())
		info.tooltipTitle = text
		info.tooltipText = tooltip
		info.tooltipOnButton = true

		info.icon = icon.attributes.texture
		info.tCoordLeft = 0.07
		info.tCoordRight = 0.93
		info.tCoordTop = 0.07
		info.tCoordBottom = 0.93
		
		info.func = Dropdown_OnClick
		info.arg1 = icon
		info.notCheckable = true
		
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end
end


Module:SetScriptHandler("OnMouseUp", function(Module, icon, button)
	wipe(icons)
	for _, instance in pairs(Module.class.instances) do
		if instance.icon:IsVisible() and instance.icon:IsMouseOver() then
			tinsert(icons, instance.icon)
		end	
	end
	if not TMW.Locked and button == "RightButton" then
		if #icons == 1 then
			TMW.IE:Load(nil, icon)
		elseif #icons > 1 then
			CloseDropDownMenus()
			ToggleDropDownMenu(1, nil, DD, icon, 0, 0)
		end
	end
end)

