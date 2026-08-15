import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../domain/flight.dart';
import '../../domain/flight_state.dart';
import '../../domain/trail_point.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'flight_labels.dart';
import 'flight_state_badge.dart';
import 'mini_map.dart';
import 'state_timeline.dart';

/// The cell of an airborne flight: mini map with its state badge, the title
/// line and the compact state timeline. The arrival block is M9.
class FlightHeroCell extends StatefulWidget {
  const FlightHeroCell({
    required this.flight,
    required this.state,
    required this.trail,
    super.key,
    this.onTap,
    this.tileProvider,
  });

  static const _mapHeight = 150.0;
  static const _badgeInset = 10.0;
  static const _blockGap = 6.0;
  static const _borderWidth = 1.0;

  final Flight flight;
  final FlightState state;
  final List<TrailPoint> trail;

  /// Opens the flight on the map; without it the cell is not interactive.
  final VoidCallback? onTap;

  /// Handed to the mini map so tests render without loading tiles.
  final TileProvider? tileProvider;

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
                        tileProvider: widget.tileProvider,
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
                    const SizedBox(height: FlightHeroCell._blockGap),
                    StateTimeline(
                      state: state,
                      variant: StateTimelineVariant.compact,
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

enum _HeroColors {
  light(
    surface: AppColors.white,
    border: AppColors.neutral200,
    title: AppColors.neutral800,
    route: AppColors.neutral500,
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
    shadow: null,
  );

  const _HeroColors({
    required this.surface,
    required this.border,
    required this.title,
    required this.route,
    required this.shadow,
  });

  final Color surface;
  final Color border;
  final Color title;
  final Color route;
  final List<BoxShadow>? shadow;
}
