local MAJOR_VERSION = "LibDogTag-Unit-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 182 $"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_Unit_MINOR_VERSION then
	_G.DogTag_Unit_MINOR_VERSION = MINOR_VERSION
end

if GetLocale() == "ruRU" then

DogTag_Unit_funcs[#DogTag_Unit_funcs+1] = function(DogTag_Unit, DogTag)
	local L = DogTag_Unit.L

	-- races
	L["Blood Elf"] = "Эльф крови"
	L["Draenei"] = "Дреней"
	L["Dwarf"] = "Дворф"
	L["Gnome"] = "Гном"
	L["Human"] = "Человек"
	L["Night Elf"] = "Ночной эльф"
	L["Orc"] = "Орк"
	L["Tauren"] = "Таурен"
	L["Troll"] = "Тролль"
	L["Undead"] = "Нежить"
	L["Blood Elf_female"] = "Эльфийка крови"
	L["Draenei_female"] = "Дреней"
	L["Dwarf_female"] = "Дворф"
	L["Gnome_female"] = "Гном"
	L["Human_female"] = "Человек"
	L["Night Elf_female"] = "Ночная эльфийка"
	L["Orc_female"] = "Орк"
	L["Tauren_female"] = "Таурен"
	L["Troll_female"] = "Тролль" -- TODO: check it
	L["Undead_female"] = "Нежить" -- TODO: check it
	
	-- short races
	L["Blood Elf_short"] = "БЭ"
	L["Draenei_short"] = "Др"
	L["Dwarf_short"] = "Дв"
	L["Gnome_short"] = "Гн"
	L["Human_short"] = "Че"
	L["Night Elf_short"] = "НЭ"
	L["Orc_short"] = "Ор"
	L["Tauren_short"] = "Та"
	L["Troll_short"] = "Тр"
	L["Undead_short"] = "Не"

	-- classes
	L["Warrior"] = "Воин"
	L["Priest"] = "Жрец"
	L["Mage"] = "Маг"
	L["Shaman"] = "Шаман"
	L["Paladin"] = "Паладин"
	L["Warlock"] = "Чернокнижник"
	L["Druid"] = "Друид"
	L["Rogue"] = "Разбойник"
	L["Hunter"] = "Охотник"
	L["Warrior_female"] = "Воин"
	L["Priest_female"] = "Жрица"
	L["Mage_female"] = "Маг"
	L["Shaman_female"] = "Шаманка"
	L["Paladin_female"] = "Паладин"
	L["Warlock_female"] = "Чернокнижница"
	L["Druid_female"] = "Друид"
	L["Rogue_female"] = "Разбойница"
	L["Hunter_female"] = "Охотница"
	
	-- short classes
	L["Warrior_short"] = "Вр"
	L["Priest_short"] = "Жр"
	L["Mage_short"] = "Мг"
	L["Shaman_short"] = "Ша"
	L["Paladin_short"] = "Па"
	L["Warlock_short"] = "Чк"
	L["Druid_short"] = "Др"
	L["Rogue_short"] = "Рз"
	L["Hunter_short"] = "Ох"

	-- No need to change: L["Player"] = PLAYER
	-- No need to change: L["Target"] = TARGET
	-- No need to change: L["Focus-target"] = FOCUS
	L["Mouse-over"] = "Наведение указателя мыши"
	L["%s's pet"] = "Питомец %s"
	L["%s's target"] = "Цель %s"
	L["%s's %s"] = "%1$s's %2$s"
	L["Party member #%d"] = "Член группы #%d"
	L["Raid member #%d"] = "Член рейда #%d"

	-- classifications
	-- No need to change: L["Rare"] = ITEM_QUALITY3_DESC
	-- No need to change: L["Rare-Elite"] = ITEM_QUALITY3_DESC and ELITE and ITEM_QUALITY3_DESC .. "-" .. ELITE
	-- No need to change: L["Elite"] = ELITE
	-- No need to change: L["Boss"] = BOSS	
	-- short classifications
	-- No need to change: L["Rare_short"] = "r"
	-- No need to change: L["Rare-Elite_short"] = "r+"
	-- No need to change: L["Elite_short"] = "+"
	-- No need to change: L["Boss_short"] = "b"

	L["Feigned Death"] = "Притворяется мертвым"
	L["Stealthed"] = "Незаметен"
	L["Soulstoned"] = "С камнем душ"
	
	-- No need to change: L["Dead"] = DEAD
	L["Ghost"] = "Призрак"
	-- No need to change: L["Offline"] = PLAYER_OFFLINE
	L["Online"] = "В сети"
	L["Combat"] = "В бою"
	L["Resting"] = "Отдых"
	L["Tapped"] = "Отмечена"
	L["AFK"] = "Отсутствует"
	L["DND"] = "Не беспокоить"
	
	-- No need to change: L["Rage"] = RAGE
	-- No need to change: L["Focus"] = FOCUS
	-- No need to change: L["Energy"] = ENERGY
	-- No need to change: L["Mana"] = MANA

	-- No need to change: L["PvP"] = PVP
	-- L["FFA"] = "FFA"

	-- genders
	-- No need to change: L["Male"] = MALE
	-- No need to change: L["Female"] = FEMALE

	-- forms
	L["Bear"] = "Медведь"
	L["Cat"] = "Кошка"
	L["Moonkin"] = "Сова"
	L["Aquatic"] = "Тюлень"
	L["Flight"] = "Птица"
	L["Travel"] = "Гепард"
	L["Tree"] = "Дерево"

	L["Bear_short"] = "Мд"
	L["Cat_short"] = "Кш"
	L["Moonkin_short"] = "Со"
	L["Aquatic_short"] = "Тю"
	L["Flight_short"] = "Пт"
	L["Travel_short"] = "Ге"
	L["Tree_short"] = "Де"

	-- shortgenders
	L["Male_short"] = "м"
	L["Female_short"] = "ж"
	
	L["Leader"] = "Лидер"
	
	-- dispel types
	L["Magic"] = "Магия"
	L["Curse"] = "Проклятие"
	L["Poison"] = "Яд"
	L["Disease"] = "Болезнь"
end

end