import 'package:flutter/widgets.dart';

import '../../../domain/signal_age.dart';
import '../../../l10n/app_localizations.g.dart';
import 'flight_labels.dart';
import 'sheet_info_box.dart';

/// Tells the reader that a missing signal is a coverage gap, not a lost flight.
class NoSignalInfoBox extends StatelessWidget {
  const NoSignalInfoBox({required this.age, super.key});

  final SignalAge age;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SheetInfoBox(
      text: localizations.mapSheetNoSignalInfo(
        signalAgeLabel(localizations, age),
      ),
    );
  }
}
