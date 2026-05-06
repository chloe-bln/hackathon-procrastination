import 'package:sqflite/sqflite.dart';

import '../../core/date_utils.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/blocked_app.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/reward.dart';
import '../../domain/models/user_profile.dart';
import 'database_service.dart';

class AppRepository {
  Future<Database> get _db => DatabaseService.instance.database;

  Future<UserProfile?> getProfile() async {
    final db = await _db;
    final rows = await db.query('profile', limit: 1);
    return rows.isEmpty ? null : UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await _db;
    await db.insert('profile', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CozyAppState?> getState() async {
    final db = await _db;
    final rows = await db.query('app_state', limit: 1);
    return rows.isEmpty ? null : CozyAppState.fromMap(rows.first);
  }

  Future<void> saveState(CozyAppState state) async {
    final db = await _db;
    await db.insert('app_state', state.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Goal>> getGoalsForDay(String day) async {
    final db = await _db;
    final rows = await db.query(
      'goals',
      where: 'goalDate = ?',
      whereArgs: [day],
      orderBy: 'isCompleted ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> completedCountForDay(String day) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as c FROM goals WHERE goalDate = ? AND isCompleted = 1',
      [day],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> upsertGoal(Goal goal) async {
    final db = await _db;
    await db.insert('goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGoal(String id) async {
    final db = await _db;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> ensureDefaultInventory() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inventory')) ?? 0;
    if (count > 0) return;

    final initialItems = <Reward>[
      const Reward(id: 'hair_bun_mint', type: 'hair', label: 'Mint bun'),
      const Reward(id: 'clothes_cardigan_lavender', type: 'clothes', label: 'Lavender cardigan'),
    ];
    for (final item in initialItems) {
      await db.insert('inventory', item.toMap(isUnlocked: true));
    }
  }

  Future<void> unlockReward(Reward reward) async {
    if (reward.type == 'freeze') return;
    final db = await _db;
    await db.insert('inventory', reward.toMap(isUnlocked: true), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Reward>> unlockedInventory() async {
    final db = await _db;
    final rows = await db.query('inventory', where: 'isUnlocked = 1', orderBy: 'type, label');
    return rows.map(Reward.fromMap).toList();
  }

  Future<List<BlockedApp>> blockedApps() async {
    final db = await _db;
    final rows = await db.query('blocked_apps', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(BlockedApp.fromMap).toList();
  }

  Future<void> upsertBlockedApp(BlockedApp app) async {
    final db = await _db;
    await db.insert('blocked_apps', app.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBlockedApp(String id) async {
    final db = await _db;
    await db.delete('blocked_apps', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> unlockOneBlockedAppForToday() async {
    final db = await _db;
    final rows = await db.query(
      'blocked_apps',
      orderBy: 'unlockedUntil IS NOT NULL, unlockedUntil ASC, name COLLATE NOCASE ASC',
      limit: 1,
    );
    if (rows.isEmpty) return;
    final app = BlockedApp.fromMap(rows.first);
    final until = DateTime.now().add(const Duration(minutes: 30));
    await upsertBlockedApp(app.copyWith(unlockedUntil: until));
  }

  Future<void> clearExpiredAppUnlocks() async {
    final db = await _db;
    await db.update(
      'blocked_apps',
      {'unlockedUntil': null},
      where: 'unlockedUntil IS NOT NULL AND unlockedUntil < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  Future<CozyAppState> createInitialState() async {
    final initial = CozyAppState(
      currentStreak: 0,
      longestStreak: 0,
      xp: 0,
      level: 1,
      freezeCount: 0,
      lastValidatedDate: DayKey.today(),
      avatarHair: 'hair_bun_mint',
      avatarClothes: 'clothes_cardigan_lavender',
    );
    await saveState(initial);
    return initial;
  }
}
