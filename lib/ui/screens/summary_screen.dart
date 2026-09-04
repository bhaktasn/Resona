import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../session/session_model.dart';
import '../../session/session_provider.dart';

class SummaryScreen extends ConsumerWidget {
  final SessionSummary summary;

  const SummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Text(
                'Session Complete',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
              // Duration
              _StatCard(
                label: 'Duration',
                value: summary.formattedDuration,
                icon: Icons.timer_outlined,
              ),
              if (summary.hadHrData) ...[
                const SizedBox(height: 16),
                // HR stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg HR',
                        value: '${summary.avgHeartRate.round()}',
                        unit: 'bpm',
                        icon: Icons.favorite_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: 'Min HR',
                        value: '${summary.minHeartRate}',
                        unit: 'bpm',
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: 'Peak HR',
                        value: '${summary.peakHeartRate}',
                        unit: 'bpm',
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Coherence stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Coherence',
                        value: summary.avgCoherence.toStringAsFixed(1),
                        icon: Icons.waves,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: 'Peak Coherence',
                        value: summary.peakCoherence.toStringAsFixed(1),
                        icon: Icons.auto_awesome,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // HRV + coherence time stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'HRV (RMSSD)',
                        value: summary.rmssd.toStringAsFixed(0),
                        unit: 'ms',
                        icon: Icons.monitor_heart_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: 'In Coherence',
                        value: summary.pctHighCoherence.toStringAsFixed(0),
                        unit: '%',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                if (summary.endBreathsPerMinute > 0) ...[
                  const SizedBox(height: 16),
                  _StatCard(
                    label: 'Ending Pace',
                    value: summary.endBreathsPerMinute.toStringAsFixed(1),
                    unit: 'breaths/min',
                    icon: Icons.air,
                  ),
                ],
                // HR chart
                if (summary.hrTimeSeries.length > 2) ...[
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Heart Rate',
                      style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: _HRChartPainter(summary.hrTimeSeries),
                    ),
                  ),
                ],
              ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).reset();
                    context.go('/');
                  },
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryTeal, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HRChartPainter extends CustomPainter {
  final List<int> data;
  _HRChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minHR = data.reduce(min).toDouble();
    final maxHR = data.reduce(max).toDouble();
    final range = maxHR - minHR;
    if (range == 0) return;

    final paint = Paint()
      ..color = AppConstants.primaryTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minHR) / range) * size.height * 0.8 - size.height * 0.1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Gradient fill below
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppConstants.primaryTeal.withValues(alpha: 0.2),
          AppConstants.primaryTeal.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_HRChartPainter oldDelegate) => oldDelegate.data != data;
}
