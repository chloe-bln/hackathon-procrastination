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
  double get minimumProgress => (completedToday / AppConstants.minimumDailyGoals).clamp(0.0, 1.0);
  int get nextLevelXp => pow((appState?.level ?? 1) + 1, 2).toInt() * 100;
  int get currentLevelBaseXp => pow(appState?.level ?? 1, 2).toInt() * 100;
  double get levelProgress {
    final state = appState;
    if (state == null) return 0;
    final span = nextLevelXp - currentLevelBaseXp;
    if (span <= 0) return 0;
    return ((state.xp - currentLevelBaseXp) / span).clamp(0.0, 1.0);
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

    final today = DayKey.today();
    state = AppUiState(
      isLoading: false,
      profile: profile,
      appState: appState,
      goals: await repository.getGoalsForDay(today),
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

  Future<void> addGoal({required String title, String? description}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final goal = Goal(
      id: _uuid.v4(),
      title: cleanTitle,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      goalDate: DayKey.today(),
    );
    await repository.upsertGoal(goal);
    await _refresh(message: 'Goal planted 🌱');
  }

  Future<void> deleteGoal(String id) async {
    await repository.deleteGoal(id);
    await _refresh(message: 'Goal removed. Keep the day realistic.');
  }

  Future<void> toggleGoal(Goal goal) async {
    final wasCompleted = goal.isCompleted;
    final updated = goal.copyWith(
      isCompleted: !goal.isCompleted,
      completedAt: !goal.isCompleted ? DateTime.now() : null,
    );
    await repository.upsertGoal(updated);

    var nextMessage = wasCompleted ? 'Goal reopened.' : _encouragement();

    if (!wasCompleted) {
      nextMessage = await _applyGoalCompletionRewards() ?? nextMessage;
      await repository.unlockOneBlockedAppForToday();
      nextMessage = '$nextMessage One blocked app is open for 30 minutes.';
    }

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

  Future<CozyAppState> _runDailyValidation(CozyAppState appState) async {
    final today = DayKey.today();
    if (!DayKey.isBefore(appState.lastValidatedDate, today)) return appState;

    var current = appState;
    final daysToValidate = DayKey.daysBetweenExclusiveEnd(appState.lastValidatedDate, today);
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

    current = current.copyWith(lastValidatedDate: today);
    await repository.saveState(current);
    return current;
  }

  Future<String?> _applyGoalCompletionRewards() async {
    final s = await repository.getState();
    if (s == null) return null;

    final result = await python.call('progression', {
      'current_xp': s.xp,
      'current_level': s.level,
      'xp_gain': AppConstants.xpPerGoal,
    });

    final rewards = (result['rewards'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((r) => Reward(id: r['id'] as String, type: r['type'] as String, label: r['label'] as String))
        .toList();

    var freezeCount = s.freezeCount;
    final cosmetics = <Reward>[];
    for (final reward in rewards) {
      if (reward.type == 'freeze') {
        freezeCount += 1;
      } else {
        cosmetics.add(reward);
        await repository.unlockReward(reward);
      }
    }

    final updated = s.copyWith(
      xp: result['xp'] as int,
      level: result['level'] as int,
      freezeCount: freezeCount,
    );
    await repository.saveState(updated);

    if ((result['level_up'] as bool?) == true) {
      final labels = rewards.map((r) => r.label).join(', ');
      return labels.isEmpty ? 'Level up! New calm energy unlocked ✨' : 'Level up! Reward unlocked: $labels ✨';
    }
    return null;
  }

  Future<void> _secureStreakIfEnough({String? message}) async {
    var s = await repository.getState();
    if (s == null) return;
    final today = DayKey.today();
    final completed = await repository.completedCountForDay(today);

    final result = await python.call('secure_streak', {
      'date': today,
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
    final today = DayKey.today();
    state = state.copyWith(
      profile: await repository.getProfile(),
      appState: await repository.getState(),
      goals: await repository.getGoalsForDay(today),
      inventory: await repository.unlockedInventory(),
      blockedApps: await repository.blockedApps(),
      isLoading: false,
      message: message,
    );
  }

  String _encouragement() => AppConstants.encouragements[_random.nextInt(AppConstants.encouragements.length)];
}
