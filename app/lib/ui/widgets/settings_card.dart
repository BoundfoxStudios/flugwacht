import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

/// One card of the settings screen: an optional section title above whatever
/// the section puts inside it.
class SettingsCard extends StatelessWidget {
  const SettingsCard({required this.children, this.title, super.key});

  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const _gap = 12.0;

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _gap,
          children: [
            if (title case final title?)
              Text(
                title,
                style: AppTextStyles.sectionLabelLarge.copyWith(
                  color: theme.textTheme.labelSmall?.color,
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}
