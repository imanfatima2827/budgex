import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AppIconBubble extends StatelessWidget {
  const AppIconBubble({
    super.key,
    required this.icon,
    this.color = AppTheme.primary,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 16,
    this.shape = BoxShape.rectangle,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.11),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
