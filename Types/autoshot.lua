-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, rc, mc, pr, ab
local GetSpellCooldown, IsSpellInRange, IsUsableSpell =
	  GetSpellCooldown, IsSpellInRange, IsUsableSpell
local GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon, GetItemCount =
	  GetItemCooldown, IsItemInRange, IsEquippedItem, GetItemIcon, GetItemCount
local GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo =
	  GetActionCooldown, IsActionInRange, IsUsableAction, GetActionTexture, GetActionInfo
local OnGCD = TMW.OnGCD
local print = TMW.print
local _, pclass = UnitClass("Player")
local SpellTextures = TMW.SpellTextures

local RelevantSettings = {
	ShowTimer = true,
	ShowTimerText = true,
	ShowWhen = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("autoshot", RelevantSettings)
Type.name = L["ICONMENU_AUTOSHOT"]
Type.hidden = pclass ~= "HUNTER"
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",  		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end

local function AutoShot_OnEvent(icon, event, unit, _, _, _, spellID)
	if unit == "player" and spellID == 75 then
		icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and ab or 1, nil, TMW.time, UnitRangedDamage("player"), true)
	end
end

local function AutoShot_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		
		if time - (icon.__start + icon.__duration) > 0 then
			icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, nil, 0, 0)
		end
	end
end

function Type:Setup(icon, groupID, iconID)

	icon:SetTexture(GetSpellTexture(75))
	icon.__start = icon.__start or 0
	icon.__duration = icon.__duration or 0
	
	icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	icon:SetScript("OnEvent", AutoShot_OnEvent)
	
	icon:SetScript("OnUpdate", AutoShot_OnUpdate)
	icon:OnUpdate(TMW.time)
end

