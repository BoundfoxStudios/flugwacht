import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// The quiet panel the open sheet explains a missing signal in.
class SheetInfoBox extends StatelessWidget {
  const SheetInfoBox({required this.text, super.key});

  static const _padding = EdgeInsets.symmetric(vertical: 10, horizontal: 12);
  static const _lineHeight = 1.5;

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _InfoBoxColors.light,
      Brightness.dark => _InfoBoxColors.dark,
    };
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.secondary.copyWith(
          color: colors.text,
          height: _lineHeight,
        ),
      ),
    );
  }
}

enum _InfoBoxColors {
  light(
    surface: AppColors.neutral50,
    border: AppColors.neutral200,
    text: AppColors.neutral500,
  ),
  dark(
    surface: AppColors.neutral900,
    border: AppColors.neutral700,
    text: AppColors.neutral400,
  );

  const _InfoBoxColors({
    required this.surface,
    required this.border,
    required this.text,
  });

  final Color surface;
  final Color border;
  final Color text;
}
