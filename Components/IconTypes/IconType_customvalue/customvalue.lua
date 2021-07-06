local TMW = TMW
if not TMW then return end

local L = TMW.L

local print = TMW.print


local Type = TMW.Classes.IconType:New("customvalue")

Type.name = L["ICONMENU_CUSTOMVALUE"]
Type.desc = L["ICONMENU_CUSTOMVALUE_DESC"]
Type.menuIcon = "Interface/Icons/inv_misc_punchcards_white"

Type.hasNoGCD = true
Type.canControlGroup = true
Type.menuSpaceBefore = true
Type.barIsTimer = false
Type.menuSpaceBefore = true



local STATE_SUCCEED = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_FAIL = TMW.CONST.STATE.DEFAULT_HIDE

Type:SetAllowanceForView("icon", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)
Type:UsesAttributes("texture")

Type:RegisterIconDefaults{
	func = nil
}


Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_CustomValue", {
	implementConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_IconStates", {
	[STATE_SUCCEED] = { text = "|cFF00FF00" .. L["ICONMENU_CUSTOMVALUE_OK"], },
	[STATE_FAIL] =    { text = "|cFFFF0000" .. L["ICONMENU_CUSTOMVALUE_ERROR"],    },
})

local BarColors = {{r=0, g=0, b=1, a=1}, {r=0, g=1, b=1, a=1}, {r=0, g=1, b=0, a=1}}

local function CustomValue_OnUpdate(icon, time)    
	local value, maxValue, valueColor
	local luaCode = icon.Name
	local func = icon.func

	if func==nil then
		icon:SetInfo("state;", STATE_FAIL)
		return
	end
	value, maxValue = func()
	value = tonumber(value)
	maxValue = tonumber(maxValue)
	if (value == nil or maxValue == nil) then
		icon:SetInfo("state;", STATE_FAIL)
		return
	end
	if value < 0 then
		value = -value
	end
	if maxValue < 0 then
		maxValue = maxValue
	end
	if value > maxValue then
		maxValue=value
	end	

	icon:SetInfo("state; value, maxValue, valueColor;", STATE_SUCCEED, value, maxValue, BarColors)

end



function Type:Setup(icon)
	icon:SetInfo("texture", "Interface/Icons/inv_misc_punchcards_white")
	icon:SetUpdateMethod("auto")
	icon:SetUpdateFunction(CustomValue_OnUpdate)
	icon.func = loadstring(icon.Name)
	icon:Update()
end

TMW:RegisterCallback("TMW_CONFIG_ICON_TYPE_CHANGED", function(event, icon, type, oldType)
	local icspv = icon:GetSettingsPerView()

	if type == Type.type then
		icon:GetSettings().CustomTex = "NONE"
		local layout = TMW.TEXT:GetTextLayoutForIcon(icon)

		if layout == "bar1" or layout == "bar2" then
			icspv.Texts[1] = "[(Value / ValueMax * 100):Round:Percent]"
			icspv.Texts[2] = "[Value:Short \"/\" ValueMax:Short]"
		end
	elseif oldType == Type.type then
		if icspv.Texts[1] == "[(Value / ValueMax * 100):Round:Percent]" then
			icspv.Texts[1] = nil
		end
		if icspv.Texts[2] == "[Value:Short \"/\" ValueMax:Short]" then
			icspv.Texts[2] = nil
		end
	end
end)

Type:Register(158)
