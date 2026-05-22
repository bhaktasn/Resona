import 'dart:math';
import '../core/constants.dart';
import '../core/utils/fft.dart';

class CoherenceCalculator {
  /// Calculate coherence score from a list of IBI values (in seconds).
  /// Returns a value from 0.0 to ~16.0, where higher = more coherent.
  static double calculate(List<double> ibiSeconds) {
    if (ibiSeconds.length < 10) return 0.0;

    // Step 1: Interpolate to uniform sampling rate
    final interpolated = _interpolate(ibiSeconds, AppConstants.interpolationRateHz);
    if (interpolated.length < 8) return 0.0;

    // Step 2: Detrend (remove mean)
    final mean = interpolated.fold(0.0, (a, b) => a + b) / interpolated.length;
    final detrended = interpolated.map((v) => v - mean).toList();

    // Step 3: Apply Hanning window
    final n = detrended.length;
    final windowed = List<double>.generate(n, (i) {
      final w = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
      return detrended[i] * w;
    });

    // Step 4: Zero-pad to next power of 2
    final padded = zeroPadToPow2(windowed);

    // Step 5: FFT
    final spectrum = fft(padded);
    final fftLen = padded.length;

    // Step 6: Power spectrum (magnitude squared, normalized)
    final freqResolution = AppConstants.interpolationRateHz / fftLen;
    final halfLen = fftLen ~/ 2;

    // Step 7: Find peak in coherence band (0.04-0.26 Hz)
    final minBin = (0.04 / freqResolution).ceil();
    final maxBin = (0.26 / freqResolution).floor().clamp(0, halfLen - 1);

    if (minBin >= maxBin) return 0.0;

    double peakPower = 0.0;
    int peakBin = minBin;

    for (int i = minBin; i <= maxBin; i++) {
      final power = spectrum[i].magnitudeSquared / fftLen;
      if (power > peakPower) {
        peakPower = power;
        peakBin = i;
      }
    }

    // Step 8: Sum power around peak (±2 bins, ~0.03 Hz)
    final peakStart = (peakBin - 2).clamp(minBin, maxBin);
    final peakEnd = (peakBin + 2).clamp(minBin, maxBin);

    double peakBandPower = 0.0;
    double totalBandPower = 0.0;

    for (int i = minBin; i <= maxBin; i++) {
      final power = spectrum[i].magnitudeSquared / fftLen;
      totalBandPower += power;
      if (i >= peakStart && i <= peakEnd) {
        peakBandPower += power;
      }
    }

    // Step 9: Coherence ratio
    final remainingPower = totalBandPower - peakBandPower;
    if (remainingPower <= 0) return 16.0;

    final coherenceRatio = peakBandPower / remainingPower;
    return coherenceRatio.clamp(0.0, 16.0);
  }

  /// Linearly interpolate unevenly-spaced IBI series to uniform sampling.
  static List<double> _interpolate(List<double> ibis, int targetHz) {
    if (ibis.isEmpty) return [];

    // Build cumulative time axis
    final times = <double>[0.0];
    for (int i = 0; i < ibis.length; i++) {
      times.add(times.last + ibis[i]);
    }

    // IBI values correspond to intervals, so place each IBI at its midpoint
    final ibiTimes = <double>[];
    final ibiValues = <double>[];
    for (int i = 0; i < ibis.length; i++) {
      ibiTimes.add(times[i] + ibis[i] / 2);
      ibiValues.add(ibis[i]);
    }

    if (ibiTimes.length < 2) return ibiValues;

    // Interpolate at uniform intervals
    final dt = 1.0 / targetHz;
    final result = <double>[];

    for (double t = ibiTimes.first; t <= ibiTimes.last; t += dt) {
      // Find surrounding points
      int idx = 0;
      while (idx < ibiTimes.length - 1 && ibiTimes[idx + 1] < t) {
        idx++;
      }

      if (idx >= ibiTimes.length - 1) {
        result.add(ibiValues.last);
      } else {
        final t0 = ibiTimes[idx];
        final t1 = ibiTimes[idx + 1];
        final v0 = ibiValues[idx];
        final v1 = ibiValues[idx + 1];
        final frac = (t1 > t0) ? (t - t0) / (t1 - t0) : 0.0;
        result.add(v0 + frac * (v1 - v0));
      }
    }

    return result;
  }
}

enum CoherenceLevel { low, medium, high }

CoherenceLevel coherenceLevelFromScore(double score) {
  if (score < 0.5) return CoherenceLevel.low;
  if (score < 1.0) return CoherenceLevel.medium;
  return CoherenceLevel.high;
}
