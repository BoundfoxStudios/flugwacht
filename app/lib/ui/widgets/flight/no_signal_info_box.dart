import 'package:flutter/widgets.dart';

import '../../../domain/signal_age.dart';
import '../../../l10n/app_localizations.g.dart';
import 'flight_labels.dart';
import 'sheet_info_box.dart';

/// Tells the reader that a missing signal is a coverage gap, not a lost
/// flight, and what the outline on the map estimates while there is one.
class NoSignalInfoBox extends StatelessWidget {
  const NoSignalInfoBox({required this.age, super.key, this.estimatedTowards});

  final SignalAge age;
  final String? estimatedTowards;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final ageLabel = signalAgeLabel(localizations, age);
    return SheetInfoBox(
      text: switch (estimatedTowards) {
        final destination? => localizations.mapSheetNoSignalEstimateInfo(
          ageLabel,
          destination,
        ),
        null => localizations.mapSheetNoSignalInfo(ageLabel),
      },
    );
  }
}
