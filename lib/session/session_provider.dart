import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_provider.dart';
import '../breathing/adaptive_pacing_provider.dart';
import '../breathing/breathing_provider.dart';
import '../breathing/breathing_settings.dart';
import '../core/constants.dart';
import '../hrv/coherence_calculator.dart';
import '../hrv/hrv_provider.dart';
import 'session_model.dart';

enum SessionStatus { idle, active, complete }

class SessionState {
  final SessionStatus status;
  final DateTime? startTime;
  final Duration elapsed;
  final SessionSummary? summary;

  const SessionState({
    this.status = SessionStatus.idle,
    this.startTime,
    this.elapsed = Duration.zero,
    this.summary,
  });

  SessionState copyWith({
    SessionStatus? status,
    DateTime? startTime,
    Duration? elapsed,
    SessionSummary? summary,
  }) => SessionState(
    status: status ?? this.status,
    startTime: startTime ?? this.startTime,
    elapsed: elapsed ?? this.elapsed,
    summary: summary ?? this.summary,
  );
}

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref _ref;
  Timer? _elapsedTimer;
  StreamSubscription? _rrSubscription;
  final List<int> _hrSamples = [];
  final List<double> _coherenceSamples = [];
  int _peakHR = 0;
  int _minHR = 999;

  // RMSSD accumulators over the whole session
  int? _lastRrMs;
  double _sumSquaredRrDiffs = 0.0;
  int _rrDiffCount = 0;

  SessionNotifier(this._ref) : super(const SessionState());

  void start() {
    final now = DateTime.now();
    _hrSamples.clear();
    _coherenceSamples.clear();
    _peakHR = 0;
    _minHR = 999;
    _lastRrMs = null;
    _sumSquaredRrDiffs = 0.0;
    _rrDiffCount = 0;

    // Clear IBI collector for fresh session
    _ref.read(ibiCollectorProvider).clear();

    state = SessionState(
      status: SessionStatus.active,
      startTime: now,
    );

    // Accumulate RR intervals across the whole session for RMSSD
    _rrSubscription =
        _ref.read(bleServiceProvider).heartRateStream.listen((data) {
      for (final rrMs in data.rrIntervals) {
        if (rrMs < AppConstants.minRRInterval ||
            rrMs > AppConstants.maxRRInterval) {
          continue;
        }
        if (_lastRrMs != null) {
          final diff = (rrMs - _lastRrMs!).toDouble();
          _sumSquaredRrDiffs += diff * diff;
          _rrDiffCount++;
        }
        _lastRrMs = rrMs;
      }
    });

    // Update elapsed time every second
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == SessionStatus.active) {
        final elapsed = DateTime.now().difference(state.startTime!);
        state = state.copyWith(elapsed: elapsed);

        // Sample HR every second
        final hr = _ref.read(heartRateProvider);
        if (hr != null && hr > 0) {
          _hrSamples.add(hr);
          if (hr > _peakHR) _peakHR = hr;
          if (hr < _minHR) _minHR = hr;
        }

        // Sample coherence
        final coherence = _ref.read(coherenceScoreProvider).whenOrNull(data: (s) => s);
        if (coherence != null) {
          _coherenceSamples.add(coherence);
        }
      }
    });
  }

  SessionSummary stop() {
    _elapsedTimer?.cancel();
    _rrSubscription?.cancel();
    _rrSubscription = null;

    final elapsed = state.startTime != null
        ? DateTime.now().difference(state.startTime!)
        : Duration.zero;

    final hadHrData = _hrSamples.isNotEmpty;
    final avgHR = hadHrData
        ? _hrSamples.fold(0, (a, b) => a + b) / _hrSamples.length
        : 0.0;
    final avgCoherence = _coherenceSamples.isNotEmpty
        ? _coherenceSamples.fold(0.0, (a, b) => a + b) / _coherenceSamples.length
        : 0.0;
    final peakCoherence = _coherenceSamples.isNotEmpty
        ? _coherenceSamples.fold(0.0, (a, b) => a > b ? a : b)
        : 0.0;
    final rmssd =
        _rrDiffCount > 0 ? sqrt(_sumSquaredRrDiffs / _rrDiffCount) : 0.0;
    final pctHighCoherence = _coherenceSamples.isNotEmpty
        ? _coherenceSamples
                .where((s) =>
                    coherenceLevelFromScore(s) == CoherenceLevel.high)
                .length /
            _coherenceSamples.length *
            100.0
        : 0.0;
    // Pace in use when the session ended (adaptive if it was active)
    final BreathingSettings endPace = _ref.read(activePaceProvider) ??
        _ref.read(breathingSettingsProvider);

    final summary = SessionSummary(
      startTime: state.startTime ?? DateTime.now(),
      duration: elapsed,
      avgHeartRate: avgHR,
      peakHeartRate: hadHrData ? _peakHR : 0,
      minHeartRate: hadHrData ? (_minHR == 999 ? 0 : _minHR) : 0,
      avgCoherence: avgCoherence,
      peakCoherence: peakCoherence,
      rmssd: rmssd,
      pctHighCoherence: pctHighCoherence,
      endBreathsPerMinute: endPace.breathsPerMinute,
      hrTimeSeries: List.from(_hrSamples),
      coherenceTimeSeries: List.from(_coherenceSamples),
      hadHrData: hadHrData,
    );

    state = SessionState(
      status: SessionStatus.complete,
      startTime: state.startTime,
      elapsed: elapsed,
      summary: summary,
    );

    return summary;
  }

  void reset() {
    _elapsedTimer?.cancel();
    _rrSubscription?.cancel();
    _rrSubscription = null;
    _hrSamples.clear();
    _coherenceSamples.clear();
    state = const SessionState();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _rrSubscription?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
