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

local gsub, bitband =
	  gsub, bit.band
local UnitGUID =
	  UnitGUID
local print = TMW.print
local huge = math.huge
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures
--local CL_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER

local clientVersion = select(4, GetBuildInfo())

local DRData = LibStub("DRData-1.0")

local DRSpells = DRData.spells
local DRReset = 17
local PvEDRs = {}
for spellID, category in pairs(DRSpells) do
	if DRData.pveDR[category] then
		PvEDRs[spellID] = 1
	end
end


local Type = TMW.Classes.IconType:New("dr")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_DR"]
Type.desc = L["ICONMENU_DR_DESC"]
Type.menuIcon = GetSpellTexture(408)
Type.usePocketWatch = 1
Type.unitType = "unitid"

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)


TMW:MergeDefaultsTables({
	global = {
		DRDuration = 17
	},
}, TMW.Defaults)

Type:RegisterIconDefaults{
	Unit					= "player", 
	CheckRefresh			= true,
	ShowWhenNone			= false,
}

TMW:RegisterUpgrade(70014, {
	icon = function(self, ics)
		-- DR categories that no longer exist (or never really existed):

		ics.Name = ics.Name:
			gsub("DR-DragonsBreath", "DR-ShortDisorient"):
			gsub("DR-BindElemental", "DR-Disorient"):
			gsub("DR-Charge", "DR-RandomStun"):
			gsub("DR-IceWard", "DR-RandomRoot"):
			gsub("DR-Scatter", "DR-ShortDisorient"):
			gsub("DR-Banish", "DR-Disorient"):
			gsub("DR-Entrapment", "DR-RandomRoot")
	end,
	})
Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	SUGType = "dr",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_DRABSENT"], 	},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_DRPRESENT"], 	},
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_DRSettings", function(self)
	self.Header:SetText(Type.name)
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "CheckRefresh",
			title = L["ICONMENU_CHECKREFRESH"],
			tooltip = L["ICONMENU_CHECKREFRESH_DESC"],
		},
		{
			setting = "ShowWhenNone",
			title = L["ICONMENU_SHOWWHENNONE"],
			tooltip = L["ICONMENU_SHOWWHENNONE_DESC"],
		},
	})
end)


TMW:RegisterCallback("TMW_EQUIVS_PROCESSING", function()
	if DRData then
		local myCategories = {
			ctrlstun		= "DR-ControlledStun",
			fear 			= "DR-Fear",
			rndstun			= "DR-RandomStun",
			silence			= "DR-Silence",
			mc 				= "DR-MindControl",
			taunt 			= "DR-Taunt",
			disarm			= "DR-Disarm",
			horror			= "DR-Horrify",
			cyclone			= "DR-Cyclone",
			disorient		= "DR-Disorient",
			shortdisorient	= "DR-ShortDisorient",
			ctrlroot		= "DR-ControlledRoot", 
			shortroot		= "DR-RandomRoot",
		}
		
		TMW.BE.dr = {}
		local dr = TMW.BE.dr
		for spellID, category in pairs(DRData.spells) do
			local k = myCategories[category]

			if k then
				dr[k] = (dr[k] and (dr[k] .. ";" .. spellID)) or tostring(spellID)
			elseif TMW.debug then
				TMW:Error("The DR category %q is undefined!", category)
			end
		end
	end
end)

local function DR_OnEvent(icon, event, arg1, cevent, _, _, _, _, _, destGUID, _, destFlags, _, spellID, spellName, _, auraType)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if auraType == "DEBUFF" and (cevent == "SPELL_AURA_REMOVED" or cevent == "SPELL_AURA_APPLIED" or (icon.CheckRefresh and cevent == "SPELL_AURA_REFRESH")) then
			local NameHash = icon.NameHash
			if NameHash[spellID] or NameHash[strlowerCache[spellName]] then
				if PvEDRs[spellID] or bitband(destFlags, CL_CONTROL_PLAYER) == CL_CONTROL_PLAYER then
					local dr = icon.DRInfo[destGUID]
					if cevent == "SPELL_AURA_APPLIED" then
						if dr and dr.start + dr.duration <= TMW.time then
							dr.start = 0
							dr.duration = 0
							dr.amt = 100
						end
					else
						if not dr then
							dr = {
								amt = 50,
								start = TMW.time,
								duration = DRReset,
								tex = SpellTextures[spellID]
							}
							icon.DRInfo[destGUID] = dr
						else
							local amt = dr.amt
							if amt and amt ~= 0 then
								dr.amt = amt > 25 and amt/2 or 0
								dr.duration = DRReset
								dr.start = TMW.time
								dr.tex = SpellTextures[spellID]
							end
						end
					end
					
					icon.NextUpdateTime = 0
				end
			end
		end
	elseif event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		icon.NextUpdateTime = 0
	end
end

local function DR_OnUpdate(icon, time)
	local Alpha, UnAlpha, Units = icon.Alpha, icon.UnAlpha, icon.Units

	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)
		local dr = icon.DRInfo[GUID]

		if dr then
			if dr.start + dr.duration <= time then
				icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
					icon.Alpha,
					dr.tex,
					0, 0,
					nil, nil,
					unit, GUID
				)
				
				if Alpha > 0 then
					return
				end
			else
				local duration = dr.duration
				local amt = dr.amt
				
				icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
					icon.UnAlpha,
					dr.tex,
					dr.start, duration,
					amt, amt .. "%",
					unit, GUID
				)
				if UnAlpha > 0 then
					return
				end
			end
		else
			icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
				icon.Alpha,
				icon.FirstTexture,
				0, 0,
				nil, nil,
				unit, GUID
			)
			if Alpha > 0 then
				return
			end
		end
	end
	
	if icon.ShowWhenNone then
		icon:SetInfo("alpha; texture; start, duration; stack, stackText; unit, GUID",
			icon.Alpha,
			icon.FirstTexture,
			0, 0,
			nil, nil,
			Units[1], nil
		)
	else
		icon:SetInfo("alpha", 0)
	end
end

function Type:FormatSpellForOutput(icon, data, doInsertLink)
	return data and (L[data] or gsub(data, "DR%-", ""))
end

local CheckCategories
do	-- CheckCategories
	local func = TMW:MakeSingleArgFunctionCached(function(NameArray)
		local categoryTEMP = setmetatable({}, {
			__index = function(t, k)
				-- a ghetto sort mechanism
				local len = 1
				for k, v in pairs(t) do
					len = len + 1
				end
				local str = format("%3.0f\001", len)
				t[k] = str
				return str
			end
		})

		local firstCategory, doWarn
		local append = ""

		for i, IDorName in ipairs(NameArray) do
			for category, str in pairs(TMW.BE.dr) do
				if TMW:IsStringInSemicolonList(str, IDorName) or TMW:GetSpellNames(str, 1, nil, 1, 1)[IDorName] then
					if not firstCategory then
						firstCategory = category
					end
					categoryTEMP[category] = categoryTEMP[category] .. ";" .. TMW:RestoreCase(IDorName)
					if firstCategory ~= category then
						doWarn = true
					end
				end
			end
		end

		if next(categoryTEMP) then
			for category, string in TMW:OrderedPairs(categoryTEMP, "values") do
				string = strmatch(string, ".*\001(.*)")
				append = append .. format("\r\n\r\n%s:\r\n%s", L[category], TMW:CleanString(string))
			end
		end
		
		return {
			append = append,
			doWarn = doWarn,
			firstCategory = firstCategory,
		}
	end)

	CheckCategories = function(icon)
		local result = func(icon.NameArray)
		icon:SetInfo("spell", result.firstCategory)

		if icon:IsBeingEdited() == "MAIN" and TellMeWhen_ChooseName then
			if result.doWarn then
				TMW.HELP:Show("ICON_DR_MISMATCH", icon, TellMeWhen_ChooseName, 0, 0, L["WARN_DRMISMATCH"] .. result.append)
			else
				TMW.HELP:Hide("ICON_DR_MISMATCH")
			end
		end
	end
end


function Type:Setup(icon)
	icon.NameFirst = TMW:GetSpellNames(icon.Name, 1, 1)
	icon.NameArray = TMW:GetSpellNames(icon.Name, 1)
	icon.NameHash = TMW:GetSpellNames(icon.Name, 1, nil, nil, 1)
	
	-- This looks really stupid, but it works exactly how it should.
	local oldDRName = icon.Name
	if not icon.oldDRName then
		icon.DRInfo = icon.DRInfo or {}
		icon.oldDRName = icon.Name
	elseif icon.DRInfo and oldDRName ~= icon.Name then
		wipe(icon.DRInfo)
	end
	
	DRReset = TMW.db.global.DRDuration
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)
	
	icon.FirstTexture = SpellTextures[icon.NameFirst]

	-- Do the Right Thing and tell people if their DRs mismatch
	CheckCategories(icon)

	icon:SetInfo("texture", Type:GetConfigIconTexture(icon))

	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
		for event in pairs(icon.UnitSet.updateEvents) do
			icon:RegisterSimpleUpdateEvent(event)
		end
		
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", DR_OnEvent, icon)
	end
	
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	icon:SetScript("OnEvent", DR_OnEvent)

	icon:SetUpdateFunction(DR_OnUpdate)
	icon:Update()
end

Type:Register(140)