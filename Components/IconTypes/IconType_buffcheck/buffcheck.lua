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

local EFF_THRESHOLD
local tonumber =
	  tonumber
local UnitAura, UnitExists, UnitIsDeadOrGhost =
	  TMW.UnitAura, UnitExists, UnitIsDeadOrGhost
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local strlowerCache = TMW.strlowerCache
local _, pclass = UnitClass("Player")
local isNumber = TMW.isNumber

local clientVersion = select(4, GetBuildInfo())

local Type = TMW.Classes.IconType:New("buffcheck")
Type.name = L["ICONMENU_BUFFCHECK"]
Type.desc = L["ICONMENU_BUFFCHECK_DESC"]
Type.menuIcon = GetSpellTexture(21562)
Type.usePocketWatch = 1
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("reverse")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	Unit					= "player", 
	BuffOrDebuff			= "HELPFUL", 
	OnlyMine				= false,
	-- HideIfNoUnits			= false,
}

Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "buffNoDS",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_ConstructorFunc(120, "TellMeWhen_BuffOrDebuff2", function(self)
	self.Header:SetText(TMW.L["ICONMENU_BUFFTYPE"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 2,
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
	})
end)

Type:RegisterConfigPanel_ConstructorFunc(125, "TellMeWhen_BuffCheckSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "OnlyMine",
			title = L["ICONMENU_ONLYMINE"],
			tooltip = L["ICONMENU_ONLYMINE_DESC"],
		},
		-- {
		-- 	setting = "HideIfNoUnits",
		-- 	title = L["ICONMENU_HIDENOUNITS"],
		-- 	tooltip = L["ICONMENU_HIDENOUNITS_DESC"],
		-- },
	})
end)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENTONANY"],		tooltipText = L["ICONMENU_ABSENTONANY_DESC"],	},
	[0x1] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENTONALL"],	tooltipText = L["ICONMENU_PRESENTONALL_DESC"], 	},
})

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	EFF_THRESHOLD = TMW.db.profile.EffThreshold
end)

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
local function BuffCheck_OnUpdate(icon, time)

	local Units, NameArray, NameNameArray, NameHash, Filter
	= icon.Units, icon.NameArray, icon.NameNameArray, icon.NameHash, icon.Filter
	
	local NAL = #icon.NameArray

	local _, iconTexture, id, count, duration, expirationTime
	local useUnit
	
	for u = 1, #Units do
		local unit = Units[u]
		if icon.UnitSet:UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			
			local _iconTexture, _id, _count, _duration, _expirationTime, _buffName
			
			if NAL > EFF_THRESHOLD then
				for z = 1, huge do
					-- Check by aura index
					_buffName, _, _iconTexture, _count, _, _duration, _expirationTime, _, _, _, _id = UnitAura(unit, z, Filter)
					
					if not _id then
						break
					elseif (NameHash[_id] or NameHash[strlowerCache[_buffName]]) then
						break
					end
				end
				
			else
				for i = 1, NAL do
					local iName = NameArray[i]
					
					-- Check by name
					_buffName, _, _iconTexture, _count, _, _duration, _expirationTime, _, _, _, _id = UnitAura(unit, NameNameArray[i], nil, Filter)
					
					-- If the name was found but the ID didnt match, check by ID.
					if _id and _id ~= iName and isNumber[iName] then
						for z=1, huge do
							_, _, _iconTexture, _count, _, _duration, _expirationTime, _, _, _, _id = UnitAura(unit, z, Filter)
							if not _id or _id == iName then
								break
							end
						end
					end
					
					if _id then
						break -- break spell loop
					end
				end
			end
			
			if _id and not useUnit then
				iconTexture, id, count, duration, expirationTime, useUnit =
				_iconTexture, _id, _count, _duration, _expirationTime, unit

			elseif not _id and icon.Alpha > 0 and not icon:YieldInfo(true, unit) then
				return
			end
		end
	end

	icon:YieldInfo(false, useUnit, iconTexture, count, duration, expirationTime, id)
end

function Type:HandleYieldedInfo(icon, iconToSet, unit, iconTexture, count, duration, expirationTime, id)
	if not unit then
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID",
			0,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			nil, nil
		)
	elseif not id then
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID",
			icon.Alpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			icon.NameFirst,
			unit, nil
		)
	elseif id then
		iconToSet:SetInfo("alpha; texture; start, duration; stack, stackText; spell; unit, GUID",
			icon.UnAlpha,
			iconTexture,
			expirationTime - duration, duration,
			count, count,
			id,
			unit, nil
		)
	end
end


function Type:Setup(icon)
	icon.NameFirst = TMW:GetSpellNames(icon.Name, 1, 1)
	--icon.NameName = TMW:GetSpellNames(icon.Name, 1, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon.Name, 1)
	icon.NameNameArray = TMW:GetSpellNames(icon.Name, 1, nil, 1)
	icon.NameHash = TMW:GetSpellNames(icon.Name, 1, nil, nil, 1)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	if icon.BuffOrDebuff == "EITHER" then
		icon:GetSettings().BuffOrDebuff = "HELPFUL"
		icon.BuffOrDebuff = "HELPFUL"
	end
	
	icon.Filter = icon.BuffOrDebuff
	if icon.OnlyMine then
		icon.Filter = icon.Filter .. "|PLAYER"
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

	icon:SetUpdateFunction(BuffCheck_OnUpdate)

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
	
Type:Register(101)

