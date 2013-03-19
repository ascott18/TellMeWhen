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
	Sort					= false,
	CheckNext				= false,
	Icons					= {
		[1]					= "",
	},   
}

Type:RegisterConfigPanel_XMLTemplate(150, "TellMeWhen_MetaIconOptions")

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
		for _, ic in pairs(icon.CompiledIcons) do
			ic = _G[ic]
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
		local ic = _G[CompiledIcons[n]]
		local attributes = ic and ic.attributes
		if ic and ic.UpdateFunction and attributes.shown and not (CheckNext and ic.__lastMetaCheck == time) and ic.viewData == icon.viewData then
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
			icon:InheritDataFromIcon(icToUse)
		end
	elseif icon.attributes.realAlpha ~= 0 and icon.metaUpdateQueued then
		icon.metaUpdateQueued = nil
		icon:SetInfo("alpha", 0)
	end
end


local function TMW_ICON_UPDATED(icon, event, ic)
	if icon.IconsLookup[ic:GetName()] or ic == icon then
		icon.metaUpdateQueued = true
	end
end


if TMW.Classes.EventHandler.instancesByName.Animations then

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
function InsertIcon(icon, ics, ic)
	if ics.Type ~= "meta" or not icon.CheckNext then
		alreadyinserted[ic] = true -- we might not have inserted if ic isnt enabled, but pretend that we did so we dont have to check again
		if ics.Enabled then
			tinsert(icon.CompiledIcons, ic)
		end
	elseif icon.CheckNext then
		GetFullIconTable(icon, ics.Icons, icon.CompiledIcons)
	end
end

function GetFullIconTable(icon, icons) -- check what all the possible icons it can show are, for use with setting CheckNext
	local thisIconsView = icon.group.viewData.view
	
	for _, ic in ipairs(icons) do
		if not alreadyinserted[ic] then
			alreadyinserted[ic] = true

			local iconID = tonumber(strmatch(ic, "TellMeWhen_Group%d+_Icon(%d+)"))
			local groupID = tonumber(strmatch(ic, "TellMeWhen_Group(%d+)"))

			if groupID and TMW.db.profile.Groups[groupID].View == thisIconsView then
				if not iconID then -- a group. Expand it into icons.
					local group = TMW[groupID]
					
					if group and group:ShouldUpdateIcons() then
						local gs = group:GetSettings()

						for ics, _, icID in TMW:InIconSettings(groupID) do
							if ics.Enabled and icID <= gs.Rows*gs.Columns then
								-- ic here is a group name. turn it into an icon
								local ic = ic .. "_Icon" .. icID
								
								-- if a meta icon is set to check its own group, dont put the meta icon in there.
								if ic ~= icon:GetName() then
									InsertIcon(icon, ics, ic)
								end
							end
						end
					end

				else -- just an icon. put it in.
					InsertIcon(icon, TMW.db.profile.Groups[groupID].Icons[iconID], ic)
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
	for k, v in pairs(icon.Icons) do
		local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g) or 0, tonumber(i) or 0
		TMW:QueueValidityCheck(v, groupID, iconID, g, i)
	end

	wipe(alreadyinserted)
	icon.CompiledIcons = wipe(icon.CompiledIcons or {})
	icon.CompiledIcons = GetFullIconTable(icon, icon.Icons)
	
	icon.IconsLookup = wipe(icon.IconsLookup or {})
	for _, ic in pairs(icon.CompiledIcons) do
		icon.IconsLookup[ic] = true
	end
	for _, ic in pairs(icon.Icons) do -- make sure to get meta icons in the table even if they get expanded
		icon.IconsLookup[ic] = true
	end

	
	local dontUpdate = true
	for _, ic in pairs(icon.CompiledIcons) do
		-- ic might not exist, so we have to directly look up the settings
		local g, i = strmatch(ic, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g), tonumber(i)
		assert(g and i)
		if TMW.db.profile.Groups[g].Icons[i].Enabled then
			dontUpdate = nil
			break
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

TMW:RegisterCallback("TMW_CONFIG_ICON_RECONCILIATION_REQUESTED", function(event, replace, limitSourceGroup)
	for ics, groupID in TMW:InIconSettings() do
		if not limitSourceGroup or groupID == limitSourceGroup then
			for k, ic in pairs(ics.Icons) do
				if type(ic) == "string" then
					replace(ics.Icons, k)
				end
			end
		end
	end
end)

function Type:GetIconMenuText(ics, groupID, iconID)
	local text = Type.name .. " " .. L["ICONMENU_META_ICONMENUTOOLTIP"]:format(ics.Icons and #ics.Icons or 0)
	
	return text, "", true
end

function Type:GuessIconTexture(ics)
	return "Interface\\Icons\\LevelUpIcon-LFD"
end

Type:Register(310)