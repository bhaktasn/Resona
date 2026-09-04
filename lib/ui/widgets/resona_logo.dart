import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// The Resona mark: concentric resonance ripples around a center dot,
/// matching the launcher icon (assets/logo/resona_logo.svg).
class ResonaLogo extends StatelessWidget {
  final double size;

  const ResonaLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ResonaLogoPainter(),
    );
  }
}

class _ResonaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.shortestSide / 1024;

    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppConstants.primaryTeal, AppConstants.accentBlue],
    ).createShader(Offset.zero & size);

    void ring(double radius, double opacity) {
      final paint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30 * unit
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, radius * unit, paint);
    }

    ring(330, 0.35);
    ring(235, 0.6);
    ring(140, 0.9);

    canvas.drawCircle(
      center,
      58 * unit,
      Paint()..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(_ResonaLogoPainter oldDelegate) => false;
}
