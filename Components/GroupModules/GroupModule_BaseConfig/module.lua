-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

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

BaseConfig:RegisterConfigPanel_XMLTemplate(20, "TellMeWhen_GM_Dims")

BaseConfig:RegisterConfigPanel_XMLTemplate(21, "TellMeWhen_GM_Texture")

BaseConfig:RegisterConfigPanel_XMLTemplate(500, "TellMeWhen_GM_Delete")

