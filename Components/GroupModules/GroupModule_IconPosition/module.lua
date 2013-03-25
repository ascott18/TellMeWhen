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



local IconPosition = TMW:NewClass("GroupModule_IconPosition", "GroupModule")


IconPosition:RegisterGroupDefaults{
	SettingsPerView			= {
		["**"] = {
			SpacingX		= 0,
			SpacingY		= 0,
		}
	},
}

TMW:RegisterUpgrade(60005, {
	group = function(self, gs)
		gs.SettingsPerView.icon.SpacingX = gs.Spacing or 0
		gs.SettingsPerView.icon.SpacingY = gs.Spacing or 0
		gs.Spacing = nil
	end,
})


function IconPosition:OnEnable()
	TMW:RegisterCallback("TMW_GROUP_SETUP_POST", self)
end

function IconPosition:OnDisable()
	TMW:UnregisterCallback("TMW_GROUP_SETUP_POST", self)
end


function IconPosition:Icon_SetPoint(icon, positionID)
	self:AssertSelfIsInstance()
	
	local group = self.group
	local gspv = group:GetSettingsPerView()
	
	local Columns = group.Columns
	
	local row = ceil(positionID / Columns)
	local column = (positionID - 1) % Columns + 1
	
	local sizeX, sizeY = group.viewData:Icon_GetSize(icon)
	
	
	local position = icon.position
	
	position.relativeTo = group
	position.point, position.relativePoint = "TOPLEFT", "TOPLEFT"
	position.x = (sizeX + gspv.SpacingX)*(column-1)
	position.y = -(sizeY + gspv.SpacingY)*(row-1)
	
	icon:ClearAllPoints()
	icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x, position.y)
end

function IconPosition:PositionIcons()
	local group = self.group

	for iconID = 1, group.numIcons do
		local icon = group[iconID]
		self:Icon_SetPoint(icon, icon.ID)
	end
end


function IconPosition:TMW_GROUP_SETUP_POST(event, group)
	if self.group == group then
		self:PositionIcons()
	end
end




