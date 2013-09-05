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

local pairs, ipairs, type, error, tostring, setmetatable, getmetatable, rawset, rawget, pcall
	= pairs, ipairs, type, error, tostring, setmetatable, getmetatable, rawset, rawget, pcall

--- The table that holds all TellMeWhen classes. Classes are keyed in this table by their name.
TMW.Classes = {}

local metamethods = {
	__add = true,
	__call = true,
	__concat = true,
	__div = true,
	__le = true,
	__lt = true,
	__mod = true,
	__mul = true,
	__pow = true,
	__sub = true,
	__tostring = true,
	__unm = true,
}

local function callFunc(class, instance, func, ...)

	-- check for all functions that dont match exactly, like OnNewInstance_1, _foo, _bar, ...
	for k, v in pairs(class.instancemeta.__index) do
		if type(k) == "string" and k:find("^" .. func) and k ~= func then
			TMW.safecall(v, instance, ...)
		end
	end
	
	if instance.isTMWClassInstance then
		-- If this is being called on an instance of a class instead of a class,
		-- search the instance itself for matching functions too.
		-- This will never step on the toes of class.instancemeta.__index because
		-- iterating over an instance will only yield things explicity set on an instance -
		-- it will never directly contain anything inherited from a class.
		for k, v in pairs(instance) do
			if type(k) == "string" and k:find("^" .. func) and k ~= func then
				TMW.safecall(v, instance, ...)
			end
		end
	end
	
	
	-- now check for the function that exactly matches. this should be called last because
	-- it should be the function that handles the real class being instantiated, not any inherited classes
	local normalFunc = instance[func]
	if normalFunc then
		TMW.safecall(normalFunc, instance, ...)
	end
end

local function initializeClass(self)
	if not self.initialized then
		-- set any defined metamethods
		for k, v in pairs(self.instancemeta.__index) do
			if metamethods[k] then
				self.instancemeta[k] = v
			end
		end
		
		self:CallFunc("OnFirstInstance")

		self.initialized = true
	end
end

local __call = function(self, arg)
	-- allow something like TMW:NewClass("Name"){Foo = function() end, Bar = 5}
	if type(arg) == "table" then
		for k, v in pairs(arg) do
			if k == "METHOD_EXTENSIONS" and type(v) == "table" then
				for methodName, func in pairs(v) do
					self:ExtendMethod(methodName, func)
				end
			else
				self[k] = v
			end
		end
	end
	return self
end

local weakMetatable = {
	__mode = "kv"
}

local inherit = function(self, source)		
	if source then
		local metatable = getmetatable(self)
		
		local index, didInherit
		
		-- TMW class inheritance (passed in class name)
		if TMW.Classes[source] then
			TMW.Classes[source]:CallFunc("OnClassInherit", self)
			
			index = getmetatable(TMW.Classes[source]).__index
			didInherit = true
		
		elseif type(source) == "table" then

			-- TMW class inheritance (passed in class table)
			if source.isTMWClass and TMW.Classes[source.className] then
				source:CallFunc("OnClassInherit", self)
				
				index = getmetatable(source).__index
				didInherit = true

			else
				-- Table inheritance
				index = source
				didInherit = true
			end
		else
		
			-- Blizzard widget inheritance
			local success, frame = pcall(CreateFrame, source)
			if success and frame then
				-- Need to do hide the frame or else if we made an editbox,
				-- it will block all keyboard input for some reason
				frame:Hide()

				self.isFrameObject = source or self.isFrameObject
				rawset(self, "isFrameObject", rawget(self, "isFrameObject") or source)
				
				metatable.__index.isFrameObject = metatable.__index.isFrameObject or source
				
				index = getmetatable(frame).__index
				didInherit = true
			
			-- LibSub lib inheritance
			elseif LibStub(source, true) then
				local lib = LibStub(source, true)
				if lib.Embed then
					lib:Embed(metatable.__index)
					didInherit = true
				else
					TMW:Error("Library %q does not have an Embed method", source)
				end
			end
		end

		if not didInherit then
			error(("Could not figure out how to inherit %s into class %s. Are you sure it exists?"):format(source, self.className), 3)
		end
		
		if index then
			for k, source in pairs(index) do
				metatable.__index[k] = (metatable.__index[k] ~= nil and metatable.__index[k]) or source
			end
		end
	end
end

--- Creates a new class.
-- @param className [String] The name of the class to be created.
-- @param ... [...] A list of things to inherit from. Valid parameters include the following (and each will be checked in the following order):
-- * The name of another TellMeWhen class.
-- * A table whose values will be merged into the class.
-- * The name of a Blizzard widget (like Frame, Button, EditBox, etc.) The class created will inherit the methods of that widget type, and instances of the class will be based on a new frame of that widget type.
-- * The name of a LibStub library that has an :Embed() method (many Ace3 libs do).
-- 
-- When conflicts between members of different inherited things arise, previously inherited members will not be overwritten.
-- @return [Class] A new class that inherits from TMW.Classes.Class and all other requested inheritances.
function TMW:NewClass(className, ...)
	TMW:ValidateType(2, "TMW:NewClass()", className, "string")
	
	if TMW.Classes[className] then
		error("TMW: A class with name " .. className .. " already exists. You can't overwrite existing classes, so pick a different name", 2)
	end
	
	local metatable = {
		__index = {},
		__call = __call,
	}
	
	local class = {
		className = className,
		instances = {},
		inherits = {},
		inheritedBy = {},
		embeds = {},
		initialized = false,
		isTMWClass = true,
	}

	class.instancemeta = {__index = metatable.__index}
	
	setmetatable(class, metatable)
	metatable.__newindex = metatable.__index

	for n, v in TMW:Vararg(TMW.Classes.Class and "Class", ...) do
		--TMW.Warn(strconcat(tostringall(n, v, className, ...)))
	--	if v then
			inherit(class, v)
	---	end
	end

	TMW.Classes[className] = class
	
	--- This is a test of a random luadoc comment
	TMW:Fire("TMW_CLASS_NEW", class)

	return class
end





-- Define the base class. All other classes implicitly inherit from this class.
local Class = TMW:NewClass("Class")

--- Instantiates a class.
--
-- All class methods and members will be accessed via metamethods.
-- 
-- If the class inherits from a Blizzard widget, any class methods that are valid script handler names for the widget type (like "OnClick" or "OnShow") will be hooked as script handlers on the instance.
-- @param ... [...] The constructor parameters of the new instance. If the class being instantiated inherits from a Blizzard widget, these will be passed directly to CreateFrame(...). In all cases, they will be passed to calls of any class methods whose name **begins** with "OnNewInstance" (E.g. {{{Class:OnNewInstance_Class(self, ...)}}}).
-- @return A new instance of the class.
function Class:New(...)
	if self.isTMWClassInstance then
		self = self.class
	end
	
	local instance
	if self.isFrameObject then
		instance = CreateFrame(...)
	else
		instance = {}
	end

	-- if this is the first instance of the class, do some magic to it:
	initializeClass(self)

	instance.class = self
	instance.className = self.className
	instance.isTMWClassInstance = true

	setmetatable(instance, self.instancemeta)

	self.instances[#self.instances + 1] = instance
	
	for k, v in pairs(self.instancemeta.__index) do
		if self.isFrameObject and instance.HasScript and instance:HasScript(k) then
			instance:HookScript(k, v)
		end
	end

	instance:CallFunc("OnNewInstance", ...)
	
	TMW:Fire("TMW_CLASS_" .. self.className .. "_INSTANCE_NEW", self, instance)
	
	return instance
end



--- Embeds the class into an already existing table.
-- @param target [table] The table to embed the class into. Effectively turns the target into an instance of the class.
-- @param canOverwrite [boolean|nil] True to suppress the non-breaking errors that will be thrown when a member of the class already exists on the target (naming conflicts).
-- @param ... [...] The parameters that will be passed to the class's OnNewInstance methods (see Class:New(...)'s documentation for more info).
-- @return Returns the target that was passed in.
function Class:Embed(target, canOverwrite, ...)
	TMW:ValidateType("2 (target)", "Class:Embed(target, canOverwrite)", target, "table")
	
	-- if this is the first instance (not really an instance here, but we need to anyway) of the class, do some magic to it:
	initializeClass(self)

	self.embeds[target] = true

	for k, v in pairs(self.instancemeta.__index) do
		if target[k] and target[k] ~= v and not canOverwrite then
			TMW:Error("Error embedding class %s into target %s: Field %q already exists on the target.", self.className, tostring(target:GetName() or target), k)
		else
			target[k] = v
		end
	end
	
	for k, v in pairs(self.instancemeta.__index) do
		if self.isFrameObject and target.HasScript and target:HasScript(k) then
			target:HookScript(k, v)
		end
	end

	target.class = self
	target.className = self.className
	
	target:CallFunc("OnNewInstance", ...)
	
	return target
end

--- Disembeds the class from the target.
-- 
-- This is not always reliable if there were naming conflicts when the class was embedded or if the target has overwritten any of the class's members that were embedded.
-- Can only be used on a target that previously had Class:Embed() called on it.
-- @param target [table] The table to disembed the class from.
-- @param clearDifferentValues [boolean|nil] True to suppress the non-breaking errors that will be thrown if one of the class's members is missing from the target or has had its value changed.
-- @return Returns the target that was passed in.
function Class:Disembed(target, clearDifferentValues)
	TMW:ValidateType("2 (target)", "Class:Disembed(target, clearDifferentValues)", target, "table")
	
	if not self.embeds[target] then
		error("Class " .. self.className .. " is not embedded into the target!", 2)
	end
	
	self.embeds[target] = false

	for k, v in pairs(self.instancemeta.__index) do
		if (target[k] == v) or (target[k] and clearDifferentValues) then
			target[k] = nil
		else
			TMW:Error("Error disembedding class %s from target %s: Field %q should exist on the target, but it doesnt.", self.className, tostring(target:GetName() or target), k)
		end
	end

	return target
end



--- Extends the specified method so that it when called, it will first call the original method being extended, and then it will call newFunction.
-- 
-- Effectively functions as a post-hook.
-- 
-- If the requested method is not defined when this is called, newFunction will simply be set as that method with no hooking involved.
-- @param method [String] The name of the method on the class that should be extended.
-- @param newFunction [Function] The function that will be called after the original function is called.
function Class:ExtendMethod(method, newFunction)
	local existingFunction = self[method]
	if existingFunction then
		self[method] = function(...)
			existingFunction(...)
			newFunction(...)
		end
	else
		self[method] = newFunction
	end
end



--- Asserts that self is a TellMeWhen class.
-- 
-- Throws a breaking error if it is not.
function Class:AssertSelfIsClass()
	if not self.isTMWClass then
		error(("Caller must be the class %q, not an instance of the class"):format(self.className), 3)
	end
end

--- Asserts that self is an instance of a TellMeWhen class.
-- 
-- Throws a breaking error if it is not.
function Class:AssertSelfIsInstance()
	if not self.isTMWClassInstance then
		error(("Caller must be an instance of the class %q, not the class itself"):format(self.className), 3)
	end
end



--- Inherits the source into the class.
-- 
-- The source parameter must be one of the valid inheritance types documented in TMW:NewClass()'s documentation.
-- @param [String|Table] The source that should be inherited into the class.
-- @see TMW:NewClass()
function Class:Inherit(source)
	self:AssertSelfIsClass()

	inherit(self, source)
end

--- Copies the requested source table into the caller (caller can be a class or an instance of a class).
-- @param source [table] The parent of the table that will be copied.
-- @param tableKey [!nil] The key on the parent that holds the table that will be copied. The copied table will be placed into this variable on the caller as well.
-- @return [table] The copied table.
function Class:InheritTable(source, tableKey)
	TMW:ValidateType(2, "Class:InheritTable()", source, "table")
	TMW:ValidateType(3, "Class:InheritTable()", tableKey, "!nil")
	
	self[tableKey] = {}
	for k, v in pairs(source[tableKey]) do
		self[tableKey][k] = v
	end
	
	-- not needed to return the table, but helpful because
	-- sometimes i set a variable to the result by mistake,
	-- and if i forget that this doesnt work then i spend a long time debugging
	-- trying to figure out why a single attributes table
	-- is shared by all icons... yeah, i did that once.
	return self[tableKey]
end

--- Calls all the functions of a class that begin with funcName.
-- @param funcName [string] The beginning of the method name that must be matched in order for the method to be called.
-- @param ... The parameters that will be passed, after a reference to self, to the function(s) when they are called.
-- @usage -- Example usage from within the Class core on how this method is used.
-- -- It may be used externally, of course
-- 
-- -- Used to notify a class that the first instance of it has been created
-- -- so that it may preform any class-level initialization needed.
-- class:CallFunc("OnFirstInstance")
-- 
-- -- Another example:
-- -- Used when an instance of a class is created.
-- -- Functions as the instance constructor. See the How To page for more info.
-- instance:CallFunc("OnNewInstance", ...)
function Class:CallFunc(funcName, ...)
	if self.isTMWClass then
		callFunc(self, self, funcName, ...)
	else
		callFunc(self.class, self, funcName, ...)
	end
end


--- Sets the __mode of the instances table of the class to "kv" so that instances will be garbage collected when they are orphaned everywhere else.
-- This behavior will not be inherited by subclasses.
function Class:MakeInstancesWeak()
	setmetatable(self.instances, weakMetatable)
end



-- [INTERNAL]
function Class:OnClassInherit_Class(newClass)
	for class in pairs(self.inherits) do
		newClass.inherits[class] = true
		class.inheritedBy[newClass] = true
	end
	
	newClass.inherits[self] = true
	self.inheritedBy[newClass] = true
end




