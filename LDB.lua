-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock 
-- Cybeloras of Mal'Ganis
-- --------------------


local L = TMW and TMW.L

local ldb = LibStub("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("TellMeWhen") or
	ldb:NewDataObject("TellMeWhen", {
		type = "launcher",
		icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	})

dataobj.OnClick = function(self, button)
	if button == "RightButton" then
		TMW:LoadOptions()
		LibStub("AceConfigDialog-3.0"):Open("TMW Options")
	else
		TMW:LockToggle()
	end
end

dataobj.OnTooltipShow = function(tt)
	tt:AddLine(L["ICON_TOOLTIP1"])
	tt:AddLine(L["LDB_TOOLTIP1"])
	tt:AddLine(L["LDB_TOOLTIP2"])
end