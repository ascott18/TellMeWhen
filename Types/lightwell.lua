-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
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
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], 			 },
	{ value = "unalpha", 		text = "|cFFFF0000" .. L["ICONMENU_ABSENT"], 			 },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("spell")
Type:UsesAttributes("alpha")
Type:UsesAttributes("color")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("stack, stackText")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type.EventDisabled_OnUnit = true
Type.EventDisabled_OnSpell = true

function Type:Update()
	pGUID = UnitGUID("player")

	self:GLYPH()
end

local MaxCharges = 10
local CurrentCharges = 0
local SummonTime
function Type:GLYPH()
	for i = 7, NUM_GLYPH_SLOTS do
		local _, _, _, spellID = GetGlyphSocketInfo(i)
		if spellID == 55673 then
			MaxCharges = 15
			return
		end
	end
	MaxCharges = 10
	for i = 1, #Type.Icons do
		Type.Icons[i].NextUpdateTime = 0
	end
end


function Type:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, _, sourceGUID, _, _, _, _, _, _, _, spellID)
	if sourceGUID == pGUID then
		if event == "SPELL_SUMMON" and spellID == 724 then
			CurrentCharges = MaxCharges
			SummonTime = TMW.time
			
			for i = 1, #Type.Icons do
				Type.Icons[i].NextUpdateTime = 0
			end
		elseif (event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED") and spellID == 7001 and CurrentCharges > 0 then
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
	if SummonTime and SummonTime + 180 < time then
		CurrentCharges = 0
	end

	local color = icon:CrunchColor(CurrentCharges) -- eww, passing # of charges as the duration. Hackerish....

	if CurrentCharges > 0 then
		icon:SetInfo("alpha; color; start, duration; stack, stackText",
			icon.Alpha,
			color,
			SummonTime, 180,
			CurrentCharges, CurrentCharges
		)
	else
		icon:SetInfo("alpha; color; start, duration; stack, stackText",
			icon.UnAlpha,
			color,
			0, 0,
			nil, nil
		)
	end
end


function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = 724

	icon:SetInfo("texture; spell",
		SpellTextures[724],
		724
	)
	
	Type:RegisterEvent("PLAYER_TOTEM_UPDATE")
	Type:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Type:RegisterEvent("GLYPH_ADDED", 	 "GLYPH")
	Type:RegisterEvent("GLYPH_DISABLED", "GLYPH")
	Type:RegisterEvent("GLYPH_ENABLED",  "GLYPH")
	Type:RegisterEvent("GLYPH_REMOVED",  "GLYPH")
	Type:RegisterEvent("GLYPH_UPDATED",  "GLYPH")

	icon:SetUpdateMethod("manual")
	
	icon:SetScript("OnUpdate", LW_OnUpdate)
	icon:Update()
end

Type:Register()