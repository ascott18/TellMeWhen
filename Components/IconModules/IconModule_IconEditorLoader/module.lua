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
	

local Module = TMW:NewClass("IconModule_IconEditorLoader", "IconModule")



local icons = {}
local DD = TMW.C.Config_DropDownMenu:New("Frame", nil, UIParent, "TMW_DropDownMenuTemplate", nil, {
	OnClick = function(button, self, icon)
		icon.group:Raise()
		TMW.IE:Load(nil, icon)
	end,
	
	func = function(self)
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["ICONMENU_CHOSEICONTOEDIT"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		for i, icon in pairs(icons) do
			
			local info = UIDropDownMenu_CreateInfo()
			info.text = icon:GetIconName()
			
			local text, textshort, tooltip = icon:GetIconMenuText()
			info.tooltipTitle = text
			info.tooltipText = tooltip
			info.tooltipOnButton = true

			info.icon = icon.attributes.texture
			info.tCoordLeft = 0.07
			info.tCoordRight = 0.93
			info.tCoordTop = 0.07
			info.tCoordBottom = 0.93
			
			info.func = self.data.OnClick
			info.arg1 = self
			info.arg2 = icon
			info.notCheckable = true
			
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end,
})


Module:SetScriptHandler("OnMouseUp", function(Module, icon, button)
	wipe(icons)
	for _, instance in pairs(Module.class.instances) do
		if instance.icon:IsVisible() and instance.icon:IsMouseOver() then
			tinsert(icons, instance.icon)
		end	
	end
	if not TMW.Locked then
		if button == "RightButton" then
			if #icons == 1 then
				TMW.IE:Load(nil, icon)
			elseif #icons > 1 then
				GameTooltip:Hide() -- hide the tooltip over an icon so we can see the menu
				CloseDropDownMenus()
				ToggleDropDownMenu(1, nil, DD, icon, 0, 0)
			end
			
		elseif IsShiftKeyDown() and button == "LeftButton" then

			-- Don't insert into the chat editbox.
			if not ChatEdit_GetActiveWindow() then

				local GUID = icon:GetGUID()
				local link = format("|H%s|h%s|h", GUID, GUID)

				local inserted = ChatEdit_InsertLink(link)

				if inserted then
					-- If the insertion was successful, make the GUID permanant.
					icon:GetGUID(1)
				end

			end
		end
	end
end)

