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

local pairs, error, rawget, next, wipe, tinsert, sort, strsplit, table, assert, loadstring, ipairs, tostring, assert
	= pairs, error, rawget, next, wipe, tinsert, sort, strsplit, table, assert, loadstring, ipairs, tostring, assert


--- {{{TMW.Classes.Icon}}} is the class of all Icons.
--
-- Icon inherits explicitly from {{{Blizzard.Button}}} and from {{{TMW.Classes.GenericModuleImplementor}}}, and implicitly from the classes that it inherits. 
--
-- Description of Class here
--
-- @class file
-- @name Icon.lua





local bitband = bit.band

local function ClearScripts(f)
	f:SetScript("OnEvent", nil)
	f:SetScript("OnUpdate", nil)
	if f:HasScript("OnValueChanged") then
		f:SetScript("OnValueChanged", nil)
	end
end

local UPD_INTV
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	UPD_INTV = TMW.UPD_INTV
end)



local Icon = TMW:NewClass("Icon", "Button", "UpdateTableManager", "GenericModuleImplementor")
Icon:UpdateTable_Set(TMW.IconsToUpdate)
Icon.IsIcon = true
Icon.attributes = {}
Icon.runEvents = 1
Icon.QueuedIcons = {}
Icon.NextUpdateTime = math.huge
local QueuedIcons = Icon.QueuedIcons

-- [INTERNAL]
function Icon.OnNewInstance(icon, ...)	
	local _, name, group, _, iconID = ... -- the CreateFrame args

	icon.group = group
	icon.ID = iconID
	group[iconID] = icon
	
	icon.EventHandlersSet = {}
	icon.lmbButtonData = {}
	icon.position = {}
	icon.anchorableChildren = {}
	
	icon.attributes = icon:InheritTable(Icon, "attributes")
end

-- [INTERNAL]
function Icon.__lt(icon1, icon2)
	local g1 = icon1.group.ID
	local g2 = icon2.group.ID
	if g1 ~= g2 then
		return g1 < g2
	else
		return icon1.ID < icon2.ID
	end
end

-- [INTERNAL]
function Icon.__tostring(icon)
	return icon:GetName()
end

function Icon.ScriptSort(iconA, iconB)
	local gOrder = -TMW.db.profile.CheckOrder
	local gA = iconA.group.ID
	local gB = iconB.group.ID
	if gA == gB then
		local iOrder = -TMW.db.profile.Groups[gA].CheckOrder
		return iconA.ID*iOrder < iconB.ID*iOrder
	end
	return gA*gOrder < gB*gOrder
end
Icon:UpdateTable_SetAutoSort(Icon.ScriptSort)
TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", "UpdateTable_PerformAutoSort", Icon)

-- [WRAPPER] (no documentation needed)
Icon.SetScript_Blizz = Icon.SetScript
function Icon.SetScript(icon, handler, func)
	icon[handler] = func
	icon:SetScript_Blizz(handler, func)
end

-- [INTERNAL]
function Icon.CheckUpdateTableRegistration(icon)
	if icon.UpdateFunction then
		icon:UpdateTable_Register()
	else
		icon:UpdateTable_Unregister()
	end
end

function Icon.SetUpdateFunction(icon, func)
	icon.UpdateFunction = func
	
	if not icon.IsSettingUp then
		icon:CheckUpdateTableRegistration()
	end
end

-- [WRAPPER] (no documentation needed)
Icon.RegisterEvent_Blizz = Icon.RegisterEvent
function Icon.RegisterEvent(icon, event)
	icon:RegisterEvent_Blizz(event)
	icon.hasEvents = 1
end

-- [WRAPPER] (no documentation needed)
Icon.UnregisterAllEvents_Blizz = Icon.UnregisterAllEvents
function Icon.UnregisterAllEvents(icon, event)
	-- UnregisterAllEvents_Blizz uses a metric fuckton of CPU, so only do it if needed
	if icon.hasEvents then
		icon:UnregisterAllEvents_Blizz()
		icon.hasEvents = nil
	end
end

-- [SCRIPT HANDLER] (no documentation needed)
function Icon.OnShow(icon)
	icon:SetInfo("shown", true)
end
-- [SCRIPT HANDLER] (no documentation needed)
function Icon.OnHide(icon)
	icon:SetInfo("shown", false)
end

function Icon.GetSettings(icon)
	return TMW.db.profile.Groups[icon.group:GetID()].Icons[icon:GetID()]
end

function Icon.GetSettingsPerView(icon, view)
	view = view or icon.group:GetSettings().View
	return icon:GetSettings().SettingsPerView[view]
end

function Icon.IsBeingEdited(icon)
	if TMW.IE and TMW.CI.ic == icon and TMW.IE.CurrentTab and TMW.IE:IsVisible() then
		return TMW.IE.CurrentTab:GetID()
	end
end


function Icon.QueueEvent(icon, arg1)
	icon.EventsToFire[arg1] = true
	icon.eventIsQueued = true
	
	QueuedIcons[#QueuedIcons + 1] = icon
end

-- [INTERNAL] (no documentation needed)
function Icon.RestoreEvents(icon)
	icon.runEvents = 1
	icon.runEventsTimerHandler = nil
	if icon.EventHandlersSet.OnEventsRestored and TMW.Locked then
		icon:QueueEvent("OnEventsRestored")
		icon:ProcessQueuedEvents()
	end
end

function Icon.IsInRange(icon)
	return icon:GetID() <= icon.group.Rows*icon.group.Columns
end

function Icon.IsValid(icon)
	-- checks if the icon should be in the list of icons that can be checked in metas/conditions

	return icon.Enabled and icon:IsInRange() and icon.group:IsValid()
end

Icon.Update_Method = "auto"
function Icon.SetUpdateMethod(icon, method)
	if TMW.db.profile.DEBUG_ForceAutoUpdate then
		method = "auto"
	end

	icon.Update_Method = method

	if method == "auto" then
		-- do nothing for now.
	elseif method == "manual" then
		icon.NextUpdateTime = 0
	else
		error("Unknown update method " .. method)
	end
end

-- [INTERNAL] (no documentation needed)
function Icon.ScheduleNextUpdate(icon)
	local attributes = icon.attributes
	local time = TMW.time
	
	local currentIconDuration = attributes.duration - (time - attributes.start)
	if currentIconDuration < 0 then currentIconDuration = 0 end

	icon.NextUpdate_Duration = 0
	
	--[[
		Fire an event that requests whatever is listening to it to add in its
		two cents about when the next update should be.
		Callback handlers for this event should set icon.NextUpdate_Duration to the duration remaining
		on the icon at which an update is needed.
	]]
	TMW:Fire("TMW_ICON_NEXTUPDATE_REQUESTDURATION", icon, currentIconDuration)

	local nextUpdateTime = time + (currentIconDuration - icon.NextUpdate_Duration)
	if nextUpdateTime == time then
		nextUpdateTime = nil
	end
	icon.NextUpdateTime = nextUpdateTime
end


local IconEventUpdateEngine = CreateFrame("Frame")
TMW.IconEventUpdateEngine = IconEventUpdateEngine
IconEventUpdateEngine.UpdateEvents = setmetatable({}, {__index = function(self, event)
	self[event] = {}
	return self[event]
end})
IconEventUpdateEngine:SetScript("OnEvent", function(self, event, arg1)
	local iconsForEvent = self.UpdateEvents[event]
	for icon, arg1ToMatch in pairs(iconsForEvent) do
		if arg1ToMatch == true or arg1ToMatch == arg1 then
			icon.NextUpdateTime = 0
		end
	end
end)
function Icon.RegisterSimpleUpdateEvent(icon, event, arg1)
	arg1 = arg1 or true
	
	local iconsForEvent = IconEventUpdateEngine.UpdateEvents[event]
	local existing = iconsForEvent[icon]
	if existing and existing ~= arg1 then
		error("Can't change the arg that you are checking for an event without unregistering first", 2)
	end
	iconsForEvent[icon] = arg1
	IconEventUpdateEngine:RegisterEvent(event)
end
function Icon.UnregisterSimpleUpdateEvent(icon, event)
	local iconsForEvent = rawget(IconEventUpdateEngine.UpdateEvents, event)
	if iconsForEvent then
		iconsForEvent[icon] = nil
		if not next(iconsForEvent) then
			IconEventUpdateEngine:UnregisterEvent(event)
		end
	end
end
function Icon.UnregisterAllSimpleUpdateEvents(icon)
	for event, iconsForEvent in pairs(IconEventUpdateEngine.UpdateEvents) do
		iconsForEvent[icon] = nil
		if not next(iconsForEvent) then
			IconEventUpdateEngine:UnregisterEvent(event)
		end
	end
end


function Icon.Update(icon, force, ...)
	local attributes = icon.attributes
	local time = TMW.time
	
	if attributes.shown and (force or icon.LastUpdate <= time - UPD_INTV) then
		icon.LastUpdate = time
		
		local Update_Method = icon.Update_Method

		local ConditionObject = icon.ConditionObject
		if ConditionObject then
			-- The condition check needs to come before we determine iconUpdateNeeded because
			-- checking a condition may set NextUpdateTime to 0 if the condition passing state changes.
			if ConditionObject.UpdateNeeded or ConditionObject.NextUpdateTime < time then
				ConditionObject:Check()
			end
		end

		local iconUpdateNeeded = force or Update_Method == "auto" or icon.NextUpdateTime < time

		if iconUpdateNeeded then
			icon:UpdateFunction(time, ...)
			if Update_Method == "manual" then
				icon:ScheduleNextUpdate()
			end
		end
	end
end

-- [EVENT HANDLER] (no documentation needed)
function Icon.TMW_CNDT_OBJ_PASSING_CHANGED(icon, event, ConditionObject, failed)
	-- failed is boolean, never nil. nil is used for the conditionFailed attribute if there are no conditions on the icon.
	if icon.ConditionObject == ConditionObject then
		icon.NextUpdateTime = 0
		
		icon:SetInfo("conditionFailed", failed)
	end
end

function Icon.ProcessQueuedEvents(icon)
	local EventsToFire = icon.EventsToFire
	if EventsToFire and icon.eventIsQueued then
		local handledOne
		for i = 1, (icon.Events.n or 0) do
			-- settings to check for in EventsToFire
			local EventSettingsFromIconSettings = icon.Events[i]
			local event = EventSettingsFromIconSettings.Event
			
			local EventSettings
			if EventsToFire[EventSettingsFromIconSettings] or EventsToFire[event] then
				-- we should process EventSettingsFromIconSettings
				EventSettings = EventSettingsFromIconSettings
			end
			local eventData = TMW.EventList[event]
			if eventData and EventSettings then
				local shouldProcess = true
				if EventSettings.OnlyShown and icon.attributes.realAlpha <= 0 then
					shouldProcess = false

				elseif EventSettings.PassingCndt then
					local conditionChecker = eventData.conditionChecker
					local conditionResult = true
					
					if conditionChecker then
						conditionResult = conditionChecker(icon, EventSettings)
						
						if EventSettings.CndtJustPassed then
							if conditionResult ~= EventSettings.wasPassingCondition then
								EventSettings.wasPassingCondition = conditionResult
							else
								conditionResult = false
							end
						end
					end
					shouldProcess = conditionResult
				end

				if shouldProcess and icon.runEvents and icon.attributes.shown then
					local EventHandler = TMW:GetEventHandler(EventSettings.Type, true)
					if EventHandler then
						local handled = EventHandler:HandleEvent(icon, EventSettings)
						if handled then
							if not EventSettings.PassThrough then
								break
							end
							handledOne = true
						end
					end
				end
			end
		end

		wipe(EventsToFire)
		icon.eventIsQueued = nil
		if handledOne then
			TMW:Fire("TMW_ICON_UPDATED", icon)
		end
	end
end

function Icon.DisableIcon(icon)
	
	icon:UnregisterAllEvents()
	icon:UnregisterAllSimpleUpdateEvents()
	ClearScripts(icon)
	icon:SetUpdateMethod("auto")
	icon:SetUpdateFunction(nil)
	icon:Hide()

	icon:DisableAllModules()
	
	if icon.typeData then
		icon.typeData:UnimplementFromIcon(icon)
	end
	
	if icon.viewData then
		icon.viewData:UnimplementFromIcon(icon)
	end
	
	TMW:Fire("TMW_ICON_DISABLE", icon)
end

function Icon.Setup(icon)
	if not icon or not icon[0] then return end
	
	local iconID = icon:GetID()
	local group = icon.group
	local groupID = group:GetID()
	local ics = icon:GetSettings()
	local typeData = TMW.Types[ics.Type]
	local viewData = group.viewData
	
	if not group:ShouldUpdateIcons() then return end
	
	icon.IsSettingUp = true
	
	local typeData_old = icon.typeData
	
	icon:DisableIcon()
	
	icon.viewData = viewData
	icon.typeData = typeData	

	if not typeData then
		error("TellMeWhen: Critical error: Couldn't find type data or fallback type data for " .. ics.Type .. " (Where is the default icon type?)")
	end
	
	for k in pairs(TMW.Icon_Defaults) do
		if typeData.RelevantSettings[k] then
			icon[k] = ics[k]
		else
			icon[k] = nil
		end
	end

	-- process alpha settings
	if icon.ShowWhen then
		if bitband(icon.ShowWhen, 0x1) == 0 then
			icon.UnAlpha = 0
		elseif bitband(icon.ShowWhen, 0x2) == 0 then
			icon.Alpha = 0
		end
	end
	
	icon:Show()
	icon:SetFrameLevel(group:GetFrameLevel() + 1)

	TMW:Fire("TMW_ICON_SETUP_PRE", icon)

	-- Conditions
	local ConditionObjectConstructor = icon:Conditions_GetConstructor(icon.Conditions)
	icon.ConditionObject = ConditionObjectConstructor:Construct()
	
	if icon.ConditionObject then
		TMW:RegisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", icon)
		icon:SetInfo("conditionFailed", icon.ConditionObject.Failed)
	else
		TMW:UnregisterCallback("TMW_CNDT_OBJ_PASSING_CHANGED", icon)
		icon:SetInfo("conditionFailed", nil)
	end

	-- force an update
	icon.LastUpdate = 0
	
	-- actually run the icon's update function
	if icon.Enabled or not TMW.Locked then
	
		------------ Icon Type ------------
		typeData:ImplementIntoIcon(icon)
		
		if icon.typeData ~= typeData_old then
			TMW:Fire("TMW_ICON_TYPE_CHANGED", icon, typeData, typeData_old)
		end		
		
		------------ Icon View ------------
		viewData:ImplementIntoIcon(icon)
		viewData:Icon_Setup(icon)
		
		
		TMW.safecall(typeData.Setup, typeData, icon, groupID, iconID)
	else
		icon:DisableIcon()
	end

	icon.NextUpdateTime = 0

	if TMW.Locked then	
		icon:SetInfo("alphaOverride", nil)
		if icon.attributes.texture == "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled" then
			icon:SetInfo("texture", "")
		end
		icon:EnableMouse(0)
	else
		icon:Show()
		ClearScripts(icon)
		icon:SetUpdateFunction(nil)
		
		icon:SetInfo(
			"alphaOverride; start, duration; stack, stackText",
			icon.Enabled and 1 or 0.5,
			0, 0,
			nil, nil
		)
		
		if icon.attributes.texture == "" then
			icon:SetInfo("texture", "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
		end

		icon:EnableMouse(1)
	end
	
	icon:CheckUpdateTableRegistration()

	TMW:Fire("TMW_ICON_SETUP_POST", icon)
	
	icon.IsSettingUp = nil
end

-- [INTERNAL] (no documentation needed)
function Icon.SetupAllModulesForIcon(icon, sourceIcon)
	for moduleName, Module in pairs(icon.Modules) do
		if Module.SetupForIcon and Module.IsEnabled and not Module.dontInherit then
			TMW.safecall(Module.SetupForIcon, Module, sourceIcon)
		end
	end
end

-- [INTERNAL] (no documentation needed)
function Icon.SetModulesToEnabledStateOfIcon(icon, sourceIcon)
	local sourceModules = sourceIcon.Modules
	for moduleName, Module in pairs(icon.Modules) do
		if Module.IsImplemented and not Module.dontInherit then
			local sourceModule = sourceModules[moduleName]
			if sourceModule then
				if sourceModule.IsEnabled then
					Module:Enable(true)
				else
					Module:Disable()
				end
			else
				Module:Disable()
			end
		end
	end
end

TMW.IconAlphaManager = {
	AlphaHandlers = {},
	
	HandlerSorter = function(a, b)
		return a.order < b.order
	end,
	
	UPDATE = function(self, event, icon)
		local attributes = icon.attributes
		local AlphaHandlers = self.AlphaHandlers
		
		local handlerToUse
		
		for i = 1, #AlphaHandlers do
			local handler = AlphaHandlers[i]
			
			local alpha = attributes[handler.attribute]
			
			if alpha == 0 then
				-- If an alpha is set to 0, then the icon should be hidden no matter what, 
				-- so use it as the final alpha value and stop looking for more.
				-- This functionality has existed in TMW since practically day one, by the way. So don't be clever and remove it.
				handlerToUse = handler
				break
			elseif alpha ~= nil then
				if handler.haltImmediatelyIfFound then
					-- This is currently only used for ALPHAOVERRIDE
					handlerToUse = handler
					break
				elseif not handlerToUse then
					-- If we found an alpha value that isn't nil and we haven't figured out
					-- an alpha value to use yet, use this one, but keep looking for 0 values.
					handlerToUse = handler
				end
			end
		end
		
		if handlerToUse then			
			-- realAlpha stores the alpha that the icon should be showing, before FakeHidden.
			icon:SetInfo_INTERNAL("realAlpha", attributes[handlerToUse.attribute])
		end
	end,
	
	SetupHandler = function(handler)
		local self = handler.self
		
		local IconDataProcessor = TMW.Classes.IconDataProcessor.ProcessorsByName[handler.processorName]
		if IconDataProcessor then
			if IconDataProcessor.NumAttributes ~= 1 then
				error("IconModule_Alpha handlers cannot check IconDataProcessors that have more than one attribute!")
			end
			
			handler.attribute = IconDataProcessor.attributesStringNoSpaces
			
			TMW:RegisterCallback(IconDataProcessor.changedEvent, "UPDATE", self)
			
			TMW:UnregisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", self.SetupHandler, handler)
		end
	end,

	-- PUBLIC METHOD (ish)
	AddHandler = function(self, order, processorName, haltImmediatelyIfFound)
		TMW:ValidateType(2, "IconAlphaManager:AddHandler()", order, "number")
		TMW:ValidateType(3, "IconAlphaManager:AddHandler()", processorName, "string")
		
		local handler = {
			self = self,
			order = order,
			processorName = processorName,
			haltImmediatelyIfFound = haltImmediatelyIfFound,
		}
		
		tinsert(self.AlphaHandlers, handler)
		
		sort(self.AlphaHandlers, self.HandlerSorter)
		
		if TMW.Classes.IconDataProcessor.ProcessorsByName[processorName] then
			self.SetupHandler(handler)
		else
			TMW:RegisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", self.SetupHandler, handler)
		end
		
	end,	
}





-- [INTERNAL] (no documentation needed)
local InheritAllFunc
function Icon.InheritDataFromIcon(iconDestination, iconSource)
	if not InheritAllFunc then
		local attributes = {}
		local attributesSplit = {}
	
		for _, Processor in pairs(TMW.Classes.IconDataProcessor.instances) do
			if not Processor.dontInherit then
				attributes[#attributes+1] = Processor.attributesStringNoSpaces
				for _, attribute in TMW:Vararg(strsplit(",", Processor.attributesStringNoSpaces)) do
					attributesSplit[#attributesSplit+1] = attribute
				end
			end
		end
		
		local t = {}
		t[#t+1] = "local iconDestination, iconSource = ..."
		t[#t+1] = "\n"
		t[#t+1] = "local attributes = iconSource.attributes"
		t[#t+1] = "\n"
		t[#t+1] = "iconDestination:SetInfo('"
		t[#t+1] = table.concat(attributes, "; ")
		t[#t+1] = "', "
		t[#t+1] = "attributes."
		t[#t+1] = table.concat(attributesSplit, ", attributes.")
		t[#t+1] = ")"
		
		local funcstr = table.concat(t)
		
		InheritAllFunc = assert(loadstring(funcstr))
	end
	
	InheritAllFunc(iconDestination, iconSource)
end

local function SetInfo_GenerateFunction(signature, isInternal)
	local originalSignature = signature
	
	signature = signature:gsub(" ", "")
	
	local t = {} -- taking a page from DogTag's book on compiling functions
	
	-- Declare all upvalues
	for UVSetID, UVSet in ipairs(TMW.Classes.IconDataProcessor.SIUVs) do
		t[#t+1] = "local "
		t[#t+1] = UVSet.variables
		t[#t+1] = " = "
		for referenceID, reference in ipairs(UVSet) do
			t[#t+1] = "TMW.Classes.IconDataProcessor.SIUVs["
			t[#t+1] = UVSetID
			t[#t+1] = "]["
			t[#t+1] = referenceID
			t[#t+1] = "]"
			t[#t+1] = ", "
		end
		t[#t] = nil -- remove the final ", " (if there were any references) or the " = " (if there weren't)
		t[#t+1] = "\n"
	end
		
	t[#t+1] = "\n"
	
	t[#t+1] = "\n"
	t[#t+1] = "return function(icon, "
	t[#t+1] = originalSignature:trim(" ,;"):gsub("  ", " "):gsub(";", ",")
	t[#t+1] = ")"
	t[#t+1] = "\n\n"
	t[#t+1] = [[
		local attributes, EventHandlersSet = icon.attributes, icon.EventHandlersSet
		local doFireIconUpdated
	]]
	
	while #signature > 0 do
		local match
		for _, Processor in ipairs(TMW.Classes.IconDataProcessor.instances) do
		
			match = signature:match("^(" .. Processor.attributesStringNoSpaces .. ")$") -- The attribute string is the only one in the signature
				 or	signature:match("^(" .. Processor.attributesStringNoSpaces .. ";)") -- The attribute string is the first one in the signature
				 or	signature:match("(;" .. Processor.attributesStringNoSpaces .. ")$") -- The attribute string is the last one in the signature
				 or	signature:match(";(" .. Processor.attributesStringNoSpaces .. ";)") -- The attribute string is in the middle of the signature
				 
			if match then
				t[#t+1] = "local Processor = "
				t[#t+1] = Processor.name
				t[#t+1] = "\n"
				
				-- Process any hooks that should go before the main function segment
				Processor:CompileFunctionHooks(t, "pre")
				
				Processor:CompileFunctionSegment(t)
				
				-- Process any hooks that should go after the main function segment
				Processor:CompileFunctionHooks(t, "post")
				
				t[#t+1] = "\n\n"  
				
				signature = signature:gsub(match, "", 1)
				
				break
			end
		end
		if not match then
			error(("Couldn't find a signature match for the beginning of signature %q from %q"):format(signature, originalSignature), 4)
		end
	end
	
	if isInternal then
		t[#t+1] = [[
			return doFireIconUpdated
		end -- "return function(icon, ...)"
		]]
	else
		t[#t+1] = [[
			if doFireIconUpdated then
				TMW:Fire("TMW_ICON_UPDATED", icon)
			end
		end -- "return function(icon, ...)"
		]]
	end
	
	local funcstr = table.concat(t)
	if TMW.debug then
		funcstr = TMW.debug.enumLines(funcstr)
		TMW.debug.SetInfoFuncsToFuncStrs[tostring(isInternal) .. originalSignature] = funcstr
	end
	local func = assert(loadstring(funcstr, "SetInfo " .. originalSignature))()
	
	return func
end

local SetInfoFuncs = setmetatable({}, { __index = function(self, signature)
	-- Check and see if we already made a function for this signature, just with different spacing.
	local signature_no_spaces = signature:gsub(" ", "")
	if rawget(self, signature_no_spaces) then
		local func = self[signature_no_spaces]
		
		-- If there was a function, cache it for the original signature also so that we don't go through this lookup process every time.
		self[signature] = func
		return func
	end
	
	local func = SetInfo_GenerateFunction(signature, nil)
	
	self[signature] = func
	self[signature:gsub(" ", "")] = func
	
	return func
end})


function Icon.SetInfo(icon, signature, ...)
	SetInfoFuncs[signature](icon, ...)
end

local SetInfoInternalFuncs = setmetatable({}, { __index = function(self, signature)
	-- Check and see if we already made a function for this signature, just with different spacing.
	local signature_no_spaces = signature:gsub(" ", "")
	if rawget(self, signature_no_spaces) then
		local func = self[signature_no_spaces]
		
		-- If there was a function, cache it for the original signature also so that we don't go through this lookup process every time.
		self[signature] = func
		return func
	end
	
	local func = SetInfo_GenerateFunction(signature, true)
	
	self[signature] = func
	self[signature:gsub(" ", "")] = func
	
	return func
end})
-- SetInfo_INTERNAL doesn't fire TMW_ICON_UPDATED because it is always called from within SetInfo (inside IconDataProcessorHooks).
-- SetInfo will fire it at the end (and only once, isntead of multiple times), so SetInfo_INTERNAL shouldn't fire it.
-- It returns doFireIconUpdated, which should be handled as needed if SetInfo_INTERNAL is being called inside a hook.
-- It can (and should, obviously) be ignored if being called from the changedEvent of an IconDataProcessor.
function Icon.SetInfo_INTERNAL(icon, signature, ...)
	SetInfoInternalFuncs[signature](icon, ...)
end

-- [INTERNAL] (no documentation needed)
function Icon:ClearSetInfoFunctionCache()
	self:AssertSelfIsClass()
	
	wipe(SetInfoFuncs)
	wipe(SetInfoInternalFuncs)
	InheritAllFunc = nil
end


