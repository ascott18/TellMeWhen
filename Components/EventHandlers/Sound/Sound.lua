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

local strfind =
	  strfind
local PlaySoundFile =
	  PlaySoundFile


local LSM = LibStub("LibSharedMedia-3.0")


local SoundBase = TMW:NewClass("EventHandler_SoundBase", "EventHandler")

SoundBase:RegisterEventDefaults{
	Sound = "None",
}

TMW:RegisterUpgrade(42105, {
	-- cleanup some old stuff that i noticed is sticking around in my settings, probably in other peoples' settings too
	iconEventHandler = function(self, eventSettings)
		-- Major screw up: It should be "None", not "" for no sound.
		-- I think this is an old artifact of the 42102 upgrade.
		if eventSettings.Sound == "" then
			eventSettings.Sound = "None"
		end
	end,
})
TMW:RegisterUpgrade(42102, {
	icon = function(self, ics)
		local Events = ics.Events
		Events.OnShow.Sound = ics.SoundOnShow or "None"

		Events.OnHide.Sound = ics.SoundOnHide or "None"

		Events.OnStart.Sound = ics.SoundOnStart or "None"

		Events.OnFinish.Sound = ics.SoundOnFinish or "None"

		ics.SoundOnShow		= nil
		ics.SoundOnHide		= nil
		ics.SoundOnStart	= nil
		ics.SoundOnFinish	= nil
	end,
})


-- Helper methods
function SoundBase:GetSoundFile(sound)
	if sound == "" or sound == "Interface\\Quiet.ogg" or sound == "None" then
		return nil
	elseif strfind(sound, "%.[^\\]+$") then
		-- Checks to see if sound is a file name (although poorly). Checks for a period followed by non-slashes:
		-- Good: file.ogg; path\to\file.ogg
		-- Bad: file; path\to\file; folder.with.periods\containing\file.ogg
		return sound
	else
		-- This will handle sounds from LSM.
		local s = LSM:Fetch("sound", sound)
		if s and s ~= "Interface\\Quiet.ogg" and s ~= "" then
			return s
		end
	end
end


-- Required methods
function SoundBase:ProcessIconEventSettings(event, eventSettings)
	return not not self:GetSoundFile(eventSettings.Sound)
end

function SoundBase:HandleEvent(icon, eventSettings)
	local Sound = self:GetSoundFile(eventSettings.Sound)
	
	if Sound then
		PlaySoundFile(Sound, TMW.db.profile.SoundChannel)
		
		return true
	end
end

function SoundBase:OnRegisterEventHandlerDataTable()
	error("Do not register event handler data for the Sound event handler. Use LibStub('LibSharedMedia-3.0'):Register('sound', name, path) instead.", 3)
end

do	-- LSM sound registration
	LSM:Register("sound", "Rubber Ducky",  [[Sound\Doodad\Goblin_Lottery_Open01.wav]])
	LSM:Register("sound", "Cartoon FX",	   [[Sound\Doodad\Goblin_Lottery_Open03.wav]])
	LSM:Register("sound", "Explosion", 	   [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.wav]])
	LSM:Register("sound", "Shing!", 	   [[Sound\Doodad\PortcullisActive_Closed.wav]])
	LSM:Register("sound", "Wham!", 		   [[Sound\Doodad\PVP_Lordaeron_Door_Open.wav]])
	LSM:Register("sound", "Simon Chime",   [[Sound\Doodad\SimonGame_LargeBlueTree.wav]])
	LSM:Register("sound", "War Drums", 	   [[Sound\Event Sounds\Event_wardrum_ogre.wav]])
	LSM:Register("sound", "Cheer", 		   [[Sound\Event Sounds\OgreEventCheerUnique.wav]])
	LSM:Register("sound", "Humm", 		   [[Sound\Spells\SimonGame_Visual_GameStart.wav]])
	LSM:Register("sound", "Short Circuit", [[Sound\Spells\SimonGame_Visual_BadPress.wav]])
	LSM:Register("sound", "Fel Portal",    [[Sound\Spells\Sunwell_Fel_PortalStand.wav]])
	LSM:Register("sound", "Fel Nova", 	   [[Sound\Spells\SeepingGaseous_Fel_Nova.wav]])
	LSM:Register("sound", "You Will Die!", [[Sound\Creature\CThun\CThunYouWillDie.wav]])

	LSM:Register("sound", "Die!", 		   [[Sound\Creature\GruulTheDragonkiller\GRULLAIR_Gruul_Slay03.wav]])
	LSM:Register("sound", "You Fail!", 	   [[Sound\Creature\Kologarn\UR_Kologarn_slay02.wav]])

	LSM:Register("sound", "TMW - Pling 1", [[Interface\Addons\TellMeWhen\Sounds\Pling1.ogg]])
	LSM:Register("sound", "TMW - Pling 2", [[Interface\Addons\TellMeWhen\Sounds\Pling2.ogg]])
	LSM:Register("sound", "TMW - Pling 3", [[Interface\Addons\TellMeWhen\Sounds\Pling3.ogg]])
	LSM:Register("sound", "TMW - Pling 4", [[Interface\Addons\TellMeWhen\Sounds\Pling4.ogg]])
	LSM:Register("sound", "TMW - Pling 5", [[Interface\Addons\TellMeWhen\Sounds\Pling5.ogg]])
	LSM:Register("sound", "TMW - Pling 6", [[Interface\Addons\TellMeWhen\Sounds\Pling6.ogg]])
	LSM:Register("sound", "TMW - Ding 1",  [[Interface\Addons\TellMeWhen\Sounds\Ding1.ogg]])
	LSM:Register("sound", "TMW - Ding 2",  [[Interface\Addons\TellMeWhen\Sounds\Ding2.ogg]])
	LSM:Register("sound", "TMW - Ding 3",  [[Interface\Addons\TellMeWhen\Sounds\Ding3.ogg]])
	LSM:Register("sound", "TMW - Ding 4",  [[Interface\Addons\TellMeWhen\Sounds\Ding4.ogg]])
	LSM:Register("sound", "TMW - Ding 5",  [[Interface\Addons\TellMeWhen\Sounds\Ding5.ogg]])
	LSM:Register("sound", "TMW - Ding 6",  [[Interface\Addons\TellMeWhen\Sounds\Ding6.ogg]])
	LSM:Register("sound", "TMW - Ding 7",  [[Interface\Addons\TellMeWhen\Sounds\Ding7.ogg]])
	LSM:Register("sound", "TMW - Ding 8",  [[Interface\Addons\TellMeWhen\Sounds\Ding8.ogg]])
	LSM:Register("sound", "TMW - Ding 9",  [[Interface\Addons\TellMeWhen\Sounds\Ding9.ogg]])
end





-------------------
-- EventSound
-------------------

local EventSound = TMW.Classes.EventHandler_SoundBase:New("Sound")





-------------------
-- StatefulSound
-------------------

local StatefulSound = TMW:NewClass(nil, "EventHandler_WhileConditions_Repetitive", "EventHandler_SoundBase"):New("Sound2")
StatefulSound.frequencyMinimum = 0.2