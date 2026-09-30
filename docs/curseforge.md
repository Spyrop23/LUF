# Lizzarick's Unit Frames

**Luna-style unit frames for World of Warcraft: Forever**, no libraries needed.

Luna Unit Frames can't run on WoW: Forever. The client is a modern one, with the new addon
restrictions (secret values, no combat log). Lizzarick's Unit Frames brings back Luna's look and
its options menu, rebuilt from scratch so it keeps working in combat.

## Frames
- Player, pet, pet target, target, target of target, target of target of target
- Party (1-4) with their pets and targets, raid (40 frames, one column per raid group)
- Main tanks and main assists (from the raid roles) with their targets
- Luna's default layout; move everything with `/lzuf unlock` or a right click on the minimap button
- Raid grid: members in columns or rows, groups per row, or move each group on its own

## Bars and texts
- Health, power and XP bars (player and pet), 3D/2D portrait, cast bars for player, target and party
- 15 smooth bar textures of our own
- Health coloured by class, reaction, health gradient or happiness (hunter pets: red/yellow/green)
- Incoming heals as in Luna (your own dark green, others light green) plus absorb shields
- An empty bar for extra texts, combat text on the portrait (damage, heals, misses)
- 30 Luna tags, e.g. `[name]`, `[smarthealth]`, `[perhp]`, `[levelcolor][level]`, `[statuscolor]`

## Auras
- Buffs and debuffs, also in combat, with tooltip, time left, stacks and a debuff border by type
- Debuffs can be larger than buffs; position, size, count and spacing are adjustable
- **Filter lists** as in Luna: search auras by name or spell ID (the rank is shown), build lists,
  export and import them, then hide those auras or show only them

## Squares, borders and indicators
- **Squares:** nine small indicators per frame. Aggro, buffs and debuffs from a list or filter, your
  own buffs, buffs you can cast, dispellable debuffs (coloured by type), missing buffs. As a
  coloured square or the spell icon, up to 8 icons per square, optional timer
- **Borders:** on mouseover, on aggro and on debuff (the ones you can dispel, or all), coloured by type
- **Highlight:** the frame lights up on mouseover, as your target, or tinted by debuff type
- **Indicators:** raid target mark, class, leader, master looter, PvP, incoming resurrection,
  role (tank/healer/damage), elite dragon, combat/resting icon

## Options
- Luna-style menu with tabs for every frame; every slider has an input box
- Colors page (classes, power, reactions, pet happiness, cast bars) with a colour picker
- Profiles per character (create, copy, delete, reset)
- Hide Blizzard page: Blizzard's frames and cast bar in one place
- `/lzuf` opens the menu, as do the minimap button and the addon compartment

## Limits of WoW: Forever
Some values are kept secret by the game in combat. The addon never works around this. It lets
the game draw those values itself. That is why a few Luna extras are not possible, such as
calculated heal tags or single incoming heals.
