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
	

 isMoving = nil
function TMW:Group_StopMoving(group)
	group:StopMovingOrSizing()
	
	isMoving = nil
	
	local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
	GroupModule_GroupPosition:UpdatePositionAfterMovement()
	
	group:Setup()
	
	TMW.IE:NotifyChanges()
end

function TMW:Group_ResetPosition(groupID)
	for k, v in pairs(TMW.Group_Defaults.Point) do
		TMW.db.profile.Groups[groupID].Point[k] = v
	end
	TMW.db.profile.Groups[groupID].Scale = 1
	TMW.db.profile.Groups[groupID].Locked = false
	TMW.IE:NotifyChanges()
	TMW[groupID]:Setup()
end


	
local Module = TMW:NewClass("IconModule_GroupMover", "IconModule"){

	METHOD_EXTENSIONS = {
		OnImplementIntoIcon = function(self)
			local icon = self.icon
			local group = icon.group
			
			local GroupModule_GroupPosition = group:GetModuleOrModuleChild("GroupModule_GroupPosition")
			
			if not GroupModule_GroupPosition then
				error("Implementing IconModule_GroupMover (or a derivative) requies that GroupModule_GroupPosition (or a derivative) be already implemented.")
			end
		end,
	},
	
	OnNewInstance_GroupMover = function(self, icon)
		icon:RegisterForDrag("LeftButton", "RightButton")
	end,
}

Module:SetScriptHandler("OnDragStart", function(Module, icon, button)
	if button == "LeftButton" then
		local group = icon:GetParent()
		if not TMW.Locked and not group.Locked then
			group:StartMoving()
			isMoving = group
		end
	end
end)

Module:SetScriptHandler("OnDragStop", function(Module, icon)
	if isMoving then
		TMW:Group_StopMoving(isMoving)
	end
end)

WorldFrame:HookScript("OnMouseDown", function(WorldFrame, button)
	-- Sometimes, if a group/icon does some things to itself while moving (I don't remember exactly what, but it is possible),
	-- OnDragStop won't fire when it should. Having this here makes sure that the user doesn't get a group permanantly stuck to their cursor.
	
	if isMoving then
		TMW:Group_StopMoving(isMoving)
	end
end)

Module:SetScriptHandler("OnMouseUp", function(Module, icon, button)
	if not TMW.Locked then
		if isMoving then
			TMW:Group_StopMoving(isMoving)
		end
	end
end)



TMW.ID:RegisterIconDragHandler(30,	-- Anchor
	function(ID, info)
		local name, desc

		local srcname = TMW:GetGroupName(ID.srcicon.group:GetID(), ID.srcicon.group:GetID())

		if ID.desticon and ID.srcicon.group:GetID() ~= ID.desticon.group:GetID() then
			local destname = L["fGROUP"]:format(TMW:GetGroupName(ID.desticon.group:GetID(), ID.desticon.group:GetID(), 1))
			name = L["ICONMENU_ANCHORTO"]:format(destname)
			desc = L["ICONMENU_ANCHORTO_DESC"]:format(srcname, destname, destname, srcname)

		elseif ID.destFrame and ID.destFrame:GetName() then
			if ID.destFrame == WorldFrame and ID.srcicon.group.Point.relativeTo ~= "UIParent" then
			
				
				local currentFrameName = ID.srcicon.group.Point.relativeTo
				
				local groupID = currentFrameName:match("^TellMeWhen_Group(%d+)")
				local iconID = currentFrameName:match("^TellMeWhen_Group%d+_Icon(%d+)")
				
				if iconID and groupID then
					currentFrameName = L["GROUPICON"]:format(TMW:GetGroupName(groupID, groupID, 1), iconID)
				elseif groupID then
					currentFrameName = TMW:GetGroupName(groupID, groupID)
				end
				
				name = L["ICONMENU_ANCHORTO_UIPARENT"]
				desc = L["ICONMENU_ANCHORTO_UIPARENT_DESC"]:format(srcname, currentFrameName)

			elseif ID.destFrame ~= WorldFrame then
				local destname = ID.destFrame:GetName()
				name = L["ICONMENU_ANCHORTO"]:format(destname)
				desc = L["ICONMENU_ANCHORTO_DESC"]:format(srcname, destname, destname, srcname)
			end
		end

		if name then
			info.text = name
			info.tooltipTitle = name
			info.tooltipText = desc
			return true
		end
	end,
	function(ID)
		if ID.desticon then
			-- we are anchoring to another TMW group, so dont operate on the same group.
			if ID.desticon.group == ID.srcicon.group then
				return
			end

			-- set the setting
			ID.srcicon.group.Point.relativeTo = ID.desticon.group:GetName()
		else
			local name = ID.destFrame:GetName()
			-- we are anchoring to some other frame entirely.
			if ID.destFrame == WorldFrame then
				-- If it was dragged to WorldFrame then reset the anchor to UIParent (the text in the dropdown is custom for this circumstance)
				name = "UIParent"
			elseif ID.destFrame == ID.srcicon.group then
				-- this should never ever ever ever ever ever ever ever ever happen.
				return
			elseif not ID.destFrame:GetName() then
				-- make sure it actually has a name
				return
			end

			-- set the setting
			ID.srcicon.group.Point.relativeTo = name
		end

		-- do adjustments and positioning
		-- i cheat. we didnt really stop moving anything, but i'm going to hijack this function anyway.
		TMW:Group_StopMoving(ID.srcicon.group)
	end
)