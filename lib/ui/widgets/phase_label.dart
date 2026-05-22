import 'package:flutter/material.dart';
import '../../breathing/breathing_engine.dart';
import '../../core/constants.dart';

class PhaseLabel extends StatelessWidget {
  final BreathPhase phase;

  const PhaseLabel({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        _labelFor(phase),
        key: ValueKey(phase),
        style: const TextStyle(
          color: AppConstants.textSecondary,
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 4,
        ),
      ),
    );
  }

  String _labelFor(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return 'BREATHE IN';
      case BreathPhase.inhaleHold:
        return 'HOLD';
      case BreathPhase.exhale:
        return 'BREATHE OUT';
      case BreathPhase.exhaleHold:
        return 'HOLD';
    }
  }
}
