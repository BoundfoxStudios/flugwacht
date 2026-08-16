import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/notification_setting.dart';
import '../../domain/flight_notification.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/app_switch_row.dart';
import '../widgets/settings_card.dart';

/// Picks the moments the app notifies about; the notifications themselves stay
/// local on the device.
class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    required this.notificationSetting,
    super.key,
  });

  final NotificationSetting notificationSetting;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
