import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

import '../domain/units.dart';

/// The units the app displays, remembered across launches; a display choice
/// only — estimates and thresholds keep working on the raw values.
class UnitsSetting {
  UnitsSetting._(this._preferences, Units units) : units = signal(units);

  static const _storageKey = 'units';

  static Future<UnitsSetting> load() async {
    final preferences = SharedPreferencesAsync();
    return UnitsSetting._(
      preferences,
      _knownOrDefault(await preferences.getString(_storageKey)),
    );
  }

  final SharedPreferencesAsync _preferences;
  final Signal<Units> units;

  Future<void> select(Units units) async {
    this.units.value = units;
    await _preferences.setString(_storageKey, units.name);
  }

  void dispose() => units.dispose();

  static Units _knownOrDefault(String? storedName) =>
      Units.values.asNameMap()[storedName] ?? defaultUnits;
}
