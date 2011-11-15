local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)

local spellFmt = "|T%s:0|t%s"
local function Spell(id)
	local name, _, tex = GetSpellInfo(id)
	if id == 42292 then
		tex = "Interface\\Icons\\inv_jewelry_trinketpvp_0" .. (UnitFactionGroup("player") == "Horde" and "2" or "1")
	end
	return spellFmt:format(tex, name)
end


L["HELP_FIRSTUCD"] 					  = L["HELP_FIRSTUCD"]			 		 :format(L["ICONMENU_CHOOSENAME"], GetSpellInfo(65547), GetSpellInfo(47528), GetSpellInfo(2139), GetSpellInfo(62618), GetSpellInfo(62618))
L["HELP_MISSINGDURS"] 				  = L["HELP_MISSINGDURS"]			 	 :format("%s", GetSpellInfo(1766)) -- keep the first "%s" as "%s"
L["ICONMENU_IGNORENOMANA_DESC"] 	  = L["ICONMENU_IGNORENOMANA_DESC"]		 :format(Spell(85288), Spell(5308))
L["ICONMENU_REACTIVE_DESC"] 		  = L["ICONMENU_REACTIVE_DESC"]	 		 :format(Spell(53351), Spell(6572), Spell(17962))
L["ICONMENU_GHOUL_DESC"] 			  = L["ICONMENU_GHOUL_DESC"]		 	 :format(Spell(52143))
L["ICONMENU_MUSHROOMS"] 			  = L["ICONMENU_MUSHROOMS"]		 		 :format(GetSpellInfo(88747))
L["ICONMENU_MUSHROOMS_DESC"] 		  = L["ICONMENU_MUSHROOMS_DESC"]	 	 :format(Spell(88747))
L["ICONMENU_UNITCOOLDOWN_DESC"] 	  = L["ICONMENU_UNITCOOLDOWN_DESC"]		 :format(Spell(42292), GetSpellInfo(42292))
L["ICONMENU_MULTISTATECD_DESC"] 	  = L["ICONMENU_MULTISTATECD_DESC"]		 :format(Spell(88625), Spell(77606))
L["HELP_ICD_NATURESGRACE"] 	  		  = L["HELP_ICD_NATURESGRACE"]		 	 :format(Spell(16886), L["ICONMENU_UNITCOOLDOWN"])


L["ICONMENU_ICD_DESC"] 	  			  = L["ICONMENU_ICD_DESC"]		 		 :format(L["ICONMENU_ICDTYPE"])
L["MESSAGERECIEVE"] 	  			  = L["MESSAGERECIEVE"]		 		 	 :format("%s", L["IMPORT_EXPORT"]) -- keep the first "%s" as "%s"


local pname 						  = UnitName("player")
L["CONDITIONPANEL_UNIT_DESC"] 		  = L["CONDITIONPANEL_UNIT_DESC"]		 :format(pname)
L["ICONMENU_UNIT_DESC"] 			  = L["ICONMENU_UNIT_DESC"]				 :format(pname)

L["ICONMENU_SPELLCAST_COMPLETE_DESC"] = L["ICONMENU_SPELLCAST_COMPLETE_DESC"]:format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_SPELLCAST_START_DESC"] 	  = L["ICONMENU_SPELLCAST_START_DESC"]	 :format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_ICDAURA_DESC"] 			  = L["ICONMENU_ICDAURA_DESC"]			 :format(L["ICONMENU_CHOOSENAME"])
L["CHOOSENAME_EQUIVS_TOOLTIP"] 		  = L["CHOOSENAME_EQUIVS_TOOLTIP"]		 :format(L["ICONMENU_CHOOSENAME"])
L["SORTBYNONE_DESC"] 				  = L["SORTBYNONE_DESC"]				 :format(L["ICONMENU_CHOOSENAME"])

--L["ICONMENU_CNDTIC_DESC"] 			  = L["ICONMENU_CNDTIC_DESC"]			 :format(L["ICONMENU_CHOOSENAME_CNDTIC"])

L["SOUND_EVENT_ONSHOW_DESC"]   		  = L["SOUND_EVENT_ONSHOW_DESC"]	 	 :format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["SOUND_EVENT_ONHIDE_DESC"]   		  = L["SOUND_EVENT_ONHIDE_DESC"]	 	 :format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["CONDITIONPANEL_ICON_DESC"]   	  = L["CONDITIONPANEL_ICON_DESC"]	 	 :format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["ICONMENU_META_DESC"]   			  = L["ICONMENU_META_DESC"]	 			 :format(L["ICONALPHAPANEL_FAKEHIDDEN"])


L["ICONMENU_CHOOSENAME_ITEMSLOT"]     = L["ICONMENU_CHOOSENAME_ITEMSLOT"]	 :format(INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED)

