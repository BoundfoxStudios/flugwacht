import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/live_activities/live_activity_service.dart';
import '../../data/settings/live_activity_setting.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/chrome/settings_card.dart';
import '../widgets/controls/app_switch_row.dart';

/// The one thing about Live Activities that is settled once for all flights:
/// whether the app reminds the user on the flight day. A device that shows no
/// activities has nothing to settle here.
class SettingsLiveActivitySection extends StatelessWidget {
  const SettingsLiveActivitySection({
    required this.setting,
    required this.service,
    super.key,
  });

  final LiveActivitySetting setting;
  final LiveActivityService service;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) =>
          service.availability.value == LiveActivityAvailability.unsupported
          ? const SizedBox.shrink()
          : SettingsCard(
              title: localizations.settingsLiveActivitySectionTitle,
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
            ),
    );
  }
}
