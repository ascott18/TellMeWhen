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

local pairs = pairs


--- {{{TMW.Classes.ObjectModule}}} is a base class of any objects that will be implemented into a {{{TMW.Classes.GenericModuleImplementor}}}. A {{{TMW.Classes.ObjectModule}}} provides frames, script handling, and other functionality to a {{{TMW.Classes.GenericModuleImplementor}}}. 
--
-- ObjectModule provides a common base for these objects, and it provides methods for enabling, disabling, and modifying script handlers. It is an abstract class, and should not be directly instantiated. All classes that inherit from {{{TMW.Classes.ObjectModule}}} should not be instantiated outside of the internal code used by a {{{TMW.Classes.IconView}}}. To create a new module, create a new class and inherit {{{TMW.Classes.ObjectModule}}} or another class that directly or indirectly inherits from {{{TMW.Classes.ObjectModule}}}.
--
-- @class file
-- @name ObjectModule.lua


local ObjectModule = TMW:NewClass("ObjectModule")
ObjectModule.ScriptHandlers = {}


function ObjectModule:OnNewInstance_ObjectModule(parent)
	local className = self.className
	
	for script, func in pairs(self.ScriptHandlers) do
		parent:HookScript(script, function(parent, ...)
			local Module = parent.Modules[className]
			if Module and Module.IsEnabled then
				func(Module, parent, ...)
			end
		end)
	end
end

function ObjectModule:OnClassInherit_ObjectModule(newClass)
	newClass.NumberEnabled = 0
	
	newClass:InheritTable(self, "ScriptHandlers")
end

--- Enables an instance of a {{{TMW.Classes.ObjectModule}}}.
function ObjectModule:Enable()
	self:AssertSelfIsInstance()
	
	if not self.IsEnabled then
		self.IsEnabled = true
		self.class.NumberEnabled = self.class.NumberEnabled + 1
		if self.class.NumberEnabled == 1 and self.class.OnUsed then
			TMW.safecall(self.class.OnUsed, self.class)
		end
		
		if self.OnEnable then
			TMW.safecall(self.OnEnable, self)
		end
	end
end

--- Disables an instance of a {{{TMW.Classes.ObjectModule}}}.
function ObjectModule:Disable()
	self:AssertSelfIsInstance()
	
	if self.IsEnabled then
		self.IsEnabled = false
		self.class.NumberEnabled = self.class.NumberEnabled - 1
		if self.class.NumberEnabled == 0 and self.class.OnUnused then
			TMW.safecall(self.class.OnUnused, self.class)
		end
		
		if self.OnDisable then
			TMW.safecall(self.OnDisable, self)
		end
	end
end

--- Sets a script handler that interacts with any {{{TMW.Classes.GenericModuleImplementor}}} that have implemented an instance of this {{{TMW.Classes.ObjectModule}}}. This script handler will only be active when {{{TMW.Classes.ObjectModule.IsEnabled == true}}}. This method must be called on a class - you cannot set the script handler separately for individual instances of {{{TMW.Classes.ObjectModule}}}.
function ObjectModule:SetScriptHandler(script, func)
	self:AssertSelfIsClass()
	
	TMW:ValidateType(2, "Module:SetScriptHandler()", script, "string")
	
	self.ScriptHandlers[script] = func
end


--- Provides a wrapper around {{{TMW.Class.IconView}}}{{{:ImplementsModule()}}} that allows you to implement modules into a {{{TMW.Classes.IconView}}} without having direct access to it.
-- @param viewName [string] The identifier of a {{{TMW.Class.IconView}}} as passed to the first param of {{{TMW.Class.IconView}}}'s constructor.
-- @param order [number] The order that this module should be implemented in, relative to other modules of the same kind (icon or group) implemented by the specified {{{TMW.Classes.IconView}}}. 
-- @param implementorFunc [function|boolean|nil] See {{{TMW.Classes.IconView}}}'s documentation for a description of this param.
-- @see http://wow.curseforge.com/addons/tellmewhen/pages/api/icon-views/api-documentation/#w-icon-view-implements-module-module-name-order-implementor
function ObjectModule:SetImplementorForView(viewName, order, implementorFunc)
	self:AssertSelfIsClass()
	
	local IconView = TMW.Views[viewName]
	local moduleName = self.className
	
	if IconView then
		IconView:ImplementsModule(moduleName, order, implementorFunc)
	else
		TMW:RegisterCallback("TMW_VIEW_REGISTERED", function(event, IconView)
			if IconView.view == viewName then
				IconView:ImplementsModule(moduleName, order, implementorFunc)
			end
		end)
	end
end
