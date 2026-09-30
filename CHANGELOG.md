# Changelog

## Unreleased
- Options window reorganised with tabs, as in Luna: every unit page now has tabs for General,
  Health bar, Power bar, Cast bar, XP bar, Portrait, Incoming heals, Auras, Range, Indicators and
  Texts (only the ones that apply to that frame). The selected tab is kept when you switch between
  frames.

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
