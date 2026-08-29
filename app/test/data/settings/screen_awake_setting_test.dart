import 'package:flugwacht/data/settings/screen_awake_setting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ScreenAwakeSetting> loadWith(Map<String, Object> stored) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    final setting = await ScreenAwakeSetting.load();
    addTearDown(setting.dispose);
    return setting;
  }

  test('leaves the screen to the system when nothing was stored', () async {
    final setting = await loadWith(const {});

    expect(setting.keepsScreenAwake.value, isFalse);
  });

  test('restores the choice a previous run made', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await ScreenAwakeSetting.load();
    await previousRun.select(isEnabled: true);
    previousRun.dispose();

    final setting = await ScreenAwakeSetting.load();
    addTearDown(setting.dispose);

    expect(setting.keepsScreenAwake.value, isTrue);
  });
}
