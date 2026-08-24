import 'package:material_ui/material_ui.dart';

import '../../../data/settings/map_style_setting.dart';
import '../../../domain/flight.dart';
import '../../../domain/flight_state.dart';
import '../../../domain/trail_point.dart';
import '../../../l10n/app_localizations.g.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../map/map_visuals.dart';
import '../map/mini_map.dart';
import 'flight_labels.dart';
import 'flight_state_badge.dart';
import 'live_activity_arm_row.dart';
import 'state_timeline.dart';

/// The cell of an airborne flight: mini map with its state badge, the title
/// line, the arrival and the compact state timeline.
class FlightHeroCell extends StatefulWidget {
  const FlightHeroCell({
    required this.flight,
    required this.state,
    required this.trail,
    required this.now,
    required this.mapStyleSetting,
    required this.tileSources,
    super.key,
    this.onTap,
    this.liveActivity,
  });

  static const _mapHeight = 150.0;
  static const _badgeInset = 10.0;
  static const _blockGap = 6.0;
  static const _borderWidth = 1.0;
  static const _arrivalGap = 10.0;
  static const _timeHeight = 0.95;

  final Flight flight;
  final FlightState state;
  final List<TrailPoint> trail;

  /// Ages the remaining flight time; the list hands its minute clock down.
  final DateTime now;

  /// Opens the flight on the map; without it the cell is not interactive.
  final VoidCallback? onTap;

  /// Offers the flight's Lock Screen switch under the cell's content.
  final FlightLiveActivityControl? liveActivity;

  /// Handed to the mini map.
  final MapStyleSetting mapStyleSetting;
  final MapTileSources tileSources;

  @override
  State<FlightHeroCell> createState() => _FlightHeroCellState();
}

class _FlightHeroCellState extends State<FlightHeroCell> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    final onTap = widget.onTap;
    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: onTap,
      child: Semantics(
        button: true,
        child: Transform.translate(
          offset: _isPressed ? const Offset(0, 1) : Offset.zero,
          child: card,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final flight = widget.flight;
    final state = widget.state;
    final localizations = AppLocalizations.of(context);
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _HeroColors.light,
      Brightness.dark => _HeroColors.dark,
    };
    final position = flight.tracking.latestPosition;
    final route = flight.route;
    final arrival = arrivalDisplayOf(
      context,
      flight: flight,
      state: state,
      now: widget.now,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.border,
          width: FlightHeroCell._borderWidth,
        ),
        boxShadow: colors.shadow,
      ),
      // Insets the clipped content so the opaque mini map stops at the border
      // instead of painting over it.
      child: Padding(
        padding: const EdgeInsets.all(FlightHeroCell._borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppRadius.card - FlightHeroCell._borderWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (position != null)
                SizedBox(
                  height: FlightHeroCell._mapHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MiniMap(
                        position: position,
                        route: route,
                        trail: widget.trail,
                        state: state,
                        mapStyleSetting: widget.mapStyleSetting,
                        tileSources: widget.tileSources,
                      ),
                      Positioned(
                        top: FlightHeroCell._badgeInset,
                        left: FlightHeroCell._badgeInset,
                        child: FlightStateBadge(state: state),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.cardPaddingLarge,
                  AppSpacing.cardPadding,
                  AppSpacing.cardPaddingLarge,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            flightTitle(localizations, flight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLargeEmphasis.copyWith(
                              color: colors.title,
                            ),
                          ),
                        ),
                        if (route != null) ...[
                          const SizedBox(width: AppSpacing.cardPadding),
                          Text(
                            flightRouteLabel(localizations, route)!,
                            style: AppTextStyles.secondary.copyWith(
                              color: colors.route,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (arrival != null) ...[
                      const SizedBox(height: FlightHeroCell._blockGap),
                      _ArrivalRow(arrival: arrival, colors: colors),
                    ],
                    const SizedBox(height: FlightHeroCell._blockGap),
                    StateTimeline(
                      state: state,
                      variant: StateTimelineVariant.compact,
                    ),
                    if (widget.liveActivity case final liveActivity?)
                      LiveActivityArmRow(
                        availability: liveActivity.availability,
                        isArmed: flight.liveActivityArmed,
                        onToggled: liveActivity.onArmed,
                        separator: _Hairline(color: colors.border),
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

/// Sets the Lock Screen switch off from the flight's own numbers above it.
class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: FlightHeroCell._blockGap),
    child: SizedBox(
      height: FlightHeroCell._borderWidth,
      child: ColoredBox(color: color),
    ),
  );
}

class _ArrivalRow extends StatelessWidget {
  const _ArrivalRow({required this.arrival, required this.colors});

  final ArrivalDisplay arrival;
  final _HeroColors colors;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    spacing: FlightHeroCell._arrivalGap,
    children: [
      Text(
        arrival.time,
        style: AppTextStyles.timeMedium.copyWith(
          color: colors.time,
          height: FlightHeroCell._timeHeight,
        ),
      ),
      Expanded(
        child: Text(
          AppLocalizations.of(
            context,
          ).flightArrivalSummary(arrival.label, arrival.detail),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.accessory.copyWith(color: colors.arrivalDetail),
        ),
      ),
    ],
  );
}

enum _HeroColors {
  light(
    surface: AppColors.white,
    border: AppColors.neutral200,
    title: AppColors.neutral800,
    route: AppColors.neutral500,
    time: AppColors.neutral900,
    shadow: [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 6,
        spreadRadius: -1,
        offset: Offset(0, 4),
      ),
    ],
  ),
  dark(
    surface: AppColors.neutral800,
    border: AppColors.neutral700,
    title: AppColors.neutral50,
    route: AppColors.neutral400,
    time: AppColors.white,
    shadow: null,
  );

  const _HeroColors({
    required this.surface,
    required this.border,
    required this.title,
    required this.route,
    required this.time,
    required this.shadow,
  });

  final Color surface;
  final Color border;
  final Color title;
  final Color route;
  final Color time;
  final List<BoxShadow>? shadow;

  Color get arrivalDetail => route;
}
