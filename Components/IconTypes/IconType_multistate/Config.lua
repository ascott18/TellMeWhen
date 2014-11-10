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
local strlowerCache = TMW.strlowerCache
local GetSpellTexture = TMW.GetSpellTexture

local SpellCache = TMW:GetModule("SpellCache")
local Module_spell = SUG:GetModule("spell")

local Module = SUG:NewModule("multistate", Module_spell)
Module.ActionCache = {}

function Module:Table_Get()
	wipe(self.ActionCache)
	for i=1, 120 do
		local actionType, spellID = GetActionInfo(i)
		if actionType == "spell" and spellID then
			self.ActionCache[spellID] = i
		end
	end

	return SpellCache:GetCache()
end
function Module:Entry_Colorize_2(f, id)
	if self.ActionCache[id] then
		f.Background:SetVertexColor(0, .44, .87, 1) --color actions that are on your action bars shaman blue
	end
end
function Module.Sorter_Spells(a, b)
	--MSCDs
	local haveA, haveB = Module.ActionCache[a], Module.ActionCache[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	return Module_spell.Sorter_Spells(a, b)
end
