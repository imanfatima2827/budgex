import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppScaledText extends StatelessWidget {
  const AppScaledText(
    this.data, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.minFontSize = 10,
    this.textAlign,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final int maxLines;
  final double minFontSize;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(style);
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0 || data.isEmpty) {
          return _text(effectiveStyle);
        }

        final baseFontSize =
            effectiveStyle.fontSize ?? defaultStyle.fontSize ?? 14;
        final smallestFontSize = math.min(minFontSize, baseFontSize);

        bool fits(double fontSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: data,
              style: effectiveStyle.copyWith(fontSize: fontSize),
            ),
            maxLines: maxLines,
            textAlign: textAlign ?? TextAlign.start,
            textDirection: direction,
            textScaler: textScaler,
          )..layout(maxWidth: maxWidth);

          return !painter.didExceedMaxLines && painter.width <= maxWidth + 0.5;
        }

        if (fits(baseFontSize)) return _text(effectiveStyle);

        var low = smallestFontSize;
        var high = baseFontSize;
        for (var i = 0; i < 9; i++) {
          final mid = (low + high) / 2;
          if (fits(mid)) {
            low = mid;
          } else {
            high = mid;
          }
        }

        return _text(effectiveStyle.copyWith(fontSize: low));
      },
    );
  }

  Widget _text(TextStyle effectiveStyle) {
    return Text(
      data,
      maxLines: maxLines,
      overflow: TextOverflow.clip,
      softWrap: softWrap ?? maxLines > 1,
      textAlign: textAlign,
      style: effectiveStyle,
    );
  }
}
