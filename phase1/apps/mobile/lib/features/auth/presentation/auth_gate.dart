import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../application/auth_notifier.dart';
import '../model/auth_session.dart';
import 'widgets/provider_login_button.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Benvenuto su XXX')),
      body: authState.when(
        data: (session) {
          if (session.isAuthenticated) {
            return const _SuccessView();
          }
          return const _LoginView();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(error: error, stack: stack),
      ),
    );
  }
}

class _LoginView extends ConsumerWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleLogin(String provider) async {
      final deviceId = await _resolveDeviceId();
      await ref.read(authSessionProvider.notifier).login(
            provider: provider,
            idToken: 'mock-token-$provider',
            deviceId: deviceId,
          );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Accedi per continuare',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ProviderLoginButton(
            provider: 'google',
            onPressed: () => handleLogin('google'),
          ),
          const SizedBox(height: 16),
          ProviderLoginButton(
            provider: 'apple',
            onPressed: () => handleLogin('apple'),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends ConsumerWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    return Center(
      child: sessionAsync.when(
        data: (session) {
          final nickname = session is AuthenticatedSession ? session.nickname : 'Player';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 48),
              const SizedBox(height: 16),
              Text('Bentornato, $nickname!'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(authSessionProvider.notifier).logout(),
                child: const Text('Logout'),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Errore: $err'),
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.error, required this.stack});

  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Errore: $error'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
            child: const Text('Riprovare'),
          ),
        ],
      ),
    );
  }
}

Future<String> _resolveDeviceId() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.packageName}-${info.buildNumber}';
}
