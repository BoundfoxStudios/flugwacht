// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Flugwacht';

  @override
  String get tabMap => 'Karte';

  @override
  String get tabList => 'Flüge';

  @override
  String get tabMore => 'Mehr';

  @override
  String get listTitle => 'Flüge';

  @override
  String get listHeaderDateFormat => 'ccc, d. MMMM';

  @override
  String get listEmptyHeadline => 'Noch kein Flug\nauf der Liste';

  @override
  String get listEmptyBody =>
      'Trag einen Flug ein — Flugwacht verfolgt ihn am Flugtag automatisch und zeigt dir, wann er ankommt.';

  @override
  String get listEmptyCta => 'Flug eintragen';

  @override
  String get newFlightTitle => 'Neuer Flug';

  @override
  String get newFlightCancel => 'Abbrechen';

  @override
  String get newFlightKindFlightNumber => 'Flugnummer';

  @override
  String get newFlightKindRegistration => 'Kennzeichen';

  @override
  String get newFlightKindHexAddress => 'Hex';

  @override
  String get newFlightFlightNumberHint => 'Wie auf dem Ticket, z. B. LH 400';

  @override
  String get newFlightRegistrationHint =>
      'Kennzeichen des Flugzeugs, z. B. D-AIMA';

  @override
  String get newFlightHexAddressHint =>
      'Sechsstellige ICAO-Adresse, z. B. 3C6444';

  @override
  String get newFlightLowCostCarrierHint =>
      'Ryanair, easyJet und Wizz Air fliegen oft unter einem Rufzeichen, das nicht zur Flugnummer passt. Findet Flugwacht deinen Flug nicht, trag ihn über Kennzeichen oder Hex ein.';

  @override
  String get newFlightDepartureDateLabel => 'Startdatum';

  @override
  String get newFlightDepartureDateHint =>
      'Tag des Abflugs · öffnet die Systemauswahl · Nachtflüge zählen bis in den Folgetag';

  @override
  String get newFlightDepartureDateFormat => 'ccc, d. MMMM y';

  @override
  String get newFlightDepartureTimeLabel => 'Abflugzeit (optional)';

  @override
  String get newFlightDepartureTimeHint =>
      'Geplanter Abflug · die Suche startet zwei Stunden davor';

  @override
  String get newFlightDepartureTimePlaceholder => 'Keine Angabe';

  @override
  String get newFlightDepartureTimeClear => 'Abflugzeit löschen';

  @override
  String get newFlightDepartureTimeFormat => 'HH:mm';

  @override
  String get newFlightNoteLabel => 'Notiz (optional)';

  @override
  String get newFlightNoteHint =>
      'Woran du den Flug erkennst, z. B. Anna & Ben';

  @override
  String get newFlightSubmit => 'Flug eintragen';

  @override
  String get newFlightDatePickerConfirm => 'Fertig';

  @override
  String get newFlightPreviewFound => 'Gefunden';

  @override
  String get newFlightPreviewRouteUnknown => 'Route unbekannt';

  @override
  String newFlightPreviewCallsign(String callsign) {
    return 'Funk: $callsign';
  }

  @override
  String newFlightPreviewRoute(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String newFlightPreviewRouteWithAirline(
    String origin,
    String destination,
    String airline,
  ) {
    return '$origin → $destination · $airline';
  }

  @override
  String get listPastSectionTitle => 'Vorbei · weg in 24 h';

  @override
  String get listFlightDeleted => 'Flug gelöscht';

  @override
  String get listUndoDelete => 'Rückgängig';

  @override
  String get listDeleteFlight => 'Flug löschen';

  @override
  String get listPlannedDateFormat => 'ccc, d. LLL';

  @override
  String flightTitleWithNote(String lookupValue, String note) {
    return '$lookupValue · $note';
  }

  @override
  String flightRoute(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String flightRowSubtitle(String route, String state) {
    return '$route · $state';
  }

  @override
  String get flightBadgeLive => 'Live';

  @override
  String get flightBadgeNoSignal => 'Kein Signal';

  @override
  String get mapAttributionOpenStreetMap => '© OpenStreetMap';

  @override
  String get mapStyleToggleLabel => 'Kartenstil wechseln';

  @override
  String get mapRecenterLabel => 'Auf den Flug zentrieren';

  @override
  String get mapAttributionOpenMapTiles => '© OpenStreetMap · © OpenMapTiles';

  @override
  String mapAttributionWithSource(String attribution, String source) {
    return '$attribution · Daten: $source';
  }

  @override
  String get mapLegendTitle => 'SPUR JE QUELLE';

  @override
  String get mapLegendActive => 'aktiv';

  @override
  String get mapSheetArrivalPlaceholder => '–:–';

  @override
  String get mapSheetValuePlaceholder => '–';

  @override
  String get mapSheetAltitudeLabel => 'Höhe';

  @override
  String get mapSheetSpeedLabel => 'Tempo';

  @override
  String get mapSheetSignalLabel => 'Signal';

  @override
  String mapSheetSignalSeconds(String seconds) {
    return 'vor $seconds s';
  }

  @override
  String mapSheetSignalMinutes(String minutes) {
    return 'vor $minutes Min';
  }

  @override
  String mapSheetSignalHours(String hours) {
    return 'vor $hours Std';
  }

  @override
  String mapSheetSignalHoursMinutes(String hours, String minutes) {
    return 'vor $hours Std $minutes Min';
  }

  @override
  String mapSheetNoSignalInfo(String age) {
    return 'Letztes Signal $age. Über Ozeanen gibt es oft 1–2 Stunden keine Empfänger — die Spur kommt wieder.';
  }

  @override
  String mapSheetAltitudeValue(String value) {
    return '$value m';
  }

  @override
  String mapSheetSpeedValue(String value) {
    return '$value km/h';
  }

  @override
  String mapSheetAltitudeValueFeet(String value) {
    return '$value ft';
  }

  @override
  String mapSheetSpeedValueKnots(String value) {
    return '$value kt';
  }

  @override
  String mapSheetSource(String source, String attribution) {
    return 'Quelle: $source · $attribution';
  }

  @override
  String get mapSheetTryAnotherSource => 'Andere Quelle probieren';

  @override
  String get flightArrivalLabel => 'Ankunft ca.';

  @override
  String get flightArrivalTimeFormat => 'HH:mm';

  @override
  String flightArrivalFrozenTime(String time) {
    return '~$time';
  }

  @override
  String flightArrivalRemainingMinutes(String minutes) {
    return 'noch $minutes Min';
  }

  @override
  String flightArrivalRemainingHours(String hours) {
    return 'noch $hours Std';
  }

  @override
  String flightArrivalRemainingHoursMinutes(String hours, String minutes) {
    return 'noch $hours Std $minutes Min';
  }

  @override
  String flightArrivalAsOf(String age) {
    return 'Stand: $age';
  }

  @override
  String flightArrivalLocalTime(String city, String time) {
    return 'Ortszeit $city · bei dir $time';
  }

  @override
  String flightArrivalSummary(String label, String detail) {
    return '$label · $detail';
  }

  @override
  String get flightRowWaitingForSignal => 'wartet auf Signal';

  @override
  String get flightRowToday => 'heute';

  @override
  String get flightRowYesterday => 'gestern';

  @override
  String flightRowPastSubtitle(String route, String day) {
    return '$route · $day';
  }

  @override
  String flightRowDepartureTime(String time) {
    return 'ab $time';
  }

  @override
  String get flightRowDepartureTimeFormat => 'HH:mm';

  @override
  String get flightRowLanded => 'gelandet ✓';

  @override
  String get flightRowMissed => 'verpasst';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSourceSectionTitle => 'Datenquelle';

  @override
  String get settingsSourceExplainer =>
      'Alle Quellen liefern dieselben Werte — sie unterscheiden sich nur darin, wer deinen Flieger gerade empfängt. Bei Lücken lohnt das Umschalten; die Spur läuft dabei weiter.';

  @override
  String get settingsUnitsSectionTitle => 'Einheiten';

  @override
  String get settingsUnitsMetric => 'Metrisch (m, km/h)';

  @override
  String get settingsUnitsAviation => 'Luftfahrt (ft, kt)';

  @override
  String get settingsNotificationsSectionTitle => 'Mitteilungen';

  @override
  String get settingsNotificationDeparted => 'Gestartet';

  @override
  String get settingsNotificationArrivingSoon => 'Ankunft bald (~30 Min)';

  @override
  String get settingsNotificationLanded => 'Gelandet';

  @override
  String get settingsNotificationsDelivery =>
      'Gestartet und Gelandet erreichen dich nur, solange Flugwacht offen ist. Ankunft bald kommt auch bei geschlossener App — ungefähr zum richtigen Zeitpunkt.';

  @override
  String get settingsNotificationsDenied =>
      'In deinen Systemeinstellungen sind Mitteilungen für Flugwacht ausgeschaltet.';

  @override
  String get settingsNotificationsUnavailable =>
      'Auf diesem Gerät ließen sich Mitteilungen nicht einrichten — die Schalter oben bleiben ohne Wirkung.';

  @override
  String get notificationOfferTitle => 'Mitteilungen einschalten?';

  @override
  String get notificationOfferBody =>
      'Flugwacht sagt dir, wann dein Flug gestartet ist, bald ankommt und gelandet ist. Du kannst das jederzeit in den Einstellungen ändern.';

  @override
  String get notificationOfferAccept => 'Ja, gerne';

  @override
  String get notificationOfferDecline => 'Nein, danke';

  @override
  String get settingsAboutTitle => 'Über Flugwacht';

  @override
  String settingsAboutSubtitle(String version) {
    return 'Version $version · Lizenzen & Quellen';
  }

  @override
  String get aboutTitle => 'Über Flugwacht';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutSourcesSectionTitle => 'Daten & Karte';

  @override
  String aboutSources(String sources) {
    return 'Flugdaten: $sources — frei für privaten Gebrauch, Community-Netze ohne Gewähr auf Verfügbarkeit oder Aktualität.';
  }

  @override
  String get aboutMapAttribution => 'Karte © OpenStreetMap-Mitwirkende.';

  @override
  String get aboutIconCredit => 'Icons: Font Awesome Pro';

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutBoundfox => 'Ein Projekt von Boundfox Studios';

  @override
  String get aboutGithub => 'Flugwacht auf GitHub';

  @override
  String get settingsFaqTitle => 'Häufige Fragen';

  @override
  String get faqTitle => 'Häufige Fragen';

  @override
  String get faqOtherServicesQuestion =>
      'Warum weichen die Daten von FlightRadar24 & Co. ab?';

  @override
  String get faqOtherServicesAnswer =>
      'Solche Dienste mischen ADS-B mit MLAT, Satellitenempfang und Flugplandaten der Airlines. Flugwacht zeigt nur, was Community-Empfänger tatsächlich hören — keine Schätzungen aus Flugplänen. Dafür bleiben Lücken, wo niemand mithört.';

  @override
  String get faqArrivalAccuracyQuestion =>
      'Warum ist die Ankunftszeit manchmal ungenau?';

  @override
  String get faqArrivalAccuracyAnswer =>
      'Sie ist die Restdistanz geteilt durch die aktuelle Geschwindigkeit über Grund. Warteschleifen, Anflugführung, Rollzeit und der Wind auf dem letzten Stück stecken nicht darin. Je näher der Flug kommt, desto genauer wird sie; ein „~“ markiert eine Schätzung auf Basis einer älteren Position.';

  @override
  String get faqTrailStartQuestion =>
      'Warum sehe ich die Spur erst ab dem Hinzufügen?';

  @override
  String get faqTrailStartAnswer =>
      'Es gibt keine Historie zum Nachladen. Die Quellen melden den aktuellen Zustand, und Flugwacht baut die Spur selbst aus den Punkten, die sie ab diesem Moment sammelt. Ein Flug, den du mitten in der Luft hinzufügst, startet deshalb ohne Spur.';

  @override
  String get faqFlightNotFoundQuestion => 'Warum finde ich meinen Flug nicht?';

  @override
  String get faqFlightNotFoundAnswer =>
      'Ein Flug taucht erst auf, wenn ihn ein Empfänger hört: nicht vor dem Start und nicht in Regionen ohne Abdeckung. Prüfe die Flugnummer so, wie die Airline sie schreibt (LH400, nicht DLH400), oder suche über Registrierung oder Hex-Adresse. Auch eine andere Quelle zu probieren lohnt sich.';

  @override
  String get faqTrailGapsQuestion => 'Warum hat die Spur Lücken?';

  @override
  String get faqTrailGapsAnswer =>
      'ADS-B braucht einen Empfänger am Boden in Reichweite. Über Ozeanen, Wüsten und Polarrouten gibt es oft ein bis zwei Stunden lang keinen. Die Spur pausiert dann und geht danach weiter.';

  @override
  String get faqFlightsDisappearQuestion =>
      'Warum verschwinden Flüge nach der Landung?';

  @override
  String get faqFlightsDisappearAnswer =>
      'Flüge räumen sich 24 Stunden nach der Landung selbst auf. So bleibt in der Liste, was noch vor dir liegt.';

  @override
  String get faqLateNotificationQuestion =>
      'Warum kommt eine Mitteilung manchmal spät?';

  @override
  String get faqLateNotificationAnswer =>
      'Das Betriebssystem entscheidet, wann eine App im Hintergrund laufen darf. Im Energiesparmodus oder wenn du die App selten öffnest, kann die Meldung ein paar Minuten später ankommen.';

  @override
  String get faqDataOriginQuestion => 'Woher kommen die Daten?';

  @override
  String get faqDataOriginAnswer =>
      'Freiwillige betreiben ADS-B-Empfänger und teilen in offenen Netzwerken wie adsb.lol und adsb.fi, was sie hören. Keine Airline, kein offizieller Feed — deshalb ist es kostenlos, und deshalb gibt es keine Gewähr.';

  @override
  String get faqAccountQuestion => 'Brauche ich ein Konto?';

  @override
  String get faqAccountAnswer =>
      'Nein. Kein Konto, kein Server, keine Anmeldung. Flüge und Einstellungen bleiben auf dem Gerät; nach draußen gehen nur die Abfragen an die gewählte Quelle und die Kartenkacheln.';

  @override
  String get notificationDepartedBody => 'Der Flug ist gestartet.';

  @override
  String get notificationArrivingSoonBody => 'Ankunft in etwa 30 Minuten.';

  @override
  String get notificationLandedBody => 'Der Flug ist gelandet.';

  @override
  String get notificationChannelName => 'Flugstatus';

  @override
  String get notificationChannelDescription =>
      'Start, Ankunft und Landung deiner Flüge.';

  @override
  String get flightStatePlanned => 'geplant';

  @override
  String get flightStateWaiting => 'wartet';

  @override
  String get flightStateLive => 'live';

  @override
  String get flightStateNoSignal => 'kein Signal';

  @override
  String get flightStateEnded => 'beendet';
}
