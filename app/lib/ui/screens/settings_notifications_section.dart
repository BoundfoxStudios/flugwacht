import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/notifications/notification_service.dart';
import '../../data/settings/notification_setting.dart';
import '../../domain/flight_notification.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/chrome/settings_card.dart';
import '../widgets/controls/app_switch_row.dart';

/// Picks the moments the app notifies about; the notifications themselves stay
/// local on the device.
class SettingsNotificationsSection extends StatefulWidget {
  const SettingsNotificationsSection({
    required this.notificationSetting,
    required this.notificationService,
    super.key,
  });

  final NotificationSetting notificationSetting;
  final NotificationService notificationService;

  @override
  State<SettingsNotificationsSection> createState() =>
      _SettingsNotificationsSectionState();
}

class _SettingsNotificationsSectionState
    extends State<SettingsNotificationsSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.notificationService.refreshPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A trip to the system settings is the way notifications get switched off,
  /// so the hint only stays honest if the app looks again on the way back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.notificationService.refreshPermission());
    }
  }

  /// With everything off by default, the first switch that goes on is where the
  /// permission is still undecided — and nothing would be delivered without it.
  Future<void> _toggle(
    FlightNotification kind, {
    required bool isEnabled,
  }) async {
    await widget.notificationSetting.select(kind, isEnabled: isEnabled);
    if (isEnabled &&
        widget.notificationService.permission.value ==
            NotificationPermission.notDetermined) {
      await widget.notificationService.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final notificationSetting = widget.notificationSetting;
    final notificationService = widget.notificationService;
    return SettingsCard(
      title: localizations.settingsNotificationsSectionTitle,
      children: [
        SignalBuilder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in FlightNotification.values)
                AppSwitchRow(
                  label: notificationLabel(localizations, kind),
                  isEnabled: notificationSetting.isEnabled(kind),
                  onToggled: (isEnabled) =>
                      unawaited(_toggle(kind, isEnabled: isEnabled)),
                ),
            ],
          ),
        ),
        SignalBuilder(
          builder: (context) => switch (notificationService.permission.value) {
            NotificationPermission.denied => Text(
              localizations.settingsNotificationsDenied,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            NotificationPermission.unavailable => Text(
              localizations.settingsNotificationsUnavailable,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            NotificationPermission.notDetermined ||
            NotificationPermission.granted => const SizedBox.shrink(),
          },
        ),
        // Nothing is delivered on a device that could not set the notifications
        // up, so promising when they arrive would be a lie.
        SignalBuilder(
          builder: (context) =>
              notificationService.permission.value ==
                  NotificationPermission.unavailable
              ? const SizedBox.shrink()
              : Text(
                  localizations.settingsNotificationsDelivery,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
      ],
    );
  }
}

/// How a notification kind is named wherever the app talks about it.
String notificationLabel(
  AppLocalizations localizations,
  FlightNotification kind,
) => switch (kind) {
  FlightNotification.departed => localizations.settingsNotificationDeparted,
  FlightNotification.arrivingSoon =>
    localizations.settingsNotificationArrivingSoon,
  FlightNotification.landed => localizations.settingsNotificationLanded,
};
