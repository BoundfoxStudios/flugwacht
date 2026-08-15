import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/poll_planning.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const departureDate = CalendarDate(2026, 3, 17);
  final window = FlightDayWindow.forDepartureDate(departureDate);
  final airborneAt = window.start.add(const Duration(hours: 5)).toUtc();

  Flight flightWith({
    FlightLookupKind lookupKind = FlightLookupKind.flightNumber,
    String lookupValue = 'LH400',
    String? hexAddress,
    String? expectedCallsign,
    FixPosition? latestPosition,
  }) => Flight(
    id: 1,
    lookupKind: lookupKind,
    lookupValue: lookupValue,
    departureDate: departureDate,
    hexAddress: hexAddress,
    expectedCallsign: expectedCallsign,
    tracking: FlightTracking(latestPosition: latestPosition),
  );

  FixPosition positionAt(DateTime timestamp, {bool? onGround = false}) =>
      FixPosition(
        latitude: 49.875687,
        longitude: 7.888834,
        timestamp: timestamp,
        onGround: onGround,
      );

  Fix fixWith({
    String hexAddress = '3c64c6',
    String? callsign,
    DateTime? positionAtTimestamp,
  }) => Fix(
    hexAddress: hexAddress,
    sourceId: SourceId.adsblol,
    callsign: callsign,
    position: positionAtTimestamp == null
        ? null
        : positionAt(positionAtTimestamp),
  );

  PollOutcome apply(Flight flight, PollQuery query, List<Fix> fixes) =>
      applyLookup(flight: flight, query: query, fixes: fixes, window: window);

  group('poll cadence', () {
    test('polls only the states that can still produce a fix', () {
      expect(isPollable(FlightState.waiting), isTrue);
      expect(isPollable(FlightState.live), isTrue);
      expect(isPollable(FlightState.noSignal), isTrue);
      expect(isPollable(FlightState.planned), isFalse);
      expect(isPollable(FlightState.ended), isFalse);
      expect(isPollable(FlightState.missed), isFalse);
    });

    test('polls a live flight every five seconds', () {
      expect(pollInterval(FlightState.live), const Duration(seconds: 5));
    });

    test('polls a searching flight every minute', () {
      expect(pollInterval(FlightState.waiting), const Duration(seconds: 60));
      expect(pollInterval(FlightState.noSignal), const Duration(seconds: 60));
    });
  });

  group('query planning', () {
    test('queries a hex flight by the entered hex address', () {
      final query = planPollQuery(
        flightWith(
          lookupKind: FlightLookupKind.hexAddress,
          lookupValue: '3c64c6',
        ),
        const [],
      );

      expect(query, isA<HexAddressPollQuery>());
      expect((query as HexAddressPollQuery).hexAddress, '3c64c6');
    });

    test('queries a registration flight by its registration', () {
      final query = planPollQuery(
        flightWith(
          lookupKind: FlightLookupKind.registration,
          lookupValue: 'D-AIXP',
        ),
        const [],
      );

      expect(query, isA<RegistrationPollQuery>());
      expect((query as RegistrationPollQuery).registration, 'D-AIXP');
    });

    test('queries an adopted hex address once the flight was found', () {
      final query = planPollQuery(
        flightWith(hexAddress: '3c64c6', expectedCallsign: 'DLH400'),
        const ['DLH400', 'GEC400'],
      );

      expect(query, isA<HexAddressPollQuery>());
      expect((query as HexAddressPollQuery).hexAddress, '3c64c6');
    });

    test('searches every callsign candidate while the flight is unfound', () {
      final query = planPollQuery(flightWith(), const ['DLH400', 'GEC400']);

      expect(query, isA<CallsignSearchPollQuery>());
      expect((query as CallsignSearchPollQuery).candidates, [
        'DLH400',
        'GEC400',
      ]);
    });

    test('searches the expected callsign first and drops the duplicate', () {
      final query = planPollQuery(
        flightWith(expectedCallsign: 'GEC400'),
        const ['DLH400', 'GEC400'],
      );

      expect((query as CallsignSearchPollQuery).candidates, [
        'GEC400',
        'DLH400',
      ]);
    });

    test(
      'searches the expected callsign alone without directory candidates',
      () {
        final query = planPollQuery(
          flightWith(expectedCallsign: 'DLH400'),
          const [],
        );

        expect((query as CallsignSearchPollQuery).candidates, ['DLH400']);
      },
    );
  });

  group('callsign search results', () {
    const search = CallsignSearchPollQuery(['DLH400', 'GEC400']);

    test('adopts the hex address and the matched callsign', () {
      final outcome = apply(flightWith(), search, [
        fixWith(callsign: 'GEC400', positionAtTimestamp: airborneAt),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.adoptedIdentity?.hexAddress, '3c64c6');
      expect(applied.adoptedIdentity?.callsign, 'GEC400');
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.trailPosition?.timestamp, airborneAt);
      expect(applied.sourceId, SourceId.adsblol);
    });

    test('ignores aircraft that carry another callsign', () {
      final outcome = apply(flightWith(), search, [
        fixWith(
          hexAddress: '3c1234',
          callsign: 'DLH4001',
          positionAtTimestamp: airborneAt,
        ),
        fixWith(callsign: 'DLH400', positionAtTimestamp: airborneAt),
      ]);

      expect((outcome as PollFixApplied).adoptedIdentity?.hexAddress, '3c64c6');
    });

    test('takes the first candidate that the response answers for', () {
      final outcome = apply(flightWith(), search, [
        fixWith(
          hexAddress: '3c1234',
          callsign: 'GEC400',
          positionAtTimestamp: airborneAt,
        ),
        fixWith(callsign: 'DLH400', positionAtTimestamp: airborneAt),
      ]);

      expect((outcome as PollFixApplied).adoptedIdentity?.callsign, 'DLH400');
    });

    test('prefers the aircraft that reports a position', () {
      final outcome = apply(flightWith(), search, [
        fixWith(hexAddress: '3c1234', callsign: 'DLH400'),
        fixWith(callsign: 'DLH400', positionAtTimestamp: airborneAt),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.adoptedIdentity?.hexAddress, '3c64c6');
      expect(applied.trailPosition?.timestamp, airborneAt);
    });

    test('adopts the identity of a positionless aircraft without a trail', () {
      final outcome = apply(flightWith(), search, [
        fixWith(callsign: 'DLH400'),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.adoptedIdentity?.hexAddress, '3c64c6');
      expect(applied.trailPosition, isNull);
      expect(applied.tracking.latestPosition, isNull);
    });

    test('matches a callsign that the source padded with spaces', () {
      final outcome = apply(flightWith(), search, [
        fixWith(callsign: 'DLH400  ', positionAtTimestamp: airborneAt),
      ]);

      expect((outcome as PollFixApplied).adoptedIdentity?.callsign, 'DLH400');
    });

    test('reports no data for an empty response', () {
      expect(apply(flightWith(), search, const []), isA<PollNoData>());
    });

    test('reports no data when no aircraft carries a queried callsign', () {
      final outcome = apply(flightWith(), search, [
        fixWith(callsign: 'AFR11', positionAtTimestamp: airborneAt),
        fixWith(hexAddress: '3c1234', positionAtTimestamp: airborneAt),
      ]);

      expect(outcome, isA<PollNoData>());
    });
  });

  group('hex safeguard', () {
    const hexQuery = HexAddressPollQuery('3c64c6');
    final foundFlight = flightWith(
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH400',
    );

    test('rejects the identity when the airframe flies another callsign', () {
      final outcome = apply(foundFlight, hexQuery, [
        fixWith(callsign: 'DLH8', positionAtTimestamp: airborneAt),
      ]);

      expect(outcome, isA<PollIdentityRejected>());
    });

    test('keeps the identity while the callsign matches', () {
      final outcome = apply(foundFlight, hexQuery, [
        fixWith(callsign: 'DLH400 ', positionAtTimestamp: airborneAt),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
    });

    test('keeps the identity while the airframe reports no callsign', () {
      final outcome = apply(foundFlight, hexQuery, [
        fixWith(positionAtTimestamp: airborneAt),
      ]);

      expect(outcome, isA<PollFixApplied>());
    });

    test('never cross-checks a hex address the user entered', () {
      final outcome = apply(
        flightWith(
          lookupKind: FlightLookupKind.hexAddress,
          lookupValue: '3c64c6',
        ),
        hexQuery,
        [fixWith(callsign: 'DLH8', positionAtTimestamp: airborneAt)],
      );

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
    });

    test('never cross-checks a registration flight', () {
      final outcome = apply(
        flightWith(
          lookupKind: FlightLookupKind.registration,
          lookupValue: 'D-AIXP',
        ),
        const RegistrationPollQuery('D-AIXP'),
        [fixWith(callsign: 'DLH8', positionAtTimestamp: airborneAt)],
      );

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
    });

    test('reports no data for an empty hex response', () {
      expect(apply(foundFlight, hexQuery, const []), isA<PollNoData>());
    });
  });

  group('trail positions', () {
    const hexQuery = HexAddressPollQuery('3c64c6');

    test('skips a position that is not newer than the latest known one', () {
      final flight = flightWith(
        lookupKind: FlightLookupKind.hexAddress,
        lookupValue: '3c64c6',
        latestPosition: positionAt(airborneAt),
      );

      expect(
        (apply(flight, hexQuery, [fixWith(positionAtTimestamp: airborneAt)])
                as PollFixApplied)
            .trailPosition,
        isNull,
      );
      expect(
        (apply(flight, hexQuery, [
                  fixWith(
                    positionAtTimestamp: airborneAt.subtract(
                      const Duration(minutes: 1),
                    ),
                  ),
                ])
                as PollFixApplied)
            .trailPosition,
        isNull,
      );
    });

    test('skips a position from before the flight day window', () {
      final outcome = apply(
        flightWith(
          lookupKind: FlightLookupKind.hexAddress,
          lookupValue: '3c64c6',
        ),
        hexQuery,
        [
          fixWith(
            positionAtTimestamp: window.start
                .subtract(const Duration(minutes: 30))
                .toUtc(),
          ),
        ],
      );

      final applied = outcome as PollFixApplied;
      expect(applied.trailPosition, isNull);
      expect(applied.tracking.latestPosition, isNull);
    });
  });
}
