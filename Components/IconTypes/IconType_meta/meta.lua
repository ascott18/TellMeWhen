-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))

local _G, strmatch, tonumber, ipairs, pairs, next =
	  _G, strmatch, tonumber, ipairs, pairs, next
local print = TMW.print
local Locked



local Type = TMW.Classes.IconType:New("meta")
Type.name = L["ICONMENU_META"]
Type.desc = L["ICONMENU_META_DESC"]
Type.menuIcon = "Interface\\Icons\\LevelUpIcon-LFD"
Type.AllowNoName = true
Type.NoColorSettings = true
Type.canControlGroup = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("alpha_metaChild")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("stack, stackText")

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_TimerBar_BarDisplay", false)
Type:SetModuleAllowance("IconModule_Texts", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)

Type:RegisterIconDefaults{
	Sort						= false,
	CheckNext					= false,
	Icons						= {
		[1]						= "",
	},   
}

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_MetaIconOptions")

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_MetaSortSettings", {
	hidden = function(self)
		return TMW.CI.icon:IsGroupController()
	end,
})


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


local Processor = TMW.Classes.IconDataProcessor:New("ALPHA_METACHILD", "alpha_metaChild")
Processor.dontInherit = true
TMW.IconAlphaManager:AddHandler(50, "ALPHA_METACHILD", true)

Processor:PostHookMethod("OnUnimplementFromIcon", function(self, icon)
	icon:SetInfo("alpha_metaChild", nil)
end)


do	-- Check for recursive references
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
			icon.metaUpdateQueued = true
			
			local success, err = pcall(CheckCompiledIcons, icon)
			if err and err:find("stack overflow") then
				local err = format("Meta icon recursion was detected in %s - there is an endless loop between the icon and its sub icons.", CCI_icon:GetName())
				TMW:Error(err)
				TMW.Warn(err)
			end
		end
	end)
end




local huge = math.huge
local function Meta_OnUpdate(icon, time)
	local Sort, CheckNext, CompiledIcons = icon.Sort, icon.CheckNext, icon.CompiledIcons

	local icToUse
	local d = Sort == -1 and huge or 0

	for n = 1, #CompiledIcons do
		local GUID = CompiledIcons[n]
		local ic = TMW.GUIDToOwner[GUID]
		
		local attributes = ic and ic.attributes

		if	ic
			and ic.Enabled
			and attributes.shown
			and not (CheckNext and ic.__lastMetaCheck == time)
			and ic.viewData == icon.viewData
		then
			ic:Update()
			if attributes.realAlpha > 0 and attributes.shown then -- make sure to re-check attributes.shown (it might have changed from the ic:Update() call)
				if Sort then
					local _d = attributes.duration - (time - attributes.start)
					if _d < 0 then
						_d = 0
					end
					if not icToUse or d*Sort < _d*Sort then
						icToUse = ic
						d = _d
					end
				else
					if not icon:YieldInfo(true, ic) then
						break
					end
				end
			else
				ic.__lastMetaCheck = time
			end
		end
	end

	if icToUse then
		icon:YieldInfo(true, icToUse)
	else
		icon:YieldInfo(false)
	end

	icon.metaUpdateQueued = nil
end

function Type:HandleInfo(icon, iconToSet, icToUse)
	if icToUse then
		local dataSource, moduleSource = icToUse, icToUse
		while moduleSource.Type == "meta" and moduleSource.__metaModuleSource do
			moduleSource = moduleSource.__metaModuleSource
		end

		local force

		if moduleSource ~= iconToSet.__metaModuleSource then
			
			iconToSet:SetModulesToEnabledStateOfIcon(moduleSource)
			iconToSet:SetupAllModulesForIcon(moduleSource)
			
			force = 1

			iconToSet.__metaModuleSource = moduleSource
		end
		
		if dataSource ~= iconToSet.__currentIcon then

			TMW:Fire("TMW_ICON_META_INHERITED_ICON_CHANGED", iconToSet, dataSource)
			
			force = 1

			iconToSet.__currentIcon = dataSource
		end

		dataSource.__lastMetaCheck = time

		if force or icon.metaUpdateQueued then

			-- Inherit the alpha of the icon. Don't SetInfo_INTERNAL here because the
			-- call to :InheritDataFromIcon might not call TMW_ICON_UPDATED
			iconToSet:SetInfo("alpha_metaChild", dataSource.attributes.realAlpha)

			iconToSet:InheritDataFromIcon(dataSource)
		end

	elseif iconToSet.attributes.realAlpha ~= 0 and icon.metaUpdateQueued then
		iconToSet:SetInfo("alpha; alpha_metaChild", 0, nil)
	end
end


local function TMW_ICON_UPDATED(icon, event, ic)
	local GUID = ic:GetGUID()
	if ic == icon or (GUID and icon.IconsLookup[GUID]) or icon.IconsLookup[ic] then
		icon.metaUpdateQueued = true
	end
end


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

function GetFullIconTable(icon, icons) -- check what all the possible icons it can show are, for use with setting CheckNext
	local thisIconsView = icon.group.viewData.view
	
	for _, GUID in ipairs(icons) do
		if not alreadyinserted[GUID] then
			alreadyinserted[GUID] = true

			local type = TMW:ParseGUID(GUID)

			if type == "icon" then
				InsertIcon(icon, GUID)
			elseif type == "group" then
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

function Type:OnGCD(icon, duration)
	if not icon.__metaModuleSource then
		return false
	end

	return icon.__metaModuleSource:OnGCD(duration)
end

function Type:Setup(icon)
	icon.__currentIcon = nil -- reset this
	icon.__metaModuleSource = nil -- reset this
	icon.metaUpdateQueued = true -- force this

	-- validity check:
	if icon.Enabled then
		for i, icGUID in pairs(icon.Icons) do
			TMW:QueueValidityCheck(icon, icGUID, L["VALIDITY_META_DESC"], i)
		end
	end

	wipe(alreadyinserted)
	icon.CompiledIcons = wipe(icon.CompiledIcons or {})
	icon.CompiledIcons = GetFullIconTable(icon, icon.Icons)
	
	icon.IconsLookup = wipe(icon.IconsLookup or {})
	for n, GUID in pairs(icon.CompiledIcons) do
		icon.IconsLookup[GUID] = n
	end
	for _, GUID in pairs(icon.Icons) do -- make sure to get meta icons in the table even if they get expanded
		icon.IconsLookup[GUID] = icon.IconsLookup[GUID] or true
	end

	--[[
	-- This breaks dynamic enabling/disabling of icons, so don't do it.
	local dontUpdate = true
	for _, GUID in pairs(icon.CompiledIcons) do
		local ics = TMW:GetSettingsFromGUID(GUID)
		if ics and ics.Enabled then
			dontUpdate = nil
			break
		end
	end]]

	icon:SetInfo("texture", "Interface\\Icons\\LevelUpIcon-LFD")
	
	-- DONT DO THIS! (manual updates) ive tried for many hours to get it working,
	-- but there is no possible way because meta icons update
	-- the icons they are checking from within them to check for changes,
	-- so everything will be delayed by at least one update cycle if we do manual updating.
	-- icon:SetUpdateMethod("manual") 
	
	icon:SetInfo("alpha", 0)

	if icon:IsGroupController() then
		icon.Sort = false
		for ic in icon.group:InIcons() do
			ic.__currentIcon = nil -- reset this
			ic.__metaModuleSource = nil -- reset this
		end
	end
		
	icon:SetUpdateFunction(Meta_OnUpdate)
	TMW:RegisterCallback("TMW_ICON_UPDATED", TMW_ICON_UPDATED, icon)

	icon.metaUpdateQueued = true
end


function Type:TMW_ICON_TYPE_CHANGED(event, icon, typeData, typeData_old)
	if self == typeData_old then
		TMW:UnregisterCallback("TMW_ICON_UPDATED", TMW_ICON_UPDATED, icon)
	end
end
TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", Type)

function Type:TMW_GLOBAL_UPDATE()
	Locked = TMW.Locked
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", Type)


TMW:RegisterCallback("TMW_EXPORT_SETTINGS_REQUESTED", function(event, strings, type, settings)
	if type == "icon" and settings.Type == "meta" then
		for k, GUID in pairs(settings.Icons) do
			if GUID ~= settings.GUID then
				local type = TMW:ParseGUID(GUID)
				local settings = TMW:GetSettingsFromGUID(GUID)
				if type == "icon" and settings then
					TMW:GetSettingsStrings(strings, type, settings, TMW.Icon_Defaults)
				end
			end
		end
	end
end)


Type:Register(310)