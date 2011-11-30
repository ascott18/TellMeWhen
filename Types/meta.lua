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

local db, UPD_INTV
local _G, strmatch, tonumber, ipairs =
	  _G, strmatch, tonumber, ipairs
local print = TMW.print
local AlreadyChecked = {} TMW.AlreadyChecked = AlreadyChecked



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
	FakeHidden = false,
	ConditionAlpha = false, --TODO:implement conditionalpha for metas (problem is the icon editor UI)
	Alpha = false,
	UnAlpha = false,
}
Type.DisabledEvents = {
	OnSpell = true,
	OnUnit = true,
}

function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
end

local function Meta_OnUpdate(icon, time)
	if icon.LastUpdate <= time - UPD_INTV then
		icon.LastUpdate = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local CheckNext, Icons = icon.CheckNext, icon.Icons
		for n = 1, #Icons do
			local ic = _G[Icons[n]]
			if ic and ic.OnUpdate and ic.__shown and not (CheckNext and AlreadyChecked[ic]) then
				ic:OnUpdate(time)
				local alpha = ic.__alpha
				if alpha > 0 and ic.__shown then

					local force
					if ic.doUpdateBindText then
						icon.bindText:SetText(ic.bindText:GetText())
					end
					if ic ~= icon.__previcon then 
						if not ic.doUpdateBindText then
							icon.bindText:SetText(ic.bindText:GetText())
						end
						
						if LMB then -- i dont like the way that ButtonFacade handles this (inefficient), so i'll do it myself
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
					icon:SetInfo(alpha, ic.__vrtxcolor, ic.__tex, ic.__start, ic.__duration, ic.__spellChecked, ic.__reverse, ic.__count, ic.__countText, force, ic.__unitChecked)
					return
				end
			end
		end
		icon:SetInfo(0)
	end
end

local alreadyinserted = {}
local function GetFullIconTable(icons, tbl) -- check what all the possible icons it can show are, for use with setting CheckNext
	tbl = tbl or {}
	for i, ic in ipairs(icons) do
		local g, i = strmatch(ic, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g), tonumber(i)
		if db.profile.Groups[g].Icons[i].Type ~= "meta" then
			tinsert(tbl, ic)
		elseif not alreadyinserted[ic] then
			alreadyinserted[ic] = 1
			GetFullIconTable(db.profile.Groups[g].Icons[i].Icons, tbl)
		end
	end
	return tbl
end


function Type:Setup(icon, groupID, iconID)
	icon.__previcon = nil -- reset this
	icon.NameFirst = "" --need to set this to something for bars update

	if icon.CheckNext then
		TMW.DoWipeAC = true
		wipe(alreadyinserted)
		icon.Icons = GetFullIconTable(icon.Icons)
	end

	icon.ShowPBar = true
	icon.ShowCBar = true
	icon.InvertBars = false
	
	icon:SetTexture("Interface\\Icons\\LevelUpIcon-LFD")
	icon.ConditionAlpha = 0

	icon:SetScript("OnUpdate", Meta_OnUpdate)
end

function Type:GetIconMenuText(data)
	return "((" .. Type.name .. "))", ""
end

TMW:RegisterIconType(Type)