import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/models/goal.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_preview.dart';
import '../widgets/flower_decoration.dart';
import '../widgets/pastel_card.dart';
import 'avatar_screen.dart';
import 'blocking_screen.dart';
import 'focus_timer_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(appControllerProvider.select((s) => s.message), (previous, next) {
      if (next != null && next != previous) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    final app = ref.watch(appControllerProvider);
    final profile = app.profile!;
    final s = app.appState!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cozy Goals'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CozyColors.roseText,
        foregroundColor: Colors.white,
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add goal'),
      ),
      body: Stack(
        children: [
          const Positioned(top: 12, right: 60, child: FlowerDecoration(size: 54)),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 110),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(profileName: profile.username, activeDay: app.activeDay, dayOffsetDays: s.dayOffsetDays),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 760;
                        final progress = _ProgressPanel(app: app);
                        final avatar = _AvatarPanel(hair: s.avatarHair, clothes: s.avatarClothes);
                        return narrow
                            ? Column(children: [progress, const SizedBox(height: 18), avatar])
                            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: progress), const SizedBox(width: 18), Expanded(flex: 2, child: avatar)]);
                      },
                    ),
                    const SizedBox(height: 20),
                    PastelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: CozyColors.sage),
                              const SizedBox(width: 10),
                              Text('Today’s goals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Start the timer. The validate button appears halfway through the selected duration.'),
                          const SizedBox(height: 16),
                          if (app.goals.isEmpty)
                            const _EmptyGoals()
                          else
                            ...app.goals.map((goal) => _GoalTile(goal: goal)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PastelCard(
                      child: Row(
                        children: [
                          const Icon(Icons.lock_open_rounded, color: CozyColors.roseText),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${app.blockedApps.length} distraction apps configured. Each completed goal unlocks one for 30 minutes.')),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlockingScreen())),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final title = TextEditingController();
    final description = TextEditingController();
    var durationMinutes = 25;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Plant a small goal 🌱'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Optional description')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: durationMinutes,
                  decoration: const InputDecoration(labelText: 'Focus duration'),
                  items: const [1, 5, 10, 15, 25, 30, 45, 60, 90]
                      .map((minutes) => DropdownMenuItem<int>(value: minutes, child: Text('$minutes minutes')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => durationMinutes = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(appControllerProvider.notifier).addGoal(
                      title: title.text,
                      description: description.text,
                      durationMinutes: durationMinutes,
                    );
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

class _Header extends StatelessWidget {
  const _Header({required this.profileName, required this.activeDay, required this.dayOffsetDays});

  final String profileName;
  final String activeDay;
  final int dayOffsetDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello, $profileName 🌤', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Three focused steps are enough to protect today.', style: Theme.of(context).textTheme.bodyLarge),
        if (dayOffsetDays != 0) ...[
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(Icons.science_rounded, size: 18),
            label: Text('Developer date: $activeDay'),
          ),
        ],
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.app});

  final AppUiState app;

  @override
  Widget build(BuildContext context) {
    final s = app.appState!;
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent),
              const SizedBox(width: 10),
              Text('Streak: ${s.currentStreak} days', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              Chip(label: Text('Freeze: ${s.freezeCount}')),
            ],
          ),
          const SizedBox(height: 18),
          Text('Daily minimum: ${app.completedToday} / ${AppConstants.minimumDailyGoals}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: app.minimumProgress, minHeight: 14, backgroundColor: CozyColors.beige, color: CozyColors.sage),
          ),
          const SizedBox(height: 20),
          Text('Level ${s.level} · ${s.xp} XP', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: app.levelProgress, minHeight: 12, backgroundColor: CozyColors.lavender.withOpacity(0.4), color: CozyColors.roseText),
          ),
        ],
      ),
    );
  }
}

class _AvatarPanel extends StatelessWidget {
  const _AvatarPanel({required this.hair, required this.clothes});

  final String hair;
  final String clothes;

  @override
  Widget build(BuildContext context) {
    return PastelCard(
      child: Column(
        children: [
          AvatarPreview(hair: hair, clothes: clothes),
          const SizedBox(height: 10),
          Text('Your calm avatar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AvatarScreen())),
            icon: const Icon(Icons.face_retouching_natural_rounded),
            label: const Text('View avatar'),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = goal.isCompleted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? CozyColors.mint.withOpacity(0.45) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: completed
                ? const Icon(Icons.check_circle_rounded, key: ValueKey('done'), color: CozyColors.sage, size: 32)
                : const Icon(Icons.timer_rounded, key: ValueKey('timer'), color: CozyColors.roseText, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: TextStyle(fontWeight: FontWeight.w800, decoration: completed ? TextDecoration.lineThrough : null),
                ),
                const SizedBox(height: 3),
                Text('${goal.durationMinutes} min focus session', style: Theme.of(context).textTheme.bodySmall),
                if (goal.description != null) ...[
                  const SizedBox(height: 4),
                  Text(goal.description!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (completed)
            TextButton(
              onPressed: () => ref.read(appControllerProvider.notifier).reopenGoal(goal),
              child: const Text('Reopen'),
            )
          else
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FocusTimerScreen(goal: goal))),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start'),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => ref.read(appControllerProvider.notifier).deleteGoal(goal.id),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CozyColors.beige.withOpacity(0.45), borderRadius: BorderRadius.circular(24)),
      child: const Row(
        children: [
          Icon(Icons.spa_rounded, color: CozyColors.sage),
          SizedBox(width: 12),
          Expanded(child: Text('No goals yet. Add three small, realistic goals with a focus duration.')),
        ],
      ),
    );
  }
}
