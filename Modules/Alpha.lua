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


local Alpha = TMW:NewClass("IconModule_Alpha", "IconModule")

Alpha:RegisterIconDefaults{
	FakeHidden				= false,
}


Alpha:RegisterConfigPanel_ConstructorFunc(220, "TellMeWhen_AlphaModuleSettings", function(self)
	self.Header:SetText(L["ICONALPHAPANEL_FAKEHIDDEN"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "FakeHidden",
			title = L["ICONALPHAPANEL_FAKEHIDDEN"],
			tooltip = L["ICONALPHAPANEL_FAKEHIDDEN_DESC"],
		}
	})
end)

function Alpha:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	
	self:REALALPHA(icon, icon.attributes.realAlpha)
end

function Alpha:REALALPHA(icon, realAlpha)
	if TMW.Locked then
		icon:SetAlpha(icon.FakeHidden and 0 or realAlpha)
	else
		icon:SetAlpha(realAlpha)
	end
end

Alpha:SetDataListner("REALALPHA")
