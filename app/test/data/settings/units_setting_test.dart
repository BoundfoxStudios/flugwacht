import 'package:flugwacht/data/settings/units_setting.dart';
import 'package:flugwacht/domain/units.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<UnitsSetting> loadWith(Map<String, Object> stored) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    final setting = await UnitsSetting.load();
    addTearDown(setting.dispose);
    return setting;
  }

  test('starts metric when nothing was stored', () async {
    final setting = await loadWith(const {});

    expect(setting.units.value, Units.metric);
  });

  test('restores the units a previous run selected', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await UnitsSetting.load();
    await previousRun.select(Units.aviation);
    previousRun.dispose();

    final setting = await UnitsSetting.load();
    addTearDown(setting.dispose);

    expect(setting.units.value, Units.aviation);
  });

  test('falls back to metric for stored units it does not know', () async {
    final setting = await loadWith(const {'units': 'nautical'});

    expect(setting.units.value, Units.metric);
  });
}
