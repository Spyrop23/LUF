# Changelog

## 0.10.0
**Heads-up for existing users:** this update turns on a few new things by default on every
frame: a white border on mouseover, a debuff border for debuffs you can dispel, and the raid
target, leader, master looter, resurrection and role icons, and combat text on player, pet and
target. Switch them off per frame on the Borders, Indicators and Combat text tabs.

- Options window reorganised with tabs, as in Luna: every unit page now has tabs for General,
  Health bar, Power bar, Cast bar, XP bar, Portrait, Incoming heals, Auras, Range, Indicators and
  Tags (only the ones that apply to that frame). The selected tab is kept when you switch between
  frames.
- Squares, as in Luna: nine indicator squares per frame (corners, edges, centre) on player, pet,
  target, party, party pets and raid. Types: aggro, aggro (target's target), buff, my buff,
  debuff, my debuff (each from a spell list), dispellable debuff (coloured by type) and missing
  buff. Shown as a coloured square or with the spell icon, optional cooldown swipe, size and
  offset per square. Works in combat through the game's aura system; spells are matched by ID
  (names of spells from your spellbook are converted automatically).
- Filters page, as in Luna: named filter lists shared by all characters. Create, rename,
  delete, export and import lists; search auras by name or spell ID (the rank is shown after
  the name, e.g. "Demon Armor  Rank 1  ID: 706") and add them with one click; hover a result
  for its tooltip. Each frame's Auras tab can use a list to hide those buffs/debuffs or to
  show only them, and every square can take its spells from a list.
- Borders, as in Luna (new Borders tab on every frame): a coloured edge on mouseover (white),
  on aggro (threat colour) and on debuff (Off / Your own = ones you can dispel / All), coloured
  by type: magic blue, curse purple, poison green, disease brown, others red. The debuff border
  works in combat and wins over aggro and mouseover. Size 1-10 and "Always on top".
- Indicators, as in Luna (Indicators tab on every frame): raid target icon, class, master looter,
  leader, PvP flag and incoming resurrection, each with on/off, size, point and X/Y offset; plus
  the elite/rare/boss dragon on the left or right side of the frame (on for the target).
- Role indicator: tank, healer or damage icon of group members (as set in the group menu).
- Raid assistant indicator: the assistant icon on raid assistants (where the leader's crown sits).
- Highlight, as in Luna (new Highlight tab): the frame lights up on mouseover, when it shows your
  target, and/or tinted by debuff type (ones you can dispel, or all; works in combat). Strength
  adjustable. Off by default.
- Colors page, as in Luna: class, power, reaction, pet happiness, static health, cast bar,
  channel, tapped and offline colours, each with a colour picker; per profile, with a reset.
- Combat text, as in Luna (new tab): damage (red), heals (green), energize (blue) and misses,
  dodges, parries ... flash on the portrait and fade out; critical hits are larger. On for
  player, pet and target, font size adjustable.
- Empty bar, as in Luna (new tab): a bar without a value, only for texts, with its own weight,
  background colour and tags. Off by default.
- Main Tank and Main Assist frames, as in Luna, each with a target frame next to it: up to four
  main tanks and two main assists, taken from the raid roles (set by the raid leader); they
  follow role changes out of combat. Placed and styled like every other frame.
- Party Targets, as in Luna: the target of each party member, next to the member's frame (upper
  half; the party pet sits below). Off by default: Party Targets → General → Enabled.
- Hide Blizzard page, as in Luna: every "Hide Blizzard frame" setting (and the cast bar) in one
  place.
- Indicator icons go up to 80 px; in config mode the raid target icon shows one mark (skull)
  instead of the whole sheet.
- Squares: the list types are now called "(from filter)", and two new types need no list:
  "My buffs (any)" (any buff you cast) and "Castable buffs" (any buff you are able to cast).
- Squares can show several auras: "Number of icons" (1-8) and the direction further icons grow
  (right, left, down, up), for every aura type except "missing".
- Config mode: stand-in party/raid frames now show your own auras in their squares, aura rows
  and debuff border, so you can see how they will look. Aura squares show no placeholder there
  any more (only aggro squares keep their coloured preview).
- Hovering a frame shows the unit's tooltip.
- Download zip now carries the version in its name (LizzaricksUnitFrames-0.10.0.zip); the folder
  inside stays LizzaricksUnitFrames.
- Every slider now has an input box: type the value and press Enter (kept within the slider's
  range; "0,35" and "0.35" both work).

## 0.9.2
- New tag `[statuscolor]`: starts red while in combat and green while resting (player only).
  Combat wins over resting. Example: `[statuscolor][name][nocolor] [smarthealth]`.

## 0.9.1
- New tag `[resting]`: shows "(Resting)" in an inn or a capital city (player only).
  Player texts update as soon as you enter or leave a rest area.

## 0.9.0
- Status icon on the player frame, as in Luna: crossed swords in combat, an animated "Zzz" while
  resting. Uses Blizzard's own player frame art.
- Options → Player → Status icon: on/off, size and position (9 anchor points). On by default,
  bottom left, 16 px.

## 0.8.1
- Unticking a "Hide Blizzard …" option (frames or cast bar) now offers to reload the interface:
  a hidden Blizzard frame can only come back after a reload.
