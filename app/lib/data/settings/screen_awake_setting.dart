import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

/// Whether the screen stays on while the app is open, so a flight can be
/// watched without touching the phone.
class ScreenAwakeSetting {
  ScreenAwakeSetting._(this._preferences, {required bool keepsScreenAwake})
    : keepsScreenAwake = signal(keepsScreenAwake);

  static const _storageKey = 'keep_screen_awake';

  static Future<ScreenAwakeSetting> load() async {
    final preferences = SharedPreferencesAsync();
    return ScreenAwakeSetting._(
      preferences,
      // Off by default: the app leaves the system's display timeout alone
      // until someone asks for something else.
      keepsScreenAwake: await preferences.getBool(_storageKey) ?? false,
    );
  }

  final SharedPreferencesAsync _preferences;
  final Signal<bool> keepsScreenAwake;

  Future<void> select({required bool isEnabled}) async {
    keepsScreenAwake.value = isEnabled;
    await _preferences.setBool(_storageKey, isEnabled);
  }

  void dispose() => keepsScreenAwake.dispose();
}
