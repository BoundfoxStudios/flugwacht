import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../../data/live_activities/live_activity_service.dart';
import '../../../l10n/app_localizations.g.dart';
import '../controls/app_switch_row.dart';
import 'live_activity_labels.dart';

/// What a flight cell needs to offer the switch of the flight it shows.
typedef FlightLiveActivityControl = ({
  Signal<LiveActivityAvailability> availability,
  ValueChanged<bool> onArmed,
});

/// Puts a flight on the Lock Screen on its flight day. A device that cannot
/// show activities gets no switch at all; one whose owner switched them off in
/// the system settings gets the switch plus the reason it does nothing.
class LiveActivityArmRow extends StatelessWidget {
  const LiveActivityArmRow({
    required this.availability,
    required this.isArmed,
    required this.onToggled,
    super.key,
    this.separator,
  });

  final Signal<LiveActivityAvailability> availability;
  final bool isArmed;
  final ValueChanged<bool> onToggled;

  /// Sets the switch off from what a list cell shows above it, and goes with
  /// the switch – a device without activities is left no gap or hairline.
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final availability = this.availability.value;
        if (availability == LiveActivityAvailability.unsupported) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?separator,
            AppSwitchRow(
              label: liveActivityArmLabel(localizations),
              isEnabled: isArmed,
              onToggled: onToggled,
            ),
            if (availability == LiveActivityAvailability.disabled)
              Text(
                liveActivityDisabledHint(localizations),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    );
  }
}
