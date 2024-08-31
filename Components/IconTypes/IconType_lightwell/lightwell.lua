-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local UnitGUID, GetGlyphSocketInfo, GetTotemInfo =
	  UnitGUID, GetGlyphSocketInfo, GetTotemInfo

local GetSpellTexture = TMW.GetSpellTexture

local _, pclass = UnitClass("Player")
local pGUID = nil -- UnitGUID() returns nil at load time, so we set this later.
local NUM_GLYPH_SLOTS = NUM_GLYPH_SLOTS

local Type = TMW.Classes.IconType:New("lightwell")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_LIGHTWELL"]
Type.desc = L["ICONMENU_LIGHTWELL_DESC"]
Type.hidden = pclass ~= "PRIEST"
Type.menuIcon = "Interface\\Icons\\Spell_Holy_SummonLightwell"
Type.hasNoGCD = true

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_HIDE

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes


Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)



Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_PRESENT] = { text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], },
	[STATE_ABSENT] =  { text = "|cFFFF0000" .. L["ICONMENU_ABSENT"],  },
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


local MaxCharges = CONST_MAX_CHARGES
local CurrentCharges = 0
local SummonTime
function Type:GLYPH()
	-- Fall back on the base number of charges.
	MaxCharges = CONST_MAX_CHARGES

	for i = 1, GetNumGlyphSockets() do
		local _, _, _, spellID = GetGlyphSocketInfo(i)
		if spellID == CONST_SPELLID_GLYPH then
			-- We have the glyph that gives us 2 extra charges.
			MaxCharges = CONST_MAX_CHARGES_GLYPHED
		end
	end

	for i = 1, #Type.Icons do
		-- Update all lightwell icons.
		Type.Icons[i].NextUpdateTime = 0
	end
end


function Type:COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, sourceGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
	if sourceGUID == pGUID then
		if event == "SPELL_SUMMON"
		and (spellID == CONST_SPELLID_LIGHTWELL_SUMMONSPELL or spellID == CONST_SPELLID_LIGHTSPRING_SUMMONSPELL)
		then
			-- The player has summoned a lightwell. Set our time variables and update all icons.
			CurrentCharges = MaxCharges
			SummonTime = TMW.time
			
			for i = 1, #Type.Icons do
				Type.Icons[i].NextUpdateTime = 0
			end
			
		elseif (event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED")
		and (spellID == CONST_SPELLID_LIGHTWELL_RENEW_HOT or spellID == CONST_SPELLID_LIGHTSPRING_RENEW_HOT)
		and CurrentCharges > 0
		then
			-- A lightwell has used a charge. Update the count and update all icons.
			CurrentCharges = CurrentCharges - 1
			
			for i = 1, #Type.Icons do
				Type.Icons[i].NextUpdateTime = 0
			end
		end
	end
end

function Type:PLAYER_TOTEM_UPDATE(_, slot)
	if slot == 1 and not GetTotemInfo(1) then
		-- Catch despawns/expirations. Then, update all icons.
		CurrentCharges = 0
		
		for i = 1, #Type.Icons do
			Type.Icons[i].NextUpdateTime = 0
		end
	end
end

local function LW_OnUpdate(icon, time)
	local have, _, start, duration = GetTotemInfo(1)

	if have then
		-- We have a lightwell, so show info about it.
		icon:SetInfo("state; start, duration; stack, stackText",
			STATE_PRESENT,
			start, duration,
			CurrentCharges, CurrentCharges
		)
	else
		-- No lightwell.
		icon:SetInfo("state; start, duration; stack, stackText",
			STATE_ABSENT,
			0, 0,
			nil, nil
		)
	end
end


function Type:Setup(icon)
	icon:SetInfo("texture; spell; reverse",
		GetSpellTexture(CONST_SPELLID_LIGHTWELL_SUMMONSPELL),
		CONST_SPELLID_LIGHTWELL_SUMMONSPELL,
		true
	)
	

	-- Register events and setup update functions.
	Type:RegisterEvent("PLAYER_TOTEM_UPDATE")
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("GLYPH_ADDED", 	 "GLYPH")
	-- Type:RegisterEvent("GLYPH_DISABLED", "GLYPH")
	-- Type:RegisterEvent("GLYPH_ENABLED",  "GLYPH")
	Type:RegisterEvent("GLYPH_REMOVED",  "GLYPH")
	Type:RegisterEvent("GLYPH_UPDATED",  "GLYPH")

	icon:SetUpdateMethod("manual")
	
	icon:SetUpdateFunction(LW_OnUpdate)
	icon:Update()
end

Type:Register(130)