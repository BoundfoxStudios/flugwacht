import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

import '../domain/flight_notification.dart';

/// Which notifications the app may deliver, remembered across launches; every
/// kind starts switched on.
class NotificationSetting {
  NotificationSetting._(this._preferences, Map<FlightNotification, bool> stored)
    : _switches = {
        for (final kind in FlightNotification.values)
          kind: signal(stored[kind] ?? true),
      };

  static Future<NotificationSetting> load() async {
    final preferences = SharedPreferencesAsync();
    return NotificationSetting._(preferences, {
      for (final kind in FlightNotification.values)
        kind: await preferences.getBool(_storageKeyOf(kind)) ?? true,
    });
  }

  final SharedPreferencesAsync _preferences;
  final Map<FlightNotification, Signal<bool>> _switches;

  bool isEnabled(FlightNotification kind) => _switches[kind]!.value;

  Future<void> select(
    FlightNotification kind, {
    required bool isEnabled,
  }) async {
    _switches[kind]!.value = isEnabled;
    await _preferences.setBool(_storageKeyOf(kind), isEnabled);
  }

  void dispose() {
    for (final entry in _switches.values) {
      entry.dispose();
    }
  }

  static String _storageKeyOf(FlightNotification kind) => 'notify_${kind.name}';
}
