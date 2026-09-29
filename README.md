# FUF – Forever Unit Frames

Unit Frames im Stil von **Luna Unit Frames** für **World of Warcraft: Forever**
(Client 1.60.1, `## Interface: 16001`). Ohne fremde Libraries.

Luna selbst lässt sich nicht portieren. Forever ist technisch ein Retail-Client mit den
Midnight-Addon-Sperren (Secret Values, kein Combat Log). FUF übernimmt deshalb Aussehen und
Bedienung von Luna, ist intern aber neu und Secret-sicher gebaut. Die Funktionsbeschreibung
und die Machbarkeit pro Feature stehen in [docs/spec.md](docs/spec.md).

## Installation

1. Das fertige Paket laden: auf GitHub unter **Actions → package → neuester Lauf → Artifacts → FUF**
   (oder selbst bauen mit `sh tools/package.sh`, ergibt `dist/FUF.zip`).
2. Entpacken nach `World of Warcraft/_classic_beta_/Interface/AddOns/`, sodass die Datei hier liegt:
   `…/Interface/AddOns/FUF/FUF.toc`
3. **Der Ordner muss exakt `FUF` heißen.** Der „Download ZIP“-Knopf von GitHub erzeugt `FUF-main`.
   Einen so benannten Ordner zeigt WoW nicht an.

## Befehle

| Befehl | Wirkung |
|---|---|
| `/fuf unlock` | Config-Mode: alle Frames zeigen und mit der linken Maustaste verschieben |
| `/fuf lock` | Config-Mode beenden (passiert beim Kampfbeginn automatisch) |
| `/fuf profile [name]` | Profil anzeigen oder wechseln (neue Namen werden angelegt) |
| `/fuf reset` | aktuelles Profil auf Standard zurücksetzen |
| `/fuf tags` | verfügbare Tags auflisten |

## Stand (Etappe 1)

- Frames: player, target, targettarget, targettargettarget im Luna-Standardlayout
- Health- und Power-Bar (Farbe nach Klasse, Reaktion, statisch oder Gesundheit), 3D/2D-Portrait
- Tag-System mit 3 Texten pro Leiste: `[name] [level] [levelcolor] [classification]
  [shortclassification] [class] [smartclass] [creature] [classcolor] [reactcolor] [nocolor]
  [hp] [maxhp] [missinghp] [perhp] [smarthealth] [smarthealthp] [status] [pp] [maxpp]
  [missingpp] [perpp]`
- Blizzard-Frames für player/target/ToT werden ausgeblendet
- Profile pro Charakter, Config-Mode

Etappen und offene Punkte: [docs/roadmap.md](docs/roadmap.md).

## Entwicklung

- Regeln für den Code: [CLAUDE.md](CLAUDE.md)
- Syntax-Check: `for f in $(find . -name '*.lua'); do luac5.1 -p $f; done`
- Smoke-Test mit simuliertem Client (Secret Values werfen bei Rechnen und Vergleichen):
  `lua5.1 tools/smoketest.lua`
- Test im Spiel ohne Kampf: `/console addonCombatRestrictionsForced 1` (wieder auf 0 stellen!)

## Lizenz

WTFPL wie Luna Unit Frames, auf dessen Design (Aviana) FUF aufbaut. Code von Luna wurde nicht übernommen.
