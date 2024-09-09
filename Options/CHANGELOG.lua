if not TMW then return end

TMW.CHANGELOG_LASTVER="10.0.0"

TMW.CHANGELOG = [==[
## v11.0.7
* #1857 - Added LibCustomGlow animations.
* #2144 - Cooldowns and auras now accounts for time dilation. For example, timer freezes caused by talents, or boss mechanics like Jailer phase transitions or Chronomatic Anomaly fast/slow effects.
* #2214 - New condition: Spell Overridden. For all those pesky new Paladin talents with no way to figure out which spell is active.
* Fix: #2089 - Track swings with Crusading Strikes talent in swing timers
* Fix: #2125 - "script ran too long" when zoning into instances.
* Fix: #2191 - Icon Shown condition ignoring Shown/Hidden checkboxes for disabled icons/groups.
* Fix: #2193 - Icon overlay and border animations starting in the wrong state.
* Fix: #2215 - Spell Charges condition not updating for countable spells without true charges.
* Fix: #2217 - Error in item cooldown conditions
* Fix: #2219 - Prevent cooldown finish pulse from showing on hidden icons
* Fix: #2220 - GCD state not ending when GCD ends.
* Fix: #2221 - Error in text display copy menu.

## v11.0.6
* #2190: Added options to Buff/Debuff icons to source stack count from tooltip numbers.
* Fix: #2208 Uncommon issue with monk action bars
* Fix: #2210 Fix desync of current GCD duration


## v11.0.5
* Spell Cooldown and Reactive Ability icons are vastly more efficient if the tracked ability is on your action bars (macros excluded).
  * This is done by utilizing new WoW 11.0 APIs that are specific to abilities present on action bars.
* Fix: #2197 upstream issue in LibSpellRange-1.0 with range checking in classic/cata.
* Fix: #2201 Don't treat inactive hero talent trees as learned talents

## v11.0.4
* Fix: #2186 Activation overlays in Retail
* The cooldown charge sweep is now skinned with Masque.

## v11.0.3
* Fix activation overlays in Classic
* Fix the Tracking ACtive condition (again)

## v11.0.2
* Support Masque round spell activation overlays. 
  * Must be enabled in Masque -> General Settings -> Advanced -> Spell Alert Style (pick anything other than "None").
* Fix: #2178 Spell dragging to icons broken (again) in WoW 11.0
* Fix: #2179 Tracking Active condition broken in WoW 11.0
* Fix: #2182 Unlearned choice node talents missing from suggestion list
* Fix: #2181 Totem tracking by name broken, added new warlock talents to Guardians icon type
* Fix: #2183 Abilities like Void Eruption/Bolt not reflecting when the spell changes.

## v11.0.1
* Fix: #2174 - Autocast conditions not working
* Fix: #2176, #2177, #2175, Many spells not tracking cooldowns properly

## v11.0.0
* Added the original Lightwell icon type back to Cata Classic
* Fix: dragging a spell to an icon not working in WoW 10.2.7.
* Fix: #2168 floating point errors in alpha animations
* Fix: Icon fade animations not always working on condition icons
* Fix: #2170 specific aura variable indexes 1,2,3 not working on buff/debuff icons

## v10.2.7
* Initial support for WoW 11.0
* Fix GetTalentTabInfo call for SOD Phase 4
* Fix Tooltip Number conditions for Cata

## v10.2.6
* Additional updates for Cataclysm Classic, including handling for new player resource types.

## v10.2.5
* Support for Cata Classic.

## v10.2.4
* Fix: #2154 - Errors when tracking items by slot number when the slot is empty.
* Fix: #2155 - Item cooldown API was broken by Blizzard in 10.2.6.

## v10.2.3
* Fix #2148 - Aura Tracking broken in WoW 1.15.1

## v10.2.2
* Fix #2137 - Tracking active condition broken in Classic Era.

## v10.2.1
* Classic: Modern APIs added back in WoW 1.15.0 are used for buff/debuff durations and spell casts.
* Fix #2122 - Keyboard input blocked after UI reload in combat when Allow Config In Combat enabled.
* Fix #2132 - attempt to index field 'SuggestionList' (a nil value).
* Fix #2131 - Additional scenarios where current talent loadout can be unknown.

## v10.2.0
* Version bumps for all WoW versions. 
* Fixed classic client detection.
* Fix #2119 - Handle Blizzard's new, poorly-introduced range check restrictions.
* Fix #2121 - Efflorescence is now just a buff, no longer a totem. If you were using the Efflorescence icon type (which will now just show as "Totem"), switch to using a buff/debuff icon.
* Workaround #2114 - Most textures become Avenging Wrath when Avenging Wrath is glyphed.

## v10.1.6
* Support for WoW Classic Era 1.14.4. The classic era codebase has been merged into the main codebase, so some features that don't support classic may be present in a non-working state.

## v10.1.5
* Support for WoW 10.1.5

## v10.1.1
* Fix #2081 - Cooldown of Eternity Surge not trackable when Font of Magic learned.
* Fix #2082 - Increase Insanity condition max to 150.

## v10.1.0
* Fixes for WoW 10.1.

## v10.0.9
* The "Buff - Number Of" and "Debuff - Number Of" conditions now support tracking multiple units (e.g. `group 1-40`). (#1989)
* Fix #2066 - Enrage effects were not being stored properly when fetching auras for noncached units.
* Fix #2059 - Condition update were not happening at the proper time for spell cooldown conditions.
* Fix #2038 - Fix more scenarios in which talent loadout name is not available immediately after talent events fire.
* Fix #2075 - Spell cast percent completion was not filtering by name.
* Fix #2072 - Swing timer monitors were not initializing dual-wield state until an equipment change was observed.
* Fix #2071 - Tooltip Number conditions not working on retail. Also switched these conditions to use modern APIs, resulting in substantially better performance.
* Workaround #1978, #2055  - Add hardcoded workarounds for a few reported covenant abilities that can't be tracked properly by name (Soul Rot, Adaptive Swarm).
* Workaround #2065 - Blizzard's cooldown bling effect ignores opacity, so suppress it for hidden icons.

## v10.0.8
* #2054 - Workaround Blizzard issue breaking tracking Execute cooldown by name.
* Workaround rare aura tracking error in arenas (Auras.lua:302: attempt to index local "instance" (a nil value)).
* Try to fix issues with `focus` unit handling when focused arena teammates join a match after you.
* Wrath: #2046 - Blizzard moved GetItemCooldown for no good reason.
* Wrath: Fix Talents.lua:399: attempt to index global 'C_ClassTalents' (a nil value) and other similar errors.

## v10.0.7
* #2053 - Fix an issue that broke tracking of Void Eruption and other similar spells in 10.0.6.

## v10.0.6
* Loss of Control icons now show the locked out spell school in the `[LocType]` tag.
* Fix icon GUIDs not getting persisted when inserted into DogTag strings.
* Fix an issue where Missing Buffs/Debuffs icon type sometimes functioned as if the 'Only cast by me' setting was enabled, even when it wasn't.
* Fix #2048 - names in spell equivalency lists were not being lowercased, resulting in spells listed by name not working in buff/debuff icons.

## v10.0.5
* Implement new WoW 10.0 Aura handling capabilities, resulting in an overwhelming performance improvement for the buff/debuff handling parts of TMW.
* #2025 - Add events to Combat Event icons for empowered spell casts.
* Fix #2026 - [string "Condition_ITEMSPELL"]:3: attempt to index field '?' (a nil value)
* Fix #2027 - Shapeshift, Zone/Subzone, Loadout, Name, NpcID, and Creature Type conditions broken.
* Fix #2029 - Unit Exists condition against "player" is always `true`, even if False is checked.
* Fix #2030 - Unit Conditions were being ignored

## v10.0.4
*  Fix bugs in totem conditions (and a few others) introduced in 10.0.3

## v10.0.3
* Fix ClassSpellCache.lua:171: attempt to index field 'SpellData' (a nil value)
* Fix #2019 - Expired totems are now treated as absent by the totem icon type, even if the wow API says they still exist.
* Fix #2017 - Add workarounds for Blizzard bugs around some Evoker ability and talent combinations.
* Wrath: Fix #2011 - PlayerNames.lua:100 attempt to concatenate field '?' (a nil value) 
* Wrath: Fix #2016 - "Unknown class DRUID"
* Wrath: Fix #2006 - Totems conditions once again function against any totem rank.

## v10.0.2
* Unified codebase for Retail and Wrath versions.
* #1992 - Added Talent Loadout condition.
* #1749 - Item Cooldown conditions no longer treat unusable items as having a cooldown of zero.
* #1758 - Added Spell Cast Percent Completion condition
* Wrath: #1996 - Add Rune Strike as a swing timer trigger
* Fix #1984 - attempt to index local 'conditionData' (a nil value)
* Fix #1998 - Error with Raid Warning (Fake) text notifications
* Fix #2001 - Points in talent not updating when switching specs

## v10.0.1
* Fix #1974 - Assorted warnings about XML attributes
* Fix #1981 - Fix integration with ElvUI's timer text
* Retail: Fix #1977 - Texts.lua:696: bad argument #1 to 'SetEndDelay' (must be a finite number)

]==]
