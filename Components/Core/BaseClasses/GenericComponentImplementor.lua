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


--- {{{TMW.Classes.GenericComponentImplementor}}} is a base class of any objects that implement any instances of {{{TMW.Classes.GenericComponent}}}
--
-- GenericComponentImplementor provides a common base for these objects, and it provides the {{{self.Components}}} and {{{self.ComponentsLookup}}} tables to its instances. It is an abstract class, and should not be directly instantiated.
--
-- @class file
-- @name GenericComponentImplementor.lua


-- @class table
-- @name TMW.Classes.GenericComponentImplementor
-- @field Components [table] An array of all the {{{TMW.Classes.GenericComponent}}} that have been implemented into this {{{TMW.Classes.GenericComponentImplementor}}}. No modifications to this table should be made outside of methods that belong to classes that explicitly inherit from {{{TMW.Classes.GenericComponent}}}.
-- @field ComponentsLookup [table] A dictionary of all the {{{TMW.Classes.GenericComponent}}} that have been implemented into this {{{TMW.Classes.GenericComponentImplementor}}}. No modifications to this table should be made outside of methods that belong to classes that explicitly inherit from {{{TMW.Classes.GenericComponent}}}.
TMW:NewClass("GenericComponentImplementor"){
	OnNewInstance_GenericComponentImplementor = function(self)
		self.Components = {}
		self.ComponentsLookup = {}
	end,
}