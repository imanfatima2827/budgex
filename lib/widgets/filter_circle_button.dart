import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class FilterCircleButton extends StatelessWidget {
  const FilterCircleButton({
    super.key,
    required this.hasActiveFilters,
    required this.onTap,
  });

  final bool hasActiveFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasActiveFilters
              ? AppTheme.primary.withValues(alpha: 0.10)
              : AppTheme.surfaceColor(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: hasActiveFilters
                ? AppTheme.primary.withValues(alpha: 0.22)
                : AppTheme.borderColor(context),
          ),
          boxShadow: [AppTheme.softShadow(alpha: 0.035, blur: 10)],
        ),
        child: Icon(
          hasActiveFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          color: AppTheme.primary,
          size: 21,
        ),
      ),
    );
  }
}
