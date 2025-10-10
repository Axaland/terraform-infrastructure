import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../../auth/model/auth_session.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session is! AuthenticatedSession) {
            return const Center(child: Text('Non autenticato'));
          }
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nickname: ${session.nickname}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('ID Utente: ${session.userId}'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(authSessionProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
      ),
    );
  }
}
