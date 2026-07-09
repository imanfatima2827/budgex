import 'package:flutter/material.dart';

class SpendingInsight {
  const SpendingInsight({
    required this.title,
    required this.message,
    required this.icon,
    this.isWarning = false,
    this.isPositive = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool isWarning;
  final bool isPositive;
}
