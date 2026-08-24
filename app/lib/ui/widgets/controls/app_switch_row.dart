import 'package:material_ui/material_ui.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// A labelled switch in the app's own look, tall enough to be a comfortable
/// hit target.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    required this.label,
    required this.isEnabled,
    required this.onToggled,
    super.key,
  });

  static const _rowHeight = 44.0;
  static const _trackSize = Size(40, 24);
  static const _knobSize = 20.0;
  static const _knobInset = 2.0;
  static const _duration = Duration(milliseconds: 180);

  final String label;
  final bool isEnabled;
  final ValueChanged<bool> onToggled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _SwitchColors.light,
      Brightness.dark => _SwitchColors.dark,
    };
    return Semantics(
      toggled: isEnabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggled(!isEnabled),
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: isEnabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: _duration,
                curve: Curves.easeInOut,
                width: _trackSize.width,
                height: _trackSize.height,
                padding: const EdgeInsets.all(_knobInset),
                alignment: isEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: isEnabled ? AppColors.amber : colors.track,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: SizedBox.square(
                  dimension: _knobSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEnabled ? AppColors.neutral800 : colors.knob,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SwitchColors {
  light(track: AppColors.neutral300, knob: AppColors.white),
  dark(track: AppColors.neutral600, knob: AppColors.neutral400);

  const _SwitchColors({required this.track, required this.knob});

  final Color track;
  final Color knob;
}
