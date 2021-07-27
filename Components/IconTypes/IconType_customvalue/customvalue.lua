local TMW = TMW
if not TMW then return end

local L = TMW.L

local print = TMW.print


local Type = TMW.Classes.IconType:New("customvalue")

Type.name = L["ICONMENU_CUSTOMVALUE"]
Type.desc = L["ICONMENU_CUSTOMVALUE_DESC"]
Type.menuIcon = "Interface/Icons/inv_misc_punchcards_white"

Type.hasNoGCD = true
Type.barIsTimer = false

local STATE_SUCCEED = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_FAIL = TMW.CONST.STATE.DEFAULT_HIDE

Type:SetAllowanceForView("icon", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)
Type:UsesAttributes("texture")

Type:UsesAttributes("value")
Type:UsesAttributes("maxValue")
Type:UsesAttributes("valueColor")
Type:UsesAttributes("state")

local BarColors = {{r=0, g=0, b=1, a=1}, {r=0, g=1, b=1, a=1}, {r=0, g=1, b=0, a=1}}

Type:RegisterIconDefaults{
	-- Lua code to be evaluated
	LuaCode			="",

	-- Currently displayed value
	value			=0,
	
	-- Maximum value displayed
	maxValue		=0,
	
	-- Bar color scheme
	valueColor		=BarColors,
	
	-- Initial state of icon (set as fail since we have no code yet)
	state			=STATE_FAIL,

}


Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_CustomValue", {
	implementConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_IconStates", {
	[STATE_SUCCEED] = { text = "|cFF00FF00" .. L["ICONMENU_CUSTOMVALUE_OK"], },
	[STATE_FAIL] =    { text = "|cFFFF0000" .. L["ICONMENU_CUSTOMVALUE_ERROR"], },
})


local function CustomValue_OnUpdate(icon, time)    

	local func = loadstring(icon.LuaCode)

	if func == nil then
		icon:SetInfo("state", STATE_FAIL)
		return
	end
	value, maxValue = func()
	value = tonumber(value)
	maxValue = tonumber(maxValue)
	if value == nil or maxValue == nil then
		icon:SetInfo("state", STATE_FAIL)
		return
	end
	if value < 0 then
		value = 0
	end
	if maxValue < 0 then
		icon:SetInfo("state", STATE_FAIL)
		return
	end
	if value > maxValue then
		maxValue = value
	end	

	icon:SetInfo("state; value, maxValue, valueColor", STATE_SUCCEED, value, maxValue, BarColors)

end



function Type:Setup(icon)
	icon:SetInfo("texture", "Interface/Icons/inv_misc_punchcards_white")
	icon:SetUpdateMethod("auto")
	icon:SetUpdateFunction(CustomValue_OnUpdate)
	icon.luaCode = loadstring(icon.LuaCode)
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

TMW:RegisterLuaImportDetector(function(table)
	if rawget(table, "LuaCode") ~= "" then
		return table.LuaCode, L["ICONMENU_CUSTOMVALUE2"]
	end
end)

Type:Register(158)
