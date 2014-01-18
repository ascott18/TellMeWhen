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

local OnGCD = TMW.OnGCD

local IconPosition_Sortable = TMW:NewClass("GroupModule_IconPosition_Sortable", "GroupModule_IconPosition")


IconPosition_Sortable:RegisterGroupDefaults{
	LayoutDirection = 1,
	
	SortPriorities = {
		{ Method = "id",			Order =	1,	},
		{ Method = "duration",		Order =	1,	},
		{ Method = "stacks",		Order =	-1,	},
		{ Method = "visiblealpha",	Order =	-1,	},
		{ Method = "visibleshown",	Order =	-1,	},
		{ Method = "alpha",			Order =	-1,	},
		{ Method = "shown",			Order =	-1,	},
	},
}


function IconPosition_Sortable:OnNewInstance_IconPosition_Sortable()

	self.SortedIcons = {}
	self.SortedIconsManager = TMW.Classes.UpdateTableManager:New()
	self.SortedIconsManager:UpdateTable_Set(self.SortedIcons)
end


function IconPosition_Sortable:OnEnable()
	local group = self.group
	
	if group.SortPriorities[1].Method ~= "id" and group.numIcons > 1 then
		TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", self)
		TMW:RegisterCallback("TMW_ICON_UPDATED", self)
	end
	TMW:RegisterCallback("TMW_GROUP_SETUP_POST", self)
end
	
function IconPosition_Sortable:OnDisable()
	wipe(self.SortedIcons)
	
	TMW:UnregisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_POST", self)
	TMW:UnregisterCallback("TMW_ICON_UPDATED", self)
	TMW:UnregisterCallback("TMW_GROUP_SETUP_POST", self)
end
	
	
function IconPosition_Sortable:Icon_SetPoint(icon, positionID)
	self:AssertSelfIsInstance()
	--[[
		ABBR	DIR 1, DIR 2	VAL		VAL%4
		RD		RIGHT, DOWN 	1		1 (normal)
		LD		LEFT, DOWN		2		2
		LU		LEFT, UP		3		3
		RU		RIGHT, UP		4		0
		DR		DOWN, RIGHT		5		1
		DL		DOWN, LEFT		6		2
		UL		UP, LEFT		7		3
		UR		UP, RIGHT		8		0
	]]
	
	local group = self.group
	local gs = group:GetSettings()
	local gspv = group:GetSettingsPerView()
	local LayoutDirection = group.LayoutDirection
	
	local row, column
	
	if LayoutDirection >= 5 then
		local Rows = group.Rows
		
		row = (positionID - 1) % Rows + 1
		column = ceil(positionID / Rows)
	else
		local Columns = group.Columns
		
		row = ceil(positionID / Columns)
		column = (positionID - 1) % Columns + 1
	end
	
	local sizeX, sizeY = group.viewData:Icon_GetSize(icon)
	local x, y = (sizeX + gspv.SpacingX)*(column-1), (sizeY + gspv.SpacingY)*(row-1)
	
	
	local point
	if LayoutDirection % 4 == 1 then
		point = "TOPLEFT"
		x, y = x, -y
	elseif LayoutDirection % 4 == 2 then
		point = "TOPRIGHT"
		x, y = -x, -y
	elseif LayoutDirection % 4 == 3 then
		point = "BOTTOMRIGHT"
		x, y = -x, y
	elseif LayoutDirection % 4 == 0 then
		point = "BOTTOMLEFT"
		x, y = x, y
	end
	
	local position = icon.position
	position.relativeTo = group
	position.point, position.relativePoint = point, point
	position.x, position.y = x, y
	
	icon:ClearAllPoints()
	icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x, position.y)
end

function IconPosition_Sortable.IconSorter(iconA, iconB)
	local group = iconA.group
	local SortPriorities = group.SortPriorities
	
	local attributesA = iconA.attributes
	local attributesB = iconB.attributes
	
	for p = 1, #SortPriorities do
		local settings = SortPriorities[p]
		local method = settings.Method
		local order = settings.Order

		if TMW.Locked or method == "id" then
			-- Force sorting by ID when unlocked.
			-- Don't force the first one to be "id" because it also depends on the order that the user has set.
			
			if method == "id" then
				return iconA.ID*order < iconB.ID*order

			elseif method == "alpha" then
				local a, b = attributesA.realAlpha, attributesB.realAlpha
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "visiblealpha" then
				local a, b = iconA:GetAlpha(), iconB:GetAlpha()
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "stacks" then
				local a, b = attributesA.stack or 0, attributesB.stack or 0
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "shown" then
				local a, b = (attributesA.shown and attributesA.realAlpha > 0) and 1 or 0, (attributesB.shown and attributesB.realAlpha > 0) and 1 or 0
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "visibleshown" then
				local a, b = (attributesA.shown and iconA:GetAlpha() > 0) and 1 or 0, (attributesB.shown and iconB:GetAlpha() > 0) and 1 or 0
				if a ~= b then
					return a*order < b*order
				end

			elseif method == "duration" then				
				local time = TMW.time
				
				local durationA = attributesA.duration
				local durationB = attributesB.duration

				durationA = iconA:OnGCD(durationA) and 0 or durationA - (time - attributesA.start)
				durationB = iconB:OnGCD(durationB) and 0 or durationB - (time - attributesB.start)

				if durationA ~= durationB then
					return durationA*order < durationB*order
				end
			end
		end
	end
end

function IconPosition_Sortable:PositionIcons()
	local SortedIcons = self.SortedIcons
	sort(SortedIcons, self.IconSorter)

	for positionID = 1, #SortedIcons do
		local icon = SortedIcons[positionID]
		self:Icon_SetPoint(icon, positionID)
	end
end


function IconPosition_Sortable:TMW_ONUPDATE_TIMECONSTRAINED_POST(event, time, Locked)
	if self.iconSortNeeded then
		self:PositionIcons()
		self.iconSortNeeded = nil
	end
end

function IconPosition_Sortable:TMW_ICON_UPDATED(event, icon)
	if self.group == icon.group then
		self.iconSortNeeded = true
	end
end

function IconPosition_Sortable:TMW_GROUP_SETUP_POST(event, group)
	if self.group == group and group:ShouldUpdateIcons() then
	
		for iconID = 1, group.numIcons do
			local icon = group[iconID]
			if icon then
				self.SortedIconsManager:UpdateTable_Register(group[iconID])
			end
		end
	
		self:PositionIcons()
	end
end



