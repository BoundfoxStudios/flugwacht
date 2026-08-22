import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

/// Whether the app reminds the user on the flight day that an armed flight's
/// Live Activity can start. The activities themselves are armed per flight and
/// have the system's word over them, so this is the one thing left to settle
/// once for all flights.
class LiveActivitySetting {
  LiveActivitySetting._(
    this._preferences, {
    required bool remindsOnFlightDay,
    required this.armsNewFlights,
  }) : remindsOnFlightDay = signal(remindsOnFlightDay);

  static const _reminderKey = 'live_activity_flight_day_reminder';
  static const _armsNewFlightsKey = 'live_activity_arms_new_flights';

  static Future<LiveActivitySetting> load() async {
    final preferences = SharedPreferencesAsync();
    return LiveActivitySetting._(
      preferences,
      // On by default: the reminder is what makes an activity armed weeks
      // ahead show up on the day it counts.
      remindsOnFlightDay: await preferences.getBool(_reminderKey) ?? true,
      armsNewFlights: await preferences.getBool(_armsNewFlightsKey) ?? false,
    );
  }

  final SharedPreferencesAsync _preferences;
  final Signal<bool> remindsOnFlightDay;

  /// What the arming switch offers for the next flight: whoever armed their
  /// last flight most likely wants the one they are adding now, and whoever
  /// did not is not asked again.
  bool armsNewFlights;

  Future<void> selectReminder({required bool isEnabled}) async {
    remindsOnFlightDay.value = isEnabled;
    await _preferences.setBool(_reminderKey, isEnabled);
  }

  Future<void> rememberArming({required bool isArmed}) async {
    armsNewFlights = isArmed;
    await _preferences.setBool(_armsNewFlightsKey, isArmed);
  }

  void dispose() => remindsOnFlightDay.dispose();
}
