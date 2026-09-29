# Luna Unit Frames – Funktionsbeschreibung für den Nachbau in WoW: Forever

Stand: 29.09.2026 · Grundlage: Luna Classic 4330 (Aviana, `## Interface: 11403`, Branch `classic`), Classic-Fix 4434 (pileopoop/caboyd), CurseForge-Kommentare, Guides, Forever-Forschungsbericht von VuloForeverUI (Stand 23.09.2026).

**Methodik:** Standardwerte, Wertebereiche und Dropdown-Optionen stammen direkt aus `modules/defaults.lua`, `modules/Options.lua` und `locales/enUS.lua` (nur gelesen, nicht kopiert). Was ich nicht im Quelltext oder in einer Quelle belegen konnte, ist mit *(unbestätigt)* markiert. Forever-Aussagen sind Beta-Stand (Build 1.60.1.699xx) und können sich bis zum Release am 04.11.2026 ändern.

---

## A) Frames: Übersicht und Standard-Layout

Alle Größen in Pixeln (vor Skalierung). Anker = Frame, an dem der Frame hängt. Skalierung überall 1 (Slider 0,5–3).

| Frame | Standard an? | Breite × Höhe | Anker / Position | Besonderheiten |
|---|---|---|---|---|
| player | ✅ | 240 × 40 | TOPLEFT an UIParent, x 10 / y −15 | Referenz für fast alle anderen |
| pet | ✅ | 240 × 30 | unter player (BOTTOMLEFT, y −55) | Farbe nach Pet-Zufriedenheit, XP-Bar an |
| pettarget | – | 100 × 30 | rechts neben pet (x +250) | |
| pettargettarget | – | 100 × 30 | rechts neben pettarget | |
| target | ✅ | 240 × 40 | rechts neben player (x +250) | Combo Points an, rechter Text `[smarthealthp]` |
| targettarget (ToT) | ✅ | 150 × 40 | rechts neben target | kein Portrait |
| targettargettarget (ToToT) | ✅ | 150 × 40 | rechts neben ToT (x +160) | kein Portrait |
| party | ✅ | 240 × 40 | unter pet, Abstand zwischen Einheiten 40 | Header; Wachstum nach unten, Sortierung Index aufsteigend, „Im Raid ausblenden: nie“, Spieler nicht anzeigen, solo nicht anzeigen |
| partytarget | – | 100 × 20 | rechts neben party | Text mittig `[smarthealth]` |
| partypet | ✅ | 100 × 20 | rechts neben party (y −20) | Text mittig `[smarthealth]` |
| raid | ✅ | 60 × 30 | 8 Gruppen-Header (raid1–raid8), je eigene Position | gruppiert nach Gruppe, 5 Gruppen pro Reihe, Wachstum nach oben (BOTTOM), Health- und Power-Bar **vertikal**, Power-Bar rechts in schmalem Slot, Text `[nameafk][br][healerhealth]`, Schrift 8 |
| raidpet | – | 60 × 30 | rechts neben raid8 | |
| maintank (+target, +targettarget) | – | je 100 × 30 | mitte, x −110; Ziele jeweils +110 rechts | Filter „MAINTANK“, 5 pro Spalte, Abstand 4 |
| mainassist (+target, +targettarget) | – | je 100 × 30 | mitte, x +110 | Filter „MAINASSIST“ |

Die Locale enthält auch Einträge für focus/arena – diese Frames sind in Classic aber nicht aktiv (kein Fokus in Classic Era). **Für Forever:** Focus existiert in der Mainline-UI *(unbestätigt, ob Forever `focus` zulässt – Forever Unit Frames bietet einen Focus-Frame, also sehr wahrscheinlich ja)*.

**Standard-Aufbau eines Frames (player):** von oben nach unten gestapelt, Höhe als relative Gewichte: Health 6 → Power 4,5 → Castbar 3 (nur beim Zaubern) → Reckoning 2; links ein 3D-Portrait (22 % Breite). Texte: Health links `[name]`, rechts `[smarthealth]`; Power links `[levelcolor][level][shortclassification] [classcolor][smartclass]`, rechts `[pp]/[maxpp]`; Castbar links `[castname]`, rechts `[casttime]`.

---

## B) Elemente pro Frame und alle Einstellungen

Legende Typ: **T** = Schalter, **S** = Slider (min–max, Schritt), **D** = Dropdown, **E** = Eingabefeld, **F** = Farbwähler. Standardwerte für den player-Frame, sofern nicht anders angegeben.

### B1 Frame allgemein (je Frame)
| Einstellung | Typ | Bereich / Werte | Standard |
|---|---|---|---|
| Aktivieren | T | | player an |
| Höhe | S | 10–600, 1 | 40 |
| Breite | S | 20–600, 1 | 240 |
| Skalierung | S | 0,5–3, 0,01 | 1 |
| Anker an (Anchor To) | D | UIParent oder jeder andere Luna-Frame/Header | UIParent |
| X / Y Position | E | Zahl | 10 / −15 |
| Bars: Stapelung | D | vertikal / horizontal | vertikal |
| Bars: Breite der Seiten-Slots | S | 1–10, 0,1 | 10 |
| Zielwechsel-Sound (nur target) | T | | *(Standard unbestätigt)* |

**Bar-Slots:** Jede Leiste gehört zu einer „Bar Group“ (links / mitte / rechts). Die mittlere Gruppe stapelt vertikal, die Seitengruppen horizontal. Innerhalb einer Gruppe bestimmt „Order“ (0–100, Schritt 5) die Reihenfolge; die Höhe ist ein relatives Gewicht (1–10).

### B2 Health-Bar
| Einstellung | Typ | Werte | Standard |
|---|---|---|---|
| Aktivieren | T | | an |
| Hintergrund | T | | an |
| Hintergrund-Alpha | S | 0–1, 0,01 | 0,2 |
| Farbe nach Typ | D | Klasse / Statisch / Gesundheit in % (pet: Zufriedenheit / Statisch / %) | Klasse (pet: Zufriedenheit) |
| Farbe nach Reaktion | D | Nie / Nur Spieler / Nur NPCs / Beide | Nur NPCs |
| Höhe (Gewicht) | S | 1–10, 0,1 | 6 (raid 10) |
| Order | S | 0–100, 5 | 10 |
| Bar-Textur | D | LibSharedMedia | „Minimalist“ (global) |
| Vertikal | T | | aus (raid an) |
| Bar Group | D | Links / Rechts / Mitte | Mitte |
| Invertieren | T | „kehrt das Farbschema um“ (Bar leer bei 100 %) | aus |

### B3 Power-Bar
Wie Health-Bar, zusätzlich:
| Einstellung | Typ | Standard |
|---|---|---|
| Farbe nach Typ: Klasse / Power-Typ | D | Power-Typ |
| Ticker (Energie-/Mana-Tick-Timer) | T | *(unbestätigt)* |
| Ticker automatisch ausblenden | T | *(unbestätigt)* |
| Fünf-Sekunden-Regel anzeigen | T | *(unbestätigt)* |
| Höhe | S 1–10 | 4,5 (raid 1, Slot rechts, vertikal) |

### B4 Manakosten-Vorschau (Mana Prediction, nur player)
Aktivieren (T, aus), Farbe (F, weiß mit Alpha 0,5). Zeigt beim Zaubern den Teil der Manabar, der verbraucht wird.

### B5 Castbar (player, target, party, raid, maintank, mainassist)
| Einstellung | Typ | Werte | Standard |
|---|---|---|---|
| Aktivieren | T | | player/target an, party/raid aus |
| Automatisch ausblenden | T | | an |
| Zauber-Icon | D | Verstecken / Links / Rechts | Verstecken |
| Höhe | S | 1–10 | 3 |
| Order | S | 0–100 | 60 |
| Textur, Bar Group | D | | |
Farben global: Zaubern orange (1 / 0,7 / 0,3), Kanalisieren blau (0,25 / 0,25 / 1).

### B6 Empty Bar (Leerleiste)
Aktivieren (aus), Deckkraft (0–1, 0,2), Farbe nach Reaktion (D: Nie / Nur Spieler / NPCs und feindliche Spieler / Nur NPCs / Beide), Klassenfarbe (T, an), Höhe 3, Order 50, Textur, vertikal, Bar Group. Zweck: Abstandshalter oder Träger für zusätzliche Tags.

### B7 Portrait
| Einstellung | Typ | Werte | Standard |
|---|---|---|---|
| Aktivieren | T | | player/pet/target/party an |
| Status anzeigen | T | Status (tot/offline …) mit Cooldown-Animation auf dem Portrait | *(unbestätigt)* |
| Ausführlicher Status | T | mehr Status-Arten | *(unbestätigt)* |
| Typ | D | 3D / 2D / Klassen-Icon / 2D-Klasse | 3D |
| Ausrichtung | D | Links / Rechts / **Bar** (Portrait als Leiste im Stapel) | Links |
| Breite | S | 0–1 (Anteil der Frame-Breite), 0,01 | 0,22 |
| Höhe (im Bar-Modus) | S | 1–10 | 4 |
| Order, Bar Group | | | 15 |

### B8 Heilvorhersage (Incoming heals)
Aktivieren (T, player/target an), Überwachs-Grenze (S 1–1,3: Vorhersage darf über die Bar hinausragen, Standard 1,3), Deckkraft (S 0–1, 0,8). Farben: eingehende Heilung grün, eigene Heilung dunkelgrün, HoTs hellgrün.

### B9 Auren (Buffs/Debuffs)
| Einstellung | Typ | Werte | Standard |
|---|---|---|---|
| Waffenbuffs | T | | aus (nur player) |
| Rahmenfarbe nach Typ | T | Magie/Fluch/Gift/Krankheit | an |
| Abstand zwischen Icons | S | 0–10 | 0 |
| Timer | D | Alle / Eigene / Keine | Alle |
| Buffs anzeigen | T | | aus |
| Buffs filtern | D | Aus / Eigene / Klasse (von deiner Klasse wirkbar) | Aus |
| Buff-Größe | S | 4–50 | 18 (raid 10) |
| Größere (eigene) Buffs | S | 0–20 (Pixel zusätzlich) | 4 (player), sonst 0 |
| Position | D | Links / Rechts / Oben / Unten / Im Frame / Im Frame mittig | Unten (raid: Im Frame) |
| Y-Versatz | S | −50–50 | 0 |
| Seite der horizontalen Begrenzung | D | Links / Rechts | Rechts |
| Horizontale Begrenzung | S | 0,2–1,5 (Anteil der Frame-Breite) | 1 |
| Max. Anzahl Buffs | S | 1–32 | 32 |
| Debuffs anzeigen | T | | aus |
| Debuffs filtern | D | Aus / Eigene / Bannbar | Aus |
| Debuff-Größe, größere Debuffs, Position, Versatz, Begrenzung | wie Buffs | | |
| Max. Anzahl Debuffs | S | 1–40 | 40 |

Global: Aurenrahmen-Stil (Keiner / Blizzard / Hell / **Dunkel** / Schwarz / je „dünn“), Auren im Vorschau-Modus maximal zeigen (an).

### B10 Rahmen (Borders) und Highlight
Beides mit denselben Auslösern: bei Ziel (T), bei Mouseover (T), bei Aggro (T), bei Debuff (D: Aus / Eigene bannbare / Alle; Standard „Eigene“). Rahmen zusätzlich Größe 1–10 (Standard 1). Farben: Ziel (0,75 / 0,75 / 0,35), Mouseover (0,75 / 0,75 / 0,5), Debuff nach Typfarbe.

### B11 Kampf-Fader
Aktivieren (aus), Alpha im Kampf (1), Alpha inaktiv (0,2), schnelles Ein-/Ausblenden (aus). „Aktiv“ ist der Frame bei: Kampf, eigener Zauber, Power nicht voll, **Health nicht voll**, player hat ein Ziel.

### B12 Reichweite
Pro Frame an/aus (Standard aus außer player). Global: Distanz (Inspizier-Distanz 10 m / Folge-Distanz 30 m / zauberbasiert 40 m / sichtbar 100 m), Alpha außerhalb 0,4.

### B13 Indikatoren (je Größe, Ankerpunkt aus 9 Punkten, X −50…50, Y −100…100)
| Indikator | player-Standard |
|---|---|
| Raid-Zielmarkierung | an, CENTER, 20 |
| Klassen-Icon | aus, BOTTOMLEFT, 16 |
| Plündermeister | an, TOPLEFT, 12 |
| Anführer | an, TOPLEFT, 14 |
| PvP-Flagge | an, LEFT, 30 |
| PvP-Rang | *(Standard unbestätigt)* |
| Bereitschaftscheck | an, LEFT, 24 |
| Spielerstatus (Kampf/Ausruhen) | an, BOTTOMLEFT, 16 |
| Wiederbelebung | an, LEFT, 20 |
| Pet-Zufriedenheit (nur pet) | an |
| Elite/Rare-Rahmen | aus; Seite Links/Rechts, Typ elite/rare |
| Rolle (Raid-Rolle) | aus, TOPLEFT, 12 |

### B14 Combat Text (auf dem Portrait/Frame)
Aktivieren (aus), Schrift (D), Größe (S 5–40, Standard 15). Technisch über das Event **UNIT_COMBAT** (nicht über das Combat Log).

### B15 Squares (9 Indikator-Quadrate)
Positionen: oben links, oben, oben rechts, links mittig, Mitte, rechts mittig, unten links, unten, unten rechts. Je Quadrat:
| Einstellung | Typ | Werte | Standard |
|---|---|---|---|
| Aktivieren | T | | aus |
| Größe | S | 4–40 | 10 (Mitte/Seiten 15) |
| Typ | D | Aggro / Aggro (ToT-basiert) / Buff/Debuff / eigener Buff/Debuff / Bannbar / Fehlender Buff | Aggro |
| Name oder ID | E | bei Buff/Debuff: Teilname oder ID, mehrere mit `;` getrennt; bei „fehlend“: exakter Name, `;` = UND, `/` = ODER, `[mana]` = nur Manaklassen (z. B. `Arcane Intellect[mana]/Arcane Brilliance[mana];Dampen Magic`) | leer |
| Timer | T | | |
| Textur statt Typfarbe | T | Zauber-Icon statt Farbe | |
| X / Y Versatz | S | −50–50 | 0 |

Bekanntes Problem: Squares mit vielen Teilnamen-Filtern verursachen Ruckler im 25er-Raid; der Classic-Fix empfiehlt „Exact“-Matching statt „Partial“.

### B16 Zusatzleisten
- **XP-Bar** (player/pet): aus (pet an); Hintergrund, Alpha, Höhe 2, Order 80, Deckkraft 1, **Maus-Interaktion** (Tooltips statt Klicks), auto-hide; Tag `[xp] [percxp]`; Farben normal lila, ausgeruht blau; zeigt auf Max-Level den beobachteten Ruf.
- **Druiden-Manabar** (player): aus; auto-hide; Höhe 3; Tag `[druid:pp]/[druid:maxpp]`.
- **Totem-Bar** (player): aus; Höhe 2, auto-hide; Classic-Fix ergänzt Timer und eigene Farben.
- **Combo Points** (target): an; auto-hide „wenn inaktiv“; Wachstum links/rechts; Höhe 2.
- **Reckoning-Stapel** (player, Paladin): an, auto-hide, Wachstum rechts, Höhe 2 (liest Aura-Stapel über UNIT_AURA).

### B17 Party-, Raid- und Tank-Header
- Party: Abstand 0–200 (40), Wachstum (links/rechts/oben/unten), im Raid ausblenden (nie / Raid > 5 / jeder Raid), Sortierung Index/Name, Reihenfolge auf-/absteigend, Spieler anzeigen, solo anzeigen.
- Raid: gruppieren nach Gruppe/Klasse, anzeigen wenn (immer / Gruppe / Raid), bei < 6 Spielern ausblenden, Gruppennummern (Schriftgröße 1–20, eigene Schrift), jede der 8 Gruppen einzeln aktivierbar und positionierbar, Einheiten pro Spalte 1–40, max. Spalten 1–40, Spaltenabstand 0–200, Spalten-Wachstumsrichtung.
- Maintank/Mainassist: Limit 1–40.

### B18 Globale Einstellungen
Sperren (Config-Mode aus/an), Auren-Vorschau, Tooltip im Kampf (an), Aurenrahmen-Stil, Heilvorhersage-Zeitfenster (3–21 s, Standard 4), HoTs in Vorhersage deaktivieren, OmniCC-Zahlen unterdrücken, Blizzard-Cooldown-Zahlen unterdrücken, Frame-Strata (BACKGROUND … TOOLTIP, Standard MEDIUM), Reichweite (siehe B12), globale Textur „Minimalist“, Schriftschatten an.

---

## C) Tag-System

Jede Leiste (top, healthBar, powerBar, castBar, emptyBar, druidBar, xpBar, bottom) hat drei Textfelder links/mitte/rechts. Pro Feld: Tag-Zeile (E), Limit 1–100 % (wo der Text abgeschnitten wird), Versatz −20…20. Pro Leiste: Schriftgröße 5–24, Schrift, Schatten, Umriss. Tags werden in eckigen Klammern kombiniert, z. B. `[levelcolor][level][shortclassification] [classcolor][smartclass]` → „<gelb>60E</> <klassenfarbe>Krieger“.

### C1 Info-Tags
| Tag | Bedeutung | Beispiel |
|---|---|---|
| `[name]` | Name | Thrall |
| `[nameafk]` | Name oder „(AFK)“ | (AFK) |
| `[shortname:x]` | erste x Buchstaben (1–12) | `[shortname:4]` → Thra |
| `[abbrev:name]` | abgekürzt | M. Williams |
| `[afk]` / `[afktime]` | „(AFK)“ / AFK-Dauer | 3:12 |
| `[br]` | Zeilenumbruch | |
| `[grpnum]` | Nummer in der Gruppe | 3 |
| `[group]` | Raid-Untergruppe | 2 |
| `[numtargeting]` / `[cnumtargeting]` | Gruppenmitglieder, die diese Einheit anvisieren (farbig) | 4 |
| `[enumtargeting]` | geschätzte Gegner, die die Einheit anvisieren (nur PvP) | 2 |
| `[guild]` / `[guildrank]` | Gilde / Rang | |
| `[level]` / `[smartlevel]` | Level (?? bei Bossen) / „Boss“ bzw. „Level+10+“ | 60 / Boss |
| `[class]` / `[smartclass]` | Klasse / Klasse bei Spielern, Kreaturtyp bei NPCs | Magier / Humanoid |
| `[race]` / `[smartrace]` / `[creature]` / `[sex]` | Rasse / Rasse oder Kreaturtyp / Kreaturtyp / Geschlecht | |
| `[rare]` / `[elite]` / `[classification]` / `[shortclassification]` | Einstufung | rare / elite / „E“, „R“, „RE“ |
| `[druidform]` | aktuelle Druidengestalt (freundlich) | Bär |
| `[civilian]` / `[pvp]` / `[rank]` / `[numrank]` / `[faction]` | PvP-Infos | „PvP“, Rangtitel, 7, Horde |
| `[ignore]` / `[server]` / `[status]` | ignoriert / Server / „Tot“, „Geist“, „Offline“ | |
| `[happiness]` / `[loyalty]` | Pet-Zufriedenheit / Pet-Loyalität | zufrieden |
| `[combat]` | „(Kampf)“ im Kampf | |
| `[buffcount]` | Anzahl positiver Effekte | 7 |
| `[range]` | Entfernung | 28 |
| `[castname]` / `[casttime]` | Zaubername / Restzeit | Frostblitz / 1.4 |
| `[xp]` / `[percxp]` / `[xppet]` / `[percxppet]` | XP absolut / % | 12345/45000 / 27 % |
| `[rep]` | Ruf der beobachteten Fraktion | |
| `[threat]` | Bedrohung in skalierten % | 87 % |

### C2 Health- und Power-Tags
| Tag | Bedeutung |
|---|---|
| `[hp]` / `[maxhp]` / `[shp]` / `[smaxhp]` | Leben / max. Leben / gekürzt ab 1K |
| `[missinghp]` | fehlendes Leben |
| `[perhp]` | Leben in % |
| `[smarthealth]` | klassisch hp/maxhp, bei Tod „Tot“ usw. |
| `[smarthealthp]` | wie smarthealth plus Prozent |
| `[ssmarthealth]` / `[ssmarthealthp]` / `[sshp]` | gekürzte Varianten |
| `[perstatus]` | wie smarthealth, aber nur Prozent |
| `[healhp]` | Leben + eingehende Heilung als eine Zahl (grün bei Heilung) |
| `[healmishp]` | fehlendes Leben nach eingehender Heilung |
| `[smart:healmishp]` | wie healmishp, mit Status |
| `[healerhealth]` | freundlich: smart:healmishp, feindlich: hp/maxhp |
| `[namehealerhealth]` | wie healerhealth, bei vollem Leben der Name |
| `[pp]` / `[maxpp]` / `[spp]` / `[smaxpp]` / `[missingpp]` / `[perpp]` | Power analog |
| `[druid:pp]` / `[druid:maxpp]` / `[druid:missingpp]` / `[druid:perpp]` | Druidenmana in Gestalt |
| `[cpoints]` | Combo Points |
| `[incheal]` / `[numheals]` | eingehende Heilung / Anzahl |
| `[incownheal]` / `[incpreheal]` / `[incafterheal]` | eigene / vor deiner landende / nach deiner landende Heilung |
| `[hotheal]` | was aktive HoTs im Zeitfenster heilen |
| `[effheal]` / `[overheal]` | effektive Heilung / Überheilung |

### C3 Farb-Tags
`[combatcolor]` (rot im Kampf), `[pvpcolor]`, `[reactcolor]`, `[levelcolor]` (grau/grün/gelb/rot nach Levelabstand), `[aggrocolor]` (rot bei Aggro), `[classcolor]`, `[healthcolor]` (nach Leben), `[color:rrggbb]` (eigene Hexfarbe), `[nocolor]` (zurück auf weiß).

---

## D) Aussehen

- **Stil:** flach und minimalistisch, im Stil von Shadowed Unit Frames. Rechteckige Frames ohne Blizzard-Ornamente. Der Frame-Hintergrund ist die Tooltip-Hintergrundtextur, schwarz mit Alpha 0,8 und 1 px Rand. Die Leisten liegen direkt übereinander, ohne Abstand.
- **Leistentextur:** „Minimalist“ (eigene, glatte Textur mit ganz leichtem Verlauf). Hintergrund = dieselbe Textur in der Leistenfarbe mit Alpha 0,2, deshalb bleibt fehlendes Leben als dunkle Version der Klassenfarbe sichtbar.
- **Schriften:** Standard ist die Spielschrift mit Schatten. Mitgeliefert und über LibSharedMedia registriert: Aldrich, Bangers, FasterOne, Iceland, Inconsolata, Metal Lord, Myriad, Optimus, Trade Winds, Vera Serif.
- **Aurenrahmen:** 7 Rahmentexturen (dark, light, black, jeweils auch dünn, dazu none). Standard ist „dark“.
- **Klassenfarben (Luna-Standard):** Jäger 0,67/0,83/0,45 · Hexenmeister 0,58/0,51/0,79 · Priester 1/1/1 · Paladin 0,96/0,55/0,73 · Magier 0,41/0,8/0,94 · Schurke 1/0,96/0,41 · Druide 1/0,49/0,04 · Schamane 0,14/0,35/1 (blau) · Krieger 0,78/0,61/0,43.
- **Power:** Mana 0,30/0,50/0,85 · Wut 0,90/0,20/0,30 · Fokus 1/0,5/0,25 · Energie 1/0,85/0,10 · Combo Points 1/0,8/0.
- **Reaktion:** feindlich 0,8/0,3/0,22 · unfreundlich 0,75/0,27/0 · neutral 0,9/0,7/0 · freundlich bis ehrfürchtig 0/0,6/0,1. **Status:** getappt/offline grau 0,5 · Zivilist 1/0,9/0,9 · statisch lila 0,7/0,2/0,9. **Verlauf:** rot 0,9/0/0 → gelb 0,93/0,93/0 → grün 0,2/0,9/0,2.
- **Typischer Screenshot (Standard):** Oben links der Spieler-Frame (240×40) mit 3D-Portrait links. Rechts davon, bündig, folgen target und ToT/ToToT (150×40) in einer Reihe. Darunter liegt der pet-Frame mit dünner lila XP-Leiste, darunter die Party (240×40 je Mitglied) mit Party-Pets (100×20) rechts daneben. Die Raid-Frames sind kleine 60×30-Kacheln mit senkrechter Füllung, Name und Heiler-Leben mittig in Zeile 1/2 und einem schmalen senkrechten Mana-Streifen rechts.

---

## E) Bedienung

- **Slash-Befehle:** `/luna`, `/luf`, `/lunauf`, `/lunaunitframes` öffnen das Optionsfenster (895×570, AceConfig). `/luna profile <name>` wechselt das Profil. (Die Befehle `/luf menu|reset|config` stammen aus der Vanilla-1.12-Version und sind in Classic nicht belegt.)
- **Optionsbaum:** Allgemein · Farben · je Frame (player … mainassisttargettarget) · Blizzard ausblenden (player, pet, Castbar, Buffs, target, party, raid; Wiedereinblenden erst nach Reload) · Tag-Hilfe · Auto-Profile · Profile. Die Seiten werden zusätzlich ins Blizzard-Interface-Menü eingehängt.
- **Config-Mode:** Der Schalter „Sperren“ aus: Alle Frames werden mit dem Spieler als Platzhalter gezeigt (Header in voller Größe) und lassen sich ziehen. Beim Loslassen wird die Position relativ zum Anker korrigiert und im Optionsfenster aktualisiert.
- **Profile:** AceDB (Profil pro Charakter, kopieren, löschen, zurücksetzen). **Auto-Profile:** automatischer Wechsel nach Bildschirmauflösung oder Gruppengröße (Solo, Party, Raid5/10/15/20/25/40).
- **Import/Export:** Nicht vorhanden. Nutzer fragen danach, wie man Profile auf einen neuen PC bekommt; die Antwort lautet „WTF-Ordner kopieren“.
- **Clique:** Die Frames registrieren sich für Klick-Heilen. **OmniCC:** optional; Zahlen auf Cooldown-Spiralen lassen sich für OmniCC und Blizzard getrennt abschalten.
- **Rechtsklick-Menü** der Einheit (Blizzard-Dropdown).

---

## F) Was Nutzer lieben und was sie vermissen (Kommentare)

**Gelobt:** „wie Shadowed Unit Frames, nur besser“, „unterschätzt“, schnell eingerichtet und trotzdem tief konfigurierbar, Tag-System, Heilvorhersage, gegnerische Castbars, Energie-Ticker, schnelle Raid-Frames.

**Wünsche und Beschwerden:**
- Performance: Stottern im 25er-Raid (Ulduar/Naxx) durch Squares. Der Autor rät zum Abschalten der Squares oder zu BuffOverlay; der Classic-Fix hat das Aurensystem deshalb neu geschrieben.
- Updates auf neue Spielversionen; Profile auf andere Clients oder PCs übertragen (fehlender Export).
- Lange Namen überlappen die Lebenszahl (Lösung: `[shortname:x]` bzw. das Limit-Feld).
- Spieler selbst in den Raid-Frames ausblenden (für LoseControl in der Arena).
- Portrait als halbtransparentes Overlay auf der Health-Bar im ElvUI-Stil (ein Nutzer hat das als Mod gebaut).
- Gifte bei „Body and Soul“ anzeigen.
- Classic-Fix 2026: Frames laden manchmal nicht (zu langsamer Addon-Start), Positionen springen nach dem Login, die XP-Bar erscheint auf Max-Level erzwungen. Seit „Blizzard deaktiviert Nicht-Zauber-Reichweitenprüfungen im Kampf“ funktionieren Folge- und Inspizier-Distanz nicht mehr.
- **Zu Forever (pileopoop, 11 Tage alt):** Luna wird Forever nicht unterstützen, weil ein Port „praktisch ein neues Addon ohne die coolen Dinge“ wäre. Nach seiner Einschätzung ist Folgendes nicht möglich: komplexe Aurenfilter, eigene Tags mit Rechnen, geordnete eingehende Heilung (eigene/fremde) und getrennte Anzeige von HoTs und Direktheilung. Die Lizenz (WTFPL) erlaubt eine Forever-Version ausdrücklich. Ein Nutzer (kmvinny) meldet, er habe mit KI-Hilfe große Teile auf Forever umgeschrieben.

---

## G) Forever-Machbarkeit pro Feature

✅ geht · ⚠️ nur mit Secret-sicherer Umsetzung · ❌ nicht möglich (Stand Beta)

**Grundregeln aus den Messungen (VuloForeverUI, 18.–23.09.2026):** `UnitHealth`, `UnitHealthPercent` und `UnitPower` sind beim Spieler **immer** secret, auch außerhalb des Kampfes. `UnitHealthMax`, `UnitPowerMax`, `UnitThreatSituation`, Einheiten-Identität, Einstufung, Reaktion und Tapped-Status bleiben lesbar (auf „restricted maps“, also in Instanzen und PvP, kann die Identität secret sein). Auren werfen im Kampf einen Fehler. Die Felder von `UnitCastingInfo` sind bei fremden Einheiten im Kampf secret, `UnitCastingDuration` liefert aber ein lesbares Duration-Objekt. Anzeigen per `SetFormattedText`, `string.format` und `AbbreviateNumbers` mit Secrets funktioniert.

### Frames und Struktur
| Feature | | Begründung / Forever-Ersatz |
|---|---|---|
| player, target, ToT, ToToT, pet, pettarget | ✅ | normale SecureUnitButtons; ToT-Einheiten per OnUpdate-Polling wie in oUF |
| Focus-Frame (neu) | ✅ *(unbestätigt)* | bietet Forever Unit Frames an |
| party, partypet, partytarget, raid, raidpet, maintank/mainassist | ⚠️ | `SecureGroupHeaderTemplate` existiert, aber **`loadstring_untainted` fehlt in der Beta**: `initialConfigFunction`, `WrapScript`, `_onstate-*` und `RunAttribute` werfen „attempt to call a nil value“. oUFs `oUF-initialConfigFunction` ist davon betroffen. Blizzard nennt das unbeabsichtigt. Bis zum Fix: Größe und Einheit ohne Snippet setzen oder eigene feste Frames party1–4 / raid1–40 nutzen. `RegisterStateDriver(…, "visibility")` funktioniert. |
| Frame-Größe, Skalierung, Strata, Anker, Bar-Slots, Reihenfolge, vertikal, invertieren | ✅ | nur außerhalb des Kampfes ändern (`InCombatLockdown`, `ADDON_RESTRICTION_STATE_CHANGED`) |
| Config-Mode (Platzhalter und ziehen) | ⚠️ | Attribute nur außerhalb des Kampfes; Header-Vorschau wegen des Snippet-Bugs gesondert lösen. Achtung: Der Client setzt gespeicherte Positionen nach einem Reload spät neu (PLAYER_LOGIN, PLAYER_ENTERING_WORLD, +2 s). |
| Blizzard-Frames ausblenden | ⚠️ | Retail-Frames (`PlayerFrame`, `TargetFrame`, `CompactRaidFrames`, `PlayerCastingBarFrame`) an einen versteckten Parent hängen. `UnregisterAllEvents()` auf Frames der Secure-Umgebung wirft einen Fehler, also in `pcall` kapseln. Edit Mode setzt `PlayerFrame` per `SetPointOverride`. |

### Leisten
| Feature | | Begründung / Ersatz |
|---|---|---|
| Health-Bar | ⚠️ | `SetMinMaxValues(0, UnitHealthMax)` + `SetValue(UnitHealth)` oder `(0,1)` + `UnitHealthPercent`; Animation per `Enum.StatusBarInterpolation` |
| Farbe Klasse / Reaktion / statisch / getappt | ✅ | `UnitClass`, `UnitReaction`, `UnitIsTapDenied` lesbar (Klasse ⚠️ bei gesperrter Identität) |
| Farbe nach Gesundheit (%) | ⚠️ | `C_CurveUtil.CreateColorCurve()` und `UnitHealthPercent(unit, …, curve)` *(Signatur mit Curve unbestätigt)*; nie selbst vergleichen |
| Invertieren | ⚠️ | nur optisch über Texturen/Reverse-Fill (`SetReverseFill`), nicht über `max − hp` |
| Power-Bar | ⚠️ | Spieler immer secret → nur an `SetValue` durchreichen; `UnitPowerMax` lesbar |
| Druiden-Manabar | ⚠️ | `UnitPower("player", Enum.PowerType.Mana)` durchreichen; auto-hide über `GetShapeshiftForm` statt Power-Vergleich |
| Energie-/MP5-Ticker | ❌ | Luna erkennt Ticks über Power-Änderungen und das Combat Log; beides ist gesperrt bzw. secret. Höchstens ein grober Zeitgeber ohne Synchronisation *(unbestätigt)* |
| Fünf-Sekunden-Regel | ⚠️ | eigene Zauber sind nie secret: `UNIT_SPELLCAST_SUCCEEDED` (player) startet einen 5-s-Timer. Ob der Zauber Mana kostete, über `C_Spell.GetSpellPowerCost` prüfen |
| Manakosten-Vorschau | ⚠️ | Kosten lesbar, aktuelles Mana nicht → Overlay an das Füll-Texture-Ende der Power-Bar ankern (wie oUF-Retail `PowerPrediction`); Breite = Kosten / Max-Mana |
| Castbar (eigene) | ✅ | eigene Casts sind nie secret |
| Castbar (fremde Einheiten) | ⚠️ | `UnitCastingDuration` → `StatusBar:SetTimerDuration`; Name/Icon/`notInterruptible` im Kampf secret, aber an `SetText`/`SetTexture` durchreichbar; Farbe nicht nach Typ verzweigen. LibClassicCasterino entfällt, Kanal-Info: `castBarID` an Position 11 |
| `[casttime]` | ⚠️ | `SetFormattedText("%.1f", dur:GetRemainingDuration())` funktioniert gemessen; `C_DurationUtil.CreateDurationTextBinding` schreibt nichts |
| XP-/Ruf-Bar | ✅ *(unbestätigt)* | `UnitXP`/`UnitXPMax`/`C_Reputation` sollten nicht secret sein; nicht gemessen |
| Empty Bar | ✅ | reine Optik |
| Totem-Bar | ⚠️ *(unbestätigt)* | `GetTotemInfo` möglicherweise secret; Forever Unit Frames zeigt Totems mit Restzeit, also machbar. `Cooldown:SetCooldown*` ist in Forever **protected** → Duration-Objekt nutzen |
| Combo Points | ⚠️ | `UnitPower("player", ComboPoints)` ist aktuell secret, laut Blizzard ist ein Fix für den nächsten Build angekündigt; bis dahin an Widgets durchreichen |
| Reckoning-Stapel | ❌/⚠️ | liest Aurenstapel; im Kampf nicht lesbar. Nur als AuraContainer-Icon mit Stapelzahl. Ob Reckoning in Forever existiert, ist unbestätigt |
| Portrait 2D/3D/Klasse | ✅ | `SetPortraitTexture`, `PlayerModel:SetUnit`; Klassen-Icon ⚠️ bei gesperrter Identität |
| Portrait-Status mit Cooldown-Animation | ⚠️ | `UnitIsDeadOrGhost`/`UnitIsConnected` lesbar; Animation nur über Duration-Objekt (SetCooldown protected) |

### Heilvorhersage
| Feature | | Begründung / Ersatz |
|---|---|---|
| Heilbalken in der Health-Bar | ⚠️ | native `UnitGetIncomingHeals` / `CreateUnitHealPredictionCalculator` (Werte secret, an StatusBars anhängen); LibHealComm entfällt (`SendAddonMessage` in Lockdown eingeschränkt) |
| Überwachs-Grenze | ⚠️ | über die Calculator-Optionen *(unbestätigt)* |
| getrennt eigene/fremde, HoT/direkt, Zeitfenster, „HoTs deaktivieren“ | ❌ | laut pileopoop nicht möglich; der native Calculator kennt kein Zeitfenster |
| Absorb-Schilde (neu) | ⚠️ | `UnitGetTotalAbsorbs` secret, aber anzeigbar |

### Auren
| Feature | | Begründung / Ersatz |
|---|---|---|
| Buffs/Debuffs anzeigen | ⚠️ | im Kampf nur `CreateFrame("AuraContainer", …, "CustomAuraContainerTemplate")` + `AddAuraGroup(name, filter, opts)` + `SetUnit`. Die Buttons mit `button:SetSize()` im Initializer selbst skalieren (sonst 0×0 ohne Fehler). Außerhalb des Kampfes nur nach `C_Secrets.ShouldAurasBeSecret()` lesen |
| Filter Eigene / Klasse / Bannbar | ✅ | Filterstrings `HELPFUL|PLAYER`, `HELPFUL|RAID`, `HARMFUL|RAID` in der Aura-Gruppe |
| Größere eigene Auren | ✅ | zweite Aura-Gruppe mit `PLAYER`-Filter und eigener Größe |
| Timer / nur eigene Timer | ⚠️ | `button:SetDurationText(fs)`; Format über `textFormatter` im Container. `Cooldown:SetCooldownFromDurationObject` mit `C_UnitAuras.GetAuraDuration` nur außerhalb des Kampfes lesbar |
| Rahmenfarbe nach Typ | ⚠️ *(unbestätigt)* | Container-Optionen bzw. `C_UnitAuras.GetAuraDispelTypeColor` mit Curve |
| Waffenbuffs | ✅ | `C_Item.GetWeaponEnchantInfo` ist im Kampf lesbar (`AddItemEnchantment`-Slots zeichnen nichts) |
| Position, Wachstum, Begrenzung, Anzahl, Abstand | ✅ | Layout des Containers bzw. eigene Anordnung außerhalb des Kampfes |
| komplexe Filter (Teilname, Listen, `;`/`/`-Logik) | ❌ im Kampf | nur `candidateFilters = { includeSpellIDs / excludeSpellIDs }` (IDs, keine Namen) |
| Debuff-Highlight/-Rahmen bei bannbaren Debuffs | ⚠️ | Forever Unit Frames hat es umgesetzt; Weg über eine Aura-Gruppe `HARMFUL|RAID` bzw. Dispel-Farbkurve *(unbestätigt)* |

### Squares
| Typ | | |
|---|---|---|
| Aggro | ✅ | `UnitThreatSituation` lesbar |
| Aggro (ToT-basiert) | ⚠️ | `UnitIsUnit("targettarget", …)` lesbar *(im Kampf unbestätigt)* |
| Buff/Debuff (Teilname) | ❌ → ⚠️ | im Kampf nur per Spell-ID-Liste in einer eigenen Aura-Gruppe |
| eigener Buff/Debuff | ⚠️ | Gruppe mit `PLAYER`-Filter + ID-Liste |
| Bannbar | ⚠️ | Gruppe `HARMFUL|RAID` |
| Fehlender Buff | ❌ im Kampf | Abwesenheit ist nicht prüfbar; nur außerhalb des Kampfes (Buff-Check vor dem Pull) |

### Indikatoren, Highlight, Fader, Reichweite, Combat Text
| Feature | | |
|---|---|---|
| Raid-Zielmarkierung | ✅ | `GetRaidTargetIndex` liefert nil statt secret, wenn keine Markierung gesetzt ist |
| Anführer, Plündermeister, Bereitschaftscheck, Wiederbelebung, Rolle | ✅ *(teils unbestätigt)* | Standard-Einheiten-APIs; `UnitGroupRolesAssigned` liefert solo „NONE“ |
| PvP-Flagge, PvP-Rang | ✅/⚠️ | Forever hat ein eigenes PvP-Rangsystem (Fraktion 2800); die Rang-API ist unbestätigt |
| Elite/Rare/Boss | ✅ | `UnitClassification` lesbar; klassische Target-Frame-Texturen sind im Client vorhanden |
| Pet-Zufriedenheit, Loyalität | ✅ | `C_PetInfo.GetPetHappiness` / `GetPetLoyalty` (nur Forever) |
| Status (Kampf/Ausruhen), Klassen-Icon | ✅/⚠️ | Klasse ⚠️ bei gesperrter Identität |
| Highlight/Rahmen bei Ziel, Mouseover, Aggro | ✅ | |
| Kampf-Fader | ⚠️ | Kampf, Ziel und eigene Casts sind lesbar; „Leben/Power nicht voll“ ist ❌ (Vergleich). Ersatz: `SetAlphaFromBoolean` oder Bedingung ohne Leben |
| Reichweiten-Alpha | ⚠️ | spellbasiert (`C_Spell.IsSpellInRange`), `UnitInRange` für Gruppen; Ergebnis ggf. über `SetAlphaFromBoolean`. Nicht-Zauber-Checks (Inspizieren/Folgen) sind im Kampf gesperrt |
| Combat Text | ⚠️ *(unbestätigt)* | Luna nutzt **UNIT_COMBAT**, nicht das Combat Log. Ob das Event in Forever feuert und die Beträge secret sind, ist ungemessen; Forever Unit Frames zeigt „Schaden- und Heilzahlen auf dem Frame“ an, also wahrscheinlich machbar |

### Tags
| Gruppe | | |
|---|---|---|
| `[name]`, `[shortname:x]`, `[abbrev:name]`, `[level]`, `[smartlevel]`, `[class]`, `[smartclass]`, `[creature]`, `[sex]`, `[classification]`, `[shortclassification]`, `[rare]`, `[elite]`, `[guild]`, `[guildrank]`, `[faction]`, `[status]`, `[combat]`, `[afk]`, `[nameafk]`, `[group]`, `[grpnum]`, `[happiness]`, `[loyalty]`, `[br]`, `[pvp]` | ✅ | lesbare Werte. Achtung Namen: Forever hat keine Realms, sondern „Main Secondary“; `UnitName("target")` liefert zwei Werte |
| `[race]`, `[smartrace]` | ❌ vorerst | `UnitRace` kann den Client einfrieren oder abstürzen lassen (Beta-Bug) |
| `[server]` | ❌ | keine Realms |
| `[hp]`, `[maxhp]`, `[pp]`, `[maxpp]`, `[smarthealth]`, `[smarthealthp]`, `[perhp]`, `[perpp]`, gekürzte Varianten, `[druid:pp]`, `[druid:maxpp]` | ⚠️ | nur Anzeige: `string.format`/`SetFormattedText` bzw. `AbbreviateNumbers`; „Tot/Offline“ über lesbare Status-APIs statt Vergleich; Prozent nur, wenn die API 0–100 liefert (Curve-Parameter) statt `×100` |
| `[missinghp]`, `[missingpp]`, `[druid:missingpp]` | ⚠️ *(unbestätigt)* | Rechnen verboten; nur mit nativer API wie `UnitHealthMissing` (Retail 12.x), falls in Forever vorhanden |
| `[healhp]`, `[healmishp]`, `[smart:healmishp]`, `[healerhealth]`, `[namehealerhealth]`, `[perstatus]` mit Heilung | ❌ | brauchen Rechnen bzw. Vergleiche auf Secrets |
| `[incheal]` | ⚠️ | Wert secret, nur formatieren |
| `[numheals]`, `[incownheal]`, `[incpreheal]`, `[incafterheal]`, `[hotheal]`, `[effheal]`, `[overheal]` | ❌ | es gibt keine Einzelheilungen ohne LibHealComm bzw. Combat Log |
| `[cpoints]` | ⚠️ | secret bis zum angekündigten Fix |
| `[threat]` | ⚠️ | Werte im Kampf secret, nur anzeigen; Zustand lesbar |
| `[numtargeting]`, `[cnumtargeting]` | ⚠️ | Gruppe durchlaufen, `UnitIsUnit` (lesbar) |
| `[enumtargeting]` | ❌ | basierte auf Gegner-Tracking/Combat Log |
| `[buffcount]` | ❌ im Kampf | Zählen verboten |
| `[druidform]` | ⚠️ | für den Spieler über `GetShapeshiftForm`; bei anderen Einheiten aurenbasiert ❌ |
| `[range]` | ⚠️ | nur grobe Stufen aus Spell-Range-Checks |
| `[castname]`, `[casttime]` | ⚠️ | durchreichen bzw. `SetFormattedText` |
| `[xp]`, `[percxp]`, `[xppet]`, `[rep]` | ✅ *(unbestätigt)* | |
| `[afktime]` | ✅ | eigener Timer ab `UnitIsAFK` |
| `[rank]`, `[numrank]`, `[civilian]`, `[ignore]` | ⚠️ *(unbestätigt)* | Forever-PvP-Ränge; APIs nicht geprüft |
| Farb-Tags `[classcolor]`, `[reactcolor]`, `[levelcolor]`, `[pvpcolor]`, `[combatcolor]`, `[aggrocolor]`, `[color:x]`, `[nocolor]` | ✅ | `GetCreatureDifficultyColor` existiert |
| `[healthcolor]` | ❌ inline / ⚠️ ganze Zeile | Hex-Code aus Secret nicht erzeugbar; ganze FontString über Farbkurve färben *(unbestätigt)* |

### Bedienung, Profile, Integration
| Feature | | |
|---|---|---|
| Slash-Befehle, Optionsfenster | ✅ | AceConfig läuft; Blizzard-Einbindung über die Settings-API statt `InterfaceOptions_AddCategory`. Settings-Panel nicht per Code schließen (`ADDON_ACTION_FORBIDDEN`) |
| Profile (AceDB) | ⚠️ | **Beta-Bug:** SavedVariables werden oft nicht geladen und dann mit Standards überschrieben. Charakterdateien überleben `/reload`, accountweite nicht; nach Kaltstart laden nur `## SavedVariablesMachine`. Forever Unit Frames hat Einstellungen zeitweise in Charakter-Makros gesichert |
| Auto-Profile nach Gruppengröße/Auflösung | ✅ | nur außerhalb des Kampfes umschalten; Charakter-Schlüssel nicht als „Name-Realm“ annehmen |
| Import/Export (neu, von Nutzern gewünscht) | ✅ | `C_EncodingUtil` (JSON/CBOR/Base64/Kompression) |
| Profil über Addon-Nachrichten teilen | ⚠️ | `AreOutgoingAddonChatMessagesRestricted()` meldet sogar außerhalb des Kampfes true; eine Bibliothek sendet trotzdem mit Retry |
| Clique | ✅ | `ClickCastFrames`-Tabelle, wie bei Forever Unit Frames |
| OmniCC-Integration | ⚠️ | `Cooldown:SetCooldown*` ist in Forever protected; Zahlen kommen vom Client (Duration-Objekte). OmniCC für Forever unbestätigt |
| Tooltip im Kampf | ✅ | Tooltip-Text über `GetTooltipData()` lesen, nicht über `GetText()` |
| `ReloadUI` nach „Blizzard ausblenden“ | ✅ | nur per Klick, nie per Timer oder Event |

**Kurz gesagt:** Aussehen, Layout, Bar-System, Config-Mode, Indikatoren, Castbars, Portraits und Anzeige-Tags lassen sich übernehmen. Umgebaut werden müssen Auren (AuraContainer), Health/Power (nur durchreichen), Heilvorhersage (nativ), Fader und Squares. Wegfallen: Energie-Ticker, rechnende Heil-Tags, Einzelheilungs-Tags, Teilnamen-Filter im Kampf, `[race]`, `[server]`, `[enumtargeting]`, `[buffcount]` im Kampf.

---

## H) Quellen

- Luna (Original, Quelltext `classic`): https://github.com/Aviana/LunaUnitFrames/tree/classic – `modules/defaults.lua`, `modules/Options.lua`, `locales/enUS.lua`, `libs/oUF_Plugins/*`
- CurseForge Luna + Kommentare: https://www.curseforge.com/wow/addons/lunaunitframes · https://www.curseforge.com/wow/addons/lunaunitframes/comments
- CurseForge Classic Fix + Kommentare (inkl. Forever-Aussage des Autors): https://www.curseforge.com/wow/addons/luna-unit-frames-classic-fix · …/comments
- Referenz-Guide (Vanilla-1.12-Version, Menüstruktur teils abweichend): https://www.briankoponen.com/luna-unit-frames-addon-vanilla-world-warcraft/
- Turtle-WoW-Wiki (Vanilla-Fork): https://turtle-wow.fandom.com/wiki/LunaUnitFrames
- Warcraft Tavern (nur Kurzbeschreibung): https://www.warcrafttavern.com/wow-classic/addons/luna-unit-frames/
- Forever Unit Frames (Vergleich, Feature-Liste): https://www.curseforge.com/wow/addons/forever-unit-frames
- Forever-Forschungsbericht: https://github.com/mrvulo/VuloForeverUI/blob/main/docs/forever-client-research.md
- woweternity.com/forever/addons – **nicht verlässlich** (nennt „Forever v1.2.0 (3.3.5a Core)“ und einen Combat-Log-Parser; widerspricht allen Messungen)
- world-of-warcraft-forever.wiki/en/addons – allgemeiner Text ohne technische Angaben
- YouTube: Die Suche „Luna Unit Frames setup classic“ liefert fast nur Videos zu Shadowed Unit Frames. Das einzige Luna-Video („Luna Unit Frames Addon for Vanilla 1.12 (Nostalrius)“, 8:21) behandelt die Vanilla-Version und hat keine Kapitel, daher kein verwertbarer Mehrwert.
