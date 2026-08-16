import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../domain/flight_notification.dart';

/// What the operating system allows; a flight that has never been saved leaves
/// it undecided, because the app only asks in that moment.
enum NotificationPermission { notDetermined, granted, denied }

/// The seam between the app and the notification plugin, so nothing above it
/// talks to the platform directly.
abstract interface class NotificationService {
  Signal<NotificationPermission> get permission;

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
  /// is closed — roughly at that moment, never to the second.
  Future<void> schedule(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  });

  Future<void> cancel(FlightNotification kind, {required int flightId});
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService._(
    this._plugin,
    this._preferences,
    this._details,
    this._hasAsked,
  ) : permission = signal(NotificationPermission.notDetermined);

  static const flightChannelId = 'flight_status';
  static const _hasAskedKey = 'notification_permission_requested';
  static const _androidIcon = '@mipmap/ic_launcher';

  /// Initializes the plugin, creates the Android channel and reads what the
  /// system currently allows.
  static Future<LocalNotificationService> start({
    required String channelName,
    required String channelDescription,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_androidIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentSound: false,
        ),
      ),
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
    await service.refreshPermission();
    return service;
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferencesAsync _preferences;
  final NotificationDetails _details;
  bool _hasAsked;

  @override
  final Signal<NotificationPermission> permission;

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
    id: _idOf(kind, flightId),
    title: title,
    body: body,
    notificationDetails: _details,
  );

  @override
  Future<void> schedule(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  }) => _plugin.zonedSchedule(
    id: _idOf(kind, flightId),
    title: title,
    body: body,
    scheduledDate: timezone.TZDateTime.from(at, timezone.UTC),
    notificationDetails: _details,
    // Inexact on purpose: an alarm to the second would need the exact-alarm
    // permission, and the copy promises no more than "about 30 minutes".
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<void> cancel(FlightNotification kind, {required int flightId}) =>
      _plugin.cancel(id: _idOf(kind, flightId));

  void dispose() => permission.dispose();

  /// One stable id per flight and kind, so a reminder can be replaced and
  /// cancelled without bookkeeping.
  static int _idOf(FlightNotification kind, int flightId) =>
      flightId * FlightNotification.values.length + kind.index;

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
