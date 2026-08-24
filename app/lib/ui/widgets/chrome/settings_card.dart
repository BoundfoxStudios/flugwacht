import 'package:material_ui/material_ui.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// One card of the settings screen: an optional section title above whatever
/// the section puts inside it. With [onTap] the whole card becomes the tap
/// target and answers a press without a ripple.
class SettingsCard extends StatefulWidget {
  const SettingsCard({
    required this.children,
    this.title,
    this.hint,
    this.onTap,
    super.key,
  });

  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const _gap = 12.0;

  final List<Widget> children;
  final String? title;
  final String? hint;
  final VoidCallback? onTap;

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.title;
    final hint = widget.hint;
    final card = Column(
      crossAxisAlignment: .start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _isPressed
                ? theme.colorScheme.surfaceContainerLow
                : theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Padding(
            padding: SettingsCard._padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SettingsCard._gap,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: AppTextStyles.sectionLabelLarge.copyWith(
                      color: theme.textTheme.labelSmall?.color,
                    ),
                  ),
                ...widget.children,
              ],
            ),
          ),
        ),
        if (hint != null)
          Padding(
            padding: EdgeInsetsGeometry.only(
              left: SettingsCard._padding.left,
              right: SettingsCard._padding.right,
            ),
            child: Text(
              hint,
              style: AppTextStyles.small.copyWith(color: AppColors.neutral400),
            ),
          ),
      ],
    );
    final onTap = widget.onTap;
    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
}
