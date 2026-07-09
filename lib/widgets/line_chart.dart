import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class DailyLineChart extends StatelessWidget {
  const DailyLineChart({super.key, required this.dailyTotals});

  final Map<int, double> dailyTotals;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: CustomPaint(
        painter: DailyLineChartPainter(
          dailyTotals: dailyTotals,
          axisColor: AppTheme.borderColor(context).withValues(alpha: 0.72),
          dotBorderColor: AppTheme.surfaceColor(context),
        ),
      ),
    );
  }
}

class DailyLineChartPainter extends CustomPainter {
  DailyLineChartPainter({
    required this.dailyTotals,
    required this.axisColor,
    required this.dotBorderColor,
  });

  final Map<int, double> dailyTotals;
  final Color axisColor;
  final Color dotBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 0.8;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primary.withValues(alpha: 0.16),
          AppTheme.primary.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = AppTheme.primary;
    final dotBorderPaint = Paint()..color = dotBorderColor;

    final chartRect = Rect.fromLTWH(8, 12, size.width - 16, size.height - 28);
    for (int i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), axisPaint);
    }

    if (dailyTotals.isEmpty) return;

    final maxDay = dailyTotals.keys.reduce((a, b) => a > b ? a : b);
    final maxValue = dailyTotals.values.fold<double>(0, (max, value) => value > max ? value : max);
    if (maxValue <= 0) return;

    final points = dailyTotals.entries.map((entry) {
      final x = chartRect.left + (entry.key / math.max(maxDay, 1)) * chartRect.width;
      final y = chartRect.bottom - (entry.value / maxValue) * chartRect.height;
      return Offset(x, y);
    }).toList()
      ..sort((a, b) => a.dx.compareTo(b.dx));

    final path = _smoothPath(points);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
    for (final point in points) {
      canvas.drawCircle(point, 6, dotBorderPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path;

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant DailyLineChartPainter oldDelegate) =>
      oldDelegate.dailyTotals != dailyTotals ||
      oldDelegate.axisColor != axisColor ||
      oldDelegate.dotBorderColor != dotBorderColor;
}
