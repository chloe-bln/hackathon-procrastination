# Data Storage

## Database

The app uses SQLite through `sqflite_common_ffi` for Linux desktop.

Default path:

```text
<application documents directory>/cozy_goals/cozy_goals.sqlite
```

## Tables

### profile

```text
id INTEGER PRIMARY KEY CHECK(id = 1)
username TEXT
birthDate TEXT ISO-8601
```

### app_state

```text
id INTEGER PRIMARY KEY CHECK(id = 1)
currentStreak INTEGER
longestStreak INTEGER
xp INTEGER
level INTEGER
freezeCount INTEGER
lastValidatedDate TEXT yyyy-MM-dd
lastStreakAwardedDate TEXT yyyy-MM-dd nullable
avatarHair TEXT
avatarClothes TEXT
dayOffsetDays INTEGER DEFAULT 0
```

`dayOffsetDays` is used only by Developer Mode. It simulates time locally without touching the Linux system clock.

### goals

```text
id TEXT PRIMARY KEY
title TEXT
description TEXT nullable
goalDate TEXT yyyy-MM-dd
durationMinutes INTEGER DEFAULT 25
isCompleted INTEGER 0/1
completedAt TEXT ISO-8601 nullable
```

A goal is completed only after the focus timer has been launched and the user validates it. The validate button appears halfway through `durationMinutes`.

### inventory

```text
id TEXT PRIMARY KEY
type TEXT hair|clothes|freeze
label TEXT
isUnlocked INTEGER 0/1
```

Cosmetics are stored in `inventory`. Streak freeze items are consumables and are stored as `freezeCount` in `app_state`.

### blocked_apps

```text
id TEXT PRIMARY KEY
name TEXT
command TEXT
unlockedUntil TEXT ISO-8601 nullable
```

## Migration

Database version 2 adds:

- `goals.durationMinutes`
- `app_state.dayOffsetDays`

Existing v1 save files are migrated automatically with default values.

## JSON save-file equivalent

A JSON export shape is provided in `docs/example_save.json`. The live implementation uses SQLite because it scales better as goals, rewards and blocking rules grow.
