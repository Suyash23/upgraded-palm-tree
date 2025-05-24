import 'package:flutter/material.dart';

// Helper class to hold the progress of each line
@immutable
class _LineProgresses {
  final double line1;
  final double line2;

  const _LineProgresses({this.line1 = 0.0, this.line2 = 0.0});

  static _LineProgresses lerp(_LineProgresses? begin, _LineProgresses? end, double t) {
    final b = begin ?? const _LineProgresses();
    final e = end ?? const _LineProgresses();
    return _LineProgresses(
      line1: b.line1 + (e.line1 - b.line1) * t,
      line2: b.line2 + (e.line2 - b.line2) * t,
    );
  }
}

// Custom Tween for _LineProgresses
class _LineProgressesTween extends Tween<_LineProgresses> {
  _LineProgressesTween({required _LineProgresses begin, required _LineProgresses end})
      : super(begin: begin, end: end);

  @override
  _LineProgresses lerp(double t) {
    // `begin` and `end` are guaranteed to be non-null by TweenSequence before calling lerp.
    return _LineProgresses.lerp(begin, end, t);
  }
}

class XPainter extends CustomPainter {
  final double progress; // For animation, 0.0 to 1.0

  XPainter({this.progress = 1.0}); // Default to fully drawn

  static final Animatable<_LineProgresses> _xAnimation = TweenSequence<_LineProgresses>([
    // Phase 1: Line 1 draws from 0.0 to 0.5, Line 2 is static at 0.0
    // This phase covers the first 33% of the total animation duration.
    TweenSequenceItem<_LineProgresses>(
      tween: _LineProgressesTween(
        begin: const _LineProgresses(line1: 0.0, line2: 0.0),
        end: const _LineProgresses(line1: 0.5, line2: 0.0),
      ),
      weight: 33.0,
    ),
    // Phase 2: Line 1 draws from 0.5 to 1.0, Line 2 draws from 0.0 to 0.5
    // This phase covers the next 33% of the total animation duration (from 33% to 66%).
    TweenSequenceItem<_LineProgresses>(
      tween: _LineProgressesTween(
        begin: const _LineProgresses(line1: 0.5, line2: 0.0),
        end: const _LineProgresses(line1: 1.0, line2: 0.5),
      ),
      weight: 33.0,
    ),
    // Phase 3: Line 1 is static at 1.0, Line 2 draws from 0.5 to 1.0
    // This phase covers the final 34% of the total animation duration (from 66% to 100%).
    TweenSequenceItem<_LineProgresses>(
      tween: _LineProgressesTween(
        begin: const _LineProgresses(line1: 1.0, line2: 0.5),
        end: const _LineProgresses(line1: 1.0, line2: 1.0),
      ),
      weight: 34.0,
    ),
  ]);

  // Static final Paint object as its properties are constant
  static final Paint _xPaint = Paint()
    ..color = const Color(0xFFFF3860) // Red
    ..strokeWidth = 8.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    double padding = size.width * 0.2;
    double x1_1 = padding;
    double y1_1 = padding;
    double x1_2 = size.width - padding;
    double y1_2 = size.height - padding;

    double x2_1 = size.width - padding;
    double y2_1 = padding;
    double x2_2 = padding;
    double y2_2 = size.height - padding;

    // Evaluate the TweenSequence based on the overall progress
    final _LineProgresses currentProgresses = _xAnimation.evaluate(AlwaysStoppedAnimation(progress));
    final double line1Progress = currentProgresses.line1;
    final double line2Progress = currentProgresses.line2;

    if (line1Progress > 0) {
      Path path1 = Path();
      path1.moveTo(x1_1, y1_1);
      path1.lineTo(x1_1 + (x1_2 - x1_1) * line1Progress, y1_1 + (y1_2 - y1_1) * line1Progress);
      canvas.drawPath(path1, _xPaint);
    }

    if (line2Progress > 0) {
      Path path2 = Path();
      path2.moveTo(x2_1, y2_1);
      path2.lineTo(x2_1 + (x2_2 - x2_1) * line2Progress, y2_1 + (y2_2 - y2_1) * line2Progress);
      canvas.drawPath(path2, _xPaint);
    }
  }

  @override
  bool shouldRepaint(covariant XPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
