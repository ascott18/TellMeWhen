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

TMW:NewClass("GroupModule_Resizer_ScaleXY", "GroupModule_Resizer"){
	tooltipText = L["RESIZE_TOOLTIP_SCALEXY"],
	scale_min = 0.6,

	OnNewInstance_GroupModule_Resizer_ScaleXY = function(self)
		self:SetModes(self.MODE_SCALE, self.MODE_SCALE)
	end,

	SizeUpdated = function(self)
		local group = self.group
		local gs = group:GetSettings()

		gs.Scale = group:GetScale()
	end,
}
