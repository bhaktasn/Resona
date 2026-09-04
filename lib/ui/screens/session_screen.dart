import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ble/ble_provider.dart';
import '../../breathing/adaptive_pacer.dart';
import '../../breathing/adaptive_pacing_provider.dart';
import '../../breathing/breathing_engine.dart';
import '../../breathing/breathing_provider.dart';
import '../../core/constants.dart';
import '../../session/session_provider.dart';
import '../../session/session_repository.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/coherence_indicator.dart';
import '../widgets/heart_rate_display.dart';
import '../widgets/phase_label.dart';
import '../widgets/session_timer.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  BreathPhase _currentPhase = BreathPhase.inhale;
  BreathPhase? _lastPhase;
  StreamSubscription<BreathingState>? _phaseSubscription;

  @override
  void initState() {
    super.initState();
    Future(() {
      ref.read(sessionProvider.notifier).start();

      // Initialize adaptive pacing
      final userSettings = ref.read(breathingSettingsProvider);
      final pacer = AdaptivePacer(userSettings);
      pacer.start(userSettings);
      ref.read(adaptivePacerProvider.notifier).state = pacer;
      ref.read(activePaceProvider.notifier).state = null;

      // Activate the controller that listens to coherence updates
      ref.read(adaptivePacingControllerProvider);
    });

    // Listen for phase changes to trigger haptics
    final engine = ref.read(breathingEngineProvider);
    _phaseSubscription = engine.stateStream.listen((state) {
      if (mounted && state.phase != _lastPhase) {
        _lastPhase = state.phase;
        HapticFeedback.lightImpact();
        setState(() => _currentPhase = state.phase);
      }
    });
  }

  @override
  void dispose() {
    _phaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _stopSession() async {
    // Capture the summary before tearing down the pacer — stop() records
    // the pace that was active when the session ended.
    final summary = ref.read(sessionProvider.notifier).stop();
    ref.read(adaptivePacerProvider.notifier).state = null;
    ref.read(activePaceProvider.notifier).state = null;

    await SessionRepository.save(summary);
    if (mounted) {
      context.go('/summary', extra: summary);
    }
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: const Text('End Session?', style: TextStyle(color: AppConstants.textPrimary)),
        content: const Text(
          'Are you sure you want to end this breathing session?',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _stopSession();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isDeviceConnectedProvider);
    final activePace = ref.watch(activePaceProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Breathing circle with HR overlay
                    const Stack(
                      alignment: Alignment.center,
                      children: [
                        BreathingCircle(),
                        HeartRateDisplay(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Phase label
                    PhaseLabel(phase: _currentPhase),
                    // Adaptive pace indicator
                    if (isConnected && activePace != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${(activePace.inhaleDuration.inMilliseconds / 1000).toStringAsFixed(1)}s / '
                        '${(activePace.exhaleDuration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Spacer(flex: 1),
                    // Coherence indicator
                    const CoherenceIndicator(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Timer (top right)
              const Positioned(
                top: 16,
                right: 16,
                child: SessionTimer(),
              ),
              // Stop button (bottom right)
              Positioned(
                bottom: 32,
                right: 32,
                child: FloatingActionButton.small(
                  onPressed: _stopSession,
                  backgroundColor: AppConstants.cardDark,
                  child: const Icon(Icons.stop, color: AppConstants.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
