import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/blocked_app.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pastel_card.dart';

class BlockingScreen extends ConsumerWidget {
  const BlockingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appControllerProvider).blockedApps;
    return Scaffold(
      appBar: AppBar(title: const Text('Distraction blocking')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add app'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                PastelCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: CozyColors.sage),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This build simulates blocking on Linux. Real OS-level blocking requires explicit system integration; see docs/PYTHON_INTEGRATION.md.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (apps.isEmpty)
                  const PastelCard(child: Text('No apps configured yet. Add browsers, games, social apps, or any tempting command.'))
                else
                  ...apps.map((app) => _BlockedAppTile(app: app)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final command = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add distraction app'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Display name, e.g. Firefox')),
              const SizedBox(height: 12),
              TextField(controller: command, decoration: const InputDecoration(labelText: 'Command, e.g. firefox')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(appControllerProvider.notifier).addBlockedApp(name: name.text, command: command.text);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _BlockedAppTile extends ConsumerWidget {
  const _BlockedAppTile({required this.app});

  final BlockedApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = app.isUnlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PastelCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: unlocked ? CozyColors.mint : CozyColors.blush,
              child: Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_rounded, color: CozyColors.cocoa),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  Text(app.command.isEmpty ? 'No command provided' : app.command),
                  if (unlocked) Text('Unlocked until ${TimeOfDay.fromDateTime(app.unlockedUntil!).format(context)}'),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => ref.read(appControllerProvider.notifier).simulateOpenBlockedApp(app),
              child: const Text('Test'),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => ref.read(appControllerProvider.notifier).deleteBlockedApp(app.id),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
