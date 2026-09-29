# FUF – Forever Unit Frames

Unit Frames im Stil von **Luna Unit Frames** für **World of Warcraft: Forever**
(Client 1.60.1, `## Interface: 16001`). Ohne fremde Libraries.

Luna selbst lässt sich nicht portieren. Forever ist technisch ein Retail-Client mit den
Midnight-Addon-Sperren (Secret Values, kein Combat Log). FUF übernimmt deshalb Aussehen und
Bedienung von Luna, ist intern aber neu und Secret-sicher gebaut. Die Funktionsbeschreibung
und die Machbarkeit pro Feature stehen in [docs/spec.md](docs/spec.md).

## Installation

**Am einfachsten:** Unter **Releases → FUF latest** die Datei `FUF.zip` laden und direkt nach
`World of Warcraft/_classic_beta_/Interface/AddOns/` entpacken. Sie wird bei jedem Push neu gebaut.

**Oder über „Code → Download ZIP“:** Im Zip liegt ein Ordner `FUF-main`. Aus ihm nur den inneren
Ordner **`FUF`** nach `…/Interface/AddOns/` kopieren.

Richtig ist es, wenn die Datei hier liegt: `…/Interface/AddOns/FUF/FUF.toc`.
Einen Ordner, der anders heißt als `FUF` (zum Beispiel `FUF-main`), zeigt WoW nicht an.

## Repo-Aufbau

```
FUF/        das Addon (dieser Ordner kommt nach Interface/AddOns), Texturen in FUF/Media
docs/       Spezifikation (Luna-Recherche) und Roadmap
tools/      Smoke-Test und Paket-Skript
```

## Bedienung

- **Minimap-Button** (Mondsymbol): Linksklick öffnet das Menü, Rechtsklick entsperrt oder sperrt
  die Frames zum Verschieben, Ziehen verschiebt den Button.
- Das Menü öffnet sich auch über das Addon-Menü am Minimap-Rand, über Optionen → AddOns → FUF und mit `/fuf`.

| Befehl | Wirkung |
|---|---|
| `/fuf` | Optionsmenü öffnen/schließen |
| `/fuf unlock` | Config-Mode: alle Frames zeigen und mit der linken Maustaste verschieben |
| `/fuf lock` | Config-Mode beenden (passiert beim Kampfbeginn automatisch) |
| `/fuf profile [name]` | Profil anzeigen oder wechseln (neue Namen werden angelegt) |
| `/fuf reset` | aktuelles Profil auf Standard zurücksetzen |
| `/fuf tags` | Tag-Übersicht im Menü |

## Stand (0.3.1)

- **Frames:** Spieler, Begleiter, Ziel des Begleiters, Ziel, Ziel des Ziels, Ziel von dessen Ziel,
  Gruppe (party1–4) und die Begleiter der Gruppenmitglieder, jeweils im Luna-Standardlayout.
- **Leisten:** Lebens- und Ressourcenbalken (Farbe nach Klasse, Reaktion, Gesundheit oder fest),
  3D/2D-Portrait, Zauberleiste für Spieler, Ziel und Gruppe, auch bei Gegnern.
- **Eigene Leisten-Texturen** ohne Streifen (Smooth, Minimalist, Gloss), dazu Blizzard/Raid/Flat.
- **Begleiter-Zufriedenheit** wie bei Luna: Lebensleiste rot/gelb/grün, Gesicht-Icon, Tags
  `[happiness]` und `[loyalty]`.
- **Tags:** 30 Luna-Tags auf drei Textfeldern pro Leiste, siehe Tag-Seite im Menü.
- **Menü:** pro Frame an/aus, Breite, Höhe, Skalierung, Position, Gruppenabstand, Leisten-Farben,
  -Höhen und -Hintergrund, Portrait, Zauberleiste, Texte und Schriftgröße. Dazu Textur,
  Hintergrund, Profile (anlegen, wechseln, kopieren, löschen, zurücksetzen) und die Tag-Hilfe.
- **Blizzard-Frames** werden auf Wunsch ausgeblendet, auch Blizzards Zauberleiste.

Etappen und offene Punkte: [docs/roadmap.md](docs/roadmap.md).

## Entwicklung

- Regeln für den Code: [CLAUDE.md](CLAUDE.md)
- Syntax-Check: `for f in $(find FUF -name '*.lua'); do luac5.1 -p $f; done`
- Smoke-Test mit simuliertem Client. Secret Values werfen dort bei Rechnen und Vergleichen einen
  Fehler, der Test klickt alle Menüseiten durch: `lua5.1 tools/smoketest.lua`
- Test im Spiel ohne Kampf: `/console addonCombatRestrictionsForced 1` (wieder auf 0 stellen!)

## Lizenz

WTFPL wie Luna Unit Frames, auf dessen Design (Aviana) FUF aufbaut. Code von Luna wurde nicht übernommen.
