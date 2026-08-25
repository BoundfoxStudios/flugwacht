import 'package:material_ui/material_ui.dart';

import '../../domain/flight_route.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/controls/app_radio_row.dart';
import 'new_flight_preview.dart';

class NewFlightPreviewCard extends StatelessWidget {
  const NewFlightPreviewCard({
    required this.state,
    required this.onLegChosen,
    this.airlineName,
    super.key,
  });

  final FlightPreviewState state;
  final ValueChanged<FlightRoute> onLegChosen;
  final String? airlineName;

  @override
  Widget build(BuildContext context) {
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _PreviewCardColors.light,
      Brightness.dark => _PreviewCardColors.dark,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: switch (state) {
        FlightPreviewFound(:final callsign, :final route) => _FoundContent(
          callsign: callsign,
          route: route,
          airlineName: airlineName,
          colors: colors,
        ),
        FlightPreviewLegChoice(:final legs) => _LegChoiceContent(
          legs: legs,
          onLegChosen: onLegChosen,
          colors: colors,
        ),
        FlightPreviewSearching() => _SearchingContent(colors: colors),
        FlightPreviewRouteUnknown() || FlightPreviewHidden() => Text(
          AppLocalizations.of(context).newFlightPreviewRouteUnknown,
          style: AppTextStyles.body.copyWith(color: colors.subtitle),
        ),
      },
    );
  }
}

class _SearchingContent extends StatelessWidget {
  const _SearchingContent({required this.colors});

  final _PreviewCardColors colors;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppSpacing.cardPadding,
    children: [
      Expanded(
        child: Text(
          AppLocalizations.of(context).newFlightPreviewSearching,
          style: AppTextStyles.body.copyWith(color: colors.subtitle),
        ),
      ),
      SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.subtitle,
        ),
      ),
    ],
  );
}

class _LegChoiceContent extends StatelessWidget {
  const _LegChoiceContent({
    required this.legs,
    required this.onLegChosen,
    required this.colors,
  });

  final List<FlightRoute> legs;
  final ValueChanged<FlightRoute> onLegChosen;
  final _PreviewCardColors colors;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.newFlightPreviewChooseLeg,
          style: AppTextStyles.sectionLabelMedium.copyWith(color: colors.label),
        ),
        const SizedBox(height: AppSpacing.grid),
        Text(
          localizations.newFlightPreviewChooseLegHint,
          style: AppTextStyles.secondary.copyWith(color: colors.subtitle),
        ),
        const SizedBox(height: AppSpacing.grid),
        for (final leg in legs)
          AppRadioRow(
            label: localizations.newFlightPreviewRoute(
              leg.origin.name,
              leg.destination.name,
            ),
            isSelected: false,
            onSelected: () => onLegChosen(leg),
          ),
      ],
    );
  }
}

class _FoundContent extends StatelessWidget {
  const _FoundContent({
    required this.callsign,
    required this.route,
    required this.airlineName,
    required this.colors,
  });

  final String callsign;
  final FlightRoute route;
  final String? airlineName;
  final _PreviewCardColors colors;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final airlineName = this.airlineName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.newFlightPreviewFound,
          style: AppTextStyles.sectionLabelMedium.copyWith(color: colors.label),
        ),
        const SizedBox(height: AppSpacing.grid * 2),
        Row(
          children: [
            Expanded(
              child: Text(
                localizations.newFlightPreviewRoute(
                  _airportCode(route.origin),
                  _airportCode(route.destination),
                ),
                style: AppTextStyles.bodyLargeEmphasis.copyWith(
                  color: colors.route,
                ),
              ),
            ),
            _CallsignPill(
              label: localizations.newFlightPreviewCallsign(callsign),
              colors: colors,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.grid),
        Text(
          airlineName == null
              ? localizations.newFlightPreviewRoute(
                  route.origin.name,
                  route.destination.name,
                )
              : localizations.newFlightPreviewRouteWithAirline(
                  route.origin.name,
                  route.destination.name,
                  airlineName,
                ),
          style: AppTextStyles.secondary.copyWith(color: colors.subtitle),
        ),
      ],
    );
  }

  String _airportCode(RouteAirport airport) =>
      airport.iataCode ?? airport.icaoCode;
}

class _CallsignPill extends StatelessWidget {
  const _CallsignPill({required this.label, required this.colors});

  final String label;
  final _PreviewCardColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.cardPadding,
      vertical: AppSpacing.grid + 2,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: colors.pillBorder),
    ),
    child: Text(
      label,
      style: AppTextStyles.sectionLabelSmall.copyWith(color: colors.route),
    ),
  );
}

enum _PreviewCardColors {
  light(
    background: AppColors.neutral50,
    border: AppColors.neutral200,
    pillBorder: AppColors.neutral300,
    label: AppColors.neutral400,
    route: AppColors.neutral900,
    subtitle: AppColors.neutral500,
  ),
  dark(
    background: AppColors.neutral800,
    border: AppColors.neutral700,
    pillBorder: AppColors.neutral600,
    label: AppColors.neutral500,
    route: AppColors.neutral50,
    subtitle: AppColors.neutral400,
  );

  const _PreviewCardColors({
    required this.background,
    required this.border,
    required this.pillBorder,
    required this.label,
    required this.route,
    required this.subtitle,
  });

  final Color background;
  final Color border;
  final Color pillBorder;
  final Color label;
  final Color route;
  final Color subtitle;
}
