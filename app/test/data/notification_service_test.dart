import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The arrival reminder is scheduled inexactly on purpose (#146): an alarm to
  /// the second would make the Play Store ask what an app that neither calls
  /// nor wakes people needs an exact alarm for.
  test('asks Android for no exact alarm permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
  });
}
