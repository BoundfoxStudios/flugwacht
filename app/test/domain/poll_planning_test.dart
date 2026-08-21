import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_route.dart';
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
    DayTime? departureTime,
    DepartureTimeInterpretation departureTimeInterpretation =
        DepartureTimeInterpretation.device,
    FlightRoute? route,
    String? hexAddress,
    String? expectedCallsign,
    FixPosition? latestPosition,
    bool hasBeenAirborne = false,
  }) => Flight(
    id: 1,
    lookupKind: lookupKind,
    lookupValue: lookupValue,
    departureDate: departureDate,
    departureTime: departureTime,
    departureTimeInterpretation: departureTimeInterpretation,
    route: route,
    hexAddress: hexAddress,
    expectedCallsign: expectedCallsign,
    tracking: FlightTracking(
      latestPosition: latestPosition,
      hasBeenAirborne: hasBeenAirborne,
    ),
  );

  FlightRoute routeFrom(RouteAirport origin) => FlightRoute(
    origin: origin,
    destination: const RouteAirport(
      icaoCode: 'EDDF',
      iataCode: 'FRA',
      name: 'Frankfurt am Main',
      latitude: 50.0379,
      longitude: 8.5622,
    ),
  );

  const taoyuan = RouteAirport(
    icaoCode: 'RCTP',
    iataCode: 'TPE',
    name: 'Taiwan Taoyuan',
    latitude: 25.0777,
    longitude: 121.2328,
  );

  const losAngeles = RouteAirport(
    icaoCode: 'KLAX',
    iataCode: 'LAX',
    name: 'Los Angeles',
    latitude: 33.9425,
    longitude: -118.4081,
  );

  FixPosition positionAt(
    DateTime timestamp, {
    bool? onGround = false,
    double latitude = 49.875687,
    double longitude = 7.888834,
  }) => FixPosition(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    onGround: onGround,
  );

  Fix fixWith({
    String hexAddress = '3c64c6',
    String? callsign,
    DateTime? positionAtTimestamp,
    bool? onGround = false,
    double latitude = 49.875687,
    double longitude = 7.888834,
  }) => Fix(
    hexAddress: hexAddress,
    sourceId: SourceId.adsblol,
    callsign: callsign,
    position: positionAtTimestamp == null
        ? null
        : positionAt(
            positionAtTimestamp,
            onGround: onGround,
            latitude: latitude,
            longitude: longitude,
          ),
  );

  PollOutcome apply(
    Flight flight,
    PollQuery query,
    List<Fix> fixes, {
    DateTime? now,
  }) => applyLookup(
    flight: flight,
    query: query,
    fixes: fixes,
    window: window,
    now: now ?? airborneAt,
  );

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
      expect(
        pollInterval(flightWith(), FlightState.live, airborneAt),
        const Duration(seconds: 5),
      );
    });

    test('polls a searching flight every minute', () {
      expect(
        pollInterval(flightWith(), FlightState.waiting, airborneAt),
        const Duration(seconds: 60),
      );
      expect(
        pollInterval(flightWith(), FlightState.noSignal, airborneAt),
        const Duration(seconds: 60),
      );
    });
  });

  group('airborne contact anchor', () {
    test('starts the search when the flight day window opens', () {
      expect(airborneContactStartsAt(flightWith()), window.start);
    });

    test('starts the search two hours before a scheduled departure', () {
      expect(
        airborneContactStartsAt(
          flightWith(departureTime: const DayTime(16, 10)),
        ),
        DateTime(2026, 3, 17, 14, 10),
      );
    });

    test('anchors an evening departure on its own departure day', () {
      expect(
        airborneContactStartsAt(
          flightWith(departureTime: const DayTime(23, 55)),
        ),
        DateTime(2026, 3, 17, 21, 55),
      );
    });

    test('anchors an origin-local departure east of the device early', () {
      expect(
        airborneContactStartsAt(
          flightWith(
            departureTime: const DayTime(23, 55),
            departureTimeInterpretation:
                DepartureTimeInterpretation.originLocal,
            route: routeFrom(taoyuan),
          ),
        ),
        DateTime.utc(2026, 3, 17, 13, 55),
      );
    });

    test('anchors an origin-local departure west of the device late', () {
      expect(
        airborneContactStartsAt(
          flightWith(
            departureTime: const DayTime(9, 0),
            departureTimeInterpretation:
                DepartureTimeInterpretation.originLocal,
            route: routeFrom(losAngeles),
          ),
        ),
        DateTime.utc(2026, 3, 17, 14, 0),
      );
    });

    test('reads an origin-local departure without a route as device time', () {
      expect(
        airborneContactStartsAt(
          flightWith(
            departureTime: const DayTime(16, 10),
            departureTimeInterpretation:
                DepartureTimeInterpretation.originLocal,
          ),
        ),
        DateTime(2026, 3, 17, 14, 10),
      );
    });

    test('never starts the search before the window opens', () {
      expect(
        airborneContactStartsAt(
          flightWith(departureTime: const DayTime(0, 30)),
        ),
        window.start,
      );
      expect(
        airborneContactStartsAt(flightWith(departureTime: const DayTime(1, 0))),
        window.start,
      );
      expect(
        airborneContactStartsAt(flightWith(departureTime: const DayTime(2, 0))),
        window.start,
      );
    });
  });

  group('departure contact gate', () {
    const search = CallsignSearchPollQuery(['DLH400', 'GEC400']);
    const departureTime = DayTime(16, 10);
    final beforeAnchor = DateTime(2026, 3, 17, 12, 0);
    final atAnchor = DateTime(2026, 3, 17, 14, 10);
    final afterAnchor = DateTime(2026, 3, 17, 15, 30);
    final routedFlight = flightWith(
      departureTime: departureTime,
      route: routeFrom(losAngeles),
    );

    Fix originFix({bool? onGround}) => fixWith(
      callsign: 'DLH400',
      positionAtTimestamp: beforeAnchor,
      onGround: onGround,
      latitude: losAngeles.latitude,
      longitude: losAngeles.longitude,
    );

    test('refuses an airborne aircraft before the anchor', () {
      expect(
        apply(routedFlight, search, [originFix()], now: beforeAnchor),
        isA<PollAwaitsDeparture>(),
      );
    });

    test('refuses an aircraft without a position before the anchor', () {
      expect(
        apply(routedFlight, search, [
          fixWith(callsign: 'DLH400'),
        ], now: beforeAnchor),
        isA<PollAwaitsDeparture>(),
      );
    });

    test('takes only the identity of an aircraft standing at the origin', () {
      final outcome = apply(routedFlight, search, [
        originFix(onGround: true),
      ], now: beforeAnchor);

      final adopted = outcome as PollIdentityAdopted;
      expect(adopted.identity.hexAddress, '3c64c6');
      expect(adopted.identity.callsign, 'DLH400');
    });

    test('refuses an aircraft on the ground far from the origin', () {
      expect(
        apply(routedFlight, search, [
          fixWith(
            callsign: 'DLH400',
            positionAtTimestamp: beforeAnchor,
            onGround: true,
          ),
        ], now: beforeAnchor),
        isA<PollAwaitsDeparture>(),
      );
    });

    test('refuses a callsign on the ground without a known route', () {
      expect(
        apply(flightWith(departureTime: departureTime), search, [
          fixWith(
            callsign: 'DLH400',
            positionAtTimestamp: beforeAnchor,
            onGround: true,
          ),
        ], now: beforeAnchor),
        isA<PollAwaitsDeparture>(),
      );
    });

    test('adopts nothing for an entered airframe before the anchor', () {
      final registrationFlight = flightWith(
        lookupKind: FlightLookupKind.registration,
        lookupValue: 'DABYT',
        departureTime: departureTime,
      );

      expect(
        apply(
          registrationFlight,
          const RegistrationPollQuery('DABYT'),
          [
            fixWith(
              callsign: 'DLH400',
              positionAtTimestamp: beforeAnchor,
              onGround: true,
            ),
          ],
          now: beforeAnchor,
        ),
        isA<PollAwaitsDeparture>(),
      );
    });

    test('takes an airborne aircraft from the anchor on', () {
      expect(
        apply(routedFlight, search, [originFix()], now: atAnchor),
        isA<PollFixApplied>(),
      );
      expect(
        apply(routedFlight, search, [originFix()], now: afterAnchor),
        isA<PollFixApplied>(),
      );
    });

    test('refuses an airborne aircraft whatever the flight stores', () {
      final withHexAddress = flightWith(
        departureTime: departureTime,
        route: routeFrom(losAngeles),
        hexAddress: '3c64c6',
        expectedCallsign: 'DLH400',
      );
      final everAirborne = flightWith(
        lookupKind: FlightLookupKind.registration,
        lookupValue: 'DABYT',
        departureTime: departureTime,
        latestPosition: positionAt(beforeAnchor),
        hasBeenAirborne: true,
      );

      expect(
        apply(withHexAddress, const HexAddressPollQuery('3c64c6'), [
          originFix(),
        ], now: beforeAnchor),
        isA<PollAwaitsDeparture>(),
      );
      expect(
        apply(everAirborne, const RegistrationPollQuery('DABYT'), [
          fixWith(callsign: 'DLH400', positionAtTimestamp: beforeAnchor),
        ], now: beforeAnchor),
        isA<PollAwaitsDeparture>(),
      );
    });

    test('spaces the searches wider while the gate is up', () {
      expect(
        pollInterval(routedFlight, FlightState.waiting, beforeAnchor),
        const Duration(minutes: 5),
      );
      expect(
        pollInterval(routedFlight, FlightState.live, beforeAnchor),
        const Duration(minutes: 5),
      );
      expect(
        pollInterval(routedFlight, FlightState.waiting, atAnchor),
        const Duration(seconds: 60),
      );
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

    test('reports no data for an empty hex response', () {
      expect(apply(foundFlight, hexQuery, const []), isA<PollNoData>());
    });
  });

  group('entered identity pinning', () {
    const hexQuery = HexAddressPollQuery('3c64c6');
    const registrationQuery = RegistrationPollQuery('D-AIXP');

    Flight hexFlight({String? expectedCallsign}) => flightWith(
      lookupKind: FlightLookupKind.hexAddress,
      lookupValue: '3c64c6',
      expectedCallsign: expectedCallsign,
    );

    Flight registrationFlight({String? expectedCallsign}) => flightWith(
      lookupKind: FlightLookupKind.registration,
      lookupValue: 'D-AIXP',
      expectedCallsign: expectedCallsign,
    );

    test('pins the callsign of the first fix of a registration flight', () {
      final outcome = apply(registrationFlight(), registrationQuery, [
        fixWith(callsign: 'DLH8', positionAtTimestamp: airborneAt),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity?.callsign, 'DLH8');
    });

    test('pins the callsign of the first fix of an entered hex address', () {
      final outcome = apply(hexFlight(), hexQuery, [
        fixWith(callsign: 'DLH8', positionAtTimestamp: airborneAt),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity?.callsign, 'DLH8');
    });

    test('names no hex address while it pins a callsign', () {
      final outcome = apply(hexFlight(), hexQuery, [
        fixWith(
          hexAddress: '4b1a1f',
          callsign: 'DLH8',
          positionAtTimestamp: airborneAt,
        ),
      ]);

      expect((outcome as PollFixApplied).adoptedIdentity?.hexAddress, isNull);
    });

    test('rejects another callsign on the pinned registration flight', () {
      final outcome = apply(
        registrationFlight(expectedCallsign: 'DLH8'),
        registrationQuery,
        [fixWith(callsign: 'DLH400', positionAtTimestamp: airborneAt)],
      );

      expect(outcome, isA<PollIdentityRejected>());
    });

    test('rejects another callsign on the pinned hex address', () {
      final outcome = apply(hexFlight(expectedCallsign: 'DLH8'), hexQuery, [
        fixWith(callsign: 'DLH400', positionAtTimestamp: airborneAt),
      ]);

      expect(outcome, isA<PollIdentityRejected>());
    });

    test('applies a fix that reports the pinned callsign padded', () {
      final outcome = apply(
        registrationFlight(expectedCallsign: 'DLH8'),
        registrationQuery,
        [fixWith(callsign: ' DLH8 ', positionAtTimestamp: airborneAt)],
      );

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
    });

    test('pins nothing from an airframe standing on the ground', () {
      final outcome = apply(registrationFlight(), registrationQuery, [
        fixWith(
          callsign: 'DLH8',
          positionAtTimestamp: airborneAt,
          onGround: true,
        ),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
    });

    test('pins nothing from an answer without a position', () {
      final outcome = apply(registrationFlight(), registrationQuery, [
        fixWith(callsign: 'DLH8'),
      ]);

      expect((outcome as PollFixApplied).adoptedIdentity, isNull);
    });

    test('pins nothing while the answer hides whether it flies', () {
      final outcome = apply(registrationFlight(), registrationQuery, [
        fixWith(
          callsign: 'DLH8',
          positionAtTimestamp: airborneAt,
          onGround: null,
        ),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
    });

    test('pins nothing from a position older than the flight day', () {
      final outcome = apply(registrationFlight(), registrationQuery, [
        fixWith(
          callsign: 'DLH8',
          positionAtTimestamp: window.start.subtract(const Duration(hours: 1)),
        ),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition, isNull);
      expect(applied.adoptedIdentity, isNull);
    });

    test('pins nothing while the airframe reports no callsign', () {
      final outcome = apply(hexFlight(), hexQuery, [
        fixWith(positionAtTimestamp: airborneAt),
      ]);

      final applied = outcome as PollFixApplied;
      expect(applied.tracking.latestPosition?.timestamp, airborneAt);
      expect(applied.adoptedIdentity, isNull);
      expect(
        (apply(hexFlight(), hexQuery, [
                  fixWith(callsign: 'DLH8', positionAtTimestamp: airborneAt),
                ])
                as PollFixApplied)
            .adoptedIdentity
            ?.callsign,
        'DLH8',
      );
    });
  });

  group('landing before the scheduled departure', () {
    const registrationQuery = RegistrationPollQuery('D-AIXP');
    const hexQuery = HexAddressPollQuery('3c64c6');
    const scheduledDeparture = DayTime(20, 0);
    final beforeDeparture = DateTime(2026, 3, 17, 19, 5).toUtc();
    final afterDeparture = DateTime(2026, 3, 17, 20, 30).toUtc();
    final pollTime = DateTime(2026, 3, 17, 19, 6);

    Flight trackedRegistrationFlight({
      DayTime? departureTime = scheduledDeparture,
      bool hasBeenAirborne = true,
    }) => flightWith(
      lookupKind: FlightLookupKind.registration,
      lookupValue: 'D-AIXP',
      departureTime: departureTime,
      expectedCallsign: 'DLH8',
      hasBeenAirborne: hasBeenAirborne,
    );

    Fix landedFix(DateTime timestamp) => fixWith(
      callsign: 'DLH8',
      positionAtTimestamp: timestamp,
      onGround: true,
    );

    test('disproves a registration contact that lands before the '
        'departure', () {
      expect(
        apply(trackedRegistrationFlight(), registrationQuery, [
          landedFix(beforeDeparture),
        ], now: pollTime),
        isA<PollAdoptionDisproved>(),
      );
    });

    test('disproves an entered hex contact that lands before the '
        'departure', () {
      final hexFlight = flightWith(
        lookupKind: FlightLookupKind.hexAddress,
        lookupValue: '3c64c6',
        departureTime: scheduledDeparture,
        expectedCallsign: 'DLH8',
        hasBeenAirborne: true,
      );

      expect(
        apply(hexFlight, hexQuery, [landedFix(beforeDeparture)], now: pollTime),
        isA<PollAdoptionDisproved>(),
      );
    });

    test('applies a landing after the scheduled departure', () {
      expect(
        apply(trackedRegistrationFlight(), registrationQuery, [
          landedFix(afterDeparture),
        ], now: DateTime(2026, 3, 17, 20, 31)),
        isA<PollFixApplied>(),
      );
    });

    test('applies a landing while the flight has no departure time', () {
      expect(
        apply(
          trackedRegistrationFlight(departureTime: null),
          registrationQuery,
          [landedFix(beforeDeparture)],
          now: pollTime,
        ),
        isA<PollFixApplied>(),
      );
    });

    test('applies an airborne fix before the scheduled departure', () {
      expect(
        apply(trackedRegistrationFlight(), registrationQuery, [
          fixWith(callsign: 'DLH8', positionAtTimestamp: beforeDeparture),
        ], now: pollTime),
        isA<PollFixApplied>(),
      );
    });

    test('applies a landing while the flight has never been airborne', () {
      expect(
        apply(
          trackedRegistrationFlight(hasBeenAirborne: false),
          registrationQuery,
          [landedFix(beforeDeparture)],
          now: pollTime,
        ),
        isA<PollFixApplied>(),
      );
    });

    test('never disproves a flight number flight', () {
      final flightNumberFlight = flightWith(
        departureTime: scheduledDeparture,
        hexAddress: '3c64c6',
        expectedCallsign: 'DLH400',
        hasBeenAirborne: true,
      );

      expect(
        apply(flightNumberFlight, hexQuery, [
          fixWith(
            callsign: 'DLH400',
            positionAtTimestamp: beforeDeparture,
            onGround: true,
          ),
        ], now: pollTime),
        isA<PollFixApplied>(),
      );
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
