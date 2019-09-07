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
local GetSpellTexture = TMW.GetSpellTexture

local Type = rawget(TMW.Types, "wpnenchant")

if not Type then return end



function Type:GuessIconTexture(ics)
	return GetInventoryItemTexture("player", GetInventorySlotInfo(ics.WpnEnchantType or "MainHandSlot"))
	or GetInventoryItemTexture("player", "MainHandSlot")
end

function Type:GetIconMenuText(ics)
	local text = ""
	if ics.WpnEnchantType == "MainHandSlot" or not ics.WpnEnchantType then
		text = INVTYPE_WEAPONMAINHAND
	elseif ics.WpnEnchantType == "SecondaryHandSlot" then
		text = INVTYPE_WEAPONOFFHAND
	elseif ics.WpnEnchantType == "RangedSlot" then
		text = INVTYPE_THROWN
	end
	
	text = text .. " - " .. L["ICONMENU_WPNENCHANT"]

	return text, ""
end



local Module = SUG:NewModule("wpnenchant", SUG:GetModule("default"), "AceEvent-3.0")
Module.noMin = true
Module.noTexture = true
Module.showColorHelp = false

function Module:OnInitialize()
	self.Table = {}
end

function Module:Table_Get()
	for k, v in pairs(TMW.db.locale.WpnEnchDurs) do
		if not self.Table[k] then
			self.Table[k] = k
		end
	end

	return self.Table
end
function Module:Entry_AddToList_1(f, name)
	f.Name:SetText(name)
	f.ID:SetText(nil)

	f.tooltiptitle = name

	f.insert = name
end

function Module:Table_GetSorter()
	return self.Sorter
end
function Module.Sorter(a, b)
	--sort by name
	return a < b
end

function Module:Table_GetNormalSuggestions(suggestions, tbl)
	local atBeginning = SUG.atBeginning

	for name in pairs(tbl) do
		if SUG.inputType == "number" or strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = name
		end
	end
end

