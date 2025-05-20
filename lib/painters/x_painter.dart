import 'package:flutter/material.dart';

class XPainter extends CustomPainter {
  final double progress; // For animation, 0.0 to 1.0

  XPainter({this.progress = 1.0}); // Default to fully drawn

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF3860) // Red
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double padding = size.width * 0.2;
    double x1_1 = padding;
    double y1_1 = padding;
    double x1_2 = size.width - padding;
    double y1_2 = size.height - padding;

    double x2_1 = size.width - padding;
    double y2_1 = padding;
    double x2_2 = padding;
    double y2_2 = size.height - padding;

    // Define progress thresholds for staggering
    // Line 1 draws from progress 0.0 to 1.0 (effectively 0.0 to 0.5 of total animation time if total is 1.0)
    // Line 2 draws from progress 0.0 to 1.0 (effectively 0.25 to 0.75 of total animation time, then scaled)
    // This is a simplified stagger. For true sequential, two controllers or a TweenSequence would be better.

    // Progress for line 1 (0.0 to 1.0)
    // double progress1 = progress; // Assume progress is for the whole X mark animation duration

    // Progress for line 2, delayed and potentially faster if duration is shared
    // Let line 1 take roughly half the duration, line 2 the other half with overlap
    // Example: Line 1: 0-1.0 over progress 0-0.66. Line 2: 0-1.0 over progress 0.33-1.0
    double line1Progress = progress / 0.66; // Full line1 by 2/3 of total progress
    line1Progress = line1Progress > 1.0 ? 1.0 : line1Progress;


    double line2StartProgress = 0.33; // Start line 2 when total progress is 0.33
    double line2DurationProgress = 1.0 - line2StartProgress; // Remaining progress for line 2
    double line2Progress = (progress - line2StartProgress) / line2DurationProgress;
    line2Progress = line2Progress < 0 ? 0 : (line2Progress > 1.0 ? 1.0 : line2Progress);


    if (line1Progress > 0) {
      Path path1 = Path();
      path1.moveTo(x1_1, y1_1);
      path1.lineTo(x1_1 + (x1_2 - x1_1) * line1Progress, y1_1 + (y1_2 - y1_1) * line1Progress);
      canvas.drawPath(path1, paint);
    }

    if (line2Progress > 0) {
      Path path2 = Path();
      path2.moveTo(x2_1, y2_1);
      path2.lineTo(x2_1 + (x2_2 - x2_1) * line2Progress, y2_1 + (y2_2 - y2_1) * line2Progress);
      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant XPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
