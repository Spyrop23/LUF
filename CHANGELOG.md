# Changelog

## Unreleased
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
