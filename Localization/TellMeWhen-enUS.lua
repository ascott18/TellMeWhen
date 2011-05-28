--GAME_LOCALE = "ruRU" --FOR TESTING
local L = LibStub("AceLocale-3.0"):NewLocale("TellMeWhen", "enUS", true)



L["CMD_OPTIONS"] = "Options"
L["ICON_TOOLTIP1"] = "TellMeWhen"
L["ICON_TOOLTIP2NEW"] = "Right click for icon options. Right click and drag to another icon to move/copy. Drag spells or items onto the icon for quick setup. Typing /tellmewhen or /tmw will lock and enable the addon."
L["LDB_TOOLTIP1"] = "|cff7fffffLeft-click|r to toggle the group locks"
L["LDB_TOOLTIP2"] = "|cff7fffffRight-click|r to show the main TMW options"
L["LOADERROR"] = "TellMeWhen_Options could not be loaded: "
L["LOADINGOPT"] = "Loading TellMeWhen_Options."
L["ENABLINGOPT"] = "TellMeWhen_Options is disabled. Enabling..."

L["LOCKED"] = "Locked"
L["RESIZE"] = "Resize"
L["RESIZE_TOOLTIP"] = "Click and drag to change size"

L["HPSSWARN"] = "Warning! Any icon conditions that you had set that checked for holy power or soul shards may be messed up! Check them to prevent later confusion!"
L["CONDITIONORMETA_CHECKINGINVALID"] = "Warning! Group %d, Icon %d is checking an invalid icon (Group %d, Icon %d)"

-- -------------
-- ICONMENU
-- -------------

L["ICONMENU_CHOOSENAME"] = "Choose name/ID"
L["ICONMENU_CHOOSENAME_CNDTIC"] = "Choose name/ID/texture path"
L["ICONMENU_ENABLE"] = "Enabled"
L["CHOOSENAME_EQUIVS_TOOLTIP"] = "You can select a predefined set of buffs/debuffs, spell casts, or dispel types (Magic, Curse, etc.) from this menu to insert into the editbox."
L["CHOOSENAME_DIALOG_DDDEFAULT"] = "Predefined Spell Sets/Dispel Types"
L["CHOOSENAME_DIALOG"] = [=[Enter the Name or ID of what you want this icon to monitor. You can add multiple things (except for multi-state cooldowns) by separating them with semicolons (;).

|cFFFF5959PET ABILITIES|r must use SpellIDs.]=]
L["CHOOSENAME_DIALOG_CNDTIC"] = "Enter the Name or ID of the spell that has the texture that you want to use. You may also enter a texture path, such as \"Interface/Icons/spell_nature_healingtouch\""
L["CHOOSENAME_DIALOG_ICD"] = "ICD/duration"
L["CHOOSENAME_DIALOG_ICD_DESC"] = "Enter the internal cooldown length or the duration of the spell that you want to track."
L["CHOOSENAME_DIALOG_UCD_DESC"] = "Enter the cooldown length of the spell(s) that you want to track."

L["ICONMENU_ALPHA"] = "Transparency"
L["CONDITIONALPHA"] = "Conditions/Duration/Stacks"
L["CONDITIONALPHA_DESC"] = "This will be used when conditions fail, or if the duration or stack requirements are not met."
L["ICONMENU_TYPE"] = "Icon type"
L["ICONMENU_COOLDOWN"] = "Cooldown"
L["ICONMENU_BUFFDEBUFF"] = "Buff/Debuff"
L["ICONMENU_REACTIVE"] = "Reactive ability"
L["ICONMENU_REACTIVE_DESC"] = [[Reactive abilities are things like Kill Shot, Revenge, and Conflagrate -
abilities that are only usable when certain conditions are met. Use this icon type to track their usability.]]
L["ICONMENU_WPNENCHANT"] = "Weapon enchant"
L["ICONMENU_WPNENCHANT_DESC"] = [[Tracks the status of temporary weapon enchants on your weapons - most useful for shaman.
With this icon type, the name can be left blank to track any weapon enchant in the specified slot,
or you can insert the names of weapon enchants to only show it for specific enchants.
The names that must be entered are the names that appear in the tooltip of your weapon while the enchant is active, e.g "Flametongue", not "Flametongue Weapon."]]
L["ICONMENU_TOTEM"] = "Totem"
L["ICONMENU_GHOUL"] = "Non-MoG ghoul"
L["ICONMENU_MUSHROOMS"] = "Wild Mushrooms"
L["ICONMENU_MULTISTATECD"] = "Multi-state ability"
L["ICONMENU_MULTISTATECD_DESC"] = "This should be used when you want to track multiple states/textures/etc of a cooldown. Some examples are Holy Word: Chastise and Dark Simulacrum. |cFFFF5959IMPORTANT|r: The action being tracked MUST be on your action bars for this icon type to work. You should also make sure that the ability is in its default state before leaving config mode."
L["ICONMENU_UNITCOOLDOWN"] = "Unit cooldown"
L["ICONMENU_UNITCOOLDOWN_DESC"] = [=[This icon type will allow you to track the cooldowns of your enemies.
You must enter the duration of the cooldown in the editbox to the right of the unit input.
Note regarding pvp trinkets: they can be tracked using '%s' as the name.]=]
L["ICONMENU_ICD"] = "Internal cooldown/Spell duration"
L["ICONMENU_ICD_DESC"] = [=[This icon type can be used to track either the internal cooldown of something such as a proc from a talent or a trinket,
or to track the duration of a spell (e.g. traps, mage orb), or even the duration of a summon (e.g. Infernal).
Enter the spellID or name of the buff/debuff that is placed when the cooldown starts,
or the name of the spell that you would like to track the duration of. Semicolon-delimited lists are valid.]=]
L["ICONMENU_CAST"] = "Spell Cast"
L["ICONMENU_CAST_DESC"] = [=[The name dialog can be left blank to show the icon for any cast, or in order to only shown the icon for certain spells,
you can enter a single spell, or a semicolon-delimited list of spells.]=]
L["ICONMENU_CNDTIC"] = "Condition Icon"
L["ICONMENU_CNDTIC_DESC"] = [=[This icon type is for simply checking a condition.
The icon can be set to a specific spell texture or texture path via the name editbox.]=]
L["ICONMENU_META"] = "Meta icon"
L["ICONMENU_META_DESC"] = [=[This icon type can be used to combine several icons into one.
Icons that have 'Always Hide' checked will still be shown if they would otherwise be shown.]=]


L["ICONMENU_COOLDOWNTYPE"] = "Cooldown type"
L["ICONMENU_SPELL"] = "Spell or ability"
L["ICONMENU_ITEM"] = "Item"

L["ICONMENU_SHOWWHEN"] = "Show icon when"
L["ICONMENU_USABLE"] = "Usable"
L["ICONMENU_UNUSABLE"] = "Unusable"

L["ICONMENU_BUFFTYPE"] = "Buff or debuff"
L["ICONMENU_BUFF"] = "Buff"
L["ICONMENU_DEBUFF"] = "Debuff"
L["ICONMENU_BOTH"] = "Either"

L["ICONMENU_CHECKNEXT"] = "Check sub-metas"
L["ICONMENU_CHECKNEXT_DESC"] = "Checking this box will cause this icon to check all the icons of any meta icons that it might be checking at any level. In addition, this icon will not show any icons that have already been shown by another meta icon with a group/icon ID closer to 1."

L["ICONMENU_DISPEL"] = "Dispel Type"
L["ICONMENU_CASTS"] = "Spell Casts"

L["ICONMENU_UNITSTOWATCH"] = "Units to watch"
L["ICONMENU_UNITS"] = "Units"
L["ICONMENU_UNIT_DESC"] = "Enter the units to watch in this box. Units can be inserted from the dropdown to the right, or advanced users can insert their own units. Separate each unit with a semicolon (;). Standard units (player, target, mouseover, etc; the same units that are used for macros) may be used, or friendly player names if those players are in your group/raid (Cybeloras, Nephthys, etc.)"
L["DROPDOWN_UNIT_DESC"] = "You can select units from this menu to insert into the editbox. Units that end with '|cFFFF0000#|r' require that the '|cFFFF0000#|r' be replaced with a number corresponding to the appropriate unit, or a range of numbers like 1-10. E.g. change 'raid|cFFFF0000#|r' to 'raid25' to track the 25th raid member, or change it to 'raid1-25' to track the first 25 raid members."
L["ICONMENU_TARGETTARGET"] = "Target's target"
L["ICONMENU_FOCUSTARGET"] = "Focus' target"
L["ICONMENU_PETTARGET"] = "Pet's target"
L["ICONMENU_MOUSEOVER"] = "Mouseover"
L["ICONMENU_MOUSEOVERTARGET"] = "Mouseover's target"
L["ICONMENU_VEHICLE"] = "Vehicle"
L["MAINTANK"] = "Main Tank"
L["MAINASSIST"] = "Main Assist"

L["ICONMENU_PRESENT"] = "Present"
L["ICONMENU_ABSENT"] = "Absent"
L["ICONMENU_ALWAYS"] = "Always"

L["ICONMENU_CASTSHOWWHEN"] = "Show when a cast is"
L["ICONMENU_ONLYINTERRUPTIBLE"] = "Only Interruptible"
L["ICONMENU_ONLYINTERRUPTIBLE_DESC"] = "Check this box to only show spell casts that are interruptible"

L["ICONMENU_ONLYMINE"] = "Only show mine"
L["ICONMENU_SHOWTIMER"] = "Show timer"
L["ICONMENU_SHOWTIMERTEXT"] = "Show timer text"
L["ICONMENU_SHOWTIMERTEXT_DESC"] = "This is only applicable if 'Show timer' is checked and OmniCC (or similar) is installed."

L["ICONMENU_BARS"] = "Bars"
L["ICONMENU_SHOWPBARN"] = "Power bar"
L["ICONMENU_SHOWCBARN"] = "Timer bar"
L["ICONMENU_SHOWPBAR_DESC"] = "Shows a bar that is overlaid across the top half of the icon that will indicate the power still needed to cast the spell (or the power that you have when 'Fill bars up' is checked)"
L["ICONMENU_SHOWCBAR_DESC"] = "Shows a bar that is overlaid across the bottom half of the icon that will indicate the cooldown/duration remaining (or the time that has passed if 'Fill bars up' is checked)"
L["ICONMENU_INVERTBARS"] = "Fill bars up"
L["ICONMENU_OFFS"] = "Offset"
L["ICONMENU_BAROFFS"] = "This amount will be added to the bar in order to offset it. Useful for custom indicators of when you should begin casting a spell to prevent a buff from falling off, or to indicate the power required to cast a spell and still have some left over for an interrupt."

L["ICONMENU_REACT"] = "Unit Reaction"
L["ICONMENU_FRIEND"] = "Friendly"
L["ICONMENU_HOSTILE"] = "Hostile"
L["ICONMENU_EITHER"] = "Any"

L["ICONMENU_ICDTYPE"] = "Triggered by"
L["ICONMENU_SPELLCAST"] = "Spell Cast"
L["ICONMENU_ICDBDE"] = "Buff/Debuff/Energize"
L["ICONMENU_SPELLCAST_DESC"] = "Select this option if the internal cooldown begins when you cast the spell that you chose"
L["ICONMENU_ICDAURA_DESC"] = "Select this option if the internal cooldown begins when you apply the buff or debuff that you chose, or if the effect energizes you with mana/rage/etc."
L["ICONMENU_ICDUSABLE"] = "Usable CD/Expired spell"
L["ICONMENU_ICDUNUSABLE"] = "Unusable CD/Present spell"

L["TOTEMS"] = "Totems to check"
L["FIRE"] = "Fire"
L["EARTH"] = "Earth"
L["WATER"] = "Water"
L["AIR"] = "Air"
L["MUSHROOMS"] = "Mushrooms to check"
L["MUSHROOM"] = "Mushroom %d"

L["ICONMENU_RANGECHECK"] = "Range check"
L["ICONMENU_RANGECHECK_DESC"] = "Check this to enable changing the color of the icon when you are out of range"
L["ICONMENU_MANACHECK"] = "Power check"
L["ICONMENU_MANACHECK_DESC"] = "Check this to enable changing the color of the icon when you are out of mana/rage/runic power/etc"
L["ICONMENU_COOLDOWNCHECK"] = "Cooldown check"
L["ICONMENU_COOLDOWNCHECK_DESC"] = "Check this to cause the icon to be considered unusable if it is on cooldown"
L["ICONMENU_IGNORERUNES"] = "Ignore Runes"
L["ICONMENU_IGNORERUNES_DESC"] = "Check this to treat the cooldown as usable if the only thing hindering it is a rune cooldown (or a global cooldown)."
L["ICONMENU_DONTREFRESH"] = "Don't Refresh"
L["ICONMENU_DONTREFRESH_DESC"] = "Check to force the cooldown to not reset if the trigger occurs while it is still counting down. Useful for talents such as Early Frost."

L["SORTBY"] = "Sort by"
L["SORTBYNONE"] = "Don't sort"
L["SORTBYNONE_DESC"] = "If checked, spells will be checked in and appear in the order that they were entered into the editbox. If this icon is a buff/debuff icon, auras will be checked in the order that they would normally appear on the unit's unit frame IF the number of auras being checked exceeds the efficiency threshold setting."
L["ICONMENU_SORTASC"] = "Ascending duration"
L["ICONMENU_SORTASC_DESC"] = "Check this box to prioritize and show spells with the lowest duration."
L["ICONMENU_SORTDESC"] = "Descending duration"
L["ICONMENU_SORTDESC_DESC"] = "Check this box to prioritize and show spells with the highest duration."

L["ICONMENU_MOVEHERE"] = "Move here"
L["ICONMENU_COPYHERE"] = "Copy here"
L["ICONMENU_SWAPWITH"] = "Swap with"
L["ICONMENU_ADDMETA"] = "Add to meta icon"
L["ICONMENU_APPENDCONDT"] = "Add as 'Icon Shown' condition"


L["STACKSPANEL_TITLE"] = "Stacks"
L["ICONMENU_STACKS_MIN_DESC"] = "Minimum number of stacks of the aura needed to show the icon"
L["ICONMENU_STACKS_MAX_DESC"] = "Maximum number of stacks of the aura allowed to show the icon"

L["DURATIONPANEL_TITLE"] = "Duration"
L["ICONMENU_DURATION_MIN_DESC"] = "Minimum duration needed to show the icon"
L["ICONMENU_DURATION_MAX_DESC"] = "Maximum duration allowed to show the icon"

L["METAPANEL_TITLE"] = "Meta Icon Editor"
L["METAPANEL_UP"] = "Move up"
L["METAPANEL_DOWN"] = "Move down"
L["METAPANEL_REMOVE"] = "Remove this icon"
L["METAPANEL_INSERT"] = "Insert an icon"

L["ICONALPHAPANEL_FAKEHIDDEN"] = "Always Hide"
L["ICONALPHAPANEL_FAKEHIDDEN_DESC"] = "Causes the icon to be hidden all the time, but whilst still enabled in order to allow the conditions of other icons to check this icon, or for meta icons to include this icon."
L["ICONMENU_WPNENCHANTTYPE"] = "Weapon slot to monitor"
L["ICONMENU_HIDEUNEQUIPPED"] = "Hide when slot is empty"
L["ICONMENU_USEACTIVATIONOVERLAY"] = "Check activation border"
L["ICONMENU_USEACTIVATIONOVERLAY_DESC"] = "Check this to cause the presence of the sparkly yellow border around an action to force the icon to act as usable."
L["ICONMENU_ONLYEQPPD"] = "Only if equipped"
L["ICONMENU_ONLYEQPPD_DESC"] = "Check this to make the icon show only if the item is equipped."
L["ICONMENU_ONLYBAGS"] = "Only if in bags"
L["ICONMENU_ONLYBAGS_DESC"] = "Check this to make the icon show only if the item is in your bags (or equipped). If 'Only if equipped' is enabled, this is also forcibly enabled."
L["ICONMENU_ONLYSEEN"] = "Only if seen"
L["ICONMENU_ONLYSEEN_DESC"] = "Check this to make the icon only show a cooldown if the unit has cast it at least once. You should check this if you are checking spells from different classes in one icon."


-- -------------
-- UI PANEL
-- -------------

L["UIPANEL_SUBTEXT2"] = "Icons work when locked. When unlocked, you can move/size icon groups and right click individual icons for more settings. You can also type /tellmewhen or /tmw to lock/unlock."
L["UIPANEL_ICONGROUP"] = "Icon group "
L["UIPANEL_MAINOPT"] = "Main Options"
L["UIPANEL_GROUPS"] = "Groups"
L["UIPANEL_COLORS"] = "Colors"
L["UIPANEL_ENABLEGROUP"] = "Enable Group"
L["UIPANEL_GROUPNAME"] = "Rename Group"
L["UIPANEL_ROWS"] = "Rows"
L["UIPANEL_COLUMNS"] = "Columns"
L["UIPANEL_ONLYINCOMBAT"] = "Only show in combat"
L["UIPANEL_NOTINVEHICLE"] = "Hide in Vehicle"
L["UIPANEL_SPEC"] = "Dual Spec"
L["UIPANEL_TREE"] = "Talent Tree"
L["UIPANEL_TREE_DESC"] = "Check to allow this group to show when this talent tree is active, or uncheck to cause it to hide when it is not active."
L["UIPANEL_PRIMARYSPEC"] = "Primary Spec"
L["UIPANEL_SECONDARYSPEC"] = "Secondary Spec"
L["UIPANEL_GROUPRESET"] = "Reset Position"
L["UIPANEL_TOOLTIP_GROUPRESET"] = "Reset this group's position and scale"
L["UIPANEL_ALLRESET"] = "Reset all"
L["UIPANEL_TOOLTIP_ALLRESET"] = "Reset DATA and POSITION of all icons and groups, as well as any other settings."
L["UIPANEL_LOCKUNLOCK"] = "Lock/Unlock AddOn"
L["UIPANEL_BARTEXTURE"] = "Bar Texture"
L["UIPANEL_NOCOUNT_DESC"] = "Enables/disables the text that displays the cooldown on the icon. It will only be shown if the icon's timer is enabled, this option is enabled, and OMNICC IS INSTALLED"
L["UIPANEL_BARIGNOREGCD"] = "Bars Ignore GCD"
L["UIPANEL_BARIGNOREGCD_DESC"] = "If checked, cooldown bars will not change values if the cooldown triggered is a global cooldown"
L["UIPANEL_CLOCKIGNOREGCD"] = "Timers Ignore GCD"
L["UIPANEL_CLOCKIGNOREGCD_DESC"] = "If checked, timers and the cooldown clock will not trigger from a global cooldown"
L["UIPANEL_UPDATEINTERVAL"] = "Update Interval"
L["UIPANEL_TOOLTIP_UPDATEINTERVAL"] = "Sets how often (in seconds) icons are checked for show/hide, alpha, conditions, etc. Zero is as fast as possible. Lower values can have a significant impact on framerate for low-end computers"
L["UIPANEL_EFFTHRESHOLD"] = "Buff Efficiency Threshold"
L["UIPANEL_EFFTHRESHOLD_DESC"] = "Sets the minimum number of buffs/debuffs to switch to a more efficient mode of checking them when there are a high number. Note that once the number of auras being checked exceeds this number, older auras will be prioritized instead of priority based on the order in which they were entered."
L["UIPANEL_ICONSPACING"] = "Icon Spacing"
L["UIPANEL_ICONSPACING_DESC"] = "Distance that icons within a group are away from each other"
L["UIPANEL_ADDGROUP"] = "Add Another Group"
L["UIPANEL_ADDGROUP_DESC"] = "The new group will be assigned the next available groupID"
L["UIPANEL_DELGROUP"] = "Delete this Group"
L["UIPANEL_DELGROUP_DESC"] = "Any groups after this group will have their ID shifted up one, and any icons that are checking icons in groups that will be shifted will have their settings automatically updated."
L["UIPANEL_TOOLTIP_ENABLEGROUP"] = "Show and enable this group"
L["UIPANEL_TOOLTIP_ROWS"] = "Set the number of rows in this group"
L["UIPANEL_TOOLTIP_COLUMNS"] = "Set the number of columns in this group"
L["UIPANEL_TOOLTIP_ONLYINCOMBAT"] = "Check to only show this group while in combat"
L["UIPANEL_TOOLTIP_NOTINVEHICLE"] = "Check to hide this group when you are in a vehicle and your action bars have changed to that vehicle's abilities"
L["UIPANEL_TOOLTIP_PRIMARYSPEC"] = "Check to show this group while your primary spec is active"
L["UIPANEL_TOOLTIP_SECONDARYSPEC"] = "Check to show this group while your secondary spec is active"
L["UIPANEL_COLOR"] = "Cooldown/Duration Bar Color"
L["UIPANEL_COLOR_COMPLETE"] = "CD/Duration Complete"
L["UIPANEL_COLOR_STARTED"] = "CD/Duration Begin"
L["UIPANEL_COLOR_COMPLETE_DESC"] = "Color of the cooldown/duration overlay bar when the cooldown/duration is complete"
L["UIPANEL_COLOR_STARTED_DESC"] = "Color of the cooldown/duration overlay bar when the cooldown/duration has just begun"
L["UIPANEL_DRAWEDGE"] = "Highlight timer edge"
L["UIPANEL_DRAWEDGE_DESC"] = "Highlights the edge of the cooldown timer (clock animation) to increase visibility"
L["UIPANEL_WARNINVALIDS"] = "Warn about invalid icons"
L["UIPANEL_COLOR_OOR"] = "Out of range color"
L["UIPANEL_COLOR_OOR_DESC"] = "Tint and alpha of the icon when you are not in range of the target to cast the spell"
L["UIPANEL_COLOR_OOM"] = "Out of power color"
L["UIPANEL_COLOR_OOM_DESC"] = "Tint and alpha of the icon when you lack the mana/rage/energy/focus/runicpower to cast the spell"
L["UIPANEL_COLOR_DESC"] = "The following options only affect the colors of icons when they are set to show all the time"
L["UIPANEL_COLOR_PRESENT"] = "Present color"
L["UIPANEL_COLOR_PRESENT_DESC"] = "The tint of the icon when the buff/debuff/enchant/totem is present and the icon is set to always show."
L["UIPANEL_COLOR_ABSENT"] = "Absent color"
L["UIPANEL_COLOR_ABSENT_DESC"] = "The tint of the icon when the buff/debuff/enchant/totem is absent and the icon is set to always show."
L["UIPANEL_STANCE"] = "Show while in:"
L["NONE"] = "None of these"
L["CASTERFORM"] = "Caster Form"

L["UIPANEL_FONT"] = "Stack Text"
L["UIPANEL_FONT_DESC"] = "Chose the font to be used by the stack text on icons."
L["UIPANEL_FONT_SIZE"] = "Font Size"
L["UIPANEL_FONT_SIZE_DESC"] = "Change the size of the font used for stack text on icons. If ButtonFacade is used and the set skin has a font size defined, then this value will be ignored."
L["UIPANEL_FONT_OUTLINE"] = "Font Outline"
L["UIPANEL_FONT_OUTLINE_DESC"] = "Sets the outline style for the stack text on icons."
L["OUTLINE_NO"] = "No Outline"
L["OUTLINE_THIN"] = "Thin Outline"
L["OUTLINE_THICK"] = "Thick Outline"
L["UIPANEL_FONT_OVERRIDELBF"] = "Override ButtonFacade"
L["UIPANEL_FONT_OVERRIDELBF_DESC"] = "Check this to override the position of the stack text that is defined in your ButtonFacade skin. If you do not use ButtonFacade, ignore this."
L["UIPANEL_FONT_XOFFS"] = "X Offset"
L["UIPANEL_FONT_YOFFS"] = "Y Offset"
L["UIPANEL_POSITION"] = "Position"
L["UIPANEL_POINT"] = "Point"
L["UIPANEL_RELATIVETO"] = "Relative To"
L["UIPANEL_RELATIVETO_DESC"] = "Type '/framestack' to toggle a tooltip that contains a list of all the frames that your mouse is over, and their names, to put into this dialog."
L["UIPANEL_RELATIVEPOINT"] = "Relative Point"
L["CHECKORDER"] = "Update order"
L["CHECKORDER_ICONDESC"] = "Sets the order in which icons within this group will be updated. This really only matters if you are using the feature of meta icons to check sub-metas."
L["CHECKORDER_GROUPDESC"] = "Sets the order in which groups will be updated. This really only matters if you are using the feature of meta icons to check sub-metas."
L["ASCENDING"] = "Ascending"
L["DESCENDING"] = "Descending"
L["UIPANEL_SCALE"] = "Scale"
L["UIPANEL_LEVEL"] = "Frame Level"
L["UIPANEL_LOCK"] = "Lock Group"
L["UIPANEL_LOCK_DESC"] = "Lock this group, preventing movement or sizing by dragging the group or the scale tab."


-- -------------
-- CONDITION PANEL
-- -------------

L["CONDITIONPANEL_TITLE"] = "TellMeWhen Condition Editor"
L["ICONTOCHECK"] = "Icon to check"
L["MOON"] = "Moon"
L["SUN"] = "Sun"
L["TRUE"] = "True"
L["FALSE"] = "False"
L["CONDITIONPANEL_TYPE"] = "Type"
L["CONDITIONPANEL_UNIT"] = "Unit"
L["CONDITIONPANEL_UNIT_DESC"] = "Enter the unit to watch in this box. The unit can be inserted from the dropdown to the right, or advanced users can insert their own unit. Standard units (player, target, mouseover, etc.) may be used, or friendly player names (Cybeloras, Nephthys, etc.)"
L["CONDITIONPANEL_UNITDROPDOWN_DESC"] = "You can select a unit from this menu to insert into the editbox. Units that end with '|cFFFF0000#|r' require that the '|cFFFF0000#|r' be replaced with a number corresponding to the appropriate unit. E.g. change 'raid|cFFFF0000#|r' to 'raid25' to track the 25th raid member. NOTE: Conditions only accept one unit."
L["CONDITIONPANEL_OPERATOR"] = "Operator"
L["CONDITIONPANEL_VALUE"] = "Percent"
L["CONDITIONPANEL_VALUEN"] = "Value"
L["CONDITIONPANEL_ANDOR"] = "And / Or"
L["CONDITIONPANEL_AND"] = "And"
L["CONDITIONPANEL_OR"] = "Or"
L["CONDITIONPANEL_POWER"] = "Primary Resource"
L["CONDITIONPANEL_COMBO"] = "Combo Points"
L["CONDITIONPANEL_ALTPOWER"] = "Alt. Power"
L["CONDITIONPANEL_ALTPOWER_DESC"] = [[This is the encounter specific power used in several encounters in Cataclysm,
including Cho'gall and Atramedes]]
L["CONDITIONPANEL_EXISTS"] = "Unit Exists"
L["CONDITIONPANEL_ALIVE"] = "Unit is Alive"
L["CONDITIONPANEL_ALIVE_DESC"] = "The condition will pass if the unit specified is alive."
L["CONDITIONPANEL_COMBAT"] = "Unit in Combat"
L["CONDITIONPANEL_VEHICLE"] = "Unit Controls Vehicle"
L["CONDITIONPANEL_POWER_DESC"] = [=[Will check for energy if the unit is a druid in cat form,
rage if the unit is a warrior, etc.]=]
L["ECLIPSE_DIRECTION"] = "Eclipse Direction"
L["CONDITIONPANEL_ECLIPSE_DESC"] = [=[Eclipse has a range of -100 (a lunar eclipse) to 100 (a solar eclipse).
Input -80 if you want the icon to work with a value of 80 lunar power.]=]
L["CONDITIONPANEL_ICON"] = "Icon Shown"
L["CONDITIONPANEL_ICON_DESC"] = [=[The condition will pass if the icon specified is currently shown with an alpha above 0%, or hidden with an alpha of 0% if set to false.
If you don't want to display the icons that are being checked, check 'Always Hide' in the icon editor of the icon being checked.
The group of the icon being checked must also be shown in order to check the icon, even if the condition is set to false.]=]
L["CONDITIONPANEL_RUNES_DESC"] = [=[Use this condition type to only show the icon when the selected runes are available.
Each rune is a check button. A check mark will require that the rune be usable, an 'X' will require that the rune be unusable, no mark will ignore the rune.
The runes in the second row are the death rune version of each rune above.]=]
L["CONDITIONPANEL_PVPFLAG"] = "Unit is PvP Flagged"
L["CONDITIONPANEL_LEVEL"] = "Unit Level"
L["CONDITIONPANEL_CLASS"] = "Unit Class"
L["CONDITIONPANEL_CLASSIFICATION"] = "Unit Classification"
L["CONDITIONPANEL_NAME"] = "Unit Name"
L["CONDITIONPANEL_NAMETOOLTIP"] = "Separate multiple names with semicolons (;)"
L["CONDITIONPANEL_INSTANCETYPE"] = "Instance Type"
L["CONDITIONPANEL_GROUPTYPE"] = "Group Type"
L["CONDITIONPANEL_SWIMMING"] = "Swimming"
L["CONDITIONPANEL_RESTING"] = "Resting"
L["CONDITIONPANEL_MANAUSABLE"] = "Spell Usable (Mana/Energy/etc.)"
L["CONDITIONPANEL_SPELLRANGE"] = "Spell in range of unit"
L["CONDITIONPANEL_ITEMRANGE"] = "Item in range of unit"
L["ONLYCHECKMINE"] = "Only Check Mine"
L["ONLYCHECKMINE_DESC"] = "Check this to cause this condition to only check your own buffs/debuffs"
L["LUACONDITION"] = "Lua (Advanced)"
L["LUACONDITION_DESC"] = [[This condition type allows you to evaluate Lua code to determine the state of a condition.
The input is not an 'if .. then' statement, nor is it a function closure.
It is a regular statement to be evaluated, e.g. 'a and b or c'.
If complex functionality is required, use a call to a function, e.g. 'CheckStuff()', that is defined externally.
ALL functions and variables used must be defined in/will be stored in TMW["CNDT"]["Env"].
If more help is needed (but not help about how to write Lua code), open a ticket on CurseForge.]]
L["NOTINRANGE"] = "Not in range"
L["INRANGE"] = "In range"
L["STANCE"] = "Stance"
L["AURA"] = "Aura"
L["ASPECT"] = "Aspect"
L["SHAPESHIFT"] = "Shapeshift"
L["PRESENCE"] = "Presence"
L["SPEED"] = "Unit Speed"
L["SPEED_DESC"] = [[This refers to the current movement speed of the unit. If the unit is not moving, it is zero.
If you wish to track the maximum run speed of the unit, use the 'Unit Run Speed' condition instead.]]
L["RUNSPEED"] = "Unit Run Speed"

L["MELEEHASTE"] = "Melee Haste"
L["MELEECRIT"] = "Melee Crit"
L["RANGEDHASTE"] = "Ranged Haste"
L["RANGEDCRIT"] = "Ranged Crit"
L["SPELLHASTE"] = "Spell Haste"
L["SPELLCRIT"] = "Spell Crit"
L["ITEMINBAGS"] = "Item count (includes charges)"
L["ITEMEQUIPPED"] = "Item is equipped"
L["ITEMCOOLDOWN"] = "Item cooldown"
L["MP5"] = "%d MP5"
L["REACTIVECNDT_DESC"] = "This condition only checks the reactive state of the ability, not the cooldown of it."
L["BUFFCNDT_DESC"] = "Only the first spell will be checked, all others will be ignored. Spells entered as IDs will not be forced to have their ID match an aura found; only the name will have to match."
L["CNDT_ONLYFIRST"] = "Only the first spell/item will be checked - semicolon-delimited lists are not valid for this condition type."

L["RESOURCES"] = "Unit Resources"
L["PLAYERSTATS"] = "Player Stats"
L["ICONFUNCTIONS"] = "Icon Functions"
L["CURRENCIES"] = "Currencies"
L["UNITSTATUS"] = "Unit Status"
L["PLAYERSTATUS"] = "Player Status"

L["CONDITIONPANEL_MOUNTED"] = "Mounted"
L["CONDITIONPANEL_EQUALS"] = "Equals"
L["CONDITIONPANEL_NOTEQUAL"] = "Not Equal to"
L["CONDITIONPANEL_LESS"] = "Less Than"
L["CONDITIONPANEL_LESSEQUAL"] = "Less Than/Equal to"
L["CONDITIONPANEL_GREATER"] = "Greater Than"
L["CONDITIONPANEL_GREATEREQUAL"] = "Greater Than/Equal to"
L["CONDITIONPANEL_REMOVE"] = "Remove this condition"
L["CONDITIONPANEL_ADD"] = "Add a condition"
L["PARENTHESISWARNING"] = "# of opening and closing parentheses isn't equal!"
L["PARENTHESISWARNING2"] = "Some closing parentheses are missing openers!"
L["NUMAURAS"] = "Number of"
L["ACTIVE"] = "%d Active"
L["NUMAURAS_DESC"] = [[This condition checks the number of an aura active - not to be confused with the number of stacks of an aura.
This is for checking things like if you have both weapon enchant procs active at the same time.
Use sparingly, as the process used to count the numbers is a bit CPU intensive.]]




-- ----------
-- STUFF THAT I GOT SICK OF ADDING PREFIXES TOO AND PUTTING IN THE RIGHT PLACE
-- ----------

L["GROUPICON"] = "Group: %s, Icon: %s"
L["fGROUP"] = "Group %s"
L["fICON"] = "Icon %s"
L["DISABLED"] = "Disabled"
L["IMPORTCOPY"] = "Copy/Import"
L["COPYPOS"] = "Copy position/scale"
L["COPYALL"] = "Copy entire group"

L["GROUPADDONSETTINGS"] = "Group settings"
L["CONDITIONS"] = "Conditions"
L["GROUPCONDITIONS"] = "Group Conditions"
L["MAIN"] = "Main"
L["RECEIVED"] = "Received icons"
L["EXPORT"] = "Export to string/player OR import from string"
L["EXPORT_LOLTITLE"] = "The editbox of sharing..."
L["EXPORT_DESC"] = [[To export to a player, type their name into this editbox and choose "Export to Player" in the dropdown menu at the right.

To export to a string, simply choose "Export to String" in the dropdown menu at the right, and then press CTRL+C to copy it to your clipboard.

To import from a string, press CTRL+V to paste the string into the editbox after you have copied it to your clipboard, and then choose "Import from String" from the dropdown menu at the right.
]]
L["UNNAMED"] = "((Unnamed))"

L["TOPLAYER"] = "Export to Player"
L["TOPLAYER_DESC"] = "Type a player's name into the editbox and choose this option to send it to them. They must be somebody that you can whisper (same faction, server, online), and they must have TellMeWhen v4+"
L["TOSTRING"] = "Export to String"
L["TOSTRING_DESC"] = "A string containing all of this icon's settings will be pasted into the editbox.  Press Ctrl+C to copy it, and then paste it wherever you want to share it."
L["FROMSTRING"] = "Import from String"
L["FROMSTRING_DESC"] = "Press Ctrl+V to paste in an export string that you have copied to your clipboard from another source to be applied to this icon."

L["SENDSUCCESSFUL"] = "Sent successfully"
L["MESSAGERECIEVE"] = "%s has sent you a TellMeWhen icon! You can import this icon into a slot by using the 'Copy/Import' dropdown in the icon editor."
L["MESSAGERECIEVE_SHORT"] = "%s has sent you a TellMeWhen icon!"
L["ALLOWCOMM"] = "Allow icon importing"
L["NEWVERSION"] = "A new version of TellMeWhen is available: %s"


L["CACHING"] = "TellMeWhen is caching and filtering all spells in the game. This only needs to be done once per WoW patch. You can speed up or slow down the process using the slider below."
L["CACHINGSPEED"] = "Spells per frame:"
L["SUGGESTIONS"] = "Suggestions:"
L["SUG_TOOLTIPTITLE"] = [[As you type, TellMeWhen will look through its cache and determine the spells that you were most likely looking for.

Spells are categorized and colored as per the list below. Note that the categories that begin with the word "Known" will not have spells put into them until they have been seen as you play or log onto different classes.

Clicking on an entry will insert it into the editbox.

]]
L["SUG_DISPELTYPES"] = "Dispel Types"
L["SUG_BUFFEQUIVS"] = "Buff Equivalencies"
L["SUG_DEBUFFEQUIVS"] = "Debuff Equivalencies"
L["SUG_CASTEQUIVS"] = "Spellcast Equivalencies"
L["SUG_MSCDONBARS"] = "Valid multi-state cooldowns"
L["SUG_PLAYERSPELLS"] = "Your spells"
L["SUG_CLASSSPELLS"] = "Known PC/pet spells"
L["SUG_NPCAURAS"] = "Known NPC buffs/debuffs"
L["SUG_PLAYERAURAS"] = "Known PC/pet buffs/debuffs"
L["SUG_MISC"] = "Miscellaneous"


L["SOUND_EVENT_ONSHOW"] = "On Show"
L["SOUND_EVENT_ONSHOW_DESC"] = "This event triggers when the icon becomes shown (even if 'Always Hide' is checked)."
L["SOUND_EVENT_ONHIDE"] = "On Hide"
L["SOUND_EVENT_ONHIDE_DESC"] = "This event triggers when the icon is hidden (even if 'Always Hide' is checked)."
L["SOUND_EVENT_ONSTART"] = "On Start"
L["SOUND_EVENT_ONSTART_DESC"] = "This event triggers when the cooldown becomes unusable, the buff/debuff is applied, etc. NOTE: This event will never trigger at the same time as the OnShow event."
L["SOUND_EVENT_ONFINISH"] = "On Finish"
L["SOUND_EVENT_ONFINISH_DESC"] = "This event triggers when the cooldown becomes usable, the buff/debuff falls off, etc. NOTE: This event will never trigger at the same time as the OnHide event."
L["SOUND_EVENTS"] = "Icon Events"
L["SOUND_SOUNDTOPLAY"] = "Sound to Play"
L["SOUND_CUSTOM"] = "Custom sound file"
L["SOUND_CUSTOM_DESC"] = [[Insert the path to a custom sound to play. Here are some examples, where "file" is the name of your sound, and "ext" is the file's extension (ogg or mp3 only!):

- "CustomSounds\file.ext": a file placed in a new folder named "CustomSounds" that is in WoW's root directory (the same location as Wow.exe, Interface and WTF folders, etc)
- "Interface\AddOns\file.ext": a loose file in the AddOns folder
- "file.ext": a loose file in WoW's root directory ]]
L["SOUND_TAB"] = "Sounds"
L["SOUND_USEMASTER"] = "Always play sounds"
L["SOUND_USEMASTER_DESC"] = "Check this to allow sounds to play even when the game sound has been muted. Uncheck to only play sounds while the game sound is enabled."
L["SOUNDERROR1"] = "File must have an extension!"
L["SOUNDERROR2"] = "Custom WAV files not supported by WoW 4.0+"
L["SOUNDERROR3"] = "|cFFFFD100Only OGG and MP3 files are supported!"

L["ANN_TAB"] = "Text Output"
L["ANN_CHANTOUSE"] = "Channel to Use"
L["ANN_EDITBOX"] = "Text to be outputted"
L["ANN_EDITBOX_DESC"] = [[Type the text that you wish to be outputted when the event triggers. Standard substitutions "%t" for your target and "%f" for your focus may be used for output to chat (say/yell/raid/etc.)]]
L["ANN_STICKY"] = "Sticky"
L["ANN_SHOWICON"] = "Show icon texture"
L["ANN_SHOWICON_DESC"] = "Some text destinations can show a texture along with the text. Check this to enable that feature."
L["ANN_SUB_CHANNEL"] = "Sub section"



L["TOPLEFT"] = "Top Left"
L["TOP"] = "Top"
L["TOPRIGHT"] = "Top Right"
L["LEFT"] = "Left"
L["CENTER"] = "Center"
L["RIGHT"] = "Right"
L["BOTTOMLEFT"] = "Bottom Left"
L["BOTTOM"] = "Bottom"
L["BOTTOMRIGHT"] = "Bottom Right"

-- --------
-- EQUIVS
-- --------

L["CrowdControl"] = "Crowd Control"
L["Bleeding"] = "Bleeding"
L["Feared"] = "Fear"
L["Incapacitated"] = "Incapacitated"
L["Stunned"] = "Stunned"
--L["DontMelee"] = "Dont Melee"
L["ImmuneToStun"] = "Immune To Stun"
L["ImmuneToMagicCC"] = "Immune To Magic CC"
--L["MovementSlowed"] = "Movement Slowed"
L["Disoriented"] = "Disoriented"
L["Silenced"] = "Silenced"
L["Disarmed"] = "Disarmed"
L["Rooted"] = "Rooted"
L["IncreasedStats"] = "Increased Stats"
L["IncreasedDamage"] = "Increased Damage Done"
L["IncreasedCrit"] = "Increased Crit Chance"
L["IncreasedAP"] = "Increased Attack Power"
L["IncreasedSPsix"] = "Increased Spellpower (6%)"
L["IncreasedSPten"] = "Increased Spellpower (10%)"
L["IncreasedPhysHaste"] = "Increased Physical Haste"
L["IncreasedSpellHaste"] = "Increased Spell Haste"
L["BurstHaste"] = "Heroism/Bloodlust"
L["BonusAgiStr"] = "Increased Agility/Strength"
L["BonusStamina"] = "Increased Stamina"
L["BonusArmor"] = "Increased Armor"
L["BonusMana"] = "Increased Mana Pool"
L["ManaRegen"] = "Increased Mana Regen"
L["BurstManaRegen"] = "Burst Mana Regen"
L["PushbackResistance"] = "Increased Pushback Resistance"
L["Resistances"] = "Increased Spell Resistance"
L["PhysicalDmgTaken"] = "Physical Damage Taken"
L["SpellDamageTaken"] = "Increased Spell Damage Taken"
L["SpellCritTaken"] = "Increased Spell Crit Taken"
L["BleedDamageTaken"] = "Increased Bleed Damage Taken"
L["ReducedAttackSpeed"] = "Reduced Attack Speed"
L["ReducedCastingSpeed"] = "Reduced Casting Speed"
L["ReducedArmor"] = "Reduced Armor"
L["ReducedHealing"] = "Reduced Healing"
L["ReducedPhysicalDone"] = "Reduced Physical Damage Done"
L["DefensiveBuffs"] = "Defensive Buffs"
L["MiscHelpfulBuffs"] = "Misc. Helpful Buffs"
L["DamageBuffs"] = "Damage Buffs"

L["Heals"] = "Player Heals"
L["PvPSpells"] = "PvP Crowd Control, etc."
L["Tier11Interrupts"] = "Tier 11 Interruptibles"

L["Magic"] = "Magic"
L["Curse"] = "Curse"
L["Disease"] = "Disease"
L["Poison"] = "Poison"
L["Enraged"] = "Enrage"

L["normal"] = "Normal"
L["rare"] = "Rare"
L["elite"] = "Elite"
L["rareelite"] = "Rare Elite"
L["worldboss"] = "World Boss"

