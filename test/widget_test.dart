import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:resona/core/utils/fft.dart';
import 'package:resona/ble/heart_rate_parser.dart';
import 'package:resona/hrv/coherence_calculator.dart';

void main() {
  group('FFT', () {
    test('returns correct length', () {
      final input = List.filled(16, 0.0);
      input[1] = 1.0;
      final result = fft(input);
      expect(result.length, 16);
    });

    test('DC component equals sum', () {
      final input = [1.0, 2.0, 3.0, 4.0];
      final result = fft(input);
      expect(result[0].real, closeTo(10.0, 0.001));
    });
  });

  group('HeartRateParser', () {
    test('parses UINT8 HR without RR', () {
      // flags: 0x00 (UINT8 HR, no RR)
      final data = [0x00, 72];
      final result = HeartRateParser.parse(data);
      expect(result.heartRate, 72);
      expect(result.rrIntervals, isEmpty);
    });

    test('parses UINT8 HR with RR intervals', () {
      // flags: 0x10 (UINT8 HR, RR present)
      // HR: 75, RR: 800ms in 1/1024s = 819
      final data = [0x10, 75, 0x33, 0x03]; // 0x0333 = 819
      final result = HeartRateParser.parse(data);
      expect(result.heartRate, 75);
      expect(result.rrIntervals.length, 1);
      expect(result.rrIntervals[0], closeTo(799, 2)); // 819 * 1000 / 1024 ≈ 799
    });

    test('parses UINT16 HR', () {
      // flags: 0x01 (UINT16 HR, no RR)
      final data = [0x01, 0x50, 0x00]; // HR = 80
      final result = HeartRateParser.parse(data);
      expect(result.heartRate, 80);
    });

    test('handles empty data', () {
      final result = HeartRateParser.parse([]);
      expect(result.heartRate, 0);
      expect(result.rrIntervals, isEmpty);
    });
  });

  group('CoherenceCalculator', () {
    test('returns 0 for insufficient data', () {
      final result = CoherenceCalculator.calculate([0.8, 0.9]);
      expect(result, 0.0);
    });

    test('returns high coherence for perfectly sinusoidal IBI', () {
      // Generate sinusoidal IBI at ~0.1 Hz (6 breaths/min)
      // Need at least 30s of data for calibration, generate ~70s worth
      final ibis = <double>[];
      double t = 0;
      while (t < 70) {
        // IBI oscillates between 0.75 and 0.95 seconds at 0.1 Hz
        final ibi = 0.85 + 0.10 * sin(2 * pi * 0.1 * t);
        ibis.add(ibi);
        t += ibi;
      }

      final score = CoherenceCalculator.calculate(ibis);
      expect(score, greaterThan(0.5)); // Should show meaningful coherence
    });
  });
}
