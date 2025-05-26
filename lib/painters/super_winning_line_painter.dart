import 'package:flutter/material.dart';

class SuperWinningLinePainter extends CustomPainter {
  final List<Offset>? lineCoords; // Start and End points
  final double progress;
  final Color lineColor; // Added

  SuperWinningLinePainter({
    this.lineCoords,
    required this.progress,
    required this.lineColor, // Added
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lineCoords == null || lineCoords!.isEmpty || progress == 0) return; // Removed winner check

    final paint = Paint()
      ..color = lineColor // New logic
      ..strokeWidth = 8.0 // Ensure this is 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset startPoint = lineCoords![0];
    Offset endPoint = lineCoords![1];
    
    Path path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(
      startPoint.dx + (endPoint.dx - startPoint.dx) * progress,
      startPoint.dy + (endPoint.dy - startPoint.dy) * progress,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SuperWinningLinePainter oldDelegate) {
    return oldDelegate.lineCoords != lineCoords || 
           oldDelegate.progress != progress ||
           oldDelegate.lineColor != lineColor; // Updated
  }
}
