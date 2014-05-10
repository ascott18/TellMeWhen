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

local DogTag = LibStub("LibDogTag-3.0")

local DOGTAGS = TMW:GetModule("DogTags")




local SUG = TMW.SUG

local Module = SUG:NewModule("dogtags", SUG:GetModule("default"))
Module.headerText = L["SUGGESTIONS_DOGTAGS"]
Module.helpText = L["SUG_TOOLTIPTITLE_TEXTSUBS"]
Module.helpOnClick = function()
	DogTag:OpenHelp()
end
Module.showColorHelp = false
--Module.dontSort = true
Module.noMin = true
Module.noTexture = true
--Module.noTab = true

local colors = {
    tag = "00ffff", -- cyan
    number = "ff7f7f", -- pink
    modifier = "00ff00", -- green
    literal = "ff7f7f", -- pink
    operator = "ff7fff", -- fuchsia
    grouping = "ffffff", -- white
    kwarg = "ff0000", -- red
    result = "ffffff", -- white
}

local extendedTags = {
	Duration = "Duration:TMWFormatDuration",
	Source = "Source:Name",
	Destination = "Destination:Name",
	Unit = "Unit:Name",
	PreviousUnit = "PreviousUnit:Name",
	Stacks = "Stacks:Hide(0)",
}

local function prepareEditBox(box)
	if not box.PreparedForDogTagInsertion then
		box:HookScript("OnEditFocusLost", function()
			DOGTAGS.AcceptingIcon = nil
		end)

		TMW.Classes.ChatEdit_InsertLink_Hook:New(box, function(self, text, linkType, linkData)
			-- if this editbox is active
			-- attempt to extract a TMW icon link and insert it into the box.

			if linkType == "TMW" then
				-- Reconstruct the GUID
				local GUID = linkType .. ":" .. linkData

				self.editbox:Insert(("%q"):format(GUID))

				-- notify success
				return true
			end
		end)

		box.PreparedForDogTagInsertion = true
	end

	DOGTAGS.AcceptingIcon = box
end

-- Finds the tag that the cursor is currently in, or at the end of.
local function getCurrentTag(editbox)
	for i = editbox:GetCursorPosition(), 1, -1 do
	    local t = editbox:GetText()
	    local color = t:match("^|cff(%x%x%x%x%x%x)", i)
	    
	    if color then
	    	local tokenType = TMW.tContains(colors, color)
	    	if tokenType == "tag" or tokenType == "modifier" then
		        local startPos, endPos = t:find("(.-)|cff", i+10)

		        if not endPos then
		            startPos, endPos = t:find("(.*)", i+10)
		        else
		            endPos = endPos - 4    

		       		local whitespace = t:match("([ \t\r\n]*)|cff", startPos) or ""

		       		-- If there is whitespace separating our cursor and the end of the tag that is being matched,
		       		-- don't match it so that a new suggestion list will be shown
		       		if (endPos - #whitespace < editbox:GetCursorPosition()) then
		       			return nil
		       		end

		        end
		        local tag = t:sub(startPos, endPos):trim()


		        return tag, startPos, endPos
		    else
		    	return nil
		    end
	    end
	end
end




function Module:OnSuggest()
	local frame = _G["LibDogTag-3.0_HelpFrame"]
	local wasShown = frame and frame:IsShown()
	DogTag:OpenHelp()
	if not wasShown then
		_G["LibDogTag-3.0_HelpFrame"]:Hide()
	end

	prepareEditBox(SUG.Box)
end

function Module:GetStartEndPositions(isClick)
	local currentTag, startPos, endPos = getCurrentTag(SUG.Box)

	if currentTag then
		SUG.startpos = startPos
		SUG.endpos = endPos
	else
		SUG.startpos = SUG.Box:GetCursorPosition()
		SUG.endpos = SUG.startpos
	end
end


function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local currentTag = getCurrentTag(SUG.Box)

	for namespaceName, namespace in pairs(DogTag.Tags) do
		if currentTag or namespaceName == "TMW" then
			for tagName, tagData in pairs(namespace) do
				if not tagData.noDoc and (not currentTag or tagName:lower():find(SUG.lastName)) then
					suggestions[#suggestions + 1] = tagName
					if extendedTags[tagName] then
						suggestions[#suggestions + 1] = extendedTags[tagName]
					end
				end
			end
		end
	end

	TMW.tRemoveDuplicates(suggestions)
end

function Module:Entry_Insert(insert)
	if insert then
		insert = tostring(insert)

		local tag, startPos, endPos = getCurrentTag(SUG.Box)
		if tag then
			-- determine the text before an after where we will be inserting to
			local currenttext = SUG.Box:GetText()
			local start = startPos-1
			local firsthalf = start > 0 and strsub(currenttext, 0, start) or ""
			local lasthalf = strsub(currenttext, SUG.endpos+1)


			-- the entire text with the insertion added in
			local newtext = firsthalf .. insert .. " " .. lasthalf

			SUG.Box:SetText(newtext)

			SUG.Box:SetCursorPosition(#(firsthalf .. insert))
		else
			insert = "[" .. insert .. "] "
			SUG.Box:Insert(insert)
		end

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
end

function Module:Entry_AddToList_1(f, tagName)

	-- I have no idea why, but sometimes tagName isn't a string (usually its a number when this happens).
	-- I haven't been able to reproduce it on demand, and it isn't critical, so just return earlier if it happens.
	if type(tagName) ~= "string" then
		return
	end
	
	local tag = "[" .. tagName .. "]"
	local colorized = DogTag:ColorizeCode(tag)
	
	f.Name:SetText(colorized)
	
	f.insert = tagName
	f.overrideInsertName = L["SUG_INSERTTEXTSUB"]
	
	f.tooltipmethod = "TMW_SetDogTag"
	f.tooltiparg = tagName
end
function Module.Sorter(a, b)
	if Module.currentTagAtStart then
		local aMatchesStart = a:lower():find(Module.currentTagAtStart)
		local bMatchesStart = b:lower():find(Module.currentTagAtStart)

		if aMatchesStart or bMatchesStart then
			if aMatchesStart and bMatchesStart then
				return a < b
			else
				return aMatchesStart
			end
		end
	end

	return a < b
end
function Module:Table_GetSorter()
	local currentTag = getCurrentTag(SUG.Box)
	Module.currentTagAtStart = currentTag and "^" .. getCurrentTag(SUG.Box):lower() or nil

	return self.Sorter
end





local function generateArgFormattedTagString(tag, tagData)
	local t = DogTag.newList()
	t[#t+1] = "["
	t[#t+1] = tag
	local arg = tagData.arg
	if arg then
		t[#t+1] = "("
		for i = 1, #arg, 3 do
			if i > 1 then
				t[#t+1] = ", "
			end
			local argName, argTypes, argDefault = arg[i], arg[i+1], arg[i+2]
			t[#t+1] = argName
			if argName ~= "..." and argDefault ~= "@req" then
				t[#t+1] = "="
				if argDefault == "@undef" then
					t[#t+1] = "undef"
				elseif argDefault == false then
					if argTypes:match("boolean") then
						t[#t+1] = "false"
					else
						t[#t+1] = "nil"
					end
				elseif type(argDefault) == "string" then
					t[#t+1] = ("%q"):format(argDefault)
				else
					t[#t+1] = tostring(argDefault)
				end
			end
		end
		t[#t+1] = ")"
	end
	t[#t+1] = "]"
	
	local retstring = DogTag:ColorizeCode(table.concat(t))
	t = DogTag.del(t)

	return retstring
end

function GameTooltip:TMW_SetDogTag(tagName)
	local tag = "[" .. tagName .. "]"
	local colorized = DogTag:ColorizeCode(tag)
		
	GameTooltip:AddLine(colorized, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
	GameTooltip:AddLine(" ", 1, 1, 1, false)
	
	local numTags = tagName:find(":") or 0
	local desc = ""
	
	for i, tag in TMW:Vararg(strsplit(":", tagName)) do
		tag = tag:gsub("%(.*%)", "") -- "Hide(0)" to "Hide"
	
		local tagData = DogTag.Tags.TMW[tag]
		local ns = "TMW"
		local doc
		
		if not tagData then
			for namespaceName, namespace in pairs(DogTag.Tags) do
				for tagName, _tagData in pairs(namespace) do
					if not _tagData.noDoc and tag == tagName then
						tagData = _tagData
						doc = tagData.doc
						ns = namespaceName
						break
					end
				end
				if doc then
					break
				end
			end
		else
			doc = tagData.doc
		end
		if not tagData then
			TMW:Debug("NO TAG DATA FOR TAG %s", tag)
		else
			local tag_colorized = generateArgFormattedTagString(tag, tagData)
		
			if tag_colorized then
				GameTooltip:AddLine(tag_colorized .. " |cff888888- " .. ns .. "", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, false)
				GameTooltip:AddLine(doc or "<???>", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)

				for i, v in TMW:Vararg((";"):split(tagData.example)) do
					local tag, result = v:trim():match("^(.*) => \"(.*)\"$")
					result = "\"|cffffffff" .. result .. "\""

					local example = "   • " .. DogTag:ColorizeCode(tag) .. " => " .. result
					GameTooltip:AddLine(example, 1, 1, 1, false)
				end
			end
			if i ~= numTags then
				GameTooltip:AddLine(" ", 1, 1, 1, false)
			end
		end
	end
end




---------- TMW:TestDogTagString ----------
do
	local EvaluateError

	local function test(success, ...)
		if success then
			local arg1, arg2 = ...
			local numArgs = select("#", ...)
			if numArgs == 2 and arg2 == nil and type(arg1) == "string" then
				return arg1
			end
		end
	end

	if DogTag and DogTag.tagError then
		hooksecurefunc(DogTag, "tagError", function(_, _, text)
			EvaluateError = text
		end)
	end

	-- Tests a dogtag string. Returns a string if there is an error.
	function TMW:TestDogTagString(icon, text, ns, kwargs)
		--icon:Setup()
		
		ns = ns or "TMW;Unit;Stats"
		kwargs = kwargs or {
			icon = icon.ID,
			group = icon.group.ID,
			unit = icon.attributes.dogTagUnit,
		}

		-- Test the string and its tags & syntax

		-- These operations are required when passing true as the 4th param (notDebug)
		-- notDebug has to be true because otherwise DogTag will throw errors if the
		-- user's input contains newlines. 
		local kwargTypes = DogTag.kwargsToKwargTypes[kwargs]
		ns = DogTag.fixNamespaceList[ns]

		local funcString = DogTag:CreateFunctionFromCode(text, ns, kwargs, true)
		local func = loadstring(funcString)
		local success, newfunc = pcall(func)

		if not success then
			return "CRITICAL ERROR: " .. newfunc
		end

		func = func and success and newfunc

		if not func then
			return
		end

		local tagError = test(pcall(func, kwargs))

		if tagError then
			return "ERROR: " .. tagError
		else
			EvaluateError = nil
			DogTag:Evaluate(text, ns, kwargs)

			if EvaluateError then
				return "CRITICAL ERROR: " .. EvaluateError
			end
		end
	end
end