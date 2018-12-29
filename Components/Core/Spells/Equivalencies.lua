-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

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

local clientVersion = select(4, GetBuildInfo())
local addonVersion = tonumber(GetAddOnMetadata("TellMeWhen", "X-Interface"))

local _, pclass = UnitClass("Player")


---------------------------------------------------------
-- NEGATIVE SPELLIDS WILL BE REPLACED BY THEIR SPELL NAME
---------------------------------------------------------

--[[ TODO: add the following:
	Tremble before me
	heart strike's snare
	
	]]
TMW.BE = {
	debuffs = {
		ReducedHealing = {
			   8679, -- Wound Poison (assassination rogue)
			  27580, -- Sharpen Blade (arms warrior, PVP talent)
			  30213, -- Legion Strike (demonology warlock, pet)
			 115625, -- Mortal Cleave (demonology warlock, pet)
			-115804, -- Mortal Wounds (arms/windwalker/hunter pet)
			 195452, -- Nightblade (subtlety rogue)
			 257775, -- Plague Step (Freehold dungeon)
			 257908, -- Oiled Blade (Freehold dungeon)
			 258323, -- Infected Wound (Freehold dungeon)
			 262513, -- Azerite Heartseeker (Motherload dungeon)
			 269686, -- Plague (Temple of Sethraliss dungeon)
			 272588, -- Rotting Wounds (Siege of Boralus dungeon)
			 274555, -- Scabrous Bite (Freehold dungeon)
			 287672, -- Fatal Wounds (windwalker monk, PVP talent)
		},
		CrowdControl = {
			   -118, -- Polymorph (mage, general)
			   -605, -- Mind Control (priest, PVE talent, general)
			   -710, -- Banish (warlock, general)
			  -2094, -- Blind (rogue, general)
			  -3355, -- Freezing Trap (hunter, general)
			  -5782, -- Fear (warlock, general)
			  -6358, -- Seduction (warlock pet, succubus)
			  -6770, -- Sap (rogue, general)
			  -9484, -- Shackle Undead (priest, general)
			  20066, -- Repentance (paladin, general)
			  33786, -- Cyclone (feral/resto/balance druid)
			 -51514, -- Hex (shaman, general)
			 -82691, -- Ring of Frost (mage, general)
			 107079, -- Quaking Palm (pandaren racial)
			 115078, -- Paralysis (monk, general)
			 115268, -- Mesmerize (warlock pet, Grimiore of Supremacy version of Succubus)
			 198909, -- Song of Chi-ji (mistweaver monk, PVE talent)
			 207685, -- Sigil of Misery (Vengeance Demon hunter)
		},
		Shatterable = {
			    122, -- Frost Nova (frost mage)
			  -3355, -- Freezing Trap (hunter, general)
			  33395, -- Freeze (frost mage pet)
			 -82691, -- Ring of Frost (mage, general)
			 157997, -- Ice Nova (frost mage PVE talent)
			 198121, -- Frostbite (frost mage PVP talent)
			 228358, -- Winter's Chill (frost mage)
			 228600, -- Glacial Spike (frost mage, PVE talent)
		},
		Bleeding = {
			   -703, -- Garrote (rogue, general)
			  -1079, -- Rip (feral druid)
			  -1822, -- Rake (feral druid)
			   1943, -- Rupture (rogue, general)
			 -11977, -- Rend (arms warrior, PVE talent)
			  16511, -- Hemorrhage (subtlety rogue)
			  77758, -- Thrash (bear druid)
			 106830, -- Thrash (feral druid)
			-115767, -- Deep Wounds (arms/prot warr)
			 162487, -- Steel Trap (hunter talent)
			 185855, -- Lacerate (Survival hunter)
			-202028, -- Brutal Slash (feral druid, PVE talent)
			 273794, -- Rezan's Fury (general azerite trait)
		},
		Feared = {
			   5246, -- Intimidating Shout (warrior, general)
			  -5782, -- Fear (warlock, general)
			  -6789, -- Mortal Coil (warlock, PVE talent, general)
			  -8122, -- Psychic Scream (disc/holy baseline, spriest PVE talent)
			  87204, -- Sin and Punishment (shadow priest, VT dispel backlash)
			 207685, -- Sigil of Misery (vengeance demon hunter)
			 255041, -- Terrifying Screech (Atal'dazar dungeon)
			 255371, -- Terrifying Visage (Atal'dazar dungeon)
			 257169, -- Terrifying Roar (Siege of Boralus dungeon)
			 257791, -- Howling Fear (Tol Dagor dungeon)
			 269369, -- Deathly Roar (King's Rest dungeon)
			 272609, -- Maddening Gaze (Underrot dungeon)
			 276031, -- Pit of Despair (King's Rest dungeon)
		},
		Incapacitated = {
			     99, -- Incapacitating Roar (bear druid)
			   -118, -- Polymorph (mage, general)
			   2637, -- Hibernate (druid, general)
			   1776, -- Gouge (rogue, outlaw)
			  -3355, -- Freezing Trap (hunter, general)
			  -6358, -- Seduction (warlock pet)
			  -6770, -- Sap (rogue, general)
			  20066, -- Repentance (paladin, PVE talent, general)
			 -51514, -- Hex (shaman, general)
			  82691, -- Ring of Frost (mage, PVE talent, general)
			 107079, -- Quaking Palm (pandaren racial)
			 115078, -- Paralysis (monk, general)
			 115268, -- Mesmerize (warlock pet, Grimiore of Supremacy version of Succubus)
			 197214, -- Sundering (enhancement shaman PVE talent)
			 200196, -- Holy Word: Chastise (holy priest)
			 217832, -- Imprison (demon hunter, general)
			 221527, -- Imprison (demon hunter, PVP talent, general)
			 226943, -- Mind Bomb (shadow priest, PVE talent)
			 252781, -- Unstable Hex (Atal'dazar dungeon)
			 263914, -- Blinding Sand (Temple of Sethraliss dungeon)
			 268008, -- Snake Charm (Temple of Sethraliss dungeon)
			 268797, -- Transmute: Enemy to Goo (Motherload dungeon)
			 280032, -- Neurotoxin (Temple of Sethraliss dungeon)
		},
		Disoriented = {
			   -605, -- Mind Control (priest, general PVE talent)
			  -2094, -- Blind (rogue, general)
			  31661, -- Dragon's Breath (fire mage)
			 105421, -- Blinding light (paladin, PVE talent, general)
			 198909, -- Song of Chi-ji (mistweaver monk, PVE talent)
			 202274, -- Incendiary brew (brewmaster monk, PVP talent)
			 207167, -- Blinding Sleet (Frost DK talent)
			 213691, -- Scatter Shot (marksman hunter, PVP talent)
			 236748, -- Intimidating Roar (bear druid)
			 257371, -- Tear Gas (Motherload dungeon)
			 258875, -- Blackout Barrel (Freehold dungeon)
			 258917, -- Righteous FLames (Tol Dagor dungeon)
			 270920, -- Seduction (King's Rest dungeon)
		},
		Silenced = {
			  -1330, -- Garrote - Silence (rogue, general)
			 -15487, -- Silence (shadow priest)
			  31117, -- Unstable Affliction (affliction warlock, dispel backlash)
			  31935, -- Avenger's Shield (protection paladin)
			 -47476, -- Strangulate (blood death knight)
			 -78675, -- Solar Beam (balance druid)
			 202933, -- Spider Sting (hunter, PVP talent, general)
			 204490, -- Sigil of Silence (vengeance demon hunter)
			 217824; -- Shield of Virtue (protection paladin, PVP talent)
			 258313, -- Handcuff (Tol Dagor dungeon)
			 268846, -- Echo Blade (Motherload dungeon)
		},
		Rooted = {
			   -339, -- Entangling Roots (druid, general)
			   -122, -- Frost Nova (mage, general)
			  33395, -- Freeze (frost mage water elemental)
			  45334, -- Immobilized (wild charge, bear form)
			  53148, -- Charge (hunter pet)
			  96294, -- Chains of Ice (death knight)
			 -64695, -- Earthgrab (resto shaman, PVE talent)
			  91807, -- Shambling Rush (Unholy DK pet)
			 102359, -- Mass Entanglement (druid, PVE talent, general)
			 105771, -- Charge (warrior, baseline)
			 116706, -- Disable (windwalker monk, disable 2x application)
			 117526, -- Binding Shot (hunter, PVE talent, general)
			 157997, -- Ice Nova (frost mage, PVE talent)
			 162480, -- Steel Trap (survival hunter, PVE talent)
			 190927, -- Harpoon (survival hunter, baseline)
			 198121, -- Frostbite (frost mage, PVP talent)
			 199042, -- Thunderstruck (protection warrior, PVP talent)
			 200108, -- Ranger's Net (survival hunter, baseline)
			 204085, -- Deathchill (frost death knight, PVP talent)
			 212638, -- Tracker's Net (survival hunter, PVP talent)
			 228600, -- Glacial Spike (frost mage, PVE talent)
			 233582, -- Entrenched in Flame (destro warlock, PVP talent)
			 256897, -- Clamping Jaws (Siege of Boralus dungeon)
			 258058, -- Squeeze (Tol Dagor dungeon)
			 259711, -- Lockdown (Tol Dagor dungeon)
			 268050, -- Anchor of Binding (Shrine of the Storms dungeon)
			 274389, -- Rat Traps (Freehold dungeon)
			 285515, -- Surge of Power (elemental shaman, PVE talent)
		},
		Slowed = {
			   -116, -- Frostbolt (frost mage)
			   -120, -- Cone of Cold (frost mage)
			  -1715, -- Hamstring (arms warrior)
			   2120, -- Flamestrike (fire mage)
			  -3409, -- Crippling Poison (assassination rogue)
			  -3600, -- Earthbind (shaman, general)
			  -5116, -- Concussive Shot (beast mastery/marksman hunter)
			   6343, -- Thunder Clap (protection warrior)
			  -7992, -- Slowing Poison (NPC ability)
			 -12323, -- Piercing Howl (fury warrior)
			 -12544, -- Frost Armor (NPC ability only now?)
			 -15407, -- Mind Flay (shadow priest)
			 -31589, -- Slow (arcane mage)
			  35346, -- Warp Time (NPC ability)
			  44614, -- Flurry (frost mage)
			  45524, -- Chains of Ice (death knight)
			  50259, -- Dazed (Wild Charge, druid talent, cat form)
			  50433, -- Ankle Crack (hunter pet)
			  51490, -- Thunderstorm (elemental shaman)
			 -58180, -- Infected Wounds (feral druid)
			  61391, -- Typhoon (druid, general)
			 102793, -- Ursol's Vortex (resto druid)
			 116095, -- Disable (windwalker monk)
			 121253, -- Keg Smash (brewmaster monk)
			 123586, -- Flying Serpent Kick (windwalker monk)
			 135299, -- Tar Trap (survival hunter)
			 147732, -- Frostbrand Attack (enhancement shaman)
			 157981, -- Blast Wave (fire mage)
			 160065, -- Tendon Rip (hunter pet)
			 160067, -- Web Spray (pet ability)
			 183218, -- Hand of Hindrance (retribution paladin)
			 185763, -- Pistol Shot (outlaw rogue)
			 195645, -- Wing Clip (survival hunter)
			-196840, -- Frost Shock (elemental shaman)
			 198222, -- System Shock (assassination rogue, PVP talent)
			 198813, -- Vengeful Retreat (havoc demon hunter)
			 201787, -- Heavy-Handed Strikes (windwalker monk, PVP talent)
			 204263, -- Shining Force (disc/holy priest, PVE talent)
			 204843, -- Sigil of Chains (veng demon hunter, PVE talent)
			 205021, -- Ray of Frost (frost mage, PVE talent)
			 205708, -- Chilled (frost mage)
			 206930, -- Heart Strike (blood death knight)
			 208278, -- Debilitating Infestation (DK unholy talent)
			 211793, -- Remorseless Winter (frost death knight)
			 212792, -- Cone of Cold (frost mage)
			 228354, -- Flurry (frost mage)
			 248744, -- Shiv (rogue, PVP talent, general)
			 257478, -- Crippling Bite (Freehold dungeon)
			 257777, -- Crippling Shiv  (Tol Dagor dungeon)
			 258313, -- Handcuff (Tol Dagor dungeon)
			 267899, -- Hindering Cleave (Shrine of the Storms dungeon)
			 268896, -- Mind Rend (Shrine of the Storms dungeon)
			 270499, -- Frost Shock (King's Rest dungeon)
			 271564, -- Embalming Fluid (King's Rest dungeon)
			 272834, -- Viscous Slobber (Siege of Boralus dungeon)
			-273984, -- Grip of the Dead (unholy death knight, PVP talent)
			 277953, -- Night Terrors (subtlety rogue, PVE talent)
			 280604, -- Iced Spritzer (Motherload dungeon)
			 288962, -- Blood Bolt (hunter pet)
		},
		Stunned = {
			    -25, -- Stun (generic NPC ability)
			   -408, -- Kidney Shot (subtlety/assassination rogue)
			   -853, -- Hammer of Justice (paladin, general)
			  -1833, -- Cheap Shot (rogue, general)
			   5211, -- Mighty Bash (druid, PVE talent, general)
			  24394, -- Intimidation (beast mastery/surival hunter, pet ability)
			 -20549, -- War Stomp (tauren racial)
			  22703, -- Infernal Awakening (destro warlock)
			 -30283, -- Shadowfury (warlock, general)
			 -89766, -- Axe Toss (demonology warlock, Felguard pet)
			  91797, -- Monstrous Blow (unholy death knight, dark transformation pet ability)
			 -91800, -- Gnaw (unholy death knightm pet ability)
			 108194, -- Asphyxiate (frost/unholy death knight, PVE talent)
			 118345, -- Pulverize (elemental shaman, primal elemental PVE talent)
			 118905, -- Static Charge (shaman, general)
			 119381, -- Leg Sweep (monk, general)
			-131402, -- Stunning Strike (generic NPC ability)
			 132168, -- Shockwave (protection warrior, baseline)
			 132169, -- Storm Bolt (warrior, PVE talent, general)
			 163505, -- Rake (druid, general)
			 179057, -- Chaos Nova (demon hunter)
			 199804, -- Between the Eyes (outlaw rogue)
			 199085, -- Warpath (protection warrior, PVE talent)
			 200200, -- Holy Word: Chastise (holy priest, PVE talent)
			 202244, -- Overrun (bear druid, PVP talent)
			 202346, -- Double Barrel (brewmaster monk, PVP talent)
			 203123, -- Maim (feral druid)
			 204437, -- Lightning Lasso (elemental shaman, PVP talent)
			 205629, -- Demonic Trample (vengeance demon hunter, PVP talent)
			 205630, -- Illidan's Grasp (vengeance demon hunter, PVP talent - primary effect) 
			 208618, -- Illidan's Grasp (vengeance demon hunter, PVP talent - throw effect)
			 211881, -- Fel Eruption (havoc demon hunter, PVE talent)
			 221562, -- Asphyxiate (blood death knight, baseline)
			 255723, -- Bull Rush (highmountain tauren racial)
			 256474, -- Heartstopper Venom (Tol Dagor dungeon)
			 257119, -- Sand Trap (Tol Dagor dungeon)
			 257292, -- Heavy Slash (Siege of Boralus dungeon)
			 257337, -- Shocking Claw (Motherload dungeon)
			 260067, -- Vicious Mauling (Tol Dagor dungeon)
			 263637, -- Clothesline (Motherload dungeon)
			 263891, -- Grasping Thorns (Waycrest Manor dungeon)
			 263958, -- A Knot of Snakes (Temple of Sethraliss dungeon)
			 268796, -- Impaling Spear (King's Rest dungeon)
			 269104, -- Explosive Void (Shrine of the Storms dungeon)
			 270003, -- Suppression Slam (King's Rest dungeon)
			 272713, -- Crushing Slam (Siege of Boralus dungeon)
			 272874, -- Trample (Siege of Boralus dungeon)
			 276268, -- Heaving Blow (Shrine of the Storms dungeon)
			 278961, -- Decaying Mind (Underrot dungeon)
			 280605, -- Brain Freeze (Motherload dungeon)
			 287254, -- Dead of Winter (frost death knight, PVP talent)
		},
	},
	buffs = {
		SpeedBoosts = {
			    783, -- Travel Form (druid, baseline)
			  -2983, -- Sprint (rogue, baseline)
			  -2379, -- Speed (generic speed buff)
			   2645, -- Ghost Wolf (shaman, general)
			   7840, -- Swim Speed (self-explanatory)
			  36554, -- Shadowstep (assassination/subtlety rogue)
			  48265, -- Death's Advance (death knight, general)
			  54861, -- Nitro Boosts (engineering rocket boots)
			  58875, -- Spirit Walk (enhancement shaman)
			 -65081, -- Body and Soul (disc/shadow priest, PVE talent)
			  68992, -- Darkflight (worgen racial)
			  87023, -- Cauterize (fire mage)
			 -61684, -- Dash (druid, general)
			 -77761, -- Stampeding Roar (feral/bear druid)
			 111400, -- Burning Rush (warlock, PVE talent, general)
			 116841, -- Tiger's Lust (monk, PVE talent, general)
			 118922, -- Posthaste (hunter, PVE talent, general)
			 119085, -- Chi Torpedo (monk, PVE talent, general)
			 199203, -- Thirst for Battle (fury warrior, PVP talent)
			 121557, -- Angelic Feather (holy/disc priest, PVE talent)
			-186257, -- Aspect of the Cheetah (hunter, general)
			 188024, -- Skystep Potion (Legion potion)
			 192082, -- Wind Rush (shaman, PVE talent, genreal)
			 201447, -- Ride the Wind (windwalker monk pvp talent)
			 202164, -- Bounding Stride (arms/fury, PVE talent)
			 209754, -- Boarding Party (outlaw rogue, PVP talent)
			 212552, -- Wraith Walk (frost/unholy death knight, PVE talent)
			 213602, -- Greater Fade (priest, PVP talent, general)
			 236060, -- Frenetic Speed (fire mage talent)
			 250878, -- Lightfoot Potion (BFA potion)
			 252216, -- Tiger Dash (druid, PVE talent, general)
			 262232, -- War Machine (fury warrior, PVE talent)
			 273415, -- Gathering Storm (warrior, azerite trait, general)
			-276112, -- Divine Steed (paladin, general)
		},
		ImmuneToStun = {
			    642, -- Divine Shield (paladin)
			    710, -- Banish (warlock)
			   1022, -- Blessing of Protection (paladin)
			   6615, -- Free Action (vanilla potion)
			  33786, -- Cyclone (feral/balance/resto druid)
			  45438, -- Ice Block (mage)
			  46924, -- Bladestorm (fury ID)
			  48792, -- Icebound Fortitude (death knight, general)
			 186265, -- Aspect of the Turtle (hunter, general)
			 213610, -- Holy Ward (holy priest, PVP talent)
			 221527, -- Imprison (demon hunter, PVP talent)
			 227847, -- Bladestorm (arms ID)
			-228049, -- Guardian of the Forgotten Queen (protection paladin)
			 287081, -- Lichborne (frost/unholy death knight, PVP talent)
		},
		DefensiveBuffsAOE = {
			 -51052, -- Anti-Magic Zone (unholy death knight, PVP talent)
			 -62618, -- Power Word: Barrier (disc priest)
			  97463, -- Rallying Cry (arms/fury warrior)
			 201633, -- Earthen Wall (resto shaman, PVE talent)
			 204150, -- Aegis of light (protection paladin, PVE talent)
			 204335, -- Aegis of light (protection paladin, PVE talent)
			-209426, -- Darkness (havoc demon hunter)
		},
		DefensiveBuffsSingle = {
			    498, -- Divine Protection (paladin, general)
			    642, -- Divine Shield (paladin, general)
			    871, -- Shield Wall (protection warrior)
			   1022, -- Blessing of Protection (paladin, general)
			  -1966, -- Feint (rogue, general)
			   5277, -- Evasion (assassination/subtlety rogue)
			   6940, -- Blessing of Sacrifice (holy paladin)
			  22812, -- Barkskin (druid, general)
			  23920, -- Spell Reflection (warrior, PVP talent for arms/fury, baseline for protection)
			  31224, -- Cloak of Shadows (rogue, general)
			  31850, -- Ardent Defender (protection paladin)
			  33206, -- Pain Suppression (disc priest)
			  45182, -- Cheating Death (rogue, PVE talent, general)
			  45438, -- Ice Block (mage, general)
			  47585, -- Dispersion (shadow priest)
			  47788, -- Guardian Spirit (holy priest)
			  48707, -- Anti-Magic Shell (death knight, general)
			  48792, -- Icebound Fortitude (death knight, general)
			  53480, -- Roar of Sacrifice (hunter pet)
			  61336, -- Survival Instincts (feral/bear druid)
			  86659, -- Guardian of Ancient Kings (protection paladin)
			 102342, -- Ironbark (resto druid)
			 104773, -- Unending Resolve (warlock, general)
			 108271, -- Astral Shift (shaman, general)
			 113862, -- Greater Invisibility (arcane mage)
			 115176, -- Zen Meditation (brewmaster monk)
			 115203, -- Fortifying Brew (monk, general)
			 116849, -- Life Cocoon (mistweaver monk)
			 118038, -- Die by the Sword (arms warrior)
			 122278, -- Dampen Harm (monk, PVE talent, general)
			 122783, -- Diffuse Magic (monk, PVE talent, general)
			 155835, -- Bristling Fur (bear druid, PVE talent)
			 184364, -- Enraged Regeneration (fury warrior)
			 186265, -- Aspect of the Turtle (hunter, general)
			-197268, -- Ray of Hope (holy priest, PVP talent)
			 199754, -- Riposte (outlaw rogue)
		   	 204018, -- Blessing of Spellwarding (protection paladin, PVP talent)
			 205191, -- Eye for an Eye (retribution paladin, PVE talent)
			 210918, -- Ethereal Form (enhancement shaman, PVP talent)
			 213602, -- Greater Fade (priest, PVP talent, general)
			 213915, -- Mass Spell Reflection (protection warrior, PVP talent)
			-228049, -- Guardian of the Forgotten Queen (protection paladin, PVP talent)
			 223658, -- Safeguard (protection warrior, PVE talent)
			 287081, -- Lichborne (frost/unholy, PVP talent)
		},
		DamageBuffs = {
			   1719, -- Recklessness (arms warrior)
			   5217, -- Tiger's Fury (feral druid)
			  12042, -- Arcane Power (arcane mage)
			  12472, -- Icy Veins (frost mage)
			  13750, -- Adrenaline Rush (outlaw rogue)
			  19574, -- Bestial Wrath (beast mastery hunter)
			  31884, -- Avenging Wrath (retribution paladin)
			  51271, -- Pillar of Frost (frost death knight)
			 102543, -- Incarnation: King of the Jungle (feral druid)
			 102560, -- Incarnation: Chosen of Elune (balance druid)
			 106951, -- Berserk (feral druid)
			-107574, -- Avatar (arms warrior)
			 113858, -- Dark Soul: Instability (destro warlock)
			 113860, -- Dark Soul: Misery (affliction warlock)
			 114050, -- Ascendance (elemental shaman)
			 114051, -- Ascendance (enhancement shaman)
			 137639, -- Storm, Earth, and Fire (windwalker monk)
			 152173, -- Serenity (windwalker monk, PVE talent)
			 162264, -- Metamorphosis (demon hunter, general)
			 185422, -- Shadow Dance (subtlety rogue)
			 190319, -- Combustion (fire mage)
			 194223, -- Celestial Alignment (balance druid)
			 194249, -- Voidform (shadow priest)
			 198144, -- Ice Form (frost mage, PVE talent)
			 199261, -- Death Wish (fury warrior, PVP talent)
			 207289, -- Unholy Frenzy (unholy death knight, PVE talent)
			 212155, -- Tricks of the Trade (Outlaw, PVP talent)
			 212283, -- Symbols of Death (subtlety rogue)
			 216113, -- Way of the Crane (mistweaver monk, PVP talent)
			 216331, -- Avenging Crusader (holy paladin, PVE talent)
			 248622, -- In for the Kill (arms warrior, PVE talent)
			 262228, -- Deadly Calm (arms warrior, PVE talent)
			 266779, -- Coordinated Assault (survival hunter)
			 288613, -- Trueshot (marksman hunter)
		},
		DamageShield = {
			    -17, -- Power Word: Shield (disc/shadow priest)
			 -11426, -- Ice Barrier (frost mage)
			  48707, -- Anti-Magic Shell (death knight, general)
			  77535, -- Blood Shield (blood death knight)
			 108008, -- Indomitable (old Dragon Soul PVE trinket)
			 108366, -- Soul Leech (warlock, general)
			 108416, -- Dark Pact (warlock, PVE talent, general)
			 116849, -- Life Cocoon (mistweaver monk)
			 145441, -- Yu'lon's Barrier (old MOP legendary cape effect)
			 169373, -- Boulder Shield (WOD world item effect)
			 173260, -- Shieldtronic Shield (WOD engineering item)
			 184662, -- Shield of Vengeance (retribution paladin)
			 190456, -- Ignore Pain (protection warrior)
			 203538, -- Greater Blessing of Kings (retribution paladin)
			 235313, -- Blazing Barrier (fire mage)
			 235450, -- Prismatic Barrier (arcane mage)
			 258153, -- Watery Dome (Tol Dagor dungeon)
			 265946, -- Ritual Wraps (trinket from King's Rest)
			 265991, -- Luster (Atal'dazar dungeon)
			 269279, -- Resounding Protection (general azerite trait)
			 270657, -- Bulwark of the Masses (general azerite trait)
			 272979, -- Bulwark of Light (paladin, azerite trait)
			 273432, -- Bound by Shadow (King's Rest dungeon and Uldir)
			 274289, -- Burning Soul (havoc demon hunter, azerite talent)
			 274346, -- Soulmonger (havoc demon hunter, azerite trait)
			 274369, -- Sanctum (priest, azerite trait)
			-274814, -- Reawakening (druid, azerite trait)
			 271466, -- Luminous Barrier (disc priest, PVE talent)
			 272987, -- Revel in Pain (vengeance demon hunter, azerite trait)
			 274395, -- Stalwart Protector (paladin azerite trait)
			 278159, -- Xalzaix's Veil (Uldir tank trinket)
			 280165, -- Ursoc's Endurance (druid, azerite trait)
			 280170, -- Duck and Cover (hunter, azerite trait)
			 280212, -- Bury the Hatchet (arms/fury warrior, azerite trait)
			 280788, -- Retaliatory Fury (general azerite trait)
			 280862, -- Last Gift (general azerite trait)
			 287722, -- Death Denied (priest, azerite trait)
		},
		ImmuneToMagicCC = {
			    642, -- Divine Shield (paladin, general)
			    710, -- Banish (warlock, general)
			   8178, -- Grounding Totem Effect (shaman, PVP talent, general)
			  23920, -- Spell Reflection (warrior, PVP talent for arms/fury, baseline for protection)
			  31224, -- Cloak of Shadows (rogue, general)
			  33786, -- Cyclone (feral/balance/resto druid, PVP talent)
			  45438, -- Ice Block (mage, general)
			  46924, -- Bladestorm (fury ID)
			  48707, -- Anti-Magic Shell (death knight, general)
			 186265, -- Aspect of the Turtle (hunter, generaL)
		   	 204018, -- Blessing of Spellwarding (protection paladin, PVP talent)
			 213610, -- Holy Ward (holy priest, PVP talent)
			 213915, -- Mass Spell Reflection (protection warrior, PVP talent)
			 221527, -- Imprison (demon hunter, PVP talent)
			 227847, -- Bladestorm (arms ID)
			-228049, -- Guardian of the Forgotten Queen (protection paladin, PVP talent)
		},
		BurstHaste = {
			   2825, -- Bloodlust (shaman, horde)
			  32182, -- Heroism (shaman, alliance)
			  80353, -- Time Warp (mage, general)
			  90355, -- Ancient Hysteria (hunter pet)
			 146555, -- Drums of Rage (leatherworking item)
			 178207, -- Drums of Fury (leatherworking item)
			 160452, -- Netherwinds (hunter pet)
			 204361, -- Bloodlust (shaman, PVP talent, horde)
			 204362, -- Heroism (shaman, PVP talent, horde)
			 230935, -- Drums of the Mountain (leatherworking item)
			 256740, -- Drums of the Maelstrom (leatherworking item)
			 264667, -- Primal Rage (hunter pet)
		},
		ImmuneToInterrupts = {
			    642, -- Divine Shield (paladin, general)
			 186265, -- Aspect of the Turtle (hunter)
			 209584, -- Zen Focus Tea (mistweaver monk, PVP talent)
			 210294, -- Divine Favor (holy paladin, PVP talent)
			 221705, -- Casting Circle (warlock, PVP talent, generaL)
			-228049, -- Guardian of the Forgotten Queen (protection paladin, PVP talent)
			-289657, -- Holy Word: Concentration (holy priest, PVP talent)
			 290641, -- Ancestral Gift (resto shaman, PVP talent)
		},
		ImmuneToSlows = {
			   1044, -- Blessing of Freedom (paladin, general)
			  46924, -- Bladestorm (fury ID)
			  48265, -- Death's Advance (death knight, general)
			  54216, -- Master's Call (hunter, pet ability)
			  87023, -- Cauterize (fire mage)
			 197003, -- Maneuverability (rogue, PVP talent, general)
			 201447, -- Ride the Wind (windwalker monk, PVP talent)
			 212552, -- Wraith Walk (frost/unholy death knight, PVE talent)
			 216113, -- Way of the Crane (mistweaver monk, PVP talent)
			 227847, -- Bladestorm (arms ID)
			 287081, -- Lichborne (frost/unholy death knight, PVP talent)
		},
	},
	casts = {
		Heals = {
			    596, -- Prayer of Healing
			   2060, -- Heal
			   2061, -- Flash Heal
			  32546, -- Binding Heal (holy priest, PVE talent)
			  33076, -- Prayer of Mending
			  64843, -- Divine Hymn
			 120517, -- Halo (holy/disc priest, PVE talent)
			 186263, -- Shadow Mend
			 194509, -- Power Word: Radiance
			 265202, -- Holy Word: Salvation (holy priest, PVE talent)
			 289666, -- Greater Heal (holy priest, PVP talent)

			    740, -- Tranquility
			   8936, -- Regrowth
			  48438, -- Wild Growth
			 289022, -- Nourish (restoration druid, PVP talent)

			   1064, -- Chain Heal
			   8004, -- Healing Surge
			  73920, -- Healing Rain
			  77472, -- Healing Wave
			 197995, -- Wellspring (restoration shaman, PVE talent)
			 207778, -- Downpour (restoration shaman, PVE talent)

			  19750, -- Flash of Light
			  82326, -- Holy Light

			 116670, -- Vivify
			 124682, -- Enveloping Mist
			 191837, -- Essence Font
			-209525, -- Soothing Mist
			 227344, -- Surging Mist (mistweaver monk, PVP talent)

		},
	},
}

TMW:RegisterUpgrade(85702, {
	icon = function(self, ics)
		-- Some equivalencies being retired.
		ics.Name = ics.Name:gsub("PvPSpells", "118;605;982;5782;20066;33786;51514")
		ics.Name = ics.Name:gsub("MiscHelpfulBuffs", "1044;1850;2983;10060;23920;31821;45182;53271;68992;197003;213915")
	end,
})

TMW.BE.buffs.DefensiveBuffs	= CopyTable(TMW.BE.buffs.DefensiveBuffsSingle)
for k, v in pairs(TMW.BE.buffs.DefensiveBuffsAOE) do
	tinsert(TMW.BE.buffs.DefensiveBuffs, v)
end


TMW.DS = {
	Magic 	= "Interface\\Icons\\spell_fire_immolation",
	Curse 	= "Interface\\Icons\\spell_shadow_curseofsargeras",
	Disease = "Interface\\Icons\\spell_nature_nullifydisease",
	Poison 	= "Interface\\Icons\\spell_nature_corrosivebreath",
	Enraged = "Interface\\Icons\\ability_druid_challangingroar",
}

local function ProcessEquivalencies()
	TMW.EquivOriginalLookup = {}
	TMW.EquivFullIDLookup = {}
	TMW.EquivFullNameLookup = {}
	TMW.EquivFirstIDLookup = {}
	
	TMW:Fire("TMW_EQUIVS_PROCESSING")
	TMW:UnregisterAllCallbacks("TMW_EQUIVS_PROCESSING")

	for dispeltype, texture in pairs(TMW.DS) do
		TMW.EquivFirstIDLookup[dispeltype] = texture
		TMW.SpellTexturesMetaIndex[strlower(dispeltype)] = texture
	end
	
	for category, b in pairs(TMW.BE) do
		for equiv, tbl in pairs(b) do
			TMW.EquivOriginalLookup[equiv] = CopyTable(tbl)
			TMW.EquivFirstIDLookup[equiv] = abs(tbl[1])
			TMW.EquivFullIDLookup[equiv] = ""
			TMW.EquivFullNameLookup[equiv] = ""

			-- turn all negative IDs into their localized name.
			-- When defining equavalancies, dont put a negative on every single one,
			-- but do use it for spells that do not have any other spells with the same name and different effects.
			
			for i, spellID in pairs(tbl) do

				local realSpellID = abs(spellID)
				local name, _, tex = GetSpellInfo(realSpellID)

				TMW.EquivFullIDLookup[equiv] = TMW.EquivFullIDLookup[equiv] .. ";" .. realSpellID
				TMW.EquivFullNameLookup[equiv] = TMW.EquivFullNameLookup[equiv] .. ";" .. (name or realSpellID)
				
				if spellID < 0 then
					
					-- name will be nil if the ID isn't a valid spell (possibly the spell was removed in a patch).
					if name then
						-- this will insert the spell name into the table of spells for capitalization restoration.
						TMW:LowerNames(name) 
						
						-- map the spell's name and ID to its texture for the spell texture cache
						TMW.SpellTexturesMetaIndex[realSpellID] = tex
						TMW.SpellTexturesMetaIndex[TMW.strlowerCache[name]] = tex

						tbl[i] = name
					else
						
						if clientVersion >= addonVersion then -- only warn for newer clients using older versions
							TMW:Debug("Invalid spellID found: %s (%s - %s)!",
							realSpellID, category, equiv)
						end

						tbl[i] = realSpellID
					end
				else
					tbl[i] = realSpellID
				end
			end

			for _, spell in pairs(tbl) do
				if type(spell) == "number" and not GetSpellInfo(spell) then
					TMW:Debug("Invalid spellID found: %s (%s - %s)!",
						spell, category, equiv)
				end
			end
		end
	end
end

TMW:RegisterCallback("TMW_INITIALIZE", ProcessEquivalencies)
