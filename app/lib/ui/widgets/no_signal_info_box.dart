import 'package:flutter/material.dart';

import '../../domain/signal_age.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'flight_labels.dart';

/// Tells the reader that a missing signal is a coverage gap, not a lost flight.
class NoSignalInfoBox extends StatelessWidget {
  const NoSignalInfoBox({required this.age, super.key});

  static const _padding = EdgeInsets.symmetric(vertical: 10, horizontal: 12);
  static const _lineHeight = 1.5;

  final SignalAge age;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _InfoBoxColors.light,
      Brightness.dark => _InfoBoxColors.dark,
    };
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        localizations.mapSheetNoSignalInfo(signalAgeLabel(localizations, age)),
        style: AppTextStyles.secondary.copyWith(
          color: colors.text,
          height: _lineHeight,
        ),
      ),
    );
  }
}

enum _InfoBoxColors {
  light(
    surface: AppColors.neutral50,
    border: AppColors.neutral200,
    text: AppColors.neutral500,
  ),
  dark(
    surface: AppColors.neutral900,
    border: AppColors.neutral700,
    text: AppColors.neutral400,
  );

  const _InfoBoxColors({
    required this.surface,
    required this.border,
    required this.text,
  });

  final Color surface;
  final Color border;
  final Color text;
}
