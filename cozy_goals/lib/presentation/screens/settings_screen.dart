import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pastel_card.dart';
import 'developer_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _developerPassword = 'zuoegfbozeiugbfzoiehgfahzefgo';

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
                      Text('Active date: ${app.activeDay}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const PastelCard(
                  child: Text('Data is stored locally in SQLite. No account, no cloud sync, no server. See docs/DATA_STORAGE.md for the exact schema.'),
                ),
                const SizedBox(height: 16),
                PastelCard(
                  child: Row(
                    children: [
                      const Icon(Icons.science_rounded, color: CozyColors.roseText),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Developer mode: manually unlock rewards, increase level and simulate time.')),
                      FilledButton(
                        onPressed: () => _openDeveloperPasswordDialog(context),
                        child: const Text('Developer mode'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDeveloperPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Developer password'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (_) => _validatePassword(context, dialogContext, controller.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _validatePassword(context, dialogContext, controller.text),
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  void _validatePassword(BuildContext pageContext, BuildContext dialogContext, String value) {
    if (value == _developerPassword) {
      Navigator.of(dialogContext).pop();
      Navigator.of(pageContext).push(MaterialPageRoute(builder: (_) => const DeveloperScreen()));
      return;
    }

    ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('Invalid developer password.')));
  }
}
