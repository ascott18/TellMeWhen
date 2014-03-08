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

local floor, min, max, strsub, strfind = 
	  floor, min, max, strsub, strfind
local pairs, ipairs, sort, tremove, CopyTable = 
	  pairs, ipairs, sort, tremove, CopyTable
	  
local CI = TMW.CI

-- GLOBALS: CreateFrame, NONE, NORMAL_FONT_COLOR



local EVENTS = TMW.EVENTS
local LuaBase = TMW.C.EventHandler_LuaBase

LuaBase.handlerName = L["EVENTHANDLER_LUA_TAB"]
LuaBase.handlerNameShort = L["EVENTHANDLER_LUA_TAB"]



-- Overrides TestEvent inherited from TMW.Classes.EventHandler
function LuaBase:TestEvent(eventID)
	local eventSettings = EVENTS:GetEventSettings(eventID)

	local code = eventSettings.Lua
	
	local func = self:GetCompiledFunction(code)
	
	if func then
		local success, err = pcall(func, TMW.CI.icon)
		
		if not success then
			self:SetError(code, "RUNTIME", err)
		end
	end
end

---------- Events ----------
function LuaBase:LoadSettingsForEventID(id)
	self:LoadCode(EVENTS:GetEventSettings(id).Lua)
end

function LuaBase:LoadCode(code)
	self.ConfigContainer.Code:SetText(code)
	
	local func, err = self:GetCompiledFunction(code)
	
	self:SetError(code, "COMPILE", err)
end

function LuaBase:SetError(code, kind, err)
	local Error = self.ConfigContainer.Error
	
	if not err or err == "" then
		--Error:Hide()
		Error:SetText("")
		return
	end
	
	err = err:gsub("%[string .*%]", "line")
	local line = tonumber(err:match("line:(%d+):"))
	
	code = code:gsub("\r\n", "\n"):gsub("\r", "\n")
	local lineText = select(line, strsplit("\n", code)) or ""
	
	lineText = lineText:trim(" \t\r\n")
	if #lineText > 25 then
		lineText = lineText:sub(1, 25) .. "..."
	end
	
	err = "|cffee0000" .. kind .. " ERROR: " .. err:gsub("line:(%d+):", "line %1 (\"" .. lineText .. "\"):")
	
	--Error:Show()
	Error:SetText(err)
end

function LuaBase:SetupEventDisplay(eventID)
	if not eventID then return end

	local code = EVENTS:GetEventSettings(eventID).Lua

	code = code:trim(" \r\n\t")
		
	if code == "" then
		code = "|cff808080<No Code>"
	else
		code = code:match("^%-?%-?([^\r\n]*)"):trim()
		
		if code == "" then
			code = "|cff808080<No Code/No Title>"
		end
	end

	
	EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["EVENTHANDLER_LUA_LUA"] .. ":|r " .. code)
end





local EventLua = EVENTS:GetEventHandler("Lua")
TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	EventLua.ConfigContainer.Error:SetWidth(EventLua.ConfigContainer:GetWidth() - 20)
end)


local StatefulLua = EVENTS:GetEventHandler("Lua2")
TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	StatefulLua.ConfigContainer = EventLua.ConfigContainer
end)

function StatefulLua:SetupEventDisplay(eventID)
	if not eventID then return end

	TMW.EVENTS.EventHandlerFrames[eventID].EventName:SetText(eventID .. ") " .. L["SOUND_EVENT_WHILECONDITION"])


	EventLua:SetupEventDisplay(eventID)
end