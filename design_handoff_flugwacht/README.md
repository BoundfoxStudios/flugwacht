# Handoff: Flugwacht — Flutter-App (iOS + Android)

## Overview
Flugwacht ist ein bewusst minimaler Flugtracker für einzelne, selbst eingetragene Flüge („Wo sind sie gerade, und wann sind sie da?"). Der Nutzer trägt Flugnummer + Startdatum (+ Notiz wie „Anna & Ben") ein; am Flugtag wird der Flug automatisch live verfolgt und auf einer Karte gezeigt. Typisch 1–3 Flüge gleichzeitig. Fachliche Grundlage: `flugwacht-fachkonzept.md` (Datenquellen, Fallstricke, Zustandsmodell) — **bitte vollständig lesen**, es ist verbindlich.

## About the Design Files
Die HTML-Dateien in diesem Ordner sind **Design-Referenzen** (Prototypen aus einem HTML-Design-Tool), kein Produktionscode. Aufgabe ist, diese Designs **in Flutter nachzubauen** (Material-Basis mit eigenem Look, s. u.), nicht das HTML zu übernehmen. Die `.dc.html`-Dateien sind im Design-Tool entstanden und laufen nur dort vollständig — sie dienen als visuelle Spezifikation; alle Maße/Farben stehen zusätzlich hier im README.

## Fidelity
- `Flugwacht-HiFi.dc.html`: **High-fidelity** — Farben, Typo, Abstände, Copy sind final gemeint; pixelgenau nachbauen (Board mit Runden 2–5; Runde 4/5 = Darkmode).
- `Flugwacht-Wireframes.dc.html`: **Low-fidelity** — nur Struktur-/Flow-Referenz (Runde 1). Gewählt: 1a/1b (Karte mit Sheet), 1f (Liste), 1h (Ein-Screen-Formular), 1i (Leerzustand ohne Demo).
- `Logo-C-Auge.dc.html`: finales Logo „Radar-Auge" mit Hell/Dunkel-Varianten und App-Icon-Kacheln.

## Navigation & Grundgerüst
- **Tab-Bar unten**, 3 Tabs: KARTE · LISTE · MEHR. Höhe 76px + Safe-Area; Labels Bebas Neue 13px, Tracking 0.05em; Icon 19px darüber; aktiver Tab: Farbe Text/Icon `#262626` (dark: `#fafafa`) + Indikator-Balken 24×3px `#ffc107` (Radius 2) oberhalb des Icons; inaktiv `#a3a3a3` (dark `#737373`). Kein Material-Standard-Look (keine Ripple-Pill).
- „Neuer Flug" ist ein **modaler Screen** (ohne Tab-Bar), erreichbar über FAB in der Liste.

## Screens

### 1. Karte (Haupt-Tab) — HiFi 2a (Peek) / 2b (offen), dark: 5a / 4a
- **Vollbild-Karte**, alle heutigen Flüge gleichzeitig als Marker; Auswahl per Tap auf Marker **oder** horizontales Wischen im Sheet (Pager-Punkte 6px: aktiv `#404040`/dark `#d4d4d4`, inaktiv `#d4d4d4`/dark `#525252`).
- Kartenstile: **OSM (Raster)** und **reduzierter Stil**; Umschalt-Button auf der Karte oben rechts (44×44px, weiß/`#262626`, Border `#e5e5e5`/`#404040`, Radius 10, Icon `layer-group`). Darunter optional Locate-Button (`location-arrow`). Attribution unten links, 10px `#a3a3a3`: „© OpenStreetMap · Daten: adsb.lol" (Pflicht, Quelle dynamisch).
- Reduzierter Stil (Referenzwerte aus den Mocks): Wasser `#ffffff`/dark `#171717`, Land `#f5f5f5`/dark `#262626` mit Border `#e5e5e5`/`#404040`, Gitterlinien `#f0f0f0`.
- **Spur**: geflogen = durchgezogen `#404040` 2.5px (dark `#d4d4d4`), geplant = gestrichelt `#a3a3a3` 2px 7-6 (dark `#737373`); Flughafenpunkte r5 `#404040` + Label Barlow 600 12px `#737373`. Flugzeug-Marker: gelbe Silhouette `#ffc107`, Kontur `#262626` (dark `#171717`), Rotation = `track`; um den Live-Marker 1–2 Ping-Ringe `#ffc107` (Opacity .5/.22).
- **Bottom-Sheet** (Radius oben 16, Shadow 0 -6 16 rgba(0,0,0,.09), dark: Fläche `#262626`, Shadow rgba(0,0,0,.5); Grabber 36×4 `#d4d4d4`/`#525252`), zwei Snap-Positionen:
  - **Peek (~176px):** Zeile „LH400 · Anna & Ben" (Barlow 600 15 `#404040`/dark `#d4d4d4`) + Badge „● LIVE" (Gelb-Pill, dunkler Text); Ankunftszeit **Bebas Neue 54px** `#171717`/dark `#ffffff` + rechts zweizeilig „Ankunft ca." 13 `#737373` / „noch 2 Std 10 Min" 15 600; darunter „Ortszeit New York · bei dir 20:32" 13 `#737373`.
  - **Offen (+~120px):** zusätzlich Kopfzeile rechts „FRA → JFK · B747-8"; **Zustands-Zeitleiste** (s. u.); Datenzeile 3 Spalten mit Bebas-Labels 12px Tracking 0.1em `#a3a3a3`: HÖHE „11 278 m" · TEMPO „876 km/h" · SIGNAL „vor 3 s" (Werte Barlow 600 15); Fußzeile „Quelle: adsb.lol · © OpenStreetMap" 11 `#a3a3a3`.
- **Zeitleiste** (in Sheet + Listen-Hero): Punkte 10px verbunden mit 2px Linien; erledigt = gefüllt `#404040` (dark `#d4d4d4`), aktueller Zustand = 16px `#ffc107` mit 3px Ring `#262626` (dark Ring `#fafafa`), zukünftig = hohl Border `#d4d4d4`/`#525252`; Labels 11px `#a3a3a3`, aktiver fett `#262626`. Reihenfolge: geplant · wartet · live · (kein Signal) · beendet.

### 2. Zustand „kein Signal" — HiFi 3b / dark 5d
- Badge „KEIN SIGNAL" (hell: Badge dark; dunkel: Outline-Pill Border `#737373`, Text `#d4d4d4`). Zeit wird zu **„~14:32"** + „Stand: vor 42 Min". Marker grau (`#d4d4d4` Kontur `#737373`; dark `#525252`/`#a3a3a3`) mit **gestricheltem** Ring statt Ping.
- Info-Box (Radius 8, `#fafafa` Border `#e5e5e5`; dark `#171717` Border `#404040`; Text 13/1.5 `#737373`/`#a3a3a3`): „Letztes Signal vor 42 Min über dem Nordatlantik. Über Ozeanen gibt es oft 1–2 Stunden keine Empfänger — die Spur kommt wieder." → Empfangslücke ist ein regulärer Zustand, **nie** ein Error-UI.
- Rechts unten im Sheet Textlink „Andere Quelle probieren" (`#a16207`, dark `#ffc107`).

### 3. Quellenvergleich auf der Karte — HiFi 3c / dark 5e
- Eine fortlaufende Spur, **Segmente nach liefernder Quelle gefärbt**: adsb.lol `#ffc107`, adsb.fi `#ffa726`, airplanes.live `#737373` (dark `#d4d4d4`); Breite 3px.
- Legenden-Card oben links (Radius 10, wie Buttons): Titel „SPUR JE QUELLE" Bebas 12 Tracking 0.1em `#a3a3a3`; Zeilen: Farbstrich 14×3 + Name 12px (aktive Quelle 600 + Zusatz „aktiv").
- Sheet-Peek zeigt Erklärsatz: „Die Spur bleibt beim Umschalten erhalten — jeder Punkt kennt seine Quelle."

### 4. Liste (Tab) — HiFi 2c / dark 4b
- Hintergrund `#fafafa` (dark `#171717`). Header: „FLÜGE" Bebas 36 `#171717`/`#ffffff` links, rechts Datum „Mi, 12. August" 13 `#737373`.
- **Hero-Zelle** für den aktiven/Live-Flug (Card Radius 12, Border `#e5e5e5`/`#404040`, Fläche weiß/`#262626`, shadow-md): oben **Mini-Karte 150px** (gleiche Kartensprache, Badge „● LIVE" oben links), darunter Titelzeile, Bebas-Zeit 40px, „Ankunft ca. · noch 2 Std 10 Min", kompakte Zeitleiste.
- Normale Zeile (wartet): Card mit „EW594 · Mama" 600 15 / „STR → PMI · wartet auf Signal" 13 `#737373`, rechts „ab 16:10".
- Geplante Zeile: **gestrichelte** Border 1.5px `#d4d4d4`/`#404040`, Textfarben eine Stufe heller, rechts „Fr, 15. Aug".
- **FAB** unten rechts (16px Rand, über Tab-Bar): 56px Kreis `#ffc107`, Plus-Icon `#262626` 24px, Amber-Glow-Shadow (0 10 15 -3 rgba(255,193,7,.4)).
- Beendete/verpasste Flüge bleiben 24 h sichtbar (Abschnitt „Vorbei", ausgegraut, „gelandet ✓" bzw. „verpasst"), danach automatisch entfernt. (Detail-Design offen — Wireframe 1e zeigt die Richtung.)

### 5. Neuer Flug (modal) — HiFi 2d / dark 5b
- Kopf: „Abbrechen" links (`#a16207`, dark `#ffc107`), Titel „NEUER FLUG" Bebas 22 zentriert.
- **Segmented Control** (Track `#f5f5f5`/dark `#262626`, Radius 8, Padding 3; aktives Segment weiß mit Border `#e5e5e5` bzw. dark `#404040`, Text 600 13): Flugnummer · Kennzeichen · Hex — **immer sichtbar** (Ausweg für Ryanair/Wizz/easyJet, deren Rufzeichen nicht zur Flugnummer passt; bei erkannter solcher Airline zusätzlich Hinweis einblenden).
- Felder (Label Bebas 14 Tracking 0.05em `#404040`/dark `#a3a3a3`; Feld 48px, Radius 8, Border `#e5e5e5`/`#404040`, Fläche weiß/`#262626`, Text 16 `#262626`/`#fafafa`):
  - FLUGNUMMER „LH 400", Hint „Wie auf dem Ticket, z. B. LH 400" (12 `#a3a3a3`).
  - STARTDATUM „Mi, 12. August 2026" + Kalender-Icon rechts — **öffnet den nativen System-Datepicker** (kein Inline-Kalender). Hint: „Tag des Abflugs · öffnet die Systemauswahl · Nachtflüge zählen bis in den Folgetag".
  - NOTIZ (OPTIONAL) „Anna & Ben".
- **„GEFUNDEN"-Vorschau-Card** (erscheint nach erfolgreichem Route-Lookup, debounced): Label Bebas 13 Tracking 0.1em `#a3a3a3`; „FRA → JFK" 600 16; Pill „FUNK: DLH400" (Outline); Unterzeile „Frankfurt am Main → New York JFK · Lufthansa" 13 `#737373`. „Route unbekannt" ist ein gültiger Zustand — Card zeigt das neutral, Speichern bleibt möglich (dann ohne Ankunftsschätzung).
- CTA zentriert unter der Card: Primary-Button „FLUG EINTRAGEN" (Gelb `#ffc107`, dunkler Bebas-Text, Radius ~10, Höhe ~52, Amber-Glow).

### 6. Leerzustand (Liste) — HiFi 2e / dark 5c
- Zentriert: Logo (Radar-Auge, 76px; dunkle Variante mit weißem Umriss + Iris `#404040`), „NOCH KEIN FLUG AUF DER LISTE" Bebas 30/1.0, Erklärtext Barlow 15/1.625 `#737373`/`#a3a3a3`: „Trag einen Flug ein — Flugwacht verfolgt ihn am Flugtag automatisch und zeigt dir, wann er ankommt.", Primary-CTA „FLUG EINTRAGEN". **Kein Demo-Flug.**

### 7. Einstellungen (Tab MEHR) — HiFi 3a / dark 4c
- Titel „EINSTELLUNGEN" Bebas 36. Karten-Sektionen (Radius 12, Border, Sektionstitel Bebas 14 Tracking 0.1em `#a3a3a3`/`#737373`):
  - **DATENQUELLE**: Radio-Liste adsb.lol (aktiv) · adsb.fi · airplanes.live (Radio: 18px Ring, aktiv Amber `#ffc107` mit 8px Punkt). Erklärtext 13/1.5: „Alle drei liefern dieselben Werte — sie unterscheiden sich nur darin, wer deinen Flieger gerade empfängt. Bei Lücken lohnt das Umschalten; die Spur läuft dabei weiter." **Genau eine aktive Quelle, kein Merge/Failover.**
  - **EINHEITEN**: Segmented „Metrisch (m, km/h)" (Default) · „Luftfahrt (ft, kt)".
  - **MITTEILUNGEN**: Switches (40×24, an = `#ffc107` mit dunklem Knauf, aus = `#d4d4d4`/`#525252`): Gestartet · Ankunft bald (~30 Min) · Gelandet. Fußnote: „Lokal auf dem Gerät — kein Konto, kein Server."
  - **Über Flugwacht** (Zeile mit Chevron): Version, Lizenzen & Quellen; hier einziges Boundfox-Branding (dezent). Screen selbst noch nicht designt.
- Fußnote 11px `#a3a3a3`: „Daten: adsb.lol (ODbL), adsb.fi, airplanes.live — frei für privaten Gebrauch, Community-Netze ohne Gewähr. Karte © OpenStreetMap."

## Interactions & Behavior
- Sheet: 2 Snap-Punkte (Peek/offen), Drag + Tap auf Grabber; horizontales Wischen wechselt Flug (PageView-Gefühl), Karte animiert zum gewählten Flug (200ms, ease-in-out — Animationen generell minimal, keine Bounces).
- Marker-Tap selektiert Flug und synct das Sheet. Stil-Button toggelt OSM ↔ reduziert (Wahl persistieren).
- Wizard: Lookup der Flugnummer → IATA→ICAO-Mapping → Callsign; „GEFUNDEN" animiert einblenden (150–200ms Fade). Speichern legt Flug an und schließt modal; neuer Flug erscheint in Liste (und Karte am Flugtag).
- Pull-to-refresh nirgends nötig — Polling läuft selbst (1 req/s Limit je Quelle beachten; UI zeigt Frische über „vor X s").
- Hover/Press (Android/Ripple aus): Press = eine Stufe dunkler (Gelb→Amber) + 1px translate-down.

## State Management
- **Flugzustände**: geplant → wartet → live ⇄ kein Signal → beendet | verpasst. Übergänge aus Datum/Zeitfenster + Alter der letzten Position (`kein Signal` ab 10–15 Min ohne frischen Fix — großzügig, sonst flackert es). Zeitfenster reicht über Mitternacht (Nachtflüge); „Startdatum" = Ortszeit des Nutzers.
- **Fix-Normalisierung** (Pflicht, siehe Fachkonzept): `alt_baro` kann String `"ground"` sein; Anzeige-Höhe = `alt_baro`; Richtung = `track` (nie `heading`); `seen_pos` + Server-`now` → absoluter Zeitstempel; Callsigns trimmen (8 Zeichen, Leerzeichen-gepolstert); Hex identifiziert die Zelle, nicht den Flug → bei jeder Hex-Abfrage Callsign gegenprüfen, sonst zurück zur Callsign-Suche.
- **Route** separat vom Fix (einmal pro Flug auflösen, cachen; Quelle `vradarserver/standing-data` lokal bevorzugt). „Route unbekannt" regulär.
- **Ankunft ca.** = Restdistanz zum Ziel / Bodengeschwindigkeit; bewusst vage labeln („Ankunft ca.", „~14:32" bei veraltetem Stand); ohne Route keine Schätzung. Anzeige immer in Ziel-Ortszeit **und** Nutzerzeit.
- Verlauf/Spur: Punkte gehören zum Flug, jeder trägt seine Quellen-ID (→ Vergleichsfärbung). Persistenz über App-Neustart erwünscht (lokal, z. B. SQLite/Isar) — Flüge + Spuren.
- Push: **nur lokale Notifications** (Gestartet / Ankunft bald ~30 Min / Gelandet), kein Backend. iOS-Hintergrund-Limits (BGTaskScheduler ist opportunistisch) sind bekannt — Machbarkeit im Projekt klären, ggf. Erwartung in der UI dämpfen.

## Design Tokens
Basis: Boundfox-Studios-DS (Tailwind-Raster). **Gelb-Trio exakt, nicht substituieren.**
- Brand: `#ffeb3b` (Gelb) · `#ffc107` (Gelb 2 / primärer Akzent) · `#ffa726` (Orange). Link hell `#a16207`, Link dark `#ffc107`.
- Neutrals hell: Text `#171717`/`#262626`/`#404040`, sekundär `#737373`, tertiär `#a3a3a3`, Border `#e5e5e5`, Flächen `#ffffff`/`#fafafa`/`#f5f5f5`.
- Dark: Grund `#171717`, Fläche `#262626`, Border `#404040`, Hairline/Aus `#525252`, Text `#fafafa`/`#d4d4d4`, sekundär `#a3a3a3`, tertiär `#737373`. Gelb bleibt einziger Akzent.
- Typo: **Bebas Neue** (Display/Labels, immer Caps, Leading 1.0, Tracking 0.025–0.1em; Zeiten 54/40, Titel 36, Nav-Titel 22, Sektionen 12–14) + **Barlow** (Body 15/16, sekundär 13, klein 11–12; 600 für Betonung). Mindestgröße 11px.
- Radius: Sheet 16 · Cards 12 · Buttons/Felder/Boxen 8–10 · Pills/Badges 999. Keine starke Rundung sonst.
- Spacing: 4px-Raster; Screen-Padding 16–20; Card-Padding 12–16.
- Schatten: Cards soft (`0 4px 6px -1px rgba(0,0,0,.07)`), Sheet `0 -6px 16px rgba(0,0,0,.09)` (dark rgba(0,0,0,.5)), Amber-Glow nur Primär-CTA/FAB.
- Motion: 150–200ms, ease-in-out, keine Bounces.
- Hit-Targets ≥ 44px.

## Icons
**Font Awesome Pro, Stil `regular`** (klassisch), v7. Genutzt: `map`, `list`, `sliders` (Tab MEHR), `layer-group` (Kartenstil), `location-arrow`, `calendar`, `plus`, `chevron-right`. In Flutter: `font_awesome_flutter` + Pro-Setup mit vorhandener Lizenz (FA CLI; siehe `.font-awesome.md` und docs.fontawesome.com — Kit-ID 85fa8e3a78, Web-Fonts-Modus). `fa-regular-icons.json` enthält die SVG-Pfade der 8 Icons als Fallback/Referenz.

## Assets
- **Logo „Radar-Auge"** (Vektor, siehe `Logo-C-Auge.dc.html`): Auge-Umriss `M4 24 Q24 6 44 24 Q24 42 4 24 Z` (Stroke `#262626` 2.6, round join; dark `#fafafa`), Iris-Scheibe r8.8 `#262626` (dark `#404040`), Radar-Keil `M24 24 L24 15.6 A8.4 8.4 0 0 1 30.9 20.3 Z` `#ffc107`, Ring r4.8 `#ffeb3b` (Opacity .85), Punkt r1.5 `#ffeb3b`. ViewBox 0 0 48 48. App-Icon: Mark auf `#171717`-Kachel (bzw. weiß) — Exporte in Plattformgrößen noch zu erzeugen.
- Wortmarke: „FLUGWACHT" in Bebas Neue, ohne Untertitel.
- Flugzeug-Marker-Silhouette (ViewBox 0 0 48 48): `M24 7C25.6 7 26.4 9.5 26.4 12L26.4 18.5L40 26L40 29.5L26.4 25.5L26.4 32.5L30.5 36.5L30.5 39.5L24 37.5L17.5 39.5L17.5 36.5L21.6 32.5L21.6 25.5L8 29.5L8 26L21.6 18.5L21.6 12C21.6 9.5 22.4 7 24 7Z`.
- Karten: OSM-Raster-Tiles (Attribution!) + reduzierter Stil (Farben oben). Keine Fotos, kein Emoji.

## Flutter-Hinweise (empfohlen, nicht bindend)
- Karte: `flutter_map` (Raster-OSM) und für den reduzierten Stil `maplibre_gl`/`vector_map_tiles` mit eigenem Style-JSON in den Token-Farben — oder reduzierten Stil als eigenes Tile-/Style-Set, Umschaltung über den Karten-Button.
- Sheet: `DraggableScrollableSheet` mit 2 Snap-Sizes; Flugwechsel via `PageView` im Sheet-Inhalt.
- Fonts: `google_fonts` (Bebas Neue, Barlow). Datum: `showDatePicker` (Android) / `CupertinoDatePicker` (iOS).
- Notifications: `flutter_local_notifications`; Hintergrund-Polling: `workmanager` (Android) / BGTaskScheduler-Grenzen auf iOS beachten.
- HTTP: Rate-Limit 1 req/s je Quelle einhalten; Quellen-Adapter hinter einem Interface (feldidentisches readsb-Format, nur Base-URL/Registrierungspfad unterscheiden sich).

## Offene Punkte (bewusst nicht designt)
- Über-/Lizenzseite (Inhalt steht in den Einstellungen-Fußnoten).
- App-Icon-Export in allen Plattformgrößen.
- Listen-Detailzustände „beendet"/„verpasst" (Richtung: Wireframe 1e „VORBEI · weg in 24 h").
- Genaues Hintergrund-Polling-Konzept (iOS-Limits) — mit dem Nutzer klären.

## Files
- `Flugwacht-HiFi.dc.html` — Hi-Fi-Board, Runden 2–5 (hell + dunkel), maßgeblich.
- `Flugwacht-Wireframes.dc.html` — Wireframes Runde 1 (Flow-Referenz).
- `Logo-C-Auge.dc.html` — finales Logo inkl. App-Icon-Kacheln und Kleintest.
- `flugwacht-fachkonzept.md` — fachliches Handoff (Datenquellen, Fallstricke, Zustände) — verbindlich.
- `design-entscheidungen.md` — Protokoll aller UX-Entscheidungen.
- `.font-awesome.md` + `fa-regular-icons.json` — Icon-Setup und SVG-Fallback.
- `ios-frame.jsx` — nur Vorschau-Gerüst des Design-Tools, ignorieren.
- `screenshots/` — PNG-Referenzen aller 16 Screens (hell-* aus Runde 2/3, dunkel-* aus Runde 4/5, je 2×-Auflösung).
