# Handoff: Minimaler Flugtracker

Dieses Dokument beschreibt **Konzept und getroffene Entscheidungen**, keine Implementierung.
Technologiewahl, Projektstruktur und Code liegen bei dir.

---

## Was gebaut wird

Ein Flugtracker für **einzelne, selbst eingetragene Flüge** — nicht für den Luftraum.

Der Nutzer trägt einen Flug ein (Flugnummer + Datum, optional eine Notiz wie „Anna & Ben").
An diesem Tag wird der Flug automatisch verfolgt und auf einer Karte dargestellt.
Typischerweise stehen ein bis drei Flüge gleichzeitig auf der Liste.

Die Reduktion ist der Zweck, nicht ein Zwischenschritt. FlightRadar24 zeigt alles und ist
deshalb unbrauchbar für die eine Frage, die zählt: *Wo sind sie gerade, und wann sind sie da?*
Jede Funktion, die nicht auf diese Frage einzahlt, gehört nicht hinein.

---

## Muss-Felder

| Feld | Quelle | Anmerkung |
|---|---|---|
| Position (lat/lon) | ADS-B | |
| Höhe | ADS-B | barometrisch, siehe Fallstricke |
| Herkunft / Ziel | **separate Datenquelle** | kommt *nicht* aus ADS-B, siehe unten |
| Richtung | ADS-B | `track`, nicht `heading`, siehe Fallstricke |

Optional: Geschwindigkeit über Grund (zuverlässig), Eigengeschwindigkeit/Mach (nur sporadisch verfügbar).

---

## Datenquellen

Drei Community-Aggregatoren, alle auf readsb basierend und damit **feldidentisch**:

| ID | Base URL | Registrierungspfad |
|---|---|---|
| `adsblol` | `https://api.adsb.lol/v2` | `/registration/` |
| `adsbfi` | `https://opendata.adsb.fi/api/v2` | `/registration/` |
| `airplanes` | `https://api.airplanes.live/v2` | `/reg/` |

Gemeinsam: Endpunkte `/hex/`, `/callsign/`, `/point/{lat}/{lon}/{radius}`.
Antwortformat identisch (`{ac: [...], now, total, ...}`). Rate Limit jeweils **1 Anfrage/Sekunde**.
Kein Account, kein API-Key.

### Quellenauswahl statt Zusammenführung

Der Nutzer wählt **eine** aktive Quelle. Es wird nicht gemergt, nicht parallel abgefragt,
kein Failover. Zweck der Auswahl ist der manuelle Vergleich: umschalten, beobachten,
entscheiden, welche Quelle den eigenen Flug zuverlässiger sieht.

Weil die Quellen feldidentisch sind, unterscheiden sie sich **ausschließlich in der
Empfängerabdeckung** — also darin, ob der Flieger zu einem Zeitpunkt gesehen wird oder nicht.
Die Zahlenwerte sind bei allen dieselben, sie stammen vom selben Transponder.

Damit der Vergleich beim Umschalten nicht bei null anfängt: erfasste Positionen gehören
zum Flug, nicht zur Quelle. Der Verlauf ist fortlaufend, jeder Punkt trägt seine Quellen-ID.
Auf der Karte lässt sich daraus pro Quelle eine eigene Spur zeichnen — das ist das
Vergleichswerkzeug.

---

## Explizit verworfen — bitte nicht wieder einführen

**OpenSky Network.** Zeitauflösung 5 s für authentifizierte Nutzer (10 s anonym), also
prinzipiell nicht aktueller zu bekommen. Kreditbudget von 4.000/Tag reicht nicht für
einen einzigen Langstreckenflug. Kein Callsign-Endpunkt, Suche nur über Hex oder Bounding Box.
Wäre die einzige Option für *nachträgliche* Flugspuren — wird nicht gebraucht, siehe unten.

**Eigener ADS-B-Empfänger.** Würde bessere Zugänge freischalten (Direct-Backend-APIs,
aggregierte Beast-Streams), ist aber ausdrücklich nicht gewünscht.

**Historie.** Nur Live-Verfolgung. Die gewählten Quellen sind reine Live-Snapshots — ein
beendeter Flug existiert dort nicht mehr. Kein nachträgliches Abrufen verpasster Flüge.

**Bezahlquellen, Satelliten-ADS-B.** Nicht im Rahmen.

---

## Route ist keine ADS-B-Information

Der wichtigste Architekturpunkt.

Ein Transponder sendet Kennung, Position, Höhe, Geschwindigkeit, Track, Squawk.
**Start und Ziel sind nicht dabei.** Sie werden über das Callsign in einer separaten
Datenbank nachgeschlagen.

Daraus folgen zwei grundverschiedene Datenpfade:

- **Position** — hochfrequent, flüchtig, im Sekundentakt
- **Route** — einmal pro Flug aufgelöst, dann für dessen Dauer gecacht

Quelle ist das offene Dataset `vradarserver/standing-data` (Callsign → Flughafenpaar).
Entweder direkt ins Projekt geholt und lokal nachgeschlagen — bevorzugt, weil ohne
Netzwerk, Latenz und Limit — oder über den Routen-Endpunkt von adsb.lol als Service.

Grenzen des Datasets, die in der UI ehrlich abgebildet gehören: es enthält die **geplante**
Route. Ausweichlandungen erscheinen nicht. Charter- und Privatflüge fehlen oft ganz.
„Route unbekannt" ist ein regulärer Zustand, kein Fehler.

---

## Datenmodell

Ein normalisiertes Positions-Objekt („Fix") entkoppelt die App vom Drahtformat.
Nicht wegen Quellenvielfalt — die Quellen sind ja identisch — sondern weil das readsb-Format
Eigenheiten hat, die man sonst durch die gesamte Anwendung trägt.

Konzeptuell enthält ein Fix:

- **Identität** — Hex-Adresse, Callsign, Registrierung, Muster
- **Position** — lat, lon, Höhe (baro und geom getrennt), Bodenflag, Track, Heading, Geschwindigkeiten, Steigrate
- **Frische** — Zeitpunkt der Positionsmessung als **absoluter Zeitstempel**
- **Herkunft** — ID der Quelle, die diesen Fix geliefert hat

Die Route ist ein eigenes Objekt am Flug, nicht Teil des Fix. Sie ändert sich nicht im Sekundentakt.

### Identität gehört dem Flug

Gesucht wird über die Flugnummer, gefunden wird ein Flugzeug mit einer Hex-Adresse.
Diese Adresse ist der stabile Schlüssel für weitere Abfragen und gehört an den Flug-Record,
nicht in die Quellen-Ebene.

**Wichtige Absicherung:** die Hex-Adresse identifiziert die *Zelle*, nicht den *Flug*.
Dasselbe Flugzeug fliegt am selben Tag weitere Strecken. Wer stur über Hex weiterfragt,
verfolgt irgendwann den falschen Flug. Bei jeder Hex-Abfrage muss geprüft werden, ob das
zurückgegebene Callsign noch zum erwarteten passt — sonst zurück auf die Callsign-Suche.

---

## Fallstricke der Domäne

**Höhe gibt es zweimal.** `alt_baro` ist barometrisch auf 1013,25 hPa bezogen — das ist,
was ATC meint und was „FL350" bedeutet. `alt_geom` ist GNSS-Höhe über dem WGS84-Ellipsoid.
Die beiden weichen routinemäßig um mehrere hundert Fuß voneinander ab. Für die Anzeige gilt
`alt_baro`.

**`alt_baro` ist nicht immer eine Zahl.** Am Boden liefert readsb den String `"ground"`.
Muss beim Normalisieren abgefangen werden.

**Richtung gibt es dreimal.** `track` ist die Bewegungsrichtung über Grund.
`true_heading` ist, wohin die Nase zeigt — im Jetstream 10–15° daneben, weil das Flugzeug
gegen den Wind vorhält. Fürs Kartensymbol gilt `track`. `heading` ist optional und nicht
immer vorhanden.

**Positionsalter ist relativ.** readsb liefert `seen_pos` als Alter in Sekunden, zusammen mit
`now` als Serverzeit. Beim Normalisieren in einen absoluten Zeitstempel umrechnen — und dabei
die **Serverzeit** verwenden, nicht die lokale Uhr, sonst wandert Uhrenversatz ins Modell.

**Callsigns sind aufgefüllt.** Auf 8 Zeichen mit Leerzeichen. Immer trimmen, sonst schlägt
jeder Vergleich fehl.

**Flugnummer ≠ Callsign.** `LH400` heißt im Funk `DLH400`. Es braucht eine IATA→ICAO-Zuordnung
der Fluggesellschaften. Bei Ryanair, Wizz und easyJet stimmt selbst das nicht: dort ist das
Rufzeichen oft völlig unabhängig von der Flugnummer. Für diese Fälle braucht der Nutzer einen
Ausweg — Eingabe per Kennzeichen (`D-AIMA`) oder Hex-Code — und einen Hinweis in der
Oberfläche, sobald so eine Airline erkannt wird.

**Empfangslücken sind normal, kein Fehlerfall.** Die Abdeckung stammt von privaten Empfängern
am Boden. Über Ozeanen, Wüsten und Polarregionen bricht die Spur ab, teils für ein bis zwei
Stunden, und kommt danach wieder. Das gilt für alle drei Quellen gleichermaßen. Die Oberfläche
muss das als eigenen Zustand zeigen, nicht als Absturz oder Verlust.

---

## Zustände eines Flugs

Ein Flug durchläuft eine Sequenz, die sich aus Datum und Positionsalter ergibt:

- **geplant** — Tag noch nicht erreicht, keine Abfragen
- **wartet** — Tag läuft, noch nie ein Signal empfangen
- **live** — Position frisch
- **kein Signal** — war schon einmal live, Position inzwischen veraltet (Empfangslücke)
- **beendet** — Zeitfenster vorbei, Flug wurde gesehen
- **verpasst** — Zeitfenster vorbei, nie ein Signal

Der Übergang live → kein Signal braucht eine großzügige Schwelle (Größenordnung 10–15 Minuten).
Zu knapp bemessen flackert die Anzeige bei jeder normalen Empfangslücke.

Das Zeitfenster eines Flugtags sollte über Mitternacht hinausreichen — Nachtflüge starten am
einen und landen am anderen Tag.

---

## Ankunftszeit

Die Zahl, die den Nutzer eigentlich interessiert. Aus Restdistanz zum Zielflughafen und
Bodengeschwindigkeit lässt sich eine grobe Schätzung rechnen. Sie ist bewusst ungenau —
Anflugverfahren, Warteschleifen und Rollzeit sind nicht enthalten. Entsprechend vage
beschriften („Ankunft ca."), keine Minutengenauigkeit vortäuschen.

Setzt eine aufgelöste Route voraus; ohne Ziel keine Schätzung.

---

## Offene Entscheidungen

**Wo läuft das Polling?** Reines Frontend bedeutet: Tab zu, Spur weg. Ein Hintergrundprozess
schreibt durchgehend mit, auch ohne offenen Browser — bei Langstreckenflügen ein spürbarer
Unterschied. Das ist die grundlegendste offene Frage und beeinflusst alles Weitere.

**Persistenz.** Sollen Flüge und Spuren einen Neustart überleben?

**Zeitzonen.** Der eingetragene „Tag" ist Ortszeit des Nutzers, ADS-B-Zeitstempel sind UTC.
Bei Flügen über die Datumsgrenze braucht das eine bewusste Festlegung.

---

## Lizenz und Namensnennung

Alle drei Quellen sind für den **privaten, nicht-kommerziellen** Gebrauch freigegeben.
adsb.lol steht unter ODbL. Die genutzte Quelle gehört sichtbar genannt, ebenso die
Kartendaten. Keine Zusicherungen zu Verfügbarkeit oder Aktualität — die Netze laufen
ehrenamtlich, ohne SLA.
