import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  static const _height = 52.0;
  static const _disabledOpacity = 0.4;

  final String label;

  /// A null callback renders the button disabled.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.amber
                : AppColors.amber.withValues(alpha: _disabledOpacity),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: -3,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              color: isEnabled
                  ? AppColors.neutral900
                  : AppColors.neutral900.withValues(alpha: _disabledOpacity),
            ),
          ),
        ),
      ),
    );
  }
}
