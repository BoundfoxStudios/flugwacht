import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final window = FlightDayWindow.forDepartureDate(
    const CalendarDate(2026, 3, 17),
  );

  DateTime afterWindowStart(Duration offset) =>
      window.start.add(offset).toUtc();

  Fix positionFix(DateTime timestamp, {bool? onGround}) => Fix(
    hexAddress: '3c64c6',
    sourceId: SourceId.adsblol,
    position: FixPosition(
      latitude: 49.875687,
      longitude: 7.888834,
      timestamp: timestamp,
      onGround: onGround,
    ),
  );

  const identityOnlyFix = Fix(hexAddress: '3c64c6', sourceId: SourceId.adsblol);

  test('starts a flight with empty tracking', () {
    const flight = Flight(
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH433',
      departureDate: CalendarDate(2026, 3, 17),
    );
    expect(flight.tracking.latestPosition, isNull);
    expect(flight.tracking.hasBeenAirborne, isFalse);
    expect(flight.tracking.lastKnownOnGround, isNull);
  });

  test('leaves tracking untouched for a fix without a position', () {
    const tracking = FlightTracking();
    expect(tracking.withFix(identityOnlyFix, window), same(tracking));
  });

  test('leaves tracking untouched for a position fix before the window', () {
    const tracking = FlightTracking();
    final fix = positionFix(
      window.start.subtract(const Duration(minutes: 1)).toUtc(),
      onGround: false,
    );
    expect(tracking.withFix(fix, window), same(tracking));
  });

  test('takes a position fix timestamped exactly at the window start', () {
    final fix = positionFix(afterWindowStart(Duration.zero), onGround: true);
    final tracking = const FlightTracking().withFix(fix, window);
    expect(tracking.latestPosition, same(fix.position));
    expect(tracking.lastKnownOnGround, isTrue);
    expect(tracking.hasBeenAirborne, isFalse);
  });

  test('latches hasBeenAirborne and keeps it latched after landing', () {
    final airborne = const FlightTracking().withFix(
      positionFix(afterWindowStart(const Duration(hours: 2)), onGround: false),
      window,
    );
    expect(airborne.hasBeenAirborne, isTrue);
    expect(airborne.lastKnownOnGround, isFalse);

    final landed = airborne.withFix(
      positionFix(afterWindowStart(const Duration(hours: 8)), onGround: true),
      window,
    );
    expect(landed.hasBeenAirborne, isTrue);
    expect(landed.lastKnownOnGround, isTrue);
  });

  test('keeps the last known ground state when a fix omits it', () {
    final onGround = const FlightTracking().withFix(
      positionFix(afterWindowStart(const Duration(hours: 1)), onGround: true),
      window,
    );
    final withoutGroundState = onGround.withFix(
      positionFix(afterWindowStart(const Duration(hours: 3))),
      window,
    );
    expect(
      withoutGroundState.latestPosition!.timestamp,
      afterWindowStart(const Duration(hours: 3)),
    );
    expect(withoutGroundState.lastKnownOnGround, isTrue);
  });

  test('copies a flight with new tracking and keeps every other field', () {
    const flight = Flight(
      lookupKind: FlightLookupKind.registration,
      lookupValue: 'D-AIFF',
      departureDate: CalendarDate(2026, 3, 17),
      note: 'Window seat',
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH433',
    );
    final tracking = const FlightTracking().withFix(
      positionFix(afterWindowStart(const Duration(hours: 1)), onGround: true),
      window,
    );

    final updated = flight.copyWith(tracking: tracking);

    expect(updated.tracking, same(tracking));
    expect(updated.lookupKind, FlightLookupKind.registration);
    expect(updated.lookupValue, 'D-AIFF');
    expect(updated.departureDate, const CalendarDate(2026, 3, 17));
    expect(updated.note, 'Window seat');
    expect(updated.hexAddress, '3c64c6');
    expect(updated.expectedCallsign, 'DLH433');
  });

  test('copies a flight with every passed field replaced', () {
    const flight = Flight(
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH433',
      departureDate: CalendarDate(2026, 3, 17),
      note: 'Window seat',
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH433',
    );
    final tracking = const FlightTracking().withFix(
      positionFix(afterWindowStart(const Duration(hours: 1)), onGround: false),
      window,
    );

    final updated = flight.copyWith(
      lookupKind: FlightLookupKind.hexAddress,
      lookupValue: '3C64C7',
      departureDate: const CalendarDate(2026, 4, 1),
      note: 'Aisle seat',
      hexAddress: '3c64c8',
      expectedCallsign: 'DLH434',
      tracking: tracking,
    );

    expect(updated.lookupKind, FlightLookupKind.hexAddress);
    expect(updated.lookupValue, '3C64C7');
    expect(updated.departureDate, const CalendarDate(2026, 4, 1));
    expect(updated.note, 'Aisle seat');
    expect(updated.hexAddress, '3c64c8');
    expect(updated.expectedCallsign, 'DLH434');
    expect(updated.tracking, same(tracking));
  });

  test('keeps the accumulated tracking when a copy does not mention it', () {
    final tracking = const FlightTracking().withFix(
      positionFix(afterWindowStart(const Duration(hours: 1)), onGround: false),
      window,
    );
    final flight = const Flight(
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH433',
      departureDate: CalendarDate(2026, 3, 17),
    ).copyWith(tracking: tracking);

    final updated = flight.copyWith(
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH433',
    );

    expect(updated.tracking, same(tracking));
    expect(updated.hexAddress, '3c64c6');
    expect(updated.expectedCallsign, 'DLH433');
  });
}
