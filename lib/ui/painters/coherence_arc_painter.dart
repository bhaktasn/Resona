import 'dart:math';
import 'package:flutter/material.dart';

class CoherenceArcPainter extends CustomPainter {
  final double score; // 0.0 to 16.0
  final Color color;

  CoherenceArcPainter({
    required this.score,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) * 0.9;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Fill arc
    final normalized = (score / 16.0).clamp(0.0, 1.0);
    if (normalized > 0) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi * normalized,
        false,
        glowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi * normalized,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CoherenceArcPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
