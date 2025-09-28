-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local _G, strmatch, tonumber, ipairs, pairs, next, type, tinsert, pcall, format, error, wipe =
	  _G, strmatch, tonumber, ipairs, pairs, next, type, tinsert, pcall, format, error, wipe

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))


local Type = TMW.Classes.IconType:New("meta")
Type.name = L["ICONMENU_META"]
Type.desc = L["ICONMENU_META_DESC"]
Type.menuIcon = "Interface\\AddOns\\TellMeWhen\\Textures\\levelupicon-lfd"
Type.AllowNoName = true
Type.canControlGroup = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state_metaChild")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


-- Not automatically generated. We need these declared so that the meta icon will
-- still have things like stack and duration min/max settings.
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("stack, stackText")


-- Disallow these modules. Their appearance and settings are inherited from the icon that the meta icon is displaying.
Type:SetModuleAllowance("IconModule_PowerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_BarDisplay", false)
Type:SetModuleAllowance("IconModule_Texts", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)




Type:RegisterIconDefaults{
	-- Sort meta icons found by their duration
	Sort						= false,

	-- Expand sub-metas. Causes the meta icon to expand any meta icons it is checking into that meta icon's component icons.
	-- Also prevents any other meta icon with this setting enabled from showing the icon that this meta icon is showing.
	CheckNext					= false,

	-- List of icons and groups that the meta icon is checking.
	Icons						= {
		[1]						= "",
	},   
}


TMW:RegisterUpgrade(70042, {
	icon = function(self, ics)
		-- Metas now always inherit whatever the alpha of their child is,
		-- regardless of where it came from. This setting has been removed.
		ics.MetaInheritConditionAlpha = nil
	end,
})

TMW:RegisterUpgrade(24100, {
	icon = function(self, ics)
		if ics.Type == "meta" and type(ics.Icons) == "table" then
			--make values the data, not the keys, so that we can customize the order that they are checked in
			for k, v in pairs(ics.Icons) do
				tinsert(ics.Icons, k)
				ics.Icons[k] = nil
			end
		end
	end,
})





-- IDP that works with TMW's state arbitrator to inherit the state of the icon that it is replicating.
local Processor = TMW.Classes.IconDataProcessor:New("STATE_METACHILD", "state_metaChild")
Processor.dontInherit = true
Processor:RegisterAsStateArbitrator(50, nil, true)

Processor:PostHookMethod("OnUnimplementFromIcon", function(self, icon)
	icon:SetInfo("state_metaChild", nil)
end)






------- Recursive Icon Ref Detector -------
-- This works by recursively going through all meta icon references of an icon.
-- If there is recursive reference, it will stack overflow. We grab this error
-- and then tell the user that it happened.

local CCI_icon
local function CheckCompiledIcons(icon)
	CCI_icon = icon
	for _, iconGUID in pairs(icon.CompiledIcons) do
		local ic = TMW.GUIDToOwner[iconGUID]
		if ic and ic.CompiledIcons and ic.Type == "meta" and ic.Enabled then
			CheckCompiledIcons(ic)
		end
	end
end

TMW:RegisterCallback("TMW_GLOBAL_UPDATE_POST", function()
	for _, icon in pairs(Type.Icons) do
		icon.NextUpdateTime = 0
		
		local success, err = pcall(CheckCompiledIcons, icon)
		if err and err:find("stack overflow") then
			local err = format("Meta icon recursion was detected in %s - there is an endless loop between the icon and its sub icons.", CCI_icon:GetName())
			TMW:Error(err)
			TMW:Warn(err)
		end
	end
end)


-- Collect icon dependencies for meta icons
TMW:RegisterCallback("TMW_COLLECT_ICON_DEPENDENCIES", function(event, icon, dependencies)
	if icon.Type == "meta" and icon.CompiledIcons then
		-- Add all compiled icon dependencies to the dependencies table
		for _, GUID in pairs(icon.CompiledIcons) do
			tinsert(dependencies, GUID)
		end
	end
end)






------- Helper Callback Handlers -------

-- Handle copying of animations when they are triggered
if TMW.EVENTS:GetEventHandler("Animations") then
	TMW:RegisterCallback("TMW_ICON_META_INHERITED_ICON_CHANGED", function(event, icon, icToUse)
		if icon:Animations_Has() then
			for k, v in next, icon:Animations_Get() do
				if v.originIcon ~= icon then
					icon:Animations_Stop(v)
				end
			end
		end
		if icToUse:Animations_Has() then
			for k, v in next, icToUse:Animations_Get() do
				icon:Animations_Start(v)
			end
		end
	end)
	
	TMW:RegisterCallback("TMW_ICON_ANIMATION_START", function(event, icon, table)
		-- Inherit animations
		local Icons = Type.Icons
		for i = 1, #Icons do
			local icon_meta = Icons[i]
			if icon_meta.__currentIcon == icon then
				icon_meta:Animations_Start(table)
			end
		end
	end)
end






------- Update Functions -------

local CompileIcons

-- Event handler for meta icons
local function Meta_OnEvent(icon, event, arg1)
	if event == "TMW_ICON_UPDATED" then
		-- Check if this updated icon is one that we're monitoring
		local GUID = arg1:GetGUID()
		if icon.IconsLookup and icon.IconsLookup[GUID] then
			icon.UpdatedIcons[arg1] = true
			icon.NextUpdateTime = 0
		end
	elseif event == "TMW_ICON_SETUP_POST" or event == "TMW_GROUP_SETUP_POST" then
		-- Re-compile icons when dependencies are setup
		local GUID = arg1:GetGUID()
		if icon.IconsLookup and icon.IconsLookup[GUID] then
			icon.UpdatedIcons[arg1] = true
			CompileIcons(icon)
			icon.NextUpdateTime = 0
		end
	end
end

local huge = math.huge
local function Meta_OnUpdate(icon, time)
	local Sort, CheckNext, CompiledIcons = icon.Sort, icon.CheckNext, icon.CompiledIcons

	local icToUse
	local curSortDur = Sort == -1 and huge or 0

	for n = 1, #CompiledIcons do
		local GUID = CompiledIcons[n]
		local ic = TMW.GUIDToOwner[GUID]
		
		local attributes = ic and ic.attributes

		if	ic
			and ic.Enabled
			and attributes.shown
			and attributes.realAlpha > 0
			and not (CheckNext and ic.__lastMetaCheck == time)
			and ic.viewData == icon.viewData
		then
			if Sort then
				-- See if we can use this icon due to sorting.
				local dur = (attributes.duration - (time - attributes.start)) / (attributes.modRate or 1)
				if dur < 0 then
					dur = 0
				end
				if not icToUse or curSortDur*Sort < dur*Sort then
					icToUse = ic
					curSortDur = dur
				end
			else
				if not icon:YieldInfo(true, ic) then
					-- icon:YieldInfo() returns false if we don't need to keep harvesting icons to use.
					break
				end
			end
		end
	end

	if icToUse then
		-- This only happens if the meta icon is sorting.
		icon:YieldInfo(true, icToUse)
	else
		-- Signal that we have ran out of icons to find.
		icon:YieldInfo(false)
	end

	wipe(icon.UpdatedIcons)
end

function Type:HandleYieldedInfo(icon, iconToSet, icToUse)
	if icToUse then
		local dataSource, moduleSource = icToUse, icToUse

		-- If we are displaying another meta icon,
		-- look at that meta icon until we find the non-meta icon that is being displayed at whatever depth,
		-- and use that as the source of the modules that we will set, instead of the meta icon itself.
		while moduleSource.Type == "meta" and moduleSource.__metaModuleSource do
			moduleSource = moduleSource.__metaModuleSource
		end

		local needUpdate = false

		if moduleSource ~= iconToSet.__metaModuleSource then
			
			iconToSet:SetModulesToEnabledStateOfIcon(moduleSource)
			iconToSet:SetupAllModulesForIcon(moduleSource)
			
			needUpdate = true

			iconToSet.__metaModuleSource = moduleSource
		end
		
		if dataSource ~= iconToSet.__currentIcon then

			TMW:Fire("TMW_ICON_META_INHERITED_ICON_CHANGED", iconToSet, dataSource)
			
			needUpdate = true

			iconToSet.__currentIcon = dataSource
		end

		-- Record that the icon has been shown in a meta icon for this update cycle
		-- so that no other CheckNext meta icons try to show it.
		dataSource.__lastMetaCheck = TMW.time

		if needUpdate or icon.UpdatedIcons[dataSource] then
			-- Inherit the alpha of the icon. Don't SetInfo_INTERNAL here because the
			-- call to :InheritDataFromIcon might not call TMW_ICON_UPDATED
			iconToSet:SetInfo("state_metaChild", dataSource.attributes.calculatedState)

			iconToSet:InheritDataFromIcon(dataSource)
		end

	elseif iconToSet.attributes.realAlpha ~= 0 then
		-- Nothing to show - hide the meta icon.
		iconToSet:SetInfo("state; state_metaChild; start, duration",
			0,
			nil,
			0, 0
		)
	end
end






------- Icon Table Management -------

local InsertIcon, GetFullIconTable -- both need access to eachother, so scope them above their definitions

local alreadyinserted = {}
function InsertIcon(icon, GUID, ics)
	if not GUID then
		error("GUID missing to InsertIcon call!")
	elseif GUID and GUID == icon:GetGUID() then
		-- Meta icons should not check themselves.
		return 
	end

	if not ics then
		ics = TMW:GetSettingsFromGUID(GUID)
	end

	if ics then
		if ics.Type ~= "meta" or not icon.CheckNext then
			alreadyinserted[GUID] = true

			--if ics.Enabled then
				tinsert(icon.CompiledIcons, GUID)
			--end
		elseif icon.CheckNext then
			GetFullIconTable(icon, ics.Icons)
		end
	end
end


-- Compile a table of all the possible icons a meta icon can show.
-- All meta icons use this, but it is especially useful for use with setting CheckNext.
function GetFullIconTable(icon, icons) 
	local thisIconsView = icon.group.viewData.view
	
	for _, GUID in ipairs(icons) do
		if not alreadyinserted[GUID] then
			alreadyinserted[GUID] = true

			local type = TMW:ParseGUID(GUID)

			if type == "icon" then
				-- If it's an icon, then just stick it in.
				InsertIcon(icon, GUID)
			elseif type == "group" then
				-- If it's a group, then get all of the group's icons and stick those in.
				local gs, group, domain, groupID = TMW:GetSettingsFromGUID(GUID)

				if gs and not group then
					group = TMW[domain][groupID]
				end

				if group and group:ShouldUpdateIcons() and gs.View == thisIconsView then

					for ics, _, _, _, icID in group:InIconSettings() do
						if icID <= gs.Rows*gs.Columns then
							local ic = group[icID]
							
							if ic and ic.Enabled then
								local GUID = ic:GetGUID()
								if not alreadyinserted[GUID] then
									InsertIcon(icon, GUID, ics)
								end
							end
						end
					end
				end
			end
		end
	end

	return icon.CompiledIcons
end

function CompileIcons(icon)
	wipe(alreadyinserted)
	icon.CompiledIcons = wipe(icon.CompiledIcons or {})
	icon.CompiledIcons = GetFullIconTable(icon, icon.Icons)
	
	icon.IconsLookup = wipe(icon.IconsLookup or {})
	for n, GUID in pairs(icon.CompiledIcons) do
		icon.IconsLookup[GUID] = n
	end
	for _, GUID in pairs(icon.Icons) do 
		-- make sure to get meta icons in the table even if they get expanded.
		-- this will also include items that weren't yet setup when we did GetFullIconTable
		icon.IconsLookup[GUID] = icon.IconsLookup[GUID] or true
	end
	icon.NextUpdateTime = 0
end





------- Required IconType methods -------

function Type:Setup(icon)
	icon.__currentIcon = nil -- reset this
	icon.__metaModuleSource = nil -- reset this

	-- validity check:
	if icon.Enabled then
		for i, icGUID in pairs(icon.Icons) do
			-- Don't warn about nils or blanks - these are totally harmless.
			if icGUID and icGUID ~= "" then
				TMW:QueueValidityCheck(icon, icGUID, L["VALIDITY_META_DESC"], i)
			end
		end
	end
	
	-- Holds the set of constituent icons that we had update event triggers
	-- for since the last update. Prevents doing a redundant SetInfo() call
	-- if we didn't change the data source. Ensures we DO a SetInfo() if the
	-- unchanged data source had attribute updates we need to copy.
	icon.UpdatedIcons = {}

	CompileIcons(icon)

	icon:SetInfo("state; texture", 
		0, 
		"Interface\\AddOns\\TellMeWhen\\Textures\\levelupicon-lfd"
	)
	
	-- Setup event-driven updates
	if icon.CheckNext then
		-- If Expand sub-metas is enabled, we have to also trigger on any meta source change
		-- because any other random meta icon in TMW could affect and shift around
		-- which icon gets chosen by this icon.
		-- TODO: Consider deleting this option since group controllers exist now.
		icon:RegisterSimpleUpdateEvent("TMW_ICON_META_INHERITED_ICON_CHANGED")
	end
	icon:SetUpdateMethod("manual")
	icon:SetScript("OnEvent", Meta_OnEvent)
		
	icon:RegisterEvent("TMW_ICON_UPDATED")
	icon:RegisterEvent("TMW_ICON_SETUP_POST")
	icon:RegisterEvent("TMW_GROUP_SETUP_POST")

	if icon:IsGroupController() then
		icon.Sort = false
		for ic in icon.group:InIcons() do
			ic.__currentIcon = nil -- reset this
			ic.__metaModuleSource = nil -- reset this
		end
	end
		
	icon:SetUpdateFunction(Meta_OnUpdate)
end

function Type:OnGCD(icon, duration)
	if not icon.__metaModuleSource then
		return false
	end

	return icon.__metaModuleSource:OnGCD(duration)
end


Type:Register(310)