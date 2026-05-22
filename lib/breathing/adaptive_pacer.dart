import 'breathing_settings.dart';

class AdaptivePacer {
  static const _calibrationSeconds = 30;
  static const _adjustmentIntervalSeconds = 15;
  static const _stepMs = 250;
  static const _minPhaseDurationMs = 4000;
  static const _maxPhaseDurationMs = 7000;

  BreathingSettings _baseSettings;
  BreathingSettings _currentSettings;
  BreathingSettings? _previousSettings;
  double? _previousCoherence;
  int _direction = 1; // +1 = lengthen, -1 = shorten
  bool _isCalibrating = true;
  final List<double> _calibrationScores = [];
  DateTime? _sessionStart;
  DateTime? _lastAdjustment;

  AdaptivePacer(BreathingSettings initialSettings)
      : _baseSettings = initialSettings,
        _currentSettings = initialSettings;

  BreathingSettings get currentSettings => _currentSettings;
  bool get isCalibrating => _isCalibrating;
  bool get isAdapted => _currentSettings != _baseSettings;

  void start(BreathingSettings settings) {
    _baseSettings = settings;
    _currentSettings = settings;
    _previousSettings = null;
    _previousCoherence = null;
    _direction = 1;
    _isCalibrating = true;
    _calibrationScores.clear();
    _sessionStart = DateTime.now();
    _lastAdjustment = null;
  }

  /// Called with each new coherence score. Returns new settings if pace should
  /// change, or null if no change needed.
  BreathingSettings? onCoherenceUpdate(double score) {
    final now = DateTime.now();
    if (_sessionStart == null) return null;

    final elapsed = now.difference(_sessionStart!).inSeconds;

    // Still calibrating — collect baseline scores
    if (elapsed < _calibrationSeconds) {
      _calibrationScores.add(score);
      return null;
    }

    // Transition out of calibration
    if (_isCalibrating) {
      _isCalibrating = false;
      _previousCoherence = _calibrationScores.isNotEmpty
          ? _calibrationScores.reduce((a, b) => a + b) / _calibrationScores.length
          : score;
      _lastAdjustment = now;
      return null;
    }

    // Throttle adjustments
    if (_lastAdjustment != null &&
        now.difference(_lastAdjustment!).inSeconds < _adjustmentIntervalSeconds) {
      return null;
    }

    _lastAdjustment = now;

    // Compare with previous coherence to decide direction
    if (_previousCoherence != null) {
      if (score < _previousCoherence! - 0.05) {
        // Coherence worsened — revert and flip direction
        if (_previousSettings != null) {
          _currentSettings = _previousSettings!;
          _previousSettings = null;
        }
        _direction = -_direction;
        _previousCoherence = score;
        return _currentSettings;
      }
    }

    // Try a step in the current direction
    _previousSettings = _currentSettings;
    _previousCoherence = score;

    final newInhaleMs =
        _currentSettings.inhaleDuration.inMilliseconds + (_direction * _stepMs);
    final newExhaleMs =
        _currentSettings.exhaleDuration.inMilliseconds + (_direction * _stepMs);

    // Check bounds
    if (newInhaleMs < _minPhaseDurationMs ||
        newInhaleMs > _maxPhaseDurationMs ||
        newExhaleMs < _minPhaseDurationMs ||
        newExhaleMs > _maxPhaseDurationMs) {
      // Hit a boundary — flip direction, no change
      _direction = -_direction;
      _previousSettings = null;
      return null;
    }

    _currentSettings = _currentSettings.copyWith(
      inhaleDuration: Duration(milliseconds: newInhaleMs),
      exhaleDuration: Duration(milliseconds: newExhaleMs),
    );

    return _currentSettings;
  }

  void reset() {
    _sessionStart = null;
    _isCalibrating = true;
    _calibrationScores.clear();
    _previousCoherence = null;
    _previousSettings = null;
  }
}
