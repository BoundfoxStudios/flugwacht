import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// The row of dots that tells how many flights the sheet pages through and
/// which one it shows. A single flight needs no dots.
class PagerDots extends StatelessWidget {
  const PagerDots({required this.count, required this.activeIndex, super.key});

  static const _dotSize = 6.0;
  static const _gap = 6.0;

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (count < 2) {
      return const SizedBox.shrink();
    }
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => (
        active: AppColors.neutral700,
        inactive: AppColors.neutral300,
      ),
      Brightness.dark => (
        active: AppColors.neutral300,
        inactive: AppColors.neutral600,
      ),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: _gap,
      children: [
        for (var index = 0; index < count; index++)
          SizedBox(
            width: _dotSize,
            height: _dotSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: index == activeIndex ? colors.active : colors.inactive,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
