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

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes
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
	MetaInheritConditionAlpha	= false,
	Icons						= {
		[1]						= "",
	},   
}

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_MetaIconOptions")

Type:RegisterConfigPanel_ConstructorFunc(160, "TellMeWhen_MetaIconInheritanceBehavior", function(self)
	self.Header:SetText(TMW.L["ICONMENU_META_INHERITANCEBEHAVIOR"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 1,
		{
			setting = "MetaInheritConditionAlpha",
			title = L["ICONMENU_META_INHERITANCEBEHAVIOR_CNDTALPHA"],
			tooltip = L["ICONMENU_META_INHERITANCEBEHAVIOR_CNDTALPHA_DESC"],
			OnClick = function(self)
				if TMW.CI.ics.Conditions.n > 0 then
					if not self.hasRegisteredCode then
						self.hasRegisteredCode = true
						TMW.HELP:NewCode("META_INHERIT_CNDTALPHA", 100, true)
					end
				
					TMW.HELP:Show("META_INHERIT_CNDTALPHA", TMW.CI.ic, self, 0, 0, L["ICONMENU_META_INHERITANCEBEHAVIOR_CNDTALPHA_HELP"])
				end
			end,
		},
	})
end)

Type:RegisterConfigPanel_XMLTemplate(170, "TellMeWhen_MetaSortSettings")


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

do
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
		local v = CompiledIcons[n]
		-- values in CompiledIcons are either a string or a table, 
		-- so in either case, it is safe to index it for IsIcon to check if it is an icon:
		local ic = v.IsIcon and v or TMW.GUIDToOwner[CompiledIcons[n]]

		local attributes = ic and ic.attributes

		if	ic
			and ic.UpdateFunction
			and attributes.shown
			and not (CheckNext and ic.__lastMetaCheck == time)
			and ic.viewData == icon.viewData
		then
			ic:Update()
			
			if attributes.realAlpha > 0 and attributes.shown then -- make sure to re-check attributes.shown (it might have changed from 2 lines ago)
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
					icToUse = ic
					break
				end
			else
				ic.__lastMetaCheck = time
			end
		end
	end

	if icToUse then
		while icToUse.Type == "meta" and icToUse.__currentIcon do
			icToUse = icToUse.__currentIcon
		end
		
		local force
		
		if icToUse ~= icon.__currentIcon then

			TMW:Fire("TMW_ICON_META_INHERITED_ICON_CHANGED", icon, icToUse)
			
			icon:SetModulesToEnabledStateOfIcon(icToUse)
			icon:SetupAllModulesForIcon(icToUse)
			
			force = 1

			icon.__currentIcon = icToUse
		end

		icToUse.__lastMetaCheck = time
		if force or icon.metaUpdateQueued then
			icon.metaUpdateQueued = nil
			
			if icon.MetaInheritConditionAlpha then
				-- SetInfo_INTERNAL is OK here because we will call a normal SetInfo immediately after
				-- (well, at least InheritDataFromIcon does fire TMW_ICON_UPDATED, which is what matters).
				icon:SetInfo_INTERNAL("alpha_conditionFailed", icToUse.attributes.alpha_conditionFailed)
			end
			
			icon:InheritDataFromIcon(icToUse)
		end
	elseif icon.attributes.realAlpha ~= 0 and icon.metaUpdateQueued then
		icon.metaUpdateQueued = nil
		icon:SetInfo("alpha", 0)
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
function InsertIcon(icon, GUID, ic)
	if (GUID and GUID == icon:GetGUID()) or icon == ic then
		-- Meta icons should not check themselves.
		return 
	end

	local thing = GUID or ic

	local ics 
	if ic then
		ics = ic:GetSettings()
	elseif GUID then
		ics = TMW:GetSettingsFromGUID(GUID)
	else
		error("Must either provide a GUID or an icon to InsertIcon")
	end

	if ics then
		if ics.Type ~= "meta" or not icon.CheckNext then
			alreadyinserted[thing] = true
			if thing.IsIcon and thing:GetGUID() then
				alreadyinserted[thing:GetGUID()] = true
			end
			if ics.Enabled then
				tinsert(icon.CompiledIcons, thing)
			end
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
				InsertIcon(icon, GUID, nil)
			elseif type == "group" then
				local group = TMW.GUIDToOwner[GUID]
				
				local gs, group, groupID = TMW:GetSettingsFromGUID(GUID)

				if not group then
					group = TMW[groupID]
				end

				if group and group:ShouldUpdateIcons() then

					for ics, _, icID in TMW:InIconSettings(group.ID) do
						if ics.Enabled and icID <= gs.Rows*gs.Columns then
							local ic = group[icID]
							
							if ic then
								local GUID = ic:GetGUID()
								if not GUID or not alreadyinserted[GUID] then
									InsertIcon(icon, nil, ic)
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


function Type:Setup(icon, groupID, iconID)
	icon.__currentIcon = nil -- reset this
	icon.metaUpdateQueued = true -- force this

	-- validity check:
	for i, icGUID in pairs(icon.Icons) do
		TMW:QueueValidityCheck(icon, icGUID, L["VALIDITY_META_DESC"], i)
	end

	wipe(alreadyinserted)
	icon.CompiledIcons = wipe(icon.CompiledIcons or {})
	icon.CompiledIcons = GetFullIconTable(icon, icon.Icons)
	
	icon.IconsLookup = wipe(icon.IconsLookup or {})
	for _, iconOrGUID in pairs(icon.CompiledIcons) do
		icon.IconsLookup[iconOrGUID] = true
	end
	for _, GUID in pairs(icon.Icons) do -- make sure to get meta icons in the table even if they get expanded
		icon.IconsLookup[GUID] = true
	end

	local dontUpdate = true
	for _, iconOrGUID in pairs(icon.CompiledIcons) do

		if type(iconOrGUID) == "table" and iconOrGUID.IsIcon then
			-- iconOrGUID is an icon
			if iconOrGUID.Enabled then
				dontUpdate = nil
				break
			end
		else
			-- iconOrGUID is a GUID
			local ics = TMW:GetSettingsFromGUID(iconOrGUID)
			if ics and ics.Enabled then
				dontUpdate = nil
				break
			end
		end
	end

	icon:SetInfo("texture", "Interface\\Icons\\LevelUpIcon-LFD")
	
	-- DONT DO THIS! (manual updates) ive tried for many hours to get it working,
	-- but there is no possible way because meta icons update
	-- the icons they are checking from within them to check for changes,
	-- so everything will be delayed by at least one update cycle if we do manual updating.
	-- icon:SetUpdateMethod("manual") 
	
	icon:SetInfo("alpha", 0)
		
	if not dontUpdate then
		icon:SetUpdateFunction(Meta_OnUpdate)
		TMW:RegisterCallback("TMW_ICON_UPDATED", TMW_ICON_UPDATED, icon)
	end
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

Type:Register(310)