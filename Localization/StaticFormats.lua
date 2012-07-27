local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)

local pname = UnitName("player")

local spellFmt = "|T%s:0|t%s"
local function Spell(id)
	local name, _, tex = GetSpellInfo(id)
	if not name or not tex then
		error("TMW: UNKNOWN SPELLID: " .. id)
	end
	if id == 42292 then
		tex = "Interface\\Icons\\inv_jewelry_trinketpvp_0" .. (UnitFactionGroup("player") == "Horde" and "2" or "1")
	end
	return spellFmt:format(tex, name)
end


L["HELP_FIRSTUCD"] 					  	= L["HELP_FIRSTUCD"]			 		 	:format(L["ICONMENU_CHOOSENAME"], GetSpellInfo(65547), GetSpellInfo(47528), GetSpellInfo(2139), GetSpellInfo(62618), GetSpellInfo(62618))
L["HELP_MISSINGDURS"] 				  	= L["HELP_MISSINGDURS"]			 	 		:format("%s", GetSpellInfo(1766)) -- keep the first "%s" as "%s"
L["ICONMENU_IGNORENOMANA_DESC"] 	  	= L["ICONMENU_IGNORENOMANA_DESC"]		 	:format(Spell(85288), Spell(5308))
L["ICONMENU_REACTIVE_DESC"] 		  	= L["ICONMENU_REACTIVE_DESC"]	 		 	:format(Spell(53351), Spell(6572), Spell(17962))
L["ICONMENU_GHOUL_DESC"] 			  	= L["ICONMENU_GHOUL_DESC"]		 	 		:format(Spell(52143))
L["ICONMENU_MUSHROOMS"] 			  	= L["ICONMENU_MUSHROOMS"]		 			:format(GetSpellInfo(88747))
L["ICONMENU_MUSHROOMS_DESC"] 		  	= L["ICONMENU_MUSHROOMS_DESC"]	 		 	:format(Spell(88747))
L["ICONMENU_UNITCOOLDOWN_DESC"] 	  	= L["ICONMENU_UNITCOOLDOWN_DESC"]		 	:format(Spell(42292), GetSpellInfo(42292))
L["ICONMENU_MULTISTATECD_DESC"] 	  	= L["ICONMENU_MULTISTATECD_DESC"]		 	:format(Spell(88625), Spell(77606))
L["HELP_ICD_NATURESGRACE"] 	  		  	= L["HELP_ICD_NATURESGRACE"]		 	 	:format(Spell(16886), L["ICONMENU_UNITCOOLDOWN"])
L["CLEU_DAMAGE_SHIELD_DESC"] 	  	  	= L["CLEU_DAMAGE_SHIELD_DESC"]		 		:format(Spell(31271), Spell(30482), Spell(324))
L["CLEU_DAMAGE_SHIELD_MISSED_DESC"]   	= L["CLEU_DAMAGE_SHIELD_MISSED_DESC"]	 	:format(Spell(31271), Spell(30482), Spell(324))
L["CLEU_SPELL_STOLEN_DESC"]   		  	= L["CLEU_SPELL_STOLEN_DESC"]	 		 	:format(Spell(30449))


L["ICONMENU_ICD_DESC"] 	  			  	= L["ICONMENU_ICD_DESC"]		 		 	:format(L["ICONMENU_ICDTYPE"])
L["MESSAGERECIEVE"] 	  			  	= L["MESSAGERECIEVE"]		 		 	 	:format("%s", L["IMPORT_EXPORT"]) -- keep the first "%s" as "%s"
L["TEXTLAYOUTS_NOEDIT_DESC"] 	  	  	= L["TEXTLAYOUTS_NOEDIT_DESC"] 		 	 	:format(L["IMPORT_EXPORT"])


L["CONDITIONPANEL_UNIT_DESC"] 		  	= L["CONDITIONPANEL_UNIT_DESC"]		 		:format(pname)
L["ICONMENU_UNIT_DESC"] 			  	= L["ICONMENU_UNIT_DESC"]				 	:format(pname)

L["SOUND_EVENT_ONSTACK_DESC"] 		  	= L["SOUND_EVENT_ONSTACK_DESC"]		 		:format(L["ICONMENU_DRS"])

L["ICONMENU_SPELLCAST_COMPLETE_DESC"] 	= L["ICONMENU_SPELLCAST_COMPLETE_DESC"]		:format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_SPELLCAST_START_DESC"] 	  	= L["ICONMENU_SPELLCAST_START_DESC"]	 	:format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_ICDAURA_DESC"] 			  	= L["ICONMENU_ICDAURA_DESC"]			 	:format(L["ICONMENU_CHOOSENAME"])
L["CHOOSENAME_EQUIVS_TOOLTIP"] 		  	= L["CHOOSENAME_EQUIVS_TOOLTIP"]		 	:format(L["ICONMENU_CHOOSENAME"])
L["SORTBYNONE_DESC"]					= L["SORTBYNONE_DESC"]				 		:format(L["ICONMENU_CHOOSENAME"])
L["CLEU_TIMER_DESC"]					= L["CLEU_TIMER_DESC"]				 		:format(L["ICONMENU_CHOOSENAME"], L["ICONMENU_CHOOSENAME"])

--L["ICONMENU_CNDTIC_DESC"] 			= L["ICONMENU_CNDTIC_DESC"]					:format(L["ICONMENU_CHOOSENAME_CNDTIC"])

L["SOUND_EVENT_ONSHOW_DESC"]		  	= L["SOUND_EVENT_ONSHOW_DESC"]	 	 		:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["SOUND_EVENT_ONHIDE_DESC"]		  	= L["SOUND_EVENT_ONHIDE_DESC"]	 	 		:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["CONDITIONPANEL_ICON_DESC"]		  	= L["CONDITIONPANEL_ICON_DESC"]	 	 		:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["ICONMENU_META_DESC"]				  	= L["ICONMENU_META_DESC"]	 			 	:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_alpha"]			= L["UIPANEL_GROUPSORT_alpha"]				:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_alpha_DESC"]		= L["UIPANEL_GROUPSORT_alpha_DESC"]			:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_visiblealpha"]		= L["UIPANEL_GROUPSORT_visiblealpha"]		:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_visiblealpha_DESC"]= L["UIPANEL_GROUPSORT_visiblealpha_DESC"]	:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_shown"]			= L["UIPANEL_GROUPSORT_shown"]				:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_shown_DESC"]		= L["UIPANEL_GROUPSORT_shown_DESC"]			:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_visibleshown"]		= L["UIPANEL_GROUPSORT_visibleshown"]		:format(L["ICONALPHAPANEL_FAKEHIDDEN"])
L["UIPANEL_GROUPSORT_visibleshown_DESC"]= L["UIPANEL_GROUPSORT_visibleshown_DESC"]	:format(L["ICONALPHAPANEL_FAKEHIDDEN"])


L["ICONMENU_CHOOSENAME_ITEMSLOT"]	 	= L["ICONMENU_CHOOSENAME_ITEMSLOT"]	 		:format(INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED)


L["COLOR_CTA_DESC"]	 				  	= L["COLOR_CTA_DESC"]					 	:format(L["ICONMENU_SHOWTIMER"], "%s", L["ICONMENU_ALWAYS"])
L["COLOR_COA_DESC"]	 				  	= L["COLOR_COA_DESC"]					 	:format(L["ICONMENU_SHOWTIMER"], "%s", L["ICONMENU_ALWAYS"])
L["COLOR_CTS_DESC"]	 				  	= L["COLOR_CTS_DESC"]					 	:format(L["ICONMENU_SHOWTIMER"], "%s", L["ICONMENU_ALWAYS"])
L["COLOR_COS_DESC"]	 				  	= L["COLOR_COS_DESC"]					 	:format(L["ICONMENU_SHOWTIMER"], "%s", L["ICONMENU_ALWAYS"])
L["COLOR_NA_DESC"]	 				  	= L["COLOR_NA_DESC"]					 	:format("%s", L["ICONMENU_ALWAYS"])
L["COLOR_NS_DESC"]	 				  	= L["COLOR_NS_DESC"]					 	:format("%s", L["ICONMENU_ALWAYS"])

L["COLOR_HEADER"] 					  	= L["COLOR_HEADER"]					 		:format("%s", L["COLOR_OVERRIDEDEFAULT"])

L["CLEU_NOFILTERS"] 				  	= L["CLEU_NOFILTERS"]						:format(L["ICONMENU_CLEU"], "%s")
L["CLEU_SPELL_DAMAGE_CRIT_DESC"]   	  	= L["CLEU_SPELL_DAMAGE_CRIT_DESC"]	 		:format(L["CLEU_SPELL_DAMAGE"])

L["SOUND_CHANNEL_DESC"] 				= L["SOUND_CHANNEL_DESC"] 					:format(L["SOUND_CHANNEL_MASTER"])

L["ANIM_INFINITE_DESC"] 				= L["ANIM_INFINITE_DESC"] 					:format(L["ANIM_ICONCLEAR"])

L["DT_DOC_Source"] 					  	= L["DT_DOC_Source"] 						:format(L["ICONMENU_CLEU"])
L["DT_DOC_Destination"] 			  	= L["DT_DOC_Destination"] 					:format(L["ICONMENU_CLEU"])
L["DT_DOC_Extra"] 					  	= L["DT_DOC_Extra"]	 						:format(L["ICONMENU_CLEU"])

L["CLEU_SOURCEUNITS_DESC"] 			  	= L["CLEU_SOURCEUNITS_DESC"] .. "\r\n\r\n" .. L["ICONMENU_UNIT_DESC"]
L["CLEU_DESTUNITS_DESC"] 			  	= L["CLEU_DESTUNITS_DESC"]   .. "\r\n\r\n" .. L["ICONMENU_UNIT_DESC"]

if select(4, GetBuildInfo()) >= 50000 then -- ISMOP
	L["ICONMENU_CUSTOMTEX_DESC"] = L["ICONMENU_CUSTOMTEX_DESC"] .. "\r\n\r\n" .. "|cffff0000MISTS OF PANDARIA BETA NOTE: Blizzard has what seems to be some temporary debugging code on their end that is interfering with TMW's ability to properly detect textures. If this icon is showing with a solid green texture, and your custom texture is in WoW's root folder, then please move it into a subdirectory of WoW's root and update the setting here accordingly to allow it to work correctly. If the custom texture is set to a spell, and it is either a spell name or a spell that no longer exists, then you should try and change it to a spellID of a spell that does exist. Sorry for the inconvenience!"
end