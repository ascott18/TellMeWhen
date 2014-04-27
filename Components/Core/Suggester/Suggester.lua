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

local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures

local _, pclass = UnitClass("Player")
local LSM = LibStub("LibSharedMedia-3.0")

local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, assert, rawget, rawset, unpack, select =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, assert, rawget, rawset, unpack, select
local strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10

-- GLOBALS: GameTooltip, GameTooltip_SetDefaultAnchor

local ClassSpellCache = TMW:GetModule("ClassSpellCache")
local AuraCache = TMW:GetModule("AuraCache")
local SpellCache = TMW:GetModule("SpellCache")
local ItemCache = TMW:GetModule("ItemCache")

local SUG = TMW:NewModule("Suggester", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")
TMW.SUG = SUG


TMW.IE:RegisterUpgrade(62217, {
	global = function(self)
		-- These are both old and unused. Kill them.
		TMW.IE.db.global.CastCache = nil
		TMW.IE.db.global.ClassSpellCache = nil
	end,
})

---------- Locals/Data ----------
local SUGIsNumberInput
local SUGpreTable = {}

local ClassSpellLookup = ClassSpellCache:GetSpellLookup()

---------- Initialization/Database/Spell Caching ----------
function SUG:OnInitialize()
	TellMeWhen_IconEditor:HookScript("OnHide", function() SUG.Suggest:Hide() end)
end

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon)
	if icon == TMW.CI.icon then
		SUG.redoIfSame = 1
		SUG.Suggest:Hide()
	end
end)

function SUG:TMW_SPELLCACHE_STARTED()
	SUG.Suggest.Status:Show()
	SUG.Suggest.Speed:Show()
	SUG.Suggest.Finish:Show()
end
TMW:RegisterCallback("TMW_SPELLCACHE_STARTED", SUG)

function SUG:TMW_SPELLCACHE_COMPLETED()
	SUG.Suggest.Speed:Hide()
	SUG.Suggest.Status:Hide()
	SUG.Suggest.Finish:Hide()
	
	if SUG.onCompleteCache and SUG.Suggest:IsShown() and SUG.Suggest:IsVisible() then
		SUG.redoIfSame = 1
		SUG:NameOnCursor()
	end
end
TMW:RegisterCallback("TMW_SPELLCACHE_COMPLETED", SUG)

---------- Suggesting ----------
function SUG:DoSuggest()
	wipe(SUGpreTable)

	local tbl = SUG.CurrentModule:Table_Get()


	SUG.CurrentModule:Table_GetNormalSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	SUG.CurrentModule:Table_GetEquivSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())
	SUG.CurrentModule:Table_GetSpecialSuggestions(SUGpreTable, SUG.CurrentModule:Table_Get())

	SUG:SuggestingComplete(1)
end

function SUG:SuggestingComplete(doSort)
	local numFramesNeeded = TMW.SUG:GetNumFramesNeeded()

	if doSort and not SUG.CurrentModule.dontSort then
		sort(SUGpreTable, SUG.CurrentModule:Table_GetSorter())
	end

	local i = 1
	local InvalidEntries = rawget(SUG.CurrentModule, "InvalidEntries")
	if not InvalidEntries then
		SUG.CurrentModule.InvalidEntries = {}
		InvalidEntries = SUG.CurrentModule.InvalidEntries
	end

	for id = 1, numFramesNeeded do
		SUG:GetFrame(id)
	end
	
	while SUG[i] do
		local id
		while true do
		
			-- Here is how this horrifying line of code works:
			-- numSuggestionsWithoutFrames = #SUGpreTable - numFramesNeeded
			-- numSuggestionsWithoutFramesPlusOneBlankAtEnd = numSuggestionsWithoutFrames + 1
			-- numSuggestionsWithoutFramesPlusOneBlankAtEnd shouldn't be less than zero
			-- the offset can't be more than the numSuggestionsWithoutFramesPlusOneBlankAtEnd
			SUG.offset = min(SUG.offset, max(0, #SUGpreTable-numFramesNeeded+1))
			
			local key = i + SUG.offset
			id = SUGpreTable[key]
			
			if not id then
				break
			end
			if InvalidEntries[id] == nil then
				InvalidEntries[id] = not SUG.CurrentModule:Entry_IsValid(id)
			end
			if InvalidEntries[id] then
				tremove(SUGpreTable, key)
			else
				break
			end
		end

		local f = SUG[i]

		f.Name:SetText(nil)
		f.ID:SetText(nil)
		f.insert = nil
		f.insert2 = nil
		f.tooltipmethod = nil
		f.tooltiparg = nil
		f.tooltiptitle = nil
		f.tooltiptext = nil
		f.overrideInsertID = nil
		f.overrideInsertName = nil
		f.Background:SetVertexColor(0, 0, 0, 0)
		f.Icon:SetTexCoord(0, 1, 0, 1)

		if SUG.CurrentModule.noTexture then
			f.Icon:SetWidth(0.00001)
		else
			f.Icon:SetWidth(f.Icon:GetHeight())
		end

		if id and i <= numFramesNeeded then
			local addFunc = 1
			while true do
				local Entry_AddToList = SUG.CurrentModule["Entry_AddToList_" .. addFunc]
				if not Entry_AddToList then
					break
				end

				Entry_AddToList(SUG.CurrentModule, f, id)

				if f.insert then
					break
				end

				addFunc = addFunc + 1
			end

			local colorizeFunc = 1
			while true do
				local Entry_Colorize = SUG.CurrentModule["Entry_Colorize_" .. colorizeFunc]
				if not Entry_Colorize then
					break
				end

				Entry_Colorize(SUG.CurrentModule, f, id)

				colorizeFunc = colorizeFunc + 1
			end

			f:Show()
		else
			f:Hide()
		end
		i=i+1
	end

	if SUG.mousedOver then
		SUG.mousedOver:GetScript("OnEnter")(SUG.mousedOver)
	end
end

function SUG:NameOnCursor(isClick)
	if SpellCache:IsCaching() then
		SUG.onCompleteCache = 1
		SUG.Suggest:Show()
		return
	end
	SUG.oldLastName = SUG.lastName
	local text = SUG.Box:GetText()

	SUG.startpos = 0
	for i = SUG.Box:GetCursorPosition(), 0, -1 do
		if strsub(text, i, i) == ";" then
			SUG.startpos = i+1
			break
		end
	end

	if isClick then
		SUG.endpos = #text
		for i = SUG.startpos, #text do
			if strsub(text, i, i) == ";" then
				SUG.endpos = i-1
				break
			end
		end
	else
		SUG.endpos = SUG.Box:GetCursorPosition()
	end


	SUG.lastName = strlower(TMW:CleanString(strsub(text, SUG.startpos, SUG.endpos)))
	SUG.lastName_unmodified = SUG.lastName

	if strfind(SUG.lastName, ":[%d:%s%.]*$") then
		SUG.lastName, SUG.duration = strmatch(SUG.lastName, "(.-):([%d:%s%.]*)$")
		SUG.duration = strtrim(SUG.duration, " :;.")
		if SUG.duration == "" then
			SUG.duration = nil
		end
	else
		SUG.duration = nil
	end

	--[[if not TMW.debug then
		-- do not escape the almighty wildcards if testing
		SUG.lastName = gsub(SUG.lastName, "([%*%.])", "%%%1")
	end]]
	-- always escape parentheses, brackets, percent signs, minus signs, plus signs
	SUG.lastName = gsub(SUG.lastName, "([%(%)%%%[%]%-%+])", "%%%1")
	
	if TMW.debug then
		SUG.lastName = SUG.lastName:trim("_") -- makes building equivalencies easier
	end

	--if TMW.db.profile.SUG_atBeginning then
		SUG.atBeginning = "^" .. SUG.lastName
	--else
	--	SUG.atBeginning = SUG.lastName
	--end



	SUG.inputType = type(tonumber(SUG.lastName) or SUG.lastName)
	SUGIsNumberInput = SUG.inputType == "number"
	
	if (not SUG.CurrentModule:GetShouldSuggest()) or (not SUG.CurrentModule.noMin and (SUG.lastName == "" or not strfind(SUG.lastName, "[^%.]"))) then
		SUG.Suggest:Hide()
		return
	else
		SUG.Suggest:Show()
	end
	
	if SUG.CurrentModule.OnSuggest then
		SUG.CurrentModule:OnSuggest()
	end

	if SUG.oldLastName ~= SUG.lastName or SUG.redoIfSame then
		SUG.redoIfSame = nil

		SUG.offset = 0
		SUG:DoSuggest()
	end

end



---------- EditBox Hooking ----------
local EditBoxHooks = {
	OnEditFocusLost = function(self)
		if self.SUG_Enabled then
			SUG.Suggest:Hide()
		end
	end,
	OnEditFocusGained = function(self)
		if self.SUG_Enabled then
			local newModule = SUG:GetModule(self.SUG_type, true)
			
			
			if not newModule then
				SUG:DisableEditBox(self)
				error(
					("EditBox %q is supposed to implement SUG module %q, but the module doesn't seem to exist..."):
					format(tostring(self:GetName() or self), tostring(self.SUG_type or "<??>"))
				)
			end
			
			SUG.redoIfSame = SUG.CurrentModule ~= newModule
			SUG.Box = self
			SUG.CurrentModule = newModule
			SUG.Suggest.Header:SetText(SUG.CurrentModule.headerText)
			SUG:NameOnCursor()
		end
	end,
	OnTextChanged = function(self, userInput)
		if userInput and self.SUG_Enabled then
			SUG.redoIfSame = nil
			SUG:NameOnCursor()
		end
	end,
	OnMouseUp = function(self)
		if self.SUG_Enabled then
			SUG:NameOnCursor(1)
		end
	end,
	OnTabPressed = function(self)
		if self.SUG_Enabled and SUG[1] and SUG[1].insert and SUG[1]:IsVisible() and not SUG.CurrentModule.noTab then
			SUG[1]:Click("LeftButton")
			TMW.HELP:Hide("SUG_FIRSTHELP")
		end
	end,
}
function SUG:EnableEditBox(editbox, inputType, onlyOneEntry)
	editbox.SUG_Enabled = 1

	inputType = TMW.get(inputType)
	inputType = (inputType == true and "spell") or inputType
	if not inputType then
		return SUG:DisableEditBox(editbox)
	end
	editbox.SUG_type = inputType
	editbox.SUG_onlyOneEntry = onlyOneEntry

	if not editbox.SUG_hooked then
		for k, v in pairs(EditBoxHooks) do
			editbox:HookScript(k, v)
		end
		editbox.SUG_hooked = 1
	end

	if editbox:HasFocus() then
		EditBoxHooks.OnEditFocusGained(editbox) -- force this to rerun becase we may be calling from within the editbox's script
	end
end

function SUG:DisableEditBox(editbox)
	editbox.SUG_Enabled = nil
end


---------- Miscellaneous ----------
function SUG:ColorHelp(frame)
	TMW:TT_Anchor(frame)
	GameTooltip:AddLine(SUG.CurrentModule.helpText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	if SUG.CurrentModule.showColorHelp then
		GameTooltip:AddLine(L["SUG_DISPELTYPES"], 1, .49, .04, 1)
		GameTooltip:AddLine(L["SUG_BUFFEQUIVS"], .2, .9, .2, 1)
		GameTooltip:AddLine(L["SUG_DEBUFFEQUIVS"], .77, .12, .23, 1)
		GameTooltip:AddLine(L["SUG_OTHEREQUIVS"], 1, .96, .41, 1)
		GameTooltip:AddLine(L["SUG_MSCDONBARS"], 0, .44, .87, 1)
		GameTooltip:AddLine(L["SUG_PLAYERSPELLS"], .41, .8, .94, 1)
		GameTooltip:AddLine(L["SUG_CLASSSPELLS"], .96, .55, .73, 1)
		GameTooltip:AddLine(L["SUG_PLAYERAURAS"], .79, .30, 1, 1)
		GameTooltip:AddLine(L["SUG_NPCAURAS"], .78, .61, .43, 1)
		GameTooltip:AddLine(L["SUG_MISC"], .58, .51, .79, 1)
	end
	GameTooltip:Show()
end

function SUG:GetNumFramesNeeded()
	return floor((TMW.SUG.Suggest:GetHeight() + 5)/TMW.SUG[1]:GetHeight()) - 2
end

function SUG:GetFrame(id)
	local Suggest = TMW.SUG.Suggest
	if TMW.SUG[id] then
		return TMW.SUG[id]
	end
	
	local f = CreateFrame("Button", Suggest:GetName().."Item"..id, Suggest, "TellMeWhen_SpellSuggestTemplate", id)
	TMW.SUG[id] = f
	
	if TMW.SUG[id-1] then
		f:SetPoint("TOPRIGHT", TMW.SUG[id-1], "BOTTOMRIGHT", 0, 0)
		f:SetPoint("TOPLEFT", TMW.SUG[id-1], "BOTTOMLEFT", 0, 0)
	end
	
	return f
end


---------- Suggester Modules ----------
local Module = SUG:NewModule("default")
Module.headerText = L["SUGGESTIONS"]
Module.helpText = L["SUG_TOOLTIPTITLE"]
Module.showColorHelp = true
function Module:GetShouldSuggest()
	return true
end
function Module:Table_Get()
	return SpellCache:GetCache()
end
function Module.Sorter_ByName(a, b)
	local nameA, nameB = SUG.SortTable[a], SUG.SortTable[b]
	if nameA == nameB then
		--sort identical names by ID
		return a < b
	else
		--sort by name
		return nameA < nameB
	end
end
function Module:Table_GetSorter()
	if SUG.inputType == "number" then
		return nil -- use the default sort func
	else
		SUG.SortTable = self:Table_Get()
		return self.Sorter_ByName
	end
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for id in pairs(tbl) do
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	else
		for id, name in pairs(tbl) do
			if strfind(name, atBeginning) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
end
function Module:Table_GetEquivSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName
	local semiLN = ";" .. lastName
	local long = #lastName > 2
	
	for _, tbl in TMW:Vararg(...) do
		for equiv in pairs(tbl) do
			if 	(long and (
					(strfind(strlowerCache[equiv], lastName)) or
					(strfind(strlowerCache[L[equiv]], lastName)) or
					(not SUGIsNumberInput and strfind(strlowerCache[TMW.EquivFullNameLookup[equiv]], semiLN)) or
					(SUGIsNumberInput and strfind(TMW.EquivFullIDLookup[equiv], semiLN))
			)) or
				(not long and (
					(strfind(strlowerCache[equiv], atBeginning)) or
					(strfind(strlowerCache[L[equiv]], atBeginning))
			)) then
				suggestions[#suggestions + 1] = equiv
			end
		end
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)

end
function Module:Entry_OnClick(frame, button)
	local insert
	if button == "RightButton" and frame.insert2 then
		insert = frame.insert2
	else
		insert = frame.insert
	end
	self:Entry_Insert(insert)
end
function Module:Entry_Insert(insert)
	if insert then
		insert = tostring(insert)
		if SUG.Box.SUG_onlyOneEntry then
			SUG.Box:SetText(TMW:CleanString(insert))
			SUG.Box:ClearFocus()
			return
		end

		-- determine the text before an after where we will be inserting to
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
		local lasthalf = strsub(currenttext, SUG.endpos+1)


		-- DURATION STUFF:
		-- determine if we should add a colon to the inserted text. a colon should be added if:
			-- one existed before (the user clicked on a spell with a duration defined or already typed it in)
			-- the module requests (requires) one
		local doAddColon = SUG.duration or SUG.CurrentModule.doAddColon

		-- determine if there is an actual duration to be added to the inserted spell
		local hasDurationData = SUG.duration

		if doAddColon then
		-- the entire text to be inserted in
			insert = insert .. ": " .. (hasDurationData or "")
		end


		-- the entire text with the insertion added in
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf
		-- clean it up
		SUG.Box:SetText(TMW:CleanString(newtext))

		-- put the cursor after the newly inserted text
		local _, newPos = SUG.Box:GetText():find(insert:gsub("([%(%)%%%[%]%-%+%.%*])", "%%%1"), max(0, SUG.startpos-1))
		if newPos then
			SUG.Box:SetCursorPosition(newPos + 2)
		end

		-- if we are at the end of the editbox then put a semicolon in anyway for convenience
		if SUG.Box:GetCursorPosition() == #SUG.Box:GetText() then
			local append = "; "
			if doAddColon then
				append = (not hasDurationData and " " or "") .. append
			end
			SUG.Box:SetText(SUG.Box:GetText() .. append)
		end

		-- if we added a colon but there was no duration information inserted, move the cursor back 2 characters so the user can type it in quickly
		if doAddColon and not hasDurationData then
			SUG.Box:SetCursorPosition(SUG.Box:GetCursorPosition() - 2)
		end

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end
function Module:Entry_IsValid(id)
	return true
end



local Module = SUG:NewModule("item", SUG:GetModule("default"), "AceEvent-3.0")
function Module:GET_ITEM_INFO_RECEIVED()
	if SUG.CurrentModule and SUG.CurrentModule.moduleName:find("item") then
		SUG:SuggestingComplete()
	end
end
Module:RegisterEvent("GET_ITEM_INFO_RECEIVED")
function Module:Table_Get()
	return TMW:GetModule("ItemCache"):GetCache()
end
function Module:Entry_AddToList_1(f, id)
	if id > INVSLOT_LAST_EQUIPPED then
		local name, link = GetItemInfo(id)

		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText(id)

		f.insert = SUG.inputType == "number" and id or name
		f.insert2 = SUG.inputType ~= "number" and id or name

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(id))
	end
end


local Module = SUG:NewModule("spell", SUG:GetModule("default"))
local PlayerSpells, AuraCache_Cache, SpellCache_Cache, EquivFirstIDLookup
function Module:OnSuggest()
	AuraCache_Cache = AuraCache:GetCache()
	SpellCache_Cache = SpellCache:GetCache()
	PlayerSpells = ClassSpellCache:GetPlayerSpells()
	EquivFirstIDLookup = TMW.EquivFirstIDLookup
end
function Module:Table_Get()
	return SpellCache_Cache
end
function Module.Sorter_Spells(a, b)

	local haveA, haveB = EquivFirstIDLookup[a], EquivFirstIDLookup[b]
	if haveA or haveB then
		if haveA and haveB then
			return a < b
		else
			return haveA
		end
	end

	--player's spells (pclass)
	local haveA, haveB = PlayerSpells[a], PlayerSpells[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	end

	--all player spells (any class)
	local haveA, haveB = ClassSpellLookup[a], ClassSpellLookup[b]
	if (haveA and not haveB) or (haveB and not haveA) then
		return haveA
	elseif not (haveA or haveB) then

		local haveA, haveB = AuraCache_Cache[a], AuraCache_Cache[b] -- Auras
		if haveA and haveB and haveA ~= haveB then -- if both are auras (kind doesnt matter) AND if they are different aura types, then compare the types
			return haveA > haveB -- greater than is intended.. player auras are 2 while npc auras are 1, player auras should go first
		elseif (haveA and not haveB) or (haveB and not haveA) then --otherwise, if only one of them is an aura, then prioritize the one that is an aura
			return haveA
		end
		--if they both were auras, and they were auras of the same type (player, NPC) then procede on to the rest of the code to sort them by name/id
	end

	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = SpellCache_Cache[a], SpellCache_Cache[b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		elseif nameA and nameB then
			--sort by name
			return nameA < nameB
		else
			return nameA
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Spells
end
function Module:Entry_AddToList_1(f, id)
	if tonumber(id) then --sanity check
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		if TMW.EquivFirstIDLookup[name] then
			-- Things that conflict with equivalencies should only be inserted as IDs
			f.insert = id
			f.insert2 = name
			f.overrideInsertName = TMW.L["SUG_INSERTNAME_INTERFERE"]
		else
			f.insert = SUG.inputType == "number" and id or name
			f.insert2 = SUG.inputType ~= "number" and id or name
		end

		f.Icon:SetTexture(SpellTextures[id])
	end
end
function Module:Entry_Colorize_1(f, id)
	if PlayerSpells[id] then
		f.Background:SetVertexColor(.41, .8, .94, 1) --color all other spells that you have in your/your pet's spellbook mage blue
		return
	else
		for class, tbl in pairs(ClassSpellCache:GetCache()) do
			if tbl[id] then
				f.Background:SetVertexColor(.96, .55, .73, 1) --color all other known class spells paladin pink
				return
			end
		end
	end

	local whoCasted = AuraCache_Cache[id]
	if whoCasted == AuraCache.CONST.AURA_TYPE_NONPLAYER then
		 -- Color known NPC auras warrior brown.
		f.Background:SetVertexColor(.78, .61, .43, 1)
	elseif whoCasted == AuraCache.CONST.AURA_TYPE_PLAYER then
		-- Color known PLAYER auras a bright pink-ish/pruple-ish color that is similar to paladin pink,
		-- but has sufficient contrast for distinguishing.
		f.Background:SetVertexColor(.79, .30, 1, 1)
	end
end


local Module = SUG:NewModule("texture", SUG:GetModule("spell"))
function Module:Entry_AddToList_1(f, id)
	if tonumber(id) then --sanity check
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = id
		if ClassSpellCache:GetCache()[pclass][id] and name and GetSpellTexture(name) then
			f.insert2 = name
		end

		f.Icon:SetTexture(SpellTextures[id])
	end
end

-- Currently unused. I'm not sure if I like this or not.
-- It includes item textures (the plain texture suggestion module doesn't), but the sorting is really weird and also CPU-intensive
--[===[
local Module = SUG:NewModule("texture2", SUG:GetModule("default"), "AceEvent-3.0")
local ItemCache_Cache
Module.Sources = {
	
}
function Module:GetShouldSuggest()
	if SUG.inputType == "number" and #SUG.lastName < 2 then
		return false
	end
	return true
end
function Module:OnSuggest()
	AuraCache_Cache = AuraCache:GetCache()
	SpellCache_Cache = SpellCache:GetCache()
	ItemCache_Cache = ItemCache:GetCache()
	PlayerSpells = ClassSpellCache:GetPlayerSpells()
	EquivFirstIDLookup = TMW.EquivFirstIDLookup
	
	Module.Sources.s = SpellCache_Cache
	Module.Sources.i = ItemCache_Cache
end
function Module:GET_ITEM_INFO_RECEIVED()
	if SUG.CurrentModule and SUG.CurrentModule.moduleName == "texture" then
		SUG:SuggestingComplete()
	end
end
Module:RegisterEvent("GET_ITEM_INFO_RECEIVED")
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	for idType, tbl in pairs(Module.Sources) do
		if SUG.inputType == "number" then
			local len = #SUG.lastName - 1
			local match = tonumber(SUG.lastName)
			for id in pairs(tbl) do
				if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
			--	if strfind(id, atBeginning) then
					suggestions[#suggestions + 1] = idType .. id
				end
			end
		else
			for id, name in pairs(tbl) do
				if strfind(name, atBeginning) then
					suggestions[#suggestions + 1] = idType .. id
				end
			end
		end
	end
end
function Module:Etc_GetID(id)
	local idType, id = strmatch(id, "(.)(.*)")
	id = tonumber(id)
	return idType, id
end
function Module:Entry_AddToList_1(f, id)
	local idType, id = self:Etc_GetID(id)
	
	if idType == "i" and id then
		local name, link = GetItemInfo(id)

		f.Name:SetText(link and link:gsub("[%[%]]", ""))
		f.ID:SetText(id)

		f.insert = GetItemIcon(id)

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = link

		f.Icon:SetTexture(GetItemIcon(id))
	end
end
function Module:Entry_AddToList_2(f, id)
	local idType, id = self:Etc_GetID(id)
	
	if idType == "s" and id then
		local name = GetSpellInfo(id)

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id

		f.insert = id
		f.insert2 = SpellTextures[id]

		f.Icon:SetTexture(SpellTextures[id])
	end
end
function Module.Sorter_Textures(a, b)
	local idType_a, a = Module:Etc_GetID(a)
	local idType_b, b = Module:Etc_GetID(b)
	
	if idType_a == idType_b and idType_a == "s" then
		local haveA, haveB = EquivFirstIDLookup[a], EquivFirstIDLookup[b]
		if haveA or haveB then
			if haveA and haveB then
				return a < b
			else
				return haveA
			end
		end
		
		local haveA, haveB = EquivFirstIDLookup[a], EquivFirstIDLookup[b]
		if haveA or haveB then
			if haveA and haveB then
				return a < b
			else
				return haveA
			end
		end

		--player's spells (pclass)
		local haveA, haveB = PlayerSpells[a], PlayerSpells[b]
		if (haveA and not haveB) or (haveB and not haveA) then
			return haveA
		end

		--all player spells (any class)
		local haveA, haveB = ClassSpellLookup[a], ClassSpellLookup[b]
		if (haveA and not haveB) or (haveB and not haveA) then
			return haveA
		elseif not (haveA or haveB) then

			local haveA, haveB = AuraCache_Cache[a], AuraCache_Cache[b] -- Auras
			if haveA and haveB and haveA ~= haveB then -- if both are auras (kind doesnt matter) AND if they are different aura types, then compare the types
				return haveA > haveB -- greater than is intended.. player auras are 2 while npc auras are 1, player auras should go first
			elseif (haveA and not haveB) or (haveB and not haveA) then --otherwise, if only one of them is an aura, then prioritize the one that is an aura
				return haveA
			end
			--if they both were auras, and they were auras of the same type (player, NPC) then procede on to the rest of the code to sort them by name/id
		end
	end

	if SUGIsNumberInput then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = Module.Sources[idType_a][a], Module.Sources[idType_b][b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		elseif nameA and nameB then
			--sort by name
			return nameA < nameB
		else
			return nameA
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Textures
end
function Module:Entry_Colorize_1(f, id)
	local idType, id = self:Etc_GetID(id)
	
	if idType == "s" then
		if PlayerSpells[id] then
			f.Background:SetVertexColor(.41, .8, .94, 1) --color all other spells that you have in your/your pet's spellbook mage blue
			return
		else
			for class, tbl in pairs(ClassSpellCache:GetCache()) do
				if tbl[id] then
					f.Background:SetVertexColor(.96, .55, .73, 1) --color all other known class spells paladin pink
					return
				end
			end
		end

		local whoCasted = AuraCache_Cache[id]
		if whoCasted == AuraCache.CONST.AURA_TYPE_NONPLAYER then
			 -- Color known NPC auras warrior brown.
			f.Background:SetVertexColor(.78, .61, .43, 1)
		elseif whoCasted == AuraCache.CONST.AURA_TYPE_PLAYER then
			-- Color known PLAYER auras a bright pink-ish/pruple-ish color that is similar to paladin pink,
			-- but has sufficient contrast for distinguishing.
			f.Background:SetVertexColor(.79, .30, 1, 1)
		end
	end
end
]===]


local Module = SUG:NewModule("spellwithduration", SUG:GetModule("spell"))
Module.doAddColon = true
local MATCH_RECAST_TIME_MIN, MATCH_RECAST_TIME_SEC
function Module:OnInitialize()
	MATCH_RECAST_TIME_MIN = SPELL_RECAST_TIME_MIN:gsub("%%%.3g", "([%%d%%.]+)")
	MATCH_RECAST_TIME_SEC = SPELL_RECAST_TIME_SEC:gsub("%%%.3g", "([%%d%%.]+)")
end
function Module:Entry_OnClick(f, button)
	local insert

	local spellID = f.tooltiparg
	local Parser, LT1, LT2, LT3, RT1, RT2, RT3 = TMW:GetParser()
	Parser:SetOwner(UIParent, "ANCHOR_NONE")
	Parser:SetSpellByID(spellID)

	local dur

	for _, text in TMW:Vararg(RT2:GetText(), RT3:GetText()) do
		if text then

			local mins = text:match(MATCH_RECAST_TIME_MIN)
			local secs = text:match(MATCH_RECAST_TIME_SEC)
			if mins then
				dur = mins .. ":00"
			elseif secs then
				dur = secs
			end

			if dur then
				break
			end
		end
	end
	if spellID == 42292 then -- pvp trinket override
		dur = "2:00"
	end

	if button == "RightButton" and f.insert2 then
		insert = f.insert2
	else
		insert = f.insert
	end

	self:Entry_Insert(insert, dur)
end
function Module:Entry_Insert(insert, duration)
	if insert then
		insert = tostring(insert)
		if SUG.Box.SUG_onlyOneEntry then
			SUG.Box:SetText(TMW:CleanString(insert))
			SUG.Box:ClearFocus()
			return
		end

		-- determine the text before an after where we will be inserting to
		local currenttext = SUG.Box:GetText()
		local start = SUG.startpos-1
		local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
		local lasthalf = strsub(currenttext, SUG.endpos+1)

		-- determine if we should add a colon to the inserted text. a colon should be added if:
			-- one existed before (the user clicked on a spell with a duration defined or already typed it in)
			-- the module requests (requires) one
		local doAddColon = SUG.duration or SUG.CurrentModule.doAddColon

		-- determine if there is an actual duration to be added to the inserted spell
		local hasDurationData = duration or SUG.duration

		-- the entire text to be inserted in
		local insert = (doAddColon and insert .. ": " .. (hasDurationData or "")) or insert

		-- the entire text with the insertion added in
		local newtext = firsthalf .. "; " .. insert .. "; " .. lasthalf


		SUG.Box:SetText(TMW:CleanString(newtext))

		-- put the cursor after the newly inserted text
		local _, newPos = SUG.Box:GetText():find(insert:gsub("([%(%)%%%[%]%-%+%.%*])", "%%%1"), max(0, SUG.startpos-1))
		newPos = newPos or #SUG.Box:GetText()
		SUG.Box:SetCursorPosition(newPos + 2)

		-- if we are at the end of the editbox then put a semicolon in anyway for convenience
		if SUG.Box:GetCursorPosition() == #SUG.Box:GetText() then
			SUG.Box:SetText(SUG.Box:GetText() .. (doAddColon and not hasDurationData and " " or "") .. "; ")
		end

		-- if we added a colon but there was no duration information inserted, move the cursor back 2 characters so the user can type it in quickly
		if doAddColon and not hasDurationData then
			SUG.Box:SetCursorPosition(SUG.Box:GetCursorPosition() - 2)
		end

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end


local Module = SUG:NewModule("cast", SUG:GetModule("spell"))
function Module:Table_Get()
	return SpellCache:GetCache(), TMW.BE.casts
end
function Module:Entry_AddToList_2(f, id)
	if TMW.BE.casts[id] then
		-- the entry is an equivalacy
		-- id is the equivalency name (e.g. Tier11Interrupts)
		local equiv = id
		id = TMW.EquivFirstIDLookup[equiv]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv
		f.overrideInsertName = L["SUG_INSERTEQUIV"]

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[id])
	end
end
function Module:Entry_Colorize_2(f, id)
	if TMW.BE.casts[id] then
		f.Background:SetVertexColor(1, .96, .41, 1) -- rogue yellow
	end
end
function Module:Entry_IsValid(id)
	if TMW.BE.casts[id] then
		return true
	end

	local _, _, _, _, _, _, castTime = GetSpellInfo(id)
	if not castTime then
		return false
	elseif castTime > 0 then
		return true
	end

	local Parser, LT1, LT2, LT3 = TMW:GetParser()

	Parser:SetOwner(UIParent, "ANCHOR_NONE") -- must set the owner before text can be obtained.
	Parser:SetSpellByID(id)

	if LT2:GetText() == SPELL_CAST_CHANNELED or LT3:GetText() == SPELL_CAST_CHANNELED then
		return true
	end
end


local Module = SUG:NewModule("buff", SUG:GetModule("spell"))
function Module:Table_Get()
	return SpellCache:GetCache(), TMW.BE.buffs, TMW.BE.debuffs
end
function Module:Entry_Colorize_2(f, id)
	if TMW.DS[id] then
		f.Background:SetVertexColor(1, .49, .04, 1) -- druid orange
	elseif TMW.BE.buffs[id] then
		f.Background:SetVertexColor(.2, .9, .2, 1) -- lightish green
	elseif TMW.BE.debuffs[id] then
		f.Background:SetVertexColor(.77, .12, .23, 1) -- deathknight red
	end
end
function Module:Entry_AddToList_2(f, id)
	if TMW.DS[id] then -- if the entry is a dispel type (magic, poison, etc)
		local dispeltype = id

		f.Name:SetText(dispeltype)
		f.ID:SetText(nil)

		f.insert = dispeltype

		f.tooltiptitle = L[dispeltype]
		f.tooltiptext = L["ICONMENU_DISPEL"]

		f.Icon:SetTexture(TMW.DS[id])

	elseif TMW.EquivFirstIDLookup[id] then -- if the entry is an equivalacy (buff, cast, or whatever)
		--NOTE: dispel types are put in TMW.EquivFirstIDLookup too for efficiency in the sorter func, but as long as dispel types are checked first, it wont matter
		local equiv = id
		local firstid = TMW.EquivFirstIDLookup[id]

		f.Name:SetText(equiv)
		f.ID:SetText(nil)

		f.insert = equiv
		f.overrideInsertName = L["SUG_INSERTEQUIV"]

		f.tooltipmethod = "TMW_SetEquiv"
		f.tooltiparg = equiv

		f.Icon:SetTexture(SpellTextures[firstid])
	end
end
function Module:Table_GetSpecialSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning

	for dispeltype in pairs(TMW.DS) do
		if strfind(strlowerCache[dispeltype], atBeginning) or strfind(strlowerCache[L[dispeltype]], atBeginning)  then
			suggestions[#suggestions + 1] = dispeltype
		end
	end
end

local Module = SUG:NewModule("buffNoDS", SUG:GetModule("buff"))
Module.Table_GetSpecialSuggestions = TMW.NULLFUNC

