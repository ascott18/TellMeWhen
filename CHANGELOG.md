## v8.7.3
* Added a new "Any Totem" condition that will check all totem slots.
* Updated totem checking to account for removal of totem APIs in 1.13.3. Totem deaths cannot be accounted for.

### Bug Fixes
* Fix #1742 - Errors related to improper escaping of user input for the suggestion list.
* Fixed error `bad argument #1 to 'strlower' (string expected, got boolean)` when using Diminishing Returns icons
* Fix #1755 - Swing Timer conditions with durations other than zero seconds were not triggering updates at the proper moment.
* Fixed error `PlayerNames.lua:96: attempt to concatenate field "?" (a nil value)`

## v8.7.2
### Bug Fixes
* Fixed handling of spell names in French that have a space before a colon.
* Classic: Fixed detection of weapon imbues with charges.

## v8.7.1
* Classic: Added a pet happiness condition.

### Bug Fixes
* Classic: Fixed errors when checking the health of non-existent units with Real Mob Health installed.

## v8.7.0
* Classic: Updated the Cast condition and icon type to use LibClassicCasterino for approximations of others' spell casts.
* Classic: Aura durations might now be correct for abilities whose durations are variable by combopoints.
* The Missing Buffs/Debuffs icon type now sorts by lowest duration first.
* Switched to DRList-1.0 (from DRData-1.0) for DR category data.
* Added events to the Combat Event icon type for swing & spell dodges/blocks/parries.
* Classic: Added support for Real Mob Health and LibClassicMobHealth. Real Mob Health is the better approach, and must be installed standalone.
* Classic: Added instructions to the Swing Timer icon type on how to get Wand "swing" timers.
* Added an option to Spell Cooldown icons and Cooldown conditions to prevent the GCD from being ignored.
* Classic: Added a Spell Autocasting condition.

### Bug Fixes
* Fixed an uncommon issue that could cause some event-driven icons to not update correctly after one of the units being tracked by an icon stops existing.
* Classic: Fixed the Unit Class condition's options.
* Classic: Fixed the Weapon Imbue icon type & Condition for offhands.
* Classic: Fixed talented aura duration tracking.
* Classic: Fixed combopoint tracking.

## v8.6.9
* Classic: Aura durations now account for learned talents.
* Classic: Swing Timer now accounts for next-swing abilities.
* Classic: Added Spell Queued condition (for Heroic Strike & other next-attack abilities)

### Bug Fixes
* Fixed an issue with Unit Conditions where the initial state of the conditions sometimes wouldn't be taken into account.
* Changed the Slowed equivalency to track Crippling Poison by ID to prevent it from picking up the Rogue buff by the same name.
* When scrolling with the mousewheel, sliders that happen to land under your mouse will no longer be adjusted as long as your cursor does not move.
* Fixed an issue where the Artificial Maximum setting for Bar groups was not properly saving its value as a number.
* Classic: Fixed the Tracking Active condition.
* Classic: Fixed errors with the Spell Cast icon type.

## v8.6.8
* Classic: Fixed the logic for checking if the client is Classic or Retail.

## v8.6.7
* Added an Inset option to the border for both Bar and Icon views.

## v8.6.6
* Added border options to the standard Icon view (#1705).
* Added Heal Crit & Non-Crit events to the Combat Event icon (#1685).

### Bug Fixes
* Fixed an issue that prevented a descriptive message from being visible in the icon editor when no icon is loaded.
* Added workarounds to errors that will arise when anchoring a group to a "restricted" region (like a nameplate).
* Fixed #1696: When swapping profiles, run snippets before setting up icons.

## v8.6.4
* Added better error messages when testing sounds for sound notifications.

### Bug Fixes
* Fixed an issue where custom sounds entered by a SoundKitID would not play using the configured sound channel.

## v8.6.3
### Bug Fixes
* Fixed #1698 (again): Utils.lua:438: attempt to index local 'path' (a number value)
* Switched WoW-built-in sounds that TMW registers with LSM to use FileDataIDs instead of paths, since paths aren't allowed anymore in WoW 8.2.
 * Note that if you have other addons which are still incorrectly registering these sounds (like Omen), they won't work for you.

## v8.6.2
### Bug Fixes
* Fixed #1698: Utils.lua:438: attempt to index local 'path' (a number value)
* Fixed #1699: Several lists when editing notifications were no longer displaying correctly, if at all, in WoW 8.2.

## v8.6.1
* Buff/Debuff equivalency improvements

### Bug Fixes
* Fixed #1690: Framelevel issue with latest alphas of Masque.
* Fixed #1694: Empty group shrinks to minimum size of 1 icon.
* Fixed that Reactive Ability icons wouldn't use the No Mana state.
* Fixed #1697: Error when logging in in WoW 8.2.

## v8.6.0

### Discord
* TellMeWhen now has a Discord! Come ask questions, share configuration, or just hang out with other TellMeWhen users. https://discord.gg/NH7RmcP

### General
* Created a new system to collect performance metrics on a per-icon basis. You can view this new feature via `/tmw cpu` or under the "Performance" section in the main options.
 * This feature is for advanced users. No instructions or guidance will be provided on how to use it or how to interpret the data.
* Added a Scale setting to the Activation Border animation.
* You can now toggle an icon's enabled/disabled state by Ctrl+clicking it. (#22)
* New setting for Combat Event icons: Only if Conditions Passing. (#20)
* Unit Conditions can now be copied from one icon to another. (#18)
* Added Raise Abomination to the totem icon type for DKs (#1688)

### Bug Fixes
* Fixed a bug that caused export strings to sometimes contain a large amount of superfluous defaults.

## v8.5.9
### Bug Fixes
* Fixed GitHub #12 - A major bug introduced by a last-minute change in v8.5.8 that broke all icons that check multiple units.

## v8.5.8
* Groups now use `:SetFlattensRenderLayers(true)`, which should prevent other frames from appearing in between the different parts of the group and its icons.

### Bug Fixes
* Fixed #1631 - The Frame Level setting should no longer be prevented from having an effect until the next UI reload due to a change Blizzard has made recently to the way that `:SetToplevel(true)` works. A side effect of this fix is that clicking a group to configure it or its icons will no longer bring that group above others on your screen if you have overlapping groups.
* Item cooldown icons no longer incorrectly show timers for items whose cooldowns are pending start, like potions used in combat.
* Fixed #1644 - ConditionObject.lua line 435: attempt to index local 'unit' (a number value)

## v8.5.7
* Bump the TOC version to 8.1 now that Blizzard finally remembered to increment it on their end.
* Significant updates to buff/debuff eqauivalencies (thanks to user Jalopyy!)

## v8.5.6
* You can now use "thisunit" in Lua conditions as a reference to the current unit in any Unit Conditions.
* Made a number of performance optimizations around Unit Conditions.
* Unit Condition Icons:
 * Now correctly pass the icon's unit to the icon's text displays for use as the default unit.
 * When acting as a Group Controller, will no longer create blank spots if the opacity is set to Hidden for the data that would otherwise be displayed in that spot. This new behavior is the same behavior of most other icon types.

### Bug Fixes
* Fixed #1615 - Critical Strike condition throwing error "attempt to call global 'max' (a nil value)"
* Fixed #1618 - Conditions on Combat Event source/destination units that used event-driven updates could be in an incorrect state before the first time an update is needed.

## v8.5.5
* A few improvements to the spell equivalency lists.
* Added Keystone Level condition for Mythic+.
* The Unit Reaction condition now checks specifically if the subject is attackable by you. This prevents false positives on, for example, the opposite-faction guards in Dalaran.

### Bug Fixes
* Hopefully fixed #1572 - "Script ran too long" when zoning into an arena.
* Fixed #1584 - Error when switching profiles via slash command.
* Fixed #1586 - Fixed a timing issue related to detecting the GCD that could cause "While condition set passing" triggered animations to flicker if their conditions were based on cooldowns.
* Fixed #1611 - Conditions on the destination units for a Combat Event icon will now be used (previously destination units were using the source unit conditions by mistake).
* Fixed #1600 - Lua inputs were causing unrecoverable freezes in WoW 8.1 because `EditBox:Insert()` now silently ignores non-printing characters.

## v8.5.4
* New icon drag operation - Insert.
* Added Dark Icon and Mag'har to Unit Race condition.
* Added Stagger to the Resouce Display icon type.

### Bug Fixes
* Fixed #1575 - Notification handlers can no longer be chosen when their parent module is disabled.
* Fixed #1561 - Shear/Fracture not working correctly with Last Ability Used condition.

## v8.5.3
* Guardians icon type now accounts for Implosion and the Consumption talent.

### Bug Fixes
* Fixed #1544 - Blizzard changed return values of GetChannelList(), breaking chat channel text notifications.

## v8.5.2
* Includes latest LibDogTag-Unit with fixes for [SoulShardParts] and others.
* Updated Guardian icon type for 8.0 Warlock changes.
* Back by popular demand, DR reset duration is now an icon-specific setting, and once again defaults to 18.

### Bug Fixes
* Fixed #1534 - Attempt to register unknown event "WORLD_MAP_UPDATE"
* Fixed cusor position in tall textboxes sometimes being incorrect due to a Blizzard bug with FontString:SetSpacing()
* Fixed handling of pipe characters in export strings.

## v8.5.1
* Changed DR reset duration to 20 seconds from 18 to increase consistency.

### Bug Fixes
* Fixed #1509 - "Couldn't open Interface/AddOns/TellMeWhen_Options/"
* Fixed #1507 - Attempt to register unknown event "UNIT_VEHICLE"
* Fixed #1521 - \Components\Core\Utils.lua line 574: attempt to index local 'str' (a nil value)


## v8.5.0
* Battle For Azeroth support. Please report bugs to https://wow.curseforge.com/projects/tellmewhen/issues. 
 * I especially need help with the spell equivalencies (e.g. "Stunned", "DefensiveBuffs", etc.)
 * If you notice spells that are missing or that shouldn't be there, please let me know!

## v8.4.5
* Fixes for upcoming changes to ElvUI's cooldown timer texts.

## v8.4.4
* TellMeWhen_Options no longer saves a spell cache to disk. Performance improvements have made it feasible to compute this each time you log in as it needed, resulting in faster log-in/log-out times.

### Bug Fixes
* Fixed additional dropdown scaling issues.
* Added error messages for invalid import strings.

## v8.4.3
* Updates for Allied Races.
* Minor options UI improvements.
* Added options to disable TMW's built-in settings backup and the "backup" import source.

## v8.4.2
* Version bump & additional fixes for patch 7.3.0.

## v8.4.1
* Compatibility updates for patch 7.3.0.
* The Guardian icon type (Warlock) now has sort settings.
* Added Light's Hammer tracking to the totem/Consecration icon type.
* Added Soul Shard fragment tracking to conditions & Resource Display icons.
* Increased Astral Power condition cap to 130.
* Added newer drums to the BurstHaste equivalency.

### Bug Fixes
* Fixed dropdown scaling issues.

## v8.4.0
* Compatibility updates for patch 7.2.5.

## v8.3.3
### Bug Fixes
* Fixed the Equipment set equipped condtion.

## v8.3.2
* Version bump for Patch 7.2.

## v8.3.1
* Added a Spell Activation Overlay condition.
 
### Bug Fixes
* Lua conditions should once again properly resolve members defined in TMW.CNDT.Env.

## v8.3.0
* New setting for Reactive Ability icons: Require activation border. 
 * For all you prot warriors who like your Revenge procs.
* New Condition: Spell Cost.
* Updated the class spell list
* Demon Hunter resource condition slider limits are now flexible.

## v8.2.6
### Bug Fixes
* Increased Combo Points condition max to 10.
* Guardian icons should now detect deaths from Implosion.
* Fixed duration sorting on buff/debuff icons.

## v8.2.5
* Updates for patch 7.1.5, including:
 * Fixed role detection bug caused by GetSpecializationInfo losing a parameter.
 * Fixed invalid equivalency spell warnings from breaking all equivalencies.
 * Removed some invalid spells from equivalencies.

## v8.2.4
* Changed behavior of the On Combat Event notification trigger slightly to avoid occasional undesired timing issues (Ticket 1352).
* Added conditions for Monks to check their stagger under the Resources condition category.

### Bug Fixes
* Fixed BigWigs conditions for the latest BigWigs update.

## v8.2.3
* Improved behavior of exporting to other players.

## v8.2.2
* Packaging latest version of LibDogTag-Unit-3.0.

## v8.2.1
* You can now change bar textures on a per-group basis.
* Added some missing currency definitions.

### Bug Fixes
* Fixed updating of class-specific resource conditions for non-player units.
* On Start and On Finish notification triggers should no longer spaz out and trigger excessively.
* Meta icons should now always use the correct unit when evaluating the DogTags used in their text displays.
* Fixed meta icon rearranging.
* Fixed tooltip number conditions for locales that use commas as their decimal separator.

## v8.2.0
* New Icon Type: Guardians. Currently only implemented for Warlocks to track their Wild Imps/Dreadstalkers/etc.
* Support for Patch 7.1.

* New DogTag: MaxDuration
* Controlled icons can now be selected as a target of Meta icons and Icon Shown conditions.
* Cooldown sweeps that are displaying charges during a GCD when the GCD is allowed will now show the GCD.
* You can now flip the origin of progress bars to the right side of the icon.
* New Notification Triggers: On Charge Gained and On Charge Spent

### Bug Fixes
* Fixed an issue that would cause unintentional renaming of text layouts. 
* Fixed an issue with text colors after a chat link in Raid Warning (Fake) text notification handlers.
* Fixed an issue with timer/status bars briefly showing their old value when they are first shown.
* Fixed a few bugs relating to improper handling of the icon type name of some variants of the totem icon type.
* Fixed an issue with Condition-triggered animations not being able to stop for non-icon-based animations.
* Fel Rush and Infernal Strike should now work with the Last Ability Used condition.
* On Show/On Hide notification triggers should now work on controlled icons.
* All-Unit Buffs/Debuffs icons should now work correctly for infinite duration effects. They're also a bit better now at cleaning up things that expired.

## v8.1.2
* Restored the old Buff/Debuff duration percentage conditions, since they still have applications for variable-duration effects like Rogue DoTs.

### Bug Fixes
* Attempted a permanant fix to very rare and very old bug where some users' includes.*.xml files were getting scrambled around in their TMW install, leading to the problem of most of the addon not getting loaded.
* Fixed an issue with Condition-triggered animations not working consistently in controlled groups.
* Buff/Debuff Duration conditions should once again work properly with effects that have no duration.
* Fixed an issue with occasional missing checkboxes in condition configuration
* Fixed resource percentage conditions
* Fixed a rare bug that would cause cooldown sweep animations to totally glitch out, usually in meta icons.

## v8.1.1
### Bug Fixes
* IconType_cooldown\cooldown.lua:295: attempt to index field 'HELP' (a nil value)

## v8.1.0
* New group layout option: Shrink Group. For dynamically centering groups.
* Added new Notification triggers for stacks increased/decreased

### Bug Fixes
* Fixed the behavior of the Ignore Runes setting.
* Fixed Soul Shards condition - correct maximum is 6.
* Made the Last Ability Used condition not suck.
* Totem icon configuration should be back to its former glory.

## v8.0.3
### Bug Fixes
* Fixed creation of new profiles

## v8.0.2
### Bug Fixes
* Fixed: TellMeWhen\Components\Core\Icon.lua:491 attempt to index field 'typeData' (a nil value)

## v8.0.1
### Bug Fixes
* Fixed Maelstrom condition - correct maximum is 150.

## v8.0.0
### Breaking Changes
* There is a small chance you will need to reconfigure the spec settings on all your groups.
* Most of your old color settings were lost.

* You can no longer scale the Icon Editor by default. You can turn this back on in the General options.

* Each of the pairs of Opacity and Shown Icon Sorting methods have been merged.

* The Update Order settings have been removed.
 * Try replacing usages of the Expand sub-metas setting with Group Controller meta icons if you experience issues.

### General
* Full support for Legion. Get out there and kill some demons!
* All TellMeWhen configuration is now done in the icon editor.

* Color configuration has been completely revamped. It is now done on each icon.
 * Duration Requirements, Stack Requirements, and Conditions Failed opacities now use Opactiy & Color settings.
 * Out of Range & Out Of Power settings now use Opactiy & Color settings.
 * You can also set a custom texture for each of your Opacity & Color settings.

* Combat Log Source and Destination units may now have unit conditions when filtered by unitID.
* New conditions have been added for:
 * Checking your current location.
 * Checking your last spell cast (for Windwalker Monk mastery).
 * The old buff/debuff Tooltip Number conditions have returned as well.
* And much, much more! Dig in to check it all out!

## v7.4.0
* Bar and Vertical Bar groups now have several new options:
 * Show/Hide Icon
 * Flip Icon
 * Bar & Icon Borders

## v7.3.5
### Bug Fixes
* The TMWFormatDuration DogTag now properly handles negative durations.

## v7.3.4
* Blizzard's new completion pulse animation on cooldown sweeps is now disabled by default, and can be enabled in TMW's main options.

### Bug Fixes
* Power Bar Overlays should function once again.

## v7.3.3
* Unit Cooldown icons can now filter spells based on the known class spells of a unit.

### Bug Fixes
* Fixed: Condition_THREATSCALED: Usage: UnitDetailedThreatSituation("unit" [, "mob"])

## v7.3.1
### Bug Fixes
* Fixed: UnitAttributes.lua:277: 'for' limit must be a number.

## v7.3.0
* The suggestion list now works with arrow keys to pick what line tab will insert.
* You can now use the suggestion list to pick condition types (the Condition Type dropdown now has a textbox on it).
* The Player Specialization condition is now deprecated in favor of the Unit Specialization condition.
* On Left/Right Click notification triggers no longer make icons click-interactive when the icon is hidden (opacity 0).

### Bug Fixes
* Fixed some issues with the All-Unit Buff/Debuff icon type caused by some auras (A Murder of Crows) not firing combat log events on application/removal.
* Icons should no longer be treated as being on cooldown for color settings if they're tracking an ability that still has charges remaining.
* Fixed a typo that could sometimes break icon sorting, and may have also broken meta icons occasionally.
* Refactored the configuration for Animation and Text notifications, fixing a minor issue with settings not saving in the process.
* The Unit Specialization condition should now work for arena enemies from your own server.
* Fixed: meta.lua line 191: attempt to index field 'IconsLookup' (a nil value) (Ticket #1114)

## v7.2.6
### Bug Fixes
* Implemented a better fix to animations missing required anchors, since the fix in v7.2.5 broke several things.

## v7.2.5
* Tweaked some of the default text layouts so that they more closely resemble their pre-WoW-6.1 appearance.
* Removed the diminishing returns duration setting, as it is now always 18 seconds.

### Bug Fixes
* Removed some old code that was needed back when cooldown sweeps weren't inheriting their parent's opacity in the WoD beta. This was breaking cooldown sweeps on icons with Icon Alpha Flash animations where the alpha would go to 0.
* Icon Events are now setup at the end of icon setup to avoid issues with animations missing required anchors.
* Fixed a rare issue caused by unused parentheses on condition settings with less than 3 conditions.
* Fixed IconType_unitcondition\unitcondition.lua:96: attempt to index local "Conditions" (a nil value).

## v7.2.4
* New icon type: Unit Condition Icon.
* Added Dialog as a possible sound channel.
* The Icon Shown Time and Icon Hidden Time conditions are now deprecated in favor of using timer notification handlers.

### Bug Fixes
* Fixed an error that will happen when screen animations end.
* Cooldown icons that aren't set to show when usable should once again fire an On Finish event.
* Fixed ItemCache.lua:110 bad argument #1 to 'pairs' (table expected, got nil)
* Fixed an issue that would break upgrades over locale-specific data.
* Fixed colors of the backdrop for bar groups being wrong (green and blue were swapped).
* The Eclipse condition should now be much more responsive.
* Fixed: ClassSpellCache.lua line 281: Usage: GetClassInfo(ID)
* Fixed several issues when using On Duration Changed notification triggers on controlled groups.

## v7.2.3
* The old Runes condition has been deprecated. In its place are 3 new conditions that should be much easier to use.
* The Spell Cast Count condition has been deprecated. Its functionality can be replicated using the counter notification handler on a Combat Event icon.
* Updated the Chi condition to support a max of 6.
* You can now globally enable/disable global groups.
* While Condition Set Passing-triggered animations now work on a priority system, with those notifications higher in the configuration list having priority over lower-ranked notifications if both are eligible to play at the same time. This also prevents situations where no animations will play even though one should be.
* You can now customize the color of the backdrop for bar groups.

### Bug Fixes
* Fixed an issue that caused Unit Conditions to not work with special units (group, maintank, mainassist, and player names).
* Mark of Shadowmoon and Mark of Blackrock should now work with the Internal Cooldown icon type.
* Fixed an error with power bar spell cost detection for German clients.
* Removed the Monochrome font outline option because it causes crashes so often.
* Resource Display icons should now correctly display partial resources.
* Fixed some errors that happen when using meta icons as group controllers.

## v7.2.2
* You can now easily clone an event handler by right-clicking it in the Notifications tab.
* There is a new special unitID in TellMeWhen, "group" that will check raid or party depending on which you are in. It prevents the overlap that happens when checking "player; party; raid".
* You can now adjust the opacity of the backdrop for bar icons.

### Bug Fixes
* Rage (and perhaps other powers) should no longer be multipled by 10 in the Resource Display icon type.
* Warriors in Gladiator Stance will now be treated as DPS for groups' role settings, and for the Specialization Role condition.
* The "Force top-row runes..." condition setting checkbox should now always reflect the icon's settings.
* The Zone PvP Type condition now actually works.
* Excluding spells from equivalencies now works if the spell is an ID in the equivalency.
* Added event registrations to two more spellcast events in hopes of fixing an issue where Spell Cast icons sometimes don't disappear (also added these to the spell cast condition).
* Fixed a silly logic error that broke skinning of texts shown through meta icons.

## v7.2.1
### Bug Fixes
* Fixed incorrect DR categories after changes made to DRData-1.0.

## v7.2.0
* New icon type: Resource Display. Works with Bar and Vertical Bar group display methods to show the amount of health, mana, etc. that some unit has.
* The Multi-state Cooldown icon type is gone - Spell Cooldown icons can replicate its functionality.

* Combat Event icons can now be group controllers, filling up a group with each event captured.
* Buff/Debuff icons can now explicity set which variable they want to look at for the "Show variable text" option.
* All icons are now hidden when you are at the barber shop.
* The combo point condition now only checks your target (so you can't try to check "player", which doesn't work).

* New condition: Item has on use effect
* New notification handler: Timer. Manipulates a stopwatch-style timer when it is triggered.

* IMPORTANT: The Buff/Debuff Duration Percent conditions are being phased out because they are deceiving.
 * In Warlords of Draenor, the point at which you can refresh a buff/debuff without clipping any of the existing duration is at 30% of the BASE DURATION of the effect - not 30% the current duration.
 * Using these conditions to check when a buff/debuff has less than 30% remaining is bad practice, because if you refresh at 30% remaining of an already extended aura, you are going to clip some of it.
 * Instead, you should manually calculate 30% of the base duration of what you want to check, and compare against that value in a regular Buff/Debuff Duration condition.

### Bug Fixes
* Fixed range checking for multiple icon types (notably Multistate cooldowns, but also others).
* Blood Pact should now have the correct ID in the BonusStamina equivalency.
* Various tooltips now reflect that the game client once again supports MP3s.
* Fixed an issue that was breaking conditions that reference other icons.
* Fixed an issue that was causing icons in controlled groups to flash shown for one frame after an update is performed.
* Fixed an issue that was causing While Condition Set Passing event triggers to not start when their condition sets are passing after leaving config mode.
* Patched a potential Lua code injection attack vector in certain condition settings. (There is no evidence that this has been abused by anybody).

## v7.1.2
* The Combat Event icon type now has special events that will fire when you multistrike.
* Various tooltips now reflect that WoW only supports .ogg files for custom sound files - MP3s are no longer supported by the game client.
* Removed error warning about other addons using debugprofilestart() - we got the data we needed.

### Bug Fixes
* The Item in Range of Unit condition should once again work properly.
* TellMeWhen will no longer forcibly disable Blizzard's cooldown timer text when Tukui is enabled since Tukui now uses those texts as its timers.

## v7.1.1
### Bug Fixes
* Fixed a very silly mistake that broke anchoring of an icon's text displays when Masque was not installed.


## v7.1.0
* TellMeWhen has been updated for Warlords of Draenor. Please open a ticket on CurseForge for TMW if you notice anything missing.

* New icon types:
 * All-Unit Buffs/Debuffs. This icon type is mainly useful for tracking your multi-dotting on targets which might not have a unitID.
 * Combat Event Error. This icon type reacts to messages like "Must be behind the target" or "You are already at full health".

* New icon display method: Vertical Bars.

* New conditions
 * Instance Size
 * Zone PvP Type

* You can now set a rotation amount for a icon's text displays.
* The "Highlight timer edge" setting is back.
* You can now export all your global groups at once.

* The suggestion list now defers its sorting so that input is more responsive.
* The suggestion list is now much smarter at suggesting things. For Example, "swp" will now suggestion "Shadow Word: Pain", and "dis mag" will suggest "Dispel Magic".


### Bug Fixes
* Fixed another issue with ElvUI's timer texts (they weren't going away when they should have been).
* A whole lot of other minor bugs have been fixed - too many to list here.


## v7.0.3
* Re-worked the Instance Type condition to make it more extensible in the future, and also added a few missing instance types to it.
* Added a Unit Specialization condition that can check the specs of enemies in arenas, and all units in battlegrounds.

### Bug Fixes
* Fixed an error that would be thrown if the whisper target ended up evaluating to nil.
* TellMeWhen now duplicates Blizzard's code for the spell activation overlay (and has some additional code to get this to play nicely with Masque) so that it should hopefully no longer get blamed for tainting your action bars.
* TellMeWhen also now duplicates Blizzard's code for dropdown menus, and improves upon it slightly. This should also help with taint issues.

## v7.0.2
### Bug Fixes
* Fixed the missing slider value text for the Unit Level condition.
* The Haste conditions no longer have a hard cap of 100%.
* Fixed a false error that would display during configuring while using the `[Range]` DogTag.
* Fixed an error relating to refreshing the tooltip for non-button widgets.

## v7.0.1
* Numbered units entered with a space in the middle (e.g. "arena 1") will once again be corrected by TellMeWhen. It is still bad practice to enter units like that, though.

### Bug Fixes
* Fixed a typo that was preventing Loss of Control icons from reporting their spell.
* Fixed an error that would happen when upgrading a text layout that was previously unnamed: IconModule_Texts\Texts.lua:150 attempt to concatenate field 'Name' (a nil value)

## v7.0.0

### Core Systems
* You can now create global groups that exist for all characters on your account. These groups can be enabled and disabled on a per-profile basis.
* Text Layouts are now defined on an account-wide basis instead of being defined for individual profiles.

* Many icon types, when set on the first icon in a group, are now able to control that entire group with the data that they harvest.

* All references from one icon or group to another in TellMeWhen are now tracked by a unique ID. This ID will persist no matter where it is moved or exported to.
 * This includes:
  * DogTags
  * Meta icons
  * Icon Shown conditions (and the other conditions that track icons)
  * Group anchoring to other groups
 * The consequence of this is that you can now, for example, import/export a meta icon separately from the icons it is checking and they will automatically find eachother once they are all imported (as long as these export strings were created with TMW v7.0.0+)
 * IMPORTANT: Existing DogTags that reference other icons/groups by ID cannot be updated automatically - you will need to change these yourself.

### Events/Notifications
* Events have been re-branded to Notifications, and you can now add notifications that will trigger continually while a set of conditions evaluate to true.
* New Notification: Counter. Configure a counter that can be checked in conditions and displayed with DogTags.
* The On Other Icon Show/Hide events have been removed. Their functionality can be obtained using an On Condition Set Passing trigger.
* You can now adjust the target opacity of the Alpha Flash animation

### Icon Types
* Global Cooldowns are now only filtered for icon types that can track things on the global cooldown.
* Combat Event: the unit exclusion "Miscellaneous: Unknown Unit" will now also cause events that were fired without a unit to be excluded.
* Meta Icon: The "Inherit failed condition opacity" setting has been removed. Meta icons will now always inherit the exact opacity of the icons they are showing, though this can be overridden by the meta icon's opacity settings.
* Meta Icon: Complex chains of meta icon inheritance should now be handled much better, especially when some of the icons have animations on them.
* Diminishing Returns: The duration of Diminishing Returns is now customizable in TMW's main options.
* Buff/Debuff: Ice Block and Divine Shield are now treated as being as non-stealable (Blizzard flags them incorrectly)
* Buff/Debuff: Added an `[AuraSource]` DogTag to obtain the unit that applied a buff/debuff, if available.
* Buff/Debuff Check: Removed the "Hide if no units" option since it didn't make much sense for this icon type.

### Conditions
* New Conditions added that offer integration with Big Wigs and Deadly Boss Mods.
* New Condition: Specialization Role
* New Condition: Unit Range (uses LibRangeCheck-2.0 to check the unit's approximate range)
* The Buff/Debuff - "Number of" conditions now accept semicolon-delimited lists of multiple auras that should be counted.

### Group Modules
* You can now anchor groups to the cursor.
* You can now right-click-and-drag the group resize handle to easily change the number of rows and columns of a group, and doing so with this method will preserve the relative positions of icons within a group.
* Added group settings that allow you to specify when a group should be shown based on the role that your current specialization fulfills.

### Icon Modules
* You can now enter "none" or "blank" as a custom texture for an icon to force it to display no texture.
* You can now enter a spell prefixed by a dash to omit that spell from any equivalencies entered, E.g. "Slowed; -Dazed" would check all slowed effects except daze.

* New text layout settings: Width, Height, & JustifyV.

### Miscellaneous
* The group settings tab in the Icon Editor now only displays the group options for the currently loaded icon's group by default. This can be changed back to the old behavior with a checkbox in the top-left corner of the tab in the Icon Editor.

* Exporting a meta icon will also export the string(s) of its component icons.
* Exporting groups and icons will also export the string(s) of their text layouts.

* Various updates to many buff/debuff equivalencies.
* New buff equivalency: SpeedBoosts

* Code snippets can now be disabled from autorunning at login.
* Dramatically decreased memory usage for icons that have no icon type assigned.
* You can now use "thisobj" in Lua conditions as a reference to the icon or group that is checking the conditions.

* TellMeWhen now warns you when importing executable Lua code so that you can't be tricked into importing scripts you don't know about.

* TellMeWhen_Options now maintains a backup of TellMeWhen's SavedVariables that will be restored if TellMeWhen's SVs become corrupted.

* TellMeWhen no longer includes the massively incomplete localizations for itIT, ptBR, frFR, deDE, koKR, and esMX (esMX now uses esES). If you would like to contribute to localization, go to http://wow.curseforge.com/addons/tellmewhen/localization/

### Bug Fixes
* Units tracked by name with spaces in them (E.g. Kor'kron Warbringer as a CLEU unit filter) will now be interpreted properly as input.
 * IMPORTANT: A consequence of this fix is that if you are enter a unit like "boss 1", this will no longer work. You need to enter "boss1", which has always been the proper unitID.
* Importing/Exporting icons from/to strings with hyperlinks in some part of the icon's data will now preserve the hyperlink.
* Icons should now always have the correct size after their view changes or the size or ID of a group changes.
* Fixed an issue where strings imported from older version of TellMeWhen (roughly pre-v6.0.0) could have their StackMin/Max and DurationMin/Max settings as strings instead of numbers.
* The "Equipment set equipped" condition should properly update when saving the equipment set that is currently equipped.
* Fixed an issue when upgrading text layouts that could also cause them to not be upgraded at all: /Components/IconModules/IconModule_Texts/Texts.lua line 205: attempt to index field 'Anchors' (a nil value)
* Currency conditions should once again be listed in the condition type selection menu.
* The NPC ID condition should now work correctly with npcIDs that are greater than 65535 (0xFFFF).
* Meta icons should reflect changes in the icons that they are checking that are caused by using slash commands to enable/disable icons while TMW is locked.
* TellMeWhen no longer registers PLAYER_TALENT_UPDATE - there is a Blizzard bug causing this to fire at random for warlocks, and possibly other classes as well, which triggers a TMW:Update() which can cause a sudden framerate drop. PLAYER_SPECIALIZATION_CHANGED still fires for everything that we cared about.

## v6.2.6
### Bug Fixes
* Added a hack to ElvUI's timer texts so that they will once again obey the setting in TellMeWhen. Previously, they would be enabled for all icons because of a change made by ElvUI's developers.
* Spell Cooldown icons that are tracking by spellID instead of by name should once again reflect spell charges properly (this functionality was disrupted by a bug introduced by Blizzard in patch 5.4).

## v6.2.5
* ElvUI's timer texts are once again supported by TellMeWhen.

## v6.2.4
* Added DogTags for string.gsub and string.find.
* Added Yu'lon's Barrier to the DamageShield equivalency.

### Bug Fixes
* IconModule_Alpha/Alpha.lua:84: attempt to index local "IconModule_Alpha" (a nil value)
* Rune icons will now behave properly when no runes are found that match the types configured for the icon.
* The Banish loss of control type was accidentally linked to the Fear loss of control type - this has been fixed.
* Unit cooldown icons should now attempt to show the first usable spell even if no units being checked have casted any spells yet.

## v6.2.3
* IMPORTANT: The color settings for all timer bars (including bar group and timer overlay bars) have changed a bit:
 * The labels for these settings now correctly correspond to the state that they will be used for.
 * The colors will automatically switch when you enable the "Fill bar up" setting for a bar.
 * These changes will probably require you to reconfigure some of your settings.

* Icons in groups that use the Bar display method can now have their colors configured on a per-icon basis.
 * You can copy colors between icons by right-click dragging one icon to another.

* TellMeWhen now uses a coroutine-based update engine to help prevent the occasional "script ran too long" error.
 * This version also includes an updated LibDogTag-3.0 and LibDogTag-Unit-3.0 that should no longer throw "script ran too long" errors.

### Bug Fixes
* Removed the "Snared" Loss of Control category from the configuration since it is most certainly not used by Blizzard.
* Item-tracking icons and condition should now always get the correct data once it becomes available.

## v6.2.2
* Buff/Debuff icons can now sort by stacks.
* The group sorting option to sort by duration now treats spells that are on the GCD as having no cooldown.

* Added a few more popup notifications when invalid settings/actions are entered/performed.
* Icons will now be automatically enabled when you select an icon type.
* Incorporated LibDogTag-Stats-3.0 into TellMeWhen's various implementations of LibDogTag-3.0.
* The Mastery condition now uses GetMasteryEffect() instead of GetMastery(). The condition will now be comparable to the total percentage increase granted by mastery instead of the value that has to be multiplied by your spec's mastery coefficient (which is no longer shown in Blizzard's character sheet.)
* TMWOptDB now uses AceDB-3.0. One benefit of this is that the suggestion list will now always be locale-appropriate.
* The suggestion list for units is now much more useful.
* The suggestion list now has a warning in the tooltip when inserting spells that interfere with the names of equivalencies.
* The suggestion list now pops up a help message the first time it is shown.
* You can now copy an icon's events and conditions by right-click-dragging the icon to another icon.
 * You can also copy group conditions between groups this way.
* When right-click-dragging an icon to an icon that has multiple icons in the same place, you can now choose which one you would like the destination to be.

### Bug Fixes
* Buff/Debuff icons that are set to sort by low duration should now properly display unlimited duration auras when there is nothing else to display.
* The Ranged Attack Power condition should now always use the proper RAP value.
* Fixed some "You are not in a raid group" errors.
* All features in TellMeWhen that track items (including Item Cooldown icons and any item conditions) are universally able to accept slotIDs as input, and all features will now correctly distinguished equipped items from items in your bag when tracking by slotID. This is the result of a new, robust system for managing items.

## v6.2.0
* New Icon Type: Buff/Debuff Check (for checking missing raid buffs).
* New advanced feature: Lua Snippets
* New advanced icon event handler: Lua Execution

* Mass refactoring has taken place. You will need to restart WoW when upgrading to this version of TellMeWhen.
* Multi-state Cooldown icons can now keep track of spell charges.
* Added a new setting to the Runes condition that allows you to force the condition to check for non-death runes.
* Rune icons can now distinguish between checking normal runes and death runes.
* Rune icons have an option to show extra unusable runes as charges.
* Added a buff equivalency to track absorbtion shields ("DamageShield").

### New Conditions
* NPC ID
* Weekday
* Time of Day
* Quest Complete
* Spell Cast Count
* Absorbtion shield amount
* Unit Incoming heals

### Bug Fixes
* The IncreasedStats equivalency should now always properly check for the Legacy of the Emperor buff
* Groups being moved (dragged around) should now much  more reliably detatch from your cursor when they are supposed to.
* Fixed an accidental inversion of the 1st param to TMW_LOCK_TOGGLED
* Replaced Blood Pact with Dark Intent for the IncreasedStamina equivalency.
* The "All Types" setting for Loss of Control icons should now work as intended.
* Attempted to fix the issue where the "You are not in a raid" message would be caused by TellMeWhen.
* Fixed: Components/IconModules/IconModule_Alpha/Alpha.lua:145 attempt to perform arithmetic on field "actualAlphaAtLastChange" (a nil value)
* Fixed: IconType_unitcooldown/unitcooldown.lua:270 attempt to index local "NameHash" (a boolean value)
* Conditions that use the c.GCDReplacedNameFirst condition substitution will no longer fail to compile when the spell being subbed in contains a double quote.

## v6.1.5
### Bug Fixes
* Fixed an offset error with the Instance Type condition. 

## v6.1.4
### Bug Fixes
* Forgot to remove a call to a method that was retired in 5.2 when I upgraded the code to work with 5.2 (GetInstanceDifficulty).

## v6.1.3
* New icon type: Swing Timer.
* New conditions: Swing Timer - Main Hand; Swing Timer - Off Hand.
* Added textures to the icon type select menu.
* All pre-MoP compatibility code has been removed.
* You can now use item slot IDs as dynamic Custom Texture values. Syntax is `$item.1`, where 1 is the item slot ID (1-19) that you want to use.
* Added a setting to customize the shadow on text displays.

### Bug Fixes
* Text from the Text Displays module should now always appear above all other icon elements.
* Fixed: `Core/Conditions/Categories/PlayerAttributes.lua:60: attempt to call upvalue "GetInstanceDifficulty" (a nil value) `
* The ALPHA_STACKREQ and ALPHA_DURATIONREQ data processor hooks should now properly trigger the TMW_ICON_UPDATED event when their state changes, which will allow meta icons (that check icons that implement these hooks) to properly update as needed.
* The "Talent learned", "Glyph active", and "Tracking active" conditions should now always update properly when checked in a condition set where there are OnUpdate driven conditions in a higher position than these conditions.
* EditBoxes will no longer have their text reset if they are focused and have unsaved changes when a non-editbox setting is changed.

## v6.1.2
* Added a new tag [LocType] to display the category of loss of control icon types.
* New slash command for changing profiles: /tmw profile "Profile Name"
* Animations can now be anchored to different components of an icon (when appropriate).

### Bug Fixes
* Designed a new protocol for sharing class spells to prevent the old version of it that was dramatically flawed from leaking into a new version of it.
* Icon Color Flash animations should now work correctly.
* Rewrote (but mostly just refactored) the database initialization process so that it runs in a much more logical fashion, and also so it allows for upgrades in the "global" DB namespace to run when they are supposed to.
* Rewrote (but mostly just refactored) event configuration code.
* The [Opacity] tag should now properly return a number instead of a boolean.
* Added Mind Quickening to the IncreasedSpellHaste equivalency
* Fixed `[string "ConditionEvents_SPELLCHARGETIME"] line 3: attempt to call global 'GetSpellCharges' (a nil value)`
* The group "Only show in combat" setting is now handled by the group's event handlers (instead of conditions) to prevent Script ran too long errors (hopefully).
* Invented a new method for moving the Icon Editor so that it won't jump around all over the place anymore.
* Fixed an issue with DetectFrame for GroupModule_GroupPosition (Thanks to ChairmanKaga, ticket #740).
* Event handlers that are changed from an event that has short condition checking enabled to an event that does not have condition checking should now function correctly.
* It should no longer be possible for the bottom of the icon editor to extend off your screen and preventing you from resizing it.

## v6.1.1
* Added a new text output handler for the Instance channel, and updated existing chat output methods for this channel.

### Bug Fixes
* Fixed error Interface/AddOns/TellMeWhen/TellMeWhen.lua:155: table index is nil

## v6.1.0
* New icon display method: Bars.
* New icon type: Loss of Control (WoW 5.1+ only)
* You may notice some slight changes to the way your text layouts appear, especially if you used the Constrain Width setting. You will have to re-adjust your old layouts to achieve old functionality, which will probably require adding a second anchor to any affected text displays.
* New group option: Group Opacity.
* New conditions: Buff/Debuff Duration Percentage.
* The "Class Colored Names" setting was removed due to internal conflicts with DogTag and the implementation of this setting.

### Bug Fixes
* Conditions with minimum values less than zero should now allow for these values to be selected.
* The Show Timer Text option should now work properly with Tukui.
* You should no longer see an error randomly telling you that TMW can't do an action in combat when no action has been triggered.
* Logging in while in combat with Masque installed without the Allow Config in Combat option enabled should no longer leave icons in a mangled state.
* Logging in while in combat with the Allow Config in Combat option enabled should now have a much lower chance of triggering a 'script ran too long' error.
* Items whose cooldown durations are reported as being 0.001 seconds should no longer be treated as being usable.
* Added missing spells to the SpellDamageTaken equivalency
* Attempted a fix for error `<string>:"Condition_SPELLDMG":3: Usage: GetSpellBonusDamage(school)`
* All slashes in custom texture paths will be converted to backslashes upon processing.
* The `[Name]` DogTag should now always update properly.
 * Fixed the error stemming from `Components/Core/Spells/ClassSpellCache.lua:215 ()?` running while in combat.

## v6.0.4
* New icon event: On Condition Set Passing. Allows you to create an event handler that reacts to the state of a condition set.
* New icon event: On Icon Setup. Essentially allows you to have a "default state" for icon animations.
* Added a dropdown menu to select an icon when right clicking a spot on your screen that contains multiple icons.
* Conditions with no maximum value (e.g. Health/Mana; any condition that checks a time) now allow manual input of a value.
* There is now an option to allow configuration while in combat (as opposed to allowing at all the time with potential bugs, the options module now loads at login when this option is enabled to prevent many errors and bugs).

### New conditions
* Spell charge time
* In pet battle
* Equipment set equipped
* Icon Shown Time
* Icon Hidden Time

* New setting for Buff/Debuff icons: Hide if no units.
* Added Challenge Mode and 40 Player raid to the Instance Type condition.
* The Totem icon type has been re-focused towards the Rune of Power talent for mages.
* The Buff Efficiency Threshold setting is back.
* Changed all file encodings to UTF-8 in hopes of fixing the loading problems that many users are having.
* The `[Duration]` tag now has a parameter that allows for the GCD to be ignored (`[Duration(gcd=false)]`)
* Added a separate toggle for the Show Timer Text option that only affects the timer text that ElvUI provides.

### Bug Fixes
* Minimum group frame level is now 5 instead of 1 to prevent issues caused at low frame levels.
* Increased the delay on LoadFirstValidIcon from 0.1 seconds to 0.5 seconds in hopes of preventing the AceCD:804 error more often.
* Soul shard condition maximum has been increased to 4 (from 3).
* The lightwell icon type should now work properly with the Lightspring glyph.
* Tried again to fix the AceCD:804 error. Probably didn't succeed.
* Fixed an incorrect spellID for Spirit Beast Blessing in the IncreasedMastery equivalency.
* Groups should now properly show/hide as needed when you change between primary/secondary talents specializations when both specializations are the same.
* Condition Object Constructors are now much more reliable (at the cost of some garbage churn when running TMW:Update())
* Fix attempted for GroupModule_GroupPosition/Config.lua line 47: attempt to index local 'Module' (a nil value)
* IncreasedStats should now properly include Legacy of the Emperor
* Fixed Components/IconTypes/IconType_unitcooldown/unitcooldown.lua:317 attempt to index local 'NameHash' (a boolean value)
* Fixed Components/IconModules/IconModule_PowerBar/PowerBar.lua:128 attempt to index local 'colorinfo' (a nil value)
* Fixed Components/IconModules/IconModule_Alpha/Alpha.lua:96 attempt to compare nil with number
* The "Show Timer Text" option now works with ElvUI
* Fixed TellMeWhen: Condition MELEEAP tried to write values to Env different than those that were already in it.
* Attempted some fixes at some obscure bugs that can happen with replacement spells (e.g. tracking Immolate in a debuff icon was getting force-changed to Corruption in Affliction spec.)
* Removed the blank normaltexture that every icon had because of issues it causes in WoW 5.1
* The Instance Type condition should now work properly.
* Hacked in a fix for `<string>:"local _G = _G -- 1...":6: attempt to index field "__functions" (a nil value)`
* Item conditions show now correctly work if the item that they are tracking was entered by name and wasn't in your bags at login.
* When a profile in the import menus has more than 10 groups, its groups will be split into submenus so that they don't run off the screen.
* Attempted a fix at the issue with text corruption when typing Chinese characters into DogTag formatted editboxes.
* The glyph condition should now work correctly when its logic is set to false.
* You should no longer be spammed with messages telling you that you are not in a guild.
* The Show icon texture setting for MikSBT text output should now function as intended.
* Attempted a fix for TellMeWhen.lua line 2333: attempt to get length of field 'CSN' (a nil value)

* A Special note: r450 concludes a series of 9 bogus commits that were made in order to restore the revision number of the repo back to where it was before the data loss that struck CurseForge's SVN repos on 11/7

## v6.0.3
* Re-implemented the stance condition for paladin seals.
* Minor updates for some buff/debuff equivalancies. Still need help getting these completely up to date, though! If you notice something missing, please let me know!
* You can now change the event of an event handler once it has been created.
* New setting for Combat Event icons - Don't Refresh.
* Added Raid Finder to the Instance Type condition.
* You can now output text to the UI Errors Frame.
* Moved the Timers ignore GCD & Bars ignore GCD settings from per-profile to per-icon.
* Updated Unit Cooldown icons for all cooldown resets in MoP.
* DR categories should now be complete for MoP. Please report any missing spells.
* You can once again toggle config mode in combat. You may still get script ran too long errors if TellMeWhen_Options has not been loaded yet and you unlock in combat,  but it won't break anything.
* You can now reorder groups.
* Added a setting to make colors ignore the GCD. It is enabled by default.
* Added center text as a default text layout.
* New condition: Unit is Player.
* Unit conditions now allow Lua conditions.
* Unit conditions now allow you to track the target of the icon's units.

### Bug Fixes
* Fixed static formats again (ICONMENU_MULTISTATECD_DESC)
* (Condition ROLE): attempt to index global "roles" (a nil value)
* Buff/debuff duration sorting actually works now!
* TellMeWhen_Options.lua:3351: attempt to index local "settingsUsedByEvent" (a nil value)
* Announcements.lua:531: attempt to concatenate local "Text" (a nil value)
* Leader of the Pack should now be properly checked by the IncreasedCrit equivalency
* Fixed a major flaw with importing profiles from backup or from other profiles in the db
* (Condition THREATRAW): attempt to call global 'UnitDetailedThreatSituation' (a nil value)
* Fixed cooldown resetting with unitcooldown icons. Spells still not really updated for MoP
* Fixed a bug where colors weren't being updated when the duration of an icon changes. Colors still suck, but at least they should work (better) now.
* Fixed a bag bug that will completely break most configuration after cloning a text layout
* Fixed a bug where profiles of version 60032 or earlier could not be imported by version 60033 or later.
* Fixed an error caused by dragging certain talents/specialization spells onto icons.
* Wrote a library (LibSpellRange-1.0) to solve the range checking problem in MoP.
* Texts.lua line 438: attempt to compare nil with number - Fixed for real this time!
* The talent specialization condition will now properly allow all four choices for druids.
* The pet talent tree conditions should no longer be listed for non-hunters.
* As a workaround to a strange bug in DogTag, the `[Stacks]` tag now returns a number value instead of a string. All default and otherwise reasonable variations of `[Stacks:Hide('0')` should automatically be upgraded.
* Unit conditions now actually work with icon types other than Buff/Debuff.
* Fixed an error with the GCD condition on login.
* The behavior of the link parameter for Item Cooldown icons' `[Spell]` DogTag should no longer be backwards.
* Shift-clicking links into the text announcement input box should now format them correctly for DogTag. Existing links cannot/will not be updated.
* Fixed errors with mismatched frames and channels in the text output event configuration.
* Attempted a fix for an error involving data from the last used suggestion module to leak into the DogTag suggestion module.

## v6.0.2
* Cooldown icons should now provide much better functionality when checking multiple spells. Single-spell functionality should (hopefully) remain unchanged.
* Updated the name and description of the "Spell Cast Succeeded" Combat Event to reflect that it now only tracks instant cast spells.

### Bug Fixes
* Bumped TellMeWhen_Options interface number
* Fixed warlock stance suggestions
* Removed paladin auras
* Fixed name coloring issue
* Fixed an error with range checking invalid spells
* Holy power limit increased to 5
* The "Show Variable text" setting should no longer cause errors
* Fixed the GCD spell for warriors (again)
* Fixed an issue with static formats and ptBR, zhCN, and zhTW.
* /Core/Conditions/Categories/BuffsDebuffs.lua:56 attempt to index global 'strlowerCache' (a nil value)

## v6.0.1
* Bug fix: Fixed positioning issues when using Masque.

## v6.0.0
* This is by far the biggest update that TMW has ever seen. There were so many changes that I lost track of them. Here are a few:

* Full support for Mists of Pandaria. If anything is missing, please open a ticket.

* Almost everything in TMW is now modular. The most immediate effect of this is that the main tab in the icon editor is now divided into panels for each component that is contributing to an icon.
* Implemented LibDogTag as the text manager for TMW instead of TMW's old (and very limited) system. You can now create text layouts that can be applied to an icon to dictate how the texts for that icon will be displayed.
* You can now specify a new set of conditions that are attached to the units that an icon checks. This is the replacement for the now-removed ability to track "%u" as a unit in icon conditions.
* You can now select any of the 4 sound channels to play sounds to (instead of just Master and SFX).
* You can now list specific totems to be checked by totem icons.
* Added On Left Click and On Right Click event handlers to icons.
* You can now change the direction that icons layout in within a group.
* Spell Crit is now an event that can be tracked by Combat Event icons.

### New Conditions
* Added a condition to check if you have your mouse over a frame (group or icon).
* Added conditions to check if you have a certain glyph active.
* Added a condition to check the creature type (Undead, Humanoid, Demon, etc.) of a unit.

* There are many, many more changes not listed here. I recommend that you just start configuring TellMeWhen to see what all has changed.

## v5.0.2
* Bug Fixes:
 * (r485) (Condition): attempt to call global "GetEclipseDirection" (a nil value)

## v5.0.1
* Bug Fixes:
 * (r483) Unit Cooldown icons checking spells by name should now function properly.
 * (r483) Cooldown sweeps and other icon components are no longer anonymous frames, returning to their previous nomenclature appended by an underscore and the icon's view type (Currently only "icon", more coming soon)
 * (r483) Fixed a faulty upgrade of the "Pass Through" setting when upgrading past 50035. Settings that already had this faulty upgrade occur may notice that the "Pass Through" setting on some of their events was toggled from checked to unchecked.

## v5.0.0
* Super cool changes:
 * All icon types have been changed to be entirely event based, meaning that they will no longer update themselves when they don't need to, resulting in a (tremendous) performance increase.
 * The Condition engine has been completely rewritten and is now almost entirely event driven, resulting in another (tremendous) performance increase.
 * Events have been completely rewritten to allow an unlimited amount of handlers to be created for an icon (instead of one text, one sound, and one animation per event per icon as previously).
 * You can now sort all of the icons of a group based on attributes like duration, stacks, and opacity.

* Pretty cool changes:
 * You can now check units relative to the special condition unit '%u' (//for example, '%u-target' or '%upettarget'//).
 * There is now an option (enabled by default) to color the names of units in text displays and outputs.
 * Added slash commands to easily enable or disable icons and groups.
 * Added Floating Combat Text as a text output.
 * Added two new animations: Icon Border and Icon Image Overlay.
 * You can now press tab to insert the first entry that is displayed in the suggestion list.

* Really boring changes:
 * The icon listing in dropdowns for meta icons, condition icons, and others is now much prettier and more informative.
 * Enrage is now a proper dispel type, and no longer relies on a pre-defined list of enrages.
 * Implemented a proper class-based inheritance system for many objects (Icons, Icon Types, Groups, Condition Groups).
 * Icons that check units now have their units managed behind the scenes whenever possible so that icons aren't trying to check units that don't exist.
 * You can now drag spells and items to the Custom Texture editbox to easily insert the texture of that spell or item.
 * Power bars and Timer bars have been shipped out into their own files, so a completely restart will be needed if you want to use them.

* Bug Fixes:
 * (r427) (Condition):  attempt to call global 'GetPrimaryTalentTree' (a nil value)
 * (r428) (Condition):  attempt to call global 'IsResting' (a nil value)
 * (r428) conditions.lua line 447: attempt to compare nil with number
 * (r429) Implemented a workaround for Blizzard's mismanagement of color in the Raid Warning Frame text output
 * (r429) TellMeWhen_Options.lua:1434: attempt to index local "icon" (a nil value)
 * (r429) An icon/group should no longer be treated as if it has failing conditions after it had conditions that were failing, but those conditions were removed
 * (r430) Fixed the list of unitIDs used to guess a unit's class
 * (r431) A unit's class should now be properly detected when the unit is from another server
 * (r434) Icon Show/Hide events should work once again
 * (r435) Unit substitutions should work once again
 * (r436) Fixed a bug causing the wrong data to be reported for Combat Event events
 * (r437) When a meta icon changes the icon it is checking, it should no longer stop any animations that the meta icon itself initiated (non-inherited animations)
 * (r439) TellMeWhen-5.0.0.lua:4227: attempt to index local "ic" (a number value)
 * (r441) TellMeWhen-5.0.0.lua:3572: attempt to compare nil with number
 * (r442) (Not really a bug fix): Added an option to TMW's main settings to temporarily disable the new update mechanism, reverting to the old method.
 * (r443) Fixed SPELL_ACTIVATION_OVERLAY_GLOW_HIDE typo.
 * (r451) `TellMeWhen-enUS.lua:404: nesting of [[...]] is deprecated near "["`
 * (r452) The Resting condition should now properly update when entering a battleground/dungeon/etc while resting, and vice-versa.
 * (r453) Combat Event icons should no longer process any sound/text/animation events when their parent group is hidden.
 * (r459) TellMeWhen-5.0.0.lua:4740: attempt to index field "OnDuration" (a boolean value)
 * (r461) TellMeWhen.lua line 3105: attempt to index field '?' (a boolean value)
 * (r462) AceDB-3.0-22.lua:104 in function <Ace3/AceDB-3.0/AceDB-3.0.lua:100 table index is NaN (MAYBE)
 * (r464) Fixed meta icons that check entire groups
 * (r467) TellMeWhen-5.0.0.lua:3018: attempt to concatenate local "name" (a nil value)
 * (r468) Meta icons that are checking conditions show now properly update themselves when the state of their conditions change
 * (r469) Buff/Debuff "Number of" conditions should work properly now.
 * (r469) Sorting Buffs/Debuffs should now work if only one aura is being checked by the icon (the unit being checked may have more than one auras of the same name/ID, or the icon may be checking multiple units.)
 * (r470) Icons that are being watched by On Icon Show/Hide events should now always be registered with the icon update engine to ensure that the icons that depend on these events function as expected
 * (r471) TellMeWhen-5.0.0.lua:522: attempt to index local "h" (a nil value)
 * (r472) TellMeWhen_Options.lua:4797: attempt to concatenate local "i" (a nil value)
 * (r476) TellMeWhen-5.0.0.lua:457: attempt to index local "h" (a nil value)
 * (r477) Buff/debuff icons that sort or that exceed the efficiency threshold should now properly update and display the unit they check when requested
 * (r478) CLEU icons should once again not process their events when the icon or the icon's group is hidden
 * (r479) Attempted a fix at activation overlay borders appearing underneath the icon they are playing on

## v4.8.3
* Bug Fixes:
 * (r423) Events with conditions (Duration, Stacks changed) should now handle animations and sound properly.

## v4.8.2
* Bug Fixes:
 * (r421) You should no longer lock up when using the GCD condition

## v4.8.1
* Bug Fixes:
 * (r412) icd.lua:134 attempt to index field 'HELP' (a nil value)
 * (r413) Meta icons that are sorted by high duration should now diplay the first icon shown if no icons have an active timer
 * (r414) Combat Event icons that have spell filters without defined durations should now properly fall back to the icon-wide duration
 * (r416) Meta icons that are set to sort should once again sort
 * (r417) The icon unit setting should now always save when using the dropdown to change it

## v4.8.0
* New icon type: Combat Event. Displays information about combat events according to filters that you can set. Full support for events, including text output.
* Rewrote the entire animation system to allow meta icons to inherit icon animations.
* Text outputs now substitute a hyperlink for '%s' when appropriate.
* --You can now leave the unit cooldown icon's "Unit(s) to watch" field blank to track all known units.
* New animation: Icon: Alpha Flash.
* Icon animations can now be set to play indefinitely (or until stopped by the Icon: Stop Animations animation trigger).
* Removed Entangling Roots from the CrowdControl debuff equivalency.
* Bug Fixes:
 * (r384) Weapon enchant should now be properly detected in zhCH clients
 * (r384) The weapon enchant suggestion list should now properly display shaman enchants in zhTW clients
 * (r384) TellMeWhen_Options.lua:2092 Usage: GetAddon(name): 'name' - Cannot find an AceAddon 'LUI_Cooldown'
 * (r385) Moving/Swapping an icon that the icon editor is editing shouldn't cause the old settings to stick around
 * (r390) Weapon enchant icons should now always detect the current weapon enchant in a timely manner for rogue characters
 * (r391) Added the debuff that results from being the the target of a warrior who casts intimidating shout with the glyph to the Feared debuff equivalency
 * (r396) Buff/debuff icons should now set an ID as their spell checked rather than a name, allowing them to function more completely with the hyperlink feature of r395
 * (r397) Animations inherited by a meta icon should now properly cancel when the meta icon changes to an icon with no animations
 * (r398) Both ranks of Shattered Barrier should now be included in the "Rooted" equivalency
 * (r401) Conditions that check units should now work again (oops)
 * (r402) Condition:1: attempt to index global "c" (a nil value)
 * (r403) StaticFormats.lua line 27: bad argument #1 to 'format' (number expected, got string)
 * (r406) Fixed a small bug with the timers on Condition Icons
 * (r409) Spell durations containing a decimal should now be properly inserted via the suggestion list when durations are inserted

## v4.7.3
* New Feature: Animations. You can now pick animations to play when an icon event occurs, such as having the screen shake or an icon flash.
* All event outlets have a "Play" button that you can test the event with.
* You can now change the "Show Timer Text" option if LUI is the only addon enabled that can handle cooldown timer texts.
* Changed the "Hide when slot is empty" to include hiding the icon if the slot being checked contains a shield or off-hand frill.
* Implemented the "Failed Conditions" opacity setting for meta icons.
* Slightly reworked the import dropdown to more accurately detect the group being edited, and to disallow importing of a data type where that data type is not being edited.
* Added buttons to the icon editor to allow easy switching between recently edited icons.
* Added suggestions for text substitutions.
* Bug Fixes:
 * (r356) Attempted a fix for default.lua:70 attempt to concatenate global 'input' (a table value)
 * (r358) Icons tracking multiple elements whose start times are exactly the same should now properly update their timers when the first element gives yield to the second after timer expiration.
 * (r358) Attempted a fix for TellMeWhen_Options.lua:2163: attempt to index upvalue 'HELP' (a nil value)
 * (r360) If a meta icon is directly checking another meta icon, and the meta icon being checked changes the icon that is is checking, the meta icon checking the other meta icon should now properly update its inherited settings.
 * (r365) Buff/Debuff icons tracking the "Enrage" dispel type only should now always show the correct texture in configuration.
 * (r368) Lightwell glyph detection was apparently a little iffy. Added some manual checks in case the events don't fire when they should.
 * (r370) The "ReducedArmor" equivalency should now track raptors' "Tear Armor" debuff properly.
 * (r372) TellMeWhen_Options-r369.lua:278 attempt to index local "f" (a nil value)
 * (r378) Icon flashers should now work properly without Masque.
 * (r379) Fixed a bug that was preventing importing from a group in which the first icon is blank.
 * (r379) Fixed (kinda) the status bar when exporting large pieces of data from TMW's Ace options dialogs.
 * (r380) TellMeWhen-r379.lua:1803 bad argument #2 to "format" (number expected, got nil)

## v4.7.2
* New Icon Type: Lightwell
* Condition icons now use the Custom Texture editbox to select their texture instead of the Choose Name editbox (for consistency)
* You can now output text to the raid warning frame without actually sending a raid warning to your raid.
* You can now export icons to an entire raid or your entire guild by typing "RAID" or "GUILD" as the name to export to.
* Meta icons can now sort their components based on their current duration.
* Added an option to color the border of Masque skins with the coloring applied to icons. This setting can be found under the *Global Colors* config in TMW's main options.
* Bug Fixes:
 * (r344) Temporary fix (I hope) for the bug where OmniCC timers would randomly stop after a timer was refreshed.
 * (r345) TellMeWhen.lua:1467 table index is nil
 * (r346) The suggestion list for weapon enchants should once again function properly.

## v4.7.1
* Bug Fixes:
 * (r342) Condition icons will no longer spam their event outputs when "Only show if timer is active" is enabled.

## v4.7.0
* Completely redid the color system. Colors are now defined (in the main optons) globally, with the option to configure them per icon type and override the global settings.
* Addded "%p" as a substitution for the name of the previously checked unit.
* Unit substitutions can be used as the destination for a whisper text output.
* You can right-click-drag icons anywhere on screen to anchor them to any mouse enabled frame, or to move an icon into a new group.
* Added a setting to disable new version warnings.
* It is now easier to delete old groups.
* Added substitutions "%d" for duration and "%k" for stacks.
* Added events for duration and stack changes, and expanded event settings.
* Performance Increase: Icons should no longer update themselves multiple times within one update period when the update interval is set to zero and the icon is being checked by multiple metas/conditions.
* You can now set a group as a component of a meta icon, causing the meta icon to check all icons that are part of the selected group.
* Meta icons now support the "Always Hide" setting.
* Conditions can now check "%u" as a unit, which will substitute in whatever unit the icon is currently checking.
* Added conditions to check absolute and max values of resources.
* Bug Fixes:
 * (r316) TellMeWhen_Options.lua:2831: attempt to index local "spaceControl" (a nil value)
 * (r321) The runic power condition should now properly track runic power instead of mana.
 * (r324) Meta icons should once again properly inherit colors from Masque.
 * (r327) TellMeWhen_Options.lua line 3189: attempt to call method 'IsVisible' (a nil value)
 * (r328) It should no longer be possible to have an icon shown condition check the icon that it is a child of.
 * (r328) Switching profiles while TMW is unlocked should no longer cause icon coloring to malfunction.
 * (r329) TellMeWhen-4.6.7.lua:3469: attempt to index local "settings" (a nil value)
 * (r332) Binding/label text should now properly clear when resetting an icon.
 * (r334) Fixed a bug with meta icons checking other meta icon without "Check sub-metas" enabled
 * (r335) TellMeWhen-4.6.7.lua:1771: attempt to index local "condition" (a number value)
 * (r335) TellMeWhen_Options.lua:3883: Usage: TellMeWhen_IconEditorSoundEventSettingsValue:SetText("text")
 * (r336) Fixed a bug with condition icon timers resetting themselves when conditions begin failing.

## v4.6.7
* Bug Fixes:
 * (r310) Fixed sound event text overflow bug
 * (r311) Possibly fixed a bug that was causing the event settings of deleted groups to stick around
 * (r312) Added Sudden Death/Colossus Smash to the cooldown reset tracker for Unit Cooldown icons
 * (r313) TellMeWhen will no longer completely break when loading with ButtonFacade but not Masque installed

## v4.6.6
* The suggestion list has been completely rewritten, and many features have been added.
* Seeing as Masque has been out for a month now, I think it is safe to say that ButtonFacade is now obsolete. Removed all support for ButtonFacade
* Added a setting to make events only fire if the icon is shown.
* Bug Fixes:
 * (r300) default.lua:67: attempt to index local 'ics' (a nil value)
 * (r301) TellMeWhen_Options-4.6.4.lua:5575 bad argument #1 to "pairs" (table expected, got nil)
 * (r302) You can now properly undo a change in sound file
 * (r302) TellMeWhen-4.6.6.lua:2259: bad argument #3 to "format" (number expected, got nil)
 * (r302) TellMeWhen-4.6.6.lua:192: attempt to compare nil with number
 * (r304) Fixed various bugs relating to inserting text into strings with multibyte characters (zhCN, zhTW, koKR, ruRU)
 * (r307) TellMeWhen_Options.lua:4662: Usage: GetModule(name, silent): "name" - Cannot find module "cooldown"
 * (r307) Imported strings created in r307+ into r307+ will now try extra hard to fix any errors casued by Blizzard's buggy editboxes.
 * (r308) Event settings in the icon editor should now always updated to reflect their current setting.
 * (r308) Fixed buggy event button texts for zhCN and zhTW clients.

## v4.6.5
* Bug Fixes:
 * (r294) Fixed a bug where conditions were being erroneously attached to an icon/group after adding a condition and then removing all conditions.
 * (r294) TellMeWhen.lua line 1452: attempt to index local 'condition' (a number value)
 * (r296) TellMeWhen_Options.lua:2703: Missing version of data

## v4.6.4
* New Condition: Pet talent tree.
* You can now undo and redo changes made to icon settings.
* Rewrote the help module, and migrated/added some new warnings to it.
* Diminishing return category mismatch warnings are now much more informative.
* The condition editor is prettier now.
* There is now a unique default condition type (instead of just using the health condition, which caused many issues.)
* Bug Fixes:
 * (r270) Export strings with a pipe character should now work properly
 * (r271) Temporary fix for failed assertion when calling Parser:SetSpellByID(109388)
 * (r272) Multi-state cooldowns will now reflect the spell being displayed in their %s variable (bindings/text output).
 * (r273) The slot settings for Wild Mushroom icons and other totem icon variants can once again be configured without error.
 * (r276) Fixed a breaking typo in the enUS locale file.
 * (r281) TellMeWhen/Types/dr.lua:182 table index is nil
 * (r282) Pet talent tree localization was incorrect for some languages due to my crafty attempts to be crafty
 * (r290) Blank icons will no longer be erroneously added to the copy dropdown.

## v4.6.3
* Bug Fixes:
 * (r268) The button to reset icons should now work properly

## v4.6.2
* Item cooldowns now have their own icon type.
* Added text substitutions for unit and spell names.
* Stack and binding texts are much more customizable now.
* Two icon events have been added:
 * On Unit Changed - fires when the unit for which information is being displayed on the icon changes. Only applicable to icon types that check units.
 * On Spell Changed - fires when the spell/item/etc for which information is being displayed on the icon changes.
* You can now change the frame strata of groups under the position tab of the group settings.
* Added import/export boxes/dropdowns to the group settings and profile settings.
* Bug Fixes:
 * (r257) Fixed warnings for missing durations (they weren't showing up)
 * (r260) The list of chat frames that can be outputted to should now list all valid frames, shown or not.
 * (r261) The "Check Activation Overlay" setting for reactive icons should now function properly for spells entered as names.

## v4.6.1
* Bug Fixes:
 * (r252) Removed spam when pasting a corrupt string
 * (r252) Importing very old strings should now work. (Very old means pre-v4.1.4)
 * (r253) TellMeWhen_Options/TellMeWhen_Options.lua:2246: attempt to index global "current" (a nil value)
 * (r254) Changes in haste percentage without changes in haste rating will now be properly reflected in conditions (Tickets 303, 304)
 * (r255) Warnings should no longer incorrectly show for missing durations for icon types that do not require them

## v4.6.0
* You can now import and export entire groups or entire profiles.
* You can now import settings from a backup created when TellMeWhen_Options loads.
* Cleaned up the import/export UI area.
* Internal Cooldown icons can now be triggered by a summon event (for the healing priest t12 4pc bonus).
* Spell Cast conditions can now match a name.
* Chat channels are now a valid text output destination.
* Bug Fixes:
 * (r242) 1x AceConfigDialog-3.0/AceConfigDialog-3.0-54.lua:803: attempt to index field "rootframe" (a nil value)
 * (r245) Fixed an error 132 crash in 4.3 when using the "Finish Caching Now" button
 * (r246) Fixed conditions for 4.3
 * (r247) Temporary compatibility code to make the options function fully, with the exception of import/export functionality, until AceSerializer gets fixed.
 * (r250) Removed print spam when sending comm

## v4.5.7
* Bug Fixes:
 * (r235) TellMeWhen_Options-4.5.6.lua:1690 attempt to index field "IgnoreRunes" (a nil value)
 * (r236) Dispel types should now always function properly

## v4.5.6
* Moved the default icon type into its own type file, because it technically is nothing more than another icon type.
* Added clarification for icon types that will accept no name to check everything.
* Added a help popup for the stop watch icon.
* You can now right-click an entry in the suggestion list to insert the opposite type of what is being typed in.
* The option "Show timer text" no longer requires that "Show timer" be enabled. It does still require OmniCC, though.
* Bug Fixes:
 * (r219) Implemented a method to determine if an export string has become corrupt due to the source's formatting
 * (r220) Fixed overlay bar frame levels
 * (r226) Dispel types should now work regardless of capitalization
 * (r230) Fixed overlapping checkboxes, and completely revamped the way that the left column in the icon editor works to prevent this from ever occurring again.
 * (r231) Fixed missing settings caused by the left-column overhaul
 * (r232) Meta icons now inherit timer settings properly
 * (r233) Fixed some deadly recursion

## v4.5.5
* Added Brazilian Portuguese localization file. Translators wanted!
* Implemented a method of determining of an import string has become corrupt by using WikiCreole formatting on Curse (and then fix it if it has been).
* Bug Fixes:
 * (r213) The cooldown bar offset editbox now uses TellMeWhen_TimeEditBoxTemplate (and on a related note, huge time strings will now format to the year level for fun)

## v4.5.4
* New icon type: Rune Cooldown. Does what you would expect it to do.
* Re-implemented the "Only in Combat" option for groups (since it is such a common option, having it only as a condition is a bit tricky for new users to figure out).
* Bug Fixes:
 * (r210) Fixed frame levels that I broke in the last revision of 4.5.3.

## v4.5.3
* Improved configurations for units. Leaving the red '#' in will now default the unit to its full range, and there is now a tooltip showing all units being checked when holding down a modifier key, similar to the name editbox.
* Added a new option to condition icons: "Only show if timer is active". If enabled, forces the icon to be hidden if there is not an active timer on the icon.
* Updated Masque/ButtonFacade code again.
* Bug Fixes:
 * (r196) I accidentally commented out the fix for the error 132 crash. Oops.
 * (r196) Updated for Masque r366
 * (r197) TellMeWhen_Options-r196.lua:3863: attempt to index global "info" (a nil value)
 * (r198) Updated bar edge offsets for Masque r366+
 * (r199) TellMeWhen.lua:1404: attempt to index field 'Font' (a nil value)
 * (r201) The suggestion list will now update its display when new item information is obtained from the server
 * (r203) TellMeWhen_Options.lua:2432: attempt to concatenate local "name" (a nil value)
 * (r204) Invalid itemIDs are now checked and purged from the cache when a new version of WoW is detected
 * (r205) Spell durations are now removed from item cooldown name data when it is parsed
 * (r206) The group settings interface will now longer incorrectly show in the icon editor after moving a group if the group settings tab is not selected
 * (r208) Loading an icon into the icon editor from a different group than the previously loaded icon while the Group Settings tab is selected will now cause the new icon's group to be loaded in the Group Settings tab


## v4.5.2
* Added "%m" as a text substitution for the name of the unit that you are currently mousing over.
* Existing substitutions "%t" and "%f" now work in all output locations.
* The change made in 4.5.0 to reactive icons and conditions has been made optional. Those checking abilities such as raging blow or execute should probably enable this option.
* Parenthesis in the condition editor are prettier now
* Tooltip scan conditions now use the new return values of UnitAura added in WoW 4.2, and have been appropriately renamed to "Aura Variable". The result is an increase in efficiency at the cost of a bit of accuracy in some obscure cases.
* Spell caching and filtering is now between 1500% and 2000% faster. (Seriously.)
* New Conditions:
 * GCD active
 * Unit Threat - Scaled
 * Unit Threat - Raw
* Bug Fixes:
 * (r192) Put the final nail in the coffin of the cooldown clock framelevel bug.

## v4.5.1
* You can now shift-click links into the Announcement EditBox.
* You can now shift-click links into the Choose Name/ID EditBox to insert a spellID/itemID.
* Suggesting a spellID is now about 75% more efficient.
* New text output locations:
 * Smart Channel
 * Chat Frame
* Bug Fixes:
 * (r178) The "Ignore Runes" setting should no longer appear for item cooldown icons
 * (r179) Meta icons should now inherit icon properties from other icons a little better.
 * (r181) Attempted a possible fix to the error 132s that some people are getting when they close the icon editor after viewing the group settings tab.
 * (r182) ICD icons should now properly use the failed duration alpha setting when the duration requirements fail.
 * (r183) Fixed texture alignment in the spell breakdown tooltip that appears when hovering over the choose name/ID editbox with a modifier key pressed.

## v4.5.0
* Fully integrated main addon settings/group settings into the icon editor.
* You can now set custom text to be displayed where a keybinding would normally be displayed in order to remind you of your keybindings directly on TMW icons.
* Moving/resizing a group that is anchored to a frame other than UIParent will adjust the offsets instead of resetting the anchor to UIParent.
* Reactive icons and conditions should now more accurately reflect the state of the abilities that they are checking.
* Greatly increased the versatility and customizability of condition icons.
* Improved rune cooldown detection.
* Version warnings should be slightly less annoying.
* Added monochrome as a font outline option.
* Buff/debuff icons can now display the first number found in the tooltip of the aura that has been found on the icon.
* New icon events:
 * On Alpha Increase
 * On Alpha Decrease
* New Conditions:
 * Buff/Debuff - Tooltip Scan
 * Points in talent
* Bug Fixes:
 * (r164) Tooltip scan conditions should now properly function with spellID input
 * (r170) TellMeWhen_Options-r169.lua:215: attempt to index field "?" (a nil value)
 * (r170) TellMeWhen_Options-r169.lua:1674: attempt to index field "?" (a nil value)

## v4.4.6
* Bug Fixes:
 * (r151) conditions.lua line 319: attempt to perform arithmetic on local 'start' (a nil value)

## v4.4.4
* Bug Fixes:
 * (r145) Totem icons now work for mushrooms/DK ghouls
 * (r146) Unit cooldown icons now properly sort
 * (r146) Fixed an extremely frustrating and elusive bug that was making it impossible to stop moving a group after you started dragging either a spell cooldown or reactive icon that was either checking an ability that was entered by spell name (IDs were fine) that the current character did not have in his/her spellbook, or checking nothing at all.
 * (r149) TellMeWhen/TellMeWhen-r147.lua:1136: attempt to index local "icon" (a nil value)

## v4.4.3
* You can now specify a custom texture to be used for an icon.
* Added whisper as a text output destination.
* Shuffled around some framelevels in hopes of fixing the timer bug.
* Attempted to force cooldowns to reset upon entering an arena. (UNTESTED)
* Added a dialog to warn users of the dangers of configuration mode.
* New Conditions:
 * Pet attack mode
 * Spell cooldown duration comparison
 * Item Cooldown duration comparison
 * Buff duration comparison
 * Debuff duration comparison
* Bug Fixes:
 * (r133) attempt to compare number with nil (In spell cooldown conditions)
 * (r133) conditions.lua:1009: Usage: GetTalentTabInfo(tabIndex[, isInspect[, isPet[, groupIndex]]])
 * (r136) TellMeWhen-4.4.3.lua:1630: attempt to index field "Font" (a nil value)
 * (r137) TellMeWhen_Options.lua:4038: attempt to index global "groups" (a nil value)
 * (r140) Icon's OnHide events should now properly fire when Always Hide is checked.
 * (r142) Using equivalencies with the new duration syntax should now cause the duration to be applied to all spells in the equivalency.
 * (r142) Fixed item textures in config mode.

## v4.4.2
* Misc. updates.

## v4.4.1
* New Condition: Spell autocasting
* New Condition: Tracking active
* New option for buff icons (mage only): Only stealable.
* Added a toggle to DR icons to help work around the buggy spell refresh behavior.
* Greatly improved config mode texture detection.
* Added Wing Clip to the slowed equivalency.
* Bug Fixes:
 * (r124) Inserting an equivalency via the dropdown should now properly save the text in the editbox.

## v4.4.0
* Dramatically changed the way that Unit Cooldown and Internal Cooldown icons handle durations. Durations are now defined per spell within an icon, instead of having the same duration for all spells within an icon. More information is available by choosing one of these types in-game.
* Added some custom sounds.
* Auto shot cooldown icons merged with normal cooldown icons.
* New debuff equivalency: Slowed
* The suggester now does its scan in about 30ms, down from about 200ms.
* Unit cooldown icons now listen for abilities that reset cooldowns and properly do so when they occur.
* Unit cooldown icons checking pvp trinkets should now show an actual pvp trinket texture.
* New Conditions:
 * Unit is Unit
 * Unit Role
 * Macro conditional
* Bug Fixes:
 * Groups that are anchored to frames that aren't created when their parent addon is loaded should now update their position once the frame that the group is anchored to is created.
 * Buffs with one stack were not obeying stack conditionals. This has been fixed.
 * (r117) icd.lua:115: attempt to perform arithmetic on local "ICDStartTime" (a nil value)
 * (r118) (Conditions) attempt to call global "GetRaidTargetIndex" (a nil value)
 * (r119) unitcooldown.lua:328: attempt to index upvalue "db" (a nil value)
 * (r119) Fixed a bug that was causing unitcooldowns/icd icons that use spellIDs to not work.

## v4.3.0
* New icon type: Diminishing Returns. Guess what this one tracks?
* New icon type: Cooldown - Auto Shot.
* The suggestion list just got a hell of a lot smarter.
* Stack text settings are now set by group.
* Significantly increased the efficiency of the icon setup process. If you have a large number of icons, you will almost certainly notice a difference.
* Export strings are a little prettier when pasted.
* Text outputs to addons can now specify the color and font size of the message.
* Power bars for spells that use holy power should always use a max value of 3.
* Bug Fixes:
 * (r99) buff.lua:87 attempt to perform arithmetic on upvalue 'UPD_INTV' (a nil value) //Not reproduced, but the fix should work//
 * (r99) TellMeWhen.lua:1039 bad argument #1 to 'pairs' (table expected, got nil)
 * (r99) Meta icons should now always inherit the proper power bar color, and icons with power bars that are checking spells/abilities with different power types (druids) should reflect this in the color.
 * (r100) TellMeWhen-4.2.1.2.lua:2115 attempt to perform arithmetic on local "start" (a nil value)
 * (r101) Condition icons should no longer be black when shown through a meta icon.
 * (r101) DR icons should properly function when a spell is reapplied within the last few seconds of the DR cooldown.
 * (r102) Buff/debuff icons that are checking multiple units with a sort method enabled should now function properly.

## v4.2.1.2
* Fixed: meta.lua line 80: bad argument #1 to 'tinsert' (table expected, got nil)

## v4.2.1.1
* Fixed a bug that was breaking meta icons until config mode was toggled on and off at least once after logging in.

## v4.2.1
* Unit cooldowns can now be sorted by duration.
* Buffs/debuffs that are being sorted by duration now do so across all units that are being checked instead of only within each unit.
* Internal Cooldown icons now have the option to not reset their cooldown to full duration if they are triggered while cooling down (mainly for the Early Frost mage talent).
* Updated COMBAT_LOG_EVENT_UNFILTERED for 4.2.
* When right-click-dragging icons to move them or swap them, any meta icons or icon shown conditions will now update to reflect that change.
* Further categorized the ever-expanding condition type dropdown.
* Some conditions that check a duration now allow a smaller increment of time to be specified.
* Some conditions that had high maximum values now adjust their min/max based on the current value, allowing finer tuning with a higher (infinite) maximum.
* Many icon types had their CPU efficiency increased.
* Added the following text output destinations:
 * Grayhoof's Scrolling Combat Text
 * mikord's MikScrollingBattleText
 * ckknight's Parrot
* New Conditions:
 * Buff/Debuff - Number of - This conditions tracks the number of a buff or debuff that are active on a unit. This is not the number of stacks, but rather the actual number of auras (3 warlocks in your raid cast 3 corruptions, etc.).
* Bug fixes:
 * The "On Show" icon event should no longer erroneously trigger sometimes when changing zones.
 * Item cooldown icons use item names instead of IDs that attempt to set themselves up before the required data is available will now attempt to fix themselves once that data becomes available instead of requiring a full lock toggle.
 * Icon settings are now resetting to the defaults in a more correct manner before icons are copied onto them.
 * The suggestion list should now properly update to the current cursor position instead of the last cursor position when clicked.
 * The suggestion list should now take an entire entry into consideration if the cursor is clicked on the middle of it.

## v4.2.0
* New feature: Announcements. This allows you to announce something to WoW's chat (say, yell, party, raid, guild, emote, etc) when icon events are triggered (the same events that sounds already use).
* The equivalency dropdown no longer gives you a headache when you look at it (It is now sorted alphabetically).
* Fake hidden has been renamed to "Always Hide." The old functionality persists.
* I spellchecked all of the English texts!
* Added Ardent Defender to the defensive buff equivalency
* Bug Fixes:
 * (r80) Fixed error: conditions.lua:276: attempt to perform arithmetic on local "start" (a nil value)
 * (r81) Hopefully put the final nail in the coffin of the Masque ugly texture crap.
 * (r82) Last minute changes without testing are bad, mmmkay? (Announcements actually work now.)
 * (r83) Sounds for event "On Finish" should now work a little better.
 * (r84) Jinx: CoE is now properly checked as part of the spell damage taken equivalency.

## v4.1.4.2
* Bugfix: TellMeWhen.lua:620: attempt to compare string with number
* Bugfix: v4.1.4s internal version number was about 40,000 higher than it should have been. Whoops!

## v4.1.4
* New profiles now default to only one group instead of ten, and new/reset groups now place themselves in the center of the screen.
* **IMPORTANT**: Because of the above change, there is a (very very small) chance that some of your groups moved. I apologize for the inconvenience. If you find that a group has been moved off the screen, type /tmw options, go to that group's config, and click the button to reset the group's position.
* You can now import and export icons in string format to other users of TMW, meaning that you can share them outside of the game or to players that you are not able to whisper.
* Imported icons will now be upgraded as needed to fully function with your current version of TMW. Icons received from newer versions of TMW that your current version may still have an occasional error, so please always ensure that you are upgraded to the latest version of TMW before reporting an error with importing.
* New/changed conditions:
 * Unit Classification (Normal, Elite, Rare, Rare-Elite, World Boss)
 * Currencies
 * Lua conditions no longer require you define functions/variables in TMW.CNDT.Env, as the _index metamethod is set to _G if you are using a Lua condition.

## v4.1.3
* Conditions can now be set by group
 * IMPORTANT: Group combat, vehicle, and stance settings have migrated to conditions instead of being settings that are defined in the group options
 * The old dual spec and talent tree settings remain as a way to prevent groups in the same spot that serve different purposes from being displayed during config when not needed.
* New/changed conditions:
 * Stance conditions now allow an operator to be specified. Less/greater than operators are relative to the stance's position on the slider.
 * Unit controlling vehicle
* Buff/debuff icons now have the option to sort the auras that they find by duration.
* Spell caching will not begin until the icon editor is opened. You can have a few framerates back.
* Bug Fixes:
 * Unit cooldown icons should now have the condition alpha option, and subsequently, conditions will actually work with them.
 * (r66) TMW will still function upon updating ButtonFacade to Masque, but skinning buttons will not. This is only temporary while I sort out the changes with Masque.
 * (r67) Fixed an infinite recursion when meta icons accidentally get looped (1 checks 2, 2 checks 3, 3 checks 1) and one of them has the 'Check sub-metas' option enabled.
 * (r67) TMW should now be compatible with Masque (and still compatible with ButtonFacade too)

## v4.1.2
* You can now 'group' conditions together with parenthesis. If you have any suggestions on how to make the GUI for it look better, please let me know.
* Implemented the suggestion list for conditions that take spell/item inputs.
* New/changed conditions:
 * Buff/Debuff conditions now have a checkbox to specify whether to only check for your auras, or any auras.
 * Buff/Debuff duration conditions now treat infinite duration auras as having an infinite duration (greater than the maximum specifiable time of 10 minutes) instead of having a duration of 0 (absent)
 * Totems 1-4 (only shown if applicable to current class)
 * Spell in range of unit
 * Item in range of unit
 * Spell usable (mana, rage, energy, etc)
 * Lua (Advanced)
* Bug fixes:
 * Error fix: TellMeWhen_Options.lua:2431: attempt to index field '?' (a nil value)
 * Fixed the bug with moonfire debuff tracking in 4.1
 * Fixed a bug with unit level conditions (attempt to compare number with string)
 * Added better checking for invalid parenthesis in conditions.

## v4.1.1
* New Condition: Unit Class
* Fixed frame level issues in the meta editor

## v4.1.0
* Implemented sounds! It should be mostly functional, but if you find anything that is breaking or not working how it probably should, open a ticket.
* Reduced CPU usage by about 20%.
* Alpha can now be customized for when conditions fail, or for when duration/stack requirements are not met.
* Made the meta icon editor much prettier.
* New/changed conditions:
 * Old Buff/Debuff conditions changed to Buff/Debuff Stacks
 * Buff duration
 * Debuff duration
 * Cooldown and weapon enchant conditions now allow you to specify a duration
* Fixes since the first revision of this version:
 * (r52) Fixed the alpha on unusable reactive icons
 * (r52) Fixed a bug where icons that were set to fake hidden would sometimes still show after leaving config
 * (r52) Fixed stack text on buff icons
 * (r53) Fixed: conditions.lua line 1220: bad argument #1 to 'gsub' (string expected, got nil)
 * (r53) Fixed: TellMeWhen_Options.lua:2217: attempt to index field '?' (a nil value)
 * (r54) Fixed the "Check sub-metas" toggle for meta icons - accidentally broke the anchor for it
 * (r54) Meta icons should obey conditions
 * (r55) Cooldowns on meta icons should properly set when the meta changes to from an icon with an active timer to one without, and then back to the first icon that has an active timer.

## v4.0.4
* Maybe fixed a really rare frame level bug with cooldowns?
* Stance conditions work now.
* Fixed debuff conditions.
* Began redesigning the condition editor to make room for the options to 'group' sets of conditions with parenthesis.
* Fixed a rare error in condition processing.
* Fixed the "only if equipped" option for item cooldowns for the 453rd time. Why don't I just leave it alone now?

## v4.0.3
* For purposes of duration requirements, buffs/debuffs with an infinite duration are now considered to have a duration of 0, instead of completely ignoring this feature.
* Meta icons now inherit the "Normal" color of the icon it is showing if you are using ButtonFacade.
* Enhanced the overall appearance of icons in config mode. The "blank" icon texture will not appear unless you completely restart WoW.
* New icon type: Condition Icon. This icon type is for simply checking the state of a condition. The icon can be set to a specific spell texture or texture path via the name editbox.
* A few random bugfixes

## v4.0.2
* Moar efficient!
* Ignore GCD settings are now on by default now. This shouldn't affect you if you manually disabled these options.
* ICD icons now refresh when a stack of a buff is added.
* Fixed the version warnings that were spamming people and telling them that you sent them an icon
* Groups that are anchored to other groups with higher groupIDs should now properly anchor after logging in or reloading
* Many old spell equivalencies were updated, and some new ones were added, thanks to Catok of Curse.

## v4.0.1.4
* Fixed all the errors. Sorry, guys!
* Fixed totem icons
* Fixed icon shown conditions

## v4.0.1.3
* Dispel types should now properly work for icons that surpass the efficiency threshold
* Internal cooldowns will show the proper icon during config in WoW 4.1+
* Textures should properly update when changing the name of an icon that remembers the previous texture (buff/debuff, icd, and others)
* Weapon enchant icons should now properly obey the setting to be hidden when the slot is empty
* Maybe fixed a really rare frame level bug with cooldowns?

## v4.0.1.2
* Groups and icons should now properly copy using the dropdown on the icon editor
* Added some tooltips to icon types
* Added some more name substitutions to equivalencies (so they will accept any spell named "Hex" instead of just the shaman's hex spell, etc)

## v4.0.1.1
* Cleaned up the condition editor

## v4.0.1 beta
* **IMPORTANT**: Instead of typing "raid" for units raid1 through raid25, you now must type "raid1-25". This will allow for much more flexibility, e.g. raid1-10.
* More Efficiency! Yayyy! (New stuff, plus a fix to a bug in the icon engine that was making it check every single icon, even when they were hidden)
* New option for icon cooldowns: Only if in bags. (Note that this is forcibly checked if 'Only if equipped' is checked, and an item that is equipped is considered to be in your bags.
* Fixed a bunch of things that were broken (sorry for being vague)
* Many conditions! Now, handle them!
* Fixed an issue with cooldowns looking bad on circular LBF skins
* Overlay bars now go underneath the border of LBF skins
* Bars and timers will be set to ignore GCD in this version. You will need to toggle this off if you don't want it. (Sorry, i screwed something up in beta 9)
* Fixed a bug that caused icons that shouldn't be shown to not be hidden when switching profiles or removing rows/columns.
* Textures should properly reset when switching profiles.
* Switched to SVN instead of manual file uploads, yay!
* New feature: Suggestion list. The suggestion list will take what you type and search though all known spells/items, as well as TMW equivalencies and dispel types, to suggest what you might be looking for. For example, if you are configuring a "Spell Cast" icon type, the list will show only spells with cast times, as well as the cast equivalencies. More information regarding this feature will be in the documentation that I will hopefully start writing soon. (If someone wants to help me out with that, send me a PM)
* Equivalencies are no longer case-sensitive.
* Reverted failed experimentation to force spell casts to match spellIDs
* Colors on the suggestion list should now be final (known player auras are now shown with a different color than known NPC auras - if you installed the first version of 4.0.1 beta, you may see a few wrong spells, but they will be updated the next time you see them)
* Fixed the tooltip that appears whilst you mouseover the name editbox in the icon editor with shift held down
* Fixed a missing translation
* Reset your aura cache to remove incorrect entires that were put in prior to version 4.0.1 beta 3
* Spell cast conditions now allow you to specify if the cast must be interruptible.
* Icon dropdowns for meta icons and icon shown conditions now divide the icons up by group (fix for too many icons syndrome, and to make it easier to find the one you need)

## v4.0.0 beta 9
* Actually added mainassist and maintank to the unit dropdowns.
* Fixed an obscure error caused by casts with no start time (this happened on Al'Akir, and only for a split second)
* Made it impossible for the addon to destroy your settings when upgrading to beta 8 from a version older than 3.0.0 after you had already upgraded one character's settings. (This wasn't happening anyway because a restart is absolutely required when upgrading to beta 8 from any version)
* Fixed an error that was causing Kong UI Hider to break with TMW installed and at least one group enabled.

## v4.0.0 beta 8
* New condition: Resting.
* New condition: Encounter Resource, for tracking the level of encounter-specific 'resources' like corruption on Cho'gall and sound on Atramedes.
* New condition: Talent Tree, for specifying what talent tree must be active.
* New conditions: Unit speed/unit run speed, for checking the current movement speed/max run speed of your target.
* Toggling the 'Ignore Runes' setting should now properly toggle the 'Ignore Runes' setting.
* Rune conditions should now properly save.
* Merged the glaringly empty alpha/stacks/duration tab with the main tab.
* The option for item cooldowns to only show if equipped is back now. Oops.
* Fixed the bug that was causing icons to occasionally hide their texture in config mode.
* Item cooldowns that use slotIDs should now work a little better.
* Conditions and each icon type have been split off into their own file, so a complete restart of WoW will be needed when upgrading to this version.
* Conditions now generate their own, single function instead of chaining a bunch of functions. They also make use of Lua's short-circuit evaluation capabilities in order to become more efficient (instead of the old way that checked EVERYTHING)
* You can now define what talent trees must be active in order to show a group.
* Fixed an error that was being caused by interference from Tukui.
* "mainassist#" and "maintank#" are now valid units for TMW. Their implementation is a little unorthodox though, so the order of them is not guaranteed compared to be the same as the order in your unit frames if your unit frames display these units.
* Added compatibility for the changes made to CLEU and pet happiness in WoW 4.1.0.
* You can now specify which totem slots to check for totem icons, and it should now be more clear what this icon type can be used for (Totems, Non-MoG ghoul, Wild Mushrooms)
* Implemented a much more elegant method of generating group settings.

## v4.0.0 beta 7
* Replaced the checkbox system in the condition editor with a simpler add/remove button, and added buttons to move conditions up or down.
* Fixed a bug that was breaking multi-state cooldown icons that used spell names.

## v4.0.0 beta 6
* Made some efficiency improvements in the area of timers and bars; be on the lookout for things that shouldn't be happening.
* Fixed inverted bars in several cases.
* Buff icons now show the power bar of whatever icon is currently shown (only matters if you were checking multiple buffs with different costs).
* The first icon of a meta icon can now be deleted if there are 2 or more total, and you can now insert another icon before the first icon.
* Conditions should now properly save, but be on the lookout for strange things happening.
* Fixed an error caused by meta icons checking invalid icons.
* Fixed an error that was breaking totem icons.
* Weapon enchants now allow you to specify specific weapon enchants (put the name that is displayed in the item's tooltip into the editbox; separate multiple enchants with ';').
* Weapon enchant icons should now have much more functional timers displayed on them.
* Weapon enchant icons now support cooldown bars.
* Totem and weapon enchant icons now reverse their timers (so they wipe the bright part away rather than wiping the dark part away).

## v4.0.0 beta 5
* You will now be alerted when a guild member logs on with a version of TMW that is newer than yours.
* Unit cooldown icons should properly obey 'Only if seen' when using spellIDs.

## v4.0.0 beta 4
* Rewrote the entire icon core, kinda. It could be cleaner, but at least its more efficient.
* Many things are now cached instead of being remade every time, resulting in a reduction of garbage generation by about 1300% (yes, really)
* Enraged has been added as a dispel type, but it is not truly a dispel type like magic and poison are, just a big list of every known enrage (from http://db.mmo-champion.com/spells/?dispel_type=9)
* The Reset all button in the options should now update all icons.
* The CPU efficiency of all icons has increased by a bit.
* You can now send icons to other players that are using this version of TMW or later, and obviously you can receive icons from other players too.
* New condition: Group type.
* When checking a high number of buffs/debuffs (this threshold can be customized), a more efficient method of checking them will be used.
* Choosing "Icon Type" in the icon type dropdown should now properly change the type to none rather than changing it to a meta icon.
* The multi-state cooldown icon type has been merged with the normal cooldown icon type.
* Removed an incorrect line from the tooltip for unit cooldown icons.
* Added trap launcher frost trap to the CrowdControl preset.
* Added a resize tick to the icon editor, and removed the editor scale setting from the options in favor of this resize method.

## v4.0.0 beta 3
* Reactive icons should now properly dim when unusable and set to always show
* Cooldown and reactive icons should now hide when checking an invalid spell (spellIDs are ALWAYS valid, names of spells you haven't learned (or pet spells if you toggle config mode without your pet out) aren't)
* TellMeWhen's options are now a separate addon. You will need to completely restart WoW when upgrading past this version if you want to configure anything.
* Fixed the ButtonFacade callback that I broke for some reason.
* Fixed an error in upgrading from old versions (actually, I just removed that upgrade entirely).
* Changed max stack and duration defaults to 10 instead of 50 and 100, respectfully.
* Conditions now save immediately upon any change made to them, instead of only when closing or reloading the icon editor.
* The tooltip over the name dialog that appears when you hold down a modifier key should now properly only attempt to get item names if the icon is an item cooldown icon.

## v4.0.0 beta 2
* Pet abilities can now be dragged onto an icon.
* Ignore Runes should no longer appear as an option for reactive icons for non-DKs.
* The icon editor should display the proper settings for each icon type instead of always meta icon settings.

## v4.0.0 beta 1
* Well, that was a quick jump from 3.0 to 4.0
* New icon type: Unit cooldown. This icon type will allow you to track the cooldown of any spell of any valid unit, provided that you specify the cooldown length. Instant casts and channeled spells are guaranteed 99.9% accurate, but spells with cast times that either apply a buff/debuff or do direct damage/healing can be off by about +- 1 second because of travel time.
* Completely revamped icon configuration. Gone is the dropdown, in is a dialog that combines all of the old dialogs (4 of them) into one. This will pave the way for many more useful settings, like some of the ones below.
* Any icon type that can check units (buff/debuff, unit cooldown) can now check multiple units.
* Overlay bars can now have a custom offset defined in order to show a value that is higher/lower than the actual value.
* New option for meta icons: 'Check sub-metas'. When meta icon 1 is checking meta icon 2, meta icon 1 will show an icon that meta icon 2 did not show if it gets that far down the list without finding one to show.
* New option for reactive icons: 'Check activation border'. When checked, the spell will be considered usable whenever the spell activation overlay in your action bars is active on the ability. (Not the pet auto-cast marching ants)
* New option for item cooldowns: 'Only if equipped'. When checked, the icon will only show if the item is equipped.
* New condition: 'Instance type'. Allows you to specify an instance type that you must be in (with operators, so greater than or equal to 10 player raid is basically any raid).
* New condition: 'Swimming'. Checks if you are swimming or not
* New condition: 'Mounted'. Checks if you are mounted or not
* Icon spacing is now defined per group.
* You can now manually define the anchors, offsets, scale, and frame level of a group. You can also lock the group, preventing any movement or resizing by click-and-drag (recommended if you want to keep it anchored to the top of your raid frames, or something else that moves dynamically).
* You can now disable the warning that is printed to chat when a meta icon or a condition is checking an invalid icon.
* You can now right-click-and-drag an icon to another icon slot in order to move or copy it.
* You can now drag a spell from your spellbook or an item from your bags/character sheet onto an icon to quickly set it up. If an icon is already configured, the name will be appended to the end of the list of names.
* All icon types except multi-state cooldown icons now accept multiple spells/items.
* Chakra states are no longer supported by reactive or cooldown icons. Use a multi-state cooldown icon in order to track chakra states from now on.
* ICD icons now check for energize effects (mana/rage/energy/etc gains).
* Custom alpha levels for failed conditions/stacks/durations have been removed. They were causing several problems that were limiting some features.
* Fix several buff equivalencies (Feared, Stunned, Disoriented, Silenced, Rooted).
* Spell names should now always check in the correct order.
* The flickering timer issue should be gone for good now.

## v3.0.4a
* Hide rune condition configuration properly

## v3.0.4
* Timers should now properly hide on buff icons with no time remaining (absent, or infinite duration)
* Consequently, meta icons that include buff icons shouldn't be dim all the time.
* Let's hide cooldown icons with invalid names.
* New condition: Runes. You can select the runes that you require to be available for the icon to show.

## v3.0.3
* Lets make ignore runes actually have a setting in the menu.
* Added boss 1-4 to units.

## v3.0.2c
* Fix item cooldowns. Oops!

## v3.0.2b
* Apparently UnitGUID("player") returns nil when not accessed sometime after addons have loaded. Lets make ICD icons work for real now.

## v3.0.2a
* Lets properly defining the alpha of ICD icons. It seems to work better when they aren't shown all the time.

## v3.0.2
* Ignore runes is back
* New icon type: Internal cooldown/Spell duration. This can be used to track the internal cooldown of a talent or trinket proc, or to track the duration of a spell such as a hunter trap or mage orb or warlock infernal. More details in the tooltip in the type menu.

## v3.0.1c
* Fixed flickering timers

## v3.0.1b
* Fixed the error that was telling you that you needed a restart even after you have restarted when upgrading directly to 3.0.1a from a pre-3.0.0 version.

## v3.0.1a
* The 'Ignore runes' option for death knights is gone. It was breaking timers for everyone else, and somehow causing other addons to break (CoolLine)
* The tooltip for 'Show timer number' is back!
* Fixed group names in the copy icon/group dropdown

## v3.0.1
* Updated Korean localization.
* You can now rename groups to whatever you want.

## v3.0.0
* Converted the entire settings system to AceDB-3.0. As such, the profile copy features that come along with it have been added to the Blizz interface options.
* You can now copy the position and scale or a group, or an entire group, or any icon from any of your characters (that you have logged in to with this version of TMW or higher) though the icon config dropdown menu.
* Right clicking the LDB plugin now brings up the Blizz interface options for TMW instead of a menu with settings in it.
* All icons now use the update interval that is specified in the Blizz interface options.
* Efficiency increases across the board.
* Overlay bars now have a little better functionality.
* Meta icons now properly inherit stack texts.
* Duration checks actually work for totem icons now.
* Weapon enchant icons that are set to hide when the slot is unequipped should actually do so now when TMW is toggled when the slot is empty.
* Meta icons and 'icon shown' conditions that check weapon enchant icons that are set to hide when the slot is empty should now reflect this.
* Buff/debuff icons now show the texture of the first spell in the name list when they are set to show when absent (or always).
* On a related note, duplicate names in an icon's name list are now eliminated post-user input. This will allow you to do something like "Faerie Fire;ReducedArmor" to show the FF texture when none are present without a performance impact.
* Groups can now be up to 20 rows by 20 columns.
* Groups can no longer be moved off the screen.
* You can now configure a group straight from an icon's dropdown menu.
* You can now have an infinite number of groups. Groups can be added by pressing the "Add another group" button in the Blizz interface options panel.
* You can now delete groups as you please. The groups with groupIDs higher than that of the deleted group will be reassigned a new groupID, and any icons that had condition or meta checks to the shifted groups will automatically be updated.
* You can now customize the position of the stack text on icons.
* And much, much more!

## v2.4.1
* You can now customize the order in which icons are checked for meta icons.
* Cleaned up icon menus (for icon shown conditions, and the new meta icon editor).
* Checking 'Fake Hidden' no longer forces the duration/stacks/condition alpha to zero. If you wish to use an icon in an 'icon shown' condition of another icon and the duration/stacks/conditions of the icon being checked are being checked, then their respective alpha sliders should be manually set to zero.
* New predefined spell sets: spell casts. These can be used in a casting icon to check for common spells that you may wish to be alerted about.
* New condition: Unit in combat.
* The condition editor scroll bar is now hidden if it isn't needed.
* Added a cute little icon to all of the icon dialog windows for a better indicator of what icon you are working with.

## v2.4.0
* Duplicate Spells Names are gone. If you put in a spellID, it will require that spellID be matched.
* The condition editor now uses a scroll frame, and has an infinite number of conditions that do not require the max number to be changed in the interface options panel.
* The group options are now compiled in a much smarter way. This probably won't mean much to you, but I feel really dumb for the old method.
* New group option: hide while controlling vehicle. If checked, the group will be hidden if your action bars have change to that of the vehicle. It will not be hidden if you are a passenger in a vehicle from which you can still attack (although this is being removed from SOtA in 4.0.6 anyway, so it doesn't really matter.
* New icon type: Multi-state CD. This icon type will allow you to properly track the cooldowns of icons with multiple states (Dark Sim, HW: Chastise, etc.) The ability being tracked must be on your action bar.
* New icon type: Cast. Basically a cast bar in a TMW icon. Can be set to only show when a cast is interruptible, and can be shown for any unit.
* New icon type: Meta. This allows you to select any number of other TMW icons and use one icon to show them all. The icon will be hidden if none of them are shown. In addition, icons will still be shown by a meta icon if they have fake hidden enabled.
* New units: Arena (enemies) 1-5, and group members 1-4 (the player is not included in these, party 1 is the first party member)
* Only settings that are relevant are defined for each icon. This should result in a performance increase.
* Cooldowns of 1 second are now always considered to be GCDs

## v2.3.0
* Icons can now check against their duration remaining to determine if they should be shown
* Alpha can be customized for for when duration and stack checks fail
* Redid/combined the alpha/stacks/duration editor
* Fix the bug with TMW not showing up in the Blizz interface options (hopefully)
* Fixed a faulty warning that was telling you to use SpellIDs when switching into a spec which was tracking the cooldown of a talent in that spec
* Slightly improved load times
* Added some missing preset auras

## v2.2.3a
* Added glyph of hemo to Bleeding preset
* Fixed an error that was breaking the interface options panel
* Fixed another error that wasn't really breaking anything, but an error is an error.

## v2.2.3
* Cleaned up the icon copy dialog
* Fixed the encoding of the French localization file
* You can now enter duplicate spell names yourself. This can be accessed in the Blizzard interface options panel under TellMeWhen, or by typing /tmw dsn. Input the spellIDs of any abilities that have the same spell name for different effects. (Hemo bleed damage increase and glyph of hemo bleed are both just called Hemorrhage; wyvern sting sleep and wyvern sting dot are both called Wyvern Sting.
* Slight efficiency increase
* Fix to TexCoords out of range error.

## v2.2.2
* Non-MoG ghoul tracking for DKs should actually work now. Just enter the name as 'Risen Ghoul', or whatever the name of the ghoul is in your locale.
* Stances are only displayed in the interface options menu when you have options to pick.
* New condition: talent spec. You should still use the group talent spec settings, but this will allow you to fine tune it.
* The condition editor continues to become beautiful!

## v2.2.1
* Unit Reaction checks are now a condition; it should convert automatically for you.
* Increased CPU efficiency in many places
* New icon type: Dark Simulacrum (experimental, should work though) (only in the type list for DKs)

## v2.2.0
* Fixed icon shown checks on cooldown icons (they don't rapidly flash anymore)
* Icon shown, unit exists, and unit alive condition checks can now check the converse (icon hidden, unit doesn't exist, unit dead)
* The LDB plugin has its own file now. A restart of WoW will be required to update to this version completely
* The choose name, alpha, and stack dialogs have been remade.
* Buff/debuff icons can now check for dispel types (Magic, Poison, Curse, Disease)
* Buff/debuff icons can now check for buffs and debuffs at the same time. If 'Either' is selected, they will first check as a buff, and if it is not present, then it will check as a debuff.
* The alpha of the icon when the icon's conditions fail can now be customized.
* New predefined aura set: crowd control (Thanks calico0!)

## v2.1.2a
* Back by one man's demand: timers on weapon enchant icons. These are going to remain very dysfunctional until Blizz implements better api get the start time and duration for these, instead of just how long until it expires.

## v2.1.2
* New option to hide temp enchant icons when the slot is empty.

## v2.1.1
* Ranged weapon temp enchant tracking icons should now display your ranged weapon's icon instead of your helmet. lol.
* Weapon enchant icons no longer support timers; this was heavily bugged, and I really don't think anyone used this anyway or they would have complained about how buggy it is.

## v2.1.0b
* New predefined aura set: Fear
* Instead of flooding you with errors when you try and use a spellname for a pet ability, I yell at you and tell you how to fix it.
* Everything else was random things with the code because I was bored.

## v2.1.0a
* Bugfixes

## v2.1.0
* Your settings file should become much, much smaller.
* Icon cooldown now support slot ids (10 for gloves, 6 for belt, 13/14 for trinkets 1,2; etc, http://www.wowpedia.org/InventorySlotId)
* A total reset puts groups where they are supposed to be instead of stacked on top of each other
* Fixed some other minor stuff too, like the encoding of the localization files

## v2.0.4
* The font of the stack text on icons can now be customized
* Implemented a new system to warn you when I screw with your settings

## v2.0.3
* A fix
* Added a condition to check if the specified unit is alive

## v2.0.2
* Added option to adjust icon spacing
* Fix a typo that was causing errors

## v2.0.1
* Localized, but many languages still are missing many translations. Please contribute!
* ButtonFacade Support
* Added a LDB plugin
* Hopefully fixed the bug with the Buff Equivalency menu going up, I split it up into 2 submenus
* Efficiency improvements across the board
* Group options are now created dynamically
* Increased maximum number of groups to 10
* Many new units that can be checked
* New option: Highlight the edge of the cooldown clock animation
* New options: Bars/Cooldown clocks ignore GCD
* New options: More color options, they now have their own page
* Icon Option: Fake Hidden - Use in conjunction with new icon-shown conditions
* Conditions: Many new conditions, condition editor overhauled, number of conditions can now be changed up to 10
* Conditions: Many conditions use real values instead of percentages
* New Feature: Copy icon settings from one icon to another
* New Feature: Option to toggle cooldown checking for reactive icons
* New Feature: Option to toggle the showing of text on timers. Still requires OmniCC
* New Feature: Weapon enchant icons can now check ranged slots

## v2.0.0 beta 8
* BUTTONFACADEOMG
* I think the LDB plugin came with this one too? or maybe that was 7

## v2.0.0 beta 7
* Should be the last

## v2.0.0 beta 6
* New translations
* Some other stuff
* Some things
* Release soon?

## v2.0.0 beta 5
* Probably the last beta release before public release

## v2.0.0 beta 4
* Just a little fix

## v2.0.0 beta 3
* Main purpose of this release was to skip beta 2
* Number of groups and number of conditions is now adjustable
* Many new conditions (2)
* Various improvements
* I finally got around to generating the options table dynamically which is why i made the number of groups adjustable
* I also made the conditions panel generate dynamically which is why i made it configurable too
* Support for poisons on thrown weapons
* New units! Can now check mouseover, mouseovertarget, and vehicle (but who cares about vehicles?)

## v2.0.0 beta 1
* Woah!
* It's Localized! (Kinda)
* Conditions can now check to see if another icon is shown. The possibilities are endless!
* A really big overhaul of conditions in general.
* You can copy icon settings from one icon to another
* More color options! Yay!
* I will put up a better changelog soon.

## v1.5.4
* I screwed up the upgrading of alpha settings. Tried to reverse it in most cases, but it might not work if you had it customized
* Fixed IncreasedStats predefined auras, was missing kings

## v1.5.3
* Added separate alpha settings for usable/present and unusable/absent icons
* Fixed the glitch with hemorrhage/glyph of hemorrhage. If you have any other buffs/debuffs that share a name with something else, let me know and I will add them to the list to check for them.
* Cleaned up a lot of code
* Improved the efficiency of buff/debuff icons even more

## v1.5.2
* Increased efficiency of buff icons
* Predefined aura sets now have a pretty dropdown
* Replaced several of the old predefined spell auras with spellIDs for localization purposes
* Removed two of the old predefined spell auras because I got really sick of converting nearly 200 names to IDs
* Better checks for conditions to make sure that percentages are valid numbers
* Slight improvement to the condition editor frame

## v1.5.1
* Fixed unit reaction checks

## v1.5
* Conditions can now check units other than  yourself
* Conditions can now check for holy power, lunar power, and soul shards
* Added many new buff equivalencies. For now these can be found in TellMeWhen.lua but will get a GUI in the next version.
* Fixed reactive icons that were set to always show (they weren't dimming when unusable)
* Small efficiency increase

## v1.4.9a
* Added option to change the color of the icons when you lack range/power. Range takes priority over power.

## v1.4.9
* Full Chakra/Holy Word support (hopefully). Can either be set as a cooldown or a reactive ability, play around with it to see the difference. Holy word aspire untested because it doesn't exist in beta.

## v1.4.8
* Fixed the cooldown animation for reactive icons
* Ugly,poor support for Holy Words. Use spellIDs for best results

## v1.4.7c
* Why do I always manage to lose a piece of the localization file every time I update the addon?

## v1.4.7b again
* Oops again

## v1.4.7b
* New way to change stack limitations of buffs/debuffs
* Put in condition and range checks for reactive icons. Idk why I didn't do this sooner.

## v1.4.7a
* Fixed the line 1427 error
* Fixed range checking for reactive icons

## v1.4.7 again
* Oops

## v1.4.7
* Added an option to highlight the edge of the cooldown clock animation
* Buff/debuff icons can now specify the minimum/maximum number of stacks required to display the icon.
* Fixed lists of spellIDs not working

## v1.4.6a
* Removed the stupid prints that i accidentally left in
* Implemented Lord Helmchen of WoWInterface's fix for SplitNames

## v1.4.6
* Potential fix for people that have issues with the text that displays the number of stacks of an aura
* The fix for pet cooldown icons should actually work now
* Added option to check for range or not. Being angry at me has a small chance to get something implemented.
* Added option to check for power(mana/rage/energy/focus/runic) or not
* Hopefully fixed the stance checking for all Classes
* Fixed the bug where icons would move when the addon was locked after having their size changed
* Fixed the toggling of the show/hide in combat state of each group

## v1.4.5b
* Fixed stance checks for rogues, shamans, and warriors.

## v1.4.5a
* Added metamorphosis as a stance check
* Fixed pet cooldown icons turning into ? sometimes on loading screens.

## v1.4.5
* Group positions are now saved variables so that groups don't loose their position when logging in without TMW enabled.

## v1.4.4
* Added cooldown/duration bar coloring options to the main TellMeWhen options in the interface options panel.

## v1.4.3b
* Fixed SetTexCoord in a few places that got broken in 1.4.2a

## v1.4.3a
* Fixed the ugly memory leak
* Also greatly reduced CPU usage in the process

## v1.4.3
* Added stance checking per group. This can be configured in the group options in the interface options panel.

## v1.4.2a
* Fixed the frame level of the cooldown clock (It should now be under the overlay bars if they are displayed)
* Fixed power bars for druids (It was checking energy if you were in cat form, even if the spell required mana)

## v1.4.2
* Multiple spells in a single icon really should be fixed once and for all now.
* If you input an spellID, TMW will now use that spellID for everything that it can (range checks have to use the name). This means that swipe is fixed, just make sure and put in the spellID.
* Fixed the flickering issue with reactive buttons

## v1.4.1
* Hopefully fix the issue with buff icons not accepting multiple spells

## v1.3.3
* Added unit reaction checks for cooldown and buff/debuff checks
* Fixed overlay bars being broken for only-in-combat icon groups

## v1.3.2a
* Revert show/hide checks to their original state before I started messing with them.

## v1.3.2
* Added bars to Buff/Debuff and reactive icons.
* Fixed show states for cooldown, buff/debuff, and reactive icons (hopefully)
* Fixed Item cooldowns

## v1.3.1a
* Removed a call to an function that was part of the old config UI

## v1.3.1
* The interface options configuration now uses Ace3 for a much cleaner and more functional look
* Embedded libraries and fixed the order in which they were registered (Oops!)
* Cooldown bars can now be shown for Item Cooldowns.

## v1.3
* Added overlay bars for resources(energy, focus, rage, mana) and cooldowns.
* Consolidated the interface options.

## v1.2.5b
* Fixed GCD spells, thanks to Oisteink.

* Fixed Swipe for druids.

## v1.2.4
* Various bug fixes
* Added 'ShowTimer' option for Reactive abilities (thanks to Jabborwok)

* Big thanks to Predeter of Proudmoore for:
 * Added support for multiple Auras in the same icon via semicolon ; separated lists.
 * Added Buff equivalencies for groups of spells with similar effects. Use the following groups (capitalization matters just like with everything else):
  * Bleeding
  * VulnerableToBleed
  * Incapacitated
  * StunnedOrIncapacitated
  * Stunned
  * DontMelee
  * ImmunToStun
  * ImmuneToMagicCC
  * FaerieFires

## v1.2.3
* Initial fix for bug where icons blink off during GCD

## v1.2.2
* Updated for 3.3.2
* timers on buffs should now reset properly when switching targets or looking at a dead target.

## v1.2.1
* Fixed Buffs not showing properly in patch 3.3

## v1.2.0
* Added options for targetoffocus and targetofpet
* Added "/tmw options" as a shortcut to options menu
* (Major thanks to Oodyboo for the following changes)
 * Changed how spec settings are saved
 * EditBox for "Choose spell/buff/item" retains previous entered value
 * Supports 8 bars instead of the old 4
 * Added primary/secondary spec toggles for each bar
 * Disabled bars and icons don't process everything

## v1.1.6
* Fixed a bug where pets caused an endless stream of error messages when dismissed/killed
* Fixed a bug where Buff/Debuff set to "Show when Absent" was acting as it was set to "Always Visible"

## v1.1.5
* Updated for 3.2
* Changed Interface and Version numbers in TOC
* Buffs/Debuffs set to Always Visible now indicates if they are missing
* Icon textures should update correctly now

## v1.1.4
* Dual Spec Support

## v1.1.3
* Rewrote Buff checks to use UNIT_AURA instead of COMBAT_LOG_EVENT_UNFILTERED.
* Removed a bunch of variables that was created, but not used.

## v1.1.2
* Updated for WoW 3.1
* Now works with vehicles
* Fixed a problem with buff charges not showing as consumed
* Icons for reactive abilities will no longer show when the abilities are still on cooldown
* Cooldown icons should now be more responsive

## v1.1.1
* Icons for reactive abilities will no longer show when the abilities are still on cooldown.

## v1.1
* Added cooldown and buff/debuff timers.  Compatible with OmniCC.

## v1.0.1
* Updated for WoW 3.0

## v1.0
* Hello world!