# Spec: Flugwacht

Verbindliche Grundlage: `design_handoff_flugwacht/flugwacht-fachkonzept.md` (Fachkonzept)
und `design_handoff_flugwacht/README.md` (Design-Handoff). Diese Spec fasst zusammen,
ergänzt Technikentscheidungen und zerlegt die Arbeit in Häppchen — bei Widerspruch gilt
das Handoff.

## Objective

Flugwacht ist ein bewusst minimaler Flugtracker (Flutter, iOS + Android) für einzelne,
selbst eingetragene Flüge: Flugnummer + Startdatum (+ optionale Notiz) eintragen, am
Flugtag wird der Flug automatisch live verfolgt und auf einer Karte gezeigt. Die eine
Frage, die zählt: *Wo sind sie gerade, und wann sind sie da?* Typisch 1–3 Flüge
gleichzeitig; jede Funktion, die nicht auf diese Frage einzahlt, gehört nicht hinein.

**Vorgehen in zwei Stufen:**

1. **Phase 0 — Spike (Wegwerf-Code):** Machbarkeitsprüfung, ob Live-Daten eines
   Providers abgerufen und auf einer Karte dargestellt werden können. Wird nach dem
   Nachweis vollständig gelöscht.
2. **App-Umsetzung in kleinen Häppchen** (Meilensteine unten), jedes Häppchen einzeln
   planbar, umsetzbar und verifizierbar.

**Planung & Tracking auf GitHub:** Je Häppchen ein GitHub-Milestone, je Task ein Issue;
Reviews und Feedback laufen über Issue-Kommentare. Im Repo liegt nur diese Spec als
Arbeitskopie — sie, der Design-Handoff-Ordner und alle sonstigen Planungsdateien werden
nach Fertigstellung gelöscht (M16; die Git-Historie behält sie).

## Tech Stack

| Bereich | Entscheidung |
|---|---|
| Framework | Flutter 3.44.9 (fvm-Pin in `.fvmrc`), Dart SDK ^3.12.2 |
| State-Management | `signals` (Repo enthält die zugehörigen Skills) |
| Persistenz | `drift` (SQLite) für Flüge + Spur-Punkte |
| Routing | `go_router` (Tab-Shell Karte · Liste · Mehr + modaler „Neuer Flug“-Screen) |
| Karte (OSM-Raster) | `flutter_map` mit OSM-Tiles |
| Karte (reduzierter Stil) | offen — Entscheidung im zugehörigen Häppchen (maplibre_gl / eigenes Style-Set) |
| HTTP | `http`, ein Quellen-Adapter hinter einem Interface (Quellen sind feldidentisch) |
| Fonts | `google_fonts` (Bebas Neue, Barlow) |
| Icons | Font Awesome Pro `regular` via `font_awesome_flutter` + Kit 85fa8e3a78; `fa-regular-icons.json` als SVG-Fallback |
| Notifications | `flutter_local_notifications`, nur lokal, kein Backend |
| Datum | nativer System-Datepicker (`showDatePicker` / `CupertinoDatePicker`) |

Dependency-Versionen werden beim Hinzufügen aktuell ermittelt (pub.dev), nie geraten.

**Datenquellen** (genau eine aktiv, kein Merge, kein Failover; Rate-Limit 1 req/s je
Quelle): adsb.lol (Default) · adsb.fi · airplanes.live. Route separat über
`vradarserver/standing-data` (lokal bevorzugt), einmal pro Flug, gecacht.
Explizit verworfen: OpenSky, eigener Empfänger, Historie, Bezahlquellen.

## Commands

```
Setup:    flutter pub get
Analyse:  flutter analyze
Format:   dart format .
Tests:    flutter test
App:      flutter run                        (auf dem Host: iOS-Simulator/Gerät)
Spike:    flutter run -t lib/spike/main.dart (auf dem Host)
Sandbox:  flutter run -d web-server          (nur Notbehelf; kein iOS/Android-Build möglich)
```

## Project Structure

```
lib/
  spike/            → Phase 0, Wegwerf-Code — wird nach der Machbarkeit gelöscht
  data/             → Quellen-Adapter (readsb-API), Fix-Normalisierung, Route-Lookup, drift-DB
  domain/           → Modelle (Flight, Fix, Route), Zustandsmaschine, Ankunftsschätzung
  ui/               → Screens (Karte, Liste, Neuer Flug, Einstellungen), Widgets, Theme/Tokens
test/               → spiegelt lib/ (data/, domain/, ui/)
design_handoff_flugwacht/ → Design-Referenz, wird nicht verändert; Löschung in M16
```

## Code Style

Englischer Code, null Kommentare als Standard, keine Abkürzungen in Bezeichnern,
`flutter_lints`, kleine komponierte Widgets mit `const`-Konstruktoren, private
Widget-Klassen statt Helper-Methoden. Beispiel für den angestrebten Stil:

```dart
class FixTimestamp {
  static DateTime fromSeenPos({required double seenPosSeconds, required double serverNowSeconds}) {
    final milliseconds = ((serverNowSeconds - seenPosSeconds) * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
}
```

UI-Texte deutsch, Du-Form, kein Emoji. Design-Tokens exakt aus dem Handoff-README
(Gelb-Trio `#ffeb3b`/`#ffc107`/`#ffa726` nie substituieren, Bebas Neue + Barlow,
4px-Raster, Hit-Targets ≥ 44px, Motion 150–200ms ease-in-out).

## Testing Strategy

`flutter_test`; Tests laufen headless in der Sandbox. Getestet wird ausschließlich
eigenes Anwendungsverhalten — Schwerpunkt auf der Domäne, in der die bekannten
Fallstricke stecken:

- Fix-Normalisierung: `alt_baro == "ground"`, `track` statt `heading`,
  `seen_pos` + Server-`now` → absoluter UTC-Zeitstempel, Callsign-Trimming (8 Zeichen)
- Zustandsmaschine: geplant → wartet → live ⇄ kein Signal → beendet | verpasst,
  großzügige Schwelle (10–15 min), Zeitfenster über Mitternacht
- Hex-Absicherung: Callsign-Gegenprüfung bei Hex-Abfragen, Rückfall auf Callsign-Suche
- IATA→ICAO-Mapping inkl. Ryanair/Wizz/easyJet-Erkennung
- Ankunftsschätzung: Restdistanz/Bodengeschwindigkeit, keine Schätzung ohne Route

Widget-Tests nur für eigenes Verhalten (z. B. Zustands-Zeitleiste rendert den richtigen
aktiven Zustand), keine Framework-Tests. Der Spike bekommt keine Tests — er ist Wegwerf-Code.

## Boundaries

**Immer:**
- Rate-Limit 1 req/s je Quelle einhalten; genau eine aktive Quelle, nie mergen
- Fix-Normalisierung wie im Fachkonzept (verbindlich), Spur-Punkte tragen ihre Quellen-ID
- Empfangslücke als regulären Zustand behandeln, nie als Error-UI
- Attribution sichtbar (aktive Quelle + © OpenStreetMap)
- `flutter analyze` + `flutter test` vor jedem Commit; Conventional Commits, nur Titelzeile
- Design-Tokens und Maße aus dem Handoff-README pixelgenau übernehmen

**Erst fragen:**
- Neue Dependencies jenseits der oben festgelegten
- Abweichungen vom HiFi-Design oder vom Fachkonzept
- Hintergrund-Polling-Ansatz (iOS-BGTaskScheduler-Grenzen — laut Handoff explizit mit dem Nutzer zu klären)
- drift-Schema-Änderungen nach dem ersten Release des Schemas

**Nie:**
- OpenSky, eigener Empfänger, Historie, Bezahlquellen wieder einführen
- Backend/Server/Konten einbauen (alles lokal auf dem Gerät)
- Demo-Flug im Leerzustand
- Brand-Farben substituieren
- Pushen (macht der Nutzer selbst); Design-Handoff-Ordner verändern (Ausnahme: Löschung in M16)
- Features ergänzen, die nicht im Handoff stehen

## Phase 0 — Spike (Wegwerf-Code)

**Ziel:** Beweis, dass Live-Daten von adsb.lol abrufbar und auf einer Karte darstellbar
sind. Reine Machbarkeit — kein Produktionsanspruch, keine Tests, wird danach gelöscht
(`lib/spike/` entfernen; `flutter_map` und `http` bleiben, die App braucht sie ohnehin).

**Umfang:**
- Eigener Entrypoint `lib/spike/main.dart`, Start via `flutter run -t lib/spike/main.dart`
  im iOS-Simulator auf dem Host
- `GET /v2/point/{lat}/{lon}/{radius}` um Frankfurt (liefert zu jeder Tageszeit Verkehr),
  Polling ≥ 1 s Abstand
- `flutter_map` mit OSM-Raster-Tiles, Flugzeuge als Marker, Rotation nach `track`
- Tap auf Marker zeigt Callsign, Höhe, Geschwindigkeit, Alter des Fixes — live aktualisiert

**Erfolgskriterien (Spike bestanden, wenn alle erfüllt):**
- [ ] Karte mit OSM-Tiles rendert im iOS-Simulator
- [ ] Live-Flugzeuge um Frankfurt erscheinen als Marker und bewegen sich über Polling-Zyklen
- [ ] Daten eines ausgewählten Fliegers aktualisieren sich sichtbar
- [ ] Rate-Limit eingehalten (max. 1 req/s)

Scheitert der Spike (API nicht erreichbar, Karte unbrauchbar), wird die Ursache
dokumentiert und die Technikwahl neu bewertet, bevor App-Häppchen starten.

## Häppchen (Meilensteine der App-Umsetzung)

Reihenfolge nach Abhängigkeit; jedes Häppchen wird vor Umsetzung in GitHub-Issues
zerlegt (Milestone je Häppchen), umgesetzt, getestet und committet (Commits referenzieren
ihr Issue). Detail-Design und Maße je Screen: Handoff-README.

| # | Häppchen | Kern |
|---|---|---|
| M1 | Fundament | Theme/Tokens, Fonts, FA-Pro-Setup, Tab-Gerüst mit go_router (Karte · Liste · Mehr), Hell/Dunkel |
| M2 | Domain-Kern | Fix-Modell + Normalisierung, Quellen-Adapter (readsb-Interface, 3 Quellen), Tests |
| M3 | Flug-Modell | Flight + Zustandsmaschine (6 Zustände, Mitternachts-Fenster), Tests |
| M4 | Persistenz | drift-Schema: Flüge + Spur-Punkte (mit Quellen-ID), Auto-Cleanup nach 24 h |
| M5 | Neuer Flug | Modal-Formular, Segmented (Flugnummer/Kennzeichen/Hex), IATA→ICAO, Route-Lookup (standing-data), „GEFUNDEN“-Card, nativer Datepicker |
| M6 | Liste | Hero-Zelle mit Mini-Karte, Zustands-Zeitleiste, normale/geplante Zeilen, Leerzustand, FAB, „Vorbei“-Sektion |
| M7 | Karte | Vollbild-`flutter_map`, Marker + Ping, Spur (geflogen/geplant), Bottom-Sheet (Peek/offen), Flugwechsel per Wisch/Tap |
| M8 | Polling | Vordergrund-Polling-Engine, Zustandsübergänge live ⇄ kein Signal, Hex↔Callsign-Absicherung, Frische-Anzeige |
| M9 | Ankunft | Schätzung (Restdistanz/Groundspeed), Ziel-Ortszeit + Nutzerzeit, „~“-Darstellung bei veraltetem Stand |
| M10 | Quellen | Umschalter, Spur-Segmente je Quelle gefärbt, Legenden-Card, „Andere Quelle probieren“ |
| M11 | Kartenstil | Reduzierter Stil + Umschalt-Button, Wahl persistieren (Technikentscheidung hier) |
| M12 | Einstellungen | Quelle, Einheiten (metrisch/Luftfahrt), Mitteilungs-Switches, Fußnoten |
| M13 | Notifications | Lokal: Gestartet · Ankunft bald (~30 min) · Gelandet |
| M14 | Hintergrund | Machbarkeit Hintergrund-Polling (iOS-Limits) — Untersuchung, Entscheidung mit Nutzer |
| M15 | Feinschliff | Über-/Lizenzseite, App-Icon-Export, „beendet/verpasst“-Detailzustände |
| M16 | Aufräumen | `design_handoff_flugwacht/`, `SPEC.md` und verbliebene Planungsdateien löschen; Check auf Spike-Reste |

## Success Criteria (App gesamt)

- Alle Screens entsprechen pixelgenau dem HiFi-Board (hell + dunkel)
- Ein eingetragener Flug durchläuft die Zustandssequenz korrekt und überlebt App-Neustarts
- Empfangslücken und „Route unbekannt“ erscheinen als reguläre Zustände
- `flutter analyze` sauber, alle Tests grün

## Open Questions

- Technik für den reduzierten Kartenstil (Entscheidung in M11)
- Hintergrund-Polling auf iOS (M14, mit Nutzer)
- FA-Pro-Kit-Einrichtung braucht ggf. Lizenz-Zugang des Nutzers auf dem Host
- Inhalt der Über-/Lizenzseite (M15)
- GitHub-Remote existiert noch nicht — Repo anlegen und pushen macht der Nutzer
