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

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'cozy_goals'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _db = await databaseFactory.openDatabase(
      p.join(dir.path, 'cozy_goals.sqlite'),
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return _db!;
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
        unlockedUntil TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE goals ADD COLUMN durationMinutes INTEGER NOT NULL DEFAULT 25');
      await db.execute('ALTER TABLE app_state ADD COLUMN dayOffsetDays INTEGER NOT NULL DEFAULT 0');
    }
  }
}
