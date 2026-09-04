import 'package:flutter_test/flutter_test.dart';
import 'package:resona/breathing/adaptive_pacer.dart';
import 'package:resona/breathing/breathing_settings.dart';

void main() {
  const initial = BreathingSettings(
    inhaleDuration: Duration(seconds: 5),
    exhaleDuration: Duration(seconds: 5),
  );

  /// Drives one full 60s evaluation period: feeds [score] every 5s and
  /// returns the pacer's decision at the period boundary.
  BreathingSettings? runPeriod(
    AdaptivePacer pacer,
    DateTime Function() advance,
    double score,
  ) {
    BreathingSettings? result;
    for (int i = 0; i < 13; i++) {
      advance();
      result = pacer.onCoherenceUpdate(score) ?? result;
    }
    return result;
  }

  (AdaptivePacer, DateTime Function()) makePacer() {
    var t = DateTime(2026, 1, 1);
    final pacer = AdaptivePacer(initial, clock: () => t);
    pacer.start(initial);
    DateTime advance() => t = t.add(const Duration(seconds: 5));
    return (pacer, advance);
  }

  group('AdaptivePacer', () {
    test('makes no change during the first evaluation period', () {
      final (pacer, advance) = makePacer();
      for (int i = 0; i < 11; i++) {
        advance();
        expect(pacer.onCoherenceUpdate(1.0), isNull);
      }
      expect(pacer.isCalibrating, isTrue);
    });

    test('takes a first exploratory step after the baseline period', () {
      final (pacer, advance) = makePacer();
      final result = runPeriod(pacer, advance, 1.0);
      expect(pacer.isCalibrating, isFalse);
      expect(result, isNotNull);
      expect(result!.inhaleDuration, const Duration(milliseconds: 5250));
    });

    test('keeps stepping the same way while coherence improves', () {
      final (pacer, advance) = makePacer();
      runPeriod(pacer, advance, 1.0); // baseline + first step (5.25s)
      final result = runPeriod(pacer, advance, 1.5); // improved
      expect(result!.inhaleDuration, const Duration(milliseconds: 5500));
    });

    test('reverts and flips direction when a step hurts coherence', () {
      final (pacer, advance) = makePacer();
      runPeriod(pacer, advance, 1.0); // baseline + step to 5.25s
      final reverted = runPeriod(pacer, advance, 0.5); // worsened
      expect(reverted!.inhaleDuration, const Duration(seconds: 5));
      // Next step should explore the other direction (shorten).
      runPeriod(pacer, advance, 0.5); // flat -> hold
      runPeriod(pacer, advance, 0.5); // flat -> hold
      final probe = runPeriod(pacer, advance, 0.5); // 3rd hold -> probe
      expect(probe!.inhaleDuration, const Duration(milliseconds: 4750));
    });

    test('holds the pace when coherence is flat', () {
      final (pacer, advance) = makePacer();
      runPeriod(pacer, advance, 1.0); // baseline + step
      final holdA = runPeriod(pacer, advance, 1.05); // within dead-band
      final holdB = runPeriod(pacer, advance, 1.0);
      expect(holdA, isNull);
      expect(holdB, isNull);
    });

    test('ignores single noisy samples inside a period', () {
      final (pacer, advance) = makePacer();
      runPeriod(pacer, advance, 1.0); // baseline + step to 5.25s
      // Mean of alternating 0.8/1.2 is 1.0 — flat, so hold despite noise.
      BreathingSettings? result;
      for (int i = 0; i < 13; i++) {
        advance();
        result = pacer.onCoherenceUpdate(i.isEven ? 0.8 : 1.2) ?? result;
      }
      expect(result, isNull);
    });

    test('never exceeds phase duration bounds', () {
      final (pacer, advance) = makePacer();
      runPeriod(pacer, advance, 1.0);
      // Keep "improving" so it steps up forever; must stop at 7s.
      var score = 1.0;
      for (int i = 0; i < 20; i++) {
        score += 0.5;
        runPeriod(pacer, advance, score);
      }
      expect(
        pacer.currentSettings.inhaleDuration.inMilliseconds,
        lessThanOrEqualTo(7000),
      );
    });
  });
}
