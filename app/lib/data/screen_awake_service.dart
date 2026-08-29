import 'package:wakelock_plus/wakelock_plus.dart';

/// The seam between the app and the wakelock plugin, so nothing above it talks
/// to the platform directly.
abstract interface class ScreenAwakeService {
  Future<void> keepAwake();

  Future<void> allowSleep();
}

class WakelockScreenAwakeService implements ScreenAwakeService {
  @override
  Future<void> keepAwake() => WakelockPlus.enable();

  @override
  Future<void> allowSleep() => WakelockPlus.disable();
}
