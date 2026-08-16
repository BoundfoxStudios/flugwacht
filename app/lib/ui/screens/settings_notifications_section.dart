import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/notification_service.dart';
import '../../data/notification_setting.dart';
import '../../domain/flight_notification.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/app_switch_row.dart';
import '../widgets/settings_card.dart';

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
                  onToggled: (isEnabled) => unawaited(
                    notificationSetting.select(kind, isEnabled: isEnabled),
                  ),
                ),
            ],
          ),
        ),
        SignalBuilder(
          builder: (context) =>
              notificationService.permission.value ==
                  NotificationPermission.denied
              ? Text(
                  localizations.settingsNotificationsDenied,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : const SizedBox.shrink(),
        ),
        Text(
          localizations.settingsNotificationsDelivery,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          localizations.settingsNotificationsFootnote,
          style: Theme.of(context).textTheme.bodySmall,
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
