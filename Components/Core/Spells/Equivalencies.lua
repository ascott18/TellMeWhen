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

]]
TMW.BE = {
	debuffs = {
		ReducedHealing = {
			   8679, -- Wound Poison                        (rogue, assassination)
			  27580, -- Sharpen Blade                       (warrior, arms)
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
			    122, -- Frost Nova                          (mage, frost)
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
			  -6789, -- Mortal Coil                         (warlock, PVE talent, general)
			  -8122, -- Psychic Scream                      (priest, disc/holy baseline, spriest PVE talent)
		},
		Incapacitated = {
			     99, -- Incapacitating Roar                 (druid, bear)
			   -118, -- Polymorph                           (mage, general)
			   2637, -- Hibernate                           (druid, general)
			   1776, -- Gouge                               (rogue, outlaw)
			  -3355, -- Freezing Trap                       (hunter, general)
			  -6358, -- Seduction                           (warlock pet)
			  -6770, -- Sap                                 (rogue, general)
			  20066, -- Repentance                          (paladin, PVE talent, general)
		},
		Disoriented = {
			   -605, -- Mind Control                        (priest, PVE talent, general)
			  -2094, -- Blind                               (rogue, general)
		},
		Silenced = {
			  -1330, -- Garrote - Silence                   (rogue, general)
			 -15487, -- Silence                             (priest, shadow)
		},
		Rooted = {
			   -339, -- Entangling Roots                    (druid, general)
			   -122, -- Frost Nova                          (mage, general)
			  19229, -- Improved Wing Clip					(hunter, talent)
			  16979, -- Feral Charge (unused?)
			  19675, -- Feral Charge Effect
		},
		Slowed = {
			   -116, -- Frostbolt                           (mage, frost)
			   -120, -- Cone of Cold                        (mage, frost)
			  -1715, -- Hamstring                           (warrior, arms)
			  -2974, -- Wing Clip                           (hunter))
			   
			   -- Crippling Poison intentionally not by name -
			   -- 3408 is the buff that goes on the rogue who has applied it to their weapons.
			   3409, -- Crippling Poison                    (rogue, assassination)
			  -3600, -- Earthbind                           (shaman, general)
			  -5116, -- Concussive Shot                     (hunter, beast mastery/marksman)
			  -6343, -- Thunder Clap                        (warrior, protection)
			  -7321, -- Chilled (Ice/Frost Armor)           (mage)
			  -7992, -- Slowing Poison                      (NPC ability)
			 -12323, -- Piercing Howl                       (warrior, fury)
			  12486, -- Blizzard                            (mage, frost)
			 -12544, -- Frost Armor                         (NPC ability only now?)
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
			    -17, -- Power Word: Shield                  (priest, disc/shadow)
			 -11426, -- Ice Barrier                         (mage)
			  -1463, -- Mana Shield                         (mage)
		},
		ImmuneToMagicCC = {
			    642, -- Divine Shield                       (paladin, general)
			    710, -- Banish                              (warlock, general)
			   8178, -- Grounding Totem Effect              (shaman, PVP talent, general)
			  23920, -- Spell Reflection                    (warrior, PVP talent for arms/fury, baseline for protection)
		},
		-- BurstHaste = {
		-- 	   2825, -- Bloodlust                           (shaman, horde)
		-- },
		ImmuneToInterrupts = {
			    642, -- Divine Shield                       (paladin, general)
		},
		ImmuneToSlows = {
			    642, -- Divine Shield                       (paladin, general)
			   1044, -- Blessing of Freedom                 (paladin, general)
		},
	},
	casts = {
		Heals = {
			    596, -- Prayer of Healing
			   2060, -- Heal
			   2061, -- Flash Heal

			    740, -- Tranquility
			   8936, -- Regrowth

			   1064, -- Chain Heal
			   8004, -- Healing Surge

			  19750, -- Flash of Light
		},
	},
}

TMW.BE.buffs.DefensiveBuffs	= CopyTable(TMW.BE.buffs.DefensiveBuffsSingle)
-- for k, v in pairs(TMW.BE.buffs.DefensiveBuffsAOE) do
-- 	tinsert(TMW.BE.buffs.DefensiveBuffs, v)
-- end


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
