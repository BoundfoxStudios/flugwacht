import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app_icons.dart';
import '../../data/settings/source_setting.dart';
import '../../data/settings/units_setting.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/chrome/settings_card.dart';
import 'settings_source_section.dart';
import 'settings_units_section.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.sourceSetting,
    required this.unitsSetting,
    required this.packageInfo,
    super.key,
  });

  static const _sectionGap = 14.0;

  final SourceSetting sourceSetting;
  final UnitsSetting unitsSetting;
  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
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
                    SettingsUnitsSection(unitsSetting: unitsSetting),
                    _LinkCard(
                      title: localizations.settingsNotificationsTitle,
                      route: '/more/notifications',
                    ),
                    _LinkCard(
                      title: localizations.settingsFaqTitle,
                      route: '/more/faq',
                    ),
                    _LinkCard(
                      title: localizations.settingsAboutTitle,
                      subtitle: localizations.settingsAboutSubtitle(
                        packageInfo.version,
                      ),
                      route: '/more/about',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

/// A card of the More screen that leads to one of its sub-screens.
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.title, required this.route, this.subtitle});

  static const _chevronSize = 14.0;

  final String title;
  final String route;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return SettingsCard(
      onTap: () => context.push(route),
      children: [
        Row(
          spacing: AppSpacing.cardPadding,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.grid / 2,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLargeEmphasis.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            FaIcon(
              AppIcons.chevronRight,
              size: _chevronSize,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ],
    );
  }
}
