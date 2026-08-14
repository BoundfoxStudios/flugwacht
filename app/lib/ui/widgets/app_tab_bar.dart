import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.labels,
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  static const height = 76.0;

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _TabBarColors.light,
      Brightness.dark => _TabBarColors.dark,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (final (index, label) in labels.indexed)
                Expanded(
                  child: _TabItem(
                    label: label,
                    isActive: index == currentIndex,
                    colors: colors,
                    onSelected: () => onTabSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TabBarColors {
  light(
    background: AppColors.white,
    border: AppColors.neutral200,
    active: AppColors.neutral800,
    activePressed: AppColors.neutral900,
    inactive: AppColors.neutral400,
    inactivePressed: AppColors.neutral500,
  ),
  dark(
    background: AppColors.neutral900,
    border: AppColors.neutral700,
    active: AppColors.neutral50,
    activePressed: AppColors.neutral100,
    inactive: AppColors.neutral500,
    inactivePressed: AppColors.neutral600,
  );

  const _TabBarColors({
    required this.background,
    required this.border,
    required this.active,
    required this.activePressed,
    required this.inactive,
    required this.inactivePressed,
  });

  final Color background;
  final Color border;
  final Color active;
  final Color activePressed;
  final Color inactive;
  final Color inactivePressed;
}

class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onSelected,
  });

  final String label;
  final bool isActive;
  final _TabBarColors colors;
  final VoidCallback onSelected;

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final labelColor = switch ((widget.isActive, _isPressed)) {
      (true, false) => widget.colors.active,
      (true, true) => widget.colors.activePressed,
      (false, false) => widget.colors.inactive,
      (false, true) => widget.colors.inactivePressed,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onSelected,
      child: Semantics(
        button: true,
        selected: widget.isActive,
        child: Transform.translate(
          offset: _isPressed ? const Offset(0, 1) : Offset.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  widget.label,
                  style: AppTextStyles.tabLabel.copyWith(color: labelColor),
                ),
              ),
              if (widget.isActive)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 24,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
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
