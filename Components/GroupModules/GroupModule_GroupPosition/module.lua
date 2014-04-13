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


local GroupPosition = TMW:NewClass("GroupModule_GroupPosition", "GroupModule")

GroupPosition:RegisterGroupDefaults{
	Point = {
		point 		  = "CENTER",
		relativeTo 	  = "UIParent",
		relativePoint = "CENTER",
		x 			  = 0,
		y 			  = 0,
	},
}

TMW:RegisterUpgrade(41402, {
	group = function(self, gs)
		gs.Point.defined = nil
	end,
})



local Ruler = CreateFrame("Frame")
local function GetAnchoredPoints(group)
	local gs = group:GetSettings()
	local p = gs.Point

	local relframe = TMW.GUIDToOwner[p.relativeTo] or _G[p.relativeTo] or UIParent
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
	
	if TMW:ParseGUID(p.relativeTo) then
		return point, p.relativeTo, relativePoint, -X, Y
	else
		return point, relframe:GetName(), relativePoint, -X, Y
	end
end

TMW_CursorAnchor = CreateFrame("Frame", "TMW_CursorAnchor", UIParent)
function TMW_CursorAnchor:Initialize()
	self:SetSize(24, 24)
	self:SetFrameStrata("HIGH")
	self:SetFrameLevel(100)

	-- Text
	self.icon = self:CreateTexture(nil, "ARTWORK", nil, 7)
	self.icon:SetAllPoints()
	self.icon:SetTexture("Interface/CURSOR/Point")
	self.icon:SetVertexColor(1, .1, .6)

	self.fs = TMW_CursorAnchor:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	self.fs:SetPoint("TOP", self, "BOTTOM", 0, 13)
	self.fs:SetText("TMW")
	self.fs:SetFont(self.fs:GetFont(), 8, "THINOUTLINE")


	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnSizeChanged", self.CheckState)

	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()

		TMW.IE.db.profile.CursorAnchorPoint = {self:GetPoint()}
		TMW.IE.db.profile.CursorAnchorPoint[2] = nil -- don't store the parent. Its always UIParent.
	end)

	TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", self, "CheckState")

	self:CheckState()

	self.Initialize = TMW.NULLFUNC
end


TMW:RegisterCallback("TMW_OPTIONS_LOADING", function()
	TMW.IE:RegisterDatabaseDefaults({
		profile = {
			CursorAnchorPoint = {
				"CENTER", nil, "CENTER", 0, 100,
			}
		}
	})
end)

function TMW_CursorAnchor:Start()
	self.Started = true
end

function TMW_CursorAnchor:CheckState()
	self:ClearAllPoints()

	self:SetScale(1/UIParent:GetScale())

	if TMW.Locked then
		self:SetClampedToScreen(false)
		self.icon:Hide()
		self.fs:Hide()

		if self.Started then
			self:SetScript("OnUpdate", self.OnUpdate)
		end

		self:EnableMouse(false)
		TMW:TT(self, nil, nil)

	else
		self:SetClampedToScreen(true)
		self.icon:Show()
		self.fs:Show()
		self:SetScript("OnUpdate", nil)

		self:EnableMouse(true)
		TMW:TT(self, "ANCHOR_CURSOR_DUMMY", "ANCHOR_CURSOR_DUMMY_DESC")

		if TMW.IE then
			self:SetPoint(unpack(TMW.IE.db.profile.CursorAnchorPoint))
		else
			self:SetPoint("CENTER", 0, 100)
		end
	end
end

function TMW_CursorAnchor:OnUpdate()
	local x, y = GetCursorPosition()
	local scale = self:GetEffectiveScale()

	self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale, y/scale)
end
TMW_CursorAnchor:Initialize()



function GroupPosition:OnEnable()
	self:SetPos()
end

function GroupPosition:OnDisable()
	TMW:UnregisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", self, "DetectFrame")
end


function GroupPosition:DetectFrame(event, time, Locked)
	local frameToFind = self.frameToFind
	
	if TMW.GUIDToOwner[frameToFind] or _G[frameToFind] then
		self:SetPos()
		TMW:UnregisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", self, "DetectFrame")
	end
end

function GroupPosition:UpdatePositionAfterMovement()
	self:CalibrateAnchors()
	
	self:SetPos()
end


function GroupPosition:CalibrateAnchors()
	local group = self.group
	
	local gs = group:GetSettings()
	local p = gs.Point

	p.point, p.relativeTo, p.relativePoint, p.x, p.y = GetAnchoredPoints(group)
end

function GroupPosition:SetPos()
	local group = self.group
	
	local gs = group:GetSettings()
	local p = gs.Point
	
	group:ClearAllPoints()
	
	if p.relativeTo == "" then
		p.relativeTo = "UIParent"
	end
	
	local relativeTo = p.relativeTo

	if relativeTo:lower() == "cursor" then
		relativeTo = "TMW_CursorAnchor"
	end

	relativeTo = TMW.GUIDToOwner[relativeTo] or _G[relativeTo]
	
	if not relativeTo then
		self.frameToFind = p.relativeTo
		TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", self, "DetectFrame")
		group:SetPoint("CENTER", UIParent)
	else
		if relativeTo == TMW_CursorAnchor then
			TMW_CursorAnchor:Start()
		end

		local success, err = pcall(group.SetPoint, group, p.point, relativeTo, p.relativePoint, p.x, p.y)
		if not success then
			TMW:Error(err)
			
			if err:find("trying to anchor to itself") then
				TMW:Print(L["ERROR_ANCHORSELF"]:format(L["fGROUP"]):format(group:GetGroupName(1)))

			elseif err:find("dependent on this") then
				local thisName = L["fGROUP"]:format(group:GetGroupName(1))
				local relativeToName

				if relativeTo.class == TMW.Classes.Group then
					relativeToName = L["fGROUP"]:format(relativeTo:GetGroupName(1))
				else
					relativeToName = relativeTo:GetName()
				end

				TMW:Print(L["ERROR_ANCHOR_CYCLICALDEPS"]:format(thisName, relativeToName, relativeToName, thisName))
			end

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



