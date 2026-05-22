import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ble/ble_provider.dart';
import '../../core/constants.dart';
import '../../hrv/coherence_calculator.dart';
import '../../hrv/hrv_provider.dart';
import '../painters/coherence_arc_painter.dart';

class CoherenceIndicator extends ConsumerWidget {
  const CoherenceIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isDeviceConnectedProvider);
    if (!isConnected) return const SizedBox.shrink();

    final collector = ref.watch(ibiCollectorProvider);
    final coherenceAsync = ref.watch(coherenceScoreProvider);
    final level = ref.watch(coherenceLevelProvider);

    final color = _colorForLevel(level);

    return SizedBox(
      width: 200,
      height: 80,
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 50,
            child: coherenceAsync.when(
              data: (score) => CustomPaint(
                size: const Size(200, 50),
                painter: CoherenceArcPainter(score: score, color: color),
              ),
              loading: () => CustomPaint(
                size: const Size(200, 50),
                painter: CoherenceArcPainter(score: 0, color: color),
              ),
              error: (e, _) => CustomPaint(
                size: const Size(200, 50),
                painter: CoherenceArcPainter(score: 0, color: color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          coherenceAsync.when(
            data: (score) => Text(
              '${_levelLabel(level)} ${score.toStringAsFixed(1)}',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            loading: () => !collector.hasEnoughData
                ? const Text(
                    'Calibrating...',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 13,
                    ),
                  )
                : const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Color _colorForLevel(CoherenceLevel? level) {
    switch (level) {
      case CoherenceLevel.high:
        return AppConstants.coherenceHigh;
      case CoherenceLevel.medium:
        return AppConstants.coherenceMedium;
      case CoherenceLevel.low:
        return AppConstants.coherenceLow;
      case null:
        return AppConstants.coherenceLow;
    }
  }

  String _levelLabel(CoherenceLevel? level) {
    switch (level) {
      case CoherenceLevel.high:
        return 'High';
      case CoherenceLevel.medium:
        return 'Medium';
      case CoherenceLevel.low:
        return 'Low';
      case null:
        return '';
    }
  }
}
