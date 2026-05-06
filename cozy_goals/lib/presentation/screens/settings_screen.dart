import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/pastel_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PastelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Username: ${app.profile?.username ?? '-'}'),
                      Text('Level: ${app.appState?.level ?? 1}'),
                      Text('XP: ${app.appState?.xp ?? 0}'),
                      Text('Longest streak: ${app.appState?.longestStreak ?? 0}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const PastelCard(
                  child: Text('Data is stored locally in SQLite. No account, no cloud sync, no server. See docs/DATA_STORAGE.md for the exact schema.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
