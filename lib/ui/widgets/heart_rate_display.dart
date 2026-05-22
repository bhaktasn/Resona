import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ble/ble_provider.dart';
import '../../core/constants.dart';

class HeartRateDisplay extends ConsumerStatefulWidget {
  const HeartRateDisplay({super.key});

  @override
  ConsumerState<HeartRateDisplay> createState() => _HeartRateDisplayState();
}

class _HeartRateDisplayState extends ConsumerState<HeartRateDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  int? _lastHR;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hr = ref.watch(heartRateProvider);
    final isConnected = ref.watch(isDeviceConnectedProvider);

    if (!isConnected) return const SizedBox.shrink();

    // Trigger pulse on HR change
    if (hr != null && hr != _lastHR) {
      _lastHR = hr;
      _pulseController.forward(from: 0);
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hr?.toString() ?? '--',
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w200,
              letterSpacing: 2,
            ),
          ),
          const Text(
            'bpm',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
