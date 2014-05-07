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

local floor, min, max, strsub, strfind = 
	  floor, min, max, strsub, strfind
local pairs, ipairs, sort, tremove, CopyTable = 
	  pairs, ipairs, sort, tremove, CopyTable
	  
local CI = TMW.CI

local LSM = LibStub("LibSharedMedia-3.0")

-- GLOBALS: CreateFrame, NONE, NORMAL_FONT_COLOR



local EVENTS = TMW.EVENTS
local Sound = TMW.EVENTS:GetEventHandler("Sound")

Sound.handlerName = L["SOUND_TAB"]
Sound.handlerDesc = L["SOUND_TAB_DESC"]
Sound.LSM = LSM

TMW.HELP:NewCode("SND_INVALID_CUSTOM")


TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()	
	local Sounds = Sound.ConfigContainer.SoundList
	
	Sounds.Header:SetText(L["SOUND_SOUNDTOPLAY"])
	
	Sounds.None:SetPoint("TOP")
	Sounds.None.Name:SetText(NONE)
	Sounds.None.Play:Hide()
	Sounds.None.soundfile = ""
	Sounds.None.soundname = "None"
	
	-- This must be done explicityly because otherwise, frame #1 would try to anchor to Sounds[0], which is the frame's userdata.
	Sound:GetFrame(1):SetPoint("TOP", Sounds.None, "BOTTOM", 0, 0)
	
	Sound:SetSoundsOffset(0)

	Sounds.ScrollBar:SetValue(0)
end)


function Sound:GetNumFramesNeeded()
	local Sounds = self.ConfigContainer.SoundList
	return floor((Sounds:GetHeight()-5)/(Sounds.None:GetHeight())) - 1
end

function Sound:GetFrame(id)
	local Sounds = self.ConfigContainer.SoundList
	if Sounds[id] then
		return Sounds[id]
	end
	
	local f = CreateFrame("Button", Sounds:GetName().."Sound"..id, Sounds, "TellMeWhen_SoundSelectButton", id)
	Sounds[id] = f
	f:SetPoint("TOP", Sounds[id-1], "BOTTOM", 0, 0)
	return f
end


---------- Events ----------
function Sound:LoadSettingsForEventID(id)
	self:SelectSound(EVENTS:GetEventSettings().Sound)
end

function Sound:SetupEventDisplay(eventID)
	if not eventID then return end

	local name = EVENTS:GetEventSettings(eventID).Sound

	if name == "None" then
		name = "|cff808080" .. NONE
	end

	EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.handlerName .. ":|r " .. name)
end



---------- Sounds ----------
function Sound:CompileSoundList()
	if not Sound.List or #LSM:List("sound")-1 ~= #Sound.List then
		Sound.List = CopyTable(LSM:List("sound"))

		for k, v in pairs(Sound.List) do
			if v == "None" then
				tremove(Sound.List, k)
				break
			end
		end
		sort(Sound.List, function(a, b)
			local TMWa = strsub(a, 1, 3) == "TMW"
			local TMWb = strsub(b, 1, 3) == "TMW"
			if TMWa or TMWb then
				if TMWa and TMWb then
					return a < b
				else
					return TMWa
				end
			else
				return a < b
			end

		end)
	end
end

function Sound:SetSoundsOffset(offs)
	self:CompileSoundList()
	
	Sound.offs = offs

	local numFramesNeeded = min(#Sound.List, self:GetNumFramesNeeded())

	for i = 1, numFramesNeeded do
		local f = self:GetFrame(i)
		if f then
			local n = i + offs
			local name = Sound.List[n]
			if name then
				f.soundname = name
				f.Name:SetText(name)
				f.soundfile = LSM:Fetch("sound", name)
				f:Show()
				if n == Sound.selectedListID then
					f:LockHighlight()
					f:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
				else
					f:UnlockHighlight()
					f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
				end
			else
				f:Hide()
			end
			f.listID = n
		end
	end
	
	self.ConfigContainer.SoundList.Background:SetPoint("BOTTOMRIGHT", self.ConfigContainer.SoundList[numFramesNeeded])
	
	self.ConfigContainer.Custom:SetPoint("TOP", self.ConfigContainer.SoundList[numFramesNeeded], "BOTTOM", 0, -5)
	
	for i = numFramesNeeded + 1, #self.ConfigContainer.SoundList do
		self.ConfigContainer.SoundList[i]:Hide()
	end

	self.ConfigContainer.SoundList.ScrollBar:SetMinMaxValues(0, max(0, #Sound.List - self:GetNumFramesNeeded()))
	if max(0, #Sound.List - self:GetNumFramesNeeded()) == 0 then
		self.ConfigContainer.SoundList.ScrollBar:Hide()
	else
		self.ConfigContainer.SoundList.ScrollBar:Show()
	end
end

function Sound:SelectSound(name)
	if not name then return end
	local soundFrame, listID

	for k, listname in ipairs(Sound.List) do
		if listname == name then
			listID = k
			break
		end
	end

	local numFramesNeeded = min(#Sound.List, self:GetNumFramesNeeded())
	
	self:SetSoundsOffset(Sound.offs)
	if listID then
		local newOffs = Sound.offs
		if listID > self.ConfigContainer.SoundList[numFramesNeeded].listID then
			newOffs = newOffs + (listID - self.ConfigContainer.SoundList[numFramesNeeded].listID)
		elseif listID < self.ConfigContainer.SoundList[1].listID then
			newOffs = newOffs - (self.ConfigContainer.SoundList[1].listID - listID)
		end
		self.ConfigContainer.SoundList.ScrollBar:SetValue(newOffs)
		self:SetSoundsOffset(newOffs)
	end

	for i, frame in ipairs(self.ConfigContainer.SoundList) do
		if frame:IsShown() and frame.soundname == name then
			soundFrame = frame
		end
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end

	Sound.selectedListID = 0
	self.ConfigContainer.Custom.selected = nil
	self.ConfigContainer.Custom.Background:Hide()
	self.ConfigContainer.Custom.Background:SetVertexColor(1, 1, 1, 1)
	self.ConfigContainer.Custom:SetText("")
	self.ConfigContainer.SoundList.None:UnlockHighlight()
	self.ConfigContainer.SoundList.None:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)

	if name == "None" then
		Sound.selectedListID = -1 -- lame
		self.ConfigContainer.SoundList.None:LockHighlight()
		self.ConfigContainer.SoundList.None:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif soundFrame then
		Sound.selectedListID = soundFrame.listID
		soundFrame:LockHighlight()
		soundFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif strfind(name, "%.[^\\]+$") then
		self.ConfigContainer.Custom.selected = 1
		self.ConfigContainer.Custom.Background:Show()
		self.ConfigContainer.Custom.Background:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		self.ConfigContainer.Custom:SetText(name)
	end

	-- self:SetupEventDisplay(EVENTS.currentEventID)
end



---------- Tests ----------
local soundChannels = {
	-- GLOBALS: SOUND_VOLUME, MUSIC_VOLUME, AMBIENCE_VOLUME
	SFX = {
		text = ENABLE_SOUNDFX,
		enableCVar = "Sound_EnableSFX",
		volumeCVar = "Sound_SFXVolume",
	},
	Music = {
		text = MUSIC_VOLUME,
		enableCVar = "Sound_EnableMusic",
		volumeCVar = "Sound_MusicVolume",
	},
	Ambience = {
		text = AMBIENCE_VOLUME,
		enableCVar = "Sound_EnableAmbience",
		volumeCVar = "Sound_AmbienceVolume",
	},
	Master = {
		text = MASTER_VOLUME,
		enableCVar = "Sound_EnableAllSound",
		volumeCVar = "Sound_MasterVolume",
	},
}

TMW.HELP:NewCode("SOUND_TEST_ERROR", 10, false)

function Sound:TestSound(button, soundFile)
	PlaySoundFile(soundFile, TMW.db.profile.SoundChannel)

	local error

	if GetCVar("Sound_EnableAllSound") == "0" then
		error = L["SOUND_ERROR_ALLDISABLED"]
	else
		local channelData = soundChannels[TMW.db.profile.SoundChannel]

		if GetCVar(channelData.enableCVar) == "0" then
			error = L["SOUND_ERROR_DISABLED"]:format(channelData.text)
		elseif GetCVar(channelData.volumeCVar) == "0" then
			error = L["SOUND_ERROR_MUTED"]:format(channelData.text)
		end
	end

	if error then
		TMW.HELP:Show{
			code = "SOUND_TEST_ERROR",
			icon = TMW.CI.icon,
			relativeTo = button,
			x = 0,
			y = 0,
			text = format(error)
		}
	end	
end



