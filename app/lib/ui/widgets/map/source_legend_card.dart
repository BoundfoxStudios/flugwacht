import 'package:flutter/material.dart';

import '../../../domain/source_id.dart';
import '../../../l10n/app_localizations.g.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import 'map_visuals.dart';

/// Names the trail color of every source on the map while a trail compares
/// several of them.
class SourceLegendCard extends StatelessWidget {
  const SourceLegendCard({
    required this.trailSourceIds,
    required this.activeId,
    super.key,
  });

  static const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const _rowGap = 6.0;
  static const _swatchGap = 7.0;
  static const _swatchSize = Size(14, 3);
  static const _swatchRadius = 2.0;

  final Set<SourceId> trailSourceIds;
  final SourceId activeId;

  @override
  Widget build(BuildContext context) {
    final colors = _LegendColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: colors.shadow == null ? null : [colors.shadow!],
      ),
      child: Padding(
        padding: _padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _rowGap,
          children: [
            Text(
              AppLocalizations.of(context).mapLegendTitle,
              style: AppTextStyles.sectionLabelSmall.copyWith(
                color: colors.title,
              ),
            ),
            for (final sourceId in SourceId.values)
              if (trailSourceIds.contains(sourceId) || sourceId == activeId)
                _LegendRow(
                  sourceId: sourceId,
                  colors: colors,
                  isActive: sourceId == activeId,
                ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.sourceId,
    required this.colors,
    required this.isActive,
  });

  final SourceId sourceId;
  final _LegendColors colors;
  final bool isActive;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: SourceLegendCard._swatchGap,
    children: [
      SizedBox.fromSize(
        size: SourceLegendCard._swatchSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MapColors.of(context).trailOf(sourceId),
            borderRadius: BorderRadius.circular(SourceLegendCard._swatchRadius),
          ),
        ),
      ),
      Text(
        sourceId.label,
        style: (isActive ? AppTextStyles.smallEmphasis : AppTextStyles.small)
            .copyWith(color: isActive ? colors.activeName : colors.name),
      ),
      if (isActive)
        Text(
          AppLocalizations.of(context).mapLegendActive,
          style: AppTextStyles.caption.copyWith(color: colors.title),
        ),
    ],
  );
}

enum _LegendColors {
  light(
    surface: AppColors.white,
    border: AppColors.neutral200,
    title: AppColors.neutral400,
    name: AppColors.neutral500,
    activeName: AppColors.neutral700,
    shadow: BoxShadow(
      color: Color(0x12000000),
      blurRadius: 6,
      spreadRadius: -1,
      offset: Offset(0, 4),
    ),
  ),
  dark(
    surface: AppColors.neutral800,
    border: AppColors.neutral700,
    title: AppColors.neutral500,
    name: AppColors.neutral300,
    activeName: AppColors.neutral50,
  );

  const _LegendColors({
    required this.surface,
    required this.border,
    required this.title,
    required this.name,
    required this.activeName,
    this.shadow,
  });

  static _LegendColors of(BuildContext context) =>
      switch (Theme.of(context).brightness) {
        Brightness.light => _LegendColors.light,
        Brightness.dark => _LegendColors.dark,
      };

  final Color surface;
  final Color border;
  final Color title;
  final Color name;
  final Color activeName;
  final BoxShadow? shadow;
}
