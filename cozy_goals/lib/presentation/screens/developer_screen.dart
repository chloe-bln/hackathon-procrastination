import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/reward.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pastel_card.dart';

class DeveloperScreen extends ConsumerWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final s = app.appState!;

    return Scaffold(
      appBar: AppBar(title: const Text('Developer mode')),
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
                          const Icon(Icons.science_rounded, color: CozyColors.roseText),
                          const SizedBox(width: 10),
                          Text('Current debug state', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Active date: ${app.activeDay}'),
                      Text('Day offset: ${s.dayOffsetDays}'),
                      Text('Level: ${s.level}'),
                      Text('XP: ${s.xp}'),
                      Text('Freeze items: ${s.freezeCount}'),
                      Text('Current streak: ${s.currentStreak}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PastelCard(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => ref.read(appControllerProvider.notifier).developerLevelUp(),
                        icon: const Icon(Icons.trending_up_rounded),
                        label: const Text('+1 level'),
                      ),
                      FilledButton.icon(
                        onPressed: () => ref.read(appControllerProvider.notifier).developerAddXp(100),
                        icon: const Icon(Icons.bolt_rounded),
                        label: const Text('+100 XP'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ref.read(appControllerProvider.notifier).developerAdvanceDays(1),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('+1 day'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ref.read(appControllerProvider.notifier).developerAdvanceDays(7),
                        icon: const Icon(Icons.fast_forward_rounded),
                        label: const Text('+7 days'),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.read(appControllerProvider.notifier).developerResetClock(),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset simulated date'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PastelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manual rewards', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      const Text('Cosmetics are unlocked in inventory. Freeze rewards are consumables added to the freeze counter.'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: developerRewardCatalog.map((reward) => _RewardButton(reward: reward)).toList(),
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
}

class _RewardButton extends ConsumerWidget {
  const _RewardButton({required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (reward.type) {
      'hair' => Icons.face_retouching_natural_rounded,
      'clothes' => Icons.checkroom_rounded,
      'freeze' => Icons.ac_unit_rounded,
      _ => Icons.card_giftcard_rounded,
    };

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(reward.label),
      onPressed: () => ref.read(appControllerProvider.notifier).developerUnlockReward(reward),
    );
  }
}
