import 'package:flutter/material.dart';

class WinningLinePainter extends CustomPainter {
  final List<Offset> lineCoords; // Start and End points
  final double progress;
  final Color lineColor; // Added

  WinningLinePainter({
    required this.lineCoords,
    required this.progress,
    required this.lineColor, // Added
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lineCoords.isEmpty || progress == 0) return;

    final paint = Paint()
      ..color = lineColor // New logic
      ..strokeWidth = 8.0 // Ensure this is 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset startPoint = lineCoords[0];
    Offset endPoint = lineCoords[1];
    
    // Animate drawing the line
    Path path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(
      startPoint.dx + (endPoint.dx - startPoint.dx) * progress,
      startPoint.dy + (endPoint.dy - startPoint.dy) * progress,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WinningLinePainter oldDelegate) {
    return oldDelegate.lineCoords != lineCoords || 
           oldDelegate.progress != progress ||
           oldDelegate.lineColor != lineColor; // Updated
  }
}
