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

local DOGTAGS = TMW:NewModule("DogTags")
TMW.DOGTAGS = DOGTAGS


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
Module.noTab = true

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

function Module:OnSuggest()
	local frame = _G["LibDogTag-3.0_HelpFrame"]
	local wasShown = frame and frame:IsShown()
	DogTag:OpenHelp()
	if not wasShown then
		_G["LibDogTag-3.0_HelpFrame"]:Hide()
	end

	prepareEditBox(SUG.Box)
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	for namespaceName, namespace in pairs(DogTag.Tags) do
		if namespaceName == "TMW" then
			for tagName, tagData in pairs(namespace) do
				if not tagData.noDoc
				and tagData.category ~= L["TEXTMANIP"]
				then
					suggestions[#suggestions + 1] = tagName
				end
			end
		end
	end
	
	suggestions[#suggestions + 1] = "Duration:TMWFormatDuration"
	suggestions[#suggestions + 1] = "Source:Name"
	suggestions[#suggestions + 1] = "Destination:Name"
	suggestions[#suggestions + 1] = "Unit:Name"
	suggestions[#suggestions + 1] = "PreviousUnit:Name"
	suggestions[#suggestions + 1] = "Stacks:Hide(0)"
end
function Module:Entry_Insert(insert)
	if insert then
		insert = tostring(insert)
		SUG.Box:Insert(insert)

		-- attempt another suggestion (it will either be hidden or it will do another)
		SUG:NameOnCursor(1)
	end
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
function Module:Entry_AddToList_1(f, tagName)

	-- I have no idea why, but sometimes tagName isn't a string (usually its a number when this happens).
	-- I haven't been able to reproduce it on demand, and it isn't critical, so just return earlier if it happens.
	if type(tagName) ~= "string" then
		return
	end
	
	local tag = "[" .. tagName .. "]"
	local colorized = DogTag:ColorizeCode(tag)
	
	f.Name:SetText(colorized)
	
	f.insert = tag
	f.overrideInsertName = L["SUG_INSERTTEXTSUB"]
	
	f.tooltiptitle = colorized
	
	local numTags = tagName:find(":") or 0
	--if (tagName:find(":") or 0) > 0 then
		local desc = ""
		
		for i, tag in TMW:Vararg(strsplit(":", tagName)) do
			tag = tag:gsub("%(.*%)", "") -- "Hide(0)" to "Hide"
		
			local tagData = DogTag.Tags.TMW[tag]
			local doc
			
			if not tagData then
				for namespaceName, namespace in pairs(DogTag.Tags) do
					for tagName, _tagData in pairs(namespace) do
						if not _tagData.noDoc and tag == tagName then
							tagData = _tagData
							doc = tagData.doc
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
			end
			local tag_colorized = tagData and generateArgFormattedTagString(tag, tagData)
			
			if tag_colorized then
				desc = desc .. "\r\n" .. tag_colorized .. "\r\n" .. (doc or "<???>")
			end
			if i ~= numTags then
				desc = desc .. "\r\n"
			end
		end
		
		f.tooltiptext = desc
	--else
	--	f.tooltiptext = DogTag.Tags.TMW[tagName].doc
	--end
end
function Module.Sorter(a, b)
	return a < b
end
function Module:Table_GetSorter()
	return self.Sorter
end

