if not TMW then return end

TMW.CHANGELOG_LASTVER="10.0.0"

TMW.CHANGELOG = [==[
## v12.0.1
* Minor clarifications of secret behavior

## v12.0.0
* WoW Midnight support. 
* TBC Classic Anniversary support.
* Timer bars now choose their start/completion color based on the default shading style of the cooldown sweep for the icon type. This means that buff/debuff and similar icons start at the Completion Color (default green) and move towards the Start Color (default red) as they expire.
* Bar icons can now have smoothing enabled (most useful on Resource Display icons). Midnight only.
* Fix: #2311 error caused by IconModule_IconEventConditionHandler enabling unconditionally

## v11.2.8
* Fix #2310 spec checking broken below level 10 on Classic Era.

## v11.2.7
* Fix #2309 Additional assorted talent/spec errors on Classic Era.

## v11.2.6
* Fix #2307 C_SpecializationInfo.GetTalent: query.specializationIndex must be specified.

## v11.2.5
* New condition: Armor Repair Level - Checks the lowest durability percentage of any equipped gear.
* Meta Icons and Icon Shown conditions now use pure event-driven updates. This is made possible by dynamic, dependency-aware ordering of icon update checks. If you have circular dependencies between icons, you may find that some updates may be delayed by at least one update interval. 
* While Condition Set Passing and On Condition Set Passing triggers for notifications no longer evaluate while their icon's group is not shown/active. This now matches the behavior of all other notification triggers.
* Unit Conditions no longer evaluate while the icon that requested them is not shown/active.

## v11.2.4
* Fix Spells.lua:27: attempt to index field "SpellBookSpellBank" (a nil value)

## v11.2.3
* Fix missing Spell Activation Overlay condition in MoP.

## v11.2.2
* Add detection and warning of malfunctioning code in MetaTracker addon that breaks TMW.
* #2297: Shapeshift condition can now check by spellID.
* #2294: Add Delves to instance type condition
* Fix: #2298 Missing entry for 'DR-KidneyShot'
* Fix: #2293 Rune icon type config not loading in MoP


## v11.2.1
* Fix missing font in WoW 11.2

## v11.2.0
* Version Bump for WoW 11.2

## v11.1.9
* Fix: #2286 - Incorrect DR categories for MoP Classic
* Fix: #2285 - Perform extra spell cost calculations for monks to workaround bad data from Blizzard APIs while rolling.

## v11.1.8
* Fix: #2284 "Single-Button Assistant" cooldown tracking only worked after performing a `/reload`.
* Improve "Single-Button Assistant" to include abilities not on the action bar.
* New condition: Spell is Assistant Button action

## v11.1.5
* Added support for tracking "Single-Button Assistant" (1229376) as a cooldown. Note that all suggestible abilities should be on your action bars for proper functioning.
* Add missing localizations for some MoP spell equivalency groups

## v11.1.4
* Fix: #2276, #2277 broken Rune Cooldown configuration for Cata Classic

## v11.1.3
* Basic support for MoP Classic.
* New Condition: Spell is Assistant Suggestion (integration with 11.1.7 Combat Assist feature)
* Fix: #2274 Unit Class condition missing/incorrect classes in Classic/SoD.
* Fix: #2275 Activation Border animation not working in WoW 11.1.7
* Fix: The missing duration warning was sometimes showing at the wrong time.

## v11.1.2
* TOC bump for WoW 11.1.5
* Fix #2269 - [string "*Help.xml:44_OnLoad"]:10: attempt to index field 'arrow' (a nil value)

## v11.1.1
* Added support to new WoW 11.1.5 spell range events
* Fix: Adjust some parameters to better handle the 7 digit spellIDs that Blizzard started adding in 11.0.7
* Fix: #2266 Occasional incorrect cooldown duration for haste-affected cooldowns, especially those that have or can have charges, due to Blizzard not firing events.

## v11.1.0
* Fixes for WoW 11.1
* Fix: #2258 - Error when changing icon sorting within a group
* Fix: #2256 - Some currency conditions missing on characters that have never encountered a particular currency.
* Fix: #2253 - Listen to better events to pick up all weapon enchant changes

## v11.0.13
* Fix: #2250 - Currency checking error in Cata clasic

## v11.0.12
* Fix: #2248 - Error on characters with no talents learned.

## v11.0.11
* Fix: #2239 - Talent API issues on era and classic.

## v11.0.10
* Fix: #2228 - Cooldown bling appearing on groups with 0% opacity.
* Fix: #2230 - Raised max value of Maelstrom condition.
* Fix: #2231 - Some abilities not reflecting out-of-power state correctly.
* Fix: #2232 - Spell Queued condition not working on retail WoW.

## v11.0.9
* Fix various Lua errors.

## v11.0.8
* #1857 - Added LibCustomGlow animations.
* #2144 - Cooldowns and auras now accounts for time dilation. For example, timer freezes caused by talents, or boss mechanics like Jailer phase transitions or Chronomatic Anomaly fast/slow effects.
* #2214 - New condition: Spell Overridden. For all those pesky new Paladin talents with no way to figure out which spell is active.
* Fix: #2089 - Track swings with Crusading Strikes talent in swing timers
* Fix: #2125 - "script ran too long" when zoning into instances.
* Fix: #2191 - Icon Shown condition ignoring Shown/Hidden checkboxes for disabled icons/groups.
* Fix: #2193 - Icon overlay and border animations starting in the wrong state.
* Fix: #2215 - Spell Charges condition not updating for countable spells without true charges.
* Fix: #2219 - Prevent cooldown finish pulse from showing on hidden icons
* Fix: #2220 - GCD state not ending when GCD ends.
* Fix: #2221 - Error in text display copy menu.

## v11.0.7
* Fix: #2217 - Error in item cooldown conditions

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
