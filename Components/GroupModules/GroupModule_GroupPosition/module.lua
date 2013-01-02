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





---------- Position ----------
local Ruler = CreateFrame("Frame")
local function GetAnchoredPoints(group)
	local gs = group:GetSettings()
	local p = gs.Point

	local relframe = _G[p.relativeTo] or UIParent
	local point, relativePoint = p.point, p.relativePoint

	if relframe == UIParent then
		-- use the smart anchor points provided by UIParent anchoring if it is being used
		local _
		point, _, relativePoint = group:GetPoint(1)
	end

	Ruler:ClearAllPoints()
	Ruler:SetPoint("TOPLEFT", group, point)
	Ruler:SetPoint("BOTTOMRIGHT", relframe, relativePoint)

	local X = Ruler:GetWidth()/UIParent:GetScale()/group:GetScale()
	local Y = Ruler:GetHeight()/UIParent:GetScale()/group:GetScale()
	
	return point, relframe:GetName(), relativePoint, -X, Y
end


TMW:NewClass("GroupModule_GroupPosition", "GroupModule"){
	
	OnEnable = function(self)
		self:SetPos()	
	end,
	
	OnDisable = function(self)
		TMW:UnregisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", "DetectFrame", self)
	end,

	DetectFrame = function(self, event, time, Locked)		
		local frameToFind = self.frameToFind
		
		if _G[frameToFind] then
			self:SetPos()
			TMW:UnregisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", "DetectFrame", self)
		end
	end,
	
	UpdatePositionAfterMovement = function(self)
		self:CalibrateAnchors()
		
		self:SetPos()
	end,
	

	CalibrateAnchors = function(self)
		local group = self.group
		
		local gs = group:GetSettings()
		local p = gs.Point
	
		p.point, p.relativeTo, p.relativePoint, p.x, p.y = GetAnchoredPoints(group)
	end,

	SetPos = function(self)
		local group = self.group
		local groupID = group:GetID()
		
		local gs = group:GetSettings()
		local p = gs.Point
		
		group:ClearAllPoints()
		
		if p.relativeTo == "" then
			p.relativeTo = "UIParent"
		end
		
		p.relativeTo = type(p.relativeTo) == "table" and p.relativeTo:GetName() or p.relativeTo
		local relativeTo = _G[p.relativeTo]
		
		if not relativeTo then
			self.frameToFind = p.relativeTo
			TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", "DetectFrame", self)
			group:SetPoint("CENTER", UIParent)
		else
			local success, err = pcall(group.SetPoint, group, p.point, relativeTo, p.relativePoint, p.x, p.y)
			if not success and err:find("trying to anchor to itself") then
				TMW:Error(err)
				TMW:Print(L["ERROR_ANCHORSELF"]:format(L["fGROUP"]):format(TMW:GetGroupName(groupID, groupID, 1)))

				p.relativeTo = "UIParent"
				p.point = "CENTER"
				p.relativePoint = "CENTER"
				p.x = 0
				p.y = 0

				return self:SetPos()
			end
		end
		
		group:SetFrameStrata(gs.Strata)
		group:SetFrameLevel(gs.Level)
		group:SetScale(gs.Scale)
	end
}





