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
local SpellTextures = TMW.SpellTextures

local Type = rawget(TMW.Types, "item")

if not Type then return end


local ItemCache = TMW:GetModule("ItemCache")
local ItemCache_Cache


function Type:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local item = TMW:GetItems(nil, ics.Name)[1]
		if item then
			return item:GetIcon()
		end
	end
end

function Type:DragReceived(icon, t, data, subType)
	local ics = icon:GetSettings()

	if t ~= "item" or not data then
		return
	end

	ics.Name = TMW:CleanString(ics.Name .. ";" .. data)
	return true -- signal success
end


local Module = SUG:NewModule("itemwithslots", SUG:GetModule("item"))
Module.Slots = {}

function Module:OnSuggest()
	ItemCache_Cache = ItemCache:GetCache()
end
function Module:Entry_AddToList_2(f, id)
	if id <= INVSLOT_LAST_EQUIPPED then
		local itemID = GetInventoryItemID("player", id) -- get the itemID of the slot
		local link = GetInventoryItemLink("player", id)

		f.overrideInsertID = L["SUG_INSERTITEMSLOT"]

		local name = GetItemInfo(itemID)

		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText("(" .. id .. ")")

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(itemID))
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local itemID = GetInventoryItemID("player", i) -- get the itemID of the slot
		self.Slots[i] = itemID and GetItemInfo(itemID)
	end

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for id in pairs(self.Slots) do
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	else
		for id, name in pairs(self.Slots) do
			if strfind(strlower(name), atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
end
function Module:Entry_Colorize_1(f, id)
	if id <= INVSLOT_LAST_EQUIPPED then
		f.Background:SetVertexColor(.58, .51, .79, 1) -- color item slots warlock purple
	end
end
function Module.Sorter_ByName(a, b)
	local haveA, haveB = Module.Slots[a], Module.Slots[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	local nameA, nameB = ItemCache_Cache[a], ItemCache_Cache[b]
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end
