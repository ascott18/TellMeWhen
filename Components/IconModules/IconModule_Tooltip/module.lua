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
	

local Module = TMW:NewClass("IconModule_Tooltip", "IconModule")
local title_default = function(icon)
	
	local line1 = "TellMeWhen " .. icon:GetIconName()
		
	if icon.group.Locked then
		line1 = line1 .. " (" .. L["LOCKED"] .. ")"
	end
	
	return line1
end
Module.title = title_default

local text_default = L["ICON_TOOLTIP2NEW"]
Module.text = text_default

Module:ExtendMethod("OnUnimplementFromIcon", function(self)
	self:SetTooltipTitle(title_default, true)
	self:SetTooltipText(text_default, true)
end)

function Module:OnDisable()
	if self.icon:IsMouseOver() and self.icon:IsVisible() then
		GameTooltip:Hide()
	end
end

function Module:SetTooltipTitle(title, dontUpdate)
	self.title = title
	
	-- this should work, even though this tooltip isn't manged by TMW's tooltip handler
	-- (TT_Update is really generic)
	if not dontUpdate then
		TMW:TT_Update(self.icon)
	end
end
function Module:SetTooltipText(text, dontUpdate)
	self.text = text
	
	-- this should work, even though this tooltip isn't manged by TMW's tooltip handler
	-- (TT_Update is really generic)
	if not dontUpdate then
		TMW:TT_Update(self.icon)
	end
end

Module:SetScriptHandler("OnEnter", function(Module, icon)
	if not TMW.Locked then
		GameTooltip_SetDefaultAnchor(GameTooltip, icon)
		GameTooltip:AddLine(TMW.get(Module.title, icon), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
		GameTooltip:AddLine(TMW.get(Module.text, icon), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false)
		
		if TMW.DOGTAGS.AcceptingIcon then
			GameTooltip:AddLine(L["DT_INSERTGUID_TOOLTIP"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false)
		end

		if TMW.db.global.ShowGUIDs then
			GameTooltip:AddLine("")
			if not icon.TempGUID then
				GameTooltip:AddLine(icon:GetGUID(), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
			end
			GameTooltip:AddLine(icon.group:GetGUID(), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
		end

		GameTooltip:Show()
	end
end)

Module:SetScriptHandler("OnLeave", function(Module, icon)
	GameTooltip:Hide()
end)



