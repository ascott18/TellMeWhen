-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
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



local SND = TMW.SND
SND.tabText = L["SOUND_TAB"]
SND.LSM = LSM

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()	
	local Sounds = SND.ConfigContainer.SoundList
	
	Sounds.Header:SetText(L["SOUND_SOUNDTOPLAY"])
	
	Sounds.None:SetPoint("TOP")
	Sounds.None.Name:SetText(NONE)
	Sounds.None.Play:Hide()
	Sounds.None.soundfile = ""
	Sounds.None.soundname = "None"
	
	-- This must be done explicityly because otherwise, frame #1 would try to anchor to Sounds[0], which is the frame's userdata.
	SND:GetFrame(1):SetPoint("TOP", Sounds.None, "BOTTOM", 0, 0)
	
	SND:SetSoundsOffset(0)

	Sounds.ScrollBar:SetValue(0)
end)

function SND:GetNumFramesNeeded()
	local Sounds = SND.ConfigContainer.SoundList
	return floor(Sounds:GetHeight()/Sounds.None:GetHeight()) - 1
end

function SND:GetFrame(id)
	local Sounds = SND.ConfigContainer.SoundList
	if Sounds[id] then
		return Sounds[id]
	end
	
	local f = CreateFrame("Button", Sounds:GetName().."Sound"..id, Sounds, "TellMeWhen_SoundSelectButton", id)
	Sounds[id] = f
	f:SetPoint("TOP", Sounds[id-1], "BOTTOM", 0, 0)
	return f
end


---------- Events ----------
function SND:LoadSettingsForEventID(id)
	local eventFrame = self:ChooseEvent(id)

	if CI.ics and eventFrame then
		SND:SelectSound(self:GetEventSettings().Sound)
		SND:SetupEventSettings()
	end
end

function SND:SetupEventDisplay(eventID)
	if not eventID then return end

	local name = self:GetEventSettings(eventID).Sound

	if name == "None" then
		name = "|cff808080" .. NONE
	end

	self.Events[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r " .. name)
end



---------- Sounds ----------
function SND:CompileSoundList()
	if not SND.List or #LSM:List("sound")-1 ~= #SND.List then
		SND.List = CopyTable(LSM:List("sound"))

		for k, v in pairs(SND.List) do
			if v == "None" then
				tremove(SND.List, k)
				break
			end
		end
		sort(SND.List, function(a, b)
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

function SND:SetSoundsOffset(offs)
	SND:CompileSoundList()
	
	SND.offs = offs

	local numFramesNeeded = min(#SND.List, SND:GetNumFramesNeeded())
	
	for i = 1, numFramesNeeded do
		local f = SND:GetFrame(i)
		if f then
			local n = i + offs
			local name = SND.List[n]
			if name then
				f.soundname = name
				f.Name:SetText(name)
				f.soundfile = LSM:Fetch("sound", name)
				f:Show()
				if n == SND.selectedListID then
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
	
	SND.ConfigContainer.SoundList.Background:SetPoint("BOTTOMRIGHT", SND.ConfigContainer.SoundList[numFramesNeeded])
	
	SND.ConfigContainer.Custom:SetPoint("TOP", SND.ConfigContainer.SoundList[numFramesNeeded], "BOTTOM", 0, -5)
	
	for i = numFramesNeeded + 1, #SND.ConfigContainer.SoundList do
		SND.ConfigContainer.SoundList[i]:Hide()
	end

	SND.ConfigContainer.SoundList.ScrollBar:SetMinMaxValues(0, max(0, #SND.List - SND:GetNumFramesNeeded()))
	if max(0, #SND.List - SND:GetNumFramesNeeded()) == 0 then
		SND.ConfigContainer.SoundList.ScrollBar:Hide()
	else
		SND.ConfigContainer.SoundList.ScrollBar:Show()
	end
end

function SND:SelectSound(name)
	if not name then return end
	local soundFrame, listID

	for k, listname in ipairs(SND.List) do
		if listname == name then
			listID = k
			break
		end
	end

	local numFramesNeeded = min(#SND.List, SND:GetNumFramesNeeded())
	
	SND:SetSoundsOffset(SND.offs)
	if listID then
		local newOffs = SND.offs
		if listID > SND.ConfigContainer.SoundList[numFramesNeeded].listID then
			newOffs = newOffs + (listID - SND.ConfigContainer.SoundList[numFramesNeeded].listID)
		elseif listID < SND.ConfigContainer.SoundList[1].listID then
			newOffs = newOffs - (listID - SND.ConfigContainer.SoundList[numFramesNeeded].listID)
		end
		SND.ConfigContainer.SoundList.ScrollBar:SetValue(newOffs)
		SND:SetSoundsOffset(newOffs)
	end

	for i, frame in ipairs(SND.ConfigContainer.SoundList) do
		if frame:IsShown() and frame.soundname == name then
			soundFrame = frame
		end
		frame.selected = nil
		frame:UnlockHighlight()
		frame:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
	end

	SND.selectedListID = 0
	SND.ConfigContainer.Custom.selected = nil
	SND.ConfigContainer.Custom.Background:Hide()
	SND.ConfigContainer.Custom.Background:SetVertexColor(1, 1, 1, 1)
	SND.ConfigContainer.Custom:SetText("")
	SND.ConfigContainer.SoundList.None:UnlockHighlight()
	SND.ConfigContainer.SoundList.None:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)

	if name == "None" then
		SND.selectedListID = -1 -- lame
		SND.ConfigContainer.SoundList.None:LockHighlight()
		SND.ConfigContainer.SoundList.None:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif soundFrame then
		SND.selectedListID = soundFrame.listID
		soundFrame:LockHighlight()
		soundFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	elseif strfind(name, "%.[^\\]+$") then
		SND.ConfigContainer.Custom.selected = 1
		SND.ConfigContainer.Custom.Background:Show()
		SND.ConfigContainer.Custom.Background:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		SND.ConfigContainer.Custom:SetText(name)
	end

	--self:SetupEventDisplay(EVENTS.currentEventID)
	self:SetupEventDisplay(self.currentEventID)
end

