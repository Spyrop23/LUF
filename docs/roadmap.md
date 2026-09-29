# Roadmap

Grundlage: [spec.md](spec.md), Abschnitt G (Machbarkeit). Jede Etappe muss für sich im Spiel laufen.

## Etappe 1 – Grundgerüst ✅
TOC, Event-System, Profile, Tags, Secret-Helfer, Frames für player/target/ToT/ToToT mit Health, Power,
Portrait und Texten, Blizzard-Frames ausblenden, Config-Mode, `/fuf`.

## Etappe 2 – Castbar, Leisten, Tags
- Castbar (eigene nie secret; fremde über `UnitCastingDuration` + `StatusBar:SetTimerDuration`),
  `[castname]`, `[casttime]`, Zauber-Icon
- Bar-Slots wie Luna (Gruppen links/mitte/rechts, Order, vertikal, Invertieren über `SetReverseFill`)
- XP-/Ruf-Bar, Empty Bar, Druiden-Manabar, Combo Points
- Tags: `[br]`, `[shortname:x]`, `[smartlevel]`, `[afk]`, `[nameafk]`, `[combat]`, `[group]`,
  `[guild]`, `[pvp]`, `[happiness]`, `[loyalty]`, `[xp]`, `[percxp]`, `[threat]`,
  `[color:rrggbb]`, `[combatcolor]`, `[aggrocolor]`
- pet, pettarget, pettargettarget; focus, sofern `focus` in Forever zulässig ist *(TODO(beta))*

## Etappe 3 – Gruppen
- party, partypet, partytarget, raid (8 Gruppen), raidpet, maintank/mainassist
- **Achtung:** `SecureGroupHeaderTemplate` funktioniert, aber in der Beta fehlt `loadstring_untainted`,
  deshalb werfen `initialConfigFunction` und `WrapScript` einen Fehler. Plan: Größe und Einheit ohne
  Snippet setzen, sonst feste Frames party1–4 / raid1–40 mit `RegisterStateDriver(…, "visibility")`.
- Reichweiten-Alpha (`UnitInRange`, `C_Spell.IsSpellInRange`, `SetAlphaFromBoolean`)
- Indikatoren: Raid-Ziel, Anführer, Plündermeister, Bereitschaftscheck, Wiederbelebung, Rolle, PvP, Elite-Rahmen

## Etappe 4 – Auren, Heilung, Squares
- Buffs/Debuffs über `AuraContainer` (Filter Eigene/Bannbar über Filterstrings, größere eigene Auren
  als zweite Gruppe, Timer über `SetDurationText`)
- Heilvorhersage nativ (`CreateUnitHealPredictionCalculator`), Absorb-Schilde
- Debuff-Highlight und -Rahmen, Aggro-Rahmen, Ziel- und Mouseover-Highlight
- Squares: Aggro, eigener Buff/Debuff und Bannbar (Spell-ID-Listen)
- Kampf-Fader (ohne die Bedingung „Leben nicht voll“)

## Etappe 5 – Optionsfenster
- Eigenes Fenster (ohne AceConfig) mit allen Einstellungen, die in spec.md als ✅ oder ⚠️ markiert
  sind, eingehängt über die Settings-API
- Profile kopieren/löschen, Auto-Profile nach Gruppengröße, Import/Export über `C_EncodingUtil`

## Bekannte Beta-Risiken
- **SavedVariables:** Die Beta lädt accountweite SVs nach einem Kaltstart oft nicht und überschreibt
  sie dann mit Standards. Prüfen, ob `## SavedVariablesPerCharacter` oder `## SavedVariablesMachine`
  zuverlässiger ist *(TODO(beta))*.
- Bestätigen, dass `CurveConstants.ScaleTo100` Prozentwerte liefert und `SetFormattedText("%.0f%%", …)`
  mit Secrets funktioniert.
- `UnitRace` kann den Beta-Client einfrieren und wird deshalb nicht verwendet.

## Nicht machbar (Forever)
Energie-/MP5-Ticker, rechnende Heil-Tags (`[healhp]`, `[healmishp]`, `[healerhealth]`), Einzelheilungs-Tags
(`[numheals]`, `[incownheal]`, `[hotheal]` …), Teilnamen-Aurenfilter und „fehlender Buff“ im Kampf,
`[race]`, `[server]`, `[enumtargeting]`, `[buffcount]` im Kampf, `[healthcolor]` als Inline-Farbe.
