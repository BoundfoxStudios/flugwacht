import 'package:flutter/material.dart';

import '../../domain/flight_state.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

enum StateTimelineVariant {
  labeled(dotSize: 10, currentDotSize: 16, ringWidth: 3, showsLabels: true),
  compact(dotSize: 8, currentDotSize: 13, ringWidth: 2.5, showsLabels: false);

  const StateTimelineVariant({
    required this.dotSize,
    required this.currentDotSize,
    required this.ringWidth,
    required this.showsLabels,
  });

  final double dotSize;
  final double currentDotSize;
  final double ringWidth;
  final bool showsLabels;
}

/// The flight states from planned to ended as a row of dots, the current one
/// marked. The no-signal dot exists only while that state is current;
/// [FlightState.missed] has no dot at all.
class StateTimeline extends StatelessWidget {
  const StateTimeline({required this.state, required this.variant, super.key})
    : assert(
        state != FlightState.missed,
        'A missed flight never reaches the timeline',
      );

  static const _connectorHeight = 2.0;
  static const _upcomingBorderWidth = 2.0;
  static const _labelGap = AppSpacing.grid * 2;
  static const _maximumLabelTextScale = 1.3;

  final FlightState state;
  final StateTimelineVariant variant;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _TimelineColors.light,
      Brightness.dark => _TimelineColors.dark,
    };
    final current = state == FlightState.missed ? FlightState.ended : state;
    final steps = [
      FlightState.planned,
      FlightState.waiting,
      FlightState.live,
      if (current == FlightState.noSignal) FlightState.noSignal,
      FlightState.ended,
    ];
    final currentIndex = steps.indexOf(current);
    return Semantics(
      container: true,
      label: _stateLabel(localizations, current),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  if (index > 0)
                    Expanded(
                      child: SizedBox(
                        height: _connectorHeight,
                        child: ColoredBox(
                          color: index <= currentIndex
                              ? colors.done
                              : colors.upcoming,
                        ),
                      ),
                    ),
                  _TimelineDot(
                    step: steps[index],
                    position: switch (index - currentIndex) {
                      < 0 => _DotPosition.done,
                      0 => _DotPosition.current,
                      _ => _DotPosition.upcoming,
                    },
                    variant: variant,
                    colors: colors,
                  ),
                ],
              ],
            ),
            if (variant.showsLabels) ...[
              const SizedBox(height: _labelGap),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: _maximumLabelTextScale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var index = 0; index < steps.length; index++)
                      Text(
                        _stateLabel(localizations, steps[index]),
                        style: AppTextStyles.caption.copyWith(
                          color: index == currentIndex
                              ? colors.activeLabelFor(current)
                              : colors.label,
                          fontWeight: index == currentIndex
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _stateLabel(AppLocalizations localizations, FlightState state) =>
    switch (state) {
      FlightState.planned => localizations.flightStatePlanned,
      FlightState.waiting => localizations.flightStateWaiting,
      FlightState.live => localizations.flightStateLive,
      FlightState.noSignal => localizations.flightStateNoSignal,
      FlightState.ended || FlightState.missed => localizations.flightStateEnded,
    };

enum _DotPosition { done, current, upcoming }

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.step,
    required this.position,
    required this.variant,
    required this.colors,
  });

  final FlightState step;
  final _DotPosition position;
  final StateTimelineVariant variant;
  final _TimelineColors colors;

  @override
  Widget build(BuildContext context) {
    final size = position == _DotPosition.current
        ? variant.currentDotSize
        : variant.dotSize;
    final (fill, border) = switch (position) {
      _DotPosition.done => (colors.done, null),
      _DotPosition.current when step == FlightState.noSignal => (
        colors.surface,
        Border.all(color: colors.noSignalRing, width: variant.ringWidth),
      ),
      _DotPosition.current => (
        AppColors.amber,
        Border.all(color: colors.currentRing, width: variant.ringWidth),
      ),
      _DotPosition.upcoming => (
        colors.surface,
        Border.all(
          color: colors.upcomingBorder,
          width: StateTimeline._upcomingBorderWidth,
        ),
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border,
      ),
    );
  }
}

enum _TimelineColors {
  light(
    done: AppColors.neutral700,
    upcoming: AppColors.neutral200,
    upcomingBorder: AppColors.neutral300,
    surface: AppColors.white,
    currentRing: AppColors.neutral800,
    noSignalRing: AppColors.neutral700,
    label: AppColors.neutral400,
    activeLabel: AppColors.neutral800,
    noSignalActiveLabel: AppColors.neutral800,
  ),
  dark(
    done: AppColors.neutral300,
    upcoming: AppColors.neutral700,
    upcomingBorder: AppColors.neutral600,
    surface: AppColors.neutral800,
    currentRing: AppColors.neutral50,
    noSignalRing: AppColors.neutral300,
    label: AppColors.neutral500,
    activeLabel: AppColors.amber,
    noSignalActiveLabel: AppColors.neutral50,
  );

  const _TimelineColors({
    required this.done,
    required this.upcoming,
    required this.upcomingBorder,
    required this.surface,
    required this.currentRing,
    required this.noSignalRing,
    required this.label,
    required this.activeLabel,
    required this.noSignalActiveLabel,
  });

  final Color done;
  final Color upcoming;
  final Color upcomingBorder;
  final Color surface;
  final Color currentRing;
  final Color noSignalRing;
  final Color label;
  final Color activeLabel;
  final Color noSignalActiveLabel;

  Color activeLabelFor(FlightState state) =>
      state == FlightState.noSignal ? noSignalActiveLabel : activeLabel;
}
