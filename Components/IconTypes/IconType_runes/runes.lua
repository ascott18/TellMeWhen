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

local GetRuneType, GetRuneCooldown =
	  GetRuneType, GetRuneCooldown
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

if not GetRuneType then return end

local Type = TMW.Classes.IconType:New("runes")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_RUNES"]
Type.desc = L["ICONMENU_RUNES_DESC"]
Type.hidden = pclass ~= "DEATHKNIGHT"
Type.AllowNoName = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	Sort					= false,
	RuneSlots				= 0x3F, --(111111)
}

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"],		},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"],	},
})

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_Runes")

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettings")

TMW:RegisterUpgrade(51024, {
	icon = function(self, ics)
		-- Import the setting from TotemSlots, which was what this setting used to be
		if ics.Type == "runes" and ics.TotemSlots and ics.TotemSlots ~= 0xF then
			ics.RuneSlots = ics.TotemSlots
		end
	end,
})

local textures = {
	"Interface\\Icons\\Spell_Deathknight_BloodPresence",
	"Interface\\Icons\\Spell_Deathknight_UnholyPresence",
	"Interface\\Icons\\Spell_Deathknight_FrostPresence",
	"Interface\\Addons\\TellMeWhen\\Textures\\DeathPresence",
}
local runeNames = {
	COMBAT_TEXT_RUNE_BLOOD,
	COMBAT_TEXT_RUNE_UNHOLY,
	COMBAT_TEXT_RUNE_FROST,
	COMBAT_TEXT_RUNE_DEATH,
}

	
	
local huge = math.huge
local function Runes_OnUpdate(icon, time)

	local Slots, Sort = icon.Slots, icon.Sort
	local readyslot
	local unstart, unduration, unslot
	local d = Sort == -1 and huge or 0

	for iSlot = 1, #Slots do -- be careful here. slots that are explicitly disabled by the user are set false. slots that are disabled internally are set nil.
		if Slots[iSlot] then
			local start, duration, runeReady = GetRuneCooldown(iSlot)

			if start == 0 then duration = 0 end
			if start > time then runeReady = false end

			if runeReady then
				if not readyslot then
					readyslot = iSlot
				end
				if icon.Alpha > 0 then
					break
				end
			else
				if Sort then
					local _d = duration - (time - start)
					if d*Sort < _d*Sort then
						unstart, unduration, unslot, d = start, duration, iSlot, _d
					end
				else
					if not unstart or (unstart > time and start < time) then
						unstart, unduration, unslot = start, duration, iSlot
					end
					if start < time and icon.Alpha == 0 then
						break
					end
				end
			end
		end
	end

	if readyslot then
		local type = GetRuneType(readyslot)

		icon:SetInfo("alpha; texture; start, duration; spell",
			icon.Alpha,
			textures[type],
			0, 0,
			type -- MAYBE: change this arg? (to a special arg instead of spell)
		)
	elseif unslot then
		local type = GetRuneType(unslot)
		
		icon:SetInfo("alpha; texture; start, duration; spell",
			icon.UnAlpha,
			textures[type],
			unstart, unduration,
			type -- MAYBE: change this arg? (to a special arg instead of spell)
		)
	end
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
	return runeNames[data]
end


function Type:Setup(icon, groupID, iconID)
	icon.Slots = wipe(icon.Slots or {})
	for i=1, 6 do
		local settingBit = bit.lshift(1, i - 1)
		icon.Slots[i] = bit.band(icon.RuneSlots, settingBit) == settingBit
	end

	for k, v in ipairs(icon.Slots) do
		if v then
			icon.FirstTexture = textures[ceil(k/2)]
			break
		end
	end

	icon:SetInfo("texture", icon.FirstTexture or "Interface\\Icons\\INV_Misc_QuestionMark")

	icon:RegisterSimpleUpdateEvent("RUNE_TYPE_UPDATE")
	icon:RegisterSimpleUpdateEvent("RUNE_POWER_UPDATE")
	
	icon:SetUpdateMethod("manual")

	icon:SetUpdateFunction(Runes_OnUpdate)
	--icon:Update()
end

function Type:GetIconMenuText(data, groupID, iconID)
	if iconID then
		return L["fICON"]:format(iconID) .. " - " .. Type.name, ""
	else
		return "((" .. Type.name .. "))", ""
	end
end

Type:Register(30)