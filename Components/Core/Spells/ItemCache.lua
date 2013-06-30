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

local clientVersion = select(4, GetBuildInfo())

local ItemCache = TMW:NewModule("ItemCache", "AceEvent-3.0", "AceTimer-3.0")

local Cache
local CurrentItems = {}

local doUpdateCache = true


TMW.IE:RegisterDatabaseDefaults{
	locale = {
		XPac_ItemCache = 0,
		ItemCache = {

		},
	},
}

TMW.IE:RegisterUpgrade(62217, {
	global = function(self)
		TMW.IE.db.global.ItemCache = nil
		TMW.IE.db.global.XPac_ItemCache = nil
	end,
})

-- PUBLIC:

--[[ Returns the main cache table. Structure:
Cache = {
	[itemID] = 1,
}
]]
function ItemCache:GetCache()
	if not Cache then
		error("ItemCache is not yet initialized", 2)
	end
	
	self:CacheItems()
	
	return Cache
end

--[[ Returns a list of items that the player currently has. Structure:
Cache = {
	[itemID] = name,
	[name] = itemID,
}
]]
function ItemCache:GetCurrentItems()
	self:CacheItems()
	
	return CurrentItems
end

-- END PUBLIC




-- PRIVATE:

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()

	Cache = TMW.IE.db.locale.ItemCache

	-- Wipe the item cache if user is running a new expansion
	-- (User probably doesn't have most item in the cache anymore,
	-- and probably doesn't care about the rest)
	local XPac = tonumber(strsub(clientVersion, 1, 1))
	if TMW.IE.db.locale.XPac_ItemCache < XPac then
		wipe(Cache)
		TMW.IE.db.locale.XPac_ItemCache = XPac
	end
	
	--Start requests so that we can validate itemIDs.
	for id in pairs(Cache) do
		GetItemInfo(id)
	end

	-- Queue the validation for 1 minute
	ItemCache:ScheduleTimer("ValidateItemIDs", 60)

	ItemCache:RegisterEvent("BAG_UPDATE")
	ItemCache:RegisterEvent("BANKFRAME_OPENED", "BAG_UPDATE")
	
	ItemCache:CacheItems()
end)

function ItemCache:BAG_UPDATE()
	doUpdateCache = true
end

function ItemCache:ValidateItemIDs()
	-- Function to call once data about items has been collected from the server.
	-- All data should be in by now, see what actually exists.
	for id in pairs(Cache) do
		if not GetItemInfo(id) then
			Cache[id] = nil
		end
	end
	
	-- Don't need this function anymore, so get rid of it.
	self.ValidateItemIDs = nil
end

function ItemCache:CacheItems(force)
	if not force and not doUpdateCache then
		return
	end

	wipe(CurrentItems)

	for container = -2, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(container) do
			local id = GetContainerItemID(container, slot)
			if id then
				local name = GetItemInfo(id)
				name = name and strlower(name)

				CurrentItems[id] = name
				Cache[id] = name
			end
		end
	end

	for slot = 1, 19 do
		local id = GetInventoryItemID("player", slot)
		if id then
			local name = GetItemInfo(id)
			name = name and strlower(name)

			CurrentItems[id] = name
			Cache[id] = name
		end
	end

	for id, name in pairs(CurrentItems) do
		CurrentItems[name] = id
	end

	doUpdateCache = nil
end

-- END PRIVATE

