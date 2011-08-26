﻿local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)

L["HELP_FIRSTUCD"] = L["HELP_FIRSTUCD"]:format(L["ICONMENU_CHOOSENAME"], GetSpellInfo(65547), GetSpellInfo(47528), GetSpellInfo(2139), GetSpellInfo(62618), GetSpellInfo(62618))
L["HELP_MISSINGDURS"] = L["HELP_MISSINGDURS"]:format("%s", GetSpellInfo(1766)) -- keep the first "%s" as "%s"
L["CONDITIONPANEL_UNIT_DESC"] = L["CONDITIONPANEL_UNIT_DESC"]:format(UnitName("player"))
L["ICONMENU_IGNORENOMANA_DESC"] = L["ICONMENU_IGNORENOMANA_DESC"]:format(GetSpellInfo(85288), GetSpellInfo(5308))
L["ICONMENU_SPELLCAST_COMPLETE_DESC"] = L["ICONMENU_SPELLCAST_COMPLETE_DESC"]:format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_SPELLCAST_START_DESC"] = L["ICONMENU_SPELLCAST_START_DESC"]:format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_ICDAURA_DESC"] = L["ICONMENU_ICDAURA_DESC"]:format(L["ICONMENU_CHOOSENAME"])
L["CHOOSENAME_EQUIVS_TOOLTIP"] = L["CHOOSENAME_EQUIVS_TOOLTIP"]:format(L["ICONMENU_CHOOSENAME"])
L["SORTBYNONE_DESC"] = L["SORTBYNONE_DESC"]:format(L["ICONMENU_CHOOSENAME"])
L["ICONMENU_CNDTIC_DESC"] = L["ICONMENU_CNDTIC_DESC"]:format(L["ICONMENU_CHOOSENAME_CNDTIC"])
