import 'package:flutter/material.dart';

class MiniGridPainter extends CustomPainter {
  final bool isPlayable;
  final double progress; // For animation later, 0.0 to 1.0
  final Color gridColor;
  final Color activeGridColor;

  MiniGridPainter({
    this.isPlayable = false,
    this.progress = 1.0,
    required this.gridColor,
    required this.activeGridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPlayable ? activeGridColor : gridColor // New logic
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Optional

    if (progress == 0) return;

    double cellWidth = size.width / 3;
    double cellHeight = size.height / 3;

    // Vertical lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double x = cellWidth * i;
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 - (size.height / 2 * progress)),
          paint);
      canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(x, size.height / 2 + (size.height / 2 * progress)),
          paint);
    }

    // Horizontal lines - draw from center outwards
    for (int i = 1; i < 3; i++) {
      double y = cellHeight * i;
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 - (size.width / 2 * progress), y),
          paint);
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2 + (size.width / 2 * progress), y),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniGridPainter oldDelegate) {
    return oldDelegate.isPlayable != isPlayable ||
           oldDelegate.progress != progress ||
           oldDelegate.gridColor != gridColor ||
           oldDelegate.activeGridColor != activeGridColor;
  }
}
