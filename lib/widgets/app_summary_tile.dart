import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'app_card.dart';
import 'app_icon_bubble.dart';
import 'app_scaled_text.dart';

class AppSummaryTile extends StatelessWidget {
  const AppSummaryTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppTheme.primary,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconBubble(
            icon: icon,
            color: color,
            size: 40,
            iconSize: 20,
            borderRadius: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppScaledText(
                  label,
                  minFontSize: 8,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AppScaledText(
                  value,
                  minFontSize: 10,
                  style: TextStyle(
                    color: AppTheme.titleColor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
