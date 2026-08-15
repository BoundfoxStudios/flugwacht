// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flugwacht';

  @override
  String get tabMap => 'Map';

  @override
  String get tabList => 'List';

  @override
  String get tabMore => 'More';

  @override
  String get newFlightTitle => 'New flight';

  @override
  String get newFlightCancel => 'Cancel';

  @override
  String get newFlightKindFlightNumber => 'Flight number';

  @override
  String get newFlightKindRegistration => 'Registration';

  @override
  String get newFlightKindHexAddress => 'Hex';

  @override
  String get newFlightFlightNumberHint =>
      'As printed on your ticket, e.g. LH 400';

  @override
  String get newFlightRegistrationHint =>
      'The registration of the aircraft, e.g. D-AIMA';

  @override
  String get newFlightHexAddressHint =>
      'The six digit ICAO address, e.g. 3C6444';

  @override
  String get newFlightLowCostCarrierHint =>
      'Ryanair, easyJet and Wizz Air often fly under a callsign that does not match the flight number. If your flight stays unfound, add it by registration or hex address.';

  @override
  String get newFlightDepartureDateLabel => 'Departure date';

  @override
  String get newFlightDepartureDateHint =>
      'Day of departure · opens the system picker · night flights count into the next day';

  @override
  String get newFlightDepartureDateFormat => 'EEE, MMMM d, y';

  @override
  String get newFlightNoteLabel => 'Note (optional)';

  @override
  String get newFlightNoteHint =>
      'Whatever helps you recognise the flight, e.g. Anna & Ben';

  @override
  String get newFlightSubmit => 'Add flight';

  @override
  String get newFlightDatePickerConfirm => 'Done';

  @override
  String get newFlightPreviewFound => 'Found';

  @override
  String get newFlightPreviewRouteUnknown => 'Route unknown';

  @override
  String newFlightPreviewCallsign(String callsign) {
    return 'Callsign: $callsign';
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
}
