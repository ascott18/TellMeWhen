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
		function(check)
			check:SetTexts(L["UIPANEL_ONLYINCOMBAT"], L["UIPANEL_TOOLTIP_ONLYINCOMBAT"])
			check:SetSetting("OnlyInCombat")
		end,
	})
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(11, "TellMeWhen_GS_Role", function(self)
	self.Header:SetText(ROLE)
	
	TMW.IE:BuildSimpleCheckSettingFrame(self, "Config_CheckButton_BitToggle", {
		numPerRow = 3,
		function(check)
			check:SetTexts(DAMAGER, L["UIPANEL_ROLE_DESC"])
			check:SetSetting("Role", 1)
		end,
		function(check)
			check:SetTexts(HEALER, L["UIPANEL_ROLE_DESC"])
			check:SetSetting("Role", 2)
		end,
		function(check)
			check:SetTexts(TANK, L["UIPANEL_ROLE_DESC"])
			check:SetSetting("Role", 3)
		end,
	})
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(12, "TellMeWhen_GS_Tree", function(self)
	self.Header:SetText(SPECIALIZATION)
	
	local data = {
		numPerRow = 2
	}	

	for i = 1, GetNumSpecializations() do
		local _, name = GetSpecializationInfo(i)
		tinsert(data, function(check)
			check:SetTexts(name, L["UIPANEL_TREE_DESC"])
			check:SetSetting("Tree"..i)
		end)
	end

	TMW.IE:BuildSimpleCheckSettingFrame(self, data)
end)

BaseConfig:RegisterConfigPanel_ConstructorFunc(13, "TellMeWhen_GS_DualSpec", function(self)
	self.Header:SetText(L["UIPANEL_SPEC"])
	
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
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
end)

BaseConfig:RegisterConfigPanel_XMLTemplate(20, "TellMeWhen_GM_Dims")

BaseConfig:RegisterConfigPanel_XMLTemplate(50, "TellMeWhen_GM_DBLoc")