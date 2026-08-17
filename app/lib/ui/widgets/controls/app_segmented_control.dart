import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const _segmentHeight = 42.0;
  static const _trackPadding = 3.0;

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _SegmentedControlColors.light,
      Brightness.dark => _SegmentedControlColors.dark,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_trackPadding),
        child: Row(
          children: [
            for (final segment in segments.entries)
              Expanded(
                child: _Segment(
                  label: segment.value,
                  isSelected: segment.key == selected,
                  colors: colors,
                  onSelected: () => onSelected(segment.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final _SegmentedControlColors colors;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: isSelected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelected,
      child: Container(
        height: AppSegmentedControl._segmentHeight,
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(
                color: colors.selected,
                borderRadius: BorderRadius.circular(AppRadius.field - 2),
                border: Border.all(color: colors.selectedBorder),
              )
            : null,
        child: Text(
          label,
          style: AppTextStyles.secondaryEmphasis.copyWith(
            color: isSelected ? colors.selectedLabel : colors.label,
          ),
        ),
      ),
    ),
  );
}

enum _SegmentedControlColors {
  light(
    track: AppColors.neutral100,
    selected: AppColors.white,
    selectedBorder: AppColors.neutral200,
    selectedLabel: AppColors.neutral900,
    label: AppColors.neutral500,
  ),
  dark(
    track: AppColors.neutral800,
    selected: AppColors.neutral700,
    selectedBorder: AppColors.neutral600,
    selectedLabel: AppColors.neutral50,
    label: AppColors.neutral400,
  );

  const _SegmentedControlColors({
    required this.track,
    required this.selected,
    required this.selectedBorder,
    required this.selectedLabel,
    required this.label,
  });

  final Color track;
  final Color selected;
  final Color selectedBorder;
  final Color selectedLabel;
  final Color label;
}
