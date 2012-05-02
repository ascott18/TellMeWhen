-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local _, pclass = UnitClass("Player")

local strlower =
	  strlower
local GetTotemInfo, GetSpellTexture, GetSpellLink, GetSpellInfo =
	  GetTotemInfo, GetSpellTexture, GetSpellLink, GetSpellInfo
local print = TMW.print
local strlowerCache = TMW.strlowerCache


local Type = TMW.Classes.IconType:New()
Type.type = "totem"
Type.name = pclass == "DRUID" and L["ICONMENU_MUSHROOMS"]		or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL"]		or L["ICONMENU_TOTEM"]
Type.desc = pclass == "DRUID" and L["ICONMENU_MUSHROOMS_DESC"]	or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL_DESC"]	or L["ICONMENU_TOTEM_DESC"]
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"]
Type.AllowNoName = true
Type.usePocketWatch = 1
Type.hidden = pclass == "PRIEST" -- priest totems are lightwells, which is tracked with icon type "lightwell"

if pclass == "SHAMAN" then
	Type.TypeChecks = {
		setting = "TotemSlots",
		text = L["TOTEMS"],
		{ text = L["FIRE"] 	},
		{ text = L["EARTH"] },
		{ text = L["WATER"] },
		{ text = L["AIR"] 	},
	}
elseif pclass == "DRUID" then
	Type.TypeChecks = {
		setting = "TotemSlots",
		text = L["MUSHROOMS"],
		{ text = format(L["MUSHROOM"], 1) },
		{ text = format(L["MUSHROOM"], 2) },
		{ text = format(L["MUSHROOM"], 3) },
	}
end
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	Name = pclass ~= "DRUID" and pclass ~= "DEATHKNIGHT",
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	TotemSlots = true,
}

Type.EventDisabled_OnUnit = true
Type.EventDisabled_OnStack = true


function Type:Update()
end

local function Totem_OnEvent(icon)
	icon.NextUpdateTime = 0
end

local function Totem_OnUpdate(icon, time)

	local Slots, NameNameHash, NameFirst = icon.Slots, icon.NameNameHash, icon.NameFirst
	for iSlot = 1, #Slots do -- be careful here. slots that are explicitly disabled by the user are set false. slots that are disabled internally are set nil.
		if Slots[iSlot] then
			local _, totemName, start, duration, totemIcon = GetTotemInfo(iSlot)
			if start ~= 0 and totemName and ((NameFirst == "") or NameNameHash[strlowerCache[totemName]]) then
				icon:SetInfo("alpha; color; texture; start, duration; spell",
					icon.Alpha,
					icon:CrunchColor(duration),
					totemIcon,
					start, duration,
					totemName
				)
				return
			end
		end
	end
	
	icon:SetInfo("alpha; color; texture; start, duration; spell",
		icon.UnAlpha,
		icon:CrunchColor(),
		icon.FirstTexture,
		0, 0,
		NameFirst
	)
end


function Type:Setup(icon, groupID, iconID)
	if icon.Name then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
		icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
		icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	end
	icon.Slots = wipe(icon.Slots or {})
	for i=1, 4 do
		local settingBit = i > 1 and bit.lshift(1, i - 1) or 1
		icon.Slots[i] = bit.band(icon.TotemSlots, settingBit) == settingBit
	end
	if pclass == "DEATHKNIGHT" then
		icon.NameFirst = ""
		icon.NameName = GetSpellInfo(46584)
		icon.Slots[1] = true -- there is only one slot for DKs, and they dont have options to check certain slots
		icon.Slots[2] = nil
		icon.Slots[3] = nil
		icon.Slots[4] = nil
	elseif pclass == "DRUID" then
		icon.NameFirst = ""
		icon.NameName = GetSpellInfo(88747)
		icon.Slots[4] = nil -- there is no mushroom 4
	elseif pclass ~= "SHAMAN" then --enable all totems for people that dont have totem slot options (future-proof it)
		icon.Slots[1] = true
		icon.Slots[2] = true
		icon.Slots[3] = true
		icon.Slots[4] = true
	end

	icon.FirstTexture = icon.NameName and TMW.SpellTextures[icon.NameName]
	
	icon:SetInfo("reverse", true)

	if pclass == "DRUID" then
		icon:SetInfo("texture", GetSpellTexture(88747))
	elseif pclass == "DEATHKNIGHT" then
		icon:SetInfo("texture", GetSpellTexture(46584))
	else
		icon:SetInfo("texture", TMW:GetConfigIconTexture(icon))
	end

	icon:SetUpdateMethod("manual")
	
	icon:RegisterEvent("PLAYER_TOTEM_UPDATE")
	icon:SetScript("OnEvent", Totem_OnEvent)
	
	icon:SetScript("OnUpdate", Totem_OnUpdate)
	icon:Update()
end

function Type:GetIconMenuText(data)
	local text = data.Name or ""
	if text == "" then
		text = "((" .. Type.name .. "))"
	end

	return text, data.Name and data.Name ~= ""  and data.Name .. "\r\n" or ""
end

function Type:GetNameForDisplay(icon, data, doInsertLink)
	data = data or icon.NameFirst
	
	if data then
		local name
		if doInsertLink then
			name = GetSpellLink(data)
		else
			name = GetSpellInfo(data)
		end
		if name then
			return name
		end
	end
	
	return data, true
end

Type:Register()