import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../session/session_provider.dart';
import '../../core/constants.dart';

class SessionTimer extends ConsumerWidget {
  const SessionTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final elapsed = session.elapsed;

    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: const TextStyle(
        color: AppConstants.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
