import '../core/constants.dart';

class IbiCollector {
  final List<double> _ibis = []; // in seconds
  double _totalDuration = 0.0; // in seconds

  void addRRIntervals(List<int> rrIntervalsMs) {
    for (final rrMs in rrIntervalsMs) {
      // Artifact rejection
      if (rrMs < AppConstants.minRRInterval || rrMs > AppConstants.maxRRInterval) continue;

      // Moving average artifact rejection
      if (_ibis.length >= 5) {
        final recentAvg = _ibis.sublist(_ibis.length - 5).fold(0.0, (a, b) => a + b) / 5;
        final rrSec = rrMs / 1000.0;
        if ((rrSec - recentAvg).abs() / recentAvg > 0.20) continue;
      }

      final rrSec = rrMs / 1000.0;
      _ibis.add(rrSec);
      _totalDuration += rrSec;

      // Trim to keep within window
      while (_totalDuration > AppConstants.coherenceWindowSeconds && _ibis.length > 2) {
        _totalDuration -= _ibis.removeAt(0);
      }
    }
  }

  List<double> get currentWindow => List.unmodifiable(_ibis);

  double get totalDurationSeconds => _totalDuration;

  bool get hasEnoughData => _totalDuration >= AppConstants.minCalibrationSeconds;

  int get sampleCount => _ibis.length;

  void clear() {
    _ibis.clear();
    _totalDuration = 0.0;
  }
}
