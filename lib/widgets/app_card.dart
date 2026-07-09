import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.showBorder = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool showBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final borderColor = AppTheme.borderColor(
      context,
    ).withValues(alpha: isDark ? 1 : 0.72);
    final radius = BorderRadius.circular(borderRadius);
    final borderSide = BorderSide(
      color: showBorder ? AppTheme.borderColor(context) : borderColor,
      width: isDark ? 1 : 0.8,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: borderSide,
    );
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          AppTheme.themedSoftShadow(
            context,
            alpha: isDark ? 0.035 : 0.045,
            blur: isDark ? 14 : 18,
          ),
        ],
      ),
      child: Material(
        color: AppTheme.surfaceColor(context),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
  }
}
