// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

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
  String get listTitle => 'Flights';

  @override
  String get listHeaderDateFormat => 'EEE, MMMM d';

  @override
  String get listEmptyHeadline => 'No flight\non the list yet';

  @override
  String get listEmptyBody =>
      'Add a flight — Flugwacht tracks it automatically on its flight day and shows you when it arrives.';

  @override
  String get listEmptyCta => 'Add flight';

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
  String get newFlightDepartureTimeLabel => 'Departure time (optional)';

  @override
  String get newFlightDepartureTimeHint =>
      'Scheduled departure · the search starts two hours before it';

  @override
  String get newFlightDepartureTimePlaceholder => 'Not set';

  @override
  String get newFlightDepartureTimeClear => 'Clear the departure time';

  @override
  String get newFlightDepartureTimeFormat => 'h:mm a';

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

  @override
  String get listPastSectionTitle => 'Past';

  @override
  String get listPlannedDateFormat => 'EEE, MMM d';

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
  String get flightBadgeNoSignal => 'No signal';

  @override
  String get mapAttributionOpenStreetMap => '© OpenStreetMap';

  @override
  String mapAttributionWithSource(String source) {
    return '© OpenStreetMap · Data: $source';
  }

  @override
  String get mapLegendTitle => 'TRAIL BY SOURCE';

  @override
  String get mapLegendActive => 'active';

  @override
  String get mapSheetArrivalPlaceholder => '–:–';

  @override
  String get mapSheetValuePlaceholder => '–';

  @override
  String get mapSheetAltitudeLabel => 'Altitude';

  @override
  String get mapSheetSpeedLabel => 'Speed';

  @override
  String get mapSheetSignalLabel => 'Signal';

  @override
  String mapSheetSignalSeconds(String seconds) {
    return '$seconds s ago';
  }

  @override
  String mapSheetSignalMinutes(String minutes) {
    return '$minutes min ago';
  }

  @override
  String mapSheetSignalHours(String hours) {
    return '$hours h ago';
  }

  @override
  String mapSheetSignalHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min ago';
  }

  @override
  String mapSheetNoSignalInfo(String age) {
    return 'Last signal $age. Over oceans there are often no receivers for 1–2 hours — the trail will come back.';
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
  String mapSheetSource(String source) {
    return 'Source: $source · © OpenStreetMap';
  }

  @override
  String get mapSheetSourceComparison =>
      'The trail survives switching — every point knows its source.';

  @override
  String get flightArrivalLabel => 'Approx. arrival';

  @override
  String get flightArrivalTimeFormat => 'h:mm a';

  @override
  String flightArrivalFrozenTime(String time) {
    return '~$time';
  }

  @override
  String flightArrivalRemainingMinutes(String minutes) {
    return '$minutes min left';
  }

  @override
  String flightArrivalRemainingHours(String hours) {
    return '$hours h left';
  }

  @override
  String flightArrivalRemainingHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min left';
  }

  @override
  String flightArrivalAsOf(String age) {
    return 'As of $age';
  }

  @override
  String flightArrivalLocalTime(String city, String time) {
    return 'Local time $city · your time $time';
  }

  @override
  String flightArrivalSummary(String label, String detail) {
    return '$label · $detail';
  }

  @override
  String get flightRowWaitingForSignal => 'waiting for signal';

  @override
  String get flightRowToday => 'today';

  @override
  String flightRowDepartureTime(String time) {
    return 'from $time';
  }

  @override
  String get flightRowDepartureTimeFormat => 'h:mm a';

  @override
  String get flightRowLanded => 'landed ✓';

  @override
  String get flightRowMissed => 'missed';

  @override
  String get flightStatePlanned => 'planned';

  @override
  String get flightStateWaiting => 'waiting';

  @override
  String get flightStateLive => 'live';

  @override
  String get flightStateNoSignal => 'no signal';

  @override
  String get flightStateEnded => 'ended';
}
