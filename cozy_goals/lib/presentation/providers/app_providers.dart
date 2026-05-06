import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../data/local/app_repository.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/python/python_engine.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/blocked_app.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/reward.dart';
import '../../domain/models/user_profile.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) => AppRepository());
final pythonEngineProvider = Provider<PythonEngine>((ref) => PythonEngine());

final appControllerProvider = StateNotifierProvider<AppController, AppUiState>((ref) {
  return AppController(
    repository: ref.watch(appRepositoryProvider),
    python: ref.watch(pythonEngineProvider),
  )..load();
});

const developerRewardCatalog = <Reward>[
  Reward(id: 'hair_bun_mint', type: 'hair', label: 'Mint bun'),
  Reward(id: 'hair_bob_rose', type: 'hair', label: 'Rose bob'),
  Reward(id: 'hair_waves_lavender', type: 'hair', label: 'Lavender waves'),
  Reward(id: 'hair_leaf_sage', type: 'hair', label: 'Sage leaf hair'),
  Reward(id: 'clothes_cardigan_lavender', type: 'clothes', label: 'Lavender cardigan'),
  Reward(id: 'clothes_sweater_mint', type: 'clothes', label: 'Mint sweater'),
  Reward(id: 'clothes_raincoat_blush', type: 'clothes', label: 'Blush raincoat'),
  Reward(id: 'clothes_overalls_sage', type: 'clothes', label: 'Sage overalls'),
  Reward(id: 'streak_freeze', type: 'freeze', label: 'Streak freeze'),
];

class AppUiState {
  const AppUiState({
    this.isLoading = true,
    this.profile,
    this.appState,
    this.goals = const [],
    this.inventory = const [],
    this.blockedApps = const [],
    this.message,
  });

  final bool isLoading;
  final UserProfile? profile;
  final CozyAppState? appState;
  final List<Goal> goals;
  final List<Reward> inventory;
  final List<BlockedApp> blockedApps;
  final String? message;

  bool get needsOnboarding => !isLoading && profile == null;
  int get completedToday => goals.where((g) => g.isCompleted).length;
  String get activeDay => DayKey.today(offsetDays: appState?.dayOffsetDays ?? 0);
  double get minimumProgress => (completedToday / AppConstants.minimumDailyGoals).clamp(0.0, 1.0);
  int get nextLevelXp => pow((appState?.level ?? 1) + 1, 2).toInt() * 100;
  int get currentLevelBaseXp {
    final level = appState?.level ?? 1;
    if (level <= 1) return 0;
    return pow(level, 2).toInt() * 100;
  }

  double get levelProgress {
    final current = appState;
    if (current == null) return 0;
    final span = nextLevelXp - currentLevelBaseXp;
    if (span <= 0) return 0;
    return ((current.xp - currentLevelBaseXp) / span).clamp(0.0, 1.0);
  }

  AppUiState copyWith({
    bool? isLoading,
    UserProfile? profile,
    CozyAppState? appState,
    List<Goal>? goals,
    List<Reward>? inventory,
    List<BlockedApp>? blockedApps,
    String? message,
  }) =>
      AppUiState(
        isLoading: isLoading ?? this.isLoading,
        profile: profile ?? this.profile,
        appState: appState ?? this.appState,
        goals: goals ?? this.goals,
        inventory: inventory ?? this.inventory,
        blockedApps: blockedApps ?? this.blockedApps,
        message: message,
      );
}

class AppController extends StateNotifier<AppUiState> {
  AppController({required this.repository, required this.python}) : super(const AppUiState());

  final AppRepository repository;
  final PythonEngine python;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    await repository.ensureDefaultInventory();
    await repository.clearExpiredAppUnlocks();

    final profile = await repository.getProfile();
    if (profile == null) {
      state = const AppUiState(isLoading: false);
      return;
    }

    var appState = await repository.getState() ?? await repository.createInitialState();
    appState = await _runDailyValidation(appState);

    final activeDay = DayKey.today(offsetDays: appState.dayOffsetDays);
    state = AppUiState(
      isLoading: false,
      profile: profile,
      appState: appState,
      goals: await repository.getGoalsForDay(activeDay),
      inventory: await repository.unlockedInventory(),
      blockedApps: await repository.blockedApps(),
    );
  }

  Future<void> completeOnboarding({required String username, required DateTime birthDate}) async {
    final profile = UserProfile(username: username.trim(), birthDate: birthDate);
    await repository.saveProfile(profile);
    final appState = await repository.createInitialState();
    await repository.ensureDefaultInventory();
    state = AppUiState(
      isLoading: false,
      profile: profile,
      appState: appState,
      goals: const [],
      inventory: await repository.unlockedInventory(),
      blockedApps: await repository.blockedApps(),
      message: 'Welcome, ${profile.username}. Let us make today gentle 🌸',
    );
  }

  Future<void> addGoal({required String title, String? description, required int durationMinutes}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final goal = Goal(
      id: _uuid.v4(),
      title: cleanTitle,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      durationMinutes: durationMinutes.clamp(1, 240).toInt(),
      goalDate: _activeDayFromState(),
    );
    await repository.upsertGoal(goal);
    await _refresh(message: 'Goal planted for ${goal.durationMinutes} min 🌱');
  }

  Future<void> deleteGoal(String id) async {
    await repository.deleteGoal(id);
    await _refresh(message: 'Goal removed. Keep the day realistic.');
  }

  Future<void> reopenGoal(Goal goal) async {
    await repository.upsertGoal(goal.copyWith(isCompleted: false, completedAt: null));
    await _refresh(message: 'Goal reopened. Relaunch the focus timer when ready.');
  }

  Future<void> completeGoalAfterFocus(Goal goal) async {
    if (goal.isCompleted) return;

    final updated = goal.copyWith(isCompleted: true, completedAt: DateTime.now());
    await repository.upsertGoal(updated);

    final completedCount = await repository.completedCountForDay(goal.goalDate);
    var nextMessage = _encouragement();

    final rewardMessage = await _applyGoalCompletionRewards(
      grantThresholdReward: completedCount >= AppConstants.minimumDailyGoals,
      completedCount: completedCount,
    );
    if (rewardMessage != null) {
      nextMessage = '$nextMessage $rewardMessage';
    }

    await repository.unlockOneBlockedAppForToday();
    nextMessage = '$nextMessage One blocked app is open for 30 minutes.';

    await _secureStreakIfEnough(message: nextMessage);
  }

  Future<void> selectAvatar({String? hair, String? clothes}) async {
    final s = state.appState;
    if (s == null) return;
    final updated = s.copyWith(avatarHair: hair, avatarClothes: clothes);
    await repository.saveState(updated);
    await _refresh(message: 'Avatar updated ✨');
  }

  Future<void> addBlockedApp({required String name, required String command}) async {
    if (name.trim().isEmpty) return;
    final app = BlockedApp(id: _uuid.v4(), name: name.trim(), command: command.trim());
    await repository.upsertBlockedApp(app);
    await _refresh(message: '${app.name} added to your calm list.');
  }

  Future<void> deleteBlockedApp(String id) async {
    await repository.deleteBlockedApp(id);
    await _refresh(message: 'Blocked app removed.');
  }

  Future<void> simulateOpenBlockedApp(BlockedApp app) async {
    final message = app.isUnlocked
        ? '${app.name} is temporarily unlocked. Use it intentionally.'
        : '${app.name} is blocked. Complete one goal to unlock it for 30 minutes.';
    state = state.copyWith(message: message);
  }

  Future<void> developerUnlockReward(Reward reward) async {
    final s = await repository.getState();
    if (s == null) return;

    if (reward.type == 'freeze') {
      await repository.saveState(s.copyWith(freezeCount: s.freezeCount + 1));
      await _refresh(message: 'Developer: +1 streak freeze added.');
      return;
    }

    await repository.unlockReward(reward);
    await _refresh(message: 'Developer: ${reward.label} unlocked.');
  }

  Future<void> developerLevelUp() async {
    final s = await repository.getState();
    if (s == null) return;

    final nextLevel = s.level + 1;
    final requiredXp = pow(nextLevel, 2).toInt() * 100;
    await repository.saveState(s.copyWith(level: nextLevel, xp: max(s.xp, requiredXp)));
    await _refresh(message: 'Developer: level increased to $nextLevel.');
  }

  Future<void> developerAddXp(int amount) async {
    final s = await repository.getState();
    if (s == null) return;

    final result = await python.call('progression', {
      'current_xp': s.xp,
      'current_level': s.level,
      'xp_gain': amount,
    });

    var freezeCount = s.freezeCount;
    for (final reward in _decodeRewards(result['rewards'])) {
      if (reward.type == 'freeze') {
        freezeCount += 1;
      } else {
        await repository.unlockReward(reward);
      }
    }

    await repository.saveState(s.copyWith(
      xp: result['xp'] as int,
      level: result['level'] as int,
      freezeCount: freezeCount,
    ));
    await _refresh(message: 'Developer: +$amount XP applied.');
  }

  Future<void> developerAdvanceDays(int days) async {
    final s = await repository.getState();
    if (s == null) return;

    await repository.saveState(s.copyWith(dayOffsetDays: s.dayOffsetDays + days));
    await load();
    state = state.copyWith(message: 'Developer: simulated time advanced by $days day(s).');
  }

  Future<void> developerResetClock() async {
    final s = await repository.getState();
    if (s == null) return;

    final reset = s.copyWith(
      dayOffsetDays: 0,
      lastValidatedDate: DayKey.today(),
      lastStreakAwardedDate: null,
    );
    await repository.saveState(reset);
    await load();
    state = state.copyWith(message: 'Developer: simulated date reset to real today.');
  }

  Future<CozyAppState> _runDailyValidation(CozyAppState appState) async {
    final activeToday = DayKey.today(offsetDays: appState.dayOffsetDays);
    if (!DayKey.isBefore(appState.lastValidatedDate, activeToday)) return appState;

    var current = appState;
    final daysToValidate = DayKey.daysBetweenExclusiveEnd(appState.lastValidatedDate, activeToday);
    for (final day in daysToValidate) {
      final completed = await repository.completedCountForDay(day);
      final result = await python.call('daily_reset', {
        'date': day,
        'completed_count': completed,
        'minimum_goals': AppConstants.minimumDailyGoals,
        'current_streak': current.currentStreak,
        'longest_streak': current.longestStreak,
        'freeze_count': current.freezeCount,
        'last_streak_awarded_date': current.lastStreakAwardedDate,
      });
      current = current.copyWith(
        currentStreak: result['current_streak'] as int,
        longestStreak: result['longest_streak'] as int,
        freezeCount: result['freeze_count'] as int,
        lastStreakAwardedDate: result['last_streak_awarded_date'] as String?,
      );
    }

    current = current.copyWith(lastValidatedDate: activeToday);
    await repository.saveState(current);
    return current;
  }

  Future<String?> _applyGoalCompletionRewards({required bool grantThresholdReward, required int completedCount}) async {
    final s = await repository.getState();
    if (s == null) return null;

    final progression = await python.call('progression', {
      'current_xp': s.xp,
      'current_level': s.level,
      'xp_gain': AppConstants.xpPerGoal,
    });

    final messages = <String>[];
    var freezeCount = s.freezeCount;

    final levelRewards = _decodeRewards(progression['rewards']);
    for (final reward in levelRewards) {
      if (reward.type == 'freeze') {
        freezeCount += 1;
      } else {
        await repository.unlockReward(reward);
      }
    }

    if ((progression['level_up'] as bool?) == true) {
      final labels = levelRewards.map((r) => r.label).join(', ');
      messages.add(labels.isEmpty ? 'Level up ✨' : 'Level up: $labels ✨');
    }

    if (grantThresholdReward) {
      final goalRewardResult = await python.call('goal_reward', {
        'completed_count': completedCount,
        'minimum_goals': AppConstants.minimumDailyGoals,
        'unlocked_ids': await repository.unlockedRewardIds(),
      });

      final payload = goalRewardResult['reward'];
      if (payload is Map<String, dynamic>) {
        final reward = Reward(
          id: payload['id'] as String,
          type: payload['type'] as String,
          label: payload['label'] as String,
        );
        if (reward.type == 'freeze') {
          freezeCount += 1;
          messages.add('Reward: +1 streak freeze ❄️');
        } else {
          await repository.unlockReward(reward);
          messages.add('Reward unlocked: ${reward.label} 🎁');
        }
      }
    }

    final updated = s.copyWith(
      xp: progression['xp'] as int,
      level: progression['level'] as int,
      freezeCount: freezeCount,
    );
    await repository.saveState(updated);

    return messages.isEmpty ? null : messages.join(' ');
  }

  List<Reward> _decodeRewards(Object? value) {
    final list = value as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((r) => Reward(id: r['id'] as String, type: r['type'] as String, label: r['label'] as String))
        .toList();
  }

  Future<void> _secureStreakIfEnough({String? message}) async {
    var s = await repository.getState();
    if (s == null) return;
    final activeToday = DayKey.today(offsetDays: s.dayOffsetDays);
    final completed = await repository.completedCountForDay(activeToday);

    final result = await python.call('secure_streak', {
      'date': activeToday,
      'completed_count': completed,
      'minimum_goals': AppConstants.minimumDailyGoals,
      'current_streak': s.currentStreak,
      'longest_streak': s.longestStreak,
      'last_streak_awarded_date': s.lastStreakAwardedDate,
    });

    s = s.copyWith(
      currentStreak: result['current_streak'] as int,
      longestStreak: result['longest_streak'] as int,
      lastStreakAwardedDate: result['last_streak_awarded_date'] as String?,
    );
    await repository.saveState(s);

    final streakMessage = result['message'] as String?;
    await _refresh(message: streakMessage ?? message);
    if (message != null) {
      await NotificationService.instance.showEncouragement(message);
    }
  }

  Future<void> _refresh({String? message}) async {
    final latestState = await repository.getState();
    final activeDay = DayKey.today(offsetDays: latestState?.dayOffsetDays ?? 0);
    state = state.copyWith(
      profile: await repository.getProfile(),
      appState: latestState,
      goals: await repository.getGoalsForDay(activeDay),
      inventory: await repository.unlockedInventory(),
      blockedApps: await repository.blockedApps(),
      isLoading: false,
      message: message,
    );
  }

  String _activeDayFromState() => DayKey.today(offsetDays: state.appState?.dayOffsetDays ?? 0);

  String _encouragement() => AppConstants.encouragements[_random.nextInt(AppConstants.encouragements.length)];
}
