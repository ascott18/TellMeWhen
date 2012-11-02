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

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures


local Module = SUG:NewModule("wpnenchant", SUG:GetModule("default"), "AceEvent-3.0")
Module.noMin = true

Module.ItemIDs = {
	-- item enhancements
	43233,	--Deadly Poison
	3775,	--Crippling Poison
	5237,	--Mind-Numbing Poison
	43235,	--Wound Poison
	43231,	--Instant Poison

	31535,	--Bloodboil Poison

	3829,	--Frost Oil
	3824,	--Shadow Oil -- good

	36899,	--Exceptional Mana Oil
	22521,	--Superior Mana Oil -- good
	20748,	--Brilliant Mana Oil -- good
	20747,	--Lesser Mana Oil -- good
	20745,	--Minor Mana Oil -- good

	22522,	--Superior Wizard Oil -- good
	20749,	--Brilliant Wizard Oil -- good
	20750,	--Wizard Oil -- good
	20746,	--Lesser Wizard Oil -- good
	20744,	--Minor Wizard Oil -- good


	34539,	--Righteous Weapon Coating
	34538,	--Blessed Weapon Coating

	--23123,	--Blessed Wizard Oil

	--23576,	--Greater Ward of Shielding
	--23575,	--Lesser Ward of Shielding

	--25521,	--Greater Rune of Warding
	--23559,	--Lesser Rune of Warding

	--7307,	--Flesh Eating Worm

	--46006,	--Glow Worm
	--6529,	--Shiny Bauble
	--6532,	--Bright Baubles
	--67404,	--Glass Fishing Bobber
	--69907,	--Corpse Worm
	--62673,	--Feathered Lure
	--34861,	--Sharpened Fish Hook
	--6533,	--Aquadynamic Fish Attractor
	--6530,	--Nightcrawlers
	--68049,	--Heat-Treated Spinning Lure
	--6811,	--Aquadynamic Fish Lens

	--12643,	--Dense Weightstone
	--3241,	--Heavy Weightstone
	--7965,	--Solid Weightstone
	--3240,	--Coarse Weightstone
	--28420,	--Fel Weightstone
	--28421,	--Adamantite Weightstone
	--3239,	--Rough Weightstone

	--23529,	--Adamantite Sharpening Stone
	--7964,	--Solid Sharpening Stone
	--23122,	--Consecrated Sharpening Stone
	--2871,	--Heavy Sharpening Stone
	--23528,	--Fel Sharpening Stone
	--2862,	--Rough Sharpening Stone
	--2863,	--Coarse Sharpening Stone
	--12404,	--Dense Sharpening Stone
	--18262,	--Elemental Sharpening Stone

	-- ZHTW:
	-- weightstone: ???
	-- sharpening stone: ???
	--25679,	--Comfortable Insoles
}
Module.SpellIDs = {
	-- Shaman Enchants
	8024,	--Flametongue Weapon
	8033,	--Frostbrand Weapon
	8232,	--Windfury Weapon
	51730,	--Earthliving Weapon
	8017,	--Rockbiter Weapon
}

local CurrentItems
function Module:OnInitialize()
	self.Items = {}
	self.Spells = {}
	self.Table = {}
	self.SpellLookup = {}


	self:Etc_DoItemLookups()

	for _, id in pairs(self.SpellIDs) do
		local name = GetSpellInfo(id)
		for _, enchant in TMW:Vararg(strsplit("|", L["SUG_MATCH_WPNENCH_ENCH"])) do
			local dobreak
			enchant = name:match(enchant)
			if enchant then
				for ench in pairs(TMW.db.global.WpnEnchDurs) do
					if ench:lower():find(enchant:gsub("([%%%[%]%-%+])", "%%%1"):lower()) then
						-- the enchant was found in the list of known enchants, so add it
						self.Spells[ench] = id
						dobreak = 1
						break
					end
				end
				if dobreak then
					break
				elseif GetLocale() ~= "ruRU" or (GetLocale() == "koKR" and id ~= 51730) then
					-- the enchant was not found in the list of known enchants, so take a guess and add it (but not for ruRU because it is just screwed up
					-- koKR is screwed up for earthliving, so dont try it either
					self.Spells[enchant] = id
				end
			end
		end
	end

	for k, v in pairs(self.Spells) do
		if self.Table[k] then
			TMW:Error("Attempted to add spellID %d, but an item already has that id.", k)
		else
			self.Table[k] = v
		end
	end

	for k, v in pairs(TMW.db.global.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end

	for name in pairs(self.Table) do
		self:Etc_GetTexture(name) -- cache textures for the spell breakdown tooltip
	end
end
function Module:OnSuggest()
	TMW:GetModule("ItemCache"):CacheItems()
	CurrentItems = TMW:GetModule("ItemCache"):GetCurrentItems()
end
function Module:Etc_DoItemLookups()
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")

	for k, id in pairs(self.ItemIDs) do
		local name = GetItemInfo(id)
		if name then
			self.Items[name] = id
		else
			self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "Etc_DoItemLookups")
		end
	end

	for k, v in pairs(self.Items) do
		self.Table[k] = v
	end
end
function Module:Table_Get()

	for k, v in pairs(TMW.db.global.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end

	return self.Table
end
function Module:Entry_AddToList_1(f, name)
	if self.Spells[name] then
		local id = self.Spells[name]
		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = name
	elseif self.Items[name] then
		local id = CurrentItems[strlowerCache[name]] or self.Items[name]
		local name, link = GetItemInfo(id)

		f.Name:SetText(link:gsub("[%[%]]", ""))
		f.ID:SetText(nil)

		f.insert = name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link
	else
		f.Name:SetText(name)
		f.ID:SetText(nil)

		f.tooltiptitle = name

		f.insert = name
	end

	f.Icon:SetTexture(self:Etc_GetTexture(name))
end
function Module:Etc_GetTexture(name)
	local tex
	if self.Spells[name] then
		tex = SpellTextures[self.Spells[name]]
	elseif self.Items[name] then
		tex = GetItemIcon(self.Items[name])
	else
		if name:match(L["SUG_PATTERNMATCH_FISHINGLURE"]) then
			tex = "Interface\\Icons\\inv_fishingpole_02"
		elseif name:match(L["SUG_PATTERNMATCH_WEIGHTSTONE"]) then
			tex = "Interface\\Icons\\inv_stone_weightstone_02"
		elseif name:match(L["SUG_PATTERNMATCH_SHARPENINGSTONE"]) then
			tex = "Interface\\Icons\\inv_stone_sharpeningstone_01"
		end
	end

	name = strlower(name)
	TMW.SpellTexturesMetaIndex[name] = TMW.SpellTexturesMetaIndex[name] or tex

	return tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local PlayerSpells
function Module:Table_GetSorter()
	TMW:GetModule("ItemCache"):CacheItems(true)
	
	PlayerSpells = TMW:GetModule("ClassSpellCache"):GetPlayerSpells()
	
	return self.Sorter
end
function Module.Sorter(a, b)
	local haveA = Module.Spells[a] and PlayerSpells[Module.Spells[a]]
	local haveB = Module.Spells[b] and PlayerSpells[Module.Spells[b]]

	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	local haveA = Module.Items[a] and (CurrentItems[ strlowerCache[ a ]] )
	local haveB = Module.Items[b] and (CurrentItems[ strlowerCache[ b ]] )

	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	-- its a very small table to sort, so i can get away with this (efficiency wise)
	local haveA = rawget(TMW.db.global.WpnEnchDurs, a)
	local haveB = rawget(TMW.db.global.WpnEnchDurs, b)
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end


	local nameA, nameB = Module.Table[a], Module.Table[b]

	if a == b then
		--sort identical names by ID
		return Module.Table[a] < Module.Table[b]
	else
		--sort by name
		return a < b
	end
end

function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for name, id in pairs(tbl) do
		if SUG.inputType == "number" or strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = name
		end
	end
end
function Module:Entry_Colorize_1(f, name)
	if PlayerSpells[Module.Spells[name]] or (CurrentItems[ strlowerCache[ name ]]) then
		f.Background:SetVertexColor(.41, .8, .94, 1) --color all spells and items that you have mage blue
		
	elseif rawget(TMW.db.global.WpnEnchDurs, name) then
		f.Background:SetVertexColor(.79, .30, 1, 1) -- color all known weapon enchants purple
	end
end

