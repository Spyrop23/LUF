# FUF – Regeln für den Code

Addon für **World of Warcraft: Forever**, Client 1.60.1, `## Interface: 16001`. Das Addon liegt im Unterordner `FUF/` (TOC `FUF/FUF.toc`, der Ordner muss im Spiel `FUF` heißen).
Gearbeitet wird direkt auf `main`, ohne PR.
Forever ist ein **Mainline-Client** (Spieltyp `camelot`) mit den Retail-12.x-Addon-Sperren.

1. **Keine fremden Libraries.** Weder Ace3 noch oUF noch LibSharedMedia. Alles lebt auf `ns`;
   die einzigen Globals sind `FUFDB`, `SLASH_FUF1`, `FUF_OnAddonCompartmentClick` und die benannten
   Frames (`FUF_<unit>`, `FUFOptionsFrame`, `FUFOptionsScroll`, `FUFMinimapButton`).
   Nie `a, _, b = f()` ohne `local` schreiben, sonst wird die globale Variable `_` beschrieben (Taint).
2. **Nur Retail-API:** `C_UnitAuras`, `C_Spell`, `C_Item`, `C_AddOns`, `MenuUtil`, Settings-API.
   Classic-Globals (`UnitAura`, `GetSpellInfo`, `IsAddOnLoaded`, `EasyMenu`,
   `InterfaceOptions_AddCategory`) gibt es nicht.
3. **Secret anzeigen, nie darauf entscheiden.** `UnitHealth`, `UnitHealthPercent` und `UnitPower`
   sind immer secret. Kein Rechnen, Vergleichen, kein boolescher Test (auch nicht `x and …` oder
   `x or …`), kein `#` und keine Verwendung als Tabellenschlüssel. Nur an Widget-Setter weitergeben
   (`StatusBar:SetValue`, `SetMinMaxValues`, `FontString:SetFormattedText`, `AbbreviateNumbers`).
   Vor jeder Entscheidung zuerst `ns.CanRead(v)` aufrufen und für „nein“ einen Fallback haben.
   Prozent kommen nur über die Curve `CurveConstants.ScaleTo100`.
4. **Tags** geben ein Format-Stück plus Werte zurück (`return "%s", wert`), nie einen selbst
   zusammengesetzten String aus Secrets (siehe `Core/Tags.lua`).
5. **Auren:** Vor jedem `C_UnitAuras`-Aufruf `C_Secrets.ShouldAurasBeSecret()` prüfen, denn im Kampf
   werfen diese Aufrufe einen Fehler. Im Kampf das `AuraContainer`-Widget verwenden.
6. **Kein Combat Log:** Niemals `COMBAT_LOG_EVENT_UNFILTERED` registrieren, auch nicht per pcall.
7. **Geschützte Aktionen** (Frames erzeugen, Größe, Position, Attribute, Unit Watch) nur außerhalb
   des Kampfes ausführen, über `ns:RunOutOfCombat(fn)`.
8. Events über `pcall` registrieren, denn unbekannte Events werfen einen Fehler. `ReloadUI()` nur
   nach einem Klick aufrufen.
9. Vor jeder API-Annahme gegen den Client-Quelltext prüfen: `Gethe/wow-ui-source` Branch `forever`,
   `Ketho/BlizzardInterfaceResources` Branch `forever` (`Resources/GlobalAPI.lua`, `Events.lua`).
   Stellen, die erst im Beta-Client bestätigt werden müssen, mit `-- TODO(beta)` markieren.
10. Vor jedem Commit: `luac5.1 -p` für alle Dateien und `lua5.1 tools/smoketest.lua` ausführen.
11. Menü-Änderungen gehen über `ns:ApplyKey(key)`. Das sammelt Änderungen und wendet sie außerhalb
    des Kampfes an. Frames nie direkt aus einem Setter heraus umbauen.
