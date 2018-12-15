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
			   8679, -- Wound Poison (sin rogue)
			  27580, -- Sharpen Blade (arms warr PVP talent)
			  30213, -- Legion Strike (demo lock pet)
			 115625, -- Mortal Cleave (demo lock pet)
			-115804, -- Mortal Wounds (arms/ww/hunter pet)
			 195452, -- Nightblade (sub rogue)
			 287672, -- Fatal Wounds (WW PVP talent)
		},
		CrowdControl = {
			   -118, -- Polymorph (mage, general)
			   -605, -- Mind Control (priest, general PVE talent)
			   -710, -- Banish (warlock, general)
			  -2094, -- Blind (rogue, general)
			  -3355, -- Freezing Trap (hunter, general)
			  -5782, -- Fear (warlock, general)
			  -6358, -- Seduction (warlock pet, succubus)
			  -6770, -- Sap (rogue, general)
			  -9484, -- Shackle Undead (priest, general)
			  20066, -- Repentance (paladin, general)
			  33786, -- Cyclone (feral/resto/boomkin)
			 -51514, -- Hex (shaman, general)
			 -82691, -- Ring of Frost (mage, general)
			 107079, -- Quaking Palm (pandaren racial)
			 115078, -- Paralysis (monk, general)
			 115268, -- Mesmerize (warlock pet, Grimiore of Supremacy version of Succubus)
			 198909, -- Song of Chi-ji (mistweaver monk talent)
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
			 228600, -- Glacial Spike (frost mage PVE talent)
		},
		Bleeding = {
			   -703, -- Garrote (rogue, general)
			  -1079, -- Rip (feral druid)
			  -1822, -- Rake (feral druid)
			   1943, -- Rupture (rogue, general)
			 -11977, -- Rend (arms warr PVE talent)
			  16511, -- Hemorrhage (sub rogue)
			  77758, -- Thrash (bear druid)
			 106830, -- Thrash (feral druid)
			-115767, -- Deep Wounds (arms/prot warr)
			 162487, -- Steel Trap (hunter talent)
			 185855, -- Lacerate (Survival hunter)
			-202028, -- Brutal Slash (feral druid talent)
			 259277, -- Kill Command (SV hunter PVE talent, Bloodseeker)
			 273794, -- Rezan's Fury (general azerite trait)
		},
		Feared = {
			   5246, -- Intimidating Shout (warrior, general)
			  -5782, -- Fear (warlock, general)
			  -6789, -- Mortal Coil (warlock PVE talent, general)
			  -8122, -- Psychic Scream (priest passive/talent, general)
			  87204, -- Sin and Punishment (spriest VT backlash)
			 207685, -- Sigil of Misery (Vengeance Demon hunter)
		},
		Incapacitated = {
			     99, -- Incapacitating Roar
			   -118, -- Polymorph
			   2637, -- Hibernate
			   1776, -- Gouge
			  -3355, -- Freezing Trap
			  -6358, -- Seduction
			  -6770, -- Sap
			 -19386, -- Wyvern Sting
			  20066, -- Repentance
			 -51514, -- Hex (also 211015; 211010; 211004; 210873; 196942; 269352; 277778; 277784)
			  82691, -- Ring of Frost
			 107079, -- Quaking Palm
			 115078, -- Paralysis
			 115268, -- Mesmerize
			 197214, -- Sundering
			 200196, -- Holy Word: Chastise
			 217832, -- Imprison (breakable)
			 221527, -- Imprison (banish, talented)
			 226943, -- Mind Bomb
		},
		Disoriented = {
			  -2094, -- Blind (rogue, general)
			  31661, -- Dragon's Breath (fire mage)
			 105421, -- Blinding light (paladin talent)
			 198909, -- Song of Chi-ji (mistweaver monk talent)
			 202274, -- Incendiary brew (brewmaster monk pvp talent)
			 207167, -- Blinding Sleet (Frost DK talent)
			 213691, -- Scatter Shot (MM hunter PVP talent)
			 236748, -- Intimidating Roar (bear druid)
		},
		Silenced = {
			  -1330, -- Garrote - Silence
			 -15487, -- Silence
			  31117, -- Unstable Affliction
			  31935, -- Avenger's Shield
			 -47476, -- Strangulate
			 -78675, -- Solar Beam
			 202933, -- Spider Sting
			 204490, -- Sigil of Silence (Vengeance Demon Hunter)
			 217824; -- Shield of Virtue
		},
		Rooted = {
			   -339, -- Entangling Roots
			   -122, -- Frost Nova
			  33395, -- Freeze (frost mage water elemental)
			  45334, -- Immobilized (wild charge, bear form)
			  53148, -- Charge
			  96294, -- Chains of Ice
			 -64695, -- Earthgrab
			  91807, -- Shambling Rush (DK ghoul)
			 102359, -- Mass Entanglement
			 105771, -- Charge
			 116706, -- Disable
			 117526, -- Binding Shot
			 157997, -- Ice Nova (frost mage talent)
			 162480, -- Steel Trap (hunter talent)
			 190927, -- harpoon (survival hunter)
			 198121, -- Frostbite
			 199042, -- Thunderstruck (Warrior PVP)
			 200108, -- Ranger's Net (Hunter talent)
			 201158, -- Super Sticky Tar (Expert Trapper, Hunter talent, Tar Trap effect)
			 204085, -- Deathchill (DK PVP)
			 207171, -- Winter is Coming
			 212638, -- Tracker's Net (hunter PvP )
			 228600, -- Glacial Spike (frost mage talent)
			 232559, -- Thorns
			 233582, -- Entrenched in Flames
		},
		Slowed = {
			   -116, -- Frostbolt
			   -120, -- Cone of Cold
			  -1715, -- Hamstring
			   2120, -- Flamestrike
			  -3409, -- Crippling Poison
			  -3600, -- Earthbind
			  -5116, -- Concussive Shot
			   6343, -- Thunder Clap
			  -7992, -- Slowing Poison
			 -12323, -- Piercing Howl
			 -12544, -- Frost Armor
			 -13810, -- Ice Trap
			 -15407, -- Mind Flay
			 -31589, -- Slow
			  35346, -- Warp Time
			  44614, -- Flurry
			  45524, -- Chains of Ice
			  50259, -- Dazed (Wild Charge, druid talent, cat form)
			  50433, -- Ankle Crack
			  51490, -- Thunderstorm
			 -58180, -- Infected Wounds
			  61391, -- Typhoon
			 102793, -- Ursol's Vortex
			 116095, -- Disable
			 121253, -- Keg Smash
			 123586, -- Flying Serpent Kick
			 135299, -- Tar Trap
			 147732, -- Frostbrand Attack
			 157981, -- Blast Wave
			 160065, -- Tendon Rip
			 160067, -- Web Spray
			 169733, -- Brutal Bash
			 183218, -- Hand of Hindrance
			 185763, -- Pistol Shot
			 191397, -- Bestial Cunning
			 194858, -- Dragonsfire Grenade
			 195645, -- Wing Clip
			-196840, -- Frost Shock
			 198222, -- System Shock
			 198813, -- Vengeful Retreat
			 201787, -- Heavy-Handed Strikes (ww pvp talent)
			 204263, -- Shining Force
			 204843, -- Sigil of Chains
			 205021, -- Ray of Frost (frost mage talent)
			 205320, -- Strike of the Windlord
			 205708, -- Chilled (frost mage effect)
			 206755, -- Ranger's Net
			 206760, -- Night Terrors
			 206930, -- Heart Strike
			 208278, -- Debilitating Infestation (DK unholy talent)
			 209786, -- Goremaw's Bite
			 211793, -- Remorseless Winter
			 211831, -- Abomination's Might
			 212764, -- White Walker
			 212792, -- Cone of Cold (frost mage)
			 222775, -- Strike from the Shadows
			 228354, -- Flurry (frost mage ability)
			 248744, -- Shiv
			-273984, -- Grip of the Dead
			 288962, -- Blood Bolt
		},
		Stunned = {
			    -25, -- Stun
			   -408, -- Kidney Shot
			   -853, -- Hammer of Justice
			  -1833, -- Cheap Shot
			   5211, -- Mighty Bash
			  -7922, -- Warbringer
			  24394, -- Intimidation
			 -20549, -- War Stomp
			  22703, -- Infernal Awakening
			 -30283, -- Shadowfury
			 -89766, -- Axe Toss
			  91797, -- Monstrous Blow
			 -91800, -- Gnaw
			 108194, -- Asphyxiate (death knight, talent for unholy)
			 118345, -- Pulverize
			 118905, -- Static Charge
			 119381, -- Leg Sweep
			-131402, -- Stunning Strike
			 132168, -- Shockwave
			 132169, -- Storm Bolt
			 163505, -- Rake
			 179057, -- Chaos Nova
			 199804, -- Between the Eyes
			 199085, -- Warpath
			 200200, -- Holy Word: Chastise
			 202244, -- Overrun
			 202346, -- Double Barrel
			 203123, -- Maim
			 204437, -- Lightning Lasso
			 205629, -- Demonic Trample
			 205630, -- Illidan's Grasp (demon hunter vengeance pvp talent - primary effect)
			 208618, -- Illidan's Grasp (demon hunter vengeance pvp talent - throw effect)
			 211881, -- Fel Eruption
			 221562, -- Asphyxiate (death knight, baseline for blood)
			 255723, -- Bull Rush
			 287254, -- Dead of Winter
		},
	},
	buffs = {
		SpeedBoosts = {
			    783, -- Travel Form
			  -2983, -- Sprint
			  -2379, -- Speed
			   2645, -- Ghost Wolf
			   7840, -- Swim Speed
			  36554, -- Shadowstep
			  54861, -- Nitro Boosts
			  58875, -- Spirit Walk
			 -65081, -- Body and Soul
			  68992, -- Darkflight
			  87023, -- Cauterize
			 -61684, -- Dash
			 -77761, -- Stampeding Roar
			 111400, -- Burning Rush
			 116841, -- Tiger's Lust
			 118922, -- Posthaste
			 119085, -- Chi Torpedo
			 121557, -- Angelic Feather
			-186257, -- Aspect of the Cheetah
			 188024, -- Skystep Potion
			 192082, -- Wind Rush (shaman wind rush totem talent)
			 197023, -- Cut to the Chase (rogue pvp talent)
			 201233, -- Whirling Kicks (windwalker monk pvp talent)
			 201447, -- Ride the Wind (windwalker monk pvp talent)
			 202164, -- Bounding Stride (warrior talent)
			 209754, -- Boarding Party (rogue pvp talent)
			 212552, -- Wraith Walk (F/UHDK PVE talent)
			 213602, -- Greater Fade
			 214121, -- Body and Mind (priest talent)
			 231390, -- Trailblazer (hunter talent)
			 236060, -- Frenetic Speed (fire mage talent)
			 250878, -- Lightfoot Potion
			 252216, -- Tiger Dash
			 262232, -- War Machine
			 273415, -- Gathering Storm
			-276112, -- Divine Steed
		},
		ImmuneToStun = {
			    642, -- Divine Shield
			    710, -- Banish
			   1022, -- Blessing of Protection
			   6615, -- Free Action
			  33786, -- Cyclone
			  45438, -- Ice Block
			  46924, -- Bladestorm (fury)
			  48792, -- Icebound Fortitude
			 186265, -- Aspect of the Turtle
			 213610, -- Holy Ward
			 221527, -- Imprison
			 227847, -- Bladestorm (arms)
			-228049, -- Guardian of the Forgotten Queen (spellID might be wrong?)
			 287081, -- Lichborne (F/UHDK PVP talent)
		},
		DefensiveBuffsAOE = {
			 -31821, -- Aura Mastery
			 -51052, -- Anti-Magic Zone
			 -62618, -- Power Word: Barrier
			  97463, -- Rallying Cry
			 201633, -- Earthen Wall (from Earthen Wall Totem)
			 204150, -- Aegis of light (prot pally talent)
			 204335, -- Aegis of light (prot pally talent)
			-209426, -- Darkness
		},
		DefensiveBuffsSingle = {
			    498, -- Divine Protection
			    642, -- Divine Shield
			    871, -- Shield Wall
			   1022, -- Blessing of Protection
			  -1966, -- Feint
			   5277, -- Evasion
			   6940, -- Blessing of Sacrifice
			  22812, -- Barkskin
			  23920, -- Spell Reflection
			  31224, -- Cloak of Shadows
			  31850, -- Ardent Defender
			  33206, -- Pain Suppression
			  45182, -- Cheating Death
			  45438, -- Ice Block
			  47585, -- Dispersion
			  47788, -- Guardian Spirit
			  48707, -- Anti-Magic Shell
			  48792, -- Icebound Fortitude
			  53480, -- Roar of Sacrifice
			  61336, -- Survival Instincts
			  86659, -- Guardian of Ancient Kings
			 102342, -- Ironbark
			 104773, -- Unending Resolve
			 108271, -- Astral Shift
			 113862, -- Greater Invisibility
			 115176, -- Zen Meditation
			 115203, -- Fortifying Brew
			 116849, -- Life Cocoon
			 118038, -- Die by the Sword
			 122278, -- Dampen Harm
			 122783, -- Diffuse Magic
			 155835, -- Bristling Fur
			 184364, -- Enraged Regeneration
			 186265, -- Aspect of the Turtle
			-197268, -- Ray of Hope
			 199754, -- Riposte
		   	 204018, -- Blessing of Spellwarding
			 205191, -- Eye for an Eye
			 210918, -- Ethereal Form (shaman PVP talent)
			 213602, -- Greater Fade
			 213871, -- Bodyguard
			-228049, -- Guardian of the Forgotten Queen (spellID might be wrong?)
			 223658, -- Safeguard
			 287081, -- Lichborne (F/UHDK PVP talent)
		},
		DamageBuffs = {
			   1719, -- Recklessness
			   5217, -- Tiger's Fury
			  12042, -- Arcane Power 
			  12472, -- Icy Veins
			  13750, -- Adrenaline Rush
			  19574, -- Bestial Wrath
			  31884, -- Avenging Wrath
			  51271, -- Pillar of Frost
			 102543, -- Incarnation: King of the Jungle
			 102560, -- Incarnation: Chosen of Elune
			 106951, -- Berserk
			 107574, -- Avatar
			 113858, -- Dark Soul: Instability
			 113860, -- Dark Soul: Misery
			 114050, -- Ascendance
			 114051, -- Ascendance
			 137639, -- Storm, Earth, and Fire
			 152173, -- Serenity
			 162264, -- Metamorphosis
			 185422, -- Shadow Dance
			 190319, -- Combustion
			 194223, -- Celestial Alignment
			 194249, -- Voidform
			 198144, -- Ice Form
			 199261, -- Death Wish
			 207289, -- Unholy Frenzy
			 212155, -- Tricks of the Trade (Outlaw PVP talent)
			 212283, -- Symbols of Death
			 216113, -- Way of the Crane
			 216331, -- Avenging Crusader
			 248622, -- In for the Kill
			 262228, -- Deadly Calm
			 266779, -- Coordinated Assault
			 288613, -- Trueshot
		},
		DamageShield = {
			    -17, -- Power Word: Shield
			   1463, -- Incanter's Flow
			 -11426, -- Ice Barrier
			  48707, -- Anti-Magic Shell
			  77535, -- Blood Shield
			 114908, -- Spirit Shell
			 108008, -- Indomitable
			 108366, -- Soul Leech
			 108416, -- Dark Pact
			 116849, -- Life Cocoon
			 145441, -- Yu'lon's Barrier
			 169373, -- Boulder Shield
			 173260, -- Shieldtronic Shield
			 184662, -- Shield of Vengeance
			 190456, -- Ignore Pain
			 203538, -- Greater Blessing of Kings
			 235313, -- Blazing Barrier
			 235450, -- Prismatic Barrier
			 258153, -- Watery Dome (m+)
			 265946, -- Ritual Wraps
			 265991, -- Luster (m+)
			 269279, -- Resounding Protection (general azerite trait)
			 270657, -- Bulwark of the Masses (general azerite trait)
			 272979, -- Bulwark of Light (paladin azerite trait)
			 273432, -- Bound by Shadow (m+ and Uldir)
			 274289, -- Burning Soul (DH azerite talent)
			 274346, -- Soulmonger (DH azerite trait)
			 274369, -- Sanctum (priest azerite trait)
			-274814, -- Reawakening (druid azerite trait)
			 271466, -- Luminous Barrier
			 272987, -- Revel in Pain
			 274395, -- Stalwart Protector (paladin azerite trait)
			 278159, -- Xalzaix's Veil
			 280165, -- Ursoc's Endurance (druid azerite trait)
			 280170, -- Duck and Cover (hunter azerite trait)
			 280212, -- Bury the Hatchet (warrior azerite trait)
			 280788, -- Retaliatory Fury
			 280862, -- Last Gift
			 287722, -- Death Denied
		},
		ImmuneToMagicCC = {
			    642, -- Divine Shield
			    710, -- Banish
			   8178, -- Grounding Totem Effect
			  23920, -- Spell Reflection
			  31224, -- Cloak of Shadows
			  33786, -- Cyclone
			  45438, -- Ice Block
			  46924, -- Bladestorm (fury)
			  48707, -- Anti-Magic Shell
			 186265, -- Aspect of the Turtle
		   	 204018, -- Blessing of Spellwarding
			 213610, -- Holy Ward
			 213915, -- Mass Spell Reflection
			 221527, -- Imprison
			 227847, -- Bladestorm (arms)
			-228049, -- Guardian of the Forgotten Queen (spellID might be wrong?)
		},
		BurstHaste = {
			   2825, -- Bloodlust
			  32182, -- Heroism
			  80353, -- Time Warp
			  90355, -- Ancient Hysteria
			 146555, -- Drums of Rage
			 178207, -- Drums of Fury
			 160452, -- Netherwinds
			 204361, -- Bloodlust (PVP talent)
			 204362, -- Heroism (PVP talent)
			 230935, -- Drums of the Mountain
			 256740, -- Drums of the Maelstrom
			 264667, -- Primal Rage
		},
		ImmuneToInterrupts = {
			    642, -- Divine Shield
			 186265, -- Aspect of the Turtle
			 196773, -- Inner Focus
			 209584, -- Zen Focus Tea
			 210294, -- Divine Favor
			 221705, -- Casting Circle
			-228049, -- Guardian of the Forgotten Queen (spellID might be wrong?)
			-289657, -- Holy Word: Concentration
			 290641, -- Ancestral Gift
		},
		ImmuneToSlows = {
			   1044, -- Blessing of Freedom
			  46924, -- Bladestorm (fury)
			  48265, -- Death's Advance
			  54216, -- Master's Call
			  87023, -- Cauterize
			 201447, -- Ride the Wind (windwalker monk pvp talent)
			 212552, -- Wraith Walk (F/UHDK PVE talent)
			 216113, -- Way of the Crane
			 227847, -- Bladestorm (arms)
			 287081, -- Lichborne (F/UHDK PVP talent)
		}.
	},
	casts = {
		Heals = {
			    596, -- Prayer of Healing
			   2060, -- Heal
			   2061, -- Flash Heal
			  32546, -- Binding Heal (hpriest PVE talent)
			  33076, -- Prayer of Mending
			  64843, -- Divine Hymn
			 120517, -- Halo (hpriest/disc PVE talent)
			 186263, -- Shadow Mend
			 194509, -- Power Word: Radiance
			 265202, -- Holy Word: Salvation (hpriest PVE talent)
			 289666, -- Greater Heal (hpriest PVP talent)

			    740, -- Tranquility
			   8936, -- Regrowth
			  48438, -- Wild Growth
			 289022, -- Nourish (rdruid PVP talent)

			   1064, -- Chain Heal
			   8004, -- Healing Surge
			  73920, -- Healing Rain
			  77472, -- Healing Wave
			 197995, -- Wellspring (rsham PVE talent)
			 207778, -- Downpour (rsham PVE talent)

			  19750, -- Flash of Light
			  82326, -- Holy Light

			 116670, -- Vivify
			 124682, -- Enveloping Mist
			 191837, -- Essence Font
			-209525, -- Soothing Mist
			 227344, -- Surging Mist (MW pvp talent)

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
