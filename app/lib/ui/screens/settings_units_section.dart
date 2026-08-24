import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/settings/units_setting.dart';
import '../../domain/units.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/chrome/settings_card.dart';
import '../widgets/controls/app_segmented_control.dart';

/// Picks the units altitude and speed are displayed in; the estimates keep
/// working on the raw values either way.
class SettingsUnitsSection extends StatelessWidget {
  const SettingsUnitsSection({required this.unitsSetting, super.key});

  final UnitsSetting unitsSetting;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SettingsCard(
      title: localizations.settingsUnitsSectionTitle,
      children: [
        SignalBuilder(
          builder: (context) => AppSegmentedControl(
            segments: {
              Units.metric: localizations.settingsUnitsMetric,
              Units.aviation: localizations.settingsUnitsAviation,
            },
            selected: unitsSetting.units.value,
            onSelected: (units) => unawaited(unitsSetting.select(units)),
          ),
        ),
      ],
    );
  }
}
