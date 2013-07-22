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



local OnGCD = TMW.OnGCD


local Item = TMW:NewClass("Item")


function Item:GetRepresentation(what)
	self:AssertSelfIsClass()

	what = tonumber(what) or what

	if type(what) == "number" then
		if what == 0 then
			return nil
		elseif what <= INVSLOT_LAST_EQUIPPED then
			return TMW.Classes.ItemBySlot:New(what)
		else
			return TMW.Classes.ItemByID:New(what)
		end

	elseif type(what) == "string" then
		what = what:trim(" \t\r\n;")

		if what == "" then
			return nil
		elseif what:find("|H") then
			return TMW.Classes.ItemByLink:New(what)
		else
			return TMW.Classes.ItemByName:New(what)
		end

	else
		return nil
	end
end
TMW:MakeFunctionCached(Item, "GetRepresentation")

function TMW:GetItems(icon, setting)
	local names = TMW:SplitNames(setting)
	
	-- REMOVE SPELL DURATIONS (FOR WHATEVER REASON THE USER MIGHT HAVE PUT THEM IN FOR ITEMS)
	for k, item in pairs(names) do
		if strfind(item, ":[%d:%s%.]*$") then
			local new = strmatch(item, "(.-):[%d:%s%.]*$")
			names[k] = tonumber(new) or new -- turn it into a number if it is one
		end
	end

	if icon then
		names = TMW:LowerNames(names)
	end

	local items = {}

	for k, item in ipairs(names) do
		item = strtrim(item, " \t\r\n;") -- trim crap

		items[#items + 1] = Item:GetRepresentation(item)
	end

	return items
end
TMW:MakeFunctionCached(TMW, "GetItems")




local ItemCount = setmetatable({}, {__index = function(tbl, k)
	if not k then return end
	local count = GetItemCount(k, nil, 1)
	tbl[k] = count
	return count
end})

local function UPDATE_ITEM_COUNT()
	for k in pairs(ItemCount) do
		ItemCount[k] = GetItemCount(k, nil, 1)
	end
end

TMW:RegisterEvent("BAG_UPDATE", UPDATE_ITEM_COUNT)
TMW:RegisterEvent("BAG_UPDATE_COOLDOWN", UPDATE_ITEM_COUNT)



function Item:OnNewInstance_Base(what)
	self.what = what
	self.icon = GetItemIcon(what)
end


function Item:IsInRange(unit)
	return IsItemInRange(self.what, unit)
end
function Item:GetIcon()
	return self.icon
end
function Item:GetCount()
	return ItemCount[self.what]
end
function Item:GetEquipped()
	return IsEquippedItem(self.what)
end
function Item:GetCooldown()
	error("This function must be overridden by subclasses")
end
function Item:GetID()
	error("This function must be overridden by subclasses")
end
function Item:GetName()
	error("This function must be overridden by subclasses")
end
-- These two functions give the remaining cooldown time for an icon.
function Item:GetCooldownDuration()
	local start, duration = self:GetCooldown()
	if duration then
		return (duration == 0 and 0) or (duration - (TMW.time - start))
	end
	return 0
end
function Item:GetCooldownDurationNoGCD()
	local start, duration = self:GetCooldown()
	if duration then
		return ((duration == 0 or OnGCD(duration)) and 0) or (duration - (TMW.time - start))
	end
	return 0
end


-- Create a valid object for invalid item input that may be used.
Item.NullRef = Item:New()
function Item.NullRef:IsInRange(unit)
	return nil
end
function Item.NullRef:GetIcon()
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end
function Item.NullRef:GetCount()
	return 0
end
function Item.NullRef:GetEquipped()
	return nil
end
function Item.NullRef:GetCooldown()
	return 0, 0, 0
end
function Item.NullRef:GetID()
	return 0
end
function Item.NullRef:GetName()
	return "Invalid Item"
end


-- Provide this object for easy external usage.
function TMW:GetNullRefItem()
	return Item.NullRef
end


-- Prevent any other instances of Item from being created.
function Item:OnNewInstance()
	if self.className == "Item" then
		error("TellMeWhen Class 'Item' should not be instantiated.")
	end
end




local ItemByID = TMW:NewClass("ItemByID", Item)

function ItemByID:OnNewInstance(itemID)
	TMW:ValidateType("2 (itemID)", "ItemByID:New(itemID)", itemID, "number")

	self.itemID = itemID
	self.name = GetItemInfo(itemID)
	self.icon = GetItemIcon(itemID)
end


function ItemByID:GetCooldown()
	return GetItemCooldown(self.itemID)
end
function ItemByID:GetID()
	return self.itemID
end
function ItemByID:GetName()
	return self.name
end






local ItemByName = TMW:NewClass("ItemByName", Item)

function ItemByName:OnNewInstance(itemName)
	TMW:ValidateType("2 (itemName)", "ItemByID:New(itemName)", itemName, "string")

	self.itemID = nil
	self.name = itemName
	self.icon = GetItemIcon(itemName)
end


function ItemByName:GetCooldown()
	local ID = self:GetID()

	if not ID then
		return 0, 0, 0
	end

	return GetItemCooldown(ID)
end
function ItemByName:GetID()
	local _, itemLink = GetItemInfo(self.name)
	if itemLink then
		return tonumber(strmatch(itemLink, ":(%d+)"))
	end
end
function ItemByName:GetName()
	return self.name
end








local ItemBySlot = TMW:NewClass("ItemBySlot", Item)

function ItemBySlot:OnNewInstance(itemSlot)
	TMW:ValidateType("2 (itemSlot)", "ItemByID:New(itemSlot)", itemSlot, "number")

	self.slot = itemSlot
end


function ItemBySlot:IsInRange(unit)
	return IsItemInRange(self:GetLink(), unit)
end
function ItemBySlot:GetIcon()
	return GetInventoryItemTexture("player", self.slot)
end
function ItemBySlot:GetCount()
	return ItemCount[self:GetID()]
end
function ItemBySlot:GetEquipped()
	return IsEquippedItem(self:GetLink())
end
function ItemBySlot:GetCooldown()
	return GetInventoryItemCooldown("player", self.slot)
end
function ItemBySlot:GetID()
	return GetInventoryItemID("player", self.slot)
end
function ItemBySlot:GetName()
	local name = GetItemInfo(self:GetLink())
	return name
end
function ItemBySlot:GetLink()
	return GetInventoryItemLink("player", self.slot)
end








local ItemByLink = TMW:NewClass("ItemByLink", Item)

function ItemByLink:OnNewInstance(itemLink)
	TMW:ValidateType("2 (itemLink)", "ItemByID:New(itemLink)", itemLink, "string")

	self.link = itemLink
	self.itemID = tonumber(strmatch(itemLink, ":(%d+)"))
	self.name = GetItemInfo(itemLink)
	self.icon = GetItemIcon(itemLink)
end


function ItemByLink:GetCooldown()
	return GetItemCooldown(self.itemID)
end
function ItemByLink:GetID()
	return self.itemID
end
function ItemByLink:GetName()
	return self.name
end