local MAJOR_VERSION = "LibDogTag-Unit-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 182 $"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_Unit_MINOR_VERSION then
	_G.DogTag_Unit_MINOR_VERSION = MINOR_VERSION
end

if GetLocale() == "frFR" then

DogTag_Unit_funcs[#DogTag_Unit_funcs+1] = function(DogTag_Unit, DogTag)
	local L = DogTag_Unit.L

	-- races
	L["Blood Elf"] = "Elfe de sang"
	L["Draenei"] = "Draeneï"
	L["Dwarf"] = "Nain"
	L["Gnome"] = "Gnome"
	L["Human"] = "Humain"
	L["Night Elf"] = "Elfe de la nuit"
	L["Orc"] = "Orc"
	L["Tauren"] = "Tauren"
	L["Troll"] = "Troll"
	L["Undead"] = "Mort-vivant"
	L["Blood Elf_female"] = "Elfe de sang" -- TODO: check it
	L["Draenei_female"] = "Draeneï"
	L["Dwarf_female"] = "Naine" -- TODO: check it
	L["Gnome_female"] = "Gnome"
	L["Human_female"] = "Humaine"
	L["Night Elf_female"] = "Elfe de la nuit"
	L["Orc_female"] = "Orc" -- TODO: check it
	L["Tauren_female"] = "Taurène" -- TODO: check it
	L["Troll_female"] = "Trollesse" -- TODO: check it
	L["Undead_female"] = "Morte-vivante" -- TODO: check it
	
	-- short races
	L["Blood Elf_short"] = "ES"
	L["Draenei_short"] = "Dr"
	L["Dwarf_short"] = "Na"
	L["Gnome_short"] = "Gn"
	L["Human_short"] = "Hu"
	L["Night Elf_short"] = "EN"
	L["Orc_short"] = "Or"
	L["Tauren_short"] = "Ta"
	L["Troll_short"] = "Tr"
	L["Undead_short"] = "MV"

	-- classes
	L["Warrior"] = "Guerrier"
	L["Priest"] = "Prêtre"
	L["Mage"] = "Mage"
	L["Shaman"] = "Chaman"
	L["Paladin"] = "Paladin"
	L["Warlock"] = "Démoniste"
	L["Druid"] = "Druide"
	L["Rogue"] = "Voleur"
	L["Hunter"] = "Chasseur"
	L["Warrior_female"] = "Guerrière"
	L["Priest_female"] = "Prêtresse"
	L["Mage_female"] = "Mage"
	L["Shaman_female"] = "Chamane"
	L["Paladin_female"] = "Paladin" -- TODO: check it
	L["Warlock_female"] = "Démoniste"
	L["Druid_female"] = "Druidesse"
	L["Rogue_female"] = "Voleuse"
	L["Hunter_female"] = "Chasseresse"
	
	-- short classes
	L["Warrior_short"] = "Gu"
	L["Priest_short"] = "Pr"
	L["Mage_short"] = "Ma"
	L["Shaman_short"] = "Ch"
	L["Paladin_short"] = "Pa"
	L["Warlock_short"] = "Dé"
	L["Druid_short"] = "Dr"
	L["Rogue_short"] = "Vo"
	L["Hunter_short"] = "Ch"

	-- No need to change: L["Player"] = PLAYER
	-- No need to change: L["Target"] = TARGET
	-- No need to change: L["Focus-target"] = FOCUS
	L["Mouse-over"] = "Sous la souris"
	L["%s's pet"] = "Familier |2 %s"
	L["%s's target"] = "Cible |2 %s"
	L["%s's %s"] = "%2$s |2 %1$s"
	L["Party member #%d"] = "Membre du groupe #%d"
	L["Raid member #%d"] = "Membre du raid #%d"

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

	L["Feigned Death"] = "Feint la mort"
	L["Stealthed"] = "Camouflé"
	L["Soulstoned"] = "Âme conservée"
	
	-- No need to change: L["Dead"] = DEAD
	L["Ghost"] = "Fantôme"
	-- No need to change: L["Offline"] = PLAYER_OFFLINE
	L["Online"] = "En ligne"
	L["Combat"] = "Combat"
	L["Resting"] = "Repos"
	L["Tapped"] = "Touché"
	L["AFK"] = "ABS"
	L["DND"] = "NPD"
	
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
	L["Bear"] = "Ours"
	L["Cat"] = "Félin"
	L["Moonkin"] = "Sélénien"
	L["Aquatic"] = "Aquatique"
	L["Flight"] = "Vol"
	L["Travel"] = "Voyage"
	L["Tree"] = "Arbre"

	L["Bear_short"] = "Ou"
	L["Cat_short"] = "Fé"
	L["Moonkin_short"] = "Sé"
	L["Aquatic_short"] = "Aq"
	L["Flight_short"] = "Vo"
	L["Travel_short"] = "Vy"
	L["Tree_short"] = "Ar"

	-- shortgenders
	L["Male_short"] = "h"
	L["Female_short"] = "f"
	
	L["Leader"] = "Chef"
	
	-- dispel types
	L["Magic"] = "Magie"
	L["Curse"] = "Malédiction"
	L["Poison"] = "Poison"
	L["Disease"] = "Maladie"
end

end