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


local Module = SUG:NewModule("talents", SUG:GetModule("spell"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

-- TODO-CLASSIC: I started working on this suggestion module during the stress test,
-- but ran out of time. It 100% doesn't work. Question: Are TalentIDs a thing we can stil use?
function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)

	for tab = 1, GetNumTalentTabs() do
		for talent = 1, GetNumTalents(tab) do
			local name, iconTexture = GetTalentInfo(tab, talent)
			
			local lower = name and strlowerCache[name]
			if lower then
				self.table[{tab, talent}] = lower
			end
		end
	end

	return self.table
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, tabTal)
	local name, iconTexture = GetTalentInfo(tabTal[1], tabTal[2])

	f.Name:SetText(name)

	f.tooltipmethod = "SetHyperlink"
	f.tooltiparg = GetTalentLink(id)

	f.insert = name

	f.Icon:SetTexture(iconTexture)
end
Module.Entry_Colorize_1 = TMW.NULLFUNC


-- TODO: Redo this for the new pvp talent system.
local Module = SUG:NewModule("pvptalents", SUG:GetModule("talents"))
Module.table = {}

function Module:Table_Get()
	wipe(self.table)

	for slot = 1, 10 do
		local info = C_SpecializationInfo.GetPvpTalentSlotInfo(slot)
		if not info then break end

		for _, id in pairs(info.availableTalentIDs) do 
			local _, name = GetPvpTalentInfoByID(id)
			
			local lower = name and strlowerCache[name]
			if lower then
				self.table[id] = lower
			end
		end
	end

	return self.table
end
function Module:Entry_AddToList_1(f, id)
	local id, name, iconTexture = GetPvpTalentInfoByID(id) -- restore case

	f.Name:SetText(name)
	f.ID:SetText(id)

	f.tooltipmethod = "SetHyperlink"
	f.tooltiparg = GetPvpTalentLink(id)

	f.insert = name
	f.insert2 = id

	f.Icon:SetTexture(iconTexture)
end
