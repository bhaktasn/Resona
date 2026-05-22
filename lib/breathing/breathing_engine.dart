import 'dart:async';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'breathing_settings.dart';

enum BreathPhase { inhale, inhaleHold, exhale, exhaleHold }

class BreathingState {
  final BreathPhase phase;
  final double progress;
  final double circleScale;

  const BreathingState({
    required this.phase,
    required this.progress,
    required this.circleScale,
  });

  static const idle = BreathingState(
    phase: BreathPhase.inhale,
    progress: 0.0,
    circleScale: 0.0,
  );
}

class BreathingEngine {
  BreathingSettings _settings;
  Ticker? _ticker;
  final _controller = StreamController<BreathingState>.broadcast();

  // Cycle-boundary tracking for smooth settings changes
  Duration _cycleStartElapsed = Duration.zero;
  BreathingSettings? _pendingSettings;

  BreathingEngine(this._settings);

  Stream<BreathingState> get stateStream => _controller.stream;
  BreathingSettings get currentSettings => _settings;

  /// Apply settings immediately (for settings screen changes outside a session).
  void updateSettings(BreathingSettings settings) {
    _settings = settings;
    _cycleStartElapsed = Duration.zero;
    _pendingSettings = null;
  }

  /// Queue settings to apply at the next cycle boundary (no mid-breath jump).
  void queueSettings(BreathingSettings settings) {
    _pendingSettings = settings;
  }

  void start(TickerProvider vsync) {
    stop();
    _cycleStartElapsed = Duration.zero;
    _pendingSettings = null;
    _ticker = vsync.createTicker(_onTick);
    _ticker!.start();
  }

  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void _onTick(Duration elapsed) {
    final totalUs = _settings.totalCycleDuration.inMicroseconds;
    var cycleElapsedUs = (elapsed - _cycleStartElapsed).inMicroseconds;

    // Handle cycle completion — apply pending settings at boundary
    while (cycleElapsedUs >= totalUs) {
      _cycleStartElapsed += _settings.totalCycleDuration;
      if (_pendingSettings != null) {
        _settings = _pendingSettings!;
        _pendingSettings = null;
      }
      cycleElapsedUs = (elapsed - _cycleStartElapsed).inMicroseconds;
    }

    final inhaleUs = _settings.inhaleDuration.inMicroseconds;
    final inhaleHoldUs = _settings.inhaleHoldDuration.inMicroseconds;
    final exhaleUs = _settings.exhaleDuration.inMicroseconds;
    final exhaleHoldUs = _settings.exhaleHoldDuration.inMicroseconds;

    BreathPhase phase;
    double progress;
    double circleScale;

    if (cycleElapsedUs < inhaleUs) {
      phase = BreathPhase.inhale;
      progress = inhaleUs > 0 ? cycleElapsedUs / inhaleUs : 0.0;
      circleScale = _easeInOutSine(progress);
    } else if (cycleElapsedUs < inhaleUs + inhaleHoldUs) {
      phase = BreathPhase.inhaleHold;
      progress = inhaleHoldUs > 0 ? (cycleElapsedUs - inhaleUs) / inhaleHoldUs : 0.0;
      circleScale = 1.0;
    } else if (cycleElapsedUs < inhaleUs + inhaleHoldUs + exhaleUs) {
      phase = BreathPhase.exhale;
      progress = exhaleUs > 0 ? (cycleElapsedUs - inhaleUs - inhaleHoldUs) / exhaleUs : 0.0;
      circleScale = _easeInOutSine(1.0 - progress);
    } else {
      phase = BreathPhase.exhaleHold;
      progress = exhaleHoldUs > 0
          ? (cycleElapsedUs - inhaleUs - inhaleHoldUs - exhaleUs) / exhaleHoldUs
          : 0.0;
      circleScale = 0.0;
    }

    _controller.add(BreathingState(
      phase: phase,
      progress: progress.clamp(0.0, 1.0),
      circleScale: circleScale.clamp(0.0, 1.0),
    ));
  }

  double _easeInOutSine(double t) {
    return (1 - cos(t * pi)) / 2;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
