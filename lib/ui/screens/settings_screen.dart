import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../breathing/breathing_provider.dart';
import '../../core/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(breathingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'BREATHING PACE',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          // Inhale duration
          _DurationSlider(
            label: 'Inhale',
            value: settings.inhaleDuration.inMilliseconds / 1000.0,
            min: 3,
            max: 8,
            onChanged: (v) {
              ref.read(breathingSettingsProvider.notifier).update(
                settings.copyWith(inhaleDuration: _toDuration(v)),
              );
            },
          ),
          const SizedBox(height: 16),
          // Exhale duration
          _DurationSlider(
            label: 'Exhale',
            value: settings.exhaleDuration.inMilliseconds / 1000.0,
            min: 3,
            max: 8,
            onChanged: (v) {
              ref.read(breathingSettingsProvider.notifier).update(
                settings.copyWith(exhaleDuration: _toDuration(v)),
              );
            },
          ),
          const SizedBox(height: 16),
          // Inhale hold
          _DurationSlider(
            label: 'Hold after inhale',
            value: settings.inhaleHoldDuration.inMilliseconds / 1000.0,
            min: 0,
            max: 4,
            onChanged: (v) {
              ref.read(breathingSettingsProvider.notifier).update(
                settings.copyWith(inhaleHoldDuration: _toDuration(v)),
              );
            },
          ),
          const SizedBox(height: 16),
          // Exhale hold
          _DurationSlider(
            label: 'Hold after exhale',
            value: settings.exhaleHoldDuration.inMilliseconds / 1000.0,
            min: 0,
            max: 4,
            onChanged: (v) {
              ref.read(breathingSettingsProvider.notifier).update(
                settings.copyWith(exhaleHoldDuration: _toDuration(v)),
              );
            },
          ),
          const SizedBox(height: 32),
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  settings.breathsPerMinute.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppConstants.primaryTeal,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Text(
                  'breaths per minute',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Snap slider values to the nearest half second.
Duration _toDuration(double seconds) =>
    Duration(milliseconds: ((seconds * 2).round() * 500));

class _DurationSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 15)),
            Text(
              '${value.toStringAsFixed(1)}s',
              style: const TextStyle(color: AppConstants.primaryTeal, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) * 2).round(),
          activeColor: AppConstants.primaryTeal,
          inactiveColor: AppConstants.cardDark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
