-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


local TMW = TMW
local L = TMW.L
local print = TMW.print

function TellMeWhen_OnAddonCompartmentClick(addonName, button) 
	if not TMW then return end
	if button == "RightButton" then
		TMW:SlashCommand("options")
	else
		TMW:LockToggle()
	end
end

function TellMeWhen_AddonCompartmentFuncOnEnter(name, btn)
	local f
	if btn and type(btn[0]) == "userdata" then
		-- MAYBE WORKS IN TWW - Addon compartment onEnter functions seem to currently not be called
		f = btn
	elseif GetMouseFocus then
		f = GetMouseFocus()
		while f and not f.dropdown do
			f = f:GetParent()
		end
	end
	
	if not f then return end

	GameTooltip:SetOwner(f, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, 0)

	if not TMW then 
		GameTooltip:AddLine("TellMeWhen failed to load.")
		GameTooltip:Show()
		return
	end

	GameTooltip:AddLine("TellMeWhen")
	GameTooltip:AddLine(L["LDB_TOOLTIP1"])
	GameTooltip:AddLine(L["LDB_TOOLTIP2"])
	GameTooltip:Show()
end

function TellMeWhen_AddonCompartmentFuncOnLeave() 
	GameTooltip:Hide()
end

if not TMW then return end


local ldb = LibStub("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("TellMeWhen") or
	ldb:NewDataObject("TellMeWhen", {
		type = "launcher",
		icon = "Interface\\Addons\\TellMeWhen\\Textures\\LDB Icon",
	})

dataobj.OnClick = function(self, button)
	if not TMW.Initialized then
		TMW:Print(L["ERROR_NOTINITIALIZED_NO_ACTION"])
		return
	end
	
	if button == "RightButton" then
		TMW:SlashCommand("options")
	else
		TMW:LockToggle()
	end
end

dataobj.OnTooltipShow = function(tt)
	tt:AddLine("TellMeWhen")
	tt:AddLine(L["LDB_TOOLTIP1"])
	tt:AddLine(L["LDB_TOOLTIP2"])
end