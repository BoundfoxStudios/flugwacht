import 'dart:io';

import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flutter_test/flutter_test.dart';

const _densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  /// The arrival reminder is scheduled inexactly on purpose (#146): an alarm to
  /// the second would make the Play Store ask what an app that neither calls
  /// nor wakes people needs an exact alarm for.
  test('asks Android for no exact alarm permission', () {
    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
  });

  /// flutter_local_notifications carries these receivers but declares neither
  /// in its own manifest. Losing them costs no build error — the scheduled
  /// notification just never shows.
  test(
    'declares the receivers a scheduled notification is delivered through',
    () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
      );
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.'
          'ScheduledNotificationBootReceiver',
        ),
      );
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    },
  );

  /// The release build shrinks resources, and nothing but a Dart string names
  /// the status bar icon. Once the shrinker drops it, the plugin's icon
  /// validation fails and the app stops starting — in release only.
  test('keeps the status bar icon from the resource shrinker', () {
    final keepRules = File(
      'android/app/src/main/res/raw/keep.xml',
    ).readAsStringSync();

    expect(
      keepRules,
      contains('@drawable/${LocalNotificationService.androidIconResource}'),
    );
  });

  test('ships the status bar icon in every density', () {
    for (final density in _densities) {
      final icon = File(
        'android/app/src/main/res/drawable-$density/'
        '${LocalNotificationService.androidIconResource}.png',
      );

      expect(icon.existsSync(), isTrue, reason: density);
    }
  });

  group('unavailable service', () {
    late UnavailableNotificationService service;

    setUp(() {
      service = UnavailableNotificationService();
      addTearDown(service.dispose);
    });

    test('reports the notifications as unavailable', () {
      expect(service.permission.value, NotificationPermission.unavailable);
    });

    test('shows nothing', () async {
      await service.show(
        FlightNotification.departed,
        flightId: 7,
        title: 'LH400',
        body: 'departed',
      );

      expect(service.permission.value, NotificationPermission.unavailable);
    });

    test('schedules nothing', () async {
      await service.schedule(
        FlightNotification.arrivingSoon,
        flightId: 7,
        title: 'LH400',
        body: 'arriving soon',
        at: DateTime.utc(2026, 3, 17, 12),
      );

      expect(service.permission.value, NotificationPermission.unavailable);
    });

    test('cancels nothing', () async {
      await service.cancel(FlightNotification.arrivingSoon, flightId: 7);

      expect(service.permission.value, NotificationPermission.unavailable);
    });

    test('keeps a permission request a no-op', () async {
      await service.requestPermission();

      expect(service.permission.value, NotificationPermission.unavailable);
    });

    test('finds nothing to pick up from the system settings', () async {
      await service.refreshPermission();

      expect(service.permission.value, NotificationPermission.unavailable);
    });
  });
}
