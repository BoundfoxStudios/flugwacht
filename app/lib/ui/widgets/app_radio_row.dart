import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

/// One option of a settings radio list, tall enough to be a comfortable hit
/// target even though the ring itself is small.
class AppRadioRow extends StatelessWidget {
  const AppRadioRow({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  static const _rowHeight = 44.0;
  static const _ringSize = 18.0;
  static const _ringWidth = 2.0;
  static const _dotSize = 8.0;
  static const _gap = 10.0;

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringColor = isSelected
        ? AppColors.amber
        : switch (Theme.of(context).brightness) {
            Brightness.light => AppColors.neutral300,
            Brightness.dark => AppColors.neutral600,
          };
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelected,
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            spacing: _gap,
            children: [
              Container(
                width: _ringSize,
                height: _ringSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: _ringWidth),
                ),
                child: isSelected
                    ? const SizedBox.square(
                        dimension: _dotSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.amber,
                          ),
                        ),
                      )
                    : null,
              ),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
