import 'package:flugwacht/data/settings/source_setting.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SourceSetting> loadWith(Map<String, Object> stored) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(stored);
    final setting = await SourceSetting.load();
    addTearDown(setting.dispose);
    return setting;
  }

  test('starts on adsb.lol when nothing was stored', () async {
    final setting = await loadWith(const {});

    expect(setting.activeId.value, SourceId.adsblol);
  });

  test('restores the source a previous run selected', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previousRun = await SourceSetting.load();
    await previousRun.select(SourceId.adsbfi);
    previousRun.dispose();

    final setting = await SourceSetting.load();
    addTearDown(setting.dispose);

    expect(setting.activeId.value, SourceId.adsbfi);
  });

  test('falls back to adsb.lol for a stored source it does not know', () async {
    final setting = await loadWith(const {'active_source_id': 'flightradar'});

    expect(setting.activeId.value, SourceId.adsblol);
  });

  test('falls back to adsb.lol for a stored source that is hidden', () async {
    final setting = await loadWith(const {'active_source_id': 'airplanes'});

    expect(setting.activeId.value, SourceId.adsblol);
  });
}
