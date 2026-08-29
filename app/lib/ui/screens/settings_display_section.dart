import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/settings/screen_awake_setting.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/chrome/settings_card.dart';
import '../widgets/controls/app_switch_row.dart';

/// The switch that keeps the screen on while the app is open.
class SettingsDisplaySection extends StatelessWidget {
  const SettingsDisplaySection({required this.screenAwakeSetting, super.key});

  final ScreenAwakeSetting screenAwakeSetting;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SettingsCard(
      title: localizations.settingsDisplaySectionTitle,
      children: [
        SignalBuilder(
          builder: (context) => AppSwitchRow(
            label: localizations.settingsKeepScreenOn,
            isEnabled: screenAwakeSetting.keepsScreenAwake.value,
            onToggled: (isEnabled) =>
                unawaited(screenAwakeSetting.select(isEnabled: isEnabled)),
          ),
        ),
        Text(
          localizations.settingsKeepScreenOnHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
