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
		if TMW:CheckCanDoLockedAction() then
			TMW:LoadOptions()
			LibStub("AceConfigDialog-3.0"):Open("TMW Options")
		end
	else
		TMW:LockToggle()
	end
end

dataobj.OnTooltipShow = function(tt)
	tt:AddLine("TellMeWhen")
	tt:AddLine(L["LDB_TOOLTIP1"])
	tt:AddLine(L["LDB_TOOLTIP2"])
end