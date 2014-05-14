-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local DS
local tonumber =
	  tonumber
local UnitAura = TMW.UnitAura
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local _, pclass = UnitClass("Player")
local isNumber = TMW.isNumber
local unitsWithExistsEvent

local clientVersion = select(4, GetBuildInfo())
local wow_501 = clientVersion >= 50100

local Type = TMW.Classes.IconType:New("buffCOR")
Type.name = "BUFF COR"
Type.desc = L["ICONMENU_BUFFDEBUFF_DESC"]
Type.menuIcon = GetSpellTexture(774)
Type.usePocketWatch = 1
Type.spacebefore = true
Type.unitType = "unitid"
Type.hasNoGCD = true


-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("reverse")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
Type:UsesAttributes("auraSourceUnit, auraSourceGUID")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	Unit					= "player", 
	BuffOrDebuff			= "HELPFUL", 
	Stealable				= false,     
	ShowTTText				= false,     
	OnlyMine				= false,
	HideIfNoUnits			= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = function(self)
		if TMW.CI.icon:IsController() then
			return L["ICONMENU_CHOOSENAME2"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"]
		else
			return L["ICONMENU_CHOOSENAME2"]
		end
	end,

	SUGType = "buff",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_BuffOrDebuff", function(self)
	self.Header:SetText(TMW.L["ICONMENU_BUFFTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 3,
		{
			setting = "BuffOrDebuff",
			value = "HELPFUL",
			title = "|cFF00FF00" .. L["ICONMENU_BUFF"],
		},
		{
			setting = "BuffOrDebuff",
			value = "HARMFUL",
			title = "|cFFFF0000" .. L["ICONMENU_DEBUFF"],
		},
		{
			setting = "BuffOrDebuff",
			value = "EITHER",
			title = L["ICONMENU_BOTH"],
		},
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(125, "TellMeWhen_BuffSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "OnlyMine",
			title = L["ICONMENU_ONLYMINE"],
			tooltip = L["ICONMENU_ONLYMINE_DESC"],
		},
		{
			setting = "ShowTTText",
			title = L["ICONMENU_SHOWTTTEXT"],
			tooltip = L["ICONMENU_SHOWTTTEXT_DESC"],
		},
		{
			setting = "Stealable",
			title = L["ICONMENU_STEALABLE"],
			tooltip = L["ICONMENU_STEALABLE_DESC"],
		},
		{
			setting = "HideIfNoUnits",
			title = L["ICONMENU_HIDENOUNITS"],
			tooltip = L["ICONMENU_HIDENOUNITS_DESC"],
		},
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONANY"], 	tooltipText = L["ICONMENU_PRESENTONANY_DESC"],	},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENTONALL"], 	tooltipText = L["ICONMENU_ABSENTONALL_DESC"],	},
})


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	DS = TMW.DS
	unitsWithExistsEvent = TMW.UNITS.unitsWithExistsEvent
end)


local NOT_ACTUALLY_SPELLSTEALABLE = {
	[43438] = true,	-- Ice Block
	[642] = true,	-- Divine Shield
}


local function Buff_OnEvent(icon, event, arg1)
	if event == "UNIT_AURA" then
		local Units = icon.Units
		for u = 1, #Units do
			if arg1 == Units[u] then
				icon.NextUpdateTime = 0
				return
			end
		end
	elseif event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		icon.NextUpdateTime = 0
	end
end

local huge = math.huge
local function Buff_OnUpdate(icon, time)
	
	local Units, NameHash, Filter, Filterh
	= icon.Units, icon.NameHash, icon.Filter, icon.Filterh
	local NotStealable = not icon.Stealable
	
	for u = 1, #Units do
		local unit = Units[u]
		if icon.UnitSet:UnitExists(unit) then

			local index, stage = 1, 1
			local filter = Filter

			while true do
				local buffName, _, iconTexture, count, dispelType, duration, expirationTime, caster, canSteal, _, id, _, _, _, v1, v2, v3, v4 = UnitAura(unit, index, filter)
				index = index + 1
				
				-- Bugfix: Enraged is an empty string.
				if dispelType == "" then
					dispelType = "Enraged"
				end

				if not buffName then
					if stage == 1 and Filterh and not buffName then
						index, stage = 1, 2
						filter = Filterh
					else
						break
					end

				elseif  (icon.NameFirst == '' or NameHash[id] or NameHash[dispelType] or NameHash[strlowerCache[buffName]])
					and (NotStealable or (canSteal and not NOT_ACTUALLY_SPELLSTEALABLE[id]))
				then
					
					if not icon:YieldInfo(1, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3, v4, unit) then
						return
					end
				end
			end
		end
	end
end


function Type:HandleData(icon, iconToSet, location, buffName, iconTexture, count, duration, expirationTime, caster, id, v1, v2, v3, v4, unit)
	local Units = icon.Units
	if buffName then
		if icon.ShowTTText then
			if v1 and v1 > 0 then
				count = v1
			elseif v2 and v2 > 0 then
				count = v2
			elseif v3 and v3 > 0 then
				count = v3
			elseif v4 and v4 > 0 then
				count = v4
			else
				count = 0
			end
		end

		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			icon.Alpha,
			iconTexture,
			expirationTime - duration, duration,
			count, count,
			id,
			unit, nil,
			caster, nil
		)

	elseif not Units[1] and icon.HideIfNoUnits then
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			0,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			nil, nil,
			nil, nil
		)

	else
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID; auraSourceUnit, auraSourceGUID",
			icon.UnAlpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			Units[1], nil,
			nil, nil
		)
	end
end




local aurasWithNoSourceReported = {
	GetSpellInfo(104993),	-- Jade Spirit
	GetSpellInfo(116660),	-- River's Song
	GetSpellInfo(120032),	-- Dancing Steel
	GetSpellInfo(116631),	-- Colossus
	GetSpellInfo(104423),	-- Windsong
	nil,	-- Terminate with nil to prevent all Windsong's return values from filling the table
}



function Type:Setup(icon)
	icon.NameFirst = TMW:GetSpellNames(icon.Name, 1, 1)
	--icon.NameName = TMW:GetSpellNames(icon.Name, 1, 1, 1)
	icon.NameNameArray = TMW:GetSpellNames(icon.Name, 1, nil, 1)
	icon.NameHash = TMW:GetSpellNames(icon.Name, 1, nil, nil, 1)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	icon.Filter = icon.BuffOrDebuff
	icon.Filterh = icon.BuffOrDebuff == "EITHER" and "HARMFUL"
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
		if icon.Filterh then icon.Filterh = icon.Filterh .. "|PLAYER" end
	end

	local isEditing
	if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
		TMW.HELP:Hide("ICONTYPE_BUFF_NOSOURCERPPM")
		isEditing = true
	end

	if icon.OnlyMine and isEditing then
		for k, spell in pairs(icon.NameNameArray) do
			for _, badSpell in pairs(aurasWithNoSourceReported) do
				if type(badSpell) == "string" and badSpell:lower() == spell then
					local NameArray = TMW:GetSpellNames(icon.Name, 1)
					TMW.HELP:Show{
						code = "ICONTYPE_BUFF_NOSOURCERPPM",
						codeOrder = 2,
						icon = icon,
						relativeTo = TellMeWhen_ChooseName,
						x = 0,
						y = 0,
						text = format(L["HELP_BUFF_NOSOURCERPPM"], TMW:RestoreCase(NameArray[k]))
					}
					break
				end
			end
		end
	end

	icon.FirstTexture = SpellTextures[icon.NameFirst]

	icon:SetInfo("texture; reverse", Type:GetConfigIconTexture(icon), true)
	
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		
		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
	
		icon:RegisterEvent("UNIT_AURA")
	
		icon:SetScript("OnEvent", Buff_OnEvent)
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", Buff_OnEvent, icon)
	end

	icon:SetUpdateFunction(Buff_OnUpdate)
	icon:Update()
end

function Type:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local name = TMW:GetSpellNames(ics.Name, nil, 1)
		if name then
			return SpellTextures[name]
		end
	end
	return "Interface\\Icons\\INV_Misc_PocketWatch_01"
end
	
Type:Register(100)

