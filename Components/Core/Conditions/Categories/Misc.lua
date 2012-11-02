-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local CNDT = TMW.CNDT
local Env = CNDT.Env


local ConditionCategory = CNDT:GetCategory("MISC", 8, L["CNDTCAT_MISC"], false, false)

ConditionCategory:RegisterCondition(0,	 "", {
	text = L["CONDITIONPANEL_DEFAULT"],
	value = "",
	hidden = true,
	noslide = true,
	unit = false,
	nooperator = true,
	min = 0,
	max = 100,
	funcstr = [[true]],
	events = function()
		-- Returning false (as a string, not a boolean) won't cause responses to any events,
		-- and it also won't make the ConditionObject default to being OnUpdate driven.
		
		return "false"
	end,
})

ConditionCategory:RegisterSpacer(0.5)

ConditionCategory:RegisterCondition(1,	 "ICON", {
	text = L["CONDITIONPANEL_ICON"],
	tooltip = L["CONDITIONPANEL_ICON_DESC"],
	min = 0,
	max = 1,
	texttable = {
		[0] = L["CONDITIONPANEL_ICON_SHOWN"],
		[1] = L["CONDITIONPANEL_ICON_HIDDEN"],
	},
	isicon = true,
	nooperator = true,
	unit = false,
	icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c, icon)
		if c.Icon == "" or c.Icon == icon:GetName() then
			return [[true]]
		end

		local g, i = strmatch(c.Icon, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g) or 0, tonumber(i) or 0
		if icon.IsIcon then
			TMW:QueueValidityCheck(c.Icon, icon.group:GetID(), icon:GetID(), g, i)
		elseif icon.class == TMW.Classes.Group then
			TMW:QueueValidityCheck(c.Icon, icon:GetID(), nil, g, i)
		end

		local str = [[( c.Icon and c.Icon.attributes.shown and c.Icon.UpdateFunction and not c.Icon:Update())]]
		if c.Level == 0 then
			str = str .. [[and c.Icon.attributes.realAlpha > 0]]
		else
			str = str .. [[and c.Icon.attributes.realAlpha == 0]]
		end
		return gsub(str, "c.Icon", c.Icon)
	end,
--[[	events = function(ConditionObject, c)
		ConditionObject:SetNumEventArgs(1)
		
		local t = {}
		for _, IconDataProcessor_name in TMW:Vararg("REALALPHA", "SHOWN") do
			local IconDataProcessor = TMW.ProcessorsByName[IconDataProcessor_name]
			local changedEvent = IconDataProcessor and IconDataProcessor.changedEvent
			
			if changedEvent then
				ConditionObject:RequestEvent(changedEvent)
				
				t[#t+1] = "event == '" .. changedEvent .. "' and arg1 == " .. c.Icon
			end
		end
		
		return unpack(t)
	end,]]
})
TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData and conditionData.value == "ICON" then
		CndtGroup.TextIcon:SetText(L["ICONTOCHECK"])
		CndtGroup.Icon:Show()
	else
		CndtGroup.TextIcon:SetText(nil)
		CndtGroup.Icon:Hide()
	end
end)

ConditionCategory:RegisterCondition(2,	 "MACRO", {
	text = L["MACROCONDITION"],
	tooltip = L["MACROCONDITION_DESC"],
	min = 0,
	max = 1,
	nooperator = true,
	noslide = true,
	name = function(editbox) TMW:TT(editbox, "MACROCONDITION", "MACROCONDITION_EB_DESC") editbox.label = L["MACROTOEVAL"] end,
	unit = false,
	icon = "Interface\\Icons\\inv_misc_punchcards_yellow",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		SecureCmdOptionParse = SecureCmdOptionParse,
	},
	funcstr = function(c)
		local text = c.Name
		text = (not strfind(text, "^%[") and ("[" .. text)) or text
		text = (not strfind(text, "%]$") and (text .. "]")) or text
		return [[SecureCmdOptionParse("]] .. text .. [[")]]
	end,
	-- events = absolutely no events
})

ConditionCategory:RegisterCondition(3,	 "MOUSEOVER", {
	text = L["MOUSEOVERCONDITION"],
	tooltip = L["MOUSEOVERCONDITION_DESC"],
	min = 0,
	max = 1,
	texttable = CNDT.COMMON.bool,
	nooperator = true,
	unit = false,
	icon = "Interface\\Icons\\Ability_Marksmanship",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c, parent)
		return [[c.True == ]] .. parent:GetName() .. [[:IsMouseOver()]]
	end,
	-- events = -- there is no good way to handle events for this condition
})

ConditionCategory:RegisterCondition(4,	 "LUA", {
	text = L["LUACONDITION"],
	tooltip = L["LUACONDITION_DESC"],
	min = 0,
	max = 1,
	nooperator = true,
	noslide = true,
	name = function(editbox) TMW:TT(editbox, "LUACONDITION", "LUACONDITION_DESC") editbox.label = L["CODETOEXE"] end,
	unit = false,
	icon = "Interface\\Icons\\INV_Misc_Gear_01",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(c)
		setmetatable(TMW.CNDT.Env, TMW.CNDT.EnvMeta)
		return c.Name ~= "" and c.Name or "true"
	end,
	
	--[=[
	Just don't do this anymore. The only person who knows about it is me.
	And i have only given it to one person in an export string.
	
	events = function(ConditionObject, c)
		-- allows parsing of events from the code string. EG:
		-- --EVENTS:'PLAYER_ENTERING_WORLD','PLAYER_LOGIN'
		-- --[[EVENTS:'PLAYER_ENTERING_WORLD','UNIT_AURA','target']]
		
		
		
		if true then return end
		
		
		
		
		
		local eventString = strmatch(c.Name, "EVENTS:([^ \t]-)\]?")
		if eventString then
			CNDT.LuaTemporaryConditionTable = c
			local func = [[
				local c = TMW.CNDT.LuaTemporaryConditionTable
			return ]] .. eventString
			local func, err = loadstring(func)
			if func then
				-- we do this convoluted shit because the function is supposed to return a list of events,
				-- but the first ret from pcall is success, which isn't expected as a ret value,
				-- but we still need to return all other values (and an unknown number of them),
				-- which makes unpack ideal for this.
				local t = {pcall(func)}
				local success = tremove(t, 1)
				if success then
					return unpack(t)
				end
			end
		end
	end,]=]
})

