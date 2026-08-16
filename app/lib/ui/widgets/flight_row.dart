import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/flight.dart';
import '../../domain/flight_state.dart';
import '../../domain/relative_day.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'flight_labels.dart';

/// A non-hero list cell: the waiting row, the dashed planned row and the
/// grayed row of the past section, told apart by the derived flight state.
class FlightRow extends StatelessWidget {
  const FlightRow({
    required this.flight,
    required this.state,
    required this.now,
    super.key,
  });

  static const _verticalPadding = 14.0;
  static const _titleGap = 2.0;

  final Flight flight;
  final FlightState state;

  /// Names the departure day of a past row relative to the current one.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final palette = switch (Theme.of(context).brightness) {
      Brightness.light => _RowPalette.light,
      Brightness.dark => _RowPalette.dark,
    };
    final variant = switch (state) {
      FlightState.planned => _RowVariant.planned,
      FlightState.ended || FlightState.missed => _RowVariant.past,
      FlightState.waiting ||
      FlightState.live ||
      FlightState.noSignal => _RowVariant.current,
    };
    final subtitle = _subtitle(context, localizations, variant);
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingLarge,
        vertical: _verticalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flightTitle(localizations, flight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyEmphasis.copyWith(
                    color: variant.titleColor(palette),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: _titleGap),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.secondary.copyWith(
                      color: variant.subtitleColor(palette),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.cardPadding),
          Text(
            _accessory(localizations, context),
            style: AppTextStyles.accessory.copyWith(
              color: variant.accessoryColor(palette),
            ),
          ),
        ],
      ),
    );
    return switch (variant) {
      _RowVariant.planned => CustomPaint(
        painter: _DashedBorderPainter(color: palette.dashedBorder),
        child: content,
      ),
      _RowVariant.current || _RowVariant.past => DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: palette.border),
        ),
        child: content,
      ),
    };
  }

  String? _subtitle(
    BuildContext context,
    AppLocalizations localizations,
    _RowVariant variant,
  ) {
    final route = flightRouteLabel(localizations, flight.route);
    if (variant == _RowVariant.past) {
      final day = _departureDay(context, localizations);
      return route == null
          ? day
          : localizations.flightRowPastSubtitle(route, day);
    }
    final stateText = switch (state) {
      FlightState.waiting => localizations.flightRowWaitingForSignal,
      FlightState.planned => localizations.flightStatePlanned,
      FlightState.live => localizations.flightStateLive,
      FlightState.noSignal => localizations.flightStateNoSignal,
      FlightState.ended || FlightState.missed => localizations.flightStateEnded,
    };
    return route == null
        ? stateText
        : localizations.flightRowSubtitle(route, stateText);
  }

  String _departureDay(BuildContext context, AppLocalizations localizations) =>
      switch (relativeDayOf(flight.departureDate, now)) {
        RelativeDay.today => localizations.flightRowToday,
        RelativeDay.yesterday => localizations.flightRowYesterday,
        RelativeDay.earlier => _departureDate(context, localizations),
      };

  String _departureDate(BuildContext context, AppLocalizations localizations) =>
      DateFormat(
        localizations.listPlannedDateFormat,
        Localizations.localeOf(context).toLanguageTag(),
      ).format(
        DateTime(
          flight.departureDate.year,
          flight.departureDate.month,
          flight.departureDate.day,
        ),
      );

  String _accessory(AppLocalizations localizations, BuildContext context) =>
      switch (state) {
        FlightState.planned => _departureDate(context, localizations),
        FlightState.ended => localizations.flightRowLanded,
        FlightState.missed => localizations.flightRowMissed,
        FlightState.waiting => _waitingAccessory(localizations, context),
        FlightState.live ||
        FlightState.noSignal => localizations.flightRowToday,
      };

  String _waitingAccessory(
    AppLocalizations localizations,
    BuildContext context,
  ) {
    final departureTime = flight.departureTime;
    if (departureTime == null) {
      return localizations.flightRowToday;
    }
    return localizations.flightRowDepartureTime(
      formatDayTime(
        context,
        localizations.flightRowDepartureTimeFormat,
        departureTime,
      ),
    );
  }
}

enum _RowVariant {
  current,
  planned,
  past;

  Color titleColor(_RowPalette palette) => switch (this) {
    _RowVariant.current => palette.primaryText,
    _RowVariant.planned => palette.secondaryText,
    _RowVariant.past => palette.tertiaryText,
  };

  Color subtitleColor(_RowPalette palette) => switch (this) {
    _RowVariant.current => palette.secondaryText,
    _RowVariant.planned || _RowVariant.past => palette.tertiaryText,
  };

  Color accessoryColor(_RowPalette palette) => subtitleColor(palette);
}

enum _RowPalette {
  light(
    surface: AppColors.white,
    border: AppColors.neutral200,
    dashedBorder: AppColors.neutral300,
    primaryText: AppColors.neutral700,
    secondaryText: AppColors.neutral500,
    tertiaryText: AppColors.neutral400,
  ),
  dark(
    surface: AppColors.neutral800,
    border: AppColors.neutral700,
    dashedBorder: AppColors.neutral700,
    primaryText: AppColors.neutral300,
    secondaryText: AppColors.neutral400,
    tertiaryText: AppColors.neutral500,
  );

  const _RowPalette({
    required this.surface,
    required this.border,
    required this.dashedBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
  });

  final Color surface;
  final Color border;
  final Color dashedBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  static const _strokeWidth = 1.5;
  static const _dashLength = 3.0;
  static const _gapLength = 2.0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.card),
        ).deflate(_strokeWidth / 2),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    for (final metric in border.computeMetrics()) {
      for (
        var start = 0.0;
        start < metric.length;
        start += _dashLength + _gapLength
      ) {
        canvas.drawPath(
          metric.extractPath(start, min(start + _dashLength, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
