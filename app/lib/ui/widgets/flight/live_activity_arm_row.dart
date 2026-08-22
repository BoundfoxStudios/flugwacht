import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../data/live_activities/live_activity_service.dart';
import '../../../l10n/app_localizations.g.dart';
import '../controls/app_switch_row.dart';

/// Puts a flight on the Lock Screen on its flight day. A device that cannot
/// show activities gets no switch at all; one whose owner switched them off in
/// the system settings gets the switch plus the reason it does nothing.
class LiveActivityArmRow extends StatelessWidget {
  const LiveActivityArmRow({
    required this.availability,
    required this.isArmed,
    required this.onToggled,
    super.key,
  });

  final Signal<LiveActivityAvailability> availability;
  final bool isArmed;
  final ValueChanged<bool> onToggled;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) => switch (availability.value) {
        LiveActivityAvailability.unsupported => const SizedBox.shrink(),
        LiveActivityAvailability.disabled => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSwitchRow(
              label: localizations.liveActivityArmLabel,
              isEnabled: isArmed,
              onToggled: onToggled,
            ),
            Text(
              localizations.liveActivityDisabledHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        LiveActivityAvailability.enabled => AppSwitchRow(
          label: localizations.liveActivityArmLabel,
          isEnabled: isArmed,
          onToggled: onToggled,
        ),
      },
    );
  }
}
