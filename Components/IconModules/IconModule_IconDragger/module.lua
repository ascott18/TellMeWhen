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

local TMW = TMW
local L = TMW.L
local print = TMW.print
	

local Module = TMW:NewClass("IconModule_IconDragger", "IconModule")

function Module:OnNewInstance_IconDragger(icon)
	icon:RegisterForDrag("LeftButton", "RightButton")
end

Module:SetScriptHandler("OnMouseDown", function(Module, icon)
	local IconDragger = TMW.IconDragger
	
	if not TMW.Locked and IconDragger then		
		IconDragger.DraggingInfo = nil
		IconDragger.DraggerFrame:Hide()
		IconDragger.IsDragging = nil
	end
end)

Module:SetScriptHandler("OnDragStart", function(Module, icon, button)
	if not TMW.Locked and button == "RightButton" and TMW.IconDragger then
		TMW.IconDragger:Start(icon)
	end
end)


local icons = {}
local DD = CreateFrame("Frame", nil, UIParent, "TMW_DropDownMenuTemplate")
DD:Hide()
DD.wrapTooltips = 1

local function Dropdown_OnClick(button, icon)
	icon.group:Raise()

	-- Trick the icon dragger into thinking that we are still dragging,
	-- even though the user is just staring at a menu.
	TMW.IconDragger.IsDragging = true

	TMW.IconDragger:CompleteDrag("OnReceiveDrag", icon)
end

DD.initialize = function(dropdown)
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_CHOSEICONTODRAGTO"]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	for i, icon in pairs(icons) do
		local groupID, iconID = icon.group.ID, icon.ID
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = icon:GetIconName()
		
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


Module:SetScriptHandler("OnReceiveDrag", function(Module, icon)
	if TMW.IconDragger then
		--TMW.IconDragger:CompleteDrag("OnReceiveDrag", icon)

		wipe(icons)
		for _, instance in pairs(Module.class.instances) do
			if instance.icon:IsVisible() and instance.icon:IsMouseOver() then
				tinsert(icons, instance.icon)
			end	
		end
		if #icons == 1 then
			TMW.IconDragger:CompleteDrag("OnReceiveDrag", icons[1])
		elseif #icons > 1 then
			CloseDropDownMenus()
			ToggleDropDownMenu(1, nil, DD, icon, 0, 0)
		end
	end
end)


Module:SetScriptHandler("OnDragStop", function(Module, icon)
	if TMW.IconDragger and TMW.IconDragger.IsDragging then
		TMW.IconDragger:CompleteDrag("OnDragStop")
	end
end)


	
