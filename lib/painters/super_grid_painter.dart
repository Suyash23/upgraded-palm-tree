import 'package:flutter/material.dart';

class SuperGridPainter extends CustomPainter {
  final double progress; // For animation later, 0.0 to 1.0

  SuperGridPainter({this.progress = 1.0});

  // Static final Paint object as its properties are constant
  static final Paint _superGridPaint = Paint()
    ..color = const Color(0xFF333333) // Dark grey
    ..strokeWidth = 6.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return; // Nothing to draw if progress is 0

    double cellWidth = size.width / 3;
    double cellHeight = size.height / 3;

    // Vertical lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double x = cellWidth * i;
      // Line 1: from center point (x, size.height / 2) upwards
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 - (size.height / 2 * progress)),
          _superGridPaint);
      // Line 2: from center point (x, size.height / 2) downwards
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 + (size.height / 2 * progress)),
          _superGridPaint);
    }

    // Horizontal lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double y = cellHeight * i;
      // Line 1: from center point (size.width / 2, y) leftwards
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 - (size.width / 2 * progress), y),
          _superGridPaint);
      // Line 2: from center point (size.width / 2, y) rightwards
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 + (size.width / 2 * progress), y),
          _superGridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SuperGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
