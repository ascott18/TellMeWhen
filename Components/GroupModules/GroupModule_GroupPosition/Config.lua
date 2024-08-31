-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache

TMW.Classes.SharableDataType.types.group:RegisterMenuBuilder(10, function(Item_group)
	local gs = Item_group.Settings
	local IMPORTS, EXPORTS = Item_group:GetEditBox():GetAvailableImportExportTypes()

	-- copy group position
	local info = TMW.DD:CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["COPYPOSSCALE"]
	info.func = function()
		TMW.DD:CloseDropDownMenus()
		local destgroup = IMPORTS.group_overwrite
		local destgs = destgroup:GetSettings()
		
		-- Restore all default settings first.
		-- Not a special table (["**"]), so just normally copy it.
		-- Setting it nil won't recreate it like other settings tables, so re-copy from defaults.
		destgs.Point = CopyTable(TMW.Group_Defaults.Point)
		
		TMW:CopyTableInPlaceUsingDestinationMeta(gs.Point, destgs.Point, true)

		destgs.Scale = gs.Scale or TMW.Group_Defaults.Scale
		destgs.Level = gs.Level or TMW.Group_Defaults.Level
		destgs.Strata = gs.Strata or TMW.Group_Defaults.Strata
		
		destgroup:Setup()
	end
	info.notCheckable = true
	info.disabled = not IMPORTS.group_overwrite
	TMW.DD:AddButton(info)
end)

local Module = SUG:NewModule("frameName", SUG:GetModule("default"))
Module.noTexture = true
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
function Module:OnInitialize()
	self.Table = {}
end
function Module:OnSuggest()
	wipe(self.Table)
	
	local frame = EnumerateFrames()
	while frame do
		local name = frame:GetName()
		if name 
		and _G[name] == frame 
		and frame:GetNumPoints() > 0 
		and frame:GetHeight() > 0 
		and frame:GetWidth() > 0 
		and not frame:IsForbidden()
		then
			self.Table[frame] = name
		end
		frame = EnumerateFrames(frame)
	end
end
function Module:Table_Get()
	return self.Table
end
function Module:Table_GetNormalSuggestions(suggestions, tbl)
	local atBeginning = SUG.atBeginning
	local strfindsug = SUG.strfindsug
	local lastName = SUG.lastName
	
	for frame, name in pairs(tbl) do
		if frame.class == TMW.C.Group then
			if (
				-- Search by group name
				strfind(strlowerCache[frame:GetGroupName()], lastName)
				-- and by frame name for fun
				or strfind(strlowerCache[name], lastName)
				-- If the input is already a TMW group or is UIParent, list all TMW groups
				or strfind(lastName, "tmw:group")
				or strfind(lastName, "uiparent")
			) 
			-- Don't suggest the current group
			and TMW.CI.group ~= frame
			then
				suggestions[#suggestions + 1] = frame
			end
		elseif strfind(strlowerCache[name], lastName) then
			suggestions[#suggestions + 1] = frame
		else
			local secure, addon = issecurevariable(name)
			if secure then
				addon = "Blizzard"
			end
			if not secure and strfindsug(strlowerCache[addon]) then
				suggestions[#suggestions + 1] = frame
			end
		end
	end
end

function Module.Sorter_ByName(a, b)
	local nameA, nameB = SUG.SortTable[a], SUG.SortTable[b]
	return nameA < nameB
end
function Module:Sorter_Bucket(suggestions, buckets)
	local atBeginning = SUG.atBeginning
	local lastName_unmodified = SUG.lastName_unmodified
	for i = 1, #suggestions do
		local frame = suggestions[i]
		local parent = frame

		local depth = 0
		while parent do
			depth = depth + 1
			parent = parent:GetParent()
		end

		local name = self.Table[frame]
		if strlowerCache[name] == lastName_unmodified then
			-- Exact matches first
			depth = -2
		elseif frame.class == TMW.C.Group then
			if strfind(SUG.lastName, frame:GetGUID():lower()) then
				-- Exact matches first (look for the GUID in the input string, which also contains the group's name and some color escapes)
				depth = -2
			else
				-- Other TMW groups come next.
				depth = -1
			end
		elseif name and strfind(strlowerCache[name], atBeginning) then
			-- Make starts-with matches worth slightly more
			depth = depth - 1
		end

		tinsert(buckets[depth], frame)
	end
end

function Module:Table_GetSorter()
	SUG.SortTable = self:Table_Get()
	return self.Sorter_ByName, self.Sorter_Bucket
end

local highlight = CreateFrame("Frame")
highlight:SetFrameStrata("FULLSCREEN_DIALOG")
local texture = highlight:CreateTexture(nil, "OVERLAY")
texture:SetAllPoints()
texture:SetColorTexture(1, 0, .66, 0.5)
GameTooltip:HookScript("OnHide", function() 
	highlight:Hide()
end)
local function SetFrameHighlight(_, frame)
	highlight:ClearAllPoints()
	if frame:IsAnchoringRestricted() then
		highlight:Hide()
		return
	end

	-- Don't highlight UIParent or other fullscreen frames, it gets annoying.
	local p1, r1, rp1, x1, y1 = frame:GetPoint(1)
	local p2, r2, rp2, x2, y2 = frame:GetPoint(2)
	if 
		not frame:IsAnchoringRestricted() and
		(not r1 or r1 == UIParent) and p1 == "TOPLEFT" and rp1 == "TOPLEFT" and x1 == 0 and y1 == 0 and
		(not r2 or r2 == UIParent) and p2 == "BOTTOMRIGHT" and rp2 == "BOTTOMRIGHT" and x2 == 0 and y2 == 0 
	then
		highlight:Hide()
	else
		highlight:SetAllPoints(frame)
		highlight:Show()
	end
end

function Module:Entry_AddToList_1(f, frame)

	if frame.class == TMW.C.Group then 
		local group = frame
		local name = group:GetGroupName()

		f.insert = group:GetGUID()

		f.Background:SetVertexColor(.41, .8, .94, 1)
		f.tooltiptitlewrap = false
		f.tooltiptitle = name
		f.tooltiptext = "TellMeWhen"
		f.Name:SetText(name)
	else
		local name = frame:GetName()

		f.insert = name

		f.tooltiptitlewrap = false
		f.tooltiptitle = name
		local secure, addon = issecurevariable(name)
		if secure then
			addon = "Blizzard"
		end
		f.tooltiptext = L["SUG_MODULE_FRAME_LIKELYADDON"]:format(addon)

		f.Name:SetText(name)
	end

	f.tooltipmethod = SetFrameHighlight
	f.tooltiparg = {frame}
end