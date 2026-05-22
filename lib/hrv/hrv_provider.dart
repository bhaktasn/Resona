import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_provider.dart';
import 'ibi_collector.dart';
import 'coherence_calculator.dart';

final ibiCollectorProvider = Provider<IbiCollector>((ref) {
  final collector = IbiCollector();

  ref.listen(heartRateDataProvider, (prev, next) {
    next.whenData((data) {
      if (data.rrIntervals.isNotEmpty) {
        collector.addRRIntervals(data.rrIntervals);
      }
    });
  });

  ref.onDispose(() => collector.clear());
  return collector;
});

final coherenceScoreProvider = StreamProvider<double>((ref) {
  final collector = ref.watch(ibiCollectorProvider);
  final controller = StreamController<double>();

  final timer = Timer.periodic(const Duration(seconds: 5), (_) {
    if (collector.hasEnoughData) {
      final score = CoherenceCalculator.calculate(collector.currentWindow);
      controller.add(score);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final coherenceLevelProvider = Provider<CoherenceLevel?>((ref) {
  final score = ref.watch(coherenceScoreProvider);
  return score.whenOrNull(data: (s) => coherenceLevelFromScore(s));
});
