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

local GetRuneType, GetRuneCooldown
	= GetRuneType, GetRuneCooldown
local bit, wipe, ipairs, ceil
	= bit, wipe, ipairs, ceil
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

if not GetRuneType then return end

local Type = TMW.Classes.IconType:New("runes")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_RUNES"]
Type.desc = L["ICONMENU_RUNES_DESC"]
Type.menuIcon = "Interface\\Addons\\TellMeWhen\\Textures\\DeathPresence"
Type.hidden = pclass ~= "DEATHKNIGHT"
Type.AllowNoName = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("charges, maxCharges")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:RegisterIconDefaults{
	Sort					= false,
	RuneSlots				= 0xFFF, --(111111 111111)
	RunesAsCharges			= false,
	
	--[[ From the LSB, RuneSlots corresponds to:
		[0x3]   blood runes 1&2
		[0xC]   unholy runes 1&2
		[0x30]  frost runes 1&2
		[0xC0]  blood death runes 1&2
		[0x300] unholy death runes 1&2
		[0xC00] frost death runes 1&2
	]]
}

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_RuneSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "RunesAsCharges",
			title = L["ICONMENU_RUNES_CHARGES"],
			tooltip = L["ICONMENU_RUNES_CHARGES_DESC"],
		}
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"],		},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"],	},
})

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_Runes")

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_SortSettings")

TMW:RegisterUpgrade(62033, {
	icon = function(self, ics)
		-- Import the setting from TotemSlots, which was what this setting used to be
		if ics.Type == "runes" then
			local firstSix = bit.band(0x3F, ics.RuneSlots)
			local secondSix = bit.lshift(firstSix, 6)
			ics.RuneSlots = bit.bor(secondSix, firstSix)
		end
	end,
})
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
	local readyslot, readyslotType
	local unstart, unduration, unslot, unslotType
	local d = Sort == -1 and huge or 0

	local usableCount = 0

	for iSlot = 1, #Slots do
		if Slots[iSlot] then
			local isDeath = false
			if iSlot > 6 then
				iSlot = iSlot - 6
				isDeath = true
			end
			local runeType = GetRuneType(iSlot)
			
			if isDeath == (runeType == 4) then
				local start, duration, runeReady = GetRuneCooldown(iSlot)
				
				if start == 0 then duration = 0 end
				if start > time then runeReady = false end

				if runeReady then
					usableCount = usableCount + 1
					if not readyslot then
						readyslot = iSlot
						readyslotType = runeType
					end
					--[[if icon.Alpha > 0 then
						break
					end]]
				else
					if Sort then
						local _d = duration - (time - start)
						if d*Sort < _d*Sort then
							unstart, unduration, unslot, d = start, duration, iSlot, _d
							unslotType = runeType
						end
					else
						if not unstart or (unstart > time and start < time) then
							unstart, unduration, unslot = start, duration, iSlot
							unslotType = runeType
						end
						--[[if start < time and icon.Alpha == 0 then
							break
						end]]
					end
				end
			end
		end
	end


	if readyslot then
		if icon.RunesAsCharges and unslot then
			icon:SetInfo("alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell",
				icon.Alpha,
				textures[readyslotType],
				unstart, unduration,
				usableCount, icon.RuneSlotsUsed,
				usableCount, usableCount,
				runeNames[readyslotType] -- MAYBE: change this arg? (to a special arg instead of spell)
			)
		else
			icon:SetInfo("alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell",
				icon.Alpha,
				textures[readyslotType],
				0, 0,
				nil, nil,
				usableCount, usableCount,
				runeNames[readyslotType] -- MAYBE: change this arg? (to a special arg instead of spell)
			)
		end
	elseif unslot then
		icon:SetInfo("alpha; texture; start, duration; charges, maxCharges; stack, stackText; spell",
			icon.UnAlpha,
			textures[unslotType],
			unstart, unduration,
			0, 0,
			nil, nil,
			runeNames[unslotType] -- MAYBE: change this arg? (to a special arg instead of spell)
		)
	else
		icon:SetInfo("alpha; texture; start, duration; charges, maxCharges; stack, stackText",
			icon.UnAlpha,
			icon.FirstTexture,
			0, 0,
			0, 0,
			nil, nil
		)
	end
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
	return runeNames[data]
end


function Type:Setup(icon)
	icon.Slots = wipe(icon.Slots or {})
	for i=1, 12 do
		local settingBit = bit.lshift(1, i - 1)
		icon.Slots[i] = bit.band(icon.RuneSlots, settingBit) == settingBit
	end
	
	icon.RuneSlotsUsed = 0
	for i = 1, 6 do
		if icon.Slots[i] or icon.Slots[i+6] then
			icon.RuneSlotsUsed = icon.RuneSlotsUsed + 1
		end
	end

	for k, v in ipairs(icon.Slots) do
		if v then
			if k > 6 then
				icon.FirstTexture = textures[4]
			else
				icon.FirstTexture = textures[ceil(k/2)]
			end
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

function Type:GetIconMenuText(ics)
	local RuneSlots = ics.RuneSlots or 0xFFF

	local Slots = {}

	local str = ""

	for slot = 1, 12, 2 do
		local settingBit = bit.lshift(1, slot - 1)
		local slotEnabled = bit.band(RuneSlots, settingBit) == settingBit

		local settingBit2 = bit.lshift(1, slot)
		local slot2Enabled = bit.band(RuneSlots, settingBit) == settingBit

		local n = (slotEnabled and 1 or 0) + (slot2Enabled and 1 or 0)

		if n > 0 then
			local runeName = runeNames[(ceil(slot/2) - 1) % 3 + 1]
			if slot > 6 then
				runeName = runeNames[4] .. " (" .. runeName .. ")"
			end

			str = str .. n .. "x " .. runeName .. ", "

		end
	end

	if str ~= "" then
		return str:sub(1, -3), ""
	else
		return "", ""
	end
end

function Type:GuessIconTexture(ics)
	return "Interface\\Icons\\Spell_Deathknight_BloodPresence"
end

Type:Register(30)