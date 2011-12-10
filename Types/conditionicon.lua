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

local db
local print = TMW.print


local Type = {}
Type.type = "conditionicon"
Type.name = L["ICONMENU_CNDTIC"]
Type.desc = L["ICONMENU_CNDTIC_DESC"]
Type.spacebefore = true
Type.AllowNoName = true
Type.SUGType = "texture"
Type.DontSetInfoInCondition = true
Type.chooseNameTitle = L["ICONMENU_CHOOSENAME_CNDTIC"]
Type.chooseNameText = L["CHOOSENAME_DIALOG_CNDTIC"]
	
Type.WhenChecks = {
	text = L["ICONMENU_CNDTSHOWWHEN"],
	{ value = "alpha",			text = L["ICONMENU_SUCCEED"],			colorCode = "|cFF00FF00" },
	{ value = "unalpha",		text = L["ICONMENU_FAIL"],				colorCode = "|cFFFF0000" },
	{ value = "always",			text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	CustomTex = false,
	ConditionDur = true,
	ConditionDurEnabled = true,
	UnConditionDur = true,
	UnConditionDurEnabled = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	OnlyIfCounting = true,
}
Type.DisabledEvents = {
	OnSpell = true,
	OnUnit = true,
	OnStack = true,
}

function Type:Update()
	db = TMW.db
end

local function ConditionIcon_OnUpdate(icon, time)
	local CndtCheck = icon.CndtCheck_CNDTIC
	if CndtCheck then
		local shouldReturn, succeeded = CndtCheck() -- we dont use shouldreturn.
		
		local alpha = succeeded and icon.Alpha or icon.UnAlpha
		
		local d, start, duration
		
		--icon:SetInfo(alpha, color, texture, start, duration, spellChecked, reverse, count, countText, forceupdate, unit)
		if succeeded and not icon.__succeeded and icon.ConditionDurEnabled then
			d = icon.ConditionDur
			start, duration = time, d
			
		elseif not succeeded and icon.__succeeded and icon.UnConditionDurEnabled then
			d = icon.UnConditionDur
			start, duration = time, d
			
		else
			d = icon.__duration - (time - icon.__start)
			d = d > 0 and d or 0
			start, duration = icon.__start, icon.__duration
		end
		
		if icon.OnlyIfCounting and d <= 0 then
			alpha = 0
		end
		local color = icon:CrunchColor(d)
		
		icon:SetInfo(alpha, color, nil, start, duration, nil, nil, nil, nil, nil, nil)
			
		icon.__succeeded = succeeded
	else
		icon:SetInfo(1)
	end
end

function Type:GetNameForDisplay(icon, data)
	return ""
end


function Type:Setup(icon, groupID, iconID)
	icon.CndtCheck_CNDTIC = icon.CndtCheck or icon.CndtCheckAfter
	icon.CndtCheck = nil
	icon.CndtCheckAfter = nil
	
	
	local Name = gsub(icon.Name, [[\\]], [[\]])
	icon.NameFirst = TMW:GetSpellNames(icon, Name, 1)
	
	local tex, reason = TMW:GetConfigIconTexture(icon)
	icon:SetTexture(tex)
	if reason == false then
		icon:SetTexture(Name)
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\" .. Name)
		end
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
	icon.__start = icon.__start or 0 --TellMeWhen-4.2.1.2.lua:2115 attempt to perform arithmetic on local "start" (a nil value) -- caused because condition icons do necessarily define start/durations, even if shown.
	icon.__duration = icon.__duration or 0
	icon.__vrtxcolor = 1
	
	icon:SetScript("OnUpdate", ConditionIcon_OnUpdate)
	--icon:Update() -- dont do this!
end

function Type:DragReceived(icon, t, data, subType)
	local ics = icon:GetSettings()
	
	local _, input
	if t == "spell" then
		_, input = GetSpellBookItemInfo(data, subType)
	elseif t == "item" then
		input = GetItemIcon(data)
	end
	if not input then
		return
	end
	
	ics.Name = TMW:CleanString(input)
	return true -- signal success
end

function Type:IE_TypeLoaded()
	TMW.IE.Main.ConditionAlpha.text:SetText(L["CONDITIONALPHA_CONDITIONICON"])
	TMW:TT(TMW.IE.Main.ConditionAlpha, "CONDITIONALPHA_CONDITIONICON", "CONDITIONALPHA_CONDITIONICON_DESC")
end

function Type:IE_TypeUnloaded()
	TMW.IE.Main.ConditionAlpha.text:SetText(L["CONDITIONALPHA"])
	TMW:TT(TMW.IE.Main.ConditionAlpha, "CONDITIONALPHA", "CONDITIONALPHA_DESC")
end

TMW:RegisterIconType(Type)
