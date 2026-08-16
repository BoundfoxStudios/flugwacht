import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'app_primary_button.dart';

/// Puts the notifications up for a decision in the app's own words, before the
/// operating system ever shows its prompt. A dismissed dialog counts as a no.
Future<bool> showNotificationOfferDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NotificationOfferDialog(),
    ) ??
    false;

class _NotificationOfferDialog extends StatelessWidget {
  const _NotificationOfferDialog();

  static const _bodyHeight = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.cardPaddingLarge,
          children: [
            Text(
              localizations.notificationOfferTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              localizations.notificationOfferBody,
              style: theme.textTheme.bodyMedium?.copyWith(height: _bodyHeight),
              textAlign: TextAlign.center,
            ),
            AppPrimaryButton(
              label: localizations.notificationOfferAccept,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            _DeclineLink(
              label: localizations.notificationOfferDecline,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeclineLink extends StatelessWidget {
  const _DeclineLink({required this.label, required this.onTap});

  static const _minimumTapTarget = 44.0;

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Semantics(
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minimumTapTarget),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: switch (Theme.of(context).brightness) {
                Brightness.light => AppColors.linkLight,
                Brightness.dark => AppColors.linkDark,
              },
            ),
          ),
        ),
      ),
    ),
  );
}
