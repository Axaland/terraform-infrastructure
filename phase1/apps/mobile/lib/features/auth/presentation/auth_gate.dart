import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_config.dart';
import '../application/auth_notifier.dart';
import '../data/local_identity_provider.dart';
import '../model/auth_session.dart';
import 'widgets/provider_login_button.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _loadingProvider;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession>>(authSessionProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (next.hasError) {
        final message = next.error?.toString() ?? 'Errore di autenticazione';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
        setState(() => _loadingProvider = null);
      }
      if (next is AsyncData<AuthSession>) {
        setState(() => _loadingProvider = null);
      }
    });
    final theme = Theme.of(context);
    final authState = ref.watch(authSessionProvider);
    final config = ref.watch(appConfigProvider);
    final isLoading = authState.isLoading && authState.value == null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'XXX',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ).animate().fade(duration: 400.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Onboarding sicuro e veloce',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                      ).animate().fade(duration: 500.ms).slide(begin: const Offset(0, 0.2)),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 140, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accedi al tuo profilo',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Usa un provider fidato per sincronizzare sessioni e progressi nel cloud.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              ProviderLoginButton(
                                provider: 'google',
                                isLoading: _loadingProvider == 'google' || isLoading,
                                onPressed: () => _handleLogin('google'),
                              ),
                              const SizedBox(height: 16),
                              ProviderLoginButton(
                                provider: 'apple',
                                isLoading: _loadingProvider == 'apple' || isLoading,
                                onPressed: () => _handleLogin('apple'),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: _buildFeatureChips(config),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(duration: 450.ms).slide(begin: const Offset(0, 0.1)),
                      const SizedBox(height: 24),
                      authState.when(
                        data: (session) => session.isAuthenticated
                            ? _AuthenticatedSummary(session: session)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => _ErrorBanner(message: error.toString()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(String provider) async {
    if (_loadingProvider != null) return;
    setState(() => _loadingProvider = provider);
    try {
      final deviceId = await _resolveDeviceId();
      final idProvider = ref.read(localIdentityProvider);
      final idToken = await idProvider.issueIdToken(provider: provider, deviceId: deviceId);
      await ref.read(authSessionProvider.notifier).login(
            provider: provider,
            idToken: idToken,
            deviceId: deviceId,
          );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login fallito: $error')),
      );
      setState(() => _loadingProvider = null);
    }
  }

  List<Widget> _buildFeatureChips(AppConfig config) {
    final enabledFlags = config.featureFlags.entries.where((entry) => entry.value).toList();
    if (enabledFlags.isEmpty) {
      return [
        Chip(
          avatar: const Icon(Icons.bolt, size: 16),
          label: const Text('Feature flag bootstrap attivo'),
        )
      ];
    }
    return enabledFlags
        .take(4)
        .map(
          (entry) => Chip(
            avatar: const Icon(Icons.bolt, size: 16),
            label: Text(entry.key),
          ),
        )
        .toList();
  }
}

class _AuthenticatedSummary extends StatelessWidget {
  const _AuthenticatedSummary({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    if (session is! AuthenticatedSession) {
      return const SizedBox.shrink();
    }
    final typed = session as AuthenticatedSession;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.15),
                  child: Text(
                    typed.nickname.isEmpty ? '👋' : typed.nickname.characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typed.nickname.isEmpty ? 'Profilo attivo' : typed.nickname,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Sessione valida fino alle ${_formatTime(typed.accessTokenExpiresAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => context.push('/profile'),
                  child: const Text('Apri profilo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> _resolveDeviceId() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.packageName}-${info.buildNumber}-${info.version}';
}
