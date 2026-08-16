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
