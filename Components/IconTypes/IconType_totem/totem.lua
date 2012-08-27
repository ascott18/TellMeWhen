-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
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


local Type = TMW.Classes.IconType:New("totem")
Type.name = pclass == "DRUID" and L["ICONMENU_MUSHROOMS"]		or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL"]		or L["ICONMENU_TOTEM"]
Type.desc = pclass == "DRUID" and L["ICONMENU_MUSHROOMS_DESC"]	or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL_DESC"]	or L["ICONMENU_TOTEM_DESC"]
Type.AllowNoName = true
Type.usePocketWatch = 1
Type.hidden = pclass == "PRIEST" -- priest totems are lightwells, which is tracked with icon type "lightwell"


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	TotemSlots				= 0xF, --(1111)
}

if pclass ~= "DRUID" and pclass ~= "DEATHKNIGHT" then
	Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
		title = L["ICONMENU_CHOOSENAME2"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	})
end

if pclass == "SHAMAN" then
	Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_TotemSlots_Shaman", function(self)
		self.Header:SetText(L["TOTEMS"])
		TMW.IE:BuildSimpleCheckSettingFrame(self, "SettingTotemButton", {
			numPerRow = 4,
			{
				setting = "TotemSlots",
				value = 1,
				title = L["FIRE"],
			},
			{
				setting = "TotemSlots",
				value = 2,
				title = L["EARTH"],
			},
			{
				setting = "TotemSlots",
				value = 3,
				title = L["WATER"],
			},
			{
				setting = "TotemSlots",
				value = 4,
				title = L["AIR"],
			},
		})
	end)
elseif pclass == "DRUID" then
	Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_TotemSlots_Druid", function(self)
		self.Header:SetText(L["MUSHROOMS"])
		TMW.IE:BuildSimpleCheckSettingFrame(self, "SettingTotemButton", {				
			{
				setting = "TotemSlots",
				value = 1,
				title = format(L["MUSHROOM"], 1),
			},
			{
				setting = "TotemSlots",
				value = 2,
				title = format(L["MUSHROOM"], 2),
			},
			{
				setting = "TotemSlots",
				value = 3,
				title = format(L["MUSHROOM"], 3),
			},
		})
	end)
elseif pclass ~= "DEATHKNIGHT" then
	Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_TotemSlots_Generic", function(self)
		self.Header:SetText(L["TOTEMS"])
		TMW.IE:BuildSimpleCheckSettingFrame(self, "SettingTotemButton", {				
			{
				setting = "TotemSlots",
				value = 1,
				title = format(L["GENERICTOTEM"], 1),
			},
			{
				setting = "TotemSlots",
				value = 2,
				title = format(L["GENERICTOTEM"], 2),
			},
			{
				setting = "TotemSlots",
				value = 3,
				title = format(L["GENERICTOTEM"], 3),
			},
			{
				setting = "TotemSlots",
				value = 4,
				title = format(L["GENERICTOTEM"], 3),
			},
		})
	end)
end

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"],		},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],		},
})

TMW:RegisterUpgrade(48017, {
	icon = function(self, ics)
		-- convert from some stupid string thing i made up to a bitfield
		if type(ics.TotemSlots) == "string" then
			ics.TotemSlots = tonumber(ics.TotemSlots:reverse(), 2)
		end
	end,
})


local function Totem_OnUpdate(icon, time)

	local Slots, NameNameHash, NameFirst = icon.Slots, icon.NameNameHash, icon.NameFirst
	for iSlot = 1, #Slots do -- be careful here. slots that are explicitly disabled by the user are set false. slots that are disabled internally are set nil.
		if Slots[iSlot] then
			local _, totemName, start, duration, totemIcon = GetTotemInfo(iSlot)
			if start ~= 0 and totemName and ((NameFirst == "") or NameNameHash[strlowerCache[totemName]]) then
				icon:SetInfo("alpha; texture; start, duration; spell",
					icon.Alpha,
					totemIcon,
					start, duration,
					totemName
				)
				return
			end
		end
	end
	
	icon:SetInfo("alpha; texture; start, duration; spell",
		icon.UnAlpha,
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
		local settingBit = bit.lshift(1, i - 1)
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
	
	icon:RegisterSimpleUpdateEvent("PLAYER_TOTEM_UPDATE")
	
	icon:SetUpdateFunction(Totem_OnUpdate)
	icon:Update()
end

function Type:GetIconMenuText(data)
	local text = data.Name or ""
	if text == "" then
		text = "((" .. Type.name .. "))"
	end

	return text, data.Name and data.Name ~= ""  and data.Name .. "\r\n" or ""
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
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

Type:Register(120)