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

local GetSpellInfo, GetSpellLink, GetSpellBookItemInfo, GetSpellBookItemName
	= GetSpellInfo, GetSpellLink, GetSpellBookItemInfo, GetSpellBookItemName
local pairs, ipairs, setmetatable, rawget, date, tinsert, type
	= pairs, ipairs, setmetatable, rawget, date, tinsert, type
	

local SpellTextures = TMW.SpellTextures
local tContains = TMW.tContains
local tDeleteItem = TMW.tDeleteItem

local RelevantToAll = {
	__index = {
		SettingsPerView = true,
		Enabled = true,
		Name = true,
		Type = true,
		Events = true,
		Conditions = true,
		UnitConditions = true,
		ShowWhen = true,
		Alpha = true,
		UnAlpha = true,
	}
}



--- [[api/icon-type/api-documentation/|IconType]] is the class of all Icon Types.
-- 
-- IconType inherits explicitly from [[api/base-classes/icon-component/|IconComponent]], and implicitly from the classes that they inherit. 
-- 
-- Icon Types take data from the WoW API, filter and manipulate it, and then pass it on to one or more [[api/icon-data-processor/api-documentation/|IconDataProcessor]] through the icon:SetInfo method. The default Icon Type (also used as the fallback when a requested IconView cannot be found) is identified by a blank string (""). To create a new IconType, make a new instance of the IconType class.
-- 
-- Instructions on how to use this API can be found at [[api/icon-type/how-to-use/]]
-- 
-- @class file
-- @name IconType.lua


--- The fields avaiable to instances of TMW.Classes.IconType. TMW.Classes.IconType inherits from TMW.Classes.IconComponent.
-- @class table
-- @name TMW.Classes.IconType
-- @field name [function->|string] A localized string that names the IconType throughout TMW.
-- @field desc [function->|string|nil] A localized string that describes the IconType throughout TMW.
-- @field tooltipTitle [function->|string|nil] A localized string that will be used as the title of the description tooltip for the IconType. Defaults to IconType.name.
-- @field menuIcon [function->|string|nil] Path to the texture that will be displayed in the type selection menu.
-- @field spacebefore [boolean|nil] True if there should be an empty row displayed before this IconType in the type selection menu.
-- @field spaceafter [boolean|nil] True if there should be an empty row displayed after this IconType in the type selection menu.
-- @field hidden [function->|boolean|nil] True if the IconType should not be displayed in the type selection menu.

-- @field Icons [table] Array of icons that use this IconType. Automatically updated, and should not be modified.
-- @field type [string] A short string that will identify the IconType across the addon. Set through the constructor, and should not be modified.
-- @field order [number] A number that determines the display order of the IconType in configuration UIs. Set through IconType:Register and should not be modified.

local IconType = TMW:NewClass("IconType", "IconComponent")
IconType.UsedAttributes = {}

--- Constructor - Creates a new IconType
-- @name IconType:New
-- @param type [string] A short string that will identify the IconType across the addon.
-- @return [TMW.Classes.IconType] A new IconType instance.
-- @usage IconType = TMW.Classes.IconType:New("cooldown")
function IconType:OnNewInstance(type)
	self.type = type
	self.Icons = {}
	self.UsedProcessors = {}
	self.Colors = {}
	
	self:InheritTable(self.class, "UsedAttributes")
end

-- [INTERNAL] - Updates self.Colors to the current settings in TMW.db.profile.Colors
function IconType:UpdateColors(dontSetupIcons)
	self:AssertSelfIsInstance()
	
	for k, v in pairs(TMW.db.profile.Colors[self.type]) do
		if v.Override then
			self.Colors[k] = v
		else
			self.Colors[k] = TMW.db.profile.Colors.GLOBAL[k]
		end
	end
	
	if not dontSetupIcons then
		self:SetupIcons()
	end
end

--- Performs TMW.Classes.Icon:Setup() on all icons that use this icon type.
function IconType:SetupIcons()
	self:AssertSelfIsInstance()
	
	for i = 1, #self.Icons do
		self.Icons[i]:Setup()
	end
end

-- [REQUIRED, FALLBACK]
--- Formats a spell, as passed to {{{icon:SetInfo("spell", spell)}}}, for human-readable output. This is a base method written for handling spells. It should be overridden for IconTypes that don't take spell input for their ics.Name setting.
-- @param icon [TMW.Classes.Icon] The icon that the spell is being formatted for.
-- @param data [.*] The data that needs to be formatted, as it was passed to {{{icon:SetInfo("spell", data)}}}.
-- @param doInsertLink [boolean] Whether or not a [[http://wowprogramming.com/docs/api_types#hyperlink|clickable link]] should be returned.
-- @return [string] The formatted data. suitable for human-readable output.
-- @return [boolean|nil] True if the formatted data might not have proper capitalization (caller will attempt to correct capitalization if this is true).
-- @usage -- This method should only be called internally by TellMeWhen and some of its components.
-- texture = TMW.Types.cooldown:FormatSpellForOutput(icon, icon.attributes.spell, true)
function IconType:FormatSpellForOutput(icon, data, doInsertLink)
	self:AssertSelfIsInstance()
	
	if data then
		local name
		if doInsertLink then
			name = GetSpellLink(data)
		else
			name = GetSpellInfo(data)
		end
		if name then
			return name
		end
	end
	
	return data, true
end

-- [REQUIRED, FALLBACK]
--- Attempts to figure out what the configuration texture of an icon will be without actually creating the icon. This is a base method written for handling spells. It should be overridden for IconTypes that don't take spell input for their ics.Name setting. It is acceptable to delay the declaration of overrides of this method until after TellMeWhen_Options has loaded if needed.
-- @param ics [TMW.Icon_Defaults] The settings of the icon that the texture is being guessed for.
-- @return [string] The guessed texture of the icon. 
-- @usage -- This method should only be called internally by TellMeWhen and some of its components. 
-- texture = TMW.Types[ics.Type]:GuessIconTexture(ics)
function IconType:GuessIconTexture(ics)
	self:AssertSelfIsInstance()
	
	if ics.Name and ics.Name ~= "" then
		local name = TMW:GetSpellNames(nil, ics.Name, 1)
		if name then
			return SpellTextures[name]
		end
	end
end



-- [FALLBACK]
--- Gets the icon texture that will be used for the icon in configuration mode. This is a base method written for handling spells. It should be overridden for IconTypes that don't take spell input for their ics.Name setting. It is acceptable to delay the declaration of overrides of this method until after TellMeWhen_Options has loaded if needed.
-- @param icon [TMW.Classes.Icon] The icon to get the config mode texture for.
-- @return [string] The texture path of the texture to use.
-- @usage icon:SetInfo("texture", Type:GetConfigIconTexture(icon))
function IconType:GetConfigIconTexture(icon)
	if icon.Name == "" and not self.AllowNoName then
		return "Interface\\Icons\\INV_Misc_QuestionMark", nil
	else
	
		if icon.Name ~= "" then
			local tbl = TMW:GetSpellNames(icon, icon.Name)

			for _, name in ipairs(tbl) do
				local t = SpellTextures[name]
				if t then
					return t, true
				end
			end
		end
		
		if self.usePocketWatch then
			if icon:IsBeingEdited() == "MAIN" then
				TMW.HELP:Show("ICON_POCKETWATCH_FIRSTSEE", nil, TMW.IE.icontexture, 0, 0, L["HELP_POCKETWATCH"])
			end
			return "Interface\\Icons\\INV_Misc_PocketWatch_01", false
		else
			return "Interface\\Icons\\INV_Misc_QuestionMark", false
		end
	end
end


-- [REQUIRED, FALLBACK]
--- Handles dragging spells, items, and other things onto an icon. This is a base method written for handling spells. It should be overridden for IconTypes that don't take spell input for their ics.Name setting. It is acceptable to delay the declaration of overrides of this method until after TellMeWhen_Options has loaded if needed.
-- @paramsig icon, ...
-- @param icon [TMW.Classes.Icon] The icon that the dragged data was released onto.
-- @param ... [...] The return values from [[http://wowprogramming.com/docs/api/GetCursorInfo|GetCursorInfo()]]. Don't call GetCursorInfo yourself in your definition, because TMW will pass in its own data in special cases that can't be obtained from GetCursorInfo.
-- @return [boolean|nil] Should return true if data from the drag was succesfully added to the icon, otherwise nil.
function IconType:DragReceived(icon, t, data, subType, param4)
	self:AssertSelfIsInstance()
	
	local ics = icon:GetSettings()

	if t ~= "spell" then
		return
	end

	local input
	if data == 0 and type(param4) == "number" then
		-- I don't remember the purpose of this anymore.
		-- It handles some special sort of spell, though, and is required.
		input = GetSpellInfo(param4)
	else
		local type, baseSpellID = GetSpellBookItemInfo(data, subType)
		
		if not baseSpellID or type ~= "SPELL" then
			return
		end
		
		
		local currentSpellName = GetSpellBookItemName(data, subType)		
		local baseSpellName = GetSpellInfo(baseSpellID)
		
		input = baseSpellName or currentSpellName
	end

	ics.Name = TMW:CleanString(ics.Name .. ";" .. input)
	return true -- signal success
end

-- [REQUIRED, FALLBACK]
--- Returns brief information about what an icon is configured to track. Used mainly in import/export menus. This is a default method, and may be overridden if it does not provide the desired functionality for an IconType. It is acceptable to delay the declaration of overrides of this method until after TellMeWhen_Options has loaded if needed.
-- @param ics [TMW.Icon_Defaults] The settings of the icon that information is being requested about.
-- @param groupID [number] The ID of the group of the icon that information is being requested for. Does not necessarily correlate to an icon that exists in the currently active profile.
-- @param iconID [number] The ID of the icon that information is being requested for. Does not necessarily correlate to an icon that exists in the currently active profile.
-- @return [string] The title text that can be displayed in a tooltip.
-- @return [string] The body text that can be displayed in a tooltip.
function IconType:GetIconMenuText(ics, groupID, iconID)
	self:AssertSelfIsInstance()
	
	local text = ics.Name or ""
	local tooltip =	""

	return text, tooltip
end

--- Register the IconType for use in TellMeWhen. IconViews cannot be used or accessed until this method is called. Should be the very last line of code in the file that defines an IconType.
-- @param order [number] The order of this IconType relative to other IconTypes in configuration UI.
-- @return self [TMW.Classes.IconType] The IconType this method was called on.
-- @usage IconType:Register(10)
function IconType:Register(order)
	self:AssertSelfIsInstance()
	
	TMW:ValidateType("IconType.name", "IconType:Register(order)", self.name, "function;string")
	TMW:ValidateType("IconType.desc", "IconType:Register(order)", self.desc, "function;string;nil")
	TMW:ValidateType("IconType.tooltipTitle", "IconType:Register(order)", self.tooltipTitle, "function;string;nil")
	TMW:ValidateType("IconType.menuIcon", "IconType:Register(order)", self.menuIcon, "function;string;nil")
	TMW:ValidateType("IconType.spacebefore", "IconType:Register(order)", self.spacebefore, "boolean;nil")
	TMW:ValidateType("IconType.spaceafter", "IconType:Register(order)", self.spaceafter, "boolean;nil")
	TMW:ValidateType("IconType.hidden", "IconType:Register(order)", self.spaceafter, "function;boolean;nil")
	
	TMW:ValidateType("2 (order)", "IconType:Register(order)", order, "number")
	
	local typekey = self.type
	
	self.order = order
	
	self.RelevantSettings = self.RelevantSettings or {}
	setmetatable(self.RelevantSettings, RelevantToAll)

	if TMW.debug and rawget(TMW.Types, typekey) then
		-- for tweaking and recreating icon types inside of WowLua so that I don't have to change the typekey every time.
		typekey = typekey .. " - " .. date("%X")
		self.name = typekey
		self.type = typekey
	end

	TMW.Types[typekey] = self -- put it in the main Types table
	tinsert(TMW.OrderedTypes, self) -- put it in the ordered table (used to order the type selection dropdown in the icon editor)
	TMW:SortOrderedTables(TMW.OrderedTypes)
	
	-- Try to find processors for the attributes declared for the icon type.
	-- It should find most since default processors are loaded before icon types.
	self:UpdateUsedProcessors()
	
	-- Listen for any new processors, too, and update when they are created.
	TMW:RegisterCallback("TMW_CLASS_IconDataProcessor_INSTANCE_NEW", self, "UpdateUsedProcessors")
	
	-- Covers the case of creating a type after login
	-- (mainly used while debugging). Calling UpdateColors here prevents 
	-- errors when types are created without performing a full TMW:Update() immediately afterwords.
	if TMW.InitializedDatabase then
		self:UpdateColors(true)
	end
	
	return self -- why not?
end

local doneImplementingDefaults
--- Declare that an IconType uses a specified attributesString.
-- @param attributesString [string] The attributesString whose usage state is being set. (an attributesString is passed as a segment of the first arg to {{{icon:SetInfo(attributesStrings, ...)}}}, and also as the second arg to the constructor of a TMW.Classes.IconDataProcessor).
-- @param uses [boolean|nil] False if the IconType does NOT use the specified attributesString. True or nil if it does use the attributesString.
-- @usage IconType:UsesAttributes("start, duration")
-- IconType:UsesAttributes("conditionFailed", false)
function IconType:UsesAttributes(attributesString, uses)
	if doneImplementingDefaults then
		self:AssertSelfIsInstance()
	end
	
	TMW:ValidateType("3 (uses)", "IconView:Register(attributesString, uses)", uses, "boolean;nil")
	
	if uses == false then
		self.UsedAttributes[attributesString] = nil
	else
		self.UsedAttributes[attributesString] = true
	end
end

-- [INTERNAL]
function IconType:UpdateUsedProcessors()
	self:AssertSelfIsInstance()
	
	for _, Processor in ipairs(TMW.Classes.IconDataProcessor.instances) do
		if self.UsedAttributes[Processor.attributesString] then
			self.UsedAttributes[Processor.attributesString] = nil
			self.UsedProcessors[Processor] = true
		end
	end
end

-- [INTERNAL]
function IconType:OnImplementIntoIcon(icon)	
	self.Icons[#self.Icons + 1] = icon

	-- Implement all of the Processors that the Icon Type uses into the icon.
	for Processor in pairs(self.UsedProcessors) do
		Processor:ImplementIntoIcon(icon)
	end
	
	
	-- ProcessorHook:ImplementIntoIcon() needs to happen in a separate loop, 
	-- and not as a method extension of Processor:ImplementIntoIcon(),
	-- because ProcessorHooks need to check and see if the icon is implementing
	-- all of the Processors that the hook has required for the hook to implement itself.
	-- If this were to happen in the first loop here, then it would frequently fail because
	-- dependencies might not be implemented before the hook would get implemented.
	for Processor in pairs(self.UsedProcessors) do
		for _, ProcessorHook in ipairs(Processor.hooks) do
		
			-- Assume that we have found all of the Processors that we need until we can't find one.
			local foundAllProcessors = true
			
			-- Loop over all Processor requirements for this ProcessorHook
			for processorRequirementName in pairs(ProcessorHook.processorRequirements) do
				-- Get the actual Processor instance
				local Processor = TMW.Classes.IconDataProcessor.ProcessorsByName[processorRequirementName]
				
				-- If the Processor doesn't exist or the icon doesn't implement it,
				-- fail the test and break the loop.
				if not Processor or not tContains(icon.Components, Processor) then
					foundAllProcessors = false
					break
				end
			end
			
			-- Everything checked out, so implement it into the icon.
			if foundAllProcessors then
				ProcessorHook:ImplementIntoIcon(icon)
			end
		end
	end
end

-- [INTERNAL]
function IconType:OnUnimplementFromIcon(icon)
	tDeleteItem(self.Icons, icon)
	
	-- Unimplement all of the Processors that the Icon Type uses from the icon.
	for Processor in pairs(self.UsedProcessors) do
	
		-- ProcessorHooks are fine being unimplemented in the same loop since there
		-- is no verification or anything like there is when imeplementing them
		for _, ProcessorHook in ipairs(Processor.hooks) do
			ProcessorHook:UnimplementFromIcon(icon)
		end
		
		Processor:UnimplementFromIcon(icon)
	end
end

--- Sets whether a certain IconModule can be implemented into an icon when the IconType is used by the icon.
-- @param moduleName [string] A string that identifies the module.
-- @param allow [boolean] True if the module should be allowed to implement when the IconType is used by the icon. Otherwise false. Cannot be nil.
-- @usage Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)
function IconType:SetModuleAllowance(moduleName, allow)
	local IconModule = TMW.Classes[moduleName]
	
	if IconModule and IconModule.SetAllowanceForType then
		IconModule:SetAllowanceForType(self.type, allow)
	elseif not IconModule then
		TMW:RegisterCallback("TMW_CLASS_NEW", function(event, class)
			if class.className == moduleName and class.SetAllowanceForType then
				local IconModule = class
				IconModule:SetAllowanceForType(self.type, allow)
			end
		end)
	end
end

IconType:RegisterIconEvent(111, "OnEventsRestored", {
	text = L["SOUND_EVENT_ONEVENTSRESTORED"],
	desc = L["SOUND_EVENT_ONEVENTSRESTORED_DESC"],
})

IconType:UsesAttributes("alpha")
IconType:UsesAttributes("alphaOverride")
IconType:UsesAttributes("realAlpha") -- this is implied by the mere existance of IconAlphaManager
IconType:UsesAttributes("conditionFailed")

doneImplementingDefaults = true