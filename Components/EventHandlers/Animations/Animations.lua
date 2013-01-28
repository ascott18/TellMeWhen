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

local huge = math.huge
local next, pairs, ipairs, type, assert, tinsert, sort =
	  next, pairs, ipairs, type, assert, tinsert, sort
local random, floor =
	  random, floor
local InCombatLockdown =
	  InCombatLockdown
	  
-- GLOBALS: UIParent, CreateFrame

local ActiveAnimations = {}

local EventHandler = TMW.Classes.EventHandler:New("Animations")

EventHandler.AllAnimationsByAnimation = {}
EventHandler.AllAnimationsOrdered = {}

EventHandler:RegisterEventDefaults{
	Animation	  	= "",
	Duration		= 0.8,
	Magnitude	  	= 10,
	ScaleMagnitude 	= 2,
	Period			= 0.4,
	Size_anim	  	= 0,
	SizeX	  		= 30,
	SizeY	  		= 30,
	Thickness	  	= 2,
	Fade	  		= true,
	Infinite  		= false,
	r_anim	  		= 1,
	g_anim	  		= 0,
	b_anim	  		= 0,
	a_anim	  		= 0.5,
	Image			= "",
	AnchorTo		= "IconModule_SelfIcon",
}

function EventHandler:ProcessIconEventSettings(event, eventSettings)
	if eventSettings.Animation ~= "" then
		return true
	end
end
function EventHandler:HandleEvent(icon, eventSettings)
	local Animation = eventSettings.Animation
	if Animation ~= "" then
		
		-- Find the eventHandlerData and animationData for the requested animation:
		
		-- First, check non-specific animations
		local NonSpecificEventHandlerData = self.NonSpecificEventHandlerData
		for i = 1, #NonSpecificEventHandlerData do
			local eventHandlerData = NonSpecificEventHandlerData[i]
			if eventHandlerData.animation == Animation then
			
				eventHandlerData.animationData.Play(icon, eventSettings, nil)
				return true
				
			end
		end
		
		-- If we didn't find it, check through all of the icon's IconComponents to find a match
		local Components = icon.Components
		for c = 1, #Components do
			local IconComponent = Components[c]
			local EventHandlerData = IconComponent.EventHandlerData
			for e = 1, #EventHandlerData do
				local eventHandlerData = EventHandlerData[e]
				if eventHandlerData.eventHandlerName == self.eventHandlerName and eventHandlerData.animation == Animation then
		
					eventHandlerData.animationData.Play(icon, eventSettings, IconComponent)
					return true
			
				end				
			end
		end
	end

end

function EventHandler:TMW_ONUPDATE_POST()
	if ActiveAnimations then
		for animatedObject, animations in next, ActiveAnimations do
			for _, animationTable in next, animations do
				if animationTable.HALTED then
					animatedObject:Animations_Stop(animationTable)
				else
					EventHandler.AllAnimationsByAnimation[animationTable.Animation].OnUpdate(animatedObject, animationTable)
				end
			end
		end
	end
end
TMW:RegisterCallback("TMW_ONUPDATE_POST", EventHandler)

local function GetAnchorOrWarn(icon, anchorTo)
	local name = icon:GetName() .. anchorTo
	local frame = _G[name]
	
	if not frame then
		TMW.Warn(L["ANIM_ANCHOR_NOT_FOUND"]:format(name))
		return icon
	end
	
	return frame
end

TMW:RegisterUpgrade(61224, {
	iconEventHandler = function(self, eventSettings)
		if eventSettings.Size_anim ~= 0 then
			eventSettings.Size_anim = (eventSettings.Size_anim - 30)/2
		end
	end,
})


function EventHandler:OnRegisterEventHandlerDataTable(eventHandlerData, order, animation, animationData)
	TMW:ValidateType("2 (order)", '[RegisterEventHandlerData - Animations](order, animation, animationData)', order, "number")
	TMW:ValidateType("3 (animation)", '[RegisterEventHandlerData - Animations](order, animation, animationData)', animation, "string")
	TMW:ValidateType("4 (animationData)", '[RegisterEventHandlerData - Animations](order, animation, animationData)', animationData, "table")
	
	assert(not EventHandler.AllAnimationsByAnimation[animation], ("An animation %q is already registered!"):format(animation))
	
	-- Validate the animationData table
	TMW:ValidateType("text", "animationData", animationData.text, "string")
	TMW:ValidateType("Play", "animationData", animationData.Play, "function")
	TMW:ValidateType("ConfigFrames", "animationData", animationData.ConfigFrames, "table")
	
	for i, configFrameIdentifier in ipairs(animationData.ConfigFrames) do
		TMW:ValidateType(i, "animationDat.ConfigFrames", configFrameIdentifier, "string")
	end
	
	animationData.order = order
	animationData.animation = animation
	
	eventHandlerData.animation = animation
	eventHandlerData.animationData = animationData
	
	EventHandler.AllAnimationsByAnimation[animation] = animationData
	
	tinsert(EventHandler.AllAnimationsOrdered, animationData)
	TMW:SortOrderedTables(EventHandler.AllAnimationsOrdered)
end

EventHandler:RegisterEventHandlerDataNonSpecific(1, "", {
	text = NONE,
	ConfigFrames = {},
	
	Play = function()
		-- Do nothing. This will never get called anyway because EventHandler:ProcessIconEventSettings declares this event handler as invalid,
		-- but it must be declared to pass validation.
	end,
})

EventHandler:RegisterEventHandlerDataNonSpecific(10, "SCREENSHAKE", {
	-- GLOBALS: WorldFrame 
	text = L["ANIM_SCREENSHAKE"],
	desc = L["ANIM_SCREENSHAKE_DESC"],
	ConfigFrames = {
		"Duration",
		"Magnitude",
	},

	Play = function(icon, eventSettings, IconComponent)
		if not WorldFrame:IsProtected() or not InCombatLockdown() then

			if not WorldFrame.Animations_Start then
				TMW.Classes.AnimatedObject:Embed(WorldFrame)
			end

			WorldFrame:Animations_Start{
				eventSettings = eventSettings,
				Start = TMW.time,
				Duration = eventSettings.Duration,

				Magnitude = eventSettings.Magnitude,
			}
		end
	end,

	OnUpdate = function(WorldFrame, table)
		local remaining = table.Duration - (TMW.time - table.Start)

		if remaining < 0 then
			WorldFrame:Animations_Stop(table)
		else
			local Amt = (table.Magnitude or 10) / (1 + 10*(300^(-(remaining))))
			local moveX = random(-Amt, Amt)
			local moveY = random(-Amt, Amt)

			WorldFrame:ClearAllPoints()
			for _, v in pairs(TMW.WorldFramePoints) do
				WorldFrame:SetPoint(v[1], v[2], v[3], v[4] + moveX, v[5] + moveY)
			end
		end
	end,
	OnStart = function(WorldFrame, table)
		if not TMW.WorldFramePoints then
			TMW.WorldFramePoints = {}
			for i = 1, WorldFrame:GetNumPoints() do
				TMW.WorldFramePoints[i] = { WorldFrame:GetPoint(i) }
			end
		end
	end,
	OnStop = function(WorldFrame, table)
		WorldFrame:ClearAllPoints()
		for _, v in pairs(TMW.WorldFramePoints) do
			WorldFrame:SetPoint(v[1], v[2], v[3], v[4], v[5])
		end
	end,
})
EventHandler:RegisterEventHandlerDataNonSpecific(11, "SCREENFLASH", {
	text = L["ANIM_SCREENFLASH"],
	desc = L["ANIM_SCREENFLASH_DESC"],
	ConfigFrames = {
		"Duration",
		"Period",
		"Fade",
		"Color",
	},

	Play = function(icon, eventSettings, IconComponent)
		local AnimationData = EventHandler.AllAnimationsByAnimation[eventSettings.Animation]

		local Duration = 0
		local Period = eventSettings.Period
		if Period == 0 then
			Duration = eventSettings.Duration
		else
			while Duration < eventSettings.Duration do
				Duration = Duration + (Period * 2)
			end
		end

		if not UIParent.Animations_Start then
			TMW.Classes.AnimatedObject:Embed(UIParent)
		end

		UIParent:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = Duration,

			Period = Period,
			Fade = eventSettings.Fade,
			Alpha = eventSettings.a_anim,
			r = eventSettings.r_anim,
			g = eventSettings.g_anim,
			b = eventSettings.b_anim,
		}
	end,
	
	OnUpdate = function(UIParent, table)
		local FlashPeriod = table.Period
		local animation_flasher = UIParent.animation_flasher

		local timePassed = TMW.time - table.Start
		local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 1

		if table.Fade and FlashPeriod ~= 0 then
			local remainingFlash = timePassed % FlashPeriod
			if fadingIn then
				animation_flasher:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
			else
				animation_flasher:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
			end
		else
			animation_flasher:SetAlpha(fadingIn and table.Alpha or 0)
		end

		-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
		if timePassed > table.Duration then
			UIParent:Animations_Stop(table)
		end
	end,
	OnStart = function(UIParent, table)
		local animation_flasher
		if UIParent.animation_flasher then
			animation_flasher = UIParent.animation_flasher
		else
			animation_flasher = UIParent:CreateTexture(nil, "BACKGROUND", nil, 6)
			
			animation_flasher:SetAllPoints(UIParent)
			animation_flasher:Hide()

			UIParent.animation_flasher = animation_flasher
		end

		animation_flasher:Show()
		animation_flasher:SetTexture(table.r, table.g, table.b, 1)
	end,
	OnStop = function(UIParent, table)
		UIParent.animation_flasher:Hide()
	end,
})


EventHandler:RegisterEventHandlerDataNonSpecific(20, "ICONSHAKE", {
	text = L["ANIM_ICONSHAKE"],
	desc = L["ANIM_ICONSHAKE_DESC"],
	ConfigFrames = {
		"Duration",
		"Infinite",
		"Magnitude",
	},

	Play = function(icon, eventSettings, IconComponent)
		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = eventSettings.Infinite and huge or eventSettings.Duration,

			Magnitude = eventSettings.Magnitude,
		}
	end,

	OnUpdate = function(icon, table)
		local remaining = table.Duration - (TMW.time - table.Start)

		if remaining < 0 then
			-- generic expiration
			icon:Animations_Stop(table)
		else
			local Amt = (table.Magnitude or 10) / (1 + 10*(300^(-(remaining))))
			local moveX = random(-Amt, Amt)
			local moveY = random(-Amt, Amt)

			local position = icon.position
			icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x + moveX, position.y + moveY)
		end
	end,
	OnStop = function(icon, table)
		local position = icon.position
		icon:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x, position.y)
	end,
})
EventHandler:RegisterEventHandlerDataNonSpecific(30, "ICONFLASH", {
	text = L["ANIM_ICONFLASH"],
	desc = L["ANIM_ICONFLASH_DESC"],
	ConfigFrames = {
		"Duration",
		"Infinite",
		"Period",
		"Fade",
		"Color",
		"AnchorTo",
	},

	Play = function(icon, eventSettings, IconComponent)
		local Duration = 0
		local Period = eventSettings.Period
		if eventSettings.Infinite then
			Duration = huge
		else
			if Period == 0 then
				Duration = eventSettings.Duration
			else
				while Duration < eventSettings.Duration do
					Duration = Duration + (Period * 2)
				end
			end
		end

		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = Duration,

			Period = Period,
			Fade = eventSettings.Fade,
			Alpha = eventSettings.a_anim,
			r = eventSettings.r_anim,
			g = eventSettings.g_anim,
			b = eventSettings.b_anim,
			
			AnchorTo = eventSettings.AnchorTo,
		}
	end,

	OnUpdate = function(icon, table)
		local FlashPeriod = table.Period
		local animation_flasher = icon.animation_flasher

		local timePassed = TMW.time - table.Start
		local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 1

		if table.Fade and FlashPeriod ~= 0 then
			local remainingFlash = timePassed % FlashPeriod
			if fadingIn then
				animation_flasher:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
			else
				animation_flasher:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
			end
		else
			animation_flasher:SetAlpha(fadingIn and table.Alpha or 0)
		end

		-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
		if timePassed > table.Duration then
			icon:Animations_Stop(table)
		end
	end,
	OnStart = function(icon, table)
		local animation_flasher
		if icon.animation_flasher then
			animation_flasher = icon.animation_flasher
		else
			animation_flasher = icon:CreateTexture(nil, "BACKGROUND", nil, 6)
			
			icon.animation_flasher = animation_flasher
		end
		
		animation_flasher:SetAllPoints(GetAnchorOrWarn(icon, table.AnchorTo))

		animation_flasher:Show()
		animation_flasher:SetTexture(table.r, table.g, table.b, 1)
	end,
	OnStop = function(icon, table)
		icon.animation_flasher:Hide()
	end,
})

EventHandler:RegisterEventHandlerDataNonSpecific(70, "ICONBORDER", {
	text = L["ANIM_ICONBORDER"],
	desc = L["ANIM_ICONBORDER_DESC"],
	ConfigFrames = {
		"Duration",
		"Infinite",
		"Period",
		"Fade",
		"Color",
		"Size_anim",
		"Thickness",
		"AnchorTo",
	},

	Play = function(icon, eventSettings, IconComponent)
		local Duration = 0
		local Period = eventSettings.Period
		if eventSettings.Infinite then
			Duration = huge
		else
			if Period == 0 then
				Duration = eventSettings.Duration
			else
				while Duration < eventSettings.Duration do
					Duration = Duration + (Period * 2)
				end
			end
		end

		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = Duration,

			Period = Period,
			Fade = eventSettings.Fade,
			Alpha = eventSettings.a_anim,
			r = eventSettings.r_anim,
			g = eventSettings.g_anim,
			b = eventSettings.b_anim,
			Thickness = eventSettings.Thickness,
			Size = eventSettings.Size_anim,
			
			AnchorTo = eventSettings.AnchorTo,
		}
	end,

	OnUpdate = function(icon, table)
		local FlashPeriod = table.Period
		local animation_border = icon.animation_border

		local timePassed = TMW.time - table.Start
		local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 0

		if table.Fade and FlashPeriod ~= 0 then
			local remainingFlash = timePassed % FlashPeriod
			if not fadingIn then
				animation_border:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
			else
				animation_border:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
			end
		else
			animation_border:SetAlpha(fadingIn and table.Alpha or 0)
		end

		-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
		if timePassed > table.Duration then
			icon:Animations_Stop(table)
		end
	end,
	OnStart = function(icon, table)
		local animation_border
		if icon.animation_border then
			animation_border = icon.animation_border
		else
			animation_border = CreateFrame("Frame", nil, icon)
			icon.animation_border = animation_border

			local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
			animation_border.TOP = tex
			tex:SetPoint("TOPLEFT")
			tex:SetPoint("TOPRIGHT")

			local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
			animation_border.BOTTOM = tex
			tex:SetPoint("BOTTOMLEFT")
			tex:SetPoint("BOTTOMRIGHT")

			local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
			animation_border.LEFT = tex
			tex:SetPoint("TOPLEFT", animation_border.TOP, "BOTTOMLEFT")
			tex:SetPoint("BOTTOMLEFT", animation_border.BOTTOM, "TOPLEFT")

			local tex = animation_border:CreateTexture(nil, "BACKGROUND", nil, 5)
			animation_border.RIGHT = tex
			tex:SetPoint("TOPRIGHT", animation_border.TOP, "BOTTOMRIGHT")
			tex:SetPoint("BOTTOMRIGHT", animation_border.BOTTOM, "TOPRIGHT")
		end
		
		local offset = table.Size
		
		animation_border:SetPoint("TOPLEFT", GetAnchorOrWarn(icon, table.AnchorTo), "TOPLEFT", -offset, offset)
		animation_border:SetPoint("BOTTOMRIGHT", GetAnchorOrWarn(icon, table.AnchorTo), "BOTTOMRIGHT", offset, -offset)

		animation_border:Show()

		for _, pos in TMW:Vararg("TOP", "BOTTOM", "LEFT", "RIGHT") do
			local tex = animation_border[pos]

			tex:SetTexture(table.r, table.g, table.b, 1)
			tex:SetSize(table.Thickness, table.Thickness)
		end
	end,
	OnStop = function(icon, table)
		icon.animation_border:Hide()
	end,
})
EventHandler:RegisterEventHandlerDataNonSpecific(80, "ICONOVERLAYIMG", {
	text = L["ANIM_ICONOVERLAYIMG"],
	desc = L["ANIM_ICONOVERLAYIMG_DESC"],
	ConfigFrames = {
		"Duration",
		"Infinite",
		"Period",
		"Fade",
		"Image",
		"AlphaStandalone",
		"SizeX",
		"SizeY",
		"AnchorTo",
	},

	Play = function(icon, eventSettings, IconComponent)
		local Duration = 0
		local Period = eventSettings.Period
		if eventSettings.Infinite then
			Duration = huge
		else
			if Period == 0 then
				Duration = eventSettings.Duration
			else
				while Duration < eventSettings.Duration do
					Duration = Duration + (Period * 2)
				end
			end
		end

		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = Duration,

			Period = Period,
			Fade = eventSettings.Fade,
			Alpha = eventSettings.a_anim,
			SizeX = eventSettings.SizeX,
			SizeY = eventSettings.SizeY,
			Image = TMW:GetTexturePathFromSetting(eventSettings.Image),
			
			AnchorTo = eventSettings.AnchorTo,
		}
	end,

	OnUpdate = function(icon, table)
		local FlashPeriod = table.Period
		local animation_overlay = icon.animation_overlay

		local timePassed = TMW.time - table.Start
		local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 0

		if table.Fade and FlashPeriod ~= 0 then
			local remainingFlash = timePassed % FlashPeriod
			if not fadingIn then
				animation_overlay:SetAlpha(table.Alpha*((FlashPeriod-remainingFlash)/FlashPeriod))
			else
				animation_overlay:SetAlpha(table.Alpha*(remainingFlash/FlashPeriod))
			end
		else
			animation_overlay:SetAlpha(fadingIn and table.Alpha or 0)
		end

		-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
		if timePassed > table.Duration then
			icon:Animations_Stop(table)
		end
	end,
	OnStart = function(icon, table)
		local animation_overlay
		if icon.animation_overlay then
			animation_overlay = icon.animation_overlay
		else
			animation_overlay = icon:CreateTexture(nil, "BACKGROUND", nil, 7)
			icon.animation_overlay = animation_overlay
		end
		
		animation_overlay:SetPoint("CENTER", GetAnchorOrWarn(icon, table.AnchorTo))

		animation_overlay:Show()
		animation_overlay:SetSize(table.SizeX, table.SizeY)

		animation_overlay:SetTexture(table.Image)
	end,
	OnStop = function(icon, table)
		icon.animation_overlay:Hide()
	end,
})
--[[EventHandler:RegisterEventHandlerDataNonSpecific(90, "", { --(spacer)
		noclick = true,
	},
)]]
EventHandler:RegisterEventHandlerDataNonSpecific(200, "ICONCLEAR", {
	text = L["ANIM_ICONCLEAR"],
	desc = L["ANIM_ICONCLEAR_DESC"],
	ConfigFrames = {},

	Play = function(icon, eventSettings, IconComponent)
		if icon:Animations_Has() then
			for k, v in pairs(icon:Animations_Get()) do
				-- instead of just calling :Animations_Stop() right here, set this attribute so that meta icons inheriting the animation will also stop it.
				v.HALTED = true
			end
		end
	end,
})



local AnimatedObject = TMW:NewClass("AnimatedObject")
function AnimatedObject:Animations_Get()
	if not self.animations then
		local t = {}
		ActiveAnimations = ActiveAnimations or {}
		ActiveAnimations[self] = t
		self.animations = t
		return t
	end
	return self.animations
end
function AnimatedObject:Animations_Has()
	return self.animations
end
function AnimatedObject:Animations_OnUnused()
	if self.animations then
		self.animations = nil
		ActiveAnimations[self] = nil
		if not next(ActiveAnimations) then
			ActiveAnimations = nil
		end
	end
end
function AnimatedObject:Animations_Start(table)
	local Animation = table.eventSettings.Animation
	local AnimationData = Animation and EventHandler.AllAnimationsByAnimation[Animation]

	if AnimationData then
		self:Animations_Get()[Animation] = table

		table.Animation = Animation

		-- Make sure not to overwrite this value.
		-- This is used to distingusih inherited meta animations from original animations on a metaicon.
		table.originIcon = table.originIcon or self

		if AnimationData.OnStart then
			AnimationData.OnStart(self, table)
		end

		TMW:Fire("TMW_ICON_ANIMATION_START", self, table)
	end
end
function AnimatedObject:Animations_Stop(arg1)
	local animations = self.animations

	if not animations then return end

	local Animation, table
	if type(arg1) == "table" then
		table = arg1
		Animation = table.Animation
	else
		table = animations[arg1]
		Animation = arg1
	end

	local AnimationData = EventHandler.AllAnimationsByAnimation[Animation]

	if AnimationData then
		animations[Animation] = nil

		if AnimationData.OnStop then
			AnimationData.OnStop(self, table)
		end

		if not next(animations) then
			self:Animations_OnUnused()
		end
	end
end

TMW.Classes.Icon:Inherit("AnimatedObject")