import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: AppTheme.primary,
      onChanged: onChanged,
      style: TextStyle(
        color: AppTheme.titleColor(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppTheme.bodyColor(context),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
        prefixIconColor: AppTheme.primary,
        suffixIconColor: AppTheme.primary,
        border: _border(context, AppTheme.borderColor(context)),
        enabledBorder: _border(
          context,
          AppTheme.borderColor(context).withValues(alpha: 0.85),
        ),
        focusedBorder: _border(context, AppTheme.primary, width: 1.25),
      ),
    );
  }

  OutlineInputBorder _border(
    BuildContext context,
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
