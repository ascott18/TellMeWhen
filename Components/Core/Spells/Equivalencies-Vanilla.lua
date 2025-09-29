-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

-- Some items in this file contributed by https://github.com/Alessandro-Barbieri

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
		Bleeding = {
			   -703, -- Garrote                             (rogue, general)
			  -1079, -- Rip                                 (druid, feral)
			  -1822, -- Rake                                (druid, feral)
			   1943, -- Rupture                             (rogue, general)
			 -11977, -- Rend                                (warrior, arms)
			  16511, -- Hemorrhage                          (rogue, subtlety)
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
		Disoriented = {
			   -605, -- Mind Control                        (priest, PVE talent, general)
			  -2094, -- Blind                               (rogue, general)
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
		ReducedHealing = {
			 -13220, -- Wound Poison                        (rogue, assassination)
			 -12294, -- Mortal Strike                       (warrior, arms)
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
		Shatterable = {
			   -122, -- Frost Nova                          (mage, frost)
			  -3355, -- Freezing Trap                       (hunter, general)
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
		ReducedArmor = {
			-11597, -- Sunder Armor
			-11198, -- Expose Armor
			439471, -- Sebacious Poison
			402818, -- Degrade
			-9907, -- Faerie Fire
			-17392, -- Faerie Fire (Feral)
			-17315, -- Puncture Armor
		},
		
	},
	buffs = {
		IncreasedStats = {
			-16878, -- Mark of the Wild
			-21849, -- Gift of the Wild
			25898, -- Greater Blessing of Kings
			20217, -- Blessing of Kings
			409583, -- Heart of the Lion
			-15366, -- Songflower Serenade
			-1218071, -- Songflower Lullaby
		},
		BonusStamina = {
			-11767, -- Blood Pact
			403215, -- Commanding Shout
			-21562, -- Prayer of Fortitude
			-10938, -- Power Word: Fortitude
			-8099, -- Stamina
		},
		IncreasedAgility = {
			17538, -- Elixir of the Mongoose
			-11328, -- Agility
			-11334, -- Greater Agility
			-2374, -- Lesser Agility
			1213904, -- Elixir of the Honey Badger
 			425600, -- Horn of Lordaeron
		},
		IncreasedIntellect = {
			-1459, -- Arcane Intellect
			23028, -- Arcane Brilliance
			16327, -- Juju Guile
			17535, -- Elixir of the Sages
			-11396, -- Greater Intellect
			-3165, -- Lesser Intellect
			-3167, -- Intellect
			16888, -- Intellect IX
		},
		IncreasedStrength = {
			16323, -- Juju Power
			17537, -- Elixir of Brute Force
			-3164, -- Strength
			-2367, -- Lesser Strength
			-8212, -- Enlarge
			-16883, -- Elixir of the Giants
 			425600, -- Horn of Lordaeron
		},
		IncreasedSpirit = {
			27681, -- Prayer of Spirit
			10767, -- Rising Spirit
			17535, -- Elixir of the Sages
			-14752, -- Divine Spirit
			15231, -- Crystal Force
			-8112, -- Spirit
		},
		IncreasedAP = {
			-25916, -- Greater Blessing of Might
			-25291, -- Blessing of Might
			-17038, -- Winterfall Firewater
			16329, -- Juju Might
			473469, -- Cleansed Firewater
		},
		IncreasedSP = {
			-17539, -- Greater Arcane Elixir
			11390, -- Arcane Elixir
			439959, -- Lesser Arcane Elixir
			1213914, -- Elixir of the Mage-Lord
			15288, -- Fury of Ragnaros
			17150, -- Arcane Might
		},
		IncreasedCrit = {
			-15366, -- Songflower Serenade
			-1218071, -- Songflower Lullaby
		},
		IncreasedPhysHaste = {
			-16609, -- Warchief's Blessing
			-460940, -- Might of Stormwind
			-1218074, -- Might of Blackrock
		},

		IncreasedArmor = {
			-11349, -- Armor
			-673, -- Lesser Armor
			1213917, -- Elixir of the Ironside
			11348, -- Greater Armor
			15233, -- Crystal Ward
		},
		IncreasedHealth = {
			3593, -- Health II
			2378, -- Health
		},
		-- BurstHaste = {
		-- 	   2825, -- Bloodlust                           (shaman, horde)
		-- },
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
		DarkFortune = {
			23738, -- Sayge's Dark Fortune of Spirit
			23767, -- Sayge's Dark Fortune of Armor
			23737, -- Sayge's Dark Fortune of Stamina
			23736, -- Sayge's Dark Fortune of Agility
			23766, -- Sayge's Dark Fortune of Intellect
			23735, -- Sayge's Dark Fortune of Strength
			23769, -- Sayge's Dark Fortune of Resistance
			23768, -- Sayge's Dark Fortune of Damage
			-473450, -- Dark Fortune of Damage 
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
		ImmuneToStun = {
			    642, -- Divine Shield                       (paladin)
			    710, -- Banish                              (warlock)
			   1022, -- Blessing of Protection              (paladin)
			   6615, -- Free Action                         (vanilla potion)
		},
		FlaskBuffs = {
			17628, -- Supreme Power
			17626, -- Flask of the Titans
			17627, -- Distilled Wisdom
			17629, -- Chromatic Resistance
			17624, -- Petrification
			448084, -- Restless Dreams
			446228, -- Nightmarish Power
			1213892, -- Flask of Ancient Knowledge
			1213897, -- Flask of Madness
			1213901, -- Flask of the Old Gods
			1213886, -- Flask of Unyielding Sorrow
		},
		FoodBuffs = {
			-19705, -- Well Fed
			-25661, -- Increased Stamina
			18141, -- Blessed Sunfruit Juice
			18125, -- Blessed Sunfruit
			18194, -- Mana Regeneration
			18192, -- Increased Agility
			22730, -- Increased Intellect
		},
		HealthRegeneration = {
			-24361, -- Regeneration
			16890, -- Regeneration IV
		},
		ImmuneToInterrupts = {
			   -642, -- Divine Shield                       (paladin, general)
		},
		ImmuneToMagicCC = {
			    642, -- Divine Shield                       (paladin, general)
			   -710, -- Banish                              (warlock, general)
			   8178, -- Grounding Totem Effect              (shaman, PVP talent, general)
			  23920, -- Spell Reflection                    (warrior, PVP talent for arms/fury, baseline for protection)
		},
		ImmuneToSlows = {
			   -642, -- Divine Shield                       (paladin, general)
			   1044, -- Blessing of Freedom                 (paladin, general)
		},
		Resistances = {
			27652, -- Elixir of Resistance
			-16878, -- Mark of the Wild
			-21849, -- Gift of the Wild
			
			-10534, -- Fire Resistance (Totem)
			-19900, -- Fire Resistance Aura
			
			 -19897, -- Frost Resistance Aura
			 -8182, -- Frost Resistance (Totem)
			 
			-20190, -- Aspect of the Nature
			-10599, -- Nature Resistance (Totem)
			
			-16874, -- Shadow Protection
			27683, -- Prayer of Shadow Protection
		},
		SpeedBoosts = {
			    783, -- Travel Form                         (druid, baseline)
			  -2983, -- Sprint                              (rogue, baseline)
			  -2379, -- Speed                               (generic speed buff)
			   2645, -- Ghost Wolf                          (shaman, general)
			   7840, -- Swim Speed                          (Swim Speed Potion)
		},
		DamageReflect = {
			-467, -- Thorns
			-2947, -- Fire Shield
			184, -- Fire Shield II
			2602, -- Fire Shield IV
			2601, -- Fire Shield III
			15279, -- Crystal Spire
			16610, -- Razorhide
		},
		WaterBreathing = {
			5697, -- Unending Breath
			16591, -- Noggenfogger Elixir
			-131, -- Water Breathing
			461137, -- Oath of the Sea
			405688, -- Riptide Bubbles
			-17443, -- Air Bubbles
			5421, -- Aquatic Form (Passive)
			22807, -- Greater Water Breathing
			24347, -- Master Angler
			24925, -- Hallow's End Candy
		},
		WaterWalking =  {
			-546, -- Water Walking
			-1706, -- Levitate
			10665, -- Water Walk
			461120, -- Treading Water
			24927, -- Hallow's End Candy
		},
		Zanza = {
			24383, -- Swiftness of Zanza
			30338, -- Permanent Swiftness of Zanza
			24382, -- Spirit of Zanza
			30336, -- Permanent Spirit of Zanza
			30331, -- Permanent Sheen of Zanza
			-24417, -- Sheen of Zanza
			-10690, -- Infallible Mind
			-10691, -- Spiritual Domination
			-10671, -- Spirit of Boar
			-10667, -- Rage of Ages
			-10669, -- Strike of the Scorpok
			446396, -- Atal'ai Mojo of Life
			446336, -- Atal'ai Mojo of War
			446256, -- Atal'ai Mojo of Forbidden Magic
			27665, -- Ironforge Gift of Friendship
			27669, -- Orgrimmar Gift of Friendship
			27671, -- Undercity Gift of Friendship
			27666, -- Darnassus Gift of Friendship
			27664, -- Stormwind Gift of Friendship
			27670, -- Thunder Bluff Gift of Friendship
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
