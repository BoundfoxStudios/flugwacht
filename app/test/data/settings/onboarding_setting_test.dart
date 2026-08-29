import 'package:flugwacht/data/settings/onboarding_setting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingSetting> loadWith(Map<String, Object> stored) {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    return OnboardingSetting.load();
  }

  test('counts the introduction as unseen when nothing was stored', () async {
    final setting = await loadWith(const {});

    expect(setting.wasSeen, isFalse);
  });

  test('restores that a previous run showed the introduction', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await OnboardingSetting.load();
    await previousRun.remember();

    final setting = await OnboardingSetting.load();

    expect(setting.wasSeen, isTrue);
  });
}
