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
	
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 1,
		{
			setting = "OnlyInCombat",
			title = L["UIPANEL_ONLYINCOMBAT"],
			tooltip = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"],
		},
	})
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(11, "TellMeWhen_GS_Role", function(self)
	self.Header:SetText(ROLE)
	
	TMW.IE:BuildSimpleCheckSettingFrame(self, "Config_CheckButton_BitToggle", {
		numPerRow = 3,
		{
			setting = "Role",
			title = DAMAGER,
			tooltip = L["UIPANEL_ROLE_DESC"],
			value = 1,
		},
		{
			setting = "Role",
			title = HEALER,
			tooltip = L["UIPANEL_ROLE_DESC"],
			value = 2,
		},
		{
			setting = "Role",
			title = TANK,
			tooltip = L["UIPANEL_ROLE_DESC"],
			value = 3,
		},
	})
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(12, "TellMeWhen_GS_Tree", function(self)
	self.Header:SetText(SPECIALIZATION)
	
	local data = {
		numPerRow = 2
	}	

	for i = 1, GetNumSpecializations() do
		local _, name = GetSpecializationInfo(i)
		tinsert(data, {
			setting = "Tree"..i,
			title = name,
			tooltip = L["UIPANEL_TREE_DESC"],
		})
	end

	TMW.IE:BuildSimpleCheckSettingFrame(self, data)
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(13, "TellMeWhen_GS_DualSpec", function(self)
	self.Header:SetText(L["UIPANEL_SPEC"])
	
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 2,
		{
			setting = "PrimarySpec",
			title = L["UIPANEL_PRIMARYSPEC"],
			tooltip = L["UIPANEL_TOOLTIP_PRIMARYSPEC"],
		},
		{
			setting = "SecondarySpec",
			title = L["UIPANEL_SECONDARYSPEC"],
			tooltip = L["UIPANEL_TOOLTIP_SECONDARYSPEC"],
		},
	})
end)

BaseConfig:RegisterConfigPanel_XMLTemplate(20, "TellMeWhen_GM_Dims")

BaseConfig:RegisterConfigPanel_XMLTemplate(50, "TellMeWhen_GM_DBLoc")