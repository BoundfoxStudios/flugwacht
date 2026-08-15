// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Flugwacht';

  @override
  String get tabMap => 'Karte';

  @override
  String get tabList => 'Liste';

  @override
  String get tabMore => 'Mehr';

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
  String get newFlightDepartureDateFormat => 'EEE, d. MMMM y';

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
