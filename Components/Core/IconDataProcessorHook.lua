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

local assert
	= assert

--- {{{TMW.Classes.IconDataProcessorHook}}} is the class of all IconDataProcessorHooks. A IconDataProcessorHook hooks into a {{{TMW.Classes.IconDataProcessor}}}, giving it a chance to modify icon attributes before they are given to their normal {{{TMW.Classes.IconDataProcessor}}}. An IconDataProcessorHook can also get access to icon attributes quicker than any other Icon Component, allowing them to read these attributes and set other attributes based on their value (this can be seen in the second usage example of {{{:RegisterCompileFunctionSegmentHook}}})
--
-- {{{TMW.Classes.IconDataProcessor}}} inherits from {{{TMW.Classes.IconDataProcessorComponent}}}, and implicitly from the classes that it inherits. 
--
-- @class file
-- @name IconDataProcessorHook.lua


local IconDataProcessorHook = TMW:NewClass("IconDataProcessorHook", "IconDataProcessorComponent")


--- Constructor - Creates a new {{{TMW.Classes.IconDataProcessorHook}}}.
-- @name IconDataProcessorHook:New
-- @param name [string] A name for this {{{TMW.Classes.IconDataProcessorHook}}}. Should be brief, and should be all capital letters.
-- @param processorToHook [string] The name of a {{{TMW.Classes.IconDataProcessor}}} (as passed to the first param of its constructor) to hook.
-- @return [{{{TMW.Classes.IconDataProcessorHook}}}] An instance of a new IconDataProcessorHook.
-- @usage
-- local Hook = TMW.Classes.IconDataProcessorHook:New("TEXTURE_CUSTOMTEX", "TEXTURE")
function IconDataProcessorHook:OnNewInstance(name, processorToHook)
	TMW:ValidateType(2, "IconDataProcessorHook:New()", name, "string")
	TMW:ValidateType(3, "IconDataProcessorHook:New()", processorToHook, "string")
	
	local Processor = TMW.Classes.IconDataProcessor.ProcessorsByName[processorToHook]
	assert(Processor, "IconDataProcessorHook:New() unable to find IconDataProcessor named " .. processorToHook)
	
	self.name = name
	self.processorToHook = processorToHook
	self.Processor = Processor
	self.Processor.hooks[#self.Processor.hooks+1] = self
	self.funcs = {}
	self.processorRequirements = {}
	
	self:RegisterProcessorRequirement(processorToHook)
end

--- Registers a CompileFunctionSegment function (similar behavior to {{{TMW.Classes.IconDataProcessor}}}{{{:CompileFunctionSegment()}}} that will be called when the segment of {{{TMW.Classes.Icon}}}{{{:SetInfo()}}} for the {{{TMW.Classes.IconDataProcessor}}} that this {{{TMW.Classes.IconDataProcessorHook}}} is hooking is being compiled.
-- @param order [string] Must be "pre" or "post". "pre" will cause this hook to be compiled before the {{{TMW.Classes.IconDataProcessor}}} that it is hooking gets compiled. "post" will cause this hook to be compiled afterwords.
-- @param func [function] A function that will be called to compile part of {{{TMW.Classes.Icon}}}{{{:SetInfo()}}}. Called with signature {{{(Processor, t)}}}. {{{Processor}}} is the {{{TMW.Classes.IconDataProcessor}}} instance hooked by this IconDataProcessorHook. {{{t}}} is the string table that will be concatenated to form the whole :SetInfo() method.
-- @usage
--	-- Example usage from TEXTURE_CUSTOMTEX:
--	Hook:RegisterCompileFunctionSegmentHook("pre", function(Processor, t)
--		t[#t+1] = [[
--		texture = icon.CustomTex_OverrideTex or texture -- if a texture override is specified, then use it instead
--		]]
--	end)
--
--	-- Example usage from ALPHA_DURATIONREQ:
--	Hook:RegisterCompileFunctionSegmentHook("post", function(Processor, t)
--		t[#t+1] = [[
--	
--		local d = duration - (TMW.time - start)
--		
--		local alpha_durationFailed = nil
--		if
--			d > 0 and ((icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax))
--		then
--			alpha_durationFailed = icon.DurationAlpha
--		end
--		
--		if attributes.alpha_durationFailed ~= alpha_durationFailed then
--			icon:SetInfo_INTERNAL("alpha_durationFailed", alpha_durationFailed)
--			doFireIconUpdated = true
--		end
--		]]
--	end)
function IconDataProcessorHook:RegisterCompileFunctionSegmentHook(order, func)
	self:AssertSelfIsInstance()
	-- These hooks are not much of hooks at all,
	-- since they go directly in the body of the function
	-- and can modify input variables before they are processed.
	
	assert(order == "pre" or order == "post", "RegisterCompileFunctionSegmentHook: arg2 must be either 'pre' or 'post'")
	
	self.funcs[func] = order
	
	TMW.Classes.Icon:ClearSetInfoFunctionCache()
end

--- Require that a {{{TMW.Classes.IconDataProcessor}}} must be implemented into a {{{TMW.Classes.Icon}}} before this {{{TMW.Classes.IconDataProcessorHook}}} will be allowed to implement into the icon. This is called by default for the {{{TMW.Classes.IconDataProcessor}}} that is being hooked, but you may need to require other {{{TMW.Classes.IconDataProcessor}}}s as well for your specific needs.
-- @param processorName [string] The name of a {{{TMW.Classes.IconDataProcessor}}} (as passed to the first param of its constructor) that is required.
-- @usage Hook:RegisterProcessorRequirement("DURATION")
function IconDataProcessorHook:RegisterProcessorRequirement(processorName)
	self:AssertSelfIsInstance()
	self.processorRequirements[processorName] = true
end


