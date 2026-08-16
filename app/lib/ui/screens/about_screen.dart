import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_icons.dart';
import '../../domain/source_id.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_tokens.dart';
import '../widgets/radar_eye_logo.dart';
import '../widgets/settings_card.dart';

const _boundfoxUrl = 'https://boundfoxstudios.com';
const _repositoryUrl = 'https://github.com/BoundfoxStudios/flugwacht';

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
            _IdentityCard(version: packageInfo.version),
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
                  label: localizations.aboutBoundfox,
                  leading: SvgPicture.asset(
                    'assets/logo/bfs.svg',
                    height: _AboutRow.leadingSize,
                  ),
                  onTap: () => unawaited(_openUrl(_boundfoxUrl)),
                ),
                _AboutRow(
                  label: localizations.aboutGithub,
                  onTap: () => unawaited(_openUrl(_repositoryUrl)),
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

  Future<void> _openUrl(String url) => launchUrl(Uri.parse(url));
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.version});

  static const _logoSize = 56.0;

  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return SettingsCard(
      children: [
        Column(
          spacing: AppSpacing.grid * 2,
          children: [
            const RadarEyeLogo(size: _logoSize),
            Text(localizations.appTitle, style: theme.textTheme.headlineMedium),
            Text(
              localizations.aboutVersion(version),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
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
        Text(
          localizations.aboutSources(
            selectableSourceIds
                .map((sourceId) => sourceId.licenseLabel)
                .join(', '),
          ),
          style: style,
        ),
        Text(localizations.aboutMapAttribution, style: style),
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
                ?widget.leading,
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
