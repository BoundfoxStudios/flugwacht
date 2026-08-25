import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:review_etiquette/review_etiquette.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_icons.dart';
import '../../domain/source_id.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_tokens.dart';
import '../widgets/branding/flugwacht_lockup.dart';
import '../widgets/chrome/settings_card.dart';

const _boundfoxUrl = 'https://boundfoxstudios.com';
const _repositoryUrl = 'https://github.com/BoundfoxStudios/flugwacht';
const _discordUrl = 'https://discord.gg/tHqNzMT';
const _openStreetMapUrl = 'https://www.openstreetmap.org/copyright';
const _appStoreId = '6801012878';

Future<void> _openUrl(String url) => launchUrl(Uri.parse(url));

/// What the app is built on and who built it: the identity, the credits the
/// data and the icons carry, and the way into the package licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({required this.packageInfo, super.key});

  static const _sectionGap = 14.0;

  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.aboutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.grid * 2,
          AppSpacing.screenPadding,
          AppSpacing.screenPaddingLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _sectionGap,
          children: [
            _IdentityCard(
              version: packageInfo.version,
              buildNumber: packageInfo.buildNumber,
            ),
            const _CreditsCard(),
            SettingsCard(
              children: [
                _AboutRow(
                  label: localizations.aboutLicenses,
                  onTap: () => _openLicenses(context),
                ),
              ],
            ),
            SettingsCard(
              children: [
                _AboutRow(
                  label: localizations.aboutRateApp,
                  leading: const FaIcon(
                    AppIcons.star,
                    size: _AboutRow.leadingSize,
                  ),
                  onTap: () => unawaited(_openStoreListing()),
                ),
              ],
            ),
            SettingsCard(
              hint: localizations.settingsBugHint,
              children: [
                _AboutRow(
                  label: localizations.aboutBoundfox,
                  leading: SvgPicture.asset(
                    'assets/logo/bfs.svg',
                    height: _AboutRow.leadingSize,
                  ),
                  onTap: () => unawaited(_openUrl(_boundfoxUrl)),
                ),
                _AboutRow(
                  label: localizations.aboutGithub,
                  leading: const FaIcon(
                    AppIcons.github,
                    size: _AboutRow.leadingSize,
                  ),
                  onTap: () => unawaited(_openUrl(_repositoryUrl)),
                ),
                _AboutRow(
                  label: localizations.aboutDiscord,
                  leading: const FaIcon(
                    AppIcons.discord,
                    size: _AboutRow.leadingSize,
                  ),
                  onTap: () => unawaited(_openUrl(_discordUrl)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openLicenses(BuildContext context) => showLicensePage(
    context: context,
    applicationName: AppLocalizations.of(context).appTitle,
    applicationVersion: packageInfo.version,
  );

  Future<void> _openStoreListing() async {
    try {
      await ReviewEtiquette.showStoreListing(appStoreId: _appStoreId);
    } on ReviewEtiquetteException {
      // A store page that stays closed leaves nothing sensible to show.
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.version, required this.buildNumber});

  static const _lockupHeight = 56.0;

  final String version;

  /// The build the version was cut from, which CI counts up per release. It is
  /// the only way to tell two builds of the same version apart on a device.
  final String buildNumber;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      Column(
        spacing: AppSpacing.cardPadding,
        children: [
          const FlugwachtLockup(height: _lockupHeight),
          Text(
            AppLocalizations.of(context).aboutVersion(version, buildNumber),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ],
  );
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5);
    return SettingsCard(
      title: localizations.aboutSourcesSectionTitle,
      children: [
        for (final sourceId in selectableSourceIds)
          _AboutRow(
            label: sourceId.licenseLabel,
            onTap: () => unawaited(_openUrl(sourceId.websiteUrl)),
          ),
        Text(localizations.aboutSources, style: style),
        _AboutRow(
          label: localizations.aboutMapAttribution,
          onTap: () => unawaited(_openUrl(_openStreetMapUrl)),
        ),
        Text(localizations.aboutIconCredit, style: style),
      ],
    );
  }
}

/// A line of the about screen that leads somewhere, marked by the chevron the
/// settings use.
class _AboutRow extends StatefulWidget {
  const _AboutRow({required this.label, required this.onTap, this.leading});

  static const leadingSize = 20.0;

  // A slot as wide as the widest logo, so rows with differently proportioned
  // logos still start their label at the same x.
  static const _leadingSlotWidth = 24.0;
  static const _chevronSize = 14.0;

  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  State<_AboutRow> createState() => _AboutRowState();
}

class _AboutRowState extends State<_AboutRow> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Semantics(
        button: true,
        child: Transform.translate(
          offset: _isPressed ? const Offset(0, 1) : Offset.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid),
            child: Row(
              spacing: AppSpacing.cardPadding,
              children: [
                if (widget.leading case final leading?)
                  SizedBox(
                    width: _AboutRow._leadingSlotWidth,
                    child: Center(child: leading),
                  ),
                Expanded(
                  child: Text(widget.label, style: theme.textTheme.bodyLarge),
                ),
                FaIcon(
                  AppIcons.chevronRight,
                  size: _AboutRow._chevronSize,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
