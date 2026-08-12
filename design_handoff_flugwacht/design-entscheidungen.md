# Flugwacht — Design-Entscheidungen

App: Minimaler Flugtracker (Flutter, iOS + Android). Quelle: uploads/flugwacht.md (Handoff).
Design System: Boundfox Studios (Bebas Neue, Barlow, Gelb-Trio #ffeb3b/#ffc107/#ffa726, Neutrals). Du-Form, kein Emoji.

## Logo (final: C „Radar-Auge")
Auge (Umriss #262626, sw 2.6, rund), Iris-Scheibe #262626 r8.8, Radar-Sweep-Keil #ffc107, feiner Ring #ffeb3b r4.8, Punkt #ffeb3b. Dunkle Fläche: Umriss #fafafa, Iris #404040. Datei: Logo-C-Auge.dc.html. Verworfen: A Radar-Ping, B Facetten, C2/C3/C4/C5-Varianten, D Wortmarke. Wortmarke: FLUGWACHT, Bebas Neue, ohne Untertitel.

## UX-Entscheidungen (aus 9 Fragerunden)
- Prozess: Wireframes zuerst (2–3 Varianten je Screen), dann Hi-Fi. Mockup: iOS-Frame.
- Hauptscreen: Vollbild-Karte + Boden-Sheet. Mehrere Flüge gleichzeitig auf der Karte; Wechsel per Sheet-Wischen ODER Antippen auf Karte.
- Heute-Liste: eigener Screen. Navigation: Tab-Bar unten (Karte · Liste · Einstellungen).
- Sheet prominent: „Ankunft ca." groß — Countdown UND Uhrzeit, Uhrzeit in BEIDEN Zonen (Ziel-Ortszeit + meine Zeit). Status + Position sekundär.
- Zustände (geplant/wartet/live/kein Signal/beendet/verpasst): als Zeitleiste, in Liste UND Detail-Sheet. „Kein Signal" großzügig (10–15 min), eigener Zustand, kein Fehler.
- Flug hinzufügen: EIN Screen (Wireframe 1h); Datum öffnet NATIVES OS-Datum-Control (kein Inline-Kalender); alternative Eingabe (Kennzeichen D-AIMA / Hex) IMMER wählbar; Ryanair/Wizz/easyJet-Hinweis; Route-Vorschau („Gefunden“) inline vor dem Speichern.
- Quellen (adsb.lol/adsb.fi/airplanes.live): eine aktive, Umschalter in Einstellungen; Spur pro Quelle einfärbbar (Vergleich); Quellen-Nennung + OSM-Attribution sichtbar.
- Kartenstil: OSM echt + reduziert/stilisiert, Wechsel-Button AUF der Karte.
- Einheiten: umschaltbar, Default metrisch (Laien-Zielgruppe).
- Alte Flüge: auto-weg nach 24 h. Leerzustand: Erklärung + CTA (Wireframe 1i), Demo-Flug GESTRICHEN.
- Push (lokal, ohne Backend geplant): Gestartet · Ankunft bald (~30 min) · Gelandet. Machbarkeit Hintergrund-Tracking klärt User mit Claude Code.
- Branding: dezent, Boundfox-Fuchs nur auf Über-Seite.
- Screens Runde 1: Heute-Liste, Flug hinzufügen, Live-Karte (Detail), Leerzustand.

## Wireframe-Auswahl (Board: Flugwacht-Wireframes.dc.html)
- Karte: 1a Peek-Sheet ↔ 1b hochgezogen = zwei Positionen desselben Sheets (bestätigt). Liste bleibt eigener Tab.
- Liste: 1f Hero-Zelle mit Mini-Karte. Wizard: 1h Ein-Screen. Leerzustand: 1i ohne Demo.

## Icons
Font Awesome Pro, Stil **regular** (klassisch). Web-Kit-ID 85fa8e3a78 (Script im helmet); Details in .font-awesome.md. Lucide ersetzt. In Flutter: font_awesome_flutter + Pro-Lizenz.

## Arbeitsvereinbarung
- In jedem Formular immer ein Freitextfeld anbieten.
