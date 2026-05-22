import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../widgets/connection_status_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Settings button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.tune, color: AppConstants.textSecondary),
                  onPressed: () => context.push('/settings'),
                ),
              ),
              const Spacer(flex: 2),
              // App name
              const Text(
                'Resona',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'coherence breathing',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(flex: 2),
              // Connection status
              GestureDetector(
                onTap: () => context.push('/connect'),
                child: const ConnectionStatusBadge(),
              ),
              const SizedBox(height: 40),
              // Begin session button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/session'),
                  child: const Text('Begin Session'),
                ),
              ),
              const SizedBox(height: 16),
              // Connect button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/connect'),
                  child: const Text('Connect WHOOP'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
