import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

import '../../domain/map_style.dart';

/// How the map draws its ground, remembered across launches: the toggle on the
/// map tab writes it, every map in the app follows it.
class MapStyleSetting {
  MapStyleSetting._(this._preferences, MapStyle style) : style = signal(style);

  static const _storageKey = 'map_style';

  static Future<MapStyleSetting> load() async {
    final preferences = SharedPreferencesAsync();
    return MapStyleSetting._(
      preferences,
      _knownOrDefault(await preferences.getString(_storageKey)),
    );
  }

  final SharedPreferencesAsync _preferences;
  final Signal<MapStyle> style;

  Future<void> select(MapStyle style) async {
    this.style.value = style;
    await _preferences.setString(_storageKey, style.name);
  }

  Future<void> toggle() => select(switch (style.value) {
    MapStyle.reduced => MapStyle.rasterOsm,
    MapStyle.rasterOsm => MapStyle.reduced,
  });

  void dispose() => style.dispose();

  static MapStyle _knownOrDefault(String? storedName) =>
      MapStyle.values.asNameMap()[storedName] ?? defaultMapStyle;
}
