import 'package:flugwacht/data/live_activities/live_activity_id.dart';
import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/data/live_activities/notification_live_activity_service.dart';
import 'package:flugwacht/data/notifications/notification_ids.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ahead of the wall clock on purpose: the plugin refuses to schedule the
  // card's stale update into the past, and it measures that against the real
  // clock rather than the moment the test hands in.
  const departureDate = CalendarDate(2099, 3, 17);
  final onFlightDay = DateTime(2099, 3, 17, 12);

  late List<MethodCall> calls;
  late List<Map<Object?, Object?>> activeNotifications;
  late List<Map<Object?, Object?>>? channels;
  late bool areNotificationsEnabled;

  RouteAirport airport(String code, double latitude, double longitude) =>
      RouteAirport(
        iataCode: code,
        icaoCode: 'X$code',
        name: code,
        latitude: latitude,
        longitude: longitude,
      );

  final route = FlightRoute(
    origin: airport('FRA', 50.0379, 8.5622),
    destination: airport('JFK', 40.6413, -73.7781),
  );

  Flight flight({
    FlightRoute? withRoute,
    DayTime? departureTime = const DayTime(14, 30),
    FlightTracking tracking = const FlightTracking(),
  }) => Flight(
    id: 3,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH433',
    departureDate: departureDate,
    departureTime: departureTime,
    route: withRoute,
    tracking: tracking,
  );

  final airborne = flight(
    withRoute: route,
    tracking: FlightTracking(
      hasBeenAirborne: true,
      firstAirborneAt: onFlightDay.subtract(const Duration(hours: 7)),
      latestPosition: FixPosition(
        latitude: 40.6413,
        longitude: -73,
        timestamp: onFlightDay,
        onGround: false,
        groundSpeedKnots: 400,
      ),
    ),
  );

  Future<LiveActivityService> startService() =>
      NotificationLiveActivityService.start(
        copy: (card) => (title: card.designator, body: card.state.name),
        channelName: 'Running flights',
        channelDescription: 'The card of a flight under way.',
        clock: () => onFlightDay,
      );

  MethodCall callOf(String method) =>
      calls.lastWhere((call) => call.method == method);

  Map<Object?, Object?> androidArgumentsOf(String method) =>
      (callOf(method).arguments as Map<Object?, Object?>)['platformSpecifics']!
          as Map<Object?, Object?>;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    calls = [];
    activeNotifications = [];
    channels = null;
    areNotificationsEnabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getActiveNotifications' => activeNotifications,
            'getNotificationChannels' => channels,
            'areNotificationsEnabled' => areNotificationsEnabled,
            _ => null,
          };
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('availability', () {
    test(
      'is enabled while the system lets the notifications through',
      () async {
        final service = await startService();

        expect(service.availability.value, LiveActivityAvailability.enabled);
      },
    );

    test('is disabled where the user switched notifications off', () async {
      areNotificationsEnabled = false;

      final service = await startService();

      expect(service.availability.value, LiveActivityAvailability.disabled);
    });

    /// The card gets a channel of its own so it can be switched off without
    /// costing the flight its other notifications; the app has to notice.
    test('is disabled where the card\'s own channel is off', () async {
      channels = [
        {
          'id': NotificationLiveActivityService.cardChannelId,
          'name': 'Running flights',
          'importance': Importance.none.value,
          'showBadge': false,
          'bypassDnd': false,
          'playSound': false,
          'enableLights': false,
          'enableVibration': false,
          'ledColor': 0,
        },
      ];

      final service = await startService();

      expect(service.availability.value, LiveActivityAvailability.disabled);
    });
  });

  group('put', () {
    test('shows the card as an ongoing notification of the flight', () async {
      final service = await startService();

      await service.put('flight-3-1', flight: airborne, now: onFlightDay);

      final arguments = callOf('show').arguments as Map<Object?, Object?>;
      expect(arguments['id'], flightCardIdOf(3));
      expect(arguments['payload'], '3');
      expect(androidArgumentsOf('show')['ongoing'], isTrue);
      expect(androidArgumentsOf('show')['autoCancel'], isFalse);
    });

    /// The whole point of the card: the countdown is drawn by the system from
    /// the moment the card carries, so it keeps running with the app closed.
    test('lets the system count down to the arrival', () async {
      final service = await startService();

      await service.put('flight-3-1', flight: airborne, now: onFlightDay);

      final android = androidArgumentsOf('show');
      expect(android['usesChronometer'], isTrue);
      expect(android['chronometerCountDown'], isTrue);
      expect(android['when'], greaterThan(onFlightDay.millisecondsSinceEpoch));
    });

    test('counts down to the departure before the flight leaves', () async {
      final service = await startService();

      await service.put('flight-3-1', flight: flight(), now: onFlightDay);

      expect(
        androidArgumentsOf('show')['when'],
        DateTime(2099, 3, 17, 14, 30).millisecondsSinceEpoch,
      );
    });

    /// Android redraws nothing on its own, so the moment the numbers stop being
    /// true has to be scheduled while the app still runs.
    test('schedules the card going stale', () async {
      final service = await startService();

      await service.put('flight-3-1', flight: airborne, now: onFlightDay);

      final arguments =
          callOf('zonedSchedule').arguments as Map<Object?, Object?>;
      expect(arguments['id'], flightCardIdOf(3));
    });

    test('schedules nothing where no countdown could run out', () async {
      final service = await startService();

      await service.put(
        'flight-3-1',
        flight: flight(departureTime: null),
        now: onFlightDay,
      );

      expect(
        calls.map((call) => call.method),
        isNot(contains('zonedSchedule')),
      );
    });
  });

  group('end', () {
    test('takes the card and its scheduled stale update away', () async {
      final service = await startService();
      await service.put('flight-3-1', flight: airborne, now: onFlightDay);

      await service.end('flight-3-1');

      expect(
        (callOf('cancel').arguments as Map<Object?, Object?>)['id'],
        flightCardIdOf(3),
      );
      expect(calls.where((call) => call.method == 'show'), hasLength(1));
    });

    /// A landed flight's card is the one the user still wants to look at, so it
    /// stays up until Android's own timeout takes it.
    test('leaves a card up until the moment it should go', () async {
      final service = await startService();
      await service.put('flight-3-1', flight: airborne, now: onFlightDay);

      await service.end(
        'flight-3-1',
        dismissAt: onFlightDay.add(const Duration(minutes: 30)),
      );

      expect(calls.where((call) => call.method == 'show'), hasLength(2));
      expect(
        androidArgumentsOf('show')['timeoutAfter'],
        const Duration(minutes: 30).inMilliseconds,
      );
      // A flight that is over has nothing left to hold its card in place.
      expect(androidArgumentsOf('show')['ongoing'], isFalse);
    });

    test('ignores an identifier no flight can be read from', () async {
      final service = await startService();
      calls.clear();

      await service.end('not-a-card');

      expect(calls, isEmpty);
    });
  });

  group('presence', () {
    test('reports a card the system still shows as running', () async {
      final service = await startService();
      activeNotifications = [
        {'id': flightCardIdOf(3), 'channelId': 'flight_card'},
      ];

      expect(
        await service.presenceOf('flight-3-1'),
        LiveActivityPresence.running,
      );
    });

    test('reports a card the user swiped away as finished', () async {
      final service = await startService();

      expect(
        await service.presenceOf('flight-3-1'),
        LiveActivityPresence.finished,
      );
    });
  });

  test('round-trips the flight through a card identifier', () {
    final activityId = liveActivityIdOf(42, onFlightDay);

    expect(flightIdFromLiveActivityId(activityId), 42);
    expect(flightIdFromLiveActivityId('nonsense'), isNull);
  });
}
