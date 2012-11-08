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


local IconView = TMW:NewClass("IconView", "GroupComponent", "IconComponent")
IconView.ModuleImplementors = {}

function IconView:OnNewInstance(view)
	self.view = view
	self.name = view
	
	TMW.Icon_Defaults.SettingsPerView[view] = {}
	self.IconDefaultsPerView = TMW.Icon_Defaults.SettingsPerView[view]
	self:InheritTable(self.class, "ModuleImplementors")
end

function IconView:Register(order)
	TMW:ValidateType("2 (order)", "IconView:Register(order)", order, "number")

	local viewkey = self.view
	
	self.order = order

	if TMW.debug and rawget(TMW.Views, viewkey) then
		-- for tweaking and recreating icon views inside of WowLua so that I don't have to change the viewkey every time.
		viewkey = viewkey .. " - " .. date("%X")
		self.name = viewkey
	end

	TMW.Views[viewkey] = self -- put it in the main Views table
	tinsert(TMW.OrderedViews, self)
	TMW:SortOrderedTables(TMW.OrderedViews)

	TMW:Fire("TMW_VIEW_REGISTERED", self)
	
	return self -- why not?
end


local function DefaultImplementorFunc(Module)
	Module:Enable()
end

function IconView:ImplementsModule(module, order, implementorFunc)
	TMW:ValidateType(2, "IconView:ImplementsModule()", module, "string")
	TMW:ValidateType(3, "IconView:ImplementsModule()", order, "number")
	
	if implementorFunc == true then
		implementorFunc = DefaultImplementorFunc
	end
	
	self.ModuleImplementors[#self.ModuleImplementors+1] = {
		order = order,
		moduleName = module,
		implementorFunc = implementorFunc,
	}
	
	TMW:SortOrderedTables(self.ModuleImplementors)
end

function IconView:DoesImplementModule(moduleName)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		if moduleName == implementationData.moduleName then
			return implementationData.implementorFunc ~= false
		end
	end
	
	return false
end


function IconView:OnImplementIntoIcon(icon)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		local implementorFunc = implementationData.implementorFunc
		
		-- implementorFunc is:
			-- nil if no function is defined, but the module should still implement
			-- function that should be called when the midle is implement (Module.OnImplementIntoIcon handles the calling)
			-- false if the module should not implement.
		
		-- Get the class of the module that we might be implementing.
		local ModuleClass = moduleName:find("IconModule") and TMW.Classes[moduleName]
			
		-- If the class exists and the module should be implemented, then proceed to check Processor requirements.
		if implementorFunc ~= false and ModuleClass then
		
			-- Check to see if an instance of the Module already exists for the icon before creating one.
			local Module = icon.Modules[moduleName]
			if not Module then
				Module = ModuleClass:New(icon)
			end
			
			Module.implementationData = implementationData
			
			-- Implement the module into the icon.
			Module:ImplementIntoIcon(icon)
		end
	end
end

function IconView:OnUnimplementFromIcon(icon)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		
		-- Make sure that the module is a IconModule
		local Module = moduleName:find("IconModule") and icon.Modules[moduleName]
		
		if Module then
			Module:UnimplementFromIcon(icon)
			Module.implementationData = nil
		end
	end
end


function IconView:OnImplementIntoGroup(group)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		local implementorFunc = implementationData.implementorFunc
		
		-- implementorFunc is:
			-- nil if no function is defined, but the module should still implement
			-- function that should be called when the midle is implement (Module.OnImplementIntoIcon handles the calling)
			-- false if the module should not implement.
		
		-- Get the class of the module that we might be implementing.
		local ModuleClass = moduleName:find("GroupModule") and TMW.Classes[moduleName]
		
		-- If the class exists and the module should be implemented, then do it.
		if implementorFunc and ModuleClass then
		
			-- Check to see if an instance of the Module already exists for the group before creating one.
			local Module = group.Modules[moduleName]
			if not Module then
				Module = ModuleClass:New(group)
			end
			
			Module.implementationData = implementationData
			
			-- Implement the Module into the group
			Module:ImplementIntoGroup(group)
		end
	end
end

function IconView:OnUnimplementFromGroup(group)
	for i, implementationData in ipairs(self.ModuleImplementors) do
		local moduleName = implementationData.moduleName
		
		-- Make sure that the module is a GroupModule		
		local Module = moduleName:find("GroupModule") and group.Modules[moduleName]
		
		if Module then
			Module:UnimplementFromGroup(group)
			Module.implementationData = nil
		end
	end
end


-- Default modules
IconView:ImplementsModule("GroupModule_GroupPosition", 1, true)

IconView:ImplementsModule("IconModule_IconEventClickHandler", 2, true)
IconView:ImplementsModule("IconModule_IconEventOtherShowHideHandler", 2.5, true)
IconView:ImplementsModule("IconModule_IconEventConditionHandler", 2.7, true)
IconView:ImplementsModule("IconModule_RecieveSpellDrags", 3, true)
IconView:ImplementsModule("IconModule_IconDragger", 4, true)
IconView:ImplementsModule("IconModule_GroupMover", 5, true)
IconView:ImplementsModule("IconModule_Tooltip", 6, true)
IconView:ImplementsModule("IconModule_IconEditorLoader", 7, true)

