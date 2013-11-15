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

local CNDT = TMW.CNDT


--- [[api/conditions/api-documentation/condition/|Condition]] provides the data that describes the configuration and evaluation of a condition. It is sometimes refered to as "condition data", which is not to be confused with "condition settings".
-- 
-- It should not be directly instantiated - use ConditionCategory:RegisterCondition() to create a condition.
-- 
-- @class file
-- @name Condition.lua


local Condition = TMW:NewClass("Condition")

function Condition:OnNewInstance(category, order, identifier)

	TMW:ValidateType("2 (category)", "Condition:New()", category, "ConditionCategory")
	TMW:ValidateType("3 (order)", "Condition:New()", order, "number")
	TMW:ValidateType("4 (identifier)", "Condition:New()", identifier, "string")

	TMW:ValidateType("funcstr", "conditionData", self.funcstr, "string;function")
	
	if CNDT.ConditionsByType[identifier] then
		error(("Condition %q already exists."):format(identifier), 2)
	end

	self.category = category
	self.identifier = identifier
	self.order = order

	CNDT.ConditionsByType[identifier] = self
end

function Condition:GetCondition(identifier)
	return CNDT.ConditionsByType[identifier]
end

function Condition:IsDeprecated()
	return self.funcstr == "DEPRECATED"
end

function Condition:PrepareEnv()

	-- Add in anything that the condition wants to include in Env
	if self.Env then
		for k, v in pairs(self.Env) do
			local existingValue = rawget(CNDT.Env, k)
			if existingValue ~= nil and existingValue ~= v then
				TMW:Error("Condition " .. Type .. " tried to write values to Env different than those that were already in it.")
			else
				CNDT.Env[k] = v
			end
		end
		
		-- We don't need this after it gets merged, so nil it.
		self.Env = nil
	end
end
