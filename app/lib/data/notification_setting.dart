import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

import '../domain/flight_notification.dart';

/// Which notifications the app may deliver, remembered across launches; every
/// kind starts switched off until the user opts in.
class NotificationSetting {
  NotificationSetting._(this._preferences, Map<FlightNotification, bool> stored)
    : _switches = {
        for (final kind in FlightNotification.values)
          kind: signal(stored[kind] ?? false),
      };

  static Future<NotificationSetting> load() async {
    final preferences = SharedPreferencesAsync();
    final wasOffered = await preferences.getBool(_offeredKey) ?? false;
    return NotificationSetting._(preferences, {
      for (final kind in FlightNotification.values)
        kind: await preferences.getBool(_storageKeyOf(kind)) ?? false,
    }).._wasOffered = wasOffered;
  }

  static const _offeredKey = 'notify_offered';

  final SharedPreferencesAsync _preferences;
  final Map<FlightNotification, Signal<bool>> _switches;
  var _wasOffered = false;

  /// Whether the app already put the notifications up for a decision. It asks
  /// once per installation, no matter how many flights come and go.
  bool get wasOffered => _wasOffered;

  bool isEnabled(FlightNotification kind) => _switches[kind]!.value;

  Future<void> select(
    FlightNotification kind, {
    required bool isEnabled,
  }) async {
    _switches[kind]!.value = isEnabled;
    await _preferences.setBool(_storageKeyOf(kind), isEnabled);
  }

  Future<void> enableAll() async {
    for (final kind in FlightNotification.values) {
      await select(kind, isEnabled: true);
    }
  }

  Future<void> rememberOffer() async {
    _wasOffered = true;
    await _preferences.setBool(_offeredKey, true);
  }

  void dispose() {
    for (final entry in _switches.values) {
      entry.dispose();
    }
  }

  static String _storageKeyOf(FlightNotification kind) => 'notify_${kind.name}';
}
