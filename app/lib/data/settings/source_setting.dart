import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

import '../../domain/source_id.dart';

/// The source the app polls, remembered across launches: the polling engine
/// resolves its adapter from it and the UI names it.
class SourceSetting {
  SourceSetting._(this._preferences, SourceId active)
    : activeId = signal(active);

  static const _storageKey = 'active_source_id';

  static Future<SourceSetting> load() async {
    final preferences = SharedPreferencesAsync();
    return SourceSetting._(
      preferences,
      _selectableOrDefault(await preferences.getString(_storageKey)),
    );
  }

  final SharedPreferencesAsync _preferences;
  final Signal<SourceId> activeId;

  Future<void> select(SourceId sourceId) async {
    activeId.value = sourceId;
    await _preferences.setString(_storageKey, sourceId.name);
  }

  void dispose() => activeId.dispose();

  static SourceId _selectableOrDefault(String? storedName) {
    final stored = SourceId.values.asNameMap()[storedName];
    return stored != null && selectableSourceIds.contains(stored)
        ? stored
        : defaultSourceId;
  }
}
