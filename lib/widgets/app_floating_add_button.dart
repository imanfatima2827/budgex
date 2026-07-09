import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AppFloatingAddButton extends StatefulWidget {
  const AppFloatingAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  State<AppFloatingAddButton> createState() => _AppFloatingAddButtonState();
}

class _AppFloatingAddButtonState extends State<AppFloatingAddButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.84, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, entryScale, child) {
          return Transform.scale(scale: entryScale, child: child);
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              child: Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(
                        alpha: AppTheme.isDark(context) ? 0.30 : 0.24,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: _isPressed ? 0.08 : 0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
