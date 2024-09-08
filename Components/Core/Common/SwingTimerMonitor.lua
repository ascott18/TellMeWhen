-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

-- This code is inspiried by Whammy! by Olidaine/Oddjorb [Argent Dawn]

--[[

-- To use the module, access SwingTimerMonitor.SwingTimers[weaponSlot]
-- where weaponSlot is either MAINHAND_SLOT or OFFHAND_SLOT (currently 16 or 17)
-- to get a SwingTimer object. Use the SwingTimer.duration and SwingTimer.startTime
-- to get data about it, and use event TMW_COMMON_SWINGTIMER_CHANGED to listen for swing time starts

]]

if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print


local strsub, pairs
	= strsub, pairs
local UnitGUID, GetNetStats, GetInventorySlotInfo, IsDualWielding, UnitAttackSpeed
	= UnitGUID, GetNetStats, GetInventorySlotInfo, IsDualWielding, UnitAttackSpeed

local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName
local strlowerCache = TMW.strlowerCache

-- Module creation
TMW.COMMON.SwingTimerMonitor = CreateFrame("Frame")

-- Constants
local MAINHAND_SLOT = GetInventorySlotInfo("MainHandSlot")
local OFFHAND_SLOT = GetInventorySlotInfo("SecondaryHandSlot")

-- Upvalues
local SwingTimers
local SwingTimerMonitor = TMW.COMMON.SwingTimerMonitor

-- Initialize module-wide variables
SwingTimerMonitor.DualWield = nil
SwingTimerMonitor.Latency = 0
SwingTimerMonitor.Initialized = false

local pGUID
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	pGUID = UnitGUID("player")
end)

local swingSpells = 
	not TMW.isRetail and {
		[strlowerCache[GetSpellName(78)]] = 1, -- Heroic Strike
		[strlowerCache[GetSpellName(845)]] = 1, -- Cleave
		[strlowerCache[GetSpellName(6807)]] = 1, -- Maul
		[strlowerCache[GetSpellName(2973)]] = 1, -- Raptor Strike
	} or {
		-- Retail spells:
        [strlowerCache[GetSpellName(404542)]] = 1, -- Crusading Strikes (ret talent)
    }

if GetSpellName(56815) then
	swingSpells[strlowerCache[GetSpellName(56815)]] = 1 -- Rune Strike
end

-- ---------------------------------
-- Misc state update functions
-- ---------------------------------

local function SetLatency()
	local _, _, Latency = GetNetStats()
	
	SwingTimerMonitor.Latency = Latency / 1000
end



-- ---------------------------------
-- SwingTimer class
-- ---------------------------------

local SwingTimer = TMW:NewClass("SwingTimer"){

	active = false,
	duration = 0,
	startTime = 0,
	
	OnNewInstance_SwingTimer = function(self, slot)
		self.slot = slot
		
		SwingTimers[slot] = self
	end,
	
	GetSwingEndTime = function(self)
		return self.startTime + self.duration
	end,
	
	CheckTime = function(self)
		local elapsed = TMW.time - self.startTime
		
		if elapsed > (self.duration - SwingTimerMonitor.Latency) then
			-- It should be safe at the current time to allow the timer to be
			-- overwritten with the next swing that is seen, so set it as inactive.
			self.active = false
		end
		
		if elapsed > self.duration then
			-- The time that has passed since the duration of the last swing
			-- has exceeded the swing timer, so reset it.
			self:Reset()
		end
		
		-- Notify any interested implementers
		self:FireChanged()
	end,
	
	FireChanged = function(self)
		TMW:Fire("TMW_COMMON_SWINGTIMER_CHANGED", self)
	end,
	
	Reset = function(self)
		self.active = false
	end,
	
	Start = function(self)
		self:Reset()
	
		self:SetSwingSpeed()
		SetLatency()
		
		self.active = true
		self.startTime = TMW.time
		
		self:CheckTime()
	end,
	

	SetSwingSpeed = function(self)
		local mainhand, offhand = UnitAttackSpeed("player")
		
		if self.slot == MAINHAND_SLOT then
			local delta = self.duration - mainhand

			-- Shift the start time by the percentage of the delta that has elapsed.
			-- elapsedTime = (TMW.time - self.startTime) / self.duration
			if self.duration ~= 0 and delta ~= 0 then
				self.startTime = self.startTime + ((TMW.time - self.startTime) / self.duration * delta)
			end
			self.duration = mainhand
		elseif SwingTimerMonitor.DualWield and offhand then
			local delta = self.duration - offhand
			if self.duration ~= 0 and delta ~= 0 then
				self.startTime = self.startTime + ((TMW.time - self.startTime) / self.duration * delta)
			end
			self.duration = offhand
		end
		self:CheckTime()
	end,
}


SwingTimerMonitor:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, event, _, src_guid, _, _, _, _, _, _, _, spellID, arg13, _, _, _, _, _, _, _, isOffHandHit = CombatLogGetCurrentEventInfo()
	
		if src_guid == pGUID then
			-- arg13 = spellName
			if (event == "SPELL_DAMAGE" or event == "SPELL_MISSED") and arg13 and swingSpells[strlowerCache[arg13]] then
				SwingTimers[MAINHAND_SLOT]:Start()
			elseif event == "SWING_DAMAGE" then
				SwingTimers[isOffHandHit and OFFHAND_SLOT or MAINHAND_SLOT]:Start()
			elseif event == "SWING_MISSED" then
				SwingTimers[arg13 and OFFHAND_SLOT or MAINHAND_SLOT]:Start()
			end
		end
	elseif event == "UNIT_ATTACK_SPEED" and ... == "player" then
		for slot, SwingTimer in pairs(SwingTimers) do
			SwingTimer:SetSwingSpeed()
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		SwingTimerMonitor.DualWield = IsDualWielding()
		-- When an item is changed in one of the weapon slots, 
		-- it resets that swing timer to its full duration
		local timer = SwingTimers[...]
		if timer then
			timer:Start()
		end
	end
end)


SwingTimerMonitor.SwingTimers = setmetatable({},
{__index = function(self, k)

	-- THIS TMW COMMON MODULE IS INITIALIZED HERE
	
	setmetatable(self, nil)
	
	-- Create the swing timers
	SwingTimer:New(MAINHAND_SLOT)
	SwingTimer:New(OFFHAND_SLOT)

	SwingTimerMonitor:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	SwingTimerMonitor:RegisterEvent("UNIT_ATTACK_SPEED")
	SwingTimerMonitor:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

	SwingTimerMonitor.DualWield = IsDualWielding()
	SwingTimerMonitor.Initialized = true

	return SwingTimers[k]
end}) SwingTimers = SwingTimerMonitor.SwingTimers