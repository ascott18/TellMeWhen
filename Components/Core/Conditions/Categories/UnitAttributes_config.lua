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

local SUG = TMW.SUG

local Module = SUG:NewModule("creaturetype", SUG:GetModule("default"))
Module.noMin = true
Module.noTexture = true
Module.NUM_CREATURE_TYPES = 14
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

function Module:Entry_AddToList_1(f, index)
	local creaturetypeLocalized = L["CREATURETYPE_" .. index]
	
	f.tooltiptitle = creaturetypeLocalized
	
	f.Name:SetText(creaturetypeLocalized)
	
	f.insert = creaturetypeLocalized
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local lastName = SUG.lastName

	for index = 1, self.NUM_CREATURE_TYPES do
		local creaturetypeLocalized = L["CREATURETYPE_" .. index]
	
		if strfind(strlower(creaturetypeLocalized), lastName) then
			suggestions[#suggestions + 1] = index
		end
	end
end
function Module:Table_GetSorter()
	return nil
end

