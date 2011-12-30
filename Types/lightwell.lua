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

local db, ClockGCD
local strlower =
	  strlower
local UnitGUID, GetGlyphSocketInfo =
	  UnitGUID, GetGlyphSocketInfo
local print = TMW.print
local SpellTextures = TMW.SpellTextures
local _, pclass = UnitClass("Player")
local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too

local clientVersion = select(4, GetBuildInfo())


local Type = {}
Type.type = "lightwell"
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_LIGHTWELL"]
Type.desc = L["ICONMENU_LIGHTWELL_DESC"]
Type.hidden = pclass ~= "PRIEST"
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	Name = false,
	ShowCBar = true,
	CBarOffs = true,
	ShowPBar = true,
	PBarOffs = true,
	InvertBars = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
}

Type.EventDisabled_OnUnit = true
Type.EventDisabled_OnSpell = true

function Type:Update()
	db = TMW.db
	pGUID = UnitGUID("player")
	
	self:GLYPH()
end

local MaxCharges = 10
local CurrentCharges = 0
local SummonTime
function Type:GLYPH()
	for i = 7, NUM_GLYPH_SLOTS do
		local _, _, _, spellID = GetGlyphSocketInfo(i);
		if spellID == 55673 then 
			MaxCharges = 15
			return
		end
	end
	MaxCharges = 10
end
Type:RegisterEvent("GLYPH_ADDED", 	 "GLYPH")
Type:RegisterEvent("GLYPH_DISABLED", "GLYPH")
Type:RegisterEvent("GLYPH_ENABLED",  "GLYPH")
Type:RegisterEvent("GLYPH_REMOVED",  "GLYPH")
Type:RegisterEvent("GLYPH_UPDATED",  "GLYPH")


function Type:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, _, sourceGUID, _, _, _, _, _, _, _, spellID)
	if sourceGUID == pGUID then		
		if event == "SPELL_SUMMON" and spellID == 724 then
			CurrentCharges = MaxCharges
			SummonTime = TMW.time
		elseif (event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED") and spellID == 7001 and CurrentCharges > 0 then
			CurrentCharges = CurrentCharges - 1
		end
	end
end
Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

function Type:PLAYER_TOTEM_UPDATE(_, slot)
	if slot == 1 and not GetTotemInfo(1) then
		-- catch despawns/expirations
		CurrentCharges = 0
	end
end
Type:RegisterEvent("PLAYER_TOTEM_UPDATE")

local function LW_OnUpdate(icon, time)
	if SummonTime and SummonTime + 180 < time then
		CurrentCharges = 0
	end
	
	local color = icon:CrunchColor(CurrentCharges) -- eww, passing # of charges as the duration. Hackerish....
	
	if CurrentCharges > 0 then
		icon:SetInfo(icon.Alpha, color, nil, SummonTime, 180, 724, nil, CurrentCharges, CurrentCharges, nil, nil)
	else
		icon:SetInfo(icon.UnAlpha, color, nil, 0, 0, 724, nil, nil, nil, nil, nil)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = 724
	
	icon:SetTexture(SpellTextures[724])

	icon:SetScript("OnUpdate", LW_OnUpdate)
	icon:Update()
end

TMW:RegisterIconType(Type)