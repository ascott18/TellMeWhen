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

local CI = TMW.CI

local _G = _G

local pairs, tinsert, tremove = 
	  pairs, tinsert, tremove

local Type = rawget(TMW.Types, "meta")

if not Type then return end


-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE, UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, CloseDropDownMenus
-- GLOBALS: TellMeWhen_MetaIconOptions
-- GLOBALS: CreateFrame


TMW.IconDragger:RegisterIconDragHandler(220, -- Add to meta icon
	function(IconDragger, info)
		if IconDragger.desticon
		and IconDragger.srcicon:IsValid()
		and IconDragger.desticon.Type == "meta"
		and IconDragger.srcicon.group.viewData == IconDragger.desticon.group.viewData
		then
			info.text = L["ICONMENU_ADDMETA"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(IconDragger)
		local Icons = IconDragger.desticon:GetSettings().Icons
		if Icons[#Icons] == "" then
			Icons[#Icons] = nil
		end
		tinsert(Icons, IconDragger.srcicon:GetGUID(true))
	end
)



function Type:GetIconMenuText(ics)
	local text = Type.name .. " " .. L["ICONMENU_META_ICONMENUTOOLTIP"]:format(ics.Icons and #ics.Icons or 0)
	
	return text, "", true
end

function Type:GuessIconTexture(ics)
	return "Interface\\Icons\\LevelUpIcon-LFD"
end


local ME = TMW:NewModule("MetaEditor")
TMW.ME = ME

function ME:LoadConfig()
	if not TellMeWhen_MetaIconOptions then return end
	local settings = CI.ics.Icons

	for k, GUID in pairs(settings) do
		local mg = ME[k] or CreateFrame("Frame", "TellMeWhen_MetaIconOptions" .. k, TellMeWhen_MetaIconOptions, "TellMeWhen_MetaGroup", k)
		ME[k] = mg
		mg:Show()
		if k > 1 then
			mg:SetPoint("TOPLEFT", ME[k-1], "BOTTOMLEFT", 0, 0)
			mg:SetPoint("TOPRIGHT", ME[k-1], "BOTTOMRIGHT", 0, 0)
		end
		mg:SetFrameLevel(TellMeWhen_MetaIconOptions:GetFrameLevel()+2)

		mg.icon:SetGUID(GUID)
	end

	TMW:AnimateHeightChange(TellMeWhen_MetaIconOptions, (#settings * ME[1]:GetHeight()) + 35, 0.1)
	
	for f=#settings+1, #ME do
		ME[f]:Hide()
	end
	ME[1]:Show()

	if settings[2] then
		ME[1].delete:Show()
	else
		ME[1].delete:Hide()
	end
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", ME, "LoadConfig")


---------- Click Handlers ----------
function ME:Insert(where)
	tinsert(CI.ics.Icons, where, "")
	ME:LoadConfig()
end

function ME:Delete(self)
	tremove(CI.ics.Icons, self:GetParent():GetID())
	ME:LoadConfig()
end

function ME:SwapIcons(id1, id2)
	local Icons = CI.ics.Icons
	
	Icons[id1], Icons[id2] = Icons[id2], Icons[id1]
	
	TMW.ME:LoadConfig()
end


---------- Dropdown ----------
local addedGroups = {}
function ME:IconMenu()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		local currentGroupView = TMW.CI.gs.View
		
		for group in TMW:InGroups() do
			if group:ShouldUpdateIcons() then
				local info = UIDropDownMenu_CreateInfo()

				info.text = group:GetGroupName()

				info.value = group

				if currentGroupView ~= group:GetSettings().View then
					info.disabled = true
					info.tooltipWhileDisabled = true
					
					info.tooltipTitle = info.text
					info.tooltipText = L["META_GROUP_INVALID_VIEW_DIFFERENT"]
						:format(TMW.Views[currentGroupView].name, TMW.Views[group:GetSettings().View].name)
					info.tooltipOnButton = true
					info.hasArrow = false
				else
					info.hasArrow = true
				end
				
				info.func = ME.IconMenuOnClick
				info.arg1 = self
				info.checked = CI.ics.Icons[self:GetParent():GetID()] == group:GetGUID()

				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for icon in UIDROPDOWNMENU_MENU_VALUE:InIcons() do
			if icon:IsValid() and CI.icon ~= icon and not icon:IsControlled() then
				local info = UIDropDownMenu_CreateInfo()

				local text, textshort, tooltip = icon:GetIconMenuText()
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipOnButton = true
				info.tooltipText = tooltip

				info.value = icon
				info.func = ME.IconMenuOnClick
				info.arg1 = self
				info.checked = CI.ics.Icons[self:GetParent():GetID()] == icon:GetGUID()

				info.tCoordLeft = 0.07
				info.tCoordRight = 0.93
				info.tCoordTop = 0.07
				info.tCoordBottom = 0.93
				info.icon = icon.attributes.texture
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end

function ME:IconMenuOnClick(frame)
	local GUID = self.value:GetGUID(true)

	assert(GUID)

	CI.ics.Icons[frame:GetParent():GetID()] = GUID

	ME:LoadConfig()
	CloseDropDownMenus()
end

