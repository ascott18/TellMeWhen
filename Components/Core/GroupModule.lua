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

local type
	= type

--- {{{TMW.Classes.GroupModule}}} is a base class of any modules that will be implemented into a {{{TMW.Classes.Group}}}. A {{{TMW.Classes.GroupModule}}} provides frames, script handling, and other functionality to classes that inherit from it.
--
-- {{{TMW.Classes.GroupModule}}} inherits from {{{TMW.Classes.GroupComponent}}} and {{{TMW.Classes.ObjectModule}}}.
--
-- {{{TMW.Classes.GroupModule}}} provides a common base for these objects. **It does not provide any methods beyond those inherited from its subclasses**. It is an abstract class, and should not be directly instantiated. All classes that inherit from {{{TMW.Classes.GroupModule}}} should not be instantiated outside of the internal code used by a {{{TMW.Classes.IconView}}}. To create a new module, create a new class and inherit {{{TMW.Classes.GroupModule}}} or another class that directly or indirectly inherits from {{{TMW.Classes.GroupModule}}}. 
--
-- @class file
-- @name GroupModule.lua


local GroupModule = TMW:NewClass("GroupModule", "GroupComponent", "ObjectModule")

function GroupModule:OnNewInstance_1_GroupModule(group)
	group.Modules[self.className] = self
	self.group = group
end

function GroupModule:OnImplementIntoGroup(group)
	local implementationData = self.implementationData
	local implementorFunc = implementationData.implementorFunc
	
	if type(implementorFunc) == "function" then
		implementorFunc(self, group)
	end
end