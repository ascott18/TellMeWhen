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

local Animations = TMW:NewClass("EventHandler_AnimationsBase", "EventHandler_ColumnConfig")
Animations.subHandlerDataIdentifier = "Animations"
Animations.subHandlerSettingKey = "Animation"

Animations.AllSubHandlersByIdentifier = {}
Animations.AllAnimationsOrdered = {}

Animations:RegisterEventDefaults{
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

TMW:RegisterUpgrade(61224, {
	iconEventHandler = function(self, eventSettings)
		if eventSettings.Size_anim ~= 0 then
			eventSettings.Size_anim = (eventSettings.Size_anim - 30)/2
		end
	end,
})


function Animations:ProcessIconEventSettings(event, eventSettings)
	if eventSettings.Animation ~= "" then
		return true
	end
end


function Animations:HandleEvent(icon, eventSettings)
	local Animation = eventSettings.Animation
	if Animation ~= "" then
		
		-- Find the eventHandlerData and animationData for the requested animation:
		
		-- First, check non-specific animations
		local NonSpecificEventHandlerData = self.NonSpecificEventHandlerData
		for i = 1, #NonSpecificEventHandlerData do
			local eventHandlerData = NonSpecificEventHandlerData[i]
			if eventHandlerData.subHandlerIdentifier == Animation then
			
				eventHandlerData.subHandlerData.Play(icon, eventSettings)
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
				
				if eventHandlerData.identifier == self.subHandlerDataIdentifier and eventHandlerData.subHandlerIdentifier == Animation then
		
					eventHandlerData.subHandlerData.Play(icon, eventSettings)
					return true
			
				end				
			end
		end
	end
end


function Animations:TMW_ONUPDATE_POST()
	if ActiveAnimations then
		for animatedObject, animations in next, ActiveAnimations do
			for _, animationTable in next, animations do
				if animationTable.HALTED then
					animatedObject:Animations_Stop(animationTable)
				else
					Animations.AllSubHandlersByIdentifier[animationTable.Animation].OnUpdate(animatedObject, animationTable)
				end
			end
		end
	end
end
TMW:RegisterCallback("TMW_ONUPDATE_POST", Animations)




function Animations:OnRegisterEventHandlerDataTable(eventHandlerData, order, animation, animationData)
	TMW:ValidateType("2 (order)", '[RegisterEventHandlerData - Animations](order, animation, animationData)', order, "number")
	TMW:ValidateType("3 (animation)", '[RegisterEventHandlerData - Animations](order, animation, animationData)', animation, "string")
	TMW:ValidateType("4 (animationData)", '[RegisterEventHandlerData - Animations](order, animation, animationData)', animationData, "table")
	
	assert(not self.AllSubHandlersByIdentifier[animation], ("An animation %q is already registered!"):format(animation))
	
	-- Validate the animationData table
	TMW:ValidateType("text", "animationData", animationData.text, "string")
	TMW:ValidateType("Play", "animationData", animationData.Play, "function")
	TMW:ValidateType("ConfigFrames", "animationData", animationData.ConfigFrames, "table")
	
	for i, configFrameIdentifier in ipairs(animationData.ConfigFrames) do
		TMW:ValidateType(i, "animationData.ConfigFrames", configFrameIdentifier, "string")
	end
	
	animationData.order = order
	animationData.subHandlerIdentifier = animation
	
	eventHandlerData.order = order
	eventHandlerData.subHandlerData = animationData
	eventHandlerData.subHandlerIdentifier = animation
	
	self.AllSubHandlersByIdentifier[animation] = animationData
	
	tinsert(self.AllAnimationsOrdered, animationData)
	TMW:SortOrderedTables(self.AllAnimationsOrdered)
end



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
	local AnimationData = Animation and Animations.AllSubHandlersByIdentifier[Animation]

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

	local AnimationData = Animations.AllSubHandlersByIdentifier[Animation]

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
function AnimatedObject:Animations_StopAll()
	local animations = self.animations

	if animations then
		for k, v in pairs(animations) do
			self:Animations_Stop(v)
		end
	end
end

TMW.Classes.Icon:Inherit("AnimatedObject")

TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon, soft)
	if not soft or not TMW.Locked then
		icon:Animations_StopAll()
	end
end)