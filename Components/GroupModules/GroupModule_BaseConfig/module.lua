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


local BaseConfig = TMW:NewClass("GroupModule_BaseConfig", "GroupModule")

BaseConfig.DefaultPanelColumnIndex = 1


BaseConfig:RegisterConfigPanel_XMLTemplate(1, "TellMeWhen_GM_Rename")

BaseConfig:RegisterConfigPanel_ConstructorFunc(9, "TellMeWhen_GS_Combat", function(self)
	self.Header:SetText(COMBAT)
	
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 1,
		function(check)
			check:SetTexts(L["UIPANEL_ONLYINCOMBAT"], L["UIPANEL_TOOLTIP_ONLYINCOMBAT"])
			check:SetSetting("OnlyInCombat")
		end,
	})
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(11, "TellMeWhen_GS_Role", function(self)
	self.Header:SetText(ROLE)
	
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
	self.Header:SetText(SPECIALIZATION)
	
	local data = {
		numPerRow = GetNumSpecializations()
	}	

	for i = 1, GetNumSpecializations() do
		local _, name, _, texture = GetSpecializationInfo(i)
		tinsert(data, function(check)
			check:SetLabel("")
			check:SetTexts(name, L["UIPANEL_TREE_DESC"])
			check:SetSetting("Tree"..i)

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

	self:CScriptAdd("PanelSetup", function()
		if TMW.CI.group.Domain == "global" then
			self:Hide()
		end
	end)
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(13, "TellMeWhen_GS_DualSpec", function(self)
	self.Header:SetText(L["UIPANEL_SPEC"])
	
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 2,
		function(check)
			check:SetTexts(L["UIPANEL_PRIMARYSPEC"], L["UIPANEL_TOOLTIP_PRIMARYSPEC"])
			check:SetSetting("PrimarySpec")
		end,
		function(check)
			check:SetTexts(L["UIPANEL_SECONDARYSPEC"], L["UIPANEL_TOOLTIP_SECONDARYSPEC"])
			check:SetSetting("SecondarySpec")
		end,
	})

	self:CScriptAdd("PanelSetup", function()
		if TMW.CI.group.Domain == "global" then
			self:Hide()
		end
	end)
end)

BaseConfig:RegisterConfigPanel_XMLTemplate(20, "TellMeWhen_GM_Dims")

BaseConfig:RegisterConfigPanel_XMLTemplate(50, "TellMeWhen_GM_DBLoc")