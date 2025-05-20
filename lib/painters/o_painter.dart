import 'package:flutter/material.dart';
import 'dart:math' as math;

class OPainter extends CustomPainter {
  final double progress; // For animation, 0.0 to 1.0

  OPainter({this.progress = 1.0}); // Default to fully drawn

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF209CEE) // Blue
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    // Define a padding factor and calculate radius
    double padding = size.width * 0.2; // 20% padding
    double radius = (math.min(size.width, size.height) - 2 * padding) / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    // For animation: draw the circle partially
    // The sweepAngle is 2 * pi * progress
    Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant OPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
