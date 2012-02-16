-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))

local db
local _G, strmatch, tonumber, ipairs, pairs, next =
	  _G, strmatch, tonumber, ipairs, pairs, next
local print = TMW.print
local Locked



local Type = TMW.Classes.IconType:New()
Type.type = "meta"
Type.name = L["ICONMENU_META"]
Type.desc = L["ICONMENU_META_DESC"]
Type.AllowNoName = true
Type.HideBars = true
Type.NoColorSettings = true
Type.RelevantSettings = {
	Icons = true,
	CheckNext = true,
	Name = false,
	BindText = false,
	CustomTex = false,
	ShowTimer = false,
	ShowTimerText = false,
	ShowWhen = false,
	Alpha = false,
	UnAlpha = false,
	Sort = true,
}

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

function Type:Update(after)
	db = TMW.db
	
	if after then
		for _, icon in pairs(Type.Icons) do
			local success, err = pcall(CheckCompiledIcons, icon)
			if err and err:find("stack overflow") then
				local err = format("Meta icon recursion was detected in %s - there is an endless loop between the icon and its sub icons.", CCI_icon:GetName())
				TMW:Error(err)
				TMW.Warn(err)
			end
		end
	end	
end




local huge = math.huge
local function Meta_OnUpdate(icon, time)
	local Sort, CheckNext, CompiledIcons = icon.Sort, icon.CheckNext, icon.CompiledIcons

	local icToUse
	local d = Sort == -1 and huge or 0

	for n = 1, #CompiledIcons do
		local ic = _G[CompiledIcons[n]]
		if ic and ic.OnUpdate and ic.__shown and not (CheckNext and ic.__lastMetaCheck == time) then
			ic:Update()
			if ic.__alpha > 0 and ic.__shown then
				if Sort then
					local _d = ic.__duration - (time - ic.__start)
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
		local force
		
		local icBindTextObj = icToUse.BindTextObj
		if icBindTextObj and icBindTextObj.hasAnySubstitutions then -- TODO: meta icons checking meta icons dont inherit properly here.
			icon.bindText:SetText(icToUse.bindText:GetText())
		end

		if icToUse ~= icon.__currentIcon or icToUse.__metaChangedTime == time then
			-- __metaChangedTime tracks changes to meta icons.
			-- we want to be sure to update a meta icon whenever it changes.
			-- Or something like that. Just keep this here, otherwise bad things happen
			icon.__metaChangedTime = time
			
			-- we check if either are nil so that the bind text will be properly reset (to blank or to static) when an icon changes.
			if not icBindTextObj or not icBindTextObj.hasAnySubstitutions then
				icon.bindText:SetText(icToUse.bindText:GetText())
			end
			
			TMW:Fire("TMW_ICON_META_INHERITED_ICON_CHANGED", icon, icToUse)

			if LMB then -- i dont like the way that Masque handles this (inefficient), so i'll do it myself
				local icnt = icToUse.normaltex -- icon.normaltex = icon.__LBF_Normal or icon:GetNormalTexture() -- set during icon:Setup()
				local iconnt = icon.normaltex
				if icnt and iconnt then
					iconnt:SetVertexColor(icnt:GetVertexColor())
				end
			end
			
			icon.pbar:SetAttributes(icToUse.pbar)
			icon.cbar:SetAttributes(icToUse.cbar)

			icon.ShowTimer = icToUse.ShowTimer
			icon.ShowTimerText = icToUse.ShowTimerText
			icon.cooldown.noCooldownCount = icToUse.cooldown.noCooldownCount
			icon.BindTextObj = icToUse.BindTextObj -- BE VERY FUCKING CAREFUL WITH THIS. dont call any methods on it - only setting it to obtain attributes

			force = 1

			icon.__currentIcon = icToUse
			TMW:Fire("TMW_ICON_UPDATED", icToUse)
			TMW:Fire("TMW_ICON_UPDATED", icon)
		end

		icToUse.__lastMetaCheck = time
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		if force or icon.metaUpdateQueued then
			icon.metaUpdateQueued = nil
			icon:SetInfo(icToUse.__alpha, icToUse.__vrtxcolor, icToUse.__tex, icToUse.__start, icToUse.__duration, icToUse.__spellChecked, icToUse.__reverse, icToUse.__count, icToUse.__countText, force, icToUse.__unitChecked)
		end
	elseif icon.__alpha ~= 0 and icon.metaUpdateQueued then
		icon.metaUpdateQueued = nil
		icon:SetInfo(0)
	end
end


local function TMW_ICON_UPDATED(icon, event, ic)
	if Locked and icon.IconsLookup[ic:GetName()] then
		icon.metaUpdateQueued = true
	end
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
	for _, ic in ipairs(icons) do
		if not alreadyinserted[ic] then
			alreadyinserted[ic] = true

			local iconID = tonumber(strmatch(ic, "TellMeWhen_Group%d+_Icon(%d+)"))
			local groupID = tonumber(strmatch(ic, "TellMeWhen_Group(%d+)"))

			if groupID and not iconID then -- a group. Expand it into icons.
				local group = TMW[groupID]

				if group:ShouldUpdateIcons() then
					local gs = group:GetSettings()

					for ics, _, icID in TMW:InIconSettings(groupID) do
						if ics.Enabled and icID <= gs.Rows*gs.Columns then
							-- ic here is a group name
							InsertIcon(icon, ics, ic .. "_Icon" .. icID)
						end
					end
				end

			elseif groupID and iconID then -- just an icon. put it in.
				InsertIcon(icon, db.profile.Groups[groupID].Icons[iconID], ic)
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

	if icon.CheckNext then
		TMW.DoWipeAC = true
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

	
	icon.ForceDisabled = true
	for _, ic in pairs(icon.CompiledIcons) do
		-- ic might not exist, so we have to directly look up the settings
		local g, i = strmatch(ic, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g), tonumber(i)
		assert(g and i)
		if db.profile.Groups[g].Icons[i].Enabled then
			icon.ForceDisabled = nil
			break
		end
	end

	if icon:Animations_Has() then
		for k, v in pairs(icon:Animations_Get()) do
			icon:Animations_Stop(v)
		end
	end

	icon:SetTexture("Interface\\Icons\\LevelUpIcon-LFD")

	--icon:SetUpdateMethod("manual") DONT DO THIS! 
	icon:SetScript("OnUpdate", Meta_OnUpdate)
	TMW:RegisterCallback("TMW_ICON_UPDATED", TMW_ICON_UPDATED, icon)
end

function Type:IE_TypeLoaded()
	local spacing = 70
	TMW.IE.Main.Sort:SetPoint("BOTTOMLEFT", 20, -22)
	TMW.IE.Main.Sort.text:SetWidth(spacing)

	TMW.IE.Main.Sort.Radio1:SetPoint("TOPLEFT", spacing, 19)
	TMW.IE.Main.Sort.Radio1.text:SetWidth(spacing + 2)

	TMW.IE.Main.Sort.Radio2:SetPoint("TOPLEFT", TMW.IE.Main.Sort.Radio1, "TOPRIGHT", spacing, 0)
	TMW.IE.Main.Sort.Radio2.text:SetWidth(spacing + 2)

	TMW.IE.Main.Sort.Radio3:SetPoint("TOPLEFT", TMW.IE.Main.Sort.Radio2, "TOPRIGHT", spacing, 0)
	TMW.IE.Main.Sort.Radio3.text:SetWidth(spacing + 2)

	TMW:TT(TMW.IE.Main.Sort.Radio1, "SORTBYNONE", "SORTBYNONE_META_DESC")
	TMW:TT(TMW.IE.Main.Sort.Radio2, "ICONMENU_SORTASC", "ICONMENU_SORTASC_META_DESC")
	TMW:TT(TMW.IE.Main.Sort.Radio3, "ICONMENU_SORTDESC", "ICONMENU_SORTDESC_META_DESC")

	TMW.IE.Main.ConditionAlpha.text:SetText(L["CONDITIONALPHA_METAICON"])
	TMW:TT(TMW.IE.Main.ConditionAlpha, "CONDITIONALPHA_METAICON", "CONDITIONALPHA_METAICON_DESC")
end

function Type:IE_TypeUnloaded()
	TMW.IE.Main.Sort:SetPoint("BOTTOMLEFT", 16, 72)
	TMW.IE.Main.Sort.text:SetWidth(0)

	TMW.IE.Main.Sort.Radio1:SetPoint("TOPLEFT", 0, 1)
	TMW.IE.Main.Sort.Radio1.text:SetWidth(TMW.WidthCol1)

	TMW.IE.Main.Sort.Radio2:SetPoint("TOPLEFT", TMW.IE.Main.Sort.Radio1, "BOTTOMLEFT", 0, 8)
	TMW.IE.Main.Sort.Radio2.text:SetWidth(TMW.WidthCol1)

	TMW.IE.Main.Sort.Radio3:SetPoint("TOPLEFT", TMW.IE.Main.Sort.Radio2, "BOTTOMLEFT", 0, 8)
	TMW.IE.Main.Sort.Radio3.text:SetWidth(TMW.WidthCol1)

	TMW:TT(TMW.IE.Main.Sort.Radio1, "SORTBYNONE", "SORTBYNONE_DESC")
	TMW:TT(TMW.IE.Main.Sort.Radio2, "ICONMENU_SORTASC", "ICONMENU_SORTASC_DESC")
	TMW:TT(TMW.IE.Main.Sort.Radio3, "ICONMENU_SORTDESC", "ICONMENU_SORTDESC_DESC")

	TMW.IE.Main.ConditionAlpha.text:SetText(L["CONDITIONALPHA"])
	TMW:TT(TMW.IE.Main.ConditionAlpha, "CONDITIONALPHA", "CONDITIONALPHA_DESC")
end

function Type:TMW_ICON_SETUP(event, icon)
	if icon.Type ~= self.type then
		TMW:UnregisterCallback("TMW_ICON_UPDATED", TMW_ICON_UPDATED, icon)
	else
		if not Locked then
			-- meta icons shouln't show bars in config, even though they are force enabled.
			if icon.class ~= TMW.Classes.Bar then
				icon.cbar:SetValue(0)
			end
			icon.pbar:SetValue(0)
		end
	end
end
TMW:RegisterCallback("TMW_ICON_SETUP", Type)

function Type:TMW_GLOBAL_UPDATE()
	TMW.DoWipeAC = false
	Locked = TMW.db.profile.Locked
end
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", Type)

function Type:GetFontTestValues(icon)
	-- its the best of both worlds!
	local rand = random(1, 23)
	local testCount = rand == 1 and 0 or rand == 2 and 25 or rand == 3 and 50 or rand - 3
	local testCountText
	if rand < 4 then
		testCountText = testCount.."%"
	end

	return testCount, testCountText
end

function Type:GetIconMenuText(data, groupID, iconID)
	local text
	if iconID then
		text = L["fICON"]:format(iconID) .. " - " .. Type.name
	else
		text = Type.name
	end
	text = text .. " " .. L["ICONMENU_META_ICONMENUTOOLTIP"]:format(data.Icons and #data.Icons or 0)
	
	return text, "", true
end

Type:Register()