import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _db = await databaseFactory.openDatabase(
      await _databasePath(),
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return _db!;
  }

  Future<String> _databasePath() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'cozy_goals'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return p.join(dir.path, 'cozy_goals.sqlite');
  }

  Future<void> resetDatabase() async {
    final dbPath = await _databasePath();
    await _db?.close();
    _db = null;
    final file = File(dbPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        username TEXT NOT NULL,
        birthDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        currentStreak INTEGER NOT NULL,
        longestStreak INTEGER NOT NULL,
        xp INTEGER NOT NULL,
        level INTEGER NOT NULL,
        freezeCount INTEGER NOT NULL,
        lastValidatedDate TEXT NOT NULL,
        lastStreakAwardedDate TEXT,
        avatarHair TEXT NOT NULL,
        avatarClothes TEXT NOT NULL,
        avatarSkin TEXT NOT NULL DEFAULT 'skin_peach',
        dayOffsetDays INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        goalDate TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL DEFAULT 25,
        focusSeconds INTEGER NOT NULL DEFAULT 0,
        isCompleted INTEGER NOT NULL,
        completedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_goals_date ON goals(goalDate)
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        label TEXT NOT NULL,
        isUnlocked INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE blocked_apps (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        command TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'app',
        target TEXT NOT NULL DEFAULT '',
        unlockedUntil TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_time_bonus (
        day TEXT PRIMARY KEY,
        xpAwarded INTEGER NOT NULL,
        awardedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE goals ADD COLUMN durationMinutes INTEGER NOT NULL DEFAULT 25');
      await db.execute('ALTER TABLE app_state ADD COLUMN dayOffsetDays INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE app_state ADD COLUMN avatarSkin TEXT NOT NULL DEFAULT 'skin_peach'");
      await db.execute('ALTER TABLE goals ADD COLUMN focusSeconds INTEGER NOT NULL DEFAULT 0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_time_bonus (
          day TEXT PRIMARY KEY,
          xpAwarded INTEGER NOT NULL,
          awardedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE blocked_apps ADD COLUMN kind TEXT NOT NULL DEFAULT 'app'");
      await db.execute("ALTER TABLE blocked_apps ADD COLUMN target TEXT NOT NULL DEFAULT ''");
      await db.execute("UPDATE blocked_apps SET target = command WHERE target = '' OR target IS NULL");
    }
  }
}
