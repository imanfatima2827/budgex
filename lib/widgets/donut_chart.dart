import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/app_theme.dart';

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.data, this.size = 170, this.centerText});

  final Map<ExpenseCategory, double> data;
  final double size;
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: DonutChartPainter(
          data: data,
          trackColor: AppTheme.borderColor(context),
        ),
        child: Center(
          child: Text(
            centerText ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.titleColor(context),
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({required this.data, required this.trackColor});

  final Map<ExpenseCategory, double> data;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 14);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      paint.color = trackColor;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint);
      return;
    }

    var start = -math.pi / 2;
    const gap = 0.018;
    data.forEach((category, amount) {
      final sweep = (amount / total) * math.pi * 2;
      paint.color = category.color;
      canvas.drawArc(rect, start, math.max(0, sweep - gap), false, paint);
      start += sweep;
    });
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.trackColor != trackColor;
}
