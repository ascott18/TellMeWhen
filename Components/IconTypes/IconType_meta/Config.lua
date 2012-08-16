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

local CI = TMW.CI

local _G = _G

local pairs, tinsert, tremove = 
	  pairs, tinsert, tremove

-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE, UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, CloseDropDownMenus
-- GLOBALS: TellMeWhen_MetaIconOptions
-- GLOBALS: CreateFrame


TMW.ID:RegisterIconDragHandler(20,
	function(ID, info)
		if ID.desticon then
			if ID.srcicon:IsValid() then
				if ID.desticon.Type == "meta" then
					info.text = L["ICONMENU_ADDMETA"]
					info.tooltipTitle = nil
					info.tooltipText = nil
					return true
				end
			end
		end
	end,
	function(ID)
		local Icons = TMW.db.profile.Groups[ID.desticon.group:GetID()].Icons[ID.desticon:GetID()].Icons
		if Icons[#Icons] == "" then
			Icons[#Icons] = nil
		end
		tinsert(Icons, ID.srcicon:GetName())
	end
)



local ME = TMW:NewModule("MetaEditor")
TMW.ME = ME

function ME:LoadConfig()
	if not TellMeWhen_MetaIconOptions then return end
	local groupID, iconID = CI.g, CI.i
	local settings = CI.ics.Icons

	for k, v in pairs(settings) do
		local mg = ME[k] or CreateFrame("Frame", "TellMeWhen_MetaIconOptions" .. k, TellMeWhen_MetaIconOptions, "TellMeWhen_MetaGroup", k)
		ME[k] = mg
		mg:Show()
		ME[k].up:Show()
		ME[k].down:Show()
		if k > 1 then
			mg:SetPoint("TOPLEFT", ME[k-1], "BOTTOMLEFT", 0, 0)
			mg:SetPoint("TOPRIGHT", ME[k-1], "BOTTOMRIGHT", 0, 0)
		end
		mg:SetFrameLevel(TellMeWhen_MetaIconOptions:GetFrameLevel()+2)

		TMW:SetUIDropdownText(mg.icon, v, TMW.InIcons, L["CHOOSEICON"])
		mg.icon.IconPreview:SetIcon(_G[v])
	end

	TellMeWhen_MetaIconOptions:SetHeight((#settings * ME[1]:GetHeight()) + 45)
	
	for f=#settings+1, #ME do
		ME[f]:Hide()
	end
	ME[1].up:Hide()
	ME[1]:Show()

	if settings[1] then
		ME[#settings].down:Hide()
		ME[1].delete:Hide()
	else
		ME[1].down:Hide()
	end

	if settings[2] then
		ME[1].delete:Show()
	else
		ME[1].delete:Hide()
	end
end
TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", ME.LoadConfig, ME)


---------- Click Handlers ----------
function ME:UpOrDown(self, delta)
	local ID = self:GetParent():GetID()
	local settings = CI.ics.Icons
	local curdata, destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	ME:LoadConfig()
end

function ME:Insert(where)
	tinsert(CI.ics.Icons, where, "")
	ME:LoadConfig()
end

function ME:Delete(self)
	tremove(TMW.db.profile.Groups[CI.g].Icons[CI.i].Icons, self:GetParent():GetID())
	ME:LoadConfig()
end


---------- Dropdown ----------
local addedGroups = {}
function ME:IconMenu()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		for group, groupID in TMW:InGroups() do
			if group:ShouldUpdateIcons() then
				local info = UIDropDownMenu_CreateInfo()

				info.text = TMW:GetGroupName(groupID, groupID, 1)

				info.value = group:GetName()

				info.func = ME.IconMenuOnClick
				info.arg1 = self

				info.hasArrow = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for icon, groupID, iconID in TMW:InIcons() do
			if icon:IsValid() and icon.group:GetName() == UIDROPDOWNMENU_MENU_VALUE and CI.ic ~= icon then
				local info = UIDropDownMenu_CreateInfo()

				local text, textshort, tooltip = TMW:GetIconMenuText(groupID, iconID)
				if text:sub(-2) == "))" then
					textshort = textshort .. " " .. L["fICON"]:format(iconID)
				end
				info.text = textshort
				info.tooltipTitle = text
				info.tooltipOnButton = true
				info.tooltipText = L["GROUPICON"]:format(TMW:GetGroupName(groupID, groupID, 1), iconID) .. "\r\n" .. tooltip

				info.value = icon:GetName()
				info.func = ME.IconMenuOnClick
				info.arg1 = self

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
	TMW.db.profile.Groups[CI.g].Icons[CI.i].Icons[frame:GetParent():GetID()] = self.value
	ME:LoadConfig()
	CloseDropDownMenus()
end

