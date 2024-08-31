-- --------------------
-- TellMeWhen
-- Originally by NephMakes

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
local GetRuneType, GetRuneCooldown
	= GetRuneType, GetRuneCooldown
local bit, wipe, ipairs, ceil
	= bit, wipe, ipairs, ceil
	
local _, pclass = UnitClass("player")

if not GetRuneType then return end

local Type = TMW.Classes.IconType:New("runes")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_RUNES"]
Type.desc = L["ICONMENU_RUNES_DESC"]
Type.menuIcon = "Interface\\Addons\\TellMeWhen\\Textures\\DeathPresence"
Type.hidden = pclass ~= "DEATHKNIGHT"
Type.AllowNoName = true
Type.hasNoGCD = true

local STATE_USABLE = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_UNUSABLE = TMW.CONST.STATE.DEFAULT_HIDE

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("charges, maxCharges, chargeStart, chargeDur")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes



Type:RegisterIconDefaults{
	-- Sort the runes found by duration
	Sort					= false,

	-- Bitfield of the runes that will be checked.
	--[[ From the LSB, RuneSlots corresponds to:
		[0x003]   blood runes 1&2
		[0x00C]   unholy runes 1&2
		[0x030]  frost runes 1&2
		[0x0C0]  blood death runes 1&2
		[0x300] unholy death runes 1&2
		[0xC00] frost death runes 1&2
	]]
	RuneSlots				= 0xFFF, --(111111 111111)

	-- Treat any runes that are cooling down as an extra charge
	RunesAsCharges			= false,
}

Type:RegisterConfigPanel_XMLTemplate(110, "TellMeWhen_Runes")

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_RuneSettings", function(self)
	self.Header:SetText(Type.name)
	self:BuildSimpleCheckSettingFrame({
		numPerRow = 1,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_RUNES_CHARGES"], TMW.L["ICONMENU_RUNES_CHARGES_DESC"])
			check:SetSetting("RunesAsCharges")
		end,
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_USABLE]           = { text = "|cFF00FF00" .. L["ICONMENU_USABLE"],   },
	[STATE_UNUSABLE]         = { text = "|cFFFF0000" .. L["ICONMENU_UNUSABLE"], },
})

Type:RegisterConfigPanel_ConstructorFunc(170, "TellMeWhen_RuneSortSettings", function(self)
	self:SetTitle(TMW.L["SORTBY"])

	self:BuildSimpleCheckSettingFrame({
		numPerRow = 3,
		function(check)
			check:SetTexts(TMW.L["SORTBYNONE"], TMW.L["SORTBYNONE_DESC"])
			check:SetSetting("Sort", false)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTASC"], TMW.L["ICONMENU_SORTASC_DESC"])
			check:SetSetting("Sort", -1)
		end,
		function(check)
			check:SetTexts(TMW.L["ICONMENU_SORTDESC"], TMW.L["ICONMENU_SORTDESC_DESC"])
			check:SetSetting("Sort", 1)
		end,
	})
end)


local textures = {
	"Interface\\Icons\\Spell_Deathknight_BloodPresence",
	"Interface\\Icons\\Spell_Deathknight_FrostPresence",
	"Interface\\Icons\\Spell_Deathknight_UnholyPresence",
	"Interface\\Addons\\TellMeWhen\\Textures\\DeathPresence",
}
local runeNames = {
	COMBAT_TEXT_RUNE_BLOOD,
	COMBAT_TEXT_RUNE_FROST,
	COMBAT_TEXT_RUNE_UNHOLY,
	COMBAT_TEXT_RUNE_DEATH,
}

	
	
local huge = math.huge
local function Runes_OnUpdate(icon, time)

	-- Upvalue things that will be referenced a lot in our loops.
	local Slots, Sort = icon.Slots, icon.Sort

	-- These variables will hold the attributes that we pass to YieldInfo().
	local readyslot, readyslotType
	local unstart, unduration, unslot, unslotType
	local usableCount = 0


	local curSortDur = Sort == -1 and huge or 0


	for slot = 1, #Slots do
		if Slots[slot] then
			-- The user is interested in the slot.

			local isDeath = false
			if slot > 6 then
				-- Slots above 6 correspond to the death rune version of that slot.
				slot = slot - 6
				isDeath = true
			end

			local runeType = GetRuneType(slot)
			
			-- Check if the rune is a death rune if it should be,
			-- or if it isn't a death rune if it shouldn't be.
			if isDeath == (runeType == 4) then
				local start, duration, runeReady = GetRuneCooldown(slot)
				
				-- Stupid API.
				if start == 0 then duration = 0 end

				-- Start times in the future indicate a rune that hasn't started its cooldown.
				if start > time then runeReady = false end

				if runeReady then
					usableCount = usableCount + 1
					if not readyslot then
						-- Record this rune as the first one we found that's ready,
						-- so that we can use it if we need to.
						readyslot = slot
						readyslotType = runeType
					end
				else
					if Sort then
						local remaining = duration - (time - start)
						if curSortDur*Sort < remaining*Sort then
							-- Sort is either 1 or -1, so multiply by it to get the correct ordering. (multiplying by a negative flips inequalities)
							-- If this rune beats the previous by sort order, then use it.
								
							unstart, unduration, unslot, curSortDur = start, duration, slot, remaining
							unslotType = runeType
						end
					else
						if not unstart or (unstart > time and start < time) then
							-- If we haven't found an unusable rune yet, or if the one that we found 
							-- hasn't started its cooldown yet and this rune has started its cooldown,
							-- record this rune as the unusable rune that we will show data for.
							unstart, unduration, unslot = start, duration, slot
							unslotType = runeType
						end
					end
				end
			end
		end
	end


	if readyslot then
		-- We found a rune that is ready. Show it.

		if icon.RunesAsCharges and unslot then
			icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
				STATE_USABLE,
				textures[readyslotType],
				unstart, unduration, unstart, unduration,
				usableCount, icon.RuneSlotsUsed,
				usableCount, usableCount,
				runeNames[readyslotType] 
			)
		else
			icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
			STATE_USABLE,
				textures[readyslotType],
				0, 0, nil, nil,
				nil, nil,
				usableCount, usableCount,
				runeNames[readyslotType] 
			)
		end
	elseif unslot then
		-- We didn't find any ready runes. Show a cooling down rune.
		icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
			STATE_UNUSABLE,
			textures[unslotType],
			unstart, unduration, nil, nil,
			0, 0,
			nil, nil,
			runeNames[unslotType]
		)
	else
		-- We didn't find any runes. This might mean that the types of runes being tracked are death runes,
		-- or if tracking death runes, those death runes aren't death runes.
		icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
		STATE_UNUSABLE,
			textures[icon.FirstType],
			0, 0, nil, nil,
			0, 0,
			nil, nil,
			runeNames[icon.FirstType]
		)
	end
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
	return data
end


function Type:Setup(icon)
	icon.Slots = wipe(icon.Slots or {})
	-- Stick the enabled state of every rune slot into a table
	-- so we don't have to do bit magic in every OnUpdate.
	for i=1, 12 do
		local settingBit = bit.lshift(1, i - 1)
		icon.Slots[i] = bit.band(icon.RuneSlots, settingBit) == settingBit
	end
	
	-- This is used as maxCharges if icon.RunesAsCharges == true.
	icon.RuneSlotsUsed = 0
	for i = 1, 6 do
		if icon.Slots[i] or icon.Slots[i+6] then
			icon.RuneSlotsUsed = icon.RuneSlotsUsed + 1
		end
	end

	icon.FirstType = nil
	for k, v in ipairs(icon.Slots) do
		if v then
			if k > 6 then
				icon.FirstType = 4
			elseif k > 4 then
				-- Slots 5 and 6 are Frost, rune type 2
				icon.FirstType = 2
			elseif k > 2 then
				-- Slots 5 and 6 are Unholy, rune type 3
				icon.FirstType = 3
			else
				icon.FirstType = ceil(k/2)
			end
			break
		end
	end
	
	icon:SetInfo("texture; spell",
		textures[icon.FirstType] or "Interface\\Icons\\INV_Misc_QuestionMark",
		runeNames[icon.FirstType]
	)

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
		-- The first slot of a given rune type.
		local settingBit = bit.lshift(1, slot - 1)
		local slotEnabled = bit.band(RuneSlots, settingBit) == settingBit

		-- The second slot of the same rune type.
		local settingBit2 = bit.lshift(1, slot)
		local slot2Enabled = bit.band(RuneSlots, settingBit) == settingBit

		-- The number of runes of a given type that are enabled.
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