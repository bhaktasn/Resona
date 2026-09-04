import 'breathing_settings.dart';

/// Hill-climbs the breathing pace toward maximum coherence.
///
/// Coherence is computed over a ~64s sliding window of heart data, so the
/// pacer must evaluate on the same timescale: every score received during a
/// 60s evaluation period is averaged, and only that mean drives a decision.
/// Reacting faster than the window length would credit or blame a pace
/// change for data that was mostly produced by the previous pace.
///
/// Decisions use a dead-band so measurement noise cannot cause drift:
/// - mean improved beyond the dead-band after a step -> step again, same way
/// - mean worsened beyond the dead-band after a step -> undo it, search the
///   other way next time
/// - anything else -> hold the current pace (after several consecutive
///   holds, take a single probe step so slow physiological drift can still
///   be tracked)
class AdaptivePacer {
  static const _evaluationIntervalSeconds = 60;
  static const _stepMs = 250;
  static const _minPhaseDurationMs = 4000;
  static const _maxPhaseDurationMs = 7000;
  static const _deadBand = 0.15;
  static const _probeAfterHolds = 3;

  BreathingSettings _baseSettings;
  BreathingSettings _currentSettings;
  BreathingSettings? _previousSettings; // settings before the last step
  double? _previousCoherence; // mean of the previous evaluation period
  int _direction = 1; // +1 = lengthen, -1 = shorten
  bool _isCalibrating = true;
  bool _lastActionWasStep = false;
  int _holdCount = 0;
  final List<double> _periodScores = [];
  DateTime? _periodStart;
  final DateTime Function() _now;

  AdaptivePacer(BreathingSettings initialSettings, {DateTime Function()? clock})
      : _baseSettings = initialSettings,
        _currentSettings = initialSettings,
        _now = clock ?? DateTime.now;

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
    _lastActionWasStep = false;
    _holdCount = 0;
    _periodScores.clear();
    _periodStart = null;
  }

  /// Called with each new coherence score. Returns new settings if pace
  /// should change, or null if no change needed.
  BreathingSettings? onCoherenceUpdate(double score) {
    final now = _now();
    // The period clock starts at the first received score, not session
    // start — scores only begin once enough heart data has accumulated.
    _periodStart ??= now;
    _periodScores.add(score);

    if (now.difference(_periodStart!).inSeconds < _evaluationIntervalSeconds) {
      return null;
    }

    final mean =
        _periodScores.reduce((a, b) => a + b) / _periodScores.length;
    _periodScores.clear();
    _periodStart = now;

    // First full period establishes the baseline, then exploration begins.
    if (_previousCoherence == null) {
      _isCalibrating = false;
      _previousCoherence = mean;
      return _step();
    }

    final delta = mean - _previousCoherence!;
    _previousCoherence = mean;

    if (delta < -_deadBand) {
      _holdCount = 0;
      if (_lastActionWasStep && _previousSettings != null) {
        // The step hurt — undo it and search the other way next time.
        _currentSettings = _previousSettings!;
        _previousSettings = null;
        _direction = -_direction;
        _lastActionWasStep = false;
        return _currentSettings;
      }
      // Coherence dropped while holding — not caused by pace; keep holding.
      _lastActionWasStep = false;
      return null;
    }

    if (delta > _deadBand && _lastActionWasStep) {
      // The step helped — keep going the same way.
      _holdCount = 0;
      return _step();
    }

    // Flat (or improved on its own): hold the pace. Probe occasionally so a
    // slowly shifting resonant rate can still be found.
    _lastActionWasStep = false;
    _holdCount++;
    if (_holdCount >= _probeAfterHolds) {
      _holdCount = 0;
      return _step();
    }
    return null;
  }

  BreathingSettings? _step() {
    final newInhaleMs =
        _currentSettings.inhaleDuration.inMilliseconds + _direction * _stepMs;
    final newExhaleMs =
        _currentSettings.exhaleDuration.inMilliseconds + _direction * _stepMs;

    if (newInhaleMs < _minPhaseDurationMs ||
        newInhaleMs > _maxPhaseDurationMs ||
        newExhaleMs < _minPhaseDurationMs ||
        newExhaleMs > _maxPhaseDurationMs) {
      // Hit a boundary — flip direction, no change this period.
      _direction = -_direction;
      _lastActionWasStep = false;
      return null;
    }

    _previousSettings = _currentSettings;
    _currentSettings = _currentSettings.copyWith(
      inhaleDuration: Duration(milliseconds: newInhaleMs),
      exhaleDuration: Duration(milliseconds: newExhaleMs),
    );
    _lastActionWasStep = true;
    return _currentSettings;
  }

  void reset() {
    _isCalibrating = true;
    _previousCoherence = null;
    _previousSettings = null;
    _lastActionWasStep = false;
    _holdCount = 0;
    _periodScores.clear();
    _periodStart = null;
  }
}
