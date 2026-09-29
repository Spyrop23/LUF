# Roadmap

Grundlage: [spec.md](spec.md), Abschnitt G (Machbarkeit). Jede Etappe muss für sich im Spiel laufen.

## Etappe 1 – Grundgerüst ✅
TOC, Event-System, Profile, Tags, Secret-Helfer, Frames für player/target/ToT/ToToT mit Health, Power,
Portrait und Texten, Blizzard-Frames ausblenden, Config-Mode, `/fuf`.

## Etappe 2 – Begleiter, Gruppe, Castbar, Menü ✅
- pet, pettarget, party1–4 (feste Frames statt Group-Header), partypet1–4 an ihrem Besitzer
- Castbar für player/target/party (Timer über `SetTimerDuration`, Name/Icon durchgereicht,
  Restzeit per `SetFormattedText`), Blizzard-Castbar ausblendbar
- Tags: `[shortname:x]`, `[smartlevel]`, `[afk]`, `[nameafk]`, `[combat]`, `[guild]`, `[xp]`,
  `[percxp]`, `[color:rrggbb]`, `[combatcolor]`
- Optionsmenü ohne Library (alle Frame-, Leisten-, Portrait-, Castbar- und Text-Einstellungen,
  Textur, Profile, Tag-Hilfe), Minimap-Button, Addon-Compartment, Eintrag unter Optionen → AddOns

## Zwischenschritt 0.4.0 – Auren ✅
- Buffs/Debuffs über `CustomAuraContainerTemplate` (Gruppen "buffs"/"debuffs", Filterstrings,
  Initializer mit Größe, Icon, Cooldown, Stapelzahl, Restzeit, Dispel-Farbrahmen). Kein Aura-Wert
  wird von FUF gelesen, deshalb funktioniert es auch im Kampf *(im Kampf noch zu bestätigen)*.

## Zwischenschritt 0.5.0 – Heilvorhersage ✅
- `CreateUnitHealPredictionCalculator` + `UnitGetDetailedHealPrediction(unit, "player", calc)`:
  `GetIncomingHeals()` liefert gesamt / vom Spieler / von anderen, geklemmt auf fehlendes Leben
  plus Overflow (`SetIncomingHealOverflowPercent`). Die Spec (G) hielt die Trennung eigene/fremde
  für unmöglich, mit dem Rechner geht sie. Weiter nicht möglich: HoT und Direktheilung getrennt,
  Zeitfenster.
- Drei StatusBars (eigene, fremde, Absorbs) jeweils an das Füllende der vorherigen geankert,
  in einem Clip-Frame so breit wie Leiste × Overflow *(im Client zu bestätigen)*.

## Etappe 3a – Raid, Reichweite, XP (0.6.0) ✅
- raid1–40 als feste SecureUnitButtons, außerhalb des Kampfes nach Untergruppe (GetRaidRosterInfo)
  in 8 Spalten sortiert; Ziehen verschiebt den ganzen Raid; Blizzards CompactRaidFrames ausblendbar
- Gruppe im Raid ausblenden: `RegisterStateDriver(f, "visibility", "[group:raid] hide; [@partyN,exists] show; hide")`
- Reichweite: `UnitInRange` (secret) -> `Frame:SetAlphaFromBoolean(inRange, 1, alpha)`, Poll 0,25 s
  plus `UNIT_IN_RANGE_UPDATE`
- XP-Leiste (Spieler mit Rested-Anteil, Begleiter über `GetPetExperience`) als dritte Leiste

## Etappe 3b – Leisten wie Luna
- Bar-Slots wie Luna (Gruppen links/mitte/rechts, Order, vertikal, Invertieren über `SetReverseFill`)
- Ruf-Bar, Empty Bar, Druiden-Manabar, Combo Points
- Tags: `[br]`, `[group]`, `[pvp]`, `[happiness]`, `[loyalty]`, `[threat]`, `[aggrocolor]`
- pettargettarget, partytarget; focus, sofern `focus` in Forever zulässig ist *(TODO(beta))*
- raidpet, maintank/mainassist, Raid-Auren (Debuffs im Frame)
- **Achtung:** `SecureGroupHeaderTemplate` funktioniert, aber in der Beta fehlt `loadstring_untainted`,
  deshalb werfen `initialConfigFunction` und `WrapScript` einen Fehler. Party läuft deshalb schon über
  feste Frames. Für den Raid gilt derselbe Plan: feste Frames raid1–40, oder ein Header ohne Snippet.
- Party im Raid ausblenden (Luna-Option), sobald das mit dem Unit-Watch vereinbar ist
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

## Im Client bestätigt (29.09.2026, Beta 1.60.1)
- `FUF.toc` in einem Ordner `FUF` lädt; ein Ordner `FUF-main` wird ignoriert.
- `SetFormattedText` mit Secret-Werten, `AbbreviateNumbers` und `CurveConstants.ScaleTo100`:
  „138/138 100%“ wird korrekt angezeigt.
- Health-/Power-Fill, Klassen- und Powerfarben, `[levelcolor][level] [smartclass]`, 3D-Portrait.
- Blizzard-PlayerFrame wird ausgeblendet, PetFrame bleibt (gewollt).
- `/fuf unlock` zeigt alle Frames mit dem Spieler als Platzhalter.
- Begleiter-Zufriedenheit über `C_PetInfo.GetPetHappiness` (Leistenfarbe gelb/grün gesehen).
- Aura-Container: Füttern-Buff am Begleiter mit Restzeit vom Client („17 s“).
- Eigene TGA-Texturen laden aus `Interface\AddOns\FUF\Media`.

## Bekannte Beta-Risiken
- **SavedVariables:** Die Beta lädt accountweite SVs nach einem Kaltstart oft nicht und überschreibt
  sie dann mit Standards. Prüfen, ob `## SavedVariablesPerCharacter` oder `## SavedVariablesMachine`
  zuverlässiger ist *(TODO(beta))*.
- Noch zu testen: Frames im Kampf (keine Lua-Fehler), `/fuf lock`, Positionen nach Neustart.
- `UnitRace` kann den Beta-Client einfrieren und wird deshalb nicht verwendet.

## Nicht machbar (Forever)
Energie-/MP5-Ticker, rechnende Heil-Tags (`[healhp]`, `[healmishp]`, `[healerhealth]`), Einzelheilungs-Tags
(`[numheals]`, `[incownheal]`, `[hotheal]` …), Teilnamen-Aurenfilter und „fehlender Buff“ im Kampf,
`[race]`, `[server]`, `[enumtargeting]`, `[buffcount]` im Kampf, `[healthcolor]` als Inline-Farbe.
