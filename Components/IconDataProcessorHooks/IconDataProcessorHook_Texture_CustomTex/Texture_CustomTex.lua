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



local Hook = TMW.Classes.IconDataProcessorHook:New("TEXTURE_CUSTOMTEX", "TEXTURE")

LibStub("AceEvent-3.0"):Embed(Hook)

Hook:RegisterIconDefaults{
	CustomTex				= "",
}

Hook:RegisterConfigPanel_XMLTemplate(190, "TellMeWhen_CustomTex")

Hook:RegisterCompileFunctionSegmentHook("pre", function(Processor, t)
	-- GLOBALS: texture
	t[#t+1] = [[
	texture = icon.CustomTex_OverrideTex or texture -- if a texture override is specified, then use it instead
	--]]
end)


-----------------------
--  varType: item
-----------------------
local IconsWithVarTex_item = {}
function UpdateVarTex_item(icon, varData)
	icon.CustomTex_OverrideTex = GetInventoryItemTexture("player", varData) or nil
	
	-- setting it nil causes the original data processor and the hook to be ran,
	-- but attributes.texture won't change unless the hook actually ended up changing the texture
	icon:SetInfo("texture", nil)
end
function Hook:PLAYER_EQUIPMENT_CHANGED()
	for icon, varData in pairs(IconsWithVarTex_item) do
		UpdateVarTex_item(icon, varData)
	end
end

function Hook:OnImplementIntoIcon(icon)
	local CustomTex = icon.CustomTex:trim()
	
	if CustomTex:sub(1, 1) == "$" then
		local varType, varData = CustomTex:match("^$([^%.:]+)%.?([^:]*)$")
		
		if varType then
			varType = varType:lower():trim(" ")
		end
		if varData then
			varData = varData:trim(" ")
		end
		
		--icon.CustomTex_VarTexType, icon.CustomTex_VarTexData = varType, varData
		
		if varType == "item" then
			varData = tonumber(varData)
			
			if varData and varData <= INVSLOT_LAST_EQUIPPED then
				IconsWithVarTex_item[icon] = varData
				Hook:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
				
				UpdateVarTex_item(icon, varData)
			end
		end
	else
		icon.CustomTex_OverrideTex = TMW:GetTexturePathFromSetting(CustomTex)
	end
	
end

function Hook:OnUnimplementFromIcon(icon)
	icon.CustomTex_OverrideTex = nil
	
	IconsWithVarTex_item[icon] = nil
	if not next(IconsWithVarTex_item) then
		Hook:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	end
end
