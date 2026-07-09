import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class FinanceInfoChip extends StatelessWidget {
  const FinanceInfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.maxWidth = 150,
    this.minHeight = 28,
    this.iconColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    this.fontSize = 11,
  });

  final IconData icon;
  final String label;
  final double maxWidth;
  final double minHeight;
  final Color? iconColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final displayLabel = label.trim();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, minHeight: minHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.softSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor(context).withValues(alpha: 0.62),
          ),
        ),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor ?? AppTheme.primary, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  displayLabel.isEmpty ? '-' : displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
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
