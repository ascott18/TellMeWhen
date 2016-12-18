if not TMW then return end

TMW.CHANGELOG_LASTVER="6.2.6"

TMW.CHANGELOG = [==[
===v8.2.4===
* Changed behavior of the On Combat Event notification trigger slightly to avoid occasional undesired timing issues (Ticket 1352).
* Added conditions for Monks to check their stagger under the Resources condition category.

====Bug Fixes====
* Fixed BigWigs conditions for the latest BigWigs update.

===v8.2.3===
* Improved behavior of exporting to other players.

===v8.2.2===
* Packaging latest version of LibDogTag-Unit-3.0.

===v8.2.1===
* You can now change bar textures on a per-group basis.
* Added some missing currency definitions.

====Bug Fixes====
* Fixed updating of class-specific resource conditions for non-player units.
* On Start and On Finish notification triggers should no longer spaz out and trigger excessively.
* Meta icons should now always use the correct unit when evaluating the DogTags used in their text displays.
* Fixed meta icon rearranging.
* Fixed tooltip number conditions for locales that use commas as their decimal separator.

===v8.2.0===
* New Icon Type: Guardians. Currently only implemented for Warlocks to track their Wild Imps/Dreadstalkers/etc.
* Support for Patch 7.1.

* New DogTag: MaxDuration
* Controlled icons can now be selected as a target of Meta icons and Icon Shown conditions.
* Cooldown sweeps that are displaying charges during a GCD when the GCD is allowed will now show the GCD.
* You can now flip the origin of progress bars to the right side of the icon.
* New Notification Triggers: On Charge Gained and On Charge Spent

====Bug Fixes====
* Fixed an issue that would cause unintentional renaming of text layouts. 
* Fixed an issue with text colors after a chat link in Raid Warning (Fake) text notification handlers.
* Fixed an issue with timer/status bars briefly showing their old value when they are first shown.
* Fixed a few bugs relating to improper handling of the icon type name of some variants of the totem icon type.
* Fixed an issue with Condition-triggered animations not being able to stop for non-icon-based animations.
* Fel Rush and Infernal Strike should now work with the Last Ability Used condition.
* On Show/On Hide notification triggers should now work on controlled icons.
* All-Unit Buffs/Debuffs icons should now work correctly for infinite duration effects. They're also a bit better now at cleaning up things that expired.

===v8.1.2===
* Restored the old Buff/Debuff duration percentage conditions, since they still have applications for variable-duration effects like Rogue DoTs.

====Bug Fixes====
* Attempted a permanant fix to very rare and very old bug where some users' includes.*.xml files were getting scrambled around in their TMW install, leading to the problem of most of the addon not getting loaded.
* Fixed an issue with Condition-triggered animations not working consistently in controlled groups.
* Buff/Debuff Duration conditions should once again work properly with effects that have no duration.
* Fixed an issue with occasional missing checkboxes in condition configuration
* Fixed resource percentage conditions
* Fixed a rare bug that would cause cooldown sweep animations to totally glitch out, usually in meta icons.

===v8.1.1===
====Bug Fixes====
* IconType_cooldowncooldown.lua:295: attempt to index field 'HELP' (a nil value)

===v8.1.0===
* New group layout option: Shrink Group. For dynamically centering groups.
* Added new Notification triggers for stacks increased/decreased

====Bug Fixes====
* Fixed the behavior of the Ignore Runes setting.
* Fixed Soul Shards condition - correct maximum is 6.
* Made the Last Ability Used condition not suck.
* Totem icon configuration should be back to its former glory.

===v8.0.3===
====Bug Fixes====
* Fixed creation of new profiles

===v8.0.2===
====Bug Fixes====
* Fixed: TellMeWhenComponentsCoreIcon.lua:491 attempt to index field 'typeData' (a nil value)

===v8.0.1===
====Bug Fixes====
* Fixed Maelstrom condition - correct maximum is 150.

===v8.0.0===
====Breaking Changes====
* There is a small chance you will need to reconfigure the spec settings on all your groups.
* Most of your old color settings were lost.

* You can no longer scale the Icon Editor by default. You can turn this back on in the General options.

* Each of the pairs of Opacity and Shown Icon Sorting methods have been merged.

* The Update Order settings have been removed.
** Try replacing usages of the Expand sub-metas setting with Group Controller meta icons if you experience issues.

====General====
* Full support for Legion. Get out there and kill some demons!
* All TellMeWhen configuration is now done in the icon editor.

* Color configuration has been completely revamped. It is now done on each icon.
** Duration Requirements, Stack Requirements, and Conditions Failed opacities now use Opactiy & Color settings.
** Out of Range & Out Of Power settings now use Opactiy & Color settings.
** You can also set a custom texture for each of your Opacity & Color settings.

* Combat Log Source and Destination units may now have unit conditions when filtered by unitID.
* New conditions have been added for:
** Checking your current location.
** Checking your last spell cast (for Windwalker Monk mastery).
** The old buff/debuff Tooltip Number conditions have returned as well.
* And much, much more! Dig in to check it all out!

===v7.4.0===
* Bar and Vertical Bar groups now have several new options:
** Show/Hide Icon
** Flip Icon
** Bar & Icon Borders

===v7.3.5===
====Bug Fixes====
* The TMWFormatDuration DogTag now properly handles negative durations.

===v7.3.4===
* Blizzard's new completion pulse animation on cooldown sweeps is now disabled by default, and can be enabled in TMW's main options.

====Bug Fixes====
* Power Bar Overlays should function once again.

===v7.3.3===
* Unit Cooldown icons can now filter spells based on the known class spells of a unit.

====Bug Fixes====
* Fixed: Condition_THREATSCALED: Usage: UnitDetailedThreatSituation("unit" [, "mob"])

===v7.3.1===
====Bug Fixes====
* Fixed: UnitAttributes.lua:277: 'for' limit must be a number.

===v7.3.0===
* The suggestion list now works with arrow keys to pick what line tab will insert.
* You can now use the suggestion list to pick condition types (the Condition Type dropdown now has a textbox on it).
* The Player Specialization condition is now deprecated in favor of the Unit Specialization condition.
* On Left/Right Click notification triggers no longer make icons click-interactive when the icon is hidden (opacity 0).

====Bug Fixes====
* Fixed some issues with the All-Unit Buff/Debuff icon type caused by some auras (A Murder of Crows) not firing combat log events on application/removal.
* Icons should no longer be treated as being on cooldown for color settings if they're tracking an ability that still has charges remaining.
* Fixed a typo that could sometimes break icon sorting, and may have also broken meta icons occasionally.
* Refactored the configuration for Animation and Text notifications, fixing a minor issue with settings not saving in the process.
* The Unit Specialization condition should now work for arena enemies from your own server.
* Fixed: meta.lua line 191: attempt to index field 'IconsLookup' (a nil value) (Ticket #1114)

===v7.2.6===
====Bug Fixes====
* Implemented a better fix to animations missing required anchors, since the fix in v7.2.5 broke several things.

===v7.2.5===
* Tweaked some of the default text layouts so that they more closely resemble their pre-WoW-6.1 appearance.
* Removed the diminishing returns duration setting, as it is now always 18 seconds.

====Bug Fixes====
* Removed some old code that was needed back when cooldown sweeps weren't inheriting their parent's opacity in the WoD beta. This was breaking cooldown sweeps on icons with Icon Alpha Flash animations where the alpha would go to 0.
* Icon Events are now setup at the end of icon setup to avoid issues with animations missing required anchors.
* Fixed a rare issue caused by unused parentheses on condition settings with less than 3 conditions.
* Fixed IconType_unitconditionunitcondition.lua:96: attempt to index local "Conditions" (a nil value).

===v7.2.4===
* New icon type: Unit Condition Icon.
* Added Dialog as a possible sound channel.
* The Icon Shown Time and Icon Hidden Time conditions are now deprecated in favor of using timer notification handlers.

====Bug Fixes====
* Fixed an error that will happen when screen animations end.
* Cooldown icons that aren't set to show when usable should once again fire an On Finish event.
* Fixed ItemCache.lua:110 bad argument #1 to 'pairs' (table expected, got nil)
* Fixed an issue that would break upgrades over locale-specific data.
* Fixed colors of the backdrop for bar groups being wrong (green and blue were swapped).
* The Eclipse condition should now be much more responsive.
* Fixed: ClassSpellCache.lua line 281: Usage: GetClassInfo(ID)
* Fixed several issues when using On Duration Changed notification triggers on controlled groups.

===v7.2.3===
* The old Runes condition has been deprecated. In its place are 3 new conditions that should be much easier to use.
* The Spell Cast Count condition has been deprecated. Its functionality can be replicated using the counter notification handler on a Combat Event icon.
* Updated the Chi condition to support a max of 6.
* You can now globally enable/disable global groups.
* While Condition Set Passing-triggered animations now work on a priority system, with those notifications higher in the configuration list having priority over lower-ranked notifications if both are eligible to play at the same time. This also prevents situations where no animations will play even though one should be.
* You can now customize the color of the backdrop for bar groups.

====Bug Fixes====
* Fixed an issue that caused Unit Conditions to not work with special units (group, maintank, mainassist, and player names).
* Mark of Shadowmoon and Mark of Blackrock should now work with the Internal Cooldown icon type.
* Fixed an error with power bar spell cost detection for German clients.
* Removed the Monochrome font outline option because it causes crashes so often.
* Resource Display icons should now correctly display partial resources.
* Fixed some errors that happen when using meta icons as group controllers.

===v7.2.2===
* You can now easily clone an event handler by right-clicking it in the Notifications tab.
* There is a new special unitID in TellMeWhen, "group" that will check raid or party depending on which you are in. It prevents the overlap that happens when checking "player; party; raid".
* You can now adjust the opacity of the backdrop for bar icons.

====Bug Fixes====
* Rage (and perhaps other powers) should no longer be multipled by 10 in the Resource Display icon type.
* Warriors in Gladiator Stance will now be treated as DPS for groups' role settings, and for the Specialization Role condition.
* The "Force top-row runes..." condition setting checkbox should now always reflect the icon's settings.
* The Zone PvP Type condition now actually works.
* Excluding spells from equivalencies now works if the spell is an ID in the equivalency.
* Added event registrations to two more spellcast events in hopes of fixing an issue where Spell Cast icons sometimes don't disappear (also added these to the spell cast condition).
* Fixed a silly logic error that broke skinning of texts shown through meta icons.

===v7.2.1===
====Bug Fixes====
* Fixed incorrect DR categories after changes made to DRData-1.0.

===v7.2.0===
* New icon type: Resource Display. Works with Bar and Vertical Bar group display methods to show the amount of health, mana, etc. that some unit has.
* The Multi-state Cooldown icon type is gone - Spell Cooldown icons can replicate its functionality.

* Combat Event icons can now be group controllers, filling up a group with each event captured.
* Buff/Debuff icons can now explicity set which variable they want to look at for the "Show variable text" option.
* All icons are now hidden when you are at the barber shop.
* The combo point condition now only checks your target (so you can't try to check "player", which doesn't work).

* New condition: Item has on use effect
* New notification handler: Timer. Manipulates a stopwatch-style timer when it is triggered.

* IMPORTANT: The Buff/Debuff Duration Percent conditions are being phased out because they are deceiving.
** In Warlords of Draenor, the point at which you can refresh a buff/debuff without clipping any of the existing duration is at 30% of the BASE DURATION of the effect - not 30% the current duration.
** Using these conditions to check when a buff/debuff has less than 30% remaining is bad practice, because if you refresh at 30% remaining of an already extended aura, you are going to clip some of it.
** Instead, you should manually calculate 30% of the base duration of what you want to check, and compare against that value in a regular Buff/Debuff Duration condition.

====Bug Fixes====
* Fixed range checking for multiple icon types (notably Multistate cooldowns, but also others).
* Blood Pact should now have the correct ID in the BonusStamina equivalency.
* Various tooltips now reflect that the game client once again supports MP3s.
* Fixed an issue that was breaking conditions that reference other icons.
* Fixed an issue that was causing icons in controlled groups to flash shown for one frame after an update is performed.
* Fixed an issue that was causing While Condition Set Passing event triggers to not start when their condition sets are passing after leaving config mode.
* Patched a potential Lua code injection attack vector in certain condition settings. (There is no evidence that this has been abused by anybody).

===v7.1.2===
* The Combat Event icon type now has special events that will fire when you multistrike.
* Various tooltips now reflect that WoW only supports .ogg files for custom sound files - MP3s are no longer supported by the game client.
* Removed error warning about other addons using debugprofilestart() - we got the data we needed.

====Bug Fixes====
* The Item in Range of Unit condition should once again work properly.
* TellMeWhen will no longer forcibly disable Blizzard's cooldown timer text when Tukui is enabled since Tukui now uses those texts as its timers.

===v7.1.1===
====Bug Fixes====
* Fixed a very silly mistake that broke anchoring of an icon's text displays when Masque was not installed.


===v7.1.0===
* TellMeWhen has been updated for Warlords of Draenor. Please open a ticket on CurseForge for TMW if you notice anything missing.

* New icon types:
** All-Unit Buffs/Debuffs. This icon type is mainly useful for tracking your multi-dotting on targets which might not have a unitID.
** Combat Event Error. This icon type reacts to messages like "Must be behind the target" or "You are already at full health".

* New icon display method: Vertical Bars.

* New conditions
** Instance Size
** Zone PvP Type

* You can now set a rotation amount for a icon's text displays.
* The "Highlight timer edge" setting is back.
* You can now export all your global groups at once.

* The suggestion list now defers its sorting so that input is more responsive.
* The suggestion list is now much smarter at suggesting things. For Example, "swp" will now suggestion "Shadow Word: Pain", and "dis mag" will suggest "Dispel Magic".


====Bug Fixes====
* Fixed another issue with ElvUI's timer texts (they weren't going away when they should have been).
* A whole lot of other minor bugs have been fixed - too many to list here.


===v7.0.3===
* Re-worked the Instance Type condition to make it more extensible in the future, and also added a few missing instance types to it.
* Added a Unit Specialization condition that can check the specs of enemies in arenas, and all units in battlegrounds.

====Bug Fixes====
* Fixed an error that would be thrown if the whisper target ended up evaluating to nil.
* TellMeWhen now duplicates Blizzard's code for the spell activation overlay (and has some additional code to get this to play nicely with Masque) so that it should hopefully no longer get blamed for tainting your action bars.
* TellMeWhen also now duplicates Blizzard's code for dropdown menus, and improves upon it slightly. This should also help with taint issues.

===v7.0.2===
====Bug Fixes====
* Fixed the missing slider value text for the Unit Level condition.
* The Haste conditions no longer have a hard cap of 100%.
* Fixed a false error that would display during configuring while using the [Range] DogTag.
* Fixed an error relating to refreshing the tooltip for non-button widgets.

===v7.0.1===
* Numbered units entered with a space in the middle (e.g. "arena 1") will once again be corrected by TellMeWhen. It is still bad practice to enter units like that, though.

====Bug Fixes====
* Fixed a typo that was preventing Loss of Control icons from reporting their spell.
* Fixed an error that would happen when upgrading a text layout that was previously unnamed: IconModule_TextsTexts.lua:150 attempt to concatenate field 'Name' (a nil value)

===v7.0.0===

====Core Systems====
* You can now create global groups that exist for all characters on your account. These groups can be enabled and disabled on a per-profile basis.
* Text Layouts are now defined on an account-wide basis instead of being defined for individual profiles.

* Many icon types, when set on the first icon in a group, are now able to control that entire group with the data that they harvest.

* All references from one icon or group to another in TellMeWhen are now tracked by a unique ID. This ID will persist no matter where it is moved or exported to.
** This includes:
*** DogTags
*** Meta icons
*** Icon Shown conditions (and the other conditions that track icons)
*** Group anchoring to other groups
** The consequence of this is that you can now, for example, import/export a meta icon separately from the icons it is checking and they will automatically find eachother once they are all imported (as long as these export strings were created with TMW v7.0.0+)
** IMPORTANT: Existing DogTags that reference other icons/groups by ID cannot be updated automatically - you will need to change these yourself.

====Events/Notifications====
* Events have been re-branded to Notifications, and you can now add notifications that will trigger continually while a set of conditions evaluate to true.
* New Notification: Counter. Configure a counter that can be checked in conditions and displayed with DogTags.
* The On Other Icon Show/Hide events have been removed. Their functionality can be obtained using an On Condition Set Passing trigger.
* You can now adjust the target opacity of the Alpha Flash animation

====Icon Types====
* Global Cooldowns are now only filtered for icon types that can track things on the global cooldown.
* Combat Event: the unit exclusion "Miscellaneous: Unknown Unit" will now also cause events that were fired without a unit to be excluded.
* Meta Icon: The "Inherit failed condition opacity" setting has been removed. Meta icons will now always inherit the exact opacity of the icons they are showing, though this can be overridden by the meta icon's opacity settings.
* Meta Icon: Complex chains of meta icon inheritance should now be handled much better, especially when some of the icons have animations on them.
* Diminishing Returns: The duration of Diminishing Returns is now customizable in TMW's main options.
* Buff/Debuff: Ice Block and Divine Shield are now treated as being as non-stealable (Blizzard flags them incorrectly)
* Buff/Debuff: Added an [AuraSource] DogTag to obtain the unit that applied a buff/debuff, if available.
* Buff/Debuff Check: Removed the "Hide if no units" option since it didn't make much sense for this icon type.

====Conditions====
* New Conditions added that offer integration with Big Wigs and Deadly Boss Mods.
* New Condition: Specialization Role
* New Condition: Unit Range (uses LibRangeCheck-2.0 to check the unit's approximate range)
* The Buff/Debuff - "Number of" conditions now accept semicolon-delimited lists of multiple auras that should be counted.

====Group Modules====
* You can now anchor groups to the cursor.
* You can now right-click-and-drag the group resize handle to easily change the number of rows and columns of a group, and doing so with this method will preserve the relative positions of icons within a group.
* Added group settings that allow you to specify when a group should be shown based on the role that your current specialization fulfills.

====Icon Modules====
* You can now enter "none" or "blank" as a custom texture for an icon to force it to display no texture.
* You can now enter a spell prefixed by a dash to omit that spell from any equivalencies entered, E.g. "Slowed; -Dazed" would check all slowed effects except daze.

* New text layout settings: Width, Height, & JustifyV.

====Miscellaneous====
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

====Bug Fixes====
* Units tracked by name with spaces in them (E.g. Kor'kron Warbringer as a CLEU unit filter) will now be interpreted properly as input.
** IMPORTANT: A consequence of this fix is that if you are enter a unit like "boss 1", this will no longer work. You need to enter "boss1", which has always been the proper unitID.
* Importing/Exporting icons from/to strings with hyperlinks in some part of the icon's data will now preserve the hyperlink.
* Icons should now always have the correct size after their view changes or the size or ID of a group changes.
* Fixed an issue where strings imported from older version of TellMeWhen (roughly pre-v6.0.0) could have their StackMin/Max and DurationMin/Max settings as strings instead of numbers.
* The "Equipment set equipped" condition should properly update when saving the equipment set that is currently equipped.
* Fixed an issue when upgrading text layouts that could also cause them to not be upgraded at all: /Components/IconModules/IconModule_Texts/Texts.lua line 205: attempt to index field 'Anchors' (a nil value)
* Currency conditions should once again be listed in the condition type selection menu.
* The NPC ID condition should now work correctly with npcIDs that are greater than 65535 (0xFFFF).
* Meta icons should reflect changes in the icons that they are checking that are caused by using slash commands to enable/disable icons while TMW is locked.
* TellMeWhen no longer registers PLAYER_TALENT_UPDATE - there is a Blizzard bug causing this to fire at random for warlocks, and possibly other classes as well, which triggers a TMW:Update() which can cause a sudden framerate drop. PLAYER_SPECIALIZATION_CHANGED still fires for everything that we cared about.

]==]
