import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/source_setting.dart';
import '../../domain/source_id.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/settings_card.dart';
import 'settings_source_section.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.sourceSetting,
    required this.packageInfo,
    super.key,
  });

  static const _sectionGap = 14.0;

  final SourceSetting sourceSetting;
  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.screenPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SettingsHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: _sectionGap,
                children: [
                  SettingsSourceSection(sourceSetting: sourceSetting),
                  _AboutCard(version: packageInfo.version),
                  const _DataFootnote(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPaddingLarge,
      AppSpacing.screenPaddingLarge,
      AppSpacing.screenPaddingLarge,
      AppSpacing.grid * 3,
    ),
    child: Text(
      AppLocalizations.of(context).settingsTitle,
      style: Theme.of(context).textTheme.headlineLarge,
    ),
  );
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return SettingsCard(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.grid / 2,
          children: [
            Text(
              localizations.settingsAboutTitle,
              style: AppTextStyles.bodyLargeEmphasis.copyWith(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              localizations.settingsAboutSubtitle(version),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _DataFootnote extends StatelessWidget {
  const _DataFootnote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.grid),
    child: Text(
      AppLocalizations.of(context).settingsDataFootnote(
        selectableSourceIds.map((sourceId) => sourceId.licenseLabel).join(', '),
      ),
      style: AppTextStyles.caption.copyWith(
        color: Theme.of(context).textTheme.labelSmall?.color,
        height: 1.5,
      ),
    ),
  );
}
