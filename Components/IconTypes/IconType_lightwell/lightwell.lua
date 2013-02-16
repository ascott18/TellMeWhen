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

local strlower =
	  strlower
local UnitGUID, GetGlyphSocketInfo, GetTotemInfo =
	  UnitGUID, GetGlyphSocketInfo, GetTotemInfo
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local _, pclass = UnitClass("Player")
local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too

local clientVersion = select(4, GetBuildInfo())


local Type = TMW.Classes.IconType:New("lightwell")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_LIGHTWELL"]
Type.desc = L["ICONMENU_LIGHTWELL_DESC"]
Type.hidden = pclass ~= "PRIEST"
Type.menuIcon = "Interface\\Icons\\Spell_Holy_SummonLightwell"

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("alpha")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_WhenChecks", {
	text = L["ICONMENU_SHOWWHEN"],
	[0x2] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], 		},
	[0x1] = { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"], 			},
})

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	pGUID = UnitGUID("player")

	Type:GLYPH()
end)

local CONST_MAX_CHARGES = 10
local CONST_MAX_CHARGES_GLYPHED = 15
local CONST_SPELLID_GLYPH = 55673

local CONST_SPELLID_LIGHTWELL_SUMMONSPELL = 724
local CONST_SPELLID_LIGHTWELL_RENEW_HOT = 7001

local CONST_SPELLID_LIGHTSPRING_SUMMONSPELL = 126135
local CONST_SPELLID_LIGHTSPRING_RENEW_HOT = 126154

if TMW.ISMOP then
	CONST_MAX_CHARGES = 15
	CONST_MAX_CHARGES_GLYPHED = 17
end

local MaxCharges = CONST_MAX_CHARGES
local CurrentCharges = 0
local SummonTime
function Type:GLYPH()
	for i = 1, NUM_GLYPH_SLOTS do
		local _, _, _, spellID = GetGlyphSocketInfo(i)
		if spellID == CONST_SPELLID_GLYPH then
			MaxCharges = CONST_MAX_CHARGES_GLYPHED
			return
		end
	end
	MaxCharges = CONST_MAX_CHARGES
	for i = 1, #Type.Icons do
		Type.Icons[i].NextUpdateTime = 0
	end
end


function Type:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, _, sourceGUID, _, _, _, _, _, _, _, spellID)
	if sourceGUID == pGUID then
		if event == "SPELL_SUMMON"
		and (spellID == CONST_SPELLID_LIGHTWELL_SUMMONSPELL or spellID == CONST_SPELLID_LIGHTSPRING_SUMMONSPELL)
		then
			CurrentCharges = MaxCharges
			SummonTime = TMW.time
			
			for i = 1, #Type.Icons do
				Type.Icons[i].NextUpdateTime = 0
			end
			
		elseif (event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED")
		and (spellID == CONST_SPELLID_LIGHTWELL_RENEW_HOT or spellID == CONST_SPELLID_LIGHTSPRING_RENEW_HOT)
		and CurrentCharges > 0
		then
			CurrentCharges = CurrentCharges - 1
			
			for i = 1, #Type.Icons do
				Type.Icons[i].NextUpdateTime = 0
			end
		end
	end
end

function Type:PLAYER_TOTEM_UPDATE(_, slot)
	if slot == 1 and not GetTotemInfo(1) then
		-- catch despawns/expirations
		CurrentCharges = 0
		
		for i = 1, #Type.Icons do
			Type.Icons[i].NextUpdateTime = 0
		end
	end
end

local function LW_OnUpdate(icon, time)
	local have, _, start, duration = GetTotemInfo(1)

	if have then
		icon:SetInfo("alpha; start, duration; stack, stackText",
			icon.Alpha,
			start, duration,
			CurrentCharges, CurrentCharges
		)
	else
		icon:SetInfo("alpha; start, duration; stack, stackText",
			icon.UnAlpha,
			0, 0,
			nil, nil
		)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = CONST_SPELLID_LIGHTWELL_SUMMONSPELL

	icon:SetInfo("texture; spell; reverse",
		SpellTextures[CONST_SPELLID_LIGHTWELL_SUMMONSPELL],
		CONST_SPELLID_LIGHTWELL_SUMMONSPELL,
		true
	)
	
	Type:RegisterEvent("PLAYER_TOTEM_UPDATE")
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("GLYPH_ADDED", 	 "GLYPH")
	Type:RegisterEvent("GLYPH_DISABLED", "GLYPH")
	Type:RegisterEvent("GLYPH_ENABLED",  "GLYPH")
	Type:RegisterEvent("GLYPH_REMOVED",  "GLYPH")
	Type:RegisterEvent("GLYPH_UPDATED",  "GLYPH")

	icon:SetUpdateMethod("manual")
	
	icon:SetUpdateFunction(LW_OnUpdate)
	icon:Update()
end

Type:Register(130)