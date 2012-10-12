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


local HELP = TMW:NewModule("Help", "AceTimer-3.0")
TMW.HELP = HELP

HELP.Codes = {
	"ICON_POCKETWATCH_FIRSTSEE",

	"ICON_DURS_FIRSTSEE",
	"ICON_DURS_MISSING",

	"ICON_IMPORT_CURRENTPROFILE",
	"ICON_EXPORT_DOCOPY",

	"ICON_DR_MISMATCH",
	"ICON_MS_NOTFOUND",

	"ICON_UNIT_MISSING",

	"CNDT_UNIT_MISSING",
	"CNDT_PARENTHESES_ERROR",
}

HELP.OnlyOnce = {
	ICON_DURS_FIRSTSEE = true,
	ICON_POCKETWATCH_FIRSTSEE = true,
	ICON_IMPORT_CURRENTPROFILE = true,
	ICON_EXPORT_DOCOPY = true,
}

function HELP:OnInitialize()
	self.Frame = TellMeWhen_HelpFrame
	self.Queued = {}
end


---------- External Usage ----------
function HELP:Show(code, icon, frame, x, y, text, ...)
	-- handle the code, determine the ID of the code.
	TMW:ValidateType(2, "TMW.HELP:Show()", code, "string")
	TMW:ValidateType(3, "TMW.HELP:Show()", icon, "frame;nil")
	TMW:ValidateType(4, "TMW.HELP:Show()", frame, "frame")
	TMW:ValidateType(5, "TMW.HELP:Show()", x, "number;nil")
	TMW:ValidateType(6, "TMW.HELP:Show()", y, "number;nil")
	TMW:ValidateType(7, "TMW.HELP:Show()", text, "string")
	
	local codeID
	for i, c in pairs(self.Codes) do
		if c == code then
			codeID = i
			break
		end
	end
	assert(codeID, format("Code %q is not defined", code))
	-- we can now safely proceded to process and queue the help

	-- retrieve or create the data table
	local help = wipe(self.Queued[code] or {})

	-- add the text format args to the data
	for i = 1, select('#', ...) do
		help[i] = select(i, ...)
	end
	-- add other data
	help.code = code
	help.codeID = codeID
	help.icon = icon
	help.frame = frame
	help.x = x
	help.y = y
	help.text = text
	-- if the frame has the CreateTexture method, then it can be made the parent.
	-- Otherwise, the frame is actually a texture/font/etc object, so set its parent as the parent.
	help.parent = help.frame.CreateTexture and help.frame or help.frame:GetParent()

	-- determine if the code has a setting associated to only show it once.
	help.setting = self.OnlyOnce[code] and code

	-- if it does and it has already been set true, then we dont need to show anything, so quit.
	if help.setting and TMW.db.global.HelpSettings[help.setting] then
		self.Queued[code] = nil
		help = nil
		return
	end

	-- if the code is the same as what is currently shown, then replace what is currently being shown.
	if self.showingHelp and self.showingHelp.code == code then
		self.showingHelp = nil
	end

	-- everything should be in order, so add the help to the queue.
	self:Queue(help)

	-- notify that this help will eventually be shown
	return 1
end

function HELP:Hide(code)
	if self.Queued[code] then
		self.Queued[code] = nil
	elseif self:GetShown() == code then
		self.showingHelp = nil
		self:ShowNext()
	end
end

function HELP:GetShown()
	return self.showingHelp and self.showingHelp.code
end

function HELP:NewCode(code, order, OnlyOnce)
	TMW:ValidateType(2, "HELP:NewCode(code, order, OnlyOnce)", code, "string")
	assert(not TMW.tContains(HELP.Codes, code), "HELP code " .. code .. " is already registered!")
	
	if order then
		tinsert(HELP.Codes, order, code)
	else
		tinsert(HELP.Codes, code)
	end
	
	if OnlyOnce then
		HELP.OnlyOnce[code] = true
	end
end


---------- Queue Management ----------
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

function HELP:ShouldShowHelp(help)
	if help.icon and not help.icon:IsBeingEdited() then
		return false
	elseif not help.parent:IsVisible() then
		return false
	end
	return true
end

function HELP:ShowNext()
	-- if there nothing currently being displayed, hide the frame.
	if not HELP.showingHelp then
		HELP.Frame:Hide()
	end

	-- if we are already showing something, then don't overwrite it.
	if HELP.showingHelp then
		-- but if the current help should not be shown, then stop showing it, but stick it back in the queue to try again later
		if not HELP:ShouldShowHelp(HELP.showingHelp) then
			local current = HELP.showingHelp
			HELP.showingHelp = nil
			HELP:Queue(current)
		end
		return
	end

	-- if there isn't a next help to show, then dont try.
	if not next(HELP.Queued) then
		return
	end

	-- calculate the next help in line based on the order of HELP.Codes
	local help
	for order, code in ipairs(HELP.Codes) do
		if HELP.Queued[code] and HELP:ShouldShowHelp(HELP.Queued[code]) then
			help = HELP.Queued[code]
			break
		end
	end

	if not help then
		return
	end

	-- show the frame with the data
	local text = format(help.text, unpack(help))

	HELP.Frame:ClearAllPoints()
	HELP.Frame:SetPoint("TOPRIGHT", help.frame, "LEFT", (help.x or 0) - 30, (help.y or 0) + 28)
	HELP.Frame.text:SetText(text)
	HELP.Frame:SetHeight(HELP.Frame.text:GetHeight() + 38)
	HELP.Frame:SetWidth(min(250, HELP.Frame.text:GetStringWidth() + 30))

	HELP.Frame:Show()


	-- if the help had a setting associated, set it now
	if help.setting then
		TMW.db.global.HelpSettings[help.setting] = true
	end

	-- remove the help from the queue and set it as the current help
	HELP.Queued[help.code] = nil
	HELP.showingHelp = help
end

function HELP:HideForIcon(icon)
	for code, help in pairs(HELP.Queued) do
		if help.icon == icon then
			HELP.Queued[code] = nil
		end
	end
	if HELP.showingHelp and HELP.showingHelp.icon == icon then
		HELP.showingHelp = nil
		HELP:ShowNext()
	end
end



TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, typeData_old)
	if TMW.CI.ic then
		HELP:HideForIcon(TMW.CI.ic)
	end
end)

TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED_CHANGED", function(event, icon, icon_old)
	HELP:HideForIcon(icon_old)
end)

TMW:RegisterCallback("TMW_ICON_SETTINGS_RESET", function(event, icon)
	HELP:HideForIcon(icon)
end)	

TMW:RegisterCallback("TMW_CONFIG_TAB_CLICKED", function(event, tab, oldTab)
	HELP:ShowNext()
end)	

TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function(event, icon)
	HELP:ShowNext()
end)