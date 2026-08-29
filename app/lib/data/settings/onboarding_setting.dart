import 'package:shared_preferences/shared_preferences.dart';

/// Whether the introduction has already run. It shows once per installation,
/// ahead of everything else the app offers, and never asks again.
class OnboardingSetting {
  OnboardingSetting._(this._preferences);

  static const _storageKey = 'onboarding_seen';

  static Future<OnboardingSetting> load() async {
    final preferences = SharedPreferencesAsync();
    final wasSeen = await preferences.getBool(_storageKey) ?? false;
    return OnboardingSetting._(preferences).._wasSeen = wasSeen;
  }

  final SharedPreferencesAsync _preferences;
  var _wasSeen = false;

  bool get wasSeen => _wasSeen;

  Future<void> remember() async {
    _wasSeen = true;
    await _preferences.setBool(_storageKey, true);
  }
}
