-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, rc, mc, pr, ab
local GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon, GetItemCount =
	  GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon, GetItemCount
local pairs =
	  pairs
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

local Type = {}
LibStub("AceEvent-3.0"):Embed(Type)
Type.type = "item"
Type.name = L["ICONMENU_ITEMCOOLDOWN"]
Type.appendNameLabel = L["ICONMENU_CHOOSENAME_ORITEMSLOT"]
Type.SUGType = "itemwithslots"
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",  		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	RangeCheck = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	OnlyEquipped = true,
	OnlyInBags = true,
	EnableStacks = true,
	
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
}
Type.DisabledEvents = {
	OnUnit = true,
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end


-- yay for caching!
local ItemCount = setmetatable({}, {__index = function(tbl, k)
	if not k then return end
	local count = GetItemCount(k, nil, 1)
	tbl[k] = count
	return count
end}) Type.ItemCount = ItemCount
function Type:BAG_UPDATE()
	for k in pairs(ItemCount) do
		ItemCount[k] = GetItemCount(k, nil, 1)
	end
end

local function ItemCooldown_OnEvent(icon)
	-- the reason for doing it like this is because this event will fire several times at once sometimes,
	-- but there is no reason to recheck things until they are needed next.
	icon.DoUpdateIDs = true
end

local function ItemCooldown_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		if icon.DoUpdateIDs then
			local Name = icon.Name
			icon.NameFirst = TMW:GetItemIDs(icon, Name, 1)
			icon.NameArray = TMW:GetItemIDs(icon, Name)
			icon.NameNameArray = TMW:GetItemIDs(icon, icon.Name, nil, 1)
			icon.DoUpdateIDs = nil
		end

		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local n, inrange, equipped, start, duration, isGCD, count = 1
		local RangeCheck, OnlyEquipped, OnlyInBags, NameArray, EnableStacks = icon.RangeCheck, icon.OnlyEquipped, icon.OnlyInBags, icon.NameArray, icon.EnableStacks
		for i = 1, #NameArray do
			local iName = NameArray[i]
			n = i
			start, duration = GetItemCooldown(iName)
			if duration then
				inrange, equipped, count = 1, true, ItemCount[iName]
				if RangeCheck then
					inrange = IsItemInRange(iName, "target") or 1
				end

				if (OnlyEquipped and not IsEquippedItem(iName)) or (OnlyInBags and (count == 0)) then
					equipped = false
				end
				isGCD = OnGCD(duration)
				if equipped and inrange == 1 and (duration == 0 or isGCD) then --usable

					--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
					icon:SetInfo(icon.Alpha, 1, GetItemIcon(iName) or "Interface\\Icons\\INV_Misc_QuestionMark", start, duration, iName, nil, count, EnableStacks and count > 1 and count or "", nil, nil)

					return
				end
			end
		end

		local NameFirst2
		if OnlyInBags then
			for i = 1, #NameArray do
				local iName = NameArray[i]
				if (OnlyEquipped and IsEquippedItem(iName)) or (not OnlyEquipped and ItemCount[iName] > 0) then
					NameFirst2 = iName
					break
				end
			end
			if not NameFirst2 then
				icon:SetInfo(0)
				return
			end
		else
			NameFirst2 = icon.NameFirst
		end
		if n > 1 then -- if there is more than 1 spell that was checked then we need to get these again for the first spell, otherwise reuse the values obtained above since they are just for the first one
			start, duration = GetItemCooldown(NameFirst2)
			inrange, count = 1, ItemCount[NameFirst2]
			if RangeCheck then
				inrange = IsItemInRange(NameFirst2, "target") or 1
			end
			isGCD = OnGCD(duration)
		end
		if duration then

			local alpha, color
			if icon.Alpha ~= 0 then
				if inrange ~= 1 then
					alpha, color = icon.UnAlpha*rc.a, rc
				elseif not icon.ShowTimer then
					alpha, color = icon.UnAlpha, 0.5
				else
					alpha, color = icon.UnAlpha, 1
				end
			else
				alpha, color = icon.UnAlpha, 1
			end
			
			--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
			icon:SetInfo(alpha, color, GetItemIcon(NameFirst2), start, duration, NameFirst2, nil, count, EnableStacks and count > 1 and count or "", nil, nil)
		else
			icon:SetInfo(0)
		end
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetItemIDs(icon, icon.Name, 1)
	icon.NameArray = TMW:GetItemIDs(icon, icon.Name)
	icon.NameNameArray = TMW:GetItemIDs(icon, icon.Name, nil, 1)
	icon.NameNameArray = TMW:GetItemIDs(icon, icon.Name, nil, 1)

	if not icon.NameFirst or icon.NameFirst == 0 then
		icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
		icon:SetScript("OnEvent", ItemCooldown_OnEvent)
	else
		for _, n in ipairs(TMW:SplitNames(icon.Name)) do
			n = tonumber(strtrim(n))
			if n and n <= INVSLOT_LAST_EQUIPPED then
				icon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
				icon:SetScript("OnEvent", ItemCooldown_OnEvent)
				break
			end
		end
	end

	icon.ShowPBar = nil
	if icon.OnlyEquipped then
		icon.OnlyInBags = true
	end

	icon:SetTexture(TMW:GetConfigIconTexture(icon, 1))
	
	Type:RegisterEvent("BAG_UPDATE")
	
	icon:SetScript("OnUpdate", ItemCooldown_OnUpdate)
	icon:OnUpdate(TMW.time)
end

function Type:GetNameForDisplay(icon, data)
	return data and GetItemInfo(data)
end

function Type:DragReceived(icon, t, data, subType)
	local ics = icon:GetSettings()
	
	if t ~= "item" or not data then
		return
	end
	
	ics.Name = TMW:CleanString(ics.Name .. ";" .. data)
	return true -- signal success
end


TMW:RegisterIconType(Type)