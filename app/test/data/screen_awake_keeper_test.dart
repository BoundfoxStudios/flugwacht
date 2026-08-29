import 'package:flugwacht/data/screen_awake_keeper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';

import '../support/test_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({
    FakeScreenAwakeService service,
    Signal<bool> setting,
    ScreenAwakeKeeper keeper,
  })
  startKeeper({required bool keepsScreenAwake}) {
    final service = FakeScreenAwakeService();
    final setting = signal(keepsScreenAwake);
    addTearDown(setting.dispose);
    final keeper = ScreenAwakeKeeper(
      service: service,
      keepsScreenAwake: setting,
    )..start();
    addTearDown(keeper.stop);
    return (service: service, setting: setting, keeper: keeper);
  }

  test('keeps the screen on while the setting asks for it', () {
    final started = startKeeper(keepsScreenAwake: true);

    expect(started.service.keepsScreenAwake, isTrue);
  });

  test('follows the setting while the app is open', () {
    final started = startKeeper(keepsScreenAwake: false);

    started.setting.value = true;
    expect(started.service.keepsScreenAwake, isTrue);

    started.setting.value = false;
    expect(started.service.keepsScreenAwake, isFalse);
  });

  test('hands the screen back when the app leaves the foreground', () {
    final started = startKeeper(keepsScreenAwake: true);

    started.keeper.didChangeAppLifecycleState(AppLifecycleState.paused);

    expect(started.service.keepsScreenAwake, isFalse);
  });

  test('keeps the screen on again once the app is back', () {
    final started = startKeeper(keepsScreenAwake: true);

    started.keeper
      ..didChangeAppLifecycleState(AppLifecycleState.paused)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(started.service.keepsScreenAwake, isTrue);
  });

  test('ignores a setting switched on while the app is in the background', () {
    final started = startKeeper(keepsScreenAwake: false);

    started.keeper.didChangeAppLifecycleState(AppLifecycleState.paused);
    started.setting.value = true;

    expect(started.service.keepsScreenAwake, isFalse);
  });
}
