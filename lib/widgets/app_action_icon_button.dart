import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AppActionIconButton extends StatelessWidget {
  const AppActionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color = AppTheme.primary,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onTap == null ? 0.48 : 1,
        child: Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor(context).withValues(alpha: 0.82)),
            boxShadow: [AppTheme.themedSoftShadow(context, alpha: 0.045, blur: 14)],
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );

    if (tooltip == null || tooltip!.trim().isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
