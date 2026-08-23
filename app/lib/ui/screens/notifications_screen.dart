import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/live_activities/live_activity_service.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/settings/live_activity_setting.dart';
import '../../data/settings/notification_setting.dart';
import '../../domain/flight_notification.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_tokens.dart';
import '../widgets/chrome/settings_card.dart';
import '../widgets/controls/app_switch_row.dart';

/// Everything the app notifies about, grouped by when it reaches the user. The
/// notifications themselves stay local on the device, and whether a flight gets
/// a Live Activity is decided per flight, not here.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    required this.notificationSetting,
    required this.notificationService,
    required this.liveActivitySetting,
    required this.liveActivityService,
    super.key,
  });

  static const _sectionGap = 14.0;

  final NotificationSetting notificationSetting;
  final NotificationService notificationService;
  final LiveActivitySetting liveActivitySetting;
  final LiveActivityService liveActivityService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
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
    return Scaffold(
      appBar: AppBar(title: Text(localizations.notificationsTitle)),
      body: SignalBuilder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.grid * 2,
            AppSpacing.screenPadding,
            AppSpacing.screenPaddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: NotificationsScreen._sectionGap,
            children: [
              _DuringFlightCard(
                setting: widget.notificationSetting,
                service: widget.notificationService,
              ),
              if (widget.liveActivityService.availability.value !=
                  LiveActivityAvailability.unsupported)
                _FlightDayCard(setting: widget.liveActivitySetting),
              if (_systemHint(
                    localizations,
                    widget.notificationService.permission.value,
                  )
                  case final hint?)
                Text(hint, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

String? _systemHint(
  AppLocalizations localizations,
  NotificationPermission permission,
) => switch (permission) {
  NotificationPermission.denied => localizations.settingsNotificationsDenied,
  NotificationPermission.unavailable =>
    localizations.settingsNotificationsUnavailable,
  NotificationPermission.notDetermined ||
  NotificationPermission.granted => null,
};

/// The moments of a running flight the app can announce.
class _DuringFlightCard extends StatelessWidget {
  const _DuringFlightCard({required this.setting, required this.service});

  final NotificationSetting setting;
  final NotificationService service;

  /// With everything off by default, the first switch that goes on is where the
  /// permission is still undecided, and nothing would be delivered without it.
  Future<void> _toggle(
    FlightNotification kind, {
    required bool isEnabled,
  }) async {
    await setting.select(kind, isEnabled: isEnabled);
    if (isEnabled &&
        service.permission.value == NotificationPermission.notDetermined) {
      await service.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) => SettingsCard(
        title: localizations.notificationsDuringFlightTitle,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in FlightNotification.values)
                AppSwitchRow(
                  label: notificationLabel(localizations, kind),
                  isEnabled: setting.isEnabled(kind),
                  onToggled: (isEnabled) =>
                      unawaited(_toggle(kind, isEnabled: isEnabled)),
                ),
            ],
          ),
          // Nothing is delivered on a device that could not set the
          // notifications up, so promising when they arrive would be a lie.
          if (service.permission.value != NotificationPermission.unavailable)
            Text(
              localizations.settingsNotificationsDelivery,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// The reminder that offers to start a Live Activity, the one notification
/// settled once for all flights.
class _FlightDayCard extends StatelessWidget {
  const _FlightDayCard({required this.setting});

  final LiveActivitySetting setting;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SettingsCard(
      title: localizations.notificationsFlightDayTitle,
      children: [
        SignalBuilder(
          builder: (context) => AppSwitchRow(
            label: localizations.settingsLiveActivityReminder,
            isEnabled: setting.remindsOnFlightDay.value,
            onToggled: (isEnabled) =>
                unawaited(setting.selectReminder(isEnabled: isEnabled)),
          ),
        ),
        Text(
          localizations.settingsLiveActivityHint,
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
