import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/auth_gate.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: authState.when(
          data: (session) => session.isAuthenticated
              ? const _OnboardingCompleted()
              : const _OnboardingContent(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _OnboardingError(error: error),
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    return const AuthGate();
  }
}

class _OnboardingCompleted extends StatelessWidget {
  const _OnboardingCompleted();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Onboarding completato!'),
    );
  }
}

class _OnboardingError extends StatelessWidget {
  const _OnboardingError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Errore onboarding: $error'),
    );
  }
}
