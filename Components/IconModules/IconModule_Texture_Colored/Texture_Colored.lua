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

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local type = type
local bitband = bit.band

local OnGCD = TMW.OnGCD

local ColorMSQ, OnlyMSQ

local Texture_Colored = TMW:NewClass("IconModule_Texture_Colored", "IconModule_Texture")

TMW:RegisterDatabaseDefaults({
	profile = {
		ColorMSQ = false,
		OnlyMSQ  = false,
	}
})

if LMB then
	Texture_Colored:RegisterConfigPanel_ConstructorFunc(9, "TellMeWhen_Main_Texture_Colored", function(self)
		self:SetTitle("Masque")
		
		self:BuildSimpleCheckSettingFrame({
			numPerRow = 1,
			function(check)
				check:SetTexts(L["COLOR_MSQ_COLOR"], L["COLOR_MSQ_COLOR_DESC"])
				check:SetSetting("ColorMSQ")
			end,
			function(check)
				check:SetTexts(L["COLOR_MSQ_ONLY"], L["COLOR_MSQ_ONLY_DESC"])
				check:SetSetting("OnlyMSQ")

				check:CScriptAdd("ReloadRequested", function()
					check:SetEnabled(TMW.db.profile.ColorMSQ)
				end)
			end,
		})
	end):SetPanelSet("profile")
end


function Texture_Colored:SetupForIcon(icon)
	self.ShowTimer = icon.ShowTimer
	self:STATE(icon, icon.attributes.state)
end

local COLOR_UNLOCKED = {
	Color = "ffffffff",
	Gray = false,
}
function Texture_Colored:STATE(icon, stateData)
	local color
	if not TMW.Locked or not stateData then
		color = "ffffffff"
	else
		color = stateData.Color
	end
	
	local texture = self.texture
	local c = TMW:StringToCachedRGBATable(color)
	
	if not (LMB and OnlyMSQ) then
		texture:SetVertexColor(c.r, c.g, c.b, 1)
	else
		texture:SetVertexColor(1, 1, 1, 1)
	end

	texture:SetDesaturated(c.flags and c.flags.desaturate or false)
	
	if LMB and ColorMSQ then
		-- This gets set by IconModule_IconContainer_Masque
		local normaltex = icon.normaltex
		if normaltex then
			normaltex:SetVertexColor(c.r, c.g, c.b, 1)
		end
	end
end

Texture_Colored:SetDataListner("STATE", Texture_Colored.STATE)


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ColorMSQ = TMW.db.profile.ColorMSQ
	OnlyMSQ = TMW.db.profile.OnlyMSQ
end)