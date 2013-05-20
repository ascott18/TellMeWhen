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


--- [[api/base-classes/generic-component/|GenericComponent]] is a base class of any objects that will be implemented into an instance of [[api/base-classes/generic-component-implementor/|GenericComponentImplementor]]
-- 
-- GenericComponent provides a common base for these objects, but provides no functionality. It is an abstract class, and should not be directly instantiated.
-- 
-- @class file
-- @name GenericComponent.lua


TMW:NewClass("GenericComponent")