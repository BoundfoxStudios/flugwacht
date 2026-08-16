import 'package:flugwacht/data/notification_setting.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<NotificationSetting> loadWith(Map<String, Object> stored) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    final setting = await NotificationSetting.load();
    addTearDown(setting.dispose);
    return setting;
  }

  test('starts with every notification off', () async {
    final setting = await loadWith(const {});

    for (final kind in FlightNotification.values) {
      expect(setting.isEnabled(kind), isFalse, reason: kind.name);
    }
  });

  test('restores every switch a previous run turned on', () async {
    for (final kind in FlightNotification.values) {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final previousRun = await NotificationSetting.load();
      await previousRun.select(kind, isEnabled: true);
      previousRun.dispose();

      final setting = await NotificationSetting.load();
      addTearDown(setting.dispose);

      expect(setting.isEnabled(kind), isTrue, reason: kind.name);
      for (final other in FlightNotification.values.where((it) => it != kind)) {
        expect(setting.isEnabled(other), isFalse, reason: other.name);
      }
    }
  });

  test('enables every kind at once', () async {
    final setting = await loadWith(const {});

    await setting.enableAll();

    for (final kind in FlightNotification.values) {
      expect(setting.isEnabled(kind), isTrue, reason: kind.name);
    }
  });

  test('remembers the offer across launches', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await NotificationSetting.load();
    expect(previousRun.wasOffered, isFalse);
    await previousRun.rememberOffer();
    previousRun.dispose();

    final setting = await NotificationSetting.load();
    addTearDown(setting.dispose);

    expect(setting.wasOffered, isTrue);
  });
}
