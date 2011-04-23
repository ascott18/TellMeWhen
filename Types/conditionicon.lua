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
		if not (CndtCheck and CndtCheck()) then
			icon:SetAlpha(1)
		end
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
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end

	icon:SetScript("OnUpdate", ConditionIcon_OnUpdate)
	--icon:OnUpdate(TMW.time)
end


local oldLabel, oldTTtitle, oldTTtext
function Type:OnUnloadIE()
	TMW.IE.Main.Name.label = oldLabel
	TMW.IE.Main.Name.TTtitle = oldTTtitle
	TMW.IE.Main.Name.TTtext = oldTTtext
end

function Type:OnLoadIE()
	local Name = TMW.IE.Main.Name
	oldLabel = Name.label
	oldTTtitle = Name.TTtitle
	oldTTtext = Name.TTtext
	Name.label = TMW.L["ICONMENU_CHOOSENAME_CNDTIC"]
	Name.TTtitle = TMW.L["ICONMENU_CHOOSENAME_CNDTIC"]
	Name.TTtext = TMW.L["CHOOSENAME_DIALOG_CNDTIC"]
end




