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

local _, pclass = UnitClass("Player")

local db, UPD_INTV, ClockGCD, pr, ab, rc, mc
local strlower =
	  strlower
local GetTotemInfo, GetSpellTexture =
	  GetTotemInfo, GetSpellTexture
local print = TMW.print
local strlowerCache = TMW.strlowerCache


local Type = {}
Type.type = "totem"
Type.name = pclass == "DRUID" and L["ICONMENU_MUSHROOMS"]		or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL"]		or L["ICONMENU_TOTEM"]
Type.desc = pclass == "DRUID" and L["ICONMENU_MUSHROOMS_DESC"]	or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL_DESC"]	or L["ICONMENU_TOTEM_DESC"]
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"]
Type.AllowNoName = true
Type.usePocketWatch = 1

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
Type.DisabledEvents = {
	OnUnit = true,
}


function Type:Update(upd_intv)
	db = TMW.db
	UPD_INTV = upd_intv
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end

local function Totem_OnUpdate(icon, time)
	if icon.LastUpdate <= time - UPD_INTV then
		icon.LastUpdate = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local Slots, NameNameHash, NameFirst = icon.Slots, icon.NameNameHash, icon.NameFirst
		for iSlot = 1, #Slots do -- be careful here. slots that are explicitly disabled by the user are set false. slots that are disabled internally are set nil.
			if Slots[iSlot] then
				local _, totemName, start, duration, totemIcon = GetTotemInfo(iSlot)
				if start ~= 0 and totemName and ((NameFirst == "") or NameNameHash[strlowerCache[totemName]]) then
				
					local color = icon:CrunchColor(duration)
					
					--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
					icon:SetInfo(icon.Alpha, color, totemIcon, start, duration, totemName, nil, nil, nil, nil, nil)
					return
				end
			end
		end
		
		local color = icon:CrunchColor()
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(icon.UnAlpha, color, icon.FirstTexture, 0, 0, nil, nil, nil, nil, nil, nil)
	end
end


function Type:Setup(icon, groupID, iconID)
	if icon.Name then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
		icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
		icon.NameNameHash = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	end
	icon.Slots = wipe(icon.Slots or {})
	for i=1, 4 do
		icon.Slots[i] = tonumber(strsub(icon.TotemSlots.."0000", i, i)) == 1
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
	icon:SetReverse(true)

	icon.FirstTexture = icon.NameName and TMW.SpellTextures[icon.NameName]

	if pclass == "DRUID" then
		icon:SetTexture(GetSpellTexture(88747))
	elseif pclass == "DEATHKNIGHT" then
		icon:SetTexture(GetSpellTexture(46584))
	else
		icon:SetTexture(TMW:GetConfigIconTexture(icon))
	end

	icon:SetScript("OnUpdate", Totem_OnUpdate)
	icon:OnUpdate(TMW.time)
end

function TypeIconMenuText(data)
	local text = data.Name or ""
	if text == "" then
		text = "((" .. Type.name .. "))"
	end
	
	return text, data.Name and data.Name ~= ""  and data.Name .. "\r\n" or ""
end

function Type:GetNameForDisplay(icon, data)
	if data then
		return data
	else
		return icon.NameFirst, 1
	end
end

TMW:RegisterIconType(Type)