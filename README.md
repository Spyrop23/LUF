# Lizzarick's Unit Frames

Unit Frames im Stil von **Luna Unit Frames** für **World of Warcraft: Forever**
(Client 1.60.1, `## Interface: 16001`). Ohne fremde Libraries.

Luna selbst lässt sich nicht portieren. Forever ist technisch ein Retail-Client mit den
Midnight-Addon-Sperren (Secret Values, kein Combat Log). Lizzarick's Unit Frames übernimmt deshalb Aussehen und
Bedienung von Luna, ist intern aber neu und Secret-sicher gebaut. Die Funktionsbeschreibung
und die Machbarkeit pro Feature stehen in [docs/spec.md](docs/spec.md).

## Installation

Hinweis: Bis 0.7.1 hieß das Addon „FUF – Forever Unit Frames“ (Ordner `FUF`). Den alten Ordner
`AddOns/FUF` löschen; die Einstellungen von damals werden nicht übernommen.


**Am einfachsten:** Unter **Releases → Lizzarick's Unit Frames (latest)** die Datei `LizzaricksUnitFrames.zip` laden und direkt nach
`World of Warcraft/_classic_beta_/Interface/AddOns/` entpacken. Sie wird bei jedem Push neu gebaut.

**Oder über „Code → Download ZIP“:** Im Zip liegt ein Ordner `FUF-main`. Aus ihm nur den inneren
Ordner **`LizzaricksUnitFrames`** nach `…/Interface/AddOns/` kopieren.

Richtig ist es, wenn die Datei hier liegt: `…/Interface/AddOns/LizzaricksUnitFrames/LizzaricksUnitFrames.toc`.
Einen Ordner, der anders heißt als `LizzaricksUnitFrames` (zum Beispiel `FUF-main`), zeigt WoW nicht an.

## Repo-Aufbau

```
LizzaricksUnitFrames/   das Addon (dieser Ordner kommt nach Interface/AddOns), Texturen in Media/
docs/       Spezifikation (Luna-Recherche) und Roadmap
tools/      Smoke-Test und Paket-Skript
```

## Bedienung

- **Minimap-Button** (Mondsymbol): Linksklick öffnet das Menü, Rechtsklick entsperrt (unlock) oder sperrt
  die Frames zum Verschieben, Ziehen verschiebt den Button.
- Das Menü öffnet sich auch über das Addon-Menü am Minimap-Rand, über Optionen → AddOns → Lizzarick's Unit Frames und mit `/lzuf` (oder `/lizuf`).

| Befehl | Wirkung |
|---|---|
| `/lzuf` | Optionsmenü öffnen/schließen |
| `/lzuf unlock` | Config-Mode: alle Frames zeigen und mit der linken Maustaste verschieben |
| `/lzuf lock` | Config-Mode beenden (passiert beim Kampfbeginn automatisch) |
| `/lzuf profile [name]` | Profil anzeigen oder wechseln (neue Namen werden angelegt) |
| `/lzuf reset` | aktuelles Profil auf Standard zurücksetzen |
| `/lzuf tags` | Tag-Übersicht im Menü |

## Stand (0.9.0)

- **Frames:** Spieler, Begleiter, Ziel des Begleiters, Ziel, Ziel des Ziels, Ziel von dessen Ziel,
  Gruppe (party1–4), die Begleiter der Gruppenmitglieder und **Raid** (40 Frames, eine Spalte pro
  Raidgruppe), jeweils im Luna-Standardlayout. Die Gruppe blendet sich im Raid auf Wunsch aus.
  Raid-Raster einstellbar: Mitglieder untereinander oder nebeneinander, Gruppen pro Reihe, oder jede
  Gruppe einzeln verschiebbar. Beim Ziehen bewegt sich die ganze Gruppe bzw. der ganze Raid mit.
- **Status-Symbol** am Spieler wie bei Luna: gekreuzte Schwerter im Kampf, animiertes „Zzz“ beim
  Ausruhen (Größe und Position einstellbar). Dazu die Tags `[combat]`, `[combatcolor]` und `[resting]`.
- **Reichweite:** Gruppe, Gruppen-Begleiter und Raid werden außer Reichweite transparent (Standard 0.4).
- **XP-Leiste** für Spieler (lila, erholter Teil blau) und Begleiter, mit Tags `[xp] [percxp]`
  und `[xppet] [percxppet]`.
- **Leisten:** Lebens- und Ressourcenbalken (Farbe nach Klasse, Reaktion, Gesundheit oder fest),
  3D/2D-Portrait, Zauberleiste für Spieler, Ziel und Gruppe, auch bei Gegnern.
- **15 eigene Leisten-Texturen** ohne Streifen, dazu Blizzard/Raid/Flat.
  Übersicht: [docs/textures.png](docs/textures.png)
- **Buffs und Debuffs** für Spieler, Begleiter, Ziel, Gruppe und Gruppen-Begleiter, auch im Kampf.
  Sie laufen über Blizzards Aura-Container, mit Tooltip, Restzeit, Stapelzahl und Debuff-Rahmen
  nach Typ. Filter: alle / nur eigene / wirkbare bzw. bannbare. Position, Größe und Anzahl sind
  einstellbar. Standard: an bei Begleiter und Ziel, Debuffs bei der Gruppe.
- **Eingehende Heilung** wie bei Luna: eigene dunkelgrün, fremde hellgrün, dazu Schilde (Absorbs).
  Die Anzeige darf über die Leiste hinausragen (einstellbar bis 130 %). Die Werte berechnet Blizzards
  Heal-Prediction-Rechner.
- **Begleiter-Zufriedenheit** wie bei Luna: Lebensleiste rot/gelb/grün, Tags
  `[happiness]` und `[loyalty]`.
- **Tags:** 30 Luna-Tags auf drei Textfeldern pro Leiste, siehe Tag-Seite im Menü.
- **Menü:** pro Frame an/aus, Breite, Höhe, Skalierung, Position, Gruppenabstand, Leisten-Farben,
  -Höhen und -Hintergrund, Portrait, Zauberleiste, Texte und Schriftgröße. Dazu Textur,
  Hintergrund, Profile (anlegen, wechseln, kopieren, löschen, zurücksetzen) und die Tag-Hilfe.
- **Blizzard-Frames** werden auf Wunsch ausgeblendet, auch Blizzards Zauberleiste.

Etappen und offene Punkte: [docs/roadmap.md](docs/roadmap.md).

## Entwicklung

- Regeln für den Code: [CLAUDE.md](CLAUDE.md)
- Syntax-Check: `for f in $(find LizzaricksUnitFrames -name '*.lua'); do luac5.1 -p $f; done`
- Smoke-Test mit simuliertem Client. Secret Values werfen dort bei Rechnen und Vergleichen einen
  Fehler, der Test klickt alle Menüseiten durch: `lua5.1 tools/smoketest.lua`
- Test im Spiel ohne Kampf: `/console addonCombatRestrictionsForced 1` (wieder auf 0 stellen!)

## Lizenz

WTFPL wie Luna Unit Frames, auf dessen Design (Aviana) Lizzarick's Unit Frames aufbaut. Code von Luna wurde nicht übernommen.
