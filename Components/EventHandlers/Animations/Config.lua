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

local CI = TMW.CI

local pairs, ipairs, max = 
	  pairs, ipairs, max

 -- GLOBALS: CreateFrame, NORMAL_FONT_COLOR, NONE

local EVENTS = TMW.EVENTS
local EventHandler = TMW.Classes.EventHandler.instancesByName.Animations
EventHandler.tabText = L["ANIM_TAB"]

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function(event)
	TMW:ConvertContainerToScrollFrame(EventHandler.ConfigContainer.ConfigFrames)
	local AnimationList = EventHandler.ConfigContainer.AnimationList

	EventHandler.ConfigContainer.ListHeader:SetText(L["ANIM_ANIMTOUSE"])
	EventHandler.ConfigContainer.SettingsHeader:SetText(L["ANIM_ANIMSETTINGS"])

end)

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	if not TMW.Locked and icon:Animations_Has() then
		for k, v in pairs(icon:Animations_Get()) do
			icon:Animations_Stop(v)
		end
	end
end)

---------- Events ----------
function EventHandler:GetAnimationFrame(frameID, previousFrame)
	local AnimationList = self.ConfigContainer.AnimationList
	
	local frame = AnimationList[frameID]
	if not frame then
		frame = CreateFrame("Button", AnimationList:GetName().."Animation"..frameID, AnimationList, "TellMeWhen_AnimationSelectButton", frameID)
		AnimationList[frameID] = frame
		frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
		frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
	end
	return frame
end

local animationsToDisplay = {}
function EventHandler:LoadSettingsForEventID(id)
	local AnimationList = EventHandler.ConfigContainer.AnimationList
	
	local previousFrame
	
	wipe(animationsToDisplay)
	
	for i, eventHandlerData in ipairs(self.NonSpecificEventHandlerData) do
		tinsert(animationsToDisplay, eventHandlerData.animationData)
	end
	
	for i, GenericComponent in ipairs(CI.ic.Components) do
		if GenericComponent.EventHandlerData then
			for i, eventHandlerData in ipairs(GenericComponent.EventHandlerData) do
				if eventHandlerData.eventHandler == self then
					tinsert(animationsToDisplay, eventHandlerData.animationData)
				end
			end
		end
	end
	
	TMW:SortOrderedTables(animationsToDisplay)
	
	local frameID = 0
	for _, animationData in ipairs(animationsToDisplay) do
		frameID = frameID + 1
		local frame = self:GetAnimationFrame(frameID, previousFrame)
		frame:Show()

		frame.animationData = animationData
		frame.animation = animationData.animation

		frame.Name:SetText(animationData.text)
		TMW:TT(frame, animationData.text, animationData.desc, 1, 1)

		previousFrame = frame
	end
	
	for i = #animationsToDisplay + 1, #AnimationList do
		AnimationList[i]:Hide()
	end

	if AnimationList[1] then
		AnimationList[1]:SetPoint("TOPLEFT", AnimationList, "TOPLEFT", 0, 0)
		AnimationList[1]:SetPoint("TOPRIGHT", AnimationList, "TOPRIGHT", 0, 0)
		
		AnimationList:Show()
	else
		AnimationList:Hide()
	end
	
	
	local EventSettings = EVENTS:GetEventSettings()
	self:SelectAnimation(EventSettings.Animation)
end

function EventHandler:SetupEventDisplay(eventID)
	if not eventID then return end

	local animation = EVENTS:GetEventSettings(eventID).Animation
	local animationData = self.AllAnimationsByAnimation[animation]

	if animationData then
		local text = animationData.text
		if text == NONE then
			text = "|cff808080" .. text
		end

		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r " .. text)
	else
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r UNKNOWN: " .. (animation or "?"))
	end
end



---------- Animations ----------
function EventHandler:SelectAnimation(animation)
	local EventSettings = EVENTS:GetEventSettings()
	local animationFrame
	
	for i=1, #EventHandler.ConfigContainer.AnimationList do
		local f = EventHandler.ConfigContainer.AnimationList[i]
		if f and f:IsShown() then
			if f.animation == animation then
				animationFrame = f
			end
			f.selected = nil
			f:UnlockHighlight()
			f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
		end
	end
	self.currentAnimationSetting = animation
	
	local Frames = EventHandler.ConfigContainer.ConfigFrames
	
	for configFrameIdentifier, configFrameData in pairs(EventHandler.ConfigFrameData) do
		
		local frame = configFrameData.frame
		if type(frame) == "string" then
			frame = Frames[frame]
		end
		if frame then
			frame:Hide()
		end
	end
	
	local animationData = self.AllAnimationsByAnimation[animation]
	local ConfigFrames = animationData and animationData.ConfigFrames
	
	local lastFrame, lastFrameBottomPadding
	for i, configFrameIdentifier in ipairs(ConfigFrames) do
		local configFrameData = EventHandler.ConfigFrameData[configFrameIdentifier]
		
		if not configFrameData then
			TMW:Error("Values in animationData.ConfigFrames for animation %q must resolve to a table registered via Animations:RegisterConfigFrame()", animation)
		else
			local frame = configFrameData.frame
			if type(frame) == "string" then
				frame = Frames[frame]
				if not frame then
					TMW:Error("Couldn't find child of %s with key %q for animation %q", Frames:GetName(), configFrameData.frame, animation)
				end
			end
			
			local yOffset = (configFrameData.topPadding or 0) + (lastFrameBottomPadding or 0)
			
			if lastFrame then
				frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -yOffset)
			else
				frame:SetPoint("TOP", Frames, "TOP", 0, -yOffset - 5)
			end
			frame:Show()
			lastFrame = frame
			
			TMW.safecall(configFrameData.Load, configFrameData, frame, EventSettings)
			
			lastFrameBottomPadding = configFrameData.bottomPadding
		end
	end	
	
	if animationFrame then
		animationFrame:LockHighlight()
		animationFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end

	self:SetupEventDisplay(self.currentEventID)
end


---------- Interface ----------
function EventHandler:SetSliderMinMax(Slider, level)
	-- level is passed in only when the setting is changing or being loaded
	if Slider.range then
		local deviation = Slider.range/2
		local val = level or Slider:GetValue()

		local newmin = max(0, val-deviation)
		local newmax = max(deviation, val + deviation)

		Slider:SetMinMaxValues(newmin, newmax)
		Slider.Low:SetText(newmin)
		Slider.High:SetText(newmax)
	end

	if level then
		Slider:SetValue(level)
	end
end

EventHandler.ConfigFrameData = {}
function EventHandler:RegisterConfigFrame(identifier, configFrameData)
	configFrameData.identifier = identifier
	TMW:ValidateType("identifier", "RegisterConfigFrame(identifier, configFrameData)", identifier, "string")
	
	TMW:ValidateType("configFrameData.frame", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.frame, "string;frame")
	TMW:ValidateType("configFrameData.Load", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.Load, "function")
	
	TMW:ValidateType("configFrameData.topPadding", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.topPadding, "number;nil")
	TMW:ValidateType("configFrameData.bottomPadding", "RegisterConfigFrame(identifier, configFrameData)", configFrameData.bottomPadding, "number;nil")
	
	EventHandler.ConfigFrameData[identifier] = configFrameData
end

local function Load_Generic_Slider(self, frame, EventSettings)
	EventHandler:SetSliderMinMax(frame, EventSettings[self.identifier])
	frame:Enable()
end

local function Load_Generic_Check(self, frame, EventSettings)
	frame:SetChecked(EventSettings[self.identifier])
end

TMW:RegisterRapidSetting("Duration")
EventHandler:RegisterConfigFrame("Duration", {
	frame = "Duration",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

TMW:RegisterRapidSetting("Magnitude")
EventHandler:RegisterConfigFrame("Magnitude", {
	frame = "Magnitude",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

TMW:RegisterRapidSetting("Period")
EventHandler:RegisterConfigFrame("Period", {
	frame = "Period",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

TMW:RegisterRapidSetting("Thickness")
EventHandler:RegisterConfigFrame("Thickness", {
	frame = "Thickness",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

TMW:RegisterRapidSetting("Size_anim")
EventHandler:RegisterConfigFrame("Size_anim", {
	frame = "Size_anim",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

EventHandler:RegisterConfigFrame("AlphaStandalone", {
	frame = "AlphaStandalone",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = function(self, frame, EventSettings)
		EventHandler:SetSliderMinMax(frame, EventSettings.a_anim*100)
		frame:Enable()
	end,
})

TMW:RegisterRapidSetting("SizeX")
EventHandler:RegisterConfigFrame("SizeX", {
	frame = "SizeX",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

TMW:RegisterRapidSetting("SizeY")
EventHandler:RegisterConfigFrame("SizeY", {
	frame = "SizeY",
	topPadding = 13,
	bottomPadding = 13,
	
	Load = Load_Generic_Slider,
})

EventHandler:RegisterConfigFrame("Fade", {
	frame = "Fade",
	--topPadding = 13,
	--bottomPadding = 13,
	Load = Load_Generic_Check,
})

EventHandler:RegisterConfigFrame("Infinite", {
	frame = "Infinite",
	--topPadding = 13,
	--bottomPadding = 13,
	Load = Load_Generic_Check,
})


EventHandler:RegisterConfigFrame("Image", {
	frame = "Image",
	topPadding = 4,
	bottomPadding = 7,
	
	Load = function(self, frame, EventSettings)
		frame:SetText(EventSettings.Image)
	end,
})

TMW:RegisterRapidSetting("r_anim")
TMW:RegisterRapidSetting("g_anim")
TMW:RegisterRapidSetting("b_anim")
TMW:RegisterRapidSetting("a_anim")
EventHandler:RegisterConfigFrame("Color", {
	frame = "Color",
	topPadding = 4,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		local r, g, b, a = EventSettings.r_anim, EventSettings.g_anim, EventSettings.b_anim, EventSettings.a_anim
		frame:GetNormalTexture():SetVertexColor(r, g, b, 1)
		frame.background:SetAlpha(a)
	end,
})

EventHandler:RegisterConfigFrame("Anchor", {
	frame = "Anchor",
	topPadding = 4,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		--[[local r, g, b, a = EventSettings.r_anim, EventSettings.g_anim, EventSettings.b_anim, EventSettings.a_anim
		frame:GetNormalTexture():SetVertexColor(r, g, b, 1)
		frame.background:SetAlpha(a)]]
	end,
})
	
	