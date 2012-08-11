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

local EventHandler = TMW.Classes.EventHandler.instancesByName.Animations
EventHandler.tabText = L["ANIM_TAB"]

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function(event)
	local AnimationList = EventHandler.ConfigContainer.AnimationList

	AnimationList.Header:SetText(L["ANIM_ANIMTOUSE"])
	EventHandler.ConfigContainer.SettingsHeader:SetText(L["ANIM_ANIMSETTINGS"])

	-- create channel frames
	local previousFrame
	local offs = 0
	for i, animationData in ipairs(EventHandler.AllAnimationsOrdered) do --TODO TEMP DEBUG: don't get from this table
		i = i + offs
		local frame = CreateFrame("Button", AnimationList:GetName().."Animation"..i, AnimationList, "TellMeWhen_AnimationSelectButton", i)
		AnimationList[i] = frame
		frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
		frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
		frame:Show()

		frame.animationData = animationData
		frame.animation = animationData.animation

		if animationData.noclick then
			frame:SetScript("OnClick", nil)
			frame:GetHighlightTexture():SetTexture(nil)
		end

		frame.Name:SetText(animationData.text)
		TMW:TT(frame, animationData.text, animationData.desc, 1, 1)

		previousFrame = frame
	end

	if AnimationList[1] then
		AnimationList[1]:SetPoint("TOPLEFT", AnimationList, "TOPLEFT", 0, 0)
		AnimationList[1]:SetPoint("TOPRIGHT", AnimationList, "TOPRIGHT", 0, 0)

		AnimationList:SetHeight(#AnimationList*AnimationList[1]:GetHeight())
		
		AnimationList:Show()
	else
		AnimationList:Hide()
	end
end)

TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
	if not TMW.Locked and icon:Animations_Has() then
		for k, v in pairs(icon:Animations_Get()) do
			icon:Animations_Stop(v)
		end
	end
end)

---------- Events ----------
function EventHandler:LoadSettingsForEventID(id)
	local eventFrame = self:ChooseEvent(id)

	if CI.ics and eventFrame then
		local EventSettings = self:GetEventSettings()
		self:SelectAnimation(EventSettings.Animation)
		self:SetupEventSettings()
	end
end

function EventHandler:SetupEventDisplay(eventID)
	if not eventID then return end

	local animation = self:GetEventSettings(eventID).Animation
	local animationData = self.AllAnimationsByAnimation[animation]

	if animationData then
		local text = animationData.text
		if text == NONE then
			text = "|cff808080" .. text
		end

		self.Events[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r " .. text)
	else
		self.Events[eventID].DataText:SetText("|cffcccccc" .. self.tabText .. ":|r UNKNOWN: " .. (animation or "?"))
	end
end



---------- Animations ----------
function EventHandler:SelectAnimation(animation)
	local EventSettings = self:GetEventSettings()
	local animationFrame

	for i=1, #EventHandler.ConfigContainer.AnimationList do
		local f = EventHandler.ConfigContainer.AnimationList[i]
		if f then
			if f.animation == animation then
				animationFrame = f
			end
			f.selected = nil
			f:UnlockHighlight()
			f:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
		end
	end
	self.currentAnimationSetting = animation

	local animationData = self.AllAnimationsByAnimation[animation]
	for i, arg in TMW:Vararg("Duration", "Magnitude", "Period", "Thickness", "Size_anim", "SizeX", "SizeY") do
		if animationData and animationData[arg] then
			self:SetSliderMinMax(EventHandler.ConfigContainer[arg], EventSettings[arg])
			EventHandler.ConfigContainer[arg]:Show()
			EventHandler.ConfigContainer[arg]:Enable()
		else
			EventHandler.ConfigContainer[arg]:Hide()
		end
	end

	for i, arg in TMW:Vararg("Fade", "Infinite") do
		if animationData and animationData[arg] then
			EventHandler.ConfigContainer[arg]:SetChecked(EventSettings[arg])
			EventHandler.ConfigContainer[arg]:Show()
		else
			EventHandler.ConfigContainer[arg]:Hide()
		end
	end

	if animationData and animationData.Color then
		local r, g, b, a = EventSettings.r_anim, EventSettings.g_anim, EventSettings.b_anim, EventSettings.a_anim
		EventHandler.ConfigContainer.Color:GetNormalTexture():SetVertexColor(r, g, b, 1)
		EventHandler.ConfigContainer.Color.background:SetAlpha(a)
		EventHandler.ConfigContainer.Color:Show()
	else
		EventHandler.ConfigContainer.Color:Hide()
	end

	if animationData and animationData.Image then
		EventHandler.ConfigContainer.Image:SetText(EventSettings.Image)
		EventHandler.ConfigContainer.Image:Show()
	else
		EventHandler.ConfigContainer.Image:Hide()
	end

	if animationFrame then
		animationFrame:LockHighlight()
		animationFrame:GetHighlightTexture():SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	end

	--self:SetupEventDisplay(EVENTS.currentEventID)
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

