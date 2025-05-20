import 'package:flutter/material.dart';

class WinningLinePainter extends CustomPainter {
  final List<Offset> lineCoords; // Start and End points
  final String player; // 'X' or 'O'
  final double progress;

  WinningLinePainter({
    required this.lineCoords,
    required this.player,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lineCoords.isEmpty || progress == 0) return;

    final paint = Paint()
      ..color = (player == 'X') ? const Color(0xFFFF3860) : const Color(0xFF209CEE) // Red for X, Blue for O
      ..strokeWidth = 10.0 // As per spec
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
           oldDelegate.player != player || 
           oldDelegate.progress != progress;
  }
}
