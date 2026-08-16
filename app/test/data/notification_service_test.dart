import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
}
