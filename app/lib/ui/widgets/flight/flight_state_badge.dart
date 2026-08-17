import 'package:flutter/material.dart';

import '../../../domain/flight_state.dart';
import '../../../l10n/app_localizations.g.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// The pill that names an airborne flight's state: filled yellow while live,
/// gray while the signal is missing.
class FlightStateBadge extends StatelessWidget {
  const FlightStateBadge({required this.state, super.key});

  static const _dotSize = 5.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 2);

  final FlightState state;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _BadgeColors.light,
      Brightness.dark => _BadgeColors.dark,
    };
    final isLive = state == FlightState.live;
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: isLive ? AppColors.yellow : colors.noSignalFill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: colors.noSignalBorder == null || isLive
            ? null
            : Border.all(color: colors.noSignalBorder!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const SizedBox(
              width: _dotSize,
              height: _dotSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.neutral900,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.grid + 1),
          ],
          Text(
            (isLive
                    ? localizations.flightBadgeLive
                    : localizations.flightBadgeNoSignal)
                .toUpperCase(),
            style: AppTextStyles.badgeLabel.copyWith(
              color: isLive ? AppColors.neutral900 : colors.noSignalText,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeColors {
  light(noSignalFill: AppColors.neutral700, noSignalText: AppColors.yellow),
  dark(
    noSignalFill: null,
    noSignalBorder: AppColors.neutral500,
    noSignalText: AppColors.neutral300,
  );

  const _BadgeColors({
    required this.noSignalFill,
    required this.noSignalText,
    this.noSignalBorder,
  });

  final Color? noSignalFill;
  final Color? noSignalBorder;
  final Color noSignalText;
}
