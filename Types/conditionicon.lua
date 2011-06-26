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

local db, UPD_INTV
local print = TMW.print




local Type = TMW:RegisterIconType("conditionicon")
Type.name = L["ICONMENU_CNDTIC"]
Type.desc = L["ICONMENU_CNDTIC_DESC"]
Type.RelevantSettings = {
	Name = true,
	FakeHidden = true,
	ConditionAlpha = true,
}

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
	elseif TMW.SpellTextures[icon.NameFirst] then
		icon:SetTexture(TMW.SpellTextures[icon.NameFirst])
	else
		icon:SetTexture(icon.Name)
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\" .. icon.Name)
		end
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
	icon.__start = icon.__start or 0 --TellMeWhen-4.2.1.2.lua:2115 attempt to perform arithmetic on local "start" (a nil value) -- caused because condition icons do not define start/durations at all, even if shown.
	icon.__duration = icon.__duration or 0
	icon.__vrtxcolor = 1

	icon:SetScript("OnUpdate", ConditionIcon_OnUpdate)
	--icon:OnUpdate(TMW.time)
end

function Type:IE_TypeLoaded()
	local Name = TMW.IE.Main.Name
	Name.label = L["ICONMENU_CHOOSENAME_CNDTIC"]
	Name.TTtitle = L["ICONMENU_CHOOSENAME_CNDTIC"]
	Name.TTtext = L["CHOOSENAME_DIALOG_CNDTIC"]
	Name:GetScript("OnTextChanged")(Name)
end

function Type:IE_TypeUnloaded()
	local Name = TMW.IE.Main.Name
	Name.label = L["ICONMENU_CHOOSENAME"]
	Name.TTtitle = L["ICONMENU_CHOOSENAME"]
	Name.TTtext = L["CHOOSENAME_DIALOG"]
	Name:GetScript("OnTextChanged")(Name)
end


