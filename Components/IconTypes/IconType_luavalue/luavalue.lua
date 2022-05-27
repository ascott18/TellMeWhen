local TMW = TMW
if not TMW then return end

local L = TMW.L

local print = TMW.print


local Type = TMW.Classes.IconType:New("luavalue")

Type.name = L["ICONMENU_LUAVALUE"]
Type.desc = L["ICONMENU_LUAVALUE_DESC"]
Type.menuIcon = "Interface/Icons/inv_misc_punchcards_white"

Type.hasNoGCD = true
Type.barIsValue = true

local STATE_SUCCEED = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_FAIL = TMW.CONST.STATE.DEFAULT_HIDE

Type:SetAllowanceForView("icon", false)
Type:SetModuleAllowance("IconModule_TimerBar_Overlay", false)
Type:SetModuleAllowance("IconModule_CooldownSweep", false)
Type:UsesAttributes("texture")

Type:UsesAttributes("value, maxValue, valueColor")
Type:UsesAttributes("state")

local BarColors = {{r=0, g=0, b=1, a=1}, {r=0, g=1, b=1, a=1}, {r=0, g=1, b=0, a=1}}

Type:RegisterIconDefaults{
	-- Lua code to be evaluated
	LuaCode			= "",
}

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_LuaValue", {
})

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_IconStates", {
	[STATE_SUCCEED] = { text = "|cFF00FF00" .. L["ICONMENU_LUAVALUE_OK"], },
	[STATE_FAIL] =    { text = "|cFFFF0000" .. L["ICONMENU_LUAVALUE_ERROR"], },
})


local function LuaValue_OnUpdate(icon)
	local func = icon.luaFunc

	local value, maxValue = func()
	value = tonumber(value)
	maxValue = tonumber(maxValue)

	if value == nil or maxValue == nil or maxValue < 0 then
		icon:SetInfo("state", STATE_FAIL)
		return
	end

	if value < 0 then
		value = 0
	end

	if value > maxValue then
		maxValue = value
	end

	icon:SetInfo("state; value, maxValue, valueColor", STATE_SUCCEED, value, maxValue, BarColors)
end

function Type:Setup(icon)
	icon:SetInfo("texture", "Interface/Icons/inv_misc_punchcards_white")

	if icon.LuaCode:trim() == "" then
		icon:SetInfo("state", STATE_FAIL)
		return
	end

	icon.luaFunc = nil
	local func, err = loadstring(icon.LuaCode, icon:GetIconName())
	if func then
		icon.luaFunc = func
	elseif err then
		TMW:Error(err)
	end

	if not func then
		icon:SetInfo("state", STATE_FAIL)
		return
	end

	icon:SetUpdateMethod("auto")
	icon:SetUpdateFunction(LuaValue_OnUpdate)
	icon:Update()
end

TMW:RegisterLuaImportDetector(function(table)
	local code = rawget(table, "LuaCode")
	if type(code) == "string" and code:trim() ~= "" then
		return table.LuaCode, L["ICONMENU_LUAVALUE2"]
	end
end)

Type:Register(158)
