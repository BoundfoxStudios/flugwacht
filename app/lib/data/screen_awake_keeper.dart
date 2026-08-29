import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals/signals.dart';

import 'screen_awake_service.dart';

/// Keeps the screen on while the setting asks for it and the app is in the
/// foreground. Android's window flag and iOS's idle timer already end with the
/// foreground; releasing it here keeps that promise the app's own.
class ScreenAwakeKeeper with WidgetsBindingObserver {
  ScreenAwakeKeeper({required this._service, required this._keepsScreenAwake});

  final ScreenAwakeService _service;
  final ReadonlySignal<bool> _keepsScreenAwake;
  void Function()? _settingWatch;
  var _isInForeground = true;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _settingWatch = _keepsScreenAwake.subscribe((_) => _apply());
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _settingWatch?.call();
    _settingWatch = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    _apply();
  }

  void _apply() => unawaited(
    _isInForeground && _keepsScreenAwake.value
        ? _service.keepAwake()
        : _service.allowSleep(),
  );
}
