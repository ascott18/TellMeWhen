-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV
local print = TMW.print


local RelevantSettings = {
	Name = true,
	FakeHidden = true,
	ConditionAlpha = true,
}

local Type = TMW:RegisterIconType("conditionicon", RelevantSettings)
Type.name = L["ICONMENU_CNDTIC"]
Type.desc = L["ICONMENU_CNDTIC_DESC"]


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
end

local function ConditionIcon_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck
		if CndtCheck and CndtCheck() then
			return
		end
		icon:SetAlpha(icon.CndtFailed and icon.ConditionAlpha or 1)
	end
end



Type.AllowNoName = true
Type.HideBars = true
function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	else
		icon:SetTexture(icon.Name)
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\" .. icon.Name)
		end
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end

	icon:SetScript("OnUpdate", ConditionIcon_OnUpdate)
	--icon:OnUpdate(TMW.time)
end




