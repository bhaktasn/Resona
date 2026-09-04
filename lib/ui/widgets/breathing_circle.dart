import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../breathing/breathing_engine.dart';
import '../../breathing/breathing_provider.dart';
import '../../core/constants.dart';
import '../../hrv/hrv_provider.dart';
import '../../hrv/coherence_calculator.dart';
import '../painters/breathing_ring_painter.dart';

class BreathingCircle extends ConsumerStatefulWidget {
  const BreathingCircle({super.key});

  @override
  ConsumerState<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends ConsumerState<BreathingCircle>
    with SingleTickerProviderStateMixin {
  BreathingState _breathState = BreathingState.idle;
  StreamSubscription<BreathingState>? _subscription;
  late final BreathingEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = ref.read(breathingEngineProvider);
    _subscription = _engine.stateStream.listen((state) {
      if (mounted) {
        setState(() => _breathState = state);
      }
    });
    _engine.start(this);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coherenceLevel = ref.watch(coherenceLevelProvider);
    final color = _colorForCoherence(coherenceLevel);
    final scale = lerpDouble(0.4, 1.0, _breathState.circleScale)!;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          CustomPaint(
            size: const Size(280, 280),
            painter: BreathingRingPainter(
              progress: _breathState.circleScale,
              color: color,
            ),
          ),
          // Main breathing circle
          Transform.scale(
            scale: scale,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.5),
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3 * _breathState.circleScale),
                    blurRadius: 40 * _breathState.circleScale,
                    spreadRadius: 5 * _breathState.circleScale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForCoherence(CoherenceLevel? level) {
    switch (level) {
      case CoherenceLevel.high:
        return AppConstants.coherenceHigh;
      case CoherenceLevel.medium:
        return AppConstants.coherenceMedium;
      case CoherenceLevel.low:
        return AppConstants.coherenceLow;
      case null:
        return AppConstants.primaryTeal;
    }
  }
}
