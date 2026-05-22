import 'dart:math';
import 'package:flutter/material.dart';

class BreathingRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (circle scale)
  final Color color;
  final double strokeWidth;

  BreathingRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Outer glow ring
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15 + 0.25 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4.0 * progress
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + 12.0 * progress);

    canvas.drawCircle(center, radius, glowPaint);

    // Main ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + 0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(BreathingRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
