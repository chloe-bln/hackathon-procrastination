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
    final app = ref.watch(appControllerProvider);
    final apps = app.blockedApps;
    final appCount = apps.where((item) => item.isApp).length;
    final siteCount = apps.where((item) => item.isSite).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Distraction blocking')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add block'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PastelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: CozyColors.sage),
                          const SizedBox(width: 10),
                          Text('Real local blocking', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('$appCount app process rule(s), $siteCount website rule(s).'),
                      const SizedBox(height: 10),
                      const Text('Apps: Cozy Goals checks every 5 seconds and closes locked processes. Websites: Cozy Goals writes a marked section in /etc/hosts via pkexec, so Linux will ask for your password.'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => ref.read(appControllerProvider.notifier).enforceAppBlocking(),
                            icon: const Icon(Icons.gpp_good_rounded),
                            label: const Text('Enforce app blocks now'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(appControllerProvider.notifier).applyWebsiteBlocks(),
                            icon: const Icon(Icons.public_off_rounded),
                            label: const Text('Apply website blocks'),
                          ),
                          TextButton.icon(
                            onPressed: () => ref.read(appControllerProvider.notifier).clearWebsiteBlocks(),
                            icon: const Icon(Icons.cleaning_services_rounded),
                            label: const Text('Clear website blocks'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (apps.isEmpty)
                  const PastelCard(child: Text('No distractions configured yet. Add app processes like firefox/steam, or websites like youtube.com.'))
                else
                  ...apps.map((app) => _BlockedAppTile(app: app)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final target = TextEditingController();
    var kind = 'app';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add distraction block'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: kind,
                  decoration: const InputDecoration(labelText: 'Block type'),
                  items: const [
                    DropdownMenuItem(value: 'app', child: Text('Linux app / process')),
                    DropdownMenuItem(value: 'site', child: Text('Website domain')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      kind = value;
                      target.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Display name, e.g. Firefox or YouTube')),
                const SizedBox(height: 12),
                TextField(
                  controller: target,
                  decoration: InputDecoration(
                    labelText: kind == 'app' ? 'Process pattern, e.g. firefox' : 'Domain, e.g. youtube.com',
                    helperText: kind == 'app' ? 'The guard uses pgrep/pkill -f on this pattern.' : 'The domain will be written to /etc/hosts.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(appControllerProvider.notifier).addBlockedApp(name: name.text, target: target.text, kind: kind);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
              child: Icon(unlocked ? Icons.lock_open_rounded : app.isSite ? Icons.public_off_rounded : Icons.lock_rounded, color: CozyColors.cocoa),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  Text('${app.isSite ? 'Website' : 'App process'} · ${app.target}'),
                  if (unlocked) Text('Unlocked until ${TimeOfDay.fromDateTime(app.unlockedUntil!).format(context)}'),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => ref.read(appControllerProvider.notifier).simulateOpenBlockedApp(app),
              child: const Text('Status'),
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
