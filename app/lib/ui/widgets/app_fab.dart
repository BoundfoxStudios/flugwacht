import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_icons.dart';
import '../theme/app_tokens.dart';

class AppFab extends StatefulWidget {
  const AppFab({required this.onPressed, super.key});

  static const size = 56.0;

  final VoidCallback onPressed;

  @override
  State<AppFab> createState() => _AppFabState();
}

class _AppFabState extends State<AppFab> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final (glowOpacity, dropOpacity) = switch (Theme.of(context).brightness) {
      Brightness.light => (0.4, 0.1),
      Brightness.dark => (0.25, 0.4),
    };
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: Semantics(
        button: true,
        child: Transform.translate(
          offset: _isPressed ? const Offset(0, 1) : Offset.zero,
          child: Container(
            width: AppFab.size,
            height: AppFab.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isPressed ? AppColors.orange : AppColors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: glowOpacity),
                  blurRadius: 15,
                  spreadRadius: -3,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dropOpacity),
                  blurRadius: 6,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const FaIcon(
              AppIcons.plus,
              size: 24,
              color: AppColors.neutral800,
            ),
          ),
        ),
      ),
    );
  }
}
