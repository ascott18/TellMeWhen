local MAJOR_VERSION = "LibDogTag-Unit-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 193 $"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_Unit_MINOR_VERSION then
	_G.DogTag_Unit_MINOR_VERSION = MINOR_VERSION
end

if GetLocale() == "koKR" then

DogTag_Unit_funcs[#DogTag_Unit_funcs+1] = function(DogTag_Unit, DogTag)
	local L = DogTag_Unit.L
	
	-- races
	L["Blood Elf"] = "블러드 엘프"
	L["Draenei"] = "드레나이"
	L["Dwarf"] = "드워프"
	L["Gnome"] = "노움"
	L["Human"] = "인간"
	L["Night Elf"] = "나이트 엘프"
	L["Orc"] = "오크"
	L["Tauren"] = "타우렌"
	L["Troll"] = "트롤"
	L["Undead"] = "언데드"

	-- short races
	L["Blood Elf_short"] = "블엘"
	L["Draenei_short"] = "드레"
	L["Dwarf_short"] = "드웝"
	L["Gnome_short"] = "놈"
	L["Human_short"] = "인간"
	L["Night Elf_short"] = "나엘"
	L["Orc_short"] = "오크"
	L["Tauren_short"] = "타렌"
	L["Troll_short"] = "트롤"
	L["Undead_short"] = "언데"

	-- classes
	L["Death Knight"] = "죽음의 기사"
	L["Warrior"] = "전사"
	L["Priest"] = "사제"
	L["Mage"] = "마법사"
	L["Shaman"] = "주술사"
	L["Paladin"] = "성기사"
	L["Warlock"] = "흑마법사"
	L["Druid"] = "드루이드"
	L["Rogue"] = "도적"
	L["Hunter"] = "사냥꾼"
	L["Death Knight_female"] = "죽음의 기사"
	L["Warrior_female"] = "전사"
	L["Priest_female"] = "사제"
	L["Mage_female"] = "마법사"
	L["Shaman_female"] = "주술사"
	L["Paladin_female"] = "성기사"
	L["Warlock_female"] = "흑마법사"
	L["Druid_female"] = "드루이드"
	L["Rogue_female"] = "도적"
	L["Hunter_female"] = "사냥꾼"

	-- short classes
	L["Death Knight_short"] = "죽"
	L["Warrior_short"] = "전"
	L["Priest_short"] = "사"
	L["Mage_short"] = "마"
	L["Shaman_short"] = "주"
	L["Paladin_short"] = "성"
	L["Warlock_short"] = "흑"
	L["Druid_short"] = "드"
	L["Rogue_short"] = "도"
	L["Hunter_short"] = "냥"

	L["Player"] = "플레이어"
	L["Target"] = "대상"
	L["Focus-target"] = "주시 대상"
	L["Mouse-over"] = "마우스-오버"
	L["%s's pet"] = "%s의 소환수"
	L["%s's target"] = "%s의 대상"
	L["%s's %s"] = "%1$s's %2$s"
	L["Party member #%d"] = "파티원 #%d"
	L["Raid member #%d"] = "공격대원 #%d"
	L["%s's %s"] = "%s의 %s"

	-- classifications
	L["Rare"] = "희귀"
	L["Rare-Elite"] = "희귀" .. "-" .. ELITE
	L["Elite"] = "정예"
	L["Boss"] = "보스"
	-- short classifications
	L["Rare_short"] = "희"
	L["Rare-Elite_short"] = "희+"
	L["Elite_short"] = "+"
	L["Boss_short"] = "보"

	L["Feigned Death"] = "죽은척하기" -- must match aura
	L["Stealthed"] = "은신중"
	L["Soulstoned"] = "영혼석 보관"

	L["Dead"] = "죽음"
	L["Ghost"] = "유령"
	L["Offline"] = "오프중"
	L["Online"] = "접속중"
	L["Combat"] = "전투중"
	L["Resting"] = "휴식중"
	L["Tapped"] = "선점"
	L["AFK"] = "자리비움"
	L["DND"] = "다른용무중"

	L["Rage"] = "분노"
	L["Focus"] = "주시"
	L["Energy"] = "기력"
	L["Mana"] = "마나"
	L["Runic Power"] = "룬 마력"
	
	L["PvP"] = "전쟁" -- PVP
	L["FFA"] = "전투 지역"

	-- genders
	L["Male"] = "남자"
	L["Female"] = "여자"
	
	-- forms
	L["Bear"] = "곰"
	L["Cat"] = "표범"
	L["Moonkin"] = "달빛야수"
	L["Aquatic"] = "바다표범"
	L["Flight"] = "폭풍까마귀"
	L["Travel"] = "치타"
	L["Tree"] = "나무"

	L["Bear_short"] = "곰"
	L["Cat_short"] = "표범"
	L["Moonkin_short"] = "달빛"
	L["Aquatic_short"] = "바표"
	L["Flight_short"] = "폭까"
	L["Travel_short"] = "치타"
	L["Tree_short"] = "나무"

	-- shortgenders
	L["Male_short"] = "남"
	L["Female_short"] = "여"
	
	L["Leader"] = "지휘관"
	
	-- dispel types
	L["Magic"] = "마법"
	L["Curse"] = "저주"
	L["Poison"] = "독"
	L["Disease"] = "질병"
		
	L["Vehicle"] = "탈것"
end

end