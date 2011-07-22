local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)

L["HELP_FIRSTUCD"] = L["HELP_FIRSTUCD"]:format(GetSpellInfo(65547), GetSpellInfo(47528), GetSpellInfo(2139), GetSpellInfo(62618), GetSpellInfo(62618))
L["HELP_MISSINGDURS"] = L["HELP_MISSINGDURS"]:format("%s", GetSpellInfo(1766)) -- keep the first "%s" as "%s"
L["CONDITIONPANEL_UNIT_DESC"] = L["CONDITIONPANEL_UNIT_DESC"]:format(UnitName("player"))
