-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print

local format, type, tonumber, wipe, bit =
	  format, type, tonumber, wipe, bit
local GetTotemInfo, GetSpellLink, GetSpellInfo =
	  GetTotemInfo, GetSpellLink, GetSpellInfo

local GetSpellTexture = TMW.GetSpellTexture
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")


local Type = TMW.Classes.IconType:New("totem")
if pclass == "DRUID" then
	-- Druid totems are wild mushrooms
	Type.name = GetSpellInfo(88747)
	Type.desc = L["ICONMENU_MUSHROOMS_DESC"]
	Type.menuIcon = "Interface\\ICONS\\druid_ability_wildmushroom_b"
elseif pclass == "MAGE" then
	-- Mage totems are runes of power
	Type.name = GetSpellInfo(116011)
	Type.desc = L["ICONMENU_RUNEOFPOWER_DESC"]
	Type.menuIcon = GetSpellTexture(116011)
else
	-- Name it "Totem" for everyone else.
	Type.name = L["ICONMENU_TOTEM"]
	Type.desc = L["ICONMENU_TOTEM_DESC"]
	Type.menuIcon = "Interface\\ICONS\\ability_shaman_tranquilmindtotem"
end

Type.AllowNoName = true
Type.usePocketWatch = 1
Type.hidden = pclass == "PRIEST" -- priest totems are lightwells, which is tracked with the "lightwell" icon type
Type.hasNoGCD = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)




Type:RegisterIconDefaults{
	-- Bitfield for the totem slots being tracked by the icon.
	TotemSlots				= 0xF, --(1111)
}

if pclass ~= "DRUID" and pclass ~= "MAGE" then
	-- Druids and mages shouldn't be able to filter by name,
	-- since their totems only have one possible name.

	Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
		title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	})
end


local totemNames = {
	SHAMAN = {
		L["FIRE"],
		L["EARTH"],
		L["WATER"],
		L["AIR"],
	},
	DRUID = {
		L["MUSHROOM"]:format(1),
		L["MUSHROOM"]:format(2),
		L["MUSHROOM"]:format(3),
	},
	MAGE = {
		L["RUNEOFPOWER"]:format(1),
		L["RUNEOFPOWER"]:format(2),
	},
	OTHER = {
		L["GENERICTOTEM"]:format(1),
		L["GENERICTOTEM"]:format(2),
		L["GENERICTOTEM"]:format(3),
		L["GENERICTOTEM"]:format(4),
	}
}
totemNames = totemNames[pclass] or totemNames.OTHER

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_TotemSlots", function(self)
	self:SetTitle(L["ICONMENU_CHOOSENAME3"])

	local data = { numPerRow = #totemNames >= 4 and #totemNames/2 or #totemNames}
	for i, name in ipairs(totemNames) do
		tinsert(data, function(check)
			check:SetTexts(name, nil)
			check:SetSetting("TotemSlots")
			check:SetSettingBitID(check:GetID())
		end)
	end

	self:BuildSimpleCheckSettingFrame("Config_CheckButton_BitToggle", data)
end)



Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[1] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"],		},
	[2] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],		},
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

	-- Upvalue things that will be referenced in our loops.
	local Slots, NameStringHash, NameFirst = icon.Slots, icon.Spells.StringHash, icon.Spells.First
	
	-- Be careful here. Slots that are explicitly disabled by the user are set false.
	-- Slots that are disabled internally are set nil (which could change table length).
	for iSlot = 1, #Slots do
		if Slots[iSlot] then
			local _, totemName, start, duration, totemIcon = GetTotemInfo(iSlot)

			if start ~= 0 and totemName and (NameFirst == "" or NameStringHash[strlowerCache[totemName]]) then
				-- The totem is present. Display it and stop.
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
	
	-- No totems were found. Display a blank state.
	icon:SetInfo("alpha; texture; start, duration; spell",
		icon.UnAlpha,
		icon.FirstTexture,
		0, 0,
		NameFirst
	)
end


function Type:Setup(icon)

	-- Put the enabled slots into a table so we don't have to do bitmagic in the OnUpdate function.
	icon.Slots = wipe(icon.Slots or {})
	for i=1, 4 do
		local settingBit = bit.lshift(1, i - 1)
		icon.Slots[i] = bit.band(icon.TotemSlots, settingBit) == settingBit
	end

	icon.FirstTexture = nil
	local name = icon.Name

	-- Force the name for classes that can't configure a name.
	if pclass == "MAGE" then
		name = 116011
		icon.Slots[3] = nil -- there is no rune 3
		icon.Slots[4] = nil -- there is no rune 4
	elseif pclass == "DRUID" then
		name = 88747
		icon.Slots[4] = nil -- there is no mushroom 4
	end

	icon.Spells = TMW:GetSpells(name, true)

	icon.FirstTexture = icon.Spells.FirstString and GetSpellTexture(icon.Spells.FirstString)
	icon:SetInfo("reverse; texture; spell",
		true,
		Type:GetConfigIconTexture(icon),
		icon.Spells.FirstString
	)

	icon:SetUpdateMethod("manual")
	
	icon:RegisterSimpleUpdateEvent("PLAYER_TOTEM_UPDATE")
	
	icon:SetUpdateFunction(Totem_OnUpdate)
	icon:Update()
end

Type:Register(120)