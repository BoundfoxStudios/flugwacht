import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/radar_eye_logo.dart';

/// The whole list screen while there is no flight to show: the centered call
/// to action is the only way on, so the screen carries neither header nor FAB.
class ListEmptyState extends StatelessWidget {
  const ListEmptyState({required this.onAddFlight, super.key});

  static const _logoSize = 76.0;
  static const _gap = AppSpacing.cardPaddingLarge;
  static const _callToActionGap = _gap + AppSpacing.grid * 2;
  static const _horizontalPadding = 40.0;
  static const _bodyLineHeight = 1.625;

  final VoidCallback onAddFlight;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: AppSpacing.screenPaddingLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadarEyeLogo(size: _logoSize),
                  const SizedBox(height: _gap),
                  Text(
                    localizations.listEmptyHeadline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: _gap),
                  Text(
                    localizations.listEmptyBody,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      height: _bodyLineHeight,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: _callToActionGap),
                  AppPrimaryButton(
                    label: localizations.listEmptyCta,
                    onPressed: onAddFlight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
