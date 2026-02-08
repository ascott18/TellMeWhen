-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print


local BaseConfig = TMW:NewClass("GroupModule_BaseConfig", "GroupModule")

BaseConfig.DefaultPanelColumnIndex = 1


BaseConfig:RegisterConfigPanel_XMLTemplate(1, "TellMeWhen_GM_Rename"):SetColumnIndex(2)

BaseConfig:RegisterConfigPanel_ConstructorFunc(2, "TellMeWhen_GM_View", function(self)
	self:SetTitle(L["UIPANEL_GROUPTYPE"])
	
	local data = { numPerRow = 3, }

	local function Reload()
		TMW:Update()

		-- We need to call this so that we make sure to get the correct panels
		-- after the view changes.
		TMW.IE:LoadGroup(1)
	end

	for view, viewData in TMW:OrderedPairs(TMW.Views, TMW.OrderSort, true) do
		tinsert(data, function(check)
			check:SetTexts(viewData.name, viewData.desc)
			check:SetSetting("View", view)
			check:CScriptAddPre("SettingSaved", Reload)
		end)
	end

	self:BuildSimpleCheckSettingFrame(data)
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(9, "TellMeWhen_GS_Combat", function(self)
	self:SetTitle(COMBAT)
	
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 1,
		function(check)
			check:SetTexts(L["UIPANEL_ONLYINCOMBAT"], L["UIPANEL_TOOLTIP_ONLYINCOMBAT"])
			check:SetSetting("OnlyInCombat")
		end,
	})
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(11, "TellMeWhen_GS_Role", function(self)
	self:SetTitle(ROLE)
	
	local data = {
		numPerRow = 3
	}	

	for i, role in TMW:Vararg("TANK", "HEALER", "DAMAGER") do
		tinsert(data, function(check)
			check:SetLabel("")
			check:SetTexts(_G[role], L["UIPANEL_ROLE_DESC"])

			-- This subtraction is because the bit order is reversed from this.
			-- We put the settings in this order since it is the role order in the default UI.
			check:SetSetting("Role")
			check:SetSettingBitID(4 - i)

			local border = CreateFrame("Frame", nil, check, "TellMeWhen_GenericBorder")
			border:ClearAllPoints()
			border:SetPoint("LEFT", check, "RIGHT", 4, 0)
			border:SetSize(21, 21)

			local tex = border:CreateTexture(nil, "ARTWORK")
			tex:SetTexture("Interface\\Addons\\TellMeWhen\\Textures\\" .. role)
			tex:SetAllPoints()
		end)
	end

	self:BuildSimpleCheckSettingFrame("Config_CheckButton_BitToggle", data)
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(12, "TellMeWhen_GS_Tree", function(self)
	self:SetTitle(SPECIALIZATION)
	
	local data = {
		numPerRow = TMW.GetNumSpecializations()
	}	

	for i = 1, TMW.GetNumSpecializations() do
		local specID, name, _, texture = TMW.GetSpecializationInfo(i)
		tinsert(data, function(check)
			check:SetLabel("")
			check:SetTexts(name, L["UIPANEL_TREE_DESC"])
			check:SetSetting(specID)

			local border = CreateFrame("Frame", nil, check, "TellMeWhen_GenericBorder")
			border:ClearAllPoints()
			border:SetPoint("LEFT", check, "RIGHT", 4, 0)
			border:SetSize(21, 21)

			local tex = border:CreateTexture(nil, "ARTWORK")
			tex:SetTexture(texture)
			tex:SetAllPoints()
			tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end)
	end

	self:BuildSimpleCheckSettingFrame(data)

	self:CScriptAdd("SettingTableRequested", function()
		return TMW.CI.gs and TMW.CI.gs.EnabledSpecs or false
	end)
end)

if TMW.clientHasSecrets then

    local viewers = {
        EssentialCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer,
        UtilityCooldownViewer
    }
    -- Remove nil viewers
    for i = #viewers, 1, -1 do
        if not viewers[i] then
            table.remove(viewers, i)
        end
    end
	
	BaseConfig:RegisterConfigPanel_ConstructorFunc(13, "TellMeWhen_GS_CDMViewerHide", function(self)
		self:SetTitle(L["UIPANEL_GROUP_CDM_HIDE"])

		local function OnClick(button, dropdown)
			local settingTable = TMW.CI.gs.CDMViewerHide
			local key = button.value
			settingTable[key] = not settingTable[key]
			dropdown:OnSettingSaved()
			TMW:Update()
		end

		self.CDMViewerDropdown = TMW.C.Config_DropDownMenu:New("Frame", "$parentCDMViewerHide", self, "TMW_DropDownMenuTemplate")
		self.CDMViewerDropdown:SetTexts(L["UIPANEL_GROUP_CDM_HIDE"], L["UIPANEL_GROUP_CDM_HIDE_DESC"])
		self.CDMViewerDropdown:SetWidth(200)
		self.CDMViewerDropdown:SetFunction(function(dropdown)
			local settingTable = TMW.CI.gs.CDMViewerHide
			for _, viewer in ipairs(viewers) do
				local settingKey = viewer.systemIndex
				local info = TMW.DD:CreateInfo()
				info.text = viewer.systemNameString
				info.tooltipTitle = viewer.systemNameString
				info.tooltipText = L["UIPANEL_GROUP_CDM_HIDE_DESC"]
				info.value = settingKey
				info.func = OnClick
				info.arg1 = dropdown
				info.keepShownOnClick = true
				info.isNotRadio = true
				info.checked = settingTable[settingKey]

				TMW.DD:AddButton(info)
			end
		end)

		self.CDMViewerDropdown:SetPoint("TOPLEFT", 5, -5)
		self.CDMViewerDropdown:SetPoint("RIGHT", -5, 0)

		self:CScriptAdd("ReloadRequested", function()
			local settingTable = TMW.CI.gs and TMW.CI.gs.CDMViewerHide
			if not settingTable then return end
			local names = {}
			for _, viewer in ipairs(viewers) do
				if settingTable[viewer.systemIndex]then
					tinsert(names, viewer.systemNameString)
				end
			end

			if #names == 0 then
				self.CDMViewerDropdown:SetText(NONE)
			else
				self.CDMViewerDropdown:SetText(table.concat(names, ", "))
			end
		end)

		self:AdjustHeight()
	end)
    
    -- Find the first active group that is hiding a specific viewer by its systemIndex.
    local function GetGroupHidingViewer(settingKey)
        for group in TMW:InGroups() do
            if group:ShouldUpdateIcons() and group:GetSettings().CDMViewerHide[settingKey] then
                return group
            end
        end
        return nil
    end

    local function ApplyViewerOverride(viewer)
        local settingName = viewer.systemIndex
        local layoutName = EditModeManagerFrame:GetActiveLayoutInfo().layoutName
        if not TMW.db then return end

        -- DONT call UpdateSystemSettingShowTooltips, it will taint.
        -- viewer:UpdateSystemSettingShowTooltips()
        viewer:UpdateSystemSettingOpacity()
        if EditModeManagerFrame:IsEditModeActive() then
            return
        end

        local shouldHide = TMW.db.global.EditModeLayouts[layoutName].CDMHide[settingName]
            or GetGroupHidingViewer(settingName) ~= nil

        if shouldHide then
            viewer:SetAlpha(0)
            -- DONT call SetTooltipsShown, it will taint.
            -- Instead, manually iterate and disable mouse motion so tooltips don't appears on invisible frames.
            for itemFrame in viewer.itemFramePool:EnumerateActive() do
                itemFrame:SetMouseMotionEnabled(false);
            end
        end
    end

    TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", function()
        for _, viewer in pairs(viewers) do
            TMW.safecall(ApplyViewerOverride, viewer)
        end
    end)

    local alwaysHideCheck
    local groupHideAnchor
    local groupHideText
    TMW.safecall(function()
        for _, viewer in pairs(viewers) do
            hooksecurefunc(viewer, "RefreshLayout", ApplyViewerOverride)
        end

        -- Add an extra setting checkbox to edit mode on the CDM frames we want to be hidable.
        -- Don't parent to EditModeSystemSettingsDialog, it'll glitch out EditModeSystemSettingsDialog
        -- when `check` is hidden and make it go super wide for some reason.
		-- Note: alwaysHideCheck is deprecated in favor of groupHideText.
        alwaysHideCheck = CreateFrame("CheckButton", "TMWEditModeCDMHide", TMW, "EditModeSettingCheckboxTemplate")
        alwaysHideCheck:SetFrameStrata("FULLSCREEN")
        alwaysHideCheck:SetWidth(140)
        alwaysHideCheck.Label:SetText("TMW: Always Hide")
        alwaysHideCheck.Label:SetWidth(140)
        TMW:TT(alwaysHideCheck, "UIPANEL_HIDE_CDM", "UIPANEL_HIDE_CDM_DESC")
        TMW:TT(alwaysHideCheck.Button, "UIPANEL_HIDE_CDM", "UIPANEL_HIDE_CDM_DESC")

        -- Create an anchor frame and a text label to show which group is hiding this viewer
        groupHideAnchor = CreateFrame("Frame", "TMWEditModeCDMHidden", TMW)
        groupHideAnchor:SetFrameStrata("FULLSCREEN")
        groupHideAnchor:SetSize(1, 1)
        groupHideAnchor:SetPoint("TOPLEFT", EditModeSystemSettingsDialog, "TOPLEFT", 20, -30)

        groupHideText = groupHideAnchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        groupHideText:SetPoint("TOPLEFT")
        groupHideText:SetWidth(280)
        groupHideText:SetJustifyH("LEFT")

        EditModeSystemSettingsDialog:HookScript("OnHide", function(self)
            alwaysHideCheck:Hide()
            groupHideAnchor:Hide()
        end)
    end)

    -- Add the checkbox to the edit mode dialog when appropriate
    hooksecurefunc(EditModeSystemSettingsDialog, "AttachToSystemFrame", function(self, systemFrame)
        if not groupHideText then return end
        if not tContains(viewers, systemFrame) then
            alwaysHideCheck:Hide()
            return
        end

        local layoutName = EditModeManagerFrame:GetActiveLayoutInfo().layoutName
        local settingTable = TMW.db.global.EditModeLayouts[layoutName].CDMHide
        local settingName = systemFrame.systemIndex

        if not settingTable[settingName] then
            -- This deprecated setting isn't enabled.
            alwaysHideCheck:Hide()
        else
            -- Position next to "Show timer"
            for _, frame in TMW:Vararg(self.Settings:GetChildren()) do
                if frame.setting == Enum.EditModeCooldownViewerSetting.ShowTimer then
                    alwaysHideCheck:SetPoint("LEFT", frame, "LEFT", frame:GetWidth() / 2 + 5, 0)
                    break
                end
            end
            alwaysHideCheck:Show()
            alwaysHideCheck.Button:SetChecked(settingTable[settingName] or false)
            alwaysHideCheck.Button:SetScript("OnClick", function(btn)
                settingTable[settingName] = btn:GetChecked()
            end)
        end

        -- Show which group is hiding this viewer, if any
        if groupHideText then
            local hidingGroup = GetGroupHidingViewer(settingName)
            if hidingGroup then
                groupHideText:SetText("|cFFFF5050" .. L["CDM_HIDDEN_BY_GROUP"]:format(hidingGroup:GetGroupName()))
                groupHideAnchor:Show()
            else
                groupHideAnchor:Hide()
            end
        end
    end)
end

BaseConfig:RegisterConfigPanel_XMLTemplate(20, "TellMeWhen_GM_Dims")

BaseConfig:RegisterConfigPanel_XMLTemplate(21, "TellMeWhen_GM_Texture")

