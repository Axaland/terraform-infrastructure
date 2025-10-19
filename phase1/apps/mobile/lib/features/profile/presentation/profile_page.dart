import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/model/auth_session.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: sessionAsync.when(
        data: (session) {
          if (session is! AuthenticatedSession) {
            return _AnonymousView(onNavigateToLogin: () => ref.read(authSessionProvider.notifier).logout());
          }
          return _ProfileContent(session: session, config: config, onLogout: () => ref.read(authSessionProvider.notifier).logout());
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorView(error: err.toString()),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.session, required this.config, required this.onLogout});

  final AuthenticatedSession session;
  final AppConfig config;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _colorFromId(session.userId);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(session.nickname.isEmpty ? 'Profilo' : session.nickname),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: avatarColor.withOpacity(0.2),
                        child: Text(
                          session.nickname.isEmpty
                              ? '👋'
                              : session.nickname.characters.first.toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.nickname.isEmpty ? 'Esploratore' : session.nickname,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID ${session.userId.substring(0, 8)} • Stato ${session.status.toUpperCase()}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dati account', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.flag,
                        label: 'Paese preferito',
                        value: session.country ?? 'Non impostato',
                      ),
                      _InfoRow(
                        icon: Icons.language,
                        label: 'Lingua UI',
                        value: session.language?.toUpperCase() ?? 'Default',
                      ),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Token valido fino',
                        value: _formatExpiration(session.accessTokenExpiresAt),
                      ),
                      const Divider(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _buildFeatureChips(theme, config),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sicurezza sessione', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      SelectableText(
                        'Access token: ${session.accessToken}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        'Refresh token: ${session.refreshToken}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureChips(ThemeData theme, AppConfig config) {
    if (config.featureFlags.isEmpty) {
      return [const Chip(label: Text('Nessun flag attivo'))];
    }
    return config.featureFlags.entries
        .map(
          (entry) => Chip(
            avatar: Icon(
              entry.value ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: entry.value ? const Color(0xFF16A34A) : theme.colorScheme.error,
            ),
            label: Text(entry.key),
            backgroundColor: entry.value ? const Color(0xFFE7F6EC) : const Color(0xFFFFEBEE),
          ),
        )
        .toList();
  }

  String _formatExpiration(DateTime value) {
    final time = '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$time • ${value.day}/${value.month}/${value.year}';
  }

  Color _colorFromId(String id) {
    final hash = id.codeUnits.fold<int>(0, (prev, element) => (prev + element) % 360);
    return HSVColor.fromAHSV(1, hash.toDouble(), 0.55, 0.75).toColor();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnonymousView extends StatelessWidget {
  const _AnonymousView({required this.onNavigateToLogin});

  final VoidCallback onNavigateToLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.indigo),
              const SizedBox(height: 12),
              const Text('Sessione non autenticata'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onNavigateToLogin,
                child: const Text('Vai al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        color: Colors.red.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: Text(error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
