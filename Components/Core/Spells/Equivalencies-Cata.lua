-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local pairs, type, ipairs, bit, select =
      pairs, type, ipairs, bit, select


---------------------------------------------------------
-- NEGATIVE SPELLIDS WILL BE REPLACED BY THEIR SPELL NAME
---------------------------------------------------------

TMW.BE = {
	debuffs = {

		-- Disarmed			= "-51722,-676,64058,50541,91644",
		-- PhysicalDmgTaken	= "30070,58683,81326,50518,55749",
		-- SpellDamageTaken	= "-1490,65142,-85547,60433,93068,34889,24844",
		-- SpellCritTaken		= "17800,22959",
		-- BleedDamageTaken	= "33878,33876,16511,-46857,50271,35290,57386",
		-- ReducedAttackSpeed  = "6343,55095,58180,68055,8042,90314,50285",
		-- ReducedCastingSpeed = "1714,5760,31589,73975,50274,50498",
		-- ReducedArmor		= "-58567,91565,8647,-50498,35387",
		-- ReducedPhysicalDone = "1160,99,26017,81130,702,24423",

		ReducedHealing = {
			 -12294, -- Mortal Strike                       (warrior, arms)

			 13218,56112,48301,82654,30213,54680 -- from 2012 TMW
		},
		CrowdControl = {
			   -118, -- Polymorph                           (mage, general)
			   -605, -- Mind Control                        (priest, PVE talent, general)
			   -710, -- Banish                              (warlock, general)
			  -2094, -- Blind                               (rogue, general)
			  -3355, -- Freezing Trap                       (hunter, general)
			  -5782, -- Fear                                (warlock, general)
			  -6358, -- Seduction                           (warlock pet, succubus)
			  -6770, -- Sap                                 (rogue, general)
			  -9484, -- Shackle Undead                      (priest, general)
			  20066, -- Repentance                          (paladin, general)

			  2637,33786,-1499,-19503,-19386,10326,-51514,76780,-49203,82691 -- from 2012 TMW
		},
		Shatterable = {
			   -122, -- Frost Nova                          (mage, frost)
			  -3355, -- Freezing Trap                       (hunter, general)
			  33395, -- Freeze (Mage Water Elemental)

			  -83302,-44572,-55080,-82691 -- from 2012 TMW
		},
		Bleeding = {
			   -703, -- Garrote                             (rogue, general)
			  -1079, -- Rip                                 (druid, feral)
			  -1822, -- Rake                                (druid, feral)
			   1943, -- Rupture                             (rogue, general)
			 -11977, -- Rend                                (warrior, arms)
			  16511, -- Hemorrhage                          (rogue, subtlety)

			  -94009,9007,33745,43104,89775 -- from 2012 TMW
		},
		Feared = {
			   5246, -- Intimidating Shout                  (warrior, general)
			  -5782, -- Fear                                (warlock, general)
			  -6789, -- Death Coil                          (warlock, PVE talent, general)
			  -8122, -- Psychic Scream                      (priest, disc/holy baseline, spriest PVE talent)
			   1513, -- Scare Beast
			  -5484, -- Howl of Terror
			   5134, -- Flash Bomb Fear
 			  10326, -- Turn Evil
			  87204, -- Sin and Punishment
			  20511, -- Intimidating Shout
		},
		Incapacitated = {
			   -118, -- Polymorph                           (mage, general)
			  -2637, -- Hibernate                           (druid, general)
			  -1776, -- Gouge                               (rogue, outlaw)
			  -3355, -- Freezing Trap                       (hunter, general)
			  -6358, -- Seduction                           (warlock pet)
			  -6770, -- Sap                                 (rogue, general)
			 -20066, -- Repentance                          (paladin, PVE talent, general)
			  28271, -- Polymorph: Turtle
			  28272, -- Polymorph: Pig
			 -19503, -- Scatter Shot
			 -19386, -- Wyvern Sting
			  -1090, -- Sleep
			  13327, -- Reckless Charge (Rocket Helmet)
			  13181, -- Gnomish Mind Control Cap
			  26108, -- Glimpse of Madness
			  31661, -- Dragon's Breath
			  49203 -- Hungering Cold
		},
		Disoriented = {
			   -605, -- Mind Control                        (priest, PVE talent, general)
			  -2094, -- Blind                               (rogue, general)
			 -19503, -- Scatter Shot
			  31661, -- Dragon's Breath                     (mage, fire)

			  -51514,90337,88625 -- from 2012 TMW
		},
		Silenced = {
			  -1330, -- Garrote - Silence                   (rogue, general)
			 -15487, -- Silence                             (priest, shadow)
			 -18469, -- Counterspell - Silenced
			 -18425, -- Kick - Silenced
			 -24259, -- Spell Lock
			 -18498, -- Shield Bash - Silenced
			  19821, -- Arcane Bomb Silence
			  34490, -- Silencing Shot (hunter)
			 -47476, -- Strangulate                         (death knight, blood)
			 -78675, -- Solar Beam                          (druid, balance)
			  31935, -- Avenger's Shield                    (paladin, protection)
			  31117, -- Unstable Affliction                 (warlock, affliction)

			  -55021,-25046,81261 -- from 2012 TMW
		},
		Rooted = {
			   -339, -- Entangling Roots                    (druid, general)
			   -122, -- Frost Nova                          (mage, general)
			   8312, -- Trap
			   8377, -- Earthgrab (Totem)
			 -13099, -- Net-o-Matic
			  16979, -- Feral Charge (unused?)
			 -19306, -- Counterattack
			 -19185, -- Entrapment
			 -23694, -- Improved Hamstring
			  33395, -- Freeze (Mage Water Elemental)
			 -64695, -- Earthgrab                           (shaman, resto)
			  45334, -- Immobilized                         (wild charge, bear form)

			  58373,64695,4167,54706,50245,90327,83301,83302,45334,-55080,87195,63685,19387 -- from 2012 TMW
		},
		Slowed = {
			   -116, -- Frostbolt                           (mage, frost)
			   -120, -- Cone of Cold                        (mage, frost)
			  -1715, -- Hamstring                           (warrior, arms)
			  -2974, -- Wing Clip                           (hunter)
			  -6136, -- Chilled                             (mage, also generic effect name)
			  -8056, -- Frost Shock                         (shaman)
			   
			   -- Crippling Poison intentionally not by name -
			   -- 3408 is the buff that goes on the rogue who has applied it to their weapons.
			   3409, -- Crippling Poison                    (rogue, assassination)
			  -3600, -- Earthbind                           (shaman, general)
			  -5116, -- Concussive Shot                     (hunter, beast mastery/marksman)
			  -7321, -- Chilled (Ice/Frost Armor)           (mage)
			  -7992, -- Slowing Poison                      (NPC ability)
			 -12323, -- Piercing Howl                       (warrior, fury)
			  12486, -- Blizzard                            (mage, frost)
			 -12544, -- Frost Armor                         (mage/NPC ability)
			 -15407, -- Mind Flay                           (priest, shadow)
			 -31589, -- Slow                                (mage, arcane)
			  45524, -- Chains of Ice                       (death knight)
			 -58180, -- Infected Wounds                     (druid, feral)
			  61391, -- Typhoon                             (druid, general)
			  44614, -- Flurry                              (mage, frost)

			 13810,-18223,26679,-51693,-50434,-55741,-7302,-8034,-63529,-15571 -- from 2012 TMW
		},
		Stunned = {
			    -25, -- Stun                                (generic NPC ability)
			   -408, -- Kidney Shot                         (rogue, subtlety/assassination)
			   -853, -- Hammer of Justice                   (paladin, general)
			  -1833, -- Cheap Shot                          (rogue, general)
			  -5211, -- Bash                                (druid)
			  -7922, -- Charge Stun                         (warrior)
			  12355, -- Impact                              (mage, fire)
			  12809, -- Concussion Blow                     (warrior)
			 -20253, -- Intercept Stun                      (warrior)
			 -20549, -- War Stomp                           (tauren racial)
			  22703, -- Infernal Awakening                  (warlock, destro)
			  24394, -- Intimidation                        (hunter, beast mastery/surival)
			   4068, -- Iron Grenade                        (engineering)
			  19769, -- Thorium Grenade                     (engineering)
			   4069, -- Big Iron Bomb                       (engineering)
			  12543, -- Hi-Explosive Bomb                   (engineering)
			   4064, -- Rough Copper Bomb                   (engineering)
			  12421, -- Mithril Frag Bomb                   (engineering)
			  19784, -- Dark Iron Bomb                      (engineering)
			   4067, -- Big Bronze Bomb                     (engineering)
			   4066, -- Small Bronze Bomb                   (engineering)
			   4065, -- Large Copper Bomb                   (engineering)
			  13237, -- Goblin Mortar                       (engineering)
			    835, -- Tidal Charm                         (trinket)
			  12562, -- The Big One                         (engineering)
			 -20170, -- Seal of Justice Stun                (paladin)
			  15283, -- Stunning Blow                       (Weapon Proc)
			  30115, -- Sacrifice                           (Karazhan, Terestian Illhoof)
			 -91800, -- Gnaw                                (death knight, unholy)
			  64044, -- Psychic Horror						(priest, talent)
		     -30283, -- Shadowfury                          (warlock, general)
			  91797, -- Monstrous Blow                      (death knight, unholy)
			 -89766, -- Axe Toss                            (warlock, demonology)

			 9005,22570,19577,56626,44572,2812,85388,46968,65929,50519,47481,83047,39796,93986,54786, -- From 2012 TMW
		},
	},
	buffs = {
		-- IncreasedStats		= "79061,79063,90363",
		-- IncreasedDamage		= "75447,82930",
		-- IncreasedCrit		= "24932,29801,51701,51470,24604,90309",
		-- IncreasedAP			= "79102,53138,19506,30808",
		-- IncreasedSPsix		= "-79058,-61316,-52109",
		-- IncreasedSPten		= "77747,53646",
		-- IncreasedPhysHaste  = "55610,53290,8515",
		-- IncreasedSpellHaste = "2895,24907,49868",
		-- BonusAgiStr			= "6673,8076,57330,93435",
		-- BonusStamina		= "79105,469,6307,90364",
		-- BonusArmor			= "465,8072",
		-- BonusMana			= "-79058,-61316,54424",
		-- ManaRegen			= "54424,79102,5677",
		-- BurstManaRegen		= "29166,16191,64901",
		-- PushbackResistance  = "19746,87717",
		-- Resistances			= "19891,8185",
		-- DefensiveBuffs		= "48707,30823,33206,47585,871,48792,498,22812,61336,5277,74001,47788,19263,6940,-12976,31850,31224,42650,86657",
		-- MiscHelpfulBuffs	= "89488,10060,23920,68992,31642,54428,2983,1850,29166,16689,53271,1044,31821,45182",

		SpeedBoosts = {
			    783, -- Travel Form                         (druid, baseline)
			  -2983, -- Sprint                              (rogue, baseline)
			  -2379, -- Speed                               (generic speed buff)
			   2645, -- Ghost Wolf                          (shaman, general)
			   7840, -- Swim Speed                          (Swim Speed Potion)
		},
		ImmuneToStun = {
			    642, -- Divine Shield                       (paladin)
			    710, -- Banish                              (warlock)
			   1022, -- Blessing of Protection              (paladin)
			   6615, -- Free Action                         (vanilla potion)

			  45438,19574,48792,33786,46924,19263, -- from 2012 TMW
		},
		-- DefensiveBuffsAOE = {
		-- },
		DefensiveBuffsSingle = {
			    498, -- Divine Protection                   (paladin, general)
			    642, -- Divine Shield                       (paladin, general)
			    871, -- Shield Wall                         (warrior, protection)
			   1022, -- Blessing of Protection              (paladin, general)
			  -1966, -- Feint                               (rogue, general)
			   5277, -- Evasion                             (rogue, assassination/subtlety)
			   6940, -- Blessing of Sacrifice               (paladin, holy)
			  22812, -- Barkskin                            (druid, general)
			  23920, -- Spell Reflection                    (warrior, PVP talent for arms/fury, baseline for protection)
		},
		DamageBuffs = {
			   1719, -- Recklessness                        (warrior, arms)
			   5217, -- Tiger's Fury                        (druid, feral)
			  12043, -- Presence of Mind                    (mage, arcane)
			  12042, -- Arcane Power                        (mage, arcane)
			  12472, -- Icy Veins                           (mage, frost)
			  13750, -- Adrenaline Rush                     (rogue, outlaw)
			  19574, -- Bestial Wrath                       (hunter, beast mastery)
			  31884, -- Avenging Wrath                      (paladin)

			  12292,85730,50334,3045,77801,34692,51713,49016,57933,64701,86700, -- from 2012 TMW
		},
		DamageShield = {
			    -17, -- Power Word: Shield                  (priest)
			  -1463, -- Mana Shield                         (mage)
			 -11426, -- Ice Barrier                         (mage)
		},
		ImmuneToMagicCC = {
			    642, -- Divine Shield                       (paladin, general)
			   -710, -- Banish                              (warlock, general)
			   8178, -- Grounding Totem Effect              (shaman, PVP talent, general)
			  23920, -- Spell Reflection                    (warrior, PVP talent for arms/fury, baseline for protection)
			  45438, -- Ice Block                           (mage, general)
			  48707, -- Anti-Magic Shell                    (death knight, general)
			  33786, -- Cyclone                             (druid, feral/balance/resto)
			  46924, -- Bladestorm                          (fury ID)
			  31224, -- Cloak of Shadows                    (rogue, general)
			  19574,19263,49039, -- from 2012 TMW
		},
		BurstHaste = {
			   2825, -- Bloodlust                           (shaman, horde)
			  32182, -- Heroism                             (shaman, alliance)
			  80353, -- Time Warp                           (mage, general)
			  90355, -- Ancient Hysteria                    (hunter pet)
		},
		ImmuneToInterrupts = {
			   -642, -- Divine Shield                       (paladin, general)
		},
		ImmuneToSlows = {
			   -642, -- Divine Shield                       (paladin, general)
			   1044, -- Blessing of Freedom                 (paladin, general)
		},
	},
	casts = {
		Heals = {
			   -596, -- Prayer of Healing
			  -2050, -- Lesser Heal
			  -2060, -- Greater Heal
			  -2061, -- Flash Heal
			 -32546, -- Binding Heal
			  64843, -- Divine Hymn

			   -740, -- Tranquility
			  -5185, -- Healing Touch
			  -8936, -- Regrowth
			  50464 -- Nourish

			   -331, -- Healing Wave
			  77472, -- Healing Wave
			  73920, -- Healing Rain
			  -1064, -- Chain Heal
			  -8004, -- Lesser Healing Wave

			   -635, -- Holy Light
			  82326, -- Holy Light
			 -19750, -- Flash of Light
		},
	},
}

TMW.BE.buffs.DefensiveBuffs	= CopyTable(TMW.BE.buffs.DefensiveBuffsSingle)
-- for k, v in pairs(TMW.BE.buffs.DefensiveBuffsAOE) do
-- 	tinsert(TMW.BE.buffs.DefensiveBuffs, v)
-- end
