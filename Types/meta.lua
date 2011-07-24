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
local LBF = LibStub("LibButtonFacade", true)
local LMB = LibMasque and LibMasque("Button")

local db, UPD_INTV
local _G, strmatch, tonumber, ipairs =
	  _G, strmatch, tonumber, ipairs
local print = TMW.print
local AlreadyChecked = {} TMW.AlreadyChecked = AlreadyChecked



local Type = {}
Type.name = L["ICONMENU_META"]
Type.desc = L["ICONMENU_META_DESC"]
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
}

function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
end

local function Meta_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local CheckNext, Icons = icon.CheckNext, icon.Icons
		for n = 1, #Icons do
			local ic = _G[Icons[n]]
			if ic and ic.OnUpdate and ic.__shown and not (CheckNext and AlreadyChecked[ic]) then
				ic:OnUpdate(time)
				local alpha = ic.__alpha
				if alpha > 0 and ic.__shown then

					if ic ~= icon.__previcon then 
						icon.BindText = ic.BindText
						icon.bindText:SetText(icon.BindText)
						if (LBF or LMB) then -- i dont like the way that ButtonFacade handles this (inefficient), so i'll do it myself
							local icnt = ic.__normaltex -- icon.__normaltex = icon.__LBF_Normal or icon:GetNormalTexture() -- set during Icon_Update()
							local iconnt = icon.__normaltex
							if icnt and iconnt then
								iconnt:SetVertexColor(icnt:GetVertexColor())
							end
						end
						icon.__previcon = ic
					end

					icon.ShowCBar, icon.ShowPBar = ic.ShowCBar, ic.ShowPBar
					icon.InvertBars = ic.InvertBars
					icon.ShowTimer = ic.ShowTimer
					icon.cooldown.noCooldownCount = ic.cooldown.noCooldownCount

					icon:SetInfo(alpha, ic.__vrtxcolor, ic.__tex, ic.__start, ic.__duration, ic.__checkGCD, ic.__pbName, ic.__reverse, ic.__count, ic.__countText)

					AlreadyChecked[ic] = true
					return
				end
			end
		end
		icon:SetAlpha(0)
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


Type.AllowNoName = true
Type.HideBars = true
local preTable = {}
function Type:Setup(icon, groupID, iconID)
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

TMW:RegisterIconType(Type, "meta")