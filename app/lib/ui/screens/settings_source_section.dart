import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/settings/source_setting.dart';
import '../../domain/source_id.dart';
import '../../l10n/app_localizations.g.dart';
import '../widgets/chrome/settings_card.dart';
import '../widgets/controls/app_radio_row.dart';

/// Picks the source the app polls; the polling engine and every attribution
/// follow the setting.
class SettingsSourceSection extends StatelessWidget {
  const SettingsSourceSection({required this.sourceSetting, super.key});

  final SourceSetting sourceSetting;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SettingsCard(
      title: localizations.settingsSourceSectionTitle,
      children: [
        SignalBuilder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final sourceId in selectableSourceIds)
                AppRadioRow(
                  label: sourceId.label,
                  isSelected: sourceId == sourceSetting.activeId.value,
                  onSelected: () => unawaited(sourceSetting.select(sourceId)),
                ),
            ],
          ),
        ),
        Text(
          localizations.settingsSourceExplainer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}
