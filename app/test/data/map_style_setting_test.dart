import 'package:flugwacht/data/map_style_setting.dart';
import 'package:flugwacht/domain/map_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MapStyleSetting> loadWith(Map<String, Object> stored) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    final setting = await MapStyleSetting.load();
    addTearDown(setting.dispose);
    return setting;
  }

  test('starts on the reduced style when nothing was stored', () async {
    final setting = await loadWith(const {});

    expect(setting.style.value, MapStyle.reduced);
  });

  test('restores the style a previous run selected', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await MapStyleSetting.load();
    await previousRun.select(MapStyle.rasterOsm);
    previousRun.dispose();

    final setting = await MapStyleSetting.load();
    addTearDown(setting.dispose);

    expect(setting.style.value, MapStyle.rasterOsm);
  });

  test(
    'falls back to the reduced style for a stored style it does not know',
    () async {
      final setting = await loadWith(const {'map_style': 'satellite'});

      expect(setting.style.value, MapStyle.reduced);
    },
  );

  test('toggles between the reduced and the raster style', () async {
    final setting = await loadWith(const {});

    await setting.toggle();
    expect(setting.style.value, MapStyle.rasterOsm);

    await setting.toggle();
    expect(setting.style.value, MapStyle.reduced);
  });
}
