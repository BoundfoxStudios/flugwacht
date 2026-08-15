import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/ui/screens/list_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const departureDate = CalendarDate(2026, 8, 12);
  final window = FlightDayWindow.forDepartureDate(departureDate);
  final duringFlightDay = window.start.add(const Duration(hours: 6));

  Flight flight({
    int id = 1,
    CalendarDate date = departureDate,
    FlightTracking tracking = const FlightTracking(),
  }) => Flight(
    id: id,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH400',
    departureDate: date,
    tracking: tracking,
  );

  FlightTracking seenAt(DateTime timestamp, {bool? onGround}) => FlightTracking(
    latestPosition: FixPosition(
      latitude: 50.026402,
      longitude: 8.543130,
      timestamp: timestamp,
    ),
    hasBeenAirborne: true,
    lastKnownOnGround: onGround,
  );

  test('groups live and no-signal flights into the active section', () {
    final live = flight(
      id: 1,
      tracking: seenAt(duringFlightDay.subtract(const Duration(minutes: 2))),
    );
    final noSignal = flight(
      id: 2,
      tracking: seenAt(duringFlightDay.subtract(const Duration(minutes: 42))),
    );

    final sections = groupFlights([live, noSignal], duringFlightDay);

    expect(sections.active.map((entry) => entry.flight.id), [1, 2]);
    expect(sections.active.map((entry) => entry.state), [
      FlightState.live,
      FlightState.noSignal,
    ]);
  });

  test('groups waiting, planned and past flights into their own sections', () {
    final waiting = flight(id: 1);
    final planned = flight(id: 2, date: const CalendarDate(2026, 8, 20));
    final landed = flight(
      id: 3,
      tracking: seenAt(
        duringFlightDay.subtract(const Duration(hours: 1)),
        onGround: true,
      ),
    );
    final missed = flight(id: 4, date: const CalendarDate(2026, 8, 10));

    final sections = groupFlights([
      waiting,
      planned,
      landed,
      missed,
    ], duringFlightDay);

    expect(sections.waiting.single.flight.id, 1);
    expect(sections.planned.single.flight.id, 2);
    expect(sections.past.map((entry) => entry.flight.id), [3, 4]);
    expect(sections.past.map((entry) => entry.state), [
      FlightState.ended,
      FlightState.missed,
    ]);
  });

  test('keeps the incoming flight order inside a section', () {
    final earlier = flight(id: 7, date: const CalendarDate(2026, 8, 20));
    final later = flight(id: 3, date: const CalendarDate(2026, 8, 21));

    final sections = groupFlights([earlier, later], duringFlightDay);

    expect(sections.planned.map((entry) => entry.flight.id), [7, 3]);
  });

  test('leaves out flights whose retention has run out', () {
    final expired = flight(date: const CalendarDate(2026, 8, 8));
    final upcoming = flight(id: 2, date: const CalendarDate(2026, 8, 20));

    final sections = groupFlights([expired, upcoming], duringFlightDay);

    expect(sections.planned.single.flight.id, 2);
    expect(sections.past, isEmpty);
  });

  test('is empty when every flight has expired', () {
    final expired = flight(date: const CalendarDate(2026, 8, 8));

    expect(groupFlights([expired], duringFlightDay).isEmpty, isTrue);
  });
}
