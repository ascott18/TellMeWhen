-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")

local function makeId(tab, talent)
	return "" .. tab .. "," .. talent
end
local function parseId(id)
	return (","):split(id)
end

local Module = SUG:NewModule("talents", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	-- nothing
end
function Module:Table_GetSorter()
	SUG.SortTable = self:Table_Get()
	return self.Sorter_ByName
end
function Module:Table_Get()
	wipe(self.table)

	for tab = 1, GetNumTalentTabs() do
		for talent = 1, GetNumTalents(tab) do
			local name, iconTexture = GetTalentInfo(tab, talent)
			
			local lower = name and strlowerCache[name]
			if lower then
				self.table[makeId(tab, talent)] = lower
			end
		end
	end

	return self.table
end
function Module:Entry_AddToList_1(f, id)
	local tab, talent = parseId(id)
	local name, iconTexture = GetTalentInfo(tab, talent)

	f.Name:SetText(name)

	f.tooltipmethod = "SetTalent"
	f.tooltiparg = {tab, talent}

	f.insert = name

	f.Icon:SetTexture(iconTexture)
end
Module.Entry_Colorize_1 = TMW.NULLFUNC
