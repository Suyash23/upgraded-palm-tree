import 'package:flutter/material.dart';

class MiniGridPainter extends CustomPainter {
  final bool isPlayable;
  final double progress; // For animation later, 0.0 to 1.0

  MiniGridPainter({this.isPlayable = false, this.progress = 1.0});

  // Reusable Paint object
  final Paint _gridPaint = Paint()
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    _gridPaint.color = isPlayable ? const Color(0xFFDAA520) : const Color(0xFF007bff); // Dark yellow or Blue

    if (progress == 0) return;

    double cellWidth = size.width / 3;
    double cellHeight = size.height / 3;

    // Vertical lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double x = cellWidth * i;
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 - (size.height / 2 * progress)),
          _gridPaint);
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 + (size.height / 2 * progress)),
          _gridPaint);
    }

    // Horizontal lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double y = cellHeight * i;
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 - (size.width / 2 * progress), y),
          _gridPaint);
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 + (size.width / 2 * progress), y),
          _gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniGridPainter oldDelegate) {
    return oldDelegate.isPlayable != isPlayable || oldDelegate.progress != progress;
  }
}
