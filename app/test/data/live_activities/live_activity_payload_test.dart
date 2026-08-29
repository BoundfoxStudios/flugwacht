import 'package:flugwacht/data/live_activities/live_activity_payload.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter_test/flutter_test.dart';

const _departureDate = CalendarDate(2026, 3, 17);

/// Frankfurt to Munich, so a position over Frankfurt is a known distance out.
const _route = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDF',
    iataCode: 'FRA',
    name: 'Frankfurt am Main',
    latitude: 50.026402,
    longitude: 8.543130,
  ),
  destination: RouteAirport(
    icaoCode: 'EDDM',
    iataCode: 'MUC',
    name: 'München',
    latitude: 48.353802,
    longitude: 11.786100,
  ),
);

final _onFlightDay = DateTime(2026, 3, 17, 12);

FixPosition _position({
  DateTime? timestamp,
  bool onGround = false,
  double groundSpeedKnots = 420,
}) => FixPosition(
  latitude: 50.026402,
  longitude: 8.543130,
  timestamp: timestamp ?? _onFlightDay,
  onGround: onGround,
  groundSpeedKnots: groundSpeedKnots,
);

Flight _flight({
  String? note,
  DayTime? departureTime,
  FlightRoute? route = _route,
  FlightTracking tracking = const FlightTracking(),
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH433',
  departureDate: _departureDate,
  departureTime: departureTime,
  note: note,
  route: route,
  tracking: tracking,
);

void main() {
  group('payload', () {
    test('carries the url that opens the app on the flight', () {
      final payload = liveActivityPayloadOf(_flight(), _onFlightDay);
      expect(payload['url'], 'flugwacht://flight/1');
    });

    test('names the flight by its lookup value and note', () {
      final payload = liveActivityPayloadOf(
        _flight(note: 'Papa'),
        _onFlightDay,
      );
      expect(payload['designator'], 'LH433');
      expect(payload['note'], 'Papa');
    });

    test('empties the note of a flight that carries none', () {
      final payload = liveActivityPayloadOf(_flight(), _onFlightDay);
      expect(payload['note'], '');
    });

    test('carries the state the app shows for the flight', () {
      final payload = liveActivityPayloadOf(
        _flight(tracking: FlightTracking(latestPosition: _position())),
        _onFlightDay,
      );
      expect(payload['state'], 'live');
    });

    test('carries the route in iata codes', () {
      final payload = liveActivityPayloadOf(_flight(), _onFlightDay);
      expect(payload['originCode'], 'FRA');
      expect(payload['destinationCode'], 'MUC');
    });

    test('falls back to the icao code of an airport without an iata one', () {
      final payload = liveActivityPayloadOf(
        _flight(
          route: const FlightRoute(
            origin: RouteAirport(
              icaoCode: 'EDDF',
              name: 'Frankfurt am Main',
              latitude: 50.026402,
              longitude: 8.543130,
            ),
            destination: RouteAirport(
              icaoCode: 'EDDM',
              name: 'München',
              latitude: 48.353802,
              longitude: 11.786100,
            ),
          ),
        ),
        _onFlightDay,
      );
      expect(payload['originCode'], 'EDDF');
      expect(payload['destinationCode'], 'EDDM');
    });

    test('empties the codes of a flight without a route', () {
      final payload = liveActivityPayloadOf(_flight(route: null), _onFlightDay);
      expect(payload['originCode'], '');
      expect(payload['destinationCode'], '');
    });

    test('carries the scheduled departure as epoch milliseconds', () {
      final payload = liveActivityPayloadOf(
        _flight(departureTime: const DayTime(10, 0)),
        _onFlightDay,
      );
      expect(
        payload['departureAt'],
        DateTime(2026, 3, 17, 10).millisecondsSinceEpoch,
      );
    });

    test('carries the estimated arrival of a tracked flight', () {
      final payload = liveActivityPayloadOf(
        _flight(tracking: FlightTracking(latestPosition: _position())),
        _onFlightDay,
      );
      expect(payload['estimatedArrivalAt'], isA<int>());
    });

    test('zeroes an arrival the flight gives no basis for', () {
      final payload = liveActivityPayloadOf(
        _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 20),
          ),
        ),
        _onFlightDay,
      );
      expect(payload['estimatedArrivalAt'], 0);
    });

    test('carries the anchor the progress bar runs from', () {
      final airborneAt = DateTime(2026, 3, 17, 10, 30);
      final payload = liveActivityPayloadOf(
        _flight(
          tracking: FlightTracking(
            latestPosition: _position(),
            firstAirborneAt: airborneAt,
          ),
        ),
        _onFlightDay,
      );
      expect(payload['firstAirborneAt'], airborneAt.millisecondsSinceEpoch);
    });

    test('carries the arrival of a flight that has landed', () {
      final landedAt = DateTime(2026, 3, 17, 11, 45);
      final payload = liveActivityPayloadOf(
        _flight(
          tracking: FlightTracking(
            latestPosition: _position(timestamp: landedAt, onGround: true),
            hasBeenAirborne: true,
            lastKnownOnGround: true,
          ),
        ),
        _onFlightDay,
      );
      expect(payload['state'], 'ended');
      expect(payload['landedAt'], landedAt.millisecondsSinceEpoch);
    });

    test('zeroes the landing while the flight is still up', () {
      final payload = liveActivityPayloadOf(
        _flight(tracking: FlightTracking(latestPosition: _position())),
        _onFlightDay,
      );
      expect(payload['landedAt'], 0);
    });

    /// An update only clears a key the map carries as null, and a create would
    /// throw on one – so a fact that stops applying has to arrive as a value
    /// the card can read as "none", or its last value stays on the Lock Screen.
    test('carries every key on every payload', () {
      final complete = liveActivityPayloadOf(
        _flight(
          note: 'Papa',
          departureTime: const DayTime(10, 0),
          tracking: FlightTracking(
            latestPosition: _position(),
            firstAirborneAt: _onFlightDay,
          ),
        ),
        _onFlightDay,
      );
      final bare = liveActivityPayloadOf(_flight(route: null), _onFlightDay);

      expect(bare.keys.toSet(), complete.keys.toSet());
      expect(bare.values, isNot(contains(isNull)));
    });
  });

  group('stale date', () {
    test('stays at least a minute, which the plugin rounds to', () {
      final flight = _flight(departureTime: const DayTime(12, 14));
      expect(
        liveActivityStaleIn(flight, DateTime(2026, 3, 17, 12, 29)),
        greaterThanOrEqualTo(const Duration(minutes: 1)),
      );
    });

    test('runs out exactly at the estimated arrival', () {
      final flight = _flight(
        tracking: FlightTracking(latestPosition: _position()),
      );
      final arrivesAt =
          liveActivityPayloadOf(flight, _onFlightDay)['estimatedArrivalAt']!
              as int;

      expect(
        _onFlightDay
            .add(liveActivityStaleIn(flight, _onFlightDay))
            .millisecondsSinceEpoch,
        arrivesAt + liveActivityStaleGrace.inMilliseconds,
      );
    });

    test('runs out at the scheduled departure before the flight is up', () {
      final flight = _flight(departureTime: const DayTime(14, 0));
      expect(
        _onFlightDay.add(liveActivityStaleIn(flight, _onFlightDay)),
        DateTime(2026, 3, 17, 14).add(liveActivityStaleGrace),
      );
    });

    test('falls back to the end of the flight day', () {
      final flight = _flight();
      expect(
        _onFlightDay.add(liveActivityStaleIn(flight, _onFlightDay)),
        DateTime(2026, 3, 19),
      );
    });

    /// A moment that has passed is exactly what staleness is for: stretching
    /// the window to the end of the flight day would let a card present an
    /// expired countdown as fresh for up to two days.
    test('marks a card outdated right away once its moment has passed', () {
      final flight = _flight(departureTime: const DayTime(6, 0));
      expect(
        liveActivityStaleIn(flight, _onFlightDay),
        const Duration(minutes: 1),
      );
    });
  });
  group('relevance', () {
    /// The bug this ranking exists for: with several cards up, iOS put the
    /// flight that had not left yet in the Dynamic Island.
    test('puts a flight in the air over one that has not left yet', () {
      final airborne = _flight(
        tracking: FlightTracking(latestPosition: _position()),
      );
      final waiting = _flight();

      expect(
        liveActivityRelevanceOf(airborne, _onFlightDay),
        greaterThan(liveActivityRelevanceOf(waiting, _onFlightDay)),
      );
    });

    test('ranks a finished flight below every running one', () {
      final landed = _flight(
        tracking: FlightTracking(
          latestPosition: _position(onGround: true),
          hasBeenAirborne: true,
          lastKnownOnGround: true,
        ),
      );

      expect(
        liveActivityRelevanceOf(landed, _onFlightDay),
        lessThan(liveActivityRelevanceOf(_flight(), _onFlightDay)),
      );
    });
  });
}
