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


local Module = SUG:NewModule("talents", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)

	if C_Traits then
		-- A "config" is a loadout - either the current one (maybe unsaved), or a saved one.
		local configID = C_ClassTalents.GetActiveConfigID()
		local configInfo = C_Traits.GetConfigInfo(configID)

		-- I have no idea why the concept of trees exists.
		-- It seems that every class has a single tree, regardless of spec.
		for _, treeID in pairs(configInfo.treeIDs) do

			-- Nodes are circles/square in the talent tree.
			for _, nodeID in pairs(C_Traits.GetTreeNodes(treeID)) do
				local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)

				-- Entries are the choices in each node.
				-- Choice nodes have two, otherwise there's only one.
				for _, entryID in pairs(nodeInfo.entryIDs) do
					local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
					-- Definition seems a useless layer between entry and spellID.
					-- Blizzard's in-game API help about them is currently completely wrong
					-- about what fields it has. Currently the only field I see is spellID.
					local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
					local spellID = definitionInfo.spellID
					local name, _, tex = GetSpellInfo(spellID)

					-- The ranks are stored on the node, but we
					-- have to make sure that we're looking at the ranks for the
					-- currently selected entry for the talent.
					local ranks = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID == entryID and nodeInfo.ranksPurchased or 0

					local lower = name and strlowerCache[name]
					if lower then
						self.table[spellID] = lower
					end
				end
			end
		end
	else
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, name = GetTalentInfo(tier, column, 1)
				
				local lower = name and strlowerCache[name]
				if lower then
					self.table[id] = lower
				end
			end
		end
	end


	return self.table
end
function Module:Entry_AddToList_1(f, id)
	if C_Traits then
		local name = GetSpellInfo(id)
	
		f.Name:SetText(name)
		f.insert = name

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id
	
		f.Icon:SetTexture(GetSpellTexture(id))
	else
		local id, name, iconTexture = GetTalentInfoByID(id) -- restore case

		f.Name:SetText(name)
		f.insert = name
	
		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = GetTalentLink(id)
	
		f.Icon:SetTexture(iconTexture)
	end

	f.ID:SetText(id)
	f.insert2 = id
end
Module.Entry_Colorize_1 = TMW.NULLFUNC


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




local Module = SUG:NewModule("azerite_essence", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)
	local essences = C_AzeriteEssence.GetEssences()
	if not essences then  
		return self.table
	end
	
	for _, info in pairs(essences) do
		self.table[info.ID] = strlowerCache[info.name]
	end

	return self.table
end
function Module:Table_GetSorter()
	if SUG.inputType == "number" then
		return nil -- use the default sort func
	else
		SUG.SortTable = self:Table_Get()
		return self.Sorter_ByName
	end
end
function Module:Entry_AddToList_1(f, id)
	local info = C_AzeriteEssence.GetEssenceInfo(id)

	f.Name:SetText(info.name)
	f.ID:SetText(id)

	f.tooltipmethod = "SetAzeriteEssence"
	f.tooltiparg = id

	f.insert = info.name
	f.insert2 = id

	f.Icon:SetTexture(info.icon)
end




local Module = SUG:NewModule("soulbind", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}
function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)

	for id = 1, 30 do
		local data = C_Soulbinds.GetSoulbindData(id)
		if data.name and data.name ~= "" then
			self.table[id] = strlowerCache[data.name]
		end
	end

	return self.table
end
function Module.Sorter(a, b)
	local nameA, nameB = C_Soulbinds.GetSoulbindData(a), C_Soulbinds.GetSoulbindData(b)
	if nameA.covenantID == nameB.covenantID then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA.covenantID < nameB.covenantID
	end
end
function Module:Table_GetSorter()
	return self.Sorter
end
function Module:Entry_AddToList_1(f, id)
	local info = C_Soulbinds.GetSoulbindData(id)

	f.Name:SetText(info.name)
	f.ID:SetText(id)

	f.tooltiptitle = info.name
	f.tooltiptext = info.description

	f.insert = info.name
	f.insert2 = id

	f.Icon:SetTexture(TMW.CovenantIcons[info.covenantID])
end
Module.Entry_Colorize_1 = TMW.NULLFUNC