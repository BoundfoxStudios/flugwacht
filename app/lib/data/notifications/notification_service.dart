import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../../domain/flight_notification.dart';
import 'notification_ids.dart';

/// What the operating system allows; a flight that has never been saved leaves
/// it undecided, because the app only asks in that moment. [unavailable] is not
/// the user's answer but the device's: the setup itself failed.
enum NotificationPermission { notDetermined, granted, denied, unavailable }

/// The seam between the app and the notification plugin, so nothing above it
/// talks to the platform directly.
abstract interface class NotificationService {
  Signal<NotificationPermission> get permission;

  /// The flights whose notification the user tapped while the app was there to
  /// hear it.
  Stream<int> get tappedFlights;

  /// The flight whose notification started the app, if one did – a tap the app
  /// was not yet running to receive.
  int? get launchFlightId;

  /// Shows the system prompt; a second call would never reach the user again,
  /// so callers ask only while the permission is undecided.
  Future<void> requestPermission();

  /// Picks up what the user changed in the system settings.
  Future<void> refreshPermission();

  /// Puts a notification of a flight in front of the user right now.
  Future<void> show(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
  });

  /// Hands a notification to the system, which delivers it even while the app
  /// is closed – roughly at that moment, never to the second.
  Future<void> schedule(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  });

  Future<void> cancel(FlightNotification kind, {required int flightId});

  /// Hands the system the offer to start a flight's Live Activity on its
  /// flight day – the app's own offer, not one of the flight's moments.
  Future<void> scheduleLiveActivityReminder({
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  });

  Future<void> cancelLiveActivityReminder({required int flightId});
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService._(
    this._plugin,
    this._preferences,
    this._details,
    this._hasAsked,
  ) : permission = signal(NotificationPermission.notDetermined);

  static const flightChannelId = 'flight_status';

  /// The status bar icon, a drawable the app resolves by name at runtime; the
  /// resource shrinker only spares it because res/raw/keep.xml says so.
  static const androidIconResource = 'ic_notification';

  static const _hasAskedKey = 'notification_permission_requested';

  /// Initializes the plugin, creates the Android channel and reads what the
  /// system currently allows. A device that fails any of that – a dropped icon
  /// resource, a broken notification stack – costs the user the notifications
  /// and gets an [UnavailableNotificationService], never a stalled app.
  static Future<NotificationService> start({
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final preferences = SharedPreferencesAsync();
      final service = LocalNotificationService._(
        plugin,
        preferences,
        NotificationDetails(
          android: AndroidNotificationDetails(flightChannelId, channelName),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
        await preferences.getBool(_hasAskedKey) ?? false,
      );
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(androidIconResource),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            defaultPresentSound: false,
          ),
        ),
        onDidReceiveNotificationResponse: service._notificationTapped,
      );
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              flightChannelId,
              channelName,
              description: channelDescription,
            ),
          );
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        service._launchFlightId = _flightIdOf(
          launch.notificationResponse?.payload,
        );
      }
      await service.refreshPermission();
      return service;
    } on Exception {
      return UnavailableNotificationService();
    }
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferencesAsync _preferences;
  final NotificationDetails _details;
  final _tappedFlights = StreamController<int>.broadcast();
  bool _hasAsked;
  int? _launchFlightId;

  @override
  final Signal<NotificationPermission> permission;

  @override
  int? get launchFlightId => _launchFlightId;

  @override
  Stream<int> get tappedFlights => _tappedFlights.stream;

  @override
  Future<void> requestPermission() async {
    _hasAsked = true;
    await _preferences.setBool(_hasAskedKey, true);
    final isGranted = await _requestFromPlatform() ?? false;
    permission.value = isGranted
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<void> refreshPermission() async {
    final isEnabled = await _isEnabledOnPlatform() ?? false;
    permission.value = switch ((isEnabled, _hasAsked)) {
      (true, _) => NotificationPermission.granted,
      (false, true) => NotificationPermission.denied,
      (false, false) => NotificationPermission.notDetermined,
    };
  }

  @override
  Future<void> show(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
  }) => _plugin.show(
    id: notificationIdOf(kind, flightId),
    title: title,
    body: body,
    notificationDetails: _details,
    payload: '$flightId',
  );

  @override
  Future<void> schedule(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  }) => _plugin.zonedSchedule(
    id: notificationIdOf(kind, flightId),
    title: title,
    body: body,
    scheduledDate: timezone.TZDateTime.from(at, timezone.UTC),
    notificationDetails: _details,
    payload: '$flightId',
    // Inexact on purpose: an alarm to the second would need the exact-alarm
    // permission, and the copy promises no more than "about 30 minutes".
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<void> cancel(FlightNotification kind, {required int flightId}) =>
      _plugin.cancel(id: notificationIdOf(kind, flightId));

  @override
  Future<void> scheduleLiveActivityReminder({
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  }) => _plugin.zonedSchedule(
    id: liveActivityReminderIdOf(flightId),
    title: title,
    body: body,
    scheduledDate: timezone.TZDateTime.from(at, timezone.UTC),
    notificationDetails: _details,
    payload: '$flightId',
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<void> cancelLiveActivityReminder({required int flightId}) =>
      _plugin.cancel(id: liveActivityReminderIdOf(flightId));

  void dispose() {
    permission.dispose();
    unawaited(_tappedFlights.close());
  }

  void _notificationTapped(NotificationResponse response) {
    final flightId = _flightIdOf(response.payload);
    if (flightId != null) {
      _tappedFlights.add(flightId);
    }
  }

  /// The flight a notification carries; every notification of the app names
  /// one, and nothing else may reach this.
  static int? _flightIdOf(String? payload) =>
      payload == null ? null : int.tryParse(payload);

  Future<bool?> _requestFromPlatform() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return android.requestNotificationsPermission();
    }
    return _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool?> _isEnabledOnPlatform() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return android.areNotificationsEnabled();
    }
    final options = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return options?.isEnabled;
  }
}

/// Stands in on a device whose notification setup failed, so everything above
/// keeps the service it depends on – and gets nothing but silence from it.
class UnavailableNotificationService implements NotificationService {
  UnavailableNotificationService()
    : permission = signal(NotificationPermission.unavailable);

  @override
  final Signal<NotificationPermission> permission;

  @override
  Stream<int> get tappedFlights => const Stream.empty();

  @override
  int? get launchFlightId => null;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> refreshPermission() async {}

  @override
  Future<void> show(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> schedule(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancel(FlightNotification kind, {required int flightId}) async {}

  @override
  Future<void> scheduleLiveActivityReminder({
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancelLiveActivityReminder({required int flightId}) async {}

  void dispose() => permission.dispose();
}
