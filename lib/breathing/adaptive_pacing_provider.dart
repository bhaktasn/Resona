import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_provider.dart';
import '../hrv/hrv_provider.dart';
import 'adaptive_pacer.dart';
import 'breathing_provider.dart';
import 'breathing_settings.dart';

/// The active adaptive pacer instance during a session.
final adaptivePacerProvider = StateProvider<AdaptivePacer?>((ref) => null);

/// The current pace being used (adaptive or user-configured).
final activePaceProvider = StateProvider<BreathingSettings?>((ref) => null);

/// Call this to start adaptive pacing for a session.
/// Only adapts when a BLE device is connected.
final adaptivePacingControllerProvider = Provider<void>((ref) {
  final isConnected = ref.watch(isDeviceConnectedProvider);
  final pacer = ref.watch(adaptivePacerProvider);

  if (!isConnected || pacer == null) return;

  ref.listen(coherenceScoreProvider, (prev, next) {
    next.whenData((score) {
      final engine = ref.read(breathingEngineProvider);
      final newSettings = pacer.onCoherenceUpdate(score);
      if (newSettings != null) {
        engine.queueSettings(newSettings);
        ref.read(activePaceProvider.notifier).state = newSettings;
      }
    });
  });
});
