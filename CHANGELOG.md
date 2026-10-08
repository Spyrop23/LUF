# Changelog

## Unreleased
- Fix: `[smarthealth]` (and the other smart health tags) showed nothing on dead, ghost and offline units instead of "Dead" / "Ghost" / "Offline". Found with the new `/luf debug`.
- The options window (and the debug window) can be closed with the X in combat too: the button hides the window itself instead of going through Blizzard's panel manager, which is locked in combat.
- `/luf debug`: errors the addon catches (in event handlers, tags, timers) are collected instead of getting lost; the first one prints a hint in the chat. `/luf debug` opens a report to copy (version, game, every error with how often it happened), handy for bug reports. `/luf debug clear` empties the list.
- Faster: the fast power update (smooth energy/mana) now redraws only texts with power tags ([pp], [mana] ...) instead of every text on the frame; power events do the same. The chosen font is looked up once instead of for every text.

## 0.14.0
- Totem timers, as in Luna: for shamans the class power row (Player → Class power) shows four bars for fire, earth, water and air that run down while the totem stands. Works in combat. Thanks to **Twiz777** for the idea!
- Druid mana bar, as in Luna: in bear and cat form your mana shows as an extra bar below the power bar (Player → Power bar → "Druid mana bar"; height, position, own texts on the Tags tab). Comes and goes with the form, also in combat. New tags `[mana]` and `[maxmana]`. Thanks to **spudster90** for the idea!
- Show yourself in the party frames, as in Luna: Party → General → "Show yourself in the party (on top)". You take the first place, party 1-4 follow below. Off by default. Thanks to **spudster90** for the idea!
- Fix: the elite/rare dragon did not show any more since 0.13.0. It shows again, and "Mirror" turns it around reliably. In config mode (/luf unlock) the dragon is shown on the frame, so it can be placed without an elite target.

## 0.13.2
- Incoming heal colours on the Colors page: your own heals, heals from others and absorb shields, each with a colour picker (e.g. for red/green colour blindness). Thanks to **snmartino** for the idea!

## 0.13.1
- Fonts: a text could stay empty with a font that was not loaded yet (e.g. from another addon) until the outline was toggled. Fonts are now loaded at login and set once more shortly after login and after every font change.
- Bar order, as in Luna: every bar tab (health, power, empty, experience) has "Position (1 = top)", e.g. the empty bar above the health and power bars. Thanks to **fmjrrmg** for the idea!

## 0.13.0
- Fonts, as in Luna: General → "Font" offers the game's fonts (Friz Quadrata, Arial Narrow, Skurri, Morpheus), seven free fonts that ship with the addon (Aldrich, Bangers, Faster One, Iceland, Inconsolata, Trade Winds, Vera Serif) and every font another addon registered with LibSharedMedia. "Font outline" adds an outline to the frame texts. Thanks to **LagaerthaTV** for the idea!
- Tag offsets are back: every text (left, center, right) on every bar has an X and Y offset on the Tags tab. Thanks to **lovemefaster**!
- Elite/rare dragon: "Mirror" turns it around, plus an X/Y position. Thanks to **lovemefaster**!

## 0.12.0
- Class power on the player frame (new "Class power" tab): combo points (rogue, druid in cat form; in Forever on your target, as Classic does it), and in Retail holy power, soul shards, chi (Windwalker), arcane charges (Arcane) and essence, as a row of points above or below the frame. Works in combat: every point fills itself from the game's value. Height and spacing adjustable. (Death Knight runes are not included yet.) Blizzard's own class bar (holy power, combo points, soul shards, chi, arcane charges, essence) is hidden meanwhile; untick "Hide Blizzard class bar" to keep it. The row sits directly on the frame; a cast bar (and auras) on the same side move further out to make room.
- Your own power (energy, mana, rage ...) and your pet's now run up smoothly point by point, as on Blizzard's frames, instead of jumping every few seconds.
- Five second rule (Forever): after you spend mana, a spark runs along your mana bar for 5 seconds, the time until your mana regenerates again. Player → Power bar → "Five second rule" (on by default).

## 0.11.0
- **Retail (Midnight 12.x) support:** the same addon now also loads in Retail WoW (one download for both games, the client picks the right interface version). Retail classes (Death Knight, Demon Hunter, Monk, Evoker) and power types (runic power, astral power, maelstrom, insanity, fury, pain, others from Blizzard's colours) are included; Classic-only options (pet happiness and loyalty, pet XP, master looter) are hidden in Retail.

## 0.10.3
- Buffs and debuffs at separate places: Auras tab → "Debuff position". "With the buffs" keeps them together as before; Below / Above / Right / Left gives the debuffs a place of their own, e.g. buffs above the frame and debuffs below. Thanks to **vbrokop** for the idea!
- Horizontal limit side and horizontal limit, as in Luna, separately for buffs and debuffs: above/below the frame the icons start at the left edge (growing right) or at the right edge (growing left), and a row may be 20-150 % of the frame width.
- Bigger buffs / bigger debuffs, as in Luna: your own auras are shown larger (+0-20 px), the others follow at the normal size. Works in combat; the max. count applies to your own and to the others' auras each.
- X and Y offset for buffs and for debuffs: move each block left/right and up/down (-100 to 100 px), e.g. buffs a little higher above the frame.
- Time left position: below the icon (as before), in the icon or above it.
- The Auras tab is laid out like Luna's: everything for buffs, then everything for debuffs.

## 0.10.2
- Raid frames in a party, as in Luna: Raid → General → "Use the raid frames in a party too". In a party the first raid group shows you and party 1-4 (with everything set up for the raid: squares, borders, range ...); in a raid the frames switch back. "Hide the party frames then" (on by default) hides the party frames meanwhile. Off by default.

## 0.10.1
- The chat command is now `/luf` (e.g. `/luf unlock`). The old `/lzuf` and `/lizuf` still work.

## 0.10.0
**Heads-up for existing users:** this update turns on a few new things by default on every
frame: a white border on mouseover, a debuff border for debuffs you can dispel, and the raid
target, leader, master looter, resurrection and role icons, and combat text on player, pet and
target. Switch them off per frame on the Borders, Indicators and Combat text tabs.

- Options window reorganised with tabs, as in Luna: every unit page now has tabs for General, Health bar, Power bar, Cast bar, XP bar, Portrait, Incoming heals, Auras, Range, Indicators and Tags (only the ones that apply to that frame). The selected tab is kept when you switch between frames.
- Squares, as in Luna: nine indicator squares per frame (corners, edges, centre) on player, pet, target, party, party pets and raid. Types: aggro, aggro (target's target), buff, my buff, debuff, my debuff (each from a spell list), dispellable debuff (coloured by type) and missing buff. Shown as a coloured square or with the spell icon, optional cooldown swipe, size and offset per square. Works in combat through the game's aura system; spells are matched by ID (names of spells from your spellbook are converted automatically).
- Filters page, as in Luna: named filter lists shared by all characters. Create, rename, delete, export and import lists; search auras by name or spell ID (the rank is shown after the name, e.g. "Demon Armor  Rank 1  ID: 706") and add them with one click; hover a result for its tooltip. Each frame's Auras tab can use a list to hide those buffs/debuffs or to show only them, and every square can take its spells from a list.
- Borders, as in Luna (new Borders tab on every frame): a coloured edge on mouseover (white), on aggro (threat colour) and on debuff (Off / Your own = ones you can dispel / All), coloured by type: magic blue, curse purple, poison green, disease brown, others red. The debuff border works in combat and wins over aggro and mouseover. Size 1-10 and "Always on top".
- Indicators, as in Luna (Indicators tab on every frame): raid target icon, class, master looter, leader, PvP flag and incoming resurrection, each with on/off, size, point and X/Y offset; plus the elite/rare/boss dragon on the left or right side of the frame (on for the target).
- Role indicator: tank, healer or damage icon of group members (as set in the group menu).
- Raid assistant indicator: the assistant icon on raid assistants (where the leader's crown sits).
- Main tank and main assist indicators: Blizzard's shield and sword icons on members with that raid role.
- Highlight, as in Luna (new Highlight tab): the frame lights up on mouseover, when it shows your target, and/or tinted by debuff type (ones you can dispel, or all; works in combat). Strength adjustable. Off by default.
- Colors page, as in Luna: class, power, reaction, pet happiness, static health, cast bar, channel, tapped and offline colours, each with a colour picker; per profile, with a reset.
- Combat text, as in Luna (new tab): damage (red), heals (green), energize (blue) and misses, dodges, parries ... flash on the portrait and fade out; critical hits are larger. On for player, pet and target, font size adjustable.
- Empty bar, as in Luna (new tab): a bar without a value, only for texts, with its own weight, background colour and tags. Off by default.
- Focus frame (with cast bar and debuffs) and Focus Target frame (off by default); Blizzard's focus frame is hidden like the other Blizzard frames.
- Main Tank and Main Assist frames, as in Luna, each with a target frame next to it: up to four main tanks and two main assists, taken from the raid roles (set by the raid leader); they follow role changes out of combat. Placed and styled like every other frame.
- Party Targets, as in Luna: the target of each party member, next to the member's frame (upper half; the party pet sits below). Off by default: Party Targets → General → Enabled.
- Hide Blizzard page, as in Luna: every "Hide Blizzard frame" setting (and the cast bar) in one place.
- Indicator icons go up to 80 px; in config mode the raid target icon shows one mark (skull) instead of the whole sheet.
- Squares: the list types are now called "(from filter)", and two new types need no list: "My buffs (any)" (any buff you cast) and "Castable buffs" (any buff you are able to cast).
- Squares can show several auras: "Number of icons" (1-8) and the direction further icons grow (right, left, down, up), for every aura type except "missing".
- Config mode: stand-in party/raid frames now show your own auras in their squares, aura rows and debuff border, so you can see how they will look. Aura squares show no placeholder there any more (only aggro squares keep their coloured preview).
- Hovering a frame shows the unit's tooltip.
- Download zip now carries the version in its name (LizzaricksUnitFrames-0.10.0.zip); the folder inside stays LizzaricksUnitFrames.
- Every slider now has an input box: type the value and press Enter (kept within the slider's range; "0,35" and "0.35" both work).

## 0.9.2
- New tag `[statuscolor]`: starts red while in combat and green while resting (player only). Combat wins over resting. Example: `[statuscolor][name][nocolor] [smarthealth]`.

## 0.9.1
- New tag `[resting]`: shows "(Resting)" in an inn or a capital city (player only). Player texts update as soon as you enter or leave a rest area.

## 0.9.0
- Status icon on the player frame, as in Luna: crossed swords in combat, an animated "Zzz" while resting. Uses Blizzard's own player frame art.
- Options → Player → Status icon: on/off, size and position (9 anchor points). On by default, bottom left, 16 px.

## 0.8.1
- Unticking a "Hide Blizzard …" option (frames or cast bar) now offers to reload the interface: a hidden Blizzard frame can only come back after a reload.
