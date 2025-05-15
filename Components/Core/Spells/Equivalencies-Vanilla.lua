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
		ReducedHealing = {
			 -13220, -- Wound Poison                        (rogue, assassination)
			 -12294, -- Mortal Strike                       (warrior, arms)
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
		},
		Shatterable = {
			   -122, -- Frost Nova                          (mage, frost)
			  -3355, -- Freezing Trap                       (hunter, general)
		},
		Bleeding = {
			   -703, -- Garrote                             (rogue, general)
			  -1079, -- Rip                                 (druid, feral)
			  -1822, -- Rake                                (druid, feral)
			   1943, -- Rupture                             (rogue, general)
			 -11977, -- Rend                                (warrior, arms)
			  16511, -- Hemorrhage                          (rogue, subtlety)
		},
		Feared = {
			   5246, -- Intimidating Shout                  (warrior, general)
			  -5782, -- Fear                                (warlock, general)
			  -6789, -- Death Coil                          (warlock, PVE talent, general)
			  -8122, -- Psychic Scream                      (priest, disc/holy baseline, spriest PVE talent)
			   1513, -- Scare Beast
			   5484, -- Howl of Terror
			   5134, -- Flash Bomb Fear
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

		},
		Disoriented = {
			   -605, -- Mind Control                        (priest, PVE talent, general)
			  -2094, -- Blind                               (rogue, general)
		},
		Silenced = {
			  -1330, -- Garrote - Silence                   (rogue, general)
			 -15487, -- Silence                             (priest, shadow)
			 -18469, -- Counterspell - Silenced
			 -18425, -- Kick - Silenced
			 -24259, -- Spell Lock
			 -18498, -- Shield Bash - Silenced
			  19821, -- Arcane Bomb Silence
		},
		Rooted = {
			   -339, -- Entangling Roots                    (druid, general)
			   -122, -- Frost Nova                          (mage, general)
			   8312, -- Trap
			   8377, -- Earthgrab (Totem)
			 -13099, -- Net-o-Matic
			 -19229, -- Improved Wing Clip					(hunter, talent)
			  16979, -- Feral Charge (unused?)
			  19675, -- Feral Charge Effect
			 -19306, -- Counterattack
			 -19185, -- Entrapment
			 -23694, -- Improved Hamstring
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
			 -16922, -- Improved Starfire                   (druid)
			 -19410, -- Improved Concussive Shot            (hunter)
			 -20170, -- Seal of Justice Stun                (paladin)
			 -15269, -- Blackout                            (priest, shadow)
			  18093, -- Pyroclasm                           (warlock)
			 -12798, -- Revenge Stun                        (warrior)
			   5530, -- Mace Stun Effect                    (Mace Specialization)
			  15283, -- Stunning Blow                       (Weapon Proc)
		},
	},
	buffs = {
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
			  28682, -- Combustion                          (mage, fire)
		},
		DamageShield = {
			    -17, -- Power Word: Shield                  (priest)
			 -11426, -- Ice Barrier                         (mage)
			  -1463, -- Mana Shield                         (mage)
		},
		ImmuneToMagicCC = {
			    642, -- Divine Shield                       (paladin, general)
			   -710, -- Banish                              (warlock, general)
			   8178, -- Grounding Totem Effect              (shaman, PVP talent, general)
			  23920, -- Spell Reflection                    (warrior, PVP talent for arms/fury, baseline for protection)
		},
		-- BurstHaste = {
		-- 	   2825, -- Bloodlust                           (shaman, horde)
		-- },
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
			  -2060, -- Heal
			  -2061, -- Flash Heal

			   -740, -- Tranquility
			  -8936, -- Regrowth

			  -1064, -- Chain Heal
			  -8004, -- Healing Surge

			 -19750, -- Flash of Light
			   -863, -- Holy Light
		},
	},
}

TMW.BE.buffs.DefensiveBuffs	= CopyTable(TMW.BE.buffs.DefensiveBuffsSingle)
-- for k, v in pairs(TMW.BE.buffs.DefensiveBuffsAOE) do
-- 	tinsert(TMW.BE.buffs.DefensiveBuffs, v)
-- end
