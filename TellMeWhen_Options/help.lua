local HELP = TMW:NewModule("Help", "AceTimer-3.0") TMW.HELP = HELP
local IE = TMW.IE
HELP.Frame = IE.Help

local L = TMW.L
local db = TMW.db

HELP.Codes = {
	"ICON_DURS_MISSING",
	"ICON_DURS_FIRSTSEE",
	
	"ICON_POCKETWATCH_FIRSTSEE",
	
	"ICON_DR_MISMATCH",
	
	
	"CNDT_PAREN_NOMATCH",
	"CNDT_PAREN_NOOPENER",
}

HELP.OnlyOnce = {
	ICON_DURS_FIRSTSEE = true,
	ICON_POCKETWATCH_FIRSTSEE = true,
}

-- Recycling functions
local new, del, copy
--newcount, delcount,createdcount,cached = 0,0,0
do
	local pool = setmetatable({},{__mode="k"})
	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		else
			return {}
		end
	end
	function del(t)
		wipe(t)
		pool[t] = true
	end
end

function HELP:OnInitialize()
	db = TMW.db
end

HELP.Queued = {}

function HELP:New(code)
	if HELP.Queued[code] then
		return wipe(HELP.Queued[code])
	else
		return new()
	end
end

function HELP:Show(code, frame, x, y, text, ...)

	-- handle the code, determine the ID of the code.
	assert(type(code) == "string")
	local codeID
	for i, c in pairs(HELP.Codes) do
		if c == code then
			codeID = i
			break
		end
	end
	assert(codeID, format("Code %q is not defined", code))
	-- we can now safely proceded to process and queue the help
	
	-- create or retrieve the data table
	local help = HELP:New(code)
	
	-- add the text format args to the data
	for i = 1, select('#', ...) do
		help[i] = select(i, ...)
	end
	-- add other data
	help.code = code
	help.codeID = codeID
	help.frame = frame
	help.x = x
	help.y = y
	help.text = text
	
	-- determine if the code has a setting associated to only show it once.
	help.setting = HELP.OnlyOnce[code]
	
	-- if it does and it has already been set true, then we dont need to show anything, so quit.
	if help.setting and db.global.HelpSettings[help.setting] then
		del(help)
		return
	end
	
	-- everything should be in order, so add the help to the queue.
	HELP:Queue(help)
	
	-- notify that this help will eventually be shown
	return 1
end

function HELP:Queue(help)
	-- add the help to the queue
	HELP.Queued[help.code] = help
	
	-- notify the engine to start
	HELP:ShowNext()
end

function HELP:OnClose()
	HELP.showingHelp = nil
	HELP:ShowNext()
end

function HELP:ShowNext()
	-- if there isn't a next to show, then dont try.
	if not next(HELP.Queued) then
		return
	end
	
	-- if we are already showing something, then don't overwrite it.
	if HELP.showingHelp then
		return
	end
	
	-- calculate the next help in line based on the order of HELP.Codes
	local help
	for order, code in ipairs(HELP.Codes) do
		if HELP.Queued[code] then
			help = HELP.Queued[code]
			break
		end
	end
	
	-- show the frame with the data
	local text = format(help.text, unpack(help))
	
	HELP.Frame:ClearAllPoints()
	HELP.Frame:SetPoint("TOPRIGHT", help.frame, "LEFT", (help.x or 0) - 30, (help.y or 0) + 28)
	HELP.Frame.text:SetText(text)
	HELP.Frame:SetHeight(HELP.Frame.text:GetHeight() + 38)
	
	local parent = help.frame.CreateTexture and help.frame or help.frame:GetParent() -- if the frame has the CreateTexture method, then it can be made the parent. Otherwise, the frame is actually a texture/font/etc object, so set 
	HELP.Frame:SetParent(parent)
	HELP.Frame:Show()
	
	-- if the help had a setting associated, set it now
	if help.setting then
		db.global.HelpSettings[help.setting] = true
	end
	HELP.Queued[help.code] = nil
	HELP.showingHelp = help
end