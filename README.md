# TellMeWhen

[![Build Status](https://dev.azure.com/Cybeloras/TellMeWhen/_apis/build/status/TellMeWhen?branchName=master)](https://dev.azure.com/Cybeloras/TellMeWhen/_build/latest?definitionId=1&branchName=master)
[![Discord](https://img.shields.io/discord/546941305264275456?color=%237289da&label=Discord&logo=Discord)](https://discord.gg/NH7RmcP)
[![Paypal](https://img.shields.io/badge/Paypal-Donate-Blue?logo=Paypal)](https://www.paypal.com/cgi-bin/webscr?return=http%3A%2F%2Fwow.curseforge.com%2Fprojects%2Ftellmewhen&cn=Add+special+instructions+to+the+addon+author%28s%29&business=ascott18%40msn.com&bn=PP-DonationsBF%3Abtn_donateCC_LG.gif%3ANonHosted&cancel_return=http%3A%2F%2Fwow.curseforge.com%2Fprojects%2Ftellmewhen&lc=US&item_name=TellMeWhen+%28from+Curse.com%29&cmd=_donations&rm=1&no_shipping=1&currency_code=USD)

<img align="left" src="https://discordapp.com/assets/f8389ca1a741a115313bede9ac02e2c0.svg" width="55"/> Join the official TellMeWhen Discord!  [https://discord.gg/NH7RmcP](https://discord.gg/NH7RmcP)
<br>
Ask questions, share configuration, or just hang out.

<br>
TellMeWhen is a WoW addon that provides visual, auditory, and textual notifications about cooldowns, buffs, and pretty much every other element of combat. TellMeWhen is...

## Flexible

Icons can track any of the following things:

*   Cooldowns
*   Buffs/Debuffs
*   Reactive abilities
*   Multi-state abilities
*   Temporary weapon enchants
*   Totems/Wild mushrooms/Ghouls/Lightwell
*   Rune cooldowns
*   Internal cooldowns
*   Others' cooldowns
*   Diminishing returns
*   Spell casts
*   Loss of Control effects
*   ...And any combination of over 110 other things with easy-to-use [conditions](http://wow.curseforge.com/addons/tellmewhen/images/29).

## Customizable

*   Icons can be set to show or hide based on the status of their basic element and their usability based on range, duration, stacks, and resources.
*   All icons can show the standard cooldown animation to display their status, and are compatible with [OmniCC](http://www.curse.com/addons/wow/omni-cc).
*   There are over 110 [conditions](http://wow.curseforge.com/addons/tellmewhen/images/29) that can be configured to make an icon show only under very specific or very general circumstances.
*   You can [set a sound to play](http://wow.curseforge.com/addons/tellmewhen/images/19-sounds/) when important attributes of an icon change.
*   You can also [set text to be announced/displayed](http://wow.curseforge.com/addons/tellmewhen/images/20-text-output/) when an icon's attributes change.
*   Icons can show at different transparency levels based upon the usability/existence of what they are checking.
*   Icons can show status bars on top of them, indicating the required resources and their remaining cooldown/duration in a different way.
*   Icons can be skinned with [Masque](http://www.curse.com/addons/wow/masque) (formerly ButtonFacade).

* * *


## Instructions

To lock and unlock TellMeWhen, type "/tmw" or "/tellmewhen".

When you first log in with TellMeWhen installed, you will see one group of four icons in the center of your screen. To begin using TellMeWhen, right-click on one of these icons, and the [icon editor](http://wow.curseforge.com/addons/tellmewhen/images/18-the-icon-editor/) will appear. You need to select an icon type from the dropdown menu and enable the icon, and then configure the icon to suit your needs based on the settings that are available. An explanation of what most settings do can be found in the tooltip displayed when you mouse over a setting.

You can also drag spells from your spellbook, your pet's spellbook, or items from your inventory to quickly set up a cooldown icon for that spell/item. Icons can be spatially manipulated by holding down the right mouse button and dragging them around. When they are dropped on another icon, a menu will appear asking you what you want to do with the icon - Options include Move, Copy, and Swap.

General settings can be accessed via '/tmw options', the Blizzard interface options, or the 'Group Settings' tab of the icon editor.

All available slash commands are:

*   '/tmw' - Toggles TellMeWhen between locked (functional) or unlocked (configuration) states.
*   '/tmw options' - Opens the general settings configuration for TellMeWhen.
*   '/tmw profile "Profile Name"' - Loads a TellMeWhen profile. Profile name is case sensitive, and must be quoted if it contains spaces. (E.g. '/tmw profile "Cybeloras - Aerie Peak"').
*   '/tmw enable global|profile groupID iconID' - Enables the specified group or icon (E.g. '/tmw enable 2 4' or '/tmw enable global 3').
*   '/tmw disable global|profile groupID iconID' - Disables the specified group or icon (E.g. '/tmw disable profile 2 4' or '/tmw disable 3').
*   '/tmw toggle global|profile groupID iconID' - Toggles the specified group or icon between enabled and disabled (E.g. '/tmw toggle global 2 4' or '/tmw toggle profile 3').
*   '/tmw cpu' - Enables and displays a UI for measurements of icon performance. This is an advanced feature; no guidance on reading the data will be offered.

### Conditions

Conditions are a very powerful feature of TellMeWhen that allow you to narrow the circumstances under which an icon or group should show. To configure conditions for an icon, click the condition tab on the Icon Editor. Conditions can check a wide variety of things, and I recommend that you explore the condition type menu to see what is available. You can add multiple conditions to an icon, and you can group different conditions together for use with the Boolean operators AND and OR by clicking the parenthesis between each condition.

Conditions are also used for other purposes throughout TellMeWhen.

### Meta icons

Meta icons are one other special feature of TellMeWhen that makes it so powerful and versatile. Meta icons allow you to specify a list of other icons to check within the meta icon, allowing you to have a large number of icons for different situations show in the same location on your screen. By chaining meta icons together

### Groups

All TellMeWhen icons belong to a parent group. Each of these groups have many settings; some affect their appearance and size, while other affect their functionality. The options for a group can be accessed by typing "/tmw options", or by clicking the group settings tab on the icon editor. Groups can also have conditions set to govern when they are shown and hidden - accessed through the Group Conditions tab of the icon editor, they are configured exactly the same way as icon conditions.

* * *

## Troubleshooting

**PLEASE DIRECT ALL FEEDBACK/BUGS/SUGGESTIONS [HERE](https://github.com/ascott18/TellMeWhen/issues)**

*   **Make sure that TellMeWhen is not in configuration mode. Type '/tmw' to toggle configuration mode on and off.**
*   The most common problem people encounter is caused by not entering the name correctly during configuration. Make sure you enter names EXACTLY as they are named when you mouse over them. For buffs this is often different from the ability/totem/trinket/enchant/**talent** which casts the buff, so be sure to check. Known buffs and debuffs are shown as a dark purple or a warrior brown color in the suggestion list.
*   If the name of the ability does not work properly, use the SpellID. SpellIDs can be found by looking at the suggestion list that pops up as you begin typing in the name, or by finding the ability on a site such as [Wowhead](http://www.wowhead.com). The spellID is in the url, for example: <code>www.wowhead.com/spell=**53351**</code>
*   Check the settings of the icon's group.
*   Check the icon's settings in the other tabs of the icon editor.

## Donations

If you enjoy using TellMeWhen or if it has helped out your game-play considerably, please consider donating so that I may be able to afford time to develop more new features. Click the button below to donate securely through PayPal. Thank You!

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif "Donate")](https://www.paypal.com/cgi-bin/webscr?return=http%3A%2F%2Fwow.curseforge.com%2Fprojects%2Ftellmewhen&cn=Add+special+instructions+to+the+addon+author%28s%29&business=ascott18%40msn.com&bn=PP-DonationsBF%3Abtn_donateCC_LG.gif%3ANonHosted&cancel_return=http%3A%2F%2Fwow.curseforge.com%2Fprojects%2Ftellmewhen&lc=US&item_name=TellMeWhen+%28from+Curse.com%29&cmd=_donations&rm=1&no_shipping=1&currency_code=USD)

_TellMeWhen is also looking for individuals who are well-versed in both English and either German, Russian, Korean, French, or Portuguese to contribute to the translations! If interested, you can begin translating [here](http://wow.curseforge.com/addons/tellmewhen/localization/), or PM me if you have questions. Thank You!_

