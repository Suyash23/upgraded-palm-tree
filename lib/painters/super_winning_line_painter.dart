import 'package:flutter/material.dart';

class SuperWinningLinePainter extends CustomPainter {
  final List<Offset>? lineCoords; // Start and End points
  final String? winner; // 'X' or 'O'
  final double progress;

  SuperWinningLinePainter({
    this.lineCoords,
    this.winner,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lineCoords == null || lineCoords!.isEmpty || winner == null || progress == 0) return;

    final paint = Paint()
      ..color = (winner == 'X') ? const Color(0xFFFF3860) : const Color(0xFF209CEE)
      ..strokeWidth = 15.0 // Thicker line
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
           oldDelegate.winner != winner ||
           oldDelegate.progress != progress;
  }
}
