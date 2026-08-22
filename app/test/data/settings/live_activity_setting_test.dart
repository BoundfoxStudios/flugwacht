import 'package:flugwacht/data/settings/live_activity_setting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LiveActivitySetting> loadWith(Map<String, Object> stored) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    final setting = await LiveActivitySetting.load();
    addTearDown(setting.dispose);
    return setting;
  }

  test('reminds on the flight day when nothing was stored', () async {
    final setting = await loadWith(const {});

    expect(setting.remindsOnFlightDay.value, isTrue);
  });

  test('restores the choice a previous run made', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await LiveActivitySetting.load();
    await previousRun.selectReminder(isEnabled: false);
    previousRun.dispose();

    final setting = await LiveActivitySetting.load();
    addTearDown(setting.dispose);

    expect(setting.remindsOnFlightDay.value, isFalse);
  });
}
