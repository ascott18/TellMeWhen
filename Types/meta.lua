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
local _G, strmatch, tonumber, ipairs =
	  _G, strmatch, tonumber, ipairs
local print = TMW.print
local AlreadyChecked = {} TMW.AlreadyChecked = AlreadyChecked
local ChangedMetas = {} TMW.ChangedMetas = ChangedMetas



local Type = {}
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


function Type:Update()
	db = TMW.db
end

local huge = math.huge
local function Meta_OnUpdate(icon, time)
	local Sort, CheckNext, CompiledIcons = icon.Sort, icon.CheckNext, icon.CompiledIcons
	
	local icToUse
	local d = Sort == -1 and huge or 0
	
	for n = 1, #CompiledIcons do
		local ic = _G[CompiledIcons[n]]
		if ic and ic.OnUpdate and ic.__shown and not (CheckNext and AlreadyChecked[ic]) then
			ic:Update(time)
			local alpha = ic.__alpha
			if alpha > 0 and ic.__shown then
				if Sort then
					local _d = ic.__duration - (time - ic.__start)
					if _d < 0 then
						_d = 0
					end
					if d*Sort < _d*Sort then
						icToUse = ic
						d = _d
					end
				else
					icToUse = ic
					break
				end
			else
				AlreadyChecked[ic] = true
			end
		end
	end
	
	if icToUse then
		local ic = icToUse
		local force
		if ic.UpdateBindText then
			icon.bindText:SetText(ic.bindText:GetText())
		end
		if ic ~= icon.__previcon or ChangedMetas[ic] then 
			ChangedMetas[icon] = true
			
			if not ic.UpdateBindText then
				icon.bindText:SetText(ic.bindText:GetText())
			end
			
			if LMB then -- i dont like the way that Masque handles this (inefficient), so i'll do it myself
				local icnt = ic.__normaltex -- icon.__normaltex = icon.__LBF_Normal or icon:GetNormalTexture() -- set during Icon_Update()
				local iconnt = icon.__normaltex
				if icnt and iconnt then
					iconnt:SetVertexColor(icnt:GetVertexColor())
				end
			end

			local icSCB, icSPB = ic.ShowCBar, ic.ShowPBar
			icon.ShowCBar, icon.ShowPBar = icSCB, icSPB
			if icSPB then
				icon.pbar.offset = ic.pbar.offset
				icon.pbar:Show()
			else
				icon.pbar:Hide()
			end
			if icSCB then
				icon.cbar.offset = ic.cbar.offset
				icon.cbar.startColor = ic.cbar.startColor
				icon.cbar.completeColor = ic.cbar.completeColor
				icon.cbar:Show()
			else
				icon.cbar:Hide()
			end
			
			icon.InvertBars = ic.InvertBars
			icon.ShowTimer = ic.ShowTimer
			icon.ShowTimerText = ic.ShowTimerText
			icon.cooldown.noCooldownCount = ic.cooldown.noCooldownCount
			
			force = 1
			
			icon.__previcon = ic
		end
		
		AlreadyChecked[ic] = true
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		icon:SetInfo(ic.__alpha, ic.__vrtxcolor, ic.__tex, ic.__start, ic.__duration, ic.__spellChecked, ic.__reverse, ic.__count, ic.__countText, force, ic.__unitChecked)
	else
		icon:SetInfo(0)
	end
end



local InsertIcon, GetFullIconTable -- both need access to eachother, so scope them above their definitions

local alreadyinserted = {}
function InsertIcon(icon, ics, ic)
	if ics.Type ~= "meta" or not icon.CheckNext then
		alreadyinserted[ic] = true
		tinsert(icon.CompiledIcons, ic)
	elseif icon.CheckNext then
		GetFullIconTable(icon, ics.Icons, icon.CompiledIcons)
	end
end

function GetFullIconTable(icon, icons) -- check what all the possible icons it can show are, for use with setting CheckNext
	for _, ic in ipairs(icons) do
		if not alreadyinserted[ic] then
			alreadyinserted[ic] = true
			
			local i = tonumber(strmatch(ic, "TellMeWhen_Group%d+_Icon(%d+)"))
			local g = tonumber(strmatch(ic, "TellMeWhen_Group(%d+)"))
			
			if g and not i then -- a group. Expand it into icons.
				if TMW:Group_ShouldUpdateIcons(g) then
					local gs = db.profile.Groups[g]
					
					for iconID, ics in ipairs(gs.Icons) do
						if ics.Enabled and iconID <= gs.Rows*gs.Columns then
							InsertIcon(icon, ics, ic .. "_Icon" .. iconID)
						end
					end
				end
				
			elseif g and i then -- just an icon. put it in.
				InsertIcon(icon, db.profile.Groups[g].Icons[i], ic)
			end
		end
	end
	return icon.CompiledIcons
end


function Type:Setup(icon, groupID, iconID)
	icon.__previcon = nil -- reset this
	icon.NameFirst = "" --need to set this to something for bars update

	-- validity check)
	for k, v in pairs(icon.Icons) do
		local g, i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g) or 0, tonumber(i) or 0
		TMW:QueueValidityCheck(v, groupID, iconID, g, i)
	end
	
	if icon.CheckNext then
		TMW.DoWipeAC = true
	end
	TMW.DoWipeChangedMetas = true
	
	wipe(alreadyinserted)
	icon.CompiledIcons = wipe(icon.CompiledIcons or {})
	icon.CompiledIcons = GetFullIconTable(icon, icon.Icons)

	icon.ShowPBar = true
	icon.ShowCBar = true
	icon.InvertBars = false
	
	icon:SetTexture("Interface\\Icons\\LevelUpIcon-LFD")

	icon:SetScript("OnUpdate", Meta_OnUpdate)
end

function Type:IE_TypeLoaded()
	local spacing = 70
	TMW.IE.Main.Sort:SetPoint("BOTTOMLEFT", 20, -22)
	TMW.IE.Main.Sort.text:SetWidth(spacing)
	
	TMW.IE.Main.Sort.Radio1:SetPoint("TOPLEFT", spacing, 19)
	TMW.IE.Main.Sort.Radio1.text:SetWidth(spacing)
	
	TMW.IE.Main.Sort.Radio2:SetPoint("TOPLEFT", TMW.IE.Main.Sort.Radio1, "TOPRIGHT", spacing, 0)
	TMW.IE.Main.Sort.Radio2.text:SetWidth(spacing)
	
	TMW.IE.Main.Sort.Radio3:SetPoint("TOPLEFT", TMW.IE.Main.Sort.Radio2, "TOPRIGHT", spacing, 0)
	TMW.IE.Main.Sort.Radio3.text:SetWidth(spacing)
	
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



function Type:GetIconMenuText(data)
	return "((" .. Type.name .. "))", ""
end

TMW:RegisterIconType(Type)