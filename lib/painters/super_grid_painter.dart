import 'package:flutter/material.dart';

class SuperGridPainter extends CustomPainter {
  final double progress; // For animation later, 0.0 to 1.0
  final Color gridColor;

  SuperGridPainter({this.progress = 1.0, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor // New logic
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Optional: for smoother ends if desired

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
          paint);
      // Line 2: from center point (x, size.height / 2) downwards
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 + (size.height / 2 * progress)),
          paint);
    }

    // Horizontal lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double y = cellHeight * i;
      // Line 1: from center point (size.width / 2, y) leftwards
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 - (size.width / 2 * progress), y),
          paint);
      // Line 2: from center point (size.width / 2, y) rightwards
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 + (size.width / 2 * progress), y),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant SuperGridPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.gridColor != gridColor;
  }
}
