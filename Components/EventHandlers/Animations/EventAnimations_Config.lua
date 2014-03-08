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

local CI = TMW.CI

local pairs, ipairs, max = 
	  pairs, ipairs, max

 -- GLOBALS: CreateFrame, NORMAL_FONT_COLOR, NONE

local EVENTS = TMW.EVENTS
local Animations = TMW.EVENTS:GetEventHandler("Animations")
Animations.handlerName = L["ANIM_TAB_EVENT"]

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function(event)
	TMW:ConvertContainerToScrollFrame(Animations.ConfigContainer.ConfigFrames)
	local SubHandlerList = Animations.ConfigContainer.SubHandlerList

	Animations.ConfigContainer.ListHeader:SetText(L["ANIM_ANIMTOUSE"])
	Animations.ConfigContainer.SettingsHeader:SetText(L["ANIM_ANIMSETTINGS"])

end)


---------- Events ----------
function Animations:SetupEventDisplay(eventID)
	if not eventID then return end

	local subHandlerData, subHandlerIdentifier = self:GetSubHandler(eventID)

	if subHandlerData then
		local text = subHandlerData.text
		if text == NONE then
			text = "|cff808080" .. text
		end

		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["ANIM_TAB"] .. ":|r " .. text)
	else
		EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["ANIM_TAB"] .. ":|r UNKNOWN: " .. (subHandlerIdentifier or "?"))
	end
end



---------- Interface ----------
local Load_Generic_Slider = Animations.Load_Generic_Slider
local Load_Generic_Check = Animations.Load_Generic_Check


TMW.IE:RegisterRapidSetting("Duration")
Animations:RegisterConfigFrame("Duration", {
	frame = "Duration",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_DURATION"],
	desc = L["ANIM_DURATION_DESC"],
	
	Load = Load_Generic_Slider,
})

TMW.IE:RegisterRapidSetting("Magnitude")
Animations:RegisterConfigFrame("Magnitude", {
	frame = "Magnitude",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_MAGNITUDE"],
	desc = L["ANIM_MAGNITUDE_DESC"],
	
	Load = Load_Generic_Slider,
})

TMW.IE:RegisterRapidSetting("Period")
Animations:RegisterConfigFrame("Period", {
	frame = "Period",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_PERIOD"],
	desc = L["ANIM_PERIOD_DESC"],
	
	Load = Load_Generic_Slider,
})

TMW.IE:RegisterRapidSetting("Thickness")
Animations:RegisterConfigFrame("Thickness", {
	frame = "Thickness",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_THICKNESS"],
	desc = L["ANIM_THICKNESS_DESC"],
	
	Load = Load_Generic_Slider,
})

TMW.IE:RegisterRapidSetting("Size_anim")
Animations:RegisterConfigFrame("Size_anim", {
	frame = "Size_anim",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_SIZE_ANIM"],
	desc = L["ANIM_SIZE_ANIM_DESC"],
	
	Load = function(self, frame, EventSettings)
		frame.min = -math.huge
		
		Load_Generic_Slider(self, frame, EventSettings)
	end,
})

Animations:RegisterConfigFrame("AlphaStandalone", {
	frame = "AlphaStandalone",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_ALPHASTANDALONE"],
	desc = L["ANIM_ALPHASTANDALONE_DESC"],
	
	Load = function(self, frame, EventSettings)
		Animations:SetSliderMinMax(frame, EventSettings.a_anim*100)

		frame.text:SetText(self.text)
		TMW:TT(frame, self.text, self.desc, 1, 1)

		frame:Enable()
	end,
})

TMW.IE:RegisterRapidSetting("SizeX")
Animations:RegisterConfigFrame("SizeX", {
	frame = "SizeX",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_SIZEX"],
	desc = L["ANIM_SIZEX_DESC"],
	
	Load = Load_Generic_Slider,
})

TMW.IE:RegisterRapidSetting("SizeY")
Animations:RegisterConfigFrame("SizeY", {
	frame = "SizeY",
	topPadding = 13,
	bottomPadding = 13,

	text = L["ANIM_SIZEY"],
	desc = L["ANIM_SIZEY_DESC"],
	
	Load = Load_Generic_Slider,
})

Animations:RegisterConfigFrame("Fade", {
	frame = "Fade",
	--topPadding = 13,
	--bottomPadding = 13,

	text = L["ANIM_FADE"],
	desc = L["ANIM_FADE_DESC"],

	Load = Load_Generic_Check,
})

Animations:RegisterConfigFrame("Infinite", {
	frame = "Infinite",
	--topPadding = 13,
	--bottomPadding = 13,

	text = L["ANIM_INFINITE"],
	desc = L["ANIM_INFINITE_DESC"],


	Load = Load_Generic_Check,
})


Animations:RegisterConfigFrame("Image", {
	frame = "Image",
	topPadding = 4,
	bottomPadding = 7,
	
	Load = function(self, frame, EventSettings)
		frame:SetText(EventSettings.Image)
	end,
})

TMW.IE:RegisterRapidSetting("r_anim")
TMW.IE:RegisterRapidSetting("g_anim")
TMW.IE:RegisterRapidSetting("b_anim")
TMW.IE:RegisterRapidSetting("a_anim")
Animations:RegisterConfigFrame("Color", {
	frame = "Color",
	topPadding = 4,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		local r, g, b, a = EventSettings.r_anim, EventSettings.g_anim, EventSettings.b_anim, EventSettings.a_anim
		frame:GetNormalTexture():SetVertexColor(r, g, b, 1)
		frame.background:SetAlpha(a)
	end,
})


Animations:RegisterConfigFrame("AnchorTo", {
	frame = "AnchorTo",
	topPadding = 14,
	bottomPadding = 4,
	
	Load = function(self, frame, EventSettings)
		Animations:AnchorTo_Dropdown_SetText(EventSettings.AnchorTo)
	end,
})

function Animations:AnchorTo_Dropdown()
	for _, IconModule in pairs(TMW.CI.icon.Modules) do
		for identifier, localizedName in pairs(IconModule.anchorableChildren) do
			if type(localizedName) == "string" then
				local completeIdentifier = IconModule.className .. identifier
				
				local info = UIDropDownMenu_CreateInfo()

				info.text = localizedName
			--[[	info.tooltipTitle = get(eventData.text)
				info.tooltipText = get(eventData.desc)
				info.tooltipOnButton = true]]

				info.value = completeIdentifier
				info.func = Animations.AnchorTo_Dropdown_OnClick
				
				info.checked = EVENTS:GetEventSettings().AnchorTo == completeIdentifier

				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				
			end
		end
	end
end
function Animations:AnchorTo_Dropdown_SetText(setting)
	local frame = Animations.ConfigContainer.ConfigFrames.AnchorTo
	local text = ""
	
	for _, IconModule in pairs(TMW.CI.icon.Modules) do
		for identifier, localizedName in pairs(IconModule.anchorableChildren) do
			local completeIdentifier = IconModule.className .. identifier
			if completeIdentifier == setting and type(localizedName) == "string" then
				
				UIDropDownMenu_SetText(frame, localizedName)
				return
				
			end
		end
	end
	
	UIDropDownMenu_SetText(frame, "????")
end
function Animations:AnchorTo_Dropdown_OnClick(event, value)
	EVENTS:GetEventSettings().AnchorTo = self.value
	
	Animations:AnchorTo_Dropdown_SetText(self.value)
end





