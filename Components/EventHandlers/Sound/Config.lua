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
local Sound = EVENTS:GetEventHandler("Sound")
Sound.handlerName = L["SOUND_TAB"]
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
	local Sounds = Sound.ConfigContainer.SoundList
	return floor(Sounds:GetHeight()/Sounds.None:GetHeight()) - 1
end

function Sound:GetFrame(id)
	local Sounds = Sound.ConfigContainer.SoundList
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
	Sound:SelectSound(EVENTS:GetEventSettings().Sound)
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
	Sound:CompileSoundList()
	
	Sound.offs = offs

	local numFramesNeeded = min(#Sound.List, Sound:GetNumFramesNeeded())
	
	for i = 1, numFramesNeeded do
		local f = Sound:GetFrame(i)
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
	
	Sound.ConfigContainer.SoundList.Background:SetPoint("BOTTOMRIGHT", Sound.ConfigContainer.SoundList[numFramesNeeded])
	
	Sound.ConfigContainer.Custom:SetPoint("TOP", Sound.ConfigContainer.SoundList[numFramesNeeded], "BOTTOM", 0, -5)
	
	for i = numFramesNeeded + 1, #Sound.ConfigContainer.SoundList do
		Sound.ConfigContainer.SoundList[i]:Hide()
	end

	Sound.ConfigContainer.SoundList.ScrollBar:SetMinMaxValues(0, max(0, #Sound.List - Sound:GetNumFramesNeeded()))
	if max(0, #Sound.List - Sound:GetNumFramesNeeded()) == 0 then
		Sound.ConfigContainer.SoundList.ScrollBar:Hide()
	else
		Sound.ConfigContainer.SoundList.ScrollBar:Show()
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

	local numFramesNeeded = min(#Sound.List, Sound:GetNumFramesNeeded())
	
	Sound:SetSoundsOffset(Sound.offs)
	if listID then
		local newOffs = Sound.offs
		if listID > Sound.ConfigContainer.SoundList[numFramesNeeded].listID then
			newOffs = newOffs + (listID - Sound.ConfigContainer.SoundList[numFramesNeeded].listID)
		elseif listID < Sound.ConfigContainer.SoundList[1].listID then
			newOffs = newOffs - (listID - Sound.ConfigContainer.SoundList[numFramesNeeded].listID)
		end
		Sound.ConfigContainer.SoundList.ScrollBar:SetValue(newOffs)
		Sound:SetSoundsOffset(newOffs)
	end

	for i, frame in ipairs(Sound.ConfigContainer.SoundList) do
		if frame:IsShown() and frame.soundname == name then
			soundFrame = frame
		end
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end

	Sound.selectedListID = 0
	Sound.ConfigContainer.Custom.selected = nil
	Sound.ConfigContainer.Custom.Background:Hide()
	Sound.ConfigContainer.Custom.Background:SetVertexColor(1, 1, 1, 1)
	Sound.ConfigContainer.Custom:SetText("")
	Sound.ConfigContainer.SoundList.None:UnlockHighlight()
	Sound.ConfigContainer.SoundList.None:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)

	if name == "None" then
		Sound.selectedListID = -1 -- lame
		Sound.ConfigContainer.SoundList.None:LockHighlight()
		Sound.ConfigContainer.SoundList.None:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif soundFrame then
		Sound.selectedListID = soundFrame.listID
		soundFrame:LockHighlight()
		soundFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif strfind(name, "%.[^\\]+$") then
		Sound.ConfigContainer.Custom.selected = 1
		Sound.ConfigContainer.Custom.Background:Show()
		Sound.ConfigContainer.Custom.Background:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		Sound.ConfigContainer.Custom:SetText(name)
	end

	self:SetupEventDisplay(self.currentEventID)
end

